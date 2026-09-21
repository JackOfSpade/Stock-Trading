# D2 halt record — BigQuery MCP de-auth, 2026-09-21

**Slot:** D2 Daily Action Conversion, evening slot, 2026-09-21 (Monday, full regular session).
**Disposition: HALTED.** Not degraded, not partially executed.
**Sibling records, same incident:** `bigquery-deauth-2026-09-21-d1-deferred-writes.md` (D1, DEGRADED,
~16:1x MT) and `bigquery-deauth-2026-09-21-d2a-halt-record.md` (D2a, HALTED, 16:40 MT). This is the
third slot of the same evening and the **second order-staging routine** lost to the same grant expiry.

Read those two first: this file deliberately does not restate their contents, their deferred-write
ledgers, or their account captures. It records only what is D2's own.

---

## 1. Why this slot halted — two independent sufficient reasons

**(a) The connector is down.** The Google-Cloud-BigQuery MCP tools were **not exposed to this session
at all** — the harness withheld the surface pending re-authorization, the same shape D2a met 35 minutes
earlier (and unlike D1, which still had the tools and got an auth error back from them). The sanctioned
pre-flight read and the DIAGNOSE-BY-PROBE pair were therefore *unexecutable*, not merely failing.
Auth class ⇒ NON-WAITABLE; the retry ladder was correctly not entered. Per INCIDENT INHERITANCE
(one incident, one thread) this slot ran **no probe of its own** and opened **no second alert thread** —
it amended the existing `[Claude] ATTENTION — RE-AUTH BigQuery connector` event in place
(id `09q69g3odvhhbiom3drf15uc60`). Claude_Task_Plan.md's connector pre-flight branch names this
routine explicitly: *"D2/D2a/D3 require canonical state → HALT cleanly (never run on missing/stale
state; craft no orders)."*

**(b) D2's FATAL dependency gate could not have passed even with a live connector.** D2 is
`depends_on: [D1, D2a]` and its gate — `CALL ops.sp_assert_deps('D2', ['D1','D2a'], <today>)` — RAISEs
unless **both** upstreams have logged `completed` for today. Neither has:

- **D2a** halted and deliberately wrote **no `ops.run_log` row at all**, not even `started`.
- **D1** ran degraded to completion but its terminal `sp_routine_end(... 'completed' ...)` is
  **deferred write #10** in its own ledger and has not landed.

So 2026-09-21 is not a case of a healthy D2 blocked by a dead pipe. The inputs D2 converts — today's
reconciled book, today's marks, today's engine, today's park call — **do not exist in canonical state**,
because the routine that writes each of them could not write it. Halting is the correct answer on the
merits, not merely on the mechanical branch.

**Corollary for the replay:** do not replay D2 before D1's deferred writes and a full D2a replay have
landed, in that order. D2's gate will enforce this itself once BigQuery is back; the point is not to
fight it.

---

## 2. Gates that could NOT be evaluated — and must never be logged as passed

Same discipline as D2a's §3. Each of these is a BigQuery read that did not happen. None of them is a
pass, and none of them is a fail:

| Gate | Read it needs | Status |
|---|---|---|
| SAME-DAY IDEMPOTENCY GUARD | `ops.run_log` count, noon-threshold clause | **Unevaluated** |
| DEPENDENCY GATE | `ops.sp_assert_deps('D2',['D1','D2a'])` | **Unevaluated** (but see §1(b) — it would have RAISEd) |
| TRADING-ENABLE GATE | `state.trading_enabled` | **Unevaluated** |
| ENTRY-STAGING GATE | `state.entry_staging_allowed` | **Unevaluated** |
| PENDING-NEWCOMER FROZEN CHECK | `state.strategy_probe_funding_gap` | **Unevaluated** |
| ORDER-GUARD CHECK | `analytics.fn_order_guard(...)` | **Unevaluated** |
| CATCH-UP CHECK | `state.routine_catchup_window` | **Unevaluated** (git-side half below) |

