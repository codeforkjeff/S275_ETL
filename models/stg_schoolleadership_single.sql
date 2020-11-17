
-- base table for School Leadership that does selection of a single Principal and Asst Prin
-- for each school/AY

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

WITH Primaries AS (
    -- a school can have more than 1 Principal or AP. pick one for each role
    SELECT
        sp.*
    FROM {{ ref('Fact_SchoolPrincipal') }} sp
    WHERE
        PrimaryForSchoolFlag = 1
)
,Leadership AS (
    -- this union and group by captures yrs where a school has an Asst Prin but not a Principal.
    SELECT
        AcademicYear
        ,CountyAndDistrictCode
        ,Building
        ,MAX(PrincipalStaffID) AS PrincipalStaffID
        ,MAX(AsstPrincipalStaffID) AS AsstPrincipalStaffID
    FROM (
        SELECT
            p.AcademicYear
            ,p.CountyAndDistrictCode
            ,p.Building
            ,p.StaffID AS PrincipalStaffID
            ,NULL AS AsstPrincipalStaffID
        FROM Primaries p
        WHERE p.PrincipalType = 'Principal'

        UNION ALL

        SELECT
            ap.AcademicYear
            ,ap.CountyAndDistrictCode
            ,ap.Building
            ,NULL AS PrincipalStaffID
            ,ap.StaffID AS AsstPrincipalStaffID
        FROM Primaries ap
        WHERE ap.PrincipalType = 'AssistantPrincipal'
    ) T
    GROUP BY
        AcademicYear
        ,CountyAndDistrictCode
        ,Building
)
,LeadershipWithPrevious AS (
    select
        curr.AcademicYear
        ,curr.CountyAndDistrictCode
        ,curr.Building
        ,curr.PrincipalStaffID
        ,prev.PrincipalStaffID AS PrevPrincipalStaffID
        ,curr.AsstPrincipalStaffID
        ,prev.AsstPrincipalStaffID AS PrevAsstPrincipalStaffID
    from leadership curr
    left join leadership prev
        ON curr.AcademicYear = prev.AcademicYear + 1
        AND curr.CountyAndDistrictCode = prev.CountyAndDistrictCode
        and curr.Building = prev.Building
),
Base AS (
    select
        le.AcademicYear
        ,le.CountyAndDistrictCode
        ,le.Building
        ,s_prin.CertificateNumber AS PrincipalCertificateNumber
        ,le.PrincipalStaffID
        ,le.PrevPrincipalStaffID
        ,s_asstprin.CertificateNumber AS AsstPrincipalCertificateNumber
        ,le.AsstPrincipalStaffID
        ,le.PrevAsstPrincipalStaffID
        ,CASE
            WHEN s_prinprev.CertificateNumber IS NOT NULL
            THEN
                CASE WHEN s_prin.CertificateNumber = s_prinprev.CertificateNumber THEN 1 ELSE 0 END
            ELSE
                NULL
        END AS SamePrincipalFlag
        ,CASE
            WHEN s_asstprinprev.CertificateNumber IS NOT NULL
            THEN
                CASE WHEN s_asstprin.CertificateNumber = s_asstprinprev.CertificateNumber THEN 1 ELSE 0 END
            ELSE
                NULL
        END AS SameAsstPrincipalFlag
        ,CASE WHEN s_prin.CertificateNumber = s_asstprinprev.CertificateNumber THEN 1 ELSE 0 END AS PromotionFlag
    from LeadershipWithPrevious le
    left join {{ ref('Dim_Staff') }} s_prin
        ON le.PrincipalStaffID = s_prin.StaffID
    left join {{ ref('Dim_Staff') }} s_prinprev
        ON le.PrevPrincipalStaffID = s_prinprev.StaffID
    left join {{ ref('Dim_Staff') }} s_asstprin
        ON le.AsstPrincipalStaffID = s_asstprin.StaffID
    left join {{ ref('Dim_Staff') }} s_asstprinprev
        ON le.PrevAsstPrincipalStaffID = s_asstprinprev.StaffID
)
SELECT
    {% call concat() %}
    CAST(AcademicYear AS VARCHAR(4)) + CAST(CountyAndDistrictCode AS VARCHAR(10)) + CAST(Building AS VARCHAR(10))
    {% endcall %}
    AS SchoolLeadershipID
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
    ,CASE WHEN SamePrincipalFlag = 0 OR SameAsstPrincipalFlag = 0 THEN 1 ELSE 0 END AS LeadershipChangeFlag
    ,PromotionFlag
FROM Base
