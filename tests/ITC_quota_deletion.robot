*** Settings ***
Resource          keywords/variables_keywords.robot
Resource          keywords/log-based_keywords.robot
Resource          keywords/retention-policies_keywords.robot
Library           libs/ExtendDictionary.py
Library           libs/KafkaClient.py
Library           libs/ElasticSearchClient.py
Library           libs/RedisClient.py

Suite Setup       Run Keywords    Save master node IP  Quota service is running
#get credentials
Suite Setup       Run Keywords    Get data from keystone with '${keystone_v3}'
Suite Setup       Run Keywords    Get datetime   Get date and _index for Elasticsearch (Y.M.D)
Test Setup        Run Keywords    Drop InfluxDB database
Suite Teardown  Run Keywords      Delete all indices for current tenant
Test Setup  Run Keywords    Create body for es_request  Delete all indices for current tenant

*** Variables ***
${sec}   10

*** Test Cases ***
Fill in ES with data
    [Tags]    ITC-Quota-0   positive  qs_migration_TC
    ${old_index_1}  Get old index for tenant  ${ES_index}   50days
    ${old_index_2}  Get old index for tenant  ${ES_index}   45days
    ${old_index_3}  Get old index for tenant  ${ES_index}   39days
    ${old_index_4}  Get old index for tenant  ${ES_index}   35days
    ${old_index_5}  Get old index for tenant  ${ES_index}   37days
    ${delay}  Set Variable  ${0.001}
    : FOR  ${i}  IN RANGE  ${100}
    \    ${index}  Get old index for tenant  ${ES_index}   ${i}days
    \    ${res}   Send Bunch Of Messages    /${index}/logs/   count=${20}  size=10  body=${es_dict}  delay=${delay}
#    \    ${res}   Send Bunch Of Messages    /${old_index_1}/logs/   count=${20}  size=10  body=${es_dict}  delay=${delay}
#    \    ${res}   Send Bunch Of Messages    /${old_index_2}/logs/   count=${20}  size=10  body=${es_dict}  delay=${delay}
#    \    ${res}   Send Bunch Of Messages    /${old_index_3}/logs/   count=${20}  size=10  body=${es_dict}  delay=${delay}
#    \    ${res}   Send Bunch Of Messages    /${old_index_4}/logs/   count=${20}  size=10  body=${es_dict}  delay=${delay}
#    \    ${res}   Send Bunch Of Messages    /${old_index_5}/logs/   count=${20}  size=10  body=${es_dict}  delay=${delay}

Indexes with wrong name are deleted by QS
    [Documentation]  Indexes with wrong names are created and QS should delete them
    [Tags]    ITC-Quota-1.1  positive  storm_migration_TC   qs_migration_TC
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  100  1  GB  TIME_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    ${index1}   Set Variable   wrong-quota-name_${tenant_id}_1
    ${index2}   Set Variable   wrong-quota-name_${tenant_id}_2
    Send Bunch Of Messages  /${index1}/logs/  count=${2}  size=1  body=${es_dict}  delay=${0.1}
    Send Bunch Of Messages  /${index2}/logs/  count=${2}  size=1  body=${es_dict}  delay=${0.1}
    Sleep  ${sec}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Contain  ${indices}  ${index1}
    Should Contain  ${indices}  ${index2}
    Send cleanup request to QS
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Not Contain  ${indices}  ${index1}
    Should Not Contain  ${indices}  ${index2}

Indexes with prefixes kibana and grafana will be skipped by QS
    [Documentation]  Created indexes with prefixes kibana-${tenant_id} and grafana-${tenant_id} should not be deleted by QS
    [Tags]    ITC-Quota-1.2  positive  qs_migration_TC
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  100  1  GB  SIZE_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    ${index1}   Set Variable   kibana-${tenant_id}_1
    ${index2}   Set Variable   grafana-${tenant_id}_1
    Send Bunch Of Messages  /${index1}/logs/  count=${2}  size=1  body=${es_dict}
    Log To Console  ${es_dict}
    Send Bunch Of Messages  /${index2}/logs/  count=${2}  size=1  body=${es_dict}
    Log To Console  ${es_dict}
    Sleep  ${sec}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Contain  ${indices}  ${index1}
    Should Contain  ${indices}  ${index2}
    Send cleanup request to QS
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Contain  ${indices}  ${index1}
    Should Contain  ${indices}  ${index2}

