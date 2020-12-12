
import codecs
import collections
import copy
import csv
import datetime
import glob
import itertools
import os
import re
import sqlite3
import sys

import pandas as pd
import haversine
import numpy as np
import pyodbc
import snowflake.connector
import yaml

try:
    from S275_settings import *
except Exception as e:
    print(f"ERROR: could't import S275_settings module: {e}")
    print("Check that you created that file and that it doesn't have any errors. See the README.")
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
    # metadata field, probably for district-level columns. this is useful for tracking.
    ,"ceridate"
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
    # metadata field, probably for assignment-level columns. this is useful for tracking.
    ,"crasdate"
    ,"yr"
]

#### End Parameters

global_conn = None

database_target = None

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


def transform_row_for_export(final_columns, row):
    """ row is a list of values """
    new_row = []
    i = 0
    for value in row:
        column_name = final_columns[i]
        if value is not None:
            new_value = str(value)
            #if column_name in ['AssignmentPercent','AssignmentFTEDesignation']:
            if isinstance(value, float):
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

            # in 2001 file, Cert is uppercased
            if 'Cert' in row:
                row['cert'] = row['Cert']
                del row['Cert']

            values = [to_file_value(value) for value in transform_raw_row(row)]
            f.write("\t".join(values + [file_type]))
            f.write(LINE_TERMINATOR)

        f.flush()

    dbConnection.close()

    f.close()


# main entry point for extracting S275
def extract():
    extract_raw_s275()


# main entry point for loading all source tables
def load():

    ## raw_s275

    load_raw_s275()

    # raw_school_base

    execute_sql_file("create_Raw_School_Base.sql")
    load_into_database([('input/Raw_School_Base.txt', 'Raw_School_Base')])

    # raw_school_fields

    execute_sql_file("create_Raw_School_Fields.sql")
    if os.path.exists(dim_school_fields):
        load_into_database([(dim_school_fields, 'Raw_School_Fields')])
    else:
        print(f"{dim_school_fields} not found, skipping processing for that file")

    ## create stubs for these tables
    create_ext_teachermobility_distance_table()

    create_ext_school_leadership_broad_table()


def execute_sql_file(path):
    """ files should default to using SQL Server dialect; we do some translation here """
    conn = get_db_conn()
    cursor = conn.cursor()
    str = open(path).read()
    statements = str.split("-- next")
    for statement in statements:
        if database_target['type'] == "sqlite":
            statement = statement.replace("LEN(", "LENGTH(")
            statement = statement.replace("SUBSTRING(", "SUBSTR(")
            statement = statement.replace("INT IDENTITY(1,1) NOT NULL PRIMARY KEY", "INTEGER PRIMARY KEY AUTOINCREMENT")
            statement = statement.replace("GETDATE()", "DATETIME('NOW')")
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

    for (output_file, table_name) in entries:
        if database_target['type'] == 'sqlserver':
            os.system("bcp %s in \"%s\" -T -S %s -d %s -F 2 -t \\t -c -b 10000" % (table_name, output_file, database_target['host'], database_target['database']))

        elif database_target['type'] == 'snowflake':

            conn = get_db_conn()
            cursor = conn.cursor()

            cursor.execute("create stage if not exists source_files")

            print(f"Uploading file to stage: {output_file}")

            path = os.path.abspath(output_file).replace("\\", "/")
            sql = f"put 'file://{path}' @source_files OVERWRITE=TRUE"
            cursor.execute(sql)

            print(f"Running COPY command into {table_name}")
            sql = f"copy into {table_name} FROM '@source_files/{os.path.basename(output_file)}' FILE_FORMAT=(TYPE='CSV' FIELD_DELIMITER='\t' skip_header=1)"
            cursor.execute(sql)

        elif database_target['type'] == 'sqlite':

            # read in the flat files and load into sqlite
            conn = get_db_conn()
            cursor = conn.cursor()
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


def get_extracted_path(source_path):
    basename = os.path.basename(source_path)
    return os.path.join(output_dir, basename[0:basename.rindex(".")] + ".txt")


def extract_raw_s275():

    for entry in source_files:
        path = entry[0]
        file_type = entry[1]
        output_file = get_extracted_path(path)

        if not os.path.exists(output_file):
            create_flat_file(path, file_type, output_file)
        else:
            print("%s already exists, skipping" % (output_file,))


def load_raw_s275():
    execute_sql_file("create_Raw_S275.sql")

    output_files = [get_extracted_path(entry[0]) for entry in source_files]

    load_into_database([(output_file, 'raw_S275') for output_file in output_files])


