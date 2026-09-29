# BigQuery connector de-auth, 2026-09-28: the AR_orc slot's halt record

**Status: HALT RECORD, CLOSED as a run. Nothing was written to BigQuery.** There is no `ops.run_log` row (not even `started`), no `sp_assert_deps` evaluation, no `events.adversarial_reviews` transcript, no `events.queue_events` transition, no `events.decision_log` entry and no `ops.alerts` row. Author: Claude (agent), AR_orc (Adversarial Review Orchestrator) slot of 2026-09-28, fired on schedule.

**This is the incident's per-incident repo record.** AR_orc is the first slot to detect this outage (see §2), so later slots should append their accounts here (one `## <slot>` section each) and keep the calendar event's description short. That follows the §Observability pre-flight bullet's 8,192-character-cap guidance.

**Read first:** `Claude_Task_Plan.md` §Observability → connector pre-flight; §Adversarial Review Attacker → CONNECTOR-DOWN DISPOSITION (its cascade paragraph binds this routine); §Adversarial Review Orchestrator → UPSTREAM-HALT LIMB; `ops/RUNBOOK.md` §15 / §26. Precedent: the 2026-09-21 records `bigquery-deauth-2026-09-21-*.md`.

---

## 1. What happened

- **Clock at pre-flight:** UTC `2026-09-29 00:36`, **Denver `2026-09-28 18:36` (Monday)**. The operating-plane date is **2026-09-28**, and this file is named for that date rather than the UTC date.
- **Signature:** the BigQuery MCP tools loaded normally, but every call returned `MCP server "Google-Cloud-BigQuery" needs you to sign in again (run /mcp to re-authenticate)`. The first call was the dependency gate `CALL ops.sp_assert_deps('AR_orc', ['AR_att'], …)`, and the one diagnostic probe `SELECT 1` failed identically. That puts this in the token-expired / re-auth class, which the TRANSIENT-FAILURE bullet marks **non-waitable**, so no retry ladder was run. The signature differs from 2026-09-21, when the tools were not exposed at all; the disposition is the same.
- **Not the RUNBOOK §54 platform `403 authentication_failed` class.** That failure kills the session. This session stayed alive, and the Calendar connector worked.

## 2. Bracketing the onset

- **Last known-good:** D2 landed `6747d44` on `origin/main` at `2026-09-28 23:21:21 UTC` (**17:21 MDT**). D2 needs canonical BigQuery state, so the connector was live then.
- **First detection:** this slot, at **18:36 MDT**.
- **AR_att (18:00 MDT):** `origin/main` has no AR_att commit and no halt record after `6747d44`, and there is no other remote branch. That fits two cases that git cannot tell apart: (a) a healthy, quiet AR_att fire, which commits nothing when the lane is empty, or (b) a halt that also failed to land its record. Its status is **UNKNOWN**, and nothing here should be read as either outcome.
- **No `[Claude] ATTENTION — RE-AUTH BigQuery connector` event existed** for 2026-09-27 to 09-30 (Calendar full-text search at 18:36 MDT). This slot created it: event id `lm3n7i64nso4babvjk9vn22nm8`, placed 19:00–19:30 MDT on 2026-09-28 with popup and email reminders.

## 3. Disposition, and what this fire deliberately did NOT do

- **HALTED.** Nothing in this routine can run without BigQuery. The dependency gate, STEP 0 reconciliation, STEP 0.5 park read, due scan, RESIDUAL SWEEP, attacker-transcript fetch, `sp_write_adversarial_review`, every Step 4 write and `ops.run_log` are all BigQuery. The AR_att limb's cascade paragraph covers this routine explicitly.
- **The review lane is UNKNOWN, not empty.** The most recent measurement anyone has (2026-09-21) found 0 `pending` and 0 `attacker-complete` rows. That is a base rate, not a reading of today's lane, and this fire claims no quiet day.
- **No `run_log` backfill is owed or licensed.** After re-auth, do NOT insert a `completed` row for this slot from this commit. RUNBOOK §48's convention (a halt-record subject does not lead with the routine id) exists so the marker parser mints nothing for it. The missed slot is recorded by the freshness and cadence dead-man switches once BigQuery returns.
- **No replay is required from OPS0.** AR_att is `catchup_safe: false`, and the next ordinary AR_att → AR_orc pair picks up whatever the lane holds, because due predicates are `<= today`.
- **No new finding filed.** The fleet-wide gap this outage exposes again is that the pre-flight's BigQuery-unreachable branch has no per-class disposition table, so each routine derives its own. It is already recorded with owner **W5 SPEC-DEFECT NOTICE INTAKE or OPS0** (§Observability pre-flight bullet, 2026-09-21), and `ops.alerts` is unreachable anyway. This record cites that owner and does not file it again.

## 4. Operator action

Re-authorize the Google-Cloud-BigQuery connector in claude.ai connector settings, then resolve per RUNBOOK §26. BigQuery-dependent slots that fire before then (D3 tonight, OPS2/OPS0, D2a/D2 tomorrow) will halt under their own limbs.

