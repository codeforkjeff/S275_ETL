
-- PESB's persistence measure logic.
-- This table is rolled up to the AY and person level. Note that this is different from other fact tables
-- which include District in the grain.
--
-- Persistence is defined here as continuously working in each of the academic years of the period examined
-- (vs comparing the start/end years). We confirmed this on 8/4/2020.

{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['CertificateNumber', 'CohortYear', 'EndYear']) }}"
        ]
    })
}}

SELECT
    p.CertificateNumber,
    p.CohortYear,
    CohortInPSESDFlag,
    CohortBeginningEducatorFlag,
    CohortRace,
    CohortPersonOfColorCategory,
    p.EndYear,
    YearCount,
    CASE WHEN c.CertificateNumber IS NOT NULL THEN 1 ELSE 0 END AS PersistedWithinWAFlag,
    CASE WHEN c2.CertificateNumber IS NOT NULL THEN 1 ELSE 0 END AS PersistedWithinPSESDFlag,
    {{ getdate_fn() }} as MetaCreatedAt
FROM {{ ref('Stg_PESB_Educator_Persistence') }} p
LEFT JOIN {{ ref('Stg_Educator_Continued_Counts')}} c
    ON p.CertificateNumber = c.CertificateNumber
    AND p.CohortYear = c.CohortYear
    AND p.EndYear = c.EndYear
    -- subtract 1 to exclude considering cohort year
    AND c.ContinuedOrTransferredCount = p.YearCount - 1
LEFT JOIN {{ ref('Stg_Educator_Continued_Counts')}} c2
    ON p.CertificateNumber = c2.CertificateNumber
    AND p.CohortYear = c2.CohortYear
    AND p.EndYear = c2.EndYear
    -- subtract 1 to exclude considering cohort year
    AND c2.ContinuedOrTransferredWithinPSESDCount = p.YearCount - 1
