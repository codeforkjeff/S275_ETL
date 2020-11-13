
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['CohortYear', 'EndYear', 'CertificateNumber'], unique=True) }}"
        ]
    })
}}

SELECT
        tc.CohortYear
        ,tc.CohortStaffID
		,tc.CertificateNumber
        ,tc.CohortCountyAndDistrictCode
		,tc.CohortBuilding
        ,a.StaffID AS EndStaffID
		,a.AcademicYear AS EndYear
        ,a.CountyAndDistrictCode AS EndCountyAndDistrictCode
        ,a.Building AS EndBuilding
        ,CASE WHEN CohortBuilding = a.Building THEN 1 ELSE 0 END AS StayedInSchool
        -- people who stayed in district (may or may not be same building) and stayed teachers
        --,StayedInDistrict = CASE WHEN CohortCountyAndDistrictCode = EndCountyAndDistrictCode AND a.EndTeacherFlag = 1 THEN 1 ELSE 0 END -- may be in the same building
        ,CASE WHEN CohortBuilding <> a.Building AND CohortCountyAndDistrictCode = a.CountyAndDistrictCode AND a.TeacherFlag = 1 THEN 1 ELSE 0 END AS ChangedBuildingStayedDistrict -- definitely not in the same building  
        ,CASE WHEN CohortBuilding <> a.Building AND CohortCountyAndDistrictCode = a.CountyAndDistrictCode AND a.TeacherFlag = 0 THEN 1 ELSE 0 END AS ChangedRoleStayedDistrict -- definitely not in the same building
        ,CASE WHEN CohortCountyAndDistrictCode <> a.CountyAndDistrictCode THEN 1 ELSE 0 END AS MovedOutDistrict
        ,0 AS Exited 
        ,{{ getdate_fn() }} as MetaCreatedAt
FROM {{ ref('fact_teachercohort') }} tc
JOIN {{ ref('stg_staff_by_building') }} a
	ON tc.CertificateNumber = a.CertificateNumber
WHERE
	a.AcademicYear > tc.CohortYear
