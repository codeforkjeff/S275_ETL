WITH t AS (
    SELECT
        base.SchoolLeadershipID
        ,AcademicYear
        ,CountyAndDistrictCode
        ,Building
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
        ,ten.PrincipalTenure
        ,ten.AsstPrincipalTenure
        ,(
            SELECT TotalTeachers
            FROM {{ ref('dim_school') }} ds
            WHERE
                base.AcademicYear = ds.AcademicYear
                AND base.CountyAndDistrictCode = ds.DistrictCode
                AND base.Building = ds.SchoolCode
        ) AS TeacherCount
        ,(
            SELECT TeachersOfColor
            FROM {{ ref('dim_school') }} ds
            WHERE
                base.AcademicYear = ds.AcademicYear
                AND base.CountyAndDistrictCode = ds.DistrictCode
                AND base.Building = ds.SchoolCode
        ) AS TeacherOfColorCount
        ,(
            SELECT Stayed
            FROM {{ ref('stg_schoolleadership_teacherretention') }} tr
            WHERE
                Period = 1
                AND Subgroup = 'All'
                AND base.AcademicYear = tr.CohortYear
                AND base.CountyAndDistrictCode = tr.CohortCountyAndDistrictCode
                AND base.Building = tr.CohortBuilding
        ) AS TeacherRetention1Yr
        ,(
            SELECT Stayed
            FROM {{ ref('stg_schoolleadership_teacherretention') }} tr
            WHERE
                Period = 2
                AND Subgroup = 'All'
                AND base.AcademicYear = tr.CohortYear
                AND base.CountyAndDistrictCode = tr.CohortCountyAndDistrictCode
                AND base.Building = tr.CohortBuilding
        ) AS TeacherRetention2Yr
        ,(
            SELECT Stayed
            FROM {{ ref('stg_schoolleadership_teacherretention') }} tr
            WHERE
                Period = 3
                AND Subgroup = 'All'
                AND base.AcademicYear = tr.CohortYear
                AND base.CountyAndDistrictCode = tr.CohortCountyAndDistrictCode
                AND base.Building = tr.CohortBuilding
        ) AS TeacherRetention3Yr
        ,(
            SELECT Stayed
            FROM {{ ref('stg_schoolleadership_teacherretention') }} tr
            WHERE
                Period = 4
                AND Subgroup = 'All'
                AND base.AcademicYear = tr.CohortYear
                AND base.CountyAndDistrictCode = tr.CohortCountyAndDistrictCode
                AND base.Building = tr.CohortBuilding
        ) AS TeacherRetention4Yr
        ,(
            SELECT Stayed
            FROM {{ ref('stg_schoolleadership_teacherretention') }} tr
            WHERE
                Period = 1
                AND Subgroup = 'Person of Color'
                AND base.AcademicYear = tr.CohortYear
                AND base.CountyAndDistrictCode = tr.CohortCountyAndDistrictCode
                AND base.Building = tr.CohortBuilding
        ) AS TeacherOfColorRetention1Yr
        ,(
            SELECT Stayed
            FROM {{ ref('stg_schoolleadership_teacherretention') }} tr
            WHERE
                Period = 2
                AND Subgroup = 'Person of Color'
                AND base.AcademicYear = tr.CohortYear
                AND base.CountyAndDistrictCode = tr.CohortCountyAndDistrictCode
                AND base.Building = tr.CohortBuilding
        ) AS TeacherOfColorRetention2Yr
        ,(
            SELECT Stayed
            FROM {{ ref('stg_schoolleadership_teacherretention') }} tr
            WHERE
                Period = 3
                AND Subgroup = 'Person of Color'
                AND base.AcademicYear = tr.CohortYear
                AND base.CountyAndDistrictCode = tr.CohortCountyAndDistrictCode
                AND base.Building = tr.CohortBuilding
        ) AS TeacherOfColorRetention3Yr
        ,(
            SELECT Stayed
            FROM {{ ref('stg_schoolleadership_teacherretention') }} tr
            WHERE
                Period = 4
                AND Subgroup = 'Person of Color'
                AND base.AcademicYear = tr.CohortYear
                AND base.CountyAndDistrictCode = tr.CohortCountyAndDistrictCode
                AND base.Building = tr.CohortBuilding
        ) AS TeacherOfColorRetention4Yr
    FROM {{ ref('stg_schoolleadership') }} base
    LEFT JOIN {{ ref('stg_schoolleadership_tenure') }} ten
        ON base.SchoolLeadershipID = ten.SchoolLeadershipID
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
