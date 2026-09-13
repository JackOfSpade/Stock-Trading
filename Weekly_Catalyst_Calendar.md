2026-W37

# Weekly Catalyst Calendar — Strategies A and C

Run date **2026-09-13** (Sunday, the `weekly_sun` slot). Windows measured from the run date: **Strategy A = 6 months (2026-09-13 → 2027-03-13); Strategy C = 45 days (2026-09-13 → 2026-10-28).**

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: ~12.4 weeks, to 2026-12-09 — the "6 months" above describes the window this file *searches*, not the horizon its bulk source *reaches*.** Beyond that cliff this file carries only per-name dates obtained from company IR pages, prior-cycle research and cadence projections, at `(C)`/`(E)`/`(T)` provenance, for shortlisted names. The horizon is a standing vendor-plan limit already logged in `Claude_Task_Plan.md` PART 1A, `ops/connector_tools.yaml` and `OWNER_ACTIONS.md` item `FMP-earn-horizon`; **no fresh alert is raised for it and none should be.** **The horizon did NOT move this cycle:** 2026-12-09 is 87 days out, against 2026-12-03 at 88 days last cycle — the same rolling ~13-week window, advanced by the seven days between runs. A probe inside the window returning zero, or the window lengthening, would be new information; neither happened.

**Marker.** `2026-W37` is the ISO week of this run date (Sun 2026-09-13 is weekday 7 of the Mon 09-07 → Sun 09-13 week) — the same week W2/W3 stamp this cycle, and the plain ISO week of today, which is what W4's upstream-freshness gate computes. The upcoming trading week (Mon 2026-09-14 →) is `2026-W38`; that is said here in prose, deliberately not in the marker.

**Catch-up window.** `state.routine_catchup_window` for W1: `never_completed = false`, `window_days = 6.98` — below the weekly 1.5x threshold (10.5 days), so **no `CATCHUP[]` token is owed**. Evidence window: **2026-09-06 → 2026-09-13**.

**Trading-day context, and a split this file has to keep straight throughout.** `state.trading_day_today`: today `2026-09-13`, `is_trading_day = false`, **last trading day 2026-09-11**, next trading day **2026-09-14**.

But the **warehouse stops a session earlier than the tape does.** D1 and D2a run `daily_sun_thu` and last fired Thursday evening, so every `events.regime_events` / `state.signal_marks_curated` figure available to this run is stamped **2026-09-10**, while IBKR — the authority named by `Operating_Protocols.md` §19 PRICE BASIS — has the **2026-09-11** bar for every name this run measured. So:

- **Anything sourced to a `state.*` / `events.*` view here is as of 2026-09-10** and is labelled so.
- **Anything measured off an IBKR regular-session bar here is as of 2026-09-11** and is labelled so.

They are never silently mixed, and where the two disagree the IBKR bar is the one that governs a price. One conclusion in this file was drafted off the warehouse alone and then **walked back** when the 09-11 bar contradicted it — see the SPY_TREND note in the next section.

> ### THE SIX THINGS IN THIS FILE A READER SHOULD NOT MISS
>
> 1. **Strategy C — the only capital-enabled strategy in the book — has a NAV of $23.64, and that number explains a six-drain losing streak that no single drain got wrong.** MEASURED from `state.strategy_nomadic_status`. A $23.64 budget admits only the cheapest **debit** structures, which are **long premium** and need implied vol cheap relative to realized. Across a 33-name measured panel, **exactly two names have implied below realized — PYPL (IV/HV20 0.68) and F (0.83) — and both are earnings events, which the FOMC-only router forbids.** Both router-eligible candidates sit on the rich side, where the edge favours *selling* premium, which $23.64 cannot collateralise. **The affordability constraint and the routing constraint select disjoint sets.** That is the mechanism behind `strategy_c_criterion2_unreached_pattern`, which until now was recorded only as a pattern.
>
> 2. **A second FOMC entered the window this week, and it is not enterable today.** The 45-day window now reaches **2026-10-28**, so C has two router-eligible events where it has had one all quarter. But C's structure rail requires expiration within **1–45 days of entry**, and the first expiry after that meeting (2026-10-30) is **47 days out from today** — outside the rail. It comes inside on **2026-09-15**. A thesis dated today would be inadmissible on tenor alone.
>
> 3. **A conclusion in this file was drafted, then walked back on a free measurement — and the walk-back is the finding.** The warehouse's last reading (2026-09-10) has SPY_TREND flipping UP → NEUTRAL by **0.4158**, which alone would mean the three-cycle *technical-ACTIVATE vs fundamental-DNA* A-router divergence had closed from the technical side. But D1/D2a run `daily_sun_thu` and **Friday 2026-09-11 is not in the warehouse**. The IBKR bar for that session — the mandated price basis — has **SPY at 764.29, back above the same 50-day SMA.** The flip is most likely a one-session artifact that tonight's D2a will reverse. Nothing operational changes either way; the stronger claim was simply wrong.
>
> 4. **Brent rose +11.79% in four sessions while the equities levered to it did not follow** — XLE **−0.58%** on the session crude rose 6.34%. That divergence is the richest seam in the A shortlist (XOM and CVX rank #1 and #2).
>
> 5. **The single best new thesis in this file is one Strategy A is forbidden to use.** The same fuel shock, landing on three airlines that report inside the window with hedge books set beforehand (DAL 10-08, UAL 10-21, AAL 10-22), is a specific, quantified, dated divergence — and it is **short**. Under A's long-only rail it is `DIRECTION-INADMISSIBLE` at any conviction: a category error, not a judgment call. It is ranked, carried, and routed to Strategy B, which is where short theses belong.
>
> 6. **A PDUFA row was wrong in both directions at once, and neither source alone would have caught it.** Last cycle's file carried *"GSK zidesamtinib — approved 2026-07-22"*; this run's fresh aggregator pull returned *"NUVL zidesamtinib — PDUFA 2026-09-18, pending."* Resolved against the FDA's own approvals page: **zidesamtinib is Nuvalent's (NUVL), and it was approved 2026-07-22, two months ahead of its PDUFA target.** The prior cycle had the company wrong; the fresh pull was serving a stale, superseded date. **Row struck.**
>
> **And the census, because the spec pins it:** `SELECT * FROM state.open_queue WHERE strategy = 'A'` returns **40 rows**. Last cycle's file said 23 against a true 39. The query wins, always.

## Regime and routing state (measured this run)

Every figure below is a MEASURED read of a `state.*` / `events.*` view or an IBKR bar this session, not a recollection.

| Input | Value | As of | Source |
|---|---|---|---|
| Fundamental regime (integrative) | decelerating growth + disinflation + hawkish tightening bias + risk-on + acute shock | 2026-09-01 | `state.current_regime` (M1a) |
| `growth_momentum` | decelerating | 2026-09-01 | `state.current_regime` |
| `inflation_trend` | disinflating (on the disinflating/stable boundary, low confidence) | 2026-09-01 | `state.current_regime` |
| `policy_stance` | hawkish | 2026-09-01 | `state.current_regime` |
| `risk_sentiment` | risk-on | 2026-09-01 | `state.current_regime` |
| `shock_overlay` | acute | 2026-09-01 | `state.current_regime` |
| SPY_TREND | **NEUTRAL** (close 757.83) — see the correction below | 2026-09-10 | `events.regime_events` (D2a) |
| EQUITY_BREADTH | HEALTHY, 54.67% | 2026-09-10 | `events.regime_events` (D1 measurement, D2a threshold) |
| VIX_REGIME | NORMAL, 17.84 | 2026-09-10 | `events.regime_events` (D2a) |
| SUSTAINED_INVERSION | NOT-SUSTAINED, 10Y−2Y = +0.39 | 2026-09-10 | `events.regime_events` (D2a) |

**Strategy activation / capital state** — `state.strategy_capital_enablement`, all five rows stamped 2026-09-03 (the M1b/AR_orc divergence cohort):

| Strategy | Activation state | Capital |
|---|---|---|
| A | DO-NOT-ACTIVATE | disabled |
| B | DO-NOT-ACTIVATE | disabled |
| **C** | **HYBRID ACTIVATE (FOMC-only)** | **enabled** |
| D | DO-NOT-ACTIVATE | disabled |
| E | DO-NOT-ACTIVATE | disabled |

**C is the only capital-enabled strategy, and only for FOMC.** That is the most load-bearing routing fact in this file and it decides how both shortlists should be read.

### THE WAREHOUSE STOPS AT 2026-09-10; THE TAPE DOES NOT — and one reading has to be walked back because of it

`state.trading_day_today` reports today `2026-09-13`, `is_trading_day = false`, **last trading day `2026-09-11`**. But every `events.regime_events` / `state.signal_marks_curated` row above is stamped **2026-09-10**, because D2a and D1 run `daily_sun_thu` and their last fire was Thursday evening. **Friday 2026-09-11 traded and is simply not in the warehouse yet.** It is, however, in IBKR — the source `Operating_Protocols.md` §19 PRICE BASIS names as authoritative for any close a screen gates on — and this run pulled it directly, free and unmetered.

**The correction that follows from it.** On the warehouse's last reading, SPY_TREND flipped **UP → NEUTRAL on 2026-09-10**: SPY closed 757.83 against a 50-day SMA of **758.2458**, short by **0.4158** (about 0.05%), with the 50/200 relationship unchanged and still strongly positive (+44.54). Read alone, that is Strategy A's router rule — **SPY Trend = UP AND Breadth = HEALTHY** — failing on its first conjunct for the first time in this sequence, which would mean the three-cycle *technical ACTIVATE vs fundamental DO-NOT-ACTIVATE* divergence recorded in `div-A-202608-1` had closed from the technical side.

**MEASURED on the IBKR bar for the session the warehouse has not yet seen: SPY closed 764.29 on 2026-09-11, +0.85% on the day and roughly six points back ABOVE that same 50-day SMA.** So the flip is, on the evidence, **a one-session artifact that D2a's next run tonight will most likely reverse** — not a regime change, and not a closed divergence. **I am recording the walk-back explicitly rather than quietly publishing the stronger claim**, because the stronger claim was what the warehouse alone supported and it would have been wrong.

Three things stay true regardless of which way the key resolves:

1. **Nothing operational changes either way.** A's operative state is DO-NOT-ACTIVATE and A is capital-disabled; the technical leg agreeing or disagreeing cannot make A more disabled. **No portfolio action follows and none is proposed.**
2. **The recomputation is D2a's, not W1's.** W1 does not compute `SPY_TREND` and must not pre-empt it. The authoritative 09-11 value will exist after tonight's D2a fire; what is written here is the input, not the verdict.
3. **Strategy C's router is untouched.** C's rule is **SPY Trend ≠ DOWN**. NEUTRAL satisfies it and UP satisfies it, so C remains routed and capital-enabled for FOMC on either resolution.

### What actually moved in the evidence window (2026-09-06 → 2026-09-13)

| Series | 2026-09-04 | 2026-09-10 | Change | Source |
|---|---|---|---|---|
| Brent (BZUSD) | 96.28 | **107.63** | **+11.79%** | `state.signal_marks_curated` (stops at 09-10) |
| SPY | 770.19 | 757.83 → **764.29 (09-11)** | −1.60% to 09-10, **−0.77% to 09-11** | warehouse to 09-10; **IBKR bar for 09-11** |
| ^VIX | 14.53 | 17.84 | +3.31 pts | `state.signal_marks_curated` (stops at 09-10) |
| S&P 500 % above 200-DMA | 60.63 (09-08) | 54.67 | −5.96pp over three sessions | `events.regime_events` |
| 10Y / 2Y | — | 4.95 / 4.56 | spread +0.39 (from +0.40 on 09-09) | D2a 2026-09-10 |

**Brent's Friday print is NOT known to this file.** The commodity mark is D2a-written and D2a's last run was Thursday, so `+11.79%` is measured **2026-09-04 → 2026-09-10** and stops there. Whether crude extended or gave back on Friday is unobserved, and no row below assumes either.

**Brent +11.79% in four sessions is the dominant new fact of this window** and it is what most of the ranking turns on. It is not a regime re-score — `shock_overlay` was already `acute` at the 2026-09-01 M1a — but it is a large, dated, quantified intensification of the shock axis landing inside the catalyst window and three days before an FOMC that is already two-sided on inflation.

D1 recorded the equity-side response and that is the interesting part: **energy equities did not follow crude up.** XLE +1.11% (09-08), +0.83% (09-09) against Brent +3.36%, then **−0.58% on 09-10 while Brent rose 6.34%**. D1 read the last of these as demand-destruction pricing. A commodity repricing violently while the equities levered to it do not is a documentable consensus-versus-tape gap, and it is the richest seam in this cycle's A shortlist.

## DAILY-TO-WEEKLY BOUNDARY — what D1 already owns, and the one session no W1 can ever see

Per this section's spec, W1 does not rediscover catalysts D1 has already announced and synthesized. D1's records for the window 2026-09-07 → 2026-09-13 were read in full (`events.decision_log`, entry types `research-screen`, `add-candidate-review`, `thesis-construction`, `action-conversion`, plus `Daily.md`). **The forward-dated catalysts below are REUSED from D1 with its canonical date, source and `entry_id` — this file does not re-run the announcement search for any of them.**

| Ticker | Catalyst type | D1's canonical date | D1 `entry_id` |
|---|---|---|---|
| ORCL | Earnings, FQ1 FY2027 (reported AMC) | 2026-09-10 | `Daily.md` §2 (reaction session 09-11) |
| ADBE | Earnings, Q3 FY2026 + CEO transition (reported AMC) | 2026-09-10 | `Daily.md` §2 (reaction session 09-11) |
| TLX | FDA PDUFA, TLX101-Px | 2026-09-11 | `Daily.md` §2 pending list |
| SRRK | FDA PDUFA, apitegromab (SMA) | 2026-09-30 | `Daily.md` §2 pending list |
| VRTX | sNDA PDUFA, Journavx chronic low-back pain | 2026-12-05 | `Watchlist.md` A-queue row |
| INTU | Investor Day | 2026-09-17 | `Watchlist.md` A-queue row |
| TTWO | GTA VI launch (company-confirmed twice) | 2026-11-19 | `Watchlist.md` A-queue row |
| AMZN | Q3 earnings / re:Invent | 2026-10-29 / 2026-11-30→12-03 | `Watchlist.md` A-queue row |
| FSLR | US Section 232 solar-trade regime effective | 2026-12-04 | `Watchlist.md` A-queue row (added 2026-09-06) |
| NVS / AMGN / IONS | Pelacarsen CV-outcomes Phase 3 miss + read-across | 2026-09-08 | `a4ce03b2` |
| IONQ | Investor Day, FY26 revenue guide raised | 2026-09-08 | `a4ce03b2` |
| TBBK | Named BaaS client loss (Chime/Stride Bank, $590M) | 2026-09-09 | `acc31c4a` |
| COO / AEO / NAVN / M / AVAV | Earnings prints | 2026-09-09 → 09-10 | `7d717e9f` |
| SCCO / FCX | US copper-tariff decision — **no dated resolution point** | undated | `7d717e9f` |

### THE FRIDAY BLIND SPOT — structural, not an outage, and it binds every W1 run

I checked whether the fleet had stalled and it had not. **MEASURED, and stated as a correction to the obvious first reading of the data:** `ops.run_log` holds 26 rows across 13 routines for 2026-09-09 and again for 2026-09-10, and then **zero rows for 2026-09-11 and 2026-09-12**. That looks exactly like a two-day fleet outage. **It is not one.** The daily fleet's monitor class is `daily_sun_thu`, documented in `ops/cadence.yaml` as "every Sunday-Thursday calendar day, NOT Friday/Saturday", `state.fleet_blackout_days` returns **zero rows**, and no `missed_run` / `routine_stalled` / `staleness` / `missing_dependency` alert has been raised since 2026-09-08. Friday and Saturday are simply not run days. Nothing is late and nothing is owed.

What IS true, and what the spec's DAILY-TO-WEEKLY paragraph does not account for, is the **ordering**:

- **W1 fires Sunday 07:30 UTC** (`30 7 * * 0`).
- **D1 fires 22:00 UTC on Sun–Thu** (`0 22 * * 0,1,2,3,4`).
- D1's most recent run was **Thursday 2026-09-10 22:00 UTC**, covering the 09-10 session. Its next run is **tonight, 2026-09-13 22:00 UTC — 14.5 hours AFTER this W1 run.**

Therefore **the Friday session is never in D1's record at the moment any W1 executes.** This is not this week's accident; it is true of every W1 run by construction. This week it costs more than usual: Friday **2026-09-11** carried the **ADBE and ORCL earnings reaction sessions** — both companies reported after the 09-10 close, and D1 explicitly recorded the 09-10 moves as *pre-print drift, not the reaction*, stating "the next D1 owns them" — and, per D2's 2026-09-08 Strategy C entry, the **August CPI print was scheduled for 09-11**, three sessions before the FOMC this file's only executable candidate turns on.

**How this run handled it, per the spec's own instruction to do only the minimum check needed to preserve the forward calendar and never turn the exception into a second broad news scan:** no news scan was run, and **no metered call was spent on Friday at all.** The two known Friday events are *reactions to prints already in the record*, not new forward-dated catalysts, and ADBE's **next** date (2026-12-09) was already captured by this run's bulk calendar pull.

Friday's **tape**, by contrast, was covered in full and for free: every one of the 33 names measured for PART 2B returned an IBKR regular-session bar dated **2026-09-11**, and those bars are the mandated price basis. **SPY closed 764.29 on 2026-09-11, +0.85% on the day.** That single free measurement is what forced the SPY_TREND walk-back in the section above — the warehouse's 09-10 NEUTRAL reading would have supported a materially stronger and wrong claim about A's router. **The Friday blind spot is a NARRATIVE gap, not a PRICE gap, and this run closed the price half at zero cost.**

**The forward calendar below loses nothing to this gap. The backward-looking read of Friday's news belongs to tonight's D1 and is deliberately left there.**

The spec gap itself — its escape hatch is written for "D1 itself is genuinely unavailable", which is not this case, and it does not contemplate a guaranteed one-session blind spot arising from trigger ordering — is **outside W1's ownership** (W1 does not own its own section's design). It is recorded, not repaired; see OUT-OF-SCOPE FINDINGS.

