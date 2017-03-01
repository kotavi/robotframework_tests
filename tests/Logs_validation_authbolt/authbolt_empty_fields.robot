*** Settings ***
Resource        authbolt_validation_keywords.robot

Suite Setup   Run Keywords  Create dictionary with roles  Create dictionary with services  Create dictionary with ldap_groups
Suite Setup   Run Keywords  Create global tenant and apikey   Get date and _index for Elasticsearch (Y.M.D)

Test Teardown  Run Keywords   Clear index in elasticsearch

Suite Setup  Run Keywords   Get date and _index for Elasticsearch (Y.M.D)
Suite Setup  Run Keywords   Get datetime   Post correct log message to Kafka
Suite Teardown  Run Keywords   Clear index in elasticsearch  Delete tenant '${tenant_id_global}'

*** Variables ***
${delay}  20

*** Test Cases ***
Message with empty apikey field will be rejected
    [Tags]  ITC-authbolt-2.1  negative
    ${message}    Set Variable    empty apikey field ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}"}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found

Message with empty message field will be stored as MISSING_REQUIRED_FIELDS
    [Tags]  ITC-authbolt-2.2   negative  discarded
    ${message}    Set Variable    ""
    ${json}  Set Variable  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":${message},"@timestamp":"${@timestamp}","some_int":7}
    Send Message To Kafka    logTopic  ${json}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  ${delay}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   MISSING_REQUIRED_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Message with empty @timestamp field will be stored as MISSING_REQUIRED_FIELDS
    [Tags]  ITC-authbolt-2.3  negative  discarded
    ${message}    Set Variable    empty @timestamp ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"","some_int":7}
    Send Message To Kafka    logTopic  ${json}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  ${delay}
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Message with empty name pattern int field will be stored as INVALID_MAPPING_FIELDS
    [Tags]    ITC-authbolt-2.4  negative  discarded
    ${message}    Set Variable    empty name pattern int ${time_ms}
    ${json}   Set Variable  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_int":""}
    Send Message To Kafka    logTopic  ${json}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  ${delay}
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Message with empty name double int field will be stored as INVALID_MAPPING_FIELDS
    [Tags]    ITC-authbolt-2.5  negative  discarded
    ${message}    Set Variable    empty name pattern double ${time_ms}
    ${json}   Set Variable  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_double":""}
    Send Message To Kafka    logTopic  ${json}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  ${delay}
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Message with empty name pattern boolean field will be stored as INVALID_MAPPING_FIELDS
    [Tags]    ITC-authbolt-2.6  negative  discarded
    ${message}    Set Variable    empty name pattern boolean ${time_ms}
    ${json}   Set Variable   {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_boolean":""}
    Send Message To Kafka    logTopic   ${json}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  ${delay}
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Message with empty name pattern some_date field will be stored as INVALID_MAPPING_FIELDS
    [Tags]    ITC-authbolt-2.7  negative  discarded
    ${message}    Set Variable    empty name pattern some_date ${time_ms}
    ${json}   Set Variable    {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_date":""}
    Send Message To Kafka    logTopic   ${json}
    Sleep   10
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  20
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Message with empty name pattern some_@date field will be stored
    [Tags]    ITC-authbolt-2.8  positive
    ${message}    Set Variable    empty name pattern some_@date ${time_ms}
    ${json}   Set Variable   {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_@date":""}
    Send Message To Kafka    logTopic   ${json}
    Sleep   ${delay}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Not Be Equal As Strings  ${res}   Message was not found

Message with empty name pattern some_@timestamp field will be stored
    [Tags]    ITC-authbolt-2.9  positive
    ${message}    Set Variable    empty name pattern some_@timestamp ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"${message}","@timestamp":"${@timestamp}","some_@timestamp":""}
    Sleep  ${delay}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Not Be Equal As Strings  ${res}   Message was not found