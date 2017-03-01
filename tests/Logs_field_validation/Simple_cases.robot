*** Settings ***
Documentation     Positive cases for fields of different types
Resource          ../keywords/keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/ElasticSearchClient.py
Library           ../libs/KafkaClient.py

Test Teardown  Run Keywords   Clear index in elasticsearch

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords   Get date and _index for Elasticsearch (Y.M.D)
Suite Setup  Run Keywords   Get datetime
Suite Teardown  Run Keywords   Clear index in elasticsearch

*** Variables ***
${sleep_time}   40

*** Test Cases ***
Post log message with name pattern int
    [Tags]  ITC-3.2   positive  es_migration_TC  storm_migration_TC
    ${message}    Set Variable    With field {}_int ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_int=${34}
    Log To Console  ${kafka_dict}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    ${sleep_time}
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern double
    [Tags]  ITC-3.3   positive  smoke   es_migration_TC    runtime  storm_migration_TC
    ${message}    Set Variable    With field {}_double ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_int=${34}  some_double=${3.4}
    Log To Console  ${kafka_dict}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    ${sleep_time}
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern boolean
    [Tags]  ITC-3.4  positive  zk_migration_TC
    ${message}    Set Variable    With field {}_bool ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_int=${0}  some_double=${0.0}  some_boolean=${True}
    Log To Console  ${kafka_dict}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    ${sleep_time}
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern date
    [Tags]  ITC-3.5  positive  smoke
    ${message}    Set Variable    With field {}_date ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  basic_date=${@timestamp}  test_ip=172.18.196.26  some_int=${5}  some_double=${0.0001}  some_boolean=${False}
    Log To Console  ${kafka_dict}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    ${sleep_time}
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  basic_date  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey  basic_date
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern @date
    [Tags]  ITC-3.5a  positive  kafka_migration_TC  storm_migration_TC  es_migration_TC
    ${message}    Set Variable    With field {}_@date ${datetime}
    #do we need this case???
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_@date=${@timestamp}  test_ip=172.18.196.26  some_int=${50}  some_double=${100.1}  some_boolean=${True}
    Log To Console  ${kafka_dict}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    ${sleep_time}
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern @timestamp
    [Tags]  ITC-3.6  positive  zk_migration_TC  kafka_migration_TC
    ${message}    Set Variable    With field {}_@timestamp ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  test_ip=172.18.196.26  some_int=${60}  some_double=${600.1}  some_boolean=${True}  some_@timestamp=${@timestamp}
    Log To Console  ${kafka_dict}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    ${sleep_time}
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern with different date fields
    [Tags]  ITC-3.7  positive
    ${message}    Set Variable    With all fields ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_@date=${@timestamp}  basic_date=${@timestamp}  test_ip=173.18.196.26  some_int=${123}  some_double=${3.04}  some_boolean=${True}  some_@timestamp=${@timestamp}
    Log To Console  ${kafka_dict}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    ${sleep_time}
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  basic_date  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey  basic_date
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern ip
    [Tags]  ITC-3.8  positive  smoke  zk_migration_TC  storm_migration_TC
    ${message}    Set Variable    With field {}_ip ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  test_ip=172.18.196.26  some_int=${67}  some_double=${67.67}  some_boolean=${True}
    Log To Console  ${kafka_dict}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    ${sleep_time}
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with int value in double field
    [Tags]  ITC-3.32  negative  es_migration_TC  storm_migration_TC
    ${message}    Set Variable    Field_validation_not_double_int ${time_ms}
    ${kafka_json}   Set Variable    {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_double":5}
    Log To Console  ${message}
    Send Message To Kafka    logTopic  ${kafka_json}
    Sleep    ${sleep_time}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Not Be Equal As Strings  ${res}  Message was not found
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern ip (some ip without quots)
    [Tags]  ITC-3.40a  negative  kafka_migration_TC
    ${message}    Set Variable    Field_validation_ip_no_quots ${time_ms}
    Log To Console  ${message}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":67,"some_double":67.67,"some_boolean":"True","test_ip":1.1.1.1}
    Sleep    ${sleep_time}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Not Be Equal As Strings  ${res}  Message was not found
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1

Post log message with name pattern ip (some ip without quots)
    [Tags]  ITC-3.41  positive  kafka_migration_TC
    ${message}    Set Variable    Field_validation_hostname ${time_ms}
    Log To Console  ${message}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","host":"epmp-px2-lmm-sys-srv-p23","type":"test-type-data"}
    Log To Console  ${json}
    Send Message To Kafka    logTopic  ${json}
    Sleep    ${sleep_time}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Not Be Equal As Strings  ${res}  Message was not found
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /${ES_index}/logs/
    Should Be Equal As Integers   ${n}    1