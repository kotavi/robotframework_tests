*** Settings ***
Resource        metric_validation_keywords.robot

Suite Setup   Run Keywords  Create dictionary with roles  Create dictionary with services  Create dictionary with ldap_groups
Suite Setup   Run Keywords  Create global tenant and apikey

Test Teardown  Run Keywords   Clear index in elasticsearch

Suite Setup  Run Keywords   Get date and _index for Elasticsearch (Y.M.D)
Test Setup  Run Keywords   Get datetime
Suite Teardown  Run Keywords   Clear index in elasticsearch  Delete tenant '${tenant_id_global}'
Suite Teardown  Run Keywords    Drop Databases for '${tenant_id_global}'
Suite Teardown  Run Keywords    Drop Databases for '${tenant_id}'


*** Variables ***
${metric_name}     metric_service

*** Test Cases ***
TC.1.1. Send event with correct credentials and retreive it from InfluxDB
    [Tags]  ITC-Metric-validation-1.1  positive
    Log To Console  tenant_id = ${tenant_id_global}; apikey = ${apikey_global}
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    ${value}    Generate Random String   3  [NUMBERS]
    ${name}  Set Variable  ${metric_name}_${value}
    : FOR  ${i}  IN RANGE  ${5}
    \   Get datetime
    \   ${kafka_dict}  Create Dictionary  apikey=${apikey_global}  tenant_id=${tenant_id_global}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    \   Send Message To Kafka    metricTopic    ${kafka_dict}
    \   Log To Console   ${kafka_dict}
    \   Sleep  ${0.1}
    Sleep  ${delay}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${name}', None)': [{u'count': 5, u'time': u'1970-01-01T00:00:00Z'}]})

TC.1.2. Event with wrong apikey is rejected by topology
    [Tags]  ITC-Metric-validation-1.2  negative
    Log To Console  tenant_id = ${tenant_id_global}; apikey = ${apikey_global}
    #---variables
    ${host_name}    Generate Random String   11  [LETTERS]
    ${value}    Generate Random String   3  [NUMBERS]
    ${name}  Set Variable  ${metric_name}_${value}
    #---send data to kafka
    ${kafka_dict}  Create Dictionary  apikey=${wrong_apikey}  tenant_id=${tenant_id_global}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Log To Console   ${kafka_dict}
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id_global}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${host_name}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})

TC.1.3. Event with deleted apikey is rejected by topology
    [Documentation]  Send event when apikey was deleted
    [Tags]  ITC-Metric-validation-1.3  negative
    ${tenant_id}  ${apikey}   Create tenant
    Log To Console  tenant_id = ${tenant_id}; apikey = ${apikey}
    #---variables
    ${host_name}    Generate Random String   11  [LETTERS]
    ${value}    Generate Random String   3  [NUMBERS]
    ${name}  Set Variable  ${metric_name}_${value}
    #---send data to kafka
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Log To Console   ${kafka_dict}
    Sleep  ${delay}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})
    #----delete apikey
    Delete apikey   ${apikey}  ${tenant_id}
    #---send data to kafka
    Get datetime
    ${host_name}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Log To Console   ${kafka_dict}
    Sleep  20
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${host_name}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})

TC.1.4. Event with deleted tenant is rejected by topology
    [Documentation]  Send event when tenant_id was deleted
    [Tags]  ITC-Metric-validation-1.4  negative
    ${tenant_id}  ${apikey}   Create tenant
    Log To Console  tenant_id = ${tenant_id}; apikey = ${apikey}
    #---variables
    ${host_name}    Generate Random String   11  [LETTERS]
    ${value}    Generate Random String   3  [NUMBERS]
    ${name}  Set Variable  ${metric_name}_${value}
    #---send data to kafka
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Log To Console   ${kafka_dict}
    Sleep  ${delay}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})
    #----delete tenant_id
    Delete tenant '${tenant_id}'
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Log To Console   ${kafka_dict}
    Sleep  20
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${host_name}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})

TC.1.4a. Send event when tenant with 3 apikeys was deleted
    [Tags]  ITC-Metric-validation-1.4a  negative
    ${tenant_id}  ${apikey_1}   Create tenant
    ${apikey_2}  Create apikey for '${tenant_id}'
    ${apikey_3}  Create apikey for '${tenant_id}'
    Log To Console  tenant_id = ${tenant_id}; apikey_1 = ${apikey_1}
    Log To Console  apikey_2 = ${apikey_2}; apikey_3 = ${apikey_3}
    sleep  ${delay}
    #---variables
    ${host_name}    Generate Random String   11  [LETTERS]
    ${value}    Generate Random String   3  [NUMBERS]
    ${name}  Set Variable  ${metric_name}_${value}
    #---send data to kafka
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Sleep  ${0.1}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Sleep  ${0.1}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    sleep  ${delay}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${name}', None)': [{u'count': 3, u'time': u'1970-01-01T00:00:00Z'}]})
    #----delete tenant_id
    Delete tenant '${tenant_id}'
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Sleep  ${0.1}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Sleep  ${0.1}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    sleep  20
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${host_name}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})

