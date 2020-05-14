# Teacher Mobility and Retention

Queries reproducing numbers and tables from Ana Elfer's slides.


```python
# Initialization: imports

import pandas as pd
import pandas.io.sql as psql

import S275

conn = S275.get_db_conn()
```


```python
sql = """
With Counts as (
	SELECT
		st.AcademicYear,
		SUM(CASE WHEN Sex = 'M' THEN 1 ELSE 0 END) AS Male,
		SUM(CASE WHEN Sex = 'F' THEN 1 ELSE 0 END) AS Female,
		SUM(CASE WHEN HighestDegree = 'B' THEN 1 ELSE 0 END) AS EdBachelors,
		SUM(CASE WHEN HighestDegree = 'M' THEN 1 ELSE 0 END) AS EdMasters,
		SUM(CASE WHEN RaceEthOSPI = 'American Indian/Alaskan Native' THEN 1 ELSE 0 END) AS RaceAmInd,
		SUM(
			CASE WHEN RaceEthOSPI = 'Asian' THEN 1 ELSE 0 END +
			CASE WHEN RaceEthOSPI = 'Native Hawaiian/Other Pacific Islander' THEN 1 ELSE 0 END
		) AS RaceAsianPacIsl,
		SUM(CASE WHEN RaceEthOSPI = 'Black/African American' THEN 1 ELSE 0 END) AS RaceBlack,
		SUM(CASE WHEN RaceEthOSPI = 'Hispanic/Latino of any race(s)' THEN 1 ELSE 0 END) AS RaceHispanic,
		SUM(CASE WHEN RaceEthOSPI = 'Two or More Races' THEN 1 ELSE 0 END) AS RaceTwoOrMore,
		SUM(CASE WHEN RaceEthOSPI = 'White' THEN 1 ELSE 0 END) AS RaceWhite,
		SUM(CASE WHEN CertYearsOfExperience <= 4.5 THEN 1 ELSE 0 END) AS Exp0to4,
		SUM(CASE WHEN CertYearsOfExperience > 4.5 AND CertYearsOfExperience <= 14.5 THEN 1 ELSE 0 END) AS Exp5to14,
		SUM(CASE WHEN CertYearsOfExperience > 14.5 AND CertYearsOfExperience <= 24.5 THEN 1 ELSE 0 END) AS Exp15to24,
		SUM(CASE WHEN CertYearsOfExperience > 24.5 THEN 1 ELSE 0 END) AS ExpOver25,
		count(*) as TotalTeachers
	FROM Fact_SchoolTeacher st
	JOIN Dim_Staff s
		ON st.StaffID = s.StaffID
	WHERE PrimaryFlag = 1
	GROUP BY
		st.AcademicYear
)
select
	AcademicYear,
	TotalTeachers,
	CAST(Male AS REAL) / CAST(TotalTeachers AS REAL) AS PctMale,
	CAST(Female AS REAL) / CAST(TotalTeachers AS REAL) AS PctFemale,
	CAST(EdBachelors AS REAL) / CAST(TotalTeachers AS REAL) AS PctEdBachelors,
	CAST(EdMasters AS REAL) / CAST(TotalTeachers AS REAL) AS PctEdMasters,
	CAST(RaceAmInd AS REAL) / CAST(TotalTeachers AS REAL) AS PctRaceAmInd,
	CAST(RaceAsianPacIsl AS REAL) / CAST(TotalTeachers AS REAL) AS PctRaceAsianPacIsl,
	CAST(RaceBlack AS REAL) / CAST(TotalTeachers AS REAL) AS PctRaceBlack,
	CAST(RaceHispanic AS REAL) / CAST(TotalTeachers AS REAL) AS PctRaceHispanic,
	CAST(RaceTwoOrMore AS REAL) / CAST(TotalTeachers AS REAL) AS PctRaceTwoOrMore,
	CAST(RaceWhite AS REAL) / CAST(TotalTeachers AS REAL) AS PctRaceWhite,
	CAST(Exp0to4 AS REAL) / CAST(TotalTeachers AS REAL) AS PctExp0to4,
	CAST(Exp5to14 AS REAL) / CAST(TotalTeachers AS REAL) AS PctExp5to14,
	CAST(Exp15to24 AS REAL) / CAST(TotalTeachers AS REAL) AS PctExp15to24,
	CAST(ExpOver25 AS REAL) / CAST(TotalTeachers AS REAL) AS PctExpOver25
FROM Counts
WHERE AcademicYear = 1996 OR AcademicYear = 2018
order by AcademicYear;
"""

df = psql.read_sql(sql, conn)

df
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>AcademicYear</th>
      <th>TotalTeachers</th>
      <th>PctMale</th>
      <th>PctFemale</th>
      <th>PctEdBachelors</th>
      <th>PctEdMasters</th>
      <th>PctRaceAmInd</th>
      <th>PctRaceAsianPacIsl</th>
      <th>PctRaceBlack</th>
      <th>PctRaceHispanic</th>
      <th>PctRaceTwoOrMore</th>
      <th>PctRaceWhite</th>
      <th>PctExp0to4</th>
      <th>PctExp5to14</th>
      <th>PctExp15to24</th>
      <th>PctExpOver25</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>1996</td>
      <td>49036</td>
      <td>0.320193</td>
      <td>0.679807</td>
      <td>0.426850</td>
      <td>0.462884</td>
      <td>0.007566</td>
      <td>0.020434</td>
      <td>0.016131</td>
      <td>0.016784</td>
      <td>0.000000</td>
      <td>0.938718</td>
      <td>0.204666</td>
      <td>0.354168</td>
      <td>0.30498</td>
      <td>0.136186</td>
    </tr>
    <tr>
      <th>1</th>
      <td>2018</td>
      <td>62970</td>
      <td>0.261585</td>
      <td>0.738367</td>
      <td>0.319581</td>
      <td>0.657408</td>
      <td>0.007242</td>
      <td>0.030316</td>
      <td>0.013244</td>
      <td>0.045196</td>
      <td>0.015293</td>
      <td>0.888137</td>
      <td>0.255137</td>
      <td>0.352771</td>
      <td>0.25023</td>
      <td>0.141845</td>
    </tr>
  </tbody>
</table>
</div>




```python

```
