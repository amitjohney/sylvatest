import sys
import datetime
import os

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
pipeline_schedules = project.pipelineschedules.list()
pipeline_number = sys.argv[1]

def create_report():
    with open('report_output.txt', 'w') as f:
         sys.stdout = f
         print("***Pipelines schedules report at " + datetime.datetime.now().strftime("%Y-%m-%d"))
         print(" ")
         for pipeline_schedule in pipeline_schedules:
             output = []
             aux= []
             keys = []
             results = []
             keys_aux= []
             if pipeline_schedule_name in pipeline_schedule.description:
                sched = project.pipelineschedules.get(pipeline_schedule.id)
                pipeline_description = pipeline_schedule.description
                pipelines = sched.pipelines.list(get_all=True)
                pipelines.reverse()
                newest_pipelines=pipelines[:int(pipeline_number)]
                results=[]
                aux = []
                output= []
                keys = ['parents_pipeline_id','parent_pipeline_status','updated_time']
                print(pipeline_description)
                print(" ")
                for pipeline in newest_pipelines:
                    markdown_id = f"[{pipeline.id}]({pipeline.web_url})"
                    output.append(markdown_id)
                    output.append(pipeline.status)
                    output.append(pipeline.updated_at)
                    child_pipelines = project.pipelines.get(pipeline.id).bridges.list()
                    for child in child_pipelines:
                        markdown_status = f"[{child.status}]({child.web_url})"
                        markdown_commit = f"[{ child.commit['title']}]({child.commit['web_url']})"
                        keys.append(child.name)
                        output.append(markdown_status)
                    keys.append('commit')
                    output.append(markdown_commit)
                    keys_aux=keys
                    aux.append(output)
                    results=aux
                    output= []
                    keys = ['parent_pipeline_id','parent_pipeline_status','updated_time']
             aux = []
             results.insert(0,keys_aux)
             data_header = results[0]
             data_values = results[1:]
             print(tabulate(data_values,headers=data_header,tablefmt='pipe'))
             print(" ")

def insert_report():
    date  = datetime.datetime.now().strftime("%Y-%m-%d")
    project.wikis.create({'title': f'Pipeline schedules report/{date}','content': open('report_output.txt').read()})
    print(f"The report can be found on following URL: https://gitlab.com/sylva-projects/sylva-core/-/wikis/Pipeline-schedules-report/{date}")
    print("Report uploaded for " + datetime.datetime.now().strftime("%Y-%m-%d"))
    pages = project.wikis.list()
    for page in pages:
        print(page.title)

def delete_report():
    print("Delete reports older than 7 days")
    date  = datetime.datetime.now().strftime("%Y-%m-%d")
    time_now = datetime.datetime.strptime(date,"%Y-%m-%d")
    pages = project.wikis.list()
    for i in range(1,len (pages)):
        report_date = datetime.datetime.strptime(pages[i].slug.split("/")[1],"%Y-%m-%d")
        delta = time_now - report_date
        if delta.days > 7:
            print(pages[i].slug)
            project.wikis.delete(pages[i].slug)


create_report()
sys.stdout = sys.__stdout__
insert_report()
delete_report()
