-- 05 · Previous campaign outcome, compared within each year.
-- Lift = conversion of the group / conversion of new prospects in the same year.

WITH by_group AS (
    SELECT campaign_year, prior_outcome, COUNT(*) AS clients, AVG(converted) AS conversion
    FROM contacts
    GROUP BY ALL
)
SELECT
    g.campaign_year,
    g.prior_outcome,
    g.clients,
    ROUND(100.0 * g.conversion, 1)                 AS conversion_pct,
    ROUND(g.conversion / n.conversion, 2)          AS lift_vs_new_prospects
FROM by_group g
JOIN by_group n
  ON n.campaign_year = g.campaign_year AND n.prior_outcome = 'New prospect'
ORDER BY g.campaign_year, g.prior_outcome;
