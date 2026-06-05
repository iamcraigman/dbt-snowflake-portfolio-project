{{
  config(
    materialized='incremental',
    unique_key='subscription_id',
    incremental_strategy='merge'
  )
}}

with subscriptions as (
    select * from {{ ref('stg_subscription_platform__subscriptions') }}
),

final as (
    select
        subscription_id,
        customer_id,
        subscription_plan,
        mrr_amount,
        subscription_status,
        valid_from_date,
        coalesce(valid_to_date, current_date()) as valid_to_date,
        case 
            when subscription_status = 'active' then true 
            else false 
        end as is_currently_active
    from subscriptions
)

select * from final

-- The engine room of incremental loading:
{% if is_incremental() %}
  -- This filter will only run on subsequent executions
  where valid_from_date >= (select max(valid_from_date) from {{ this }})
{% endif %}