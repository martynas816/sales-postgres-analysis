-- Build a simple star schema from sales.sales_clean
-- Grain of fact table: one row per (ordernumber, orderlinenumber)

\set ON_ERROR_STOP on

DROP TABLE IF EXISTS sales.fct_order_lines CASCADE;
DROP TABLE IF EXISTS sales.dim_date CASCADE;
DROP TABLE IF EXISTS sales.dim_products CASCADE;
DROP TABLE IF EXISTS sales.dim_customers CASCADE;

-- =====================
-- Dimension: Date
-- =====================
CREATE TABLE sales.dim_date (
  date_id      INTEGER PRIMARY KEY,          -- yyyymmdd
  date         DATE    NOT NULL UNIQUE,
  year         INTEGER NOT NULL,
  quarter      INTEGER NOT NULL,
  month        INTEGER NOT NULL,
  month_name   TEXT    NOT NULL,
  day          INTEGER NOT NULL,
  day_of_week  INTEGER NOT NULL,             -- 1=Mon ... 7=Sun
  day_name     TEXT    NOT NULL,
  is_weekend   BOOLEAN NOT NULL
);

INSERT INTO sales.dim_date (
  date_id, date, year, quarter, month, month_name, day, day_of_week, day_name, is_weekend
)
SELECT
  (EXTRACT(YEAR  FROM d)::int * 10000 + EXTRACT(MONTH FROM d)::int * 100 + EXTRACT(DAY FROM d)::int) AS date_id,
  d::date                                                                                             AS date,
  EXTRACT(YEAR    FROM d)::int                                                                        AS year,
  EXTRACT(QUARTER FROM d)::int                                                                        AS quarter,
  EXTRACT(MONTH   FROM d)::int                                                                        AS month,
  TO_CHAR(d, 'Mon')                                                                                   AS month_name,
  EXTRACT(DAY     FROM d)::int                                                                        AS day,
  EXTRACT(ISODOW  FROM d)::int                                                                        AS day_of_week,
  TO_CHAR(d, 'Dy')                                                                                    AS day_name,
  (EXTRACT(ISODOW FROM d)::int IN (6, 7))                                                              AS is_weekend
FROM (
  SELECT DISTINCT orderdate::date AS d
  FROM sales.sales_clean
) s
ORDER BY d;

-- =====================
-- Dimension: Products
-- =====================
CREATE TABLE sales.dim_products (
  product_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  productcode  TEXT    NOT NULL UNIQUE,
  productline  TEXT,
  msrp         INTEGER
);

INSERT INTO sales.dim_products (productcode, productline, msrp)
SELECT DISTINCT
  productcode,
  productline,
  msrp
FROM sales.sales_clean
ORDER BY productcode;

-- =====================
-- Dimension: Customers
-- =====================
CREATE TABLE sales.dim_customers (
  customer_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customername     TEXT    NOT NULL UNIQUE,
  contactfirstname TEXT,
  contactlastname  TEXT,
  phone            TEXT,
  addressline1     TEXT,
  addressline2     TEXT,
  city             TEXT,
  state            TEXT,
  postalcode       TEXT,
  country          TEXT,
  territory        TEXT
);

INSERT INTO sales.dim_customers (
  customername,
  contactfirstname,
  contactlastname,
  phone,
  addressline1,
  addressline2,
  city,
  state,
  postalcode,
  country,
  territory
)
SELECT DISTINCT
  customername,
  contactfirstname,
  contactlastname,
  phone,
  addressline1,
  addressline2,
  city,
  state,
  postalcode,
  country,
  territory
FROM sales.sales_clean
ORDER BY customername;

-- =====================
-- Fact: Order Lines
-- =====================
CREATE TABLE sales.fct_order_lines (
  ordernumber      INTEGER NOT NULL,
  orderlinenumber  INTEGER NOT NULL,

  date_id          INTEGER NOT NULL REFERENCES sales.dim_date(date_id),
  customer_id      INTEGER NOT NULL REFERENCES sales.dim_customers(customer_id),
  product_id       INTEGER NOT NULL REFERENCES sales.dim_products(product_id),

  status           TEXT,
  dealsize         TEXT,

  quantityordered  INTEGER,
  priceeach        NUMERIC(10,2),
  line_sales       NUMERIC(12,2),

  PRIMARY KEY (ordernumber, orderlinenumber)
);

INSERT INTO sales.fct_order_lines (
  ordernumber,
  orderlinenumber,
  date_id,
  customer_id,
  product_id,
  status,
  dealsize,
  quantityordered,
  priceeach,
  line_sales
)
SELECT
  sc.ordernumber,
  sc.orderlinenumber,
  dd.date_id,
  dc.customer_id,
  dp.product_id,
  sc.status,
  sc.dealsize,
  sc.quantityordered,
  sc.priceeach,
  sc.sales
FROM sales.sales_clean sc
JOIN sales.dim_date dd
  ON dd.date = sc.orderdate
JOIN sales.dim_customers dc
  ON dc.customername = sc.customername
JOIN sales.dim_products dp
  ON dp.productcode = sc.productcode;

-- Indexes that make BI tools much faster
CREATE INDEX IF NOT EXISTS idx_fct_order_lines_date     ON sales.fct_order_lines(date_id);
CREATE INDEX IF NOT EXISTS idx_fct_order_lines_customer ON sales.fct_order_lines(customer_id);
CREATE INDEX IF NOT EXISTS idx_fct_order_lines_product  ON sales.fct_order_lines(product_id);
CREATE INDEX IF NOT EXISTS idx_fct_order_lines_status   ON sales.fct_order_lines(status);

-- sanity checks
SELECT COUNT(*) AS fact_rows FROM sales.fct_order_lines;
SELECT COUNT(*) AS customers FROM sales.dim_customers;
SELECT COUNT(*) AS products  FROM sales.dim_products;
SELECT COUNT(*) AS dates     FROM sales.dim_date;
