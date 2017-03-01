*** Settings ***
Library           String
Resource          keywords.robot

*** Keywords ***
Create recepient delivery list with '${urls}' and '${emails}'
    ${delivery_list}  Set Variable  [{"type":"email","recipients":[${emails}]},{"type":"callback","recipients":[${urls}]}]
    [Return]  ${delivery_list}

Json for simple log-based rule  [Arguments]   ${not}  ${field}   ${action}   ${value}  ${num} 
    ${template}   Generate Random String   17   [LETTERS] 
    Set Global Variable    ${template}    ${template}
    Set Global Variable    ${templ}    ${template} simple log-based alert #${num} 
    Set Global Variable    ${rule_name}    alert_log_based_rules_${num}
    ${conditions}   Set Variable    {"not":${not},"field":"${field}","action":"${action}","value":${value}} 
    ${delivery_groups}  Set Variable    [{"use_default_delivery":true,"type":"email","name":"Delivery_groups_simple_${num}","template":"${templ}","recipients":[]}] 
    ${log_based_rule}   Set Variable      {"delivery_groups":${delivery_groups},"name":"${rule_name}","condition":${conditions}}
    [Return]  ${log_based_rule}

Json for complex log-based rule  [Arguments]   ${operation}  ${not1}  ${field1}  ${action1}  ${value1}  ${not2}  ${field2}  ${action2}  ${value2}  ${num} 
    ${template}   Generate Random String   17   [LETTERS] 
    Set Global Variable    ${template}    ${template}
    Set Global Variable    ${templ}    ${template} simple log-based alert #${num} 
    Set Global Variable    ${rule_name}    alert_log_based_complex_rules_${num}_${templ}
    ${conditions}   Set Variable    {"operation":"${operation}","conditions":[{"not":${not1},"field":"${field1}","action":"${action1}","value":${value1}},{"not":${not2},"field":"${field2}","action":"${action2}","value":${value2}}]}
    ${delivery_groups}  Set Variable    [{"use_default_delivery":true,"type":"email","name":"Delivery_groups_simple_${num}","template":"${templ}","recipients":[]}] 
    ${log_based_rule}   Set Variable      {"delivery_groups":${delivery_groups},"name":"${rule_name}","condition":${conditions}}
    [Return]  ${log_based_rule}

Json for metric-based rule  [Arguments]   ${metric_name}   ${not}  ${action}   ${value}  ${num}
    ${template}    Generate Random String   17   [LETTERS]
    Set Global Variable    ${templ}    ${template} metric-based alert #${num}
    Set Global Variable    ${rule_name}     alert_metric_based_rules_${num}_${template}
    ${conditions}   Set Variable    {"operation":"AND","conditions":[{"not":false,"field":"name","action":"match","value":"${metric_name}"},{"not":${not},"field":"value","action":"${action}","value":${value}}]}
    ${delivery_groups}  Set Variable    [{"use_default_delivery":true,"type":"email","name":"Delivery_groups_simple_${num}","template":"${templ}","recipients":[]}]
    ${metric_based_rule}   Set Variable      {"delivery_groups":${delivery_groups},"name":"${rule_name}","condition":${conditions}}
    [Return]  ${metric_based_rule}

Json for complex metric-based rule  [Arguments]   ${metric_name}  ${not1}  ${action1}  ${value1}  ${not2}  ${action2}  ${value2}  ${num}
    ${template}    Generate Random String   17   [LETTERS]
    Set Global Variable    ${templ}    ${template} metric-based alert #${num}
    Set Global Variable    ${rule_name}     alert_metric_based_rules_${num}_${templ}
    ${conditions}   Set Variable    {"operation":"AND","conditions":[{"not":false,"field":"name","action":"match","value":"${metric_name}"},{"not":${not1},"field":"value","action":"${action1}","value":${value1}},{"not":${not2},"field":"value","action":"${action2}","value":${value2}}]}
    ${delivery_groups}  Set Variable    [{"use_default_delivery":true,"type":"email","name":"Delivery_groups_simple_${num}","template":"${templ}","recipients":[]}]
    ${metric_based_rule}   Set Variable      {"delivery_groups":${delivery_groups},"name":"${rule_name}","condition":${conditions}}
    [Return]  ${metric_based_rule}

