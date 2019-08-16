
S275_ETL
========

This is a perpetual work in progress!

# Features

- Does ETL and data cleaning of the [S275 files from OSPI](https://www.k12.wa.us/safs-database-files). Files for 1996 - 2019 are supported.
- Creates dimensional models for flexible reporting
- Generates dataset of teacher demographics and retention/mobility
- Supports sqlite3 (included with Python) and SQL Server databases

# Requirements

Make sure you install all 32-bit or 64-bit programs; don't mix and match or you'll get errors about missing data sources.

- Python 3.7.4
- ODBC drivers for Microsoft Access (included with [Microsoft Access Database Engine 2016](https://www.microsoft.com/en-us/download/details.aspx?id=54920))

# Instructions

On Windows:

- Open a Command Prompt window.

- Install required Python packages by running: `pip install -r requirements.txt`

- Download and unzip the S275 files from [the OSPI website](https://www.k12.wa.us/safs-database-files).
  The unzipped files are Access databases (have an `.accdb` extension). Put these files
  in the `input/` directory.

- Copy the `S275_settings_sample.py` file to `S275_settings.py` and edit to suit
  your environment. By default, the code does all data processing using the embedded sqlite3
  database that comes with Python but you can change this to use SQL Server instead.

- Generate the data you want, as follows:

```sh
# create auxiliary tables (usually for lookups)
python -c "import S275; S275.create_auxiliary_tables();"

# create S275 table with improved column names, cleaned and standardized data
python -c "import S275; S275.create_base_S275();"

# DEPRECATED: use the Fact_SchoolTeachers table created by create_dimensional_models() instead
python -c "import S275; S275.create_teacher_assignments();"

# create dimensional models
python -c "import S275; S275.create_dimensional_models();"

# create teacher mobility (single teacher per year)
python -c "import S275; S275.create_teacher_mobility();"

# create aggregations for teacher mobility (work in progress)
python -c "import S275; S275.create_teacher_mobility_aggregations();"

```

- Use a SQL client such as [DBeaver](https://dbeaver.io/) to connect to the database
  and to work with the generated tables. Sample queries demonstrating how to use
  the tables can be found in `report_teacher_mobility.sql`

# Generated Tables

`Dim_Staff` - dimension table for staff person for a given year, county, and district.

`Fact_Assignment` - an assignment line item. This table is at the same grain as the rows in the S275 file.

`Fact_SchoolTeacher` - table of teachers at schools, and rolled up Percentage, FTEDesignation,
and Salary fields per teacher/school. The PrimaryFlag field is used to support a single school selection
for each teacher/year for reports that want to avoid double counting.

`Fact_TeacherMobility` - mobility of teachers from their "primary" school,
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
