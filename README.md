
S275_ETL
========

# Features

- Cleaning and ETL of the [S275 files from OSPI](http://www.k12.wa.us/safs/db.asp) into a SQL database
- Generation of a teacher assignments file
- Other products coming soon...

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
# create cleaned S275 table with improved column names
python -c "import S275; S275.create_base_S275();"

# create teacher assignments
python -c "import S275; S275.create_teacher_assignments();"

```

- The above commands will create files in the output directory.

# Developnment Process

- Create one or more .sql files with the commands that you want to run.

- Add a new, appropriately-named function to `S275.py` to run your .sql files.
Make sure the code runs successfully in both SQL Server and sqlite.

- Document your new command in this README (above).

# Credits

Jose M Hernandez [jmhernan](https://github.com/jmhernan) wrote the
original code for teacher assignments
