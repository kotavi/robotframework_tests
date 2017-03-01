*** Settings ***
Documentation     Can be used to create new indexes with method "Send Bunch Of Messages"
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
Test Setup  Run Keywords    Create body for es_request

*** Test Cases ***
Send bunch of messages to ES
    ${index}  Get old index for tenant  ${ES_index}   -3days
    Log To Console   1) ${index}
    Send Bunch Of Messages  /${index}/logs/  count=${5000000}  size=10  body=${es_dict}  delay=${0.000001}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
#    ${old_index}  Get old index for tenant  ${ES_index}   1days
#    Send Bunch Of Messages  /${old_index}/logs/  count=${4702796}  size=2  body=${es_dict}  delay=${0.0001}
    Log To Console   TOTAL SIZE = ${total_size}


Send ${num} logs of ${len} length to Kafka in time range for ${day} ${start} - ${end} with lag ${sec}
    [Tags]  load_es_queries
#    ${timerange_start}  2014-12-09T12:00:00.000Z
#    ${timerange_end}  2014-12-10T12:00:00.000Z
    ${index}  Get old index for tenant  ${ES_index}   ${day}
    ${delay}  Set Variable   ${${sec}}
    : FOR    ${i}    IN RANGE    ${num}
    \    Get datetime
    \    ${template}    Generate Random String   ${len}   [LETTERS]
    \    ${message}  Set variable  ${template} ${time_ms}
    \    ${rnd_date}  Get Random Date    ${start}  ${end}  %Y-%m-%dT%H:%M:%S.000Z
    \    ${json}    Create Dictionary   host_name=qa-test  message=${message}  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${rnd_date}
    \    ${message_id}  User Send Message To ES  /${index}/logs/  ${json}
#    \    Sleep   ${delay}

#pybot -i load_es_queries -v num:500 -v sec:${0.0001} -v len:100 -v day:-3day -v start:2015-04-27T12:00:00.000Z -v end:2015-04-27T22:00:00.000Z

*** Keywords ***
Create body for es_request
    ${es_dict}   Create Dictionary     apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Set Global Variable  ${es_dict}  ${es_dict}