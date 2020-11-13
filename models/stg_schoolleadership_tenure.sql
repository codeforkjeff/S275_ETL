
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['SchoolLeadershipID'], unique=True) }}"
        ]
    })
}}

SELECT
	SchoolLeadershipID
	-- this is a count of cumulative years spent at the school.
	-- it does NOT handle gaps in tenure (e.g. person starts begin a principal in 2014,
	-- goes elsewhere for 2015, returns in 2016. The row for 2016 will have Tenure = 2)
	,row_number() over (partition by CountyAndDistrictCode, Building, PrincipalCertificateNumber ORDER BY AcademicYear) AS PrincipalTenure
	,row_number() over (partition by CountyAndDistrictCode, Building, AsstPrincipalCertificateNumber ORDER BY AcademicYear) AS AsstPrincipalTenure
FROM {{ ref('stg_schoolleadership') }}
