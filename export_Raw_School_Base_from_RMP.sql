
-- this is the query to run in the CCER data warehouse to create input\raw_school_base.txt

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
INTO S275.dbo.Dim_School
FROM T
WHERE Ranked = 1;