On the idempotency guard specifically: this was D2's **own cron fire and the first fire of the day**.
D2a's chain-call to D2's trigger fires only on D2a's *successful completion*, and D2a halted — so no
chain-call was issued. That is read off D2a's halt record, not off the guard, which could not run.

The **git half** of the CATCH-UP CHECK *was* runnable and was run: the clone is full (1,501 commits,
no `.git/shallow`), so the HISTORY-DEPTH PRECHECK passes and history is not truncated. It is recorded
here only so the replay knows the "no intervening commits" reading would have been trustworthy; the
window's own start timestamp is a BigQuery read and was not available.

---

## 3. What the halt cost — measured, not asserted

### 3.1 Nothing was stranded at the broker

Read at 2026-09-21 23:17–23:20 UTC (17:17–17:20 MT), roughly 35 minutes after D2a's capture:

- `get_account_orders` → `{"orders": []}`
- `get_order_instructions` → `{"instructions": []}`

So the staged-order registry's daily re-craft (the persist-and-wait path) had **nothing to re-craft**,
and no DAY order lapsed unattended tonight. This independently reproduces D2a's 16:42–16:58 MT read.

**This does NOT close D2a's open question**, and the distinction matters. The broker holding no live
order tells you nothing about whether the *BigQuery registry* `state.open_orders` still carries
`pending` `ORDER_STAGED` rows for the 2026-09-17 park re-risk legs that filled 2026-09-18. That view is
unreadable, so the question D2a flagged is now the **second consecutive slot** that could not answer it.
Unchanged from D2a's framing: if those rows were not cleared by the Sunday 2026-09-20 slot they cross
the 120-hour `staged_order_reconciliation_overdue` bar **around 2026-09-22 evening UTC** — and OPS0,
which owns that escalation, is blind on this same outage. **Check it first on replay.**

### 3.2 No fills to convert, and no exits to stage

Zero trades on 2026-09-21 (`get_account_trades` DAYS_7); most recent fill 2026-09-18. Daily.md's
RECOMMENDED ACTIONS reads **"No exits triggered. No add candidates flagged. No router review
recommended."**

**Scope that claim precisely — it covers the D1-FLAGGED limb of those items and nothing more.**
Items 1 (exits), 2a (adds) and 4 (router reviews) are fed only by D1's file, so Daily.md saying
"none" plus the passing cross-check (§3.6) makes them genuinely empty tonight, and the replay should
not go looking for missing exits. Items **2** and **5** are NOT closed by that, because each has a
second, queue-driven limb that Daily.md cannot see: item 2 can be entered by a `PENDING_ANALYSIS`
thesis-construction falling due, and item 5 by a drained foundation-change "terminate" verdict or an
Orchestrator m2m TERMINATE verdict awaiting execution. Those limbs read `state.open_queue` and are
**UNKNOWN**, per §3.4 — not empty. This is the same distinction the EARLY-EXIT pin exists to enforce,
and it is worth stating rather than rounding off: a quiet `Daily.md` is not evidence about the queue.

### 3.3 The park conversion was NOT a no-op — this is the real cost

This is where D2's halt differs from D2a's. D2a's park sweep/cover was a no-op **on its own thresholds
anyway** (settled cash $15.70 against a +$25 sweep bar and a −$5 cover bar), so its halt cost nothing
there. D2's item 6 PARK ALLOCATION CONVERSION was a live, executable conversion that did not execute.

D1's park call today (its deferred write #6): **status BOUND, direction RE-RISK, `target_f_pct` 25 → 0,
`risk_sleeve` VOO, `defensive_sleeve` SGOV, conviction LOW / `conviction_pct` 15.** It could not be
written, so it reaches neither `events.decision_log` nor `state.park_allocation_latest`. D2 reads the
park call **only** through that view — `d1_actions` is a pointer at most and today deliberately carries
no park entry at all — so item 6 had no row to read. Not a HOLD; the view itself was unreachable.

**The CONVERGENCE BAND verdict, computed from IBKR marks at 2026-09-21 23:20 UTC:**

