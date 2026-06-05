with source as (
    select * from {{ source('subscription_platform', 'raw_customers') }}
),

staged as (
    select
        cast(customer_id as string) as customer_id,
        cast(signup_at as timestamp) as signed_up_at,
        lower(trim(email)) as customer_email,
        upper(trim(country)) as country_code,
        trim(marketing_channel) as acquisition_channel
    from source
)

select * from staged