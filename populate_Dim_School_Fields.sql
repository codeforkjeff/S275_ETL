
INSERT INTO Dim_School (
    AcademicYear,
    DistrictCode,
    DistrictName,
    SchoolCode,
    SchoolName,
    GradeLevelStart,
    GradeLevelEnd,
    GradeLevelSortOrderStart,
    GradeLevelSortOrderEnd,
    SchoolType,
    Lat,
    Long ,
    NCESLocaleCode,
    NCESLocale,
    RMRFlag,
    MetaCreatedAt
)
SELECT 
    AcademicYear,
    DistrictCode,
    DistrictName,
    SchoolCode,
    SchoolName,
    GradeLevelStart,
    GradeLevelEnd,
    GradeLevelSortOrderStart,
    GradeLevelSortOrderEnd,
    SchoolType,
    Lat,
    Long ,
    NCESLocaleCode,
    NCESLocale,
    RMRFlag,
    GETDATE() AS MetaCreatedAt
FROM Dim_School_Base;

-- next

-- this is verbose and annoying but has to be done this way for compatibility with sqlite

UPDATE Dim_School
SET
	TotalEnrollmentOct = (
		SELECT TotalEnrollmentOct
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,GraduationPercent = (
		SELECT GraduationPercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,FRPL = (
		SELECT FRPL
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,FRPLPercent = (
		SELECT FRPLPercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,AmIndOrAlaskan = (
		SELECT AmIndOrAlaskan
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,AmIndOrAlaskanPercent = (
		SELECT AmIndOrAlaskanPercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,Asian = (
		SELECT Asian
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,AsianPercent = (
		SELECT AsianPercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,PacIsl = (
		SELECT PacIsl
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,PacIslPercent = (
		SELECT PacIslPercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,AsPacIsl = (
		SELECT AsPacIsl
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,AsPacIslPercent = (
		SELECT AsPacIslPercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,Black = (
		SELECT Black
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,BlackPercent = (
		SELECT BlackPercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,Hispanic = (
		SELECT Hispanic
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,HispanicPercent = (
		SELECT HispanicPercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,White = (
		SELECT White
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,WhitePercent = (
		SELECT WhitePercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,TwoOrMoreRaces = (
		SELECT TwoOrMoreRaces
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,TwoOrMoreRacesPercent = (
		SELECT TwoOrMoreRacesPercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,Male = (
		SELECT Male
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,MalePercent = (
		SELECT MalePercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,Female = (
		SELECT Female
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,FemalePercent = (
		SELECT FemalePercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,GenderX = (
		SELECT GenderX
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
	,GenderXPercent = (
		SELECT GenderXPercent
		FROM Dim_School_Fields d
		WHERE 
			Dim_School.AcademicYear = d.AcademicYear
			AND Dim_School.DistrictCode = d.DistrictCode
			AND Dim_School.SchoolCode = d.SchoolCode
	)
;

-- next

UPDATE Dim_School
SET
	StudentsOfColor =
		COALESCE(AmIndOrAlaskan, 0)
		+ COALESCE(Asian, 0)
		+ COALESCE(PacIsl, 0)
		+ COALESCE(Black, 0)
		+ COALESCE(Hispanic, 0)
		+ COALESCE(TwoOrMoreRaces, 0)
WHERE TotalEnrollmentOct > 0;

-- next

UPDATE Dim_School
SET
	StudentsOfColorPercent = StudentsOfColor / TotalEnrollmentOct
WHERE TotalEnrollmentOct > 0;
