
-- Fact_schoolLeadership records the leadership (principal, asst principal) at each school/year.
-- attributes include:
--      - whether leadership changed from the previous year
--      - teacher retention 1 and 2 years out from the base year

DROP TABLE IF EXISTS Fact_SchoolLeadership;

-- next

CREATE TABLE Fact_SchoolLeadership (
	SchoolLeadershipID INT IDENTITY(1,1) NOT NULL PRIMARY KEY
	,AcademicYear SMALLINT
	,CountyAndDistrictCode VARCHAR(5)
	,Building VARCHAR(10)
	-- these Principal and AP fields take the "primary" person if there is more than 1 in that role
	,PrincipalCertificateNumber VARCHAR(20)
	,PrincipalStaffID INT
	,PrevPrincipalStaffID INT
	,AsstPrincipalCertificateNumber VARCHAR(20)
	,AsstPrincipalStaffID INT
	,PrevAsstPrincipalStaffID INT
	,SamePrincipalFlag TINYINT
	,SameAsstPrincipalFlag TINYINT
	,LeadershipChangeFlag TINYINT
	,PromotionFlag TINYINT
	,PrincipalTenure TINYINT
	,AsstPrincipalTenure TINYINT
	-- 'broad' leadership fields = considers ALL principals and asst principals at the school
	,AllPrincipalCertList VARCHAR(1000)
	,AllAsstPrinCertList VARCHAR(1000)
	,AnyPrincipalPOC TINYINT
	,AnyAsstPrinPOC TINYINT
    ,BroadLeadershipAnyPOCFlag TINYINT
    -- change flags
    ,BroadLeadershipChangeFlag TINYINT
    ,BroadLeadershipAnyPOCStayedFlag TINYINT
    ,BroadLeadershipStayedNoPOCFlag TINYINT
    ,BroadLeadershipChangeAnyPOCToNoneFlag TINYINT
    ,BroadLeadershipChangeNoPOCToAnyFlag TINYINT
    -- gain/loss flags
	,BroadLeadershipGainedPrincipalPOCFlag TINYINT
	,BroadLeadershipGainedAsstPrinPOCFlag TINYINT
	,BroadLeadershipGainedPOCFlag TINYINT
	,BroadLeadershipLostPrincipalPOCFlag TINYINT
	,BroadLeadershipLostAsstPrinPOCFlag TINYINT
	,BroadLeadershipLostPOCFlag TINYINT
	--
	,TeacherCount INT
	,TeacherRetention1Yr INT
	,TeacherRetention1YrPct NUMERIC(10,2)
	,TeacherRetention2Yr INT
	,TeacherRetention2YrPct NUMERIC(10,2)
	,TeacherRetention3Yr INT
	,TeacherRetention3YrPct NUMERIC(10,2)
	,TeacherRetention4Yr INT
	,TeacherRetention4YrPct NUMERIC(10,2)
	,TeacherOfColorCount INT
	,TeacherOfColorRetention1Yr INT
	,TeacherOfColorRetention1YrPct NUMERIC(10,2)
	,TeacherOfColorRetention2Yr INT
	,TeacherOfColorRetention2YrPct NUMERIC(10,2)
	,TeacherOfColorRetention3Yr INT
	,TeacherOfColorRetention3YrPct NUMERIC(10,2)
	,TeacherOfColorRetention4Yr INT
	,TeacherOfColorRetention4YrPct NUMERIC(10,2)
	,MetaCreatedAt DATETIME
);

-- next

