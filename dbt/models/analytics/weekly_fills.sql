-- Parallel-run dbt port of bigquery/14_weekly_report.sql:analytics.weekly_fills — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT ticker, side, shares, price, strategy,
       CAST(DATE(fill_ts, 'America/Denver') AS STRING) AS fill_date,
       UNIX_MILLIS(fill_ts) AS fill_ts_ms  -- lets the renderer format in the DETECTED user tz (state.user_tz)
FROM {{ ref('trade_fills_curated') }}
WHERE DATE(fill_ts, 'America/Denver') >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
ORDER BY fill_ts DESC LIMIT 6
