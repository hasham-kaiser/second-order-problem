-- RFM segmentation: recency and monetary scored with NTILE, frequency as a repeat flag
WITH customer_rfm_base AS (
    SELECT customer_unique_id,
           DATEDIFF('day', MAX(DATE_TRUNC('day', order_purchase_timestamp)),
                    (SELECT MAX(order_purchase_timestamp) FROM orders)) AS days_since_last_purchase,
           COUNT(DISTINCT DATE_TRUNC('day', order_purchase_timestamp)) AS no_of_purchase_days,
           ROUND(SUM(price), 2) AS spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
),
ntile_table AS (
    SELECT customer_unique_id,
           days_since_last_purchase,
           spend,
           no_of_purchase_days,
           NTILE(5) OVER (ORDER BY days_since_last_purchase DESC, customer_unique_id) AS recency_score,
           NTILE(5) OVER (ORDER BY spend, customer_unique_id) AS monetary_score,
           CASE WHEN no_of_purchase_days > 1 THEN 1 ELSE 0 END AS frequency_flag
    FROM customer_rfm_base
)
SELECT customer_unique_id,
       days_since_last_purchase,
       spend,
       no_of_purchase_days,
       recency_score,
       monetary_score,
       frequency_flag,
       CASE
           WHEN frequency_flag = 1 AND recency_score BETWEEN 4 AND 5 AND monetary_score BETWEEN 4 AND 5 THEN 'Repeat, recent, high spend'
           WHEN frequency_flag = 1 AND recency_score BETWEEN 4 AND 5 AND monetary_score BETWEEN 1 AND 3 THEN 'Repeat, recent, low spend'
           WHEN frequency_flag = 1 AND recency_score BETWEEN 1 AND 3 AND monetary_score BETWEEN 4 AND 5 THEN 'Repeat, lapsed, high spend'
           WHEN frequency_flag = 1 AND recency_score BETWEEN 1 AND 3 AND monetary_score BETWEEN 1 AND 3 THEN 'Repeat, lapsed, low spend'
           WHEN frequency_flag = 0 AND recency_score BETWEEN 4 AND 5 AND monetary_score BETWEEN 4 AND 5 THEN 'One-time, recent, high spend'
           WHEN frequency_flag = 0 AND recency_score BETWEEN 4 AND 5 AND monetary_score BETWEEN 1 AND 3 THEN 'One-time, recent, low spend'
           WHEN frequency_flag = 0 AND recency_score BETWEEN 1 AND 3 AND monetary_score BETWEEN 4 AND 5 THEN 'One-time, lapsed, high spend'
           WHEN frequency_flag = 0 AND recency_score BETWEEN 1 AND 3 AND monetary_score BETWEEN 1 AND 3 THEN 'One-time, lapsed, low spend'
       END AS segment
FROM ntile_table;
