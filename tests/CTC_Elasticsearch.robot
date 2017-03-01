*** Settings ***
Documentation     Set of tests is used for component testing of Elasticsearch.
...               Here we check that ES is available for operations of POST, GET, DELETE.

Resource          keywords/keywords.robot
Library           libs/ElasticSearchClient.py
Library           libs/Additional.py

Suite Setup   Delete Index From Es  tmp_test
Suite Teardown   Delete Index From Es  tmp_test
Test Setup    Get datetime

*** Test Cases ***
Elasticsearch version number is correct
    [Tags]    CTC-EvSt-1  ctc_smoke  positive
    Set Global Variable    ${url}    http://${es_cluster[0]}:9200
    Set Global Variable    ${method}    GET
    Log    "GET request on link ${url}"
    GET Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Log To Console   ${response_body}
    Log To Console   Elasticsearch version number
    Log To Console   ${response_body['version']['number']}
    Should Be Equal   ${response_body['version']['number']}   ${ES_version}

Elasticsearch cluster name and node names are correct
    [Tags]    CTC-EvSt-2  ctc_smoke  positive
    ${es_cluster}   Create List  @{es_cluster}
    ${count}  Get Length  ${es_cluster}
    Log To Console   Elasticsearch nodes:
    : FOR   ${i}   IN RANGE   ${count}
    \    ${url}    Set Variable    http://${es_cluster[${i}]}:9200/
    \    ${method}    Set Variable   GET
    \    Log    "GET request on link ${url}"
    \    GET Request    ${url}
    \    The response code should be 200
    \    ${response_body}    Get Response Body
    \    Should Be Equal As Strings   ${response_body["status"]}   200
    \    Log To Console   ${response_body["name"]}
    \    Should Be Equal   ${response_body["cluster_name"]}   ${es_cluster_name}

Mappings are created for ES
    [Tags]    CTC-EvSt-3  ctc_smoke  es_migration_TC  positive
     ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=directly to ES at ${datetime}  pid=${60385}
     ${message_id}  User Send Message To ES  /openstack-549469538e5ab9fec47d3-2015.09.23/logs/   ${es_dict}
     Sleep  10
     ${message}  Get Message From ES By Id  /openstack-549469538e5ab9fec47d3-2015.09.23/logs/  ${message_id}
     Dictionaries Should Be Equal  ${message["_source"]}   ${es_dict}

    ${url}    Set Variable     http://${es_cluster[0]}:${ES_port}/openstack-549469538e5ab9fec47d3-2015.09.23/_mapping
    ${method}    Set Variable   GET
    Log    "GET request on link ${url}"
    GET Request    ${url}

    The response code should be 200
    ${response_body}    Get Response Body
    Log To Console  ${response_body}

    Delete Message From ES  /openstack-549469538e5ab9fec47d3-2015.09.23/logs/  ${message_id}
    ${message}  Get Message From ES By Id  /openstack-549469538e5ab9fec47d3-2015.09.23/logs/  ${message_id}
    Should Be Equal As Strings  ${message}  Message was not found

Post message to ES index tmp_test
    [Tags]    CTC-EvSt-4   CTC-EvSt-5   CTC-EvSt-6  ctc_smoke  positive  es_migration_TC
     ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=directly to ES at ${datetime}
     ${message_id}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
     Sleep  10
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Dictionaries Should Be Equal  ${message["_source"]}  ${es_dict}
     Delete Message From ES  /tmp_test/logs/  ${message_id}
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Should Be Equal As Strings  ${message}  Message was not found

Post message to ES index tmp_test with host field
    [Tags]    CTC-EvSt-8  ctc_smoke  positive  es_migration_TC
    ${es_dict}  Create Dictionary  host=epmp-px2-lmm-sys-srv-p23   user=testuser  post_date=2014-06-17T19:12:12  message=directly to ES at ${datetime}
    Log  ${es_dict}
    ${message_id}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    Sleep  10
    ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
    Dictionaries Should Be Equal  ${message["_source"]}  ${es_dict}
    Log To Console  ${message["_source"]}
    Delete Message From ES  /tmp_test/logs/  ${message_id}
    ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
    Should Be Equal As Strings  ${message}  Message was not found

