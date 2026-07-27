2026-07-27
<!-- d1_scan_through_utc: 2026-07-27T22:40:00Z -->

# Daily Market Development Scan — 2026-07-27 (Mon, MT)

Scan window: 2026-07-26 16:11 MDT → 2026-07-27 16:40 MDT (~24.5h — normal daily cadence; `state.routine_catchup_window` `window_days` 0.99, no `CATCHUP` token warranted). Window start resolved from the prior `Daily.md` marker (`d1_scan_through_utc: 2026-07-26T22:11:28Z`), cross-checked against `git log -1 --format=%cI -- Daily.md` = 2026-07-26T22:29:41Z (agree to within one session length, as the fallback rule expects). **Today IS a trading day** (`state.trading_day_today.is_trading_day = true`) and the window contains exactly one full US cash session (Mon 7/27, closed 16:00 ET). Connectors: BigQuery / IBKR / FMP / Tavily / WebSearch / HF all UP. **FMP's ETF and batch-quote endpoints were plan-gated this session** (`ACCESS DENIED`, lower-tier plan) — single-symbol `quote` still worked, so `^VIX` and SPY are FMP-authoritative but the sector-ETF table is web-sourced and carries an unresolved sign conflict (flagged in DEVELOPMENT 4). Sub-agent research fleet (6 Sonnet agents) did the source sweeps; conflicts are flagged inline rather than silently resolved. **All open-position marks below are IBKR-connector values, not web quotes**, per the source-of-truth precedence rule.

**Tape summary.** A **dispersion/rotation session, not a directional one.** S&P 500 **7,413.18** (+0.02%); Dow **52,210.08** (+0.51%); Nasdaq Composite **24,932.08** (−0.18%); Russell 2000 **2,948.03** (+0.61%) — small caps and cyclicals led, cap-weighted tech lagged. **SPY 739.09 (+0.02%) — still BELOW its 50dma (745.07)**, above its 200dma (698.54), −2.80% from the 252-day high. **VIX 18.67** (+0.48%; FMP `^VIX` quote, authoritative — 50d avg **17.35**, 200d avg 18.72; a MarketWatch widget showed 18.89, discarded in favour of the spec's FMP source). 10Y ~**4.64%** (−3bp), 2Y ~4.30%, 30Y ~5.13% (CNBC intraday; no confirmed FMP closing print for 7/27 — the feed's last row is 7/24). **Brent −6% to −8.7%, WTI ~−8%** to roughly $82–86 — the day's dominant macro fact. Gold $4,074.50 settle (+0.17%); DXY 101.41 (−0.06%); EURUSD 1.1371, USDJPY 163.73; BTC $64,663 (−1.03%). `hy_oas` **2.74** (FRED, June ref-month) — historically tight, no credit stress. Two structural shocks ran in opposite directions all session: a weekend US-Iran bombing pause collapsed oil and lifted cyclicals/travel/small-caps, while a China-lithography report and the CXMT Shanghai debut crushed AI-semiconductor leadership — netting to a dead-flat S&P.

## TL;DR

- **Exits triggered: none.** Mechanical sweep clean on all 11 book rows + the connector union. MDT $84.22 vs $90 target — **time-exit Fri 2026-07-31, 4 sessions out; still the one dated risk in the book** (see STAGING-DEPENDENCY below). ISRG/B $356.81 vs $400, time-exit 9/18. No D-book trigger before 2027. Kill sweep clean (live-mark refresh: B ≈ 0% drawdown / new high, D ≈ −3%; nothing near −50%).
- **New entry candidates: 3 — ASML, AMD, SNDK (all Strategy B, long direction).** All three fell ≥5% close-to-close on one identifiable public event (China domestic DUV lithography mass-production report + CXMT debut). ASML carries an unresolved ADR-vs-"US-listed common equity" eligibility question that thesis construction must settle first.
- **Add candidates: none.** DIS, CRM and TSM were each evaluated and declined with reasons recorded (ADD-CANDIDATE CHECK below); no position clears the gate cleanly today.
- **Watchlist changes: 5 note refreshes** — ORCL, NVDA, AMAT, MU, ADBE. No adds, no removes, no demotions.
- **Regime review: no review.** High bar not met; one session of oil does not move a monthly axis, and the actual policy event is Wednesday's FOMC.

---

# DEVELOPMENTS

## 1. Market-wide breaking events

**a. US–Iran: the bombing pause holds, oil collapses — but this is a pause, not a settlement.** After US Central Command paused 13 consecutive nights of strikes on Fri 7/24–Sat 7/25 (before the window), the pause continued through the weekend with Omani mediators reporting "constructive" talks. **Inside the window,** Iran's Foreign Ministry (spokesman Esmaeil Baghaei) stated Monday that Tehran is **not** seeking to resume direct talks with Washington and maintains the Strait of Hormuz remains closed on Iran's telling — a claim the US (Hegseth) disputes. *Sources: CNBC https://www.cnbc.com/2026/07/27/us-iran-war-trump-hormuz.html; Al Jazeera https://www.aljazeera.com/news/2026/7/27/why-has-the-us-halted-its-bombing-of-iran; DW live blog https://www.dw.com/en/iran-rules-out-us-talks-as-hormuz-strait-remains-closed/live-78127467.*
**Reaction across asset classes:** Brent −6% to −8.7% (source dispersion across contracts and snapshot times is real; direction and magnitude corroborated by WSJ, Reuters, Barchart, TradingEconomics), WTI ~−8% to ~$82. 10Y −3bp to ~4.64%, 2Y −2bp to ~4.30%. Equities: Dow +0.51%, Russell +0.61%, S&P +0.02%, Nasdaq −0.18%. S&P energy sector −2.54%; airlines up (AAL +3.28%, JBLU +3.04%); oilfield services down (HAL −2.67%). Gold +0.17% to $4,074.50 settle. Deutsche Bank (Monday note via CNBC): "a welcome pause from the main actors but a fragile one, especially with side battles still ongoing," flagging Bab el-Mandeb/Red Sea transits at multi-month lows after Houthi–Saudi exchanges Sunday (Kpler).
**Read:** this *reduces* the acute oil-inflation channel but does **not** resolve `shock_overlay` — Iran ruling out talks while the Strait question stays contested is the definition of *latent*, not *resolved*. One unconfirmed item (a DW-reported Iranian claim about an alleged Ukrainian strike on Iran) is labelled unconfirmed and not corroborated elsewhere.

**b. China begins mass-producing domestic immersion DUV lithography tools — the day's most structurally significant single item.** The Information reported Monday that a state-backed Shanghai company has begun mass-producing homegrown immersion DUV machines — previously an ASML monopoly — with initial delivery this year to SMIC, Hua Hong and CXMT (~5 units in 2026, ~20 in 2027). The report explicitly frames this as eroding the leverage behind the pending US MATCH Act export-control legislation. *Sources: Reuters https://www.reuters.com/world/china/china-begins-making-homegrown-duv-chipmaking-tools-information-reports-2026-07-27; Tom's Hardware.* **Reaction:** ASML −5.8% (range to −7.1% across sources), erasing early gains of >2%; AMAT −3.61%, LRCX −4.46%, KLAC −3.40% in sympathy.

