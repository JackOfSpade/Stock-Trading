2026-09-22
<!-- d1_scan_through_utc: 2026-09-22T22:35:29Z -->

# Daily Market Development Scan — 2026-09-22 (Tue, MT)

**Scan window: 2026-09-21 16:10 MT → 2026-09-22 16:35 MT** (**24.4h — the normal daily cadence, no gap**). Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-21T22:10:30Z -->` marker, cross-checked against that file's own commit at `2026-09-21T22:33:10Z`; the two differ by 23 minutes, which is that run's write-to-commit interval, not a coverage gap. **ONE completed US trading session inside this window: Tuesday 2026-09-22.** **Every close-to-close figure in this file is measured 2026-09-21 → 2026-09-22 unless it is explicitly labelled an anchor-session measurement, of which there are several and they are the point of this scan.**

**CONNECTORS ALL HEALTHY, AND YESTERDAY'S OUTAGE IS CLOSED.** The BigQuery MCP connector — de-authed for the entirety of the 2026-09-21 run — answered at pre-flight and throughout. The deferred-write ledger `ops/spikes/bigquery-deauth-2026-09-21-d1-deferred-writes.md` has been **drained**: the 2026-09-21 equity-breadth row, both `research-screen` rows, the `add-candidate-review` row, the park heartbeat and all **109** `ops.web_calls` rows have landed, and both tracking alerts (`d1_deferred_writes_unlanded`, `web_call_coverage_gap`) are resolved. One ledger item was deliberately **not** replayed and the reasoning is recorded in the ledger: the 2026-09-21 `park-allocation` row is superseded by design, because D1 re-issues the park call daily and landing a stale dated call would misrepresent superseded guidance as current.

**Tape — the index did nothing and the market did a great deal.** SPY 773.50 → **773.38** (**−0.0155%**, twelve cents) on 20,055,518 shares; **VOO closed unchanged to the cent at 712.78** (verified by a solo re-pull, below). But **QQQ +0.8079%** (741.47 → 747.46) against **DIA −0.3425%** and IWM +0.5708%, and the **cross-sector spread was 3.6174pp** — XLB **+1.6496%** to XLF **−1.9678%**. Six sectors higher, five lower. **Yields fell at the front only: 2Y 4.76 → 4.71 (−5bp), 10Y 4.96 unchanged, 30Y 5.29 unchanged — so the curve STEEPENED to +0.25 from +0.20**, reversing yesterday's flattening. TLT −0.0611%, IEF +0.0110%, LQD **0.0000%**, HYG −0.0127%, SGOV +0.0099%. **Brent (BZX6) 100.34 → 99.25 (−1.0863%) — a fifth consecutive decline and the first sub-100 close of this series** — with USO −2.7538%. GLD +0.4242%, UUP unchanged, BITO −0.3442%. **VIX 14.87 → 14.21 (−4.4385%), a third consecutive sub-15 close and −9.1665% below its 20d SMA of 15.6440.** Equity breadth (`$S5TH`) **50.49 → 49.70, −0.79pp**, back below the shared vocabulary's 50 HEALTHY line after one session above it.

**The session's one genuine macro development was de-escalation, not data.** Iran offered to reopen the Strait of Hormuz within seven days if the US lifts its naval blockade (Reuters, ~11:16 ET), Saudi Arabia began testing its East–West bypass pipeline, and crude fell through $100 — a channel that bears directly on the `shock_overlay='acute'` axis holding a quarter of the park in T-bills. The scheduled macro tape was second-order: S&P Global flash US composite PMI **53.6** from 54.6, Richmond Fed manufacturing **4** (prior 5, consensus 3).

All equity/ETF figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), **read from the `close` array at both ends**, every bar verified carrying a 2026-09-22 stamp of `13:30:00Z`. Two documented exceptions, stated rather than hidden: the `^VIX` bar (contract 13455763, `IND`/CBOE) stamps `07:15:00Z` and carries `delayed:900`, an index-feed property rather than an equity RTH bar; and Brent is a NYMEX future (BZX6, contract 339981284, `delayed:600`, last trading date 2026-09-30 — verified still front-month this run via `search_futures`, not rolled, but 8 days from expiry). Treasury yields are the Treasury par curve via FMP `economics/treasury-rates` with **both** dates pinned, and FMP is confirmed to have published a genuine 2026-09-22 row (its 2Y differs from the 09-21 row, which is what establishes it is not a carried-forward latest).

**MEASUREMENT INTEGRITY.** **43 distinct single names and 19 index/ETF/future instruments were put to IBKR across four sequential batches; every one returned a genuine 2026-09-22 regular-session bar. Zero symbol-level denials. Zero measurement failures. Zero discovered-but-unconfirmable names.** The IBKR parallel cross-contamination defect (`ops.alerts` `7cc25b71`, owner OPS1) was contained the same way as the prior two runs — **every** `get_price_history` call issued strictly one per message at concurrency 1 — and the self-check passed across all four batches: no two distinct instruments share an identical close or an identical volume to full precision. The defect is OPS1's and is **not** fixed here. **VOO's exactly-unchanged close was treated as a suspect rather than a curiosity**, because an identical close on consecutive days is also the signature that defect produces: a solo verification re-pull reproduced 712.78 / 712.78 *and both volumes* (3,150,532 and 3,880,235) byte-for-byte, so the unchanged close is genuine.

---

## TL;DR

- **Exits triggered: none.** The open book is 12 tranches across 8 names, all Strategy D; not one carries a `convergence_target` or a `time_exit_date` (both are B/E fields, and B and E hold nothing), so **zero mechanical triggers are capable of firing**. No thesis-invalidation criterion is met on any of the 12.
- **New entry candidates: 6 (VKTX, BFLY, CLDX, SNDK, RCL, SHOP)** — all Strategy B, all **state-index only**; B is `DO-NOT-ACTIVATE` and capital-disabled, so no thesis construction is routed. **Five further names cleared the 5% bar on today's reaction and are deliberately NOT routed because they fail it on the correct anchor session: VICR, GRAB, LEN, GME, ALL.**
- **Add candidates: none.** 12 tranches evaluated, 0 flagged, 3 declined at the HARD GATE (ISRG, RTX, UBER — `breach_status` unassessed and uncovered by any later tranche). Seven of twelve sit above cost and the tape was flat, so no dip trigger existed to decline.
- **Watchlist changes: 6 adds** to the Strategy B new-entry candidates state index.
- **Regime review: no review.** Breadth crossed back below 50 after one session above; recorded as an observation, since the threshold is D2a's to apply.
- **Park: RE-RISK, `target_f_pct` 25 → 0, LOW 15, BOUND.** Separately and unrelatedly: **the park was liquidated ~17.6% pro-rata at this morning's open by orders no routine staged** — `ops.alerts` `park_unexplained_liquidation`, NAV intact, cash still in the account.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**Hormuz de-escalation is the one market-wide development, and it is a genuine one.** No discrete shock broke inside the window; what did break is a cluster of linked headlines pointing the same way:

- **Iran offered to reopen the Strait of Hormuz within seven days** if the US lifts its naval blockade and military pressure — conveyed to US officials and reported by Reuters, carried 2026-09-22 ~11:16 ET, inside the window.
- **Saudi Arabia began testing its East–West bypass pipeline** (the Hormuz-bypass route, shut after drone attacks) and could restart flows this week (WSJ live coverage, 2026-09-22 16:06 ET).
- **Secretary Rubio** said 60–70% of Hormuz oil flows are now moving and climbing.
- Trump addressed the UN General Assembly and floated restricting diesel exports.

**Observable reaction, measured here rather than quoted:** Brent **−1.0863%** to 99.25 (fifth consecutive decline, first sub-100 close), USO **−2.7538%**, XLE **−1.0887%**, and the refiners fell hardest — VLO **−4.1015%**, MPC **−3.1562%**, DINO **−2.3790%**. Equities were unmoved in aggregate (SPY −0.0155%) and the front end of the curve rallied 5bp.

**Background, and deliberately NOT counted as in-window:** the blockade itself, CENTCOM's 110-ships tally (09-21), the tanker struck inside the Strait (09-21), and Treasury's statement that Iranian carriers are shut out worldwide from 09-23 are a live multi-month crisis, not fresh developments. **Also outside the window and stated so it is not mistaken for today's news:** Google's **€403M** EU/Ireland DPC location-data GDPR fine was announced **2026-09-21 between ~11:28 ET and ~13:49 ET** — *before* this window opened at 16:10 MT. It is a live overhang on a held position and is assessed under RISK below, but it is not a Development of this session.

**No other qualifying market-wide breaking event** — no bankruptcy, disaster, central-bank surprise, or enforcement action — originated inside the window.

### 2. Scheduled events that resolved today

**Earnings.** Exactly **two** US-listed companies at or above $2B reported inside the window, which is itself the story of the day's calendar:

| Ticker | Period | EPS | Revenue | Timing | Measured reaction |
|---|---|---|---|---|---|
| **AZO** | FY26 Q4 (16wk, ended 2026-08-29) | **$56.05** GAAP vs ~$54.08–54.14 est — **beat** | **$6.59B**, +5.6% YoY vs ~$6.7B est — **miss** | pre-open ~06:55 ET **2026-09-22** | **+3.2634%** (2803.25 → 2894.73) |
| **KBH** | FY26 Q3 (ended 2026-08-31) | **$1.05** GAAP vs ~$0.88–0.90 est — **beat** | **$1.30B**, −20% YoY, in line | **after close 2026-09-22** (call 17:00 ET) | **no reaction session yet** — +1.7% in after-hours only |

AZO comps +2.7% (domestic +1.6%, international +1.3% cc), FY26 the first $20B sales year, FY27 sales acceleration guided. **KBH is recorded as an anchor-dated event with NO measured move**, per the EVENT-IDENTITY GATE: it printed after today's close, so its anchor is **2026-09-22** and its reaction session is 2026-09-23, which has not happened. Its eligibility will be testable by tomorrow's D1 and is deliberately left untested rather than assessed off an after-hours print.

**Macro (2026-09-22).** S&P Global flash US composite PMI **53.6** (August 54.6) — a second consecutive month of slowing growth, though Q3 still tracks the strongest average expansion since Q4 2024; chief business economist Chris Williamson flagged slowing hiring and softening pricing power. Richmond Fed manufacturing **4** (prior 5, consensus 3 — beat), shipments 11, services revenues −8 (prior −6). ADP weekly employment change 16.25K; Redbook YoY 8.5%. Fed speakers Williams (14:05 ET), Jefferson (14:20 ET) and Barkin (17:30 ET); EUR/USD fell to a two-month low on Fed-vs-ECB divergence. **No macro release produced a standalone market-moving surprise.**

**FDA.** Two approvals resolved inside the window, **both resolved against the sponsor's own release rather than an aggregator calendar**, per the FDA limb:
- **MRK — WINREVAIR (sotatercept-csrk):** FDA approved an updated/expanded label for PAH (WHO Group 1) on the Phase 3 ZENITH trial, 2026-09-22 06:45 ET, confirmed on Merck's own newsroom. **This is a label update, not a new approval** (WINREVAIR was first approved March 2024) and is recorded as such.
- **LNTH — BRAVNETSA (lutetium Lu 177 dotatate):** FDA granted final ANDA approval (bioequivalent/therapeutically equivalent to LUTATHERA) for GEP-NETs, 2026-09-22 08:00 ET, confirmed on Lantheus's own investor release.

**⚠ THE KNOWN-BAD AGGREGATOR ROW FIRED AGAIN AND WAS REFUSED AGAIN.** Benzinga's FDA calendar **still lists a forward "2026-09-22" PDUFA date for IONS' zilganersen**. Zilganersen was **approved 2026-09-03**. This is the third documented appearance of this exact stale row; it is **not** recorded as a resolved event, **not** recorded as a pending forward action, and is noted here only so the next run recognises it on sight. No CRLs were identified inside the window.

**Other resolved catalysts.** **LEN**: Berkshire Hathaway disclosed buying ~2.74M Lennar shares across both classes, taking its stake **above 10%** — Form 4, EDGAR-accepted **2026-09-21 21:31:10 ET**. (Lennar's own Q3 FY26 earnings were 2026-09-16, a week before this window, and are not today's event.) **RCL**: reported — not closed — to be near a ~$3B deal for 50% of Sandals Resorts, valuing Sandals at ~$6B; first reported by the FT, corroborated by Reuters/CNBC, 2026-09-22 afternoon. **CFTC event-contracts rulemaking**: no new action inside the window; the June NPRM remains pending.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

`events.decision_log` `research-screen` row **`587a88e4-31b3-4899-ab31-26f9f63bbacc`** (`screen='single-name-move'`). **43 names measured, `rail_tally` 20, `surfaced_count` 26** (`ARRAY_LENGTH(passed)`, per the 2026-08-30 pin — the rail arithmetic lives in `rail_tally`/`universe_measured` and the two legitimately differ here because two sub-rail names are surfaced under the §19 escape valve).

#### THE FINDING: the anchor convention disqualified FIVE of the eleven names whose reaction cleared B's floor

The convention landed in this prompt **yesterday**. On its first full day it moved five candidates:

| name | reaction session (09-22) | correct anchor | move ON the anchor session | verdict |
|---|---|---|---|---|
| **VICR** | **+19.8481%** | 2026-09-21 after-close (issuer PR) | **+0.5298%** | **FAILS by 4.47pp** |
| **GRAB** | +8.9347% | 2026-09-21 **20:40:35 ET** (EDGAR Form 4) | **+4.3011%** | **FAILS by 70bp** |
| **LEN** | +6.3781% | 2026-09-21 **21:31:10 ET** (EDGAR Form 4) | **+2.1588%** | **FAILS by 2.84pp** |
| **GME** | +5.5800% | 2026-09-21 **17:04:15 ET** (EDGAR Form 4) | **+0.5300%** | **FAILS by 4.47pp** |
| **ALL** | −5.5011% | **2026-09-17** 07:58 ET (issuer PR) | **−1.0359%** | **FAILS by 3.96pp** |

Under the pre-convention default — stamp the reaction session — **all five would have been routed.** VICR is the starkest: a **+19.85% print that is not a Strategy-B candidate at all**, because its guidance raise was issued after Monday's close and on Monday the stock moved half a percent. ALL is the most instructive: its qualifying release is **five sessions old**, its own event-day move was −1.04%, and today's −5.50% is the financials cohort rather than the event reaction — so stamping it 09-22 would have manufactured a candidate out of a week-old catastrophe-loss estimate the tape had already absorbed.

**SHOP is the control that keeps this from being a merely restrictive rule.** Its anchor is *also* 2026-09-21 — but **intraday** (~11:04 ET, the CEO's own post), so the eligibility session is 09-21 and it **CLEARS there at +7.3307%**. The convention is load-bearing in both directions.

**Three of the five anchors are SEC EDGAR acceptance timestamps** — published, exact, and impossible to reconstruct from price. **No anchor was inferred from the price series**, per the rule forbidding exactly that. ALL's 2026-09-17 anchor-session bar was pulled specifically so its eligibility could be tested on the right session instead of left untested.

#### The written-up names

**Highest conviction (75) — and note the biggest numbers are not here on size.**
- **CLDX −11.5598%** (37.89 → 33.51, $2.23B). Phase 3 EMBARQ-CSU1/CSU2 hit the primary **and all key secondary** endpoints for barzolvolimab, released pre-open ahead of an 08:00 ET webcast — and the stock fell 11.6%. A positive surprise met with a violently negative reaction is the sentiment-versus-information divergence Strategy B exists to ask about. **Cleanest mechanism on the board.**
- **VKTX +35.6692%** (30.11 → 40.85, $4.77B). VK2735 maintenance-dosing topline, issuer PR 07:05 ET. Largest move of the session, and it earns 75 for the mechanism — maintenance and tolerability are the specific questions the obesity complex has been repricing all year — not for the magnitude.
- **VICR +19.8481%** ($12.16B). Raised Q3 revenue guidance tied to a named AI-hardware Vertical Power Delivery royalty: genuine new company information. 75 for that *and* as the run's cleanest anchor case.

**Medium (60).** **SCHW −6.1097%** ($174.5B) — a 6% single-session fall in a mega-cap with **no discrete company event** is more remarkable than a 20% move in a small-cap on news, and it is a measured cohort, not a print: LPLA −7.4520%, ALL −5.5011%, WFC −3.9173%, RJF −3.5111%, BAC −3.0366%. **LPLA −7.4520%** — same cohort, larger move, and two candidate explanations were found and *both rejected* (a Valero board appointment dated 09-17/18, the classic aggregator misattribution of stale news; and a same-day advisor-recruitment release that is positive-sounding and an odd fit for a 7% fall). **RCL −6.1379%** — capital-allocation news read decisively negatively. **SHOP +7.1201%** — Shop Pay checkout inside Meta's Muse agent. **GRAB +8.9347%** — a CEO buying ~$29.9M on the open market with the COO alongside. **LEN +6.3781%** — Berkshire through 10%. **AZO +3.2634%** — the session's one genuine large-cap earnings print; a restrained response to a mixed print in a low-beta retailer is arguably more informative than a large move in a high-beta name. **VLO −4.1015%** and **MPC −3.1562%** — Jefferies to Hold, pre-open.

**Lower (45/30).** **BFLY +21.9902%** and **SNDK +6.8152%** are both held at 45 despite their size because each moved on a **sell-side initiation alone** — a float event, not an information event. **INOD +14.6110%** (30) and **SGRY +15.6662%** (30) are the two largest moves with the thinnest content on the board: a third-party read-through note about someone else's product, and an undated sector theme. **GME +5.5800%** (30). **MU +5.0002%** (45) — lands *exactly* on the floor with no discrete event.

#### Absences, recorded rather than omitted

**Six names cleared the move and cap rails with no identifiable public event** after a dedicated search and sit in `rejected_notable` so the unexplained tail is countable: **ONDS +4.6070%, HL +3.7057%, RKT +3.0744%, MARA +2.6355%, PATH −2.5018%, PSKY +2.0182%**. Two have their obvious explanation **contradicted by this run's own measurements**: HL rose while gold and silver futures fell, and MARA rose while BITO fell −0.3442%. Ten further names carry `qualifying_event_date: UNRESOLVED` rather than a defaulted date.

**Two magnitudes are reported DISPUTED rather than resolved in our own favour**, per the SOURCE-DISAGREEMENT rule: **MPC** (measured −3.1562% against a third-party −5.3%) and **DINO** (measured −2.3790% against −5.7%). Both were re-derived on clean solo re-pulls that reproduced byte-for-byte and the disagreement survived. Neither is near B's floor on either figure, so nothing turns on it — but the rule exists because the 2026-09-14 ORCL defect was a run dismissing correct third-party closes by assertion.

**Two sub-rail names surfaced under the §19 escape valve and labelled as such:** **MAZE +26.7530%** (~$1.57B) and **GSHD −11.4894%** (~$1.71B). Both fail the $2B population rail, neither is routable, and neither is counted in `rail_tally`.

**Coverage is bounded and the bound is stated.** Discovery was the union of three 50-row FMP vendor lists (~140 raw rows) plus wrap-article names, ~55–60 tickers examined; confirmation measured 43. **This is not an enumeration of the ≥2%/≥$2B population** — no constituent-level sweep was run, so an ordinary large-cap that moved 2–4% on modest volume and was not named by a reporter can be missing entirely. FMP's `news/search-stock-news` is plan-gated and denied both calls, so every event attribution came from Tavily/web rather than a vendor news feed. No discovery leg was down.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

`events.decision_log` `research-screen` row **`730ccc29-8d07-4c26-8c68-ea5c1d48f903`** (`screen='sector-move'`; it supersedes `39deb2b3`, which landed with `fields` NULL — see PROCESS NOTES). **All 11 GICS sector SPDRs measured, so the measured universe IS the population: `rail_tally` 4, `universe_measured` 11, `surfaced_count` 5.**

| | | | | | |
|---|---|---|---|---|---|
| XLB **+1.6496** | XLP +0.9888 | XLK +0.7288 | XLV +0.5207 | XLI +0.1706 | XLY +0.0891 |
| XLRE −0.2113 | XLU −0.3197 | XLC −1.0632 | XLE −1.0887 | XLF **−1.9678** | |

**The legacy rule surfaces NOTHING today, and that is the point of having converted this screen.** `sector>=2%` passes on **zero of eleven** — XLF misses it by **3.2 basis points**. Under the old fixed bar this session would have been written up as having no sector development at all. Agreement: `both` 0, `ai_only` 5, `rule_only` 0.

- **XLF −1.9678% (75).** A ~2% sector fall is unremarkable; a ~2% fall in financials on a tape where the index moved twelve cents is not. Every named constituent measured this run moved **more** than the sector — a sector being repriced from the inside, on a hawkish rate path plus the AI-agent disintermediation story.
- **XLE −1.0887% (60).** The cleanest transmission of the Hormuz de-escalation, and it reaches beyond its own sector: `Brent > 95` is one of the three axes currently holding the park's defensive weight.
- **XLB +1.6496% (60).** Top sector, and the *direction* is informative: materials led while energy **fell**, the input-cost signature rather than a risk-on sweep, which would have carried energy along.
- **XLP +0.9888% (45).** An **escape-valve sub-net surfacing**, labelled as one, taking one of three permitted slots. A staples bid on a flat tape while financials fall is the shape §19 says can outrank a bigger beta-day move — and it is the **inverse of yesterday**, when the defensives fell on an up day. Held at 45 rather than 60 because the other three defensives **disagree** (XLU −0.3197%, XLRE −0.2113%, XLV +0.5207%): this is staples specifically, not a defensive rotation, and calling it one would read a sector move as a regime signal it does not support.
- **XLC −1.0632% (45).** Surfaced on the rail and then deliberately discounted: XLC was the **top** sector yesterday at +3.5556% and has given back under a third of it on no new information. One-day mean reversion in the prior leader is not a development.

Dispersion context: **3.6174pp** today against 6.4323pp on 09-21 and 2.2387pp on 09-18 — narrowing from yesterday's spike, still well above Friday's.

### 5. Notable commentary

- **Chris Williamson (S&P Global Market Intelligence, Chief Business Economist)** on the flash PMI: "further robust growth of output in September rounds off the best quarter so far this year," while flagging slowing hiring and softening demand and pricing power.
- **Secretary of State Marco Rubio**: 60–70% of Strait of Hormuz oil flows are now moving and climbing; claimed diesel prices would be far higher without the blockade policy.
- **Jefferies** cut **MPC** and **VLO** to Hold (pre-open, ~09:13 ET). Note the limit of the evidence: the note as reported names **only** MPC and VLO — **DINO's inclusion in the refiner selloff is sector sympathy, not a rating action**, and the single claim that Jefferies downgraded DINO traces to an AI-generated aggregator page and is treated as noise.
- **Rosenblatt** initiated **SNDK** at Buy, $2,400 PT (05:17 ET); **Needham** initiated **BFLY** at Buy, $10 PT (06:39 ET); **UBS** cut **CMCSA** to a $27 target, Neutral maintained.
- Desk colour across WSJ/MarketWatch framed brokers and insurers (Schwab, LPL, Allstate) as exposed to AI-agent disintermediation following Meta's Muse reaching 500k users; **Apple briefly crossed a $5 trillion market cap intraday** (AAPL closed +0.2272%, so the crossing was intraday only and is recorded as colour, not as a development).

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP — structurally incapable of firing, stated as a fact rather than as "nothing fired"

The open book is **12 tranches across 8 names, every one Strategy D**. **Not one carries a `convergence_target` or a `time_exit_date`** — both are Strategy B / E fields, and B and E hold nothing — so **zero mechanical exit triggers are capable of firing on this book.** That is a structural property of an all-D book, not an observation about today.

**UNION SWEEP against the live broker — clean.** `get_account_positions` returns exactly ten line items: the eight open-book names plus the VOO/SGOV park sleeve, with per-name quantities reconciling **exactly** to the BigQuery tranche sums (AMZN 0.3464 = 0.1910 + 0.1554; DIS 0.7244 = 0.4422 + 0.2822; GOOGL 0.2577 = 0.1043 + 0.1534; TSM 0.1550 = 0.0891 + 0.0659; GEV 0.1244, ISRG 0.1091, RTX 0.1601, UBER 0.5156 all single-tranche). **No position exists at the broker that is absent from `state.current_positions`**, so no `position_reconciliation_lag` alert is owed, and `state.system_health.position_drift_detected` independently reads FALSE.

### PER-STRATEGY KILL-TRIGGER SWEEP — nothing firing

`perf.kill_flags`, with `current_drawdown` refreshed unconditionally against today's live marks:

- **Strategy D** (as_of 2026-09-21): `current_drawdown` **−1.5948%** against the **−50%** drawdown-kill bar; `deployed_days` 102; `closed_trades` 1 against a `gate_n` of 29. **All five flags FALSE** — `drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `gate_reached`, `interim_underperf_warning`.
- **Strategy B** (as_of 2026-08-18, B holds nothing): all flags FALSE.
- **No `interim_underperf_warning` alert is owed** and **none is open to heal-resolve** — the flag reads FALSE for both strategies and no alert of that category is unresolved.
- **B open-book pairwise correlation:** `analytics.b_pairwise_correlation` returns `n_positions = 0`, so the `n_positions >= 2` limb fails on zero and the check is **structurally inert**. No `b_pairwise_corr_high` alert.

