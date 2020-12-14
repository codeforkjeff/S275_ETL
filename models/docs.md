{% docs __S275__ %}

## Dimensional Modeling

The `Dim_` and `Fact_` tables use [dimensional modeling](https://www.kimballgroup.com/2003/01/fact-tables-and-dimension-tables/).
We follow this method so that the reporting tables can be reused for many
types of research and reporting questions and so that what each table represents
is clear and concise.

Note that AcademicYear values are based on the "end year": e.g. 2016 means 2015-2016.

## Base Tables

These are broadly useful tables, with high fidelity to the "upstream" source data.

```
S275
Dim_Staff
Dim_School
Fact_Assignment
Fact_SchoolTeacher
Fact_SchoolPrincipal
```

## Tables using College of Ed logic

These were created specifically to reproduce the work from the College of Ed.

```
Fact_TeacherMobility
Fact_PrincipalMobility
```

## Cohort Tables

These were created to enable analysis of what happens to individuals from a starting
cohort year to each subsequent year. These are more "general purpose" (from a CCER
standpoint) than the COE tables above.

```
Fact_TeacherCohort
Fact_TeacherCohortMobility
Fact_PrincipalCohort
Fact_PrincipalCohortMobility
```

{% enddocs %}

{% docs Dim_Staff %}

Dimension table for a staff person in a given year and district.
This is the grain because a person can be employed by more than one district
in an academic year.

PK = AcademicYear, CountyAndDistrictCode, CertificateNumber

{% enddocs %}

{% docs Dim_School %}

Dimension table for school in an academic year.

PK = AcademicYear, DistrictCode, SchoolCode. DistrictCode is part of the PK b/c there
are a small number of cases where the same SchoolCode is used across districts,
often for administrative units.

{% enddocs %}

{% docs Fact_Assignment %}

An assignment line item. This table is at the same grain as the rows in the original
S275 data. Personnel can (and often do) have multiple assignments within the district
they're employed by, and multiple assignments within a given school building.

PK = StaffID (key into Dim_Staff), RecordNumber

{% enddocs %}

{% docs Fact_SchoolTeacher %}

Teachers at schools. This table rolls up from assignments, so a row sums the Percentage, FTEDesignation,
and Salary fields per teacher/school/year. The PrimaryFlag field is used to support a single school
selection for each teacher/year for reports that want to avoid double counting.

PK = StaffID (key into Dim_Staff), Building

{% enddocs %}

{% docs Fact_SchoolPrincipal %}

Table of all principals and assistant principals at all the schools where they served.

PK = StaffID (key into Dim_Staff), Building, PrincipalType

{% enddocs %}

{% docs Fact_TeacherMobility %}

Created to reproduce College of Ed work.

Mobility of teachers from their "primary" school (only one school per year), calculated
both year over year and at 5 year snapshots, with flag fields describing the transitions.

PK = StartYear, EndYear, CertificateNumber

{% enddocs %}

{% docs Fact_PrincipalMobility %}

Created to reproduce College of Ed work.

Mobility of principals from their "primary" school (only one school per year),
calculated both year over year and at 5 year snapshots.

PK = StartYear, EndYear, CertificateNumber

{% enddocs %}

{% docs Fact_TeacherCohort %}

Cohort table containining teachers for each year.

PK = CohortYear, CertificateNumber

{% enddocs %}

{% docs Fact_TeacherCohortMobility %}

Mobility of teachers from their `CohortYear` to each successive `EndYear`
up to the present. The flag fields describe the transitions between `CohortYear`
and `EndYear`.

It's easier to do rollups on the flag fields using this table rather than
`Fact_TeacherMobility`: because the latter doesn't contain every CohortYear/EndYear combo,
the counts won't add up for a given combo because 'exited' isn't represented.

PK = CohortYear, EndYear, CertificateNumber

{% enddocs %}

{% docs Fact_PrincipalCohort %}

Cohort table containing principals and assistant principals.

PK = CohortYear, CertificateNumber

{% enddocs %}

{% docs Fact_PrincipalCohortMobility %}

Mobility of principals and asst principals from their `CohortYear` to each
successive `EndYear` up to the present. The flag fields describe the transitions
between `CohortYear` and `EndYear`.

It's easier to do rollups on the flag fields using this table rather than
`Fact_PrincipalMobility`: because the latter doesn't contain every CohortYear/EndYear combo,
the counts won't add up for a given combo because 'exited' isn't represented.

PK = CohortYear, EndYear, CertificateNumber

{% enddocs %}
