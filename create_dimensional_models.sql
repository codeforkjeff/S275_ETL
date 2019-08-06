-- NOTE: some steps in this file might seem circuitous but they're done that way
-- in order to work with both sqlite and SQL Server.

DROP TABLE IF EXISTS S275_Coalesced;

-- next

-- create copy of S275 table: several fields used for combo key in Dim_Staff are
-- copied to coalesced versions. This avoids having to use COALESCE()
-- in the join clause when populating fact tables with keys to Dim_Staff,
-- which is extremely time consuming.
CREATE TABLE S275_Coalesced (
    AcademicYear varchar(500) NULL,
    Area varchar(500) NULL,
    County varchar(500) NULL,
    District varchar(500) NULL,
    CountyAndDistrictCode varchar(500) NULL,
    LastName varchar(500) NULL,
    FirstName varchar(500) NULL,
    MiddleName varchar(500) NULL,
    CertificateNumber varchar(500) NULL,
    Birthdate varchar(500) NULL,
    Sex varchar(500) NULL,
    Hispanic varchar(500) NULL,
    Race varchar(500) NULL,
    HighestDegree varchar(500) NULL,
    HighestDegreeYear varchar(500) NULL,
    AcademicCredits varchar(500) NULL,
    InServiceCredits varchar(500) NULL,
    ExcessCredits varchar(500) NULL,
    NonDegreeCredits varchar(500) NULL,
    CertYearsOfExperience varchar(500) NULL,
    StaffMixFactor varchar(500) NULL,
    FTEHours varchar(500) NULL,
    FTEDays varchar(500) NULL,
    CertificatedFTE varchar(500) NULL,
    ClassifiedFTE varchar(500) NULL,
    CertificatedBase varchar(500) NULL,
    ClassifiedBase varchar(500) NULL,
    OtherSalary varchar(500) NULL,
    TotalFinalSalary varchar(500) NULL,
    ActualAnnualInsurance varchar(500) NULL,
    ActualAnnualMandatory varchar(500) NULL,
    CBRTNCode varchar(500) NULL,
    ClassificationFlag varchar(500) NULL,
    CertifiedFlag varchar(500) NULL,
    NationalBoardCertExpirationDate varchar(500) NULL,
    RecordNumber varchar(500) NULL,
    ProgramCode varchar(500) NULL,
    ActivityCode varchar(500) NULL,
    DutyArea varchar(500) NULL,
    DutyRoot varchar(500) NULL,
    DutySuffix varchar(500) NULL,
    Grade varchar(500) NULL,
    Building varchar(500) NULL,
    AssignmentPercent varchar(500) NULL,
    AssignmentFTEDesignation varchar(500) NULL,
    AssignmentSalaryTotal varchar(500) NULL,
    AssignmentHoursPerYear varchar(500) NULL,
    Major varchar(500) NULL,
    TwoDigitYear varchar(500) NULL,
    FileType varchar(500) NULL,
    -- coalesced fields
    LastNameC varchar(500) NULL,
    FirstNameC varchar(500) NULL,
    MiddleNameC varchar(500) NULL,
    CertificateNumberC varchar(500) NULL
);

-- next

INSERT INTO S275_Coalesced
SELECT
    *,
    COALESCE(LastName, '') AS LastNameC,
    COALESCE(FirstName, '') AS FirstNameC,
    COALESCE(MiddleName, '') AS MiddleNameC,
    COALESCE(CertificateNumber, '') AS CertificateNumberC
FROM S275;

-- next

DROP TABLE IF EXISTS Dim_Staff_Coalesced;

-- next

