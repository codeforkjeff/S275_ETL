
WITH MissingSchoolsBase as (
	SELECT a.AcademicYear, s.CountyAndDistrictCode, a.Building
	FROM {{ ref('fact_assignment') }} a
	JOIN {{ ref('dim_staff') }} s
		ON a.StaffID = s.StaffID
	WHERE Building is not null
	EXCEPT
	SELECT DISTINCT AcademicYear, DistrictCode, SchoolCode
	FROM {{ ref('stg_dim_school') }}
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
	LEFT JOIN {{ ref('stg_dim_school') }} s
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
	FROM {{ ref('stg_dim_school') }}
),
MostRecentDistrictNames AS (
	SELECT
		DistrictCode,
		DistrictName
	FROM DistrictNames
	WHERE RN = 1
)
SELECT 
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
	TotalEnrollmentOct,
	GraduationMet,
	GraduationTotal,
	GraduationPercent,
	FRPL,
	FRPLPercent,
	AmIndOrAlaskan,
	AmIndOrAlaskanPercent,
	Asian,
	AsianPercent,
	PacIsl,
	PacIslPercent,
	AsPacIsl,
	AsPacIslPercent,
	Black,
	BlackPercent,
	Hispanic,
	HispanicPercent,
	White,
	WhitePercent,
	TwoOrMoreRaces,
	TwoOrMoreRacesPercent,
	StudentsOfColor,
	StudentsOfColorPercent,
	Male,
	MalePercent,
	Female,
	FemalePercent,
	GenderX,
	GenderXPercent,
	MetaCreatedAt
FROM {{ ref('stg_dim_school') }}
UNION ALL
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
	,NULL AS TotalEnrollmentOct
    ,NULL AS GraduationMet
    ,NULL AS GraduationTotal
    ,NULL AS GraduationPercent
    ,NULL AS FRPL
    ,NULL AS FRPLPercent
    ,NULL AS AmIndOrAlaskan
    ,NULL AS AmIndOrAlaskanPercent
    ,NULL AS Asian
    ,NULL AS AsianPercent
    ,NULL AS PacIsl
    ,NULL AS PacIslPercent
    ,NULL AS AsPacIsl
    ,NULL AS AsPacIslPercent
    ,NULL AS Black
    ,NULL AS BlackPercent
    ,NULL AS Hispanic
    ,NULL AS HispanicPercent
    ,NULL AS White
    ,NULL AS WhitePercent
    ,NULL AS TwoOrMoreRaces
    ,NULL AS TwoOrMoreRacesPercent
    ,NULL AS StudentsOfColor
    ,NULL AS StudentsOfColorPercent
    ,NULL AS Male
    ,NULL AS MalePercent
    ,NULL AS Female
    ,NULL AS FemalePercent
    ,NULL AS GenderX
    ,NULL AS GenderXPercent
	,{{ getdate_fn() }} AS MetaCreatedAt
FROM MissingSchools missing
LEFT JOIN {{ ref('stg_dim_school') }} s
	ON missing.CountyAndDistrictCode = s.DistrictCode
	AND missing.Building = s.SchoolCode
	AND missing.ClosestYearThatExists = s.AcademicYear
LEFT JOIN MostRecentDistrictNames mrdn
	ON missing.CountyAndDistrictCode = mrdn.DistrictCode
