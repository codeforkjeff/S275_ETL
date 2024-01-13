
WITH Base AS (
SELECT
    -- only 2 digit 'yr' field was available in the file 1999-2000 AY and prior
    CAST(CASE
        WHEN SchoolYear IS NOT NULL
        THEN {{ substring_fname() }}(SchoolYear, 6, 4)
        ELSE cast(
            cast(
            {% call concat() %}
            '19' + cast(yr as {{ t_varchar() }}) -- sqlite_concat
            {% endcall %}
            as {{ t_int() }})
            + 1 as {{ t_varchar() }})
    END AS {{ t_int() }}) as AcademicYear
    ,area as Area
    ,cou as County
    ,dis as District
    -- pre-2011 tables don't have a codist field, so populate it
    ,CASE
        WHEN codist IS NULL
        THEN
            {% call concat() %}
            CAST(cou as {{ t_varchar() }}) + CAST(dis as {{ t_varchar() }}) -- sqlite_concat
            {% endcall %}
        ELSE codist
    END as CountyAndDistrictCode
    ,CASE WHEN lname IS NOT NULL THEN lname ELSE LastName END as LastName
    ,CASE WHEN lname IS NOT NULL THEN fname ELSE FirstName END as FirstName
    ,CASE WHEN lname IS NOT NULL THEN mname ELSE MiddleName END as MiddleName
    ,cert as CertificateNumber
    ,CASE
        WHEN
            bdate IS NULL AND byr IS NOT NULL AND {{ len_fname() }}(byr) > 1 AND NOT (byr = '00' AND  bmo = '00' and bday = '00')
        THEN
            {% call concat() %}
            '19' + CAST(byr as {{ t_varchar() }}) + '-'  -- sqlite_concat
            + CASE WHEN {{ len_fname() }}(bmo) = 1 THEN '0' ELSE '' END + CAST(bmo as {{ t_varchar() }}) + '-' -- sqlite_concat
            + CASE WHEN {{ len_fname() }}(bday) = 1 THEN '0' ELSE '' END + CAST(bday as {{ t_varchar() }}) + ' 00:00:00' -- sqlite_concat
            {% endcall %}
        ELSE bdate
    END as Birthdate
    ,sex as Sex
    ,ethnic as Ethnicity
    ,hispanic as Hispanic
    -- deduplicate race codes which happens in some years. e.g. 'WW'
    ,{% call concat() %}
        CASE WHEN race LIKE '%A%' THEN 'A' ELSE '' END +
        CASE WHEN race LIKE '%W%' THEN 'W' ELSE '' END +
        CASE WHEN race LIKE '%B%' THEN 'B' ELSE '' END +
        CASE WHEN race LIKE '%H%' THEN 'H' ELSE '' END +
        CASE WHEN race LIKE '%P%' THEN 'P' ELSE '' END +
        CASE WHEN race LIKE '%I%' THEN 'I' ELSE '' END
    {% endcall %} as Race
    ,hdeg as HighestDegree
    ,CASE
        -- AY 1996 (yr=95) has 2 digit years, so we can safely assume they're in 20th century
        WHEN yr = '95' AND {{ len_fname() }}(hyear) = 2 AND hyear <> '00' THEN {% call concat() %} '19' + hyear {% endcall %} -- sqlite_concat
        WHEN hyear = 'B0' THEN NULL
        WHEN hyear = '07' THEN '2007'
        WHEN hyear = '13' THEN '2013'
        WHEN hyear = '19' THEN '2019'
        -- WHEN UNICODE(hyear) = 0 THEN NULL -- 4 rows with weird NUL ascii chars?!
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
FROM {{ source('sources', 'Raw_S275') }}
)
,Cleaned1 AS (
    -- some numeric fields in AY <= 2000 were stored as integers; convert them to decimal values
    SELECT
        AcademicYear,
        Area,
        County,
        District,
        CountyAndDistrictCode,
        LastName,
        FirstName,
        MiddleName,
        CertificateNumber,
        -- fix invalid birthdate
        CASE
            WHEN Birthdate = '1946-02-29 00:00:00' AND AcademicYear = 1997 THEN '1946-02-28 00:00:00'
            ELSE Birthdate
        END AS Birthdate,
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
        CASE
            WHEN AcademicYear <= 2000
            THEN CAST((CAST(CertYearsOfExperience as {{ t_real() }}) / 10) as {{ t_varchar() }})
            ELSE CertYearsOfExperience
        END AS CertYearsOfExperience,
        StaffMixFactor,
        StaffMixFactor1,
        StaffMixFactor1A,
        StaffMixFactor1S,
        StaffMixFactor1Sa,
        StaffMixFactor1SB,
        FTEHours,
        FTEDays,
        CASE
            WHEN AcademicYear <= 2000
            THEN CAST((CAST(CertificatedFTE as {{ t_real() }}) / 1000) as {{ t_varchar() }})
            ELSE CertificatedFTE
        END AS CertificatedFTE,
        CASE
            WHEN AcademicYear <= 2000
            THEN CAST((CAST(ClassifiedFTE as {{ t_real() }}) / 1000) as {{ t_varchar() }})
            ELSE ClassifiedFTE
        END AS ClassifiedFTE,
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
        CASE
            WHEN AcademicYear <= 2000
            THEN CAST((CAST(AssignmentPercent as {{ t_real() }}) / 10) as {{ t_varchar() }})
            ELSE AssignmentPercent
        END AS AssignmentPercent,
        CASE
            WHEN AcademicYear <= 2000
            THEN CAST((CAST(AssignmentFTEDesignation as {{ t_real() }}) / 1000) as {{ t_varchar() }})
            ELSE AssignmentFTEDesignation
        END AS AssignmentFTEDesignation,
        AssignmentSalaryTotal,
        CASE
            WHEN AcademicYear <= 2000
            THEN CAST((CAST(AssignmentHoursPerYear as {{ t_real() }}) / 100) as {{ t_varchar() }})
            ELSE AssignmentHoursPerYear
        END AS AssignmentHoursPerYear,
        Major,
        TwoDigitYear,
        FileType
    FROM Base
)
,Cleaned2 AS (
    SELECT
        *
    FROM Cleaned1
    WHERE NOT (
        (AcademicYear = 1996 AND CertificateNumber = '336200A' and TotalFinalSalary = '25809')
        OR (AcademicYear = 1996 AND CertificateNumber = '313671J' and TotalFinalSalary = '36936')
        OR (AcademicYear = 1996 AND CertificateNumber = '180264D' and TotalFinalSalary = '23764')
        OR (AcademicYear = 1996 AND CertificateNumber = '254690A' and ActualAnnualMandatory = '15776')
        OR (AcademicYear = 1996 AND CertificateNumber = '319100D' and TotalFinalSalary = '17813')

        OR (AcademicYear = 1997 AND CertificateNumber = '244870B' and TotalFinalSalary = '43236')
        OR (AcademicYear = 1997 AND CertificateNumber = '319527H' and TotalFinalSalary = '27774')
        OR (AcademicYear = 1997 AND CertificateNumber = '267008A' and TotalFinalSalary = '31675')

        -- filter out the group with no ethnicity value
        OR (AcademicYear = 1999 AND CertificateNumber = '365096G' and Ethnicity IS NULL)

        OR (AcademicYear = 2001 AND LastName = 'PETTY' and FirstName = 'JENNY' and MiddleName = 'ELIZABETH' and TotalFinalSalary = '13422')
        OR (AcademicYear = 2001 and LastName = 'DELOACH' and FirstName = 'JEFFERY' and MiddleName = 'D' and TotalFinalSalary = '5787')
        OR (AcademicYear = 2001 and LastName = 'BROWNE' and FirstName = 'RAYETTA' and MiddleName = 'S.' and TotalFinalSalary = '11516')
        OR (AcademicYear = 2001 and LastName = 'SHARR' and FirstName = 'TEDDY' and MiddleName = 'M' and TotalFinalSalary = '41539')
        OR (AcademicYear = 2001 and LastName = 'NELSON' and FirstName = 'DAPHNE' and MiddleName = 'R' and TotalFinalSalary = '31257')
        OR (AcademicYear = 2001 and LastName = 'DOCKERY' and FirstName = 'JOSEPH' and MiddleName = 'C.' and TotalFinalSalary = '50082')
        OR (AcademicYear = 2001 and LastName = 'HERMAN' and FirstName = 'MARIAN' and MiddleName = 'JEAN' and TotalFinalSalary = '12088')
        OR (AcademicYear = 2001 and LastName = 'DITH' and FirstName = 'SAKHAN' and TotalFinalSalary = '28252')
        OR (AcademicYear = 2001 and LastName = 'RUSSELL' and FirstName = 'PATRICK' and MiddleName = 'R' and TotalFinalSalary = '3605')
        OR (AcademicYear = 2001 and LastName = 'NAVARRETTE' and FirstName = 'KATHLEEN' and MiddleName = 'M' and TotalFinalSalary = '11790')
        OR (AcademicYear = 2001 and LastName = 'JOHNSON' and FirstName = 'CHRISTOPHER' and MiddleName = 'J.' and TotalFinalSalary = '5292')
        OR (AcademicYear = 2001 and LastName = 'CARNEY' and FirstName = 'SEAN' and MiddleName = 'TODD' and TotalFinalSalary = '31193')
        OR (AcademicYear = 2001 and LastName = 'HODGES' and FirstName = 'ROBIN' and MiddleName = 'L' and HighestDegreeYear = '1900')
        OR (AcademicYear = 2001 and LastName = 'POWELL' and FirstName = 'DAVID' and MiddleName = 'KENNETH' and TotalFinalSalary = '49355')
        OR (AcademicYear = 2001 and LastName = 'HORNE' and FirstName = 'ERICA' and MiddleName = 'L.' and HighestDegreeYear = '1915')
        OR (AcademicYear = 2001 and LastName = 'COX' and FirstName = 'LISA' and MiddleName = 'ANN' and HighestDegreeYear = '1915')
        OR (AcademicYear = 2001 and LastName = 'ORTIZ' and FirstName = 'JUAN' and MiddleName = 'R' and TotalFinalSalary = '9330')
        OR (AcademicYear = 2001 and LastName = 'AMES' and FirstName = 'H.' and MiddleName = 'NORMAN' and TotalFinalSalary = '34610')

        OR (AcademicYear = 2002 and CertificateNumber = '393926A' and TotalFinalSalary = '65000')

        OR (AcademicYear = 2004 and LastName = 'MARTINEZ' and FirstName = 'RANDALL' and MiddleName = 'L' and TotalFinalSalary = '5830')
        OR (AcademicYear = 2004 and CertificateNumber = '387894R' and TotalFinalSalary = '20479')
        OR (AcademicYear = 2004 and CertificateNumber = '253579G' and TotalFinalSalary = '90128')

        OR (AcademicYear = 2005 and CertificateNumber = '418549B' and TotalFinalSalary = '56863')

        OR (AcademicYear = 2006 and CertificateNumber = '377014F' and TotalFinalSalary = '43382')

        OR (AcademicYear = 2007 and CertificateNumber = '437767G' and TotalFinalSalary = '43949')
        OR (AcademicYear = 2007 AND CertificateNumber = '369842J' and TotalFinalSalary = '45634')
        OR (AcademicYear = 2007 AND CertificateNumber = '420978R' and TotalFinalSalary = '41553')

        OR (AcademicYear = 2009 and CertificateNumber = '466137G' and TotalFinalSalary = '39200')
    )
)
SELECT
    *
    ,{{ getdate_fn() }} as MetaCreatedAt
FROM Cleaned2