## PART 1A — Strategy A universe catalyst calendar (6-month window, 2026-09-13 → 2027-03-13)

### COVERAGE STATEMENT — read before any table below

Strategy A's universe is *"all US-listed equities with market cap ≥ $2B and 30-day ADV ≥ $10M with a scheduled catalyst in the next 6 months."* **That population cannot be enumerated from the connectors this system has.** This is a structural plan gate, not a budget shortfall and not a transient failure: `search.search-company-screener`, all `directory.*` endpoints and `quote.batch-quote` each return ACCESS DENIED on this FMP tier (measured 2026-09-06; `ops.alerts` `6c4004e3`, owned to W5 / `OWNER_ACTIONS.md` item `FMP-earn-horizon`). **No fresh alert is raised for it here** — it is recorded, it has not changed, and a weekly re-raise is alarm fatigue.

What this file therefore IS: a catalyst calendar over the **reachable** population — the union of (i) every symbol the forward `earnings-calendar` pull returns, (ii) the 40 names already on the Strategy A queue, (iii) names D1 surfaced in the evidence window, and (iv) dated non-earnings catalysts carried from prior-cycle research. **Every count below is a floor, not a total.** A reader who quotes a figure from this file as "the number of Strategy A catalysts" will be wrong in the optimistic direction.

**Measured this run.** The bulk pull returned **78 rows across 77 unique symbols** spanning **2026-09-17 → 2026-12-09**, from 9 date-sliced requests; two consecutive slices beyond 2026-12-20 returned zero rows, which is what fixes the horizon.

**A new endpoint finding, stated in its corrected form — the first version of this paragraph was wrong and the error is instructive.** `batch-market-cap` is **not** plan-denied: it returned a market cap for **all 77** calendar symbols in ONE request, so 74 clear the $2B rail and TLRY ($0.45B), FUBO ($1.26B) and LCID ($1.34B) fail it **by measurement rather than by assumption**. That looked like it generalised to "the $2B rail is now checkable for any candidate list at one call." **It does not.** A follow-up probe passing **47 A-queue and energy names** returned **only 8** — and those 8 were precisely the ones already inside the calendar allow-list. The single-symbol `company/market-cap` endpoint then returned **ACCESS DENIED** outright.

So the corrected reading, which is narrower and more useful than either the old finding or my first draft of this one:

- `batch-market-cap` works **only over the plan's covered symbol set** — effectively the same allow-list the forward calendar exposes.
- For symbols outside it, **it does not error. It silently omits them from the response.** A caller that passes 47 symbols, receives 8, and does not compare the two lists will conclude the other 39 have no market cap, or will run a "screen" over 8 names believing it covered 47.
- Single-symbol `market-cap` is denied, so there is no per-name fallback.

