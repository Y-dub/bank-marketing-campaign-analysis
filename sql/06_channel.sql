-- 06 · Mobile vs landline, overall and within each year.
-- The overall gap (14.7% vs 5.2%) is inflated by timing: May-June 2008 was landline only, at 3-4% conversion.

SELECT 'All years' AS period, channel, COUNT(*) AS clients, ROUND(100.0 * AVG(converted), 1) AS conversion_pct
FROM contacts
GROUP BY ALL
UNION ALL
SELECT CAST(campaign_year AS VARCHAR), channel, COUNT(*), ROUND(100.0 * AVG(converted), 1)
FROM contacts
GROUP BY ALL
ORDER BY period, channel;