Post message to ES with empty user field with no exception
    [Tags]    CTC-EvSt-9  ctc_smoke  es_migration_TC  positive
     ${es_dict}  Create Dictionary  user=   post_date=2014-06-17T19:12:12  message=directly to ES at ${datetime}  pid=${60385}
     ${message_id}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
     Sleep  10
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Dictionaries Should Be Equal  ${message["_source"]}  ${es_dict}
     Delete Message From ES  /tmp_test/logs/  ${message_id}
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Should Be Equal As Strings  ${message}  Message was not found

Post message to ES with empty message field with no exception
    [Tags]    CTC-EvSt-10  ctc_smoke  es_migration_TC  positive
     ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=  pid=${60385}
     ${message_id}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
     Sleep  10
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Dictionaries Should Be Equal  ${message["_source"]}  ${es_dict}
     Delete Message From ES  /tmp_test/logs/  ${message_id}
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Should Be Equal As Strings  ${message}  Message was not found

Post message to ES with empty post_date field and get exception
    [Tags]    CTC-EvSt-11  ctc_smoke  es_migration_TC  negative
    #Response body: {u'status': 400, u'error': u'RemoteTransportException[[ES-slave qa-es-3][inet[/192.168.8.241:9300]][index]]; nested: MapperParsingException[failed to parse [post_date]]; ne
    #sted: MapperParsingException[failed to parse date field [], tried both date format [dateOptionalTime], and timestamp number with locale []]; ne
    #sted: IllegalArgumentException[Invalid format: ""]; '}
    ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=directly to ES at ${datetime}  pid=${60385}
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    ${es_dict}  Create Dictionary  user=testuser  post_date=  message=directly to ES at ${datetime}  pid=${60385}
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    Should Be Equal As Strings  ${exception["status"]}  400
    ${error}  Get Message From ES By Body  /tmp_test/logs/   ${es_dict}
    Should Be Equal As Strings  ${error}  Message was not found

Post message to ES with empty pid field with no exception
    [Tags]    CTC-EvSt-12  ctc_smoke  es_migration_TC  positive
     ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=directly to ES at ${datetime}  pid=
     ${message_id}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
     Sleep  10
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Dictionaries Should Be Equal  ${message["_source"]}  ${es_dict}
     Delete Message From ES  /tmp_test/logs/  ${message_id}
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Should Be Equal As Strings  ${message}  Message was not found

Post message to ES with wrong format for post_date field and get exception
    [Tags]    CTC-EvSt-13  ctc_smoke  es_migration_TC  negative
    #"Response body: {u'status': 400, u'error': u'RemoteTransportException[[ES-slave qa-es-3][inet[/192.168.8.241:9300]][index]]; nested: MapperParsingException[failed to parse [post_date]]; ne
    #sted: MapperParsingException[failed to parse date field [2014/06/17T19/12/12], tried both date format [dateOptionalTime], and timestamp number
    #with locale []]; nested: IllegalArgumentException[Invalid format: "2014/06/17T19/12/12" is malformed at "/06/17T19/12/12"]; '}
    ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=temporary message ${datetime}  pid=${60385}
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    ${es_dict}  Create Dictionary  user=testuser  post_date=2014/06/17T19/12/12  message=directly to ES at ${datetime}  pid=${60385}
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    Should Be Equal As Strings  ${exception["status"]}  400
    ${error}  Get Message From ES By Body  /tmp_test/logs/  ${es_dict}
    Should Be Equal As Strings  ${error}  Message was not found

Post message to ES with wrong format for pid field and get exception
    [Tags]    CTC-EvSt-14  ctc_smoke  es_migration_TC  negative
    #{u'status': 400, u'error': u'RemoteTransportException[[ES-slave qa-es-5][inet[/192.168.8.239:9300]][index]];
    #nested: MapperParsingException[failed to parse [pid]]; nested: NumberFormatException[For input string: "09rt56"]; '}
    ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=temporary message ${datetime}  pid=${60385}
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=directly to ES at ${datetime}  pid=09rt56
#    ${exception}  User Send Message To ES  /tmp_test/logs/  {"user" : "testuser","post_date" : "2014-06-17T19:12:12","message" : "directly to ES at ${datetime}","pid" : "09rt56"}
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    Should Be Equal As Strings  ${exception["status"]}  400
    ${error}  Get Message From ES By Body  /tmp_test/logs/  ${es_dict["message"]}
    Should Be Equal As Strings  ${error}  Message was not found

