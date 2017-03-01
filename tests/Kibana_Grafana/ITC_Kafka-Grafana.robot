*** Settings ***
Resource          settings.robot

Suite Setup   Run Keywords   User send POST request to keystone for demo user  User send POST request to keystone for main user
Suite Setup   Run Keywords   Get datetime  Getting the time in milliseconds   Define variables

Test Teardown   Run Keywords   Drop created tables for metric "${metric}" with "${tenant_id}"
Test Teardown   Run Keywords   Drop created tables for metric "${metric_group}" with "${tenant_id}"

Suite Teardown   Run Keywords   Drop created tables for metric "${metric}" with "${tenant_id}"
Suite Teardown   Run Keywords   Drop created tables for metric "${metric_group}" with "${tenant_id}"

*** Test Cases ***
Check multitenancy between main user and demo user with different credentials
    [Tags]  Graph-4.0  positive  smoke  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    ${json_main}    Create Dictionary  host=qa-main-node  @version=1  name=${metric}  value=11111.11111  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json_main}
    ${json_demo}    Create Dictionary  host=qa-demo-node  @version=1  name=${metric}  value=22222.22222  apikey=${apikey_demo}  tenant_id=${tenant_id_demo}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json_demo}
    # search 1
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant})
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_Tenant}   ${Tenant}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  11111.11111
    # search 2. User from Tenant PKI_Tenant has no access to metrics of Tenant_demo
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant_demo})
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_Tenant}   ${Tenant}
    Should Contain   ${result}    Couldn't find series: _${metric}_
    # search 3. User from Tenant_demo PKI_Tenant_demo has access to metrics of Tenant
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant})
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_Tenant_demo}   ${Tenant}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  11111.11111
    # search 4. Does not depend on Tenant name
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant})
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_Tenant}   ${Tenant_demo}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  11111.11111
    # search 5. The same as for #1 but for demo user
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant_demo})
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_Tenant_demo}   ${Tenant_demo}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  22222.22222
    # search 6. Does not depend on Tenant name
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant_demo})
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_Tenant_demo}   ${Tenant}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  22222.22222

Send metric to metricTopic and get it from Grafana
    [Tags]  Graph-4.1  positive  smoke  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    ${json}    Create Dictionary  host=qa-test-node  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json}
    ${results}    Get Message From Kafka By key    metricTopic    {"@timestamp":"${@timestamp}"}
    Dictionaries Should Be Equal    ${results}  ${json}
    ${search_req}    Set variable    select * from ${tenant_id}_${metric}_
    ${result}  Wait Until Keyword Succeeds  1 min  5 sec  Get Data From Influx  ${search_req}  ${30}
    Log    ${result}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  ${time_ms}
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant})
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_TOKEN}   ${Tenant}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  ${time_ms}

Send bunch of metrics to metricTopic and check count via Grafana
    [Tags]  Graph-4.2  positive  critical  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    :FOR    ${i}    IN RANGE    ${10}
    \   Get datetime
    \   ${json}    Create Dictionary  host=qa-test-node  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    \   Send Message To Kafka    metricTopic  ${json}
    \   ${search_req}    Set variable    SELECT * FROM ${tenant_id}_${metric}_ where value=${time_ms}
    \   sleep  10
    \   ${result}  Wait Until Keyword Succeeds  1 min  5 sec  Get Data From Influx  ${search_req}  ${10}
    \   Length Should Be  ${result[0]["points"]}  ${1}
    \   ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant})
    \   ${response}  Querying Data From Graphana  ${search_req}  ${PKI_TOKEN}   ${Tenant}
    \   Length Should Be  ${response[0]["points"]}  ${i+1}

