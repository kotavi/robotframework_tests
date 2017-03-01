*** Settings ***
Documentation     Set of tests is used for component testing of Kafka.
...               Here we check that Kafka can store data to log/alert/metric/callback topics in json (and not json) format
...               This test suite should be run only if there is kafka install - no storm topology deployed


Test Setup        Run Keywords    Get datetime         
Resource          keywords/keywords.robot
Resource          keywords/prepopulate_data.robot
Resource          keywords/influx-grafana_keywords.robot
Library           libs/Additional.py
Library           libs/KafkaClient.py
Library           libs/ElasticSearchClient.py
Library           libs/InfluxClient.py
Library           Collections

*** Test Cases ***
Successful connection to all broker in the cluster
    [Tags]    CTC-Kaf-7  ctc_smoke  kafka_migration_TC  positive
    Show Kafka Connection

#Show kafka leader for partition
#    Show kafka leader for partition  logTopic  1

Show Kafka metadata for topic
    [Tags]    CTC-Kaf-8  ctc_smoke  kafka_migration_TC  positive
    @{list}    Create List    logTopic  metricTopic  email  alertTopic  cacheInvalidation  callback  quotaViolation
    :FOR    ${topic}    IN    @{list}
    \    Log    ${topic}
    \    Show Kafka metadata for topic  ${topic}
    
Send message to Kafka logTopic not in json format
    [Tags]    CTC-Kaf-1  CTC-Kaf-2    ctc_smoke  kafka_migration_TC  positive
    ${message}   Set Variable   CTCKafka-log message not in json format ${datetime}
    Send Message To Kafka   logTopic    ${message}
    Check Message In Kafka exists    logTopic    ${message}

Send message to Kafka to alertTopic not in json format
    [Tags]    CTC-Kaf-3    ctc_smoke  kafka_migration_TC  positive
    ${message}   Set Variable   CTCKafka-alert message ${datetime}
    Send Message To Kafka  alertTopic    ${message}
    Check Message In Kafka exists    alertTopic    ${message}

Send message to Kafka logTopic with specific symbols
    [Tags]    CTC-Kaf-4    ctc_smoke  kafka_migration_TC  positive
    ${message}   Set Variable   @ # % % ^ & * ( ${datetime}
    Send Message To Kafka  logTopic    ${message}
    Check Message In Kafka exists    logTopic    ${message}

Send long message to Kafka logTopic not in json format
    [Tags]    CTC-Kaf-5    ctc_smoke  kafka_migration_TC  positive
    ${message}   Set Variable   Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer eu ante vel sem fringilla fringilla. Nullam in ipsum ac enim posuere facilisis. Praesent eget orci bibendum, posuere magna sit amet, accumsan dui. Proin quam turpis, adipiscing elementum eros a, lobortis ullamcorper elit. Praesent quis erat fringilla, sollicitudin sem et, sollicitudin dolor. Sed varius a sem quis euismod. Cras ligula purus, porttitor a quam sit amet, elementum rhoncus enim. Proin gravida, mauris sed rutrum facilisis, nisi diam tempor elit, et vulputate tortor lacus vitae sem. Suspendisse in diam ac sem feugiat auctor ullamcorper id quam. Nullam ac consectetur lacus. Aliquam at lobortis risus. Maecenas venenatis tellus vel tellus imperdiet, a gravida ligula feugiat. Nullam eu euismod lorem. Mauris ac augue risus. ${datetime}
    Send Message To Kafka  logTopic    ${message}
    Check Message In Kafka exists    logTopic    ${message}

Send message to Kafka metricTopic not in json format
    [Tags]    CTC-Kaf-6    ctc_smoke  kafka_migration_TC  positive
    ${message}   Set Variable   CTCKafka-metric not in json format ${datetime}
    Send Message To Kafka  metricTopic   ${message}
    Check Message In Kafka exists    metricTopic    ${message}

Send message to Kafka metricTopic in wrong json format
    [Tags]    CTC-Kaf-6a    ctc_smoke  kafka_migration_TC  positive
    ${json_1}    Create Dictionary  host=qa-test-node  name=CTC_tests_metric_topic  value=33  @timestamp=${datetime}
    Send Message To Kafka    metricTopic  ${json_1}
    ${results}    Get Message From Kafka By key    metricTopic    {"@timestamp":"${datetime}"}
    Dictionaries Should Be Equal    ${results}  ${json_1}

Get messages from email topic
    [Tags]    CTC-Kaf-9    ctc_smoke  kafka_migration_TC  positive
#    ${message}   Set Variable   {"message":"CTC-Kaf-9","recipients":["Frodolmm@gmail.com"],"tenant_id":"d9840542280941c2b20a2b71d8f47c49","rule_name":"CTC-Kaf-9"}
#    Send Message To Kafka  email    ${message}
    ${res}  Get Messages From Kafka     email
    Log   ${res[-20:-1]}

Get messages from callback topic
    [Tags]    CTC-Kaf-10    ctc_smoke  kafka_migration_TC  positive
#    ${message}  Set Variable  {"message":"{\\"message\\":\\"callback flood 1437090002273\\"}","recipients":["http://192.168.9.35:8000/correctcallback-flood-4/"],"tenant_id":"d9840542280941c2b20a2b71d8f47c49","rule_name":""}
#    Send Message To Kafka  callback    ${message}
    ${res}  Get Messages From Kafka     callback
    Log   ${res[-20:-1]}

Get messages from quotaViolation topic
    [Tags]    CTC-Kaf-11    ctc_smoke  kafka_migration_TC  positive
#    ${message}   Set Variable   {"message":"Violation of quota for tenant d9840542280941c2b20a2b71d8f47c49. Current used storage: 0GB. Quota: 1GB. Proceeding to DELETE 0GB of oldest logs.","tenant_id":"d9840542280941c2b20a2b71d8f47c49"}
#    Send Message To Kafka  quotaViolation    ${message}
    ${res}  Get Messages From Kafka     quotaViolation
    Log   ${res[-20:-1]}

Get messages from cacheInvalidation topic
    [Tags]    CTC-Kaf-12    ctc_smoke  kafka_migration_TC  positive
#    ${message}   Set Variable
    ${res}  Get Messages From Kafka     cacheInvalidation
    Log   ${res[-20:-1]}