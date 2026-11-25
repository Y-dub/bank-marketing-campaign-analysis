-- 08 · Customer segments by age band, as lift over the same year's average
-- (so that segments contacted mostly in high-conversion years are not flattered).

WITH yearly AS (
    SELECT campaign_year, AVG(converted) AS year_rate FROM contacts GROUP BY 1
)
SELECT
    age_band,
    COUNT(*)                                            AS clients,
    ROUND(100.0 * AVG(converted), 1)                    AS conversion_pct,
    ROUND(AVG(converted / year_rate), 2)                AS lift_vs_year_average
FROM contacts
JOIN yearly USING (campaign_year)
GROUP BY age_band
ORDER BY age_band;
