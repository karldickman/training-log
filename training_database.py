from configparser import ConfigParser
from preview_database import PreviewDatabase
from psycopg2 import connect
from psycopg2.extensions import connection
from os.path import expanduser

def config(filename: str = "~/.workout.ini", section: str = "postgresql") -> "dict[str, str]":
    filename = expanduser(filename)
    parser = ConfigParser()
    parser.read(filename)
    database: "dict[str, str]" = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            database[param[0]] = param[1]
    else:
        raise Exception(f"Section {section} not found in the {filename} file.")
    return database

def new_connection(preview: bool = False) -> connection:
    """Open a new connection to the database."""
    if preview:
        return PreviewDatabase()
    params = config()
    return connect(**params)
