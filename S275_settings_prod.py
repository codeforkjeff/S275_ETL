
import os.path

scriptDir = os.path.dirname(__file__)

# directory of Access database files downloaded from OSPI website
input_dir = "S:\\Data\\Data System\\RawSourceFiles\\From OSPI\\S-275 Personnel Database"

# output directory to write files to
output_dir = "S:\\Data\\Data System\\Jeff\\S275\\output"

# filenames of the source files
source_files = [
	(os.path.join(input_dir, "Final\\1995-1996S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\1996-1997S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\1997-1998S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\1998-1999S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\1999-2000S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2000-2001S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2001-2002S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2002-2003S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2003-2004S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2004-2005S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2005-2006S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2006-2007S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2007-2008S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2008-2009S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2009-2010S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2010-2011S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2011-2012S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2012-2013S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2013-2014S275FinalForPublic.mdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2014-2015S275FinalForPublic.accdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2015-2016_Final_S-275_Personnel_Database.accdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2016-2017_Final_S-275_Personnel_Database.accdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2017-2018FinalS-275PersonnelDatabase.accdb"), "FINAL")
	,(os.path.join(input_dir, "Final\\2018-2019_Final_S-275_Personnel_Database.accdb"), "FINAL")
	,(os.path.join(input_dir, "Preliminary\\2019-2020_Preliminary_S-275_Personnel_Database.accdb"), "PRELIMINARY")
]

# see the stored proc Exports.usp_create_S275_Dim_School_Fields in the data warehouse
# for creating this file
dim_school_fields = "S:\\DB Server Files\\DevSourceFiles\\Personnel Database\\Dim_School_Fields_20200520.txt"
