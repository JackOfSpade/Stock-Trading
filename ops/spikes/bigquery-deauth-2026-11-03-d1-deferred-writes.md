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

---

## D2a slot, 2026-11-03: HALTED

**Disposition: HALT, as D2a's CONNECTOR-DOWN DISPOSITION requires.** Author: Claude (agent), the D2a slot
for operating date 2026-11-03 (session `3042e66d-11b0-57a5-81a9-30e9caaa7318`). It fired on schedule at
~15:40 MST (22:40Z). Nothing was written:
- no `ops.run_log` row, not even `started`;
- no `events.*` row and no `ops.alerts` row;
- no order crafted and nothing staged;
- no second calendar event.

**Same incident, still unresolved at 22:41Z:**
- the `Google-Cloud-BigQuery` MCP server was still listed as requiring authentication;
- `bq ls` returned `Invalid Credentials`.

That is auth wording, so the case is NON-WAITABLE and this slot spent no time on the wait ladder.

**Calendar.** The existing event `en7a5vooom7a0c0mk1p8hnin78` got one line,
`UPDATE 15:45 MST D2a halted — first broker-reconcile/order-staging routine blocked …`. Before amending I
checked the description length: about 0.8 KB against the 8,192 cap, so there was room. The update was sent
with notifications off.

**Raw evidence.** IBKR responses are captured verbatim, except the YTD/1Y PA arrays, in
`ops/spikes/bigquery-deauth-2026-11-03-d2a-ibkr-capture.md` (reads at 22:42:24–22:42:52Z, post-close).

### What the halt cost, measured from IBKR

- **The staged-order re-craft had nothing to re-craft.** `get_account_orders` and `get_order_instructions`
  both returned empty lists.
  - This is an inference: it means the broker holds no live order or instruction. It does not prove the
    registry holds no `pending` row, because `state.open_orders` could not be read.
  - On replay, D2a's window-open → re-craft and window-closed → `expired` branches settle the question.
- **The §13.E sweep/cover was a no-op on its own thresholds.** Neither bound was reached, so the halt
  suppressed nothing:
  - `settled_cash` was **1.23** (BASE and USD agree; `total_cash_value` 1.23).
  - There were no fills today, so `bridge_adjusted_settled_cash` was also **1.23**.
  - A sweep needs at least +$25 and a cover needs −$5 or less.
- **No new fills were missed.** `get_account_trades(DAYS_30)` returned 5 trades, all park-vehicle trades.
  - The latest is a VOO SELL of 0.8357 @ 705.36 on 2026-10-27T13:30:06Z.
  - The other four are the VOO/SGOV pair from 2026-10-06.
  - There are zero trades on or after 2026-10-28, so this slot's fill-reconciliation duty was empty.
  - Several D2a slots have run since 10-27. That the 10-27 fill was reconciled there is an inference; on
    replay, the idempotent `trade_id` window confirms it either way.
- **The book matches what D1 recorded this afternoon.**
  - Eight strategy names: AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER.
  - Park: VOO 16.895 sh, and nothing else. SGOV is fully gone, which fits the VOO-only pin. That is
    consistent with the pin, not a read of it.

| Owed for 2026-11-03 | Recoverable later? |
|---|---|
| `ops.account_snapshot`. D2a is the sole writer and nothing backfills it (`bigquery/153`). | **Only from the capture below.** The replay writes it from these values. It must not re-read them. |
| `events.daily_marks` (8 names + VOO + SPY) and `events.signal_marks` | **Yes, exactly.** IBKR daily bars are immutable, so the replay re-pulls them. Closes are deliberately not frozen here, to avoid a second, unpinned price basis. |
| `events.regime_events` `TECHNICAL_SIGNAL` (4 keys), `perf.strategy_daily`, engine recompute | Yes. Each is recomputed mechanically from marks. |
| The tripwires that never ran: cash/park, mark-discontinuity, connector-sanity band, soft-drawdown, owner-confirmation liveness, funds deficit | The next run sees the state at that time. A condition that arose and cleared inside this window stays unobserved. |
| `ops.run_log` D2a/2026-11-03 | **No, deliberately.** Never backfill it as `completed` (RUNBOOK §48). That is why this commit's subject does not lead with the routine id. |
| `ops.web_calls` | Nothing is owed. This slot made zero metered calls; IBKR and Calendar are free. |

**Three gates could not be evaluated. Do not record them as passed:**
1. the same-day double-run guard;
2. `state.trading_enabled_mechanical`, whose verdict is unknown. That is a second, independent reason not
   to craft;
3. the cash/park tripwire.

### Perishable evidence: the inputs the snapshot needs

| Field | Value |
|---|---|
| `get_account_summary` | net_liquidation **12271.94**, equity_with_loan 12271.88, gross_position_value 12270.83, total_cash 1.23, available_funds 9050.78, buying_power 36203.14, init/maint margin 3221.09/3067.71, excess_liquidity 9204.17, dividends 0.06 |
| `get_account_balances` (BASE=USD) | cash 1.23, settled 1.23, NLV **12271.9367**, stock_market_value 12270.83, unrealized −438.52, realized 0 |
| PA TWR, `last_successful_update` 2026-11-03 22:42:44 | 1D +0.00561022 (from 20261102, start_nav 12203.472562) · 7D −0.0180693 (from 20261027) · MTD +0.0011155 (from 20261030) · 1M −0.02121219 (from 20261002) · YTD/1Y −0.04279051 (start_nav 98.711006, the young-account artifact) |
| PA NAV series | **20261103 = 12271.9367**; 20261102 = 12203.472562; 20261030 = 12258.262562 |
| Session | SPY (756733) has a 2026-11-03 RTH daily bar: O 752.72 / H 757.07 / L 752.39 / C 754.35, vol 21,674,585. The day was a regular session, so the marks and snapshot are genuinely owed. |

**Which NAV the replay should stamp.**
- **Use the PA series' 12271.9367.** It equals the `get_account_balances` NLV exactly, and it is the source
  of the TWR columns.
- Do not use the per-position `market_value` sum. That sum is 12276.99, **+6.16** against
  `gross_position_value`, so the positions surface is the outlier, as it was on 2026-09-21 (Step 0b
  caveat (iii)).
- This is not a cash/park tripwire residual. That tripwire could not be evaluated.

### Recovery and expected signature (WHAT EVERY HALTED SLOT OWES, item 6)

