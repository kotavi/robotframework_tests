#Integration autotests run

##Precondition

* check the version for python (2.7), java (1.7.0_55), ubuntu (12.04)
* test environment must be prepared by installing additional python packages
####run script from *integration_test/scripts/env_preparation/* as a root

./pckg_py.sh

* go to *integration_test/src/keywords/variables_keywords.robot* and change parameters according to your test environment. 

Here is the list of possible variables to change:

	* ES_ip (IP of one of the elasticsearch nodes)
	* ES_port
	* db_host (IP/DNS name of the node with InfluxDB installed)
	* db_name (data base name in InfluxDB)
	* IP_web (logging_web IP)
	* Tenant (tenant name for tenant_id)
	* ${Domain
	* ${Tenant_domain}
	* ${Tenant}
	* ${username}
	* ${keystone_pass}
	* ${keystone_v3}
	* ${user_demo}
	* ${keystone_demo_pass}
	* ${Tenant_demo}
	* ${Domain_demo}
	* ${Tenant_domain_demo}
	* ${keystone_demo_v3}

##Script to run tests

cd integration_test/src/

./test_run.sh

##Commands to run tests

cd integration_test/src/tests/  (or you may run it from the HOME directory)

* Component tests

pybot --include ctc_smoke  integration_test/src/tests/

Results will be saved to the file log.html in the working directory

* Smoke integration tests:

pybot --log ITC_test_results.html --include runtime integration_test/src/tests/

Results will be saved to the file ITC_test_results.html in the working directory

* Excluding tests on specified tags 

pybot --exclude inprogress --exclude email --exclude logstash integration_test/src/tests/

####The next tags are used in the tests

* positive, negative

* runtime, critical

* ctc_smoke, smoke

* logstash

* multitenancy

* email

* inprogress

* LMM-<ticket_number>

* kafka_migration_TC, influx_migration_TC, zk_migration_TC, ui_migration_TC, es_migration_TC, redis_migration_TC, qs_migration_TC, ks_migration_TC, storm_migration_TC

If you want to check the environment run the next command:

pybot -i runtime .

#####Kafka component check
pybot integration_test/src/tests/CTC_Kafka.robot

#####Elasticsearch component check
pybot integration_test/src/tests/CTC_Elasticsearch.robot

#####InfluxDB component check
pybot integration_test/src/tests/CTC_InfluxDB.robot

#####REST API of logging web component check
pybot --exclude inprogress integration_test/src/tests/CTC_API_LW.robot

