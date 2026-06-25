SELECT
    seller_state,
    COUNT(*)                                    AS total_sellers,
    SUM(survived_month_12)                      AS survived,
    ROUND(100.0 * SUM(survived_month_12)
          / COUNT(*), 1)                        AS survival_rate_pct,
    ROUND(AVG(orders_first_90d), 1)             AS avg_orders_90d
FROM seller_survival
WHERE seller_state IS NOT NULL
GROUP BY seller_state
HAVING COUNT(*) >= 10
ORDER BY survival_rate_pct DESC
LIMIT 15;