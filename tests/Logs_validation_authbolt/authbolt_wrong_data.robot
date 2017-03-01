*** Settings ***
Resource        authbolt_validation_keywords.robot

Suite Setup   Run Keywords  Create dictionary with roles  Create dictionary with services  Create dictionary with ldap_groups
Suite Setup   Run Keywords  Create global tenant and apikey   Get date and _index for Elasticsearch (Y.M.D)

Test Teardown  Run Keywords   Clear index in elasticsearch

Suite Setup  Run Keywords   Get datetime   Post correct log message to Kafka
Suite Teardown  Run Keywords   Clear index in elasticsearch  Delete tenant '${tenant_id_global}'

*** Test Cases ***
Log messages - Incorrect value for apikey
    [Tags]   ITC-authbolt-4.1  negative  discarded
    ${message}    Set Variable    Incorrect value for apikey ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${wrong_apikey}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_int":0}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Sleep  ${delay}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res}   Message was not found

Log messages - Incorrect value for tenant_id
    [Tags]   ITC-authbolt-4.2  negative
    ${message}    Set Variable    Incorrect value for tenant_id ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${wrong_tenant}","message":"${message}","@timestamp":"${@timestamp}","some_int":0}
    Sleep  ${delay}
    #-------------------------------------------------------------------------
    ${res_bool}  Check Index Exists    /${ES_index}
    should not be true  ${res_bool}

Get INVALID_MAPPING_FIELDS for event with double value in int field
    [Tags]  ITC-authbolt-4.3  negative  discarded
    ${message}    Set Variable    Field_validation_not_int_double ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_int":0.05}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Sleep  ${delay}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message field with dict value
    [Tags]  ITC-authbolt-4.4  negative  discarded
    ${message}    Set Variable    Field_validation_not_int_double ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":["${message}"],"@timestamp":"${@timestamp}"}
    Sleep  ${delay}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with message format - unicode
    [Tags]  ITC-authbolt-4.5  negative
    ${message}    Set Variable    Field_validation_not_int_unicode ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":u"${message}","@timestamp":"${@timestamp}"}
    Sleep  ${delay}
    #-------------------------------------------------------------------------
    ${res_bool}  Check Index Exists    /${ES_index}
    should not be true  ${res_bool}

Get INVALID_MAPPING_FIELDS for message with string value in boolean field
    [Tags]  ITC-authbolt-4.6  negative  discarded
    ${message}    Set Variable    Field_validation_not_bool ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_boolean":"YES"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with string value in IP field
    [Tags]  ITC-authbolt-4.7  negative  discarded
    ${message}    Set Variable    Field_validation_not_ip ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_ip":"my_ip"}
    Sleep    ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Log  ${results}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with name pattern date (some string - date)
    [Tags]  ITC-authbolt-4.8  negative  discarded
    ${message}    Set Variable    Field_validation_not_date_string ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_int":555,"some_double":0.0001,"some_boolean":"False","basic_date":"date"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with name pattern boolean (some string - hello world)
    [Tags]  ITC-authbolt-4.9  negative  discarded
    ${message}    Set Variable    Field_validation_not_bool_string ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_int":0,"some_double":0.0,"some_boolean":"hello+world"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}   Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with pid_int with letters (e.g. 09rt56)
    [Tags]  ITC-authbolt-4.10  negative  discarded
    ${message}    Set Variable    pid_int with letters ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"09rt56"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Log  ${results}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with pid_int with spases (e.g. 39 56)
    [Tags]  ITC-authbolt-4.11  negative  discarded
    ${message}    Set Variable    pid_int with spases ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"39 56"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with pid_int with @#$%^&*()-+ symbols
    [Tags]  ITC-authbolt-4.12  negative  discarded
    ${message}    Set Variable    pid_int with @#$%^&*()-+ symbols ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"@#$%^&*()-+"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with pid_int with dot (e.g. 39.56)
    [Tags]  ITC-authbolt-4.13  negative  discarded
    ${message}    Set Variable    pid_int with dot ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"39.56"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with hostname field with integer value (e.g. "hostname":1233)
    [Tags]  ITC-authbolt-4.14  negative  discarded
    ${message}    Set Variable    hostname field with integer value ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","hostname":1233}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with bool field with "@#$%^&" symbols
    [Tags]  ITC-authbolt-4.15  negative  discarded
    ${message}    Set Variable    bool field with @#$%^& symbols ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"@#$%^&"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with bool field with spases (e.g. 39 56)
    [Tags]  ITC-authbolt-4.16  negative  discarded
    ${message}    Set Variable    bool field with spases ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"39 56"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Log  ${results}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with bool field with dot (e.g. 39.56)
    [Tags]  ITC-authbolt-4.17  negative  discarded
    ${message}    Set Variable    bool field with dot ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"39.56"}
    Sleep   ${delay}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with bool field with string
    [Tags]  ITC-authbolt-4.18  negative  discarded
    ${message}    Set Variable    bool field with string ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"some_string"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with date field in format yyyyMMdd'T'HHmmss
    [Tags]  ITC-authbolt-4.19  negative  discarded
    ${message}    Set Variable    date field in format yyyyMMddTHHmmss ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","field_date":"20140915T155${delay}0"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with date field in format yyyyMMdd'-'HHmmss
    [Tags]  ITC-authbolt-4.20  negative  discarded
    ${message}    Set Variable    date field in format yyyyMMdd-HHmmss ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","field_date":"20140915-155${delay}0"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with date field in format yyyy:MM:dd:HH:mm:ss
    [Tags]  ITC-authbolt-4.21  negative  discarded
    ${message}    Set Variable    date field in format yyyy:MM:dd:HH:mm:ss ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","field_date":"2014:09:15:15:53:00"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Get INVALID_MAPPING_FIELDS for message with date field in format HH:mm:ss-yyyy-MM-dd
    [Tags]  ITC-authbolt-4.22  negative  discarded
    ${message}    Set Variable    date field in format HH:mm:ss-yyyy-MM-dd ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","field_date":"15:53:00-2014-09-15"}
    Sleep   ${delay}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}  Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${res}  Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}