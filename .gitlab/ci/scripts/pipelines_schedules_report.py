#!/bin/env python

import sys
import datetime
import os

try:
    import gitlab
except ModuleNotFoundError:
    print("[ERROR] python-gitlab package not found", file=sys.stderr)
    print("[ERROR] it can be installed with: 'pip install --upgrade python-gitlab'", file=sys.stderr)
    sys.exit(1)

try:
    from tabulate import tabulate
except ModuleNotFoundError:
    print("[ERROR] tabulate package not found", file=sys.stderr)
    print("[ERROR] it can be installed with: 'pip install --upgrade tabulate'", file=sys.stderr)
    sys.exit(1)


PIPELINE_HISTORY_COUNT = int(sys.argv[1])
print(f"PIPELINE_HISTORY_COUNT={PIPELINE_HISTORY_COUNT}")

gitlab_url = "https://gitlab.com"
gl = gitlab.Gitlab(gitlab_url, private_token=os.getenv("PRIVATE_TOKEN"))
project_id = 42451983
pipeline_schedule_name = os.getenv("PIPELINE_SCHEDULE_NAME_SELECTOR", default="Nightly")
project = gl.projects.get(project_id)
print("retrieving pipeline schedules")
pipeline_schedules = project.pipelineschedules.list()
print("  done")

REPORT_FILE = "report_output.md"
WIKI_REPORT_PAGE = os.getenv("WIKI_REPORT_PAGE", "Scheduled-pipelines-report")

status_icon = {
    "failed": "❌",
    "success": "✔",
    "canceled": "🛇",
    "skipped": "⏩",
    "running": "🔄",
    "created": "𑀣",
    "waiting_for_resource": "🔒",
    "preparing": "👀",
    "pending": "⏸️",
    "manual": "⚙️",
    "scheduled": "🕒",
}


def get_status_icon(status):
    return status_icon.get(status, status)


def pipeline_summary(pipeline):
    if not pipeline:
        return "(no pipeline info)"

    pipeline = project.pipelines.get(pipeline["id"])

    summary = ""

    def _sort_jobs_by_starting_date(jobs):
        executed_jobs = [j for j in jobs if hasattr(j, "started_at") and j.started_at]
        return sorted(
            executed_jobs,
            key=lambda x: datetime.datetime.strptime(
                x.started_at, "%Y-%m-%dT%H:%M:%S.%f%z"
            ),
        )

    jobs = _sort_jobs_by_starting_date(pipeline.jobs.list())
    test_jobs = [j for j in jobs if j.stage == "deployment-test"]
    test_combined_md = ""
    for job in jobs:
        # we don't care about displaying the create-runner job if it worked
        if job.name == "create-runner" and job.status == "success":
            continue

        # we don't care about displaying the delete stage if it worked
        if job.stage == "delete" and job.status == "success":
            continue

        if job not in test_jobs:
            job_text = f"{job.name.replace('-','‑')}: {get_status_icon(job.status)}"
            job_md = f"[{job_text}]({job.web_url})<br>"
            summary += job_md
        else:
            if test_combined_md == "":
                test_combined_statuses = " ".join(
                    [get_status_icon(j.status) for j in test_jobs]
                )
                test_text = f"tests: {test_combined_statuses}"
                test_combined_md = f"[{test_text}]({pipeline.web_url})<br>"
                summary += test_combined_md

    # dumy line for padding to avoid ugly line breaks
    summary += "&#160;"*60

    return summary


def create_report():
    with open(REPORT_FILE, "w") as report_fd:

        def print_report(text):
            print(text, file=report_fd)

        print_report(
            "**scheduled pipelines report produced at "
            + datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
            + ".**"
        )
        print_report("")
        for pipeline_schedule in pipeline_schedules:

            if pipeline_schedule_name not in pipeline_schedule.description:
                continue

            pipeline_description = pipeline_schedule.description

            print(f"processing pipeline schedule {pipeline_description}")

            schedules = project.pipelineschedules.get(pipeline_schedule.id)
            pipelines = schedules.pipelines.list(get_all=True)
            pipelines.reverse()
            newest_pipelines = pipelines[:PIPELINE_HISTORY_COUNT]

            print_report(f"## {pipeline_description}")
            print_report("")

            def _get_child_md(child):
                duration_text = "unknown runtime"
                if child.duration:
                    duration_text = f"{child.duration/60.0:.0f}min"
                ds_pipeline_summary = pipeline_summary(child.downstream_pipeline)
                return f"[{duration_text} {get_status_icon(child.status)}]({child.web_url})<br>{ds_pipeline_summary}"

            child_pipelines_reports = dict()
            for pipeline in newest_pipelines:
                print(f"  processing pipeline {pipeline.id}")
                for child in project.pipelines.get(pipeline.id).bridges.list():
                    print(f"    processing child {child.name}")
                    child_pipelines_reports.setdefault(child.name, dict())
                    child_pipelines_reports[child.name][pipeline.id] = _get_child_md(child)

            headers = ["name"]
            rows_as_dict = dict()
            for pipeline in newest_pipelines:
                time_status = f"[{pipeline.created_at[:16]} {get_status_icon(pipeline.status)}]({pipeline.web_url})"
                headers.append(time_status)
                # add empty cell in table if any child pipeline type doesn't exit at a given date
                for child_pipeline_name in child_pipelines_reports.keys():
                    if pipeline.id not in child_pipelines_reports[child_pipeline_name]:
                        child_pipelines_reports[child_pipeline_name][pipeline.id] = ""

                    rows_as_dict.setdefault(child_pipeline_name, [child_pipeline_name.replace("-deploy", "").replace("-", "‑")])
                    rows_as_dict[child_pipeline_name].append(child_pipelines_reports[child_pipeline_name][pipeline.id])

            report_rows = list(rows_as_dict.values())
            print_report(tabulate(report_rows, headers=headers, tablefmt="pipe"))
            print_report(" ")


def publish_report():

    with open(REPORT_FILE, "r") as f:
        report_content = f.read()

    if PIPELINE_HISTORY_COUNT > 1:
        # if script is run for aggregate several days, publish on "WIKI_REPORT_PAGE"
        wiki_page = WIKI_REPORT_PAGE
    else:
        # if script is run for an single day, publish on "WIKI_REPORT_PAGE/date"
        date = datetime.datetime.now().strftime("%Y-%m-%d")
        wiki_page = f"{WIKI_REPORT_PAGE}/{date}"

    try:
        main_report = project.wikis.get(wiki_page)
    except gitlab.exceptions.GitlabGetError:
        main_report = project.wikis.create(
            {
                "title": f"{wiki_page}",
                "content": report_content,
            }
        )
    else:
        main_report.content = report_content
        main_report.save()

    print(f"The report can be found on following URL: https://gitlab.com/sylva-projects/sylva-core/-/wikis/{wiki_page}")
    print("Report uploaded for " + datetime.datetime.now().strftime("%Y-%m-%d"))


def delete_old_reports():
    print("Delete reports older than 7 days")
    date = datetime.datetime.now().strftime("%Y-%m-%d")
    time_now = datetime.datetime.strptime(date, "%Y-%m-%d")
    for page in project.wikis.list():
        if f"{WIKI_REPORT_PAGE}/" not in page.slug:
            continue
        report_date = datetime.datetime.strptime(page.slug.split("/")[1], "%Y-%m-%d")
        delta = time_now - report_date
        if delta.days > 7:
            print(f"Deleting page {page.slug}")
            project.wikis.delete(page.slug)


create_report()
publish_report()

if PIPELINE_HISTORY_COUNT == 1:
    delete_old_reports()
