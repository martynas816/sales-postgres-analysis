-- Advanced analytics queries (window functions, cohorts, segmentation)
-- Run after: 01_schema.sql -> 05_build_star_schema.sql

-- =============================================
-- 1) Monthly revenue trend + MoM change + rolling avg
-- =============================================
WITH monthly AS (
  SELECT
    DATE_TRUNC('month', d.date)::date AS month,
    SUM(f.line_sales) FILTER (WHERE f.status ILIKE 'Cancelled%')     AS cancelled_revenue,
    SUM(f.line_sales) FILTER (WHERE f.status NOT ILIKE 'Cancelled%') AS net_revenue
  FROM sales.fct_order_lines f
  JOIN sales.dim_date d ON d.date_id = f.date_id
  GROUP BY 1
)
SELECT
  month,
  ROUND(net_revenue, 2) AS net_revenue,
  ROUND(cancelled_revenue, 2) AS cancelled_revenue,
  ROUND(net_revenue - LAG(net_revenue) OVER (ORDER BY month), 2) AS mom_change,
  ROUND(
    100 * (net_revenue - LAG(net_revenue) OVER (ORDER BY month))
    / NULLIF(LAG(net_revenue) OVER (ORDER BY month), 0),
    2
  ) AS mom_change_pct,
  ROUND(AVG(net_revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3mo_avg
FROM monthly
ORDER BY month;

-- =============================================
-- 2) Top 3 product lines each month (ranking)
-- =============================================
WITH product_month AS (
  SELECT
    DATE_TRUNC('month', d.date)::date AS month,
    p.productline,
    SUM(f.line_sales) AS revenue
  FROM sales.fct_order_lines f
  JOIN sales.dim_date d      ON d.date_id = f.date_id
  JOIN sales.dim_products p  ON p.product_id = f.product_id
  WHERE f.status NOT ILIKE 'Cancelled%'
  GROUP BY 1, 2
)
SELECT month, productline, ROUND(revenue, 2) AS revenue
FROM (
  SELECT
    month,
    productline,
    revenue,
    ROW_NUMBER() OVER (PARTITION BY month ORDER BY revenue DESC) AS rn
  FROM product_month
) ranked
WHERE rn <= 3
ORDER BY month, rn;

-- =============================================
-- 3) Country contribution + cumulative share (Pareto)
-- =============================================
WITH country_rev AS (
  SELECT
    c.country,
    SUM(f.line_sales) AS revenue
  FROM sales.fct_order_lines f
  JOIN sales.dim_customers c ON c.customer_id = f.customer_id
  WHERE f.status NOT ILIKE 'Cancelled%'
  GROUP BY 1
), totals AS (
  SELECT SUM(revenue) AS total_revenue FROM country_rev
)
SELECT
  cr.country,
  ROUND(cr.revenue, 2) AS revenue,
  ROUND(100 * cr.revenue / NULLIF(t.total_revenue, 0), 2) AS pct_of_total,
  ROUND(
    100 * SUM(cr.revenue) OVER (ORDER BY cr.revenue DESC)
    / NULLIF(t.total_revenue, 0),
    2
  ) AS cumulative_pct
FROM country_rev cr
CROSS JOIN totals t
ORDER BY cr.revenue DESC;

-- =============================================
-- 4) Customer RFM scoring (Recency / Frequency / Monetary)
-- =============================================
WITH per_customer AS (
  SELECT
    c.customer_id,
    c.customername,
    MAX(d.date) AS last_order_date,
    COUNT(DISTINCT f.ordernumber) AS orders,
    SUM(f.line_sales) FILTER (WHERE f.status NOT ILIKE 'Cancelled%') AS revenue
  FROM sales.fct_order_lines f
  JOIN sales.dim_customers c ON c.customer_id = f.customer_id
  JOIN sales.dim_date d      ON d.date_id = f.date_id
  GROUP BY 1, 2
), scored AS (
  SELECT
    *,
    (CURRENT_DATE - last_order_date) AS recency_days,
    NTILE(4) OVER (ORDER BY (CURRENT_DATE - last_order_date) ASC) AS r_score, -- lower recency is better
    NTILE(4) OVER (ORDER BY orders DESC)                          AS f_score,
    NTILE(4) OVER (ORDER BY revenue DESC)                         AS m_score
  FROM per_customer
)
SELECT
  customername,
  recency_days,
  orders,
  ROUND(revenue, 2) AS revenue,
  r_score,
  f_score,
  m_score,
  CASE
    WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
    WHEN r_score >= 3 AND f_score >= 2 THEN 'Loyal'
    WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk (High Frequency)'
    WHEN r_score <= 2 AND m_score >= 3 THEN 'At Risk (High Value)'
    ELSE 'Others'
  END AS segment
FROM scored
ORDER BY revenue DESC
LIMIT 30;

