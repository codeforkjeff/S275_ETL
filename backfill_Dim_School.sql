
WITH MissingSchoolsBase as (
	SELECT AcademicYear, Building
	FROM Fact_Assignment
	WHERE Building is not null
	EXCEPT
	SELECT DISTINCT AcademicYear, SchoolCode
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
			m.AcademicYear, m.Building
			ORDER BY
				-- prioritize closest year (smallest difference), and then the earlier year if both earlier and later years exist
				ABS(m.AcademicYear - s.AcademicYear), s.AcademicYear ASC
		) AS Rank
	FROM MissingSchoolsBase m
	LEFT JOIN Dim_School s
		ON m.Building = s.SchoolCode
),
MissingSchools AS (
	SELECT
		AcademicYear,
		Building,
		ExistingYearInDimSchool AS ClosestYearThatExists
	FROM MissingSchoolsCombos
	WHERE Rank = 1
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
	,COALESCE(s.DistrictCode, 'UNKNOWN') AS DistrictCode
	,COALESCE(s.DistrictName, 'UNKNOWN') AS DistrictName
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
	ON missing.Building = s.SchoolCode
	AND missing.ClosestYearThatExists = s.AcademicYear
;
