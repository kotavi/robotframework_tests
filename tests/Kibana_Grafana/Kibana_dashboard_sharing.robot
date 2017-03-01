*** Settings ***
Resource          settings.robot
Resource          ../keywords/dashboard_keywords.robot

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords  Clear index in ES for 'kibana' dashboards '${username}'   Clear index in ES for 'kibana' dashboards '${user_demo}'
Test Teardown  Run Keywords   Clear index in ES for 'kibana' dashboards '${username}'   Clear index in ES for 'kibana' dashboards '${user_demo}'

*** Variables ***
${num}   10

*** Test Cases ***
User can save displayed data as dashboard to his index in Kibana
    [Tags]   Dash-1.1   positive   smoke  es_migration_TC  ui_migration_TC
    Create Dasnboard with random name in Kibana for '${PKI_TOKEN}' and '${TENANT}'
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'kibana' with '${username}'
    Dictionaries Should Be Equal  ${response_body}  ${response}

User can save displayed data as dashboard to his index predefined number of times in Kibana
    [Tags]   Dash-1.2   positive  critical   es_migration_TC  ui_migration_TC
    : FOR    ${index}    IN RANGE    ${num}
    \   Create Dasnboard with random name in Kibana for '${PKI_TOKEN}' and '${TENANT}'
    \   ${response_body}    Get Response Body
    \   ${response}  Create Dictionary of Successfull Dashboard Creation in 'kibana' with '${username}'
    \   Dictionaries Should Be Equal  ${response_body}  ${response}
#    \   Dictionary Should Contain Item    ${response_body}   _version   ${index+1}

User can delete dashboard created by him in Kibana
    [Tags]   Dash-1.3   positive  critical  es_migration_TC  ui_migration_TC
    Create Dasnboard with random name in Kibana for '${PKI_TOKEN}' and '${TENANT}'
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'kibana' with '${username}'
    Dictionaries Should Be Equal  ${response_body}  ${response}
    User can delete dashboard in 'kibana' with name '${dash_name}' (${PKI_TOKEN}, ${TENANT})
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Deletion in 'kibana' with '${username}'
    Dictionaries Should Be Equal  ${response_body}  ${response}

User can get list of dashboards in Kibana that were saved by him
    [Tags]   Dash-1.4   positive   es_migration_TC  ui_migration_TC  inprogress
    User can get list of dashboards in 'kibana' (${PKI_TOKEN}, ${TENANT})
    ${response_body}    Get Response Body
    LOG   ${response_body}
    #    may fail in the shared environment
    The response code should be 404
    Create Dasnboard with random name in Kibana for '${PKI_TOKEN}' and '${TENANT}'
    Sleep   10
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'kibana' with '${username}'
    Dictionaries Should Be Equal  ${response_body}  ${response}
    User can get list of dashboards in 'kibana' (${PKI_TOKEN}, ${TENANT})
    ${response_body}    Get Response Body
    LOG   ${response_body}
    Should Be Equal As Integers   ${response_body['hits']['total']}   1
    Should Be Equal As Strings   ${response_body['hits']['hits'][0]['_id']}   ${dash_name}

Create shareable link in Kibana, share it with another user and delete it
    [Tags]   Dash-1.5   positive   multitenancy  es_migration_TC  ui_migration_TC
    User send POST request to keystone for demo user
    Create Dasnboard with random name in Kibana for '${PKI_TOKEN_demo}' and '${tenant_id_demo}'
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'kibana' with '${user_demo}'
    Dictionaries Should Be Equal  ${response_body}  ${response}
    User can share temporary link to dashboard in 'kibana' with '${dash_body}' (${PKI_TOKEN_demo}, ${tenant_id_demo})
    The response code should be 201
    ${response_body}    Get Response Body
    ${body_id}  Set Variable  ${response_body['_id']}
    ${res}   Create Dictionary for temp link in 'kibana' with '${body_id}'
    ${url}   Create shareable link with '${response_body['_id']}' for 'kibana'
    Get data from keystone with '${keystone_v3}'
    User can follow the created link in 'kibana' for dashboard with '${body_id}' (${PKI_TOKEN}, ${Tenant})
    ${response_body}    Get Response Body
    The response code should be 200
    Should Be Equal As Strings   ${response_body['_id']}   ${body_id}
    LOG   ${response_body}
    Dictionary Should Contain Item    ${response_body}   found   True
    #-----------------------------------------------------------------
    Delete item with '${body_id}' from 'kibana-int' index in elasticsearch
    ${response_body}    Get Response Body
    Dictionary Should Contain Item    ${response_body}   found   True
    #----------------------------------------------------------------
    User can delete dashboard in 'kibana' with name '${dash_name}' (${PKI_TOKEN_demo}, ${tenant_id_demo})
    The response code should be 200

User cannot get list of dashboards in Kibana that were not saved by him
    [Tags]   Dash-1.6   positive   multitenancy   es_migration_TC  ui_migration_TC
    User send POST request to keystone for demo user
    Create Dasnboard with random name in Kibana for '${PKI_TOKEN_demo}' and '${tenant_id_demo}'
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'kibana' with '${user_demo}'
    Dictionaries Should Be Equal  ${response_body}  ${response}
    User can get list of dashboards in 'kibana' (${PKI_TOKEN_demo}, ${tenant_id_demo})
    ${response_body}    Get Response Body
    LOG   ${response_body}
    The response code should be 200
    Get data from keystone with '${keystone_v3}'
    User can get list of dashboards in 'kibana' (${PKI_TOKEN}, ${TENANT})
    ${response_body}    Get Response Body
    LOG   ${response_body}
