
SELECT
    tm.TeacherMobilityID
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
    ,d.Distance
    ,RoleChanged
    ,RoleChangedToPrincipal
    ,RoleChangedToAsstPrincipal
    ,Stayer
    ,MovedInBuildingChange
    ,MovedInRoleChange
    ,MovedIn
    ,MovedOut
    ,MovedOutOfRMR
    ,Exited
    ,{{ getdate_fn() }} as MetaCreatedAt
FROM {{ ref('Stg_TeacherMobility') }} tm
LEFT JOIN {{ source('ext', 'ext_teachermobility_distance') }} d
    ON tm.TeacherMobilityID = d.TeacherMobilityID