- **Order.** After re-auth and D1's §3 landing, replay D2a for 2026-11-03 first, then D2, then D3.
  - D2a and D2 are in the never-refire set: OPS0 STEP 2b raises the manual-rerun notice.
  - D2a's declared dependents in `ops/cadence.yaml` are **D2** and **SL3**.
  - SL3 is `catchup_safe` and needs no manual replay. It has its own catch-up loop and recovers once the
    upstream's catch-up lands.
- **Expected signature.** `missed_run`/`staleness` for **D1/D2a/D2/D3/SL3** is the outage's expected
  signature (RUNBOOK §26), not new faults.

### Unfiled findings

None. Nothing new beyond the incident itself, which is already on the calendar thread.

---

## D2 slot, 2026-11-03: HALTED

**Disposition: HALT, as D2's CONNECTOR-DOWN DISPOSITION requires.** Author: Claude (agent), the D2 slot for
operating date 2026-11-03 (scheduled fire, ~16:17 MST / 23:17Z). Nothing was written:
- no `ops.run_log` row, not even `started`;
- no `events.*` row, no `ops.alerts` row, no `events.queue_events` row;
- no `PENDING_ANALYSIS` drain, no thesis, no router review, no order crafted, nothing staged;
- **no `Watchlist.md` edit**: the 49 B-index ADDs need the Strategy-B event-identity field dedupe
  against `events.queue_events` + `events.decision_log`, which could not be read;
- no second calendar event.

**Same incident, still unresolved at 23:18Z.** The `Google-Cloud-BigQuery` MCP server is still listed as
requiring authentication, and `bq query 'SELECT 1'` returns `Invalid Credentials`. That is auth wording, so
the case is NON-WAITABLE and this slot spent no time on the wait ladder.

**Two independent halt reasons, recorded separately because they are different findings:**
1. **Connector-down (governing).** Canonical state is unreadable, and D2's own limb halts on that.
2. **Dependency gate (would also RAISE against a live connector).** D2 is `depends_on: [D1, D2a]`. D2a
   halted with no `ops.run_log` row, and D1's `completed` row is itself a deferred write (§3.8), so
   `ops.sp_assert_deps('D2', ['D1','D2a'], 2026-11-03)` would fail even after re-auth until both land.

**Calendar.** The existing event `en7a5vooom7a0c0mk1p8hnin78` got one line,
`UPDATE 16:20 MST D2 halted — no queue drain, no conversion, no orders; …`. The description was checked
first (about 1.1 KB against the 8,192 cap), and the update was sent with notifications off.

### Checks that need no connector (run, verdicts below)

- **Prose/`d1_actions` cross-check on today's `Daily.md` (commit `63f4573d`): MATCH.** The prose has 49
  actionable items and the block has 49 entries, all `watchlist` / B / "ADD to B new-entry index; B GATED,
  index only". Exits, new candidates, add candidates, router reviews and park are 0 on both sides, and the
  explicit "none" lines count zero. The tickers match one-to-one and in order, and the YAML parses. Today's
  file is trustworthy input for the replay.
- **HISTORY-DEPTH PRECHECK (git half).** `git rev-parse --is-shallow-repository` returned `false`, so the
  clone is complete and no deepen was needed.
- **CATCH-UP window (git half).** D2's last completion could not be read from `state.routine_catchup_window`
  or `ops.run_log`. The latest D2 commit marker on main is `c37cf9ff`
  (`D2 2026-11-02: …`, 23:25Z). Since then `Daily.md` has exactly one commit, today's `63f4573d`. So the
  replay's backfill set is today's snapshot only, unless BigQuery shows D2's last `completed` earlier than
  2026-11-02. In that case, re-derive the set from BigQuery and do not rely on this marker.

### What the halt cost, measured

- **The staged-order re-craft had nothing to re-craft.** At 23:17Z, `get_account_orders(show_completed=true)`
  and `get_order_instructions` both returned empty lists, the same as D2a at 22:42Z.
  - The broker holds no live order or instruction.
  - Whether `state.open_orders` holds a `pending` row is UNKNOWN; the registry was unreadable.
- **Item 6 park conversion: not a cost.** It was retired 2026-10-15 (park VOO-only, `bigquery/256`), so
  there is no park call to convert. D1's block carries no park entry.
- **Order-craft points (items 1, 2, 2a, 5).** Today's block has no exit, entry, add or termination. The
  router state D1 carried forward has A/B/D/E DO-NOT-ACTIVATE and C HYBRID (FOMC-only). The conversion half
  of D2 would therefore have staged nothing from `d1_actions`.
- **What the halt really delayed (all UNKNOWN, never "empty"):**
  - the `PENDING_ANALYSIS` drain (`state.open_queue` unreadable): any item due ≤ 2026-11-03 is now one
    evening late;
  - ROUTER EVERY-RUN DUTIES: measured out-of-cycle triggers, unanswered `FUNDAMENTAL_AXIS`, and the daily
    technical-flip divergence. These also read D2a's `TECHNICAL_SIGNAL` rows, which D2a did not write
    today;
  - the 49 Watchlist B-index ADDs.
- **IBKR account at 23:18Z, for context only, not a snapshot input** (D2a's capture above is the snapshot
  basis): `net_liquidation` 12285.34, `total_cash_value` 1.23, `gross_position_value` 12284.23.
  - The first `get_account_summary` call returned a transient `-32400 "An error occurred. Please try again
    later."`; the immediate retry succeeded.
  - `RETRY[kind=ibkr_transient;n=2;waited_s=0;outcome=recovered]`.
- **`ops.web_calls`.** Nothing is owed. This slot made zero metered calls; IBKR and Calendar are free.

| Owed for 2026-11-03 | Recoverable later? |
|---|---|
| `PENDING_ANALYSIS` drain (due ≤ today) | **Yes.** The next D2 drains `due_date <= today`. Any item whose `conservative_default` window closed tonight is applied on replay, per STEP 1. |
| ROUTER EVERY-RUN DUTIES | **Yes, re-derived.** On replay, after D2a writes today's `TECHNICAL_SIGNAL`, read state again. Never re-use tonight's carried-forward router text from `Daily.md` as a measured reading. |
| 49 Watchlist B-index ADDs | **Yes.** Convert from `63f4573d:Daily.md` through the full event-identity field dedupe. They are index-only (B is DO-NOT-ACTIVATE), so the delay is not capital-relevant. |
| Order re-craft (persist-and-wait) | **Yes.** The broker holds nothing, and the replay's registry read settles it. |
| `ops.run_log` D2/2026-11-03 | **No, deliberately.** Never backfill it as `completed` (RUNBOOK §48). That is why this commit's subject does not lead with the routine id. |

