#    Copyright (c) 2013 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import json
import requests
from robot.api import logger


class _Rest(object):

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    headers = None
    body = None
    url = None

    def clear_headers(self):
        """
        Clears headers for REST API requests.

        *Arguments:*
            - None.

        *Return:*
            - None.

        *Examples*:
        | Clear Headers |
        """
        self.headers = []

    def set_headers(self, headers_dict):
        """
        Configures headers for REST API requests.

        *Arguments:*
            - headers_dict: string with json dict.

        *Return:*
            - None.

        *Examples*:
        | Set Headers | {'Content-Type': 'application/json' |
        """
        try:
            self.headers = json.loads(headers_dict)
        except:
            raise AssertionError('Incorrect headers: %s' % headers_dict)

    def update_headers(self, name, value):
        """
        Modifies headers for REST API requests.

        *Arguments:*
            - name: header name.
            - value: header value.

        *Return:*
            - None.

        *Examples*:
        | Update Headers | X-Auth-Token | 8808880808080808 |
        """
        self.headers[name] = value

    def set_body(self, body_dict):
        """
        This function allows to configure body for REST API requests.

        *Arguments:*
            - body_dict: string with json dict.

        *Return:*
            - None.

        *Examples*:
        | Set Headers | {'Content-Type': 'application/json' |
        """
        self.body = body_dict

    def get_headers(self):
        """
        Gets headers for REST API requests.

        *Arguments:*
            - None.

        *Return:*
            - Headers dict.

        *Examples*:
        | ${headers} | Get Headers |
        """
        return self.headers

    def GET_request(self, url):
        """
        Sends GET request.

        *Arguments:*
            - url: destination url.

        *Return:*
            - None.

        Examples:
        | GET request | http://10.10.10.1:8082/environments |
        """
        self.response = requests.request('GET', url=url, headers=self.headers)

    def POST_request(self, url):
        """
        Sends POST request.

        *Arguments:*
            - url: destination url.

        *Return:*
            - None.

        *Examples*:
        | POST request | http://10.10.10.1:8082/environments |
        """
        debug_data = 'POST Request to URL: %s \n' \
                     'with Headers: %s \n' \
                     'and Body: %s' % (url, self.headers, self.body)
        logger.debug(debug_data)

        self.response = requests.request('POST', url,
                                         headers=self.headers,
                                         data=self.body)

        logger.debug('Response: %s' % self.response.text)

    def POST_request_without_body(self, url):
        """
        Sends POST request without body.

        *Arguments:*
            - url: destination url.

        *Return:*
            - None.

        *Examples*:
        | POST request | http://10.10.10.1:8082/environments |
        """
        debug_data = 'POST Request to URL: %s \n' \
                     'with Headers: %s \n' % (url, self.headers)
        logger.debug(debug_data)

        self.response = requests.request('POST', url,
                                         headers=self.headers)
        logger.debug('Response: %s' % self.response.text)

    def DELETE_request(self, url):
        """
        Sends DELETE request.

        *Arguments:*
            - url: destination url.

        *Return:*
            - None.

        *Examples*:
        | DELETE request | http://10.10.10.1:8082/environments |
        """
        self.response = requests.request('DELETE', url=url,
                                         headers=self.headers)

    def PUT_request(self, url):
        """
        Sends PUT request.

        *Arguments:*
            - url: destination url.

        *Return:*
            - None.

        *Examples*:
        | PUT request | http://10.10.10.1:8082/env |
        """
        debug_data = 'POST Request to URL: %s \n' \
                     'with Headers: %s \n' \
                     'and Body: %s' % (url, self.headers, self.body)
        logger.debug(debug_data)

        self.response = requests.request('PUT', url,
                                         headers=self.headers,
                                         data=self.body)
        logger.debug('Response: %s' % self.response.text)

    def get_response_code(self):
        """
        Gets response code.

        *Arguments:*
            - None.

        *Return:*
            - response code.

        *Examples*:
        | ${code} | Get Response Code |
        """
        return self.response.status_code

    def get_response_body(self):
        """
        Gets response body.

        *Arguments:*
            - None.

        *Return:*
            - response body.

        *Examples*:
        | ${body} | Get Response Body |
        """
        logger.debug('Response: %s' % self.response.text)
        if self.response.text is None:
            self.response.text = {}

        return json.loads(self.response.text)
