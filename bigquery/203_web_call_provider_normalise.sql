-- ===== 203: ops.web_calls provider vocabulary — normalise ON READ (case + huggingface -> hf) =====
-- (2026-08-30, interactive alert triage — ops.alerts info d35dc719-5c3c-4e08-98c1-782c4e131702,
--  source OPS2, category `web_call_provider_vocabulary_drift`.)
--
-- WHY. `ops.web_calls.provider` carries a canonical vocabulary in its own column description
-- (bigquery/174_web_call_telemetry.sql: "tavily | anthropic | fmp | hf") and NOTHING enforces it.
-- The written values drifted. RE-MEASURED 2026-08-30 over the whole life of the table:
--     anthropic    984 rows, 5 routines, 2026-08-17..2026-08-30   <- canonical
--     tavily       386 rows, 4 routines, 2026-08-17..2026-08-30   <- canonical
--     fmp          241 rows, 6 routines, 2026-08-17..2026-08-30   <- canonical
--     hf             7 rows, 1 routine,  2026-08-17..2026-08-30   <- canonical
--     FMP            3 rows, 2 routines, 2026-08-26..2026-08-27   <- DRIFT
--     huggingface    1 row,  1 routine,  2026-08-26..2026-08-26   <- DRIFT
-- It is not a per-routine convention that could be read as deliberate: D2a wrote `fmp` on
-- 2026-08-26 and `FMP` on 2026-08-27; D1 wrote `huggingface` on 2026-08-26 and `hf` on 2026-08-27.
-- The same routine varies run to run, and OPS2 -- which raised the alert -- wrote one of the `FMP`
-- rows itself.
--
-- SILENT-UNDERCOUNT CLASS, NOT A GATE CLASS. Three reads over this column are case-sensitive today:
--   1. `state.web_spend_month` GROUPs BY (month_start, provider, routine) -- each variant becomes a
--      SEPARATE row for the same provider, so a per-provider spend read undercounts.
--   2. `state.fmp_daily_budget` (bigquery/192) filters `WHERE provider = 'fmp'` -- the FMP free-tier
--      250/day counter, whose failure mode is SILENT EVIDENCE LOSS rather than a bill, simply does
--      not see the `FMP` rows. Measured 2026-08-30 against live: 2026-08-26 reads 24 requests but
--      is really 25, 2026-08-27 reads 21 but is really 23.
--   3. `state.web_duplicate_targets` GROUPs BY (provider, target_norm) -- the same target logged
--      once as `fmp` and once as `FMP` does not group, so a genuine repeat fetch reads as two
--      singletons and the owner-defined waste metric (`credits_on_repeats`) misses it.
-- And `state.web_spend_month.n_priced_upgrade` is
-- `COUNTIF(provider = 'tavily' AND depth IN ('advanced','pro'))` -- case-sensitive on BOTH columns,
-- so a `Tavily`/`Advanced` row would score zero priced upgrades with no error at all. Every one of
-- these reads as COMPLETE while being wrong, which is exactly what `has_unreported_runs` cannot
-- catch: it detects a run that logged NOTHING, never a run that logged under a mis-keyed provider.
--
-- THE FIX -- NORMALISE ON READ, IN ALL THREE VIEWS. `LOWER(TRIM(provider))`, with the single
-- observed non-canonical spelling `huggingface` folded to `hf`. Same shape as bigquery/199's
-- `state.queue_venue_claim_unwired` fix (a case-sensitive vocabulary literal made a detector blind
-- to real rows) and bigquery/201's dash normalisation: a NORMALISATION, not a masking fix.
--   * `ops.web_calls` IS NOT TOUCHED. It is append-only (CLAUDE.md; bigquery/174's own header) and
--     no landed row is altered, deleted or rewritten -- the repair is entirely in the read path, so
--     it also repairs HISTORY rather than only future rows.
--   * A token that is NOT a case/spelling variant of a canonical one (say `financialmodelingprep`)
--     still surfaces as its OWN row in `state.web_spend_month` -- visible, not silently merged into
--     a neighbour. Deliberate: this file makes the KNOWN variants aggregate correctly; it does not
--     pretend to canonicalise whatever a future routine invents. It also does not blind the
--     detector that found this: OPS2 measured the drift against the RAW table, not these views.
--   * `depth` is folded with `LOWER(TRIM(...))` in the `n_priced_upgrade` term for the same reason.
--     No case drift exists in `depth` as of 2026-08-30 (NULL 1235, `basic` 220, `advanced` 166,
--     `n/a` 1), so this closes a latent trap and changes no current row's classification. The one
--     `n/a` row is itself a vocabulary drift (the documented form for "no priced mode" is NULL) but
--     is deliberately NOT folded: it scores identically either way and no view groups on `depth`.
--
-- MEASURED EFFECT OF THIS FILE, run read-only against live BEFORE applying (2026-08-30):
--   * state.web_spend_month: exactly three cells merge and NOTHING else changes --
--     (fmp, D2a) 8 -> 10, (fmp, OPS2) 3 -> 4, (hf, D1) 7 -> 8; the `FMP` and `huggingface` rows
--     disappear as separate cells. Every `n_priced_upgrade` value is unchanged.
--   * state.fmp_daily_budget: 2026-08-26 24 -> 25 (9.6% -> 10.0% of cap), 2026-08-27 21 -> 23
--     (8.4% -> 9.2%). No other day moves; nothing crosses the 60% warning threshold.
--   * state.web_duplicate_targets: 39 groups before, 39 after, zero groups added or removed --
--     the drifted rows' targets happen not to collide with a canonical-provider row today. This
--     change is therefore a latent-trap closure there, with no current effect, and is included
--     because leaving one of three sibling reads case-sensitive is how this class comes back.
--
-- NOT FIXED HERE, RECORDED. `ops.web_calls.tool` carries a wider vocabulary drift (`tavily_search`
-- 18 vs `search` 315; `tavily_extract` 12 vs `extract` 45; `mcp__FMP__chart` 1 vs `chart` 19;
-- `quote/quote` 5 vs `quote` 9 -- measured 2026-08-30). No view aggregates or filters on `tool`
-- (`state.web_duplicate_targets` only ARRAY_AGGs it for display), so it costs no number today, and
-- the column's own description explicitly allows an open vocabulary for non-Tavily providers
-- ("else the tool name"). Deciding what canonical means there is a separate question and must not
-- be smuggled into a normalisation fix.
--
-- SUPERSEDES `state.web_spend_month` and `state.web_duplicate_targets` in
-- `bigquery/174_web_call_telemetry.sql`, and `state.fmp_daily_budget` in
-- `bigquery/192_fmp_daily_budget.sql`. Apply after both. Defines exactly those three views;
-- creates, redefines or drops nothing else. The `ops.web_calls` TABLE is unchanged, and so is
-- `state.web_call_coverage` (canonical at `bigquery/200_web_call_coverage_obligation_floor.sql`),
-- which does not read `provider` at all.
--
-- COLUMN SHAPE IS BYTE-COMPATIBLE with the definitions being superseded -- same columns, same
-- order, same `ORDER BY` -- so W5's EXTERNAL-SPEND DIGEST and OPS0's STEP 5 reads need no change.


-- Monthly spend rollup, grain (month_start, provider, routine). Aggregate away `routine` for the
-- fleet total that compares against the provider dashboard; keep it for the attribution the
-- dashboard cannot produce.
--
-- run_covered / runs_in_month keep an ABSENCE honest. A routine that logged no row this month
-- either made no metered call or made calls and failed to log them, and those are indistinguishable
-- from this table alone. runs_in_month counts terminal ops.run_log rows DIRECTLY (not from this
-- table), so has_unreported_runs names the reporting gap instead of hiding it inside a credits
-- total that reads as complete. A routine that genuinely never touches an external surface
-- (D2a, OPS0, SL5, ...) sits at run_covered = 0 permanently and correctly.
CREATE OR REPLACE VIEW `stock-trading-498512.state.web_spend_month` AS
WITH normalised AS (
  -- Provider vocabulary folded here, ONCE, so every downstream term in this view agrees on what a
  -- provider IS (bigquery/203). Case-only variants and `huggingface` collapse onto the canonical
  -- token; anything else passes through lowercased and stays visible as its own row.
  SELECT
    run_date,
    routine,
    session_id,
    depth,
    credits,
    credits_reported,
    CASE
      WHEN LOWER(TRIM(provider)) = 'huggingface' THEN 'hf'
      ELSE LOWER(TRIM(provider))
    END AS provider
  FROM `stock-trading-498512.ops.web_calls`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 180 DAY)
),
per_cell AS (
  SELECT
    DATE_TRUNC(run_date, MONTH)                       AS month_start,
    provider,
    routine,
    COUNT(*)                                          AS n_calls,
    COUNT(DISTINCT session_id)                        AS run_covered,
    SUM(credits)                                      AS credits,
    COUNTIF(credits_reported)                         AS n_calls_provider_reported,
    COUNTIF(provider = 'tavily' AND LOWER(TRIM(depth)) IN ('advanced', 'pro')) AS n_priced_upgrade
  FROM normalised
  GROUP BY month_start, provider, routine
),
-- Terminal rows only: ops.run_log writes a paired started + terminal row per run, so counting every
-- row would double the denominator and make coverage look half as complete as it is.
runs AS (
  SELECT
    DATE_TRUNC(run_date, MONTH) AS month_start,
    routine,
    COUNT(*)                    AS runs_in_month
  FROM `stock-trading-498512.ops.run_log`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 180 DAY)
    AND status IN ('completed', 'failed', 'halted')
  GROUP BY month_start, routine
)
SELECT
  c.month_start,
  c.provider,
  c.routine,
  c.n_calls,
  c.credits,
  c.n_calls_provider_reported,
  c.n_priced_upgrade,
  c.run_covered,
  r.runs_in_month,
  c.run_covered < r.runs_in_month AS has_unreported_runs
