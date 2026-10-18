-- Data quality checks across the nine Olist tables: row counts, unique customers,
-- order status, date range, monthly volume, orphan keys, grain and nulls

-- Row counts per table
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'categories', COUNT(*) FROM categories
ORDER BY row_count DESC;

-- customer_id is unique per order, not per person, so count real people via customer_unique_id
SELECT COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

-- Revenue, delivery and review analysis will use delivered orders only
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- Date range of purchases
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- Monthly order counts, used to set the trend analysis window
SELECT DATE_TRUNC('month', order_purchase_timestamp) AS month,
       COUNT(*) AS orders
FROM orders
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY month;

-- Orphan checks: every foreign key should resolve to a row in its parent table
SELECT 'order_items -> orders' AS check_name, COUNT(*) AS orphans
FROM order_items WHERE order_id NOT IN (SELECT order_id FROM orders)
UNION ALL
SELECT 'order_payments -> orders', COUNT(*)
FROM order_payments WHERE order_id NOT IN (SELECT order_id FROM orders)
UNION ALL
SELECT 'order_reviews -> orders', COUNT(*)
FROM order_reviews WHERE order_id NOT IN (SELECT order_id FROM orders)
UNION ALL
SELECT 'orders -> customers', COUNT(*)
FROM orders WHERE customer_id NOT IN (SELECT customer_id FROM customers)
UNION ALL
SELECT 'order_items -> products', COUNT(*)
FROM order_items WHERE product_id NOT IN (SELECT product_id FROM products)
UNION ALL
SELECT 'order_items -> sellers', COUNT(*)
FROM order_items WHERE seller_id NOT IN (SELECT seller_id FROM sellers)
UNION ALL
SELECT 'products -> categories', COUNT(*)
FROM products WHERE product_category_name NOT IN (SELECT product_category_name FROM categories);

-- Grain check: order_id should appear exactly once in orders
SELECT order_id, COUNT(*) AS occurrences
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Grain check: orders with multiple reviews
SELECT order_id, COUNT(*) AS occurrences
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Grain check: orders with multiple payment rows (expected for installments and vouchers)
SELECT order_id, COUNT(*) AS occurrences
FROM order_payments
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Grain check: confirm primary keys are unique in lookup tables used in joins
SELECT 'products' AS table_name, COUNT(*) AS total_rows, COUNT(DISTINCT product_id) AS distinct_keys
FROM products
UNION ALL
SELECT 'categories', COUNT(*), COUNT(DISTINCT product_category_name)
FROM categories
UNION ALL
SELECT 'customers', COUNT(*), COUNT(DISTINCT customer_id)
FROM customers;

-- Null check: missing delivery dates cannot be used in delivery time calculations
SELECT COUNT(*) AS missing_delivery_dates
FROM orders
WHERE order_delivered_customer_date IS NULL;

-- Breakdown by status to confirm nulls are concentrated in non-delivered orders
SELECT order_status,
       COUNT(*) AS total,
       COUNT(order_delivered_customer_date) AS has_delivery_date,
       COUNT(*) - COUNT(order_delivered_customer_date) AS missing_delivery_date
FROM orders
GROUP BY order_status
ORDER BY total DESC;

-- Null check: missing prices would silently understate revenue
SELECT COUNT(*) AS missing_prices
FROM order_items
WHERE price IS NULL;

-- Null check: products with no category cannot be classified in revenue analysis
SELECT COUNT(*) AS missing_categories
FROM products
WHERE product_category_name IS NULL;

-- Null check: categories with no English translation
SELECT COUNT(*) AS missing_translations
FROM categories
WHERE product_category_name_english IS NULL;