With time based policy QS deletes one old index
    [Tags]    ITC-Quota-1.3   positive  qs_migration_TC
    ${threshold}  Create json for QS in Redis   ${tenant_id}  32  100  100  MB  TIME_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    Sleep   ${qs_sleep_time}
    ${old_index}  Get old index for tenant  ${ES_index}   40days
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${20}  size=10  body=${es_dict}  delay=${0.1}
    ${res}   Send Bunch Of Messages    /${ES_index}/logs/   count=${5}  body=${es_dict}  delay=${0.1}
    Sleep  ${sec}
    Send cleanup request to QS
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Not Contain  ${indices}  ${old_index}
    Should Contain  ${indices}  ${ES_index}

With time based policy QS deletes two old indexes
    [Tags]    ITC-Quota-1.3a   positive  qs_migration_TC
    ${threshold}  Create json for QS in Redis   ${tenant_id}  36  100  100  MB  TIME_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    Sleep   ${qs_sleep_time}
    ${old_index_1}  Get old index for tenant  ${ES_index}   50days
    ${old_index_2}  Get old index for tenant  ${ES_index}   45days
    ${res}   Send Bunch Of Messages    /${old_index_1}/logs/   count=${20}  size=10  body=${es_dict}  delay=${0.1}
    ${res}   Send Bunch Of Messages    /${old_index_2}/logs/   count=${10}  size=10  body=${es_dict}  delay=${0.1}
    ${res}   Send Bunch Of Messages    /${ES_index}/logs/   count=${5}  body=${es_dict}  delay=${0.1}
    Sleep  ${sec}
    Send cleanup request to QS
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Not Contain  ${indices}  ${old_index_1}
    Should Not Contain  ${indices}  ${old_index_2}
    Should Contain  ${indices}  ${ES_index}

QS works when there are 200 wrong indexes in ES
    [Documentation]  In ES we have: 200 of wrongly named indexes, one index with current date, one undex with date 40 days ago
    [Documentation]  As a result of QS only index with current date should not be deleted
    [Tags]    ITC-Quota-1.3b   positive  qs_migration_TC
#    [Arguments]  ${tenant_id}  ${days}  ${percent}  ${ind_size}  ${unit}
    ${threshold}  Create json for QS in Redis   ${tenant_id}  32  100  1  GB  TIME_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    Sleep   ${qs_sleep_time}
    ${old_index}  Get old index for tenant  ${ES_index}   40days
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${20}  size=1  body=${es_dict}  delay=${0.1}
    ${res}   Send Bunch Of Messages    /${ES_index}/logs/   body=${es_dict}  delay=${0.1}
    : FOR  ${day}  IN RANGE  ${200}
    \     ${template}    Generate Random String   17   [LOWER]
    \     ${id}   Send Bunch Of Messages    /${template}/logs/   body=${es_dict}  delay=${0.01}
    \     Log To Console   ${day}: Sent ${template} to ES
    Sleep  ${sec}
    Send cleanup request to QS
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Not Contain  ${indices}  ${old_index}
    Should Contain  ${indices}  ${ES_index}

QS works when there are more then 200 of users' and wrong indexes in ES
    [Documentation]  In ES we have: 100 of wrongly named indexes, 100 of users' old indexes
    [Documentation]  As a result of QS all indexes should be deleted
    [Tags]    ITC-Quota-1.4   positive  qs_migration_TC
    ${threshold}  Create json for QS in Redis   ${tenant_id}  32  100  1  GB  TIME_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    Sleep   ${qs_sleep_time}
    ${index}  Get old index for tenant  ${ES_index}   40days
    ${res}   Send Bunch Of Messages    /${index}/logs/   count=${10}  size=10  body=${es_dict}  delay=${0.1}
    : FOR  ${day}  IN RANGE  ${200}
    \     ${template}    Generate Random String   17   [LOWER]
    \     ${res}   Send Bunch Of Messages    /${template}/logs/  count=${10}  body=${es_dict}  delay=${0.01}
    \     Log To Console    ${day}: Sent ${template} to ES
    \     Sleep  ${1}
    : FOR  ${day}  IN RANGE  ${200}
    \     ${old_index}  Get old index for tenant  ${ES_index}   ${day+10}days
    \     ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${10}  body=${es_dict}  delay=${0.01}
    \     Log To Console    ${day}: Sent ${old_index} to ES
    \     Sleep  ${1}
    Sleep  ${sec}
    Send cleanup request to QS
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Not Contain  ${indices}  ${index}

