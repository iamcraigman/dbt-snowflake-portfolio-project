with int_customers as (
    select * from {{ ref('int_customers_cleaned') }}
),

int_subs as (
    select * from {{ ref('int_subscriptions_enriched') }}
),

conversion_cohorts as (
    select * from {{ ref('int_customer_conversions') }}
),

latest_sub as (
    select
        customer_id,
        plan_id,
        clear_mrr_amount,
        subscription_status,
        row_number() over (
            partition by customer_id 
            order by valid_from_date desc
        ) as rn
    from int_subs
),

final as (
    select
        c.customer_id,
        c.customer_email,
        c.is_valid_email_format,
        c.country_code,
        c.acquisition_channel_id,
        c.signed_up_at,
        coalesce(ls.plan_id, 'unsubscribed') as current_plan_id,
        coalesce(ls.subscription_status, 'inactive') as current_status,
        coalesce(ls.clear_mrr_amount, 0.00) as current_mrr,
        coalesce(ch.trial_conversion_cohort, 'Unknown') as trial_conversion_cohort
    from int_customers c
    left join latest_sub ls 
        on c.customer_id = ls.customer_id and ls.rn = 1
    left join conversion_cohorts ch
        on c.customer_id = ch.customer_id
)

select * from final