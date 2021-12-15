
-- this is here for legacy reasons: in the RMP data warehouse, use
-- the Exports.S275_Dim_School_Fields view

WITH T AS (
    -- there's 53 rows with duplicate schoolcodes b/c of bad data quality;
    -- we arbitrarily order by districtcode to de-dupe these
    SELECT
        *
        ,ROW_NUMBER() OVER (PARTITION BY SchoolCode, AcademicYear
            ORDER BY DistrictCode) AS Ranked
    FROM Dim.School
)
SELECT
    T.AcademicYear
    ,T.DistrictCode
    ,T.DistrictName
    ,T.SchoolCode
    ,T.SchoolName
    ,GradeLevelStart
    ,GradeLevelEnd
    ,GradeLevelSortOrderStart
    ,GradeLevelSortOrderEnd
    ,SchoolType
    ,Lat
    ,Long
    ,NCESLocaleCode
    ,NCESLocale
    ,dRoadMapRegionFlag AS RMRFlag
INTO S275.dbo.Raw_School_Base
FROM T
WHERE Ranked = 1
