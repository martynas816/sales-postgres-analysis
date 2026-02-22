\set ON_ERROR_STOP on

\i /sql/01_schema.sql
\i /sql/02_create_raw_table.sql
\i /sql/03_load_raw.sql

-- build clean layer + star schema so Metabase can query modeled tables immediately
\i /sql/04_transform_and_analysis.sql
\i /sql/05_build_star_schema.sql
