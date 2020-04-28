
DROP TABLE IF EXISTS S275;

-- next

CREATE TABLE S275 (
    AcademicYear smallint NULL,
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
    MetaCreatedAt DATETIME
);

-- next

INSERT INTO S275 (
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
    Major,
    TwoDigitYear,
    FileType,
    MetaCreatedAt
)
SELECT
    -- only 2 digit 'yr' field was available in the file 1999-2000 AY and prior
    CASE
        WHEN SchoolYear IS NOT NULL
        THEN SUBSTRING(SchoolYear, 6, 4)
        ELSE cast(
            cast('19' + cast(yr as varchar) as int)-- sqlite_concat
            + 1 as varchar)
    END as SchoolYear
    ,area as Area
    ,cou as County
    ,dis as District
    -- pre-2011 tables don't have a codist field, so populate it
    ,CASE
        WHEN codist IS NULL
        THEN CAST(cou as VARCHAR) + CAST(dis as VARCHAR) -- sqlite_concat
        ELSE codist
    END as CountyAndDistrictCode
    ,CASE WHEN lname IS NOT NULL THEN lname ELSE LastName END as LastName
    ,CASE WHEN lname IS NOT NULL THEN fname ELSE FirstName END as FirstName
    ,CASE WHEN lname IS NOT NULL THEN mname ELSE MiddleName END as MiddleName
    ,cert as CertificateNumber
    ,CASE
        WHEN
            bdate IS NULL AND byr IS NOT NULL AND LEN(byr) > 1 AND NOT (byr = '00' AND  bmo = '00' and bday = '00')
        THEN
            '19' + CAST(byr as varchar) + '-'  -- sqlite_concat
            + CASE WHEN LEN(bmo) = 1 THEN '0' ELSE '' END + CAST(bmo as varchar) + '-' -- sqlite_concat
            + CASE WHEN LEN(bday) = 1 THEN '0' ELSE '' END + CAST(bday as varchar) + ' 00:00:00' -- sqlite_concat
        ELSE bdate
    END as Birthdate
    ,sex as Sex
    ,ethnic as Ethnicity
    ,hispanic as Hispanic
    ,race as Race
    ,hdeg as HighestDegree
    ,CASE
        -- AY 1996 (yr=95) has 2 digit years, so we can safely assume they're in 20th century
        WHEN yr = '95' AND LEN(hyear) = 2 AND hyear <> '00' THEN '19' + hyear -- sqlite_concat
        WHEN hyear = 'B0' THEN NULL
        WHEN hyear = '07' THEN '2007'
        WHEN hyear = '13' THEN '2013'
        WHEN hyear = '19' THEN '2019'
        WHEN UNICODE(hyear) = 0 THEN NULL -- 4 rows with weird NUL ascii chars?!
        ELSE hyear
    END as HighestDegreeYear
    ,acred as AcademicCredits
    ,icred as InServiceCredits
    ,bcred as ExcessCredits
    ,vcred as NonDegreeCredits
    ,exp as CertYearsOfExperience
    ,camix as StaffMixFactor
    ,camix1 as StaffMixFactor1
    ,camix1A as StaffMixFactor1A
    ,camix1S as StaffMixFactor1S
    ,camix1Sa as StaffMixFactor1Sa
    ,camix1SB as StaffMixFactor1SB
    ,ftehrs as FTEHours
    ,ftedays as FTEDays
    ,certfte as CertificatedFTE
    ,clasfte as ClassifiedFTE
    ,certbase as CertificatedBase
    ,clasbase as ClassifiedBase
    ,othersal as OtherSalary
    ,tfinsal as TotalFinalSalary
    ,cins as ActualAnnualInsurance
    ,cman as ActualAnnualMandatory
    ,cbrtn as CBRTNCode
    ,clasflag as ClassificationFlag
    ,certflag as CertifiedFlag
    ,NBcertexpdate as NationalBoardCertExpirationDate
    ,recno as RecordNumber
    ,prog as ProgramCode
    ,act as ActivityCode
    ,darea as DutyArea
    ,droot as DutyRoot
    ,dsufx as DutySuffix
    ,grade as Grade
    ,bldgn as Building
    ,asspct as AssignmentPercent
    ,assfte as AssignmentFTEDesignation
    ,asssal as AssignmentSalaryTotal
    ,asshpy as AssignmentHoursPerYear
    ,major as Major
    ,yr as TwoDigitYear
    ,FileType
    ,GETDATE() as MetaCreatedAt
FROM Raw_S275;

-- next

-- numeric fields in AY <= 2000 were stored as integers; convert them to decimal values
UPDATE S275
SET
    CertYearsOfExperience = CAST((CAST(CertYearsOfExperience as real) / 10) as varchar)
    ,CertificatedFTE = CAST((CAST(CertificatedFTE as real) / 1000) as varchar)
    ,ClassifiedFTE = CAST((CAST(ClassifiedFTE as real) / 1000) as varchar)
    ,AssignmentPercent = CAST((CAST(AssignmentPercent as real) / 10) as varchar)
    ,AssignmentFTEDesignation = CAST((CAST(AssignmentFTEDesignation as real) / 1000) as varchar)
    ,AssignmentHoursPerYear = CAST((CAST(AssignmentHoursPerYear as real) / 100) as varchar)
WHERE CAST(AcademicYear as int) <= 2000

-- next

-- Fix invalid birthdate
UPDATE S275
SET Birthdate = '1946-02-28 00:00:00'
WHERE Birthdate = '1946-02-29 00:00:00' AND AcademicYear = 1997;

-- next

