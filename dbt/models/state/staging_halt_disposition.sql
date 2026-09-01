-- Parallel-run dbt port of bigquery/206_staging_halt_prerefresh_disposition.sql:
-- state.staging_halt_disposition — canonical source is that file until owner cutover.
--
-- READ-ONLY CLASSIFICATION of a halt that state.trading_enabled has ALREADY decided. It adds no
-- gate and loosens none: `gate_alert_action = 'defer_to_craft_site'` still means staging is BLOCKED;
-- it only tells a TRADING-ENABLE GATE step to withhold the human-latching `trading_halted` critical
-- until a craft site is actually declined.
--
-- The condition it names is structural: state.trading_day_today.last_trading_day equals TODAY from
-- DENVER MIDNIGHT on a trading day, while events.daily_marks / perf.strategy_daily for today are
-- written by D2a at 22:40 UTC — so marks_fresh/engine_fresh are FALSE for ~16.5h every trading day.
-- D2/D3/AR_orc run after D2a and never see it; M4 (~15:22 UTC) and Q4 (20:00 UTC) always do.
--
-- The five AND-terms are reused from canonical views rather than re-derived, so bigquery/176's
-- eight-term chain (it superseded bigquery/107's gate views on 2026-08-17) is never transcribed twice. `NOT snapshot_stale` is stated separately because
-- state.trading_enabled_mechanical omits that term as well as the freshness pair. Every COALESCE
-- resolves toward "NOT an artifact", so any NULL fails CLOSED to `raise_critical`. See bigquery/206's
-- header for the full derivation and for why re-classification (not suppression) keeps the
-- dead-man's teeth: marks_current/engine_current are SCHEDULE-derived, so a dead D2a still trips it.

WITH
-- EXPLICIT range-variable aliases (`AS v`) are REQUIRED, not style -- see bigquery/206's note at the
-- same lines. ref() compiles to `proj`.`state`.`trading_enabled`, whose implicit range variable is
-- named `trading_enabled` and SHADOWS the view's same-named BOOL column, so a bare
-- `SELECT trading_enabled` yields the whole ROW STRUCT and the predicate below fails to compile.
te AS (SELECT v.trading_enabled, v.halt_reason FROM {{ ref('trading_enabled') }} AS v),
tm AS (SELECT v.trading_enabled AS mechanical_enabled FROM {{ ref('trading_enabled_mechanical') }} AS v),
f  AS (SELECT marks_fresh, engine_fresh, marks_current, engine_current,
              last_mark_date, engine_through, marks_due_through, last_trading_day
       FROM {{ ref('freshness') }}),
dd AS (SELECT snapshot_stale FROM {{ ref('book_drawdown_watch') }}),
d  AS (
  SELECT
    te.trading_enabled,
    te.halt_reason,
    tm.mechanical_enabled,
    f.marks_fresh, f.engine_fresh, f.marks_current, f.engine_current,
    f.last_mark_date, f.engine_through, f.marks_due_through, f.last_trading_day,
    COALESCE(dd.snapshot_stale, TRUE) AS snapshot_stale,
    (NOT COALESCE(te.trading_enabled, TRUE)
     AND te.halt_reason = 'state.freshness marks_fresh/engine_fresh not both TRUE'
     AND COALESCE(tm.mechanical_enabled, FALSE)
     AND NOT COALESCE(dd.snapshot_stale, TRUE)
     AND COALESCE(f.marks_current, FALSE)
     AND COALESCE(f.engine_current, FALSE)) AS halt_is_prerefresh_artifact
  FROM te, tm, f, dd
)
SELECT
  d.trading_enabled,
  d.halt_reason,
  d.halt_is_prerefresh_artifact,
  CASE
    WHEN COALESCE(d.trading_enabled, FALSE) THEN 'none'
    WHEN d.halt_is_prerefresh_artifact THEN 'defer_to_craft_site'
    ELSE 'raise_critical'
  END AS gate_alert_action,
  CASE
    WHEN COALESCE(d.trading_enabled, FALSE) THEN NULL
    WHEN d.halt_is_prerefresh_artifact THEN FORMAT(
      'PRE-REFRESH ARTIFACT, not a fault: marks/engine cover %s = marks_due_through, the last '
      || 'trading day a scheduled D2a slot has had the opportunity to ingest; they do not yet cover '
      || 'last_trading_day %s because that session has not closed and D2a (40 22 * * 0,1,2,3,4) has '
      || 'not run. Every other gate term is green. Staging stays blocked; no critical raised unless a '
      || 'craft site is actually declined. See bigquery/206.',
      CAST(d.marks_due_through AS STRING), CAST(d.last_trading_day AS STRING))
    ELSE d.halt_reason
  END AS disposition_note,
  d.mechanical_enabled,
  d.marks_fresh, d.engine_fresh, d.marks_current, d.engine_current, d.snapshot_stale,
  d.last_mark_date, d.engine_through, d.marks_due_through, d.last_trading_day,
  CURRENT_TIMESTAMP() AS checked_at
FROM d
