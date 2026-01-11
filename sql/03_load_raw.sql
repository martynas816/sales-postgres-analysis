TRUNCATE TABLE sales.stg_sales_raw;

COPY sales.stg_sales_raw (
    ordernumber,
    quantityordered,
    priceeach,
    orderlinenumber,
    sales,
    orderdate,
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
    addressline2,
    city,
    state,
    postalcode,
    country,
    territory,
    contactlastname,
    contactfirstname,
    dealsize
)
FROM 'D:/downloads/sales_data_sample.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'WIN1252');
