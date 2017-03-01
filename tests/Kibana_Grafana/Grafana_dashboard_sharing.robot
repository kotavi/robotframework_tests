*** Settings ***
Resource          settings.robot
Resource          ../keywords/dashboard_keywords.robot

Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
#Test Setup  Run Keywords  Clear index in ES for 'grafana' dashboards '${username}'  Clear index in ES for 'grafana' dashboards '${user_demo}'
#Test Teardown  Run Keywords   Clear index in ES for 'grafana' dashboards '${username}'  Clear index in ES for 'grafana' dashboards '${user_demo}'

*** Variables ***
${num}   2

*** Test Cases ***
User can save displayed data in Grafana as dashboard to his index
    [Tags]   Dash-2.1   positive   smoke  influx_migration_TC  ui_migration_TC  es_migration_TC
    Create Dasnboard with random name in Grafana for '${PKI_TOKEN}' and '${TENANT}'
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'grafana' with '${username}'
    Dictionaries Should Be Equal  ${response_body}  ${response}

User can save displayed data as dashboard to his index predefined number of times in Grafana
    [Tags]   Dash-2.2   positive   es_migration_TC  ui_migration_TC  influx_migration_TC
    : FOR    ${index}    IN RANGE    ${num}
    \   Create Dasnboard with random name in Grafana for '${PKI_TOKEN}' and '${TENANT}'
    \   ${response_body}    Get Response Body
    \   ${response}  Create Dictionary of Successfull Dashboard Creation in 'grafana' with '${username}'
    \   Dictionaries Should Be Equal  ${response_body}  ${response}

User can delete dashboard created by him in Grafana
    [Tags]   Dash-2.3   positive   es_migration_TC  ui_migration_TC  influx_migration_TC
    Create Dasnboard with random name in Grafana for '${PKI_TOKEN}' and '${TENANT}'
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'grafana' with '${username}'
    Dictionaries Should Be Equal  ${response_body}  ${response}
    User can delete dashboard in 'grafana' with name '${dash_name}' (${PKI_TOKEN}, ${TENANT})
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Deletion in 'grafana' with '${username}'
    Dictionaries Should Be Equal  ${response_body}  ${response}

User can search through all existing dashboard from all the tenants and they should be visible to the user
    [Tags]   Dash-2.4   positive  multitenancy  es_migration_TC  ui_migration_TC  influx_migration_TC
    User send POST request to keystone for demo user
    Create Dasnboard with random name in Grafana for '${PKI_TOKEN_demo}' and '${tenant_id_demo}'
    Sleep   10
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'grafana' with '${user_demo}'
    Dictionaries Should Be Equal  ${response_body}  ${response}
    Get data from keystone with '${keystone_v3}'
    User can get list of dashboards in 'grafana' (${PKI_TOKEN}, ${TENANT})
    ${response_body}    Get Response Body
    Log   ${response_body}
    ${dash_num}    Set Variable    ${response_body['hits']['total']}
    : FOR    ${index}    IN RANGE    ${dash_num}
    \   ${name}    Set Variable    ${response_body['hits']['hits'][${index}]['sort'][0]}
    \   Run Keyword If    '${name}' == '${dash_name} (${user_demo})'    Exit For Loop
    Should Be Equal As Strings   ${name}   ${dash_name} (${user_demo})
    #----------------------------------------------------------------
    User can delete dashboard in 'grafana' with name '${dash_name}' (${PKI_TOKEN_demo}, ${tenant_id_demo})
    The response code should be 200

Use gets 403 error trying to delete dashboard of another user
    [Tags]   Dash-2.5   positive   multitenancy  es_migration_TC  ui_migration_TC
    User send POST request to keystone for demo user
    Create Dasnboard with random name in Grafana for '${PKI_TOKEN_demo}' and '${tenant_id_demo}'
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'grafana' with '${user_demo}'
    Dictionaries Should Be Equal  ${response_body}  ${response}
    Get data from keystone with '${keystone_v3}'
    User can delete dashboard in 'grafana' with name '${dash_name} (${user_demo})' (${PKI_TOKEN}, ${TENANT})
    The response code should be 403
    #----------------------------------------------------------------
    User can delete dashboard in 'grafana' with name '${dash_name}' (${PKI_TOKEN_demo}, ${tenant_id_demo})
    The response code should be 200

