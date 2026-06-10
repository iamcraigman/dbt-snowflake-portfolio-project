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
        -- Find the user's very first staus
        first_value(subscription_status) over (
            partition by customer_id 
            order by valid_from_date asc
            rows between unbounded preceding and unbounded following
        ) as initial_status,
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
        initial_status,
        next_plan,
        next_status,
        case
            -- Scenario 1: Initial plan was a free trial, and the next record shows a valid plan upgrade
            when initial_plan in ('Trial') and next_plan in ('Pro', 'Enterprise', 'Basic') then 'Trial Upgraded'
            -- Scenario 2: Initial plan was a trial, and the intial record flags a cancellation subscription_status
            when initial_plan in ('Trial') and initial_status = 'cancelled' then 'Trial Cancelled'
            -- Scenario 3: Initial plan is a trial, but there is no next event yet (Ongoing trial)
            when initial_plan in ('Trial') and next_plan is null then 'Active Trial'
            -- Scenario 4: Ongoing or signed up directly to a paid tier
            else 'Direct Sign-up'
        end as trial_conversion_cohort
    from ordered_history
    where event_sequence = 1
)

select * from conversions_calculated