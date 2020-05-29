
----------------------------------
-- Teacher demographics for 1996 vs 2018
----------------------------------

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


----------------------------------
-- Statewide counts of novice teachers
----------------------------------

With Counts as (
	SELECT
		StartYear AS AcademicYear,
		count(*) as TotalTeachers,
		SUM(IsNoviceTeacherFlag) AS TotalNoviceTeachers
	FROM Fact_TeacherMobility m
	JOIN Dim_Staff s
		ON m.StartStaffID = s.StaffID
	where DiffYears = 1
	GROUP BY
		StartYear,
		EndYear
)
select
	*,
	(CAST(TotalNoviceTeachers AS REAL) / CAST(TotalTeachers AS REAL)) AS Pct
from Counts
order by AcademicYear;


----------------------------------
-- 5-year Statewide retention and mobility
----------------------------------

With Counts as (
	SELECT
		StartYear,
		EndYear,
		SUM(Stayer) AS Stayer,
		SUM(MovedIn) AS MovedIn,
		SUM(MovedOut) AS MovedOut,
		SUM(Exited) AS Exited,
		count(*) as TotalTeachers
	FROM Fact_TeacherMobility
	where DiffYears = 4
	GROUP BY
		StartYear,
		EndYear
)
select
	*,
	cast(Stayer AS real) / cast(TotalTeachers as real) as StayerPct,
	cast(MovedIn AS real) / cast(TotalTeachers as real) as MovedInPct,
	cast(MovedOut AS real) / cast(TotalTeachers as real) as MovedOutPct,
	cast(Exited AS real) / cast(TotalTeachers as real) as ExitedPct
from Counts
WHERE StartYear IN (1999, 2011, 2012, 2013, 2014, 2015)
order by StartYear;


----------------------------------
-- Comparing statewide retention/mobility of all teachers vs novice teachers for 2015-2019
----------------------------------

WITH Counts as (
	SELECT
		StartYear,
		EndYear,
		SUM(Stayer) AS Stayer,
		SUM(MovedIn) AS MovedIn,
		SUM(MovedOut) AS MovedOut,
		SUM(Exited) AS Exited,
		count(*) as TotalTeachers
	FROM Fact_TeacherMobility m
	where DiffYears = 4
	GROUP BY
		StartYear,
		EndYear
)
,CountsNovice as (
	SELECT
		StartYear,
		EndYear,
		SUM(Stayer) AS Stayer,
		SUM(MovedIn) AS MovedIn,
		SUM(MovedOut) AS MovedOut,
		SUM(Exited) AS Exited,
		count(*) as TotalTeachers
	FROM Fact_TeacherMobility m
	JOIN Dim_Staff s
		ON m.StartStaffID = s.StaffID
	where
		DiffYears = 4
		AND IsNoviceTeacherFlag = 1
	GROUP BY
		StartYear,
		EndYear
)
SELECT
	c.StartYear,
	c.EndYear,
	cast(c.Stayer AS real) / cast(c.TotalTeachers as real) as AllStayerPct,
	cast(c.MovedIn AS real) / cast(c.TotalTeachers as real) as AllMovedInPct,
	cast(c.MovedOut AS real) / cast(c.TotalTeachers as real) as AllMovedOutPct,
	cast(c.Exited AS real) / cast(c.TotalTeachers as real) as AllExitedPct,
	CAST(cn.Stayer AS real) / cast(cn.TotalTeachers as real) as NoviceStayerPct,
	cast(cn.MovedIn AS real) / cast(cn.TotalTeachers as real) as NoviceMovedInPct,
	cast(cn.MovedOut AS real) / cast(cn.TotalTeachers as real) as NoviceMovedOutPct,
	cast(cn.Exited AS real) / cast(cn.TotalTeachers as real) as NoviceExitedPct
FROM Counts c
LEFT JOIN CountsNovice cn
	ON c.StartYear = cn.StartYear
	AND c.EndYear = cn.EndYear
WHERE c.StartYear = 2015
order by c.StartYear;


----------------------------------
-- Retention and mobility for select districts 2012-2016
----------------------------------

With 
Codes AS (
	SELECT
		DistrictCode,
		max(DistrictName) as DistrictName
	FROM Dim_School
	GROUP BY DistrictCode
)
,Counts as (
	SELECT
		StartYear,
		EndYear,
		StartCountyAndDistrictCode,
		SUM(Stayer) AS Stayer,
		SUM(MovedIn) AS MovedIn,
		SUM(MovedOut) AS MovedOut,
		SUM(Exited) AS Exited,
		count(*) as TotalTeachers
	FROM Fact_TeacherMobility m
	where DiffYears = 4
	GROUP BY
		StartYear,
		EndYear,
		StartCountyAndDistrictCode
)
select
	StartYear,
	EndYear,
	StartCountyAndDistrictCode,
	Codes.DistrictName,
	cast(Stayer AS real) / cast(TotalTeachers as real) as StayerPct,
	cast(MovedIn AS real) / cast(TotalTeachers as real) as MovedInPct,
	cast(MovedOut AS real) / cast(TotalTeachers as real) as MovedOutPct,
	cast(Exited AS real) / cast(TotalTeachers as real) as ExitedPct
