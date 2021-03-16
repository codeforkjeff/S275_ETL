
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

- Install required Python packages by running one of the following,
  depending on which database you want to use:

  `pip install -r requirements-sqlite.txt`

  OR

  `pip install -r requirements-sqlserver.txt`

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
      threads: 2
      driver: 'SQL Server Native Client 11.0'
      host: localhost\
      database: S275
      schema: dbo
      windows_login: True

  target: dev
```

Note that the non-dbt python code reads these dbt settings to do its
own database stuff.

- Copy the `S275_settings_sample.py` file to `S275_settings.py` and edit the paths and variables to suit
  your environment. In the CCER production environment, copy `S275_settings_prod.py` to
  `S275_settings.py`.

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

Open a Powershell window.

Activate the virtual env: `./S275_env/Scripts/activate`

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
