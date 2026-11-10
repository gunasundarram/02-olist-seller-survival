-- Survival rate by early activity (orders in the first 90 days)
-- Reproduces the activity-band chart and the "Survival Rate by Early Activity" table.
-- Note: the top band is labelled "30+ orders" but holds sellers with 31 or more
-- orders, because exactly 30 orders falls in "16-30 orders".
SELECT
    CASE
        WHEN orders_first_90d = 1                THEN '1 order'
        WHEN orders_first_90d BETWEEN 2  AND 5   THEN '2-5 orders'
        WHEN orders_first_90d BETWEEN 6  AND 15  THEN '6-15 orders'
        WHEN orders_first_90d BETWEEN 16 AND 30  THEN '16-30 orders'
        ELSE '30+ orders'
    END                                         AS activity_band,
    COUNT(*)                                    AS total_sellers,
    SUM(survived_month_12)                      AS survived,
    ROUND(100.0 * SUM(survived_month_12)
          / COUNT(*), 1)                        AS survival_rate_pct
FROM seller_survival
GROUP BY activity_band
ORDER BY MIN(orders_first_90d);
