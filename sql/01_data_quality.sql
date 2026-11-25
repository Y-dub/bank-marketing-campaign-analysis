-- 01 · Data quality checks before any analysis.

WITH dup AS (
    SELECT COUNT(*) - COUNT(DISTINCT (
        age, job, marital, education, "default", housing, loan, contact, month, day_of_week, duration,
        campaign, pdays, previous, poutcome, "emp.var.rate", "cons.price.idx", "cons.conf.idx", euribor3m,
        "nr.employed", y)) AS n
    FROM raw
)
SELECT 'Rows' AS check_name, COUNT(*) AS value, 'Matches the published 41,188' AS note FROM raw
UNION ALL
SELECT 'Exact duplicate rows', (SELECT n FROM dup), 'Kept: identical records can be genuine (same profile, same day)'
UNION ALL
SELECT 'Unknown credit default', COUNT(*) FILTER (WHERE "default" = 'unknown'), '21% of rows: treat as its own category, not as "no"' FROM raw
UNION ALL
SELECT 'Unknown education', COUNT(*) FILTER (WHERE education = 'unknown'), NULL FROM raw
UNION ALL
SELECT 'Unknown job', COUNT(*) FILTER (WHERE job = 'unknown'), NULL FROM raw
UNION ALL
SELECT 'Previously contacted but pdays = 999', COUNT(*) FILTER (WHERE previous > 0 AND pdays = 999),
       'pdays 999 should mean "never contacted": inconsistent with previous > 0' FROM raw
UNION ALL
SELECT 'Zero-second calls', COUNT(*) FILTER (WHERE duration = 0), 'All "no": call never connected' FROM raw
UNION ALL
SELECT 'Years inferred', COUNT(DISTINCT campaign_year), 'May 2008 to November 2010' FROM contacts;
