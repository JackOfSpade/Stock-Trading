# BigQuery connector de-auth, 2026-09-21 — D1's deferred writes

**Status: LEDGER, OPEN. Nothing here has landed.** Author: Claude (agent), D1 run of 2026-09-21.
This file changes no live BigQuery object and no trigger. It exists so that the writes D1 could not
make survive `Daily.md`'s next overwrite.

> **SAME INCIDENT, SECOND FILE (added by the D2a slot, 2026-09-21 ~16:5x MT).** The D2a slot halted on
> this same OAuth expiry ~35 minutes later. It deferred no composed write — it never got far enough to
> compose one — so it did not extend this ledger; its halt record, the perishable connector evidence it
> captured (NAV / cash / positions, which are not re-readable after the day passes), and its measured
> cost account are in the sibling file **`bigquery-deauth-2026-09-21-d2a-halt-record.md`**. Recovery
> step 2 of that file is step 2 of this one. Work them together, not separately.

**Read first:** `ops/RUNBOOK.md` §26 (the 2026-06-26 precedent — same failure, same branch),
`Claude_Task_Plan.md` §Observability → connector pre-flight (the BigQuery-unreachable branch that
put D1 in degraded mode), and `Daily.md` for 2026-09-21 (the run itself, while it is still current).

---

## 1. What happened

At D1's connector pre-flight, **2026-09-21 ~16:10 MT**, the Google-Cloud-BigQuery MCP connector
returned `MCP server "Google-Cloud-BigQuery" needs you to sign in again` on every call.

**Diagnosed by probe, once, per the TRANSIENT-FAILURE ladder's DIAGNOSE BY PROBE rule:** a bare
`SELECT 1` — no table reference — **also failed with the same auth wording**. Per that rule's
classification table this is *connector/service down, auth wording → the RE-AUTH branch*, which is
**NON-WAITABLE**. The ladder was therefore not entered and no session time was spent waiting.

**This is NOT the platform `403 authentication_failed` signature recorded in RUNBOOK §54** (the
2026-09-21 OPS0 kill). That one terminates the session mid-run and leaves an orphaned `started` row.
This session stayed alive for its full duration and every other connector worked normally —
**IBKR returned `net_liquidation` 15916.02 at pre-flight and served 52 clean price-history pulls**,
Google Calendar accepted an event write, and Tavily / FMP / Hugging Face all answered. The failure is
scoped to the BigQuery MCP server's own OAuth grant. Discriminate on that: a platform 403 kills
everything, an OAuth expiry kills one connector.

**Channel used.** `ops.alerts` lives in BigQuery, so `sp_raise_alert` could not run and
`alert_emailer.gs` has nothing to poll. Per the pre-flight branch, the only surviving first-class
channel is a calendar event, and one was created immediately:
**`[Claude] ATTENTION — RE-AUTH BigQuery connector`**, 2026-09-21 17:00 MT, event id
`09q69g3odvhhbiom3drf15uc60`, with popup + email reminders at event time.

**Disposition of the run.** D1 is research-only and stages no orders, so per the same branch it
proceeded in **DEGRADED MODE** rather than halting: book read from the IBKR connector, regime and
per-strategy kill state carried forward from the prior `Daily.md`, every BigQuery side-write deferred
to this file. D2 / D2a / D3 require canonical state and will halt cleanly until the connector is
restored.

---

## 2. Recovery procedure

Fix the cause first, then land the writes, then resolve the alerts. Do not blind-resolve a live red.

1. **Re-auth the connector (owner, no code change).** Re-consent the Google / BigQuery connector in
   claude.ai connector settings. Per RUNBOOK §26 this is a Google-account-side grant lifecycle event
   on Anthropic's first-party connector — there is nothing in the GCP project console that governs
   it. Verify with any `state.*` read.
2. **Land the deferred writes in §3 below**, in the order given. They are written paste-ready.
3. **Re-run D2a, then D2, then D3** for 2026-09-21 so the close is ingested and
   `state.system_health.all_green` returns TRUE.
4. **Expect — and do not treat as new bugs — a cadence + freshness double-critical.** Per RUNBOOK
   §26's general rule, `missed_run` (D1/D2/D2a/D3) and `staleness` firing in the same batch is the
   *expected signature* of a connector outage, not two independent faults. They are TRUE positives.
   Resolve them with a note pointing at this file once green.

---

## 3. The deferred writes

