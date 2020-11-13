
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['CohortYear', 'Period', 'CohortCountyAndDistrictCode', 'CohortBuilding', 'SubGroup'], unique=True) }}"
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
	from {{ ref('fact_teachercohortmobility') }} tcm
	JOIN {{ ref('dim_staff') }} s
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
	from {{ ref('fact_teachercohortmobility') }} tcm
	JOIN {{ ref('dim_staff') }} s
		ON tcm.CohortStaffID = s.StaffID
	where
		EndYear - CohortYear <= 4
		AND PersonOfColorCategory = 'Person of Color'
	GROUP BY
		CohortYear, EndYear, CohortCountyAndDistrictCode, CohortBuilding

)
select
	CohortYear
	,Period
	,CohortCountyAndDistrictCode
	,CohortBuilding
	,SubGroup
	,Stayed
from t
