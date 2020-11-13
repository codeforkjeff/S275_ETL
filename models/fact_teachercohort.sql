
{{
    config({
        "pre-hook": [
            "DROP INDEX IF EXISTS idx_fact_teachercohort"
        ]
        ,"post-hook": [
            """
            CREATE UNIQUE INDEX idx_fact_teachercohort ON fact_teachercohort (
				CertificateNumber, CohortYear
            )
            """
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
FROM {{ ref('fact_teachermobility') }}
WHERE
	DiffYears = 1
	-- handful of rows where Building is null from raw file. no idea what these mean.
	AND StartBuilding IS NOT NULL
