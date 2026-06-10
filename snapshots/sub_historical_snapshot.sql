{% snapshot sub_historical_snapshot %}

{{
    config(
      target_database='dbt-bigquery-portfolio-project',
      target_schema='project_data',
      unique_key='subscription_id',
      strategy='check',
      check_cols=['status', 'monthly_amount'],
    )
}}

select * from {{ source('subscription_platform', 'raw_subscriptions') }}

{% endsnapshot %}