| Sleeve | Shares | Mark | Market value |
|---|---|---|---|
| VOO (risk) | 16.2040 | 713.10601805 | 11,555.16991648 |
| SGOV (defensive) | 37.7181 | 100.5985031 | 3,794.38439978 |
| **park_mv** | | | **15,349.55431626** |

- SGOV actual weight = 3,794.38439978 / 15,349.55431626 = **24.720%**
- Target weight at `target_f_pct = 0` = **0%**
- |actual − target| = **24.720pp**, against the band's **>10pp** bar — clears by ~2.5x
- Both resulting legs (~$3.79k SELL SGOV, ~$3.78k BUY VOO) are far above the **≥$25 per-leg** minimum

So the conversion would have converged, and the band verdict is robust: the margin is wide enough that
no plausible re-mark at replay flips it. The park sleeve is 96.4% of a $15,922.07 NLV, so this is
**~$3.79k of a $15.9k account** that stayed defensive tonight instead of re-risking.

**Deliberately NOT recorded here: the leg share counts.** They must be recomputed at replay from the
reference prices of *that* session. Freezing tonight's numbers into this file would create exactly the
second, unpinned price basis D2a's record refused to create for marks — and the sizing chain
(`expected_net_proceeds` → 0.995 haircut → `free_cash` base → `MAX(0, …)` floor) must run against live
figures, not against a day-old transcription.

**What this cost, stated honestly and bounded:**

- **It is a DELAY, not a loss.** D1 re-issues the park call every day. If re-auth lands before D1's
  2026-09-22 run, the 09-22 call supersedes this one on fresher evidence and the conversion (or a
  revised one) executes then. Nothing needs to be replayed *as of 09-21* for the park.
- **The cost is one session of sleeve positioning:** ~$3.79k held in SGOV rather than VOO for one
  additional session. Had D2 run, both legs would have been crafted tonight as DAY orders working the
  2026-09-22 open; now the earliest is the 09-23 open.
- **The regret is bounded by the call's own conviction, which is LOW (15).** D1's own record notes the
  ladder returns 0 only because conviction scored 15 rather than 20 — at 20 this is a KEEP — and names
  that number as the thing its `theater_check` attacks. A marginal, low-conviction re-risk deferred by
  one session is a small cost, and it should not be written up as a large one.

### 3.4 The PENDING_ANALYSIS drain — UNKNOWN, and deliberately not called empty

STEP 1 reads `state.open_queue` / `state.open_queue_detail` for `PENDING_ANALYSIS` rows with
`status='pending'` and `due_date <= today`. That view is unreadable and **no repo file mirrors the
queue**, so this slot cannot know what was due tonight.

**Record it as UNKNOWN, never as empty.** This is the same discipline the CATCH-UP CHECK applies to an
undeepenable clone ("treat the backfill set as UNKNOWN rather than empty"): an unreadable queue and an
empty queue are indistinguishable from here, and the failure mode of guessing "empty" is silent.

The EARLY-EXIT pin in D2's own section exists for precisely this trap — on 2026-09-01 a `d1_actions: []`
day simultaneously carried a BOUND park switch of 96.6% of the account *and* a due `PENDING_ANALYSIS`
item. Tonight is the same shape with the state layer removed entirely.

Note for the replay: a drained entry whose `due_date` has passed with its required data still
unavailable takes its `conservative_default` (skip / decline / exit) and is marked complete — deferrals
do not chain. A **halted** D2 does not apply that default; the items simply sit undrained. So the replay
must check whether any entry's window closed across 09-21, and must not assume the conservative default
was already applied on time.

### 3.5 Three Watchlist adds not applied — and why that was a choice

Daily.md's three RECOMMENDED ACTIONS bullets are Strategy-B **index-only** watchlist adds:
**GRAL** (+33.6759%, 80.77 → 107.97), **WBD** (+10.7914%, 27.80 → 30.80), **NVO** (−7.9556%,
43.24 → 39.80), all `qualifying_event_date: 2026-09-21`, all with B's router DO-NOT-ACTIVATE and
capital-disabled, no thesis construction routed.

