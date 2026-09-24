-- Correct the "both raw-table counters are clean" clearance that bigquery/242 appended to
-- artifact_version_drift's ops.alert_policy.resolve_rule.
-- Project: stock-trading-498512. UPDATEs one existing ops.alert_policy row's resolve_rule text.
-- CREATES NO OBJECT, REPLACES NO PROCEDURE, no scheduled-query version bump. Idempotent: the
-- UPDATE is guarded on the new text being ABSENT, so re-applying this file is a no-op.
--
-- WHY A SEPARATE FILE AND NOT AN EDIT TO 242: the same reason 242 was not an edit to 188, and 188
-- not an edit to 187. Each of those UPDATEs is guarded on its own appended text being absent, so
-- once it has run -- and 242 has; the live row has carried the "CORRECTION 2026-09-15" block since
-- that date -- editing its literal can never reach the live row again. Apply-in-order replay stays
-- correct: 187 inserts, 188 pins the artifact_moved read scope, 242 corrects 188's two over-broad
-- claims, 247 corrects 242's own.
--
-- ============ WHAT 242 GOT RIGHT, AND THE ONE SENTENCE THAT IS NOW A FALSE CLEARANCE ============
-- 242's substance is unchanged and still correct: echo_suspect_cooloff had a SECOND reader, Step 4's
-- entry condition was row-scoped by default, and a resolve site is its ENTRY CONDITION and its
-- predicate. All of that stands. The sentence that does not is its opening concession:
--
--   "What is true: Step 0.5's echo_suspect_cooloff lifetime-cap COUNT(*) and Step 3.5's
--    echo_suspect_requeue prior-count are both raw events.queue_events queries and have never
--    exhibited this failure."
--
-- True, and irrelevant in the direction that matters. Those two ARE raw-table queries, so neither
-- can MISS a marker AR_att dropped -- that is the read-scope failure, and they are genuinely clear
-- of it. But the sentence sits on a triage surface, next to a heading that reads as a sweep result,
-- and it clears the two sites outright. It does not. Both had a different defect, in the opposite
-- direction, and 242's own measurement is the evidence for it.
--
-- THE FOURTH INSTANCE, AND IT IS A UNIT ERROR RATHER THAN A SCOPE ERROR (found 2026-09-23 by
-- AR_orc's own fire, a no-op day on the review queue). Three AR_orc sites tally echo-suspect
-- history and all three counted ROWS: Step 0.5's LIFETIME CAP (>= 3), Step 3.5's prior-requeue
-- count (< 2 / >= 2), and Step 4's cooloff_attempt_n. Each retry is enqueued by AR_orc as exactly
-- ONE new 'pending' row carrying the marker. AR_att then inserts its OWN row for the same item_key
-- and the same cycle_number -- and MAY CARRY THAT MARKER FORWARD. Nothing instructs it either way:
-- AR_att's transition bullet pins only the two due-date payload fields and is silent on every other
-- key. So one retry leaves one marker row or two, and the ROW unit equals the RETRY unit only in the
-- half of the lane where AR_att happens to drop the key.
--
-- MEASURED 2026-09-23, and the majority case is the doubling one:
--   Across the 59 (item_key, cycle_number) groups holding both a 'pending' and an
--   'attacker-complete' row, ALL 59 carried at least one payload key beyond the schema's own fields
--   on the pending row. AR_att carried EVERY one of them forward in 37 groups and some in 22, and
--   in ZERO groups did it drop them all -- 255 of 349 such keys, 73%, were replicated.
--   So a cool-off or requeue marker is MORE LIKELY THAN NOT to be counted twice for one retry.
--   The one contrary datum, artifact_moved (2 pending rows, 0 attacker-complete), is a single
--   enqueue instant dropped by a single attacker session: n=1 against a 37-of-59 base rate, and it
--   is the same observation 188 already spent.
--
-- THE SAME MEASUREMENT BREAKS A READ AND A COUNT IN OPPOSITE DIRECTIONS, WHICH IS WHY 242 CAUGHT
-- ONLY HALF OF IT. A DROPPED key makes a row-scoped READ miss a marker that is present -- 188 and
-- 242's defect. A REPLICATED key makes a row-counted TALLY double a retry that happened once.
-- Widening the SCOPE of a read does nothing about the UNIT of a count, and 242 went further: it
-- ratified the row unit outright, in the very paragraph that measured the intermittency, and
-- Claude_Task_Plan.md's Step 4 clause said so in as many words ("deliberately counting marker ROWS,
-- the same unit as STEP 0.5's lifetime-cap COUNT(*), so the two can never disagree"). The
-- consistency goal was right and is kept. The unit made both sites agree on the same wrong number.
--
-- AND THE CONSEQUENCE RUNS THE OTHER WAY FROM 242's, which is why this belongs in the live policy
-- row too. 242's defect was fail-OPEN: a resolve that silently never fires, leaving a trading halt
-- latched. This one is fail-CLOSED, and not free: under replication Step 3.5 allows ONE
-- echo-suspect requeue instead of two before raising echo_suspect_cap_reached at 'critical', and
-- Step 0.5 allows TWO cool-off retries instead of three before echo_suspect_exhausted. Both
-- criticals are owner-resolve-only, are reached by no rule of ops.sp_auto_resolve_alerts (canonical
-- body bigquery/148), and sit in NONE of the four carve-outs of the live state.trading_enabled
-- blocking-criticals term (canonical body bigquery/176) -- so each halts trading a full cycle
-- earlier than the owner-directed rail specifies, on a review that rail meant to keep retrying.
-- Step 4 would meanwhile write "cool-off retry 4 of 3" into its resolved_note and its
-- events.decision_log entry: an audit trail contradicting its own stated bound. The cap's stated
-- arithmetic goes unreachable with it -- "6 total independence failures (3 pre-cap + 3 failed
-- cool-off retries)", a count a 2026-07-18 audit ALREADY corrected once, from "5".
--
-- THE FIX IS ON THE COUNT SIDE, AND 188's AND 242's READ-SIDE REFUSAL STANDS UNCHANGED. Count
-- DISTINCT cycle_number, never rows, at all three sites: one retry is one cycle by construction,
-- since every re-enqueue in AR_orc's section sets cycle_number = last cycle + 1, so the cycle is
-- the only unit a duplicate row cannot inflate. Fall back to the row's own event_id where the cycle
-- does not parse, so an unkeyed marker row counts as its OWN attempt -- a cap is an UPPER bound and
-- a change of unit must never be able to talk it downward. is_cooloff_cycle stays a
-- COUNTIF(...) > 0 (a boolean is replication-proof) and the 14-day cadence MAX(event_ts) stays as
-- written (a duplicate row can only push it LATER, lengthening the gap between retries, the safe
-- direction). Do NOT close this by asking AR_att to replicate, or to stop replicating: the
-- 37-of-59 measurement is evidence FOR the read-side refusal exactly as the 22-of-59 was, and a
-- writer-propagation contract would have to be honoured by every writer on every key.
-- Claude_Task_Plan.md now carries the three corrected queries at the three sites that execute them,
-- plus the full pin below STEP 0.5.
--
-- LATENT, NEVER REALISED -- do not inflate this into a realised mis-park. echo_suspect_requeue has
-- never been written at all (0 of 206 PENDING_REVIEW rows); echo_suspect_cooloff appears on exactly
-- 3, all the synthetic TEST-REVIEW-CC2-DRYRUN item (cycles 1-3, all 'abandoned', 2026-06-07 /
-- 06-22 / 07-01). Those 3 rows span 3 distinct cycles, so row-count and cycle-count agree there --
-- and they agree for the reason that proves the point: that item never passed through AR_att, so no
-- attacker row exists to duplicate its markers. Neither counter has ever once run against a target
-- AR_att had touched.
--
-- WHY THE POLICY ROW AND NOT ONLY THE TASK PLAN: verbatim 242's own reason, which this file is the
-- first occasion to test. ops.alert_policy.resolve_rule is a triage surface read by a session
-- looking at an alert board, not at AR_orc's section. 242 wrote that leaving a sentence there which
-- reads as "both echo_suspect markers are already safe" is how the next sweep skips the site a
-- second time -- and its own replacement sentence reads as "both echo_suspect COUNTERS are already
-- safe". That is how the next sweep would have skipped them a third time.

