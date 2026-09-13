2026-09-13
<!-- d1_scan_through_utc: 2026-09-13T22:34:33Z -->

# Daily Market Development Scan — 2026-09-13 (Sun, MT)

**Scan window: 2026-09-10 16:30 MT → 2026-09-13 16:34 MT** (72.1h — a **MULTI-SESSION GAP, stated explicitly because it exceeds the ~50h threshold**. This is not a missed run: D1's cadence is Sun–Thu, so Friday's session is covered by the following **Sunday** fire by design. Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-10T22:30:10Z -->` marker, cross-checked against that file's own commit at 2026-09-10T22:36:08Z — the two agree to within six minutes. `state.routine_catchup_window` independently returns `window_start_ts ≈ 2026-09-10T13:36:55Z`, `window_days = 2.98`, `never_completed = false`, against a `fallback_days = 3` bar — cadence-normal for a Sun–Thu routine crossing a weekend, so **no `CATCHUP[...]` token is owed**. The git history is **not** shallow (1,430 commits), so the HISTORY-DEPTH PRECHECK passes and the git leg of the window resolution is sound rather than merely silent.)

**ONE completed US trading session inside this window: Friday 2026-09-11.** `state.trading_day_today` gives `is_trading_day = false` (Sunday), `last_trading_day = 2026-09-11`, `next_trading_day = 2026-09-14`. Every close-to-close figure in this file is measured **2026-09-10 → 2026-09-11**. Saturday and Sunday were closed; the weekend is scanned for *developments*, not for prices.

**Tape — a broad risk-on reversal, and the mirror image of the previous session.** SPY 757.83 → 764.29 (**+0.8524%**), VOO 696.65 → 702.56 (+0.8483%), QQQ **+0.8734%**, DIA +0.9678%, IWM +0.4136%, SGOV +0.0199%. VIX 17.84 → **15.84** (**−11.2108%**). Brent (BZX6 front month) 107.63 → **104.61** (−2.8059%), USO −2.1972%. GLD +0.6080%, TLT +0.1114%, UUP +0.1427%, BITO **0.0000%** (exactly flat). Equity breadth ($S5TH) 54.67 → **56.46**. **Nine of eleven GICS sectors higher** — the previous session had nine of eleven *lower* — and the cross-sector spread **narrowed** to 1.6285pp (XLK +1.3228% to XLU −0.3057%) from 2.02pp.

All equity/ETF figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), each verified carrying a 2026-09-11 bar stamped `13:30:00Z`. **Two documented exceptions, stated rather than hidden:** the ^VIX bar (contract 13455763, `IND`/CBOE) stamps `07:15:00Z`, an index-feed property rather than an equity RTH bar; and the Brent bar is a NYMEX future (BZX6, contract 339981284, `contract_month` 202611, last trading date 2026-09-30 — a legitimate front month with ~19 days to expiry, not a stale about-to-roll contract).

**This run is NOT degraded, and that is measured rather than claimed.** 117 single names and 24 index/ETF/future instruments were put to IBKR for confirmation; **140 of 141 returned a genuine 2026-09-11 regular-session bar. Zero symbol-level denials. Zero FMP `ACCESS DENIED` responses across 44 calls.** The one failure is named in full below. So every `surfaced_count` in this file is an affirmatively established figure, never a reported zero standing in for an unmeasured population.

**The one measurement failure, named individually with its reason, per the REPORTING RULE.** **SRRK** (Scholar Rock, contract 319099330) resolved cleanly via `search_contracts` but `get_price_history` returned `-32400 "An error occurred. Please try again later."` on **14 attempts** interleaved with unrelated successful calls across the session. No price was obtained and **no substitute source was used**. This matters more than a single missing row would normally: SRRK is the one name with a confirmed in-window FDA approval (Isembyld / apitegromab-mstn for spinal muscular atrophy, FDA "Novel Drug Approvals for 2026" #39, dated 2026-09-11), and its reported ~+12% reaction was an **after-hours** move — so its close-to-close reaction day is **2026-09-14** regardless, and it is owed a measure on the next run either way.

---

## TL;DR

- **Exits triggered: none.** No mechanical trigger exists that could fire — all 12 open tranches carry NULL `convergence_target` and NULL `time_exit_date` — and no Development breaches any thesis-invalidation criterion.
- **New entry candidates: 3** — **HPE** and **DELL** (Strategy B, `qualifying_event_date` 2026-09-10) and **DELL/STX** (Strategy E pair). No A, no C.
- **Add candidates: none.** 12 open Strategy-D tranches evaluated, 0 flagged, 3 declined at the HARD GATE (ISRG, RTX, UBER). **The gate cost a real flag today** — UBER was the one textbook dip in the book.
- **Watchlist changes:** HPE and DELL enter the Strategy B new-entry-candidate index. No removes, no demotions.
- **Regime review: no review.** Default-NO on ambiguity holds.
- **Park: BOUND KEEP at `target_f_pct` 50** (VOO 50% / SGOV 50%), MEDIUM **48** — the index axis EXITED exactly as Thursday predicted, but the rates axis entered and the weekend escalated.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**Both of Saudi Arabia's main crude export outlets came under simultaneous pressure — and the confirmations landed AFTER Friday's close.** This is the single most important framing fact in this file: Friday's tape had not seen most of it.

**(a) The East-West pipeline — the Hormuz bypass — was struck and shut.** Drone strikes launched from Iraq hit pumping stations on Saudi Arabia's 1,200km East-West Crude Oil Pipeline in the Riyadh and Medina regions on 2026-09-10/11, causing fires and several injuries (no deaths reported). Saudi Arabia shut the pipeline as a precaution. The pipeline normally moves 4–7M bpd and exists precisely to route crude around the Strait of Hormuz.
- Sources: Reuters, 2026-09-12; CNN, 2026-09-11; Al Jazeera, 2026-09-11 (citing a Saudi Foreign Ministry statement and AFP satellite imagery); New York Times, 2026-09-12.
- Context from the same reporting: Saudi crude output fell in August to its lowest since 1990 (reported to OPEC); Saudi exports to Asia collapsed from ~3.4M bpd in June to ~128,000 bpd in August, recovering to ~700,000 bpd this month (Kpler data via AP/PBS). Saudi Arabia has asked Washington for military help against the Houthis (Reuters, 09-12).

**(b) Houthi forces took the Bab al-Mandeb chokepoint.** Houthi forces captured the port city of **Mocha on Thursday 09-10**, then took the strategic **Perim (Mayun) Island on Friday 09-11**, giving them effective control of Yemen's entire Red Sea coast and, per cited security analysis, the capability to close Bab al-Mandeb at will.
- Sources: Reuters (two separate wire pieces, 09-11 and 09-12); CNN, 09-10 and 09-11; Al Jazeera, 09-11 and 09-12; AP via PBS NewsHour, 09-12.

**And yet Brent FELL 2.8059% on Friday, to 104.61.** The two facts are in tension and the resolution is simply chronological: the pipeline-strike severity was confirmed over Saturday and Sunday. Barron's reported that Saudi's flow-suspension announcement left oil futures "roughly unchanged" in the moment on Friday — i.e. the market had not priced what the following two days established.

**Recorded but NOT used as fact — two single-source claims.** (i) A claim that the US Treasury imposed new sanctions on Iran's airlines ("Operation Economic Outcast") appears only in one newsletter and could not be corroborated by any wire service. (ii) The BRICS 18th Summit (New Delhi, 09-12/13) is confirmed to have occurred, but the characterisation of a "New Delhi Declaration" calling for maximum restraint on the Iran war rests only on a Substack, a trading-desk note and an exam-prep aggregator. Both are flagged, neither is relied on.

**No other market-wide breaking event surfaced** — no material bankruptcy, disaster, or unscheduled enforcement action. Stated as a measured absence over the scan performed, not as a claim of exhaustiveness.

### 2. Scheduled events that resolved in the window

**EVENT-IDENTITY GATE applied throughout.** Each item below was verified against reporting naming the release date, and every price reaction was independently confirmed from IBKR regular-session bars rather than taken from the reporting.

**August CPI (released Friday 2026-09-11, 08:30 ET) — the session's central catalyst, and it was not a dovish print.**
- Headline **+0.4% m/m, +3.4% y/y** — matched consensus.
- Core (ex food and energy) **+0.3% m/m against ~0.2% expected — HOTTER than forecast**; +2.4% y/y, in line.
- Sources: Yahoo Finance, Barron's, MarketWatch, TheStreet, all citing the same figures.
- **The market read is the point:** this was not taken as inflation cooling. It *raised* the implied probability of a **rate HIKE** at the 2026-09-15/16 FOMC. Equities rallied because a binary uncertainty resolved, not because the data was friendly.

**August PPI (released Thursday 09-10, the lead-in):** headline **+0.4% m/m, +5.4% y/y**, up from 4.7% in July, with energy, transport/warehousing, hospital services and airfares re-accelerating. Sources: Reuters, the BLS release page, Investing.com. This is what pushed hike odds up *before* Friday's CPI.

**Fed-hike odds — restated because the direction is easy to misread: this is a HIKE cycle.** CME FedWatch odds of a 25bp hike at the 09-15/16 meeting moved from roughly 56–71% across the week to **~85–90%** after Friday's CPI (Kiplinger 85%, Yahoo Finance 87%, a 09-13 recap ~90%). Reuters' 09-11 "Wall St Week Ahead" dissents, calling it "a razor's edge." **The spread across sources is recorded rather than collapsed into one number.** A hike would be the Fed's first since July 2023.

**Treasury yields.** The 10Y closed **4.96%** on 09-11 (`events.regime_events` `TECHNICAL_INPUT`/`TREASURY_10Y`, FMP treasury-rates), after 4.95% on 09-10 and 4.83% on 09-09 — approaching 5% and at multi-year highs. The 30Y is ~5.27–5.31%. **One source rejected:** FirstMetroSec's 09-11 wrap cites a 10Y of "4.17%", inconsistent with every other source and with our own stored series; treated as a data error and not used.

**Treasury buyback.** Treasury announced on 09-09 it would buy back up to $6B of 10–20yr debt; the Thursday operation closed at **$5.19B**, under the maximum, only the third such shortfall since the programme restarted in 2024. Yields rose anyway. Sources: NYT 09-09, WSJ, The Guardian 09-09.

**Earnings: the window is EMPTY, and that is a confirmed emptiness rather than an unsearched one.** FMP's `earnings-calendar` returned an empty result set for 2026-09-11 through 2026-09-13. No US-listed company with market cap ≥$2B published a print inside this window. The next notable reports are **PENDING** and outside it — Dave & Buster's (PLAY) Mon 09-14 after close, Trip.com (TCOM) Wed 09-16 after close, Carnival (CCL) Thu 09-17 before open — and **no outcome figures are populated for any of them**, per the gate.

**Oracle's FQ1 print is the event that drove this session, and it sits on the window boundary.** It was released after the **2026-09-10** close — i.e. its *reaction day* is 2026-09-11 and therefore inside this window, while the release itself is dated to the prior session. Its $95B capex plan is the qualifying event behind most of §3 below. Its own price action is extraordinary and is recorded in §3.

**FDA — one confirmed approval, one decision whose OUTCOME IS NOT ESTABLISHED.**
- **SRRK — Isembyld (apitegromab-mstn) APPROVED for spinal muscular atrophy, 2026-09-11.** Confirmed on the FDA's own "Novel Drug Approvals for 2026" page (approval #39) and by Seeking Alpha (09-13). The ~+12% reaction was **after-hours**, so the close-to-close reaction day is 2026-09-14. **No IBKR price could be obtained for SRRK at all** (see the header). Nothing is routed on it today.
- **TLX (Telix) — PDUFA goal date 2026-09-11 for Pixclara / TLX101-Px.** The **date is confirmed; the OUTCOME is not.** No post-decision primary source was obtained. TLX closed **−5.1261%**, which is suggestive of an adverse outcome — and that is precisely why it is **not written down as one**. Per the gate: no outcome figure populated, no event-dependent criterion assessed, re-assessment queued after publication. Its 10-day window runs to roughly 2026-09-25, so nothing is lost by waiting.

**M&A: nothing newly resolved inside the window.** The Skyworks/Qorvo $22B merger clearing HSR/SAMR review moved SWKS +10% and QRVO +6% — but **both the event and that reaction are dated 2026-09-10**, outside this window and already covered by the prior run. Explicitly flagged as out of scope rather than re-reported as a fresh Friday finding. The 09-11 moves in both names are second-day continuation (§3).

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (`screen='single-name-move'`)

Logged as `events.decision_log` `entry_type='research-screen'`. **`surfaced_count` = 14 = `ARRAY_LENGTH(passed)`** per the 2026-08-30 pin; `fields.rail_tally` = **30** (names clearing ≥2% AND cap ≥$2B); `fields.universe_measured` = **116**. Agreement **7 both / 7 ai_only / 2 rule_only**, written under the **nested** `"agreement": {...}` object.

**On this tape a +2.5% move in a high-beta name is BETA, not information**, and Layer 2 has been applied with that in mind — which is why several names clearing the rail were rejected and two sub-rail names were surfaced at the *highest* conviction in the screen.

**The information-dense fact is a discrimination WITHIN a theme, not the theme.** The Oracle capex read-through re-rated **compute and networking** hard — HPE **+12.4411%**, DELL **+11.9776%**, SMCI +7.2766%, ANET +5.6087%, JBL +5.0462%, CIEN +4.4766%, CSCO +4.3663%, MRVL +4.0271%, IBM +3.9612%, GEV +3.6106%, VRT +3.5989% — while the **storage leg FELL: STX −3.7297% and WDC −2.9835%**. The market did not buy "AI" indiscriminately; it picked a side inside one sub-industry, and it sold two $150B+ names on the session their own complex ripped. That is why STX and WDC carry conviction 75 despite clearing neither the 5% legacy bar nor the spec floor.

**ORCL itself — the company whose print caused all of it — CLOSED DOWN 1.7393%,** after opening at 163.34 and trading to a high of 165.98 before a low of 149.84. That is a ~9.5% intraday round trip from high to close. ORCL does **not** clear the 2% close-to-close rail and is therefore not in the population, but it is recorded here because **a small close-to-close number is concealing a very large session** — the market rewarded the suppliers of Oracle's spend and charged Oracle for it.

| Ticker | Move | Cap | Conviction | Judgment |
|---|---|---|---|---|
| **HPE** | **+12.4411%** | $82.2B | 75 | Largest large-cap move of the session; an $82B incumbent re-rated on *another* company's capex disclosure |
| **DELL** | **+11.9776%** | $376.7B | 75 | More striking on size — a $377B company moving +12% on a read-through is a far larger anomaly per unit of market value |
| **STX** | −3.7297% | $186.1B | 75 | FELL while its own complex ripped — the within-sub-industry discrimination |
| **WDC** | −2.9835% | $154.1B | 75 | The second storage decliner; two $150B+ names down together is a pattern, not two idiosyncratic prints |
| SMCI | +7.2766% | $25.9B | 60 | Same read-through, but a +7% day is ordinary in its volatility regime |
| ANET | +5.6087% | $251.3B | 60 | The networking leg; evidence the bid extended past servers |
| **TLX** | −5.1261% | $3.8B | 60 | On its confirmed PDUFA date — **outcome NOT established, not routed** |
| **SMR** | **−15.6709%** | $2.56B | 45 | Largest decliner in the population and **no identifiable event found** — escape-valve surfacing, recorded as UNEXPLAINED |
| SWKS | +5.1410% | $13.3B | 45 | Second-day merger continuation; event day was 09-10, so not an event-day reaction |
| MARA | +4.8118% | $4.6B | 45 | Miners up (RIOT +2.4821%) while BITO closed **exactly flat** — a datacenter-pivot decoupling, not a crypto move |
| HAL | −4.4267% | $29.9B | 45 | Cleanest crude-beta name, ~1.6× Brent's −2.8059%, no name event |
| QRVO | +3.8180% | $10.3B | 45 | Trailed SWKS by 1.32pp on the continuation day |
| UNH | −2.3670% | $344.3B | 45 | Largest mega-cap decliner on a rising tape, no catalyst found |
| GEV | +3.6106% | $255.0B | 45 | Held D name; feeds this run's own add sweep |

**Rejected, with the two legacy-rule-passing rejections named as the contract requires:** **SLS** −14.4181% (a 14% session in a ~$2.15B clinical-stage biotech is its ordinary volatility regime, no event found, and its cap sits inside the unreliable band — three reasons, none of them the size of the move) and **JBL** +5.0462% (the same Oracle factor already carried by four names; one factor across many tickers is approximately one observation). Also recorded as informative double-rejects: AMD +2.4881%, ISRG +2.4107%, TMUS +2.9183%, SNAP +2.8986%.

**Market-cap rail.** Sourced from FMP `company/profile-symbol` per the pinned finding that it answers where `batch-market-cap`, `market-cap` and `shares-float` deny. All 40 movers ≥2% returned; **zero ACCESS DENIED**. Four sit inside the ~30% band where FMP's implied share count is unreliable and need a second source before the rail call is trusted: **SMR ~$2.56B** and **SLS ~$2.15B** (above), **ACVA ~$1.82B** and **ATEC ~$1.63B** (below). SMR is carried *with* that caveat; ACVA (+44.1828%) and ATEC (+19.6833%) are excluded as sub-rail — **flagged here so the exclusion is visible rather than silent**. Six further large movers were excluded on cap with no ambiguity: FEIM +42.4105% ($872M), CRMT +19.4969% ($15.8M), VERI +18.1549% ($96.7M), PMTS −16.4810% ($258M), ZUMZ −12.9264% ($245M), RENT −13.1206% ($82.3M), TLS −15.5983% ($296M), EQ −12.8099% ($133M).

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (`screen='sector-move'`)

Logged as a second `research-screen` row. `surfaced_count` = **4**; `rail_tally` = **2** (only XLK and XLI cleared the ≥1% net); `universe_measured` = **11**. **No sector moved ≥2%, so the legacy rule caught nothing** — `rejected_notable` carries no legacy-rule-passing item and the contract's MUST is satisfied vacuously rather than by omission. Every passed item is consequently `ai_only`; agreement **0 / 4 / 0**.

Full panel: XLK +1.3228, XLI +1.0671, XLC +0.9865, XLY +0.8932, XLRE +0.8595, XLF +0.6682, XLB +0.3743, XLP +0.3490, XLE +0.3234, XLV −0.1811, XLU −0.3057.

**The primary reading is the LOW dispersion.** At 1.6285pp, narrower than the previous session's 2.02pp, this was index-level repricing of the rate path, not sector rotation. Which is exactly why **the two red sectors carry more information than the two that cleared the net** — and why the highest convictions here sit on sub-net items.

- **Energy (XLE) +0.3234% — the session's cleanest tell, and the second consecutive one with the sign flipped both times.** XLE *rose* while front-month Brent *fell* 2.8059%. The previous session was the exact inverse: XLE −0.5818% on Brent +6.3433%. Two sessions, two opposite crude moves, and energy equities declined to follow on both. Read together, the equity market is **not pricing the war premium in crude in either direction** — it is treating the disruption as a commodity event with a finite horizon rather than a durable repricing of energy earnings. **That reading reaches beyond this screen: the park allocator's shock axis tests Brent > 95, and the equity market is implicitly disputing that the level is load-bearing.** Conviction 60.
- **Utilities (XLU) −0.3057%** — the most negative sector on a +0.85% tape, and the most rate-sensitive one, on the session the 10Y printed 4.96%. The rates channel surfacing in equities precisely where it should rather than at random. Conviction 60.
- **Information Technology (XLK) +1.3228%** — led the tape, but the headline is roughly beta. What is significant is the composition: the bid came from second-tier suppliers while the **mega-cap platforms sat flat** (NVDA −0.0321%, AVGO +0.3215%, MSFT +0.6478%, META +0.5664%) and storage was sold. Conviction 60.
- **Industrials (XLI) +1.0671%** — carried by the electrical-equipment and power complex on the same read-through (GEV +3.6106%). Conviction 45.

**Health Care (XLV −0.1811%)** was considered and rejected as a double-reject: ordinary defensive rotation on a risk-on day, no threshold crossed.

### 5. Notable commentary

- **Treasury Secretary Scott Bessent**, defending the undersubscribed buyback: *"if some of the Bloomberg Terminal bros are unhappy with what I'm doing, well, that's too bad"*; *"I try to slow things down, to get people to get out of their fever dream and look at the facts."* (NYT, WSJ.)
- **Fed Chair Kevin Warsh**, from the late-August Jackson Hole speech repeatedly cited as the week's overhang: the Fed has *"work to do"* if officials cannot be confident the underlying inflation trend is meaningfully improving. (CNBC, Reuters, WSJ, Kiplinger.)
- **Alicia Levine (CIO, BNY Wealth)** on the FOMC: *"It's kind of a razor's edge... This is the first meeting in a long time where it's felt, wow, it really could go either way."* (Reuters, 09-11.)
- **Will Rhind (CEO, GraniteShares)** on the rally: *"We've seen this trend multiple times where macro factors will induce a selloff, but it's typically bought back pretty quickly."* (Barron's.)
- A Reuters poll of 93 economists (09-04/09) had ~70% expecting a hold, down from ~90% in August — the economist consensus moved toward "hike is plausible" but stayed well short of market-implied pricing.

**No discrete flagship sell-side note was itself a market driver this window.** The CPI/PPI data and the geopolitical/oil shock were the drivers; sell-side commentary reacted rather than led. Stated rather than padded.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP

**Result: no exit triggered, and no mechanical trigger exists that could fire.**

The book is **12 open tranches across 8 names, all Strategy D**. Strategies A, B, C and E hold no open position. Re-read live this run, every one of the 12 carries **NULL `convergence_target` and NULL `time_exit_date`**, so both mechanical limbs are structurally inert for the whole book — stated as a property of the record, not as a passed test.

**UNION SWEEP against the live connector: clean, no reconciliation lag.** `get_account_positions` returns ten lines — the eight held names plus the two park sleeves. Every share count reconciles exactly: AMZN 0.1554 + 0.1910 = 0.3464 ✓, DIS 0.2822 + 0.4422 = 0.7244 ✓, GOOGL 0.1534 + 0.1043 = 0.2577 ✓, TSM 0.0891 + 0.0659 = 0.1550 ✓, and GEV / ISRG / RTX / UBER single-tranche exact. **No position exists in the connector that is absent from `state.current_positions`**, so no `position_reconciliation_lag` alert is owed and none is raised.

**The park sleeves changed, and that is the 09-10 de-risk having FILLED:** SGOV 37.4175 → **74.8667** and VOO 16.2575 → **10.8278**. Valued at the 2026-09-11 closes that is SGOV $7,525.60 against VOO $7,607.18, an **actual f of 49.7305%** against the policy 50. So today's park call is made from a book that is genuinely half defensive, not from a staged intention.

### PER-STRATEGY KILL-TRIGGER SWEEP

`perf.kill_flags` carries two rows. **Strategy D** (as of 2026-09-10): `deployed_unit_value` 1.050429, `peak_unit_value` 1.098110312, `current_drawdown` −4.3421%, `excess_vs_sgov` +3.6245%, `deployed_days` 95, `closed_trades` 1, `gate_n` 29 (gate not reached), `beta_hat` 0.93334, all four flags FALSE. **Strategy B** (as of **2026-08-18**, its last marked session): `deployed_days` 79, `closed_trades` 13, `gate_n` 17, all four flags FALSE — legitimately stale rather than missing, because B has held no position since that date.

**Unconditional drawdown refresh against today's marks, as required — no judgment predicate applied.** Refreshed on the 2026-09-11 IBKR RTH daily-bar closes rather than `get_price_snapshot`. The D book moved 539.3579 → **548.4773, +1.6908%** on the session, carrying the deployed unit value to ≈**1.068190** and the drawdown to **−2.7247%**, from −4.3421%. The kill threshold is −50%. **No drawdown kill.**

- **Drawdown kill (#1):** NO — −2.7247% against a −50% bar.
- **Runaway-success (#3):** NO — deployed TWR has not doubled (unit value 1.07).
- **Interim underperformance warning:** `interim_underperf_warning` is FALSE for both strategies. There is **no open `ops.alerts` row in that category**, so no heal-resolution `UPDATE` is owed either.
- **B open-book pairwise correlation:** `analytics.b_pairwise_correlation` returns `n_positions = 0` with `avg_offdiagonal_corr` and `min_overlap_days` both NULL. The `n_positions >= 2` term fails, so the check is a no-op and no `b_pairwise_corr_high` alert is raised. Note again that this is a stricter zero than the standing plan text, which describes B as holding a single position (MDT) — **B's open book is empty, not one name.**

### JUDGMENT-LADEN THESIS-INVALIDATION CHECK

**Result: no invalidation criterion is met on any of the 12 tranches.**

No Development in this scan touched any of the eight held names with adverse new information. Ten of twelve tranches rose; the session was a broad risk-on reversal and every held name moved inside it: AMZN +1.9414%, DIS +0.6898%, GEV +3.6106%, GOOGL +1.7740%, ISRG +2.4107%, RTX −0.2221%, TSM +1.2172%, UBER −1.2266%.

Criterion by criterion, the invalidation sets are all fundamental-metric or discrete-event, and none has a test this session's data could move:

- **AMZN** (both tranches) — AWS revenue YoY, AWS operating margin, AWS backlog, hyperscaler commitments, metric immutability. All quarterly; next test is the Q3 print. Unbreached. *Note the cross-current, recorded because it is genuinely two-sided:* the Oracle capex plan is corroborating evidence for hyperscaler commitment generally, which is an AMZN criterion — but it is a competitor's disclosure and reinforces rather than tests the criterion.
- **DIS** (both) — Entertainment SVOD operating margin, FY26 EPS guide, buyback pace, metric immutability, FCC escalation. The 08-05 tranche records all five affirmatively re-verified at the Q3 FY26 checkpoint. Unbreached.
- **GEV** — total-company organic orders growth YoY, entry-quarter reading 88% against a 15% two-consecutive-quarter invalidation floor. Unbreached with a very wide margin; Friday's move was reinforcing, not testing.
- **GOOGL** (both) — Cloud revenue YoY, Cloud operating margin, Cloud RPO, adverse structural remedy. All four recorded `unbreached` on the 07-26 tranche. Unbreached.
- **ISRG** — procedure growth, placements, recurring revenue decoupling, competitor displacement at named IDNs. Quarterly. No breach evidence.
- **RTX** — Airbus damages ruling >$2B, a new powder-metal-class quality event >$1B, GTF Advantage EIS slipping past Q1'27, two-quarter backlog decline, FY26 FCF guide below $7.5B, FY27 defence procurement cut ≥10%. None engaged.
- **TSM** — gross margin <55% or USD revenue YoY <15% for two quarters, N2/A16 pushout or sub-7nm share decline, structural AI-capex reset. **The Oracle $95B capex plan is evidence directly AGAINST the structural-AI-capex-reset criterion**, i.e. it strengthens the thesis rather than threatening it. Unbreached.
- **UBER** — gross bookings cc YoY, adjusted-EBITDA margin as a share of gross bookings, Uber One membership, metric immutability. Quarterly. No breach evidence; Friday's −1.2266% is price action, not information.

**DIVIDEND NETTING: not engaged this session, and this is a scope finding rather than an omission.** The rule binds only where an invalidation criterion names a **price level**. `state.price_level_criterion_drift` returns exactly one row — `D:DIS:2026-08-05` — and that row's own flags settle it: `is_exit_criterion = false`, `actionable_price_level = false`, `likely_fundamental_context = true`, with criterion text reading *"NOT exit-triggering: ordinary adverse mark-to-market… No price-based stop (long-only, open-ended downside per Strategy D)."* The 45.00 figure is the CaR notional, not a stop. So no price test was reported as met anywhere in this file, and the netting rule had nothing to bind on. (`marks_cover_reference = true` and `has_dividend_drift = false` on that row in any case.)

### WATCHLIST CANDIDATE STATUS

No Development materially changes the candidacy status of any queued name. The Strategy A queue gained MRK, JPM, CVX and XOM earlier today from W1/W4 — none is touched by this scan; `A:FSLR:2026-09-06` remains pending. The four B index candidates from 2026-09-10 (COO, AEO, NAVN, RDDT) were verified landed by D2 in `Watchlist.md`'s B new-entry index — **the handoff completed correctly**; their windows (09-23 / 09-24) remain open and nothing this session closes or invalidates one. The B index gains two names below and loses none.

---

## ANALYSIS — OPPORTUNITY CHECK

Scoped to roster-active strategies with `review_cadence: reactive` — verified live as **A, B, C, E** (D carries `long_horizon`; `state.strategy_roster` shows A–E `ADOPTED`, F/G/H `REJECTED`).

**Strategy B — 2 candidates.** B's frozen Entry criterion 1 requires **≥5% close-to-close on the event day** plus a resolved qualifying public event.

| Ticker | Move | `qualifying_event_date` | Why it creates the opportunity |
|---|---|---|---|
| **HPE** | **+12.4411%** | 2026-09-10 | An $82B hardware incumbent re-rated +12.4% on **another company's** capex disclosure — a second-order repricing of an unquantified share of a third party's spend, which is the over-sized-reaction shape B exists to test |
| **DELL** | **+11.9776%** | 2026-09-10 | The same event, and a larger anomaly per unit of market value: a **$377B** company moving +12% in one session on a read-through rather than on its own disclosure |

**The qualifying event is Oracle's FQ1 print and $95B capex plan, released after the 2026-09-10 close.** It is discrete, dated, public and resolved — which is what distinguishes it from the prior run's SCCO/FCX rejections, where "continued White House indecision" was a non-announcement with nothing to date a thesis from. The event does not have to be the company's own; criterion 1 requires only a public event producing an immediate ≥5% reaction.

**Identity checks, done on the FIELDS and not on the key string.** HPE carries a **completed** `thesis-HPE-B-20260602` (`due_date` 2026-06-02) — a different `qualifying_event_date`, so `(thesis-construction, B, HPE, 2026-09-10)` is a distinct identity and is not suppressed. DELL has no prior B record of any kind. Both appear in the **A watchlist queue** (`A:HPE:2026-05-29`, `A:DELL:2026-05-17`, both pending) — but a queue entry is not an open position, and **Strategy A holds nothing**, so B's criterion 5 (no open A position in the same name) clears for both.

**SMCI (+7.2766%) and ANET (+5.6087%) also clear criterion 1 on the same event and are deliberately NOT routed as separate candidates.** They are the same single factor, and this file's own cohort discipline treats one factor across many tickers as approximately one observation. HPE and DELL are routed as the two cleanest and largest instances; SMCI and ANET are recorded here so a thesis session can widen the cohort from this record if it judges that worthwhile. **This is a judgment, stated so it is reviewable, not a measurement.**

**Names clearing 5% and deliberately NOT routed, each with its reason:** **SWKS** +5.1410% (the merger-clearance **event day was 09-10**, so the 09-11 move is second-day continuation and not an event-day reaction; a regulatory clearance is also about as information-driven as an event gets, which is what criterion 4 rejects); **TLX** −5.1261% (**outcome not established** — the PDUFA date is confirmed but no decision was published, so the gate forbids assessing it; queued for re-assessment, window open to ~09-25); **SMR** −15.6709% (**no identifiable public event**, so no four-part identity is constructible, and its ~$2.56B cap is inside the band needing a second source); **SLS** −14.4181% (rejected at Layer 2, same cap caveat); **JBL** +5.0462% (same factor as HPE/DELL, one observation).

**Strategy A — none.** No development in the window named a dated qualifying catalyst within six months on an A-eligible name. The Oracle capex plan is a demand datapoint, not a dated catalyst on any specific name.

**Strategy C — none, and this is a deliberate suppression rather than an absence.** The 2026-09-15/16 FOMC sits inside C's 45-day window and C's router reads `HYBRID ACTIVATE (FOMC-only)`. But the identity check finds **both** FOMCs in the window already covered: `thesis-FOMC-C-20260908` is in terminal status **`complete`**, and W4 **earlier today** enqueued `thesis-FOMC-C-20261020` (`pending`, due 2026-10-20) for the October meeting. Flagging either would duplicate a live or finished item. Independently, W5's open `strategy_c_criterion2_unreached_pattern` alert records C failing FOMC entry criterion 2 on five consecutive drains.

**Strategy E — 1 candidate, surfaced with a caveat that may well kill it.** **DELL / STX.** Both are conventionally classified in the same GICS sub-industry (Technology Hardware, Storage & Peripherals), and they split by **15.7073pp in a single session** — DELL +11.9776% against STX −3.7297%, with WDC −2.9835% alongside. That is the intra-industry-group divergence E's opportunity bullet asks D1 to surface. **Two things are stated rather than glossed:** (i) the 252-day correlation test (E's frozen Entry criterion 3, corr ≥ 0.5) was **not measured by this run** — that is M2's population screen, not D1's, and this is a surfacing, not a qualification; and (ii) the divergence has a **named fundamental mechanism** — hyperscaler capex accrues to compute and networking, not to commodity storage — which is exactly the "information-driven, not sentiment-driven" finding that would foreclose it at thesis construction. It is surfaced anyway because a 15.7pp one-session same-sub-industry split is the strongest E-shaped observation in weeks, and recording it with its own likely refutation is more useful than not recording it.

**Router activation context, stated so the candidates are not misread as entries.** `state.current_regime` (as of 2026-09-03) carries **A, B, D and E at DO-NOT-ACTIVATE** and C at HYBRID ACTIVATE (FOMC-only); E's flip to DO-NOT-ACTIVATE on 2026-09-03 was a STATE CHANGE and E became capital-disabled from 09-04, leaving **C as the sole capital-enabled strategy**. B is capital-disabled with NAV $0.00. The candidates above therefore go to the **index**, not to thesis construction; the activation gate is D2's to apply and nothing in this file relaxes it.

---

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

**Result: 12 tranches evaluated, 0 flagged, 3 declined at the HARD GATE.** Logged in full — including every decline — as an `events.decision_log` `entry_type='add-candidate-review'` row.

All 12 open tranches are Strategy D; A and B hold nothing, so the A/B/D scope reduces to D.

**Price basis, per the 2026-09-07 pin, both halves.** Numerator: the 2026-09-11 IBKR **regular-session** daily-bar close. Denominator: that **tranche's own** `cost_basis / shares`, never the account-level blended `average_price`. **The pin was validated rather than assumed:** recomputing every tranche against the 2026-09-10 closes reproduced the previous run's twelve published figures **exactly on all twelve** — an independent cross-run check on the arithmetic. And the connector mark was again wrong in both directions, with the worst instance yet: `get_account_positions` served **TSM at 417.39** against a true 09-11 close of **433.24** (**3.66% stale**, and stale even against the 09-10 close of 428.03), AMZN at 252.98 against 256.78, GOOGL at 335.00 against 338.50, VOO at 699.00 against 702.56 — while DIS, ISRG, SGOV and UBER matched.

| Tranche | `mark_vs_cost_pct` | Session | Trigger | Disposition | Evaluable |
|---|---|---|---|---|---|
| D:RTX:2026-04-27 | **+11.7475%** | −0.2221% | none | `declined_hard_gate` | false |
| D:TSM:2026-07-29 | +10.2720% | +1.2172% | none | declined | true |
| D:AMZN:2026-07-09 | +6.4399% | +1.9414% | none | declined | false |
| D:ISRG:2026-07-20 | +5.6191% | +2.4107% | none | `declined_hard_gate` | false |
| D:GOOGL:2026-07-26 | +3.2505% | +1.7740% | none | declined | true |
| D:DIS:2026-08-05 | +2.6638% | +0.6898% | none | declined | true |
| D:TSM:2026-07-21 | +1.2571% | +1.2172% | none | declined | false |
| D:GEV:2026-08-03 | −1.3028% | **+3.6106%** | **strengthened-conviction** | declined | true |
| D:UBER:2026-07-09 | −2.1000% | **−1.2266%** | **dip-with-intact-thesis** | `declined_hard_gate` | false |
| D:AMZN:2026-07-30 | −3.3546% | +1.9414% | none | declined | true |
| D:DIS:2026-05-07 | −4.2841% | +0.6898% | none | declined | false |
| D:GOOGL:2026-07-09 | **−5.9326%** | +1.7740% | none | declined | false |

**Why zero flagged, and it is structural to the session rather than a shrug.** Ten of twelve tranches ROSE. Only UBER and RTX fell, and both are hard-gated. A dip trigger requires a dip; on this tape there were almost none to have.

**The one genuine trigger available was GEV, and it is declined on the MERITS, not on the gate.** GEV rose 3.6106% on the Oracle-capex read-through into electrical equipment, and that *is* new, public, dated information bearing on data-centre electrical demand — the position's own core driver — so `trigger_type` is recorded as `strengthened-conviction` rather than `none`, because saying otherwise would understate the record. It is declined for three compounding reasons: the information is not GEV-specific and reaches it only as a third-party read-through; it is already paid for in a +3.61% same-session move; and GEV's thesis has **no conviction gap for new evidence to close** — 88% organic orders growth against a 15% two-consecutive-quarter invalidation floor is a margin so wide that reinforcing evidence changes no decision. Adding to a name up 3.6% on someone else's capex line, two sessions before an FOMC carrying an ~85–90% implied hike, is momentum wearing conviction's clothing.

**THE HARD GATE COST A REAL FLAG TODAY, and this is the second time.** `D:UBER:2026-07-09` is the one textbook dip-with-intact-thesis in the book: **−1.2266% on a session the tape rose +0.8524%** — a 2.08pp relative decline — sitting −2.1000% against its own tranche cost, with no adverse UBER news in the window and every invalidation criterion quarterly-reported and untested by this session. It cannot be flagged, because its `invalidation_status` carries `$.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'` and no later UBER tranche exists to cover the name. The 2026-09-08 sweep recorded the same of ISRG and UBER. **This has stopped being a record-legibility defect and is now measurably costing candidate flags** — raised this run as an `ops.alerts` info row naming its owning surface (see PROCESS NOTES), rather than absorbed silently for a fourth sweep.

**HARD GATE, computed with all three disjuncts and the NULL-safety wrapper.** Seven tranches report `invalidation_criteria_evaluable = false` on the **third** disjunct: D:AMZN:2026-07-09, D:DIS:2026-05-07, D:GOOGL:2026-07-09, D:ISRG:2026-07-20, D:RTX:2026-04-27, D:TSM:2026-07-21, D:UBER:2026-07-09. **Measured live this run and worth restating, because it is the exact trap that bullet exists to close: ZERO of the twelve carry a `$.status` key and ZERO carry a NULL `invalidation_status`** — so the two-disjunct form would have returned `true` for every single position, reporting as evaluable precisely the seven whose breach status was never assessed. **Four** of the seven are covered at NAME level by a later tranche (AMZN by 07-30, DIS by 08-05, GOOGL by 07-26, TSM by 07-29) and are ordinary declines. **Three are covered nowhere — ISRG, RTX, UBER.**

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review recommended.** High bar; default-NO on ambiguity holds.

A single risk-on session does not plausibly shift any activation state, and the two macro facts that moved are both *deepenings of conditions the router has already priced* rather than new ones: `policy_stance` already reads **hawkish**, so an ~85–90% hike probability confirms the axis rather than turning it; `shock_overlay` already reads **acute**, so the weekend chokepoint escalation deepens a condition already in force. The other three axes (decelerating growth, disinflating, risk-on) are untouched by one session.

**Two watch items, recorded and explicitly NOT escalated.**
1. **Breadth turned UP** — 54.67 → **56.46**, +1.79pp, the first increase in five recorded sessions, breaking a 66.40 → 64.01 → 60.63 → 56.85 → 54.67 run of −11.73pp. It remains 9.54pp below the 66 park-axis threshold. Applying the HEALTHY/WEAK `TECHNICAL_SIGNAL` threshold is **D2a's** job, not D1's — D1 observes, D2a classifies.
2. **`SPY_TREND` flipped to NEUTRAL on 09-10** when SPY closed 0.4158pts below its 50dma; on 09-11 SPY reclaimed it decisively, closing 5.6736pts (+0.7479%) **above**. D2a will likely flip that key back to UP. Again: D1 observes.

---

## EQUITY-BREADTH OBSERVATION

**Written: `events.regime_events`, `as_of_date = 2026-09-11`, `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`, `numeric_value = 56.46`, `value='Barchart $S5TH'`.** Idempotency verified before the write — no prior row existed on that key for that date.

- **Primary: Barchart `$S5TH`**, https://www.barchart.com/stocks/quotes/$S5TH via `tavily_extract` (advanced). Page header verbatim: *"Quote Overview for Fri, Sep 11th, 2026"*; published figure `56.46 +1.79 (+3.27%)` dated `09/11/26`; Open 57.05, Day High 57.05, Day Low 54.87, Previous Close 54.67. **Source-dated, not inferred** — `date_attribution=inferred_post_close` was not used and is not claimed.
- **Previous-Close self-check passes EXACTLY.** Barchart's Previous Close of 54.67 equals the value this key already carries for 2026-09-10, and 54.67 + 1.79 = 56.46 reconciles internally. No overnight settlement revision this session, and no prior row was retroactively corrected (the idempotency rule is unchanged and was not touched).
- **Second independent source obtained — EODData, exact agreement.** https://www.eoddata.com/stockquote/INDEX/S5TH.htm?cb=20260913, end-of-day row "11 Sep 26": Open 57.05, High 57.05, Low 54.87, **Close 56.46**, PREV 54.67 — a **0.00pp** match on the close, the prior reading, and the full OHLC. **Two usable sources**, so no single-source disclosure is owed and the >5pp no-write rule is not engaged. The unsettled tell was checked and is clear on both: Low 54.87 ≠ Close 56.46, and the page stamp is `11 Sep 26 16:26`, post-close — and this is additionally a Sunday fetch sitting ~48h after Friday's close.
- **A STALE-VINTAGE TRAP WAS HIT AND REJECTED — recorded because it is the dangerous shape.** The *same site's* `/quotes/$S5TH/overview` path returned, to the *same* `tavily_extract` call, a header reading *"Quote Overview for Wed, Sep 9th, 2026"* carrying 56.85 with Previous Close 60.63 — a genuinely older cached page, not a data error (both figures match this table's own 09-09 and 09-08 rows). **The on-page date is what caught it.** The bare `/quotes/$S5TH` path served the current vintage and is what produced the figure kept. Fetch path is recorded as part of the provenance.
- **MACROMICRO WEEKLY RE-PROBE WAS DUE TODAY AND WAS SPENT.** Today is Sunday, which anchors the week under the 2026-09-06 W5 ruling, so this run owed exactly one probe. It **FAILED on both sanctioned paths**: `tavily_extract` (advanced, `?cb=20260913`) returned `Failed to fetch url` and a direct `WebFetch` of the same URL returned **HTTP 403**. Not retried beyond those two attempts, per the ruling. The streak since 2026-08-19 is unbroken. `ops.alerts` **`b4fe8d88`** (`breadth_primary_source_persistently_unreachable`) is already OPEN and names this exact mechanism, so it is deliberately **NOT re-raised**.

