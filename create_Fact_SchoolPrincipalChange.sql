
DROP TABLE IF EXISTS Fact_SchoolPrincipalChange;

-- next

CREATE TABLE Fact_SchoolPrincipalChange (
	AcademicYear               smallint     NOT   NULL,
	Building                   varchar(500) NULL,
	StaffID                    int          NOT   NULL,
	CertificateNumber          varchar(500) NULL,
	LastYearOfTenure           smallint     NULL,
	TenureDuration             smallint     NULL,
	PrincipalPercentage        numeric(14,  4)    NULL,
	PrincipalFTEDesignation    numeric(14,  4)    NULL,
	TeachersOfColor            smallint     null,
	TeachersWhite              smallint     null,
	TeachersTotal              smallint     null,
	TeachersOfColorRetained1Yr smallint     null,
	TeachersWhiteRetained1Yr   smallint     null,
	TeachersOfColorRetained2Yr smallint     null,
	TeachersWhiteRetained2Yr   smallint     null,
	MetaCreatedAt              DATETIME
);

-- next

DROP TABLE IF EXISTS TeacherRetention;

-- next
CREATE TABLE TeacherRetention (
	CohortYear      smallint     NOT   NULL,
	EndYear         smallint     NOT   NULL,
	Interval        tinyint      not   null,
	CohortBuilding  varchar(500) NULL,
	TeacherCategory varchar(50)  null,
	StayedInSchool  int          null
);

-- next

INSERT INTO TeacherRetention
SELECT
	CohortYear
	,EndYear
	,Interval = EndYear - CohortYear 
	,CohortBuilding
	,PersonOfColorCategory AS TeacherCategory
	,SUM(StayedInSchool) AS StayedInSchool
FROM Fact_TeacherCohortMobility a
JOIN Dim_Staff b
	ON a.CohortStaffID = b.StaffID
WHERE
	EndYear - CohortYear <= 2
GROUP BY
	CohortYear
	,EndYear
	,CohortBuilding
	,PersonOfColorCategory
;

-- next

-- schools can have 2 principals at the same time: Beamer in 2018
-- TODO: should we de-dupe to 1 principal per school first?

;WITH
Principals AS (
	SELECT
		s1.CertificateNumber,
		s1.LastName,
		t1.*
		,ROW_NUMBER() OVER (PARTITION BY Building ORDER BY t1.AcademicYear) as YearRankBySchool
	from Fact_SchoolPrincipal t1
	INNER JOIN Dim_Staff s1
		ON t1.StaffID = s1.StaffID
	WHERE 
		PrincipalType = 'Principal'
)
,PrincipalTransitions AS (
	-- find the transitions
	SELECT
		CASE 
			WHEN curr.CertificateNumber <> prev.CertificateNumber OR prev.AcademicYear is null THEN 1
			ELSE 0
		END As PrincipalChange,
		curr.*
	FROM Principals curr
	LEFT JOIN Principals prev
		ON curr.Building = prev.Building
		AND prev.AcademicYear = curr.AcademicYear - 1
)
,PrincipalChangesRanked AS (
	-- filter down to only the years when there was a change and rank them
	SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY CertificateNumber, Building ORDER BY YearRankBySchool) as YearRankByPrincipal
	FROM PrincipalTransitions
	WHERE PrincipalChange = 1
)
,PrincipalChanges AS (
	SELECT
		*
	FROM PrincipalChangesRanked
	WHERE YearRankByPrincipal = 1
)
,TenureEndYears AS (
	-- if the next year doesn't have the same principal, then current year is the end of a period of tenure
	SELECT
		curr.*,
		CASE 
			WHEN curr.CertificateNumber <> next_.CertificateNumber THEN curr.AcademicYear
			ELSE NULL
		END As TenureEndYear
	FROM PrincipalTransitions curr
	LEFT JOIN Principals next_
		ON curr.Building = next_.Building
		AND next_.AcademicYear = curr.AcademicYear + 1
)
,FirstTenureEndYear AS (
	-- take the first tenure end year, since there may be multiple
	-- if a principal leaves and comes back
	SELECT 
		CertificateNumber,
		Building,
		MIN(TenureEndYear) As FirstTenureEndYear
	FROM TenureEndYears
	GROUP BY
		CertificateNumber,
		Building
)
INSERT INTO Fact_SchoolPrincipalChange
(
	AcademicYear,
	Building,
	StaffID,
	CertificateNumber,
	LastYearOfTenure,
	TenureDuration,
	PrincipalPercentage,
	PrincipalFTEDesignation,
	MetaCreatedAt
)
SELECT
	t1.AcademicYear,
	t1.Building,
	t1.StaffID,
	t1.CertificateNumber,
	t2.FirstTenureEndYear AS LastYearOfTenure,
	(t2.FirstTenureEndYear - t1.AcademicYear + 1) AS TenureDuration,
	t1.PrincipalPercentage,
	t1.PrincipalFTEDesignation,
	GETDATE() AS MetaCreatedAt
