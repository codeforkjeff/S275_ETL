
SELECT a.*,x.DistrictName,x.SchoolName,x.dRoadMapRegionFlag,x.GradeSpan,x.ElementarySchoolFlag,x.HighSchoolFlag,x.MiddleSchoolFlag 
INTO [SandBox].[dbo].s275_stateh_sch_17
FROM [SandBox].[dbo].[s275_state_hfinal17] a
LEFT JOIN (SELECT *
			FROM [DataHub].[dbo].[vw_K12Schools]
			WHERE AcademicYear = '2017') x
ON a.codist = x.DistrictCode and a.bldgn = x.BuildingID

