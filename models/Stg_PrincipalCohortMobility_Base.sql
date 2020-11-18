
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['CohortYear', 'EndYear', 'CertificateNumber']) }}"
        ]
    })
}}

SELECT
        pc.CohortYear
        ,pc.CohortStaffID
		,pc.CertificateNumber
        ,pc.CohortCountyAndDistrictCode
		,pc.CohortBuilding
		,pc.CohortPrincipalType
        ,h.StaffID AS EndStaffID
		,h.AcademicYear AS EndYear
        ,h.CountyAndDistrictCode AS EndHighestFTECountyAndDistrictCode
        ,h.Building AS EndHighestFTEBuilding
        ,endpc.CohortPrincipalType as EndPrincipalType
        ,CASE WHEN pc.CohortBuilding = h.Building THEN 1 ELSE 0 END AS StayedInSchool
        ,CASE WHEN pc.CohortBuilding <> h.Building AND pc.CohortCountyAndDistrictCode = h.CountyAndDistrictCode  AND pc.CohortPrincipalType = endpc.CohortPrincipalType THEN 1 ELSE 0 END AS ChangedBuildingStayedDistrict
        ,CASE WHEN pc.CohortBuilding <> h.Building AND pc.CohortCountyAndDistrictCode = h.CountyAndDistrictCode  AND pc.CohortPrincipalType <> COALESCE(endpc.CohortPrincipalType, '') THEN 1 ELSE 0 END AS ChangedRoleStayedDistrict
        ,CASE WHEN pc.CohortCountyAndDistrictCode <> h.CountyAndDistrictCode  THEN 1 ELSE 0 END AS MovedOutDistrict
        ,0 AS Exited
        ,{{ getdate_fn() }} as MetaCreatedAt
FROM {{ ref('Fact_PrincipalCohort') }} pc
-- join to a wide set of staff/yr/highest duty root
JOIN {{ ref('Stg_Staff_By_Highest_FTE') }} h
	ON pc.CertificateNumber = h.CertificateNumber
LEFT JOIN {{ ref('Fact_PrincipalCohort') }} endpc
    ON pc.CertificateNumber = endpc.CertificateNumber
    AND h.AcademicYear = endpc.CohortYear
WHERE
	h.AcademicYear > pc.CohortYear
