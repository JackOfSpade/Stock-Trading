# BigQuery connector de-auth, 2026-10-05: the OPS2 slot's halt record

**Status: HALT RECORD, CLOSED as a run. Nothing was written to BigQuery.** There is no `ops.run_log` row (not even `started`), no STEP 0 marker self-heal, no `state.catchup_refire_readiness` read, no `ops.catchup_refire_log` row, no `events.decision_log` entry and no `ops.alerts` row. Author: Claude (agent), OPS2 (Catch-up Executor) slot of 2026-10-05, fired on schedule.

**This is the incident's per-incident repo record.** OPS2 is the first slot to detect this outage (see §2), so later slots should append their accounts here (one `## <slot>` section each) and keep the calendar event's description short.

**Read first:** `Claude_Task_Plan.md` §Observability → connector pre-flight → BigQuery unreachable branch and the FLEET CONNECTOR-DOWN DISPOSITION TABLE (OPS2 row: HALT); `ops/RUNBOOK.md` §15 / §26. Precedent: `bigquery-deauth-2026-09-28-ar_orc-halt-record.md`.

---

## 1. What happened

- **Clock at pre-flight:** UTC `2026-10-06 04:16`, **Denver `2026-10-05 22:16` (Monday)**. The operating-plane date is **2026-10-05**, and this file is named for that date rather than the UTC date.
- **Signature:** the BigQuery MCP tools loaded, but the first call (the pre-flight `state.trading_day_today` read, combined with the SAME-DAY DOUBLE-RUN GUARD read) returned `MCP server "Google-Cloud-BigQuery" needs you to sign in again (run /mcp to re-authenticate)`, the same signature as AR_orc on 2026-09-28. A diagnostic-only `bq query` with the session's ambient CLI credentials returned `Invalid Credentials` (`gcloud auth list`: no credentialed accounts); that is not the connector's credential and OPS2 would not write through it. Re-auth class, which the TRANSIENT-FAILURE bullet marks **non-waitable**, so no retry ladder was run.
- The Calendar connector worked.

## 2. Bracketing the onset

- **Last known-good:** SL3 landed `18f22bc` on `origin/main` at **20:15 MDT** (D1 16:23, D2 17:20, SL2 19:10 also landed). SL3 needs BigQuery, so the connector was live at ~20:00–20:15 MDT.
- **First detection:** this slot, at **22:16 MDT**.
- **D3 (~18:45 MDT):** no D3 commit on `origin/main` today. D3 can legitimately land nothing, so its status is **UNKNOWN** from git alone; it was before SL3's known-good window, so it most likely ran with BigQuery live.
- **No `[Claude] ATTENTION — RE-AUTH BigQuery connector` event existed** for 2026-10-04 to 10-08 (Calendar full-text search at 22:17 MDT). This slot created it: event id `hc7dmisu5jkql9f6cdre9bsags`, 22:30–23:00 MDT on 2026-10-05, popup and email reminders.

## 3. Disposition, and what this fire deliberately did NOT do

- **HALTED** per the disposition table's OPS2 row. Every OPS2 step is BigQuery: the double-run guard, STEP 0 `sp_backfill_run_log_from_markers`, STEP 1 readiness read, STEP 2's in-flight/idempotency re-checks, STEP 2.6's completion verification and suppression row. With no way to verify completion or write `ops.catchup_refire_log`, no routine was hosted inline.
- **The miss feed is UNKNOWN, not empty.** This fire does not claim "no catchup-safe misses."
- **No `run_log` backfill is owed or licensed** after re-auth. OPS2 is `catchup_safe: false`; the next regular fire (Tue 2026-10-06, 22:15 MT) reads the readiness feed, which covers any catchup-safe miss still in window.
- **OPS0 (22:30 MT)** will also halt on the same connector unless it is re-authorized first; its `catchup_refire_blocked` email cannot go out while `ops.alerts` is unreachable.

## 4. Operator action

Re-authorize the Google-Cloud-BigQuery connector in claude.ai connector settings, then resolve per RUNBOOK §26. BigQuery-dependent slots that fire before then (OPS0 tonight; OPS1, D1, D2a, D2 tomorrow) will halt or degrade under their own limbs.

## Unfiled findings

- None new. `ops.alerts` is unreachable, so nothing was filed.