FROM per_cell c
LEFT JOIN runs r
  ON r.month_start = c.month_start AND r.routine = c.routine
ORDER BY c.month_start DESC, c.provider, c.credits DESC;


-- DUPLICATE DETECTION -- the owner-defined waste ("not pulling the same info twice").
--
-- Normalisation matters more than the grouping here, and gets three specific things right:
--   (a) CACHE-BUSTING PARAMS ARE STRIPPED. D1 and M1a are both instructed to append a `?cb=<today>`
--       param to defeat a stale Tavily extract cache (D1 EQUITY-BREADTH step 2, after the
--       2026-08-16 incident where a Barchart page nine days stale came back reading a plausible
--       value; M1a hy_oas for fred.stlouisfed.org HTTP 403). That param changes every single day BY
--       DESIGN, so without stripping it every repeat fetch of the same page looks unique and this
--       view would report zero duplicates while the fleet re-pulled the same URL daily -- the exact
--       blind spot it exists to close. utm_* and fbclid are stripped for the same reason.
--   (b) A SEARCH QUERY AND A URL NORMALISE DIFFERENTLY. URLs lose scheme, www., a trailing slash
--       and their whole query string; free-text queries are lowercased and whitespace-collapsed.
--   (c) THE PROVIDER TOKEN IS FOLDED TOO (bigquery/203). Grouping is per (provider, normalised
--       target), so before this an `fmp` row and an `FMP` row for the same target landed in
--       different groups and a real repeat read as two singletons.
-- Grouping is per (provider, normalised target) so a page pulled by TWO different routines counts
-- as a duplicate -- cross-routine repetition is the kind least likely to be noticed by either.
CREATE OR REPLACE VIEW `stock-trading-498512.state.web_duplicate_targets` AS
WITH normalised AS (
  SELECT
    CASE
      WHEN LOWER(TRIM(provider)) = 'huggingface' THEN 'hf'
      ELSE LOWER(TRIM(provider))
    END AS provider,
    tool,
    routine,
    run_date,
    credits,
    target,
    CASE
      WHEN REGEXP_CONTAINS(LOWER(TRIM(target)), r'^https?://') THEN
        -- URL: drop scheme, leading www., the entire query string, and any trailing slash.
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(LOWER(TRIM(target)), r'^https?://(www\.)?', ''),
            r'\?.*$', ''),
          r'/+$', '')
      ELSE
        -- Free-text query: collapse internal whitespace so trivial spacing differences do not
        -- masquerade as distinct questions.
        REGEXP_REPLACE(LOWER(TRIM(target)), r'\s+', ' ')
    END AS target_norm
  FROM `stock-trading-498512.ops.web_calls`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 90 DAY)
    AND target IS NOT NULL
    AND TRIM(target) != ''
)
SELECT
  provider,
  target_norm,
  COUNT(*)                                   AS n_fetches,
  COUNT(DISTINCT routine)                    AS n_routines,
  COUNT(DISTINCT run_date)                   AS n_distinct_days,
  ARRAY_AGG(DISTINCT routine ORDER BY routine) AS routines,
  ARRAY_AGG(DISTINCT tool ORDER BY tool)     AS tools,
  MIN(run_date)                              AS first_fetched,
  MAX(run_date)                              AS last_fetched,
  SUM(credits)                               AS credits_total,
  -- Credits attributable to the REPEATS only: everything past the first fetch. This is the
  -- recoverable number -- the first fetch was never waste. The per-fetch average divides by the
  -- count of rows that actually CARRY a credit figure, not by COUNT(*): a row with NULL credits
  -- contributes nothing to SUM, so dividing by COUNT(*) would understate the average and thus
  -- overstate the recoverable amount. SAFE_DIVIDE covers the all-NULL case.
  SUM(credits) - SAFE_DIVIDE(SUM(credits), COUNTIF(credits IS NOT NULL)) AS credits_on_repeats,
  COUNT(DISTINCT routine) > 1                AS is_cross_routine
