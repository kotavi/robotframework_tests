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

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords   Get date and _index for Elasticsearch (Y.M.D)  Get datetime

*** Variables ***
${message}  some_text
${log_number}  10000
${delay}  1
${timerange_start}  2014-12-09T12:00:00.000Z
${timerange_end}  2014-12-10T12:00:00.000Z

*** Test Cases ***
Fill in ES with batch of data
    [Documentation]  Case used to fill ES with logs in current time
    [Tags]   load_es_current
    Log To Console  \n ---- Start time ${@timestamp}
    Send ${log_number} logs to Kafka in current time with lag ${delay}

Fill in ES with data from different time range
    [Documentation]  Case used to fill ES with logs in current time
    [Tags]   load_es_old
    Log To Console  \n ---- Start time ${@timestamp}
    Send ${log_number} logs to Kafka in time range ${timerange_start} - ${timerange_end} with lag ${delay}

Fill in ES through logstash
    [Documentation]  Case used to fill ES with logs in current time
    [Tags]   load_es_ls
    Log To Console  \n ---- Start time ${@timestamp}
    Update file ${ls_path} with ${log_number} logs with '${message}' in current time with lag ${delay}

*** Keywords ***
Send ${num} logs to Kafka in current time with lag ${sec}
    ${warning}  Set Variable   Mising data detected
    : FOR    ${index}    IN RANGE    ${num}
    \    Get datetime
    \    ${message}  Generate random message
    \    ${json}  Create Dictionary   host_name=qa-test  message=${message}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    \    ${res}  Send Message To Kafka   logTopic  ${json}
    \    Sleep  ${sec}
    \    ${res}  Count All ES Messages   /${ES_index}/logs/
    \    Run Keyword Unless  ${res}==${index+1}  Log To Console  ${warning}: found ${res}, should be ${index+1}

Send ${num} logs to Kafka in time range ${start} - ${end} with lag ${sec}
    ${warning}  Set Variable   Mising data detected
    : FOR    ${index}    IN RANGE    ${num}
    \    ${message}  Generate random message
    \    ${ip}  Define Ip  ${kafka_cluster}
    \    ${rnd_date}  Get Random Date    ${start}  ${end}  %Y-%m-%dT%H:%M:%S.000Z
    \    ${json}    Create Dictionary   host_name=qa-test  message=${message}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${rnd_date}
    \    ${res}  Send Message To Kafka By Broker Ip  ${ip}  logTopic  ${json}
    \    ${error}   Set Variable  KAFKA ERROR: ${ip}
    \    Run Keyword If   '${res}'=='${error}'   Log To Console  No logTopic on ${ip} node
    \    ${ip_es}  Define Ip  ${es_cluster}
    \    ${res}  Count All ES Messages By Host   ${ip_es}  /${ES_index}/logs/
    \    Run Keyword Unless  ${res}==${index+1}  Log To Console  ${warning}: found ${res}, should be ${index+1} for ${ip} node

Update file ${ls_path} with ${num} logs with '${message}' in current time with lag ${sec}
    ${warning}  Set Variable   Mising data detected
    : FOR    ${index}    IN RANGE    ${num}
    \    ${msg}  Generate random message
    \    Append to file    ${ls_path}   ${message}+${msg}\n
    \    Sleep  ${sec}
    \    ${ip_es}  Define Ip  ${es_cluster}
    \    ${res}  Count All ES Messages By Host   ${ip_es}  /${ES_index}/logs/
    \    Run Keyword Unless  ${res}==${index+1}  Log To Console  ${warning}: found ${res}, should be ${index+1} for ${ip} node

Count logs in ES_index  [Arguments]  ${ES_index}
    ${n}    Count All Es Messages    /${ES_index}/logs/
    [Return]  ${n}

Generate random message
    Get datetime
    ${template}    Generate Random String   30   [LETTERS]
    ${message}  Set variable  ${template} ${time_ms}
    [Return]  ${message}

Delete logs from unknown index
    Delete Index From Es   ${ES_unknown}
    The response code should be 200

Delete logs from index
    Delete Index From Es   ${ES_index}
    The response code should be 200