---

## PARK ALLOCATION CALL

Logged as `events.decision_log` entry_id **`831ce6cf-cb83-4b2a-8794-71615c881cff`** (`entry_type='park-allocation'`); heartbeat written to `ops.heartbeat` (`loop:park_allocator`). `state.park_allocation_latest` confirms the row surfaces to D2 with `status='BOUND'`, `direction='keep'`, `is_call=true`.

- **`vehicle`** — **VOO** (the majority sleeve; at f=50 the tie resolves to the **risk** sleeve. This is *not* a claim that the book is single-vehicle).
- **`target_f_pct`** — **50** (risk sleeve VOO 50% / defensive sleeve SGOV 50%), unchanged from a policy 50 and an actual 49.7305%. **Direction: KEEP. Status: BOUND.**
- **`conviction`** — **MEDIUM**, `conviction_pct` **48** (down from 55).
- **`rationale`** — **This is not the same KEEP as Thursday's de-risk; two axes changed places.** The **index** axis, which single-handedly carried Thursday's step from 25 to 50 on a 0.0548% crossing *below* the 50dma, has **EXITED** — SPY closed 764.29 against a 50dma of 758.6164, now **0.7479% above** it, a reversal an order of magnitude deeper than the crossing that created it, with drawdown from the 252-session closing high at only −1.7471% against a −3% limb. Thursday's record pre-registered this almost exactly: *"if SPY closes back above its 50dma with nothing else changed, the fourth axis is gone and 25 is again the ladder's answer."* The index axis **is** gone, as predicted. But something else did change, so that sentence's antecedent fails. **The rates axis landed and is genuinely defensive** — and I checked whether that is a real entry or an artifact of the measurement arriving, because those are very different things: the stored 10Y series reads 4.83 (09-09) → 4.95 (09-10) → 4.96 (09-11), so it crossed 4.90 on its **own**, two sessions ago. **And that is exactly why it is not counted as fresh evidence for an increase:** Thursday's call already carried this fact narratively (*"the session's dominant macro fact… lives on precisely the axis the panel cannot see"*), so scoring it again today would be double-counting one fact. Run the arithmetic both ways and it is stable — had Thursday scored rates, its standing count would have been 5, cap 100, 0.55 × 100 = 55 → step **50**, the same f it reached; today index drops out (5 → 4), the cap stays 100, and 0.48 × 100 = 48 → step **50**. The ladder returns 50 from both directions, which is the check that this is arithmetic and not narration. **The runner-up is a step down to 25** and it has real arguments — volatility is hanging on by 0.4435, breadth turned up, credit is actively risk-on and moving further away, and this allocator's live record is bad. It loses on one point: a near-certain policy hike two sessions out, plus a weekend escalation on two chokepoints that Friday's tape never saw, is not an evidence set that supports halving defensive exposure. Reaching 25 requires conviction below 37.5 — barely above a third — with 4 of 6 axes standing. I do not hold that.
- **`invalidation`** — **Symmetric by construction and deliberately DISJUNCTIVE; do not require a conjunction.** A step **down** toward f=25 needs **any one** of these, judged in the round (each takes standing to 3 and the cap to 75, whereupon 0.48 × 75 = 36 → step 25): **(a)** VIX closes below its 20d SMA — the margin is only **0.4435**, so one quiet session does it; **or (b)** the 10Y closes below 4.90, most plausibly on a dovish-surprise FOMC on 09-16; **or (c)** Brent retreats below 95, or `shock_overlay` leaves acute; **or (d)** breadth reclaims 66. A step **up** to 75 needs the increase gate (≥1 axis ENTERED within 2 sessions **and** standing ≥ 2) together with conviction above 62.5 — credit finally confirming (which from +0.6688% requires a ~1.17% swing), the index axis re-entering on a decisive break of 758.6164, or a hawkish FOMC surprise. **The asymmetry is deliberate and is the correct direction:** the step-down bar is any one of four axis exits, several within one session's reach, while the step-up bar needs a firing *event* plus higher conviction — cheap to return to risk, dear to leave it, for a park whose default vehicle is the risk asset. No later session is bound by any of this.
- **`theater_check`** — The rationale names the axis that **refuses to confirm** (credit, which moved *further* risk-on to +0.6688% against a −0.50% bar and has now declined to confirm on every session of this episode), names the axis that **exited exactly as Thursday predicted** (index), and names the measured record that argues against any defensive posture at all. Conviction **fell 55 → 48 while f is unchanged**, purely because the ladder's step spacing is 25 and 48 sits 2 points from 50 — if the number had been reverse-engineered to defend the position, keeping 55 would have been the easier arithmetic; if reverse-engineered to look decisive, 37 would have bought a headline re-risk. Neither was done.

