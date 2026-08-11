2026-08-11
<!-- d1_scan_through_utc: 2026-08-11T22:22:49Z -->

# Daily Market Development Scan — 2026-08-11 (Tue, MT)

**Scan window:** 2026-08-10 16:11 MT → 2026-08-11 16:22 MT (24.2h). The prior-run marker `<!-- d1_scan_through_utc: 2026-08-10T22:11:29Z -->` parsed cleanly from the `Daily.md` on disk, cross-checked against that file's own commit at 2026-08-10T22:34:00Z (agree to within 23 min — the prior run's write-then-commit interval, not drift). `state.routine_catchup_window` reports `window_days = 0.98`, `never_completed = false` — cadence-normal, so no `CATCHUP` token is owed on this run's completion note.

**This window contains exactly ONE trading session — Tuesday 2026-08-11.** `state.trading_day_today` reads `today = 2026-08-11`, `is_trading_day = true`, `last_trading_day = 2026-08-11`.

**Tape (2026-08-11 regular session; every ETF/equity figure from IBKR regular-session `ONE_DAY` bars, `outside_rth=false`, denominator = the 2026-08-10 close):** SPY 770.56 (−0.32%, from 773.03), QQQ 718.45 (−0.34%), IWM 300.99 (+0.34%), equal-weight RSP 220.69 (+0.21%). VIX 15.28 (−1.16% from 15.46; FMP `quote` on `^VIX`, timestamped 2026-08-11T20:14:31Z — essentially the close, but a live quote rather than a dated EOD bar; D2a STEP 1d ingests the dated bar). Brent settled ~$88.91 (+1.4%, AP wrap). Gold roughly flat-to-firmer on a volatile up-then-fade session (~$4,430–4,440 area; no clean NY settle obtained — see MEASUREMENT GAPS). 10Y ~4.69 (≈−1 to −2bp), 2Y ~4.23–4.26, curve NORMAL at roughly +43 to +46bp — **the rates figures are a source-disagreement BAND, not a single sourced print, and are labelled as such deliberately.** hy_oas 2.85 (2026-07 monthly, latest available). Index cross-check via AP wire: S&P 500 7,728.20 (−0.32%, matching SPY exactly), Dow 53,791.85 (−0.34%), Nasdaq 26,445.45 (−0.60%), Russell 2000 3,027.12 (+0.32%).

**The one-line characterisation: yesterday's violent internal rotation collapsed into a quiet, broad, mildly-risk-off drift ahead of tomorrow's CPI, with one live geopolitical bid underneath it.** Top-to-bottom GICS sector dispersion fell from 5.95pp on Monday to **1.97pp** today, seven of eleven sectors closed inside ±0.5%, and the two sectors that did clear 1% (Energy, Utilities) are precisely the two you would expect on a Hormuz-escalation-plus-pre-CPI day. This is the mirror image of Monday: Monday was a flat index built out of a loud interior; today is a slightly-down index built out of a quiet one.

---

## TL;DR

- **Exits triggered: 1 — `B:ISRG` convergence target HIT.** ISRG closed **401.23**, through its 400 convergence target (intraday high 402.14, open 392.85). This is a mechanical exit under Strategy B — the target IS the exit rule, no judgment required. Yesterday's scan flagged it at 1.7% away; today it crossed. **D2 must craft the exit.**
- **New entry candidates: none new.** The 2026-08-10 Strategy-E candidate (FRO long / APA short) carries forward with a **material new input** — see OPPORTUNITY CHECK.
- **Add candidates: none flagged** (15 A/B/D tranches evaluated, 1 declined at the HARD GATE). **GOOGL was today's best-formed dip and it is declined on MERIT, not capital** — the first time in three sessions the binding constraint was the thesis rather than the wallet.
- **Watchlist changes: 2 adds** — ONON and TME to the Strategy B new-entry-candidate index (both router-blocked; B is DO-NOT-ACTIVATE).
- **Regime review flag: no review.** Nothing today plausibly moves a router activation state; `shock_overlay` is already `acute` and today's escalation sits inside it.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**ONE material event, and it is the day's organising fact.**

