*** Settings ***
Resource          keywords.robot

*** Keywords ***
Get data from keystone with '${body}'
    User sends POST request to keystone with '${body}'
    The response code should be 201
    User saves tenant_id
    User saves PKI_TOKEN from keystone
    Get APIKEY for '${Tenant}' with '${PKI_TOKEN}'
    User saves APIKEY
#    User saves tenant_id

User sends POST request to keystone with '${body}'
    Set Headers    {"Content-Type": "application/json"}
    ${request_body}    Set Variable    ${body}
    Set Global Variable    ${url}    https://${keystone_ip}/v3/auth/tokens?nocatalog
    Set Global Variable    ${method}    POST
    Log    "POST request on link ${url} with body ${request_body}"
    Set Body    ${request_body}
#    Should Be Equal As Strings  ${request_body}  1
    POST Request    ${url}

User saves PKI_TOKEN from keystone
    ${response_headers}    Get Response Headers
    Log    ${response_headers}
    Log    ${response_headers['X-Subject-Token']}
    Set Global Variable    ${PKI_TOKEN}    ${response_headers['X-Subject-Token']}

Get APIKEY for '${tenant_id}' with '${TOKEN}'
    #$ curl -XGET "http://$IP:80/get_apikey" -H "X-Tenant:$TENANT_ID_OR_NAME" -H "X-Auth-token:$PKI_TOKEN"
    Set Headers    {"X-Tenant": "${tenant_id}","X-Auth-token": "${TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/get_apikey?tenant=${tenant_id}
    Set Global Variable    ${method}    GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

Force to generate a new APIKEY for '${Tenant}' with '${PKI_TOKEN}'
    #$ curl -XGET "http://$IP:80/new_apikey" -H "X-Tenant:$TENANT_ID_OR_NAME" -H "X-Auth-token:$PKI_TOKEN"
    Set Headers    {"X-Tenant": "${Tenant}","X-Auth-token": "${PKI_TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/new_apikey
    Set Global Variable    ${method}    GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

User saves APIKEY
    ${response_body}    Get Response Body
    Log    ${response_body['apikey']}
    Set Global Variable    ${apikey}    ${response_body['apikey']}

#User saves tenant_id
#    ${response_body}    Get Response Body
#    Log    ${response_body['user_tenant']}
#    Set Global Variable    ${tenant_id}    ${response_body['user_tenant'][-32:]}

User saves tenant_id
    ${response_body}    Get Response Body
    Log    ${response_body['token']['project']['id']}
    Set Global Variable    ${tenant_id}    ${response_body['token']['project']['id']}