### Recovery and expected signature (WHAT EVERY HALTED SLOT OWES, item 6)

- **Order.**
  1. Re-auth.
  2. Land D1's §3.
  3. Replay D2a for 2026-11-03.
  4. Replay D2. Its dependency gate then passes, and its CATCH-UP CHECK picks up `63f4573d:Daily.md`.
  5. Replay D3.
- **Never-refire.** D2 is in the never-refire set (not `catchup_safe`), so OPS0 STEP 2b raises the
  manual-rerun notice. Otherwise the next regular D2 fire converts it through the CATCH-UP CHECK.
- **Dependents.** D2's only declared dependent in `ops/cadence.yaml` is **D3** (`catchup_safe`). D3 has its
  own catch-up loop and recovers once the upstream's catch-up lands.
- **Expected signature.** `missed_run`/`staleness` for **D1/D2a/D2/D3/SL3** is the outage's expected
  signature (RUNBOOK §26), not new faults.

### Unfiled findings

- **Owner D1 (prose hygiene), info.** Today's `d1_actions` entries carry
  `source_research_screen_id: DEFERRED (…)` instead of an id. The replay D2 must back-fill the id from the
  landed §3 #1 row's `entry_id` before citing it in any queue or decision payload. Otherwise a literal
  "DEFERRED" string enters a durable record. Info-level only; this is the expected shape of a degraded D1.

## AR_att slot, 2026-11-03: HALTED

**Disposition: HALT, as AR_att's CONNECTOR-DOWN DISPOSITION requires.** Author: Claude (agent), the AR_att
slot for operating date 2026-11-03 (scheduled fire, ~17:06 MST / 2026-11-04 00:06Z). Nothing was written:
- no `ops.run_log` row, not even `started`;
- no STEP 0 reconciliation, no due scan, no RESIDUAL SWEEP, no heal;
- no `ops.sp_write_adversarial_review` call, no `attacker-complete` transition, no `ops.alerts` row;
- **no quiet-day line.** The review queue is UNKNOWN, not empty;
- no second calendar event.

**Same incident, still unresolved at 00:06Z.** The `Google-Cloud-BigQuery` MCP server is still listed as
requiring authentication. `bq --project_id=stock-trading-498512 query 'SELECT * FROM state.trading_day_today'`
returns `Invalid Credentials`, and `gcloud auth list` shows no credentialed account. That is auth wording, so
the case is NON-WAITABLE and this slot spent no time on the wait ladder.

**Calendar.** The existing event `en7a5vooom7a0c0mk1p8hnin78` got one line, `UPDATE 17:10 MST AR_att halted —
first review-lane routine blocked (prior reports were all capital-path); …`. The description was checked first
(about 1.2 KB against the 8,192 cap, ending on a complete sentence), and the update was sent with
notifications off. Start/end times were preserved.

### Checks that need no connector (run, verdicts below)

- **HISTORY-DEPTH PRECHECK (git half).** `git rev-parse --is-shallow-repository` returned `false`; the clone is
  complete (1,894 commits reachable from `origin/main` at `90bfc3ab`).
- **Operating-plane date.** Taken from the Denver clock: 2026-11-03 (MST). The UTC clock already read
  2026-11-04, the trap the limb names.

### What the halt cost — a PRIOR from git, not a measurement

The queue could not be read, so nothing below is a finding about `state.open_queue_detail`. It is what the
repo says the producers did, and the replay must re-measure it.

- **Likely due today: three `pre-mortem` re-reviews.** SL2 commit `450c0f36` (2026-11-03 01:10Z =
  2026-11-02 18:10 MST, Denver enqueue date **2026-11-02**) re-enqueued `premortem-A-2026-a3` cycle 11,
  `premortem-B-2026-a3` cycle 12 and `premortem-D-2026-a3` cycle 10. On the Denver plane their
  `attacker_due_date` would be **2026-11-03 (today)** and `orchestrator_due_date` 2026-11-04.
- **Possibly open: five `divergence-review` items.** M1b commit `087c3796` (2026-11-01) reports 5 divergences
  (A–E), the lane's monthly recurring producer. Their attacker due date would be 2026-11-02, so the
  2026-11-02 AR_att fire should have taken them. Whether it did is UNKNOWN from here.
- **Last enqueue / gap.** The last enqueue git can see is 2026-11-02 (Denver), a gap of 1 day. That is well
  inside the lane's pinned Denver gap distribution (longest healthy gap 27 days). It is labelled a prior,
  not a measurement.
- **`ops.web_calls`.** Nothing is owed. This slot made zero metered calls; Calendar is free.

| Owed for 2026-11-03 | Recoverable later? |
|---|---|
| STEP 0, due scan, RESIDUAL SWEEP + heal | **Yes, exactly.** The predicates are `<= today`, an entry due today is still due on replay, and each artifact is pinned by `p_source_commit_sha` and does not decay. |
| Attacks on the (likely) three A/B/D pre-mortem cycles | **Yes, the content.** The next AR_att fire with BigQuery live attacks them from `pending`. |
| Due-date discipline (attacker 11-03 → orchestrator 11-04) | **No.** It slips with the paired `orchestrator_due_date` and does not come back. |
| `ops.run_log` AR_att/2026-11-03 | **No, deliberately.** Never backfill it as `completed` (RUNBOOK §48). That is why this commit's subject does not lead with the routine id. |

### Recovery and expected signature (WHAT EVERY HALTED SLOT OWES, item 6)

- **Order.** Re-auth, then the D1 → D2a → D2 → D3 replay above. AR_att itself is queue-driven and not
  `catchup_safe`: no replay is owed, and the next regular AR_att fire picks up everything with
  `attacker_due_date <= today`.
- **Dependents (`ops/cadence.yaml depends_on`).**
  - **AR_orc** (`depends_on: [AR_att]`): HALTS by cascade (UPSTREAM-HALT LIMB). An AR_orc fire that precedes
    AR_att's next live fire will correctly find nothing `attacker-complete` for today's entries, and must not
    read that as a quiet lane.
  - **SL5** (`depends_on: [AR_orc]`): queue-driven, HALT, as AR_att. No replay is owed; it recovers when the
    AR_orc → SL5 handoff next lands.
