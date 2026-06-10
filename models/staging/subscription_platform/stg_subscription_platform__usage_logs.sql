with source as (
    select * from {{ source('subscription_platform', 'raw_usage_logs') }}
),

staged as (
    select
        cast(event_id as string) as log_id,
        cast(customer_id as string) as customer_id,
        cast(event_timestamp as timestamp) as event_at,
        lower(trim(action)) as event_action,
        lower(trim(feature_used)) as feature_name
    from source
)

select * from staged