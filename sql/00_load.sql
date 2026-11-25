-- 00 · Load the raw file and build the analysis table.
-- The runner sets the variable csv_path before executing this file.
-- Source: UCI Bank Marketing, bank-additional-full.csv (Moro, Cortez & Rita, 2014). 41,188 rows, ';'-separated.

CREATE OR REPLACE TABLE raw AS
SELECT *
FROM read_csv(
    getvariable('csv_path'),
    delim = ';',
    header = true,
    -- Declare the yes/no/unknown columns: type inference would read them as booleans
    -- whenever a file happens to contain no 'unknown' values.
    types = {'default': 'VARCHAR', 'housing': 'VARCHAR', 'loan': 'VARCHAR', 'y': 'VARCHAR'}
);

-- The file has no year, but rows are in date order (May 2008 to November 2010).
-- A new year starts wherever the month number drops compared with the previous row.
CREATE OR REPLACE TABLE contacts AS
WITH numbered AS (
    SELECT
        rowid + 1 AS record_id,
        *,
        list_position(['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'], month) AS month_num
    FROM raw
),
year_breaks AS (
    SELECT
        *,
        CASE WHEN month_num < LAG(month_num) OVER (ORDER BY record_id) THEN 1 ELSE 0 END AS starts_new_year
    FROM numbered
)
SELECT
    record_id,
    CAST(2008 + SUM(starts_new_year) OVER (ORDER BY record_id) AS INTEGER) AS campaign_year,
    month_num,
    month AS month_name,
    make_date(CAST(2008 + SUM(starts_new_year) OVER (ORDER BY record_id) AS INTEGER), month_num, 1) AS campaign_month,
    age,
    CASE
        WHEN age < 25 THEN '18-24'
        WHEN age < 35 THEN '25-34'
        WHEN age < 45 THEN '35-44'
        WHEN age < 55 THEN '45-54'
        WHEN age < 65 THEN '55-64'
        ELSE '65+'
    END AS age_band,
    job,
    marital,
    education,
    "default" AS credit_default,
    housing AS housing_loan,
    loan AS personal_loan,
    contact AS channel,
    day_of_week,
    campaign AS contacts_this_campaign,
    CASE
        WHEN campaign = 1 THEN '1'
        WHEN campaign = 2 THEN '2'
        WHEN campaign = 3 THEN '3'
        WHEN campaign <= 5 THEN '4-5'
        WHEN campaign <= 9 THEN '6-9'
        ELSE '10+'
    END AS contact_band,
    previous AS previous_contacts,
    CASE poutcome
        WHEN 'success' THEN 'Said yes before'
        WHEN 'failure' THEN 'Said no before'
        ELSE 'New prospect'
    END AS prior_outcome,
    pdays,
    duration AS call_seconds,  -- only known after the call ends: never use it for targeting
    "emp.var.rate" AS employment_variation_rate,
    "cons.conf.idx" AS consumer_confidence,
    euribor3m AS euribor_3m,
    CAST(y = 'yes' AS INTEGER) AS converted
FROM year_breaks;
