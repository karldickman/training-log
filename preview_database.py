from datetime import date as Date

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