### Thesis-invalidation assessment — all 12 UNBREACHED

| position | close | session | mark vs cost | verdict |
|---|---|---|---|---|
| D:AMZN:2026-07-30 / 2026-07-09 | 254.98 | −1.3426% | −4.0321% / +5.6938% | **UNBREACHED** — no AWS-bearing development in-window |
| D:DIS:2026-08-05 / 2026-05-07 | 103.82 | −0.3934% | +0.0334% / −6.7365% | **UNBREACHED** — SVOD margin ~13% at FQ3 FY26, third consecutive quarter of expansion |
| D:GEV:2026-08-03 | 950.28 | +0.4291% | −2.0235% | **UNBREACHED** — organic-orders growth untouched |
| D:GOOGL:2026-07-09 / 2026-07-26 | 351.16 | −1.0733% | −2.4145% / +7.1121% | **UNBREACHED** — see the GDPR assessment below |
| D:ISRG:2026-07-20 | 402.09 | +0.1096% | +15.0437% | **UNBREACHED** on available evidence |
| D:RTX:2026-04-27 | 190.99 | −1.7238% | +7.9657% | **UNBREACHED** — largest single-session decline in the book, no news behind it |
| D:TSM:2026-07-21 / 2026-07-29 | 452.00 | +1.5411% | +5.6417% / +15.0470% | **UNBREACHED** — best performer of the session |
| D:UBER:2026-07-09 | 69.89 | −1.3411% | −4.5314% | **UNBREACHED** — GB/EBITDA criteria untouched |

