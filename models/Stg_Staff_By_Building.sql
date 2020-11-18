
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

-- this is table used to determine EndYear fields: we need this to account
-- for teachers who stopped being teachers but are still in the system

-- FIXME: this rolls up to a building, and hence, more than row for a person/year row,
-- which results multiple rows in the transitions table for a person/year.

-- query assignments here, b/c we want to know if teachers became non-teachers

WITH T AS (
    SELECT
        t.StaffID
        ,t.AcademicYear
        ,CertificateNumber
        ,s.CountyAndDistrictCode
        ,Building
        ,MAX(IsTeachingAssignment) AS TeacherFlag
        ,ROW_NUMBER() OVER (PARTITION BY
            t.AcademicYear,
            CertificateNumber
        ORDER BY
            SUM(AssignmentFTEDesignation) DESC,
            -- tiebreaking below this line
            SUM(AssignmentPercent) DESC,
            SUM(AssignmentSalaryTotal) DESC
        ) as RN
    FROM {{ ref('Fact_Assignment') }} t
    JOIN {{ ref('Dim_Staff') }} s
        ON t.StaffID = s.StaffID
    GROUP BY
        t.StaffID
        ,t.AcademicYear
        ,CertificateNumber
        ,s.CountyAndDistrictCode
        ,Building
)
SELECT
    StaffID,
    AcademicYear,
    CertificateNumber,
    CountyAndDistrictCode,
    Building,
    TeacherFlag
FROM T
WHERE RN = 1