#    may fail in the shared environment
    The response code should be 404

User cannot delete dashboard created by another user
    [Tags]   Dash-1.7   negative  multitenancy  es_migration_TC  ui_migration_TC
    User send POST request to keystone for demo user
    Create Dasnboard with random name in Kibana for '${PKI_TOKEN_demo}' and '${tenant_id_demo}'
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'kibana' with '${user_demo}'
    Dictionaries Should Be Equal  ${response_body}  ${response}
    Get data from keystone with '${keystone_v3}'
    User can delete dashboard in 'kibana' with name '${dash_name}' (${PKI_TOKEN}, ${TENANT})
    ${response_body}    Get Response Body
    Should Be String   ${response_body}
    Should Contain   ${response_body}   found
    Should Contain    ${response_body}  false

*** Keywords ***
User send POST request to keystone for demo user
    User sends POST request to keystone with '${keystone_demo_v3}'
    The response code should be 201
    User saves PKI_TOKEN from keystone
    Set Global Variable    ${PKI_TOKEN_demo}    ${PKI_TOKEN}
    User saves tenant_id
    Set Global variable    ${tenant_id_demo}    ${tenant_id}
    Get APIKEY for '${Tenant_demo}' with '${PKI_TOKEN_demo}'
    The response code should be 200
    User saves APIKEY
    Set Global variable    ${apikey_demo}    ${apikey}

Create Dasnboard with random name in Kibana for '${keystone_token}' and '${tenat_name}'
    ${rnd}    Generate Random String   10   [LETTERS]
    Set Global Variable   ${dash_name}   ${rnd}-QA
    # TODO: change  ${dash_body} for the correct one
    Set Global Variable   ${dash_body}    {"title":"${dash_name}","services":{"query":{"list":{"0":{"query":"*","alias":"","color":"#7EB26D","id":0,"pin":false,"type":"lucene","enable":true}},"ids":[0]},"filter":{"list":{"0":{"type":"time","field":"@timestamp","from":"now-5m","to":"now","mandate":"must","active":true,"alias":"","id":0}},"ids":[0]}},"rows":[{"title":"Graph","height":"350px","editable":true,"collapse":false,"collapsable":true,"panels":[{"span":12,"editable":true,"group":["default"],"type":"histogram","mode":"count","time_field":"@timestamp","value_field":null,"auto_int":true,"resolution":100,"interval":"1s","fill":3,"linewidth":3,"timezone":"browser","spyable":true,"zoomlinks":true,"bars":true,"stack":true,"points":false,"lines":false,"legend":true,"x-axis":true,"y-axis":true,"percentage":false,"interactive":true,"queries":{"mode":"all","ids":[0]},"title":"Events over time","intervals":["auto","1s","1m","5m","10m","30m","1h","3h","12h","1d","1w","1M","1y"],"options":true,"tooltip":{"value_type":"cumulative","query_as_alias":true},"scale":1,"y_format":"none","grid":{"max":null,"min":0},"annotate":{"enable":false,"query":"*","size":20,"field":"_type","sort":["_score","desc"]},"pointradius":5,"show_query":true,"legend_counts":true,"zerofill":true,"derivative":false}],"notice":false},{"title":"Events","height":"350px","editable":true,"collapse":false,"collapsable":true,"panels":[{"title":"All events","error":false,"span":12,"editable":true,"group":["default"],"type":"table","size":100,"pages":5,"offset":0,"sort":["@timestamp","desc"],"style":{"font-size":"9pt"},"overflow":"min-height","fields":[],"localTime":true,"timeField":"@timestamp","highlight":[],"sortable":true,"header":true,"paging":true,"spyable":true,"queries":{"mode":"all","ids":[0]},"field_list":true,"status":"Stable","trimFactor":300,"normTimes":true,"all_fields":false}],"notice":false}],"editable":true,"failover":false,"index":{"interval":"day","pattern":"[openstack-*-]YYYY.MM.DD","default":"NO_TIME_FILTER_OR_INDEX_PATTERN_NOT_MATCHED","warm_fields":true},"style":"light","panel_hints":true,"pulldowns":[{"type":"query","collapse":false,"notice":false,"query":"*","pinned":true,"history":[],"remember":10,"enable":true},{"type":"filtering","collapse":true,"notice":true,"enable":true}],"nav":[{"type":"timepicker","collapse":false,"notice":false,"status":"Stable","time_options":["5m","15m","1h","6h","12h","24h","2d","7d","30d"],"refresh_intervals":["5s","10s","30s","1m","5m","15m","30m","1h","2h","1d"],"timefield":"@timestamp","now":true,"filter_id":0,"enable":true}],"loader":{"save_gist":false,"save_elasticsearch":true,"save_local":true,"save_default":true,"save_temp":true,"save_temp_ttl_enable":true,"save_temp_ttl":"30d","load_gist":true,"load_elasticsearch":true,"load_elasticsearch_size":20,"load_local":true,"hide":false},"refresh":false}
    User send a PUT request to save dashboard with '${dash_name}' and '${dash_body}' in 'kibana' (${keystone_token}, ${tenat_name})

