
S275_ETL
========

Cleans and prepares teacher data from S275 files from OSPI.

http://www.k12.wa.us/safs/db.asp

# Requirements

Make sure you install all 32-bit or 64-bit programs; don't mix and match or you'll get errors about missing data sources.

- SQL Server Management Studio
- Python 3.7.2
- ODBC drivers for Microsoft Access and SQL Server
- a SQL Server somewhere

# Instructions

On Windows:

- Open a Command Prompt window.

- Install required Python packages by running: `pip install -r requirements.txt`

- OPTIONAL: Run script to download all available S275 Access database
  files. If you already have these files, you can skip this step. Edit
  the paths in that script, then run: `python OSPI_data_downloader.py`

- Edit `Access_2_FlatFile.py`, setting variables at the top of the
  file to suit your needs. Then run the script to create a flat file
  on disk at `output\S275.txt` from the Access databases:

```
python Access_2_FlatFile.py
```

- Load the file into the database using bcp: 

```
bcp Sandbox.dbo.S275 in output/S275.txt -b 10000 -F 2 -a 65535 -m 0 -c -t \t -S HOSTNAME -d DATABASE
```

- Run this script in SSMS: `S275_ETL_teacher_assignments.sql`

- The resulting table is `S275_teacher_assignments` containing a row
  per teacher per school with roll-ups for a few fields.
