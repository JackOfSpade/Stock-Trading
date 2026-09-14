2026-09-14
<!-- d1_scan_through_utc: 2026-09-14T22:30:34Z -->

# Daily Market Development Scan — 2026-09-14 (Mon, MT)

**Scan window: 2026-09-13 16:34 MT → 2026-09-14 16:30 MT** (23.9h — cadence-normal, no gap to state). Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-13T22:34:33Z -->` marker, cross-checked against that file's own commit at `2026-09-13T22:39:50Z` — the two agree to within six minutes. The git history is **not** shallow (1,446 commits), so the git leg of the window resolution is sound rather than merely silent. **ONE completed US trading session inside this window: Monday 2026-09-14.** `state.trading_day_today` gives `is_trading_day = true`, `last_trading_day = 2026-09-14`, `next_trading_day = 2026-09-15`. Every close-to-close figure in this file is measured **2026-09-11 → 2026-09-14**.

**Tape — a ROTATION, not a selloff, and the distinction is the whole story.** SPY 764.29 → 760.88 (**−0.4461%**), VOO 702.56 → 699.30 (−0.4640%), QQQ **−0.7974%**, DIA −0.2472%, IWM −0.3393%, SGOV +0.0099%. VIX 15.84 → **17.10** (**+7.9545%**). Brent (BZX6 front month) 104.61 → **105.68** (+1.0229%), USO +1.1362%. GLD **−1.4874%**, TLT +0.0742%, UUP +0.3563%, BITO +2.3144%. Equity breadth ($S5TH) 56.46 → **56.26**. **Three of eleven GICS sectors higher**, and the cross-sector spread **widened to 4.0000pp** (XLC +2.1936% to XLK −1.8064%) from 1.6285pp on 09-11 and 2.02pp on 09-10. An index down less than half a percent while its sectors spread four points apart is doing something far more specific than falling.

All equity/ETF figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), every bar verified carrying a 2026-09-14 stamp of `13:30:00Z`. **Two documented exceptions, stated rather than hidden:** the ^VIX bar (contract 13455763, `IND`/CBOE) stamps `07:15:00Z` and carries `delayed:900` — an index-feed property, not an equity RTH bar; and the Brent bar is a NYMEX future (BZX6, contract 339981284, `contract_month` 202611, last trading date 2026-09-30 — a legitimate front month with ~16 days to expiry).

**This run is NOT degraded, and that is measured rather than claimed.** 33 distinct single names and 24 index/ETF/future instruments were put to IBKR for confirmation; **all 57 returned a genuine 2026-09-14 regular-session bar. Zero symbol-level denials. Zero measurement failures.** Every `surfaced_count` in this file is an affirmatively established figure, never a reported zero standing in for an unmeasured population.

---

## TL;DR

- **Exits triggered: none.** No convergence target, no time exit, and no thesis-invalidation criterion met on any of the 12 open tranches — including GEV, which fell 8.62%.
- **New entry candidates: none routable.** A, B, D, E are all `DO-NOT-ACTIVATE`; C is `HYBRID ACTIVATE (FOMC-only)` and its FOMC lane is already queued (`thesis-FOMC-C-20261020`).
- **Add candidates: none** (12 evaluated, 0 flagged, 3 declined at the HARD GATE — ISRG, RTX, UBER).
- **Watchlist changes: none.**
- **Regime review: no review.** Wednesday's FOMC (~92% priced for the first hike since 2023) is the event that could warrant one; it has not resolved.
- **Park: KEEP at f=50** (VOO 50% / SGOV 50%), MEDIUM 60, BOUND — four standing defensive axes but **zero fired**, so the increase gate is shut.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**(a) Middle East energy-corridor escalation → oil up, yields up, equities down.** Inside the window, overnight Sunday into Monday's session:
- **Sun 2026-09-13:** Oman's Foreign Minister announced that Monday's planned Salalah meeting between Iran and Gulf Arab states — intended to finalise a Strait of Hormuz shipping-safety framework — was **postponed** "in the interests of consensus" (Reuters, ADEN/DUBAI; corroborated by CNBC and Al Jazeera, both 09-13).
- Same day, UKMTO reported a **projectile strike on a vessel transiting the Strait of Hormuz**, causing a fire; Iranian state media reported one death when an Iranian commercial vessel was struck nearby (Reuters / AP, 09-13).
- Backdrop carried into the window: Saudi Arabia's 1,200 km **East-West (Petroline) pipeline** — its main Hormuz-bypass route, 4–5m bpd — was struck by drones and shut 09-11/12 and remained closed through the weekend; Houthi forces seized **Perim** in the Bab el-Mandeb (Reuters / Al Jazeera, 09-11/12).
- **Observable reaction:** Brent front month **104.61 → 105.68 (+1.0229%, IBKR)**, the 10-year Treasury **briefly above 5%** intraday — its highest since 2023 — settling at **4.97** (FMP `treasury-rates`, against 4.96 on 09-11 and 4.80 on 09-08). Gold **fell** 1.4874% as real yields outweighed safe-haven demand. **Energy equities declined to follow crude** — see Development 4.

**(b) A frontier-AI-pacing scare — the larger driver of the equity tape.** Anthropic CEO Dario Amodei published a ~3,800-word essay, *"We Must Pace the Frontier,"* over the weekend of 09-12, urging frontier labs to slow capability development on safety grounds. OpenAI's Sam Altman publicly agreed and told *Fortune* OpenAI is **delaying its IPO to 2027**; Elon Musk and Demis Hassabis also joined within hours. **Observable reaction:** a rotation *within* the AI trade rather than out of equities — sell the buildout chain, buy the names seen as less dependent on it continuing. Asian AI names led (SoftBank −13.2%, Kioxia −9.8%, SK Hynix −5.3%, Samsung −3.7%); in the US, ORCL **−13.7912%**, MRVL −7.3189%, INTC −5.5858%, NVDA −3.3579% against GOOGL +3.2171% and a cybersecurity complex up 7–17%.

**These two shocks ran concurrently and neither alone explains the tape.** The energy/rates leg explains Utilities, Real Estate and gold; the AI-pacing leg explains Technology, Communication Services and the cybersecurity bid.

### 2. Scheduled events that resolved today

**Nothing material resolved.** Applying the EVENT-IDENTITY GATE strictly, no US-listed issuer at ≥$2B market cap published an earnings result, FDA decision or other scheduled catalyst inside this window. Specifically **pending, not resolved**:
- **FOMC — PENDING.** The meeting is **2026-09-15/16**; the decision and SEP/dot plot are due **Wednesday 2026-09-16, 14:00 ET**. Fed-funds futures price ~**92%** probability of a **25bp HIKE to 3.75–4.00%** — which would be the first hike since 2023. Nothing in this window confirms an outcome and no outcome figure is recorded.
- **Empire State Manufacturing (September)** — scheduled **Tuesday 2026-09-15** per the NY Fed's own release calendar, consensus ~14–15 against August's 20.60. Not resolved.
- **University of Michigan Consumer Sentiment (Sept prelim, 47.8 vs 51.7)** was released **Friday 09-11**, *before* this window opens, and is excluded.
- Dave & Buster's (PLAY) reported after Monday's close, but its non-affiliate market value is ~$1.0B per its own 10-K — **below the $2B screen threshold**, so it is noted for completeness only and is not a category-2 finding.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

**Layer-1 rail:** 33 distinct US-listed names measured individually against IBKR daily bars; **25 cleared** the mechanical net (≥2% close-to-close, ≥$2B cap, identifiable public event). **Layer-2 surfaced 14.** Logged as one `research-screen` row (`screen='single-name-move'`), `surfaced_count`=14=`ARRAY_LENGTH(passed)`, `rail_tally`=25, `universe_measured`=33.

| Ticker | Move | Conv. | Driver |
|---|---|---|---|
| **ORCL** | **−13.7912%** | 75 | Largest mega-cap move of the day. AI-capex repricing amplified by the most leveraged balance sheet in the basket. **Driver partly unresolved — see below.** |
| **GEV** | **−8.6189%** | 75 | **HELD.** GLJ Research Sell initiation at $470 on a forward backlog-margin case, plus a sector-wide datacenter-power repricing. |
| **TSM** | **−3.5153%** | 75 | **HELD.** Below the legacy 5% bar yet the most thesis-relevant name on the board — see RISK below. |
| SIMO | −16.7569% | 30 | Largest move, lowest conviction: no catalyst established beyond the semis selloff. |
| ZS | +16.5249% | 60 | Cybersecurity bid, and the only cluster member with a real event: FQ4 revenue $898.2M vs $877.0M, adj EPS $1.19 vs $1.09. |
| CRWD | +13.8531% | 60 | ~$240B mega-cap at a record high on **no company news** — prices the narrative itself. |
| NOK | −13.2974% | 45 | Three causes stacked: AI-optical capex, a mainland-China site exit, and a terminated combination. |
| MRVL | −7.3189% | 60 | The cleanest read of the AI-capex repricing at the component layer. |
| SRRK | −6.4249% | 45 | Gave back the entire FDA-approval pop (see 4 below). |
| BAC | −5.1364% | 60 | The one genuinely independent cause on the board. |
| RIG | −3.8801% | 45 | Counter-narrative: a driller **fell** on an oil supply shock. |
| NVDA | −3.3579% | 60 | Small in percent, large in signal — the reference the rest is read against. |
| GOOGL | +3.2171% | 60 | **HELD.** The receiving side of the rotation. |
| ISRG | +2.3814% | 30 | **HELD.** No established driver — recorded as unexplained. |

**ORCL, and why its driver is recorded as partly unresolved.** A ~$417B company lost roughly an eighth of its value in a session. *Established:* the AI-pacing scare repriced the buildout chain, and Oracle is the most leveraged way to express that — downgraded to **BBB−** (one notch above junk) on 2026-07-09 citing OpenAI concentration at roughly half of RPO; its 09-10 fiscal Q1 FY2027 print disclosed capex up to **$28.5B** from $8.5B and free cash flow swinging to **−$5.4B** against ~$125–130B of debt. *Not established:* the third-party record is internally inconsistent — that 09-10 print was a **beat** (revenue $19.35B +30%, non-GAAP EPS $1.92, OCI +121%, RPO $664B, FY27 guide raised) that lifted the stock, yet same-day headlines describe Monday's fall as "on weak guidance"; and those sources carry a 09-11 close of **150.28** against IBKR's **164.38**, so their surrounding figures cannot be relied on. Recorded as an AI-capex repricing amplified by leverage, **with the guidance question open**, rather than resolved into a tidier story than the evidence supports.

**The cybersecurity cluster is one phenomenon with eleven names and is deliberately not written up eleven times.** ZS +16.5249, TENB +16.5061, NTSK +15.6463, RBRK +15.6376, SAIL +15.3132, QLYS +15.0586, CRWD +13.8531, PANW +13.0924, OKTA +11.9820, NET +7.7741, PATH +6.6182 — all confirmed, **all clearing the legacy 5% bar**. Two are surfaced as representatives and nine are recorded in `rejected_notable`, where each is a `rule_only` disagreement. That is why this screen's `rule_only` count is 9: Layer-2 judgment overriding Layer-1 magnitude, which is the conversion working as designed. One rejection is flagged as the least clean — **NET**, because some reporting ties its move to a specific OpenAI security partnership rather than to the sector bid, which would make it a distinct event; not resolved this run.

> **THIRD-PARTY PRICE DATA WAS MEASURABLY WRONG ON THIS TAPE, TWICE, IN OPPOSITE DIRECTIONS.** A discovery pass reported **ORCL at −3.7%** (true: **−13.7912%**) and **SMCI at −8.4%** (true: **−0.8739%**, which does not clear the 2% rail at all and is correctly excluded). Taken on trust, this screen would have buried the largest mega-cap move of the day *and* manufactured a phantom one. A third instance: FMP's `price` for ORCL read 144.72 against the true 141.71 close — a 2.1% after-hours gap — while its GEV/CRWD/ISRG prices matched the closes exactly, i.e. the divergence appeared specifically as an after-hours print on the one name that moved most. This is the clearest vindication of the §19 PRICE BASIS rule the screen has recorded.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (§19)

**Full measured board (all 11 GICS sector ETFs, IBKR daily bars):** XLC +2.1936, XLV +1.4452, XLP +1.2473, XLY −0.0974, XLF −0.3843, XLRE −0.6911, XLB −0.9029, XLE −0.9365, XLU −1.3447, XLI −1.4155, XLK −1.8064. **Rail_tally 6** (clearing ±1%), **surfaced 5**, `universe_measured` 11.

- **XLK −1.8064% (conv. 75)** — the AI-capex repricing at its source. Ranked first not on magnitude but on regime relevance: it is the price-stage form of the mechanism named verbatim in an open position's own invalidation criterion.
- **XLC +2.1936% (60)** — the **only** legacy-rule pass. The receiving side of the same rotation, but driven substantially by GOOGL as a single dominant weight, which is why it sits below XLK.
- **XLU −1.3447% (60)** — two independent causes converging: a 10Y at 4.97 hitting a bond proxy (XLRE −0.6911 moved with it), *and* the AI-datacenter power trade inside it falling far harder than the sector (Constellation −3.91, Vistra −2.43).
- **XLV +1.4452% (45)** — the defensive bid, written up as representative of the XLV/XLP pair. Low conviction: a ~1.4% defensive bid on a −0.45% tape is ordinary.
- **XLE −0.9365% (60)** — a **sub-net escape-valve surfacing and the most anomalous item on the board.** Energy equities **fell** while Brent **rose** 1.0229% on a physical supply disruption: XOM −0.5482, CVX −0.8829, OXY +0.5207, RIG −3.8801, each individually confirmed. The premarket "energy rallies on the oil spike" story did not survive the close. The reading that fits: the tape priced this shock as a **rates and demand-destruction** event rather than an energy-earnings event — consistent with the 10Y going through 5% the same session.

Rejected: **XLI −1.4155** and **XLP +1.2473** — both cleared the ±1% rail, both rejected as double-counting causes already carried by XLK and XLV respectively. Neither passes the legacy 2% bar, so neither is a `rule_only` disagreement.

### 5. Notable commentary

- **The Amodei essay and the responses to it** (Development 1b) are themselves the dominant commentary of the window.
- **Sell-side Fed calls shifted hard into Wednesday:** Goldman Sachs **reversed** its prior no-hike call to expect a 25bp September hike; UBS forecasts 25bp in **both** September and December, citing Chair Warsh's hawkish Jackson Hole tone; Barclays and MUFG separately flagged September + December.
- **No Fed speeches occurred** — the FOMC is in its pre-meeting blackout.
- **SRRK follow-up (completing the prior run's open item).** Scholar Rock's FDA approval of **Isembyld** (apitegromab-mstn, spinal muscular atrophy; FDA "Novel Drug Approvals for 2026" #39) was an **after-hours 09-11** event, so 09-14 was its true close-to-close reaction day. It **gave back the entire approval pop and more** — −6.4249% — on broad risk-off rather than any adverse company news, while four brokers *raised* targets the same day (Citi $74, Truist $76, BMO $76, Raymond James $72). The company held an 08:00 ET investor call and filed a corresponding 8-K; no safety signal or label walk-back. **It also resolves the prior run's reported measurement failure:** SRRK priced on the **first** attempt here using `contract_id` **319099332**, two digits from the **319099330** cited in that 14-failure record.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

**MECHANICAL EXIT-TRIGGER SWEEP — run for every open position. NO EXIT TRIGGERED.**

The union of `state.current_positions` and live `get_account_positions` is **exactly 12 tranches across 8 names, all Strategy D**, and the two sides agree share-for-share (AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.1550, UBER 0.5156). **No position exists in the connector that is missing from BigQuery**, so no RECONCILIATION-LAG position exists and no `position_reconciliation_lag` alert is owed. The only other connector holdings are the park sleeves (VOO 10.8278, SGOV 74.8667).

- **Convergence targets:** `NULL` on all 12 tranches. No convergence exit is possible.
- **Time-based exits:** `time_exit_date` `NULL` on all 12. No time exit is due.
- **Price-level criteria / dividend netting:** **not engaged, verified rather than assumed.** `state.price_level_criterion_drift` returns exactly one row (D:DIS:2026-08-05) and it is a non-case on its own fields — `is_exit_criterion=false`, `actionable_price_level=false`, `has_dividend_drift=false`; the "45.00" it matched is the CaR *notional* quoted in that tranche's `not_exit_triggering` text, not a price level. **Zero actionable price-level exit criteria exist across the open book**, so no price test was reported as met anywhere in this sweep.

**PER-STRATEGY KILL-TRIGGER SWEEP — no trigger fired.**

`perf.kill_flags` carries D as of 2026-09-11 (D2a has not yet run today): `drawdown_kill` FALSE, `runaway_review` FALSE, `m2m_underperf_review` FALSE, `gate_reached` FALSE, `interim_underperf_warning` FALSE. **Drawdown refreshed unconditionally against today's live marks**, as required: D's deployed book fell **−1.5286%** today (548.4774 → 540.0937 on shares × IBKR closes), taking deployed unit value from 1.06818939 to ≈1.05186 against a peak of 1.098110312 — a refreshed drawdown of **≈−4.21%**, against a −50% kill bar. Not close by two orders of magnitude. (This is an approximation: the engine's TWR also reflects cash and flows. The conclusion is robust to that.)

- **Interim underperformance:** D shows `excess_vs_sgov` **+5.36%** at 96 deployed days — the warning needs ≤−15%, so it is FALSE and no alert is owed. No open alert of this category exists to heal-resolve.
- **B pairwise-correlation control:** `analytics.b_pairwise_correlation` returns `n_positions = 0`. **Strategy B holds nothing**, so the check is inert (needs ≥2) and no `b_pairwise_corr_high` alert is raised.
- B's `perf.kill_flags` row is stamped 2026-08-18 and stale **because B has no open positions** — expected, not a defect.

**THESIS-INVALIDATION ASSESSMENT — the four movers that matter.**

**GEV −8.6189% — NOT INVALIDATED, and the reasoning is the point.** GEV's declared primary trend metric is *total-company organic orders growth YoY* (entry-quarter reading 88%, prior quarter 71%), invalidating only **below 15% for two consecutive quarters**, with auto-invalidation if that metric stops being disclosed comparably for two quarters. **Nothing today touches it:** GEV issued no guidance, no orders figure and no backlog revision; its last reported numbers (Q2 2026 — orders +88% organic, backlog $176B) stand unrevisited; next data point is the **Q3 print on 2026-10-28**. The dominant driver was a **GLJ Research Sell initiation at $470** whose argument is *forward backlog margin* — ~3 points on the 2027 delivery vintage booked in 2024 ahead of price increases, against 10–11 points on the 2025 vintage, putting GLJ's 2027 EBITDA at $7.42B against ~$9.45B Street. Stacked on that was a genuine sector repricing (Vertiv −7.41, Eaton ~−7, Quanta ~−4, Constellation −3.91, Vistra −2.43). Two of the candidate explanations are on this tranche's own explicit *not exit-triggering* list anyway — **Wind-segment deterioration** (no evidence found today) and **tariff-guidance revision** (no evidence found today) — and **short-term price action** is named outright. **Criteria UNBREACHED. No exit.**

> **Worth carrying forward, and recorded because `Daily.md` is overwritten tomorrow:** GEV's four frozen criteria are keyed to orders growth, disclosure comparability and Wind, and contain **no margin term at all**. GLJ's thesis is therefore a bear case in a dimension this position's invalidation machinery cannot test, confirm or refute. That does not invalidate anything — the criteria are immutable for the tranche's life by design — but it is exactly the kind of finding **M3 (D Position Deep-Dive)** exists to weigh. It is carried durably in this run's `add-candidate-review` decision-log row.

**TSM −3.5153% — NOT INVALIDATED, but this is the criterion to watch.** TSM's criterion 3 names *"structural AI-capex reset (hyperscaler/Nvidia order cuts; CoWoS utilization drop)"* — and today's dominant narrative was precisely a call to slow AI capex. **Criterion 3 is NOT met:** it requires a structural reset evidenced by *actual order cuts* or a *CoWoS utilization drop*. What occurred was three executives arguing for pacing. No hyperscaler cut an order; no utilization figure moved. Criteria 1 (GM <55% or USD rev YoY <15% for 2 consecutive quarters) and 2 (N2/A16 pushout or sub-7nm share decline) are untouched — the 07-29 tranche measured GM 67.7%, USD rev +33.7% YoY, sub-7nm mix 77% and rising, FY26 capex guide **raised**. **The honest statement is that today is the first observable event in criterion 3's causal chain, at narrative stage only.** That is a watch item, not an exit. Secondary and non-event: TSM goes ex-dividend 2026-09-16 ($1.114), so some of the move is ordinary pre-dividend positioning.

**GOOGL +3.2171% — no criterion engaged.** A rotation-driven gain (out of AI capex, into hyperscalers), not new information about Cloud revenue, operating margin or RPO. All four criteria remain unbreached.

**ISRG +2.3814% — no criterion engaged, driver unestablished.** The only same-day company item was a CE-mark approval for da Vinci SP in Europe (transvaginal gynaecologic indication) — minor, region-specific, and not plausibly a 2.4% move in a ~$134B name on its own. **Recorded as unexplained rather than narrated.** Criterion 4 (a competitor disclosing displacement of da Vinci at named large IDNs) shows no evidence today.

**The remaining four names** — AMZN −1.2618%, DIS +1.91%, RTX −1.1836%, UBER +1.3393% — all moved below the screen rail on no company-specific development, and no criterion is engaged on any of them.

**Watchlist candidates:** no development in this window materially changes the candidacy status of any queued name. The Strategy A queue (17 pending names) is unaffected — A remains `DO-NOT-ACTIVATE`.

---

## ANALYSIS — OPPORTUNITY CHECK

Scoped to roster-active strategies with `review_cadence: reactive` — currently **A, B, C, E** (D is excluded via `long_horizon`). **No new entry candidate is routable this session.**

- **Strategy A** — `DO-NOT-ACTIVATE` (router, as of 2026-09-03). Not routable.
- **Strategy B** — `DO-NOT-ACTIVATE`. Not routable. Worth stating explicitly: this tape produced an unusually rich crop of B-*shaped* names — ORCL −13.79%, SIMO −16.76%, ZS +16.52%, NOK −13.30%, CRWD +13.85% and six more all cleared B's frozen ≥5% close-to-close Entry criterion 1 on a dated public event. **None is routed**, because the router gates entry. The durable capture is the `research-screen` decision-log row written this run, which W2 consumes for post-event enrichment — that is the designed path, and duplicating it onto the watchlist would add nothing.
- **Strategy C** — `HYBRID ACTIVATE (FOMC-only)`, the one active lane, and there **is** a qualifying catalyst inside 45 days: the FOMC on **2026-09-15/16**. **No new candidate is created**, because C's FOMC lane is already queued as `thesis-FOMC-C-20261020` (pending, created 2026-09-13) and this week's meeting is inside its blackout. Noted for the owning routine rather than acted on: `ops.alerts` `c144d35f` (W5, 09-08) records that C has now failed FOMC entry criterion 2 on **five consecutive drains** and has never deployed capital — a ~92%-priced hike is exactly the kind of low-uncertainty setup that tends to fail criterion 2 again.
- **Strategy E** — `DO-NOT-ACTIVATE`. Not routable. The 4.0000pp cross-sector spread is the widest in a week and is the shape that generates intra-industry-group pair candidates; recorded as context for M2's monthly screen, not routed.

---

## ANALYSIS — ADD-CANDIDATE CHECK (A / B / D only)

**12 tranches evaluated · 0 flagged · 3 declined at the HARD GATE (ISRG, RTX, UBER).** All 12 are Strategy D; zero A and zero B positions are open. Logged durably as one `add-candidate-review` decision-log row including **every decline**.

| Tranche | Mark vs cost | Evaluable | Disposition |
|---|---|---|---|
| D:RTX:2026-04-27 | **+10.4250%** | ✗ | `declined_hard_gate` |
| D:ISRG:2026-07-20 | **+8.1341%** | ✗ | `declined_hard_gate` |
| D:GOOGL:2026-07-26 | +6.5722% | ✓ | declined |
| D:TSM:2026-07-29 | +6.3956% | ✓ | declined |
| D:AMZN:2026-07-09 | +5.0968% | ✗ | declined (name covered) |
| D:DIS:2026-08-05 | +4.6295% | ✓ | declined |
| D:UBER:2026-07-09 | −0.7886% | ✗ | `declined_hard_gate` |
| D:TSM:2026-07-21 | −2.3025% | ✗ | declined (name covered) |
| D:DIS:2026-05-07 | −2.4515% | ✗ | declined (name covered) |
| D:GOOGL:2026-07-09 | −2.9062% | ✗ | declined (name covered) |
| D:AMZN:2026-07-30 | −4.5740% | ✓ | declined |
| **D:GEV:2026-08-03** | **−9.8098%** | ✓ | **declined — see below** |

`mark_vs_cost_pct` is the IBKR regular-session close over **that tranche's own** `cost_basis / shares`, never the account-level blended `avg_price` and never a snapshot mark.

**GEV is the one substantive decline.** It clears the HARD GATE and mechanically presents as textbook trigger (a) — a dip with a formally intact thesis. It is declined anyway, and the reason is the part worth keeping: the driver introduced a **specific, dated, credible bear case in a dimension the thesis has no criterion for** (forward backlog margin), and the first evidence capable of adjudicating it is ~6 weeks away at the Q3 print. That makes today a dip against a thesis that has just acquired an *unaddressed challenge*, not a dip against an *unchanged* one. Committing a fresh no-ceiling risk budget into an unresolved challenge on the day it appeared is not what trigger (a) is for. **This is a decision not to add — not a decision to exit; GEV remains held and unbreached.**

**TSM is declined for the mirror reason:** an add there would be buying into the exact mechanism its own criterion 3 exists to watch, on the first day that mechanism became observable.

**The HARD GATE gap, and what it cost this run.** Seven of the 12 tranches carry `breach_status = NOT_ASSESSED_BY_THIS_BACKFILL`, and **not one of the 12 carries a `$.status` key at all** — so the two-disjunct form of the evaluability rule would have returned TRUE for every position including the three it must catch, and the NULL-safety `COALESCE` wrapper is what keeps the healthy five reading TRUE rather than NULL. Both documented traps are live in this exact data and both were avoided. Four of the seven are covered at *name* level by a later tranche carrying a fresh assessment (AMZN, DIS, GOOGL, TSM); **three are covered nowhere — ISRG, RTX, UBER — and are structurally ineligible for an add on any evidence.** Note the cost: **RTX is the best-performing tranche in the book and ISRG the second**, and neither can even be considered, because a 2026-07-30 backfill transcribed their criteria without assessing them. This is the third consecutive sweep returning the same three names. The standing notice is `ops.alerts` `3daf511e` (`add_gate_uncovered_breach_status`, D1 2026-09-13), still open and owned by **M3**; no duplicate was raised.

---

## ANALYSIS — REGIME CHECK

**No router review recommended.** High bar, default NO on ambiguity, and this session does not clear it.

The recorded regime (as of 2026-09-01) is *decelerating growth + disinflation + hawkish tightening bias + risk-on + acute shock*. Today is **consistent with** that reading rather than a break from it: a hawkish-priced FOMC confirms `policy_stance = hawkish`; the Hormuz escalation continues `shock_overlay = acute`; the 10Y through 5% is a continuation of a trend already visible since 09-08 (4.80 → 4.97). The AI-pacing narrative is the one genuinely new element, and it is **narrative-stage**: it repriced equities along a rotation axis without yet changing any measured macro input.

**What could warrant one, stated so the next session need not re-derive it:** Wednesday's FOMC (2026-09-16) has not resolved. A hike delivered *with* hawkish projections, or a 10Y that holds above 5% afterward, would be a genuine change in the rates plane and is the most plausible route to an inter-monthly re-score. **M1R exists for exactly that**, and the correct posture today is to let the event resolve rather than to pre-empt it.

---

## EQUITY-BREADTH OBSERVATION

**$S5TH = 56.26 for the 2026-09-14 session** (56.46 → 56.26, −0.20pp). Written to `events.regime_events` as `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`, `as_of_date=2026-09-14`. The HEALTHY/WEAK threshold is D2a's to apply; this step writes the input only.

- **Source — Barchart `$S5TH` (the declared primary):** `https://www.barchart.com/stocks/quotes/$S5TH`, cache-busted `?cb=20260914`, obtained via **`tavily_extract`** after a `WebFetch` on the identical URL returned empty. Per the fetch-method rule, an empty/undated payload condemns *that fetch*, not the source — so Barchart is **not** recorded as rejected.
- **Date is SOURCED, not inferred.** The page states its own as-of session: *"Quote Overview for Mon, Sep 14th, 2026"*, with the quote line `56.26 -0.20 (-0.35%) 17:03 ET` — after the 16:00 ET close. **`date_attribution=sourced`**, and the post-close fallback is not invoked.
- **Previous Close read 56.46**, an exact match to the stored 2026-09-11 value. **No settlement revision to record this session.**
- **Second independent source obtained:** EODData `$S5TH` (fetched on **both** `WebFetch` and `tavily_extract`), dated history row *"14 Sep 26"* — Open 56.46 / High 57.25 / Low 56.06 / **Close 56.26**, an exact four-field match to Barchart. **Agreement 0.00pp**, far inside the 5pp no-write bar. The EODData settlement-lag tell was **checked and is absent** (Low 56.06 ≠ Close 56.26). Its separate header widget (`LAST 56.46 / PREV 56.46 / LOW 55.26`, stamped 14:08) contradicts the dated table below it and was **not used** — a pre-close snapshot, not the settled row.
- **MacroMicro was deliberately not attempted.** It is a weekly re-probe riding the **Sunday** D1 fire only; today is Monday, so no probe was due and none was spent.
- **Sources tried and REJECTED: none.**

