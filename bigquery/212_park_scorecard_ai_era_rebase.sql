-- Park scorecard ATTRIBUTION defect (2026-09-03, interactive-session probe). Project: stock-trading-498512.
--
-- ============================================================================
-- THE DEFECT. W5's PARK SCORECARD grades the AI Park Allocator's judgment, but the series it grades
-- starts THREE MONTHS BEFORE the allocator existed, so the published verdict is dominated by
-- decisions the allocator never made.
-- ============================================================================
-- Claude_Task_Plan.md's W5 PARK SCORECARD bullet says, verbatim: read
--   "analytics.park_nav_daily (THE AI ALLOCATOR'S OWN chained park TWR + vehicle label)"
-- against park_counterfactuals' three benchmarks. The stated purpose is the allocator's own judgment
-- ("if AI judgment can't beat a lookup table, the owner should know" -- same bullet).
--
-- Measured live 2026-09-03: analytics.park_counterfactuals spans 2026-04-17 .. 2026-09-02 (96 rows).
-- Its axis is park_nav_daily's, which begins at PARK INCEPTION -- the founding SGOV policy row
-- (events.park_policy_changes, effective 2026-04-17, "SGOV was the idle-capital vehicle from the
-- start of this account's trading history"). But the AI Park Allocator's first BOUND, book-moving
-- call is 2026-07-26 (events.decision_log entry_type='park-allocation', fields.status='BOUND';
-- the 07-19..07-22 and 07-25 rows are all RECORD_ONLY and moved nothing). Between those two dates
-- the park was moved ONCE, and by the OWNER, not the allocator: events.park_policy_changes
-- effective 2026-07-15, note "Owner-executed manual IBKR transfer: sold all SGOV, bought VOO.
-- Owner directive 2026-07-15" (bigquery/54_park_policy_voo_cutover.sql).
--
-- That owner cutover went underwater immediately (VOO 690.33 on 07-15 -> 679.14 on 07-24, -1.62%)
-- and the allocator inherits the hole. Segment decomposition, MEASURED against the live view this
-- session (not estimated -- each row is (1+idx_end)/(1+idx_anchor)-1 evaluated in BigQuery):
--
--   SEGMENT                                          ai      sgov     voo     rule   ai-sgov
--   PRE-AI   2026-04-17 .. 07-24 (owner cutover)   -0.858%  +0.972%  +4.343%  -2.319%  -1.83pp
--   AI ERA   2026-07-24 .. 09-02 (allocator only)  +1.063%  +0.392%  +3.574%  +2.855%  +0.67pp
--   PUBLISHED inception .. 09-02 (what W5 logs)    +0.196%  +1.369%  +8.072%  +0.470%  -1.17pp
--
-- The published -1.17pp "AI trails SGOV" verdict is ENTIRELY inherited from the pre-AI segment's
-- -1.83pp. In its own era the allocator BEATS never-switching SGOV by +67bp. The sign flips.
--
-- THIS FIX IS NOT A WHITEWASH, and that is the main reason to trust it. Re-anchoring moves the
-- AI-vs-rule-table leg the OTHER way -- the shadow rule's own pre-AI segment is -2.319%, so
-- correcting the anchor takes the AI from 27bp BEHIND the rule table to 179bp BEHIND it. One leg
-- improves, one gets materially worse. An attribution fix that only ever flattered the AI would be
-- the thing to distrust; this one does not.
--
-- SAME DEFECT CLASS AS bigquery/179, which this file follows rather than supersedes. That file's
-- own header states the principle exactly: the benchmark legs are computed from clean,
-- never-switching chains, so "ONLY the AI's own series carries this penalty -- an asymmetry
-- precisely in the comparison the scorecard exists to make." 179 fixed WHEN the AI's series is
-- marked (fill vs close). This file fixes WHERE it starts. Both are the same failure mode: the
-- graded series and the grading series are not measured on the same footing. Note 179 already
-- established the precedent that a wrong verdict here has real consequence -- five consecutive
-- park-scorecard decision_log entries (2026-07-19 .. 08-17) published "trails ALL THREE benchmarks
-- including the rejected rule table" and two of the three legs were artifacts.
--
-- ============================================================================
-- WHY ADD COLUMNS RATHER THAN RE-ANCHOR THE EXISTING ONES.
-- ============================================================================
-- The inception-anchored series is NOT wrong as a measure of the PARK BOOK -- "how has idle capital
-- actually done since this account started parking it" is a legitimate, separate question, and it is
-- the honest denominator for the owner's own 07-15 call. Re-anchoring the existing four columns
-- would destroy that reading and silently rewrite every historical scorecard comparison. So the
-- existing five columns (as_of_date, sgov_index, voo_index, rule_index, ai_index) are carried
-- through with byte-identical logic and semantics, and five new columns are ADDED alongside. Every
-- existing reader is unaffected by construction; W5 gains the attribution-correct pair to report.
--
-- WHY 2026-07-24 IS THE RIGHT ANCHOR, and the objection that has to be answered first. The
-- events.park_policy_changes row effective 2026-07-26 describes its own source call as "itself an
-- owner-directed REPLAY of the 2026-07-25 RECORD_ONLY call d4464255-...". A reviewer will reasonably
-- ask whether that makes 07-26 an OWNER decision too -- which would undercut treating it as the start
-- of AI-era attribution. It does not, on two measured grounds. (a) The owner's act was the v3
-- IMMEDIATE-BINDING cutover -- making the allocator's calls bind at all (PARK_ROUTER_DESIGN.md's v3
-- status block, owner directive 2026-07-26) -- not the choice of vehicle. The judgment being replayed
-- (VOO -> SGOV, de-risk, MEDIUM 60, with its stated FOMC / SPY-below-50dma / VIX-above-50d-avg
-- rationale) is the allocator's own, from its own RECORD_ONLY call. Contrast the 2026-07-15 row,
-- whose note is "Owner-executed manual IBKR transfer: sold all SGOV, bought VOO" -- there the owner
-- picked the vehicle, which is exactly why the pre-AI segment must be excluded. (b) That same note
-- states the call's "evidence is 2026-07-24 close, carried verbatim, NOT re-derived" -- so the
-- allocator's first binding judgment was formed on the 07-24 close, and anchoring the AI era at that
-- close measures it from the first moment its own judgment had evidence and effect. The axis
-- confirms the mechanics: park_nav_daily's dates run ... 07-23, 07-24, 07-27 ... (07-25/26 are a
-- weekend), so 07-24 is the last axis date before the call, and the first fill lands 07-27 -- whose
-- return the AI era therefore correctly includes, fill-anchored per bigquery/179.
-- (c) DECISIVE, and it makes the objection moot rather than merely answerable: there are TWO BOUND
-- park-allocation rows dated 2026-07-26, not one. state.decision_log_current gives
-- 1cfe3d28-c2c8-4903-89af-7626b484586c at 07:03 UTC (the owner-directed DE-RISK replay) and
-- bade05ab-8add-4b1c-9f02-2fd800d1d432 at 18:29 UTC, titled "D1 own daily call, distinct from this
-- morning owner-directed DE-RISK replay" (KEEP SGOV, BOUND). So D1 independently re-derived and
-- ratified the position the same day under its own judgment. Even if a future reader discounts the
-- replay entirely as owner-influenced, the allocator's first unambiguously-own BOUND call is STILL
-- dated 2026-07-26 and MIN(entry_date) -- and therefore the anchor -- is unchanged either way.
-- Independently, Claude_Task_Plan.md dates the IMMEDIATE BINDING regime itself to "owner directive
-- 2026-07-26", so 07-26 is also the canonical go-live of binding park calls, not a date this file
-- selected.
--
-- ANCHOR IS DERIVED, NOT HARDCODED. ai_era_start_date = the last axis date STRICTLY BEFORE the
-- allocator's first BOUND park-allocation call (expected: 2026-07-24, the Friday close before the
-- 07-26 call; first fill 07-27). Derived rather than pinned so that if the allocator's start is ever
-- re-dated, or a BOUND row is ever found earlier, the view follows instead of quietly disagreeing
-- with events.decision_log. The anchor is EXPOSED as its own column so any consumer can audit which
-- baseline produced the numbers it is reading -- a hardcoded constant inside the body could drift
-- from its own comment undetected, which is the failure mode bigquery/93's mis-citation of
-- 03_twr_engine.sql already demonstrated once.
--
-- Rebasing convention: NULL strictly before the anchor; exactly 0 AT the anchor; thereafter
-- (1+idx_t)/(1+idx_anchor)-1. NULL propagates from the base series, so voo_index_ai_era inherits
-- voo_index's own null-on-gap discipline unchanged. If NO BOUND call exists yet (a fresh deployment,
-- or the entry_type/status contract changing shape), ai_era_start_date is NULL and all four rebased
-- columns are NULL for every row -- the view degrades to exactly its current content rather than
-- silently anchoring at row zero and reporting the uncorrected number as if it were corrected.
--
-- ============================================================================
-- RECORD-ONLY, and the scope claim is re-measured this session rather than inherited from 179.
-- `grep -rn "park_counterfactuals"` reaches: bigquery/21, 93, 156, 179, README, this file;
-- dbt/parity_live_scope.yml, dbt/models/sources.yml, dbt/models/analytics/schema.yml,
-- dbt/models/analytics/park_counterfactuals.sql; and W5's PARK SCORECARD read in
-- Claude_Task_Plan.md. It gates nothing, sizes nothing, triggers no kill and feeds no order path.
-- Correcting it changes no trade, past or future; it changes what the system believes about its own
-- park judgment. The four ADDED index columns are consumed by nothing until W5's bullet is updated
-- in this same commit.
--
-- NEW UPSTREAM DEPENDENCY introduced by this file: state.decision_log_current (bigquery/144). The
-- view previously read only price/marks/shadow surfaces; it now also reads the allocator's own call
-- record to derive its anchor. Declared in dbt as source('state_external','decision_log_current'),
-- which already exists (added 2026-08-31) -- no sources.yml change is needed.
--
-- NOT APPLIED LIVE BY THIS SESSION (interactive session -- operator approves apply/push separately;
-- CLAUDE.md "Interactive sessions must ASK"). analytics.park_counterfactuals is in
-- dbt/parity_live_scope.yml, so scripts/check_live_sql_parity.py compares the LIVE body against this
-- file's canonical body: this file and the live view must land together, or the daily 07:10 UTC
-- parity check reports drift to ops.ci_findings (advisory, not ops.alerts -- no trading-halt risk).
-- SUPERSEDES the analytics.park_counterfactuals definition in bigquery/179_park_twr_fill_anchored.sql
-- (that file's header updated in the same commit, per bigquery/README.md supersede discipline).
-- bigquery/179's analytics.park_nav_daily definition is NOT touched and remains canonical.
-- Apply after bigquery/93_park_accounting.sql, bigquery/156_park_residual_sign_fix.sql and
-- bigquery/179_park_twr_fill_anchored.sql.
-- After applying, W5's next PARK SCORECARD should log a correction entry noting that every prior
-- entry compared an inception-anchored AI series against the same-window benchmarks, and that the
-- AI-vs-SGOV sign flips under the corrected anchor while AI-vs-rule-table widens against the AI.

-- ============================================================================
-- analytics.park_counterfactuals -- REDEFINED: adds ai_era_start_date + four AI-era-rebased index
-- columns. The five original columns (as_of_date, sgov_index, voo_index, rule_index, ai_index) are
-- UNCHANGED -- every CTE below the header is carried over verbatim from bigquery/179 so the existing
-- legs stay byte-identical and this file introduces no behaviour change to them whatsoever.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.park_counterfactuals` AS
WITH axis AS (
  SELECT as_of_date FROM `stock-trading-498512.analytics.park_nav_daily`
),
sgov_leg AS (
  SELECT a.as_of_date,
    COALESCE(
      sg.r_sgov,
      LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
        ORDER BY a.as_of_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
      0) AS r_sgov
  FROM axis a
  LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
),
sgov_cum AS (
  SELECT as_of_date, EXP(SUM(LN(1 + r_sgov)) OVER (ORDER BY as_of_date)) - 1 AS sgov_index
  FROM sgov_leg
),
voo_leg AS (
  SELECT a.as_of_date, v.r_voo,
    MIN(CASE WHEN v.r_voo IS NOT NULL THEN a.as_of_date END) OVER () AS first_voo_date
  FROM axis a
  LEFT JOIN `stock-trading-498512.analytics.voo_daily_return` v USING (as_of_date)
),
voo_cum AS (
  SELECT as_of_date,
    CASE WHEN first_voo_date IS NULL OR as_of_date < first_voo_date THEN NULL
         WHEN r_voo IS NULL THEN NULL
         ELSE EXP(SUM(LN(1 + GREATEST(COALESCE(r_voo, 0), -0.9999)))
                  OVER (ORDER BY as_of_date)) - 1
    END AS voo_index
  FROM voo_leg
),
rule_marks AS (
  SELECT ticker, mark_date, close, COALESCE(dividend, 0) AS dividend, 1 AS src_priority
  FROM `stock-trading-498512.state.daily_marks_curated`
  UNION ALL
  SELECT ticker, mark_date, close, COALESCE(dividend, 0) AS dividend, 2 AS src_priority
  FROM `stock-trading-498512.state.signal_marks_curated`
),
rule_marks_curated AS (
  SELECT ticker, mark_date, close, dividend
  FROM rule_marks
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY src_priority) = 1
),
rule_ticker_returns AS (
  SELECT ticker, mark_date AS as_of_date,
    SAFE_DIVIDE(
      close + dividend - LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date),
      LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date)) AS r
  FROM rule_marks_curated
),
-- The prior AXIS date (not calendar date) for each day -- so a Monday's return is governed by the
-- preceding Friday's classification, with no weekend hole and no assumption of contiguous dates.
axis_prev AS (
  SELECT as_of_date,
    LAG(as_of_date) OVER (ORDER BY as_of_date) AS prev_as_of_date
  FROM axis
),
rule_leg AS (
  -- state.park_rule_shadow's date column is `mark_date` (bigquery/92), not `as_of_date`.
  -- LAGGED join (bigquery/179's DEFECT 2 fix): day d-1's rule_vehicle governs day d's return,
  -- because park_rule_shadow classifies from day d-1's OWN closing signals and could not have been
  -- acted on before day d opened.
  SELECT ap.as_of_date,
    COALESCE(GREATEST(rtr.r, -0.9999), 0) AS r_rule
  FROM axis_prev ap
  LEFT JOIN `stock-trading-498512.state.park_rule_shadow` prs
    ON prs.mark_date = ap.prev_as_of_date
  LEFT JOIN rule_ticker_returns rtr
    ON rtr.ticker = prs.rule_vehicle AND rtr.as_of_date = ap.as_of_date
),
rule_cum AS (
  SELECT as_of_date, EXP(SUM(LN(1 + r_rule)) OVER (ORDER BY as_of_date)) - 1 AS rule_index
  FROM rule_leg
),
-- ===== AI-ERA ANCHOR (this file) ============================================================
-- The allocator's first BOUND, book-moving call. RECORD_ONLY rows (2026-07-19..07-22, 07-25) are
-- deliberately excluded: they moved nothing, so grading from them would re-import part of the
-- owner's manual VOO segment.
--
-- MEASURED status distribution over entry_type='park-allocation' (state.decision_log_current,
-- 2026-09-03) -- there are THREE values, not two, and the third is not what the D1 spec's wording
-- would lead you to expect:
--   BOUND        33 rows  2026-07-26 .. 09-02   decisions: DE-RISK, KEEP, "KEEP VOO", SWITCH
--   RECORD_ONLY   5 rows  2026-07-19 .. 07-25   decisions: DE-RISK, KEEP  (pre-v3 shadow stage)
--   NULL          3 rows  2026-08-03 .. 08-13   decisions: COVER, SWEEP
-- The NULL-status rows are execution-bookkeeping sub-records (a park cash SWEEP, a park cash COVER)
-- filed under the same entry_type, NOT D1 judgment calls, and they legitimately carry no status.
-- They are excluded correctly and for the right reason: `JSON_VALUE(...) = 'BOUND'` evaluates to
-- NULL, not TRUE, for them, so BigQuery's three-valued logic drops them from the WHERE clause with
-- no explicit IS NOT NULL guard needed. They also all postdate the anchor, so they could not move
-- MIN(entry_date) even if admitted. Stated explicitly because an earlier draft of this header
-- asserted RECORD_ONLY was "the only other value present in history" -- measured false, and a header
-- that misstates its own evidence is precisely the failure bigquery/93's mis-citation of
-- 03_twr_engine.sql already caused once in this very view family.
--
-- Reads state.decision_log_current, NOT the raw events.decision_log. This is a SEMANTIC read ("when
-- did the allocator first bind a call"), which is exactly the population bigquery/144 routes to the
-- final-effective view; the raw-table allowlist in scripts/check_superseded_by_discipline.py is
-- reserved for readers that need the PHYSICAL row set (state.freshness' dead-man's switch, the
-- embedding row-count parity checks, the VECTOR_SEARCH substrate) and this is not one of them. A raw
-- read here would also fail that checker, which maps events.decision_log -> state.decision_log_current
-- for every file not on its allowlist. Behaviour is identical on today's data -- both surfaces give
-- 2026-07-26, since no park-allocation row has ever been superseded (measured this session) -- so
-- this is a correctness/discipline choice, not a numbers change.
first_bound_call AS (
  SELECT MIN(entry_date) AS first_bound_call_date
  FROM `stock-trading-498512.state.decision_log_current`
  WHERE entry_type = 'park-allocation'
    AND JSON_VALUE(fields, '$.status') = 'BOUND'
),
-- The baseline close the AI era is measured from: the last axis date ON OR BEFORE the first BOUND
-- call. Expected 2026-07-24. NULL (and therefore an all-NULL rebased block) if no BOUND row exists.
--
-- THE `<=` IS LOAD-BEARING, and `<` would be subtly wrong. D1 decides AFTER the close and D2/D2a
-- executes at the NEXT open (the decide-after-close / execute-next-open cadence bigquery/179 lags the
-- rule shadow to match). So a call dated d is formed on d's CLOSE, and the first return the allocator
-- can possibly have influenced is d+1's. The anchor must therefore BE d, not d-1: anchoring at d-1
-- would pull day d's own return -- earned entirely under the PREVIOUS, owner-chosen vehicle, hours
-- before the allocator decided anything -- into the AI era, which is the exact contamination this
-- file exists to remove, just one day of it.
-- INERT ON TODAY'S DATA, and that is verified rather than assumed: the first BOUND call (2026-07-26)
-- fell on a SUNDAY, and park_nav_daily's axis jumps 07-24 -> 07-27, so `<` and `<=` both resolve to
-- 2026-07-24. The distinction only bites when a BOUND call lands on a trading day. Measured
-- counter-example from this same table -- the 2026-08-03 BOUND SWITCH (a Monday, fill 08-04):
-- `<` resolves to 2026-07-31 and `<=` to 2026-08-03, and ai_index moves +131.3bp on the FILL day
-- (08-04), not the decision day, so the `<` form would have imported a full pre-decision session.
-- Chosen over the alternative "last axis date before the first FILL" because that form is undefined
-- when the first BOUND call is a KEEP -- a KEEP produces no fill at all, yet the allocator is
-- genuinely responsible for the book from that call onward. Anchoring on the CALL date handles the
-- KEEP and SWITCH cases identically; anchoring on the fill does not.
ai_era_anchor AS (
  SELECT MAX(a.as_of_date) AS ai_era_start_date
  FROM axis a
  CROSS JOIN first_bound_call f
  WHERE f.first_bound_call_date IS NOT NULL
    AND a.as_of_date <= f.first_bound_call_date
),
-- The four index LEVELS at the anchor date. Exactly one row (or zero, if the anchor is NULL).
ai_era_base AS (
  SELECT
    an.ai_era_start_date,
    sc.sgov_index AS base_sgov_index,
    vc.voo_index  AS base_voo_index,
    rc.rule_index AS base_rule_index,
    pnd.twr_index AS base_ai_index
  FROM ai_era_anchor an
  LEFT JOIN sgov_cum sc ON sc.as_of_date = an.ai_era_start_date
  LEFT JOIN voo_cum  vc ON vc.as_of_date = an.ai_era_start_date
  LEFT JOIN rule_cum rc ON rc.as_of_date = an.ai_era_start_date
  LEFT JOIN `stock-trading-498512.analytics.park_nav_daily` pnd
    ON pnd.as_of_date = an.ai_era_start_date
  WHERE an.ai_era_start_date IS NOT NULL
)
SELECT
  a.as_of_date,
  sc.sgov_index,
  vc.voo_index,
  rc.rule_index,
  -- ai_index = analytics.park_nav_daily.twr_index joined by date, per the approved spec -- fill-
  -- anchored (bigquery/179's DEFECT 1 fix), so it is measured on the same footing as the benchmarks.
  pnd.twr_index AS ai_index,

  -- ===== AI-era attribution block (this file) ================================================
  -- ai_era_start_date is the SAME value on every row by construction (a single-row cross join) --
  -- it is a property of the view, not of the row, and is repeated so any single-row read is
  -- self-describing about which baseline it was rebased on.
  b.ai_era_start_date,
  CASE WHEN b.ai_era_start_date IS NULL OR a.as_of_date < b.ai_era_start_date THEN NULL
       ELSE SAFE_DIVIDE(1 + sc.sgov_index, 1 + b.base_sgov_index) - 1 END AS sgov_index_ai_era,
  CASE WHEN b.ai_era_start_date IS NULL OR a.as_of_date < b.ai_era_start_date THEN NULL
       ELSE SAFE_DIVIDE(1 + vc.voo_index,  1 + b.base_voo_index)  - 1 END AS voo_index_ai_era,
  CASE WHEN b.ai_era_start_date IS NULL OR a.as_of_date < b.ai_era_start_date THEN NULL
       ELSE SAFE_DIVIDE(1 + rc.rule_index, 1 + b.base_rule_index) - 1 END AS rule_index_ai_era,
  CASE WHEN b.ai_era_start_date IS NULL OR a.as_of_date < b.ai_era_start_date THEN NULL
       ELSE SAFE_DIVIDE(1 + pnd.twr_index, 1 + b.base_ai_index)  - 1 END AS ai_index_ai_era
FROM axis a
LEFT JOIN sgov_cum sc USING (as_of_date)
LEFT JOIN voo_cum  vc USING (as_of_date)
LEFT JOIN rule_cum rc USING (as_of_date)
LEFT JOIN `stock-trading-498512.analytics.park_nav_daily` pnd USING (as_of_date)
LEFT JOIN ai_era_base b ON TRUE
;
