# The BigQuery MCP connector drops the `query` argument — investigation, localisation, and vendor report

**Status: INVESTIGATION COMPLETE — REPORT READY TO FILE, NOT YET FILED.** Author: Claude (agent),
2026-09-11. This file changes no live BigQuery object and no trigger. It carries (1) the measurements,
(2) the localisation, (3) the settled retry semantics, and (4) a paste-ready vendor report. §7 states
exactly what access is needed to complete the filing and who must do it.

**Read first:** `Claude_Task_Plan.md` §Observability → TRANSIENT-FAILURE WAIT-AND-RETRY (the binding
rule), `ops/RUNBOOK.md` §51 (the durable incident record that points here).

---

## 1. The defect in one paragraph

`mcp__Google_Cloud_BigQuery__execute_sql` and `..._execute_sql_readonly` intermittently return, to the
model, exactly:

```
Required parameter is missing: query
```

for a well-formed call in which `query` WAS supplied and is valid. No BigQuery job is created — no
`queryId`, zero bytes billed, nothing in `INFORMATION_SCHEMA.JOBS_BY_PROJECT`. An immediate
byte-identical re-issue succeeds. It is non-deterministic, silent, and has been reproducing since
2026-08-18.

The **drop** is survivable; one retry clears it. The **message** is the damaging part, and it is a
separate defect with its own consequence — see §5.

## 2. What this session measured (2026-09-11)

All arms below: project `stock-trading-498512`, location US, OAuth under the project owner's own Google
identity, from a Claude Code remote session and its Sonnet subagents. Never retried inside an arm — a
failure was recorded and the arm continued, so these are clean per-call rates.

### 2a. The two SQL-executing tools

| Arm | Caller / emission shape | Tool | Failed / calls | Rate |
|---|---|---|---|---|
| A1+A2 | Opus 5, **batched** (many `tool_use` blocks in ONE assistant message) | `execute_sql_readonly` | 5 / 40 | 12.5% |
| A3 | Opus 5, sequential (one call per turn) | `execute_sql_readonly` | 3 / 12 | 25.0% |
| B | Sonnet 5, sequential | `execute_sql_readonly` | 3 / 30 | 10.0% |
| C | Sonnet 5, sequential | `execute_sql` (non-readonly) | 3 / 30 | 10.0% |
| E1 | Sonnet 5, sequential, **`query` emitted FIRST** | `execute_sql_readonly` | 3 / 30 | 10.0% |
| E2 | Sonnet 5, sequential, **`query` emitted FIRST** | `execute_sql_readonly` | 7 / 30 | 23.3% |
| | | **SUBTOTAL (arms A–E)** | **24 / 172** | **14.0%** |
| H | Sonnet 5, sequential, interleaved with `list_table_ids` | `execute_sql_readonly` | 1 / 20 | 5.0% |
| I | Sonnet 5, sequential, **16,042-char** request body | `execute_sql_readonly` | 2 / 8 | 25.0% |
| I | Sonnet 5, sequential, **25,018-char** request body | `execute_sql_readonly` | 1 / 4 | 25.0% |
| | | **TOTAL (all SQL-tool arms)** | **28 / 204** | **13.7%** |

Every one of the 24 errors was the byte-identical string `Required parameter is missing: query`.
Failures were scattered, never clustered.

### 2b. The controls — same connector, tools WITHOUT a `query` argument

| Arm | Tool | Required params | Failed / calls |
|---|---|---|---|
| F | `list_table_ids` | `projectId`, `datasetId` | **0 / 30** |
| G | `list_dataset_ids` | `projectId` | **0 / 30** |
| H | **interleaved** `list_table_ids` (alternating with `execute_sql_readonly`, same window) | `projectId`, `datasetId` | **0 / 20** |
| H | **interleaved** `execute_sql_readonly` | `projectId`, `query` | **1 / 20** |

Arm H alternated the two tools call-for-call in one window, so both experienced identical conditions.
That eliminates the "the bug is bursty and the control ran during a quiet period" confound: in the same
interleaved window the SQL tool dropped arguments and the sibling tool did not.

