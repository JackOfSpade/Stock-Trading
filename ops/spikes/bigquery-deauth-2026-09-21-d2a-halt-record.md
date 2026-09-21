# BigQuery connector de-auth, 2026-09-21 — the D2a slot's halt record

**Status: HALT RECORD, CLOSED as a run. Nothing was written anywhere — no `ops.run_log` row (not even
`started`), no `events.*` row, no `ops.alerts` row, no order crafted, no calendar event created.**
Author: Claude (agent), D2a slot of 2026-09-21, fired on schedule at its ordinary 16:40 MT cron.
This file changes no live BigQuery object and no trigger.

**This is the SAME INCIDENT as `ops/spikes/bigquery-deauth-2026-09-21-d1-deferred-writes.md`**, not a
second one — same OAuth grant, same operating date, D1's slot ~35 minutes earlier. That file is D1's
**deferred-writes ledger** (ten writes it composed and could not land). This file is the D2a slot's
**halt record**: D2a deferred no composed write, because it never got far enough to compose one. What
it owes instead is (a) an account of what the halt actually cost, measured rather than assumed, and
(b) the perishable connector evidence the replay cannot go back and re-read.

**Read first:** `ops/RUNBOOK.md` §26 (the 2026-06-26 precedent — same failure class, same branch),
`Claude_Task_Plan.md` §Observability → connector pre-flight (the BigQuery-unreachable branch), and
the D2a section's **CONNECTOR-DOWN DISPOSITION** limb, which this run landed because it did not exist
and this is the second D2a slot to have had to derive it from scratch.

---

## 1. What happened

The Google-Cloud-BigQuery MCP server's **tools were not exposed to this session at all** — the harness
withheld the surface pending re-authorization, and a tool-schema lookup for `execute_sql` returned no
match. So the sanctioned pre-flight read (`SELECT * FROM state.trading_day_today`) and the
DIAGNOSE-BY-PROBE probe pair were **unexecutable rather than merely failing**. This is the identical
presentation to the 2026-08-23 D2a slot (commit `0f15df5`), and one presentation removed from D1's own
pre-flight ~35 minutes earlier, where the tools WERE exposed and returned
`MCP server "Google-Cloud-BigQuery" needs you to sign in again` on every call including a bare
`SELECT 1`.