TC.1.5. Event with disabled apikey is rejected by topology
    [Documentation]  Send event with disabled apikey and check error message
    [Tags]  ITC-Metric-validation-1.5  positive
    ${tenant_id}  ${apikey}   Create tenant
    Log To Console  tenant_id = ${tenant_id}; apikey = ${apikey}
    Get date and _index for Elasticsearch (Y.M.D)
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    ${value}    Generate Random String   3  [NUMBERS]
    ${name}  Set Variable  ${metric_name}_${value}
    : FOR  ${i}  IN RANGE  ${5}
    \   Get datetime
    \   ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    \   Send Message To Kafka    metricTopic    ${kafka_dict}
    \   Log To Console   ${kafka_dict}
    \   Sleep  ${0.1}
    Sleep  ${delay}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${name}', None)': [{u'count': 5, u'time': u'1970-01-01T00:00:00Z'}]})
    #---update apikey to disable
    Update apikey '${apikey}' for '${tenant_id}' with status 'False'
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    : FOR  ${i}  IN RANGE  ${5}
    \   Get datetime
    \   ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    \   Send Message To Kafka    metricTopic    ${kafka_dict}
    \   Log To Console   ${kafka_dict}
    \   Sleep  ${0.1}
    Sleep  20
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${host_name}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})

TC.1.6. Send event with disabled apikey and check error message
    [Tags]  ITC-Metric-validation-1.6  positive
    ${tenant_id}  ${apikey}   Create tenant
    Log To Console  tenant_id = ${tenant_id}; apikey = ${apikey}
    #---variables
    ${host_name}    Generate Random String   11  [LETTERS]
    ${value}    Generate Random String   3  [NUMBERS]
    ${name}  Set Variable  ${metric_name}_${value}
    #---send data to kafka
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic    ${kafka_dict}
    Sleep  20
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})
    #---update apikey to disable
    Update apikey '${apikey}' for '${tenant_id}' with status 'False'
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic    ${kafka_dict}
    Sleep  20
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host=${host_name}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})
    #---update apikey to enable
    Update apikey '${apikey}' for '${tenant_id}' with status 'True'
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic    ${kafka_dict}
    Sleep  20
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

TC.1.7. Send event with disabled apikey and check error message
    [Tags]  ITC-Metric-validation-1.7  positive
    ${tenant_id}  ${apikey_1}   Create tenant
    ${apikey_2}  Create apikey for '${tenant_id}'
    ${apikey_3}  Create apikey for '${tenant_id}'
    Log To Console  tenant_id = ${tenant_id}; apikey_1 = ${apikey_1}
    Log To Console  apikey_2 = ${apikey_2}; apikey_3 = ${apikey_3}
    sleep  ${delay}
    #---variables
    ${host_name}    Generate Random String   11  [LETTERS]
    ${value}    Generate Random String   3  [NUMBERS]
    ${name}  Set Variable  ${metric_name}_${value}
    #---send data to kafka
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    sleep  ${delay}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${name}', None)': [{u'count': 3, u'time': u'1970-01-01T00:00:00Z'}]})
    #---update apikey to disable
    Update apikey '${apikey_1}' for '${tenant_id}' with status 'False'
    Update apikey '${apikey_2}' for '${tenant_id}' with status 'False'
    Update apikey '${apikey_3}' for '${tenant_id}' with status 'False'
    Sleep  5
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    sleep  ${delay}
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${host_name}
    #---update apikey to enable
    Update apikey '${apikey_2}' for '${tenant_id}' with status 'True'
    Sleep  5
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    sleep  ${delay}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})
    #----delete apikey
    Delete apikey   ${apikey_2}  ${tenant_id}
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    sleep  ${delay}
    #---check InfluxDB
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})
    #---update apikey to enable
    Update apikey '${apikey_1}' for '${tenant_id}' with status 'True'
    Update apikey '${apikey_3}' for '${tenant_id}' with status 'True'
    Sleep  5
    #---send data to kafka
    ${host_name}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    Get datetime
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  name=${name}  value=${value}  host=${host_name}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   metricTopic  ${kafka_dict}
    sleep  ${delay}
    #-------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT COUNT(name) FROM /${name}/ where host = '${host_name}'
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${name}', None)': [{u'count': 2, u'time': u'1970-01-01T00:00:00Z'}]})
