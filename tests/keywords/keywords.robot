*** Settings ***
Library           ../libs/simple_REST.py
Library           ../libs/ImapLibrary.py
Library           Collections
Library           String
Resource          variables_keywords.robot
Library           ../libs/ElasticSearchClient.py
Library           ../libs/ExtendDictionary.py
Library           ../libs/InfluxClient.py

*** Keywords ***
Drop created tables for metric "${metricName}" with "${tenant_id}"
    ${list}  Create List  ${metricName}_
    ${count}  Get Length  ${affix}
    :FOR    ${i}    IN RANGE  ${count}
    \   Append To List  ${list}      ${metricName}__${affix[${i}]}
    Log  metrics list = ${list}
    ${count}  Get Length  ${list}
    :FOR    ${i}    IN RANGE  ${count}
    \    Delete Influx Series  tenant_${tenant_id}   ${list[${i}]}
    \    Log    Deleted ${tenant_id}_${list[${i}]}

Check email arrival for ${email} with ${password} from ${fromEmail} and '${text}'
    Open mailbox    server=imap.googlemail.com    user=${email}    password=${password}
    ${LATEST}=    Wait for Mail    fromEmail=${fromEmail}    toEmail=${email}    status=UNSEEN    timeout=30
    Log    ${LATEST}
    ${HTML}=    Get email body    ${LATEST}
    Log    ${HTML}
    Get matches from email    ${LATEST}    ${text}
    Close Mailbox

Check that email didn't arrive for ${email} with ${password} from ${fromEmail} and '${text}'
    Open mailbox    server=imap.googlemail.com    user=${email}    password=${password}
    ${LATEST}=    Wait for Mail    fromEmail=${fromEmail}    toEmail=${email}    status=UNSEEN    timeout=20
    Should be equal as strings   ${LATEST}   No mail received within time

Clear index in elasticsearch
    Get date and _index for Elasticsearch (Y.M.D)
    Delete Index From Es    ${ES_index}
#    The response code should be 200

Get datetime
    ${datetime}=    Get Time    now
    Set Global Variable    ${datetime}    ${datetime}
    ${year}    ${month}    ${day}=    Get Time    year,month,day
    ${hour}    ${min}    ${sec}=    Get Time    hour,min,sec
    ${str}   Generate Random String  3  [NUMBERS]
    ${int}  Convert To Integer  ${str}
    Set Global Variable    ${@timestamp}    ${year}-${month}-${day}T${hour}:${min}:${sec}.${int}Z
    ${ms}=    Evaluate    int(round(time.time() * 1000))    time
    log    time in ms: ${ms}
    Set Global Variable    ${time_ms}    ${ms}
    Set Global Variable   ${es_time}     ${year}${month}${day}T${hour}${min}${sec}.${int}Z
    Set Global Variable    ${Y.M.D}    ${year}.${month}.${day}
    Set Global Variable    ${Y-M-D}    ${year}-${month}-${day}
    Set Global Variable    ${M-D-Y}    ${month}-${day}-${year}

Get timestamp different format
    # future time
    ${year}    ${month}    ${day}=    Get Time    year,month,day
    ${hour}    ${min}    ${sec}=    Get Time    hour,min,sec
    ${year}    Set variable    ${year}+1
    Set Global Variable    ${future}    ${year}-${month}-${day}T${hour}:${min}:${sec}.000Z
    # yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'fffffffzz
    Set Global Variable    ${format1}    ${year}-${month}-${day}T${hour}:${min}:${sec}.0000000zz
    # ddd, dd MMM yyyy HH':'mm':'ss 'GMT'
    Set Global Variable    ${format2}    ${day} ${month} ${year} ${hour}:${min}:${sec} GMT
    # yyyy'-'MM'-'dd'T'HH':'mm':'ss
    Set Global Variable    ${format3}    ${year}-${month}-${day}T${hour}:${min}:${sec}
    # yyyy'-'MM'-'dd HH':'mm':'ss'Z'
    Set Global Variable    ${format4}    ${year}-${month}-${day} ${hour}:${min}:${sec}Z

Get date and _index for Elasticsearch (Y.M.D)
    ${year}=    Get Time    year
    ${month}=    Get Time    month
    ${day}=    Get Time    day
    Set Global Variable    ${Y.M.D}    ${year}.${month}.${day}
    Set Global Variable    ${ES_index}    logs-${tenant_id}-${Y.M.D}

Send ${number} log messages to Kafka to '${topic}' with body '${body}'
    : FOR    ${index}    IN RANGE    ${number}
    \    Log    ${index}
    \    Send Message To Kafka  ${topic}  ${body}

The response body of alert from email topic should have a key '${key}' in dict with value "${value}"
    ${body}    Get Response Body
    Log    "Expect ${key} == ${value} in body ${body}"
    Should Be Equal    ${body['${key}'][0]}    ${value}

The response body of auth error from ES should have a key '${key}' in dict with value "${value}"
    ${body}    Get Response Body
    Log    "Expect ${key} == ${value} in body ${body}"
    Should Be Equal    ${body['hits']['hits'][0]['_source']['${key}']}    ${value}

The response body for ES should not have a key '${key}' in dict with value "${value}"
    ${body}    Get Response Body
    Log    "Expect ${key} == ${value} in body ${body}"
    Should Not Be Equal    ${body['hits']['hits'][0]['_source']['${key}']}    ${value}

The response body for ES should have a key '${key}' in dict with value "${value}"
    ${body}    Get Response Body
    ${body['_source']}
    Log    "Expect ${key} == ${value} in body ${body['message']}"
    Should Be Equal    ${body['messages'][0]['key']}    ${value}

The response body should be ${body}
    ${response_body}    Get Response Body
    Log   ${response_body}
    Log    "Response body: ${response_body}. Expected body: ${body}"
    Should Be Equal    ${body}    ${response_body}

The response code should be ${status_code}
    ${response_body}    Get Response Body
    Log    ${response_body}
    ${response_code}    Get Response Code
    Run Keyword If    ${status_code} != ${response_code}    Fail    "User has sent ${method} request with url ${url}. Response code: ${response_code}. Response body: ${response_body}"

The response body should have keys
    [Arguments]    @{keys}
    ${body}    Get Response Body
    : FOR    ${key}    IN    @{keys}
    \    Log    "Expect ${key} in body ${body}"
    \    Log    ${body['${key}']}

The response body should have key '${key}' with list ${value}
    ${body}    Get Response Body
    ${array}    Convert To List    ${value}
    Log    "Expect ${key} == ${array} in body ${body}"
    Should Be Equal    ${body['${key}']}    ${array}

The response body should have key '${key}' with not empty list
    ${body}    Get Response Body
    Log    "Expect list ${key} in body ${body}"
    ${length}    Get Length    ${body['${key}']}
    Should Not Be Equal As Integers    ${length}    0

The response body should have key '${key}' with value "${value}"
    ${body}    Get Response Body
    Log    "Expect ${key} == ${value} in body ${body}"
    Should Be Equal    ${body['${key}']}    ${value}

The response body should have key '${key}' in dict with value "${value}"
    ${body}    Get Response Body
    Log    ${body}
    Log    ${body['${key}']}
    Log    "Expect ${key} == ${value} in body ${body['messages']}"
    Should Be Equal    ${body['messages']['${key}']}    ${value}

The response body not should have key '${key}' with value "${value}"
    ${body}    Get Response Body
    Log    "NoExpect ${key} == ${value} in body ${body}"
    Should Be Not Equal    ${body['${key}']}    ${value}