FROM PrincipalChanges t1
LEFT JOIN FirstTenureEndYear t2
	ON t1.CertificateNumber = t2.CertificateNumber  
	AND t1.Building = t2.Building
ORDER BY Building, AcademicYear;

-- next

UPDATE Fact_SchoolPrincipalChange
SET TeachersTotal = 
	(SELECT COUNT(*) as total
	FROM Fact_TeacherCohort t1
	INNER JOIN Dim_Staff t2
		ON t1.CohortStaffID = t2.StaffID
	WHERE
		t1.CohortYear = Fact_SchoolPrincipalChange.AcademicYear
		AND t1.CohortBuilding = Fact_SchoolPrincipalChange.Building);

-- next

UPDATE Fact_SchoolPrincipalChange
SET TeachersOfColor = 
	(SELECT COUNT(*) as total
	FROM Fact_TeacherCohort t1
	INNER JOIN Dim_Staff t2
		ON t1.CohortStaffID = t2.StaffID
	WHERE
		t2.PersonOfColorCategory = 'Person of Color'
		AND t1.CohortYear = Fact_SchoolPrincipalChange.AcademicYear
		AND t1.CohortBuilding = Fact_SchoolPrincipalChange.Building);

-- next

UPDATE Fact_SchoolPrincipalChange
SET TeachersWhite = 
	(SELECT COUNT(*) as total
	FROM Fact_TeacherCohort t1
	INNER JOIN Dim_Staff t2
		ON t1.CohortStaffID = t2.StaffID
	WHERE
		t2.PersonOfColorCategory = 'White'
		AND t1.CohortYear = Fact_SchoolPrincipalChange.AcademicYear
		AND t1.CohortBuilding = Fact_SchoolPrincipalChange.Building);

-- next

UPDATE Fact_SchoolPrincipalChange
SET TeachersOfColorRetained1Yr = 
	(SELECT StayedInSchool as total
	FROM TeacherRetention t
	WHERE
		t.Interval = 1
		AND t.TeacherCategory = 'Person of Color'
		AND t.CohortYear = Fact_SchoolPrincipalChange.AcademicYear
		AND t.CohortBuilding = Fact_SchoolPrincipalChange.Building
	);

-- next

UPDATE Fact_SchoolPrincipalChange
SET TeachersWhiteRetained1Yr  = 
	(SELECT StayedInSchool as total
	FROM TeacherRetention t
	WHERE
		t.Interval = 1
		AND t.TeacherCategory = 'White'
		AND t.CohortYear = Fact_SchoolPrincipalChange.AcademicYear
		AND t.CohortBuilding = Fact_SchoolPrincipalChange.Building
	);

-- next

UPDATE Fact_SchoolPrincipalChange
SET TeachersOfColorRetained2Yr = 
	(SELECT StayedInSchool as total
	FROM TeacherRetention t
	WHERE
		t.Interval = 2
		AND t.TeacherCategory = 'Person of Color'
		AND t.CohortYear = Fact_SchoolPrincipalChange.AcademicYear
		AND t.CohortBuilding = Fact_SchoolPrincipalChange.Building
	);

-- next

UPDATE Fact_SchoolPrincipalChange
SET TeachersWhiteRetained2Yr    = 
	(SELECT StayedInSchool as total
	FROM TeacherRetention t
	WHERE
		t.Interval = 2
		AND t.TeacherCategory = 'White'
		AND t.CohortYear = Fact_SchoolPrincipalChange.AcademicYear
		AND t.CohortBuilding = Fact_SchoolPrincipalChange.Building
	);
