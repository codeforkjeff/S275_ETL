
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

#### Parameters

scriptDir = os.path.dirname(__file__)

# directory of Access database files downloaded from OSPI website
inputDir = os.path.join(scriptDir, "input")

# output directory to write files to
outputDir = os.path.join(scriptDir, "output")

# expression for which files to select from inputDir
academic_year_filter = lambda year: year >= 2011

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

stage_db_path = os.path.join(outputDir, "S275.sqlite")


def transform_raw_row(raw_columns, row):
    new_row = []
    for column_name in raw_columns:
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


def create_teachers(conn):
    print("creating teachers")

    cursor = conn.cursor()

    cursor.execute(''' drop table if exists teachers''')

    cursor.execute('''
    create table teachers AS
    SELECT
            substr(schoolyear,-4) AS AcademicYear
            ,RTRIM(area) AS Area
            ,RTRIM(cou) AS County
            ,RTRIM(dis) AS DistrictCode
            ,RTRIM(codist) AS CountyAndDistrictCode
            ,NULLIF(RTRIM(LastName), '') AS LastName
            ,NULLIF(RTRIM(FirstName), '') AS FirstName
            ,NULLIF(RTRIM(MiddleName), '') AS MiddleName
            ,RTRIM(cert) AS CertificateNumber
            ,RTRIM(bdate) AS Birthdate
            ,RTRIM(sex) AS Sex
            ,NULLIF(RTRIM(hispanic), '') AS Hispanic
            ,NULLIF(RTRIM(race), '') AS Race
            ,NULLIF(RTRIM(hdeg), '') AS HighestDegree
            ,NULLIF(RTRIM(hyear), '') AS HighestDegreeYear
            ,RTRIM(acred) AS AcademicCredits
            ,RTRIM(icred) AS InServiceCredits
            ,RTRIM(bcred) AS ExcessCredits
            ,RTRIM(vcred) AS NonDegreeCredits
            ,RTRIM(exp) AS CertYearsOfExperience
            ,RTRIM(camix1) AS StaffMixFactor
            ,RTRIM(ftehrs) AS FTEHours
            ,RTRIM(ftedays) AS FTEDays
            ,RTRIM(certfte) AS CertificatedFTE
            ,RTRIM(clasfte) AS ClassifiedFTE
            ,RTRIM(certbase) AS CertificatedBase
            ,RTRIM(clasbase) AS ClassifiedBase
            ,RTRIM(othersal) AS OtherSalary
            ,RTRIM(tfinsal) AS TotalFinalSalary
            ,RTRIM(cins) AS ActualAnnualInsurance
            ,RTRIM(cman) AS ActualAnnualMandatory
            ,RTRIM(cbrtn) AS CBRTNCode
            ,RTRIM(clasflag) AS ClassificationFlag
            ,RTRIM(certflag) AS CertifiedFlag
            ,RTRIM(act) AS ActivityCode
            ,NULLIF(RTRIM(droot), '') AS DutyRoot
            ,RTRIM(bldgn) AS Building
            ,CAST(asspct AS NUMERIC(14, 4)) AS AssignmentPercent
            ,CAST(assfte AS NUMERIC(14, 4)) AS AssignmentFTEDesignation
            ,CAST(asssal AS INT) AS AssignmentSalaryTotal
    FROM S275
    WHERE
            droot IN ('31','32','33','34')
            AND act ='27'
            AND area = 'L'
    ''')

    # Fix known data issues

    cursor.execute("UPDATE teachers SET HighestDegreeYear = 2007 WHERE HighestDegreeYear = '07'")
    cursor.execute("UPDATE teachers SET HighestDegreeYear = 2013 WHERE HighestDegreeYear = '13'")
    cursor.execute("UPDATE teachers SET HighestDegreeYear = NULL WHERE HighestDegreeYear = 'B0'")

    conn.commit()