### Ladder arithmetic (stated, as required)

Hand-scored `standing_defensive_count` = **4** → raw cap = `LEAST(100, 25 × 4)` = **100**. **Decay:** the confirmed cap steps down only on the first session at which a *lower* standing count has already held on the two preceding measured sessions; the counts run **3 (09-09) → 4 (09-10) → 4 (09-11)**, so no lower count has held and no step-down is due — the confirmed cap equals the raw cap at **100**. The clamp is therefore non-binding (50 ≤ 100). **Conviction sizes it:** 0.48 × 100 = 48; the nearest step in {0, 25, 50, 75, 100} is **50** (|48−50| = 2 against |48−25| = 23). **No ±1-step deviation taken** — see below. **Crisis override not engaged:** session index move **+0.8524%** (bar −2.5%), VIX **15.84** (bar 28).

### The six axes, measured live this session

| Axis | Verdict | Reading |
|---|---|---|
| **index** | **NOT defensive — EXITED TODAY** | SPY **764.29** > 50dma **758.6164** by 5.6736pts (**+0.7479%**); dd **−1.7471%** does not clear the −3% limb |
| **rates** | **DEFENSIVE — entered 09-10, firing** | 10Y **4.96** ≥ 4.90; crossed on its own two sessions ago (4.83 → 4.95 → 4.96) |
| volatility | defensive, standing, **margin collapsing** | VIX **15.84** > 20d SMA **15.3965** and > 15 — margin **+0.4435**, down from **+2.4655** |
| breadth | defensive, standing, **improving** | **56.46** < 66, but **+1.79pp**, the first rise in five sessions |
| shock | defensive, standing, both limbs | `shock_overlay='acute'` **and** Brent **104.61** > 95 |
| **credit** | **NOT defensive — the honest counterweight, and it widened** | HYG/IEF **0.863641** vs 20d SMA **0.857904** = **+0.6688%**; the test needs **−0.50%** |

