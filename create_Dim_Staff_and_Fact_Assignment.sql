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
    Ethnicity varchar(500) NULL,
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
    StaffMixFactor1 varchar(500) NULL,
    StaffMixFactor1A varchar(500) NULL,
    StaffMixFactor1S varchar(500) NULL,
    StaffMixFactor1Sa varchar(500) NULL,
    StaffMixFactor1SB varchar(500) NULL,
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
    MetaCreatedAt DATETIME,
    -- coalesced fields
    LastNameC varchar(500) NULL,
    FirstNameC varchar(500) NULL,
    MiddleNameC varchar(500) NULL,
    CertificateNumberC varchar(500) NULL,
    BirthdateC varchar(500) NULL
);

-- next

-- some rows in 1996 have empty name fields but birthdate differs, so include birthdate in the key
INSERT INTO S275_Coalesced
SELECT
    *,
    COALESCE(LastName, '') AS LastNameC,
    COALESCE(FirstName, '') AS FirstNameC,
    COALESCE(MiddleName, '') AS MiddleNameC,
    COALESCE(CertificateNumber, '') AS CertificateNumberC,
    COALESCE(Birthdate, '') AS BirthdateC
FROM S275;

-- next

DROP TABLE IF EXISTS Dim_Staff_Coalesced;

-- next

-- sqlite doesn't support alter table drop column,
-- so create this intermediate table
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
    BirthdateC varchar(500) NULL,
    --
    Birthdate varchar(500) NULL,
    Sex varchar(500) NULL,
    Ethnicity varchar(500) NULL,
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
    StaffMixFactor1 varchar(500) NULL,
    StaffMixFactor1A varchar(500) NULL,
    StaffMixFactor1S varchar(500) NULL,
    StaffMixFactor1Sa varchar(500) NULL,
    StaffMixFactor1SB varchar(500) NULL,
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
    FileType varchar(500) NULL
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
    BirthdateC,
    --
    Birthdate,
    Sex,
    Ethnicity,
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
    StaffMixFactor1,
    StaffMixFactor1A,
    StaffMixFactor1S,
    StaffMixFactor1Sa,
    StaffMixFactor1SB,
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
    FileType
)
SELECT DISTINCT
    -- all these fields should, theoretically, be distinct to the combo key of AY/names/certnum/birthdate field.
    -- if they aren't, it suggests problems in the source data.
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
    BirthdateC,
    --
    Birthdate,
    Sex,
    Ethnicity,
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
    StaffMixFactor1,
    StaffMixFactor1A,
    StaffMixFactor1S,
    StaffMixFactor1Sa,
    StaffMixFactor1SB,
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
    FileType
FROM S275_Coalesced t;

-- next

-- creating this index fails when there are 'dupe' staff entries
-- (each with their own set of assignments). these cases occurred
-- in earlier years (from 1996 to 2001); they should have been removed
-- prior to the S275 table being loaded, so that this index can be
-- succesfully created.
CREATE UNIQUE INDEX idx_Dim_Staff_Coalesced ON Dim_Staff_Coalesced (
    AcademicYear,
    Area,
    CountyAndDistrictCode,
    LastNameC,
    FirstNameC,
    MiddleNameC,
    CertificateNumberC,
    BirthdateC,
    -- add staffid to make this a covering index
    StaffID
);

-- next

DROP TABLE IF EXISTS Fact_Assignment;

-- next

