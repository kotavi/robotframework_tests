*** Variables ***
#use in case if keystone doesn't work or not accessible
#${tenant_id}   1dd50be286d6483f8f9c9abdadaa2b9f
#${apikey}   260cc97e-7256-4b45-a2ec-38ec00303085

${keystone_ip}    keystone.ash2.symcpe.net
#keystone.phx2.symcpe.net

#Voltad
${voltad_log}   /var/log
#path QA/PHX2
${settings_path}    /usr/lib/storm/conf
#path ASH2
${settings_path}    /data/home/storm/

#DEV
${IP_web}             https://localhost
${es_master_node}     10.109.8.8
${kibana_node}        localhost
@{es_cluster}         10.109.8.8
@{influxdb_cluster}    localhost
@{kafka_cluster}       localhost  localhost  localhost  localhost
${test_node}           localhost  #for callbacks use test VM from the same net
@{redis_cluster}       localhost
${storm_ip}            localhost
${qs_ip}               localhost
${qs_sleep_time}       30
@{zk_cluster}          localhost

#API versions
${query_api_version}   v1
${api_version}         v1
${api_version_v2}      v2

#Volta UI API
${centos_node}      192.168.9.4
${pckg_name}        volta-api-0.0.3-SNAPSHOT.jar

#credentials
${sudo_user}        tetiana_korchak
${sudo_pass}
${name_test_user1}    volta_test_user1
${pass_test_user1}    &eital3Gian3s
${name_test_user2}    volta_test_user2
${pass_test_user2}    @s5ngPeeaMts

#ports
${ES_port}          9200
${qs_port}          8081
${callback_port}    8000
${storm_port}       8744
${kafka_port}       9092
${kafka_api_port}   9000
${statsd_port}      8126
${kibana_port}      5601

${es_cluster_name}     es_aws_east_region
${ES_version}          1.7.5

#kafka topics
${tenantTopic}  tenantKeysTopic
${log_topic}    awsLogTopic
${alert_topic}   awsAlertTopic
${group_topic}   tenantKeysTopic

#credentials for main user
${Domain}           default
${Tenant_domain}    lmm
${Tenant}           lmm-qa

${username}         volta_test_user1
${keystone_pass}    &eital3Gian3s

${keystone_v3}      { "auth": { "scope": { "project": { "domain": {"name": "${Tenant_domain}"}, "name": "${Tenant}" } }, "identity": { "methods": ["password"], "password": { "user": { "domain": {"name": "${Domain}"}, "name": "${username}", "password": "${keystone_pass}"}}}}}

${user_demo}         volta_test_user2
${keystone_demo_pass}   @s5ngPeeaMts


${Tenant_demo}      lmm-qa-no-membership
${Domain_demo}      default
${Tenant_domain_demo}         default
${keystone_demo_v3}      { "auth": { "scope": { "project": { "domain": {"name": "${Tenant_domain_demo}"}, "name": "${Tenant_demo}" } }, "identity": { "methods": ["password"], "password": { "user": { "domain": {"name": "${Domain_demo}"}, "name": "${user_demo}", "password": "${keystone_demo_pass}"}}}}}

#no in white list tenant
${tenant_no_white_list}   lmm_canary
${keystone_wl_v3}      { "auth": { "scope": { "project": { "domain": {"name": "${Domain}"}, "name": "${tenant_no_white_list}" } }, "identity": { "methods": ["password"], "password": { "user": { "domain": {"name": "${Domain}"}, "name": "${username}", "password": "${keystone_pass}"}}}}}

#-----------------------------------------------------------------------
#additional data for keywords
${wrong_apikey}    c72a9818
${wrong_tenant}    3fee8132b
${email}          Frodolmm@gmail.com
${secondary_email}   Frodo2lmm@gmail.com
${password}       Welcome123_4
${fromEmail}     LMM@symantec.com

#-----------------------------------------------------------------------
#info on InfluxDB
${db_name}        lmm
${influx_pass}       root
${influx_user}       root
@{affix}            1min  5min  1hr  1s
#-----------------------------------------------------------------------
${email_recipients}     [{"type":"email","recipients":["Frodolmm@gmail.com"]},{"type":"callback","recipients":[]}]
${new_recipients}  [{"type":"email","recipients":["Frodo2lmm@gmail.com"]},{"type":"callback","recipients":[]}]
${callback}       [{"type":"email","recipients":["${email}"]},{"type":"callback","recipients":["http://${test_node}:8000/CTC-API-LW"]}]
${wrong_json}     [{"type":"sms","recipients":"+80951338536"}}]
${default_log_rules}      [{"delivery_groups":[{"use_default_delivery":true,"type":"email","name":"Delivery_groups1","template":"log-based alert #1","recipients":[]}],"name":"alert_log_based_rules1","condition":{"not":false,"field":"message","action":"match","value":"redbutton"}},{"delivery_groups":[{"use_default_delivery":true,"type":"email","name":"Delivery_groups2","template":"log-based alert #2","recipients":[]}],"name":"alert_log_based_rules2","condition":{"operation":"AND","conditions":[{"not":false,"field":"message","action":"=","value":"logTopic"},{"not":false,"field":"alt_message","action":"match","value":"alternative message"}]}}]
${default_metric_rules}    [{"delivery_groups":[{"use_default_delivery":true,"type":"email","name":"Delivery_groups4","template":"metric-based alert #2","recipients":[]}],"name":"alert_metric_based_rules2","condition":{"operation":"AND","conditions":[{"not":false,"field":"name","action":"match","value":"qa.cpu.test2"},{"not":true,"field":"value","action":"=","value":666}]}}]
${default_callback_rule1}    [{"delivery_groups":[{"use_default_delivery":true,"type":"email","name":"Delivery_groups1","template":"email, log-based alert #1","recipients":[]},{"use_default_delivery":true,"type":"callback","name":"Delivery_groups1","template":"{\\"callback\\":\\"log-based alert #1\\"}","recipients":[]}],"name":"alert_log_based_rules5","condition":{"operation":"AND","conditions":[{"not":false,"field":"message","action":"match","value":"log alert #1"},{"operation":"AND","conditions":[{"not":false,"field":"host_ip","action":"match","value":"1.1.1.1"},{"not":false,"field":"host_id","action":"match","value":"3b8a"}]}]}},{"delivery_groups":[{"use_default_delivery":true,"type":"email","name":"Delivery_groups2","template":"email, log-based alert #2","recipients":[]},{"use_default_delivery":true,"type":"callback","name":"Delivery_groups2","template":"{\\"callback\\":\\"log-based alert #2\\"}","recipients":[]}],"name":"alert_log_based_rules6","condition":{"operation":"AND","conditions":[{"not":false,"field":"message","action":"match","value":"callback"},{"not":false,"field":"alt_message","action":"match","value":"alternative message"}]}}]
${wrong_rule}     [{"short_template":""]
