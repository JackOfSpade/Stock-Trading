-- PAPER time-cull COMPLETENESS (SL3 2026-08-20 diligence sweep). Project: stock-trading-498512.
--
-- PROBLEM. `state.strategy_paper_readiness.stuck` — the ONLY mechanically-encoded PAPER cull signal in
-- the system, read by Claude_Task_Plan.md SL3 STEP 4's PAPER TIME-CULL — is defined as
--
--     paper_days >= 400 AND NOT trades_met
--
-- so it covers exactly ONE of PAPER's three candidate-side gate terms. `ready` requires
-- trades_met AND excess_met AND regime_met (plus the arsenal-state terms); `stuck` interrogates only
-- trades_met. A PAPER candidate that trades PLENTY but is persistently negative on excess-vs-SGOV, or
-- that never demonstrates positive excess in >= 2 regime cells, is therefore
--
--     ready = FALSE  (it cannot graduate)   AND   stuck = FALSE  (it cannot be culled)
--
-- **forever**, at any paper_days, with no alert and no dead-man's switch anywhere. It squats one of the
-- two `k_incubate` slots permanently. Two such candidates freeze the entire SISA ADD path — SL1 can
-- synthesize, SL2 can draft, and SL5 can never register a new SHADOW member again — and nothing in the
-- system says so. That is a silent hard-stop of an autonomous loop, which is a materially worse failure
-- than the one this flag was introduced to prevent.
--
-- This is the SAME defect class as the 2026-07-15 self-improvement audit's CONFIRMED GAP
-- `shadow-incubation-no-time-cull`, on the other axis. That audit found SHADOW's "window-exceeded" cull
-- was unquantified prose with no SQL-encoded check and closed it with bigquery/60_shadow_stuck_cull.sql.
-- bigquery/60 took bigquery/35's PAPER `stuck` as its model and — correctly — encoded ALL THREE of
-- SHADOW's dead-ends in one flag (its header says so in as many words: "Covers all three SHADOW
-- dead-ends"). The mirror was taken in the wrong direction: the MODEL was the incomplete one. PAPER's
-- remaining dead-ends were left to STEP 4's other trigger, "materially-negative paper excess / paper
-- drawdown-kill-equivalent" — which, exactly like SHADOW's "window-exceeded" before bigquery/60, is
-- unquantified prose with NO SQL object, NO threshold, NO view and NO flag behind it. Experiment_
-- Parameters.md:205 states the same trigger in the same unquantified form. Two documents describe this
-- cull; zero objects encode it. A session reading the readiness view sees `ready=FALSE, stuck=FALSE`
-- and correctly does nothing, which is why this can persist indefinitely without anyone noticing.
--
-- FIX. Widen `stuck` to cover every CANDIDATE-side gate term, mirroring bigquery/60's SHADOW flag
-- properly this time:
--
--     paper_days >= 400 AND NOT (trades_met AND excess_met AND regime_met)
--
-- and add `stuck_reason` naming which term(s) failed, so SL3 STEP 4's required `reject_reason` is read
-- off the view rather than invented as free text at the write site.
--
-- DELIBERATELY EXCLUDED FROM `stuck` — this is the load-bearing design distinction, not an oversight.
-- `rate_limit_clear`, `ceiling_ok`, `arsenal_ok` and `not_already_transitioned` are ARSENAL-STATE
-- conditions, not candidate defects. A candidate held back solely because the roster is at `n_max`,
-- because the 90-day adoption window is closed, or because the owner froze incubation via
-- `ops.arsenal_control` is HEALTHY and must never be culled for it — culling there would let a roster
-- ceiling silently destroy a qualified candidate, and would make the owner kill-switch destructive
-- instead of a freeze. bigquery/60's SHADOW `stuck` excludes `arsenal_ok` on exactly this reasoning;
-- this file keeps that boundary and states it explicitly so the next widening does not cross it.
--
-- MONOTONE WIDENING — no candidate that was stuck becomes unstuck. Old `stuck` implies new `stuck`
-- (NOT trades_met implies NOT (trades_met AND excess_met AND regime_met)), so this can only ever cull
-- MORE, never rescue something already culled. The fail-safe direction, matching SISA's default-REJECT
-- bias.
--
-- NO FALSE-TRIGGER ON THE FAIL-CLOSED `excess_met`. `excess_met` is FALSE when `trailing_n < 10`, i.e.
-- for a candidate with fewer than 10 paper days. `stuck` fires only at `paper_days >= 400`, where
-- `trailing_n` is necessarily 10, so the short-history branch of `excess_met` can never reach this flag.
--
-- INVARIANT: `stuck_reason IS NOT NULL` <=> `stuck` — the two are computed from the same predicate and
-- must never be read as independent signals.
--
-- ZERO MIGRATION BURDEN, CLOSED BEFORE FIRST FIRING. `analytics.strategy_incubation_perf` holds 0 rows
-- and `state.strategy_paper_readiness` returns 0 rows (verified read-only 2026-08-20); no strategy has
-- ever entered PAPER, so no live candidate's disposition changes today. Same posture as the
-- 2026-08-18/19 SL3 and SL5 pins: close it before it can ever fire, not after.
--
-- BLAST RADIUS: none outside SL3. A repo-wide grep (2026-08-20) finds `strategy_paper_readiness` read
-- by NO other view, procedure, dbt model or script — only by SL3's prose and by documentation prose —
-- and an INFORMATION_SCHEMA.VIEWS scan of `state` + `analytics` confirms no other view references it or
-- `paper_days`. No trading gate, kill flag or capital path reads `stuck`.
--
-- DUPLICATION ACKNOWLEDGED AND DELIBERATELY NOT REFACTORED HERE. bigquery/35's own `freq` CTE comment
-- warns that repeating a gate expression invites silent divergence, and this change adds a fourth copy
-- of the trades/excess/regime expressions. De-duplicating them into a CTE would restructure every
-- column in the view — and with the source table at 0 rows there is no way to differentially test that
-- the restructured columns still evaluate identically. Bundling an untestable refactor into a
-- correctness fix is precisely how the divergence that comment warns about gets introduced. The
-- expressions below are copied VERBATIM from the bigquery/35 originals so the diff is auditable
-- line-by-line; the de-duplication pass is its own change, for a day when the table has rows to test
-- against.
--
-- SUPERSEDES the state.strategy_paper_readiness VIEW definition in bigquery/35_strategy_arsenal.sql
-- (adds `stuck_reason`, widens `stuck`; EVERY other column byte-identical). Apply after
-- bigquery/35_strategy_arsenal.sql.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_paper_readiness` AS
WITH agg AS (
  SELECT strategy_code,
    COUNT(DISTINCT incubation_day) AS paper_days,
    MAX(sim_closed_trades) AS sim_closed_trades,
    ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest_excess,
    ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 10) AS trailing_excess,
    ARRAY_LENGTH(ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 10)) AS trailing_n
  FROM `stock-trading-498512.analytics.strategy_incubation_perf`
  WHERE phase = 'paper'
  GROUP BY strategy_code
),
positive_cells AS (
  SELECT strategy_code, COUNT(DISTINCT regime_cell) AS n_positive_cells
  FROM `stock-trading-498512.analytics.strategy_incubation_perf`
  WHERE phase = 'paper' AND excess >= 0 AND regime_cell IS NOT NULL
  GROUP BY strategy_code
),
gap_fill AS (
  SELECT DISTINCT p.strategy_code
  FROM `stock-trading-498512.analytics.strategy_incubation_perf` p
  JOIN `stock-trading-498512.state.arsenal_regime_coverage` c ON c.regime_cell = p.regime_cell
  WHERE p.phase = 'paper' AND p.excess >= 0 AND c.is_gap
),
freq AS (
  -- trades_threshold computed ONCE here (adversarial self-audit fix, rev 2026-07-11) — the same CASE
  -- expression used to be duplicated 4x below (trades_met_threshold, trades_met, stuck, ready), inviting
  -- silent divergence if only some copies were ever edited. Semantics-preserving; the frequency-scaled
  -- trade-count floor for a slow-cadence strategy (declared_annual_roundtrips < 10), floored at 3.
  SELECT candidate_code AS strategy_code, declared_annual_roundtrips,
    CASE WHEN declared_annual_roundtrips IS NULL OR declared_annual_roundtrips >= 10 THEN 10
         ELSE GREATEST(3, CAST(CEIL(declared_annual_roundtrips / 2) AS INT64))
    END AS trades_threshold
  FROM `stock-trading-498512.state.strategy_candidates`
  -- Defense-in-depth (2026-07-18 audit): candidate_code has no enforced uniqueness (NOT ENFORCED PK
  -- world) and four independent routines write NEW rows. A duplicate code here would fan out the
  -- LEFT JOIN below into duplicate readiness rows, corrupting the single `ready`/`stuck` boolean SL3
  -- keys transitions off. Newest row wins.
  QUALIFY ROW_NUMBER() OVER (PARTITION BY candidate_code ORDER BY created_ts DESC) = 1
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  COALESCE(a.paper_days, 0) AS paper_days,
  COALESCE(a.sim_closed_trades, 0) AS sim_closed_trades,
  a.latest_excess,
  fr.declared_annual_roundtrips,
  COALESCE(fr.trades_threshold, 10) AS trades_met_threshold,
  COALESCE(pc.n_positive_cells, 0) AS n_positive_cells,
  COALESCE(a.paper_days, 0) >= 60 AS days_met,
  COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10) AS trades_met,
  (COALESCE(a.trailing_n, 0) >= 10
   AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0) AS excess_met,
  (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL) AS regime_met,
  rails.adoption_window_open AS rate_limit_clear,
  NOT rails.at_ceiling AS ceiling_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':PAPER->PROBE')) AS not_already_transitioned,
  -- stuck (ITEM 9, 2026-07-11; WIDENED 2026-08-20 by this file to cover all three PAPER dead-ends,
  -- mirroring bigquery/60's SHADOW flag properly — see this file's header): paper_days has run long
  -- enough (>=400) that continuing to wait is no longer reasonable, and at least one CANDIDATE-side
  -- gate term is still unmet. Read by Claude_Task_Plan.md SL3 STEP 4's PAPER TIME-CULL, not itself a
  -- component of `ready` below (a stuck candidate is culled to REJECTED, not promoted). The three
  -- covered dead-ends: too few simulated closed round-trips (the original ITEM 9 case), persistently
  -- negative/NULL trailing excess-vs-SGOV, and regime coverage never demonstrated. Arsenal-state terms
  -- (rate_limit_clear / ceiling_ok / arsenal_ok / not_already_transitioned) are DELIBERATELY excluded —
  -- a candidate blocked only by a roster ceiling, a closed adoption window or the owner's freeze is
  -- healthy and must not be culled for it.
  (COALESCE(a.paper_days, 0) >= 400
   AND NOT (
     COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)
     AND (COALESCE(a.trailing_n, 0) >= 10
          AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0)
     AND (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL)
   )) AS stuck,
  -- stuck_reason (NEW 2026-08-20): the '+'-joined list of failed candidate-side terms, so SL3 STEP 4's
  -- required `reject_reason` is READ from the view rather than composed as free text at the write site.
  -- NULL exactly when `stuck` is FALSE — `stuck_reason IS NOT NULL` <=> `stuck`, always; never read the
  -- two as independent signals.
  CASE WHEN COALESCE(a.paper_days, 0) < 400 THEN NULL
       ELSE NULLIF(ARRAY_TO_STRING(ARRAY_CONCAT(
              IF(NOT (COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)),
                 ['trades'], ARRAY<STRING>[]),
              IF(NOT (COALESCE(a.trailing_n, 0) >= 10
                      AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0),
                 ['excess'], ARRAY<STRING>[]),
              IF(NOT (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL),
                 ['regime'], ARRAY<STRING>[])
            ), '+'), '')
  END AS stuck_reason,
  (COALESCE(a.paper_days, 0) >= 60
   AND COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)
   AND (COALESCE(a.trailing_n, 0) >= 10
        AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0)
   AND (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL)
   AND rails.adoption_window_open
   AND NOT rails.at_ceiling
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':PAPER->PROBE'))) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN agg a USING (strategy_code)
LEFT JOIN positive_cells pc USING (strategy_code)
LEFT JOIN gap_fill gf USING (strategy_code)
LEFT JOIN freq fr USING (strategy_code)
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'PAPER';
