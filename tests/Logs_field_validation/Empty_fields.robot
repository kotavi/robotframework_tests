*** Settings ***
#Documentation     Negative cases for fields of different types
Resource          ../keywords/keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/ElasticSearchClient.py
Library           ../libs/KafkaClient.py

Suite Setup   Execute Preconditions 
Test Setup        Run Keywords     Get datetime
Suite Teardown    Run Keywords     Clean index

*** Test Cases ***
Send message to logTopic with empty apikey field
    [Tags]  ITC-3.52  negative  storm_migration_TC
    ${message}    Set Variable    empty apikey field ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"456","hostname_string":"hello","priority_boolean":"False","myhost_ip":"172.18.196.23"}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res}   Message was not found

#Send message to logTopic with empty tenant_id field
#    [Tags]  ITC-3.53  negative
#    ${message}    Set Variable    empty tenant_id field ${time_ms}
#    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"","message":"double fields","@timestamp":"${@timestamp}","pid_int":"0","hostname_string":"hello","priority_boolean":"False","myhost_ip":"172.18.196.23"}
#    ${res_bool}  Check Index Exists    /${ES_unknown}
#    ${res_str}  Convert To String    ${res_bool}
#    Should Be Equal As Strings  ${res_str}   False

Send message to logTopic with empty message field
    [Tags]  ITC-3.54  negative  smoke
    ${message}    Set Variable    ""
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":${message},"@timestamp":"${@timestamp}","some_int":7}
    Send Message To Kafka    logTopic  ${json}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  30
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   MISSING_REQUIRED_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Send message to logTopic with empty field @timestamp
    [Tags]  ITC-3.55  negative
    ${message}    Set Variable    empty @timestamp ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"","some_int":7}
    Send Message To Kafka    logTopic  ${json}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  30
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

#Message with all empty fields is rejected by topology
#    [Tags]  ITC-3.56  negative
#    ${body}  Set Variable  {"apikey":"","tenant_id":"","message":"","@timestamp":"","pid_int":"","hostname_string":"","priority_boolean":"","myhost_ip":""}
#    Send Message To Kafka    logTopic  ${body}
#    ${res_bool}  Check Index Exists    /${ES_unknown}
#    ${res_str}  Convert To String    ${res_bool}
#    Should Be Equal As Strings  ${res_str}   False

Send message to logTopic with empty name pattern int
    [Tags]    ITC-3.57  negative  storm_migration_TC
    ${message}    Set Variable    empty name pattern int ${time_ms}
    ${json}   Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":""}
    Send Message To Kafka    logTopic  ${json}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  30
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Send message to logTopic with empty name pattern double
    [Tags]    ITC-3.58  negative
    ${message}    Set Variable    empty name pattern double ${time_ms}
    ${json}   Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_double":""}
    Send Message To Kafka    logTopic  ${json}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  30
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Send message to logTopic with empty name pattern boolean
    [Tags]    ITC-3.59  negative
    ${message}    Set Variable    empty name pattern boolean ${time_ms}
    ${json}   Set Variable   {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_boolean":""}
    Send Message To Kafka    logTopic   ${json}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  30
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Send message to logTopic with empty name pattern some_date
    [Tags]    ITC-3.60  negative
    ${message}    Set Variable    empty name pattern some_date ${time_ms}
    ${json}   Set Variable    {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_date":""}
    Send Message To Kafka    logTopic   ${json}
    Sleep   10
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    sleep  20
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Send message to logTopic with empty name pattern some_@date
    [Tags]    ITC-3.61  negative
    ${message}    Set Variable    empty name pattern some_@date ${time_ms}
    ${json}   Set Variable   {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_@date":""}
    Send Message To Kafka    logTopic   ${json}
    Sleep   60
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Not Be Equal As Strings  ${res}   Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  empty name pattern some_@date ${time_ms}
    Should Not Be Equal As Strings  ${res}   Message was not found

Send message to logTopic with empty name pattern some_@timestamp
    [Tags]    ITC-3.62  negative
    ${message}    Set Variable    empty name pattern some_@timestamp ${time_ms}
    Send Message To Kafka    logTopic  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_@timestamp":""}
    Sleep  30
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Not Be Equal As Strings  ${res}   Message was not found

*** Keywords ***
Execute Preconditions
   Get data from keystone with '${keystone_v3}'
   Get datetime
   Get date and _index for Elasticsearch (Y.M.D)
   Clean index
   Post correct log message to Kafka
   ${dict}  Create Dictionary  raise_if_not_found=True
   Set Global Variable  ${kwargs}  ${dict}

Clean index
   Delete Index From Es  ${ES_index}

Check Message From ES By Body  [Arguments]  ${body}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${body}
    Should Not Be Equal As Strings  ${res}  Message was not found

Post correct log message to Kafka
    ${message}    Set Variable    correct log message to Kafka
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_int=${34}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    60
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}