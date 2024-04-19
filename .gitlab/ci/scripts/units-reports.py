#!/usr/bin/env python3

import yaml
import os
import argparse
from junit_xml import TestSuite, TestCase
from yaml.loader import SafeLoader
from datetime import datetime

parser = argparse.ArgumentParser(description='Generate junit xml report')
parser.add_argument('--input',
                    dest='input_filename',
                    required=True,
                    help='flux-kustomizations.yaml absolute path.')
parser.add_argument('--output',
                    dest='output_filename',
                    default="units-report.xml",
                    help='xml report output path. Default: "units-report.xml"')
parser.add_argument('--env-type',
                    dest='env_type',
                    default="",
                    help='deployment env type, used in tests name. eg capd/kubeadm-capo etc...')

args = parser.parse_args()

input_filename = args.input_filename
output_filename = args.output_filename
env_type = args.env_type

timestampFormat = '%Y-%m-%dT%H:%M:%SZ'
test_cases = []

short_filename = os.path.basename(os.path.split(input_filename)[0]) + "/" + os.path.basename(input_filename)

try:
    f = open(input_filename)
    data = yaml.load(f, Loader=SafeLoader)
    test_case = TestCase(env_type + ":dump-check:" + short_filename, classname='sylva-unit-validation')
    test_cases.append(test_case)

    for unit in data['items']:

        unit_name = unit['metadata']['name']
        unit_creation_timestamp = unit['metadata']['creationTimestamp']
        unit_ready_status = [status for status in unit['status']['conditions'] if status['type'] == 'Ready']

        tstamp1 = datetime.strptime(unit_creation_timestamp, timestampFormat)
        tstamp2 = datetime.strptime(unit_ready_status[0]['lastTransitionTime'], timestampFormat)
        td = tstamp2 - tstamp1

        print("Generating testcase for " + unit_name)
        test_case = TestCase(env_type + ":" + unit_name, classname='sylva-unit-validation',
                             elapsed_sec=td.total_seconds())
        if unit_ready_status[0]['status'] != 'True':
            test_case.add_failure_info(unit_name + " unit ready status was: " + unit_ready_status[0]['status'])
        test_cases.append(test_case)

except IOError:
    print(input_filename + " was not found")
    test_case = TestCase(env_type + ":dump-check:" + short_filename, classname='sylva-unit-validation')
    test_case.add_failure_info(short_filename + " was not found: ")
    test_cases.append(test_case)
    ts = TestSuite(env_type + ":" + "sylva-unit-validation", test_cases)


ts = TestSuite(env_type + ":" + "sylva-unit-validation", test_cases)

report = open(output_filename, "w")
report.write(TestSuite.to_xml_string([ts]))
report.close()

print("\nFinal report:\n")
print(TestSuite.to_xml_string([ts]))
