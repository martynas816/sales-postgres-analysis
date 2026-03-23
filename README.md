# Sales Analysis with PostgreSQL

SQL analytics project built in PostgreSQL and Docker Compose, with Metabase used for dashboarding.

## Overview
- Raw CSV load into PostgreSQL
- Cleaning and transformation in SQL
- Star schema modeling
- Metabase dashboards on top of the warehouse

## Stack
- PostgreSQL
- Docker Compose
- Metabase

## Run
```bash
docker compose up
```

Metabase: `http://localhost:3001`

Warehouse connection:
- Host: `warehouse`
- Port: `5432`
- Database: `sales`
- Username: `postgres`
- Password: `postgres`

## Repository layout
- `data/sales_raw.csv` - source data
- `sql/` - schema, load, transformation, star schema, analytics queries
- `docker/warehouse-init/00_bootstrap.sql` - warehouse bootstrap
- `outputs/outputs.md` - saved query outputs
- `outputs/*.png` - dashboard screenshots

## Warehouse model
- `sales.stg_sales_raw`
- `sales.sales_clean`
- `sales.fct_order_lines`
- `sales.dim_date`
- `sales.dim_customers`
- `sales.dim_products`

## Dashboard
![Overview](outputs/01-dashboard-overall.png)

<details>
  <summary>More screenshots</summary>

## USA

  ![USA](outputs/02-usa.png)

## Finland
  ![Finland](outputs/03-finland.png)

## USA 2003
  ![USA 2003](outputs/04-usa-year-2003.png)
</details>
