
DROP TABLE IF EXISTS TeacherAssignmentsAll;

-- next

CREATE TABLE TeacherAssignmentsAll (
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

INSERT INTO TeacherAssignmentsAll (
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
    ,
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
    END AS RaceEthOSPI
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
    ,SUM(AssignmentPercent) AS AssignmentPercent
    ,SUM(AssignmentFTEDesignation) AS AssignmentFTEDesignation
    ,SUM(AssignmentSalaryTotal) AS AssignmentSalaryTotal
FROM Teachers
GROUP BY
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
