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
    STRUCT('alert_emailer' AS script_name, 'v10' AS expected_version, '2026-07-29 (correctness fix): alert_emailer.gs v4 retrieves every BigQuery result page and serializes delivery with a script lock, so large alert batches are neither truncated nor sent twice by concurrent runs. Email copy now distinguishes newly un-notified from recurring alerts, with that split computed ONCE per poll and threaded through alertSubject_/htmlAlerts_/plainAlerts_/the Logger.log line -- previously each re-derived it independently and had already drifted once (one call site used the pre-dedup query result instead of the post-dedup fresh-alert count). The "in the last <LOOKBACK_HOURS>" window callout, dropped from both email footers as a side effect of that same rewrite (LOOKBACK_LABEL went dead), is restored -- scoped to the newly-un-notified count only, since the recurring termination_close_staged re-sends are unbounded by LOOKBACK_HOURS. v5, 2026-08-04 (owner directive on roster-change email notifications, bigquery/134_roster_change_notifications.sql): adds the ROSTER CHANGE lane. The six roster-membership categories (strategy_shadow_registered, strategy_probe_registered, strategy_graduated, retirement_proposed, strategy_deregistered, roster_below_floor) moved from info to warning severity upstream, so they now reach this emailer at all -- info was filtered out by both this script and alert_relay.py, which is why an autonomous strategy add or drop previously reached no channel whatsoever. v5 renders them in a separate section with their own subject line and the structured payload detail (strategy, transition, roster count, capital, reason) rather than as another warning-severity fault, selects payload in both queries to do so, and extends isTest_ to recognize payload.synthetic so a fire-drill row caught mid-poll cannot render as a fabricated roster change. v6, 2026-08-04 (adversarial self-review of the v5 change, same session): fixes two self-contradictions the roster lane introduced -- the HTML/plaintext body header keyed on incidents.length, which counts canary and fire-drill rows, so a batch of one real roster notice plus one test row printed the alarming unresolved-alerts header under a calm ROSTER CHANGE subject; and the newly-un-notified footer count was fresh.length, which now includes roster notices, printed directly beneath an incident-only list. Both now key on real incidents excluding tests. Also fences the payload-rendering block in its own try/catch (a persistent throw there would silently stop ALL alert delivery, since the outer catch swallows and state.automation_heartbeat reads only MAX(beat_ts), never the note) and strips CR/LF from the one payload-derived value that reaches the email subject. v6 also closes two delivery gaps the same review surfaced. First, the six roster-change categories are now EXEMPT from the LOOKBACK_HOURS bound: that bound is a cliff rather than a window, because alert_ts is fixed while CURRENT_TIMESTAMP advances, so an un-notified alert that passes 168h leaves the only query in the system that ever stamps notified_ts, permanently -- and with notified_ts stuck NULL, bigquery/134 Rule 5 never resolves it either, so a one-shot roster fact that nothing ever re-raises would be lost silently and sit open forever. Second, a new delivery-failure escalation: the heartbeat proves the SCRIPT ran, not that anything was DELIVERED, since checkAlerts_ swallows every exception and beat_ runs outside that try, so a render throw or a Gmail quota rejection leaves a green heartbeat and zero delivered alerts indefinitely (state.automation_heartbeat reads only MAX(beat_ts), never the note). After 3 consecutive failed polls the script raises a warning alert_delivery_failing row via sp_raise_alert_once, which scripts/alert_relay.py pushes to the ntfy topic from GitHub Actions independently of Apps Script and Gmail, and also sends a direct Gmail escalation. Warning and not critical on purpose: a critical would count toward blocking_criticals and halt order staging on what may be an email hiccup. v7, 2026-08-05 (interactive triage): the AUTO-RESOLVED tag keyed on the resolved boolean alone, so EVERY hand-closed alert was labelled as having self-healed -- observed live on alert 26969a5c (SL5 stall), which an interactive session closed by hand with a detailed note and the emailer then reported as AUTO-RESOLVED, telling the operator the system had fixed itself when it had not. The tag now inspects resolved_note and prints AUTO-RESOLVED only when the note carries the ops.sp_auto_resolve_alerts signature prefix auto-resolved:, else plain RESOLVED. resolved_note was not previously selected by either query, so it was added to BOTH bqAlerts_ SELECTs -- the main un-notified poll and the recurring termination_close_staged query. Adding it to only one would leave the field undefined on recurring rows, which silently regresses them to the RESOLVED branch rather than erroring, so both call sites must stay in lockstep. v8, 2026-08-07 (audit of the 2026-08-07 daily runs): POST-SEND INBOX VERIFICATION. v6 closed the case where sending THROWS; v8 closes the case where sending SUCCEEDS and Gmail then routes the message away from the Inbox, which no code path looked at. MEASURED: all 50 Stock-Trading threads from 2026-07-14 through 2026-08-07 -- alert digests, the 2026-08-01 CRITICAL missing_dependency cascade, the 2026-08-03/04 trading_halted criticals, and every weekly delivery canary -- carry labelIds TRASH+SENT and not one carries INBOX; subject:Stock-Trading in:inbox returns zero threads. Every existing guard read green throughout, necessarily so: the heartbeat beat poll 15 consecutive times, notified_ts stamped normally, alert_delivery_failing never fired because no exception ever occurred, and the weekly delivery_canary asserts the canary row was delivered+STAMPED -- but the stamp is written by this script right after sendEmail, so it proves the loop ran, not that a human could see the result; the canary was itself in Trash. Nothing in the repo trashes the mail (no moveToTrash anywhere), so the cause is a Gmail account-side rule only the operator can change -- what the script owes them is to NOTICE. checkAlerts_ now calls verifyInboxDelivery_ after a successful send: it searches in:anywhere FIRST to distinguish a lagging search index (inconclusive, streak untouched) from a positive misroute (indexed, but absent from in:inbox), then escalates on a 3-poll streak via sp_raise_alert_once alert_not_reaching_inbox. Deliberately ntfy-only through scripts/alert_relay.py, with NO direct-mail twin: emailing a human to tell them their email is not arriving is self-defeating. Warning and not critical for the same reason v6 is -- a critical counts toward blocking_criticals and would halt order staging over a mail-routing rule. v9, 2026-08-21 (owner-directed audit fixes): three delivery-reliability fixes from the 2026-08-21 full-repo audit. (1) escalateDeliveryFailure_ passed a message with the varying streak/hours counters interpolated to sp_raise_alert_once, whose dedup keys on the EXACT (category, message) text -- so the collapse it was chosen for could never fire and every re-escalation of one outage opened a NEW unresolved alert_delivery_failing row. The SQL channel now uses a FIXED message (counters moved to the payload, which is not part of the dedup key; the varying text stays in the direct-email body), and adopts verifyInboxDelivery_ existing proc split: first escalation via sp_raise_alert_once, periodic reminders via plain sp_raise_alert so a fresh row re-enters alert_relay.py relay window and re-pings. (2) checkAlerts_ gains a payload-render fence at the send site: alertSubject_/plainAlerts_ rendered routine-authored payloads unfenced AND are evaluated before htmlAlerts_ own inner fence, so one malformed payload row could black out the whole channel; a render throw now degrades to a payload-free message-only email instead. (3) the inbox-probe inconclusive log line said "the last hour" while INBOX_PROBE_WINDOW_SEC is 600s; the text is now derived from the constant. v10, 2026-08-31 (owner-authorized bug-fix pass, alert-emailer-chain): two fixes. (1) fmtAlertTs_ formatted alert timestamps as MMM d, h:mm a -- no year -- while weekly_report.gs uses MMM d, yyyy. Roster-change notices are deliberately EXEMPT from LOOKBACK_HOURS (v6 above) precisely so a delivery outage of any length delays one instead of destroying it, so the exact mail most likely to arrive long after it was raised, possibly in a different calendar year, was the one rendering a genuinely ambiguous year-less timestamp. Now MMM d, yyyy, h:mm a, matching weekly_report.gs. (2) verifyInboxDelivery_ (v8 above) probed on the unquoted single token subject:Stock-Trading, reasoned to be safe because every subject both this script and weekly_report.gs emit contains that token. That reasoning was correct about needing no quoting and wrong about the consequence: BOTH scripts sharing the token meant the probe could not tell mail sent by this script apart from mail sent by weekly_report.gs, so a healthy weekly report sitting in the Inbox inside the 600s probe window satisfied inbox > 0 and reset inbox_fail_streak even while alert mail sent by this script was silently landing in Trash -- the exact "delivery is not the same thing as liveness" failure mode v8 exists to catch, reopened by the probe design itself. Fixed with a new module-level ALERT_PROBE_TOKEN ("stalertprobe", a single unquoted ASCII lowercase word, so the no-quoting property is preserved) appended to the body of every alert email at the send site in checkAlerts_ -- covering both the normal render and the payload-render-failure fallback -- and never appended to the direct mail escalateDeliveryFailure_ sends, which must stay outside what the probe searches for. The probe now searches on that token instead of the shared subject substring. Transitional and self-healing: between this deploy and the first send under it, no mail carries the token yet, so the probe reads inconclusive (anywhere=0) and leaves the streak untouched, the safe direction. NOTE: do not apply this MERGE live until the owner has actually re-pasted alert_emailer.gs into the live Apps Script project and it has emitted a v10 heartbeat.' AS git_note),
    STRUCT('weekly_report' AS script_name, 'v9' AS expected_version, '2026-07-29 (correctness fix): weekly_report.gs v8 retrieves every BigQuery result page and builds its date axis from the union of benchmark and deployed-strategy dates, so a missing VOO backfill cannot suppress strategy charts. v9, 2026-08-21 (owner-directed audit fix): CHART_COLORS was complete only for strategies A-E while the SISA roster is autonomous up to roster.yaml n_max=8, so a 6th and 7th deployed strategy would both render as the same fallback gray -- mutually indistinguishable lines in the chart, legend and table chip. The map now carries CVD-distinguishable hues for F/G/H (clear of A-E and of VOO_COLOR), the fallback gray stays as the last-resort guard, and the one-row-per-strategy comment stops asserting an always-all-five constraint the code does not have. NOTE: do not apply this MERGE live until the owner has actually re-pasted weekly_report.gs into the live Apps Script project and it has emitted a v9 heartbeat.' AS git_note)
  ])
) S
ON T.script_name = S.script_name
-- git_note is compared too (rev 2026-08-08, codebase audit). The condition used to be
-- `T.expected_version != S.expected_version` ALONE, which meant a git_note correction could never
-- propagate live: the row only refreshes when the VERSION changes, so re-applying this file after a
-- note-only edit was a silent no-op. Found the hard way -- live alert_emailer.git_note was still the
-- 902-char v4-era text while this file carried the 6,919-char v4..v8 history, and no re-apply could
-- ever have fixed it. Nothing reads git_note mechanically (state.script_version_drift reads only
-- expected_version), so this is provenance hygiene, not a functional gate -- but a provenance column
-- that cannot be corrected is worse than none.
WHEN MATCHED AND (T.expected_version != S.expected_version OR T.git_note != S.git_note) THEN
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
