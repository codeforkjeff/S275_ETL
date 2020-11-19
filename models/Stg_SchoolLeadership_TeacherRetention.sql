
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['CohortYear', 'CohortCountyAndDistrictCode', 'CohortBuilding'], unique=True) }}"
        ]
    })
}}

WITH t AS (

	select
		CohortYear
		,EndYear - CohortYear as Period
		,CohortCountyAndDistrictCode
		,CohortBuilding
		,'All' AS SubGroup
		,Sum(StayedInSchool) as Stayed
	from {{ ref('Fact_TeacherCohortMobility') }} tcm
	JOIN {{ ref('Dim_Staff') }} s
		ON tcm.CohortStaffID = s.StaffID
	where
		EndYear - CohortYear <= 4
	GROUP BY
		CohortYear, EndYear, CohortCountyAndDistrictCode, CohortBuilding

	UNION ALL

	select
		CohortYear
		,EndYear - CohortYear as Period
		,CohortCountyAndDistrictCode
		,CohortBuilding
		,'Person of Color' AS SubGroup
		,Sum(StayedInSchool) as Stayed
	from {{ ref('Fact_TeacherCohortMobility') }} tcm
	JOIN {{ ref('Dim_Staff') }} s
		ON tcm.CohortStaffID = s.StaffID
	where
		EndYear - CohortYear <= 4
		AND PersonOfColorCategory = 'Person of Color'
	GROUP BY
		CohortYear, EndYear, CohortCountyAndDistrictCode, CohortBuilding

)
,Wide AS (
	-- distribute fields across
	select
		CohortYear
		,CohortCountyAndDistrictCode
		,CohortBuilding
		,CASE WHEN SubGroup = 'All' And Period = 1 THEN Stayed END AS TeacherRetention1Yr
		,CASE WHEN SubGroup = 'All' And Period = 2 THEN Stayed END AS TeacherRetention2Yr
		,CASE WHEN SubGroup = 'All' And Period = 3 THEN Stayed END AS TeacherRetention3Yr
		,CASE WHEN SubGroup = 'All' And Period = 4 THEN Stayed END AS TeacherRetention4Yr
		,CASE WHEN SubGroup = 'Person of Color' And Period = 1 THEN Stayed END AS TeacherOfColorRetention1Yr
		,CASE WHEN SubGroup = 'Person of Color' And Period = 2 THEN Stayed END AS TeacherOfColorRetention2Yr
		,CASE WHEN SubGroup = 'Person of Color' And Period = 3 THEN Stayed END AS TeacherOfColorRetention3Yr
		,CASE WHEN SubGroup = 'Person of Color' And Period = 4 THEN Stayed END AS TeacherOfColorRetention4Yr
	from t
)
SELECT
	CohortYear
	,CohortCountyAndDistrictCode
	,CohortBuilding
	,MAX(TeacherRetention1Yr) AS TeacherRetention1Yr
	,MAX(TeacherRetention2Yr) AS TeacherRetention2Yr
	,MAX(TeacherRetention3Yr) AS TeacherRetention3Yr
	,MAX(TeacherRetention4Yr) AS TeacherRetention4Yr
	,MAX(TeacherOfColorRetention1Yr) AS TeacherOfColorRetention1Yr
	,MAX(TeacherOfColorRetention2Yr) AS TeacherOfColorRetention2Yr
	,MAX(TeacherOfColorRetention3Yr) AS TeacherOfColorRetention3Yr
	,MAX(TeacherOfColorRetention4Yr) AS TeacherOfColorRetention4Yr
FROM Wide
GROUP BY
	CohortYear
	,CohortCountyAndDistrictCode
	,CohortBuilding
