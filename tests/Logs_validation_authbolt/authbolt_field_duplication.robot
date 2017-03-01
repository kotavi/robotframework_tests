*** Settings ***
Resource        authbolt_validation_keywords.robot

Suite Setup   Run Keywords  Create dictionary with roles  Create dictionary with services  Create dictionary with ldap_groups
Suite Setup   Run Keywords  Create global tenant and apikey   Get date and _index for Elasticsearch (Y.M.D)

Test Teardown  Run Keywords   Clear index in elasticsearch

Test Setup  Run Keywords   Get datetime
Suite Teardown  Run Keywords   Clear index in elasticsearch  Delete tenant '${tenant_id_global}'

*** Variables ***
${delay}  15

*** Test Cases ***
Send message to logTopic with two apikey fields with the same values
    [Tags]  ITC-authbolt-3.1  negative   es_migration_TC
    Create index in es shoud fail  {"apikey":"${apikey_global}","apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"duplication field apikey ${@timestamp}","@timestamp":"${es_time}","some_int":7}
    
Send message to logTopic with two apikey fields with the different values
    [Tags]  ITC-authbolt-3.2  negative  storm_migration_TC
    Create index in es shoud fail  {"apikey":"${apikey_global}","apikey":"asdaa2134agbnje","tenant_id":"${tenant_id_global}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","some_int":6}

Send message to logTopic with two tenant_id fields
    [Tags]  ITC-authbolt-3.3  negative  smoke
    Create index in es shoud fail  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","tenant_id":"${tenant_id_global}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","some_int":5}

Send message to logTopic with two message fields
    [Tags]  ITC-authbolt-3.4  negative
    Create index in es shoud fail  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"Field_validation_two_message_fields","message":"Field_validation_two_message_fields","@timestamp":"${@timestamp}","some_int":4}

Send message to logTopic with two @timestamp fields 
    [Tags]  ITC-authbolt-3.5  negative  smoke
    Create index in es shoud fail  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","@timestamp":"${@timestamp}","some_int":3}

Send message to logTopic with two @version field
    [Tags]  ITC-authbolt-3.6  negative  storm_migration_TC
    Create index in es shoud fail  {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","@version"=1,"@version"=1,"some_int":1}

Send message to logTopic with two pid_int field
    [Tags]  ITC-authbolt-3.7  negative  storm_migration_TC
    Create index in es shoud fail   {"apikey":"${apikey_global}","tenant_id":"${tenant_id_global}","message":"Field_validation_not_int_double","@timestamp":"${@timestamp}","some_int":2,"some_int":2}
