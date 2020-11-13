
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}",
            "{{ drop_index(2) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['AcademicYear', 'CertificateNumber'], unique=True) }}",
            "{{ create_index(2, ['AcademicYear', 'CertificateNumber', 'CountyAndDistrictCode', 'Building']) }}"
        ]
    })
}}

-- This logic selects a single teacher/building per year

SELECT
    s.StaffID
    ,t.AcademicYear
    ,CertificateNumber
    ,s.CountyAndDistrictCode
    ,Building
FROM {{ ref('fact_schoolteacher') }} t
JOIN {{ ref('dim_staff') }} s
    ON t.StaffID = s.StaffID
WHERE PrimaryFlag = 1
