# BigQuery connector de-auth, 2026-11-03: D1's deferred writes

**Status: OPEN, awaiting re-auth.** Author: Claude (agent), D1 run of 2026-11-03 (session
`0ae50cfd-af1c-5586-8100-6d25daa8b824`). This file changes no live BigQuery object and no trigger.
It exists so the writes D1 could not make on 2026-11-03 survive `Daily.md`'s next overwrite.

**Unlike the 2026-09-21 ledger, every deferred row here is carried as GENERATED, DIGEST-GUARDED SQL** in
the sibling directory `ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/`. A landing session issues
those files verbatim and reconstructs nothing. That 2026-09-21 landing pass had to rebuild `fields` from
prose, because the summary table it relied on did not carry them.

**Later slots of this incident:** append `## <slot> slot, 2026-11-03: HALTED` to THIS file (per the
FLEET CONNECTOR-DOWN DISPOSITION TABLE, item 2), not to the calendar thread.

**Read first:** `ops/RUNBOOK.md` §26; `Claude_Task_Plan.md` §Observability → connector pre-flight; and
`Daily.md` for 2026-11-03 (`git show <the D1 2026-11-03 commit>:Daily.md` once it has been overwritten).

---

## 1. What happened

- **The failure.** At D1's connector pre-flight, **2026-11-03 ~15:05 MT (22:05Z)**, the
  `Google-Cloud-BigQuery` MCP server was listed as **requiring authentication**, and its tools were not
  callable at all. The preconfigured `bq` CLI (`bq ls`) returned **`Invalid Credentials`**.
- **The diagnosis.** Both failures carry auth wording, which the TRANSIENT-FAILURE ladder classifies as
  the **RE-AUTH branch, NON-WAITABLE**. The ladder was not entered and no session time was spent waiting.
- **The scope.** It is one connector's grant, not a platform 403 (RUNBOOK §54). The session stayed up,
  and every other connector answered:
  - IBKR: `get_account_summary` returned `net_liquidation` 12271.73.
  - Google Calendar accepted an event write.
  - Tavily, FMP, Hugging Face, the key-less Nasdaq/EDGAR endpoints and Google News RSS all answered.

**Channel.** `ops.alerts` lives in BigQuery, so the only surviving channel is a calendar event.
**`[Claude] ATTENTION — RE-AUTH BigQuery connector`** was created for 2026-11-03 15:30 MT (event id
`en7a5vooom7a0c0mk1p8hnin78`), with popup and email reminders at event time. No earlier event existed
for this incident; the 11-02 to 11-05 window was searched first.

**Disposition.** D1 ran in **DEGRADED MODE**:
- the book and marks came from IBKR;
- the regime, router state and per-strategy kill state were carried forward from the 2026-11-02 `Daily.md`;
- every BigQuery side-write is deferred to §3.

D2a, D2 and D3 must HALT until the connector is re-authorized, per their CONNECTOR-DOWN DISPOSITION limbs.

## 2. Recovery procedure

1. **Re-auth (owner, no code change).** Re-consent the Google/BigQuery connector in claude.ai connector
   settings (RUNBOOK §26). Verify it with any `state.*` read.
2. **Land §3 in order**, verbatim from the files. Check idempotency first: if a later D1 has already
   written a `research-screen` or `add-candidate-review` row for `entry_date = 2026-11-03`, do not
   duplicate it; mark it SUPERSEDED BY EVENTS here.
3. **Re-run D2a → D2 → D3** for the missed slots, per the catch-up path and RUNBOOK §26.
4. **Recovery order covers every declared dependent of D1.** D1 is `catchup_safe`. This degraded run
   writes no `ops.run_log` row, so the slot reads as missed. Two outcomes are acceptable:
   - The catch-up replay lands a normal D1 row. Its same-day guard then sees a `completed` row, and this
     ledger's run-log rows are SUPERSEDED.
   - `ops.sp_backfill_run_log_from_markers` self-heals the slot from this run's commit marker.

   **D2**, which consumes D1's `Daily.md` and `d1_actions`, runs its own catch-up loop and recovers once
   the upstream catch-up lands. This file stays readable from main for that.
5. **Expected signature, not new bugs.** A `missed_run` (D1, D2a, D2, D3) plus `staleness` double
   critical is expected once BigQuery returns. Resolve it with a note pointing at this file.

## 3. The deferred writes

Directory: `ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/`. Issue every `.sql` file VERBATIM, one
at a time, through `execute_sql`. Never retype one. Each `decision_log` call is digest-checked by
`ops.sp_log_decision_checked`: a `REFUSED, digest mismatch` means nothing was written, so re-issue the
same file.

| # | Target | Files, in order | Notes |
|---|---|---|---|
| 1 | `events.decision_log` `research-screen` (`single-name-move`, router-gated) | `single_name_screen/part_fields_*.sql` in order, then `single_name_screen/call.sql`, then `readback.sql` | split write: issue every part before `call.sql`. Source JSON `single.json` alongside. |
| 2 | `events.decision_log` `research-screen` (`sector-move`) | `sector_screen/call.sql`, then `readback.sql` | source `sector.json` |
| 3 | `events.decision_log` `add-candidate-review` | `add_candidate_review/call.sql`, then `readback.sql` | 12 evaluated, 0 flagged, 12 `declined_hard_gate` (`invalidation_status` unreadable) |
| 4 | `events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT` = 61.63 for 2026-11-03 | `breadth_regime_event.sql` | **check `(as_of_date, scope, key)` absent first**; a plain VALUES insert carries no NOT EXISTS guard. `numeric_value` is already `NUMERIC '61.63'`. |
| 5 | `events.news_reaction_calls` (paper book J, 120 calls, `call_date` 2026-11-03) | `paper_book_calls/batch_01..04.sql` one at a time, then `readback.sql` | row-digest guarded and idempotent per WRITE INTEGRITY; the 4-day story lookback and per-ticker cap are evaluated at landing time |
| 6 | `ops.heartbeat` `loop:park_allocator` | inline below | the pin itself could not be read; see §4 |
| 7 | `ops.web_calls` | inline below | per-call tally in §5 |
| 8 | `ops.run_log` start + end | inline below | only if no D1 `completed` row exists yet for 2026-11-03 |