Pooling the interleaved arm in, the SQL-executing tools fail **25 / 192 (13.0%)** and the controls
**0 / 80 (0.0%)**. Against a common rate, `0 / 80` is **p ≈ 1.4e-5**; Fisher exact on the pooled
counts gives **p ≈ 1.3e-4** (on the non-interleaved arms alone, 24/172 vs 0/60, p ≈ 8.5e-4).

### 2c. Facts the arms establish

1. **It is not the model's emission.** In arm A2, thirty byte-identical `tool_use` blocks were emitted
   in a *single* assistant message; twenty-five were serviced and five were rejected as missing
   `query`. Same message, same bytes, different outcomes.
2. **It is not positional.** Arms E1/E2 reversed the emission order so `query` was written FIRST and
   `projectId` SECOND. All 10 failures still named `query`. Zero named `projectId`. A "trailing field
   lost during streaming JSON assembly" mechanism is ruled out.
3. **It is specific to the `query` argument.** `projectId` was supplied in all 272 calls of this
   investigation — 192 SQL and 80 control — and was reported missing **zero** times. `query` was
   supplied in all 192 SQL calls and reported missing 25 times.
4. **It is not confined to one model or host.** Opus 5 and Sonnet 5 reproduce it at comparable rates,
   in a Claude Code remote session, and (per `ops.run_log`) in cloud scheduled agent sessions.
5. **It is not request size.** See §4.
6. **The error is indistinguishable from real caller error.** Deliberately calling
   `execute_sql_readonly` with `projectId` and NO `query` returns the byte-identical string. The caller
   therefore cannot tell "you failed to supply `query`" from "`query` was supplied and lost in transit".
   This is the root of the damage in §5.

## 3. Localisation

**The fault is downstream of the model and upstream of BigQuery, in the handling of the `query`
argument on the SQL-execution path.** Supporting the two boundaries:

* *Downstream of the model* — fact (1): identical blocks in one message diverge. Reinforced by facts
  (2) and (3): the model has no reason to omit `query` but never `datasetId`/`projectId`, at similar
  rates across two different models, irrespective of the order it writes them in.
* *Upstream of BigQuery* — no job is ever created for a failed attempt, and the DML case was verified
  non-partial (effect read back as count 0, then the re-issue wrote exactly one row).

**Which vendor owns that span is not determinable from this access path**, and I did not guess. Both
layers are in it:

