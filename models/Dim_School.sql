
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}",
			"{{ drop_index(2) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['AcademicYear', 'DistrictCode', 'SchoolCode']) }}",
            "{{ create_index(2, ['AcademicYear', 'SchoolCode', 'DistrictCode']) }}"
        ]
    })
}}

SELECT
	base.AcademicYear,
	base.DistrictCode,
	DistrictName,
	base.SchoolCode,
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
	tc.TeachersOfColor,
	tc.TotalTeachers,
	COALESCE(PrincipalOfColorFlag, 0) AS PrincipalOfColorFlag,
	COALESCE(AsstPrincipalOfColorFlag, 0) AS AsstPrincipalOfColorFlag,
	{{ getdate_fn() }} AS MetaCreatedAt
FROM {{ ref('Stg_School_Backfilled') }} base
LEFT JOIN {{ ref('Stg_TeacherCounts') }} tc
	ON tc.AcademicYear = base.AcademicYear
	AND tc.CountyAndDistrictCode = base.DistrictCode
	AND tc.Building = base.SchoolCode
LEFT JOIN {{ ref('Stg_PrincipalsOfColor') }} pc
	ON pc.AcademicYear = base.AcademicYear
	AND pc.CountyAndDistrictCode = base.DistrictCode
	AND pc.Building = base.SchoolCode
	