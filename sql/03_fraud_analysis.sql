-- =============================================================
-- 03_fraud_analysis.sql
-- Exploratory fraud-risk analysis
-- Techniques: CASE, CTEs, subqueries, HAVING, window functions
-- Note: fraud_flag is a historical label in a synthetic dataset;
--       this is pattern analysis, not a fraud detection model.
-- =============================================================

-- Q1. Fraud rate by claim type (highest first)
SELECT
    claim_type,
    COUNT(*)                          AS claims,
    SUM(fraud_flag)                   AS fraudulent_claims,
    ROUND(100.0 * AVG(fraud_flag), 1) AS fraud_rate_pct
FROM insurance_claims
GROUP BY claim_type
ORDER BY fraud_rate_pct DESC;

-- Q2. Fraud rate by region and by channel
SELECT 'Region' AS dimension, region AS category,
       COUNT(*) AS claims, ROUND(100.0 * AVG(fraud_flag), 1) AS fraud_rate_pct
FROM insurance_claims GROUP BY region
UNION ALL
SELECT 'Channel', channel,
       COUNT(*), ROUND(100.0 * AVG(fraud_flag), 1)
FROM insurance_claims GROUP BY channel
ORDER BY dimension, fraud_rate_pct DESC;

-- Q3. Profile of fraudulent vs non-fraudulent claims
SELECT
    CASE WHEN fraud_flag = 1 THEN 'Fraudulent' ELSE 'Non-fraudulent' END AS claim_group,
    COUNT(*)                               AS claims,
    ROUND(AVG(claim_amount), 0)            AS avg_claim_amount,
    ROUND(AVG(processing_days), 1)         AS avg_processing_days,
    ROUND(AVG(previous_claims), 2)         AS avg_previous_claims,
    ROUND(AVG(reporting_lag_days), 1)      AS avg_reporting_lag_days,
    ROUND(AVG(policy_tenure_months), 1)    AS avg_policy_tenure_months,
    ROUND(100.0 * AVG(investigation_required), 1) AS investigated_pct
FROM insurance_claims
GROUP BY claim_group;

-- Q4. Risk level: share of claims vs share of value vs fraud rate
--     (the key "X% of claims but Y% of value" finding)
WITH risk AS (
    SELECT
        risk_level,
        COUNT(*)          AS claims,
        SUM(claim_amount) AS claim_value,
        AVG(fraud_flag)   AS fraud_rate
    FROM insurance_claims
    GROUP BY risk_level
)
SELECT
    risk_level,
    claims,
    ROUND(100.0 * claims      / SUM(claims)      OVER (), 1) AS pct_of_claims,
    ROUND(100.0 * claim_value / SUM(claim_value) OVER (), 1) AS pct_of_value,
    ROUND(100.0 * fraud_rate, 1)                             AS fraud_rate_pct
FROM risk
ORDER BY CASE risk_level WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END;

-- Q5. Late reporting as a fraud signal: fraud rate by reporting delay
SELECT
    CASE
        WHEN reporting_lag_days = 0              THEN '1. Same day'
        WHEN reporting_lag_days BETWEEN 1 AND 3  THEN '2. 1-3 days'
        WHEN reporting_lag_days BETWEEN 4 AND 7  THEN '3. 4-7 days'
        ELSE                                          '4. 8+ days'
    END AS reporting_delay,
    COUNT(*)                          AS claims,
    ROUND(100.0 * AVG(fraud_flag), 1) AS fraud_rate_pct
FROM insurance_claims
GROUP BY reporting_delay
ORDER BY reporting_delay;

-- Q6. New policies: fraud rate for policies held 6 months or less vs longer
SELECT
    CASE WHEN policy_tenure_months <= 6 THEN 'New policy (<= 6 months)'
         ELSE 'Established policy (> 6 months)' END AS policy_age,
    COUNT(*)                          AS claims,
    ROUND(100.0 * AVG(fraud_flag), 1) AS fraud_rate_pct
FROM insurance_claims
GROUP BY policy_age;

-- Q7. Top 3 highest-value HIGH-risk claims in each region
--     (an investigator's priority list)
WITH ranked AS (
    SELECT
        region, claim_id, claim_type, claim_amount,
        previous_claims, risk_score, claim_status,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY claim_amount DESC) AS rn
    FROM insurance_claims
    WHERE risk_level = 'High'
)
SELECT region, rn AS priority, claim_id, claim_type,
       claim_amount, previous_claims, risk_score, claim_status
FROM ranked
WHERE rn <= 3
ORDER BY region, priority;

-- Q8. Policies with repeat claims in this dataset (subquery + HAVING)
SELECT
    claims_per_policy,
    COUNT(*) AS policies
FROM (
    SELECT policy_id, COUNT(*) AS claims_per_policy
    FROM insurance_claims
    GROUP BY policy_id
    HAVING COUNT(*) >= 2
) AS repeat_policies
GROUP BY claims_per_policy
ORDER BY claims_per_policy;