* The MCP server is **Google's**, fully managed and closed-source, at `https://bigquery.googleapis.com/mcp`
  ("Google Cloud builds and maintains the BigQuery MCP server" —
  https://docs.cloud.google.com/bigquery/docs/use-bigquery-mcp; the connector card at
  https://claude.com/connectors/bigquery says "Made by Google"). The `goog-mcp-server: true` job label
  and the camelCase schema are its fingerprints. It is **not** the open-source `googleapis/mcp-toolbox`,
  which is a different, self-hosted project.
* The **claude.ai MCP broker relaying the call is Anthropic's**, and this exact failure shape is a
  documented, recurring class there — arguments dropped or emptied between a healthy remote server and
  the client: `anthropics/claude-ai-mcp#628` (open; ~1-in-5, identical retry succeeds),
  `anthropics/claude-code#36518` (intermittent "required parameter is missing", retry succeeds),
  `#3966` (empty parameter dicts sent to MCP servers, root-caused to client-side serialization),
  `#49910` (~25% of brokered remote MCP calls fail while the server answers in milliseconds),
  `claude-ai-mcp#154`/`#394`.

**Weighing it:** the broker-side precedent is a strong behavioural match, but it does not explain
fact (3) on its own — a generic client serialization fault should not spare `datasetId` and
`projectId` across 80 control calls while hitting `query` 24 times in 172. Either the broker's
handling is field-specific on this path (e.g. an inspection or rewrite step applied to the free-text
SQL argument that occasionally consumes it), or the fault is in Google's server-side request
assembly for the two SQL tools. **Server-side logs are required to close this**, correlated by project
and the windows in §2 — the failures will appear as tool invocations with no corresponding BigQuery
job. That is the one question this access path cannot answer, and it is named as such in §7.

## 4. The request-size theory is refuted — and it was still live in binding guidance

`Claude_Task_Plan.md` asserted a second, deterministic cause with the same error text: *"REQUEST SIZE
— measured between ~12.6KB (succeeds) and ~15KB (fails twice)"*, concluding **"Keep the whole request
under ~13KB."** That rule was propagated by `scripts/split_task_plan.py` into **34 `task_plan/` slices**.

It is false, on three independent grounds:

1. **Directly re-measured this session, above the claimed ceiling.** Byte-identical sequential calls
   carrying a **16,042-character** request body succeeded **6 of 8**; at **25,018 characters**, **3 of 4**.
   Both sizes are above the "~15KB fails twice" threshold, and a deterministic ceiling cannot produce a
   success above it — let alone nine. Every failure in that arm carried the same
   `Required parameter is missing: query`; **no response at any size mentioned size, length, or a limit.**
   This agrees with the previously established successes at **27,415 / 29,824 / 44,387 characters**, also
   recorded in the `ops.alerts` resolution note quoted in (2).
   *Do not read the large-payload arm's 3/12 as a size correlation:* against the 13.0% baseline that is
   p = 0.20, nowhere near significant at n = 12. The claim refuted here is a deterministic ceiling; no
   rate-vs-size relationship is asserted in either direction.
2. **The warehouse already retracted it.** `ops.alerts` `5d971f00` (`mcp_query_size_ceiling_measured`,
   D2 2026-09-10) was resolved on 2026-09-11 09:19:06 UTC as **wrong**, on exactly those counter-
   measurements. The retraction reached the alert but **never reached the plan text**, so a refuted rule
   stayed binding on all 35 files for a day.
3. **The arithmetic never needed a second cause.** At the measured 13% per-call drop rate, two
   consecutive drops is p² ≈ **1.7%**, and across a 30-call session the chance of seeing *at least one*
   back-to-back double is **~39%**. "It failed twice in a row, so it must be deterministic" is therefore the
   expected behaviour of a single intermittent bug and is a guaranteed false-positive generator. Two
   independent routines (D2 and M1R) reached the same wrong conclusion the same day for exactly this
   reason.

**Resolution.** The withdrawal landed on `main` in commit `8c1f780`, written independently and
concurrently with this investigation — two sessions reached the same conclusion from different
evidence, which is itself corroboration. This changeset does not re-litigate that wording: it keeps
main's text (whose provenance argument — that each large `sp_write_adversarial_review` call takes
`p_body_md` as a single STRING parameter with no chunking, so each was necessarily ONE request — is
stronger than mine) and adds on top the localisation in §3, the direct 16,042/25,018-character
re-measurement, the indistinguishable-error finding, and the arithmetic above.

## 5. Impact — and one correction to the received account

The handoff that opened this item stated that a session, misreading the error as a size ceiling,
"silently truncated a durable record whose body was SHA-256-asserted at write time — corrupting the
artifact." **That overstates the damage, and the record should be accurate.** Measured live
2026-09-11:

* `events.adversarial_reviews` — the SHA-256-asserted table — holds **193 rows with 0 hash mismatches**
  (`content_sha256` vs `TO_HEX(SHA256(body_md))` for every row). The three rows written in the
  2026-09-07..11 window are 15,133 / 27,539 / 29,954 bytes, all well above the 9,284-byte median. **No
  truncation, no integrity violation.** The SHA-256 artifact was never corrupted.
* The real damage landed on an `ops.run_log` **note** — AR_att, run_date 2026-09-09 — shortened from
  **6,495 → 4,703 bytes** because the session inferred a size limit from this error. That field carries
  no integrity check, which is *why* the damage was silent there and absent from the checksummed table.
  The run self-documented it in an appended correction and re-measured the identical 6,495-byte
  payload afterwards: it succeeded first try. ~2,291 bytes of prose were not recovered.

The distinction matters for severity: this bug corrupts records in the fields that are **not**
checksummed, and a write-time hash assertion is no defence — a session that shortens its own text
*before* hashing produces a self-consistent row that passes every assertion. Detection has to come
from not making the misdiagnosis in the first place, which is a property of the error message.

