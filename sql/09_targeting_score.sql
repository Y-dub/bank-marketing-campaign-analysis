-- 09 · A simple targeting score, tested out of time.
-- Learn segment lift (vs each year's average) from 2008-2009, score 2010 clients, compare by quintile.
-- Inputs are things known before the call: prior outcome, channel, age group, and whether this is an early contact.

WITH yearly AS (
    SELECT campaign_year, AVG(converted) AS year_rate FROM contacts GROUP BY 1
),
labelled AS (
    SELECT
        c.*,
        c.converted / y.year_rate AS lift,
        CASE WHEN age < 25 THEN 'Under 25' WHEN age >= 60 THEN '60+' ELSE '25-59' END AS age_group,
        CASE WHEN contacts_this_campaign <= 3 THEN 'Contacts 1-3' ELSE 'Contacts 4+' END AS contact_stage
    FROM contacts c
    JOIN yearly y USING (campaign_year)
),
segment_lift AS (
    SELECT prior_outcome, channel, age_group, contact_stage, AVG(lift) AS expected_lift
    FROM labelled
    WHERE campaign_year < 2010
    GROUP BY ALL
    HAVING COUNT(*) >= 30          -- ignore segments too small to trust
),
scored AS (
    SELECT l.*, COALESCE(s.expected_lift, 1.0) AS score
    FROM labelled l
    LEFT JOIN segment_lift s USING (prior_outcome, channel, age_group, contact_stage)
    WHERE l.campaign_year = 2010
),
quintiles AS (
    SELECT *, NTILE(5) OVER (ORDER BY score DESC, record_id) AS priority_quintile
    FROM scored
)
SELECT
    priority_quintile,
    COUNT(*)                                                         AS clients,
    SUM(converted)::BIGINT                                                   AS subscriptions,
    ROUND(100.0 * AVG(converted), 1)                                 AS conversion_pct,
    ROUND(100.0 * SUM(converted)::BIGINT / SUM(SUM(converted)::BIGINT) OVER (), 1)   AS share_of_subscriptions_pct,
    ROUND(100.0 * SUM(SUM(converted)::BIGINT) OVER (ORDER BY priority_quintile) / SUM(SUM(converted)::BIGINT) OVER (), 1)
                                                                     AS cumulative_share_pct
FROM quintiles
GROUP BY priority_quintile
ORDER BY priority_quintile;
