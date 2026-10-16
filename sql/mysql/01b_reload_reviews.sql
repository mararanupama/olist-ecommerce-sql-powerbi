USE olist_bi;

TRUNCATE TABLE raw_order_reviews;

LOAD DATA LOCAL INFILE 'data/staged/olist_order_reviews_clean.csv'
INTO TABLE raw_order_reviews CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

SELECT COUNT(*) AS review_rows FROM raw_order_reviews;
SHOW WARNINGS LIMIT 10;
