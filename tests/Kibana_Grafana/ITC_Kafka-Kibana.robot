*** Settings ***
Resource          settings.robot
Library           ../libs/ExtendDictionary.py

Suite Setup   Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup   Run Keywords   Get datetime  Getting the time in milliseconds
Test Setup   Run Keywords    Clear index in elasticsearch

*** Test Cases ***
Post simple log message to kafka and get from kibana
    [Tags]   Graph-3.1  positive  smoke  influx_migration_TC  kafka_migration_TC  ui_migration_TC  es_migration_TC
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=simple integration test kafka-kibana  @timestamp=${@timestamp}
    Successful creating of index  ${kafka_dict}

Post many log messages and check that count always the same
    [Tags]  Graph-3.2  critical  influx_migration_TC  kafka_migration_TC  ui_migration_TC  es_migration_TC
    :FOR  ${i}  IN RANGE  ${20}
    \    Get datetime
    \    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=critical test kafka-kibana log: ${i}   @timestamp=${@timestamp}
    \    Send Message To Kafka    logTopic    ${kafka_dict}    
    \    Sleep  1
    Sleep  10
    :FOR  ${i}  IN RANGE  ${10}
    \    ${result}  Querying Data From Kibana  ${tenant_id}
    \    Length Should Be  ${result}  20    
    \    Sleep  2

Post log message with many fields to kafka and get from kibana
    [Tags]  Graph-3.3  positive  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=extended integration test kafka-kibana  @timestamp=${@timestamp}  some_int=${12}  some_string=Its my string  some_double=${0.1234}  hostname_string=qa-host  version=100  age_int=${23}  name_string=John  lastname_string=Doe  default_log_name_string=my.log  username_string=arnold  password_string=bigSecret2122
    Successful creating of index  ${kafka_dict}

User cannot get message from Kibana if it's with invalid apikey
    [Tags]  Graph-3.5   negative  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    ${kafka_dict}  Create Dictionary  apikey=wrongapikey  tenant_id=${tenant_id}  message=with invalid apikey  @timestamp=${@timestamp}
    Send Message To Kafka    logTopic    ${kafka_dict}
    Querying Not Existing Data From Kibana   ${tenant_id}
    ${body}    Get Response Body
    Should Contain   ${body}    IndexMissingException

User cannot get message from Kibana if it's without apikey
    [Tags]  Graph-3.6  negative  influx_migration_TC  kafka_migration_TC  ui_migration_TC
    ${kafka_dict}  Create Dictionary  tenant_id=${tenant_id}  message=without apikey  @timestamp=${@timestamp}
    Send Message To Kafka    logTopic    ${kafka_dict}
    Querying Not Existing Data From Kibana   ${tenant_id}
    ${body}    Get Response Body
    Should Contain   ${body}    IndexMissingException

User can get INVALID_MAPPING_FIELDS message from Kibana
    [Tags]  Graph-3.7  negative  critical  es_migration_TC
    ${message}    Set Variable    Field_validation_not_bool ${time_ms}
    ${json}   Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_boolean":"YES"}
    Send Message To Kafka    logTopic  ${json}
    Sleep   30
    ${result}   Querying Data From Kibana  ${tenant_id}
    Log To Console  ${result}
    Should Be Equal As Strings    ${result[0]['_source']['message']}   INVALID_MAPPING_FIELDS
    Should Be Equal As Strings    ${result[0]['_source']['@rawMessage']}  ${json}
    ${res}   Return Full Es Message   /${ES_index}/logs/  INVALID_MAPPING_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

User can get MISSING_REQUIRED_FIELDS message from Kibana
    [Tags]  Graph-3.8  negative  critical  es_migration_TC
    ${message}   Set Variable   Field_validation_some_@timestamp ${datetime}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","some_@timestamp":"${@timestamp}","message":"${message}"}
    Send Message To Kafka    logTopic    ${json}
    Sleep    30
    ${result}   Querying Data From Kibana  ${tenant_id}
    Log To Console  ${result}
    Should Be Equal As Strings    ${result[0]['_source']['message']}   MISSING_REQUIRED_FIELDS
    Should Be Equal As Strings    ${result[0]['_source']['@rawMessage']}  ${json}
    #-------------------------------------------------------------------------
    ${res}   Return Full Es Message   /${ES_index}/logs/  MISSING_REQUIRED_FIELDS
    Delete Message From Es  /${ES_index}/logs/   ${res['_id']}

*** Keywords ***
Successful creating of index  [Arguments]  ${kafka_dict}
    Send Message To Kafka    logTopic    ${kafka_dict}
    Sleep   60
    ${result}   Querying Data From Kibana  ${tenant_id}
    Remove From Dictionary    ${result[0]['_source']}    @timestamp  tags  messageId
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${result[0]['_source']}  ${kafka_dict}
    Length Should Be  ${result}  1

Querying Data From Kibana  [Arguments]  ${id}
     Set Headers    {"X-Auth-token": "${PKI_TOKEN}", "X-Tenant": "${Tenant}"}
     Set Global Variable    ${url}    ${IP_web}/elasticsearch/openstack-${tenant_id}-${Y.M.D}/_search
     Log    "GET request on link ${url}"
     Set Global Variable    ${method}    POST
     ${body}  Convert To Dictionary     {"query":{"filtered":{"query":{"bool":{"should":[{"query_string":{"query":"*"}}]}},"filter":{"bool":{"must":[{"range":{"@timestamp":{"from":1418789244552,"to":"now"}}}]}}}},"highlight":{"fields":{},"fragment_size":2147483647,"pre_tags":["@start-highlight@"],"post_tags":["@end-highlight@"]},"size":500,"sort":[{"@timestamp":{"order":"desc"}},{"@timestamp":{"order":"desc"}}]}
     ${body}  Convert To Json  ${body}
     Set Body  ${body}
     POST Request    ${url}
     ${body}    Get Response Body
     [Return]  ${body['hits']['hits']}

Querying Not Existing Data From Kibana  [Arguments]  ${id}
     Set Headers    {"X-Auth-token": "${PKI_TOKEN}", "X-Tenant": "${Tenant}"}
     Set Global Variable    ${url}    ${IP_web}/elasticsearch/openstack-${tenant_id}-${Y.M.D}/_search
     Log    "GET request on link ${url}"
     Set Global Variable    ${method}    POST
     ${body}  Convert To Dictionary     {"query":{"filtered":{"query":{"bool":{"should":[{"query_string":{"query":"*"}}]}},"filter":{"bool":{"must":[{"range":{"@timestamp":{"from":1418789244552,"to":"now"}}}]}}}},"highlight":{"fields":{},"fragment_size":2147483647,"pre_tags":["@start-highlight@"],"post_tags":["@end-highlight@"]},"size":500,"sort":[{"@timestamp":{"order":"desc"}},{"@timestamp":{"order":"desc"}}]}
     ${body}  Convert To Json  ${body}
     Set Body  ${body}
     POST Request    ${url}