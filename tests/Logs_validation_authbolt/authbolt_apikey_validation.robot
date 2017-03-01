*** Settings ***
Resource        authbolt_validation_keywords.robot

Suite Setup   Run Keywords  Create dictionary with roles  Create dictionary with services  Create dictionary with ldap_groups
Suite Setup   Run Keywords  Create global tenant and apikey

Test Teardown  Run Keywords   Clear index in elasticsearch

Suite Setup  Run Keywords   Get date and _index for Elasticsearch (Y.M.D)
Test Setup  Run Keywords   Get datetime
Suite Teardown  Run Keywords   Clear index in elasticsearch  Delete tenant '${tenant_id_global}'

*** Variables ***


*** Test Cases ***
TC.1.1. Send event with correct credentials and retreive it from ES
    [Tags]  ITC-authbolt-1.1  positive
    ${tag}  set variable  ITC-authbolt-1.1
    Log To Console  tenant_id = ${tenant_id_global}; apikey = ${apikey_global}
    Get date and _index for Elasticsearch (Y.M.D)
    #---send data to kafka
    : FOR  ${i}  IN RANGE  ${5}
    \   ${message}    Generate Random String   11  [LETTERS]
    \   Get datetime
    \   ${kafka_dict}  Create Dictionary  apikey=${apikey_global}  tenant_id=${tenant_id_global}  message=${tag} ${message}  @timestamp=${@timestamp}
    \   Send Message To Kafka    ${log_topic}    ${kafka_dict}
    \   Log To Console   ${kafka_dict}
    Sleep  ${delay}
    #---check ES
    ${message}  Get Message From Es By Body  /logs-${tenant_id_global}-${Y.M.D}/logs/   ${tag} ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    5

TC.1.2. Event with wrong apikey is rejected by topology
    [Tags]  ITC-authbolt-1.2  negative
    ${tag}  set variable  ITC-authbolt-1.2
    Log To Console  tenant_id = ${tenant_id_global}; apikey = ${apikey_global}
    Get date and _index for Elasticsearch (Y.M.D)
    #---send data to kafka
    ${message}    Generate Random String   17  [LOWER]
    ${wrong_apikey}    Generate Random String   11  [LOWER]
    ${kafka_dict}  Create Dictionary  apikey=${wrong_apikey}  tenant_id=${tenant_id_global}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    Log To Console   ${kafka_dict}
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id_global}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${message}
    #-------------------------------------------------------------------------
    ${res_bool}  Check Index Exists    /logs-${tenant_id_global}-${Y.M.D}
    should not be true  ${res_bool}

TC.1.3. Event with deleted apikey is rejected by topology
    [Documentation]  Send event when apikey was deleted
    [Tags]  ITC-authbolt-1.3  negative
    ${tag}  set variable  ITC-authbolt-1.3
    ${tenant_id}  ${apikey}   Create tenant
    Log To Console  tenant_id = ${tenant_id}; apikey = ${apikey}
    Get date and _index for Elasticsearch (Y.M.D)
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    Log To Console   ${kafka_dict}
    #---check ES
    ${message}  Get Message From Es By Body  /logs-${tenant_id_global}-${Y.M.D}/logs/   ${tag} ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    1
    #----delete apikey
    Delete apikey   ${apikey}  ${tenant_id}
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    Log To Console   ${kafka_dict}
    Sleep  20
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${message}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    1

TC.1.4. Event with deleted tenant is rejected by topology
    [Documentation]  Send event when tenant_id was deleted
    [Tags]  ITC-authbolt-1.4  negative
    ${tag}  set variable  ITC-authbolt-1.4
    ${tenant_id}  ${apikey}   Create tenant
    Log To Console  tenant_id = ${tenant_id}; apikey = ${apikey}
    Get date and _index for Elasticsearch (Y.M.D)
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    Log To Console   ${kafka_dict}
    #---check ES
    ${message}  Get Message From Es By Body  /logs-${tenant_id_global}-${Y.M.D}/logs/   ${tag} ${message}
    Remove From Dictionary    ${message}    @timestamp  tags  messageId  id  index
    Remove From Dictionary   ${kafka_dict}  @timestamp  apikey
    Dictionaries Should Be Equal  ${message}  ${kafka_dict}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    1
    #----delete tenant_id
    Delete tenant '${tenant_id}'
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    Log To Console   ${kafka_dict}
    Sleep  20
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${message}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    1

