2026-06-10
<!-- d1_scan_through_utc: 2026-06-10T22:06:26Z -->

# Daily Market Development Scan — 2026-06-10 (Wed, MT)

Scan window: 2026-06-09 16:04 MDT → 2026-06-10 16:06 MDT (~24h). Covers the **Wednesday 6/10 cash session** plus the two catalysts the 6/9 scan flagged as live: the **May CPI print (BMO)** and **Oracle FQ4 earnings (AMC)**. Cast broadly across the US-listed ≥$2B universe, not scoped to held/watchlist names. Live book + marks pulled from the IBKR connector at/just after the close; canonical state read from BigQuery (`state.current_positions`, `state.current_regime`, `perf.kill_flags`).

Open book (connector `get_account_positions`): **ZBRA (B), HCA (B), AZO (B), RTX (D), DIS (D)** + SGOV park (92.30 sh). **⚠ Divergence vs `state.current_positions`: TJX (B) still shows OPEN in BigQuery but the connector shows position 0 — the 6/9-flagged TJX convergence exit (`stage-TJX-exit-20260609`) was crafted by D2, confirmed, and FILLED today.** This is expected and reconciles at today's D2 Step 0 (flip OPEN→CLOSED, mark the queue item complete). No other divergence — AZO/HCA/ZBRA/RTX/DIS share counts match BigQuery exactly.

Regime (`state.current_regime`, M1b 2026-06-01 + divergence reviews 6/3): **A=DO-NOT-ACTIVATE, B=ACTIVATE, C=HYBRID ACTIVATE (FOMC-only), D=ACTIVATE, E=ACTIVATE (execution-feasibility-deferred, ETF-substitution-required at current book size)**. Fundamental axis: stagflation-tilt + risk-on; shock_overlay=latent. Breadth HEALTHY · SPY Trend NEUTRAL · curve NOT-sustained-inverted.

