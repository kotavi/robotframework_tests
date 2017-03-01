*** Settings ***
Documentation     Integration test cases for scenarios concerning messages
Resource          ../keywords/keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/KafkaClient.py
Library           ../libs/ElasticSearchClient.py

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'  Get date and _index for Elasticsearch (Y.M.D)
Suite Setup  Run Keywords   Clear index in elasticsearch   Post correct log message to Kafka
Test Setup   Run Keywords   Get datetime
Suite Teardown  Run Keywords   Clear index in elasticsearch

*** Test Cases ***
Log messages - Incorrect value for apikey
    [Tags]   ITC-3.9a
    ${message}    Set Variable    Incorrect value for apikey ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${wrong_apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":0}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Sleep  30
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res}   Message was not found

Log messages - Incorrect value for tenant_id
    [Tags]   ITC-3.9b
    ${message}    Set Variable    Incorrect value for tenant_id ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${wrong_tenant}","message":"${message}","@timestamp":"${@timestamp}","some_int":0}
    Sleep  30
    ${results}    Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${results}  Message was not found

Post log message with double value in int field
    [Tags]  ITC-3.31a  negative  storm_migration_TC
    ${message}    Set Variable    Field_validation_not_int_double ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":0.05}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Sleep  30
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log with message field with dict value
    [Tags]  ITC-3.31b  negative  storm_migration_TC
    ${message}    Set Variable    Field_validation_not_int_double ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":["${message}"],"@timestamp":"${@timestamp}"}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}

Post log message with message format - unicode
    [Tags]  ITC-3.71  negative
    ${message}    Set Variable    Field_validation_not_int_unicode ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":u"${message}","@timestamp":"${@timestamp}"}
    Sleep  30
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res}  Message was not found

Post log message with string value in boolean field
    [Tags]  ITC-3.34  negative  es_migration_TC
    ${message}    Set Variable    Field_validation_not_bool ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_boolean":"YES"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with string value in IP field
    [Tags]  ITC-3.40  negative  smoke  storm_migration_TC
    ${message}    Set Variable    Field_validation_not_ip ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_ip":"my_ip"}
    Sleep    30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Log  ${results}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with name pattern date (some string - date)
    [Tags]  ITC-3.41a  negative
    ${message}    Set Variable    Field_validation_not_date_string ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":555,"some_double":0.0001,"some_boolean":"False","basic_date":"date"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with name pattern boolean (some string - hello world)
    [Tags]  ITC-3.39a  negative  storm_migration_TC
    ${message}    Set Variable    Field_validation_not_bool_string ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":0,"some_double":0.0,"some_boolean":"hello+world"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with pid_int with letters (e.g. 09rt56)
    [Tags]  ITC-3.28  negative  smoke  es_migration_TC
    ${message}    Set Variable    pid_int with letters ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"09rt56"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Log  ${results}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with pid_int with spases (e.g. 39 56)
    [Tags]  ITC-3.30  negative  storm_migration_TC
    ${message}    Set Variable    pid_int with spases ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"39 56"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with pid_int with @#$%^&*()-+ symbols
    [Tags]  ITC-3.29  negative
    ${message}    Set Variable    pid_int with @#$%^&*()-+ symbols ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"@#$%^&*()-+"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with pid_int with dot (e.g. 39.56)
    [Tags]  ITC-3.31  negative
    ${message}    Set Variable    pid_int with dot ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"39.56"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with hostname field with integer value (e.g. "hostname":1233)
    [Tags]  ITC-3.33  negative  storm_migration_TC
    ${message}    Set Variable    hostname field with integer value ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","hostname":1233}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with bool field with "@#$%^&" symbols
    [Tags]  ITC-3.36  negative
    ${message}    Set Variable    bool field with @#$%^& symbols ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"@#$%^&"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with bool field with spases (e.g. 39 56)
    [Tags]  ITC-3.37  negative  smoke  es_migration_TC
    ${message}    Set Variable    bool field with spases ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"39 56"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Log  ${results}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with bool field with dot (e.g. 39.56)
    [Tags]  ITC-3.38  negative
    ${message}    Set Variable    bool field with dot ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"39.56"}
    Sleep   30
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with bool field with string
    [Tags]  ITC-3.39  negative
    ${message}    Set Variable    bool field with string ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"some_string"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with date field in format yyyyMMdd'T'HHmmss
    [Tags]  ITC-3.41  negative
    ${message}    Set Variable    date field in format yyyyMMddTHHmmss ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","field_date":"20140915T155300"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with date field in format yyyyMMdd'-'HHmmss
    [Tags]  ITC-3.42  negative
    ${message}    Set Variable    date field in format yyyyMMdd-HHmmss ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","field_date":"20140915-155300"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with date field in format yyyy:MM:dd:HH:mm:ss
    [Tags]  ITC-3.43  negative
    ${message}    Set Variable    date field in format yyyy:MM:dd:HH:mm:ss ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","field_date":"2014:09:15:15:53:00"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message with date field in format HH:mm:ss-yyyy-MM-dd
    [Tags]  ITC-3.44  negative
    ${message}    Set Variable    date field in format HH:mm:ss-yyyy-MM-dd ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","field_date":"15:53:00-2014-09-15"}
    Sleep   30
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

*** Keywords ***
Delete created indexes
    Delete Index From Es   ${ES_index}

Post correct log message to Kafka
    Get datetime
    ${message}    Set Variable    correct log message to Kafka ${time_ms}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_int=${34}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    50
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}