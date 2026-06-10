with stg_customers as (
    select * from {{ ref('stg_subscription_platform__customers') }}
),

ref_marketing as (
    select * from {{ ref('raw_marketing_channels') }} -- Directly referencing seed for lookup
),

joined as (
    select
        c.customer_id,
        c.customer_email,
        c.country_code,
        c.signed_up_at,
        m.channel_id as acquisition_channel_id,
        -- Utilizing your custom macro execution here
        {{ validate_email('c.customer_email') }} as is_valid_email_format
    from stg_customers c
    left join ref_marketing m 
        on c.acquisition_channel = m.channel_name
)

select * from joined