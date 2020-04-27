
DROP TABLE IF EXISTS Fact_TeacherCohort;

-- next

-- table for cohort-level attributes
CREATE TABLE Fact_TeacherCohort (
	CohortYear                    smallint     NOT   NULL,
	CohortStaffID                 int          NOT   NULL,
	CertificateNumber             varchar(500) NULL,
	CohortCountyAndDistrictCode   varchar(500) NULL,
	CohortBuilding                varchar(500) NULL
);

-- next

INSERT INTO Fact_TeacherCohort 
SELECT
    StartYear AS CohortYear
	,StartStaffID AS CohortStaffID
	,CertificateNumber
    ,StartCountyAndDistrictCode AS CohortCountyAndDistrictCode
    ,StartBuilding AS CohortBuilding
FROM Fact_TeacherMobility
WHERE
	DiffYears = 1
	-- handful of rows where Building is null from raw file. no idea what these mean.
	AND StartBuilding IS NOT NULL
;

-- next

CREATE UNIQUE INDEX idx_Fact_TeacherCohort ON dbo.Fact_TeacherCohort (CertificateNumber, CohortYear);
