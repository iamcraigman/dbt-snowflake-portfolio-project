with source as (
    select * from {{ source('subscription_platform', 'raw_marketing_channels') }}
),

staged as (
    select
        cast(channel_id as string) as channel_id,
        upper(trim(channel_name)) as channel_name,
        upper(trim(channel_type)) as channel_type
    from source
)

select * from staged