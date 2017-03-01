*** Settings ***
Resource          ../tests/keywords/keywords.robot
Library           Collections
Library           ../tests/libs/OperatingSystem.py

Suite Setup  Run Keywords   Get datetime

*** Variables ***
${topology_summ}  /api/v1/topology/summary
${topology}       /api/v1/topology

*** Test Cases ***
Request the topology summary
    [Tags]  ITC-St-4
    Set Global Variable    ${url}    http://${storm_ip}:${storm_port}${topology_summ}
    Set Global Variable    ${method}    GET
    Log    "GET request on link ${url}"
    GET Request    ${url}
    ${response_body}    Get Response Body
    Log   ${response_body}
    Log To Console   ${response_body}
    Log To Console   ${response_body['topologies'][0]['id']}
    Log To Console   ${response_body['topologies'][1]['id']}
    Log To Console   ${response_body['topologies'][2]['id']}
    Log To Console   ${response_body['topologies'][3]['id']}
    Log To Console   ${response_body['topologies'][4]['id']}
#    Set Global Variable  ${log_topology}  ${response_body['topologies'][4]['id']}
#    Set Global Variable  ${metric_topology}  ${response_body['topologies'][2]['id']}

Get latency info for ${log_topology} and ${metric_topology}
    [Tags]  latency
    Append To File    log_latency_res.csv   --------------${@timestamp}--------------\n
    Append To File    log_latency_res.csv    ----------------------------------------------------------------------------------------------------------------------------------\n
    Append To File    log_latency_res.csv    ${@timestamp}| status |exec|work| spoutid | boltId | latency |acked|processL|executeL| acked | boltId | processL | executeL | acked | boltId | processL | executeL | acked \n

    Append To File    metric_latency_res.csv   --------------${@timestamp}--------------\n
    Append To File    metric_latency_res.csv    ----------------------------------------------------------------------------------------------------------------------------------\n
    Append To File    metric_latency_res.csv    ${@timestamp}| status |exec|work| spoutid | boltId | latency |acked|processL|executeL| acked | boltId | processL | executeL | acked | boltId | processL | executeL | acked \n

    : FOR  ${i}  IN RANGE  ${2000000}
    \     Get information on latency for ${log_topology}
    \     ${spouts_acked}   Set Variable   ${response_body['spouts'][1]['acked']}
    \     ${spouts_latency}   Set Variable   ${response_body['spouts'][1]['completeLatency']}
    \     Append To File    log_latency_res.csv     ----------------------------------------------------------------------------------------------------------------------------------\n
    \     Append To File    log_latency_res.csv     ${@timestamp}|${status} | ${executors} | ${workers} | ${spouts[1]['encodedSpoutId']} | ${spouts_latency} | ${spouts_acked} | ${bolts[2]['boltId']} | ${bolts[2]['processLatency']} | ${bolts[2]['executeLatency']} | ${bolts[2]['acked']} | ${bolts[4]['boltId']} | ${bolts[4]['processLatency']} | ${bolts[4]['executeLatency']} | ${bolts[4]['acked']} | ${bolts[6]['boltId']} | ${bolts[6]['processLatency']} | ${bolts[6]['executeLatency']} | ${bolts[4]['acked']} \n
#${status} | ${executors} | ${workers} | ${spouts_latency} | ${spouts_acked}
#------------------------------------------------------------------------
    \     Get information on latency for ${metric_topology}
    \     ${spouts_acked}   Set Variable   ${response_body['spouts'][1]['acked']}
    \     ${spouts_latency}   Set Variable   ${response_body['spouts'][1]['completeLatency']}
    \     Append To File    metric_latency_res.csv     ----------------------------------------------------------------------------------------------------------------------------------\n
    \     Append To File    metric_latency_res.csv    ${@timestamp}|${status} | ${executors} | ${workers} | ${spouts[1]['encodedSpoutId']} | ${bolts[2]['boltId']} | ${spouts_latency} | ${spouts_acked} | ${bolts[2]['processLatency']} | ${bolts[2]['executeLatency']} | ${bolts[2]['acked']} | ${bolts[4]['boltId']} | ${bolts[4]['processLatency']} | ${bolts[4]['executeLatency']} | ${bolts[4]['acked']} | ${bolts[5]['boltId']} | ${bolts[5]['processLatency']} | ${bolts[5]['executeLatency']} | ${bolts[5]['acked']} \n
    \     Sleep  ${5}



#pybot -i latency -v log_topology:Remote-DevTest-Log-21-1427317088 -v metric_topology:Remote-DevTest-Metric-22-1427317099
*** Keywords ***
Get information on latency for ${id}
    Set Global Variable    ${url}    http://${storm_ip}:${storm_port}${topology}/${id}
    Set Global Variable    ${method}    GET
    Log    "GET request on link ${url}"
    GET Request    ${url}
    ${response_body}    Get Response Body
    Set Global Variable   ${response_body}  ${response_body}
    Set Global Variable   ${status}   ${response_body['status']}
    Set Global Variable   ${bolts}   ${response_body['bolts']}
    Set Global Variable   ${spouts}   ${response_body['spouts']}
    Set Global Variable   ${executors}   ${response_body['executorsTotal']}
    Set Global Variable   ${workers}   ${response_body['workersTotal']}