CREATE TABLE Fact_Assignment (
    AssignmentID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
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
    FileType varchar(500) NULL,
    IsTeachingAssignment INT NOT NULL,
    IsAdministrativeAssignment INT NOT NULL,
    IsPrincipalAssignment INT NOT NULL,
    IsAsstPrincipalAssignment INT NOT NULL,
    MetaCreatedAt DATETIME
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
    FileType,
    IsTeachingAssignment,
    IsAdministrativeAssignment,
    IsPrincipalAssignment,
    IsAsstPrincipalAssignment,
    MetaCreatedAt
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
    S275.FileType,
    CASE WHEN
        CAST(S275.DutyRoot as integer) IN (31, 32, 33, 34)
        AND ActivityCode ='27'
        AND S275.Area = 'L'
    THEN 1 ELSE 0 END AS IsTeachingAssignment,
    CASE WHEN
        CAST(S275.DutyRoot as integer) >= 11 AND CAST(S275.DutyRoot as integer) <= 25
    THEN 1 ELSE 0 END AS IsAdministrativeAssignment,
    CASE WHEN
        CAST(S275.DutyRoot as integer) = 21 OR CAST(S275.DutyRoot as integer) = 23
    THEN 1 ELSE 0 END AS IsPrincipalAssignment,
    CASE WHEN
        CAST(S275.DutyRoot as integer) = 22 OR CAST(S275.DutyRoot as integer) = 24
    THEN 1 ELSE 0 END AS IsAsstPrincipalAssignment,
    GETDATE() as MetaCreatedAt
from S275_Coalesced S275
JOIN Dim_Staff_Coalesced d ON
    d.AcademicYear = S275.AcademicYear
    AND d.Area = S275.Area
    AND d.CountyAndDistrictCode = S275.CountyAndDistrictCode
    AND d.LastNameC = S275.LastNameC
    AND d.FirstNameC = S275.FirstNameC
    AND d.MiddleNameC = S275.MiddleNameC
    AND d.CertificateNumberC = S275.CertificateNumberC
    AND d.BirthdateC = S275.BirthdateC
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
    AcademicYear INT NOT NULL,
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
    Ethnicity varchar(500) NULL,
    Hispanic varchar(500) NULL,
    Race varchar(500) NULL,
    RaceEthOSPI varchar(500) NULL,
    HighestDegree varchar(500) NULL,
    HighestDegreeYear varchar(500) NULL,
    AcademicCredits varchar(500) NULL,
    InServiceCredits varchar(500) NULL,
    ExcessCredits varchar(500) NULL,
    NonDegreeCredits varchar(500) NULL,
    CertYearsOfExperience real null,
    StaffMixFactor varchar(500) NULL,
    StaffMixFactor1 varchar(500) NULL,
    StaffMixFactor1A varchar(500) NULL,
    StaffMixFactor1S varchar(500) NULL,
    StaffMixFactor1Sa varchar(500) NULL,
    StaffMixFactor1SB varchar(500) NULL,
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
    FileType varchar(500) NULL,
    IsTeacherFlag INT NOT NULL,
    IsNoviceTeacherFlag INT NOT NULL,
    IsPrincipalFlag INT NOT NULL,
    IsAsstPrincipalFlag INT NOT NULL,
    IsNationalBoardCertified INT NOT NULL,
    TempOrPermCert varchar(1) NULL,
    IsNewHireFlag INT NOT NULL,
    MetaCreatedAt DATETIME
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
    Ethnicity,
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
    StaffMixFactor1,
    StaffMixFactor1A,
    StaffMixFactor1S,
    StaffMixFactor1Sa,
    StaffMixFactor1SB,
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
    IsTeacherFlag,
    IsNoviceTeacherFlag,
    IsPrincipalFlag,
    IsAsstPrincipalFlag,
    IsNationalBoardCertified,
    IsNewHireFlag,
    MetaCreatedAt
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
    Ethnicity,
    Hispanic,
    Race,
    CASE
        WHEN Ethnicity IS NOT NULL THEN
            CASE UPPER(Ethnicity)
                -- note that there is no P code for Pacific Islander in this field
                WHEN 'A' THEN 'Asian'
                WHEN 'W' THEN 'White'
                WHEN 'B' THEN 'Black/African American'
                WHEN 'H' THEN 'Hispanic/Latino of any race(s)'
                WHEN 'I' THEN 'American Indian/Alaskan Native'
                ELSE 'Unknown' -- should never happen
            END
        ELSE
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
    StaffMixFactor1,
    StaffMixFactor1A,
    StaffMixFactor1S,
    StaffMixFactor1Sa,
    StaffMixFactor1SB,
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
    0 AS IsTeacherFlag,
    0 AS IsNoviceTeacherFlag,
    0 AS IsPrincipalFlag,
    0 AS IsAsstPrincipalFlag,
    0 AS IsNationalBoardCertified,
    0 AS IsNewHireFlag,
    GETDATE() as MetaCreatedAt
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

UPDATE Dim_Staff
SET IsNoviceTeacherFlag = 1
WHERE
    IsTeacherFlag = 1
    AND CertYearsOfExperience < 2.0;

-- next

WITH grouped as (
    select
        s.StaffID,
        max(IsPrincipalAssignment) as IsPrincipalFlag
    FROM Dim_Staff s
    JOIN Fact_Assignment a ON s.StaffID = a.StaffID
    group by s.StaffID
)
UPDATE Dim_Staff
SET IsPrincipalFlag = 1
WHERE EXISTS (
    select 1
    from grouped
    where StaffID = Dim_Staff.StaffID
    and IsPrincipalFlag = 1);

-- next

WITH grouped as (
    select
        s.StaffID,
        max(IsAsstPrincipalAssignment) as IsAsstPrincipalFlag
    FROM Dim_Staff s
    JOIN Fact_Assignment a ON s.StaffID = a.StaffID
    group by s.StaffID
)
UPDATE Dim_Staff
SET IsAsstPrincipalFlag = 1
WHERE EXISTS (
    select 1
    from grouped
    where StaffID = Dim_Staff.StaffID
    and IsAsstPrincipalFlag = 1);

-- next

UPDATE Dim_Staff
SET IsNationalBoardCertified = 1
WHERE
    SUBSTRING(NationalBoardCertExpirationDate, 1, 7) >=
    (CAST((AcademicYear - 1) as varchar) + '-09'); -- sqlite_concat

-- next

DROP TABLE IF EXISTS FirstYearInDistrict;

-- next

CREATE TABLE FirstYearInDistrict (
    CertificateNumber varchar(500) NULL,
    CountyAndDistrictCode varchar(500) NULL,
    FirstYear INT NULL
);

-- next

INSERT INTO FirstYearInDistrict
SELECT
    CertificateNumber,
    CountyAndDistrictCode,
    MIN(AcademicYear) AS FirstYear
FROM Dim_Staff
WHERE CertificateNumber is not null
GROUP BY
    CertificateNumber,
    CountyAndDistrictCode;

-- next

CREATE INDEX idx_FirstYearInDistrict ON FirstYearInDistrict (
    CertificateNumber,
    CountyAndDistrictCode,
    FirstYear
);

-- next

UPDATE Dim_Staff
SET IsNewHireFlag = 1
WHERE
    EXISTS (
        SELECT 1
        FROM FirstYearInDistrict
        WHERE FirstYearInDistrict.CertificateNumber = Dim_Staff.CertificateNumber
        AND FirstYearInDistrict.CountyAndDistrictCode = Dim_Staff.CountyAndDistrictCode
        AND FirstYearInDistrict.FirstYear = Dim_Staff.AcademicYear
    );

-- next

DROP TABLE FirstYearInDistrict;

-- next

UPDATE Dim_Staff
SET TempOrPermCert = CASE WHEN CertificateNumber LIKE 'Z%' THEN 'T' ELSE 'P' END
WHERE
    CertificateNumber IS NOT NULL;

