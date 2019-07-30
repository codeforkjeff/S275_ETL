
DROP TABLE IF EXISTS TeacherAssignments;

-- next

CREATE TABLE TeacherAssignments (
    AcademicYear varchar(500) NULL,
    Area varchar(500) NULL,
    County varchar(500) NULL,
    DistrictCode varchar(500) NULL,
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
    ActivityCode varchar(500) NULL,
    Building varchar(500) NULL,
    AssignmentPercent NUMERIC(14,4) NULL,
    AssignmentFTEDesignation NUMERIC(14,4) NULL,
    AssignmentSalaryTotal INT NULL
);

-- next

INSERT INTO TeacherAssignments (
    AcademicYear
    ,Area
    ,County
    ,DistrictCode
    ,CountyAndDistrictCode
    ,LastName
    ,FirstName
    ,MiddleName
    ,CertificateNumber
    ,Birthdate
    ,Sex
    ,Hispanic
    ,Race
    ,RaceEthOSPI
    ,HighestDegree
    ,HighestDegreeYear
    ,AcademicCredits
    ,InServiceCredits
    ,ExcessCredits
    ,NonDegreeCredits
    ,CertYearsOfExperience
    ,StaffMixFactor
    ,FTEHours
    ,FTEDays
    ,CertificatedFTE
    ,ClassifiedFTE
    ,CertificatedBase
    ,ClassifiedBase
    ,OtherSalary
    ,TotalFinalSalary
    ,ActualAnnualInsurance
    ,ActualAnnualMandatory
    ,CBRTNCode
    ,ClassificationFlag
    ,CertifiedFlag
    ,ActivityCode
    ,Building
    ,AssignmentPercent
    ,AssignmentFTEDesignation
    ,AssignmentSalaryTotal
)
SELECT
    AcademicYear
    ,Area
    ,County
    ,DistrictCode
    ,CountyAndDistrictCode
    ,LastName
    ,FirstName
    ,MiddleName
    ,CertificateNumber
    ,Birthdate
    ,Sex
    ,Hispanic
    ,Race
    ,RaceEthOSPI
    ,HighestDegree
    ,HighestDegreeYear
    ,AcademicCredits
    ,InServiceCredits
    ,ExcessCredits
    ,NonDegreeCredits
    ,CertYearsOfExperience
    ,StaffMixFactor
    ,FTEHours
    ,FTEDays
    ,CertificatedFTE
    ,ClassifiedFTE
    ,CertificatedBase
    ,ClassifiedBase
    ,OtherSalary
    ,TotalFinalSalary
    ,ActualAnnualInsurance
    ,ActualAnnualMandatory
    ,CBRTNCode
    ,ClassificationFlag
    ,CertifiedFlag
    ,ActivityCode
    ,Building
    ,AssignmentPercent = COALESCE(AssignmentPercent, 0)
    ,AssignmentFTEDesignation
    ,AssignmentSalaryTotal
FROM TeacherAssignmentsAll
WHERE
    CertificateNumber IS NOT NULL
    AND CertificateNumber <> ''
    AND AssignmentFTEDesignation > 0
