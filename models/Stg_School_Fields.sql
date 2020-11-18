
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
    CAST(AcademicYear AS int) AS AcademicYear, -- TODO: NOT NULL,
    CAST(DistrictCode AS varchar(8)) AS DistrictCode,
    CAST(DistrictName AS varchar(250)) AS DistrictName,
    CAST(SchoolCode AS varchar(8)) AS SchoolCode,
    CAST(SchoolName AS varchar(250)) AS SchoolName,
        -- attributes
    CAST(TotalEnrollmentOct AS smallint) AS TotalEnrollmentOct,
    CAST(GraduationMet AS smallint) AS GraduationMet,
    CAST(GraduationTotal AS smallint) AS GraduationTotal,
    CAST(GraduationPercent AS numeric(9,4)) AS GraduationPercent,
    CAST(FRPL AS smallint) AS FRPL,
    CAST(FRPLPercent AS numeric(10,2)) AS FRPLPercent,
    CAST(AmIndOrAlaskan AS smallint) AS AmIndOrAlaskan,
    CAST(AmIndOrAlaskanPercent AS numeric(10,2)) AS AmIndOrAlaskanPercent,
    CAST(Asian AS smallint) AS Asian,
    CAST(AsianPercent AS numeric(10,2)) AS AsianPercent,
    CAST(PacIsl AS smallint) AS PacIsl,
    CAST(PacIslPercent AS numeric(10,2)) AS PacIslPercent,
    CAST(AsPacIsl AS smallint) AS AsPacIsl,
    CAST(AsPacIslPercent AS numeric(10,2)) AS AsPacIslPercent,
    CAST(Black AS smallint) AS Black,
    CAST(BlackPercent AS numeric(10,2)) AS BlackPercent,
    CAST(Hispanic AS smallint) AS Hispanic,
    CAST(HispanicPercent AS numeric(10,2)) AS HispanicPercent,
    CAST(White AS smallint) AS White,
    CAST(WhitePercent AS numeric(10,2)) AS WhitePercent,
    CAST(TwoOrMoreRaces AS smallint) AS TwoOrMoreRaces,
    CAST(TwoOrMoreRacesPercent AS numeric(10,2)) AS TwoOrMoreRacesPercent,
    CAST(Male AS smallint) AS Male,
    CAST(MalePercent AS numeric(10,2)) AS MalePercent,
    CAST(Female AS smallint) AS Female,
    CAST(FemalePercent AS numeric(10,2)) AS FemalePercent,
    CAST(GenderX AS smallint) AS GenderX,
    CAST(GenderXPercent AS numeric(10,2)) AS GenderXPercent
FROM {{ source('sources', 'Raw_School_Fields') }}
