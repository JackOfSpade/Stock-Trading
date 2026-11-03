2026-11-03
<!-- d1_scan_through_utc: 2026-11-03T22:22:24Z -->

# Daily Market Development Scan — session 2026-11-03 (Tue), run 2026-11-03 (Tue)

Scan window: 2026-11-02 15:20 MT → 2026-11-03 15:22 MT (~24h). The start is the prior `Daily.md` marker `2026-11-02T22:20:52Z`. The window holds one completed US session, Tuesday 2026-11-03, which was also US midterm election day. "Today" comes from America/Denver system time, because `state.trading_day_today` was unreadable this run (see the DEGRADED MODE banner).

> **⚠️ DEGRADED MODE: the BigQuery connector was unreachable this run (re-authorization required).** At pre-flight (~22:05Z) the Google-Cloud-BigQuery MCP server required authentication, and the `bq` CLI returned `Invalid Credentials`. That is auth wording, so it is non-waitable and the retry ladder was not entered. Every `state.*`, `perf.*` and `events.*` read and write was unavailable.
>
> **Substitutions used:**
> - The open book and live marks came from the **IBKR connector** (`get_account_positions`, `get_price_history` regular-session bars).
> - The regime, router state and per-strategy kill state were carried forward from the **prior Daily.md (2026-11-02)**.
> - "Today" came from system time, not `state.trading_day_today`.
>
> **Deferred (needs BigQuery):**
> - run logging;
> - both `research-screen` rows;
> - the `add-candidate-review` row;
> - the equity-breadth `regime_events` row;
> - the 120 paper-book calls;
> - the park heartbeat;
> - `ops.web_calls`.
>
> Every row is pre-generated as digest-guarded SQL in `ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/`, with its ledger at `ops/spikes/bigquery-deauth-2026-11-03-d1-deferred-writes.md`. A `[Claude] ATTENTION — RE-AUTH BigQuery connector` calendar event was created as the only surviving alert channel.
>
> **D1 is research-only and stages no orders, so the scan below is complete; only the BigQuery side-writes are deferred.** D2a, D2 and D3 will halt on the connector until it is re-authorized.

SCAN MODE: ROUTER-GATED, carried forward from 2026-11-02 because `state.current_regime` was unreadable. A, B, D and E are DO-NOT-ACTIVATE; C is HYBRID ACTIVATE (FOMC-only), so only its carve-out class is evaluated.

Tape: **a narrow, chip-led tech rebound on election day.** Big Tech and semis bounced after a three-session liquidation, while the average stock, staples and materials fell.
- **Indices.** IBKR closes, 11-02 → 11-03:
  - SPY 752.10 → **754.35 (+0.30%, 0.67x volume)**; SPX 7541.40 → 7568.58 (+0.36%).
  - QQQ +0.62%, **SMH +2.01%**, DIA −0.44%, RSP −0.33%, IWM +0.23%.
  - RSP lagged SPY by 0.63pp, reversing Monday's breadth rotation.
- **Volatility.** VIX 21.15 → **20.83** (IBKR IND/CBOE bar, 900-second delayed flag), inside the 15–25 NORMAL band.
- **Rates and havens.** TLT −0.76% (10y about 4.91–4.93%), HYG +0.12%, GLD −0.66%.
- **Oil.** Brent (BZUSD, provisional same-evening read) was **104.36 on 2026-11-03**, against **104.77 on 2026-11-02** in the same FMP series (−0.39%). The vendor has revised the 11-02 figure from the 104.22 recorded yesterday. USO +0.83%, XLE −0.85%.
- **Breadth.** Down to **61.63** (from 63.41), from Barchart `$S5TH`, settled-stamped 16:52 ET. That is a single source; ChartRow lags one session.

## TL;DR

- **Exits triggered: none.** None of the twelve D tranches has a mechanical trigger, and no development in the window meets an invalidation criterion. UBER reports Wed 11-04 before the open and DIS on 11-17; neither print has happened yet.
- **New entry candidates: none routed.** **49** names cleared Strategy B's frozen ≥5% floor on their own events, all confirmed on IBKR bars. B is `DO-NOT-ACTIVATE` (carried forward), so all 49 go to the index only. No new FOMC-class C candidate.
- **Add candidates: none (0 of 12).** All 12 tranches are declined at the hard gate this run, because `invalidation_status` is a BigQuery field the run could not read. GOOGL ×2 and TSM ×2 carry a dip-with-intact-thesis trigger. D is capital-disabled regardless.
- **Watchlist: 49 changes.** ADD the 49 names to the Strategy B new-entry index.
- **Regime review: no review.** A limited US strike on Iranian SAM sites (Qeshm and Hengam islands) falls inside the standing `acute` grade. No settlement is in force: Iran's 7 conditions are unmet and the blockade continues.

Park: VOO-only pin NOT VERIFIED (BigQuery unreadable). IBKR shows idle capital in VOO only, and the heartbeat is deferred.

