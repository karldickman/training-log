#!/usr/bin/python
"""Command-line tool to log training to a database."""

from configparser import ConfigParser
from datetime import date as Date
from getpass import getpass as prompt_for_password
from math import floor
from optparse import OptionParser as BaseOptionParser
from psycopg2 import connect
from sys import argv

def config(filename="database.ini", section="postgresql"):
    parser = ConfigParser()
    parser.read(filename)
    database = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            database[param[0]] = param[1]
    else:
        raise Exception(f"Section{section} not found in the {filename} file.")
    return database

def record_activity(cursor, activity_date, activity_type_id, equipment_id,
        route, duration_minutes, distance_miles):
    """Record an activity in the database using the specified parameters."""
    params = (activity_date, activity_type_id, equipment_id, route.route_id,
        route.description, duration_minutes, distance_miles)
    cursor.callproc("record_activity", params)
    (activity_id,) = cursor.fetchone()
    return activity_id

def new_connection():
    """Open a new connection to the database."""
    params = config()
    return connect(**params)

def parse_arguments(arguments):
    """Parse the command-line arguments."""
    option_parser = OptionParser()
    return option_parser.parse_args(arguments)

def parse_route(route_string):
    """Convert a route string into route information."""
    with new_connection() as database, database.cursor() as cursor:
        cursor.callproc("get_route_id_by_name", (route_string,))
        (route_id,) = cursor.fetchone()
        if route_id is None:
            return Route(description=route_string)
        return Route(route_id=route_id)

def run_to_bike(distance_miles, duration_minutes):
    """Convert a bike ride to running miles."""
    duration_hours = duration_minutes / 60.0
    speed_mph = distance_miles / duration_hours
    return distance_miles * (0.0003736 * speed_mph ** 2 + 0.1973)

class OptionParser(BaseOptionParser):
    """Option parser for this command-line utility."""
    def __init__(self):
        usage_string = "%prog <activity> <route> [<duration hh:mm:ss>] [<distance miles>] [<yyyy-mm-dd>]"
        BaseOptionParser.__init__(self, usage=usage_string)
        self.add_option("--equipment", default=None,
                        help="The equipment used for the session.")
        self.add_option("--date", default=None,
                        help="The date on which the session occurred.")
        self.add_option("--distance-miles", default=None,
                        help="The length of the session in miles.")
        self.add_option("--print-id", default=False, action="store_true",
                        help="Print the database ID of the recorded session.")
        self.add_option("--duration", default=None,
                        help="The duration of the session.",
                        metavar="[HH:]MM:SS")

    def parse_args(self, arguments):
        options, arguments = BaseOptionParser.parse_args(self, arguments[1:])
        if len(arguments) < 2 or len(arguments) > 5:
            self.error("Incorrect number of arguments.")
        options.activity = int(arguments.pop(0))
        route_string = arguments.pop(0)
        options.route = parse_route(route_string)
        if len(arguments) > 0:
            duration_string = arguments.pop(0)
            options.duration_minutes = self.parse_duration(duration_string)
        else:
            options.duration_minutes = None
        if options.route.route_id is None or len(arguments) > 0:
            if any(arguments):
                distance_string = arguments.pop(0)
            elif options.distance_miles is not None:
                distance_string = options.distance_miles
            else:
                distance_string = None
            options.distance_miles = self.parse_distance(distance_string)
        # Parse date
        date_needs_parse = False
        if len(arguments) > 0:
            date_string = arguments.pop(0)
            date_needs_parse = True
        elif isinstance(options.date, str):
            date_string = options.date
            date_needs_parse = True
        if date_needs_parse:
            try:
                date_components = date_string.split("-")
                num_components = len(date_components)
                if num_components > 3 or num_components < 2:
                    self.error("Improperly formatted date.")
                if num_components == 3:
                    year_string, month_string, day_string = date_components
                    year = int(year_string)
                elif num_components == 2:
                    month_string, day_string = date_components
                    year = Date.today().year
                options.date = Date(year, int(month_string), int(day_string))
            except ValueError:
                self.error("Improperly formatted date.")
        elif options.date is None:
            options.date = Date.today()
        options.equipment_id = self.parse_equipment(options.equipment)
        return options, arguments

    def parse_equipment(self, equipment_string):
        """Convert an equipment string into an equipment id."""
        if equipment_string is None:
            return None
        with new_connection() as database, database.cursor() as cursor:
            cursor.callproc("get_equipment_id_by_label", (equipment_string,))
            (equipment_id,) = cursor.fetchone()
            if equipment_id is not None:
                return equipment_id
            try:
                return int(equipment_string)
            except ValueError:
                self.error("Improperly formatted equipment.")

    def parse_distance(self, distance_string):
        """Convert a distance string into a decimal distance."""
        if distance_string is None:
            return None
        try:
            distance = 0.0
            for segment_distance_string in distance_string.split("+"):
                distance += float(segment_distance_string)
        except ValueError:
            self.error("Improperly formatted distance.")
        return distance


    def parse_duration(self, duration_string):
        """Convert a duration string into a decimal duration."""
        try:
            duration = 0.0
            for minute_second_string in duration_string.split("+"):
                split_by_colon = minute_second_string.split(":")
                if len(split_by_colon) > 3:
                    self.error("Improperly formatted duration.")
                seconds = float(split_by_colon.pop())
                if split_by_colon:
                    minutes = float(split_by_colon.pop())
                else:
                    minutes = 0
                if split_by_colon:
                    hours = float(split_by_colon.pop())
                else:
                    hours = 0
                duration += hours * 60.0 + minutes + seconds / 60.0
        except ValueError:
            self.error("Improperly formatted duration.")
        return duration

class Route(object):
    """Represents information about the route that was taken."""

    def __init__(self, route_id=None, description=None):
        self.route_id = route_id
        self.description = description

    def __repr__(self):
        if self.route_id is None:
            return "bike_log.Route(description='%s')" % repr(self.description)
        return "bike_log.Route(%d, %s)" % \
                (self.route_id, repr(self.description))

def main():
    """Process command line arguments and use them to write to the log."""
    option_parser = OptionParser()
    options, _ = option_parser.parse_args(argv)
    with new_connection() as database, database.cursor() as cursor:
        ride_id = record_activity(cursor, options.date, options.activity, options.equipment_id, options.route,
                options.duration_minutes, options.distance_miles)
        if options.print_id:
            print(ride_id)

if __name__ == "__main__":
    main()