These are the one part of tonight's conversion that is *physically* possible under a dead connector —
Watchlist.md is a file, not a table. They were **deliberately not applied**. Three reasons, in order of
weight:

1. **Their mandatory prerequisite is a BigQuery read that cannot run.** D1's block says so in terms, on
   all three names: *"Four-part field-identity dedupe could NOT be run (events.queue_events unreadable)
   … D2 must perform the real field-based dedupe, never a key-string match."* The Strategy-B event
   identity guard requires querying `events.queue_events` and `events.decision_log` on
   (`analysis_type`, `strategy`, `ticker`, `qualifying_event_date`). D1 explicitly deferred that dedupe
   **to D2**, and D2 cannot run it either. Writing the names into the durable index without it is
   precisely the key-string shortcut the guard forbids.
2. **The carve-out that appears to permit it is scoped to a different gate** — see §4.
3. **A partial D2 with no run-log row is worse for the replay than a clean halt.** With no `ops.run_log`
   row to say which steps ran, a replay session reaching back through the CATCH-UP evidence window
   would have to guess which bullets were already converted. A clean halt plus this file removes the
   guess.

Nothing decays by waiting: B is DO-NOT-ACTIVATE and capital-disabled, so these entries carry no action,
and `qualifying_event_date` is pinned to 2026-09-21 in D1's block, so the 10-day window stays anchored
and recoverable.

### 3.6 The prose / `d1_actions` cross-check — RUN, and it PASSES

Cheap, needs no connector, and running it now saves the replay from re-litigating a gate that has twice
come within one reading of halting a sound file. Counting **actionable items, not bullet lines**, per
the 2026-08-30 pin:

| Category | Prose | `d1_actions` block | Verdict |
|---|---|---|---|
| Exits | 0 ("No exits triggered.") | 0 | match |
| New entry candidates | 0 | 0 | match |
| Add candidates | 0 ("No add candidates flagged.") | 0 | match |
| Watchlist | 3 (GRAL, WBD, NVO) | 3 (`action: watchlist`) | match |
| Router reviews | 0 ("No router review recommended.") | 0 | match |
| Park | 0 bullets (a NOTE, deliberately not a bullet) | 0 entries | match |

**No mismatch. Today's Daily.md is sound and convertible as-is.** The 2026-09-17 pin (a park conversion
mis-encoded as `action: router_review`) does **not** apply: D1 carried the park call as an explicit
prose NOTE and correctly emitted no block entry for it, so the park category is 0-vs-0 on both sides
rather than 0-vs-1. The replay can convert straight from this block.

---

## 4. Plan edit landed with this record — D2's own CONNECTOR-DOWN DISPOSITION limb

**The gap, and why it is the same one D2a closed this morning.** D2a's section had a prominent
"STEP 0 … RUNS UNCONDITIONALLY … a hard invariant, not a judgment call" sentence that reads like an
override of the connector-down branch and is not one — it is scoped to the trading-enable gate. Two
independent D2a slots (2026-08-23, and today) had to derive the disposition unaided, so today's D2a run
landed a CONNECTOR-DOWN DISPOSITION limb saying so.

**D2's section carries the identical trap, one paragraph wide, and nobody had noticed.** D2's
TRADING-ENABLE GATE block ends with a carve-out list: *"NOT BLOCKED, ever — STEP 1's `PENDING_ANALYSIS`
drain …, thesis construction and its GO/NO-GO `events.decision_log` write, Watchlist.md updates, router
reviews, queue bookkeeping, and run logging,"* closing with *"A halt is a reason not to move capital; it
is never a reason to stop thinking."* That is correct and load-bearing **for a `trading_enabled = FALSE`
verdict**, which is what the paragraph answers. Read by a session whose *connector* is dead, it reads
like a licence to run most of D2 anyway.

**D2's version of the trap is sharper than D2a's**, which is why it is worth its own limb rather than a
cross-reference. Of the six things that list declares unblockable, five are BigQuery reads or writes and
are impossible under this outage regardless — so they are self-enforcing. Exactly one, **Watchlist.md
updates**, is physically performable with no connector at all. That one is also the one whose mandatory
prerequisite (the Strategy-B four-part field-identity dedupe) is itself a BigQuery read — so the single
item a connector-down session *could* execute off that list is the single item it most specifically must
not. A list whose only actionable entry is a trap is worse than no list.

