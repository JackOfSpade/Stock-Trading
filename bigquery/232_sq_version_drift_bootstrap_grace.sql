-- ============================================================================
-- 232 — SCHEDULED-QUERY VERSION DRIFT: give the `drift` term the same cadence-aware bootstrap
--       grace its two sibling terms already have, so a version bump on a MONTHLY scheduled query
--       stops raising a warning every night for the ~3 weeks before that query next runs.
--
-- Project: stock-trading-498512. Apply after 231_run_outcome_notification_fire_drill.sql.
-- SUPERSEDES bigquery/63_scheduled_query_version_registry.sql's definition of
-- state.scheduled_query_version_drift, and ONLY that view. bigquery/63 remains the source of truth
-- for the state.expected_scheduled_query_versions TABLE and its MERGE seed rows, both untouched
-- here. No procedure body, no SQ_VERSION, and no ops.alert_policy row changes, so this carries none
-- of the partial-apply risk bigquery/63's registry note documents at length -- there is no paired
-- registry row to land with it.
--
-- ===== WHAT WENT WRONG, MEASURED 2026-09-09 =====
--
-- Live alert e0cb2898-e22d-4218-9d8b-19a0704c1fd9, `scheduled_query_version_drift`, warning,
-- emailed: "fire_drill_alert_lifecycle (expected v4, reported v3)".
--
-- Nothing is drifted. Verified live, all three legs:
--   * the REGISTRY says v4      -- state.expected_scheduled_query_versions, updated_ts 2026-09-08 16:10:20
--   * the LIVE PROCEDURE says v4 -- ops.INFORMATION_SCHEMA.ROUTINES DDL for
--     ops.sp_sq_fire_drill_alert_lifecycle opens
--     `CALL ops.sp_beat_heartbeat('sq:fire_drill_alert_lifecycle', 'v4', ...)`
--   * the HEARTBEAT says v3      -- ops.heartbeat, beat_ts 2026-09-01 06:20:03
-- The heartbeat is stale, not wrong: bigquery/231 bumped this procedure v3 -> v4 on 2026-09-08, and
-- the procedure is MONTHLY (expected_interval_hours = 744, fires 06:20 UTC on the 1st). It has had
-- no opportunity to run since the bump and will not until 2026-10-01.
--
-- THE VIEW ALREADY KNOWS THIS SHAPE -- FOR ITS OTHER TWO TERMS ONLY. `stale_beat` scales its grace
-- by cadence (interval x 1.5). `never_beat_overdue` was FIXED for precisely this bug on 2026-07-25
-- and its own inline comment says so: a flat 7-day floor "fires every night for ~24 days after
-- registration despite the query never having had a chance to run yet ... Now
-- GREATEST(7 days, interval_hours * 1.5) ... a monthly query gets ~46.5 days, comfortably past its
-- next real firing before ever alarming." `drift` -- the third term, in the same SELECT -- never got
-- the same treatment and compares versions with no timing guard whatsoever. This is the
-- paired-mechanism-drift shape: one branch of a mechanism gets hardened, its sibling does not.
--
-- WHY IT WENT UNNOTICED FOR SO LONG. Every version bump before this one landed on a DAILY query, and
-- a daily query's stale beat clears within hours. bigquery/63's own v22 note reasons through exactly
-- this phenomenon for cadence_check -- "that is not drift, it is staleness: the procedure has not RUN
-- since the apply, so it has not had a chance to beat v22 yet, and will on its next 05:15 UTC pass"
-- -- and it was right: cadence_check beat v22 at 2026-09-09 05:15:07, ~15h later. What that note did
-- not carry is that the SAME 2026-09-08 apply bumped a MONTHLY query too, where "its next pass" is 23
-- days away. The reasoning was correct and cadence-blind at the same time.
--
-- WHY THE #14 AUTO-AGE ALLOWLIST DOES NOT COVER IT. `scheduled_query_version_drift` has been on that
-- list since bigquery/111 (v9) precisely because it is "self-healing". Auto-age clears the row after
-- 7 days -- but the underlying condition is still true, so the nightly cadence_check re-raises it,
-- and the cycle repeats until 2026-10-01. Auto-age converts a permanently-open row into a recurring
-- email; it does not stop the emails. bigquery/111's own words, "It heals on its own within one
-- cycle", are true for a 24h cycle and false for a 744h one.
--
-- ===== THE FIX =====
--
-- ONE new conjunct on the `drift` term: `lb.last_beat_ts >= COALESCE(e.updated_ts, ...)`. In words:
-- do not compare versions until the query has actually beaten at least once SINCE the registry was
-- bumped. Before that first post-bump beat, the reported version is stale by construction and
-- carries no information about whether the live body matches the repo.
--
-- THIS COSTS ZERO DETECTION POWER, MEASURED rather than argued. Across all 12 registered queries on
-- 2026-09-09, exactly one has `drift = TRUE` (fire_drill_alert_lifecycle, the bootstrap case) and the
-- other ELEVEN all have last_beat_ts >= updated_ts, so the new conjunct is already satisfied for
-- every one of them and changes nothing about their evaluation. A genuinely drifted query -- one that
-- HAS run since the bump and still reports the old version -- beats after updated_ts and so still
-- trips the term on its very next run. That is the irreversible case prior triage warned about
-- (registry caught up to a bumped live proc, never self-heals) and it stays fully covered.
--
-- WHY NOT INSTEAD scale a grace window off expected_interval_hours, as the sibling terms do? Because
-- a beat-based predicate is strictly sharper here. `never_beat_overdue` has to use a time window --
-- it is reasoning about a query that has NEVER beaten, so there is no beat to compare against. This
-- term has one. Using `interval x 1.5` here would suppress until ~2026-10-25 and would therefore stay
-- blind for 3 weeks AFTER the 2026-10-01 run that actually settles the question; keying on the beat
-- re-arms the check the instant real evidence arrives.
--
-- THE OTHER MONTHLY QUERIES ARE UNAFFECTED TODAY and this is why the bug is only now live:
-- fire_drill_order_guard and restore_drill are both interval 744 but both still carry their original
-- 2026-07-17 registration with no bump since, so both already satisfy last_beat_ts >= updated_ts.
-- fire_drill_alert_lifecycle is the first monthly query in this registry ever to have its version
-- bumped, which is why this latent defect became live on 2026-09-08 and not before.
--
-- Body generated by programmatic exact-string replacement against the LIVE view definition read from
-- state.INFORMATION_SCHEMA.VIEWS on 2026-09-09, not retyped -- ONE replacement, on the drift term.
-- Every other line, including both sibling terms and all of their comments, is byte-identical to
-- what was live.
-- ============================================================================

