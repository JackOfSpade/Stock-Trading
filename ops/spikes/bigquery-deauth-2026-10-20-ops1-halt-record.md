# BigQuery connector de-auth, 2026-10-20: the OPS1 slot's halt record

**Status: HALT RECORD, CLOSED as a run. Nothing was written to BigQuery.** There is no `ops.run_log` row (not even `started`), no `ops.connector_tool_inventory` rows, no `ops.web_calls` row and no `ops.alerts` row. Author: Claude (agent), OPS1 (Morning Connector Liveness Probe) slot of 2026-10-20, fired on schedule.

**This is the incident's per-incident repo record.** OPS1 is the first slot to detect this outage (see §2), so later slots should append their accounts here (one `## <slot>` section each) and keep the calendar event's description short.

**Read first:** `Claude_Task_Plan.md` §Observability → connector pre-flight → BigQuery unreachable branch and the FLEET CONNECTOR-DOWN DISPOSITION TABLE (OPS1 row: HALT, `catchup_safe`); `ops/RUNBOOK.md` §15 / §26. Precedent: `bigquery-deauth-2026-10-05-ops2-halt-record.md`.

---

## 1. What happened

- **Clock at pre-flight:** UTC `2026-10-20 12:35`, **Denver `2026-10-20 06:35` (Tuesday)**. The operating-plane date is **2026-10-20**.
- **Signature:** the BigQuery MCP tools loaded, but the first call (the pre-flight `state.trading_day_today` read, combined with the SAME-DAY DOUBLE-RUN GUARD read) returned `MCP server "Google-Cloud-BigQuery" needs you to sign in again (run /mcp to re-authenticate)`. The one allowed diagnostic `SELECT 1` returned the same error. As a diagnostic only, `bq query` with the session's ambient CLI credentials returned `Invalid Credentials` (`gcloud auth list`: no credentialed accounts). That is not the connector's credential, and OPS1 would not write through it. This is the re-auth class, which the TRANSIENT-FAILURE bullet marks **non-waitable**, so no retry ladder was run.

## 2. Bracketing the onset

- **Last known-good:** SL3 landed `288982a` on `origin/main` at **20:16 MDT on 2026-10-19**, and SL3 needs BigQuery. An interactive commit `69ae867` at **23:11 MDT** (bigquery/261, 262) probably also had the connector live. That is inferred from its subject; it was not verified.
- **OPS2 (22:15 MT) and OPS0 (22:30 MT) on 2026-10-19** landed nothing on `origin/main`. Both can legitimately land nothing, so their status is **UNKNOWN** from git alone.
- **First detection:** this slot, at **06:35 MDT on 2026-10-20**.
- **No `[Claude] ATTENTION — RE-AUTH BigQuery connector` event existed** for 2026-10-18 to 10-22. A full-text search for "RE-AUTH BigQuery" and a title search, both at 06:36 MDT, found none. This slot created it: event id `fp4q99provs98frj45j93ou4t0`, 06:45–07:15 MDT on 2026-10-20, with popup and email reminders at 0 min.

## 3. What OPS1 could still observe (read-only, no BigQuery)

These results are informational only. None of them was written to BigQuery.

- **IBKR:** `get_account_summary` PASS, and `get_price_snapshot` for SPY (conid 756733, after a `search_contracts` lookup) PASS: structurally valid.
- **Google Calendar:** `list_calendars` PASS.
- **Gmail:** `list_labels` PASS.
- **FMP `^VIX` probe:** **deliberately NOT issued.** It is a metered call, and every call owes an `ops.web_calls` row that cannot be written while BigQuery is down. Skipping it creates no unlogged spend, so **no `ops.web_calls` row is owed for today.** METERED SPEND: ZERO. Neither the orchestrator nor any sub-agent made a Tavily, web_search, web_fetch, FMP or HF call.
- **Tool inventory:** the session's deferred-tool listing matched `ops/connector_tools.yaml` exactly. All 124 manifest tools across the 7 connectors were present, with **no `added` and no `removed` drift** and no reappeared `absent:` entry. BigQuery's 9 tools were listed, although the server is unauthenticated. No manifest edit is needed and none was made. Because `ops.connector_tool_inventory` cannot be written, this has to be re-observed on OPS1's next completed run.
- **Net:** BigQuery is the only connector down. IBKR is live for tonight's cadence.

