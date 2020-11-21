
-- exactly one of these flags should be set

select *
from {{ ref('Fact_TeacherCohortMobility') }}
where
    (
        StayedInSchool
        + ChangedBuildingStayedDistrict
        + ChangedRoleStayedDistrict
        + MovedOutDistrict
        + Exited
    ) <> 1
