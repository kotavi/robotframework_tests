from ast import literal_eval
import json
import logging
from time import sleep
from influxdb.client import InfluxDBClient, InfluxDBClientError
from robot.libraries.BuiltIn import BuiltIn
from Additional import Additional


LOG = logging.getLogger(__name__)

class InfluxClient(object):
    def __init__(self, host=None):
        if not host:
            helper = Additional()
            cluster = BuiltIn().replace_variables("${influxdb_cluster}")
            host = helper.define_ip(cluster)
        port = 8086
        username = 'root'
        passwd = 'root'
        db = None
        self.influx_client = InfluxDBClient(host, port, username, passwd, db)

    def get_influxdb_cluster_info(self):
        """ Returns full info of cluster """
        url = 'cluster/configuration'
        response = self.influx_client.request(
            url=url,
            method='GET',
            status_code=200
        )

        return response.json()

    def delete_continuous_query(self, database, query):
        """
        Get a list of continuous queries
        """
        self.influx_client.switch_database(database)
        response = self.influx_client.query('list continuous queries')
        query_id = [_query[1] for _query in response[0]['points']
                       if _query[2] == query]
        self.influx_client.query('drop continuous query %s' % query_id[0])
        return [query[2] for query in response[0]['points']]

    def get_list_continuous_queries(self, database):
        """
        Get a list of continuous queries
        """
        self.influx_client.switch_database(database)
        response = self.influx_client.query('list continuous queries')
        return [query[2] for query in response[0]['points']]

    def get_influxdb_continuous_queries(self):
        """ Returns continuous queries for all dbs in cluster """
        return self.get_influxdb_cluster_info()['ContinuousQueries']

    def get_influxdb_shard_spaces(self):
        """ Returns shard spaces for all dbs in cluster """
        return self.get_influxdb_cluster_info()['DatabaseShardSpaces']

    def create_influx_database(self, database):
        """
        Method creates a database with the name specified in request
        """
        try:
            self.influx_client.create_database(database)
        except InfluxDBClientError as e:
            if e.code == 409:
                return e.message
            else:
                raise e

    def delete_influx_database(self, database):
        """
        Method deletes database with the name specified in request
        """
        self.influx_client.drop_database(database)

    def _clean_database(self, database):
        """
        Deletes all series from given database
        """
        self.influx_client.switch_database(database)
        results = self.influx_client.query('list series')
        series = [s[1] for s in results[0]['points']]
        map(self.influx_client.delete_series, series)

    def cleand_database_for_tenant(self, database, tenant_id):
        """
        Deletes all series from given database by tenant id
        """
        self.influx_client.switch_database(database)
        results = self.influx_client.query('list series')
        series = [s[1] for s in results[0]['points']
                     if tenant_id in s[1]]
        map(self.influx_client.delete_series, series)

    def write_data_to_influx(self, database, json_body):
        """
        Writes data into database
        """
        self.influx_client.switch_database(database)
        LOG.info("json: %s" % json_body)
        self.influx_client.write_points(json.loads(json_body))

    def querying_data_from_influx_by_host_ip(self, ip, database, query):
        self.__init__(ip)
        return self.querying_data_from_influx(database, query)

    def querying_data_from_influx(self, database, query):
        """
        Returns data from database according to the query
        """
        self.influx_client.switch_database(database)
        result = self.influx_client.query(query)
        return result

    def get_database_list_from_influx(self):
        """
        Returns a list of databases
        """
        return self.influx_client.get_list_database()

    def check_db_in_influx_does_not_exist(self, database):
        """
        Checks that database doesn't exist
        """
        dbs = self.get_database_list_from_influx()
        for db in dbs:
            if db["name"] == database:
                raise InfluxDBClientError("Database %s exists!"
                                          % database, 409)

    def check_db_in_influx_exist(self, database):
        """
        Checks that database exists
        """
        dbs = self.get_database_list_from_influx()
        LOG.info("list of DBs %s" % dbs)
        for db in dbs:
            print db["name"]
        if database in dbs:
            return True
        else:
            return 'Database %s doesn\'t exist!' % database

        # LOG.info("list of DBs %s" % dbs)
        # for db in dbs:
        #     LOG.info("db[name] %s" % db["name"])
        #     if db["name"] == database:
        #         return True
        #     else:
        #         return 'Database %s doesn\'t exist!' % database

    def wait_until_series_created(self, db, series):
        """
        Waits until series specified in request
        is created in the database
        """
        # TODO: debug and use this method in tests
        timeout = 600
        query = "select count(name) from %s" % series
        initial = len(self.querying_data_from_influx(db, query))
        for i in range(timeout):
            if initial > 0:
                return True
            sleep(1)
        raise InfluxDBClientError("Series was not created", 404)

    # def _delete_series(self, series):
    #     self.influx_client.query('drop series "%s"' % series)

    def delete_influx_series(self, database, series):
        """
        Deletes series from database
        """
        self.influx_client.switch_database(database)
        self.influx_client.delete_series(database=database, measurement=series)

    def find_messages_in_influx_response_where(self, query, response):
        """
        Seeks hits in influxdb response by query
        :arg query: Name and value of columns in format name=value
        :arg resonse: Response of method querying_data_from_influx
        """
        key, value = query.split('=')
        index = response[0]['columns'].index(key)
        try:
            value = literal_eval(value)
        except:
            hits = [point for point in response[0]['points']
                    if point[index] == value]
            if hits:
                return [{'points': hits,
                         'name': response[0]['name'],
                         'columns': response[0]['columns']}]
            else:
                raise InfluxDBClientError('Message was not found', 404)

        hits = []
        for k, v in value.iteritems():
            if isinstance(v, unicode):
                value[k] = str(v)

        for point in response[0]['points']:
            try:
                resp = literal_eval(point[index])
            except:
                continue
            if resp == value:
                hits.append(point)
        if hits:
            return [{'points': hits,
                     'name': response[0]['name'],
                     'columns': response[0]['columns']}]
        else:
            raise InfluxDBClientError('Message was not found', 404)
