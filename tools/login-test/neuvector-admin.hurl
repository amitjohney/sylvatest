GET https://{{vault_url}}/v1/secret/data/neuvector
X-Vault-Token: {{token}}
HTTP 200
[Captures]
password_neuvector: jsonpath "$.data.data.password"

POST https://{{neuvector_url}}/auth
{"username":"admin",
"password":"{{password_neuvector}}"}
HTTP 200

