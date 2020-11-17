
{{
    config({
        "pre-hook": [
            "{{ drop_index(1) }}"
        ]
        ,"post-hook": [
            "{{ create_index(1, ['StaffID'], unique=True) }}"
        ]
    })
}}

select
    s.StaffID,
    max(IsTeachingAssignment) as IsTeacherFlag,
    max(IsPrincipalAssignment) as IsPrincipalFlag,
    max(IsAsstPrincipalAssignment) as IsAsstPrincipalFlag
FROM {{ ref('stg_dim_staff') }} s
JOIN {{ ref('Fact_Assignment') }} a
    ON s.StaffID = a.StaffID
group by s.StaffID
