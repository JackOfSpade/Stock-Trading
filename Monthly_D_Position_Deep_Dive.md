2026-11

# Monthly D Position Deep-Dive — November 2026 cycle (review window 2026-10-01 → 2026-11-01)

**IMMEDIATE-ACTION flag: NONE.** No D position shows material thesis invalidation. Across **8 names and 12 tranches** there are **34 at-entry criteria** (AMZN 5, GOOGL 5, DIS 5, RTX 6, UBER 4, ISRG 4, TSM 3, GEV 2). **Zero are breached.**

**All eight recommendations are HOLD.** There are no exits, no completions and no "further research" deferrals.

This was the dense test window that last month's file predicted. Six of the eight names printed Q3 inside the window:

| Name | Q3 report date |
|---|---|
| TSM | 10-15 |
| ISRG | 10-20 |
| RTX | 10-20 |
| GEV | 10-28 |
| GOOGL | 10-28 |
| AMZN | 10-29 |

Every quarterly criterion on those six now carries a fresh measurement, and every one reads further from its trigger than it did at entry. The two names that have not printed carry their last readings: UBER (Q3 expected ~11-03, unconfirmed) and DIS (FQ4 expected ~11-17, secondary).

The month's substantive outputs:

1. **The prints confirmed every Subtype B trend metric.**
   - GEV organic orders +96%.
   - GOOGL Cloud +103% at a 36.2% margin, with Cloud RPO $560.8B (+9.1% sequential).
   - AMZN AWS +39.3% at a 38.7% margin.
   - TSM USD revenue +41.2% at a 66.4% GM.
   - ISRG da Vinci procedures +14%, placements +28%.
   - RTX backlog $340B, with the FCF guide raised to $9.0–9.2B.
2. **The book still fell.** Deployed unit value went from 1.070 to 1.033 and drawdown from −2.5% to −6.7%. Three print-reaction drops drove most of the fall: GOOGL −12.6% on 10-29 on an EPS miss despite the Cloud beat, GEV −10.6% on 10-22, and TSM −5.9% on 10-30. Strategy D's rules are explicit that "short-term adverse price moves" and "quarterly results that don't bear on the multi-year thesis" are **not exit-triggering**. This file records the divergence between fundamentals and price; it does not act on it (F-19).
3. **GEV's first completion leg is within reach, but completion is not.** Backlog is $197B against the ≥$200B leg (i), and management expects it to cross $200B in Q4. Completion requires **both** legs. Leg (ii), trailing-4Q organic orders growth ≤25%, is moving the wrong way for completion: +71%, then +88%, then +96%. **No completion call is owed to M4** (F-1).
4. **The GOOGL episode that prompted Strategy.md Rev 55 is recorded against the measured segment data** (F-18). Search & other revenue grew **+12.0%** YoY in Q3, from the primary release. The Rev 55 rule is forward-only and changes nothing for the open GOOGL tranches.

---

## Span covered

