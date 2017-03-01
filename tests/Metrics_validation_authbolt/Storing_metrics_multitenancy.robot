*** Settings ***
Resource          metric_validation_keywords.robot

Test Setup   Run Keywords   Get datetime  Getting the time in milliseconds
Suite Setup   Run Keywords   Set variables for metrics
Suite Setup   Run Keywords  Create dictionary with roles  Create dictionary with services  Create dictionary with ldap_groups

Test Teardown  Run Keywords  Delete tenant '${tenant_id_1}'   Delete tenant '${tenant_id_2}'

Test Teardown  Run Keywords    Drop Databases for '${tenant_id_1}'
Test Teardown  Run Keywords    Drop Databases for '${tenant_id_2}'

*** Test Cases ***
Each metric from each tenant is stored in separate tables in InfluxDB
    [Tags]    ITC-Metric-validation-3.1  positive  multitenancy  storm_migration_TC
    ${tenant_id_1}  ${apikey_1}   Create tenant
    ${tenant_id_2}  ${apikey_2}   Create tenant
    #two metrics are sent from different tenants
    ${json_1}    Create Dictionary  host=qa-test-node  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey_1}  tenant_id=${tenant_id_1}  @timestamp=${@timestamp}
    ${json_2}    Create Dictionary  host=qa-test-node2  @version=1  name=${metric}  value=${time_ms}  apikey=${apikey_2}  tenant_id=${tenant_id_2}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json_1}
    Send Message To Kafka    metricTopic  ${json_2}
    Sleep    15
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id_1}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id_2}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Users can save metrics with double value when '.' is used
    [Tags]    ITC-Metric-validation-3.2  positive  multitenancy  storm_migration_TC
    ${tenant_id_1}  ${apikey_1}   Create tenant
    ${tenant_id_2}  ${apikey_2}   Create tenant
    #two metrics are sent from different tenants
    ${value1}   Set variable    ${time_ms}.56
    ${value2}   Set variable    ${time_ms}.12
    ${json_1}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric}","value":${value1},"tenant_id":"${tenant_id_1}","apikey":"${apikey_1}"}
    ${json_2}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node2","name":"${metric}","value":${value2},"tenant_id":"${tenant_id_2}","apikey":"${apikey_2}"}
    Send Message To Kafka    metricTopic  ${json_1}
    Send Message To Kafka    metricTopic  ${json_2}
    Sleep    15
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}/ where value=${value1}
    ${result}  Querying Data From Influx  tenant_${tenant_id_1}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}/ where value=${value2}
    ${result}  Querying Data From Influx  tenant_${tenant_id_2}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Users cannot save metrics with double value when ',' is used
    [Tags]    ITC-Metric-validation-3.3  negative  multitenancy  storm_migration_TC
    ${tenant_id_1}  ${apikey_1}   Create tenant
    ${tenant_id_2}  ${apikey_2}   Create tenant
    #two metrics are sent from different tenants
    ${value1}   Set variable    ${time_ms},33
    ${value2}   Set variable    ${time_ms},338
    ${json_1}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric}_data","value":${value1},"tenant_id":"${tenant_id_1}","apikey":"${apikey_1}"}
    ${json_2}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node2","name":"${metric}_data","value":${value2},"tenant_id":"${tenant_id_2}","apikey":"${apikey_2}"}
    Send Message To Kafka    metricTopic  ${json_1}
    Send Message To Kafka    metricTopic  ${json_2}
    Sleep    15
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}_data/
    ${result}   Querying Data From Influx  tenant_${tenant_id_1}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric}_data/
    ${result}   Querying Data From Influx  tenant_${tenant_id_2}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})

User can send more then one metric to InfluxDB and they will be stored
    [Tags]    ITC-Metric-validation-3.4    positive  smoke   multitenancy  zk_migration_TC  kafka_migration_TC
    ${tenant_id_1}  ${apikey_1}   Create tenant
    ${tenant_id_2}  ${apikey_2}   Create tenant
    ${time_ms_1}  Set Variable  ${time_ms}
    ${json_1}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric_1}","value":${time_ms_1},"tenant_id":"${tenant_id_1}","apikey":"${apikey_1}"}
    ${json_2}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric_2}","value":${time_ms_1},"tenant_id":"${tenant_id_2}","apikey":"${apikey_2}"}
    Send Message To Kafka  metricTopic  ${json_1}
    Send Message To Kafka  metricTopic  ${json_2}
    Sleep  1
    Get datetime 
    Getting the time in milliseconds
    ${time_ms_2}  Set Variable  ${time_ms}
    ${json_1}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric_1}","value":${time_ms_2},"tenant_id":"${tenant_id_1}","apikey":"${apikey_1}"}
    ${json_2}   Set variable    {"@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric_2}","value":${time_ms_2},"tenant_id":"${tenant_id_2}","apikey":"${apikey_2}"}
    Send Message To Kafka    metricTopic  ${json_1}
    Send Message To Kafka    metricTopic  ${json_2}
    Sleep    30
    #--------------------------------------------------------------
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric_1}/ where value = ${time_ms_1} or value = ${time_ms_2}
    ${result}  Querying Data From Influx  tenant_${tenant_id_1}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_1}', None)': [{u'count': 2, u'time': u'1970-01-01T00:00:00Z'}]})
    #--------------------------------------------------------------
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${metric_2}/ where value = ${time_ms_2} or value = ${time_ms_1}
    ${result}  Querying Data From Influx  tenant_${tenant_id_2}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_2}', None)': [{u'count': 2, u'time': u'1970-01-01T00:00:00Z'}]})

*** Keywords ***
Set variables for metrics
    Set Global Variable    ${metric}    qa.test.if_errors
    Set Global Variable    ${metric_1}    qa.interface_test.collectd_type.if_errors
    Set Global Variable    ${metric_2}    qa.cpu_test.3.cpu

Drop series ${series} from ${db}
    Delete Influx Series  ${db}  ${series}

Create Databases
   Create Influx Database  tenant_${tenant_id}
   Create Influx Database  tenant_${tenant_id_2}
   ${res}  Get Database List From Influx