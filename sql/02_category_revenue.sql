-- Revenue and share by product category across all delivered orders
SELECT COALESCE(c.product_category_name_english, p.product_category_name, 'Uncategorized') AS category,
       SUM(price) AS revenue,
       ROUND(SUM(price) / SUM(SUM(price)) OVER () * 100, 2) AS category_share
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN categories c ON p.product_category_name = c.product_category_name
WHERE order_status = 'delivered'
GROUP BY COALESCE(c.product_category_name_english, p.product_category_name, 'Uncategorized')
ORDER BY revenue DESC;
