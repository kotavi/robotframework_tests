*** Settings ***
Documentation     Can be used to execute long run cases to test issues with missing data in Kibana
Resource          ../tests/keywords/keywords.robot
Resource          ../tests/keywords/variables_keywords.robot
Resource          ../tests/keywords/prepopulate_data.robot
Library           ../tests/libs/Additional.py
Library           ../tests/libs/simple_REST.py
Library           ../tests/libs/ElasticSearchClient.py
Library           ../tests/libs/KafkaClient.py
Library           Collections
Library           String
Library             ../tests/libs/Additional.py
Library           ../tests/libs/OperatingSystem.py

Suite Setup  Run Keywords    Get datetime

*** Variables ***
${log_number}  10000
${metric_num}  10000
${delay}  1
${num}   100
${num_letters}  30
#@{tenant_list}    0b913d65b924449abadb98a7a35399d1      1dd50be286d6483f8f9c9abdadaa2b9f      48a3895748314381853aae4bbdf1e3de      534f8bd7882049ee9bc09379c34e7da1      6e9bdf030e154d4db3fca7fed974bc8e      8afeb90e049741a8a044c905bb6f3275      d9840542280941c2b20a2b71d8f47c49
#@{apikey_list}       b93ccc93-9a35-4986-9d5d-195a75348ff2  350d4ac5-1a4b-42f7-93e8-e1c7b4afba0a  2c71a4ea-4ee3-48b6-ac2b-0b91bd600636  4ba31b8a-38bb-443d-8619-b6be17e2cf05  43afb0d5-0ee0-43d3-b319-3892578cc85b  afe5e75b-5e29-4f0d-994c-be36dbf54f94  e97af0a6-4bf7-41b4-a489-d6545f5dd619
@{tenant_list}    gPj2HsveRgbIG9R4VEbCj5eJinJJ1xha      UBmISrY4ys5JFvbOsVvUF1wcjSz88TrI
@{apikey_list}    025ce62a7f7d442a95435b4d50d4c492  4e68b018fc8e47d8a578c5349acce4c9

*** Test Cases ***
Fill in ES with batch of data
    [Documentation]  Case used to fill ES with logs in current time
    [Tags]   load_es_multy
    Log To Console  \n ---- Start time ${@timestamp}
    Send ${log_number} logs to Kafka in current time with lag ${delay}

Fill in ES with batch of data with random time
    [Documentation]  Case used to fill ES with logs in current time
    [Tags]   load_es_random_time
    Log To Console  \n ---- Start time ${@timestamp}
    : FOR    ${index}    IN RANGE    ${num}
    \    Log To Console  -------------------------------------------------
    \    ${message}  Generate random message
    \    Send log message time range for ${start} - ${end} from multiple tenants
    \    Sleep  ${delay}
#pybot -i load_es_queries -v num:500 -v delay:0.1 -v start:2015-04-27T12:00:00.000Z -v end:2015-04-27T22:00:00.000Z

Fill in ES with batch of data with random message size
    [Documentation]  Case used to fill ES with logs in current time
    [Tags]   load_es_random_message
    Log To Console  \n ---- Start time ${@timestamp}
    : FOR    ${index}    IN RANGE    ${num}
    \    Log To Console  -------------------------------------------------
    \    ${message}  Generate random message
    \    Send log message time range for ${start} - ${end} from multiple tenants
    \    Sleep  ${delay}
    \    ${message}  Generate large message with random size
    \    Send log message time range for ${start} - ${end} from multiple tenants
    \    Sleep  ${delay}

Fill in Inflix with data for different tenants
    [Tags]   load_influx_multy
    Log To Console  \n ---- Start time ${@timestamp}
    Send ${metric_num} metrics with name '${metric_name}' to Kafka in current time with lag ${delay}

