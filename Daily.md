2026-08-13
<!-- d1_scan_through_utc: 2026-08-13T22:30:01Z -->

# Daily Market Development Scan — 2026-08-13 (Thu, MT)

**Scan window:** 2026-08-12 16:24 MT → 2026-08-13 16:30 MT (24.1h). The prior-run marker `<!-- d1_scan_through_utc: 2026-08-12T22:24:00Z -->` parsed cleanly from the `Daily.md` on disk, cross-checked against that file's own commit at 2026-08-12T22:28:50Z (agree to within 5 min — the prior run's write-then-commit interval, not drift). `state.routine_catchup_window` reports `window_days = 0.99`, `never_completed = false` — cadence-normal, so no `CATCHUP` token is owed on this run's completion note.

**This window contains exactly ONE trading session — Thursday 2026-08-13.** `state.trading_day_today` reads `today = 2026-08-13`, `is_trading_day = true`, `last_trading_day = 2026-08-13`.

**Tape (2026-08-13 regular session; every ETF/equity figure from IBKR regular-session `ONE_DAY` bars, `outside_rth=false`, denominator = the 2026-08-12 close):** SPY **777.88 (+0.70%**, from 772.49 — a record close), QQQ 732.07 (+1.16%), IWM 303.50 (+0.26%), equal-weight **RSP 222.73 (+0.75%)**. **VIX 14.63** (FMP `chart` historical-price-eod-full, the bar carrying its own `"date":"2026-08-13"` field, not a live quote), from 14.55 — a second consecutive session inside the LOW band (<15). 10Y **4.63%** (−5bp), 2Y **4.15%** (−5bp). Brent **$87.00 (−1.66%)**, gold **$4,420.40 (−1.08%)** off yesterday's nine-week high. `hy_oas` 2.85 (2026-07 monthly, latest available — no daily series exists). Index cross-check via AP: S&P 500 7,798.99 (+0.7%, first close above 7,800), Nasdaq Composite 26,803.03 (+0.8%), Dow 53,839.99 (+0.1%), Russell 2000 3,052.85 (+0.2%).

**The one-line characterisation: a flat July PPI print took the September hike off the table, and the market's response was to buy real estate and consumer staples ahead of technology into a record close — a rates-driven advance, not a risk-appetite one — while the Iran conflict escalated rhetorically and oil and gold both FELL.** Yesterday this scan flagged an open disagreement between the equity-vol complex (calm) and the commodity/haven complex (escalation). That split narrowed today from the commodity side, which is the single most decision-relevant fact in this file: it is what the park KEEP is being paid by, and it is why the KEEP is bound at higher conviction than the switch that created it.

---

## TL;DR

- **Exits triggered: none.** All 14 open tranches swept against both mechanical triggers. B:MSCI is the only position carrying either; its convergence target of 615 was not approached (close 575.24, intraday high 579.36) and its time-exit is 2026-09-25. No Development met any judgment-laden invalidation criterion on any position.
- **New entry candidates: none routable.** 21 names cleared Strategy B's frozen ≥5% event-day floor — the second-richest post-event cohort in recent memory — and not one can be staged: B's router has read DO-NOT-ACTIVATE since 2026-08-05 and B's `available_funds` is **$0**. Handed to W2 as shortlist material. **REZI (−20.42%) and LFTO (−20.59%) are the two most B-shaped setups on the tape** and are named for W2 specifically.
- **Add candidates: none flagged** (14 A/B/D tranches evaluated, **0 declined at the HARD GATE** — second consecutive zero). **This is the fourth consecutive all-decline session, and for the best-formed cases the binding reason is capital, not merit** — A, B and D all hold `available_funds = 0`. See ANALYSIS — ADD-CANDIDATE CHECK; this is now a structural finding, not a daily coincidence.
- **Watchlist changes: none.** No name on any queue changed candidacy status; nothing added or removed. The 21-name ≥5% cohort is routed to W2's screen rather than onto the B queue, per the standing handling while B is DO-NOT-ACTIVATE.
- **Regime review: YES — ONE flagged, for Strategies A and D.** Two dated primary-source inflation prints in two sessions have inverted the specific input M1a cited for `policy_stance = hawkish`. Both A's and D's DO-NOT-ACTIVATE calls rest on the Strategy.md:123 override, which requires `policy_stance = hawkish` to fire at all. See ANALYSIS — REGIME CHECK.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**Iran / Hormuz — escalation in rhetoric and interdiction, de-escalation in price.** The conflict remained live through the window and produced several discrete items, but the market's expression of them ran the opposite way to the headlines:

- Both sides publicly claimed control of the Strait of Hormuz on 2026-08-13: Trump asserted "total control" on Truth Social (CBS News live blog, updated 2026-08-13 08:31 ET), while Iran's Basij commander Hossein Taeb stated the strait is "under Iran's control and management" (Fars News via The Hindu live blog, 2026-08-13 12:53).
- Hormuz transits ran at **16 ships on 2026-08-11** against a 130–140 pre-war baseline (Hellenic Shipping News, published 2026-08-13).
- The US Navy fired on an Iran-bound container ship in the Gulf of Oman (NBC/Reuters, 2026-08-12); US forces have reportedly diverted 59 vessels under the blockade (The National, updated 2026-08-13 04:53).
- An oil spill from a grounded tanker reached Oman's coastline (AFP via The Hindu live blog, 2026-08-13 09:26).
- The fatal Houthi attack on the cargo ship *Tihamah* in Bab el-Mandeb — six killed — was confirmed 2026-08-12 (Al Jazeera, NBC/Reuters) and was the lead item in yesterday's scan; it is carried here only as the prior-session anchor.

