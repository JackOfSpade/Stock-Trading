2026-07-28
<!-- d1_scan_through_utc: 2026-07-28T22:28:24Z -->

# Daily Market Development Scan — 2026-07-28 (Tue, MT)

Scan window: 2026-07-27 16:40 MDT → 2026-07-28 16:28 MDT (~23.8h — normal daily cadence; `state.routine_catchup_window` `window_days` 0.98, no `CATCHUP` token warranted). Window start resolved from the prior `Daily.md` marker (`d1_scan_through_utc: 2026-07-27T22:40:00Z`), cross-checked against `git log -1 --format=%cI -- Daily.md` = 2026-07-27T22:45:39Z (agree to within one session length, as the fallback rule expects). **Today IS a trading day** (`state.trading_day_today.is_trading_day = true`) and the window contains exactly one full US cash session (Tue 7/28, closed 16:00 ET). Connectors: BigQuery / IBKR / FMP / Tavily / WebSearch / HF all UP. **FMP's ETF endpoints remain plan-gated** (`ACCESS DENIED` on every SPDR sector ticker and on the park-menu ETFs), so ETF figures are web-sourced — see the provenance note in DEVELOPMENT 4, which is load-bearing this session. Sub-agent research fleet (8 Sonnet agents) did the source sweeps; conflicts are flagged inline rather than silently resolved. **All open-position marks below are IBKR-connector values, not web quotes**, per the source-of-truth precedence rule.

**Tape summary.** A **rotation session, and a broad one.** S&P 500 **7,428.16** (+0.20%); Dow **52,747.32** (+1.03%); Nasdaq Composite **24,876.91** (−0.22%); Russell 2000 **2,953.80** (+0.20%). **8 of 11 GICS sectors closed green**, and equal-weight **RSP +1.17%** against cap-weighted **SPY +0.24%** — a 93bp spread that is the whole story of the day. The entire drag sat in AI hardware: **SMH −3.45%** against **IGV +0.96%**, with the Nasdaq-100 trading briefly into correction territory intraday before recovering. **SPY 740.86 (+0.24%) — still BELOW its 50dma (745.00)**, above its 200dma (698.89), −2.57% from the 252-day high. **VIX 18.21** (−2.46%; FMP `^VIX` quote, authoritative — 50d avg **17.37**, 200d avg **18.73**; VIX3M ~19.50, so the term structure is in **contango**, no stress signature). Curve rallied across the board: 2Y **4.26%** (−5bp), 5Y 4.35% (−5bp), 10Y **4.61%** (−4bp), 30Y **5.09%** (−3bp); 2s10s +35bp, ~1bp steeper. **WTI ~$79.15 (−4.2%)** — a third consecutive down day, which Bloomberg called Brent's worst three-day stretch since 2020. Gold $4,025.80 (−0.32%); DXY ~101.5 (flat); EURUSD 1.1391, USDJPY 163.82; BTC ~$63,900. `hy_oas` **2.74** (FRED, June ref-month; no print newer than 7/23 available anywhere) — historically tight, no credit stress. **The FOMC decides tomorrow, Wed 2026-07-29 at 14:00 ET, and the market is not pricing a cut at all — it is pricing hold-versus-HIKE**, with hike odds read between 31.5% and 37.6% across sources. That single fact dominates the PARK ALLOCATION CALL below.

## TL;DR

- **Exits triggered: none.** Mechanical sweep clean on all 12 book rows + the connector union. MDT $86.80 vs $90 target — **time-exit Fri 2026-07-31, 3 sessions out; still the one dated risk in the book.** ISRG/B $363.40 vs $400 (time-exit 9/18); MSCI/B $579.39 vs $615 (time-exit 9/25). No D-book trigger before 2027. Kill sweep clean on a live-mark refresh: B ≈ 0% drawdown / at a new high, D ≈ −1.1% (improved from −2.9%); nothing near the −50% kill.
- **New entry candidates: 3 — SANM, GLW, AMKR (all Strategy B, long direction).** All three fell ≥5% close-to-close today on one identifiable earnings event, all US-listed common equity, all ≥$2B. SANM is the cleanest: a beat-and-raise that fell 17.5% with no identified negative detail.
- **Add candidates: none.** All 11 open A/B/D positions evaluated; every one declined with a recorded reason (ADD-CANDIDATE CHECK below). Two were declined at the HARD GATE because their at-entry invalidation criteria are unrecorded and therefore cannot be confirmed unbreached.
- **Watchlist changes: 2 note refreshes** — MU, INTC. No adds, no removes, no demotions.
- **Regime review: no review.** The actual regime event is tomorrow's FOMC, 18 hours away; opening a router review tonight would pre-empt information that arrives before it could conclude.

---

# DEVELOPMENTS

## 1. Market-wide breaking events

**Thread A — US/Iran de-escalation continues; oil extends its collapse.** Continuation, not reversal, of Monday's crash.
- Bloomberg (Markets Wrap, 4pm NY, 2026-07-28): "West Texas Intermediate crude fell 4.2% to $79.15 a barrel"; Brent "saw its worst three-day stretch since 2020, driving bond yields down before the Federal Reserve decision."
- Al Jazeera (2026-07-28): Trump says Washington is in "very friendly negotiations" with Iran after pausing strikes; "On Tuesday, the third day of renewed talks continued, with the Strait of Hormuz at the centre of the discussions."
- The Hill (2026-07-28, 14:32 ET): mediators "reported progress in a potential ceasefire after both American and Iranian forces paused attacks."
- Counter-signal, same window — The Hindu (2026-07-28), quoting Iran's foreign ministry spokesman Esmaeil Baqaei: "at present, we are not engaged in any negotiations with the United States"; and Iran's joint military command stating any company or country receiving Iranian frozen assets as vessel compensation "won't be allowed to transit the Strait of Hormuz."
- **Reaction:** oil −4.2%; the whole Treasury curve lower (2Y −5bp, 10Y −4bp, 30Y −3bp), explicitly attributed by Bloomberg to the oil-driven disinflation read ahead of the Fed; energy equities down far less than the commodity (XLE −1.35%).
- ⚠ **Unresolved conflict:** WTI's exact close is not agreed across sources — Bloomberg $79.15 (−4.2%), investing.com $80.72 (−2.29%), a MarketWatch live snapshot $78.47 (−5.01%). Direction and rough magnitude are certain; the precise print is not. **No confirmed Brent closing print for Tuesday was obtained at all** — same-day reads spanned $81.59 to $92.16 and are not reconcilable. Do not reuse a Brent number from this file.