- **Expected signature.** `missed_run` for **AR_att / AR_orc** on 2026-11-03 joins the D1/D2a/D2/D3/SL3
  outage signature (RUNBOOK §26), not new faults.

### Unfiled findings

- **Owner OPS0 (UNFILED-FINDINGS INTAKE) / RUNBOOK §26 step 4, info. FIXED IN THIS COMMIT — file as
  already resolved.** The intake read only `ops/spikes/bigquery-deauth-*-halt-record.md`. This incident's
  record is D1's `*-d1-deferred-writes.md`, because D2a, D2 and AR_att followed its header and appended here.
  So its three unfiled-findings headings (D1 §6, D2a, D2) would have been skipped by the intake. A one-line
  correction in `Claude_Task_Plan.md` §OPS0 and RUNBOOK §26 step 4 widens the glob to
  `ops/spikes/bigquery-deauth-*.md` and accepts the heading at any level. The pre-existing records are
  unaffected: every older `Unfiled findings` heading is already marked `FILED`, and the 2026-09-21 D1 record
  has none.

## AR_orc slot, 2026-11-03: HALTED

**Disposition: HALT.** Author: Claude (agent), the AR_orc slot for operating date 2026-11-03 (scheduled fire,
~17:36 MST / 2026-11-04 00:36Z). The halt has two independent grounds, and they are different findings:
1. **Own pre-flight failed (the governing reason).** Step (1) of the QUIET-RUN FAST PATH says "if BigQuery is
   unreachable, HALT". The `Google-Cloud-BigQuery` MCP server is still listed as requiring authentication.
   `bq --project_id=stock-trading-498512 query 'SELECT * FROM state.trading_day_today'` returns
   `Invalid Credentials`, and `gcloud auth list` shows no credentialed account. That is auth wording, so the
   case is NON-WAITABLE and no time went on the wait ladder.
2. **Upstream cascade (would apply even with a live connector).** AR_att's halt record (`1fd678a2`, merged
   as `e12ec854`) is a same-day halt record for the named upstream on `origin/main`. Under the UPSTREAM-HALT
   LIMB that alone makes the DEPENDENCY GATE's FUTILE branch apply. The gate was never reached, because (1)
   comes first. The halt record was **not** converted into a `completed` row for AR_att.

Nothing was written:
- no `ops.run_log` row, not even `started`;
- no `sp_auto_resolve_alerts`, no STEP 0 / STEP 0.5, no due scan, no RESIDUAL SWEEP, no NOTICE-CLOSE PASS;
- no orchestrator verdict, no `PENDING_REVIEW` close or re-enqueue, no `ops.alerts` row;
- no sub-agent was spawned, because there was nothing to grade;
- **no quiet-day line.** The orchestrator lane is UNKNOWN, not empty;
- no second calendar event.

**Calendar.** The existing event `en7a5vooom7a0c0mk1p8hnin78` got one line, `UPDATE 17:40 MST AR_orc halted
(own pre-flight failed; cascade as predicted) — …`. The description was checked first (about 1.5 KB against
the 8,192 cap, ending on a complete sentence), and the update was sent with notifications off. Start/end
times were preserved (22:30Z–23:00Z).

### Checks that need no connector

- **HISTORY-DEPTH PRECHECK (git half).** `git rev-parse --is-shallow-repository` returned `false`.
- **Operating-plane date.** Taken from the Denver clock: 2026-11-03 MST. The UTC clock already read
  2026-11-04.

### What the halt cost: a prior from git, not a measurement

- **The three A/B/D pre-mortem cycles that AR_att flagged** (SL2 `450c0f36`) would carry
  `orchestrator_due_date` **2026-11-04**. So even a live AR_orc fire tonight would not have found them due.
  More importantly, they cannot reach `attacker-complete` until AR_att's next live fire. This slot's halt
  costs them nothing beyond AR_att's halt.
- **Anything AR_att completed on its 2026-11-02 fire** (for example the M1b `087c3796` divergence items)
  would carry `orchestrator_due_date` <= 2026-11-03 and was due tonight. Git cannot tell whether such rows
  exist: AR_att and AR_orc quiet runs commit nothing (`REPO OUTPUT: NONE`). So the count is **UNKNOWN**.
  The DIVERGENCE-REVIEW STANDING-CYCLE PRE-CHECK and the NOTICE-CLOSE PASS are UNKNOWN for the same reason.
- **Last handoff / gap.** This cannot be measured. The producer-side basis
  (`MAX(event_ts)` of `attacker-complete`) is a BigQuery read.
- **`ops.web_calls`.** Nothing is owed. Zero metered calls were made; Calendar is free.

| Owed for 2026-11-03 | Recoverable later? |
|---|---|
| STEP 0 / 0.5, due scan, RESIDUAL SWEEP + heal, NOTICE-CLOSE PASS | **Yes, exactly.** The predicates are `<= today`, and the next live fire re-reads them. |
| Grading of any `attacker-complete` entry due <= 11-03 | **Yes, the content.** The transcripts are pinned by `p_source_commit_sha` and do not decay. |
| Due-date discipline for those entries | **No.** It slips by at least one day. |
| `ops.run_log` AR_orc/2026-11-03 | **No, deliberately.** It is never backfilled as `completed` (RUNBOOK §48). That is why this commit's subject does not lead with the routine id. |

### Recovery and expected signature (WHAT EVERY HALTED SLOT OWES, item 6)

- **Order.** Re-auth, then the D1 → D2a → D2 → D3 replay above. Then **AR_att before AR_orc**: AR_orc is
  queue-driven and not `catchup_safe`, so no replay is owed. The next regular AR_orc fire after AR_att's next
  live fire picks up everything with `orchestrator_due_date <= today`. An AR_orc fire that lands first will
  correctly find nothing for the A/B/D cycles, and must not read that as a quiet lane.
- **Dependents (`ops/cadence.yaml depends_on`).** **SL5** (`depends_on: [AR_orc]`): queue-driven, HALT, as
  AR_att. No replay is owed. It has its own catch-up loop and recovers once the AR_orc → SL5 handoff next
  lands. This halt wrote no `ops.run_log` row, so SL5's gate meets the "invisible upstream halt" case that its
  own section flags (the `dependency_gate_misreads_upstream_halt_record` exposure). This halt record on
  `origin/main` is the FUTILE evidence for it.