QS works when there are more then 50 of users and 100 of wrong indexes in ES
    [Tags]    ITC-Quota-1.4a   positive  qs_migration_TC
    #    [Arguments]  ${tenant_id}  ${days}  ${percent}  ${ind_size}  ${unit}
    ${threshold}  Create json for QS in Redis   ${tenant_id}  32  100  1  GB  TIME_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    Sleep   ${qs_sleep_time}
    ${index}  Get old index for tenant  ${ES_index}   40days
    ${res}   Send Bunch Of Messages    /${index}/logs/   count=${1000}  size=10  body=${es_dict}  delay=${0.01}
    : FOR  ${day}  IN RANGE  ${100}
    \     ${template}    Generate Random String   17   [LOWER]
    \     ${res}   Send Bunch Of Messages    /${template}/logs/  count=${100}  body=${es_dict}  delay=${0.001}
    \     Log To Console    ${day}: Sent ${template} to ES
    : FOR  ${day}  IN RANGE  ${50}
    \     ${old_index}  Get old index for tenant  ${ES_index}   ${day+10}days
    \     ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${100}  size=10  body=${es_dict}  delay=${0.001}
    \     Log To Console    ${day}: Sent ${old_index} to ES
    Sleep  ${sec}
    Send cleanup request to QS
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Not Contain  ${indices}  ${index}

Indexes from 2d/3d ago deleted from ES (quota on 1 day)
    [Tags]    ITC-Quota-1.5  storm_migration_TC   qs_migration_TC  positive
    #    [Arguments]  ${tenant_id}  ${days}  ${percent}  ${ind_size}  ${unit}
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  80  151  KB  TIME_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    ${old_index}  Get old index for tenant  ${ES_index}   2days
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${5}  size=2  body=${es_dict}  delay=${0.1}
    ${oldest_index}  Get old index for tenant  ${ES_index}   3days
    ${res}   Send Bunch Of Messages    /${oldest_index}/logs/   count=${30}  size=15  body=${es_dict}  delay=${0.1}
    Sleep  ${sec}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${old_size}  Get ES Index Size  ${old_index}
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    Log To Console  \n OLD SIZE = ${old_size}; \n OLDEST SIZE = ${oldest_size}
    Send cleanup request to QS
    ${test}  Get Es Indices Size For Tenant   ${tenant_id}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Not Contain  ${indices}  ${old_index}
    Should Not Contain  ${indices}  ${oldest_index}

Current index is not deleted for TIME_BASED retention policy
    [Tags]    ITC-Quota-1.6  storm_migration_TC   qs_migration_TC  positive
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  80  17  MB  TIME_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    ${res}   Send Bunch Of Messages    /${ES_index}/logs/   count=${15}  size=2  body=${es_dict}  delay=${0.1}
    ${old_index}  Get old index for tenant  ${ES_index}   2days
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${5}  size=2  body=${es_dict}  delay=${0.1}
    ${oldest_index}  Get old index for tenant  ${ES_index}   3days
    ${res}   Send Bunch Of Messages    /${oldest_index}/logs/   count=${30}  size=15  body=${es_dict}  delay=${0.1}
    Sleep   ${qs_sleep_time}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${current_size}  Get ES Index Size  ${ES_index}
    ${old_size}  Get ES Index Size  ${old_index}
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    Log To Console  \n OLD SIZE = ${old_size}; \n OLDEST SIZE = ${oldest_size}; \n CURRENT_SIZE = ${current_size}
    Send cleanup request to QS
    Sleep  ${sec}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \n TOTAL SIZE = ${total_size}
    #-------------------------------------------------------------------
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  \n Left indexes after QS, indices = ${indices}
    Should Contain  ${indices}  ${ES_index}
    Should Not Contain  ${indices}  ${old_index}
    Should Not Contain  ${indices}  ${oldest_index}

The quota service retains the last index that violates the tenant policy (2 old indexes, 100%,150kb)
    [Tags]    ITC-Quota-2.1  qs_migration_TC  storm_migration_TC   positive
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  100  152  KB  SIZE_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    ${allowed_size}=  Evaluate  100*150*1024/100
    Log To Console   ${allowed_size} of bytes
    Log  ${res}
    Log To Console  ${res}
    #------------------------------------------------------------------------------
    Sleep  ${sec}
    ${old_index}  Get old index for tenant  ${ES_index}   2days
    ${oldest_index}  Get old index for tenant  ${ES_index}   3days
    ${res}   Send Bunch Of Messages    /${oldest_index}/logs/   count=${25}   size=10  body=${es_dict}  delay=${0.1}
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${5}   size=5  body=${es_dict}  delay=${0.1}
    Sleep   10
    ${old_size}  Get ES Index Size  ${old_index}
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    Log To Console  \n OLD SIZE = ${old_size}; \n OLDEST SIZE = ${oldest_size}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \n TOTAL SIZE = ${total_size}
    Send cleanup request to QS
    Sleep  ${sec}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  \n ${indices}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \n TOTAL SIZE = ${total_size}
    Log To Console  \n Left indexes after QS, indices = ${indices}
    Should Contain  ${indices}  ${old_index}
    Should Contain  ${indices}  ${oldest_index}