Credit did not merely fail to confirm again — it moved **further away**, from +0.5561% to +0.6688%. **Credit has now declined to confirm on every single session of this defensive episode.** In a genuine risk event credit leads; it is not leading, and it is now leading the other way. That, plus a VIX margin of 0.4435 and a cross-sector spread of only 1.6285pp, is why this is MEDIUM **48** and not Thursday's 55.

**A note on the VIX 20d SMA, because one input bar is corrupt.** The 2026-09-04 ^VIX bar carries close 15.30 *above* its own high of 14.58 — the known defect class, already documented in the 2026-09-08 park record. Per `bigquery/216`'s SOURCE TRAP, the axis reads `state.signal_marks_curated`, which carries **14.53** for that session; substituting it gives a 20d SMA of **15.3965**. On the raw bars the SMA is 15.4350. **The axis verdict is unchanged either way** (15.84 exceeds both), and both figures are recorded in `fields.readings` rather than one being quietly chosen.

### Axis overrides — the mechanical panel disagrees, and the override is a DEMOTION

`state.park_axis_daily` for 2026-09-11 reports `standing_defensive_count = 5`, `firing_count = 2`, `cap_pct = 100`, `increase_gate_open = TRUE`. Its four price-derived axes still carry `measured_on = 2026-09-10` (`sessions_since_measured = 1`), because D2a — which writes `events.signal_marks` — does not run on Friday or Saturday; only `rates` carries a same-session 09-11 reading, via the `bigquery/236` backfill.