Either way the classification is the same and is **auth-class → NON-WAITABLE**: the
TRANSIENT-FAILURE WAIT-AND-RETRY ladder was correctly **not entered** and no session time was spent
waiting. D1 had already diagnosed this by probe today; per **INCIDENT INHERITANCE** ("one incident,
one alert thread") this slot did not re-probe and did not open a second thread.

**Not the RUNBOOK §54 signature.** That is a platform `403 authentication_failed` which kills the
session mid-run and orphans a `started` row. This session ran to its own end with every other
connector healthy: IBKR served 9 calls (summary, balances, positions, orders, trades, instructions,
contract search, price history, PA performance), Google Calendar served two reads and accepted an
in-place update. **A
platform 403 kills everything; an OAuth expiry kills one connector.** Discriminate on that.

**Recurrence.** This is the **fourth** recorded occurrence of this grant expiring: 2026-06-26
(RUNBOOK §26), 2026-08-23 (`0f15df5`, also a D2a slot), 2026-09-14 (`bd81376`, M1R slot), 2026-09-21
(today, D1 + D2a + whatever follows tonight). The owner already carries a **quarterly proactive
re-auth** reminder on the calendar (next fire 2026-10-01 11:00). Four expiries in ~12 weeks is
faster than quarterly; that cadence is not this run's to change, and is recorded in §6 for its owner.

---

## 2. Disposition: HALT, not degraded — and why Step 0 is not an exception

Per `Claude_Task_Plan.md` §Observability → connector pre-flight, **BigQuery unreachable**: a routine
that requires canonical state and crafts orders **HALTS cleanly**; it does not degrade. D1 is
research-only and therefore degrades; D2a is neither.

**The trap this run had to step around, and the reason the plan edit below was landed.** D2a's own
1,440-line section never mentions BigQuery being unreachable — verified by exhaustive read of lines
1089–2530. What it *does* say, prominently, is:

> **STEP 0 — BROKER RECONCILIATION RUNS UNCONDITIONALLY, whatever the gate says. This is a hard
> invariant, not a judgment call.**

That sentence is scoped to the **TRADING-ENABLE GATE** reading FALSE, and to nothing else. It does not
survive a dead BigQuery, for a reason that is structural rather than a matter of degree: **Step 0's
entire output is BigQuery writes.** It is the sole writer of broker fills into `events.trade_fills` →
`analytics.position_lifecycle`, and its whole purpose is to clear a `state.position_reconciliation`
drift. With BigQuery unreachable there is nothing for it to run unconditionally *into* — reconciling
the book against the broker with nowhere to record the reconciliation is not reconciliation, it is a
read. The same holds for the routine's other half, which says so in its own words:

> The authoritative engine is the BigQuery value-weighted daily TOTAL-return TWR … **Requires the
> BigQuery MCP connector.**

So: halted. No craft, no write, no run-log row. The 2026-08-23 slot reached the same disposition by
the same reasoning and also had to derive it unaided; two independent derivations of an unwritten rule
is the signature of a missing limb, and §5 records the limb this run landed to close it.

**No duplicate calendar event.** D1's `[Claude] ATTENTION — RE-AUTH BigQuery connector`
(id `09q69g3odvhhbiom3drf15uc60`, 2026-09-21 17:00 MT) was **amended in place** with the blast-radius
escalation, per INCIDENT INHERITANCE — which explicitly sanctions adding material information to an
existing thread ("a different blast radius — e.g. first order-staging routine blocked where the prior
report was research-only") rather than opening a new one. That is exactly this escalation. Its alarm
had **not yet fired** when this slot ran (16:49 MT vs a 17:00 MT event), so the amended description is
what the owner sees on the first notification, and the event was deliberately **not** moved or
re-armed.

---

## 3. What the halt cost — measured from IBKR, not assumed

Evidence read 2026-09-21 22:42–22:58 UTC (16:42–16:58 MT), post-close.

**Nothing needed crafting, and nothing was stranded by not crafting.**

- `get_account_orders` → `{"orders": []}`. `get_order_instructions` → `{"instructions": []}`.
- The staged-order registry's **unconditional daily re-craft** — the one obligation that survives even
  a FALSE trading-enable gate, because a DAY-TIF order that stops being re-crafted silently ceases to
  exist while its intent remains recorded (`bigquery/76`/`78`, the 2026-06-08 MDT de-funding
  precedent) — **had nothing to re-craft.** This is the obligation a halt could genuinely have
  damaged, and it is the reason it is checked first and from the broker rather than assumed.
  **Stated as the inference it is:** `state.open_orders` was unreadable, so this is "the broker holds
  no live order or instruction", not "the registry holds no pending row". A `pending` registry row
  whose DAY order had already expired would present identically. What closes the gap is the registry
  read itself, once BigQuery returns — and the replay's own **(b) window-still-open → re-craft** /
  **(c) window-closed → terminal `expired`** branch is what adjudicates it, correctly, one slot late.

**The park sweep/cover was a no-op on its own thresholds — it was not suppressed by the halt.**

- `settled_cash` = **15.70** USD (`get_account_balances`, BASE and USD agreeing; `total_cash_value`
  15.70, `available_funds` 11,744.41).
- No fills at all on 2026-09-21, therefore no filled-but-unsettled paired SELL, therefore
  `bridge_adjusted_settled_cash` = **15.70** as well.
- §13.E sweeps (BUY the park vehicle) only at `free_cash ≥ +$25` and covers (SELL) only at
  `bridge_adjusted_settled_cash ≤ −$5`. **15.70 clears neither bound.** The cash waits for the next
  slot exactly as it would have on a healthy day.

**No new fills were missed, and the one open question about older fills is bounded.**

- `get_account_trades(period=DAYS_90)` returned 111 trades, most recent **2026-09-18T13:30:07Z**.
  **Zero trades on 2026-09-21.** So this slot's own fill-reconciliation duty was empty on its own
  terms, independent of everything below.
- The four most recent fills (all 2026-09-18, a Friday) are **park-vehicle only** — VOO BUY 0.3013 @
  701.599, SGOV SELL 0.1486 @ 100.58, SGOV SELL 37 @ 100.59, VOO BUY 5 @ 701.80. They are the fills
  of D2's **2026-09-17 park graded re-risk pair** (`target_f_pct` 50→25; SELL 37.1486 SGOV instr 100,
  BUY 5.3013 VOO instr 101, both MARKET/DAY). Park fills book to `events.parking_events`, not
  `events.trade_fills`, and their registry rows clear only when D2a STEP 0 appends a terminal
  `events.queue_events` row for the `item_key`.
- D2a does not fire Friday or Saturday, so the first reconciliation opportunity for those fills was
  the **Sunday 2026-09-20** slot. **The balance of evidence says that slot ran and cleared them:**
  D2 completed on 2026-09-20, `ops/cadence.yaml` gives D2 `depends_on: [D1, D2a]`, and that gate is
  enforced by `sp_assert_deps`, which aborts on an unsatisfied dependency — D2's own 2026-09-20 commit
  records no dependency abort and no wait.
- **The contrary reading, and why it does not survive.** A reasonable reconstruction from git alone
  says these rows are still pending, on two grounds — no D2a commit exists after 2026-09-13, and
  `bigquery/244`'s own header (committed 2026-09-20 01:15 UTC) describes the pair as sitting unreconciled
  at ~53h. **Neither holds.** (1) A D2a run that changes no repo file leaves no commit at all; over the
  trailing 60 days only ~10 D2a-subject commits exist and several are plan edits rather than run
  records, so commit absence is D2a's *normal* case, not an anomaly. (2) That 01:15 UTC measurement
  **predates D2a's own 22:40 UTC Sunday slot by 21 hours** and therefore says nothing about the state
  after it. Recorded explicitly because the failure mode runs both ways: a replay session that believes
  these rows are still open could write reconciliation rows for fills already reconciled.
- **What would settle it, and the dated bar if the inference is wrong.** The registry read itself, on
  re-auth. If the 09-20 slot did *not* run, the pair has been pending since 2026-09-17 evening and
  crosses `bigquery/244`'s **120-hour** `staged_order_reconciliation_overdue` bar around **2026-09-22
  evening UTC** — a park leg has, in that view's own words, "NO backstop whatsoever" short of it. That
  escalation is **OPS0 STEP 2c's** to raise, not a halted D2a slot's to chase; note that OPS0 reads the
  view from BigQuery and is therefore blind on the same outage, so the bar may be crossed silently and
  be waiting when the connector returns. **Check it on replay.**
- Fills are **idempotent on `trade_id`** and the replay's window is
  `GREATEST(7 days, days since D2a's own last successful completion)`, which widens automatically if
  that last completion turns out to be older than assumed — so no fill is at risk of being lost either
  way. Only the registry-clearing side is in question, never the fill record.

**So the real cost is one trading day of the engine and snapshot layer, and it is not nothing:**

| Owed for `2026-09-21` | Why it matters | Recoverable later? |
|---|---|---|
| `ops.account_snapshot` — one row | **D2a is the SOLE writer** (the Apps Script emailer cannot reach IBKR) and there is **no backfill loop**: `bigquery/153`'s own header states that a trading day D2a does not run on is **"missing FOREVER"**, and names 2026-07-23/24 as the two existing permanent gaps. Without the capture below, 2026-09-21 becomes the third. | **Yes — fully, but ONLY because §4 captured it.** NAV, cash and every position are recorded verbatim, and `get_pa_performance_all_periods` was pulled deliberately before the day closed because its period TWRs are computed relative to the QUERY INSTANT and a replay tomorrow could never reproduce them. The replay writes the row from §4; it does not re-read it. |
| `events.daily_marks` — 8 held names + SGOV + SPY + VOO | Feeds `sp_recompute_engine()`; a missing day breaks the TWR chain. | **Yes, exactly.** IBKR daily bars are immutable history; the replay re-pulls 2026-09-21 with `include_corporate_actions:true` and gets the same numbers. Deliberately NOT frozen into this file — see §5's note on not inventing a second price basis. |
| `events.signal_marks` — 11 park-menu tickers + SPY + `^VIX` + BZUSD | Park-allocator evidence layer. | Yes, same reasoning. BZUSD is FMP-only with no fallback; if the vendor lacks the day, the plan already says ingest nothing and let the freeze semantics carry. |
| `events.regime_events` `TECHNICAL_SIGNAL` — 4 keys | **"NOT best-effort in the same sense"**: the router's whole technical half — every M1b divergence flag and every daily technical flip D2 acts on — reads these four rows. | Yes, recomputed mechanically from marks. |
| `perf.strategy_daily` via `CALL ops.sp_daily_refresh()` | State-free DELETE+INSERT rebuild — self-healing by construction once marks land. | Yes, inherently. |
| Tripwires that never ran: cash/park, mark-discontinuity, connector-sanity band, book soft-drawdown, owner-confirmation liveness, strategy funds deficit | Each is a detector, and a detector that does not run does not accumulate a backlog — it simply has a blind day. | The next successful run evaluates present state. A condition that **arose and cleared** inside this window is permanently unobserved; that is the honest residual risk of the halt. |
| `ops.run_log` — `started` + terminal rows | Cadence/dead-man's-switch input. | **No — and deliberately so.** See §6 on why this slot must NOT be backfilled as `completed`. |
| `ops.web_calls` | This run made **zero metered calls** (IBKR and BigQuery are free surfaces; no Tavily/FMP/HF call was made). | **Nothing is owed.** Recorded so a later session does not manufacture rows. |

**Three gates could not be EVALUATED at all, and must not be recorded as having passed.** Each reads
BigQuery and each was therefore simply blind: (a) the **SAME-DAY DOUBLE-RUN GUARD** (`ops.run_log`
count for D2a/today) — harmless here only because this run wrote nothing, so a second fire could not
double-anything; (b) the **TRADING-ENABLE GATE** (`state.trading_enabled_mechanical`), whose verdict is
unknown, which is an additional and independent reason not to craft; and (c) the **cash/park tripwire**,
whose expected side is a BigQuery view. A detector that did not run has no backlog, but it also has no
finding — do not read silence here as an all-clear.

**Downstream, stated so it is not mistaken for new faults:** D2 halts tonight (it needs `D1`+`D2a`
deps, `marks_fresh`/`engine_fresh`, and `state.park_allocation_latest`, which D1 could not write).
D3 halts behind D2. Tomorrow's freshness + cadence dead-man's switches will fire a `missed_run` /
`staleness` **double-critical** once BigQuery returns — per RUNBOOK §26 that is the **expected
signature** of a connector outage, a true positive, and not two independent bugs.

---

## 4. Perishable connector evidence, captured so the replay does not have to invent it

All values verbatim from IBKR, 2026-09-21 22:42–22:58 UTC (post-close on a confirmed regular session).

**`get_account_summary`** — `net_liquidation` **15919.21**, `equity_with_loan_value` 15919.04,
`gross_position_value` 15903.34, `total_cash_value` 15.70, `available_funds` 11744.41,
`buying_power` 46977.65, `initial_margin` 4174.63, `maintenance_margin` 3975.83,
`excess_liquidity` 11943.20, `dividends` 0.17, `leverage` 1.0, currency USD.

**`get_account_balances`** — BASE and USD both: `cash_balance` 15.70, `settled_cash` 15.70,
`net_liquidation_value` 15919.2088, `stock_market_value` 15903.34, `unrealized_pnl` −12.05,
`realized_pnl` 0, `exchange_rate` 1.

**`get_account_positions`** — 10 positions, all STK/USD:

| Ticker | contract_id | Position | Avg cost | Mkt price | Market value | Unrealized P&L |
|---|---|---|---|---|---|---|
| AMZN | 3691937 | 0.3464 | 254.72488453 | 258.7000122 | 89.61368423 | 1.37698423 |
| DIS | 6459 | 0.7244 | 106.72018222 | 104.15000155 | 75.44626112 | −1.86183888 |
| GEV | 691984365 | 0.1244 | 969.90594855 | 947.0999756 | 117.81923696 | −2.83706304 |
| GOOGL | 208813719 | 0.2577 | 340.79705083 | 356.29000855 | 91.81593520 | 3.99253520 |
| ISRG | 9063285 | 0.1091 | 352.46379468 | 401.0 | 43.74910000 | 5.29530000 |
| RTX | 415342104 | 0.1601 | 176.89881324 | 194.1000061 | 31.07541098 | 2.75391098 |
| TSM | 6223250 | 0.1550 | 412.98967742 | 445.79000855 | 69.09745133 | 5.08405133 |
| UBER | 365207014 | 0.5156 | 73.20733126 | 71.01000215 | 36.61275711 | −1.13294289 |
| SGOV | 424099317 | 37.7181 | 100.93277763 | 100.59999845 | 3794.44080154 | −12.55179846 |
| VOO | 136155102 | 16.2040 | 713.76413231 | 712.9000244 | 11551.83199538 | −14.00200462 |

**Eight strategy names — AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER — exactly the set D1's own
ledger recorded this morning**, plus the VOO/SGOV park sleeve and nothing else. Strategy market value
**555.23**; park sleeve **15,346.27** (96.51% of gross position value).

**Session confirmation.** SPY (contract 756733, ARCA) `get_price_history` ONE_DAY returned a
2026-09-21 regular-session bar — O 766.29 / H 774.89 / L 766.04 / **C 773.50**, volume 5,201,404, bar
stamped 13:30 UTC = 09:30 ET. **2026-09-21 was a full regular US equity session**, so the marks and
snapshot enumerated in §3 are genuinely owed for this date and this is not a no-session slot. (This
also substitutes, for evidence purposes only, for the `state.trading_day_today` read that could not be
made — it establishes the session, not the routine's `today`.)

**`get_pa_performance_all_periods` — the genuinely unrecoverable surface, captured deliberately.**
Step 0b reads this for `ops.account_snapshot`'s TWR columns, and its period returns are computed
**relative to the QUERY INSTANT, not to `snapshot_date`** — so a replay run tomorrow cannot reproduce
today's values, ever. Read at `last_successful_update` **2026-09-21 22:58:27**, `portfolio_measure`
**TWR**, base USD:

| Period | start_date | start_nav | cumulative return (`cps`, a fraction) |
|---|---|---|---|
| 1D | 20260918 | 15728.575506 | **+0.012145** |
| 7D | 20260914 | 15691.154343 | +0.01455882 |
| MTD | 20260831 | 15973.751808 | −0.00339011 |
| 1M | 20260820 | 15894.229893 | +0.00159612 |
| YTD | 20251231 | 98.711006 | −0.01653743 |
| 1Y | 20250919 | 98.711006 | −0.01653743 |

The series' own **20260921 NAV is 15919.59901** (prior points: 15728.575506 on 20260918, 15715.99395
on 20260917). 1Y equalling YTD is expected and not a defect — the tool documents that for an account
younger than one year, and the `start_nav` of 98.711006 is the inception-keyed artifact the same note
describes, not a real opening balance.

**Three NAV figures disagree, and the replay must pick deliberately rather than by accident.** Read
within the same ~16 minutes: the performance series says **15,919.59901**, `get_account_summary`'s
`net_liquidation` says **15,919.21** (`get_account_balances` agrees at 15919.2088), and the
per-position `market_value` fields **sum to 15,901.50**, which plus 15.70 cash gives **15,917.20**.
The positions surface is the outlier at **−$1.84** against `gross_position_value` 15,903.34; the
per-position `unrealized_pnl` fields sum to −13.88 against a reported −12.05, the **same $1.83**, which
places the disagreement entirely in market value and not in cost basis — consistent with Step 0b's own
caveat (iii), an after-hours mark against a regular-session mark. **Recommendation for the replay:
stamp the row from the performance series' 20260921 NAV, which is the same source its TWR columns come
from and which keeps NAV and return internally consistent** — this is also what the 2026-08-23
precedent concluded for its own back-dated row. Do not stamp it from the positions sum. Follow Step
0b's own field mapping where it is explicit; this note resolves only the ambiguity, not the spec.

**And it must NOT be read as a cash/park tripwire residual.** That tripwire compares *expected park
shares + cash* against live, its expected side is a BigQuery view, and it **could not be evaluated at
all this run**. At 0.0116% of gross the $1.84 is ~3 orders of magnitude inside the ±15%
connector-sanity band, but that band could not be evaluated either. Do not record either as passed.

---

## 5. The plan edit this run landed, and the one it deliberately did not

**LANDED — `Claude_Task_Plan.md`, two limbs, because the disposition of this very run was unwritten.**

1. §Observability → connector pre-flight, BigQuery-unreachable branch: the HALT list now reads
   **D2/D2a/D3**, with D2a named explicitly rather than left to class-inference.
2. D2a's own section, immediately after the trading-enable gate paragraphs: a **CONNECTOR-DOWN
   DISPOSITION** limb stating that the `STEP 0 … RUNS UNCONDITIONALLY` invariant is scoped to the
   gate and does not survive a dead BigQuery, that a halted slot writes nothing and amends rather than
   duplicates the RE-AUTH calendar event, and that what a halted slot still owes is the **perishable**
   connector evidence plus a measured cost account — with the explicit instruction to state which owed
   writes are recoverable, so the replay does not manufacture the ones that are.

This is landed rather than merely recorded because it is **D2a's own section**, it blocked this run's
own disposition, and two slots (2026-08-23 and today) have now derived it unaided.

**NOT LANDED — the fleet-wide deferred-writes convention.** D1 already recorded this gap today (§5 of
its ledger; `Daily.md`'s not-fixed-here block), owner **W5 or OPS0**: a degraded or halted routine has
nowhere durable to put deferred writes, and `Daily.md` is wholesale-overwritten by the next D1 run.
This file is the same hand-rolled answer, one slot later. **A broker-reconcile routine's halted fire
is an even worse place than a research routine's to choose a fleet convention unilaterally**, and
choosing one here would also have meant inventing an `ops/spikes/` naming scheme in the same breath.
Recorded, not fixed. The shape a fix would take is stated in D1's §5.

**Also deliberately not done: freezing 2026-09-21 closing marks into this file.** It would have cost
~13 sequential IBKR pulls and looked like diligence. It is the wrong call: `events.daily_marks` has a
pinned price basis, the replay re-pulls the identical immutable daily bars anyway, and a hand-copied
price table in a spike file is a **second, unpinned basis** that a later session could mistake for
authority. The recoverable column in §3 says so explicitly for exactly this reason.

---

## 6. Recovery procedure

Fix the cause first, then land D1's deferred writes, then replay the routines in dependency order.
Do not blind-resolve a live red.

1. **Re-auth the connector (owner, no code change).** Re-consent the Google / BigQuery connector in
   claude.ai connector settings. Per RUNBOOK §26 this is a Google-account-side grant lifecycle event
   on Anthropic's first-party connector — nothing in the GCP project console governs it. Verify with
   any `state.*` read. Then **delete the `[Claude] ATTENTION — RE-AUTH BigQuery connector` calendar
   event** (D3 does this automatically once its own pre-flight passes).
2. **Land D1's ten deferred writes** from `ops/spikes/bigquery-deauth-2026-09-21-d1-deferred-writes.md`
   §3, in the order given, honoring its idempotency guards.
3. **Replay D2a for 2026-09-21, then D2, then D3.** D2a's catch-up evidence window
   (`state.routine_catchup_window`) reaches back to its own last completion and will re-read the fills
   itself; §4 above supplies only the NAV/cash/positions read that is not re-readable.
4. **`ops.run_log` for D2a/2026-09-21: leave the gap, or log it terminal — never `completed`.**
   This slot did no work. A spurious `completed` row would advance D2a's own catch-up watermark past
   an unlanded snapshot and mark-day, which is the precise failure RUNBOOK §48 documents. Note that
   this commit's subject deliberately does **not** lead with the routine id, because
   `scripts/auto_merge_decision.sh` + `bigquery/38` parse a leading routine token in a commit subject
   as a completion marker and silently backfill exactly that row.
5. **Expect the `missed_run` + `staleness` double-critical** (D1/D2/D2a/D3) and resolve it with a note
   pointing at this file and RUNBOOK §26. It is the expected signature, not two new faults.

---

## 7. Recorded for their owning surfaces, not acted on from a halted run

None of these could be raised as an `ops.alerts` row, for the obvious reason: the alert sink is the
thing that is down. They are recorded here, with owners named, rather than silently dropped.

- **Grant-expiry cadence outruns the mitigation. Owner: `ops/RUNBOOK.md` §26 / OPS0.** Four expiries —
  2026-06-26, 2026-08-23, 2026-09-14, 2026-09-21 — in ~12 weeks, against a **quarterly** proactive
  re-auth reminder (next fire 2026-10-01). Three of the four were caught by a routine hitting the wall
  rather than by the reminder. Whether the reminder should move to monthly is a cost/annoyance
  judgment for the owner; the measurement is recorded so it is made against data.
- **The blast radius is now measured and it is a whole evening, not one routine.** A single expiry
  takes D1 (degrades), D2a (halts), D2 (halts), D3 (halts) and every write all four owed. The
  per-incident cost has been paid four times without being written down anywhere as a total; it is
  written here.
- **`get_account_positions` and `get_account_summary` disagree by $1.84 on the same account in the
  same minute** (§4). Owner: D2a's Step 0b caveat (iii) / the connector-sanity band. Recorded with the
  arithmetic so a future session can tell whether it is a fixed offset or a moving one, since a single
  observation cannot.
