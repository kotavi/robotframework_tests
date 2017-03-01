import json
import logging
from time import sleep
from kafka.common import (
    UnknownTopicOrPartitionError,
    NotLeaderForPartitionError,
    KafkaError,
    TopicAndPartition)
from kafka import producer, SimpleConsumer
from kafka import KafkaClient as kafkaCl
from robot.libraries.BuiltIn import BuiltIn
from Additional import Additional


LOG = logging.getLogger(__name__)


class LmmProducer(producer.SimpleProducer):
    def send_messages(self, topic, *msg):
        partition = self._next_partition(topic)
        if self.async:
            for m in msg:
                self.queue.put((TopicAndPartition(topic, partition), m))
                resp = []
        else:
            messages = producer.create_message_set(msg, self.codec)
            req = producer.ProduceRequest(topic, partition, messages)
            try:
                resp = self.client.send_produce_request([req],
                                                        acks=self.req_acks,
                                                        timeout=self.ack_timeout
                )
            except Exception as e:
                producer.log.exception('Unable to send message to topic: %s '
                                       'and partition: %s. Failed with error'
                                       ' %s' % (topic, partition, e.message))
                raise
            producer.log.info('Message to the topic: %s and partition: %s '
                              'was sent successfully' % (topic, partition))
        return resp