def export_query(sql, output_path):
    conn = get_db_conn()
    cursor = conn.cursor()

    cursor.execute(sql)

    output_columns = [item[0] for item in cursor.description]

    f = open(output_path, "w")
    f.write("\t".join(output_columns))
    f.write("\n")
    f.flush()

    keep_going = True
    while keep_going:
        rows = cursor.fetchmany(100000)
        keep_going = False
        for row in rows:
            f.write("\t".join(transform_row_for_export(output_columns, row)))
            f.write("\n")
            keep_going = True
        f.flush()

    f.close()

    conn.close()


def export_table(table, output_path):
    export_query("Select * From %s" % (table,), output_path)


def get_database_target():
    profiles_path = os.path.expanduser("~/.dbt/profiles.yml")

    profile_name = get_profile_name()

    database_target = None
    if os.path.exists(profiles_path):
        profiles = yaml.load(open(profiles_path).read(), Loader=yaml.Loader)
        target_name = profiles[profile_name]['target']
        database_target = profiles[profile_name]['outputs'][target_name]
    else:
        raise Exception(f"{profiles_path} doesn't exist, can't get db connection params")
    return database_target


def get_profile_name():
    this_module_path = os.path.abspath(__file__)
    dbt_project_path = os.path.join(os.path.dirname(this_module_path), "dbt_project.yml")

    profile_name = ''
    if os.path.exists(dbt_project_path):
        profiles = yaml.load(open(dbt_project_path).read(), Loader=yaml.Loader)
        profile_name = profiles['profile']
    else:
        raise Exception(f"{dbt_project_path} doesn't exist, can't get db connection params")

    return profile_name


def get_db_conn():
    global global_conn

    if global_conn is None:

        if database_target['type'] == "sqlserver":
            db_pyodbc_connection_string = "Driver={SQL Server Native Client 11.0};Server=%s;Database=%s;Trusted_Connection=yes" % \
            (database_target['host'], database_target['database'])

            global_conn = pyodbc.connect(db_pyodbc_connection_string)
        elif database_target['type'] == "sqlite":
            schema_defs = database_target['schemas_and_paths'].split(";")

            db_sqlite_path = None

            for schema_def in schema_defs:
                schema_name, sqlite_path = schema_def.split("=")
                if schema_name == 'main':
                    db_sqlite_path = sqlite_path

            global_conn = sqlite3.connect(db_sqlite_path)
        elif database_target['type'] == "snowflake":

            global_conn = snowflake.connector.connect(
                account=database_target['account'],
                user=database_target['user'],
                password=database_target['password'],
                role=database_target['role'],
                database=database_target['database'],
                warehouse=database_target['warehouse'],
                schema=database_target['schema']
            )
        else:
            raise "Unrecognized type: %s" % (database_target['type'],)

    return global_conn


def create_year_range(years_str):
    """ returns list of  years """
    if "-" in years_str:
        pieces = years_str.split("-")
        return list(range(int(pieces[0]), int(pieces[1]) + 1))
    return [int(years_str)]


def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx"
    args = [iter(iterable)] * n
    return itertools.zip_longest(*args, fillvalue=fillvalue)


def create_ext_teachermobility_distance_table():

    conn = get_db_conn()
    cursor = conn.cursor()

    print("Creating Ext_TeacherMobility_Distance")

    cursor.execute("DROP TABLE IF EXISTS Ext_TeacherMobility_Distance;")

    cursor.execute("CREATE TABLE Ext_TeacherMobility_Distance (TeacherMobilityID varchar(500), Distance real)")

    if database_target['type'] in ("sqlite", "sqlserver"):
        cursor.execute("CREATE INDEX idx_ext_teachermobility_distance ON Ext_TeacherMobility_Distance (TeacherMobilityID, Distance)")

    conn.commit()


