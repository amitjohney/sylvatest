{{/*

interpret-values-gotpl

This template allows the interpretation of go templates inside values. It should be called at the beginning of every template file that uses templated values, using the following syntax for eample:

{{- $envAll := set . "Values" (include "interpret-values-gotpl" . | fromJson) -}}

Here is an example of its usage:

# values:

foo: bar
sample: "{{ .Values.foo }}"

# template:

{{- $_ := set . "Values" (include "interpret-values-gotpl" . | fromJson) -}}
sample-value: {{ .Values.sample }}

# result:

sample-value: bar

If your template outputs is not a string, you should pass it to the "preserve-type" template if want to prevent the result from being transformed to a string (which often produces unwanted result, as illustrated below):

# values:

sample: '{{ dict "foo" "bar" }}'
preserved: '{{ dict "foo" "bar" | include "preserve-type" }}'

# template:

{{- $_ := set . "Values" (include "interpret-values-gotpl" . | fromJson) -}}
sample-value: {{ .Values.sample }}
preserved-value: {{ .Values.preserved }}

# result:

sample-value: map[foo:bar]
preserved-value:
  foo: bar

Note well that there are a few limitations:

* there is no error management on templating:
    foo: 42
    x: "{{ .Values.fooo }}" -> x after processing by this template will give "" (nothing complains about 'fooo' not being defined)

* everything looking like "{{ }}" will be interpreted, even non-gotpl stuff
  that you might want to try to put in your manifest because a given component
  would need that

* templates that use "preserve-type" must define the whole key or value field, it can't be compound inline with a string:
  (this wouldn't make sense anyway, as you can't concaternate a string with another type)

value: prefix-{{ 42 | "include preserve-type" }}            -> will produce prefix-{"encapsulated-result":42}
value: "{{ print "prefix-" 42 | "include preserve-type" }}  -> will produce prefix-42
value: "prefix-{{ 42 }}"                                    -> will also produce prefix-42

*/}}

{{ define "interpret-values-gotpl" }}
{{ $envAll := . }}
{{ range until 3 }}
{{ $_ := set $envAll "Values" (index (tuple $envAll $envAll.Values | include "interpret-inner-gotpl" | fromJson) "result") }}
{{ end }}
{{ $envAll.Values | toJson }}
{{ end }}

{{/*

preserve-type

The goal of this template is just to encapsulate a value into json, using a well known key to retrieve it later in interpret-inner-gotpl

Given that templating function (aka "tpl") only returns strings, it is impossible to retrieve the original type of values. For example:

# values:
test: 42
# template:
{{ tpl "{{ .Values.test }}" . | kindOf }}
# result:
string

This simple template enables the encapsulation of the template result in a json that will preserve the original type:

# values:
test: 42
# template:
{{ tpl "{{ .Values.test | include \"preserve-type\" }}" . }}
# result:
"{\"encapsulated-result\":4}"

The result is still a string, but we'll be able to match its signature and deserialize properly its content in interpret-inner-gotpl
*/}}

{{ define "preserve-type" }}
  {{- dict "encapsulated-result" . | toJson -}}
{{ end }}

{{/*

interpret-inner-gotpl

This is used to interpret any '{{ .. }}' templating found in a datastructure, doing that on all strings found at the different levels.

This template returns the resulting datastructure marshalled as a JSON dict {"result": ...}

Usage:

    tuple $envAll $data | include "interpret-inner-gotpl"

Example:

    $data := dict "foo" (dict "bar" "{{ .Values.bar }}")
    index (tuple $envAll $data | include "interpret-inner-gotpl" | fromJson) "result"

Values:

    bar: something here

Result:

    {"foo": {"bar": "something here"}}


Note well that there are a few limitations:

* there is no error management on templating:

    foo: 42
    x: "{{ .Values.fooo }}"  -> x after processing by this template will give "" (nothing complains about 'fooo' not being defined)

* the templating that you use cannot currently return anything else than a string.

    foo: 42
    x: "{{ .Values.foo }}"  -> x after processing by this template will give "42" not 42

    bar:
     - 1
     - 2
     - 3
    y: "{{ .Values.bar }}"  -> y after processing by this template will give '[1 2 3]', which is not what you want (not a list of numbers)

    In order to workaround this issue, you should pass the value to "preserve-type" template defined above:

    y: '{{ .Values.bar | include "preserve-type }}' -> will produce the expected content

* everything looking like "{{ }}" will be interpreted, even non-gotpl stuff
  that you might want to try to put in your manifest because a given component
  would need that

*/}}

{{ define "interpret-inner-gotpl" }}
    {{ $envAll := index . 0 }}
    {{ $data := index . 1 }}
    {{ $kind := kindOf $data }}
    {{ $result := 0 }}
    {{ if (eq $kind "string") }}
        {{ if regexMatch ".*{{.*}}.*" $data }}
            {{/* This is where we actually trigger GoTPL interpretation */}}
            {{ $tpl_res := tpl $data $envAll }}
            {{ if (hasPrefix "{\"encapsulated-result\":" $tpl_res) }}
                {{ $result = index (fromJson $tpl_res) "encapsulated-result" }}
            {{ else }}
                {{ $result = $tpl_res }}
            {{ end }}
        {{ else }}
            {{ $result = $data }}
        {{ end }}
    {{ else if (eq $kind "slice") }}
        {{/* this is a list, recurse on each item */}}
        {{ $result = list }}
        {{ range $data }}
            {{ $result = append $result (index (tuple $envAll . | include "interpret-inner-gotpl" | fromJson) "result") }}
        {{ end }}
    {{ else if (eq $kind "map") }}
        {{/* this is a dictionary, recurse on each key-value pair */}}
        {{ $result = dict }}
        {{ range $key,$value := $data }}
            {{ $_ := set $result (index (tuple $envAll $key | include "interpret-inner-gotpl" | fromJson) "result") (index (tuple $envAll $value | include "interpret-inner-gotpl" | fromJson) "result") }}
        {{ end }}
    {{ else }}  {{/* bool, int, float64 */}}
        {{ $result = $data }}
    {{ end }}

{{ dict "result" $result | toJson }}
{{ end }}