Paper book (J): 120 calls (generated, landing deferred: BigQuery down), n_realized/net_mu/ready unreadable this run; futility-stop query not run; marks not ingested (self-heal next run)

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **Iran / Hormuz: a new limited US strike, and still nothing in force.**
  - **The strike.** US forces struck Iranian targets in the Strait of Hormuz. Iranian state media reported explosions on Qeshm and Hengam islands and near Bandar Abbas.
    - A US official said the strikes hit Iranians firing surface-to-air missiles at US forces (AP via OPB, 11-03; Reuters).
    - AP called it "a limited strike" hours before the midterms.
    - Timing straddles the window start: the official spoke on 11-02 (evening ET), and wire copy is stamped 11-03. Yesterday's file did not have it.
  - **No settlement.**
    - Iran's Rezaei (SNSC, Reuters 11-03) says the strait reopens only after **7 conditions** are met: end of the US naval blockade, oil-sanction waivers, unfrozen assets, a ceasefire on all fronts including Lebanon, and recognition of the Iran-Oman route.
    - Qalibaf says Iran sent a "firm and rational response" and "the ball is in America's court".
    - An Al Araby report of a draft MOU "approved by Washington and Tehran" was **denied by IRIB**.
    - Vance: "we've made some progress", with no deadlines.
  - **Forward risk.** The pre-midterm strike moratorium nominally expired on 11-03.
    - The WSJ reports Trump is leaning toward a large post-midterm attack. Trump said on 11-02 he was not considering one.
    - Iran International says Gulf allies were told to prepare for possible strikes after 11-04.
  - **Oil.** Oil was flat to slightly lower after Monday's −8%, with intraday direction mixed.
- **Crypto.** BTC is about $77.6k (+1.2%, Reuters). Binance added withdrawal routes after last week's hack.
- **Other.**
  - The PBOC raised its FX deposit reserve ratio to 6% from 4%, effective 11-15 (Reuters).
  - A second US-hosted Russia-Ukraine trilateral round is set for Abu Dhabi on 11-10 to 11-11 (scheduled only).
- **M&A in the screen:**
  - CVI is buying Marathon Petroleum refinery assets for $4.2B cash. CVI is the acquirer, and it fell −13.09%.
  - Liberty Global (LBTYK) announced a planned spin-off. It is not an all-cash target, so the deal-pinned rail does not apply.
- **Unmeasured:** material bankruptcies, disasters, enforcement actions and US-China tariffs. Nothing turned up in the searches run, which were not exhaustive. Two searches hit Tavily HTTP 429 limits.

### 2. Scheduled events that resolved in the window

- **JOLTS, September:** openings **7.5M** against a consensus of about 7.10–7.13M, a beat. The prior figure is reported inconsistently across sources (7.08M against 7.19M) and is unresolved. Hires rate 3.4%.
- **Factory orders, September:** **+1.8% m/m** against +1.1% consensus. That is medium confidence: the source may conflate it with durable goods, and the prior figure is reported inconsistently.
- **RBA:** hiked 25bp to **4.85%** as expected. It is the fifth hike of 2026, on a 6–3 vote. The statement softened, and AU yields fell.
- **Fed:** no Fed-speaker item was found (a coverage gap after a 429). Yesterday's file had December-hike pricing at about 75%; that was not re-verified. The next FOMC is December 8–9.
- **Midterms (11-03):** polls and prediction markets favour a Democratic House, with the Senate a toss-up. CNBC says a sweep is not fully priced. Results arrive after this window.
- **Earnings, router-gated sourcing.** Events were labelled from the key-less Nasdaq calendar (11-02, 11-03), with release times from one scripted EDGAR `data.sec.gov/submissions` batch. The reporters that cleared the B floor are in item 3.
  - Apple and Palantir reported after the close on 11-02. Both fell on 11-03 but below the 5% floor (AAPL about −1.9%).
  - AMD reported after the close on 11-03. Headlines put it about +7% after hours; that is the 11-04 reaction session and outside this window's measured close.
- **FDA:** no PDUFA outcome was resolved against FDA's own pages; all items are **UNRESOLVED**. Agios mitapivat's goal date was extended to 2027-02-01 (company). uniQure's BLA was accepted (goal date 2027-05-01), which is not an outcome. One unsourced social-media claim of a RARE approval was not cited.
- **Upcoming:**
  - 11-04: ADP, ISM Services, the Treasury refunding, UBER (pre-open), and midterm results.
  - 11-05: BoE (a hike is expected).
  - 11-06: October payrolls.

### 3. Large single-name moves — AI-significance screen, ROUTER-GATED MODE (row DEFERRED: BigQuery down)

- **Population.** US-listed, market cap ≥$2B, and |close-to-close| ≥5% on 11-03 against 11-02. That is B's frozen floor; there are no sub-floor write-ups in this mode.
- **Discovery.**
  - The Nasdaq screener supplied the symbol list and caps only.
  - Moves were found from per-symbol Nasdaq `quote/info` closes dated "Closed at Nov 3, 2026". **2,117 of 2,120** names were measured, and **146** moved ≥5% (`rail_tally`).
  - BRK/A and BRK/B (slash-symbol fetch failed) and GJS (no regular-session print) are unmeasured. 383 screener rows with no marketCap were not screened.
  - Excluded as non-common: CORZZ, SLNHP, RVMDW.
- **Confirmation and identity.** Every passed name was confirmed from IBKR regular-session daily bars (`close` array at both ends, `outside_rth=false`). Release times come from the EDGAR batch only; no per-name metered or news call was made.
  - IBKR's `search_contracts` hit its 30-per-minute limit mid-pass, so the orchestrator ran a paced second pass. That pass measured all 23 remaining own-event names, and all cleared 5%.
  - Seven near-floor discovery names fell just below 5% on IBKR and were dropped: TSEM +4.98%, ENS +4.99%, EFXT +4.99%, RMBS +4.96%, SFM −4.96%, APO −4.94%, LBTYA +4.93%.