**Consequence for this file:** market cap is MEASURED for the 77 reachable calendar names and is **NOT measured** for queue-only names (AKAM, AMAT, AVGO, CAT, CRM, CRWD, DDOG, DELL, FSLR, GEV, HPE, IBM, INTU, LLY, MRVL, MU, NBIS, NOW, NTAP, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TTWO, VRTX and the rest). For those the cap rail is carried as **CAP-UNVERIFIED**, and where this file judges them above the floor it says so as a labelled **inference**, never as a measurement. The silent-omission behaviour is recorded as finding **F-4**.

The 30-day ADV half of the rail is unreachable from FMP at any tier here and was measured instead off **IBKR regular-session daily bars, which are free and unmetered** — see 1A.3a, where it is measured for 52 names and every one of them passes.

**Provenance key used throughout PART 1A and 1B:**
**(C)** first-party confirmed — company IR, an agency, or an exchange release, cited.
**(2S)** two independent secondary sources in agreement.
**(E)** vendor calendar or a single secondary source — estimated.
**(T)** tentative: no day-level date, or a date this file positively distrusts (said so at the row).

The bulk `earnings-calendar` rows are **(E)** without exception. FMP mixes company-confirmed and vendor-projected dates in that endpoint and exposes no field distinguishing them, and `calendar/earnings-company` — the per-symbol route that would settle it — is ACCESS DENIED. Rows upgraded to (C) below are upgraded because D1, `Watchlist.md` or a company release independently pinned them, not because the vendor asserted them twice.

### THE HORIZON, AND WHAT IS BEYOND IT

The effective confirmed-earnings horizon is **2026-12-09**, 87 days out — against **2026-12-03 at 88 days** last cycle. **The horizon did not move.** It is the same forward-only rolling ~13-week window, advanced by the seven days between runs; a probe inside the window returning zero, or the window genuinely lengthening, would be new information and neither happened. Roughly the last **13 weeks** of the 6-month window — all of January, February and the first half of March 2027, which is exactly the FY-report cluster — **cannot be filled from a bulk calendar pull at all**, and the historical end is not merely empty but explicitly refused (`ACCESS DENIED`), so the "project last year's actual report dates forward" fallback is unavailable too.

The tail is filled per-name for shortlisted names only, from company IR and prior-cycle research, and every such row is labelled. It is not filled speculatively for names that are not shortlisted, and the resulting holes are real.

#### 1A.1 — Earnings inside the Strategy C 45-day window (2026-09-13 → 2026-10-28)

| Date (E) | Ticker | Market cap | A-eligible? |
|---|---|---|---|
| 2026-09-17 | FDX | $73.8B | yes |
| 2026-09-24 | COST | $401.2B | yes |
| 2026-10-01 | NKE | $54.5B | yes |
| 2026-10-05 | CCL | $31.2B | yes |
| 2026-10-08 | DAL | $52.6B | yes |
| 2026-10-08 | PEP | $186.2B | yes |
| 2026-10-08 | TLRY | $0.4B | NO - cap $0.45B < $2B |
| 2026-10-13 | C | $238.1B | yes |
| 2026-10-13 | GS | $303.6B | yes |
| 2026-10-13 | JNJ | $640.0B | yes |
| 2026-10-13 | JPM | $954.5B | yes |
| 2026-10-13 | WFC | $272.9B | yes |
| 2026-10-14 | BAC | $444.9B | yes |
| 2026-10-15 | TSM | $2247.0B | NO - ADR, not US common equity |
| 2026-10-20 | GE | $335.8B | yes |
| 2026-10-20 | GM | $77.4B | yes |
| 2026-10-20 | KO | $379.9B | yes |
| 2026-10-20 | LMT | $121.0B | yes |
| 2026-10-20 | NFLX | $322.3B | yes |
| 2026-10-20 | VZ | $211.3B | yes |
| 2026-10-21 | T | $178.5B | yes |
| 2026-10-21 | UAL | $35.6B | yes |
| 2026-10-22 | AAL | $8.6B | yes |
| 2026-10-22 | F | $55.7B | yes |
| 2026-10-22 | INTC | $519.2B | yes |
| 2026-10-22 | NOK | $60.2B | NO - ADR, not US common equity |
| 2026-10-23 | HCA | $92.4B | yes |
| 2026-10-27 | CARR | $47.4B | yes |
| 2026-10-27 | PYPL | $46.0B | yes |
| 2026-10-27 | SOFI | $22.2B | yes |
| 2026-10-27 | UNH | $344.3B | yes |
| 2026-10-27 | V | $691.6B | yes |
| 2026-10-28 | BA | $166.3B | yes |
| 2026-10-28 | FDX | $73.8B | NO - (T) suspect vendor row |
| 2026-10-28 | GOOGL | $4096.6B | yes |
| 2026-10-28 | META | $1650.8B | yes |
| 2026-10-28 | MSFT | $3680.3B | yes |
| 2026-10-28 | SBUX | $112.6B | yes |
| 2026-10-28 | TSLA | $1443.3B | yes |

39 rows.

#### 1A.2 — Earnings from 2026-10-29 to the horizon (2026-12-09)

| Date (E) | Ticker | Market cap | A-eligible? |
|---|---|---|---|
| 2026-10-29 | AAPL | $4880.2B | yes |
| 2026-10-29 | AMZN | $2762.2B | yes |
| 2026-10-29 | COIN | $46.2B | yes |
| 2026-10-29 | RBLX | $32.5B | yes |
| 2026-10-29 | RIOT | $8.1B | yes |
| 2026-10-29 | RKT | $37.2B | yes |
| 2026-10-30 | ABBV | $454.2B | yes |
| 2026-10-30 | CVX | $426.2B | yes |
| 2026-10-30 | XOM | $688.1B | yes |
| 2026-11-02 | FUBO | $1.3B | NO - cap $1.26B < $2B |
| 2026-11-02 | PLTR | $384.0B | yes |
| 2026-11-03 | AMD | $841.6B | yes |
| 2026-11-03 | PFE | $158.0B | yes |
| 2026-11-03 | PINS | $12.1B | yes |
| 2026-11-03 | RIVN | $19.5B | yes |
| 2026-11-03 | SHOP | $167.1B | yes |
| 2026-11-03 | SIRI | $9.8B | yes |
| 2026-11-03 | UBER | $145.9B | yes |
| 2026-11-04 | ET | $74.2B | yes |
| 2026-11-04 | ETSY | $6.9B | yes |
| 2026-11-04 | HOOD | $101.2B | yes |
| 2026-11-04 | LCID | $1.3B | NO - cap $1.34B < $2B |
| 2026-11-04 | MGM | $10.0B | yes |
| 2026-11-04 | ROKU | $23.0B | yes |
| 2026-11-04 | SNAP | $9.6B | yes |
| 2026-11-05 | MRNA | $57.1B | yes |
| 2026-11-10 | SONY | $140.4B | NO - ADR, not US common equity |
| 2026-11-11 | CSCO | $442.0B | yes |
| 2026-11-12 | BILI | $6.5B | NO - ADR, not US common equity |
| 2026-11-12 | DIS | $185.0B | yes |
| 2026-11-17 | BIDU | $31.1B | NO - ADR, not US common equity |
| 2026-11-18 | NVDA | $5287.2B | yes |
| 2026-11-18 | TGT | $70.8B | yes |
| 2026-11-19 | WMT | $852.7B | yes |
| 2026-11-23 | ZM | $28.0B | yes |
| 2026-11-24 | BABA | $262.0B | NO - ADR, not US common equity |
| 2026-11-24 | NIO | $9.2B | NO - ADR, not US common equity |
| 2026-12-03 | DOCU | $12.5B | yes |
| 2026-12-09 | ADBE | $100.3B | yes |

39 rows.

### 1A.3 — The universe rails, and which one actually binds

Strategy A's two rails are **market cap ≥ $2B** and **30-day average dollar volume ≥ $10M**, both at entry.

**Cap rail — MEASURED for the 77 reachable calendar names, NOT measurable for queue-only names.** One `batch-market-cap` request returned a cap for all 77. **74 clear $2B; three fail and are excluded from A by measurement: TLRY ($0.45B), FUBO ($1.26B), LCID ($1.34B).** A further seven are excluded on a different ground — **TSM, BABA, NIO, BIDU, BILI, SONY and NOK are ADRs**, not US-listed common equity, and A's universe is defined on the latter. (That is the same ground on which TSM appears in `Watchlist.md`'s audit trail but not in the live A queue.) For names outside the allow-list the cap is **CAP-UNVERIFIED** — see the corrected endpoint finding in the COVERAGE STATEMENT and finding F-4.

### 1A.3a — ADV rail, MEASURED off IBKR regular-session bars

52 names — the full A queue, the open D book and an energy cross-section — were measured from IBKR daily RTH bars, 30-day average dollar volume computed per-bar (mean of close × volume, not average price × average volume). **All 52 resolved cleanly to a US-listed primary common-stock contract, and all 52 PASS the ≥$10M rail. Zero fail, zero unverified, zero unresolved.**

The rail is not close for any of them. The **lowest** measured 30-day average dollar volume in the set is **AKAM at ~$183M** — roughly **18x** the $10M floor — and the highest is **MU at ~$18.1B**. Selected rows:

| Ticker | Close (2026-09-11) | 30d avg $ volume | 1-week % |
|---|---|---|---|
| MU | 975.26 | ~$18,131M | +1.78% |
| NVDA | 218.29 | ~$15,822M | −4.45% |
| AAPL | 332.27 | ~$8,914M | +1.24% |
| MSFT | 495.63 | ~$6,899M | −2.84% |
| INTC | 102.94 | ~$6,303M | **+12.29%** |
| META | 648.03 | ~$6,193M | +6.12% |
| AMZN | 256.78 | ~$5,597M | −0.82% |
| AMD | 516.13 | ~$5,585M | **+13.15%** |
| GOOGL | 338.50 | ~$4,921M | −1.16% |
| XOM | 165.99 | ~$983M | +2.33% |
| CVX | 214.06 | ~$692M | +1.30% |
| COP | 137.35 | ~$379M | +1.20% |
| **ADBE** | 252.23 | ~$727M | **−11.73%** |
| AKAM | 106.79 | ~$183M (lowest in set) | +0.27% |

**So the ADV rail binds nothing here, and that is a measurement rather than an assumption.** The constraints that actually bind the shortlist are the cap rail, ADR status, and above all whether a name is *reachable at all* — the vendor allow-list, not liquidity, is what shapes this file.

**Two things the 1-week column settles that the warehouse could not.** Both are measured off the 2026-09-11 bar the warehouse has not yet ingested:

