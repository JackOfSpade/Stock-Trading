-- Live-SQL-parity drift self-heal latch substrate (live-sql-parity self-heal audit 2026-07-16,
-- RES-3; issue #10). Project: stock-trading-498512. Apply after 47_trading_enabled_resync.sql.
--
-- PROBLEM: live-sql-parity.yml (.github/workflows/live-sql-parity.yml) detects the exact
-- 2026-07-11 state.trading_enabled-clobber drift class daily, but its only output before this
-- change was a GitHub issue no routine reads -- issue #10 (opened 2026-07-16T09:34Z) sat
-- unconsumed while the run itself concluded 'success'. Re-applying the listed object(s)' current
-- repo definition via the BigQuery MCP is something any in-band routine session can already do --
-- the missing piece was a durable findings hand-off plus a latch so a self-heal loop can tell
-- "just detected" apart from "already healed and still flagged" (comparator bug or a competing
-- live writer) without looping forever or re-applying the same object every single day.
--
-- DELIVERY PATH -- REWIRED TWICE, current since 2026-07-18 (header updated 2026-07-18; the original
-- version of this text described a repo-file hand-off that no longer exists):
--   * v1 (2026-07-16): the checker's --json-out written to a git-tracked file
--     (ops/monitoring/live_sql_parity_findings.json) that D3 read from the repo. RETIRED 2026-07-17
--     (OWNER_ACTIONS SS-I option 3) when the gh-ci-runner@ dataEditor grant on ops.ci_findings went
--     live -- two delivery paths for one signal was one too many.
--   * v2 (current): live-sql-parity.yml writes ONE ops.ci_findings row PER DRIFTED OBJECT
--     (workflow='live-sql-parity', finding_key='<dataset>.<name>', detail names the canonical
--     source file), auto-resolves keys that stop drifting, and keeps the legacy aggregate
--     finding_key='live_sql_parity' ONLY for the zero-verification fail-closed case.
--     state.ci_findings_open (canonical: bigquery/86_ci_findings_first_detected.sql) adds the
--     episode-aware per-object first_detected this loop's one-day lag keys on.
--
-- ops.parity_selfheal_log is the latch: an append-only idempotency/outcome log. Claude_Task_Plan.md's
-- D3 "CI-FINDINGS ADJUDICATION & LIVE-SQL-PARITY SELF-HEAL" step:
--   1. reads state.ci_findings_open for workflow='live-sql-parity' per-object rows whose
--      first_detected predates today (a >=1-day lag so a same-day out-of-band hotfix has time to
--      land its own repo commit first, the bigquery/47 precedent, before being reverted). NOTE the
--      lag interacts with the workflow's auto-resolve to make the loop REAL-DRIFT-ONLY by
--      construction: a transient/phantom finding is auto-resolved by the next clean daily run
--      BEFORE it can ever age past the lag, so only drift that persists across >=2 daily runs --
--      i.e. drift that is really there -- ever reaches a re-apply.
--   2. LATCH CHECKs this table (heal_date within the last 7 days) for that (dataset, object) --
--      a hit means a prior heal did NOT converge (comparator bug / competing writer), so D3 raises
--      live_sql_parity_selfheal_ineffective and does NOT re-apply;
--   3. otherwise adjudicates live-vs-repo (stale live -> re-apply, bounded to 10 objects/session,
--      oldest first_detected first, and INSERTs an 'applied'/'failed' row here; legit un-committed
--      live hotfix -> commit it repo-side instead, the bigquery/47 precedent; already-matching
--      (phantom/healed out-of-band) -> log-only, no apply).
--
-- outcome: 'applied' | 'failed'. first_detected is carried through from state.ci_findings_open so
-- the log preserves how long each drift had been open before it was healed. healed_at is the
-- wall-clock INSERT time (distinct from heal_date, the logical trading-day key other latch tables
-- in this repo use, e.g. ops.monitor_promotion_log / ops.catchup_refire_log).
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.parity_selfheal_log` (
  heal_date      DATE NOT NULL,
  dataset        STRING NOT NULL,
  object         STRING NOT NULL,
  source_file    STRING,
  first_detected DATE,
  outcome        STRING NOT NULL,
  healed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
OPTIONS(description='Append-only live-SQL-parity self-heal latch/idempotency log (live-sql-parity self-heal audit 2026-07-16, RES-3, issue #10; delivery path rewired to the ops.ci_findings / state.ci_findings_open bridge 2026-07-17/18 -- see file header). One row per D3 re-apply attempt for a (dataset, object) drift surfaced by state.ci_findings_open (workflow=live-sql-parity, per-object finding_key). outcome=applied|failed. D3 latch-checks the last 7 days of heal_date before re-applying; a re-flagged object already in this window within 7 days means the heal did not converge and is NOT re-applied again (comparator/competing-writer investigation instead).');
