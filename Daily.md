2026-09-20
<!-- d1_scan_through_utc: 2026-09-20T22:09:44Z -->

# Daily Market Development Scan — 2026-09-20 (Sun, MT)

**Scan window: 2026-09-17 16:33 MT → 2026-09-20 16:09 MT** (**71.6h — a MULTI-SESSION GAP, stated explicitly per the >50h rule, and an EXPECTED one**: D1's cadence is Sun–Thu, so there is no Friday or Saturday fire and this Sunday run is the first one able to cover the Friday session). Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-17T22:33:15Z -->` marker, cross-checked against that file's own commit at `2026-09-17T22:38:00Z` — the two agree to within five minutes. `state.routine_catchup_window` independently gives `window_days = 2.98` for D1, consistent with the marker. **ONE completed US trading session inside this window: Friday 2026-09-18.** `state.trading_day_today` gives `is_trading_day = false`, `last_trading_day = 2026-09-18`, `next_trading_day = 2026-09-21`. **Every close-to-close figure in this file is measured 2026-09-17 → 2026-09-18.**

**Tape — nine of eleven sectors fell, the defensives fell with them, and the index barely moved. That combination is a rates repricing, not risk aversion.** SPY 762.60 → **761.69** (**−0.1193%**) on **27,034,733** shares against 27,364,608 on 09-17 and a trailing-eleven-session range of 19.1M–37.8M. VOO 701.03 → **701.78** (+0.1070%). QQQ **+0.6319%** (716.92 → 721.45) led while DIA **−0.4765%** and IWM **−0.4660%** lagged — the same large-cap-growth-over-everything split as the week before. **Volatility kept falling: VIX 15.44 → 14.81, −4.0803%, its first sub-15 close of this episode, now −5.9025% below its 20d SMA of 15.7390.** But **yields gave back the entire 09-17 rally**: 2Y 4.67 → **4.76** (+9bp, a cycle high), 10Y 4.94 → **5.01** (+7bp, back above 5.00), 30Y 5.29 → **5.34** (+5bp), so the 10Y−2Y spread flattened to **+0.25** from +0.27. TLT **−0.6481%**, LQD −0.4374%, HYG −0.2414%, IEF −0.4932%, SGOV +0.0298%. Brent (BZX6) 104.82 → **103.87** (**−0.9063%**, a third consecutive decline) and USO −0.9594%. GLD **+0.7054%**. UUP +0.0352%. **BITO +6.2257%** — the loudest move on the board. Equity breadth ($S5TH) **50.29 → 49.50, −0.79pp**, the **first sub-50 reading of this episode**. **Two of eleven GICS sectors higher, nine lower, none flat**, cross-sector spread **2.2387pp** (XLK +0.8189% to XLB −1.4198%) against 2.8201pp on 09-17 — a second consecutive session of narrowing dispersion.

**THE SESSION WAS MECHANICAL BEFORE IT WAS DIRECTIONAL, and that discounts everything below.** 2026-09-18 was quarterly **triple witching** — roughly **$7.1 trillion** notional of equity, index and index-futures options expiring at once, about a quarter of all US options notional outstanding (Citadel Securities via press, corroborated by Goldman and Citi; sources disagree only on whether it was the largest or the second-largest ever) — coinciding with the **S&P 500 and Nasdaq-100 quarterly rebalance** effective at the close. A −0.12% index print on an expiry that size carries little information, and no conviction in this file's screens is set above 60 for that reason.

All equity/ETF figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), every bar verified carrying a 2026-09-18 stamp of `13:30:00Z`. Two documented exceptions, stated rather than hidden: the ^VIX bar (contract 13455763, `IND`/CBOE) stamps `07:15:00Z` and carries `delayed:900`, an index-feed property rather than an equity RTH bar; and Brent is a NYMEX future (BZX6, contract 339981284) carrying `delayed:600` and sitting ~10 days from expiry. Treasury yields are the Treasury par curve via FMP `economics/treasury-rates`, date-pinned 2026-09-16→2026-09-18. A Barron's/Dow Jones 3pm quote independently read 10Y 4.995 and 2Y 4.741 for the same session — a different convention, not a contradiction, and the par curve is this file's basis as in every prior run.

**THIS RUN IS NOT DEGRADED, AND THAT IS MEASURED.** 39 distinct single names and 15 index/ETF/future instruments were put to IBKR for confirmation; **every one returned a genuine 2026-09-18 regular-session bar. Zero symbol-level denials. Zero measurement failures. Zero discovered-but-unconfirmable names.** Every `surfaced_count` in this file is affirmatively established, never a reported zero standing in for an unmeasured population.

**A LIVE CONNECTOR DEFECT WAS HIT AND CONTAINED, AND IT CHANGED HOW THIS RUN WORKED.** `ops.alerts` `7cc25b71` (W1, this morning) records that IBKR `get_price_history` returns **another ticker's series** at parallel concurrency ≥5 — no error, a perfectly well-formed confident wrong answer. A first, parallel-batched confirmation pass in this run **exhibited exactly that signature**: XLK carrying LQD's volume, XLI carrying AMZN's volume, UUP carrying USO's volume. **That pass's entire volume column was discarded rather than reconciled**, the whole single-name confirmation was re-run **strictly sequentially at concurrency 1** (35 instruments, one call per message), and the seven load-bearing series — SPY, VIX, HYG, IEF, XLU, XLB, ORCL — were additionally re-pulled **solo by the orchestrator**. W1's cheap detector was then applied: **no two of the 35 sequentially-confirmed instruments share an identical close or an identical volume to full precision.** Every close in this file is from the sequential or solo pulls; no figure is taken from the contaminated batch. The defect itself is OPS1's (`ops/connector_tools.yaml`) and is **not** fixed here.

---

## TL;DR

- **Exits triggered: none.** Not one of the 12 open tranches carries a `convergence_target` or a `time_exit_date` (both are B/E fields and B and E hold nothing), so zero mechanical triggers could fire and zero did; no thesis-invalidation criterion is met either. No position tests a price level, so no dividend netting was owed.
- **New entry candidates: 5 (XENE, NUE, BE, MSTR, COIN)** — all Strategy B, all **state-index only**; B is `DO-NOT-ACTIVATE` and capital-disabled, so no thesis construction is routed.
- **Add candidates: none.** 12 D tranches evaluated, 0 flagged, 3 declined at the HARD GATE (ISRG, RTX, UBER). **DIS is a genuine dip-with-intact-thesis trigger and is declined on D's capital-disabled router state, not on its merits** — recorded so the series does not read as though nothing ever qualified.
- **Watchlist changes: 5 adds** to the Strategy B new-entry candidates state index, per the above.
- **Regime review: no review.** No development moves a router state; default NO on ambiguity holds. Breadth did cross below the vocabulary's 50% HEALTHY line for the first time — recorded as an observation, since the threshold is D2a's to apply.
- **Park: KEEP, `target_f_pct` 25 unchanged, MEDIUM 45, BOUND.** Zero axes entered, zero exited, increase gate shut.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**The record-size expiry and the index rebalance are the session's largest single fact, and they are mechanical.** Quarterly triple witching (~$7.1T notional) plus the S&P 500 / Nasdaq-100 quarterly rebalance took effect at Friday's close. **Bloom Energy, Illumina and Everpure were added to the S&P 500**; SpaceX received a weighting increase in the Nasdaq-100 rebalance. Sources: Barchart/Yahoo/TradingView wire copy, 2026-09-18; Gokhshtein Media and BigGo Finance for the notional (the two disagree on the superlative and both are cited rather than one being picked).

