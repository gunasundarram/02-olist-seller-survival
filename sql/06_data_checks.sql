-- ============================================================
-- 06: Checks that qualify the headline findings
-- Table: seller_survival (1,468 eligible sellers)
-- Run each query separately (highlight it, press F5).
-- ============================================================

-- ------------------------------------------------------------
-- 6A. What is really inside each seller segment?
--     The segment CASE in query 5 sends every seller who is not High Potential,
--     Growing or At Risk to "Critical Risk". That includes sellers with 6 or
--     more orders whose average review is below the High Potential / Growing
--     thresholds (or missing), not only sellers with a single order.
-- ------------------------------------------------------------
WITH segmented AS (
    SELECT
        orders_first_90d,
        survived_month_12,
        CASE
            WHEN orders_first_90d >= 16 AND avg_review_score_90d >= 4.0 THEN 'High Potential'
            WHEN orders_first_90d BETWEEN 6 AND 15 AND avg_review_score_90d >= 3.5 THEN 'Growing'
            WHEN orders_first_90d BETWEEN 2 AND 5 THEN 'At Risk'
            ELSE 'Critical Risk'
        END AS seller_segment
    FROM seller_survival
)
SELECT
    seller_segment,
    CASE
        WHEN orders_first_90d = 1               THEN '1 order'
        WHEN orders_first_90d BETWEEN 2 AND 5   THEN '2-5 orders'
        WHEN orders_first_90d BETWEEN 6 AND 15  THEN '6-15 orders'
        ELSE '16+ orders'
    END                                         AS orders_band,
    COUNT(*)                                    AS sellers,
    SUM(survived_month_12)                      AS survived,
    ROUND(100.0 * SUM(survived_month_12) / COUNT(*), 1) AS survival_rate_pct
FROM segmented
GROUP BY seller_segment, orders_band
ORDER BY seller_segment, MIN(orders_first_90d);
-- Finding: "Critical Risk" = 361 one-order sellers + 111 sellers with 6+ orders but weaker reviews.
-- Those 111 survive at 43% (6-15 orders) and 80% (16+ orders); the 30+ group alone survives at 89%.


-- ------------------------------------------------------------
-- 6B. Review bands without gaps.
--     Query 3 uses BETWEEN 3 AND 3.9 and BETWEEN 4 AND 4.4 on a score that has two
--     decimals, so averages from 3.91 to 3.99 and from 4.41 to 4.49 fall through to
--     the ELSE branch and are counted as "Excellent (4.5+)". This version closes the gaps
--     and splits out the perfect 5.0 sellers.
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN avg_review_score_90d IS NULL THEN 'No reviews'
        WHEN avg_review_score_90d < 3.0   THEN 'Low (< 3.0)'
        WHEN avg_review_score_90d < 4.0   THEN 'Medium (3.0-3.99)'
        WHEN avg_review_score_90d < 4.5   THEN 'Good (4.0-4.49)'
        WHEN avg_review_score_90d < 5.0   THEN 'Excellent (4.5-4.99)'
        ELSE 'Perfect (5.0)'
    END                                         AS review_band,
    COUNT(*)                                    AS total_sellers,
    SUM(survived_month_12)                      AS survived,
    ROUND(100.0 * SUM(survived_month_12) / COUNT(*), 1) AS survival_rate_pct,
    ROUND(AVG(orders_first_90d), 1)             AS avg_orders_90d
FROM seller_survival
GROUP BY review_band
ORDER BY MIN(COALESCE(avg_review_score_90d, 0));

-- How many sellers does the original query 3 put in the wrong band?
SELECT COUNT(*) AS sellers_in_the_gaps
FROM seller_survival
WHERE (avg_review_score_90d > 3.9 AND avg_review_score_90d < 4.0)
   OR (avg_review_score_90d > 4.4 AND avg_review_score_90d < 4.5);
-- Finding: 57 sellers (14 + 43). Perfect 5.0 sellers survive at 31.2% and have a median of 1 early order.


-- ------------------------------------------------------------
-- 6C. Does review score matter once early order volume is known?
--     Survival by order band and review band.
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN orders_first_90d = 1               THEN '1 order'
        WHEN orders_first_90d BETWEEN 2 AND 5   THEN '2-5 orders'
        WHEN orders_first_90d BETWEEN 6 AND 15  THEN '6-15 orders'
        ELSE '16+ orders'
    END                                         AS orders_band,
    CASE
        WHEN avg_review_score_90d IS NULL THEN 'No reviews'
        WHEN avg_review_score_90d < 3.0   THEN 'Low (< 3.0)'
        WHEN avg_review_score_90d < 4.0   THEN 'Medium (3.0-3.99)'
        WHEN avg_review_score_90d < 4.5   THEN 'Good (4.0-4.49)'
        ELSE 'Excellent (4.5+)'
    END                                         AS review_band,
    COUNT(*)                                    AS sellers,
    SUM(survived_month_12)                      AS survived,
    ROUND(100.0 * SUM(survived_month_12) / COUNT(*), 1) AS survival_rate_pct
FROM seller_survival
GROUP BY orders_band, review_band
ORDER BY MIN(orders_first_90d), MIN(COALESCE(avg_review_score_90d, 0));
-- Finding: within every order band, sellers with an average review under 3.0 do worst; above 3.0
-- the bands are close once volume is held fixed (for example 63.6%, 64.6%, 60.6% at 6-15 orders).


-- ------------------------------------------------------------
-- 6D. States with a Wilson 95% interval, because small states give unstable rates.
-- ------------------------------------------------------------
WITH s AS (
    SELECT seller_state,
           COUNT(*)::numeric                     AS n,
           SUM(survived_month_12)::numeric       AS x
    FROM seller_survival
    WHERE seller_state IS NOT NULL
    GROUP BY seller_state
    HAVING COUNT(*) >= 10
),
p AS (
    SELECT seller_state, n, x, x / n AS p, 1.96::numeric AS z FROM s
)
SELECT
    seller_state,
    n::int                                      AS total_sellers,
    x::int                                      AS survived,
    ROUND(100 * p, 1)                           AS survival_rate_pct,
    ROUND(100 * ((p + z*z/(2*n)) - z * SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
    ROUND(100 * ((p + z*z/(2*n)) + z * SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM p
ORDER BY survival_rate_pct DESC;
-- Finding: DF 58.8% rests on 17 sellers (interval about 36% to 78%); MG 52.1% on 140 (about 44% to 60%).


-- ------------------------------------------------------------
-- 6E. The headline volume contrast, stated exactly.
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN orders_first_90d = 1  THEN '1 order'
        WHEN orders_first_90d >= 6 THEN '6+ orders'
        ELSE '2-5 orders'
    END                                         AS activity_group,
    COUNT(*)                                    AS sellers,
    SUM(survived_month_12)                      AS survived,
    ROUND(100.0 * SUM(survived_month_12) / COUNT(*), 1) AS survival_rate_pct
FROM seller_survival
GROUP BY activity_group
ORDER BY MIN(orders_first_90d);
-- Finding: 6+ orders 68.7% vs 1 order 20.5% = 3.4 times. The 6-15 band alone (60.7%) is 3.0 times.