**Ordering matters only for the two run-log rows** (start before end). Everything else is independent.
**Idempotency:** the `events.regime_events` row is keyed on `(as_of_date, scope, key)` — check before
inserting. The `events.decision_log` rows are append-only; if a later D1 run has ALREADY written a
`research-screen` row for `run_date = 2026-09-21`, **do not write these as duplicates** — a second
same-day screen row is not a correction and there is no `in_superseded_by` relationship to express.
In that case land only the `ops.web_calls` and `ops.run_log` rows and mark the rest **SUPERSEDED BY
EVENTS** here.

> **If these are landed LATE — after 2026-09-21 — `run_date` / `as_of_date` still read 2026-09-21.**
> These record what was measured on that date. Per §Decision discipline, a widened window lets a
> later session *see* this history; it does not let it act as though it were an earlier date, and
> nothing in this ledger is an action.

### 3.1 `ops.run_log` — the two rows the run could not log

```sql
-- START row (log first; the run genuinely began 2026-09-21 ~16:10 MT)
BEGIN
  CALL `stock-trading-498512.ops.sp_routine_start`('D1', DATE '2026-09-21',
    'e89e367f-0305-54b2-b815-bfd00785ac90', 'claude/epic-cray-d67489',
    'Read Claude_Task_Plan.md. Perform D1 — deep research.');
EXCEPTION WHEN ERROR THEN SELECT @@error.message;
END;
```

```sql
-- END row. rows_written = 0 is CORRECT and is not a placeholder: this run inserted ZERO BigQuery
-- rows, because BigQuery was unreachable for its entire duration. Per the 2026-08-07 pin the field
-- counts BigQuery rows inserted and nothing else -- not repo files, not tickers, not decisions --
-- and per the 2026-09-06 addition it excludes the run's own run_log rows.
-- error_msg is populated deliberately: sp_log_run reads it at write time to build the
-- routine_run_warning alert detail, so a specific diagnostic here is what actually reaches the owner.
BEGIN
  CALL `stock-trading-498512.ops.sp_routine_end`('D1', DATE '2026-09-21', 'completed',
    'e89e367f-0305-54b2-b815-bfd00785ac90', 'claude/epic-cray-d67489', 0,
    'DEGRADED MODE: BigQuery MCP connector de-authed at pre-flight (bare SELECT 1 also failed with auth wording -> non-waitable RE-AUTH branch, ladder not entered). Research completed in full; all BigQuery side-writes deferred to ops/spikes/bigquery-deauth-2026-09-21-d1-deferred-writes.md.',
    'DEGRADED RUN, COMPLETE OUTPUT. BigQuery unreachable for the whole session; [Claude] ATTENTION RE-AUTH calendar event raised as the only surviving channel. Scan itself is NOT degraded: 52 instruments confirmed on IBKR regular-session daily bars, zero symbol-level denials, zero measurement failures, zero discovered-but-unconfirmable names. Book read from get_account_positions; per-strategy kill state and per-tranche cost basis carried forward/reconstructed from the prior Daily.md and labelled as reconstruction, not as a state.current_positions read. PARK: re-risk call f 25 -> 0, which could not be logged and therefore could not reach D2 via state.park_allocation_latest -- D2 is halted on the same outage regardless. Add-candidate sweep ran; 12 tranches evaluated, 0 flagged, and ALL 12 recorded declined_hard_gate because invalidation_status is a BigQuery field and the gate cannot affirmatively confirm "unbreached" from an unreadable mirror -- conservative and costless, since zero add triggers fired (every open position rose). rows_written=0 is literal. ANCHOR CONVENTION landed in D1 prompt this run closing d1_qualifying_event_date_anchor_unspecified (03b8f773) after four consecutive cycles of downstream correction; it bound immediately and moved two of seven candidates (ARM anchors 2026-09-16 after-close, META 2026-09-18), which under the prior silent default would both have been stamped 09-21 and routed. METERED SPEND: 94 metered calls, 109 ops.web_calls rows owed -- 65 Tavily (62 search + 3 advanced extract), 28 FMP, 1 HF, plus 13 Anthropic web_fetch and 2 WebSearch which are free but still owe rows -- all deferred to the ops.web_calls INSERT in the same ledger file; IBKR (94 calls) and BigQuery calls are free and are not billed telemetry.');
EXCEPTION WHEN ERROR THEN SELECT @@error.message;
END;
```

### 3.2 `events.regime_events` — the equity-breadth observation

Measured cleanly this run; only the write is missing. **Check idempotency on
`(as_of_date, scope, key)` before inserting.** Do NOT write `scope='TECHNICAL_SIGNAL'` — that scope is
D2a's and the HEALTHY/WEAK threshold is D2a's to apply.

