{% docs __S275__ %}

# S275 Project

This project does ELT for the S-275 school personnel data.

Below is a high-level "lay of the land" for the tables in this project.
Browse the individual tables for more detailed information.

## Dimensional Modeling

The `Dim_` and `Fact_` tables use [dimensional modeling](https://www.kimballgroup.com/2003/01/fact-tables-and-dimension-tables/).
We follow this method so that the reporting tables can be reused for many
types of research and reporting questions and so that what each table represents
is clear and concise.

Note that AcademicYear values are based on the "end year": e.g. 2016 means 2015-2016.

## Base Tables

These are broadly useful tables, with high fidelity to the upstream source data.

```
S275 - union of all the raw data, cleaned
Dim_Staff - "left side" set of fields from the raw data pertaining to employment at a district in a given AY
Fact_Assignment - "right side" set of fields from the raw data pertaining to assignments at schools

Dim_School - information about schools
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

{# ----------------------------- #}

{% docs Dim_Staff %}

Dimension table for a staff person in a given year and district.
This is the grain because a person can be employed by more than one district
in an academic year.

PK = AcademicYear, CountyAndDistrictCode, CertificateNumber

{% enddocs %}

{# ----------------------------- #}

{% docs Dim_School %}

Dimension table for school in an academic year.

Many fields in this table are from a join with `Raw_School_Fields` which
is populated with an extract from CCER's RMP database. Data in `Raw_School_Fields`
is optional, though, in which case the fields here will be null.

PK = AcademicYear, DistrictCode, SchoolCode. DistrictCode is part of the PK b/c there
are a small number of cases where the same SchoolCode is used across districts,
often for administrative units.

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_Assignment %}

An assignment line item. This table is at the same grain as the rows in the original
S275 data. Personnel can (and often do) have assignments across the multiple buildings
where they work, and multiple assignments within the same building.

PK = StaffID (key into Dim_Staff), RecordNumber

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_Career %}

This is a table that rolls up various aspects of a staff person's career. Currently
the attribute fields are focused on tracking teacher to asstprincipal/principal career
transitions, though it could be extended to look at other kinds of career trajectories
as well.

The grain is the individual. As such, there is no information in this table that pertains
to a specific year, although there are 'FirstYear' and 'LastYear' types of columns.

PK = CertificateNumber

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_SchoolTeacher %}

Teachers at schools. This table rolls up from assignments, so a row sums the Percentage, FTEDesignation,
and Salary fields per teacher/school/year. The PrimaryFlag field is used to support a single school
selection for each teacher/year for reports that want to avoid double counting.

PK = StaffID (key into Dim_Staff), Building

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_SchoolPrincipal %}

Table of all principals and assistant principals at all the schools where they served.

PrimaryFlag is set 1 for the assignment w/ highest FTE for the individual across all schools
where they serve, regardless of AP/Prinicpal role.

PrimaryForSchoolFlag is set to 1 for the assignment w/ the highest FTE at the building.

PK = StaffID (key into Dim_Staff), Building, PrincipalType

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_TeacherMobility %}

Created to reproduce College of Ed work.

Mobility of teachers from their "primary" school (only one school per year), calculated
both year over year and at 5 year snapshots, with flag fields describing the transitions.

PK = StartYear, EndYear, CertificateNumber

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_PrincipalMobility %}

Created to reproduce College of Ed work.

Mobility of principals from their "primary" school (only one school per year),
calculated both year over year and at 5 year snapshots.

PK = StartYear, EndYear, CertificateNumber

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_TeacherCohort %}

Cohort table containining teachers for each year.

PK = CohortYear, CertificateNumber

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_TeacherCohortMobility %}

Mobility of teachers from their `CohortYear` to each successive `EndYear`
up to the present. The flag fields describe the transitions between `CohortYear`
and `EndYear`.

This includes rows for CohortYear, EndYear pairs where the individual no longer
exists in the S-275 data. In these cases, they are considered Exited.

This is the main difference from `Fact_TeacherMobility` (an earlier table
created to reproduce COE work), which doesn't contain CohortYear/EndYear combos
for end years where individual is no longer in the data. So `Fact_TeacherCohortMobility`
makes it easier to do rollups on the flag fields with better completeness.

PK = CohortYear, EndYear, CertificateNumber

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_PrincipalCohort %}

Cohort table containing principals and assistant principals.

PK = CohortYear, CertificateNumber

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_PrincipalCohortMobility %}

Mobility of principals and asst principals from their `CohortYear` to each
successive `EndYear` up to the present. The flag fields describe the transitions
between `CohortYear` and `EndYear`.

It's easier to do rollups on the flag fields using this table rather than
`Fact_PrincipalMobility`: because the latter doesn't contain every CohortYear/EndYear combo,
the counts won't add up for a given combo because 'exited' isn't represented.

PK = CohortYear, EndYear, CertificateNumber

{% enddocs %}

{# ----------------------------- #}

{% docs Fact_SchoolLeadership %}

Table describing leadership at a school in a given year, and how it has changed from
the previous year in terms of POC composition. Fields with teacher retention are also included
in this table to enable correlation analysis.

A single individual is selected for the Principal and AsstPrincipal fields, but there are
sometimes more than one principal or AP at a school. The BroadLeadership fields consider
changes in the entire set of principals and APs.

PK = AcademicYear, CountyAndDistrictCode, Building

{% enddocs %}

{# ----------------------------- #}

{% docs S275 %}

This is all years of the S275 data, cleaned and with fields given more verbose names
for clarity.

{% enddocs %}
