#!/usr/bin/python
"""Your docstring here."""

from datetime import date
from miscellaneous import main_function
from MySQLdb import connect as MySqlConnection
from optparse import OptionParser

def log_ride(ride_date, route, distance, time, bike_id):
    route = route.replace("\\", "\\\\").replace("\"", "\\\"")
    connection = MySqlConnection("localhost", "bike_log", "bike_log", "bike_log")
    cursor = connection.cursor()
    query = """INSERT INTO rides
        (ride_date, ride, distance_miles, time_minutes, bicycle_id)
        VALUES
        ("%s", "%s", %lf, %lf, %d)"""
    query %= (ride_date.isoformat(), route, distance, time, bike_id)
    cursor.execute(query)
    connection.commit()
    connection.close()

def parse_arguments(arguments):
    usage_string = "%prog <route> <miles> <hh>:<mm> <bike_id> [--date=<yyyy-mm-dd>]"
    option_parser = OptionParser(usage = usage_string)
    option_parser.add_option("-d", "--date", help = "The date on which to log the ride.")
    #And so on
    options, arguments = option_parser.parse_args(arguments[1:])
    if len(arguments) != 4:
        option_parser.error("Incorrect number of arguments.")
    route, distance_string, time_string, bike_id_string = arguments
    # Parse distance
    try:
        distance = float(distance_string)
    except:
        option_parser.error("Improperly formatted distance.")
    # Parse time
    try:
        time = 0.0
        for minute_second_string in time_string.split("+"):
            minutes_string, seconds_string = minute_second_string.split(":")
            time += float(minutes_string) + float(seconds_string) / 60.0
    except:
        option_parser.error("Improperly formatted time.")
    # Parse bike ID
    try:
        bike_id = int(bike_id_string)
    except:
        option_parser.error("Improperly formatted bicycle ID.")
    # DONE!
    arguments = route, distance, time, bike_id
    if options.date is None:
        options.date = date.today()
    else:
        try:
            year_string, month_string, day_string = options.date.split("-")
            options.date = date(int(year_string), int(month_string), int(day_string))
        except:
            option_parser.error("Improperly formatted date.")
    return options, arguments

@main_function(parse_arguments)
def main(options, arguments):
    log_ride(options.date, *arguments)

if __name__ == "__main__":
    main()
