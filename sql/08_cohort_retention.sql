-- Cohort retention: share of each monthly cohort still purchasing in later months, Jan 2017 to Aug 2018
WITH first_purchase_table AS (
    SELECT c.customer_unique_id,
           MIN(DATE_TRUNC('month', order_purchase_timestamp)) AS first_purchase_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
),
order_gap_table AS (
    SELECT fpt.customer_unique_id,
           first_purchase_month,
           DATE_TRUNC('month', order_purchase_timestamp) AS order_month,
           DATEDIFF('month', first_purchase_month, DATE_TRUNC('month', order_purchase_timestamp)) AS month_number
    FROM first_purchase_table fpt
    JOIN customers c ON fpt.customer_unique_id = c.customer_unique_id
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp < '2018-09-01'
    GROUP BY fpt.customer_unique_id, first_purchase_month,
             DATE_TRUNC('month', order_purchase_timestamp)
),
retained_users_table AS (
    SELECT first_purchase_month,
           month_number,
           COUNT(DISTINCT customer_unique_id) AS retained_customers
    FROM order_gap_table
    WHERE first_purchase_month >= '2017-01-01'
      AND first_purchase_month < '2018-09-01'
    GROUP BY first_purchase_month, month_number
)
SELECT first_purchase_month,
       month_number,
       retained_customers,
       FIRST_VALUE(retained_customers) OVER (PARTITION BY first_purchase_month ORDER BY month_number) AS cohort_size,
       ROUND(retained_customers / FIRST_VALUE(retained_customers) OVER (PARTITION BY first_purchase_month ORDER BY month_number) * 100.0, 1) AS retention_rate
FROM retained_users_table
ORDER BY first_purchase_month, month_number;
