
WITH MissingSchoolsBase as (
	SELECT a.AcademicYear, s.CountyAndDistrictCode, a.Building
	FROM Fact_Assignment a
	JOIN Dim_Staff s
		ON a.StaffID = s.StaffID
	WHERE Building is not null
	EXCEPT
	SELECT DISTINCT AcademicYear, DistrictCode, SchoolCode
	FROM Dim_School
	WHERE SchoolCode is not null
)
,MissingSchoolsCombos AS (
	-- create all combinations of missing years * existing years; then rank to get the closest one
	SELECT
		m.*
		,s.AcademicYear AS ExistingYearInDimSchool
		,m.AcademicYear - s.AcademicYear AS YearDiff
		,ROW_NUMBER() OVER (
			PARTITION BY
			m.AcademicYear, m.CountyAndDistrictCode, m.Building
			ORDER BY
				-- prioritize closest year (smallest difference), and then the earlier year if both earlier and later years exist
				ABS(m.AcademicYear - s.AcademicYear), s.AcademicYear ASC
		) AS Rank
	FROM MissingSchoolsBase m
	LEFT JOIN Dim_School s
		ON m.CountyAndDistrictCode = s.DistrictCode
		AND m.Building = s.SchoolCode
),
MissingSchools AS (
	SELECT
		AcademicYear,
		CountyAndDistrictCode,
		Building,
		ExistingYearInDimSchool AS ClosestYearThatExists
	FROM MissingSchoolsCombos
	WHERE Rank = 1
),
DistrictNames as (
	SELECT
		AcademicYear,
		DistrictCode,
		DistrictName,
		ROW_NUMBER() OVER (
			PARTITION BY
				DistrictCode
			ORDER BY
				AcademicYear DESC
		) AS RN
	FROM Dim_School
),
MostRecentDistrictNames AS (
	SELECT
		DistrictCode,
		DistrictName
	FROM DistrictNames
	WHERE RN = 1
)
INSERT INTO Dim_School
(
    AcademicYear,
    DistrictCode,
    DistrictName,
    SchoolCode,
    SchoolName,
	GradeLevelStart,
    GradeLevelEnd,
    GradeLevelSortOrderStart,
    GradeLevelSortOrderEnd,
    SchoolType,
    Lat,
    Long,
    NCESLocaleCode,
    NCESLocale,
    RMRFlag,
    MetaCreatedAt
)
SELECT
	missing.AcademicYear
	,missing.CountyAndDistrictCode AS DistrictCode
	,COALESCE(s.DistrictName, mrdn.DistrictName, 'UNKNOWN') AS DistrictName
	,missing.Building AS SchoolCode
	,COALESCE(s.SchoolName, 'UNKNOWN') AS SchoolName
	,s.GradeLevelStart
    ,s.GradeLevelEnd
    ,s.GradeLevelSortOrderStart
    ,s.GradeLevelSortOrderEnd
    ,s.SchoolType
	,s.Lat
    ,s.Long
    ,s.NCESLocaleCode
    ,s.NCESLocale
	,COALESCE(s.RMRFlag, 0) AS RMRFlag
	,GETDATE() AS MetaCreatedAt
FROM MissingSchools missing
LEFT JOIN Dim_School s
	ON missing.CountyAndDistrictCode = s.DistrictCode
	AND missing.Building = s.SchoolCode
	AND missing.ClosestYearThatExists = s.AcademicYear
LEFT JOIN MostRecentDistrictNames mrdn
	ON missing.CountyAndDistrictCode = mrdn.DistrictCode
;
