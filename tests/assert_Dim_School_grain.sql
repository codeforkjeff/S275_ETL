
select AcademicYear, DistrictCode, SchoolCode
from {{ ref('Dim_School') }}
group by AcademicYear, DistrictCode, SchoolCode
having count(*) > 1
