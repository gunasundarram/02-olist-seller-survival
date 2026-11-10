CREATE TABLE seller_survival AS
WITH seller_timeline AS (
    SELECT 
        oi.seller_id,
        MIN(o.order_purchase_timestamp)                    AS first_sale_date,
        MAX(o.order_purchase_timestamp)                    AS last_sale_date,
        COUNT(DISTINCT o.order_id)                         AS total_orders,
        ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('cancelled', 'unavailable')
    GROUP BY oi.seller_id
    HAVING MIN(o.order_purchase_timestamp) <= '2017-10-17'
),
first_90_days AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT o.order_id)                          AS orders_first_90d,
        ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value_90d,
        ROUND(AVG(r.review_score)::NUMERIC, 2)              AS avg_review_score_90d
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN order_reviews r ON o.order_id = r.order_id
    JOIN seller_timeline st ON oi.seller_id = st.seller_id
    WHERE o.order_purchase_timestamp <= st.first_sale_date + INTERVAL '90 days'
      AND o.order_status NOT IN ('cancelled', 'unavailable')
    GROUP BY oi.seller_id
),
month12_activity AS (
    SELECT DISTINCT oi.seller_id
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN seller_timeline st ON oi.seller_id = st.seller_id
    WHERE o.order_purchase_timestamp >= st.first_sale_date + INTERVAL '10 months'
      AND o.order_purchase_timestamp <= st.first_sale_date + INTERVAL '12 months'
      AND o.order_status NOT IN ('cancelled', 'unavailable')
)
SELECT
    st.seller_id,
    st.first_sale_date,
    st.last_sale_date,
    st.total_orders,
    st.avg_order_value,
    f.orders_first_90d,
    f.avg_order_value_90d,
    f.avg_review_score_90d,
    ROUND(EXTRACT(EPOCH FROM (st.last_sale_date - st.first_sale_date)) / 2592000, 1) AS months_active,
    CASE WHEN m.seller_id IS NOT NULL THEN 1 ELSE 0 END    AS survived_month_12,
    s.seller_state,
    s.seller_city
FROM seller_timeline st
LEFT JOIN first_90_days f ON st.seller_id = f.seller_id
LEFT JOIN month12_activity m ON st.seller_id = m.seller_id
LEFT JOIN sellers s ON st.seller_id = s.seller_id;
