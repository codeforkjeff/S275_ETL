
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
    AcademicYear AS CohortYear
	,StaffID AS CohortStaffID
	,CertificateNumber
    ,CountyAndDistrictCode AS CohortCountyAndDistrictCode
    ,Building AS CohortBuilding
    ,{{ getdate_fn() }} as MetaCreatedAt
FROM {{ ref('Stg_Base_SchoolTeachers') }}
WHERE
	-- handful of rows where Building is null from raw file. no idea what these mean.
	Building IS NOT NULL
