
-- TODO: add tests for  NOT NULL

SELECT
	CAST(AcademicYear AS {{ t_int() }}) AS AcademicYear, -- NOT NULL
	CAST(DistrictCode AS {{ t_varchar(8) }}) AS DistrictCode,
	CAST(DistrictName AS {{ t_varchar(250) }}) AS DistrictName,
	CAST(SchoolCode AS {{ t_varchar(8) }}) AS SchoolCode,
	CAST(SchoolName AS {{ t_varchar(250) }}) AS SchoolName,
	CAST(GradeLevelStart AS {{ t_varchar(3) }}) AS GradeLevelStart,
	CAST(GradeLevelEnd AS {{ t_varchar(3) }}) AS GradeLevelEnd,
	CAST(GradeLevelSortOrderStart AS {{ t_tinyint() }}) AS GradeLevelSortOrderStart,
	CAST(GradeLevelSortOrderEnd AS {{ t_tinyint() }}) AS GradeLevelSortOrderEnd,
	CAST(SchoolType AS {{ t_varchar(50) }}) AS SchoolType,
	CAST(Lat AS {{ t_real() }}) AS Lat,
	CAST(Long AS {{ t_real() }}) AS Long,
	CAST(NCESLocaleCode AS {{ t_varchar(2) }}) AS NCESLocaleCode,
	CAST(NCESLocale AS {{ t_varchar(50) }}) AS NCESLocale,
	CAST(RMRFlag AS {{ t_int() }}) AS RMRFlag
FROM {{ source('sources', 'Raw_School_Base') }}
