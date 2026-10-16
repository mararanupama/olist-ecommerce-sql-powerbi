USE olist_bi;

CREATE INDEX idx_orders_order_id ON raw_orders(order_id);
CREATE INDEX idx_orders_customer_id ON raw_orders(customer_id);
CREATE INDEX idx_orders_purchase_timestamp ON raw_orders(order_purchase_timestamp);
CREATE INDEX idx_items_order_id ON raw_order_items(order_id);
CREATE INDEX idx_items_product_id ON raw_order_items(product_id);
CREATE INDEX idx_items_seller_id ON raw_order_items(seller_id);
CREATE INDEX idx_payments_order_id ON raw_order_payments(order_id);
CREATE INDEX idx_reviews_order_id ON raw_order_reviews(order_id);
CREATE INDEX idx_customers_customer_id ON raw_customers(customer_id);
CREATE INDEX idx_customers_unique_id ON raw_customers(customer_unique_id);
CREATE INDEX idx_products_product_id ON raw_products(product_id);
CREATE INDEX idx_sellers_seller_id ON raw_sellers(seller_id);
CREATE INDEX idx_translation_category ON raw_category_translation(product_category_name);