**Thread B — China DUV lithography / CXMT: follow-through, second session.**
- Reuters (2026-07-28): "investors were unsettled by reports of China's progress in developing homegrown deep ultraviolet (DUV) lithography tools, a potential step toward reducing the country's reliance on Western semiconductor equipment."
- WSJ live coverage (2026-07-28, 13:55 ET): "A nearly 6% drop this morning in the PHLX semiconductor index... briefly pulled the Nasdaq-100 index into correction territory, or 10% below a recent high."
- TSPA/SemiVision (2026-07-28) on the Monday CXMT Shanghai debut: closed at RMB 49 versus an IPO price of RMB 8.66, "a first-day gain of 466%," raising ~US$8.6B at a ~RMB 3.3 trillion market cap.
- Yahoo Finance (2026-07-28): "AI memory stocks surged more than 600% as HBM shortages drove premium pricing, but expanding supply has since erased between 30 and 50 percent of those gains. South Korea's KOSPI plunged 29% in a month."
- **Reaction:** SMH −3.45%, XLK −1.84%, MU −8.85%, SKHY −8.98%, INTC −5.86% — but offset market-wide, with 8 of 11 sectors green.
- **Standing precedent applied:** D2 adjudicated this exact theme as **information, not mispricing** on 2026-07-27 (SNDK NO-GO at 80 conviction, "CXMT supply shock is information, confirmed cross-sectionally"; AMD and ASML NO-GO the same session). Today's semiconductor casualties are therefore **not** routed as B candidates — see the OPPORTUNITY CHECK.

**Thread C — FOMC is tomorrow and has NOT resolved.** The Federal Reserve's own calendar confirms a two-day meeting July 28–29 with the decision and press conference **Wed 2026-07-29 at 14:00 ET**. Market pricing is hold-versus-hike, not hold-versus-cut: investing.com's CME Fed Rate Monitor (7/27 17:55 EDT) showed hold 62.4% / hike 37.6%, up sharply from 16.6% hike odds a week earlier; goldsilver citing CME FedWatch showed 36.5%; Barron's live coverage (7/28 ~16:08 ET) "traders see a 31.5% chance of a surprise rate hike." **These are expectations, not outcomes.** No Tuesday price action in this file should be read as an FOMC reaction.

## 2. Scheduled events that resolved in the window

**Economic data (Tue 7/28):**
- **Conference Board Consumer Confidence (July) — MISS.** "The Conference Board Consumer Confidence Index® decreased by 1.4 points to 90.8 (1985=100) in July, down from an upwardly revised 92.2 in June" against a ~92.3 consensus. Present Situation Index −3.6 pts to 114.9, "its third consecutive monthly decline"; Expectations Index flat at 74.7, below the 80 threshold the Conference Board itself associates with recession risk. Survey window July 1–22, spanning the Middle East conflict; grocery-price mentions "increased in frequency."
- **S&P Cotality Case-Shiller (May data).** National index +1.1% YoY, +0.6% MoM — with CPI at 4.2%, real home prices declined. The release itself carries a data caveat: no valid May update for the Detroit index due to Wayne County transaction delays.

**Earnings — reported BMO Tue 7/28** (actual vs consensus):

| Name | EPS | Revenue | Guide | Close reaction |
|---|---|---|---|---|
| **KO** | $0.97 vs $0.92–0.93 ✔ | $13.373B vs ~$13.17B ✔ | **RAISED** — FY26 comp EPS growth to 9–10%, organic rev ~5%, FCF ~$12.4B | **+5.00%** |
| **BA** | −$0.76 vs −$0.34 ✘ | $24.56B vs $24.26B ✔ | Record $715B backlog; FCF $0.6B | **+3.98%** |
| **PYPL** | $1.38 vs $1.28–1.30 ✔ | $8.682B vs $8.473B ✔ | **RAISED** — FY26 non-GAAP EPS ~$5.38 | **+4.01%** |
| **UPS** | $1.76 adj vs $1.65 ✔ (GAAP $0.71) | $22.8B vs $21.68B ✔ | **RAISED** — FY rev ~$91.2B | premarket +2% → **reported −6.8% intraday; close unconfirmed** |
| **CARR** | $0.86 adj vs $0.82–0.83 ✔ | $6.351B vs $6.018B ✔ | **RAISED** — FY adj EPS mid ~$2.90 | **−8.90%** |
| **GLW** (7/27 AMC) | core $0.78 vs $0.76 ✔ | core $4.74B vs $4.61–4.63B ✔ | "mostly in-line," disappointed | **−16.1%**, "worst day in 6 years" |
| **IQV** | adj $6.04 (+9.8% YoY) | — | **RAISED** across rev/EBITDA/EPS | **+14.11%** |

⚠ **GLW sourcing conflict, unresolved:** a separate outlet reports revenue "$4.51 billion but fell short of Wall Street's estimates." That is **GAAP net sales ($4.505B)**, a different, non-comparable metric from the "core sales" $4.74B in the official release. Both are reported here; thesis construction must settle which frame the market traded on before relying on the over-reaction shape.

