-- state.instruction_drift: stop asserting drift from a sample that predates the canonical change,
-- plus register the two long-firing alert classes that never had an ops.alert_policy row.
-- Project: stock-trading-498512. Apply after bigquery/15 (which now carries canonical_since) and 115.
-- Idempotent (CREATE OR REPLACE VIEW + guarded policy INSERTs).
--
-- ============================================================================================
-- PART 1 — state.instruction_drift: separate "the live trigger differs" from "we have no sample".
-- ============================================================================================
--
-- WHAT THIS VIEW ACTUALLY COMPARES, and why that matters. Its name and its alert text
-- ("routine(s) whose live web-UI trigger differs from the canonical catalog") both claim it reads the
-- LIVE trigger. It does not, and cannot: the trigger config lives only in the claude.ai web UI, which
-- no BigQuery view can reach. The "live" side is `state.routine_last_instruction` <-
-- `ops.run_log.instruction` — the text the routine TRANSCRIBED THE LAST TIME IT RAN. For a daily
-- routine that proxy is hours old and nearly as good as a live read. For an ANNUAL routine it can be
-- a year old.
--
-- THE INCIDENT (2026-08-19, this file). On 2026-08-17 commit 29f6547 ("routine-instruction format
-- decoupling", owner-directed) dropped every routine's descriptive TITLE from the canonical
-- instruction so a remote trigger references only the stable routine ID and re-describing a backend
-- section never again requires editing 33 remote triggers. 30 of the 32 catalog rows changed text
-- that day (all but AR_att/AR_orc, whose headings carry no "<ID>. " prefix and so were a no-op for
-- the decoupling), and `ops.routine_catalog` was regenerated in that same commit. The operator pushed
-- the matching short-form text to the live triggers over the following hours — staggered, not one
-- batch: W3 logged the new short form at 16:13 UTC and W4 at 16:35 UTC, while the last triggers were
-- touched 19:05-19:09 UTC. Both sides therefore AGREE, and have since that afternoon.
--
-- But 17 routines had not executed since the edit, so their newest run_log sample still held the OLD
-- title-bearing text, which is not a prefix of the new short canonical -> `drifted = TRUE` for
-- A1, A2, A3, M1a, M1b, M2, M3, M4, M5, Q1, Q2, Q3, Q4, SL1, SL4, W1, W2. Every one of them is a
-- FALSE POSITIVE about a live trigger that is in fact correct — verified by RemoteTrigger `get`
-- against the live objects on 2026-08-18 and again on 2026-08-19.
--
-- WHY THIS DOES NOT SELF-HEAL, which is the part that makes it worth fixing rather than waiting out.
-- The 2026-08-18 interactive session diagnosed this correctly and hand-resolved the alert, noting it
-- "will self-clear on each routine's next fire". That is true, but the horizon is the routine's own
-- CADENCE: W-tier clears within a week, M-tier by ~2026-09-01, Q-tier not until ~2026-10-02, and
-- A1/A2/A3 not until 2027. Meanwhile the condition is re-evaluated NIGHTLY by
-- ops.sp_sq_cadence_check, and `sp_raise_alert_once` dedupes on the exact (category, message) pair —
-- so every time one routine drops out of the list the MESSAGE changes and a brand-new alert + operator
-- email is raised even while the previous one is still open. Left alone this emits operator mail about
-- correctly-configured triggers, on and off, until January 2027. The alert fired on 2026-08-18 (19
-- routines) and again on 2026-08-19 (17 routines) for exactly this reason.
--
-- THE FIX, and why it is a correctness fix rather than a suppression. `ops.routine_catalog` now
-- carries `canonical_since` — the date that row's canonical_instruction last changed (bigquery/15;
-- generated and preserved by scripts/gen_routine_lists.py, which re-stamps a row only when its own
-- text changes). A sample logged NO LATER than that date cannot be evidence about the live trigger in
-- EITHER direction: it was written before the text it is being compared against existed. Reporting it
-- as `drifted` asserts a fact the view cannot observe. So the mismatch is still computed and still
-- published — as `drift_unproven` — but it no longer sets `drifted`, and `drifted` is the only column
-- the cadence_check raise site reads (`WHERE drifted OR unknown_routine`, bigquery/172's live body).
-- No procedure change is needed and none is made.
--
-- BOUNDARY DAY IS TREATED AS NO-EVIDENCE (`<=`, not `<`). A sample whose run_date EQUALS
-- canonical_since may have been logged before or after that day's edit — run_date is a date, the edit
-- has a clock time (here: text committed 15:51 UTC, triggers updated 16:13-19:09 UTC). W2's last run
-- was on 2026-08-17 at 10:25 UTC and did predate the edit, which is precisely the ambiguity.
-- Withholding the verdict is the honest reading, but be clear about what it costs: the withheld state
-- lasts until that routine NEXT RUNS, which is one CADENCE PERIOD, not one day. For W2 that is a week;
-- for A1/A2/A3, whose last samples are 2026-07-28 and whose cadence is annual, this view offers no
-- automated re-verification of their live triggers until ~2027. That is the honest cost of the
-- boundary rule and of the staleness gate generally, and it is why the two compensating signals below
-- matter rather than being incidental: the CI-side scripts/routine_backup.py check runs on every push
-- and is not sample-bound, and a one-off RemoteTrigger `get` is the way to settle any specific doubt.
--
-- WHAT IS DELIBERATELY NOT MASKED — the detector keeps every tooth it had:
--   * A routine that runs AFTER a canonical change and logs the wrong text still sets `drifted`. That
--     is the actual threat model (a typo'd or hand-edited web-UI trigger pointing a routine at the
--     wrong section), and it is untouched.
--   * `unknown_routine` is untouched — a logged routine absent from the catalog still flags.
--   * Nothing is filtered out of the view. Every routine still returns a row; the withheld ones are
--     visible and countable via `drift_unproven` + `sample_predates_canonical`, so a future session
--     can see exactly what is being withheld and why, instead of finding a silently shorter result.
--   * The repo-side check is unaffected and remains the fresher of the two signals: CI runs
--     `scripts/routine_backup.py check` on every push, validating the DECLARED live trigger text in
--     ops/routine_backup.json against ops/cadence.yaml + ops/triggers.json + ops/trigger_ids.json.
--     So a bad trigger has two independent detectors, and this view's unique contribution — catching
--     an out-of-band console edit — resumes for a given routine the moment it next runs.
--
-- REJECTED ALTERNATIVE, for the next session that reaches for it: relaxing the TEXT match to ignore an
-- optional title clause (so the old title-bearing samples parse as equal). That is the masking fix.
-- It would permanently blind the detector to a title-bearing trigger, which is now exactly the
-- non-canonical form the 2026-08-17 decoupling removed. Same reasoning that rejected dash-folding on
-- 2026-08-03 (alert 2026-08-03 resolved_note): do not buy quiet by removing the detector's ability to
-- see a real difference. The staleness gate above removes only verdicts the view was never entitled
-- to make.
--
-- SUPERSEDED LIVE by bigquery/201_instruction_drift_dash_normalize.sql (2026-08-26) — that file is the
-- CURRENT canonical definition of state.instruction_drift; it adds em/en-dash normalization
-- (r'[—–]' → '-') before the whitespace-normalized PREFIX match so transcription artefacts that fold
-- em-dashes to ASCII hyphens no longer fire a false drift. Do NOT re-apply this file's view in isolation.

CREATE OR REPLACE VIEW `stock-trading-498512.state.instruction_drift` AS
WITH li AS (
  SELECT routine, instruction, run_date
  FROM `stock-trading-498512.state.routine_last_instruction`
  -- collapse id-separator-punctuation variants of the SAME routine to its most recent run
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY REGEXP_REPLACE(routine, r'[·._-]', '')
    ORDER BY run_date DESC, log_ts DESC) = 1
),
j AS (
  SELECT
    COALESCE(c.routine, li.routine) AS routine,
    c.canonical_instruction,
    li.instruction AS live_instruction,
    li.run_date    AS live_last_seen,
    c.canonical_since,
    -- The raw text predicate, UNCHANGED from bigquery/115: whitespace-normalized PREFIX match
    -- (2026-07-29; was first-line-only equality, which false-fired whenever a routine transcribed its
    -- trigger with the newlines collapsed). Normalizing BOTH sides keeps the comparison symmetric even
    -- if a future canonical heading gains odd spacing. A trailing operator addendum still passes; a
    -- wrong routine number / heading / type-tag / truncation / prepended text still fails.
    (c.routine IS NOT NULL AND li.instruction IS NOT NULL
       AND NOT STARTS_WITH(
             TRIM(REGEXP_REPLACE(li.instruction, r'\s+', ' ')),
             TRIM(REGEXP_REPLACE(c.canonical_instruction, r'\s+', ' ')))) AS text_mismatch,
    -- The sample is not newer than the canonical text it is being compared against, so it carries no
    -- information about the CURRENT live trigger. A routine with no catalog row (unknown_routine) or
    -- no sample at all is not "stale" — it is a different condition entirely — hence the guards.
    (c.canonical_since IS NOT NULL AND li.run_date IS NOT NULL
       AND li.run_date <= c.canonical_since) AS sample_predates_canonical,
    (c.routine IS NULL) AS unknown_routine
  FROM `stock-trading-498512.ops.routine_catalog` c
  FULL OUTER JOIN li
    ON REGEXP_REPLACE(li.routine, r'[·._-]', '') = REGEXP_REPLACE(c.routine, r'[·._-]', '')
)
SELECT
  routine,
  canonical_instruction,
  live_instruction,
  live_last_seen,
  canonical_since,
  sample_predates_canonical,
  -- PROVEN drift: the texts differ AND the sample is new enough to be evidence about the live
  -- trigger. This is the ONLY column the cadence_check raise site reads.
  (text_mismatch AND NOT sample_predates_canonical) AS drifted,
  -- Texts differ but the sample predates the canonical change — reported, never raised. This is the
  -- 17-routine 2026-08-17 decoupling backlog; it empties itself as each routine next runs.
  (text_mismatch AND sample_predates_canonical) AS drift_unproven,
  unknown_routine,
  CURRENT_TIMESTAMP() AS checked_at
