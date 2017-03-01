*** Settings ***
Resource          settings.robot
Library           ../libs/ExtendDictionary.py
Library             ../libs/Additional.py

#Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords   Get date and _index for Elasticsearch (Y.M.D)   Create ES body
Test Setup   Run Keywords    Clear index in elasticsearch
Suite Teardown   Run Keywords    Clear index in elasticsearch

*** Test Cases ***
Get information on cluster health
    [Tags]  Graph-0.1  positive  es_migration_TC  ui_migration_TC
#    Set Headers    {"X-Auth-token": "${PKI_TOKEN}", "X-Tenant": "${TENANT}","Content-Type": "application/json"}
    Set Global Variable    ${url}    ${kibana_node}/elasticsearch/_nodes
    Set Global Variable    ${method}    GET
    GET Request    ${url}
    ${response_body}    Get Response Body
    LOG   ${response_body}
    Dictionary Should Contain Key    ${response_body}   cluster_name
    Dictionary Should Contain Key    ${response_body}   nodes

Successful count of log messages in elasticsearch through proxy
    [Tags]  Graph-0.2  positive  es_migration_TC  ui_migration_TC
#    Set Headers    {"X-Auth-token": "${PKI_TOKEN}", "X-Tenant": "${TENANT}","Content-Type": "application/json"}
    Set Global Variable    ${url}    ${kibana_node}/elasticsearch/log-*/_search?search_type=count
    Set Global Variable    ${method}    GET
    GET Request    ${url}
    ${response_body}    Get Response Body
    LOG   ${response_body}
    Dictionary Should Contain Item    ${response_body['_shards']}    failed   0

Successful search request through proxy
    [Tags]  Graph-0.3  positive  es_migration_TC  ui_migration_TC
#    Set Headers    {"X-Auth-token": "${PKI_TOKEN}", "X-Tenant": "${TENANT}","Content-Type": "application/json"}
    Set Global Variable    ${url}    ${kibana_node}/elasticsearch/log-*/_search
    Set Global Variable    ${method}    GET
    GET Request    ${url}
    ${response_body}    Get Response Body
    LOG   ${response_body}
    Dictionary Should Contain Item  ${response_body['_shards']}    failed   0

There are correct mappings for elasticsearch
    [Tags]  Graph-0.4  positive  es_migration_TC  ui_migration_TC
#    Set Headers    {"X-Auth-token": "${PKI_TOKEN}", "X-Tenant": "${TENANT}","Content-Type": "application/json"}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Set Global Variable    ${url}    ${kibana_node}/elasticsearch/log-*/_mapping
    Set Global Variable    ${method}    GET
    GET Request    ${url}
    ${response_body}    Get Response Body
    LOG   ${response_body}
    ${keys}  Get Dictionary Keys    ${response_body}
    ${ind}    Set Variable    ${keys[0]}
    Dictionary Should Contain Key   ${response_body['${ind}']['mappings']['_default_']['dynamic_templates'][1]}    ints
    Dictionary Should Contain Key    ${response_body['${ind}']['mappings']['_default_']['dynamic_templates'][2]}   doubles
    Dictionary Should Contain Key    ${response_body['${ind}']['mappings']['_default_']['dynamic_templates'][3]}   booleans
    Dictionary Should Contain Key    ${response_body['${ind}']['mappings']['_default_']['dynamic_templates'][4]}   ips

#There is no failed shards in the cluster
#    [Tags]  Graph-0.5  positive  es_migration_TC  ui_migration_TC
#    Set Headers    {"X-Auth-token": "${PKI_TOKEN}", "X-Tenant": "${TENANT}","Content-Type": "application/json"}
#    Set Global Variable    ${url}    ${kibana_node}:${ES_port}/elasticsearch/_search_shards
#    Set Global Variable    ${method}    GET
#    GET Request    ${url}
#    ${response_body}    Get Response Body
#    LOG   ${response_body}
#    Dictionary Should Contain Item    ${response_body['_shards']}   failed   0

Send one log message to ES and check it in Kibana
    [Tags]  Graph-1.1  positive  es_migration_TC  ks_migration_TC  ui_migration_TC  inprogress
    Get datetime
    ${message}   Set Variable   kibana_es case ${@timestamp}
    ${es_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}   @timestamp=${@timestamp}
    User Send Message To ES  /${ES_index}/logs/   ${es_dict}
    Sleep   90
    ${result}  Querying Data From Kibana  ${tenant_id}
    Remove From Dictionary    ${result[0]['_source']}    @timestamp  tags  messageId
    Remove From Dictionary   ${es_dict}  @timestamp
    Dictionaries Should Be Equal  ${result[0]['_source']}  ${es_dict}
    Length Should Be  ${result}  1

Post many log messages and check that count always the same
    [Tags]  Graph-1.2  es_migration_TC  ui_migration_TC
    :FOR  ${i}  IN RANGE  ${20}
    \    Get datetime
    \    ${message}   Set Variable   kibana_es case ${i+1} ${@timestamp}
    \    ${es_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}   @timestamp=${@timestamp}
    \    User Send Message To ES  /${ES_index}/logs/   ${es_dict}
    \    Wait Until Keyword Succeeds  1 min  2 sec  Check index size  ${i+1}

*** Keywords ***
Check index size  [Arguments]  ${size}
      ${result}  Querying Data From Kibana  ${tenant_id}
      Length Should Be  ${result}  ${size}

Querying Data From Kibana  [Arguments]  ${id}
     Set Headers    {"X-Auth-token": "${PKI_TOKEN}", "X-Tenant": "${Tenant}"}
     Set Global Variable    ${url}    ${IP_web}/elasticsearch/openstack-${tenant_id}-${Y.M.D}/_search
     Log    "GET request on link ${url}"
     Set Global Variable    ${method}    POST
     ${body}  Convert To Dictionary     {"query":{"filtered":{"query":{"bool":{"should":[{"query_string":{"query":"*"}}]}},"filter":{"bool":{"must":[{"range":{"@timestamp":{"from":1418789244552,"to":"now"}}}]}}}},"highlight":{"fields":{},"fragment_size":2147483647,"pre_tags":["@start-highlight@"],"post_tags":["@end-highlight@"]},"size":500,"sort":[{"@timestamp":{"order":"desc"}},{"@timestamp":{"order":"desc"}}]}
     ${body}  Convert To Json  ${body}
     Set Body  ${body}
     POST Request    ${url}
     ${body}    Get Response Body
     [return]  ${body['hits']['hits']}

Count logs in ES_index
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Log   ${n}

Create body for es_request ('${key}', '${id}')
    Get datetime
    ${es_dict}   Create Dictionary     apikey=${key}  tenant_id=${id}  @timestamp=${@timestamp}
    Set Global Variable  ${es_dict}  ${es_dict}
    [Return]  ${es_dict}

Create ES body
    ${es_dict}   Create body for es_request ('${apikey}', '${tenant_id}')
    Set Global Variable    ${es_dict_main}    ${es_dict}