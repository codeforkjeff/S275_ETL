-- we need this table for per-building rolled up fields, can't simply extend Fact_Assignment
--
-- grain of this table is StaffID (whose grain is AY, District, CertNumber), Building, PrincipalType.
-- this rolls up the 2 different DutyRoot codes for Principal and AssistantPrincipal, which are used to distinguish
-- between primary and secondary schools.

DROP TABLE IF EXISTS Fact_SchoolPrincipal;

-- next

CREATE TABLE Fact_SchoolPrincipal (
    SchoolPrincipalID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StaffID INT NOT NULL,
    AcademicYear SMALLINT NOT NULL,
    Building varchar(500) NULL,
    PrincipalType VARCHAR(50) NULL,
    PrincipalPercentage NUMERIC(14,4) NULL,
    PrincipalFTEDesignation NUMERIC(14,4) NULL,
    PrincipalSalaryTotal INT NULL,
    PrimaryFlag TINYINT NULL,
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
    Building,
    PrincipalType,
    PrincipalPercentage,
    PrincipalFTEDesignation,
    PrincipalSalaryTotal,
    PrimaryFlag,
    MetaCreatedAt
)
select
    a.StaffID
    ,a.AcademicYear
    ,Building
    ,PrincipalType
    ,COALESCE(SUM(AssignmentPercent), 0) AS PrincipalPercentage
    ,SUM(AssignmentFTEDesignation) AS PrincipalFTEDesignation
    ,SUM(AssignmentSalaryTotal) AS PrincipalSalaryTotal
    ,0 AS PrimaryFlag
    ,GETDATE() as MetaCreatedAt
from AssignmentsWithPrincipalType a
JOIN Dim_Staff s ON a.StaffID = s.StaffID
WHERE IsPrincipalAssignment = 1 OR IsAsstPrincipalAssignment = 1
GROUP BY
    a.StaffID
    ,a.AcademicYear
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

