import re
import logging
import string
import random
from datetime import datetime, timedelta
from elasticsearch import Elasticsearch
from elasticsearch import TransportError, NotFoundError

from time import sleep
from robot.libraries.BuiltIn import BuiltIn
from Additional import Additional


LOG = logging.getLogger(__name__)


class EsClientError(Exception):
    pass


class ElasticSearchClient(object):
    def __init__(self, es_host=None):
        if not es_host:
            helper = Additional()
            cluster = BuiltIn().replace_variables("${es_cluster}")
            es_host = helper.define_ip(cluster)
        es_port = BuiltIn().replace_variables("${ES_port}")
        user = BuiltIn().replace_variables("${sudo_user}")
        secret = BuiltIn().replace_variables("${sudo_pass}")
        self.es = Elasticsearch(hosts=[{"host": es_host, "port": int(es_port)}], http_auth=(user, secret))

    def user_send_message_to_es(self, url, message):
        """
        Method allows to send given message to specified url;
        Returns id of the message
        """
        _index, _type = url.replace("/", " ").split()
        try:
            res = self.es.index(index=_index, doc_type=_type,
                                body=message, params={"ignore": 400})
            LOG.info('sent message to ES:  ', res)
        except TransportError as e:
            raise e  # TODO add handling
        else:
            if "status" in res.keys() and res["status"] == 400:
                return res
            else:
                return res["_id"]

    def get_message_from_es_by_id(self, url, _id):
        """
        Method returns a message from specified url with corresponding id;
        If message wasn't found method returns "Message was not found"
        """
        _index, _type = url.replace("/", " ").split()
        try:
            res = self.es.get(index=_index, doc_type=_type,
                              id=_id, params={"ignore": 404})
            LOG.info(res)
        except Exception as e:
            raise e  # TODO add handling
        if 'found' in res and res["found"] is True:
            LOG.info(res)
            return res
        elif 'status' in res and res["status"] is True:
            LOG.info(res)
            return res
        LOG.info("Message was not found")
        return "Message was not found"

    def get_message_from_es_by_body(self, url, body, kwargs={}):
        """
        Method returns a message from specified url with corresponding body;
        If message wasn't found method returns "Message was not found"
        """
        _index, _type = url.replace("/", " ").split()
        sleep(1)
        res = self.es.search(index=_index, doc_type=_type,
                             params={"size": 200000})
        for r in res["hits"]["hits"]:
            if r["_source"].has_key('message') and r["_source"]["message"] == body:
                # raise AssertionError(r["_source"])
                return r["_source"]
            else:
                if r["_source"].has_key('@rawMessage') and r["_source"]["@rawMessage"] == body:
                    return r["_source"]
        msg = "Message was not found"
        if kwargs.get('raise_if_not_found'):
            raise NotFoundError(msg, 404)
        else:
            return msg

    def return_full_es_message(self, url, body, kwargs={}):
        """
        Method returns a message from specified url with corresponding body;
        If message wasn't found method returns "Message was not found"
        """
        _index, _type = url.replace("/", " ").split()
        sleep(1)
        res = self.es.search(index=_index, doc_type=_type,
                             params={"size": 200000})
        for r in res["hits"]["hits"]:
            if r["_source"].has_key('message') and r["_source"]["message"] == body:
                # raise AssertionError(r["_source"])
                return r
            else:
                if r["_source"].has_key('@rawMessage') and r["_source"]["@rawMessage"] == body:
                    return r
        msg = "Message was not found"
        if kwargs.get('raise_if_not_found'):
            raise NotFoundError(msg, 404)
        else:
            return msg

    def get_message_from_es_by_key(self, url, key, body, kwargs={}):
        """
        Method returns a message from specified url by key with corresponding body;
        If message wasn't found method returns "Message was not found"
        """
        _index, _type = url.replace("/", " ").split()
        sleep(1)
        res = self.es.search(index=_index, doc_type=_type,
                             params={"size": 200000})
        for r in res["hits"]["hits"]:
            if r["_source"].has_key(key) and r["_source"][key] == body:
                return r["_source"]
        msg = "Message was not found"
        if kwargs.get('raise_if_not_found'):
            raise NotFoundError(msg)
        else:
            return msg

    def _get_messages_from_es(self, url):
        _index, _type = url.replace("/", " ").split()
        result = self.es.search(index=_index, doc_type=_type,
                                params={"size": 200000})
        return result["hits"]["hits"]

    def get_message_from_es_by_keys(self, url, *args):
        keys = {}
        for arg in args:
            key, value = arg.split('=')
            keys[key] = value
        messages = self._get_messages_from_es(url)
        ab = []
        for message in messages:
            if all([message['_source'][key] == value for key, value in keys.iteritems()
                    if message['_source'].has_key(key)]):
                return message

    def delete_messages_from_es_by_list_ids(self, url, lst):
        for item in lst:
            self.delete_message_from_es(url, item)


    def delete_message_from_es(self, url, _id):
        """
        Method deletes message from Elasticsearch by its id;
        If message wasn't found method returns "Message was not found"
        """
        _index, _type = url.replace("/", " ").split()
        try:
            self.es.delete(index=_index, doc_type=_type, id=_id, params={"ignore": 404})
        except Exception as e:
            return "Message was not found"

    def delete_index_from_es(self, index):
        """
        Method deletes index predefined in input argument from Elacticsearch
        """
        self.es.indices.delete(index=index, params={"ignore": 404})

    def delete_all_indices_for_tenant(self, tenant_id):
        indices = self.get_indices_for_tenant(tenant_id)
        map(self.delete_index_from_es, indices)

    def _get_all_messages_from_es(self, url):
        _index, _type = url.replace("/", " ").split()
        sleep(1)
        res = self.es.search(index=_index, doc_type=_type,
                             params={"size": 200000})
        return res

    def check_if_index_exist(self, url):
        _index, _type = url.replace("/", " ").split()
        try:
            self.es.search(index=_index, doc_type=_type, params={"size": 200000})
            return "Index %s exists." % url
        except Exception as e:
            return "Index %s does not exist." % url

    def count_es_messages_by_body(self, url, body):
        """
        Method returns number of messages from url by searched body;
        """
        res = self._get_all_messages_from_es(url)
        body_count = 0
        for r in res["hits"]["hits"]:
            if r["_source"].has_key('message') and r["_source"]["message"] == body:
                body_count += 1
            elif r["_source"].has_key('@rawMessage') and r["_source"]["@rawMessage"] == body:
                body_count += 1
        return body_count

    def count_all_es_messages_by_host(self, host, url):
        self.__init__(host)
        return self.count_all_es_messages(url)

    def count_all_es_messages(self, url):
        """
        Method returns number messages stored in Elasticsearch;
        """
        # TODO replace method with default from es-client
        # res = self.es.count(url)
        res = self._get_all_messages_from_es(url)
        body_count = 0
        for r in res["hits"]["hits"]:
            # LOG.warning("res[\"hits\"][\"hits\"]: %s" % res["hits"]["hits"])
            if r["_source"].has_key('message'):
                body_count += 1
        return body_count

    def wait_until_message_comes_to_es(self, url, body):
        """
        Waits until searched message comes to the specified url
        """
        timeout = 600
        for i in range(timeout):
            hits = self.count_es_messages_by_body(url, body)
            if hits > 0:
                return True
            sleep(1)
        return "Message didn't come"

    def get_es_message_id_by_body(self, url, body):
        """
        Method searches specified url and returns an id of the message by its body;
        If message wasn't found method returns "Message was not found"
        """
        res = self._get_all_messages_from_es(url)
        for r in res["hits"]["hits"]:
            if r["_source"].has_key('message') and r["_source"]["message"] == body:
                return r["_id"]
            if r["_source"].has_key('@rawMessage') and r["_source"]["@rawMessage"] == body:
                return r["_id"]
        return "Message was not found"

    def list_append(self, lst, item):
        """
        Appends given list with specified value
            Examples:
            | ${id}  |  *Get Es Message Id By Body* |  /${ES_index}/logs/ | message body |
            | ${empty_list} =   | *Create List* |
            | ${list} | *List append* | ${empty_list} | ${id} |

        """
        return lst.append(item)

    def get_es_index_size(self, index):
        # raise RuntimeError(self.es.indices.stats(index=index, metric=['store'])['indices'][index]['total']['store'])
        bytes = self.es.indices.stats(index=index, metric=['store'])[
            'indices'][index]['total']['store']['size_in_bytes']
        return bytes

    # def send_logs_until_index_size_satisfies(self, url, expected_size, size=5, body=None):
    # ids = list()
    # _index, _type = url.replace("/", " ").split()
    # actual_size = 0
    # expected_size = int(expected_size)
    #     message = ''.join(['q' for a in range(int(size) * 1024)])
    #     if body:
    #         body["message"] = message
    #         message = body
    #     while actual_size < expected_size:
    #         _id = self.user_send_message_to_es(url, message)
    #         actual_size = self.get_es_index_size(_index)
    #         LOG.info("actual_size: %s" % actual_size)
    #         ids.append(_id)
    #     sleep(5)
    #     for i in range(10):
    #         if actual_size > expected_size + 15:
    #             self.delete_message_from_es(url, ids[i])
    #             actual_size = self.get_es_index_size(_index)
    #             LOG.info("actual_size: %s" % actual_size)
    #         sleep(1)
    #     return actual_size

    def get_es_count_of_message_for_index(self, index):
        LOG.warning(
            "get_es_count_of_message_for_index: %s" % self.es.indices.stats(index=index, metric=['docs'])['indices'][
                index])
        return self.es.indices.stats(index=index, metric=['docs'])['indices'][index]['primaries']['docs']['count']

    def should_be_more(self, first, second):
        assert (int(first) > int(second)), 'First argument is less: %s<%s' % (first, second)

    def should_be_less(self, first, second):
        assert (int(first) < int(second)), 'First argument is more: %s>%s' % (first, second)

    def send_bunch_of_messages(self, url, count=1, size=5, body=None, delay=1):
        ids = list()
        message = ''.join([random.choice(string.ascii_letters + string.digits) for n in xrange(int(size) * 1024)])
        if body:
            body["message"] = message
            body["@version"] = 1
            message = body
        for i in range(count):
            _id = self.user_send_message_to_es(url, message)
            ids.append(_id)
            sleep(delay)
        return ids

    def get_indices_for_tenant(self, tenant_id):
        return [index for index in self.es.indices.status()['indices'].keys() if tenant_id in index]

    def get_es_indices_size_for_tenant(self, tenant_id):
        indices = self.get_indices_for_tenant(tenant_id)
        LOG.info("indices: %s" % indices)
        return sum([self.get_es_index_size(x) for x in indices])

    def get_old_index_for_tenant(self, index, days):
        days = days.replace('days', '')
        date = index.split('-')[-1]
        old_date = self.get_old_date(date, days)
        return index.replace(date, old_date)

    def get_old_date(self, date, days):
        if re.match('^\d{4}\.\d{2}\.\d{2}$', date):
            pattern = '%Y.%m.%d'
        elif re.match('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$', date):
            pattern = '%Y-%m-%dT%H:%M:%S.%fZ'
        else:
            raise RuntimeError('Date fromat is not supported')
        date = datetime.strptime(date, pattern) - timedelta(days=int(days))
        return date.strftime(pattern)

    def get_message_from_es_by_index(self, _index):
        sleep(1)
        res = self.es.search(index=_index,
                             params={"size": 200000})
        return res["hits"]["hits"]

    def check_index_exists(self, index):
        """
        Return a boolean indicating whether given index exists.
        """
        res = self.es.indices.exists(index, params=None)
        return res

    def split_returned_value(self, data):
        return data.split()