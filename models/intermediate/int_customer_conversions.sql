with subscriptions as (
    select * from {{ ref('stg_subscription_platform__subscriptions') }}
),

ordered_history as (
    select
        customer_id,
        subscription_plan,
        subscription_status,
        valid_from_date,
        valid_to_date,
        -- Find the user's very first plan tier
        first_value(subscription_plan) over (
            partition by customer_id 
            order by valid_from_date asc
            rows between unbounded preceding and unbounded following
        ) as initial_plan,
        -- Get the plan details of their NEXT chronological subscription state
        lead(subscription_plan) over (
            partition by customer_id 
            order by valid_from_date asc
        ) as next_plan,
        lead(subscription_status) over (
            partition by customer_id 
            order by valid_from_date asc
        ) as next_status,
        -- Row number to isolate their first lifecycle event block
        row_number() over (
            partition by customer_id 
            order by valid_from_date asc
        ) as event_sequence
    from subscriptions
),

conversions_calculated as (
    select
        customer_id,
        initial_plan,
        next_plan,
        next_status,
        case
            -- Scenario 1: Initial plan was a free trial, and the next record shows a valid plan upgrade
            when initial_plan in ('Free / Trial', 'Trial', 'Basic') and next_plan in ('Pro', 'Enterprise') then 'Trial Upgraded'
            -- Scenario 2: Initial plan was a trial, and the next record flags a cancellation status
            when initial_plan in ('Free / Trial', 'Trial') and next_status = 'cancelled' then 'Trial Cancelled'
            -- Scenario 3: Ongoing or signed up directly to a paid tier
            else 'Direct Sign-up / Active'
        end as trial_conversion_cohort
    from ordered_history
    where event_sequence = 1
)

select * from conversions_calculated