
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['CertificateNumber', 'CohortYear', 'CohortPrincipalType'], unique=True) }}"
        ]
    })
}}

SELECT
    StartYear AS CohortYear
	,StartStaffID AS CohortStaffID
	,CertificateNumber
    ,StartCountyAndDistrictCode AS CohortCountyAndDistrictCode
    ,StartBuilding AS CohortBuilding
    ,StartPrincipalType AS CohortPrincipalType
    ,{{ getdate_fn() }} as MetaCreatedAt
FROM Fact_PrincipalMobility
WHERE
	DiffYears = 1
	-- handful of rows where Building is null from raw file. no idea what these mean.
	AND StartBuilding IS NOT NULL
	-- one row in 2014 where certificatnumber is null
	AND CertificateNumber IS NOT NULL