def create_teacher_assignments_all(conn):
    print("creating all teacher assignments")

    cursor = conn.cursor()

    cursor.execute('''drop table if exists s275_teacher_assignments_all''')

    cursor.execute('''
        create table s275_teacher_assignments_all AS
        SELECT
                    AcademicYear
                    ,Area
                    ,County
                    ,DistrictCode
                    ,CountyAndDistrictCode
                    ,LastName
                    ,FirstName
                    ,MiddleName
                    ,CertificateNumber
                    ,Birthdate
                    ,Sex
                    ,Hispanic
                    ,Race
                    ,
                    CASE
                            WHEN Hispanic = 'Y' THEN 'Hispanic/Latino of any race(s)'
                            WHEN LENGTH(LTRIM(RTRIM(Race))) > 1 THEN 'Two or More Races'
                            ELSE
                                    CASE LTRIM(RTRIM(COALESCE(Race, '')))
                                            WHEN 'A' THEN 'Asian'
                                            WHEN 'W' THEN 'White'
                                            WHEN 'B' THEN 'Black/African American'
                                            WHEN 'P' THEN 'Native Hawaiian/Other Pacific Islander'
                                            WHEN 'I' THEN 'American Indian/Alaskan Native'
                                            WHEN '' THEN 'Not Provided'
                                            ELSE NULL -- should never happen
                                    END
                    END AS RaceEthOSPI
          ,HighestDegree
          ,HighestDegreeYear
          ,AcademicCredits
          ,InServiceCredits
          ,ExcessCredits
          ,NonDegreeCredits
          ,CertYearsOfExperience
          ,StaffMixFactor
          ,FTEHours
          ,FTEDays
          ,CertificatedFTE
          ,ClassifiedFTE
          ,CertificatedBase
          ,ClassifiedBase
          ,OtherSalary
          ,TotalFinalSalary
          ,ActualAnnualInsurance
          ,ActualAnnualMandatory
          ,CBRTNCode
          ,ClassificationFlag
          ,CertifiedFlag
          ,ActivityCode
          ,Building
          ,SUM(AssignmentPercent) AS AssignmentPercent
          ,SUM(AssignmentFTEDesignation) AS AssignmentFTEDesignation
          ,SUM(AssignmentSalaryTotal) AS AssignmentSalaryTotal
      FROM teachers
      GROUP BY
                    AcademicYear
                    ,Area
                    ,County
                    ,DistrictCode
                    ,CountyAndDistrictCode
                    ,LastName
                    ,FirstName
                    ,MiddleName
                    ,CertificateNumber
                    ,Birthdate
                    ,Sex
                    ,Hispanic
                    ,Race
                    ,HighestDegree
                    ,HighestDegreeYear
                    ,AcademicCredits
                    ,InServiceCredits
                    ,ExcessCredits
                    ,NonDegreeCredits
                    ,CertYearsOfExperience
                    ,StaffMixFactor
                    ,FTEHours
                    ,FTEDays
                    ,CertificatedFTE
                    ,ClassifiedFTE
                    ,CertificatedBase
                    ,ClassifiedBase
                    ,OtherSalary
                    ,TotalFinalSalary
                    ,ActualAnnualInsurance
                    ,ActualAnnualMandatory
                    ,CBRTNCode
                    ,ClassificationFlag
                    ,CertifiedFlag
                    ,ActivityCode
                    ,Building
    ''')

    conn.commit()


def create_teacher_assignments(conn):

    print("creating teacher assignments")

    cursor = conn.cursor()

    cursor.execute('''drop table if exists s275_teacher_assignments''')

    cursor.execute('''
        create table s275_teacher_assignments AS
        SELECT *
        FROM s275_teacher_assignments_all
        WHERE
            CertificateNumber IS NOT NULL
            AND CertificateNumber <> ''
            AND AssignmentFTEDesignation > 0
    ''')

    conn.commit()


def load_staging_db(years):

    stage_db = sqlite3.connect(stage_db_path)
    stage = stage_db.cursor()

    stage.execute('DROP TABLE IF EXISTS S275')
    stage.execute('CREATE TABLE S275 (%s)' % (",".join(raw_columns)))
    stage_db.commit()

    for file in sorted(glob.glob(os.path.join(inputDir, "*"))):

        # pattern in the original filename of S275 files
        match_year_range = re.search(r"(\d{4})-(\d{4})", file)

        if ((file[-4:].upper() == ".MDB") or (file[-6:].upper() == ".ACCDB")) and match_year_range:
            AcademicYear = match_year_range[2]

            if len(years) > 0 and not int(AcademicYear) in years:
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

                cursor.execute("Select * From [%s]" % (table_name))

                keep_going = True
                while keep_going:
                    rows = cursor.fetchmany(100000)
                    if len(rows) > 0:
                        print("Writing batch to staging db...")
                        rows_to_insert = [transform_raw_row(raw_columns, row) for row in rows]
                        stage.executemany('INSERT INTO S275 VALUES (%s)' % (",".join(["?" for x in range(len(raw_columns))])), rows_to_insert)
                        stage_db.commit()
                    else:
                        keep_going = False

            dbConnection.close()

    stage_db.close()


def do_ETL():
    stage_db = sqlite3.connect(stage_db_path)
    create_teachers(stage_db)
    create_teacher_assignments_all(stage_db)
    create_teacher_assignments(stage_db)
    stage_db.close()


def output_results():
    stage_db = sqlite3.connect(stage_db_path)
    stage = stage_db.cursor()

    print("Writing output file...")

    stage.execute("Select * From S275_teacher_assignments")

    output_columns = [item[0] for item in stage.description]

    output_file = os.path.join(outputDir, "S275_teacher_assignments.txt")

    f = open(output_file, "w")
    f.write("\t".join(output_columns))
    f.write("\n")
    f.flush()

    keep_going = True
    while keep_going:
        rows = stage.fetchmany(100000)
        keep_going = False
        for row in rows:
            f.write("\t".join(transform_final_row(output_columns, row)))
            f.write("\n")
            keep_going = True
        f.flush()

    f.close()

    stage_db.close()


def create_year_range(years_str):
    """ returns list of  years """
    if "-" in years_str:
        pieces = years_str.split("-")
        return list(range(int(pieces[0]), int(pieces[1]) + 1))
    return [int(years_str)]


if __name__ == "__main__":

    years = []
    if(len(sys.argv) > 1):
        try:
            years = create_year_range(sys.argv[1])
        except:
            print("ERROR: couldn't parse years range argument")
            sys.exit(1)

    load_staging_db(years)

    do_ETL()

    output_results()