**Earnings — reported AMC Tue 7/28** (after-hours; not close-to-close events for today's screen):
- **F** — EPS $0.42 vs $0.31–0.33 ✔; GAAP net loss $1.3B on $4.2B of special items (a $3.6B BlueOval SK disposition charge, $0.5B EV cancellations); adjusted EBIT $2.5B. **FY26 guidance RAISED** to $10.0–11.0B adj EBIT (from $8.5–10.5B) and $6.0–7.0B adj FCF. Reported **+6.81%** after-hours on top of a +1.87% regular session. ⚠ Revenue is genuinely conflicted — $44.89B vs $48.3B (company 8-K); **unconfirmed**, do not reuse.
- **V** — non-GAAP EPS $3.32 vs $3.23 ✔; revenue $11.633B vs $11.400B ✔ (+14% YoY). After-hours quote roughly flat.
- **STX** — EPS $5.71 vs ~$5.14 ✔; revenue $3.629B vs ~$3.52B ✔. Reported **+7.03%** after-hours.

**FDA/PDUFA:** none resolved in-window. Two nearby and explicitly **unresolved**: Replimune RP1 PDUFA 2026-08-02 (ODAC expected 7/30), Capricor deramiocel 2026-08-22.

**Not in-window, flagged to prevent double-counting:** the J&J talc resolution framework is dated **2026-07-27** (Monday), is contingent on ≥95% claimant participation, and is not a court-approved settlement. One secondary source mislabeled it "Monday, July 28" — internally inconsistent, since 7/28 is a Tuesday.

## 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

Layer-1 rail surfaced **18** US-listed names ≥$2B market cap that moved ≥2% close-to-close today attributable to an identifiable public event. Four names that moved ≥5% — **PLTR −6.08, IREN −6.50, SNAP +5.42, RIG −5.40** — were **excluded from the population rather than rejected**: no identifiable public event could be attributed to any of them, so they fail the rail itself. Layer-2 passed 7. Logged as one `entry_type='research-screen'` row, `screen='single-name-move'`.

| Name | Move | Conv. | Judgment | `legacy_rule_pass` |
|---|---|---|---|---|
| **SANM** | **−17.46%** | 75 | Q3 FY26 beat both lines (EPS $3.31 vs $2.77; rev $3.46B, +69.7% YoY) **and** raised FY26 EPS guidance to $11.90–12.20 against $10.83 consensus — then fell 17.5% with no identified negative detail in any source. The largest reaction-versus-fundamentals gap on the tape | true |
| **AMKR** | **−24.74%** | 60 | Record Q2 (EPS $0.70 vs $0.48; rev $1.9B vs $1.81B) against a Q3 guide of $1.95–2.05B versus ~$2.10–2.12B consensus. A ~3% guide shortfall producing a 24.7% decline is disproportionate even granting the guide is genuine information | true |
| **GLW** | **−16.1%** | 72 | Core sales +17% YoY and core EPS both beat; guidance in-line. A six-year worst day on an in-line guide is a large reaction to a small information delta — subject to the GAAP-vs-core conflict above | true |
| **CARR** | −8.90% | 60 | Beat-and-raise sold off, but with an **identified** cause: segment operating margin −260bp, net income −15% YoY on unfavorable mix and input costs. The identified cause is exactly what makes it information rather than mispricing | true |
| **MU** | −8.85% | 60 | Third and largest session of the CXMT supply-shock repricing. Significant as a development; **not routed** — the theme was adjudicated as information on 7/27 and this is continuation, not a fresh event-day reaction | true |
| **IQV** | +14.11% | 60 | Q2 beat with FY26 revenue, EBITDA and EPS all raised; the single largest contributor to Health Care leading every sector, so it carries sector-level information beyond the name | true |
| **KO** | +5.00% | 45 | Q2 beat with FY26 guidance raised; a 5% move in a ~$380B staple is large for the name and corroborates the defensive bid visible in XLP +1.99% | true |

**Rejected (all nine legacy-rule-passing rejections recorded per §19's floor):** **CVLT** −19.70 (beat rev/EPS/FCF but billings declined YoY and missed — billings is *the* leading indicator for subscription software, so weighting the forward metric over the trailing beat is correct pricing); **ITRI** +26.23 and **KNSA** +25.03 (genuine guidance raises re-rating small/mid caps, not sentiment overshoots to fade); **LCID** +21.54 (a 13G passive-stake disclosure is an ownership fact, not a fundamental change); **JBLU** +10.50 (a 4-cent beat on a loss quarter — WTI −4.2% is the more plausible driver, so attribution to the print is unsafe); **SKHY** −8.98 and **INFY** +5.56 (**ADRs — fail B's "US-listed common equity" instrument rule outright**, the same gate that terminated ASML on 7/27); **INTC** −5.86 (no Intel-specific event; sympathy to the settled CXMT theme); **UPS** −6.8 (identified cause for the fade, and the close-to-close magnitude is itself unconfirmed).

Agreement: `both` 7, `ai_only` 0, `rule_only` 9.

## 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

> ⚠ **DATA-PROVENANCE NOTE — load-bearing, and it corrects the prior session.** The first sector table this session gathered came from an article dated July 28 that was in fact recapping the **July 27** session — its index levels matched Monday's closes exactly. It was caught and **discarded**. Every figure below instead comes from per-ticker quote pages carrying an explicit `Jul 28, 2026, 4:00 PM EDT` stamp, validated by a **SPY control** returning 740.86 / +0.24%, matching the independently-known Tuesday close.
>
> **The same failure mode corrupted yesterday's file.** The 2026-07-27 `Daily.md` reported XLK **+1.48** and XLE **−2.54** from a Benzinga morning snapshot, and explicitly flagged an unresolved sign conflict against a wire reporting XLK −1.4%. **The wire was right**: Monday's true closes were XLK **−0.90** and XLE **−2.11**. Yesterday's two findings both survive the correction — exactly as that write-up predicted, since the Energy finding did not use the sector table and the dispersion finding held under either XLK sign — but **the numbers in yesterday's sector table should not be reused.**

Layer-1 rail surfaced **8** sectors ≥1%: XLV +2.36, XLP +1.99, XLC +1.87, XLB +1.85, XLY +1.48, XLF +1.27, XLE −1.35, XLK −1.84. Below the rail: XLRE +0.55, XLU −0.35, XLI −0.39. Layer-2 passed 4. Logged as one `entry_type='research-screen'` row, `screen='sector-move'`.

| Sector | Move | Conv. | Judgment | `legacy_rule_pass` |
|---|---|---|---|---|
| **Technology** | **−1.84%** | 75 | **SMH −3.45% against IGV +0.96%** — a 4.4-point fracture *inside one sector*, on the second consecutive session of AI-hardware de-rating. The Nasdaq-100 traded briefly into correction territory intraday while the equal-weight S&P rose 1.17%. The tape is repricing AI **capex quality**, not risk appetite — a far more informative object than the headline sector number | false |
| **Health Care** | **+2.36%** | 60 | The only sector clearing the legacy 2% bar and the day's leader, on an identifiable driver rather than beta: a UBS medtech upgrade cluster (**ISRG Neutral→Buy, PT $500→$550**; ZBH double-upgrade to Buy; EW and SOLV to Buy; STE initiated Buy) plus IQV +14.11%. **Directly relevant to the open ISRG book** across B and D | **true** |
| **Consumer Staples** | +1.99% | 60 | A 1.99% defensive bid on a day the cap-weighted index rose 0.20% is the clean signature of the rotation, corroborated by Comm Services +1.87%, Discretionary +1.48%, and RSP +1.17% vs SPY +0.24%. Breadth broadened precisely as leadership narrowed — the inverse of a risk-off tape | false |
| **Energy** | −1.35% | 45 | Third session of the risk-premium unwind, but the sector fell only 1.35% against WTI −4.2%. **The equity complex treating the oil move as largely discounted is the informative part**, not the decline. Carries a disinflationary read-through into tomorrow's FOMC | false |

**Rejected:** Materials +1.85 and Financials +1.27 — cyclical/dollar and curve beta respectively, with no independent sector driver; both move *with* the rotation rather than leading or explaining it.

Agreement: `both` 1, `ai_only` 3, `rule_only` 0.

⚠ **Secondary conflict, stated not resolved:** FMP's `sector-performance-snapshot` (an *unweighted* average across GICS-classified NASDAQ stocks, not a cap-weighted ETF close) reports Consumer Defensive **−0.391%**, opposite in sign to XLP's confirmed +1.99%. Different methodology on a different universe; the cap-weighted ETF close is the figure used above, per §19's rule that `metric_pct` is always the raw sector-ETF close-to-close move.

**Breadth: deliberately not reported.** No advancers/decliners or new-highs/lows table carrying a verifiable Tuesday date stamp was obtained. The widely-circulated figures (1,374 adv / 773 dec, 30 new highs / 3 lows, 15.8B shares) belong to **Monday**. An unconfirmed number is worse than none here, given this session already caught two date-mislabeled sector tables.

## 5. Notable commentary

- **Central banks — Fed in blackout ahead of tomorrow's decision.** The one market-relevant central-bank voice was **RBA Governor Michele Bullock** (Anika Foundation address, Sydney, 2026-07-28), who made clear a rate rise will be discussed at the August meeting: "Domestic demand has eased broadly as expected and labour market conditions have softened somewhat… But with continued weak productivity growth, the economy can't grow strongly without putting pressure on inflation." ABC News reports the RBA "would be prepared to lift interest rates even higher, if it was necessary to achieve its inflation mandate." No confirmed US-session reaction; noted as a second developed-market central bank leaning hawkish into the same oil-driven inflation picture.
- **Sell-side, position-relevant.** **UBS upgraded ISRG Neutral→Buy, PT $500→$550**, as part of a medtech cluster that also double-upgraded ZBH to Buy (PT $115), lifted EW and SOLV to Buy, and initiated STE at Buy. This is the driver behind Health Care leading the tape and it bears directly on both open ISRG positions — see RISK TO EXISTING POSITIONS.
- **Other notable sell-side.** BofA upgraded **HON** Underperform→Neutral, PT $205→$265, citing "better-than-expected Q2 results and raised 2026 guidance, with strong orders across all business segments." BofA **downgraded XOM** Buy→Neutral (PT raised $154→$158 despite the downgrade). TD Cowen cut **INTU**'s target $504→$304 — the most severe single PT cut of the day. Jefferies cut **CLX** to Hold ($125→$98); UBS cut **ACI** to Neutral ($20→$12); Loop Capital initiated **CRWD** at Buy, $230; JPMorgan raised **IP** to Overweight ($51).
- **Corporate.** UPS CEO Carol Tomé and CFO Brian Dykes raised FY26 guidance across revenue, adjusted operating profit and adjusted EPS while absorbing $891M of transformation charges tied to the Driver Choice Program workforce reduction. GSK (CEO Luke Miels) reported sales £8.4bn (+5%), core EPS 50.5p (+9%), and specified FY guidance at "the upper half of range" for sales and operating profit, "lower half" for EPS.

---

# ANALYSIS — RISK TO EXISTING POSITIONS

## MECHANICAL EXIT-TRIGGER SWEEP

Swept the **union** of `state.current_positions` (12 rows) and live `get_account_positions` (13 rows incl. the SGOV park), per the ITEM-14 union rule. Live marks are IBKR-connector values.

| Position | Shares | Live mark | Convergence target | Time exit | Trigger? |
|---|---|---|---|---|---|
| B:ISRG:2026-07-21 | 0.1388 | $363.40 | $400.00 | 2026-09-18 | **no** — 9.1% below target |
| B:MDT:2026-06-17 | 0.4852 | $86.80 | $90.00 | **2026-07-31** | **no** — 3.6% below target; **time-exit in 3 sessions** |
| B:MSCI:2026-07-27 | 0.0863 | $579.39 | $615.00 | 2026-09-25 | **no** — 5.8% below target |
| D:AMZN:2026-07-09 | 0.1554 | $231.20 | — | — (LTCG 2027-07-09) | no |
| D:CRM:2026-07-09 | 0.2275 | $181.01 | — | — (LTCG 2027-07-09) | no |
| D:DIS:2026-05-07 | 0.2822 | $98.98 | — | — | no |
| D:GOOGL:2026-07-09 | 0.1043 | $334.50 | — | — (LTCG 2027-07-09) | no |
| D:GOOGL:2026-07-26 | 0.1534 | $334.50 | — | — (LTCG 2027-07-27) | no |
| D:ISRG:2026-07-20 | 0.1091 | $363.40 | — | — (LTCG 2027-07-20) | no |
| D:RTX:2026-04-27 | 0.1601 | $218.30 | — | 2027-04-27 | no |
| D:TSM:2026-07-21 | 0.0891 | $394.50 | — | — (LTCG 2027-07-21) | no |
| D:UBER:2026-07-09 | 0.5156 | $70.56 | — | — (LTCG 2027-07-09) | no |

**No EXIT TRIGGERED.** The single dated risk remains **MDT's Strategy-B time-stop on Fri 2026-07-31**, now 3 sessions out. It stages through D2, which runs its own trading-enable gate — the GOOGL reconciliation drift that blocked D2 on 7/25–7/26 has since cleared (D2a reconciled the fill on 7/27), so the path is currently open.

**Connector-union reconciliation notes:**
- **MSCI** is present in `state.current_positions` as a *provisional staging-time* row (cost_basis $570.95 is the staging reference price, not a fill) and is **filled in the connector** at 0.0863 sh / avg $579.28. D2a Step 0 supersedes the provisional row tonight. This is the designed handoff, not a lag — no alert.
- **HCA (0.0001 sh, $0.04) and IBM (0.0007 sh, $0.16)** appear in the connector but not in `state.current_positions`. Both are **fully-closed positions** — `events.position_events` shows HCA CLOSED 2026-06-29 (time-exit, 0.0642 sh sold) and IBM CLOSED — leaving sub-penny fractional broker residue. Their exit checks were run and are trivially clean (no convergence target, no time exit, no live thesis). **Deliberately NOT raised as `position_reconciliation_lag`:** that category's semantics are "awaiting a D2a Step-0 fill catch-up," and its resolver clears on an incoming fill matched by ticker — no fill is coming, so the alert would never resolve and would sit open permanently, which is exactly the noise `sp_raise_alert_once` exists to avoid. The residue already sits inside the tracked `analytics.account_reconciliation` residual ($39.81) and belongs to that reconciliation surface, not to this sweep. Flagged here for D2a/W5 rather than alerted.

## PER-STRATEGY KILL-TRIGGER SWEEP

`perf.kill_flags` is as of the 2026-07-27 close (D1 runs before D2a), so `current_drawdown` was **unconditionally refreshed against today's live marks** for every open position, per ITEM 16 — no judgment predicate.

| Strategy | Engine drawdown (7/27) | Refreshed on live 7/28 marks | Drawdown kill (≥50%) | Runaway (2×, pre-gate) | Interim underperf | Gate |
|---|---|---|---|---|---|---|
| **B** | 0.000 (at peak, unit 1.1241) | ≈ **0%** — B gained on the day (ISRG +1.63, MDT +1.25, MSCI +0.01 daily P&L); at/near a new high | **no** | no (unit 1.12, not 2×) | FALSE | 8 / 22 closed |
| **D** | −2.873% (unit 0.99975 vs peak 1.02932) | ≈ **−1.1%** — D gained ~+$5.89 on ~$337 deployed (+1.8%), improving the drawdown | **no** | no | FALSE | 0 / 30 closed |

All flags clean. `interim_underperf_warning` is FALSE for both strategies and **no open alert of that category exists**, so no heal-resolution `UPDATE` was required.

**B open-book pairwise correlation (KL #12 control):** `analytics.b_pairwise_correlation` returns `n_positions = 3`, `avg_offdiagonal_corr = NULL`, `min_overlap_days = NULL` — no pair yet has the ≥40 trading days of overlap the view requires (ISRG opened 7/21, MSCI today; MDT's only partners overlap ~5 sessions). The `> 0.5 AND n ≥ 2 AND overlap ≥ 40` condition therefore fails on the maturity guard, and **no `b_pairwise_corr_high` alert is raised.** Worth noting the check is now *approaching* live for the first time — B has held 3 concurrent positions since today, so this control becomes operative around mid-September if all three persist.

## Thesis-invalidation review (judgment-laden)

- **B:ISRG / D:ISRG — strengthened, not threatened.** UBS upgraded ISRG Neutral→Buy with PT $550 today; ISRG closed $363.40 (+1.8%). The B thesis (post-Q2 overreaction fade toward $400) and the D thesis are both *supported*. No invalidation criterion approached.
- **B:MSCI — unbreached, one session in.** All three recorded invalidation criteria (first analyst downgrade — still zero; a fresh close below the $550.79 post-event trough — today's $579.39 is 5.2% above it; further FY26 opex-guidance escalation — none) remain UNBREACHED. Filled at $579.28 today.
- **B:MDT — unbreached; the binding constraint is the calendar, not the thesis.** $86.80 against a $90 target with 3 sessions to the time-stop.
- **D:TSM — the one position with genuine adverse read-through.** The China domestic-DUV story is structurally negative for the leading-edge foundry moat, and TSM is −7.8% against cost. But D's recorded invalidation criteria are multi-year and TSM's Q2 was a beat-and-raise; a two-session sector de-rating is not a thesis invalidation on a `long_horizon` position. **NO** — criterion not met. Flagged for M3/Q2 rather than acted on here.
- **D:GOOGL (both tranches)** — the four recorded invalidation criteria (Cloud revenue YoY <20% for 2Q, Cloud margin contraction 2Q, Cloud RPO sequential decline 2Q, adverse structural remedy) are all recorded UNBREACHED as of the 7/26 add. Nothing today touches any of them. **NO.**
- **D:AMZN, D:CRM, D:DIS, D:RTX, D:UBER** — no Development in the window bears on any of them. **NO** for each.

## Watchlist candidate status

- **MU** — materially changed. −8.85% today, the largest of the three CXMT-driven sessions, deepening the supply-side counter to the queued **bullish** DRAM-tightness/HBM premise. Net: better entry price, materially worse thesis. Note refresh below.
- **INTC** — changed. −5.86% today on sector sympathy with no Intel-specific event, extending Friday's −7.89%. The queued foundry-ramp thesis is untouched on its own terms; the entry price improves again. Note refresh below.
- **AAPL** — unchanged today, but its confirmed Q2 print is **Thu 2026-07-30 AMC** (Tim Cook's last call as CEO), inside 2 sessions.
- **NVDA, AMAT, ADBE, ORCL** — no incremental evidence in today's window beyond the 7/27 notes already on file. Unchanged; deliberately not re-noted.
- **GEV** — `rescreen-GEV-D-20260731` is due Friday. No development today.
- **LLY** — the flagged retatrutide topline-vs-FDA-filing-slip conflict remains **unresolved**; deadline is M1 (2026-08-03) or `rescreen-LLY-D-20260914`, whichever is first. Nothing today resolves it.

---

# ANALYSIS — OPPORTUNITY CHECK

Evaluated against every roster-active strategy with `review_cadence: reactive` in `strategy/roster.yaml` — currently **A, B, C, E** (D excluded as `long_horizon`).

**Strategy B — three candidates routed.** All three clear the frozen Entry criterion 1 (≥5% close-to-close on event day, `strategy/04_strategy_b.md`), are US-listed common equity, are ≥$2B market cap, and have no open A position in the same name (criterion 5 — A holds no positions at all). Event day is **2026-07-28**, so the 10-trading-day entry window closes **~2026-08-11**.

1. **SANM (Sanmina), −17.46%.** The cleanest object on the tape. Q3 FY26 beat both lines and raised FY26 EPS guidance to $11.90–12.20 against $10.83 consensus — a ~10% guidance raise — and the stock fell 17.5% with *no identified negative detail in any source reviewed*. That is the canonical criterion-2 shape: reaction materially over-sized relative to the event's fundamental implications. **The counter-argument thesis construction must defeat:** the name reportedly ran +194% YoY, and coverage notes SANM has printed a similar ~18–22% post-beat drop before — a repeating pattern is evidence of a structural valuation reset rather than a one-off over-reaction, which would make this information-driven. Also note a price-level conflict in sourcing (a cached quote page showed a $250.95–257.00 range against the $172.43 close) that must be resolved before sizing.
2. **GLW (Corning), −16.1%.** Core sales +17% YoY and core EPS both beat; guidance in-line. A six-year worst day on an in-line guide is a large reaction to a small information delta. **Must resolve first:** whether the market traded the GAAP net-sales figure ($4.505B, framed by some outlets as a miss) or the core-sales figure ($4.74B, a beat). If the former, the "over-reaction" may be a correct reaction to a metric this file has mis-framed, and the candidate dies at criterion 2.
3. **AMKR (Amkor), −24.74%.** Record quarter into a Q3 guide ~3% below consensus, producing a 24.7% decline. Disproportionate on its face. **Lowest conviction of the three, and flagged as such:** the guide is genuine forward information, AMKR sits squarely in the semiconductor complex currently being de-rated on the CXMT/DUV theme this system has *already* adjudicated as information, and part of the decline is attributed to profit-taking after a rally on a $1.5B Nvidia advanced-packaging partnership. The thesis must separate an idiosyncratic guide over-reaction from the sector de-rate, and if it cannot, this is a NO-GO at criterion 4.

**Explicitly declined, with reasons** (so the reasoning is on the record rather than a silent omission):
- **CARR, CVLT, UPS** — each fell ≥5% on a beat, but each has an *identified* fundamental cause (margin compression −260bp; a YoY billings decline; US Domestic margin plus an $891M charge). Identified cause ⇒ information ⇒ criterion 2 fails.
- **MU, INTC, SKHY** — the CXMT/DUV theme, adjudicated as information (confirmed cross-sectionally) by D2 on 2026-07-27 across SNDK, AMD and ASML. Re-routing it 24 hours later on unchanged evidence would be re-litigating a settled call. SKHY additionally fails instrument eligibility as an ADR.
- **ITRI, KNSA, LCID, JBLU, IQV, KO** — up-moves, which for B means a *short* thesis. Beyond the mechanism problems noted in the screen, B is long-biased in practice and every short-direction candidate routed to date (SHOP, PYPL, CDW, MGM) has been declined at D2. Routing another without new evidence that the short mechanism works would be volume, not signal.
- **INFY** — ADR; fails B instrument eligibility, same gate as ASML on 7/27.

**Strategy C — no candidate.** Router is HYBRID ACTIVATE, **FOMC-only**. The 7/29 FOMC is exactly the admissible catalyst, and `thesis-FOMC-C-20260726` was already constructed and **NO-GO'd yesterday** at 75 conviction ("structures ARE buildable inside budget; no directional divergence established"). Nothing today establishes a directional divergence — if anything the ~1-in-3 hike pricing is *more* efficient than yesterday. No new queue row; the existing terminal NO-GO stands.

**Strategy A — no candidate.** Router remains **DO-NOT-ACTIVATE**; A holds $0.00 NAV. Today's movers route to the A queue as watchlist notes, not entries.

**Strategy E — no candidate.** Router is ACTIVATE (substantive) but **execution-feasibility-deferred** at the ~$1.9k/strategy book size, which gates any live entry. Today's rotation did produce genuine intra-industry dispersion (SMH −3.45% vs IGV +0.96%; XLV +2.36% vs XLK −1.84%), which is the *kind* of signal E exists to harvest — recorded here as evidence for the next M2, but not actionable while the feasibility gate binds.

---

# ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only — Rev 40)

Every open A/B/D position was evaluated case-by-case. **No add candidates.** Reasons per position:

| Position | Mark vs cost | Trigger present? | Disposition |
|---|---|---|---|
| B:ISRG | +3.1% | Strengthened conviction? UBS upgrade to Buy, PT $550 | **Declined.** A sell-side rating change is an opinion, not new fundamental information; and the position is working, so neither the dip nor the strengthened-conviction trigger is genuinely met. ISRG is also already held twice across B and D |
| B:MDT | +9.9% | No | **Declined.** Time-stop is in 3 sessions — adding into a position about to mechanically exit is definitionally not thesis-intact |
| B:MSCI | ≈0% | No | **Declined.** Entered today; no dip, no new information |
| D:AMZN | −4.2% | Dip | **Declined.** Q2 print is Thu 7/30, inside 2 sessions. Adding immediately ahead of a print is the same objection that produced yesterday's AMD NO-GO |
| D:CRM | +12.9% | No | **Declined.** Up 12.9%, so no dip; no new fundamental information today |
| D:DIS | −11.1% | Dip | **Declined at the HARD GATE.** No at-entry invalidation criteria are recorded on this legacy row (`invalidation_status` is NULL), so "criteria remain UNBREACHED" cannot be affirmatively confirmed. Per the Rev-40 gate, only a position whose criteria are confirmed unbreached may be flagged |
| D:GOOGL ×2 | −1.8% | No | **Declined.** Criteria recorded and unbreached, but an add tranche filled *yesterday*; a second add on the next session with no new development is churn |
| D:ISRG | +3.7% | See B:ISRG | **Declined**, same reasoning |
| D:RTX | +23.4% | No | **Declined.** An RTX add was already constructed and NO-GO'd on 2026-07-26 (fails Entry criterion); nothing today changes that |
| D:TSM | −7.8% | Dip | **Declined at the HARD GATE.** `invalidation_status` is NULL on this row, so unbreached cannot be confirmed — and independently, the DUV development is adverse read-through, which is invalidation territory rather than add territory |
| D:UBER | −3.6% | No | **Declined.** No development in the window bears on UBER |

**Process note worth surfacing:** two declines (D:DIS, D:TSM) turned on *missing* recorded invalidation criteria rather than on the merits. The Rev-40 hard gate is written to fail closed, and it correctly did — but it means legacy position rows without a populated `invalidation_status` are structurally ineligible for adds regardless of how good the case is. Recorded here for W5 / self-improvement; **not** worked around in this session.

---

# ANALYSIS — REGIME CHECK

**No router review recommended.** High bar, default NO on ambiguity — and this is not even ambiguous, because the actual regime event is 18 hours away.

The candidate arguments were weighed and declined:
- *The AI-hardware de-rate is a genuine leadership change.* Two sessions of SMH weakness with the equal-weight index simultaneously making ground is a rotation, not a regime break. `risk_sentiment` is already `neutral` and breadth **broadened** today — the opposite of the deterioration that would justify a flip.
- *The oil collapse changes `inflation_trend` and `shock_overlay`.* `shock_overlay` was re-reviewed inter-monthly as recently as 2026-07-26 (12th adjudication, kept `latent`) on substantially this same evidence. Three days of oil is not a monthly axis, and the disinflationary impulse is not yet in any reported data — the June-referenced `inflation_trend = reaccelerating` still stands on the prints that exist.
- *A ~1-in-3 priced hike is a policy-stance signal.* `policy_stance` is **already** `hawkish`. Hike pricing is consistent with the recorded axis, not a change to it.

Opening a review tonight would resolve into an FOMC decision that lands before it could conclude. The correct trigger is Wednesday's outcome plus the MSFT/META (7/29) and AMZN (7/30) prints — if those move the axes, the next D1 raises it with actual information rather than anticipation.

---

# ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

Tuesday's rotation slot is the **prompt-injection** battery (`HF_Resource_Catalog.md` §6.1). One query run via the HF papers search; five results returned, **none published on or after 2026-07-25** (most recent: BrowseSafe, 2025-11-25, already cited in the catalog as a known prior hit). **Nothing in the ~72h window** — no capture written, no `state.strategy_candidates` row, per the default-silent posture. No `AI_Trading_Foundation.md` item affected.

---

# PARK ALLOCATION CALL

- **`vehicle`** — **SGOV** (KEEP). Today's opening `state.park_policy_current.vehicle` is SGOV, effective 2026-07-26. Trivially BOUND: D2's PARK ALLOCATION CONVERSION no-ops when the called vehicle equals the current policy vehicle.
- **`conviction`** — **HIGH**, `conviction_pct` **72**.
- **`rationale`** — The runner-up today is **duration (GOVT / IEF / TLT)**, and its case is the strongest it has been. The whole curve rallied — 2Y 4.26% (−5bp), 5Y 4.35% (−5bp), 10Y 4.61% (−4bp), 30Y 5.09% (−3bp). WTI fell another 4.2% to ~$79.15, extending Brent's worst three-day stretch since 2020, and that unwind of the Iran risk premium is a real disinflationary impulse rather than a sentiment move. Every duration rung beat the tier-0 rung on the day: **TLT +0.59%, IEF +0.30%, GOVT +0.27% against SGOV +0.01%.** I am declining duration on one specific, dated fact: **the FOMC decides tomorrow at 14:00 ET, and the market is not pricing a cut at all — it is pricing hold-versus-HIKE**, at 31.5% (Barron's, 7/28 16:08 ET), 36.5% (CME FedWatch via goldsilver, 7/27) and 37.6% (investing.com Fed Rate Monitor, 7/27). A ~1-in-3 hike is a materially asymmetric risk to every duration rung on the menu, and it is not a contrarian read — the regime's own `policy_stance` is already `hawkish` with `inflation_trend` `reaccelerating`. Taking duration into that binary, 18 hours before it resolves, to capture a carry differential of order 1bp/day, is the wrong side of the same event that moved the park to tier 0 two sessions ago. **VOO/VTI** are ruled out on the same binary *plus* MSFT and META printing tomorrow and AMZN Thursday, into a tape where SPY 740.86 is still **below** its 50dma (745.00) and the semis fell hard enough to put the Nasdaq-100 briefly into correction intraday. **LQD / HYG / PFF** add credit or equity beta to buy an HY OAS already around 2.7 — historically tight, no compensation. **AOR** blends both risks I am declining. SGOV is the single rung whose payoff is indifferent to tomorrow.
- **`invalidation`** — A 7/29 FOMC resolving to a **hold with non-hawkish guidance**, with the oil-driven disinflation impulse intact → duration (GOVT, then IEF) becomes the better rung and I re-risk on the next call. Conversely an actual **hike**, or `hy_oas` widening materially off ~2.7, keeps tier 0 and pushes any re-risk further out.
- **`theater_check`** — **PASS.** The test is that today's genuinely new evidence points **away** from the call I made: the curve rallied, oil fell again, credit is pristine, and *every* alternative rung outperformed SGOV on the day. Those are all arguments to re-risk; they are identified rather than omitted, and I am declining them for one dated, falsifiable reason that resolves within 24 hours — not because KEEP is the default and not because nothing changed. The asymmetry is doing the work, not the base rate: if I am wrong the cost is one session of roughly 25–60bp of foregone duration return; if the hike lands, the avoided drawdown on TLT/IEF is a multiple of that. A KEEP resting on inertia would be exposed if the 7/26 de-risk premises had decayed — both were re-read independently on today's close and both still hold (SPY below its 50dma; VIX 18.21 still above its 50d average of 17.37).

Logged: `events.decision_log` `entry_type='park-allocation'`, `status='BOUND'`, `direction='keep'`, with the full `readings` evidence snapshot. Heartbeat written: `ops.heartbeat ('loop:park_allocator', 'SGOV call, status=BOUND')`.

---

# RECOMMENDED ACTIONS

- **New entry candidate — SANM, Strategy B (long).** −17.46% close-to-close on 2026-07-28, the event day, on a Q3 FY26 beat-and-raise (EPS $3.31 vs $2.77; FY26 EPS guide $11.90–12.20 vs $10.83 consensus) with no identified negative detail. Clears B entry criterion 1; window closes ~2026-08-11. Full thesis construction required in a separate session per Strategy.md. Highest conviction of the three. **Must defeat:** a reported +194% YoY run and a precedent of similar post-beat drops, which would make this a structural valuation reset rather than an over-reaction; and a source-level price-range conflict that must be settled before sizing.
- **New entry candidate — GLW, Strategy B (long).** −16.1% close-to-close on 2026-07-28 on a Q2 print where core sales (+17% YoY) and core EPS both beat with in-line guidance — "worst day in six years." Clears B entry criterion 1; window closes ~2026-08-11. Full thesis construction required in a separate session. **Must resolve first:** whether the market traded GAAP net sales ($4.505B, reported by some outlets as a miss) or core sales ($4.74B, a beat) — if the former, criterion 2 likely fails.
- **New entry candidate — AMKR, Strategy B (long).** −24.74% close-to-close on 2026-07-28 on a record Q2 against a Q3 guide ~3% below consensus. Clears B entry criterion 1; window closes ~2026-08-11. Full thesis construction required in a separate session. Lowest conviction of the three and flagged as such: the guide is genuine forward information, the name sits inside the semiconductor complex already de-rating on the settled CXMT/DUV theme, and part of the move is profit-taking after a rally on the $1.5B Nvidia packaging partnership.
- **Watchlist update — MU (A queue), note refresh.** −8.85%, the largest of three CXMT-driven sessions, deepening the supply-side counter to the queued **bullish** DRAM-tightness/HBM premise. Net: better entry price, materially worse thesis — the same direction as the 7/27 note but a larger magnitude. No disposition change; A router remains DO-NOT-ACTIVATE.
- **Watchlist update — INTC (A queue), note refresh.** −5.86% on sector sympathy to the CXMT/DUV theme with **no Intel-specific event**, extending Friday's −7.89%. The queued foundry-ramp thesis is untouched on its own terms; the valuation-reset caveat eases further on the drawdown.

*No exits triggered. No add candidates. No router reviews recommended.*

```yaml d1_actions
- action: thesis
  ticker: SANM
  strategy: B
  detail: "-17.46% close-to-close on event day 2026-07-28 (Q3 FY26 beat both lines + FY26 EPS guide raised to 11.90-12.20 vs 10.83 consensus, no identified negative detail); clears B entry criterion 1, window closes ~2026-08-11; must defeat the +194% YoY run and a precedent of similar post-beat drops that would make this a structural valuation reset"
- action: thesis
  ticker: GLW
  strategy: B
  detail: "-16.1% close-to-close on event day 2026-07-28 (core sales +17% YoY and core EPS both beat, guidance in-line, worst day in six years); clears B entry criterion 1, window closes ~2026-08-11; thesis must FIRST resolve whether the market traded GAAP net sales 4.505B (framed as a miss) or core sales 4.74B (a beat)"
- action: thesis
  ticker: AMKR
  strategy: B
  detail: "-24.74% close-to-close on event day 2026-07-28 (record Q2 vs a Q3 guide ~3% below consensus); clears B entry criterion 1, window closes ~2026-08-11; lowest conviction of the three - guide is genuine forward information and the name sits inside the semiconductor complex already de-rating on the settled CXMT/DUV theme"
- action: watchlist
  ticker: MU
  strategy: A
  detail: "note refresh - -8.85%, largest of three CXMT-driven sessions, deepening the supply-side counter to the queued bullish DRAM-tightness/HBM premise; better entry price, materially worse thesis; no disposition change, A router still DO-NOT-ACTIVATE"
- action: watchlist
  ticker: INTC
  strategy: A
  detail: "note refresh - -5.86% on sector sympathy to the CXMT/DUV theme with no Intel-specific event, extending Friday's -7.89%; queued foundry-ramp thesis untouched on its own terms, valuation-reset caveat eases further on the drawdown"
```

*Prose bullets: 5. `d1_actions` entries: 5. Cross-check agrees.*
