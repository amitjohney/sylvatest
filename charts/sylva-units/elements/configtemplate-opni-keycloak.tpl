# Configurations needed to automate Opni's Monitoring authentication with Sylva's Keycloak

# Add Sylva's CA cert secret as a volume to Opni's manager
volumes:
- name: sylva-ca
  secret:
    secretName: sylva-ca.crt

# Mount Sylva's CA cert to Opni's manager
volumeMounts:
- name: sylva-ca
  mountPath: /etc/ssl/certs/ca.crt
  readOnly: true
  subPath: ca.crt

# Add Sylva's CA cert secret as a volume to Opni's gateway and mount it
extraVolumeMounts: 
- mountPath: /etc/ssl/certs
  name: sylva-ca
  readOnly: true
  secret:
    secretName: sylva-ca.crt

# Opni configuration for Sylva's Keycloak
openid:
  insecureSkipVerify: '{{ .Values.cluster.opni.gateway.auth.openid.insecureSkipVerify | default false | include "as-bool" }}'
  identifyingClaim: '{{ .Values.cluster.opni.gateway.auth.openid.identifyingClaim | default "sub" }}'
  scopes: ["openid", "profile", "email", "offline_access", "roles"]
  roleAttributePath: "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'"
  wellKnownConfiguration:
    issuer: "https://{{ .Values.cluster.keycloak.external_hostname }}/realms/sylva"
    authorization_endpoint: "https://{{ .Values.cluster.keycloak.external_hostname }}/realms/sylva/protocol/openid-connect/auth"
    token_endpoint: "https://{{ .Values.cluster.keycloak.external_hostname }}/realms/sylva/protocol/openid-connect/token"
    userinfo_endpoint: "https://{{ .Values.cluster.keycloak.external_hostname }}/realms/sylva/protocol/openid-connect/userinfo"
    jwks_uri: "https://{{ .Values.cluster.keycloak.external_hostname }}/realms/sylva/protocol/openid-connect/certs"

# Secrets from where the 'opni' unit will retrieve the clientID and clientSecret
# for the Keycloak client created by the 'opni-keycloak-resources' unit
valuesFrom:
- kind: Secret
  name: opni-oidc-auth
  valuesKey: clientID
  targetPath: gateway.auth.openid.clientID
- kind: Secret
  name: opni-oidc-auth
  valuesKey: clientSecret
  targetPath: gateway.auth.openid.clientSecret
