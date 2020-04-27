
DROP TABLE IF EXISTS Dim_School;

-- next

-- Created by running this in RMP database:
-- there's 53 rows with duplicate schoolcodes b/c of bad data quality;
-- we arbitrarily order by districtcode to de-dupe these
-- WITH T AS (
--     SELECT
--         *
--         ,ROW_NUMBER() OVER (PARTITION BY SchoolCode, AcademicYear
--             ORDER BY DistrictCode) AS Ranked
--     FROM Dim.School
-- )
-- SELECT
--     T.AcademicYear
--     ,T.DistrictCode
--     ,T.DistrictName
--     ,T.SchoolCode
--     ,T.SchoolName
--     ,GradeLevelStart
--     ,GradeLevelEnd
--     ,GradeLevelSortOrderStart 
--     ,GradeLevelSortOrderEnd
--     ,SchoolType
--     ,Lat
--     ,Long
--     ,NCESLocaleCode
--     ,NCESLocale
--     ,dRoadMapRegionFlag
-- into S275.dbo.Dim_School
-- FROM T
-- WHERE Ranked = 1;


CREATE TABLE Dim_School (
    AcademicYear int NOT NULL,
    DistrictCode varchar(8) NULL,
    DistrictName varchar(250) NULL,
    SchoolCode varchar(8) NOT NULL,
    SchoolName varchar(250) NULL,
    GradeLevelStart varchar(3) NULL,
    GradeLevelEnd varchar(3) NULL,
    GradeLevelSortOrderStart tinyint NULL,
    GradeLevelSortOrderEnd tinyint NULL,
    SchoolType varchar(50) NULL,
    Lat real NULL,
    Long real NULL,
    NCESLocaleCode VARCHAR(2) NULL,
    NCESLocale VARCHAR(50) NULL,
    RMRFlag int
);

-- next

CREATE UNIQUE INDEX idx_Dim_School ON Dim_School (
    AcademicYear,
    DistrictCode,
    DistrictName,
    SchoolCode,
    SchoolName,
    RMRFlag
);

-- next

CREATE INDEX idx_Dim_School2 ON Dim_School (
    AcademicYear,
    SchoolCode,
    SchoolName,
    DistrictCode,
    DistrictName,
    RMRFlag
);

