DROP TABLE IF EXISTS sales.sales_clean;

CREATE TABLE sales.sales_clean AS
SELECT
  ordernumber,
  quantityordered,
  priceeach::numeric(10,2)              AS priceeach,
  orderlinenumber,
  sales::numeric(12,2)                  AS sales,
  orderdate::date                       AS orderdate,
  status,
  qtr_id,
  month_id,
  year_id,
  productline,
  msrp,
  productcode,
  customername,
  phone,
  addressline1,
  NULLIF(addressline2, '')              AS addressline2,
  city,
  state,
  postalcode,
  country,
  territory,
  contactlastname,
  contactfirstname,
  dealsize
FROM sales.stg_sales_raw;

-- sanity check
SELECT COUNT(*) AS rows FROM sales.sales_clean;

CREATE INDEX IF NOT EXISTS idx_sales_clean_orderdate ON sales.sales_clean(orderdate);
CREATE INDEX IF NOT EXISTS idx_sales_clean_country   ON sales.sales_clean(country);
CREATE INDEX IF NOT EXISTS idx_sales_clean_product   ON sales.sales_clean(productline);
CREATE INDEX IF NOT EXISTS idx_sales_clean_year      ON sales.sales_clean(year_id);

SELECT year_id, ROUND(SUM(sales), 2) AS revenue
FROM sales.sales_clean
GROUP BY year_id
ORDER BY year_id;

SELECT month_id, ROUND(SUM(sales), 2) AS revenue
FROM sales.sales_clean
GROUP BY month_id
ORDER BY month_id;

SELECT productline, ROUND(SUM(sales), 2) AS revenue
FROM sales.sales_clean
GROUP BY productline
ORDER BY revenue DESC;

SELECT country, ROUND(SUM(sales), 2) AS revenue
FROM sales.sales_clean
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;

SELECT dealsize, ROUND(SUM(sales), 2) AS revenue
FROM sales.sales_clean
GROUP BY dealsize
ORDER BY revenue DESC;