Recorded in `fields.axis_overrides`: **index** (mechanical *DEFENSIVE and FIRING* @09-10 vs live **NOT defensive** @09-11), taking standing 5 → **4** and firing 2 → **1**, cap unchanged at 100. **Note the direction: this override DEMOTES the mechanical count, which the one-way ratchet expressly permits** — the ratchet's prohibition is on the panel *upgrading* a call, and it is not engaged here. **Credit and rates are both recorded as explicit non-disagreements** — each re-measured live, each agreeing with the panel.

### Why no ±1-step deviation down to 25

The tempting deviation is to override the ladder downward because defensive positioning has destroyed value on this tape — and the record supports the premise: segment-scored on `analytics.park_counterfactuals` as of 2026-09-10, the AI era (anchor 2026-07-24) reads **ai_index −0.5684%** against never-switching **VOO +2.5783%**, and against even the record-only rule shadow at **+2.9370%**; both closed defensive excursions lost. **But that is precisely the intervention that would make the forward test unmeasurable.** The ladder was activated on live capital by owner directive on 2026-09-04 specifically *to measure this*, and an allocator that overrides its own arithmetic whenever the arithmetic says "defensive" is running the counterfactual rather than the system. W5's PARK FORWARD-TEST COUNTDOWN forces the re-evaluation after three post-activation episodes; that is the sanctioned venue for this argument, not here.

