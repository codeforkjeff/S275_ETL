
-- Fact_TeacherMobility was designed to reproduce COE's numbers,
-- so it follows their logic very closely. It should probably be kept that way
-- for reference. See Fact_TeacherCohortMobility for a table that's more tailored
-- to analysis by CCER.

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
PrincipalsLookup AS (
    SELECT DISTINCT
        PrincipalType
        ,StaffID
    FROM {{ ref('Fact_SchoolPrincipal') }}
)
,YearBrackets AS (
    SELECT DISTINCT
        AcademicYear AS StartYear,
        AcademicYear + 1 AS EndYear
    FROM {{ ref('stg_base_schoolteachers') }} y1
    WHERE EXISTS (
        SELECT 1 FROM {{ ref('stg_base_schoolteachers') }} WHERE AcademicYear = y1.AcademicYear + 1
    )
    UNION ALL
    SELECT DISTINCT
        AcademicYear AS StartYear,
        AcademicYear + 4 AS EndYear
    FROM {{ ref('stg_base_schoolteachers') }} y2
    WHERE EXISTS (
        SELECT 1 FROM {{ ref('stg_base_schoolteachers') }} WHERE AcademicYear = y2.AcademicYear + 4
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
        -- end fields
        t2.CountyAndDistrictCode AS EndCountyAndDistrictCode,
        t2.Building AS EndBuilding,
        t2.TeacherFlag AS EndTeacherFlag
    FROM {{ ref('stg_base_schoolteachers') }} t1
    JOIN YearBrackets y
        ON t1.AcademicYear = y.StartYear
    LEFT JOIN {{ ref('stg_staff_by_building') }} t2
        ON t1.CertificateNumber = t2.CertificateNumber
        AND y.EndYear = t2.AcademicYear
)
,TransitionsWithMovedInBase AS (
    SELECT
        *
        ,CASE WHEN
            EndCountyAndDistrictCode IS NOT NULL
            AND EndBuilding IS NOT NULL
            AND StartCountyAndDistrictCode = EndCountyAndDistrictCode
        THEN 1 ELSE 0 END AS StayedInDistrict
    FROM TransitionsBase
)
,Transitions AS (
    SELECT
        t.*
        ,s1.NCESLocale AS StartLocale
        ,s2.NCESLocale AS EndLocale
        ,CASE WHEN EndTeacherFlag = 0 THEN 1 ELSE 0 END AS RoleChanged
        -- MovedInBuildingChange and MovedInRoleChange are components of MovedIn
        ,CASE WHEN
            StayedInDistrict = 1
            -- there are a handful of 'ELE' building codes, so coalesce to string, not int
            AND COALESCE(StartBuilding, 'NONE') <> COALESCE(EndBuilding, 'NONE')
        THEN 1 ELSE 0 END AS MovedInBuildingChange
        ,CASE WHEN
            StayedInDistrict = 1
            AND EndTeacherFlag = 0
        THEN 1 ELSE 0 END AS MovedInRoleChange
    FROM TransitionsWithMovedInBase t
    LEFT JOIN {{ ref('Dim_School') }} s1
        ON t.StartCountyAndDistrictCode = s1.DistrictCode
        AND t.StartBuilding = s1.SchoolCode
        AND t.StartYear = s1.AcademicYear
    LEFT JOIN {{ ref('Dim_School') }} s2
        ON t.EndCountyAndDistrictCode = s2.DistrictCode
        AND t.EndBuilding = s2.SchoolCode
        AND t.EndYear = s2.AcademicYear
)
,TransitionsFinal AS (
    SELECT
        StartStaffID
        ,EndStaffID
        ,StartYear
        ,EndYear
        ,DiffYears
        ,CertificateNumber
        ,StartCountyAndDistrictCode
        ,StartBuilding
        ,StartLocale
        ,EndCountyAndDistrictCode
        ,EndBuilding
        ,EndLocale
        ,EndTeacherFlag
        ,RoleChanged
        ,CASE WHEN
            EndCountyAndDistrictCode IS NOT NULL
            AND StartCountyAndDistrictCode = EndCountyAndDistrictCode
            AND StartBuilding = EndBuilding
            AND EndTeacherFlag = 1
        THEN 1 ELSE 0 END AS Stayer
        ,MovedInBuildingChange
        ,MovedInRoleChange
        ,CASE WHEN
            MovedInBuildingChange = 1 OR MovedInRoleChange = 1
        THEN 1 ELSE 0 END AS MovedIn
        ,CASE WHEN
            EndCountyAndDistrictCode IS NOT NULL
            AND EndBuilding IS NOT NULL
            AND COALESCE(StartCountyAndDistrictCode, -1) <> COALESCE(EndCountyAndDistrictCode, -1)
        THEN 1 ELSE 0 END AS MovedOut
        ,0 AS MovedOutOfRMR
        ,CASE WHEN
            EndBuilding IS NULL
        THEN 1 ELSE 0 END AS Exited
    FROM Transitions
)
SELECT
    -- since StaffID can be none if they exited, we include EndYear in composite key to ensure uniqueness
    {% call hash() %}
    {% call concat() %}
    CAST(StartStaffID AS VARCHAR(500)) + CAST(COALESCE(EndStaffID, 'NONE') AS VARCHAR(500)) + CAST(EndYear as VARCHAR(4))
    {% endcall %}
    {% endcall %}
    AS TeacherMobilityID
    ,StartStaffID
    ,EndStaffID
    ,StartYear
    ,EndYear
    ,DiffYears
    ,CertificateNumber
    ,StartCountyAndDistrictCode
    ,StartBuilding
    ,StartLocale
    ,EndCountyAndDistrictCode
    ,EndBuilding
    ,EndLocale
    ,EndTeacherFlag
    ,RoleChanged
    ,CASE
        WHEN EXISTS (
            SELECT 1
            FROM PrincipalsLookup p
            WHERE
                p.PrincipalType = 'Principal'
                AND p.StaffID = TransitionsFinal.EndStaffID
        )
        THEN 1
        ELSE 0
    END AS RoleChangedToPrincipal
    ,CASE
        WHEN EXISTS (
            SELECT 1
            FROM PrincipalsLookup p
            WHERE
                p.PrincipalType = 'AssistantPrincipal'
                AND p.StaffID = TransitionsFinal.EndStaffID
        )
        THEN 1
        ELSE 0
    END AS RoleChangedToAsstPrincipal
    ,Stayer
    ,MovedInBuildingChange
    ,MovedInRoleChange
    ,MovedIn
    ,MovedOut
    ,CASE
        WHEN MovedOut = 1
            AND EXISTS (
                SELECT 1
                FROM {{ ref('Dim_School') }}
                WHERE
                    TransitionsFinal.StartYear = AcademicYear
                    AND TransitionsFinal.StartCountyAndDistrictCode = DistrictCode
                    AND TransitionsFinal.StartBuilding = SchoolCode
                AND RMRFlag = 1
                )
            AND NOT EXISTS (
                SELECT 1
                FROM {{ ref('Dim_School') }}
                WHERE
                    TransitionsFinal.EndYear = AcademicYear
                    AND TransitionsFinal.EndCountyAndDistrictCode = DistrictCode
                    AND TransitionsFinal.EndBuilding = SchoolCode
                AND RMRFlag = 1
                )
        THEN 1
        ELSE 0
    END AS MovedOutOfRMR
    ,Exited
    ,{{ getdate_fn() }} as MetaCreatedAt
FROM TransitionsFinal
