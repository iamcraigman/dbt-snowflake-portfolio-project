with stg_subscriptions as (
    select * from {{ ref('stg_subscription_platform__subscriptions') }}
),

ref_plans as (
    select * from {{ ref('raw_plans') }}
),

ref_pricing as (
    select * from {{ ref('raw_plan_pricing_history') }}
),

joined as (
    select
        s.subscription_id,
        s.customer_id,
        p.plan_id,
        pr.price_id,
        s.subscription_status,
        s.valid_from_date,
        s.valid_to_date,
        -- Pull pricing from the historical pricing matrix based on the date boundary context
        coalesce(s.mrr_amount, pr.monthly_amount) as clear_mrr_amount
    from stg_subscriptions s
    left join ref_plans p 
        on s.subscription_plan = p.plan_name
    left join ref_pricing pr 
        on p.plan_id = pr.plan_id
        and s.valid_from_date >= pr.valid_from
        and (s.valid_from_date < pr.valid_to or pr.valid_to is null)
)

select * from joined