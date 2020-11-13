
{{
    config({
        "pre-hook": [
            "DROP INDEX IF EXISTS idx_stg_base_schoolteachers"
        ]
        ,"post-hook": [
            """
            CREATE INDEX idx_stg_base_schoolteachers ON stg_base_schoolteachers (
                AcademicYear
                ,CertificateNumber
                ,CountyAndDistrictCode
                ,Building
            )
            """
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
