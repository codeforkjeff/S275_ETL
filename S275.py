
import pandas as pd
import codecs
import collections
import csv
import datetime
import glob
import numpy as np
import pyodbc
import os
import re
import sqlalchemy
import sqlite3
import sys

try:
    from S275_settings import *
except:
    print("ERROR: could't import S275_settings module, check that you created that file. See the README.")
    sys.exit(1)

#### Parameters

LINE_TERMINATOR = u"\r\n"

# union of all column names found across files for all years.
# we list these explicitly here to eliminate variations in column order;
# this way, we can import all flat files into a single table
all_possible_columns = [
    "SchoolYear"
    ,"area"
    ,"cou"
    ,"dis"
    ,"codist"
    ,"LastName"
    ,"FirstName"
    ,"MiddleName"
    ,"lname"
    ,"fname"
    ,"mname"
    ,"cert"
    ,"bdate"
    ,"byr"
    ,"bmo"
    ,"bday"
    ,"sex"
    ,"ethnic"
    ,"hispanic"
    ,"race"
    ,"hdeg"
    ,"hyear"
    ,"acred"
    ,"icred"
    ,"bcred"
    ,"vcred"
    ,"exp"
    ,"camix"
    ,"camix1"
    ,"camix1A"
    ,"camix1S"
    ,"camix1Sa"
    ,"camix1SB"
    ,"ftehrs"
    ,"ftedays"
    ,"certfte"
    ,"clasfte"
    ,"certbase"
    ,"clasbase"
    ,"othersal"
    ,"tfinsal"
    ,"cins"
    ,"cman"
    ,"cbrtn"
    ,"clasflag"
    ,"certflag"
    # metadata field, probably
    # ,"ceridate"
    # don't know what this is, there's already a camix1
    #,"camix1S"
    ,"NBcertexpdate"
    ,"recno"
    # always NULL in the files
    #,"parea"
    ,"prog"
    ,"act"
    ,"darea"
    ,"droot"
    ,"dsufx"
    ,"grade"
    ,"bldgn"
    ,"asspct"
    ,"assfte"
    ,"asssal"
    ,"asshpy"
    ,"major"
    # metadata field, probably
    # ,"crasdate"
    ,"yr"
]

#### End Parameters

global_conn = None

def transform_raw_row(row):
    new_row = []
    for column_name in all_possible_columns:
        value = row.get(column_name)
        if value is not None:
            new_value = str(value).rstrip()
            if column_name in ['acred','icred','bcred','vcred','exp', 'ftehrs']:
                new_value = '%.1f' % (value)
            elif column_name in ['certfte']:
                new_value = '%.2f' % (value)
            elif column_name in ['ftedays','clasfte','asspct','assfte','asshpy']:
                new_value = '%.4f' % (value)
            elif column_name in ['camix','camix1','camix1A','camix1S','camix1Sa','camix1SB']:
                new_value = '%.5f' % (value)
            elif column_name in ['certbase','clasbase','othersal','tfinsal','cins','cman','asssal']:
                new_value = '%d' % (value)
        else:
            new_value = None
        new_row.append(new_value)
    return new_row


def transform_final_row(final_columns, row):
    """ row is a list of values """
    new_row = []
    i = 0
    for value in row:
        column_name = final_columns[i]
        if value is not None:
            new_value = str(value)
            if column_name in ['AssignmentPercent','AssignmentFTEDesignation']:
                new_value = '%.4f' % (value)
        else:
            new_value = ''
        new_row.append(new_value)
        i = i + 1
    return new_row


def pyodbc_row_to_dict(columns_in_result, row):
    d = {}
    for col in columns_in_result:
        value = getattr(row, col, None)
        d[col] = value
    return d


def strip_if_str(s):
    if s is None:
        return s
    return s.strip()


def empty_str_to_none(s):
    return None if s == '' else s


def create_flat_file(access_db_path, file_type, output_path):
    """ conform all the column names across tables and write to flat files """
    print("Processing %s" % (access_db_path))

    connectionString = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=%s" % access_db_path
    dbConnection = pyodbc.connect(connectionString)
    cursor = dbConnection.cursor()

    f = codecs.open(output_path, "w", 'utf-8')
    f.write("\t".join(all_possible_columns + ['FileType']))
    f.write(LINE_TERMINATOR)
    f.flush()

    to_file_value = lambda s: '' if s is None else s

    for table_entry in cursor.tables(tableType='TABLE'):
        table_name = table_entry[2]

        print("Found table: %s" % (table_name))

        # for row in cursor.columns(table=table_name):
        #     print("Field name: %s, Type: %s, Width: %s" % (row.column_name,row.type_name,row.column_size))

        print("Creating flat file for table %s, hang on..." % (table_name))
        cursor.execute("Select * From [%s]" % (table_name))

        rows = cursor.fetchall()

        columns_in_result = [column[0] for column in cursor.description]

        print("Writing rows to file...")

        for row in rows:
            row = pyodbc_row_to_dict(columns_in_result, row)

            values = [to_file_value(value) for value in transform_raw_row(row)]
            f.write("\t".join(values + [file_type]))
            f.write(LINE_TERMINATOR)

        f.flush()

    dbConnection.close()

    f.close()