-- delete one 'staff' group when a person has 2 (duplicate) 'staff' entries, each with its own set of assignments.
-- usually, the tfinsal field is different for mysterious reasons; we filter one of them out here.

DELETE FROM S275
WHERE
    (AcademicYear = '1996' AND CertificateNumber = '336200A' and TotalFinalSalary = 25809)
    OR (AcademicYear = '1996' AND CertificateNumber = '313671J' and TotalFinalSalary = 36936)
    OR (AcademicYear = '1996' AND CertificateNumber = '180264D' and TotalFinalSalary = 23764)
    OR (AcademicYear = '1996' AND CertificateNumber = '254690A' and ActualAnnualMandatory = 15776)
    OR (AcademicYear = '1996' AND CertificateNumber = '319100D' and TotalFinalSalary = 17813)

    OR (AcademicYear = '1997' AND CertificateNumber = '244870B' and TotalFinalSalary = 43236)
    OR (AcademicYear = '1997' AND CertificateNumber = '319527H' and TotalFinalSalary = 27774)
    OR (AcademicYear = '1997' AND CertificateNumber = '267008A' and TotalFinalSalary = 31675)

    -- filter out the group with no ethnicity value
    OR (AcademicYear = '1999' AND CertificateNumber = '365096G' and Ethnicity IS NULL)

    OR (AcademicYear = '2001' AND LastName = 'PETTY' and FirstName = 'JENNY' and MiddleName = 'ELIZABETH' and TotalFinalSalary = 13422)
    OR (AcademicYear = '2001' and LastName = 'DELOACH' and FirstName = 'JEFFERY' and MiddleName = 'D' and TotalFinalSalary = 5787)
    OR (AcademicYear = '2001' and LastName = 'BROWNE' and FirstName = 'RAYETTA' and MiddleName = 'S.' and TotalFinalSalary = 11516)
    OR (AcademicYear = '2001' and LastName = 'SHARR' and FirstName = 'TEDDY' and MiddleName = 'M' and TotalFinalSalary = 41539)
    OR (AcademicYear = '2001' and LastName = 'NELSON' and FirstName = 'DAPHNE' and MiddleName = 'R' and TotalFinalSalary = 31257)
    OR (AcademicYear = '2001' and LastName = 'DOCKERY' and FirstName = 'JOSEPH' and MiddleName = 'C.' and TotalFinalSalary = 50082)
    OR (AcademicYear = '2001' and LastName = 'HERMAN' and FirstName = 'MARIAN' and MiddleName = 'JEAN' and TotalFinalSalary = 12088)
    OR (AcademicYear = '2001' and LastName = 'DITH' and FirstName = 'SAKHAN' and TotalFinalSalary = 28252)
    OR (AcademicYear = '2001' and LastName = 'RUSSELL' and FirstName = 'PATRICK' and MiddleName = 'R' and TotalFinalSalary = 3605)
    OR (AcademicYear = '2001' and LastName = 'NAVARRETTE' and FirstName = 'KATHLEEN' and MiddleName = 'M' and TotalFinalSalary = 11790)
    OR (AcademicYear = '2001' and LastName = 'JOHNSON' and FirstName = 'CHRISTOPHER' and MiddleName = 'J.' and TotalFinalSalary = 5292)
    OR (AcademicYear = '2001' and LastName = 'CARNEY' and FirstName = 'SEAN' and MiddleName = 'TODD' and TotalFinalSalary = 31193)
    OR (AcademicYear = '2001' and LastName = 'HODGES' and FirstName = 'ROBIN' and MiddleName = 'L' and HighestDegreeYear = '1900')
    OR (AcademicYear = '2001' and LastName = 'POWELL' and FirstName = 'DAVID' and MiddleName = 'KENNETH' and TotalFinalSalary = 49355)
    OR (AcademicYear = '2001' and LastName = 'HORNE' and FirstName = 'ERICA' and MiddleName = 'L.' and HighestDegreeYear = '1915')
    OR (AcademicYear = '2001' and LastName = 'COX' and FirstName = 'LISA' and MiddleName = 'ANN' and HighestDegreeYear = '1915')
    OR (AcademicYear = '2001' and LastName = 'ORTIZ' and FirstName = 'JUAN' and MiddleName = 'R' and TotalFinalSalary = 9330)
    OR (AcademicYear = '2001' and LastName = 'AMES' and FirstName = 'H.' and MiddleName = 'NORMAN' and TotalFinalSalary = 34610)

    OR (AcademicYear = '2002' and CertificateNumber = '393926A' and TotalFinalSalary = 65000)

    OR (AcademicYear = '2004' and LastName = 'MARTINEZ' and FirstName = 'RANDALL' and MiddleName = 'L' and TotalFinalSalary = 5830)
    OR (AcademicYear = '2004' and CertificateNumber = '387894R' and TotalFinalSalary = 20479)
    OR (AcademicYear = '2004' and CertificateNumber = '253579G' and TotalFinalSalary = 90128)

    OR (AcademicYear = '2005' and CertificateNumber = '418549B' and TotalFinalSalary = 56863)

    OR (AcademicYear = '2006' and CertificateNumber = '377014F' and TotalFinalSalary = 43382)

    OR (AcademicYear = '2007' and CertificateNumber = '437767G' and TotalFinalSalary = 43949)
    OR (AcademicYear = '2007' AND CertificateNumber = '369842J' and TotalFinalSalary = 45634)
    OR (AcademicYear = '2007' AND CertificateNumber = '420978R' and TotalFinalSalary = 41553)

    OR (AcademicYear = '2009' and CertificateNumber = '466137G' and TotalFinalSalary = 39200)
;