User can create temporary shared dashboard that is available for everyone who has a link to read/write
    [Tags]   Dash-2.6   positive  multitenancy  es_migration_TC  ui_migration_TC  CFS-867
    User send POST request to keystone for demo user
    Create Dasnboard with random name in Grafana for '${PKI_TOKEN_demo}' and '${tenant_id_demo}'
    ${response_body}    Get Response Body
    ${response}  Create Dictionary of Successfull Dashboard Creation in 'grafana' with '${user_demo}'
    Dictionaries Should Be Equal  ${response_body}  ${response}
    #-----------------------------------------------------------------
    User can share temporary link to dashboard in 'grafana' with '${dash_body}' (${PKI_TOKEN_demo}, ${tenant_id_demo})
    The response code should be 201
    ${response_body}    Get Response Body
    ${body_id}  Set Variable  ${response_body['_id']}
    ${res}   Create Dictionary for temp link in 'grafana' with '${body_id}'
    ${url}   Create shareable link with '${response_body['_id']}' for 'kibana'
    Get data from keystone with '${keystone_v3}'
    User can follow the created link in 'grafana' for dashboard with '${body_id}' (${PKI_TOKEN}, ${Tenant})
    ${response_body}    Get Response Body
    The response code should be 200
    Should Be Equal As Strings   ${response_body['_id']}   ${body_id}
    LOG   ${response_body}
    Dictionary Should Contain Item    ${response_body}   found   True
    #-----------------------------------------------------------------
    Delete item with '${body_id}' from 'grafana-int' index in elasticsearch
    ${response_body}    Get Response Body
    Dictionary Should Contain Item    ${response_body}   found   True
    #----------------------------------------------------------------
    User can delete dashboard in 'grafana' with name '${dash_name}' (${PKI_TOKEN_demo}, ${tenant_id_demo})
    The response code should be 200

#User can save dashboard in his index of another user with new name
#    [Tags]   Dash-2.7   positive   es_migration_TC  ui_migration_TC

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

Create Dasnboard with random name in Grafana for '${keystone_token}' and '${tenat_name}'
    ${rnd}    Generate Random String   10   [LETTERS]
    Set Global Variable   ${dash_name}   ${rnd}-QA
    Set Global Variable   ${dash_body}    {"user":"guest","group":"guest","title":"${dash_name}","tags":[],"dashboard":"{'id':${dash_name},'title':'${dash_name}','originalTitle':'Grafana','tags':[],'style':'dark','timezone':'browser','editable':true,'hideControls':false,'sharedCrosshair':false,'rows':[{'title':'New row','height':'150px','collapse':false,'editable':true,'panels':[{'id':1,'span':12,'editable':true,'type':'text','mode':'html','style':{},'title':'Welcome to'}]},{'title':'Welcome to Grafana','height':'210px','collapse':false,'editable':true,'panels':[{'id':2,'span':6,'type':'text','mode':'html','style':{},'title':'Documentation Links'},{'id':3,'span':6,'type':'text','mode':'html','style':{},'title':'Tips & Shortcuts'}]},{'title':'test','height':'250px','editable':true,'collapse':false,'panels':[{'id':4,'span':12,'type':'graph','x-axis':true,'y-axis':true,'scale':1,'y_formats':['%C2%B5s','short'],'grid':{'max':null,'min':null,'leftMax':null,'rightMax':null,'leftMin':null,'rightMin':null,'threshold1':null,'threshold2':null,'threshold1Color':'rgba(216, 200, 27, 0.27)','threshold2Color':'rgba(234, 112, 112, 0.22)'},'resolution':100,'lines':true,'fill':1,'linewidth':2,'points':false,'pointradius':5,'bars':false,'stack':false,'spyable':true,'options':false,'legend':{'show':true,'values':false,'min':false,'max':false,'current':false,'total':false,'avg':false},'interactive':true,'legend_counts':true,'timezone':'browser','percentage':false,'nullPointMode':'connected','steppedLine':false,'tooltip':{'value_type':'cumulative','query_as_alias':true,'shared':false},'targets':[{'target':'randomWalk('random walk')','function':'mean','column':'value'}],'aliasColors':{},'aliasYAxis':{},'title':'First Graph (click title to edit)','datasource':'influxdb','renderer':'flot','annotate':{'enable':false},'seriesOverrides':[]}]}],'nav':[{'type':'timepicker','collapse':false,'enable':true,'status':'Stable','time_options':['5m','15m','1h','6h','12h','24h','2d','7d','30d'],'refresh_intervals':['5s','10s','30s','1m','5m','15m','30m','1h','2h','1d'],'now':false,'notice':false}],'time':{'from':'2015-02-18T23:47:49.407Z','to':'2015-02-19T00:04:33.556Z'},'templating':{'list':[]},'annotations':{'list':[]},'refresh':false,'version':6,'hideAllLegends':false}"}
    User send a PUT request to save dashboard with '${dash_name}' and '${dash_body}' in 'grafana' (${keystone_token}, ${tenat_name})