**Observable cross-asset reaction — and it is the inverse of the headline flow.** Brent **fell 1.66% to $87.00** and gold **fell 1.08% to $4,420.40**, both measured from dated FMP EOD bars. Sell-side framing attributes the oil move to the market reading the US shift toward *economic pressure and naval blockade* rather than further strikes as reducing the near-term probability of an actual closure, compounded by demand-side revisions — the IEA cut its 2026 demand-growth outlook by 1.6M bpd and OPEC cut its own forecast to 580k bpd from 780k (Barron's, 2026-08-13; Scotia Wealth Management morning note, 2026-08-13). US energy equities did neither: **XLE +0.05%**, a third consecutive session of not pricing the conflict in either direction.

Nothing else in the window qualifies as a market-wide breaking event. No material bankruptcy, disaster, or unscheduled enforcement action affecting global risk assets was identified.

### 2. Scheduled events that resolved in this window

**US macro — the two that mattered, both released 2026-08-13 08:30 ET:**

- **July PPI (final demand), BLS release USDL-26-1380.** Headline **0.0% m/m** against **+0.2% consensus** — softer than expected. Annual final demand **+4.7%** vs +4.9% consensus. Core (ex food/energy) **+0.2% m/m**, below the +0.3% forecast. *(One secondary source cited a prior-month YoY of +5.5%; that figure was not corroborated at the primary source and is not relied on here.)*
- **Initial jobless claims, week ended 2026-08-08, US DOL.** **209,000** against a 202,000 Bloomberg consensus — a miss on the soft side, up from 200,000 prior; the 4-week moving average held at 199,000. Still near historic lows, but it reinforces rather than contradicts the `growth_momentum = decelerating` axis.

**Market response to the PPI print:** the S&P 500 took its first close above 7,800; September-hold odds repriced to **65–68%** from roughly 45% a week earlier (one source put September *hike* odds at ~34%, down from ~55%); the 2Y and 10Y both fell 5bp on the day.

**Out of window, flagged only so the boundary is explicit:** July CPI (+0.1% m/m, +3.4% y/y) was released 2026-08-12 08:30 ET — *before* this window opened at 16:24 MT that day, and it was covered by yesterday's scan. July retail sales are scheduled 2026-08-14 08:30 ET, *after* this window closes. No FOMC meeting, minutes, or policy action fell in the window; the most recent was 2026-07-29.

**Earnings prints resolved in window (≥$2B cap).** Every item below was verified against the issuer's own release or SEC filing for release date/time and stated fiscal period, per the EVENT-IDENTITY GATE:

| Ticker | Period | Released | Result vs consensus | Guidance | Reaction |
|---|---|---|---|---|---|
| **CSCO** | Q4 FY2026 (ended 2026-07-25) | 2026-08-12 after close | non-GAAP EPS **$1.22** vs $1.17; revenue **$17.25B** vs $16.84B (+18% YoY) — **beat** | **Raised**: Q1 FY27 EPS $1.32–1.34, revenue $18.0–18.2B vs ~$16.8B street | **−8.40%** |
| **COHR** | Q4 + FY2026 (ended 2026-06-30) | 2026-08-12 (time not obtained) | non-GAAP EPS **$1.74** vs $1.58; revenue **$2.05B** vs ~$2.025B (+34% YoY) — **beat** | Q1 FY27 revenue $2.2–2.4B, EPS $1.85–2.05 | **−7.99%** |
| **AMAT** | Q3 FY2026 (ended 2026-07-26) | 2026-08-13 16:01 ET | non-GAAP EPS **$3.50** vs ~$3.38–3.45; revenue **$9.115B** — beat *(consensus reported inconsistently ~$9.0–9.18B across secondary sources; flagged)* | **Raised**: Q4 revenue $10.25B ±$0.5B, EPS $4.02 ±$0.20 | after-hours only — no settled close |
| **NU** | Q2 2026 (ended 2026-06-30) | 2026-08-13 17:06 ET (6-K) | Revenue **$5,875.7M** vs ~$5.45B — beat; net income $1,061.1M | not itemized in the 6-K obtained | not yet observable |
| **JD** | Q2 + interim 2026 | 2026-08-13 pre-open | adj EPS **RMB6.29** vs RMB5.61 — beat; revenue **RMB346.40B**, **−2.9% YoY** | — | **−7.31%** |
| **TPR** | Q4 + FY2026 | 2026-08-13 pre-market | non-GAAP EPS **$1.32** vs ~$1.26; revenue **$1.88B** vs $1.86B (+9%) — **beat**; dividend +16% | FY27 revenue **$8.4–8.5B, below street**; FY27 EPS $7.80–7.90 ≈ in line | **−16.49%** |
| **ENS** | Q1 FY2027 | 2026-08-12 | non-GAAP EPS **$3.66** vs $2.83 (+64% YoY); revenue **$935.6M** vs $928M — beat | — | +~14% 08-12, but confounded by a same-day lithium-plant announcement |
| **BLSH** | Q2 2026 | 2026-08-13 | adj revenue **$92.6M** vs $87.4M (+62% YoY) — beat; GAAP net loss $(280.0)M | full-year outlook raised | +~13% intraday |

**PENDING — recorded as pending, NOT as an outcome.** **MK-6240** (florquinitau F-18, tau PET imaging for Alzheimer's) carried a **PDUFA target action date of 2026-08-13**, confirmed from the sponsor's own NDA-acceptance release. **No FDA action letter, 8-K, or company release confirming approval or a CRL was found.** The target date is a schedule, not evidence of a completed decision, and no outcome is recorded. Sponsor is **Lantheus Holdings (LNTH)** / Enigma Biomedical — an initial secondary source misattributed sponsorship to Merck and Bristol Myers Squibb and is corrected here. Re-check on the next run.

**No M&A closings, index changes, or material court rulings** were identified in the window. Two coverage gaps are stated rather than papered over: no comprehensive real-time index-change feed was reachable, and no dedicated legal-docket search was run — so "none identified" for those two categories is weaker than "none occurred."

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

Layer-1 rail: US-listed, market cap ≥$2B, ≥2% close-to-close on 2026-08-13, attributable to an identifiable public event. **26 names verified on the rail; 21 of them ≥5%.** Full judged output logged as one `entry_type='research-screen'` row (`screen='single-name-move'`).

**PROCESS NOTE — a near-miss on the price basis, caught and corrected.** The first-pass sweep returned its closes from FMP `company/profile-symbol` **post-close snapshots**, because the EOD chart endpoint was plan-gated for all but six whitelisted symbols. That is exactly the basis §19 forbids — the 2026-08-05 CVS case (−4.96% snapshot vs −5.08% true close) moved a name across B's frozen 5% floor on precisely this error. Nothing was written up as delivered: **all 26 names were re-measured against IBKR regular-session `ONE_DAY` bars**, and every figure in this file is that re-measured value. The re-measurement *confirmed* rather than corrected — largest discrepancy 0.01pp (HUBS 14.46 vs 14.47), no name changed side of the 5% floor. Recorded because a verification that finds nothing is still evidence: it establishes the snapshot path was accurate *on this date*; it does not license using it next time.

**The three threads that carry information beyond the individual names:**

**(a) AI-infrastructure revenue is now being priced against the margin it arrives with.** **CSCO −8.40%** (123.88 → 113.47), a $447B mega-cap, on a **beat AND raise**, with a record $9.3B FY26 AI-infrastructure order backlog — for one reason: non-GAAP gross margin compressed to **66.3% from 68.4%** YoY on AI-hardware mix. **COHR −7.99%** fell on the same axis after its own beat. This is a different regime from "AI revenue is rewarded," which is the one every open Strategy D AI-adjacent thesis was written under. It invalidates nothing — none of TSM, GEV, AMZN or GOOGL names a customer's gross margin among its criteria — but it is the kind of shift W3 and M4 should see.

**(b) Enterprise software got a take-private bid.** **WDAY +17.78%** on a Reuters exclusive that Silver Lake is in talks to acquire Workday at roughly **$43B**. At that size it would rank among the largest LBOs ever attempted, and it re-rates the enterprise-SaaS complex. It is the identifiable driver of open position **D:CRM's +4.16%** session — adjudicated, and declined as an add, below.

**(c) Memory/storage went vertical on a calendar event, with a cleanly separable sympathy leg.** **SNDK +13.67%** ($226B) on its scheduled 2026 Investor Day — FY28–30 targets of mid/high-teens revenue growth and ~80% gross margin. **WDC +7.31%** on no news of its own, pure sympathy. One leg moved on dated company guidance, the other on association: the textbook intra-industry-group divergence shape. Note that SNDK and CSCO are the same session's counterpoint — margin-*accretive* AI exposure was rewarded as hard as margin-*dilutive* AI exposure was punished.

**Judged significant (17 written up; `metric_pct` = IBKR close-to-close):**

| Ticker | Move | Conviction | Event |
|---|---|---|---|
| CSCO | −8.40% | high 75 | Beat + raise, sold on AI-mix gross-margin compression |
| WDAY | +17.78% | high 75 | Reuters: Silver Lake take-private talks, ~$43B |
| SNDK | +13.67% | high 75 | 2026 Investor Day, FY28–30 targets |
| REZI | −20.42% | high 75 | First standalone FY guide post ADI spin-off |
| LFTO | −20.59% | high 75 | Analyst downgrade to a 52-wk low, day after its own beat+raise |
| JD | −7.31% | high 75 | First-ever YoY revenue decline since 2014 listing, on an EPS beat |
| ARX | +43.35% | medium 60 | Q2 beat: pretax income $87.4M vs $22.3M YoY |
| CLBT | −29.18% | medium 60 | Q2 miss + FY guide cut + CEO change |
| AVAH | +24.75% | medium 60 | Q2 beat + raised FY guide |
| TPR | −16.49% | medium 60 | Beat, but FY27 revenue guide soft on Kate Spade |
| BSP | −16.46% | medium 60 | BofA cut to Underperform + Q2 results same window |
| HUBS | +14.46% | medium 60 | Q2 EPS beat *despite* a trimmed FY26 revenue guide |
| BIRK | +11.59% | medium 60 | Q3 revenue beat, FY26 cc growth guide raised to 15% |
| WDC | +7.31% | medium 60 | Sympathy with SNDK, no own news |
| FISV | +7.64% | medium 60 | **Driver UNIDENTIFIED** — surfaced *because* unexplained at $30B |
| NFLX | +5.43% | medium 60 | Pershing Square (Ackman) stake disclosed — pure flow |
| AMBP | +4.35% | low 45 | **`below_spec_floor`** — parent retained advisers to prep an AMP sale (13D/A) |

**Two pairings worth more than either name alone.** HUBS rose 14.46% on an EPS beat *despite* cutting its revenue guide; TPR fell 16.49% on a revenue guide read as soft *despite* an EPS guide roughly in line. Same session, opposite resolutions of the same earnings-line-versus-revenue-line question. And **BIRK +11.59% against TPR −16.49%** complicates any simple "the consumer is weak" read of the day.

**Cleared the 5% bar and judged NOT significant** (5 — `rule_only`): STUB −10.07% (ordinary outlook reaction), ONDS −8.80% (real beat, real dilution concern, correctly weighed), COHR −7.99% (folded into the CSCO thread), LITE −5.58% (direction settled by the bar, cause not isolated — none asserted), RBLX +6.78% (**no identifiable catalyst**; a broad-tech-rally attribution on a +0.70% index day is not one).

**Coverage boundary, stated rather than silent:** the raw sweep produced 38 candidates at ≥$2B; 26 were carried to bar verification. The 12 not carried (incl. MOS, GFI, HMY, ZTS, CAVA, RDDT, BILI, NOK, SMR) were each UNIDENTIFIED-driver or low-rail sector sympathy; they are named in the logged record and **their closes are not asserted anywhere**. A further ~70 raw-list names were excluded by inspection as clearly sub-$2B.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

Layer-1 rail: any GICS sector ≥1% at sector-ETF level, or notable intraday dispersion. **Four sectors cleared the 1% rail; dispersion 2.58pp.** Logged as one `entry_type='research-screen'` row (`screen='sector-move'`). All eleven SPDRs measured from IBKR `ONE_DAY` bars — FMP returned ACCESS DENIED for every sector symbol this run.

| Rank | ETF | 08-12 | 08-13 | % |
|---|---|---|---|---|
| 1 | XLC | 110.27 | 112.55 | **+2.07%** |
| 2 | XLRE | 44.49 | 45.12 | **+1.42%** |
| 3 | XLP | 85.08 | 86.00 | **+1.08%** |
| 4 | XLK | 188.86 | 190.77 | **+1.01%** |
| 5 | XLF | 57.92 | 58.26 | +0.59% |
| 6 | XLY | 117.89 | 118.45 | +0.48% |
| 7 | XLU | 43.84 | 44.04 | +0.46% |
| 8 | XLE | 61.03 | 61.06 | +0.05% |
| 9 | XLV | 168.44 | 168.38 | −0.04% |
| 10 | XLI | 185.88 | 185.79 | −0.05% |
| 11 | XLB | 52.58 | 52.31 | **−0.51%** |

**The leaderboard order is the content, not the magnitudes.** The index closed at a record and the two sectors that led it were **real estate and consumer staples**, both ahead of technology. XLRE is the purest duration-sensitive sector on the board and XLP is the classic defensive; both outran XLK on a day the curve fell 5bp at both ends after a flat PPI. **A record close led by duration-sensitives and defensives is a rates-driven advance, not a risk-appetite one.** This is precisely the case §19 names when it says a defensives bid can outrank a larger cyclical sweep. XLK is written up for the *negative* information: it rose 1.01% and still finished **fourth**, after a week in which technology alone accounted for essentially the entire index gain.

Two items surfaced **below** the rail through §19's escape valve:

- **XLE +0.05% — third consecutive session of refusing to price the war, in either direction.** Unchanged today while Brent fell 1.66% and both sides publicly disputed control of Hormuz; unchanged on 08-12 when Brent rose and the first fatal shipping attack was confirmed. A sector that ignores its own commodity in both directions for three sessions is either fully discounting the conflict or is being priced on something else. Either reading is material to the `shock_overlay = acute` score and neither is visible from the 1% rail.
- **XLB −0.51% — the lone decliner** on a session where breadth expanded to a one-month high and ten of eleven sectors rose. A small but real dissent, consistent with `growth_momentum = decelerating` and inconsistent with reading the rate rally as reflationary.

*Keeping the rates read honest:* utilities are the **other** duration proxy and they materially lagged (**XLU +0.46% vs XLRE +1.42%**). One sector is not carrying the thesis unopposed, and that is recorded rather than omitted.

### 5. Notable commentary

- **Richmond Fed President Tom Barkin**, "The Mysterious U.S. Economy," reprinted as an op-ed 2026-08-13: explicitly declined to signal the FOMC's next move ("I won't spoil the plot today"), framing the path back to the 2% target as the open question. Notable for what it is *not* — no pushback on the market's dovish repricing from a sitting president on the day it happened.
- **IEA / OPEC demand revisions**, cited as co-driver of the oil pullback alongside the Hormuz de-escalation read: IEA cut its 2026 demand-growth outlook by 1.6M bpd; OPEC cut its own forecast to 580k bpd from 780k (Barron's, 2026-08-13).
- **JJ Kinahan (Cboe SVP)**, "Producer Price Index Offers Another Respite on Inflation," 2026-08-13 09:05 CT.
- **Mona Mahajan (Edward Jones)**, quoted 2026-08-13: "a combination of strong earnings growth and stable labor market and consumption trends continues to underpin stock market gains" (Barron's live blog).
- No regulator or central-bank speech with market-moving content beyond Barkin's was identified in the window.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP

Swept the **union** of `state.current_positions` (14 open tranches) and live IBKR `get_account_positions`. **The two reconcile exactly, name by name and share by share** — AMZN 0.3464 = 0.1910 + 0.1554; DIS 0.7244 = 0.2822 + 0.4422; GOOGL 0.2577 = 0.1534 + 0.1043; TSM 0.1550 = 0.0891 + 0.0659; CRM, GEV, ISRG, MSCI, RTX, UBER single-tranche and matching. **Zero RECONCILIATION-LAG positions**; no `position_reconciliation_lag` alert is owed. (VOO 21.6747 sh / $15,499.58 is the park vehicle, not a strategy position.) Yesterday's outstanding item is closed: the `B:ISRG` convergence exit that filled 2026-08-12 no longer appears in either source.

Of the 14 tranches, **only B:MSCI carries either mechanical trigger.** The 13 Strategy D tranches carry neither `convergence_target` nor `time_exit_date` by design — Strategy D runs to thesis invalidation with no max hold.

| Position | Trigger | Threshold | Today | Status |
|---|---|---|---|---|
| B:MSCI:2026-07-27 | Convergence target | 615.00 | close **575.24**, intraday high 579.36 | **NOT triggered** — 6.5% below target |
| B:MSCI:2026-07-27 | Time exit | 2026-09-25 | today 2026-08-13 | **NOT due** — 43 days out |

**EXIT TRIGGERED: none.**

### PER-STRATEGY KILL-TRIGGER SWEEP

`perf.kill_flags` read for both strategies with a live book. Per the standing rule, `current_drawdown` was refreshed **unconditionally** against today's live marks — not conditioned on any judgment about whether the day was eventful.

| Strategy | Deployed unit value | Peak | Current drawdown | Excess vs SGOV | Deployed days | Closed trades / gate | Flags |
|---|---|---|---|---|---|---|---|
| B | 1.2062 | 1.2062 | **0.00%** | +19.33% | 75 | 12 / 30 | all FALSE |
| D | 1.0902 | 1.0924 | **−0.20%** | +7.85% | 75 | 0 / 30 | all FALSE |

- **Drawdown kill (≥50% peak-to-trough):** not remotely approached. B at 0.00%, D at −0.20%.
- **Runaway-success (deployed TWR doubled, pre-gate):** B at 1.21x, D at 1.09x. Not triggered.
- **Interim underperformance warning** (`deployed_days ≥ 90 AND beta-adjusted excess vs SGOV ≤ −15%`): **FALSE for both**, and structurally unreachable today — both strategies are at 75 deployed days, short of the 90-day precondition, and both carry *positive* excess. No `interim_underperf_warning` alert is owed, and none is open to heal.
- **B open-book pairwise-correlation warning:** `analytics.b_pairwise_correlation` reads `n_positions = 1, n_pairs = 0, avg_offdiagonal_corr = NULL`. B holds a single position (MSCI), so `n_positions >= 2` fails and the check is a no-op, exactly as the standing note anticipates.

`ops.alerts` carries **zero unresolved rows** at the time of this sweep.

### Judgment-laden thesis-invalidation check, per position

Every open position was checked against every Development above. **No invalidation criterion is met on any position.** The four requiring more than a null answer:

- **D:CRM** — the day's largest position gain (+4.16%), driven by WDAY's take-private report, not by CRM news. CRM's four criteria are Agentforce/Data-360 ARR growth, cRPO, non-GAAP operating margin, and the FY27 revenue guide — all company-reported. A peer M&A rumour is a **multiple** event and touches none of them. **UNBREACHED, and not reinforced either** (see the add check).
- **D:TSM / D:GEV / D:AMZN / D:GOOGL** — the CSCO margin thread (Development 3a) is the one item this session that could plausibly bear on AI-infrastructure theses. It does not breach any criterion: TSM's are gross margin / USD revenue growth / node ramp / structural AI-capex reset; GEV's is total-company organic orders growth; AMZN's and GOOGL's are cloud revenue, margin and backlog. **A customer's gross margin compressing is not any of these.** Recorded as a regime observation for W3/M4, not as an invalidation. **All UNBREACHED.**
- **D:GOOGL** — no in-window update to the federal appellate action that yesterday's scan identified as raising the probability of named criterion 4 (adverse structural remedy). A filing is still not a remedy. **UNBREACHED**, overhang unresolved and carried.
- **D:RTX** — the only meaningful decliner (−1.02%), underperforming a flat XLI by ~1pp. **No driver identified in window.** None of its six criteria (Airbus damages ruling, powder-metal quality event, GTF Advantage EIS timing, backlog, FY26 FCF guide, FY27 defense procurement) has any in-window news against it. **UNBREACHED.**

### Watchlist candidate status

**No change to any queued name.** The A queue (29 names), B watch-overflow (7), B new-entry candidates (4: CVS, DVA, ONON, TME), B disqualifiers (2), B short-decline tracking (4), and the D re-screen pipeline (2 deferred + 5 superseded) were checked against today's Developments. **ONON was explicitly checked and moved <2%**, so it did not surface on the rail. No queued name appeared in the 26-name mover cohort, no queued name's candidacy moved closer to or further from entry, and no demotion is owed.

---

## ANALYSIS — OPPORTUNITY CHECK

Evaluated against every roster-active strategy carrying `review_cadence: reactive` in `strategy/roster.yaml` — **A, B, C, E** (D excluded via `review_cadence: long_horizon`). The router and capital state jointly determine that **nothing is routable today**:

| Strategy | Router (as of 2026-08-05) | `available_funds` | Routable? |
|---|---|---|---|
| A | DO-NOT-ACTIVATE | $0 | No — blocks new A entries |
| B | DO-NOT-ACTIVATE | $0 | No — blocks new B entries |
| C | HYBRID ACTIVATE (FOMC-only) | $0 | No — next FOMC 2026-09-16, none in window |
| E | **ACTIVATE** | **$15,309.94** | **Yes — the only strategy both activated and funded** |

**Strategy B — 21 names cleared the frozen ≥5% floor and none is staged.** This is the second-richest post-event cohort this scan has produced, and B's router has read DO-NOT-ACTIVATE since 2026-08-05 (the universal `shock_overlay = acute` reconciliation override) with `available_funds = 0`. The cohort is handed to **W2** as shortlist material. Two names are called out for W2 specifically, because both display the shape B's entry criterion 2 exists to find — a reaction driven by something other than new fundamental information:

- **REZI −20.42%.** Record Q2, and the 20% decline came on the **first standalone FY guide ($2.9–2.95B) issued after the 2026-08-03 ADI spin-off**. A guide that is smaller because the company is smaller is a mechanical artifact. Whether the market distinguished the artifact from deterioration is exactly the criterion-2 question.
- **LFTO −20.59%.** Fell to a **52-week low on an analyst downgrade**, the session immediately after its own beat-and-raise. Opinion moving a name 20% one day after information moved it the other way is the cleanest sentiment-versus-information separation on this tape.

**Strategy E — the one live path, and today produced a genuine candidate shape.** E takes intra-industry-group pair divergences, not single-name post-event moves, so none of the cohort above routes to it directly. But **SNDK +13.67% (own dated Investor Day guidance) against WDC +7.31% (pure sympathy, no news of its own)** is a same-industry-group pair where one leg moved on information and the other on association — the divergence archetype. **Handed to M2's pair screen as ideation; not acted on here**, since E entries require the full divergence screen and a per-name SLB check, and D1 does not construct theses.

Two candidate pairings were considered and **rejected** as co-movement rather than divergence: the optical complex (COHR −7.99% / LITE −5.58%, both down together) and the gold miners (KGC −2.29%, GFI, HMY, plus FCX −3.45%, all down 2–3× more than bullion's −1.08%, which is beta-consistent).

**Strategies A and C — no candidates.** No newly announced qualifying catalyst within 45 days (C) or within 6 months (A) was identified on any name in window, and both are router-blocked and unfunded regardless.

---

## ANALYSIS — ADD-CANDIDATE CHECK

Strategies **A, B, D only** (Rev 40). **14 open tranches evaluated: 1 Strategy B, 13 Strategy D. 0 flagged. 0 declined at the HARD GATE.**

**HARD GATE result:** all 14 tranches carry a populated `invalidation_status`, and none carries `$.status = 'NOT_DISCRETELY_RECORDED_AT_ENTRY'` — so "unbreached" was affirmatively confirmable in every case and `invalidation_criteria_evaluable = true` for all 14. Second consecutive zero, for the same reason as yesterday: the one structurally-ineligible tranche (B:ISRG) left the book on 2026-08-12.

**The day gave the sweep almost nothing.** Twelve of fourteen tranches' underlying names *rose*. Only AMZN (−0.80%) and RTX (−1.02%) declined at all, both inside ordinary daily noise. Trigger (a) needs a dip; there were effectively none.

**The one case requiring real adjudication — D:CRM, declined on merit.** CRM was the book's best performer at **+4.16%**, and the driver is identifiable: **WDAY +17.78%** on the Silver Lake take-private report. It is nonetheless **not** strengthened conviction under Strategy D's terms. CRM's criteria are all company-reported fundamentals; a take-private rumour at a peer changes what someone might *pay* for enterprise software, not what CRM's Agentforce ARR is doing. Treating a peer M&A headline as thesis reinforcement is the category error trigger (b)'s wording — "new information reinforcing, not replacing, the original thesis" — exists to exclude.

### The structural finding

**This is the fourth consecutive session in which every A/B/D tranche is declined, and for the best-formed cases the binding constraint is not merit — it is that there is no capital to size a tranche against.** `analytics.strategy_nav` reads `available_funds = 0` for A, B, C *and* D; the entire **$15,309.94** of free capital sits in **E**.

Each step of how that happened is documented and none is a defect: A/B/D became capital-disabled following the 2026-08-05 AR_orc DO-NOT-ACTIVATE resolutions; C was swept to zero on 2026-08-12 by a `nomadic_capital_sweep` under its permanent NOMADIC classification; and a $3,525 external withdrawal left E on 2026-08-11. But the consequence deserves stating once, plainly, rather than being re-derived daily:

> **While A, B and D remain router-disabled, this sweep is structurally incapable of producing a flagged add, whatever the tape does.**

**D:DIS:2026-05-07** is the demonstration. It was named on 2026-08-10 as "the best-formed add case in the book" — all five criteria unbreached with **three affirmatively PASSED at their own Q3 FY26 checkpoints** (SVOD operating margin ~13% on a third consecutive quarter of expansion; FY26 ~12% adjusted EPS growth reiterated; buyback target *raised* to ≥$9B from $8B). It sits **−5.86% below cost** today, the deepest underwater tranche in the book — exactly the dip-with-intact-thesis condition the trigger describes. It was declined then and is declined now, on zero available funds. **A future reader should not mistake this run of zeros for an absence of candidates.**

**Per-tranche dispositions** (marks = IBKR `ONE_DAY` close 2026-08-13 vs each tranche's own cost basis per share):

| Position | Mark vs cost | Trigger | Disposition | Why |
|---|---|---|---|---|
| B:MSCI:2026-07-27 | −0.70% | dip-with-intact-thesis | declined | Marginal dip on a name that *rose* 2.17%; all three criteria unbreached. B has $0 and is DO-NOT-ACTIVATE. |
| D:CRM:2026-07-09 | +25.58% | none | declined | **Merit** — peer take-private rumour is a multiple event, touches no criterion. |
| D:DIS:2026-05-07 | **−5.86%** | dip-with-intact-thesis | declined | Best-formed case in the book. **Capital only** — 4th consecutive session. |
| D:DIS:2026-08-05 | +0.98% | none | declined | Above cost after DIS +1.53%; no tranche-level dip. Same capital constraint. |
| D:RTX:2026-04-27 | +24.64% | none | declined | Only real decliner (−1.02%) but **driver unidentified** — same epistemic bar that declined UBER yesterday. A 1% move on a name +24.6% up is a wobble. |
| D:AMZN:2026-07-30 | −0.21% | none | declined | AMZN −0.80%; sub-1% drift is not a dip. No AWS-metric news. |
| D:AMZN:2026-07-09 | +9.90% | none | declined | Same session, tranche well above cost. Wobble. |
| D:GOOGL:2026-07-09 | −3.75% | none | declined | Underwater but GOOGL *rose* 0.82% — no fresh dip; structural-remedy overhang unresolved, which argues for waiting. |
| D:GOOGL:2026-07-26 | +5.65% | none | declined | Above cost, same unresolved overhang. |
| D:TSM:2026-07-21 | +0.61% | none | declined | +0.31% session; thesis intact but nothing moved either way. |
| D:TSM:2026-07-29 | +9.57% | none | declined | No dip, no new information on the three inherited criteria. |
| D:GEV:2026-08-03 | +8.20% | none | declined | +0.92%; primary trend metric reports quarterly, no in-window update. |
| D:ISRG:2026-07-20 | +14.81% | none | declined | Closed **exactly unchanged** (401.27 both sessions) on a +0.70% index day. The most literal no-op in the book. |
| D:UBER:2026-07-09 | +3.65% | none | declined | Recovered +0.69%, retiring yesterday's near-miss: the unexplained −4.05% dip has substantially reversed **without ever acquiring an explanation**. |

Logged as ONE `entry_type='add-candidate-review'` row carrying all 14 dispositions verbatim. **Record-only — changes no gate, blocks nothing.**

---

## ANALYSIS — REGIME CHECK

**ONE inter-monthly router review is flagged, for Strategies A and D.** The bar here is high and the default is NO; this clears it, and the counter-case is recorded alongside.

**The claim.** `policy_stance = hawkish` (M1a, as-of 2026-08-01) rests in its own written rationale on a *specific, named, numeric* input: *"Fed funds futures ended July pricing ~66% odds of a September hike and roughly two hikes to ~4.125% by year-end."* Across two sessions that input has **inverted**: July CPI (+0.1% m/m, released 2026-08-12) and July PPI (**0.0% m/m against +0.2% expected**, released 2026-08-13) have moved September-**hold** odds to **65–68%**, with one source putting September *hike* odds at ~34% against ~55% a week earlier. The 2Y fell 5bp to 4.15% and the 10Y 5bp to 4.63% on the day.

**Why it is load-bearing rather than merely interesting.** Both A's and D's DO-NOT-ACTIVATE calls, resolved 2026-08-05, rest on the **Strategy.md:123 reconciliation override**, which requires **`growth_momentum = decelerating` AND `policy_stance = hawkish`** to fire at all. The A orchestrator record states this outright — the DNA is "architecturally over-determined" *because* both preconditions hold. The D record likewise turns on the override's precondition status. **If `policy_stance` ceases to be hawkish, that override is precondition-failed and inert for both strategies**, exactly as the D review found had already happened to the *inflation* leg. This is not a narrative shift; it is the named input to a pre-committed mechanical rule reversing on two dated primary-source releases.

**The counter-case, recorded and not disposed of:**
1. `policy_stance` is a **composite** axis, and its other components are unchanged — the 9–3 July FOMC split with three dissents for an identical hike, Chair Warsh's removal of forward guidance and "no soft inflation target" framing, and the June SEP's upgraded 3.8% median dot. Futures odds are one input, not the axis.
2. Barkin, speaking the same day, **explicitly declined to endorse the repricing** ("I won't spoil the plot today"). No Fed official validated the dovish move in window.
3. `inflation_trend = stable` was scored 2026-08-01 with an explicit warning that the energy-led disinflation driver had **already reversed** and would mechanically re-inflate the next print. Brent falling back to $87.00 today cuts *toward* the benign read — but two prints against a core CPI that has oscillated in a 2.47–2.82% band for three quarters is thin evidence for a durable turn.
4. The **other** leg of the override strengthened today: jobless claims at 209k vs 202k consensus reinforces `growth_momentum = decelerating`.
5. M1a re-scores the axis monthly and will pick this up on 2026-09-01 regardless — roughly 12 trading days away.

**Disposition.** The recommendation is a **review**, not a flip, and that is the whole of the claim: point 5 is the strongest objection and it is an argument about *timing*, not about whether the evidence has changed. Two dated primary-source prints inverting the specific numeric input that two strategies' DO-NOT-ACTIVATE calls were built on is enough to warrant looking before the monthly cycle does. Conviction **MEDIUM**. No entry follows from this today even if the review flipped both routers — A and D both hold `available_funds = 0`.

**No other strategy's activation state is plausibly affected.** B's DNA rests on the `shock_overlay = acute` universal override, and today's evidence on that axis is genuinely two-sided (rhetorical escalation, price de-escalation) — nowhere near enough to move it. C is scope-limited to FOMC-only by a separate adjudication with no FOMC in window. E is ACTIVATE and nothing challenged it.

---

## EQUITY-BREADTH OBSERVATION

**MEASURED: 73.16%** of S&P 500 constituents closed above their own 200-day SMA, **as-of 2026-08-13**.

Source: published Barchart index **`$S5TH`**. **`date_attribution = source_dated`** — unlike the 2026-08-10 and 2026-08-12 rows, the page rendered its own session-date field *filled* this run: the quote read verbatim **"73.16 unch on 08/13/26"**, and the 1-Month period table independently carried "Period High: 73.16 unch on 08/13/26". Two independent live fetches returned the identical dated string. No post-close inference was needed or used.

**Arithmetic tie-out, exact — and it retrospectively settles the prior row's stated ambiguity.** Barchart published a day change of **+5.45%**. Yesterday's D1 recorded **69.38** for 2026-08-12. **69.38 × 1.0545 = 73.1613 ≈ 73.16.** Today's figure reconciles to yesterday's through an independently published change, which **confirms** that yesterday's `inferred_post_close` attribution of 69.38 to the 08-12 session was correct. The residual ambiguity that row honestly flagged is now closed.

**Cross-check: rejected, not counted.** Investing.com's S5TH page returned **71.17 and 69.38 on two live fetches minutes apart**, with no stable as-of date (one carried an ambiguous "12/08" token). Recorded because knowing which trackers are unreliable is durable; **not** treated as corroboration. Even had it been counted, the largest gap to 73.16 is 3.78pp — inside the 5pp suppression threshold — so no suppression was owed on any reading.

**Direction: +3.78pp expansion, a one-month high** (1-month low 62.62 on 2026-07-21). Yesterday's narrowing interior — breadth *falling* 1.79pp on an up day, one sector carrying the entire index gain — **reversed decisively in one session**: RSP (+0.75%) outpaced SPY (+0.70%) and ten of eleven sectors rose. Written to `events.regime_events` with `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`. The HEALTHY/WEAK threshold is D2a's to apply on `TECHNICAL_SIGNAL` and is deliberately not applied here.

---

## PARK ALLOCATION CALL

- **vehicle:** **VOO** (KEEP — equal to `state.park_policy_current.vehicle`, effective 2026-08-03). `direction = keep`, `status = BOUND`.
- **conviction:** **HIGH**, `conviction_pct = 70` — raised from the 60 the 2026-08-03 SGOV→VOO switch itself carried.
- **rationale:** The runner-up is SGOV, and today moved against it *on its own ground*. SGOV's entire case is a front-end yield paid for taking no equity risk; the front end repriced **down** today — 2Y −5bp to 4.15%, 10Y −5bp to 4.63%, September-hold odds to 65–68% — after a flat PPI. Meanwhile all three conditions the 08-03 re-risk named are not merely intact but extended: SPY is above its 50-day (748.12) at a **record 777.88**, VIX at **14.63** is below both its 50-day and 200-day and inside the LOW band for a second session, and the FOMC/Mag-7 event cluster is behind us. Two things improved that were **not** part of that call. First, the advance was **broad** — equal-weight RSP (+0.75%) *outpaced* cap-weighted SPY (+0.70%) and breadth expanded 3.78pp to a one-month high; VOO's specific risk is being a cap-weighted vehicle carried by a handful of names, and that risk receded today rather than grew. Second, the 08-03 call rejected every *intermediate* menu instrument on the grounds that "duration is unambiguously unfavourable (30Y 5.23%, within 4bp of a 19-year high)"; that objection is softening, but it argues for GOVT/IEF/TLT and not for SGOV, and not by enough to displace a tier-4 vehicle in an established uptrend. The menu still collapses to a tier-0/tier-4 binary and the binary tilted further toward tier 4.
- **invalidation:** ANY of — (a) Brent closes back above ~$95, or a confirmed Hormuz closure or further step-down from the 16-vessel 08-11 transit level; (b) VIX closes back above its 50-day (~17.4) **while** SPY closes below its 50-day (~748); (c) published breadth (`$S5TH`) falls back below 50%; (d) the September path re-prices toward a hike (hold odds back below ~50%), restoring the front-end case for SGOV that today weakened.
- **theater_check:** The tell would be a KEEP that recites yesterday's reasons because they are already on file. Two guards. The call is stated as a comparison against a named runner-up whose case is the one that actually *moved* today, so the reasoning is new rather than restated. And the strongest counter is stated without being disposed of: `shock_overlay` is still scored **acute**, VOO is the tier-4 instrument on the menu, and this parks the entire free book in equities at an all-time high against a live naval blockade and a public dispute over control of Hormuz. That exposure is real, unhedged, and **accepted deliberately**. What changed today is the direction of the evidence on it, not its existence — Brent −1.66% and gold −1.08% mean the commodity and haven complex moved *toward* the equity read for the first time this week. A KEEP that had to ignore an oil spike to stay coherent would be theater; this one is being paid by the tape that would otherwise have threatened it. Conviction is held at 70 and not higher precisely because one Hormuz-closure headline reverses the whole argument in a session.

Heartbeat written to `ops.heartbeat` (`loop:park_allocator`). Logged to `events.decision_log` as `entry_type='park-allocation'`.

---

## RECOMMENDED ACTIONS

- **Router review recommended — Strategies A and D (`policy_stance` axis).** Two dated primary-source inflation prints in two sessions (July CPI 2026-08-12 +0.1% m/m; July PPI 2026-08-13 **0.0% m/m vs +0.2% expected**) have inverted the specific numeric input M1a cited for `policy_stance = hawkish` — September-hold odds now 65–68% against the ~66% *hike* odds the axis was scored on. Both A's and D's DO-NOT-ACTIVATE calls rest on the Strategy.md:123 override, which requires `policy_stance = hawkish` to fire at all; if the axis flips, the override is precondition-failed and inert for both. MEDIUM conviction; counter-case (composite axis unchanged on its other components, Barkin declining to validate the repricing, M1a re-scores 2026-09-01) recorded in full in ANALYSIS — REGIME CHECK.

**No other recommended actions.** No exits triggered, no new entry candidates routable, no add candidates flagged, no watchlist changes.

```yaml d1_actions
- action: router_review
  ticker: n/a
  strategy: n/a
  detail: >-
    Strategies A and D — inter-monthly router review of the policy_stance axis. July CPI
    (2026-08-12, +0.1% m/m) and July PPI (2026-08-13, 0.0% m/m vs +0.2% expected) have moved
    September-hold odds to 65-68%, inverting the ~66% September-HIKE odds M1a's 2026-08-01
    policy_stance=hawkish rationale explicitly cites. Both A's and D's DO-NOT-ACTIVATE calls
    rest on the Strategy.md:123 reconciliation override (growth_momentum=decelerating AND
    policy_stance=hawkish); a non-hawkish policy_stance renders that override precondition-failed
    and inert for both. MEDIUM conviction. Counter-case recorded: the axis is composite and its
    other components (9-3 FOMC split, Warsh no-forward-guidance, 3.8% median dot) are unchanged;
    Barkin declined to validate the repricing same-day; M1a re-scores 2026-09-01. No entry follows
    even on a flip — A and D both hold available_funds = 0.
```

---

## PROCESS NOTES (not actions)

- **Price-basis near-miss, caught.** The single-name sweep first returned FMP post-close *snapshots* because the EOD chart endpoint was plan-gated. Nothing was written up as delivered; all 26 names were re-measured on IBKR regular-session bars. The re-measurement confirmed rather than corrected (max discrepancy 0.01pp; no name changed side of the 5% floor) — recorded so a future run knows the snapshot path was accurate *on this date* without being licensed to use it.
- **FMP plan-gating is now materially degrading coverage.** ACCESS DENIED this run on: `chart/historical-price-eod-full` for all but six whitelisted symbols, `economics/economics-calendar`, `news/press-releases`, `quote/batch-quote`, and index/forex EOD (DXY, WTI). `calendar/earnings-calendar` returned only **one** name (CSCO) for 2026-08-12→13 against a universe of 170–300 daily reporters. Every macro and earnings figure in this file was therefore sourced from primary agency releases and SEC filings via web search rather than from FMP. **WTI and DXY have no clean dated close for 2026-08-13** and are not asserted anywhere in this file. Flagged for W5 — this is a tooling constraint that is now shaping what the screen can see, not a one-off.
- **Frontier-LLM capability check:** one `hf_fs` paper-search query run (sycophancy / anchoring battery). All five results predate the scan window (2024-10 through 2025-10); **nothing published since the last D1 run**, so no capture and no `state.strategy_candidates` row. Silent by default, as specified.
- **Capital concentration.** All free capital ($15,309.94) sits in **E**, the only strategy both ACTIVATE and funded. C is capital-*enabled* but holds **$0** after the 2026-08-12 `nomadic_capital_sweep` under its permanent NOMADIC classification. Each step is documented and none is a defect, but the combination means four of five strategies cannot act at all — noted for W5 rather than alarmed here.