- **Close-chain check.** The durable BigQuery read could not run. By hand against yesterday's passed table: **0 hits**, which is not a clearance.

**Passed (49, `surfaced_count = 49`, all anchors resolved):**

|Ticker|Move|IBKR closes 11-02 → 11-03|Event|Release|Anchor|Conv.|Prior ≥5% sessions|
|---|---|---|---|---|---|---|---|
|GPK|+21.22%|9.33 → 11.31|Q3 earnings|pre-open|2026-11-03|75|1|
|XMTR|+16.55%|95.49 → 111.29|Q3 earnings|pre-open|2026-11-03|30|3|
|BETA|+16.00%|20.38 → 23.64|Q3 earnings|pre-open|2026-11-03|75|1|
|FN|+15.45%|314.7 → 363.33|Q3 earnings|after-close|2026-11-02|30|5|
|DT|-14.69%|55.13 → 47.03|Q3 earnings plus new $1B buyback authorization|pre-open|2026-11-03|60|1|
|ADEA|-13.59%|20.67 → 17.86|Q3 earnings|after-close|2026-11-02|30|3|
|NBIX|+13.42%|145.35 → 164.85|Q3 earnings|after-close|2026-11-02|60|0|
|IT|-13.19%|235.26 → 204.22|Q3 earnings|pre-open|2026-11-03|45|2|
|CVI|-13.09%|55.92 → 48.6|Q3 earnings plus a $4.2B cash acquisition of Marathon Petroleum refinery assets (CVI is the acquirer)|pre-open|2026-11-03|45|2|
|FISV|+12.46%|51.93 → 58.4|Q3 earnings|pre-open|2026-11-03|60|1|
|PTCT|+11.89%|60.88 → 68.12|$500M share repurchase authorization (Q3 earnings were 10-29)|pre-open|2026-11-03|60|1|
|RRX|+11.81%|160.93 → 179.93|Q3 earnings|pre-open|2026-11-03|45|2|
|PAY|-11.50%|35.05 → 31.02|Q3 earnings|after-close|2026-11-02|60|1|
|DRVN|-11.24%|12.72 → 11.29|Q3 earnings plus Item 4.02 non-reliance on prior financials|pre-open|2026-11-03|60|1|
|LSCC|+10.98%|95.44 → 105.92|Q3 earnings|after-close|2026-11-02|30|3|
|LIND|-10.64%|36.66 → 32.76|Q3 earnings|pre-open|2026-11-03|60|0|
|TBBB|+10.53%|56.97 → 62.97|Q3 earnings (6-K)|after-close|2026-11-02|60|0|
|SRAD|+10.33%|12.87 → 14.2|Q3 earnings (6-K)|pre-open|2026-11-03|45|2|
|TRI|-9.87%|122.24 → 110.18|Q3 earnings (6-K)|pre-open|2026-11-03|45|1|
|SHC|-9.64%|17.74 → 16.03|Q3 earnings|pre-open|2026-11-03|45|0|
|AEIS|+9.63%|217.19 → 238.1|Q3 earnings|after-close|2026-11-02|30|3|
|SYY|-9.33%|81.74 → 74.11|Q3 earnings plus CFO appointment|pre-open|2026-11-03|45|0|
|GRAB|+9.09%|2.86 → 3.12|Q3 earnings (6-K)|pre-open|2026-11-03|45|1|
|OTTR|-8.85%|91.51 → 83.41|Q3 earnings|pre-open|2026-11-03|45|0|
|ZBRA|-8.76%|361.13 → 329.5|Q3 earnings|pre-open|2026-11-03|45|0|
|SHOP|-8.74%|156.22 → 142.57|Q3 earnings|pre-open|2026-11-03|45|1|
|DD|+8.61%|141.3 → 153.46|Q3 earnings|pre-open|2026-11-03|45|0|
|MTCH|-8.49%|42.07 → 38.5|Q3 earnings|after-close|2026-11-02|45|0|
|MDGL|-8.08%|431.15 → 396.32|Q3 earnings|pre-open|2026-11-03|45|0|
|CALX|-7.97%|36.13 → 33.25|Q3 earnings|after-close|2026-11-02|45|0|
|RVTY|+7.84%|151.6 → 163.48|Q3 earnings|pre-open|2026-11-03|45|1|
|RYTM|-7.49%|93.44 → 86.44|Q3 earnings|pre-open|2026-11-03|45|0|
|TLN|+7.29%|332.99 → 357.28|Q3 earnings|pre-open|2026-11-03|45|1|
|HGTY|+7.17%|15.89 → 17.03|Q3 earnings|pre-open|2026-11-03|45|0|
|BALL|-7.14%|68.07 → 63.21|Q3 earnings|pre-open|2026-11-03|45|0|
|JAZZ|+7.13%|214.44 → 229.74|Q3 earnings|after-close|2026-11-02|45|0|
|ETN|+7.00%|366.07 → 391.7|Q3 earnings|pre-open|2026-11-03|45|2|
|ULS|+7.00%|75.14 → 80.4|Q3 earnings|pre-open|2026-11-03|45|0|
|ADM|-6.82%|75.77 → 70.6|Q3 earnings|pre-open|2026-11-03|45|0|
|MSA|-6.64%|186.44 → 174.06|Q3 earnings|after-close|2026-11-02|45|0|
|LDOS|-6.55%|144.16 → 134.72|Q3 earnings (8-K accepted 2026-11-02 22:38Z)|after-close|2026-11-02|45|0|
|APTV|-6.53%|44.23 → 41.34|Q3 earnings (post-spin Aptiv)|pre-open|2026-11-03|45|0|
|NPO|+6.06%|268.98 → 285.27|Q3 earnings|pre-open|2026-11-03|45|1|
|KDP|-5.65%|36.82 → 34.74|Q3 earnings|pre-open|2026-11-03|45|0|
|LBTYK|+5.51%|7.99 → 8.43|Q3 earnings (8-K 2.02/7.01)|pre-open|2026-11-03|45|0|
|KMX|-5.39%|56.42 → 53.38|Strategic Update investor event at 8:00 ET (8-K Item 7.01)|pre-open|2026-11-03|45|0|
|RIG|-5.30%|6.23 → 5.9|Q3 earnings plus fleet status report|after-close|2026-11-02|45|2|
|ALSN|+5.16%|113.09 → 118.92|Q3 earnings|after-close|2026-11-02|45|0|
|CE|+5.05%|47.94 → 50.36|Q3 earnings (8-K 2.02 plus Item 7.01 webcast notice)|after-close|2026-11-02|45|0|

