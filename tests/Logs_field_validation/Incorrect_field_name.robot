*** Settings ***
Documentation     Integration test cases for scenarios concerning messages
Resource          ../keywords/keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/ElasticSearchClient.py
Library           ../libs/KafkaClient.py
Library           ../libs/ExtendDictionary.py

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'   Get date and _index for Elasticsearch (Y.M.D)
Test Setup  Run Keywords   Get datetime     Get date and _index for Elasticsearch (Y.M.D)
# clean indexes that were created before
Suite Setup  Run Keywords   Delete created indexes    Post correct log message to Kafka
Suite Teardown  Run Keywords   Delete created indexes

*** Test Cases ***
Topology rejects message to Kafka instead of apikey - api_key field name
    [Tags]  ITC-3.17   negative  smoke  storm_migration_TC
    ${message}    Set Variable    Field_validation_api_key ${datetime}
    ${kafka_dict}  Create Dictionary  api_key=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}
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

#Topology rejects message to Kafka instead of tenant_id - tenant_ID field name
#    [Tags]  ITC-3.18   negative  es_migration_TC  storm_migration_TC
#    ${message}    Set Variable    Field_validation_tenant_ID ${datetime}
#    #-------------------------------------------------------------------------
#    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_ID=${tenant_id}  message=${message}  @timestamp=${@timestamp}
#    Send Message To Kafka    logTopic    ${kafka_dict}
#    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
#    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
#    Sleep  30
#    #-------------------------------------------------------------------------
#    ${res_bool}  Check Index Exists    /${ES_unknown}
#    ${res_str}  Convert To String    ${res_bool}
#    Should Be Equal As Strings  ${res_str}   False

#Topology rejects message to Kafka instead of the tenant_id - tenantid field name
#    [Tags]  ITC-3.19   negative   smoke  storm_migration_TC
#    ${message}    Set Variable    Field_validation_tenantid ${datetime}
#    #-------------------------------------------------------------------------
#    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenantid=${tenant_id}  message=${message}  @timestamp=${@timestamp}
#    Send Message To Kafka    logTopic    ${kafka_dict}
#    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
#    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
#    Sleep  30
#    #-------------------------------------------------------------------------
#    ${res_bool}  Check Index Exists    /${ES_unknown}
#    ${res_str}  Convert To String    ${res_bool}
#    Should Be Equal As Strings  ${res_str}   False

Post log message to Kafka instead of @timestamp - timestamp field name
    [Tags]  ITC-3.20   negative  es_migration_TC  storm_migration_TC
    ${message}    Set Variable    Field_validation_timestamp ${datetime}
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  timestamp=${@timestamp}
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