CREATE TABLE Dim_Staff_Coalesced (
    StaffID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    AcademicYear varchar(500) NULL,
    Area varchar(500) NULL,
    County varchar(500) NULL,
    District varchar(500) NULL,
    CountyAndDistrictCode varchar(500) NULL,
    LastName varchar(500) NULL,
    FirstName varchar(500) NULL,
    MiddleName varchar(500) NULL,
    CertificateNumber varchar(500) NULL,
    -- coalesced fields
    LastNameC varchar(500) NULL,
    FirstNameC varchar(500) NULL,
    MiddleNameC varchar(500) NULL,
    CertificateNumberC varchar(500) NULL,
    --
    Birthdate varchar(500) NULL,
    Sex varchar(500) NULL,
    Hispanic varchar(500) NULL,
    Race varchar(500) NULL,
    HighestDegree varchar(500) NULL,
    HighestDegreeYear varchar(500) NULL,
    AcademicCredits varchar(500) NULL,
    InServiceCredits varchar(500) NULL,
    ExcessCredits varchar(500) NULL,
    NonDegreeCredits varchar(500) NULL,
    CertYearsOfExperience varchar(500) NULL,
    StaffMixFactor varchar(500) NULL,
    FTEHours varchar(500) NULL,
    FTEDays varchar(500) NULL,
    CertificatedFTE varchar(500) NULL,
    ClassifiedFTE varchar(500) NULL,
    CertificatedBase varchar(500) NULL,
    ClassifiedBase varchar(500) NULL,
    OtherSalary varchar(500) NULL,
    TotalFinalSalary varchar(500) NULL,
    ActualAnnualInsurance varchar(500) NULL,
    ActualAnnualMandatory varchar(500) NULL,
    CBRTNCode varchar(500) NULL,
    ClassificationFlag varchar(500) NULL,
    CertifiedFlag varchar(500) NULL,
    NationalBoardCertExpirationDate varchar(500) NULL,
    IsTeacherFlag INT NOT NULL
);

-- next

INSERT INTO Dim_Staff_Coalesced (
    AcademicYear,
    Area,
    County,
    District,
    CountyAndDistrictCode,
    LastName,
    FirstName,
    MiddleName,
    CertificateNumber,
    -- coalesced
    LastNameC,
    FirstNameC,
    MiddleNameC,
    CertificateNumberC,
    --
    Birthdate,
    Sex,
    Hispanic,
    Race,
    HighestDegree,
    HighestDegreeYear,
    AcademicCredits,
    InServiceCredits,
    ExcessCredits,
    NonDegreeCredits,
    CertYearsOfExperience,
    StaffMixFactor,
    FTEHours,
    FTEDays,
    CertificatedFTE,
    ClassifiedFTE,
    CertificatedBase,
    ClassifiedBase,
    OtherSalary,
    TotalFinalSalary,
    ActualAnnualInsurance,
    ActualAnnualMandatory,
    CBRTNCode,
    ClassificationFlag,
    CertifiedFlag,
    NationalBoardCertExpirationDate,
    IsTeacherFlag
)
SELECT DISTINCT
    AcademicYear,
    Area,
    County,
    District,
    CountyAndDistrictCode,
    LastName,
    FirstName,
    MiddleName,
    CertificateNumber,
    --
    LastNameC,
    FirstNameC,
    MiddleNameC,
    CertificateNumberC,
    --
    Birthdate,
    Sex,
    Hispanic,
    Race,
    HighestDegree,
    HighestDegreeYear,
    AcademicCredits,
    InServiceCredits,
    ExcessCredits,
    NonDegreeCredits,
    CertYearsOfExperience,
    StaffMixFactor,
    FTEHours,
    FTEDays,
    CertificatedFTE,
    ClassifiedFTE,
    CertificatedBase,
    ClassifiedBase,
    OtherSalary,
    TotalFinalSalary,
    ActualAnnualInsurance,
    ActualAnnualMandatory,
    CBRTNCode,
    ClassificationFlag,
    CertifiedFlag,
    NationalBoardCertExpirationDate,
    0 As IsTeacherFlag
FROM S275_Coalesced t;

-- next

CREATE UNIQUE INDEX idx_Dim_Staff_Coalesced ON Dim_Staff_Coalesced (
    AcademicYear,
    Area,
    CountyAndDistrictCode,
    LastNameC,
    FirstNameC,
    MiddleNameC,
    CertificateNumberC
);

-- next

DROP TABLE IF EXISTS Fact_Assignment;

-- next

CREATE TABLE Fact_Assignment (
    StaffID INT NOT NULL,
    AcademicYear INT NOT NULL,
    RecordNumber varchar(500) NULL,
    ProgramCode varchar(500) NULL,
    ActivityCode varchar(500) NULL,
    DutyArea varchar(500) NULL,
    DutyRoot varchar(500) NULL,
    DutySuffix varchar(500) NULL,
    DutyDescription varchar(100) NULL,
    Grade varchar(500) NULL,
    Building varchar(500) NULL,
    AssignmentPercent NUMERIC(14,4) NULL,
    AssignmentFTEDesignation NUMERIC(14,4) NULL,
    AssignmentSalaryTotal INT NULL,
    AssignmentHoursPerYear varchar(500) NULL,
    Major varchar(500) NULL,
    TwoDigitYear varchar(500) NULL,
    FileType varchar(500) NULL,
    IsTeachingAssignment INT NOT NULL
);

-- next

