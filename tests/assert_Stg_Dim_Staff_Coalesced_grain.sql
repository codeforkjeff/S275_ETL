
-- this table gets an index but not all platforms have indexes, so here's a test

select
    AcademicYear, Area, CountyAndDistrictCode, LastNameC, FirstNameC, MiddleNameC, CertificateNumberC, BirthdateC, StaffID, count(*) AS NumRows
FROM {{ ref('Stg_Dim_Staff_Coalesced') }}
GROUP BY
    AcademicYear, Area, CountyAndDistrictCode, LastNameC, FirstNameC, MiddleNameC, CertificateNumberC, BirthdateC, StaffID
HAVING COUNT(*) > 1
