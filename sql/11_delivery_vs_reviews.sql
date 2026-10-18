-- Delivery delay vs review score: average review by delay bucket
WITH updated_order_reviews AS (
    SELECT order_id, AVG(review_score) AS avg_review_score
    FROM order_reviews
    GROUP BY order_id
),
delivery_delay AS (
    SELECT o.order_id,
           avg_review_score,
           DATEDIFF('day', order_estimated_delivery_date, order_delivered_customer_date) AS delay_in_days
    FROM updated_order_reviews uor
    JOIN orders o ON uor.order_id = o.order_id
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
)
SELECT
    CASE
        WHEN delay_in_days < 0 THEN 'Early'
        WHEN delay_in_days = 0 THEN 'On time'
        WHEN delay_in_days BETWEEN 1 AND 3 THEN '1 to 3 days late'
        WHEN delay_in_days BETWEEN 4 AND 7 THEN '4 to 7 days late'
        ELSE 'Over 7 days late'
    END AS delivery_time,
    COUNT(*) AS orders,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score
FROM delivery_delay
GROUP BY CASE
        WHEN delay_in_days < 0 THEN 'Early'
        WHEN delay_in_days = 0 THEN 'On time'
        WHEN delay_in_days BETWEEN 1 AND 3 THEN '1 to 3 days late'
        WHEN delay_in_days BETWEEN 4 AND 7 THEN '4 to 7 days late'
        ELSE 'Over 7 days late'
    END
ORDER BY MIN(delay_in_days);
