*** Settings ***
Documentation     Can be used to execute long run cases to test issues with missing data in Grafana
Resource          ../tests/keywords/keywords.robot
Resource          ../tests/keywords/variables_keywords.robot
Resource          ../tests/keywords/prepopulate_data.robot
Library           String
Library           ../tests/libs/simple_REST.py
Library           ../tests/libs/InfluxClient.py
Library           ../tests/libs/KafkaClient.py
Library           Collections
Library             ../tests/libs/Additional.py
Library           ../tests/libs/OperatingSystem.py

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords   Get datetime  Get date and _index for Elasticsearch (Y.M.D)

*** Variables ***
${metric_name}  test_inxlux
${metric_number}  6000
${delay}  1
${timerange_start}  2014-12-09T12:00:00.000Z
${timerange_end}  2014-12-10T12:00:00.000Z

*** Test Cases ***
Fill in Influx with current data
    [Tags]   load_influx_current
    Log To Console  \n ---- Start time ${@timestamp}
    ${int}  Set variable  90
    ${cpu_id}    Generate Random String   30   [LETTERS]
    ${pid}    Generate Random String   5   [NUMBERS]
    : FOR    ${index}    IN RANGE    ${metric_number}
    \    ${cpu_id}    Generate Random String   30   [LETTERS]
    \    Get datetime
    \    ${json}   Set Variable   {"cpu_id":"${cpu_id}","@version":"1","@timestamp":"${@timestamp}","host":"qa-test-node","name":"${metric_name}","value":${int},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    \    Send Message To Kafka  metricTopic  ${json}
    \    Sleep  ${delay}


Fill in Influx with batch of data in different time range
    [Documentation]  Case used to fill InfluxDB with logs in time range defined in the test
    [Tags]   load_influx
    Log To Console  \n ---- Start time ${@timestamp}
    Send ${metric_number} metrics (${metric_name}) to Kafka in time range ${timerange_start} - ${timerange_end}

Fill in Influx through logstash
    [Tags]   load_influx_ls
    Log To Console  \n ---- Start time ${@timestamp}
    Update file ${ls_path} with ${num} metric ${metric_name} in current time with lag ${sec}

*** Keywords ***
Send ${num} metrics (${mtr}) to Kafka in current time with lag ${sec}
    ${metric}  Set variable  qa.${mtr}
    ${warning}  Set Variable   Mising data detected
    ${int}  Set variable  90
#    ${search_req}    Set variable    select count (value) from ${tenant_id}_${metric}_ where value='${int}'
    : FOR    ${index}    IN RANGE    ${num}
    \    Get datetime
    \    ${json}    Create Dictionary   host=qa-test   @version=1  name=${metric}  value=${int}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    \    Send Message To Kafka  metricTopic  ${json}
    \    Sleep  ${sec}
    \    Log To Console   ${i}
#    \    ${res}  Count metrics in Influx for  ${search_req}  ${metric}  ${tenant_id}  ${db_name}
#    \    Run Keyword Unless  ${res}==${index+1}  Log To Console  ${warning}: found ${res}, should be ${index+1}

Send ${num} metrics (${mtr}) to Kafka in time range ${start} - ${end}
    ${metric}  Set variable  qa.${mtr}
    ${warning}  Set Variable   Mising data detected
    ${int}  Set variable  10
    ${search_req}    Set variable    select count (value) from ${tenant_id}_${metric}_ where value='${int}'
    : FOR    ${index}    IN RANGE    ${num}
#    \    ${val}    Generate Random String   3   123456789
#    \    ${int}  Convert To Integer   ${val}
    \    ${rnd_date}  Get Random Date    ${start}  ${end}  %Y-%m-%dT%H:%M:%S.000Z
    \    ${json}    Create Dictionary   host=qa-test   @version=1  name=${metric}  value=${int}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${rnd_date}
    \    Send Message To Kafka  metricTopic  ${json}
    \    ${res}  Count metrics in Influx for  ${search_req}  ${metric}  ${tenant_id}  ${db_name}
    \    Run Keyword Unless  ${res}==${index+1}  Log To Console  ${warning}: found ${res}, should be ${index+1} (${index+1} - ${res})
    \    Sleep   10

Update file ${ls_path} with ${num} metric ${metric_name} in current time with lag ${sec}
    #check the metric name in ls_metric.conf
    ${metric}  Set variable  ${metric_name}
    ${warning}  Set Variable   Mising data detected
    Drop created table ${tenant_id}_${metric}_
    Sleep  5
    ${search_req}    Set variable    select count (value) from ${tenant_id}_${metric}_ where tenant_id='${tenant_id}'
    : FOR    ${index}    IN RANGE    ${num}
    \    Append to file    ${ls_path}   32\n
    \    Sleep  ${sec}
    \    ${res}  Count metrics in Influx for  ${search_req}  ${metric}  ${tenant_id}  ${db_name}
    \    Run Keyword Unless  ${res}==${index+1}  Log To Console  ${warning}: found ${res}, should be ${index+1} (${index+1} - ${res})

Count metrics in Influx for  [Arguments]  ${search_req}  ${metric}  ${tenant_id}  ${db_name}
    ${result}  Querying Data From Influx  ${db_name}  ${search_req}
    [Return]  ${result[0]["points"][0][1]}

Drop created table ${table}
    Delete Influx Series  ${db_name}  ${tenant_id}_${table}_