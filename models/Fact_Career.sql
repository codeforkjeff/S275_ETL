
/*

fields to add:

- First role: how to select if there are multiple roles?
- Last Role: how to select if there are multiple roles?
- in district: how to select if employed in multiple districts?
- in school: how to select if employed in multiple schools?
- number of transitions
- org culture: how to capture/quantify this?
- how long have they been in current role (teacher, principal) - roles where they began, when they ended up
- "promotions": from teacher to admin?

*/

WITH
Stage AS (
	SELECT
		CertificateNumber
		,MIN(AcademicYear) AS FirstYear
		,MAX(AcademicYear) AS MostRecentYear
		,COUNT(DISTINCT AcademicYear) AS TotalActiveYearsWA
		,COUNT(DISTINCT District) AS NumDistrictsWorked
		,MIN(CASE WHEN IsTeacherFlag = 1 then AcademicYear END) AS TeacherFirstYear
		,MAX(CASE WHEN IsTeacherFlag = 1 then AcademicYear END) AS TeacherLastYear
		,COUNT(DISTINCT CASE WHEN IsTeacherFlag = 1 then AcademicYear END) AS TeacherNumYears
		,MIN(CASE WHEN IsAsstPrincipalFlag = 1 OR IsPrincipalFlag = 1 then AcademicYear END) AS APOrPrincipalFirstYear
		,MAX(CASE WHEN IsAsstPrincipalFlag = 1 OR IsPrincipalFlag = 1 then AcademicYear END) AS APOrPrincipalLastYear
		,COUNT(DISTINCT CASE WHEN IsAsstPrincipalFlag = 1 OR IsPrincipalFlag = 1 then AcademicYear END) AS APOrPrincipalNumYears
	FROM {{ ref('Dim_Staff') }}
	GROUP BY CertificateNumber
)
,FromAssignments AS (
	SELECT
		s.CertificateNumber
		,COUNT(DISTINCT Building) AS NumSchools
		,COUNT(DISTINCT DutyRoot) AS NumDistinctDutyRoots
	FROM {{ ref('Fact_Assignment') }} a
	JOIN {{ ref('Dim_Staff') }} s
		ON a.StaffID = s.StaffID
	GROUP BY
		s.CertificateNumber
)
,Characteristics AS (
	SELECT *
	FROM (
		SELECT
			s.CertificateNumber
			,s.RaceEthOSPI
			,s.Sex
			,ROW_NUMBER() OVER (PARTITION BY
				s.CertificateNumber
			ORDER BY
				s.AcademicYear DESC,
				-- if they worked in multiple districts, pick one
				s.District
			) AS Ranked
		FROM {{ ref('Dim_Staff') }} s
	) t
	WHERE Ranked = 1
)
select
	base.CertificateNumber
	,c.RaceEthOSPI
	,c.Sex
	,base.FirstYear
	,base.MostRecentYear
	,base.TotalActiveYearsWA
	,base.NumDistrictsWorked
	,a.NumSchools
	,a.NumDistinctDutyRoots
	,d.DutyList
	--
	,base.TeacherFirstYear
	,base.TeacherLastYear
	,base.TeacherNumYears
	,base.APOrPrincipalFirstYear
	,base.APOrPrincipalLastYear
	,base.APOrPrincipalNumYears
	,CASE WHEN APOrPrincipalFirstYear >= TeacherLastYear THEN 1 ELSE 0 END AS TeacherToAPOrPrincipal
FROM Stage base
LEFT Join FromAssignments a
	ON base.CertificateNumber = a.CertificateNumber
LEFT Join Characteristics c
	ON base.CertificateNumber = c.CertificateNumber
LEFT JOIN {{ source('ext', 'Ext_DutyList') }} d
	ON base.CertificateNumber = d.CertificateNumber
