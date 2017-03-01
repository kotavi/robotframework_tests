*** Settings ***
Resource          metric_validation_keywords.robot


Suite Setup   Run Keywords  Create dictionary with roles  Create dictionary with services  Create dictionary with ldap_groups
Suite Setup   Run Keywords  Create global tenant and apikey

Test Setup  Run Keywords   Get datetime
Suite Teardown  Run Keywords  Delete tenant '${tenant_id_global}'

Suite Teardown  Run Keywords    Drop Databases for '${tenant_id_global}'

Suite Setup  Run Keywords   Define variables

*** Variables ***
${delay}  10

*** Test Cases ***
Metric event without no apikey field will be rejected by topology
    [Tags]    ITC-Metric-validation-2.1  negative  storm_migration_TC  kafka_migration_TC
    ${kafka_dict}    Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}   ResultSet({})

Metric event without no tenant_id field will be rejected by topology
    [Tags]    ITC-Metric-validation-2.2  negative
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_16","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM unknown_notifications
    ${result}   Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event without no value field will be rejected by topology
    [Tags]    ITC-Metric-validation-2.3  negative  smoke  kafka_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_17","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}   Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event without no host field will be rejected by topology
    [Tags]    ITC-Metric-validation-2.4  negative  critical  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_18","@version":"1","@timestamp":"${@timestamp}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event without no collectd_type field will be stored to Influx
    [Tags]    ITC-Metric-validation-2.5  positive  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_19","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    Log To Console  ${search_req}
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Log To Console   tenant_${tenant_id_global}
    Log To Console   ${result}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Metric event without no @timestamp field will be rejected by topology
    [Tags]    ITC-Metric-validation-2.6 negative  smoke  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_20","@version":"1","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Remove From Dictionary  ${kafka_dict}  @timestamp
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}   Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event without no @version field will be stored to Influx
    [Tags]    ITC-Metric-validation-2.7  positive  influx_migration_TC
    ${json_1}    Set Variable   {"tags":"ITC_M_21","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${json_1}
    Sleep  ${delay}
    ${kafka_dict}  Convert To Dictionary  ${json_1}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Metric event without no name field will be rejected by topology
    [Tags]    ITC-Metric-validation-2.8  negative  smoke  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_22","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Log  ${kafka_dict}
    Sleep   ${delay}
    ${search_req}    Set variable    SELECT * FROM /.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event without no type_instance field will be stored to Influx
    [Tags]    ITC-Metric-validation-2.9  positive  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_22a","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Metric event with field apikey format - list will be rejected by topology
    [Tags]    ITC-Metric-validation-2.10  negative  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_28","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":[${apikey}]}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with field tenant_id format - long will be rejected by topology
    [Tags]    ITC-Metric-validation-2.11  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_29","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":1234566412546532,"apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({})

Metric event with field tenant_id format - dict will be rejected by topology    
    [Tags]    ITC-Metric-validation-2.12  negative  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_30","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},{"tenant_id":"${tenant_id_global}"},"apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with field host format - tuple will be rejected by topology    
    [Tags]    ITC-Metric-validation-2.13  negative  influx_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_31","@version":"1","@timestamp":"${@timestamp}","host":(1,),"name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with field host format - long will be rejected by topology 
    [Tags]    ITC-Metric-validation-2.14  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_32","@version":"1","@timestamp":"${@timestamp}","host":7982374236121482,"name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with field value format - srting (numbers) will be rejected by topology
    [Tags]    ITC-Metric-validation-2.15  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_33","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":"7","tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Log   ${kafka_dict}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}/ where value=7
    ${result}     Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with field value format - string (letters) will be rejected by topology
    [Tags]    ITC-Metric-validation-2.16  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_33a","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":"34er","tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with field value format - list will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.17  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":[1,2],"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with field value format - unicode will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.18  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34a","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":u'1',"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with field value format - long will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.19  negative  storm_migration_TC
    ${value}   Set Variable   51924361L
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${value}   Set Variable   -0x19323L
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${value}   Set Variable   0122L
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${value}   Set Variable   0xDEFABCECBDAECBFBAEL
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${value}   Set Variable   0xDEFABCECBDAECBFBAEL
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${value}   Set Variable   -4721885298529L
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34b","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep   30
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}   Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with field value format in exponencial form 32.3+e18 will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.20  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34c","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":32.3+e18,"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}   Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with field value format in exponencial form 7.2286071603222E13 will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.21  positive  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34cc","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":7.${time_ms}E13,"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=7${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Metric event with field value format - float in complex form will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.22  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_34d","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":4.53e-7j,"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with two same value fields will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.23  negative  storm_migration_TC
    ${kafka_dict}  Set Variable   {"tags":"ITC_M_35","version":1, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with two same apikey fields will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.24  negative  storm_migration_TC
    ${kafka_dict}  Set Variable   {"tags":"ITC_M_36","version":1, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id_global}","apikey":"${apikey}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with two same tenant_id fields will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.25  negative
    Set Global Variable  ${kafka_dict}  {"tags":"ITC_M_37","version":1, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id_global}","tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with two host fields will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.26  negative
    Set Global Variable  ${kafka_dict}  {"tags":"ITC_M_41","version":1, "@timestamp":"${@timestamp}","host":"qa_host", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with two @version fields will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.27  negative
    Set Global Variable  ${kafka_dict}  {"tags":"ITC_M_42","@version":1, "@version":2, "@timestamp":"${@timestamp}", "host":"${db_host}","name":"${metric_name}","plugin_instance":2, "collectd_type":"cpu", "type_instance":"${instance_type}", "value":${time_ms}, "tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with empty field value will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.28  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_44","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":"","tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with Null in field value will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.29  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_44a","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":Null,"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with empty field apikey will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.30  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_45","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":""}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with Null in field apikey will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.31  negative  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_45a","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":Null}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with empty field host will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.32  negative  critical  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_46","@version":"1","@timestamp":"${@timestamp}","host":"","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with Null in field host will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.33  negative  critical  storm_migration_TC
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_46a","@version":"1","@timestamp":"${@timestamp}","host":Null,"name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with empty field tenant_id will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.34  negative
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_47","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Metric event with empty field @timestamp will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.35  negative
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_50","@version":"1","@timestamp":"","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${search_req}    Set variable    SELECT * FROM notifications
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    #------------------------------------------------------------------------------------
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})
    
Metric event with long field name will be rejected by topology     
    [Tags]    ITC-Metric-validation-2.36  negative  smoke  storm_migration_TC
    ${name}   Set Variable   ARoerNnUJ0c19njHcCLEyDx9uL7b0kT5j9ptxJWSPLtm9U87NJ58VLM9sNHlOMNwgIkO0OH3NuiHzI6YHlNUmvhtrV0SqHN9EVjMSs2ZQU2mO9yyNKYKH49MUxrcthoWXIWgPeucI4lzaYnngeIw1PuTInLKIfqQeLycrkshkEOtccwzvjqGasIJYvBLIQ0JV94pbv68Lf5CNICbk88KDnfKeQk5Ssp6nCsTbP7SixJHDFEkVB5CJOsJwP3tqVZ1jv7hruGGGUJBEACGQaY
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_52","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${name}.${instance_type}/
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Topology can process number in value field with maximum digits - 19
    [Tags]    ITC-Metric-validation-2.37  positive  storm_migration_TC
    ${value}    Generate Random String  19  [NUMBERS]
    ${value_int}   Convert To Integer   ${value}
    ${data}    Set Variable   {"tags":"ITC_M_54","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value_int},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${data}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${value_int}
    ${result}   Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Topology rejects metric with number in value field > 20 digits
    [Tags]    ITC-Metric-validation-2.38  negative  smoke  storm_migration_TC  inprogress
    ${value}    Set Variable  12345678909876543219798763
    ${value_int}   Convert To Integer   ${value}
    ${data}    Set Variable   {"@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${value_int},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${data}
    Sleep  ${delay}
    ${search_req}    Set variable    SELECT * FROM /${metric_name}.${instance_type}/ where value=${value_int}
    ${result}       Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings   ${result}  ResultSet({})

Topology can process event with long field host
    [Tags]    ITC-Metric-validation-2.39  negative  critica  storm_migration_TC
    ${host}  Set Variable  Ab6vI8rYkoEfvkwj5jHjQiVflFHGGb2Q280KjR5De214iktqgkNjFoWDpB4QkeXoBRxTvS747ZGCGbZOnwKIUYURyGj3wNExZFrkkD0Wp1ewIIWaSvzvSDBJRvwLvzPqEkD0LpXZptBJzuepJIvr29IgwKN1MGllJ98IiuOQoKBpZZoV99wr887c1rjE6h1WXE9ceMYtTfufaOfOVVYuQ8tClrCTl6uPIVADf9Y8jLrnJivOFfwaGcXgqBJLqx1Di9rjO7vkGYq1uQ8MoYnB
    ${json_1}    Set Variable   {"tags":"ITC_M_55","@version":"1","@timestamp":"${@timestamp}","host":"${host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${instance_type}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${json_1}
    Sleep  ${delay}
    ${data}  Convert To Dictionary  ${json_1}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

Topology can process event with long field type_instance
    [Tags]    ITC-Metric-validation-2.40  positive  storm_migration_TC
    ${type_instance}   Set variable   FGkjnIbGUAttuPHhFZnO7WeaTIkLn90yzlw1hoHZfCFXzXPtmVEHgLNGbuNn1PqUFGkicDk5bN7ppHuvFnDtiKq72hBvSRwDPkyDe0AF2UzzteCh9pI7ya3gwDOBFGEPh4489g6TXw3jee6CLXuqFhPe5h4civLjMBLMtPUq5a9PklwIs5U6weEYVqR2rrPbitNqu9abZAeKCjuHEeQr2W7wDNpwiCri1vKY7IPsHzLyTvnVK476GkuFDBjWMmMyyLjlODlhgMhteFqBxcr
    ${kafka_dict}    Set Variable   {"tags":"ITC_M_56","@version":"1","@timestamp":"${@timestamp}","host":"${db_host}","name":"${metric_name}","plugin_instance":2,"collectd_type":"cpu","type_instance":"${type_instance}","value":${time_ms},"tenant_id":"${tenant_id_global}","apikey":"${apikey}"}
    Send Message To Kafka    metricTopic  ${kafka_dict}
    Sleep  ${delay}
    ${kafka_dict}  Convert To Dictionary  ${kafka_dict}
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/ where value=${time_ms}
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings  ${result}  ResultSet({'(u'${metric_name}', None)': [{u'count': 1, u'time': u'1970-01-01T00:00:00Z'}]})

*** Keywords ***
Define variables
    Set Global Variable  ${metric_name}  cpu.test.1
    Set Global Variable  ${instance_type}  wait
    Set Global Variable  ${db_host}       lmm_bastion

Querying Data From Influx And Find message  [Arguments]  ${search_req}  ${req}
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    ${res}  Find messages in influx response where  ${req}  ${result}
    Should Not Be Equal  ${res}   []
    [Return]  ${res}

Verify number of data
    Sleep  10
    ${search_req}    Set variable    SELECT count(value) FROM /${metric_name}/
    ${result}  Querying Data From Influx  tenant_${tenant_id_global}  ${search_req}
    Should Be Equal As Strings  ${result}   ResultSet({'(u'${metric_name}', None)': [{u'count': 8, u'time': u'1970-01-01T00:00:00Z'}]})
