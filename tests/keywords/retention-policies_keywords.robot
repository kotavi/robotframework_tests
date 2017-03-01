*** Settings ***
Library           ../libs/simple_REST.py
Library           ../libs/ExtendDictionary.py
Resource          variables_keywords.robot
Resource          prepopulate_data.robot
Resource          log-based_keywords.robot

*** Keywords ***
User send a PUT request to create retention policy (file ${data}) with '${tenant_id}' and '${PKI_TOKEN}'
    Set Headers    {"X-Super-User": "True","X-Auth-token": "${PKI_TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/policy?tenant_id=${tenant_id}
    ${data}  Convert To Json  ${data}
    Log    "Put request on link ${url} with file ${data}"
    Set Global Variable    ${method}    PUT
    Set Body    ${data}
    Put request    ${url}

User sends GET request to get retention policy for the '${tenant_id}' and '${PKI_TOKEN}'
    Set Headers    {"X-Super-User": "True","X-Auth-token": "${PKI_TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/policy?tenant_id=${tenant_id}
    Set Global Variable    ${method}    GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

User sends Delete request for retention policy for '${tenant_id}'
    Set Headers    {"X-Tenant": "${Tenant}","X-Auth-token": "${PKI_TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/policy?tenant_id=${tenant_id}
    Set Global Variable    ${method}    DELETE
    Log    "DELETE request on link ${url}"
    DELETE Request    ${url}

Admin sends Delete request for retention policy for '${tenant_id}'
    Set Headers    {"X-Super-User": "True","X-Auth-token": "${PKI_TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/policy?tenant_id=${tenant_id}
    Set Global Variable    ${method}    DELETE
    Log    "DELETE request on link ${url}"
    DELETE Request    ${url}

The response body for get retention policy should be "${value}" with "${key}"
    ${body}    Get Response Body
    #${body}  Convert To Dictionary  ${body}
    ${body_value}    Convert To String    ${body${key}}
    Should Be Equal    ${body_value}    ${value}

