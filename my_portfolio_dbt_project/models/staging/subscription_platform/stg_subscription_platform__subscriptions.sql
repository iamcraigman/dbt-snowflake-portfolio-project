with source as (
    select * from {{ source('subscription_platform', 'raw_subscriptions') }}
),

staged as (
    select
        cast(subscription_id as string) as subscription_id,
        cast(customer_id as string) as customer_id,
        trim(plan_name) as subscription_plan,
        cast(monthly_amount as numeric) as mrr_amount,
        lower(trim(status)) as subscription_status,
        cast(start_date as date) as valid_from_date,
        cast(end_date as date) as valid_to_date
    from source
)

select * from staged