Wednesday tape: **S&P 500 −1.62% → 7,266.99; Dow −1.87% (−953) → 49,918.78; Nasdaq −1.98% → 25,169.50.** A **broad risk-off** — materially different in character from Tuesday's tech-specific de-rate inside positive breadth. Twin drivers: (1) a **hot May CPI** (+4.2% YoY headline, fastest since May 2023; +0.5% MoM) keeping a Fed *hike* in play, and (2) a **third Iran flare** that this time *broadened* (Iran struck multiple Gulf states after US "self-defence" strikes). Industrials led the downside (−3%+), Tech and Materials −2%+; defensives/energy relatively firm. **Notable nuance:** the CPI was hot on the *headline* (energy-driven) but **soft on the core (+0.2% MoM, undershooting)** — so the 10yr yield actually *eased* to ~4.52% (off a 4.55% intraday high) and hike bets were modestly *pared* (Oct hike ~51%; a Dec 25bps remains fully priced). And oil stayed **rangebound** (WTI ~$87–90, Brent ~$90–94) despite the broadened conflict — the supply shock still isn't decisively re-pricing crude. The selloff was thus as much an **AI-capex/financing-digestion + industrial-recession-fear** event (ORCL/SMCI capital-raise shocks; ODFL freight; ZBRA) as a pure inflation/rates shock.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **May CPI — hot headline, soft core, energy-driven.** Headline CPI **+0.5% MoM SA / +4.2% YoY** — the fastest annual pace since May 2023, in line with consensus; **energy was the single biggest contributor**, tied directly to the Iran/Hormuz supply disruption. But **core CPI rose only +0.2% MoM, undershooting forecasts** — i.e. the energy shock has **not yet broadly spilled into underlying prices**. Market read: the 10yr yield *eased* to ~4.52% (from a 4.55% intraday high), the 2yr fell ~2bps to 4.15%, and traders **pared** near-term hike odds (Oct ~51%) while keeping a **Dec 25bps hike fully priced**. Net: confirms the reaccelerating-inflation axis on the headline while the soft core tempers a "broadening" read. (Sources: [Yahoo Finance 6/10](https://finance.yahoo.com/markets/live/stock-market-today-wednesday-june-10-dow-sp-500-nasdaq-may-cpi-report-215056384.html), [TheStreet 6/10](https://www.thestreet.com/stock-market-today/stock-market-today-dow-jones-sp-500-nasdaq-updates-june-10-2026), [TradingEconomics 10yr](https://tradingeconomics.com/united-states/government-bond-yield).)
- **Iran — third flare, broadened in scope; oil still capped.** After US "self-defence strikes" responding to the downing of a US Army helicopter, **Iran retaliated against multiple Gulf states (Bahrain, Jordan, Kuwait)**, and the Strait of Hormuz remained blocked (Iran halting most transit; the US imposing its own restrictions on Iranian ports). This is the **third intraday flare in three sessions and the first to widen geographically** — peace-talk odds receded. Yet **crude stayed rangebound** (WTI ~$87–90 vs $88.20 prior close; Brent ~$90–94 vs $94.25 prior) — no decisive spike, the same "Hormuz still leaking ~15% of visible traffic" dynamic capping the geopolitical bid. (Sources: [TheStreet 6/10](https://www.thestreet.com/stock-market-today/stock-market-today-dow-jones-sp-500-nasdaq-updates-june-10-2026), [2026 Strait of Hormuz crisis](https://en.wikipedia.org/wiki/2026_Strait_of_Hormuz_crisis), [TradingEconomics crude](https://tradingeconomics.com/commodity/crude-oil).)
- No unscheduled regulatory/enforcement action, material bankruptcy, or disaster surfaced inside the window beyond the above.

### 2. Scheduled events that resolved today (US-listed ≥$2B)

- **CPI (above)** — the macro catalyst of the day.
- **Oracle (ORCL) FQ4 + FY26 — AMC, record results but a sharp sell-the-news on capital intensity.** Total revenue **+21% to $19.2B**; cloud (IaaS+SaaS) **+47% to $9.9B** with **IaaS +93%**; non-GAAP EPS **$2.11 vs ~$1.89 cons (+11.6% beat)**; **RPO $638B, +363% YoY** (+$85B QoQ). Despite the blowout backlog, the stock **fell ~7–9% after hours** on two capital items: a Q1-FY27 guide for **~$70B of capex** (up from ~$56B in FY26) and a plan to **raise ~$40B via debt + equity financing**. The A-queue OCI/RPO-ramp thesis is *ratified at the fundamentals level* but the market is repricing the **capital intensity / dilution** of the AI build-out. Day-0 close-to-close lands tomorrow (6/11) — verify in the next D1. (Sources: [Oracle IR 6/10](https://investor.oracle.com/investor-news/news-details/2026/Oracle-Announces-Record-Q4-and-FY-2026-Results-Driven-by-Cloud-Infrastructure--Cloud-Applications/default.aspx), [StockTitan ORCL](https://www.stocktitan.net/news/ORCL/oracle-announces-record-q4-and-fy-2026-results-driven-by-cloud-sbg54dgv99js.html).)
- Smaller resolved prints (non-held/watchlist): **Cracker Barrel (CBRL)** beat + raised FY guidance (+10.7% premkt). **Calendar ahead:** **ADBE FQ2 — Thu 6/11 AMC** (A-queue, bearish-framed). **FOMC 6/16–17** (Warsh's first as Chair; live C catalyst, queued `rescreen-FOMC-C-20260615`). **MU FQ3 — 6/24 AMC** (A-queue).

### 3. Large single-name moves (≥$2B, ≥5% close-to-close, event-attributable)

- **Super Micro (SMCI) −~11.5%** (A-queue name) — on announcing **~$7B in equity-related financing deals**. A **dilution/financing repricing**, not a demand event — the same pattern as RDW's $500M ATM on 6/9 and ORCL's $40B raise tonight. A genuine new-supply adjustment, not a sentiment overshoot.
- **ZBRA (held, B) −7.43% → $216.79, a fresh 52-week low** (52w low now 199.05; YTD −10.7%). **No name-specific catalyst inside the window** (last analyst action was a late-March Baird PT cut; nothing 6/9–6/10). The move is **macro/sector beta** — ZBRA is a high-beta cyclical industrial-tech (enterprise mobility / automation, capex-sensitive) that amplifies the day's industrial-recession + rate-hike fears (Industrials −3%). See Risk-to-Positions.
- **Old Dominion (ODFL) −6.4%** (LTL freight) — an industrial-recession read-through on a hot-CPI/risk-off day; corroborates the Industrials-led downside.
- **CBRL +10.7%** (premarket; earnings beat + raised guide) — clean up-move on good news, not held/watchlist.
- **MU −4.7%** (A-queue; semis weak again) — just under the 5% bar. AAPL, the megacaps, and broad semis fell but none printed a clean ≥5% close beyond the above. (ORCL's −7–9% is *after-hours* — a Day-0 event for tomorrow, logged in §2.) (Source: [TheStreet 6/10](https://www.thestreet.com/stock-market-today/stock-market-today-dow-jones-sp-500-nasdaq-updates-june-10-2026).)

### 4. Sector-level moves

- **Industrials — the laggard, −3%+.** Hot-CPI/rate-hike + Iran risk-off + freight/recession signals (ODFL −6.4%) hit the most cyclical complex hardest. **Information Technology −2%+** and **Materials −2%+** also fell. This was a **broad** risk-off, unlike Tuesday's tech-specific de-rate inside positive breadth.
- **Defensives / Energy relatively firm.** Energy held up best (XLE ~+32% YTD context) with crude rangebound-to-firm on the Iran bid; defensive sectors outperformed the tape. No GICS sector printed a clean upside ≥2% ETF close attributable to a single identifiable driver — it was a down-tape with relative-strength rotation, not an up-leg anywhere. (Source: [Benzinga sectors 6/10](https://www.benzinga.com/insights/sector-etfs/26/06/53113393/leading-and-lagging-sectors-for-june-10-2026).)

### 5. Notable commentary

- **CPI core-soft framing (rates desks):** the undershoot on core (+0.2% MoM) was read as evidence the energy shock hasn't yet broadened — the reason the 10yr *eased* post-print despite a 3yr-high headline. The hawkish tail (Dec 25bps fully priced) is intact but front-loaded-hike fears were trimmed.
- **ORCL capital-intensity debate:** record RPO (+363%) vs a $70B capex guide + $40B raise crystallized the bull/bear tension on whether the AI-infrastructure backlog converts to FCF or to a multi-year capital-consumption + dilution cycle. BofA's pre-print $240 PT (Buy, "robust demand") now faces the capital-intensity counter-read. Directly relevant to the A-queue AI-infrastructure cohort.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP (every open position; today = 2026-06-10 MT)

Live connector marks at/just after the close; targets/time-exits from `state.current_positions`. Open set per connector = AZO, HCA, ZBRA, RTX, DIS (+SGOV). **TJX excluded — exit FILLED today (position 0); D2 reconciles.**

| Pos (strat) | Last (Wed 6/10) | Today % | Convergence target | Time-exit | Trigger? |
|---|---|---|---|---|---|
| ZBRA (B) | $216.79 | **−7.43%** | $264.00 | 2026-07-13 | No (−17.9% below) |
| HCA (B) | $373.21 | −0.45% | $442.85 | 2026-06-27 | No (−15.7% below) |
| AZO (B) | $3,111.35 | −0.84% | $3,200.00 | 2026-07-24 | No (−2.8% below) |
| RTX (D) | $178.10 | −1.91% | none (long-horizon) | 2027-04-27 | No |
| DIS (D) | $98.61 | −0.72% | none (long-horizon) | 2027-05-07 | No |

**No mechanical exit triggered.** No convergence-target hit (ZBRA, after −7.43%, sits −17.9% *below* its $264 target; AZO −2.8% below, reversing Tuesday's drift toward target). No time-based exit due (earliest is HCA 2026-06-27, 17 days out). TJX's mechanical convergence exit (flagged 6/9) **filled today** — the daily sweep's purpose served; D2 marks `stage-TJX-exit-20260609` complete at Step 0.

### PER-STRATEGY KILL-TRIGGER SWEEP (every active strategy)

Latest engine row (`perf.kill_flags`, as-of 2026-06-09): **B** deployed_unit_value 1.01338 / peak 1.01338 / **drawdown 0.0%** (deployed_days 31, gate_n 26); **D** deployed_unit_value 0.97166 / peak 1.00926 / **drawdown −3.72%** (deployed_days 31, gate_n 30). All four flags false (drawdown_kill / runaway_review / m2m_underperf_review / gate_reached). Intraday refresh against today's adverse marks: **B** takes a small hit (ZBRA −7.43% is ~$32.6 of ~$1,888 NAV ≈ −0.14% of NAV; AZO/HCA small; partly offset by the TJX exit booked at a gain) → B drawdown ~−0.2 to −0.5% from a fresh peak. **D** widens modestly (RTX −1.91%, DIS −0.72%) → ~−4.5% drawdown. Both remain **nowhere near the −50% drawdown kill (#1)**, and neither deployed TWR has doubled → **no runaway-success (#3)**. **No kill-trigger flags.**

### JUDGMENT-LADEN INVALIDATION CHECK (developments vs entry-record exit criteria)

- **ZBRA (B) — NOT-TRIPPED, but elevated-monitor.** −7.43% to a fresh 52-week low on **macro/sector beta**, not a thesis event. Against the entry-record invalidation set (re-affirmed in the 6/9 mid-window review, `events.decision_log` 2026-06-09 HOLD): (i)–(iii) no name-specific catalyst / guidance cut / demand-break inside the window — **none observed**; (iv) sub-pattern-1 PT-raise cluster — **none**; tariff/customer-demand monitoring — **no new adverse datapoint**. B-longs carry no price stop; disposition stays convergence ($264) / time-exit (2026-07-13, ~33 days out). The position is now −17.9% below target at a 52-wk low — flag for the next D1's continued watch, but **no invalidation and no action**.
- **RTX (D) — NOT-TRIPPED.** The broadened Iran flare is a **mild demand tailwind** (effectors / missile-defense on a multi-Gulf-strike day), though RTX still fell −1.91% on the broad risk-off. Entry-record criteria (Airbus / powder-metal / GTF EIS / backlog / FCF / procurement) NOT-TRIPPED. No action.
- **DIS (D) — NOT-TRIPPED.** No fresh name-specific news inside the window; −0.72% beta. Criterion (v) (final FCC order materially restricting ownership AND a Disney 8-K material-adverse disclosure) — neither exists → NOT-TRIPPED, elevated-monitor. No action.
- **HCA / AZO (B) — NOT-TRIPPED.** Small beta declines, no name-specific catalyst, below the ≥5% bar. AZO's −0.84% reverses some of Tuesday's drift toward its $3,200 target (now −2.8% below). Criteria NOT-TRIPPED.
- **TJX (B)** — exited today (mechanical convergence exit filled); no longer an open position.

### WATCHLIST CANDIDATE STATUS

- **Strategy A queue (AI/semi/tech: NVDA, AVGO, MU, ORCL, AMD, MRVL, AMAT, INTC, CRM, SNOW, DELL, HPE, SMCI, NOW, PANW, CRWD, etc.)** — **context for the next M1 ACTIVATE evaluation, not a today action** (router DNA → no drain). The AI-capex-digestion headwind **materially aggravated this window, and gained a new financing/dilution dimension**: ORCL guided **$70B FY27 capex + a $40B raise**, SMCI announced **$7B of equity financing** (−11.5%), following RDW's $500M ATM on 6/9. The market is now repricing not just AI *valuations* but the **capital intensity and dilution** of the build-out. Crucially, **ORCL's own A-queue thesis (OCI/RPO ramp) was *ratified* at the fundamentals level** (RPO +363%, IaaS +93%, EPS beat) even as the tape punished the capital plan — i.e. the demand data is *intact*, the de-rate is about *who pays for the capex*. Net: the A-queue "valuation-reset caveat" strengthens to a **"valuation + capital-intensity / dilution reset"** caveat. **Watch ORCL Day-0 (6/11 D1) and ADBE 6/11 AMC.** No queue name moves to entry-ready; none invalidated. **Strategy A queue unchanged.**
- No B-overflow (NVO) / D-pipeline / short-direction-tracking (SHOP/PYPL/CDW/MGM) name materially changed inside the window.

---

## ANALYSIS — OPPORTUNITY CHECK

- **No new clean B/C/A/E entry candidate originated this window.**
- **SMCI (B) — NO-GO on its face.** −11.5% clears the mechanical ≥5% screen, but the driver is a **$7B equity-related financing/dilution repricing** — genuine new-supply information, not a sentiment overshoot to fade (and a down-move on dilution is the inverse of a B convergence-long setup). Same disposition as RDW 6/9. Fails B criterion-2 (disproportion = "real repricing").
- **ORCL (A-queue) — the AMC −7–9% is a Day-0 event for tomorrow, NOT a clean B candidate.** The move is **information-driven** (capex guide + $40B financing), not a sentiment overshoot — B mechanism doesn't fit; it is an A-queue name whose entry resolves at next M1 ACTIVATE. Flag for **6/11 D1 to confirm Day-0 close-to-close** and feed the A-queue capital-intensity read.
- **ODFL −6.4% / ZBRA −7.43% / MU −4.7%** — macro/sector beta or held names, no clean event-overshoot → no candidate. **CBRL +10.7%** is an up-move on a beat-and-raise (B-long foreclosed = information-driven continuation; B-short mechanism-mismatched = no overshoot to fade) → not a clean B setup.
- **No new C or A catalyst announced.** Live C catalyst remains **FOMC 6/16–17** (queued `rescreen-FOMC-C-20260615`, conservative-default = stay in SGOV). A is DNA → any A catalyst routes to the Watchlist A-queue.
- **E (intra-cyclical dispersion)** widened today (Industrials −3% vs defensives/energy firm) — a clean *conceptual* divergence, but **E is execution-feasibility-deferred at current book size** (ETF-substitution-required per `div-E-202605-1`) → no actionable E pair; noted as an E-watch for M2/M4.
- **Already-queued items drained by D2 (not D1):** `rescreen-LLY-D-20260612` (due 6/12), `rescreen-FOMC-C-20260615` (6/15), staged `stage-MDT-B-20260603` (expire-missed-entry 6/17), and the now-filled `stage-TJX-exit-20260609` (reconcile/close). No D1 action.

---

## ANALYSIS — REGIME CHECK

Today is the most regime-relevant cluster in weeks — a hot CPI, a Fed-hike-confirmation, a broadened Iran flare, AND the first **broad** risk-off day of the recent window. Walked against the high bar:

- **Inflation / policy axis — CONFIRMS the existing 6/1 axis, no change.** The M1b axis already reads **inflation_trend=reaccelerating + policy_stance=hawkish + stagflation-tilt**. May CPI (+4.2% YoY headline) *confirms* the reaccelerating read; the **soft core (+0.2% MoM)** and the **easing 10yr (4.52%)** argue the energy shock hasn't broadened into underlying prices — so the print *ratifies* the standing axis rather than introducing a new one. A Dec 25bps hike stays fully priced (hawkish tail intact). **No axis flip.**
- **shock_overlay (Iran) — third flare, broadened, but stays latent.** This flare *widened geographically* (multiple Gulf states) and peace-talk odds receded — the most adverse of the three — **yet crude stayed rangebound** (no decisive spike), so active transmission persists (Hormuz blocked) while the acute/sustained-supply-shock branch is still not realized. The overlay **stays latent**, but this is the thread closest to the router-relevant bar: a **fourth flare with a sustained crude breakout** (WTI decisively > ~$95–100) would be an M1-level shock_overlay input.
- **risk_sentiment axis — first broad risk-off day; one session does not flip a monthly axis.** Today (S&P −1.62%, all majors ~−2%, Industrials −3%) is a genuine *broad* de-risking, distinct from Tuesday's tech-specific de-rate inside positive breadth. But the monthly axis is set on weight of evidence, not a single session; SPY Trend is still NEUTRAL (not yet DOWN) and the credit/VIX confirmation isn't in evidence at scan depth. **Watch:** if SPY Trend flips DOWN and/or breadth turns UNHEALTHY and/or VIX breaks higher over the next sessions, that *would* be an M1 risk-axis input.
- **Per-strategy activation — no flip implied even if the risk axis later softens.** B (post-event mispricing) *benefits* from elevated volatility → ACTIVATE unaffected; C is FOMC-gated (6/16–17 ahead, queued); A is already DNA; D is long-horizon ACTIVATE; E is deferred. No development today changes any activation state.

**Default NO — no inter-monthly router review recommended.** Today *confirms* the standing stagflation/hawkish/latent-shock axis rather than contradicting it, and no per-strategy activation would flip. **Monitor into 6/11 D1 and the run-up to FOMC 6/16–17:** (a) Iran — fourth flare vs sustained crude breakout (Hormuz still blocked); (b) risk_sentiment — SPY Trend / breadth / VIX confirmation of today's broad risk-off; (c) AI-capex/financing read into **ORCL Day-0** and **ADBE 6/11 AMC**.

*(Frontier-LLM capability check — Wednesday rotation [calibration], 1 HF `paper_search` run, concise, limit 5: nearest on-topic results — "Systematic Evaluation of Uncertainty Estimation Methods in LLMs" 2510.20460 (2025-10-23), "Calibrating LLM Judges: Linear Probes…" 2512.22245 (2025-12-23), "CritiCal" 2510.24505 (2025-10-28), plus older Xiong-confidence-elicitation / "Must Be Taught". All pre-date the ~24h scan window; nothing published inside 6/9→6/10, no Tier-1 architectural delta, new failure mode, or Tier-2 numerical contradiction → silent per protocol; no Decision_Log capture.)*

---

## RECOMMENDED ACTIONS

The downstream D2 routine reads this section verbatim and converts each bullet into an order / live-file edit / queue entry.

- **Exits triggered:** **NONE new.** No mechanical convergence-target hit (ZBRA −17.9% / AZO −2.8% / HCA −15.7% below targets), no time-based exit due (earliest HCA 2026-06-27), no per-strategy kill-flag (B drawdown ~0%, D ~−3.7%; all flags false), no judgment-laden invalidation trip. **Reconciliation item for D2 Step 0:** **TJX (B) exit FILLED today** — flip TJX OPEN→CLOSED in `state.current_positions`, record the fill (price/commission/realized_pnl from `get_account_trades`), recompute `perf.strategy_daily` for B, and mark `stage-TJX-exit-20260609` complete (`events.queue_events`). State currently shows TJX OPEN; the connector shows position 0.
- **New entry candidates:** NONE clean. **SMCI (B) screens on the ≥5% bar but is a NO-GO on its face** (−11.5% = $7B equity-financing/dilution repricing, like RDW 6/9 — not an overshoot to fade). **ORCL (A-queue) AMC −7–9% is a Day-0 event → 6/11 D1 must verify Day-0 close-to-close**; information-driven (capex/financing), not a clean B setup, and A-queue entry resolves at next M1 ACTIVATE. Queued items (`rescreen-LLY-D-20260612`, `rescreen-FOMC-C-20260615`, staged `stage-MDT-B-20260603`) are drained by D2, not actioned here.
- **Watchlist updates:** none requiring an edit today. **Note for the next M1 ACTIVATE evaluation (A-queue AI-infrastructure cohort):** the AI-capex headwind aggravated materially this window and gained a **financing/dilution dimension** — ORCL ($70B FY27 capex + $40B raise; thesis *ratified* at fundamentals, RPO +363%/IaaS +93%, but capital intensity repriced), SMCI (−11.5% on $7B financing), following RDW's $500M ATM (6/9). Upgrade the standing "valuation-reset caveat" to a **"valuation + capital-intensity / dilution reset"** caveat. Watch ORCL Day-0 (6/11) and ADBE 6/11 AMC for the demand-vs-capital read.
- **Router reviews:** none (high bar not met; today confirms the standing 6/1 stagflation/hawkish/latent-shock axis and flips no activation). **Monitor 6/11 D1 + run-up to FOMC 6/16–17:** (i) Iran — fourth flare vs **sustained crude breakout** (WTI decisively >~$95–100; Hormuz still blocked) → shock_overlay M1 input; (ii) **risk_sentiment** — whether SPY Trend flips DOWN / breadth turns UNHEALTHY / VIX confirms today's first broad risk-off; (iii) AI-capex/financing read into ORCL Day-0 and ADBE 6/11 AMC. Also continue to watch **ZBRA** (held B, fresh 52-wk low, −17.9% below target, ~33 days to its 7/13 time-exit) — no invalidation today, but the closest open position to an adverse disposition.
