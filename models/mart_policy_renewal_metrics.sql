-- models/mart_policy_renewal_metrics.sql
WITH policy_history AS (
    SELECT * FROM {{ ref('moh_demo', 'dim_policy_customer_history') }}
),

renewal_criteria AS (
    SELECT * FROM {{ ref('renewal_rates') }}
),

policy_tenures AS (
    SELECT 
        policy_id,
        policy_type,
        customer_name,
        state,
        MIN(valid_from) as first_policy_date,
        DATEDIFF('month', MIN(valid_from), CURRENT_DATE()) as tenure_months,
        MAX(CASE WHEN is_current = true THEN premium_amount END) as current_premium_amount
    FROM policy_history
    GROUP BY 1,2,3,4
)

SELECT 
    pt.*,
    rr.renewal_rate_percentage,
    CASE 
        WHEN pt.tenure_months >= rr.min_tenure_months THEN true 
        ELSE false 
    END as eligible_for_renewal,
    DATEADD('month', 12, pt.first_policy_date) as next_renewal_date,
    pt.current_premium_amount * (1 + (rr.renewal_rate_percentage/100)) as projected_renewal_amount
FROM policy_tenures pt
JOIN renewal_criteria rr 
    ON pt.policy_type = rr.policy_type