**An honest limitation, recorded because it is invisible in the output.** This call is **less defensive than Thursday's and the ladder cannot express it**. Conviction moved 55 → 48 and f did not, because both map to the same step on a 25-point grid. A reader seeing two consecutive f=50 rows should not read them as two identical assessments.

---

## RECOMMENDED ACTIONS

- **Exits triggered:** none.
- **New entry candidates (full thesis construction required in separate sessions per Strategy.md):**
  - **HPE — Strategy B.** +12.4411% close-to-close (55.22 → 62.09, IBKR RTH daily bars, contract 209411798) on Oracle's FQ1 print and $95B capex plan released after the 2026-09-10 close. Clears B Entry criterion 1 by ~2.5×. `qualifying_event_date` **2026-09-10**. Prior `thesis-HPE-B-20260602` is complete on a different qualifying event — distinct identity, checked on the fields. No open A position (A holds nothing), so criterion 5 clears.
  - **DELL — Strategy B.** +11.9776% close-to-close (506.62 → 567.29, IBKR RTH daily bars, contract 346218218) on the same event. Clears criterion 1 by ~2.4×. `qualifying_event_date` **2026-09-10**. No prior B record of any kind — the four-part identity is new outright. No open A position, so criterion 5 clears.
  - **DELL/STX — Strategy E (pair).** A 15.7073pp one-session divergence inside one GICS sub-industry (DELL +11.9776% against STX −3.7297%, WDC −2.9835% alongside). **Surfacing only, not a qualification:** E's frozen Entry criterion 3 (252-day correlation ≥ 0.5) was not measured by this run — that is M2's screen — and the divergence carries a named fundamental mechanism that may foreclose it at criterion 4.