---

## PARK ALLOCATION CALL

- **`vehicle`: VOO** — the majority sleeve at f=50 (the tie resolves to the risk sleeve). Not a claim the book is single-vehicle.
- **`target_f_pct`: 50** (risk sleeve VOO 50% / defensive sleeve SGOV 50%) — **unchanged**. `direction = keep`, **`status = BOUND`**.
- **`conviction`: MEDIUM, `conviction_pct` 60.**
- **`rationale`:** The session deteriorated and the call still does not move — that is the rule working, not the rule being ignored. **All six axes were measured same-session this run**, which is unusual and worth stating: volatility **DEFENSIVE** (VIX 17.10 > 20d SMA **15.505** and > 15); breadth **DEFENSIVE** (56.26 < 66); shock **DEFENSIVE** (`shock_overlay='acute'` **and** Brent 105.68 > 95); rates **DEFENSIVE** (10Y 4.97, +17bp over five sessions, above 5% intraday); index **NOT defensive** (SPY 760.88 vs 50d SMA **758.9384**, **+0.2558% above** — it fell today and still did not cross); credit **NOT defensive and improving** (HYG/IEF 0.8636313 vs 20d SMA 0.8582491 = **+0.627%** against a test needing −0.50%). **`standing_defensive_count` = 4, `firing_count` = 0** — every standing axis has been defensive since at least 09-11, and **a standing state is never news**, so the increase gate is shut on a mechanical fact rather than a judgment. Raw cap `LEAST(100, 25×4)` = 100; standing count ran 5 → 4 → 4 and both map to cap 100, so the **decay clause is inert** and the confirmed cap is 100 — binding nothing at f=50. **Conviction independently sizes to the same place:** 0.60 × 100 = 60, nearest ladder step **50** (|60−50|=10 vs |60−75|=15), so this is not merely gate-forced. The runner-up — an increase to f=75 — loses three ways: gate-ineligible, conviction-ineligible, and against the measured record (the allocator is **0-for-2** on closed defensive excursions in the AI era, −2.841pp and −1.019pp, and the 15-episode historical defensive signal has mean forward edge −0.638pp winning 4 of 15). The other runner-up, a re-risk to 25, is always permitted and never delayed, but today's evidence moved the wrong way for it. **Crisis override not engaged** (−0.4461% vs the −2.5% bar; VIX 17.10 vs the 28 bar). **`fields.axis_overrides` is empty:** my hand-scoring and `state.park_axis_daily` agree on every axis verdict — the panel's four price axes carry `measured_on = 2026-09-11` while mine are today's, so the fresher vintage strengthens rather than contradicts it. Independent confirmation from the connector: VOO $7,576.21 / SGOV $7,525.83 puts **actual f at 49.83%** against a 50% target.
- **`invalidation` (symmetric — one axis-crossing event, either direction):** **To INCREASE f** — any single axis *entering* defensive, most plausibly index (SPY closing below its ~759 and rising 50dma) or credit (HYG/IEF falling 0.50% below its 20d SMA). One axis, one session, no confirmation period, because standing count is already 4 and the gate's second limb is met. **To DECREASE f** — any single axis *exiting* defensive, most plausibly volatility (VIX back below its 20d SMA and below 15) or rates (the 10Y retreating toward ~4.80 post-FOMC), at the same conviction. Deliberately symmetric: the 2026-07-26 directive retired every anti-churn rail and named next-session reversibility as the compensating control, and a re-entry bar harder than the exit bar would quietly remove it.
- **`theater_check`:** The rationale argues for no change, which is the cheapest thing to write, so the test is whether it would have said otherwise on different evidence. It would: had volatility or index crossed *today* rather than a week ago, the same arithmetic (conviction 60 × cap 100 → step 75) produces a de-risk. The independent tell that this is not a foregone conclusion is that two axes came back **NOT defensive** on a day the tape fell and VIX rose 8% — the day's mood was not allowed to score the axes.

---

## RECOMMENDED ACTIONS

**No recommended actions.**

No exit was triggered on any of the 12 open tranches; no add candidate was flagged; no entry candidate is routable while A/B/D/E sit at `DO-NOT-ACTIVATE` and C's only active lane is already queued; no watchlist change is warranted; and the regime check defaults to NO with Wednesday's FOMC unresolved. The park call is a bound KEEP, which D2's conversion step no-ops by design.

```yaml d1_actions
[]
```
