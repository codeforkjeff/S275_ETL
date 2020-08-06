
----------------------------------
-- Reproduces the "New Educator 3 Year Persistence" measure on the PESB website
----------------------------------

-- See https://www.pesb.wa.gov/resources-and-reports/monitoring-strategic-goals/goal-5
--
-- Note that there are some discrepancies:
--
-- 2012-2013 AY: due to messy data in the 'race' field in S275 data, PESB counts
--   a number of rows as POC whereas we count as White
--
-- 2015-2017 AY: persistent counts are slightly different; we count (Hispanic=NULL
--   and Race=White) as White educators

select
    p.CohortYear,
    p.CohortPersonOfColorCategory,
    count(*) as Hired,
    SUM(PersistedWithinWAFlag) as PersistentWithinWA,
	SUM(PersistedWithinWAFlag) / cast(count(*) as real) * 100 as Pct
from Fact_PESBEducatorPersistence p
where
    CohortBeginningEducatorFlag = 1
    and p.YearCount = 3
    AND p.CohortYear >= 2011
    AND p.CohortYear <= 2017
GROUP BY
    p.CohortYear,
    p.YearCount,
    p.CohortPersonOfColorCategory
ORDER BY
    p.CohortYear,
    p.YearCount,
    p.CohortPersonOfColorCategory
