2026-11-17
<!-- d1_scan_through_utc: 2026-11-17T22:25:19Z -->

# Daily Market Development Scan — session 2026-11-17 (Tue), run 2026-11-17

Scan window: 2026-11-16 15:20 MT → 2026-11-17 15:25 MT (~24 hours). The start is the prior `Daily.md` marker `2026-11-16T22:20:52Z`; git agrees (last Daily.md commit 2026-11-16T22:23:58Z). This covers the Tuesday 11-17 session plus Monday-evening news.

SCAN MODE: ROUTER-GATED for A (DO-NOT-ACTIVATE) and D (DO-NOT-ACTIVATE), read live from `state.current_regime`. B reads ACTIVATE (since 2026-11-09), so the single-name screen runs in FULL mode. The newest earlier screen row was already FULL, so there is no gated re-check. E reads ACTIVATE. C is `HYBRID ACTIVATE (FOMC-only)`, so only its carve-out class is evaluated.

- **Indices (IBKR closes 11-16 → 11-17).** SPY 739.95 → 732.44 (−1.01%). SPX 7,340.63 (−1.02%; IBKR delayed index bar), lowest close since late July (CNBC). Dow −1.64% to 50,759 (CNBC). QQQ −0.73%, IWM −1.43%, SMH −0.39%. Software was routed: CRM −9.4%, INTU −7.2%, NOW −6.6%, WDAY −5.8%; IGV about −3.4% (Benzinga).
- **Volatility.** VIX 22.91 → **25.46** (IBKR CBOE index bar, delayed). That is above the 25 NORMAL/HIGH line; D2a's mechanical `VIX_REGIME` step classifies it, and D2 item 4 owns any measured refresh trigger.
- **Rates and dollar.** The 10-year was about 5.09–5.10% and the 2-year about 4.79% (Benzinga, Barchart $TNX 5.10). DXY was about 103.6, the highest since early 2025. CME FedWatch prices a December 9 hike at about 91–100%. Musalem said "several" hikes are likely needed by spring.
- **Oil.** Brent (BZUSD, provisional same-evening read) **93.01 on 2026-11-17**, against 92.44 on 2026-11-16 in the same FMP series (+0.57). The 11-16 figure was restated from the 91.81 read last evening. Reuters reports the Brent January settle at $93.14 (+0.76%) and WTI at $86.01; the IEA sees a Q4 surplus of about 1.7 mb/d.
- **Breadth.** **56.06** for 11-17 (Barchart `$S5TH`, stamped 16:56 ET, single usable source), against 59.84 stored for 11-16. See EQUITY-BREADTH OBSERVATION.
- **Crypto.** Bitcoin about $64.6–65.0K, −13% on the week; spot ETF outflows about $1.07B for a second week (CoinDesk).

## TL;DR

- **Exits triggered: none.** No tranche reaches a convergence target or time exit, kill flags are all FALSE, and no in-window development meets an invalidation criterion. Rockwell's Investor Day runs 11-17/18; its guidance has not been published in the window.
- **New entry candidates: none routed as thesis handoffs.** 8 names passed the FULL-mode Strategy B screen and go to the B new-entry index (W2 ranks them): BILL, ACM, RYTM, JD, TME, NKE, ESLT, UNH. 94 other ≥5% movers were rejected, mostly software, crypto and solar beta. Discovery ran in full this run (2,088 names ≥$2B measured).
- **Add candidates: none (0 of 26).** The 14 B tranches are two sessions old and their losses are tape beta. D adds are declined because D is DO-NOT-ACTIVATE.
- **Watchlist: 8 changes.** ADD BILL, ACM, RYTM, JD, TME, NKE, ESLT and UNH to the Strategy B new-entry index.
- **Regime review: one PENDING flag.** Gulf-channel attacks of 11-16 evening and 11-17 (the LPG tanker Tara Gas hit twice near Khasab, a further Riffa drone attempt) are dated events while `shock_overlay` reads latent. S1 (11-17) closed with Brent up 0.57, so the window is incomplete. The 11-15/11-16 flag's window has now closed at −2.83 (not met). No resolution event.

