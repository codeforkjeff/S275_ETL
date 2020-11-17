
S275_ETL
========

This is a perpetual work in progress!

# Features

- Does ETL (ELT, really) and data cleaning of the [S275 Microsoft Access files from OSPI](https://www.k12.wa.us/safs-database-files) into a single table in a SQL database.
  Files for 1996 - 2019 are currently supported; however, not all of these years are currently available for download on the website.
- Creates dimensional models for flexible reporting
- Generates models for teacher/principal demographics, retention/mobility, and cohort analysis
- Supports sqlite3 (included with Python) and Microsoft SQL Server databases

# Requirements

Make sure you install all 32-bit or 64-bit programs; don't mix and match or you'll get errors about missing data sources.

- Windows 10 (needed for ODBC)
- Python >= 3.7.4 - this includes the minimum version of sqlite3 (3.28.0) needed to support the window functions used in this code.
- ODBC drivers for Microsoft Access (included with [Microsoft Access Database Engine 2016](https://www.microsoft.com/en-us/download/details.aspx?id=54920))
- Roughly 1GB of disk space for each academic year of data, when using sqlite3

Using Microsoft SQL Server is optional.

# Setup

- Open a PowerShell window.

- Create a virtual environment: `python -m venv ./S275_env`

- Activate the virtual env: `./S275_env/Scripts/activate`

- Install required Python packages by running: `pip install -r requirements.txt`

- If you're using SQL Server, run `pip install dbt-sqlserver`

- Download and unzip the S275 files for the desired years from [the OSPI website](https://www.k12.wa.us/safs-database-files).
  The unzipped files are Access databases (have an `.accdb` extension). Put these files
  in the `input/` directory. (Alternatively, you can set the path where the script looks for these files,
  using settings in the next step.)

  Instead of doing this step manually, you can run this script to do it for you:

```sh
# this downloads all currently available files, as of Jun 2020
python OSPI_data_downloader.py
```

- Edit your `~/.dbt/profiles.yml` file (or create one) with one of these entries:

For SQLite:

```
S275:

  outputs:

    dev:
      type: sqlite
      threads: 1
      database: "database"
      schema: "main"
      schemas_and_paths: "main=C:/Users/jchiu/S275_ETL/output/S275.sqlite"
      schema_directory: "C:/Users/jchiu/S275_ETL/output"

  target: dev
```

For SQL Server:

```
S275:

  outputs:

    dev:
      type: sqlserver
      driver: 'SQL Server Native Client 11.0'
      host: localhost\
      database: S275
      schema: dbo
      windows_login: True

  target: dev
```

- Copy the `S275_settings_sample.py` file to `S275_settings.py` and edit the paths and variables to suit
  your environment. In the CCER production environment, copy `S275_settings_prod.py` to
  `S275_settings.py`.

# Creating the Data

Run this script:

```sh
.\elt.ps1
```

See the section "Development Notes" below for details on what this does.

# Working with the Data

When the transforms above are finished, you can connect directly to the resulting
database to work with the generated tables. If you built a sqlite database, you
can connect to it and run queries using a compatible SQL client. Two freely
available ones are [DBeaver](https://dbeaver.io/) and
[SQuirreL](http://squirrel-sql.sourceforge.net/).

You can also export the generated data into tab-separated files for use in
Excel, R, Tableau, or any other program that can read such files. Do this as follows:

```sh
# output Dim_Staff
python -c "import S275; S275.export_table('Dim_Staff', 'output/Dim_Staff.txt')"
# output Fact_TeacherMobility
python -c "import S275; S275.export_table('Fact_TeacherMobility', 'output/Fact_TeacherMobility.txt')"

```

Sample queries demonstrating how to use the tables can be found in `report_teacher_mobility.sql`

# Generated Tables

The end result is a set of tables based on [dimensional modeling](https://www.kimballgroup.com/2003/01/fact-tables-and-dimension-tables/).
We follow this method so that the reporting tables can be reused for many
types of research and reporting questions and so that what each table represents is
clear and concise.

Note that AcademicYear values are based on the "end year": e.g. 2016 means 2015-2016.

## Base Tables

`Dim_Staff` - dimension table for staff person for a given year, county, and district.
This is the grain because a person can be employed by more than one district in an
academic year.

`Dim_School` - dimension table for schools. The grain of this table is school building
and academic year.

`Fact_Assignment` - an assignment line item. This table is at the same grain as the rows
in the S275 file. Personnel can (and often do) have multiple assignments within the district
they're employed by, and multiple assignments within a given school building.

`Fact_SchoolTeacher` - table of teachers at schools, and rolled up Percentage, FTEDesignation,
and Salary fields per teacher/school. The PrimaryFlag field is used to support a single school selection
for each teacher/year for reports that want to avoid double counting.

`Fact_SchoolPrincipal` - table of principals and asst principals

## Tables using College of Ed logic

These were created specifically to reproduce the work from the College of Ed.

`Fact_TeacherMobility` - mobility of teachers from their "primary" school,
calculated both year over year and at 5 year snapshots, with flag fields describing
the transitions.

`Fact_PrincipalMobility` - mobility of principals from their "primary" school,
calculated both year over year and at 5 year snapshots.

## Cohort Tables

These were created to enable analysis of what happens to individuals from a starting
cohort year to each subsequent year. These are more "general purpose" (from a CCER
standpoint) than the COE tables above.

`Fact_TeacherCohort` - cohort table containining teachers for each year.

`Fact_TeacherCohortMobility` - mobility of teachers from their CohortYear to
each successive EndYear up to the present. In this table, the flag fields
describe the transitions between CohortYear and EndYear.

`Fact_PrincipalCohort` - cohort table containing principals and assistant principals.

`Fact_PrincipalCohortMobility` - mobility of principals and asst principals from
their CohortYear to each successive EndYear up to the present. In this table,
the flag fields describe the transitions between CohortYear and EndYear.

# Development Notes

This repo uses the open source tool [dbt](http://getdbt.com) to manage the transforms.
See its documentation for how to use that tool, including how to generate
a flow diagram for a bird's-eye view of the entire data pipeline.

In a nutshell, you can see definitions for each table in the `models/` directory,
and trace backwards from there.

# Credits

The work in developing the original coding for educator retention and mobility
is attributed to Dr. Ana Elfers and Dr. Marge Plecki, faculty at the University
of Washington's [Center for the Study of Teaching and Policy (CTP)](https://www.education.uw.edu/ctp/home) in the
[College of Education](https://education.uw.edu/), and data programmer, Gerry Esterbrook. This work was
supported by research sponsors including the [Center for Strengthening the
Teaching Profession (CSTP)](http://cstp-wa.org/), the [Washington State Board of Education (SBE)](https://www.sbe.wa.gov/), and
the [Washington State Office of Superintendent of Public Instruction (OSPI)](https://www.k12.wa.us/).

[Jose M Hernandez](https://github.com/jmhernan) wrote the original implementation
for teacher assignments following the decision rules suggested by the College of Education.