**c. CXMT's Shanghai debut, +~470%.** Changxin Memory Technologies, the world's #4 DRAM producer, debuted on the STAR Market after raising ~¥57.9–66.8B (~$8.6–9.9B) — the year's largest Asian IPO — closing up ~465–472% at ~¥3.3T (~$487B), making it mainland China's most valuable listed company. *Sources: Reuters via Virginia Business; Times of India.* Not a US-listed name, so out of the single-name screen's population, but it is the second half of the memory/China-capacity shock that hit SNDK (−11.02%), MU (−2.25%), WDC (−4.21%) and STX (−4.07%).

**d. Nvidia–OpenAI reported ~$250B financing backstop reignites circular-financing concern.** WSJ and Bloomberg reported, confirmed by CNBC Monday, that Nvidia is in talks to provide up to a $250B financing backstop for OpenAI's 10-gigawatt Ohio data-center project with SoftBank's energy arm (total project cost >$500B), separately from ~$350B in chip-purchase discussions. *Sources: CNBC https://www.cnbc.com/2026/07/27/nvidia-and-openai-in-talks-for-up-to-250-billion-dollar-ai-backstop.html; Axios.* **Reaction:** NVDA −4.99%, market cap temporarily falling below Apple's. Michael Burry (Scion, on X, 7/27): "Around and around we go. Nvidia to guarantee $200 billion of ChatGPT's spending on $NVDA chips," disclosing an increased NVDA short as of Fri 7/24. The originating report first surfaced over the weekend; the confirmation and the price reaction are inside the window.

**e. Republic National Distributing Co. (RNDC) Chapter 11.** The former #2 US wine-and-spirits distributor filed voluntary Chapter 11 in S.D. Texas Sunday 7/26 (case 9:26-bk-90736 and related) to formalize a wind-down, listing $1B–$10B in liabilities to >100,000 creditors; National Distributing Co. and most JV entities are excluded. *Sources: VinePair; Shanken News Daily; PacerMonitor.* No discernible index reaction (private company); relevant only as a supply-chain credit event for beverage-alcohol suppliers.