- **Add candidates:** none. 12 open Strategy-D tranches evaluated, 0 flagged, 3 declined at the HARD GATE (ISRG, RTX, UBER).
- **Watchlist updates:** ADD **HPE** and **DELL** to the Strategy B new-entry-candidate index. No removes, no demotions.
- **Router reviews recommended:** none.

```yaml d1_actions
- action: thesis
  ticker: HPE
  strategy: B
  qualifying_event_date: 2026-09-10
  source_research_screen_id: single-name-move screen, D1 2026-09-13
  detail: +12.4411% close-to-close (55.22 -> 62.09, IBKR RTH daily bars, contract 209411798) on Oracle's FQ1 print and $95B capex plan released after the 2026-09-10 close. Clears B Entry criterion 1 by ~2.5x. An $82.2B incumbent re-rated on another company's capex disclosure - the over-sized-reaction shape B tests. Prior thesis-HPE-B-20260602 is complete on a different qualifying event, so the identity is distinct (matched on fields, not the key string). A holds no position, so criterion 5 clears.
- action: thesis
  ticker: DELL
  strategy: B
  qualifying_event_date: 2026-09-10
  source_research_screen_id: single-name-move screen, D1 2026-09-13
  detail: +11.9776% close-to-close (506.62 -> 567.29, IBKR RTH daily bars, contract 346218218) on the same Oracle capex event. Clears criterion 1 by ~2.4x. At $376.7B this is the larger anomaly per unit of market value. No prior B record of any kind - four-part identity new outright. A holds no position, so criterion 5 clears.
- action: thesis
  ticker: DELL/STX
  strategy: E
  qualifying_event_date: 2026-09-11
  source_research_screen_id: single-name-move screen, D1 2026-09-13
  detail: 15.7073pp one-session divergence inside one GICS sub-industry - DELL +11.9776% against STX -3.7297%, with WDC -2.9835% alongside. SURFACING ONLY, not a qualification - E's frozen Entry criterion 3 (252-day correlation >= 0.5) was NOT measured by this run, that is M2's population screen. The divergence has a named fundamental mechanism (hyperscaler capex accrues to compute and networking, not commodity storage) which may foreclose it at criterion 4.
- action: watchlist
  ticker: n/a
  strategy: B
  qualifying_event_date: n/a
  source_research_screen_id: single-name-move screen, D1 2026-09-13
  detail: ADD HPE and DELL to the Strategy B new-entry-candidate index. No removes and no demotions this session. SMCI (+7.2766%) and ANET (+5.6087%) also clear criterion 1 on the same event and are deliberately NOT routed as separate candidates - one factor across many tickers is approximately one observation; recorded so a thesis session can widen the cohort from this record if it judges that worthwhile.
```