**The one development that touches a held name, assessed explicitly: GOOGL's €403M EU/Ireland DPC location-data GDPR fine.** Three reasons it does not invalidate. **(i)** It was announced **2026-09-21 before this window opened**, so it is not a Development of this session at all. **(ii)** GOOGL's `invalidation_4` names an **adverse structural remedy** — a monetary penalty is categorically not one, and the position's own entry record already identifies the EU DMA behavioural ruling of 07-23 as the closest-watched item in that lane. **(iii)** €403M is immaterial against Alphabet's scale and does not touch Cloud revenue, Cloud margin or Cloud RPO, which are what criteria 1–3 measure. **NO invalidation criterion is met.**

**DIVIDEND NETTING — inert this run, and measured rather than assumed.** `state.price_level_criterion_drift` returns exactly **one** row (`D:DIS:2026-08-05`) and it is a **non-criterion**: `is_exit_criterion=false`, `actionable_price_level=false`, `has_dividend_drift=false`. The "45.00" the view picked up is the **CaR notional** from that position's not-exit-triggering text, not a price level. **No open position carries a price-level exit criterion**, so the mandatory netting step has nothing to net; `marks_cover_reference=true`, so no incomplete-window caveat is owed either.

### Watchlist candidacy

No Development materially changes the candidacy status of any name already queued on the Strategy A queue, the Strategy B overflow, or the B new-entry index. **VICR is a live exception worth flagging**: it was added to the B new-entry index on **2026-09-17** on a *different* qualifying event, and today's guidance raise is a genuinely distinct second event — but it **fails criterion 1 on its correct 09-21 anchor (+0.5298%)**, so it generates **no** new row. Ticker-only deduplication is prohibited and was not used; the four-part field identity `(item_type, strategy, ticker, qualifying_event_date)` was checked against both open and terminal `events.queue_events` history for every routed name.

