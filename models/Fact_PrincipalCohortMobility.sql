
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
    CohortYear
    ,CohortStaffID
    ,CertificateNumber
    ,CohortCountyAndDistrictCode
    ,CohortBuilding
    ,CohortPrincipalType
    ,EndStaffID
    ,EndYear
    ,EndHighestFTECountyAndDistrictCode
    ,EndHighestFTEBuilding
    ,EndPrincipalType
    ,StayedInSchool
    ,ChangedBuildingStayedDistrict
    ,ChangedRoleStayedDistrict
    ,MovedOutDistrict
    ,Exited
    ,{{ getdate_fn() }} as MetaCreatedAt
FROM {{ ref('Stg_PrincipalCohortMobility_Base') }}

UNION ALL

-- ensure full representation of every CohortYear + EndYear combo for each principal:
-- creating rows for missing EndYears (people who no longer appear in S275 and are thus considered exited)

SELECT
    pc.CohortYear
    ,pc.CohortStaffID
    ,pc.CertificateNumber
    ,pc.CohortCountyAndDistrictCode
    ,pc.CohortBuilding
    ,pc.CohortPrincipalType
    ,NULL as EndStaffID
    ,y.AcademicYear as EndYear
    ,NULL AS EndHighestFTECountyAndDistrictCode
    ,NULL AS EndHighestFTEBuilding
    ,NULL AS EndPrincipalType
    ,0 AS StayedInSchool
    ,0 AS ChangedBuildingStayedDistrict
    ,0 AS ChangedRoleStayedDistrict
    ,0 AS MovedOutDistrict
    ,1 AS Exited
    ,{{ getdate_fn() }} as MetaCreatedAt
FROM {{ ref('Fact_PrincipalCohort') }} pc
CROSS JOIN
(
	SELECT DISTINCT
		AcademicYear
	FROM {{ ref('Dim_Staff') }}
) AS y
WHERE
	y.AcademicYear > pc.CohortYear
	AND NOT EXISTS (
		SELECT 1
		FROM {{ ref('Stg_PrincipalCohortMobility_Base') }} exists_
		WHERE
			exists_.CohortYear = pc.CohortYear
			AND exists_.EndYear = y.AcademicYear
			AND exists_.CertificateNumber = pc.CertificateNumber
	)

-- validation: this should return 0 rows
-- select top 1000 * 
-- from Fact_TeacherCohortMobility
-- where
-- 	StayedInSchool = 0
-- 	and ChangedBuildingStayedDistrict = 0
-- 	and ChangedRoleStayedDistrict = 0
-- 	and MovedOutDistrict = 0
-- 	and Exited = 0 
