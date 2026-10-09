-- =============================================================
-- 01_basic_analysis.sql
-- Insurance Claims Analytics: headline business metrics
-- Table: insurance_claims (cleaned dataset, 14,983 claims)
-- =============================================================

-- Q1. How many claims were received?
SELECT COUNT(*) AS total_claims
FROM insurance_claims;

-- Q2. Total claimed value and total settled value
SELECT
    ROUND(SUM(claim_amount), 0)      AS total_claim_value,
    ROUND(SUM(settlement_amount), 0) AS total_settlement_value
FROM insurance_claims;

-- Q3. Average claim amount
SELECT ROUND(AVG(claim_amount), 0) AS avg_claim_amount
FROM insurance_claims;

-- Q4. Claim volume and value by region
SELECT
    region,
    COUNT(*)                    AS claim_count,
    ROUND(SUM(claim_amount), 0) AS total_claim_value
FROM insurance_claims
GROUP BY region
ORDER BY claim_count DESC;

-- Q5. How many claims breached the 7-day SLA, and what percentage is that?
SELECT
    SUM(CASE WHEN processing_days > 7 THEN 1 ELSE 0 END) AS outside_sla_claims,
    ROUND(100.0 * SUM(CASE WHEN processing_days > 7 THEN 1 ELSE 0 END) / COUNT(*), 1) AS sla_breach_pct
FROM insurance_claims;

-- Q6. Overall fraud rate (%)
SELECT ROUND(AVG(fraud_flag) * 100, 2) AS fraud_rate_pct
FROM insurance_claims;

-- Q7. Performance by claim type
SELECT
    claim_type,
    COUNT(*)                       AS claims,
    ROUND(AVG(claim_amount), 0)    AS avg_claim,
    ROUND(AVG(processing_days), 1) AS avg_processing_days
FROM insurance_claims
GROUP BY claim_type
ORDER BY claims DESC;

-- Q8. Top 20 highest-value claims
SELECT
    claim_id,
    claim_type,
    region,
    claim_amount,
    processing_days,
    fraud_flag
FROM insurance_claims
ORDER BY claim_amount DESC
LIMIT 20;

-- Q9. Claim status breakdown with share of total
SELECT
    claim_status,
    COUNT(*) AS claims,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM insurance_claims), 1) AS pct_of_claims
FROM insurance_claims
GROUP BY claim_status
ORDER BY claims DESC;

-- Q10. Average settlement ratio for settled claims, by customer segment
SELECT
    customer_segment,
    COUNT(*)                         AS settled_claims,
    ROUND(AVG(settlement_ratio), 3)  AS avg_settlement_ratio
FROM insurance_claims
WHERE claim_status = 'Settled'
GROUP BY customer_segment
ORDER BY avg_settlement_ratio DESC;
