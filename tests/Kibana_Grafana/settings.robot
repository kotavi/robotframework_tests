*** Settings ***
Documentation     Test suites that check Web UI in terms of graphs visualization.
Resource          ../keywords/keywords.robot
Resource          ../keywords/influx-grafana_keywords.robot
Resource          ../keywords/prepopulate_data.robot
Library           ../libs/InfluxClient.py
Library           ../libs/KafkaClient.py
Library           Collections
Library           ../libs/ElasticSearchClient.py