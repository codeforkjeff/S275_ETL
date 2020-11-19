
import os.path

scriptDir = os.path.dirname(__file__)

# directory of Access database files downloaded from OSPI website
input_dir = os.path.join(scriptDir, "input")

# output directory to write files to
output_dir = os.path.join(scriptDir, "output")

# tuples of (filename, file type). file type is either FINAL or PRELIMINARY.
source_files = [

	# OSPI periodically changes the names of files for past years, as well as
	# how far back its available files go. You may need to change this list
	# if OSPI's filenames change OR if you are working with archival files
	# you downloaded in the past.

	(os.path.join(input_dir, "2013-2014_Final_S-275_Personnel_Database.accdb"), "FINAL")
	,(os.path.join(input_dir, "2014-2015_Final_S-275_Personnel_Database.accdb"), "FINAL")
	,(os.path.join(input_dir, "2015-2016_Final_S-275_Personnel_Database.accdb"), "FINAL")
	,(os.path.join(input_dir, "2016-2017_Final_S-275_Personnel_Database.accdb"), "FINAL")
	,(os.path.join(input_dir, "2017-2018FinalS-275PersonnelDatabase.accdb"), "FINAL")
	,(os.path.join(input_dir, "2018-2019_Final_S-275_Personnel_Database.accdb"), "FINAL")
]

# Dim_School_Fields table gets loaded from this only if file exists
dim_school_fields = "Dim_School_Fields.txt"