The limb states: on an unreachable/de-authed BigQuery at pre-flight, **D2 HALTS** — it does not degrade,
does not drain the queue, does not convert the file-only bullets, and does not edit Watchlist.md; the
carve-out list is scoped to the trading-enable gate and does not survive a dead connector; and a halted
D2 slot owes the same three things a halted D2a slot owes (perishable evidence to a durable repo file, a
measured cost account, an explicit recoverable / not-recoverable split).

---

## 5. Recoverable vs not

| Owed output | Recoverable? | How |
|---|---|---|
| The three Watchlist.md B-index adds | **Yes, fully** | Convert from today's `Daily.md` block on replay, after the field-identity dedupe runs. `qualifying_event_date` is pinned 2026-09-21; B is DO-NOT-ACTIVATE so nothing decays. |
| Park allocation conversion (f 25 → 0) | **Superseded, not replayed** | D1 re-issues the call daily. Take the 09-22 (or later) call on its own fresh evidence. Do **not** replay the 09-21 call as if it were still current; do not reuse tonight's marks to size it. |
| `PENDING_ANALYSIS` drain | **Unknown scope; recoverable once readable** | Query `state.open_queue` on recovery for `due_date <= 2026-09-21` still `pending`. Check whether any entry's window closed across 09-21 (§3.4). |
| `events.decision_log` rows D2 would have written | **None owed from the D1-flagged limb; UNKNOWN from the queue-driven limb** | No exits, adds or router reviews were flagged (§3.2). Whether a due `PENDING_ANALYSIS` item would have produced a thesis GO/NO-GO or a termination verdict is unknowable from here — resolve with §3.4's queue query. The park conversion decision belongs to whichever session executes the superseding call. |
| `ORDER_STAGED` rows | **N/A — none owed** | Nothing was crafted, so nothing is owed. |
| `ops.run_log` started/terminal rows for this slot | **NO — a permanent, deliberate gap** | Never backfill this slot as `completed`. It would falsely advance D2's catch-up watermark past an unconverted day (RUNBOOK §48), and the commit carrying this file is subject-shaped to avoid being parsed as a completion marker. |
| Tripwires/gates listed in §2 | **NO — a blind evaluation** | Any condition that arose and cleared inside tonight's window is unobservable. Not backfillable; recorded so it is not mistaken for a pass. |

---

## 6. Recorded for owners, not acted on here

- **The fleet-wide deferred-writes convention is still unbuilt** — this is now the **third** hand-rolled
  `ops/spikes/` file for one evening (D1's ledger, D2a's halt record, this one), each inventing its own
  shape. D1 and D2a both recorded the gap; this run confirms it at n=3 in a single incident, which is
  the strongest evidence yet that the interim convention is load-bearing and should be specified.
  **Owner: W5 (spec-defect intake) or OPS0.** A halted conversion routine is no better placed than a
  halted broker-reconcile routine to choose a fleet-wide convention unilaterally.
- **Grant-expiry cadence** — unchanged from D2a's §7 and not re-litigated here: 4 expiries in ~12 weeks
  against a quarterly reminder next firing 2026-10-01. Owner: RUNBOOK §26 / OPS0.
- **The 120-hour staged-order bar on the 09-17 park legs** (§3.1) is now unanswerable by two consecutive
  slots and goes overdue ~2026-09-22 evening UTC with its owning routine blind. First item on replay.

---

## 7. Disposition summary

**HALTED.** No `ops.run_log` row (not even `started`). No `events.*` row. No `ops.alerts` row. No order
crafted, no instruction created, no `ORDER_STAGED` row. No Watchlist.md edit. No second calendar event —
the existing RE-AUTH event was amended in place with D2's blast-radius escalation. IBKR served 5 calls
(orders, instructions, trades, summary, positions) and Calendar 2 (read, amend).
