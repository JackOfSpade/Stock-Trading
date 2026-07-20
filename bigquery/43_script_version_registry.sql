-- Apps Script version-drift registry (item 23 gap closure). Project: stock-trading-498512.
--
-- WHY: Claude cannot reach script.google.com, so an in-repo .gs fix (alert_emailer.gs / weekly_report.gs)
-- takes effect only after the OWNER manually re-pastes it into the Apps Script editor. Nothing today
-- detects the gap between "the repo was fixed" and "the live script was redeployed" -- a routine could
-- believe a bug is closed while the deployed script still runs the old, buggy code indefinitely.
-- ops.heartbeat / state.automation_heartbeat (bigquery/16_automation_health.sql) already prove the
-- scripts are ALIVE; this file adds a second, independent signal -- are they running the EXPECTED
-- VERSION. Both scripts already write an ops.heartbeat beat every run (alert_emailer.gs beat_(),
-- weekly_report.gs's inline heartbeat insert); this file assumes a `version` column is added to that
-- same beat write (see the owner_actions .gs diffs delivered alongside this file) so a version can be
-- read back without any new write path.
--
-- CIRCULARITY NOTE (header, per item-23 spec): the drift alarm MUST be delivered via the DTS fail-loud
-- channel (bigquery/scheduled_queries/cadence_check.sql -> BigQuery's built-in "Send email
-- notifications on failure"), NOT via alert_emailer.gs. alert_emailer.gs is one of the two scripts
-- being monitored here -- routing its own drift alarm through itself would be exactly the same
-- "who watches the watchers" failure mode automation_heartbeat was built to close (a stale/wrong-version
-- alert_emailer cannot be trusted to notice or report its own staleness). The RAISE wiring itself is a
-- shared_edit to cadence_check.sql, delivered separately (NOT applied by this file) -- see that file's
-- integrator diff.
--
-- SELF-BOOTSTRAPPING: state.script_version_drift.monitored is TRUE only once a script has beaten at
-- least once WITH a non-NULL version column populated. Before the owner pastes the version-emitting
-- .gs diff, every script reports version = NULL and monitored = FALSE for that source, so applying this
-- file does not false-alarm ahead of the owner's manual redeploy. FAIL-CLOSED the other direction too:
-- once a script HAS reported a version at least once, any subsequent beat with a NULL/blank/mismatched
-- version, or (once expected) no beat at all, computes drift = TRUE -- never silently treated as
-- "up to date" on missing data.
--
-- Depends on bigquery/16_automation_health.sql (ops.heartbeat, state.automation_heartbeat -- read for
-- context/pattern only; this file does not modify either). Idempotent: CREATE TABLE IF NOT EXISTS for
-- the seed table (guarded MERGE below keeps expected_version current on re-apply without duplicating
-- rows), CREATE OR REPLACE VIEW for the drift view. Apply after 16; apply BEFORE re-pasting
-- cadence_check.sql's RAISE addition (shared_edit, delivered separately -- see that file's integrator
-- diff) since that addition will reference state.script_version_drift.
--
-- SCOPE NOTE: this file does NOT alter ops.heartbeat's schema (adding the `version` column is itself a
-- shared_edit -- see the live_sql ALTER TABLE below, listed separately from the CREATE statements so the
-- integrator can sequence it before the .gs owner-paste lands data). state.script_version_drift reads
-- that column defensively (COALESCE-safe) so this view is valid to CREATE even before the ALTER runs;
-- it will simply show every source as drift=TRUE (missing version) until both the ALTER and the .gs
-- paste have happened -- which is the correct fail-closed initial state, not a false alarm, because
-- monitored gates it off until the first version-bearing beat arrives.

-- ===== ops.heartbeat schema evolution -- add the version column the .gs beat writes will populate =====
-- CREATE TABLE IF NOT EXISTS (16_automation_health.sql) will not add a column to a pre-existing table,
-- so this explicit ALTER is the upgrade path (same pattern as ops.backup_log's `dataset` column,
-- 16_automation_health.sql). Nullable and additive only -- existing rows/readers are unaffected; the
-- state.automation_heartbeat liveness view (16_automation_health.sql) does not reference this column and
-- keeps working unchanged.
ALTER TABLE `stock-trading-498512.ops.heartbeat` ADD COLUMN IF NOT EXISTS version STRING;

-- ===== state.expected_script_versions -- seed table of what SHOULD be deployed =====
-- One row per out-of-band Apps Script, reflecting the version string committed in THIS repo's .gs file
-- at the time this row was last written. Bumped by whichever commit changes the corresponding .gs file's
-- SCRIPT_VERSION constant (see owner_actions diff) -- keep the two in lockstep by convention, not by any
-- automated check (no CI can see script.google.com's live state; git is the only source of truth for
-- "expected").
CREATE TABLE IF NOT EXISTS `stock-trading-498512.state.expected_script_versions` (
  script_name STRING NOT NULL,        -- 'alert_emailer' | 'weekly_report' -- MUST match ops.heartbeat.source
  expected_version STRING NOT NULL,   -- matches the per-file version const: ALERT_SCRIPT_VERSION in
                                       -- alert_emailer.gs, SCRIPT_VERSION in weekly_report.gs (renamed
                                       -- 2026-07-14 to avoid a same-project top-level-scope const collision)
  git_note STRING,                    -- which commit / .gs change last bumped this row
  updated_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) OPTIONS(description='Seed/reference table: the Apps Script version each out-of-band .gs SHOULD be running, per the repo state. Source of truth for state.script_version_drift. Updated by a guarded MERGE (idempotent re-apply) whenever a .gs SCRIPT_VERSION constant is bumped in this file.');

