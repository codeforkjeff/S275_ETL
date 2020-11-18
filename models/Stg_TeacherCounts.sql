
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
	st.AcademicYear,
	staff.CountyAndDistrictCode,
	st.Building,
	SUM(CASE WHEN staff.PersonOfColorCategory = 'Person of Color' THEN 1 ELSE 0 END) AS TeachersOfColor,
	COUNT(*) AS TotalTeachers
FROM {{ ref('Fact_SchoolTeacher') }} st
JOIN {{ ref('Dim_Staff') }} staff
	ON st.StaffID = staff.StaffID
JOIN {{ ref('Stg_School_Backfilled') }} sch
	ON st.AcademicYear = sch.AcademicYear
	AND staff.CountyAndDistrictCode = sch.DistrictCode
	and st.Building = sch.SchoolCode
WHERE PrimaryFlag = 1
GROUP BY
	st.AcademicYear,
	staff.CountyAndDistrictCode,
	st.Building