- **Noisy names.** FN has 5 other ≥5% sessions in its 10-trading-day window. XMTR, ADEA, LSCC and AEIS have 3 each, and IT, ETN, RRX, CVI, SRAD and RIG have 2. Their 11-03 move is not a clean single-event reaction (criteria 2 and 4 context).
- **Event notes:**
  - DRVN's 8-K carries an **Item 4.02 non-reliance** on prior financials.
  - DT and PTCT paired the print with buybacks; PTCT's Q3 was on 10-29, so its 11-03 event is the $500M authorization.
  - KMX's event is an 8:00 ET Strategic Update (Item 7.01), not earnings.
  - Anchor judgment calls on the issuer EDGAR stamp: LDOS is anchored 11-02 (22:38Z), even though the calendar listed pre-market 11-03; GRAB is anchored 11-03 (6-K stamp), even though the calendar listed after-hours 11-02.
- **Rejected:**
  - **`rejected_notable` (1).** STVN −28.57% (19.74 → 14.10), code `ANCHOR_UNRESOLVED`. The calendar says pre-market 11-03, but every EDGAR 6-K is stamped 21:05–21:15Z, after the close, so no release time is established and no watchlist action is written.
  - **`rejected_compact` (96).** Closes for these are Nasdaq discovery closes, not IBKR-confirmed, and the row says so.
    - 48 `ANCHOR_UNRESOLVED`: no own-event filing.
    - 43 `DAY2_EVENT_PRIOR`: the own event came before 11-02's close.
    - 5 `POST_MOVE_EVENT`: the only filing came after the 11-03 close (ECG, NVTS, PRIM, DUOL, SEB).
- **Deal-pinned:** none. The 8-K text was read for CVI, DT, PTCT, SYY, KMX, CE, IT, HGTY, ULS, RIG and APTV, and the LBTYK 8-K plus two of four 425 exhibits.
- **Metered calls:** none (key-less Nasdaq and EDGAR plus IBKR).
- **Durable row:** DEFERRED, split write (3 parts + call), `ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen/`, call digest `30cceaa8…57b2ce`. agreement = {both 49, ai_only 0, rule_only 97}.

### 4. Sector-level moves (row DEFERRED; IBKR regular-session closes 11-02 → 11-03)

- **Surfaced (3 of 11; rail tally 4 at |move| ≥ 1%).**
  - **XLP −2.07%** (90.83 → 88.95, conviction 60). Staples reversed Monday's +1.58% as money rotated back into chips. Sysco (SYY −9.33%, item 3) guided weak. Reuters put S&P staples at −1.76%.
  - **XLB −2.01%** (53.67 → 52.59, conviction 60). Industrial metals retreated: copper futures −2.6% to about $6.40/lb (Benzinga), and DD's print was the sector's bright spot.
  - **XLK +1.31%** (174.22 → 176.51, conviction 45, below the legacy 2% bar). The semis rebound (SMH +2.01%, NVDA +2.3%, MU +2.6%, AMD +4.9% before its print) outweighed AAPL −1.9% and PLTR's post-earnings drop.
- **Rejected notable:** XLC +1.18% (conviction 30). It moved with the Big Tech rebound, with no sector-specific catalyst.
- **Not surfaced:** XLI +0.95%, XLRE +0.07%, XLV −0.31%, XLU −0.57%, XLF −0.64%, XLY −0.70%, XLE −0.85%.
- **Id check.** All 11 prior closes match the 11-02 closes recorded yesterday, so no contract ids were re-resolved.
- **Sources:** IBKR bars; Reuters via Business Times; Benzinga midday; AP; MarketWatch; FMP BZUSD. Row DEFERRED: `ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/sector_screen/`.

### 5. Notable commentary

- **ING:** Tuesday is "nothing more than the day ahead of a much bigger day," with the midterm result and the refunding arriving together.
- **Sell-side headlines, not opened:**
  - Goldman: "don't try to time the S&P 500 top," with EPS growth seen slowing to 11%.
  - Citi raised its bitcoin target to $113k.
  - Pershing Square calls Big Tech's ~$740B capex "offensive, not defensive". Ackman (11-03) called the market "broken" but touted V, MA and NFLX.
  - Bernstein says data-center political risk is "overblown"; power names rallied on election day (GEV +6.49%).