```sql
INSERT INTO `stock-trading-498512.events.regime_events`
  (as_of_date, scope, key, value, numeric_value, rationale, source_review_ref)
SELECT DATE '2026-09-21', 'TECHNICAL_INPUT', 'EQUITY_BREADTH_PCT', 'Barchart $S5TH', 50.49,
  'https://www.barchart.com/stocks/quotes/$S5TH (cache-busted) — published 50.49 +0.99 (+2.00%), source as-of wording verbatim "Quote Overview for Mon, Sep 21st, 2026". SOURCE-DATED, not inferred_post_close. On-page timestamp 18:09 ET, i.e. AT OR AFTER the 16:00 ET close, satisfying the 2026-09-20 settlement pin that closed the 2026-09-17 unsettled-snapshot defect. Barchart Previous Close field read 49.50, reconciling EXACTLY against the stored 2026-09-18 value — zero mismatch, so no revision-noise question arises. TWO independent usable sources: EODData S5TH returned Close 50.49 for 21 Sep 26 (O 50.69 / H 51.09 / L 48.70), gap 0.00pp, and its Low(48.70) != Close(50.49) so the compound unsettled tell does not fire. CAVEAT RECORDED RATHER THAN SMOOTHED: EODData''s own page header stamped 15:48 ET, BELOW the 16:00 threshold, and did not advance across a deliberate re-fetch — it is used as corroboration on the strength of Barchart''s confirmed post-close page and the non-firing Low==Close tell, not as an independently certified post-close read. SECOND CAVEAT: the two vendors agree to the cent on all four of OHLC, which is more consistent with a shared upstream feed than with independent computation, so "two sources" here is weaker evidence of independence than the count suggests. Fetch path: tavily_extract (advanced) produced both figures; a rendering web_fetch on the Barchart URL returned an EMPTY body, which per the FETCH-METHOD-IS-PROVENANCE rule condemns that fetch, not the source. MacroMicro NOT probed this run and no probe was owed: the weekly re-probe rides on the Sunday-anchored week''s first D1 fire, and the 2026-09-20 Sunday run already spent it (both paths failed; streak unbroken since 2026-08-19). Day-over-day: 49.50 -> 50.49, +0.99pp, back ABOVE the shared vocabulary''s 50 HEALTHY line after one session below it.',
  'D1 2026-09-21 EQUITY-BREADTH OBSERVATION'
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.regime_events`
  WHERE as_of_date = DATE '2026-09-21' AND scope = 'TECHNICAL_INPUT' AND key = 'EQUITY_BREADTH_PCT');
```

### 3.3 `events.decision_log` — four rows

The full `fields` JSON and `body_md` for each are carried in the **`## DEFERRED BIGQUERY WRITES`**
section of `Daily.md` for 2026-09-21. If `Daily.md` has already been overwritten by a later D1 run,
recover it with:

```
git log --oneline --all -- Daily.md | head
git show <the 2026-09-21 D1 commit>:Daily.md
```

The four rows, with the contract each must satisfy:

| # | `entry_type` | Notes on the contract |
|---|---|---|
| 1 | `research-screen` (`screen='single-name-move'`) | Per-item keys EXACTLY `name` / `metric_pct` / `conviction_pct` / `reason` / `below_spec_floor` / `legacy_rule_pass` / `prior_close` / `event_close` / `market_cap_usd` / `qualifying_event_date`. Top-level `population_rail`, `legacy_rule`, `rail_tally`, `universe_measured`, `selection_rule`, and `agreement` as a **NESTED OBJECT** `{"both":n,"ai_only":n,"rule_only":n}` — a flat `agreement_both` is read by nothing. `surfaced_count` MUST equal `ARRAY_LENGTH(passed)`. |
| 2 | `research-screen` (`screen='sector-move'`) | Same key contract; `prior_close`/`event_close` required. A dispersion-only surfacing logs `legacy_rule_pass=false`, never NULL. |
| 3 | `add-candidate-review` | ONE row for the whole sweep, not one per position. `positions[]` + `n_evaluated` / `n_flagged` / `n_declined_hard_gate`. `trigger_type` from the controlled vocabulary EXACTLY: `dip-with-intact-thesis` / `strengthened-conviction` / `none`. |
| 4 | `park-allocation` | `fields` carries `{vehicle, conviction, conviction_pct, direction, status, readings, target_f_pct, risk_sleeve, defensive_sleeve}`. Every numeric claim the rationale makes must appear in `readings` with value + source + as-of date. |

**`ops.heartbeat`** — the `meta_monitoring_heartbeat` dead-man's-switch marker, owed on every D1 firing
regardless of outcome:

```sql
INSERT INTO `stock-trading-498512.ops.heartbeat` (source, note)
VALUES ('loop:park_allocator', 'VOO call, status=BOUND');
```

### 3.4 `ops.web_calls` — the metered-call telemetry

**109 rows** are owed. Totals: **65 Tavily** (62 `search` + 3 advanced `extract`, ~68 credits on the
rate card — an ESTIMATE, not provider-reported), **28 FMP** (2 of them ACCESS DENIED on plan tier,
which still cost a call), **1 HF**, **13 Anthropic `web_fetch`** (free; 4 of 8 on the anchor leg were
blocked or paywalled) and **2 WebSearch** (free). Free surfaces still owe a row.

IBKR (**94 calls** — 52 `get_price_history` issued strictly one per message across two sequential
passes, 39 `search_contracts`, 1 `search_futures`, 1 `get_account_summary`, 1 `get_account_positions`)
and BigQuery are free and are not billed telemetry. Two Bash `curl` calls to the Internet Archive
availability API are not a metered surface and are noted rather than logged.

Per-leg attribution, since `call_ts` can only be accurate to the sub-agent window rather than to the
individual call: market-wide events 20 Tavily; scheduled events 13 Tavily + 1 WebSearch + 3
`web_fetch` + 4 FMP; single-name discovery 13 Tavily + 1 WebSearch + 23 FMP; equity breadth 3 Tavily
`extract` + 2 `web_fetch`; treasury + HF 1 FMP + 1 HF; anchor-timestamp resolution 16 Tavily + 8
`web_fetch`. The two IBKR price-desk legs and the orchestrator spent nothing metered.

**This run is `expected_metered` under `bigquery/200_web_call_coverage_obligation_floor.sql`**, so
until this INSERT lands, `state.web_spend_month.has_unreported_runs` will be TRUE for D1 on
2026-09-21 and any fleet spend total drawn from that table is a **FLOOR, not a total**, and must be
reported as one.

---

## 4. What is NOT owed, and why — so a later session does not manufacture these

- **No `position_reconciliation_lag` alert.** That alert fires for a position real in IBKR but not yet
  in `state.current_positions`. The broker shows exactly the same eight names the prior run
  reconciled (AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER) plus the VOO/SGOV park sleeve and nothing
  else, so no new position appeared. **Stated as the INFERENCE it is:** the BigQuery side of that
  comparison was unreadable, so this is "no new name appeared at the broker", not "the two sides were
  compared". What would confirm it is the comparison itself, once BigQuery returns.
- **No `interim_underperf_warning` alert, and none to heal-resolve.** `perf.kill_flags` was unreadable;
  the prior run read every flag FALSE for both B and D, and nothing this session bears on a 90-day
  beta-adjusted excess. Carried forward, not re-measured.
- **No `b_pairwise_corr_high` alert.** Strategy B holds nothing (`n_positions = 0`), so the
  `n_positions >= 2` limb fails on zero. Structurally inert.
- **No `[HF Frontier-LLM Capture]` decision row and no `state.strategy_candidates` row.** The one
  permitted HF query returned five papers, none published inside the scan window — the most recent
  dates to 2025-12-08, over nine months stale. Nothing to evaluate against the materiality bar.
- **No `missing_dependency` handling.** D1 declares no upstream dependencies (the arrow runs
  `D2 -> ['D1']`, not the reverse), so `ops.sp_assert_deps` is correctly not called at all.

---

## 5. One thing this incident exposes that is NOT fixed here

**A degraded routine has nowhere durable to put a deferred write, and this file is a hand-rolled
answer to that.** The 2026-06-26 precedent (RUNBOOK §26) had the same problem and solved it the same
ad-hoc way — its banner simply noted that no writes were needed that day, which was true then and is
not true now: this run owes six decision/regime/heartbeat rows plus telemetry. The plan's degraded
branch says "defer every BigQuery side-write" and "banner `Daily.md`", but **`Daily.md` is
wholesale-overwritten by the next D1 run**, which is precisely the "prose log that deletes itself"
failure the add-candidate durable-log rule was written against.

**Deliberately not fixed in this run**, because it is a fleet-wide convention change and a research
routine's degraded fire is the wrong place to decide one unilaterally. The shape a fix would take:
either a standing `ops/deferred_writes/` convention with a CI check that fails while a ledger is open,
or a queue lane that a returning routine drains. **Owner: W5** (spec-defect intake) or OPS0.
Recorded here rather than raised as an `ops.alerts` row for the obvious reason — the alert sink is the
thing that is down.
