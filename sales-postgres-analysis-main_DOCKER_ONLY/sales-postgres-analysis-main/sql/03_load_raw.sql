\set ON_ERROR_STOP on

TRUNCATE TABLE sales.stg_sales_raw;

COPY sales.stg_sales_raw
FROM '/data/sales_raw.csv'
WITH (
  FORMAT csv,
  HEADER true,
  ENCODING 'WIN1252'
);
