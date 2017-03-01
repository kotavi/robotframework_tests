*** Settings ***
Library           String
Resource          keywords.robot
Resource          prepopulate_data.robot
Resource          log-based_keywords.robot

*** Keywords ***
Delete alerting metric delivery configuration with keystone credentials
    #Get data from keystone with '${keystone_v3}'
    User sends Delete request for alerting metric configuration rules for the "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}"

Put request to create alerting metric delivery configuration rules for a tenant_id with ${rule}
    #Get data from keystone with '${keystone_v3}'
    User create/update alerting metric delivery rules for a "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}" (with ${rule})
    The response code should be 200
    The response body should contain boolean "True" with "success"

Put request to create alerting callback metric delivery configuration rules for a tenant_id with ${rule}
    #Get data from keystone with '${keystone_v3}'
    User create/update alerting metric delivery rules for a "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}" (with ${rule})
    The response code should be 200
    The response body should contain boolean "True" with "success"

PUT request to create delivery list with predifined ${callback}
    #Get data from keystone with '${keystone_v3}'
    User send a PUT request to create alerting delivery rules (file ${callback}) with "${Tenant}"/"${tenant_id}" and "${PKI_TOKEN}"
    The response code should be 200
    The response body should contain boolean "True" with "success"

User create/update alerting metric delivery rules for a "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}" (with ${metric_rules})
    Set Headers    {"X-Tenant": "${Tenant}","X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    Set Global Variable    ${url}    ${IP_web}/${api_version}/metric_based_alert_rules_conf?tenant_id=${tenant_id}
    Log    "Put request on link ${url} with file ${metric_rules}"
    Set Global Variable    ${method}    PUT
    Set Body    ${metric_rules}
    Put request    ${url}

User sends GET request to get metric rules conf for the "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}"
    Set Headers    {"X-Tenant": "${Tenant}","X-Auth-token": "${PKI_TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/${api_version}/metric_based_alert_rules_conf?tenant_id=${tenant_id}
    Set Global Variable    ${method}    GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

User sends Delete request for alerting metric configuration rules for the "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}"
    Set Headers    {"X-Tenant": "${Tenant}","X-Auth-token": "${PKI_TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/${api_version}/metric_based_alert_rules_conf?tenant_id=${tenant_id}
    Set Global Variable    ${method}    DELETE
    Log    "DELETE request on link ${url}"
    DELETE Request    ${url}