INSERT INTO Fact_Assignment (
    StaffID,
    AcademicYear,
    RecordNumber,
    ProgramCode,
    ActivityCode,
    DutyArea,
    DutyRoot,
    DutySuffix,
    DutyDescription,
    Grade,
    Building,
    AssignmentPercent,
    AssignmentFTEDesignation,
    AssignmentSalaryTotal,
    AssignmentHoursPerYear,
    Major ,
    TwoDigitYear,
    FileType,
    IsTeachingAssignment
)
SELECT
    StaffID,
    S275.AcademicYear,
    RecordNumber,
    ProgramCode,
    ActivityCode,
    DutyArea,
    S275.DutyRoot,
    S275.DutySuffix,
    DutyCodes.Description AS DutyDescription,
    Grade,
    Building,
    AssignmentPercent,
    AssignmentFTEDesignation,
    AssignmentSalaryTotal,
    AssignmentHoursPerYear,
    Major ,
    TwoDigitYear,
    FileType,
    CASE WHEN
        S275.DutyRoot IN ('31','32','33','34')
        AND ActivityCode ='27'
        AND S275.Area = 'L'
    THEN 1 ELSE 0 END AS IsTeachingAssignment
from S275_Coalesced S275
JOIN Dim_Staff_Coalesced d ON
    d.AcademicYear = S275.AcademicYear
    AND d.Area = S275.Area
    AND d.CountyAndDistrictCode = S275.CountyAndDistrictCode
    AND d.LastNameC = S275.LastNameC
    AND d.FirstNameC = S275.FirstNameC
    AND d.MiddleNameC = S275.MiddleNameC
    AND d.CertificateNumberC = S275.CertificateNumberC
LEFT JOIN DutyCodes ON
    S275.DutyRoot = DutyCodes.DutyRoot
    AND (DutyCodes.DutySuffix IN ('x', 'y') OR DutyCodes.DutySuffix = S275.DutySuffix)
;

-- next

-- we don't need this anymore after this point
DROP TABLE S275_Coalesced;

-- next

DROP TABLE IF EXISTS Dim_Staff;

-- next

CREATE TABLE Dim_Staff (
    StaffID INT NOT NULL PRIMARY KEY,
    AcademicYear varchar(500) NULL,
    Area varchar(500) NULL,
    County varchar(500) NULL,
    District varchar(500) NULL,
    CountyAndDistrictCode varchar(500) NULL,
    LastName varchar(500) NULL,
    FirstName varchar(500) NULL,
    MiddleName varchar(500) NULL,
    CertificateNumber varchar(500) NULL,
    Birthdate varchar(500) NULL,
    Sex varchar(500) NULL,
    Hispanic varchar(500) NULL,
    Race varchar(500) NULL,
    RaceEthOSPI varchar(500) NULL,
    HighestDegree varchar(500) NULL,
    HighestDegreeYear varchar(500) NULL,
    AcademicCredits varchar(500) NULL,
    InServiceCredits varchar(500) NULL,
    ExcessCredits varchar(500) NULL,
    NonDegreeCredits varchar(500) NULL,
    CertYearsOfExperience varchar(500) NULL,
    StaffMixFactor varchar(500) NULL,
    FTEHours varchar(500) NULL,
    FTEDays varchar(500) NULL,
    CertificatedFTE varchar(500) NULL,
    ClassifiedFTE varchar(500) NULL,
    CertificatedBase varchar(500) NULL,
    ClassifiedBase varchar(500) NULL,
    OtherSalary varchar(500) NULL,
    TotalFinalSalary varchar(500) NULL,
    ActualAnnualInsurance varchar(500) NULL,
    ActualAnnualMandatory varchar(500) NULL,
    CBRTNCode varchar(500) NULL,
    ClassificationFlag varchar(500) NULL,
    CertifiedFlag varchar(500) NULL,
    NationalBoardCertExpirationDate varchar(500) NULL,
    IsTeacherFlag INT NOT NULL
);

-- next

