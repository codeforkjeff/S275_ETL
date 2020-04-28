-- we need this table for per-building rolled up fields, can't simply extend Fact_Assignment

DROP TABLE IF EXISTS Fact_SchoolPrincipal;

-- next

CREATE TABLE Fact_SchoolPrincipal (
    SchoolPrincipalID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StaffID INT NOT NULL,
    AcademicYear SMALLINT NOT NULL,
    Building varchar(500) NULL,
    DutyRoot varchar(2) NULL,
    PrincipalType VARCHAR(50) NULL,
    PrincipalPercentage NUMERIC(14,4) NULL,
    PrincipalFTEDesignation NUMERIC(14,4) NULL,
    PrincipalSalaryTotal INT NULL,
    PrimaryFlag TINYINT NULL,
    MetaCreatedAt DATETIME
);

-- next

INSERT INTO Fact_SchoolPrincipal (
    StaffID,
    AcademicYear,
    Building,
    DutyRoot,
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
    ,DutyRoot
    ,CASE
        WHEN cast(DutyRoot as integer) IN (21, 23) THEN 'Principal'
        WHEN cast(DutyRoot as integer) IN (22, 24) THEN 'AssistantPrincipal'
    END AS PrincipalType
    ,COALESCE(SUM(AssignmentPercent), 0) AS PrincipalPercentage
    ,SUM(AssignmentFTEDesignation) AS PrincipalFTEDesignation
    ,SUM(AssignmentSalaryTotal) AS PrincipalSalaryTotal
    ,0 AS PrimaryFlag
    ,GETDATE() as MetaCreatedAt
from Fact_Assignment a
JOIN Dim_Staff s ON a.StaffID = s.StaffID
WHERE IsPrincipalAssignment = 1 OR IsAsstPrincipalAssignment = 1
GROUP BY
    a.StaffID
    ,a.AcademicYear
    ,Building
    ,DutyRoot
;

-- next

DELETE FROM Fact_SchoolPrincipal
WHERE
    PrincipalFTEDesignation IS NULL
    OR PrincipalFTEDesignation <= 0;

-- next

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

