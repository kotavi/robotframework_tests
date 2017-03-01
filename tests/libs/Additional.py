import string
from datetime import datetime
import random
import time
import pycurl
import StringIO
import cStringIO
import json
from robot.libraries.BuiltIn import BuiltIn
import logging

LOG = logging.getLogger(__name__)

class Additional(object):
    def generate_random_date(self,):
        year = random.choice(range(1950, 2000))
        month = random.choice(range(1, 12))
        day = random.choice(range(1, 28))
        birthDate = datetime(year, month, day)

    def _strTimeProp(self, start, end, format, prop):
        """Get a time at a proportion of a range of two formatted times.
        start and end should be strings specifying times formated in the
        given format (strftime-style), giving an interval [start, end].
        prop specifies how a proportion of the interval to be taken after
        start.  The returned time will be in the specified format.
        """

        stime = time.mktime(time.strptime(start, format))
        etime = time.mktime(time.strptime(end, format))

        ptime = stime + prop * (etime - stime)

        return time.strftime(format, time.localtime(ptime))

    def define_ip(self, cluster):
        """ define randon ip within cluster"""
        rnd = random.randint(0, len(cluster) - 1)
        return cluster[rnd]

    def get_random_date(self, start, end, format):
        """
        Example of using:
        print randomDate("1/1/2008 1:30 PM", "1/1/2009 4:50 AM")
        ${year}-${month}-${day}T${hour}:${min}:${sec}.000Z
        """
        return self._strTimeProp(start, end, format, random.random())

    def save_topology_id(self, dict, name):
        dict_len = len(dict)
        for i in range(0, dict_len):
            if name in dict[i]['id']:
                topology_id = dict[i]['id']
                break
        return topology_id

    def _get_variables(self):
        keystone_url = BuiltIn().replace_variables("${keystone_ip}")
        url_path = BuiltIn().replace_variables("${url_path}")
        user_name = BuiltIn().replace_variables("${username}")
        user_pass = BuiltIn().replace_variables("${keystone_pass}")
        body = BuiltIn().replace_variables("${keystone_v3}")
        web_url = BuiltIn().replace_variables("${IP_web}")
        return keystone_url, url_path, user_name, user_pass, body, web_url

    def get_pkitoken_tenantid(self):
        keystone_url, url_path, user_name, user_pass, body, web_url = self._get_variables()
        data = StringIO.StringIO()
        hdrs = cStringIO.StringIO()
        curl = pycurl.Curl()
        curl.setopt(pycurl.URL, str('https://%s/%s' % (keystone_url, url_path)))
        curl.setopt(pycurl.POST, 1)
        curl.setopt(pycurl.HTTPHEADER, ['Content-Type: application/json', 'Accept: application/json'])
        curl.setopt(pycurl.POSTFIELDS, str(body))
        curl.setopt(pycurl.USERPWD, str('%s:%s' % (user_name, user_pass)))
        # curl.setopt(pycurl.VERBOSE, 1)
        curl.setopt(pycurl.WRITEFUNCTION, data.write)
        curl.setopt(pycurl.HEADERFUNCTION, hdrs.write)
        curl.perform()
        if curl.getinfo(pycurl.RESPONSE_CODE) == 201:
            dictionary = json.loads(data.getvalue())
            tenant_id = dictionary["token"]["project"]["id"]
            status_line = hdrs.getvalue().splitlines()[3]
            pki_token = status_line.split()[1]
            LOG.critical("pki_token: %s" % pki_token)
            LOG.critical("tenant_id: %s" % tenant_id)
        curl.reset()
        curl.close()
        return tenant_id, pki_token

    def get_apikey(self, tenant_id, pki_token):
        keystone_url, url_path, user_name, user_pass, body, web_url = self._get_variables()
        data = StringIO.StringIO()
        hdrs = cStringIO.StringIO()
        c = pycurl.Curl()
        web_path = 'get_apikey?tenant=' + tenant_id
        get_apikey_url = str(web_url + '/' + web_path)
        c.setopt(pycurl.URL, get_apikey_url)
        c.setopt(pycurl.HTTPGET, 1)
        LOG.critical("tenant_id: %s" % tenant_id)
        arg1, arg2 = str('X-Tenant: %s' % tenant_id), str('X-Auth-token: %s' % pki_token)
        c.setopt(pycurl.HTTPHEADER, [arg1, arg2])
        # c.setopt(pycurl.VERBOSE, 1)
        c.setopt(pycurl.SSL_VERIFYPEER, False)
        c.setopt(pycurl.SSL_VERIFYHOST, False)
        c.setopt(pycurl.WRITEFUNCTION, data.write)
        c.setopt(pycurl.HEADERFUNCTION, hdrs.write)
        c.perform()
        if c.getinfo(pycurl.RESPONSE_CODE) == 200:
            dictionary = json.loads(data.getvalue())
            print dictionary
            apikey = dictionary["apikey"]
            LOG.critical("apikey: %s" % apikey)
        c.close()
        return apikey
