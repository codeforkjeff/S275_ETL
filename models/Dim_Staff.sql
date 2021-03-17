
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['StaffID'], unique=True) }}"
        ]
    })
}}

WITH
Stage1 AS (
    SELECT
        *,
        CASE
            WHEN RaceEthOSPI IN ('White', 'Not Provided') THEN RaceEthOSPI
            ELSE 'Person of Color'
        END AS PersonOfColorCategory,
        CASE WHEN EXISTS (
            select 1
            from {{ ref('Stg_Dim_Staff_Flags') }} f
            where f.StaffID = base.StaffID
            and IsTeacherFlag = 1
        ) THEN 1 ELSE 0 END AS IsTeacherFlag,
        CASE WHEN EXISTS (
            select 1
            from {{ ref('Stg_Dim_Staff_Flags') }} f
            where f.StaffID = base.StaffID
            and IsPrincipalFlag = 1
        ) THEN 1 ELSE 0 END AS IsPrincipalFlag,
        CASE WHEN EXISTS (
            select 1
            from {{ ref('Stg_Dim_Staff_Flags') }} f
            where f.StaffID = base.StaffID
            and IsAsstPrincipalFlag = 1
        ) THEN 1 ELSE 0 END AS IsAsstPrincipalFlag,
        -- is board certified at the start of the AY (i.e. their cert expires after Sept of the AY)
        -- NationalBoardCertExpirationDate became available starting in 2017. note that this is different
        -- from the 'certflag' field which designates whether person is "certificated employee"
        CASE
            WHEN {{ substring_fname() }}(NationalBoardCertExpirationDate, 1, 7) >=
            {% call concat() %}
            (CAST((AcademicYear - 1) as {{ t_varchar() }}) + '-09') -- sqlite_concat
            {% endcall %}
            THEN 1 ELSE 0
        END AS IsNationalBoardCertified,
        CASE
            WHEN CertificateNumber IS NOT NULL
            THEN
                CASE WHEN CertificateNumber LIKE 'Z%' THEN 'T' ELSE 'P' END
        END AS TempOrPermCert,
        CASE WHEN EXISTS (
            SELECT 1
            FROM {{ ref('Stg_First_Year_In_District') }} FirstYearInDistrict
            WHERE FirstYearInDistrict.CertificateNumber = base.CertificateNumber
            AND FirstYearInDistrict.CountyAndDistrictCode = base.CountyAndDistrictCode
            AND FirstYearInDistrict.FirstYear = base.AcademicYear
        ) THEN 1 ELSE 0 END AS IsNewHireFlag,
        CASE WHEN EXISTS (
            SELECT 1
            FROM {{ ref('Stg_First_Year_In_WA') }} FirstYearInWA
            WHERE FirstYearInWA.CertificateNumber = base.CertificateNumber
            AND FirstYearInWA.FirstYear = base.AcademicYear
        ) THEN 1 ELSE 0 END AS IsNewHireWAStateFlag,
        CASE
            WHEN CountyAndDistrictCode IN (
                '17408', -- Auburn School District
                '18303', -- Bainbridge Island School District
                '17405', -- Bellevue School District
                '27403', -- Bethel School District
                '27019', -- Carbonado School District
                '27400', -- Clover Park School District
                '27343', -- Dieringer School District
                '27404', -- Eatonville School District
                '17216', -- Enumclaw School District
                '17210', -- Federal Way School District
                '27417', -- Fife School District
                '27402', -- Franklin Pierce School District
                '17401', -- Highline School District
                '17411', -- Issaquah School District
                '17415', -- Kent School District
                '17414', -- Lake Washington School District
                '17400', -- Mercer Island School District
                '17417', -- Northshore School District
                '27344', -- Orting School District
                '27401', -- Peninsula School District
                '27003', -- Puyallup School District
                '17403', -- Renton School District
                '17407', -- Riverview School District
                '17001', -- Seattle Public Schools
                '17412', -- Shoreline School District
                '17404', -- Skykomish School District
                '17410', -- Snoqualmie Valley School District
                '27001', -- Steilacoom Hist. School District
                '27320', -- Sumner School District
                '27010', -- Tacoma School District
                '17409', -- Tahoma School District
                '17406', -- Tukwila School District
                '27083', -- University Place School District
                '17402', -- Vashon Island School District
                '27416'  -- White River School District
            ) THEN 1
            ELSE 0
        END AS IsInPSESDFlag
    FROM {{ ref('Stg_Dim_Staff') }} base
)
,Stage2 AS (
    SELECT
        *,
        CASE WHEN IsTeacherFlag = 1 AND CAST(CertYearsOfExperience AS {{ t_real() }}) < 2.0 THEN 1 ELSE 0 END
        AS IsNoviceTeacherFlag
    FROM Stage1
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
    RaceEthOSPI,
    PersonOfColorCategory,
    HighestDegree,
    HighestDegreeYear,
    CAST(AcademicCredits AS {{ t_numeric(6, 2) }}) AS AcademicCredits,
    CAST(InServiceCredits AS {{ t_numeric(6, 2) }}) AS InServiceCredits,
    CAST(ExcessCredits AS {{ t_numeric(6, 2) }}) AS ExcessCredits,
    CAST(NonDegreeCredits AS {{ t_numeric(6, 2) }}) AS NonDegreeCredits,
    CAST(CertYearsOfExperience AS {{ t_real() }}) AS CertYearsOfExperience,
    StaffMixFactor,
    StaffMixFactor1,
    StaffMixFactor1A,
    StaffMixFactor1S,
    StaffMixFactor1Sa,
    StaffMixFactor1SB,
    CAST(FTEHours AS {{ t_numeric(6, 2) }}) AS FTEHours,
    CAST(FTEDays AS {{ t_numeric(10,4) }}) AS FTEDays,
    CAST(CertificatedFTE AS {{ t_numeric(6, 3) }}) AS CertificatedFTE,
    CAST(ClassifiedFTE AS {{ t_numeric(6, 3) }}) AS ClassifiedFTE,
    CAST(CertificatedBase AS {{ t_int() }}) AS CertificatedBase,
    CAST(ClassifiedBase AS {{ t_int() }}) AS ClassifiedBase,
    CAST(OtherSalary AS {{ t_int() }}) AS OtherSalary,
    CAST(TotalFinalSalary AS {{ t_int() }}) AS TotalFinalSalary,
    CAST(ActualAnnualInsurance AS {{ t_int() }}) AS ActualAnnualInsurance,
    CAST(ActualAnnualMandatory AS {{ t_int() }}) AS ActualAnnualMandatory,
    CBRTNCode,
    ClassificationFlag,
    CertifiedFlag,
    NationalBoardCertExpirationDate,
    FileType,
    CAST(IsTeacherFlag AS {{ t_tinyint() }}) AS IsTeacherFlag,
    CAST(IsNoviceTeacherFlag AS {{ t_tinyint() }}) AS IsNoviceTeacherFlag,
    CAST(IsPrincipalFlag AS {{ t_tinyint() }}) AS IsPrincipalFlag,
    CAST(IsAsstPrincipalFlag AS {{ t_tinyint() }}) AS IsAsstPrincipalFlag,
    CAST(IsNationalBoardCertified AS {{ t_tinyint() }}) AS IsNationalBoardCertified,
    CAST(TempOrPermCert AS {{ t_varchar(1) }}) AS TempOrPermCert,
    CAST(IsNewHireFlag AS {{ t_tinyint() }}) AS IsNewHireFlag,
    CAST(IsNewHireWAStateFlag AS {{ t_tinyint() }}) AS IsNewHireWAStateFlag,
    CAST(IsInPSESDFlag AS {{ t_tinyint() }}) AS IsInPSESDFlag,
    {{ getdate_fn() }} as MetaCreatedAt
FROM Stage2
