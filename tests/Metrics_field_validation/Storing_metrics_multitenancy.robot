*** Settings ***
Resource          ../keywords/keywords.robot
Resource          ../keywords/influx-grafana_keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/KafkaClient.py
Library           ../libs/InfluxClient.py
Library           ../libs/ExtendDictionary.py
Library           Collections

#pybot -v apikey:  -v tenant_id: -v apikey_demo:  -v tenant_id_demo: src/tests/Metrics_field_validation

#Suite Setup   Run Keywords   User send POST request to keystone for demo user  User send POST request to keystone for main user
Test Setup   Run Keywords   Get datetime  Getting the time in milliseconds
Suite Setup   Run Keywords   Set variables for metrics

#Test Setup  Run Keywords   Create Databases

#Suite Teardown  Run Keywords   Drop series ${metric} from tenant_${tenant_id}
#Suite Teardown  Run Keywords   Drop series ${metric_1} from tenant_${tenant_id}
#Suite Teardown  Run Keywords   Drop series ${metric_2} from tenant_${tenant_id}
#Test Setup     Run Keywords    Drop database for specific tenant '${tenant_id}'
#Test Teardown  Run Keywords    Drop database for specific tenant '${tenant_id}'
#Suite Teardown  Run Keywords   Drop database for specific tenant '${tenant_id}'

*** Test Cases ***
Each metric type from each tenant is stored in a separate table in InfluxDB
    [Tags]    ITC-M-6  positive  multitenancy  storm_migration_TC
    #two metrics are sent from different tenants
    ${json_1}    Create Dictionary  host=qa-test-node  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    ${json_2}    Create Dictionary  host=qa-test-node2  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey_demo}  tenant_id=${tenant_id_demo}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json_1}
    Send Message To Kafka    metricTopic  ${json_2}
    Sleep    15
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id_demo}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Users can save metrics with double value when '.' is used
    [Tags]    ITC-M-6a  positive  multitenancy  storm_migration_TC
    #two metrics are sent from different tenants
    ${value1}   Set variable    ${time_ms}.56
    ${value2}   Set variable    ${time_ms}.12
    ${json_1}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric}","value":${value1},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    ${json_2}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node2","name":"${metric}","value":${value2},"tenant_id":"${tenant_id_demo}","apikey":"${apikey_demo}"}
    Send Message To Kafka    metricTopic  ${json_1}
    Send Message To Kafka    metricTopic  ${json_2}
    Sleep    15
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}/ where value=${value1}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}/ where value=${value2}
    ${result}  Querying Data From Influx  tenant_${tenant_id_demo}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Users cannot save metrics with double value when ',' is used
    [Tags]    ITC-M-6b  negative  multitenancy  storm_migration_TC
    #two metrics are sent from different tenants
    ${value1}   Set variable    ${time_ms},33
    ${value2}   Set variable    ${time_ms},338
    ${json_1}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric}_data","value":${value1},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    ${json_2}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node2","name":"${metric}_data","value":${value2},"tenant_id":"${tenant_id_demo}","apikey":"${apikey_demo}"}
    Send Message To Kafka    metricTopic  ${json_1}
    Send Message To Kafka    metricTopic  ${json_2}
    Sleep    15
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}_data/
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}_data/
    ${result}   Querying Data From Influx  tenant_${tenant_id_demo}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})

User can send more then one metric to InfluxDB and they will be stored
    [Tags]    ITC-M-9    positive  smoke   multitenancy  zk_migration_TC  kafka_migration_TC
    ${time_ms_1}  Set Variable  ${time_ms}
    ${json_1}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric_1}","value":${time_ms_1},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    ${json_2}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric_2}","value":${time_ms_1},"tenant_id":"${tenant_id_demo}","apikey":"${apikey_demo}"}
    Send Message To Kafka  metricTopic  ${json_1}
    Send Message To Kafka  metricTopic  ${json_2}
    Sleep  1
    Get datetime 
    Getting the time in milliseconds
    ${time_ms_2}  Set Variable  ${time_ms}
    ${json_1}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric_1}","value":${time_ms_2},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    ${json_2}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric_2}","value":${time_ms_2},"tenant_id":"${tenant_id_demo}","apikey":"${apikey_demo}"}
    Send Message To Kafka    metricTopic  ${json_1}
    Send Message To Kafka    metricTopic  ${json_2}
    Sleep    30
    #--------------------------------------------------------------
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric_1}/ where value = ${time_ms_1} or value = ${time_ms_2}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_1}', None)': [{u'count': 2, u'time': u'1970-01-01T00:00:00Z'}]})
    #--------------------------------------------------------------
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric_2}/ where value = ${time_ms_2} or value = ${time_ms_1}
    ${result}  Querying Data From Influx  tenant_${tenant_id_demo}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_2}', None)': [{u'count': 2, u'time': u'1970-01-01T00:00:00Z'}]})

#User can't start storing metrics for the tenant he has no permissions for
#    [Tags]    ITC-M-8

*** Keywords ***
Set variables for metrics
    Set Global Variable    ${metric}    qa.test.if_errors
    Set Global Variable    ${metric_1}    qa.interface_test.collectd_type.if_errors
    Set Global Variable    ${metric_2}    qa.cpu_test.3.cpu

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

Drop series ${series} from ${db}
    Delete Influx Series  ${db}  ${series}

Drop Databases
    Delete Influx Database  tenant_${tenant_id}
    Delete Influx Database  tenant_${tenant_id_demo}

Create Databases
   Create Influx Database  tenant_${tenant_id}
   Create Influx Database  tenant_${tenant_id_demo}
   ${res}  Get Database List From Influx