---

## ANALYSIS — OPPORTUNITY CHECK

Evaluated against every roster-active strategy with `review_cadence: reactive` in `strategy/roster.yaml` — currently **A, B, C, E** (D is excluded via `review_cadence: long_horizon`). Confirmed live from `state.active_strategy_codes`: A, B, C, D, E adopted.

**Strategy B — six candidates, all state-index only.** Each clears B's frozen Entry criterion 1 (≥5% close-to-close **on the anchor session**) and each carries a resolved anchor:

| ticker | anchor | move on the anchor session | anchor evidence | 10-day window closes |
|---|---|---|---|---|
| **VKTX** | 2026-09-22 | +35.6692% | issuer PR (PRNewswire) 07:05 ET | 2026-10-06 |
| **BFLY** | 2026-09-22 | +21.9902% | initiation, MT Newswire 06:39 ET | 2026-10-06 |
| **CLDX** | 2026-09-22 | −11.5598% | issuer PR (GlobeNewswire), pre-open | 2026-10-06 |
| **SNDK** | 2026-09-22 | +6.8152% | initiation, MT Newswire 05:17 ET | 2026-10-06 |
| **RCL** | 2026-09-22 | −6.1379% | FT report, afternoon | 2026-10-06 |
| **SHOP** | **2026-09-21** | **+7.3307%** | CEO's own post ~11:04 ET, **intraday** | **2026-10-05** |

