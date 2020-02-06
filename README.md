
S275_ETL
========

This is a perpetual work in progress!

# Features

- Does ETL and data cleaning of the [S275 files from OSPI](https://www.k12.wa.us/safs-database-files) into a single table in a SQL database.
  Files for 1996 - 2019 are currently supported.
- Creates dimensional models for flexible reporting
- Generates dataset of teacher demographics and retention/mobility
- Supports sqlite3 (included with Python) and SQL Server databases

# Requirements

Make sure you install all 32-bit or 64-bit programs; don't mix and match or you'll get errors about missing data sources.

- Python 3.7.4 - this includes the minimum version of sqlite3 needed to support the window functions used in this code.
- ODBC drivers for Microsoft Access (included with [Microsoft Access Database Engine 2016](https://www.microsoft.com/en-us/download/details.aspx?id=54920))
- Roughly 1GB of disk space for each academic year of data, when using sqlite3

# Instructions

On Windows:

- Open a Command Prompt window.

- Create a virtual environment: `python -m venv ./S275_env`

- Activate the virtual env: `./S275_env/Scripts/activate`

- Install required Python packages by running: `pip install -r requirements.txt`

- Download and unzip the S275 files for the desired years from [the OSPI website](https://www.k12.wa.us/safs-database-files).
  The unzipped files are Access databases (have an `.accdb` extension). Put these files
  in the `input/` directory. (Alternatively, you can set the path where the script looks for these files,
  using settings in the next step.)

  Instead of doing this step manually, you can run this script to do it for you:

```sh
# this downloads all currently available files, as of Aug 2019
python OSPI_data_downloader.py
```

- Copy the `S275_settings_sample.py` file to `S275_settings.py` and edit the paths and variables to suit
  your environment. By default, the code does all data processing using the embedded sqlite3
  database that comes with Python but you can change this to use SQL Server instead.

  For CCER production environment, you can use the encrypted settings file,
  `S275_settings.py.gpg` There's nothing really secret in there but we encrypt it anyway. Look in
  you-know-where for the passphrase.

  To decrypt it:

```sh
gpg -d -o S275_settings.py S275_settings.py.gpg
```

  If you update it, encrypt it back to the .gpg file to commit to the repo:

```sh
gpg -c -a -o S275_settings.py.gpg --cipher-algo AES256 S275_settings.py
```

- Generate everything:

```sh
python -c "import S275; S275.create_everything();"
```

OR you can generate only the data you want, as follows:

```sh
# create auxiliary tables (usually for lookups)
python -c "import S275; S275.create_auxiliary_tables();"

# create S275 table with improved column names, cleaned and standardized data
python -c "import S275; S275.create_base_S275();"

# create dimensional models
python -c "import S275; S275.create_dimensional_models();"

# create teacher mobility (single teacher per year)
python -c "import S275; S275.create_teacher_mobility();"

# create aggregations for teacher mobility (work in progress)
python -c "import S275; S275.create_teacher_mobility_aggregations();"

# create principal mobility (single princpal or asst principal per year)
python -c "import S275; S275.create_principal_mobility();"
```

- You can export the generated data into tab-separated files for use in Excel, R, etc. as follows:

```sh
# output Dim_Staff
python -c "import S275; S275.export_table('Dim_Staff', 'output/Dim_Staff.txt')"
# output Fact_TeacherMobility
python -c "import S275; S275.export_table('Fact_TeacherMobility', 'output/Fact_TeacherMobility.txt')"

```

  Or you can use a SQL client such as [DBeaver](https://dbeaver.io/) to connect directly
  to the database and to work with the generated tables.

  Sample queries demonstrating how to use the tables can be found in `report_teacher_mobility.sql`

# Generated Tables

Note that AcademicYear values are based on the "end year": e.g. 2016 means 2015-2016.

`Dim_Staff` - dimension table for staff person for a given year, county, and district.

`Fact_Assignment` - an assignment line item. This table is at the same grain as the rows in the S275 file.

`Fact_SchoolTeacher` - table of teachers at schools, and rolled up Percentage, FTEDesignation,
and Salary fields per teacher/school. The PrimaryFlag field is used to support a single school selection
for each teacher/year for reports that want to avoid double counting.

`Fact_SchoolPrincipal` - table of principals and asst principals

`Fact_TeacherMobility` - mobility of teachers from their "primary" school,
calculated both year over year and at 5 year snapshots.

`Fact_PrincipalMobility` - mobility of principals from their "primary" school,
calculated both year over year and at 5 year snapshots.

# Development Process

- Create one or more .sql files with the commands that you want to run.

- Add a new, appropriately-named function to `S275.py` to run your .sql files.
Make sure the code runs successfully in both SQL Server and sqlite. .sql files
should be written in SQL Server dialect where standard SQL isn't possible;
see the `execute_sql_file()` in `S275.py` for the code that translates to sqlite.

- Document your new command in this README (above).

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
