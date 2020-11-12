
{{
    config({
        "pre-hook": [
            "DROP INDEX IF EXISTS idx_stg_first_year_in_district"
        ]
        ,"post-hook": [
            """
			CREATE INDEX idx_stg_first_year_in_district ON stg_first_year_in_district (
			    CertificateNumber,
			    CountyAndDistrictCode,
			    FirstYear
			)
            """
        ]
    })
}}

SELECT
    CertificateNumber,
    CountyAndDistrictCode,
    MIN(AcademicYear) AS FirstYear
FROM {{ ref('stg_dim_staff') }}
WHERE CertificateNumber is not null
GROUP BY
    CertificateNumber,
    CountyAndDistrictCode
