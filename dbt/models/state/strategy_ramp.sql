-- Parallel-run dbt port of bigquery/259_live_ramp.sql:state.strategy_ramp — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH params AS (
  SELECT * FROM {{ source('ops', 'strategy_ramp_params') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code ORDER BY effective_ts DESC) = 1
),
book AS (
  SELECT COALESCE(SUM(nav), 0) AS book_nav FROM {{ ref('strategy_nav') }}
),
rails AS (
  SELECT active_count FROM {{ ref('arsenal_rails') }}
),
path AS (
  SELECT strategy_code,
         ARRAY_AGG(STRUCT(idx, score_after, cum_llr, surprise, evidence_kill, evidence_confirmed) ORDER BY idx) AS p
  FROM {{ ref('strategy_ramp_trades') }}
  GROUP BY strategy_code
),
last_row AS (
  SELECT strategy_code,
         ARRAY_LENGTH(p) AS trades_n,
         p[ORDINAL(ARRAY_LENGTH(p))] AS l,
         (SELECT MAX(x.idx) FROM UNNEST(p) AS x WHERE x.surprise) AS last_surprise_idx
  FROM path
),
sized AS (
  SELECT
    r.strategy_code,
    r.current_state,
    r.immutable_since                                   AS probe_entry_ts,
    p.effective_ts                                      AS params_effective_ts,
    p.opening_score,
    COALESCE(l.l.score_after, p.opening_score)          AS score,
    COALESCE(l.trades_n, 0)                             AS trades_n,
    COALESCE(l.l.cum_llr, 0.0)                          AS cum_llr,
    COALESCE(l.l.evidence_kill, FALSE)                  AS evidence_kill,
    COALESCE(l.l.evidence_confirmed, FALSE)             AS evidence_confirmed,
    l.last_surprise_idx,
    b.book_nav,
    rails.active_count,
    GREATEST(p.cost_min_usd, p.floor_pct_nav * b.book_nav) AS floor_usd,
    SAFE_DIVIDE(b.book_nav, rails.active_count)            AS full_usd,
    COALESCE(n.deployed_mv, 0)                             AS deployed_mv
  FROM {{ source('state_external', 'strategy_roster') }} r
  JOIN params p USING (strategy_code)
  LEFT JOIN last_row l USING (strategy_code)
  LEFT JOIN {{ ref('strategy_nav') }} n ON n.strategy = r.strategy_code
  CROSS JOIN book b
  CROSS JOIN rails
  WHERE r.current_state = 'PROBE'
),
capped AS (
  SELECT *, floor_usd + score * GREATEST(0.0, COALESCE(full_usd, 0.0) - floor_usd) AS deployable_cap_usd
  FROM sized
)
SELECT
  c.*,
  c.deployable_cap_usd - c.deployed_mv                 AS headroom_usd,
  c.deployed_mv > 1.05 * c.deployable_cap_usd           AS cap_breached,
  (ROUND(c.score, 10) >= 1.0   -- ten in-line increments of 0.1 sum to 0.9999999999999999 in binary floating point; the reference implementation rounds to 10 places too
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
                   WHERE cl.change_key = CONCAT(c.strategy_code, ':PROBE->ADOPTED'))) AS graduation_ready
FROM capped c