;WITH Primaries AS (
	-- a school can have more than 1 Principal or AP. pick one for each role
	SELECT
		sp.*
	FROM Fact_SchoolPrincipal sp
	WHERE
		PrimaryForSchoolFlag = 1
)
,Leadership AS (
	-- this union and group by captures yrs where a school has an Asst Prin but not a Principal.
	SELECT
		AcademicYear
		,CountyAndDistrictCode
		,Building
		,MAX(PrincipalStaffID) AS PrincipalStaffID
		,MAX(AsstPrincipalStaffID) AS AsstPrincipalStaffID
	FROM (
		SELECT
			p.AcademicYear
			,p.CountyAndDistrictCode
			,p.Building
			,p.StaffID AS PrincipalStaffID
			,NULL AS AsstPrincipalStaffID
		FROM Primaries p
		WHERE p.PrincipalType = 'Principal'

		UNION ALL

		SELECT
			ap.AcademicYear
			,ap.CountyAndDistrictCode
			,ap.Building
			,NULL AS PrincipalStaffID
			,ap.StaffID AS AsstPrincipalStaffID
		FROM Primaries ap
		WHERE ap.PrincipalType = 'AssistantPrincipal'
	) T
	GROUP BY
		AcademicYear
		,CountyAndDistrictCode
		,Building
)
,LeadershipWithPrevious AS (
	select
		curr.AcademicYear
		,curr.CountyAndDistrictCode
		,curr.Building
		,curr.PrincipalStaffID
		,prev.PrincipalStaffID AS PrevPrincipalStaffID
		,curr.AsstPrincipalStaffID
		,prev.AsstPrincipalStaffID AS PrevAsstPrincipalStaffID
	from leadership curr
	left join leadership prev
		ON curr.AcademicYear = prev.AcademicYear + 1
		AND curr.CountyAndDistrictCode = prev.CountyAndDistrictCode
		and curr.Building = prev.Building
)
INSERT INTO Fact_SchoolLeadership (
	AcademicYear
	,CountyAndDistrictCode
	,Building
	,PrincipalCertificateNumber
	,PrincipalStaffID
	,PrevPrincipalStaffID
	,AsstPrincipalCertificateNumber
	,AsstPrincipalStaffID
	,PrevAsstPrincipalStaffID
	,SamePrincipalFlag
	,SameAsstPrincipalFlag
	,PromotionFlag
	/*
	,PrincipalTenure
	,AsstPrincipalTenure
	,TeacherRetentionForLeadership1YR
	,TeacherRetentionForLeadership2YR
	,TeacherOfColorRetention1YR
	,TeacherOfColorRetention2YR
	*/
	,MetaCreatedAt
)
select
	le.AcademicYear
	,le.CountyAndDistrictCode
	,le.Building
	,s_prin.CertificateNumber AS PrincipalCertificateNumber
	,le.PrincipalStaffID
	,le.PrevPrincipalStaffID
	,s_asstprin.CertificateNumber AS AsstPrincipalCertificateNumber
	,le.AsstPrincipalStaffID
	,le.PrevAsstPrincipalStaffID
	,CASE
		WHEN s_prinprev.CertificateNumber IS NOT NULL
		THEN
			CASE WHEN s_prin.CertificateNumber = s_prinprev.CertificateNumber THEN 1 ELSE 0 END
		ELSE
			NULL
	END AS SamePrincipalFlag
	,CASE
		WHEN s_asstprinprev.CertificateNumber IS NOT NULL
		THEN
			CASE WHEN s_asstprin.CertificateNumber = s_asstprinprev.CertificateNumber THEN 1 ELSE 0 END
		ELSE
			NULL
	END AS SameAsstPrincipalFlag
	,CASE WHEN s_prin.CertificateNumber = s_asstprinprev.CertificateNumber THEN 1 ELSE 0 END AS PromotionFlag
	,GETDATE() as MetaCreatedAt
from LeadershipWithPrevious le
left join Dim_staff s_prin
	ON le.PrincipalStaffID = s_prin.StaffID
left join Dim_staff s_prinprev
	ON le.PrevPrincipalStaffID = s_prinprev.StaffID
left join Dim_staff s_asstprin
	ON le.AsstPrincipalStaffID = s_asstprin.StaffID
left join Dim_staff s_asstprinprev
	ON le.PrevAsstPrincipalStaffID = s_asstprinprev.StaffID
order by
	le.CountyAndDistrictCode, le.Building, le.AcademicYear;

-- next

UPDATE Fact_SchoolLeadership
SET
	LeadershipChangeFlag = CASE WHEN SamePrincipalFlag = 0 OR SameAsstPrincipalFlag = 0 THEN 1 ELSE 0 END

-- next

-----------------------------
-- Calculate Principal Tenure
-----------------------------

DROP TABLE IF EXISTS PrincipalTenure;

-- next

CREATE TABLE PrincipalTenure (
	SchoolLeadershipID INT,
	Tenure SMALLINT
);

-- next

INSERT INTO PrincipalTenure
select
	SchoolLeadershipID
	-- this is a count of cumulative years spent at the school.
	-- it does NOT handle gaps in tenure (e.g. person starts begin a principal in 2014,
	-- goes elsewhere for 2015, returns in 2016. The row for 2016 will have Tenure = 2)
	,row_number() over (partition by CountyAndDistrictCode, Building, PrincipalCertificateNumber ORDER BY AcademicYear) AS Tenure
FROM Fact_SchoolLeadership;

-- next

CREATE UNIQUE INDEX idx_PrincipalTenure ON PrincipalTenure (SchoolLeadershipID);

-- next

UPDATE Fact_SchoolLeadership
SET PrincipalTenure = (
	SELECT
		Tenure
	FROM PrincipalTenure WHERE PrincipalTenure.SchoolLeadershipID = Fact_SchoolLeadership.SchoolLeadershipID
	);

-- next

DROP TABLE IF EXISTS PrincipalTenure;

-- next