Park: VOO-only pin verified

Paper book (J): 120 calls, 377/30 realized, net_mu -0.73%, ready=FALSE

## DEVELOPMENTS

### 1. Market-wide breaking events

**Software sell-off on the Anthropic IPO launch (Tue 11-17).**
- Anthropic launched an offering of 825M shares at $70–78 (up to $64.4B). It is expected to price on Wed 11-18 and trade on Nasdaq on Thu 11-19 as "ANT" (Benzinga, TradingEconomics; not seen at a primary filing).
- Seat-based software sold on capital-drain and AI-agent displacement worries. IBKR bars: CRM −9.41%, INTU −7.17%, NOW −6.55%, HUBS −6.71%, MNDY −6.93%, ZETA −6.47%, FIG −6.39%, ESTC −6.27%, GWRE −6.19%, TEAM −5.98%, GTLB −5.81%, WDAY −5.80%, MDB −5.77%. No guidance cut or downgrade was found as the trigger.
- The Monday 11-16 BIS interim final rule on licensing advanced AI chips shipped via five intermediary countries still weighed on tech (UOB research note).

**Nvidia Q3 FY27 (after the close, ~16:20 ET; GlobeNewswire copy of the NVIDIA release).**
- Revenue $115.84B vs about $109.1B consensus; Data Center $107.6B; non-GAAP EPS $2.68 vs $2.48.
- Q4 guide $130.0B ±3% (includes an extra week, no China data-center compute) vs about $125B; gross margin 71–72%.
- The stock closed $155.46 (−0.44% on Nasdaq's closing print) and traded up to about +4% after hours.
- Leadership: Huang resigned on 11-12 and Kress is interim CEO. Huang said on 11-17 he would return if asked; the board is reportedly not considering it (secondary sources, not verified at a primary source).

**Crypto.** Bitcoin about $64.6–65.0K after a weekend low near $62.6K. On IBKR bars: MSTR −6.34%, CRCL −5.24%, FUTU −5.14%, AFRM −5.21%. MSCI is to drop Strategy (MSTR) from its indexes after 11-30.

**Iran / Hormuz / Gulf (channel: US blockade of Iranian ports plus Iran's restriction of Hormuz).** No ceasefire, settlement or blockade lift is in force.
- 11-16 ~19:00 UTC: the Panama-flag LPG tanker Tara Gas was hit by a projectile near Khasab, and hit again on 11-17. The crew of 25 was evacuated; one Indian seafarer is missing (Gulf News, UKMTO).
- The IRGC claims six tankers have hit mines or sunk since 11-15 (unverified). Iran's army says another tanker hit a mine on 11-17.
- Iranian drones targeted a US radar at Bahrain's Riffa air base for the third time in under a week; Bahrain says all were intercepted. Mehr reports US strikes on Qeshm Island (unverified).
- Talk only: Araghchi met Oman's foreign minister in Muscat on 11-17 ("constructive", no agreement). An Iran–Oman Hormuz navigation framework awaits ratification. Araghchi's "two-day plan" to reopen Hormuz is conditional on US concessions.

**Managed care.** UNH −5.42%, MOH −5.05% on IBKR bars, with HUM and CVS lower, on a Medicare Advantage audit framework (CRUSH) and insurer break-up headlines (news reports; no primary agency notice seen).

### 2. Scheduled events that resolved in the window

Enumerated from the key-less Nasdaq earnings calendar for 2026-11-17 (46 rows, 18 at ≥$2B). Each outcome below is from the issuer release or a copy of it, dated inside the window.

- **Home Depot (HD)**, Q3 FY2026 (ended 11-01), pre-open (ir.homedepot.com). Sales $43.40B (+4.9%); comps +2.2%; adjusted EPS $3.86 vs $3.84. FY26 guide: comps about +1.4%, adjusted EPS growth about 2% (about $14.98 vs $15.01 consensus). CFO Richard McPhail becomes CEO on 11-23.
- **Disney (DIS)**, Q4 FY2026 (ended 10-03, 53-week year), ~06:30 ET (shareholder letter, Exhibit 99.1). Revenue $25.95B (+16%); adjusted EPS $1.77 vs about $1.68. FY27: double-digit adjusted EPS growth ex the 53rd week; dividend raised 33% to $2.00. IBKR close 116.94 (−1.48%).
- **Nvidia (NVDA)**: see section 1.
- **JD.com (JD)**, Q3, pre-open ~04:37 ET (6-K). Revenue RMB309.6B (+3.5%); non-GAAP EPS/ADS $0.88 vs $0.93–0.98. IBKR −7.66%.
- **Tencent Music (TME)**, Q3, pre-open ~04:09 ET (6-K). Revenue RMB8.94B (+5.6%) missed; non-IFRS EPS/ADS RMB1.55; ~$300M buyback. IBKR +6.64%.
- **Elbit Systems (ESLT)**, Q3, pre-open (6-K 06:24 ET). Non-GAAP EPS $4.36 vs $3.85; backlog $33B. IBKR +5.85%.
- **Amer Sports (AS)**, Q3: revenue $2.17B (+24%) vs $2.14B; adjusted EPS $0.42 vs $0.35; FY26 guide raised; $1B buyback. Reported up about 7.6% intraday (not on the ≥$2B ≥5% IBKR list at the close).
- **MINISO (MNSO)**, Q3: nine-month revenue +19.3%, buyback above RMB1B. IBKR +8.41% (ADR below $10B, so not B-eligible).
- **Klarna (KLAR)**, Q3: GMV $36.1B (+10%), revenue $1.0B (+12%).
- **Pending after the close (not resolved in this window's sources):** ZTO, SQM, DLB, CAAP, GBDC. VIK, SR, GFF and BHP outcomes were not found.
- **AECOM (ACM)**, FQ4, after the close on 11-16 (~16:05 ET, issuer release): adjusted EPS $1.63 vs $1.59, record $28B backlog, FY27 guide $6.15–6.35. IBKR +11.08% on 11-17.
- **FDA.** 11-17 accelerated approval of neladalkib (Nuvalent) for previously treated ALK+ NSCLC, on the FDA oncology approvals page. No 11-17 CRL found.

### 3. Large single-name moves — AI-significance screen, FULL mode (B ACTIVATE)

**Discovery ran in full this run.** The key-less Nasdaq screener gave 2,099 symbols at ≥$2B. Their 11-17 closing prints (Nasdaq `quote/info`, "Closed at Nov 17, 2026 4:00 PM ET") were measured against their 11-16 historical closes: 2,088 measured, 688 moved ≥2%, 104 moved ≥5%. The historical table had no 11-17 row at D1 time, which is the documented lag.

All 103 common-equity ≥5% names were re-measured on IBKR regular-session daily bars, in four sequential batches with none unresolved. SENEA's −79% was a 5-for-1 split artifact (IBKR +3.79%), so it is not written up. Events were attributed by one Parallel leg (17 searches) and a scripted EDGAR submissions batch. 2–5% movers were not individually attributed.

**Passed (8), each to the Strategy B new-entry index:**

- BILL — FT reported TPG is close to a take-private at a premium (unsigned, no price; not deal-pinned); intraday 2026-11-17 ~11:43 ET (news report); reaction session 2026-11-17, +12.58% (57.63 -> 64.88), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-17.
- ACM — FQ4/FY26 beat (adj EPS $1.63 vs $1.59), record $28B backlog, FY27 guide $6.15-6.35, dividend +10%; after-close release 2026-11-16 ~16:05 ET, anchor 2026-11-16; reaction session 2026-11-17, +11.08% (72.5 -> 80.53), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-16.
- RYTM — two-year Phase 3 TRANSCEND extension data (BMI -18.8%); after-close release 2026-11-16 16:00 ET (GlobeNewswire), anchor 2026-11-16; reaction session 2026-11-17, +8.49% (107.48 -> 116.61), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-16.
- JD — Q3 non-GAAP EPS/ADS $0.88 vs $0.93-0.98 consensus (ADR, ~$37B cap); pre-open release 2026-11-17 ~04:37 ET; reaction session 2026-11-17, -7.66% (27.54 -> 25.43); qualifying_event_date 2026-11-17.
- TME — Q3 revenue miss, non-IFRS EPS beat, ~$300M buyback (ADR, ~$14B cap); pre-open release 2026-11-17 ~04:09 ET; reaction session 2026-11-17, +6.64% (8.88 -> 9.47); qualifying_event_date 2026-11-17.
- NKE — Investor Day: FY27 revenue down high-single digits, growth only from FY29; reversed from +6% pre-open; 8-K Item 7.01 accepted 2026-11-17 09:01 ET; reaction session 2026-11-17, -6.30% (38.26 -> 35.85), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-17.
- ESLT — Q3 non-GAAP EPS $4.36 vs $3.85, backlog $33B; pre-open 6-K 2026-11-17 06:24 ET; reaction session 2026-11-17, +5.85% (680.74 -> 720.53), with 3 prior >=5% sessions in the window; qualifying_event_date 2026-11-17.
- UNH — managed-care sell-off on a Medicare Advantage audit framework (CRUSH) and insurer break-up headlines; intraday 2026-11-17 (news reports; no primary agency timestamp); reaction session 2026-11-17, -5.42% (412.02 -> 389.68); qualifying_event_date 2026-11-17.

**Rejected (94)**, all recorded in full in the `research-screen` row:
- 44 sector beta: software (CRM, NOW, INTU, WDAY, TEAM, HUBS, MDB and 21 more), crypto/quantum/eVTOL/space (MSTR, CRCL, FUTU, AFRM, IONQ, QBTS, RGTI, JOBY, ACHR, LUNR and others), solar (ENPH, FSLR, RUN), towers (SBAC, CCI) and MOH.
- 38 with no identified event, among them SNAP +7.95%, UNFI +7.58%, SA +7.39%, LUMN +6.70%, TWST +6.63%, IEP −11.39%, WCN −8.05%, RH −8.28%, IDYA −9.75%.
- 2 chain-carried: SMMT −9.73% and CGON −6.89% chain to yesterday's passed items on the same anchors (11-15 CRL; 11-16 PIVOT-006), and that disposition is carried forward.
- MNSO (ADR below $10B); LMND (analyst downgrade only); NXT, GPN, WU and HZN (event unverified or follow-through); REGCO (a preferred).
- No deal-pinned target. BILL's FT report is unsigned with no price, so it is judged on its merits.

### 4. Sector-level moves (IBKR regular-session closes 11-16 → 11-17)

Every sector fell. Seven cleared the 1% rail; none reached the old 2% bar.
- **XLF −1.91% (passed, 45):** crypto-linked, payments and data names led (MSTR, CRCL, AFRM, GPN, FICO, TRU, FUTU, DB), with bitcoin near $65K and the software rout spreading to fintech multiples.
- **XLK −0.91% (passed as dispersion, 60):** seat-based software was routed on the Anthropic IPO launch while semis held (SMH −0.39%) into Nvidia's beat.
- Rejected as risk-off beta (30): XLU −1.59%, XLRE −1.49%, XLC −1.46%, XLV −1.41% (managed care weak), XLP −1.23%, XLB −1.22%.
- Not on the rail: XLY −0.89%, XLI −0.55%, XLE −0.52%.

### 5. Notable commentary

- **Fed.** Musalem (non-voter) said "several" hikes are likely needed by spring (Bloomberg). Hammack favours gradual hikes. Chair Warsh opened a San Francisco Fed conference on AI and productivity with no rate guidance. FOMC minutes are Wed 11-18 at 14:00 ET.
- **ECB.** Nagel (11-13) said further tightening is "highly probable". Lagarde speaks on 11-18.
- **Sell-side.** No notable report was verified for 11-17. Wintermute warned that bitcoin could slide into the $50Ks after losing its 200-week average.

## ANALYSIS — RISK TO EXISTING POSITIONS

**Mechanical sweep (union of `state.current_positions` and IBKR `get_account_positions`).** 26 strategy tranches plus the VOO park; every connector position is in `state.current_positions`, so there is no reconciliation lag. Closes are IBKR 11-17 regular-session bars.

| Tranche | Close | Convergence target | Time exit | Triggered? |
|---|---|---|---|---|
| B:ANDE | 52.02 | 61.50 | 2027-01-15 | No |
| B:ARQT | 27.33 | 32.00 | 2027-01-15 | No |
| B:DDOG | 165.18 | 202.00 | 2027-01-15 | No |
| B:ECG | 85.55 | 103.00 | 2027-01-15 | No |
| B:EXPE | 243.16 | 290.00 | 2027-01-15 | No |
| B:IRTC | 89.67 | 111.00 | 2027-01-15 | No |
| B:MCY | 84.00 | 96.00 | 2027-01-15 | No |
| B:MTRN | 196.56 | 225.00 | 2027-01-15 | No |
| B:NRIX | 14.24 | 19.50 | 2027-01-15 | No |
| B:RELY | 20.53 | 24.50 | 2027-01-15 | No |
| B:ROK | 391.26 | 430.00 | 2027-01-15 | No |
| B:RVMD | 162.69 | 188.00 | 2027-01-15 | No |
| B:SM | 30.43 | 35.50 | 2027-01-15 | No |
| B:SYY | 77.99 | 81.00 | 2027-01-15 | No |
| D (12 tranches: AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER) | — | none | none | No |

**Kill-trigger sweep (`perf.kill_flags`, as of 11-16, refreshed against 11-17 closes).**
- B: drawdown −5.31% at the 11-16 engine row. The 11-17 move of the B book was about −1.7% (summed daily P&L about −$60 on about $3.56K), so about −7%. Far from the 50% kill. No runaway, no evidence kill, no interim warning.
- D: drawdown −9.08%, roughly −9.5% after 11-17. No flags.
- `analytics.b_pairwise_correlation`: 14 positions, average correlation NULL (no pair has ≥40 overlap days yet), so no warning.

**Judgment invalidation sweep.** No development meets a criterion.
- **DDOG −4.44%:** the software rout is a sector move. There is no AI-customer termination, peer slowdown or guidance cut, so criteria 1–3 are not met.
- **RELY −6.38%:** no company event found. Criterion 1 needs a broker PT cut >15% or a downgrade; none was found. Criteria 2–4 are not met.
- **EXPE −3.77%:** no peer guidance cut. The Gulf events extend a standing structure, with Brent 93 and no airspace closure or travel advisory reported, so criterion 2 is not met.
- **ROK +1.65%:** criterion 1 is tested at or after its 11-17/18 Investor Day. No FY27 guidance was published in this window; re-check on the next run.
- **ANDE, NRIX, SM, RVMD, MCY:** declines are beta with no company news.
- **D:DIS:** the FY26 Q4 beat and FY27 guide reinforce the thesis.
- **D:TSM, D:GOOGL, D:GEV:** no development meets a criterion.

**Watchlist candidates.** No in-window development invalidates or advances a queued name beyond the screen items above.

## ANALYSIS — OPPORTUNITY CHECK

Reactive-cadence set: B, C (carve-out only), E. A and D are gated and not evaluated.
- **B:** 8 ≥5% screen passes go to the new-entry index as `watchlist` actions (below). W2 ranks them; D1 makes no thesis handoff.
- **C (FOMC-only carve-out):** no new FOMC-class catalyst; the next meeting is 12-09, already known.
- **E:** software vs semis diverged sharply (IGV about −3.4% vs SMH −0.39%; CRM −9.4% vs NVDA flat). That is a theme-level split, not a confirmed intra-industry-group pair with the correlation and hedge-ratio evidence E requires, so it is left to M2's screen. No E candidate is raised.

## ANALYSIS — ADD-CANDIDATE CHECK

26 tranches evaluated (14 B, 12 D, no A): 0 flagged, 26 declined, 0 at the hard gate. All are `invalidation_criteria_evaluable = TRUE`.
- **B tranches:** two sessions after the 11-16 entry, with losses vs cost of RELY −8.26%, DDOG −9.56%, NRIX −7.35%, ANDE −6.13% and SM −6.12%. These are risk-off and software beta with no new thesis information, so no dip-with-intact-thesis or strengthened-conviction case is made yet.
- **D tranches:** criteria unbreached, but D reads DO-NOT-ACTIVATE (div-D-202611-1).

Recorded in `events.decision_log` `add-candidate-review` 21fba791-cb6b-40ba-aab7-43e10a741ca8.

## ANALYSIS — REGIME CHECK

**One PENDING geopolitical flag, no resolution flag.**
- `shock_overlay` reads latent; the Gulf/Hormuz structure is open.
- The 11-16 evening / 11-17 attacks are dated events on the named channel: Tara Gas hit twice near Khasab with a seafarer missing; a further tanker mine strike claimed by Iran's army; a third Riffa drone attempt; reported US strikes on Qeshm.
- Two-session window: P 92.44 (BZUSD 11-16), S1 93.01 on 11-17 (+0.57, not met), S2 11-18 open. Flagged PENDING for D2 and M1R.
- The 11-15/11-16 flag carried yesterday now has a closed window: P 95.84 (11-13), S1 92.44 (11-16), S2 93.01 (11-17), so −2.83 at S2. That does not meet an upward oil criterion; M1R rules.
- No qualifying resolution event: the Muscat talks produced no agreement, and nothing is in force.

**Measured triggers (for D2 item 4, not computed here):**
- VIX closed 25.46 on IBKR's CBOE bar, above the 25 HIGH line.
- Breadth is down to 56.06.

## EQUITY-BREADTH OBSERVATION

- **Value written:** **56.06** for 2026-11-17 (`events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT`).
- **Source:** Barchart `$S5TH` via Parallel `web_fetch`: "56.06 −3.78 (−6.32%) 16:56 ET", "Quote Overview for Tue, Nov 17th, 2026", Previous Close 59.84 (equal to the stored 11-16 value). It is settled, with on-page time ≥16:00 ET. This is a single usable source.
- **ChartRow cross-check:** its 200-day card still reads 297 of 497 (59.76%) as of Nov 16, so `chartrow_unconfirmed=lag session 2026-11-16`.
- **Lagged check of the prior row:** ChartRow 11-13 → 11-16 −4.02pp vs stored −3.97pp, so `chartrow_lagged_dod_gap=0.05`. Consistent.
- No MacroMicro re-probe (Tuesday).

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

NO CAPTURE. The Tuesday battery (prompt injection) search returned only older or catalogued papers. The date-ordered `hf://papers/daily/latest` listing for 11-17 was read. Its in-window items (11-16/17) include agent-harness work on silent API failures (2611.20595) and open model releases. None materially changes a documented `AI_Trading_Foundation.md` disadvantage, so the default is silent.

## RECOMMENDED ACTIONS

- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): BILL — FT reported TPG is close to a take-private at a premium (unsigned, no price; not deal-pinned); intraday 2026-11-17 ~11:43 ET (news report); reaction session 2026-11-17, +12.58% (57.63 -> 64.88), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-17.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): ACM — FQ4/FY26 beat (adj EPS $1.63 vs $1.59), record $28B backlog, FY27 guide $6.15-6.35, dividend +10%; after-close release 2026-11-16 ~16:05 ET, anchor 2026-11-16; reaction session 2026-11-17, +11.08% (72.5 -> 80.53), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-16.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): RYTM — two-year Phase 3 TRANSCEND extension data (BMI -18.8%); after-close release 2026-11-16 16:00 ET (GlobeNewswire), anchor 2026-11-16; reaction session 2026-11-17, +8.49% (107.48 -> 116.61), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-16.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): JD — Q3 non-GAAP EPS/ADS $0.88 vs $0.93-0.98 consensus (ADR, ~$37B cap); pre-open release 2026-11-17 ~04:37 ET; reaction session 2026-11-17, -7.66% (27.54 -> 25.43); qualifying_event_date 2026-11-17.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): TME — Q3 revenue miss, non-IFRS EPS beat, ~$300M buyback (ADR, ~$14B cap); pre-open release 2026-11-17 ~04:09 ET; reaction session 2026-11-17, +6.64% (8.88 -> 9.47); qualifying_event_date 2026-11-17.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): NKE — Investor Day: FY27 revenue down high-single digits, growth only from FY29; reversed from +6% pre-open; 8-K Item 7.01 accepted 2026-11-17 09:01 ET; reaction session 2026-11-17, -6.30% (38.26 -> 35.85), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-17.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): ESLT — Q3 non-GAAP EPS $4.36 vs $3.85, backlog $33B; pre-open 6-K 2026-11-17 06:24 ET; reaction session 2026-11-17, +5.85% (680.74 -> 720.53), with 3 prior >=5% sessions in the window; qualifying_event_date 2026-11-17.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): UNH — managed-care sell-off on a Medicare Advantage audit framework (CRUSH) and insurer break-up headlines; intraday 2026-11-17 (news reports; no primary agency timestamp); reaction session 2026-11-17, -5.42% (412.02 -> 389.68); qualifying_event_date 2026-11-17.
- Router review (refresh-only): 2026-11-16 evening / 2026-11-17 Gulf-channel attacks (LPG tanker Tara Gas hit twice near Khasab with one seafarer missing; Iran-army-claimed tanker mine strike; third Riffa drone attempt; Mehr-reported US strikes on Qeshm, unverified) while shock_overlay reads latent; they may meet the Qualifying shock event criterion. Two-session window PENDING: P 92.44 (BZUSD 2026-11-16), S1 93.01 on 2026-11-17 (+0.57, not met), S2 2026-11-18 open. The 11-15/11-16 flag window has closed at P 95.84 / S1 92.44 / S2 93.01 (-2.83, not met) for M1R to rule.

