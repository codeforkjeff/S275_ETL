# Access to SQL Server  
# Jose M Hernandez
# 1/10/2018
# edited 2/1/2019 bc
# pip install -r requirements.txt

import pandas as pd
import csv
import numpy as np
import pyodbc
import os
import sqlalchemy



# Parameters 
AcademicYear = '2018'
FileNameYear = '2017-2018'
dataFile = "S:\\Data\\Data System\\RawSourceFiles\\From OSPI\\S-275 Personnel Database\\Final\\%sFinalS-275PersonnelDatabase.accdb" % (FileNameYear)
dbHost = 'SQLDB-DEV-01'
dbName = 'SandBox'


# End Parameters

connectionString = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=%s" % dataFile
print(connectionString)
dbConnection   = pyodbc.connect(connectionString)
cursor = dbConnection.cursor()

for row in cursor.columns(table='%sS-275FinalForPublic' % (FileNameYear)):
    print("Field name:" + str(row.column_name))
    print("Type:" + str(row.type_name))
    print("Width:" + str(row.column_size))

for table_name in cursor.tables(tableType='TABLE'):
    print(table_name)

sql = "Select *"
sql = sql + " From [%sS-275FinalForPublic]" % (FileNameYear)
print(sql)

cursor.execute(sql)

cursor.description #we want to keep this as we load things back to sql server

# Here we convert to pandas to do necessary transformation if necessary before we load up to SQL Server.  This might not be necessary.
# Might make more sense to upload to sql server using 'pyodbc' and skipping the pandas step...

dataf = pd.read_sql(sql, dbConnection)

len(dataf.columns)

headers = dataf.dtypes.index
print(headers)

engine = sqlalchemy.create_engine('mssql+pyodbc://%s/%s?driver=SQL+Server+Native+Client+11.0' % (dbHost,dbName))

datatypes = {'SchoolYear': sqlalchemy.types.NVARCHAR(),
 'area': sqlalchemy.types.NVARCHAR(), 
 'cou': sqlalchemy.types.NVARCHAR(),
 'dis': sqlalchemy.types.NVARCHAR(), 
 'codist': sqlalchemy.types.NVARCHAR(), 
 'LastName': sqlalchemy.types.NVARCHAR(), 
 'FirstName': sqlalchemy.types.NVARCHAR(), 
 'MiddleName': sqlalchemy.types.NVARCHAR(),
 'cert': sqlalchemy.types.NVARCHAR(),
 'bdate': sqlalchemy.Date(),
 'byr': sqlalchemy.types.NVARCHAR(), 
 'bmo': sqlalchemy.types.NVARCHAR(),
 'bday': sqlalchemy.types.NVARCHAR(),
 'sex': sqlalchemy.types.NVARCHAR(), 
 'hispanic': sqlalchemy.types.NVARCHAR(), 
 'race': sqlalchemy.types.NVARCHAR(),
 'hdeg': sqlalchemy.types.NVARCHAR(),
 'hyear': sqlalchemy.types.NVARCHAR(), 
 'acred': sqlalchemy.types.Float(precision=1, asdecimal=True),
 'icred': sqlalchemy.types.Float(precision=1, asdecimal=True),
 'bcred': sqlalchemy.types.Float(precision=1, asdecimal=True),
 'vcred': sqlalchemy.types.Float(precision=1, asdecimal=True),
 'exp': sqlalchemy.types.Float(precision=1, asdecimal=True),
 'camix1': sqlalchemy.types.Float(precision=5, asdecimal=True),
 'ftehrs': sqlalchemy.types.Float(precision=1, asdecimal=True),
 'ftedays': sqlalchemy.types.Float(precision=4, asdecimal=True),
 'certfte': sqlalchemy.types.Float(precision=2, asdecimal=True),
 'clasfte': sqlalchemy.types.Float(precision=4, asdecimal=True),
 'certbase': sqlalchemy.types.INTEGER(), 
 'clasbase': sqlalchemy.types.INTEGER(), 
 'othersal': sqlalchemy.types.INTEGER(), 
 'tfinsal': sqlalchemy.types.INTEGER(), 
 'cins': sqlalchemy.types.INTEGER(), 
 'cman': sqlalchemy.types.INTEGER(), 
 'cbrtn': sqlalchemy.types.NVARCHAR(), 
 'clasflag': sqlalchemy.types.NVARCHAR(), 
 'certflag': sqlalchemy.types.NVARCHAR(), 
 'ceridate': sqlalchemy.DateTime(),
 'camix1S': sqlalchemy.types.Float(precision=4, asdecimal=True),
 'recno': sqlalchemy.types.NVARCHAR(),
 'parea': sqlalchemy.types.NVARCHAR(), 
 'prog': sqlalchemy.types.NVARCHAR(),
 'act': sqlalchemy.types.NVARCHAR(),
 'darea': sqlalchemy.types.NVARCHAR(), 
 'droot': sqlalchemy.types.NVARCHAR(),
 'dsufx': sqlalchemy.types.NVARCHAR(), 
 'grade': sqlalchemy.types.NVARCHAR(), 
 'bldgn': sqlalchemy.types.NVARCHAR(), 
 'asspct': sqlalchemy.types.Float(precision=4, asdecimal=True),
 'assfte': sqlalchemy.types.Float(precision=4, asdecimal=True),
 'asssal': sqlalchemy.types.INTEGER(), 
 'asshpy': sqlalchemy.types.Float(precision=4, asdecimal=True),
 'major': sqlalchemy.types.NVARCHAR(), 
 'crasdate': sqlalchemy.DateTime(),
 'yr': sqlalchemy.types.NVARCHAR() }

dataf.to_sql("S275_%s" % (AcademicYear), engine, dtype= datatypes)

dbConnection.close()