Current index violates the tenant policy so the old indexes are deleted (100%,150kb)
    [Tags]    ITC-Quota-2.1a  qs_migration_TC  storm_migration_TC   positive
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  100  153  KB  SIZE_BASED
    ${allowed_size}=  Evaluate  100*150*1024/100
    Log To Console   ${allowed_size} of bytes
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    Sleep   ${qs_sleep_time}
    ${res}   Send Bunch Of Messages    /${ES_index}/logs/   count=${25}   size=10  body=${es_dict}  delay=${0.1}
    ${old_index}  Get old index for tenant  ${ES_index}   2days
    ${oldest_index}  Get old index for tenant  ${ES_index}   3days
    ${res}   Send Bunch Of Messages    /${oldest_index}/logs/   count=${25}   size=10  body=${es_dict}  delay=${0.1}
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${5}   size=10  body=${es_dict}  delay=${0.1}
    Sleep   10
    ${current_size}  Get ES Index Size  ${ES_index}
    ${old_size}  Get ES Index Size  ${old_index}
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    Log To Console  \n CURRENT SIZE = ${current_size}; \n OLD SIZE = ${old_size}; \n OLDEST SIZE = ${oldest_size}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    Send cleanup request to QS
    Sleep  10
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Contain  ${indices}  ${ES_index}
    #because current index already violates the policy
    Should Not Contain  ${indices}  ${old_index}
    Should Not Contain  ${indices}  ${oldest_index}
    #------------------------------------------------------------------------------
    Check index information for '${ES_index}' with '${25}' of logs


Current index violates the tenant policy so the old indexes are deleted (90%,150kb)
    [Tags]    ITC-Quota-2.1c  qs_migration_TC  storm_migration_TC   positive
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  90  154  KB  SIZE_BASED
    ${allowed_size}=  Evaluate  100*150*1024/100
    Log To Console   ${allowed_size} of bytes
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    Sleep   ${qs_sleep_time}
    ${res}   Send Bunch Of Messages    /${ES_index}/logs/   count=${26}   size=10  body=${es_dict}  delay=${0.1}
    ${old_index}  Get old index for tenant  ${ES_index}   2days
    ${oldest_index}  Get old index for tenant  ${ES_index}   3days
    ${res}   Send Bunch Of Messages    /${oldest_index}/logs/   count=${25}   size=10  body=${es_dict}  delay=${0.1}
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${30}   size=15  body=${es_dict}  delay=${0.1}
    Sleep   10
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    ${old_size}  Get ES Index Size  ${old_index}
    ${current_size}  Get ES Index Size  ${ES_index}
    Log To Console  \n CURRENT SIZE = ${current_size}; \n OLD SIZE = ${old_size}; \n OLDEST SIZE = ${oldest_size}

    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  ${indices}
    Send cleanup request to QS
    Sleep  10
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Contain  ${indices}  ${ES_index}
    #because current index already violates the policy
    Should Not Contain  ${indices}  ${old_index}
    Should Not Contain  ${indices}  ${oldest_index}
    #-----------------------------------------------------------------------------
    Check index information for '${ES_index}' with '26' of logs

Current index doesn't violate the policy so the first old indexes tht violates the policy is not deleted
    [Tags]    ITC-Quota-2.1d  qs_migration_TC  storm_migration_TC   positive
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  100  155  KB  SIZE_BASED
    ${allowed_size}=  Evaluate  100*150*1024/100
    Log To Console   ${allowed_size} of bytes
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    Sleep   ${qs_sleep_time}
    ${res}   Send Bunch Of Messages    /${ES_index}/logs/   count=${2}   size=1  body=${es_dict}  delay=${0.1}
    ${old_index}  Get old index for tenant  ${ES_index}   2days
    ${oldest_index}  Get old index for tenant  ${ES_index}   3days
    ${res}   Send Bunch Of Messages    /${oldest_index}/logs/   count=${25}   size=10  body=${es_dict}  delay=${0.1}
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${30}   size=15  body=${es_dict}  delay=${0.1}
    Sleep   10
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    ${current_size}  Get ES Index Size  ${ES_index}
    ${old_size}  Get ES Index Size  ${old_index}
    Log To Console  \n CURRENT SIZE = ${current_size}; \n OLD SIZE = ${old_size}; \n OLDEST SIZE = ${oldest_size}
    Send cleanup request to QS
    Sleep  10
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Should Contain  ${indices}  ${ES_index}
    #because current index doesn't violate the policy
    Should Contain  ${indices}  ${old_index}
    Should Not Contain  ${indices}  ${oldest_index}
    #-----------------------------------------------------------------------------
    Check index information for '${ES_index}' with '2' of logs