Post message to ES with wrong format for pid field and get exception2
    [Tags]    CTC-EvSt-15  ctc_smoke  es_migration_TC  negative
    ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=temporary message ${datetime}  pid=${60385}
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=directly to ES at ${datetime}  pid=603 85
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    Should Be Equal As Strings  ${exception["status"]}  400
    ${error}  Get Message From ES By Body  /tmp_test/logs/   ${es_dict}
    Should Be Equal As Strings  ${error}  Message was not found

Post message to ES with wrong format for pid field and get exception3
    [Tags]    CTC-EvSt-16  ctc_smoke  es_migration_TC  negative
    #Response body: {u'status': 400, u'error': u'RemoteTransportException[[ES-slave qa-es-4][inet[/192.168.8.240:9300]][index]];
    #nested: MapperParsingException[failed to parse [pid]]; nested: NumberFormatException[For input string: "603 85"]; '}
    ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=temporary message ${datetime}  pid=${60385}
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=directly to ES at ${datetime}  pid=603.85
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    Should Be Equal As Strings  ${exception["status"]}  400
    ${error}  Get Message From ES By Body  /tmp_test/logs/  ${es_dict["message"]}
    Should Be Equal As Strings  ${error}  Message was not found

Post message to ES with string in pid field and get exception
    [Tags]    CTC-EvSt-17  ctc_smoke  es_migration_TC  negative
    ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  message=temporary message ${datetime}  pid=${60385}
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    ${es_dict}  Create Dictionary   pid=somestring  message=directly to ES at ${datetime}
    ${exception}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    Should Be Equal As Strings  ${exception["status"]}  400
    ${error}  Get Message From ES By Body  /tmp_test/logs/  ${es_dict["message"]}
    Should Be Equal As Strings  ${error}  Message was not found

Post message to ES without user field
    [Tags]    CTC-EvSt-18  ctc_smoke  es_migration_TC  positive
     ${es_dict}  Create Dictionary  post_date=2014-06-17T19:12:12  message=directly to ES at ${datetime}  pid=${60385}
     ${message_id}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
     Sleep  10
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Dictionaries Should Be Equal  ${message["_source"]}  ${es_dict}
     Delete Message From ES  /tmp_test/logs/  ${message_id}
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Should Be Equal As Strings  ${message}  Message was not found

Post message to ES without post_date field
    [Tags]    CTC-EvSt-19  ctc_smoke  es_migration_TC  positive
     ${es_dict}  Create Dictionary  user=testuser  message=directly to ES at ${datetime}  pid=${60385}
     ${message_id}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
     Sleep  10
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Dictionaries Should Be Equal  ${message["_source"]}   ${es_dict}
     Delete Message From ES  /tmp_test/logs/  ${message_id}
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Should Be Equal As Strings  ${message}  Message was not found

Post message to ES without message field
    [Tags]    CTC-EvSt-20  ctc_smoke  es_migration_TC  positive
     ${es_dict}  Create Dictionary  user=testuser  post_date=2014-06-17T19:12:12  pid=${60385}
     ${message_id}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
     Sleep  10
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Dictionaries Should Be Equal  ${message["_source"]}  ${es_dict}
     Delete Message From ES  /tmp_test/logs/  ${message_id}
     ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
     Should Be Equal As Strings  ${message}  Message was not found

Post message to ES with field _index
    [Tags]    CTC-EvSt-21  ctc_smoke  es_migration_TC  negative
    ${es_dict}  Create Dictionary  _index=tkorchak_test   pid=${452}
    ${message_id}  User Send Message To ES  /tmp_test/logs/  ${es_dict}
    Sleep  10
    ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
    Dictionaries Should Be Equal  ${message["_source"]}  ${es_dict}
    Delete Message From ES  /tmp_test/logs/  ${message_id}
    ${message}  Get Message From ES By Id  /tmp_test/logs/  ${message_id}
    Should Be Equal As Strings  ${message}  Message was not found

*** Keywords ***
Numder of logs should be ${num}
     ${ip}  Define Ip  ${es_cluster}
     ${res}  Count All ES Messages By Host   ${ip}  /tmp_test/logs/
     Should Be Equal As Strings  ${res}  ${num}
     Log To Console  ${ip}