`state.routine_catchup_window` gives M3 `window_start_ts` = 2026-10-01 14:28 UTC (M3's own last completion) and `window_days = 30.99`. That is cadence-normal: no monthly cycle was missed, no catch-up sub-sections are owed, and no `CATCHUP[...]` token is due. The research window is **2026-10-01 → 2026-11-01**.

**Same-day double-run guard: clear.** `ops.run_log` had no M3 row of any status for 2026-11-01 before work began.

**Scope is roster-derived.** In `strategy/roster.yaml`, A, B, C and E are `reactive` and **D alone is `long_horizon`**. Scope is exactly D, unchanged.

---

## Book state

**The book is unchanged: 8 names, 12 tranches, no opens or closes in the window.** `state.current_positions` holds 12 rows, all Strategy D.

| Name | Tranches | Shares | Cost basis | Mark (10-29) | Market value | Unrealized | % of D book | Month Δ mark | Recommendation |
|---|---|---|---|---|---|---|---|---|---|
| **GEV** | 1 (08-03) | 0.1244 | $120.656 | $887.85 | $110.449 | −$10.208 (−8.46%) | 20.84% | −6.6% | HOLD |
| **AMZN** | 2 (07-09, 07-30) | 0.3464 | $88.237 | $243.79 | $84.449 | −$3.788 (−4.29%) | 15.93% | −2.2% | HOLD |
| **DIS** | 2 (05-07, 08-05) | 0.7244 | $77.308 | $110.91 | $80.343 | +$3.035 (+3.93%) | 15.16% | +5.7% | HOLD |
| **GOOGL** | 2 (07-09, 07-26) | 0.2577 | $87.823 | $283.82 | $73.140 | −$14.683 (−16.72%) | 13.80% | −17.5% | HOLD |
| **TSM** | 2 (07-21, 07-29) | 0.1550 | $64.013 | $431.81 | $66.931 | +$2.917 (+4.56%) | 12.63% | −5.3% | HOLD |
| **ISRG** | 1 (07-20) | 0.1091 | $38.132 | $448.76 | $48.960 | +$10.828 (+28.40%) | 9.24% | +10.4% | HOLD |
| **UBER** | 1 (07-09) | 0.5156 | $37.746 | $65.74 | $33.896 | −$3.850 (−10.20%) | 6.39% | −4.0% | HOLD |
| **RTX** | 1 (04-27) | 0.1601 | $28.321 | $199.40 | $31.924 | +$3.602 (+12.72%) | 6.02% | +7.4% | HOLD |
| **Total** | **12** | — | **$542.237** | — | **$530.091** | **−$12.146 (−2.24%)** | **100.0%** | — | — |

**Mark source.** Marks are the 2026-10-29 closes in `events.daily_marks` (source `connector`, i.e. the IBKR connector). That is the latest ingested session: D2a runs Sun–Thu, so Friday 10-30 lands in tonight's run. Market value reconciles to the cent with `analytics.strategy_nav.deployed_mv` of **$530.09**. NAV is **$530.15**: deposits $524.78 + realized $16.58 + unrealized −$12.15 + dividends $0.94, with `available_funds` $0.06. D is still capital-disabled, so "% of D book" is effectively "% of D NAV" (F-12).

**Friday 10-30 closes (informational).** The 10-30 IBKR closes were read during the correlation pull and are not yet in the warehouse. They would put the book at **$518.17**:

| GEV | TSM | ISRG | AMZN | GOOGL | UBER | RTX | DIS |
|---|---|---|---|---|---|---|---|
| 857.87 (−3.4%) | 406.13 (−5.9%) | 432.01 (−3.7%) | 240.35 | 279.84 | 65.25 | 199.80 | 110.94 |

None of these changes any disposition.

**Per-tranche detail** (cost per share is cost basis ÷ shares, commission-inclusive; days to LTCG counted from 2026-11-01):

| Tranche | Cost/sh | Unrealized | LTCG date | Days to LTCG |
|---|---|---|---|---|
| D:RTX:2026-04-27 | $176.90 | +12.72% | 2027-04-27 | 177 |
| D:DIS:2026-05-07 | $111.32 | −0.37% | 2027-05-08 | 188 |
| D:AMZN:2026-07-09 | $241.24 | +1.06% | 2027-07-09 | 250 |
| D:GOOGL:2026-07-09 | $359.85 | −21.13% | 2027-07-09 | 250 |
| D:UBER:2026-07-09 | $73.21 | −10.20% | 2027-07-09 | 250 |
| D:ISRG:2026-07-20 | $349.51 | +28.40% | 2027-07-20 | 261 |
| D:TSM:2026-07-21 | $427.86 | +0.92% | 2027-07-21 | 262 |
| D:GOOGL:2026-07-26 | $327.84 | −13.43% | 2027-07-27 | 268 |
| D:TSM:2026-07-29 | $392.88 | +9.91% | 2027-07-30 | 271 |
| D:AMZN:2026-07-30 | $265.69 | −8.24% | 2027-07-31 | 272 |
| D:GEV:2026-08-03 | $969.91 | −8.46% | 2027-08-04 | 276 |
| D:DIS:2026-08-05 | $103.79 | +6.86% | 2027-08-06 | 278 |

These per-tranche unrealized figures match D1's 2026-10-29 add-candidate record (`1ec75295`) to the hundredth on all 12.

**D engine state (informational; not exit-triggering).** Values are from `perf.kill_flags` / `perf.strategy_daily` as of 2026-10-29:

| Field | 2026-10-29 | A month ago |
|---|---|---|
| `deployed_unit_value` | **1.032827** | 1.070179 (09-30); peak in window 1.074978 (10-14) |
| `peak_unit_value` | 1.106464 | — |
| `current_drawdown` | **−6.66%** | −2.54% |
| `excess_vs_sgov` | **+1.37%** | +5.38% |
| `beta_hat` | **1.330** | 0.942 |
| `alpha_annualized` | **−17.5%** | +21.8% |

`deployed_days` is 130, `closed_trades` 1 and `gate_n` 29. **All kill flags are FALSE**: `drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `gate_reached`, `interim_underperf_warning` and `evidence_kill`. `beta_min_n_met` is TRUE.

The alpha estimate swung **39 percentage points in one month**. That is the caveat last month's file attached to the +21.8% reading, now realized in the other direction (F-19).

**Regime and router state (informational; does NOT alter disposition).**

- **Binding activation state is DO-NOT-ACTIVATE.** It was re-held on 2026-10-06 by `div-D-202609-1` (`a6ae4e22`): "DNA now override-manufactured but the override still binds on current data". The `shock_overlay` axis has read **acute** on every M1a/M1R scoring in the window, through the 2026-11-01 scoring. D remains `capital_disabled`, and C is the only capital-enabled strategy.
- **Fundamental axes (2026-11-01 scoring):** stable growth, **reaccelerating** inflation (it was stable on 10-01 and 10-28), hawkish policy, neutral risk, acute shock.
- **Technical signals (D2a, 2026-10-29, mechanical):**
  - SPY_TREND is **UP** (769.36).
  - EQUITY_BREADTH is **HEALTHY** (63.81%, up from 40.55% on 09-30).
  - VIX_REGIME is **NORMAL** (17.20).
  - SUSTAINED_INVERSION is **NOT-SUSTAINED** (10Y 4.98 vs 2Y 4.61, +0.37).
  - D's technical rule reads ACTIVATE. The override, not the technical half, binds.
- **This changes no disposition below.** Strategy D's rule: "router deactivation does not force exits on existing D positions." Every recommendation here is criterion-driven.

---

## Cross-cutting findings

Numbering continues the prior series. F-18 and F-19 are new. F-1, F-5, F-7, F-9, F-12, F-13/F-14, F-16 and F-17 are updated.

### F-18 (NEW). GOOGL: the Rev 55 episode, recorded against the measured segment data

**What happened.** GOOGL fell **−12.6%** on 2026-10-29 (283.82 vs 324.89, IBKR) after its Q3 print, and a further −1.4% on 10-30. On 10-30 the owner, in an interactive session, adopted **Strategy.md Rev 55** (`eb85a625`). Under that rule, a D thesis constructed on or after 2026-10-30 must also carry a quantitative, falsifiable invalidation test on the issuer's dominant segment whenever that segment is not the thesis segment. The trigger was that both GOOGL tranches carry Cloud-only criteria, so "criteria unbreached" was a true statement while Search, the main line, was the news.

**What this cycle measured** (Alphabet Q3 8-K Ex. 99.1 and 10-Q, primary):

| Line | Q3'26 | Q3'25 | YoY |
|---|---|---|---|
| Google Search & other revenue | $63,350M | $56,567M | **+12.0%** |
| Consolidated revenue | $127.6B | — | +25% |
| Consolidated operating income | $40,576M | $31,228M | +30% |
| GAAP diluted EPS | **$2.12** | $2.87 | — |

- **The miss was at the EPS line.** Consensus was about $3.00 (secondary). The gap between rising operating income and falling EPS sits below the operating line, and this run did not identify its cause.
- **Capex** was $51.4B in the quarter against $24.0B a year earlier (primary). Free cash flow was reportedly −$9.1B (secondary).
- **The disclosure about AI summaries.** The sub-agent did **not** find language in the earnings release saying AI summaries / AI Overviews are hurting ad revenue. The release instead says Search query growth is at a five-year high. The language the owner directive cites may come from the call or the 10-Q MD&A, neither of which was read in full. This is recorded as **not located in the release**, which is different from **not said**. This file makes no correction to the owner directive's premise.

**What this means for the open GOOGL tranches: nothing mechanical.**

- Rev 55 is explicitly forward-only, and both tranches' criteria are immutable.
- On the reported segment data, Alphabet's dominant line **grew** +12% in the quarter the stock fell. The price reaction is the EPS/capex story.
- An M3 must not invent a Search criterion for an open position. The prospective-only rule forbids inventing or softening criteria, and that cuts both ways.

The thesis segment is stronger than at entry: Cloud +103% and Cloud RPO +9.1% sequential.

**Routing:** none. This is a record of the measured data behind an owner decision already taken. No queue item and no alert.

### F-19 (NEW). Fundamentals and price diverged hard this month; the engine's alpha estimate is not yet information

**The six Q3 prints all moved away from their invalidation thresholds** (per-position tables below). Over the same window:

- deployed unit value fell 1.070 → 1.033 (−3.5%);
- drawdown widened to −6.66%;
- `excess_vs_sgov` compressed from +5.38% to +1.37%;
- `alpha_annualized` flipped from +21.8% to −17.5%, with `beta_hat` at 1.33.

**The fall came almost entirely from print-reaction gaps:**

| Name | Date | Move | Context |
|---|---|---|---|
| GOOGL | 10-29 | −12.6% | Q3 EPS miss and capex, despite the Cloud beat |
| GEV | 10-22 | −10.6% | Pre-print, cause not identified this run (see the GEV section) |
| TSM | 10-30 | −5.9% | Unexplained this run |
| GEV | 10-30 | −3.4% | 887.85 → 857.87 (IBKR) |

The correlation sub-agent's summary listed this GEV move as −6.3%. Its own closes (887.85 → 857.87) give −3.4%, and the closes are what this file uses.

**Disposition is unaffected and must stay so.** These moves sit exactly on Strategy D's "Not exit-triggering" list, under short-term adverse price moves and results that don't bear on the multi-year thesis.

**The alpha caveat.** On 130 deployed days and one closed trade, `alpha_annualized` is a ±40pp-per-month quantity. The 24-month edge-decay test needs the point estimate ≤ −3pp **and** a 95% upper CI bound ≤ 0pp. `perf.kill_flags` exposes no CI field (the `bigquery/193` path computes it), and no flag fired. Last month this file warned against reading anything into +21.8%. The same warning applies to −17.5%.

**Routing:** M4 / M5 context only. No kill trigger fired, no queue item is owed, and `drawdown_kill` is FALSE.

### F-17 (updated). Breach-status backfill: zero backlog, duty discharged for this cycle

`state.current_positions` shows **0 of 12** tranches with `breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`. The seven written on 2026-10-01 read `UNBREACHED`. GEV, TSM:07-29, AMZN:07-30, GOOGL:07-26 and DIS:08-05 carry their own entry-time assessments. **No `events.position_events` write is owed this cycle, and none was made.** The duty covers only `NOT_ASSESSED_BY_THIS_BACKFILL` rows. Re-stamping the 10-01 assessments would add churn without changing the gate's input: every criterion still reads unbreached on this cycle's Q3 measurements, below.

D1's add-candidate HARD GATE has cleared all 12 tranches on every sweep since 2026-10-01 (`6a138b25` through `1ec75295`). Every flagged dip or strengthened-conviction trigger has been declined for lack of a funding path, not on merit.

### F-16 (updated). The 10Y shock partly reversed

The 10Y has come back down from last month's high. Readings below are from D2a's daily SUSTAINED_INVERSION rationale, using the FMP treasury-rates pinned read:

| Date | 10Y | 2Y | Spread |
|---|---|---|---|
| 09-30 | **5.29** | 4.88 | +0.41 |
| 10-15 | 5.10 | 4.77 | +0.33 |
| 10-22 | 4.96 | 4.65 | +0.31 |
| 10-29 | **4.98** | 4.61 | +0.37 |

That is about −31bp, giving back roughly 60% of September's +54bp. Last month's point stands in weakened form: `div-D-202608-1`'s "10Y flat at 4.75" premise was stale, and the 10-06 review (`div-D-202609-1`) was taken on post-shock data. The level is still about 23bp above that premise.

**Not exit-triggering for any position.** No D thesis carries a rate criterion.

**Source note.** The structured `TREASURY_10Y` row in `events.regime_events` ends on 2026-10-14. That is by design: its only reader, the park allocator's rates axis, was retired on 2026-10-15 (commit `a0c54648`, `bigquery/256`). The rationale text is now the source, so this is not a defect.

### F-12 (updated). Sector-cap reading: Industrials and Communication Services both drifted down

Readings on market value / cost against D's book of $530.09:

| Sector | Names | Market value | Cost |
|---|---|---|---|
| Industrials | GEV, UBER, RTX | **33.25%** | **34.44%** |
| Communication Services | GOOGL, DIS | **28.95%** | **30.45%** |
| Consumer Discretionary | AMZN | 15.93% | — |
| Information Technology | TSM | 12.63% | — |
| Health Care | ISRG | 9.24% | — |

Communication Services fell back under 30% at market on GOOGL's drop. **The adjudication is unchanged** (W5 FIX, commit `4c8d06d`):

- Entry criterion 5 is entry-scoped, so no exit is triggered or available.
- Nothing is blocked, because D is DNA and capital-disabled.
- Q2 carries the denominator caveat.

Nothing is owed.

### F-9 (updated). The AI-capex cluster, now measured by `analytics.factor_cluster_exposure`

This cycle reads the new `bigquery/272` view (Rev 55 companion, `eb85a625`), cluster `AI_CAPEX`, as of 2026-11-01. The D row and the ALL row are identical, because only D holds positions.

| Field | Value |
|---|---|
| `cluster_tickers` | AMZN, GEV, GOOGL, TSM |
| `cluster_market_value` | **$334.97** (cost $360.73) |
| `book_market_value` | $530.09 |
| `cluster_share_of_book_pct` | **63.19%** |
| `account_nav` | $12,382.02 |
| `cluster_share_of_account_pct` | **2.71%** |
| `latest_mark_date` | 2026-10-29 |
| `names_missing_mark` | 0 |

My independent recompute from the tranche table above gives $334.97 and 63.19%, which reconciles to the cent.

**Scope of the reading:**

- **VOO park look-through is excluded**, per the view's own definition. Any account-wide AI-capex share that includes VOO's index weight would be an approximate estimate and is not attempted here.
- This is **record-only**: no threshold, no alert, no block.

**Why the share fell from 66.2% last month.** It is price, not book change: GOOGL −17.5%, GEV −6.6% and TSM −5.3%, against ISRG +10.4%, RTX +7.4% and DIS +5.7%.

**This month's evidence on the cohort risk points two ways:**

- Demand side: every AI-capex name printed accelerating demand, and TSM guided Q4 at about +58% YoY.
- Financing side, which sharpened further:
  - AMZN TTM free cash flow is **−$42.4B**, and long-term debt went from $68.8B to **$180.9B** in nine months (10-Q, primary).
  - GOOGL quarterly capex doubled to $51.4B.
  - TSM's CFO said 2026–28 capex will be "significantly higher than the past three years".

No criterion in any of the four names tests FCF, leverage or capex intensity. That is unchanged, and it is recorded for future thesis construction only.

### F-7 (updated). Correlation recompute

This is the monthly post-entry recompute required by Entry criterion 5 (rev 28).

**Source.** IBKR `get_price_history`, one call per contract ID (never batched), `ONE_YEAR` / `ONE_DAY`, regular trading hours only. All 8 returned **251 bars with identical date sets**, 2025-10-31 → 2026-10-30, so **n = 250 returns** on all 28 pairs. Dates come from the returned timestamps, converted to America/New_York; this closes last month's synthetic-calendar caveat. **Every series' 2026-10-29 close matched `events.daily_marks` exactly**, so no series swap occurred.

```
         AMZN     DIS     GEV   GOOGL    ISRG     RTX     TSM    UBER
  AMZN  1.000   0.159   0.197   0.597   0.261  -0.002   0.319   0.264
   DIS  0.159   1.000  -0.108   0.177   0.336   0.077   0.038   0.305
   GEV  0.197  -0.108   1.000   0.174   0.030   0.146   0.620  -0.055
 GOOGL  0.597   0.177   0.174   1.000   0.271   0.028   0.301   0.228
  ISRG  0.261   0.336   0.030   0.271   1.000   0.144   0.112   0.258
   RTX -0.002   0.077   0.146   0.028   0.144   1.000  -0.018   0.074
   TSM  0.319   0.038   0.620   0.301   0.112  -0.018   1.000   0.147
  UBER  0.264   0.305  -0.055   0.228   0.258   0.074   0.147   1.000
```

- **Above 0.6: GEV–TSM at 0.620**, essentially unchanged from 0.614. Under Rev 35, bucket membership is informational only.
- **Above the 0.7 post-entry emergent threshold: none.**
- **AMZN–GOOGL rose to 0.597**, from 0.537 last month and 0.504 the month before. It now sits just under the 0.6 line, again a cross-sector AI-capex pair (F-9). Both names printed on consecutive days (10-28 and 10-29), and both moved down on 10-29, which by itself lifts the coefficient.
- **Mean pairwise correlation is 0.181**, against ~0.19 last month. RTX is uncorrelated with everything (all |r| ≤ 0.146).

**Caveats, stated.**

- At n = 250 the 95% CI half-width on r is about ±0.06–0.07, so neither the 0.620 nor the 0.597 is distinguishable from last month's value.
- The final two sessions of the window carry several outsized moves: GOOGL −12.6%, GEV −6.3%, TSM −5.9% and ISRG −3.7%. The end-of-window coefficients are sensitive to those days.
- **Process caveat:** the closes were re-entered from tool output into files, which is transcription. The controls applied:
  - every file length-checked to 251;
  - all eight 10-29 closes matched the warehouse;
  - the 10-30 closes were checked against the returned arrays.

  Interior values are not machine-verified. The date index for seven of the eight series reuses AMZN's identical timestamp list, a visual match.
- pandas and numpy were unavailable, so the computation used pure-Python Pearson. Whether the prices are dividend-adjusted is unknown.

### F-13 / F-14 (updated). Criteria testability: one new watch item, one deferral, one labelling note

- **UBER c2 (F-14), deferred again.** The first live test of whether Uber still discloses Adjusted EBITDA as a % of Gross Bookings was expected at the Q3 print. **Uber had not reported by 2026-11-01:** EDGAR shows no Item 2.02 8-K after 2026-09-15. Secondary sources give 11-02 or 11-03. Next cycle owns this test.
- **DIS c4 (F-14), unchanged.** The first test is the ~Feb 2027 Q1 FY27 report.
- **ISRG c3 (NEW watch, not a breach).** On the Q3 call, management said pricing actions will lower I&A revenue per procedure by about **3–5%** on a mix-constant basis once fully implemented: extended-use instruments, volume-based pricing, and a China price cut effective Q4. Source is a secondary transcript. c3 reads "recurring-rev decouples down from procedures". Q3 shows I&A **+18% against procedures +14–15%**, so there is no decoupling. A deliberate per-procedure price reduction is the mechanism by which a downward decoupling could appear **by design** in 2027 without any adoption failure.
  - This is an F-13-class observation, a bare criterion that fires on a known input. It is recorded so next cycles read c3 with that context.
  - Criteria are immutable, and nothing changes.
  - c3 as written has no consecutive-quarter count. Any future reading of "decouple" must be made literally, per the PROSPECTIVE ONLY rule.
- **AMZN c3 labelling (NEW note).** The Q3 10-Q states "commitments not yet recognized … approximately $578 billion as of September 30, 2026". The sub-agent could not confirm from the summarized text whether that sentence is AWS-specific or company-wide. Last cycle's $496B Q2 figure is the same disclosure line and was primary-confirmed, so the series is like-for-like, and it **rose** about $82B (+16.5%) sequentially. That reads UNBREACHED on either labelling. Next cycle should quote the 10-Q note's exact scope wording once, so the criterion's metric is pinned in this file.

### F-1 (updated). Completion-criteria gap: GEV is the first name to approach a completion leg

GEV is still the only position with a testable completion criterion. At Q3:

- **Leg (i), backlog ≥ $200B: $197B**, up $20B sequentially. Management expects it to exceed $200B in Q4 (secondary). Leg (i) will very likely be **met at the Q4 print, ~late January 2027**.
- **Leg (ii), trailing-4Q organic orders growth ≤ 25% for at least one quarter: not met, and moving away.** Organic orders were +71%, +88% and **+96%** in Q1–Q3'26. The disclosed quarterly series cannot produce a trailing-4Q figure without the Q4'25 organic number, which was not retrieved. With three of the four quarters at +71% to +96%, the trailing figure is far above 25%.

**Completion requires BOTH legs, so GEV is not near completion.** The thesis is completing on the size of the book while the growth rate is still accelerating. That is exactly the case the two-leg design was written for: backlog size alone is not "fulfillment" while orders are still compounding.

**For M4: no completion call, now or at the Q4 print, unless leg (ii) also turns.** The other seven names still have no completion mechanism. That is unchanged and recorded, not actionable.

### F-5 (updated). Source reliability this cycle

1. **Earnings figures come from primary filings** (8-K Ex. 99.1, 10-Q and 6-K on `sec.gov`), retrieved through `WebFetch`. The fetch tool returns a model-summarized rendering of the document, not verbatim text, so every primary figure is "primary source via a summarizer". Numbers that matter were cross-checked against D1's independent same-day reads where those exist:
   - GEV +96%;
   - GOOGL Cloud +103% / 36.2% and the $567.7B RPO;
   - AMZN AWS +39.3% / 38.65%.

   All agreed.
2. **Prior-quarter comparatives** come from this file's own prior cycles or from secondary sources, labelled per position: RTX Q2 $289B, TSM sub-7nm 77%, AMZN Q2 $496B.
3. **Stock-reaction claims from web search were unreliable this cycle.**
   - A secondary snippet claiming ISRG fell 10.5% after hours to about $392 is **contradicted by the IBKR series**: ISRG has no October daily move larger than −3.7%, and it closed $448.76 on 10-29. The snippet is treated as stale or misdated.
   - Only the IBKR-measured moves are cited in this file.
4. **Not read:** the GOOGL call transcript and full 10-Q MD&A (F-18); the RTX 10-Q (any powder-metal accrual update); the GOOGL ad-tech final judgment; the Disney IR earnings-date page.

---

## Per-position deep-dives

Each section covers the six required items: (1) thesis status, (2) driver check, (3) fundamental developments, (4) invalidation check, (5) sector and theme, and (6) tax.

Status vocabulary for criteria:

- **UNBREACHED**: the last measurement does not meet the trigger.
- **NOT ENGAGED**: no new data point arrived in the window.
- **"0 of 2"**: zero of the two consecutive quarters a criterion requires are in breach territory.

### GEV — GE Vernova · 1 tranche · HOLD

**Thesis (Subtype B):** total-company organic orders growth continues; the gas-turbine and grid super-cycle is driven by AI-datacenter and electrification power demand. **Status: intact and strengthening.**

**Developments in window** (Q3 8-K Ex. 99.1 and 10-Q filed 2026-10-28, primary; these are the only two GEV filings in the window):

- **Orders $29.3B, +96% organically.** Power was $21.8B (+178%), Electrification $5.4B (−9% organic, against large synchronous-condenser orders in Q3'25) and Wind $2.1B (+16%). Power services orders were +12%.
- **Backlog $197B**, up $20B sequentially.
- **Gas turbine backlog plus slot reservations: 116 → 122 GW** (64 GW backlog + 58 GW slots). The YE2026 target is now **"at least 130 GW"**, up from ≥125 GW.
- **FY26 guidance raised:**

  | Line | New guide | Prior guide |
  |---|---|---|
  | Revenue | $46.5–47.5B | $45.5–46.5B |
  | Adjusted EBITDA margin | 13.5–14.5% | 12–14% |
  | FCF | **$16–17B** | $11.5–12.5B |
- **Portfolio:**
  - agreed to acquire Trench Group (~$9.0B; close expected late 2027);
  - bought the remaining 50% of Prolec GE (+$4.0B pre-tax remeasurement gain);
  - sold Proficy;
  - Vineyard Wind litigation resolved.

  A buyback increase to $20B was reported by a secondary source only and was not confirmed in the primary document.
- **Stock:** −10.6% on 10-22, **before** the print. This run did not identify a cause, and the research found no GEV filing or company event that day. The stock fell a further 10-30. The month's move was −6.6%.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| Inv | Organic orders growth YoY < 15% for 2 consecutive Q | **Yes** | **UNBREACHED** | +71% → +88% → **+96%** (Q3'26); 0 of 2 |
| Imm | Organic-orders disclosure lapses in comparable form for 2 consecutive Q | **Yes** | **UNBREACHED** | Q3 still discloses total-company organic orders growth in the same form |
| Comp (i) | Backlog ≥ $200B | **Yes** | **NOT MET** (close) | $197B; > $200B expected in Q4 (secondary) |
| Comp (ii) | Trailing-4Q organic orders growth ≤ 25% for ≥ 1 Q | **Yes** | **NOT MET** (far) | Accelerating; see F-1 |

**Drivers:** progressing on every axis (orders, slots, capacity, margin). **Sector:** the AI-power scarcity narrative is intact. The October drawdown is price, not driver. **Next test:** Q4 print ~late January 2027. **Tax:** LTCG 2027-08-04 (276 days). Completion is not near (F-1), so there is no LTCG coordination question.

**Recommendation: HOLD.** The −8.5% mark is short-term price action and is explicitly not exit-triggering.

### AMZN — Amazon · 2 tranches · HOLD

**Thesis (Subtype B):** AWS growth, margin and backlog compound, anchored by large AI-lab compute commitments. **Status: intact and strengthening.**

**Developments in window** (Q3 8-K Ex. 99.1 filed 10-29 and 10-Q filed 10-30, primary):

- **AWS net sales $45,984M, +39.3% YoY**, the "fastest growth in nearly five years". AWS operating income was $17,773M, a **38.7%** margin (Q2 39.4%; Q3'25 34.6%).
- **Commitments not yet recognized: ~$578B** (Q2 ~$496B); see F-14 for the labelling note. The release names new AWS agreements with Meta, NVIDIA, OpenAI and Oracle, without values.
- **Anthropic / OpenAI (10-Q):** every disclosed movement is an **expansion**, with no reduction or churn.
  - Anthropic expanded its commitment by more than $100B over 10 years in Q2'26.
  - OpenAI's $38B commitment was expanded by $100B over 8 years in Q1'26.
  - Amazon funded $21.3B of its OpenAI preferred commitment in Q3.
- **Financing** (F-9): TTM free cash flow −$42.4B; long-term debt $180.9B (from $68.8B at year-end 2025); a $17.5B term loan drawn in September. The 2026 capex outlook of ~$220B is unchanged.
- **Q4 guide:** net sales $240–247B, operating income $28.5–33.5B.
- **EU DMA:** the AWS gatekeeper designation was **not** finalized in October. A report says it is planned for November (secondary).

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | AWS YoY < 18% for 2 consecutive Q | **Yes** | **UNBREACHED** | +37.0% → **+39.3%**; 0 of 2 |
| 2 | AWS op margin < ~30% for 2 consecutive Q | **Yes** | **UNBREACHED** | 39.4% → **38.7%**; 0 of 2 |
| 3 | AWS backlog declines sequentially for 2 consecutive Q | **Yes** | **UNBREACHED** | ~$496B → **~$578B**; 0 of 2 (F-14 labelling note) |
| 4 | Anthropic/OpenAI commitments renegotiated down or churned | **Yes** | **UNBREACHED** | 10-Q shows expansions only |
| 5 | AWS segment reporting restructures for ≥ 2 Q | **Yes** | **UNBREACHED** | North America / International / AWS unchanged |

**Drivers:** progressing. Jassy projects AWS growth above 40% in 2027–28 (release). **Sector:** debt-funded capex escalation (F-9). **Next tests:** EU DMA designation (~November); Q4 print ~early February 2027. **Tax:** LTCG 2027-07-09 and 2027-07-31.

**Recommendation: HOLD.**

### DIS — Walt Disney · 2 tranches · HOLD

**Thesis (Subtype B):** streaming profitability expansion, the EPS-growth framework and buyback execution. **Status: intact. A second quiet month; FQ4 has not printed.**

**Developments in window:**

- **EDGAR shows only Forms 4 in the window**: 12 filings, on 10-02, 10-09 and 10-19. There is no 8-K, 10-K or 10-Q (primary).
- **FQ4/FY26 results are reported for Tuesday 2026-11-17, before the open.** This is secondary and not confirmed on Disney IR.
- **FCC / ABC licences** (ABC v. FCC, D.D.C. 1:26-cv-02902): Judge AliKhan heard the preliminary-injunction argument on **2026-10-06** and did not rule. Supplemental filings were due 10-14. **No ruling on the PI or on the FCC's motion to dismiss was found** as of 11-01 (secondary). No FCC final order restricting station ownership was found.
- **Pricing:** Disney+, Hulu and ESPN prices rose by $0.50–3 per month. New subscribers pay from 09-23; existing bills from 10-21 (secondary).
- No guidance, buyback, segment-reporting or CEO-succession news was found. The searches were not exhaustive.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | SVOD op margin < 8% for 2 consecutive Q | No | **UNBREACHED** (not engaged) | ~12.9% FQ3 FY26; 0 of 2 |
| 2 | FY26 adj EPS growth guide cut to ≤ 6% | No | **UNBREACHED** (not engaged) | ~12% reiterated at FQ3; no 8-K since |
| 3 | Buyback below run-rate, or a suspension 8-K | No | **UNBREACHED** (un-breachable for FY26) | 9-month $7,245M vs the ≤$5B Q3 floor; no 8-K |
| 4 | Metric-immutability (SVOD in its current 8-K Ex-99.1 form) | No | **UNBREACHED** | First test ~Feb 2027 |
| 5 | ESCALATION: FCC final order **AND** a Disney material-adverse 8-K | Litigation only | **NOT ENGAGED** | Neither leg present |

**Drivers:** carried as progressing; the price increases are mildly supportive of SVOD margin. **Next tests:** FQ4 FY26 print **~2026-11-17**, which tests c1, c2 and c3 for the full year; the D.D.C. PI ruling. **Tax:** LTCG 2027-05-08 (parent, 188 days) and 2027-08-06.

**Recommendation: HOLD.**

### GOOGL — Alphabet · 2 tranches · HOLD

**Thesis (Subtype B):** Google Cloud revenue growth, margin and backlog keep compounding, and structural-remedy risk stays bounded. **Status: intact. The thesis segment is markedly stronger; the stock fell on the parent's EPS (F-18).**

**Developments in window** (Q3 8-K Ex. 99.1 and 10-Q, 2026-10-28, primary):

- **Google Cloud revenue $30,709M, +102.6% YoY** (Q2 +81.8%). Cloud operating income was $11,121M, a **36.2%** margin, up from 35.6% in Q2 and 23.7% a year ago.
- **RPO:** Alphabet total **$567.7B**, of which **Google Cloud is $560.8B**, against $513.9B in Q2 (+$46.9B, +9.1%). The $567.7B figure D1 quoted is the Alphabet total; the criterion's Cloud figure is $560.8B. Just over 55% of RPO is to be recognized within 24 months. $16.8B comes from an agreement with an unconsolidated equity-method joint venture (Crux AI).
- **Segments unchanged:** Google Services, Google Cloud, Other Bets.
- **Ad-tech remedies (E.D. Va.):** behavioral only. The DOJ's structural remedies were rejected on 09-02. Whether the final judgment was entered in October was **not found** (secondary; no docket access). Google says it will appeal liability.
- **Search case (D.C. Cir.):** "Oral Argument Not Yet Scheduled". No ruling.
- **Price:** −12.6% on 10-29 and −1.4% on 10-30. The month's move was −17.5% (F-18, F-19).

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | Cloud rev YoY < 20% for 2 consecutive Q | **Yes** | **UNBREACHED** | +81.8% → **+102.6%**; 0 of 2 |
| 2 | Cloud op margin contracts for 2 consecutive Q | **Yes** | **UNBREACHED** | 35.6% → **36.2%** (expanded); 0 of 2 |
| 3 | Cloud RPO/backlog declines sequentially for 2 consecutive Q | **Yes** | **UNBREACHED** | $513.9B → **$560.8B**; 0 of 2 |
| 4 | Adverse structural remedy | Searched | **UNBREACHED** | No structural remedy in any jurisdiction found; ad-tech remedies behavioral |
| 5 | Cloud revenue reported comparably for ≥ 2 Q | **Yes** | **UNBREACHED** | Segment unchanged |

**Drivers:** Cloud and TPU demand are accelerating. TPU systems sales were cited as a Cloud contributor (secondary). **Sector:** AI-capex monetization scrutiny is now acute in the price (F-9, F-19). The parent's dominant line, Search, grew +12% (F-18). **Next tests:** ad-tech final-judgment entry and appeal; Q4 print ~early February 2027. **Tax:** LTCG 2027-07-09 and 2027-07-27.

**Recommendation: HOLD.** Both tranches are below cost (−21.1% and −13.4%). That is price action against an intact, strengthening criterion set, and it is not exit-triggering. Rev 55 does not apply retroactively.

### TSM — Taiwan Semiconductor · 2 tranches · HOLD

**Thesis:** AI-accelerator-driven leading-edge foundry demand, gross margin, node leadership (N2/A16) and CoWoS. **Status: intact and strengthening.**

**Developments in window** (6-Ks filed 10-08 and 10-15, primary, unless noted):

- **Q3'26 revenue was US$46.72B, +41.2% YoY** (+16.2% QoQ). **GM 66.4%**, down 1.3pt from 67.7% on N2 ramp dilution (secondary transcript).
- **Wafer revenue by node:** N2 8%, N3 33%, N5 28%, N7 10%. **Advanced (7nm and below) was 79%**, against Q2's 77%.
- **Q4 guide:** revenue US$52.3–54.3B, about +58% YoY at the midpoint (secondary arithmetic); GM 65–67%. FY26 USD growth about 44%, and FY26 capex US$60–64B, reiterated (secondary).
- **Demand commentary** (secondary transcript): demand is "still far above our capability today to supply"; CoWoS is "still the number one choice", with a back-end shortage.
- **N2:** "ramping successfully in multiple phases"; N2-family capacity is to more than double by 2027.
- **A16:** not mentioned on the call. A14 risk production is in 2027. Arizona fab 2 volume production is now expected in Q3 2027, "slightly ahead" of schedule.
- **Monthly revenue:** September was NT$511.86B, +54.6% YoY. October is due ~11-10.
- **Unchecked or unremarkable:** the 6-K of 10-22 was not read. No in-window Section 232 action was found. One Taiwan-geopolitics search found no verified October incident.
- **Price:** −5.9% on 10-30 (unexplained this run); the month's move was −5.3%.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | GM < 55% OR USD rev YoY < 15% for 2 consecutive Q | **Yes** | **UNBREACHED** | GM 66.4%; USD rev **+41.2%**; 0 of 2 |
| 2 | N2/A16 ramp pushed out OR sub-7nm share declines for 2 consecutive Q | **Yes** | **UNBREACHED** | No pushout (N2 at 8% of revenue, ramping); sub-7nm 77% → **79%** |
| 3 | Structural AI-capex reset | Continuous | **UNBREACHED**; evidence points the other way | Demand exceeds supply; Q4 guide +58% YoY |

**Drivers:** progressing. A16 status was **not found** this cycle, so the "A16" half of c2's pushout leg is evidenced only by the absence of any reported slip. Next cycle should confirm A16 explicitly. **Sector:** demand is not the issue; capital intensity is rising (F-9). **Next tests:** October revenue ~11-10; Q4 print ~mid-January 2027. **Tax:** LTCG 2027-07-21 and 2027-07-30.

**Recommendation: HOLD.**

### ISRG — Intuitive Surgical · 1 tranche · HOLD

**Thesis:** da Vinci procedure growth, system placements and recurring-revenue attach, against competitive entry. **Status: intact.**

**Developments in window** (Q3 8-K Ex. 99.1 filed 10-20 and 10-Q filed 10-21, primary):

- **da Vinci procedures about +14% YoY** (about +15% including Ion; Ion +31%). By region: US +10%, OUS +20% (secondary).
- **Placements 546 vs 427 (+28%)**, of which 315 were da Vinci 5.
- **I&A $1.80B, +18%.** Total revenue $3.05B (+22%).
- **FY26 procedure guide** narrowed to about 14–15%, "closer to the midpoint".
- **$450M antitrust settlement** (In re: da Vinci Surgical Robot Antitrust Litigation) with agreed injunctive relief, subject to court approval. It was booked as a Q3 SG&A charge, about $0.99/share.
- **Pricing actions** will cut I&A per procedure by about 3–5% (F-14 watch).
- **No competitor disclosure of a named-IDN displacement** was found in the filing or the call. A separate news search was not run.
- **Price:** +10.4% over the month. The circulating "−10.5% after hours" claim is refuted by the IBKR series (F-5).

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | Procedure growth < 10% YoY for 2 consecutive Q | **Yes** | **UNBREACHED** | +16% → +15% → **+14%** (da Vinci); 0 of 2. The trend is gently decelerating, still 4pt clear |
| 2 | Placements decline YoY for 2 consecutive Q | **Yes** | **UNBREACHED** | **546 vs 427 (+28%)**; 0 of 2 |
| 3 | Recurring revenue decouples down from procedures | **Yes** | **UNBREACHED** | I&A +18% vs procedures +14%; pricing-driven watch (F-14) |
| 4 | Competitor displaces da Vinci at named large IDNs | Partial | **UNBREACHED** | None in the filing or call; no separate competitor search |

**Drivers:** progressing (dV5 placements, Ion). **Watch:** US da Vinci growth of +10% is the single closest reading to any threshold in the book. Note that c1's threshold applies to the **worldwide** procedure figure, at +14%. **Next test:** Q4 print ~late January 2027. **Tax:** LTCG 2027-07-20 (261 days).

**Recommendation: HOLD.** The +28.4% unrealized gain is not a completion signal, because ISRG has no completion criterion (F-1).

### UBER — Uber Technologies · 1 tranche · HOLD

**Thesis (Subtype B):** Gross Bookings growth, margin expansion and Uber One flywheel compounding. **Status: intact. No new data: Q3 had not printed by 11-01.**

**Developments in window:**

- **EDGAR shows only Forms 4 and a CERT** from 09-15 through 10-20 (primary). **Q3 is not yet reported.** The date is unconfirmed: secondary sources say 11-02 or 11-03, and investor.uber.com returned template content only.
- The Q3 guide carried from Q2 is GB $58.25–60.25B (secondary).
- **Delivery Hero:** the €41.50 offer's acceptance period ends **2026-11-05**. The minimum acceptance is 50% + 1 share, with Prosus irrevocably committed for ~16.7%. Settlement is expected in H2 2027, subject to regulatory approval (secondary). The running acceptance level was not found.
- No October AV news was found. The Lucid/Nuro robotaxi is planned for late 2026 (secondary, pre-window).
- **Price:** −4.0% over the month.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | GB cc YoY < ~15% for 2 consecutive Q | No | **UNBREACHED** (not engaged) | +21%, +22%; 0 of 2 |
| 2 | Adj-EBITDA % of GB contracts YoY for 2 consecutive Q | No | **UNBREACHED** (not engaged) | +26bp, +40bp. **Testability test deferred to the Q3 print** (F-14) |
| 3 | Uber One membership stalls or declines sequentially | No | **UNBREACHED** | "Another all-time high" at Q2 |
| 4 | GB disclosure structurally changes | No | **UNBREACHED** | No filing |

**Next tests:** Q3 print ~11-02/03 (c1–c4 plus the c2 testability test); Delivery Hero acceptance close 11-05. **Tax:** LTCG 2027-07-09.

**Recommendation: HOLD.** The −10.2% mark is price action only.

### RTX — RTX Corporation · 1 tranche · HOLD

**Thesis:** commercial aerospace aftermarket and GTF fleet recovery, plus the defense backlog. **Status: intact and strengthening.**

**Developments in window** (Q3 8-K Ex. 99 and 10-Q, 2026-10-20, primary; the only 8-K in the window):

- **Backlog $340B** ($176B commercial, $164B defense), up from $289B in Q2 (+17.6%). Q3 included Tomahawk and AMRAAM multi-year undefinitized awards (secondary).
- **FY26 guidance raised:**

  | Line | New guide | Prior guide | Basis |
  |---|---|---|---|
  | FCF | **$9.0–9.2B** | $8.50–8.75B | primary |
  | Adjusted sales | $97.0–97.5B | — | secondary |
  | Adjusted EPS | $7.65–7.75 | — | secondary |

  Q3 FCF was $2.1B, −47% YoY (secondary).
- **Charges:** a $363M P&W charge for a customer bankruptcy, well under $1B and not a fleet-quality event. Powder metal appears only in risk-factor language. The 10-Q itself was **not read**.
- **GTF Advantage:** first delivery 2026-09-24; no slip reported.
- **Airbus damages:** no ruling or settlement found.
- **FY27 appropriations:** the CR (P.L. 119-103) runs to **2026-12-11** at FY26 levels. No full-year FY27 defense bill has been enacted. A lapse would begin 12-12.
- **Price:** +7.4% over the month.

| # | Criterion | New data? | Status | Evidence |
|---|---|---|---|---|
| 1 | Airbus damages ruling > $2B | Searched | **UNBREACHED** | None found |
| 2 | New powder-metal-style quality event > $1B charge | **Yes** | **UNBREACHED** | Only a $363M customer-bankruptcy charge (not a quality event); 10-Q unread |
| 3 | GTF Advantage EIS slips beyond Q1'27 | Yes | **UNBREACHED** | Entered service 2026-09-24 |
| 4 | Backlog declines for 2 consecutive Q | **Yes** | **UNBREACHED** | $271B → $289B → **$340B**; 0 of 2 (Q1/Q2 comparatives secondary or prior-cycle) |
| 5 | FY26 FCF guide < $7.5B | **Yes** | **UNBREACHED** | Raised to **$9.0–9.2B** |
| 6 | FY27 defense procurement cut ≥ 10% YoY | Yes | **UNBREACHED** | CR at FY26 levels to 12-11; nothing enacted below |

**Watch:** CR expiry on **2026-12-11**. A lapse, a further CR or a full-year bill is the next c6 data point. **Tax:** LTCG 2027-04-27 (177 days), the nearest in the book. **Separate trigger:** the falsifiable-milestone reassessment at Q1'27 earnings.

**Recommendation: HOLD.**

---

## Long-term tax treatment — full book

No tranche reaches LTCG inside the next quarter. The nearest are **RTX on 2027-04-27 (177 days)** and the **DIS parent on 2027-05-08 (188 days)**. The other ten fall between 2027-07-09 and 2027-08-06.

No position is at a completion or invalidation signal. GEV's leg (i) alone does not complete its thesis (F-1). **No LTCG-timing coordination question arises.** Under Rev 39, exit timing is governed by thesis criteria alone. All 12 tranches carry a populated `ltcg_date`.

---

## Summary of recommendations

| Name | Recommendation | Basis | Next scheduled test |
|---|---|---|---|
| GEV | **HOLD** | 0 of 2 breached; completion leg (i) $197B vs $200B, leg (ii) far | Q4 ~late Jan 2027 |
| AMZN | **HOLD** | 0 of 5 breached; AWS +39.3% / 38.7% | EU DMA ~Nov; Q4 ~early Feb |
| DIS | **HOLD** | 0 of 4 breached; c5 not engaged | FQ4 ~11-17; D.D.C. PI ruling |
| GOOGL | **HOLD** | 0 of 5 breached; Cloud +103% / 36.2% / RPO +9.1% | Ad-tech judgment and appeal; Q4 ~early Feb |
| TSM | **HOLD** | 0 of 3 breached; GM 66.4%, USD +41.2% | Oct revenue ~11-10; Q4 ~mid-Jan |
| ISRG | **HOLD** | 0 of 4 breached; c3 pricing watch | Q4 ~late Jan |
| UBER | **HOLD** | 0 of 4 breached; Q3 not yet printed | Q3 ~11-02/03; DH tender close 11-05 |
| RTX | **HOLD** | 0 of 6 breached; backlog $340B, FCF guide raised | CR expiry 12-11; Q4 ~late Jan |

**For M4:** there are no exits to stage, no research deferrals to schedule and no IMMEDIATE-ACTION flag. **GEV is not a completion candidate** (F-1). F-18 (the GOOGL / Rev 55 record), F-19 (the price-fundamentals divergence and alpha swing) and F-16 (rates) are **context only**. Manufacturing an action from any of them would be an error.

## Items owned by a routine other than M4's exit path

- **D1 (add-candidate HARD GATE):** all 12 tranches remain affirmatively assessed (F-17). This cycle's Q3 data supports the "strengthened conviction" reads D1 recorded for GEV, GOOGL and AMZN. Adds remain unfundable while D is DNA and capital-disabled.
- **Next M3 (2026-12):** must cover four things:
  - UBER Q3, including the c2 Adjusted EBITDA testability test;
  - DIS FQ4;
  - the TSM A16 confirmation;
  - the AMZN 10-Q RPO scope wording (F-14).

## Method, and what this run did not do

- **Sources.**
  - BigQuery for positions, marks, engine, NAV, regime, factor-cluster exposure, decision log, queue and alerts.
  - Four Sonnet research sub-agents ran on SEC EDGAR / `sec.gov` (`WebFetch`), issuer IR and free web search: **52 calls**, all on the free `web_search` / `web_fetch` surfaces.
  - A fifth sub-agent made 8 read-only IBKR `get_price_history` calls for the correlation recompute (unmetered).
  - The orchestrator made no web call.
- **No FMP, no Tavily, no metered spend.** The `ops.web_calls` rows are logged with `credits = 0`.
- **Writes.**
  - This file.
  - `ops.run_log` start and end rows.
  - `ops.web_calls` telemetry.
  - **No `events.position_events` row** (F-17: zero backlog).
- **Not done, deliberately:**
  - No order, queue item or calendar event (M3 stages nothing).
  - No re-derivation or re-stamping of any criterion.
  - No retroactive application of Rev 55.
- **Not done, coverage gaps (stated):**
  - GOOGL call transcript and MD&A (F-18).
  - RTX 10-Q.
  - GOOGL ad-tech final-judgment docket.
  - Disney IR date page.
  - Uber's Q3 date confirmation.
  - The cause of GEV's 10-22 drop and TSM's 10-30 drop.
  - ISRG competitor news search.
  - GEV Q4'25 organic orders (needed for a trailing-4Q figure).
