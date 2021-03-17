
SELECT
    CAST(AcademicYear as {{ t_smallint() }}) AS AcademicYear
    ,CountyAndDistrictCode
    ,Building
    ,AllPrincipalCertList
    ,AllAsstPrinCertList
    ,CAST(AnyPrincipalPOC AS {{ t_tinyint() }}) AS AnyPrincipalPOC
    ,CAST(AnyAsstPrinPOC AS {{ t_tinyint() }}) AS AnyAsstPrinPOC
    ,CAST(BroadLeadershipAnyPOCFlag AS {{ t_tinyint() }}) AS BroadLeadershipAnyPOCFlag
    ,CAST(BroadLeadershipChangeFlag AS {{ t_tinyint() }}) AS BroadLeadershipChangeFlag
    ,CAST(BroadLeadershipAnyPOCStayedFlag AS {{ t_tinyint() }}) AS BroadLeadershipAnyPOCStayedFlag
    ,CAST(BroadLeadershipStayedNoPOCFlag AS {{ t_tinyint() }}) AS BroadLeadershipStayedNoPOCFlag
    ,CAST(BroadLeadershipChangeAnyPOCToNoneFlag AS {{ t_tinyint() }}) AS BroadLeadershipChangeAnyPOCToNoneFlag
    ,CAST(BroadLeadershipChangeNoPOCToAnyFlag AS {{ t_tinyint() }}) AS BroadLeadershipChangeNoPOCToAnyFlag
    ,CAST(BroadLeadershipGainedPrincipalPOCFlag AS {{ t_tinyint() }}) AS BroadLeadershipGainedPrincipalPOCFlag
    ,CAST(BroadLeadershipGainedAsstPrinPOCFlag AS {{ t_tinyint() }}) AS BroadLeadershipGainedAsstPrinPOCFlag
    ,CAST(BroadLeadershipGainedPOCFlag AS {{ t_tinyint() }}) AS BroadLeadershipGainedPOCFlag
    ,CAST(BroadLeadershipLostPrincipalPOCFlag AS {{ t_tinyint() }}) AS BroadLeadershipLostPrincipalPOCFlag
    ,CAST(BroadLeadershipLostAsstPrinPOCFlag AS {{ t_tinyint() }}) AS BroadLeadershipLostAsstPrinPOCFlag
    ,CAST(BroadLeadershipLostPOCFlag AS {{ t_tinyint() }}) AS BroadLeadershipLostPOCFlag
FROM {{ source('ext', 'Ext_SchoolLeadership_Broad') }}

