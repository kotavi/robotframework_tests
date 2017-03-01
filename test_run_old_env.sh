#!/bin/bash
#---    test_run.sh should be run from integration_test/src/ directory.
#---    Test reports will be saved to directory defined in --log,--report,--output parameters
#---    Each section is responsible for its part of functionality.
#---    Depending on what is under the testing not needed part of tests can be commented.
#---    Explanation of commands:
#---    -e - exclude tests with specified tags
#---    -i - include tests
#---    --log specify log file name (log.html is by default)


#---DO NOT FORGET TO CHANGE variable_keyword.robot FILE


#To run component tests separately on each component
#pybot --log report/CTC_API_LW.html --report none --output report/CTC_API_LW.xml tests/CTC_API_LW.robot
#pybot --log report/CTC_Elasticsearch.html --report none --output report/CTC_Elasticsearch.xml tests/CTC_Elasticsearch.robot
#pybot --log report/CTC_InfluxDB.html --report none --output report/CTC_InfluxDB.xml tests/CTC_InfluxDB.robot
#pybot --log report/CTC_Kafka.html --report none --output report/CTC_Kafka.xml tests/CTC_Kafka.robot
#pybot --log report/CTC_Redis.html --report none --output report/CTC_Redis.xml tests/CTC_Redis.robot
#pybot --log report/CTC_Storm.html --report none --output report/CTC_Storm.xml tests/CTC_Storm.robot

#To run all component tests together
#pybot --log report/CTC.html --report none --output report/CTC.xml tests/CTC_*

#To run smoke tests
#pybot -i smoke -e inprogr* --log report/CTC_Smoke.html --report none --output report/CTC_Smoke.xml tests/

#To run Web-UI tests
#pybot -e inprogress --log report/Kibana_Grafana.html --report none --output report/Kibana_Grafana.xml tests/Kibana_Grafana/
#pybot --log report/CTC_API_LW.html --report none --output report/CTC_API_LW.xml tests/CTC_API_LW.robot
#pybot --log report/Query_API.html --report none --output report/Query_API.xml src/tests/Query_API.robot

#To run Web-UI tests together
#pybot -e inprogress --log report/web_ui.html --report none --output report/web_ui.xml src/tests/Kibana_Grafana/ src/tests/CTC_API_LW.robot src/tests/Query_API.robot

#Storm tests
#pybot -e inprogress -i storm_migration_TC --log report/Logs_field_validation.html --report none --output report/Logs_field_validation.xml tests/Logs_field_validation/
#pybot -e inprogress -i storm_migration_TC --log report/Metrics_field_validation.html --report none --output report/Metrics_field_validation.xml tests/Metrics_field_validation/
#pybot -e inprogress -i storm_migration_TC --log report/Storm_cache_invalidation.html --report none --output report/Storm_cache_invalidation.xml tests/Storm_cache_invalidation.robot
#pybot -e inprogress -i storm_migration_TC --log report/ITC_quota_deletion.html --report none --output report/ITC_quota_deletion.xml tests/ITC_quota_deletion.robot
#pybot -e inprogress -i storm_migration_TC --log report/Emails.html --report none --output report/Emails.xml tests/Alerts_flow/Emails_alert_topic.robot
#pybot -e inprogress -i storm_migration_TC --log report/Callback_alert_topic.html --report none --output report/Callback_alert_topic.xml tests/Alerts_flow/Callback_alert_topic.robot

#Critical tests
#pybot -i critical -e *Quota* -e inprogr* -e multitenancy -e *Callback* -e email --log report/CTC_Critical.html --report none --output report/CTC_Critical.xml tests/


#Fill in InfluxDB with metrics
#pybot -i load_influx_current -v metric_number:100 -v metric_name:qa_influx_test -v delay:1 src/Debug_steps/influxdb.robot

#Fill in ES with logs
#pybot -i load_es_current -v log_number:100 -v delay:1 src/Debug_steps/elasticsearch.robot

#Example of how to run tests in the loop
#for i in {1..3}; do pybot -e email src/tests/Alerts_flow/Callback_email_alert_topic.robot; done

#To run only tests for simple and log/metric-based alerts
#pybot -e *flood* -e *Callback* -e *time-alerts* src/tests/Alerts_flow/

#To run tests on Callbacks
#pybot -i *Callback* -e *flood* -e *time-alerts* src/tests/Alerts_flow/

#To run critical tests without QS
#pybot -e *Quota* src/tests/

#Sends logs each ~1 sec
#pybot -i ITC-email-flood-6.7 -v num:100000 src/tests/Alerts_flow/

#sends logs for testing callbacks
#pybot -i ITC-callback-flood-6.4a  -v num:100000 src/tests/Alerts_flow/
#pybot -i ITC-email-flood-6.12 -v num:100000 src/tests/Alerts_flow/
#pybot src/tests/Alerts_flow/metric_based_alerts.robot