Fleet-wide blast radius (from `ops.run_log`): **21 distinct (routine, run_date) sightings**, 2026-08-18
to 2026-09-10, across D1, D2, D2a, D3, M1R, OPS0, OPS1, OPS2, SL2, SL5, AR_att, AR_orc.
`state.retry_telemetry` records 12 arg-drop retries, **all recovered, none exhausted** — though the
true count is higher, because the `kind` slug drifted (`mcp_payload_rejected`,
`mcp_execute_sql_query_arg_dropped`, `mcp_arg_drop`) before `mcp_arg_drop` was standardised.

## 6. Retry semantics — settled

**Is retry-on-this-error sanctioned client behaviour? Yes — exactly once, verbatim, with no wait,
before any other branch.** That is already the fleet rule (`Claude_Task_Plan.md` §Observability →
MCP-TRANSPORT REJECTION) and this investigation confirms it is correct: all 25 observed drops were
transient, and `state.retry_telemetry` shows every recorded retry recovered and none exhausted. The
rule is unchanged by this work. What changed is its *failure* branch: a second identical failure is
the same bug again, not a size problem (§4), so it falls through to THE LADDER rather than triggering
a measure-and-shrink response.

**Should the connector retry internally? Yes — and that is the right layer.** Today every consumer
invents its own rule; this repo needed three separate routines and four `ops.alerts` rows to converge
on one, and got it wrong in between. The argument is not merely convenience:

* The failure is **provably idempotent to retry at the transport layer**, because no BigQuery job is
  created. There is no partial-write hazard for the layer that can see that no request was dispatched —
  unlike a consumer, which cannot distinguish "never dispatched" from "dispatched, response lost" and
  must therefore read back the effect before re-issuing a DML. **The layer that knows it never sent
  the request is the only layer that can retry a write safely and cheaply.**
* A consumer-side wrapper cannot fix the misleading message for anyone else, which is why it is
  explicitly *not* proposed as the resolution here.

**Recommended vendor behaviour:** retry internally once on a dropped argument, and if the retry also
fails, return an error that distinguishes *argument not received* from *argument invalid* (§7, defect B).
Until a vendor ships that, the sanctioned client rule above stands and is documented at its point of
use in this repo.

## 7. The vendor report — paste-ready

**Not yet filed.** This session could not open the issue: attaching an external repository is denied by
this environment's permission classifier, so `anthropics/claude-ai-mcp` is unreachable from here, and
Google's Issue Tracker requires an interactive signed-in session. **What is needed to finish:** someone
with a browser session as the project owner posts §7a to
**https://github.com/anthropics/claude-ai-mcp/issues/new/choose** (primary — this is the repo Anthropic
designates for "issues related to MCP integration with Claude"), and, if Google-side correlation is
wanted, to the BigQuery component of Google Issue Tracker,
**https://issuetracker.google.com/issues/new?component=187149&template=0**. Project
`stock-trading-498512` is shareable with either owner; it is what lets them correlate server-side logs.

Severity to claim: **medium-high**. The drop is recoverable, but the message is not: it caused silent
record corruption in a production trading system and sent two independent investigations down a false
theory that survived in binding operating guidance for a day.

### 7a. Issue body

