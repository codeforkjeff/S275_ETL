DROP TABLE IF EXISTS Dim_Staff;

-- next

CREATE TABLE Dim_Staff (
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

INSERT INTO Dim_Staff (
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
FROM S275 t;

-- next

CREATE UNIQUE INDEX idx_Dim_Staff ON Dim_Staff (
    AcademicYear,
    Area,
    CountyAndDistrictCode,
    LastName,
    FirstName,
    MiddleName,
    CertificateNumber,
    Birthdate
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
    DutyRoot,
    DutySuffix,
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
        DutyRoot IN ('31','32','33','34')
        AND ActivityCode ='27'
        AND S275.Area = 'L'
    THEN 1 ELSE 0 END AS IsTeachingAssignment
from S275
JOIN Dim_Staff ON
    Dim_Staff.AcademicYear = S275.AcademicYear
    AND Dim_Staff.Area = S275.Area
    AND Dim_Staff.CountyAndDistrictCode = S275.CountyAndDistrictCode
    AND Dim_Staff.LastName = S275.LastName
    AND Dim_Staff.FirstName = S275.FirstName
    AND COALESCE(Dim_Staff.MiddleName, '') = COALESCE(S275.MiddleName, '')
    AND Dim_Staff.CertificateNumber = S275.CertificateNumber
    AND COALESCE(Dim_Staff.Birthdate, '') = COALESCE(S275.Birthdate, '')
;

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

-- we need this table for rollups

DROP TABLE IF EXISTS Fact_Teacher;

-- next

CREATE TABLE Fact_Teacher (
    StaffID INT NOT NULL,
    AcademicYear INT NOT NULL,
    ActivityCode varchar(500) NULL,
    Building varchar(500) NULL,
    AssignmentPercent NUMERIC(14,4) NULL,
    AssignmentFTEDesignation NUMERIC(14,4) NULL,
    AssignmentSalaryTotal INT NULL
);

-- next

INSERT INTO Fact_Teacher (
    StaffID,
    AcademicYear,
    ActivityCode,
    Building,
    AssignmentPercent,
    AssignmentFTEDesignation,
    AssignmentSalaryTotal
)
select
    a.StaffID
    ,a.AcademicYear
    ,ActivityCode
    ,Building
    ,SUM(AssignmentPercent) AS AssignmentPercent
    ,SUM(AssignmentFTEDesignation) AS AssignmentFTEDesignation
    ,SUM(AssignmentSalaryTotal) AS AssignmentSalaryTotal
from Fact_Assignment a
JOIN Dim_Staff s ON a.StaffID = s.StaffID
WHERE IsTeachingAssignment = 1
GROUP BY
    a.StaffID
    ,a.AcademicYear
    ,ActivityCode
    ,Building
;

-- next

DELETE FROM Fact_Teacher
WHERE
    EXISTS (
        SELECT 1 from Dim_Staff
        WHERE StaffID = Fact_Teacher.StaffID
        AND (CertificateNumber IS NULL OR CertificateNumber = '')
    )
    OR AssignmentFTEDesignation IS NULL
    OR AssignmentFTEDesignation <= 0;

-- next

CREATE INDEX idx_Fact_Teacher ON Fact_Teacher (
    StaffID, AcademicYear
);

-- next

CREATE INDEX idx_Fact_Teacher2 ON Fact_Teacher (
    AcademicYear, StaffID
);
