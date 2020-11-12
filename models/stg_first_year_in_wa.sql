
{{
    config({
        "pre-hook": [
            "DROP INDEX IF EXISTS idx_stg_first_year_in_wa"
        ]
        ,"post-hook": [
            """
			CREATE INDEX idx_stg_first_year_in_wa ON stg_first_year_in_wa (
			    CertificateNumber,
			    FirstYear
			)
            """
        ]
    })
}}

SELECT
    CertificateNumber,
    MIN(AcademicYear) AS FirstYear
FROM {{ ref('stg_dim_staff') }}
WHERE CertificateNumber is not null
GROUP BY
    CertificateNumber;