---

## D3 (Calendar Hygiene) slot, 2026-09-28: HALTED

- **Clock at pre-flight:** UTC `2026-09-29 00:45`, **Denver `2026-09-28 18:45` (Monday)**. D3 fired on its regular schedule. **Nothing was written to BigQuery.** There is no `ops.run_log` row, and the SAME-DAY DOUBLE-RUN GUARD, the queue terminal-entry sweep, self-heal, CI-findings adjudication, the golden-scenario prose-regression check and every other step were not run.
- **Signature (different from AR_orc's 36 minutes earlier):** the BigQuery MCP server was **not exposed at all** in this session. The harness listed `Google-Cloud-BigQuery` as "requires authentication", which is the 2026-09-21 signature and not AR_orc's "sign in again" one. As a second check, a direct REST `jobs.query` using the session's ambient `CLOUDSDK_AUTH_ACCESS_TOKEN` returned `401 UNAUTHENTICATED / CREDENTIALS_MISSING`. That token is not the connector's credential and D3 would not write through it, so the call was only a diagnostic probe. Both results put this in the re-auth class, which is non-waitable, so no retry ladder was run.
- **Disposition:** under §Observability connector pre-flight, "D2/D2a/D3 require canonical state → HALT cleanly". D3's only other connector is Calendar, and its routine calendar writes depend on BigQuery state, so no partial run was attempted.
- **Calendar:** no second event was created. The existing event `lm3n7i64nso4babvjk9vn22nm8` was amended in place with one short `UPDATE 18:48 MDT` line (about 1.6 KB in total, well under the 8,192 cap), and the notification level was set to NONE.
- **After re-auth:** do NOT backfill a `completed` `run_log` row for this slot. The cadence and freshness dead-man switches record the miss. D3's next regular fire picks up the queue sweep, since its predicates are `<= today`, and the golden-scenario check will cover the missed day, because its `git log --since=` window keys off D3's last *completed* run.
- **No new finding filed.** The fleet-wide disposition-table gap is already owned by W5 SPEC-DEFECT NOTICE INTAKE / OPS0 (see §3 above).

---

## SL5 (Strategy Register & Roster Sync) slot, 2026-09-28: HALTED

- **Clock at pre-flight:** UTC `2026-09-29 01:26`, **Denver `2026-09-28 19:26` (Monday)**. SL5 fired on its regular trigger (`25 1 * * 1-5` UTC). **Nothing was written to BigQuery**, and nothing was changed in `strategy/roster.yaml`, `Strategy.md` or the `strategy/` slices. There is no `ops.run_log` row. The arsenal kill-switch gate (`sp_assert_arsenal_enabled`), the dependency gate (`sp_assert_deps('SL5', ['AR_orc'], …)`), the start-log and all three dispatch scans were not run: SHADOW-register off `state.strategy_adoption_readiness`, PROBE-register off the `PENDING_ROSTER` lane, and TERMINATED-deregister off `events.strategy_lifecycle`.
- **Signature:** the same as D3's. The Google-Cloud-BigQuery MCP server was **not exposed at all**. The harness listed it as "requires authentication", and a tool search for it returned nothing. This is the re-auth class, which is non-waitable, so no retry ladder was run.
- **Disposition: HALTED, and the roster-mutation queue is UNKNOWN, not empty.** SL5 cannot run without BigQuery. Every input and every write goes through it, including roster membership (`state.strategy_roster`), and the dependency gate must run before anything else. SL5's section forbids concluding "no roster mutations due" without a gate that passed, so this fire reports no quiet day. Even with BigQuery up, the gate would have failed: AR_orc halted at 18:36 with no `run_log` row, which is the §Observability upstream-halt-invisible case. That is moot here, because SL5 never reached its gate.
- **Calendar:** no second event was created. The existing event `lm3n7i64nso4babvjk9vn22nm8` was amended in place with one `UPDATE 19:27 MDT` line (about 2.0 KB in total, re-read and intact), with notification level NONE. That thread shows that SL2 (19:05 MDT) also halted and added a 19:06 line. SL2 has no repo record on `origin/main`.
- **After re-auth:** do NOT backfill a `completed` `run_log` row for this slot. SL5 is queue-driven and `catchup_safe: false`, so no OPS0/OPS2 replay is owed. Its next regular fire (Tue 2026-09-29, 19:25 MT) picks up any due item, because the `PENDING_ROSTER` scan's due predicate is `due_date <= today`. `state.stalled_runs` records the miss.
- **No new finding filed.** SL5's section has no CONNECTOR-DOWN DISPOSITION limb of its own. That is one more instance of the fleet-wide disposition-table gap, which is already owned by W5 SPEC-DEFECT NOTICE INTAKE / OPS0 (see §3 above), and `ops.alerts` is unreachable anyway.

---

## SL3 (Incubation Monitor & Graduation) slot, 2026-09-28: HALTED

- **Clock at pre-flight:** UTC `2026-09-29 02:11`, **Denver `2026-09-28 20:11` (Monday)**. SL3 fired on its regular Sun–Thu schedule. **Nothing was written to BigQuery.** There is no `ops.run_log` row. The arsenal kill-switch read, the dependency gate on D2a, STEP 1's marks catch-up loop, the SHADOW→PAPER graduation evaluation, the STEP 3 `ops.roster_change_log` marker, the STEP 4 `cooldown_until` stamp and the STEP 5 regime-coverage read were not run.
- **Signature:** the same as D3's and SL5's. The Google-Cloud-BigQuery MCP server was **not exposed at all** (harness listed it as "requires authentication"; a tool search for BigQuery tools returned nothing). A diagnostic-only REST `jobs.query` `SELECT 1` with the session's ambient token returned `401`. Re-auth class, non-waitable, so no retry ladder was run.
- **Disposition: HALTED, and the SHADOW/PAPER incubation state is UNKNOWN, not quiet.** SL3 promotes nothing and reports no graduations without a passed gate and fresh readiness views. It touches no capital, so the halt carries no order-side exposure.
- **Recoverable, unlike AR_orc/SL5:** SL3 is `catchup_safe: true` and owns STEP 1's multi-day catch-up loop, so its next fire with BigQuery live re-covers 2026-09-28, provided a `state.daily_marks_curated` row exists for that day (D2a ran before the 17:21 MDT D2 commit, so it should). No manual replay is owed.
- **Calendar:** no second event. The existing event `lm3n7i64nso4babvjk9vn22nm8` was amended in place with one `UPDATE 20:15 MDT` line (about 2.4 KB total, re-read and intact), notification level NONE.
- **After re-auth:** do NOT backfill a `completed` `run_log` row for this slot; the cadence and freshness dead-man switches record the miss.
- **No new finding filed.** SL3's section already carries its own connector/dependency-halt limb, and the fleet-wide disposition-table gap is owned by W5 SPEC-DEFECT NOTICE INTAKE / OPS0 (see §3 above); `ops.alerts` is unreachable anyway.

## OPS2 (Catch-up Executor) slot, 2026-09-28: BigQuery REACHABLE again, catch-up path running

- **Connector state at 22:16 MDT:** the Google-Cloud-BigQuery MCP tools were exposed and answered `state.trading_day_today` on the first call (no retry, no auth error). IBKR, Calendar and Gmail also answered. So the connector was re-authorized, or recovered, at some point between SL3's 20:15 MDT halt and 22:16 MDT. This record cannot say which, or who did it.
- **Miss feed:** `state.catchup_refire_readiness` held two rows, `D3|2026-09-28` and `SL3|2026-09-28`. It held no AR_orc, SL2 or SL5 rows, which is correct: those three are not `catchup_safe` and their next regular fire picks up. The AR_att row the calendar event lists as UNKNOWN is resolved: `ops.run_log` shows AR_att `completed` at 18:16 MDT, before the de-auth.
- **SL3: CAUGHT UP INLINE by OPS2.** Both gates passed. There are 0 SHADOW/PAPER members, so no transition and no cull. The heartbeat was written, and the completion was verified before the `ops.catchup_refire_log` row was written.
- **D3: DEFERRED, not run.** D3's own section calls `create_order_instruction`, so OPS2's order-craft slice-scan excludes it by design. It is left for OPS0's 22:30 MT `catchup_refire_blocked` email: the operator re-runs D3 through its own trigger.
- **AR_orc, SL2, SL5:** no replay is owed (per the disposition table). Their next regular fires pick up the queue.

## D3 (Calendar Hygiene) re-run, 2026-09-28: COMPLETED

- **Clock:** started 22:27 MDT on 2026-09-28 (04:27 UTC on 2026-09-29). This was the re-run through D3's own trigger that OPS2 deferred it to. The BigQuery MCP answered on the first call. `sp_assert_deps('D3', ['D2'])` passed and the SAME-DAY DOUBLE-RUN GUARD read 0, so this session is the day's only D3 completion. It does not backfill the halted 18:45 slot.
- **Calendar:** both leftover `[Claude] ATTENTION — RE-AUTH BigQuery connector` events were deleted, because this session's own pre-flight is the evidence the D3 bullet requires. They are `lm3n7i64nso4babvjk9vn22nm8` (this incident) and `09q69g3odvhhbiom3drf15uc60` (the 2026-09-21 incident, still on the calendar a week later). Both deletes used notification NONE.
- **Result:** IBKR has no instructions and no working orders, and `state.open_orders` is empty. The queue has no past-due items. All check views (ops0 fallback, CI findings, promotion ladder, sq drift) are clean.
- **One real action:** the Tier-M model-of-record sync `claude-opus-5` → `claude-opus-5-5` in `AI_Trading_Foundation.md`, at rev 10. This is the sync that commit `8bcaba5` deliberately left for D3. See `events.decision_log` `foundation-change-review` 2026-09-28.