DROP TABLE IF EXISTS AsstPrincipalTenure;

-- next

-----------------------------
-- Calculate Assistant Principal Tenure
-----------------------------

CREATE TABLE AsstPrincipalTenure (
	SchoolLeadershipID INT,
	Tenure SMALLINT
);

-- next

INSERT INTO AsstPrincipalTenure
select
	SchoolLeadershipID
	-- this is a count of cumulative years spent at the school.
	-- it does NOT handle gaps in tenure (e.g. person starts begin a principal in 2014,
	-- goes elsewhere for 2015, returns in 2016. The row for 2016 will have Tenure = 2)
	,row_number() over (partition by CountyAndDistrictCode, Building, AsstPrincipalCertificateNumber ORDER BY AcademicYear) AS Tenure
FROM Fact_SchoolLeadership;

-- next

CREATE UNIQUE INDEX idx_AsstPrincipalTenure ON AsstPrincipalTenure (SchoolLeadershipID);

-- next

UPDATE Fact_SchoolLeadership
SET AsstPrincipalTenure = (
	SELECT
		Tenure
	FROM AsstPrincipalTenure WHERE AsstPrincipalTenure.SchoolLeadershipID = Fact_SchoolLeadership.SchoolLeadershipID
	);

-- next

DROP TABLE IF EXISTS AsstPrincipalTenure;

-- next

-----------------------------
-- Calculate teacher retention
-----------------------------

DROP TABLE IF EXISTS TeacherRetentionForLeadership;

-- next

-- there's another TeacherRetention elsewhere in pipeline, so use more distinctive name
CREATE TABLE TeacherRetentionForLeadership (
	CohortYear SMALLINT
	,Period SMALLINT
	,CohortCountyAndDistrictCode VARCHAR(10)
	,CohortBuilding VARCHAR(10)
	,SubGroup VARCHAR(20)
	,Stayed INT
);

-- next

;WITH t AS (

	select
		CohortYear
		,EndYear - CohortYear as Period
		,CohortCountyAndDistrictCode
		,CohortBuilding
		,'All' AS SubGroup
		,Sum(StayedInSchool) as Stayed
	from Fact_TeacherCohortMobility tcm
	JOIN Dim_Staff s
		ON tcm.CohortStaffID = s.StaffID
	where
		EndYear - CohortYear <= 4
	GROUP BY
		CohortYear, EndYear, CohortCountyAndDistrictCode, CohortBuilding

	UNION ALL

	select
		CohortYear
		,EndYear - CohortYear as Period
		,CohortCountyAndDistrictCode
		,CohortBuilding
		,'Person of Color' AS SubGroup
		,Sum(StayedInSchool) as Stayed
	from Fact_TeacherCohortMobility tcm
	JOIN Dim_Staff s
		ON tcm.CohortStaffID = s.StaffID
	where
		EndYear - CohortYear <= 4
		AND PersonOfColorCategory = 'Person of Color'
	GROUP BY
		CohortYear, EndYear, CohortCountyAndDistrictCode, CohortBuilding

)
INSERT INTO TeacherRetentionForLeadership (
	CohortYear
	,Period
	,CohortCountyAndDistrictCode
	,CohortBuilding
	,SubGroup
	,Stayed
)
select
	CohortYear
	,Period
	,CohortCountyAndDistrictCode
	,CohortBuilding
	,SubGroup
	,Stayed
from t;

-- next

-- both for speed and correctness

CREATE UNIQUE INDEX idx_Teacher_Retention ON TeacherRetentionForLeadership (
	CohortYear
	,Period
	,CohortCountyAndDistrictCode
	,CohortBuilding
	,SubGroup
);

-- next

