-- 04 · What a cap on contact attempts would save, and what it puts at risk.
-- "At risk" is an upper bound: it assumes every client who converted after the cap would be lost.

SELECT
    cap AS max_contacts,
    SUM(contacts_this_campaign)::BIGINT                                         AS calls_now,
    SUM(LEAST(contacts_this_campaign, cap))::BIGINT                             AS calls_with_cap,
    ROUND(100.0 - 100.0 * SUM(LEAST(contacts_this_campaign, cap))::BIGINT / SUM(contacts_this_campaign)::BIGINT, 1) AS calls_saved_pct,
    (SUM(converted) FILTER (WHERE contacts_this_campaign > cap))::BIGINT AS subscriptions_at_risk,
    ROUND(100.0 * SUM(converted) FILTER (WHERE contacts_this_campaign > cap) / SUM(converted)::BIGINT, 1)  AS subscriptions_at_risk_pct,
    ROUND((SUM(contacts_this_campaign)::BIGINT - SUM(LEAST(contacts_this_campaign, cap))::BIGINT) * 1.0
          / NULLIF(SUM(converted) FILTER (WHERE contacts_this_campaign > cap), 0), 1)           AS calls_per_subscription_beyond_cap
FROM contacts
CROSS JOIN (VALUES (2), (3), (4), (5)) AS caps(cap)
GROUP BY cap
ORDER BY cap;
