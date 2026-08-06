-- Register the append_only_violation alert class in ops.alert_policy. Project: stock-trading-498512.
--
-- WHY: `scheduled.integrity` / `append_only_violation` (detector: state.append_only_integrity,
-- bigquery/18_stack_review_fixes.sql; fired by ops.sp_sq_integrity_check, bigquery/75) has fired 8
-- times since 2026-07-16 and has NEVER had a row in ops.alert_policy. That omission is the gap this
-- file closes. Its practical effect until now was invisible-but-real: ops.sp_auto_resolve_alerts
-- (bigquery/134, current) evaluates six hard-coded categories and additionally gates every rule on
-- `category IN (SELECT category FROM ops.alert_policy WHERE NOT latching)`, so an UNREGISTERED
-- category can never satisfy either test -- the class was already manual-only by accident rather than
-- by declaration, with no resolve_rule text telling a future session what closing it correctly
-- requires. Every one of the 8 instances was in fact closed by a hand-written resolved_note, and the
-- 2026-08-01 instance (alert 2d719763) says so explicitly in its own note: "This alert has no
-- auto-resolve path by construction, so it is being closed by hand."
--
-- latching = TRUE is the honest declaration of the behaviour that already existed, and adds the same
-- double lock bigquery/138 gave prompt_injection_attempt: absent from every rule list AND excluded by
-- the NOT latching predicate. Registering it as latching = FALSE would be the actively wrong choice --
-- it would advertise an auto-resolve path that does not exist and cannot be built for this class,
-- because "was that UPDATE legitimate" is an adjudication, not a condition a view can re-check.
--
-- 2026-08-05 CONTEXT (alert 9c7c0261). AR_att repaired two of its own rows mid-run with an in-place
-- UPDATE on events.adversarial_reviews, tripping this detector. Root-caused to a genuine spec gap:
-- AR_att is STRICT-BLINDED and so could not read bigquery/README.md, the only place the BigQuery
-- string-literal escaping convention was written down; six of its ten rows that fire were stored
-- corrupted. Fixed by restating the rule inline in Claude_Task_Plan.md's shared preamble
-- ("Writing long markdown into a BigQuery column"), which every generated task_plan slice inherits.
--
-- Defines NO views or procedures -- one registry INSERT, guarded by NOT EXISTS so re-apply is
-- idempotent. Does NOT redefine ops.sp_auto_resolve_alerts (bigquery/134 remains current) and does NOT
-- alter the detector (bigquery/18 remains current). Apply after bigquery/34_alert_lifecycle.sql
-- (which creates ops.alert_policy).
--
-- ===================== NOTE TEXT SUPERSEDED 2026-08-06 (read before trusting the literal below) ====
-- The `note` literal in this file's INSERT is RETAINED VERBATIM as the original registration record,
-- but it is NO LONGER what the live ops.alert_policy row says, and its central claim is now FALSE.
-- bigquery/143_adversarial_review_correction_path.sql added `superseded_by` to
-- events.adversarial_reviews AND fixed ops.sp_score_cross_model_referee's missing dedup -- the two
-- facts this note cites as the reason a superseding row is unsafe. It also issues the UPDATE that
-- rewrote the live row's `note`; because THIS file's INSERT is NOT-EXISTS-guarded on `category`,
-- re-applying this file is a NO-OP against the existing row and will NOT propagate any edit made here.
-- bigquery/143 is the current source of truth for this row's `note`.
-- `latching = TRUE` and `resolve_rule` are UNCHANGED and remain correct: the class is still a manual
-- adjudication, and no auto-resolve rule exists or should be added. What changed is only how OFTEN it
-- should fire -- a correct repair is now an INSERT, which is not a watched statement_type, so it
-- raises nothing. An append_only_violation naming events.adversarial_reviews after 2026-08-06 means
-- something performed an in-place UPDATE, which is NO LONGER sanctioned and is a real finding.

INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'append_only_violation' AS category,
    TRUE AS latching,
    CONCAT(
      'NEVER auto-resolves -- adjudication, not a re-checkable condition. Close by hand only, after ',
      'doing all four: (a) attribute EVERY job_id in the payload via ',
      'region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT (creation_time, user_email, labels -- a ',
      'goog-mcp-server label means an MCP/Claude session, bq-scheduler means a scheduled query) and ',
      'correlate against ops.run_log to name the routine session that ran it; (b) judge whether the ',
      'write was legitimate in CONTENT and separately whether the MECHANISM was sanctioned -- these ',
      'differ, and the usual finding is correct content written the wrong way; (c) if the mechanism ',
      'was wrong, fix the emitter so it stops recurring, or record why no fix is possible; (d) note ',
      'that the detector scans a rolling 2-DAY JOBS_BY_PROJECT window while sp_raise_alert_once ',
      'dedups only on (category, message) WHERE NOT resolved -- so resolving a row whose jobs are ',
      'still inside that window re-arms exactly one more identical raise per remaining night. State ',
      'the predicted recurrence in the note (precedent: 4353777f then afdc096d; 58da7e8f then ',
      '94ce1df2) so the echo can be closed by reference instead of re-investigated. Resolve with ',
      'UPDATE ops.alerts SET resolved=TRUE, resolved_note=<attribution + disposition>, scoped by ',
      'alert_id.'
    ) AS resolve_rule,
    CONCAT(
      'INTEGRITY CLASS, first raised 2026-07-16; registered here 2026-08-05 after the 8th firing ',
      '(alert 9c7c0261, AR_att UPDATE on events.adversarial_reviews) revealed the class had no ',
      'ops.alert_policy row at all and therefore no written resolve rule. Detector: ',
      'state.append_only_integrity (bigquery/18) over UPDATE/DELETE/MERGE/TRUNCATE_TABLE against the ',
      'eight audit-truth events.* tables; one carve-out exists, W5 normalizing ',
      'events.decision_log.sub_pattern in place (RUNBOOK 21). NOTE for future sessions: adding a ',
      'second row is NOT a universally safe alternative to an in-place fix on ',
      'events.adversarial_reviews -- that table has no superseded_by column, and ',
      'ops.sp_score_cross_model_referee filters role=attacker with no dedup across rows, so a ',
      'superseding row makes it insert duplicate referee_gemini rows. See the shared-preamble section ',
      'in Claude_Task_Plan.md titled Writing long markdown into a BigQuery column.'
    ) AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` a WHERE a.category = p.category
);
