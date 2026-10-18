-- Customers who placed more than one delivered order on the same calendar day
SELECT COUNT(*) AS same_day_customers
FROM (
    SELECT customer_unique_id, DATE_TRUNC('day', order_purchase_timestamp) AS day
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id, DATE_TRUNC('day', order_purchase_timestamp)
    HAVING COUNT(*) > 1
) AS same_day_table;
