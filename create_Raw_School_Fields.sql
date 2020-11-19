
DROP TABLE IF EXISTS Raw_School_Fields;

-- next

CREATE TABLE Raw_School_Fields (
    AcademicYear VARCHAR(500),
    DistrictCode VARCHAR(500),
    DistrictName VARCHAR(500),
    SchoolCode VARCHAR(500),
    SchoolName VARCHAR(500),
    -- attributes
    TotalEnrollmentOct VARCHAR(500),
    GraduationMet VARCHAR(500),
    GraduationTotal VARCHAR(500),
    GraduationPercent VARCHAR(500),
    FRPL VARCHAR(500),
    FRPLPercent VARCHAR(500),
    AmIndOrAlaskan VARCHAR(500),
    AmIndOrAlaskanPercent VARCHAR(500),
    Asian VARCHAR(500),
    AsianPercent VARCHAR(500),
    PacIsl VARCHAR(500),
    PacIslPercent VARCHAR(500),
    AsPacIsl VARCHAR(500),
    AsPacIslPercent VARCHAR(500),
    Black VARCHAR(500),
    BlackPercent VARCHAR(500),
    Hispanic VARCHAR(500),
    HispanicPercent VARCHAR(500),
    White VARCHAR(500),
    WhitePercent VARCHAR(500),
    TwoOrMoreRaces VARCHAR(500),
    TwoOrMoreRacesPercent VARCHAR(500),
    Male VARCHAR(500),
    MalePercent VARCHAR(500),
    Female VARCHAR(500),
    FemalePercent VARCHAR(500),
    GenderX VARCHAR(500),
    GenderXPercent VARCHAR(500)
);
