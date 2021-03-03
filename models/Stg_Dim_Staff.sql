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
                WHEN {{ len_fname() }}(LTRIM(RTRIM(Race))) > 1 THEN 'Two or More Races'
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
--    NULL AS PersonOfColorCategory,
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
    FileType,
    {{ getdate_fn() }} as MetaCreatedAt
FROM {{ ref('Stg_Dim_Staff_Coalesced') }}
