
DROP TABLE IF EXISTS raw_school_base;

-- next

CREATE TABLE raw_school_base (
    AcademicYear VARCHAR(500),
    DistrictCode VARCHAR(500),
    DistrictName VARCHAR(500),
    SchoolCode VARCHAR(500),
    SchoolName VARCHAR(500),
    GradeLevelStart VARCHAR(500),
    GradeLevelEnd VARCHAR(500),
    GradeLevelSortOrderStart VARCHAR(500),
    GradeLevelSortOrderEnd VARCHAR(500),
    SchoolType VARCHAR(500),
    Lat VARCHAR(500),
    Long VARCHAR(500),
    NCESLocaleCode VARCHAR(500),
    NCESLocale VARCHAR(500),
    RMRFlag VARCHAR(500)
);
