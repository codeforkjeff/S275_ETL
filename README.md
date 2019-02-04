
S275_ETL
========

Cleans and prepares teacher data from [S275 files from OSPI](http://www.k12.wa.us/safs/db.asp).

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

- Run the main script, optionally specifying the years you want as a
  parameter. Examples:

```sh
# this will process ALL the files in the input dir
python S275_ETL.py

# this will process only the file for Academic Year 2017 (i.e. 2016-2017)
python S275_ETL.py 2017

# this will process only the files for Academic Years 2011 to 2017
python S275_ETL.py 2011-2017
```

- The resulting file `S275_teacher_assignments.txt` in the output
  directory is a tab-separated file containing a row per teacher per
  school with roll-ups for a few fields.

# Credits

Jose M Hernandez [jmhernan](https://github.com/jmhernan) wrote the
original code for teacher assignments