- **ADBE −11.73% on the week.** Adobe reported after the close on 2026-09-10 alongside a CEO transition, and D1 explicitly recorded the 09-10 move as *pre-print drift, not the reaction*. This is the reaction, and it is sharply negative — which **vindicates on the tape** the bearish direction ADBE has carried in the DIRECTION-INADMISSIBLE tier for several cycles. It does not make ADBE admissible to Strategy A; a confirmed-correct short thesis is still a short thesis.
- **The semiconductor and AI-infrastructure complex ran hard into the same week the index fell:** INTC +12.29%, AMD +13.15%, MRVL +13.06%, HPE +14.05%, DELL +9.86%, QCOM +7.95%, NTAP +7.50%, NBIS +6.61% — against SPY −0.77% over the comparable span. Breadth fell 5.96pp over three sessions while this group rose, which is consistent with the narrowing D1 flagged and is the tape-level counterpart of it.

### 1A.4 — Product launches, keynotes and product events

CARRIED rows come from the 2026-09-06 file with original sourcing intact and were **not re-verified** this run.

| Date | Ticker | Event | Prov. | Source |
|---|---|---|---|---|
| 2026-09-15 → 09-17 | CRM | Dreamforce 2026, Moscone Center SF — Agentforce | (C) | CARRIED |
| 2026-09-23 → 09-24 | META | Meta Connect 2026 — AI / VR / wearables | (C) | CARRIED |
| 2026-10-20 → 10-22 | NVDA | GTC Berlin | (E) | CARRIED |
| 2026-10-25 → 10-28 | ORCL | Oracle AI World / CloudWorld 2026 | (C) | CARRIED |
| 2026-11-10 → 11-12 | ADBE | Adobe MAX 2026 | (E) | CARRIED |
| 2026-11-17 → 11-20 | MSFT | Microsoft Ignite 2026 | (C) | CARRIED |
| **2026-11-19** | **TTWO** | **GTA VI launch** (PS5, Xbox Series X\|S); digital pre-load 11-12 | **(C)** | CARRIED **+ RE-VERIFIED NEW this run** — CEO publicly reaffirmed, no further delay |
| 2026-11-30 → 12-04 | AMZN | AWS re:Invent 2026 | (C) | CARRIED |
| 2026-11-30 → 12-03 | NVDA | GTC Washington DC | (E) | CARRIED |
| 2026 (year only) | GOOGL | Waymo multi-city robotaxi launches (Dallas, Houston, San Antonio, Miami, Orlando) | (T) | CARRIED — no day-level date |
| 2027-01-06 → 01-09 | broad | CES 2027, Las Vegas | (E) | CARRIED |

**Named as BEYOND WINDOW so a later cycle does not rediscover it:** NVDA GTC 2027, 2027-03-15 → 03-18 (C) — the window closes 2027-03-13, two days before it starts.

**Caveat:** this table is carry-forward-heavy and the March 2027 tail is thin. AAPL's next hardware event (typically spring) has not been announced and was not searched for. AAPL's 2026-09-09 keynote is **NOW PAST** and is deliberately not carried forward as a forward row.

### 1A.5 — Analyst days, investor days and conferences

| Date | Ticker | Event | Prov. | Source |
|---|---|---|---|---|
| 2026-09-16 | ON | onsemi Financial Analyst Day, NYC | (C) | CARRIED |
| **2026-09-17** | **INTU** | **Intuit Investor Day**, 08:00–12:00 PDT | (C) | CARRIED — first-party, second consecutive cycle. **The nearest dated catalyst on the entire A queue** |
| 2026-09-17 | DCO | Ducommun Investor Day, NYC | (C) | CARRIED |
| 2026-10-13 | BGC | FMX (BGC Group) first Investor Day, NYC | (C) | CARRIED |
| **2026-10-13** | **WDAY** | **Workday Financial Analyst Day**, at Workday Rising | (C) | CARRIED — release dated 2026-09-01 |
| "Fall 2026" | NKE | Nike investor day | (T) | CARRIED — no day, single weak source |
| ~early Dec 2026 | UNH | UnitedHealth investor conference | (E) | CARRIED — projected from annual cadence |
| **2027-02-22** | **JPM** | **JPMorganChase Investor Day** | (C) | CARRIED |

**Affirmative negative, searched this run:** no standalone investor or analyst day exists in the window for **AMZN, MSFT, META or GOOGL**. Searches returned only quarterly earnings dates. This is consistent with those companies' actual practice — they communicate through product keynotes and earnings calls — and is stated as a *not found* rather than left as an unsearched hole. It was one search pass, not an IR-calendar-by-IR-calendar sweep.

### 1A.6 — Regulatory, legal, trade and policy decisions

| Date | Ticker(s) | Event | Prov. |
|---|---|---|---|
| 2026-09-29 | GOOGL | DOJ v. Google search remedies — Google reply brief due (D.C. Cir.); argument unscheduled | (C) |
| 2026-09-30 | BMY | Camzyos adolescent oHCM sNDA PDUFA | (2S) |
| 2026-09-30 | broad | US government funding deadline; Senate-passed CR runs to 2026-12-11 | (E) |
| **2026-10-02** | **GOOGL** | **DOJ v. Google ad-tech — joint proposed Final Judgment due**, following the 2026-09-02 Brinkema remedies ruling (breakup avoided, operational changes ordered) | (C) |
| 2026-10-04 | MRK | Welireg + Lenvima, advanced RCC sNDA PDUFA | (C) |
| 2026-10-10 | MRK | Ifinatamab deruxtecan, ES-SCLC BLA PDUFA | (C) |
| 2026-10-16 | V | DOJ v. Visa — fact discovery closes (expert discovery to 2027-04-08); no trial date | (C) |
| 2026-10-17 | VTRS | MR-141 presbyopia sNDA PDUFA | (C) |
| by Oct 2026 | AAPL | Company-stated deadline to update App Store terms for EU DMA compliance | (C) as commitment, no day |
| 2026-11-10 | China-import-exposed | USTR Section 301 exclusions (178 products) expire 23:59 ET 11-09 absent extension | (C) |
| 2026-11-18 | UNP · NSC | STB UP–NS merger review: public comments due | (C) |
| **2026-11-30** | **VRTX** | Povetacicept BLA PDUFA, IgA nephropathy, Priority Review | (C) |
| 2026-12-03 | UNP · NSC | STB UP–NS: DOJ / USDOT preliminary comments due | (C) |
| **2026-12-04** | **FSLR** + solar chain | **Section 232 tariff / minimum-import-price regime effective** — polysilicon $21/kg, ingots-wafers $100/kg, cells $0.22/W, modules $0.38/W | (C) whitehouse.gov |
| **2026-12-05** | **VRTX** | **Journavx (suzetrigine) chronic-low-back-pain sNDA PDUFA** — distinct from the povetacicept row above | (2S) |
| by year-end 2026 | BA | FAA type certification, 737 MAX 10 | (T) |
| late 2026 | NVO | FDA decision, CagriSema NDA — **ADR, not A-eligible** | (T) |
| **2027-01-21** | **DYN** | Z-rostudirsen BLA PDUFA, DMD exon 51, Priority Review | (C) |
| 2027-02-16 | UNP · NSC | STB UP–NS: responses to comments/protests due | (C) |
| **2027-02-28** | **BMRN** | VOXZOGO sNDA — full approval in achondroplasia | (C) |
| 2027-02-28 | SRPT | AMONDYS 45 / VYONDYS 53 sNDAs, DMD — cap ~$2.14B, **sits on the $2B floor; re-measure before use** | (C) |
| ~2027-02 | LYV | DOJ / states v. Live Nation — remedies phase, unscheduled | (E) |
| **2027-03-02** | **WBD** (acquirer PSKY) | States' antitrust trial over the Paramount Skydance–WBD merger begins — judge-set | (C) |

**One row recovered this run that last cycle's table did not carry:** VRTX's **Journavx sNDA PDUFA 2026-12-05**, present in `Watchlist.md`'s A-queue row but absent from the 2026-09-06 regulatory table. It is distinct from VRTX's povetacicept PDUFA on 2026-11-30 — **two separate dated regulatory catalysts five days apart on the same name**, which is why the omission mattered.

**Resolved before the window, recorded so it is not rediscovered:** the SCOTUS IEEPA tariff ruling (*Learning Resources v. Trump*, consolidated with *Trump v. V.O.S. Selections*) was decided **2026-02-20**; the IEEPA tariff regime terminated 2026-02-24. It is **not** a forward catalyst, and specifically **it does not touch the FSLR Section 232 row above** — Section 232 rests on separate national-security statutory authority untouched by that ruling. Checked this run precisely because a reader could reasonably assume otherwise.

**Named as BEYOND WINDOW:** FTC v. Amazon trial, ~2027-03-29 (E).

**Not searched this run:** the FDA advisory-committee calendar was not re-checked for new October–March notices. Federal Register lead times make these highly time-sensitive and last cycle already classified this as a re-check rather than a gap to alert on; the budget was spent on higher-priority items first.

### 1A.7 — Restructuring and structural events

| Date | Ticker(s) | Event | Prov. |
|---|---|---|---|
| 2026-09-18 | S&P 500 | Q3 quarterly index rebalance (third Friday; effective ~09-21 open) | (E) |
| Q4 2026 | CTVA | "Vylor" seed/genetics spin-off completion — company says only "on track for Q4 2026" | (T) |
| 2H / by year-end 2026 | KMB · KVUE | Kimberly-Clark / Kenvue merger close; votes passed 2026-01-29; outside date 2026-11-02, auto-extending to 2027-05-03 | (T) |
| spans window | TECK | Anglo American–Teck final approvals; China MOFCOM the last pending item | (C) |
| mid-Dec 2026 | Nasdaq-100 | Annual reconstitution, effective before the third-Friday open | (E) |
| 2026-12-18 | S&P 500 | Q4 quarterly index rebalance | (E) |
| 2027-01-01 | DG | CEO transition — Fleeman becomes CEO | (C) |
| upon 2026 10-K filing | BA | SVP Finance Shedd succeeds Cleary as Controller (8-K 2026-08-21) | (C) |

**Narrative input with no datable forward row:** UBER's 2026-09-02 restructuring announcement (~3,300 roles, ~10% of headcount; management layers −20%; AV footprint 7→15 cities). It feeds PART 2A #19 as thesis context; it is not a forward calendar row because the announcement is already past and no execution date was given.

**Checked this run and confirmed already complete before the window** (so they are not rediscovered as gaps): Comcast/Versant spin-off (completed 2026-01-02, trading as VSNT from 01-05), Honeywell/Solstice (Oct 2025), DuPont/Qnity (Nov 2025).

**One unresolved gap, left unresolved rather than guessed:** the **Honeywell Aerospace** spin-off — distinct from the completed Solstice spin-off — returned internally inconsistent dates across sources, so no date is published here. It needs a direct read of Honeywell's own spin-off reference page, which was not fetched within budget. **Named as an open gap; not fabricated.**