- **Expected signature.** `missed_run` for **AR_orc** (and SL5 if it fires tonight) on 2026-11-03 joins the
  outage signature (RUNBOOK §26). These are not new faults.

### Unfiled findings

None from this slot.

## D3 slot, 2026-11-03: HALTED

**Disposition: HALT, per the FLEET CONNECTOR-DOWN DISPOSITION TABLE (D3 row: HALT, `catchup_safe`).**
Author: Claude (agent), the D3 slot for operating date 2026-11-03 (scheduled fire, ~17:47 MST / 2026-11-04
00:47Z). Nothing was written:
- no `ops.run_log` row, not even `started`; the SAME-DAY DOUBLE-RUN GUARD could not be evaluated (it is a
  BigQuery read), so this slot cannot tell whether an earlier D3 fire completed today. None did on git
  evidence: no D3 commit since the incident began;
- no `sp_auto_resolve_alerts`, no TRADING-ENABLE read, no dependency gate, no QUEUE HYGIENE / terminal-entry
  sweep, no staged-order registry reconcile, no GO-WITHOUT-ORDER check, no PRE-FILL INVALIDATION RE-CHECK,
  no golden-scenario prose-regression check, no self-heal / monitor-promotion step, no DISPLAY-TIMEZONE write;
- no order crafted, re-crafted or deleted; no `ops.alerts` / `events.*` row;
- **no quiet-day line.** Queue, registry and self-heal state are UNKNOWN, not clean;
- no second calendar event.

**Two independent halt reasons:**
1. **Connector-down (governing).** The `Google-Cloud-BigQuery` MCP server is still listed as requiring
   authentication; `bq query 'SELECT 1'` returns `Invalid Credentials`; `gcloud auth list` shows no
   credentialed account. Auth wording, so NON-WAITABLE; no time went on the wait ladder.
2. **Dependency gate (would also fail against a live connector).** D3 is `depends_on: [D2]`, and D2 halted
   with no `ops.run_log` row (D2 slot above), so `ops.sp_assert_deps('D3', ['D2'])` would raise until D2's
   replay lands.

