-- Repeat purchase rate: share of customers who ordered on at least two different days
WITH customer_days AS (
    SELECT customer_unique_id,
           COUNT(DISTINCT DATE_TRUNC('day', order_purchase_timestamp)) AS distinct_days
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
)
SELECT COUNT(*) AS total_customers,
       COUNT(CASE WHEN distinct_days > 1 THEN 1 END) AS repeat_customers,
       ROUND(COUNT(CASE WHEN distinct_days > 1 THEN 1 END) / COUNT(*) * 100, 2) AS repeat_rate
FROM customer_days;
