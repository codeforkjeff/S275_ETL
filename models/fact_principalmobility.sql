
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}",
            "{{ drop_index(2) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['StartStaffID', 'EndStaffID']) }}",
            "{{ create_index(2, ['StartYear', 'StartCountyAndDistrictCode', 'StartBuilding']) }}",
        ]
    })
}}

WITH
YearBrackets AS (
    SELECT DISTINCT
        AcademicYear AS StartYear,
        AcademicYear + 1 AS EndYear
    FROM {{ ref('stg_base_school_principals') }} y1
    WHERE EXISTS (
        SELECT 1 FROM {{ ref('stg_base_school_principals') }} WHERE AcademicYear = y1.AcademicYear + 1
    )
    UNION ALL
    SELECT DISTINCT
        AcademicYear AS StartYear,
        AcademicYear + 4 AS EndYear
    FROM {{ ref('stg_base_school_principals') }} y2
    WHERE EXISTS (
        SELECT 1 FROM {{ ref('stg_base_school_principals') }} WHERE AcademicYear = y2.AcademicYear + 4
    )
)
,TransitionsBase AS (
    SELECT
        t1.StaffID AS StartStaffID,
        t2.StaffID AS EndStaffID,
        t1.AcademicYear AS StartYear,
        y.EndYear AS EndYear,
        y.EndYear - t1.AcademicYear AS DiffYears,
        t1.CertificateNumber,
        -- start fields
        t1.CountyAndDistrictCode AS StartCountyAndDistrictCode,
        t1.Building AS StartBuilding,
        t1.PrincipalType AS StartPrincipalType,
        -- end fields, using StaffByHighestFTE
        t2.CountyAndDistrictCode AS EndStaffByHighestFTECountyAndDistrictCode,
        t2.Building AS EndStaffByHighestFTEBuilding,
        --t2.DutyRoot AS EndStaffByHighestFTEDutyRoot,
        -- end fields, using principals table
        t3.PrincipalType AS EndPrincipalType,
        -- avoid counting exiters by checking for join to a StaffByHighestFTE row to ensure they're still employed somehow;
        -- if join didn't match anything in BaseSchoolPrincipals, then person isn't a Principal or AP in endyear
        CASE WHEN t2.CertificateNumber IS NOT NULL AND t3.CertificateNumber IS NULL THEN 1 ELSE 0 END AS NoLongerAnyPrincipal
    FROM {{ ref('stg_base_school_principals') }} t1
    JOIN YearBrackets y
        ON t1.AcademicYear = y.StartYear
    -- join to a wide set of staff/yr/highest duty root
    LEFT JOIN {{ ref('stg_staff_by_highest_fte') }} t2
        ON t1.CertificateNumber = t2.CertificateNumber
        AND y.EndYear = t2.AcademicYear
    -- join to a set of principals
    LEFT JOIN {{ ref('stg_base_school_principals') }} t3
        ON t1.CertificateNumber = t3.CertificateNumber
        AND y.EndYear = t3.AcademicYear
)
,Transitions AS (
    SELECT
        *
        -- mobility for principals is based strictly on location
        ,CASE WHEN StartBuilding = EndStaffByHighestFTEBuilding THEN 1 ELSE 0 END as Stayer
        ,CASE WHEN
            StartBuilding <> EndStaffByHighestFTEBuilding AND StartCountyAndDistrictCode = EndStaffByHighestFTECountyAndDistrictCode
        THEN 1 ELSE 0 END as MovedIn
        ,CASE WHEN
            StartCountyAndDistrictCode <> EndStaffByHighestFTECountyAndDistrictCode
        THEN 1 ELSE 0 END as MovedOut
        ,CASE WHEN
            EndStaffByHighestFTEBuilding IS NULL
        THEN 1 ELSE 0 END AS Exited
        ,CASE WHEN StartPrincipalType = EndPrincipalType THEN 1 ELSE 0 END AS SameAssignment
        ,CASE
            WHEN StartPrincipalType = 'AssistantPrincipal' AND EndPrincipalType = 'Principal'
        THEN 1 ELSE 0 END AS AsstToPrincipal
        ,CASE
            WHEN StartPrincipalType = 'Principal' AND EndPrincipalType = 'AssistantPrincipal'
        THEN 1 ELSE 0 END AS PrincipalToAsst
    FROM TransitionsBase
)
SELECT
    StartStaffID
    ,EndStaffID
    ,StartYear
    ,EndYear
    ,DiffYears
    ,CertificateNumber
    ,StartCountyAndDistrictCode
    ,StartBuilding
    ,StartPrincipalType
    ,EndStaffByHighestFTECountyAndDistrictCode
    ,EndStaffByHighestFTEBuilding
    ,EndPrincipalType
    ,Stayer
    ,MovedIn
    ,MovedOut
    ,CASE
    WHEN MovedOut = 1
        AND EXISTS (
            SELECT 1
            FROM {{ ref('dim_school') }}
            WHERE
                Transitions.StartYear = AcademicYear
                AND Transitions.StartBuilding = SchoolCode
            AND RMRFlag = 1
            )
        AND NOT EXISTS (
            SELECT 1
            FROM {{ ref('dim_school') }}
            WHERE
                Transitions.EndYear = AcademicYear
                AND Transitions.EndStaffByHighestFTEBuilding = SchoolCode
            AND RMRFlag = 1
            )
    THEN 1
    ELSE 0
    END AS MovedOutOfRMR
    ,Exited
    ,SameAssignment
    ,NoLongerAnyPrincipal
    ,AsstToPrincipal
    ,PrincipalToAsst
    ,{{ getdate_fn() }} as MetaCreatedAt
FROM Transitions