from Counts
LEFT JOIN Codes
	ON Counts.StartCountyAndDistrictCode = Codes.DistrictCode
WHERE
	StartYear = 2012
	AND EndYear = 2016
	AND (
		Codes.DistrictName LIKE 'Seattle%'
		OR Codes.DistrictName LIKE 'Spokane%'
		OR Codes.DistrictName LIKE 'Tacoma%'
		OR Codes.DistrictName LIKE 'Vancouver%'
		OR Codes.DistrictName LIKE 'Bellevue%'
		OR Codes.DistrictName LIKE 'Highline%'
		OR Codes.DistrictName LIKE 'Kennewick%'
		OR Codes.DistrictName LIKE 'Yakima%'
		OR Codes.DistrictName LIKE 'Bellingham%'
		OR Codes.DistrictName LIKE 'Central Kitsap%'
	)
order by StartYear, endyear, Codes.DistrictName;


----------------------------------
-- Retention and mobility for Auburn schools 2011-2015
----------------------------------

With Counts as (
	SELECT
		StartYear,
		EndYear,
		StartCountyAndDistrictCode,
		StartBuilding,
		SUM(Stayer) AS Stayer,
		SUM(MovedIn) AS MovedIn,
		SUM(MovedOut) AS MovedOut,
		SUM(Exited) AS Exited,
		count(*) as TotalTeachers
	FROM Fact_TeacherMobility m
	where DiffYears = 4
	GROUP BY
		StartYear,
		EndYear,
		StartCountyAndDistrictCode,
		StartBuilding
)
select
	Counts.StartYear,
	Counts.EndYear,
	Sch.DistrictName,
	Sch.SchoolName,
	Stayer,
	cast(Stayer AS real) / cast(Counts.TotalTeachers as real) as StayerPct,
	MovedIn,
	cast(MovedIn AS real) / cast(Counts.TotalTeachers as real) as MovedInPct,
	MovedOut,
	cast(MovedOut AS real) / cast(Counts.TotalTeachers as real) as MovedOutPct,
	Exited,
	cast(Exited AS real) / cast(Counts.TotalTeachers as real) as ExitedPct
from Counts
LEFT JOIN Dim_School Sch
	ON Counts.StartBuilding = Sch.SchoolCode
	AND Counts.StartYear = Sch.AcademicYear
WHERE
	StartYear = 2011
	AND EndYear = 2015
	AND Sch.DistrictName LIKE 'Auburn%'
order by StartYear, endyear, Sch.SchoolName;


----------------------------------
-- Yearly Retention and mobility rates
----------------------------------

With Counts as (
	SELECT
		StartYear,
		EndYear,
		SUM(Stayer) AS Stayer,
		SUM(MovedIn) AS MovedIn,
		SUM(MovedOut) AS MovedOut,
		SUM(Exited) AS Exited,
		count(*) as TotalTeachers
	FROM Fact_TeacherMobility m
	where DiffYears = 1
	GROUP BY
		StartYear,
		EndYear
)
select
	*,
	cast(Stayer AS real) / cast(TotalTeachers as real) as StayerPct,
	cast(MovedIn AS real) / cast(TotalTeachers as real) as MovedInPct,
	cast(MovedOut AS real) / cast(TotalTeachers as real) as MovedOutPct,
	cast(Exited AS real) / cast(TotalTeachers as real) as ExitedPct
from Counts
where StartYear IN (2006, 2014, 2015, 2016, 2017, 2018)
order by StartYear;


----------------------------------
-- Sample query with range buckets for distance moved
----------------------------------

