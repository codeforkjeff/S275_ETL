
import os.path

scriptDir = os.path.dirname(__file__)

# directory of Access database files downloaded from OSPI website
input_dir = os.path.join(scriptDir, "input")

# output directory to write files to
output_dir = os.path.join(scriptDir, "output")

# tuples of (filename, file type). file type is either FINAL or PRELIMINARY.
source_files = [
	(os.path.join(input_dir, "1995-1996S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "1996-1997S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "1997-1998S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "1998-1999S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "1999-2000S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2000-2001S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2001-2002S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2002-2003S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2003-2004S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2004-2005S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2005-2006S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2006-2007S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2007-2008S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2008-2009S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2009-2010S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2010-2011S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2011-2012S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2012-2013S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2013-2014S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "2014-2015S275FinalForPublic.accdb"), "FINAL")
	,(os.path.join(input_dir, "2015-2016_Final_S-275_Personnel_Database.accdb"), "FINAL")
	,(os.path.join(input_dir, "2016-2017_Final_S-275_Personnel_Database.accdb"), "FINAL")
	,(os.path.join(input_dir, "2017-2018FinalS-275PersonnelDatabase.accdb"), "FINAL")
]

# currently supported: "SQL Server" or "sqlite"
# python typically comes with sqlite compiled into it.
# if you use SQL Server (on Windows), you'll need the bcp program installed.
#db_type = "SQL Server"
db_type = "sqlite"

db_sqlite_path = os.path.join(output_dir, "S275.sqlite")

db_sqlserver_host = "SERVER_NAME"
db_sqlserver_database = "DATABASE_NAME"
db_pyodbc_connection_string = "Driver={SQL Server};Server=%s;Database=%s;Trusted_Connection=yes" % (db_sqlserver_host, db_sqlserver_database)
