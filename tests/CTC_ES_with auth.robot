*** Settings ***
Documentation     Set of tests is used for component testing of Elasticsearch.
...               Here we check that ES is available for operations of POST, GET, DELETE.

Resource          ../keywords/searchguard_settings.robot

Suite Setup  Run Keywords   Get datetime   Getting the time in milliseconds
Suite Setup  Run Keywords   Send one message to ES

*** Test Cases ***
Elasticsearch version number is correct
    [Tags]    CTC-ES-sg-1  ctc_smoke  positive
    Execute GET request to '${es_url}' with credentials user='${sudo_user}' pass='${sudo_pass}'
    The response code should be 200
    ${response_body}    Get Response Body
    Log To Console   ${response_body}
    Log To Console   Elasticsearch version number
    Log To Console   ${response_body['version']['number']}
    Should Be Equal   ${response_body['version']['number']}   ${ES_version}

Elasticsearch cluster name and node names are correct
    [Tags]    CTC-ES-sg-2  positive
    ${es_cluster}   Create List  @{es_cluster}
    ${count}  Get Length  ${es_cluster}
    Log To Console   Elasticsearch nodes:
    : FOR   ${i}   IN RANGE   ${count}
    \    Execute GET request to 'http://${es_cluster[${i}]}:9200' with credentials user='${sudo_user}' pass='${sudo_pass}'
    \    The response code should be 200
    \    ${response_body}    Get Response Body
    \    Should Be Equal As Strings   ${response_body["status"]}   200
    \    Log To Console   ${response_body["name"]}
    \    Should Be Equal   ${response_body["cluster_name"]}   ${es_cluster_name}