Json for complex metric-based rule with time period  [Arguments]   ${cond}  ${type}  ${time_interval}  ${time_value}  ${metric_name}  ${not1}  ${field1}  ${action1}  ${value1}  ${not2}  ${field2}  ${action2}  ${value2}  ${num}
    ${template}    Generate Random String   17   [LETTERS]
    Set Global Variable    ${templ}    ${template} metric time-based alert #${num}
    ${conditions}   Set Variable    {"operation":"${cond}","conditions":[{"not":false,"field":"name","action":"match","value":"${metric_name}"},{"not":${not1},"field":"${field1}","action":"${action1}","value":${value1}},{"not":${not2},"field":"${field2}","action":"${action2}","value":${value2}}]}
    ${delivery_groups}  Set Variable    [{"use_default_delivery":true,"type":"${type}","name":"Delivery_groups_simple_${num}","template":"${templ}","recipients":[]}]
    ${at_least}   Set Variable   {"duration":"${time_interval}","value":${time_value}}
    Set Global Variable   ${rule_name}   alert_metric_based_rules_${num}
    ${metric_based_rule}   Set Variable      {"delivery_groups":${delivery_groups},"name":"${rule_name}","condition":${conditions},"at_least":${at_least}}
    [Return]  ${metric_based_rule}

Json for complex log-based rule for callback
    [Arguments]   ${type}  ${not1}  ${field1}  ${action1}  ${value1}  ${not2}  ${field2}  ${action2}  ${value2}  ${num} 
    ${template}   Generate Random String   17   [LETTERS] 
    Set Global Variable    ${template}    ${template}
    Set Global Variable    ${clbk_message}    ${template} log-based alert #${num}
    Set Global Variable    ${templ}    {\\"callback\\":\\"${clbk_message}\\"}
    ${conditions}   Set Variable    {"operation":"AND","conditions":[{"not":${not1},"field":"${field1}","action":"${action1}","value":${value1}},{"not":${not2},"field":"${field2}","action":"${action2}","value":${value2}}]}
    ${delivery_groups}  Set Variable    [{"use_default_delivery":true,"type":"${type}","name":"Delivery_groups_simple_${num}","template":"${templ}","recipients":[]}] 
    ${log_based_rule}   Set Variable      {"delivery_groups":${delivery_groups},"name":"alert_log_based_rules_${num}","condition":${conditions}}
    [Return]  ${log_based_rule}

Json for complex metric-based rule for callback
    [Arguments]   ${type}  ${metric_name}  ${not1}  ${field1}  ${action1}  ${value1}  ${not2}  ${field2}  ${action2}  ${value2}  ${num} 
    ${template}   Generate Random String   17   [LETTERS] 
    Set Global Variable    ${template}    ${template}
    Set Global Variable    ${clbk_message}    ${template} metric-based alert #${num}
    Set Global Variable    ${templ}    {\\"callback\\":\\"${clbk_message}\\"}
    Set Global Variable    ${rule_name}    alert_metric_based_rules_${num}_${template}
    ${conditions}   Set Variable    {"operation":"AND","conditions":[{"not":false,"field":"name","action":"match","value":"${metric_name}"},{"not":${not1},"field":"${field1}","action":"${action1}","value":${value1}},{"not":${not2},"field":"${field2}","action":"${action2}","value":${value2}}]}
    ${delivery_groups}  Set Variable    [{"use_default_delivery":true,"type":"${type}","name":"Delivery_groups_simple_${num}","template":"${templ}","recipients":[]}] 
    ${metric_based_rule}   Set Variable      {"delivery_groups":${delivery_groups},"name":"${rule_name}","condition":${conditions}}
    [Return]  ${metric_based_rule}

Json for complex metric-based rule for callback with time period
    [Arguments]   ${type}  ${time_interval}  ${time_value}  ${metric_name}  ${not1}  ${field1}  ${action1}  ${value1}  ${not2}  ${field2}  ${action2}  ${value2}  ${num} 
    ${template}   Generate Random String   17   [LETTERS] 
    Set Global Variable    ${template}    ${template}
    Set Global Variable    ${clbk_message}    ${template} metric-based alert #${num}
    Set Global Variable    ${templ}    {\\"callback\\":\\"${clbk_message}\\"}
    ${conditions}   Set Variable    {"operation":"AND","conditions":[{"not":false,"field":"name","action":"match","value":"${metric_name}"},{"not":${not1},"field":"${field1}","action":"${action1}","value":"${value1}"},{"not":${not2},"field":"${field2}","action":"${action2}","value":"${value2}"}]}
    ${delivery_groups}  Set Variable    [{"use_default_delivery":true,"type":"${type}","name":"Delivery_groups_simple_${num}","template":"${templ}","recipients":[]}] 
    ${at_least}   Set Variable   {"duration":"${time_interval}","value":${time_value}}
    ${metric_based_rule}   Set Variable      {"delivery_groups":${delivery_groups},"name":"alert_metric_based_rules_${num}","condition":${conditions},"at_least":${at_least}}
    [Return]  ${metric_based_rule}

