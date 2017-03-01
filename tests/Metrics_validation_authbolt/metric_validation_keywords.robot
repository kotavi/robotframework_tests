*** Settings ***
Documentation    Suite description
Resource        ../micro_services/keywords/tenant_management_settings.robot
Resource        ../micro_services/keywords/logging_service_settings.robot
Resource        ../micro_services/keywords/REST_keywords.robot
Resource        ../micro_services/keywords/variables_settings.robot
Resource        ../keywords/keywords.robot

Library         ../libs/KafkaClient.py
Library         ../libs/InfluxClient.py
Library           Collections
Library           String

*** Variables ***
${logging_service_id}  1
${delay}   40

*** Keywords ***
Create tenant
    ${tenant_id}    Generate Random String   32  [LOWER]
    ${tenant_name}    Generate Random String   17  [LETTERS][NUMBERS]
    ${body}  Set Variable  {"tenant_name": "${tenant_name}","tenant_id": "${tenant_id}"}
    Simple user can send POST request for '${MS_url_path}/' with body '${body}'
    Response code should be 201
    Set Global Variable  ${tenant_id}   ${tenant_id}
    #---get apikey
    User can send GET request to retreive info for specific tenant   ${MS_url_path}/${tenant_id}/apikey  ${roles['2']}  ${tenant_id}  ${sudo_user}
    Response code should be 200
    ${response_body}    Get Response Body
    Set Global Variable  ${apikey}   ${response_body[0]['apikey']}
    Sleep  15
    #---check kafka topic
    ${results}    Get Message From Kafka By key    ${tenantTopic}    {"tenant_id":"${tenant_id}"}
    ${results}  convert to string  ${results}
    should contain  ${results}  ${apikey}
    should contain  ${results}  created_apiKey
    [Return]  ${tenant_id}  ${apikey}

Create global tenant and apikey
    ${tenant_id_global}  ${apikey_global}   Create tenant
    Set Global Variable  ${tenant_id_global}   ${tenant_id_global}
    Set Global Variable  ${apikey_global}   ${apikey_global}

Create apikey for '${tenant_id}'
    ${description}    Generate Random String   17  [LOWER][NUMBERS]
    User can send POST request for specific tenant  ${MS_url_path}/${tenant_id}/apikey?description=${description}  ''  ${roles['1']}  ${tenant_id}  ${sudo_user}
    Response code should be 201
    ${response_body}    Get Response Body
    Should Be Equal   ${response_body['type']}  ok
    ${apikey}  Set Variable  ${response_body['message'][15:47]}
    Should Be Equal   ${response_body['message']}  Created apikey ${apikey} for tenant id ${tenant_id}
    [Return]  ${apikey}

Delete apikey   [Arguments]  ${apikey}   ${tenant_id}
    User can send DELETE request for specific tenant  ${MS_url_path}/${tenant_id}/apikey?apikey=${apikey}   ${roles['1']}  ${tenant_id}  ${sudo_user}
    Response code should be 200
    Sleep  15
    User can send GET request to retreive info for specific tenant   ${MS_url_path}/${tenant_id}/apikey  ${roles['2']}  ${tenant_id}  ${sudo_user}
    Response code should be 200
    ${response_body}    Get Response Body
    ${response_body}  convert to string   ${response_body}
    should not contain  ${response_body}  ${apikey}

Response code should be ${status_code}
    ${response_body}    Get Response Body
    Log    ${response_body}
    ${response_code}    Get Response Code
    Run Keyword If    ${status_code} != ${response_code}    Fail    "Response code: ${response_code}. Response body: ${response_body}"

Delete tenant '${tenant_id}'
    User can send DELETE request for specific tenant  ${MS_url_path}/${tenant_id}   ${roles['1']}  ${tenant_id}  ${sudo_user}
    Response code should be 200
    Sleep  15
    User can send GET request to retreive info for specific tenant   ${MS_url_path}/${tenant_id}/apikey  ${roles['2']}  ${tenant_id}  ${sudo_user}
    Response code should be 404
    ${response_body}    Get Response Body

Update apikey '${apikey}' for '${tenant_id}' with status '${status}'
    ${body}  Set Variable  {"apikey": "${apikey}","enabled": "${status}"}
    User can send PUT request for specific tenant  ${MS_url_path}/${tenant_id}/apikey?apikey=${apikey}  ${body}  ${roles['2']}  ${tenant_id}  ${sudo_user}
    Response code should be 200
    ${response_body}    Get Response Body
    #---check that apikey was disabled
    User can send GET request to retreive info for specific tenant   ${MS_url_path}/${tenant_id}/apikey?apikey=${apikey}  ${roles['2']}  ${tenant_id}  ${sudo_user}
    Response code should be 200
    ${response_body}    Get Response Body
#    should be equal as strings   ${response_body[0]['enabled']}  ${status}
    sleep  15

Post correct metric event to Kafka
    ${message}    Set Variable    correct log message to Kafka
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${message}  @timestamp=${@timestamp}  some_int=${34}
    Send Message To Kafka    logTopic    ${kafka_dict}
    ${results}    Get Message From Kafka By key    metricTopic    {"message":"${message}"}
    Dictionaries Should Be Equal    ${results}    ${kafka_dict}
    Sleep    40
    ${message}  Get Message From Es By Body  /${ES_index}/logs/   ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}

Getting the time in milliseconds
    ${ms}=    Evaluate    int(round(time.time() * 1000))    time
    log    time in ms: ${ms}
    Set Global Variable    ${time_ms}    ${ms}

Drop Databases for '${tenant_id}'
    Delete Influx Database  tenant_${tenant_id}


#Create tenant
#    ${rnd}    Generate Random String   11  [LETTERS]
#    #-----create new tenant--------------------
#    ${role_1}  Set Variable  {"role_id": 1,"idm_group_id": "${ldap_groups['1']}","tenant_email": "${rnd}@gmail.com"}
#    ${body}  Set Variable  {"tenant_name": "lmm-${rnd}","service_id": ${logging_service_id},"roles": [${role_1}]}
#    Send POST request with token  ${tenants_gateway}/tenants   ${body}  ${token_sudo}  ${hmac_sudo}
#    The response code should be 201
#    ${response_body}    Get Response Body
#    Set Global Variable  ${tenant_id}  ${response_body['message'][-36:]}
#    #--get apikey
#    Send GET request with token   ${logging_gateway}/${tenant_id}/apikey  ${token_sudo}  ${hmac_sudo}
#    The response code should be 200
#    ${response_body}    Get Response Body
#    Set Global Variable  ${apikey}   ${response_body['apikey']}
#    #---check kafka topic
#    Check Message In Kafka exists    tenantKeysTopic    ${message}
#    [Return]  ${tenant_id}  ${apikey}

#    Send DELETE request with token    ${logging_gateway}/${tenant_id}/apikey?apikey=${api_key}  ${token_sudo}   ${hmac_sudo}
#    The response code should be 200
#    ${response_body}    Get Response Body
#    Should Be Equal  ${response_body['message']}  Deleted apikey ${apikey}


#Execute precondition
#    Get credentials for '${sudo_user}', '${sudo_pass}'
#    Get the LDAP groups that user belongs to
#    Set Global Variable  ${token_sudo}   ${token}
#    Set Global Variable  ${hmac_sudo}   ${hmac}
#    Set Global Variable  ${ldap_groups_sudo}   ${sudo_ldap_groups}