def create_ext_teachermobility_distance():

    create_ext_teachermobility_distance_table()

    conn = get_db_conn()
    cursor = conn.cursor()

    print("Querying stg_TeacherMobility")

    cursor.execute("""
        SELECT
            TeacherMobilityID
            ,s1.Lat AS LatStart
            ,s1.Long AS LongStart
            ,s2.Lat AS LatEnd
            ,s2.Long AS LongEnd
        FROM Stg_TeacherMobility m
        LEFT JOIN Dim_School s1 ON m.StartCountyAndDistrictCode = s1.DistrictCode AND m.StartBuilding = s1.SchoolCode AND m.StartYear = s1.AcademicYear 
        LEFT JOIN Dim_School s2 ON m.EndCountyAndDistrictCode = s2.DistrictCode AND m.EndBuilding = s2.SchoolCode AND m.EndYear = s2.AcademicYear
    """)

    rows = cursor.fetchall()

    rows_to_insert = []

    for raw_row in rows:
        row = {}
        (row['TeacherMobilityID'], row['LatStart'], row['LongStart'], row['LatEnd'], row['LongEnd']) = raw_row
        if row['LatStart'] and row['LatEnd']:
            dist = haversine.haversine((row['LatStart'], row['LongStart']), (row['LatEnd'], row['LongEnd']), unit=haversine.Unit.MILES)
            rows_to_insert.append((row['TeacherMobilityID'], dist))

    with codecs.open("distances.tmp", "w", 'utf-8') as f:
        f.write("TeacherMobilityID\tDistance")
        f.write(LINE_TERMINATOR)
        for row in rows_to_insert:
            f.write(str(row[0]))
            f.write("\t")
            f.write(str(row[1]))
            f.write(LINE_TERMINATOR)

    print("Inserting %d entries in Ext_TeacherMobility_Distance" % (len(rows_to_insert)))

    load_into_database([('distances.tmp', 'Ext_TeacherMobility_Distance')])

    os.remove("distances.tmp")


def create_ext_school_leadership_broad_table():

    print("Creating Ext_SchoolLeadership_Broad table")

    conn = get_db_conn()
    cursor = conn.cursor()

    cursor.execute("DROP TABLE IF EXISTS Ext_SchoolLeadership_Broad;")

    cursor.execute("""
        CREATE TABLE Ext_SchoolLeadership_Broad (
            AcademicYear SMALLINT
            ,CountyAndDistrictCode VARCHAR(10)
            ,Building VARCHAR(10)
            ,AllPrincipalCertList VARCHAR(1000)
            ,AllAsstPrinCertList VARCHAR(1000)
            ,AnyPrincipalPOC TINYINT
            ,AnyAsstPrinPOC TINYINT
            ,BroadLeadershipAnyPOCFlag TINYINT
            ,BroadLeadershipChangeFlag TINYINT
            ,BroadLeadershipAnyPOCStayedFlag TINYINT
            ,BroadLeadershipStayedNoPOCFlag TINYINT
            ,BroadLeadershipChangeAnyPOCToNoneFlag TINYINT
            ,BroadLeadershipChangeNoPOCToAnyFlag TINYINT
            ,BroadLeadershipGainedPrincipalPOCFlag TINYINT
            ,BroadLeadershipGainedAsstPrinPOCFlag TINYINT
            ,BroadLeadershipGainedPOCFlag TINYINT
            ,BroadLeadershipLostPrincipalPOCFlag TINYINT
            ,BroadLeadershipLostAsstPrinPOCFlag TINYINT
            ,BroadLeadershipLostPOCFlag TINYINT
        )
    """)

    conn.commit()


LeadershipFields = collections.namedtuple('LeadershipFields', [
    'key',
    'principal_rows',
    'asstprincipal_rows',
    'all_principal_cert_list',
    'all_asstprincipal_cert_list',
    'any_principal_poc',
    'any_asstprincipal_poc',
    'broad_leadership_any_poc_flag',
    'broad_leadership_change_flag',
    'broad_leadership_any_poc_stayed_flag',
    'broad_leadership_stayed_no_poc_flag',
    'broad_leadership_change_any_poc_to_none_flag',
    'broad_leadership_change_no_poc_to_any_flag',
    'broad_leadership_gained_principal_poc_flag',
    'broad_leadership_gained_asstprin_poc_flag',
    'broad_leadership_gained_poc_flag',
    'broad_leadership_lost_principal_poc_flag',
    'broad_leadership_lost_asstprin_poc_flag',
    'broad_leadership_lost_poc_flag'
    ])