**Caveat:** this is the thinnest of the four tables, and that is structural rather than a research failure — IPO lockups and index-reconstitution adds/drops are largely unannounceable this far ahead.

## PART 1B — Strategy C universe catalyst calendar (45-day window, 2026-09-13 → 2026-10-28)

Strategy C's qualifying event list is **closed by the strategy itself** and this run re-read it to be sure: corporate earnings releases (US-listed, **confirmed date from company IR**), FDA PDUFA dates (FDA calendar or company disclosure), FOMC meetings (confirmed Fed calendar). `strategy/05_strategy_c.md` then says in terms: *"Other event types (analyst days, product launches, conference presentations, M&A-related, legal rulings, index rebalances) are excluded at the strategy level."* Nothing else below the line is eligible, however interesting.

### 1B.1 — FOMC (confirmed, federalreserve.gov)

| Dates | Decision day | SEP / press conference | Window |
|---|---|---|---|
| 2026-09-15 → 09-16 | **Wed 2026-09-16**, statement 14:00 ET, presser 14:30 ET | **SEP (dot plot) + press conference** | IN WINDOW — **3 days away** |
| 2026-10-27 → 10-28 | **Wed 2026-10-28** | press conference, **no SEP** | IN WINDOW |

**The October FOMC is newly in scope and that is purely a window-arithmetic fact, not new research.** Last cycle's 45-day window ended 2026-10-21 and stopped short of it; this cycle's ends 2026-10-28 and reaches the decision day exactly. C now has **two** qualifying FOMC events in window where it has had one all quarter.

Remaining 2026: Dec 8-9 (SEP). Announced 2027: Jan 26-27, Mar 16-17, Apr 27-28, Jun 8-9, Jul 27-28, Sep 14-15, Oct 26-27, Dec 7-8 — each tentative until confirmed at the preceding meeting, per the Fed's own note. **Provenance honesty:** the two in-window dates are cross-confirmed against federalreserve.gov and multiple independent secondary sources and are (C). The 2027 list did not re-render cleanly from the Fed's own page in this run's extract and rests on secondary aggregation — carried at **(2S)**, adequate for 6-month context and not adequate to trade from.

### 1B.2 — Earnings inside the 45-day window

Thirty-seven distinct US-listed names have a scheduled report inside the window. The full dated list is in PART 1A.1 below and is not duplicated here.

**A provenance warning that binds every one of these rows, and it is a strategy-level requirement rather than a preference.** Strategy C requires a **"confirmed date from company IR."** Every earnings date in this file's bulk table came from the FMP `earnings-calendar` endpoint, which mixes company-confirmed and vendor-projected dates and **exposes no flag distinguishing them**. They are therefore carried at **(E)**, not (C). That is sufficient to RANK a candidate here; it is **not** sufficient to enter one. Any C earnings thesis must have its date re-confirmed against the company's own IR page at D2 thesis-construction time, and this file does not discharge that obligation for it.

One row in the vendor pull is rejected outright rather than carried:

- **FDX appears TWICE — 2026-09-17 and 2026-10-28 — and the second date is almost certainly a vendor artifact.** FedEx's fiscal Q1 ends in August and reports in September; fiscal Q2 ends in November and reports in December. **2026-10-28 corresponds to no FedEx quarter-end.** The 09-17 row is consistent with the fiscal calendar and is carried; the 10-28 row is marked **(T) — REJECTED AS SUSPECT** and is excluded from both shortlists. It is named here rather than silently dropped so a later cycle does not "rediscover" it as a gap. Confirming it is impossible from this plan tier: `calendar/earnings-company` is ACCESS DENIED, so there is no per-symbol route to check a bulk row against.

### 1B.3 — FDA PDUFA target action dates

Rows marked CARRIED come from last cycle's 1B.3/1B.4 with their original sourcing intact — **prior-cycle research, not re-verified this run.** Rows marked NEW were sourced this run.

