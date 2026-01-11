\# Sales Analysis with PostgreSQL (Local)



End-to-end SQL analytics project in PostgreSQL: load → stage → clean → analyze.



\## What’s inside

\- `data/sales\_data\_sample.csv` – source dataset (2,823 rows)

\- `sql/01\_schema.sql` – creates schema + sets search\_path

\- `sql/02\_create\_raw\_table.sql` – creates staging table

\- `sql/03\_load\_raw.sql` – loads CSV into staging (COPY)

\- `sql/04\_transform\_and\_analysis.sql` – creates clean table + analysis queries

\- `outputs/results.md` – saved query outputs (viewable without running)



\## How to run (DBeaver)

1\. Create database `analytics` (or use an existing DB)

2\. Connect in DBeaver

3\. Run scripts in this order:

&nbsp;  - `sql/01\_schema.sql`

&nbsp;  - `sql/02\_create\_raw\_table.sql`

&nbsp;  - `sql/03\_load\_raw.sql`  

&nbsp;    \*\*Note:\*\* this script uses a local file path. If your repo path is different, edit the `FROM '...'` line.

&nbsp;  - `sql/04\_transform\_and\_analysis.sql`



\## Notes

\- CSV load uses `ENCODING 'WIN1252'` to avoid UTF-8 byte errors.

\- Tables created:

&nbsp; - `sales.stg\_sales\_raw` (staging)

&nbsp; - `sales.sales\_clean` (clean analytics table)



\## Tools

PostgreSQL • DBeaver • SQL