The first index that violates the policy is retained (80%,10kb)
    [Tags]    ITC-Quota-2.2    positive  qs_migration_TC  storm_migration_TC
    ${threshold}  Create json for QS in Redis   ${tenant_id}  50  80  10  KB  SIZE_BASED
    ${allowed_size}=  Evaluate  80*10*1024/100
    Log To Console   ${allowed_size} of bytes
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    Sleep   ${qs_sleep_time}
    ${old_index}  Get old index for tenant  ${ES_index}   3days
    ${oldest_index}  Get old index for tenant  ${ES_index}   20days
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${5}   size=10  body=${es_dict}  delay=${0.1}
    ${res}   Send Bunch Of Messages    /${oldest_index}/logs/   count=${5}   size=10  body=${es_dict}  delay=${0.1}
    Sleep  10
    ${old_size}  Get ES Index Size  ${old_index}
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    Log To Console  \n OLDEST SIZE = ${oldest_size}; \n OLD SIZE = ${old_size}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Send cleanup request to QS
    Sleep  10
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  Left indexes after QS, indices = ${indices}
    Should Contain  ${indices}  ${old_index}
    Should Not Contain  ${indices}  ${oldest_index}

Current index is not deleted when it exceeded the quota (80%, 1 MB)
    [Tags]    ITC-Quota-2.3  positive   qs_migration_TC  storm_migration_TC
#    [Arguments]  ${tenant_id}  ${days}  ${percent}  ${ind_size}  ${unit}
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  80  1  MB  SIZE_BASED
    ${allowed_size}=  Evaluate  80*1024*1024/100
    Log To Console   ${allowed_size} of bytes
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
    Sleep   ${qs_sleep_time}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${20}  size=20  body=${es_dict}  delay=${0.00001}
    ${old_index}  Get old index for tenant  ${ES_index}   20days
    ${res}   Send Bunch Of Messages   /${old_index}/logs/   count=${7}   size=1  body=${es_dict}  delay=${0.00001}
    ${oldest_index}  Get old index for tenant  ${ES_index}   45days
    ${res}   Send Bunch Of Messages    /${oldest_index}/logs/   count=${10}   size=10  body=${es_dict}  delay=${0.00001}
    Sleep  15
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \n TOTAL SIZE = ${total_size}
    ${current_size}   Get ES Index Size  ${ES_index}
    ${old_size}  Get ES Index Size  ${old_index}
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    Log To Console  \n CURRENT SIZE = ${current_size}; \n OLD SIZE = ${old_size}; \n OLDEST SIZE = ${oldest_size};
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Send cleanup request to QS
    Sleep  10
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  LEFT INDICES = ${indices}
    Should Contain  ${indices}  ${ES_index}
    #because current index already violates the policy
    Should Not Contain  ${indices}  ${old_index}
    Should Not Contain  ${indices}  ${oldest_index}
    #-----------------------------------------------------------------------------
    Check index information for '${ES_index}' with '20' of logs

Left indexes by size_based are not deleted if their total size < 80% of 100kb
    [Tags]    ITC-Quota-2.4   positive  qs_migration_TC
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  80  100  KB  SIZE_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${allowed_size}=  Evaluate  80*100*1024/100
    Log To Console   ALLOWED SIZE = ${allowed_size} of bytes
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
#    Create retention policy for tenant  ${tenant_id}  index_retention_size=100   policy_type=SIZE_BASED
    Sleep   ${qs_sleep_time}
    : FOR  ${day}  IN RANGE  ${10}
    \    ${old_index}  Get old index for tenant  ${ES_index}  ${day}days
    \     Send Bunch Of Messages  /${old_index}/logs/  count=${2}  size=4  body=${es_dict}  delay=${0.00001}
    \     ${ind}  Get ES Index Size  ${old_index}
    Sleep  10
    : FOR  ${day}  IN RANGE  ${10}
    \    ${old_index}  Get old index for tenant  ${ES_index}  ${day}days
    \    ${ind}  Get ES Index Size  ${old_index}
    \    Log To Console  \n ${old_index} = ${ind}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \n TOTAL SIZE = ${total_size}
    Send cleanup request to QS
    Sleep  10
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \n TOTAL SIZE after QS = ${total_size}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  \n Left indexes after QS, indices = ${indices}
    Length Should Be  ${indices}  3

