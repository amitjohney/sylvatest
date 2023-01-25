# Sets of Helm values overrides

Each of the subdirectories contains a set of files used as Helm values override.

For each of these sub-directores the "sylva-units:helm-template-yamllint"
CI job (defined in tools/gci-templates)  will give all YAML files as inputs to
"helm template" (which will validate against the Helm schema) and also check the
result with `yamllint`.