def create_ext_school_leadership_broad():
    """
    we do this in Python because our version of SQL Server doesn't support STRING_AGG() function
    (sqlite does have group_concat())
    """

    conn = get_db_conn()
    cursor = conn.cursor()

    print("Populating school leadership fields")

    cursor.execute("""
        select
            sp.AcademicYear,
            sp.CountyAndDistrictCode,
            sp.Building,
            sp.PrincipalType,
            s.CertificateNumber,
            s.PersonOfColorCategory
        from Fact_SchoolPrincipal sp
        join Dim_Staff s
            ON sp.StaffID = s.StaffID
        order by
            sp.AcademicYear,
            sp.CountyAndDistrictCode,
            sp.Building,
            sp.PrincipalType
    """)

    raw_rows = cursor.fetchall()

    ####

    key_fn = lambda row: "_".join([str(row['AcademicYear']), str(row['CountyAndDistrictCode']), str(row['Building']), str(row['CertificateNumber'])])

    ####

    rows = []

    for raw_row in raw_rows:
        row = {}
        (row['AcademicYear'], row['CountyAndDistrictCode'], row['Building'], row['PrincipalType'], row['CertificateNumber'], row['PersonOfColorCategory']) = raw_row
        rows.append(row)

    key_fn = lambda row: "_".join([str(row['AcademicYear']), str(row['CountyAndDistrictCode']), str(row['Building'])])

    def group_and_sort(rows):
        i = itertools.groupby(rows, key=key_fn)
        results = {}
        for (key, values) in i:
            # realize iterator as a list so we can use 'values' multiple times
            values = list(values)

            principal_rows = []
            asstprincipal_rows = []
            all_principal_cert_list = ""
            any_principal_poc = 0
            all_asstprincipal_cert_list =""
            any_asstprincipal_poc = 0

            for (principal_type, p_values) in itertools.groupby(values, key=lambda row: row['PrincipalType']):
                p_values = list(p_values)
                certs = sorted([v['CertificateNumber'] for v in p_values if v['CertificateNumber'] and len(v['CertificateNumber']) > 0])
                certs_str = ",".join(certs)
                poc = int(any(map(lambda v: v['PersonOfColorCategory'] == 'Person of Color', p_values)))
                if principal_type == 'Principal':
                    principal_rows = p_values
                    all_principal_cert_list = certs_str
                    any_principal_poc = poc
                elif principal_type == 'AssistantPrincipal':
                    asstprincipal_rows = p_values
                    all_asstprincipal_cert_list = certs_str
                    any_asstprincipal_poc = poc
                else:
                    raise "Error"

            broad_leadership_any_poc_flag = 1 if any_principal_poc+any_asstprincipal_poc > 0 else 0

            results[key] = LeadershipFields(
                key=key,
                principal_rows=principal_rows,
                asstprincipal_rows=asstprincipal_rows,
                all_principal_cert_list=all_principal_cert_list,
                all_asstprincipal_cert_list=all_asstprincipal_cert_list,
                any_principal_poc=any_principal_poc,
                any_asstprincipal_poc=any_asstprincipal_poc,
                broad_leadership_any_poc_flag=broad_leadership_any_poc_flag,
                broad_leadership_change_flag=0,
                broad_leadership_any_poc_stayed_flag=0,
                broad_leadership_stayed_no_poc_flag=0,
                broad_leadership_change_any_poc_to_none_flag=0,
                broad_leadership_change_no_poc_to_any_flag=0,
                broad_leadership_gained_principal_poc_flag=0,
                broad_leadership_gained_asstprin_poc_flag=0,
                broad_leadership_gained_poc_flag=0,
                broad_leadership_lost_principal_poc_flag=0,
                broad_leadership_lost_asstprin_poc_flag=0,
                broad_leadership_lost_poc_flag=0
            )
        return results

    grouped = group_and_sort(rows)

    final = {}

    for (key, leadership) in grouped.items():
        pieces = key.split("_")

        all_principal_cert_list = leadership.all_principal_cert_list.split(",")
        all_asstprincipal_cert_list = leadership.all_asstprincipal_cert_list.split(",")

        # previous yr
        pieces[0] = str(int(pieces[0]) - 1)
        new_key = "_".join(pieces)

        new_leadership = leadership

        prev_leadership = grouped.get(new_key)

        if prev_leadership:
            prev_all_principal_cert_list = prev_leadership.all_principal_cert_list.split(",")
            prev_all_asstprincipal_cert_list = prev_leadership.all_asstprincipal_cert_list.split(",")

            prin_gained = set(all_principal_cert_list) - set(prev_all_principal_cert_list)
            prin_gained_poc = any([(r['PersonOfColorCategory'] == 'Person of Color') for r in leadership.principal_rows if r['CertificateNumber'] in prin_gained])

            prin_lost = set(prev_all_principal_cert_list) - set(all_principal_cert_list)
            prin_lost_poc = any([(r['PersonOfColorCategory'] == 'Person of Color') for r in prev_leadership.principal_rows if r['CertificateNumber'] in prin_lost])

            ap_gained = set(all_asstprincipal_cert_list) - set(prev_all_asstprincipal_cert_list)
            ap_gained_poc = any([(r['PersonOfColorCategory'] == 'Person of Color') for r in leadership.asstprincipal_rows if r['CertificateNumber'] in ap_gained])

            ap_lost = set(prev_all_asstprincipal_cert_list) - set(all_asstprincipal_cert_list)
            ap_lost_poc = any([(r['PersonOfColorCategory'] == 'Person of Color') for r in prev_leadership.asstprincipal_rows if r['CertificateNumber'] in ap_lost])

            new_leadership = new_leadership._replace(
                broad_leadership_change_flag=int(
                    leadership.all_principal_cert_list != prev_leadership.all_principal_cert_list or \
                    leadership.all_asstprincipal_cert_list != prev_leadership.all_asstprincipal_cert_list),
                broad_leadership_any_poc_stayed_flag= \
                    1 if prev_leadership.broad_leadership_any_poc_flag==1 and leadership.broad_leadership_any_poc_flag==1 else 0,
                broad_leadership_stayed_no_poc_flag = \
                    1 if prev_leadership.broad_leadership_any_poc_flag==0 and leadership.broad_leadership_any_poc_flag==0 else 0,
                broad_leadership_change_any_poc_to_none_flag= \
                    1 if prev_leadership.broad_leadership_any_poc_flag==1 and leadership.broad_leadership_any_poc_flag==0 else 0,
                broad_leadership_change_no_poc_to_any_flag= \
                    1 if prev_leadership.broad_leadership_any_poc_flag==0 and leadership.broad_leadership_any_poc_flag==1 else 0,
                broad_leadership_gained_principal_poc_flag=int(prin_gained_poc),
                broad_leadership_gained_asstprin_poc_flag=int(ap_gained_poc),
                broad_leadership_gained_poc_flag=int(prin_gained_poc or ap_gained_poc),
                broad_leadership_lost_principal_poc_flag=int(prin_lost_poc),
                broad_leadership_lost_asstprin_poc_flag=int(ap_lost_poc),
                broad_leadership_lost_poc_flag=int(prin_lost_poc or ap_lost_poc)
            )

        final[key] = new_leadership


    with codecs.open("ext_schoolleadership_broad.tmp", "w", 'utf-8') as f:
            header = "\t".join([
                "AcademicYear",
                "CountyAndDistrictCode",
                "Building",
                "AllPrincipalCertList",
                "AllAsstPrinCertList",
                "AnyPrincipalPOC",
                "AnyAsstPrinPOC",
                "BroadLeadershipAnyPOCFlag",
                "BroadLeadershipChangeFlag",
                "BroadLeadershipAnyPOCStayedFlag",
                "BroadLeadershipStayedNoPOCFlag",
                "BroadLeadershipChangeAnyPOCToNoneFlag",
                "BroadLeadershipChangeNoPOCToAnyFlag",
                "BroadLeadershipGainedPrincipalPOCFlag",
                "BroadLeadershipGainedAsstPrinPOCFlag",
                "BroadLeadershipGainedPOCFlag",
                "BroadLeadershipLostPrincipalPOCFlag",
                "BroadLeadershipLostAsstPrinPOCFlag",
                "BroadLeadershipLostPOCFlag"
            ])

            f.write(header)
            f.write(LINE_TERMINATOR)
            for row in final.values():
                pieces = row.key.split("_")
                f.write(pieces[0])
                f.write("\t")
                f.write(pieces[1])
                f.write("\t")
                f.write(pieces[2])
                f.write("\t")
                f.write(str(row.all_principal_cert_list))
                f.write("\t")
                f.write(str(row.all_asstprincipal_cert_list))
                f.write("\t")
                f.write(str(row.any_principal_poc))
                f.write("\t")
                f.write(str(row.any_asstprincipal_poc))
                f.write("\t")
                f.write(str(row.broad_leadership_any_poc_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_change_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_any_poc_stayed_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_stayed_no_poc_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_change_any_poc_to_none_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_change_no_poc_to_any_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_gained_principal_poc_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_gained_asstprin_poc_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_gained_poc_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_lost_principal_poc_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_lost_asstprin_poc_flag))
                f.write("\t")
                f.write(str(row.broad_leadership_lost_poc_flag))
                f.write(LINE_TERMINATOR)

    print("Inserting %d entries in Ext_SchoolLeadership_Broad" % (len(grouped)))

    create_ext_school_leadership_broad_table()

    load_into_database([('ext_schoolleadership_broad.tmp', 'Ext_SchoolLeadership_Broad')])

    if database_target['type'] in ("sqlite", "sqlserver"):
        cursor.execute("CREATE UNIQUE INDEX idx_Ext_SchoolLeadership_Broad ON Ext_SchoolLeadership_Broad(AcademicYear, CountyAndDistrictCode, Building);")

    conn.commit()

    os.remove("ext_schoolleadership_broad.tmp")


database_target = get_database_target()
