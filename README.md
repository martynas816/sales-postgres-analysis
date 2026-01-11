\# Sales Analysis with PostgreSQL



End-to-end SQL analytics project using PostgreSQL and DBeaver.



\## Project Overview

This project demonstrates a simple analytics pipeline:

\- Raw CSV ingestion

\- Staging table

\- Cleaned analytical table

\- Business-focused aggregations



\## Dataset

\- Source: `sales\_data\_sample.csv`

\- Rows: 2,823

\- Domain: Retail sales



\## Pipeline

1\. Create schema

2\. Create raw staging table

3\. Load CSV into PostgreSQL

4\. Transform into clean analytics table

5\. Run exploratory revenue analysis



\## Analysis Highlights

\- Revenue by year

\- Revenue by month

\- Revenue by product line

\- Revenue by country

\- Revenue by deal size



\## Tools

\- PostgreSQL

\- DBeaver

\- SQL



\## How to Run

Execute SQL scripts in order:

1\. `01\_schema.sql`

2\. `02\_create\_raw\_table.sql`

3\. `03\_load\_raw.sql`

4\. `04\_transform\_and\_analysis.sql`



