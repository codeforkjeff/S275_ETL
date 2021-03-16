
-- sqlite and SQL Server don't have compatible VALUES syntax
-- hence the ugly unions

WITH
-- Indicators AS (
-- 	SELECT 'Stayer' AS Indicator
-- 	UNION ALL
-- 	SELECT 'MovedIn' AS Indicator
-- 	UNION ALL
-- 	SELECT 'MovedOut' AS Indicator
-- 	UNION ALL
-- 	SELECT 'Exited' AS Indicator
-- )
-- ,SubgroupCategories AS (
-- 	SELECT 'All' AS SubGroupCategory
-- 	UNION ALL
-- 	SELECT 'Race' AS SubGroupCategory
-- 	UNION ALL
-- 	SELECT 'Gender' AS SubGroupCategory
-- 	UNION ALL
-- 	SELECT 'HighestDegree' AS SubGroupCategory
-- 	UNION ALL
-- 	SELECT 'YearsExperience' AS SubGroupCategory
-- )
LongTable AS (
	-- this is basically a unpivot
	SELECT
		StartYear,
		EndYear,
		DiffYears,
		ind.Indicator,
		RMRFlag,
		CASE WHEN s.RMRFlag = 1 THEN 'RMP' ELSE NULL END AS Region,
		StartCountyAndDistrictCode as DistrictCode,
		s.DistrictName AS DistrictName,
		StartBuilding AS SchoolCode,
		s.SchoolName,
		cat.SubGroupCategory,
		CASE
			WHEN cat.SubGroupCategory = 'All' THEN 'All'
			WHEN cat.SubGroupCategory = 'Race' THEN COALESCE(staff.RaceEthOSPI, 'Race Not Provided')
			WHEN cat.SubGroupCategory = 'Gender' THEN COALESCE(
				CASE
					WHEN staff.Sex = 'M' THEN 'Male'
					WHEN staff.Sex = 'F' THEN 'Female'
				END, 'Gender Not Provided')
			WHEN cat.SubGroupCategory = 'HighestDegree' THEN COALESCE(staff.HighestDegree, 'Highest Degree Not Provided')
			WHEN cat.SubGroupCategory = 'YearsExperience' THEN
				CASE
					WHEN CertYearsOfExperience <= 4.5 THEN '0-4'
					WHEN CertYearsOfExperience > 4.5 AND CertYearsOfExperience <= 14.5 THEN '05-14'
					WHEN CertYearsOfExperience > 14.5 AND CertYearsOfExperience <= 24.5 THEN '15-24'
					WHEN CertYearsOfExperience > 24.5 THEN '25+'
				END
			ELSE NULL
		END AS Subgroup,
		CASE
			WHEN ind.Indicator = 'Stayer' THEN Stayer
			WHEN ind.Indicator = 'MovedIn' THEN MovedIn
			WHEN ind.Indicator = 'MovedOut' THEN MovedOut
			WHEN ind.Indicator = 'Exited' THEN Exited
		END AS Met
	FROM {{ ref('Fact_TeacherMobility') }}  m
	JOIN {{ ref('Dim_Staff') }} staff
		ON m.StartStaffID = staff.StaffID
	JOIN {{ ref('Dim_School') }} s
		ON m.StartBuilding = s.SchoolCode
		and s.AcademicYear = 2018
	CROSS JOIN {{ ref('SubgroupCategories') }} cat
	CROSS JOIN {{ ref('Indicators') }} ind
)
,Aggregated AS (
	-- sqlite doesn't have GROUPING SETS so use UNION ALL
	SELECT
		StartYear,
		EndYear,
		Indicator,
		Region,
		NULL AS DistrictCode,
		NULL AS DistrictName,
		NULL AS SchoolCode,
		NULL AS SchoolName,
		SubGroupCategory,
		Subgroup,
		SUM(Met) AS Met,
		count(*) as Total
	FROM LongTable
	WHERE
		RMRFlag = 1
	GROUP BY
		StartYear, EndYear, Indicator, Region, SubGroupCategory, Subgroup
	UNION ALL
	SELECT
		StartYear,
		EndYear,
		Indicator,
		Region,
		DistrictCode,
		DistrictName,
		NULL AS SchoolCode,
		NULL AS SchoolName,
		SubGroupCategory,
		Subgroup,
		SUM(Met) AS Met,
		count(*) as Total
	FROM LongTable
	WHERE
		RMRFlag = 1
	GROUP BY
		StartYear, EndYear, Indicator, Region, DistrictCode, DistrictName, SubGroupCategory, Subgroup
	UNION ALL
	SELECT
		StartYear,
		EndYear,
		Indicator,
		Region,
		DistrictCode,
		DistrictName,
		SchoolCode,
		SchoolName,
		SubGroupCategory,
		Subgroup,
		SUM(Met) AS Met,
		count(*) as Total
	FROM LongTable
	WHERE
		RMRFlag = 1
	GROUP BY
		StartYear, EndYear, Indicator, Region, DistrictCode, DistrictName, SchoolCode, SchoolName, SubGroupCategory, Subgroup
)
SELECT
	StartYear,
	EndYear,
	Indicator,
	Region,
	DistrictCode,
	CASE WHEN DistrictName = 'Seattle Public Schools' THEN 'South Seattle' ELSE DistrictName END AS DistrictName,
	SchoolCode,
	SchoolName,
	SubGroupCategory,
	Subgroup,
	Met,
	Total,
	CAST(Met AS {{ t_real() }}) / Total AS Percentage,
	{{ getdate_fn() }} as MetaCreatedAt
FROM Aggregated
