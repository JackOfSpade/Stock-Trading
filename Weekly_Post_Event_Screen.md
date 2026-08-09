2026-W32

# Weekly Post-Event Screen — Strategy B (W2)

**Run:** 2026-08-09 (Sun, ISO week **2026-W32**, per `state.trading_day_today.today`; `is_trading_day=false`, `last_trading_day=2026-08-07`). Every price figure below is a **completed regular-session close** — no live/intraday prints are load-bearing anywhere in this file.

**⚠ Marker collision, deliberate and correct.** The prior W2 run was **2026-08-03 (Mon)**, which falls in the *same* ISO week as today (2026-W32 runs Mon 08-03 → Sun 08-09). The file-write convention pins the marker to the ISO week of the run date and **explicitly forbids look-ahead stamping** ("never the upcoming trading-Monday's week"), so this file carries `2026-W32` again rather than `2026-W33`. Both sibling weeklies that ran today — `Weekly_Catalyst_Calendar.md` (W1) and `Weekly_Position_Deep_Dive.md` (W3) — are likewise stamped `2026-W32`, so the three are consistent. Verified via BigQuery `FORMAT_DATE('%G-W%V', DATE '2026-08-09')`. **This is not a stale marker.**

**Prior-10-trading-day window screened:** 2026-07-27, 07-28, 07-29, 07-30, 07-31, 08-03, 08-04, 08-05, 08-06, 08-07. No holidays in range (`events.market_holidays` returned empty for 2026-07-20 → 2026-09-01). Catch-up check: `state.routine_catchup_window` gives `window_days = 5.61` (last W2 completion 2026-08-03), i.e. **normal weekly cadence** — the CATCH-UP EVIDENCE WINDOW does not widen the look-back and **no `CATCHUP` token is owed**.

**Window arithmetic** (B entry window = 10 trading sessions counting the event day as day 1; next sessions are 8/10, 8/11, 8/12, 8/13, 8/14, 8/17, 8/18, 8/19, 8/20):
7/27 → **CLOSED 8/7** · 7/28 → 8/10 (**1 day left**) · 7/29 → 8/11 (2) · 7/30 → 8/12 (3) · 7/31 → 8/13 (4) · 8/3 → 8/14 (5) · 8/4 → 8/17 (6) · 8/5 → 8/18 (7) · 8/6 → 8/19 (8) · 8/7 → 8/20 (9).

**Overlap with last cycle:** 2026-W32's 08-03 run screened 7/20–7/31. **7/27–7/31 is carried forward** with updated trajectory (the informative change is how much of each reaction has since reverted); **8/3–8/7 is fresh ground** — five full sessions, including 8/3, which was still *in session* at the prior run and so had no completed close-to-close move then.

---

## Gating context — read this before the rankings

**🔴 REGIME GATE — Strategy B is DO-NOT-ACTIVATE for new entries.** Per `state.current_regime`, divergence review **`div-B-202607-1` RESOLVED on 2026-08-05** and converted B from ACTIVATE to **DO-NOT-ACTIVATE (STATE CHANGE)**. B's raw M1b call and its technical call both read ACTIVATE; the DNA is produced entirely by the **universal `shock_overlay=acute` reconciliation override** (Strategy.md:121), which the orchestrator found correctly and validly applied. Theater-check DIVERGENT; verdict binds per Strategy.md:156.

- **Practical bite: this blocks NEW B entries only** (Strategy.md:101). Existing B positions run to their own mechanical exit criteria, undisturbed.
- **B's technical legs still pass independently** and are re-measured as of 2026-08-07: `SPY_TREND = UP` (≠ DOWN ✔), `VIX_REGIME = LOW` at 14.90 (≠ HIGH ✔). So the DNA is *entirely* the macro-shock override, not a technical failure of B's own activation rule.
- **⚠ W4: rank order below is valid research output, but do NOT convert it into staged entries while the DNA stands.** A screen moves research attention, never capital. If the override lifts (the shock_overlay axis is re-scored monthly by M1a, and D2 has been re-reviewing it on a rolling basis), the shortlist is ready; until then these are thesis-construction candidates at most, and the conservative default on any candidate whose window expires under the DNA is simply to let it expire.

**Operational context (not a screen input).** `state.trading_enabled = TRUE` and `state.freshness` is fully green through 2026-08-07 (`marks_fresh`, `engine_fresh`, `d2_ran_last_trading_day` all TRUE) — a change from last cycle, when the whole conversion path was halted. So the *only* thing standing between this shortlist and staging is the B regime gate above.

**Long-bias (Rev 36).** DOWN movers are the natural B setups (fade an overdone selloff as a LONG); UP movers are takeable only as LONG under-reactions, which is the hardest B case and has never once converted in the recorded lineage. **No shorting of pops in this regime** — the router activates B precisely in the risk-on/neutral regimes where fading a pop runs into momentum, squeeze risk and the 2.20 textbook-rational penalty. Every UP mover below is therefore recorded for completeness and rejected on mechanism, not on merit.

**Cross-strategy.** Open **A** positions: **none** — the Strategy-A entries in `state.open_queue` are all `WATCHLIST`/`pending` rows, not open positions, and A is itself DO-NOT-ACTIVATE. **Entry criterion 5 (no open A position in the same name) therefore binds nothing this week**, including on DDOG, which sits on the A watchlist queue. Open **B** book: **ISRG** (`B:ISRG:2026-07-21`) and **MSCI** (`B:MSCI:2026-07-27`) — FTV closed 2026-08-06 on its convergence target (+2.63 realized), MDT and MTZ both closed earlier in the week. Neither open name is offered as a new-entry candidate. The D book (AMZN×2, CRM, DIS×2, GOOGL×2, GEV, ISRG, RTX, TSM×2, UBER) does **not** gate B; only A↔B and A↔C bind.

**🔵 CRITERION-3 CONSTRAINT — binds the ENTIRE cohort, verified not assumed.** 60 days from a realistic 2026-08-10 entry is **2026-10-09**. The FMP forward earnings calendar for 2026-10-01 → 10-12 returns exactly **three** names (DAL, PEP, TLRY, all 10/08) — Q3 season does not begin until ~10/08 and no candidate below reports before it. **"Next earnings release" is therefore NOT an admissible convergence target for any name in this file**, and the other closed-list markers (next FDA decision date, next FOMC, index inclusion in S&P 500 / Russell 1000 / Nasdaq 100) do not apply to any of them either. **Every thesis in this cohort requires a NUMERICAL price target.** Do not let a thesis session reach for an event marker; it is out of window. (This is the second consecutive cycle where this constraint binds cohort-wide.)

**📊 CALIBRATION PRIOR — the honest base rate this shortlist should be read against.** Measured directly from `events.decision_log`: since 2026-06-01 there have been **84 Strategy-B thesis constructions → 4 GO, 79 NO-GO (4.8% conversion)**. Last cycle's entire top-5 (LII, CARR, AAPL, VRT, GDDY) was adjudicated **NO-GO on 2026-08-03**, along with RDDT, VCYT, ALHC, BTSG, SRAD and TGTX — seven B theses in one session, all NO-GO. A high rank in PART 2 means "this is the best-shaped candidate available," **not** "this is likely to convert. The prior says it probably will not.

---

## Data provenance and method

**FMP was live this cycle** — the first time in five cycles (the prior four runs were hard rate-limited account-wide). `marketPerformance`, `company`, `calendar` and `analyst` endpoints responded, though `calendar/earnings-company` and `analyst/price-target-news` returned plan-tier ACCESS DENIED and the forward earnings-calendar pull was thin enough that it is treated as a lead source, not a census.

**All load-bearing magnitudes are IBKR `get_price_history` ONE_DAY regular-session bars** (`security_type='STK'`, `outside_rth=false`), per Operating_Protocols.md §19 PRICE BASIS. Bars were pulled **sequentially, one ticker at a time**, with each returned series checked against the ticker requested — the 2026-W30 batched-parallel mis-assignment defect remains a standing process caveat and was deliberately not repeated.

Work was fanned out across **four Sonnet-5 sub-agents** (8/6–8/7 down-mover sweep; 8/4–8/5 down-mover sweep; independent population sweep for names the daily screen missed; 7/28–7/31 carry-forward trajectory). **Every figure carrying a ranking decision was re-verified in-session against IBKR by the orchestrator**: TTD, DOCS, DAVE, POST, RRX, INSP, BROS, SEZL, DDOG, PODD and TDC were each re-pulled and recomputed independently, and all eleven matched the sub-agent figures exactly.

Event attribution and sell-side breadth come from Tavily/web plus the in-system D1 daily `research-screen` decision rows for 8/3–8/7, which are themselves verified records. **Extraction-before-reasoning was applied to all external text**: only quoted/checkable facts carrying a source and date entered the reasoning below.

---

## 🔎 TWO MEASUREMENT FINDINGS (process, not routing)

**1. The daily screen missed two qualifying names outright.** Neither **TTD** nor **DOCS** appears anywhere in D1's 2026-08-07 `single-name-move` screen (29 surfaced, 22 judged significant), yet both clear every population rail by a wide margin and both were among the largest moves on the tape:

- **TTD −21.90%** (17.67 → 13.80) on **105.8M shares against a ~9M-share norm — 11×**. It had *already* fallen −6.80% on 8/6 on 41.4M shares, so this was a visible two-session break, not a single surprise print. Cumulative 8/5 → 8/7: **−27.2%**.
- **DOCS +32.62%** (20.66 → 27.40) on **36.9M shares against a ~1.3M norm — 28×**.

