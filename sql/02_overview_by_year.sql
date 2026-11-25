-- 02 · Volume, conversion and economic context by campaign year.
-- Conversion rose from about 5% to 52% while volume fell by 93%: everything else must be compared within a year.

SELECT
    campaign_year,
    COUNT(*)                                    AS clients_contacted,
    SUM(contacts_this_campaign)::BIGINT                 AS calls_made,
    SUM(converted)::BIGINT                              AS subscriptions,
    ROUND(100.0 * AVG(converted), 1)            AS conversion_pct,
    ROUND(SUM(contacts_this_campaign)::BIGINT * 1.0 / SUM(converted)::BIGINT, 1) AS calls_per_subscription,
    ROUND(100.0 * AVG(CAST(channel = 'cellular' AS INTEGER)), 1) AS mobile_share_pct,
    ROUND(AVG(euribor_3m), 2)                   AS avg_euribor_3m
FROM contacts
GROUP BY campaign_year
ORDER BY campaign_year;
