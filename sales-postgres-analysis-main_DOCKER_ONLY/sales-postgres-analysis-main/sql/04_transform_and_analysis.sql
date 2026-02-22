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

-- helpful indexes for downstream modeling/queries
CREATE INDEX IF NOT EXISTS idx_sales_clean_ordernumber ON sales.sales_clean(ordernumber);
CREATE INDEX IF NOT EXISTS idx_sales_clean_orderdate   ON sales.sales_clean(orderdate);
CREATE INDEX IF NOT EXISTS idx_sales_clean_customer    ON sales.sales_clean(customername);
CREATE INDEX IF NOT EXISTS idx_sales_clean_productcode ON sales.sales_clean(productcode);
CREATE INDEX IF NOT EXISTS idx_sales_clean_country     ON sales.sales_clean(country);
