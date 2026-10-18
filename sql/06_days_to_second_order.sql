-- Median days between first and second delivered order for repeat customers
WITH repeat_customer_orders AS (
    SELECT customer_unique_id,
           DATE_TRUNC('day', order_purchase_timestamp) AS day,
           ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY DATE_TRUNC('day', order_purchase_timestamp)) AS purchase_order
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id, DATE_TRUNC('day', order_purchase_timestamp)
),
gap_bw_first_two_orders AS (
    SELECT a.customer_unique_id,
           a.day AS first_order,
           b.day AS second_order,
           DATEDIFF('day', a.day, b.day) AS order_days_difference
    FROM repeat_customer_orders a
    JOIN repeat_customer_orders b ON a.customer_unique_id = b.customer_unique_id
    WHERE a.purchase_order = 1
      AND b.purchase_order = 2
)
SELECT MEDIAN(order_days_difference) AS median_days_to_second_order
FROM gap_bw_first_two_orders;
