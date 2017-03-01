*** Settings ***
Resource          ../keywords/keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/ExtendDictionary.py
Library           ../libs/InfluxClient.py
Library           ../libs/KafkaClient.py
Library           ../libs/RedisClient.py
Library           String

#Suite Setup  Run Keywords   Get data from keystone with '${keystone_v3}'
Suite Setup  Run Keywords   Define variables
Test Setup  Run Keywords   Get datetime

*** Variables ***
${delay}  60

*** Test Cases ***
Post to Kafka topic "metric" without apikey
    [Tags]    ITC-M-15  negative  storm_migration_TC  kafka_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_15","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}   ResultSet({})

Post to Kafka topic "metric" without tenant_id
    [Tags]    ITC-M-16  negative
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_16","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" without value
    [Tags]    ITC-M-17  negative  smoke  kafka_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_17","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" without host
    [Tags]    ITC-M-18  negative  critical  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_18","@version":"1","@timestamp":"${@timestamp}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" without collectd_type
    [Tags]    ITC-M-19  positive  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_19","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    Log To Console  ${search_req}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Log To Console   tenant_${tenant_id}
    Log To Console   ${result}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Post to Kafka topic "metric" without @timestamp
    [Tags]    ITC-M-20  negative  smoke  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_20","@version":"1","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Remove From Dictionary  ${kafka_dict}  @timestamp
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" without @version
    [Tags]    ITC-M-21  positive  influx_migration_TC
    ${json_1}    Set Variable   {"tags":"ITC_M_21","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${json_1}
    Sleep  ${delay}
    ${kafka_dict}  Convert To Dictionary  ${json_1}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Post to Kafka topic "metric" without name
    [Tags]    ITC-M-22  negative  smoke  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_22","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Log  ${kafka_dict}
    Sleep   30
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" without type_instance
    [Tags]    ITC-M-22a  positive  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_22a","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Post to Kafka topic "metric" with field api_key
    [Tags]    ITC-M-23  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_23","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","value":${time_ms},"tenant_id":"${tenant_id}","api_key":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})
    
Post to Kafka topic "metric" with field tenantid
    [Tags]    ITC-M-24  negative  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_24","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenantid":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})
    
Post to Kafka topic "metric" with field value_value
    [Tags]    ITC-M-25  negative  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_25","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value_value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with field host_name
    [Tags]    ITC-M-26  negative  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_26","@version":"1","@timestamp":"${@timestamp}","host_name":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with field apikey format- int
    [Tags]    ITC-M-27  negative  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_27","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"1234566"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with field apikey format- list
    [Tags]    ITC-M-28  negative  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_28","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":[${apikey}]}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with field tenant_id format- long
    [Tags]    ITC-M-29  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_29","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":1234566412546532,"apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})
    
Post to Kafka topic "metric" with field tenant_id format- dict
    [Tags]    ITC-M-30  negative  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_30","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},{"tenant_id":"${tenant_id}"},"apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with field host format- tuple
    [Tags]    ITC-M-31  negative  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_31","@version":"1","@timestamp":"${@timestamp}","host":(1,),"name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" with field host format- long
    [Tags]    ITC-M-32  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_32","@version":"1","@timestamp":"${@timestamp}","host":7982374236121482,"name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

