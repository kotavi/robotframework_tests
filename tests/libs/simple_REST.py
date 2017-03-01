import json
import requests
import logging


logging.basicConfig()
LOG = logging.getLogger(__name__)


class simple_REST:
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    __version__ = '0.1'

    headers = None
    body = None
    url = None

    def clear_headers(self):
        """
            This function allows to clear headers for REST API requests

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
        """
        self.headers = []

    def set_headers(self, headers_dict):
        """
            This function allows to configure headers for REST API requests

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
        """
        try:
            self.headers = json.loads(headers_dict)
        except:
            LOG.critical("Incorrect headers")
            LOG.critical(self.headers)

    def update_headers(self, key, value):
        """
            This function allows to modify headers for REST API requests

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
            | *Update Headers*  | X-Auth-Token | 8808880808080808 |
        """
        self.headers[key] = value

    def set_body(self, body_dict):
        """
            This function allows to configure body for REST API requests

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
            | *Set Body*        | {"name":"test"} |
            | *POST request*    | http://10.10.10.1:8082/environments |
        """
        self.body = body_dict

    def get_headers(self):
        """
            This function returns headers for REST API requests

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type  | application/json |
            | ${headers}        | *Get Headers* |
            | *LOG*             | ${headers}    |
        """
        return self.headers

    def GET_request(self, url):
        """
            This function allows to send GET requests

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
            | *GET request*     | http://10.10.10.1:8082/environments |
        """
        self.response = requests.request('GET', url=url, headers=self.headers, verify=False)

    def POST_request(self, url):
        """
            This function allows to send POST requests

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
            | *Set Body*        | {"name":"test"} |
            | *POST request*    | http://10.10.10.1:8082/environments |
        """
        self.response = requests.request('POST', url,
                                         headers=self.headers,
                                         data=str(self.body),
                                         verify=False)

    def POST_request_without_body(self, url):
        """
            This function allows to send POST requests

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
            | *Set Body*        | {"name":"test"} |
            | *POST request*    | http://10.10.10.1:8082/environments |
        """
        self.response = requests.request('POST', url,
                                         headers=self.headers)

    def DELETE_request(self, url):
        """
            This function allows to send DELETE requests

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
            | *DELETE request*  | http://10.10.10.1:8082/environments |
        """
        self.response = requests.request('DELETE', url=url,
                                         headers=self.headers,
                                         verify=False)

    def PUT_request(self, url):
        """
            This function allows to send PUT requests

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
            | *Set Body*        | {"name":"test-changed"} |
            | *PUT request*     | http://10.10.10.1:8082/634876 |
        """
        # :param files: (optional) Dictionary of 'name': file-like-objects (or {'name': ('filename', fileobj)}) for multipart encoding upload.
        self.response = requests.request('PUT', url,
                                         headers=self.headers,
                                         data=str(self.body),
                                         verify=False)

    def get_response_code(self):
        """
            This function allows to get response code

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
            | *DELETE request*  | http://10.10.10.1:8082/environments |
            | ${code}           | *Get Response Code* |
        """
        if self.response:
            if self.response.status_code != 200:
                LOG.debug(self.response.text)
        return self.response.status_code

    def get_response_headers(self):
        """
            This function allows to get response headers

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
            | *GET request*     | http://10.10.10.1:8082/environments |
            | ${body}           | *Get Response Headers* |
        """
        return self.response.headers

    def get_response_body(self):
        """
            This function allows to get response body

            Examples:
            | *Clear Headers*   |
            | *Set Headers*     | Content-Type | application/json |
            | *GET request*     | http://10.10.10.1:8082/environments |
            | ${body}           | *Get Response Body* |
        """
        try:
            return_text = json.loads(self.response.text)
        except:
            return_text = self.response.text
        return return_text


    def GET_request_with_auth(self, url, user, password):
        """
        :param url:
        :param user:
        :param password:
        :return:
        "auth" takes two parameters: username and password, so the actual statement should be
        """

        self.response = requests.get(url, auth=(user, password))

    def DELETE_request_with_auth(self, url, user, password):

        self.response = requests.delete(url=url, headers=self.headers, auth=(user, password))

    def POST_request_with_auth(self, url, user, password):

        self.response = requests.post(url, headers=self.headers,
                                      data=str(self.body),
                                      auth=(user, password))