# BigQuery connector de-auth, 2026-11-22: the W1 slot's halt record

**Status: HALT RECORD, CLOSED as a run. Nothing was written to BigQuery.** There is no `ops.run_log` row (not even `started`), no `ops.web_calls` row and no `ops.alerts` row. `Weekly_Catalyst_Calendar.md` was NOT overwritten; it still carries the prior cycle's content and ISO-week marker. Author: Claude (agent), W1 (Catalyst Calendar, Strategies A and C) slot of 2026-11-22, fired on schedule (cron `30 7 * * 0`).

**This is the incident's per-incident repo record.** W1 is the first slot to detect this outage (see §2), so later slots should append their accounts here (one `## <slot> slot, <date>: HALTED` section each) and keep the calendar event's description short.

**Read first:** `Claude_Task_Plan.md` §Observability → connector pre-flight → BigQuery unreachable branch and the FLEET CONNECTOR-DOWN DISPOSITION TABLE (W1 row: HALT, `catchup_safe`); `ops/RUNBOOK.md` §26 / §48. Precedent: `bigquery-deauth-2026-10-20-ops1-halt-record.md`.

---

## 1. What happened

- **Clock at pre-flight:** UTC `2026-11-22 07:39`, **Denver `2026-11-22 00:39 MST` (Sunday)**. The operating-plane date is **2026-11-22**.
- **Signature:** the first BigQuery call (the pre-flight `state.trading_day_today` read combined with the SAME-DAY DOUBLE-RUN GUARD read of `ops.run_log`) returned `MCP server "Google-Cloud-BigQuery" needs you to sign in again (run /mcp to re-authenticate)`. One reconnect (tool reload, then the same read) returned the same error. As a diagnostic only, `bq query` with the session's ambient CLI credentials returned `Invalid Credentials` (`gcloud auth list`: no credentialed accounts). That is not the connector's credential, and W1 would not write through it. This is the re-auth class, which is non-waitable, so no retry ladder was run.
- **Consequence for the double-run guard:** it could not be evaluated. Whether a prior W1 fire completed today is UNKNOWN; none is expected (OPS0/OPS2 catch-up fire later in the day).

## 2. Bracketing the onset

- **Last known-good:** not established from git. The most recent `origin/main` commits (2026-11-20 13:12Z `30e9f8a3`, then the 2026-11-21 Dependabot merges `d0b5d7ff`/`87119ec1`/`4c129883`) do not need BigQuery, so they bracket nothing.
- **First detection:** this slot, at **00:39 MST on 2026-11-22**.
- **No `[Claude] ATTENTION — RE-AUTH BigQuery connector` event existed** for 2026-11-19 to 11-25 (full-text list search for "RE-AUTH BigQuery" and a semantic search, both at 00:39 MST, found none). This slot created it: event id `4okrus27i276s7ac953obvhs6s`, 00:50–01:20 MST on 2026-11-22, popup and email reminders at 0 min.

## 3. Disposition, and what this fire deliberately did NOT do

- **HALTED** per the disposition table's W1 row. W1's inputs (`state.open_queue`, `events.decision_log`, D1 `research-screen` records, `ops.run_log` for the CATALYST-GATE MODE STEP 1 gate date, `state.open_queue_detail`, `state.market_calendar`) and its owed writes (`ops.web_calls`, run logging) are all BigQuery.
- **No web research was done.** No Parallel `web_search`/`web_fetch`, FMP, IBKR or HF call was made by the orchestrator or any sub-agent (none were spawned). **METERED SPEND: ZERO**, so no `ops.web_calls` row is owed for today. The FMP pull was deliberately not issued because every metered call owes an `ops.web_calls` row that cannot be written while BigQuery is down.
- **`Weekly_Catalyst_Calendar.md` was not rewritten.** Its first line is still the previous cycle's marker `2026-W46`, so W4's upstream-freshness gate will correctly see W1 as not fresh for 2026-W47 rather than reading a half-built calendar.
- **No `ops.run_log` backfill is owed or licensed after re-auth.** W1 is `catchup_safe: true`, so the catch-up path (OPS2's inline executor, fed by `state.catchup_refire_readiness`; OPS0 STEP 2 as fallback) replays the missed slot once BigQuery is back. W1's own SAME-DAY DOUBLE-RUN GUARD makes that replay a clean single run.
- **Never read as a quiet week:** this fire makes no claim about this week's catalysts, the A-queue census or the gate date. All are UNKNOWN.

## 4. Operator action

Re-authorize the Google-Cloud-BigQuery connector in claude.ai connector settings, then resolve per RUNBOOK §26. BigQuery-dependent slots that fire before then will halt or degrade under their own limbs: today W2, W3, W4, W5 and OPS2/OPS0 halt; D1 degrades.

## 5. Recovery procedure

- **Replay order:** W1 (own catch-up via `catchup_safe`), then its declared dependent **W4** (`ops/cadence.yaml` `depends_on: [W1, W2, W3]`): own catch-up loop; recovers once the upstream's catch-up lands (W4 also waits on W2 and W3, which halt on the same outage).
- **Expected signature after re-auth:** no W1 `run_log` row for 2026-11-22 until the catch-up replays it; `Weekly_Catalyst_Calendar.md` stale at the prior ISO week until then. Cadence/period-watch dead-man switches may record the gap, and W4's dependency gate may hold. That is expected, not a fresh fault.

## Unfiled findings

- None new. `ops.alerts` is unreachable, so nothing was filed.