User cannot save string value in Influxdb
    [Tags]    ITC-M-33  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_33","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":"7","tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Log   ${kafka_dict}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  30
    ${search_req}    Set variable    SELECT * FROM /${metric_name}/ where value=7
    ${result}     Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" with field value format- string with letters
    [Tags]    ITC-M-33a  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_33a","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":"34er","tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with field value format- list
    [Tags]    ITC-M-34  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":[1,2],"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with field value format- unicode
    [Tags]    ITC-M-34a  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34a","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":u'1',"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" with field value format- long
    [Tags]    ITC-M-34b  negative  storm_migration_TC
    ${value}   Set Variable   51924361L
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${value}   Set Variable   -0x19323L
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${value}   Set Variable   0122L
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${value}   Set Variable   0xDEFABCECBDAECBFBAEL
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${value}   Set Variable   0xDEFABCECBDAECBFBAEL
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${value}   Set Variable   -4721885298529L
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep   30
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" with field value format in exponencial form 32.3+e18
    [Tags]    ITC-M-34c  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34c","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":32.3+e18,"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" with field value format in exponencial form 7.2286071603222E13
    [Tags]    ITC-M-34cc  positive  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34cc","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":7.${time_ms}E13,"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=7${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Post to Kafka topic "metric" with field value format- float in complex form
    [Tags]    ITC-M-34d  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34d","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":4.53e-7j,"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

#User can post metric with values "080", "-0490"
#    [Tags]    ITC-M-34e  positive  smoke  storm_migration_TC  LMM-1648
#    ${search_req}    Set variable    SELECT COUNT (name) FROM /${metric_name}.${instance_type}/
#    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
#    Log   ${result}
#    @{values}  Create List   080  -0490
#    : FOR   ${i}   IN   @{values}
#    \    ${value}   Set Variable   ${i}
#    \    ${kafka_dict}    Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
#    \    Send Message To Kafka    metricTopic  ${kafka_dict}
#    Sleep   30
#    @{values}  Create List   80  -490
#    : FOR   ${i}   IN   @{values}
#    \    ${search_req}    Set Variable    SELECT * FROM /${metric_name}.${instance_type}/ where value='${i}'
#    \    ${result}    Querying Data From Influx  tenant_${tenant_id}  ${search_req}
#    \    Should Be Equal As Strings  ${result[0]["points"][0][1]}  1

#User cannot post metric with values "-0x260", "0x69"
#    [Tags]    ITC-M-34f  positive  smoke  storm_migration_TC  LMM-1648
#    ${search_req}    Set variable    SELECT COUNT (name) FROM /${metric_name}.${instance_type}/
#    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
#    Log   ${result}
#    @{values}  Create List   -0x260  0x69
#    : FOR   ${i}   IN   @{values}
#    \    ${value}   Set Variable   ${i}
#    \    ${kafka_dict}    Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
#    \    Send Message To Kafka    metricTopic  ${kafka_dict}
#    Sleep   30
#    : FOR   ${i}   IN   @{values}
#    \    ${search_req}    Set Variable    SELECT * FROM /${metric_name}.${instance_type}/
#    \    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
#    \    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" two same field value
    [Tags]    ITC-M-35  negative  storm_migration_TC
    ${kafka_dict}  Set Variable   {"tags":"ITC_M_35","version":1, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" two same field apikey
    [Tags]    ITC-M-36  negative  storm_migration_TC
    ${kafka_dict}  Set Variable   {"tags":"ITC_M_36","version":1, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id}","apikey":"${apikey}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" two same field tenant_id
    [Tags]    ITC-M-37  negative
    Set Global Variable  ${kafka_dict}  {"tags":"ITC_M_37","version":1, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id}","tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" two same different value
    [Tags]    ITC-M-38  negative
    Set Global Variable  ${kafka_dict}  {"tags":"ITC_M_38","version":1, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "value":322,"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" two different field apikey
    [Tags]    ITC-M-39  negative  storm_migration_TC
    Set Global Variable  ${kafka_dict}  {"tags":"ITC_M_39","version":1, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id}","apikey":"${apikey}","apikey":"itsmypass"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" two different field tenant_id
    [Tags]    ITC-M-40  negative
    Set Global Variable  ${kafka_dict}  {"tags":"ITC_M_40","version":1, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id}","tenant_id":"magicname","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" two different field host
    [Tags]    ITC-M-41  negative
    Set Global Variable  ${kafka_dict}  {"tags":"ITC_M_41","version":1, "@timestamp":"${@timestamp}","host":"qa_host", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" two different field @version
    [Tags]    ITC-M-42  negative
    Set Global Variable  ${kafka_dict}  {"tags":"ITC_M_42","@version":1, "@version":2, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" two same field @version
    [Tags]    ITC-M-43  negative
    Set Global Variable  ${kafka_dict}  {"tags":"ITC_M_43","@version":1, "@version":1, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with empty field value
    [Tags]    ITC-M-44  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_44","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":"","tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with Null in field value
    [Tags]    ITC-M-44a  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_44a","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":Null,"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with empty field apikey
    [Tags]    ITC-M-45  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_45","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":""}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with Null in field apikey
    [Tags]    ITC-M-45a  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_45a","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":Null}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with empty field host
    [Tags]    ITC-M-46  negative  critical  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_46","@version":"1","@timestamp":"${@timestamp}","host":"","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  10
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #-------------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" with Null in field host
    [Tags]    ITC-M-46a  negative  critical  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_46a","@version":"1","@timestamp":"${@timestamp}","host":Null,"name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #-------------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" with empty field tenant_id
    [Tags]    ITC-M-47  negative
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_47","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" with empty field @version
    [Tags]    ITC-M-48  positive
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_48","@version":"","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Post to Kafka topic "metric" with empty field @timestamp
    [Tags]    ITC-M-50  negative
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_50","@version":"1","@timestamp":"","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with long field apikey
    [Tags]    ITC-M-51  negative  storm_migration_TC
    ${apikey}  Set Variable  JEAzhlyh58asufuDCgnEJFKB5QS4DOnahZEunsifE0zXjsfZFWAQ6Je4WZjiVXi8sGfb0pGtclem28c3WY7Ko0JYsX3qkMWq6ODjRDGgBM2ZqKEyfZSBhmYrtatXUSaiYpAuEmDoa3o27xOGzyRR9MWOiEAeqhwgINRb3aLSFvnsZxfrCU7xhoHFX8ubwYpwtZ3M2gDqiXPeOYr1QWHulW0E52zIFO6wJsFCtc6yeRPMyXX268Vo8YUGfmbB4wuoP3uX3lCzO0njr0I48AJ
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_51","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Post to Kafka topic "metric" with long field name
    [Tags]    ITC-M-52  negative  smoke  storm_migration_TC
    ${name}   Set Variable   ARoerNnUJ0c19njHcCLEyDx9uL7b0kT5j9ptxJWSPLtm9U87NJ58VLM9sNHlOMNwgIkO0OH3NuiHzI6YHlNUmvhtrV0SqHN9EVjMSs2ZQU2mO9yyNKYKH49MUxrcthoWXIWgPeucI4lzaYnngeIw1PuTInLKIfqQeLycrkshkEOtccwzvjqGasIJYvBLIQ0JV94pbv68Lf5CNICbk88KDnfKeQk5Ssp6nCsTbP7SixJHDFEkVB5CJOsJwP3tqVZ1jv7hruGGGUJBEACGQaY
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_52","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #-------------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${name}.${instance_type}/
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Topology can process number in value field with maximum digits - 19
    [Tags]    ITC-M-54  positive  storm_migration_TC
    ${value}    Generate Random String  19  [NUMBERS]
    ${value_int}   Convert To Integer   ${value}
    ${data}    Set Variable   {"tags":"ITC_M_54","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value_int},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${data}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${value_int}
    ${result}   Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

#Topology rejects metric with number in value field > 20 digits
#    [Tags]    ITC-M-54a  negative  smoke  storm_migration_TC  inprogress
#    ${value}    Set Variable  12345678909876543219798763
#    ${value_int}   Convert To Integer   ${value}
#    ${data}    Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value_int},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
#    Send Message To Kafka    metricTopic  ${data}
#    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/ where value=${value_int}
#    ${result}       Querying Data From Influx  tenant_${tenant_id}  ${search_req}
#    Should Be Equal As Strings   ${result}  ResultSet({})

Post to Kafka topic "metric" with long field host
    [Tags]    ITC-M-55  negative  critica  storm_migration_TC
    ${host}  Set Variable  Ab6vI8rYkoEfvkwj5jHjQiVflFHGGb2Q280KjR5De214iktqgkNjFoWDpB4QkeXoBRxTvS747ZGCGbZOnwKIUYURyGj3wNExZFrkkD0Wp1ewIIWaSvzvSDBJRvwLvzPqEkD0LpXZptBJzuepJIvr29IgwKN1MGllJ98IiuOQoKBpZZoV99wr887c1rjE6h1WXE9ceMYtTfufaOfOVVYuQ8tClrCTl6uPIVADf9Y8jLrnJivOFfwaGcXgqBJLqx1Di9rjO7vkGYq1uQ8MoYnB
    ${json_1}    Set Variable   {"tags":"ITC_M_55","@version":"1","@timestamp":"${@timestamp}","host":"${host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${json_1}
    Sleep  ${delay}
    ${data}  Convert To Dictionary  ${json_1}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Post to Kafka topic "metric" with long field type_instance
    [Tags]    ITC-M-56  positive  storm_migration_TC
    ${type_instance}   Set variable   FGkjnIbGUAttuPHhFZnO7WeaTIkLn90yzlw1hoHZfCFXzXPtmVEHgLNGbuNn1PqUFGkicDk5bN7ppHuvFnDtiKq72hBvSRwDPkyDe0AF2UzzteCh9pI7ya3gwDOBFGEPh4489g6TXw3jee6CLXuqFhPe5h4civLjMBLMtPUq5a9PklwIs5U6weEYVqR2rrPbitNqu9abZAeKCjuHEeQr2W7wDNpwiCri1vKY7IPsHzLyTvnVK476GkuFDBjWMmMyyLjlODlhgMhteFqBxcr
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_56","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${type_instance}","value":${time_ms},"tenant_id":"${tenant_id}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

*** Keywords ***
Define variables
    Set Global Variable  ${metric_name}  cpu.test.1
    Set Global Variable  ${instance_type}  wait
    Set Global Variable  ${db_host}       lmm_bastion

Querying Data From Influx And Find message  [Arguments]  ${search_req}  ${req}
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    ${res}  Find messages in influx response where  ${req}  ${result}
    Should Not Be Equal  ${res}   []
    [Return]  ${res}

Verify number of data
    Sleep  10
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/
    ${result}  Querying Data From Influx  tenant_${tenant_id}  ${search_req}
    Should Be Equal As Strings  ${result}   ResultSet({'(u'${metric_name}', None)': [{u'count': 8, u'time': u'1970-01-01T00:00:00Z'}]})

#Drop series ${series} from ${db}
#    Delete Influx Series  ${db}  ${series}
#
#Drop Database
#    Drop database for specific tenant '${tenant_id}'
#
#Create Database
#   Create Influx Database  tenant_${tenant_id}
#   ${res}  Get Database List From Influx