UPDATE Fact_SchoolLeadership
SET
	TeacherRetention1Yr = (
		SELECT Stayed
		FROM TeacherRetentionForLeadership
		WHERE
			Period = 1
			AND Subgroup = 'All'
			AND Fact_SchoolLeadership.AcademicYear = TeacherRetentionForLeadership.CohortYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = TeacherRetentionForLeadership.CohortCountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = TeacherRetentionForLeadership.CohortBuilding
	)
	,TeacherRetention2Yr = (
		SELECT Stayed
		FROM TeacherRetentionForLeadership
		WHERE
			Period = 2
			AND Subgroup = 'All'
			AND Fact_SchoolLeadership.AcademicYear = TeacherRetentionForLeadership.CohortYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = TeacherRetentionForLeadership.CohortCountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = TeacherRetentionForLeadership.CohortBuilding
	)
	,TeacherRetention3Yr = (
		SELECT Stayed
		FROM TeacherRetentionForLeadership
		WHERE
			Period = 3
			AND Subgroup = 'All'
			AND Fact_SchoolLeadership.AcademicYear = TeacherRetentionForLeadership.CohortYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = TeacherRetentionForLeadership.CohortCountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = TeacherRetentionForLeadership.CohortBuilding
	)
	,TeacherRetention4Yr = (
		SELECT Stayed
		FROM TeacherRetentionForLeadership
		WHERE
			Period = 4
			AND Subgroup = 'All'
			AND Fact_SchoolLeadership.AcademicYear = TeacherRetentionForLeadership.CohortYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = TeacherRetentionForLeadership.CohortCountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = TeacherRetentionForLeadership.CohortBuilding
	)
	,TeacherOfColorRetention1Yr = (
		SELECT Stayed
		FROM TeacherRetentionForLeadership
		WHERE
			Period = 1
			AND Subgroup = 'Person of Color'
			AND Fact_SchoolLeadership.AcademicYear = TeacherRetentionForLeadership.CohortYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = TeacherRetentionForLeadership.CohortCountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = TeacherRetentionForLeadership.CohortBuilding
	)
	,TeacherOfColorRetention2Yr = (
		SELECT Stayed
		FROM TeacherRetentionForLeadership
		WHERE
			Period = 2
			AND Subgroup = 'Person of Color'
			AND Fact_SchoolLeadership.AcademicYear = TeacherRetentionForLeadership.CohortYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = TeacherRetentionForLeadership.CohortCountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = TeacherRetentionForLeadership.CohortBuilding
	)
	,TeacherOfColorRetention3Yr = (
		SELECT Stayed
		FROM TeacherRetentionForLeadership
		WHERE
			Period = 3
			AND Subgroup = 'Person of Color'
			AND Fact_SchoolLeadership.AcademicYear = TeacherRetentionForLeadership.CohortYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = TeacherRetentionForLeadership.CohortCountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = TeacherRetentionForLeadership.CohortBuilding
	)
	,TeacherOfColorRetention4Yr = (
		SELECT Stayed
		FROM TeacherRetentionForLeadership
		WHERE
			Period = 4
			AND Subgroup = 'Person of Color'
			AND Fact_SchoolLeadership.AcademicYear = TeacherRetentionForLeadership.CohortYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = TeacherRetentionForLeadership.CohortCountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = TeacherRetentionForLeadership.CohortBuilding
	)
;

-- next

DROP TABLE TeacherRetentionForLeadership;

-- next

-- we already calculate TotalTeachers, TeachersOfColor in Dim_School so copy those here for convenience.
-- we can't roll up totals from Fact_TeacherCohortMobility b/c it won't have the latest year

UPDATE Fact_SchoolLeadership
SET
	TeacherCount = (
		SELECT TotalTeachers
		FROM Dim_School
		WHERE
			Fact_SchoolLeadership.AcademicYear = Dim_School.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = Dim_School.DistrictCode
			AND Fact_SchoolLeadership.Building = Dim_School.SchoolCode
	)
	,TeacherOfColorCount = (
		SELECT TeachersOfColor
		FROM Dim_School
		WHERE
			Fact_SchoolLeadership.AcademicYear = Dim_School.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = Dim_School.DistrictCode
			AND Fact_SchoolLeadership.Building = Dim_School.SchoolCode
	)
;

-- next

UPDATE Fact_SchoolLeadership
SET
	TeacherRetention1YrPct = CASE WHEN TeacherCount > 0 THEN CAST(TeacherRetention1Yr AS REAL) / TeacherCount END,
	TeacherRetention2YrPct = CASE WHEN TeacherCount > 0 THEN CAST(TeacherRetention2Yr AS REAL) / TeacherCount END,
	TeacherRetention3YrPct = CASE WHEN TeacherCount > 0 THEN CAST(TeacherRetention3Yr AS REAL) / TeacherCount END,
	TeacherRetention4YrPct = CASE WHEN TeacherCount > 0 THEN CAST(TeacherRetention4Yr AS REAL) / TeacherCount END,
	TeacherOfColorRetention1YrPct = CASE WHEN TeacherOfColorCount > 0 THEN CAST(TeacherOfColorRetention1Yr AS REAL) / TeacherOfColorCount END,
	TeacherOfColorRetention2YrPct = CASE WHEN TeacherOfColorCount > 0 THEN CAST(TeacherOfColorRetention2Yr AS REAL) / TeacherOfColorCount END,
	TeacherOfColorRetention3YrPct = CASE WHEN TeacherOfColorCount > 0 THEN CAST(TeacherOfColorRetention3Yr AS REAL) / TeacherOfColorCount END,
	TeacherOfColorRetention4YrPct = CASE WHEN TeacherOfColorCount > 0 THEN CAST(TeacherOfColorRetention4Yr AS REAL) / TeacherOfColorCount END
;
