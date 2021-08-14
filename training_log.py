#!/usr/bin/python3.8
"""Command-line tool to log training to a database."""

from configparser import ConfigParser
from datetime import date as Date
from optparse import OptionParser as BaseOptionParser
from os.path import expanduser
from sys import argv
from psycopg2 import connect

def config(filename="~/.workout.ini", section="postgresql"):
    filename = expanduser(filename)
    parser = ConfigParser()
    parser.read(filename)
    database = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            database[param[0]] = param[1]
    else:
        raise Exception(f"Section {section} not found in the {filename} file.")
    return database

def record_activity(cursor, activity_date, activity_type_id, equipment_id,
        route, route_url, duration_minutes, distance_miles, notes,
        heart_rate_avg, heart_rate_max, inhaler):
    """Record an activity in the database using the specified parameters."""
    route = parse_route(route, route_url)
    params = (activity_date, activity_type_id, equipment_id, route.route_id,
        route.description, route.url, duration_minutes, distance_miles, notes,
        heart_rate_avg, heart_rate_max, inhaler)
    cursor.callproc("record_activity", params)
    (activity_id,) = cursor.fetchone()
    return activity_id

def new_connection(preview=False):
    """Open a new connection to the database."""
    if preview:
        return PreviewDatabase()
    params = config()
    return connect(**params)

def parse_arguments(arguments):
    """Parse the command-line arguments."""
    option_parser = OptionParser()
    return option_parser.parse_args(arguments)

def parse_route(route_string, route_url):
    """Convert a route string into route information."""
    with new_connection() as database, database.cursor() as cursor:
        cursor.callproc("get_route_id_by_name", (route_string,))
        (route_id,) = cursor.fetchone()
        if route_id is None:
            return Route(description=route_string, url=route_url)
        return Route(route_id=route_id, url=route_url)

def run_to_bike(distance_miles, duration_minutes):
    """Convert a bike ride to running miles."""
    duration_hours = duration_minutes / 60.0
    speed_mph = distance_miles / duration_hours
    return distance_miles * (0.0003736 * speed_mph ** 2 + 0.1973)

class OptionParser(BaseOptionParser):
    """Option parser for this command-line utility."""
    def __init__(self):
        usage_string = "%prog <activity> <route> [<duration hh:mm:ss>] [<distance miles>] [equipment] [<yyyy-mm-dd>] [notes]"
        BaseOptionParser.__init__(self, usage=usage_string)
        self.add_option("--duration", default=None,
                        help="The duration of the session.",
                        metavar="[HH:]MM:SS")
        self.add_option("--distance-miles", default=None,
                        help="The length of the session in miles.")
        self.add_option("--date", default=None,
                        help="The date on which the session occurred.")
        self.add_option("--equipment", default=None,
                        help="The equipment used for the session.")
        self.add_option("--hr-avg", default=None, type=float, help="Average heart rate.")
        self.add_option("--hr-max", default=None, type=float, help="Maximum heart rate.")
        self.add_option("--inhaler", action="store_true", dest="inhaler", help="Inhaler was used before this activity.")
        self.add_option("--no-inhaler", action="store_false", dest="inhaler", help="No inhaler was used before this activity.")
        self.add_option("--notes", default=None,
                        help="Additional notes on the activity.")
        self.add_option("--url", default=None, help="URL to route map")
        self.add_option("--quiet", default=False, action="store_true",
                        help="Suppress output")
        self.add_option("--preview", default=False, action="store_true",
                        help="Show but do not execute database commands.")

    def parse_args(self, arguments):
        options, arguments = BaseOptionParser.parse_args(self, arguments[1:])
        if len(arguments) < 2 or len(arguments) > 6:
            self.error("Incorrect number of arguments.")
        options.activity = self.parse_activity_type(arguments.pop(0))
        options.route = arguments.pop(0)
        if any(arguments):
            duration_string = arguments.pop(0)
            options.duration_minutes = self.parse_duration(duration_string)
        elif options.duration is not None:
            options.duration_minutes = self.parse_duration(options.duration)
        else:
            options.duration_minutes = None
        if any(arguments):
            if any(arguments):
                distance_string = arguments.pop(0)
            elif options.distance_miles is not None:
                distance_string = options.distance_miles
            else:
                distance_string = None
            options.distance_miles = self.parse_distance(distance_string)
        # Parse equipment
        if any(arguments):
            equipment_string = arguments.pop(0)
        else:
            equipment_string = options.equipment
        options.equipment_id = self.parse_equipment(equipment_string)
        # Parse date
        date_needs_parse = False
        if any(arguments):
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
        # Parse notes
        if any(arguments):
            options.notes = arguments.pop()
        return options, arguments

    def parse_activity_type(self, activity_type):
        """Convert an activity type string into a database identifier."""
        try:
            return int(activity_type)
        except ValueError:
            with new_connection() as database, database.cursor() as cursor:
                cursor.callproc("get_activity_type_id_by_name", (activity_type,))
                (activity_type_id,) = cursor.fetchone()
                if activity_type_id is None:
                    self.error(f"No activity type found in database matching {repr(activity_type)}")
                return activity_type_id

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

class PreviewCursor(object):
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, exc_traceback):
        pass

    def callproc(self, procedure, arguments):
        arguments = ", ".join(map(self.db_value, arguments))
        print(f"SELECT * FROM {procedure}({arguments})")

    def fetchone(self):
        return (None,)

    def db_value(self, value):
        if value is None:
            return "NULL"
        if isinstance(value, Date):
            return repr(value.strftime("%Y-%m-%d"))
        return repr(value)

class PreviewDatabase(object):
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, exc_traceback):
        pass

    def cursor(self):
        return PreviewCursor()

class Route(object):
    """Represents information about the route that was taken."""

    def __init__(self, route_id=None, description=None, url=None):
        self.route_id = route_id
        self.description = description
        self.url = url

    def __repr__(self):
        properties = ("route_id", "description", "url")
        property_values = map(lambda prop: (prop, getattr(self, prop)), properties)
        arguments = ", ".join(f"{prop}={repr(value)}" for (prop, value) in property_values if value is not None)
        return f"bike_log.Route({arguments})"

def main():
    """Process command line arguments and use them to write to the log."""
    option_parser = OptionParser()
    options, _ = option_parser.parse_args(argv)
    with new_connection(options.preview) as database, database.cursor() as cursor:
        ride_id = record_activity(cursor, options.date, options.activity, options.equipment_id, options.route,
                options.url, options.duration_minutes, options.distance_miles, options.notes,
                options.hr_avg, options.hr_max, options.inhaler)
        if not options.quiet and ride_id is not None:
            print(ride_id)

if __name__ == "__main__":
    main()
