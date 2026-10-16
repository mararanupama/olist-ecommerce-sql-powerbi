USE olist_bi;

-- One postcode row prevents repeated geolocation points from multiplying orders.
CREATE OR REPLACE VIEW vw_postcode_geography AS
WITH valid_points AS (
    SELECT DISTINCT
        LPAD(TRIM(geolocation_zip_code_prefix), 5, '0') AS postcode,
        UPPER(TRIM(geolocation_state)) AS state_code,
        CAST(geolocation_lat AS DECIMAL(18,12)) AS latitude,
        CAST(geolocation_lng AS DECIMAL(18,12)) AS longitude
    FROM raw_geolocation
    WHERE CAST(geolocation_lat AS DECIMAL(18,12)) BETWEEN -34 AND 6
      AND CAST(geolocation_lng AS DECIMAL(18,12)) BETWEEN -74 AND -32
      AND UPPER(TRIM(geolocation_state)) IN
          ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
           'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO')
), ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY postcode, state_code ORDER BY latitude, longitude) AS latitude_rank,
        ROW_NUMBER() OVER (PARTITION BY postcode, state_code ORDER BY longitude, latitude) AS longitude_rank,
        COUNT(*) OVER (PARTITION BY postcode, state_code) AS source_points
    FROM valid_points
), medians AS (
    SELECT postcode, state_code, MAX(source_points) AS source_points,
        AVG(CASE WHEN latitude_rank IN (FLOOR((source_points+1)/2), FLOOR((source_points+2)/2)) THEN latitude END) AS latitude,
        AVG(CASE WHEN longitude_rank IN (FLOOR((source_points+1)/2), FLOOR((source_points+2)/2)) THEN longitude END) AS longitude
    FROM ranked
    GROUP BY postcode, state_code
), canonical AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY postcode ORDER BY source_points DESC, state_code) AS postcode_rank
    FROM medians
)
SELECT postcode, state_code, latitude, longitude, source_points
FROM canonical
WHERE postcode_rank = 1;

-- Delivered merchandise sales exclude freight, payments, canceled and unfinished orders.
SELECT c.customer_state,
       COUNT(*) AS delivered_orders,
       ROUND(SUM(o.item_revenue), 2) AS delivered_revenue_brl,
       ROUND(AVG(o.delivery_days), 1) AS average_delivery_days,
       ROUND(100 * SUM(o.late_delivery_flag)
           / NULLIF(SUM(o.delivered_timestamp IS NOT NULL AND o.estimated_delivery_date IS NOT NULL), 0), 2) AS observed_late_delivery_pct,
       ROUND(AVG(o.review_score), 2) AS average_review_score
FROM vw_fact_orders o
JOIN dim_customer c ON c.customer_id = o.customer_id
WHERE o.delivered_flag = 1
GROUP BY c.customer_state
ORDER BY delivered_revenue_brl DESC;

-- These counts must match before using postcode coordinates in a report.
SELECT COUNT(*) AS customer_rows_before_join FROM dim_customer;
SELECT COUNT(*) AS customer_rows_after_join,
       SUM(g.postcode IS NULL) AS customers_without_coordinates
FROM dim_customer c
LEFT JOIN vw_postcode_geography g
  ON LPAD(c.customer_zip_code_prefix, 5, '0') = g.postcode;
