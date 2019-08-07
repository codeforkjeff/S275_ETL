-- Created by running this in RMP database:
--
-- SELECT
--   DistrictCode,
--   MAX(DistrictName) AS DistrictName,
--   SchoolCode,
--   MAX(SchoolName) AS SchoolName
-- FROM Dim.School
-- WHERE SchoolCode IS NOT NULL
-- GROUP BY
--   DistrictCode,
--   SchoolCode


DROP TABLE IF EXISTS SchoolCodes;

-- next

CREATE TABLE SchoolCodes (
	DistrictCode varchar(8) NULL,
	DistrictName varchar(250) NULL,
	SchoolCode varchar(8) NOT NULL,
	SchoolName varchar(250) NULL
);
-- next

CREATE INDEX idx_SchoolCodes ON SchoolCodes (
	DistrictCode,
	DistrictName,
	SchoolCode,
	SchoolName
);
