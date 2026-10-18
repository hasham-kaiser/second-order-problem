-- First order experience: comparing repeat buyers vs one-time buyers on their first order
WITH first_order AS (
    SELECT customer_unique_id, order_id AS first_order_id
    FROM (
        SELECT c.customer_unique_id,
               o.order_id,
               ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp, o.order_id) AS order_rank
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        WHERE o.order_status = 'delivered'
    ) ranked_orders
    WHERE order_rank = 1
),
order_items_table AS (
    SELECT order_id, SUM(price) AS total_price, SUM(freight_value) AS freight_cost
    FROM order_items
    GROUP BY order_id
),
order_reviews_table AS (
    SELECT order_id, AVG(review_score) AS avg_review_score
    FROM order_reviews
    GROUP BY order_id
),
frequency_flag_table AS (
    SELECT customer_unique_id,
           CASE WHEN COUNT(DISTINCT DATE_TRUNC('day', order_purchase_timestamp)) > 1
                THEN 'Repeat' ELSE 'One-time' END AS customer_type
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
),
first_order_experience AS (
    SELECT c.customer_unique_id,
           DATEDIFF('day', order_estimated_delivery_date, order_delivered_customer_date) AS delay_in_days,
           avg_review_score,
           total_price,
           freight_cost,
           customer_type
    FROM first_order fo
    JOIN orders o ON fo.first_order_id = o.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items_table oit ON o.order_id = oit.order_id
    JOIN order_reviews_table ort ON oit.order_id = ort.order_id
    JOIN frequency_flag_table fft ON c.customer_unique_id = fft.customer_unique_id
    WHERE order_delivered_customer_date IS NOT NULL
)
SELECT customer_type,
       ROUND(AVG(delay_in_days), 1) AS average_delay,
       ROUND(COUNT(CASE WHEN delay_in_days > 0 THEN 1 END) / COUNT(*) * 100.0, 1) AS pct_delivered_late,
       ROUND(AVG(avg_review_score), 1) AS average_review_score,
       ROUND(AVG(total_price), 1) AS average_order_value,
       ROUND(AVG(freight_cost / total_price * 100.0), 1) AS avg_freight_pct
FROM first_order_experience
GROUP BY customer_type
ORDER BY customer_type;