With 
Base as (
	select 
		*
		,case when Distance > 0 then 1 else 0 end as Moved
		,CASE WHEN Distance > 0 AND Distance <= 5.0 THEN 1 ELSE 0 END AS DistanceUpTo5 
		,CASE WHEN Distance > 5.0 AND Distance <= 10.0 THEN 1 ELSE 0 END AS Distance5To10
		,CASE WHEN Distance > 10.0 AND Distance <= 25.0 THEN 1 ELSE 0 END AS Distance10To25
		,CASE WHEN Distance > 25.0 AND Distance <= 50.0 THEN 1 ELSE 0 END AS Distance25To50
		,CASE WHEN Distance > 50.0 THEN 1 ELSE 0 END AS DistanceOver50
	FROM Fact_TeacherMobility
)
,Counts as (
	SELECT
		StartYear,
		EndYear,
		count(*) as TotalTeachers,
		sum(moved) as Moved,
		Sum(DistanceUpTo5) as DistanceUpTo5, 
		Sum(Distance5To10) as Distance5To10,
		sum(Distance10To25) as Distance10To25,
		sum(Distance25To50) as Distance25To50,
		sum(DistanceOver50) as DistanceOver50
	FROM Base m
	where DiffYears = 1
	GROUP BY
		StartYear,
		EndYear
)
select
	*,
	cast(DistanceUpTo5 as real) / cast(moved as real) as DistanceUpTo5Pct,
	cast(Distance5To10 as real) / cast(moved as real) as Distance5To10Pct,
	cast(Distance10To25 as real) / cast(moved as real) as Distance10To25Pct,
	cast(Distance25To50 as real) / cast(moved as real) as Distance25To50Pct,
	cast(DistanceOver50 as real) / cast(moved as real) as DistanceOver50Pct
from Counts
order by StartYear;


----------------------------------
-- Sample query showing top 10 counts of different locale changes for each start/end year period
----------------------------------

WITH PeriodTotals AS (
	SELECT
		StartYear,
		EndYear,
		COUNT(*) AS Total
	FROM Fact_TeacherMobility
	GROUP BY StartYear, EndYear
)
,LocaleChanges AS (
	SELECT
		StartYear,
		EndYear,
		StartLocale,
		EndLocale,
		COUNT(*) AS ChangeTotal
	FROM Fact_TeacherMobility
	WHERE
		StartLocale IS NOT NULL
		AND EndLocale IS NOT NULL
	GROUP BY StartYear, EndYear, StartLocale, EndLocale
)
,Percentages AS (
	SELECT
		l.StartYear,
		l.EndYear,
		StartLocale,
		EndLocale,
		ChangeTotal,
		Total,
		CAST(ChangeTotal AS NUMERIC(10,2)) / Total AS Pct
	FROM LocaleChanges l
	LEFT JOIN PeriodTotals T
		ON l.StartYear = T.StartYear
		AND l.EndYear = T.EndYear
)
,Ranked AS (
	SELECT
		*
		,ROW_NUMBER() OVER (PARTITION BY StartYear, EndYear ORDER BY Pct DESC) AS RN
	FROM Percentages
)
SELECT *
FROM Ranked
WHERE RN <= 10 -- top 10
ORDER BY
	StartYear, EndYear, Pct DESC;


----------------------------------
-- Leaky pipeline for 2015 cohort of teachers by race (white/teachers of color)
----------------------------------

-- this traces what happens to an initial cohort of teachers over several years,
-- comparing where they were during their cohort year with where they were in each subsequent year.
-- accordingly, this does not account for multiple moves or years where a teacher disappears
-- from S275 (there is no data).

