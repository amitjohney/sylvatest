GET https://{{vault_url}}/v1/secret/data/rancher
X-Vault-Token: {{token}}
HTTP 200
[Captures]
password_rancher: jsonpath "$.data.data.bootstrapPassword"

POST https://{{rancher_url}}/v3-public/localProviders/local?action=login
{"username":"admin",
"password":"{{password_rancher}}",
"ttl":100}
HTTP 201
[Captures]
token_rancher: jsonpath "$.token"

GET https://{{rancher_url}}/v3/clusters
Authorization: Bearer {{token_rancher}}
HTTP 200
[Captures]
workload_cluster_id: jsonpath "$.data[0].id"

GET https://{{rancher_url}}/api/v1/namespaces/cattle-monitoring-system/services/http:rancher-monitoring-grafana:80/proxy/?orgId=1
Authorization: Bearer {{token_rancher}}
HTTP 200


GET https://{{rancher_url}}/k8s/clusters/{{workload_cluster_id}}/api/v1/namespaces/cattle-monitoring-system/services/http:rancher-monitoring-grafana:80/proxy/?orgId=1
Authorization: Bearer {{token_rancher}}
HTTP 200


GET https://{{rancher_url}}/k8s/clusters/local/api/v1/namespaces/cattle-monitoring-system/services/http:rancher-monitoring-prometheus:9090/proxy/targets?search=
Authorization: Bearer {{token_rancher}}
HTTP 200


GET https://{{rancher_url}}/k8s/clusters/{{workload_cluster_id}}/api/v1/namespaces/cattle-monitoring-system/services/http:rancher-monitoring-prometheus:9090/proxy/targets?search=
Authorization: Bearer {{token_rancher}}
HTTP 200


