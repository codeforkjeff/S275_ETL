
{{
    config({
        "pre-hook": [
            "DROP INDEX IF EXISTS idx_stg_dim_staff_flags"
        ]
        ,"post-hook": [
            """
            CREATE UNIQUE INDEX idx_stg_dim_staff_flags ON stg_dim_staff_flags (
                StaffID
            )
            """
        ]
    })
}}

select
    s.StaffID,
    max(IsTeachingAssignment) as IsTeacherFlag,
    max(IsPrincipalAssignment) as IsPrincipalFlag,
    max(IsAsstPrincipalAssignment) as IsAsstPrincipalFlag
FROM {{ ref('stg_dim_staff') }} s
JOIN {{ ref('fact_assignment') }} a
    ON s.StaffID = a.StaffID
group by s.StaffID