CREATE OR REPLACE VIEW `stock-trading-498512.state.scheduled_query_version_drift` AS
WITH latest_beat AS (
  SELECT
    SUBSTR(source, 4) AS sq_name,   -- strip the 'sq:' prefix
    ARRAY_AGG(beat_ts ORDER BY beat_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_beat_ts,
    ARRAY_AGG(version ORDER BY beat_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_reported_version,
    LOGICAL_OR(version IS NOT NULL AND TRIM(version) != '') AS ever_reported_version
  FROM `stock-trading-498512.ops.heartbeat`
  WHERE STARTS_WITH(source, 'sq:')
  GROUP BY source
)
SELECT
  e.sq_name,
  e.expected_version,
  e.expected_interval_hours,
  lb.last_reported_version,
  lb.last_beat_ts,
  COALESCE(lb.ever_reported_version, FALSE) AS monitored,
  -- BOOTSTRAP GRACE (2026-09-09, bigquery/232): the `last_beat_ts >= updated_ts` conjunct. A version
  -- mismatch is only EVIDENCE of drift once the query has beaten at least once since the registry row
  -- was bumped; before that the reported version is stale by construction. Without it, bumping a
  -- MONTHLY query (interval 744h) raised this warning every night for the ~23 days until its next
  -- run -- and because the category is on cadence_check's #14 auto-age allowlist, that became a
  -- weekly raise/age/re-raise email cycle rather than one open row. Measured on the live board
  -- 2026-09-09: alert e0cb2898 for fire_drill_alert_lifecycle, registry v4 (2026-09-08 16:10:20),
  -- live procedure DDL v4, heartbeat v3 from 2026-09-01 -- nothing drifted, the query simply had not
  -- run yet. COALESCE guards a NULL updated_ts: without it the comparison would yield NULL and
  -- silently disable drift detection for that row, which is the failure this term must never have.
  -- The two sibling terms below already carry cadence-aware graces; this one did not, and that
  -- asymmetry -- not the grace value -- was the defect. See this file's header for the measurement
  -- showing all 11 other registered queries already satisfy this conjunct, so it costs no coverage.
  COALESCE(lb.ever_reported_version, FALSE)
    AND lb.last_beat_ts >= COALESCE(e.updated_ts, TIMESTAMP '1970-01-01 00:00:00 UTC')
    AND (lb.last_reported_version IS NULL
         OR TRIM(lb.last_reported_version) = ''
         OR lb.last_reported_version != e.expected_version) AS drift,
  -- MON H5 (2026-07-17) beat-AGE dead-man. GRACE_FACTOR = 1.5 (a daily query tolerates one missed run
  -- before flagging; weekly ~10.5d; monthly ~46d — the monthly restore_drill is additionally covered by
  -- restore_stale's own >40d critical, so a generous grace here just avoids false fires on the backstop).
  --   * stale_beat: a query that HAS beaten (monitored) but whose last beat is older than interval x grace
  --     — it was running and silently stopped. NULL expected_interval_hours (unseeded) can never fire.
  (COALESCE(lb.ever_reported_version, FALSE)
   AND e.expected_interval_hours IS NOT NULL
   AND lb.last_beat_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(),
                                       INTERVAL CAST(e.expected_interval_hours * 1.5 AS INT64) HOUR)) AS stale_beat,
  --   * never_beat_overdue: a query registered (updated_ts) more than its own cadence-scaled grace ago
  --     that has NEVER beaten — the self-bootstrapping grace so a freshly-registered query stays quiet
  --     until it has had a real chance to fire at least once (matching the state.script_version_drift /
  --     automation_heartbeat convention: no alarm until first beat unless the never-beat state itself
  --     persists past the grace window). FIXED (2026-07-25): this used to be a flat 7 days regardless of
  --     cadence, same GRACE_FACTOR=1.5 scaling as stale_beat above -- but for a MONTHLY query (interval
  --     744h) that flat floor fires every night for ~24 days after registration despite the query never
  --     having had a chance to run yet (verified live: fire_drill_order_guard / restore_drill both
  --     registered 2026-07-17, both monthly-1st-of-month, both correctly never-beaten-yet, both wrongly
  --     flagged never_beat_overdue starting 2026-07-24 -- the scheduled_query_stale alert this fix
  --     resolves). Now GREATEST(7 days, interval_hours * 1.5) -- daily/weekly queries keep effectively the
  --     same (or the already-more-correct stale_beat-matching) grace; a monthly query gets ~46.5 days,
  --     comfortably past its next real firing before ever alarming.
  (NOT COALESCE(lb.ever_reported_version, FALSE)
   AND e.updated_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(),
       INTERVAL CAST(GREATEST(7 * 24, COALESCE(e.expected_interval_hours, 0) * 1.5) AS INT64) HOUR)) AS never_beat_overdue,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.expected_scheduled_query_versions` e
LEFT JOIN latest_beat lb ON lb.sq_name = e.sq_name;
