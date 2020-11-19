
-- TODO: add tests for  NOT NULL

SELECT
	CAST(AcademicYear AS INT) AS AcademicYear, -- NOT NULL
	CAST(DistrictCode AS varchar(8)) AS DistrictCode,
	CAST(DistrictName AS varchar(250)) AS DistrictName,
	CAST(SchoolCode AS varchar(8)) AS SchoolCode,
	CAST(SchoolName AS varchar(250)) AS SchoolName,
	CAST(GradeLevelStart AS varchar(3)) AS GradeLevelStart,
	CAST(GradeLevelEnd AS varchar(3)) AS GradeLevelEnd,
	CAST(GradeLevelSortOrderStart AS tinyint) AS GradeLevelSortOrderStart,
	CAST(GradeLevelSortOrderEnd AS tinyint) AS GradeLevelSortOrderEnd,
	CAST(SchoolType AS varchar(50)) AS SchoolType,
	CAST(Lat AS real) AS Lat,
	CAST(Long AS real) AS Long,
	CAST(NCESLocaleCode AS VARCHAR(2)) AS NCESLocaleCode,
	CAST(NCESLocale AS VARCHAR(50)) AS NCESLocale,
	CAST(RMRFlag AS INT) AS RMRFlag
FROM {{ source('sources', 'Raw_School_Base') }}
