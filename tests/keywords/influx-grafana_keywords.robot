*** Settings ***
Library           ../libs/simple_REST.py
Resource          keywords.robot
Resource          log-based_keywords.robot
Resource          variables_keywords.robot    # https://github.com/influxdb/influxdb-python/blob/master/influxdb/client.py

*** Keywords ***
Getting the time in milliseconds
    ${ms}=    Evaluate    int(round(time.time() * 1000))    time
    log    time in ms: ${ms}
    Set Global Variable    ${time_ms}    ${ms}

User send ${number} POST request to influxDB '${db_name}' with body '${body}'
    : FOR    ${index}    IN RANGE    ${number}
    \    Log    ${index}
    \    Set Headers    {"Content-Type": "application/json"}
    \    ${request_body}    Set Variable    ${body}
    \    Set Global Variable    ${url}    http://${db_host}:8086/db/${db_name}/series?u=root&p=root&${body}
    \    Set Global Variable    ${method}    POST
    \    Log    "POST request on link ${url} with body ${request_body}"
    \    Set Body    ${request_body}
    \    POST Request    ${url}

User creates DB "${body}" in influxDB
    #curl -X POST 'http://localhost:8086/db?u=root&p=root' -d '{"name": "qwerty"}'
    ${request_body}    Set Variable    ${body}
    Set Global Variable    ${url}    http://${db_host}:8086/db?u=root&p=root
    Set Global Variable    ${method}    POST
    Log    "POST request on link ${url} with body ${request_body}"
    Set Body    ${request_body}
    POST Request    ${url}

User send GET request to influxDB '${db_name}' with body '${body}'
    #curl -G 'http://localhost:8086/db/lmm/series?u=root&p=root' --data-urlencode
    #"q=SELECT COUNT(message) FROM unknown_notifications where message='NOT_VALID_JSON_OBJECT'"
    Set Global Variable    ${url}    http://${db_host}:8086/db/${db_name}/series?u=root&p=root&${body}
    Log    "GET request on link ${url} with body ${body}"
    Set Global Variable    ${method}    GET
    GET Request    ${url}

User send GET request to Graphana with body '${body}', ${PKI_TOKEN} for '${Tenant}'
    #curl -v -GET 'http://10.119.207.242/grafana/dashboard/series?u=root&p=root' --data-urlencode
    #"q=SELECT * from 41ae9ac9fb514915ad82fa6939f9c967_cpu_idle" -H "X-Auth-token:$PKI_TOKEN"
    Set Headers    {"X-Auth-token": "${PKI_TOKEN}", "X-Tenant": "${Tenant}"}
    Set Global Variable    ${url}    ${IP_web}/influxdb/series?${body}
    Log    "GET request on link ${url}"
    Set Global Variable    ${method}    GET
    GET Request    ${url}

#User send POST request to influxDB '${db_name}' with body '${body}'
#    Set Headers    {"Content-Type": "application/json"}
#    ${request_body}    Set Variable    ${body}
#    Set Global Variable    ${url}    http://${db_host}:8086/db/${db_name}/series?u=root&p=root&${body}
#    Set Global Variable    ${method}    POST
#    Log    "POST request on link ${url} with body ${request_body}"
#    Set Body    ${request_body}
#    POST Request    ${url}

#User send DELETE request to influxDB for '${db_name}'
#    #curl -X DELETE 'http://localhost:8086/db/no_nulls/series/CPU?u=root&p=root'
#    Set Global Variable    ${url}    http://${db_host}:8086/db/${db_name}?u=root&p=root
#    Set Global Variable    ${method}    DELETE
#    Log    "DELETE request on link ${url}"
#    DELETE Request    ${url}

#User send DELETE request to influxDB '${db_name}' for series '${series}'
#    #curl -XDELETE 'http://localhost:8086/db/lmm/series/cpu_idle?u=root&p=root'
#    Set Global Variable    ${url}    http://${db_host}:8086/db/${db_name}/series/${series}?u=root&p=root
#    Set Global Variable    ${method}    DELETE
#    Log    "DELETE request on link ${url}"
#    DELETE Request    ${url}

The response body of GET all data from DB has '${key}' with value "${value}"
    ${body}    Get Response Body
    Log    ${body}
    Log    ${body[0]['${key}']}
    Should Be Equal    ${body[0]['${key}']}    ${value}

The response body of GET '${data}' from InfluxDB has '${key}' with value "${value}"
    ${body}    Get Response Body
    Log    ${body}
    Log    ${body[0]['${key}']}
    Should Be Equal    ${body[0]['${key}'][0][3]}    ${value}

The response body of GET '${data}' from Grafaha has '${key}' with value "${value}"
    ${body}    Get Response Body
    Log    ${body}
    Log    ${body[0]['${key}']}
    Should Be Equal    ${body[0]['${key}'][-1]}    ${value}
