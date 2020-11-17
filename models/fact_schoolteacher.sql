t

{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}",
            "{{ drop_index(2) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['StaffID', 'AcademicYear']) }}",
            "{{ create_index(2, ['AcademicYear', 'StaffID']) }}",
        ]
    })
}}

WITH TeachingRollups AS (
    select
        {% call concat() %}CAST(a.StaffID AS VARCHAR(500)) + CAST(a.AcademicYear AS VARCHAR(4)) + CAST(Building AS VARCHAR(100)){% endcall %} AS SchoolTeacherID
        ,a.StaffID
        ,a.AcademicYear
        ,Building
        ,COALESCE(SUM(AssignmentPercent), 0) AS TeachingPercent
        ,SUM(AssignmentFTEDesignation) AS TeachingFTEDesignation
        ,SUM(AssignmentSalaryTotal) AS TeachingSalaryTotal
        ,{{ getdate_fn() }} as MetaCreatedAt
    from {{ ref('Fact_Assignment') }} a
    JOIN {{ ref('Dim_Staff') }} s ON a.StaffID = s.StaffID
    WHERE IsTeachingAssignment = 1
    GROUP BY
        a.StaffID
        ,a.AcademicYear
        ,Building
)
,Filtered AS (
    SELECT *
    FROM TeachingRollups
    WHERE NOT (
        EXISTS (
            SELECT 1
            FROM {{ ref('Dim_Staff') }} s
            WHERE s.StaffID = TeachingRollups.StaffID
            AND (CertificateNumber IS NULL OR CertificateNumber = '')
        )
        OR TeachingFTEDesignation IS NULL
        OR TeachingFTEDesignation <= 0
    )
)
,Ranked AS (
    SELECT
        SchoolTeacherID
        ,row_number() OVER (
            PARTITION BY
                st.AcademicYear,
                CertificateNumber
            ORDER BY
                TeachingFTEDesignation DESC,
                -- tiebreaking below this line
                TeachingPercent DESC,
                TeachingSalaryTotal DESC
        ) AS RN
    FROM Filtered st
    JOIN {{ ref('Dim_Staff') }} s ON st.StaffID = s.StaffID
)
SELECT
    StaffID,
    AcademicYear,
    Building,
    TeachingPercent,
    TeachingFTEDesignation,
    TeachingSalaryTotal,
    CASE WHEN r.SchoolTeacherID IS NOT NULL THEN 1 ELSE 0 END AS PrimaryFlag,
    MetaCreatedAt
FROM Filtered f
LEFT JOIN Ranked r
    ON r.RN = 1
    AND r.SchoolTeacherID = f.SchoolTeacherID
