
-- creating this index fails when there are 'dupe' staff entries
-- (each with their own set of assignments). these cases occurred
-- in earlier years (from 1996 to 2001); they should have been removed
-- prior to the S275 table being loaded, so that this index can be
-- succesfully created.

{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['AcademicYear', 'Area', 'CountyAndDistrictCode', 'LastNameC', 'FirstNameC', 'MiddleNameC', 'CertificateNumberC', 'BirthdateC', 'StaffID'], unique=True) }}"
        ]
    })
}}

WITH T AS (
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
    FROM {{ ref('Stg_S275_Coalesced') }}
)
SELECT
    {% call hash() %}
    {% call concat() %}
    CAST(COALESCE(CAST(AcademicYear AS VARCHAR(100)), '') AS VARCHAR(100)) + 
    CAST(COALESCE(CountyAndDistrictCode, '') AS VARCHAR(100)) + 
    CAST(COALESCE(LastNameC, '') AS VARCHAR(100)) + 
    CAST(COALESCE(FirstNameC, '') AS VARCHAR(100)) + 
    CAST(COALESCE(MiddleNameC, '') AS VARCHAR(100)) + 
    CAST(COALESCE(CertificateNumberC, '') AS VARCHAR(100)) + 
    CAST(COALESCE(BirthdateC, '') AS VARCHAR(100))
    {% endcall %}
    {% endcall %}
    AS StaffID
    ,*
FROM T
