\set ON_ERROR_STOP on

TRUNCATE TABLE stg_sales_raw;

COPY stg_sales_raw
FROM '/data/sales_raw.csv'
WITH (
  FORMAT csv,
  HEADER true,
  ENCODING 'WIN1252'
);
