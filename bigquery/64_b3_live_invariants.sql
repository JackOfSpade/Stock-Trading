-- Live B3 invariant: trading_enabled formula self-check (self-improvement audit 2026-07-15 —
-- CONFIRMED GAP dbt-b3-coverage-advisory-only). Project: stock-trading-498512. Apply after
-- 47_trading_enabled_resync.sql.
--
-- WHY: dbt/tests/assert_trading_enabled_formula.sql already recomputes state.trading_enabled's
-- formula independently and fails if the dbt MIRROR disagrees — but that dbt test is advisory-only
-- (ci.yml's `dbt test` step never blocks auto-merge) and only runs in CI, never against the LIVE view
-- day to day. It exists specifically because of the 2026-07-11 incident (bigquery/47_trading_enabled_
-- resync.sql): an in-place re-apply of 23_trading_control.sql silently clobbered 34's trading_halted
-- exclusion, and NOTHING caught it live for days. Porting the identical formula to a live,
-- daily-checked view closes exactly that gap — this is the single highest-value B3 invariant (the
-- exact incident class this whole audit repeatedly references), scoped narrowly rather than porting
-- all 5 dbt B3 classes at once.
--
-- POSTURE: staged-rollout WARNING (record-only, wired into cadence_check.sql below) — a formula
-- mismatch is a real bug worth fixing immediately regardless of alarm tier, but this is a NEW,
-- unproven monitor; promote to critical+RAISE via the existing D3 MONITOR-PROMOTION SELF-FLIP
-- mechanism (bigquery/45_monitor_promotion.sql) once a clean baseline is confirmed, same as
-- ddl_drift/restore_stale/append_only_integrity.
--
-- SUPERSEDED LIVE by bigquery/78_book_drawdown_rebase_and_staleness_gate.sql (2026-07-17: breach_hard
-- drawdown term + trading_halted/staleness blocking-criticals exclusion), and 78 was in turn
-- superseded by bigquery/97_halt_echo_dependency_gate.sql (2026-07-19: halt-echo missing_dependency
-- exclusion) — 97 is the CURRENT single source of truth for this view. Re-applying the CREATE OR
-- REPLACE VIEW below live in isolation would REGRESS both of those changes and false-fire drift
-- against the current state.trading_enabled. Kept here, unmodified, for DR-rebuild apply-in-order
-- reference only. DO NOT re-apply this CREATE OR REPLACE VIEW statement live in isolation.
-- (Retroactive marker added 2026-07-19; the matching grandfathered BASELINE entry was removed from
-- scripts/check_superseded_markers.py at the same time.)
CREATE OR REPLACE VIEW `stock-trading-498512.state.b3_trading_enabled_check` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
f AS (SELECT marks_fresh, engine_fresh FROM `stock-trading-498512.state.freshness`),
eh AS (SELECT is_healthy FROM `stock-trading-498512.state.embedding_health`),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category != 'trading_halted') AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM `stock-trading-498512.state.position_reconciliation`),
dd AS (SELECT drawdown_breach, snapshot_stale FROM `stock-trading-498512.state.book_drawdown_watch`),
expected AS (
  SELECT
    NOT COALESCE(ctrl.latest.halt_all, FALSE)
    AND COALESCE(f.marks_fresh, FALSE)
    AND COALESCE(f.engine_fresh, FALSE)
    AND COALESCE(eh.is_healthy, FALSE)
    AND al.blocking_criticals = 0
    AND NOT pr.drift
    AND NOT COALESCE(dd.drawdown_breach, FALSE)
    AND NOT COALESCE(dd.snapshot_stale, FALSE) AS v
  FROM ctrl, f, eh, al, pr, dd
)
SELECT
  t.trading_enabled AS live_value,
  e.v AS expected_value,
  (t.trading_enabled IS DISTINCT FROM e.v) AS drift,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.trading_enabled` t, expected e;
