
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['CertificateNumber', 'FirstYear']) }}"
        ]
    })
}}

SELECT
    CertificateNumber,
    MIN(AcademicYear) AS FirstYear
FROM {{ ref('Stg_Dim_Staff') }}
WHERE CertificateNumber is not null
GROUP BY
    CertificateNumber;
