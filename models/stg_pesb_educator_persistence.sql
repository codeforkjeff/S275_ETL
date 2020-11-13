
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['CertificateNumber', 'CohortYear', 'EndYear']) }}"
        ]
    })
}}

WITH DistinctEducators AS (
	-- since we're collapsing multiple assignments at multiple buildings into single rows,
	-- we necessarily do some selection here
	SELECT
		a.AcademicYear
		,s.CertificateNumber
		,MAX(s.IsInPSESDFlag) AS CohortInPSESDFlag
		-- flag is set if educator was 'Beginning' in any district
		,MAX(CASE WHEN s.CBRTNCode = 'B' THEN 1 ELSE 0 END) as BeginningEducatorFlag
		-- MIN() here will bias towards non-White people if they identified differently
		-- in diff districts in same yr
		,MIN(RaceEthOSPI) AS Race
		-- use MIN() to bias towards 'Person of Color' vs 'White':
		-- i.e. if they identified anywhere as POC for that year, consider them POC.
		-- I tried this with MAX and it doesn't make a difference, which means peoples'
		-- racial identifications are highly  consistent when they work in multiple districts
		,MIN(PersonOfColorCategory) AS PersonOfColorCategory
	FROM {{ ref('fact_assignment') }} a
	JOIN {{ ref('dim_staff') }} s
		ON a.StaffID = s.StaffID
	WHERE
		a.IsPESBEducatorAssignment = 1
		-- handful of rows where CertNumber is null
		AND s.CertificateNumber IS NOT NULL
		-- A note on PESB's Tableau viz says: "2016-17 starting cohort does not include beginning
		-- teachers from Bellevue School District due to probable reporting error."
		-- We follow that here.
		AnD NOT (a.AcademicYear = 2017 and s.CountyAndDistrictCode = '17405')
	GROUP BY
		a.AcademicYear
		,s.CertificateNumber

)
SELECT
		e.CertificateNumber
		,e.AcademicYear AS CohortYear
		,e.CohortInPSESDFlag AS CohortInPSESDFlag
		,e.BeginningEducatorFlag AS CohortBeginningEducatorFlag
		,e.Race AS CohortRace
		,e.PersonOfColorCategory AS CohortPersonOfColorCategory
		,endyears.AcademicYear AS EndYear
		-- note that the year count includes the Cohort Year:
		-- e.g. 2013 AY to 2014 AY would be considered 2 year persistence
		,endyears.AcademicYear - e.AcademicYear + 1 AS YearCount
		,{{ getdate_fn() }} as MetaCreatedAt
FROM DistinctEducators e
CROSS JOIN
	(
		SELECT DISTINCT
			AcademicYear
		FROM {{ ref('dim_staff') }}
	) AS endyears
WHERE
	-- limit to 2010 so table isn't enormous
	e.AcademicYear >= 2010
	AND e.AcademicYear < endyears.AcademicYear
