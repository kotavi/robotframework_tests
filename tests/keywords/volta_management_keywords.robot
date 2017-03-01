*** Settings ***
Resource          ../keywords/keywords.robot
Library           String
Library           Collections
Library           ../libs/simple_REST.py
Library           ../libs/KafkaClient.py
Library           ../libs/OperatingSystem.py
Library           ../libs/ExtendDictionary.py
Resource          ../micro_services/keywords/variables_settings.robot

*** Keywords ***
Delete S3 data
    Send DELETE request to S3 with username  ${LS_url_path}/s3?bucketName=${bucketName}   ${sudo_user}
    The response code should be 200

Get the LDAP groups that user belongs to
    Send GET request with token  ${url_gateway}/userGroups  ${token}  ${hmac}
    The response code should be 200
    ${response_body}    Get Response Body
    Set Global Variable  ${sudo_ldap_groups}  ${response_body}
    Log   ${token}
    Log   ${hmac}

Get credentials for '${user}', '${login}'
    ${json}  Set Variable  {"username":"${user}","password":"${login}"}
    ${stdout}  Run  curl -k -XPOST -d '${json}' ${url_token} -H "Content-Type:application/json" > token.txt
    ${stdout}  Run  cat token.txt
    ${stdout}  Convert To Dictionary  ${stdout}
    Set Global Variable  ${token}   ${stdout[0]["X-Subject-Token"]}
    Set Global Variable  ${hmac}   ${stdout[0]["HMAC"]}

Execute precondition
    Get credentials for '${sudo_user}', '${sudo_pass}'
    Get the LDAP groups that user belongs to
    Set Global Variable  ${token_sudo}   ${token}
    Set Global Variable  ${hmac_sudo}   ${hmac}
    Set Global Variable  ${ldap_groups_sudo}   ${sudo_ldap_groups}

Create body for creating tenant
    [Arguments]  ${tenant_name}  ${id_service}  ${role_id}  ${id_idm_group}  ${email}
    ${role}  set variable  {"role_id":"${role_id}","idm_group_id":"${id_idm_group}","tenant_email":"tenant_${email}@gmail.com"}
    ${body}  Set Variable  {"tenant_name":"${tenant_name}","service_id":"${service_id}","roles":[${role}]}
    Log   ${body}
    [Return]  ${body}  ${role}

Send POST request to "${path}" with "${body}"
    Set Headers    {"Content-type":"application/json"}
    Set Global Variable   ${request_body}   ${body}
    Set Global Variable   ${url}   ${path}
    Set Global Variable   ${method}   POST
    Log    "POST request on link ${url} with body ${request_body}"
    Set Body    ${request_body}
    POST Request    ${url}

Send POST request with token
    [Arguments]   ${path}  ${body}  ${token}  ${hmac}
    Log   ${token}
    Log   ${hmac}
    Set Headers    {"x-subject-token":"${token}","hmac":"${hmac}","Content-Type":"application/json"}
    ${method}   Set Variable   POST
    Log    "POST request on link ${path} with body ${body}"
    Set Body    ${body}
    POST Request    ${path}

#group header is needed for post and put tenant requests
Send POST request with token and group headers
    [Arguments]  ${path}  ${body}  ${group}  ${token}  ${hmac}
    ${header}  Set Variable  {"Content-type":"application/json","Group":"${group}","x-subject-token":"${token}","hmac":"${hmac}"}
    Log  ${header}
    Set Headers    ${header}
    Set Global Variable   ${request_body}   ${body}
    Set Global Variable   ${url}   ${path}
    Set Global Variable   ${method}   POST
    Log    "POST request on link ${url} with body ${request_body}"
    Set Body    ${request_body}
    POST Request    ${url}

User can send GET request to retreive info for specific tenant
    [Arguments]  ${path}  ${role}  ${tenant_id}  ${username}
    ${header}  Set Variable  {"Content-Type":"application/json","Role_${tenant_id}":"${role}","Username":"${username}"}
    Log  ${header}
    Set Headers    ${header}
    ${method}   Set Variable    GET
    Log    "GET request on link ${path}"
    GET Request    ${path}

Send GET request to retreive information specific tenant
    [Arguments]  ${path}  ${role}  ${tenant_id}  ${Username}
    ${header}  Set Variable  {"Content-type":"application/json","Role_${tenant_id}":"${role}","Username":"${Username}"}
    Log  ${header}
    Set Headers    ${header}
    Set Global Variable   ${url}    ${path}
    Set Global Variable   ${method}   GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

Send GET request with token
    [Arguments]   ${path}  ${token}  ${hmac}
    Set Headers    {"x-subject-token":"${token}","hmac":"${hmac}"}
    ${method}  Set Variable    GET
    Log    "GET request on link ${path}"
    GET Request    ${path}

Send GET request to S3 with username
    [Arguments]   ${path}  ${Username}
    Set Headers    {"Content-type":"application/json","Username":"${Username}"}
    ${method}  Set Variable    GET
    Log    "GET request on link ${path}"
    GET Request    ${path}

Send PUT request with role
    [Arguments]  ${path}  ${role}  ${tenant_id}  ${body}  ${group}  ${Username}
    ${header}  Set Variable  {"Content-type":"application/json","Role_${tenant_id}":"${role}","Group":"${group}","Username":"${Username}"}
    Log  ${header}
    Set Headers    ${header}
    Set Global Variable   ${request_body}   ${body}
    Set Global Variable   ${url}   ${path}
    Set Global Variable   ${method}   PUT
    Log    "PUT request on link ${url} with body ${request_body}"
    Set Body    ${request_body}
    PUT Request    ${url}

Send PUT request with token
    [Arguments]   ${path}  ${body}  ${token}  ${hmac}
    ${header}  Set Variable  {"Content-type":"application/json","x-subject-token":"${token}","hmac":"${hmac}"}
    Log  ${header}
    Set Headers    ${header}
    Set Global Variable   ${request_body}   ${body}
    Set Global Variable   ${url}   ${path}
    Set Global Variable   ${method}   PUT
    Log    "PUT request on link ${url} with body ${request_body}"
    Set Body    ${request_body}
    PUT Request    ${url}

Send DELETE request with token
    [Arguments]   ${path}  ${token}  ${hmac}
    Set Headers    {"x-subject-token":"${token}","hmac":"${hmac}"}
    ${method}  Set Variable  DELETE
    Log    "DELETE request on link ${path}"
    DELETE Request    ${path}

Send DELETE request to S3 with username
    [Arguments]   ${path}  ${Username}
    Set Headers    {"Content-type":"application/json","Username":"${Username}"}
    ${method}  Set Variable    DELETE
    Log    "GET request on link ${path}"
    DELETE Request    ${path}