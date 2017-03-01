*** Settings ***
Resource          keywords.robot
Resource          variables_keywords.robot
Resource          prepopulate_data.robot
Library           ../libs/ExtendDictionary.py
Library           ../libs/OperatingSystem.py

*** Variables ***
${es_url}     http://${es_master_node}:${es_port}
${kibana_url}   http://${kibana_node}:${kibana_port}
${index_with_patterns}   .cf-kibana

${tenant_id}  d9840542280941c2b20a2b71d8f47c49
${apikey}     e97af0a6-4bf7-41b4-a489-d6545f5dd619

@{user1_tenants}   0b913d65b924449abadb98a7a35399d1        1dd50be286d6483f8f9c9abdadaa2b9f        48a3895748314381853aae4bbdf1e3de        d9840542280941c2b20a2b71d8f47c49
@{user1_apikey}    b93ccc93-9a35-4986-9d5d-195a75348ff2    350d4ac5-1a4b-42f7-93e8-e1c7b4afba0a    2c71a4ea-4ee3-48b6-ac2b-0b91bd600636    e97af0a6-4bf7-41b4-a489-d6545f5dd619
@{user2_tenants}   534f8bd7882049ee9bc09379c34e7da1        6e9bdf030e154d4db3fca7fed974bc8e        8afeb90e049741a8a044c905bb6f3275        d9840542280941c2b20a2b71d8f47c49 
@{user2_apikey}    4ba31b8a-38bb-443d-8619-b6be17e2cf05    43afb0d5-0ee0-43d3-b319-3892578cc85b    afe5e75b-5e29-4f0d-994c-be36dbf54f94    e97af0a6-4bf7-41b4-a489-d6545f5dd619


*** Keywords ***
Delete all data from ES
    Execute DELETE request to '${es_url}/*' with credentials user='${sudo_user}' pass='${sudo_pass}'
    ${response_body}    Get Response Body
    Sleep  1

Apply filter (create searchguard index)
    ${stdout}  Run  cat src/tests/SearchGuard/config.json
    Log  ${stdout}
    ${stdout}  Run  curl -u${sudo_user}:${sudo_pass} -XPUT '${es_url}/searchguard/ac/ac?pretty' -d '${stdout}'
    Log  ${stdout}
    Should Contain  ${stdout}   \"created\" : true
    Sleep  15

Getting the time in milliseconds
    ${ms}=    Evaluate    int(round(time.time() * 1000))    time
    log    time in ms: ${ms}
    Set Global Variable    ${time_ms}    ${ms}

Execute GET request to '${path}' with credentials user='${user}' pass='${pass}'
    ${method}   Set Variable    GET
    Log    "GET request on link ${path}"
    GET Request With Auth    ${path}   ${user}   ${pass}

Execute DELETE request to '${path}' with credentials user='${user}' pass='${pass}'
    Set Headers    {"Content-Type": "application/json", "kbn-xsrf-token": "kibana"}
    ${method}   Set Variable    DELETE
    Log    "DELETE request on link ${path}"
    DELETE Request With Auth    ${path}   ${user}   ${pass}

Execute DELETE request with '${body}' to '${path}' with credentials user='${user}' pass='${pass}'
    Set Headers    {"Content-Type": "application/json", "kbn-xsrf-token": "kibana"}
    ${method}   Set Variable    DELETE
    Log    "DELETE request on link ${path}"
    Set Body  ${body}
    DELETE Request With Auth    ${path}   ${user}   ${pass}

Execute POST request to '${path}' with credentials user='${user}' pass='${pass}' with '${body}'
    Set Headers    {"Content-Type": "application/json", "kbn-xsrf-token": "kibana"}
    ${method}   Set Variable    POST
    Log    "POST request on link ${path}"
    Set Body  ${body}
    POST Request With Auth    ${path}   ${user}   ${pass}

Delete kibana patterns from ES
    ${len1}  get length  ${user1_tenants}
    ${len2}  get length  ${user2_tenants}
    : FOR  ${i}  IN RANGE  ${len1}
    \   Execute DELETE request to '${es_url}/${index_with_patterns}/index-pattern/logs-${user1_tenants[${i}]}-*/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    \   ${response_body}    Get Response Body
    \   Execute DELETE request to '${es_url}/${index_with_patterns}/index-pattern/logs-${user1_tenants[${i}]}-${Y-M-D}/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    \   ${response_body}    Get Response Body
    \   Sleep  1
    : FOR  ${i}  IN RANGE  ${len2}
    \   Execute DELETE request to '${es_url}/${index_with_patterns}/index-pattern/logs-${user2_tenants[${i}]}-*/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    \   ${response_body}    Get Response Body
    \   Execute DELETE request to '${es_url}/${index_with_patterns}/index-pattern/logs-${user2_tenants[${i}]}-${Y-M-D}/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    \   ${response_body}    Get Response Body
    \   Sleep  1
    Sleep  5

