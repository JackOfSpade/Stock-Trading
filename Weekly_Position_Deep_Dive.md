2026-W34

# W3 — Open-Position Deep-Dive (Strategies A, B, C, E)

**Run date:** 2026-08-23 (Sunday; `state.trading_day_today.today` = 2026-08-23, `is_trading_day=false`, `last_trading_day=2026-08-21`, `next_trading_day=2026-08-24`). Every price in this file is a completed regular-session close; no intraday print is used anywhere, because no session is open.

**Marker `2026-W34` — the same marker the file it replaces carried, and that is correct, not stale.** The prior W3 ran **Monday 2026-08-17**, the first day of ISO week 2026-W34; today is **Sunday 2026-08-23**, the last day of the *same* ISO week. The convention is the ISO week of the run date with no look-ahead, so both runs legitimately stamp W34. W1 and W2 both ran earlier today and both stamped `2026-W34`, so all three weekly files agree this cycle and W4's upstream-freshness read matches. A reader checking freshness should use the **run date** above, not the marker. (Same situation as the 2026-08-09 run, which repeated `2026-W32` for the same reason.)

**Span covered: since W3's own last successful completion, 2026-08-17 → today.** `state.routine_catchup_window` gives `window_days = 5.69` against the 10.5-day (1.5× weekly) bar — **cadence-normal, no `CATCHUP[...]` token owed**, no missed-period sub-section due. The prior W3 measured through the **2026-08-14** close. The five completed sessions newly in scope are therefore **2026-08-17 through 2026-08-21**.

**That the 2026-08-17 close is newly in scope is the single most consequential fact about this run's window.** The prior W3 ran that morning, before that day's close existed. The 08-17 close is what tripped MSCI's invalidation criterion and produced the exit that emptied this book — so the exit-triggering session falls inside *this* run's evidence window, and adjudicating it is W3's job, not a re-tread of the prior file's.

**Scope: Strategies A, B, C, E** — the roster-derived `review_cadence: reactive` set, re-verified this run against **both** `strategy/roster.yaml` and `state.strategy_roster`: A, B, C, E are `reactive` and `ADOPTED`; **D** is `long_horizon` and gets its deep-dive monthly in M3; **F, G, H** are `REJECTED` and hold nothing.

---

## IMMEDIATE-ACTION

**None. No `WEEKLY-THESIS-ACTION` flag is set, and no `immediate_action_flagged` alert is raised.**

Both are structurally unavailable this week rather than merely declined: that flag exists to hand W4 a *cumulative or slow-burn finding on an open position*, and **there is no open position in any in-scope strategy.** The one substantive finding below concerns a position that closed five days ago and cannot be acted on. It is routed to `ops.alerts` instead, where the routine that owns it will actually see it.

---

## THE IN-SCOPE BOOK IS EMPTY

**Zero open positions across Strategies A, B, C and E.** This is the first W3 cycle in the recorded history with nothing to review, so it is verified on five independent lines rather than one query.

