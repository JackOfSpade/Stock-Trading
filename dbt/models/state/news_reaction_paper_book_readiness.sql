-- Parallel-run dbt port of bigquery/261_news_reaction_paper_book.sql:state.news_reaction_paper_book_readiness — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH consts AS (
  SELECT 0.8 AS agreement_gate, 0.002 AS cost_round_trip, 30 AS n_min
),
flagged AS (
  SELECT
    r.*,
    (r.direction = 'UP' AND CAST(r.agreement_score AS FLOAT64) >= cst.agreement_gate) AS long_gated,
    (r.direction = 'DOWN' AND CAST(r.agreement_score AS FLOAT64) >= cst.agreement_gate) AS short_gated
  FROM {{ ref('news_reaction_call_returns') }} r
  CROSS JOIN consts cst
),
agg AS (
  SELECT
    lead_id,
    MAX(horizon_days) AS horizon_days,
    COUNT(*) AS n_calls_total,
    COUNTIF(long_gated) AS n_long_gated,
    COUNTIF(long_gated AND realized_return IS NOT NULL) AS n_realized,
    AVG(IF(long_gated, realized_return, NULL)) AS gross_mu,
    AVG(IF(long_gated, realized_return - realized_spy_return, NULL)) AS excess_vs_spy_mu,
    SAFE_DIVIDE(COUNTIF(long_gated AND realized_return > 0),
                COUNTIF(long_gated AND realized_return IS NOT NULL)) AS hit_rate,
    COUNTIF(short_gated) AS n_short_gated,
    AVG(IF(short_gated, realized_return, NULL)) AS short_gross_mu,
    MIN(call_date) AS first_call_date,
    MAX(call_date) AS last_call_date
  FROM flagged
  GROUP BY lead_id
)
SELECT
  a.lead_id,
  cst.agreement_gate,
  cst.cost_round_trip,
  cst.n_min,
  a.horizon_days,
  a.n_calls_total,
  a.n_long_gated,
  a.n_realized,
  a.gross_mu,
  a.gross_mu - cst.cost_round_trip AS net_mu,
  a.excess_vs_spy_mu,
  a.hit_rate,
  a.n_short_gated,
  a.short_gross_mu,
  a.first_call_date,
  a.last_call_date,
  DATE_DIFF(CURRENT_DATE('America/Denver'), a.last_call_date, DAY) AS days_since_last_call,
  COALESCE(a.n_realized >= cst.n_min AND (a.gross_mu - cst.cost_round_trip) > 0, FALSE) AS ready
FROM agg a
CROSS JOIN consts cst
