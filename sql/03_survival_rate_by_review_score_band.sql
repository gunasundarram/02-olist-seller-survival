SELECT
    CASE
        WHEN avg_review_score_90d IS NULL THEN 'No reviews'
        WHEN avg_review_score_90d < 3 THEN 'Low (< 3.0)'
        WHEN avg_review_score_90d BETWEEN 3 AND 3.9 THEN 'Medium (3.0-3.9)'
        WHEN avg_review_score_90d BETWEEN 4 AND 4.4 THEN 'Good (4.0-4.4)'
        ELSE 'Excellent (4.5+)'
    END                                         AS review_band,
    COUNT(*)                                    AS total_sellers,
    SUM(survived_month_12)                      AS survived,
    ROUND(100.0 * SUM(survived_month_12)
          / COUNT(*), 1)                        AS survival_rate_pct
FROM seller_survival
GROUP BY review_band
ORDER BY MIN(avg_review_score_90d) NULLS FIRST;