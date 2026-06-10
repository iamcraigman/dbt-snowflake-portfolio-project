with source as (
    select * from {{ ref('raw_marketing_channels') }} -- Directly referencing seed for lookup
),

staged as (
    select
        cast(channel_id as string) as channel_id,
        upper(trim(channel_name)) as channel_name,
        upper(trim(channel_type)) as channel_type
    from source
)

select * from staged