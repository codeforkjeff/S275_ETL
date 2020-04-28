
DROP TABLE IF EXISTS Fact_TeacherCohortMobility;

-- next

CREATE TABLE Fact_TeacherCohortMobility (
	CohortYear                    smallint          NOT   NULL,
	CohortStaffID                 int          NOT   NULL,
	CertificateNumber             varchar(500) NOT NULL,
	CohortCountyAndDistrictCode   varchar(500) NULL,
	CohortBuilding                varchar(500) NULL,
	EndStaffID                    int          NULL,
	EndYear                       smallint          NOT NULL,
	EndCountyAndDistrictCode      varchar(500) NULL,
	EndBuilding                   varchar(500) NULL,
	StayedInSchool                tinyint          NOT   NULL,
	ChangedBuildingStayedDistrict tinyint          NOT   NULL,
	ChangedRoleStayedDistrict     tinyint          NOT   NULL,
	MovedOutDistrict              tinyint          NOT   NULL,
	Exited                        tinyint          NOT   NULL,
	MetaCreatedAt                 DATETIME,
	PRIMARY KEY (CohortYear, EndYear, CertificateNumber)
);

-- next

INSERT INTO Fact_TeacherCohortMobility
SELECT
        tc.CohortYear
        ,tc.CohortStaffID
		,tc.CertificateNumber
        ,tc.CohortCountyAndDistrictCode
		,tc.CohortBuilding
        ,a.EndStaffID
		,a.EndYear
        ,a.EndCountyAndDistrictCode
        ,a.EndBuilding
        ,CASE WHEN CohortBuilding = EndBuilding THEN 1 ELSE 0 END AS StayedInSchool
        -- people who stayed in district (may or may not be same building) and stayed teachers
        --,StayedInDistrict = CASE WHEN CohortCountyAndDistrictCode = EndCountyAndDistrictCode AND a.EndTeacherFlag = 1 THEN 1 ELSE 0 END -- may be in the same building
        ,CASE WHEN CohortBuilding <> EndBuilding AND CohortCountyAndDistrictCode = EndCountyAndDistrictCode AND a.EndTeacherFlag = 1 THEN 1 ELSE 0 END AS ChangedBuildingStayedDistrict -- definitely not in the same building  
        ,CASE WHEN CohortBuilding <> EndBuilding AND CohortCountyAndDistrictCode = EndCountyAndDistrictCode AND a.EndTeacherFlag = 0 THEN 1 ELSE 0 END AS ChangedRoleStayedDistrict -- definitely not in the same building
        ,CASE WHEN CohortCountyAndDistrictCode <> EndCountyAndDistrictCode THEN 1 ELSE 0 END AS MovedOutDistrict
        ,Exited 
        ,GETDATE() as MetaCreatedAt
FROM Fact_TeacherCohort tc
JOIN Fact_TeacherMobility a
	ON tc.CertificateNumber = a.CertificateNumber
WHERE
	-- take only the single year changes
	a.DiffYears = 1
	AND a.StartYear >= tc.CohortYear

-- next

-- ensure full representation of every CohortYear + EndYear combo for each teacher:
-- creating rows for missing EndYears (people who no longer appear in S275 and are thus considered exited)

INSERT INTO Fact_TeacherCohortMobility
SELECT
        tc.CohortYear
        ,tc.CohortStaffID
		,tc.CertificateNumber
        ,tc.CohortCountyAndDistrictCode
		,tc.CohortBuilding
        ,NULL as EndStaffID
		,y.AcademicYear as EndYear
        ,NULL AS EndCountyAndDistrictCode
        ,NULL AS EndBuilding
        ,0 AS StayedInSchool
        ,0 AS ChangedBuildingStayedDistrict
        ,0 AS ChangedRoleStayedDistrict
        ,0 AS MovedOutDistrict
        ,1 AS Exited
        ,GETDATE() as MetaCreatedAt
FROM Fact_TeacherCohort tc
CROSS JOIN
(
	SELECT DISTINCT
		AcademicYear
	FROM Dim_Staff
) AS y
WHERE
	y.AcademicYear > tc.CohortYear
	AND NOT EXISTS (
		SELECT 1
		FROM Fact_TeacherCohortMobility exists_
		WHERE
			exists_.CohortYear = tc.CohortYear
			AND exists_.EndYear = y.AcademicYear
			AND exists_.CertificateNumber = tc.CertificateNumber
	);

-- validation: this should return 0 rows
-- select top 1000 * 
-- from Fact_TeacherCohortMobility
-- where
-- 	StayedInSchool = 0
-- 	and ChangedBuildingStayedDistrict = 0
-- 	and ChangedRoleStayedDistrict = 0
-- 	and MovedOutDistrict = 0
-- 	and Exited = 0 
