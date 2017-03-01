*** Settings ***
Documentation     Set of tests is used for component testing of InfluxDB.
...               Here we check that InfluxDB can create table and store sent data there
Resource          keywords/keywords.robot
Resource          keywords/prepopulate_data.robot
Library           libs/InfluxClient.py
Library           libs/Additional.py


*** Variables ***
${db_test}    CTC_TEST

${cq1}   select mean(value) from /.+_$/ group by time(1m) into :series_name_1w
${cq2}   select mean(value) from /.+_$/ group by time(5m) into :series_name_1m
${cq3}   select mean(value) from /.+_$/ group by time(1h) into :series_name_3m
#${test_cq}   select mean(value) from /^${tenant_id}.+_$/ group by time(1s) into :series_name_1s
${rp1}   /.+_@{affix[0]}$/
${rp2}   /.+_@{affix[1]}$/
${rp3}   /.+_@{affix[2]}$/
${rp4}   /.+_$/
${rp5}   /.*/

*** Test Cases ***
Check database CTC_TEST doesn't exist
    [Tags]    CTC-Influx-0a   ctc_smoke  influx_migration_TC  positive
    ${res}  Check db In Influx Exist   ${db_test}
    Should Be Equal As Strings  ${res}  Database CTC_TEST doesn't exist!

Create DB CTC_TEST in influxDB
    [Tags]    CTC-Influx-1   ctc_smoke  influx_migration_TC  positive
    Set global variable    ${db}    ${db_test}
    Create Influx Database  ${db}

Sent Post request to CTC_TEST influxDB
    [Tags]    CTC-Influx-2   ctc_smoke  influx_migration_TC  positive
    ${data}    Set variable   [{"measurement": "test_table","tags": {"host": "server_test_table","region": "mtv"},"time": "2009-11-10T23:00:00Z","fields": {"value": 56.4567123}}]
    Write Data To Influx  ${db_test}  ${data}
    Sleep  2

After DB is created it can be reached from all nodes in cluster
    [Tags]    CTC-Influx-2a   ctc_smoke  influx_migration_TC  positive
    ${influxdb_cluster}   Create List  @{influxdb_cluster}
    ${count}  Get Length  ${influxdb_cluster}
    : FOR   ${i}   IN RANGE   ${count}
    \    ${result}  Querying Data From Influx By Host IP  ${influxdb_cluster[${i}]}   ${db_test}   SELECT * FROM test_table
    \    Log To Console  \n${result}
    \    ${res}  Set Variable  ResultSet({'(u'test_table', None)': [{u'host': u'server_test_table', u'region': u'mtv', u'value': 56.4567123, u'time': u'2009-11-10T23:00:00Z'}]})
    \    Should Be Equal As Strings    ${res}  ${result}

Send Get request to CTC_TEST influxDB
    [Tags]    CTC-Influx-3   ctc_smoke  influx_migration_TC  positive
    ${ip}  Define ip  ${influxdb_cluster}
    ${result}  Querying Data From Influx By Host IP  ${ip}  ${db_test}  SELECT * FROM test_table
    Log To Console  \n${result}
    ${res}  Set Variable  ResultSet({'(u'test_table', None)': [{u'host': u'server_test_table', u'region': u'mtv', u'value': 56.4567123, u'time': u'2009-11-10T23:00:00Z'}]})
    Should Be Equal As Strings    ${res}  ${result}

Delete DB CTC_TEST from in influxDB
    [Tags]    CTC-Influx-4   ctc_smoke  influx_migration_TC  positive
    Delete Influx Database   ${db_test}
    Check DB In Influx Does Not Exist  ${db_test}

#Check Continuous Queries
#     [Tags]  CTC-Influx-6  ctc_smoke  influx_migration_TC
#     @{queries}   Create List  ${cq1}  ${cq2}  ${cq3}
#     @{queries2}   Create List
#     ${count}  Get Length  ${queries}
#     ${actual_queries}  Get Influxdb Continuous Queries
#     ${actual_queries_number}  Get Length  ${actual_queries['${db_name}']}
#     Should Be Equal As Integers  ${count}  ${actual_queries_number}
#     : FOR  ${index}  IN RANGE  ${count}
#     \    Append To List  ${queries2}  ${actual_queries['${db_name}'][${index}]['Query']}
#     Log To Console  ${queries2}
#
#Check Retention Policies
#     [Tags]  CTC-Influx-7  ctc_smoke  influx_migration_TC
#     @{rps}   Create List  ${rp1}  ${rp2}  ${rp3}  ${rp4}  ${rp5}
#     @{rps2}   Create List
#     ${count}  Get Length  ${rps}
#     ${actual_rps}  Get Influxdb Shard Spaces
#     ${actual_rps_number}  Get Length  ${actual_rps['${db_name}']}
#     Should Be Equal As Integers  ${count}  ${actual_rps_number}
#     : FOR  ${index}  IN RANGE  ${count}
#     \    Append To List  ${rps2}  ${actual_rps['${db_name}'][${index}]['regex']}
#     Log To Console   ${rps2}

#Create series with symbols - and check cq
#    [Tags]  CTC-Influx-8  ctc_smoke  inprogress
#    ${result}  Querying Data From Influx  ${db_name}  ${test_cq}
#    ${info}  Get Influxdb Cluster Info
#    @{tables}  Create List   my_test_series_  its%needed_   1_23a^$_   qa.metric_   12-test*&!~_
#    : FOR  ${table}  IN  @{tables}
#    \    Write Data To Influx  ${db_name}  [{"name":"${table}","columns":["host", "value"],"points":[[ "test-ui-5", 56.4567123]]}]
#    \    ${result}  Wait Until Keyword Succeeds  1 min  0 sec   Querying Data From Influx  ${db_name}  select * from "${table}_1s"
#    \    ${ind}  Get Index From List  ${result[0]['columns']}  value
#    \    Should Be Equal As Strings  ${result[0]["points"][0][${ind}]}  56.4567123
#    \    Delete Influx Series  ${db_name}  ${table}
#    Delete Continuous Query  ${db_name}   ${test_cq}
