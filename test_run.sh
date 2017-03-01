#!/bin/bash
#---    test_run.sh should be run from integration_test/src/ directory.
#---    Test reports will be saved to directory defined in --log,--report,--output parameters
#---    Each section is responsible for its part of functionality.
#---    Depending on what is under the testing not needed part of tests can be commented.
#---    Explanation of commands:
#---    -e - exclude tests with specified tags
#---    -i - include tests
#---    --log specify log file name (log.html is by default)


#---DO NOT FORGET TO CHANGE FILES
#   src/tests/micro_services/keywords/variables_settings.robot
#   src/tests/keywords/variables_keywords.robot

#---remove data from ES and apply filter
# pybot src/tests/Update_Searchguard_with_changed_tenant_status/clean_es_applyfilter.robot

#---remove tenants from tenant management
# pybot -v service_id:1 src/tests/s3_topology/remove_tenants.robot

#---create 3 tenants with unifiedsecurity business unit
# pybot -i ITC-S3-unifiedsecurity-tenants src/tests/s3_topology/whitelisted_ldap_groups.robot

#---send events for S3 merge topology
# pybot -v delay:0 -v message_num:2000 -v message_size:100 src/tests/s3_topology/messages_file_objects.robot

#---Validate searchguard deployment
# pybot src/tests/Update_Searchguard_with_changed_tenant_status/TM_LDAP_integration_with_SearchGuard.robot
# pybot src/tests/SearchGuard/