*** Settings ***
Resource          ../keywords/keywords.robot
Resource          ../keywords/influx-grafana_keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/KafkaClient.py
Library           ../libs/InfluxClient.py
Library           Collections

#Suite Setup    Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords   Set variables for metrics
Suite Setup    Run Keywords   Get datetime  Getting the time in milliseconds
#Suite Teardown  Run Keywords   Drop series ${metric} from tenant_${tenant_id}
#Suite Teardown  Run Keywords   Drop series ${metric_1} from tenant_${tenant_id}
#Test Setup     Run Keywords    Drop database for specific tenant '${tenant_id}'  Create Database
#Test Teardown  Run Keywords    Drop database for specific tenant '${tenant_id}'
#Suite Teardown  Run Keywords   Drop database for specific tenant '${tenant_id}'

*** Variables ***
${sleep_time}   60

*** Test Cases ***
User can store metric with integer value in a separate table in InfluxDB
    [Tags]    ITC-M-6  positive  critical  storm_migration_TC  influx_migration_TC
    ${json_1}    Create Dictionary  host=qa-test-node  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json_1}
    Sleep    ${sleep_time}
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

User can send more then one metric to InfluxDB and they will be stored
    [Tags]    ITC-M-9    positive  smoke   zk_migration_TC  kafka_migration_TC
    ${time_ms_1}  Set Variable  ${time_ms}
    ${json_1}    Create Dictionary     host=qa-test-node  @version=1  name=${metric_1}  value=${time_ms_1}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka  metricTopic  ${json_1}
    Get datetime 
    Getting the time in milliseconds
    ${time_ms_2}  Set Variable  ${time_ms}
    ${json_2}    Create Dictionary   host=qa-test-node  @version=1  name=${metric_1}  value=${time_ms_2}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json_2}
    Sleep    ${sleep_time}
    #--------------------------------------------------------------
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric_1}/ where value = ${time_ms_1} or value = ${time_ms_2}
    ${result}  Querying Data From Influx  tenant_${tenant_id}   ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_1}', None)': [{u'count': 2, u'time': u'1970-01-01T00:00:00Z'}]})

*** Keywords ***
Set variables for metrics
    Set Global Variable    ${metric}    qa.test.if_errors
    Set Global Variable    ${metric_1}    qa.interface_test.collectd_type.if_errors
#
#Drop series ${series} from ${db}
#    Delete Influx Series  ${db}  ${series}
#
#Drop Database
#    Delete Influx Database  tenant_${tenant_id}
#
#Create Database
#   Create Influx Database  tenant_${tenant_id}
#   ${res}  Get Database List From Influx
