
{{
    config({
        "pre-hook": [
            "DROP INDEX IF EXISTS idx_stg_principalsofcolor"
        ]
        ,"post-hook": [
            """
            CREATE UNIQUE INDEX idx_stg_principalsofcolor ON stg_principalsofcolor (
				AcademicYear,
				CountyAndDistrictCode,
				Building
            )
            """
        ]
    })
}}

SELECT
	p.AcademicYear,
	st.CountyAndDistrictCode,
	p.Building,
	MAX(CASE WHEN p.PrincipalType = 'Principal' THEN 1 ELSE 0 END) AS PrincipalOfColorFlag,
	MAX(CASE WHEN p.PrincipalType = 'AssistantPrincipal' THEN 1 ELSE 0 END) AS AsstPrincipalOfColorFlag
FROM {{ ref('fact_schoolprincipal') }} p
JOIN {{ ref('dim_staff') }} st
	ON p.StaffID = st.StaffID
WHERE
	st.PersonOfColorCategory = 'Person of Color'
	AND p.PrimaryFlag = 1
GROUP BY
	p.AcademicYear,
	st.CountyAndDistrictCode,
	p.Building
