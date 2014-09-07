#!/usr/bin/python
"""Upload a running log to Flotrack."""

from cookielib import MozillaCookieJar
from datetime import date as Date
from getpass import getpass as prompt_for_password
from httplib import HTTPConnection as HttpConnection
from httplib import FOUND
from httplib import OK
from math import floor
from miscellaneous import main_function
from optparse import OptionParser
from os import path
from urllib import urlencode as url_encode

class FlotrackConnection(object):
    """Provides an interface for connecting to the Flotrack website
    and logging runs."""

    # The domain name of the flotrack website
    flotrack_domain = "www.flotrack.org"
    # The URL to use to log in
    login_url = "/site/login"
    # The URL to use to log out
    logout_url = "/site/logout"
    # The URL to use to record runs
    running_log_url = "/running_logs/new/%s"
    # The file containing the cookies
    cookie_file = "/home/karl/.flotrack-cookies"

    def __enter__(self):
        self.cookie_jar.load()
        if not self.login(self.username, self.password):
            raise Exception("Invalid flotrack password.")
        return self

    def __exit__(self, type_, value, tb):
        try:
            self.cookie_jar.save()
            self.connection.close()
        except:
            pass

    def __init__(self, username, password, debug_level=0):
        self.username = username
        self.password = password
        if not path.exists(self.cookie_file):
            with open(self.cookie_file, "w+"):
                pass
        self.cookie_jar = MozillaCookieJar(self.cookie_file)
        self.debug_level = debug_level

    def get_default_headers(self, content, content_type=None):
        content_type = "application/x-www-form-urlencoded"
        cookies = "; ".join(("%s=%s" % (c.name, c.value) for c in self.cookie_jar))
        return { "Accept": "text/html,application/xhtml+xml",
                "Accept-Encoding": "gzip, deflate",
                "Accept-Language": "en-US,en",
                "Content-Length": len(content),
                "Content-Type": content_type,
                "Connection": "keep-alive",
                "Cookie": cookies, }

    def get_running_log_params(self, date, route, distance_miles, time_minutes, notes):
        minutes_component = floor(time_minutes)
        seconds_component = (time_minutes - minutes_component) * 60
        date_string = date.isoformat()
        run_info = [("date", date_string),
                    ("log_type", ""),
                    ("log_type", "run"),
                    ("crossTrainType", ""),
                    ("workout", ""),
                    ("workout", ""),
                    ("title", route),
                    ("show_on_menu", 0),
                    ("date", date_string),
                    ("warmup_mins", ""),
                    ("warmup_secs", ""),
                    ("warmup_distance", ""),
                    ("warmup_dist_unit", "miles"),
                    ("warmup_shoe_id", ""),
                    ("add_log", ""),
                    ("interval[0][reps]", ""),
                    ("interval[0][distance]", ""),
                    ("interval[0][dist_unit]", "miles"),
                    ("interval[0][rest]", ""),
                    ("interval[0][rest_unit]", "secs"),
                    ("interval[0][calculate_pace]", 1),
                    ("interval[0][shoe_id]", ""),
                    ("cooldown_mins", ""),
                    ("cooldown_secs", ""),
                    ("cooldown_distance", ""),
                    ("cooldown_dist_unit", "miles"),
                    ("cooldown_shoe_id", ""),
                    ("mins", int(minutes_component)),
                    ("secs", int(seconds_component)),
                    ("distance", distance_miles),
                    ("dist_unit", "miles"),
                    ("calculate_pace", 0),
                    ("calculate_pace", 1),
                    ("feel", ""),
                    ("field1", ""),
                    ("field2", ""),
                    ("shoe_id", ""),
                    ("notes", notes),
                    ("add_log", ""),]
        for i in range(len(run_info)):
            key = run_info[i][0]
            value = run_info[i][1]
            if key != "add_log" and "interval[0]" not in key:
                key = "RunningLogResource[%s]" % key
                run_info[i] = (key, value)
        return url_encode(run_info)

    def get_running_log_url(self, date):
        date_string = format(date, "%Y/%m/%d")
        return self.running_log_url % date_string

    def login(self, username, password):
        connection = HttpConnection(self.flotrack_domain)
        connection.set_debuglevel(self.debug_level)
        connection.connect()
        # Configure login parameters (this is the content of the HTTP request)
        params = { "LoginForm[username]": username,
                   "LoginForm[password]": password,
                   "LoginForm[rememberMe]": 1, }
        encoded_params = url_encode(params)
        # Get the HTTP headers to use
        headers = self.get_default_headers(encoded_params)
        del headers["Cookie"]
        # Configure the cookie jar to store the login information
        cookie_request = HttpRequestAdapter(self.flotrack_domain, self.login_url,
                                            headers)
        self.cookie_jar.add_cookie_header(cookie_request)
        # Issue the HTTP request
        request = connection.request("POST", self.login_url, encoded_params, headers)
        response = connection.getresponse()
        if response.status == OK:
            return False
        if response.status == FOUND:
            response.read()
            response.info = lambda: response.msg
            # Extract the login cookies
            self.cookie_jar.extract_cookies(response, cookie_request)
            self.connection = connection
            return True
        raise Exception("Flotrack connection failed during login.")

    def logout(self):
        request = self.connection.request("GET", self.logout_url)
        response = self.connection.getresponse()
        if response.status == OK:
            return False
        if response.status == FOUND:
            return True
        raise Exception("Flotrack connection failed during logout.")

    def record_run(self, date, route, distance_miles, time_minutes, notes=""):
        # Create parameters to pass to the log
        encoded_params = self.get_running_log_params(date, route, distance_miles, time_minutes, notes)
        # Post the data to the server
        headers = self.get_default_headers(encoded_params)
        running_log_url = self.get_running_log_url(date)
        request = self.connection.request("POST", running_log_url, encoded_params, headers)
        response = self.connection.getresponse()
        if response.status == OK:
            return False
        if response.status == FOUND:
            response.read()
            return True
        raise Exception("Flotrack connection failed while recording run.")

class HttpRequestAdapter(object):
    """Data container for HTTP request (used for cookie processing)."""

    def __init__(self, host, url, headers={}):
        self._host = host
        self._url = url
        self._headers = {}
        for key, value in headers.items():
            self.add_header(key, value)

    def has_header(self, name):
        return name in self._headers

    def add_header(self, key, val):
        self._headers[key.capitalize()] = val

    def add_unredirected_header(self, key, val):
        self._headers[key.capitalize()] = val

    def is_unverifiable(self):
        return True

    def get_type(self):
        return "http"

    def get_full_url(self):
        # TODO: implement other protocols support
        return "http://" + self._host[0] + ":" + str(self._host[1]) + self._url

    def get_header(self, header_name, default=None):
        return self._headers.get( header_name, default )

    def get_host(self):
        return self._host[0]

    get_origin_req_host = get_host

    def get_headers(self):
        return self._headers

def parse_arguments(arguments):
    usage = "%prog USER"
    option_parser = OptionParser(usage)
    options, arguments = option_parser.parse_args(arguments[1:])
    if len(arguments) != 1:
        option_parser.error("Incorrect number of arguments.")
    options.username = arguments[0]
    return options, []

@main_function(parse_arguments)
def main(options, arguments):
    password = prompt_for_password("Flotrack password: ")
    with FlotrackConnection(options.username, password) as connection:
        connection.record_run(Date.today(), "Test", 3.14159, 3 + 14.0 / 60)

if __name__ == "__main__":
    main()
