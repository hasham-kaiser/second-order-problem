-- Freight cost by region: which states pay the highest freight relative to order value
WITH order_items_table AS (
    SELECT order_id,
           SUM(price) AS order_value,
           SUM(freight_value) AS freight_cost
    FROM order_items
    GROUP BY order_id
)
SELECT customer_state,
       COUNT(*) AS order_count,
       ROUND(AVG(freight_cost), 2) AS avg_freight_cost,
       ROUND(SUM(freight_cost) / SUM(order_value) * 100.0, 2) AS freight_pct_of_order_value
FROM order_items_table oit
JOIN orders o ON oit.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY freight_pct_of_order_value DESC;