> **Title:** BigQuery connector intermittently returns "Required parameter is missing: query" for calls that supplied `query` (~13%, `execute_sql`/`execute_sql_readonly` only)
>
> **Summary.** The Google Cloud BigQuery connector's `execute_sql` and `execute_sql_readonly` tools
> intermittently return `Required parameter is missing: query` to the model for well-formed calls in
> which `query` was supplied and valid. No BigQuery job is created (no `queryId`, zero bytes billed,
> nothing in `INFORMATION_SCHEMA.JOBS_BY_PROJECT`), so the request never reaches BigQuery. An immediate
> byte-identical re-issue succeeds. First seen 2026-08-18; still reproducing 2026-09-11.
>
> **Environment.** GCP project `stock-trading-498512`, location US. Connector authorised under the
> project owner's own Google identity (OAuth), not a service account. Reproduces from both cloud
> scheduled Claude agent sessions and interactive Claude Code sessions, on Opus 5 and Sonnet 5.
>
> **Rate.** 25 failures in 192 calls (13.0%) measured 2026-09-11 across seven arms, never retrying
> inside an arm. Independently, 21 distinct (routine, date) sightings in our operational logs 2026-08-18 to
> 2026-09-10.
>
> **Reproduction.** Issue ~30 sequential `execute_sql_readonly` calls with `projectId` and
> `query: "SELECT 1 AS probe"`. Several will fail. No special setup.
>
> **What we ruled out, with measurements:**
> * *Not the model's emission.* Thirty byte-identical `tool_use` blocks emitted in a SINGLE assistant
>   message: 25 serviced, 5 rejected as missing `query`.
> * *Not positional.* Reversing emission order (`query` first, `projectId` second) across 60 calls: all
>   10 failures still named `query`, none named `projectId`.
> * *Specific to the `query` argument.* `projectId` was supplied in 272 calls and reported missing zero
>   times.
> * *Specific to the SQL-executing tools.* `list_table_ids` (2 required params) and `list_dataset_ids`
>   (1 required param) on the same connector: **0 failures in 80 calls**, including 20 interleaved
>   call-for-call with `execute_sql_readonly` in the same window (which failed 1/20 there), ruling out a bursty
>   quiet period. Fisher exact vs the SQL tools: p ≈ 1.3e-4.
> * *Not request size.* Single-call requests carrying string arguments of 27,415 / 29,824 / 44,387
>   characters all succeeded first try. An earlier theory of a ~13KB ceiling was withdrawn: at a 13%
>   per-call drop rate, the "fails twice in a row" observation behind it has ~1.7% probability per
>   pair and ~39% odds of appearing at least once in a 30-call session.
> * *Not auth, quota, permission, or SQL.* No 401/403, no `accessDenied`, no quota wording, no
>   parse/semantic message. Verified non-partial on a DML case: effect read back as count 0, then the
>   re-issue wrote exactly one row.
>
> **Defect 2 — the error message, which we ask you to fix independently of the cause.** Calling
> `execute_sql_readonly` with `projectId` and deliberately NO `query` returns the *byte-identical*
> string. A caller therefore cannot distinguish "you did not supply `query`" from "`query` was supplied
> and was lost before validation". Reporting a transport loss as a caller error has real consequences:
> in our system a session read this error, inferred its payload was too large, and silently shortened a
> durable operational record rather than retrying — losing ~2,291 bytes of an audit note. It also sent
> two independent automated investigations down a false "request-size ceiling" theory that took three
> rounds to kill and briefly became binding operating guidance. An error that said *argument not
> received* would have prevented all of it. This is shippable separately from the root cause and removes
> most of the harm. It is also the direction MCP's own spec work is taking (SEP-1303,
> modelcontextprotocol/modelcontextprotocol#1303, accepted: move argument-validation failures out of raw
> protocol errors so they carry actionable, recoverable detail).
>
> **Defect 3 — retry semantics are undefined, so every consumer invents one.** Please state whether
> retrying this error is sanctioned, and consider retrying internally. The failure is uniquely safe to
> retry at your layer because no BigQuery job is created — the layer that knows the request was never
> dispatched is the only one that can retry a write without a read-back, which every consumer must
> otherwise do.
>
> **Related.** This looks like the brokered-remote-MCP argument-loss family already tracked in
> `anthropics/claude-ai-mcp#628`, `#154`, `#394`, and `anthropics/claude-code#36518`, `#3966`, `#49910` —
> but none of those is filed against the BigQuery connector, and none carries the field-specificity
> evidence above, which argues the fault is narrower than a generic client serialization bug.
>
> **What we cannot see.** Whether the argument is absent from what the MCP server received (transport)
> or present-but-rejected by server-side validation. Connector/gateway logs for tool invocations against
> `stock-trading-498512` in the windows above would close it: the failures appear as invocations with no
> corresponding BigQuery job. Project ID shareable on request.

## 8. Outcome and residual risk

* **Localised** to the `query` argument on the SQL-execution path, downstream of model emission and
  upstream of BigQuery; the vendor boundary within that span needs server-side logs (§3, §7).
