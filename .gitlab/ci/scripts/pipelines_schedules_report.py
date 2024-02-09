#!/bin/env python

import sys
import datetime
import os

from collections import defaultdict

def get_req_packages():
    os.system('pip install --upgrade python-gitlab')
    os.system('pip install tabulate')
    print("Done with require packages")

get_req_packages()

import gitlab
from tabulate import tabulate

gitlab_url = "https://gitlab.com"
private_token = os.getenv('PRIVATE_TOKEN')
gl = gitlab.Gitlab(gitlab_url, private_token=private_token)
project_id = 42451983
pipeline_schedule_name="Nightly"
project = gl.projects.get(project_id)
print("retrieving pipeline schedules")
pipeline_schedules = project.pipelineschedules.list()
print("  done")
pipeline_number = sys.argv[1]
print(f"{pipeline_number=}")

report_fd = open('report_output.md', 'w')

status_icon = {
    "failed": "❌",
    "success": ":white_check_mark:", # ✅
    "canceled": "🛇",
    "skipped": "⏩",
}

def print_report(text):
    print(text, file=report_fd)


def get_status_icon(status):
    return status_icon.get(status,status)

def order_stages(stages):
    _stages = list(stages)
    # return stages in a pre-defined order
    # (I didn't find a way to get the stages order from the API)
    for s in [
            ".pre",
            "deploy",
            "update",
            "deploy-wc",
            "update-wc",
            "deployment-test",
            "delete",
        ]:
        if s in _stages:
            _stages.remove(s)
            yield s
    for s in _stages:
        yield s

def pipeline_summary(pipeline):
    pipeline = project.pipelines.get(pipeline["id"])

    stage_statuses = defaultdict(set)
    for job in pipeline.jobs.list():
        stage_statuses[job.stage].add(job.status)

    summary = ""
    for stage in order_stages(stage_statuses.keys()):
        statuses = stage_statuses[stage]
        if stage == ".pre":
            continue
        if len(statuses) == 0:
            continue
        if len(statuses) == 1 and list(statuses)[0] == "skipped":
            continue

        # we don't care about displaying the delete stage if it worked
        if len(statuses) == 1 and stage == "delete" and list(statuses)[0] == "success":
            continue

        combined_statuses = " ".join([get_status_icon(s) for s in statuses])

        summary += f" {stage}: {combined_statuses}"

    return summary


def create_report():
    print_report(f"**scheduled pipelines report produced at " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M") +".**")
    print_report("")
    for pipeline_schedule in pipeline_schedules:

        if pipeline_schedule_name not in pipeline_schedule.description:
            continue

        pipeline_description = pipeline_schedule.description

        print(f"processing pipeline schedule {pipeline_description}")

        schedules = project.pipelineschedules.get(pipeline_schedule.id)
        pipelines = schedules.pipelines.list(get_all=True)
        pipelines.reverse()
        newest_pipelines=pipelines[:int(pipeline_number)]

        print_report(f"## {pipeline_description}")
        print_report("")
        pipeline_items = []
        for pipeline in newest_pipelines:
            print(f"  processing pipeline {pipeline.id}")
            pipeline_item = {
                "time / status": f"[{pipeline.created_at[:16]} {get_status_icon(pipeline.status)}]({pipeline.web_url})",
            }
            child_pipelines = project.pipelines.get(pipeline.id).bridges.list()
            for child in child_pipelines:
                print(f"    processing child {child.name}")

                duration = child.duration/60.0

                ds_pipeline_summary = pipeline_summary(child.downstream_pipeline)

                child_pipeline_md = f"[{duration:.0f}min {get_status_icon(child.status)}]({child.web_url})<br/>{ds_pipeline_summary}"
                pipeline_item[child.name] = child_pipeline_md

                #commit_md = f"[{child.commit['short_id']} / { child.commit['committed_date'][:16]}]({child.commit['web_url']})"
                #pipeline_item["commit"] = commit_md

            pipeline_items.append(pipeline_item)

        all_columns = set()
        for item in pipeline_items:
            for k in item.keys():
                all_columns.add(k)
        all_columns.remove("time / status")
        #all_columns.remove("commit")

        headers = []
        headers.append("time / status")
        headers.extend(sorted(all_columns))
        #headers.append("commit")

        tab_values = [[pipeline_item.get(h,"") for h in headers] for pipeline_item in pipeline_items]

        print_report(tabulate(tab_values,headers=headers,tablefmt='pipe'))
        print_report(" ")

def publish_report():

    import pdb; pdb.set_trace()

    main_report = project.wikis.get("Scheduled-pipelines-report")
    main_report.content = open('report_output.md').read()
    main_report.save()

    date  = datetime.datetime.now().strftime("%Y-%m-%d")
    project.wikis.create({'title': f'Scheduled-pipelines-report/{date}','content': open('report_output.md').read()})
    print(f"The report can be found on following URL: https://gitlab.com/sylva-projects/sylva-core/-/wikis/Scheduled-pipelines-report/{date}")
    print("Report uploaded for " + datetime.datetime.now().strftime("%Y-%m-%d"))

    pages = project.wikis.list()
    for page in pages:
        print(page.title)

def delete_report():
    print("Delete reports older than 7 days")
    date  = datetime.datetime.now().strftime("%Y-%m-%d")
    time_now = datetime.datetime.strptime(date,"%Y-%m-%d")
    for page in project.wikis.list():
        if "Scheduled-pipelines-report/" not in page.slug:
            continue
        report_date = datetime.datetime.strptime(page.slug.split("/")[1],"%Y-%m-%d")
        delta = time_now - report_date
        if delta.days > 7:
            print(page.slug)
            project.wikis.delete(page.slug)


create_report()

report_fd.close()

publish_report()
delete_report()
