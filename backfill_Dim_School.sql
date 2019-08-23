
WITH MissingSchools as (
	SELECT AcademicYear, Building
	FROM Fact_Assignment
	WHERE Building is not null
	EXCEPT
	SELECT DISTINCT AcademicYear, SchoolCode
	FROM Dim_School
	WHERE SchoolCode is not null
)
,Ranked AS (
	SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY SchoolCode ORDER BY AcademicYear DESC) AS Rank
	FROM Dim_School
),
MostRecentSchools AS (
	SELECT *
	FROM Ranked
	WHERE Rank = 1
)
INSERT INTO Dim_School
(
    AcademicYear,
    DistrictCode,
    DistrictName,
    SchoolCode,
    SchoolName,
    Lat,
    Long,
    RMRFlag
)
SELECT
	missing.AcademicYear
	,COALESCE(recent.DistrictCode, 'UNKNOWN') AS DistrictCode
	,COALESCE(recent.DistrictName, 'UNKNOWN') AS DistrictName
	,missing.Building AS SchoolCode
	,COALESCE(recent.SchoolName, 'UNKNOWN') AS SchoolName
	,recent.Lat
    ,recent.Long
	,COALESCE(recent.RMRFlag, 0) AS RMRFlag
FROM MissingSchools missing
LEFT JOIN MostRecentSchools recent
	ON missing.Building = recent.SchoolCode
;