Post message to ES with empty host field with no exception
    [Tags]    CTC-ES-sg-3   positive
    ${es_json}  Set Variable  {"some_int":34,"user":"testuser","host":"","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","pid":"60385","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 201
    ${response_body}    Get Response Body
    #---find id of the message----
    ${message_id}  Set Variable  ${response_body['_id']}
    #--search by message id-------
    ${es_json}  Set Variable  {"query":{"term":{"_id":"${message_id}"}}}
    Execute POST request to '${path}/_search' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 200
    ${response_body}    Get Response Body

Post message to ES with empty message field with no exception
    [Tags]    CTC-ES-sg-4   positive
    ${es_json}  Set Variable  {"some_int":34,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"","pid":"60385","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 201
    ${response_body}    Get Response Body
    #---find id of the message----
    ${message_id}  Set Variable  ${response_body['_id']}
    #--search by message id-------
    ${es_json}  Set Variable  {"query":{"term":{"_id":"${message_id}"}}}
    Execute POST request to '${path}/_search' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 200
    ${response_body}    Get Response Body

Post message to ES with double value in *_int and get exception
    [Tags]    CTC-ES-sg-5   negative
    ${es_json}  Set Variable  {"some_int":3.4,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","pid":"60385","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 400
    ${response_body}    Get Response Body

Post message to ES with string value in *_double and get exception
    [Tags]    CTC-ES-sg-6   negative
    ${es_json}  Set Variable  {"some_int":3.4,"some_double":"9.111","user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","pid":"60385","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 400
    ${response_body}    Get Response Body

Post message to ES with empty pid field with no exception
    [Tags]    CTC-ES-sg-8  ctc_smoke  es_migration_TC  positive
    ${es_json}  Set Variable  {"some_int":34,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","pid":"","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 201
    ${response_body}    Get Response Body
    #---find id of the message----
    ${message_id}  Set Variable  ${response_body['_id']}
    #--search by message id-------
    ${es_json}  Set Variable  {"query":{"term":{"_id":"${message_id}"}}}
    Execute POST request to '${path}/_search' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 200
    ${response_body}    Get Response Body

Post message to ES with wrong format for post_date field and get exception
    [Tags]    CTC-ES-sg-9  ctc_smoke  es_migration_TC  negative
    ${es_json}  Set Variable  {"some_int":34,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"20140617T191212","message":"directly to ES at ${time_ms}","pid":"60385","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 400
    ${response_body}    Get Response Body

Post message to ES with wrong format for pid field and get exception
    [Tags]    CTC-ES-sg-10  ctc_smoke  es_migration_TC  negative
    ${es_json}  Set Variable  {"some_int":34,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","pid":"1q2w3e4r","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 400
    ${response_body}    Get Response Body

Post message to ES with wrong format for pid field and get exception2
    [Tags]    CTC-ES-sg-11  ctc_smoke  es_migration_TC  negative
    ${es_json}  Set Variable  {"some_int":34,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","pid":1234,"data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 400
    ${response_body}    Get Response Body

Post message to ES with wrong format for pid field and get exception3
    [Tags]    CTC-ES-sg-12  ctc_smoke  es_migration_TC  negative
    ${es_json}  Set Variable  {"some_int":34,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","pid":"123.123","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 400
    ${response_body}    Get Response Body

Post message to ES with no pid field and get exception
    [Tags]    CTC-ES-sg-13  ctc_smoke  es_migration_TC  negative
    ${es_json}  Set Variable  {"some_int":34,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 400
    ${response_body}    Get Response Body

Post message to ES without user field
    [Tags]    CTC-ES-sg-14  ctc_smoke  es_migration_TC  positive
    ${es_json}  Set Variable  {"some_int":34,"host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","pid":"123","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 201
    ${response_body}    Get Response Body
    #---find id of the message----
    ${message_id}  Set Variable  ${response_body['_id']}
    #--search by message id-------
    ${es_json}  Set Variable  {"query":{"term":{"_id":"${message_id}"}}}
    Execute POST request to '${path}/_search' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 200
    ${response_body}    Get Response Body

Post message to ES without post_date field
    [Tags]    CTC-ES-sg-15  ctc_smoke  es_migration_TC  positive
    ${es_json}  Set Variable  {"some_int":34,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","message":"directly to ES at ${time_ms}","pid":"12367","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 201
    ${response_body}    Get Response Body
    #---find id of the message----
    ${message_id}  Set Variable  ${response_body['_id']}
    #--search by message id-------
    ${es_json}  Set Variable  {"query":{"term":{"_id":"${message_id}"}}}
    Execute POST request to '${path}/_search' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 200
    ${response_body}    Get Response Body

Post message to ES without message field
    [Tags]    CTC-ES-sg-16   positive
    ${es_json}  Set Variable  {"some_int":34,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","pid":"123","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 201
    ${response_body}    Get Response Body
    #---find id of the message----
    ${message_id}  Set Variable  ${response_body['_id']}
    #--search by message id-------
    ${es_json}  Set Variable  {"query":{"term":{"_id":"${message_id}"}}}
    Execute POST request to '${path}/_search' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 200
    ${response_body}    Get Response Body

Post message to ES with field _index
    [Tags]    CTC-ES-sg-17   negative
    ${es_json}  Set Variable  {"_index":"tkorchak_test","some_int":34,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","pid":"123","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 201
    ${response_body}    Get Response Body
    #---find id of the message----
    ${message_id}  Set Variable  ${response_body['_id']}
    #--search by message id-------
    ${es_json}  Set Variable  {"query":{"term":{"_id":"${message_id}"}}}
    Execute POST request to '${path}/_search' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 200
    ${response_body}    Get Response Body

*** Keywords ***
Send one message to ES
    ${tmp_test}   Set Variable  logs-d9840542280941c2b20a2b71d8f47c49-${Y.M.D}
    Set Global Variable  ${path}       ${es_url}/${tmp_test}/logs
    ${es_json}  Set Variable  {"some_int":34,"some_double":0.01,"user":"testuser","host":"epmp-px2-lmm-sys-srv-p23","post_date":"${@timestamp}","message":"directly to ES at ${time_ms}","pid":"60385","data_boolean":true}
    #---send message to ES----
    Execute POST request to '${path}' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${es_json}'
    The response code should be 201
    ${response_body}    Get Response Body