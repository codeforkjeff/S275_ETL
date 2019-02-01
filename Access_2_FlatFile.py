
import pandas as pd
import csv
import glob
import numpy as np
import pyodbc
import os
import re
import sqlalchemy


#### Parameters

# directory of Access database files downloaded from OSPI website
inputDir = "S:\\Data\\Data System\\RawSourceFiles\\From OSPI\\S-275 Personnel Database\\Final"

# output directory to write files to
outputDir = ".\\output"

# expression for which files to select from inputDir
academic_year_filter = lambda year: year >= 2011

# the columns to select from files
output_columns = [
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
    ,"ceridate"
    ,"camix1S"
    ,"NBcertexpdate"
    ,"recno"
    ,"parea"
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
    ,"crasdate"
    ,"yr"
]

#### End Parameters


def transform_row(output_columns, row):
    new_row = []
    for column_name in output_columns:
        value = getattr(row, column_name, None)
        if value is not None:
            new_value = str(value)
            if column_name in ['acred','icred','bcred','vcred','exp', 'ftehrs']:
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
            new_value = ''
        new_row.append(new_value)
    return new_row

output_file = "%s\\S275.txt" % (outputDir)

f = open(output_file, "w")
f.write("\t".join(output_columns))
f.write("\n")
f.flush()

for file in sorted(glob.glob("%s\\*" % (inputDir))):

    match_year_range = re.search(r"(\d{4})-(\d{4})", file)

    if match_year_range:
        AcademicYear = match_year_range[2]

        if not academic_year_filter(int(AcademicYear)):
            print("Skipping %s" % (file))
            continue

        print("Processing %s" % (file))

        connectionString = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=%s" % file
        dbConnection = pyodbc.connect(connectionString)
        cursor = dbConnection.cursor()

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
                f.write("\t".join(transform_row(output_columns, row)))
                f.write("\n")

            f.flush()

        dbConnection.close()

f.close()
