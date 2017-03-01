*** Variables ***
#DEV
${es_master_node}     10.109.8.8
${kibana_node}        localhost
@{es_cluster}         10.109.8.8
@{influxdb_cluster}    localhost

#credentials
${sudo_user}        tetiana_korchak
${sudo_pass}
${name_test_user1}    volta_test_user1
${pass_test_user1}    &eital3Gian3s
${name_test_user2}    volta_test_user2
${pass_test_user2}    @s5ngPeeaMts

#ports
${ES_port}          9200
${kibana_port}      5601

${es_cluster_name}     node-5.test.domain.local_es-01
${ES_version}          2.3.3

