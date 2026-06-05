# 🚀 Subscription SaaS Analytics Platform (dbt Core + Google BigQuery)

An end-to-end modern data stack pipeline that transforms raw transactional data from a subscription-based SaaS platform into an optimized, star-schema analytics data mart. 

This project simulates complex real-world data engineering challenges, including tracking historical subscription price adjustments over time, data validation via custom Jinja macros, multi-layer data cleaning, and implementing cost-effective incremental loading strategies.

---

## 🏗️ Warehouse Architecture & Data Lineage

This warehouse is built using a modular, multi-layer architecture following dbt implementation best practices to isolate ingestion from business logic:

`Raw (Seeds) ──> Staging (stg_) ──> Intermediate (int_) ──> Marts (dim_ / fct_)`

### Pipeline Lineage Graph
![dbt Lineage Graph](target/run/my_portfolio_dbt_project/Images/prod_lineage.png)  
*(To view dynamically, run `dbt docs generate` and `dbt docs serve` locally).*

### Data Layer Breakdown:
1. **Source Layer (Seeds):** Raw CSV snapshots mimicking production databases (`raw_customers`, `raw_subscriptions`, `raw_usage_logs`) along with normalized lookup dimensions (`raw_plans`, `raw_plan_pricing_history`, `raw_marketing_channels`).
2. **Staging Layer (`stg_`):** 1-to-1 views mapping raw assets. Performs basic column renaming, string trimming, and initial type casting without introducing joins or heavy business filters.
3. **Intermediate Layer (`int_`):** The operational engine room. Handles multi-table normalization joins, calculates temporal window states, and runs custom validation macros. Kept private from downstream BI layers.
4. **Marts Layer (`dim_` / `fct_`):** High-performance physical tables serving as the final semantic layer for business intelligence tools, tracking current states and historical facts.

---

## 🛠️ Tech Stack & Infrastructure

* **Data Warehouse:** Google BigQuery (Serverless, Columnar OLAP architecture)
* **Transformation Engine:** dbt Core v1.11 (Jinja-SQL compiler & orchestration)
* **Language:** ANSI SQL
* **Version Control:** Git & GitHub
* **Development Environment:** VS Code & Python Virtual Environment (`venv`)

---

## 🧠 Core Engineering Highlights

### 1. Advanced Normalization & Historic Pricing Log (SCD Type 2)
To model shifting financial metrics accurately, the project decouples plans from flat records and utilizes a **Slowly Changing Dimension (SCD Type 2)** structure (`raw_plan_pricing_history`). The intermediate layer dynamically maps subscription events to active price scales based on historical timestamp boundaries:
```sql
left join ref_pricing pr 
    on p.plan_id = pr.plan_id
    and s.valid_from_date >= pr.valid_from
    and (s.valid_from_date < pr.valid_to or pr.valid_to is null)
2. High-Performance Incremental Processing (merge strategy)
To minimize BigQuery query computation costs, the main fact table (fct_subscriptions_historical) uses an Incremental Materialization strategy. Rather than rebuilding the table from scratch, dbt writes a target MERGE statement to update modified historical keys and append new records seamlessly based on unique keys:

YAML
marts:
  core:
    fct_subscriptions_historical:
      +materialized: incremental
      +incremental_strategy: merge
      +unique_key: subscription_id
3. Custom Jinja Macro Data Validation
Data quality is enforced programmatically in the intermediate layer. A custom Jinja macro (validate_email) wraps a complex regular expression evaluation to validate account strings and generate an execution flag before records are exposed to production dashboards:

SQL
{% macro validate_email(column_name) %}
    case 
        when regexp_contains({{ column_name }}, r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$") then true
        else false
    end
{% endmacro %}
📂 Project Directory Structure
Plaintext
my_portfolio_dbt_project/
├── dbt_project.yml              # Central project configuration, tracking materialization layers
├── macros/
│   └── validate_email.sql       # Custom Jinja regex macro for string formatting checks
├── seeds/
│   ├── _seeds__models.yml       # Explicit seed data type contracts
│   ├── raw_customers.csv        # Raw customer profiles
│   ├── raw_marketing_channels.csv # Lookup: Marketing streams
│   ├── raw_plan_pricing_history.csv # Lookup: SCD Type 2 price changes
│   ├── raw_plans.csv            # Lookup: Core product tiers (Basic, Pro, Enterprise)
│   ├── raw_subscriptions.csv    # Raw subscription history logs
│   └── raw_usage_logs.csv       # Raw product usage and clickstream logs
└── models/
    ├── staging/
    │   └── subscription_platform/
    │       ├── src_subscription_platform.yml       # Source definitions & data quality tests
    │       ├── stg_subscription_platform__customers.sql
    │       ├── stg_subscription_platform__subscriptions.sql
    │       └── stg_subscription_platform__usage_logs.sql
    ├── intermediate/
    │   ├── int_customer_subscription_states.sql   # Lifecycle logic & ranking
    │   ├── int_customers_cleaned.sql              # Invokes custom email validation macro
    │   └── int_subscriptions_enriched.sql         # Resolves pricing timestamps
    └── marts/
        └── core/
            ├── _core__models.yml                  # Strict schema enforcement and FK testing
            ├── dim_customers.sql                  # Wide Customer 360 table
            └── fct_subscriptions_historical.sql   # Optimized incremental billing table
🧪 Data Quality & Testing Contracts
Robust data contracts are enforced via strict schema documentation and tests inside _core__models.yml. The platform utilizes built-in and relational validation constraints:

Primary Key Verification: unique and not_null assertions applied across all dimensional entities.

Foreign Key Constraints: Dynamic relationships tests ensuring every fact entity ties directly back to a valid dimension block.

Schema Contracts: Enabled contract: enforced: true to prevent schema drift from breaking downstream BI tools.

To execute the verification matrix locally:

Bash
dbt build --no-partial-parse
📈 Executive Deliverables (Business Metrics)
The final presentation mart layer exposes business-critical dimensions optimized for BI tools (e.g., Google Looker Studio), tracking core SaaS KPIs:

Monthly Recurring Revenue (MRR): Calculated dynamically across account cohorts even through price changes.

Customer Lifecycle States: Tracking healthy, canceled, and churned accounts over operational timelines.

Funnel Attribution: Correlating marketing acquisition channels directly against recurring billing values.