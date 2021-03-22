
-- this is the query to run to populate Raw_School_Base from an RMP database
-- in SQL Server. This needs to be done each academic year.
--
-- The resulting table should then be exported to input\raw_school_base.txt
-- so builds can load it from there.
--
-- Export-RmpTable -Database

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
