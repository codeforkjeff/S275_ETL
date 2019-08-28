
DROP TABLE IF EXISTS Indicators;

-- next

CREATE TABLE Indicators (
	Indicator varchar(100)
);

-- next

INSERT INTO Indicators
VALUES
	('Stayer')
	,('MovedIn')
	,('MovedOut')
	,('Exited')
;

-- next

DROP TABLE IF EXISTS SubgroupCategories;

-- next

CREATE TABLE SubgroupCategories (
	SubGroupCategory varchar(100)
);

-- next

INSERT INTO SubgroupCategories
VALUES
	('All')
	,('Race')
	,('Gender')
	,('HighestDegree')
	,('YearsExperience')
;

-- next

DROP TABLE IF EXISTS Agg_MobilityIndicators;

-- next

CREATE TABLE Agg_MobilityIndicators (
	StartYear int NULL,
	EndYear int NULL,
	Indicator varchar(8) NULL,
	Region varchar(3) NULL,
	DistrictCode varchar(500) NULL,
	DistrictName varchar(250) NULL,
	SchoolCode varchar(500) NULL,
	SchoolName varchar(250) NULL,
	SubGroupCategory varchar(15) NULL,
	Subgroup varchar(500) NULL,
	Met int NULL,
	Total int NULL,
	Percentage real NULL,
	MetaCreatedAt DATETIME
);

-- next

WITH
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
	FROM Fact_TeacherMobility m
	JOIN Dim_Staff staff
		ON m.StartStaffID = staff.StaffID
	JOIN Dim_School s
		ON m.StartBuilding = s.SchoolCode
		and s.AcademicYear = 2018
	CROSS JOIN SubgroupCategories cat
	CROSS JOIN Indicators ind
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
INSERT INTO Agg_MobilityIndicators (
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
	Met,
	Total,
	Percentage,
	MetaCreatedAt
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
	CAST(Met AS REAL) / Total AS Percentage,
	GETDATE() as MetaCreatedAt
FROM Aggregated;

-- next

DROP TABLE IF EXISTS Agg_MobilityFromTo;

-- next

CREATE TABLE Agg_MobilityFromTo (
	StartYear int NOT NULL,
	EndYear int NULL,
	StartDistrictCode varchar(500) NULL,
	StartDistrictName varchar(250) NULL,
	EndDistrictCode varchar(500) NULL,
	EndDistrictName varchar(250) NULL,
	Stayer int NULL,
	MovedIn int NULL,
	MovedOut int NULL,
	Exited int NULL,
	MetaCreatedAt DATETIME
);

-- next

WITH
DistrictCodes AS (
	SELECT
		DistrictCode,
		max(DistrictName) as DistrictName
	FROM Dim_School
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

	FROM Fact_TeacherMobility m
	JOIN Dim_Staff staff
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
INSERT INTO Agg_MobilityFromTo (
	StartYear,
	EndYear,
	StartDistrictCode,
	StartDistrictName,
	EndDistrictCode,
	EndDistrictName,
	Stayer,
	MovedIn,
	MovedOut,
	Exited,
	MetaCreatedAt
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
	,GETDATE() as MetaCreatedAt
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