- **Wasif Latif (Sarmaya, Reuters):** the market has been absorbing the Fed, earnings season and the midterms at once.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

**Mechanical exit-trigger sweep (DEGRADED).**
- **The book.** It comes from IBKR `get_account_positions` alone; `state.current_positions` was unreadable. The 8 strategy tickers carry the same share counts as yesterday's reconciled book: AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156. So there is no new connector-only position, and no `position_reconciliation_lag`.
- **VOO** (16.895 sh) is the park holding, not a strategy position.
- **Exit triggers.** Yesterday's reconciled read showed no tranche carrying a `convergence_target` or `time_exit_date`, and no fill has occurred since. **No EXIT TRIGGERED.**

**Per-strategy kill-trigger sweep (DEGRADED, a reconstruction).**
- **Strategy D.** `perf.kill_flags` was unreadable, so this carries forward from yesterday's sweep: all flags FALSE, peak 1.1065, unit about 1.018 at 11-02.
  - Refreshed with IBKR 11-03 closes, book market value is 522.50 → 533.74 (**+2.15%**). That puts the unit at about 1.040 and the drawdown at about **−6.0%**, far from the −50% kill.
  - `runaway_review`, `evidence_kill` and `interim_underperf_warning` are carried as FALSE. No alert is raised or healed this run, because `ops.alerts` is unreachable.
- **Strategy B.** No open positions, so the correlation check is inert.

**Thesis-invalidation check.**
- **Source of the criteria.** Criteria are reconstructed from `Monthly_D_Position_Deep_Dive.md`, which lists 34 at-entry criteria with zero breached, plus yesterday's c1–c5 verdicts. The entry-record text is in BigQuery.
- **Basis.** Closes are IBKR 11-03; moves are against 11-02.
- **AMZN** 250.69 (+2.06%). Only analyst notes and a Jassy retail interview. The Q3 print stands as assessed. **NO.**
- **DIS** 114.18 (+0.95%). Bloomberg/WSJ report thousands of job cuts and a target of up to 20% cost savings. That is a cost action, not a criterion. FQ4 is confirmed for 11-17 and has **not occurred** (EVENT-IDENTITY GATE). **NO.**
- **GEV** 918.20 (+6.49%). An election-day rally in power names, plus Bernstein calling political risk "overblown"; the Trench Group deal is re-coverage. Q3 orders are +96% organic, far above the 15% line. **NO.**
- **GOOGL** 280.03 (+0.37%, −13.8% against 10-28). Only drop recaps, a euro bond sale, and a ROSEN class-action solicitation, which is not a criterion. c4 (structural remedy) is unchanged. **NO.**
- **ISRG** 440.75 (+0.89%). A small insider sale, and instrument-price cuts already disclosed with Q3. **NO.**
- **RTX** 203.82 (+0.51%). A DARPA PICASSO phase-one award. A "$24.4B SM-6" article carries a stale quote and is unconfirmed in-window, so it is not counted. **NO.**
- **TSM** 404.80 (+1.55%). Speculative Tesla Terafab talk and ARK trimming. October sales are due about 11-10. **c1–c3 NO.**
- **UBER** 66.60 (−0.16%). Q3 is due **Wed 2026-11-04 before the open** and has not occurred. UBS cut its target to $106. **NO.**

Price-level criteria: none of these verdicts tests a price level, so the dividend-netting view was not needed (it is unreadable this run anyway).

Watchlist candidates: no existing B-index name's candidacy changes beyond the 49 adds below.

## ANALYSIS — OPPORTUNITY CHECK

- **A, D and E are GATED** under the ROUTER-GATED SCAN RULE (state carried forward), so nothing was evaluated for them.
- **B is GATED.** Its 49 ≥5% own-event names still reach the new-entry index as `watchlist` actions (item 3). There is no deal-pinned target, and no thesis handoff is routed.
- **C, HYBRID (FOMC-only carve-out).** No new FOMC-class candidate. The RBA hike is not in C's carve-out class, and the December 8–9 FOMC is already inside the 45-day window.

## ANALYSIS — ADD-CANDIDATE CHECK

- **Durable row:** DEFERRED, at `ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/add_candidate_review/`. 12 evaluated, **0 flagged, 12 `declined_hard_gate`**.
- **Gate.** `invalidation_status` lives in `state.current_positions`, which was unreadable. So the HARD GATE cannot affirmatively confirm "unbreached" for any tranche, and it fails closed, as on 2026-09-21. `invalidation_criteria_evaluable = FALSE` on all 12.