**2. A logged D1 magnitude was wrong by sign and by session — a NEW error class.** D1's 2026-08-05 screen logged **INSP at −6.31%**, filed as a `rule_only` disagreement with the note "one source reported +27% on a raised FY outlook. Unresolved source conflict." The IBKR bars resolve it decisively: INSP's event day was **2026-08-04 at +22.83%** (52.22 → 64.14, 4× volume, on an EPS beat *and* a raised FY guide). D1 measured the **8/5 pullback session** (64.14 → 60.09 = −6.16%) as though it were the event day. The "+27%" source it could not reconcile was directionally right.

  **Why this one matters beyond the name.** §19's PRICE BASIS clause (added 2026-08-05, the same day) fixes the price *source* — daily bars, never snapshots. It says nothing about selecting the right *session*. This is a **wrong-session-selection** error, which survives the PRICE BASIS fix completely. It is a distinct failure mode from the snapshot-contamination class that clause was written for, and it is the kind that silently inverts a sign. **INSP itself changes no routing** — it fails the $2B floor at ~$1.74B — so this is a measurement-process finding, not a missed candidate.

  **And it is not isolated — the same class appeared twice in this one run.** Re-measuring the carry-forward set found **CCJ** recorded last cycle at +4.30% on 7/31, where IBKR's 7/30→7/31 close-to-close is **−2.10%** and the +4.30% figure matches the **7/29→7/30** session instead (see the carry-forward corrections below). Two independent instances of wrong-session selection in one cycle, in two different routines' outputs, is the argument for treating this as a pattern rather than a one-off. Both instances happened to land on below-floor / below-spec-floor names and changed no routing, which is luck rather than a control. Recorded here rather than escalated; a future self-improvement pass may want to consider whether the event-day selection deserves the same explicit treatment §19 gave the price source.

  Related, smaller sign/magnitude corrections this run (published figure → IBKR close-to-close): **BRKR** −18.13% → **−21.79%**; **RRX** −14.3% → **−16.72%**; **TDC** "17–20%" → **−23.73%**; **SEDG** "22.3–28.1%" → **−30.48%**; **WRBY** "~11–12%" (an intraday trough) → **−7.89%**; **ITGR** "+2.5–2.7%" (a premarket print) → **+20.19%**; **SUPN** "+24.9%" → **+3.07%**; **OC** "+7.65%" → **+4.77%**; **UWMC** wire used a $1.84 reference close against IBKR's actual $1.95.

---

## PART 1 — §19 significance screen

Sorted by event date, most recent first. **Move** = close-to-close on the event day, IBKR regular-session bars. **Verdict** = Layer-2 significance judgment (SIG/REJ + conviction 30/45/60/75). **L5** = `legacy_rule_pass` (the retired fixed ≥5% bar, computed mechanically, record-only benchmark). **BSF** = `below_spec_floor` (<5% — context / SL1 ideation evidence only, **never** rankable as a B candidate, §19 spec-floor rail).

### Event day 2026-08-07 — 9 days remaining (window closes 8/20)

