#!/usr/bin/python
"""Command-line tool to parse a CSV file of intervals and store that in the database."""

from argparse import ArgumentParser, FileType
from datetime import datetime
from sys import exit, stdin
from training_database import new_connection

def parse_arguments():
    parser = ArgumentParser(
        prog = "workout-intervals",
        description = "Reads a CSV file containing workout intervals and saves that to the database.  distance (meters),duration (mm:ss)[,target split (seconds)[,target race (km)]]")
    parser.add_argument("activity_id", type = int, help = "The database ID of the activity whose intervals to record.")
    #parser.add_argument("date", type = lambda d: datetime.strptime(d, "%Y-%m-%d").date(), help = "The date of the interval workout")
    parser.add_argument("-f", "--file", type = FileType("r"), default = stdin, help = "The file containing the splits.  Defaults to STDIN.")
    parser.add_argument("--preview", action = "store_true", help = "Show but do not execute database commands.")
    return parser.parse_args()

def parse_file(file, activity_id):
    for interval, line in enumerate(file):
        try:
            row = line[0:-1].split(",")
            distance_meters = float(row[0])
            duration_datetime = datetime.strptime(row[1], "%M:%S.%f")
            duration_minutes = duration_datetime.minute * 60 + duration_datetime.second + duration_datetime.microsecond / 1_000_000
            target_split_seconds = float(row[2]) if len(row) > 2 else None
            target_race_distance_km = float(row[3]) if len(row) > 3 else None
        except ValueError as e:
            print("Syntax error in row", interval, row, str(e))
            return 1
        yield activity_id, interval + 1, distance_meters, duration_minutes, target_split_seconds, target_race_distance_km

def main():
    arguments = parse_arguments()
    interval_params = list(parse_file(arguments.file, arguments.activity_id))
    with new_connection(arguments.preview) as database, database.cursor() as cursor:
        for params in interval_params:
            cursor.callproc("record_interval", params)
    return 0

if __name__ == "__main__":
    exit(main())