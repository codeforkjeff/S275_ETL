
DROP TABLE IF EXISTS Fact_PrincipalCohort;

-- next

-- table for cohort-level attributes
CREATE TABLE Fact_PrincipalCohort (
	CohortYear                    smallint     NOT   NULL,
	CohortStaffID                 int          NOT   NULL,
	CertificateNumber             varchar(500) NULL,
	CohortCountyAndDistrictCode   varchar(500) NULL,
	CohortBuilding                varchar(500) NULL,
	CohortPrincipalType           varchar(500) NULL,
	MetaCreatedAt                 DATETIME
);

-- next

INSERT INTO Fact_PrincipalCohort
SELECT
    StartYear AS CohortYear
	,StartStaffID AS CohortStaffID
	,CertificateNumber
    ,StartCountyAndDistrictCode AS CohortCountyAndDistrictCode
    ,StartBuilding AS CohortBuilding
    ,StartPrincipalType AS CohortPrincipalType
    ,GETDATE() as MetaCreatedAt
FROM Fact_PrincipalMobility
WHERE
	DiffYears = 1
	-- handful of rows where Building is null from raw file. no idea what these mean.
	AND StartBuilding IS NOT NULL
	-- one row in 2014 where certificatnumber is null
	AND CertificateNumber IS NOT NULL
;

-- next

CREATE UNIQUE INDEX idx_Fact_PrincipalCohort ON Fact_PrincipalCohort (CertificateNumber, CohortYear, CohortPrincipalType);
