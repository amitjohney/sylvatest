#!/usr/bin/python3

import argparse
import copy
import os
import json
import sys
import urllib.request
import yaml

# This script is used to generate sylva-units helm schema values.schema.json from values.schema.yaml
# Moreover this script is adding sylva-capi-cluster schema into sylva-units schema in order to
# make helm able to check values provided for cluster creation.

SCRIPT_DIR = os.path.dirname(os.path.abspath(sys.argv[0]))
CHART_DIR = os.path.abspath(f"{SCRIPT_DIR}/../charts/sylva-units")
SYLVA_UNITS_VALUES_FILE = f"{CHART_DIR}/values.yaml"
SYLVA_UNITS_YAML_SCHEMA = f"{CHART_DIR}/values.schema.yaml"
SYLVA_UNITS_JSON_SCHEMA = f"{CHART_DIR}/values.schema.json"


def get_sylva_capi_cluster_schema(values_file):
    """
    Get sylva-capi-cluster helm chart schema from Gitlab repository
    Helm chart url and tag (or branch, or commit) is read from values.yaml
    """
    with open(values_file) as f:
        data = yaml.load(f, Loader=yaml.loader.SafeLoader)
    spec_ref = data['source_templates']['sylva-capi-cluster']['spec']['ref']
    ref = spec_ref.get('commit') or spec_ref.get('tag') or spec_ref['branch']
    base_url = data['source_templates']['sylva-capi-cluster']['spec']['url']
    if base_url.endswith(".git"):
        base_url = base_url[:-4]
    url = f"{base_url.rstrip('/')}/-/raw/{ref}/values.schema.json"
    sylva_capi_cluster_schema = urllib.request.urlopen(url).read()
    return json.loads(sylva_capi_cluster_schema)


def load_sylva_units_schema(yaml_schema_file):
    with open(yaml_schema_file) as f:
        return yaml.load(f, Loader=yaml.loader.SafeLoader)


def check_sub_schemas(schema1, schema2):
    """
    Verify there is conflit in sub-schema definitions
    2 sub-schemas cannot share same name with different content
    """
    common_keys = set(schema1['$defs']) & set(schema2['$defs'])
    conflicts = 0
    for c in common_keys:
        if schema1['$defs'][c] != schema2['$defs'][c]:
            conflicts += 1
            print(f"[CONFLICT] schema are both defining '$defs/{c}' with different content")
    if conflicts > 0:
        sys.exit(1)


def allow_additional_format_for_all_schema_properties(schema, format):
    """
    Brutally recursively parse all properties and patternProperties from a schema
    to add "#/$defs/gotpl" option
    """
    if "properties" in schema:
        for property, property_definition in schema['properties'].items():
            schema['properties'][property] = _allow_additional_format_for_all(property_definition, format)
    if "patternProperties" in schema:
        for property, property_definition in schema['patternProperties'].items():
            schema['patternProperties'][property] = _allow_additional_format_for_all(property_definition, format)
    if "allOf" in schema:
        for index, condition in enumerate(schema['allOf']):
            schema['allOf'][index] = allow_additional_format_for_all_schema_properties(condition, format)
    if "then" in schema:
        schema['then'] = allow_additional_format_for_all_schema_properties(schema['then'], format)

    return schema


def _allow_additional_format_for_all(property_definition, format):
    if "anyOf" in property_definition:
        for index, case in enumerate(property_definition['anyOf']):
            if "type" in case and case['type'] == "object":
                property_definition['anyOf'][index] = allow_additional_format_for_all_schema_properties(property_definition['anyOf'][index], format)
        property_definition['anyOf'].append(format)
    else:
        if "properties" in property_definition or "patternProperties" in property_definition:
            property_definition = allow_additional_format_for_all_schema_properties(property_definition, format)
        property_definition = {
            "anyOf": [copy.deepcopy(property_definition), format]
        }
    return property_definition


def merge_schemas(schema1, schema2, target_sub_schema):
    """
    Inject schema2 as a $defs.<target_sub_schema> of schema1.
    """
    check_sub_schemas(schema1, schema2)
    # since sylva-units may use GoTPL for any value then passed to sylva-capi-cluster,
    # we need all values of sylva-capi-cluster to be GoTPL
    schema2 = allow_additional_format_for_all_schema_properties(schema2, {"$ref": "#/$defs/gotpl"})
    # we also need to be able to set some value to null
    schema2 = allow_additional_format_for_all_schema_properties(schema2, {"type": "null"})
    schema1['$defs'] = {**schema2['$defs'], **schema1['$defs']}
    schema2_no_defs = copy.deepcopy(schema2)
    del schema2_no_defs['$defs']
    schema1['$defs'][target_sub_schema] = schema2_no_defs

    return schema1


def dump_schema(schema, output):
    with open(output, 'w', encoding='utf8') as json_file:
        json.dump(schema, json_file, ensure_ascii=False, indent=2)


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="Sylva-units schema generator",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("-i", "--input", metavar="input", required=False, default=SYLVA_UNITS_YAML_SCHEMA, help="sylva-units schema in yaml format")
    parser.add_argument("-o", "--output", metavar="output", required=False, default=SYLVA_UNITS_JSON_SCHEMA, help="sylva-units schema in json format")
    parser.add_argument("-v", "--values", metavar="values", required=False, default=SYLVA_UNITS_VALUES_FILE, help="sylva-units values file")
    args = parser.parse_args()

    sylva_unit_schema = load_sylva_units_schema(args.input)
    sylva_capi_cluster_schema = get_sylva_capi_cluster_schema(args.values)
    final_schema = merge_schemas(sylva_unit_schema, sylva_capi_cluster_schema, "sylva-capi-cluster-values")
    dump_schema(final_schema, args.output)
