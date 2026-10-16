USE olist_bi;

CREATE OR REPLACE VIEW dim_customer AS
SELECT
    customer_id,
    customer_unique_id,
    CAST(customer_zip_code_prefix AS UNSIGNED) AS customer_zip_code_prefix,
    TRIM(customer_city) AS customer_city,
    customer_state
FROM raw_customers;

CREATE OR REPLACE VIEW dim_product AS
SELECT
    p.product_id,
    TRIM(BOTH '\r' FROM COALESCE(t.product_category_name_english, p.product_category_name, 'unknown')) AS product_category,
    CAST(NULLIF(p.product_name_length, '') AS UNSIGNED) AS product_name_length,
    CAST(NULLIF(p.product_description_length, '') AS UNSIGNED) AS product_description_length,
    CAST(NULLIF(p.product_photos_qty, '') AS UNSIGNED) AS product_photos_qty,
    CAST(NULLIF(p.product_weight_g, '') AS DECIMAL(12,2)) AS product_weight_g,
    CAST(NULLIF(p.product_length_cm, '') AS DECIMAL(10,2)) AS product_length_cm,
    CAST(NULLIF(p.product_height_cm, '') AS DECIMAL(10,2)) AS product_height_cm,
    CAST(NULLIF(p.product_width_cm, '') AS DECIMAL(10,2)) AS product_width_cm
FROM raw_products p
LEFT JOIN raw_category_translation t
    ON p.product_category_name = t.product_category_name;

CREATE OR REPLACE VIEW dim_seller AS
SELECT
    seller_id,
    CAST(seller_zip_code_prefix AS UNSIGNED) AS seller_zip_code_prefix,
    TRIM(seller_city) AS seller_city,
    seller_state
FROM raw_sellers;

CREATE OR REPLACE VIEW vw_fact_order_items AS
SELECT
    CONCAT(i.order_id, '-', LPAD(i.order_item_id, 2, '0')) AS order_item_key,
    i.order_id,
    CAST(i.order_item_id AS UNSIGNED) AS order_item_number,
    o.customer_id,
    c.customer_unique_id,
    i.product_id,
    i.seller_id,
    STR_TO_DATE(o.order_purchase_timestamp, '%Y-%m-%d %H:%i:%s') AS purchase_timestamp,
    DATE(STR_TO_DATE(o.order_purchase_timestamp, '%Y-%m-%d %H:%i:%s')) AS purchase_date,
    o.order_status,
    CAST(i.price AS DECIMAL(12,2)) AS item_revenue,
    CAST(i.freight_value AS DECIMAL(12,2)) AS freight_value,
    CAST(i.price AS DECIMAL(12,2)) + CAST(i.freight_value AS DECIMAL(12,2)) AS item_total,
    CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END AS delivered_flag
FROM raw_order_items i
JOIN raw_orders o ON i.order_id = o.order_id
JOIN raw_customers c ON o.customer_id = c.customer_id;

CREATE OR REPLACE VIEW vw_fact_orders AS
WITH item_summary AS (
    SELECT order_id,
           COUNT(*) AS item_count,
           COUNT(DISTINCT seller_id) AS seller_count,
           SUM(CAST(price AS DECIMAL(12,2))) AS item_revenue,
           SUM(CAST(freight_value AS DECIMAL(12,2))) AS freight_value
    FROM raw_order_items
    GROUP BY order_id
),
payment_summary AS (
    SELECT order_id,
           SUM(CAST(payment_value AS DECIMAL(12,2))) AS payment_value,
           MAX(CAST(payment_installments AS UNSIGNED)) AS max_installments,
           COUNT(*) AS payment_count
    FROM raw_order_payments
    GROUP BY order_id
),
review_summary AS (
    SELECT order_id,
           AVG(CAST(review_score AS DECIMAL(4,2))) AS review_score,
           COUNT(*) AS review_count
    FROM raw_order_reviews
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    STR_TO_DATE(o.order_purchase_timestamp, '%Y-%m-%d %H:%i:%s') AS purchase_timestamp,
    DATE(STR_TO_DATE(o.order_purchase_timestamp, '%Y-%m-%d %H:%i:%s')) AS purchase_date,
    STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s') AS delivered_timestamp,
    DATE(STR_TO_DATE(o.order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s')) AS estimated_delivery_date,
    COALESCE(i.item_count, 0) AS item_count,
    COALESCE(i.seller_count, 0) AS seller_count,
    COALESCE(i.item_revenue, 0) AS item_revenue,
    COALESCE(i.freight_value, 0) AS freight_value,
    COALESCE(p.payment_value, 0) AS payment_value,
    COALESCE(p.max_installments, 0) AS max_installments,
    r.review_score,
    CASE
        WHEN NULLIF(o.order_delivered_customer_date, '') IS NULL THEN NULL
        ELSE TIMESTAMPDIFF(
            DAY,
            STR_TO_DATE(o.order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(o.order_delivered_customer_date, '%Y-%m-%d %H:%i:%s')
        )
    END AS delivery_days,
    CASE
        WHEN o.order_status <> 'delivered' THEN NULL
        WHEN DATE(STR_TO_DATE(o.order_delivered_customer_date, '%Y-%m-%d %H:%i:%s'))
             > DATE(STR_TO_DATE(o.order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s')) THEN 1
        ELSE 0
    END AS late_delivery_flag,
    CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END AS delivered_flag,
    CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END AS canceled_flag
FROM raw_orders o
JOIN raw_customers c ON o.customer_id = c.customer_id
LEFT JOIN item_summary i ON o.order_id = i.order_id
LEFT JOIN payment_summary p ON o.order_id = p.order_id
LEFT JOIN review_summary r ON o.order_id = r.order_id;

CREATE OR REPLACE VIEW vw_customer_summary AS
SELECT
    customer_unique_id,
    COUNT(*) AS order_count,
    SUM(item_revenue) AS lifetime_item_revenue,
    AVG(review_score) AS average_review_score,
    MIN(purchase_date) AS first_purchase_date,
    MAX(purchase_date) AS last_purchase_date,
    CASE WHEN COUNT(*) > 1 THEN 1 ELSE 0 END AS repeat_customer_flag
FROM vw_fact_orders
GROUP BY customer_unique_id;
