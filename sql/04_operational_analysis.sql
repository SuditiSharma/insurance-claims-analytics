-- =============================================================
-- 04_operational_analysis.sql
-- Operational bottlenecks, documentation, handlers and channels
-- Techniques: JOIN, CTEs, CASE, window AVG/RANK, subqueries
-- =============================================================

-- Q1. Operational bottlenecks by claim type
SELECT
    claim_type,
    COUNT(*)                         AS claim_volume,
    ROUND(AVG(processing_days), 1)   AS avg_tat_days,
    ROUND(100.0 * SUM(CASE WHEN processing_days > 7 THEN 1 ELSE 0 END) / COUNT(*), 1)
                                     AS sla_breach_pct
FROM insurance_claims
GROUP BY claim_type
ORDER BY sla_breach_pct DESC;

-- Q2. Claim-type-specific targets (JOIN to a lookup table)
--     A single 7-day SLA is unfair to complex claims like theft,
--     so here each claim type gets its own realistic target.
WITH targets(claim_type, target_days) AS (
    VALUES ('Windscreen', 5), ('Accidental damage', 10), ('Collision', 10),
           ('Third-party', 14), ('Fire', 21), ('Theft', 21)
)
SELECT
    c.claim_type,
    t.target_days,
    COUNT(*)                         AS claims,
    ROUND(AVG(c.processing_days), 1) AS avg_tat_days,
    ROUND(100.0 * SUM(CASE WHEN c.processing_days > t.target_days THEN 1 ELSE 0 END)
          / COUNT(*), 1)             AS breach_vs_own_target_pct
FROM insurance_claims AS c
JOIN targets AS t
    ON c.claim_type = t.claim_type
GROUP BY c.claim_type, t.target_days
ORDER BY breach_vs_own_target_pct DESC;

-- Q3. Impact of incomplete documentation on processing time
SELECT
    doc_status,
    COUNT(*)                        AS claims,
    ROUND(AVG(processing_days), 1)  AS avg_tat_days,
    ROUND(100.0 * SUM(CASE WHEN processing_days > 7 THEN 1 ELSE 0 END) / COUNT(*), 1)
                                    AS sla_breach_pct
FROM insurance_claims
GROUP BY doc_status;

-- Q4. Impact of investigation on processing time
SELECT
    CASE WHEN investigation_required = 1 THEN 'Investigated' ELSE 'Not investigated' END
                                    AS investigation,
    COUNT(*)                        AS claims,
    ROUND(AVG(processing_days), 1)  AS avg_tat_days
FROM insurance_claims
GROUP BY investigation;

-- Q5. Does handler experience affect processing time?
SELECT
    CASE
        WHEN handler_experience_years <= 1 THEN '1. 0-1 years'
        WHEN handler_experience_years <= 4 THEN '2. 2-4 years'
        WHEN handler_experience_years <= 8 THEN '3. 5-8 years'
        ELSE                                    '4. 9+ years'
    END AS handler_experience,
    COUNT(*)                        AS claims,
    ROUND(AVG(processing_days), 1)  AS avg_tat_days
FROM insurance_claims
GROUP BY handler_experience
ORDER BY handler_experience;

-- Q6. Channel performance scorecard with rankings
WITH channel_stats AS (
    SELECT
        channel,
        COUNT(*)                              AS claims,
        ROUND(AVG(processing_days), 1)        AS avg_tat_days,
        ROUND(AVG(customer_satisfaction), 2)  AS avg_satisfaction,  -- AVG ignores NULL (no survey)
        ROUND(100.0 * SUM(CASE WHEN claim_status = 'Closed/Rejected' THEN 1 ELSE 0 END)
              / COUNT(*), 1)                  AS rejected_pct
    FROM insurance_claims
    GROUP BY channel
)
SELECT
    channel,
    claims,
    avg_tat_days,
    avg_satisfaction,
    rejected_pct,
    RANK() OVER (ORDER BY claims DESC)           AS volume_rank,
    RANK() OVER (ORDER BY avg_tat_days ASC)      AS speed_rank,
    RANK() OVER (ORDER BY avg_satisfaction DESC) AS satisfaction_rank
FROM channel_stats
ORDER BY claims DESC;

-- Q7. How many claims took longer than the average for their own claim type?
--     (window AVG partitioned by claim type)
WITH with_type_avg AS (
    SELECT
        claim_id,
        claim_type,
        processing_days,
        AVG(processing_days) OVER (PARTITION BY claim_type) AS type_avg_days
    FROM insurance_claims
)
SELECT
    claim_type,
    ROUND(MAX(type_avg_days), 1)                                   AS type_avg_days,
    SUM(CASE WHEN processing_days > type_avg_days THEN 1 ELSE 0 END) AS slower_than_avg,
    COUNT(*)                                                       AS claims
FROM with_type_avg
GROUP BY claim_type
ORDER BY type_avg_days DESC;

-- Q8. Slowest claims still open: oldest unresolved cases in the pipeline
SELECT
    claim_id, claim_type, region, claim_status,
    processing_days, doc_status, investigation_required
FROM insurance_claims
WHERE claim_status IN ('Open', 'Pending Documents', 'Under Investigation')
  AND processing_days > (SELECT AVG(processing_days) * 2 FROM insurance_claims)
ORDER BY processing_days DESC
LIMIT 15;
