
-- TODO: generate AssignmentID
SELECT
    StaffID,
    S275.AcademicYear,
    RecordNumber,
    ProgramCode,
    ActivityCode,
    DutyArea,
    S275.DutyRoot,
    S275.DutySuffix,
    duty_codes.Description AS DutyDescription,
    Grade,
    Building,
    CAST(AssignmentPercent AS {{ t_numeric(14,4) }}) AS AssignmentPercent,
    CAST(AssignmentFTEDesignation AS {{ t_numeric(14,4) }}) AS AssignmentFTEDesignation,
    CAST(AssignmentSalaryTotal AS {{ t_int() }}) AS AssignmentSalaryTotal,
    AssignmentHoursPerYear,
    Major ,
    S275.FileType,
    CASE WHEN
        (
            CAST(S275.DutyRoot as {{ t_int() }}) IN (31, 32, 33, 34)
            AND ActivityCode ='27'
            AND S275.Area = 'L'
        )
        OR
        (
            CAST(S275.DutyRoot as {{ t_int() }}) = 63
        )
    THEN 1 ELSE 0 END AS IsTeachingAssignment,
    CASE WHEN
        CAST(S275.DutyRoot as {{ t_int() }}) >= 11 AND CAST(S275.DutyRoot as {{ t_int() }}) <= 25
    THEN 1 ELSE 0 END AS IsAdministrativeAssignment,
    CASE WHEN
        CAST(S275.DutyRoot as {{ t_int() }}) = 21 OR CAST(S275.DutyRoot as {{ t_int() }}) = 23
    THEN 1 ELSE 0 END AS IsPrincipalAssignment,
    CASE WHEN
        CAST(S275.DutyRoot as {{ t_int() }}) = 22 OR CAST(S275.DutyRoot as {{ t_int() }}) = 24
    THEN 1 ELSE 0 END AS IsAsstPrincipalAssignment,
    -- definition of an 'Educator' according to PESB
    CASE
        WHEN CAST(S275.DutyRoot as {{ t_int() }}) IN (11, 12, 13, 21, 22, 23, 24, 31, 32, 33, 34, 41, 42, 43, 45, 46, 47, 48, 49, 51, 52, 63, 64)
        THEN 1
        ELSE 0
    END AS IsPESBEducatorAssignment,
    {{ getdate_fn() }} as MetaCreatedAt
from {{ ref('Stg_S275_Coalesced') }} S275
JOIN {{ ref('Stg_Dim_Staff_Coalesced') }} d ON
    d.AcademicYear = S275.AcademicYear
    AND d.Area = S275.Area
    AND d.CountyAndDistrictCode = S275.CountyAndDistrictCode
    AND d.LastNameC = S275.LastNameC
    AND d.FirstNameC = S275.FirstNameC
    AND d.MiddleNameC = S275.MiddleNameC
    AND d.CertificateNumberC = S275.CertificateNumberC
    AND d.BirthdateC = S275.BirthdateC
LEFT JOIN {{ source('sources', 'Duty_Codes') }} ON
    S275.DutyRoot = CAST(duty_codes.DutyRoot AS {{ t_varchar() }})
    AND (duty_codes.DutySuffix IN ('x', 'y') OR duty_codes.DutySuffix = S275.DutySuffix)

