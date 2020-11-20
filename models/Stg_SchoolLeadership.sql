
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['SchoolLeadershipID'], unique=True) }}"
        ]
    })
}}

WITH t AS (
    SELECT
        base.SchoolLeadershipID
        ,base.AcademicYear
        ,base.CountyAndDistrictCode
        ,base.Building
        ,PrincipalCertificateNumber
        ,PrincipalStaffID
        ,PrevPrincipalStaffID
        ,AsstPrincipalCertificateNumber
        ,AsstPrincipalStaffID
        ,PrevAsstPrincipalStaffID
        ,SamePrincipalFlag
        ,SameAsstPrincipalFlag
        ,LeadershipChangeFlag
        ,PromotionFlag
        ,PrincipalTenure
        ,AsstPrincipalTenure
        ,ds.TotalTeachers AS TeacherCount
        ,ds.TeachersOfColor AS TeacherOfColorCount
        ,tr.TeacherRetention1Yr
        ,tr.TeacherRetention2Yr
        ,tr.TeacherRetention3Yr
        ,tr.TeacherRetention4Yr
        ,tr.TeacherOfColorRetention1Yr
        ,tr.TeacherOfColorRetention2Yr
        ,tr.TeacherOfColorRetention3Yr
        ,tr.TeacherOfColorRetention4Yr
    FROM {{ ref('Stg_SchoolLeadership_Single') }} base
    LEFT JOIN {{ ref('Dim_School') }} ds
        ON base.AcademicYear = ds.AcademicYear
        AND base.CountyAndDistrictCode = ds.DistrictCode
        AND base.Building = ds.SchoolCode
    LEFT JOIN {{ ref('Stg_SchoolLeadership_TeacherRetention') }} tr
        ON base.AcademicYear = tr.CohortYear
        AND base.CountyAndDistrictCode = tr.CohortCountyAndDistrictCode
        AND base.Building = tr.CohortBuilding
)
SELECT
    SchoolLeadershipID
    ,AcademicYear
    ,CountyAndDistrictCode
    ,Building
    --
    ,PrincipalCertificateNumber
    ,PrincipalStaffID
    ,PrevPrincipalStaffID
    ,AsstPrincipalCertificateNumber
    ,AsstPrincipalStaffID
    ,PrevAsstPrincipalStaffID
    ,SamePrincipalFlag
    ,SameAsstPrincipalFlag
    ,LeadershipChangeFlag
    ,PromotionFlag
    ,PrincipalTenure
    ,AsstPrincipalTenure
    --
    -- ,AllPrincipalCertList
    -- ,AllAsstPrinCertList
    -- ,AnyPrincipalPOC
    -- ,AnyAsstPrinPOC
    -- ,BroadLeadershipAnyPOCFlag
    -- --
    -- ,BroadLeadershipChangeFlag
    -- ,BroadLeadershipAnyPOCStayedFlag
    -- ,BroadLeadershipStayedNoPOCFlag
    -- ,BroadLeadershipChangeAnyPOCToNoneFlag
    -- ,BroadLeadershipChangeNoPOCToAnyFlag
    -- --
    -- ,BroadLeadershipGainedPrincipalPOCFlag
    -- ,BroadLeadershipGainedAsstPrinPOCFlag
    -- ,BroadLeadershipGainedPOCFlag
    -- ,BroadLeadershipLostPrincipalPOCFlag
    -- ,BroadLeadershipLostAsstPrinPOCFlag
    -- ,BroadLeadershipLostPOCFlag
    --
    ,TeacherCount
    ,TeacherRetention1Yr
    ,CASE WHEN TeacherCount > 0 THEN CAST(TeacherRetention1Yr AS REAL) / TeacherCount END AS TeacherRetention1YrPct
    ,TeacherRetention2Yr
    ,CASE WHEN TeacherCount > 0 THEN CAST(TeacherRetention2Yr AS REAL) / TeacherCount END AS TeacherRetention2YrPct
    ,TeacherRetention3Yr
    ,CASE WHEN TeacherCount > 0 THEN CAST(TeacherRetention3Yr AS REAL) / TeacherCount END AS TeacherRetention3YrPct
    ,TeacherRetention4Yr
    ,CASE WHEN TeacherCount > 0 THEN CAST(TeacherRetention4Yr AS REAL) / TeacherCount END AS TeacherRetention4YrPct
    ,TeacherOfColorCount
    ,TeacherOfColorRetention1Yr
    ,CASE WHEN TeacherOfColorCount > 0 THEN CAST(TeacherOfColorRetention1Yr AS REAL) / TeacherOfColorCount END AS TeacherOfColorRetention1YrPct
    ,TeacherOfColorRetention2Yr
    ,CASE WHEN TeacherOfColorCount > 0 THEN CAST(TeacherOfColorRetention2Yr AS REAL) / TeacherOfColorCount END AS TeacherOfColorRetention2YrPct
    ,TeacherOfColorRetention3Yr
    ,CASE WHEN TeacherOfColorCount > 0 THEN CAST(TeacherOfColorRetention3Yr AS REAL) / TeacherOfColorCount END AS TeacherOfColorRetention3YrPct
    ,TeacherOfColorRetention4Yr
    ,CASE WHEN TeacherOfColorCount > 0 THEN CAST(TeacherOfColorRetention4Yr AS REAL) / TeacherOfColorCount END AS TeacherOfColorRetention4YrPct
    ,{{ getdate_fn() }} AS MetaCreatedAt
FROM t