WITH TeacherCohort AS (
	-- build initial cohort, including their district/building which we use to compare to each future year
	SELECT
		a.StartStaffID AS CohortStaffID
		,a.CertificateNumber
		,a.StartYear AS CohortYear
		,a.StartCountyAndDistrictCode AS CohortCountyAndDistrictCode
		,a.StartBuilding AS CohortBuilding
	from Fact_TeacherMobility a
	JOIN Dim_Staff b
		ON a.StartStaffID = b.StaffID
	WHERE
		EXISTS (select 1 from Dim_School s where s.DistrictCode = a.StartCountyAndDistrictCode and s.SchoolCode = a.StartBuilding and RMRFlag = 1)
		and a.DiffYears = 1
		and a.StartYear = 2015
		AND b.IsNoviceTeacherFlag = 1
)
,Mobility AS (
	-- find all the mobility records for the cohort (CertNumber)
	SELECT
		tc.CohortYear
		,tc.CertificateNumber
		,tc.CohortCountyAndDistrictCode
		,a.StartYear
		,a.StartCountyAndDistrictCode
		,a.StartBuilding
		,a.EndYear
		,a.EndCountyAndDistrictCode
		,a.EndBuilding
		,a.Stayer
		,b.RaceEthOSPI
		,b.Sex
		,TeacherCategory = CASE
			WHEN b.RaceEthOSPI IN ('White', 'Not Provided') THEN b.RaceEthOSPI
			ELSE 'Teacher of Color'
		END
		,CASE WHEN CohortBuilding = EndBuilding THEN 1 ELSE 0 END AS StayedInSchool
		,CASE WHEN CohortBuilding <> EndBuilding AND CohortCountyAndDistrictCode = EndCountyAndDistrictCode AND a.EndTeacherFlag = 1 THEN 1 ELSE 0 END AS ChangedBuildingStayedDistrict 
		,CASE WHEN CohortBuilding <> EndBuilding AND CohortCountyAndDistrictCode = EndCountyAndDistrictCode AND a.EndTeacherFlag = 0 THEN 1 ELSE 0 END AS ChangedRoleStayedDistrict 
		,CASE WHEN CohortCountyAndDistrictCode <> EndCountyAndDistrictCode THEN 1 ELSE 0 END AS MovedOutDistrict 
		,Exited
	FROM TeacherCohort tc
	JOIN Fact_TeacherMobility a
		ON tc.CertificateNumber = a.CertificateNumber
	JOIN Dim_Staff b
		on tc.CohortStaffID = b.StaffID
	WHERE
		a.DiffYears = 1
		AND a.StartYear >= 2015
)
,Agg AS (
	SELECT
		CohortYear
		,EndYear
		,TeacherCategory
		,SUM(StayedInSchool) AS StayedInSchool
		,SUM(ChangedBuildingStayedDistrict) AS ChangedBuildingStayedDistrict
		,SUM(ChangedRoleStayedDistrict) AS ChangedRoleStayedDistrict
		,SUM(MovedOutDistrict) as MovedOutDistrict
		,SUM(Exited) as Exited
		,COUNT(*) AS TotalTeachersYr
	FROM Mobility
	GROUP BY
		CohortYear
		,EndYear
		,TeacherCategory
)
,CohortDenominator AS (
	SELECT
		TeacherCategory,
		TotalTeachersYr AS CohortDenominator
	FROM Agg
	WHERE
		CohortYear = 2015
		AND EndYear = 2016
)
,Final AS (
	SELECT
		CohortYear
		,EndYear
		,t1.TeacherCategory
		,StayedInSchool
		,ChangedBuildingStayedDistrict
		,ChangedRoleStayedDistrict
		,MovedOutDistrict
		-- use running total for Exited
		,SUM(Exited) OVER (PARTITION BY CohortYear, t1.TeacherCategory ORDER BY EndYear) as Exited
		-- not all fields will add up to CohortDenominator b/c of
		-- small number of teachers who are missing data in some years between 2015 and 2019
		,CohortDenominator
	FROM Agg t1
	LEFT JOIN CohortDenominator t2
		ON t1.TeacherCategory = t2.TeacherCategory
)
SELECT
	CohortYear
	,EndYear
	,TeacherCategory
	,StayedInSchool
	,CONVERT(FLOAT, StayedInSchool) / CohortDenominator AS StayedInSchoolPct
	,ChangedBuildingStayedDistrict
	,CONVERT(FLOAT, ChangedBuildingStayedDistrict) / CohortDenominator AS ChangedBuildingStayedDistrictPct
	,ChangedRoleStayedDistrict
	,CONVERT(FLOAT, ChangedRoleStayedDistrict) / CohortDenominator AS ChangedRoleStayedDistrictPct
	,MovedOutDistrict
	,CONVERT(FLOAT, MovedOutDistrict) / CohortDenominator AS MovedOutDistrictPct
	,Exited
	,CONVERT(FLOAT, Exited) / CohortDenominator AS ExitedPct
	,CohortDenominator
FROM Final
ORDER BY
	EndYear
	,TeacherCategory

----------------------------------
-- Leaky pipeline for 2015 cohort of teachers by race, using Fact_TeacherCohortMobility
----------------------------------

-- Similar to the previous query but uses new Fact_TeacherCohortMobility table for greater simplicity

;WITH
Cohort2015RMP AS (
	SELECT
		a.*
		,PersonOfColorCategory AS TeacherCategory
	FROM Fact_TeacherCohortMobility a
	JOIN Dim_Staff b
		ON a.CohortStaffID = b.StaffID
	WHERE
		CohortYear = 2015
		AND b.IsNoviceTeacherFlag = 1
		AND EXISTS (
			SELECT 1
			FROM Dim_School s
			WHERE
				s.DistrictCode = a.CohortCountyAndDistrictCode
				AND s.SchoolCode = a.CohortBuilding
				AND RMRFlag = 1
		)
)
SELECT
	CohortYear
	,EndYear
	,TeacherCategory
	,SUM(StayedInSchool) AS StayedInSchool
	,SUM(ChangedBuildingStayedDistrict) AS ChangedBuildingStayedDistrict
	,SUM(ChangedRoleStayedDistrict) AS ChangedRoleStayedDistrict
	,SUM(MovedOutDistrict) as MovedOutDistrict
	,SUM(Exited) as Exited
	,COUNT(*) TotalTeachersYr
FROM Cohort2015RMP
GROUP BY
	CohortYear
	,EndYear
	,TeacherCategory
ORDER BY
	CohortYear
	,EndYear
	,TeacherCategory
