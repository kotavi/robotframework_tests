import logging
import web
import threading
from time import sleep
from robot.libraries.BuiltIn import BuiltIn

LOG = logging.getLogger(__name__)


class CallbackClientError(Exception):
    def __init__(self, msg):
        super(CallbackClientError, self).__init__(msg)


class SaveRequest():
    def __init__(self):
        self.call_client = CallbackClient()

    def POST(self, url):
        raw_data = web.data()
        self.call_client._add_request({url: raw_data})
        web.ctx.status = '200'
        return "OK"


class FailResponse():
    def __init__(self):
        self.call_client = CallbackClient()

    def POST(self, code):
        raw_data = web.data()
        self.call_client._add_request({code: raw_data})
        web.ctx.status = code
        return "FAILED"


class CallbackClient(object):

    ROBOT_LIBRARY_SCOPE = 'GLOBAL' #global?????

    requests = []

    def run_callback_client(self):
        try:
            port = BuiltIn().replace_variables('${callback_port}')
            args = (port,)
        except:
            args = ()
        self._thread = threading.Thread(target=self._run, args=args)
        self._thread.setDaemon(True)
        self._thread.start()

    def check_post_request(self, url, message):
        """
        Method checks whether post request was received or not
        Returns True, error message otherwise
        """
        hits = len([k for req in self.get_all_requests()
                    for k, v in req.iteritems()
                    if k == url and v == message])
        if hits == 1:
            return True
        # if hits != 1 or hits > 1:
        #     return hits
        elif hits == 0:
            msg = 'Request with url: %s and message: %s not found'
        elif hits > 1:
            msg = 'Multiple requests with url: %s and message: %s'
        raise CallbackClientError(msg % (url, message))

    def get_count_of_requests(self, url, message=None):
        """
        Returns number of POST requests sent to specified url
        """
        if message:
            return len([k for req in self.get_all_requests()
                        for k, v in req.iteritems()
                        if k == url and v == message])
        else:
            return len([k for req in self.get_all_requests()
                        for k in req.keys()
                        if k == url])

    def get_all_requests(self):
        """
        Returns all POST requests
        """
        LOG.info('self.requests:  ', self.requests)
        return self.requests

    def delete_all_requests(self):
        """
        Deletes all requests
        """
        self.requests = []

    def wait_until_request_come(self):
        """
        Waits until at least one request comes
        """
        # at least one request
        timeout = 600
        initial = len(self.get_all_requests())
        for i in range(timeout):
            if len(self.get_all_requests()) > initial:
                return True
            sleep(1)
        raise CallbackClientError("Request has not come")

    def wait_until_message_come(self, url, message):
        """
        Waits until the expected message comes to the specified url
        """
        timeout = 600
        hits = 0
        while hits == 0:
            hits = self.get_count_of_requests(url, message)
            sleep(1)
        raise CallbackClientError("Request has not come")

    def _add_request(self, request):
        self.requests.append(request)

    def _run(self, port=8080, ip_address='0.0.0.0', *middleware):
        url = (
            '/failresponse/(\d{3})', 'FailResponse',
            '/(.+)', 'SaveRequest'
        )
        app = web.application(url, globals())
        try:
            return web.httpserver.runsimple(app.wsgifunc(), (ip_address, int(port)))
        except Exception as e:
            raise CallbackClientError(e.message)

    def thread_count(self):
        return threading.active_count()

    def thread_current(self):
        return threading.current_thread()

    def thread_enumerate(self):
        return threading.enumerate()

    def __del__(self):
        try:
            self._thread.cleanup()
            self._thread.join()
        except Exception:
            LOG.critical("Callback client was not stopped")
            pass