-- Guarded MERGE (idempotent re-apply, same pattern as 35_strategy_arsenal.sql's seed INSERTs but
-- upsert-shaped since this table's content should track the CURRENT repo state on every re-apply, not
-- just the first). Bump the version strings here in the SAME commit that bumps the .gs SCRIPT_VERSION
-- constants (owner_actions diffs).
MERGE `stock-trading-498512.state.expected_script_versions` T
USING (
  SELECT * FROM UNNEST([
    STRUCT('alert_emailer' AS script_name, 'v3' AS expected_version, '2026-07-18 (audit): alert_emailer.gs v3 -- guard the notified_alert_ids JSON.parse so a corrupt/non-JSON Script Property no longer throws on every poll before any send and PERMANENTLY suppresses ALL alert delivery (degrades to an empty Set == at worst a re-send). NOTE: do not apply this MERGE live until the owner has actually re-pasted alert_emailer.gs into the live Apps Script project -- applying it early makes state.script_version_drift false-alarm against the still-v2 live heartbeat.' AS git_note),
    STRUCT('weekly_report' AS script_name, 'v7' AS expected_version, '2026-07-20 (code-quality audit finding C25): weekly_report.gs v7 -- pctCellHtml_\'s color swatch picked clr_(v) off v\'s RAW sign while its text came from signPct_(v*100), which forces a \'+\' once the FORMATTED magnitude rounds to \'0.00\' (2026-07-17 GS-1); a hairline loss in roughly (-0.00005, 0) -- easily hit by a near-flat sleeve or the park\'s AI row -- rendered loss-red \'#c0392b\' around text reading \'+0.00%\'. Same sign/color contradiction GS-1 already removed from the text half, still present in the color half. Fix: the swatch now checks the same rounded view (Math.abs(v*100).toFixed(2) === \'0.00\') before falling back to clr_(v), so the sign glyph and swatch can never disagree at that boundary; clr_ itself is unchanged (still a pure sign->color map, one call site). NOTE: do not apply this MERGE live until the owner has actually re-pasted weekly_report.gs into the live Apps Script project and it has emitted a v7 heartbeat -- applying it early makes state.script_version_drift false-alarm against the still-v6 live heartbeat.' AS git_note)
  ])
) S
ON T.script_name = S.script_name
WHEN MATCHED AND T.expected_version != S.expected_version THEN
  UPDATE SET expected_version = S.expected_version, git_note = S.git_note, updated_ts = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
  INSERT (script_name, expected_version, git_note) VALUES (S.script_name, S.expected_version, S.git_note);

-- ===== state.script_version_drift -- latest reported version per script vs expected (self-bootstrapping) =====
-- monitored: TRUE only once the script has logged >=1 heartbeat beat carrying a non-NULL/non-blank
-- version (i.e. the owner has pasted the version-emitting .gs diff at least once). Until then this
-- source is excluded from being "unmonitored == drifted" noise, matching state.automation_heartbeat's
-- and state.backup_health's established self-bootstrapping convention.
-- drift: FAIL-CLOSED. TRUE when monitored AND (no reported version OR reported version != expected).
-- A script that has never reported a version is NOT "assumed fine" -- it is simply not yet monitored
-- (monitored=FALSE, drift=FALSE) until its first version-bearing beat; every beat AFTER that first one
-- is held to the expected_version bar, and a later beat that regresses to NULL/blank (e.g. a partial or
-- reverted re-paste) is drift=TRUE, never silently ignored.
CREATE OR REPLACE VIEW `stock-trading-498512.state.script_version_drift` AS
WITH latest_beat AS (
  SELECT
    source AS script_name,
    ARRAY_AGG(beat_ts ORDER BY beat_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_beat_ts,
    -- BUG FIX (rev 2026-07-11, adversarial self-audit): this MUST NOT use IGNORE NULLS. The point of
    -- last_reported_version is "what did the MOST RECENT beat actually report" -- if that beat's own
    -- version is NULL (a regression: a broken/partial re-paste, or the SCRIPT_VERSION const dropped),
    -- IGNORE NULLS would silently fall back to an OLDER beat's non-NULL version instead, masking the
    -- exact regression this view exists to catch and directly contradicting the header's own documented
    -- fail-closed guarantee ("a later beat that regresses to NULL/blank... is drift=TRUE, never silently
    -- ignored"). Without IGNORE NULLS, ARRAY_AGG's default NULL-inclusive behavior correctly surfaces a
    -- NULL here when the latest beat's version genuinely is NULL.
    ARRAY_AGG(version ORDER BY beat_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_reported_version,
    -- has this source EVER reported a non-blank version (arms monitoring independent of the latest beat)
    LOGICAL_OR(version IS NOT NULL AND TRIM(version) != '') AS ever_reported_version
  FROM `stock-trading-498512.ops.heartbeat`
  GROUP BY source
)
SELECT
  e.script_name,
  e.expected_version,
  lb.last_reported_version,
  lb.last_beat_ts,
  COALESCE(lb.ever_reported_version, FALSE) AS monitored,
  COALESCE(lb.ever_reported_version, FALSE)
    AND (lb.last_reported_version IS NULL
         OR TRIM(lb.last_reported_version) = ''
         OR lb.last_reported_version != e.expected_version) AS drift,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.expected_script_versions` e
LEFT JOIN latest_beat lb ON lb.script_name = e.script_name;