Indexes are deleted if their total size > 30% of 1mb
    [Tags]    ITC-Quota-2.5   positive  qs_migration_TC
#    [Arguments]  ${tenant_id}  ${days}  ${percent}  ${ind_size}  ${unit}
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  30  1  MB  SIZE_BASED
    ${allowed_size}=  Evaluate  30*1024*1024/100
    Log To Console   ALLOWED SIZE = ${allowed_size} of bytes
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
#    Create retention policy for tenant  ${tenant_id}  index_retention_size_units=mb   index_retention_size=1    percentage_to_retain=30   policy_type=SIZE_BASED
    Sleep   ${qs_sleep_time}
    ${current_index_number}   Send Bunch Of Messages   /${ES_index}/logs/  count=${150}   size=1  body=${es_dict}  delay=${0.1}
    ${oldest_index}  Get old index for tenant  ${ES_index}   45days
    ${res}   Send Bunch Of Messages    /${oldest_index}/logs/   count=${200}   size=1  body=${es_dict}  delay=${0.1}
    ${old_index}  Get old index for tenant  ${ES_index}   20days
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${900}   size=1  body=${es_dict}  delay=${0.1}
    Sleep  10
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${current_size}   Get ES Index Size  ${ES_index}
    ${old_size}  Get ES Index Size  ${old_index}
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    Log To Console  CURRENT SIZE = ${current_size}; OLD SIZE = ${old_size}; OLDEST SIZE = ${oldest_size}
    Send cleanup request to QS
    Sleep  10
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \nTOTAL SIZE after QS = ${total_size}
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  Left indexes after QS, indices = ${indices}
    Should Contain   ${indices}   ${ES_index}
    Should Contain  ${indices}  ${old_index}
    Should Not Contain  ${indices}  ${oldest_index}
    #-----------------------------------------------------------------------------
    Check index information for '${ES_index}' with '150' of logs

Old indexes for two days are not deleted if their total size < 30% of 300kb
    [Tags]    ITC-Quota-2.6   positive  qs_migration_TC
#    [Arguments]  ${tenant_id}  ${days}  ${percent}  ${ind_size}  ${unit}
    ${threshold}  Create json for QS in Redis   ${tenant_id}  1  10  300  KB  SIZE_BASED
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    ${allowed_size}=  Evaluate  10*300*1024/100
    Log To Console   ALLOWED SIZE = ${allowed_size} of bytes
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
#    Create retention policy for tenant  ${tenant_id}   index_retention_size=300    percentage_to_retain=10   policy_type=SIZE_BASED
    Sleep   ${qs_sleep_time}
    ${old_index}  Get old index for tenant  ${ES_index}   4days
    ${res}   Send Bunch Of Messages    /${old_index}/logs/   count=${20}   size=1  body=${es_dict}  delay=${0.1}
    ${older_index}  Get old index for tenant  ${ES_index}   5days
    ${res}   Send Bunch Of Messages    /${older_index}/logs/   count=${20}   size=1  body=${es_dict}  delay=${0.1}
    ${oldest_index}  Get old index for tenant  ${ES_index}   20days
    ${res}   Send Bunch Of Messages    /${oldest_index}/logs/   count=${250}   size=1  body=${es_dict}  delay=${0.1}
    Sleep  10
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  TOTAL SIZE = ${total_size}
    ${old_size}   Get ES Index Size  ${old_index}
    ${older_size}  Get ES Index Size  ${older_index}
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    Log To Console  OLD SIZE = ${old_size}; OLDER SIZE = ${older_size}; OLDEST SIZE = ${oldest_size}
    Send cleanup request to QS
    Sleep  10
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  Left indexes after QS, indices = ${indices}
    Should Contain   ${indices}   ${old_index}
    #because old_index already violates the policy
    Should Not Contain   ${indices}   ${older_index}
    Should Not Contain  ${indices}  ${oldest_index}

Old and current indexes are not deleted with policy 1month
    [Tags]    ITC-Quota-3.1   positive  qs_migration_TC
