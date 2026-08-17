2026-W34

# Weekly Post-Event Screen — Strategy B (W2)

**Run:** 2026-08-17 (Mon, ISO week **2026-W34**, per `state.trading_day_today.today`; `is_trading_day=true`, `last_trading_day=2026-08-17`). Run started 04:21 MT, **before the opening bell** — so the last *completed* regular session is Friday **2026-08-14**, and every price figure below is a completed regular-session close. No live or intraday print is load-bearing anywhere in this file.

**⚠ There is no 2026-W33 Post-Event Screen, and this marker skips a week deliberately.** W2's W33 cycle **aborted**: `ops.run_log` carries a `W2 / 2026-08-16 / started` row (session `5b0a30b8…`, branch `claude/confident-brahmagupta-x6m7tv`, logged 12:04 MT) with **no terminal row**, consistent with the BigQuery connector de-auth that also halted W5 that day. W2's last *successful* completion is therefore **2026-08-09** (marker `2026-W32`). The file-write convention pins the marker to the ISO week of **today's run date** and forbids look-ahead stamping, so this file carries `2026-W34`. Verified via BigQuery `FORMAT_DATE('%G-W%V', DATE '2026-08-17')` → `2026-W34`.

**⚠ Sibling-weekly marker divergence, stated rather than hidden.** W1 completed **2026-08-16 (Sun)** and stamped `Weekly_Catalyst_Calendar.md` with `2026-W33`. That run is on branch `claude/friendly-ramanujan-e9plia` and **has not merged to `main`** as of this write (`git show origin/main:Weekly_Catalyst_Calendar.md` still reads `2026-W32`). So this cycle's weeklies will carry *different* markers — W1 `2026-W33`, W2 `2026-W34` — because they ran on opposite sides of a Sunday/Monday ISO-week boundary, not because either is mis-stamped. Both are correct under the convention as written. **This does not break W4's dependency gate,** which is period-aware (`bigquery/114_period_aware_dependency_gate.sql`): W1/W2/W3/W4 are `weekly_sun`, and both 2026-08-16 and 2026-08-17 fall inside the same Sunday-anchored weekly period. Flagged because the marker-vs-period distinction is exactly the kind of seam that has previously been misread as staleness.

**Prior-10-trading-day window screened:** 2026-08-03, 08-04, 08-05, 08-06, 08-07, 08-10, 08-11, 08-12, 08-13, 08-14. Confirmed against `state.market_calendar`; `events.market_holidays` returned **zero rows** for 2026-07-25 → 2026-09-01.

**Catch-up check — no widening owed.** `state.routine_catchup_window` gives `routine='W2', last_completed_ts=2026-08-09, never_completed=false, window_days=8.07`. Against a 7-day normal weekly look-back that is **1.15×**, below the 1.5× threshold, so **no `CATCHUP` token is owed**. The trading-day arithmetic agrees: only **6 trading days** have elapsed since the last successful completion (8/10, 8/11, 8/12, 8/13, 8/14, 8/17), far short of the >10-trading-day trigger in W2's own PART 1. The standard 10-trading-day look-back (8/03–8/14) already spans everything since 2026-08-09 and more, so the missed W33 cycle costs **no evidence coverage** — only a week of ranking freshness.