**No material items in-window** for: new large-cap-tech antitrust/enforcement action (the EU's €890M Google DMA fine was 7/23, **outside** the window — flagged, not reported as new); natural disasters or infrastructure disruption; central-bank surprises (the Fed has been in pre-FOMC blackout since 7/18, no Fed speakers in-window); new tariff or export-control **announcements** (the Section 301 forced-labor tariffs took effect 7/24 and the Section 338 Canadian tariffs were announced 7/20 — both outside the window; several 7/27-dated recap pieces are analysis of pre-window actions).

## 2. Scheduled events that resolved today

**Earnings prints** (US-listed, mkt cap ≥ $2B). A light day ahead of this week's mega-cap wave:

| Ticker | EPS actual vs cons | Revenue actual vs cons | Guidance | Reaction |
|---|---|---|---|---|
| **BKR** Baker Hughes | Adj. $0.64 vs ~$0.50 (GAAP diluted $0.68) | $6.742B vs $6.523B (+3.3%) | Record orders $10.5B (+49% YoY); IET record $7.1B; adj. EBITDA margin +70bps to 18.3% | **+5.83%** — rose against a −2.54% energy tape |
| **AZN** AstraZeneca | Core $2.63 vs $2.48–2.49 | Q2 $15.38B vs $15.39B (in line) | FY26 reaffirmed: mid-to-high single-digit revenue, low-double-digit core EPS growth (CER) | LSE +1.7–1.8%; US ADR move not separately confirmed |
| **CDNS** Cadence | Non-GAAP $2.11 vs ~$2.05–2.10 | $1.584B vs $1.608B (**miss**, −1.5%; +24.2% YoY) | FY26 revenue **raised** to $6.26–6.34B; non-GAAP EPS raised to $8.05–8.15 | +4.37% after-hours (reported post-close) |
| **NUE** Nucor | Adj. $4.84–$4.87 (source variance) vs ~$4.53–4.57 | ~$10.4B vs ~$10.13–10.31B | Includes ~$0.20/sh non-cash Helion mark-to-market benefit | Post-close; **reaction not confirmed by press time** |
| **WELL** Welltower | Normalized FFO $1.60 vs $1.55 | $3.54B vs $3.39B | Guidance/dividend raise referenced | "Trades up"; exact % not confirmed |
| **TFII** TFI International | Diluted $1.65 (+41% YoY) — one source shows $1.59, **discrepancy unreconciled** | $2.29B (+12% YoY); ex-fuel-surcharge $1.90B (+6%) | Quarterly dividend +4% to $0.47 | Not confirmed |

**Explicitly did NOT report today** (several aggregators conflated "this week" with "today"): RTX (reported 7/22–23), SAP (prior week), WM / NXPI / BA / CARR / F / KO / PYPL / V (all 7/28).

**FDA:** nothing resolved in-window. The only advisory-committee event this cycle — the PCAC vote on 503A-bulks status for seven compounded peptides — concluded 7/23–24, outside the window.

**FOMC / central banks:** nothing resolved. **FOMC meets Tue–Wed 7/28–29 with the decision Wed 7/29 at 14:00 ET, no SEP.** Consensus is a hold at 3.50–3.75%; ING (7/27) notes markets price only ~8bp for the meeting and 41bp of cuts by year-end, and flags Chair Warsh's aversion to forward guidance as raising meeting-day surprise risk. Hawkish-surprise odds had been priced up to ~36% by Fri 7/24 on the oil-driven inflation scare (IBD); today's oil collapse cuts directly against that.

**US economic data released today:**

| Indicator (June unless noted) | Actual | Consensus | Prior |
|---|---|---|---|
| Durable goods orders MoM | **+0.30%** | +1.80% | −4.50% (rev. −4.00%) |
| Durables ex-transport MoM | +0.60% | +0.80–0.90% | +1.40% (rev. +1.80%) |
| Cap goods orders, nondef. ex-air MoM | **+0.90%** | +0.70% | +1.40% (rev. +1.90%) |
| Cap goods shipments, nondef. ex-air MoM | **+1.90%** | +0.60% | +0.10% (rev. +0.20%) |
| Dallas Fed manufacturing (July) | **1.3** | 0.0 | 0.0 |

Headline durables missed badly; the core capex internals (orders +0.9%, shipments +1.9%) beat clearly. A soft-headline/firm-core split, consistent with the `growth_momentum: stable` axis rather than challenging it.

**Other resolved catalysts:** no US-listed IPO ≥$2B priced or debuted (D-Wave's Nasdaq bell-ringing was a ceremony for an already-public company). No court rulings, shareholder votes or index rebalances resolving today; Nasdaq's GIDS feed change takes effect 7/28.

## 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

Layer-1 population rail surfaced **29** US-listed names ≥$2B moving ≥2% close-to-close on identifiable public events, plus **3 sub-2% items** judged extraordinary under §19's escape valve. Layer-2 judgment decides what is written up. Logged as one `entry_type='research-screen'` row, `screen='single-name-move'`.

**Judged significant (10):**

| Name | Move | Conviction | Why significant | `legacy_rule_pass` | `below_spec_floor` |
|---|---|---|---|---|---|
| **ASML** | **−5.80%** | 60 | China domestic immersion-DUV mass-production report attacks a **monopoly premise**, not a quarter; propagated mechanically into LRCX/AMAT/KLAC the same session | true | false |
| **SNDK** | **−11.02%** | 45 | Largest single-name expression of the memory/China-capacity shock — but the name is +858% YTD, so re-rating and overreaction are genuinely hard to separate | true | false |
| **AMD** | **−5.17%** | 45 | Fabless name marked down on a *lithography-tooling* story with no direct AMD exposure — the indiscriminate-sector-selloff shape Strategy B exists to test | true | false |
| **NVDA** | **−4.99%** | 60 | The day's most consequential *narrative* (up-to-$250B OpenAI backstop; Burry re-shorting on circular-financing grounds) — **but 1bp below B's frozen 5% floor** | **false** | **true** |
| **CRM** | +6.07% | 45 | Name-specific fundamental event (VA $1.6B agentic ELA follow-through; Agentforce ARR $1.2B, +205% YoY). Held in Strategy D — thesis-supportive | true | false |
| **BKR** | +5.83% | 45 | Q2 beat with record $10.5B orders lifting the name *against* a −2.54% energy tape — a clean idiosyncratic signal | true | false |
| **ORCL** | +4.27% | 45 | ~$7B 10-year DoD software-consolidation award (initial 5-yr tranche $3.31B) — a real name-specific event below the legacy bar, directly material to its queued A-thesis | **false** | true |
| **ISRG** | +5.73% | 30 | Driver is a **celebrity marketing collaboration** (Deion Sanders) — low information content; significant to *this book* only because ISRG is held in B (target $400) and D | true | false |
| **SHOP** | +11.54% | 30 | Analyst initiations/upgrades only (MS Overweight $192; Jefferies/Stifel to Buy), no company event; already tracked as a B short-direction-declined name | true | false |
| **FBRX** | +39.65% | 30 | argenx $77/share cash tender at an 86% premium — price pinned to the offer, no mean-reversion mechanism; notable as a biotech-M&A signal only | true | false |

**Rejected despite clearing the legacy ≥5% bar (6 — `rule_only`):** TEAM +10.35%, IONQ +9.38%, WDAY +9.01%, ADSK +7.70%, NOW +6.86%, ADBE +5.62%. Five of the six are the enterprise-software rotation with **no name-specific event** — six outlets describe one "sell hardware, buy software" rotation, so the significant object is the *rotation* (captured in the sector screen), not any member name. IONQ is rejected separately: no catalyst identified and ≥$2B population membership could not be verified.

**Sub-2% extraordinary (§19 escape valve, 3):** **AAPL +1.17%** to $336.91, at/near a record two days before its print, the world's largest company decoupling *upward* from a Nasdaq falling on a chip rout. **MSFT +1.94%** to $389.10, riding the software-over-hardware rotation while reporting Wednesday into elevated AI-capex scrutiny. **TSLA −1.22%** — a sub-2% day is itself notable given last week's reported ~14–18% two-day post-Q2 crash.

Agreement: `both` 8, `ai_only` 2 (NVDA, ORCL), `rule_only` 6.

**Sourcing caveat carried into the log:** FMP batch/ETF quote endpoints were plan-gated, so several percentages come from a Barchart late-session table. That table was cross-validated to the basis point against directly-queried FMP closes on AMD/MU/NVDA and against MarketWatch on NVDA/AMD/INTC/KLAC before being relied on.

## 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

Layer-1 rail surfaced **5** items: four sector ETFs ≥1% (XLE −2.54%, XLK +1.48%, XLY +1.12%, XLI +1.08%) plus one dispersion surfacing. Logged as one `entry_type='research-screen'` row, `screen='sector-move'`.

| Sector | Move | Conviction | Judgment | `legacy_rule_pass` |
|---|---|---|---|---|
| **Energy** | **−2.54%** | 75 | Only sector-wide decliner and the cleanest attributable move on the tape — direct read-through from Brent −6/−8.7%, mirrored in airlines (+3%) and oilfield services (−2.7%). Significant not for magnitude but because it is the market pricing a change in the regime's `shock_overlay` term, **and** because an oil collapse of that size is a disinflationary impulse two days before an FOMC where a hawkish surprise had been priced near a third | true |
| **Technology** | +1.48% (dispersion surfacing) | 75 | XLK closed **+1.48% while containing** SNDK −11.0, ASML −5.8, AMD −5.2, NVDA −5.0, LRCX −4.5, WDC −4.2, STX −4.1, AMAT −3.6, KLAC −3.4, MU −2.3 **and** TEAM +10.4, WDAY +9.0, ADSK +7.7, NOW +6.9, CRM +6.1, ADBE +5.6, ORCL +4.3, INTU +4.2. A cap-weighted sector printing +1.48% while its two largest sub-industries move ~15 points apart is a far more informative object than any 2%-plus headline sector move — the AI trade fracturing along hardware-vs-application lines rather than trading as a bloc | **false** (dispersion-only surfacing, per §19 convention) |

**Rejected:** Consumer Discretionary +1.12% and Industrials +1.08% — second-order oil-down/cyclical beta with no independent sector driver. Both are double-rejects (fail the judgment *and* the legacy ≥2% bar) and are recorded only because the Layer-1 rail surfaced them. Full table: XLK +1.48, XLY +1.12, XLI +1.08, XLF +0.71, XLC +0.55, XLB +0.50, XLV +0.28, XLU +0.23, XLRE +0.21, XLP +0.14, XLE −2.54.

> **⚠ UNRESOLVED DATA CONFLICT — stated, not silently resolved.** FMP's ETF-quote endpoints were plan-gated all session, so the sector table above is **Benzinga-sourced and unconfirmed**. A Zacks/Globe-and-Mail wire reports **XLK down 1.4%** — the opposite sign — and also gives different index closes (S&P 7,411.98, Dow 51,947.25, Nasdaq 24,975.82) than the AP wire. Benzinga's XLK sign was weighted higher because it is the only one consistent with the FMP-confirmed closes of the mega-caps inside XLK (MSFT +1.94%, AAPL +1.17%) and with the confirmed software complex. **Neither finding above depends on the disputed number:** the Energy finding does not use the sector table at all, and the dispersion finding holds under either XLK sign — a sector containing a 21-point spread between SNDK and TEAM is dispersed whichever way the cap-weighted aggregate printed.

Agreement: `both` 1 (Energy), `ai_only` 1 (Technology), `rule_only` 0.

## 5. Notable commentary

- **Deutsche Bank** (Monday, via CNBC) — energy and shipping remain the dominant near-term market risk; the pause is "welcome but fragile," with Red Sea transits at multi-month lows per Kpler.
- **ING FX Daily (7/27)** — expects a Fed hold Wednesday but flags Chair Warsh's aversion to forward guidance as raising meeting-day surprise risk; favours precautionary USD buying pre-FOMC. Markets pricing ~8bp for the meeting, 41bp of cuts by year-end. *https://think.ing.com/downloads/pdf/article/fx-daily-pre-fomc-positioning-may-favour-the-dollar*
- **Michael Burry** (Scion, X, 7/27) — on the Nvidia–OpenAI backstop: "Around and around we go. Nvidia to guarantee $200 billion of ChatGPT's spending on $NVDA chips"; disclosed an increased NVDA short as of 7/24.
- **Sell-side actions that moved names** (Yahoo/24-7WallSt, 7/27). *Upgrades:* GOOGL → Buy at Phillip Securities (PT cut $450→$425); F → Buy at Jefferies (PT $17.50); RIVN → Overweight at Piper Sandler (PT $20); SIRI → Equal Weight at Wells Fargo (PT $18→$30); RKLB → Outperform at KGI (PT $107). *Downgrades:* STLA double-downgrade Overweight→Underweight at Piper Sandler (PT $14→$4); ACI → Neutral at Citi; HBAN → Neutral at BofA; WBD → Neutral at Seaport; VALE → Neutral at Goldman. **Position-relevant:** TD Cowen raised **RTX** to $240 from $225 (Buy); Needham raised **TSM** to $530 from $480 (Buy).
- No regulator or central-bank speech content in-window — Fed blackout since 7/18.

---

# ANALYSIS — RISK TO EXISTING POSITIONS

## MECHANICAL EXIT-TRIGGER SWEEP

Run for **every** open position, over the **union** of `state.current_positions` (11 rows) and live `get_account_positions` (13 lines), regardless of whether any Development fired. Marks are IBKR-connector values.

| Position | Strategy | Shares | IBKR mark | Convergence target | Time exit | Trigger? |
|---|---|---|---|---|---|---|
| B:MDT:2026-06-17 | B | 0.4852 | **$84.22** | **$90.00** | **2026-07-31** | **NO** — $5.78 (6.4%) below target; time exit is 4 sessions out, not today |
| B:ISRG:2026-07-21 | B | 0.1388 | $356.81 | $400.00 | 2026-09-18 | NO — $43.19 (10.8%) below target; time exit 53 days out |
| D:RTX:2026-04-27 | D | 0.1601 | $218.63 | — | 2027-04-27 | NO — time exit 9 months out |
| D:UBER:2026-07-09 | D | 0.5156 | $68.08 | — | — | NO — no mechanical trigger defined |
| D:DIS:2026-05-07 | D | 0.2822 | $96.86 | — | — | NO |
| D:CRM:2026-07-09 | D | 0.2275 | $173.86 | — | — | NO |
| D:AMZN:2026-07-09 | D | 0.1554 | $231.39 | — | — | NO |
| D:GOOGL:2026-07-09 | D | 0.1043 | $327.00 | — | — | NO |
| D:GOOGL:2026-07-26 | D | 0.1534 | $327.00 | — | — | NO |
| D:ISRG:2026-07-20 | D | 0.1091 | $356.81 | — | — | NO |
| D:TSM:2026-07-21 | D | 0.0891 | $398.60 | — | — | NO |

**Result: no EXIT TRIGGERED flags. Zero mechanical exits for D2 to convert today.**

**Connector-union reconciliation — no reconciliation-lag position.** `state.current_positions` carries 11 rows; the connector reports 13 lines. Every difference is explained:
- **GOOGL 0.2577 sh** in the connector = 0.1043 (parent) + 0.1534 (the Rev-40 add tranche) — **the add order filled at today's open** (IBKR order 84254447, MARKET/DAY, owner-confirmed 7/26). Both tranches are already rows in `state.current_positions`, so this is **not** a lag case. Implied fill ≈ $329.50 vs the $318.85 provisional reference — D2a's fill reconciliation at 16:20 MT owns the cost-basis correction. **This fill is what clears the `state.position_reconciliation` drift that has held `state.trading_enabled = FALSE` since 7/25** (see STAGING-DEPENDENCY below).
- **SGOV 88.7917 sh / $8,936.88** and **VOO 0 sh** — the **park book**, governed by `state.park_policy_current` (vehicle SGOV, effective 2026-07-26), not by any entry record. Both park legs (VOO SELL 13.2219, SGOV BUY 88.7917) filled at today's open, completing the 7/26 BOUND de-risk.
- **HCA 0.0001 sh ($0.04)** and **IBM 0.0007 sh ($0.15)** — residual dust from Strategy-B positions that BigQuery already records as terminal (`events.position_events`: IBM CLOSE/CLOSED 2026-05-27, HCA CLOSE/CLOSED 2026-06-29). These are broker-side fractional rounding artifacts on *reconciled, closed* lifecycles, not unreconciled positions.

**No `sp_raise_alert_once('warning','D1','position_reconciliation_lag', …)` is warranted this run.** The ITEM-14 gap this check exists to close — a position live in IBKR but *absent* from BigQuery — does not occur today. Same disposition as the 2026-07-26 run, on independently re-verified evidence.

## PER-STRATEGY KILL-TRIGGER SWEEP

`perf.kill_flags` is as of 2026-07-24 (D1 runs before D2a/D2, so the engine row is the prior close). **`current_drawdown` was refreshed unconditionally against today's live marks for every open position**, per the ITEM-16 rule that removed the judgment predicate on whether to run this refresh at all.

| Strategy | Engine (7/24) unit / peak / drawdown | Today's live-mark P&L | Refreshed drawdown | Flags |
|---|---|---|---|---|
| **B** | 1.084632 / 1.115458 / **−2.76%** | +$3.17 on $90.39 deployed = **+3.63%** | Unit ≈ **1.124** — **above the prior peak; drawdown ≈ 0%, a new high** | `drawdown_kill` false, `runaway_review` false (unit 1.12, not doubled), `gate_reached` false (22/30 closed trades), `interim_underperf_warning` **false** |
| **D** | 0.977725 / 1.029318 / **−5.01%** | +$7.12 on ~$331.7 deployed ≈ **+2.2%** (overstated slightly — the GOOGL add injected ~$50 of fresh capital today) | Unit ≈ **0.998** → drawdown ≈ **−3.1%** | `drawdown_kill` false, `runaway_review` false, `gate_reached` false (0/30), `interim_underperf_warning` **false** (deployed_days 62 < 90) |

**No STRATEGY TERMINATION — DRAWDOWN flag. No RUNAWAY-SUCCESS REVIEW flag.** Both strategies are an order of magnitude away from the −50% mechanical kill.

**Interim-underperformance warning:** `interim_underperf_warning = FALSE` for both strategies, so no `sp_raise_alert_once` is raised. HEAL-RESOLUTION check run as specified: **no open `ops.alerts` row of category `interim_underperf_warning` exists**, so there is nothing to resolve.

**B open-book pairwise-correlation warning (KL #12 control):** `analytics.b_pairwise_correlation` returns `n_positions = 2`, `n_pairs = 1`, `avg_offdiagonal_corr = NULL`, `min_overlap_days = NULL`. The alert condition (`avg > 0.5 AND n_positions >= 2 AND min_overlap_days >= 40`) **fails on the NULL**, correctly. Reason: ISRG opened 2026-07-21, giving the MDT↔ISRG pair only ~4 overlapping trading days — far below the 40-day maturity guard, so the view excludes the single pair from its own average by design. **No alert.** This check becomes live if ISRG is still open around mid-September; MDT's 7/31 time-stop will likely return B to a single position first.

## Judgment-laden thesis-invalidation check, per position

| Position | Triggering development | Criterion met? |
|---|---|---|
| **D:GOOGL** (both tranches) | No GOOGL-specific news in-window; +2.13% to $327.00. Phillip Securities upgraded to Buy (PT $450→$425) | **NO.** All four recorded criteria unbreached, re-verified: (a) cloud rev YoY <20% for 2Q — Q2 (7/22) cloud growth was well above 20% on any source; (b) cloud margin contraction 2Q — no; (c) cloud RPO sequential decline 2Q — RPO/backlog reached $514B; (d) adverse **structural** remedy — the 7/23 EU DMA €890M fine is confirmed **behavioral** (redesign Search ranking/Play steering within 60 days, no divestiture ordered) and had **no update in-window**; the US DOJ appeal remains pending at the D.C. Circuit with no ruling in-window. ⚠ **Unresolved source conflict, recorded not hidden:** one agent reported Q2 Google Cloud revenue +82% YoY, another +34% YoY. **The verdict is insensitive to it — both are far above the 20% floor** — but the true figure should be pinned before it is cited as a number anywhere. *Not exit-triggering:* Q2 FCF of −$5.9B (first negative quarter since the 2004 IPO) and 2026 capex guidance raised to $195–205B are capex-intensity facts, not cloud-growth-thesis breaches |
| **D:UBER** | **CNBC in-window: "Uber and Waymo revive robotaxi rivalry as partnership unravels"** — reporting a deteriorating alliance and a fight over the rider relationship, following a 7/24 CNBC report that Waymo was weighing ending the partnership | **NO — but this is the single most material position development of the day.** The stock rose **+3.40% to $68.08**, i.e. the tape read it as Uber reasserting an independent AV strategy rather than losing a partner. That is a defensible read, and the entry record carries no AV-partnership-specific invalidation criterion. But a multi-year platform thesis whose AV optionality partly rested on the Waymo tie-up now has an open question the market answered optimistically on one day's news. **Carrying forward as the book's top watch item into the 8/5 print.** Not an exit today |
| **D:TSM** | −1.07% to $398.60; Needham raised PT to $530 from $480 (Buy). Background: China MOFCOM reportedly weighing controls barring TSM from fabbing Huawei/Alibaba/ByteDance designs (FT, 7/21, pre-window) | **NO.** Today's China-DUV story is a *tooling* development that hits equipment makers, not a logic foundry, and CXMT is memory not logic. The mild decline against a −5% semis complex is itself evidence of relative insulation. Directionally adverse to the long-run China-exposure axis; not a breach |
| **B:ISRG** + **D:ISRG** | +5.73% to $356.81 on a Deion Sanders marketing collaboration | **NO.** Moves *toward* the $400 B target; low information content but not adverse. Background context retained: the 7/16 Q2 print beat (revenue $2.89B +19%, procedures +16%, 468 da Vinci placements) yet the stock **fell ~8% after-hours and >11% the next morning** on procedure-growth softness — which is why the name sat well below target before today's bounce |
| **B:MDT** | No material MDT-specific news in-window; +1.21% to $84.22. Only routine items (a MarketBeat consensus-rating snapshot, a Lazard 13F reduction) | **NO.** Needs +6.86% in 4 sessions to reach $90 — the base case remains the **7/31 time-exit**, consistent with W3 2026-W30's HOLD-to-time-stop recommendation |
| **D:CRM** | +6.07% to $173.86 on VA $1.6B agentic-ELA follow-through; Agentforce ARR $1.2B, +205% YoY | **NO** — thesis-supportive |
| **D:AMZN** | −0.31% to $231.39. FCC filing (7/25, reported in-window) for up to 5,105 D2D satellites combining Kuiper with the ~$11.6B Globalstar acquisition. Pre-earnings previews flag ~$200B annualized capex as a reaction risk | **NO.** **Q2 earnings Thu 7/30 after the close — 3 days out** (cons. EPS $1.82, revenue ~$196.8B). That print, not today's tape, is the thesis test |
| **D:DIS** | No material DIS-specific news in-window; +1.90% to $96.86 (routine 13F items only) | **NO.** **FQ3 earnings Wed 8/5 — 9 days out** (cons. EPS $1.88, revenue ~$25.4B) |
| **D:RTX** | +2.65% to $218.63. TD Cowen PT $225→$240 (Buy). One secondary source (TradingKey) attributes part of the move to a multi-billion-dollar DoD award — **contract detail unconfirmed** (a DoD contract-briefs fetch returned HTTP 403) | **NO** — thesis-supportive. Following the 7/23 beat-and-raise (adj. EPS $1.89 vs $1.66; FY guidance raised on sales, EPS and FCF) |

## Watchlist candidacy status changes

- **ORCL** (A queue, bullish OCI/RPO thesis) — **materially strengthened.** A ~$7B, 10-year DoD software-consolidation award (initial 5-year tranche $3.31B) is precisely the bookings-ramp evidence the queued thesis predicted; +4.27% today.
- **NVDA** (A queue, bullish sovereign-AI/Rubin thesis) — **new counter-evidence.** −4.99% on the reported up-to-$250B OpenAI financing backstop, with a named short-seller publicly framing it as circular financing. This is a *different* class of objection from the valuation-reset caveat already on file: it questions demand quality, not price. The valuation-reset caveat itself eases on the drawdown.
- **AMAT** (A queue, bearish "China WFE cliff" thesis, marked REFUTED-at-print with the framing-flip deferred to next M1 ACTIVATE) — **the original bearish framing is materially re-supported.** China beginning domestic immersion-DUV mass production is the structural China-WFE-substitution risk that thesis named; −3.61% today. This is direct input to the deferred framing-flip decision.
- **MU** (A queue, bullish HBM/DRAM-tightness thesis) — **−2.25%,** extending Friday's −6.99%. The CXMT debut and China memory-capacity expansion are a genuine supply-side counter to the DRAM-tightness premise, not merely sector sympathy. Valuation-reset caveat eases further; the *thesis* premise weakens slightly.
- **ADBE** (A queue, bearish "AI monetization lagging" thesis) — **+5.62%** in the software rotation. Rotation beta rather than an execution datapoint, but it is the second consecutive session of the market re-rating exactly the software-AI-monetization cohort the bearish thesis is short.
- **AAPL, LLY, INTC** — the 7/26 notes stand; D2's catch-up window re-reads that file, so they are not restated here. AAPL's +1.17% to a near-record two days pre-print is captured in DEVELOPMENT 3's sub-2% escape valve.
- **SHOP, CDW, PYPL, MGM** (B short-direction-declined tracking) — SHOP +11.54% on analyst initiations. Consistent with the standing observation that declined shorts extend rather than fade; no disposition change, no action.
- All other queued names: **unchanged.**

---

# ANALYSIS — OPPORTUNITY CHECK

Evaluated for every roster-active strategy with `review_cadence: reactive` in `strategy/roster.yaml` — **A, B, C, E** (D is `long_horizon` and excluded here; it is in scope for the ADD check below). Not scoped to watchlist names.

## Strategy B — ACTIVATE (confirmed). Three candidates, all long.

Today produced a rare clean setup: **one datable public event drove a cohort of ≥5% single-day declines**, and B's entry criterion 1 (≥5% close-to-close on event day, either direction) is met on the *down* side — the direction B is long-biased toward, rather than the pop-fade the router structurally disfavours. Router state is intact: SPY Trend ≠ DOWN and VIX 18.67 is NORMAL, not HIGH.

1. **ASML — −5.80%, close ~$1,655 (ADR).** Event: The Information's report that a Shanghai state-backed firm has begun mass-producing homegrown immersion DUV tools, delivering ~5 units in 2026 and ~20 in 2027 to SMIC/Hua Hong/CXMT. The overreaction case is quantitative and testable: ~5 tools this year against ASML's shipment base, from a competitor with no demonstrated yield, service network or throughput parity. The counter-case is that this is a *permanent-moat* repricing, not a quarter — in which case there is no convergence to trade. **⚠ Eligibility question thesis construction must settle FIRST:** B's instrument rule requires "US-listed **common equity**," and ASML's US listing is a New York Registry Share (ADR), not common equity. If that fails, the candidate dies on eligibility regardless of the thesis.
2. **AMD — −5.17%, close $494.95.** Event: the same lithography report plus AI-financing jitters. This is the purest indiscriminate-sector-selloff shape in the cohort — AMD is fabless, fabbed at TSMC, and has no direct exposure to Chinese DUV tooling. Counter-argument to construct: whether the market is pricing a broader AI-capex-quality re-rate (the Nvidia/OpenAI backstop story) that legitimately impairs AMD's demand outlook, in which case the "unrelated" framing is wrong.
3. **SNDK — −11.02%, close $1,278.23.** Event: the CXMT Shanghai debut (+~470%, ~$487B) crystallising Chinese memory capacity. Largest move in the cohort, and the weakest overreaction case: the name is **+858% YTD**, so separating overreaction from an overdue re-rate is the whole problem, and new DRAM/NAND supply is a genuine, durable threat to memory pricing. Surfaced honestly as the lowest-conviction of the three.

**Explicitly NOT routed as B candidates:**
- **NVDA −4.99%** — `below_spec_floor = true`. Per §19's spec-floor rail this is context and SL1 ideation evidence **only**, never a tradeable candidate. It is 1bp from the floor; the floor is the floor.
- **The +5% software cohort** (TEAM, WDAY, ADSK, NOW, ADBE, SHOP) — all *up* moves, so any B trade is a short. B is long-biased by construction, not by screen miscalibration: 0 of ~108 B theses have produced a short entry, and every declined short has held or extended. Adding to that record without a router relaxation would be wilful.
- **CRM +6.07% / ISRG +5.73%** — both clear the floor but both are **already held in Strategy D** (and ISRG in B). A B entry would be a short against an existing long in the same name.
- **FBRX +39.65%** — price pinned to a $77 cash tender; no mean-reversion mechanism exists.

## Strategy C — HYBRID ACTIVATE (FOMC-only). No new candidate; material new evidence for the queued one.

No new qualifying FOMC-class catalyst was announced today, so **no new C candidate.** But the already-queued `thesis-FOMC-C-20260726` (`PENDING_ANALYSIS`, due 2026-07-26, **entry deadline 2026-07-28**) received genuinely material new evidence: today's 6–8.7% oil collapse cuts directly against the oil-driven inflation scare that had pushed hawkish-surprise pricing to ~36% by Friday, and ING notes only ~8bp is priced for the meeting itself with no SEP. That materially changes the distribution a defined-risk FOMC structure would be priced against. **This is flagged for D2's queue drain, not as a new action** — see the note under RECOMMENDED ACTIONS.

## Strategy A — DO-NOT-ACTIVATE (confirmed, M4 2026-07).

The router is off, so A signals route to the watchlist queue only. Today's A-relevant developments (ORCL, NVDA, AMAT, MU, ADBE) are handled as **note refreshes on already-queued names** under Watchlist updates. **No new names added to the A queue** — with the router off and 25+ names already queued, adding a name without a specific 6-month-horizon catalyst thesis would be padding, not queueing.

## Strategy E — ACTIVATE (substantive) + execution-feasibility-deferred.

Today produced textbook E material: a **large intra-industry-group divergence inside Technology** (semis/hardware −2% to −11% against enterprise software +4% to +10% in the same session), plus a clean cross-sector mirror pair (airlines +3.0/+3.3% against oilfield services −2.7% on the same oil move). **This is recorded as tracking evidence for M2's monthly pair screen, NOT routed as an entry candidate**, for two independent reasons: E's frozen entry criterion 3 requires 252-day correlation ≥ 0.5 (unmeasured here — a one-day divergence is not a correlation estimate), and the execution-feasibility-deferred gate blocks any live entry at the ~$1.9k/strategy book size regardless. Queueing a thesis that cannot execute would waste a D2 drain slot.

---

# ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only — Rev 40)

Open positions in scope: **B** — MDT, ISRG. **D** — UBER, DIS, CRM, AMZN, GOOGL ×2, ISRG, TSM, RTX. **A** — none open. (C and E never get an add flag here.)

**Result: no ADD candidates flagged.** Three positions were genuine near-misses and are recorded with reasons so the calls are auditable rather than silent:

- **D:DIS — the closest formal case, declined.** Marked $96.86 against a $111.32 average cost (−13.0%), the deepest drawdown in the book, with **no material in-window news** — formally "adverse price action with no invalidation news." Declined on three grounds: (i) the entry record carries **no recorded at-entry invalidation criteria** (`invalidation_status` NULL), and the hard gate requires *positive confirmation* that those criteria are unbreached — an absent list cannot be confirmed unbreached, only assumed; (ii) FQ3 earnings land **8/5, 9 days out**, so a fresh tranche would ride a binary print it was not sized for; (iii) a −13% drift accumulated over ~2.5 months with no identifiable catalyst reads more like slow thesis erosion than a discrete dip. Better resolved after the 8/5 print, on a re-read of the source thesis.
- **D:CRM — declined.** The strengthened-conviction trigger is genuinely met on fundamentals (VA $1.6B agentic ELA; Agentforce ARR $1.2B, +205% YoY). Declined because the contract was public **Friday 7/24** and the stock has already repriced +6.07% for it today: a strengthened-conviction add is meant to capture information the market has *not* absorbed, and buying on the session the market absorbs it is the weakest version of that trade. Same NULL-invalidation-criteria gate problem as DIS.
- **D:TSM — declined.** −6.0% from a $423.93 entry with a thesis that has arguably strengthened (Q2 record, FY26 revenue growth guided >40%, capex raised to $60–64B, $100B Arizona expansion, +10% 2027 pricing, Needham PT $530 today). But this is **not** a dip with no invalidation news: the day's dominant development — China accelerating domestic semiconductor tooling and memory capacity — is thematically adverse to the exact geopolitical/moat axis TSM's long-run thesis rests on, compounding the 7/21 FT report on Chinese controls barring TSM from Huawei/Alibaba/ByteDance designs. Default-NO on ambiguity.

**Declined without close consideration, with reasons:** **B:MDT** — 4 days from its time-stop; adding to a position with no convergence runway is definitionally wrong. **B:ISRG** — up 5.73% on a celebrity marketing collaboration, which is neither a dip nor a fundamental conviction-strengthener. **D:GOOGL** — an add tranche was staged 7/26 and **filled at today's open**; a second tranche the same session is churn, and there is no new dip (+2.13%) or new conviction event. **D:AMZN** — earnings in 3 days; an add here is an earnings bet, not a thesis add. **D:UBER** — down 6.1% from entry, but today's Waymo development is unresolved *news*, so this is not "adverse price action with no invalidation news"; it must resolve first. **D:RTX** — genuinely strengthened on fundamentals but already the book's largest winner (+23.6%) with the beat-and-raise and PT raises broadly priced. **D:ISRG** — same reason as B:ISRG.

---

# ANALYSIS — REGIME CHECK

**No inter-monthly router review recommended.** High bar; default NO on ambiguity, and the bar is not met.

The candidate argument is real and worth stating: a 6–8.7% single-session oil collapse is a genuine disinflationary impulse against the `inflation_trend: reaccelerating` axis, and it arrived alongside a soft durable-goods headline. But (i) one session does not move a monthly axis scored on CPI/PPI/PCE prints, (ii) Brent has already round-tripped once this cycle — it fell to ~$73 on the mid-June ceasefire and was back at $96.78 by Friday, so a de-escalation-driven move is precisely the kind that has reversed before, (iii) Iran ruled out direct talks *the same day*, so `shock_overlay` stays **latent** rather than resolving, and (iv) the actual event with the power to move `policy_stance` is **Wednesday's FOMC**, 2 days away, which is M1a/M1b/M4's business on their own cadence and not something to pre-empt with an inter-monthly review. Router states for A/B/C/D/E are all unchanged on today's evidence.

---

# PARK ALLOCATION CALL

- **`vehicle`** — **SGOV** (KEEP; today's opening `state.park_policy_current.vehicle` is SGOV, effective 2026-07-26). The 7/26 BOUND de-risk legs **filled at today's open** and are visible in the connector: VOO 0 shares, SGOV 88.7917 shares / $8,936.88. This is the **first binding call** under the 2026-07-26 owner directive promoting loop `park_allocator` to `active_auto`; KEEP is the trivially-BOUND case and D2's PARK ALLOCATION CONVERSION no-ops.
- **`conviction`** — **MEDIUM**, `conviction_pct` **60**.
- **`rationale`** — The runner-up is **VOO** (re-risk to tier 4), and its case is real: oil collapsing 6–8.7% is disinflationary, it materially lowers the hawkish-FOMC-surprise odds that were priced near a third late last week, 10Y fell ~3bp with it, and `hy_oas` at 2.74 shows no credit stress anywhere. I am declining it **on timing, not on thesis.** The FOMC decision lands **Wednesday 7/29, inside 48 hours** — no SEP, a chair averse to forward guidance, only ~8bp priced for the meeting — with MSFT, AAPL and AMZN printing into the back half of the same week. Re-risking ~96% of NLV into tier-4 equity beta the session *before* that binary, having moved to tier 0 for that exact binary 24 hours ago, is a round trip whose only certain outcome is two more sets of commissions. Crucially, the technical premise behind the 7/26 de-risk has **not** decayed on today's own close: SPY 739.09 is still **below** its 50dma (745.07), exactly as on 7/23 and 7/24, and VIX 18.67 is still **above** its 50d average (17.35) and rose on the day. Duration (IEF/TLT/GOVT) stays ruled out for the reason today did not change — with inflation reaccelerating and the dot plot carrying a hike tilt, taking duration into a hawkish-tilted FOMC is the wrong side of the same event. LQD/HYG/PFF/AOR add credit or equity beta to buy a spread already at 2.74 — no compensation. **SGOV is the rung that is indifferent to Wednesday.**
- **`invalidation`** — A benign or dovish 7/29 FOMC **and** SPY reclaiming 745.07 with VIX back below 17.35 → re-risk toward VOO on the next call. Conversely, `hy_oas` widening materially off 2.74, or a resumption of kinetic strikes reversing the oil move, keeps or deepens tier 0.
- **`theater_check`** — The rationale is not narrating a foregone conclusion, and the test is that **the genuinely new evidence today points the other way**: oil down, yields down, credit pristine are all arguments *to re-risk*. I am declining that specific, identified argument for a specific, dated reason, not because nothing changed and not because KEEP is the default. The falsifier is stated and observable. Counter-check from the other side: a KEEP that were merely one-day-old inertia would be exposed if the 7/26 switch had rested on evidence that has since decayed — it has not, and both premises (SPY below 50dma, VIX above its 50d average) were re-read independently on today's close rather than carried forward.

Logged: `events.decision_log` `entry_type='park-allocation'`, `status='BOUND'`, `direction='keep'`, with the full `readings` evidence snapshot. Heartbeat written: `ops.heartbeat ('loop:park_allocator', 'SGOV call, status=BOUND')`.

---

# ⚠ STAGING-DEPENDENCY FLAG (carried forward, materially improved today)

`state.trading_enabled` has been **FALSE since 7/25** on a `state.position_reconciliation` drift, blocking two consecutive D2 runs (7/25, 7/26) and leaving 6 `PENDING_ANALYSIS` theses undrained. The sole remaining blocker was the D:GOOGL add-tranche lag (`current_positions` 0.2577 vs `position_lifecycle` 0.1043; diff 0.1534 = exactly the pending add). **That order filled at today's open** — the connector now shows GOOGL 0.2577 — so **D2a's Step-0 fill reconciliation at 16:20 MT today is expected to clear the drift and flip the gate TRUE**, exactly as alert `7ef50e04` predicted. D2a had not yet run at this scan's close (16:40 MT); `ops.run_log` for 2026-07-27 shows only OPS1, OPS2 and this D1 run, which is **on schedule**, not a miss (D1's slot is 16:00, D2a's 16:20, D2's 17:15).

**Why this still matters:** the **MDT Strategy-B time-stop is Friday 2026-07-31**, and that exit stages through D2, which runs its own trading-enable gate. Four sessions of runway remain. If the 7/27 D2a run does **not** clear the drift, this becomes an owner-action item rather than a self-healing one. Two open `trading_halted` alerts (`29eb4bae` warning, `a35dcba0` critical) still narrate the **superseded** dashboard/`automation_heartbeat` root cause (resolved 7/26 03:58Z) and would send a human chasing a fixed problem; D1 does not resolve them — `trading_halted` is capital-affecting and stays human-only under `ops.alert_policy`'s fail-closed allowlist.

---

# RECOMMENDED ACTIONS

> **Context for D2's queue drain — NOT a recommended action and deliberately excluded from the bullet count and the YAML block below.** The already-queued `thesis-FOMC-C-20260726` (entry deadline **2026-07-28**, one day out) has material new evidence as of today: the 6–8.7% oil collapse cuts against the oil-driven inflation scare that had lifted hawkish-surprise pricing to ~36% by Friday, and only ~8bp is priced for Wednesday's meeting with no SEP. Weigh it in the drain; do **not** create a second queue row. The other five due-7/26 theses (ELV, DHR, MSCI, VZ, SLB) are unchanged by today's developments.

- **New entry candidate — ASML, Strategy B (long).** −5.80% close-to-close on 2026-07-27, the event day, on The Information's China domestic immersion-DUV mass-production report. Clears B entry criterion 1; 10-day entry window closes 2026-08-10. Full thesis construction required in a separate session per Strategy.md. **Thesis must first resolve instrument eligibility:** ASML's US listing is a New York Registry Share (ADR), and B's instrument rule specifies "US-listed common equity" — if that fails, the candidate dies on eligibility.
- **New entry candidate — AMD, Strategy B (long).** −5.17% close-to-close on 2026-07-27 on the same lithography report plus AI-financing jitters; US-listed common equity, mkt cap ~$807–851B, ADV far above the $10M floor. Clears B entry criterion 1; window closes 2026-08-10. Full thesis construction required in a separate session. Central counter-argument to test: whether the sell-off prices a broader AI-capex-quality re-rate that legitimately impairs demand, rather than an unrelated tooling story.
- **New entry candidate — SNDK, Strategy B (long).** −11.02% close-to-close on 2026-07-27 on the CXMT Shanghai debut and Chinese memory-capacity expansion. Clears B entry criterion 1; window closes 2026-08-10. Full thesis construction required in a separate session. Lowest conviction of the three and flagged as such: the name is +858% YTD, so overreaction and overdue re-rate are hard to separate, and new DRAM/NAND supply is a durable threat to memory pricing.
- **Watchlist update — ORCL (A queue), note refresh.** Won a ~$7B, 10-year DoD software-consolidation award (initial 5-year tranche $3.31B); +4.27%. Materially ratifies the queued bullish OCI-bookings/RPO-ramp thesis at exactly the bookings layer it predicted. No disposition change; A router remains DO-NOT-ACTIVATE.
- **Watchlist update — NVDA (A queue), note refresh.** −4.99% on the reported up-to-$250B Nvidia financing backstop for OpenAI's Ohio build, with Burry publicly framing it as circular financing and disclosing an increased short. This is a **new class of objection** to the queued bullish thesis — demand *quality*, not price — distinct from the valuation-reset caveat already on file, which itself eases on the drawdown.
- **Watchlist update — AMAT (A queue), note refresh.** −3.61% on China beginning domestic immersion-DUV mass production. This **materially re-supports the original queued bearish "China WFE cliff" framing** that was marked REFUTED-at-print with the framing-flip deferred to the next M1 ACTIVATE; direct input to that deferred decision.
- **Watchlist update — MU (A queue), note refresh.** −2.25%, extending Friday's −6.99%. The CXMT debut and Chinese memory-capacity expansion are a genuine supply-side counter to the queued bullish DRAM-tightness/HBM premise, not merely sector sympathy — the *thesis* weakens slightly even as the valuation-reset caveat eases further on the drawdown.
- **Watchlist update — ADBE (A queue), note refresh.** +5.62% in the enterprise-software rotation — a second consecutive session of the market re-rating exactly the software-AI-monetization cohort the queued bearish thesis is short. Rotation beta rather than an execution datapoint, but recorded as counter-evidence.

*No exits triggered. No add candidates. No router reviews recommended.*

```yaml d1_actions
- action: thesis
  ticker: ASML
  strategy: B
  detail: "-5.80% close-to-close on event day 2026-07-27 (The Information report of Chinese domestic immersion-DUV mass production); clears B entry criterion 1, window closes 2026-08-10; thesis must FIRST resolve whether an ADR/New York Registry Share satisfies B's 'US-listed common equity' instrument rule"
- action: thesis
  ticker: AMD
  strategy: B
  detail: "-5.17% close-to-close on event day 2026-07-27 (same lithography report + AI-financing jitters); fabless with no direct DUV-tooling exposure, the indiscriminate-sector-selloff shape B tests; window closes 2026-08-10"
- action: thesis
  ticker: SNDK
  strategy: B
  detail: "-11.02% close-to-close on event day 2026-07-27 (CXMT Shanghai debut, Chinese memory-capacity expansion); lowest conviction of the three - +858% YTD makes overreaction vs overdue re-rate hard to separate; window closes 2026-08-10"
- action: watchlist
  ticker: ORCL
  strategy: A
  detail: "note refresh - ~$7B 10-year DoD software-consolidation award (initial 5-yr tranche $3.31B), +4.27%; materially ratifies the queued bullish OCI-bookings thesis; no disposition change, A router still DO-NOT-ACTIVATE"
- action: watchlist
  ticker: NVDA
  strategy: A
  detail: "note refresh - -4.99% on the reported up-to-$250B OpenAI financing backstop; new demand-QUALITY objection (circular financing, Burry short) distinct from the existing valuation-reset caveat, which itself eases on the drawdown"
- action: watchlist
  ticker: AMAT
  strategy: A
  detail: "note refresh - -3.61% on China domestic DUV mass production; materially re-supports the original bearish China-WFE-cliff framing that was marked REFUTED-at-print with the framing-flip deferred to next M1 ACTIVATE"
- action: watchlist
  ticker: MU
  strategy: A
  detail: "note refresh - -2.25% extending Friday's -6.99%; CXMT debut and Chinese memory capacity are a supply-side counter to the queued bullish DRAM-tightness/HBM premise, not merely sector sympathy"
- action: watchlist
  ticker: ADBE
  strategy: A
  detail: "note refresh - +5.62% in the enterprise-software rotation, second consecutive session re-rating the software-AI-monetization cohort the queued bearish thesis is short; rotation beta, recorded as counter-evidence"
```

---

*Prose bullets: 8. `d1_actions` entries: 8. Cross-check agrees.*