#    [Arguments]  ${tenant_id}  ${days}  ${percent}  ${ind_size}  ${unit}
    ${threshold}  Create json for QS in Redis   ${tenant_id}  32  80  1  KB  SIZE_BASED
    ${allowed_size}=  Evaluate  80*1*1024/100
    Log To Console   ALLOWED SIZE = ${allowed_size} of bytes
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
#    Create retention policy for tenant  ${tenant_id}   index_retention_days=32
    Sleep   ${qs_sleep_time}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${200}  size=1  body=${es_dict}  delay=${0.1}
    ${old_index}   Get old index for tenant  ${ES_index}   31days
    Send Bunch Of Messages  /${old_index}/logs/  count=${10}  size=3  body=${es_dict}  delay=${0.1}
    ${oldest_index}  Get old index for tenant  ${ES_index}   33days
    Send Bunch Of Messages  /${oldest_index}/logs/  count=${100}  size=4  body=${es_dict}  delay=${0.1}
    Sleep  10
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  \nCreated indexes, indices = ${indices}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \nTOTAL SIZE = ${total_size}
    ${current_size}  Get ES Index Size  ${ES_index}
    ${old_size}  Get ES Index Size  ${old_index}
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    Log To Console  \nCURRENT SIZE = ${current_size}; OLD SIZE = ${old_size}; OLDEST SIZE = ${oldest_size}
    Send cleanup request to QS
    Sleep  10
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  \nLeft indexes, indices = ${indices}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \nTOTAL SIZE = ${total_size}
    Should Contain   ${indices}   ${ES_index}
    Should Not Contain   ${indices}   ${old_index}
    Should Not Contain  ${indices}  ${oldest_index}
    #-----------------------------------------------------------------------------
    Check index information for '${ES_index}' with '200' of logs

Parameter with % doesn't influence the data, so it's not deleted
    [Tags]    ITC-Quota-3.2   positive  qs_migration_TC
#    [Arguments]  ${tenant_id}  ${days}  ${percent}  ${ind_size}  ${unit}
    ${threshold}  Create json for QS in Redis   ${tenant_id}  63  0  1  KB  SIZE_BASED
    ${allowed_size}=  Evaluate  0*1*1024/100
    Log To Console   ALLOWED SIZE = ${allowed_size} of bytes
    ${result}  Set Throttle Threshold   ${master_redis}   tenant_policies_${tenant_id}  ${threshold}
    ${res}  Get Data From Redis By Key  tenant_policies_${tenant_id}
    Log  ${res}
    Log To Console  ${res}
    #-----------------------------------------------------------------------------
#    Create retention policy for tenant  ${tenant_id}   index_retention_days=63   percentage_to_retain=0
    Sleep   ${qs_sleep_time}
    Send Bunch Of Messages  /${ES_index}/logs/  count=${20}  size=2  body=${es_dict}  delay=${0.1}
    ${old_index}   Get old index for tenant  ${ES_index}   62days
    Send Bunch Of Messages  /${old_index}/logs/  count=${10}  size=3  body=${es_dict}  delay=${0.1}
    ${oldest_index}  Get old index for tenant  ${ES_index}   300days
    Send Bunch Of Messages  /${oldest_index}/logs/  count=${23}  size=4  body=${es_dict}  delay=${0.1}
    Sleep   10
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  \nCreated indexes, indices = ${indices}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \nTOTAL SIZE = ${total_size}
    ${current_size}  Get ES Index Size  ${ES_index}
    ${old_size}  Get ES Index Size  ${old_index}
    ${oldest_size}  Get ES Index Size  ${oldest_index}
    Log To Console   \n${ES_index}: ${current_size} \n ${old_index}: ${old_size} \n ${oldest_index}: ${oldest_size}
    Send cleanup request to QS
    Sleep  10
    ${indices}  Get Indices For Tenant  ${tenant_id}
    Log To Console  \nLeft indexes, indices = ${indices}
    ${total_size}  Get Es Indices Size For Tenant   ${tenant_id}
    Log To Console  \nTOTAL SIZE = ${total_size}
    Should Contain   ${indices}   ${ES_index}
    Should Not Contain   ${indices}   ${old_index}
    Should Not Contain  ${indices}  ${oldest_index}
    #-----------------------------------------------------------------------------
    Check index information for '${ES_index}' with '20' of logs

#QS metrics are saved for two indexes

*** Keywords ***
Save master node IP
    ${redis_cluster}   Create List  @{redis_cluster}
    ${count}  Get Length  ${redis_cluster}
    : FOR   ${i}   IN RANGE   ${count}
    \    ${res}  Get Redis Server Info   ${redis_cluster[${i}]}
    \    Run Keyword If  '${res['role']}' == 'slave'  Set Global Variable  ${master_redis}  ${res['master_host']}
    [Return]  ${master_redis}

Create json for QS in Redis  [Arguments]  ${tenant_id}  ${days}  ${percent}  ${ind_size}  ${unit}   ${policy_type}
    ${json}  Set Variable  {"tenantId":"${tenant_id}","eventThreshold":"10000","windowInterval":1,"index_retention_days":"${days}","percentage_to_retain":"${percent}","index_retention_size":${ind_size},"index_retention_size_units":"${unit}","policy_action":"DELETE","policy_type":"${policy_type}"}
    [Return]  ${json}

