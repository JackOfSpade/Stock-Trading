2026-10

# Monthly D Position Deep-Dive — October 2026 cycle (review window 2026-09-01 → 2026-10-01)

**IMMEDIATE-ACTION flag: NONE.** No D position shows material thesis invalidation. Across **8 names and 12 tranches** there are **34 at-entry criteria** (AMZN 5, GOOGL 5, DIS 5, RTX 6, UBER 4, ISRG 4, TSM 3, GEV 2). **Zero are breached.**

**All eight recommendations are HOLD.** There are no exits, no completions and no "further research" deferrals. **No quarterly print fell inside this window for any of the eight names.** The Q3 round starts on 2026-10-15 with TSM and finishes around mid-November with DIS. Most quarterly criteria are therefore **NOT ENGAGED** this cycle (no new data), and carry their last measured reading. That is a property of the calendar, not a gap in coverage. The event-driven criteria were searched for this month.

The month's substantive outputs:

1. **The breach-status backfill is done (F-17).** Seven legacy tranches still read `breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`. All seven now carry an affirmative assessment of **UNBREACHED**, written append-only to `events.position_events`. The criteria text is byte-identical. D1's add-candidate HARD GATE can now evaluate all 12 tranches, including ISRG, RTX and UBER, which it has had to decline since 2026-09-06.
2. **The only unscheduled structural risk in the book came off (GOOGL c4).** On 2026-09-02 the E.D. Va. ad-tech remedies decision **rejected divestiture of AdX and DFP** and imposed behavioral remedies only.
3. **A rates shock is new context (F-16), not a trigger.** The Fed hiked on 2026-09-16. The 10Y went from **4.75% to 5.29%** and the 2Y from 4.34% to 4.88%, so the curve's level shifted up about 54bp with its slope unchanged. SPY trend slipped to NEUTRAL and breadth fell to WEAK (40.55%). None of this is an invalidation criterion for any name. It does matter as **router context**: last month's D divergence review rested partly on "the long-rate transmission channel did not move." It has now moved.

---

## Span covered