FROM normalised
GROUP BY provider, target_norm
HAVING COUNT(*) > 1
ORDER BY credits_on_repeats DESC, n_fetches DESC;


-- FMP daily budget -- counts FMP requests against the 250/day ACCOUNT-WIDE free-tier cap, whose
-- failure mode is silent evidence loss rather than a bill (bigquery/192's header carries the full
-- rationale and the 2026-08-17 incident; nothing in it is withdrawn here).
-- Carried forward from bigquery/192 UNCHANGED except the provider predicate, which was the
-- case-sensitive literal `provider = 'fmp'` and therefore could not see the `FMP` rows at all.
-- HONEST FLOOR, NOT A METER, still: this counts LOGGED calls only, so pct_consumed remains a lower
-- bound while ops.web_calls adoption is incomplete (state.web_call_coverage, bigquery/200, is what
-- makes the unlogged runs visible). RECORD-ONLY: no cap enforcement, no gate, no throttle.
CREATE OR REPLACE VIEW `stock-trading-498512.state.fmp_daily_budget` AS
WITH fmp AS (
  SELECT run_date, COUNT(*) AS logged_fmp_requests
  FROM `stock-trading-498512.ops.web_calls`
  WHERE LOWER(TRIM(provider)) = 'fmp'
    AND run_date >= DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY)
  GROUP BY run_date
),
fanout AS (
  SELECT run_date, COUNT(DISTINCT routine) AS fan_out_routines_completed
  FROM `stock-trading-498512.ops.run_log`
  WHERE status = 'completed'
    AND routine IN ('D1','W1','M2','Q2','A1')
    AND run_date >= DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY)
  GROUP BY run_date
)
SELECT
  run_date,
  COALESCE(f.logged_fmp_requests, 0) AS logged_fmp_requests,
  250 AS daily_cap,
  ROUND(COALESCE(f.logged_fmp_requests, 0) / 250 * 100, 1) AS pct_consumed,
  COALESCE(fo.fan_out_routines_completed, 0) AS fan_out_routines_completed,
  COALESCE(fo.fan_out_routines_completed, 0) > 1 AS fan_out_day,
  CURRENT_TIMESTAMP() AS checked_at
FROM fmp f
FULL OUTER JOIN fanout fo USING (run_date);
