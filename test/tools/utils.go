package tools

import (
	"fmt"
	"reflect"

	"gopkg.in/yaml.v3"
)

// Take an array and count elemetn by type
// Add also a "total" entry to the resulted map
func GetCountPerType(input []interface{}) map[string]int {
	result := map[string]int{
		"total": len(input),
	}
	for _, v := range input {
		valueType := fmt.Sprintf("%v", reflect.TypeOf(v))
		result[valueType] += 1
	}
	return result
}

func IsUnitEnabled(name string, sylvaObjects []interface{}) bool {
	values := getValuesDebugData(sylvaObjects)
	parsedValues := parseGenericYaml(values)
	enabled := getNestedValue(parsedValues, "units", name, "enabled")
	if enabled, ok := enabled.(bool); ok {
		return enabled
	}
	if enabled, ok := enabled.(string); ok && enabled == "true" {
		return true
	}
	return false
}

func getValuesDebugData(sylvaObjects []interface{}) string {
	debugUnitSecret := GetSecret("sylva-units-values-debug", sylvaObjects)
	if debugUnitSecret == nil {
		panic("Debug secret not found")
	}
	values, ok := debugUnitSecret.StringData["values"]
	if !ok {
		panic("No values found in debug secret")
	}
	return values
}

func parseGenericYaml(input string) map[string]interface{} {
	res := make(map[string]interface{})

	err := yaml.Unmarshal([]byte(input), &res)
	if err != nil {
		panic(fmt.Sprintf("Error parsing yaml: %v", err))
	}
	return res
}

func getNestedValue(input map[string]interface{}, keys ...string) interface{} {
	var result interface{}
	var ok bool

	if result, ok = input[keys[0]]; !ok {
		panic(fmt.Sprintf("key %v not found", keys[0]))
	}
	if len(keys) == 1 {
		return result
	}
	if input, ok = result.(map[string]interface{}); !ok {
		panic(fmt.Sprintf("malformed structure at %#v", result))
	}
	return getNestedValue(input, keys[1:]...)
}
