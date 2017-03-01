*** Settings ***
Resource          keywords/keywords.robot
Resource          keywords/log-based_keywords.robot
Resource          keywords/metric-based_keywords.robot
Resource          keywords/retention-policies_keywords.robot
Library           libs/OperatingSystem.py
Library           Collections
Library           libs/ExtendDictionary.py
Library           libs/ElasticSearchClient.py
Library           libs/InfluxClient.py
Library           libs/KafkaClient.py
Resource          keywords/prepopulate_data.robot

Suite Setup  Run Keywords   User send POST request to keystone for demo user   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords   Get date and _index for Elasticsearch (Y.M.D)   Define variables
Suite Setup  Run Keywords   Create ES body
Test Setup  Run Keywords    Get datetime

*** Variables ***
${delay}     60

*** Test Cases ***
Get API for /api_versions
    [Tags]    ITC-Query-1.0  smoke  ui_migration_TC  ks_migration_TC  positive
    Set Headers    {"X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    ${url}    Set Variable     ${IP_web}/api_versions
    ${method}    Set Variable   GET
    Log    "GET request on link ${url}"
    GET Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Log To Console   ${response_body}

Get API for /_settings
    [Tags]    ITC-Query-1.0a  smoke  ui_migration_TC  ks_migration_TC  positive  LMM-2187
    Set Headers    {"X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    ${url}    Set Variable     ${IP_web}/_settings
    ${method}    Set Variable   GET
    Log    "GET request on link ${url}"
    GET Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Log To Console   ${response_body}

Get API for /health
    [Tags]    ITC-Query-1.0b  smoke  ui_migration_TC  ks_migration_TC  positive
    Set Headers    {"X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    ${url}    Set Variable     ${IP_web}/health
    ${method}    Set Variable   GET
    Log    "GET request on link ${url}"
    GET Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Log To Console   ${response_body}

#API exposed to User to query log events
Using PKI_TOKEN user can query all available log events with simple _search command
    [Tags]    ITC-Query-1.1  smoke  ui_migration_TC  positive  redis_migration_TC
    Query elasticsearch data with 'log/_search' (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    #make check

Using APIKEY user can query all available log events with simple _search command
    [Tags]    ITC-Query-1.1a  smoke  ui_migration_TC  positive  redis_migration_TC
    ${query_api_version}   Set Variable  ${api_version_v2}
    Query elasticsearch data with 'log/_search' (${Tenant}, ${apikey})
    The response code should be 200

Using PKI_TOKEN user can query log events from specific index available for him
    [Tags]    ITC-Query-1.2  smoke  ui_migration_TC  positive  redis_migration_TC
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep  ${delay}
    Query elasticsearch data with 'log/${ES_index}/_search' (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using APIKEY user can query log events from specific index available for him
    [Tags]    ITC-Query-1.2a  ui_migration_TC  positive  redis_migration_TC
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Log  ${es_dict_main}
    Sleep  ${delay}
    ${query_api_version}   Set Variable  ${api_version_v2}
    Query elasticsearch data with 'log/${ES_index}/_search' (${Tenant}, ${apikey})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using PKI_TOKEN user can query one specific log event from specific tenant
    [Tags]    ITC-Query-1.3  ui_migration_TC  positive  redis_migration_TC
    ${ids}  Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Log  ${es_dict_main}
    Sleep   ${delay}
    Sleep  ${delay}
    Sleep  ${delay}
    Query elasticsearch data with 'log/${ES_index}/_search?q=_id:${ids[0]}' (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Be Equal  '${response_body['hits']['total']}'   '0'

Using APIKEY user can query one specific log event from specific tenant
    [Tags]    ITC-Query-1.3a  ui_migration_TC  positive  redis_migration_TC
    ${ids}  Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Log  ${es_dict_main}
    Sleep   ${delay}
    Sleep  ${delay}
    Sleep  ${delay}
    ${query_api_version}   Set Variable  ${api_version_v2}
    Query elasticsearch data with 'log/${ES_index}/_search?q=_id:${ids[0]}' (${Tenant}, ${apikey})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Be Equal  '${response_body['hits']['total']}'   '0'

User gets 401 by querying log events with wrong PKI_TOKEN
    [Tags]    ITC-Query-1.4  multitenancy  ui_migration_TC  positive  redis_migration_TC
    ${ES_index_demo}   Set Variable   openstack-${tenant_id_demo}-${Y.M.D}
    Send Bunch Of Messages  /${ES_index_demo}/logs/  count=${2}  size=1  body=${es_dict_demo}
    Sleep   ${delay}
    Query elasticsearch data with 'log/${ES_index_demo}/_search' (qwerty, qwewrvd-dfgfhbf453ebjwer3-erfldgn)
    The response code should be 401

User gets 401 by querying log events with wrong APIKEY
    [Tags]    ITC-Query-1.4a  multitenancy  ui_migration_TC  positive  redis_migration_TC
    ${ES_index_demo}   Set Variable   openstack-${tenant_id_demo}-${Y.M.D}
    Send Bunch Of Messages  /${ES_index_demo}/logs/  count=${2}  size=1  body=${es_dict_demo}
    Sleep   ${delay}
    ${query_api_version}   Set Variable  ${api_version_v2}
    Query elasticsearch data with 'log/${ES_index_demo}/_search' (qwerty, ------)
    The response code should be 401

Using PKI_TOKEN user gets empty list trying to query log events from tenant not available for user
    [Tags]    ITC-Query-1.5  multitenancy  ui_migration_TC  positive  redis_migration_TC
    ${ES_index_demo}   Set Variable   openstack-${tenant_id_demo}-${Y.M.D}
    Send Bunch Of Messages  /${ES_index_demo}/logs/  count=${2}  size=1  body=${es_dict_demo}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Log  ${es_dict_main}
    Sleep   ${delay}
    Query elasticsearch data with 'log/${ES_index_demo}/_search' (${Tenant}, ${PKI_TOKEN})
    ${response_body}    Get Response Body
    Should Be Equal  '${response_body['hits']['total']}'   '0'

Using APIKEY user gets empty list trying to query log events from tenant not available for user
    [Tags]    ITC-Query-1.5a  multitenancy  ui_migration_TC  positive  redis_migration_TC
    ${ES_index_demo}   Set Variable   openstack-${tenant_id_demo}-${Y.M.D}
    Send Bunch Of Messages  /${ES_index_demo}/logs/  count=${2}  size=1  body=${es_dict_demo}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    ${query_api_version}   Set Variable  ${api_version_v2}
    Query elasticsearch data with 'log/${ES_index_demo}/_search' (${Tenant}, ${apikey})
    ${response_body}    Get Response Body
    Should Be Equal  '${response_body['hits']['total']}'   '0'

#API exposed to User to query metric events
Using PKI_TOKEN user can query only metric events available for him
    [Tags]    ITC-Query-2.1  smoke  ui_migration_TC  positive  redis_migration_TC  influx_migration_TC
    ${json_main}    Create Dictionary  host=qa-query-api-main  @version=1  name=${metric}  value=3333.3333  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json_main}
    ${json_demo}    Create Dictionary  host=qa-query-api-demo  @version=1  name=${metric}  value=4444.4444  apikey=${apikey_demo}  tenant_id=${tenant_id_demo}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json_demo}
    Sleep  ${delay}
    Query metric events with command 'list series' (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    ${apikey_demo}
    Get list of metrics (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    ${apikey_demo}
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using APIKEY user can query only metric events available for him
    [Tags]    ITC-Query-2.1a  smoke  ui_migration_TC  positive  redis_migration_TC  LMM-2040  influx_migration_TC
    ${json_main}    Create Dictionary  host=qa-query-api-main  @version=1  name=${metric}  value=3333.3333  apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json_main}
    ${json_demo}    Create Dictionary  host=qa-query-api-demo  @version=1  name=${metric}  value=4444.4444  apikey=${apikey_demo}  tenant_id=${tenant_id_demo}  @timestamp=${@timestamp}
    Send Message To Kafka    metricTopic  ${json_demo}
    ${query_api_version}   Set Variable  ${api_version_v2}
    sleep  ${delay}
    Query metric events with command 'list series' (${Tenant}, ${apikey})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    ${apikey_demo}
    Get list of metrics (${Tenant}, ${apikey})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    ${apikey_demo}
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using PKI_TOKEN user can query specific table with metric events available for him
    [Tags]    ITC-Query-2.2  ui_migration_TC  positive  redis_migration_TC  influx_migration_TC
    ${body}   Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"qa_test_query","name":"${metric}","value":1.3,"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${body}
    Sleep   ${delay}
    Sleep  ${delay}
    Query metric events with command 'select%20*%20from%20${metric}_%20%28${Tenant}%29' (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal  '${response_body[0]['name']}'   '${metric}_ (${Tenant})'

Using APIKEY user can query specific table with metric events available for him
    [Tags]    ITC-Query-2.2a  ui_migration_TC  positive  redis_migration_TC  influx_migration_TC
    ${body}   Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"qa_test_query","name":"${metric}","value":1.3,"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${body}
    Sleep   ${delay}
    ${query_api_version}   Set Variable  ${api_version_v2}
    Query metric events with command 'select%20*%20from%20${metric}_%20' (${Tenant}, ${apikey})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal  '${response_body[0]['name']}'   '${tenant_id}_${metric}_'

Using PKI_TOKEN user cannot query specific metric events not available for him
    [Tags]    ITC-Query-2.3  multitenancy  ui_migration_TC  positive  redis_migration_TC  influx_migration_TC
    ${body}   Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"qa_test_query","name":"${metric_2}","value":1.2,"tenant_id":"${tenant_id_demo}","apikey":"${apikey_demo}"}
    Send Message To Kafka    metricTopic  ${body}
    Sleep   ${delay}
    Query metric events with command 'select%20*%20from%20${metric_2}_%20%28${Tenant_demo}%29' (${Tenant_demo}, ${PKI_TOKEN_demo})
    The response code should be 200
    Query metric events with command 'select%20*%20from%20${metric_2}_%20%28${Tenant_demo}%29' (${Tenant}, ${PKI_TOKEN})
    The response code should be 400
    ${response_body}    Get Response Body
    Should Be Equal   ${response_body}    Couldn't find series: _${metric_2}_

Using APIKEY user cannot query specific metric events not available for him
    [Tags]    ITC-Query-2.3a  multitenancy  ui_migration_TC  negative  redis_migration_TC  influx_migration_TC
    ${body}   Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"qa_test_query","name":"${metric_2}","value":1.2,"tenant_id":"${tenant_id_demo}","apikey":"${apikey_demo}"}
    Send Message To Kafka    metricTopic  ${body}
    Sleep   ${delay}
    ${query_api_version}   Set Variable  ${api_version_v2}
    Query metric events with command 'select%20*%20from%20${metric_2}_%20' (${Tenant_demo}, ${apikey_demo})
    The response code should be 200
    Query metric events with command 'select%20*%20from%20${metric_2}_%20' (${Tenant_demo}, ${apikey})
    The response code should be 400
    ${response_body}    Get Response Body
    Should Be Equal   ${response_body}    Couldn't find series: ${tenant_id}_${metric_2}_

#Internal API. Kibana internal ElasticSearch API
Using PKI_TOKEN user can get the mapping for <index>
    [Tags]    ITC-Query-3.1  smoke  ui_migration_TC  positive  redis_migration_TC
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    Use internal query '${ES_index}/_mapping' for elasticsearch data (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using APIKEY user can get the mapping for <index>
    [Tags]    ITC-Query-3.1a  smoke  ui_migration_TC  positive  redis_migration_TC
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    Use internal query '${ES_index}/_mapping' for elasticsearch data (${Tenant}, ${apikey})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using PKI_TOKEN user cannot get the mapping for <index> using wrong credentials
    [Tags]    ITC-Query-3.2  ui_migration_TC  positive  redis_migration_TC
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    Use internal query '${ES_index}/_mapping' for elasticsearch data (qwewefv, laskfd0djfoe-oeirfh)
    The response code should be 200
    ${response_body}    Get Response Body
    Should Contain   ${response_body}    Enter Your Keystone Credentials

Using APIKEY user cannot get the mapping for <index> using wrong credentials
    [Tags]    ITC-Query-3.2a  ui_migration_TC  negative  redis_migration_TC
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    Use internal query '${ES_index}/_mapping' for elasticsearch data (qwewefv, ///)
    The response code should be 200
    ${response_body}    Get Response Body
    Should Contain   ${response_body}    Enter Your Keystone Credentials

Using PKI_TOKEN user can get ES index aliases for <index>
    [Tags]    ITC-Query-3.3  ui_migration_TC  positive  redis_migration_TC
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    Use internal query '${ES_index}/_aliases' for elasticsearch data (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using APIKEY user can get ES index aliases for <index>
    [Tags]    ITC-Query-3.3a  ui_migration_TC  positive  redis_migration_TC
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    Use internal query '${ES_index}/_aliases' for elasticsearch data (${Tenant}, ${apikey})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using PKI_TOKEN user can get ES index aliases
    [Tags]    ITC-Query-3.4  ui_migration_TC  positive  redis_migration_TC
    Use internal query '_aliases' for elasticsearch data (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using APIKEY user can get ES index aliases
    [Tags]    ITC-Query-3.4a  ui_migration_TC  positive  redis_migration_TC
    Use internal query '_aliases' for elasticsearch data (${Tenant}, ${apikey})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using PKI_TOKEN user can get ES cluster nodes
    [Tags]    ITC-Query-3.5  ui_migration_TC  positive  redis_migration_TC
    Use internal query '_nodes' for elasticsearch data (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using APIKEY user cannot get ES cluster nodes
    [Tags]    ITC-Query-3.5a  negative  ui_migration_TC  redis_migration_TC
    Use internal query '_nodes' for elasticsearch data (${Tenant}, ${apikey})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Contain   ${response_body}    Enter Your Keystone Credentials

Using PKI_TOKEN user can retrieve log messages
    [Tags]    ITC-Query-3.6  ui_migration_TC  positive  redis_migration_TC
    Use internal query '_search' for elasticsearch data (${Tenant}, ${PKI_TOKEN})
    The response code should be 200

Using APIKEY user cannot retrieve log messages
    [Tags]    ITC-Query-3.6a  ui_migration_TC  positive  redis_migration_TC
    Use internal query '_search' for elasticsearch data (${Tenant}, ${apikey})
    The response code should be 401

Using PKI_TOKEN user can retrieve log messages from <index>
    [Tags]    ITC-Query-3.7    ui_migration_TC  positive  redis_migration_TC
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    Use internal query '${ES_index}/_search' for elasticsearch data (${Tenant}, ${PKI_TOKEN})
    The response code should be 200
    ${response_body}    Get Response Body
    Should Not Contain   ${response_body}    Enter Your Keystone Credentials

Using APIKEY user cannot retrieve log messages from <index>
    [Tags]    ITC-Query-3.7a    ui_migration_TC  positive  redis_migration_TC
    Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    Use internal query '${ES_index}/_search' for elasticsearch data (${Tenant}, ${apikey})
    The response code should be 401

#Forbidden ES proxy API.
Using PKI_TOKEN user cannot create and delete any index in ES
    [Tags]    ITC-Query-4.1  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    ${id}    Generate Random String   10   [LETTERS]
    ${body}   Set Variable    {"user" : "QA_testing", "post_date" : "${@timestamp}", "message" : "${id}"}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${ES_index}/${id}
    Set Global Variable    ${method}    PUT
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 404
    ${index}  Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${ES_index}/${index[0]}
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}
    The response code should be 404

Using APIKEY user cannot create and delete any index in ES
    [Tags]    ITC-Query-4.1a  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${apikey}","Content-type":"application/json"}
    ${id}    Generate Random String   10   [LETTERS]
    ${body}   Set Variable    {"user" : "QA_testing", "post_date" : "${@timestamp}", "message" : "${id}"}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${ES_index}/${id}
    Set Global Variable    ${method}    PUT
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 404
    ${index}  Send Bunch Of Messages  /${ES_index}/logs/  count=${2}  size=1  body=${es_dict_main}
    Sleep   ${delay}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${ES_index}/${index[0]}
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}
    The response code should be 404

Using PKI_TOKEN user cannot update existing index in ES
#curl -XPOST "http://192.168.199.30:9200/<INDEX>/logs/<ID>/_update"
#-d '{"script" : "ctx._source.apikey=12345"}'
    [Tags]    ITC-Query-4.2  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    ${body}   Set Variable    {"script" : "ctx._source.apikey=12345"}
    ${index}  Send Bunch Of Messages  /${ES_index}/logs/  count=${1}  size=1  body=${es_dict_main}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${ES_index}/${index[0]}/_update
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 404

Using APIKEY user cannot update existing index in ES
#curl -XPOST "http://192.168.199.30:9200/<INDEX>/logs/<ID>/_update"
#-d '{"script" : "ctx._source.apikey=12345"}'
    [Tags]    ITC-Query-4.2a  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${apikey}","Content-type":"application/json"}
    ${body}   Set Variable    {"script" : "ctx._source.apikey=12345"}
    ${index}  Send Bunch Of Messages  /${ES_index}/logs/  count=${1}  size=1  body=${es_dict_main}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${ES_index}/${index[0]}/_update
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 404

Using PKI_TOKEN user is not allowed to create/update/delete index mappings
    [Tags]    ITC-Query-4.3  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    ${body}   Set Variable    {"script" : "ctx._source.apikey=12345"}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${1}  size=1  body=${es_dict_main}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${ES_index}/_mapping
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}
    The response code should be 405

Using APIKEY user is not allowed to create/update/delete index mappings
    [Tags]    ITC-Query-4.3a  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${apikey}","Content-type":"application/json"}
    ${body}   Set Variable    {"script" : "ctx._source.apikey=12345"}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${1}  size=1  body=${es_dict_main}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${ES_index}/_mapping
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Should Contain   ${response_body}    Enter Your Keystone Credentials
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Should Contain   ${response_body}    Enter Your Keystone Credentials
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Should Contain   ${response_body}    Enter Your Keystone Credentials

Using PKI_TOKEN user is not allowed to create/update/delete index aliases
    [Tags]    ITC-Query-4.4  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    ${body}   Set Variable    {"script" : "ctx._source.apikey=12345"}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${1}  size=1  body=${es_dict_main}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${ES_index}/_aliases
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}
    The response code should be 405

Using APIKEY user is not allowed to create/update/delete index aliases
    [Tags]    ITC-Query-4.4a  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${apikey}","Content-type":"application/json"}
    ${body}   Set Variable    {"script" : "ctx._source.apikey=12345"}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${1}  size=1  body=${es_dict_main}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${ES_index}/_aliases
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}
    The response code should be 405

Using PKI_TOKEN user is not allowed to create/update/delete ES aliases
    [Tags]    ITC-Query-4.5  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    ${body}   Set Variable    {"script" : "ctx._source.apikey=12345"}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${1}  size=1  body=${es_dict_main}
    ${url}    Set Variable     ${IP_web}/elasticsearch/_aliases
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}
    The response code should be 405

Using APIKEY user is not allowed to create/update/delete ES aliases
    [Tags]    ITC-Query-4.5a  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${apikey}","Content-type":"application/json"}
    ${body}   Set Variable    {"script" : "ctx._source.apikey=12345"}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${1}  size=1  body=${es_dict_main}
    ${url}    Set Variable     ${IP_web}/elasticsearch/_aliases
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}
    The response code should be 405

Using PKI_TOKEN user is not allowed to create/update/delete ES nodes
    [Tags]    ITC-Query-4.6  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${PKI_TOKEN}","Content-type":"application/json"}
    ${body}   Set Variable    {"script" : "ctx._source.apikey=12345"}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${1}  size=1  body=${es_dict_main}
    ${url}    Set Variable     ${IP_web}/elasticsearch/_nodes
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 405
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}
    The response code should be 405

Using APIKEY user is not allowed to create/update/delete ES nodes
    [Tags]    ITC-Query-4.6a  ui_migration_TC  positive  redis_migration_TC
    Set Headers    {"X-Auth-token": "${apikey}","Content-type":"application/json"}
    ${body}   Set Variable    {"script" : "ctx._source.apikey=12345"}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${1}  size=1  body=${es_dict_main}
    ${url}    Set Variable     ${IP_web}/elasticsearch/_nodes
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Should Contain   ${response_body}    Enter Your Keystone Credentials
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Should Contain   ${response_body}    Enter Your Keystone Credentials
    Set Global Variable    ${method}    DELETE
    DELETE Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Should Contain   ${response_body}    Enter Your Keystone Credentials

#Forbidden InfluxDB proxy API.
Using PKI_TOKEN user cannot delete metrics through InfluxDB proxy API
    [Tags]    ITC-Query-4.7  ui_migration_TC  positive  redis_migration_TC
    ${body}   Set Variable    [{"measurement": "${metric}","tags": {"host": "server_${metric}","region": "mtv"},"time": "${@timestamp}","fields": {"value": ${time_ms}}}]
    Write Data To Influx  tenant_${tenant_id}  ${body}
    Sleep  5
    ${cmd}   Set Variable    delete%20from%20${metric}_%20%28${Tenant}%29%20where%20value%20=%2055
    Use internal query '${cmd}' to delete metric events (${Tenant}, ${PKI_TOKEN})
    The response code should be 405

Using APIKEY user cannot delete metrics through InfluxDB proxy API
    [Tags]    ITC-Query-4.7a  ui_migration_TC  positive  redis_migration_TC
    ${body}   Set Variable    [{"measurement": "${metric}","tags": {"host": "server_${metric}","region": "mtv"},"time": "${@timestamp}","fields": {"value": ${time_ms}}}]
    Write Data To Influx  tenant_${tenant_id}  ${body}
    ${cmd}   Set Variable    delete%20from%20${metric}_%20%28${Tenant}%29%20where%20value%20=%2055
    Use internal query '${cmd}' to delete metric events (${Tenant}, ${apikey})
    The response code should be 405

Using PKI_TOKEN user cannot drop metrics through InfluxDB proxy API
    [Tags]    ITC-Query-4.8  ui_migration_TC  positive  redis_migration_TC
    ${body}   Set Variable    [{"measurement": "${metric}","tags": {"host": "server_${metric}","region": "mtv"},"time": "${@timestamp}","fields": {"value": ${time_ms}}}]
    Write Data To Influx  tenant_${tenant_id}  ${body}
    ${cmd}   Set Variable    drop%20series%20${metric}_%20%28${Tenant}%29
    Use internal query '${cmd}' to delete metric events (${Tenant}, ${PKI_TOKEN})
    The response code should be 405

Using APIKEY user cannot drop metrics through InfluxDB proxy API
    [Tags]    ITC-Query-4.8a  ui_migration_TC  positive  redis_migration_TC
    ${body}   Set Variable    [{"measurement": "${metric}","tags": {"host": "server_${metric}","region": "mtv"},"time": "${@timestamp}","fields": {"value": ${time_ms}}}]
    Write Data To Influx  tenant_${tenant_id}  ${body}
    ${cmd}   Set Variable    drop%20series%20${metric}_%20%28${Tenant}%29
    Use internal query '${cmd}' to delete metric events (${Tenant}, ${apikey})
    The response code should be 405

Using PKI_TOKEN user cannot write metrics through InfluxDB proxy API
    [Tags]    ITC-Query-4.9    ui_migration_TC  positive  redis_migration_TC  influx_migration_TC
    ${body}   Set Variable    [{"measurement": "${metric}","tags": {"host": "server_${metric}","region": "mtv"},"time": "${@timestamp}","fields": {"value": ${time_ms}}}]
    Write data to influxDB with body '${body}' (${Tenant}, ${PKI_TOKEN})
    The response code should be 405

Using APIKEY user cannot write metrics through InfluxDB proxy API
    [Tags]    ITC-Query-4.9a    ui_migration_TC  positive  redis_migration_TC  influx_migration_TC
    ${body}   Set Variable    [{"measurement": "${metric}","tags": {"host": "server_${metric}","region": "mtv"},"time": "${@timestamp}","fields": {"value": ${time_ms}}}]
    Write data to influxDB with body '${body}' (${Tenant}, ${apikey})
    The response code should be 405

*** Keywords ***
Put data to elasticsearch with '${body}' (${tenant_name}, ${pkitoken})
    Set Headers    {"X-Auth-token": "${pkitoken}","Content-type":"application/json"}
    Log  ${pkitoken}
    ${url}    Set Variable     ${IP_web}/${query_api_version}/${ES_index}/log/
    Set Global Variable    ${method}    PUT
    Set Body    ${body}
    POST Request    ${url}

Use internal query '${query}' for elasticsearch data (${tenant_name}, ${pkitoken})
    Set Headers    {"X-Auth-token": "${pkitoken}","Content-type":"application/json"}
    Log  ${pkitoken}
    ${url}    Set Variable     ${IP_web}/elasticsearch/${query}
    ${method}    Set Variable   GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

Query elasticsearch data with '${query}' (${tenant_name}, ${pkitoken})
    Set Headers    {"X-Auth-token": "${pkitoken}","Content-type":"application/json"}
    Log  ${pkitoken}
    ${url}    Set Variable     ${IP_web}/${query_api_version}/${query}
    ${method}    Set Variable   GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

Query metric events with command '${cmd}' (${tenant_name}, ${pkitoken})
    Set Headers    {"X-Auth-token": "${pkitoken}","Content-type":"application/json"}
    Log  ${pkitoken}
    ${url}    Set Variable     ${IP_web}/${query_api_version}/metric/series?q=${cmd}
    ${method}    Set Variable   GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

Use internal query '${query}' to delete metric events (${tenant_name}, ${pkitoken})
    Set Headers    {"X-Auth-token": "${pkitoken}","Content-type":"application/json"}
    Log  ${pkitoken}
    ${url}    Set Variable     ${IP_web}/influxdb/series?u=${influx_user}&p=${influx_pass}&q=${query}
    Set Global Variable    ${method}    POST
    Set Body    ${body}
    POST Request    ${url}

Get list of metrics (${tenant_name}, ${pkitoken})
    Set Headers    {"X-Auth-token": "${pkitoken}","Content-type":"application/json"}
    Log  ${pkitoken}
    ${url}    Set Variable     ${IP_web}/${query_api_version}/metric/list
    ${method}    Set Variable   GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

Write data to influxDB with body '${body}' (${tenant_name}, ${pkitoken})
#[{"name":"${tenant_id}_test.table_","columns":["time","sequence_number","host","name","value"],"points":[[1424982404000,1,"qa_test_node","test.table",1.2]]}]
    Set Headers    {"X-Tenant": "${tenant_name}","X-Auth-token": "${pkitoken}","Content-type":"application/json"}
    Log  ${pkitoken}
    ${request_body}    Set Variable    ${body}
    ${url}    Set Variable     ${IP_web}/influxdb/series?u=${influx_user}&p=${influx_pass}
    Set Global Variable    ${method}    POST
    Log    "POST request on link ${url} with body ${request_body}"
    Set Body    ${request_body}
    POST Request    ${url}

User send POST request to keystone for demo user
    User sends POST request to keystone with '${keystone_demo_v3}'
    The response code should be 201
    ${PKI_TOKEN_demo}    Save PKI_TOKEN from keystone
    Set Global Variable   ${PKI_TOKEN_demo}   ${PKI_TOKEN_demo}
    ${tenant_id_demo}    Save tenant_id
    Set Global Variable   ${tenant_id_demo}   ${tenant_id_demo}
    Get APIKEY for '${Tenant_demo}' with '${PKI_TOKEN_demo}'
    The response code should be 200
    ${apikey_demo}   Save APIKEY
    Set Global Variable   ${apikey_demo}     ${apikey_demo}

Save PKI_TOKEN from keystone
    ${response_headers}    Get Response Headers
    Log    ${response_headers}
    Log    ${response_headers['X-Subject-Token']}
    ${token}    Set Variable    ${response_headers['X-Subject-Token']}
    [Return]  ${token}

Save tenant_id
    ${response_body}    Get Response Body
    Log    ${response_body['token']['project']['id']}
    ${id}    Set Variable   ${response_body['token']['project']['id']}
    [Return]  ${id}

Save APIKEY
    ${response_body}    Get Response Body
    Log    ${response_body['apikey']}
    ${api_key}    Set Variable    ${response_body['apikey']}
    [Return]  ${api_key}

Create body for es_request ('${key}', '${id}')
    Get datetime
    ${es_dict}   Create Dictionary     apikey=${key}  tenant_id=${id}  @timestamp=${@timestamp}
    Set Global Variable  ${es_dict}  ${es_dict}
    [Return]  ${es_dict}

Create ES body
    ${es_dict}   Create body for es_request ('${apikey}', '${tenant_id}')
    Set Global Variable    ${es_dict_main}    ${es_dict}
    ${es_dict}   Create body for es_request ('${apikey_demo}', '${tenant_id_demo}')
    Set Global Variable    ${es_dict_demo}    ${es_dict}

Delete indexes
    ${ES_index_demo}   Set Variable   openstack-${tenant_id_demo}-${Y.M.D}
    Delete Index From Es   ${ES_index}
    Delete Index From Es   ${ES_index_demo}

Define variables
    Set Global Variable    ${metric}    test.influx.query
    Set Global Variable    ${metric_2}  test.influx.query_2