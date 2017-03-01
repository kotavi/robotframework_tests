*** Settings ***

Resource          ../keywords/keywords.robot
Resource          ../keywords/influx-grafana_keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/InfluxClient.py
Library           ../libs/KafkaClient.py

#Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords   Define variables
Test Setup  Run Keywords   Get datetime  Getting the time in milliseconds

*** Variables ***
${sleep_time}   60

*** Test Cases ***
Send metric to metricTopic and get it from InfluxDB
    [Tags]    ITC-M-1  positive  smoke  zk_migration_TC  storm_migration_TC
    ${json}    Create Dictionary  host=qa-test-node  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json}
    Sleep    ${sleep_time}
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Post metric to Kafka not in json format
    [Tags]    ITC-M-1a  negative  kafka_migration_TC
    Send Message To Kafka    metricTopic  sending_metric_1 ${datetime}
    Sleep    ${sleep_time}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}   ResultSet({})

Post metric to Kafka in wrong json format
    [Tags]    ITC-M-1b  negative  storm_migration_TC
    ${kafka_dict}  Create Dictionary  collectd_type=if_errors  rx=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  ""=cpu.test.3  times=${@timestamp}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep    ${sleep_time}
    ${search_req}    Set variable    SELECT COUNT(message) FROM notifications where message='MISSING_REQUIRED_FIELDS'
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}   ResultSet({})

Post metric to Kafka with invalid apikey
    [Tags]    ITC-M-2  negative  storm_migration_TC
    ${kafka_dict}    Create Dictionary  @version=1  @timestamp=${datetime}  host=${db_host}  name=cpu.test.3  plugin_instance=2  collectd_type=cpu  type_instance=wait  value=${time_ms}  tenant_id=${tenant_id}  apikey=${wrong_apikey}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep    ${sleep_time}
    ${search_req}    Set variable    SELECT COUNT(message) FROM notifications WHERE apikey='c72a9818'
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}   ResultSet({})
    ${search_req}    Set variable    SELECT * FROM notifications WHERE value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}   ResultSet({})

*** Keywords ***
Define variables
    Set Global Variable   ${db_host}    lmm_qa_test
    Set Global Variable   ${metric}     qa.interface.if_errors

Create Database
   Create Influx Database  tenant_${tenant_id}
   ${res}  Get Database List From Influx