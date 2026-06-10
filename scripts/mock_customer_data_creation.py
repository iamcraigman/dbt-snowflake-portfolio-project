import pandas as pd
import random
from datetime import datetime, timedelta
import os

# Set random seed for reproducibility
random.seed(42)

# Ensure the output directory exists
output_dir = r"C:\Users\Logon\dbt-bigquery-portfolio-project\seeds"
os.makedirs(output_dir, exist_ok=True)

# --- STEP 1: GENERATE THE CUSTOMER BASE ---
num_rows = 1000
start_date_env = datetime(2026, 1, 1, 0, 0, 0)
end_date_env = datetime(2026, 5, 31, 23, 59, 59)

countries = ['US', 'CA', 'UK', 'DE', 'FR', 'IT']
channels = ['Organic Search', 'Google Ads', 'LinkedIn', 'Direct', 'Blog Post']
domains = ['example.com', 'test.com', 'mockdata.org', 'mail.com']

def random_date(start, end):
    delta = end - start
    int_delta = (delta.days * 24 * 60 * 60) + delta.seconds
    random_second = random.randint(0, int_delta)
    return start + timedelta(seconds=random_second)

customer_data = []
for i in range(1, num_rows + 1):
    customer_id = f"c_{i:03d}"  # Using 3-digit padding as in original prompt example c_001
    signup_dt = random_date(start_date_env, end_date_env)
    email = f"user_{i}@{random.choice(domains)}"
    country = random.choice(countries)
    channel = random.choice(channels)
    customer_data.append([customer_id, signup_dt, email, country, channel])

df_customers = pd.DataFrame(customer_data, columns=['customer_id', 'signup_at', 'email', 'country', 'marketing_channel'])
df_customers = df_customers.sort_values(by='signup_at').reset_index(drop=True)

# Format customer datetime to string matching the sample row
df_customers['signup_at'] = df_customers['signup_at'].dt.strftime('%Y-%m-%d %H:%M:%S')

# Save raw_customers file
customers_path = os.path.join(output_dir, 'raw_customers.csv')
df_customers.to_csv(customers_path, index=False)


# --- STEP 2: GENERATE THE SUBSCRIPTIONS DATA ---
plans = ['Trial', 'Basic', 'Pro', 'Enterprise']
sub_id_counter = 101
subscription_data = []

def get_monthly_amount(plan, start_date_obj):
    if plan == 'Trial':
        return 0.00
    elif plan == 'Basic':
        return 29.00
    elif plan == 'Pro':
        cutoff_date = datetime(2026, 3, 1)
        return 89.00 if start_date_obj < cutoff_date else 99.00
    elif plan == 'Enterprise':
        return 499.00
    return 0.00

for _, row in df_customers.iterrows():
    cust_id = row['customer_id']
    signup_dt_obj = datetime.strptime(row['signup_at'], '%Y-%m-%d %H:%M:%S')
    signup_date = signup_dt_obj.date()
    
    current_plan = random.choice(plans)
    status = random.choice(['active', 'cancelled', 'upgraded'])
    
    sub_id = f"sub_{sub_id_counter}"
    sub_id_counter += 1
    amount = get_monthly_amount(current_plan, signup_dt_obj)
    
    start_str = signup_date.strftime('%Y-%m-%d')
    end_str = ""
    
    if status in ['cancelled', 'upgraded']:
        days_active = random.randint(1, 45)
        end_date_obj = signup_date + timedelta(days=days_active)
        if end_date_obj > end_date_env.date():
            end_date_obj = end_date_env.date()
        end_str = end_date_obj.strftime('%Y-%m-%d')
    
    subscription_data.append([sub_id, cust_id, current_plan, f"{amount:.2f}", status, start_str, end_str])
    
    if status == 'upgraded':
        upgrade_options = [p for p in ['Basic', 'Pro', 'Enterprise'] if p != current_plan]
        if not upgrade_options: 
            upgrade_options = ['Enterprise']
            
        next_plan = random.choice(upgrade_options)
        
        sub_id_next = f"sub_{sub_id_counter}"
        sub_id_counter += 1
        
        next_start_date_obj = datetime.strptime(end_str, '%Y-%m-%d')
        next_amount = get_monthly_amount(next_plan, next_start_date_obj)
        
        next_status = random.choice(['active', 'cancelled'])
        next_end_str = ""
        
        if next_status == 'cancelled':
            days_next_active = random.randint(1, 45)
            next_end_date_obj = next_start_date_obj.date() + timedelta(days=days_next_active)
            if next_end_date_obj > end_date_env.date():
                next_end_date_obj = end_date_env.date()
            next_end_str = next_end_date_obj.strftime('%Y-%m-%d')
            
        subscription_data.append([
            sub_id_next, cust_id, next_plan, f"{next_amount:.2f}", 
            next_status, end_str, next_end_str
        ])

sub_columns = ['subscription_id', 'customer_id', 'plan_name', 'monthly_amount', 'status', 'start_date', 'end_date']
df_subs = pd.DataFrame(subscription_data, columns=sub_columns)

# Save raw_subscriptions file
subscriptions_path = os.path.join(output_dir, 'raw_subscriptions.csv')
df_subs.to_csv(subscriptions_path, index=False)

print(f"Saved customers to {customers_path}")
print(f"Saved subscriptions to {subscriptions_path}")