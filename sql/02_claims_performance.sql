-- =============================================================
-- 02_claims_performance.sql
-- Claims trends and regional performance
-- Techniques: CTEs, date functions, window functions
--             (LAG, SUM OVER, RANK, ROW_NUMBER)
-- =============================================================

-- Q1. Monthly claim volume with month-over-month change
--     (CTE + date function + LAG window function)
WITH monthly AS (
    SELECT
        strftime('%Y-%m', claim_date) AS claim_month,
        COUNT(*)                      AS claims,
        ROUND(SUM(claim_amount), 0)   AS claim_value
    FROM insurance_claims
    GROUP BY claim_month
)
SELECT
    claim_month,
    claims,
    claim_value,
    LAG(claims) OVER (ORDER BY claim_month) AS prev_month_claims,
    ROUND(100.0 * (claims - LAG(claims) OVER (ORDER BY claim_month))
          / LAG(claims) OVER (ORDER BY claim_month), 1) AS mom_change_pct
FROM monthly
ORDER BY claim_month;

-- Q2. Running (cumulative) total of claims value by month
WITH monthly AS (
    SELECT
        strftime('%Y-%m', claim_date) AS claim_month,
        SUM(claim_amount)             AS claim_value
    FROM insurance_claims
    GROUP BY claim_month
)
SELECT
    claim_month,
    ROUND(claim_value, 0)                                AS claim_value,
    ROUND(SUM(claim_value) OVER (ORDER BY claim_month), 0) AS cumulative_value
FROM monthly
ORDER BY claim_month;

-- Q3. Seasonality: average claims per calendar month across both years
SELECT
    strftime('%m', claim_date)                          AS month_num,
    COUNT(*)                                            AS total_claims,
    COUNT(DISTINCT strftime('%Y', claim_date))          AS years_covered,
    ROUND(1.0 * COUNT(*) / COUNT(DISTINCT strftime('%Y', claim_date)), 0) AS avg_claims_per_month
FROM insurance_claims
GROUP BY month_num
ORDER BY avg_claims_per_month DESC;

-- Q4. Rank regions by SLA breach rate (worst first)
WITH region_sla AS (
    SELECT
        region,
        COUNT(*) AS claims,
        ROUND(AVG(processing_days), 1) AS avg_processing_days,
        ROUND(100.0 * SUM(CASE WHEN processing_days > 7 THEN 1 ELSE 0 END) / COUNT(*), 1)
            AS sla_breach_pct
    FROM insurance_claims
    GROUP BY region
)
SELECT
    RANK() OVER (ORDER BY sla_breach_pct DESC) AS breach_rank,
    region,
    claims,
    avg_processing_days,
    sla_breach_pct
FROM region_sla
ORDER BY breach_rank;

-- Q5. Most expensive claim type in each region
--     (ROW_NUMBER partitioned by region)
WITH type_region AS (
    SELECT
        region,
        claim_type,
        COUNT(*)                    AS claims,
        ROUND(SUM(claim_amount), 0) AS total_value
    FROM insurance_claims
    GROUP BY region, claim_type
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_value DESC) AS rn
    FROM type_region
)
SELECT region, claim_type, claims, total_value
FROM ranked
WHERE rn = 1
ORDER BY total_value DESC;

-- Q6. Each region's share of total claim value
--     (window SUM with empty OVER () = grand total)
SELECT
    region,
    ROUND(SUM(claim_amount), 0) AS region_value,
    ROUND(100.0 * SUM(claim_amount) / SUM(SUM(claim_amount)) OVER (), 1) AS pct_of_total_value
FROM insurance_claims
GROUP BY region
ORDER BY pct_of_total_value DESC;
