
DROP TABLE IF EXISTS Dim_School_Base;

-- next

CREATE TABLE Dim_School_Base (
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

DROP TABLE IF EXISTS Dim_School_Fields;

-- next

CREATE TABLE Dim_School_Fields (
    AcademicYear int NOT NULL,
    DistrictCode varchar(8) NULL,
    DistrictName varchar(250) NULL,
    SchoolCode varchar(8) NOT NULL,
    SchoolName varchar(250) NULL,
    -- attributes
    TotalEnrollmentOct smallint,
    GraduationPercent numeric(9,4),
    FRPL smallint,
    FRPLPercent numeric(10,2),
    AmIndOrAlaskan smallint,
    AmIndOrAlaskanPercent numeric(10,2),
    Asian smallint,
    AsianPercent numeric(10,2),
    PacIsl smallint,
    PacIslPercent numeric(10,2),
    AsPacIsl smallint,
    AsPacIslPercent numeric(10,2),
    Black smallint,
    BlackPercent numeric(10,2),
    Hispanic smallint,
    HispanicPercent numeric(10,2),
    White smallint,
    WhitePercent numeric(10,2),
    TwoOrMoreRaces smallint,
    TwoOrMoreRacesPercent numeric(10,2),
    Male smallint,
    MalePercent numeric(10,2),
    Female smallint,
    FemalePercent numeric(10,2),
    GenderX smallint,
    GenderXPercent numeric(10,2)
);

-- next

CREATE UNIQUE INDEX idx_Dim_School_Fields ON Dim_School_Fields (
    AcademicYear,
    DistrictCode,
    SchoolCode
);

-- next

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
    RMRFlag int,
    -- from Fields
    TotalEnrollmentOct smallint,
    GraduationPercent numeric(9,4),
    FRPL smallint,
    FRPLPercent numeric(10,2),
    AmIndOrAlaskan smallint,
    AmIndOrAlaskanPercent numeric(10,2),
    Asian smallint,
    AsianPercent numeric(10,2),
    PacIsl smallint,
    PacIslPercent numeric(10,2),
    AsPacIsl smallint,
    AsPacIslPercent numeric(10,2),
    Black smallint,
    BlackPercent numeric(10,2),
    Hispanic smallint,
    HispanicPercent numeric(10,2),
    White smallint,
    WhitePercent numeric(10,2),
    TwoOrMoreRaces smallint,
    TwoOrMoreRacesPercent numeric(10,2),
    -- StudentsOfColor fields are derived
    StudentsOfColor smallint,
    StudentsOfColorPercent numeric(10,2),
    Male smallint,
    MalePercent numeric(10,2),
    Female smallint,
    FemalePercent numeric(10,2),
    GenderX smallint,
    GenderXPercent numeric(10,2),
    MetaCreatedAt DATETIME
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

