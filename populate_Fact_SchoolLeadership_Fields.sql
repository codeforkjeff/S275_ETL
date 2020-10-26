
UPDATE Fact_SchoolLeadership
SET
	AllPrincipalCertList = (
		SELECT AllPrincipalCertList
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
	,AnyPrincipalPOC = (
		SELECT AnyPrincipalPOC
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
	,AllAsstPrinCertList = (
		SELECT AllAsstPrinCertList
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
	,AnyAsstPrinPOC = (
		SELECT AnyAsstPrinPOC
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
	,BroadLeadershipChangeFlag = (
		SELECT BroadLeadershipChangeFlag
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
	,BroadLeadershipGainedPrincipalPOCFlag = (
		SELECT BroadLeadershipGainedPrincipalPOCFlag
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
	,BroadLeadershipGainedAsstPrinPOCFlag = (
		SELECT BroadLeadershipGainedAsstPrinPOCFlag
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
	,BroadLeadershipGainedPOCFlag = (
		SELECT BroadLeadershipGainedPOCFlag
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
	,BroadLeadershipLostPrincipalPOCFlag = (
		SELECT BroadLeadershipLostPrincipalPOCFlag
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
	,BroadLeadershipLostAsstPrinPOCFlag = (
		SELECT BroadLeadershipLostAsstPrinPOCFlag
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
	,BroadLeadershipLostPOCFlag = (
		SELECT BroadLeadershipLostPOCFlag
		FROM Fact_SchoolLeadership_Fields f
		WHERE
			Fact_SchoolLeadership.AcademicYear = f.AcademicYear
			AND Fact_SchoolLeadership.CountyAndDistrictCode = f.CountyAndDistrictCode
			AND Fact_SchoolLeadership.Building = f.Building
	)
;