`state.routine_catchup_window` gives M3 `window_start_ts` = 2026-09-01 15:28 UTC (M3's own last completion) and `window_days = 29.98`. That is cadence-normal: no monthly cycle was missed, no catch-up sub-sections are owed, and no `CATCHUP[...]` token is due. The research window is **2026-09-01 → 2026-10-01**.

**Same-day double-run guard: clear.** `ops.run_log` had 0 `completed` and no in-flight M3 row for 2026-10-01 before work began.

**Scope is roster-derived.** In `strategy/roster.yaml`, A, B, C and E are `reactive` and **D alone is `long_horizon`**. Scope is exactly D, unchanged.

---

## Book state

**The book is unchanged: 8 names, 12 tranches, no opens or closes in the window.** `state.current_positions` holds 12 rows, all Strategy D.

| Name | Tranches | Shares | Cost basis | Mark (09-30) | Market value | Unrealized | % of D NAV | Recommendation |
|---|---|---|---|---|---|---|---|---|
| **GEV** | 1 (08-03) | 0.1244 | $120.656 | $950.49 | $118.241 | −$2.415 (−2.00%) | 21.52% | HOLD |
| **GOOGL** | 2 (07-09, 07-26) | 0.2577 | $87.823 | $344.08 | $88.670 | +$0.847 (+0.96%) | 16.14% | HOLD |
| **AMZN** | 2 (07-09, 07-30) | 0.3464 | $88.237 | $249.15 | $86.306 | −$1.931 (−2.19%) | 15.71% | HOLD |
| **DIS** | 2 (05-07, 08-05) | 0.7244 | $77.308 | $104.90 | $75.990 | −$1.318 (−1.70%) | 13.83% | HOLD |
| **TSM** | 2 (07-21, 07-29) | 0.1550 | $64.013 | $456.19 | $70.710 | +$6.697 (+10.46%) | 12.87% | HOLD |
| **ISRG** | 1 (07-20) | 0.1091 | $38.132 | $406.63 | $44.363 | +$6.232 (+16.34%) | 8.08% | HOLD |
| **UBER** | 1 (07-09) | 0.5156 | $37.746 | $68.51 | $35.324 | −$2.422 (−6.42%) | 6.43% | HOLD |
| **RTX** | 1 (04-27) | 0.1601 | $28.321 | $185.65 | $29.723 | +$1.401 (+4.95%) | 5.41% | HOLD |
| **Total** | **12** | — | **$542.237** | — | **$549.327** | **+$7.090 (+1.31%)** | **100.0%** | — |

*Marks are the 2026-09-30 closes in `events.daily_marks` (source `connector`, i.e. the IBKR connector, ingested by D2a). Cost basis is the ledger figure from `state.current_positions` (shares × fill + commission). Market value totals $549.327. That reconciles to the cent with `analytics.strategy_nav.deployed_mv` of $549.32 and gives `nav` $549.33 (deposits $524.78 + realized $16.58 + unrealized $7.09 + dividends $0.88), with `available_funds` $0.00. D is still capital-disabled and swept to zero idle cash, so "% of D NAV" is effectively "% of the deployed book" (F-12).*

**Per-tranche detail** (cost per share is cost basis ÷ shares, commission-inclusive):

| Tranche | Cost/sh | Unrealized | LTCG date | Days to LTCG |
|---|---|---|---|---|
| D:RTX:2026-04-27 | $176.90 | +4.95% | 2027-04-27 | 208 |
| D:DIS:2026-05-07 | $111.32 | −5.77% | 2027-05-08 | 219 |
| D:AMZN:2026-07-09 | $241.24 | +3.28% | 2027-07-09 | 281 |
| D:GOOGL:2026-07-09 | $359.85 | −4.38% | 2027-07-09 | 281 |
| D:UBER:2026-07-09 | $73.21 | −6.42% | 2027-07-09 | 281 |
| D:ISRG:2026-07-20 | $349.51 | +16.34% | 2027-07-20 | 292 |
| D:TSM:2026-07-21 | $427.86 | +6.62% | 2027-07-21 | 293 |
| D:GOOGL:2026-07-26 | $327.84 | +4.95% | 2027-07-27 | 299 |
| D:TSM:2026-07-29 | $392.88 | +16.11% | 2027-07-30 | 302 |
| D:AMZN:2026-07-30 | $265.69 | −6.23% | 2027-07-31 | 303 |
| D:GEV:2026-08-03 | $969.91 | −2.00% | 2027-08-04 | 307 |
| D:DIS:2026-08-05 | $103.79 | +1.07% | 2027-08-06 | 309 |

**D engine state (informational; not exit-triggering).** Values are from `perf.strategy_daily` / `perf.kill_flags` as of 2026-09-30:

- `deployed_unit_value` **1.070179**, up from 1.061062 a month ago.
- `peak_unit_value` 1.098110 and `current_drawdown` **−2.54%**, an improvement on −3.37%.
- `excess_vs_sgov` **+5.38%**, up from +4.80%.
- `deployed_days` 109, `closed_trades` 1, `gate_n` 29.
- **All kill flags are FALSE:** `drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `gate_reached` and `interim_underperf_warning`.
- **New this cycle: `beta_min_n_met` flipped to TRUE.** The engine now treats its beta/alpha estimate as usable: `beta_hat` **0.942**, `alpha_annualized` **+21.8%**.

That alpha figure needs two caveats before anyone reads anything into it. (a) It comes from ~109 deployed days on a book whose largest single contributor was one post-earnings gap (AMZN +15.3% on 2026-07-31). (b) The 24-month edge-decay test fires only when the alpha point estimate is ≤ −3pp **and** the 95% upper CI bound is ≤ 0pp. `perf.kill_flags` exposes no CI field, so the CI leg was **not measured** here. The estimate is far on the favourable side of the decay test, which is all this cycle can say.

**Regime and router state (informational; does NOT alter disposition).**

- **Binding activation state is DO-NOT-ACTIVATE.** It was re-held on 2026-09-03 by `div-D-202608-1` (`events.regime_events` `2ac50b53`). That review was *not* a clean ratification: it adopted two attacker Tier 1 findings, and it held state partly because "the long-rate transmission channel did not move (10Y flat at 4.75)". **That premise no longer holds (F-16).** D remains `capital_disabled`. C (HYBRID, FOMC-only) is now the only capital-enabled strategy after E went DNA on 2026-09-03.
- **Technical signals (D2a 2026-09-30, mechanical):**
  - SPY_TREND is **NEUTRAL**: close 762.63 sits 0.11 below the 50d SMA of 762.74. It flipped from UP on 09-30 after earlier NEUTRAL readings on 09-15/16.
  - SUSTAINED_INVERSION is **NOT-SUSTAINED** (10Y 5.29 vs 2Y 4.88, +0.41).
  - VIX_REGIME is **NORMAL** (16.34).
  - EQUITY_BREADTH is **WEAK** (40.55%, down from 66.2% on 08-31).
  - D's technical rule (SPY UP or NEUTRAL, and inversion NOT-SUSTAINED) still reads ACTIVATE, but only just.
- **This changes no disposition below.** Strategy D's rule is explicit: "router deactivation does not force exits on existing D positions." Every recommendation here is criterion-driven.

---

## Cross-cutting findings

Numbering continues the prior series. F-16 and F-17 are new. F-12, F-9, F-7, F-13, F-14, F-5 and F-1 are updated. F-15 closes.

### F-17 (NEW). The breach-status backfill is complete, and D1's add gate can now see every tranche

**What was owed.** Since 2026-09-27 this routine owns a duty, assigned by W5 when it adjudicated D1's `add_gate_uncovered_breach_status` (alert `3daf511e`, commit `2edc774`). The duty: write a fresh breach assessment for every open D tranche whose `invalidation_status.$.breach_status` reads `NOT_ASSESSED_BY_THIS_BACKFILL`. That marker came from the 2026-07-30 `bigquery/117` mirror, which transcribed criteria verbatim and deliberately assessed nothing. Seven tranches still carried it: `D:AMZN:2026-07-09`, `D:DIS:2026-05-07`, `D:GOOGL:2026-07-09`, `D:ISRG:2026-07-20`, `D:RTX:2026-04-27`, `D:TSM:2026-07-21` and `D:UBER:2026-07-09`. Three of them (ISRG, RTX, UBER) have no later sibling tranche carrying a fresh assessment. D1 had therefore declined all three at the HARD GATE on every sweep since 2026-09-06, on missing breach status alone.

**What was written.** Seven append-only `ADJUST` rows were inserted into `events.position_events`, one per tranche (`numDmlAffectedRows = 7`). Each row:

- echoes every column of the current row forward unchanged: shares, cost basis, LTCG date, conviction, model, `source_thesis_ref`;
- leaves the `invalidation_1..N` criteria keys **byte-identical**, never re-derived or re-stamped, because criteria are immutable for a position's life;
- changes only `breach_status` → `UNBREACHED`;
- adds `breach_assessed_on` (2026-10-01), `breach_assessed_by` (M3 plus session) and a per-criterion `breach_assessment` string. Each criterion in that string carries its last measured reading and source, matching the tables below.

Read-back confirms the change in `state.current_positions`: **0 of 12 tranches** still read `NOT_ASSESSED_BY_THIS_BACKFILL`, and `invalidation_1` text matches on all seven.

**What this does and does not do.**

- **It does not loosen the gate.** The gate is fail-closed, and that remains correct. It now has an affirmative assessment to read.
- **It is not a standing pass.** The assessment is dated. Next month's cycle re-assesses against the Q3 prints.
- **D1 will still not stage anything for these names.** It flags add *candidates*, which D2 thesis-constructs. While D is DO-NOT-ACTIVATE and capital-disabled, no add can be funded, as D1's own 2026-09-01 sweep recorded ("declined on fundability, not merit").

The practical effect is that D1's `invalidation_criteria_evaluable` field now reads TRUE for all 12 tranches, so its add-sweep record is no longer structurally blind to three names.

### F-16 (NEW). A rates shock moved the one channel D's divergence review said had not moved

**Measured** (`events.regime_events`, D2a's pinned FMP treasury-rates read):

| Date | 10Y | 2Y-10Y spread |
|---|---|---|
| 08-31 | 4.75 | +0.41 |
| 09-08 | 4.80 | +0.41 |
| 09-15 | 5.00 | +0.33 |
| 09-22 | 4.96 | +0.25 |
| 09-29 | 5.26 | +0.37 |
| 09-30 | **5.29** | +0.41 |

The 2026-09-30 close at 5.29% is independently corroborated by a secondary source (CNBC 2026-09-30, and a market brief reporting a cross above 5.30% intraday). The **Fed hiked at its 2026-09-16 meeting** (D1 park-allocation entry `d5709d26`). Across the window, equity breadth fell from 66.2% to 40.55% and SPY trend wobbled between UP and NEUTRAL.

**Why it is written down here.** `div-D-202608-1` (2026-09-03) held D at DO-NOT-ACTIVATE and listed as one of its reasons that "the long-rate transmission channel did not move (10Y flat at 4.75)". The channel has now moved about 54bp, and in the direction that **supports** the DNA call: a higher discount rate is the textbook headwind for multi-year equity theses. This finding does not argue for or against activation. That is M1b's call and the divergence review's, made this month on M1a's fresh scoring. It records that one stated premise of the last review is stale, so the next review does not inherit it.

**Not exit-triggering, for any position.** No D thesis carries a rate-level criterion. Strategy D's "Not exit-triggering" list explicitly covers "macro environment shifts that don't invalidate the specific structural drivers." The book's deployed TWR in fact **rose** in the window (unit value 1.061 → 1.070) despite the move.

**Routing:** M4 and M1b should carry this as context. No queue item or alert is owed. M1a/M1b read the rates series directly.

### F-12 (updated). Sector-cap denominator artifact: adjudicated, caveat landed, artifact unchanged

The prior cycle's `sector_cap_denominator_artifact` (alert `b1e69e7c`) was **resolved by W5 as FIX** (commit `4c8d06d`). W5 re-verified that Entry criterion 5 is entry-scoped and that D's exit rules carry no sector-cap trigger. It also caught the one live consumer this file had missed: **Q2 PART 2's concentration check**, which treats a sector-cap breach as blocking. Q2 now carries a caveat to read `state.strategy_capital_enablement` / `state.regime_capital_debt` before treating such a breach as real. Q2 runs about 2026-10-02, while D is still capital-disabled, so that caveat is live on schedule.

**Today's reading, on market value / cost against D NAV of $549.33:**

- **Industrials** (GEV, UBER, RTX): **33.37% / 33.99%**
- **Communication Services** (GOOGL, DIS): **29.97% / 30.06%**
- Consumer Discretionary (AMZN): 15.71%
- Information Technology (TSM): 12.87%
- Health Care (ISRG): 8.08%

Communication Services now sits right on the line: just under 30% at market and just over at cost. The difference is DIS's −1.7% move, not any book change. **The adjudication is unchanged:** no exit is triggered or available, nothing is blocked (D is DNA and capital-disabled), and the reading reverses mechanically when the sweep debt is restored on re-activation. Nothing is owed.

### F-9 (carried, updated). The AI-capex cluster is 66% of the book and still invisible to every control

AMZN + GOOGL + TSM (compute) plus GEV (power) hold **$363.93 of $549.33 market value, or 66.2%**, up from 64.5%. The four names sit in four different GICS sectors, so the sector cap cannot see them. No invalidation criterion in any of the four names AI-capex intensity, FCF, ROIC or cross-position correlation. TSM's c3 is a single-name structural test.

This cycle adds one data point **against** the cohort risk materialising: TSM's August revenue was **+53.3% YoY**, the strongest month of the year (6-K, 2026-09-10). It adds one data point that **sharpens** its financing side: Amazon raised **£4.25B of sterling notes** in September (8-K 2026-09-14), continuing debt-funded capex. Neither changes the posture. The concentration is recorded for future thesis construction and is not actionable against open positions. See F-7 for the correlation read.

### F-7 (updated). Correlation recompute

This is the monthly post-entry recompute that Entry criterion 5 (rev 28) requires. **Source:** IBKR `get_price_history`, one call per contract ID (never batched, the documented mitigation for the series-swap defect), `ONE_YEAR` / `ONE_DAY`, regular trading hours only. All 8 returned 251 bars with identical date sets. The in-progress 2026-10-01 bar was dropped. **Common window: 2025-10-02 → 2026-09-30, 250 closes, n = 249 returns on all 28 pairs.**

Every series' 2026-09-30 close matched the `events.daily_marks` connector close exactly, so no series swap occurred. `events.daily_marks` itself could not serve as the source because it holds only ~41–114 sessions per name.

Pearson correlation of daily simple returns:

```
         AMZN     DIS     GEV   GOOGL    ISRG     RTX     TSM    UBER
  AMZN  1.000   0.192   0.196   0.537   0.251   0.071   0.298   0.280
   DIS  0.192   1.000  -0.076   0.221   0.296   0.105   0.075   0.302
   GEV  0.196  -0.076   1.000   0.185   0.068   0.164   0.614  -0.029
 GOOGL  0.537   0.221   0.185   1.000   0.296   0.078   0.318   0.276
  ISRG  0.251   0.296   0.068   0.296   1.000   0.197   0.116   0.239
   RTX  0.071   0.105   0.164   0.078   0.197   1.000   0.029   0.084
   TSM  0.298   0.075   0.614   0.318   0.116   0.029   1.000   0.201
  UBER  0.280   0.302  -0.029   0.276   0.239   0.084   0.201   1.000
```

- **Above the 0.6 entry-time bucket threshold: GEV–TSM at 0.614.** It was 0.587 two cycles ago and 0.599 last cycle, and has now crossed the line on a third consecutive rise. **Under rev 35 bucket membership is informational only**, neither capped nor entry-blocking, so no consequence follows. D is also DNA, so there is no entry it could gate anyway.
- **Above the 0.7 post-entry emergent threshold: none.**
- Second-highest is **AMZN–GOOGL at 0.537**, up from 0.504. The two top pairs are both cross-sector AI-capex pairs, which is F-9 seen through the correlation lens. The mean pairwise correlation is ~0.19.

**Caveats, stated.**

- At n = 249 the 95% CI half-width on r is about ±0.06–0.07. So "0.614 > 0.6" is a crossing in point estimate, not a statistically distinguishable change from last month's 0.599. The informative fact is the **direction**: three consecutive rises.
- The window still contains outsized earnings gaps: AMZN +15.3% (07-31), GEV +15.6% (2025-12-10) and +13.7% (04-22), and ISRG −14.1% (07-17) and +13.9% (2025-10-22).
- Daily Pearson says nothing about tail co-movement.
- **Process caveat:** the sub-agent transcribed the closes from tool output into a script by hand, and rebuilt the date index from an NYSE calendar rather than from the returned timestamps. The calendar gave 251 sessions, matching all 8 series. Every series' final close matched an independent source exactly, which bounds but does not eliminate transcription risk on interior values.

### F-13 / F-14 (carried). Criteria that fire on lumpy inputs, and criteria drifting toward untestability

No new realized data point this cycle; both stand as written last month.

- **F-13** (D's two realized observations both show bare thresholds firing on lumpy quarterly series): calibration input for future thesis construction only.
- **F-14** has two items:
  - **UBER c2:** Uber states Adjusted EBITDA "is no longer a key measure". c4's metric-immutability covers Gross Bookings only, so an Adjusted EBITDA phase-out would leave c2 unmeasurable with no auto-invalidation. This was confirmed this month: no Uber filing in the window changed any disclosure. **First live test: the Q3 print, ~2026-10-29 / 11-03.**
  - **DIS c4:** the Consumer-Products-into-Entertainment reclassification takes effect with fiscal 2027 reporting. First test is the ~Feb 2027 Q1 FY27 report; the earliest possible auto-invalidation is ~May 2027.

  A reminder carried from last cycle: the "current form" of SVOD operating income is the 8-K Ex-99.1 supplemental table, **not** the 10-Q segment footnote.

### F-15 — CLOSED, and adopted in practice this cycle

`fmp_tier_fallback_not_default` (alert `9b39f1da`) was **resolved by W5 as FIX** on 2026-09-14. The shared extraction-discipline section now says to go to SEC EDGAR or issuer IR **first** for filing, transcript and news content. **This cycle made zero FMP calls**: every research pass went straight to `data.sec.gov` / EDGAR / issuer IR and free web search, and none spent a metered call rediscovering a denial. The prior cycle's repeated waste did not recur.

### F-5 (updated). Source reliability this cycle

Stated, in the same spirit as prior cycles:

1. **This month's evidence is thinner than last month's, by design and by calendar.** With no quarterly print in the window, research was a filings-and-events sweep. It used 40 free web/EDGAR calls across four sub-agents plus one corroboration search, and zero Tavily or FMP. Every "no 8-K / no filing in window" statement rests on the **primary** EDGAR submissions feed for that issuer. Event facts are mostly **secondary** (trade press, issuer press-release headlines), and are labelled per position below.
2. **The GOOGL ad-tech ruling is from two trade-press summaries** (AdExchanger, PPC Land). The 106-page opinion itself was not read. The direction of the ruling is not in doubt across both sources, but the precise remedy list should be read from the opinion or final judgment before any future thesis relies on it.
3. **Two internal date discrepancies, unreconciled and immaterial:**
   - GEV's CFO-succession 8-K is dated 2026-08-27 on the EDGAR submissions feed, against 08-25 in the prior file.
   - Uber's Delivery Hero tender: the prior file has an 08-27 offer document, while secondary sources say "launched 2026-09-18".

   Neither touches a criterion.
4. **Sub-agent call timestamps are approximate.** Sub-agents do not report per-call clock times. The `ops.web_calls` rows for this run therefore carry `call_ts` values spread across each sub-agent's measured run window, which is accurate to about a minute but not per call.

### F-1 (carried). Completion-criteria gap for legacy positions: unchanged

Only **GEV** carries a testable completion criterion. The other seven can exit on failure but not on success, and criteria are immutable. RTX remains the live illustration: its first GTF Advantage-powered aircraft was delivered on 2026-09-24, another milestone reached early, with still no completion mechanism. Recorded, not actionable.

---

## Per-position deep-dives

Each section covers the six required items: (1) thesis status, (2) driver check, (3) fundamental developments, (4) invalidation check, (5) sector and theme, and (6) tax. Status vocabulary for criteria: **UNBREACHED** means the last measurement does not meet the trigger. **NOT ENGAGED** means no new data point arrived in the window. A criterion can be both: not engaged this month, unbreached on its last reading.

### GEV — GE Vernova · 1 tranche · HOLD

**Thesis (Subtype B):** total-company organic orders growth continues; the gas turbine / grid super-cycle driven by AI-datacenter and electrification power demand. **Status: intact.**

**Developments in window:**

- **EDGAR shows no GEV filing at all** between 2026-09-01 and 2026-10-01. The newest is the 2026-08-27 CFO-succession 8-K. Source: `data.sec.gov` submissions, primary.
- **2026-09-16, Morgan Stanley Laguna conference** (secondary, search snippet; transcript not read). CEO Strazik said GEV is accelerating gas power capacity additions by ~50% this year. He reiterated **≥125 GW of gas turbine orders plus slot reservations by YE2026** (116 GW at Q2).
- **2026-09-23:** rotor life-extension services deal on five 9F units in Egypt. Immaterial.
- **Theme:** coverage of multi-year turbine wait times driven by AI power demand continued (Washington Times, 2026-09-30, secondary).

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| Inv | Organic orders growth YoY < 15% for 2 consecutive Q | No | **UNBREACHED** (not engaged) | Last +88% (Q2'26), +71% (Q1'26); 0 of 2 |
| Imm | Organic-orders disclosure lapses in comparable form 2 consecutive Q | No | **UNBREACHED** | No filing in window |
| Comp (i) | Backlog ≥ $200B | No | **NOT MET** | $176.3B at Q2'26. A Q3 step similar to Q2's +$13.0B would reach about $189B. *That is an inference, not a measurement.* |
| Comp (ii) | Trailing-4Q organic orders growth ≤ 25% for ≥ 1 Q | No | **NOT MET** | Trend is accelerating, away from the trigger |

**Drivers:** progressing (slot reservations, capacity expansion), with no evidence of stalling. **Sector:** AI power scarcity remains the dominant narrative; the rates move (F-16) is a valuation headwind, not a driver change. **Next test: Q3 print 2026-10-28.** **Tax:** LTCG 2027-08-04 (307 days). Completion is not near, so there is no LTCG coordination question.

**Recommendation: HOLD.** No criterion is engaged and neither completion leg is met. The mark is −2.0% against cost, which is short-term price action and explicitly not exit-triggering.

### GOOGL — Alphabet · 2 tranches · HOLD

**Thesis (Subtype B):** Google Cloud revenue growth, margin and backlog continue to compound; structural-remedy risk is bounded. **Status: intact, and the main tail risk receded.**

**Developments in window:**

- **2026-09-02, ad-tech remedies decision (E.D. Va., Judge Brinkema).** The court **rejected** the DOJ's AdX divestiture, the open-sourcing of DFP's final auction logic, and a contingent DFP divestiture. It ordered **behavioral remedies only**: Prebid integration, equal-terms AdX bidding into rival ad servers, bid-data sharing, a bar on AdWords bidding directly into DFP, and a six-year technical monitor applied globally. The court called structural remedies "neither realistic nor needed". The opinion was unsealed on 09-16, and the proposed joint final judgment is due 2026-10-02. Sources: AdExchanger and PPC Land, secondary; the opinion itself was not read.
- **Search case:** the D.C. Circuit appeal and DOJ cross-appeal (which seeks stronger remedies) are pending, and no argument date was found. Judge Mehta's remedies remain behavioral.
- **EDGAR shows only Forms 4 and 144 in the window,** with no 8-K and no 10-Q (primary).

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | Cloud rev YoY < 20% for 2 consecutive Q | No | **UNBREACHED** (not engaged) | +63% Q1'26, +81.8% Q2'26; 0 of 2 |
| 2 | Cloud op margin contracts 2 consecutive Q | No | **UNBREACHED** (not engaged) | 32.9% → 35.6%, expanding; 0 of 2 |
| 3 | Cloud RPO/backlog declines sequentially 2 consecutive Q | No | **UNBREACHED** (not engaged) | $513.9B Cloud RPO, rising; 0 of 2 |
| 4 | Adverse structural remedy | **Yes** | **UNBREACHED, with risk materially reduced** | Ad-tech court rejected divestiture (09-02); search remedies also behavioral. The residual path is the DOJ cross-appeal (no ruling, no date). |
| 5 | Cloud revenue reported comparably | No | **UNBREACHED** | No filing in window |

**Drivers:** no new measured data on Cloud, TPU or Gemini, so they are carried as progressing. **Sector:** regulatory overhang reduced; AI-capex-versus-monetisation scrutiny persists (F-9). **Next tests:** 2026-10-02 (ad-tech final-judgment proposal) and the Q3 print ~2026-10-27/28. **Tax:** LTCG 2027-07-09 and 2027-07-27.

**Recommendation: HOLD.**

### AMZN — Amazon · 2 tranches · HOLD

**Thesis (Subtype B):** AWS growth, margin and backlog compound, anchored by large AI-lab compute commitments. **Status: intact.**

**Developments in window** (EDGAR submissions feed, primary):

- 2026-09-09: 8-K Item 5.02, Kevin Mandia elected to the board. Governance only.
- 2026-09-09 to 09-24: a **£4.25B sterling notes offering** (2029/2032/2038/2045 maturities): underwriting 09-09, 8-K 09-14, listing 09-24. Use of proceeds was not read.
- Routine Forms 3/4.
- No 10-Q or earnings filing in the window.
- **Anthropic / OpenAI commitments:** no source found describing any reduction. Commentary (Motley Fool 09-06, secondary) restates Anthropic's >$100B AWS commitment. A 09-30 piece (The Register, secondary; body not read) concerns marketplace *distribution*, not compute commitments.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | AWS YoY < 18% for 2 consecutive Q | No | **UNBREACHED** (not engaged) | +37.0% Q2'26; 0 of 2 |
| 2 | AWS op margin < ~30% for 2 consecutive Q | No | **UNBREACHED** (not engaged) | 39.4%; 0 of 2 |
| 3 | AWS backlog declines sequentially 2 consecutive Q | No | **UNBREACHED** (not engaged) | $496B, primary-confirmed from the Q2 10-Q last cycle (that carry-forward is closed); 0 of 2 |
| 4 | Anthropic/OpenAI commitments renegotiated down or churned | Continuous | **UNBREACHED** | No evidence of reduction (secondary-only search) |
| 5 | AWS segment reporting restructures ≥ 2 Q | No | **UNBREACHED** | No filing |

**Drivers:** carried as progressing; no new measured data. **Sector:** debt-funded AI capex continues (F-9). **Next test:** Q3 print ~2026-10-29. Carried from last cycle and not re-verified: an EU DMA gatekeeper decision on AWS is expected around late October. **Tax:** LTCG 2027-07-09 and 2027-07-31.

**Recommendation: HOLD.**

### DIS — Walt Disney · 2 tranches · HOLD

**Thesis (Subtype B):** streaming profitability expansion, an EPS-growth framework and buyback execution. **Status: intact. A quiet month with no new fundamental information.**

**Developments in window:**

- **EDGAR shows only two Forms 4** (09-03, 09-25), with no 8-K and no 10-Q (primary).
- **FCC / ABC licences:** Disney's suit against the FCC's early-renewal order for 8 ABC stations has a court hearing set for **2026-10-06** (D.D.C.; scheduling order dated 08-20, secondary). The FCC has moved to dismiss.
- No FCC *final order* restricting station ownership was found. FCC press pages were not checked directly, so this is "not found", not "verified absent".
- No in-window buyback, guidance, segment-reporting or CEO-succession news was found. The absence of any 8-K is consistent with none being material.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | SVOD op margin < 8% for 2 consecutive Q | No | **UNBREACHED** (not engaged) | ~12.9% FQ3 FY26; 0 of 2 |
| 2 | FY26 adj EPS growth guide cut to ≤ 6% | No | **UNBREACHED** (not engaged) | ~12% reiterated at FQ3; no 8-K since |
| 3 | Buyback below run-rate, or a suspension 8-K | No | **UNBREACHED**: un-breachable for FY26 | 9-month $7,245M vs the ≤$5B Q3 floor; target ≥$9B; no 8-K of any kind in window |
| 4 | Metric-immutability (SVOD in current 8-K Ex-99.1 form) | No | **UNBREACHED** | Zero non-conforming quarters; first test ~Feb 2027 |
| 5 | ESCALATION: FCC final order **AND** a Disney material-adverse 8-K | Partial (litigation scheduling only) | **NOT ENGAGED** | Neither leg present |

**Drivers:** carried as progressing (SVOD margin 8.4% → 10.6% → ~12.9%). **Sector:** no in-window verification on parks or linear TV; no claim made. **Next tests:** 2026-10-06 FCC hearing, and the FQ4 FY26 print ~2026-11-12 (estimate, unconfirmed). **Tax:** LTCG 2027-05-08 (parent, 219 days) and 2027-08-06.

**Recommendation: HOLD.** c5 needs **both** legs, and neither exists. The 10-06 hearing alone cannot engage it.

### TSM — Taiwan Semiconductor · 2 tranches · HOLD

**Thesis:** AI-accelerator-driven leading-edge foundry demand, gross margin, node leadership (N2/A16) and CoWoS. **Status: intact and strengthening on the in-window proxy.**

**Developments in window:**

- **2026-09-10, August revenue NT$514.81B: +10.1% MoM and +53.3% YoY.** Year-to-date NT$3,386.87B, +39.3% YoY. Source: 6-K, `sec.gov` primary, matching the TSMC IR monthly-revenue page. This accelerates from July's +44.7%.
- **2026-09-02, Section 232 semiconductor tariff "Phase Two" confirmed** by the Commerce Secretary, with **no rates, product list or timeline**. The reported framework ties duty-free import quotas to US capacity (2.5× during construction, 1.5× once operational), which favours TSMC's Arizona build. Source: TechTimes, secondary. This is a watch item, not a criterion.
- No in-window hyperscaler or Nvidia order cut and no CoWoS utilization drop was found. The search was light: one query.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | GM < 55% OR USD rev YoY < 15%, 2 consecutive Q | Proxy only | **UNBREACHED** (not engaged) | Q2'26 GM 67.7%, USD rev +33.7%. NT$ monthly +53.3% is a proxy, **not** the specified USD-quarterly metric |
| 2 | N2/A16 ramp pushed out OR sub-7nm share declines 2 consecutive Q | No | **UNBREACHED** | No pushout in window; sub-7nm 77% and rising at last print |
| 3 | Structural AI-capex reset | Continuous | **UNBREACHED**: evidence points the other way | Monthly revenue accelerating; no order-cut evidence found |

**Drivers:** AI demand progressing; N2 ramp under way (Q3 GM guide 65–67% cites ramp costs; secondary, pre-window). **Sector:** tariff detail pending; Taiwan geopolitics was not searched this cycle. **Next tests:** September revenue ~2026-10-10, and the **Q3 print 2026-10-15**, the first full criterion test of the round. **Tax:** LTCG 2027-07-21 and 2027-07-30.

**Recommendation: HOLD.**

### ISRG — Intuitive Surgical · 1 tranche · HOLD

**Thesis:** da Vinci procedure growth, system placements and a recurring-revenue attach, against competitive entry. **Status: intact.**

**Developments in window:**

- **EDGAR shows only Forms 4 and 144** (primary).
- **2026-09-08:** an Annals of Surgery Open meta-analysis covering >14M procedures (da Vinci versus laparoscopy: lower conversion to open surgery, shorter stays). Secondary.
- EU label expansions (da Vinci SP transvaginal gynecology; da Vinci 5 adult cardiac). Secondary, exact dates not verified.
- **Competitors:** no disclosure of displacing da Vinci at a named large IDN. Only known early Hugo/Versius installations surfaced, and an early installer is not a displacement disclosure.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | Procedure growth < 10% YoY for 2 consecutive Q | No | **UNBREACHED** (not engaged) | +16% Q1'26, +15% Q2'26; 0 of 2 |
| 2 | Placements decline YoY for 2 consecutive Q | No | **UNBREACHED** (not engaged) | 431 vs 367; 468 vs 395; 0 of 2 |
| 3 | Recurring revenue decouples down from procedures | No | **UNBREACHED** | I&A +18% vs procedures +15% |
| 4 | Competitor displaces da Vinci at named large IDNs | Searched | **UNBREACHED** | No qualifying disclosure (not exhaustive: one competitor search plus last cycle's baseline) |

**Drivers:** adoption carried as progressing; label expansion and clinical evidence are mildly positive. **Next test:** Q3 print ~2026-10-20 (expected date, secondary). **Tax:** LTCG 2027-07-20 (292 days).

**Recommendation: HOLD.** The +16.3% mark is not a completion signal; ISRG has no completion criterion (F-1).

### UBER — Uber Technologies · 1 tranche · HOLD

**Thesis (Subtype B):** Gross Bookings growth, margin expansion and Uber One flywheel compounding. **Status: intact. Every September event was thesis-neutral to mildly positive; AV competition intensified.**

**Developments in window:**

- **2026-09-15:** 8-K (Items 8.01 and 9.01) plus Form 8-A registering **five senior note series** (2029–2046) on the NYSE. Source: `sec.gov`, primary. The purpose is likely Delivery Hero financing, but that is *an inference, not verified*.
- **2026-09-02:** Delivery Hero's board recommended Uber's €41.50/sh (~$14.8B) tender offer. Overlap businesses in 14 markets are to be sold to SSW Partners for $1.6B. Source: TechCrunch, secondary.
- **2026-09-02:** layoffs of ~10% of staff (~3,000–3,300), aimed at management layers. Secondary; no 8-K was filed.
- **AV competition:** Waymo launched Denver, San Diego and Tampa (14 US cities, 4,000+ vehicles). Tesla Cybercab opened to public riders in Austin. Reports say Uber may commit ~$10B to AV procurement and stakes (secondary, snippet only).
- No Item 2.02 filing and no Gross Bookings or Adjusted EBITDA disclosure change in the window.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | GB cc YoY < ~15% for 2 consecutive Q | No | **UNBREACHED** (not engaged) | +21% Q1'26, +22% Q2'26; Q3 guide 18–22% cc |
| 2 | Adj-EBITDA % of GB contracts YoY for 2 consecutive Q | No | **UNBREACHED** (not engaged) | +26bp, +40bp YoY. **Testability risk at Q3** (F-14) |
| 3 | Uber One membership stalls or declines sequentially | No | **UNBREACHED** | "Another all-time high" (Q2'26 CEO remarks). The raw count is not disclosed, so obtain it at Q3 if published |
| 4 | GB disclosure structurally changes | No | **UNBREACHED** | No change in window |

**Drivers:** flywheel carried as progressing. Layoffs are a margin tailwind. Delivery Hero adds scale and leverage. **Sector:** AV disruption risk rising, and it sits outside the four criteria as written. **Next tests:** Q3 print ~2026-10-29 / 11-03 (sources conflict); Delivery Hero acceptance period ends ~2026-11-05 (carried, not re-verified). **Tax:** LTCG 2027-07-09.

**Recommendation: HOLD.** The −6.4% mark is price action only.

### RTX — RTX Corporation · 1 tranche · HOLD

**Thesis:** commercial aerospace aftermarket and GTF fleet recovery plus a defense backlog. **Status: intact. The one new milestone is positive.**

**Developments in window:**

- **2026-09-15:** 8-K Item 5.02. Shane Eddy steps down as Pratt & Whitney president effective 2027-01-01 and is succeeded by Jill Albertelli (President, Military Engines). Filing confirmed on EDGAR (primary); detail is from a snippet.
- **2026-09-24: first GTF Advantage-powered A321XLR delivered to United.** P&W says the whole PW1100G-JM line moves to Advantage spec by 2028. Source: RTX newsroom, primary headline.
- **2026-09-02: FY27 continuing resolution (P.L. 119-103) signed.** It funds government at FY26 levels through 2026-12-11, with no new starts and no rate increases above FY26. Source: CRS, primary via summary.
- **2026-09-29:** RTX confirmed Q3 results for **2026-10-20** (primary).
- No Airbus damages ruling or settlement; no new quality event.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | Airbus damages ruling > $2B | Searched | **UNBREACHED** | No ruling or settlement; claim unquantified |
| 2 | New powder-metal-style quality event > $1B charge | Searched | **UNBREACHED** | Only in-window 8-K is a leadership change |
| 3 | GTF Advantage EIS slips beyond Q1'27 | **Yes** | **UNBREACHED**: affirmatively on schedule | First Advantage delivery 2026-09-24 |
| 4 | Backlog declines 2 consecutive Q | No | **UNBREACHED** (not engaged) | $289B Q2'26, +6% sequential |
| 5 | FY26 FCF guide < $7.5B | No | **UNBREACHED** (not engaged) | Guide $8.50–8.75B, no revision |
| 6 | FY27 defense procurement cut ≥ 10% YoY | **Yes** | **UNBREACHED** | The CR holds FY26 levels to 12-11. That is no cut, though it is not yet an enacted FY27 level |

**Drivers:** GTF fleet-durability fix progressing; defense demand intact. The CR's no-rate-increase clause is mild near-term friction, not a cut. **Watch:** CR expiry on 2026-12-11. A lapse or full-year bill is the next c6 data point. **Tax:** LTCG 2027-04-27 (208 days), the nearest in the book. **Separate trigger:** the falsifiable-milestone reassessment at Q1'27 earnings.

**Recommendation: HOLD.**

---

## Long-term tax treatment — full book

No tranche reaches LTCG inside the next quarter. The nearest are **RTX 2027-04-27 (208 days)** and **DIS parent 2027-05-08 (219 days)**. The other ten fall between 2027-07-09 and 2027-08-06. No position is near a completion or invalidation signal, so **no LTCG-timing coordination question arises.** Per Rev 39, exit timing is governed by thesis criteria alone, and there is no preference to delay an exit to qualify for LTCG. All 12 tranches carry a populated `ltcg_date`; the prior cycle's `D:DIS:2026-08-05` NULL was repaired by `bigquery/240`.

---

## Summary of recommendations

| Name | Recommendation | Basis | Next scheduled test |
|---|---|---|---|
| GEV | **HOLD** | 0 of 2 criteria breached; completion not met | Q3 print 2026-10-28 |
| GOOGL | **HOLD** | 0 of 5 breached; structural-remedy risk reduced (ad-tech ruling 09-02) | 10-02 final-judgment proposal; Q3 ~10-27/28 |
| AMZN | **HOLD** | 0 of 5 breached | Q3 ~10-29 |
| DIS | **HOLD** | 0 of 4 breached; escalation c5 not engaged | FCC hearing 10-06; FQ4 ~11-12 |
| TSM | **HOLD** | 0 of 3 breached; monthly revenue +53.3% YoY | Sept revenue ~10-10; Q3 10-15 |
| ISRG | **HOLD** | 0 of 4 breached | Q3 ~10-20 |
| UBER | **HOLD** | 0 of 4 breached; c2 testability risk at Q3 | Q3 ~10-29/11-03 |
| RTX | **HOLD** | 0 of 6 breached; GTF Advantage EIS on schedule | Q3 10-20; CR expiry 12-11 |

**For M4:** no exits to stage, no research deferrals to schedule, and no IMMEDIATE-ACTION flag. F-16 (rates) and F-12 (sector-cap artifact) are **context only**. Neither creates an action, and manufacturing one from either would be an error. October's Q3 print round is the dense test window: **all eight names report between 10-15 and ~11-12**, so next cycle's file will carry real criterion measurements for every quarterly criterion.

## Items owned by a routine other than M4's exit path

- **D1 (add-candidate HARD GATE):** all 12 tranches now carry an affirmative breach assessment (F-17). The ISRG/RTX/UBER structural ineligibility is cleared on the record side. Adds remain unfundable while D is DNA and capital-disabled.
- **M1b / next D divergence review:** `div-D-202608-1`'s "10Y flat" premise is stale (F-16).
- **Q2 (~2026-10-02):** apply W5's landed caveat to the sector-cap reading (F-12). Communication Services is now right at the 30% line on the artifact denominator.

## Method, and what this run did not do

- **Sources.** BigQuery for positions, engine, NAV, regime, decision log, queue and alerts. `events.daily_marks` for the 2026-09-30 connector closes. Four Sonnet research sub-agents ran on SEC EDGAR / `data.sec.gov`, issuer IR and free web search. One further sub-agent handled the IBKR price-history correlation recompute. The orchestrator made one corroborating web search on the 10Y close.
- **No FMP, no Tavily, no metered spend.** Every external call this run was on a free surface; the `ops.web_calls` rows are logged with `credits = 0`.
- **Writes.**
  - 7 `events.position_events` ADJUST rows (F-17).
  - This file.
  - `ops.run_log` start and end rows.
  - `ops.web_calls` telemetry.
- **Not done, deliberately:**
  - No order, queue item or calendar event (M3 stages nothing).
  - No re-derivation of any criterion.
  - The GOOGL ad-tech opinion was not read in full.
  - FCC press pages were not checked directly.
  - Taiwan geopolitics was not researched.
  - Uber Form 4 patterns were not analysed.
