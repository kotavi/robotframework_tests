*** Settings ***
Documentation     Positive cases for fields of different types
Resource          ../keywords/keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/ElasticSearchClient.py
Library           ../libs/KafkaClient.py

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'   Get date and _index for Elasticsearch (Y.M.D)
Suite Setup  Run Keywords   Get datetime
Suite Teardown   Run Keywords    Clean index
Test Setup  Get datetime
#Test Teardown  Clean index

*** Test Cases ***
Send message to logTopic with field message long
    [Tags]  ITC-3.63  positive  es_migration_TC
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${time_ms} Too long message Too long message Too long message Too long message Too long message Too long message Too long message Too long message Too long message Too long message Too long message Too long message Too long message Too long message Too long message  @timestamp=${@timestamp}
    Creating index should be finished successfully  ${kafka_dict}

Send message to logTopic with field pid_int too long
    [Tags]  ITC-3.64  negative  storm_migration_TC
    ${message}   Set Variable   field pid_int too long ${time_ms}
    ${kafka_dict}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","@timestamp":"${@timestamp}","message":"${message} Too long pid","pid_int":333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333}
    Send Message To Kafka    logTopic    ${kafka_dict}
    sleep  30
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${kafka_dict}
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Send message to logTopic with field hostname_string too long
    [Tags]  ITC-3.65  negative  smoke
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}  message=${time_ms} Too long hostname  hostname_string=Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long Hostname is too long
    Creating index should be finished successfully  ${kafka_dict}

Send message to logTopic with field version too long
    [Tags]  ITC-3.66  negative  storm_migration_TC
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}  message=${time_ms} Too long version  version=1234567889087657245341234123456788908765724534123123456788908765724534123123456788908765724534123123456788908765724534123123456788908765724534123123456788908765724534123123456788908765724534123123456788908765724534123123456788908765724534123123456788908765724534123123456788908765724534123123456788908765724534123123456788908765724534123
    Creating index should be finished successfully  ${kafka_dict}

Topology rejects message with field apikey too long (280 symbols)
    [Tags]  ITC-3.67  negative
    ${message}   Set Variable   field apikey too long ${time_ms}
    ${kafka_dict}  Create Dictionary  tenant_id=${tenant_id}  @timestamp=${@timestamp}  message=${message} Too long apikey  apikey=zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0
    Send Message To Kafka    logTopic    ${kafka_dict}
    Sleep  30
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found

#Topology rejects message with field tenant_id too long (280 symbols)
#    [Tags]  ITC-3.68  negative  storm_migration_TC
#    ${message}   Set Variable   field tenant_id too long ${time_ms}
#    ${kafka_dict}  Create Dictionary  apikey=${apikey}  @timestamp=${@timestamp}  message=${message} Too long tenant_id  tenant_id=zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0zaqwsxcderfvbgt54321yhn6ujm8k7idflgh9op0
#    Send Message To Kafka    logTopic    ${kafka_dict}
#    Sleep  30
#    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
#    Should Be Equal As Strings  ${res}   Message was not found
#    ${res_bool}  Check Index Exists    /${ES_unknown}
#    ${res_str}  Convert To String    ${res_bool}
#    Should Be Equal As Strings  ${res_str}   False

Send message to logTopic with field pattern int too long
    [Tags]  ITC-3.69  negative
    ${message}   Set Variable   field pattern int too long ${time_ms}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}  message=${message} Too long pattern int  some_int=${1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890}
    Send Message To Kafka    logTopic    ${kafka_dict}
    Sleep  30
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Be Equal As Strings  ${res}   Message was not found
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   INVALID_MAPPING_FIELDS
    Should Not Be Equal As Strings  ${res}   Message was not found
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Send message to logTopic with field pattern double too long
    [Tags]  ITC-3.70  positive  smoke
    ${message}   Set Variable   field pattern double too long ${time_ms}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}  message=${message}  some_double=0.12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
    Send Message To Kafka    logTopic    ${kafka_dict}
    Sleep  40
    ${res}  Get Message From ES By Body  /${ES_index}/logs/   ${message}
    Should Not Be Equal As Strings  ${res}   Message was not found
    Log  ${res}; some_double = ${res['some_double']}
    Should Be Equal As Strings  ${res['some_double']}  0.123456789012

*** Keywords ***
Creating index should be finished successfully  [Arguments]  ${kafka_dict}
    ${kwargs}  Create Dictionary  raise_if_not_found=True
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${message}  Wait Until Keyword Succeeds  1 min  5 sec  Get Message From Es By Body  /${ES_index}/logs/   ${kafka_dict['message']}  ${kwargs}
    Remove From Dictionary    ${message}    @timestamp  tags    messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}

Check Message From ES Exists By Body  [Arguments]  ${body}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${body}
    Should Not Be Equal As Strings  ${res}  Message was not found
    [Return]  ${res}

Clean index
   Delete Index From Es  ${ES_index}