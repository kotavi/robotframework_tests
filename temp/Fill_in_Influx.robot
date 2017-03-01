*** Settings ***
Documentation     Can be used to create new tabes in nfluxDB with method "Write Data To Influx"
Resource          ../tests/keywords/keywords.robot
Resource          ../tests/keywords/variables_keywords.robot
Resource          ../tests/keywords/prepopulate_data.robot
Library           ../tests/libs/Additional.py
Library           ../tests/libs/simple_REST.py
Library           ../tests/libs/InfluxClient.py

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords    Get datetime  Create variables

*** Test Cases ***
Write tables from Grafana to verify that all data are accessible
    [Tags]  load_influx
    : FOR  ${i}  IN RANGE   1000
    \    Get datetime
    \    ${int} =	Evaluate	random.randint(100, 500)	random,sys
    \    Getting the time in milliseconds
    \    Write Data To Influx  tenant_${tenant_id}  [{"measurement": "${metric_name}","tags": {"host": "server_${metric_name}","region": "mtv"},"time": "${@timestamp}","fields": {"value": ${int}.${time_ms}}}]
    \    Sleep   ${0.001}

*** Keywords ***
Getting the time in milliseconds
    ${ms}=    Evaluate    int(round(time.time() * 1000))    time
    log    time in ms: ${ms}
    Set Global Variable    ${time_ms}    ${ms}

Create variables
   Set global variable  ${metric_name}   qa.influx_grafana_test