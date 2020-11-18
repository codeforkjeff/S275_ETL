
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

WITH EducatorContinued AS (
	select
		s.AcademicYear,
		s.CertificateNumber,
		MAX(CASE WHEN s.CBRTNCode IN ('C', 'T') THEN 1 ELSE 0 END) AS ContinuedOrTransferredFlag,
		MAX(CASE WHEN s.CBRTNCode IN ('C', 'T') AND s.IsInPSESDFlag = 1 THEN 1 ELSE 0 END) AS ContinuedOrTransferredWithinPSESDFlag
	FROM {{ ref('Dim_Staff') }}  s
	JOIN {{ ref('Fact_Assignment') }} a
		ON s.StaffID = a.StaffID
	WHERE
		a.IsPESBEducatorAssignment = 1
		and s.CertificateNumber IS NOT NULL
	GROUP BY
		s.AcademicYear,
		s.CertificateNumber
)
select
	p.CertificateNumber,
	p.CohortYear,
	p.EndYear,
	SUM(ContinuedOrTransferredFlag) AS ContinuedOrTransferredCount,
	SUM(ContinuedOrTransferredWithinPSESDFlag) AS ContinuedOrTransferredWithinPSESDCount
FROM {{ ref('Stg_PESB_Educator_Persistence') }} p
JOIN EducatorContinued ct
	ON p.CertificateNumber = ct.CertificateNumber
	AND ct.AcademicYear > p.CohortYear
	AND ct.AcademicYear <= p.EndYear
GROUP BY
	p.CertificateNumber,
	p.CohortYear,
	p.EndYear