| PDUFA date | Ticker | Drug / indication | Provenance | C-eligible? |
|---|---|---|---|---|
| 2026-09-19 | RARE | UX111, Sanfilippo A | CARRIED | cap near floor; C has no cap rail, options liquidity is the binding test |
| 2026-09-23 | GRAL | Galleri **AdCom panel** | CARRIED | **NO — an advisory-committee vote is not a PDUFA action date.** Excluded at the strategy level |
| 2026-09-26 | MIRM | Zilurgisertib, FOP | CARRIED (resolves this run's MIRM-vs-INCY ambiguity in favour of MIRM) | yes |
| 2026-09-28 | BFRI | Ameluz PDT, sBCC (sNDA) | NEW | nominally yes; micro-cap, options chain likely unusable |
| 2026-09-30 | SRRK | Apitegromab, SMA (BLA) | NEW + CARRIED (agree) | yes |
| 2026-09-30 | BMY | Camzyos, adolescent oHCM (sNDA) | CARRIED (2S) | yes |
| 2026-10-04 | MRK | Welireg + Lenvima, advanced RCC | CARRIED | yes |
| 2026-10-09 | RHHBY | Tecentriq, colon cancer | CARRIED | **NO — ADR, fails the US-listed test** |
| 2026-10-10 | MRK | Ifinatamab deruxtecan, ES-SCLC | CARRIED | yes |
| 2026-10-15 | RHHBY | Enspryng, thyroid eye disease | CARRIED | **NO — ADR** |
| 2026-10-17 | VTRS | MR-141, presbyopia (sNDA) | CARRIED | yes |
| 2026-10-24 | PHAR | Joenja | CARRIED (lighter verification) | yes |
| 2026-10-26 | GSK | Bepirovirsen, hepatitis B | CARRIED + corroborated this run | **NO — ADR** |

**STRUCK THIS RUN — and it is a correction to this file's own prior cycle, not a vendor problem.** Last cycle's table carried a row reading *"GSK zidesamtinib — approved 2026-07-22"*, while this run's fresh aggregator pull independently returned *"NUVL zidesamtinib — PDUFA 2026-09-18, pending."* Same drug, different company, incompatible status; both could not stand. Resolved against the FDA's own approvals page and Nuvalent's IR: **zidesamtinib is Nuvalent's (NUVL), brand name Jideytro, and the FDA approved it on 2026-07-22 — roughly two months AHEAD of its 2026-09-18 PDUFA target.** So **each input was half wrong**: the prior cycle had the date and status right and the company wrong; the fresh aggregator had the company right and was serving a stale, superseded PDUFA date. **The row is struck — it is not a forward catalyst, and NUVL must not appear as a pending PDUFA in this or any later window.** Sources: [FDA approvals page](https://www.fda.gov/drugs/resources-information-approved-drugs/fda-approves-zidesamtinib-ros1-positive-non-small-cell-lung-cancer), [Nuvalent IR](https://investors.nuvalent.com/2025-11-19-Nuvalent-Announces-FDA-Acceptance-of-New-Drug-Application-for-Zidesamtinib-for-the-Treatment-of-TKI-Pre-treated-Patients-with-Advanced-ROS1-positive-NSCLC).

**NOW PAST (was in last cycle's pending list):** TLX / Pixclara, 2026-09-11 — falls before this window opens. **Whether it actually resolved is not established here**; D1's 2026-09-10 file still had it pending and Friday 09-11 is the session no W1 can see (above). Tonight's D1 owns it.

**OUT OF WINDOW:** PRAX / relutrigine → 2026-12-27 (extended); CAPR / deramiocel → 2026-11-22 (extended); INO / INO-3107 → 2026-10-30 (just past the 10-28 boundary, first-party 8-K corroborated this run); Beren / adrabetadex → 2026-11-17; SVRA / Molbreevi → 2026-11-22.

**ALREADY RESOLVED before the window:** PTGX/TAK rusfertide (08-28), ROIV brepocitinib (08-26), IONS zilganersen (09-03), NUVL zidesamtinib (07-22, above).

**COMPLETENESS CAVEAT — this PDUFA table is a FLOOR, not a total, and the October half is the thin part.** The FDA publishes no forward PDUFA calendar (it cannot confirm an application exists until the sponsor discloses it), so every row here originates in a third-party tracker or a company release. A dedicated follow-up pass spending its full budget on the 2026-10-01 → 10-28 sub-window closed **zero** new rows beyond the carry-forward, while aggregators claim on the order of a hundred Sept+Oct catalysts sitewide. The honest reading is that in-window October coverage is incomplete and cannot be shown to be complete from the sources reachable at this spend level.

## PART 2A — Strategy A preliminary ranked shortlist (50 candidates)

### A-QUEUE CENSUS — the pinned query, run verbatim

The spec pins this and the pin exists because W1 got it wrong: last cycle's file stated the A queue "currently holds 23 pending A rows" and enumerated 23 tickers where the true figure was 39, an undercount that makes an already-queued name read as NEW. Run as pinned — `SELECT * FROM state.open_queue WHERE strategy = 'A'` — the query returns:

> **40 rows.**

That is the census. It is 39 plus **FSLR**, added by W4 on 2026-09-06 after last cycle's W1 had already written. Enumerated, all 40:

`AAPL · ADBE · AKAM · AMAT · AMD · AMZN · AVGO · CAT · CRM · CRWD · CSCO · DDOG · DELL · FSLR · GEV · GOOGL · HD · HPE · IBM · INTC · INTU · LLY · META · MRVL · MSFT · MU · NBIS · NOW · NTAP · NVDA · OKTA · ORCL · PANW · QCOM · SMCI · SNOW · TGT · TTWO · VRTX · WMT`

The hand enumeration agrees with the query at 40. **One reconcilable discrepancy is stated rather than smoothed over:** `Watchlist.md`'s Strategy A queue table carries **41** ticker rows — the 40 above plus **TSM**. TSM is not in the live queue because it is an ADR and therefore not Strategy-A-eligible; the markdown table is a historical audit trail and does not delete rows, so the two are expected to differ by exactly this kind of row. **The query wins: the census is 40.**

### MODE — read this before reading the ranking

Strategy A is **DO-NOT-ACTIVATE and capital-disabled**, for a fourth consecutive cycle, and as of 2026-09-10 its technical leg fails too (SPY_TREND NEUTRAL). **No name below can produce a position this cycle.** W4 section D routes A top-tier names to `Watchlist.md` under the router gate rather than enqueueing thesis-construction, so the downstream work is correctly gated already.

That W1 has no explicit INDEX MODE limb for this situation — where W2's PART 2 gained one on 2026-08-24 after three router-gated cycles — is a **known, recorded finding**: `ops.alerts` `06520989`, raised by W1 itself on 2026-09-06, owned to W5. **It is not re-raised here.** Its `consecutive_gated_cycles` payload field read 3 when it was written and the true figure is now 4; that is an update to an open finding, not a new finding, and this file is the place to say so. The shortlist below is produced at the depth the spec specifies, because the spec specifies it.

### THE DIRECTION RAIL, APPLIED FIRST

Strategy A is **long-only** — `strategy/03_strategy_a.md`: *"Long-only (no short positions in A — short is B's territory)."* Per this section's DIRECTION ADMISSIBILITY rule, hypothesized direction is evaluated **before** ranking, and any candidate whose thesis is that the name is **over**-valued is marked `DIRECTION-INADMISSIBLE (A long-only rail)` and placed **below** the actionable tier regardless of how strong the narrative is. It is a category error, not a judgment call.

**This cycle the rail costs more than it usually does, and that is worth saying plainly: the single best new idea in this window is inadmissible.** Brent rose **+11.79% in four sessions** (96.28 → 107.63). The three US carriers reporting inside the window — **DAL 10-08, UAL 10-21, AAL 10-22** — face a fuel-cost shock arriving after their hedge books were set, with a dated print to mark it against. That is a specific, quantified, dated, documentable divergence, and it is **a short thesis, so Strategy A cannot use it at any conviction.** It is ranked, carried, and routed below — to Strategy B's sub-pattern taxonomy, which is where short-direction theses belong. Suppressing it would lose real signal; admitting it to the actionable tier would consume a thesis slot that cannot produce a position.

### TOP-10 — the actionable tier (all long-direction, rail-checked)

Per candidate: (a) hypothesized direction · (b) supporting public documents · (c) catalyst date · (d) overlap with open A positions / watchlist · (e) tier.

**There are ZERO open Strategy A positions.** The entire open book is 12 Strategy D lots (AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER), so for every candidate below, (d) reduces to queue membership and, for five names, co-existence with a D lot. That is noted per row rather than repeated.

**Rail status for the names below, stated once.** Every shortlisted name was measured against the **ADV rail and passes** (1A.3a; the lowest in the whole measured set is ~18x the floor). The **cap rail is MEASURED only for names inside the vendor allow-list**; queue-only names are **CAP-UNVERIFIED** because `batch-market-cap` silently omits them and the single-symbol endpoint is denied (finding F-4). Where such a name is treated as clearing $2B that is a labelled **inference** from its dollar-volume magnitude, not a measurement. **One name is explicitly flagged for re-measurement before any use: SRPT, carried at ~$2.14B, sits directly on the floor.**

| # | Ticker | (a) Direction | (c) Catalyst date | (d) Overlap | Thesis seam in one line |
|---|---|---|---|---|---|
| 1 | **XOM** | Bullish | Q3 earnings **2026-10-30 (E)** | not queued; no A position | Brent +11.79% in four sessions while XLE **fell 0.58%** on the session Brent rose 6.34% — the tape is pricing demand destruction, the upstream realization arithmetic in the 10-Q is not |
| 2 | **CVX** | Bullish | Q3 earnings **2026-10-30 (E)** | not queued | Same seam, higher post-Hess upstream leverage; second independent instance rather than a duplicate |
| 3 | **GEV** | Bullish | Q3 earnings **~2026-10-20 (T — company-unconfirmed, flagged "soft" in `Watchlist.md`)** | queued 2026-08-09; **also an open D lot** (`D:GEV:2026-08-03`) | Data-centre power capex; an energy shock raises the option value of gas-turbine and grid capex rather than lowering it. Prior cycle's #1, carried on its own rationale |
| 4 | **INTC** | Bullish | Q3 earnings **2026-10-22 (E)** | queued 2026-05-12 | Cap $519.2B. Sold off inside the 09-10 XLK −1.41% rate-duration move; the foundry/industrial-policy thesis is not a duration thesis, so the transmission channel and the thesis channel are different things |
| 5 | **JPM** | Bullish | Q3 earnings **2026-10-13 (E)**; Investor Day **2027-02-22 (C)** | not queued | XLF −1.38% on 09-08 as hike odds firmed, but a hike from 3.50–3.75% with a +0.39 curve is NIM-supportive for an asset-sensitive book. Consensus has been positioned for cuts since the June SEP |
| 6 | **GOOGL** | Bullish | Q3 earnings **2026-10-28 (E)**; ad-tech joint proposed Final Judgment **2026-10-02 (C)**; search-remedies reply brief **2026-09-29 (C)** | queued 2026-07-05; **also an open D lot** (×2) | The 2026-09-02 Brinkema ruling avoided a breakup; the residual legal tail became **quantifiable rather than binary**, and a quantifiable tail is what a narrative thesis can actually price |
| 7 | **TTWO** | Bullish | **GTA VI launch 2026-11-19 (C — re-verified first-party this run, no delay)**; pre-load 11-12 | queued 2026-08-09 | The single largest dated non-earnings binary in the entire calendar, and the date has now survived re-confirmation |
| 8 | **FSLR** | Bullish | **Section 232 regime effective 2026-12-04 (C, whitehouse.gov)** — polysilicon $21/kg, ingots/wafers $100/kg, cells $0.22/W, modules $0.38/W | queued 2026-09-06 (newest queue member) | A fully specified, quantified, dated policy catalyst — the rarest shape in this file. Confirmed unaffected by the 2026-02-20 SCOTUS IEEPA ruling, which struck a *different* tariff authority |
| 9 | **CAT** | Bullish | Q3 earnings **(T — no date in the reachable calendar)** | queued 2026-05-01, thesis ratified 2026-08-04 | Data-centre power capex plus energy-capex pull-through. **Ranked with its date weakness explicit** — an unconfirmed catalyst date is a real deduction, not a formality |
| 10 | **MRK** | Bullish | **Welireg+Lenvima RCC PDUFA 2026-10-04 (C)**; **I-DXd ES-SCLC BLA PDUFA 2026-10-10 (C)** | not queued | Two first-party-confirmed dated regulatory catalysts eight days apart, into a sector the tape just marked down (XLV −2.52% on 09-08 on an unrelated clinical cluster) |

**Why COP is not in the top-10, and the coverage hole it exposes.** A pure-play E&P is the highest-beta expression of the #1/#2 seam and on merit would rank near the top. It is held out because **the reachable calendar contains no independent E&P at all** — no COP, no EOG, no DVN, no FANG row exists in the 77-symbol pull — so its catalyst date is (T) and unverifiable at this plan tier. That is not a judgment that COP is unattractive; it is the vendor allow-list deciding the shortlist's composition, which is exactly the distortion the COVERAGE STATEMENT warns about. **Named here so the hole is visible rather than invisible.**

### 11–20

| # | Ticker | Direction | Catalyst date | Note |
|---|---|---|---|---|
| 11 | MSFT | Bullish | earnings 2026-10-28 (E); Ignite 11-17→11-20 (C) | queued 2026-07-05 |
| 12 | META | Bullish | earnings 2026-10-28 (E); Meta Connect 09-23→09-24 (C) | queued 2026-07-05; D1 logged +6.55% on 09-09 with no attributed event |
| 13 | AMZN | Bullish | earnings 2026-10-29 (E); re:Invent 11-30→12-04 (C) | queued 2026-07-12; **also an open D lot (×2)** |
| 14 | NVDA | Bullish | earnings 2026-11-18 (E); GTC Berlin 10-20→10-22 (E) | queued 2026-05-09; circular-financing objection still unresolved on the queue row |
| 15 | AMD | Contested (long) | earnings 2026-11-03 (E) | queued 2026-05-29 |
| 16 | UNH | Bullish | earnings 2026-10-27 (E); investor conference ~early Dec (E) | not queued; XLV weakness is the entry seam |
| 17 | VRTX | Bullish | **povetacicept BLA PDUFA 2026-11-30 (C)**; **Journavx CLBP sNDA PDUFA 2026-12-05 (2S)** | queued 2026-07-05; two dated regulatory catalysts, both beyond the earnings horizon and neither dependent on it |
| 18 | CSCO | Bullish | earnings 2026-11-11 (E) | queued 2026-05-09 |
| 19 | UBER | Contested (long) | earnings 2026-11-03 (E) | queued? no — **not on the A queue**; restructuring announced 2026-09-02 (~3,300 roles, ~10%); **also an open D lot** |
| 20 | GE | Bullish | earnings 2026-10-20 (E) | not queued; aero + power capex, energy-linked |

### 21–50 — the rest tier

Ranked, long-direction, all rail-checked. `q` = on the A queue.

21 **BAC** (10-14, E) · 22 **GS** (10-13, E) · 23 **C** (10-13, E) · 24 **WFC** (10-13, E) — the NIM seam at #5, three further instances plus the money-centre peer; ranked below JPM on balance-sheet mix rather than on thesis.
25 **V** (10-27, E; DOJ fact discovery closes 2026-10-16 (C)) · 26 **ORCL** q (AI World 10-25→10-28 (C); reported 09-10, reaction session unobserved) · 27 **CRM** q (Dreamforce 09-15→09-17 (C)) · 28 **NOW** q (T) · 29 **INTU** q (**Investor Day 2026-09-17 (C)** — the nearest dated catalyst on the whole queue) · 30 **WDAY** (**Financial Analyst Day 2026-10-13 (C)**).
31 **MU** q (T) · 32 **AVGO** q (T) · 33 **MRVL** q (T) · 34 **QCOM** q (T) · 35 **DELL** q (T) · 36 **SNOW** q (T) · 37 **CRWD** q (T) · 38 **PANW** q (T) · 39 **NBIS** q (T) · 40 **SMCI** q (T).
41 **HPE** q (T) · 42 **IBM** q (T) · 43 **OKTA** q (T) · 44 **DDOG** q (T) · 45 **NTAP** q (T) · 46 **AAPL** q (10-29, E) · 47 **LLY** q (T; a Strategy D re-screen is due 2026-09-14) · 48 **BMY** (**Camzyos adolescent oHCM PDUFA 2026-09-30 (2S)**) · 49 **ON** (**Financial Analyst Day 2026-09-16 (C)**) · 50 **BA** (10-28, E; 737 MAX 10 FAA certification "by year-end 2026" (T)).

**Ranks 31–45 are queue-carried names whose catalyst dates fall in the unreachable tail.** They are ranked on carried thesis strength, not on catalyst proximity, and that is stated because the ranking would look different if their dates were knowable. This is the horizon constraint showing up as a *ranking* distortion rather than as a missing row, which is the harder form to notice.

### DIRECTION-INADMISSIBLE — ranked, carried, and ineligible for the actionable tier

`DIRECTION-INADMISSIBLE (A long-only rail)`. These are **not** rejected candidates — they are genuine evidence for the divergence record and for Strategy B, which is where short-direction theses belong.

| Ticker | Direction | Catalyst date | Why it is real, and why A cannot use it |
|---|---|---|---|
| **DAL** | **Bearish** | earnings **2026-10-08 (E)** | Brent +11.79% in four sessions, arriving after the hedge book was set, with a dated print to mark it against. **The strongest new thesis in this cycle's file** |
| **UAL** | **Bearish** | earnings **2026-10-21 (E)** | Same shock, same window, independent print |
| **AAL** | **Bearish** | earnings **2026-10-22 (E)** | Same shock; thinnest balance sheet of the three, so the highest sensitivity — and consensus already models a loss (−$0.32 EPS) |
| **CCL** | **Bearish** | earnings **2026-10-05 (E)** | Bunker-fuel channel of the identical shock; first of the fuel-exposed names to report |
| **AMAT** | Bearish | (T) | China WFE cliff; carried, and re-affirmed bearish this cycle rather than inherited |
| **AKAM** | Bearish / contested | (T) | Carried |
| **WMT** | Bearish | 2026-11-19 (E) | Carried; two adverse datapoints since the original bullish tariff-pass-through framing |
| **ADBE** | Bearish — **vindicated on the tape this week** | **2026-12-09 (E)** — the horizon-edge row | Creative Cloud deceleration. Reported 09-10 AMC with a **CEO transition announced**, and D1 recorded the 09-10 move as pre-print drift rather than the reaction. **MEASURED off the 2026-09-11 IBKR bar the warehouse has not ingested: ADBE −11.73% on the week.** That is the reaction, and it is sharply negative. **A confirmed-correct short thesis is still a short thesis** — this makes the direction call better evidenced, not admissible |
| **HD** | Bearish / neutral | (T) | Housing-turnover starvation; carried |

**TGT — direction UNRESOLVED, held below the actionable tier.** Carried into this cycle bearish, but the prior print was a beat-and-raise that refuted the bearish thesis on its own terms, and no replacement direction has been established. **An unresolved direction is not a long direction**, so it does not enter the actionable tier by default; it is held here until a cycle establishes a direction either way. Catalyst: earnings 2026-11-18 (E).

## PART 2B — Strategy C preliminary ranked shortlist (15 event candidates)

### THE TWO CONSTRAINTS THAT DECIDE THIS WHOLE SECTION, AND THEY POINT AT DISJOINT SETS

**Constraint 1 — routing.** C is **HYBRID ACTIVATE (FOMC-only)**. Only FOMC events are router-eligible; every earnings and PDUFA candidate below is ranked but **router-parked**. Widening past FOMC-only is procedurally unreachable through a divergence review — `Strategy.md` reserves it to a separate scope-widening adjudication whose conditions (≥5 closed FOMC trades, or portfolio ≳$25k) are unmet, and none is open.

**Constraint 2 — size, and it is smaller than it looks.** MEASURED this run from `state.strategy_nomadic_status`: **Strategy C's NAV is $23.64.** Idle capital $23.64, deployed $0.00, zero open positions, `capital_enabled = TRUE`, `is_nomadic = TRUE`. Account NAV is $15,629.21, of which $15,088.25 is the SGOV park and **$15,368.39 of strategy NAV sits with Strategy E — which is capital-DISABLED as of 2026-09-04.** So the one strategy permitted to deploy capital has **$23.64** to deploy. (The capital-debt side of this is already carried at `ops.alerts` `regime_restore_shortfall`, warning, 2026-09-07 — debtor strategies A, B and D against an empty enabled-donor set. **Not re-raised here.**)

**Put the two together and this cycle's central finding falls out of the arithmetic.** A $23.64 budget admits only the cheapest **debit** structures — D2 priced six of them at $5–$65/contract on 2026-09-08 and recorded criterion 4 (executability) as PASSING, so this is not a mechanics failure. A debit structure is **long premium**, and long premium needs implied vol to be **cheap relative to realized**.

MEASURED across the 33-name panel (IBKR RTH bars dated 2026-09-11; ATM IV from the first listed expiry strictly after each event): **exactly two names have implied below realized — PYPL (IV/HV20 0.68) and F (0.83). Both are earnings events, which the FOMC-only router forbids.** Every router-eligible candidate — both FOMC dates — sits on the *rich* side, where the measurable edge favours **selling** premium, which $23.64 cannot collateralise.

**The affordability constraint and the routing constraint select disjoint sets.** That is the structural reason criterion 2 has now failed on six consecutive drains, and it is not a judgment any single drain got wrong. It is recorded at `ops.alerts` `strategy_c_criterion2_unreached_pattern` (info, 2026-09-08, owned to W5) — **not re-raised here**, but this run supplies the mechanism that entry only named as a pattern.

### Method for the ranking

Ranked by the measured divergence between the options market's implied view and realized behaviour. **(e) is uniform and therefore stated once: there are ZERO open Strategy A positions, so the A/C simultaneous-holding prohibition binds no candidate below.** (d) is per-row. Every IV figure is MEASURED from IBKR; every HV and ratio is INFERRED from measured closes by sample stdev of log returns × √252.

### TOP-5

| # | Event | Date | (a) Hypothesized divergence | IV / HV20 | (d) Executable at $23.64? | Router |
|---|---|---|---|---|---|---|
| 1 | **FOMC** | **2026-09-16** (SEP + presser) | **NO VIEW TAKEN on direction.** The measurable leg is premium, and it points against the only affordable structure: SPY ATM IV **11.72%** (09-17 expiry, strike 764) vs HV10 **10.00%** and HV20 **8.74%** | **1.34** (IV/HV10 1.17) | Structures buildable; **the measurable edge runs against every affordable one** | **ELIGIBLE** |
| 2 | **FOMC** | **2026-10-28** (presser, no SEP) | Not yet measurable — the governing expiry is not the one quoted above | n/a | **NOT ENTERABLE TODAY — see the tenor note below** | **ELIGIBLE (from 2026-09-15)** |
| 3 | **PYPL** | 2026-10-27 earnings **(E)** | Implied materially **CHEAPER** than realized — ATM IV 40.04% against HV10 **80.94%** and HV20 58.69%. The only row in the panel where the gap is large and in the direction a debit structure wants | **0.68** (IV/HV10 **0.49**) | Affordable in principle; **router-parked, so moot** | parked |
| 4 | **F** | 2026-10-22 earnings **(E)** | Implied below realized — ATM IV 33.55% vs HV20 40.41%. Second and only other such row | **0.83** | Affordable; **router-parked** | parked |
| 5 | **AAL** | 2026-10-22 earnings **(E)** | **Richest premium in the panel** — ATM IV 46.83% vs HV20 26.48%. Consistent with the Brent +11.79% fuel shock being priced into the option surface ahead of the print | **1.77** | A credit structure is indicated and **$23.64 cannot collateralise one**; **router-parked** | parked |

**Tenor note on candidate 2, and it is a real rail rather than a formality.** Strategy C requires the structure's **expiration within 1–45 days of entry**, with the event strictly before expiration. The first listed expiry after 2026-10-28 is 2026-10-30, which is **47 days from today** — **outside the rail, so the October FOMC is NOT enterable on today's date.** It comes inside the rail from **2026-09-15**, when 10-30 falls at 45 days. It is ranked at #2 rather than deferred out because a two-day wait is a scheduling fact, not a disqualification — but a thesis dated today would be inadmissible on tenor alone, and that is the kind of error worth pre-empting.

### REST (6–15), by measured IV/HV20 descending — all router-parked

| # | Ticker | Event date (E) | ATM IV | HV20 | IV/HV20 |
|---|---|---|---|---|---|
| 6 | GOOGL | 2026-10-28 | 33.74% | 19.36 | 1.74 |
| 7 | JPM | 2026-10-13 | 24.21% | 14.50 | 1.67 |
| 8 | VZ | 2026-10-20 | 23.34% | 14.50 | 1.61 |
| 9 | BAC | 2026-10-14 | 25.22% | 15.79 | 1.60 |
| 10 | NKE | 2026-10-01 | 49.64% | 31.26 | 1.59 |
| 11 | CCL | 2026-10-05 | 45.10% | 29.00 | 1.56 |
| 12 | GM | 2026-10-20 | 37.81% | 25.39 | 1.49 |
| 13 | BA | 2026-10-28 | 32.95% | 22.47 | 1.47 |
| 14 | MSFT | 2026-10-28 | 31.20% | 21.78 | 1.43 |
| 15 | T | 2026-10-21 | 27.22% | 19.27 | 1.41 |

The spec caps this shortlist at 10–15 candidates and it is held to **exactly 15**; the measured panel was **33 names**, and the remainder (DAL 1.40, PEP 1.40, C 1.40, COST 1.38, GS 1.31, WFC 1.31, UAL 1.27, NFLX 1.23, META 1.17, KO 1.16, V 1.14, INTC 1.13, JNJ 1.08, GE 1.04, HCA 1.04, LMT 1.02) is in PART 1B's universe rather than promoted into a shortlist the spec does not size for.

**Three names returned no IV and are excluded from the ranking rather than estimated into it:** **FDX**, **UNH** and **TSLA**. In each case both the ATM call and the ATM put returned `is_valid:false` from IBKR after a retry and a cross-check on the opposite leg. HV was measured cleanly for all three; only the option leg failed. **No IV was estimated for any of them** — an unavailable quote is reported as unavailable.

**One measurement-method caveat worth recording, because it would silently corrupt this table if inherited.** IBKR's `option_midpoint_iv` field returned an identical invalid sentinel — `annualIv = -15.874507866387544`, `isValid: false` — on **every contract tried, across every ticker and strike**. It is not a per-name data gap; the field is unusable wholesale at present. The IV figures above come from the `implied_vol` market-data field instead, which returned valid contract-specific quotes for 30 of 33 names. A future cycle that reads `option_midpoint_iv` and does not check `isValid` would ingest a **negative** volatility as a number.

### PDUFA candidates — carried, unmeasured, and honestly so

The in-window PDUFA events from PART 1B.3 (MIRM 09-26, BFRI 09-28, SRRK 09-30, BMY 09-30, MRK 10-04, MRK 10-10, VTRS 10-17, PHAR 10-24, RARE 09-19) are **not ranked above**, because no IV was measured for any of them this run. They are router-parked regardless, so a measurement would not have changed a disposition this cycle. **Stated rather than omitted:** their absence from the ranking is an unmeasured gap, not a judgment that their premium is uninteresting, and a cycle in which C's router widens would need to measure them before ranking.

## OUT-OF-SCOPE FINDINGS — RECORDED, NOT REPAIRED

W1 does not own any of the surfaces below. Each is recorded with its owning routine named, per this run's standing instruction, and none is repaired here.

**F-1 · The Friday blind spot is structural, and W1's spec does not contemplate it.** `ops.alerts` info, category `w1_daily_boundary_excludes_friday_session`, owner: W5 SPEC-DEFECT NOTICE INTAKE (the `Claude_Task_Plan.md` W1 section). MEASURED from `ops/routine_backup.json`: W1's trigger is `30 7 * * 0` and D1's is `0 22 * * 0,1,2,3,4`, so every W1 run executes **14.5 hours before** the D1 fire that will first cover the preceding Friday session. The DAILY-TO-WEEKLY BOUNDARY paragraph instructs W1 to reuse D1's records and provides an escape hatch only for "D1 itself is genuinely unavailable" — which is not this case and never will be. The gap is guaranteed by trigger ordering, recurs weekly, and this cycle covered the ADBE and ORCL earnings reaction sessions and the August CPI print. **It is a narrative gap only: the price half is closeable for free off IBKR bars, as this run did.**

**F-2 · `option_midpoint_iv` returns an invalid negative sentinel across every contract on the IBKR connector.** `ops.alerts` info, category `ibkr_option_midpoint_iv_invalid_sentinel`, owner: OPS1 (the connector manifest, `ops/connector_tools.yaml`), with D2's options-pricing path as the consumer at risk. MEASURED across every ticker and strike attempted in a 33-name sweep this run: the field returns `annualIv = -15.874507866387544` with `isValid: false`, identically, wholesale — not a per-name data gap. The usable field is `implied_vol`, which returned valid contract-specific quotes for 30 of 33 names. **The hazard is specific: a consumer that reads `option_midpoint_iv` without checking `isValid` ingests a NEGATIVE implied volatility as a number**, and Strategy C's entire entry test is an implied-versus-realized comparison.

**F-4 · FMP `batch-market-cap` SILENTLY OMITS symbols outside the plan's covered set instead of erroring.** `ops.alerts` info, category `fmp_batch_market_cap_silently_omits_symbols`, owner: OPS1 (`ops/connector_tools.yaml`, the FMP tool record), with W1/W2/W3 and any universe-screening step as consumers at risk. MEASURED by direct probe this run, in three steps: a 77-symbol request (all inside the forward-calendar allow-list) returned **77 of 77**; a 47-symbol request of A-queue and energy names returned **8 of 47**, and those 8 were exactly the ones that also appear in the calendar allow-list; the single-symbol `company/market-cap` endpoint returned **ACCESS DENIED**. **The 39 omitted symbols produced no error, no warning and no null row — they were simply absent from the response.**

This is the same failure shape as the already-open `treasury_range_call_silently_truncates` finding on a different FMP endpoint, and it is more dangerous here because the natural use is a screen: a caller that passes N symbols, receives M < N, and does not diff the two lists will either read the omitted names as having no market cap, or will believe a universe screen covered N names when it covered M. **This run wrote a paragraph asserting the generalisation before probing it, and the probe falsified it** — which is precisely how a consumer would get this wrong. Recorded rather than repaired; the prior finding `6c4004e3` should be read as amended by it rather than replaced.

**F-3 · The A-router gating count on an already-open finding is now 4, not 3.** No new alert. `ops.alerts` `06520989` (`w1_part2a_no_router_aware_mode`, info, 2026-09-06, owned to W5) carries `consecutive_gated_cycles: 3` in its payload; with this cycle it is **4**. That is an update to an open finding, not a new finding, and re-raising it would mint a second row for one condition — the exact alarm-fatigue failure the message-literal rules exist to prevent. Recorded here instead.

### CHECKED AND FOUND NOT TO BE A DEFECT — recorded so it is not re-raised

**N-1 · The 2026-09-08 Strategy B handoff was NOT dropped.** An intermediate reading of this run's own evidence suggested it had been: D1's 2026-09-08 single-name screen names seven names clearing Strategy B's frozen Entry criterion 1 (NVS, ROIV, GPCR, AMGN, INTC, BKNG, QBTS, each `qualifying_event_date` 2026-09-08); **no `action-conversion` row exists in `events.decision_log` for 2026-09-08 at all**, while 09-09 and 09-10 both have one; and none of those names appears in `Watchlist.md`'s Strategy B index under that event date. Against the convention that a router-gated candidate still earns an index-only add, that reads exactly like a silent drop.

**It is not one, and the primary source says so in terms.** D1's own entry (`a4ce03b2`) states: *"None is routed as a thesis handoff because state.current_regime STRATEGY_ACTIVATION B reads DO-NOT-ACTIVATE and B holds no capital. The identities are preserved here so a later session can pick any of them up without re-deriving them."* That is a **deliberate, stated, reasoned decision with the identities durably preserved**, not an omission. The inference was drawn from the absence of a record and was refuted by reading the record; it is written up here because an inference from absence is the highest-risk kind and the next cycle to notice the same shaped hole should not spend the work again.

The one genuine residue is a **convention inconsistency, not a defect**: D1 declined to route on 09-08 while D2 made router-gated index-only adds on 09-09 and 09-10. Nothing was lost either way — the 09-08 identities are recoverable from `a4ce03b2` — so it is noted and not escalated.

**N-2 · The fleet did not stall on 2026-09-11/12.** `ops.run_log` holds 26 rows across 13 routines for each of 09-09 and 09-10 and **zero rows for 09-11 and 09-12**, which reads as a two-day outage. It is not: the daily fleet's monitor class is `daily_sun_thu`, documented in `ops/cadence.yaml` as "every Sunday-Thursday calendar day, NOT Friday/Saturday"; `state.fleet_blackout_days` returns zero rows; and no `missed_run` / `routine_stalled` / `staleness` / `missing_dependency` / `trading_halted` alert has been raised since 2026-09-08. **Nothing is late and nothing is owed.** Recorded because the raw table is genuinely misleading on first read and a future session will read it the same way.

## Method and coverage notes

**What was measured, and with what.** BigQuery (`state.*`, `events.*`, `ops.*`) and the IBKR connector are free and unmetered and did the great majority of the work here: the regime and routing reads, the A-queue census, the capital state, every close, every realized-volatility figure and every option implied-volatility quote. Metered spend went to two places only — the FMP forward earnings calendar and market caps, and a small amount of web research for the FOMC and PDUFA calendars, which no structured connector on this plan holds.

**Metered calls this run: 34 in total** — **15 FMP** (9 date-sliced `earnings-calendar` pulls, 1 `splits-calendar`, 1 `ipos-calendar` returning ACCESS DENIED, 1 screener probe, 2 `batch-market-cap`, 1 single-symbol `market-cap` returning ACCESS DENIED), **16 `WebSearch`**, and **3 Tavily `tavily_extract`** at basic depth (~3 credits). **`tavily_research` was not used and was explicitly forbidden to every sub-agent** — it is the 4–250-credit tail risk in the pricing table and no question here was open-ended enough to warrant it. Against the FMP free-tier daily cap of 250, this run consumed 15 (~6%). One `ops.web_calls` row is written per call.

Three of those calls were spent on things that returned no data and were worth spending anyway: the two ACCESS DENIED probes fixed the boundary of what this plan reaches, and the 47-symbol `batch-market-cap` probe is what falsified a generalisation this file had already drafted (finding F-4).

**Sub-agent fan-out obeyed the one-shared-pull rule.** Five Sonnet sub-agents ran. The earnings calendar and the market-cap batch — the only datasets identical for every agent — were pulled **once**, by a single designated agent that was told it held the sole FMP budget, and every other agent was explicitly forbidden from calling FMP at all. The measurement agents (liquidity, options) were confined to IBKR and BigQuery, which are free, so fan-out multiplied compute and not spend. Each agent carried a stated call budget and an instruction to report a completeness caveat on exhaustion rather than discover the ceiling by hitting it; two did exactly that and their caveats are carried verbatim above rather than smoothed away.

**Where sub-agent output was overridden.** Two sub-agent conclusions did not survive verification against primary sources and are corrected rather than inherited:
- A reported "dropped Strategy B handoff" on 2026-09-08 was **refuted** by reading D1's own entry, which records a deliberate, reasoned decision not to route (finding N-1).
- A fresh PDUFA pull reported NUVL/zidesamtinib as pending on 2026-09-18; the FDA's own approvals page shows it **approved 2026-07-22** (PART 1B.3). The prior cycle's contradicting row was also wrong, on a different field.

Both are noted because a fan-out architecture makes it cheap to generate confident claims and no cheaper to check them; the checking is the orchestrator's job and it changed two answers here.

**The three standing constraints, restated so no reader mistakes a floor for a total.**
1. **The Strategy A universe cannot be enumerated** on this FMP tier — screener, directory and batch-quote endpoints are all ACCESS DENIED. Every count in PART 1A is a floor over a reachable population of 77 vendor-listed symbols plus the queue, not the universe the strategy defines. **Newly measured this run:** `batch-market-cap` is *not* gated and returns caps for all 77 in one call, so the $2B rail is mechanically checkable for a candidate list even though the universe is not listable. The denial is of *enumeration*, not of *rail-checking* — those are different things and the distinction was not previously recorded.
2. **The confirmed-earnings horizon is 2026-12-09**, 87 days out, unchanged in substance from last cycle's 88. The final ~13 weeks of the 6-month window — the January-to-March FY-report cluster — cannot be filled from any bulk source, and the historical fallback is refused outright, so ranks 31–45 of the A shortlist are ranked on carried thesis strength rather than catalyst proximity. That is the horizon showing up as a **ranking distortion** rather than as a missing row, which is the harder form to see.
3. **The in-window PDUFA table is incomplete and provably so.** The FDA publishes no forward PDUFA calendar. A follow-up pass spending its full budget on 2026-10-01 → 10-28 closed zero new rows while aggregators claim ~100 Sept+Oct catalysts sitewide.

**Carry-forward provenance.** The four non-earnings tables in PART 1A are largely carried from the 2026-09-06 file with their original sourcing intact. Carried rows were re-classified against this cycle's window but **not re-verified against their primary sources**, and each is labelled CARRIED for that reason. Three rows were re-checked or recovered this run and are labelled NEW: the GTA VI date (re-confirmed, no delay), the VRTX Journavx PDUFA (recovered from `Watchlist.md`, absent from last cycle's regulatory table), and the SCOTUS IEEPA ruling (confirmed already-resolved and confirmed *not* to touch FSLR's Section 232 row, which rests on separate statutory authority).

**What this file deliberately did not do.** It did not re-run D1's announcement search for any catalyst D1 already owns; it did not spend a metered call on the Friday session, whose forward-calendar content is nil and whose tape was recoverable free; it did not raise a fresh alert for the earnings horizon, the enumeration gate, or the A-router gating count, all of which are already open findings; and it did not construct a thesis for any candidate — full thesis construction per `Strategy.md` happens in separate D2 sessions scheduled by W4, and nothing here is a thesis.
