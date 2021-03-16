
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['AcademicYear', 'DistrictCode', 'SchoolCode'], unique=True) }}"
        ]
    })
}}

SELECT
    CAST(AcademicYear AS {{ t_int() }}) AS AcademicYear, -- TODO: NOT NULL,
    CAST(DistrictCode AS {{ t_varchar(8) }}) AS DistrictCode,
    CAST(DistrictName AS {{ t_varchar(250) }}) AS DistrictName,
    CAST(SchoolCode AS {{ t_varchar(8) }}) AS SchoolCode,
    CAST(SchoolName AS {{ t_varchar(250) }}) AS SchoolName,
        -- attributes
    CAST(TotalEnrollmentOct AS {{ t_smallint() }}) AS TotalEnrollmentOct,
    CAST(GraduationMet AS {{ t_smallint() }}) AS GraduationMet,
    CAST(GraduationTotal AS {{ t_smallint() }}) AS GraduationTotal,
    CAST(GraduationPercent AS {{ t_numeric(9,4) }}) AS GraduationPercent,
    CAST(FRPL AS {{ t_smallint() }}) AS FRPL,
    CAST(FRPLPercent AS {{ t_numeric(10,2) }}) AS FRPLPercent,
    CAST(AmIndOrAlaskan AS {{ t_smallint() }}) AS AmIndOrAlaskan,
    CAST(AmIndOrAlaskanPercent AS {{ t_numeric(10,2) }}) AS AmIndOrAlaskanPercent,
    CAST(Asian AS {{ t_smallint() }}) AS Asian,
    CAST(AsianPercent AS {{ t_numeric(10,2) }}) AS AsianPercent,
    CAST(PacIsl AS {{ t_smallint() }}) AS PacIsl,
    CAST(PacIslPercent AS {{ t_numeric(10,2) }}) AS PacIslPercent,
    CAST(AsPacIsl AS {{ t_smallint() }}) AS AsPacIsl,
    CAST(AsPacIslPercent AS {{ t_numeric(10,2) }}) AS AsPacIslPercent,
    CAST(Black AS {{ t_smallint() }}) AS Black,
    CAST(BlackPercent AS {{ t_numeric(10,2) }}) AS BlackPercent,
    CAST(Hispanic AS {{ t_smallint() }}) AS Hispanic,
    CAST(HispanicPercent AS {{ t_numeric(10,2) }}) AS HispanicPercent,
    CAST(White AS {{ t_smallint() }}) AS White,
    CAST(WhitePercent AS {{ t_numeric(10,2) }}) AS WhitePercent,
    CAST(TwoOrMoreRaces AS {{ t_smallint() }}) AS TwoOrMoreRaces,
    CAST(TwoOrMoreRacesPercent AS {{ t_numeric(10,2) }}) AS TwoOrMoreRacesPercent,
    CAST(Male AS {{ t_smallint() }}) AS Male,
    CAST(MalePercent AS {{ t_numeric(10,2) }}) AS MalePercent,
    CAST(Female AS {{ t_smallint() }}) AS Female,
    CAST(FemalePercent AS {{ t_numeric(10,2) }}) AS FemalePercent,
    CAST(GenderX AS {{ t_smallint() }}) AS GenderX,
    CAST(GenderXPercent AS {{ t_numeric(10,2) }}) AS GenderXPercent
FROM {{ source('sources', 'Raw_School_Fields') }}
