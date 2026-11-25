-- 03 · Diminishing returns from repeat contact.
-- Cumulative shares use window functions over the ordered contact counts.

WITH by_count AS (
    SELECT
        LEAST(contacts_this_campaign, 10)  AS contacts,      -- 10 = "10 or more"
        COUNT(*)                           AS clients,
        SUM(contacts_this_campaign)::BIGINT        AS calls_made,
        SUM(converted)::BIGINT                     AS subscriptions
    FROM contacts
    GROUP BY 1
)
SELECT
    contacts,
    clients,
    calls_made,
    subscriptions,
    ROUND(100.0 * subscriptions / clients, 1)                                           AS conversion_pct,
    ROUND(calls_made * 1.0 / NULLIF(subscriptions, 0), 1)                               AS calls_per_subscription,
    ROUND(100.0 * SUM(subscriptions) OVER (ORDER BY contacts) / SUM(subscriptions) OVER (), 1) AS cumulative_share_of_subscriptions_pct,
    ROUND(100.0 * SUM(calls_made) OVER (ORDER BY contacts) / SUM(calls_made) OVER (), 1)       AS cumulative_share_of_calls_pct
FROM by_count
ORDER BY contacts;
