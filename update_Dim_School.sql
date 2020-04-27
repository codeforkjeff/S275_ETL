
DROP TABLE IF EXISTS TeacherCounts;

-- next

CREATE TABLE TeacherCounts (
	AcademicYear INT NOT NULL,
    Building varchar(500) NULL,
	TeachersOfColor INT NULL,
	TotalTeachers INT NULL
);

-- next

INSERT INTO TeacherCounts
SELECT
	st.AcademicYear,
	st.Building,
	SUM(CASE WHEN staff.PersonOfColorCategory = 'Person of Color' THEN 1 ELSE 0 END) AS TeacherOfColors,
	COUNT(*) AS TotalTeachers
FROM Fact_SchoolTeacher st
JOIN Dim_Staff staff
	ON st.StaffID = staff.StaffID
JOIN Dim_School sch
	ON st.AcademicYear = sch.AcademicYear
	and st.Building = sch.SchoolCode
WHERE PrimaryFlag = 1
GROUP BY
	st.AcademicYear,
	st.Building
ORDER BY
	st.AcademicYear,
	st.Building
;

ALTER TABLE Dim_School ADD TeachersOfColor INT NULL;
ALTER TABLE Dim_School ADD TotalTeachers INT NULL;

-- next

UPDATE Dim_School
SET TeachersOfColor = (
	SELECT
		TeachersOfColor
	FROM TeacherCounts
	WHERE
		TeacherCounts.AcademicYear = Dim_school.AcademicYear
		AND TeacherCounts.Building = Dim_school.SchoolCode
	),
	TotalTeachers = (
	SELECT
		TotalTeachers
	FROM TeacherCounts
	WHERE
		TeacherCounts.AcademicYear = Dim_school.AcademicYear
		AND TeacherCounts.Building = Dim_school.SchoolCode
)
;
