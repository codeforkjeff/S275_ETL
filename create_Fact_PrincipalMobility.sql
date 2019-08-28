
-- This logic selects a single principal (either 'main' principal or Asst Principal)/building per year

DROP TABLE IF EXISTS BaseSchoolPrincipals;

-- next

CREATE TABLE BaseSchoolPrincipals (
    StaffID int not null,
    AcademicYear int NOT NULL,
    CertificateNumber varchar(500) NULL,
    CountyAndDistrictCode varchar(500) NULL,
    Building varchar(500) NULL,
    DutyRoot varchar(2) NULL,
    PrincipalType varchar(50) NULL
);

-- next

INSERT INTO BaseSchoolPrincipals (
    StaffID,
    AcademicYear,
    CertificateNumber,
    CountyAndDistrictCode,
    Building,
    DutyRoot,
    PrincipalType
)
SELECT
    sp.StaffID,
    sp.AcademicYear,
    CertificateNumber,
    CountyAndDistrictCode,
    Building,
    DutyRoot,
    PrincipalType
FROM Fact_SchoolPrincipal sp
JOIN Dim_Staff s
    ON sp.StaffID = s.StaffID
    WHERE PrimaryFlag = 1;

-- next

CREATE INDEX idx_BaseSchoolPrincipals ON BaseSchoolPrincipals (
    AcademicYear
    ,CountyAndDistrictCode
    ,Building
);

-- next

DROP TABLE IF EXISTS HighestFTE;

-- next

CREATE TABLE HighestFTE (
    StaffID int not null,
    AcademicYear int NOT NULL,
    CertificateNumber varchar(500) NULL,
    CountyAndDistrictCode varchar(500) NULL,
    Building varchar(500) NULL,
    DutyRoot varchar(2) NULL
);

-- next

-- do selection to create one row per cert/year
-- picking the highest assignment FTE, used to calculate the location of endyear
WITH T AS (
    SELECT
        t.StaffID
        ,t.AcademicYear
        ,CertificateNumber
        ,s.CountyAndDistrictCode
        ,Building
        ,ROW_NUMBER() OVER (PARTITION BY
            t.AcademicYear,
            CertificateNumber
        ORDER BY
            AssignmentFTEDesignation DESC,
            -- tiebreaking below this line
            AssignmentPercent DESC,
            AssignmentSalaryTotal DESC
        ) as RN
    FROM Fact_assignment t
    JOIN Dim_Staff s
        ON t.StaffID = s.StaffID
)
INSERT INTO HighestFTE (
    StaffID,
    AcademicYear,
    CertificateNumber,
    CountyAndDistrictCode,
    Building
)
SELECT
    StaffID
    ,AcademicYear
    ,CertificateNumber
    ,CountyAndDistrictCode
    ,Building
FROM T
WHERE RN = 1;

-- next

CREATE INDEX idx_HighestFTE ON HighestFTE (
    CertificateNumber
    ,AcademicYear
);

-- next

DROP TABLE IF EXISTS Fact_PrincipalMobility;

-- next

CREATE TABLE Fact_PrincipalMobility (
    StartStaffID int not null,
    EndStaffID int null,
    StartYear int NOT NULL,
    EndYear int NULL,
    DiffYears int NULL,
    CertificateNumber varchar(500) NULL,
    StartCountyAndDistrictCode varchar(500) NULL,
    StartBuilding varchar(500) NULL,
    StartPrincipalType varchar(50) NULL,
    EndHighestFTECountyAndDistrictCode varchar(500) NULL,
    EndHighestFTEBuilding varchar(500) NULL,
    EndPrincipalType varchar(50) NULL,
    Stayer int NOT NULL,
    MovedIn int NOT NULL,
    MovedOut int NOT NULL,
    MovedOutOfRMR int NOT NULL,
    Exited int NOT NULL,
    SameAssignment int NOT NULL,
    NoLongerAnyPrincipal int NOT NULL,
    AsstToPrincipal int NOT NULL,
    PrincipalToAsst int NOT NULL,
    MetaCreatedAt DATETIME
);

-- next