| Tranche | Close 11-03 | Tranche cost | Mark vs cost | Trigger | Disposition |
|---|---|---|---|---|---|
| D:AMZN:2026-07-09 | 250.69 | 241.2441 | +3.92% | none | declined_hard_gate |
| D:AMZN:2026-07-30 | 250.69 | 265.693 | −5.65% | none | declined_hard_gate |
| D:DIS:2026-05-07 | 114.18 | 111.319 | +2.57% | none | declined_hard_gate |
| D:DIS:2026-08-05 | 114.18 | 103.7854 | +10.02% | none | declined_hard_gate |
| D:GEV:2026-08-03 | 918.20 | 969.9058 | −5.33% | none | declined_hard_gate |
| D:GOOGL:2026-07-09 | 280.03 | 359.8484 | −22.18% | dip-with-intact-thesis | declined_hard_gate |
| D:GOOGL:2026-07-26 | 280.03 | 327.8435 | −14.58% | dip-with-intact-thesis | declined_hard_gate |
| D:ISRG:2026-07-20 | 440.75 | 349.5106 | +26.10% | none | declined_hard_gate |
| D:RTX:2026-04-27 | 203.82 | 176.8988 | +15.22% | none | declined_hard_gate |
| D:TSM:2026-07-21 | 404.80 | 427.8613 | −5.39% | dip-with-intact-thesis | declined_hard_gate |
| D:TSM:2026-07-29 | 404.80 | 392.883 | +3.03% | dip-with-intact-thesis | declined_hard_gate |
| D:UBER:2026-07-09 | 66.60 | 73.2073 | −9.03% | none | declined_hard_gate |

- **Price basis.** The numerator is the IBKR 11-03 regular-session close. Tranche costs are carried from yesterday's reconciled table, because `state.current_positions` was unreadable.
- **The dip rule.** A dip needs the 11-03 close at least 5% below the 10-28 close with no invalidation news:
  - GOOGL −13.81% and TSM −7.90% qualify.
  - GEV's 11-02 dip cleared after its +6.49% session.
- D is `DO-NOT-ACTIVATE` and capital-disabled, so no funding path exists in any case.

## ANALYSIS — REGIME CHECK

**No router review.** The standing regime, carried forward, is `shock_overlay = acute` (Gulf/Hormuz structure, price leg ELEVATED).

**Qualifying shock event: no flag needed.**
- The limited US strike on Iranian SAM sites (Qeshm, Hengam, Bandar Abbas; 11-02 evening ET to 11-03) is a dated kinetic event on the Gulf/Hormuz channel.
- The overlay already reads `acute`, so it is inside the standing grade: the rubric escalates no further.
- Its effect on a plateau re-base is for M1a and M1R to read. Oil did not spike: BZUSD −0.39%.

**Qualifying resolution event: NO.**
- No ceasefire or settlement is in force. The US naval blockade continues, and Hormuz is not reopened.
- Iran conditions any reopening on 7 unmet demands, and the reported draft MOU was denied by IRIB.
- That is narrative at most. The two-session window for 11-02's −8% oil move closed today at −0.39% further, but the event itself does not qualify.

The measured technical triggers are D2's to detect. They also depend on this run's deferred breadth row: 61.63, down 1.78pp, not a >10pp month-over-month move on its own.

## EQUITY-BREADTH OBSERVATION

**Row DEFERRED** (BigQuery down): `events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT` = **61.63** for as_of_date **2026-11-03**. The ready SQL is at `ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/breadth_regime_event.sql`.
- **Source.** Barchart `$S5TH`, via `tavily_extract` (advanced, `?cb=20261103`), fetched about 22:07Z. The page reads "Quote Overview for Tue, Nov 3rd, 2026", stamped 16:52 ET (settled).
  - Previous Close 63.41 matches the stored 11-02 value exactly.
  - O 62.02, H 63.81, L 61.63: not a carry and not an exact repeat. Low = Close is a genuine close at the low, given the post-close stamp.
- **Corroboration.** EODData read 61.82 but with a 15:15 ET quote stamp, so it is unsettled and not counted (`unsettled_at_fetch=15:15 ET`). Barchart and EODData count as one feed anyway, so this is a **single settled source**. MacroMicro was not probed (Tuesday; the probe rides on Sunday).
- **ChartRow lags one session.** It reads 313 of 496 (63%) as of 11-02, read twice including the final late re-read at about 22:09Z.
  - Recorded: `chartrow_unconfirmed=lag session 2026-11-02`, plus `chartrow_lagged_dod_gap=0.03 for 2026-11-02` (ChartRow +3.94pp against `$S5TH` +3.97pp for 10-30 → 11-02).
  - That is a plain one-session lag on a non-repeat row, so it is not an in-run issue.

## RECOMMENDED ACTIONS

