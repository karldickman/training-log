#!/usr/bin/python
"""Upload a running log to Flotrack."""

from httplib import HTTPConnection as HttpConnection
from miscellaneous import main_function

def parse_arguments(arguments):
    usage = ""
    option_parser = OptionParser(usage)
    #And so on
    return option_parser.parse_args(arguments[1:])

#@main_function(parse_arguments)
def main():#options, arguments):
    flotrack_domain = "www.flotrack.org"
    request_url = "/running_logs/day/2013/04/01/user/karldickman"
    connection = HttpConnection(flotrack_domain)
    connection.set_debuglevel(1)
    connection.connect()
    request = connection.putrequest("POST", request_url)
    headers = { "Content-Type": "application/x-www-form-urlencoded",
               "User-Agent": "Dickman's Flotrack Upload Client",
               "Accept": "*/*", }
    for key, value in headers.iteritems():
        connection.putheader(key, value)
    connection.endheaders()
    data = "RunningLogResource%5Bdate%5D=2013-04-01&RunningLogResource%5Blog_type%5D=&RunningLogResource%5Blog_type%5D=run&RunningLogResource%5BcrossTrainType%5D=&RunningLogResource%5Bworkout%5D=&RunningLogResource%5Bworkout%5D=&RunningLogResource%5Btitle%5D=Test&RunningLogResource%5Bshow_on_menu%5D=0&RunningLogResource%5Bdate%5D=2013-04-01&RunningLogResource%5Bwarmup_mins%5D=&RunningLogResource%5Bwarmup_secs%5D=&RunningLogResource%5Bwarmup_distance%5D=&RunningLogResource%5Bwarmup_dist_unit%5D=miles&RunningLogResource%5Bwarmup_shoe_id%5D=&interval%5B0%5D%5Breps%5D=&interval%5B0%5D%5Bdistance%5D=&interval%5B0%5D%5Bdist_unit%5D=miles&interval%5B0%5D%5Brest%5D=&interval%5B0%5D%5Brest_unit%5D=secs&interval%5B0%5D%5Bcalculate_pace%5D=1&interval%5B0%5D%5Bshoe_id%5D=&RunningLogResource%5Bcooldown_mins%5D=&RunningLogResource%5Bcooldown_secs%5D=&RunningLogResource%5Bcooldown_distance%5D=&RunningLogResource%5Bcooldown_dist_unit%5D=miles&RunningLogResource%5Bcooldown_shoe_id%5D=&RunningLogResource%5Bmins%5D=3&RunningLogResource%5Bsecs%5D=14&RunningLogResource%5Bdistance%5D=3.14159&RunningLogResource%5Bdist_unit%5D=miles&RunningLogResource%5Bcalculate_pace%5D=0&RunningLogResource%5Bcalculate_pace%5D=1&RunningLogResource%5Bfeel%5D=&RunningLogResource%5Bfeel%5D=3&RunningLogResource%5Bfield1%5D=&RunningLogResource%5Bfield2%5D=&RunningLogResource%5Bshoe_id%5D=&RunningLogResource%5Bnotes%5D=&add_log="
    connection.send(data)
    response = connection.getresponse()
    print response.status
    print response.reason
    print response.read()
    connection.close()

if __name__ == "__main__":
    main()
