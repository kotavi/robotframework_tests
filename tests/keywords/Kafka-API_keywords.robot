*** Settings ***
Library           ../libs/simple_REST.py
Library           Collections
Resource          variables_keywords.robot

*** Keywords ***
User send a POST request to Kafka '${topic}' with body '${body}'
    Set Headers    {"Content-Type": "application/json"}
    ${request_body}    Set Variable    ${body}
    Set Global Variable    ${url}    http://${test_node}:${kafka_api_port}/${topic}
    Set Global Variable    ${method}    POST
    Log    "POST request on link ${url} with body ${request_body}"
    Set Body    ${request_body}
    POST Request    ${url}