Send metric to metricTopic and get it from Grafana by time range
    [Tags]  Graph-4.3  positive  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    ${json}    Create Dictionary  host=qa-test-node  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json}
    ${search_req}    Set variable    select * from ${tenant_id}_${metric}_
    ${result}  Wait Until Keyword Succeeds  1 min  5 sec  Get Data From Influx  ${search_req}  ${30}
    Log    ${result}
    ${ind}  Get Index From List  ${result[0]['columns']}  time
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant})+where+time+>+${result[0]["points"][0][${ind}]-20}
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_TOKEN}   ${Tenant}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  ${time_ms}

Send metric to metricTopic and get from Grafana by time range (out of range)
    [Tags]  Graph-4.4  positive  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    ${json}    Set variable    {"host":"qa_test_node","@version":"1","name":"${metric}","value":${time_ms},"apikey":"${apikey}","tenant_id":"${tenant_id}","@timestamp":"${@timestamp}"}
    Send Message To Kafka    metricTopic   ${json}
    Sleep  2
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant})+where+time+>+now()+-+1s
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_TOKEN}   ${Tenant}
    Length Should Be  ${result}   0

Send metric to metricTopic with additional field (integer) and get from Grafana
    [Tags]  Graph-4.5  positive  critical  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    ${json}    Create Dictionary  host=qa-test-node  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}  additional_field=${10}
    Send Message To Kafka    metricTopic  ${json}
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant})
    Sleep   30
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_TOKEN}   ${Tenant}
    Log    ${result}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  ${time_ms}

Send metric to metricTopic with "group" in metric name and get from Grafana
    [Tags]  Graph-4.6  positive  critical  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    ${json}    Create Dictionary  host=qa-test-node  @version=1  name=${metric_group}  value=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json}
    ${search_req}    Set variable    select+*+from+${metric_group}_+(${Tenant})
    Sleep   30
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_TOKEN}   ${Tenant}
    Log    ${result}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  ${time_ms}

Send metric with different int view to metricTopic and get from Grafana
    [Tags]    Graph-4.7  positive  storm_migration_TC  LMM-1669
    ${kafka_dict}    Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric}","value":"7","tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${kafka_dict}    Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric}","value":-0490,"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${kafka_dict}    Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric}","value":080,"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    select+*+from+${metric}_+(${Tenant})
    Sleep   30
    ${result}  Querying Data From Graphana  ${search_req}  ${PKI_TOKEN}   ${Tenant}
    Log    ${result}
    ${ind}  Get Index From List  ${result[0]['columns']}  value
    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  7

*** Keywords ***
User send POST request to keystone for demo user
    User sends POST request to keystone with '${keystone_demo_v3}'
    The response code should be 201
    User saves tenant_id
    Set Global variable    ${tenant_id_demo}    ${tenant_id}
    User saves PKI_TOKEN from keystone
    Set Global Variable    ${PKI_Tenant_demo}    ${PKI_TOKEN}
    Get APIKEY for '${Tenant_demo}' with '${PKI_Tenant_demo}'
    The response code should be 200
    User saves APIKEY
    Set Global variable    ${apikey_demo}    ${apikey}

User send POST request to keystone for main user
    User sends POST request to keystone with '${keystone_v3}'
    The response code should be 201
    User saves tenant_id
    User saves PKI_TOKEN from keystone
    Set Global Variable    ${PKI_Tenant}    ${PKI_TOKEN}
    Get APIKEY for '${Tenant}' with '${PKI_Tenant}'
    The response code should be 200
    User saves APIKEY

Define variables
    Set Global Variable   ${metric}   qa.test_kafka_graphana
    Set Global Variable   ${metric_group}   ${metric}.group

Get Data From Influx  [Arguments]  ${search_req}  ${sleep}
    :FOR    ${i}    IN RANGE    ${sleep}
    \    ${res}  Querying Data From Influx   ${db_name}  ${search_req}
    \    Run Keyword Unless    ${res} == []    Exit For Loop
    [Return]  ${res}

Querying Data From Graphana  [Arguments]  ${search_req}  ${pki}  ${ten}
     User send GET request to Graphana with body 'q=${search_req}', ${pki} for '${ten}'
     ${body}    Get Response Body
     Log  ${body}
     [return]  ${body}