| Ticker | Name | Event | Move | Verdict | L5 | BSF | Note / trajectory |
|---|---|---|---|---|---|---|---|
| **SEZL** | Sezzle | Earnings — rev $149.7M vs ~$137M (**+10% beat**), adj EPS $1.13 vs ~$1.04 (beat); **FY guide RAISED** (growth to 35%, adj NI $185M, EPS $5.25) | **−33.89%** | **SIG (75)** | ✔ | — | **NEW.** Largest reaction-to-information mismatch in the window. 11× volume. Opened 132.36 = session HIGH, closed 118.02 near the 114.16 low — a one-way tape with no bid all session. ⚠ Insider selling by President and CFO the prior week; +150% YTD into the print. **Ranked #5.** |
| **TTD** | The Trade Desk | Earnings — rev $715.1M vs $752.6M (**miss**, and below mgmt's own ≥$750M floor), EPS $0.34 vs $0.40; Q3 guide ≥$650M vs $804.8M cons = **first-ever YoY revenue decline** (−12.1%); CFO/CMO/commercial chief all replaced | **−21.90%** | **SIG (75)** | ✔ | — | **NEW — MISSED BY D1.** 11× volume; −6.80% on 8/6 already. 7 firms cut (BMO, Truist, Baird, Raymond James, Guggenheim, Evercore, Susquehanna). Cap ~$6.5B (one source cites $8.91B — unresolved). **Rejected for PART 2 — see EXCLUDED.** |
| **POST** | Post Holdings | Earnings — FQ3 rev $1.94B vs $2.03B cons (**miss**), net earnings −41.7% YoY | **−12.79%** | SIG (60) | ✔ | — | **NEW.** 6.4× volume. Clean top-line miss = information by construction. **Ranked #11.** |
| **DOCS** | Doximity | Earnings — rev $156.6M vs ~$151.8M (beat, above own guide), adj EPS $0.29 vs $0.30 (narrow miss); **FY27 guide RAISED** ~$6M | **+32.62%** | SIG (60) | ✔ | — | **NEW — MISSED BY D1.** 28× volume. **Opened 38.86 (+88%), closed 27.40** — gave back roughly two-thirds of the gap intraday, a shape a close-to-close screen cannot see. ~16% of float short → squeeze artifact. UP mover → not rankable. |
| TEAM | Atlassian | Earnings — FQ4 beat + BofA upgrade to Buy PT $175 | **+35.31%** | REJ (75) | ✔ | — | Largest move on the tape. **Prior B NO-GO 2026-05-02 under SP6 — the eponymous "TEAM Pattern."** Same shape, same name, same conclusion. |
| TWLO | Twilio | Earnings — Q2 beat, four-year high | **+24.89%** | REJ (60) | ✔ | — | **Prior B NO-GO 2026-05-02 (SP1)** on an identical positive-reaction/sell-side-ratification shape. |
| NTRA | Natera | Earnings — rev $752.8M vs $673.9M cons (+38.8% YoY), narrower loss, outlook raised | **+21.37%** | SIG (45) | ✔ | — | UP mover; ~$46B cap. Information-proportionate re-rating. |
| HALO | Halozyme | Earnings — adj EPS $2.28 vs ~$1.85 (+25%), FY EPS guide raised to $8.65–9.00 | **+20.24%** | SIG (45) | ✔ | — | UP mover, multiple upgrades. Ratification, not under-reaction. |
| ABNB | Airbnb | Earnings — beat AND raise | **+17.43%** | SIG (60) | ✔ | — | EXTENDED through the session (+8.5% premarket → +17.4% close) — a stronger sub-pattern than a fading spike. UP mover. |
| FLR | Fluor | Earnings — Q2 beat | **+16.92%** | SIG (45) | ✔ | — | ~$7.4B cap; discounted for single-day noise at that size. |
| SPCX | (SpaceX) | Post-IPO earnings beat + Argus upgrade | **+15.83%** | REJ (45) | ✔ | — | Recently listed — no established volatility regime to judge significance against. Caps conviction rather than raising it. |
| OKLO | Oklo | Groves reactor **first criticality** — binary technical milestone | **+14.77%** | SIG (60) | ✔ | — | Different information type (milestone, not a print). SMR complex reprices on these. |
| PLTR | Palantir | BofA upgrade following an already-public Q2 print | **+10.32%** | REJ (45) | ✔ | — | Upgrade on public information — informative about positioning, weaker evidence than the print. |
| RKLB | Rocket Lab | Upgrade + 92nd Electron mission success | **+9.46%** | REJ (30) | ✔ | — | At this cadence the mission is routine; the move is substantially the upgrade. |
| DKNG | DraftKings | Earnings — rev **MISSED** ($1.44B vs ~$1.52B) and the stock ROSE | **+8.39%** | SIG (60) | ✔ | — | Miss attributed to sports-outcome variance; FY26 reaffirmed. The market explicitly separated noise from signal — notable, but an UP mover. |
| LYFT | Lyft | Earnings — EPS $0.29 vs $0.15 beat, in-line revenue, solid Q3 bookings guide | **+7.12%** | SIG (60) | ✔ | — | Published +1.68% understated by 5.4pp; correct measurement is what surfaced it at all. UP mover. |
| UBER | Uber | Second consecutive up session on the Q2 print, against PT cuts | **+6.46%** | SIG (60) | ✔ | — | **Held Strategy D name** — not a B candidate. Tape overruling the sell-side. |
| TTWO | Take-Two | FQ1 bookings above own guided range; GTA VI reaffirmed for 2026-11-19 | **+6.04%** | SIG (45) | ✔ | — | Reaction is to hard de-risking of the largest catalyst in the name. UP mover. |
| NET | Cloudflare | Earnings — all-time high intraday (+16.2% premarket), gave back two-thirds by the close | **+5.57%** | **SIG (75)** | ✔ | — | The most informative *shape* on the tape: an over-reaction that self-corrected inside one session. **Prior B NO-GO 2026-05-13 (SP4b+SP3).** UP mover. |
| QCOM | Qualcomm | Semis/software relief rally | +4.66% | REJ (45) | ✗ | **✔** | Derivative of the tape. A circulated "−11% on weak guidance" framing is a weekly figure presented as daily. |
| UAA | Under Armour | Q1 FY27 print | −4.53% | REJ (30) | ✗ | **✔** | Dual-class share counts put cap at $1.5–2.9B across sources — **may not clear the $2B rail at all.** Flagged, not silently dropped. |
| SNOW | Snowflake | Software/AI cohort rally | +3.93% | REJ (45) | ✗ | **✔** | Cohort beta, no name-specific event. |
| WDC | Western Digital | Second consecutive session of memory guidance de-rating | −3.81% | REJ (60) | ✗ | **✔** | Segment story, not a name story. See 8/6 row. |
| SNDK | Sandisk | Other half of the memory de-rating | −3.68% | REJ (60) | ✗ | **✔** | Extends the cohort pattern; cuts against reading memory as tech beta. |
| LNG | Cheniere | Energy pullback on a day crude rose | −3.62% | REJ (45) | ✗ | **✔** | Sector rotation, not a name event. |

### Event day 2026-08-06 — 8 days remaining (window closes 8/19)

| Ticker | Name | Event | Move | Verdict | L5 | BSF | Note / trajectory |
|---|---|---|---|---|---|---|---|
| **BROS** | Dutch Bros | Earnings — rev $550.9M vs $526.3M (**+4.7% beat**), adj EPS $0.33 vs $0.29 beat; **FY revenue, same-shop comps AND EBITDA guides ALL RAISED** | **−18.79%** | **SIG (75)** | ✔ | — | **NEW.** 9.5× volume. **Zero reversion** — fell a further −0.60% on 8/7 (cumulative −19.28%). Street 20/24 Buy, median PT ~$78–80 vs $53.01 spot. Bear case = H2 comp deceleration + capex 27% above expectations. **Ranked #2.** |
| **DDOG** | Datadog | Earnings — rev $1.12B vs $1.08B (+36% YoY beat), non-GAAP EPS $0.65 vs $0.49–0.58 (beat); **FY26 guide RAISED** to $4.45–4.47B | **−19.03%** | **SIG (75)** | ✔ | — | **NEW event** (prior B NO-GO 2026-05-12, SP1 — different event). 4× volume. Only **8.6% reverted**. Analysts RAISED post-print (Citi →$305 "buy the dip", DA Davidson $315, Scotiabank →$285) vs $233.93 spot. ⚠ Largest-customer usage decline disclosed; FCF margin 29%→25%. **Ranked #3.** |
| **HUBS** | HubSpot | Earnings — rev $911.7M vs $898.3M (beat), non-GAAP EPS $3.26 vs $3.02 (**+8% beat**); but net customer adds guided **9–10k → 5–6k** | **−19.09%** | SIG (60) | ✔ | — | **NEW.** Steepest single-day drop in company history; CEO: "the quarter we expected did not fully materialize." ≥6 downgrades (Piper, Oppenheimer, Bernstein $381→$220, BMO, Barclays) with **new targets at/near spot** → SP6 ratified-at-cluster signature. 16.8% reverted. **Ranked #9.** |
| **APP** | AppLovin | Earnings — rev $1.924B vs ~$1.95B (narrow miss), adj EPS $3.97 vs $4.21 (−5.7%); Q3 guide slightly below | **−19.66%** | **REJ (75)** | ✔ | — | **The APP 2026-07-20 NO-GO named this exact print as "an in-window ratification binary." That binary has now landed.** Rejecting again on the standing precedent rather than re-litigating it. |
| **HONA** | Honeywell Aerospace | Earnings — first standalone print post 2026-06-29 spin; adj EPS $1.87 vs ~$2.10 miss; **FY26 organic growth guide CUT 7–9% → 4–5%**, EPS guide $7.60–7.90 vs ~$8.86 | **−23.16%** | SIG (60) | ✔ | — | **NEW.** Real quantified guide cut on supply-chain constraints + $50M inventory charge. 25.5% reverted. Read-through to held **D:RTX**. **Ranked #15.** |
| **FOUR** | Shift4 Payments | Earnings — beat both lines; **FY26 adj EPS guide CUT** $5.50–5.70 → $5.15–5.35 vs ~$5.41 cons | **−18.77%** | SIG (45) | ✔ | — | **NEW.** **Zero reversion** — a further −4.84% on 8/7. A real forward guide cut = information. **Ranked #12.** |
| CELH | Celsius | Earnings — rev $817.9M vs ~$879M (**miss ~6%**), adj EPS $0.36 vs ~$0.42 (miss); domestic CELSIUS-brand revenue **−11.7% YoY** | **−18.46%** | REJ (45) | ✔ | — | **74.3% of the gap reverted by 8/7** (23.77 → 27.77). Residual far thinner than the DHR/VRT disqualifying precedent (79% / 86–99%). Genuine miss + near-full retrace = nothing left to harvest. |
| **PTON** | Peloton | Earnings — FQ4 rev $608M vs $597.7M (beat), adj EPS $0.13 vs $0.11 (beat); **first full profitable fiscal year**; FY27 guide −3.9% YoY at midpoint | **−15.64%** | SIG (45) | ✔ | — | **NEW.** Guide reflects lapping a known price increase. 28-analyst consensus ~$8.03–8.40 vs $5.68 spot. Cap $2.37B — clears the floor **narrowly**. Paid subs still −8.8% YoY. **Ranked #8.** |
| **DAVE** | Dave Inc | Earnings — EPS $4.12 vs $3.67 (beat), rev +30% YoY, **guidance RAISED**; sold on a sharp planned H2 marketing/CAC step-up | **−15.09%** | SIG (60) | ✔ | — | **NEW — MISSED BY D1.** Then **EXTENDED a further −12.96% on 8/7** (→317.93): cumulative **−26.09%**, zero reversion. Cap ~$3.4–4.6B across sources. **Ranked #7.** |
| **FIG** | Figma | Earnings — rev $370.1M **+48% YoY**, above own guide; **FY26 guide RAISED +$40M**; GAAP loss $112.2M is SBC-driven | **−14.85%** | SIG (45) | ✔ | — | **Zero reversion** (further −2.8% on 8/7). Consensus ~$37 vs $23.29 spot. ⚠ **Prior B NO-GO 2026-05-18 (SP5c lockup-supply binary)**; recent IPO with no established baseline; Q3 guide implies 48%→36% deceleration. **Ranked #10.** |
| WDC | Western Digital | Earnings — rev $3.75B vs $3.68B and adj EPS $3.56 vs $3.31 (**clean double beat**); sold on the HAMR qualification gap vs Seagate | **−13.03%** | REJ (45) | ✔ | — | Disproportionate on the numbers alone, but this is the **memory/AI-capex cohort D2 already adjudicated as information** (SNDK 2026-07-27 NO-GO, MU). EXTENDED a further −25.5%. Re-litigating on unchanged evidence is not a fresh event. |
| DUOL | Duolingo | Earnings — beat both lines; bookings growth decelerated to +7.9% and **revenue exceeded bookings for the first time in company history** | **−9.42%** | REJ (45) | ✔ | — | **65.3% reverted.** Consensus target $115.63 sits **BELOW** the $130.90 spot — SP6 ratified-at-cluster. BofA downgraded to Underperform $93. |
| INSM | Insmed | Clinical + earnings — 12-month TPIP PAH data (sustained efficacy, clean safety); peak-revenue reframe to **>$14B** across three lead programs | **+33.86%** | REJ (60) | ✔ | — | Largest gainer on the tape. Analyst targets ~$196.74 sit **far above** the $131.10 spot — the Street reads the move as insufficient, not excessive. Hard clinical information. UP mover. |
| UWMC | UWM Holdings | Earnings — rev $888M big beat, but GAAP EPS **−$0.23 vs +$0.08 cons**; consolidated net loss $451.9M; **$2.05B dilutive Oaktree equity investment announced same day** | **−38.46%** | — | ✔ | — | **FAILS the $2B floor — $1.94B.** Excluded. The Oaktree dilution, under-reported in headline wires, is the likelier driver than the EPS miss. |
| WRBY | Warby Parker | Earnings — rev $235.5M vs ~$238M (slight miss), adj EPS $0.04 vs $0.10 (**−60% miss**); FY reaffirmed | **−7.89%** | REJ (30) | ✔ | — | Real EPS miss + active-customer growth decelerating to 4.1%. Proportionate. Zero reversion. |
| Z | Zillow | Earnings — beat both lines, FY reaffirmed; but management **cut its industry view** to a low-to-mid-single-digit decline in purchase originations, and Q3 guided below cons | **−7.39%** | REJ (45) | ✔ | — | ≥5 downgrades (Bernstein, Evercore, Wells Fargo, Susquehanna) with targets **straddling** spot. Modest, defensible reaction. |
| SNDK | Sandisk | Earnings — rev $8.97B vs $8.39B (beat); **FQ1 guide $10.3–10.8B vs $11.16B cons** on a prolonged NAND glut | **−6.81%** | REJ (30) | ✔ | — | **50.5% reverted.** Arguably an *under*-reaction to a ~4% guide miss given the ~574% YTD run into the print. Cohort-adjudicated 2026-07-27. |
| NVMI | Nova | Earnings — record Q2 rev ~$255M (+16% YoY); fell on gross margin + in-line-vs-elevated-expectations | **−5.23%** | REJ (30) | ✔ | — | **55.6% reverted** — thin residual. Sector sympathy with WDC/SNDK. 4 PT cuts, all still above spot. |
| SITM | SiTime | Earnings — rev **+127% YoY** on AI-datacentre timing demand, guide raised | +26.58% | REJ (45) | ✔ | — | Real beat, ordinary in kind — a mid-cap guidance-raise repricing. |
| PAYC | Paycom | Earnings — EPS $2.78 vs $2.28, PT raise | +23.55% | REJ (45) | ✔ | — | Ordinary beat repricing. |
| CACI | CACI | Guidance — FY27 EPS $32.96–33.86 vs $28.16 cons | +21.38% | REJ (45) | ✔ | — | Large forward-guide raise; the counter-example to the day's guidance-punishment pattern. |
| CHYM | Chime | Earnings — second consecutive GAAP-profitable quarter, rev +27%, FY guide raised, against a CFO departure | +20.56% | REJ (45) | ✔ | — | Ordinary beat repricing. |
| MTSI | MACOM | Earnings — beat both lines | +14.49% | REJ (45) | ✔ | — | Semiconductor strength offsetting the software rout inside a flat-looking XLK. |
| MSI | Motorola Solutions | Earnings — beat with better-than-expected forward guidance | +8.20% | REJ (30) | ✔ | — | Ordinary large-cap repricing, no cross-holding or cohort read-through. |
| SPCX | (SpaceX) | Post-IPO lockup expiry of >900M shares | +6.14% | REJ (30) | ✔ | — | Float/supply mechanic, explicitly not a fundamental catalyst. |
| ALB | Albemarle | Earnings — beat both lines | +5.54% | REJ (30) | ✔ | — | Ordinary single-name earnings repricing. |
| BA | Boeing | Regulatory — FAA ordered inspections of ~471 737 MAX jets for fuselage cracks, effective 2026-09-10 | −3.33% | SIG (60) | ✗ | **✔** | Below spec floor. Dated regulatory action with a defined compliance deadline; second aerospace quality/supply item alongside HONA. |
| CVS | CVS Health | Fell despite an unambiguous beat AND raise across all three segments | −2.93% | SIG (45) | ✗ | **✔** | Below floor. **Already B NO-GO 2026-08-05.** Context only. |

### Event day 2026-08-05 — 7 days remaining (window closes 8/18)

| Ticker | Name | Event | Move | Verdict | L5 | BSF | Note / trajectory |
|---|---|---|---|---|---|---|---|
| **RRX** | Regal Rexnord | Earnings — **adj EPS $2.99, a +15.4% BEAT**; rev $1,558.4M vs ~$1,580M (**−1.4% miss**); **FY guidance REAFFIRMED** | **−16.72%** | **SIG (75)** | ✔ | — | **NEW.** 5.3× volume. **Zero reversion — EXTENDED to −19.11% cumulative** by 8/7 (220.04 → 178.00). ⭐ **Post-print analysts RAISED targets: Baird $253→$300, Citi $240→$260, KeyBanc $255→$265**; consensus ~$251 vs $178 spot (**+41%**). The sell-side actively raised into a −17% day — the exact inverse of SP1 ratification. **Ranked #1.** |
| **TDC** | Teradata | Earnings — adj EPS $0.69 vs $0.55 and rev $410M vs $396M (**BOTH BEAT**); **FY26 EPS guide RAISED** to $2.65–2.73; but Q3 EPS guided $0.55–0.59 vs $0.62 and Q3 rev −4 to −6% YoY | **−23.73%** | SIG (60) | ✔ | — | **NEW.** 5× volume. 14.2% reverted. Consensus ~$48 vs $27.39 spot (**+75%**). ⚠ Cap $2.58B and ADV $79M — smallest rankable name. **Ranked #4.** |
| **PODD** | Insulet | Earnings — rev $801.7M **+23.5% YoY beat**, adj EPS $1.66 vs $1.45 (**beat**); FY revenue-growth guide trimmed 21–23% → **20–22%**, US Omnipod 20–22% → 17–19% on T2D retention/utilisation | **−20.12%** | SIG (60) | ✔ | — | **NEW.** 6.5× volume. 23.6% reverted. Consensus fell 27% to ~$172 but still sits above the $141.17 spot. ⚠ The T2D retention datapoint is a disclosed demand signal — structurally the LII "residential unit volumes" objection that took LII to NO-GO. **Ranked #6.** |
| **EXTR** | Extreme Networks | Earnings — EPS $0.32 vs $0.30 beat, rev essentially in line; **initial FY27 guide implies growth slowing 13% → 8–9%** | **−19.02%** | SIG (45) | ✔ | — | **NEW.** EXTENDED a further −36.1%. Needham and Rosenblatt both cut but maintained positive ratings, targets above spot. Multiple compression on a forward-deceleration narrative. **Ranked #14.** |
| **NRG** | NRG Energy | Earnings — adj EPS $1.49 vs ~$1.78 (**miss**), rev $7.48B vs $7.79B (**miss**); adj EBITDA still +34% YoY; Texas segment EBITDA −25.6% | **−15.48%** | SIG (45) | ✔ | — | Event day 8/4. Barely retraced (**+5.1%**) — still near the post-print low. Double miss = information, though −15.5% against a +34% EBITDA print is somewhat outsized. **Ranked #13.** |
| CC | Chemours | Earnings — EPS $0.42 vs $0.50 and rev $1.59B vs $1.66B (**double miss**); GAAP net loss $274M | **−18.63%** | REJ (45) | ✔ | — | Cap $2.37B (clears). 34.7% reverted. Genuine double miss with a deepened GAAP loss = proportionate. |
| SEDG | SolarEdge | Earnings — Q2 beat; **Q3 rev guided $310–340M vs ~$371M cons** (~10%+ miss) | **−30.48%** | — | ✔ | — | **FAILS the $2B floor — $1.93B, narrowly.** Excluded. Would otherwise be a large item; worth re-checking if it recurs above the floor. |
| SPCX | (SpaceX) | Earnings — rev +92% YoY beat, but in-quarter capex ~2× QoQ (~$18.4B), into a lockup expiry | **−13.61%** | REJ (45) | ✔ | — | The AI-capex-payoff anxiety trade. Recent IPO, no established baseline. |
| PINS | Pinterest | Earnings — EPS $0.43 vs $0.36 and rev $1.18B vs $1.15B (**BOTH BEAT**); Q3 revenue guide in line | **−8.68%** | REJ (45) | ✔ | — | **Prior B NO-GO 2026-05-07 (SP1+SP3).** Consensus cut ~$35.41 → ~$23.81, i.e. **to the $23.68 spot** — ratified-at-cluster. 14.4% reverted. |
| MTCH | Match Group | Earnings — EPS $0.70 vs $0.92 and rev $853.1M vs $856.8M (**double miss**); paying users **−5.7% YoY to 13.3M** | **−7.49%** | REJ (45) | ✔ | — | A real, quantified KPI erosion — information, not optics. EXTENDED a further −28.8%. |
| AMD | AMD | Earnings — beat with Q3 guide raised, but lost the exclusive SpaceX compute socket to Nvidia | **−7.04%** | REJ (75) | ✔ | — | **B NO-GO 2026-07-27** flagged this exact Aug-4/5 print as an in-window binary. Durable competitive-position datapoint. |
| DVA | DaVita | Earnings — beat met with a ~9.4-sigma decline against a disclosed ACA-subsidy headwind | **−17.24%** | SIG (75) | ✔ | — | **B NO-GO 2026-08-05** (SP4a + SP3-negative, conviction 70). Context. |
| CVS | CVS Health | Earnings — EPS $2.58 vs $1.85 beat **plus** raised FY guidance, sold off | **−5.08%** | SIG (75) | ✔ | — | **B NO-GO 2026-08-05** (conviction 80) — preliminary FY27 EPS floor of $8.44 MET rather than beat consensus. Clears the frozen floor by 8bp on a correctly-measured close. Context. |
| SHOP | Shopify | Earnings — beat-and-raise, GMV +32%, Q3 gross-profit guide above cons | +16.98% | REJ (60) | ✔ | — | Clean ratification, explicitly not a mispricing. |
| MTRN | Materion | Earnings — EPS $1.90 vs $1.52, rev +42% YoY, FY raised | +30.81% | REJ (45) | ✔ | — | Large re-rating but a saturated up-move in a ~$6B name. |
| WTTR | Select Water | Earnings — rev $395.8M vs $374.5M, adj EBITDA +18.2% beat | +20.32% | REJ (30) | ✔ | — | Small-cap beat re-rating. |
| BKNG | Booking Holdings | Earnings — EPS $2.54 vs $2.41 beat, cost-savings target raised to ~$650M | +6.56% | REJ (45) | ✔ | — | Management flagged long-haul international travel still pressured by Middle East capacity. |
| UBER | Uber | Earnings — Q2 rev/EPS miss and soft Q3 gross-bookings guide | **−5.29%** | REJ (60) | ✔ | — | **Held Strategy D name.** Gross bookings +22% YoY keeps the D thesis's primary metric well above its ~15% floor. Not a B candidate. |
| OC | Owens Corning | Earnings — EPS $3.93 vs $3.09 (**+27% beat**), rev $2.76B vs $2.65B | +4.77% | SIG (45) | ✗ | **✔** | Below spec floor (published "+7.65%" was not the regular-session close). Context only. |
| LLY | Eli Lilly | Earnings — EPS $8.38 vs $6.01, FY revenue raised to $85–87B | +4.86% | SIG (60) | ✗ | **✔** | Would be a prime look but **misses the frozen 5% floor by 14bp**. Context only. |
| GFS | GlobalFoundries | Preliminary Q2 described as positive; tape disagreed | −4.92% | REJ (30) | ✗ | **✔** | Misses the floor by 8bp. |
| GOOGL | Alphabet | AI research-leadership exodus (Dean, Ghemawat, Vinyals, Le) | −4.03% | SIG (75) | ✗ | **✔** | Below floor. **Held in D**; its criteria are structurally blind to this risk class. |
| DIS | Disney | FQ3 beat, streaming profit doubled, buyback raised to ≥$9B | +3.65% | SIG (75) | ✗ | **✔** | Below floor. **Held in D** — invalidation criteria 2 and 3 affirmatively PASSED at their checkpoint. |
| ANET | Arista | Q2 beat (the Day-0 the 8/4 screen flagged as pending) | +3.57% | REJ (45) | ✗ | **✔** | Below floor. |
| NVDA | Nvidia | Sole Magnificent-Seven gainer on the SpaceX exclusivity | +3.43% | REJ (60) | ✗ | **✔** | Below floor; routed as an E candidate, not B. |
| WYNN | Wynn Resorts | Solid Macau results — mass drop +5%, $297M adj property EBITDA | +3.64% | REJ (30) | ✗ | **✔** | Below floor. |
| KHC | Kraft Heinz | Adj EPS $0.56, −18.8% YoY despite a revenue beat | −3.42% | REJ (30) | ✗ | **✔** | Below floor. |
| RARE | Ultragenyx | Record $214M revenue, guidance reaffirmed, overshadowed by setrusumab regulatory uncertainty (MHRA) | −3.41% | REJ (45) | ✗ | **✔** | Below floor. |

### Event day 2026-08-04 — 6 days remaining (window closes 8/17)

| Ticker | Name | Event | Move | Verdict | L5 | BSF | Note |
|---|---|---|---|---|---|---|---|
| BRKR | Bruker | Earnings — adj EPS $0.49 beat; **rev $838.5M vs $870.6M miss**; FY revenue guide **CUT** to ~$3.56B midpoint | **−21.79%** | REJ (60) | ✔ | — | A real guide cut overshadowing a wide EPS beat = information. 22.2% reverted. Cap $8.13B. |
| CTRI | Centuri | Earnings — −21.46% on a +33% revenue beat | **−21.46%** | SIG (75) | ✔ | — | **B NO-GO 2026-08-04** (PatternN + SP9-negative, conviction 75). Context. |
| APTV | Aptiv | Guidance — **FY26 revenue guide cut $300M at the midpoint**, Q3 EPS guide $1.30 vs $1.60 cons, on prolonged China weakness | **−16.62%** | REJ (60) | ✔ | — | Quantified guidance cut = information. 19.2% reverted. Cap $10.5B. |
| AIN | Albany International | Earnings — EPS $0.82 vs $0.71 beat, rev $329.5M vs $342.5M miss; FCF flipped to a −$14.5M use | **−16.16%** | — | ✔ | — | **FAILS the $2B floor — $1.78B.** Excluded. Notable shape: a single-quarter FCF swing drove −16% on an EPS beat, and even post-print consensus (~$56.67–60.25) sits **below** the $62.71 spot. Worth re-checking if it clears the floor. |
| CIFR | Cipher Mining | High-beta crypto/AI-datacentre name | **−15.65%** | REJ (45) | ✔ | — | No proportionality read available on the disclosed information. |
| NRG | NRG Energy | (see 8/5 table — event day 8/4) | **−15.48%** | SIG (45) | ✔ | — | Ranked #13. |
| CMG | Chipotle | Regulatory — salmonella outbreak; **Minnesota DoH: 110 cases, 75 of 84 interviewed ate at Chipotle; CDC: 345 cases across 27 states, 36 hospitalised**; company pulled jalapeños and changed suppliers | **−9.72%** | REJ (60) | ✔ | — | ⭐ **The 8/4 daily screen flagged that this attribution rested on a single social-media screenshot. It does not.** Primary state-health-department and CDC sourcing exists. Hard information. EXTENDED a further −28.3%. |
| INSP | Inspire Medical | Earnings — adj EPS $0.14 vs a −$0.22 consensus LOSS, rev $200.6M vs $194.7M; **FY26 EPS guide RAISED** $0.75–1.25 → $1.05–1.45 | **+22.83%** | — | ✔ | — | ⚠ **D1 logged this as −6.31% — the wrong session.** See MEASUREMENT FINDINGS above. **FAILS the $2B floor — $1.74B**, so no routing changes. 33.4% of the pop has since faded. |
| PLTR | Palantir | Earnings — beat-and-raise, FY26 guide lifted to $8.15–8.16B from $7.65–7.66B | +29.45% | REJ (75) | ✔ | — | It *was* the tape — carries a large share of XLK +4.98% alone. UP mover. |
| PAY | Paysafe | Earnings — rev +28.8% YoY, FY26 EBITDA guide raised | +29.20% | REJ (45) | ✔ | — | ~$4B cap where a 29% single-day re-rating is within the normal event range. |
| ZBRA | Zebra Technologies | Earnings — adj EPS $6.35 vs $4.35, FY26 raised | +26.47% | REJ (60) | ✔ | — | Large mid-cap re-rating, saturated up-move. |
| IT | Gartner | Earnings — adj EPS $4.37 vs $3.77, FY26 guide raised to $14.00 from $13.25 | +22.61% | REJ (60) | ✔ | — | Same beat-and-raise re-rating profile. |
| SNAP | Snap | Earnings — consensus was a loss; company printed a beat with positive FCF on World Cup ad spend | +14.88% | REJ (60) | ✔ | — | Genuine surprise, but an UP mover. |
| INTC | Intel | Sector risk-on / short-covering after a 24% monthly slide | +10.84% | REJ (30) | ✔ | — | No distinct same-day company event. A-queue name. |
| SMCI | Super Micro | AI-hardware sector rally | +10.65% | REJ (30) | ✔ | — | No name-specific headline. **Prior B NO-GO 2026-07-22 (SP4d+SP1).** |
| MU | Micron | Memory/chip complex | +7.62% | REJ (30) | ✔ | — | No name event. |
| AMD | AMD | Chip-complex rally; own print landed after this close | +7.00% | REJ (45) | ✔ | — | Setup day; its Day-0 is 8/5. |
| CAT | Caterpillar | Earnings — largest beat in five years, record $63B backlog, power/energy +29% YoY on data-centre demand | +5.60% | REJ (75) | ✔ | — | Second engine of the record Dow close. **SP1 cleanest-L1 benchmark name.** |
| NVO | Novo Nordisk | Guidance disappointment | **−5.97%** | REJ (45) | ✔ | — | **Foreign-domiciled ADR → instrument-eligibility fail.** Mechanical exclusion, no criteria 2–5 analysis. |
| FANG | Diamondback | Macro — Brent −5.3% on US-Iran/Hormuz diplomatic optimism | −3.46% | REJ (45) | ✗ | **✔** | Below floor; sector beta, not a name event. Cap $53.7B. |
| NKE | Nike | JPMorgan downgrade to Underweight, PT $47→$40 | −2.60% | SIG (45) | ✗ | **✔** | Below floor. Adverse to the open `rescreen-NKE-D-20260925` trigger. |
| ANET | Arista | Regular-session move preceding its after-close beat-and-raise | +3.04% | REJ (45) | ✗ | **✔** | Below floor; Day-0 is 8/5. |

### Event day 2026-08-03 — 5 days remaining (window closes 8/14)

| Ticker | Name | Event | Move | Verdict | L5 | BSF | Note |
|---|---|---|---|---|---|---|---|
| ATKR | Atkore | M&A — definitive all-cash takeout at $95/sh by Prysmian | +28.10% | REJ (75) | ✔ | — | Deal-arb, terminal for the name. Hard exclude. |
| ITGR | Integer Holdings | M&A — **KKR to acquire at $127.00/sh cash**, ~$5.7B EV, announced pre-market | **+20.19%** | REJ (75) | ✔ | — | **MISSED BY D1** (wires reported only the +2.5–2.7% premarket print; the full-day close-to-close was +20.19% as the stock converged to the deal price). Deal-arb — no fundamental convergence to harvest. |
| CRWV | CoreWeave | AI-infra complex repricing after the MSFT/AMZN prints | +19.50% | REJ (60) | ✔ | — | Cohort read, not a name event. |
| SRAD | Sportradar | Guidance — FY26 EBITDA-growth guide cut −28% relative | **−15.10%** | SIG (60) | ✔ | — | **B NO-GO 2026-08-03** (SP4c + PatternN, conviction 78). Context. |
| GME | GameStop | Other-corporate — **private exchange of $1.4B convertible notes for common stock** | **−12.25%** | REJ (45) | ✔ | — | $1.4B against an ~$8.6B cap is a real, quantifiable dilution overhang. Mechanical supply, not sentiment. 3.8% reverted. Formal sell-side coverage too thin to verify. |
| TGTX | TG Therapeutics | Earnings — revenue beat against a large EPS miss | **−11.30%** | SIG (45) | ✔ | — | **B NO-GO 2026-08-03** (conviction 65) — the R&D-ramp explanation was disclosed pre-market before the move completed. Context. |
| ONDS | Ondas | Corporate action + guide hike | +11.70% | REJ (45) | ✔ | — | Name with a history of promotional guidance. |
| SOFI | SoFi | Earnings — strong clean beat | +10.50% | REJ (45) | ✔ | — | Positive-direction print into an already-recovered name. |
| FSLR | First Solar | Analyst wave — Citi →$297, Guggenheim →$282 following the 7/30 Q2 beat (EPS $3.92 vs ~$2.95), plus positioning into a pending Section 232 decision | **+10.28%** | REJ (45) | ✔ | — | **MISSED BY D1.** Delayed rally on PT hikes = canonical SP1 ratification. Cap $25.0B. |
| ORCL | Oracle | AI-cloud sympathy | +9.30% | REJ (45) | ✔ | — | No name-specific event; on the A queue. |
| AZN | AstraZeneca | Mega-cap pharma combination-talk speculation, confirmed cross-sectionally by BMY moving opposite | **−9.00%** | REJ (60) | ✔ | — | **Foreign-domiciled ADR → instrument-eligibility fail.** |
| IREN | IREN | Guidance raise to a $4B 2026 revenue target | +8.00% | REJ (45) | ✔ | — | **Prior B NO-GO 2026-07-20 (SP1+SP3).** |
| SNAP | Snap | Earnings — consensus loss, printed a profit | +7.70% | REJ (60) | ✔ | — | Largest true earnings surprise on the tape; UP mover. |
| INDV | Indivior | **All-stock "merger of equals" with Supernus** (INDV holders ~56.5% of combined co.) alongside a Q2 beat (EPS $1.15 vs $0.92) | **−6.60%** | REJ (60) | ✔ | — | **MISSED BY D1.** Fell despite the beat, but price is now anchored to merger arithmetic — deal-anchored, mechanism mismatch for B. Cap $4.6B. |
| ISRG | Intuitive Surgical | 6.25% move on a $134B mega-cap with no discrete public event | +6.25% | SIG (60) | ✔ | — | **Held in BOTH B and D.** Not a new-entry candidate. |
| BMY | Bristol Myers | The cross-sectional confirmation leg of the AZN combination report | +6.00% | REJ (60) | ✔ | — | Both legs moving correctly is what made the report credible. |
| AAL | American Airlines | Mechanical read-through of the day's oil move | +5.00% | REJ (45) | ✔ | — | Not name-specific. |
| MSFT | Microsoft | Proximate driver of the tech complex | +4.90% | SIG (60) | ✗ | **✔** | Below floor. |
| AMZN | Amazon | AWS +37% YoY follow-through | +4.60% | SIG (60) | ✗ | **✔** | Below floor. **Held in D** (2 tranches). |
| GOOGL | Alphabet | TPU v9 capacity reports | +4.34% | REJ (45) | ✗ | **✔** | Below floor. **Held in D** (2 tranches). |
| SUPN | Supernus | Merger of equals with Indivior + Q2 revenue beat (+32.4% YoY to $219.1M) | +3.07% | REJ (30) | ✗ | **✔** | Below floor. A circulated "+24.9%" headline measured to **+3.07%** — intraday high only reached +17.6%. Deal-anchored regardless. |
| NVDA | Nvidia | AI-complex beta | +2.90% | REJ (30) | ✗ | **✔** | Below floor. |
| PLTR | Palantir | Pre-print drift | +2.10% | REJ (45) | ✗ | **✔** | Below floor; the print landed after this close. |

### Carry-forward — event days 2026-07-27 → 07-31 (1–4 days remaining)

Screened in full last cycle; carried here with updated trajectory through the 2026-08-07 close. **The informative change is how much of each reaction has since reverted.** Every name below is either already adjudicated or has too little window left to construct and stage a thesis under the DNA — none is offered as a new candidate, and 7/27 events have **expired** (day 10 was 8/7).

| Ticker | Event day | Event-day move | Status | Trajectory through 8/7 |
|---|---|---|---|---|
All 8/7 closes below are **IBKR regular-session bars, measured this run**; event-day moves are carried forward verbatim from last cycle and not re-derived. `% reverted` = how much of the event-day move has retraced by the 8/7 close (negative = the move EXTENDED further).

**The names the market held hardest** — these are the ones whose reactions have *not* been retracted, and the contrast is the point of this table:

| Ticker | Event day | Event move | 8/7 close | Cum. since event | % reverted | Status / new information since 2026-08-03 |
|---|---|---|---|---|---|---|
| **LII** | 7/29 | −20.97% | 439.77 | −19.18% | **9%** | **ADJUDICATED** (B NO-GO 2026-08-03, SP4c, 78). **No new information found.** Last cycle's #1-ranked candidate is still essentially un-reverted six sessions on — the de-rate has held completely. |
| **CARR** | 7/28 | −8.90% | 64.01 | −7.67% | **14%** | **ADJUDICATED** (NO-GO, SP4a+PatternN, 72). No new information. Also still un-reverted. **Window expires 8/10 (1 day).** |
| MTZ | 7/31 | −18.91% | 272.46 | −16.02% | 15% | **CLOSED** — B GO 2026-08-03, exit staged same session on invalidation criterion 3 (bear-cluster, n=5), filled 2026-08-04. |
| ALNY | 7/30 | −28.31% | 219.20 | −23.52% | 17% | **ADJUDICATED** (NO-GO 2026-07-30). ⚠ **New:** securities-fraud investigation opened 8/4 + H.C. Wainwright PT $485→$455. The market's conviction now has a fresh reason behind it. |
| RBLX | 7/31 | −26.85% | 37.79 | −22.35% | 17% | Un-adjudicated but not advanced: FY guidance WITHDRAWN + Q3 bookings −14/−18% is decisive information, ratified by a one-directional sell-side wave. ⚠ **New:** EU DSA "Very Large Online Platform" designation expected Aug 2026 — a live incremental overhang. |
| VCYT | 7/31 | −22.52% | 47.22 | −21.01% | 7% | **ADJUDICATED** (NO-GO, SP4a+PatternN, 78). None found. |
| ALHC | 7/31 | −20.20% | 14.37 | −22.78% | **−13% (EXTENDED)** | **ADJUDICATED** (NO-GO, SP4d, 78). ⚠ **New:** two securities-fraud investigations opened (8/4, 8/6). |
| AAPL | 7/31 | −7.36% | 313.33 | −6.03% | 18% | **ADJUDICATED** (NO-GO, SP4c+PatternN, 78). None found. |
| BTSG | 7/31 | −18.07% | 62.43 | −14.34% | 21% | **ADJUDICATED** (NO-GO, SP1+SP5c, 78). |
| GDDY | 7/31 | −16.70% | 91.07 | −8.32% | 50% | **ADJUDICATED** (NO-GO, SP4b+SP3, 65). Half the gap now closed. |
| COIN | 7/31 | −10.58% | 153.60 | −6.10% | 42% | Un-adjudicated; wide GAAP miss with revenue −18.5% YoY = information. ⚠ **New:** a federal judge rejected COIN's bid to block Michigan enforcement against Kalshi prediction-market contracts (**8/7**) — a fresh adverse legal datapoint on a growth bet. |
| RIVN | 7/31 | −9.57% | 16.00 | −4.93% | 48% | **ADJUDICATED** (NO-GO 2026-07-05). |
| PSN | 7/29 | −35.00% | 47.55 | −23.34% | 33% | **ADJUDICATED** (NO-GO 2026-07-29). ⚠ **New:** securities-claims investigation opened 8/4. |

**Fully round-tripped or overshot — nothing left to harvest:**

| Ticker | Event day | Event move | 8/7 close | Cum. since event | % reverted | Note |
|---|---|---|---|---|---|---|
| **VRT** | 7/29 | −17.26% | 272.40 | **+1.05%** | **106%** | **ADJUDICATED** (NO-GO 2026-08-03, SP6-negative, 85). ⭐ The gap has now fully closed **and gone positive** — the 2026-08-03 NO-GO reasoning ("79% already retraced, residual does not justify a slot," citing the DHR precedent) is **confirmed correct by outcome**. A useful calibration datapoint: the residual-too-thin test worked. |
| GLW | 7/28 | −12.10% | 165.68 | +15.57% | 229% | Fully reversed and well past the pre-event level. NO-GO 2026-07-28 (SP6-negative) likewise vindicated. |
| MRNA | 7/31 | −5.35% | 59.17 | +2.16% | 140% | ⚠ **New and material:** the FDA approved Moderna's **mFLUSIVA, the first-ever mRNA flu vaccine**, on 2026-08-06. Last cycle recorded MRNA as an attribution failure ("no catalyst identified in any source"); the subsequent approval explains the round trip. |
| META | 7/30 | −7.96% | 592.10 | +1.11% | 114% | Fully reverted. |
| MU | 7/31 | −5.90% | 877.57 | +0.33% | 106% | Memory cohort; fully reverted. |
| HUM | 7/29 | −5.99% | 385.00 | −0.95% | 84% | Morgan Stanley double-notch upgrade (Underweight→Equal-Weight, PT $249→$370). |
| SANM | 7/28 | −17.46% | 202.73 | −2.95% | 83% | NO-GO 2026-07-28 (SP6-negative); 83% retraced. |
| REPL | 7/31 | +127% (see below) | 12.06 | +122.92% | 3% | ⚠ **The SP5 in-window binary the last cycle flagged as unrankable has RESOLVED FAVOURABLY:** FDA granted accelerated approval to Tudriqev (RP1) on 2026-08-07. Still fails the cap floor. |

**⚠ TWO CORRECTIONS TO THE PRIOR CYCLE'S FILE**, surfaced by re-measurement:

1. **CBZ was misclassified as an organic re-rating.** Last cycle recorded CBZ's +17.6% (7/29) as a genuine re-rating on raised guidance. In fact **CBIZ agreed to be acquired by Grant Thornton Advisors at $55.00/sh cash, announced 2026-07-28 — the session before that "event day."** The 8/7 close of $54.50 sits just under the offer, the classic deal-arb pin (go-shop runs to 8/27). CBZ belongs in the **deal-arb exclusion bucket alongside MKTX**, not in the candidate population. Corrected here; carried forward so next cycle does not repeat it.
2. **CCJ's event date does not match the bars.** Last cycle recorded CCJ at **+4.30% on 7/31**. IBKR's 7/30→7/31 close-to-close is **−2.10%**; the +4.30% figure matches the **7/29→7/30** session instead. This is the *same wrong-session-selection class* as the INSP finding above, now observed twice in one run — which is the argument for treating it as a pattern rather than a one-off. CCJ was below-spec-floor context only, so nothing downstream depended on it.
   Related, unresolved: **REPL's stated +127%** computes to **+107%** from the last non-halted prior close (7/29 $5.41 → 7/31 $11.20; 7/30 printed zero volume, presumably halted pending the adcom vote). Carried as stated, gap flagged for a future session.

**Other carry-forward names** (AMZN, IESC, AXTI, MPWR, DXCM, NWL, CDNA, PRM, AMBA, MKTX, BHC, MANH, GRMN, GEHC, HURN, FTV, NBIS, PPG, LAD, EXLS, AVTR, LMND, AMKR, CVLT, IQV, SHW, UPS, KO, ITRI, KNSA, LCID, JBLU, INTC, SKHY, INFY, TSM, NVO, MSFT, AMAT) are held positions, deal-anchored, cap-floor or ADR instrument failures, cohort/sector beta, already adjudicated, or have reverted past the point of usefulness. **None is advanced.** Notable new overhangs recorded for the factbase: fresh securities investigations opened on **CVLT** (8/4) and **MANH** (8/5–8/6); **WU** jumped ~11% on 2026-08-04 on a reported private-equity take-private approach just below $10/sh plus a strategic review — which moves WU out of the post-event population and into **deal-anchored** territory for any future cycle.

**Bottom line for this sub-table:** no carry-forward name is advanced to PART 2. Every one is adjudicated, expired, deal-anchored, or has 1–4 days of window remaining — too little to construct and stage a thesis under the DNA. The value here is calibration: **the two most-held names (LII 9%, CARR 14% reverted) were both NO-GO'd anyway, and the name that fully round-tripped (VRT, 106%) was NO-GO'd precisely for having already retraced** — the residual-thinness test made the right call in all three directions.

### Examined and EXCLUDED (with reason)

- **Deal-anchored / acquisition-probability pricing — mechanism mismatch for B** (PYPL 7/15, MGM 2026-06-01, MKTX 7/30 precedents): **ITGR** (+20.19%, KKR $127/sh cash definitive), **ATKR** (+28.10%, Prysmian $95/sh), **INDV** and **SUPN** (all-stock merger of equals). Price is pinned to deal arithmetic; there is no fundamental convergence to harvest and no admissible 60-day convergence target.
- **Below the $2B market-cap floor:** **UWMC** ($1.94B, −38.46%), **SEDG** ($1.93B, −30.48% — narrowly), **AIN** ($1.78B, −16.16%), **INSP** ($1.74B, +22.83%), **ATLC** (~$1.65B, −10.54%), **FIGS** (~$1.5B), **PLTK** (~$1.1–1.5B). SEDG and AIN are the two genuinely large moves lost to the floor this cycle and are worth re-checking if either recurs above it. **UAA** ($1.5–2.9B across sources on dual-class counts) is flagged UNVERIFIED rather than silently included or dropped.
- **Foreign-domiciled — instrument-eligibility fail** (US-listed common equity only): **NVO** (−5.97%), **AZN** (−9.00%), **BTG** (+22.98%, Canadian).
- **UP movers — LONG framing structurally inappropriate, SHORT foreclosed by Rev 36 long-bias:** TEAM, TWLO, DOCS, INSM, NTRA, HALO, ABNB, SHOP, PLTR, SNAP, ZBRA, IT, PAY, SITM, PAYC, CACI, CHYM, MTRN, WTTR, FLR, OKLO, DKNG, LYFT, TTWO, NET, CAT, SOFI, ORCL, IREN, BMY, MSI, MTSI, ALB. Recorded for completeness; the router activates B only in regimes where fading a pop runs into momentum and squeeze risk, and 0 of ~108 B theses have ever produced a short entry.
- **Reaction already substantially retraced — residual too thin to justify a slot** (DHR 2026-07-27 precedent, NO-GO'd at 79% retraced; VRT 2026-08-03 at 86–99%): **CELH** (74.3% reverted), **DUOL** (65.3%), **NVMI** (55.6%), **SNDK** (50.5%).
- **Sector/cohort beta or already-adjudicated cohort — criterion-1 attribution fail:** the **memory/NAND de-rate** (WDC, SNDK across 8/6–8/7; MU) — a theme D2 adjudicated as information on 2026-07-27, and re-litigating it on unchanged evidence is not a fresh event; the **AI-infra complex** (CRWV, IREN, CIFR, SPCX); **FANG** and **LNG** (Brent/energy rotation); **QCOM, SNOW, INTC, SMCI, NVDA** (tape beta with no name event).
- **Held positions — not offered as new entries:** ISRG and MSCI (open B); AMZN, CRM, DIS, GOOGL, GEV, RTX, TSM, UBER (open D).
- **Already adjudicated this cycle** (context, not candidates): DVA, CVS, CTRI, SRAD, TGTX, AAPL, GDDY, LII, CARR, VRT, RDDT, VCYT, ALHC, BTSG, MTZ.
- **Prior NO-GO on the same shape, re-rejected rather than re-litigated:** **APP** (2026-07-20 SP1 — that entry explicitly named this Aug-5 print as "an in-window ratification binary," and it has now landed exactly as predicted), **TEAM** (2026-05-02 SP6 — the eponymous pattern), **TWLO** (2026-05-02 SP1), **PINS** (2026-05-07 SP1+SP3), **AMD** (2026-07-27), **SMCI** (2026-07-22), **IREN** (2026-07-20), **NET** (2026-05-13).

---

## PART 2 — Ranked shortlist (priority for W4 → `PENDING_ANALYSIS` thesis-construction)

**Default assumption: the market reaction is correct.** A thesis must affirmatively establish an over- or under-sized reaction versus fundamental implications — grounded in event details, recent fundamentals, and comparable historical reactions **retrieved, not recalled** — and survive criterion 4 (information-driven ⇒ correct pricing, not mispricing). Only PART-1 entries clearing **both** the §19 significance judgment **and** B's frozen ≥5% spec floor are rankable; `below_spec_floor` rows are not here.

**🔴 Every candidate below is gated by the DO-NOT-ACTIVATE regime state.** Rank order is research priority, not a staging instruction.

**Criterion-3 note covering the ENTIRE cohort (verified, see gating section):** no candidate reports before ~2026-10-09, so **no admissible event-marker convergence target exists for any of them**. Every thesis here requires a **NUMERICAL price target**.

**Retrieved precedent covering the whole top tier.** `analytics.find_precedents()` on the dominant shape in this cohort — *"beats earnings and raises guidance but collapses on forward spending or guidance composition, no reversion"* — returns **10 of 10 NO-GO**, led by ZS (0.277, SP6), BBY (0.284, SP8+SP3), BE (0.286, SP1), ORCL (0.291, SP6+PatternN), BBWI, CHWY, INTC, GTLB, SJM, PINS. The recurring decisive flaw is **SP6 — valuation reset, not narrative reset**: the market re-rates the multiple on a forward-growth datapoint, the sell-side cuts targets *to* the new price, and there is no asymmetric mean-reversion anchor left. **A thesis session on any name below must defeat SP6 specifically.** The single strongest discriminator available is whether the post-print sell-side **raised** targets (leaving an anchor well above spot) or **cut them to spot** (ratifying the new level). That test is applied explicitly to every candidate below.

### TOP-5 tier

**1. RRX — Regal Rexnord** · −16.72% (8/5) · **window closes 8/18 → 7 trading days**
- **(a) Hypothesized mispricing: LONG over-reaction — the cleanest reaction-to-information mismatch in the window.** Adjusted EPS of **$2.99 beat by 15.4%**, revenue missed by **~1.4%** ($1,558.4M vs ~$1,580M), and **full-year guidance was REAFFIRMED, not cut**. The stock fell 16.72% on 5.3× volume and has since **extended to −19.11% cumulative** (220.04 → 178.00) with **zero reversion**.
- **(b) Supporting public information — and the discriminator that puts it first.** Post-print the sell-side **RAISED** targets into the decline: **Baird $253→$300, Citi $240→$260, KeyBanc $255→$265**, consensus ~$251 against a $178.00 spot (**+41%**). This is the *inverse* of the SP1 ratification signature and the direct opposite of the SP6 pattern that killed the 10-of-10 precedent cohort — the sell-side did not re-rate the name down to the new price, it marked it up while the tape marked it down. Cap $11.85B, ADV ~$193M — comfortably inside the rails.
- **(c) Convergence indicators to watch:** whether any firm migrates a target to or below spot (bear cluster forming → PatternN); whether the ~1.4% revenue miss is followed by a second soft top line (resolves outside the window → numerical target mandatory); stabilization versus the $176.65 (8/7) intraday low; whether the reaffirmed guide is quietly walked back in any 8-K or conference appearance inside the window.
- **(d) Days remaining: 7.**
- **(e) Tier: top-5 (#1).** Largest gap between what was disclosed (a beat with guidance intact) and what the tape did (−19% and still falling), with the one sell-side signature that most reliably separates a genuine over-reaction from a ratified de-rate. **Named risk:** an EPS beat driven by below-the-line items against a revenue miss can mask deteriorating organic demand — a thesis session must decompose the beat before trusting it, because "reaffirmed guidance" is exactly what SP4a names get to say one quarter before they cut.

**2. BROS — Dutch Bros** · −18.79% (8/6) · **window closes 8/19 → 8 trading days**
- **(a) Hypothesized mispricing: LONG over-reaction on a clean beat-and-raise.** Revenue $550.9M beat by 4.7%, adjusted EPS $0.33 vs $0.29, and **FY revenue, same-shop comps AND EBITDA guidance were all RAISED**. The stock fell 18.79% on **9.5× volume** and has **not reverted at all** (a further −0.60% on 8/7; cumulative −19.28%).
- **(b) Supporting public information:** the bear case is specific and real — management guided **H2 comp deceleration** and capex came in **27% above expectations**. Against that, the Street stayed 20-of-24 Buy with a median target of **~$78–80 against a $53.01 spot (+47–51%)**, i.e. no ratification wave. Cap $9.16B, ADV ~$194M.
- **(c) Convergence indicators:** whether the H2 comp guide is confirmed or beaten at the next datapoint (outside window → numerical target); whether the capex overshoot is framed as unit-growth investment or margin leakage; any first downgrade to/below spot; recovery toward the $65.67 pre-event level versus settling in the low $50s.
- **(d) Days remaining: 8.**
- **(e) Tier: top-5 (#2).** Ranked below RRX only because BROS's bear case (comp deceleration at a premium-multiple growth name) is *precisely* the SP6 valuation-reset mechanism the precedent cohort says wins, whereas RRX's sell-side actually raised. **Named risk:** a 27% capex overshoot at a unit-growth concept is not a one-quarter item, and the market may be correctly pricing a slower, costlier growth curve.

**3. DDOG — Datadog** · −19.03% (8/6) · **window closes 8/19 → 8 trading days**
- **(a) Hypothesized mispricing: LONG over-reaction on a beat-and-raise across every headline metric.** Revenue $1.12B beat (+36% YoY), non-GAAP EPS $0.65 beat by 11–33%, and **FY26 guidance was RAISED** to $4.45–4.47B. The stock fell 19.03% on 4× volume; only **8.6% has reverted**.
- **(b) Supporting public information:** analysts **raised** targets post-print — **Citi to $305 explicitly framed as "buy the dip," DA Davidson reaffirmed Buy $315, Scotiabank $275→$285** — with a 35-analyst consensus of ~$265–279 against a $233.93 spot (+13–19%). That is the same non-ratification discriminator that ranks RRX first.
- **(c) Convergence indicators:** whether the disclosed **largest-customer usage decline** is one-quarter or the start of a concentration problem; whether FCF margin stabilises off the 29%→25% step-down; whether the cohort's recovery pulls it back.
- **(d) Days remaining: 8.**
- **(e) Tier: top-5 (#3), with two explicit warnings.** ⚠ **First**, the customer-concentration disclosure is an **AI-capex demand-quality objection** — a more durable class than multiple compression, and structurally the same objection that produced NO-GOs on AMKR, GLW, SANM and GOOGL. ⚠ **Second, and more damaging: D1's own 8/7 note records that DDOG recovered only 2.02% while its software cohort rallied double digits — the tape did NOT retract the objection when given the chance.** That is close to a direct refutation of the over-reaction read, and a thesis session should treat it as the primary obstacle. Prior B NO-GO 2026-05-12 (SP1) is a different event and does not bar re-evaluation.

**4. TDC — Teradata** · −23.73% (8/5) · **window closes 8/18 → 7 trading days**
- **(a) Hypothesized mispricing: LONG over-reaction — the widest gap between the annual and quarterly signal.** Adjusted EPS $0.69 vs $0.55 and revenue $410M vs $396M **both beat**, and the company **RAISED its FY26 adjusted-EPS guide** to $2.65–2.73. The stock fell 23.73% on 5× volume; 14.2% has reverted.
- **(b) Supporting public information:** the bear case is a **Q3-specific** step-down — adjusted EPS guided $0.55–0.59 vs $0.62 consensus and Q3 revenue guided **−4% to −6% YoY**. Citigroup cut $39→$36 but **maintained Buy**, and broader consensus sits ~$48 against a $27.39 spot (**+75%**, the widest in the cohort).
- **(c) Convergence indicators:** whether the Q3 softness is timing (contract slippage) or demand; whether the raised FY guide survives the next update; whether any target migrates below spot.
- **(d) Days remaining: 7.**
- **(e) Tier: top-5 (#4).** The "FY raised, quarter soft" split is a genuinely unusual shape and the raised annual guide is hard to dismiss as sentiment. ⚠ **Ranked fourth on capacity, not on shape:** at **$2.58B cap and ~$79M ADV** this is the smallest and thinnest rankable name, and a −4 to −6% YoY revenue quarter at a company already shrinking is a real deterioration signal, not a composition quirk.

**5. SEZL — Sezzle** · −33.89% (8/7) · **window closes 8/20 → 9 trading days**
- **(a) Hypothesized mispricing: LONG over-reaction — the largest raw magnitude mismatch in the entire window.** Revenue $149.7M beat by ~10%, adjusted EPS $1.13 beat, and **FY guidance was RAISED on all three lines** (growth to 35%, adjusted net income to $185M, EPS to $5.25). The stock fell **33.89%** on 11× volume.
- **(b) Supporting public information — and why this is fifth and not first.** Three facts cut hard against the over-reaction read, and a thesis session must clear all three. **(i)** Management guided **H2 revenue growth to ~30% against Q2's 51.7%** and flagged **revenue-yield normalisation to ~11.4%** — that is quantified, company-supplied forward information, the exact CVS-shaped "management itself supplied the bear case" flaw that produced a conviction-80 NO-GO on 2026-08-05. **(ii)** The **President and CFO both sold stock in the preceding week**. **(iii)** The 8/7 session **opened at 132.36, which was also the session high, and closed at 118.02 near the 114.16 low** — a one-way tape with no bid at any point, which is the trading signature of conviction repricing rather than a panic that got bought. Sell-side split: B. Riley reiterated Buy, KBW downgraded to Market Perform.
- **(c) Convergence indicators:** whether the yield normalisation proves conservative; whether insider selling continues or reverses; whether a bid appears at all (the first up-session on volume would be the earliest real evidence); whether KBW's downgrade broadens into a cluster.
- **(d) Days remaining: 9** — the longest runway in the cohort, which matters here because this is the name most in need of a session or two of hold-versus-fade evidence before anyone acts.
- **(e) Tier: top-5 (#5), marginal.** Included over PODD purely on magnitude and runway; the +150% YTD run into the print, the insider selling and the self-supplied guidance make this the most likely of the five to resolve as information. Also the thinnest top-5 name at ~$79M ADV.

### REST tier

**6. PODD — Insulet** · −20.12% (8/5) · closes 8/18 → **7 days** · cap $9.78B
Beat both lines (revenue +23.5% YoY, adjusted EPS $1.66 vs $1.45) against a **1–2 percentage-point** FY guide trim. Consensus fell 27% to ~$172 but still sits above the $141.17 spot; 23.6% reverted. ⚠ **The reason it is not top-5:** the trim was attributed to **type-2-diabetes retention and utilisation**, which is a disclosed *demand* signal — structurally identical to LII's "−12% YoY residential unit volumes," the exact evidence that took LII to a conviction-78 NO-GO six days ago. Distinguish it from that precedent or expect the same outcome.

**7. DAVE — Dave Inc** · −15.09% (8/6) · closes 8/19 → **8 days** · cap ~$3.4–4.6B
Beat ($4.12 vs $3.67), revenue +30% YoY, **guidance raised** — sold on a planned H2 marketing/CAC step-up. Then **extended a further −12.96% on 8/7** for a **−26.09% two-session cumulative with zero reversion**. Missed by the daily screen. ⚠ A deliberate, management-announced spending increase is company-supplied forward information, and the second-day extension says the market did not treat it as an over-reaction. Cap disputed across sources.

**8. PTON — Peloton** · −15.64% (8/6) · closes 8/19 → **8 days** · cap $2.37B (clears narrowly)
Beat both lines and posted its **first full profitable fiscal year**; the FY27 guide implying −3.9% simply reflects lapping a known price increase. 28-analyst consensus ~$8.03–8.40 vs a $5.68 spot. ⚠ Paid subscriptions are still **−8.8% YoY** — a multi-year structural subscriber decline that no single quarter's profitability reverses, and the name sits just above the cap floor.

**9. HUBS — HubSpot** · −19.09% (8/6) · closes 8/19 → **8 days** · cap $10.77B
Beat every headline line (revenue $911.7M vs $898.3M; non-GAAP EPS $3.26 vs $3.02) yet posted the **steepest single-day drop in company history**, with the CEO conceding "the quarter we expected did not fully materialize." ⚠ **Ranked here rather than top-5 because it carries the full SP6 signature:** net customer adds guided down **9–10k → 5–6k** (a real, quantified forward cut, not composition) and **≥6 downgrades landed with new targets at or near spot** (Bernstein $381→$220, Piper →$220, BMO →$215). Sell-side ratification at the new level is exactly what removes the mean-reversion anchor.

**10. FIG — Figma** · −14.85% (8/6) · closes 8/19 → **8 days** · cap $11.35B
Revenue +48% YoY above its own guide with FY guidance **raised $40M**, and zero reversion (a further −2.8% on 8/7). Consensus ~$37 vs $23.29. ⚠ Three strikes: **prior B NO-GO 2026-05-18 (SP5c lockup-supply binary)**, a **recent IPO with no established volatility baseline** (the standing SPCX/FIG exclusion class), and a Q3 guide implying deceleration from 48% to 36%.

**11. POST — Post Holdings** · −12.79% (8/7) · closes 8/20 → **9 days** · cap ~$3.6–4.3B
FQ3 revenue $1.94B vs $2.03B consensus and net earnings −41.7% YoY, on 6.4× volume. Missed by the daily screen. ⚠ A clean top-line miss with sharply lower earnings is information by construction; ranked only because the magnitude is large for a defensive staples name and the full 9-day window is intact.

**12. FOUR — Shift4 Payments** · −18.77% (8/6) · closes 8/19 → **8 days** · cap $3.76B
Beat both lines but **cut FY26 adjusted EPS guidance** to $5.15–5.35 from $5.50–5.70, against ~$5.41 consensus. Zero reversion (a further −4.84% on 8/7). ⚠ An explicit, quantified forward guide cut below consensus is the textbook information case; listed for completeness rather than as a live prospect.

**13. NRG — NRG Energy** · −15.48% (8/4) · closes 8/17 → **6 days** · cap $24.92B
Double miss (adjusted EPS $1.49 vs ~$1.78; revenue $7.48B vs $7.79B) though adjusted EBITDA still grew 34% YoY. Barely retraced (+5.1%) — still near the post-print low. ⚠ Texas segment EBITDA −25.6% is a real regional deterioration; the −15.5% against a +34% EBITDA print is the only genuinely disproportionate element.

**14. EXTR — Extreme Networks** · −19.02% (8/5) · closes 8/18 → **7 days** · cap $3.13B
EPS beat with roughly in-line revenue; the decline is a response to an **initial FY27 guide implying growth slowing from 13% to 8–9%**. Needham and Rosenblatt both cut targets while maintaining positive ratings, leaving targets above spot. ⚠ Extended a further −36.1% — the market is not retracting the deceleration read.

**15. HONA — Honeywell Aerospace** · −23.16% (8/6) · closes 8/19 → **8 days** · cap $53.41B
First standalone print since the 2026-06-29 spin. ⚠ Ranked last despite the large magnitude because the information is unambiguous and quantified: **FY26 organic growth guided down from 7–9% to 4–5%** and adjusted EPS to $7.60–7.90 against ~$8.86 consensus, on supply-chain constraints plus a $50M inventory-obsolescence charge. 25.5% reverted. Carries a **read-through to the held D:RTX position** that is more valuable than its B candidacy.

---

## Self-check

- **§19 rails applied as written.** Layer-1 population rail = mkt cap ≥ $2B, 30-day ADV ≥ $10M, |close-to-close| ≥ 3% on an event day in the 10-trading-day window, event-attributable. Layer-2 AI significance judgment — not the move % — decided what advanced. B's frozen Entry criterion 1 (≥5% event-day move, `strategy/04_strategy_b.md`, spec_hash-frozen) survives only as the PART-2 spec-floor rail; **no `below_spec_floor` name was advanced as a candidate anywhere in this file**. `legacy_rule_pass` computed mechanically per row as a record-only benchmark. **No file under `strategy/` or `strategy_math/` was read for editing or modified.**
- **PRICE BASIS honoured.** Every load-bearing magnitude is an IBKR ONE_DAY regular-session bar with `outside_rth=false`; `get_price_snapshot` was not used for any close anywhere in this run. Bars pulled sequentially with per-ticker verification. Eleven ranking-decisive names re-verified independently by the orchestrator, all matching.
- **Shortlist cap respected:** 15 ranked candidates, the unchanged maximum.
- **Criterion 5 (no open A position in the same name):** checked — no open A positions exist; the constraint binds nothing, including DDOG.
- **"NO-GO records are context, not barriers"** applied: DDOG, FIG, NET and PINS all carry prior NO-GOs on *different* events and were re-evaluated on current evidence rather than pre-empted; APP, TEAM and TWLO were re-rejected on precedent because the shape and the mechanism are unchanged, which is a judgment, not a bar.
- **Honest limitations, stated rather than buried.** (i) The independent population sweep was **not exhaustive** — Q2 season had hundreds of reporters and the FMP earnings-calendar pull returned only ~16 rows for the week; REITs, regional banks/insurers and mid-cap chemicals/packaging are the acknowledged blind spots, and the sweep still surfaced four names the daily screen missed entirely, so more probably remain. (ii) The carry-forward reversion figures WERE re-measured against IBKR bars this run; two unresolved items remain inside it — REPL's stated +127% computes to +107%, and CCJ's stated event date does not match its bars (both flagged in place, neither decision-bearing). (iii) TTD's market cap is unresolved between ~$6.5B and $8.91B across sources; it clears the floor on either, so it does not affect eligibility. (iv) Analyst-reaction breadth for APP and GME could not be verified and is marked as such rather than asserted.
- **Chat output:** one-line acknowledgment only.