**Not deferred, by design:**
- **`events.news_reaction_marks`.** Marks self-heal: the next D1 re-ingests a 14-day window and writes
  any absent bar. No marks were fetched this run.
- **The paper book's READINESS + ENQUEUE step and FUTILITY STOP query.** Both read BigQuery and write
  nothing unless their condition holds. The next normal D1 evaluates them.

### 3.6 Park pin heartbeat

The VOO-only pin could not be VERIFIED: `state.park_policy_current` and `state.park_menu` are unreadable.
IBKR shows idle capital in VOO only (16.895 sh), which is consistent with the pin but is not a read of it.
So land the heartbeat with an honest note, or not at all:

```sql
INSERT INTO `stock-trading-498512.ops.heartbeat` (source, note)
VALUES ('loop:park_allocator', 'D1 2026-11-03 DEGRADED: pin not verifiable (BigQuery de-authed); IBKR shows idle capital in VOO only. Landed late from ops/spikes/bigquery-deauth-2026-11-03-d1-deferred-writes.md');
```

### 3.7 `ops.web_calls`

See §5 for the per-call list, then build the batched INSERT per the shared Run-logging template
(§Observability), copying the column list from a recent D1 row. It is not pre-rendered here, because the
template's column list is in BigQuery-side history this run could not read.

### 3.8 `ops.run_log`

```sql
BEGIN
  CALL `stock-trading-498512.ops.sp_routine_start`('D1', DATE '2026-11-03',
    '0ae50cfd-af1c-5586-8100-6d25daa8b824', 'claude/d1-2026-11-03-degraded',
    'Read Claude_Task_Plan.md. Perform D1 — deep research.');
EXCEPTION WHEN ERROR THEN SELECT @@error.message;
END;
```

```sql
BEGIN
  CALL `stock-trading-498512.ops.sp_routine_end`('D1', DATE '2026-11-03', 'completed',
    '0ae50cfd-af1c-5586-8100-6d25daa8b824', 'claude/d1-2026-11-03-degraded', 0,
    'DEGRADED MODE: BigQuery MCP connector de-authed at pre-flight (MCP server requires authentication; bq CLI Invalid Credentials -> non-waitable RE-AUTH branch, ladder not entered). Research completed; all BigQuery side-writes deferred to ops/spikes/bigquery-deauth-2026-11-03-d1-deferred-writes.md.',
    'DEGRADED RUN, COMPLETE RESEARCH OUTPUT. rows_written=0 is literal. See the ledger for the research-screen (single-name, sector), add-candidate-review, breadth and paper-book rows and the web_calls tally.');
EXCEPTION WHEN ERROR THEN SELECT @@error.message;
END;
```

## 4. What this run could not do at all (not deferrable)

- **Re-read and decide on BigQuery state:**
  - `state.trading_day_today`: today came from `America/Denver` system time instead, and 2026-11-03 is a
    regular US session;
  - `state.current_positions` convergence and time-exit fields;
  - `perf.kill_flags`;
  - `analytics.b_pairwise_correlation` (B holds no positions, so it is inert anyway);
  - `state.price_level_criterion_drift`;
  - `ops.alerts`.
- **The CROSS-ROW CLOSE-CHAIN durable check.** The by-hand check against the 2026-11-02 `Daily.md`
  passed table found 0 hits.
- **The paper book's FUTILITY STOP query.** The 2026-11-02 run reported 189 realized calls and
  net_mu −0.54%; the stop needs ≥20 realized call-dates (SL1 counted 7 on 11-02), so it very likely had
  not tripped.
- **IN-RUN ISSUE REPORTING** (`ops.sp_report_run_issue`): unreachable. Findings are in §6.

## 5. Metered calls owed to `ops.web_calls`

| Leg | Provider | Calls | Notes |
|---|---|---|---|
| Developments (news) | tavily | 7 search (6 ok, 1 HTTP 429) | about 10 credits |
| Held positions | tavily | 8 search ok + 5 HTTP 429 failures | one per held name |
| Sector and breadth | tavily | 2 search (advanced) + 1 extract (Barchart `$S5TH`) | |
| Sector and breadth | fmp | 1 `commodities-historical-price-eod-light` BZUSD | |
| Sector and breadth | web_fetch | 3 (EODData, ChartRow ×2) | free, still owes rows |
| HF capability check | hf | 1 search + 1 `ls hf://papers/daily/latest` | |
| Single-name screen | none | 0 | key-less Nasdaq, EDGAR and IBKR only |

The per-call targets are in the run's scratch `web_calls.json` files, which are ephemeral; the table
above is the durable tally.

## 6. Unfiled findings (`ops.alerts` unreachable; RUNBOOK §26 step 4, OPS0 intake)

- **Owner D1 (screen tooling): IBKR `search_contracts` rate limit, 30 requests/minute.** The router-gated
  screen hit it mid-confirmation on 2026-11-03, and an orchestrator-directed paced second pass was needed
  to measure the remaining own-event names. The screen scripts could pace contract resolution, or cache
  the symbol → `contract_id` map, so one pass suffices. Info-level; it did not change the run's output.
