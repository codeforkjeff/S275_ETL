
{{
    config({
        "pre-hook": [
            "DROP INDEX IF EXISTS idx_stg_teachercounts"
        ]
        ,"post-hook": [
            """
            CREATE UNIQUE INDEX idx_stg_teachercounts ON stg_teachercounts
			(AcademicYear, CountyAndDistrictCode, Building)
            """
        ]
    })
}}

SELECT
	st.AcademicYear,
	staff.CountyAndDistrictCode,
	st.Building,
	SUM(CASE WHEN staff.PersonOfColorCategory = 'Person of Color' THEN 1 ELSE 0 END) AS TeachersOfColor,
	COUNT(*) AS TotalTeachers
FROM {{ ref('fact_schoolteacher') }} st
JOIN {{ ref('dim_staff') }} staff
	ON st.StaffID = staff.StaffID
JOIN {{ ref('dim_school_backfilled') }} sch
	ON st.AcademicYear = sch.AcademicYear
	AND staff.CountyAndDistrictCode = sch.DistrictCode
	and st.Building = sch.SchoolCode
WHERE PrimaryFlag = 1
GROUP BY
	st.AcademicYear,
	staff.CountyAndDistrictCode,
	st.Building
ORDER BY
	st.AcademicYear,
	staff.CountyAndDistrictCode,
	st.Building
