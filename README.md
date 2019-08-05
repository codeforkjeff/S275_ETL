
S275_ETL
========

# Features

- Supports sqlite3 (included with Python) and SQL Server databases
- Cleaning and ETL of the [S275 files from OSPI](http://www.k12.wa.us/safs/db.asp) into a SQL database
- Creates dimensional models for extensible reporting
- Generation of a teacher assignments file

# Requirements

Make sure you install all 32-bit or 64-bit programs; don't mix and match or you'll get errors about missing data sources.

- Python 3.7.2
- ODBC drivers for Microsoft Access (included with [Microsoft Access Database Engine 2016](https://www.microsoft.com/en-us/download/details.aspx?id=54920))

# Instructions

On Windows:

- Open a Command Prompt window.

- Install required Python packages by running: `pip install -r requirements.txt`

- OPTIONAL: Run script to download all available S275 Access database
  files. If you already have all these files (or just the subset you
  need), copy them into the `input/` directory and skip this
  step.

```
python OSPI_data_downloader.py
```

- Copy the `S275_settings_sample.py` file to `S275_settings.py` and edit to suit your environment.

- Generate the data/files you want, as follows:

```sh
# create auxiliary tables (usually for lookups)
python -c "import S275; S275.create_auxiliary_tables();"

# create cleaned S275 table with improved column names
python -c "import S275; S275.create_base_S275();"

# create teacher assignments
python -c "import S275; S275.create_teacher_assignments();"

# create dimensional models
python -c "import S275; S275.create_dimensional_models();"
```

- The above commands will create files in the output directory.

# Generated Artifacts

`Dim_Staff` - dimension table for staff person for a given year, county, and district.

`Fact_Assignment` - an assignment line item. This table is at the same grain as the S275 file.

`Fact_SchoolTeacher` - table of teachers at schools, and rolled up Percentage, FTEDesignation,
and Salary fields per teacher/school.

# Developnment Process

- Create one or more .sql files with the commands that you want to run.

- Add a new, appropriately-named function to `S275.py` to run your .sql files.
Make sure the code runs successfully in both SQL Server and sqlite. .sql files
should be written in SQL Server dialect where standard SQL isn't possible;
see the `execute_sql_file()` in `S275.py` for the code that translates to sqlite.

- Document your new command in this README (above).

# Credits

Jose M Hernandez [jmhernan](https://github.com/jmhernan) wrote the
original code for teacher assignments
