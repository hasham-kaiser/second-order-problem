-- Top 20 sellers by revenue across all delivered orders, with share of total
SELECT seller_id,
       SUM(price) AS revenue,
       ROUND(SUM(price) / SUM(SUM(price)) OVER () * 100, 2) AS revenue_share,
       RANK() OVER (ORDER BY SUM(price) DESC) AS rank
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE order_status = 'delivered'
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 20;