TC.1.4a. Send event when tenant with 3 apikeys was deleted
    [Tags]  ITC-authbolt-1.4a  negative
    ${tag}  set variable  ITC-authbolt-1.4a
    ${tenant_id}  ${apikey_1}   Create tenant
    ${apikey_2}  Create apikey for '${tenant_id}'
    ${apikey_3}  Create apikey for '${tenant_id}'
    Log To Console  tenant_id = ${tenant_id}; apikey_1 = ${apikey_1}
    Log To Console  apikey_2 = ${apikey_2}; apikey_3 = ${apikey_3}
    sleep  ${delay}
    Get date and _index for Elasticsearch (Y.M.D)
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    sleep  ${delay}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    3
    #----delete tenant_id
    Delete tenant '${tenant_id}'
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    sleep  20
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${tag} ${message}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    3

TC.1.5. Event with disabled apikey is rejected by topology
    [Documentation]  Send event with disabled apikey and check error message
    [Tags]  ITC-authbolt-1.5  positive
    ${tag}  set variable  ITC-authbolt-1.5
    ${tenant_id}  ${apikey}   Create tenant
    Log To Console  tenant_id = ${tenant_id}; apikey = ${apikey}
    Get date and _index for Elasticsearch (Y.M.D)
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    : FOR  ${i}  IN RANGE  ${5}
    \   Get datetime
    \   ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    \   Send Message To Kafka    ${log_topic}    ${kafka_dict}
    \   Log To Console   ${kafka_dict}
    Sleep  ${delay}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    5
    #---update apikey to disable
    Update apikey '${apikey}' for '${tenant_id}' with status 'False'
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    : FOR  ${i}  IN RANGE  ${5}
    \   Get datetime
    \   ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    \   Send Message To Kafka    ${log_topic}    ${kafka_dict}
    \   Log To Console   ${kafka_dict}
    Sleep  20
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${tag} ${message}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    5

TC.1.6. Send event with disabled apikey and check error message
    [Tags]  ITC-authbolt-1.6  positive
    ${tag}  set variable  ITC-authbolt-1.6
    ${tenant_id}  ${apikey}   Create tenant
    Log To Console  tenant_id = ${tenant_id}; apikey = ${apikey}
    Get date and _index for Elasticsearch (Y.M.D)
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    Send Message To Kafka    ${log_topic}    ${kafka_dict}
    Sleep  20
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    1
    #---update apikey to disable
    Update apikey '${apikey}' for '${tenant_id}' with status 'False'
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    Send Message To Kafka    ${log_topic}    ${kafka_dict}
    Sleep  20
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    1
    #---update apikey to enable
    Update apikey '${apikey}' for '${tenant_id}' with status 'True'
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    Send Message To Kafka    ${log_topic}    ${kafka_dict}
    Sleep  20
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    2

TC.1.7. Send event with disabled apikey and check error message
    [Tags]  ITC-authbolt-1.7  positive
    ${tag}  set variable  ITC-authbolt-1.7
    ${tenant_id}  ${apikey_1}   Create tenant
    ${apikey_2}  Create apikey for '${tenant_id}'
    ${apikey_3}  Create apikey for '${tenant_id}'
    Log To Console  tenant_id = ${tenant_id}; apikey_1 = ${apikey_1}
    Log To Console  apikey_2 = ${apikey_2}; apikey_3 = ${apikey_3}
    sleep  ${delay}
    Get date and _index for Elasticsearch (Y.M.D)
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    sleep  ${delay}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    3
    #---update apikey to disable
    Update apikey '${apikey_1}' for '${tenant_id}' with status 'False'
    Update apikey '${apikey_2}' for '${tenant_id}' with status 'False'
    Update apikey '${apikey_3}' for '${tenant_id}' with status 'False'
    Sleep  5
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    sleep  ${delay}
    #---check errorTopic
    ${results}    Get Message From Kafka By key    errorTopic    {"errorSource":"${tenant_id}"}
    ${srt_res}  convert to string  ${results}
    should contain   ${srt_res}  ${message}
    #---update apikey to enable
    Update apikey '${apikey_2}' for '${tenant_id}' with status 'True'
    Sleep  5
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    sleep  ${delay}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    4
    #----delete apikey
    Delete apikey   ${apikey_2}  ${tenant_id}
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    sleep  ${delay}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    4
    #---update apikey to enable
    Update apikey '${apikey_1}' for '${tenant_id}' with status 'True'
    Update apikey '${apikey_3}' for '${tenant_id}' with status 'True'
    Sleep  5
    #---send data to kafka
    ${message}    Generate Random String   11  [LETTERS]
    ${kafka_dict}  Create Dictionary  apikey=${apikey_1}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_2}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    ${kafka_dict}  Create Dictionary  apikey=${apikey_3}  tenant_id=${tenant_id}  message=${tag} ${message}  @timestamp=${@timestamp}
    ${res}  Send Message To Kafka   ${log_topic}  ${kafka_dict}
    sleep  ${delay}
    #-------------------------------------------------------------------------
    ${n}    Count All Es Messages    /logs-${tenant_id_global}-${Y.M.D}/logs/
    Should Be Equal As Integers   ${n}    6
