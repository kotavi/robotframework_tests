*** Settings ***
Documentation     Is used when there is no keystone available. But tenant_id, apikey are needed to execute tests.
Resource          ../tests/keywords/keywords.robot
Resource          ../tests/keywords/variables_keywords.robot
Resource          ../tests/keywords/prepopulate_data.robot
Resource          ../tests/keywords/influx-grafana_keywords.robot
Library           ../tests/libs/simple_REST.py
Library           ../tests/libs/ElasticSearchClient.py
Library           ../tests/libs/KafkaClient.py
Library           ../tests/libs/InfluxClient.py

Suite Setup  Run Keywords    Delete index in elasticsearch
#Drop created tables
Test Teardown  Run Keywords     Delete index in elasticsearch
#Drop created tables
Test Setup   Run Keywords   Get datetime  Getting the time in milliseconds   Get date and _index for Elasticsearch (Y.M.D)


*** Variables ***
${apikey}      123-456-789
${tenant_id}   123456789

#------------------------------------------------
${metric_name}  cpu.test.1
${instance_type}  wait
${metric_1}      qa.interface_test.collectd_type.if_errors
${metric_2}      qa.cpu_test.3.cpu
${metric}      qa.interface.if_errors

*** Test Cases ***
Post log message with name pattern int
    [Tags]    kafka_es
    ${message}    Set Variable    With field {}_int ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_int=${34}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    5
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern double
    [Tags]    kafka_es
    Get date and _index for Elasticsearch (Y.M.D)
    ${message}    Set Variable    With field {}_double ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_int=${34}  some_double=${3.4}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    5
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern boolean
    [Tags]    kafka_es
    ${message}    Set Variable    With field {}_bool ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_int=${0}  some_double=${0.0}  some_boolean=${True}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    5
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Send metric to metricTopic and get it from InfluxDB
    [Tags]    kafka_influx
    ${json}    Create Dictionary  host=qa-test-node  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json}
    ${results}    Get Message From Kafka By key    metricTopic    {"@timestamp":"${@timestamp}"}
    Dictionaries Should Be Equal    ${results}  ${json}
    Sleep    20
    ${search_req}    Set variable    SELECT COUNT (name) FROM /${metric}/ where value=${time_ms}
    ${result}  Querying Data From Influx  ${db_name}  ${search_req}
    Should Be Equal As Strings  ${result[0]["points"][0][1]}  1

User can send more then one metric to InfluxDB and they will be stored
    [Tags]    kafka_influx
    ${time_ms_1}  Set Variable  ${time_ms}
    ${json_1}    Create Dictionary     host=qa-test-node  @version=1  name=${metric_1}  value=${time_ms_1}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    ${json_2}    Create Dictionary     host=qa-test-node  @version=1  @timestamp=${@timestamp}  name=${metric_2}  value=${time_ms_1}  tenant_id=${tenant_id}  apikey=${apikey}
    Send Message To Kafka  metricTopic  ${json_1}
    Send Message To Kafka  metricTopic  ${json_2}
    Get datetime
    Getting the time in milliseconds
    ${time_ms_2}  Set Variable  ${time_ms}
    ${json_1}    Create Dictionary   host=qa-test-node  @version=1  name=${metric_1}  value=${time_ms_2}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    ${json_2}    Create Dictionary   host=qa-test-node  @version=1  @timestamp=${@timestamp}  name=${metric_2}  value=${time_ms_2}  tenant_id=${tenant_id}  apikey=${apikey}
    Send Message To Kafka    metricTopic  ${json_1}
    Send Message To Kafka    metricTopic  ${json_2}
    Sleep    20
    #--------------------------------------------------------------
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric_1}/ where value = ${time_ms_1}
    ${result}  Querying Data From Influx  ${db_name}  ${search_req}
    Should Be Equal As Strings  ${result[0]["points"][0][1]}  2
    #--------------------------------------------------------------
    ${search_req}    Set variable    SELECT COUNT (name) FROM /${metric_2}/ where value = ${time_ms_2}
    ${result}  Querying Data From Influx  ${db_name}  ${search_req}
    Should Be Equal As Strings  ${result[0]["points"][0]}  [0, 2]

Load Influx with metrics
    [Tags]    load_influx
    : FOR    ${index}    IN RANGE    100
    \    Get datetime
    \    Getting the time in milliseconds
    \    Sleep   1
    \    ${json_1}    Create Dictionary   host=qa-test-node  @version=1  name=${metric_1}  value=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    \    Send Message To Kafka    metricTopic  ${json_1}
    Sleep    2
    #--------------------------------------------------------------
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric_1}/
    ${result}  Querying Data From Influx  ${db_name}  ${search_req}
    Should Be Equal As Strings  ${result[0]["points"][0][1]}  100

*** Keywords ***
Delete index in elasticsearch
    Delete Index From Es    openstack-123456789-2015.03.02

Querying Data From Influx And Find message  [Arguments]  ${search_req}  ${req}
    ${result}  Querying Data From Influx  ${db_name}  ${search_req}
    ${res}  Find messages in influx response where  ${req}  ${result}
    [Return]  ${res}