| # | Check | Result |
|---|---|---|
| 1 | `state.current_positions` | **13 rows, every one `strategy='D'`.** Zero A/B/C/E rows. |
| 2 | `events.position_events`, latest event per `position_key`, strategy in (A,B,C,E) | **0 rows** with a latest status other than `CLOSED` (compared case-insensitively — this table's casing is inconsistent). No hidden `OPEN` / `ADJUST` / `ORDER_STAGED` / `EXIT_PENDING`. |
| 3 | `state.open_orders` | **0 rows.** No staged-but-unfilled entry that would become an in-scope position. `get_account_orders` likewise returns **zero** live or working orders. |
| 4 | **Live broker cross-check** (`get_account_positions`) | **10 equity lines, every one reconciled exactly.** AMZN 0.3464, CRM 0.2275, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.1550, UBER 0.5156 — each equals the sum of that ticker's Strategy-D tranches to the share. The eleventh line, **VOO 21.8139**, matches `state.park_position_current` exactly (`is_policy_vehicle=true`) and is the park vehicle, not a strategy position. **No unaccounted broker holding exists.** |
| 5 | `analytics.strategy_nav` | A, B, C and E all carry `deployed_mv = 0`. |

Check 4 is the one that matters. The other four are all readings of the same warehouse and could in principle share a fault; the broker is an independent system, and it agrees to the share on every line.

**A caveat worth publishing rather than smoothing over.** For **B** the emptiness is the ordinary kind — 13 position keys, all now `CLOSED`. For **A, C and E** it is a different and weaker kind of evidence: those three strategies have **zero rows in `events.position_events` in the entire recorded history** (which begins 2026-04-27). They have not gone flat; they have **never opened a position at all**. Nothing in this file should be read as "these strategies traded and closed out."

### Why it is empty — decomposed, because the four causes are not the same

Router state is binding as of **2026-08-05** (the `div-*-202607-1` divergence-review batch) and unchanged since.

| | Router | Capital | Deployed | Why flat |
|---|---|---|---|---|
| **A** | DO-NOT-ACTIVATE | NAV **$0.00** | $0 | **Double-blocked.** Router off since 2026-07-01 *and* zero capital. Its 40-name Watchlist queue is parked behind `Next M1 with A router ACTIVATE`. Not a signal failure. |
| **B** | DO-NOT-ACTIVATE | NAV **~$0.00** | $0 | Router off since 2026-08-05 (blocks *new* entries only); its last position hit an invalidation criterion 08-17 and its remaining $47.35 was swept to C/E on 08-18. Not a signal failure. |
| **C** | HYBRID ACTIVATE (FOMC-only) | NAV **$23.68**, 2% base **$0.47** | $0 | **Flat by design.** C is classified permanently NOMADIC — it holds no standing capital and borrows at order-craft time — and its activation is narrowed to FOMC windows, 0–8 trades/year. Next window: `thesis-FOMC-C-20260908`, due 2026-09-08. Not a signal failure. |
| **E** | **ACTIVATE** | NAV **$15,333.61**, 2% base **$306.67** | $0 | **The only genuine "no qualifying entry fired" case.** Nothing structural blocks E. |

`perf.kill_flags` holds rows only for B and D; B's current row (as-of 2026-08-18) reads **all flags false** — no drawdown kill, no gate, no m2m review. A, C and E have no rows, consistent with never having deployed. `state.entry_staging_allowed` reads `entries_allowed = TRUE`, `block_reason = NULL`. So nothing was *blocked* this week either.

**Three of the four causes are the router doing its job. Only E's is a live question**, and it is E's own entry bar, not a fault.

---

## RESOLUTION RECORD — B:MSCI:2026-07-27

Reported as a **resolution, not a review**: the position closed inside this window and is not eligible for a hold/action recommendation.

**Closed 2026-08-18**, SELL 0.0863 sh MARKET/DAY, filled at the 13:30:00Z open @ **550.68**, commission 0.351271, connector `realized_pnl` **−$2.819387**. Authorizing decision `bf2746f7-f112-494c-8c65-566c7386c0d9` (D2, 2026-08-17); reconciled by D2a. Criteria (a) and (c) were re-verified UNBREACHED, the $615 convergence target was not hit and the 2026-09-25 time exit was not due — **the exit rested solely on criterion (b)**.

### The finding: the breach disappears once the dividend is netted out

Criterion (b), verbatim from the immutable at-entry record: *"fresh close below the 550.79 post-event trough with no accompanying new information."* The exit record itself identifies that 550.79 as the **2026-07-24 closing low**.

| Quantity | Value |
|---|---|
| Named trough (2026-07-24 close, **cum-dividend**) | **$550.79** |
| MSCI ex-dividend, 2026-08-14 (`events.daily_marks`, connector corporate-action field) | **$2.05** |
| Economically-equivalent **post-ex** line | **$548.74** |
| 2026-08-17 close (a **post-ex** price) | **$550.68** |
| Breach as read: 550.68 vs 550.79 | **−$0.11 (−0.020%)** |
| Against the adjusted line: 550.68 vs 548.74 | **+$1.94 (+0.354%)** |
| **Distortion ÷ breach margin** | **18.6×** |

A cum-dividend line was compared against a post-ex price. The measurement error is **eighteen times larger than the breach it produced.** On a like-for-like total-return basis **criterion (b) was not breached at all.**

**This was predicted, in writing, in this file, one week early.** The prior W3 did not bury it in a run-log note — it published it in `Weekly_Position_Deep_Dive.md` at §5, in bold, **pre-computing the $548.74 adjusted line**, and stating: *"if criterion 2 fires, W4/D2 must net out the $2.05 before reading the breach as thesis deterioration, because up to $2.05 of any move toward the line is a dividend, not a market verdict."* W3 completed **13:50Z**; D2 staged the exit at **20:44Z the same day**, roughly seven hours later, with that file already committed. D2's exit record contains no dividend adjustment at any point.

**What D2 did right, stated plainly so this is not read as a blanket criticism.** D2 fired **literally** on an immutable criterion — which is correct, and is exactly what the prior W3 instructed for the *price test*. It re-verified both legs from sources independent of D1, closed the primary-source gap via SEC EDGAR CIK 0001408198, and checked every gate. The defect is narrow and sits at the **second** step: reading the literal fire as *thesis deterioration* ("falsifies the stabilisation read") without first netting the dividend.

**Subsequent price action is consistent with the no-real-breach reading** — corroboration, not proof, and one week is a small sample:

| Session | Close | vs the $550.79 line |
|---|---:|---|
| 2026-08-14 | 569.13 | +3.33% (last close the prior W3 could see) |
| **2026-08-17** | **550.68** | **−0.02% — the trigger** |
| 2026-08-18 | 562.77 | +2.18% *(fill day; filled at the open, 550.68)* |
| 2026-08-19 | 565.27 | +2.63% |
| 2026-08-20 | 568.75 | +3.26% |
| 2026-08-21 | 563.49 | +2.31% |

MSCI closed back above the line the **very next session** and never revisited it again through 08-21 — **not even intraday** (session lows 554.04 / 560.43 / 561.79 / 562.68). The 08-21 close is **+2.326% above the 550.68 fill**. IBKR daily bars (contract 47101335, `ONE_DAY`, `outside_rth=false`) agree byte-for-byte with `events.daily_marks` on 08-13/14/17/18; `daily_marks` has **no rows yet for 08-19 through 08-21**, so those three closes are IBKR-only — a gap, not a disagreement.

**Was the prior W3's HOLD wrong? No.** It measured the last close available to it (08-14, 569.13) at **+3.330%** above the line — not a marginal call. The breach came from a **single-session −3.242% move that had not yet happened**, and it landed 0.02% under the trough. A weekly review cannot see a move that has not occurred; the daily routine caught it the same day. **The weekly/daily division of labour worked exactly as designed.** What did not work is the hand-off of the adjustment W3 had already computed.

**Second, separable execution item, already flagged by D2a and repeated here because it now has a pattern.** The exit was MARKET/DAY and filled at the 13:30Z open at 550.68; MSCI closed **562.77** the same day. The fill was **2.20% worse than a close-priced exit**, which is most of the −$2.82 realized loss. The prior W3 recorded the mirror-image case on the entry side ("the fourth consecutive post-print add staged into a gap-up"). Adverse open fills on MARKET orders are now observed on both sides of the book. **W5's execution-quality review owns this; W3 does not adjudicate it.**

**Actionability: none, and that is not a judgment call.** The position is closed. B is router DO-NOT-ACTIVATE with ~$0 NAV, so a re-entry is barred regardless of merit. This finding is recorded for **W5 calibration** and for whoever drafts the *next* price-level criterion — the generic form is that **any immutable price-LEVEL criterion on a dividend-paying name drifts against its own economics at every subsequent ex-date, always in the fire-earlier direction.** The dollar loss here is trivial ($2.82 on a ~$50 position, small only because B is capital-depleted); the same defect against E's $306.67 sizing base scales with the position. Raised as `ops.alerts` **warning** `criterion_dividend_distortion`.

---

## PER-STRATEGY REVIEW

No position means the six standing questions (thesis status, competitive landscape, fundamental developments, sector/macro, invalidation signals, time-to-resolution) have no subject. They are answered at strategy level only where there is something measured to say, and are recorded as **not applicable** where there is not — rather than filled with market commentary that no position depends on.

### Strategy A — no position, no capital, router off
40 names in the `Watchlist.md` queue, all carrying the same disposition (`Resolution trigger: Next M1 with A router ACTIVATE`). **No net change in span**: W4 2026-08-17 added zero new names (all ten of its top-ten — NVDA, MRVL, ORCL, CAT, GEV, SMCI, TTWO, AVGO, INTC, MU — were already queued) and removed **NUVL** outright, which is no longer a listed company (GSK tender closed 2026-07-15, confirmed on SEC EDGAR independently by W1 and W4). D1 routed no A candidate on any session in the window. **Nothing owed.**

### Strategy B — no position as of 2026-08-18
Covered in full in the resolution record above. D1 added **12 names** to the B new-entry index across 08-17→08-20 (FN, KLAR, BIDU, AMLX, EL, MRNA, WMT, WOLF, MRVL, AAP, NDSN, DE), every one **index-only** — the router is DO-NOT-ACTIVATE and NAV is ~$0, so nothing could be staged. W2 re-ranked that same cohort this morning (excluding WOLF, ARGX, CBRS on eligibility/event-identity grounds). **This is D1/W2 coverage and W3 does not re-derive it.** **Nothing owed.**

### Strategy C — no position, flat by design
No FOMC decision in the window. The standing drain `thesis-FOMC-C-20260908` is queued and **not due until 2026-09-08**. D1 noted on 08-20 a sharpening divergence — hawkish data and hawkish minutes against roughly flat 32.7% hike-odds pricing — and correctly forwarded it to that drain as evidence rather than opening anything. With a $0.47 2%-sizing base, C could not size a meaningful position today even if a window were open; that is the nomadic design (it borrows at craft time), not a defect. **Nothing owed.**

### Strategy E — no position, and the only one where that is a live question
E is the sole strategy that is **both** router-ACTIVATE **and** meaningfully funded, and it has **never opened a position** in ~4 months of recorded history.

It is not idle for want of trying. On **2026-08-18** D2 evaluated a TLN/VST pair and returned a **NO-GO on E's own criteria, not procedurally** (`62a05cec-678e-4874-9659-8d45398d0ca0`, conviction ~90%) — the record is explicit that every gate was open and *"nothing external stopped this trade; the pair's own numbers did."* Three independently sufficient grounds: the quantitative divergence anchor read **65.1st percentile against a required ≥95th**; the spread sat *above* its 252-day mean, so the mean-reverting trade was actually the **opposite direction** to the one proposed; and criterion 5's Anchor 2 required 10 qualifying reference pairs in GICS 551050 where only **1** exists. A fourth, independently disqualifying finding: VST carried a pending FERC-approved Cogentrix acquisition, and E's own rules treat shorting into announced M&A as thesis-invalidating.

That session's `ops-note` surfaced three E machinery gaps, and **the owner closed them the same day via Rev 45** — Anchor 2 was subsequently dropped. A future reader re-reading the 08-18 NO-GO must not mistake its pre-Rev-45 criteria for the current rule.

D1 on 08-20 measured cross-sectional dispersion **collapsing to 2.14pp from 4.58pp** — moving away from, not toward, E's ≥95th-percentile anchor.

**Observation, recorded and deliberately not escalated.** E's lane holds **$15,333.61 — 96.1% of the book's $15,959.77 total NAV** — against zero deployment in four months. Two things stop this being an alarm, and both are measured:

1. **The capital is not idle.** It is physically invested in the **VOO park** (21.8139 shares, $15,411.79 net cash in; D1's 2026-08-20 park call is KEEP/MEDIUM-55/BOUND). "Available funds" is a *lane* balance, not cash under a mattress. The opportunity cost of E not firing is therefore (E's expected edge − VOO's return), **not** (E's edge − 0), which is a far smaller number and may be negative.
2. **Four months is a short sample for a strategy designed around rare, high-conviction divergences**, and the one candidate that appeared was declined on measured numbers with a documented margin, not on vagueness.

The legitimate open question — *is a ≥95th-percentile anchor that has produced zero entries in four months correctly calibrated, or unsatisfiable?* — is **real but is not W3's to answer.** E's machinery is spec-locked, and criteria changes belong to the owner and the SL lifecycle routines, which have already engaged this surface once (Rev 45). Recorded here for **W5** and left there. **No alert raised**, because on the two points above nothing is currently going wrong.

---

## PROCESS AND HOUSEKEEPING

**D1 coverage in the span is complete through 08-20 and does not yet reach 08-21.** D1 ran 08-17, 08-18, 08-19 and 08-20. It did **not** run Friday 2026-08-21 — the daily tier is `daily_sun_thu` and is not scheduled Fridays — and today's Sunday D1 has not yet fired (only W1, W2 and W3 have run). So **the 2026-08-21 session is not yet covered by any D1 scan.** With an empty book this changes no conclusion, but this file does not claim D1 coverage it does not have. The newest `Daily.md` is marked **2026-08-20**.

**A false-positive fleet-outage alert was refuted and resolved this run** (`f6ff58ee`, raised by W1 at 10:02Z today, category `cadence_outage`). It reported zero `ops.run_log` rows on 2026-08-21 and 08-22 as a fleet-wide trigger outage. Those are a **Friday and a Saturday**, and since the 2026-08-08 daily-tier consolidation **no routine is scheduled on either day**: `ops/cadence.yaml` defines `daily_sun_thu` literally as *"every Sunday-Thursday calendar day, NOT Friday/Saturday"*, every `cron_utc` in the file is either `0,1,2,3,4` (Sun-Thu UTC) or `1,2,3,4,5` (Mon-Fri UTC, which fires the *previous* evening in America/Denver — which is why 2026-08-20 carries 26 rows across 13 routines), and the identical zero-row shape already appears on 2026-08-08, 08-14 and 08-15 with no outage raised, against 24 rows on the pre-consolidation Friday 2026-08-07. The alert's second limb ("no `missed_run` alert was ever raised") is the monitor working correctly — `daily_sun_thu` is `dow NOT IN (6,7)`, so nothing was expected to miss. **No defect exists in OPS0 or `sp_sq_cadence_check` and neither should be changed for this.** Resolved with the full evidence rather than left open, because `alert_emailer.gs` forwards unresolved warnings and a false fleet-outage email is exactly the alarm fatigue the plan names as eroding operator trust. W3 refired nothing.

**The two overdue pre-mortem reviews have the same benign cause and are deliberately not alerted.** `premortem-C-2026-a3` and `premortem-E-2026-a3` have been attacker-complete since 08-20 against a due date of 08-21 — i.e. they came due on the Friday nobody runs. AR_orc's next scheduled fire is tonight. There is already an open AR_orc `artifact_version_drift` alert covering both cycles. Raising anything for a two-day gap that resolves itself in hours would be noise.

**`state.trading_enabled` reads FALSE**, `halt_reason` = *"state.freshness marks_fresh/engine_fresh not both TRUE"*. This is the benign Sunday pre-close artifact: D2a has not yet run today and the newest marks are 08-20. It should clear tonight. **Not an issue and not W3's to fix.**

**Observed, not adjudicated:** `ops.trading_control`'s most recent row is dated **2026-07-19** with `mode='entries_halted'`, which sits oddly against `state.entry_staging_allowed.entries_allowed = TRUE` and against D2 having staged orders freely throughout the intervening month. The operative gate that D2/D2a actually read is `state.trading_enabled`; on a month of evidence `ops.trading_control` is not blocking anything. Recorded as a raw discrepancy for D2a, whose surface it is. W3 did not touch it.

**One prior-cycle referral was re-raised because its channel demonstrably failed.** W3 2026-08-17 referred three data-plane findings to W5 in its run-log note; W5 then ran a full cycle (2026-08-17, completed) whose note mentions none of them. The one that is a live measured discrepancy — `events.regime_events` `SUSTAINED_INVERSION` as-of 2026-08-14 carrying FMP 10Y=4.68 / 2Y=4.17 against Treasury.gov's 4.51 / 3.81 for the same date — is re-raised as `ops.alerts` info `referral_unactioned` naming W5, on the reasoning that a run-log note is evidently not a channel W5 reads. The FMP side was re-verified live this run; the Treasury.gov side is **relayed from the prior W3 and was not re-measured here**, and W5 should re-measure rather than treat it as established. The derived signal is unaffected either way (both sources put 10Y above 2Y, so the curve reads NORMAL). The other two referrals are deliberately not re-raised — the `include_usage` item was settled in the plan text by the 2026-08-19 D1 correction, and the FMP rate-limit item is superseded by W1's standing `source_coverage_gap` alert.

**Research method.** Three Sonnet sub-agent sweeps — book-emptiness verification against BigQuery *and* the live broker, D1/D2 span coverage, and MSCI resolution plus structural capital/regime state. All adjudication, all arithmetic, the dividend-distortion finding and every alert decision were retained in-session (claude-opus-5). **Metered external spend this run: zero.** No Tavily, `web_search`, `web_fetch`, FMP or HF call was made by the orchestrator or by any sub-agent — every fact above came from BigQuery, the IBKR connector, or repo files, all of which are free. Sub-agents were instructed to prefer those surfaces and to cap web use at 3 calls; the one sweep with a budget reported using 0 of 3. Consequently **no `ops.web_calls` rows are owed or written.**

---

## WHAT W4 OWES ON THIS FILE

**Nothing.** There is no `WEEKLY-THESIS-ACTION` flag, no hold/action recommendation, and no `further research` recommendation — so there is no research-deferral checkpoint to enqueue and no thesis action to hand to D2. Stated affirmatively so W4 does not go looking: **W3 produced zero queue-convertible items this cycle.**

The two findings that do exist are already routed to the surfaces that own them, via `ops.alerts`, and are **not** W4's to convert:

- `criterion_dividend_distortion` (warning) → **W5** calibration + future criterion drafting.
- `referral_unactioned` (info) → **W5** data-plane.

Nor should the cross-strategy deconfliction step find anything: with zero open in-scope positions there can be no A↔B or A↔C simultaneous-holding conflict with any W1/W2 new-entry candidate.