```yaml d1_actions
- action: watchlist
  ticker: BILL
  strategy: B
  qualifying_event_date: 2026-11-17
  source_research_screen_id: 46f9523a-d05a-4a2f-8192-c0fe389c6999
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): BILL — FT reported TPG is close to a take-private at a premium (unsigned, no price; not deal-pinned); intraday 2026-11-17 ~11:43 ET (news report); reaction session 2026-11-17, +12.58% (57.63 -> 64.88), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-17."
- action: watchlist
  ticker: ACM
  strategy: B
  qualifying_event_date: 2026-11-16
  source_research_screen_id: 46f9523a-d05a-4a2f-8192-c0fe389c6999
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): ACM — FQ4/FY26 beat (adj EPS $1.63 vs $1.59), record $28B backlog, FY27 guide $6.15-6.35, dividend +10%; after-close release 2026-11-16 ~16:05 ET, anchor 2026-11-16; reaction session 2026-11-17, +11.08% (72.5 -> 80.53), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-16."
- action: watchlist
  ticker: RYTM
  strategy: B
  qualifying_event_date: 2026-11-16
  source_research_screen_id: 46f9523a-d05a-4a2f-8192-c0fe389c6999
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): RYTM — two-year Phase 3 TRANSCEND extension data (BMI -18.8%); after-close release 2026-11-16 16:00 ET (GlobeNewswire), anchor 2026-11-16; reaction session 2026-11-17, +8.49% (107.48 -> 116.61), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-16."
- action: watchlist
  ticker: JD
  strategy: B
  qualifying_event_date: 2026-11-17
  source_research_screen_id: 46f9523a-d05a-4a2f-8192-c0fe389c6999
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): JD — Q3 non-GAAP EPS/ADS $0.88 vs $0.93-0.98 consensus (ADR, ~$37B cap); pre-open release 2026-11-17 ~04:37 ET; reaction session 2026-11-17, -7.66% (27.54 -> 25.43); qualifying_event_date 2026-11-17."
- action: watchlist
  ticker: TME
  strategy: B
  qualifying_event_date: 2026-11-17
  source_research_screen_id: 46f9523a-d05a-4a2f-8192-c0fe389c6999
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): TME — Q3 revenue miss, non-IFRS EPS beat, ~$300M buyback (ADR, ~$14B cap); pre-open release 2026-11-17 ~04:09 ET; reaction session 2026-11-17, +6.64% (8.88 -> 9.47); qualifying_event_date 2026-11-17."
- action: watchlist
  ticker: NKE
  strategy: B
  qualifying_event_date: 2026-11-17
  source_research_screen_id: 46f9523a-d05a-4a2f-8192-c0fe389c6999
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): NKE — Investor Day: FY27 revenue down high-single digits, growth only from FY29; reversed from +6% pre-open; 8-K Item 7.01 accepted 2026-11-17 09:01 ET; reaction session 2026-11-17, -6.30% (38.26 -> 35.85), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-17."
- action: watchlist
  ticker: ESLT
  strategy: B
  qualifying_event_date: 2026-11-17
  source_research_screen_id: 46f9523a-d05a-4a2f-8192-c0fe389c6999
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): ESLT — Q3 non-GAAP EPS $4.36 vs $3.85, backlog $33B; pre-open 6-K 2026-11-17 06:24 ET; reaction session 2026-11-17, +5.85% (680.74 -> 720.53), with 3 prior >=5% sessions in the window; qualifying_event_date 2026-11-17."
- action: watchlist
  ticker: UNH
  strategy: B
  qualifying_event_date: 2026-11-17
  source_research_screen_id: 46f9523a-d05a-4a2f-8192-c0fe389c6999
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): UNH — managed-care sell-off on a Medicare Advantage audit framework (CRUSH) and insurer break-up headlines; intraday 2026-11-17 (news reports; no primary agency timestamp); reaction session 2026-11-17, -5.42% (412.02 -> 389.68); qualifying_event_date 2026-11-17."
- action: router_review
  ticker: n/a
  strategy: n/a
  qualifying_event_date: n/a
  source_research_screen_id: n/a
  detail: "Refresh-only: 2026-11-16 evening / 2026-11-17 Gulf-channel attacks (LPG tanker Tara Gas hit twice near Khasab with one seafarer missing; Iran-army-claimed tanker mine strike; third Riffa drone attempt; Mehr-reported US strikes on Qeshm, unverified) while shock_overlay reads latent; they may meet the Qualifying shock event criterion. Two-session window PENDING: P 92.44 (BZUSD 2026-11-16), S1 93.01 on 2026-11-17 (+0.57, not met), S2 2026-11-18 open. The 11-15/11-16 flag window has closed at P 95.84 / S1 92.44 / S2 93.01 (-2.83, not met) for M1R to rule."
```
