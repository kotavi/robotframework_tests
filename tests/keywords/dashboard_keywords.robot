*** Settings ***
Library           ../libs/simple_REST.py
Library           ../libs/ExtendDictionary.py
Resource          keywords.robot
Resource          variables_keywords.robot

*** Keywords ***
User send a PUT request to save dashboard with '${name}' and '${body}' in '${ui}' (${keystone_token}, ${tenat_name})
    Set Headers    {"X-Auth-token": "${keystone_token}", "X-Tenant": "${tenat_name}","Content-Type": "application/json"}
    Set Global Variable    ${url}     ${IP_web}/elasticsearch/${ui}-int/dashboard/${name}
    Set Global Variable    ${method}    PUT
    ${res_body}  Convert To Dictionary     ${body}
    ${res_body}  Convert To Json  ${res_body}
    ${request_body}    Set Variable    ${res_body}
    Log    "PUT request on link ${url} with body ${request_body}"
    Set Body    ${request_body}
    PUT Request    ${url}

#{"query":{"query_string":{"query":"title:*"}},"facets":{"tags":{"terms":{"field":"tags","order":"term","size":50}}},"size":100,"sort":["_uid"]}
User can get list of dashboards in '${ui}' (${keystone_token}, ${tenant_user})
    ${body}   Set Variable    {"query":{"query_string":{"query":"title:*"}},"size":20}
    Set Headers    {"X-Auth-token": "${keystone_token}", "X-Tenant": "${tenant_user}","Content-Type": "application/json"}
    Set Global Variable    ${url}     ${IP_web}/elasticsearch/${ui}-int/dashboard/_search
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}

User can delete dashboard in '${ui}' with name '${name}' (${keystone_token}, ${tenant_user})
    Set Headers    {"X-Auth-token": "${keystone_token}", "X-Tenant": "${tenant_user}","Content-Type": "application/json"}
    Set Global Variable    ${url}     ${IP_web}/elasticsearch/${ui}-int/dashboard/${name}
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}

Delete item with '${id}' from '${ui}-int' index in elasticsearch
    Set Global Variable    ${url}     ${IP_web}/elasticsearch/${ui}-int/temp/${id}
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}

User can share temporary link to dashboard in '${ui}' with '${body}' (${keystone_token}, ${tenant_user})
    Set Headers    {"X-Auth-token": "${keystone_token}", "X-Tenant": "${tenant_user}","Content-Type": "application/json"}
    Set Global Variable    ${url}     ${IP_web}/elasticsearch/${ui}-int/temp
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}

User can follow the created link in '${ui}' for dashboard with '${id}' (${keystone_token}, ${tenant_user})
    Set Headers    {"X-Auth-token": "${keystone_token}", "X-Tenant": "${tenant_user}","Content-Type": "application/json"}
    Set Global Variable    ${url}     ${IP_web}/elasticsearch/${ui}-int/temp/${id}
    Set Global Variable    ${method}    GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

Create shareable link with '${id}' for '${ui}'
    ${url}   Set Variable    ${IP_web}/${ui}/src/index.html#dashboard/temp/${id}
    [Return]   ${url}

Create Dictionary of Successfull Dashboard Creation in '${ui}' with '${user_name}'
    ${bool_true}   Convert To Boolean   True
    ${int_1}   Convert To Integer   1
    ${response}  Create Dictionary  _type=dashboard  _id=${dash_name}  created=${bool_true}  _version=${int_1}  _index=${ui}-int_${user_name}
    [Return]   ${response}

Create Dictionary of Successfull Dashboard Deletion in '${ui}' with '${user_name}'
    ${bool_true}   Convert To Boolean   True
    ${int_2}   Convert To Integer   2
    ${response}  Create Dictionary  _type=dashboard  _id=${dash_name}  found=${bool_true}  _version=${int_2}   _index=${ui}-int_${username}
    [Return]   ${response}

Create Dictionary for temp link in '${ui}' with '${id}'
    ${bool_true}   Convert To Boolean   True
    ${int_1}   Convert To Integer   1
    ${response}  Create Dictionary  _type=temp  _id=${id}  ok=${bool_true}  _version=${int_1}  _index=${ui}-int
    [Return]   ${response}

Clear index in ES for '${ui}' dashboards '${user_name}'
    Delete Index From Es    ${ui}-int_${user_name}

