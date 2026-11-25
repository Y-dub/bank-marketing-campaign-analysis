-- 07 · Why "call in March" would be the wrong lesson.
-- The high-conversion months are small months that fall almost entirely in 2009-2010,
-- after volume dropped and targeting tightened. Month is a proxy for period, not a cause.

SELECT
    month_name,
    COUNT(*)                                                  AS clients,
    ROUND(100.0 * AVG(converted), 1)                          AS conversion_pct,
    ROUND(100.0 * AVG(CAST(campaign_year = 2008 AS INTEGER)), 1) AS share_from_2008_pct
FROM contacts
GROUP BY month_name, month_num
ORDER BY month_num;
