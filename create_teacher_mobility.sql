
-- This logic selects a single teacher/building per year

DROP TABLE IF EXISTS BaseSchoolTeachers;

-- next

CREATE TABLE BaseSchoolTeachers (
    StaffID int not null,
    AcademicYear int NOT NULL,
    CertificateNumber varchar(500) NULL,
    CountyAndDistrictCode varchar(500) NULL,
    Building varchar(500) NULL
);

-- next

INSERT INTO BaseSchoolTeachers (
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

CREATE INDEX idx_BaseSchoolTeachers ON BaseSchoolTeachers (
    AcademicYear
    ,CertificateNumber
    ,CountyAndDistrictCode
    ,Building
);

-- next

DROP TABLE IF EXISTS ByBuilding;

-- next

CREATE TABLE ByBuilding (
    StaffID int not null,
    AcademicYear int NOT NULL,
    CertificateNumber varchar(500) NULL,
    CountyAndDistrictCode varchar(500) NULL,
    Building varchar(500) NULL,
    TeacherFlag INT NULL,
    RN INT NULL
);

-- next

-- query assignments here, b/c we want to know if teachers became non-teachers
INSERT INTO ByBuilding (
    StaffID,
    AcademicYear,
    CertificateNumber,
    CountyAndDistrictCode,
    Building,
    TeacherFlag,
    RN
)
SELECT
    t.StaffID
    ,t.AcademicYear
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
    t.StaffID
    ,t.AcademicYear
    ,CertificateNumber
    ,s.CountyAndDistrictCode
    ,Building;

-- next

DELETE FROM ByBuilding
WHERE RN <> 1;

-- next

CREATE INDEX idx_ByBuilding ON ByBuilding (
    CertificateNumber
    ,AcademicYear
);

-- next

DROP TABLE IF EXISTS Fact_TeacherMobility;

-- next

CREATE TABLE Fact_TeacherMobility (
    StartStaffID int not null,
    EndStaffID int null,
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
    MovedInBuildingChange int NOT NULL,
    MovedInRoleChange int NOT NULL,
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
    FROM BaseSchoolTeachers y1
    WHERE EXISTS (
        SELECT 1 FROM BaseSchoolTeachers WHERE AcademicYear = y1.AcademicYear + 1
    )
    UNION ALL
    SELECT DISTINCT
        AcademicYear AS StartYear,
        AcademicYear + 4 AS EndYear
    FROM BaseSchoolTeachers y2
    WHERE EXISTS (
        SELECT 1 FROM BaseSchoolTeachers WHERE AcademicYear = y2.AcademicYear + 4
    )
)
,TransitionsBase AS (
    SELECT
        t1.StaffID AS StartStaffID,
        t2.StaffID AS EndStaffID,
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
    FROM BaseSchoolTeachers t1
    JOIN YearBrackets y
        ON t1.AcademicYear = y.StartYear
    LEFT JOIN ByBuilding t2
        ON t1.CertificateNumber = t2.CertificateNumber
        AND y.EndYear = t2.AcademicYear
)
,TransitionsWithMovedInBase AS (
    SELECT
        *
        ,CASE WHEN
            EndCountyAndDistrictCode IS NOT NULL
            AND EndBuilding IS NOT NULL
            AND StartCountyAndDistrictCode = EndCountyAndDistrictCode
        THEN 1 ELSE 0 END AS StayedInDistrict
    FROM TransitionsBase
)
,Transitions AS (
    SELECT
        *
        -- MovedInBuildingChange and MovedInRoleChange are components of MovedIn
        ,CASE WHEN
            StayedInDistrict = 1
            AND COALESCE(StartBuilding, -1) <> COALESCE(EndBuilding, -1)
        THEN 1 ELSE 0 END AS MovedInBuildingChange
        ,CASE WHEN
            StayedInDistrict = 1
            AND EndTeacherFlag = 0
        THEN 1 ELSE 0 END AS MovedInRoleChange
    FROM TransitionsWithMovedInBase
)
INSERT INTO Fact_TeacherMobility (
    StartStaffID,
    EndStaffID,
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
    MovedInBuildingChange,
    MovedInRoleChange,
    MovedIn,
    MovedOut,
    Exited
)
SELECT
    StartStaffID
    ,EndStaffID
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
    ,MovedInBuildingChange
    ,MovedInRoleChange
    ,CASE WHEN
        MovedInBuildingChange = 1 OR MovedInRoleChange = 1
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
DROP TABLE BaseSchoolTeachers;

-- next

DROP TABLE ByBuilding;
