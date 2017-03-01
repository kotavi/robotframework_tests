import redis
import logging
from robot.libraries.BuiltIn import BuiltIn
from Additional import Additional

LOG = logging.getLogger(__name__)


class RedisClient(object):
    def __init__(self, host=None):
        if not host:
            self.helper = Additional()
            self.redis_cluster = BuiltIn().replace_variables("${redis_cluster}")
            self.host = self.helper.define_ip(self.redis_cluster)
        self.r_server = redis.Redis(self.host)

    def _change_redis_ip(self):
        host = self.helper.define_ip(self.redis_cluster)
        LOG.info('redis host: %s', host)
        self.r_server = redis.Redis(host)

    def get_data_from_redis_by_key(self, key):
        """
        with the created redis object
        user can get data from redis by specified key
        """
        self._change_redis_ip()
        result = self.r_server.get(key)
        if result:
            return result
        else:
            return 'KeyError for %s' % key

    def set_data_to_redis(self, host, key, value):
        """
        with the created redis object
        user can set new data to redis
        """
        new_server = redis.Redis(host)
        result = new_server.set(key, value)
        # result = self.r_server.set(key, value)
        return result

    def delete_data_from_redis(self, host, *names):
        """Delete one or more keys specified by ``names``"""
        # self.__init__(host)
        new_server = redis.Redis(host)
        result = new_server.delete(*names)
        return result

    def verify_data_in_redis_exists(self, name):
        """Returns a boolean indicating whether key ``name`` exists"""
        self._change_redis_ip()
        result = self.r_server.exists(name)
        return result

    def show_client_list(self):
        self._change_redis_ip()
        result = self.r_server.client_list()
        return result

    def show_database_size(self):
        """Returns the number of keys in the current database"""
        self._change_redis_ip()
        result = self.r_server.dbsize()
        return result

    def get_redis_server_info(self, host, section=None):
        """
        Returns a dictionary containing information about the Redis server
        The ``section`` option can be used to select a specific section
        of information
        The section option is not supported by older versions of Redis Server,
        and will generate ResponseError
        """
        new_server = redis.Redis(host)
        result = new_server.info(section)
        return result

    def data_redis_lastsave(self):
        """
        Return a Python datetime object representing the last time the
        Redis database was saved to disk
        """
        self._change_redis_ip()
        result = self.r_server.lastsave()
        return result

    def ping_redis_server(self):
        """Ping the Redis server"""
        self._change_redis_ip()
        result = self.r_server.ping()
        return result
        # for ip in self.redis_cluster:
        #     result = self.r_server.ping()
        #     if not result:
        #         LOG.critical("result: %s, host: %s" % (result, ip))


    def get_info_on_sentinel_masters(self):
        """Returns a list of dictionaries containing each master's state."""
        self._change_redis_ip()
        result = self.r_server.sentinel_masters()
        return result

    def get_redis_keys_by_pattern(self, pattern='*'):
        """Returns a list of keys matching ``pattern``"""
        self._change_redis_ip()
        result = self.r_server.keys(pattern)
        return result

    def create_record_in_redis(self, host, name, id):
        new_server = redis.Redis(host)
        result = new_server.sadd(name, id)
        return result

    def tenant_member_of_service_group(self, host, name):
        new_server = redis.Redis(host)
        result = new_server.smembers(name)
        return result

    def get_last_alert_occurrence(self, name):
        result = self.r_server.hgetall(name)
        return result

    def delete_tenant_from_service_group(self, host, name, id):
        new_server = redis.Redis(host)
        result = new_server.srem(name, id)
        return result

    def set_throttle_threshold(self, host, name, value):
        new_server = redis.Redis(host)
        result = new_server.set(name, value)
        return result

    def delete_throttle_threshold(self, host, param):
        new_server = redis.Redis(host)
        result = new_server.delete(param)
        return result

    def get_throttle_threshold(self, host, param):
        new_server = redis.Redis(host)
        result = new_server.get(param)
        return result