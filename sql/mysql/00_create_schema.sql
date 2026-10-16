DROP DATABASE IF EXISTS olist_bi;
CREATE DATABASE olist_bi CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE olist_bi;

CREATE TABLE raw_customers (
    customer_id VARCHAR(32),
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

CREATE TABLE raw_geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat VARCHAR(40),
    geolocation_lng VARCHAR(40),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2)
);

CREATE TABLE raw_order_items (
    order_id VARCHAR(32),
    order_item_id VARCHAR(10),
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date VARCHAR(30),
    price VARCHAR(30),
    freight_value VARCHAR(30)
);

CREATE TABLE raw_order_payments (
    order_id VARCHAR(32),
    payment_sequential VARCHAR(10),
    payment_type VARCHAR(30),
    payment_installments VARCHAR(10),
    payment_value VARCHAR(30)
);

CREATE TABLE raw_order_reviews (
    review_id VARCHAR(32),
    order_id VARCHAR(32),
    review_score VARCHAR(10),
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date VARCHAR(30),
    review_answer_timestamp VARCHAR(30)
);

CREATE TABLE raw_orders (
    order_id VARCHAR(32),
    customer_id VARCHAR(32),
    order_status VARCHAR(30),
    order_purchase_timestamp VARCHAR(30),
    order_approved_at VARCHAR(30),
    order_delivered_carrier_date VARCHAR(30),
    order_delivered_customer_date VARCHAR(30),
    order_estimated_delivery_date VARCHAR(30)
);

CREATE TABLE raw_products (
    product_id VARCHAR(32),
    product_category_name VARCHAR(100),
    product_name_length VARCHAR(20),
    product_description_length VARCHAR(20),
    product_photos_qty VARCHAR(20),
    product_weight_g VARCHAR(20),
    product_length_cm VARCHAR(20),
    product_height_cm VARCHAR(20),
    product_width_cm VARCHAR(20)
);

CREATE TABLE raw_sellers (
    seller_id VARCHAR(32),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

CREATE TABLE raw_category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);
