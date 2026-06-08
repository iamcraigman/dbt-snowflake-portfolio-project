with source as (
    select * from {{ source('subscription_platform', 'raw_plans') }}
),

staged as (
    select
        cast(plan_id as string) as plan_id,
        upper(trim(plan_name)) as plan_name,
        cast(tier_level as int64) as tier_level
    from source
)

select * from staged