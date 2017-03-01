*** Settings ***
Documentation     Negative test scenarios for no field cases.
...               Check what messages are created in ES in case of wrong data input
Resource          ../keywords/keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/ElasticSearchClient.py
Library           ../libs/KafkaClient.py
Library           ../libs/ExtendDictionary.py

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'  Get date and _index for Elasticsearch (Y.M.D)
Test Setup  Run Keywords   Get datetime     Get date and _index for Elasticsearch (Y.M.D)
Suite Setup   Run Keywords   Post correct log message to Kafka
Suite Teardown  Run Keywords   Clear index in elasticsearch

*** Test Cases ***
#Post log message to Kafka not in json format
#    [Tags]  ITC-3.10  negative  storm_migration_TC
#    ${message}   Set Variable   Field_validation_not_in_JSON_format ${datetime}
#    Send Message To Kafka    logTopic    ${message}
#    Check Message In Kafka exists    logTopic    ${message}
#    Sleep    5
#    #-------------------------------------------------------------------------
#    ${res_bool}  Check Index Exists    /${ES_unknown}
#    ${res_str}  Convert To String    ${res_bool}
#    Should Be Equal As Strings  ${res_str}   False

#Post log message to Kafka in wrong Json format
#    [Tags]    ITC-3.11   negative  es_migration_TC
#    ${json}   Set Variable   {"apikey":"${apikey}","tenant_id":"${tenant_id}", message, hostname":"testPC"}
#    Send Message To Kafka    logTopic    ${json}
#    Check Message In Kafka exists    logTopic    ${json}
#    Sleep    5
#    #-------------------------------------------------------------------------
#    ${res_bool}  Check Index Exists    /${ES_unknown}
#    ${res_str}  Convert To String    ${res_bool}
#    Should Be Equal As Strings  ${res_str}   False

Post log message to Kafka without apikey
    [Tags]  ITC-3.12  negative  storm_migration_TC
    ${message}   Set Variable     Field_validation_no_apikey ${datetime}
    ${kafka_dict}  Create Dictionary  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep  30
    #-------------------------------------------------------------------------
    ${message_by_body}  Get Message From Es By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${message_by_body}  Message was not found
    #-------------------------------------------------------------------------
    ${count}  Count Es Messages By Body   /${ES_index}/logs/   MISSING_REQUIRED_FIELDS
    Should Be Equal As Strings  ${count}   0

#Post log message to Kafka without a tenant_id field
#    [Tags]    ITC-3.13   negative
#    ${message}   Set Variable     Field_validation_no_tenant_id ${datetime}
#    ${kafka_dict}  Create Dictionary  apikey=${apikey}  message=${message}  @timestamp=${@timestamp}
#    Send Message To Kafka    logTopic    ${kafka_dict}
#    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
#    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
#    Sleep  30
#    #-------------------------------------------------------------------------
#    ${res_bool}  Check Index Exists    /${ES_unknown}
#    ${res_str}  Convert To String    ${res_bool}
#    Should Be Equal As Strings  ${res_str}   False

Post log message to Kafka without message field
    [Tags]  ITC-3.14  negative
    ${kafka_dict}  Create Dictionary  tenant_id=${tenant_id}  apikey=${apikey}  @timestamp=${@timestamp}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"@timestamp":"${@timestamp}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep  30
    #-------------------------------------------------------------------------
    ${message_by_body}  Get Message From Es By Key  /${ES_index}/logs/   @timestamp   ${@timestamp}
    Should Be Equal As Strings  ${message_by_body}  Message was not found
    #-------------------------------------------------------------------------
    ${count}  Count Es Messages By Body   /${ES_index}/logs/   MISSING_REQUIRED_FIELDS
    Should Be Equal As Strings  ${count}   1
    ${res}   Return Full Es Message   /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message to Kafka without @timestamp field
    [Tags]  ITC-3.15  negative  smoke  es_migration_TC
    ${message}   Set Variable   Field_validation_no_timestamp ${datetime}
    ${kafka_dict}  Create Dictionary  tenant_id=${tenant_id}  apikey=${apikey}  message=${message}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep  30
    #-------------------------------------------------------------------------
    ${message_by_body}  Get Message From Es By Body  /${ES_index}/logs/  ${message}
    Should Be Equal As Strings  ${message_by_body}  Message was not found
    #-------------------------------------------------------------------------
    ${count}  Count Es Messages By Body   /${ES_index}/logs/   MISSING_REQUIRED_FIELDS
    Should Be Equal As Strings  ${count}   1
    ${res}   Return Full Es Message   /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

Post log message to Kafka without @timestamp but with some_@timestamp
    [Tags]  ITC-3.16   negative
    ${message}   Set Variable   Field_validation_some_@timestamp ${datetime}
    ${kafka_dict}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","some_@timestamp":"${@timestamp}","message":"${message}"}
    Send Message To Kafka    logTopic    ${kafka_dict}
    Sleep    30
    #-------------------------------------------------------------------------
    ${res}   Get Message From ES By Body  /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
    Should Be Equal As Strings  ${res['@rawMessage']}   ${kafka_dict}
    ${res}   Return Full Es Message   /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
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
    Sleep    60
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}