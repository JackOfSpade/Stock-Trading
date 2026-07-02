-- User display preferences (2026-07 report-system redesign). Project: stock-trading-498512.
--
-- WHY. The system has two timezone planes (see ops/RUNBOOK.md "Report timezone redesign"):
--   * OPERATING plane — trading-day semantics, cadence deadlines, dead-man's-switch timing — stays
--     PINNED to America/Denver always. Re-anchoring this to wherever the operator happens to be would
--     reintroduce the 2026-05-27 class of bug (a UTC-vs-Denver date mixup deleted a same-day
--     order-confirmation event). Nothing in this file changes that plane.
--   * DISPLAY plane — purely how a timestamp is RENDERED to the human in an email/alert/dashboard —
--     should follow wherever the operator actually is. The Google Calendar connector already exposes
--     this for free: the primary calendar's `timeZone` field tracks the phone's current timezone (if
--     "update primary time zone" is enabled) or the operator's last manual change. D3 (Calendar
--     Hygiene) already calls the Calendar connector daily, so it is the natural, zero-new-cost writer.
--
-- ops.user_prefs is a tiny append-only log (mirrors the ops.heartbeat / ops.backup_log pattern
-- elsewhere in this codebase) so a bad detection is just a new row, never a destructive UPDATE.
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.user_prefs` (
  pref_key STRING NOT NULL,
  pref_value STRING NOT NULL,
  updated_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  source STRING
) PARTITION BY DATE(updated_ts)
OPTIONS(description='Append-only display-preference log (currently: display_tz). D3 writes a new row only when the Calendar connector primary-calendar timezone differs from the current state.user_tz value. DISPLAY-ONLY — never read by trading-day/cadence logic.');

-- Latest value per pref_key, with a hard fallback to America/Denver so every consumer works even
-- before D3 has ever written a row (self-bootstrapping, same pattern as state.automation_heartbeat).
CREATE OR REPLACE VIEW `stock-trading-498512.state.user_tz` AS
SELECT
  COALESCE(
    (SELECT pref_value FROM `stock-trading-498512.ops.user_prefs`
     WHERE pref_key = 'display_tz'
     ORDER BY updated_ts DESC LIMIT 1),
    'America/Denver'
  ) AS tz,
  (SELECT MAX(updated_ts) FROM `stock-trading-498512.ops.user_prefs` WHERE pref_key = 'display_tz') AS detected_ts;
