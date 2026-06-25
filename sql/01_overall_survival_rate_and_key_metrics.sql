SELECT
    survived_month_12,
    COUNT(*)                                    AS seller_count,
    ROUND(AVG(orders_first_90d), 1)             AS avg_orders_90d,
    ROUND(AVG(avg_review_score_90d), 2)         AS avg_review_score,
    ROUND(AVG(avg_order_value_90d), 2)          AS avg_order_value,
    ROUND(AVG(months_active), 1)                AS avg_months_active,
    ROUND(AVG(total_orders), 1)                 AS avg_total_orders
FROM seller_survival
GROUP BY survived_month_12
ORDER BY survived_month_12 DESC;