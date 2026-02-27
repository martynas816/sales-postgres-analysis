-- Daily "commercial support" query pack
-- Typical questions:
-- 1) What happened yesterday?
-- 2) Why did KPI change? (drivers)
-- 3) Give me numbers for a segment (promo/country/product line)
--
-- Assumes star schema already built (run 05_build_star_schema.sql)

-- =========================
-- 0) FAST VALIDATION CHECKS
-- =========================

-- Data freshness
SELECT MAX(orderdate) AS latest_orderdate
FROM sales.sales_clean;

-- Fact table row count
SELECT COUNT(*) AS fact_rows
FROM sales.fct_order_lines;

-- Duplicate grain check (should return 0 rows)
SELECT ordernumber, orderlinenumber, COUNT(*) AS n
FROM sales.fct_order_lines
GROUP BY 1,2
HAVING COUNT(*) > 1;


-- =========================
-- 1) "WHAT HAPPENED YESTERDAY?"
-- =========================

-- Replace the date if you want (e.g. DATE '2004-11-30')
WITH params AS (
  SELECT (MAX(date) - INTERVAL '1 day')::date AS target_date
  FROM sales.dim_date
), base AS (
  SELECT
    d.date,
    f.ordernumber,
    f.quantityordered,
    f.line_sales,
    f.status
  FROM sales.fct_order_lines f
  JOIN sales.dim_date d ON d.date_id = f.date_id
  JOIN params p ON d.date = p.target_date
)
SELECT
  (SELECT target_date FROM params) AS date,
  ROUND(SUM(line_sales) FILTER (WHERE status NOT ILIKE 'Cancelled%'), 2) AS net_revenue,
  COUNT(DISTINCT ordernumber) FILTER (WHERE status NOT ILIKE 'Cancelled%') AS net_orders,
  SUM(quantityordered) FILTER (WHERE status NOT ILIKE 'Cancelled%') AS net_units,
  ROUND(
    SUM(line_sales) FILTER (WHERE status NOT ILIKE 'Cancelled%')
    / NULLIF(COUNT(DISTINCT ordernumber) FILTER (WHERE status NOT ILIKE 'Cancelled%'), 0),
    2
  ) AS aov,
  ROUND(
    100.0 * COUNT(DISTINCT ordernumber) FILTER (WHERE status ILIKE 'Cancelled%')
    / NULLIF(COUNT(DISTINCT ordernumber), 0),
    2
  ) AS cancel_rate_orders_pct
FROM base;


-- =========================
-- 2) "WHY DID KPI CHANGE?" (DoD drivers)
-- =========================

-- Step A: Net revenue trend (last 14 days)
WITH daily AS (
  SELECT
    d.date,
    ROUND(SUM(f.line_sales) FILTER (WHERE f.status NOT ILIKE 'Cancelled%'), 2) AS net_revenue
  FROM sales.fct_order_lines f
  JOIN sales.dim_date d ON d.date_id = f.date_id
  GROUP BY 1
)
SELECT
  date,
  net_revenue,
  ROUND(net_revenue - LAG(net_revenue) OVER (ORDER BY date), 2) AS dod_change,
  ROUND(
    100 * (net_revenue - LAG(net_revenue) OVER (ORDER BY date))
    / NULLIF(LAG(net_revenue) OVER (ORDER BY date), 0),
    2
  ) AS dod_change_pct
FROM daily
ORDER BY date DESC
LIMIT 14;

-- Step B: Drivers by COUNTRY (yesterday vs day before)
WITH params AS (
  SELECT
    (MAX(date) - INTERVAL '1 day')::date AS d1,
    (MAX(date) - INTERVAL '2 days')::date AS d0
  FROM sales.dim_date
), by_country AS (
  SELECT
    d.date,
    c.country,
    SUM(f.line_sales) FILTER (WHERE f.status NOT ILIKE 'Cancelled%') AS net_revenue
  FROM sales.fct_order_lines f
  JOIN sales.dim_date d       ON d.date_id = f.date_id
  JOIN sales.dim_customers c  ON c.customer_id = f.customer_id
  JOIN params p ON d.date IN (p.d0, p.d1)
  GROUP BY 1,2
), pivoted AS (
  SELECT
    country,
    SUM(net_revenue) FILTER (WHERE date = (SELECT d0 FROM params)) AS revenue_d0,
    SUM(net_revenue) FILTER (WHERE date = (SELECT d1 FROM params)) AS revenue_d1
  FROM by_country
  GROUP BY 1
)
SELECT
  country,
  ROUND(revenue_d1, 2) AS revenue_yesterday,
  ROUND(revenue_d0, 2) AS revenue_day_before,
  ROUND(revenue_d1 - revenue_d0, 2) AS change
FROM pivoted
ORDER BY ABS(revenue_d1 - revenue_d0) DESC
LIMIT 10;

-- Step C: Drivers by PRODUCT LINE
WITH params AS (
  SELECT
    (MAX(date) - INTERVAL '1 day')::date AS d1,
    (MAX(date) - INTERVAL '2 days')::date AS d0
  FROM sales.dim_date
), by_pl AS (
  SELECT
    d.date,
    p.productline,
    SUM(f.line_sales) FILTER (WHERE f.status NOT ILIKE 'Cancelled%') AS net_revenue
  FROM sales.fct_order_lines f
  JOIN sales.dim_date d      ON d.date_id = f.date_id
  JOIN sales.dim_products p  ON p.product_id = f.product_id
  JOIN params x ON d.date IN (x.d0, x.d1)
  GROUP BY 1,2
), pivoted AS (
  SELECT
    productline,
    SUM(net_revenue) FILTER (WHERE date = (SELECT d0 FROM params)) AS revenue_d0,
    SUM(net_revenue) FILTER (WHERE date = (SELECT d1 FROM params)) AS revenue_d1
  FROM by_pl
  GROUP BY 1
)
SELECT
  productline,
  ROUND(revenue_d1, 2) AS revenue_yesterday,
  ROUND(revenue_d0, 2) AS revenue_day_before,
  ROUND(revenue_d1 - revenue_d0, 2) AS change
FROM pivoted
ORDER BY ABS(revenue_d1 - revenue_d0) DESC
LIMIT 10;


-- =========================
-- 3) "NUMBERS FOR PROMO X" (segment template)
-- =========================
-- This dataset has no explicit promotion_id, so use this as a template.
-- Common real-world segments: campaign_id, channel, coupon_code, product set.

-- Example segment: productline = 'Classic Cars' for the last 30 days
WITH params AS (
  SELECT (MAX(date) - INTERVAL '30 days')::date AS start_date, MAX(date)::date AS end_date
  FROM sales.dim_date
)
SELECT
  p.productline,
  ROUND(SUM(f.line_sales) FILTER (WHERE f.status NOT ILIKE 'Cancelled%'), 2) AS net_revenue,
  COUNT(DISTINCT f.ordernumber) FILTER (WHERE f.status NOT ILIKE 'Cancelled%') AS orders,
  SUM(f.quantityordered) FILTER (WHERE f.status NOT ILIKE 'Cancelled%') AS units
FROM sales.fct_order_lines f
JOIN sales.dim_date d      ON d.date_id = f.date_id
JOIN sales.dim_products p  ON p.product_id = f.product_id
JOIN params x ON d.date BETWEEN x.start_date AND x.end_date
WHERE p.productline = 'Classic Cars'
GROUP BY 1;