---

## PROCESS NOTES

- **Frontier-LLM capability check: run, silent, no capture.** One Hugging Face `hf_fs` paper search on the Sunday battery (long-context / lost-in-the-middle). The five results published 2025-02 through 2026-01 — none since the scan-window start — so nothing qualified for the abstract skim, no `[HF Frontier-LLM Capture]` entry was written and no `state.strategy_candidates` row was emitted. Default-silent on ambiguity, as specified.
- **MCP-TRANSPORT REJECTION encountered and handled correctly, recorded because the wrong response is the damaging one.** The single-name `sp_log_decision` call returned `Required parameter is missing: query`. Per the §Observability rule the identical call was **re-issued verbatim and landed on the first retry**. The note was **not** trimmed — trimming is the one response explicitly forbidden here, and the 2026-09-09 incident it exists to prevent produced a permanently abbreviated record for a size limit that does not exist.
- **Fields-JSON key contract VERIFIED after writing, not assumed.** `state.research_screen_calls` for 2026-09-13 returns **14 passed + 6 rejected_notable** single-name item rows and **4 + 1** sector item rows, with `name`, `metric_pct` and `conviction_pct` populated on **100%** of all 25, `surfaced_count` equal to `ARRAY_LENGTH(passed)` on both screens (14 and 4), and the agreement columns populated from the **nested** `"agreement": {…}` object (7/7/2 and 0/4/0). `state.add_candidate_reviews` returns 12 item rows with 7 `invalidation_criteria_evaluable = false`. The W2 `screen_fields_schema_drift` failure mode is closed for this run.
- **One out-of-scope finding raised rather than absorbed**, naming its owning surface per this run's standing rule: `ops.alerts` **info**, category **`add_gate_uncovered_breach_status`** — ISRG, RTX and UBER carry `$.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'` with no later tranche in the same name carrying a fresh assessment, so the ADD hard gate can never affirmatively confirm "unbreached" for them and they are structurally ineligible regardless of merit. **Owner: M3** (the routine that already re-reads each Strategy-D thesis monthly and is the only one positioned to assess breach status), with spec adjudication to **W5 SPEC-DEFECT NOTICE INTAKE**. Raised now because it stopped being cosmetic: this run had a genuine dip-with-intact-thesis in `D:UBER:2026-07-09` that the gate blocked. D1 cannot fix it — D1 does not write `state.current_positions`. The message is a fixed string with all varying detail in the payload, per the message-stability rule, and `sp_raise_alert_once` dedups it against re-raising each sweep.
- **Two pre-existing open alerts deliberately NOT re-raised:** `b4fe8d88` (`breadth_primary_source_persistently_unreachable`, MacroMicro — probe due, spent, failed again) and `hy_oas_not_refreshed_by_last_m1a` (`hy_oas` still at `ref_month` 2026-07-01, `fetched_ts` 2026-08-05). The latter is again **not** a park defect: the credit axis reads HYG/IEF, and `hy_oas` is labelled STALE in `fields.readings` and excluded from the decision.
- **Four data-quality flags found and recorded rather than smoothed:** the ^VIX 2026-09-04 bar (close 15.30 above its own high 14.58 — handled via the curated substitution above); SPY 2025-10-30 (close 679.83 below its own low 679.86, inside the 252-session window but nowhere near the high, so the drawdown is unaffected); IEF 2026-08-10 and HYG 2026-09-11 (1-cent close-below-low violations, immaterial to a credit verdict sitting +0.6688% against a −0.50% bar).
