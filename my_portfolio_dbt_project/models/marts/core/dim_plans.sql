with source as (
    select * from {{ ref('raw_plans') }} -- Directly referencing seed for lookup
),

staged as (
    select
        cast(plan_id as string) as plan_id,
        upper(trim(plan_name)) as plan_name,
        cast(tier_level as int64) as tier_level
    from source
)

select * from staged