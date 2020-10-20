-- we need this table for per-building rolled up fields, can't simply extend Fact_Assignment
--
-- grain of this table is StaffID (whose grain is AY, District, CertNumber), Building, PrincipalType.
-- this rolls up the 2 different DutyRoot codes for Principal and AssistantPrincipal, which are used to distinguish
-- between primary and secondary schools. It also rolls up multiple Assignments for the same DutyRoot:
-- Principals and APs sometimes have separate assignment line items by Grade Level.
--
-- since this table contains every principal/AP at every school they served at, users of this table
-- will typically want to filter by PrimaryFlag (to get one principal/AP per person/year)
-- or PrimaryForSchoolFlag (to get one principal/AP per school/year)

DROP TABLE IF EXISTS Fact_SchoolPrincipal;

-- next

CREATE TABLE Fact_SchoolPrincipal (
    SchoolPrincipalID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StaffID INT NOT NULL,
    AcademicYear SMALLINT NOT NULL,
    CountyAndDistrictCode varchar(500) NULL,
    Building varchar(500) NULL,
    PrincipalType VARCHAR(50) NULL,
    PrincipalPercentage NUMERIC(14,4) NULL,
    PrincipalFTEDesignation NUMERIC(14,4) NULL,
    PrincipalSalaryTotal INT NULL,
    PrimaryFlag TINYINT NULL,
    PrimaryForSchoolFlag TINYINT NULL,
    MetaCreatedAt DATETIME
);

-- next

WITH AssignmentsWithPrincipalType AS (
    SELECT
        *
        ,CASE
            WHEN cast(DutyRoot as integer) IN (21, 23) THEN 'Principal'
            WHEN cast(DutyRoot as integer) IN (22, 24) THEN 'AssistantPrincipal'
        END AS PrincipalType
    FROM Fact_assignment
)
INSERT INTO Fact_SchoolPrincipal (
    StaffID,
    AcademicYear,
    CountyAndDistrictCode,
    Building,
    PrincipalType,
    PrincipalPercentage,
    PrincipalFTEDesignation,
    PrincipalSalaryTotal,
    PrimaryFlag,
    PrimaryForSchoolFlag,
    MetaCreatedAt
)
select
    a.StaffID
    ,a.AcademicYear
    ,CountyAndDistrictCode
    ,Building
    ,PrincipalType
    ,COALESCE(SUM(AssignmentPercent), 0) AS PrincipalPercentage
    ,SUM(AssignmentFTEDesignation) AS PrincipalFTEDesignation
    ,SUM(AssignmentSalaryTotal) AS PrincipalSalaryTotal
    ,0 AS PrimaryFlag
    ,0 AS PrimaryForSchoolFlag
    ,GETDATE() as MetaCreatedAt
from AssignmentsWithPrincipalType a
JOIN Dim_Staff s ON a.StaffID = s.StaffID
WHERE IsPrincipalAssignment = 1 OR IsAsstPrincipalAssignment = 1
GROUP BY
    a.StaffID
    ,a.AcademicYear
    ,CountyAndDistrictCode
    ,Building
    -- is this right? or should we group by rolled up PrincipalType?
    ,PrincipalType
;

-- next

DELETE FROM Fact_SchoolPrincipal
WHERE
    PrincipalFTEDesignation IS NULL
    OR PrincipalFTEDesignation <= 0;

-- next

-- PrimaryFlag = pick the assighnment w/ highest FTE for the individual across
-- all schools where they serve, regardless of whether they were a Principal or Asst Prin.
-- It is NOT the "primary" Principal at the school (a school can sometimes have more than
-- one principal)

WITH Ranked AS (
    SELECT
        SchoolPrincipalID
        ,row_number() OVER (
            PARTITION BY
                sp.AcademicYear,
                CertificateNumber
            ORDER BY
                PrincipalFTEDesignation DESC,
                -- TODO: add school enrollment count as tiebreaker
                -- tiebreaking below this line
                PrincipalPercentage DESC,
                PrincipalSalaryTotal DESC
        ) AS RN
    FROM Fact_SchoolPrincipal sp
    JOIN Dim_Staff s ON sp.StaffID = s.StaffID
)
UPDATE Fact_SchoolPrincipal
SET PrimaryFlag = 1
WHERE EXISTS (
    SELECT 1
    FROM Ranked
    WHERE Ranked.SchoolPrincipalID = Fact_SchoolPrincipal.SchoolPrincipalID
    AND RN = 1
);

-- next

-- PrimaryForSchoolFlag = who is the Principal and AP with the highest FTE at each building?
-- better logic for this flag might be who served the longest during that year,
-- but we don't have start/end dates for assignments

WITH Ranked AS (
    SELECT
        SchoolPrincipalID
        ,row_number() OVER (
            PARTITION BY
                sp.AcademicYear,
                sp.CountyAndDistrictCode,
                sp.Building,
                sp.PrincipalType
            ORDER BY
                PrincipalFTEDesignation DESC,
                PrincipalPercentage DESC,
                PrincipalSalaryTotal DESC,
                CertYearsOfExperience DESC
        ) AS RN
    FROM Fact_SchoolPrincipal sp
    JOIN Dim_Staff s ON sp.StaffID = s.StaffID
)
UPDATE Fact_SchoolPrincipal
SET PrimaryForSchoolFlag = 1
WHERE EXISTS (
    SELECT 1
    FROM Ranked
    WHERE Ranked.SchoolPrincipalID = Fact_SchoolPrincipal.SchoolPrincipalID
    AND RN = 1
);

