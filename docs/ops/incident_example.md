# Example incident: revenue doubled after a reload

## Symptoms
A stakeholder reports that the Metabase dashboard revenue looks ~2x higher than yesterday for the same historical period.

## First checks (5 minutes)
1. **Confirm the definition** (net vs gross; cancelled included?).
2. **Check row counts**:
   - `sales.stg_sales_raw` and `sales.sales_clean`
   - `sales.fct_order_lines`
3. **Check duplicate grain** in the fact table: `(ordernumber, orderlinenumber)` should be unique.

## Root cause (example)
During a change, the raw load step switched from **TRUNCATE + COPY** to **append-only COPY**, so every run duplicated rows.

## Fix
- Restore the safe load pattern:
  - `TRUNCATE sales.stg_sales_raw;` before `COPY`.
- Add a preventive constraint (optional):
  - unique index on `(ordernumber, orderlinenumber)` in `sales.fct_order_lines`.

## Prevention
- Add a **daily anomaly check**: if `COUNT(*)` changes by >X% day-over-day, alert.
- Keep a small **data quality query pack** (duplicates/nulls/freshness) and run it before publishing numbers.

(See `sql/07_daily_commercial_questions.sql` for the actual checks used in this repo.)
