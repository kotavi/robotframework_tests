*** Settings ***
#Documentation     Positive cases for fields of different types
Resource          ../keywords/keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/ElasticSearchClient.py
Library           ../libs/KafkaClient.py

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords   Get datetime
Test Setup        Run Keywords      Get datetime
Suite Teardown    Run Keywords     Clean index

*** Test Cases ***
Send message to logTopic with two apikey fields with the same values
    [Tags]  ITC-3.45  negative   es_migration_TC
    Create index in es shoud fail  {"apikey":"${apikey}","apikey":"${apikey}","tenant_id":"${tenant_id}","message":"duplication field apikey ${@timestamp}","@timestamp":"${es_time}","some_int":7}
    
Send message to logTopic with two apikey fields with the different values
    [Tags]  ITC-3.46  negative  storm_migration_TC
    Create index in es shoud fail  {"apikey":"${apikey}","apikey":"asdaa2134agbnje","tenant_id":"${tenant_id}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","some_int":6}

Send message to logTopic with two tenant_id fields
    [Tags]  ITC-3.47  negative  smoke
    Create index in es shoud fail  {"apikey":"${apikey}","tenant_id":"${tenant_id}","tenant_id":"${tenant_id}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","some_int":5}

Send message to logTopic with two message fields
    [Tags]  ITC-3.48  negative
    Create index in es shoud fail  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"Field_validation_two_message_fields","message":"Field_validation_two_message_fields","@timestamp":"${@timestamp}","some_int":4}

Send message to logTopic with two @timestamp fields 
    [Tags]  ITC-3.49  negative  smoke
    Create index in es shoud fail  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","@timestamp":"${@timestamp}","some_int":3}

Send message to logTopic with two @version field
    [Tags]  ITC-3.50  negative  storm_migration_TC
    Create index in es shoud fail  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","@version"=1,"@version"=1,"some_int":1}

Send message to logTopic with two pid_int field
    [Tags]  ITC-3.51  negative  storm_migration_TC
    Create index in es shoud fail   {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","some_int":2,"some_int":2}

*** Keywords ***
Create index in es shoud fail  [Arguments]  ${body}
    Get date and _index for Elasticsearch (Y.M.D)
    Send Message To Kafka    logTopic  ${body}
    Sleep   2
    ${res_bool}  Check Index Exists    /${ES_index}
    ${res_str}  Convert To String    ${res_bool}
    Should Be Equal As Strings  ${res_str}   False

Clean index
   Delete Index From Es  ${ES_index}