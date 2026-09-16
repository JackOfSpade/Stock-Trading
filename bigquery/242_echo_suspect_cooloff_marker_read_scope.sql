-- Correct the sibling-marker claim and the "no other instance" sweep result that bigquery/188
-- appended to artifact_version_drift's ops.alert_policy.resolve_rule.
-- Project: stock-trading-498512. UPDATEs one existing ops.alert_policy row's resolve_rule text.
-- CREATES NO OBJECT, REPLACES NO PROCEDURE, no scheduled-query version bump. Idempotent: the
-- UPDATE is guarded on the new text being ABSENT, so re-applying this file is a no-op.
--
-- WHY THIS IS A SEPARATE FILE AND NOT AN EDIT TO bigquery/188. Same reason 188 was not an edit to
-- 187: 188's UPDATE is guarded on its own appended text being absent, so once it has run (it has --
-- the live row has carried the "READ SCOPE OF THE MARKER" block since 2026-08-20) editing its
-- literal can never reach the live row again. Apply-in-order replay stays correct: 187 inserts,
-- 188 pins the artifact_moved read scope, 242 corrects 188's two over-broad claims.
--
-- ============ WHAT 188 GOT RIGHT, AND THE TWO SENTENCES THAT WERE TOO BROAD ============
-- 188's substance is unchanged and still correct: artifact_moved must be read CYCLE-scoped, and the
-- read-side fix was the right side to fix it on. Two of its closing claims were wrong, and both are
-- the kind of claim a later session reads as a clearance:
--
--   (1) "This read matches AR_orc's two sibling markers (echo_suspect_cooloff,
--       echo_suspect_requeue), which already scan events.queue_events directly and have never
--       exhibited this failure."  -- TRUE of the two SITES it was measured against (Step 0.5's
--       lifetime-cap COUNT(*) and Step 3.5's prior-requeue COUNT(*), both raw-table queries).
--       FALSE as stated, because it names the MARKERS, not the sites -- and echo_suspect_cooloff
--       has a SECOND reader.
--
--   (2) "SWEEP (2026-08-20, same fire): every alert-resolve site in Claude_Task_Plan.md was checked
--       for this class. No other instance."  -- INCOMPLETE. That sweep classified each site by its
--       UPDATE PREDICATE. A resolve site is its ENTRY CONDITION and its predicate, and the third
--       instance was in the condition.
--
-- THE THIRD INSTANCE (found 2026-09-15 by AR_orc's own fire, a no-op day on the review queue):
-- AR_orc Step 4's ECHO-SUSPECT COOL-OFF RESOLVE. Its UPDATE predicate is sound -- it keys off the
-- alert row's own message -- which is exactly why the 2026-08-20 sweep passed it. One level up, the
-- clause that reaches that UPDATE read "If this cycle's queue payload has echo_suspect_cooloff=
-- 'true'", named no query at all, and was therefore row-scoped by default. The shape is identical
-- to artifact_moved's: STEP 0.5 writes the marker onto the NEW 'pending' row it enqueues, the
-- verdict for that cycle is graded days later by a DIFFERENT fire, and by then the row the session
-- holds is AR_att's 'attacker-complete' row (Step 3's p_queue_event_id resolution selects it by
-- name), which need not carry the key.
--
-- MEASURED 2026-09-15, and the measurement is WORSE than 2026-08-20's, not merely analogous:
--   AR_att's key replication is INTERMITTENT, not uniformly absent. Of the 59 (item_key,
--   cycle_number) groups in PENDING_REVIEW holding both a 'pending' and an 'attacker-complete' row,
--   37 attacker rows carry every key the pending row had and 22 drop at least one. premortem-C-
--   2026-a3 cycle 15 dropped all 8 of its pending-only keys, artifact_moved among them. A
--   row-scoped read therefore succeeds on roughly two groups in three: it passes any spot check and
--   fails on the group that matters.
--
-- AND THE CONSEQUENCE RUNS THE WRONG WAY, which is why this is corrected in the live policy row and
-- not just in prose. artifact_version_drift is a warning; hygiene. The alert the cool-off resolve
-- fails to clear is echo_suspect_cap_reached, raised 'critical' by Step 3.5's >= 2 branch, and that
-- UPDATE is the ONLY automated path that can ever clear it: no ops.alert_policy row exists for it
-- or for any other echo_suspect_* category (0 of that table's 49 rows), and ops.sp_auto_resolve_
-- alerts (canonical body bigquery/148, five rules over eleven hardcoded categories) names none of
-- them. The LIVE state.trading_enabled blocking-criticals term (canonical body bigquery/176)
-- counts every unresolved critical except trading_halted, staleness, and the missing_dependency /
-- missed_run halt-echo carve-outs -- echo_suspect_cap_reached is in none of the four. A gate that
-- silently never fires thus leaves the trading halt latched on a review that HAS been independently
-- re-adjudicated and HAS executed its verdict: a fail-OPEN read withholding the release of a
-- fail-CLOSED, trading-halting latch.
--
-- LATENT, NEVER REALISED -- do not inflate this into a realised stranding. Of 206 PENDING_REVIEW
-- rows, exactly 3 carry echo_suspect_cooloff='true' and all 3 belong to the synthetic
-- TEST-REVIEW-CC2-DRYRUN item (cycles 1-3, all 'abandoned', 2026-06-07 / 06-22 / 07-01);
-- echo_suspect_requeue has never been written at all (0 of 206); and the only two
-- echo_suspect_cap_reached alerts ever raised are the 2026-07-13 dry-run pair, both raised at
-- 'info' rather than the 'critical' Step 3.5 prescribes, both resolved 2026-07-17. No real park has
-- ever needed clearing, so that clause has never once executed against a well-formed target.
--
-- THE FIX IS STILL ON THE READ SIDE, AND 188's REFUSAL STANDS. Do NOT close this by asking AR_att
-- to propagate markers forward: the 22-of-59 measurement is positive evidence FOR that refusal, not
-- against it -- a writer-propagation contract would have to be honoured by every writer on every
-- key, and it demonstrably is not. Claude_Task_Plan.md's Step 4 clause now carries the cycle-scoped
-- query, and its Step 5 paragraph now says the sibling sentence clears sites rather than markers.
--
-- WHY THE POLICY ROW AND NOT ONLY THE TASK PLAN: ops.alert_policy.resolve_rule is a triage surface
-- read by a session that is looking at an alert board, not at AR_orc's section. Leaving a sentence
-- there that reads as "both echo_suspect markers are already safe" is how the next sweep skips the
-- site a second time.

UPDATE `stock-trading-498512.ops.alert_policy`
SET resolve_rule = CONCAT(
      resolve_rule,
      ' CORRECTION 2026-09-15 -- THE SIBLING-MARKER SENTENCE ABOVE CLEARS TWO SITES, NOT TWO '
      'MARKERS, AND THE 2026-08-20 "no other instance" SWEEP WAS INCOMPLETE. What is true: Step '
      '0.5\'s echo_suspect_cooloff lifetime-cap COUNT(*) and Step 3.5\'s echo_suspect_requeue '
      'prior-count are both raw events.queue_events queries and have never exhibited this failure. '
      'What was wrong: echo_suspect_cooloff has a SECOND reader, and it had the defect. AR_orc '
      'Step 4 ECHO-SUSPECT COOL-OFF RESOLVE keyed its entry condition on "if this cycle\'s queue '
      'payload has echo_suspect_cooloff=\'true\'" -- no query named, hence row-scoped by default -- '
      'while its UPDATE predicate (message LIKE the review id) was sound, which is precisely why '
      'the 2026-08-20 sweep passed it: that sweep classified each site by its UPDATE predicate, and '
      'a resolve site is its ENTRY CONDITION AND its predicate. Now pinned cycle-scoped in '
      'Claude_Task_Plan.md at that clause: SELECT COUNTIF(JSON_VALUE(payload,'
      '\'$.echo_suspect_cooloff\')=\'true\' AND CAST(JSON_VALUE(payload,\'$.cycle_number\') AS '
      'INT64)=<cycle>) > 0 FROM events.queue_events WHERE queue=\'PENDING_REVIEW\' AND '
      'item_key=<review id>. MEASURED 2026-09-15, and worse than the 2026-08-20 case: AR_att\'s '
      'key replication is INTERMITTENT, not uniformly absent -- of the 59 (item_key, cycle_number) '
      'groups holding both a pending and an attacker-complete row, 37 attacker rows carry every '
      'pending key and 22 drop at least one, and premortem-C-2026-a3 cycle 15 dropped all 8 of its '
      'pending-only keys including artifact_moved. A row-scoped read succeeds on two groups in '
      'three, so it passes any spot check and fails on the group that matters. DIRECTION OF HARM, '
      'why this correction is here and not only in prose: artifact_version_drift is a warning, but '
      'the alert the cool-off clause fails to clear is echo_suspect_cap_reached at critical, and '
      'that UPDATE is the ONLY automated path that can ever clear it (no ops.alert_policy row for '
      'any echo_suspect_* category; ops.sp_auto_resolve_alerts, canonical body bigquery/148, names '
      'none of them), while the live state.trading_enabled blocking-criticals term (bigquery/176) '
      'excludes only trading_halted, staleness and the two halt-echo carve-outs. LATENT, NEVER '
      'REALISED -- 3 of 206 PENDING_REVIEW rows carry the cooloff marker and all 3 are the '
      'synthetic TEST-REVIEW-CC2-DRYRUN item; the only two cap alerts ever raised are the '
      '2026-07-13 dry-run pair, both at info, both resolved 2026-07-17. Do not inflate it into a '
      'realised stranding, and do not close it by having AR_att propagate markers forward -- the '
      '22-of-59 measurement is evidence FOR 188\'s read-side refusal, not against it. A FUTURE '
      'SWEEP OF THIS CLASS MUST READ THE CONDITION THAT REACHES EACH UPDATE, NOT ONLY THE UPDATE.')
WHERE category = 'artifact_version_drift'
  AND resolve_rule NOT LIKE '%CORRECTION 2026-09-15%';
