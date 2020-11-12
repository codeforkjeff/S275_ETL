-- TODO: make this a temp table

SELECT
    *,
    COALESCE(LastName, '') AS LastNameC,
    COALESCE(FirstName, '') AS FirstNameC,
    COALESCE(MiddleName, '') AS MiddleNameC,
    COALESCE(CertificateNumber, '') AS CertificateNumberC,
    COALESCE(Birthdate, '') AS BirthdateC
FROM {{ ref('s275') }}
