-- 174_web_call_telemetry.sql (2026-08-17)
-- Project: stock-trading-498512. Apply after 10_observability.sql (ops.run_log, which the coverage
-- columns below join against). Purely additive: one new append-only table and two new state.* views.
-- No existing object is touched, no procedure body changed, and nothing here gates anything --
-- there is no threshold, no alert, and no cap in this file by design.
--
-- APPLY STATUS: APPLIED LIVE 2026-08-17 15:13 UTC (ops.web_calls), 15:13:48 / 15:13:57 (the two views).
-- 8bd7d13's commit message said "NOT YET APPLIED LIVE"; that was true when written and is now stale --
-- the apply happened ~5h later and was never written back anywhere, which is why a 2026-08-19 review
-- re-derived it from the commit message and started from the wrong premise. Verified 2026-08-19 against
-- INFORMATION_SCHEMA.TABLES in both datasets. Do NOT re-apply expecting to create anything: the table is
-- CREATE TABLE IF NOT EXISTS (a no-op re-run is harmless but proves nothing), and re-running the two
-- CREATE OR REPLACE VIEWs is only correct if this file is still the newest definition of them.
--
-- WHAT IS ACTUALLY BROKEN IS ADOPTION, NOT THE DDL (measured 2026-08-19). ops.web_calls held 54 rows,
-- every one stamped run_date = 2026-08-17 (the day it was created) and written by only D1 and W3.
-- D1 ran again on 2026-08-18, fetched a published breadth figure and cited external URLs, and logged
-- ZERO rows here; no other routine has ever logged one. The fix is NOT in this file -- it is that the
-- shared rule's part (d) obligation now lives at the run-logging template in Claude_Task_Plan.md
-- (Observability -> "Run logging (every run)"), where a session actually reads it at session end,
-- instead of only in the shared-rules section ~450 lines away. state.web_spend_month.has_unreported_runs
-- is the column that makes this gap visible; it is TRUE for essentially the whole fleet right now.
--
-- ===== WHY =====
-- The owner asked on 2026-08-17 whether the fleet uses its metered Tavily requests EFFICIENTLY,
-- and defined efficiency precisely: paying for capability is fine, "not pulling the same info
-- twice" is the thing to avoid. Neither half was answerable from the warehouse:
--
--   * ops.run_log records run_id/log_ts/routine/run_date/status/session_id/branch/rows_written/
--     error_msg/note/instruction. NOT ONE is a tool-call or spend metric.
--   * A per-dataset INFORMATION_SCHEMA.COLUMNS sweep across all six datasets (analytics, events,
--     events_restore_drill, ops, perf, state -- 178 tables) found ZERO columns named url,
--     source_url, link, citation, headline, snippet, raw_content, fetched_at or retrieved_at, and
--     a cache/ttl/expire/query_hash sweep found only ops.order_stage_mutex.lease_expires_at, an
--     unrelated order-staging lease. No cache, and nothing shaped to hold a fetched page.
--   * The only trace of external research anywhere was incidental URLs in
--     events.decision_log.body_md free text -- 675 mentions all-time, and just ONE of the 496
--     decision_log rows written in the trailing 30 days.
--
-- Ground truth for the LEVEL came from the owner reading the Tavily dashboard on 2026-08-17:
-- May 507 -> June 1,349 -> July 3,009 credits, and Aug 1-17 at 3,751 credits / $22.01, which
-- reconciles exactly against the published rate ((3751-1000) * 0.008 = 22.01, confirming the
-- 1,000 free monthly credits and the $0.008 pay-as-you-go price). August endpoint mix: search
-- 3,661 (97.6%), extract 70, research 16, map 3, crawl 1.
--
-- So the dashboard already answers "how much" for the ACCOUNT. What it can never answer, and what
-- this file exists for, is the two questions that actually drive a fix:
--   (1) WHICH ROUTINE is spending it, and
--   (2) WHAT was fetched -- so a repeat fetch of the same target is detectable at all.
--
-- ===== THE $100 TAVILY SPEND CAP IS A DELIBERATE TRIGGER, NOT A FAILURE MODE TO PREVENT =====
-- Owner decision 2026-08-17, recorded here because this file is the durable artifact a future session
-- opens when it asks "what is this telemetry for?", and it must not read the series as a budget alarm.
-- The $100/month cap (= 12,500 pay-as-you-go credits) is LEFT IN PLACE ON PURPOSE: reaching it is the
-- SIGNAL to move to a monthly Tavily tier, which is cheaper at that volume. PAYG costs
-- (credits - 1000) * $0.008, so it equals Bootstrap's flat $100/15,000 at ~13,500 credits/month --
-- the cap and the switch-point are essentially the same number, which is exactly what makes the cap a
-- good trigger. Below ~13,500 credits PAYG is cheaper, so switching EARLY costs money.
-- A future session must NOT raise the cap reflexively, treat reaching it as an incident, or "fix" it by
-- switching plans early. The early warning is already wired on Tavily's side (an 80% email usage alert,
-- enabled and verified 2026-08-17, firing around 11,000 credits while PAYG is still the cheaper option):
-- the correct response to that email is to PROJECT month-end usage and switch only if the projection
-- clears ~13,500. Verified 2026-08-19 against tavily.com/pricing: a "Project" tier exists at $30/month
-- for 4,000 credits, BETWEEN free and Bootstrap -- and it does NOT move the switch-point, because PAYG's
-- 1,000 free credits make PAYG strictly cheaper than Project at every volume ($24 vs $30 at exactly
-- 4,000 credits). Do not "discover" Project later and switch to it; the number to switch on is ~13,500.
-- What must NOT happen is reaching the cap UNNOTICED -- Tavily then hard-stops with HTTP 432
-- ("This request exceeds your plan's set usage limit"), erroring mid-run, which is the same degradation
-- that cost the 2026-08-17 sweep its COHR detection when FMP's 250/day cap blew. The 80% email plus
-- state.web_spend_month are the two things preventing that; the cap itself is working as designed.
--
-- ===== WHY A TABLE AND NOT A run_log.note TOKEN =====
-- The first draft of this file parsed a WEB[provider=..;tool=..;n=..;credits=..] token out of
-- ops.run_log.note, mirroring the RETRY[...]/DEPWAIT[...] tokens that bigquery/88 already parses.
-- That was REPLACED, deliberately: a note token can carry per-run COUNTS but cannot carry the
-- fetched targets, so it could report volume forever and never once answer "did we pull this
-- twice" -- the owner's actual question. Rather than run two mechanisms (a token for spend, a
-- table for targets), this file keeps ONE substrate: routines append their calls here, and both
-- the spend rollup and the duplicate detector are views over it. That also matches the standing
-- repo rule that records belong in tables, not in prose fields.

CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.web_calls` (
  call_ts          TIMESTAMP NOT NULL OPTIONS(description="When the call was made (routine-supplied or CURRENT_TIMESTAMP)."),
  routine          STRING    NOT NULL OPTIONS(description="Routine id, e.g. D1, W1, M2 -- matches ops.run_log.routine."),
  run_date         DATE      NOT NULL OPTIONS(description="Operating-plane run date (America/Denver), same key ops.run_log uses."),
  session_id       STRING             OPTIONS(description="The run session id, so coverage can be counted per RUN not per row."),
  provider         STRING    NOT NULL OPTIONS(description="tavily | anthropic | fmp | hf -- the metered external surface."),
  tool             STRING    NOT NULL OPTIONS(description="tavily: search|extract|research|crawl|map. anthropic: web_search|web_fetch. else the tool name."),
  target           STRING             OPTIONS(description="The SEARCH QUERY (search/research) or the URL (extract/crawl/map). The field duplicate detection runs on."),
  depth            STRING             OPTIONS(description="Priced mode actually chosen: basic|advanced|mini|pro, or NULL where the tool has no mode."),
  credits          NUMERIC            OPTIONS(description="Credits consumed. From Tavily include_usage=true where available, else estimated from the published rate card."),
  credits_reported BOOL               OPTIONS(description="TRUE when `credits` came from the provider (include_usage), FALSE/NULL when it is a routine estimate.")
)
PARTITION BY run_date
CLUSTER BY routine, provider
OPTIONS(description="Append-only log of metered external calls, one row per call. Written by the routines per the Claude_Task_Plan.md shared rule 'Metered external calls'. Substrate for state.web_spend_month and state.web_duplicate_targets. The provider dashboard remains authoritative for the ACCOUNT total; this table is authoritative for per-routine attribution and for duplicate detection, which no dashboard can show.");


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
--
-- SUPERSEDED LIVE by bigquery/203_web_call_provider_normalise.sql (2026-08-30) — that file is the
-- CURRENT canonical definition of state.web_spend_month. It folds the ops.web_calls.provider
-- vocabulary on read (LOWER/TRIM, with `huggingface` -> `hf`) so case/spelling variants aggregate
-- into one cell, and makes this view's n_priced_upgrade depth test case-insensitive. The version
-- below is left byte-unchanged as the DR-rebuild record; do NOT re-apply it live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.web_spend_month` AS
WITH per_cell AS (
  SELECT
    DATE_TRUNC(run_date, MONTH)                       AS month_start,
    provider,
    routine,
    COUNT(*)                                          AS n_calls,
    COUNT(DISTINCT session_id)                        AS run_covered,
    SUM(credits)                                      AS credits,
    COUNTIF(credits_reported)                         AS n_calls_provider_reported,
    COUNTIF(provider = 'tavily' AND depth IN ('advanced', 'pro')) AS n_priced_upgrade
  FROM `stock-trading-498512.ops.web_calls`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 180 DAY)
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
-- Normalisation matters more than the grouping here, and gets two specific things right:
--   (a) CACHE-BUSTING PARAMS ARE STRIPPED. D1 and M1a are both instructed to append a `?cb=<today>`
--       param to defeat a stale Tavily extract cache (D1 EQUITY-BREADTH step 2, after the
--       2026-08-16 incident where a Barchart page nine days stale came back reading a plausible
--       value; M1a hy_oas for fred.stlouisfed.org HTTP 403). That param changes every single day BY
--       DESIGN, so without stripping it every repeat fetch of the same page looks unique and this
--       view would report zero duplicates while the fleet re-pulled the same URL daily -- the exact
--       blind spot it exists to close. utm_* and fbclid are stripped for the same reason.
--   (b) A SEARCH QUERY AND A URL NORMALISE DIFFERENTLY. URLs lose scheme, www., a trailing slash
--       and their whole query string; free-text queries are lowercased and whitespace-collapsed.
-- Grouping is per (provider, normalised target) so a page pulled by TWO different routines counts
-- as a duplicate -- cross-routine repetition is the kind least likely to be noticed by either.
--
-- SUPERSEDED LIVE by bigquery/203_web_call_provider_normalise.sql (2026-08-30) — that file is the
-- CURRENT canonical definition of state.web_duplicate_targets. It adds a THIRD normalisation to the
-- two described above: the provider token itself is folded (LOWER/TRIM, `huggingface` -> `hf`), so
-- an `fmp` row and an `FMP` row for the same target group together instead of reading as two
-- singletons. Measured 2026-08-30, that change moves nothing yet (39 groups before and after) —
-- it is a latent-trap closure. Do NOT re-apply this file's view in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.web_duplicate_targets` AS
WITH normalised AS (
  SELECT
    provider,
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