**Calendar.** The existing event `en7a5vooom7a0c0mk1p8hnin78` got one line, `UPDATE 17:50 MST D3 halted (as
predicted) — …`. The description was checked first (about 1.5 KB against the 8,192 cap, ending on a complete
sentence) and the update was sent with notifications off; start/end times were preserved (22:30Z–23:00Z).
The event's own deletion is D3's job once BigQuery is confirmed live (calendar reconcile bullet "For a
`[Claude] ATTENTION — RE-AUTH BigQuery connector` event"), so the replay D3 deletes it.

### Checks that need no connector

- **HISTORY-DEPTH PRECHECK (git half).** `git rev-parse --is-shallow-repository` returned `false`.
- **Broker side of the registry reconcile, measured at 00:47Z:** `get_account_orders(show_completed=true)`
  and `get_order_instructions` both returned empty lists, matching D2a (22:42Z) and D2 (23:17Z). So nothing
  can sit un-tapped at the broker; whether `state.open_orders` holds a `pending` row is UNKNOWN.
- **Operating-plane date.** Denver clock: 2026-11-03 MST (UTC already read 2026-11-04).
- **`ops.web_calls`.** Nothing is owed: zero metered calls (IBKR and Calendar are free).

| Owed for 2026-11-03 | Recoverable later? |
|---|---|
| Queue hygiene (terminal sweep, `queue_item_stale`, venue-claim, lifecycle-provenance) | **Yes.** All predicates are state reads re-done by the replay. |
| Registry ↔ IBKR reconcile, GO-WITHOUT-ORDER, PRE-FILL re-check | **Yes.** Broker holds nothing (measured above); the replay's registry read settles the BigQuery side. |
| Golden-scenario prose-regression check | **Yes, exactly.** It keys on `governing_files` changed since D3's last completed run, which a later run still sees. |
| Self-heal / monitor-promotion / CI-findings adjudication | **Yes.** Readiness views are re-read on replay. |
| RE-AUTH calendar event deletion | **Yes.** First D3 with a passing BigQuery pre-flight. |
| `ops.run_log` D3/2026-11-03 | **No, deliberately.** Never backfilled as `completed` (RUNBOOK §48); hence no routine-id prefix on this commit's subject. |

### Recovery and expected signature (WHAT EVERY HALTED SLOT OWES, item 6)

- **Order.** Re-auth → land D1's §3 → replay D2a → replay D2 → **replay D3** (the catch-up path,
  `catchup_safe: true`; its dependency gate passes only after D2's replay lands). Then AR_att before AR_orc,
  as in the AR_orc slot above.
- **Dependents.** D3 has **no** declared dependent in `ops/cadence.yaml` (no routine lists `D3` in
  `depends_on`), so no downstream replay is owed on its account.
- **Expected signature.** `missed_run`/`staleness` for **D3** on 2026-11-03 joins the outage signature
  (RUNBOOK §26), not a new fault.

### Unfiled findings

None from this slot.

## SL5 slot, 2026-11-03: HALTED

**Disposition: HALT, per the FLEET CONNECTOR-DOWN DISPOSITION TABLE (SL5 row: HALT, "as AR_att").** Author:
Claude (agent), the SL5 slot for operating date 2026-11-03 (scheduled fire, ~18:25 MST / 2026-11-04 01:25Z).
There are two grounds for the halt:
1. **Own pre-flight failed (the governing reason).** Step (1) of SL5's QUIET-RUN FAST PATH says "if BigQuery
   is unreachable, HALT and never emit the no-op line". The `Google-Cloud-BigQuery` MCP server still requires
   authentication. `bq --project_id=stock-trading-498512 query 'SELECT * FROM state.trading_day_today'`
   returns `Invalid Credentials`, and `gcloud auth list` shows no credentialed account. That is auth wording,
   so the case is NON-WAITABLE and no time went on the wait ladder.
2. **Upstream cascade (would apply even with a live connector).** AR_orc, SL5's only declared dependency, has
   a same-day halt record on `origin/main` (`4c7cbc45`, merged as `e7db53be`) and wrote no `ops.run_log` row.
   Under SL5's DEPENDENCY GATE paragraph, that is the FUTILE branch with zero polls waited
   (AR_orc is `catchup_safe: false` in `ops/cadence.yaml`, checked by parsing the file). It is also the
   "invisible upstream halt" case that the paragraph flags as the
   `dependency_gate_misreads_upstream_halt_record` exposure. The gate was never reached, because (1) comes
   first, and the halt record was **not** turned into a `completed` row for AR_orc.

Nothing was written:
- no `ops.run_log` row, not even `started`;
- no kill-switch gate, dependency gate, `sp_auto_resolve_alerts`, STEP 0 heal, or `sp_score_theater()`;
- none of the three roster inputs was read;
- no roster mutation, no `ops.roster_change_log` row, no `ops.alerts` row;
- **no "No roster mutations due." line.** All three inputs are UNKNOWN, not empty;
- no second calendar event. The existing event gets one `UPDATE … SL5 halted` line.

### Checks that need no connector

- **HISTORY-DEPTH PRECHECK (git half).** `git rev-parse --is-shallow-repository` returned `false`.
- **Operating-plane date.** Taken from the Denver clock: 2026-11-03 MST. The UTC clock already read
  2026-11-04.
- **Repo-side roster state (a prior, not the BigQuery inputs).** `strategy/roster.yaml` has A–E, all
  `roster_state: adopted`. `Strategy.md` has no `[CANDIDATE]` heading. Since 2026-10-20, no commit
  on `origin/main` mentions `probe-register`, `adopt-register`, a SUFFICIENT `strategy-adoption` verdict or a
  TERMINATED transition. So the git evidence suggests nothing was due for registration, but it cannot rule
  that out. In particular, an SL3 `probe-register`/`adopt-register` enqueue or a D2/AR_orc TERMINATED row
  would be BigQuery-only.
- **`ops.web_calls`.** Nothing is owed. Zero metered calls were made; Calendar is free.

| Owed for 2026-11-03 | Recoverable later? |
|---|---|
| STEP 0 heal, theater-judge score, the three roster-input reads | **Yes, exactly.** The predicates are `<= today` or anti-joins on `ops.roster_change_log`, so the next live fire re-reads them. |
| Any due roster mutation (SHADOW / PROBE / ADOPT register, deregister) | **Yes, the content.** It is applied on the next live fire after AR_orc's. Its timing slips by at least one day. |
| `ops.run_log` SL5/2026-11-03 | **No, deliberately.** It is never backfilled as `completed` (RUNBOOK §48). That is why this commit's subject does not start with the routine id. |

### Recovery and expected signature (WHAT EVERY HALTED SLOT OWES, item 6)

- **Order.** Re-auth, then the D1 → D2a → D2 → D3 replay above. Then AR_att, then AR_orc, then **SL5**. SL5 is
  queue-driven and not `catchup_safe`, so no replay is owed. The next regular SL5 fire (Sun–Thu) after AR_orc's
  next live `completed` run picks up everything. If an SL5 fire lands before that, its dependency gate must
  read AR_orc's halt correctly. It must not report a quiet run.
- **Dependents (`ops/cadence.yaml depends_on`).** No routine lists `SL5` in `depends_on`, so no downstream
  replay is owed on its account.
- **Expected signature.** A `queue_driven_missed_fire` / `missed_run` for **SL5** on 2026-11-03 is part of the
  outage signature (RUNBOOK §26). It is not a new fault.

### Unfiled findings

None from this slot.

## SL3 slot, 2026-11-03: HALTED

**Disposition: HALT, per the FLEET CONNECTOR-DOWN DISPOSITION TABLE (SL3 row: HALT, `catchup_safe`).** Author:
Claude (agent), the SL3 slot for operating date 2026-11-03 (scheduled fire, ~19:10 MST / 2026-11-04 02:10Z).
There are two grounds for the halt:
1. **Own pre-flight failed (the governing reason).** Step (1) of SL3's QUIET-RUN FAST PATH says "if BigQuery
   is unreachable, HALT and never emit the no-transition line". The `Google-Cloud-BigQuery` MCP server still
   requires authentication. `bq --project_id=stock-trading-498512 query 'SELECT * FROM state.trading_day_today'`
   returns `Invalid Credentials`, and `gcloud auth list` shows no credentialed account. Auth wording, so
   NON-WAITABLE; no time went on the wait ladder.
2. **Upstream halt (would apply even with a live connector).** D2a, SL3's only declared dependency, halted with
   no `ops.run_log` row (D2a slot above). Under SL3's DEPENDENCY GATE → UPSTREAM-HALT LIMB that is the FUTILE
   branch with zero polls waited. The gate was never reached, because (1) comes first, and the D2a halt record
   was **not** turned into a `completed` row.

Nothing was written:
- no `ops.run_log` row, not even `started`; the SAME-DAY DOUBLE-RUN GUARD could not be evaluated (a BigQuery
  read). No SL3 commit exists on `origin/main` since the incident began;
- no kill-switch gate, `sp_auto_resolve_alerts`, dependency gate, empty-population check, coverage read,
  re-resolve row, R3 NOTICE-CLOSE PASS or `probe_funding_stalled` duty;
- no `analytics.strategy_incubation_perf` / `events.shadow_positions` / `events.strategy_lifecycle` /
  `ops.roster_change_log` row, no `probe-register` / `adopt-register` enqueue, no `ops.alerts` row;
- no `arsenal-heartbeat` decision-log entry (W5's META-HEARTBEAT CHECK will see the gap; it is part of this
  outage, not a heartbeat defect);
- **no "SL3 evaluated, no incubation transition." line.** SHADOW/PAPER/PROBE populations are UNKNOWN, not empty;
- no second calendar event. The existing event `en7a5vooom7a0c0mk1p8hnin78` got one line, `UPDATE 19:15 MST SL3
  halted …`, after checking the description (~2.2 KB of 8,192, ending on a complete sentence), notifications
  off, start/end preserved.

### Checks that need no connector

- **HISTORY-DEPTH PRECHECK (git half).** `git rev-parse --is-shallow-repository` returned `false`.
- **Operating-plane date.** Denver clock: 2026-11-03 MST (UTC already read 2026-11-04).
- **Repo-side population prior.** `strategy/roster.yaml` has A–E, all `roster_state: adopted`, and the SL5 slot
  above found no `probe-register` / `adopt-register` / SHADOW-entry evidence on `origin/main` since 2026-10-20.
  So git suggests SHADOW/PAPER/PROBE are empty (a quiet fire), but SHADOW entries are BigQuery-only and this
  cannot be confirmed.
- **`ops/cadence.yaml` (parsed).** SL3: `depends_on: [D2a]`, `catchup_safe: true`. No routine lists `SL3` in
  `depends_on`.
- **`ops.web_calls`.** Nothing is owed: zero metered calls (Calendar is free).

| Owed for 2026-11-03 | Recoverable later? |
|---|---|
| STEP 1 forward-test series (shadow signals / paper sim fills) for any SHADOW/PAPER member | **Yes, exactly — conditional.** STEP 1's per-member day set covers every day `>= MAX(incubation_day)` with a `state.daily_marks_curated` row, so 2026-11-03 is re-covered once D2a's OWN marks catch-up lands that day's marks (OPS0 never refires D2a). |
| STEPS 2–4 readiness / SHADOW→PAPER advance / culls; R1–R4 ramp monitor; STEP 5 coverage | **Yes.** All are reads of views re-evaluated on the next live fire (catch-up path, `catchup_safe: true`). |
| R3(a) `ramp_surprise_cut` notices | **Yes.** Keyed on `idx > last_surprise_idx` of the previous heartbeat, so a skipped heartbeat delays but does not lose them. |
| `arsenal-heartbeat` for 2026-11-03 | **No, deliberately.** Never backfilled; the gap is the outage signature. |
| `ops.run_log` SL3/2026-11-03 | **No, deliberately.** Never backfilled as `completed` (RUNBOOK §48); hence no routine-id prefix on this commit's subject. |

### Recovery and expected signature (WHAT EVERY HALTED SLOT OWES, item 6)

- **Order.** Re-auth → land D1's §3 → replay D2a (manual / its own marks catch-up) → D2 → D3 → **SL3** (the
  catch-up path, `catchup_safe: true`; its dependency gate passes only once D2a has a `completed` row for the
  replayed operating date). SL3 needs no manual replay of its own: its STEP 1 loop recovers 2026-11-03 once
  D2a's marks catch-up lands.
