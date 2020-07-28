
-- PESB's persistence measure logic.
-- This table is rolled up to the AY and person level. Note that this is different from other fact tables
-- which include District in the grain.

DROP TABLE IF EXISTS Fact_PESBEducatorPersistence;

-- next

CREATE TABLE Fact_PESBEducatorPersistence (
	CertificateNumber     varchar(500) NOT   NULL,
	StartYear             smallint     NOT   NULL,
	EndYear               smallint     NOT   NULL,
	IsInPSESDFlag         tinyint      NOT   NULL,
	BeginningEducatorFlag tinyint      NOT   NULL,
	PersonOfColorCategory varchar(50)  NULL,
	YearCount             tinyint      NOT   NULL,
	PersistedFlag         tinyint      NOT   NULL,
	MetaCreatedAt         DATETIME,
	PRIMARY KEY (CertificateNumber, StartYear, EndYear)
);

-- next

WITH DistinctEducators AS (
	-- since we're collapsing multiple assignments at multiple buildings into single rows,
	-- we necessarily do some selection here
	SELECT
		a.AcademicYear
		,s.CertificateNumber
		,MAX(s.IsInPSESDFlag) AS IsInPSESDFlag
		-- flag is set if educator was 'Beginning' in any district
		,MAX(CASE WHEN s.CBRTNCode = 'B' THEN 1 ELSE 0 END) as BeginningEducatorFlag
		-- use MIN() to bias towards 'Person of Color' vs 'White':
		-- i.e. if they identified anywhere as POC for that year, consider them POC.
		,MIN(PersonOfColorCategory) AS PersonOfColorCategory
	FROM Fact_Assignment a
	JOIN Dim_Staff s
		ON a.StaffID = s.StaffID
	WHERE
		a.IsPESBEducatorAssignment = 1
		-- handful of rows where CertNumber is null
		AND s.CertificateNumber IS NOT NULL
		-- A note on PESB's Tableau viz says: "2016-17 starting cohort does not include beginning
		-- teachers from Bellevue School District due to probable reporting error."
		-- We follow that here.
		AnD NOT (a.AcademicYear = 2017 and s.CountyAndDistrictCode = '17405')
	GROUP BY
		a.AcademicYear
		,s.CertificateNumber

)
INSERT INTO Fact_PESBEducatorPersistence
SELECT
		e.CertificateNumber
		,e.AcademicYear AS StartYear
		,endyears.AcademicYear AS EndYear
		,e.IsInPSESDFlag AS IsInPSESDFlag
		,e.BeginningEducatorFlag AS BeginningEducatorFlag
		,e.PersonOfColorCategory AS PersonOfColorCategory
		,endyears.AcademicYear - e.AcademicYear + 1 AS YearCount
		,0 AS PersistedFlag
		,GETDATE() as MetaCreatedAt
FROM DistinctEducators e
CROSS JOIN
	(
		SELECT DISTINCT
			AcademicYear
		FROM Dim_Staff
	) AS endyears
WHERE
	-- limit to 2010 so table isn't enormous
	e.AcademicYear >= 2010
	AND e.AcademicYear < endyears.AcademicYear

-- next

DROP TABLE IF EXISTS EducatorContinued;

-- next

-- did educator Continue or Transfer in a given year?
CREATE TABLE EducatorContinued (
	AcademicYear                  smallint NOT   NULL,
	CertificateNumber             varchar(500) NOT NULL,
	ContinuedOrTransferredFlag    smallint NOT   NULL,
	PRIMARY KEY (AcademicYear, CertificateNumber)
);

-- next

INSERT INTO EducatorContinued
select
	s.AcademicYear,
	s.CertificateNumber,
	MAX(CASE WHEN s.CBRTNCode IN ('C', 'T') THEN 1 ELSE 0 END) AS ContinuedOrTransferredFlag
FROM Dim_Staff s
JOIN Fact_Assignment a
	ON s.StaffID = a.StaffID
WHERE
	a.IsPESBEducatorAssignment = 1
	and s.CertificateNumber IS NOT NULL
GROUP BY
	s.AcademicYear,
	s.CertificateNumber
;

-- next

DROP TABLE IF EXISTS EducatorContinuedCounts;

-- next

-- count how many records there are for continuation between StartYear and endyear, excluding StartYear.
CREATE TABLE EducatorContinuedCounts (
	CertificateNumber           varchar(500) NOT NULL,
	StartYear                   smallint     NOT NULL,
	EndYear                     smallint     NOT NULL,
	ContinuedOrTransferredCount smallint     NOT NULL,
	PRIMARY KEY (CertificateNumber, StartYear, EndYear)
);

-- next

INSERT INTO EducatorContinuedCounts
select
	p.CertificateNumber,
	p.StartYear,
	p.EndYear,
	SUM(ContinuedOrTransferredFlag) AS ContinuedOrTransferredCount
FROM Fact_PESBEducatorPersistence p
JOIN EducatorContinued ct
	ON p.CertificateNumber = ct.CertificateNumber
	AND ct.AcademicYear > p.StartYear
	AND ct.AcademicYear <= p.EndYear
GROUP BY
	p.CertificateNumber,
	p.StartYear,
	p.EndYear;

-- next

UPDATE Fact_PESBEducatorPersistence
SET PersistedFlag = 1
WHERE EXISTS (
	SELECT 1
	FROM EducatorContinuedCounts c
	WHERE
		Fact_PESBEducatorPersistence.CertificateNumber = c.CertificateNumber
		AND Fact_PESBEducatorPersistence.StartYear = c.StartYear
		AND Fact_PESBEducatorPersistence.EndYear = c.EndYear
		-- subtract 1 to exclude considering start year
		AND c.ContinuedOrTransferredCount = Fact_PESBEducatorPersistence.YearCount - 1
);

-- next

DROP TABLE EducatorContinued;

-- next

DROP TABLE EducatorContinuedCounts;
