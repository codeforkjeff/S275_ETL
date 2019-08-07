
-- This analysis selects a single teacher/building per year

DROP TABLE IF EXISTS BaseSchoolTeachersSingle;

-- next

CREATE TABLE BaseSchoolTeachersSingle (
    StaffID int not null,
    AcademicYear int NOT NULL,
    CertificateNumber varchar(500) NULL,
    CountyAndDistrictCode varchar(500) NULL,
    Building varchar(500) NULL
);

-- next

INSERT INTO BaseSchoolTeachersSingle (
    StaffID,
    AcademicYear,
    CertificateNumber,
    CountyAndDistrictCode,
    Building
)
SELECT
    s.StaffID
    ,t.AcademicYear
    ,CertificateNumber
    ,s.CountyAndDistrictCode
    ,Building
FROM Fact_SchoolTeacher t
JOIN Dim_Staff s
    ON t.StaffID = s.StaffID
WHERE PrimaryFlag = 1;

-- next

CREATE INDEX idx_BaseSchoolTeachersSingle ON BaseSchoolTeachersSingle (
    AcademicYear
    ,CertificateNumber
    ,CountyAndDistrictCode
    ,Building
);

-- next

DROP TABLE IF EXISTS ByBuildingSingle;

-- next

CREATE TABLE ByBuildingSingle (
    AcademicYear int NOT NULL,
    CertificateNumber varchar(500) NULL,
    CountyAndDistrictCode varchar(500) NULL,
    Building varchar(500) NULL,
    TeacherFlag INT NULL,
    RN INT NULL
);

-- next

-- query assignments here, b/c we want to know if teachers became non-teachers
INSERT INTO ByBuildingSingle (
    AcademicYear,
    CertificateNumber,
    CountyAndDistrictCode,
    Building,
    TeacherFlag,
    RN
)
SELECT
    t.AcademicYear
    ,CertificateNumber
    ,s.CountyAndDistrictCode
    ,Building
    ,MAX(IsTeachingAssignment) AS TeacherFlag
    ,ROW_NUMBER() OVER (PARTITION BY
        t.AcademicYear,
        CertificateNumber
    ORDER BY
        SUM(AssignmentFTEDesignation) DESC,
        -- tiebreaking below this line
        SUM(AssignmentPercent) DESC,
        SUM(AssignmentSalaryTotal) DESC
    ) as RN
FROM Fact_assignment t
JOIN Dim_Staff s
    ON t.StaffID = s.StaffID
GROUP BY
    t.AcademicYear
    ,CertificateNumber
    ,s.CountyAndDistrictCode
    ,Building;

-- next

DELETE FROM ByBuildingSingle
WHERE RN <> 1;

-- next

CREATE INDEX idx_ByBuildingSingle ON ByBuildingSingle (
    CertificateNumber
    ,AcademicYear
);

-- next

DROP TABLE IF EXISTS Fact_TeacherMobilitySingle;

-- next

CREATE TABLE Fact_TeacherMobilitySingle (
    StaffID int not null,
    StartYear int NOT NULL,
    EndYear int NULL,
    DiffYears int NULL,
    CertificateNumber varchar(500) NULL,
    StartCountyAndDistrictCode varchar(500) NULL,
    StartBuilding varchar(500) NULL,
    EndCountyAndDistrictCode varchar(500) NULL,
    EndBuilding varchar(500) NULL,
    EndTeacherFlag int NULL,
    Stayer int NOT NULL,
    MovedIn int NOT NULL,
    MovedOut int NOT NULL,
    Exited int NOT NULL
);

-- next

WITH
YearBrackets AS (
    SELECT DISTINCT
        AcademicYear AS StartYear,
        AcademicYear + 1 AS EndYear
    FROM BaseSchoolTeachersSingle y1
    WHERE EXISTS (
        SELECT 1 FROM BaseSchoolTeachersSingle WHERE AcademicYear = y1.AcademicYear + 1
    )
    UNION ALL
    SELECT DISTINCT
        AcademicYear AS StartYear,
        AcademicYear + 4 AS EndYear
    FROM BaseSchoolTeachersSingle y2
    WHERE EXISTS (
        SELECT 1 FROM BaseSchoolTeachersSingle WHERE AcademicYear = y2.AcademicYear + 4
    )
)
,Transitions AS (
    SELECT
        t1.StaffID,
        t1.AcademicYear AS StartYear,
        y.EndYear AS EndYear,
        y.EndYear - t1.AcademicYear AS DiffYears,
        t1.CertificateNumber,
        -- start fields
        t1.CountyAndDistrictCode AS StartCountyAndDistrictCode,
        t1.Building AS StartBuilding,
        -- end fields
        t2.CountyAndDistrictCode AS EndCountyAndDistrictCode,
        t2.Building AS EndBuilding,
        t2.TeacherFlag AS EndTeacherFlag
    FROM BaseSchoolTeachersSingle t1
    JOIN YearBrackets y
        ON t1.AcademicYear = y.StartYear
    LEFT JOIN ByBuildingSingle t2
        ON t1.CertificateNumber = t2.CertificateNumber
        AND y.EndYear = t2.AcademicYear
)
INSERT INTO Fact_TeacherMobilitySingle (
    StaffID,
    StartYear,
    EndYear,
    DiffYears,
    CertificateNumber,
    StartCountyAndDistrictCode,
    StartBuilding,
    EndCountyAndDistrictCode,
    EndBuilding,
    EndTeacherFlag,
    Stayer,
    MovedIn,
    MovedOut,
    Exited
)
SELECT
    StaffID
    ,StartYear
    ,EndYear
    ,DiffYears
    ,CertificateNumber
    ,StartCountyAndDistrictCode
    ,StartBuilding
    ,EndCountyAndDistrictCode
    ,EndBuilding
    ,EndTeacherFlag
    ,CASE WHEN
        EndCountyAndDistrictCode IS NOT NULL
        AND StartCountyAndDistrictCode = EndCountyAndDistrictCode
        AND StartBuilding = EndBuilding
        AND EndTeacherFlag = 1
    THEN 1 ELSE 0 END AS Stayer
    ,CASE WHEN
        EndCountyAndDistrictCode IS NOT NULL
        AND EndBuilding IS NOT NULL
        AND StartCountyAndDistrictCode = EndCountyAndDistrictCode
        AND (
            COALESCE(StartBuilding, -1) <> COALESCE(EndBuilding, -1)
            OR EndTeacherFlag = 0
        )
    THEN 1 ELSE 0 END AS MovedIn
    ,CASE WHEN
        EndCountyAndDistrictCode IS NOT NULL
        AND EndBuilding IS NOT NULL
        AND COALESCE(StartCountyAndDistrictCode, -1) <> COALESCE(EndCountyAndDistrictCode, -1)
    THEN 1 ELSE 0 END AS MovedOut
    ,CASE WHEN
        EndBuilding IS NULL
    THEN 1 ELSE 0 END AS Exited
FROM Transitions;

-- next

-- cleanup
DROP TABLE BaseSchoolTeachersSingle;

-- next

DROP TABLE ByBuildingSingle;