- Watchlist: ADD GPK to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +21.22% (9.33 → 11.31), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD XMTR to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +16.55% (95.49 → 111.29), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD BETA to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +16.00% (20.38 → 23.64), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD FN to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, +15.45% (314.7 → 363.33), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-02.
- Watchlist: ADD DT to the Strategy B new-entry index — Q3 earnings plus new $1B buyback authorization, pre-open release; reaction session 11-03, -14.69% (55.13 → 47.03), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD ADEA to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, -13.59% (20.67 → 17.86), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-02.
- Watchlist: ADD NBIX to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, +13.42% (145.35 → 164.85); qualifying_event_date 2026-11-02.
- Watchlist: ADD IT to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -13.19% (235.26 → 204.22), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD CVI to the Strategy B new-entry index — Q3 earnings plus a $4.2B cash acquisition of Marathon Petroleum refinery assets (CVI is the acquirer), pre-open release; reaction session 11-03, -13.09% (55.92 → 48.6), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD FISV to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +12.46% (51.93 → 58.4), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD PTCT to the Strategy B new-entry index — $500M share repurchase authorization (Q3 earnings were 10-29), pre-open release; reaction session 11-03, +11.89% (60.88 → 68.12), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD RRX to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +11.81% (160.93 → 179.93), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD PAY to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, -11.50% (35.05 → 31.02), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-02.
- Watchlist: ADD DRVN to the Strategy B new-entry index — Q3 earnings plus Item 4.02 non-reliance on prior financials, pre-open release; reaction session 11-03, -11.24% (12.72 → 11.29), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD LSCC to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, +10.98% (95.44 → 105.92), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-02.
- Watchlist: ADD LIND to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -10.64% (36.66 → 32.76); qualifying_event_date 2026-11-03.
- Watchlist: ADD TBBB to the Strategy B new-entry index — Q3 earnings (6-K), after-close release; reaction session 11-03, +10.53% (56.97 → 62.97); qualifying_event_date 2026-11-02.
- Watchlist: ADD SRAD to the Strategy B new-entry index — Q3 earnings (6-K), pre-open release; reaction session 11-03, +10.33% (12.87 → 14.2), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD TRI to the Strategy B new-entry index — Q3 earnings (6-K), pre-open release; reaction session 11-03, -9.87% (122.24 → 110.18), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD SHC to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -9.64% (17.74 → 16.03); qualifying_event_date 2026-11-03.
- Watchlist: ADD AEIS to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, +9.63% (217.19 → 238.1), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-02.
- Watchlist: ADD SYY to the Strategy B new-entry index — Q3 earnings plus CFO appointment, pre-open release; reaction session 11-03, -9.33% (81.74 → 74.11); qualifying_event_date 2026-11-03.
- Watchlist: ADD GRAB to the Strategy B new-entry index — Q3 earnings (6-K), pre-open release; reaction session 11-03, +9.09% (2.86 → 3.12), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD OTTR to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -8.85% (91.51 → 83.41); qualifying_event_date 2026-11-03.
- Watchlist: ADD ZBRA to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -8.76% (361.13 → 329.5); qualifying_event_date 2026-11-03.
- Watchlist: ADD SHOP to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -8.74% (156.22 → 142.57), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD DD to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +8.61% (141.3 → 153.46); qualifying_event_date 2026-11-03.
- Watchlist: ADD MTCH to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, -8.49% (42.07 → 38.5); qualifying_event_date 2026-11-02.
- Watchlist: ADD MDGL to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -8.08% (431.15 → 396.32); qualifying_event_date 2026-11-03.
- Watchlist: ADD CALX to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, -7.97% (36.13 → 33.25); qualifying_event_date 2026-11-02.
- Watchlist: ADD RVTY to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +7.84% (151.6 → 163.48), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD RYTM to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -7.49% (93.44 → 86.44); qualifying_event_date 2026-11-03.
- Watchlist: ADD TLN to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +7.29% (332.99 → 357.28), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD HGTY to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +7.17% (15.89 → 17.03); qualifying_event_date 2026-11-03.
- Watchlist: ADD BALL to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -7.14% (68.07 → 63.21); qualifying_event_date 2026-11-03.
- Watchlist: ADD JAZZ to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, +7.13% (214.44 → 229.74); qualifying_event_date 2026-11-02.
- Watchlist: ADD ETN to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +7.00% (366.07 → 391.7), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD ULS to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +7.00% (75.14 → 80.4); qualifying_event_date 2026-11-03.
- Watchlist: ADD ADM to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -6.82% (75.77 → 70.6); qualifying_event_date 2026-11-03.
- Watchlist: ADD MSA to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, -6.64% (186.44 → 174.06); qualifying_event_date 2026-11-02.
- Watchlist: ADD LDOS to the Strategy B new-entry index — Q3 earnings (8-K accepted 2026-11-02 22:38Z), after-close release; reaction session 11-03, -6.55% (144.16 → 134.72); qualifying_event_date 2026-11-02.
- Watchlist: ADD APTV to the Strategy B new-entry index — Q3 earnings (post-spin Aptiv), pre-open release; reaction session 11-03, -6.53% (44.23 → 41.34); qualifying_event_date 2026-11-03.
- Watchlist: ADD NPO to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, +6.06% (268.98 → 285.27), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD KDP to the Strategy B new-entry index — Q3 earnings, pre-open release; reaction session 11-03, -5.65% (36.82 → 34.74); qualifying_event_date 2026-11-03.
- Watchlist: ADD LBTYK to the Strategy B new-entry index — Q3 earnings (8-K 2.02/7.01), pre-open release; reaction session 11-03, +5.51% (7.99 → 8.43); qualifying_event_date 2026-11-03.
- Watchlist: ADD KMX to the Strategy B new-entry index — Strategic Update investor event at 8:00 ET (8-K Item 7.01), pre-open release; reaction session 11-03, -5.39% (56.42 → 53.38); qualifying_event_date 2026-11-03.
- Watchlist: ADD RIG to the Strategy B new-entry index — Q3 earnings plus fleet status report, after-close release; reaction session 11-03, -5.30% (6.23 → 5.9), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-02.
- Watchlist: ADD ALSN to the Strategy B new-entry index — Q3 earnings, after-close release; reaction session 11-03, +5.16% (113.09 → 118.92); qualifying_event_date 2026-11-02.
- Watchlist: ADD CE to the Strategy B new-entry index — Q3 earnings (8-K 2.02 plus Item 7.01 webcast notice), after-close release; reaction session 11-03, +5.05% (47.94 → 50.36); qualifying_event_date 2026-11-02.