**Iran / Strait of Hormuz — an escalation headline inside the window, and the oil tape went the other way.** Iran claimed it struck an oil tanker in the Strait on 2026-09-18 (AP News), amid continued Saudi–Houthi cross-border exchanges (Reuters, 09-18). Against that, **crude fell for a third straight session** — Brent −0.9063% to 103.87 — on reports that Saudi East-West (Petroline) repair was progressing faster than feared and that China had pressed Iran to restrain Houthi action. **That is the tell, and it is the same one as 09-17: a market pricing escalation does not sell oil into a tanker strike.** The bearing on this file is the park's shock axis, where it is recorded as evidence pointing away from the standing `acute` overlay rather than toward it.

**Turkey's fund-liquidity selloff (Reuters, 2026-09-17)** sits one day before the window opens and is carried as backdrop only: a liquidity crunch at Turkish investment funds hit Borsa Istanbul banks, regulators cut margin-maintenance requirements, and analysts (Aberdeen, Tellimer) called it idiosyncratic and contained. **German state elections in Berlin and Mecklenburg-Vorpommern were held Sunday 09-20** — inside the window, with no market reaction available yet since no session has priced them.

**No material bankruptcies, natural disasters or new unscheduled regulatory/enforcement actions of market-wide scale were found in the window.** Stated as a measured absence: four searches covering geopolitical, regulatory and breaking-news angles across 09-17→09-20 returned nothing in this class.

### 2. Scheduled events that resolved in the window

**The Bank of Japan resolved, and this closes the prior run's explicitly-deferred PENDING item.** The 09-17/18 meeting decided Friday: **+25bp to 1.25%**, by a **7–2 majority vote** (dissenters Toichiro Asada and Ayano Sato), **the highest policy rate since 1995** — a 31-year high — with the new guideline and the 1.5% basic loan rate effective 2026-09-24. **Primary source read directly: the Bank of Japan's own Monetary Policy Statement PDF** (`boj.or.jp/en/mopo/mpmdeci/mpr_2026/k260918a.pdf`), not an aggregator. The reaction inverted the textbook: **the yen WEAKENED**, ~156 → ~157.8/USD (−1.2%), and the Nikkei rose ~1.5%, because markets read the two dissents and the absence of explicitly hawkish forward guidance as a slower path — Governor Ueda declined to rule out 50bp or back-to-back moves but said underlying inflation "hasn't exceeded 2% yet." Reuters-polled analysts now see 1.5% by end-March and 1.75% in Q2 2027. **Bearing on this file:** a third major central bank tightening in the same week is carried into the park's rates axis as degree, not as a new firing.

**The FOMC's 25bp hike to 3.75–4.00% (2026-09-16) is OUTSIDE this window** — it resolved one day before the window opens and is carried as context only, per the EVENT-IDENTITY GATE. No figures from it are recorded as in-window, and no event-dependent criterion is assessed against it here.

**Steel guidance — the session's only company-issued, non-thematic signal, and it explains the worst sector.** **Nucor (NUE)** and **Steel Dynamics (STLD)** both guided Q3 EPS below consensus on 09-18 (STLD $5.34–5.38 against $5.55 consensus). NUE closed **−6.3211%** and STLD **−4.1125%**; materials (XLB) was the worst GICS sector at **−1.4198%**.

**FDA — Ultragenyx UX111 / "Fayuvi" (Sanfilippo Type A gene therapy) was APPROVED 2026-09-17**, two days ahead of its 09-19 PDUFA target. Confirmed against **the FDA's own Novel Drug Approvals 2026 list**, not an aggregator. It lands at the very edge of / just before this window and is recorded with that ambiguity stated rather than claimed as in-window.

**FDA limb — two aggregator rows REJECTED against the FDA's own page, which is the discipline this run added to the D1 prompt.** Aggregator calendars still show (a) a 09-18 PDUFA/approval for **Nuvalent/GSK zidesamtinib ("Jideytro")** and (b) a 09-22 PDUFA for **Ionis zilganersen**. Both are stale: **zidesamtinib was approved 2026-07-22 to NUVALENT (NUVL), not GSK**, ~two months ahead of target, and **zilganersen was approved 2026-09-03**. W1 struck both on 2026-09-13 and **D1 re-imported them on 2026-09-17** inside a sentence framed as a measured absence (`ops.alerts` `031108b9`). **They are not carried here, and the rule that stops a third repeat is now in the plan.** No confirmed pending ≥$2B-sponsor PDUFA date was verified for the week of 09-21.

**No major US macro release fell inside the window** — the last was Philadelphia Fed Manufacturing on Thu 09-17, before the window opens, and the weekend carries no scheduled US data.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

Full durable record: `events.decision_log` `ce24e9cb-603d-4c8e-81fa-1a7a9fad0ff6` (`screen='single-name-move'`). **39 single names measured, `rail_tally` 27, `surfaced_count` 15.** Agreement: both 7, ai_only 8, rule_only 2.

**Two of the three new S&P 500 members FELL on the day their inclusion took effect — that is this screen's finding.** **BE −5.3890%** (280.76 → 265.63) and **ILMN −2.2677%** (245.18 → 239.62) were both added effective at Friday's close and both were sold into it; the textbook index-add bid did not appear. Neither alone would establish anything; two of three moving the same way on the same mechanical event is worth a durable record. Recorded as an observation, **not** a tradeable regularity — one session of evidence, and inclusion effects are exactly the sort of thing that reverses.

**The AI-power complex split down the middle, which is new.** After two weeks of moving as one block: **SMR −8.5177%**, **BE −5.3890%**, **CEG −3.0784%** and **VST −2.0131%** fell while **ETN +3.7391%** and **VRT +3.2711%** rose — a ~12pp spread inside one theme in a single session. The mechanism is **not** established; a rates-driven de-rating of capital-intensive generation while short-cycle equipment demand holds is the obvious reading and is consistent with utilities being the second-worst sector on a 7bp rise in the 10Y, but nothing here proves it. ETN is surfaced specifically to carry the divergence, on the 2026-09-14 RIG precedent.

**XENE −30.6888% is the largest move on the board and the only clean company-specific catalyst** — a ~$3.84B biotech losing roughly a third of its value after pausing enrollment in trials of its experimental depression/bipolar candidate on reports of side effects (Reuters, 09-18). Attribution is secondary press reporting the company's own action, not a release read directly.

**The crypto complex is one cause and is deliberately not written up six times.** MSTR **+16.3856**, SECZ **+21.6125**, MARA **+13.7457**, COIN **+11.6571**, BMNR **+8.7903**, IBIT **+6.2818** all trace to bitcoin above $80,000 after the SEC cleared a regulatory path for tokenized stocks. **MSTR** (balance-sheet channel) and **COIN** (business-model channel — tokenized-stock rulemaking bears on what a regulated exchange may list, not merely on a holdings mark) are surfaced as representatives; MARA and BMNR are rejected as duplication and are this screen's two `rule_only` disagreements; IBIT is an ETF and outside a single-name population.

