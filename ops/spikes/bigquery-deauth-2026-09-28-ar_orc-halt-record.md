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
