*** Settings ***
Resource          settings.robot

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup   Run Keywords  Getting the time in milliseconds  Create variables
Test Setup  Run Keywords  Drop database for specific tenant '${tenant_id}'
Test Teardown  Run Keywords  Drop database for specific tenant '${tenant_id}'
Suite Teardown  Run Keywords  Drop database for specific tenant '${tenant_id}'

*** Test Cases ***
Send one log message to Influx and check it in Grafana
    [Tags]  Graph-2.1  positive  smoke  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    Get datetime
    Create Influx Database  tenant_${tenant_id}
    Write Data To Influx  tenant_${tenant_id}  [{"measurement": "${metric_name}","tags": {"host": "server_${metric_name}","region": "mtv"},"time": "${@timestamp}","fields": {"value": ${time_ms}}}]
    ${search_req}    Set variable    select+*+from+${metric_name}_+(${Tenant})+where+value=${time_ms}
    Sleep  5
    User send GET request to Graphana with body 'q=${search_req}', ${PKI_Token} for '${Tenant}'
    The response code should be 200
    The response body of GET 'value' from InfluxDB has 'points' with value "${time_ms}"

Get data from Grafana to verify that all metrics are accessible
    [Tags]  Graph-2.2  positive  critical  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    Create Influx Database  tenant_${tenant_id}
    :FOR    ${i}    IN RANGE    ${30}
    \   Get datetime
    \   Write Data To Influx  tenant_${tenant_id}  [{"measurement": "${metric_name}","tags": {"host": "server_${metric_name}","region": "mtv"},"time": "${@timestamp}","fields": {"value": ${time_ms}}}]
    \   Sleep  1
    ${search_req}    Set variable    select+*+from+${metric_name}_+(${Tenant})
    :FOR  ${i}  IN RANGE  ${5}
    \   ${result}  Querying Data From Graphana  ${search_req}
    \   Length Should Be  ${result[0]["points"]}  ${30}
    \   Sleep  2

#Get _1w, _1m, _3m tables from Grafana to verify that all data are accessible
#    [Tags]  Graph-2.3  positive  smoke  influx_migration_TC  kafka_migration_TC  ui_migration_TC  progress
#    : FOR  ${arg}  IN  @{affix}
#    \    Getting the time in milliseconds
#    \    Write Data To Influx  ${db_name}  [{"name":"${metric_name}_${arg}","columns":["mean", "sequence_number"],"points":[[${time_ms}, 1]]}]
#    \    ${result}  Querying Data From Graphana  select+*+from+${metric_name}__${arg}+(${Tenant})
#    \    Length Should Be  ${result[0]["points"]}  ${1}
#    \    ${ind}  Get Index From List  ${result[0]['columns']}  mean
#    \    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  ${time_ms}

*** Keywords ***
Create variables
   Set global variable  ${metric_name}   qa.influx_grafana_test

Querying Data From Graphana  [Arguments]  ${search_req}
     User send GET request to Graphana with body 'q=${search_req}', ${PKI_TOKEN} for '${Tenant}'
     ${body}    Get Response Body
     [return]  ${body}

#User send POST request to keystone for demo user
#    User sends POST request to keystone with '${keystone_demo_v3}'
#    The response code should be 201
#    User saves PKI_TOKEN from keystone
#    Set Global Variable    ${PKI_Tenant_demo}    ${PKI_TOKEN}
#    Get APIKEY for '${Tenant_demo}' with '${PKI_Tenant_demo}'
#    The response code should be 200
#    User saves APIKEY
#    Set Global variable    ${apikey_demo}    ${apikey}
#    User saves tenant_id
#    Set Global variable    ${tenant_id_demo}    ${tenant_id}

User send POST request to keystone for main user
    User sends POST request to keystone with '${keystone_v3}'
    The response code should be 201
    User saves PKI_TOKEN from keystone
    Set Global Variable    ${PKI_Tenant}    ${PKI_TOKEN}
    Get APIKEY for '${Tenant}' with '${PKI_Tenant}'
    The response code should be 200
    User saves APIKEY
    User saves tenant_id
