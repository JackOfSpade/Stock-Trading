-- Pin the READ SCOPE of artifact_version_drift's resolve marker in ops.alert_policy.
-- Project: stock-trading-498512. UPDATEs one existing ops.alert_policy row's resolve_rule text.
-- CREATES NO OBJECT, REPLACES NO PROCEDURE, no scheduled-query version bump. Idempotent: the
-- UPDATE is guarded on the OLD text still being present, so re-applying this file is a no-op.
--
-- WHY THIS IS A SEPARATE FILE AND NOT AN EDIT TO bigquery/187. That file's INSERT is guarded by
-- NOT EXISTS on (category), which is correct for its own re-apply safety but means editing its
-- literal can never reach the live row once the row exists — and it has existed since 2026-08-19.
-- Editing 187 in place would silently desync the repo's declared text from live state, which is
-- the opposite of what a triage surface is for. Apply-in-order replay stays correct: 187 inserts,
-- 188 corrects.
--
-- ===================== WHY: THE MARKER WAS WRITABLE BUT NOT READABLE =====================
-- 187 fixed WHERE the close is stated (Step 1.5's withhold branch -> Step 5, the branch that
-- actually executes it). It did not pin WHICH ROW the close reads the marker off, and neither did
-- Claude_Task_Plan.md, which said only "Read THIS cycle's queue payload".
--
-- MEASURED 2026-08-20 (AR_orc's own fire, a no-op day on the review queue):
--   Step 1.5's re-enqueue writes payload.artifact_moved='true' onto the NEW 'pending' queue row.
--   AR_att then consumes that row and inserts its OWN 'attacker-complete' row for the same
--   item_key and the same cycle_number, carrying its own payload keys and NOT artifact_moved --
--   correctly, since the marker is no part of AR_att's contract and nothing told it to copy one
--   forward. state.open_queue / state.open_queue_detail expose only the LATEST status row per
--   item_key, so from that moment the marker is invisible to every row-scoped read.
--
--   premortem-C-2026-a3 cycle 15 : 2 PENDING_REVIEW rows (pending | attacker-complete), marker on 1
--   premortem-E-2026-a3 cycle 11 : 2 PENDING_REVIEW rows (pending | attacker-complete), marker on 1
--   JSON_VALUE(payload,'$.artifact_moved') off state.open_queue_detail : NULL for BOTH.
--
-- The drift gate first fired 2026-08-19 and its resolve half had never once executed. The
-- 2026-08-21 fire takes the gate's *equal-SHA* branch (strategy/08_pre_mortems.md is still at
-- 60878d6d) -- precisely the case the Step 5 close was written for -- and a row-scoped read would
-- have found no marker and left alerts a8992f43 and 8eb5f355 open permanently. First execution,
-- silent no-op. THE MARKER IS A PROPERTY OF THE CYCLE Step 1.5's re-enqueue created, NOT of any one
-- row inside it.
--
-- THE FIX IS ON THE READ SIDE, DELIBERATELY. Do NOT close this by asking AR_att to propagate the
-- key forward: that makes every writer responsible for carrying every other routine's markers and
-- fails silently the first time one is missed. Scope the READ to the cycle, at the site that owns
-- the close. This also makes the read CONSISTENT with the only two sibling markers in the same
-- routine -- Step 0.5's echo_suspect_cooloff lifetime-cap count and Step 3.5's echo_suspect_requeue
-- prior-count -- which already query events.queue_events directly rather than any latest-row view,
-- which is exactly why neither has ever exhibited this failure. artifact_moved was the lone AR_orc
-- marker read through a latest-row surface.
--
-- SWEEP (2026-08-20, same fire): every alert-resolve site in Claude_Task_Plan.md was checked for
-- this class. No other instance. The remaining sites key off the ALERT row's own payload, off a
-- freshly-recomputed live view, or off a full events.queue_events scan -- none of which a later
-- status-transition row can hide. One adjacent (different-class) gap was found and fixed in the
-- same commit: upstream_marker_mismatch named its close in prose but never stated the UPDATE.
--
-- CORRECTED IN PART by bigquery/242_echo_suspect_cooloff_marker_read_scope.sql (2026-09-15). The
-- sweep result just above is INCOMPLETE and the sibling-marker sentence at lines 40-44 clears two
-- SITES, not two MARKERS: echo_suspect_cooloff has a second reader -- AR_orc Step 4's ECHO-SUSPECT
-- COOL-OFF RESOLVE -- whose UPDATE predicate is sound (which is why this sweep passed it) but whose
-- entry condition named no query and was row-scoped by default. A resolve site is its entry
-- condition AND its predicate. Read 242's header before trusting either claim; this file's body is
-- left unmodified as the apply-in-order record.

UPDATE `stock-trading-498512.ops.alert_policy`
SET resolve_rule = CONCAT(
      resolve_rule,
      ' READ SCOPE OF THE MARKER -- PINNED 2026-08-20, CYCLE-SCOPED, NEVER ROW-SCOPED: read '
      'payload.artifact_moved across EVERY events.queue_events row for THIS item_key at THIS '
      'cycle_number -- SELECT COUNTIF(JSON_VALUE(payload,\'$.artifact_moved\')=\'true\') > 0 FROM '
      'events.queue_events WHERE queue=\'PENDING_REVIEW\' AND item_key=<review id> AND '
      'CAST(JSON_VALUE(payload,\'$.cycle_number\') AS INT64)=<cycle> -- and specifically NOT off the '
      'single row the fire consumed and NOT off state.open_queue / state.open_queue_detail. WHY: '
      'Step 1.5\'s re-enqueue writes the marker on the new \'pending\' row; AR_att then inserts its '
      'own \'attacker-complete\' row for the same item_key and cycle_number without the key (it is '
      'no part of AR_att\'s contract), and the open_queue views expose only the LATEST status row '
      'per item_key, so a row-scoped read sees NULL. MEASURED 2026-08-20: premortem-C-2026-a3 '
      'cycle 15 and premortem-E-2026-a3 cycle 11 each had 2 rows with the marker on 1, and '
      'open_queue_detail returned NULL for both -- the first close this category was ever due to '
      'perform would have silently no-opped and left alerts a8992f43 / 8eb5f355 open forever. THE '
      'MARKER IS A PROPERTY OF THE CYCLE, NOT OF A ROW. Do NOT fix this on the write side by having '
      'AR_att propagate the key -- that makes every writer own every other routine\'s markers and '
      'fails silently the first time one is missed. This read matches AR_orc\'s two sibling markers '
      '(echo_suspect_cooloff, echo_suspect_requeue), which already scan events.queue_events '
      'directly and have never exhibited this failure.')
WHERE category = 'artifact_version_drift'
  AND resolve_rule NOT LIKE '%READ SCOPE OF THE MARKER%';
