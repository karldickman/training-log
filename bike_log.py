#!/usr/bin/python
"""Your docstring here."""

from datetime import date as Date
from flotrack_upload import FlotrackConnection
from getpass import getpass as prompt_for_password
from math import floor
from miscellaneous import main_function
from MySQLdb import connect as MySqlConnection
from optparse import OptionParser as BaseOptionParser

def log_ride(ride_date, bike_id, route, time_minutes, distance_miles):
    """Log a ride to the database and Flotrack using the specified parameters."""
    flotrack_password = prompt_for_password("Flotrack password: ")
    with FlotrackConnection("karldickman", flotrack_password) as flotrack, \
            new_connection() as database:
        log_ride_to_database(database, ride_date, bike_id, route, time_minutes,
                             distance_miles)
        log_ride_to_flotrack(flotrack, ride_date, bike_id, route, time_minutes,
                             distance_miles)

def log_ride_to_database(database, ride_date, bike_id, route, time_minutes, distance_miles):
    """Log a ride to the database using the specified parameters."""
    query = """INSERT INTO rides
        (ride_date, time_minutes, bicycle_id)
        VALUES
        (%s, %s, %s)"""
    database.execute(query, (ride_date, time_minutes, bike_id))
    query = "SELECT LAST_INSERT_ID()"
    database.execute(query)
    ride_id = database.fetchone()[0]
    if route.route_id is not None:
        query = """INSERT INTO ride_routes
            (ride_id, route_id)
            VALUES
            (%s, %s)"""
        database.execute(query, (ride_id, route.route_id))
    else:
        query = """INSERT INTO ride_descriptions
            (ride_id, ride_description)
            VALUES
            (%s, %s)"""
        database.execute(query, (ride_id, route.description))
    if distance_miles is not None:
        query = """INSERT INTO ride_distances
            (ride_id, distance_miles)
            VALUES
            (%s, %s)"""
        database.execute(query, (ride_id, distance_miles))

def log_ride_to_flotrack(flotrack, ride_date, bike_id, route, time_minutes,
                         distance_miles):
    """Log a ride to flotrack."""
    run_distance_miles = run_to_bike(distance_miles, time_minutes)
    run_time_minutes = run_distance_miles * 7.5
    minutes_component = int(floor(time_minutes))
    seconds_component = 60 * (time_minutes - minutes_component)
    notes = "Route: %s\nMiles: %.2lf\nMinutes: %d:%05.2lf"
    notes %= (route, distance_miles, minutes_component, seconds_component)
    success = flotrack.record_run(ride_date, "Commute (Bike)",
                                    run_distance_miles, run_time_minutes,
                                    notes)
    if not success:
        raise Exception("Could not write bike ride as run to Flotrack.")

def new_connection():
    """Open a new connection to the database."""
    database = MySqlConnection("localhost", "bike_log", "bike_log", "bike_log")
    database.autocommit(False)
    return database

def parse_arguments(arguments):
    """Parse the command-line arguments."""
    option_parser = OptionParser()
    return option_parser.parse_args(arguments)

def run_to_bike(distance_miles, time_minutes):
    """Convert a bike ride to running miles."""
    time_hours = time_minutes / 60.0
    speed_mph = distance_miles / time_hours
    return distance_miles * (0.0003736 * speed_mph ** 2 + 0.1973)

class OptionParser(BaseOptionParser):
    """Option parser for this command-line utility."""
    def __init__(self):
        usage_string = "%prog <route> <bike_id> <hh:mm>+[<hh:mm>]\
                [<miles>[+<more_miles>]] [<yyyy-mm-dd>]"
        BaseOptionParser.__init__(self, usage=usage_string)
        self.add_option("--flotrack", default=False, action="store_true",
                        help="Upload ride to flotrack")

    def parse_args(self, arguments):
        options, arguments = BaseOptionParser.parse_args(self, arguments[1:])
        if len(arguments) < 3:
            self.error("Incorrect number of arguments.")
        route_string = arguments[0]
        bike_string = arguments[1]
        time_string = arguments[2]
        options.route = self.parse_route(route_string)
        options.bike_id = self.parse_bicycle(bike_string)
        options.time_minutes = self.parse_time(time_string)
        if not hasattr(options, "distance_miles"):
            if len(arguments) > 3:
                distance_string = arguments[3]
                options.distance_miles = self.parse_distance(distance_string)
            elif options.route.route_id is None:
                self.error("Ride distance not specified.")
            else:
                options.distance_miles = None
        # Parse date
        if len(arguments) == 5 \
                or options.distance_miles is None and len(arguments) == 4:
            date_string = arguments[-1]
            try:
                year_string, month_string, day_string = date_string.split("-")
                ride_date = Date(int(year_string), int(month_string), \
                                 int(day_string))
            except ValueError:
                self.error("Improperly formatted date.")
        else:
            ride_date = Date.today()
        options.date = ride_date
        return options, []

    def parse_bicycle(self, bike_string):
        """Convert a bicycle string into a bicycle id."""
        with new_connection() as database:
            query = "SELECT bicycle_id FROM bicycle_names WHERE bicycle = %s"
            if database.execute(query, bike_string) > 0:
                return database.fetchone()[0]
            try:
                return int(bike_string)
            except ValueError:
                self.error("Improperly formatted bicycle ID.")

    def parse_distance(self, distance_string):
        """Convert a distance string into a decimal distance."""
        try:
            distance = 0.0
            for segment_distance_string in distance_string.split("+"):
                distance += float(segment_distance_string)
        except ValueError:
            self.error("Improperly formatted distance.")
        return distance

    def parse_route(self, route_string):
        """Convert a route string into route information."""
        with new_connection() as database:
            query = "SELECT route_id FROM routes WHERE route = %s"
            if database.execute(query, route_string) > 0:
                return Route(route_id=database.fetchone()[0])
            else:
                return Route(description=route_string)

    def parse_time(self, time_string):
        """Convert a time string into a decimal time."""
        try:
            time = 0.0
            for minute_second_string in time_string.split("+"):
                split_by_colon = minute_second_string.split(":")
                if len(split_by_colon) > 2:
                    self.error("Improperly formatted time.")
                minutes_string = split_by_colon[0]
                if len(split_by_colon) > 1:
                    seconds_string = split_by_colon[1]
                else:
                    seconds_string = 0
                time += float(minutes_string) + float(seconds_string) / 60.0
        except ValueError:
            self.error("Improperly formatted time.")
        return time

class Route(object):
    """Represents information about the route that was taken."""

    def __init__(self, route_id=None, description=None):
        self.route_id = route_id
        self.description = description

    def __repr__(self):
        return "bike_log.Route(%d, %s)" % \
                (self.route_id, repr(self.description))

@main_function(parse_arguments)
def main(options, arguments):
    """Process command line arguments and use them to write to the log."""
    options.flotrack = False
    if options.flotrack:
        log_ride(options.date, options.bike_id, options.route,
                options.time_minutes, options.distance_miles)
    else:
        with new_connection() as database:
            log_ride_to_database(database, options.date, options.bike_id,
                                 options.route, options.time_minutes,
                                 options.distance_miles)

if __name__ == "__main__":
    main()
