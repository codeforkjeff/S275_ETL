
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['AcademicYear', 'CountyAndDistrictCode', 'Building']) }}"
        ]
    })
}}

-- This logic selects a single principal (either 'main' principal or Asst Principal)/building per year

SELECT
    sp.StaffID,
    sp.AcademicYear,
    CertificateNumber,
    sp.CountyAndDistrictCode,
    Building,
    PrincipalType
FROM {{ ref('Fact_SchoolPrincipal') }} sp
JOIN {{ ref('Dim_Staff') }} s
    ON sp.StaffID = s.StaffID
    WHERE PrimaryFlag = 1
