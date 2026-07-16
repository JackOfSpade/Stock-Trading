-- Live-SQL-parity drift self-heal latch substrate (live-sql-parity self-heal audit 2026-07-16,
-- RES-3; issue #10). Project: stock-trading-498512. Apply after 47_trading_enabled_resync.sql.
--
-- PROBLEM: live-sql-parity.yml (.github/workflows/live-sql-parity.yml) detects the exact
-- 2026-07-11 state.trading_enabled-clobber drift class daily, but its only output before this
-- change was a GitHub issue no routine reads -- issue #10 (opened 2026-07-16T09:34Z) sat
-- unconsumed while the run itself concluded 'success'. Re-applying the listed object(s)' current
-- repo definition via the BigQuery MCP is something any in-band routine session can already do --
-- the missing piece was a durable, git-tracked findings hand-off (see
-- scripts/check_live_sql_parity.py's new --json-out flag and
-- ops/monitoring/live_sql_parity_findings.json) plus a latch so a self-heal loop can tell "just
-- detected" apart from "already healed and still flagged" (comparator bug or a competing live
-- writer) without looping forever or re-applying the same object every single day.
--
-- ops.parity_selfheal_log is that latch: an append-only idempotency/outcome log. Claude_Task_Plan.md's
-- D3 LIVE-SQL-PARITY SELF-HEAL step:
--   1. reads ops/monitoring/live_sql_parity_findings.json (repo, main) for candidates whose
--      first_detected predates today (a >=1-day lag so a same-day out-of-band hotfix has time to
--      land its own repo commit first, the bigquery/47 precedent, before being reverted);
--   2. LATCH CHECKs this table (heal_date within the last 7 days) for that (dataset, object) --
--      a hit means a prior heal did NOT converge (comparator bug / competing writer), so D3 raises
--      live_sql_parity_selfheal_ineffective and does NOT re-apply;
--   3. otherwise re-applies the repo's bigquery/*.sql definition via the BigQuery MCP (bounded to
--      10 objects/session, oldest first_detected first) and INSERTs an 'applied' (or 'failed') row
--      here.
--
-- outcome: 'applied' | 'failed'. first_detected is carried through from the findings JSON so the
-- log preserves how long each drift had been open before it was healed. healed_at is the wall-clock
-- INSERT time (distinct from heal_date, the logical trading-day key other latch tables in this repo
-- use, e.g. ops.monitor_promotion_log / ops.catchup_refire_log).
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.parity_selfheal_log` (
  heal_date      DATE NOT NULL,
  dataset        STRING NOT NULL,
  object         STRING NOT NULL,
  source_file    STRING,
  first_detected DATE,
  outcome        STRING NOT NULL,
  healed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
OPTIONS(description='Append-only live-SQL-parity self-heal latch/idempotency log (live-sql-parity self-heal audit 2026-07-16, RES-3, issue #10). One row per D3 re-apply attempt for a (dataset, object) drift found in ops/monitoring/live_sql_parity_findings.json. outcome=applied|failed. D3 latch-checks the last 7 days of heal_date before re-applying; a re-flagged object already in this window within 7 days means the heal did not converge and is NOT re-applied again (comparator/competing-writer investigation instead).');
