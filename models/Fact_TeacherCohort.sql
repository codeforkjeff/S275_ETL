
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['CertificateNumber', 'CohortYear'], unique=True) }}"
        ]
    })
}}

SELECT
    StartYear AS CohortYear
	,StartStaffID AS CohortStaffID
	,CertificateNumber
    ,StartCountyAndDistrictCode AS CohortCountyAndDistrictCode
    ,StartBuilding AS CohortBuilding
    ,{{ getdate_fn() }} as MetaCreatedAt
FROM {{ ref('Fact_TeacherMobility') }}
WHERE
	DiffYears = 1
	-- handful of rows where Building is null from raw file. no idea what these mean.
	AND StartBuilding IS NOT NULL