def create_teacher_assignments():
    print("creating teachers")
    execute_sql_file("create_teachers.sql")

    print("creating all teacher assignments")
    execute_sql_file("create_teacher_assignments_all.sql")

    print("creating teacher assignments")
    execute_sql_file("create_teacher_assignments.sql")

    print("Writing output file...")
    output_teacher_assignments()


def create_dimensional_models():
    print("creating dimensional models")

    execute_sql_file("create_Dim_School.sql")
    load_into_database([('Dim_school.txt', 'Dim_School')])

    execute_sql_file("create_dimensional_models.sql")


def create_teacher_mobility():
    print("creating teacher mobility tables (single teacher per year)")
    execute_sql_file("create_teacher_mobility.sql")


def create_aggregations():
    print("creating teacher mobility aggregations")
    execute_sql_file("create_teacher_mobility_aggregations.sql")


def execute_sql_file(path):
    """ files should default to using SQL Server dialect; we do some translation here """
    conn = get_db_conn()
    cursor = conn.cursor()
    str = open(path).read()
    statements = str.split("-- next")
    for statement in statements:
        if db_type == "sqlite":
            statement = statement.replace("LEN(", "LENGTH(")
            statement = statement.replace("SUBSTRING(", "SUBSTR(")
            statement = statement.replace("INT IDENTITY(1,1) NOT NULL PRIMARY KEY", "INTEGER PRIMARY KEY AUTOINCREMENT")
            # handle ||
            lines = statement.split("\n")
            transformed = []
            for line in lines:
                if "sqlite_concat" in line:
                    line = line.replace("+", "||")
                transformed.append(line)
            statement = "\n".join(transformed)

        print("RUNNING: " + statement)
        cursor.execute(statement)
        conn.commit()


def load_into_database(entries):
    """ entries should be a tuple of (path, tablename) """

    if db_type == 'SQL Server':
        for (output_file, table_name) in entries:
            os.system("bcp %s in \"%s\" -T -S %s -d %s -F 2 -t \\t -c -b 10000" % (table_name, output_file, db_sqlserver_host, db_sqlserver_database))
    else:
        # read in the flat files and load into sqlite
        conn = get_db_conn()
        cursor = conn.cursor()
        for (output_file, table_name) in entries:
            print("Loading %s" % (output_file,))
            f = codecs.open(output_file, 'r', 'utf-8')
            column_names = f.readline().split("\t")

            eof = False

            while not eof:
                batch = []
                count = 0
                keep_going = True
                while keep_going:
                    line = f.readline().strip("\n").strip("\r")
                    values = [empty_str_to_none(value) for value in line.split("\t")]
                    if line != '':
                        batch.append(values)
                    else:
                        keep_going = False
                        eof = True
                    count = count + 1
                    if count > 100000:
                        keep_going = False

                if len(batch) > 0:
                    print("Writing batch to staging db...")
                    cursor.executemany('INSERT INTO %s VALUES (%s)' % (table_name, ",".join(["?" for x in range(len(column_names))])), batch)
                    conn.commit()


def create_auxiliary_tables():
    execute_sql_file("create_dutycodes.sql")
    load_into_database([('dutycodes.txt', 'DutyCodes')])


def create_base_S275():
    output_files = []
    for entry in source_files:
        path = entry[0]
        file_type = entry[1]
        basename = os.path.basename(path)
        output_file = os.path.join(output_dir, basename[0:basename.rindex(".")] + ".txt")

        if not os.path.exists(output_file):
            create_flat_file(path, file_type, output_file)
        else:
            print("%s already exists, skipping" % (output_file,))

        output_files.append(output_file)

    execute_sql_file("create_Raw_S275.sql")
    load_into_database([(output_file, 'Raw_S275') for output_file in output_files])
    execute_sql_file("create_Cleaned_S275.sql")

def output_teacher_assignments():
    conn = get_db_conn()
    cursor = conn.cursor()

    cursor.execute("Select * From TeacherAssignments")

    output_columns = [item[0] for item in cursor.description]

    output_file = os.path.join(output_dir, "teacher_assignments.txt")

    f = open(output_file, "w")
    f.write("\t".join(output_columns))
    f.write("\n")
    f.flush()

    keep_going = True
    while keep_going:
        rows = cursor.fetchmany(100000)
        keep_going = False
        for row in rows:
            f.write("\t".join(transform_final_row(output_columns, row)))
            f.write("\n")
            keep_going = True
        f.flush()

    f.close()

    conn.close()


def get_db_conn():
    global global_conn
    if global_conn is None:
        if db_type == "SQL Server":
            global_conn = pyodbc.connect(db_pyodbc_connection_string)
        elif db_type == "sqlite":
            global_conn = sqlite3.connect(db_sqlite_path)
        else:
            raise "Unrecognized db_type: %s" % (db_type,)
    return global_conn


def create_year_range(years_str):
    """ returns list of  years """
    if "-" in years_str:
        pieces = years_str.split("-")
        return list(range(int(pieces[0]), int(pieces[1]) + 1))
    return [int(years_str)]

