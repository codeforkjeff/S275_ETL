
S275_ETL
========

This code does ELT for the [WA State S-275 school personnel data from OSPI](https://www.k12.wa.us/safs-database-files).
It does data cleaning and creates dimensional models for teacher/principal demographics, retention/mobility,
and cohort analysis... with more to come, probably.

This is a perpetual work in progress!

# Features

- Files for 1996 - 2019 are currently supported; however, not all of these years are currently available for download on the website.
- Supported databases: sqlite (included with Python), Microsoft SQL Server, BigQuery

# Running on Linux

Using docker on Linux is the recommended way to build the database. Run the compose stack:

```
docker compose up
```

This will start a postgres database and run the entire elt process, including downloading the
database files from the OSPI website, loading them into the database, and running all the transforms.

You'll know it's ready when you see the message "ELT is finished, starting documentation server"
on the console. You can now use a SQL client to connect to the "s275" database on localhost,
with "s275" as the username and password. You can also view the browser-based documentation
at http://localhost:8080

# Running on Windows

## Requirements

Make sure you install all 32-bit or 64-bit programs; don't mix and match or you'll get errors about missing data sources.

- Windows 10 (needed for ODBC)
- Python >= 3.7.4 - this includes the minimum version of sqlite3 (3.28.0) needed to support the window functions used in this code.
- ODBC drivers for Microsoft Access (included with [Microsoft Access Database Engine 2016](https://www.microsoft.com/en-us/download/details.aspx?id=54920))

## Setup

- Open a PowerShell window.

- Create a virtual environment: `python -m venv $HOME\S275_env`

- Activate the virtual env: `. $HOME\S275_env\Scripts\activate.ps1`

- Install required Python packages by running one of the following,
  depending on which database you want to use:

  `pip install -r requirements-sqlite.txt`

  OR

  `pip install -r requirements-sqlserver.txt`

  OR

  `pip install -r requirements-bigquery.txt`

- Download and unzip the S275 files for the desired years from [the OSPI website](https://www.k12.wa.us/safs-database-files).
  The unzipped files are Access databases (have an `.accdb` extension). Put these files
  in the `input/` directory. (Alternatively, you can set the path where the script looks for these files,
  using settings file in the step below.)

  Instead of doing this step manually, you can run this script to do it for you:

```sh
# this downloads all currently available files, as of Jun 2020
python OSPI_data_downloader.py
```

- Edit your `~/.dbt/profiles.yml` file (or create one) with one of these entries:

For SQLite:

```yaml
S275:

  outputs:

    dev:
      type: sqlite
      threads: 1
      database: "database"
      schema: "main"
      schemas_and_paths:
        main: "C:/Users/jchiu/S275_ETL/output/S275.sqlite"
      schema_directory: "C:/Users/jchiu/S275_ETL/output"

  target: dev
```

For SQL Server:

```yaml
S275:

  outputs:

    dev:
      type: sqlserver
      threads: 2
      driver: 'SQL Server Native Client 11.0'
      host: localhost\
      database: S275
      schema: dbo
      windows_login: True

  target: dev
```

For BigQuery:

```yaml
# create a service account for your Google Cloud project, generate a key for it,
# and download it to your machine; the "keyfile" configuration parameter below
# should point to it.
#
# make sure the service account has permissions for BigQuery and Google Cloud Storage.

S275:

  outputs:

    dev:
      type: bigquery
      method: service-account
      project: project-id-goes-here
      dataset: main
      threads: 4
      keyfile: C:/path/to/keyfile.json
      timeout_seconds: 1000
      priority: interactive
      retries: 1

  target: dev
```

Note that the non-dbt python code reads these dbt settings to do its
own database stuff.

- Edit the `S275_settings.py` file, changing the paths and variables to suit
  your environment.

# School-Level Data Used by the Code

There are two files containing school-level data that this ELT code uses. One is required
(and checked into this repository), and one is not.

The `input\raw_school_base.txt` file contains basic information about WA schools for each
academic year. It's generated out of the CCER data warehouse using the query in
`export_Raw_School_Base_from_RMP.sql`. It should be updated every year and committed into
this repository.

The other file, which is optional, provides additional fields for each school and
academic year. The `dim_school_fields` variable in the `S275_settings.py` file
points to a file. If the path doesn't exist, the ELT code simply doesn't load it. The
production settings file does point to an actual file.

# Creating the Data

Make sure the (empty) database already exists; these scripts do not create a new database.

Open a Powershell window.

Activate the virtual env: `. $HOME\S275_env\Scripts\activate.ps1`

Run this script:

```sh
.\elt.ps1
```

See the contents of that script and the section "Development Notes" below for more details.

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

# Documentation

View the dbt-generated documentation in a browser by running:

```sh
dbt docs generate
dbt docs serve
```

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
