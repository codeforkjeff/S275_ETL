
----------------------------------
-- Five-year retention & mobility: Principals and APs
----------------------------------

With Counts as (
	SELECT
		StartPrincipalType AS PrincipalType,
		StartYear,
		EndYear,
		SUM(Stayer) AS Stayer,
		SUM(MovedIn) AS MovedIn,
		SUM(MovedOut) AS MovedOut,
		SUM(Exited) AS Exited,
		count(*) as Total
	FROM Fact_PrincipalMobility
	where DiffYears = 4
	GROUP BY
		StartYear,
		EndYear,
		StartPrincipalType
)
select
	*,
	cast(Stayer AS real) / cast(Total as real) as StayerPct,
	cast(MovedIn AS real) / cast(Total as real) as MovedInPct,
	cast(MovedOut AS real) / cast(Total as real) as MovedOutPct,
	cast(Exited AS real) / cast(Total as real) as ExitedPct
from Counts
WHERE StartYear IN (2000, 2005, 2010, 2011)
order by
	PrincipalType, StartYear;


----------------------------------
-- Average Year-by-Year Retention & Mobility for Principals
----------------------------------

With Counts as (
	SELECT
		StartPrincipalType AS PrincipalType,
		StartYear,
		EndYear,
		SUM(Stayer) AS Stayer,
		SUM(MovedIn) AS MovedIn,
		SUM(MovedOut) AS MovedOut,
		SUM(Exited) AS Exited,
		count(*) as Total
	FROM Fact_PrincipalMobility
	where DiffYears = 1
	AND StartPrincipalType = 'Principal'
	GROUP BY
		StartYear,
		EndYear,
		StartPrincipalType
)
,Agg AS (
	SELECT
		*,
		cast(Stayer AS real) / cast(Total as real) as StayerPct,
		cast(MovedIn AS real) / cast(Total as real) as MovedInPct,
		cast(MovedOut AS real) / cast(Total as real) as MovedOutPct,
		cast(Exited AS real) / cast(Total as real) as ExitedPct
	from Counts
)
SELECT
	AVG(StayerPct) AS StayerPct
	,AVG(MovedInPct) AS MovedInPct
	,AVG(MovedOutPct) AS MovedOutPct
	,AVG(ExitedPct) AS ExitedPct
FROM Agg;


----------------------------------
-- Comparing to national averages for 2013 AY
----------------------------------

With Counts as (
	SELECT
		StartPrincipalType AS PrincipalType,
		StartYear,
		EndYear,
		SUM(Stayer) AS Stayer,
		SUM(MovedIn) AS MovedIn,
		SUM(MovedOut) AS MovedOut,
		SUM(Exited) AS Exited,
		count(*) as Total
	FROM Fact_PrincipalMobility
	where DiffYears = 1
	AND StartPrincipalType = 'Principal'
	GROUP BY
		StartYear,
		EndYear,
		StartPrincipalType
)
,Agg AS (
	SELECT
		*,
		cast(Stayer AS real) / cast(Total as real) as StayerPct,
		cast(MovedIn AS real) / cast(Total as real) as MovedInPct,
		cast(MovedOut AS real) / cast(Total as real) as MovedOutPct,
		cast(Exited AS real) / cast(Total as real) as ExitedPct,
		-- "Higher rates of staying in the same district for those who do move"
		cast(MovedIn AS real) / (CAST(MovedIn AS real) + CAST(MovedOut AS real)) AS StayedInDistrictAmongMoversPct
	from Counts
)
SELECT *
FROM Agg
WHERE EndYear = 2013

