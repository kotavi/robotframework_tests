*** Settings ***
Resource          settings.robot
Library           ../libs/ExtendDictionary.py
Library           Collections
Library             ../libs/Additional.py

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords   Get date and _index for Elasticsearch (Y.M.D)
#Test Setup   Run Keywords    Clear index in elasticsearch
Test Setup   Run Keywords    Get datetime
#Test Teardown   Run Keywords    Clear index in elasticsearch

*** Test Cases ***
User from tenat1 cannot see logs from tenant2 if he is not a member of tenant2
    [Tags]  Graph-1.3   positive  multitenancy   smoke  kibana_migration_TC  es_migration_TC  ui_migration_TC
    Log To Console  -- Fails if other tenants that user has access to has data
    User send POST request to keystone for demo user
    ${ES_index_demo}  Set Variable    openstack-${tenant_id_demo}-${Y.M.D}
    Delete Index From Es    ${ES_index_demo}
    #-----send log to ES-----------------------------------
    ${message}   Set Variable   kibana_es multitenancy case ${@timestamp}
    ${es_dict}  Create Dictionary  apikey=${apikey_demo}  tenant_id=${tenant_id_demo}  message=${message}   @timestamp=${@timestamp}
    User Send Message To ES  /${ES_index_demo}/logs/   ${es_dict}
    Sleep   1
    #-----send log to Kafka---------------------------------
    Get datetime
    ${message}   Set Variable   kibana_es multitenancy case ${@timestamp}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_demo}  tenant_id=${tenant_id_demo}  message=${message}  @timestamp=${@timestamp}
    Send Message To Kafka    logTopic    ${kafka_dict}
    #-------------------------------------------------------
    Sleep   30
    ${result}  Wait Until Keyword Succeeds  1 min  5 sec   Querying Data From Kibana  ${tenant_id}  ${Tenant_demo}  ${PKI_TOKEN_demo}
    Length Should Be  ${result}  2
    Get data from keystone with '${keystone_v3}'
    ${result}  Wait Until Keyword Succeeds  1 min  5 sec   Querying Data From Kibana  ${tenant_id_demo}  ${Tenant}  ${PKI_TOKEN}
    Length Should Be  ${result}  0
    Delete Index From Es    ${ES_index_demo}

User from tenat1 cannot see metrics from tenant2 if he is not a member of tenant2
    [Tags]  Graph-2.4   positive  multitenancy  smoke  grafana_migration_TC  es_migration_TC  ui_migration_TC
    Getting the time in milliseconds
    User send POST request to keystone for demo user
    Create Influx Database  tenant_${tenant_id_demo}
    #-----send metric to Influx-----------------------------------
    ${metric_name}   Set variable  qa.influx_grafana_test_multitenancy
    Write Data To Influx  tenant_${tenant_id_demo}  [{"measurement": "${metric_name}","tags": {"host": "test-node-QA","region": "mtv"},"time": "${@timestamp}","fields": {"value": ${time_ms}}}]
    ${search_req}    Set variable    select+*+from+${metric_name}_+(${Tenant_demo})+where+value=${time_ms}
    #-----send metric to Kafka-----------------------------------
    ${json}    Create Dictionary  host=test-node-QA   name=${metric_name}  value=${time_ms}  apikey=${apikey_demo}  tenant_id=${tenant_id_demo}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json}
    #-------------------------------------------------------
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_TOKEN_demo}  ${Tenant_demo}
    Length Should Be  ${result[0]["points"]}  2
    Get data from keystone with '${keystone_v3}'
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_TOKEN}  ${Tenant}
    Should Be Equal As Strings  ${result}   Couldn't find series: _${metric_name}_
    Delete Influx Database  tenant_${tenant_id_demo}

*** Keywords ***
User send POST request to keystone for demo user
    User sends POST request to keystone with '${keystone_demo_v3}'
    The response code should be 201
    User saves PKI_TOKEN from keystone
    Set Global Variable    ${PKI_TOKEN_demo}    ${PKI_TOKEN}
    User saves tenant_id
    Set Global variable    ${tenant_id_demo}    ${tenant_id}
    Get APIKEY for '${Tenant_demo}' with '${PKI_TOKEN_demo}'
    The response code should be 200
    User saves APIKEY
    Set Global variable    ${apikey_demo}    ${apikey}

Querying Data From Kibana  [Arguments]  ${id_tenant}   ${user_tenant}  ${keystone_token}
     Set Headers    {"X-Auth-token": "${keystone_token}", "X-Tenant": "${user_tenant}"}
     LOG   ${keystone_token}
     LOG   ${user_tenant}
     Set Global Variable    ${url}    ${IP_web}/elasticsearch/openstack-*-${Y.M.D}/_search
     Log    "GET request on link ${url}"
     Set Global Variable    ${method}    POST
     ${body}  Convert To Dictionary     {"query":{"filtered":{"query":{"bool":{"should":[{"query_string":{"query":"*"}}]}},"filter":{"bool":{"must":[{"range":{"@timestamp":{"from":1418789244552,"to":"now"}}}]}}}},"highlight":{"fields":{},"fragment_size":2147483647,"pre_tags":["@start-highlight@"],"post_tags":["@end-highlight@"]},"size":500,"sort":[{"@timestamp":{"order":"desc"}},{"@timestamp":{"order":"desc"}}]}
     ${body}  Convert To Json  ${body}
     Set Body  ${body}
     POST Request    ${url}
     ${body}    Get Response Body
     [Return]  ${body['hits']['hits']}

Querying Data From Graphana  [Arguments]  ${search_req}  ${keystone_token}  ${user_tenant}
     Set Headers    {"X-Auth-token": "${keystone_token}", "X-Tenant": "${user_tenant}"}
     Set Global Variable    ${url}   ${IP_web}/influxdb/series?q=${search_req}
     Log    "GET request on link ${url}"
     Set Global Variable    ${method}    GET
     GET Request    ${url}
     ${body}    Get Response Body
     [return]  ${body}

Drop Database
    Delete Influx Database  tenant_${tenant_id}

Create Database
   Create Influx Database  tenant_${tenant_id}