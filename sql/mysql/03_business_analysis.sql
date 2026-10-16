USE olist_bi;

-- 1. Monthly commercial trend and month-over-month revenue change.
WITH monthly AS (
    SELECT DATE_FORMAT(purchase_date, '%Y-%m-01') AS month_start,
           COUNT(*) AS orders,
           SUM(item_revenue) AS revenue,
           AVG(item_revenue) AS average_order_value
    FROM vw_fact_orders
    WHERE order_status = 'delivered'
    GROUP BY DATE_FORMAT(purchase_date, '%Y-%m-01')
)
SELECT month_start, orders, revenue, average_order_value,
       LAG(revenue) OVER (ORDER BY month_start) AS prior_month_revenue,
       (revenue / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0)) - 1 AS revenue_growth_rate
FROM monthly
ORDER BY month_start;

-- 2. Product categories ranked by delivered revenue and review score.
WITH category_performance AS (
    SELECT p.product_category,
           COUNT(DISTINCT i.order_id) AS orders,
           SUM(i.item_revenue) AS revenue,
           AVG(o.review_score) AS average_review_score
    FROM vw_fact_order_items i
    JOIN dim_product p ON i.product_id = p.product_id
    JOIN vw_fact_orders o ON i.order_id = o.order_id
    WHERE i.order_status = 'delivered'
    GROUP BY p.product_category
)
SELECT *, DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM category_performance
ORDER BY revenue_rank, product_category;

-- 3. Delivery lateness and customer satisfaction.
SELECT late_delivery_flag,
       COUNT(*) AS delivered_orders,
       AVG(delivery_days) AS average_delivery_days,
       AVG(review_score) AS average_review_score,
       AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) AS low_review_rate
FROM vw_fact_orders
WHERE order_status = 'delivered'
GROUP BY late_delivery_flag;

-- 4. Seller risk matrix: high revenue with weak reviews or late delivery.
WITH seller_performance AS (
    SELECT i.seller_id,
           COUNT(DISTINCT i.order_id) AS orders,
           SUM(i.item_revenue) AS revenue,
           AVG(o.review_score) AS average_review_score,
           AVG(o.late_delivery_flag) AS late_delivery_rate
    FROM vw_fact_order_items i
    JOIN vw_fact_orders o ON i.order_id = o.order_id
    WHERE i.order_status = 'delivered'
    GROUP BY i.seller_id
)
SELECT *,
       NTILE(4) OVER (ORDER BY revenue DESC) AS revenue_quartile
FROM seller_performance
WHERE orders >= 20
ORDER BY revenue DESC;

-- 5. Customer retention profile.
SELECT repeat_customer_flag,
       COUNT(*) AS customers,
       AVG(order_count) AS average_orders,
       AVG(lifetime_item_revenue) AS average_lifetime_revenue
FROM vw_customer_summary
GROUP BY repeat_customer_flag;