**The automaker reversal has no company news attached and is recorded that way.** GM **−5.1028%**, STLA **−4.5545%**, F **−2.9390%**: Thursday's cyclical rally unwound, and the best-sourced account states explicitly there was zero company-specific news. **GM therefore clears the 5% bar but is NOT routed even to the B state index** — criterion 1 requires a public *event* producing the reaction, and a rotation unwind is not one. Same for **SMR**, whose attribution is sector-level only.

**Four names moved ≥2% with no established driver at any level, and are recorded as unexplained rather than narrated:** **META −2.4271%** (the only Magnificent-7 decliner on a session when NVDA +1.3357, AVGO +2.9686 and MU +3.9182 rose), **TTD −2.3843%**, and of the held book **ISRG +2.5525%** (up 2.80pp against its own sector) and **DIS −2.5439%** (1.17pp worse than XLC).

**Near-boundary cap, disclosed: SMR is the one name where the $2B rail call is not comfortably settled.** FMP `profile-symbol` gives **$2.46B**, ~23% above the rail and therefore **inside Operating_Protocols.md §11's ~25% near-boundary band — where §11 explicitly rules `profile-symbol` INADMISSIBLE** and requires re-deriving shares outstanding from the issuer's own 10-Q/10-K. **That re-derivation was not performed and is not claimed.** SMR is retained because the measured FMP error direction for this exact name is ~30% *understatement* (2026-08-30: $2.77B against $3.81–3.99B from two independent sources, the up-C Class B share count being the documented cause), so the binary call is safe in the direction that matters. **SECZ ($1.61B) and GENI ($1.45B) fail the cap rail outright** and are listed in `rejected_notable` as Layer-1 exclusions — **deliberately NOT counted as `rule_only`**, consistently with the BZ ruling this run applied when correcting the 2026-09-14 screen.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

Full durable record: `events.decision_log` `4f06d0b0-4c9a-4665-9660-bb5befc58cb3` (`screen='sector-move'`; supersedes `5bc3bb3c`, see Corrections below). **11 measured, `rail_tally` 3, `surfaced_count` 6.** A **pure AI-only day**: agreement both 0, ai_only 6, rule_only 0, `rejected_notable` empty — **not one sector cleared the old fixed 2% bar**, the largest move on the board being 1.4198%.

XLK **+0.8189%** · XLI +0.4378% · XLF −0.0358% · XLV −0.2488% · XLE −0.2636% · XLY −0.3232% · XLP **−0.8264%** · XLRE **−0.9548%** · XLC **−1.3707%** · XLU **−1.4152%** · XLB **−1.4198%**.

**THE FINDING: THE DEFENSIVES FELL TOO, AND THAT IS WHAT THIS SESSION MEANS.** Nine of eleven sectors were lower — but so were **all three defensive sectors and real estate**. A risk-off rotation *bids* defensives; this session sold them, with the two most duration-sensitive sectors (XLU, XLRE) among the four worst on a 7bp rise in the 10Y to 5.01, while technology and industrials rose. **This distinction is load-bearing for the park call below**, and it is recorded in the screen so it does not live only there. Drivers: XLB on the two steel guidance cuts (the only company-issued cause on the board); XLU on rates plus the AI-power complex being sold independently; XLC on a clean single-name chain (NFLX −4.6738 on a Wells Fargo downgrade to underweight, PT $57; PSKY −3.8606; TTD −2.3843; META −2.4271) for a second consecutive session as a worst-or-near-worst sector. XLRE, XLP and XLK are the three sub-rail surfacings permitted by §19's escape valve — XLP because a staples decline is the single most informative datum separating a rates repricing from risk aversion, XLK because the AI-memory bid behind it (MU, AVGO, SKHY, SMH) was the session's only genuine risk appetite and surfacing the nine-down side alone would misrepresent the board.

**Measurement provenance, because a prior run found nine of eleven sector contract ids wrong.** XLU and XLB — the two largest fallers, which decide the rail — were re-pulled **solo** and both reproduced. Two independent continuity checks tie this series to the corrected one: XLC's 09-17 close of 112.35 against the prior file's 09-16 close of 113.00 reproduces the 09-17 row's **−0.5752%** digit for digit, and XLF's 55.88/55.93 reproduces its **−0.0894%**. The registry gap itself remains open as `ops.alerts` `716d9ab3`, owner W5, and is **not** fixed here.

### 5. Notable commentary

- **Kevin Warsh (Fed Chair)** — the 09-16 press conference's hawkish tone ("inflation is too high") continued to set the week's frame; resolved before this window and carried as context.
- **Kazuo Ueda (BoJ Governor)**, 09-18 press conference: "this phase has just started"; would not rule out 50bp or back-to-back hikes but noted underlying inflation "hasn't exceeded 2% yet" and that the Bank wants to "act pre-emptively." Read as neutral-to-hawkish in substance and dovish in market effect.
- **Jamie Dimon (JPMorgan)**: "It's not clear to me we've slayed inflation."
- **Ben Snider (Goldman Sachs)**, 09-18: flagged "earnings bubble" concerns; base case deceleration, not collapse, in S&P 500 earnings growth.
- **Daniel Skelly (Morgan Stanley WM)**, 09-18: near-term volatility risk from oil, yields and midterms; constructive longer term on AI adoption.
- **Wells Fargo** downgraded **Netflix** to underweight (PT $57) on 09-18 — the identified driver of XLC's decline.
- **Christine Lagarde (ECB)**, 09-18 RTE Radio: expects to leave the ECB "in '27", before her term formally ends in October 2027.
- **Berkshire Hathaway**: Warren Buffett stepped down as chairman on 09-18, becoming chairman emeritus; Howard Buffett named chairman. Corporate governance rather than a scheduled event.
- One third-party markets blog attributed to "GS Economics" a call for another 25bp hike in October with a 3.25–3.50% terminal rate. **Flagged as low-confidence secondary sourcing** — the terminal rate quoted sits *below* the current target range, which is internally incoherent, so it is recorded as unreliable rather than repeated as a fact.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

**MECHANICAL EXIT-TRIGGER SWEEP — run for every open position, and empty for a structural reason worth stating.** The open book is **12 tranches across 8 names, every one Strategy D**. **Not one carries a `convergence_target` or a `time_exit_date`** — those are Strategy B / E fields, and B and E hold nothing — so **zero mechanical triggers could fire and zero did.** This is a genuine absence, not an unchecked one.

The sweep was run over the **UNION** of `state.current_positions` and live `get_account_positions`, per the 2026-07-11 ITEM-14 rule. The broker shows exactly AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER plus the VOO/SGOV park sleeve and **nothing else**, and every book name appears at the broker. **No reconciliation-lag position exists and no `position_reconciliation_lag` alert is owed.**

