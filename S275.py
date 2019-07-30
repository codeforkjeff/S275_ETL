
import pandas as pd
import csv
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

# columns from source data to stage
raw_columns = [
    "SchoolYear"
    ,"area"
    ,"cou"
    ,"dis"
    ,"codist"
    ,"LastName"
    ,"FirstName"
    ,"MiddleName"
    ,"cert"
    ,"bdate"
    ,"sex"
    ,"hispanic"
    ,"race"
    ,"hdeg"
    ,"hyear"
    ,"acred"
    ,"icred"
    ,"bcred"
    ,"vcred"
    ,"exp"
    ,"camix1"
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

column_names_map = {
    "SchoolYear": "AcademicYear"
    ,"area": "Area"
    ,"cou": "County"
    ,"dis": "District"
    ,"codist": "CountyAndDistrictCode"
    ,"LastName": "LastName"
    ,"FirstName": "FirstName"
    ,"MiddleName": "MiddleName"
    ,"cert": "CertificateNumber"
    ,"bdate": "Birthdate"
    ,"sex": "Sex"
    ,"hispanic": "Hispanic"
    ,"race": "Race"
    ,"hdeg": "HighestDegree"
    ,"hyear": "HighestDegreeYear"
    ,"acred": "AcademicCredits"
    ,"icred": "InServiceCredits"
    ,"bcred": "ExcessCredits"
    ,"vcred": "NonDegreeCredits"
    ,"exp": "CertYearsOfExperience"
    ,"camix1": "StaffMixFactor"
    ,"ftehrs": "FTEHours"
    ,"ftedays": "FTEDays"
    ,"certfte": "CertificatedFTE"
    ,"clasfte": "ClassifiedFTE"
    ,"certbase": "CertificatedBase"
    ,"clasbase": "ClassifiedBase"
    ,"othersal": "OtherSalary"
    ,"tfinsal": "TotalFinalSalary"
    ,"cins": "ActualAnnualInsurance"
    ,"cman": "ActualAnnualMandatory"
    ,"cbrtn": "CBRTNCode"
    ,"clasflag": "ClassificationFlag"
    ,"certflag": "CertifiedFlag"
    ,"NBcertexpdate": "NationalBoardCertExpirationDate"
    ,"recno": "RecordNumber"
    ,"prog": "ProgramCode"
    ,"act": "ActivityCode"
    ,"darea": "DutyArea"
    ,"droot": "DutyRoot"
    ,"dsufx": "DutySuffix"
    ,"grade": "Grade"
    ,"bldgn": "Building"
    ,"asspct": "AssignmentPercent"
    ,"assfte": "AssignmentFTEDesignation"
    ,"asssal": "AssignmentSalaryTotal"
    ,"asshpy": "AssignmentHoursPerYear"
    ,"major": "Major"
    ,"yr": "TwoDigitYear"
}

cleaned_column_names = [column_names_map[col] for col in raw_columns]

#### End Parameters

global_conn = None

def transform_raw_row(raw_columns, row):
    new_row = []
    for column_name in raw_columns:
        value = getattr(row, column_name, None)
        if value is not None:
            new_value = str(value).rstrip()
            if column_name == 'SchoolYear':
                new_value = value[-4:]
            elif column_name in ['acred','icred','bcred','vcred','exp', 'ftehrs']:
                new_value = '%.1f' % (value)
            elif column_name in ['certfte']:
                new_value = '%.2f' % (value)
            elif column_name in ['ftedays','clasfte', 'camix1S','asspct','assfte','asshpy']:
                new_value = '%.4f' % (value)
            elif column_name in ['camix1']:
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


def fix_bad_data(row):
    hyear = getattr(row, 'hyear', None)
    if hyear == '07':
        row['hyear'] = '2007'
    elif hyear == '13':
        row['hyear'] = '2013'
    elif hyear == 'B0':
        row['hyear'] = None
    return row


def create_flat_file(access_db_path, file_type, output_path):

    print("Processing %s" % (access_db_path))

    connectionString = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=%s" % access_db_path
    dbConnection = pyodbc.connect(connectionString)
    cursor = dbConnection.cursor()

    f = open(output_path, "w")
    f.write("\t".join(cleaned_column_names + ['FileType']))
    f.write("\n")
    f.flush()

    to_file_value = lambda s: '' if s is None else s

    for table_entry in cursor.tables(tableType='TABLE'):
        table_name = table_entry[2]

        print("Found table: %s" % (table_name))

        # for row in cursor.columns(table=table_name):
        #     print("Field name: %s, Type: %s, Width: %s" % (row.column_name,row.type_name,row.column_size))

        print("Loading table %s, hang on..." % (table_name))
        cursor.execute("Select * From [%s]" % (table_name))

        rows = cursor.fetchall()

        print("Writing rows to file...")

        for row in rows:
            row = fix_bad_data(row)
            values = [to_file_value(value) for value in transform_raw_row(raw_columns, row)]
            f.write("\t".join(values + [file_type]))
            f.write("\n")

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
    execute_sql_file("create_dimensional_models.sql")


def execute_sql_file(path):
    """ files should default to using SQL Server dialect; we do some translation here """
    conn = get_db_conn()
    cursor = conn.cursor()
    str = open(path).read()
    statements = str.split("-- next")
    for statement in statements:
        if db_type == "sqlite":
            statement = statement.replace("LEN(", "LENGTH(")
            statement = statement.replace("INT IDENTITY(1,1) NOT NULL PRIMARY KEY", "INTEGER PRIMARY KEY AUTOINCREMENT")
        print("RUNNING: " + statement)
        cursor.execute(statement)
        conn.commit()


def create_base_S275():
    execute_sql_file("create_s275.sql")

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

    if db_type == 'SQL Server':
        for output_file in output_files:
            os.system("bcp S275 in \"%s\" -T -S %s -d %s -F 2 -t \\t -c -b 10000" % (output_file, db_sqlserver_host, db_sqlserver_database))
    else:
        # read in the flat files and load into sqlite
        conn = get_db_conn()
        cursor = conn.cursor()
        for output_file in output_files:
            f = open(output_file)
            column_names = f.readline().split("\t")

            eof = False

            while not eof:
                batch = []
                count = 0
                keep_going = True
                while keep_going:
                    line = f.readline().strip("\n")
                    values = line.split("\t")
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
                    cursor.executemany('INSERT INTO S275 VALUES (%s)' % (",".join(["?" for x in range(len(column_names))])), batch)
                    conn.commit()

        conn.close()


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

