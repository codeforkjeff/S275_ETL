
-- creating this index fails when there are 'dupe' staff entries
-- (each with their own set of assignments). these cases occurred
-- in earlier years (from 1996 to 2001); they should have been removed
-- prior to the S275 table being loaded, so that this index can be
-- succesfully created.

{{
    config({
        "pre-hook": [
            "DROP INDEX IF EXISTS idx_stg_dim_staff_coalesced"
        ]
        ,"post-hook": [
            """
            CREATE UNIQUE INDEX idx_stg_dim_staff_coalesced ON stg_dim_staff_coalesced (
                AcademicYear,
                Area,
                CountyAndDistrictCode,
                LastNameC,
                FirstNameC,
                MiddleNameC,
                CertificateNumberC,
                BirthdateC
                -- TODO: add staffid to make this a covering index
                -- StaffID
            )
            """
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
    FROM {{ ref('stg_s275_coalesced') }}
)
SELECT
    {% call concat() %}
    COALESCE(AcademicYear, '') + 
    COALESCE(CountyAndDistrictCode, '') + 
    COALESCE(LastNameC, '') + 
    COALESCE(FirstNameC, '') + 
    COALESCE(MiddleNameC, '') + 
    COALESCE(CertificateNumberC, '') + 
    COALESCE(BirthdateC, '')
    {% endcall %}
    AS StaffID
    ,*
FROM T