- **Dependents (`ops/cadence.yaml depends_on`).** None — no routine lists `SL3`, so no downstream replay is owed
  on its account.
- **Expected signature.** `missed_run` / `staleness` for **SL3** on 2026-11-03, plus a missing
  `arsenal-heartbeat` noticed by W5's META-HEARTBEAT CHECK, join the outage signature (RUNBOOK §26), not new
  faults.

### Unfiled findings

None from this slot.

## OPS2 slot, 2026-11-03: HALTED

**Disposition: HALT, per the FLEET CONNECTOR-DOWN DISPOSITION TABLE (OPS0/OPS2 row: HALT, not `catchup_safe`, no
replay owed).** Author: Claude (agent), the OPS2 (catch-up executor) slot for operating date 2026-11-03 (scheduled
fire, ~21:15 MST / 2026-11-04 04:15Z, on its configured cron).

**Why it halted.** OPS2's QUIET-RUN FAST PATH step (2) is a BigQuery-only connector pre-flight
(`state.trading_day_today`). The `Google-Cloud-BigQuery` MCP server still requires authentication.
`bq --project_id=stock-trading-498512 query 'SELECT * FROM state.trading_day_today'` returns `Invalid Credentials`,
and `gcloud auth list` shows no credentialed account. That is auth wording, so the case is NON-WAITABLE and no time
went on the wait ladder. OPS2 has no dependency gate (`depends_on: []`), so the halt has only this one ground.

Nothing was written or hosted:
- no SAME-DAY DOUBLE-RUN GUARD read (it is a BigQuery read), and no `ops.run_log` row, not even `started`;
- no `sp_auto_resolve_alerts`, no STEP 0 `sp_backfill_run_log_from_markers` self-heal;
- no STEP 1 `state.catchup_refire_readiness` read and no STEP 1a `PENDING_QUALIFICATION` lead-readiness read;
- **no routine hosted inline.** Even with the feed known, every hosted routine would itself fail its own BigQuery
  pre-flight, so STEP 2 item 4's CONNECTOR CHECK would have DEFERRED each one (`deferred:connector`);
- no `ops.catchup_refire_log`, `ops.alerts` or `ops.web_calls` row;
- **no quiet-night line.** The miss feed and the lead-readiness lane are UNKNOWN, not empty;
- IBKR, FMP and Gmail were not probed (conditional, and nothing was hosted). Calendar was used only for the
  existing event's single `UPDATE 21:20 MST OPS2 halted …` line, after checking the description (~2.8 KB of 8,192,
  ending on a complete sentence), with notifications off and start/end preserved.
- **Zero metered calls** were made (Calendar is free), so nothing is owed to `ops.web_calls`.

### Checks that need no connector

- **HISTORY-DEPTH PRECHECK (git half).** `git rev-parse --is-shallow-repository` returned `false`.
- **Operating-plane date.** Denver clock: 2026-11-03 MST (UTC already read 2026-11-04).
- **`ops/cadence.yaml` (parsed).** OPS2: `depends_on: []`, `catchup_safe: false`. No routine lists `OPS2` in
  `depends_on`.
- **What the feed would likely have held (git prior, not the BigQuery read).** Every slot of this incident so far
  wrote no `ops.run_log` row: D1 (degraded), D2a, D2, AR_att, AR_orc, D3, SL2, SL5 and SL3. Of those, the
  `catchup_safe` set that `state.catchup_refire_readiness` would normally surface is **D1, D3 and SL3** (plus any
  period-tier slot due today, which this record cannot see). D2a and D2 are in the never-refire set, so OPS0 STEP 2b
  owns their manual-rerun notice. AR_att, AR_orc, SL2 and SL5 are queue-driven and owe no replay.

| Owed for 2026-11-03 | Recoverable later? |
|---|---|
| Inline catch-up of the outage's `catchup_safe` misses (D1, D3, SL3, …) | **Yes.** The misses stay in `state.catchup_refire_readiness` until a run logs them. The next live OPS2 fire after re-auth (Sun–Thu, 04:15Z) hosts them, bounded at N=4 per run. OPS0's `catchup_refire_blocked` email covers the residual. |
| STEP 0 marker self-heal | **Yes, exactly.** `sp_backfill_run_log_from_markers` is idempotent and also runs from `sp_assert_deps` and the nightly `cadence_check`. Note that this outage's halt-record commits use the RUNBOOK §48 subject, so they create no routine markers and nothing is wrongly healed to `completed`. |
| STEP 1a hosted SL1 for any due `lead-readiness` item | **Yes.** The predicate is `due_date <= today`, so the next live fire re-reads it. A due item that stays open is surfaced by D3's `queue_item_stale` warning. |
| `ops.run_log` OPS2/2026-11-03 | **No, deliberately.** It is never backfilled (WHAT EVERY HALTED SLOT OWES item 3). That is why this commit's subject has no routine-id prefix. |