Remove QS configuration for ${tenant}
    ${res}  Delete Throttle Threshold   ${master_redis}  tenant_policies_${tenant}

Index '${ind}' doesn't exist in ES
    ${res_bool}  Check Index Exists    /${ind}
    ${res_str}  Convert To String    ${res_bool}
    Should Be Equal As Strings  ${res_str}   False

Index '${ind}' exists in ES
    ${res_bool}  Check Index Exists    /${ind}
    ${res_str}  Convert To String    ${res_bool}
    Should Be Equal As Strings  ${res_str}   True

Set new retention policy '${data}' to redis with '${tenantid}'
    #Delete tenant policy from redis for '${tenantid}'
    ${res}  Set Data To Redis  tenant_policies_${tenantid}  ${data}
    Should Be Equal As Strings  ${res}  True
    ${res}  Verify Data In Redis Exists  tenant_policies_${tenantid}
    Should Be Equal As Strings  ${res}  True
    ${res}  Get Data From Redis By Key  tenant_policies_${tenantid}
    Log   ${res}
    Log To Console    tenant_policies_${tenantid} = ${res}

Quota service is running
    Set Global Variable    ${url}    http://${qs_ip}:8082/healthcheck
    Set Global Variable    ${method}    GET
    GET Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    Should Be Equal As Strings  ${response_body['elasticSearch']['healthy']}  True
    Should Be Equal As Strings  ${response_body['redis']['healthy']}  True
    Should Be Equal As Strings  ${response_body['deadlocks']['healthy']}  True

Send cleanup request to QS
    Set Global Variable    ${url}    http://${qs_ip}:${qs_port}/cleanup
    Set Global Variable    ${method}    POST
    POST Request    ${url}

Collect metrics to InfluxDB
    Set Global Variable    ${url}    http://${qs_ip}:${qs_port}/es
    Set Global Variable    ${method}    POST
    POST Request    ${url}

Check index information for '${index}' with '${num}' of logs
    Sleep  30
    Collect metrics to InfluxDB
    Sleep  5
    ${search_req}    Set variable    SELECT documentCount FROM /esMetric_${tenant_id}/
    ${result}  Querying Data From Influx  esMetric_${tenant_id}  ${search_req}
    Log To Console  ${result}
    ${result}  Convert To String   ${result}
    Should Contain  ${result}  ResultSet({'(u'esMetric_${tenant_id}', None)': [{u'documentCount': ${num}, u'time':
    ${search_req}    Set variable    SELECT indexSize FROM /esMetric_${tenant_id}/
    ${result}  Querying Data From Influx  esMetric_${tenant_id}  ${search_req}
    Log To Console  ${result}
    ${result}  Convert To String   ${result}
    ${current_size}  Get ES Index Size  ${index}
    Should Contain  ${result}  ResultSet({'(u'esMetric_${tenant_id}', None)': [{u'indexSize': ${current_size}, u'time':

Drop InfluxDB database
    Delete Influx Database  esMetric_${tenant_id}
    Sleep  2

Create body for es_request
    ${es_dict}   Create Dictionary     apikey=${apikey}  tenant_id=${tenant_id}  @timestamp=${@timestamp}
    Set Global Variable  ${es_dict}  ${es_dict}

Delete all indices for current tenant
      Delete All Indices For Tenant  ${tenant_id}
      Sleep  5

Get number of logs for index '${index}'
    Set Global Variable    ${url}    http://${es_cluster[0]}:${ES_port}/_cat/count/${index}
    Set Global Variable    ${method}    GET
    GET Request    ${url}
    The response code should be 200
    ${response_body}    Get Response Body
    ${string}  Split Returned Value  ${response_body}
    ${res}  Convert To Integer  ${string[2]}
    [Return]   ${res}

Send messages to ES with serchguard  [Arguments]   ${index_num}
    : FOR  ${i}  IN RANGE  ${index_num}
    \    ${index}  Get old index for tenant  ${ES_index}   ${i}days
    \    ${message}    Generate Random String   17   [LOWER]
    \    ${body}  Set Variable  {"apikey":"${apikey}","tenant_id":"${tenant_id}","message":"${message}","@timestamp":"${@timestamp}","some_int":8}
    \    Execute POST request to '${es_url}/${index}/logs' with credentials user='${sudo_user}' pass='${sudo_pass}' with '${body}'
    \    The response code should be 201