-- =============================================
-- 5) Cohort retention (customer first purchase month)
-- =============================================
WITH customer_months AS (
  SELECT
    f.customer_id,
    DATE_TRUNC('month', d.date)::date AS month
  FROM sales.fct_order_lines f
  JOIN sales.dim_date d ON d.date_id = f.date_id
  WHERE f.status NOT ILIKE 'Cancelled%'
  GROUP BY 1, 2
), first_month AS (
  SELECT customer_id, MIN(month) AS cohort_month
  FROM customer_months
  GROUP BY 1
), activity AS (
  SELECT
    fm.cohort_month,
    cm.month,
    (
      (EXTRACT(YEAR FROM cm.month)::int  - EXTRACT(YEAR FROM fm.cohort_month)::int) * 12
      + (EXTRACT(MONTH FROM cm.month)::int - EXTRACT(MONTH FROM fm.cohort_month)::int)
    ) AS month_number,
    COUNT(DISTINCT cm.customer_id) AS active_customers
  FROM customer_months cm
  JOIN first_month fm ON fm.customer_id = cm.customer_id
  GROUP BY 1, 2, 3
), cohort_base AS (
  SELECT cohort_month, MAX(active_customers) FILTER (WHERE month_number = 0) AS cohort_size
  FROM activity
  GROUP BY 1
)
SELECT
  a.cohort_month,
  a.month_number,
  a.active_customers,
  ROUND(100 * a.active_customers::numeric / NULLIF(cb.cohort_size, 0), 1) AS retention_pct
FROM activity a
JOIN cohort_base cb USING (cohort_month)
ORDER BY a.cohort_month, a.month_number;

-- =============================================
-- 6) Deal size mix by year (share of revenue)
-- =============================================
WITH by_year AS (
  SELECT
    d.year,
    f.dealsize,
    SUM(f.line_sales) FILTER (WHERE f.status NOT ILIKE 'Cancelled%') AS revenue
  FROM sales.fct_order_lines f
  JOIN sales.dim_date d ON d.date_id = f.date_id
  GROUP BY 1, 2
), totals AS (
  SELECT year, SUM(revenue) AS total_revenue
  FROM by_year
  GROUP BY 1
)
SELECT
  by_year.year,
  by_year.dealsize,
  ROUND(by_year.revenue, 2) AS revenue,
  ROUND(100 * by_year.revenue / NULLIF(t.total_revenue, 0), 2) AS pct_of_year
FROM by_year
JOIN totals t USING (year)
ORDER BY by_year.year, pct_of_year DESC;

-- =============================================
-- 7) "What happened yesterday?" Daily revenue + anomaly flag (7-day z-score)
-- =============================================
WITH daily AS (
  SELECT
    d.date,
    SUM(f.line_sales) FILTER (WHERE f.status NOT ILIKE 'Cancelled%') AS revenue
  FROM sales.fct_order_lines f
  JOIN sales.dim_date d ON d.date_id = f.date_id
  GROUP BY 1
), stats AS (
  SELECT
    date,
    revenue,
    AVG(revenue)    OVER (ORDER BY date ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS avg_prev_7,
    STDDEV_SAMP(revenue) OVER (ORDER BY date ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS std_prev_7
  FROM daily
)
SELECT
  date,
  ROUND(revenue, 2) AS revenue,
  ROUND(avg_prev_7, 2) AS avg_prev_7,
  ROUND(std_prev_7, 2) AS std_prev_7,
  CASE
    WHEN std_prev_7 IS NULL OR std_prev_7 = 0 THEN NULL
    ELSE ROUND((revenue - avg_prev_7) / std_prev_7, 2)
  END AS z_score,
  CASE
    WHEN std_prev_7 IS NULL OR std_prev_7 = 0 THEN 'no_baseline'
    WHEN ABS((revenue - avg_prev_7) / std_prev_7) >= 2 THEN 'anomaly'
    ELSE 'normal'
  END AS flag
FROM stats
ORDER BY date DESC
LIMIT 30;

-- =============================================
-- 8) Top customers with running total share (Pareto)
-- =============================================
WITH customer_rev AS (
  SELECT
    c.customername,
    SUM(f.line_sales) FILTER (WHERE f.status NOT ILIKE 'Cancelled%') AS revenue
  FROM sales.fct_order_lines f
  JOIN sales.dim_customers c ON c.customer_id = f.customer_id
  GROUP BY 1
), totals AS (
  SELECT SUM(revenue) AS total_revenue FROM customer_rev
)
SELECT
  cr.customername,
  ROUND(cr.revenue, 2) AS revenue,
  ROUND(100 * cr.revenue / NULLIF(t.total_revenue, 0), 2) AS pct_of_total,
  ROUND(
    100 * SUM(cr.revenue) OVER (ORDER BY cr.revenue DESC)
    / NULLIF(t.total_revenue, 0),
    2
  ) AS cumulative_pct
FROM customer_rev cr
CROSS JOIN totals t
ORDER BY cr.revenue DESC
LIMIT 50;
