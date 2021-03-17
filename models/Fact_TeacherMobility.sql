
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
    ,CAST(d.Distance AS {{ t_float() }}) AS Distance
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
LEFT JOIN {{ source('ext', 'Ext_TeacherMobility_Distance') }} d
    ON tm.TeacherMobilityID = d.TeacherMobilityID
