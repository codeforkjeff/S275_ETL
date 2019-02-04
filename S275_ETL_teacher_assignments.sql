-- DROP TABLE IF EXISTS SandBox.dbo.s275_teacher_assignments;

-- Create a table of teacher assignments: each row is a teacher at a building,
-- with aggregations for pctass, ftetotal, saltotal

DROP TABLE IF EXISTS #teachers;

SELECT
	AcademicYear = CONVERT(int,RIGHT(schoolyear,4))
	,Area = RTRIM(area)
	,County = RTRIM(cou)
	,DistrictCode = RTRIM(dis)
	,CountyAndDistrictCode = RTRIM(codist)
	,LastName = NULLIF(RTRIM(LastName), '')
	,FirstName = NULLIF(RTRIM(FirstName), '')
	,MiddleName = NULLIF(RTRIM(MiddleName), '')
	,CertificateNumber = RTRIM(cert)
	,Birthdate = RTRIM(bdate)
	--,[byr] not in 2018 file
	--,[bmo] not in 2018 file
	--,[bday] not in 2018 file
	,Sex = RTRIM(sex)
	,Hispanic = NULLIF(RTRIM(hispanic), '')
	,Race = NULLIF(RTRIM(race), '')
	,HighestDegree = NULLIF(RTRIM(hdeg), '')
	,HighestDegreeYear = NULLIF(RTRIM(hyear), '')
	,AcademicCredits = RTRIM(acred)
	,InServiceCredits = RTRIM(icred)
	,ExcessCredits = RTRIM(bcred)
	,NonDegreeCredits = RTRIM(vcred)
	,CertYearsOfExperience = RTRIM(exp)
	,StaffMixFactor = RTRIM(camix1)
	,FTEHours = RTRIM(ftehrs)
	,FTEDays = RTRIM(ftedays)
	,CertificatedFTE = RTRIM(certfte)
	,ClassifiedFTE = RTRIM(clasfte)
	,CertificatedBase = RTRIM(certbase)
	,ClassifiedBase = RTRIM(clasbase)
	,OtherSalary = RTRIM(othersal)
	,TotalFinalSalary = RTRIM(tfinsal)
	,ActualAnnualInsurance = RTRIM(cins)
	,ActualAnnualMandatory = RTRIM(cman)
	,CBRTNCode = RTRIM(cbrtn)
	,ClassificationFlag = RTRIM(clasflag)
	,CertifiedFlag = RTRIM(certflag)
	--      ,[ceridate]
	,ActivityCode = RTRIM(act)
	,DutyRoot = NULLIF(RTRIM(droot), '')
	,Building = RTRIM(bldgn)
	,AssignmentPercent = CONVERT(NUMERIC(14, 4), asspct)
	,AssignmentFTEDesignation = CONVERT(NUMERIC(14, 4), assfte)
	,AssignmentSalaryTotal = CONVERT(INT, asssal)
INTO #teachers
FROM SandBox.dbo.S275
  -- droot = 31-34 duty root codes for teachers
  -- act = 27 is activity code for teachers
WHERE
	droot IN (31,32,33,34)
	AND act ='27'
	AND area = 'L'


-- Fix known data issues
UPDATE #teachers SET HighestDegreeYear = 2007 WHERE HighestDegreeYear = '07';
UPDATE #teachers SET HighestDegreeYear = 2013 WHERE HighestDegreeYear = '13';
UPDATE #teachers SET HighestDegreeYear = NULL WHERE HighestDegreeYear = 'B0';

;WITH TeacherAssignments AS (
    SELECT 
		AcademicYear
		,Area
		,County
		,DistrictCode
		,CountyAndDistrictCode
		,LastName
		,FirstName
		,MiddleName
		,CertificateNumber
		,Birthdate
		,Sex
		,Hispanic
		,Race
		,RaceEthOSPI =
		CASE
			WHEN Hispanic = 'Y' THEN 'Hispanic/Latino of any race(s)'
			WHEN LEN(LTRIM(RTRIM(Race))) > 1 THEN 'Two or More Races'
			ELSE
				CASE LTRIM(RTRIM(COALESCE(Race, '')))
					WHEN 'A' THEN 'Asian'
					WHEN 'W' THEN 'White'
					WHEN 'B' THEN 'Black/African American'
					WHEN 'P' THEN 'Native Hawaiian/Other Pacific Islander'
					WHEN 'I' THEN 'American Indian/Alaskan Native'
					WHEN '' THEN 'Not Provided'
					ELSE NULL -- should never happen
				END
		END
      ,HighestDegree
      ,HighestDegreeYear
      ,AcademicCredits
      ,InServiceCredits
      ,ExcessCredits
      ,NonDegreeCredits
      ,CertYearsOfExperience
      ,StaffMixFactor
      ,FTEHours
      ,FTEDays
      ,CertificatedFTE
      ,ClassifiedFTE
      ,CertificatedBase
      ,ClassifiedBase
      ,OtherSalary
      ,TotalFinalSalary
      ,ActualAnnualInsurance
      ,ActualAnnualMandatory
      ,CBRTNCode
      ,ClassificationFlag
      ,CertifiedFlag
      ,ActivityCode
      ,Building
      ,AssignmentPercent = SUM(AssignmentPercent)
      ,AssignmentFTEDesignation = SUM(AssignmentFTEDesignation)
      ,AssignmentSalaryTotal = SUM(AssignmentSalaryTotal)
  FROM #teachers
  GROUP BY 
		AcademicYear
		,Area
		,County
		,DistrictCode
		,CountyAndDistrictCode
		,LastName
		,FirstName
		,MiddleName
		,CertificateNumber
		,Birthdate
		,Sex
		,Hispanic
		,Race
		,HighestDegree
		,HighestDegreeYear
		,AcademicCredits
		,InServiceCredits
		,ExcessCredits
		,NonDegreeCredits
		,CertYearsOfExperience
		,StaffMixFactor
		,FTEHours
		,FTEDays
		,CertificatedFTE
		,ClassifiedFTE
		,CertificatedBase
		,ClassifiedBase
		,OtherSalary
		,TotalFinalSalary
		,ActualAnnualInsurance
		,ActualAnnualMandatory
		,CBRTNCode
		,ClassificationFlag
		,CertifiedFlag
		,ActivityCode
		,Building
)
SELECT *
INTO SandBox.dbo.s275_teacher_assignments
FROM TeacherAssignments
WHERE
	CertificateNumber IS NOT NULL
	AND AssignmentFTEDesignation > 0
