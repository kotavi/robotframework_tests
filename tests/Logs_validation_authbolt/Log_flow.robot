*** Settings ***
Resource          ../keywords/searchguard_settings.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/KafkaClient.py

Suite Setup   Execute Preconditions 
Test Setup        Run Keywords   Get datetime
Test Teardown     Run Keywords   Clean index

*** Variables ***
${delay}   30

*** Test Cases ***
#-------Empty_fields------------------------
Log event is rejected by topology when sent with empty apikey field
    [Tags]  ITC-log-flow-sg-1.1  negative
    ${message}    Set Variable    empty apikey field ${time_ms}
    ${json}  Set Variable  {"apikey":"","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"456","hostname_string":"hello","priority_boolean":"False","myhost_ip":"172.18.196.23"}
    Send Message To Kafka    logTopic  ${json}
    ${results}    Get Message From Kafka By key    logTopic    {"message":"${message}"}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body
    Log  ${response_body}

User gets 'MISSING_REQUIRED_FIELDS' message when sending log event with empty message field
    [Tags]  ITC-log-flow-sg-1.2  negative
    ${message}    Set Variable    ""
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":${message},"@timestamp":"${@timestamp}","some_int":7}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   MISSING_REQUIRED_FIELDS

User gets 'MISSING_REQUIRED_FIELDS' message when sending log event with empty @timestamp field
    [Tags]  ITC-log-flow-sg-1.3  negative
    ${message}    Set Variable    empty @timestamp ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"","some_int":7}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   MISSING_REQUIRED_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when sending log event with empty name pattern int
    [Tags]    ITC-log-flow-sg-1.4  negative
    ${message}    Set Variable    empty name pattern int ${time_ms}
    ${json}   Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":""}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when sending log event with empty name pattern double
    [Tags]    ITC-log-flow-sg-1.5  negative
    ${message}    Set Variable    empty name pattern double ${time_ms}
    ${json}   Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_double":""}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when sending log event with empty name pattern boolean
    [Tags]    ITC-log-flow-sg-1.6  negative
    ${message}    Set Variable    empty name pattern boolean ${time_ms}
    ${json}   Set Variable   {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_boolean":""}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

#-------Field_duplication------------------------
Log event is rejected by topology when sent with double apikey field
    [Tags]  ITC-log-flow-sg-2.1  negative
    ${json}   Set Variable   {"apikey":"${apikey}","apikey":"${apikey}","tenant_id":"${tenant_id}","message":"duplication field apikey ${@timestamp}","@timestamp":"${es_time}","some_int":7}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

Log event is rejected by topology when sent with two apikey fields with the different values
    [Tags]  ITC-log-flow-sg-2.2  negative
    ${json}   Set Variable   {"apikey":"${apikey}","apikey":"asdaa2134agbnje","tenant_id":"${tenant_id}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","some_int":6}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

Log event is rejected by topology when sent with two tenant_id fields
    [Tags]  ITC-log-flow-sg-2.3  negative
    ${json}   Set Variable   {"apikey":"${apikey}","tenant_id":"${tenant_id}","tenant_id":"${tenant_id}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","some_int":5}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

Log event is rejected by topology when sent with two message fields
    [Tags]  ITC-log-flow-sg-2.4  negative
    ${json}   Set Variable   {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"Field_validation_two_message_fields","message":"Field_validation_two_message_fields","@timestamp":"${@timestamp}","some_int":4}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

Log event is rejected by topology when sent with two @timestamp fields
    [Tags]  ITC-log-flow-sg-2.5  negative  smoke
    ${json}   Set Variable   {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","@timestamp":"${@timestamp}","some_int":3}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

Log event is rejected by topology when sent with two @version field
    [Tags]  ITC-log-flow-sg-2.6  negative  storm_migration_TC
    ${json}   Set Variable   {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","@version"=1,"@version"=1,"some_int":1}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

Log event is rejected by topology when sent with two pid_int field
    [Tags]  ITC-log-flow-sg-2.7  negative
    ${json}   Set Variable   {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","some_int":2,"some_int":2}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

#-------Field_too_long------------------------
User gets 'INVALID_MAPPING_FIELDS' message when sending log event with field pid_int of 500 digits
    [Tags]  ITC-log-flow-sg-3.1  negative
    ${pid_int}    Generate Random String   500  [NUMBERS]
    ${message}   Set Variable   field pid_int too long ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","@timestamp":"${@timestamp}","message":"${message} Too long pid","pid_int":${pid_int}}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User can send log event with field hostname_string of 1000 symbols
    [Tags]  ITC-log-flow-sg-3.2   positive
    ${hostname}    Generate Random String   1000  [LETTERS][NUMBERS]
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","@timestamp":"${@timestamp}","message":"${time_ms} Too long hostname","hostname":"${hostname}"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['hostname']}   ${hostname}

User can send log event with field version of 266 digits
    [Tags]  ITC-log-flow-sg-3.3  positive
    ${version}  Generate Random String   266  [NUMBERS]
    ${message}   Set Variable   ${time_ms} Too long version
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","@timestamp":"${@timestamp}","message":"${message}","version":"${version}"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['version']}   ${version}

User gets 'INVALID_MAPPING_FIELDS' message when sending log event with field pattern int too long
    [Tags]  ITC-log-flow-sg-3.4  negative
    ${some_int}  Generate Random String   100  [NUMBERS]
    ${message}   Set Variable   field pattern int too long ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","@timestamp":"${@timestamp}","message":"${message}","some_int":${some_int}}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User can send log event with field pattern double too long
    [Tags]  ITC-log-flow-sg-3.5  positive
    ${some_double}  Generate Random String   100  [NUMBERS]
    ${message}   Set Variable   field pattern double too long ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","@timestamp":"${@timestamp}","message":"${message}","some_double":0.${some_double}}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}

#-------Incorrect_field_name------------------------
Log event is rejected by topology when sent instead of apikey - api_key field name
    [Tags]  ITC-log-flow-sg-4.1   negative
    ${message}    Set Variable    Field_validation_api_key ${datetime}
    ${json}   Set Variable  {"api_key":"${apikey}","tenant_id":"${tenant_id}","@timestamp":"${@timestamp}","message":"${message}"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

User gets 'MISSING_REQUIRED_FIELDS' message when sending instead of @timestamp - timestamp field name
    [Tags]  ITC-log-flow-sg-4.2   negative
    ${message}    Set Variable    Field_validation_timestamp ${datetime}
    ${json}   Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","timestamp":"${@timestamp}","message":"${message}"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   MISSING_REQUIRED_FIELDS

#-------Log_no_field------------------------
Log event is rejected by topology when sent without apikey
    [Tags]  ITC-log-flow-sg-5.1  negative
    ${message}   Set Variable     Field_validation_no_apikey ${datetime}
    ${json}   Set Variable  {"tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

User gets 'MISSING_REQUIRED_FIELDS' message when sent without message field
    [Tags]  ITC-log-flow-sg-5.2  negative
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","@timestamp":"${@timestamp}"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   MISSING_REQUIRED_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when sent without @timestamp field
    [Tags]  ITC-log-flow-sg-5.3  negative
    ${message}   Set Variable   Field_validation_no_timestamp ${datetime}
    ${json}   Set Variable    {"tenant_id":"${tenant_id}","apikey":"${apikey}","message":"${message}"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   MISSING_REQUIRED_FIELDS

#-------Negative_cases_wrong_data------------------------
Log event is rejected by topology when sent with incorrect value for apikey
    [Tags]   ITC-log-flow-sg-6.1  negative
    ${message}    Set Variable    Incorrect value for apikey ${time_ms}
    ${json}   Set Variable    {"apikey":"${wrong_apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":0}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

Log event is rejected by topology when sent with incorrect value for tenant_id
    [Tags]   ITC-log-flow-sg-6.2  negative
    ${message}    Set Variable    Incorrect value for tenant_id ${time_ms}
    ${json}   Set Variable    {"apikey":"${apikey}","tenant_id":"${wrong_tenant}","message":"${message}","@timestamp":"${@timestamp}","some_int":0}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

User gets 'INVALID_MAPPING_FIELDS' message when event sent with double value in int field
    [Tags]  ITC-log-flow-sg-6.3  negative
    ${message}    Set Variable    Field_validation_not_int_double ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":0.05}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

Log event is rejected by topology when sent with message format - unicode
    [Tags]  ITC-log-flow-sg-6.4  negative
    ${message}    Set Variable    Field_validation_not_int_unicode ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":u"${message}","@timestamp":"${@timestamp}"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 404
    ${response_body}    Get Response Body

User gets 'INVALID_MAPPING_FIELDS' message when event sent with string value in boolean field
    [Tags]  ITC-log-flow-sg-6.5  negative
    ${message}    Set Variable    Field_validation_not_bool ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_boolean":"YES"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with string value in IP field
    [Tags]  ITC-log-flow-sg-6.6  negative
    ${message}    Set Variable    Field_validation_not_ip ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_ip":"my_ip"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with name pattern date (some string - date)
    [Tags]  ITC-log-flow-sg-6.7  negative
    ${message}    Set Variable    Field_validation_not_date_string ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":555,"some_double":0.0001,"some_boolean":"False","basic_date":"date"}
    Send Message To Kafka    logTopic   ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with name pattern boolean (some string - hello world)
    [Tags]  ITC-log-flow-sg-6.8  negative
    ${message}    Set Variable    Field_validation_not_bool_string ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":0,"some_double":0.0,"some_boolean":"hello+world"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with pid_int with letters (e.g. 09rt56)
    [Tags]  ITC-log-flow-sg-6.9  negative
    ${message}    Set Variable    pid_int with letters ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"09rt56"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with pid_int with spases (e.g. 39 56)
    [Tags]  ITC-log-flow-sg-6.10  negative
    ${message}    Set Variable    pid_int with spases ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"39 56"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with pid_int with @#$%^&*()-+ symbols
    [Tags]  ITC-log-flow-sg-6.11  negative
    ${message}    Set Variable    pid_int with @#$%^&*()-+ symbols ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"@#$%^&*()-+"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with pid_int with dot (e.g. 39.56)
    [Tags]  ITC-log-flow-sg-6.12  negative
    ${message}    Set Variable    pid_int with dot ${time_ms}
    ${json}  Set Variable      {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","pid_int":"39.56"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with with hostname field with integer value (e.g. "hostname":1233)
    [Tags]  ITC-log-flow-sg-6.13  negative
    ${message}    Set Variable    hostname field with integer value ${time_ms}
    ${json}  Set Variable      {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","hostname":1233}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with with bool field with "@#$%^&" symbols
    [Tags]  ITC-log-flow-sg-6.14  negative
    ${message}    Set Variable    bool field with @#$%^& symbols ${time_ms}
    ${json}  Set Variable      {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"@#$%^&"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with bool field with spases (e.g. 39 56)
    [Tags]  ITC-log-flow-sg-6.15  negative
    ${message}    Set Variable    bool field with spases ${time_ms}
    ${json}  Set Variable      {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"39 56"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with bool field with dot (e.g. 39.56)
    [Tags]  ITC-log-flow-sg-6.16  negative
    ${message}    Set Variable    bool field with dot ${time_ms}
    ${json}  Set Variable      {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"39.56"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with with bool field with string
    [Tags]  ITC-log-flow-sg-6.17  negative
    ${message}    Set Variable    bool field with string ${time_ms}
    ${json}  Set Variable      {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","priority_boolean":"some_string"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with date field in format yyyyMMdd'T'HHmmss
    [Tags]  ITC-log-flow-sg-6.18  negative
    ${message}    Set Variable    date field in format yyyyMMddTHHmmss ${time_ms}
    ${json}  Set Variable      {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","field_date":"20140915T155300"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with date field in format yyyyMMdd'-'HHmmss
    [Tags]  ITC-log-flow-sg-6.19  negative
    ${message}    Set Variable    date field in format yyyyMMdd-HHmmss ${time_ms}
    ${json}  Set Variable      {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","field_date":"20140915-155300"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with with date field in format yyyy:MM:dd:HH:mm:ss
    [Tags]  ITC-log-flow-sg-6.20  negative
    ${message}    Set Variable    date field in format yyyy:MM:dd:HH:mm:ss ${time_ms}
    ${json}  Set Variable      {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","field_date":"2014:09:15:15:53:00"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

User gets 'INVALID_MAPPING_FIELDS' message when event sent with date field in format HH:mm:ss-yyyy-MM-dd
    [Tags]  ITC-log-flow-sg-6.21  negative
    ${message}    Set Variable    date field in format HH:mm:ss-yyyy-MM-dd ${time_ms}
    ${json}  Set Variable      {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","field_date":"15:53:00-2014-09-15"}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['@rawMessage']}   ${json}
    Should Be Equal   ${response_body['message']}   INVALID_MAPPING_FIELDS

#-------Simple_cases------------------------
Post log message with name pattern int
    [Tags]  ITC-log-flow-sg-7.1  positive
    ${message}    Set Variable    With field {}_int ${datetime}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":${34}}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}
    Execute GET request to '${es_url}/${ES_index}/logs/_count/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings   ${response_body['count']}  1

Post log message with name pattern double
    [Tags]  ITC-log-flow-sg-7.2  positive
    ${message}    Set Variable    With field {}_double ${datetime}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":${34},"some_double":${3.4}}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}
    Execute GET request to '${es_url}/${ES_index}/logs/_count/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings   ${response_body['count']}  1

Post log message with name pattern boolean
    [Tags]  ITC-log-flow-sg-7.3  positive
    ${message}    Set Variable    With field {}_bool ${datetime}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":${0},"some_double":${0.0},"some_boolean":${True}}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}
    Execute GET request to '${es_url}/${ES_index}/logs/_count/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings   ${response_body['count']}  1

Post log message with name pattern date
    [Tags]  ITC-log-flow-sg-7.4  positive
    ${message}    Set Variable    With field {}_date ${datetime}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":${5},"some_double":${0.0001},"some_boolean":${False},"basic_date":"${@timestamp}","test_ip":"172.18.196.26"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}
    Execute GET request to '${es_url}/${ES_index}/logs/_count/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings   ${response_body['count']}  1

Post log message with name pattern @date
    [Tags]  ITC-log-flow-sg-7.5  positive
    ${message}    Set Variable    With field {}_@date ${datetime}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_boolean":${False},"some_@date":"${@timestamp}","test_ip":"172.18.196.26"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}
    Execute GET request to '${es_url}/${ES_index}/logs/_count/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings   ${response_body['count']}  1

Post log message with name pattern @timestamp
    [Tags]  ITC-log-flow-sg-7.6  positive
    ${message}    Set Variable    With field {}_@timestamp ${datetime}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_boolean":${False},"some_@timestamp":"${@timestamp}","test_ip":"172.18.196.26"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}
    Execute GET request to '${es_url}/${ES_index}/logs/_count/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings   ${response_body['count']}  1

Post log message with name pattern with different date fields
    [Tags]  ITC-log-flow-sg-7.7  positive
    ${message}    Set Variable    With all fields ${datetime}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_@date":"${@timestamp}","some_@timestamp":"${@timestamp}","basic_date":"${@timestamp}"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}
    Execute GET request to '${es_url}/${ES_index}/logs/_count/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings   ${response_body['count']}  1

Post log message with name pattern ip
    [Tags]  ITC-log-flow-sg-7.8  positive
    ${message}    Set Variable    With field {}_ip ${datetime}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","test_ip":"172.18.196.26"}
    Send Message To Kafka    logTopic    ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}
    Execute GET request to '${es_url}/${ES_index}/logs/_count/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings   ${response_body['count']}  1

Post log message with int value in double field
    [Tags]  ITC-log-flow-sg-7.9  positive
    ${message}    Set Variable    Field_validation_not_double_int ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_double":5}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}
    Execute GET request to '${es_url}/${ES_index}/logs/_count/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings   ${response_body['count']}  1

Post log message with name pattern ip (some ip without quots)
    [Tags]  ITC-log-flow-sg-7.10   positive
    ${message}    Set Variable    Field_validation_ip_no_quots ${time_ms}
    ${json}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","test_ip":1.1.1.1}
    Send Message To Kafka    logTopic  ${json}
    sleep  ${delay}
    Execute GET request to '${es_url}/${ES_index}/_search/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    ${response_body}   Set Variable  ${response_body['hits']['hits'][0]['_source']}
    Should Be Equal   ${response_body['message']}   ${message}
    Execute GET request to '${es_url}/${ES_index}/logs/_count/' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings   ${response_body['count']}  1

*** Keywords ***
Execute Preconditions
   Get data from keystone with '${keystone_v3}'
   Get datetime
   Get date and _index for Elasticsearch (Y.M.D)
   Clean index

Clean index
    Execute DELETE request to '${es_url}/${ES_index}' with credentials user='${sudo_user}' pass='${sudo_pass}'
    ${response_body}    Get Response Body

Check Message From ES By Body  [Arguments]  ${body}
    ${res}  Get Message From ES By Body  /${ES_index}/logs/  ${body}
    Should Not Be Equal As Strings  ${res}  Message was not found
