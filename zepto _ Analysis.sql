USE zepto_analysis;
SELECT DATABASE();
SHOW TABLES;

# 1 Delivery Performance
#  Average delivery time
SELECT ROUND(AVG(actual_minutes),2) AS avg_delivery_time
FROM deliveries;
select * FROM deliveries;

#  On-time vs Late deliveries
SELECT delivery_status, COUNT(*) AS total_orders
FROM deliveries
GROUP BY delivery_status;

#On-time delivery % 
SELECT 
ROUND(SUM(CASE WHEN delivery_status='On Time' THEN 1 ELSE 0 END)*100.0/COUNT(*),2)
AS on_time_percentage
FROM deliveries;

# 2️  Customer Behavior
# Repeat customers
SELECT customer_id, COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) > 1;
select * from orders;

# Orders per customer
SELECT 
ROUND(COUNT(order_id)*1.0/COUNT(DISTINCT customer_id),2)
AS avg_orders_per_customer
FROM orders;

#3️  Revenue Analysis
#   Total revenue
SELECT SUM(order_value) AS total_revenue
FROM orders;

# City-wise revenue
SELECT city, SUM(order_value) AS revenue
FROM orders
GROUP BY city;


# 4️  Product Demand
# Most sold products
SELECT p.product_name, SUM(oi.quantity) AS total_quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC;


# 5️ Peak Order Time
SELECT HOUR(order_date) AS order_hour, COUNT(*) AS total_orders
FROM orders
GROUP BY order_hour
ORDER BY total_orders DESC;

# 1️  Customer → Order → Delivery (Deep Join)
SELECT 
    c.customer_name,
    c.city,
    o.order_id,
    o.order_value,
    d.actual_minutes,
    d.delivery_status
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN deliveries d ON o.order_id = d.order_id;

# 2 CTE: On-time vs Late Delivery Summary
WITH delivery_summary AS (
    SELECT delivery_status, COUNT(*) AS total_orders
    FROM deliveries
    GROUP BY delivery_status
)
SELECT * FROM delivery_summary;

# 3  Window Function: Rank delivery partners by speed
SELECT 
    dp.partner_name,
    ROUND(AVG(d.actual_minutes),2) AS avg_delivery_time,
    RANK() OVER (ORDER BY AVG(d.actual_minutes)) AS speed_rank
FROM deliveries d
JOIN delivery_partners dp ON d.partner_id = dp.partner_id
GROUP BY dp.partner_name;

# 4    Window Function: Customer spending rank
SELECT 
    c.customer_name,
    SUM(o.order_value) AS total_spent,
    DENSE_RANK() OVER (ORDER BY SUM(o.order_value) DESC) AS spending_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name;

#  5   Subquery: Orders with delivery delay > average
SELECT order_id, actual_minutes
FROM deliveries
WHERE actual_minutes > (
    SELECT AVG(actual_minutes) FROM deliveries
);

# 6 CTE: City-wise delivery performance
WITH city_delivery AS (
    SELECT o.city, ROUND(AVG(d.actual_minutes),2) AS avg_time
    FROM orders o
    JOIN deliveries d ON o.order_id = d.order_id
    GROUP BY o.city
)
SELECT * FROM city_delivery;

# 7   Top 2 products by demand
SELECT product_name, total_quantity
FROM (
    SELECT 
        p.product_name,
        SUM(oi.quantity) AS total_quantity,
        RANK() OVER (ORDER BY SUM(oi.quantity) DESC) AS rnk
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_name
) t
WHERE rnk <= 2;