UPDATE `stock-trading-498512.ops.alert_policy`
SET resolve_rule = CONCAT(
      resolve_rule,
      ' CORRECTION 2026-09-23 -- THE 2026-09-15 CLAUSE ABOVE CLEARS THOSE TWO COUNTERS OF THE '
      'READ-SCOPE DEFECT ONLY, AND BOTH HAD A SECOND ONE: THEY COUNTED ROWS, AND A MARKER ROW IS '
      'NOT A RETRY. What stays true: Step 0.5\'s lifetime cap and Step 3.5\'s prior-requeue count '
      'are raw events.queue_events queries, so neither can MISS a marker AR_att dropped. What was '
      'wrong: each retry is enqueued by AR_orc as exactly ONE new pending row carrying the marker, '
      'and AR_att then inserts its OWN row for the same item_key and cycle_number which MAY carry '
      'that marker forward -- nothing instructs it either way, since AR_att\'s transition bullet '
      'pins only the two due-date payload fields. MEASURED 2026-09-23, the majority case is the '
      'doubling one: across the 59 (item_key, cycle_number) groups holding both a pending and an '
      'attacker-complete row, ALL 59 carried at least one payload key beyond the schema fields on '
      'the pending row, AR_att carried EVERY one forward in 37 groups and some in 22, and in ZERO '
      'groups dropped them all -- 255 of 349 such keys, 73 percent, replicated. The same '
      'intermittency therefore breaks a READ and a COUNT in OPPOSITE directions: a dropped key '
      'makes a row-scoped read MISS, a replicated key makes a row-counted tally DOUBLE, and '
      'widening the scope of a read does nothing about the unit of a count. DIRECTION OF HARM, '
      'opposite to the 2026-09-15 case and still not free: that one was fail-OPEN (a resolve that '
      'never fires, leaving a halt latched); this one is fail-CLOSED -- Step 3.5 allows ONE requeue '
      'instead of two before echo_suspect_cap_reached at critical, and Step 0.5 allows TWO cool-off '
      'retries instead of three before echo_suspect_exhausted, both owner-resolve-only, both '
      'reached by no rule of ops.sp_auto_resolve_alerts, and both outside all four carve-outs of '
      'the live state.trading_enabled blocking-criticals term (bigquery/176), so each halts trading '
      'a full cycle early on a review the rail meant to keep retrying. Step 4 would also write '
      '"cool-off retry 4 of 3" into its resolved_note and decision-log entry, and the cap\'s stated '
      '6-total-failures arithmetic -- itself already corrected once, from 5, by a 2026-07-18 audit '
      '-- goes unreachable again. THE RULE, now pinned in Claude_Task_Plan.md at all three '
      'executing sites plus a full pin below STEP 0.5: count DISTINCT cycle_number, never rows, '
      'with a COALESCE fallback to the row\'s own event_id so an unkeyed marker row counts as its '
      'OWN attempt and a change of unit can never talk a cap DOWNWARD. One retry is one cycle by '
      'construction, since every re-enqueue in that section sets cycle_number = last cycle + 1. '
      'is_cooloff_cycle stays a COUNTIF(...) > 0 and the 14-day cadence MAX(event_ts) stays as '
      'written -- a duplicate row can only push it later, the safe direction. LATENT, NEVER '
      'REALISED -- echo_suspect_requeue has never been written (0 of 206 PENDING_REVIEW rows) and '
      'the 3 echo_suspect_cooloff rows are all the synthetic TEST-REVIEW-CC2-DRYRUN item, whose '
      'row-count and cycle-count agree precisely because it never passed through AR_att. Do not '
      'inflate it into a realised mis-park, and do not close it by having AR_att replicate or stop '
      'replicating -- the 37-of-59 measurement is evidence FOR the read-side refusal exactly as the '
      '22-of-59 was. A FUTURE SWEEP OF THIS CLASS MUST CHECK THE UNIT OF EACH TALLY, NOT ONLY THE '
      'SCOPE OF EACH READ.'),
    updated_ts = CURRENT_TIMESTAMP()