### Recovery and expected signature (WHAT EVERY HALTED SLOT OWES, item 6)

- **Order.** Re-auth, then land D1's §3, then the D2a → D2 → D3 replay above, then the AR_att → AR_orc → SL5 and SL3
  recoveries above. **OPS2 itself needs no replay.** Its next regular fire is the catch-up mechanism for D1, D3, SL3
  and any other `catchup_safe` miss that is still open. If re-auth lands before 2026-11-04 22:30 MST, OPS0's next
  sweep is the fallback.
- **Dependents (`ops/cadence.yaml depends_on`).** None. No routine lists `OPS2`, so no downstream replay is owed on
  its account.
- **Expected signature.** A `missed_run` for **OPS2** on 2026-11-03 is part of the outage signature (RUNBOOK §26).
  It is not a new fault. The same holds for any `catchup_refire_blocked` email that OPS0 raises after re-auth for
  this outage's slots.

### Unfiled findings

None from this slot.

## OPS0 slot, 2026-11-03: HALTED

**Disposition: HALT, per the FLEET CONNECTOR-DOWN DISPOSITION TABLE (OPS0/OPS2 row: HALT, not `catchup_safe`, no
replay owed).** Author: Claude (agent), the OPS0 (cadence watchdog) slot for operating date 2026-11-03 (scheduled
fire, ~21:30 MST / 2026-11-04 04:30Z, on its configured cron).

**Why it halted.** OPS0's observability preamble requires a BigQuery connector pre-flight
(`state.trading_day_today`). The `Google-Cloud-BigQuery` MCP server still requires authentication. `bq ls` returns
`Invalid Credentials`, and `gcloud auth list` shows no credentialed account. That is auth wording, so the case is
NON-WAITABLE and no time went on the wait ladder. OPS0 has no dependency gate (`depends_on: []`), so the halt has only
this one ground.

Nothing was written:
- no `ops.run_log` row, not even `started`; no `sp_auto_resolve_alerts`;
- no UNFILED-FINDINGS INTAKE (it needs BigQuery live, so this incident's `Unfiled findings` headings stay unfiled);
- no STEP 1 `state.catchup_refire_readiness` read, so no STEP 2 re-fire and no `catchup_refire_blocked` email;
- no STEP 2b manual-rerun notice for the never-refire set (D2a and D2 both halted today and are owed one);
- no STEP 2c `state.staged_order_reconciliation_overdue` read;
- STEP 3 (trigger-config sweep) is Sunday-only and would have been skipped anyway (2026-11-03 is a Tuesday);
- no STEP 4 (c)/(e)/(f) alerts or resolves, and no STEP 5 telemetry sweep;
- no `ops.catchup_refire_log`, `ops.alerts`, `events.decision_log` or `ops.web_calls` row;
- **no "no catchup-safe misses pending" heartbeat.** The miss feed is UNKNOWN, not empty;
- Calendar was used only for the existing event's single `UPDATE 21:35 MST OPS0 halted …` line, after checking the
  description (~3.1 KB of 8,192, ending on a complete sentence), with notifications off and start/end preserved.
- **Zero metered calls** were made (Calendar and GitHub are free), so nothing is owed to `ops.web_calls`.

### Checks that need no connector

- **HISTORY-DEPTH PRECHECK.** `git rev-parse --is-shallow-repository` returned `false` (1,906 commits reachable from
  `origin/main`), so git verdicts this run carry evidentiary weight.
- **STEP 4(a) DETECT (pure git).** After `git fetch origin '+refs/heads/*:refs/remotes/origin/*' --prune`,
  `git ls-remote --heads origin 'claude/*'` lists **zero** branches, so no `claude/*` ref is unlanded and there is no
  stranded-branch candidate. Every halt record of this incident (PRs #157–#159 and earlier) is merged.
- **STEP 4(f) git half.** Latest routine-subject commit on `origin/main` is `63f4573d` (D1 2026-11-03, degraded,
  writes deferred). The `ops.run_log` half of (f) cannot be read, so no unlanded-completed-run verdict is drawn.
- **`ops/cadence.yaml` (parsed).** OPS0: `depends_on: []`, `catchup_safe: false`. No routine lists `OPS0` in
  `depends_on`.

| Owed for 2026-11-03 | Recoverable later? |
|---|---|
| STEP 2 re-fire / `catchup_refire_blocked` email for the outage's `catchup_safe` misses (D1, D3, SL3, OPS1 if missed, …) | **Yes.** The misses stay in `state.catchup_refire_readiness` until a run logs them. OPS2's next live fire hosts them inline first; OPS0's next live sweep is the fallback. |
| STEP 2b manual-rerun notice for D2a and D2 (never-refire set) | **Yes, if they are still missed.** STEP 2b re-reads `state.cadence_watch` on every live run and re-checks completion first. A manual re-run of D2a then D2 after re-auth needs no notice at all. |
| UNFILED-FINDINGS INTAKE for this incident's `Unfiled findings` headings | **Yes, exactly.** It runs on OPS0's first run with BigQuery live, and marks each heading `FILED <date>`. |
| STEP 2c / STEP 5 reads | **Yes.** Both are recomputed from live state on every run. |
| `ops.run_log` OPS0/2026-11-03 | **No, deliberately.** It is never backfilled (WHAT EVERY HALTED SLOT OWES item 3). That is why this commit's subject has no routine-id prefix. |

### Recovery and expected signature (WHAT EVERY HALTED SLOT OWES, item 6)

- **Order.** Re-auth, then land D1's §3, then the D2a → D2 → D3 replay above, then the AR_att → AR_orc → SL5 and SL3
  recoveries above. **OPS0 itself needs no replay.** Its next regular fire (Sun–Thu, 04:30Z) runs the intake and the
  STEP 2/2b catch-up fallback.
- **Dependents (`ops/cadence.yaml depends_on`).** None. No routine lists `OPS0`, so no downstream replay is owed on
  its account.
- **Expected signature.** A `missed_run` for **OPS0** on 2026-11-03 is part of the outage signature (RUNBOOK §26). It
  is not a new fault. The same holds for `catchup_refire_blocked` emails that OPS0 raises after re-auth for this
  outage's slots.

### Unfiled findings

None from this slot.