class KafkaClient(object):
    def __init__(self, ip_address=None):
        """
        Starts Kafka client on specified port (by default port=9092)
        """
        if not ip_address:
            self.helper = Additional()
            self.kafka_cluster = BuiltIn().replace_variables("${kafka_cluster}")
            ip_address = self.helper.define_ip(self.kafka_cluster)
        port = BuiltIn().replace_variables("${kafka_port}")
        try:
            self.kafka = kafkaCl("%s:%s" % (ip_address, port))
        except Exception as e:
            raise KafkaError("KAFKA ERROR: %s %s"
                             % (e, "%s:%s" % (ip_address, port)))
        self.producer = LmmProducer(self.kafka)
        self.messages = []

    def _change_kafka_ip(self):
        self.host = self.helper.define_ip(self.kafka_cluster)
        self.__init__(self.host)

    def send_message_to_kafka_by_broker_ip(self, ip, topic="", message=""):
        try:
            res = self.send_message_to_kafka(topic, message)
        except Exception as e:
            return KafkaError("KAFKA ERROR: %s" % ip)
        return res

    def send_message_to_kafka(self, topic="", message=""):
        """
        Allows to send message to defined Kafka topic
        """
        if isinstance(message, dict):
            message = json.dumps(message)
        elif isinstance(message, unicode):
            message = str(message)
        for i in self.kafka.topic_partitions[str(topic)]:
            try:
                response = self.producer.send_messages(str(topic), message)
                break
            except (UnknownTopicOrPartitionError,
                    NotLeaderForPartitionError) as e:
                # these errors can appear in case of not proper work of Kafka nodes
                continue
        if not response:
            raise KafkaError('Message was not sent')
        if response[0].error != 0:
            raise KafkaError("Error code %s" % response[0].error)
        else:
            self.messages.append(response[0])

    def get_messages_from_kafka(self, topic):
        """
        Gets all messages from Kafka topic which were sent to kafka
        via KafkaClient
        """
        mes = []
        consumer = SimpleConsumer(self.kafka, "my-consumer", str(topic))
        LOG.info("consumer: %s" % consumer)
        if any([True for m in self.messages if m.topic == topic]):
            LOG.info("self.messages: %s" % self.messages)
            for message in self.messages:
                if message.topic == topic:
                    LOG.info("message.topic: %s" % message.topic)
                    consumer.fetch_offsets = {
                        message.partition: message.offset}
                    _message = consumer.get_message()
                    consumer.fetch_offsets = consumer.offsets
                    mes.append(_message.message.value)
                    self.messages.remove(message)
        else:
            # """Alter the current offset in the consumer to the earliest
            #            available offset (head)"""
            # consumer.seek(0, 0) - to start reading from the beginning of the queue.
            # consumer.seek(0, 1) - to start reading from current offset.
            # consumer.seek(0, 2) - to skip all the pending messages and start reading only new messages.
            # The first argument is an offset to those positions.
            # In that way, if you call consumer.seek(5, 0) you will skip the first 5 messages from the queue.
            consumer.seek(1, 0)
            for i in range(50000):
                _message = consumer.get_message()
                if not _message:
                    return mes
                else:
                    mes.append(_message.message.value)
        return mes

    def get_message_from_kafka_by_key(self, topic, key):
        """
        Returns message from Kafka topic according to the key.
            Examples:
            | ${message} | *Get Message From Kafka By key* | TopicName |
                                           {"field_name":"value_name"} |
        """
        uniq_key = json.loads(key)
        key = uniq_key.keys()[0]
        value = uniq_key[key]
        messages = self.get_messages_from_kafka(topic)
        for message in messages:
            try:
                _message = json.loads(message.replace('//', ''))
            except Exception as e:
                continue
            if key in _message.keys():
                if str(value) == _message[key]:
                    return _message
                else:
                    continue
        raise KafkaError('''In kafka  topic '%s' no message with key:
                         %s and value: %s. Was consumed %s messages.'''
                         % (topic, key, value, len(messages)))

    def check_message_in_kafka_exists(self, topic, message):
        """
        This method gets all messages from Kafka topic
        and asserts that searched message is there
        """
        messages = self.get_messages_from_kafka(topic)
        assert (message in messages), "No message '%s' in kafka" % message

    def count_kafka_messages_by_key(self, topic, key):
        """
        This method returns number of how many messages in Kafka topic
        satisfies the key
        """
        key_count = 0
        uniq_key = json.loads(key)
        key = uniq_key.keys()[0]
        value = uniq_key[key]
        messages = self.get_messages_from_kafka(topic)
        for message in messages:
            try:
                _message = json.loads(message)
            except Exception as e:
                continue
            if key in _message.keys():
                if str(value) == _message[key]:
                    key_count += 1
                else:
                    continue
        return key_count

    def get_last_n_messages(self, topic, msgs_number):
        """
        Method extracts last N messages from Kafka topic
        and returns these N messages
        """
        messages = self.get_messages_from_kafka(topic)
        len_messages = len(messages)
        res = messages[len_messages - msgs_number:len_messages]
        return res

    def show_kafka_connection(self):
        """
        Checks that a connection to all broker in the cluster is possible using host and port
        <KafkaConnection host=192.168.199.44 port=9092>
        """
        port = int(BuiltIn().replace_variables("${kafka_port}"))
        for host in self.kafka_cluster:
            output = '<KafkaConnection host=%s port=%s>' % (host, port)
            res = kafkaCl._get_conn(self.kafka, host, port)
            res = str(res)
            LOG.info("res: %s" % res)
            if res != output:
                LOG.critical('ERROR in connection to %s broker with %s port.' % (host, port))
                # raise KafkaError('ERROR in connection to %s broker with %s port.' % (host, port))

    # def show_kafka_leader_for_partition(self, topic, partition):
    # """
    #     """
    #     for host in self.kafka_cluster:
    #         partition = str(partition)
    #         topic = str(topic)
    #         res = kafkaCl._get_leader_for_partition(self.kafka, topic, partition)
    #         LOG.critical("res: %s, host: %s" % (res, host))

    def show_kafka_metadata_for_topic(self, topic):
        topic = str(topic)
        for host in self.kafka_cluster:
            res = kafkaCl.has_metadata_for_topic(self.kafka, topic)
            if not res:
                LOG.critical("result: %s, host: %s, topic: %s" % (res, host, topic))

    def __del__(self):
        """
        Closes Kafka client
        """
        self.kafka.close()

    if __name__ == "__main__":
        import pdb
        pdb.set_trace()
        get_messages_from_kafka(email)

