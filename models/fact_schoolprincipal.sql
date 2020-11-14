-- we need this table for per-building rolled up fields, can't simply extend Fact_Assignment
--
-- grain of this table is StaffID (whose grain is AY, District, CertNumber), Building, PrincipalType.
-- this rolls up the 2 different DutyRoot codes for Principal and AssistantPrincipal, which are used to distinguish
-- between primary and secondary schools. It also rolls up multiple Assignments for the same DutyRoot:
-- Principals and APs sometimes have separate assignment line items by Grade Level.
--
-- since this table contains every principal/AP at every school they served at, users of this table
-- will typically want to filter by PrimaryFlag (to get one principal/AP per person/year)
-- or PrimaryForSchoolFlag (to get one principal/AP per school/year)

WITH AssignmentsWithPrincipalType AS (
    SELECT
        *
        ,CASE
            WHEN cast(DutyRoot as integer) IN (21, 23) THEN 'Principal'
            WHEN cast(DutyRoot as integer) IN (22, 24) THEN 'AssistantPrincipal'
        END AS PrincipalType
    FROM {{ ref('fact_assignment') }}
)
,Rolledup AS (
    select
        a.StaffID
        ,a.AcademicYear
        ,CountyAndDistrictCode
        ,Building
        ,PrincipalType
        ,COALESCE(SUM(AssignmentPercent), 0) AS PrincipalPercentage
        ,SUM(AssignmentFTEDesignation) AS PrincipalFTEDesignation
        ,SUM(AssignmentSalaryTotal) AS PrincipalSalaryTotal
        ,0 AS PrimaryFlag
        ,0 AS PrimaryForSchoolFlag
    from AssignmentsWithPrincipalType a
    JOIN {{ ref('dim_staff') }} s ON a.StaffID = s.StaffID
    WHERE IsPrincipalAssignment = 1 OR IsAsstPrincipalAssignment = 1
    GROUP BY
        a.StaffID
        ,a.AcademicYear
        ,CountyAndDistrictCode
        ,Building
        -- is this right? or should we group by rolled up PrincipalType?
        ,PrincipalType
)
,Filtered AS (
    SELECT
        {% call concat() %}CAST(StaffID AS VARCHAR(500)) + CAST(Building AS VARCHAR(100)) + CAST(PrincipalType AS VARCHAR(100)){% endcall %} AS SchoolPrincipalID
        ,*
    FROM Rolledup
    WHERE NOT (
        PrincipalFTEDesignation IS NULL
        OR PrincipalFTEDesignation <= 0
    )
)
,T_PrimaryFlag AS (

    -- PrimaryFlag = pick the assighnment w/ highest FTE for the individual across
    -- all schools where they serve, regardless of whether they were a Principal or Asst Prin.
    -- It is NOT the "primary" Principal at the school (a school can sometimes have more than
    -- one principal)

    SELECT
        SchoolPrincipalID
        ,row_number() OVER (
            PARTITION BY
                sp.AcademicYear,
                CertificateNumber
            ORDER BY
                PrincipalFTEDesignation DESC,
                -- TODO: add school enrollment count as tiebreaker
                -- tiebreaking below this line
                PrincipalPercentage DESC,
                PrincipalSalaryTotal DESC
        ) AS RN
    FROM Filtered sp
    JOIN {{ ref('dim_staff') }} s ON sp.StaffID = s.StaffID
)
,T_PrimaryForSchoolFlag AS (

    -- PrimaryForSchoolFlag = who is the Principal and AP with the highest FTE at each building?
    -- better logic for this flag might be who served the longest during that year,
    -- but we don't have start/end dates for assignments

    SELECT
        SchoolPrincipalID
        ,row_number() OVER (
            PARTITION BY
                sp.AcademicYear,
                sp.CountyAndDistrictCode,
                sp.Building,
                sp.PrincipalType
            ORDER BY
                PrincipalFTEDesignation DESC,
                PrincipalPercentage DESC,
                PrincipalSalaryTotal DESC,
                CertYearsOfExperience DESC
        ) AS RN
    FROM Filtered sp
    JOIN {{ ref('dim_staff') }}  s ON sp.StaffID = s.StaffID
)
SELECT
    base.SchoolPrincipalID,
    StaffID,
    AcademicYear,
    CountyAndDistrictCode,
    Building,
    PrincipalType,
    PrincipalPercentage,
    PrincipalFTEDesignation,
    PrincipalSalaryTotal,
    CASE WHEN T_PrimaryFlag.SchoolPrincipalID IS NOT NULL THEN 1 ELSE 0 END AS PrimaryFlag,
    CASE WHEN T_PrimaryForSchoolFlag.SchoolPrincipalID IS NOT NULL THEN 1 ELSE 0 END AS PrimaryForSchoolFlag,
    {{ getdate_fn() }} as MetaCreatedAt
FROM Filtered base
LEFT JOIN T_PrimaryFlag
    ON T_PrimaryFlag.RN = 1
    AND base.SchoolPrincipalID = T_PrimaryFlag.SchoolPrincipalID
LEFT JOIN T_PrimaryForSchoolFlag
    ON T_PrimaryForSchoolFlag.RN = 1
    AND base.SchoolPrincipalID = T_PrimaryForSchoolFlag.SchoolPrincipalID