FROM j;

-- ============================================================================================
-- PART 2 — ops.alert_policy rows for ci_finding and instruction_drift.
-- ============================================================================================
--
-- ACCIDENT OF ABSENCE, the same class ops.alert_policy already documents for append_only_violation
-- ("registered 2026-08-05 after the 8th firing revealed the class had no ops.alert_policy row at all
-- and therefore no written resolve rule"). ci_finding has fired 13 times since 2026-07-16 and
-- instruction_drift 10 times since 2026-06-21 — between them the two most frequently raised classes in
-- the table — and NEITHER has a policy row. Consequence today: every triage session re-derives the
-- resolve rule from scratch (visible in the resolved_note history: four different hand-authored
-- rationales for ci_finding, five for instruction_drift), and `ops.alert_policy` — which is supposed
-- to be the readable index of how every class clears — silently omits its two busiest members.
--
-- Adding a row is SAFE and changes no behaviour: ops.sp_auto_resolve_alerts' rules are each hardcoded
-- to a specific category (`a.category = 'missing_dependency'` etc.), so the table is a fail-closed
-- ALLOWLIST that GATES those rules, never a trigger that enables one. latching=FALSE here records that
-- these classes are mechanically self-clearing and sanctions the documented resolve; it does not make
-- anything resolve that was not already resolving.

INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT * FROM UNNEST([
  STRUCT('ci_finding' AS category, FALSE AS latching,
    'ALREADY AUTOMATED, but NOT by ops.sp_auto_resolve_alerts (whose rules are hardcoded to '
    'missing_dependency/missed_run/routine_stalled/catchup_refire_blocked/staleness and the six '
    'roster-change notices). The resolver is an INLINE, AUTO-RESOLVE-FIRST statement at the top of the '
    'ci_finding block inside ops.sp_sq_cadence_check itself (live body: '
    'bigquery/172_run_log_unpaired_terminal.sql): UPDATE ops.alerts SET resolved=TRUE, '
    'resolved_note=CONCAT(\'auto-resolved: state.ci_findings_open empty. \', ...) WHERE NOT resolved '
    'AND category=\'ci_finding\' AND NOT EXISTS (SELECT 1 FROM state.ci_findings_open); the raise then '
    'runs only IF that view is still non-empty. It therefore fires ONCE DAILY, at the 23:15 '
    'America/Denver cadence_check beat, and NOT when the CI workflow writes its resolved row. '
    'TWO CONSEQUENCES A TRIAGE SESSION MUST KNOW. (1) LAG: a workflow that clears its finding after the '
    'nightly beat leaves the alert open for up to ~24h with nothing wrong — resolving by hand is '
    'cosmetic tidiness, not repair (precedent: alerts 831be955 + ac60de96 on 2026-07-31, and 14106561 '
    'on 2026-08-09 whose own note says the mechanism \'would have closed it tonight regardless\'). '
    '(2) ALL-OR-NOTHING, the trap: the guard is NOT EXISTS over state.ci_findings_open across ALL '
    'workflows, not just the finding_keys named in this alert\'s own message. So ONE unrelated open '
    'finding from ANY producer (live-sql-parity, b3-invariants, alert-relay, auto-merge-main, '
    'stranded-branch-check) pins EVERY open ci_finding alert indefinitely. Measured: seven alerts '
    'raised 2026-07-20..2026-07-26 all cleared at the same instant, 2026-07-27 05:16:48 UTC — the '
    'oldest had been open 7 days, not one night, because a differently-worded finding kept arriving '
    'before the view ever emptied. So DIAGNOSE BY THE VIEW, NOT THE MESSAGE: SELECT * FROM '
    'state.ci_findings_open, and fix whatever it still holds — the alert message is a point-in-time '
    'snapshot that never re-renders and routinely names findings that are already resolved. '
    'Resolve by hand only after that view is empty, or to close a verified-stale digest early; scope '
    'by alert_id. Never resolve on age: the all-or-nothing guard means an aged-out row is '
    'indistinguishable from a genuinely-cleared one. Registered 2026-08-19 (bigquery/183) after the '
    '13th firing found the class had no policy row.' AS resolve_rule,
    'CI-GUARD BRIDGE CLASS, first raised 2026-07-16; producers write ops.ci_findings from GitHub '
    'Actions (RUNBOOK CI->BigQuery delivery pattern: CI writes ops.ci_findings, never ops.alerts '
    'directly), and state.ci_findings_open (bigquery/86) is the latest-row-per-(workflow,finding_key) '
    'open filter. WARNING, never critical: an open critical sets state.trading_enabled=FALSE '
    '(bigquery/107) and a red CI guard is not a reason to halt order staging. Never info: '
    'alert_emailer.gs and alert_relay.py both filter info out, so an info raise would be invisible.' AS note),
  STRUCT('instruction_drift' AS category, FALSE AS latching,
    'SELF-CLEARING ON EXECUTION, plus a 7-day auto-age. Two independent mechanisms, neither in '
    'ops.sp_auto_resolve_alerts: (1) the CONDITION clears when every routine in '
    'state.instruction_drift WHERE drifted OR unknown_routine drops out — for a genuine drift that '
    'means fixing the live web-UI trigger (owner-only) or the catalog (bigquery/15, regenerate via '
    'scripts/gen_routine_lists.py --write), after which the routine\'s NEXT run re-logs matching text; '
    '(2) the ALERT ROW itself is auto-aged after 7 days by the #14 self-clearing-class block inside '
    'ops.sp_sq_cadence_check, which lists instruction_drift first. '
    'READ THE VIEW BEFORE BELIEVING THE MESSAGE. The alert text says "live web-UI trigger differs", '
    'but the view\'s live side is ops.run_log.instruction — what the routine TRANSCRIBED WHEN IT LAST '
    'RAN, never a live read. Since 2026-08-19 (bigquery/183) the view separates the two cases '
    'explicitly: `drifted` = texts differ AND the sample postdates ops.routine_catalog.canonical_since '
    '(a real, actionable finding); `drift_unproven` = texts differ but the sample predates the last '
    'canonical change (NO evidence either way — do NOT touch a trigger over one). Only `drifted` and '
    '`unknown_routine` raise. HISTORY, so this is not re-litigated a sixth time: of the five prior '
    'firings, ONE was genuine live drift (W5, 2026-06-29, owner-fixed) and FOUR were detector '
    'artifacts fixed in the detector, never by editing a trigger — ad-hoc note shadowing (2026-06-21, '
    'RUNBOOK 22), id-separator mismatch (2026-06-30, RUNBOOK 28), the standing operator addendum '
    '(2026-07-20), and newline-collapsed transcription (2026-07-29, bigquery/115). Default posture on a '
    'new firing is therefore: verify the LIVE trigger with RemoteTrigger get BEFORE concluding drift, '
    'and prefer fixing the detector to editing a trigger. Resolve with UPDATE ops.alerts SET '
    'resolved=TRUE, resolved_note=<which routines, live-verified verdict per routine>, scoped by '
    'alert_id. Registered 2026-08-19 (bigquery/183) after the 10th firing found the class had no '
    'policy row.' AS resolve_rule,
    'TRIGGER-INTEGRITY CLASS, first raised 2026-06-21. The schedule and instruction of every routine '
    'live ONLY in the claude.ai web UI — unversioned and invisible — so this view plus the CI-side '
    'scripts/routine_backup.py check are the only two things that would ever notice a typo\'d or '
    'hand-edited trigger. WARNING, never critical: an open critical sets state.trading_enabled=FALSE '
    '(bigquery/107) and a mis-worded trigger is not a reason to halt order staging. Never info: '
    'alert_emailer.gs and alert_relay.py both filter info out.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` a WHERE a.category = p.category
);