WITH
YearBrackets AS (
    SELECT DISTINCT
        AcademicYear AS StartYear,
        AcademicYear + 1 AS EndYear
    FROM BaseSchoolPrincipals y1
    WHERE EXISTS (
        SELECT 1 FROM BaseSchoolPrincipals WHERE AcademicYear = y1.AcademicYear + 1
    )
    UNION ALL
    SELECT DISTINCT
        AcademicYear AS StartYear,
        AcademicYear + 4 AS EndYear
    FROM BaseSchoolPrincipals y2
    WHERE EXISTS (
        SELECT 1 FROM BaseSchoolPrincipals WHERE AcademicYear = y2.AcademicYear + 4
    )
)
,TransitionsBase AS (
    SELECT
        t1.StaffID AS StartStaffID,
        t2.StaffID AS EndStaffID,
        t1.AcademicYear AS StartYear,
        y.EndYear AS EndYear,
        y.EndYear - t1.AcademicYear AS DiffYears,
        t1.CertificateNumber,
        -- start fields
        t1.CountyAndDistrictCode AS StartCountyAndDistrictCode,
        t1.Building AS StartBuilding,
        t1.DutyRoot AS StartDutyRoot,
        t1.PrincipalType AS StartPrincipalType,
        -- end fields, using HighestFTE
        t2.CountyAndDistrictCode AS EndHighestFTECountyAndDistrictCode,
        t2.Building AS EndHighestFTEBuilding,
        t2.DutyRoot AS EndHighestFTEDutyRoot,
        -- end fields, using principals table
        t3.PrincipalType AS EndPrincipalType,
        t3.DutyRoot AS EndPrincipalDutyRoot,
        -- avoid counting exiters by checking for join to a HighestFTE row to ensure they're still employed somehow;
        -- if join didn't match anything in BaseSchoolPrincipals, then person isn't a Principal or AP in endyear
        CASE WHEN t2.CertificateNumber IS NOT NULL AND t3.CertificateNumber IS NULL THEN 1 ELSE 0 END AS NoLongerAnyPrincipal
    FROM BaseSchoolPrincipals t1
    JOIN YearBrackets y
        ON t1.AcademicYear = y.StartYear
    -- join to a wide set of staff/yr/highest duty root
    LEFT JOIN HighestFTE t2
        ON t1.CertificateNumber = t2.CertificateNumber
        AND y.EndYear = t2.AcademicYear
    -- join to a set of principals
    LEFT JOIN BaseSchoolPrincipals t3
        ON t1.CertificateNumber = t3.CertificateNumber
        AND y.EndYear = t3.AcademicYear
)
,Transitions AS (
    SELECT
        *
        -- mobility for principals is based strictly on location
        ,CASE WHEN StartBuilding = EndHighestFTEBuilding THEN 1 ELSE 0 END as Stayer
        ,CASE WHEN
            StartBuilding <> EndHighestFTEBuilding AND StartCountyAndDistrictCode = EndHighestFTECountyAndDistrictCode
        THEN 1 ELSE 0 END as MovedIn
        ,CASE WHEN
            StartCountyAndDistrictCode <> EndHighestFTECountyAndDistrictCode
        THEN 1 ELSE 0 END as MovedOut
        ,CASE WHEN
            EndHighestFTEBuilding IS NULL
        THEN 1 ELSE 0 END AS Exited
        ,CASE WHEN StartDutyRoot = EndPrincipalDutyRoot THEN 1 ELSE 0 END AS SameAssignment
        ,CASE
            WHEN StartPrincipalType = 'AssistantPrincipal' AND EndPrincipalType = 'Principal'
        THEN 1 ELSE 0 END AS AsstToPrincipal
        ,CASE
            WHEN StartPrincipalType = 'Principal' AND EndPrincipalType = 'AssistantPrincipal'
        THEN 1 ELSE 0 END AS PrincipalToAsst
    FROM TransitionsBase
)
INSERT INTO Fact_PrincipalMobility (
    StartStaffID,
    EndStaffID,
    StartYear,
    EndYear,
    DiffYears,
    CertificateNumber,
    StartCountyAndDistrictCode,
    StartBuilding,
    StartPrincipalType,
    EndHighestFTECountyAndDistrictCode,
    EndHighestFTEBuilding,
    EndPrincipalType,
    Stayer,
    MovedIn,
    MovedOut,
    MovedOutOfRMR,
    Exited,
    SameAssignment,
    NoLongerAnyPrincipal,
    AsstToPrincipal,
    PrincipalToAsst,
    MetaCreatedAt
)
SELECT
    StartStaffID
    ,EndStaffID
    ,StartYear
    ,EndYear
    ,DiffYears
    ,CertificateNumber
    ,StartCountyAndDistrictCode
    ,StartBuilding
    ,StartPrincipalType
    ,EndHighestFTECountyAndDistrictCode
    ,EndHighestFTEBuilding
    ,EndPrincipalType
    ,Stayer
    ,MovedIn
    ,MovedOut
    ,0 AS MovedOutOfRMR
    ,Exited
    ,SameAssignment
    ,NoLongerAnyPrincipal
    ,AsstToPrincipal
    ,PrincipalToAsst
    ,GETDATE() as MetaCreatedAt
FROM Transitions;

-- next

UPDATE Fact_PrincipalMobility
SET MovedOutOfRMR = CASE
    WHEN MovedOut = 1
        AND EXISTS (
            SELECT 1
            FROM Dim_School
            WHERE
                Fact_PrincipalMobility.StartYear = AcademicYear
                AND Fact_PrincipalMobility.StartBuilding = SchoolCode
            AND RMRFlag = 1
            )
        AND NOT EXISTS (
            SELECT 1
            FROM Dim_School
            WHERE
                Fact_PrincipalMobility.EndYear = AcademicYear
                AND Fact_PrincipalMobility.EndHighestFTEBuilding = SchoolCode
            AND RMRFlag = 1
            )
    THEN 1
    ELSE 0
    END;

-- next

CREATE INDEX idx_Fact_PrincipalMobility ON Fact_PrincipalMobility(StartStaffID, EndStaffID);

-- next

CREATE INDEX idx_Fact_PrincipalMobility2 ON Fact_PrincipalMobility(StartYear, StartCountyAndDistrictCode, StartBuilding);

-- next

-- cleanup
DROP TABLE BaseSchoolPrincipals;

-- next

DROP TABLE HighestFTE;
