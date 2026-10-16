# Olist e-commerce: SQL and Power BI

A portfolio analysis of sales, seller contribution and delivery experience using Olist's historical public dataset.

- [Case study and interactive report](https://anupamav.com/olist/)
- The report has four pages: Market Geography, Sales & Assortment, Seller Network and Delivery Experience.
- Values are in Brazilian reais (BRL). Revenue covers products in delivered orders and excludes freight.

## Findings

Verified against the public report on 16 October 2026, with all report slicers set to All:

- The Southeast generated 65.4% of customer revenue: R$8,648,409.57 out of R$13,221,498.11.
- The ten leading sellers generated R$1,754,800, or 13.3% of delivered product revenue, among 2,970 active sellers.
- The Northeast's observed late-delivery rate was 12.7%, compared with 6.8% overall.
- Reviewed on-time orders averaged 4.29/5; reviewed late orders averaged 2.27/5. This is an association, not a causal estimate.

See `results/report-findings.json` for the values, filters, calculations and reconciliation used in the case study. These are a dated report snapshot, not live results or proof of a new database execution.

## Source files

`sql/mysql/` contains the project SQL:

- `00_create_schema.sql`: staging tables. This script recreates the dedicated `olist_bi` database; use a disposable local project database.
- `01_load_data.sql`: imports source CSVs and the cleaned review file. File paths have been made relative for portability; adjust them for your MySQL client and local data location.
- `01b_reload_reviews.sql`: reloads the cleaned review file when required.
- `02a_create_indexes.sql`: supporting indexes.
- `02_analytics_views.sql`: typed dimensions, order-item facts, order facts and customer summaries.
- `03_business_analysis.sql`: exploratory business queries, including monthly trends, rankings and delivery comparisons.
- `04_validation.sql`: row counts, unique order IDs, missing IDs, invalid dates and orphan item checks.
- `05_geographic_analysis.sql`: postcode geography preparation, regional extraction and customer join checks.

`powerbi/KPI Measures.tmdl` contains the report's DAX definitions. The standalone measure table is reference source, not a complete PBIP project. Exploratory SQL queries may use a different grain or denominator from a report KPI; use the DAX definitions and report glossary when interpreting the published findings.

## Reproduce the workflow

1. Obtain the Brazilian E-Commerce Public Dataset by Olist from its original distribution and place its CSVs in `data/raw/`.
2. Prepare `data/staged/olist_order_reviews_clean.csv` by parsing the review CSV with a CSV-aware reader, replacing embedded comment line breaks with spaces and writing CRLF-terminated records. The source comments must not be split into extra SQL rows. The review load expects 99,224 parsed source review records.
3. Use MySQL 8.0, review the schema reset script, and run the schema, loading, index and view scripts in the dedicated project database. CSV loading requires LOCAL INFILE support in the client and server.
4. Run the validation queries before using the analytical views.
5. Run the business queries and optional geography script; connect Power BI to the views.

The original MySQL views back the imported commercial facts. The report uses a geography snapshot prepared from source CSVs; `05_geographic_analysis.sql` implements the equivalent postcode-cleaning logic in MySQL.

## Modelling choices

Orders and order items remain separate so joins do not multiply order counts. Items, payments and reviews are aggregated to one row per order before joining into order facts. Product cleaning uses TRIM, COALESCE, NULLIF and explicit numeric casts. CASE expressions define delivery flags. Customer and seller geography are separate roles.

Late-delivery rates use delivered orders with both actual and estimated dates. Reviews without a score are excluded from review averages. Regional and seller patterns are historical observations. Revenue is not profit; freight charged is not the cost of logistics.

## Data attribution

Brazilian E-Commerce Public Dataset by Olist: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

The source project's documentation identifies the dataset as CC BY-NC-SA 4.0. Obtain the data from its original distribution and follow its licence. This source package does not redistribute customer records or review comments.