Delete alerting delivery rules with keystone credentials
    User sends Delete request for alerting delivery rules for the "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}"

Delete alerting log delivery configuration with keystone credentials
    User sends Delete request for alerting configuration rules for the "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}"

Create delivery list (file ${email_recipients}) with "${Tenant}"/"${tenant_id}" and "${PKI_TOKEN}"
    User send a PUT request to create alerting delivery rules (file ${email_recipients}) with "${Tenant}"/"${tenant_id}" and "${PKI_TOKEN}"
    The response code should be 200
    The response body should contain boolean "True" with "success"

Put request to create alerting log delivery configuration rules for a tenant_id with ${rule}
    User create/update alerting delivery rules for a "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}" (with ${rule})
    The response code should be 200
    The response body should contain boolean "True" with "success"

User send a PUT request to create alerting delivery rules (file ${data}) with "${TenantName}"/"${tenant_id}" and "${PKI_TOKEN}"
    Set Headers    {"X-Tenant": "${TenantName}","X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    Set Global Variable    ${method}    PUT
    Set Global Variable    ${url}    ${IP_web}/${api_version}/alert_delivery_conf?tenant_id=${tenant_id}
    Log    "Put request on link ${url} with file ${data}"
    Set Body    ${data}
    Put request    ${url}

User sends GET request to get alerting delivery rules conf for the ${Tenant}/"${tenant_id}" and "${pkitoken}"
    Set Headers    {"X-Tenant": "${Tenant}","X-Auth-token": "${pkitoken}"}
    Log   ${pkitoken}
    Set Global Variable    ${url}    ${IP_web}/${api_version}/alert_delivery_conf?tenant_id=${tenant_id}
    Set Global Variable    ${method}    GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

The response body for alerting delivery rules should be key ${key} with ${value}
    ${body}    Get Response Body
    Log    "Expect ${key} == ${value} in body ${body}"
    Should Be Equal    ${body[0]['${key}'][0]}    ${value}

The response body for alerting generation rules should be key ${key} with ${value}
    ${body}    Get Response Body
    Log    "Expect ${key} == ${value} in body ${body}"
    Should Be Equal    ${body[0]['delivery_groups'][0]['${key}']}    ${value}

The response body for PUT request should be "${value}" with key "${key}"
    ${body}    Get Response Body
    Log    "Expect ${key} == ${value} in body ${body}"
    Should Be Equal    ${body['${key}'][0]}    ${value}

The response body should contain boolean "${value}" with "${key}"
    ${body}    Get Response Body
    ${body_value}    Convert To String    ${body['${key}']}
    Should Be Equal    ${body_value}    ${value}

User create/update alerting delivery rules for a "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}" (with ${data})
    Set Headers    {"X-Tenant": "${Tenant}","X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    Set Global Variable    ${url}   ${IP_web}/${api_version}/log_based_alert_rules_conf?tenant_id=${tenant_id}
    Log    "Put request on link ${url} with file ${data}"
    Set Global Variable    ${method}    PUT
    Set Body    ${data}
    Put request    ${url}

User sends GET request to get rules conf for the "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}"
    Set Headers    {"X-Tenant": "${Tenant}","X-Auth-token": "${PKI_TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/${api_version}/log_based_alert_rules_conf?tenant_id=${tenant_id}
    Set Global Variable    ${method}    GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

User sends Delete request for alerting delivery rules for the "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}"
    Set Headers    {"X-Tenant": "${Tenant}","X-Auth-token": "${PKI_TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/${api_version}/alert_delivery_conf?tenant_id=${tenant_id}
    Set Global Variable    ${method}    DELETE
    Log    "DELETE request on link ${url}"
    DELETE Request    ${url}

User sends Delete request for alerting configuration rules for the "${Tenant}"/"${tenant_id}", "${PKI_TOKEN}"
    Set Headers    {"X-Tenant": "${Tenant}","X-Auth-token": "${PKI_TOKEN}"}
    Set Global Variable    ${url}    ${IP_web}/${api_version}/log_based_alert_rules_conf?tenant_id=${tenant_id}
    Set Global Variable    ${method}    DELETE
    Log    "DELETE request on link ${url}"
    DELETE Request    ${url}