INSERT INTO Dim_Staff (
    StaffID,
    AcademicYear,
    Area,
    County,
    District,
    CountyAndDistrictCode,
    LastName,
    FirstName,
    MiddleName,
    CertificateNumber,
    Birthdate,
    Sex,
    Hispanic,
    Race,
    RaceEthOSPI,
    HighestDegree,
    HighestDegreeYear,
    AcademicCredits,
    InServiceCredits,
    ExcessCredits,
    NonDegreeCredits,
    CertYearsOfExperience,
    StaffMixFactor,
    FTEHours,
    FTEDays,
    CertificatedFTE,
    ClassifiedFTE,
    CertificatedBase,
    ClassifiedBase,
    OtherSalary,
    TotalFinalSalary,
    ActualAnnualInsurance,
    ActualAnnualMandatory,
    CBRTNCode,
    ClassificationFlag,
    CertifiedFlag,
    NationalBoardCertExpirationDate,
    IsTeacherFlag
)
SELECT
    StaffID,
    AcademicYear,
    Area,
    County,
    District,
    CountyAndDistrictCode,
    LastName,
    FirstName,
    MiddleName,
    CertificateNumber,
    Birthdate,
    Sex,
    Hispanic,
    Race,
    CASE
            WHEN Hispanic = 'Y' THEN 'Hispanic/Latino of any race(s)'
            WHEN LEN(LTRIM(RTRIM(Race))) > 1 THEN 'Two or More Races'
            ELSE
                    CASE LTRIM(RTRIM(COALESCE(Race, '')))
                            WHEN 'A' THEN 'Asian'
                            WHEN 'W' THEN 'White'
                            WHEN 'B' THEN 'Black/African American'
                            WHEN 'P' THEN 'Native Hawaiian/Other Pacific Islander'
                            WHEN 'I' THEN 'American Indian/Alaskan Native'
                            WHEN '' THEN 'Not Provided'
                            ELSE NULL -- should never happen
                    END
    END AS RaceEthOSPI,
    HighestDegree,
    HighestDegreeYear,
    AcademicCredits,
    InServiceCredits,
    ExcessCredits,
    NonDegreeCredits,
    CertYearsOfExperience,
    StaffMixFactor,
    FTEHours,
    FTEDays,
    CertificatedFTE,
    ClassifiedFTE,
    CertificatedBase,
    ClassifiedBase,
    OtherSalary,
    TotalFinalSalary,
    ActualAnnualInsurance,
    ActualAnnualMandatory,
    CBRTNCode,
    ClassificationFlag,
    CertifiedFlag,
    NationalBoardCertExpirationDate,
    IsTeacherFlag
FROM Dim_Staff_Coalesced;

-- next

DROP TABLE Dim_Staff_Coalesced;

-- next

WITH grouped as (
    select
        s.StaffID,
        max(IsTeachingAssignment) as IsTeacherFlag
    FROM Dim_Staff s
    JOIN Fact_Assignment a ON s.StaffID = a.StaffID
    group by s.StaffID
)
UPDATE Dim_Staff
SET IsTeacherFlag = 1
WHERE EXISTS (
    select 1
    from grouped
    where StaffID = Dim_Staff.StaffID
    and IsTeacherFlag = 1);

-- next

-- we need this table for per-building rolled up fields, can't simply extend Fact_Assignment

DROP TABLE IF EXISTS Fact_SchoolTeacher;

-- next

CREATE TABLE Fact_SchoolTeacher (
    StaffID INT NOT NULL,
    AcademicYear INT NOT NULL,
    Building varchar(500) NULL,
    AssignmentPercent NUMERIC(14,4) NULL,
    AssignmentFTEDesignation NUMERIC(14,4) NULL,
    AssignmentSalaryTotal INT NULL
);

-- next

INSERT INTO Fact_SchoolTeacher (
    StaffID,
    AcademicYear,
    Building,
    AssignmentPercent,
    AssignmentFTEDesignation,
    AssignmentSalaryTotal
)
select
    a.StaffID
    ,a.AcademicYear
    ,Building
    ,COALESCE(SUM(AssignmentPercent), 0) AS AssignmentPercent
    ,SUM(AssignmentFTEDesignation) AS AssignmentFTEDesignation
    ,SUM(AssignmentSalaryTotal) AS AssignmentSalaryTotal
from Fact_Assignment a
JOIN Dim_Staff s ON a.StaffID = s.StaffID
WHERE IsTeachingAssignment = 1
GROUP BY
    a.StaffID
    ,a.AcademicYear
    ,Building
;

-- next

DELETE FROM Fact_SchoolTeacher
WHERE
    EXISTS (
        SELECT 1 from Dim_Staff
        WHERE StaffID = Fact_SchoolTeacher.StaffID
        AND (CertificateNumber IS NULL OR CertificateNumber = '')
    )
    OR AssignmentFTEDesignation IS NULL
    OR AssignmentFTEDesignation <= 0;

-- next

CREATE INDEX idx_Fact_SchoolTeacher ON Fact_SchoolTeacher (
    StaffID, AcademicYear
);

-- next

CREATE INDEX idx_Fact_SchoolTeacher2 ON Fact_SchoolTeacher (
    AcademicYear, StaffID
);
