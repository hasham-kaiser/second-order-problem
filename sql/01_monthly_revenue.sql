-- Monthly revenue and month-over-month change across delivered orders, Jan 2017 to Aug 2018
WITH revenue_by_month AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp) AS month,
           SUM(price) AS revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp < '2018-09-01'
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
)
SELECT month,
       revenue,
       revenue - LAG(revenue) OVER (ORDER BY month) AS mom_change
FROM revenue_by_month
ORDER BY month;
