#!/usr/bin/python3.8
from argparse import ArgumentParser
from csv import reader
from sys import stdin

def main():
    arg_parser = ArgumentParser()
    arg_parser.add_argument("file_name")
    args = arg_parser.parse_args()
    with open(args.file_name, "r") as log_file:
        for row in reader(log_file):
            print(", ".join(row))

if __name__ == "__main__":
    main()
