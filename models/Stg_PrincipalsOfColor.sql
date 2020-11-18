
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['AcademicYear', 'CountyAndDistrictCode', 'Building'], unique=True) }}"
        ]
    })
}}

SELECT
	p.AcademicYear,
	st.CountyAndDistrictCode,
	p.Building,
	MAX(CASE WHEN p.PrincipalType = 'Principal' THEN 1 ELSE 0 END) AS PrincipalOfColorFlag,
	MAX(CASE WHEN p.PrincipalType = 'AssistantPrincipal' THEN 1 ELSE 0 END) AS AsstPrincipalOfColorFlag
FROM {{ ref('Fact_SchoolPrincipal') }} p
JOIN {{ ref('Dim_Staff') }} st
	ON p.StaffID = st.StaffID
WHERE
	st.PersonOfColorCategory = 'Person of Color'
	AND p.PrimaryFlag = 1
GROUP BY
	p.AcademicYear,
	st.CountyAndDistrictCode,
	p.Building
