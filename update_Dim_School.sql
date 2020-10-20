
DROP TABLE IF EXISTS TeacherCounts;

-- next

CREATE TABLE TeacherCounts (
	AcademicYear SMALLINT NOT NULL,
	CountyAndDistrictCode varchar(500) NOT NULL,
    Building varchar(500) NOT NULL,
	TeachersOfColor INT NULL,
	TotalTeachers INT NULL,
	PRIMARY KEY (AcademicYear, Building)
);

-- next

INSERT INTO TeacherCounts
SELECT
	st.AcademicYear,
	staff.CountyAndDistrictCode,
	st.Building,
	SUM(CASE WHEN staff.PersonOfColorCategory = 'Person of Color' THEN 1 ELSE 0 END) AS TeacherOfColors,
	COUNT(*) AS TotalTeachers
FROM Fact_SchoolTeacher st
JOIN Dim_Staff staff
	ON st.StaffID = staff.StaffID
JOIN Dim_School sch
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
;

-- next

ALTER TABLE Dim_School ADD TeachersOfColor INT NULL;

-- next

ALTER TABLE Dim_School ADD TotalTeachers INT NULL;

-- next

UPDATE Dim_School
SET TeachersOfColor = (
	SELECT
		TeachersOfColor
	FROM TeacherCounts
	WHERE
		TeacherCounts.AcademicYear = Dim_school.AcademicYear
		AND TeacherCounts.CountyAndDistrictCode = Dim_school.DistrictCode
		AND TeacherCounts.Building = Dim_school.SchoolCode
	),
	TotalTeachers = (
	SELECT
		TotalTeachers
	FROM TeacherCounts
	WHERE
		TeacherCounts.AcademicYear = Dim_school.AcademicYear
		AND TeacherCounts.CountyAndDistrictCode = Dim_school.DistrictCode
		AND TeacherCounts.Building = Dim_school.SchoolCode
)
;

-- next

DROP TABLE TeacherCounts;

-- next

ALTER TABLE Dim_School ADD PrincipalOfColorFlag TINYINT NULL;

-- next

ALTER TABLE Dim_School ADD AsstPrincipalOfColorFlag TINYINT NULL;

-- next

UPDATE Dim_School
SET
	PrincipalOfColorFlag =
		CASE WHEN EXISTS (
			SELECT 1
			FROM Fact_SchoolPrincipal p
			JOIN Dim_Staff st
				ON p.StaffID = st.StaffID
			WHERE
				p.PrincipalType = 'Principal'
				AND st.PersonOfColorCategory = 'Person of Color'
				AND p.PrimaryFlag = 1
				AND p.AcademicYear = Dim_School.AcademicYear
				AND st.CountyAndDistrictCode = Dim_School.DistrictCode
				AND p.Building = Dim_School.SchoolCode
		) THEN 1 ELSE 0 END,
	AsstPrincipalOfColorFlag =
		CASE WHEN EXISTS (
			SELECT 1
			FROM Fact_SchoolPrincipal p
			JOIN Dim_Staff st
				ON p.StaffID = st.StaffID
			WHERE
				p.PrincipalType = 'AssistantPrincipal'
				AND st.PersonOfColorCategory = 'Person of Color'
				AND p.PrimaryFlag = 1
				AND p.AcademicYear = Dim_School.AcademicYear
				AND st.CountyAndDistrictCode = Dim_School.DistrictCode
				AND p.Building = Dim_School.SchoolCode
		) THEN 1 ELSE 0 END
;