* **The misleading message is filed as its own defect** with the measurement that proves the ambiguity
  (§2c fact 6) and the concrete harm (§5).
* **Retry semantics settled and documented** at the point of use (§6).
* **The refuted size ceiling is out of binding guidance** (§4) — the highest-value fix here, because
  that rule, not the drop, is what corrupted a record.
* **Residual:** the report is not yet submitted (§7), and until a vendor fixes the message, any new
  consumer of this connector that has not read `Claude_Task_Plan.md` can make the same misdiagnosis.

---

## Appendix — ready-to-run `events.decision_log` record (NOT executed)

RUNBOOK §51 is the durable in-repo record and is committed. This is its in-warehouse counterpart, left
**unexecuted deliberately**: `events.decision_log` is append-only production state, and CLAUDE.md's
2026-07-21 rule is that an interactive session asks before taking an autonomous live action even when a
scheduled routine would take the same one unattended. Signature verified live against
`ops.INFORMATION_SCHEMA.PARAMETERS` (16 parameters) on 2026-09-11. Run as-is to record it.

```sql
CALL `stock-trading-498512.ops.sp_log_decision`(
  DATE '2026-09-11',                                    -- in_entry_date
  'ops-note',                                           -- in_entry_type
  NULL,                                                 -- in_strategy
  NULL,                                                 -- in_ticker
  'LOCALISED-REPORT-PENDING-SUBMISSION',                -- in_decision
  NULL,                                                 -- in_conviction
  NULL,                                                 -- in_conviction_pct
  NULL,                                                 -- in_sub_pattern
  NULL,                                                 -- in_theater_check
  'BigQuery MCP query-arg drop localised; refuted ~13KB size ceiling withdrawn',  -- in_title
  CONCAT(
    'Measured 2026-09-11 over 284 connector calls. The two SQL-executing tools ',
    '(execute_sql, execute_sql_readonly) drop the query argument on 28 of 204 calls (13.7%); ',
    'their siblings list_table_ids and list_dataset_ids failed 0 of 80, including 20 interleaved ',
    'call-for-call in the same window (Fisher exact p ~ 1.3e-4). projectId was supplied in all 284 ',
    'calls and reported missing zero times. Not the model emission: 30 byte-identical tool_use blocks ',
    'in ONE assistant message gave 25 successes and 5 rejections. Not positional: emitting query first ',
    'still named query in all 10 failures. Fault is downstream of model emission and upstream of ',
    'BigQuery, specific to the free-text query argument; separating the Google MCP server from the ',
    'Anthropic broker needs server-side logs unavailable on this access path. SECOND DEFECT: calling ',
    'the tool with no query at all returns the byte-identical error, so a caller cannot distinguish ',
    'not-supplied from lost-in-transit -- the root of every misdiagnosis. ACTION TAKEN: withdrew the ',
    'refuted ~13KB request-size ceiling from Claude_Task_Plan.md and all 34 slices (16,042- and ',
    '25,018-char requests succeed; two-in-a-row is p^2 ~ 1.7% and ~39% likely per 30-call session). ',
    'Confirmed events.adversarial_reviews is 193 rows with 0 hash mismatches -- the SHA-256 artifact ',
    'was never corrupted; the damage was an ops.run_log note (AR_att 2026-09-09, 6495 -> 4703 bytes), ',
    'a field with no integrity check. Retry rule unchanged and confirmed correct: one immediate ',
    'verbatim re-issue, no wait. Vendor report ready to file at ',
    'ops/spikes/bigquery-mcp-query-arg-drop-2026-09-11.md; submission blocked on browser access.'
  ),                                                    -- in_body_md
  '{"sql_tool_failures": 28, "sql_tool_calls": 204, "control_failures": 0, "control_calls": 80}',
  ['runbook:51', 'alert:5d971f00-aa24-4ccf-accf-bedd6d5d3834'],                    -- in_refs
  ['connector', 'mcp', 'bigquery', 'external-dependency', 'ops-note'],             -- in_tags
  NULL,                                                 -- in_superseded_by
  'interactive session 2026-09-11'                      -- in_source_session
);
```
