
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['CertificateNumber', 'AcademicYear']) }}"
        ]
    })
}}

-- do selection to create one row per cert/year
-- picking the highest assignment FTE, used to calculate the location of endyear
WITH T AS (
    SELECT
        t.StaffID
        ,t.AcademicYear
        ,CertificateNumber
        ,s.CountyAndDistrictCode
        ,Building
        ,ROW_NUMBER() OVER (PARTITION BY
            t.AcademicYear,
            CertificateNumber
        ORDER BY
            AssignmentFTEDesignation DESC,
            -- tiebreaking below this line
            AssignmentPercent DESC,
            AssignmentSalaryTotal DESC
        ) as RN
    FROM {{ ref('Fact_Assignment') }} t
    JOIN {{ ref('Dim_Staff') }} s
        ON t.StaffID = s.StaffID
)
SELECT
    StaffID
    ,AcademicYear
    ,CertificateNumber
    ,CountyAndDistrictCode
    ,Building
FROM T
WHERE RN = 1
