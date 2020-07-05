#!/usr/bin/python3.8
from argparse import ArgumentParser
import csv
from operator import itemgetter
from sys import stdin

class workout(object):
    def __init__(self, activity, route, duration_minutes=None, distance_miles=None, date=None, equipment=None):
        self.activity = activity
        self.route = route
        self.duration_minutes = duration_minutes
        self.distance_miles = distance_miles
        self.date = date
        self.equipment = equipment

    def __str__(self):
        keys = ["duration_minutes", "distance_miles", "date", "equipment",]
        options = " ".join(f"--{key}='{getattr(self, key)}'" for key in keys if getattr(self, key) is not None)
        return f"workout '{self.activity}' '{self.route}' {options}"

activity_ids = {
    "": -1,
    "bike": -1,
    "core": -1,
    "hiking": -1,
    "mountainbike": -1,
    "skiing": -1,
    "weights": -1,
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
    activity_id = activity_ids[row["Cross Train Type"]]
    route = row["Name"]
    duration_minutes = float(row["Minutes"]) + float(row["Seconds"]) / 60
    distance_miles = parse_distance(row["Distance"], row["Unit"])
    date = row["Date"]
    return workout(activity_id, route, duration_minutes, distance_miles, date)

def main():
    arg_parser = ArgumentParser()
    arg_parser.add_argument("file_name")
    args = arg_parser.parse_args()
    with open(args.file_name, "r") as log_file:
        reader = csv.DictReader(log_file)
        for row in reader:
            print(str(parse_workout(row)))

if __name__ == "__main__":
    main()