**B is `DO-NOT-ACTIVATE` and capital-disabled, so no thesis construction is routed for any of them** and no capital is at risk. Two anchors are **LIKELY rather than CONFIRMED** and are labelled so in the durable record: SHOP (briefed rather than issued as a dated newsroom PR — note the Muse *launch* itself was 2026-09-08 and is a different, earlier event) and RCL (the FT original is paywalled; the earliest secondary confirmations are 14:25 ET and 15:33 ET). **SNDK's and BFLY's anchors are aggregator-sourced** because Rosenblatt and Needham publish no public timestamped release — stated as aggregator evidence, not issuer evidence.

**Strategies A, C, E — no candidates.** No newly announced qualifying catalyst within 6 months landed on a name fitting **A**'s eligibility inside this window. No newly announced qualifying catalyst within 45 days landed for **C**, whose operative state is the narrower HYBRID ACTIVATE (FOMC-only) carve-out, and the next FOMC is already queued as `thesis-FOMC-C-20261020`. For **E**, the day's dispersion was wide (3.6174pp) but it was cross-sector, not the **intra-industry-group** divergence E requires; the financials cohort is the one place to look and it moved *together* (SCHW/LPLA/RJF/WFC/BAC all down, 3.0–7.5%), which is convergence within the group, not divergence. E is also `DO-NOT-ACTIVATE` and capital-disabled.

---

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

`events.decision_log` `add-candidate-review` row **`b62e4c9a-8890-4ec7-9175-70092175113d`**. **12 evaluated, 0 flagged, 3 declined at the HARD GATE.** A and B hold nothing; all 12 tranches are D.

**Nothing flagged, and the reason is boring in the right way: there was no dip to buy.** Seven of twelve tranches sit above cost and the session was flat, so trigger (a) — adverse price action against an intact thesis — did not arise anywhere. Trigger (b) requires **new** information reinforcing an original thesis, and no name had an in-window development bearing on its own criteria. `trigger_type` is `none` on all twelve.

**HARD GATE — the same three as the 2026-09-20 sweep, which is the point.** Seven tranches carry `$.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`. Four are covered at **name** level by a later tranche carrying a fresh assessment (AMZN 07-30, DIS 08-05, GOOGL 07-26, TSM 07-29). **Three are covered nowhere — ISRG, RTX, UBER — and are structurally ineligible for an add regardless of merit.** An unchanged book producing an unchanged gate verdict is the correct outcome; a verdict that drifted run-to-run on identical inputs would be the defect. Worth recording that **RTX and UBER are the two most plausible dip cases in the book** (−1.7238% today and −4.5314% from cost respectively) — the gate, not the merits, is what closes them.

**⚠ THE CONNECTOR MARKS WERE STALE ON ALL EIGHT NAMES TODAY**, which is the 2026-09-07 price-basis pin earning its keep. `get_account_positions.market_price` differed from the true RTH close on **every one**: AMZN 255.19 vs 254.98, DIS 103.85 vs 103.82, GEV 950.75 vs 950.28, GOOGL 352.55 vs 351.16, ISRG 402.90 vs 402.09, RTX 191.13 vs 190.99, **TSM 450.37 vs 452.00 — stale in the opposite direction**, so this is not a uniform lag that could be corrected out — and UBER 70.05 vs 69.89. SGOV's mark matched **yesterday's** close. Only VOO matched to the penny. Every `mark_vs_cost_pct` above is therefore computed from the IBKR RTH daily-bar close over **that tranche's own** `cost_basis / shares`, never from the connector mark and never from the account-level blended `average_price` — which for GOOGL reads 340.797 against per-tranche costs of 359.848 and 327.843, a number matching neither tranche.

**Scope note, stated rather than assumed:** D is `DO-NOT-ACTIVATE` and capital-disabled, so a flagged add could not be funded today in any case. The sweep is run on the merits regardless, because this log is record-only and its value is that it keeps running when nothing happens.

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review recommended.** High bar, default NO on ambiguity, and nothing today clears it.

The session's genuine developments push in **opposite** directions on the regime vocabulary and therefore cancel rather than accumulate: the Hormuz de-escalation and a fifth consecutive Brent decline argue *against* the `shock_overlay='acute'` state, while breadth fell back below its HEALTHY line and the flash PMI stepped down for a second month, both of which argue *for* continued caution. `policy_stance` is untouched — the curve steepened 5bp on a 2Y rally, which is front-end relief, not a policy-path change. A one-session move of 0.79pp in breadth, with the index flat and the standing defensive count unchanged at 3, is nowhere near a router-review trigger.

**EQUITY-BREADTH OBSERVATION — written.** `events.regime_events` `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`, `as_of_date` **2026-09-22**, `numeric_value` **49.70**, `value` `Barchart $S5TH`.

