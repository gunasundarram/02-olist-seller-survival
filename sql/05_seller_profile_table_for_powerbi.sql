SELECT
    seller_id,
    orders_first_90d,
    avg_review_score_90d,
    avg_order_value_90d,
    months_active,
    total_orders,
    survived_month_12,
    seller_state,
    CASE
        WHEN orders_first_90d >= 16 AND avg_review_score_90d >= 4.0 
            THEN 'High Potential'
        WHEN orders_first_90d BETWEEN 6 AND 15 AND avg_review_score_90d >= 3.5 
            THEN 'Growing'
        WHEN orders_first_90d BETWEEN 2 AND 5 
            THEN 'At Risk'
        ELSE 'Critical Risk'
    END                                         AS seller_segment,
    CASE survived_month_12
        WHEN 1 THEN 'Survived'
        ELSE 'Churned'
    END                                         AS survival_status
FROM seller_survival;