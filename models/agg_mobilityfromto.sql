
WITH
DistrictCodes AS (
	SELECT
		DistrictCode,
		max(DistrictName) as DistrictName
	FROM {{ ref('dim_school') }}
	GROUP BY DistrictCode
)
,Base AS (
	SELECT
		StartYear,
		EndYear,
		--ind.Indicator,

		StartCountyAndDistrictCode as StartDistrictCode,
		--StartSch.DistrictNameReporting AS StartDistrictName,
		--StartBuilding AS StartSchoolCode,
		--StartSch.SchoolName AS StartSchoolName,
		--StartSch.dRoadMapRegionFlag AS StartRMRFlag,

		EndCountyAndDistrictCode as EndDistrictCode,
		--EndSch.DistrictNameReporting AS EndDistrictName,
		--EndBuilding AS EndSchoolCode,
		--EndSch.SchoolName AS EndSchoolName,
		--EndSch.dRoadMapRegionFlag AS EndRMRFlag,

		Stayer,
		MovedIn,
		MovedOut,
		Exited

	FROM {{ ref('fact_teachermobility') }} m
	JOIN {{ ref('dim_staff') }} staff
		ON m.StartStaffID = staff.StaffID
)
,Agg AS (
	SELECT
		StartYear
		,EndYear
		,StartDistrictCode
		,EndDistrictCode
		,SUM(Stayer) AS Stayer
		,SUM(MovedIn) AS MovedIn
		,SUM(MovedOut) AS MovedOut
		,SUM(Exited) AS Exited
	FROM Base
	GROUP BY
		StartYear
		,EndYear
		,StartDistrictCode
		,EndDistrictCode
)
SELECT
	StartYear
	,EndYear
	,StartDistrictCode
	,StartDistrict.DistrictName AS StartDistrictName
	,EndDistrictCode
	,EndDistrict.DistrictName AS EndDistrictName
	,Stayer
	,MovedIn
	,MovedOut
	,Exited
	,{{ getdate_fn() }} as MetaCreatedAt
FROM Agg
LEFT JOIN DistrictCodes StartDistrict
	ON StartDistrict.DistrictCode = StartDistrictCode
LEFT JOIN DistrictCodes EndDistrict
	ON EndDistrict.DistrictCode = EndDistrictCode
ORDER BY
	StartYear
	,EndYear
	,StartDistrictCode
	,EndDistrictCode
