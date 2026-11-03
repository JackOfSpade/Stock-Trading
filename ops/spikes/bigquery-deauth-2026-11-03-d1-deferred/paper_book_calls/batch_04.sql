-- scripts/paper_book.py calls batch 4/4 (input rows 118, 119, 120). Issue this text VERBATIM, after the previous batch finished.
-- A row is written only if its literal arrived intact (row_sha), its story has no call on 2026-11-03 or the
-- 4 days before, and its ticker stays within 3 calls for the day. readback.sql names every skipped row.
INSERT INTO `stock-trading-498512.events.news_reaction_calls` (call_date, lead_id, ticker, headline_hash, headline, published_ts, source, source_url, direction, agreement_score, k, votes_json, horizon_days, scorer_routine, scorer_session)
WITH t AS (
  SELECT DATE '2026-11-03' AS call_date, 'interactive-2026-10-news-reaction-confidence-gated-long-short' AS lead_id, v.ticker, v.headline_hash, v.headline,
         TIMESTAMP(NULLIF(v.published_ts, '')) AS published_ts, v.source, NULLIF(v.source_url, '') AS source_url,
         v.direction, CAST(v.agreement_score AS NUMERIC) AS agreement_score, 5 AS k,
         PARSE_JSON(v.votes_json) AS votes_json, 1 AS horizon_days,
         'D1' AS scorer_routine, '0ae50cfd-af1c-5586-8100-6d25daa8b824' AS scorer_session, v.row_sha
  FROM UNNEST(ARRAY<STRUCT<n INT64, ticker STRING, headline_hash STRING, headline STRING, published_ts STRING,
       source STRING, source_url STRING, direction STRING, agreement_score STRING, votes_json STRING,
       row_sha STRING>>[
  (118, 'XOM', '9e0dbb8eeb20a1647ceb28e787c95b0fcf0e691e67678bdb4592dcbaf08d5b41', 'ExxonMobil Stock Trades at a Premium: Is It Still Worth Buying? - The Globe and Mail', '2026-11-03T16:47:28Z', 'google-news-rss', 'https://news.google.com/rss/articles/CBMi3gFBVV95cUxNeXNLQ00zZmN6NURORXYwUmFxNXdybnJERDg3dTlHMVkxdXdBODRtQ3hiYmhnSDMwQ3FTR1B3T2I1VDNxc05DeTBkYTJrZmtBWlE3MTN1aDRCM2hkbFJyUFNPX1VzT2p5T3FTdnFzQzQxaUVVLVFrc2YyMllxOXB5TEFqeUdzX1JKNnEwRUpqWXhIdGNBMXFsOWVBU01pd1hvU2RIRW5mOW9MRDJXd0htUEZEN2tBRHlkdkZTaXJvY0o1X3ZaR2hTeUUyT053bTB3ZGphSG0xTVVEa040cFE?oc=5', 'FLAT', '1', '["FLAT","FLAT","FLAT","FLAT","FLAT"]', 'd973b666dd49b676'),
  (119, 'XOM', 'cb8000a38453400501e09abcaefca271ff1fc54458046330d9ae87b4c3a05115', 'Exxon Mobil shares weekly forecast: Consolidates after more than 4% slide amid robust earnings and capital return plans - Traders Union', '2026-11-03T14:36:32Z', 'google-news-rss', 'https://news.google.com/rss/articles/CBMijwFBVV95cUxPWnpOZ1M4TGxWQjZJSG82bGNfQV9MbmtkcUtlU0g3MW5MSlEwLUVFT0ZfTkFZeFNhOUp5ZjJ5R3U4bmZIbTB2M09mNmFnUmFCdmZyamhTcVVhWHBEcGVaeU9HZS1uWFY3WHFkTDZ4enVKVTFrMkgzYWY2OUdydTdLd3RtSVNZSUJnanlWQjBtWQ?oc=5', 'FLAT', '1', '["FLAT","FLAT","FLAT","FLAT","FLAT"]', 'a753d67b572fa809'),
  (120, 'XOM', '5131e15384245d1bd5629aa53c64a102c92860c85358d9c45f06492990d245c2', 'Exxon Mobil Holdings (XOM) Just Overtook the 200-Day Moving Average - Yahoo Finance', '2026-11-03T13:30:02Z', 'google-news-rss', 'https://news.google.com/rss/articles/CBMimgFBVV95cUxOUG9vSXhWUzNrdVZlRnNseHFWWjZWSENrUlktLXNaOVY4SUJuWFhkSjNudkxnWHhtN1RVb1hKUmN5eldPV2RTa3FPNER6T3duWlZuU0dUclQ0d2lNMFV4SE1iWnZGZUdNUk83VllXbF9xTUE2MDFkRXNaNXpNQV9MdVdxZ2EySWZ4WTlBMEo5TVBwUi04VndmNVB3?oc=5', 'UP', '1', '["UP","UP","UP","UP","UP"]', '671bf942d765adb9')
  ]) AS v
),
g AS (
  -- everything below reads only digest-guarded values: the story, the window and the cap order
  SELECT t.*, LEFT(TO_HEX(SHA256(ARRAY_TO_STRING([CAST(t.call_date AS STRING), t.lead_id, CAST(t.k AS STRING), CAST(t.horizon_days AS STRING), t.scorer_routine, IFNULL(t.scorer_session, ''), t.ticker, t.headline_hash, t.headline, IFNULL(FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', t.published_ts, 'UTC'), ''), t.source, IFNULL(t.source_url, ''), t.direction, CAST(t.agreement_score AS STRING), TO_JSON_STRING(t.votes_json)], '\x1f'))), 16) = t.row_sha
           AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.events.news_reaction_calls` x
                           WHERE x.ticker = t.ticker
                             AND x.call_date BETWEEN DATE_SUB(t.call_date, INTERVAL 4 DAY) AND t.call_date
                             AND (x.headline_hash = t.headline_hash OR LEFT(TO_HEX(SHA256(LOWER(TRIM(IF(STRPOS(REGEXP_REPLACE(x.headline, r'[\t\n\f\r ]+', ' '), ' - ') > 0, REGEXP_EXTRACT(REGEXP_REPLACE(x.headline, r'[\t\n\f\r ]+', ' '), r'^(.*) - '), REGEXP_REPLACE(x.headline, r'[\t\n\f\r ]+', ' ')), ' ')))), 16) = LEFT(TO_HEX(SHA256(LOWER(TRIM(IF(STRPOS(REGEXP_REPLACE(t.headline, r'[\t\n\f\r ]+', ' '), ' - ') > 0, REGEXP_EXTRACT(REGEXP_REPLACE(t.headline, r'[\t\n\f\r ]+', ' '), r'^(.*) - '), REGEXP_REPLACE(t.headline, r'[\t\n\f\r ]+', ' ')), ' ')))), 16))) AS eligible
  FROM t
),
a AS (
  SELECT g.*, g.eligible AND IFNULL(today.n, 0) + ROW_NUMBER() OVER (
           PARTITION BY g.ticker, g.eligible ORDER BY g.published_ts DESC, g.headline_hash) <= 3 AS admit
  FROM g
  LEFT JOIN (SELECT call_date, ticker, COUNT(*) AS n FROM `stock-trading-498512.events.news_reaction_calls` GROUP BY call_date, ticker) AS today
    ON today.ticker = g.ticker AND today.call_date = g.call_date
)
SELECT IF(a.admit, a.call_date, NULL), a.lead_id, a.ticker, a.headline_hash, a.headline, a.published_ts, a.source,
       a.source_url, a.direction, a.agreement_score, a.k, a.votes_json, a.horizon_days, a.scorer_routine,
       a.scorer_session
FROM a
WHERE a.admit