- **Source and settlement.** Barchart `$S5TH` (the declared primary per the 2026-09-06 W5 ruling), cache-busted, fetched via `tavily_extract` at advanced depth. As-of wording verbatim: *"Quote Overview for Tue, Sep 22nd, 2026"* — **source-dated, not `inferred_post_close`**. On-page timestamp **16:56 ET**, i.e. **at or after the 16:00 ET close**, so the 2026-09-20 settlement pin is satisfied and **no `unsettled_at_fetch` token is owed for the recorded value**. OHLC 48.90 / 49.90 / 48.11 / 49.70.
- **Previous-close self-check: exact.** Barchart's Previous Close reads **50.49**, reconciling precisely against the value D1's 2026-09-21 run measured. Zero mismatch, so no revision-noise question arises.
- **Cross-check, and the caveat is on the cross-check rather than the primary.** EODData `S5TH` returned **49.50** (gap **0.20pp**, far inside the 5pp no-row threshold) with OHLC 50.49 / 50.49 / 48.11 / 49.50 — **but its page header stamped 15:58 ET, below the 16:00 threshold, and did not advance across a deliberate re-fetch with a different cache-buster.** So `unsettled_at_fetch=15:58 ET` applies to **the cross-check figure only**. The compound EODData tell does **not** fire (Low 48.11 ≠ Close 49.50), which is in tension with the pre-close timestamp; the explicit timestamp governs and the tension is recorded rather than resolved.
- **Independence, stated honestly.** The two vendors share the Low to the cent and share the Previous Close, but their Open (48.90 vs 50.49) and High (49.90 vs 50.49) genuinely differ — so this is not the OHLC-identical shape that would indicate a straight rebroadcast. Two usable sources, one of them not independently certified post-close.
- **Fetch-method provenance.** A rendering `web_fetch` on the identical cache-busted Barchart URL returned an **empty body**; per the FETCH-METHOD-IS-PROVENANCE rule that condemns *that fetch*, not the source, and the extract path answered in full. Same signature as 2026-09-20.
- **MacroMicro not probed and none owed.** The weekly re-probe rides the first D1 fire of the Sunday-anchored week, and the 2026-09-20 Sunday run already spent it (both paths failed; the streak is unbroken since 2026-08-19). Today is Tuesday.
- **Note for D2a** (threshold application is D2a's, an observation not a classification): **49.70 is below the 50 HEALTHY line**, one session after 50.49 crossed back above it. D1 writes `TECHNICAL_INPUT` only.

---

## PARK ALLOCATION CALL

`events.decision_log` `park-allocation` row; `state.park_allocation_latest` carries it to D2.

- **`vehicle`: VOO** — at `target_f_pct = 0` the risk sleeve is the whole book, so VOO is the majority sleeve trivially. `risk_sleeve` VOO, `defensive_sleeve` SGOV.
- **`target_f_pct`: 0 — DOWN from 25. Direction: RE-RISK. Status: BOUND.**
- **`conviction`: LOW, `conviction_pct` 15.**

### The axes, hand-scored from readings measured live today

`state.park_axis_daily` for 2026-09-22 reports **`axes_measured_today = 0`** — **all six axes are CARRIED** (breadth from 09-18, the other five from 09-21), because D2a has not yet written today's `events.signal_marks` and D1 runs before it. The panel is briefing input only this run; every axis below was scored from today's own measurements, and `fields.axis_overrides` records the vintage disagreement. The panel's **count** is not overridden — it says 3 and the live scoring also says 3 — but a matching count off stale inputs is agreement by coincidence, not corroboration.

- **Volatility — NOT defensive, and further from its test than on any session of this series.** VIX **14.21**, a **third** consecutive sub-15 close, **−9.1665%** below its 20d SMA of **15.6440** (−5.4432% yesterday, −5.9025% Friday). The test is conjunctive and fails both limbs by a widening margin.
- **Breadth — STANDING defensive, and the ONE axis that deteriorated.** **49.70** against the 66 line, **−0.79pp**, back below the vocabulary's 50. This is the real argument for holding and it is not discounted.
- **Index — NOT defensive.** SPY **773.38**, **+1.6821%** above its 50dma (760.5862), **+7.8349%** above its 200dma (717.1889), drawdown from the 777.88 trailing 252-day high (2026-08-13) **−0.5785%**. Essentially at the high.
- **Rates — STANDING defensive on the 10Y limb, but IMPROVED inside itself.** 10Y **4.96** (≥ the 4.90 limb, so the axis stands), 30Y 5.29 unchanged, **2Y −5bp to 4.71**, curve **steepened to +0.25 from +0.20** — reversing exactly the flattening yesterday's call named as a deterioration.
- **Credit — NOT defensive.** HYG/IEF **0.862988** against a 20-session SMA of **0.860455** = **+0.2945% ABOVE**, where the test needs 0.50% *below*. Moved toward the test from +0.3537%, still the wrong side.
- **Shock — STANDING defensive, and the weakest by a widening margin.** `shock_overlay='acute'` is a **21-day-old standing state**, and a standing state is never news. Brent **99.25** — sub-100 for the first time in this series, a **fifth** consecutive decline, margin over the 95 line narrowed to **4.47%** from 5.62% and 9.34%. The session's own news actively contradicts the axis.

### The arithmetic, computed before the call was written

Standing defensive count **3** (breadth, rates, shock), unchanged. **Firing count 0** — no axis ENTERED defensive — so the **increase gate is SHUT** and f=50 was mechanically unavailable; the only live choice was KEEP-25 versus DECREASE-to-0. Raw cap `LEAST(100, 25 × 3)` = **75**; the decay-confirmed cap (`analytics.park_ladder_shadow`) is also **75**, having stepped 100 → 75 on 09-21 on the third consecutive reading of standing-count 3, exactly as the prior run predicted. The two agree and the clamp is non-binding at any f considered. **Ladder: 0.15 × 75 = 11.25; |11.25 − 0| = 11.25 against |11.25 − 25| = 13.75 → step 0.** No ±1-step deviation used or needed. **Crisis override NOT engaged:** session index move **−0.0155%** against the −2.5% bar, VIX **14.21** against the 28 bar. Decreasing f is always allowed and never delayed; the DE-RISK EVIDENCE CARDINALITY rule and the one-way ratchet both govern *increases* and neither is engaged.

### ⚠ The park was liquidated pro-rata this morning by orders no routine staged

**VOO 16.2040 → 13.3540 shares and SGOV 37.7181 → 31.0781** — both cut by the same proportion (17.588% and 17.604%), raising **$2,701.01** gross across four fills at the 2026-09-22 open under order ids `993912164` and `993912093`. **No routine in this system staged them:** no `ORDER_STAGED` row, no `events.parking_events` row, `state.open_orders` empty, D2's own run note for today records that *no craft point was reached by any path*, and D2a recorded the §13.E sweep/cover as a no-op on its own thresholds. The order-id series matches none of the routine-staged park orders.

**Nothing was lost.** NAV **$15,914.83** against $15,916.02 at the prior run — a −$1.19 delta fully explained by $0.77 of commissions plus ordinary drift — and **$2,715.94 is sitting in the account as settled cash**. A composition change, not a loss. Raised as `ops.alerts` **`park_unexplained_liquidation`** (`5c04fcb8`, `warning`, owning routine **D2a**), with the hazard named: **if the cash is spoken for by a pending owner withdrawal that IBKR funded by auto-liquidation, D2a's next §13.E sweep will buy back roughly what was just sold and a second liquidation will follow when the withdrawal settles.**

**It is NOT load-bearing for this call, and that is stated so a reader does not assume otherwise.** On a cash-inclusive base the book is already **38.0330%** in `risk_tier`-0 assets (CASH sits on `state.park_menu` at tier 0, like SGOV) against a policy of 25 — which pushes the *same* direction as this call. But on the securities-only base `actual_f_pct_before` is **24.7243%**, inside the no-op band against the standing 25, and the call is identical on that book and would have been identical on yesterday's un-liquidated book.

### Why f=0 beats the runner-up

The runner-up is KEEP-25 (f=50 is *barred* by the shut gate, not declined). The park's default vehicle is the risk asset, so **it is the defensive weight that needs justifying**. Two of the three standing axes are weakening on their own evidence and the third improved within itself. Against that sits a measured record hostile to defensive positioning: the allocator trails **VOO by 3.267pp** AI-era and **8.613pp** inception, **both** closed defensive excursions of the AI era lost (−2.841pp, −1.019pp), and across 15 historical episodes the defensive signal carried mean forward edge **−0.638pp**, winning 4 of 15.

**And yesterday named this exact bar.** Its RAISE-f limb was set at breadth breaking down through **~45**, not 50. Breadth at 49.70 does not reach it. Declining now on a 0.79pp move that falls short of a limb I myself named would make the re-entry bar harder than the exit bar in substance while appearing to honour it in form — the precise asymmetry the 2026-08-18 SYMMETRIC EVIDENTIARY STANDARD forbids.

### The case AGAINST f=0, stated in full because it is real

Breadth deteriorated and is back below the HEALTHY line. Three axes still stand defensive on the mechanical scale. The Hormuz de-escalation is a conditional **offer** — the Strait is not reopened, and an offer contingent on the US lifting a blockade can evaporate. And the rates axis reads defensive on only **3.17% of 252 testable sessions** (`state.park_axis_calibration`), so it carries far more information when it fires than breadth or volatility do — and it is firing now. **What decides it against all that:** decreasing f is always allowed and never delayed, yesterday named a bar today's tape does not reach, and the conditions that bar was written against have not returned.

- **`invalidation` (symmetric standard, both limbs disjunctive and at the same height — and DELIBERATELY IDENTICAL to yesterday's, because re-writing the bar each session to fit the day's evidence is itself a way of making it non-binding).** **Would RAISE f from 0** — any one of: VIX closing back above its 20d SMA; SPY losing its 50dma on a close; credit finally confirming (HYG/IEF crossing more than 0.50% **below** its 20d SMA); breadth breaking back down through ~45; or Brent closing back above ~110. **Would KEEP f at 0** — the absence of all of the above. Each raise-limb disjunct is itself an *entering* event, so the gate would open on any of them and the cardinality rule would then require a second independent axis before any increase converts. **Deliberately NOT on the raise limb**, though each was considered: a further curve flattening; a single hot inflation print; the Hormuz reopening failing to materialise. All three are real, but naming them would make the return bar a conjunction-in-spirit against a single-disjunct exit bar. No later session is bound by any of this.
- **`theater_check`:** **The decision turns on one falsifiable number and I am naming it rather than burying it.** At `conviction_pct` 20 the ladder returns 0.20 × 75 = 15 → nearest step **25**, and this call would have been KEEP. At 15 it returns 0. The conviction was scored before the target, not after. **And the strongest argument against this call is not the one that was most tempting to rebut, so it is stated instead:** the rates axis has read defensive on only **8 of 252** testable sessions. A signal that fires 3% of the time carries far more information when it fires than breadth or volatility do. **If a reader weights rates by its rarity rather than by its count of one, the correct call is KEEP-25 and the arithmetic says so explicitly.** What weighs against it: rates *improved* within itself today, so the rare signal is pointing the right way on its own margin even while its level keeps the axis standing. The opposite theater risk also applies — a conversion day invites dressing the decision as inevitable, and it was not.

**Park state, measured at the broker:** VOO **13.3540 sh** × 712.78 = **$9,519.13**; SGOV **31.0781 sh** × 100.61 = **$3,126.56**; securities total **$12,645.69**; settled cash **$2,715.94**; NAV **$15,914.83**. Converting to f=0 sells the whole 31.0781 SGOV and buys ≈4.387 VOO.

---

## RECOMMENDED ACTIONS

- **Watchlist add — VKTX** to the Strategy B new-entry candidates state index (index-only; **no** thesis construction routed, B router `DO-NOT-ACTIVATE` and capital-disabled), qualifying event date **2026-09-22**.
- **Watchlist add — BFLY**, same treatment, qualifying event date **2026-09-22**.
- **Watchlist add — CLDX**, same treatment, qualifying event date **2026-09-22**.
- **Watchlist add — SNDK**, same treatment, qualifying event date **2026-09-22**.
- **Watchlist add — RCL**, same treatment, qualifying event date **2026-09-22**.
- **Watchlist add — SHOP**, same treatment, qualifying event date **2026-09-21** (the one anchor of the six that is not today).

**No exits triggered. No add candidates flagged. No router review recommended.**

*NOTE, deliberately not a bullet and deliberately absent from the block below: the* `## PARK ALLOCATION CALL` *above is a* **BOUND RE-RISK to** `target_f_pct` **0**. *D2 reaches it through* `state.park_allocation_latest`, *never through* `d1_actions` *or prose-parsing, so it is not a* `router_review` *entry and there is no* `park` *action type. Encoding it here as a bullet would make the prose-bullet count and the block's entry count disagree and would halt D2 on a false* `missing_dependency`.

*NOTE 2, for D2 before it converts the park call: the park was liquidated ~17.6% pro-rata at this morning's open by orders this system did not stage (*`ops.alerts` `park_unexplained_liquidation`*), leaving $2,715.94 of settled cash outside both sleeves. The f=0 conversion is sized off the SGOV sleeve as it now stands (31.0781 sh), not off the pre-liquidation book.*

```yaml d1_actions
- action: watchlist
  ticker: VKTX
  strategy: B
  qualifying_event_date: 2026-09-22
  source_research_screen_id: 587a88e4-31b3-4899-ab31-26f9f63bbacc
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, no thesis construction
    routed, B router DO-NOT-ACTIVATE and capital-disabled). +35.6692% close-to-close 30.11 ->
    40.85, IBKR RTH daily bars contract 192379311, both bars stamped 13:30:00Z, close array read
    at both ends, issued in a strictly-sequential solo pull. Qualifying event: positive topline
    from the VK2735 maintenance study (dual GLP-1/GIP agonist), issuer press release via
    PRNewswire 2026-09-22 07:05 ET, PRE-OPEN, so the anchor and the reaction session are the same
    day and criterion 1 is tested on today's move. ANCHOR CONFIRMED to the clock from the issuer's
    own release. Largest move on the board; clears B Entry criterion 1's frozen >=5% floor by 7.1x.
    Cap $4.77B (FMP profile-symbol). Four-part field identity (item_type, strategy, ticker,
    qualifying_event_date) checked against open and terminal events.queue_events history and the
    B new-entry index - no prior VKTX record. D2 must perform the real field-based dedupe, never a
    key-string match.
- action: watchlist
  ticker: BFLY
  strategy: B
  qualifying_event_date: 2026-09-22
  source_research_screen_id: 587a88e4-31b3-4899-ab31-26f9f63bbacc
  detail: >-
    ADD to the Strategy B new-entry candidates state index, same index-only treatment. +21.9902%
    close-to-close 8.14 -> 9.93, IBKR RTH daily bars contract 470662751, both bars stamped
    13:30:00Z. Qualifying event: Needham initiated coverage at Buy with a $10 price target,
    published 2026-09-22 06:39 ET, PRE-OPEN. ANCHOR CONFIRMED as to date and session; the
    timestamp is AGGREGATOR-SOURCED (MT Newswire via MarketScreener) because Rosenblatt-class
    sell-side initiations carry no public issuer release, and that is stated rather than dressed
    as issuer evidence. Cap $2.64B. CAVEAT FOR THE THESIS SESSION, recorded because it cuts
    against the candidate: a 22% move on an initiation ALONE carries no new company information -
    this is a float/liquidity event, and D1 scored its significance at 45 rather than 75 for
    exactly that reason. Cleared criterion 1 by 4.4x regardless. No prior BFLY record.
- action: watchlist
  ticker: CLDX
  strategy: B
  qualifying_event_date: 2026-09-22
  source_research_screen_id: 587a88e4-31b3-4899-ab31-26f9f63bbacc
  detail: >-
    ADD to the Strategy B new-entry candidates state index, same index-only treatment. -11.5598%
    close-to-close 37.89 -> 33.51, IBKR RTH daily bars contract 353042531, both bars stamped
    13:30:00Z. Qualifying event: Phase 3 EMBARQ-CSU1 and EMBARQ-CSU2 topline for barzolvolimab in
    chronic spontaneous urticaria - BOTH trials hit the primary endpoint AND all key secondary
    endpoints - issuer press release via GlobeNewswire 2026-09-22 pre-open, ahead of an 08:00 ET
    webcast. ANCHOR CONFIRMED as to date and session; the exact release minute was not visible on
    the IR mirror page and is recorded as unresolved to the clock rather than defaulted. Cap
    $2.23B. THE STRONGEST MECHANISM OF THE SIX: a positive surprise met with an 11.6% decline is
    the sentiment-versus-information divergence Strategy B exists to ask about, which is why D1
    scored it 75. Clears criterion 1 by 2.3x. No prior CLDX record.
- action: watchlist
  ticker: SNDK
  strategy: B
  qualifying_event_date: 2026-09-22
  source_research_screen_id: 587a88e4-31b3-4899-ab31-26f9f63bbacc
  detail: >-
    ADD to the Strategy B new-entry candidates state index, same index-only treatment. +6.8152%
    close-to-close 1766.64 -> 1887.04, IBKR RTH daily bars contract 760250490, both bars stamped
    13:30:00Z. Qualifying event: Rosenblatt initiated coverage at Buy with a $2,400 price target,
    2026-09-22 05:17 ET, PRE-OPEN. ANCHOR CONFIRMED as to date and session, timestamp
    AGGREGATOR-SOURCED (MT Newswire) for the same structural reason as BFLY. Same caveat as BFLY
    and it is the reason significance was scored 45: an initiation carries no new company
    information. It is noted as a point in the name's favour that a 6.8% response to a price
    target in a name this size is a larger reaction than an initiation usually commands. Clears
    criterion 1 by 1.4x - the narrowest margin of the six, so a re-measurement before any thesis
    work is worth the call. No prior SNDK record.
- action: watchlist
  ticker: RCL
  strategy: B
  qualifying_event_date: 2026-09-22
  source_research_screen_id: 587a88e4-31b3-4899-ab31-26f9f63bbacc
  detail: >-
    ADD to the Strategy B new-entry candidates state index, same index-only treatment. -6.1379%
    close-to-close 250.25 -> 234.89, IBKR RTH daily bars contract 11520, both bars stamped
    13:30:00Z. Qualifying event: a Financial Times report that Royal Caribbean is near a ~$3B deal
    for a 50% stake in Sandals Resorts International, valuing Sandals at ~$6B; corroborated by
    Reuters and CNBC. ANCHOR LIKELY, NOT CONFIRMED, and the reason is recorded rather than
    smoothed: the FT original is paywalled and its own publish timestamp could not be obtained;
    the earliest secondary confirmations are Investing.com 14:25 ET and CNBC 15:33 ET, both
    2026-09-22 afternoon, which bounds the event inside the session but not to the clock. NOTE
    THE EVENT SHAPE: the wire-crossing event here is a press REPORT of talks, not a company
    announcement, so the deal itself is unresolved and a confirmation-or-denial is a second and
    larger event inside any 10-day window. Clears criterion 1 by 1.2x. No prior RCL record.
- action: watchlist
  ticker: SHOP
  strategy: B
  qualifying_event_date: 2026-09-21
  source_research_screen_id: 587a88e4-31b3-4899-ab31-26f9f63bbacc
  detail: >-
    ADD to the Strategy B new-entry candidates state index, same index-only treatment. THE ANCHOR
    IS 2026-09-21, NOT TODAY, AND CRITERION 1 IS TESTED ON THE 09-21 SESSION ACCORDINGLY:
    +7.3307% close-to-close 128.50 -> 137.92 on 2026-09-18 -> 2026-09-21, IBKR RTH daily bars
    contract 195014116, both bars stamped 13:30:00Z. It also moved +7.1201% on 2026-09-22
    (137.92 -> 147.74), so unusually this name clears on EITHER anchor and nothing turns on the
    choice except the window end date, which runs from the anchor: 10 trading days from
    2026-09-21 closes 2026-10-05, one session earlier than the other five. Qualifying event: the
    Shop Pay checkout integration inside Meta's Muse AI agent, announced INTRADAY on 2026-09-21
    at approximately 11:04 ET via Shopify's CEO's own post and corroborated by PYMNTS and WSJ as
    Monday. ANCHOR LIKELY, NOT CONFIRMED: Shopify appears to have briefed rather than issued a
    dated newsroom release, so there is no issuer timestamp to cite. IMPORTANT DISAMBIGUATION
    carried so a later reader does not merge two events: the Muse LAUNCH itself was 2026-09-08
    and is a separate, earlier event that is NOT this anchor. No prior SHOP record.
```

---

## PROCESS NOTES

**A write defect of my own, found by verification and corrected append-only.** The `sector-move` `research-screen` row landed first as `39deb2b3` with **`fields` NULL** — a placeholder expression was passed in the twelfth positional argument of `sp_log_decision` instead of the fields JSON. `state.research_screen_calls` parses `fields` and nothing else, so that row was invisible to W5's scorecard and to `analytics.research_screen_disagreements`. It was replaced by **`730ccc29`**, carrying `in_superseded_by=39deb2b3` and the `correction` tag; the original is left untouched because `events.decision_log` is append-only. **No measurement changed** — the defect was entirely in the write. Every subsequent decision_log write this run was verified by reading `fields` back and checking the parsed counts against their expected values before moving on, which is how this was caught at all.

**`fields.routine` is populated on both screen rows**, which is the field W5's open `research_screen_calls_routine_unattributed` notice is about. That notice is not closed by two rows, but it is not made worse by them.

**Recorded and NOT fixed here, with owners named:**
- **The unstaged park liquidation** — `ops.alerts` `park_unexplained_liquidation` (`5c04fcb8`, `warning`), owner **D2a** (§13.E sweep/cover and the §13 cash tripwire; D2a is the only writer of `events.parking_events` and the only routine that sweeps settled cash into the park). D1 is research-only and stages nothing, so raising it with the full fill detail, both readings of what it could be, and the round-trip hazard is the whole of what this routine can do about it.
- **The IBKR parallel cross-contamination defect** (`7cc25b71`, owner OPS1 / `ops/connector_tools.yaml`) — contained again this run by strictly sequential pulls and an explicit cross-batch self-check, **not** repaired.
- **The stale `zilganersen` PDUFA row on Benzinga's FDA calendar** — third documented appearance; refused again. Owner is the aggregator, not this repo; the FDA limb that catches it is already in the prompt and worked.
- **`DINO`'s and `MPC`'s disputed magnitudes** — measured, re-derived once each on clean solo pulls, and reported as disputed rather than resolved in our own favour.

**Metered-call discipline.** Six sub-agents ran this session (deferred-write recovery, market-wide/scheduled events, single-name discovery, equity breadth, HF + treasury, anchor-timestamp resolution) plus a dedicated IBKR price desk that owned **every** price call so no two agents could touch that connector concurrently. The anchor-resolution leg deliberately spent above its budget — three SEC EDGAR acceptance-timestamp chases needed sequential index-page fetches once the accession numbers were discovered — and that spend is exactly what disqualified VICR, GRAB, LEN and GME. The `ops.web_calls` rows for this run are written before the terminal `sp_routine_end`.