## 4. Disposition, and what this fire deliberately did NOT do

- **HALTED** per the disposition table's OPS1 row. OPS1's outputs are all BigQuery: `ops.alerts` (raise and self-heal), `ops.connector_tool_inventory`, `ops.web_calls`, and run logging.
- **No `ops.run_log` backfill is owed or licensed after re-auth.** OPS1 is `catchup_safe: true`, so the catch-up path (OPS2's inline executor, fed by `state.catchup_refire_readiness`) replays the missed slot once BigQuery is back. OPS1's own SAME-DAY DOUBLE-RUN GUARD makes that replay a clean single run.
- **Never read as a quiet day:** this fire does not claim "all connectors OK" or "no drift" as a run outcome. Today's alert state is UNKNOWN.

## 5. Operator action

Re-authorize the Google-Cloud-BigQuery connector in claude.ai connector settings, then resolve per RUNBOOK §26. BigQuery-dependent slots that fire before then will halt or degrade under their own limbs: D1 (16:10 MT) degrades; D2a, D2, D3, SL2, SL3, AR_att/AR_orc, OPS2 and OPS0 halt.

## 6. Recovery procedure

- **Replay order:** OPS1 only. It has no declared dependents: no routine in `ops/cadence.yaml` names OPS1 in `depends_on`. The replay comes from the catch-up path, so no manual re-run is needed.
- **Expected signature after re-auth:** no OPS1 `run_log` row for 2026-10-20 until the catch-up replays it. The freshness and cadence dead-man switches may record the gap, and that is expected, not a fresh fault.

## Unfiled findings

- None new. `ops.alerts` is unreachable, so nothing was filed.

---

## M1R slot, 2026-10-20: HALTED

- **Clock at pre-flight:** UTC `2026-10-20 13:09` (scheduled 13:05:57), **Denver 07:09 MDT**. Operating-plane date **2026-10-20**. Trigger `trig_01R6YpUzw3pk7UEeWB5Bdtvq`.
- **Signature:** the Google-Cloud-BigQuery MCP server was listed as **requiring authentication** at session start. None of its tools were exposed, so the pre-flight `state.trading_day_today` read could not be issued through the connector at all. As a diagnostic only, `bq query --project_id=stock-trading-498512` with the ambient CLI credentials returned `Invalid Credentials`, the same as OPS1 saw. This is the re-auth class, which is **non-waitable**, so no retry ladder was run. The outage still held 34 minutes after OPS1's detection.
- **Disposition:** HALT, per the FLEET CONNECTOR-DOWN DISPOSITION TABLE's M1R row (M1R has no limb of its own).
- **What this fire did NOT do:** it ran no STEP 1 gate read, so whether a `PENDING_REGIME_REFRESH` `regime-refresh` item is open is **UNKNOWN, not empty**. It emits no "No open regime-refresh item" line. It ran no STEP 2a event sweep and made no metered call, so **METERED SPEND: ZERO** and no `ops.web_calls` row is owed. It wrote no `events.regime_events` or `events.queue_events` row and resolved no `rerisking_limb_fired` alert. It wrote no `ops.run_log` row (not even `started`). Under the blinding rules it read no strategy material; beyond the plan, its file reads were this record and `ops/cadence.yaml`.
- **Calendar:** no second event was created. One line, `UPDATE 07:12 MDT M1R halted …`, was appended to event `fp4q99provs98frj45j93ou4t0`. The description was well under the 8,192-character cap and ended cleanly before the append.
- **After re-auth:** M1R is queue-driven and `catchup_safe: true`, so the catch-up path replays the slot. Its STEP 1 due predicate is `due_date <= today`, so an item that was open today is still picked up by the replay or by the next regular fire (Wed 2026-10-21 07:00 MT). No `ops.run_log` backfill is owed.
- **Recovery procedure:** no routine in `ops/cadence.yaml` names M1R in `depends_on`, so no dependent needs a replay. D2 picks up a new `FUNDAMENTAL_AXIS` row the same evening only if M1R has run by then. That is a reading relationship, not a declared dependency, and D2 halts anyway while BigQuery is down. **Expected signature:** no M1R `run_log` row for 2026-10-20 until the catch-up replays it. A `queue_driven_missed_fire` warning for M1R/2026-10-20 from `state.queue_driven_missed_fire_watch` is expected, not a fresh fault.

### Unfiled findings (M1R slot)

- None new.
