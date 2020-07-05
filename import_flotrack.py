#!/usr/bin/python3.8
from argparse import ArgumentParser
import csv
from operator import itemgetter
from sys import stdin

class workout(object):
    def __init__(self, activity, route, duration_minutes=None, distance_miles=None, date=None, notes=None, preview=False):
        self.activity = activity
        self.route = route
        self.duration_minutes = duration_minutes
        self.distance_miles = distance_miles
        self.date = date
        self.notes = notes
        self.preview = preview

    def __str__(self):
        keys = ["duration_minutes", "distance_miles", "date", "notes",]
        options = " ".join(f"--{key}='{getattr(self, key)}'" for key in keys if getattr(self, key) is not None)
        preview = " --preview" if self.preview else ""
        return f"workout '{self.activity}' '{self.route}' {options}{preview}"

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

def parse_workout(row, preview):
    activity_id = activity_ids[row["Cross Train Type"].strip()]
    route = row["Name"].replace("\\", "").strip()
    duration_minutes = float(row["Minutes"]) + float(row["Seconds"]) / 60
    distance_miles = parse_distance(row["Distance"], row["Unit"])
    date = row["Date"].strip()
    notes = row["Notes"].strip() if row["Notes"] != "" else None
    return workout(activity_id, route, duration_minutes, distance_miles, date, notes, preview)

def main():
    arg_parser = ArgumentParser()
    arg_parser.add_argument("file_name")
    arg_parser.add_argument("--preview", default=False, action="store_true",
                            help="Show but do not execute database commands.")
    args = arg_parser.parse_args()
    with open(args.file_name, "r") as log_file:
        reader = csv.DictReader(log_file)
        for row in reader:
            print(str(parse_workout(row, args.preview)))

if __name__ == "__main__":
    main()
