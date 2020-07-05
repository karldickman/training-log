#!/usr/bin/python3.8
from argparse import ArgumentParser
import csv
from operator import itemgetter
from sys import stdin

class workout(object):
    def __init__(self, activity, route, duration_minutes=None, distance_miles=None, date=None, notes=None):
        self.activity = activity
        self.route = route
        self.duration = duration_minutes
        self.distance_miles = distance_miles
        self.date = date
        self.notes = notes

    def __str__(self):
        bash = lambda string: string.replace('"', '\\"')
        route = bash(self.route)
        def option(key):
            value = getattr(self, key)
            try:
                value = bash(value)
            except AttributeError:
                pass
            key = key.replace("_", "-")
            return f'--{key}="{value}"'
        keys = ["duration", "distance_miles", "date", "notes",]
        options = " ".join(option(key) for key in keys if getattr(self, key) is not None)
        return f'workout "{self.activity}" "{route}" {options}'

activity_ids = {
    "": 1,
    "bike": 2,
    "core": 7,
    "hiking": 4,
    "mountainbike": 8,
    "skiing": 9,
    "weights": 10,
}

def parse_distance(distance, units):
    if distance == "":
        return None
    distance = float(distance)
    if units == "km":
        distance /= 1.609334
    elif units != "miles":
        raise Exception(f"Unknown units {units}")
    return distance

def parse_workout(row):
    activity_id = activity_ids[row["Cross Train Type"].strip()]
    route = row["Name"].replace("\\", "").strip()
    duration_minutes = float(row["Minutes"]) + float(row["Seconds"]) / 60
    distance_miles = parse_distance(row["Distance"], row["Unit"])
    date = row["Date"].strip()
    notes = row["Notes"].strip() if row["Notes"] != "" else None
    return workout(activity_id, route, duration_minutes, distance_miles, date, notes)

def main():
    arg_parser = ArgumentParser()
    arg_parser.add_argument("file_name")
    args = arg_parser.parse_args()
    is_bike = lambda name: "(bike)" in name.lower() or name.lower() in ["bike", "bike commute", "bike cross train", "work, bike shop, richie's, home"]
    with open(args.file_name, "r") as log_file:
        reader = csv.DictReader(log_file)
        for row in reader:
            command = str(parse_workout(row))
            if row["Cross Train Type"] == "" and is_bike(row["Name"]):
                command = command.replace("\n", " ")
                command = f"# Bike converted to run, skipping\n# {command}"
            print(command)

if __name__ == "__main__":
    main()