Send logs to Kafka from one tenant
    [Tags]  load_es_one
    ${message}  Generate random message
    : FOR    ${index}    IN RANGE    ${log_number}
    \    Get datetime
    \    ${json}  Create Dictionary   host_name=qa-test  message=${message}  apikey=${apikey_list[-1]}  tenant_id=${tenant_list[-1]}  @timestamp=${@timestamp}
    \    ${res}  Send Message To Kafka   logTopic  ${json}
    \    Log To Console  -------------------------------------------------
    \    Log To Console   ${json}
    \    Sleep  ${delay}

#pybot -i load_es_multy -v log_number:20 -v delay:0.2 src/Debug_steps/multiple_tenants.robot
#pybot -i load_influx_multy -v metric_num:20 -v metric_name:new_fancy_name -v delay:0.2 src/Debug_steps/multiple_tenants.robot
*** Keywords ***
Send ${num} logs to Kafka in current time with lag ${sec}
    : FOR    ${index}    IN RANGE    ${num}
    \    Get datetime
    \    Log To Console  -------------------------------------------------
    \    ${message}  Generate random message
    \    Send log message from multiple tenants
    \    Sleep  ${sec}

Send log message from multiple tenants
    ${tenant_list}   Create List  @{tenant_list}
    ${count}  Get Length  ${tenant_list}
    : FOR   ${i}   IN RANGE   ${count}
    \    ${json}  Set Variable   {"host":"lmm-qa","message":"${message}","apikey":"${apikey_list[${i}]}","tenant_id":"${tenant_list[${i}]}","@timestamp":"${@timestamp}"}
    \    ${res}  Send Message To Kafka   logTopic  ${json}
    \    Log To Console   ${json}

Send log message time range for ${start} - ${end} from multiple tenants
    ${tenant_list}   Create List  @{tenant_list}
    ${count}  Get Length  ${tenant_list}
    : FOR   ${i}   IN RANGE   ${count}
    \    ${@timestamp}  Get Random Date    ${start}  ${end}  %Y-%m-%dT%H:%M:%S.000Z
    \    ${json}  Set Variable   {"message":"${message}","apikey":"${apikey_list[${i}]}","tenant_id":"${tenant_list[${i}]}","@timestamp":"${@timestamp}"}
    \    ${res}  Send Message To Kafka   logTopic  ${json}
    \    Log To Console   ${json}

Send ${num} metrics with name '${metric_name}' to Kafka in current time with lag ${sec}
    : FOR    ${index}    IN RANGE    ${num}
    \    Get datetime
    \    Log To Console  -------------------------------------------------
    \    ${message}  Generate random message
    \    Send metric '${metric_name}' event from multiple tenants
    \    Sleep  ${sec}

Send metric '${metr}' event from multiple tenants
    ${tenant_list}   Create List  @{tenant_list}
    ${count}  Get Length  ${tenant_list}
    : FOR   ${i}   IN RANGE   ${count}
    \    Get datetime
    \    ${json}  Create Dictionary   host=qa-test-${metr}  value=${time_ms}  name=${metr}  apikey=${apikey_list[${i}]}  tenant_id=${tenant_list[${i}]}  @timestamp=${@timestamp}
    \    ${res}  Send Message To Kafka   metricTopic  ${json}
    \    Log To Console   ${json}

Generate random message
    Get datetime
    ${template}    Generate Random String   ${num_letters}   [LETTERS]
    ${message}  Set variable  ${template} ${time_ms}
    [Return]  ${message}

Generate message with random size
    Get datetime
    ${number}    Generate Random String   3   [NUMBERS]
    ${template}    Generate Random String   ${number}   [LETTERS]
    ${message}  Set variable  ${template} ${time_ms}
    [Return]  ${message}

Generate large message with random size
    Get datetime
    ${number}    Generate Random String   6   [NUMBERS]
    ${template}    Generate Random String   ${number}   [LETTERS]
    ${message}  Set variable  ${template} ${time_ms}
    [Return]  ${message}