**Window arithmetic** (B's frozen entry window = 10 trading sessions counting the event day as day 1; forward sessions are 8/18, 8/19, 8/20, 8/21, 8/24, 8/25, 8/26, 8/27):

| Event day | Window closes | Trading days left **after today** |
|---|---|---|
| 8/3 | **CLOSED 8/14** | — (PART 1 context only) |
| 8/4 | **8/17 — today** | **0** (today is day 10) |
| 8/5 | 8/18 | 1 |
| 8/6 | 8/19 | 2 |
| 8/7 | 8/20 | 3 |
| 8/10 | 8/21 | 4 |
| 8/11 | 8/24 | 5 |
| 8/12 | 8/25 | 6 |
| 8/13 | 8/26 | 7 |
| 8/14 | 8/27 | 8 |

**Overlap with last cycle.** The 2026-08-09 run screened 7/27–8/07, so **8/3–8/7 is carry-forward** and **8/10–8/14 is fresh ground** — five full sessions never before screened, and the sessions that matter most, because they are the only ones with meaningful window left. Event day **8/3 has expired** (window closed 8/14) and is recorded as context only.

---

## Gating context — read this before the rankings

**🔴 REGIME GATE — Strategy B remains DO-NOT-ACTIVATE for new entries.** Per `state.current_regime`, divergence review **`div-B-202607-1`** resolved 2026-08-05 as **DO-NOT-ACTIVATE (STATE CHANGE from ACTIVATE)**, theater-check DIVERGENT. Unchanged this week. The DNA is produced **entirely by the universal `shock_overlay=acute` reconciliation override** (Strategy.md:121) — the Iran/Hormuz acute call still stands off the 2026-08-01 fundamental read. B's own technical legs still pass independently, re-measured as of 2026-08-14: **`SPY_TREND = UP`** (776.34 > 50d 748.93 > 200d 705.46, ≠ DOWN ✔) and **`VIX_REGIME = LOW`** at 14.25 (≠ HIGH ✔). So B is gated by macro overlay, not by any failure of its own activation rule.

- **Practical bite: this blocks NEW B entries only** (Strategy.md:101). The one open B position (MSCI) runs to its own mechanical exit criteria, undisturbed.
- **⚠ W4: this is research output, not a staging instruction.** Last cycle proves the point — `events.decision_log` 2026-08-09 records `action-conversion → NO THESIS-CONSTRUCTION ENQUEUED`, reason "B = DO-NOT-ACTIVATE, capital_disabled=TRUE; router gate, not load cap." **All 15 candidates from the 2026-08-09 shortlist were never converted, and every one of their windows has since run down to 0–3 days.** Expect the same outcome this cycle unless the override lifts. A screen moves research attention, never capital.

**Operational context (not a screen input).** `state.trading_enabled = FALSE`, `halt_reason = "state.freshness marks_fresh/engine_fresh not both TRUE"`. This is the ordinary Monday-pre-market artifact — `last_trading_day` has already rolled to 2026-08-17 while marks/engine cover through 2026-08-14; the cadence-aware pair (`marks_current`, `engine_current`) is **TRUE**. It is not a drawdown or incident halt. W2 stages nothing, so it does not gate this run.

**Long-bias (Rev 36).** DOWN movers are the natural B setups (fade an overdone selloff as a LONG); UP movers are takeable only as LONG under-reactions, the hardest B case, which **has never once converted in the recorded lineage** (0 of ~108 theses produced a short entry through 2026-06-22). Every UP mover below is therefore recorded for completeness and **rejected on mechanism, not on merit**. No shorting of pops in this regime.

**Cross-strategy — criterion 5 binds nothing this week.** Open **A** positions: **none** (`state.current_positions` holds only B and D rows). The 37 Strategy-A names in `state.open_queue` are `WATCHLIST`/`pending` rows, **not open positions**, so Entry criterion 5 ("No A position currently open in the same name") is satisfied vacuously — including for **AVGO** and **AMAT**, both of which sit on the A watchlist queue and both of which appear below. Open **B** book: **MSCI** only (`B:MSCI:2026-07-27`); **ISRG closed 2026-08-11/12** on its convergence target. MSCI is not offered as a new-entry candidate. The D book (AMZN, CRM, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER) does **not** gate B — only A↔B and A↔C bind. Already-queued B watchlist rows (CDW, MGM, PYPL, SHOP, NVO) are noted but none recur below.

**📊 Calibration prior.** `events.decision_log` for the trailing window records **1 GO against 12 NO-GOs** on B thesis constructions (the single GO being MTZ, 2026-08-03). The base rate for a ranked candidate converting to a GO is low by construction, and the ranking below should be read as "worth a thesis session," not "likely to trade."

---

## Data provenance and method

- **PRICE BASIS (Operating_Protocols.md §19).** Every close-to-close magnitude that this screen computes, gates on, or logs is measured from **IBKR regular-session daily bars** — `get_price_history(contract_id, security_type='STK', step='ONE_DAY', outside_rth=false)`. `get_price_snapshot` was **not used for any close anywhere in this run**. Contract resolution was done per ticker with explicit rejection of foreign cross-listings, leveraged/inverse single-stock ETFs, and same-ticker unrelated issuers (the rejected sets are non-trivial — e.g. DOCS collides with Dr. Martens PLC on LSE, ATS with Austria Technologie & System, LITE with CoinShares Litecoin ETPs).
- **This is the first cycle in the recorded lineage where the discovery source and the IBKR bars agreed to the rounding digit.** All **44** independently-discovered magnitudes were re-verified against IBKR bars and **not one deviated by more than 0.05pp** (largest: CBRS 0.05pp; most 0.00–0.01pp). The §19 PRICE BASIS rule exists because W2 has repeatedly had to correct D1's snapshot-based figures a week late (COIN −9.3% vs −10.58%, GLW −16.1% vs −12.10%, UPS "unconfirmed" vs −6.57%). **No such correction is owed this week** — measuring it right at the source worked.
- **FMP was rate-limited ("Limit Reach") on every endpoint for the entire session**, across all six discovery/research agents. Population discovery therefore ran on WebSearch + WebFetch against stockanalysis.com historical daily-close tables, CNBC/Yahoo/Reuters movers coverage, SEC filings and company IR releases, with **IBKR bars as the authoritative price layer over the top**. Market caps and ADV are the weakest layer in this file and are flagged where load-bearing.
- **Extraction-before-reasoning** was applied to all external text: only quoted, checkable facts carrying a source and date entered the reasoning below. Source disagreements are reported in place rather than silently resolved.
- **Sub-agent fan-out:** 15 Sonnet-5 agents — 5 population discovery (by date block + a non-earnings sweep), 1 targeted gap-check, 6 IBKR price verification, 3 thesis-grade deep research. Orchestration, Layer-2 judgment and ranking were done by the Opus-5 session.

---

## 🔎 Process findings (measurement and coverage, not routing)

1. **The 8/13–8/14 discovery sweep missed COHR, and the IBKR bars caught it.** Coherent reported FQ4 after the 8/12 close and fell **355.64 → 327.23 on 8/13 = −7.99%**, a clean ≥5% event-day move on a ~$64B cap that no headline sweep surfaced. It was found only because the verification pull for its *earlier* 8/10 move returned the whole bar series. **Lesson: the price layer is a better completeness check than the headline layer.** COHR is carried below with the honest caveat that it was surfaced too late for deep research this cycle.
2. **Last cycle missed BLLN entirely** — a **−38.89%** single-session move on a ~$4.4B cap, the largest single-name reaction anywhere in the 10-day window, on event day 8/6 which the 2026-08-09 run *did* screen. It is ranked #2 below. A second name, **ATS** (−26.55%, 8/6), was also missed but excludes mechanically on the cap floor.
3. **The gap-check also corrected a name the sweeps had half-caught.** MNDY was surfaced with the wrong event day (8/14) and a wrong event description (a "guidance cut" plus a simultaneous 20% RIF). Verification against IBKR bars and the primary release established the event day as **8/10 at −4.84%** — below the spec floor — with FY26 revenue guidance **unchanged**, FY26 margin guidance **raised**, and the workforce reduction announced separately on 2026-07-22. Both intervening moves were sector noise: 8/13's +9.70% was a soft-PPI software rally (MDB +7.9%, NET +6.2% the same session) and 8/14's −7.18% was its giveback. **A late-session correction beats a confident wrong row**, and the misreading is recorded in place rather than quietly fixed.
4. **The completeness of the ≥5% decliner list for 8/13–8/14 is NOT established.** The dedicated gap-check found no further qualifying names but reported low confidence: CNBC article pages returned HTTP 403 all session, no date-filterable earnings calendar was reachable (FMP rate-limited; Nasdaq/Zacks/EarningsWhispers are JS-gated), and its WebSearch budget (200/200) was exhausted mid-sweep. Two other agents also exhausted their search budgets. **Evidence lists are floors, not ceilings** — and this week that rule is doing real work.
5. **A sign-convention trap, recorded so it is not re-introduced.** The reversion metric was first specified to the price agents as a signed ratio whose sign reads counter-intuitively (negative = reverted). It was computed correctly but stated backwards in the first pass. All trajectory language in this file has been normalised to the plain words **"reverted X%"** (moved back toward the pre-event level) and **"extended X%"** (moved further in the event direction).

---

## PART 1 — §19 significance screen

Columns: **Move** = IBKR-verified event-day close-to-close. **Verdict** = Layer-2 significance judgment, `SIG`/`REJ` + conviction (30/45/60/75). **L5** = `legacy_rule_pass`, the old fixed ≥5% bar, computed mechanically as a record-only benchmark. **BSF** = `below_spec_floor` (move <5%, B's frozen Entry criterion 1) — context/SL1 evidence only, **never advanced as a candidate**. Ticker **bold** = surfaced this cycle for the first time.

### Event day 2026-08-14 — 8 days remaining (window closes 8/27)

| Ticker | Name | Event | Move | Verdict | L5 | BSF | Note / trajectory |
|---|---|---|---|---|---|---|---|
| **RDDT** | Reddit | S&P 500 inclusion announced after 8/13 close, replacing AvalonBay effective 8/18 | **+12.63%** | REJ (60) | ✔ | — | **NEW.** Mechanical index-demand event, not a fundamental repricing. UP mover. No post-event sessions yet. |
| **NU** | Nu Holdings | Earnings — revenue, purchase volume, customer growth all beat | **+9.30%** | REJ (45) | ✔ | — | **NEW.** UP mover; Cayman/Brazil domicile. Rejected on mechanism and eligibility. |
| **NBIS** | Nebius Group | Earnings + >$1B TCV contract announcements (Vantage Data Centers) | **+8.90%** | REJ (45) | ✔ | — | **NEW.** Second up-leg after the 8/12 +34.14%. Dutch-incorporated (N.V.). UP mover. |
| **AVGO** | Broadcom | BofA **credit-desk** note on the XPV AI financing vehicle; issuer rating cut to Marketweight | **−5.94%** | **SIG (75)** | ✔ | — | **NEW.** Consensus PT $527.88 vs $392.99 = **+34.3%**, widest gap in the file; 37 of 48 analysts Strong Buy, zero Sell. The triggering analyst **raised** FY26 revenue/EBITDA forecasts (+10%/+13%) in the same note. **⚠ REJECTED for ranking on SP5** — see below. |
| **AMAT** | Applied Materials | FQ3 beat-and-raise; sold on China revenue mix 35%→28% and flat margin guide | **−5.12%** | **SIG (60)** | ✔ | — | **NEW.** Record revenue $9.115B vs $8.99B cons.; EPS $3.50 vs $3.40; Q4 guide $10.25B/$4.02 both above Street. Every post-event PT still far above tape (lowest $605 vs $507.18). **Ranked #6.** |
| **SNDK** | Sandisk | Investor Day long-term targets, continued digestion | **+7.40%** | REJ (30) | ✔ | — | Second up-leg after 8/13's +13.67%. UP mover. |
| **BIRK** | Birkenstock | L Catterton-affiliated discounted secondary, 22.5M shares at ~4% discount | **−4.03%** | REJ (45) | ✗ | ✔ | Mechanical float/supply event; German-domiciled. Below spec floor. |

### Event day 2026-08-13 — 7 days remaining (window closes 8/26)

| Ticker | Name | Event | Move | Verdict | L5 | BSF | Note / trajectory |
|---|---|---|---|---|---|---|---|
| **TPR** | Tapestry | FQ4 beat (rev $1,876.6M, adj EPS $1.32 vs $1.28) into a FY27 guide at/below elevated hopes | **−16.49%** | **SIG (75)** | ✔ | — | **NEW.** Consensus PT $167–168 vs $128.39 = **+29.6%**. Post-print PTs $159–$185, none near the tape. Flat since (+0.46%). ⚠ Kate Spade −10% FY26, guided to another HSD decline, turnaround admitted slower. **Ranked #3.** |
| **SNDK** | Sandisk | Investor Day: ~80% GM target, mid/high-teens growth, 100% excess-cash return | **+13.67%** | REJ (45) | ✔ | — | UP mover; extended a further +7.40%. Rejected on mechanism. |
| **CBRS** | Cerebras Systems | Q2 revenue $180.1M vs $193.6M cons. (miss); FY26 core guide **raised** to $880–890M | **−11.85%** | **SIG (60)** | ✔ | — | **NEW.** Consensus ~$282 vs $231.01 = **+22%**; UBS called it "a compelling buying opportunity." Extended a further 5.21%. ⚠ Concentration merely reshuffled (G42 11%/MBZUAI 63%), $450.5M GAAP loss, lockup ~Nov 9 (~171M shares, ~5× IPO float). **Ranked #7.** |
| **YETI** | YETI Holdings | Q2 adj EPS $0.67 vs $0.55 cons.; **FY adj EPS guide RAISED** to $2.94–3.00 from $2.83–2.89 | **−10.56%** | **SIG (60)** | ✔ | — | **NEW.** Three post-print PT **raises** (Stifel $42→$45, Raymond James $55→$56, Baird $55→$57). Consensus $54.47 vs $44.56 = **+22.2%**. Extended 2.00%. ⚠ ~$0.40 one-time tariff benefit in the quarter; FY revenue *dollar* guide trimmed to $1.967–1.985B from $1.999–2.017B; op margin 14.9%→12.9%. **Ranked #4.** |
| **STUB** | StubHub Holdings | Q2 revenue $573.1M vs $513.3M cons. (+33%) but bottom-line loss vs $0.11 cons. profit | **−10.07%** | **SIG (60)** | ✔ | — | **NEW.** ⚠ **REJECTED for ranking.** BofA cut PT **$11 → $7.50, below the $8.08 close, and downgraded to Sell** — a target through the tape is the PatternN/SP1-inversion ratification signature. CEO sold 8/5 pre-print; $4.4M insider selling in 3 months; ~Sept-16 one-year lockup question unresolved. Reverted 5.21%. |
| **CSCO** | Cisco Systems | FQ4 beat (rev $17.3B vs $16.82B, EPS $1.22 vs $1.17); FY27 revenue guide **raised**; sold on GM 66.3% vs 68.4% and a 65–66% FY27 margin guide | **−8.40%** | **SIG (75)** | ✔ | — | **NEW.** **Five same-day PT raises** (Barclays $123, KeyBanc $135, Morgan Stanley $135, Rosenblatt $165, Wells Fargo $150) against one downgrade whose target ($120) still sits *above* the tape. Consensus $132.59 vs $111.68 = **+18.7%**. Extended only 1.58%. **Ranked #1.** |
| **COHR** | Coherent | FQ4 earnings, reported after the 8/12 close | **−7.99%** | **SIG (45)** | ✔ | — | **NEW — MISSED BY THE HEADLINE SWEEP, caught by the IBKR bars** (see Process finding 1). 355.64 → 327.23. Cap ~$64B. ⚠ Not deep-researched this cycle; ranked on magnitude + window only. **Ranked #10.** |
| **JD** | JD.com | Earnings — EPS beat, but first-ever YoY quarterly revenue decline (−2.9%) | **−7.31%** | REJ (60) | ✔ | — | **MECHANICAL instrument-eligibility exclusion** — Cayman-incorporated, Beijing HQ, US-listed **ADR**. Same basis as the AZN/NVO exclusions. |
| **NFLX** | Netflix | Pershing Square disclosed a new ~3.15M-share stake | **+5.43%** | REJ (45) | ✔ | — | 13F/activist-disclosure event. UP mover. |
| **WDAY** | Workday | Reuters: Silver Lake in talks to acquire (~$43B); trading briefly halted | **+17.77%** | REJ (75) | ✔ | — | **NEW.** Deal-speculation arb — price is anchored to takeout arithmetic, no fundamental convergence to harvest. UP mover. |
| **ENS** | EnerSys | FQ1 adj EPS $3.66 vs $2.83 expected | **+5.71%** | REJ (30) | ✔ | — | Ordinary beat repricing. UP mover. |
| **MU** | Micron | PT hikes (Citi, HSBC, Melius to $1,100) + $250M ventures fund launch | **+4.23%** | REJ (30) | ✗ | ✔ | Analyst action on already-public information. Below floor. |
| **SMCI** | Super Micro | Continued post-earnings PT hikes (Bernstein $37→$42) | **+4.12%** | REJ (30) | ✗ | ✔ | Below floor; prior B NO-GO 2026-07-22 on the identical AI-hardware pop shape. |
| **CAVA** | CAVA Group | Continued digestion of the 8/11 Q2 beat | **+3.90%** | REJ (30) | ✗ | ✔ | Below floor. Extended a further +57% of the 8/12 move. |
| **TMUS** | T-Mobile US | Completed spectrum-portfolio swap with Grain Management | **+3.53%** | REJ (30) | ✗ | ✔ | Below floor. |
| **AMBP** | Ardagh Metal Packaging | Disclosed it is exploring a potential sale | **+4.35%** | REJ (45) | ✗ | ✔ | Below floor; deal speculation. Luxembourg-domiciled. |

### Event day 2026-08-12 — 6 days remaining (window closes 8/25)

| Ticker | Name | Event | Move | Verdict | L5 | BSF | Note / trajectory |
|---|---|---|---|---|---|---|---|
| **NBIS** | Nebius Group | Q2 revenue +454% YoY to $582.3M; EPS −$0.12 vs −$0.82 est. | **+34.14%** | REJ (60) | ✔ | — | **NEW.** Extended a further 28%. UP mover; Dutch-incorporated. |
| **QNT** | Quantinuum | Q2 revenue $8M (+279% YoY) + first FY26 guide $28–32M; Oracle OCI partnership | **+27.97%** | REJ (45) | ✔ | — | **NEW.** Reverted 52% within two sessions — an up-move that self-corrected. UP mover. |
| **CRWV** | CoreWeave | Q2 revenue $2.575B, roughly doubled YoY | **+19.28%** | REJ (60) | ✔ | — | UP mover. Reverted 14.2%. |
| **SMCI** | Super Micro | FQ4 + FY27 revenue guide $65–72B vs $52.5B est.; GM guide 15–17% vs 8.2–8.4% | **+19.02%** | REJ (60) | ✔ | — | **NEW.** Large genuine guide raise, but an UP mover and a saturated move (extended a further 37%). |
| **HRB** | H&R Block | FQ4 adj EPS $2.38 vs $2.21; FY27 EPS guide above consensus; dividend +10% | **+16.09%** | REJ (45) | ✔ | — | **NEW.** UP mover; essentially flat since (reverted 3.5%). |
| **CAVA** | CAVA Group | Q2 EPS $0.19 vs $0.18 | **+14.24%** | REJ (45) | ✔ | — | **NEW.** UP mover on a one-cent beat; extended a further 57%. |
| **LITE** | Lumentum | FQ4 results (reported after the 8/11 close) | **+13.63%** | REJ (45) | ✔ | — | **NEW.** Fully reversed the 8/10 −8.61% pre-earnings selloff and then some. UP mover. |
| **ACM** | AECOM | FQ3: $337M–$377M charge on one legacy 2019 construction-management project; **FY26 EPS guide cut to $3.95–4.15 from $5.90–6.10**; FCF guide $400M→$300M | **−8.96%** | **SIG (60)** | ✔ | — | **NEW.** Six post-event PT cuts — **all maintaining Buy/Outperform, all above tape** ($73–$97). Consensus $86.92 vs $63.11 = **+37.7%**. Backlog +13% to a record $27.8B, book-to-burn 1.6. Insider **buying** (CEO, President, a director) May–June. Reverted 34.4%. **Ranked #5.** |
| **KTB** | Kontoor Brands | Q2 slight beat; FY earnings guide raised above consensus | **+8.86%** | REJ (30) | ✔ | — | **NEW.** UP mover; extended a further ~50%. |
| **APP** | AppLovin | Piper Sandler / Wells Fargo downgrades layered on the 8/11 BofA cut | **−4.68%** | REJ (45) | ✗ | ✔ | Below floor. Second consecutive down session. |

### Event day 2026-08-11 — 5 days remaining (window closes 8/24)

| Ticker | Name | Event | Move | Verdict | L5 | BSF | Note / trajectory |
|---|---|---|---|---|---|---|---|
| **ONON** | On Holding | Q2 net sales CHF 850.3M vs CHF 879.57M cons.; FY26 cc growth guide cut from "at least 23%" to "low-20%s"; NA wholesale +4.8% vs +12.7% cons. | **−20.29%** | **SIG (75)** | ✔ | — | **NEW.** ⚠ **REJECTED for ranking under SP6.** Six firms cut targets post-print (Stifel $60→$41, Raymond James downgrade $52→$38, Baird $70→$55, UBS $83→$73, Telsey $51→$43, Barclays $46→$42), several by >20%, **ratings mostly maintained Buy/Outperform** — the canonical TEAM/SP6 valuation-reset-not-narrative-reset signature. Reverted 16.6%. Swiss-domiciled Class A **ordinary shares** (not an ADR) — eligibility note below. |
| **KKR** | KKR & Co | Rallied with asset managers on Nvidia's >$500B AI-infrastructure financing partnerships | **+6.88%** | REJ (30) | ✔ | — | Sector read-through, no name-specific event. UP mover. |
| **APO** | Apollo Global | Record Q2 (AUM ~$1.05T), $2.6B Yankee Global financing, Nvidia partnership optimism | **+6.26%** | REJ (45) | ✔ | — | UP mover; second consecutive up session. |
| **APP** | AppLovin | BofA downgrade to Neutral from Buy | **−5.99%** | REJ (45) | ✔ | — | Analyst action continuing post-Q2 fallout. Combined 8/11+8/12 drop −10.39%, reverted 33.2%. Prior-shape NO-GO lineage unchanged. |
| **JBL** | Jabil | UBS upgrade to Buy on a multiyear AI-driven growth cycle | **+5.94%** | REJ (45) | ✔ | — | UP mover; extended a further 32.5%. |
| **RIOT** | Riot Platforms | Q2 revenue $174.2M vs $154.3M est.; 191MW/20-yr/up-to-$16.1B Anthropic data-centre lease | **+4.33%** | REJ (45) | ✗ | ✔ | Below floor on the close despite a ~+20% intraday spike — reverted 146% and is now *below* the pre-event level. A clean example of why the close, not the print, is the measurement. |
| **HIMS** | Hims & Hers | Trimmed upper end of FY EBITDA outlook; Q2 net loss $0.37/sh vs prior-year $0.17 profit | **−3.97%** | REJ (45) | ✗ | ✔ | Below floor, but **extended 187%** — cumulative −11.40%. Worth a look next cycle if it re-crosses the floor on a fresh event. |

### Event day 2026-08-10 — 4 days remaining (window closes 8/21)

| Ticker | Name | Event | Move | Verdict | L5 | BSF | Note / trajectory |
|---|---|---|---|---|---|---|---|
| **COHR** | Coherent | Pre-earnings unwind of a multi-week AI-optics rally (no discrete company event) | **−14.24%** | REJ (30) | ✔ | — | Positioning, not information — no company-specific catalyst on the day. COHR's *real* event is its 8/13 print above. Held (reverted 1.3%). |
| **LITE** | Lumentum | Pre-earnings profit-taking, AI-optics group pullback (no discrete company event) | **−8.61%** | REJ (30) | ✔ | — | Fully recovered and then some by 8/14 (reverted 147%, net +4.04%). No event. |
| **DOCS** | Doximity | Giving back part of the 8/7 +32.62% CEO-commentary surge; no new 8/10 catalyst | **−6.46%** | REJ (30) | ✔ | — | Not a fresh event — a reversal of the prior event. Extended 46.9%. |
| **VRSK** | Verisk Analytics | Delaware Chancery ruled Verisk's termination of the $2.35B AccuLynx acquisition invalid; ordered to proceed, plus damages | **−5.55%** | **SIG (60)** | ✔ | — | **NEW.** ⚠ **REJECTED for ranking.** This is **information by construction** — a court ordered a $2.35B capital commitment the company had tried to escape, and Verisk "strongly disagree[s]" and is weighing appeal. The ~$1.39B cap erasure ≈ 59% of the deal price is a proportionate repricing, not a sentiment overshoot. Appeal timeline is an unresolved in-window binary. Held (reverted 4.6%). |
| **NTAP** | NetApp | Morgan Stanley upgrade to Equal Weight from Underweight | **+4.85%** | REJ (30) | ✗ | ✔ | Below floor; extended a further 91%. |
| **GLW** | Corning | Tracked the COHR/LITE AI-optics selloff; no Corning-specific news found | **−4.78%** | REJ (30) | ✗ | ✔ | Below floor, sector drift. Fully recovered by 8/14 (reverted 104%). |
| **RDNT** | RadNet | Record Q2 revenue, raised 2026 outlook | **+6.76%** | REJ (30) | ✔ | — | UP mover. Reverted 19%. |
| **APO** | Apollo Global | Nvidia AI-infrastructure financing partnership announcement | **+3.59%** | REJ (30) | ✗ | ✔ | Below floor; first of two up sessions. |
| **MNDY** | monday.com | Q2 earnings (BMO 8/10): revenue $364.6M vs ~$355.6M cons., non-GAAP EPS $1.48 vs ~$1.11 (+33%); **FY26 revenue guide UNCHANGED**, FY26 operating-margin guide **RAISED** ~13% → ~16%; sold on a Q3 guide of $368–370M (16–17% growth) vs ~22% just posted | **−4.84%** | **SIG (60)** | ✗ | ✔ | **NEW — surfaced only by the gap-check, and it corrects two prior misreadings.** (1) The event day is **8/10 at −4.84%**, not the 8/13 +9.70% (a sector-wide software rally on soft PPI — MDB +7.9%, NET +6.2% same session) or the 8/14 −7.18% (giveback of that rally). (2) There was **no FY guidance cut** and the ~20% workforce reduction was announced **2026-07-22, three weeks before the print**, not with it. Sell-side cut but stayed above tape (Citi $154→$132, Wells $130→$120, Cantor downgrade $112→$90); consensus $109 vs $87.52 = **+24.5%**. Extended, not reverted. ⚠ **`below_spec_floor` — context/SL1 evidence ONLY, never advanceable as a B candidate.** Noted because the *shape* (in-line guidance, beat on both lines, sold on an implied deceleration) is the same shape as BLLN at #2 — a recurring sub-floor pattern is exactly the SL1 ideation evidence §19's spec-floor rail exists to capture. Cap ~$3.70B; Israeli-domiciled ordinary shares. |

### Event days 2026-08-04 → 2026-08-07 — carry-forward, 0–3 days remaining

All magnitudes below were re-verified against IBKR bars this run and **all matched the 2026-08-09 file to within 0.01pp**. What is new is the **trajectory**, and it is the most informative thing in this cycle.

| Ticker | Event day | Move | Cum. → 8/14 | Trajectory | Days left | Verdict | L5 | Note |
|---|---|---|---|---|---|---|---|---|
| **BLLN** | 8/6 | **−38.89%** | −37.77% | **reverted 2.9%** | 2 | **SIG (75)** | ✔ | **NEW — missed entirely last cycle.** Largest single-name reaction in the window. **Ranked #2.** |
| ATS | 8/6 | −26.55% | −27.34% | extended 3.0% | 2 | REJ (45) | ✔ | **MECHANICAL cap-floor exclusion at ~$1.97–1.99B**; also Canadian-domiciled. Missed last cycle; excluded twice over. |
| TDC | 8/5 | −23.73% | −19.51% | reverted 17.8% | **1** | SIG (60) | ✔ | **Ranked #13.** Window nearly gone. |
| HONA | 8/6 | −23.16% | −18.31% | reverted 21.0% | 2 | SIG (60) | ✔ | **Ranked #11.** Quantified guide cut (7–9% → 4–5% organic) remains unambiguous information. |
| TTD | 8/7 | −21.90% | −19.98% | **reverted 8.8%** | 3 | SIG (75) | ✔ | **Ranked #9.** Least-reverted of the large carry-forwards. |
| PODD | 8/5 | −20.12% | −14.08% | reverted 30.0% | **1** | SIG (60) | ✔ | **Ranked #14.** Nearly a third already harvested; window nearly gone. |
| HUBS | 8/6 | −19.09% | −10.42% | **reverted 45.4%** | 2 | REJ (45) | ✔ | **Thesis substantially played out unaided** — 240.51 high on 8/13. Little left to harvest in 2 days. |
| DDOG | 8/6 | −19.03% | −9.79% | **reverted 48.6%** | 2 | REJ (45) | ✔ | Last cycle's #3. **Best-performing thesis of the cohort and it converged without us** — 229.29 → 255.46. Not re-offered: the mispricing is largely gone. |
| EXTR | 8/5 | −19.02% | −24.52% | **extended 28.9%** | **1** | REJ (45) | ✔ | Market is not retracting the FY27 deceleration read. Prior rank 14; drops out. |
| BROS | 8/6 | −18.79% | −20.79% | **extended 10.6%** | 2 | REJ (45) | ✔ | Last cycle's **#2**. Still falling. See calibration note below. |
| FOUR | 8/6 | −18.77% | −15.01% | reverted 20.1% | 2 | SIG (45) | ✔ | **Ranked #12.** Explicit FY26 adj-EPS guide cut below consensus remains the textbook information case. |
| RRX | 8/5 | −16.72% | −20.25% | **extended 21.1%** | **1** | REJ (45) | ✔ | Last cycle's **#1**. Still falling. See calibration note below. |
| PTON | 8/6 | −15.64% | −13.65% | reverted 12.7% | 2 | REJ (30) | ✔ | Prior rank 8; drops out on window exhaustion, not on thesis change. |
| NRG | 8/4 | −15.48% | −8.83% | reverted 42.9% | **0** | REJ (45) | ✔ | **Window closes TODAY (day 10 of 10).** Already 43% harvested. Not rankable in practice. |
| DAVE | 8/6 | −15.09% | −22.22% | **extended 47.3%** | 2 | REJ (60) | ✔ | Last cycle's #7. The worst extension in the cohort. |
| FIG | 8/6 | −14.85% | −9.70% | reverted 34.7% | 2 | REJ (45) | ✔ | Prior rank 10; a third harvested, 2 days left. |
| LCID | 8/5 | −13.88% | — | — | **1** | **SIG (60)** | ✔ | **NEW — missed last cycle.** ⚠ **REJECTED under SP4.** Guidance suspended 3+ months, FCF −$1.48B vs −$1.01B YoY, $761M cash vs $3.36B debt, dilution dependency on PIF/Ayar (~45%), Morgan Stanley at Sell/$5 **below** the tape. Cap ~$2.46–2.60B and falling toward the floor. Rivian/Fisker/Nikola comps all resolved against reversion. |
| POST | 8/7 | −12.79% | −10.28% | reverted 19.6% | 3 | SIG (60) | ✔ | **Ranked #15.** |
| SEZL | 8/7 | −33.89% | −27.77% | reverted 18.1% | 3 | SIG (75) | ✔ | **Ranked #8.** Last cycle's #5. |
| OPEN | 8/5 | −8.74% | — | — | **1** | REJ (30) | ✔ | **NEW — missed last cycle.** Post-report reversal on profitability-timeline skepticism; ~$3B cap. 1 day left; not rankable in practice. |
| EBAY | 8/3 | −6.03% | — | — | **CLOSED** | REJ (45) | ✔ | **NEW — missed last cycle.** Wells Fargo downgrade to Underweight on Depop integration costs + Vinted US entry. **Window expired 8/14** — context only. |
| SEDG | 8/6 | −3.63% | −4.37% | extended 20.3% | 2 | REJ (30) | ✗ | **MECHANICAL cap-floor exclusion at ~$1.99B**; also Israeli-domiciled. Below floor regardless. |
| EXPE | 8/6 | −4.10% | +4.07% | reverted 200% | 2 | REJ (30) | ✗ | Below floor; fully round-tripped to *above* the pre-event close. |
| CRM | 8/6 | −3.22% | +1.67% | reverted 152% | 2 | REJ (45) | ✗ | Below floor; held D name; fully recovered. Multi-executive leadership shuffle did not stick as a repricing. |
| IOVA | 8/6 | +43.09% | +60.83% | extended 41.2% | 2 | REJ (45) | ✔ | UP mover; record Q2 revenue ~$99M. Cap ~$3.16B. |
| FIGS | 8/7 | +26.87% | +30.71% | extended 14.2% | 3 | REJ (30) | ✔ | UP mover; cap ~$2.44B. |
| SOUN | 8/6, 8/7 | +10.11%, +13.28% | +15.55% | reverted 37% of the 2-day run | 2–3 | REJ (30) | ✔ | UP mover; record revenue + raised FY guide. |
| ARX | 8/13 | +43.35% | — | — | 7 | REJ (75) | ✔ | **NEW.** Thoma Bravo definitive all-cash takeout at $20.25/sh — deal-arb, no fundamental convergence to harvest. |
| ATKR | 8/3 | +28.22% | — | — | **CLOSED** | REJ (75) | ✔ | Prysmian definitive acquisition at $95.00/sh — deal-arb. Window expired. |
| TSAT | 8/4 | +36.26% | — | — | 0 | REJ (45) | ✔ | **NEW.** $2.3B Canadian Arctic satcom contract. UP mover; ADV unverified; window closes today. |
| AVAV | 8/7 | +9.12% | — | — | 3 | REJ (45) | ✔ | **NEW.** ≥$400M US Army Locust laser production order. UP mover. |
| PLD | 8/4 | −3.54% | — | — | 0 | REJ (45) | ✗ | **NEW.** Fell as acquirer on the ~$18.8B SEGRO bid. Below floor; window closes today. |

### Examined and EXCLUDED (with reason)

- **Mechanical cap-floor (<$2B):** ATS (~$1.97–1.99B), SEDG (~$1.99B), GLOB (~$1.6–1.8B), YSS (~$1.5B), SPCE (~$0.5B), TROX (~$0.95B), HZO (~$1.15B), VREX (~$0.78B), UPWK (~$1.06B), WEN (~$1.65B), BW (~$1.53B), VLD (~$0.52B), VALN (~$0.65B), OMER (~$1.0B), FOSL (~$0.3B), GO (~$1.1B).
- **Mechanical instrument-eligibility (foreign-domiciled ADR):** JD (Cayman/Beijing). Same basis as the AZN/NVO exclusions in the prior two cycles.
- **Foreign-domiciled but NOT an ADR — flagged, not excluded on that basis:** ONON (Swiss, NYSE Class A **ordinary shares**, files 20-F), BIRK (German), AMBP (Luxembourg), MNDY (Israeli), NU (Cayman/Brazil), NBIS (Dutch N.V.). B's instrument rule says "US-listed common equity"; ordinary shares listed directly on a US exchange satisfy that on a plain reading, whereas a depositary receipt does not. **ONON is rejected below on SP6, not on domicile** — but the ADR-vs-ordinary-shares distinction is doing real work here for the first time and **should be pinned explicitly by the owner** rather than left to each session's reading.
- **UP movers rejected on mechanism (Rev 36 long-bias):** RDDT, NU, NBIS×2, SNDK×2, WDAY, ENS, NFLX, MU, SMCI×2, CAVA×2, TMUS, AMBP, QNT, CRWV, HRB, LITE×2, KTB, KKR, APO×2, JBL, RIOT, NTAP, RDNT, IOVA, FIGS, SOUN×2, ARX, ATKR, TSAT, AVAV.
- **No discrete company event (positioning/sector drift):** COHR 8/10, LITE 8/10, GLW 8/10, DOCS 8/10.
- **Window expired before this run:** EBAY (8/3), ATKR (8/3).
- **Thesis substantially converged already, not re-offered:** DDOG (48.6% reverted), HUBS (45.4%), NRG (42.9%, window closes today).
- **Extended rather than converged — prior-cycle candidates dropping out:** RRX, BROS, DAVE, EXTR.

---

## PART 2 — Ranked shortlist (priority for W4 → PENDING_ANALYSIS thesis-construction)

**Default assumption: the market reaction is correct.** Every entry below has to overcome that prior, and the criterion-4 test is explicit — if the reaction is *information*-driven, the "mispricing" is correct pricing. The discriminator applied throughout is the **post-event sell-side response**: targets cut down *to or below* the new price means the decline was ratified as information (kill); targets left materially above, or raised into the decline, means the sell-side did not re-rate the name down with the tape.

**⚠ The regime gate above stands. Do not convert this into staged entries while B is DO-NOT-ACTIVATE.**

**Structural note on this week's ordering.** The fresh 8/12–8/14 cohort has **6–8 trading days** of window and essentially its full move intact; the carry-forward 8/4–8/7 cohort has **0–3 days** and has already reverted 10–49%. Runway and residual mispricing both point the same way, so the fresh cohort dominates the top of this list on structure, not just on merit.

**📉 Retrieved-precedent calibration, and an honest correction to last week's reasoning.** The 2026-08-09 run ranked RRX **#1** and BROS **#2** largely *because* they showed "zero reversion" at screen time, treating an un-retraced move as evidence of overshoot. Five sessions later RRX has **extended 21.1%**, BROS **extended 10.6%**, and DAVE (#7) **extended 47.3%** — while DDOG (#3) and HUBS (#9), both sold off inside a sector-wide software de-rate, **reverted 48.6% and 45.4% unaided**. On this one cohort, "hasn't bounced yet" predicted *continued decline*, not overshoot. It is a single cycle and not a base rate, but the ordering below deliberately does **not** repeat that inference — reversion-to-date is used as a measure of *how much is left to harvest*, never as evidence of mispricing.

### TOP-5 tier

**1. CSCO — Cisco Systems** · −8.40% (8/13) · **window closes 8/26 → 7 trading days** · cap ~$441B
- **(a) Hypothesized mispricing: LONG over-reaction — the cleanest reaction-to-information mismatch in the window.** Cisco beat on revenue ($17.3B vs $16.82B consensus, +18% YoY) and non-GAAP EPS ($1.22 vs $1.17), and **raised** FY27 revenue guidance to $72.2–73.4B. The stock fell 8.40% on a *gross-margin mix* story: non-GAAP GM 66.3% vs 68.4% YoY, guided to 65–66% for FY27. That compression is the arithmetic consequence of AI infrastructure revenue scaling from $1B (FY25) → $4B (FY26) → a guided $7.5B (FY27) against a $9.3B cumulative order book — lower-margin hardware mix is what *winning* this business looks like.
- **(b) Supporting public information — and the discriminator that puts it first.** **Five firms raised targets the same day the stock fell 8.4%**: Barclays $121→$123, KeyBanc $130→$135, Morgan Stanley $130→$135, Rosenblatt $150→$165, Wells Fargo $130→$150. The single downgrade (HSBC to Hold) cut its target to **$120 — still above the $111.68 close** — and framed it as "lack of positive catalysts," not a fundamentals critique. Consensus $132.59 vs $111.68 = **+18.7%**. This is the *inverse* of the SP1 ratification signature and the opposite of the SP6 mass-PT-cut pattern.
- **(c) Convergence indicators to watch:** whether any firm migrates a target to or below spot (bear cluster forming → PatternN); whether FY27 gross-margin guidance is revised down again at any conference appearance inside the window; whether AI-infrastructure order intake is re-cited above the $9.3B cumulative figure; stabilization versus the $111.68 (8/14) low.
- **(d) Days remaining: 7.**
- **(e) Tier: top-5 (#1).** Best combination in the file of a clean mechanism (beat + raised revenue guide, sold on a mix effect), the strongest sell-side counter-signal, no structural overhang, **no in-window binary** (next earnings Nov 18, ~93 days out), full runway, and mega-cap liquidity that makes any size executable. **Named risk:** the margin guide is a genuine multi-year mix change, not a one-quarter blip — if the market is re-rating Cisco's terminal margin structure rather than reacting to one guide, that is a slow re-rate no 60-day thesis will catch, and Cisco's own Nov-2023 −11% print took many months to work off.

**2. BLLN — BillionToOne** · −38.89% (8/6) · **window closes 8/19 → 2 trading days** · cap ~$4.40B
- **(a) Hypothesized mispricing: LONG over-reaction — the largest reaction-to-information mismatch anywhere in the window, and last cycle missed it.** Revenue was **in line** ($109.4M vs $109.12M consensus, +64% YoY), full-year guidance was **maintained** at $450–465M, gross margin 70.5%, and the company was **profitable at the operating line** ($5.5M). There was no miss and no guide cut. The −38.89% came entirely from the market reverse-engineering that unchanged FY guidance implies 2H growth of 29–38% against 1H's 74% — an inference about shape, applied to a stock that had run **+84% since May 6**.
- **(b) Supporting public information.** Both dated post-event actions **cut but stayed positive and stayed far above the tape**: BTIG $142→$130 (Buy), JPMorgan $145→$130 (Overweight), against a $93.33 close — roughly **+39%** to the cut targets, and consensus ~$121.43 = **+30%**. The Class B lockup (4.55M shares) **already expired 2026-05-05**, so the supply overhang is behind it, not ahead — this is *not* an SP5c lockup binary. Delaware-incorporated, US common stock, no eligibility complication.
- **(c) Convergence indicators to watch:** any firm migrating a target below spot; whether management re-guides or clarifies the 2H shape at any conference inside the window; ASP trajectory (Q2 $537 ex-true-ups, +$15 sequentially) holding; whether the +84% pre-print run continues to unwind or stabilizes near the $91.65 (8/6) low.
- **(d) Days remaining: 2.**
- **(e) Tier: top-5 (#2), ranked on merit with the window stated plainly.** On mechanism this is the single cleanest sentiment-over-information move in the file — in-line revenue, maintained guidance, healthy margins, a −38.89% tape. **It is ranked #2 rather than #1 solely because two trading days is barely enough to construct a thesis and act**, and under the standing DNA it will almost certainly expire unconverted. **Named risks:** only ~4–5 firms cover the name, so the "sell-side didn't ratify" signal is thin; it holds ~15% NIPT share against Natera's ~60%, so growth is structurally lumpier than an incumbent's; and at ~$104M/day it is the least liquid name in the top tier.

**3. TPR — Tapestry** · −16.49% (8/13) · **window closes 8/26 → 7 trading days** · cap ~$26.1B
- **(a) Hypothesized mispricing: LONG over-reaction, with a real and named structural qualifier.** FQ4 beat on both lines (revenue $1,876.6M vs ~$1.86B; adj EPS $1.32 vs $1.28, +28% YoY), and FY26 was strong throughout (revenue +14%, adj EPS +38%, non-GAAP operating margin +340bps to 23.4%). FY27 guidance ($8.4–8.5B revenue, $7.80–7.90 EPS) landed roughly in line rather than above — into a stock that had run ~20% into the print.
- **(b) Supporting public information.** Post-print targets were **$159–$185, none remotely near the $128.39 close**: Morgan Stanley $164→$159, BTIG $180→$175, Bernstein $180→**$185 (a raise)**. Consensus $167–168 vs $128.39 = **+29.6%**, the second-widest gap among ranked names. Coach — ~86% of revenue — grew **23–24%**.
- **(c) Convergence indicators to watch:** whether Kate Spade's FY27 decline guidance is tightened or widened; whether any firm cuts to or below spot; Coach's momentum in any interim datapoint; whether the new Kate Spade creative director produces a dated turnaround milestone inside the window.
- **(d) Days remaining: 7.**
- **(e) Tier: top-5 (#3).** Large magnitude, wide sell-side gap, full runway. **Named risk — and it is the reason this is #3 and not #1:** Kate Spade is a genuine multi-quarter structural drag (−10% FY26, guided to another high-single-digit decline, management explicitly admitting the turnaround "is taking longer than planned"), which is SP4a-shaped. The retrieved comp set splits precisely on this axis — PVH fell −26.5% on an actual guide cut and recovered **+31.2% over 90 days**, while Capri, whose Michael Kors problem is the closest structural analog to Kate Spade, bled a further ~15% over 30 days and was still far below targets six months later. A thesis session must decide which analogy governs before sizing.

**4. YETI — YETI Holdings** · −10.56% (8/13) · **window closes 8/26 → 7 trading days** · cap ~$3.47B
- **(a) Hypothesized mispricing: LONG over-reaction on a beat-and-raise.** Q2 adjusted EPS $0.67 beat $0.55 consensus, GAAP EPS $0.94 (+54% YoY), revenue essentially in line, gross margin +890bps to 66.7%, $130M repurchased in the quarter — and **FY adjusted EPS guidance was raised** to $2.94–3.00 from $2.83–2.89. The stock fell 10.56%.
- **(b) Supporting public information.** Every post-print action found was a **raise**: Stifel $42→$45, Raymond James $55→$56, Baird $55→$57, ratings held. Consensus $54.47 vs $44.56 = **+22.2%**. The sell-side moved targets *up* on the day the stock fell double digits.
- **(c) Convergence indicators to watch:** whether Drinkware (+2% in Q2, the weak leg) re-accelerates in any interim datapoint; whether the H2 tariff assumption (~20%) is revised; whether operating margin stabilizes off the 12.9% print; any firm cutting to or below spot.
- **(d) Days remaining: 7.**
- **(e) Tier: top-5 (#4).** Clean beat-and-raise with a unanimous PT-raise response and a wide consensus gap. **Named risks, which are why it sits below TPR:** roughly **$0.40 of the quarter's beat was a one-time tariff benefit**, without which the beat reportedly becomes a miss; the FY revenue *dollar* guide was quietly cut to $1.967–1.985B from $1.999–2.017B even as the percentage-growth range was held constant; and operating margin compressed 200bps YoY. A thesis session must decompose the beat before trusting it — a raised EPS guide resting on a tariff assumption and a trimmed revenue guide is exactly the shape that gets revised one quarter later.

**5. ACM — AECOM** · −8.96% (8/12) · **window closes 8/25 → 6 trading days** · cap ~$8.11B
- **(a) Hypothesized mispricing: LONG over-reaction to a one-project charge, with the guide cut acknowledged as real information.** A $337M–$377M pre-tax charge (sources conflict) on a **single legacy 2019-vintage construction-management contract** with subcontractors behind schedule drove a GAAP net loss of $0.65/share. FY26 EPS guidance was cut ~33% to $3.95–4.15 from $5.90–6.10 and FCF to $300M from $400M. Against that: **backlog grew 13% to a record $27.8B with a book-to-burn of 1.6** — the demand franchise is not what broke.
- **(b) Supporting public information.** Six post-event PT cuts, **every one maintaining Buy/Outperform (one Neutral), every one above the tape**: Baird $87→$73, BofA $94.50→$81, Citi $98→$97, KeyCorp →$79, RBC $105→$90, Truist $102→$85, against a $63.11 close. Consensus $86.92 = **+37.7%**, the widest gap of any ranked name. Insider activity in the prior 90 days is **buying only** — CEO Troy Rudd (4,225 sh @ ~$71.02), President Lara Poloni (4,224 sh @ ~$70.63), a director — all above the current price.
- **(c) Convergence indicators to watch:** whether AECOM discloses exposure to other similar-vintage legacy contracts (the single question that decides whether this is one project or a class); whether the charge estimate moves again before the project's mid-2027 completion; backlog and book-to-burn holding; any firm cutting to or below spot.
- **(d) Days remaining: 6.**
- **(e) Tier: top-5 (#5).** Widest consensus gap, unanimous rating maintenance, record backlog, and insider buying above spot. **Named risk:** a 33% EPS guide cut months after that guide was *raised* is a credibility event, not just an accounting charge, and the retrieved comps are cautionary in kind — Jacobs fell 26% in 2014 on restructuring charges and Fluor 21.3% in a single month in Dec-2018 on project-execution charges with a similar guidance cut. Neither comp yielded clean forward-return data, so the reversion base rate here is **asserted by nobody, including this file**.

### REST tier

**6. AMAT — Applied Materials** · −5.12% (8/14) · closes 8/27 → **8 days** · cap ~$403B
Record FQ3 (revenue $9.115B vs $8.99B consensus; non-GAAP EPS $3.50 vs $3.40) with Q4 guidance ($10.25B ±$500M revenue, $4.02 ±$0.20 EPS) **above** Street and the FY equipment-growth outlook raised to >30%. Post-event targets ranged $585–$740 — even the deepest cut (Deutsche Bank $680→$605) sits ~19% above the $507.18 close; consensus $638.17 = **+25.8%**. Longest runway in the file. ⚠ Two real drags keep it out of the top tier: China revenue share fell 35%→28% YoY against a **disclosed $600–710M FY26 revenue headwind** from the Sept-2025 export-control expansion — a durable policy fact, not a sentiment wobble — and the *identical* beat-and-sell-on-valuation pattern hit **LRCX and KLAC in the same reporting season**, which reads as a cohort de-rate (SP6-shaped) rather than a single-name mispricing. Insider selling of ~$90.7M in the trailing 3 months compounds the caution.

**7. CBRS — Cerebras Systems** · −11.85% (8/13) · closes 8/26 → **7 days** · cap ~$52.0B
Q2 revenue missed ($180.1M vs $193.6M consensus) but FY26 core guidance was **raised** to $880–890M with core gross margin to 41–43%. Two cuts (Mizuho $310→$300, Citi $340→$320) and two raises (UBS to $330 calling the selloff "a compelling buying opportunity", Morgan Stanley $273→$279) all sit far above the $231.01 close; consensus ~$282 = **+22%**. ⚠ Ranked no higher because the structural questions are unresolved *in the evidence itself*: customer concentration was **reshuffled, not reduced** (G42 87% → G42 11%/MBZUAI 63%, with a new OpenAI agreement becoming the next concentration), a $450.5M GAAP net loss, a lockup releasing ~171M shares (~5× the IPO float) at the earlier of two days post-Q3-earnings or **Nov 9**, and a **directly contradictory EPS-vs-consensus record across sources** that this run could not reconcile. Thin float means quoted liquidity overstates tradeable liquidity.

**8. SEZL — Sezzle** · −33.89% (8/7) · closes 8/20 → **3 days** · cap ~$4.3B
Revenue +51.7% YoY beat with FY guidance raised on all three guided lines; the −33.89% was a response to an implied 2H deceleration to ~30% growth. Second-largest magnitude in the window. Reverted 18.1% since, so roughly four-fifths of the move is still intact. ⚠ Three days left, and the pre-print setup remains unattractive — insider selling by the President and CFO the week before, and +150% YTD into the print. Same shape as BLLN but with a worse insider record and a shorter window.

**9. TTD — The Trade Desk** · −21.90% (8/7) · closes 8/20 → **3 days** · cap ~$6.6B
**Least-reverted large carry-forward in the file — only 8.8% retraced**, so essentially the entire move is intact. ⚠ Ranked here rather than higher because the information is unusually hard: TTD guided its **first-ever YoY revenue decline** with the CFO, CMO and commercial chief all replaced, and a downgrade wave followed. A first-ever revenue decline plus a management clear-out is SP4-shaped structural information, and "hasn't bounced" is precisely the signal this file has just finished cautioning against over-reading.

**10. COHR — Coherent** · −7.99% (8/13) · closes 8/26 → **7 days** · cap ~$64B
**Surfaced only by the IBKR price layer after the headline sweep missed it** (Process finding 1). FQ4 reported after the 8/12 close; 355.64 → 327.23. Full runway and a large-cap, liquid name. ⚠ Ranked on magnitude and window alone — **no deep research was performed on it this cycle**, so the decisive sell-side-response test has not been run, and it must not be treated as validated. A thesis session should start by establishing whether post-print targets sit above or below the $325.83 close. Listed at #10 as an honest placeholder, not a recommendation.

**11. HONA — Honeywell Aerospace** · −23.16% (8/6) · closes 8/19 → **2 days** · cap ~$52.7B
First standalone print since the spin. FY26 organic growth guided down from 7–9% to **4–5%** on mechanical-parts/casting shortages. Reverted 21.0%. ⚠ The guide cut is quantified and unambiguous — information by construction — and two days of window make it academic. Retains a read-through to the held **D:RTX** position that is more valuable than its B candidacy.

**12. FOUR — Shift4 Payments** · −18.77% (8/6) · closes 8/19 → **2 days** · cap ~$3.76B
Beat both lines but **cut FY26 adjusted EPS guidance** below consensus. Reverted 20.1%. ⚠ An explicit, quantified forward guide cut below consensus is the textbook information case; carried for continuity with two days left.

**13. TDC — Teradata** · −23.73% (8/5) · closes 8/18 → **1 day** · cap ~$2.4B
Both lines beat and the FY EPS guide was **raised**; only the Q3 guide was soft. Reverted 17.8%. ⚠ **One trading day left** — retained for record continuity as last cycle's #4, not as a live prospect.

**14. PODD — Insulet** · −20.12% (8/5) · closes 8/18 → **1 day** · cap ~$9.9B
Beat both lines against a 1–2pp guide trim citing type-2 retention. **Reverted 30.0%** — nearly a third already harvested. ⚠ One day left; effectively closed.

**15. POST — Post Holdings** · −12.79% (8/7) · closes 8/20 → **3 days** · cap ~$4.6B
Clean top-line miss with earnings −41.7% YoY on 6.4× volume. Reverted 19.6%. ⚠ A clean miss with sharply lower earnings is information by construction; ranked last, retained for continuity.

---

## Self-check

- **§19 rails applied as written.** Layer-1 population rail = mkt cap ≥ $2B, 30-day ADV ≥ $10M, |close-to-close| ≥ 3% on an event day in the 10-trading-day window (2026-08-03 → 2026-08-14), event-attributable. Layer-2 AI significance judgment — not the move percentage — decided what advanced. The escape valve was not used (no sub-net items surfaced). B's frozen Entry criterion 1 (≥5% event-day move, `strategy/04_strategy_b.md`, spec_hash-frozen) was applied as the PART-2 spec-floor rail only; **no `below_spec_floor` name was advanced as a candidate anywhere in this file**. `legacy_rule_pass` computed mechanically per row as a record-only benchmark. **No file under `strategy/` or `strategy_math/` was read for editing or modified.**
- **PRICE BASIS honoured, and for once with nothing to correct.** Every load-bearing magnitude is an IBKR ONE_DAY regular-session bar with `outside_rth=false`; `get_price_snapshot` was not used for any close anywhere in this run. **All 44 independently-discovered magnitudes were re-verified against IBKR bars and none deviated by more than 0.05pp.**
- **Shortlist cap respected:** 15 ranked candidates, the unchanged maximum.
- **Criterion 5 (no open A position in the same name):** checked — **no open A positions exist**, so the constraint binds nothing, explicitly including AVGO and AMAT, which sit on the A *watchlist queue* but are not positions.
- **"NO-GO records are context, not barriers"** applied: SEZL, TTD, HONA, FOUR, TDC, PODD and POST all carry prior-cycle screen history and were re-evaluated on **current trajectory evidence** rather than pre-empted or auto-renewed; RRX, BROS, DAVE and EXTR were dropped on new evidence (extension, not convergence) rather than on their prior ranking; APP, SMCI and IREN-shaped pops were re-rejected on precedent because the shape and mechanism are unchanged, which is a judgment, not a bar.
- **Rejections carry their reasons, and the sub-pattern is named where one fits:** ONON → **SP6** (six PT cuts >20% with ratings maintained); STUB → **PatternN/SP1-inversion** (BofA target cut *through* the tape to $7.50 with a Sell); AVGO → **SP5a** (Q3 earnings 2026-09-02, 16 days out, squarely in-window); LCID → **SP4** (suspended guidance, worsening burn, dilution dependency); VRSK → information by construction (court-ordered $2.35B commitment).
- **Honest limitations, stated rather than buried.** (i) **The ≥5% decliner list for 8/13–8/14 is not established as complete** — the dedicated gap-check reported low confidence after CNBC pages returned HTTP 403 all session, no date-filterable earnings calendar was reachable, and its search budget was exhausted; two other agents also hit their budgets. Given that the price layer caught COHR after the headline layer missed it, more misses are likely, not unlikely. (ii) **FMP was rate-limited on every endpoint all session**, so no market cap or ADV figure in this file is FMP-sourced; caps near the $2B floor (ATS ~$1.97–1.99B, SEDG ~$1.99B, LCID ~$2.46–2.60B) turn on shares-outstanding vintage and are flagged in place. (iii) **MNDY was resolved after the first draft of this file and the correction is recorded rather than smoothed over** — its event day is 8/10 at **−4.84%**, which puts it **below the spec floor** and makes it unrankable; the initial reading (which took the 8/14 −7.18% for the event and assumed a guidance cut plus a simultaneous 20% RIF) was wrong on all three counts, and the corrected row states what actually happened. (iv) **COHR is ranked without deep research** and is labelled as such at #10. (v) Source conflicts left unresolved rather than smoothed: ACM's charge ($337M vs $377M), CBRS's EPS-vs-consensus (two irreconcilable framings), AVGO's $370B figure (vehicle-level debt vs Broadcom guarantee exposure), LCID's ADV (9.21M vs 19M shares). (vi) The **ADR-vs-ordinary-shares** eligibility question (ONON) is decided here on a plain reading of "US-listed common equity" and **flagged for the owner to pin**.
- **Chat output:** one-line acknowledgment only.