**PER-STRATEGY KILL-TRIGGER SWEEP.** `perf.kill_flags` carries rows for **B and D only** (A, C, E hold nothing). Every flag is FALSE for both: `drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `gate_reached`, `interim_underperf_warning`. No `interim_underperf_warning` alert is owed and none is open to heal-resolve.

**The `current_drawdown` refresh was performed UNCONDITIONALLY against live 09-18 marks, as the rule requires — and it had to be computed in-session rather than read.** The engine row for D is stamped 2026-09-17 (`deployed_unit_value` 1.059721779, `peak` 1.098110312, `current_drawdown` −3.4959%) because D2a has not run since 09-17; its cadence is Sun–Thu, so Friday's session is reconciled by tonight's run, and `state.freshness` correctly reads `marks_fresh = false` / `engine_fresh = false`. Computing the book's 09-18 value-weighted return from per-tranche share counts and confirmed closes gives **+0.5607%**, so D's deployed unit value is ≈**1.065664** and **`current_drawdown` ≈ −2.9547%**, an improvement from −3.4959%. Against the **−50%** drawdown-kill threshold that is not remotely close. **No STRATEGY TERMINATION — DRAWDOWN flag. No RUNAWAY-SUCCESS flag** (D has 1 closed trade against a 30-trade gate and its TWR has not doubled).

**B open-book pairwise-correlation warning — INERT, and now structurally so.** `analytics.b_pairwise_correlation` returns `n_positions = 0`, `n_pairs = 0`, with `avg_offdiagonal_corr` and `min_overlap_days` NULL. Strategy B holds **nothing** — its last position (MDT) is gone and the ISRG B exit filled in August — so the `n_positions >= 2` limb fails on zero rather than on one. No `b_pairwise_corr_high` alert is owed.

**DIVIDEND NETTING ON A PRICE-LEVEL CRITERION — checked, not owed.** `state.price_level_criterion_drift` holds exactly one row, `D:DIS:2026-08-05`, and it is **not** an actionable price-level exit criterion: `is_exit_criterion = false`, `actionable_price_level = false`, `criterion_key = not_exit_triggering`, `has_dividend_drift = false`, `cum_dividend_since_reference = 0`, and `marks_cover_reference = true` (so the dividend total is complete, not a lower bound) with `reference_date_declared = false` noted. **No position in this book tests a PRICE LEVEL**, so no comparison against a raw close was made and none needed netting.

**Per-position thesis-invalidation assessment against this window's DEVELOPMENTS — no criterion is met on any of the 12.**

| Position | 09-18 move | Development bearing on it | Invalidation met? |
|---|---|---|---|
| D:AMZN ×2 | **+1.0032%** | None. Crypto, steel, autos, index rebalance and the BoJ touch nothing in AMZN's structural case. | **NO** |
| D:DIS ×2 | **−2.5439%** | Communication services −1.3707% on a media/ad-tech de-rating (NFLX downgrade), but **no DIS-specific news** — it fell 1.17pp worse than its sector with no established driver. An adverse mark with no new information is explicitly "not exit-triggering". | **NO** |
| D:GEV | **+1.6650%** | The AI-power complex split and **GEV was on the rising side**. Its orders-growth invalidation criterion is untouched and GEV disclosed nothing. The GLJ forward backlog-margin bear case from 09-14 remains unaddressed but is not an invalidation event. | **NO** |
| D:GOOGL ×2 | **+0.6363%** | Nothing bearing on Cloud revenue, margin or RPO. | **NO** |
| D:ISRG | **+2.5525%** | Largest single-session move in the book, **with no established driver** — recorded as unexplained. No competitor-displacement evidence, so criterion 4 is untouched. | **NO** |
| D:RTX | **+0.2377%** | Nothing. | **NO** |
| D:TSM ×2 | **+1.0250%** | Its criterion 3 names a structural AI-capex reset via hyperscaler/Nvidia order cuts or a CoWoS utilization drop. **Neither moved**, and the session's AI-memory bid (MU +3.9182, AVGO +2.9686, SKHY +2.4645, SMH +2.2101) points the other way. | **NO** |
| D:UBER | **−0.5221%** | Nothing. | **NO** |

**Watchlist candidate status.** The Strategy A queue (~45 names) is uniformly held out by A's `DO-NOT-ACTIVATE` router with trigger "Next M1 with A router ACTIVATE" — unchanged by anything in this window. The Strategy B overflow blocks and new-entry index are likewise router-held. Two Strategy D re-screens are live: `rescreen-LLY-D-20260914` (complete; a further `rescreen-LLY-D-20261214` is pending) and `rescreen-NKE-D-20260925` (default decline). **One new queue item appeared today from another routine and is noted rather than actioned here:** `rescreen-ORCL-B-20260920`, due 2026-09-21, created by W2 to carry the ORCL correction's disposition side — D2's to drain.

---

## ANALYSIS — OPPORTUNITY CHECK

Evaluated against every roster-active strategy with `review_cadence: reactive` in `strategy/roster.yaml` — currently **A, B, C, E** (D is excluded via `review_cadence: long_horizon`). All five founding strategies are `roster_state: adopted`; F, G and H are `REJECTED`.

**Every reactive-cadence strategy is router-held, so nothing routes to thesis construction from this window.** A `DO-NOT-ACTIVATE` (`div-A-202608-1`), B `DO-NOT-ACTIVATE` (`div-B-202608-1`), E `DO-NOT-ACTIVATE` (`div-E-202608-1`, capital-disabled effective 2026-09-04, zero open positions); C is `HYBRID ACTIVATE (FOMC-only)` (`div-C-202608-1`).

**Strategy B — five candidates clear the frozen Entry criterion 1 (≥5% close-to-close on event day) AND carry a defensible public event.** State-index only:

| Ticker | Move | Qualifying event (2026-09-18) | Caveat carried to any future thesis session |
|---|---|---|---|
| **XENE** | **−30.6888%** | Enrollment pause in depression/bipolar trials on reported side effects | Cleanest event on the board. Attribution is Reuters reporting the company's own action, not a release read directly. Cap $3.84B. |
| **NUE** | **−6.3211%** | Company-issued Q3 EPS guidance below consensus | Strongest event class here — issuer-originated. Cap ~$55.9B (estimate). |
| **BE** | **−5.3890%** | S&P 500 inclusion effective at the close — **and it fell** | Note the inversion: B's criterion 3 lists index inclusion as a valid *convergence target*, but here inclusion is the **qualifying event**, already consumed. A thesis would need a different convergence target. Cap $78.2B (FMP). |
| **MSTR** | **+16.3856%** | BTC >$80k on the SEC's tokenized-stocks regulatory path | The event is **sector/regulatory, not issuer-specific** — weigh that against criterion 1's "public event" before treating it as one, exactly as the 09-17 run flagged for INTC. Cap $50.9B. |
| **COIN** | **+11.6571%** | Same SEC development, but it bears on COIN's **operating permissions** rather than a holdings mark | The strongest of the two crypto names on event-relevance grounds. Cap ~$49.5B (estimate). |

**Two names clear the 5% bar and are deliberately NOT routed even to the index:** **SMR −8.5177%** (no company-level event; sector repricing only) and **GM −5.1028%** (explicitly zero company-specific news — a rotation unwind is not an event). Both fail criterion 1's second limb, and recording *why* matters more than the magnitude.

**Strategies A, C, E: no candidates.** No newly-announced qualifying catalyst within 6 months surfaced for A, none within 45 days for C, and no intra-industry-group pair divergence for E — the AI-power split (ETN/VRT vs SMR/CEG/VST) is the closest thing in this window, but E is capital-disabled with a `DO-NOT-ACTIVATE` router and the pair screen is M2's monthly call, not D1's.

**`NO-GO records are context, not barriers`** was applied: no candidate above was suppressed by a prior NO-GO, and none of the five carries a prior `events.queue_events` row of any status (checked on the four-part field identity `(item_type, strategy, ticker, qualifying_event_date)`, never on the key string).

---

## ANALYSIS — ADD-CANDIDATE CHECK

Strategies **A, B, D only** (Rev 40). Durable record: `events.decision_log` `add-candidate-review` for 2026-09-20 — **`n_evaluated` 12, `n_flagged` 0, `n_declined_hard_gate` 3**, with every decline and its reasoning logged per position (including `position_key`, added this run because five of eight names carry two tranches that the contract's per-item keys cannot otherwise distinguish).

`mark_vs_cost_pct` uses the **2026-09-18 IBKR regular-session close** over **that tranche's own** `cost_basis / shares` — never the broker's blended `avg_price`, never a snapshot. The broker position endpoint was read only as a cross-check and **its marks were not used**: it served GEV, ISRG, RTX and VOO at exactly the confirmed close but TSM at 432.57 against a true 434.67 (−0.48%) and DIS at 102.93 against 102.67, i.e. it again mixes stale and after-hours prints exactly as the 2026-09-07 pin records.

| Tranche | mark vs cost | Trigger | Disposition | Evaluable |
|---|---|---|---|---|
| D:AMZN:2026-07-09 | +5.1675% | none | declined | false |
| D:AMZN:2026-07-30 | −4.5098% | none | declined | true |
| D:DIS:2026-05-07 | −7.7704% | **dip-with-intact-thesis** | declined | false |
| D:DIS:2026-08-05 | −1.0747% | **dip-with-intact-thesis** | declined | true |
| D:GEV:2026-08-03 | −3.0494% | none | declined | true |
| D:GOOGL:2026-07-09 | −2.8644% | none | declined | false |
| D:GOOGL:2026-07-26 | +6.6180% | none | declined | true |
| D:ISRG:2026-07-20 | +12.5313% | none | **declined_hard_gate** | false |
| D:RTX:2026-04-27 | +9.6671% | none | **declined_hard_gate** | false |
| D:TSM:2026-07-21 | +1.5914% | none | declined | false |
| D:TSM:2026-07-29 | +10.6361% | none | declined | true |
| D:UBER:2026-07-09 | −3.6973% | none | **declined_hard_gate** | false |

**THE HARD GATE — 3 of 12, the same three as every run since 2026-09-06.** ISRG, RTX and UBER carry `$.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'` and are **covered nowhere** by a later tranche with a fresh assessment, so "unbreached" cannot be affirmatively confirmed and they are structurally ineligible. Seven tranches carry that marker in total, but four names (AMZN, DIS, GOOGL, TSM) are covered at NAME level by a later tranche. **`invalidation_criteria_evaluable` was computed on all THREE disjuncts:** no tranche has a NULL `invalidation_status` and **not one carries a `$.status` key at all**, so a two-disjunct rule would have returned TRUE for all twelve — including the three the gate declines — which is exactly the re-hiding the third disjunct exists to prevent. The `COALESCE(..., '')` wrapping is applied so an absent key reads as "not the honest marker" rather than as NULL.

