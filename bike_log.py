#!/usr/bin/python
"""Your docstring here."""

from datetime import date as Date
from flotrack_upload import FlotrackConnection
from getpass import getpass as prompt_for_password
from math import floor
from miscellaneous import main_function
from MySQLdb import connect as MySqlConnection
from optparse import OptionParser as BaseOptionParser

def log_ride_to_database(database, ride_date, bike_id, route, time_minutes,
                         distance_miles):
    """Log a ride to the database using the specified parameters."""
    query = """INSERT INTO rides
        (ride_date, bicycle_id)
        VALUES
        (%s, %s)"""
    database.execute(query, (ride_date, bike_id))
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
    if time_minutes is not None:
        query = """INSERT INTO ride_durations
            (ride_id, duration_minutes)
            VALUES
            (%s, %s)"""
        database.execute(query, (ride_id, time_minutes))
    if distance_miles is not None:
        query = """INSERT INTO ride_non_route_distances
            (ride_id, distance_miles)
            VALUES
            (%s, %s)"""
        database.execute(query, (ride_id, distance_miles))
    return ride_id

def log_ride_to_flotrack(flotrack, ride_date, route, time_minutes,
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

def parse_route(route_string):
    """Convert a route string into route information."""
    with new_connection() as database:
        query = "SELECT route_id FROM routes WHERE route = %s"
        if database.execute(query, route_string) > 0:
            return Route(route_id=database.fetchone()[0])
        else:
            return Route(description=route_string)

def run_to_bike(distance_miles, time_minutes):
    """Convert a bike ride to running miles."""
    time_hours = time_minutes / 60.0
    speed_mph = distance_miles / time_hours
    return distance_miles * (0.0003736 * speed_mph ** 2 + 0.1973)

class OptionParser(BaseOptionParser):
    """Option parser for this command-line utility."""
    def __init__(self):
        usage_string = "%prog <route> <bike_id> [--time=][<[hh:]mm:ss>+[[<hh:]mm:ss>]] [--distance-miles=][<miles>[+<more_miles>]] [--date=][<yyyy-mm-dd>]"
        BaseOptionParser.__init__(self, usage=usage_string)
        self.add_option("--date", default=None,
                        help="The date on which the ride occurred.")
        self.add_option("--distance-miles", default=None,
                        help="The length of the ride in miles.")
        self.add_option("-V", "--preview", default=False, action="store_true",
                        help="Print SQL commands instead of executing them.")
        self.add_option("-F", "--flotrack", default=False, action="store_true",
                        help="Upload ride to flotrack")
        self.add_option("--print-id", default=False, action="store_true",
                        help="Print the database ID of the recorded ride.")

    def parse_args(self, arguments):
        options, arguments = BaseOptionParser.parse_args(self, arguments[1:])
        if len(arguments) < 2 or len(arguments) > 5:
            self.error("Incorrect number of arguments.")
        route_string = arguments.pop(0)
        bike_string = arguments.pop(0)
        options.route = parse_route(route_string)
        options.bike_id = self.parse_bicycle(bike_string)
        if len(arguments) > 0:
            time_string = arguments.pop(0)
            options.time_minutes = self.parse_time(time_string)
        else:
            options.time_minutes = None
        if options.route.route_id is None or len(arguments) > 0:
            if any(arguments):
                distance_string = arguments.pop(0)
            else:
                distance_string = options.distance_miles
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
        if options.preview and options.flotrack:
            self.error("Options --preview and --flotrack are incompatible.")
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


    def parse_time(self, time_string):
        """Convert a time string into a decimal time."""
        try:
            time = 0.0
            for minute_second_string in time_string.split("+"):
                split_by_colon = minute_second_string.split(":")
                if len(split_by_colon) > 3:
                    self.error("Improperly formatted time.")
                seconds = float(split_by_colon.pop())
                if split_by_colon:
                    minutes = float(split_by_colon.pop())
                else:
                    minutes = 0
                if split_by_colon:
                    hours = float(split_by_colon.pop())
                else:
                    hours = 0
                time += hours * 60.0 + minutes + seconds / 60.0
        except ValueError:
            self.error("Improperly formatted time.")
        return time

class DebugDatabase(object):
    """Instead of executing SQL statements, writes them to the console."""

    def __init__(self, database):
        """Construct a new DebugDatabase"""
        self.database = database

    def execute(self, sql_to_execute, sql_parameters=None):
        """Pretend to execute an SQL command"""
        self.executed_query = sql_to_execute
        if self.modifies_database(sql_to_execute):
            print sql_to_execute % self.literals(sql_parameters)
        else:
            self.database.execute(sql_to_execute, sql_parameters)

    def fetchone(self):
        """Fetch a result from the database"""
        if self.executed_query == "SELECT LAST_INSERT_ID()":
            return LastInsertId(),
        return self.database.fetchone()

    @staticmethod
    def literal(sql_parameter, sql_literal):
        if isinstance(sql_parameter, LastInsertId):
            return "LAST_INSERT_ID()"
        return sql_literal

    def literals(self, sql_parameters=None):
        parameter_literals = self.database.connection.literal(sql_parameters)
        return tuple(self.literal(p, l) for p, l in zip(sql_parameters, parameter_literals))

    @staticmethod
    def modifies_database(sql_to_execute):
        """Determine if the specified SQL command modifies the database"""
        return sql_to_execute.startswith("INSERT") \
                or sql_to_execute.startswith("UPDATE")

class LastInsertId(object):
    pass

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

@main_function(parse_arguments)
def main(options, arguments):
    """Process command line arguments and use them to write to the log."""
    options.flotrack = False
    with new_connection() as sql_database:
        database = sql_database
        if options.preview:
            database = DebugDatabase(sql_database)
        ride_id = log_ride_to_database(database, options.date, options.bike_id,
                                       options.route, options.time_minutes,
                                       options.distance_miles)
        if options.print_id:
            print ride_id
        if ride_id > 0 and options.flotrack:
            flotrack_password = prompt_for_password("Flotrack password")
            with FlotrackConnection("karldickman", flotrack_password) \
                as flotrack:
                log_ride_to_flotrack(flotrack, options.date,
                                     options.route.description,
                                     options.time_minutes,
                                     options.distance_miles)


if __name__ == "__main__":
    main()
