# Commercial support playbook (daily analytics)

This is a practical workflow for the most common "commercial support" requests:

1) **What happened yesterday?** (topline KPIs)
2) **Why did KPI change?** (drivers + drilldowns)
3) **Give me numbers for a segment/promo** (template)

## KPI definitions used in this repo
- **Net revenue**: `SUM(line_sales)` excluding cancelled orders (`status NOT ILIKE 'Cancelled%'`).
- **Orders**: distinct `ordernumber`.
- **Units**: `SUM(quantityordered)`.
- **AOV**: `net_revenue / orders`.
- **Cancel rate** (orders): cancelled orders / total orders.

## Always-run validation checks (before answering)
These take ~10 seconds and prevent embarrassing mistakes:
- **Freshness**: latest `orderdate` in `sales.sales_clean` (or `dim_date`).
- **Row-count sanity**: `COUNT(*)` in `sales.fct_order_lines` stable across runs.
- **Duplicate grain**: no duplicates on `(ordernumber, orderlinenumber)`.
- **Cancelled filter**: confirm whether the request wants gross vs net.

All queries + checks live in: `sql/07_daily_commercial_questions.sql`.

## Response template (paste-ready)
**Summary:** Yesterday net revenue was **X**, from **Y** orders (**AOV Z**), with **N%** cancellations.

**Drivers vs previous day:** Change was mainly driven by **(country/product line/deal size)**, with the biggest contributors being **A, B, C**.

**Confidence / checks:** Data is fresh up to **DATE**, no duplicate grain detected, and definitions match the dashboard.
