-- Arsenal correctness fix H3 (Phase-C live-apply follow-ups, 2026-07-17). Project: stock-trading-498512.
--
-- SUPERSEDES state.strategy_retirement_candidacy — the live definition until now was
-- bigquery/39_beta_adjusted_alpha.sql (which itself superseded bigquery/35_strategy_arsenal.sql's original,
-- folding in a beta-adjusted suppression). This file is applied AFTER 39 and CREATE OR REPLACEs the view
-- once more; at runtime THIS definition wins. 35's and 39's copies are left unmodified (each carries a
-- "SUPERSEDED ... by bigquery/81" pointer comment) per the repo's supersede discipline — a superseded
-- object's original CREATE is never edited in place. Consolidating the view here also RETIRES the no-CI
-- hand-sync hazard the 35<->39 pair warned about: there is now exactly one authoritative definition.
--
-- APPLY ORDER: after 35 (state.strategy_roster, state.arsenal_rails, state.arsenal_enabled,
-- ops.roster_change_log) AND after 39 (analytics.strategy_beta_latest). On a full DR rebuild the sequence
-- is 01..35, then 22/26, ..., then 39, then 81. Idempotent (CREATE OR REPLACE); safe to re-run.
--
-- WHY (finding H3, parts 1-2):
--   (1) ZERO-DEPLOYMENT ADOPTED strategies were INVISIBLE to the retirement/edge loop. The prior view
--       `JOIN latest USING (strategy_code)` where `latest` is the newest perf.strategy_daily row per
--       strategy. Only strategies that have ever been deployed (B and D today) have perf rows, so the
--       INNER JOIN silently dropped the three ADOPTED-but-never-deployed strategies (A, C, E) — they
--       appeared in NO row of state.strategy_retirement_candidacy at all. SL4 reads this view for its
--       qualitative-evidence intake (redundancy / dominated-by-newcomer / never-deployed capital review),
--       so those three were unreachable by the whole discretionary-retirement path. This file makes it a
--       state.strategy_roster LEFT JOIN latest with NULL-safe COALESCE defaults, so EVERY ADOPTED strategy
--       always has a row: floor_ok / arsenal_ok / cooldown_clear populated, edge_decay_signal = FALSE when
--       unmeasurable, and a new `never_deployed_days` column (days since adopted_date for a strategy with
--       zero perf rows; NULL once it has been deployed) giving SL4 the objective "adopted capital never
--       put to work" signal it previously had no surface for. (Verified read-only 2026-07-17: the old live
--       view returned 2 rows {B,D}; this definition returns 5 {A,B,C,D,E}, A/C/E with
--       never_deployed_days=85 and every boolean at its safe default.)
--   (2) SINGLE-DAY edge_decay defect. edge_decay_signal fired on a SINGLE latest-day row
--       (`latest.excess_vs_sgov < 0`) — the identical single-lucky/unlucky-day defect that was already
--       fixed at the PAPER->PROBE gate (state.strategy_paper_readiness.excess_met, ITEM 8) but left here.
--       It now requires the latest-row condition AND a SUSTAINED count: at least 42 of the trailing 63
--       trading days negative (COUNTIF(excess_vs_sgov < 0) >= 42). A NULL excess day counts as NOT negative
--       (COUNTIF's predicate is false on NULL) and a strategy with fewer than 63 rows simply has a smaller
--       count — both fail-conservative TOWARD KEEP, matching the default-KEEP doctrine.
--
-- PRESERVED VERBATIM from bigquery/39: the beta-adjusted suppression AND-term
-- `(NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)` on edge_decay_signal and
-- candidacy_fired, plus the alpha/min_n columns. This file only ADDS the LEFT JOIN, the sustained-count
-- term, and never_deployed_days — it never fires a candidacy the beta-adjusted bigquery/39 view would not
-- already have fired (it is strictly harder to fire: an extra AND-term), and it stays ADDITIVE-ONLY over
-- the unchanged SGOV excess-real-return success metric.
--
-- BEHAVIOURALLY INERT TODAY: B and D have deployed_days=57 (< the 252 gate), so edge_decay_signal /
-- candidacy_fired are FALSE for them under BOTH the old and new definitions; A/C/E newly appear with all
-- booleans FALSE and never_deployed_days populated. No candidacy fires for anyone today (verified
-- read-only 2026-07-17).
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_retirement_candidacy` AS
WITH latest AS (
  -- newest deployed-perf row per strategy; has_perf_row is the LEFT-JOIN sentinel (survives USING, which
  -- only coalesces the join key) that distinguishes "never deployed" from "deployed with a NULL metric".
  SELECT strategy AS strategy_code, excess_vs_sgov, deployed_days, TRUE AS has_perf_row
  FROM `stock-trading-498512.perf.strategy_daily`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
sustained AS (
  -- trailing 63 trading days per strategy; count of negative-excess days. NULL excess -> predicate FALSE
  -- (not counted); < 63 rows -> a smaller count. Both fail-conservative toward KEEP (H3 part 2).
  SELECT strategy AS strategy_code, COUNTIF(excess_vs_sgov < 0) AS neg_days_63
  FROM (
    SELECT strategy, excess_vs_sgov
    FROM `stock-trading-498512.perf.strategy_daily`
    QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) <= 63
  )
  GROUP BY strategy
),
beta AS (
  -- fail-closed by construction: a strategy absent here (zero deployed days) has no row, and the
  -- COALESCE(min_n_met, FALSE) below treats a missing row as "beta not measurable" (verbatim from 39).
  SELECT strategy AS strategy_code, alpha_annualized, min_n_met
  FROM `stock-trading-498512.analytics.strategy_beta_latest`
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
-- defense-in-depth (rev 2026-07-10b, code-review finding #3): SL4 is blocked entirely at the shared
-- ops.sp_assert_arsenal_enabled gate when incubation_frozen=TRUE, but this view ALSO folds it in here,
-- matching its 3 siblings, so it stays internally safe even if ever queried without that gate first.
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  l.excess_vs_sgov,
  l.deployed_days,
  COALESCE(s.neg_days_63, 0) AS neg_days_63,          -- trailing-63d negative-excess day count (H3 part 2)
  -- days since adopted_date for a strategy that has ZERO perf rows (never deployed live capital); NULL once
  -- it has been deployed. The objective "adopted but idle" signal SL4 previously had no surface for (H3 part 1).
  IF(COALESCE(l.has_perf_row, FALSE), NULL,
     DATE_DIFF(CURRENT_DATE('America/Denver'), r.adopted_date, DAY)) AS never_deployed_days,
  b.alpha_annualized,
  COALESCE(b.min_n_met, FALSE) AS beta_min_n_met,
  -- edge_decay_signal: latest-row condition AND sustained (>=42/63) negativity AND the beta-adjusted
  -- suppression (preserved from 39). COALESCE defaults make it FALSE (never NULL) when unmeasurable.
  (COALESCE(l.deployed_days, 0) >= 252
   AND COALESCE(l.excess_vs_sgov, 0) < 0
   AND COALESCE(s.neg_days_63, 0) >= 42
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS edge_decay_signal,
  rails.active_count,
  rails.active_count > rails.n_min AS floor_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.strategy_code = r.strategy_code
                AND cl.to_state = 'RETIREMENT_PROPOSED'
                AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)) AS cooldown_clear,
  (COALESCE(l.deployed_days, 0) >= 252
   AND COALESCE(l.excess_vs_sgov, 0) < 0
   AND COALESCE(s.neg_days_63, 0) >= 42
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)
   AND rails.active_count > rails.n_min
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.strategy_code = r.strategy_code
                     AND cl.to_state = 'RETIREMENT_PROPOSED'
                     AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY))) AS candidacy_fired
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN latest l USING (strategy_code)
LEFT JOIN sustained s USING (strategy_code)
LEFT JOIN beta b USING (strategy_code)
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'ADOPTED';