**THE ONE LIVE TRIGGER, AND WHY IT STILL DECLINES.** **DIS is a genuine dip-with-intact-thesis case**: the largest faller in the book at −2.5439% on **no company-specific news**, 1.17pp worse than its own sector, with both tranches below cost and invalidation criteria unbreached. **It is declined anyway, and not because of DIS** — Strategy D is `DO-NOT-ACTIVATE` and **capital-disabled**, so there is no capital an add could be funded from and a flag would be an instruction nothing can execute. This is the same ground on which 09-14 and 09-16 declined GEV with an explicitly strong case, and it is recorded the same way **so that a future session reading this series can see the pipeline produced a candidate and the capital gate stopped it**, rather than inferring from a run of zeros that nothing ever qualified.

**The other nine, briefly.** The session was mildly positive for this book (+0.5607% value-weighted), so dip triggers were scarce by construction — AMZN, GEV, GOOGL, ISRG, RTX and TSM all rose, which forecloses criterion (a) whatever their position versus cost. **GEV** is the case worth naming: −3.0494% below cost with its invalidation criterion untouched, but it rose 1.665% so there is no dip, and no new information strengthened conviction. **UBER** fell and sits −3.6973% below cost, but the HARD GATE is checked first and short-circuits it, which is why its `trigger_type` is `none` — the trigger was never reached rather than evaluated and rejected. **No strengthened-conviction trigger fired anywhere:** nothing in this window's developments bears on a multi-year structural driver for any of the eight names.

**Cross-strategy exclusions** are not binding here: every open position is Strategy D and Strategy.md bars only concurrent A-and-B and A-and-C in the same name. Six of these names also sit on the A queue (`DO-NOT-ACTIVATE`); an A activation on any would face the 30% GICS concentration check, not a same-name bar.

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review is recommended. High bar; default NO on ambiguity holds.**

