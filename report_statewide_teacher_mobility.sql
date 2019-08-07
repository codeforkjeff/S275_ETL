-- Statewide counts

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
	cast(MovedIn AS numeric) / cast(TotalTeachers as real) as MovedInPct,
	cast(MovedOut AS numeric) / cast(TotalTeachers as real) as MovedOutPct,
	cast(Exited AS numeric) / cast(TotalTeachers as real) as ExitedPct
from Counts
order by StartYear;
