
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

-- this doesn't work b/c some staff don't have cert numbers

-- ensure we only have one teacher/district per year
-- CREATE UNIQUE INDEX idx_BaseSchoolTeachers_unique ON BaseSchoolTeachers (
--     AcademicYear,
--     CertificateNumber,
-- );

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

-- FIXME: this rolls up to a building, and hence, more than row for a person/year row,
-- which results multiple rows in the transitions table for a person/year.

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
    TeacherMobilityID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StartStaffID int not null,
    EndStaffID int null,
    StartYear int NOT NULL,
    EndYear int NULL,
    DiffYears int NULL,
    CertificateNumber varchar(500) NULL,
    StartCountyAndDistrictCode varchar(500) NULL,
    StartBuilding varchar(500) NULL,
    StartLocale varchar(50) NULL,
    EndCountyAndDistrictCode varchar(500) NULL,
    EndBuilding varchar(500) NULL,
    EndLocale varchar(50) NULL,
    EndTeacherFlag int NULL,
    Distance real NULL,
    RoleChanged int NULL,
    Stayer int NOT NULL,
    MovedInBuildingChange int NOT NULL,
    MovedInRoleChange int NOT NULL,
    MovedIn int NOT NULL,
    MovedOut int NOT NULL,
    MovedOutOfRMR int NOT NULL,
    Exited int NOT NULL,
    MetaCreatedAt DATETIME
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
        t.*
        ,s1.NCESLocale AS StartLocale
        ,s2.NCESLocale AS EndLocale
        ,CASE WHEN EndTeacherFlag = 0 THEN 1 ELSE 0 END AS RoleChanged
        -- MovedInBuildingChange and MovedInRoleChange are components of MovedIn
        ,CASE WHEN
            StayedInDistrict = 1
            -- there are a handful of 'ELE' building codes, so coalesce to string, not int
            AND COALESCE(StartBuilding, 'NONE') <> COALESCE(EndBuilding, 'NONE')
        THEN 1 ELSE 0 END AS MovedInBuildingChange
        ,CASE WHEN
            StayedInDistrict = 1
            AND EndTeacherFlag = 0
        THEN 1 ELSE 0 END AS MovedInRoleChange
    FROM TransitionsWithMovedInBase t
    LEFT JOIN Dim_School s1
        ON t.StartBuilding = s1.SchoolCode
        AND t.StartYear = s1.AcademicYear
    LEFT JOIN Dim_School s2
        ON t.EndBuilding = s2.SchoolCode
        AND t.EndYear = s2.AcademicYear
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
    StartLocale,
    EndCountyAndDistrictCode,
    EndBuilding,
    EndLocale,
    EndTeacherFlag,
    RoleChanged,
    Stayer,
    MovedInBuildingChange,
    MovedInRoleChange,
    MovedIn,
    MovedOut,
    MovedOutOfRMR,
    Exited,
    MetaCreatedAt
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
    ,StartLocale
    ,EndCountyAndDistrictCode
    ,EndBuilding
    ,EndLocale
    ,EndTeacherFlag
    ,RoleChanged
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
    ,0 AS MovedOutOfRMR
    ,CASE WHEN
        EndBuilding IS NULL
    THEN 1 ELSE 0 END AS Exited
    ,GETDATE() as MetaCreatedAt
FROM Transitions;

-- next

UPDATE Fact_TeacherMobility
SET MovedOutOfRMR = CASE
    WHEN MovedOut = 1
        AND EXISTS (
            SELECT 1
            FROM Dim_School
            WHERE
                Fact_TeacherMobility.StartYear = AcademicYear
                AND Fact_TeacherMobility.StartBuilding = SchoolCode
            AND RMRFlag = 1
            )
        AND NOT EXISTS (
            SELECT 1
            FROM Dim_School
            WHERE
                Fact_TeacherMobility.EndYear = AcademicYear
                AND Fact_TeacherMobility.EndBuilding = SchoolCode
            AND RMRFlag = 1
            )
    THEN 1
    ELSE 0
    END;

-- next

CREATE INDEX idx_Fact_TeacherMobility ON Fact_TeacherMobility(StartStaffID, EndStaffID);

-- next

CREATE INDEX idx_Fact_TeacherMobility2 ON Fact_TeacherMobility(StartYear, StartCountyAndDistrictCode, StartBuilding);

-- next

-- cleanup
DROP TABLE BaseSchoolTeachers;

-- next

DROP TABLE ByBuilding;