Nothing in this window plausibly shifts any strategy's activation state. The five current divergence ids (`div-{A,B,C,D,E}-202608-1`) all date to 2026-08 and the FUNDAMENTAL_AXIS scores are as-of 2026-09-01 — none of the session's developments (a record expiry, an index rebalance, two steel guidance cuts, a crypto regulatory path, an automaker rotation unwind, the BoJ's second hike) speaks to a strategy's *activation* conditions as Strategy.md defines them.

**The one thing that came close, and why it is still NO.** Equity breadth crossed **below 50** for the first time in this episode (49.50), and the shared regime vocabulary's Equity Breadth State is **HEALTHY ≥50 / WEAK <50** — a threshold Strategy A's router reads. **But the classification is D2a's to apply, not D1's** (D1 writes `TECHNICAL_INPUT`, never `TECHNICAL_SIGNAL`), the crossing is 0.50pp with a −0.79pp day-over-day, and **A is already `DO-NOT-ACTIVATE`** so a HEALTHY→WEAK flip cannot change A's state in the restrictive direction. It is recorded as an observation for D2a's STEP 1e and for M1a's next scoring, not as a review trigger.

**One recorded ambiguity, unresolved and not resolved here:** `shock_overlay = 'acute'` is as-of **2026-09-01**, nineteen days old, while this window's own evidence (oil falling for a third session into a claimed tanker strike) points toward de-escalation. The overlay is M1a's to re-score, and a standing state is never news; flagged for M1a rather than acted on.

---

## EQUITY-BREADTH OBSERVATION

**Written: `events.regime_events` `as_of_date = 2026-09-18`, `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`, `numeric_value = 49.50`, `value = 'Barchart $S5TH'`.**

- **Figure:** **49.50** as published (`49.50 -0.79 (-1.57%) 09/18/26 [INDEX]`), source **Barchart `$S5TH`**, as-of wording verbatim *"Quote Overview for Fri, Sep 18th, 2026"*. **SOURCE-DATED, not `inferred_post_close`** — the fallback was neither used nor claimed. Fetch path: `tavily_extract` at advanced depth on a cache-busted URL; a rendering `web_fetch` on the identical URL returned an **empty body**, and per the FETCH-METHOD-IS-PROVENANCE rule that condemns the fetch, not the source.
- **Cross-check: TWO usable sources, exact agreement.** EODData `S5TH` independently returned Close **49.50** for 18 Sep 26 (OHLC 48.90 / 50.49 / 48.11 / 49.50). Gap **0.00pp**. The compound EODData unsettled tell does not fire (Low 48.11 ≠ Close 49.50), and today is Sunday — two calendar days past the close.
- **MacroMicro weekly re-probe: DUE TODAY AND SPENT.** Today is Sunday, the first D1 fire of the Sunday-anchored week, so the one permitted probe was attempted on **both** paths with a cache-buster: `tavily_extract` returned `Failed to fetch url`, `web_fetch` returned **HTTP 403**. **The streak is now unbroken since 2026-08-19 on both paths.** MacroMicro is **not** restored to primary; its 2026-08-17 settlement-lag designation remains unrefuted and it resumes primacy the moment it answers.
- **A LARGE PREVIOUS-CLOSE MISMATCH, AND THE STORED PRIOR VALUE IS THE ONE THAT IS WRONG.** Both sources now carry **50.29** as the settled 2026-09-17 value; the row stored for 09-17 reads **51.09**. At **0.80pp** that is **16×** the ~0.05pp overnight-revision band the plan blesses as noise, so it is not that noise. **Cause, measured from the prior row's own text:** D1's 09-17 run recorded in that same `rationale` that **both** vendors carried an on-page timestamp of **14:58 ET** — about an hour *before* the 16:00 ET close — despite being fetched at ~18:10 ET. It was an unsettled intraday snapshot served from cache, correctly *dated* to the 09-17 session but not settled; **two sources agreeing did not help, because both agreed on the same unsettled snapshot.**
- **What was done about it.** The 09-17 row is **NOT** retroactively corrected — a second row on the same `as_of_date` would make D2a's STEP 1e (`ORDER BY as_of_date DESC LIMIT 1`, no `event_ts` tiebreak) read nondeterministically. The reconciliation lives in **today's** `rationale` instead: the true change into this session is **50.29 → 49.50, −0.79pp**, not the −1.59pp a reader would compute against 51.09. **No router state turned on the error** — 51.09 and 50.29 are both ≥50, so the 09-17 classification was HEALTHY either way. **The defect class is closed forward in the D1 prompt this run** (new pin: the on-page *time* must be at or after 16:00 ET for the session claimed, else re-fetch or carry an explicit `unsettled_at_fetch` token).

---

## PARK ALLOCATION CALL

- **`vehicle`: VOO** — the **majority sleeve** at `target_f_pct = 25` (risk sleeve 75%). `risk_sleeve` VOO, `defensive_sleeve` SGOV.
- **`target_f_pct`: 25 — UNCHANGED. Direction: KEEP. Status: BOUND.**
- **`conviction`: MEDIUM, `conviction_pct` 45.**
- **`rationale`:** **Nothing happened on any axis, and that is the whole case.** **Zero axes ENTERED defensive and zero EXITED.** Hand-scored standing defensive count **3**, unchanged: **breadth**, **rates**, **shock**. `firing_count` **0**, so the **increase gate is SHUT** — raising f requires an axis entering defensive within 2 sessions *and* standing ≥2, and the first limb fails outright. Decreasing f is always allowed, so **f=0 was genuinely available and is declined below**.

  **The mechanical panel and my hand-scoring agree exactly this run**, which is worth saying because last session they did not. `state.park_axis_daily` for 09-18 publishes standing **3** / firing **0** / raw cap **75** / gate shut; my scoring off 09-18 closes gives standing **3** / firing **0**. **No ratchet question arises and no axis verdict is overridden.** The panel does carry all six axes at `measured_on = 2026-09-17` with `axes_measured_today = 0` — structural, since D2a writes `events.signal_marks` at 16:41 MT after this run — but there is nothing to override. One *reading* is superseded without changing a verdict: the panel's breadth leg derives from the 51.09 stored for 09-17 while I wrote **49.50** for 09-18 minutes earlier. Both are DEFENSIVE against the 66 line, so this is recorded in `fields.axis_overrides` as a **reading-level supersession, explicitly not a verdict disagreement**.

  **The three standing axes, and two of them got WORSE rather than merely persisting.** **Breadth** DEFENSIVE at **49.50** vs the 66 line, −0.79pp against a settled 50.29, and the weakest reading of this episode. **Rates** DEFENSIVE and materially worse: 10Y **+7bp to 5.01** (back above 5.00, the whole 09-17 rally given back), 2Y **+9bp to 4.76** (a cycle high), 30Y +5bp to 5.34, curve flattening to +0.25 from +0.27, with the Fed mid-cycle at 3.75–4.00% on 16-of-18 dots for another hike **and the BoJ tightening to a 31-year high on this very session**. **Shock** DEFENSIVE on `shock_overlay='acute'` (as-of 2026-09-01 — a **nineteen-day-old standing state, which is never news**) plus Brent 103.87 > 95 — and this leg is the weakest of the three, because the session's own news pointed the other way: crude fell a third straight session *into* a claimed Hormuz tanker strike.

  **The three non-defensive axes all moved FURTHER away, which is the case for f=0.** **Volatility** now fails **both** limbs of its conjunctive test rather than one: VIX **14.81**, its first sub-15 close of the episode, **−5.9025%** below its 20d SMA of **15.7390** (on 09-17 it was 0.44 *above* 15; now 0.19 below). **Index** holds: SPY **761.69** above its 50dma of **759.7310** (+0.2578%) and far above the 200dma 716.2816 — though the drawdown from the 777.88 trailing high (2026-08-13) **widened** to **−2.0813%** from −1.9643%, which is marginally adverse and is not rounded the flattering way. **Credit** refuses to confirm more firmly than yesterday: HYG/IEF **0.8648678** against a 20-session SMA of **0.8598755** = **+0.5806% ABOVE**, where the test needs 0.50% *below*, and it was +0.3816% above yesterday. HYG fell −0.2414% but IEF fell harder (**−0.4932%**), so the ratio **rose on a down day for credit** — a rates move, not a credit event.

  **The arithmetic, computed before this was written.** Standing 3 → raw cap `LEAST(100, 25×3)` = **75**, matching the panel. Suggested target = nearest step to `0.45 × 75 = 33.75`; |33.75−25| = 8.75 against |33.75−50| = 16.25 → **25**. The ±1-step deviation is available in both directions and declined in both. **The decay-confirmed cap is 100, computed rather than assumed:** the standing series reads 5 (09-15), 5 (09-16), 3 (09-17), 3 (09-18), so the lower count has held on only **one** preceding measured session and the step-down is **not yet due** — `analytics.park_ladder_shadow` for 09-18 independently publishes `confirmed_cap_pct` 100, agreeing. **The step to 75 becomes due next session if standing reads 3 again.** The clamp is non-binding at any f considered, and I size on the **raw** cap precisely because the confirmed cap is a ceiling the one-way ratchet forbids using to license a larger defensive weight than my own hand-scoring supports.

  **The case for f=0, stated in full, because it is the only alternative the gate permitted.** Volatility, index and credit all moved further from defensive; the decline was mechanical and rate-driven; and the standing record is hostile to defensive positioning — **both closed defensive excursions of the AI era LOST** (−2.841pp, −1.019pp; 0-for-2), across 15 historical episodes the defensive signal carried mean forward edge **−0.638pp** and won 4 of 15, and the park's default vehicle is the risk asset so it is the *defensive* weight that needs justifying. **It is declined because two of the three standing axes deteriorated inside themselves this session** — breadth made a new low and crossed below 50, and the 2Y printed a cycle high with the 10Y back through 5% on the day a third major central bank tightened. Going to zero defensive weight on the session breadth broke 50 would be acting on the volatility and credit legs while ignoring the two that actually moved. f=25 is one quarter of NAV in T-bills against three standing defensive axes — a modest posture, not a fearful one.

  **Why VOO 75 / SGOV 25 beats the runner-up.** The runner-up is **f=0** (f=50 is *barred* by the shut gate, not merely declined). f=25 keeps three-quarters in the risk asset history favours while retaining a quarter against the one axis that is deteriorating rather than merely standing. **Crisis override not engaged:** session index move −0.1193% against the −2.5% bar; VIX 14.81 against the 28 bar.

  **No conversion is owed — and `actual_f` confirms it, which also surfaces a reconciliation lag.** The 09-17 graded re-risk (f 50→25) **FILLED AT THE BROKER on 2026-09-18**, measured not assumed: the broker now shows **VOO 16.2040 sh** and **SGOV 37.7181 sh** against 10.9027 / 74.8667 in the 09-17 file, and **74.8667 − 37.1486 = 37.7181 reproduces the staged SGOV sell leg exactly** (the VOO buy filled 5.3013 against 5.3288 staged). Park market value at 09-18 closes is **$15,165.31**, so **`actual_f_pct_before` = 25.0154%** against a target of 25 — inside the no-op band, and D2's conversion step will correctly no-op. **But BigQuery does not know the orders filled:** `events.parking_events` carries no row after 2026-09-15, both `park-convergence` queue rows are still `pending`, and the two `staged_order_awaiting_confirm` warnings of 09-18 (`536cff2f`, `c379a987`) therefore now assert "awaiting confirm" about orders that are **filled**. **This is the ordinary Fri→Sun cadence gap, not an outage** — D2a owns park-fill reconciliation at STEP 0, its cadence is Sun–Thu, and it runs tonight at 16:41 MT, which should drain both rows and resolve both warnings. **No alert is raised for a by-design lag that self-clears within the hour**; it is recorded here so that if tonight's D2a does *not* clear it, the next session has the measurement in hand.

  `fields.park_watch` is **false** — the watch flag marks the exactly-one-axis-firing case, and zero fired. The DE-RISK EVIDENCE CARDINALITY floor never came into play, since it governs increases.

- **`invalidation` (symmetric standard, both limbs disjunctive and at the same height):** **Would RAISE f** — any one of: VIX closing back above its 20d SMA; SPY losing its 50dma on a close; credit finally confirming (HYG/IEF crossing more than 0.50% *below* its 20d SMA); or breadth breaking down through ~45. **Would LOWER f to 0** — any one of: breadth recovering above ~60; the shock overlay de-escalating at the next M1a scoring; **or a second consecutive session with VIX below 15.** The lower limb is carried forward **unchanged** from the 09-17 call rather than re-tightened, and **one of its disjuncts is now half-satisfied**: VIX printed its first sub-15 close at 14.81, so a second consecutive sub-15 close completes it. Adding a conjunctive rates condition to that disjunct — which I considered, since the 10Y went back above 5% — **would be exactly the asymmetry the 2026-08-18 SYMMETRIC EVIDENTIARY STANDARD forbids, so it was not added.** Each raise-limb disjunct is itself an entering event, so the increase gate would open with any of them. No later session is bound by any of this.
- **`theater_check`:** The conclusion **is** the default here, so the theater risk runs the opposite way to a conversion day — the danger is dressing a foregone KEEP as deliberation. Stated plainly instead: **an increase was MECHANICALLY UNAVAILABLE** (gate shut, `firing_count` 0), so no judgment of mine could have raised f whatever I believed. The only live choice was KEEP-25 versus DECREASE-to-0, and the ladder at unchanged conviction returns 25; the arithmetic was computed before the rationale was written. The one genuinely judgmental call is that conviction is **unchanged at 45 rather than lower**, and it is falsifiable: at ≤16.67% the ladder returns 0. I do not believe it should be there, because breadth made a new low below the vocabulary's HEALTHY line and the 2Y printed a cycle high — two of the three standing axes got worse, not merely persisted.

Heartbeat written: `ops.heartbeat` `('loop:park_allocator', 'VOO call, status=BOUND')`.

---

## CORRECTIONS LANDED THIS RUN

Three append-only corrections, all verified by reading the written row back. **No `UPDATE`, `DELETE` or `MERGE` touched `events.decision_log`,** and every superseded row keeps its own `superseded_by` NULL forever.

1. **The 2026-09-14 single-name screen's ORCL item — a W2 finding, and D1's to fix.** `46d69e8d` → **`4264b87f`**. ORCL was recorded at **−13.7912%**, which is the **open-to-open** move where §19 PRICE BASIS requires the **close**; the true close-to-close is **−3.6532%** (150.28 → 144.79). Independently re-measured here on IBKR contract 272800 in a **solo** pull, and the root cause reproduced exactly: open-to-open 164.38 → 141.71 = −13.7912% to four decimals. **Consequence:** the error promoted a **sub-floor** move to the session's top-ranked, highest-conviction (75) item, described as "the headline" — and because W2's Strategy-B intake reads this record exclusively, on an ACTIVATE cycle that would have put a name failing criterion 1 at the head of the thesis queue. B was `DO-NOT-ACTIVATE` on 09-14 so **no capital was ever at risk**. ORCL now carries conviction 30, `below_spec_floor` true, `legacy_rule_pass` false; agreement counts recomputed (both 9→8, ai_only 5→6, rule_only 9→**10**, the last being a *separate* arithmetic defect stated independently so a reader can reject it — INTC was a Layer-2 rejection wrongly omitted, while BZ is excluded because its own reason places its rejection at **Layer 1**). Built by a `JSON_SET` transform of the stored row, so the other 24 items are byte-identical rather than retyped. `ops.alerts` `f6347d9a`.
2. **This run's own sector screen — a prose/`fields` membership drift, caught by reading the row back.** `5bc3bb3c` → **`4f06d0b0`**. `fields.passed` carried XLRE but **omitted XLK**, while the body named XLP and XLK as the sub-rail surfacings. The counts were internally consistent (`surfaced_count` 5 = array length 5), **so no arithmetic check would have caught it** — the defect was in *which* sectors the row says it surfaced, the exact field `state.research_screen_calls` and W5's scorecard read. XLK added; `surfaced_count` 5→6, `ai_only` 5→6; all three sub-rail items now both in the array and named in prose, which is exactly §19's limit of three.
3. **This run's own park call — a prose-only number, and it was also slightly wrong.** `4718a9de` → **`ffe94150`**. The credit paragraph asserted IEF at **−0.4955%**; the correct figure is **−0.4932%** (91.25 → 90.80), and `ief_move_pct` **did not appear in `fields.readings` at all** — precisely the failure class the 2026-09-04 READINGS PROVENANCE rule was added for, failing a third time, in my own row, thirty minutes after I cited the rule. **The substantive claim is unaffected** (IEF still fell harder than HYG, by 0.2518pp) and **no axis verdict, cap, ladder step or conviction moved** — the ratio and its SMA were computed from the close series directly, never from these percentages. Five readings keys added, including the pre-fill park share counts that the fill arithmetic depends on.

**Plan edits landed this run** (`Claude_Task_Plan.md`, slices regenerated in the same commit): the breadth step now requires the source's on-page **time** to be at or after 16:00 ET for the session claimed; the park call is pinned as **not** a `d1_actions` entry and not a `RECOMMENDED ACTIONS` bullet (closing D2's `453c18f9`); the FDA limb must resolve sponsor and status against the FDA's own approvals/CRL page (closing W1's `031108b9`); and `fields.selection_rule` is now written on every screen (adopting W2's `08582955` proposal).

**Recorded and NOT fixed here, with owners named:** the IBKR parallel cross-contamination defect (`7cc25b71`, owner OPS1 / `ops/connector_tools.yaml`) — contained in this run by sequential pulls, not repaired; the sector-ETF contract-id registry gap (`716d9ab3`, owner W5); W2's `08582955` coverage measurement, whose *additive* half is adopted above while **widening D1's rail is deliberately not proposed** — that is a metered-cost decision on a daily routine and it is D1/W5's surface, not something to take unilaterally inside a run.

---

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

One HF `hf_fs` paper search, the Sunday rotation slot (**long-context**), query `"long context LLM lost in the middle"` from `HF_Resource_Catalog.md` §6.1. Five results returned; **none published on or after 2026-09-17**, the scan-window lower bound — the most recent (STAIR, 2609.03874) dates to 2026-09-03, seventeen days before the window opens, and two of the five are already cited in §1.5. **No capture owed, no `[HF Frontier-LLM Capture]` entry written, no `state.strategy_candidates` row.** Out-of-window results are reported as out-of-scope rather than as new findings.

---

## RECOMMENDED ACTIONS

- **Watchlist add — XENE** to the Strategy B new-entry candidates state index (index-only; **no** thesis construction routed, B router `DO-NOT-ACTIVATE` and capital-disabled), qualifying event date **2026-09-18**, ten-trading-day window to ~2026-10-02 anchored on the event date.
- **Watchlist add — NUE**, same treatment and window.
- **Watchlist add — BE**, same treatment and window.
- **Watchlist add — MSTR**, same treatment and window.
- **Watchlist add — COIN**, same treatment and window.

**No exits triggered. No add candidates flagged. No router review recommended.**

*NOTE, deliberately not a bullet and deliberately absent from the block below: the* `## PARK ALLOCATION CALL` *above is a BOUND **KEEP** at* `target_f_pct` *25, so no conversion is owed. D2 reaches the park call through* `state.park_allocation_latest`*, never through* `d1_actions` *— pinned in the D1 prompt this run after D2's* `453c18f9` *showed that encoding it as a* `router_review` *entry reads as 0 prose against 1 block entry and would halt D2 on a sound file.*

```yaml d1_actions
- action: watchlist
  ticker: XENE
  strategy: B
  qualifying_event_date: 2026-09-18
  source_research_screen_id: ce24e9cb-603d-4c8e-81fa-1a7a9fad0ff6
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, no thesis construction
    routed, B router DO-NOT-ACTIVATE and capital-disabled). -30.6888% close-to-close 57.35 -> 39.75,
    IBKR RTH daily bars contract 170553308, on a temporary pause of enrollment in trials of its
    experimental depression/bipolar candidate after reported side effects. Largest move on the board
    and the cleanest company-specific catalyst of the session; clears B Entry criterion 1's frozen
    >=5% floor by 6.1x. Cap $3.84B (FMP profile-symbol). CAVEAT for the thesis session: attribution
    is Reuters reporting the company's own action, not a release read directly. Window ~2026-10-02
    anchored on the qualifying event date 2026-09-18. No prior XENE queue row of any status exists.
- action: watchlist
  ticker: NUE
  strategy: B
  qualifying_event_date: 2026-09-18
  source_research_screen_id: ce24e9cb-603d-4c8e-81fa-1a7a9fad0ff6
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE).
    -6.3211% close-to-close 265.14 -> 248.38, IBKR RTH daily bars contract 10557, on company-ISSUED
    Q3 EPS guidance below consensus. With STLD (-4.1125%, below the floor) this is the session's only
    company-guided non-thematic signal and it explains materials being the worst GICS sector at
    -1.4198%. Strongest event class in this cohort - issuer-originated. Cap ~$55.9B, an estimate from
    the confirmed close, well above the rail. Window ~2026-10-02 anchored on 2026-09-18. No prior NUE
    queue row of any status exists.
- action: watchlist
  ticker: BE
  strategy: B
  qualifying_event_date: 2026-09-18
  source_research_screen_id: ce24e9cb-603d-4c8e-81fa-1a7a9fad0ff6
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE).
    -5.3890% close-to-close 280.76 -> 265.63, IBKR RTH daily bars contract 326398514. Qualifying
    event is ADDITION TO THE S&P 500 effective with this session's close - and the name FELL on it,
    the textbook inclusion bid never appearing; one of two of the three new members to fall (ILMN
    -2.2677% is the other). NOTE FOR THE THESIS SESSION, an inversion worth reading twice: B's
    criterion 3 lists index inclusion as a valid CONVERGENCE TARGET, but here inclusion is the
    already-consumed QUALIFYING EVENT, so a thesis would need a different convergence target. Also
    confounded - the AI-power complex BE belongs to was being sold independently the same session.
    Cap $78.2B (FMP profile-symbol). Window ~2026-10-02 anchored on 2026-09-18.
- action: watchlist
  ticker: MSTR
  strategy: B
  qualifying_event_date: 2026-09-18
  source_research_screen_id: ce24e9cb-603d-4c8e-81fa-1a7a9fad0ff6
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE).
    +16.3856% close-to-close 132.25 -> 153.92, IBKR RTH daily bars contract 272110, on bitcoin above
    $80,000 after the SEC cleared a regulatory path for tokenized stocks. Surfaced as the
    balance-sheet-channel representative of a six-name complex (MARA and BMNR rejected as
    duplication). CAVEAT CARRIED TO THE THESIS SESSION: the event is SECTOR/REGULATORY, not
    issuer-specific, and criterion 1 wants a public event producing the reaction - weigh that before
    treating it as one, exactly as the 2026-09-17 run flagged for INTC. Cap $50.9B (FMP
    profile-symbol). Window ~2026-10-02 anchored on 2026-09-18.
- action: watchlist
  ticker: COIN
  strategy: B
  qualifying_event_date: 2026-09-18
  source_research_screen_id: ce24e9cb-603d-4c8e-81fa-1a7a9fad0ff6
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE).
    +11.6571% close-to-close 173.97 -> 194.25, IBKR RTH daily bars contract 481691285, on the same
    SEC tokenized-stocks development. Surfaced as the business-model-channel representative and the
    stronger of the two crypto names on event-relevance grounds: tokenized-stock rulemaking bears on
    what a regulated exchange is permitted to list and trade, not merely on a holdings mark. Cap
    ~$49.5B, an estimate from the confirmed close, an order of magnitude above the rail. Window
    ~2026-10-02 anchored on 2026-09-18.
```

---

*Metered spend this run: **50** logged `ops.web_calls` rows — 24 Tavily (21 `search` + 3 `extract`, ~32 credits, a rate-card ESTIMATE not provider-reported), 22 FMP, 3 Anthropic `web_fetch` (free), 1 HF. `call_ts` values are accurate to the minute-level sub-agent window rather than to the individual call, and are deliberately staggered rather than collapsed to the batch write time. IBKR and BigQuery calls are free and are not billed telemetry.*