**Trump asserts "100% US control" of the Strait of Hormuz, announces a 20% transit levy on cargo, and makes war-reparations-style compensation a precondition for further talks.** Speaking from the Oval Office (reported Monday 2026-08-10, carried through Tuesday), the President said "The only one that has control of the Strait of Hormuz right now is the United States Navy. We have a blockade that's been infallible… a steel wall," claimed US minesweeping had cleared Iranian mines, and said he would levy a 20% transit fee on commercial cargo. He also instructed negotiators to demand compensation from Iran in any future talks. Iran disputed the claim, asserting that it and Oman retain sovereignty over the strait and refusing to fully reopen it absent sanctions relief and war-damage payments.
Sources: [CBS News live updates](https://www.cbsnews.com/) (published/updated 2026-08-11 03:18 EDT); [Al Jazeera, 11 Aug 2026](https://www.aljazeera.com/) (Hancock/AFP/Reuters); San.com.

**Observable reaction, by asset class:**
- **Oil:** Brent spiked +1.81% to ~$89.25 in early Tuesday trade on the "control" comments (CNBC), swung between $87 and $90 intraday, and settled **+1.4% at ~$88.91** (AP).
- **Equities:** AP's wrap attributes Tuesday's declines directly to the intensifying US-Iran standoff. S&P −0.32%, Dow −0.34%, Nasdaq −0.60%; Russell 2000 bucked it at +0.32%.
- **Gold:** spiked to a ~2-month intraday high near $4,495 (+1.7%) on hopes the comments signalled a path to reopening, then faded to ~$4,440 as oil turned back up (mining.com, 10:51 ET).
- **Rates:** yields rose early (10Y +3bp) on the oil-inflation channel, then eased into the close.

**Why this is more than a headline, and why it did NOT change the park call:** a 20% transit levy is a *concrete economic imposition on the chokepoint itself*, not rhetoric — it is qualitatively different from the strike-and-counterstrike news flow that produced the `acute` overlay in the first place. But the measured market transmission today was a +1.4% Brent move and a −0.32% index, and **VIX FELL 1.16%**. The vol market is explicitly not pricing this as stress. Both halves of that are recorded because they point in opposite directions.

**Explicitly checked and empty:** no material bankruptcy filing dated to this window; no disaster affecting global risk assets; no unscheduled regulatory or enforcement action against a specific issuer dated to this window (the Alphabet decline was investigated separately and is an accumulation of ongoing items — see §3).

### 2. Scheduled events that resolved in the window

**Earnings (US-listed, ≥$2B).** Every price reaction below is an IBKR regular-session close-to-close move, `outside_rth=false`, 08-11 vs 08-10 — **several diverge materially from the figures news outlets reported, and the IBKR number governs**:

| Name | Print | Outcome vs consensus | **IBKR cc move** | News-reported figure |
|---|---|---|---|---|
| **ONON** (On Holding, ~$13B) | Tue BMO | Adj EPS $0.35 vs $0.44 (miss); net sales CHF 850.3M, +21.6% cc; **FY26 growth guide cut to low-20s from ≥23%**; GM outlook raised | **−20.29%** (38.78→30.91) | "−20 to −22%" ✓ consistent |
| **SE** (Sea Ltd, ~$70-80B) | Tue BMO | Revenue $7.805B vs ~$7.27-7.34B (beat ~+7%); EPS contested adj-vs-GAAP across sources | **+14.56%** (114.80→131.51) | "+9% to +13.6%" — **understated** |
| **TME** (Tencent Music, ~$20B) | Tue BMO | Non-IFRS diluted EPS RMB1.70 vs RMB1.62 (**beat**); revenue $1.32B, +11.9% | **−11.92%** (9.90→8.72) | "−12.7% pre-market" ≈ consistent |
| **CAH** (Cardinal Health, ~$40B) | Tue | Q4 non-GAAP EPS $2.91 (+40% YoY) vs ~$2.42 (beat ~+20%); upbeat FY27 outlook | **+1.30%** (237.18→240.26) | "**+7% to a 52-week high**" — **badly overstated** |
| **ALC** (Alcon, ~$45B) | Tue | Adj EPS $0.84 vs $0.75-0.76 (beat ~11%); FY26 core EPS growth guide raised to 12-15%; $402M PowerVision charge | **+2.34%** (73.63→75.35) | "+4% to +5.7%" — **overstated** |
| **SPG** (Simon Property, ~$60B) | Mon AMC | RE FFO $3.29 (+7.9%, beat +3.5%); GAAP EPS $0.29 vs $1.69 (large miss, one-timers); FY26 FFO guide raised | **−0.46%** (220.55→219.53) | not reported by sources |
| **RIOT** (Riot Platforms, ~$8.1B) | Mon AMC | EPS −$0.68 vs −$0.303 (miss); revenue $174.2M vs ~$153M (beat) | **+4.33%** (19.40→20.24) | "**+17% to +20%**" — **badly overstated** (intraday high $23.65) |

**This table is the day's most important process finding and it is worth stating plainly: on six of seven names the news-reported reaction and the exchange-measured reaction disagreed, twice by more than 5 percentage points, and in every disagreement the news figure was the more dramatic one.** CAH was reported as a +7% breakout to a 52-week high and closed **+1.30%**. RIOT was reported as a +17-20% surge on a genuinely large contract and closed **+4.33%**. This is exactly the failure mode Operating_Protocols.md §19 PRICE BASIS exists to prevent, and it fired on more than half the sample in a single ordinary session. Nothing downstream should ever consume a reaction figure this file did not measure from IBKR bars.

**Economic data.** **NFIB Small Business Optimism (July, 06:00 ET)** rose to **99.8**, +2.4 points, best since August 2025, above the 52-year average of 98.0; hiring-plans component at its highest since October 2022; Uncertainty Index +2 to 91 (vs 68 historical average). Consensus figure not obtainable — flagged rather than invented. Source: [NFIB](https://www.nfib.com/news/press-release/new-nfib-survey-small-business-optimism-continues-to-rise-11/).
**July CPI is NOT in this window — it prints Wednesday 2026-08-12 at 08:30 ET.** Multiple outlets characterised Tuesday's tape as defensive positioning into it. This matters to the park call below.

**FOMC / central banks: none in window.** July FOMC was 07-28/29 (resolved); minutes are not due until ~2026-08-19.

**FDA PDUFA / regulatory: none confirmed in window.** The most recent confirmed FDA actions (Tudriqev, melanoma, 08-06; mFLUSIVA and Orzeyful, narcolepsy, 08-05) all predate the window. Regeneron's garetosmab PDUFA is reported only as "August 2026" with no day-level confirmation and no evidence it resolved on 08-10 or 08-11 — recorded as an OPEN PDUFA, not a resolved one.

**Other scheduled catalysts: none** meeting the dated-resolution bar.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

**Layer-1 population rail** (mechanical cost bound, never a significance claim): US-listed, market cap ≥$2B, ≥2% close-to-close, attributable to an identifiable public event. **14 names cleared the rail.** Every figure below is IBKR regular-session `ONE_DAY`, `outside_rth=false`.

**Layer-2 judgment — 10 written up (conviction ≥45); 4 recorded rail-only at conviction 30 (PLUG +5.21%, SNAP +2.99%, ORCL −3.69%, ALC +2.34%).**

| Ticker | Move (cc) | Event | Conv. | `legacy_rule_pass` (≥5%) | Reason |
|---|---|---|---|---|---|
| **ONON** | **−20.29%** | Q2 sales miss + FY26 growth guide cut | **75** | TRUE | A 20% single-session repricing of a $13B name on a *guidance* cut, not a print miss, is a genuine narrative reset rather than a beat/miss reaction — the market re-rated the growth algorithm itself. |
| **HUBG** | **−19.75%** | Form 12b-25 (late 10-Q) + H1 business update, tied to the ongoing 2023-25 restatement | **75** | TRUE | Highest-significance move of the day *per unit of magnitude*: HUBG is a low-single-digit-daily-move freight name, so this is a multi-sigma event, and it is a **governance/accounting** event. Critically it is **NOT resolved** — see the B-eligibility note below. |
| **GOOGL** | **−3.84%** (357.52→343.80) | $25B senior-notes offering closed (2028-2066 maturities); federal appellate filings seeking to overturn the search-remedy order; DeepMind leadership churn (Hassabis to chairman, Jeff Dean departs); AI-capex margin concern | **75** | **FALSE** — `below_spec_floor` | **The clearest illustration this month of why §19 replaced a fixed threshold with judgment.** The smallest move in this table is the most significant one: ~3.8% of a ~$4T market cap is roughly $150B, GOOGL is a **currently-held D position**, and the antitrust leg sits directly adjacent to that position's named invalidation criterion 4. A 5%-floor screen would have discarded it entirely. |
| **LIF** | **−24.76%** | Q2: guidance held flat despite 38% revenue growth; GAAP EPS $0.08→$0.06; hardware target cut | 60 | TRUE | Largest move of the day, but LIF has a documented history of double-digit earnings-day swings, so the move carries less information per point than ONON's or HUBG's. |
| **SE** | **+14.56%** | Q2 revenue $7.805B, ~+7% beat; Shopee growth + profitability inflection | 60 | TRUE | Large, clean, on a $70-80B name — and **+5pp larger than any source reported**. |
| **TME** | **−11.92%** | Q2 non-IFRS EPS **beat** (RMB1.70 vs 1.62), stock fell hard | 60 | TRUE | A double-digit decline **on a beat** is the highest-information pattern in this list: the market rejected something in the guidance or margin commentary that the headline numbers concealed. |
| **P / Everpure** | **+11.64%** | Dual upgrade (Susquehanna Positive PT $120; Morgan Stanley Overweight PT $108) + hyperscaler design win / supply agreement | 60 | TRUE | Double-digit day on a normally 1-3%/day large-cap; the design win is the substance, the upgrades are confirmation. |
| **RIOT** | **+4.33%** | **20-year, 191MW Anthropic data-centre lease, ~$9.1B contracted revenue through 2048** | 60 | **FALSE** — `below_spec_floor` | The inverse of GOOGL: here the *event* dwarfs the *move*. Contracted revenue on the order of the entire market cap, and the stock closed up 4.3% after spiking to $23.65 intraday. The move understates the news; the news is what matters. |
| **UAA** | **−9.03%** | Q1 FY27 revenue miss ($1.10B vs $1.11B, EPS beat); FY guide cut to mid-single-digit revenue **decline**; Curry partnership ending | 45 | TRUE | Discounted because UAA has cut guidance repeatedly through 2026 — this is continuation of a known deterioration, not new information. |
| **NOK** | **+3.40%** | AI-RAN platform launch with Nvidia Aerial; €2.8B AI & Cloud order book (>2x YoY); possible FCC ban on Chinese optical transceivers; BofA PT to $18.50 | 45 | **FALSE** — `below_spec_floor` | NOK typically moves <1%/day; 3.4% is a 3+ sigma session for this name, and the order-book datapoint is concrete. |

**Verified-and-rejected (the screen's most valuable output today).** Two names carried loud headlines that did not survive measurement, and both were correctly excluded:
- **RKLB (~$50B)** — "falls 9%+ premarket" on Neutron timeline slippage. IBKR bars: 80.04 → 80.01, **−0.04%**. Did not clear the 2% rail at all.
- **RIOT** — headlines said +17-20%; measured +4.33% (see above).

**Recorded, no identifiable event, therefore below the rail's own attribution requirement:** SMR +7.73%, CVNA −2.91%, KVYO +2.74%, PINS −2.54%, FCX −2.33%, BX +3.89% (AI-infra sympathy, earnings were 07-23), DELL −3.69% (accumulated PT-cut/insider overhang, no fresh 08-11 catalyst). **AMZN −2.09%** is treated the same way: one WebSearch found no adverse Amazon-specific catalyst; coverage attributes it to post-earnings/post-$3T-rally profit-taking. This matters for the ADD check below.

**Sub-$2B, screened and excluded on the cap floor:** UPWK (−20%, ~$1.16B), BBAI (~$1.76B), NUTX, OPFI, TTEC, GETY, SEPN, ACB, TISI.

**A `research-screen` decision_log row (screen='single-name-move') is written for this screen per §19's logging contract.**

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

**Layer-1 rail:** any GICS sector ≥1% at sector-ETF level, or notable intraday dispersion. All figures IBKR `ONE_DAY`, `outside_rth=false`, 08-11 vs 08-10.

| Sector ETF | 08-10 | 08-11 | % chg |
|---|---|---|---|
| XLE Energy | 60.18 | 60.93 | **+1.25%** |
| XLU Utilities | 43.13 | 43.63 | **+1.16%** |
| XLI Industrials | 184.60 | 185.70 | +0.60% |
| XLB Materials | 53.18 | 53.24 | +0.11% |
| XLF Financials | 57.81 | 57.80 | −0.02% |
| XLK Technology | 186.32 | 186.09 | −0.12% |
| XLV Health Care | 168.44 | 168.01 | −0.26% |
| XLP Cons. Staples | 84.95 | 84.69 | −0.31% |
| XLY Cons. Disc. | 119.67 | 119.24 | −0.36% |
| XLC Comm. Svcs | 111.83 | 111.27 | −0.50% |
| XLRE Real Estate | 44.40 | 44.08 | −0.72% |

**Top-to-bottom dispersion 1.97pp** (vs 5.95pp Monday). **The dispersion arm of the rail does NOT fire** — 1.97pp is unremarkable, and saying so is the honest reading rather than manufacturing a signal from a quiet cross-section.

**Two sectors surfaced, both judged significant despite BOTH failing the legacy ≥2% bar:**

- **XLE +1.25%** — `legacy_rule_pass=FALSE`, `metric_pct=+1.25`. **Conviction 60.** Direct, attributable transmission of the day's one breaking event: Brent touched ~$90 intraday on the Hormuz impasse and settled +1.4%. The ETF's close-to-close gain is materially smaller than the intraday sector pop because oil pared into the close (WSJ: "Oil Turns Lower With Market Watching Hormuz Talks") — which is itself the informative part. Energy took the geopolitical bid and then gave half of it back on the same day the US claimed physical control of the chokepoint. That is a market declining to extrapolate.
- **XLU +1.16%** — `legacy_rule_pass=FALSE`, `metric_pct=+1.16`. **Conviction 45.** No discrete catalyst found. Read as a defensive-dividend bid on a −0.32% tape with yields easing into a CPI print, i.e. coherent pre-event positioning rather than a sector story. Discounted below XLE precisely because it rests on inference rather than an identified driver.

**Noted but NOT surfaced (below the 1% rail):** XLRE −0.72%, the day's laggard, moved *opposite* XLU despite both being rate-sensitive bond proxies. No REIT-specific 08-11 catalyst was found. Recorded as an observation because a utilities/real-estate divergence on a day yields eased is mildly incoherent, not because it clears any bar.

**A `research-screen` decision_log row (screen='sector-move') is written for this screen per §19, including the two surfaced entries.**

### 5. Notable commentary

**Sell-side:** one item worth flagging — **UBS (Andrew Jones) cut Steel Dynamics (STLD) to Neutral from Buy while simultaneously raising the price target to $276 from $165**, a >65% target increase alongside a downgrade. The combination is unusual enough to record even though the rationale could not be independently verified beyond aggregator reporting. William Blair initiated Standard Nuclear (STDN) at Outperform. Routine same-day target tweaks (NIQ, VSE, HIMS, MTDR, SI) are not material. No broad sector call from a bulge-bracket desk dated to this window.

**Central banks / regulators: none material in window.** Verified directly against federalreserve.gov's August 2026 calendar and speech index — the most recent Fed speeches were Governor Cook on 08-05 and 08-08, both **before** the window. No ECB/BoJ/BoE/Treasury item dated 08-10 or 08-11.

**Senior corporate commentary: none material in window** that is distinguishable from the earnings numbers themselves. Pfizer, Clorox and Pinnacle West all held calls on 08-11; no remark from any of them was reported as independently moving its stock.

**Tooling caveat carried forward:** `mcp__FMP__news`, `mcp__FMP__analyst` and `mcp__FMP__economics` all returned ACCESS DENIED (plan-tier gating) across three independent sub-agents this session. Commentary and event attribution therefore rest on WebSearch/Tavily with per-item URLs, not on FMP. **FMP was not "checked and found empty" — it was unavailable.** This is a recurring, structural gap in this routine's evidence base, not a one-session blip.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP

Swept the **UNION** of `state.current_positions` (15 tranches) and live `get_account_positions` (11 broker rows). **Reconciliation is clean — every strategy position in the broker book aggregates exactly to its BigQuery tranches**, so there are **no RECONCILIATION-LAG positions and no `position_reconciliation_lag` alert is due**: AMZN 0.3464 = 0.1554+0.1910 ✓ · DIS 0.7244 = 0.2822+0.4422 ✓ · GOOGL 0.2577 = 0.1043+0.1534 ✓ · ISRG 0.2479 = 0.1388(B)+0.1091(D) ✓ · TSM 0.1550 = 0.0891+0.0659 ✓ · CRM, GEV, MSCI, RTX, UBER all single-tranche exact. `get_account_orders` returns an empty list — no open or pending orders.

**EXIT TRIGGERED — 1.**

> **`B:ISRG:2026-07-21` — CONVERGENCE TARGET HIT.** Convergence target **400.00**; ISRG closed **401.23** on 2026-08-11 (IBKR `ONE_DAY`, `outside_rth=false`; open 392.85, high 402.14, low 392.22, volume 2,546,342 — a full session held above the target, not a wick). Live after-hours print 400.56, also through the target. **This is mechanical — the target IS the exit rule per Strategy B; no judgment applies and none was exercised.** Position: 0.1388 sh, cost basis 48.921957 (352.46/sh), mark-vs-cost **+13.84%**. Yesterday's scan flagged this position as sitting 1.7% below its target and named it as the watch item for D2; it crossed the next session. **D2 converts this into a crafted exit order.**
> **Cross-strategy note:** ISRG is also held in Strategy D (`D:ISRG:2026-07-20`, 0.1091 sh, +14.80% vs cost, no convergence target, no time exit). The B exit does **not** touch the D tranche — D positions run to thesis-invalidation, and after the B exit clears, ISRG is held solely by D. No simultaneous-holding constraint is engaged by an exit.

**Time-based exits: none due.** The only two dated exits in the book are `B:ISRG:2026-07-21` → 2026-09-18 and `B:MSCI:2026-07-27` → 2026-09-25, both comfortably ahead. (ISRG exits today on convergence, ~5 weeks before its time exit.)
**Other convergence targets: not hit.** `B:MSCI:2026-07-27` target 615.00, closed **561.71** — 8.7% below target, and it moved *away* today (−0.24%). No Strategy D tranche carries a convergence target by design.

### PER-STRATEGY KILL-TRIGGER SWEEP

`perf.kill_flags` as of 2026-08-10 (D1 runs before D2a, so the engine row is yesterday's close), with `current_drawdown` **unconditionally refreshed against today's live marks for every open position, as required — this refresh is not conditioned on any judgment about whether the tape moved.**

| Strategy | deployed_unit_value | peak | drawdown (engine) | drawdown (refreshed on today's closes) | excess vs SGOV | deployed_days | closed trades / gate | Flags |
|---|---|---|---|---|---|---|---|---|
| **B** | 1.191459 | 1.191459 | 0.00 | **0.00 — still at peak** (B book +9.4% vs aggregate cost on today's closes) | +17.90% | 73 | 11 / 19 | all FALSE |
| **D** | 1.092373 | 1.092373 | 0.00 | **0.00 — still at peak** (D book +6.3% vs aggregate cost on today's closes) | +8.09% | 73 | 0 / 30 | all FALSE |

- **Drawdown kill (#1):** NOT triggered. Both strategies sit at their peak unit value; the ≥50% peak-to-trough threshold is not remotely approached.
- **Runaway-success (#3):** NOT triggered. Neither strategy has doubled (B 1.19x, D 1.09x), and neither has cleared its trade gate.
- **Interim underperformance warning:** `interim_underperf_warning = FALSE` for both. **HEAL-RESOLUTION CHECK RUN:** no open `interim_underperf_warning` alert exists for either strategy, so no resolve is owed.
- **A / C / E:** no deployed capital, hence no `perf.kill_flags` rows and no kill evaluation possible. Recorded explicitly so that "no row" is never later misread as "no risk measured."
- **B open-book pairwise correlation (KL #12 control):** `analytics.b_pairwise_correlation` returns `n_positions=2, n_pairs=1, avg_offdiagonal_corr=NULL, min_overlap_days=NULL`. The single ISRG/MSCI pair has insufficient qualifying overlap history (<40 days) to produce a non-noise correlation, so the view correctly returns NULL and **the alert condition fails on the NULL — no `b_pairwise_corr_high` alert is due.** Note this becomes a genuine no-op again tomorrow: with ISRG exiting, B falls back to a single position.

### THESIS-INVALIDATION CHECK — do today's Developments trigger any judgment-laden exit criterion?

Every open position was checked against its own entry-record criteria. **One position had a development that reached its criteria; it did not breach them.**

**`D:GOOGL:2026-07-09` + `D:GOOGL:2026-07-26` — GOOGL −3.84%. NO INVALIDATION. Criterion 4 is engaged-adjacent and is now the position's live watch item.**
- inv_1 (Cloud rev YoY <20%, 2 consecutive Q) — **NO.** No cloud datapoint in this window.
- inv_2 (Cloud op-margin contracts 2 consecutive Q) — **NO.** No datapoint.
- inv_3 (Cloud RPO/backlog declines sequentially 2 consecutive Q) — **NO.** No datapoint.
- inv_4 (**adverse structural remedy**) — **NOT BREACHED, and this is the one that needs stating precisely.** What happened is that *federal enforcers filed appellate briefs seeking to overturn the existing search-monopoly remedies* in favour of harsher ones — specifically to prohibit the multi-billion-dollar default-distribution payments to Apple and Mozilla — while advocacy groups continue pressing for Chrome divestiture and ad-tech structural separation. **A filing is not a remedy.** The criterion requires an *imposed* adverse structural remedy, and none exists. The 2026-07-26 tranche's own record already designates this the "closest-watched" criterion (recorded there as `d_adverse_structural_remedy: unbreached (EU DMA 7/23 ruled behavioral, closest-watched)`), and today moves the probability distribution unfavourably without moving the criterion.
- inv_5 (metric-immutability, Cloud revenue reporting) — **NO.**
- The $25B debt offering and the DeepMind leadership churn (Hassabis to chairman; Jeff Dean departing) touch no criterion. They are real information and they are recorded; they are not exit triggers.

**All other positions: no development in this window reached any criterion.** AMZN −2.09% is profit-taking with no adverse company-specific catalyst identified and touches none of the five AWS criteria (all re-verified UNBREACHED against a six-quarter SEC-sourced series at the 2026-07-30 entry). ISRG +2.00%, TSM +0.86%, UBER +0.65%, DIS +0.34%, GEV +2.12%, CRM −0.02%, RTX −0.12%, MSCI −0.24% — all ordinary marks against intact theses, and ordinary adverse mark-to-market is explicitly on the "Not exit-triggering" list for D positions carrying one.

### WATCHLIST CANDIDATE STATUS

No queued name's candidacy materially changed. **GEV** (A queue, added 2026-08-09) closed +2.12% and is unaffected as an A candidate; it remains simultaneously a D holding, and A is DO-NOT-ACTIVATE so no simultaneous-holding conflict can arise. **TGT, DDOG, CRWD, AMZN, GOOGL, TSM, CRM** and the rest of the 41-name A queue saw nothing in this window that changes candidacy. The B watch-overflow names (META, RRX, BROS, DDOG, TDC, SEZL, RBLX) are unchanged and remain router-gated.

---

## ANALYSIS — OPPORTUNITY CHECK

Evaluated for every roster-active strategy carrying `review_cadence: reactive` in `strategy/roster.yaml` — **A, B, C, E** (D is excluded via `review_cadence: long_horizon`). Router states read live from `state.current_regime`: **A = DO-NOT-ACTIVATE, B = DO-NOT-ACTIVATE, C = HYBRID ACTIVATE (FOMC-only), D = DO-NOT-ACTIVATE, E = ACTIVATE.**

**No NEW entry candidate is raised today.**

**Strategy B — two names clear the entry gate on the numbers and are router-blocked; recorded to the index, not routed.**
Strategy B's frozen Entry criterion 1 requires **≥5% close-to-close on event day** (`strategy/04_strategy_b.md`; §19's spec-floor rail — that number derives from the frozen spec, not from a screen tune). Today's qualifying post-event movers:
- **ONON −20.29%** — resolved, dated, discrete earnings event; a guidance cut, information-driven. Clears criterion 1 decisively.
- **TME −11.92% on an EPS BEAT** — structurally the more interesting of the two, because a double-digit decline into a beat is the sentiment-vs-information divergence Strategy B is built to exploit.
- **SE +14.56%** — clears criterion 1 in the *up* direction, which would be a B SHORT. The B short-direction book has been declined at D2 repeatedly (SHOP, PYPL, CDW, MGM all in the declined-tracking index) and B is router-blocked regardless. Recorded as context only; not proposed.
- **LIF −24.76%, UAA −9.03%** — both clear criterion 1 numerically. LIF is discounted (habitual double-digit earnings swings dilute the signal); UAA is a continuation of a serially-cut guide rather than new information. Neither is proposed.
- **HUBG −19.75% — clears criterion 1 numerically and is explicitly B-INELIGIBLE.** Strategy B trades mean reversion after an event has *resolved*. HUBG's event is a Form 12b-25 late-filing notice tied to an **ongoing, unresolved 2023-25 restatement** — there is no resolved information set for the market to have over-reacted to, and the tail is open-ended. **This is a decline on mechanism, not on the router**, and it would still be a decline if B were ACTIVATE.
- **Disposition:** B is DO-NOT-ACTIVATE (binding, div-B-202607-1 resolved 2026-08-05; blocks NEW B entries only, existing positions run to their own exits). ONON and TME are therefore added to the **Strategy B new-entry-candidate index** in Watchlist.md, not routed for thesis construction.

**Strategy E — no new candidate; the 2026-08-10 candidate carries forward with a material new input.**
Yesterday flagged FRO (long) / APA (short) on a 12.26pp same-sector, same-day divergence. **Measured today (IBKR `ONE_DAY`, `outside_rth=false`): FRO 38.45 → 38.14 = −0.81%; APA 41.02 → 40.62 = −0.98%.** Both legs fell together; the spread moved **+0.17pp in the long leg's favour**, i.e. essentially nothing. Cumulative two-session divergence from the 08-07 base: FRO 39.74 → 38.14 = **−4.03%**, APA 37.63 → 40.62 = **+7.95%**, a **~12.0pp gap, statistically unchanged from yesterday's 12.26pp.** The divergence neither extended nor began reconverging.
**The material new input:** today's Hormuz development lands directly on the FRO leg, and it cuts **both ways** — a 20% transit levy is a new cost imposed on cargo through the chokepoint (bearish for transit volume), while a constrained chokepoint lengthens routes and lifts war-risk premia (historically bullish for tanker rates). **This is a genuine ambiguity, not a wrinkle**, and any thesis constructed on this pair must resolve it explicitly rather than assume the "chokepoint hardens → tankers win" direction the original divergence observation implied. Recorded here so the thesis-construction session inherits the problem rather than rediscovering it.
**No NEW E candidate today:** at 1.97pp of sector dispersion this was the least fertile day for pair divergence in over a week.

**Strategy A — no candidate.** No name in this window announced a qualifying catalyst within a 6-month horizon that is not already on the 41-name A queue. Router DO-NOT-ACTIVATE.
**Strategy C — no candidate.** C is HYBRID ACTIVATE (FOMC-only), and **no FOMC event resolved or was newly scheduled in this window** (July FOMC resolved 07-29; minutes ~08-19; no new meeting announced). C's scope cannot widen beyond FOMC-only absent a separate scope-widening adjudication whose conditions are nowhere near met. **Tomorrow's CPI is not an FOMC event and does not create C candidacy** — stating that explicitly because a hawkish-policy CPI print is exactly the kind of thing that invites scope creep.

---

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only — Rev 40)

**15 open A/B/D tranches evaluated across 10 names. 0 flagged. 1 declined at the HARD GATE. 14 declined on merit.**

**HARD GATE (checked first, per candidate):**

> **`B:ISRG:2026-07-21` — DECLINED AT THE HARD GATE, for two independent and individually sufficient reasons.** (1) The position **hit its convergence target today and is exit-triggered** — per the gate's own text, an add that would sit in exit territory "is NOT an add — it is an exit," and it is routed through RISK above. (2) `invalidation_criteria_evaluable = FALSE`: `JSON_VALUE(invalidation_status,'$.status') = 'NOT_DISCRETELY_RECORDED_AT_ENTRY'` — the honest marker `bigquery/117` wrote for the two Strategy B positions that recorded no discrete criteria at entry — so "unbreached" cannot be affirmatively confirmed from the mirror field regardless. Note that reason (2) alone would have declined it, exactly as the 2026-07-28 D:DIS/D:TSM precedent, and note that a plain `IS NULL` test would have wrongly reported this position as evaluable.

**All 14 other tranches clear the HARD GATE** — `invalidation_criteria_evaluable = TRUE` for every one, criteria enumerable and unbreached as evaluated in the RISK section above. They are declined on the merits of the add case, which is a different and weaker statement than the gate declining them.

| Position | mark vs cost | Trigger type | Disposition | Judgment |
|---|---|---|---|---|
| `D:GOOGL:2026-07-09` | −4.46% | none | declined | **Today's best-formed dip, and the first one in three sessions declined on MERIT rather than on capital.** A −3.84% session on a name whose thesis is fully intact is textbook dip-with-intact-thesis — except the dip is **not** content-free. Its largest single driver is federal appellate action aimed squarely at the position's own invalidation criterion 4. Adding into an escalating legal overhang that sits directly adjacent to a named invalidation criterion is not "adverse price action with no invalidation news"; it is adding while the probability of the criterion firing rises. **Decline, and watch criterion 4.** |
| `D:GOOGL:2026-07-26` | +4.87% | none | declined | Same name, same reasoning; additionally not a dip at all — up 4.9% on this tranche. |
| `D:AMZN:2026-07-09` | +12.86% | none | declined | −2.09% today with **no adverse company-specific catalyst** — genuinely content-free profit-taking after the $3T milestone, which is the cleanest dip *pattern* in the book today. Declined because 2% is ordinary noise on a name up 12.9%: the same "ordinary adverse mark-to-market" that is explicitly non-exit-triggering is, by symmetry, not an add trigger either. A trigger has to be a dip, not a wobble. |
| `D:AMZN:2026-07-30` | +2.48% | none | declined | Same; and this tranche is the 2026-07-30 add, filled into a post-print gap-up at 263.86. Adding again 12 days later at a higher price on a 2% dip would be chasing. |
| `D:DIS:2026-08-05` | −0.25% | none | declined | **+0.34% today and no new information whatsoever.** Yesterday's scan named this the best-formed case in the book; today it produced nothing new. A case that was already made and already deferred does not become stronger by being restated — declined for absence of a fresh trigger, not for weakness. |
| `D:DIS:2026-05-07` | −7.00% | none | declined | Parent tranche; same absence of a fresh trigger. Its five criteria were affirmatively re-passed at the Q3 FY26 checkpoint (SVOD margin ~13%, buyback target raised to ≥$9B, FY26/FY27 EPS growth reiterated) — the thesis is in good health, which is precisely why a mark 7% below cost is not distress. |
| `B:MSCI:2026-07-27` | −3.03% | none | declined | −0.24% today, drifting away from its 615 target rather than toward it. Criteria evaluable and unbreached (no analyst downgrade; no close below the 550.79 post-event trough; no further opex-guide escalation). A −3% mark five weeks into a mean-reversion position with a ~09-25 time exit is the thesis being *slow*, not the thesis being *cheap*. |
| `D:TSM:2026-07-21` | −1.36% | none | declined | +0.86% today; a 1.4% mark below cost is noise, not a dip. |
| `D:TSM:2026-07-29` | +7.43% | none | declined | Up; no dip. No new TSM information in window. |
| `D:GEV:2026-08-03` | +4.33% | none | declined | +2.12% today, up on the week; also newly on the A queue (2026-08-09) — no add trigger, and any A interest is router-blocked. |
| `D:ISRG:2026-07-20` | +14.80% | none | declined | Up strongly (+2.00% today). Note the book is *reducing* ISRG exposure today via the B exit; adding to the D tranche in the same session would work against that without a fresh D-specific thesis, and there is none. |
| `D:CRM:2026-07-09` | +23.14% | none | declined | −0.02% today. No new information; well in profit. |
| `D:RTX:2026-04-27` | +26.55% | none | declined | −0.12% today. Best performer in the book; no dip and no fresh conviction event. |
| `D:UBER:2026-07-09` | +7.28% | none | declined | +0.65% today. No new information. |

**PROCESS NOTE — the capital picture changed shape today, and it should be recorded before it is forgotten.** For two consecutive sessions this section reported that a merit-worthy add died on **capital** (`analytics.strategy_nav`: D `available_funds = 0`, B `available_funds = 0`, both fully deployed). That is still true — D holds $615.30 of deployed market value against $615.29 NAV with nothing free, and B holds $103.19 with nothing free, while C ($9,436.86) and E ($9,342.37) sit entirely undeployed and the park holds ~$15.4k in VOO. But **today the constraint did not bind, because no add cleared on merit anyway.** That distinction matters for anyone reading this series: three consecutive zero-add days do not have the same cause, and treating them as one trend would mis-attribute a thesis judgment (today) to a funding problem (the two prior sessions). The funding asymmetry is real and is a live question for capital allocation; it is simply not what stopped an add today.

**A single `events.decision_log` row (`entry_type='add-candidate-review'`) is written for this whole sweep, including all 14 declines**, per the 2026-07-30 decision-record audit — `n_evaluated=15`, `n_flagged=0`, `n_declined_hard_gate=1`.

---

## ANALYSIS — REGIME CHECK

**NO inter-monthly router review recommended.** High bar; default NO on ambiguity; nothing today clears it.

The candidate argument is the Hormuz escalation. It fails because **`shock_overlay` is already scored `acute`** (M1a, as_of 2026-08-01) on precisely this conflict — the ceasefire collapse, the strike waves, the 66-70% collapse in Hormuz transits, Brent +20.5% on the month. Today's development is an intensification *inside* a state the router already occupies, not a transition into a new one. A router review is warranted when a development would plausibly *change* an activation state; escalation within an already-maximal overlay cannot do that. The B and D DO-NOT-ACTIVATE calls are themselves produced by the `shock_overlay=acute` reconciliation override (Strategy.md:121), so a further escalation reinforces the current calls rather than challenging them.

The technical inputs are likewise stable: SPY_TREND UP (close 770.56 vs 50dma ~747.6 and 200dma ~703.5, both comfortably clear), VIX_REGIME NORMAL (15.28, unchanged band, and *falling*), SUSTAINED_INVERSION NOT-SUSTAINED (curve normal, positive spread). None is near a boundary — the VIX reading moved *away* from the 15.00 LOW boundary it narrowly crossed on Monday, in the direction of stability.

**The one thing that could warrant a review is tomorrow's CPI**, given `policy_stance=hawkish` with three FOMC dissenters arguing for a September hike and an energy-led July disinflation whose driver has already reversed. That is a *scheduled, dated, unresolved* event — reviewing the router today in anticipation of it would be exactly the pre-emptive-adjudication error the default-NO rule exists to prevent. **The correct action is to wait for the print, which D1 will see tomorrow.**

---

## EQUITY-BREADTH OBSERVATION

**NO `events.regime_events` ROW IS WRITTEN THIS RUN. This is a deliberate, reasoned suppression, not a fetch failure — and the reasoning matters more than the miss.**

**What was attempted:** eight sources across two agents plus direct fetches — Barchart `$S5TH` (WebFetch and Tavily-extract, both variants), MacroMicro series 22718 (WebFetch and Tavily-extract), StockCharts `$SPXA200R`, indexindicators, StreetStats, MarketInOut, Investing.com.

**What was actually obtained:**
1. **MacroMicro (source: S&P Dow Jones Indices LLC)** — a properly dated series. Its "Latest Stats" block reads, verbatim: **`2026-08-10 → 70.57 %`**, with the prior value **72.76%**. Its most recent available session is **2026-08-10** — it had not published an 08-11 value at fetch time (2026-08-11 ~22:20 UTC), consistent with a one-session publication lag.
2. **Barchart `$S5TH`** — the Tavily-extract returned the page's own header **"Quote Overview for Fri, Aug 7th, 2026"** with value **72.76**, i.e. the page state is stale at 08-07. A separate live WebFetch returned **71.17 labelled "(unch)"** with no resolvable session date.

**Why no row:**
- **No source produced a session-dated 2026-08-11 value.** MacroMicro's dated series stops at 08-10; Barchart's dated view stops at 08-07.
- **The one live number available (Barchart 71.17) is byte-identical to the value already recorded in this table for `as_of_date = 2026-08-10`, and the page labels it "unch".** Applying the post-close inference fallback to it would record an exactly-zero one-session change in a 500-constituent breadth metric on a day the index moved −0.32% with 1.97pp of sector dispersion. That is not a plausible measurement; it is a stale page. **The fallback exists to date a genuinely fresh undated value, not to launder a carried-forward one** — and this is precisely the case its "never let an inferred-date row silently look like a source-dated one" clause is guarding against. An absent row is honest; this one would not have been.
- Step 3's >5pp cross-check disagreement rule is **not** what suppressed the row — the two sources are only ~0.6pp apart. The row is suppressed for absence of a datable 08-11 observation.

**Consequence, stated so it is not a surprise downstream:** `events.regime_events` `TECHNICAL_INPUT`/`EQUITY_BREADTH_PCT` remains at `as_of_date = 2026-08-10` (71.17). D2a STEP 1e will therefore carry forward with `breadth_measurement_age_days = 1` and its staleness alarm handles the gap correctly — the threshold is 5 days, so one carried session is well inside tolerance. Classification stays HEALTHY on any value in this range regardless.

**CALIBRATION FINDING on the inference fallback itself — measured, and worth recording.** Yesterday's D1 wrote **71.17** for `as_of_date = 2026-08-10` via the post-close inference fallback, deriving it arithmetically from a source-dated 08-07 value of 72.76 and Barchart's stated −2.19% day change. MacroMicro's independently source-dated value for that same session is **70.57** — the inference was **~0.60pp high**. That is a small, tolerable error and it changed no classification (both are far above the HEALTHY ≥50 threshold), and the two series are different products (Barchart's `$S5TH` vs S&P DJI's), so this is not evidence the inference was performed incorrectly. It IS the first direct measurement of the fallback's accuracy against a dated alternative, and it is recorded here because a mechanism that has been used repeatedly with no error bar now has one. **No correction is made to the 08-10 row:** that step is idempotent on `(as_of_date, scope, key)`, D2a has already consumed the row and written its `TECHNICAL_SIGNAL` classification from it, and a 0.6pp revision that changes no classification does not justify breaking the idempotency contract. **Recommendation for a future cycle: prefer MacroMicro as the primary dated source and demote Barchart to the cross-check, accepting a one-session lag** — a dated value one session late is worth more than an undated value today, which is the whole lesson of this section.

---

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

One `hf_fs` paper-search query run, per the Tuesday rotation slot (**prompt injection**): `search hf://papers "indirect prompt injection robustness LLM agents" --limit 5`.

Five papers returned: 2505.05849 (AgentVigil), 2606.10525 (Automated Prompt Injection in Agentic Environments), 2601.04795 (Defense via Tool Result Parsing), 2602.07398 (AgentSys), 2606.15441 (RETA). **The most recent is dated 2026-06-13 — every result falls outside the scan window's ~24h lower bound (and outside the ~72h cap).**

**Verdict: nothing material. No `events.decision_log` capture is written and no `state.strategy_candidates` row is emitted.** Default-silent on ambiguity, as specified. No Daily.md action follows from this check.

---

## PARK ALLOCATION CALL

**Evidence gathered fresh this session** (a floor, not a ceiling): VIX 15.28 (−1.16%, FMP `quote` 20:14:31Z); SPY 770.56, −0.32%, versus 50dma 747.56 and 200dma 703.48 (`state.park_signal_daily`, 08-10), `spy_trend = UP`, `dd_from_252d_high` −0.03% — i.e. the index is **0.03% from its 252-day high**; `hy_oas` **2.85** (2026-07, latest monthly, credit in the tight third of its trailing range); `FUNDAMENTAL_AXIS` growth `decelerating`, inflation `stable`, policy `hawkish`, risk_sentiment `neutral`, **`shock_overlay` `acute`**; today's DEVELOPMENTS above; and, weighed beyond the listed floor, the fact that **July CPI prints tomorrow at 08:30 ET** and that Brent settled +1.4%.

- **`vehicle`: VOO** — KEEP (current `state.park_policy_current.vehicle` is VOO, effective 2026-08-03).
- **`conviction`: MEDIUM · `conviction_pct` 55** (down from 58 yesterday, and the decline is the point — see below).
- **`direction`: keep · `status`: BOUND.**
- **`rationale`:** VOO beats the runner-up **SGOV** because the de-risk case rests entirely on a shock whose *measured* transmission today was a +1.4% Brent settle and a −0.32% index, while **VIX fell 1.16%** — the vol market is actively declining to price the escalation as stress. Against that, the cost of sitting in tier-0 is forgoing an uptrend 0.03% from its 252-day high, with breadth above 70%, credit tight at 2.85, and SPY 3.1% clear of its 50dma. The intermediate menu (GOVT/IEF/MUB/LQD/TLT) stays excluded on the same ground as the 08-03 switch: every one is a duration bet, and duration is unattractive with policy `hawkish`, three FOMC dissenters pressing for a September hike, and an energy-led disinflation whose driver has already reversed. **The decisive precedent is this router's own 2026-07-26 → 2026-08-03 round trip**, which de-risked into SGOV on an `acute` overlay, watched markets absorb it, and re-risked eight days later — a measured cost paid for exactly the reasoning the de-risk case is making again today. **Conviction is cut to 55 rather than held at 58** because a 20% Hormuz transit levy is a concrete new economic imposition rather than more rhetoric, and it lands the session before a CPI print whose single largest swing factor is energy. That is a genuine deterioration in the evidence, and it belongs in the number.
- **`invalidation`:** any ONE of — SPY closing below its 50-day SMA (~747.6); VIX closing above 25; Brent sustaining above ~$100 on an actual Hormuz closure rather than a levy; or a July CPI print tomorrow that re-accelerates core enough to price September-hike odds above ~85% and carry the 10Y through 5%.
- **`theater_check`:** **Not a foregone conclusion, and here is the falsifiable evidence for that claim.** The call moves conviction **against** the direction a narrating-to-conclusion rationale would move it — down, on the day the vehicle was retained — and it concedes outright that the vol market disagrees with its own shock framing. It names four specific, observable, dated flip conditions rather than a mood. Two conditions would have produced a SWITCH today had they held: a VIX close through 20, or Brent breaking $95; both were checked and neither did. The KEEP is the default under a genuinely mixed read, and the mixed-ness is recorded rather than resolved by assertion. **What would make this theater is if conviction never moved; it moved.**

**PARK RECONCILIATION OBSERVATION — MEASURED, handed to D2a, deliberately NOT adjudicated here.** The live broker book shows **21.6747 VOO shares** (market value $15,360.86 at $708.70). `state.park_position_current` shows `events_shares = 26.6347` (buy 40.0395 − sell 13.4048), `last_parking_date = 2026-08-07`, `parking_event_count = 17`. **The divergence is exactly 4.96 shares (~$3,515).** This is a MEASURED discrepancy between two reads taken this session, not an inference about its cause. A plausible — and explicitly UNVERIFIED — explanation is the withdrawal landed on `main` as `feat/withdrawal-after-the-fact-2026-08-10`, whose funding sale may not yet be recorded in `events.park_*`. **D1 does not own park-position reconciliation and does not repair it; D2a does.** No alert is raised because the sanctioned `position_reconciliation_lag` category is scoped to strategy positions present in the connector but absent from `state.current_positions`, and VOO is neither — manufacturing an alert outside its defined scope would be worse than this note. **D2a: please reconcile.**

**Heartbeat** (`ops.heartbeat`, `source='loop:park_allocator'`) written this run regardless of outcome, per the `meta_monitoring_heartbeat` dead-man's-switch marker.

---

## MEASUREMENT GAPS AND CAVEATS

Recorded so that no downstream reader mistakes an unavailable number for a measured one:
1. **FMP `news` / `analyst` / `economics` / batch-`quote` all returned ACCESS DENIED** (plan-tier gating), across three independent sub-agents. Event attribution rests on WebSearch/Tavily with per-item URLs. **FMP was unavailable, not empty.**
2. **Treasury yields are a source-disagreement band**, not a print: 10Y ~4.69 (sources converged near 4.688), 2Y 4.23-4.26, 2s10s ~+43-46bp. No single authoritative EOD figure was obtained.
3. **No clean NY settle for gold** — FMP's snapshot was a post-close continuous-futures print; the session was volatile (~$4,495 intraday high, fading to ~$4,440). Treat the level with a ±$50 band.
4. **DXY** ~99.84, +0.03%, single low-confidence web source; direction only.
5. **Equity breadth: no 08-11 value exists** — see the EQUITY-BREADTH section for the full reasoning.
6. **ONON and SE consensus figures conflict across sources** (ONON net-sales consensus cited as both CHF 1,114M and CHF 878.16M; SE EPS cited as both a beat on adj and a miss on GAAP). Both conflicts are recorded rather than silently resolved.

---

## RECOMMENDED ACTIONS

- **EXIT — ISRG (Strategy B), `B:ISRG:2026-07-21`, 0.1388 sh, contract_id 9063285.** Mechanical convergence-target exit: target 400.00, 2026-08-11 regular-session close **401.23** (IBKR `ONE_DAY`, `outside_rth=false`; open 392.85, high 402.14, low 392.22). The target IS the exit rule per Strategy B — no judgment applied. Mark-vs-cost +13.84%. **Does NOT affect `D:ISRG:2026-07-20`**, which carries no convergence target and runs to thesis-invalidation.
- **WATCHLIST ADD — ONON to the Strategy B new-entry-candidate index.** −20.29% close-to-close on a resolved, dated Q2 earnings event with an FY26 growth-guidance cut; clears B Entry criterion 1 (≥5%) decisively. **Index-only — B router is DO-NOT-ACTIVATE, so no thesis construction is routed.**
- **WATCHLIST ADD — TME to the Strategy B new-entry-candidate index.** −11.92% close-to-close **on a non-IFRS EPS beat** (RMB1.70 vs RMB1.62) — the sentiment-vs-information divergence pattern B targets. Clears B Entry criterion 1. **Index-only — B router is DO-NOT-ACTIVATE.**

**No new entry candidates. No add candidates. No router reviews recommended.**

```yaml d1_actions
- action: exit
  ticker: ISRG
  strategy: B
  detail: Mechanical convergence-target exit — target 400.00, 2026-08-11 RTH close 401.23 (IBKR ONE_DAY outside_rth=false); position_key B:ISRG:2026-07-21, 0.1388 sh, contract_id 9063285, mark-vs-cost +13.84%; does not affect D:ISRG:2026-07-20
- action: watchlist
  ticker: ONON
  strategy: B
  detail: ADD to Strategy B new-entry-candidate index — -20.29% cc on resolved Q2 earnings with FY26 growth guide cut, clears B Entry criterion 1 (>=5%); index-only, B router DO-NOT-ACTIVATE
- action: watchlist
  ticker: TME
  strategy: B
  detail: ADD to Strategy B new-entry-candidate index — -11.92% cc on a non-IFRS EPS beat (RMB1.70 vs 1.62), sentiment-vs-information divergence, clears B Entry criterion 1; index-only, B router DO-NOT-ACTIVATE
```
