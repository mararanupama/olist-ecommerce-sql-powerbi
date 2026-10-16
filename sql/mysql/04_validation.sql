USE olist_bi;

SELECT 'raw_customers' AS table_name, COUNT(*) AS row_count FROM raw_customers
UNION ALL SELECT 'raw_geolocation', COUNT(*) FROM raw_geolocation
UNION ALL SELECT 'raw_order_items', COUNT(*) FROM raw_order_items
UNION ALL SELECT 'raw_order_payments', COUNT(*) FROM raw_order_payments
UNION ALL SELECT 'raw_order_reviews', COUNT(*) FROM raw_order_reviews
UNION ALL SELECT 'raw_orders', COUNT(*) FROM raw_orders
UNION ALL SELECT 'raw_products', COUNT(*) FROM raw_products
UNION ALL SELECT 'raw_sellers', COUNT(*) FROM raw_sellers
UNION ALL SELECT 'raw_category_translation', COUNT(*) FROM raw_category_translation;

SELECT
    (SELECT COUNT(*) FROM vw_fact_orders) AS fact_order_rows,
    (SELECT COUNT(DISTINCT order_id) FROM vw_fact_orders) AS distinct_fact_orders,
    (SELECT COUNT(*) FROM vw_fact_order_items) AS fact_item_rows,
    (SELECT COUNT(*) FROM dim_product) AS product_rows,
    (SELECT COUNT(*) FROM dim_seller) AS seller_rows;

SELECT
    SUM(order_id IS NULL OR order_id = '') AS missing_order_ids,
    SUM(customer_id IS NULL OR customer_id = '') AS missing_customer_ids,
    SUM(purchase_date IS NULL) AS invalid_purchase_dates,
    SUM(item_revenue < 0) AS negative_revenue_rows
FROM vw_fact_orders;

SELECT i.order_id
FROM raw_order_items i
LEFT JOIN raw_orders o ON i.order_id = o.order_id
WHERE o.order_id IS NULL
LIMIT 20;
