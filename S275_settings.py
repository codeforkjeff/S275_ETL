
import os.path

scriptDir = os.path.dirname(__file__)

# directory of Access database files downloaded from OSPI website
input_dir = "./input"

# output directory to write files to
#output_dir = "S:\\Data\\Data System\\RawSourceFiles\\From OSPI\\S-275 Personnel Database\\extracted"

# reading extracted files from network drive causes failures in bcp sometimes, so we stage them locally
output_dir = os.path.join(scriptDir, "output")

# filenames of the source files
source_files = [
	(f"{input_dir}/2013-2014_Final_S-275_Personnel_Database.accdb", "FINAL")
	,(f"{input_dir}/2014-2015_Final_S-275_Personnel_Database.accdb", "FINAL")
	,(f"{input_dir}/2015-2016_Final_S-275_Personnel_Database.accdb", "FINAL")
	,(f"{input_dir}/2016-2017_Final_S-275_Personnel_Database.accdb", "FINAL")
	,(f"{input_dir}/2017-2018FinalS-275PersonnelDatabase.accdb", "FINAL")
	,(f"{input_dir}/2018-2019_Final_S-275_Personnel_Database.accdb", "FINAL")
	,(f"{input_dir}/2019-2020_Final_S-275_Personnel_Database.accdb", "FINAL")
	,(f"{input_dir}/2020-2021_Final_S-275_Personnel_Database.accdb", "FINAL")
	,(f"{input_dir}/2021-2022_Final_S-275_Personnel_Database.accdb", "FINAL")
	,(f"{input_dir}/2022-2023_Final_S-275_Personnel_Database.accdb", "FINAL")
]

# export the view Exports.S275_Dim_School_Fields in the data warehouse to create this file
# e.g.
# Export-RmpTable -Table Exports.S275_Dim_School_Fields -DBHost sqldb-dev-02 -Database RMPProd -OutputPath Dim_School_Fields_20211215.txt
dim_school_fields = "S:\\DB Server Files\\DevSourceFiles\\Personnel Database\\Dim_School_Fields_20211215.txt"