WHERE category = 'artifact_version_drift'
  AND resolve_rule NOT LIKE '%CORRECTION 2026-09-23%';

-- UPDATED_TS IS BUMPED HERE, AND 187 / 188 / 242 EACH FAILED TO (noticed 2026-09-23 by the fire
-- that wrote this file, on re-reading the live row it had just changed). ops.alert_policy.updated_ts
-- carries a CURRENT_TIMESTAMP() default, which fires on INSERT and never on UPDATE, so a resolve_rule
-- amendment leaves it reading the row's CREATION date unless the statement sets it. The repo
-- convention is to set it: bigquery/228 bumps it on all seven of its UPDATEs, for documentation prose
-- with exactly this audience ("only documentation prose that humans and triage sessions read"), and
-- where a no-bump IS wanted an author says so explicitly -- bigquery/94 writes `updated_ts =
-- updated_ts` because that statement is a deliberate never-matching drift guard. The
-- artifact_version_drift lineage is the outlier: 187 inserted the row on 2026-09-06, 188 and 242 then
-- amended resolve_rule without touching the stamp, and as of this fire the LIVE row read
-- `updated_ts = 2026-09-06 03:34:02 MT` over text containing "CORRECTION 2026-09-15".
--
-- WHY IT IS WORTH A LINE RATHER THAN A SHRUG. It is self-undercutting in the narrowest possible way:
-- 242's stated reason for writing to the policy row at all -- restated by this file -- is that the row
-- is a TRIAGE SURFACE read by a session looking at an alert board rather than at AR_orc's section. A
-- session that sorts or filters that table by updated_ts to find recently-changed policy would not see
-- this row, which is precisely the discoverability the whole lineage exists to buy. The staleness is
-- not silent (the correction dates are in the text a reader is already reading), so this is hygiene
-- and not a gate, and the three prior stamps are deliberately NOT backfilled: their dates are gone,
-- inventing them would be worse than the gap. THE LIVE ROW WAS BUMPED BY A SEPARATE ONE-OFF STATEMENT
-- this same run, because by the time the omission was noticed this file's own guard had already
-- consumed -- the CORRECTION text was present, so re-applying the file is the intended no-op and would
-- never have reached the stamp: `UPDATE ops.alert_policy SET updated_ts = CURRENT_TIMESTAMP() WHERE
-- category = 'artifact_version_drift' AND resolve_rule LIKE '%CORRECTION 2026-09-23%' AND updated_ts <
-- TIMESTAMP('2026-09-23 00:00:00', 'America/Denver')`, 1 row affected. That statement is deliberately
-- NOT reproduced as a second executable block below: on a clean DR replay the UPDATE above does both
-- halves in one statement, so a second bump would be dead code guarded on a condition replay can never
-- satisfy. DO NOT add an updated_ts bump to 187, 188 or 242 retroactively -- each is guarded on
-- its own appended text being absent, so an edit to their literals can never reach the live row again
-- and would only desynchronise the landed record from what was actually applied.