```yaml d1_actions
- action: watchlist
  ticker: GPK
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +21.22% (9.33 -> 11.31), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: XMTR
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +16.55% (95.49 -> 111.29), 3 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: BETA
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +16.00% (20.38 -> 23.64), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: FN
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, +15.45% (314.7 -> 363.33), 5 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: DT
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings plus new $1B buyback authorization pre-open, -14.69% (55.13 -> 47.03), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: ADEA
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, -13.59% (20.67 -> 17.86), 3 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: NBIX
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, +13.42% (145.35 -> 164.85); B GATED, index only
- action: watchlist
  ticker: IT
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -13.19% (235.26 -> 204.22), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: CVI
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings plus a $4.2B cash acquisition of Marathon Petroleum refinery assets (CVI is the acquirer) pre-open, -13.09% (55.92 -> 48.6), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: FISV
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +12.46% (51.93 -> 58.4), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: PTCT
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; $500M share repurchase authorization (Q3 earnings were 10-29) pre-open, +11.89% (60.88 -> 68.12), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: RRX
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +11.81% (160.93 -> 179.93), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: PAY
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, -11.50% (35.05 -> 31.02), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: DRVN
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings plus Item 4.02 non-reliance on prior financials pre-open, -11.24% (12.72 -> 11.29), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: LSCC
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, +10.98% (95.44 -> 105.92), 3 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: LIND
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -10.64% (36.66 -> 32.76); B GATED, index only
- action: watchlist
  ticker: TBBB
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings (6-K) after-close, +10.53% (56.97 -> 62.97); B GATED, index only
- action: watchlist
  ticker: SRAD
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings (6-K) pre-open, +10.33% (12.87 -> 14.2), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: TRI
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings (6-K) pre-open, -9.87% (122.24 -> 110.18), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SHC
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -9.64% (17.74 -> 16.03); B GATED, index only
- action: watchlist
  ticker: AEIS
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, +9.63% (217.19 -> 238.1), 3 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SYY
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings plus CFO appointment pre-open, -9.33% (81.74 -> 74.11); B GATED, index only
- action: watchlist
  ticker: GRAB
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings (6-K) pre-open, +9.09% (2.86 -> 3.12), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: OTTR
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -8.85% (91.51 -> 83.41); B GATED, index only
- action: watchlist
  ticker: ZBRA
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -8.76% (361.13 -> 329.5); B GATED, index only
- action: watchlist
  ticker: SHOP
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -8.74% (156.22 -> 142.57), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: DD
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +8.61% (141.3 -> 153.46); B GATED, index only
- action: watchlist
  ticker: MTCH
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, -8.49% (42.07 -> 38.5); B GATED, index only
- action: watchlist
  ticker: MDGL
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -8.08% (431.15 -> 396.32); B GATED, index only
- action: watchlist
  ticker: CALX
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, -7.97% (36.13 -> 33.25); B GATED, index only
- action: watchlist
  ticker: RVTY
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +7.84% (151.6 -> 163.48), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: RYTM
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -7.49% (93.44 -> 86.44); B GATED, index only
- action: watchlist
  ticker: TLN
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +7.29% (332.99 -> 357.28), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: HGTY
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +7.17% (15.89 -> 17.03); B GATED, index only
- action: watchlist
  ticker: BALL
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -7.14% (68.07 -> 63.21); B GATED, index only
- action: watchlist
  ticker: JAZZ
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, +7.13% (214.44 -> 229.74); B GATED, index only
- action: watchlist
  ticker: ETN
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +7.00% (366.07 -> 391.7), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: ULS
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +7.00% (75.14 -> 80.4); B GATED, index only
- action: watchlist
  ticker: ADM
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -6.82% (75.77 -> 70.6); B GATED, index only
- action: watchlist
  ticker: MSA
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, -6.64% (186.44 -> 174.06); B GATED, index only
- action: watchlist
  ticker: LDOS
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings (8-K accepted 2026-11-02 22:38Z) after-close, -6.55% (144.16 -> 134.72); B GATED, index only
- action: watchlist
  ticker: APTV
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings (post-spin Aptiv) pre-open, -6.53% (44.23 -> 41.34); B GATED, index only
- action: watchlist
  ticker: NPO
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, +6.06% (268.98 -> 285.27), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: KDP
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings pre-open, -5.65% (36.82 -> 34.74); B GATED, index only
- action: watchlist
  ticker: LBTYK
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings (8-K 2.02/7.01) pre-open, +5.51% (7.99 -> 8.43); B GATED, index only
- action: watchlist
  ticker: KMX
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Strategic Update investor event at 8:00 ET (8-K Item 7.01) pre-open, -5.39% (56.42 -> 53.38); B GATED, index only
- action: watchlist
  ticker: RIG
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings plus fleet status report after-close, -5.30% (6.23 -> 5.9), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: ALSN
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings after-close, +5.16% (113.09 -> 118.92); B GATED, index only
- action: watchlist
  ticker: CE
  strategy: B
  qualifying_event_date: 2026-11-02
  source_research_screen_id: DEFERRED (BigQuery down; ops/spikes/bigquery-deauth-2026-11-03-d1-deferred/single_name_screen)
  detail: ADD to B new-entry index; Q3 earnings (8-K 2.02 plus Item 7.01 webcast notice) after-close, +5.05% (47.94 -> 50.36); B GATED, index only
```
