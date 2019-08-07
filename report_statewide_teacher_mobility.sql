
----------------------------------
-- 5-year Statewide counts
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
	FROM Fact_TeacherMobilitySingle
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
order by StartYear;

----------------------------------
-- 5-year Statewide counts of novice teachers
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
	FROM Fact_TeacherMobilitySingle m
	where DiffYears = 4
		AND CertYearsOfExperience <= 2.0
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
order by StartYear;

----------------------------------
-- Yearly Statewide counts
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
	FROM Fact_TeacherMobilitySingle m
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
order by StartYear;

----------------------------------
-- District counts for select districts
----------------------------------

With Counts as (
	SELECT
		StartYear,
		EndYear,
		StartCountyAndDistrictCode,
		SUM(Stayer) AS Stayer,
		SUM(MovedIn) AS MovedIn,
		SUM(MovedOut) AS MovedOut,
		SUM(Exited) AS Exited,
		count(*) as TotalTeachers
	FROM Fact_TeacherMobilitySingle m
	where DiffYears = 4
		AND StartCountyAndDistrictCode IN (17001, 17210, 17401, 17403, 17406, 17408, 17415)
	GROUP BY
		StartYear,
		EndYear,
		StartCountyAndDistrictCode
)
select
	*,
	cast(Stayer AS real) / cast(TotalTeachers as real) as StayerPct,
	cast(MovedIn AS real) / cast(TotalTeachers as real) as MovedInPct,
	cast(MovedOut AS real) / cast(TotalTeachers as real) as MovedOutPct,
	cast(Exited AS real) / cast(TotalTeachers as real) as ExitedPct
from Counts
order by StartYear;
