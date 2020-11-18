
SELECT
    base.SchoolLeadershipID
    ,base.AcademicYear
    ,base.CountyAndDistrictCode
    ,base.Building
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
    ,AllPrincipalCertList
    ,AllAsstPrinCertList
    ,AnyPrincipalPOC
    ,AnyAsstPrinPOC
    ,BroadLeadershipAnyPOCFlag
    --
    ,BroadLeadershipChangeFlag
    ,BroadLeadershipAnyPOCStayedFlag
    ,BroadLeadershipStayedNoPOCFlag
    ,BroadLeadershipChangeAnyPOCToNoneFlag
    ,BroadLeadershipChangeNoPOCToAnyFlag
    --
    ,BroadLeadershipGainedPrincipalPOCFlag
    ,BroadLeadershipGainedAsstPrinPOCFlag
    ,BroadLeadershipGainedPOCFlag
    ,BroadLeadershipLostPrincipalPOCFlag
    ,BroadLeadershipLostAsstPrinPOCFlag
    ,BroadLeadershipLostPOCFlag
    --
    ,TeacherCount
    ,TeacherRetention1Yr
    ,TeacherRetention1YrPct
    ,TeacherRetention2Yr
    ,TeacherRetention2YrPct
    ,TeacherRetention3Yr
    ,TeacherRetention3YrPct
    ,TeacherRetention4Yr
    ,TeacherRetention4YrPct
    ,TeacherOfColorCount
    ,TeacherOfColorRetention1Yr
    ,TeacherOfColorRetention1YrPct
    ,TeacherOfColorRetention2Yr
    ,TeacherOfColorRetention2YrPct
    ,TeacherOfColorRetention3Yr
    ,TeacherOfColorRetention3YrPct
    ,TeacherOfColorRetention4Yr
    ,TeacherOfColorRetention4YrPct
    ,{{ getdate_fn() }} AS MetaCreatedAt
FROM {{ ref('stg_schoolleadership') }} base
LEFT JOIN {{ source('ext', 'ext_schoolleadership_broad') }} broad
    ON base.AcademicYear = broad.AcademicYear
    AND base.CountyAndDistrictCode = broad.CountyAndDistrictCode
    AND base.Building = broad.Building
