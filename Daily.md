2026-09-21
<!-- d1_scan_through_utc: 2026-09-21T22:10:30Z -->

# Daily Market Development Scan — 2026-09-21 (Mon, MT)

**Scan window: 2026-09-20 16:09 MT → 2026-09-21 16:10 MT** (**24.0h — the normal daily cadence, no gap**). Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-20T22:09:44Z -->` marker, cross-checked against that file's own commit at `2026-09-20T22:54:38Z`; the two differ by 45 minutes, which is that run's own write-to-commit interval and not a coverage gap. **ONE completed US trading session inside this window: Monday 2026-09-21.** **Every close-to-close figure in this file is measured 2026-09-18 → 2026-09-21.**

> **⚠️ DEGRADED MODE — the BigQuery connector was unreachable for this entire run (token expired / re-authorization required).** Diagnosed by probe, once, per the TRANSIENT-FAILURE ladder: a bare `SELECT 1` **with no table reference also failed with the same auth wording**, which is the ladder's *connector down, auth wording → RE-AUTH branch* classification and is explicitly **NON-WAITABLE**, so no session time was spent retrying. Every `state.*` / `perf.*` / `events.*` / `ops.*` read and write was unavailable. A **`[Claude] ATTENTION — RE-AUTH BigQuery connector`** calendar event was created immediately as the only surviving channel — `ops.alerts` lives in BigQuery, so `sp_raise_alert` cannot run and `alert_emailer.gs` has nothing to poll.
>
> **This is NOT the platform `403 authentication_failed` signature recorded in RUNBOOK §54 this morning.** That one kills the session mid-run and leaves an orphaned `started` row. This session ran to completion and **every other connector worked**: IBKR served 94 calls including 52 clean price-history pulls, Calendar accepted a write, Tavily / FMP / Hugging Face all answered. The failure is scoped to the BigQuery MCP server's own OAuth grant. The discriminator is exactly that: a platform 403 kills everything, an OAuth expiry kills one connector.
>
> **Substitutions used, each labelled where it appears:** open book from the IBKR connector (`get_account_positions`, authoritative for holdings); per-strategy kill/drawdown state and the regime carried forward from the prior `Daily.md`; per-tranche cost basis **reconstructed arithmetically** from the prior run's published `mark_vs_cost_pct` figures and **labelled as a reconstruction, never as a `state.current_positions` read**; "today" from the system clock rather than `state.trading_day_today`.
>
> **D1 is research-only and stages no orders, so the scan below is complete and faithful — only the BigQuery side-writes are deferred.** Every one of them is enumerated with paste-ready SQL in **`ops/spikes/bigquery-deauth-2026-09-21-d1-deferred-writes.md`**, which exists because `Daily.md` is wholesale-overwritten by the next D1 run and a deferral recorded only here would delete itself. **D2 / D2a / D3 require canonical state and will halt cleanly** until the connector is re-authed; expect a cadence + freshness double-critical, which per RUNBOOK §26 is the expected signature of a connector outage and a TRUE positive, not two new bugs.

**Tape — a broad risk-on reversal led by AI semis and communication services, on falling oil and a 10Y back below 5%. The defensives fell on an up day, which is the tell that separates this session from the last one.** SPY 761.69 → **773.50** (**+1.5505%**) on 5,201,404 shares. VOO 701.78 → **712.78** (+1.5674%). **QQQ +2.7750%** (721.45 → 741.47) led, DIA +0.7560% and IWM +0.5209% lagged — the same large-cap-growth-over-everything split as the prior two sessions, but this time with the index actually rising. AP has the S&P 500 +1.5% to 7,764.70 and the **Nasdaq Composite +2.3% to 27,122.09, a first record close since June**; WSJ corroborates. **Yields gave back part of Friday's move: 10Y 5.01 → 4.96 (−5bp, back below 5.00), 30Y 5.34 → 5.29 (−5bp), 2Y 4.76 unchanged at its cycle high** — so the curve **flattened again, to +0.20 from +0.25, the flattest of this series**. TLT **+0.6769%**, IEF +0.3855%, LQD +0.3725%, HYG +0.1910%, SGOV +0.0099%. **Brent (BZX6) 103.87 → 100.34 (−3.3985%, a fourth consecutive decline)** and USO −3.6796%. GLD **−0.6955%** (Reuters attributes it to hike odds and a firmer dollar; aggregator claims that gold "hit new records" the same day are stale and are rejected). UUP +0.3170%. **BITO +6.4103%**. VIX 14.81 → **14.87 (+0.4051%) — its second consecutive sub-15 close, and −5.4432% below its 20d SMA of 15.7260.** Equity breadth ($S5TH) **49.50 → 50.49, +0.99pp**, back above the shared vocabulary's 50 HEALTHY line after one session beneath it. **Seven of eleven GICS sectors higher, four lower**, cross-sector spread **6.4323pp** (XLC +3.5556% to XLE −2.8767%) against 2.2387pp on 09-18 — **nearly three times Friday's dispersion**, reversing two consecutive sessions of narrowing.

**THE SESSION HAD NO SCHEDULED CATALYST AT ALL, AND THAT DISCOUNTS THINGS IN BOTH DIRECTIONS.** MarketWatch's US economic calendar lists *"Monday, Sep. 21 — No events scheduled"*; the FOMC decision was five days prior, the next real macro print (S&P Global flash PMIs) is 2026-09-23, and exactly one US-listed company at or above $2B reported. A +1.55% index day built on flow, positioning and two sell-side/product datapoints carries less information than its magnitude suggests — **but it is also not the mechanical artifact the 09-18 triple-witching session was**, and nothing here is discounted for expiry mechanics.

All equity/ETF figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), every bar verified carrying a 2026-09-21 stamp of `13:30:00Z`. Two documented exceptions, stated rather than hidden: the ^VIX bar (contract 13455763, `IND`/CBOE) stamps `07:15:00Z` and carries `delayed:900`, an index-feed property rather than an equity RTH bar; and Brent is a NYMEX future (BZX6, contract 339981284, last trading date 2026-09-30 — verified still front-month this run, not rolled). Treasury yields are the Treasury par curve via FMP `economics/treasury-rates`, date-pinned, with FMP confirmed to have published a genuine 2026-09-21 row rather than the 09-18 row carried forward.

**THE SCAN ITSELF IS NOT DEGRADED, AND THAT IS MEASURED SEPARATELY FROM THE BIGQUERY OUTAGE.** 25 distinct single names and 19 index/ETF/future instruments were put to IBKR for confirmation across two passes; **every one returned a genuine 2026-09-21 regular-session bar. Zero symbol-level denials. Zero measurement failures. Zero discovered-but-unconfirmable names.** Every `surfaced_count` below is affirmatively established. **The IBKR parallel cross-contamination defect (`ops.alerts` `7cc25b71`) was contained the same way as the prior run**: all 52 `get_price_history` calls were issued **strictly one per message at concurrency 1**, and the self-check was applied to both passes — no two distinct instruments share an identical close or an identical volume to full precision. The defect is OPS1's and is **not** fixed here.

---

## TL;DR

- **Exits triggered: none.** The open book is 12 tranches across 8 names, all Strategy D; not one carries a `convergence_target` or a `time_exit_date` (both are B/E fields, and B and E hold nothing), so zero mechanical triggers could fire. **Every open position ROSE**, and no thesis-invalidation criterion is met on any of the 12.
- **New entry candidates: 3 (GRAL, WBD, NVO)** — all Strategy B, all **state-index only**; B is `DO-NOT-ACTIVATE` and capital-disabled, so no thesis construction is routed. Four further names cleared the 5% bar and are **deliberately not routed** (ARM, META, AMD, INTC). **The anchor convention landed in D1's own prompt this run caught two of those four within hours of being written**: ARM's governing event is dated 2026-09-16 after the close, and META's is 2026-09-18 — anchoring either to today would have been the exact MSTR-class error the rule exists to prevent.
- **Add candidates: none.** 12 tranches evaluated, 0 flagged. **All 12 recorded `declined_hard_gate` this run** — not on their merits but because `invalidation_status` is a BigQuery field and the gate cannot affirmatively confirm "unbreached" from an unreadable mirror. Costless: every position rose, so no dip trigger existed to decline.
- **Watchlist changes: 3 adds** to the Strategy B new-entry candidates state index. **These cannot be converted tonight** — D2 halts on the same outage — and will be picked up by its catch-up window.
- **Regime review: no review.** Breadth crossed back above 50 (HEALTHY) after one session below; recorded as an observation, since the threshold is D2a's to apply.
- **Park: RE-RISK, `target_f_pct` 25 → 0, LOW 15, BOUND in form.** The prior session's own named re-risk bar — a second consecutive sub-15 VIX close — was met, and both reasons it gave for declining f=0 were removed today. **The write is deferred, so no conversion reaches D2.**

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **A tanker was struck in the Strait of Hormuz — and crude fell 3.4% anyway. That combination is the development, not the strike.** UKMTO (the primary maritime-security authority) reported a tanker on inbound transit struck by an "unknown projectile" on 2026-09-21, two crew with minor injuries, vessel proceeding under its own power; the Saudi Press Agency separately reported an LPG tanker hit by shrapnel the same day. **Brent nonetheless closed −3.3985% at 100.34, a fourth consecutive decline**, on UN General Assembly diplomacy hopes, resilient Saudi export flows and reported higher Hormuz vessel throughput. **The market priced de-escalation straight through a kinetic event.** This is the second consecutive session in which the oil tape has contradicted the geopolitical headline, and it is the single most load-bearing observation in this file for the park's shock axis. Sources: UKMTO via MarineLink; SPA; AP wire.
- **Iran–US threat exchange escalated in-window.** Trump warned Iran would "fail economically" or its leadership be "wiped out" absent a deal; the Revolutionary Guard said it would "change the geography of the war" on further escalation. A fresh US travel/security alert cited possible airspace closures. Treasury Secretary Bessent said China is "very engaged" on Iran sanctions and that all Iranian airlines face shutdown by secondary-sanctions pressure from 2026-09-23. (Reuters; CBS live updates; CNBC transcript.) **Note the tension with the item above** — rhetoric escalated while the priced risk premium fell.
- **Google fined €403m (~$463m) by Ireland's Data Protection Commission** for unlawful location-data processing 2018–2020 across "Web & App Activity", "Location History" and "Location Accuracy"; the DPC said three further statutory inquiries into Google are at an advanced stage. **No GOOGL-specific price reaction attributable to the fine was located** — GOOGL rose +1.5535%, less than XLC's +3.5556%, so if anything it lagged its own sector. Recorded as an unscheduled enforcement action **without** a confirmed market reaction rather than asserting one. (AP wire via US News / ABC News.)
- **The Fed and Bank of England stepped up scrutiny of bank exposure to large trading firms** following Jane Street's reported ~$15bn July loss tied to the near-collapse of AI-focused hedge fund Situational Awareness. Citigroup, JPMorgan, Goldman Sachs and Bank of America were asked for detail on intraday counterparty exposure; the SEC separately subpoenaed several of the same banks last month. **A financial-stability development, not a single-day price event** — XLF was the fourth-smallest mover on the board at +0.0716%, and no discrete reaction is claimed. (Reuters; FT original, paywalled.)

### 2. Scheduled events that resolved in the window

**This category is close to genuinely empty, and that is a measured finding rather than a thin search.** MarketWatch's US economic calendar carries *"Monday, Sep. 21 — No events scheduled."*

- **Earnings — exactly ONE US-listed name at or above $2B reported. Abivax SA (ABVX)**, ~$9.2B, **H1 2026 results (six months ended 2026-06-30)**, released via GlobeNewswire **2026-09-21 22:05 CEST = 16:05 ET**, i.e. **five minutes AFTER the close**. Net loss €165.9M vs €100.8M in H1 2025; operating loss €140.3M vs €93.7M; cash + short-term investments €402.4M at 30 June plus €767.1M raised in a July offering; runway into Q4 2029. **EVENT-IDENTITY GATE applied:** release date/time and fiscal period are read off the issuer's own release, not a calendar. **No outcome-versus-consensus figure is stated** — the available per-share consensus (Benzinga Pro, a loss of $1.08/share) has an undisclosed ADS-count and FX basis and cannot be honestly reconciled against a GAAP euro net-loss figure, so the beat/miss is recorded as **not computed** rather than estimated. **Its reaction session is 2026-09-22, not today**, so it is not a candidate in this run's screen.
- **VinFast (VFS) explicitly checked and EXCLUDED** — its Q2 2026 results were released Friday 2026-09-18, before this window, and its call is 2026-09-24. One aggregator listing it as "reporting today" was uncorroborated by any primary source and is disregarded as stale.
- **FDA: genuinely empty for this window.** No PDUFA target action date falls on 2026-09-20 or 09-21. The nearest are 2026-09-19 (Ultragenyx UX111, IntraBio Aqneursa — both before the window) and 2026-09-22 onward. **FDA LIMB applied:** the two rows that have now misfired twice were checked and **neither was re-imported** — Jideytro/zidesamtinib was approved 2026-07-22 to **NUVALENT (NUVL), not GSK**, and IONS' zilganersen was approved **2026-09-03**, not pending 09-22. A direct FDA.gov check for approvals dated 09-19 to 09-21 surfaced nothing beyond UX111 (approved 09-17, outside the window).
- **No FOMC action** — the decision and the Warsh press conference were 2026-09-16. In-window Fed-speak is recorded under item 5. The only other calendar items were a Chicago Fed National Activity Index print (August, ≈ −0.08) and a 3-month bill auction, neither market-moving and neither with a reaction attributed to it in any source.
- **PENDING, not resolved:** S&P Global flash September PMIs (2026-09-23); AutoZone, MillerKnoll, Thor (2026-09-22 BMO); Cintas, General Mills, Paychex (2026-09-23).

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

**Layer-1 population rail** (mechanical, a cost bound — never a significance claim): US-listed, market cap ≥ $2B, ≥2% close-to-close, attributable to an identifiable public event. **`universe_measured` = 25** distinct single names put to IBKR and confirmed (17 screen candidates + the 8 open-position names). **`rail_tally` = 11** of the 17 screen candidates cleared all three limbs; **6 of 17 moved ≥2% with NO identifiable public event after checking** and fail the rail's third limb — recorded below rather than dropped.

**`selection_rule` — stated because `universe_measured` is a numerator with no denominator without it, and because this scan IS the definition of the Strategy-B candidate population.** The discovery leg was a **news-surfaced sample, not a systematic scan of the ≥$2B universe**. It began from three FMP structured screeners — `most-active` (~50 rows, volume-ranked, which is what surfaces ordinary large-cap moves that the percent-ranked lists miss), `biggest-gainers` and `biggest-losers` (~50 rows each, percent-ranked and dominated by micro-caps and leveraged ETFs) — plus three broad "biggest movers September 21 2026" searches at high `max_results`. From ~120–150 heavily-overlapping row-slots, **~28 distinct large-cap tickers** were taken for follow-up and **17 were put to IBKR for confirmation**. **A genuine qualifying mover with thin news coverage would not have been caught by this method**, and no coverage ratio computed off this row should be read as one.

**A DISCOVERY-SIDE CONTAMINATION WAS CAUGHT AND SETTLED BY MEASUREMENT.** One aggregator's "movers" snapshot served **Thursday/Friday (09-17/09-18) figures labelled as Monday's** for six tickers (XENE, BTU, GENI, NBTX, ALKS, MIRM). The sharpest instance: **SMR was shown at −8.5%**, which is its real 09-18 move, against **+6.4%** from a live post-close pull. **IBKR settled it at 8.27 → 8.79, +6.2878%** — the stale figure was not merely imprecise, it had the wrong sign. The five tickers that could not be confirmed against a Monday-dated source were **excluded entirely** rather than carried at a suspect number; XENE in particular is already a live 09-20 cohort row and re-importing a stale −30.7% for it would have corrupted that record.

**Layer-2 — the decider. Written up (`passed`, `surfaced_count` = 8):**

| Ticker | Move | prior_close → event_close | Cap | Event | Conviction | Reason |
|---|---|---|---|---|---|---|
| **GRAL** | **+33.6759%** | 80.77 → 107.97 | $4.63B | FDA staff briefing document for the Galleri multi-cancer test posted with no major concerns, ahead of the 2026-09-23 advisory-committee vote | **75** | Largest move on the board by 16pp and the cleanest event shape of the session: a binary regulatory readout partially de-risked two days ahead of the vote, by the regulator's own document. |
| **ARM** | **+17.1583%** | 275.61 → 322.90 | $344.9B | CEO Rene Haas's bullish AI-demand comments — **dated 2026-09-16, after the close** (CNBC, not 09-21) | **45** | Magnitude is extraordinary for a $345B name, but **the attribution collapses on dating**: the governing comments aired five sessions earlier and **no new Haas remarks on 2026-09-21 exist**. A 17% move five sessions after a TV interview, on the same day AMD and INTC surged, is far more plausibly the sector repricing than the interview. Conviction cut from 60 to 45 on that finding. |
| **INTC** | **+12.1363%** | 108.60 → 121.78 | $614.3B | Server-CPU-supplier rally on Meta's Muse launch; SK Hynix deal **speculation** | **60** | A 12% day in a $614B name is significant on magnitude alone. The SK Hynix leg is explicitly speculation and is **not** treated as an event. |
| **META** | **+11.3406%** | 665.75 → 741.25 | $1.89T | Two legs, **both mis-dateable**: Muse topped the US App Store — first claimed **2026-09-18**, not today — and a Wells Fargo PT raise to $796 from $640, pre-open 09-21 | **60** | The single name that drove XLC's +3.56%, so the sector print overstates sector-wide strength. Significant on that ground alone. But **neither leg is a dateable issuer disclosure on 09-21** — see the OPPORTUNITY CHECK. |
| **WBD** | **+10.7914%** | 27.80 → 30.80 | $77.2B | State attorneys general settled their suit blocking the ~$110B Paramount Skydance merger | **75** | The cleanest **dateable third-party** event of the session — a legal settlement removing a named, quantified obstacle. |
| **AMD** | **+9.9496%** | 559.82 → 615.52 | $1.00T | Same Muse-sparked AI-infrastructure rally; crossed a $1T valuation intraday at a record high | **60** | With INTC and ARM this is one repricing, not three. Bears directly on D:TSM's criterion 3 — and points the **opposite** way to it. |
| **NVO** | **−7.9556%** | 43.24 → 39.80 | $176.8B | Announced 2030 growth ambitions; fell on US semaglutide exclusivity loss and obesity-drug competition | **75** | **Issuer-originated and it fell on its own good news** — an information-versus-reaction divergence, which is the exact shape Strategy B exists to trade. |
| **PSKY** | **−2.9383%** | 10.21 → 9.91 | $10.8B | The same AG settlement as WBD, from the other side | **45** | `below_spec_floor`. Surfaced only because it is the **counterparty leg of a single event** — the two names moving opposite ways on one settlement is more informative than either print alone. Context only, never routed as a B candidate. |

**`rejected_notable` (9) — measured, confirmed, and deliberately not surfaced:**

- **RSI −7.4249%** (23.30 → 21.57, $5.34B) and **SMR +6.2878%** (8.27 → 8.79, $2.62B) both clear the 5% bar with **no company-specific event found after checking**. They fail the rail's third limb, exactly as SMR and GM were declined on 09-20. Recording *why* matters more than the magnitude.
- **USAR +9.1737%** (15.37 → 16.78) — its partnership release is dated **2026-09-17**, so under the anchor convention its event session is not today; and its $2.23B FMP cap sits **within ~30% of the $2B rail**, inside the band where the documented implied-share-count lag means the figure must be second-sourced. Two independent reasons to hold it out.
- **SMCI +5.3978%**, **AAL +4.7068%** (oil-driven, macro not company), **GRAB +4.3011%**, **NU +3.0037%**, **TNGX +2.6667%**, **NOK +2.4345%** — all confirmed, none with an identifiable issuer event.

**`agreement` = `{both: 7, ai_only: 1, rule_only: 4}`.** Seven surfaced names also clear the legacy ≥5% bar; PSKY is AI-significant but sub-floor; and **four names clear ≥5% without being surfaced** (SMR, RSI, USAR, SMCI) — the largest `rule_only` count in recent runs, and it is entirely the event-attribution limb doing the work rather than a judgment of magnitude.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

**Layer-1 rail:** any GICS sector ≥1% at sector-ETF level, or notable dispersion. **`rail_tally` = 6** of **`universe_measured` = 11** clear ≥1%; **three clear the legacy ≥2% bar**. Cross-sector spread **6.4323pp** against 2.2387pp on 09-18 — **dispersion nearly tripled**, itself a rail surfacing.

**Written up (`passed`, `surfaced_count` = 5):**

| Sector | Move | prior_close → event_close | legacy ≥2% | Conviction | Driver and judgment |
|---|---|---|---|---|---|
| **XLC** | **+3.5556%** | 110.81 → 114.75 | **true** | **75** | Largest sector move — but **META alone (+11.34%, $1.89T) accounts for the bulk of it**. A sector print driven by one constituent is not sector-wide strength, and reading it as such is the error this row exists to prevent. |
| **XLK** | **+2.7690%** | 189.60 → 194.85 | **true** | **75** | The session's structural story: AMD to a $1T valuation, INTC +12.1%, ARM +17.2%, on AI-infrastructure demand confidence plus a softer US-China tone ahead of the 09-23 Xi visit. Unlike XLC this is **broad within its sector**. |
| **XLE** | **−2.8767%** | 64.31 → 62.46 | **true** | **60** | The only sector with a fully-corroborated causal chain to a measurable input: Brent −3.3985%, a fourth straight decline. Refiners fell hardest (VLO −3.7% to −4.8%, MPC −5.3%) on **feared** margin compression from the speed of the crude repricing — reported explicitly as a fear, not a realized event. |
| **XLU** | **−1.0706%** | 41.10 → 40.66 | false | **60** | **Utilities fell on a day the 10Y dropped 5bp.** A bond proxy that declines as its discount rate falls is not being priced off rates — it is being sold. `legacy_rule_pass=false` by convention on a sub-2% surfacing. |
| **XLP** | **−1.0628%** | 82.80 → 81.92 | false | **60** | Same signature as XLU. **This is the session's cleanest regime tell and the sharpest contrast with 09-18**: on Friday the defensives fell *with* the cyclicals, which read as a rates repricing; today they fell *while* the cyclicals rose, which is rotation out of defence. Different mechanism, opposite meaning, and only visible because both sessions were measured the same way. |

**`rejected_notable`: XLY +1.0808%** — clears the ≥1% rail but no sector-wide driver was identified (TSLA +3.0%, AMZN +1.9%, and a minor Amazon/Meta-agent friction story that is not a sector driver). Judged beta, conviction 30.

**Honest gaps, recorded rather than papered over.** No identifiable driver was found for **XLV (+0.3682%)**, **XLI (+0.1355%)**, **XLRE (+0.1411%)**, **XLF (+0.0716%)** or **XLB (−0.5601%)**. For XLB one data snapshot showed Mohawk (MHK) at −7% for the session, but **every explanatory article located for MHK was dated to a different quarter's earnings reaction (May 2026)** — so that move is recorded as **without a confirmed catalyst** rather than attributed to a stale one. The lower-10Y tailwind for XLRE is an inference and is labelled as such, not sourced.

**`agreement` = `{both: 3, ai_only: 2, rule_only: 0}`.** XLC/XLK/XLE clear both bars; XLU/XLP are AI-significant sub-rail surfacings; no sector clears ≥2% without being surfaced.

### 5. Notable commentary

- **Chicago Fed President Austan Goolsbee (Monday)** warned the AI investment boom may be adding a **second, demand-side inflation driver** on top of the existing energy and tariff supply shocks, with October hike odds staying above 50%. **This is the most consequential commentary of the session for this book** — it is an argument that the very capex cycle driving XLK's +2.77% is itself inflationary, which ties the equity rally and the rate path together in a way that cuts against both. Sourced to secondary wires (Newsquawk, Benzinga) summarising the remarks rather than a Fed transcript retrieved directly; flagged as such.
- **Treasury Secretary Scott Bessent (CNBC "Squawk Box", primary transcript).** Called Sunday's talks with China's Vice Premier He Lifeng "successful", covering AI and trade including a proposed bilateral notification mechanism for AI incidents — widely credited, alongside falling oil and yields, for the session's tone ahead of Xi's 09-23–25 Washington visit. Separately **rejected an AI-industry ask for a federal liability shield** ("It is humans who are responsible, not the AI"), and said Treasury remains "confident" in Fed Chair Warsh.
- **Wells Fargo (Ken Gawrelski)** raised Meta's PT to $796 from $640, Overweight — the proximate cause of the largest single-name contribution to the day's largest sector move. **Citi** separately placed Meta on a 90-day upside catalyst watch at $800 ahead of Meta Connect (reported via TipRanks/GuruFocus, not verified against a Citi primary document).
- **Oppenheimer (John Stoltzfus), dated 2026-09-21 weekly note:** maintained an 8,100 S&P 500 year-end target while explicitly cautioning that "the number and magnitude of future Fed hikes matter much more than this first increase."

---

## ANALYSIS — RISK TO EXISTING POSITIONS

**MECHANICAL EXIT-TRIGGER SWEEP — run for every open position, and empty for the same structural reason as the prior run.** The open book is **12 tranches across 8 names, every one Strategy D**. **Not one carries a `convergence_target` or a `time_exit_date`** — those are Strategy B / E fields and B and E hold nothing — so **zero mechanical triggers could fire and zero did.** A genuine absence, not an unchecked one.

**The UNION sweep, and what degraded mode does to it.** `state.current_positions` was unreadable, so the union could not be formed as a comparison. The broker shows exactly **AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER** plus the VOO/SGOV park sleeve and **nothing else** — the identical name set the prior run reconciled. **Stated as the inference it is:** no *new* position appeared at the broker, which is not the same as the two sides having been compared. **No `position_reconciliation_lag` alert is owed on that basis**, and what would confirm it is the comparison itself once BigQuery returns.

**PER-STRATEGY KILL-TRIGGER SWEEP.** `perf.kill_flags` was unreadable; the prior run read every flag FALSE for both B and D (A, C, E hold nothing). Carried forward, not re-measured.

**The `current_drawdown` refresh was performed UNCONDITIONALLY against today's live closes, as the rule requires — and in degraded mode it had to be computed rather than read.** The D book's value-weighted return for 2026-09-21, from per-tranche share counts and confirmed closes, is **+1.4011%** (market value 547.0082 → 554.6725). Carrying the prior run's deployed unit value of ≈1.065664 forward gives ≈**1.080595** against a peak of 1.098110312, so **`current_drawdown` ≈ −1.5950%**, improved from −2.9547%. Against the **−50%** drawdown-kill threshold this is not remotely close. **No STRATEGY TERMINATION — DRAWDOWN flag. No RUNAWAY-SUCCESS flag** (D has 1 closed trade against a 30-trade gate and its TWR has not doubled).

**B open-book pairwise-correlation warning — structurally inert.** Strategy B holds **nothing**, so `n_positions = 0` and the `n_positions >= 2` limb fails on zero rather than on one. No `b_pairwise_corr_high` alert is owed. (The fixed-message correction landed 2026-08-31 remains untested by any live firing, as it has been since.)

**`interim_underperf_warning`** — carried forward FALSE for both strategies; nothing this session bears on a 90-day beta-adjusted excess. No alert owed and none open to heal-resolve.

**DIVIDEND NETTING ON A PRICE-LEVEL CRITERION — not owed, and not re-verifiable this run.** The prior run read `state.price_level_criterion_drift` and found exactly one row (`D:DIS:2026-08-05`), which is **not** an actionable price-level exit criterion (`is_exit_criterion = false`, `actionable_price_level = false`, `cum_dividend_since_reference = 0`). **No position in this book tests a PRICE LEVEL**, so no comparison against a raw close was made and none needed netting. Carried forward; the view itself was unreadable.

**Per-position thesis-invalidation assessment against this window's DEVELOPMENTS — no criterion is met on any of the 12, and every position rose.**

| Position | 09-21 move | Development bearing on it | Invalidation met? |
|---|---|---|---|
| D:AMZN ×2 | **+1.8683%** | Rose with XLY. The Amazon/Meta-agent blocking story is real but is a minor commercial friction item, not a structural claim about AWS or retail margin. | **NO** |
| D:DIS ×2 | **+1.5194%** | Rose roughly with the tape, and **notably UNDER-performed XLC's +3.5556%** — but that gap is entirely META's, not a DIS-specific signal. No DIS news. | **NO** |
| D:GEV | **+0.6264%** | The weakest riser in the book. Nothing in this window touches its orders-growth criterion; the GLJ forward backlog-margin bear case from 09-14 remains unaddressed and is still not an invalidation event. | **NO** |
| D:GOOGL ×2 | **+1.5535%** | **The €403m Irish DPC fine is the one development that names a position directly.** Assessed and NOT invalidating: GOOGL's criteria name Cloud revenue, margin and RPO; a privacy penalty of ~0.02% of market cap touches none of them, and the DPC's three further advanced inquiries are a forward overhang, not a resolved event. Recorded so a later session sees it was evaluated rather than missed. | **NO** |
| D:ISRG | **+2.1153%** | Rose again, and again with no established driver — a second consecutive unexplained advance, recorded as such. No competitor-displacement evidence, so criterion 4 is untouched. | **NO** |
| D:RTX | **+0.1753%** | Nothing. The Iran escalation rhetoric is the kind of development that would normally bid a defence prime; RTX barely moved, which is itself mild evidence the market is not pricing escalation. | **NO** |
| D:TSM ×2 | **+2.4087%** | Its criterion 3 names a structural AI-capex reset via hyperscaler/Nvidia order cuts or a CoWoS utilization drop. **The session moved hard the OTHER way** — AMD to $1T, INTC +12.1%, ARM +17.2%, XLK +2.77%. Criterion 3 is not merely untouched, it is contradicted. | **NO** |
| D:UBER | **+0.4823%** | Nothing. | **NO** |

**Watchlist candidate status.** The Strategy A queue (~45 names) is uniformly held out by A's `DO-NOT-ACTIVATE` router — unchanged by anything in this window. The five-name 09-20 Strategy B cohort (XENE, NUE, MSTR, COIN re-anchored to 2026-09-17, windows closing 2026-10-01; **BE expired ungraded on its corrected 2026-09-04 anchor**) is unchanged by this session's developments; **none of the five appeared in today's confirmed mover set**, and the stale XENE figure one aggregator served was rejected rather than mistaken for a fresh move. Two Strategy D re-screens remain live (`rescreen-LLY-D-20260914` complete with `rescreen-LLY-D-20261214` pending; `rescreen-NKE-D-20260925` default decline), plus `rescreen-ORCL-B-20260920` which was due 2026-09-21 — **it is D2's to drain and D2 is halted tonight**, so it will roll.

---

## ANALYSIS — OPPORTUNITY CHECK

Evaluated against every roster-active strategy with `review_cadence: reactive` in `strategy/roster.yaml` — **A, B, C, E** (D excluded via `review_cadence: long_horizon`), re-read from the repo file this run since the state mirror was unreadable. All five founding strategies are `roster_state: adopted`.

**Every reactive-cadence strategy remains router-held**, so nothing routes to thesis construction from this window: A, B and E are `DO-NOT-ACTIVATE` and B and E are capital-disabled; C is `HYBRID ACTIVATE (FOMC-only)` and no FOMC event falls in this window.

**Strategy B — three candidates carry a defensible public event AND clear the frozen Entry criterion 1 (≥5% close-to-close on event day). State-index only.**

| Ticker | Move | Anchor | Qualifying event, with its release timestamp | Caveat carried to any future thesis session |
|---|---|---|---|---|
| **GRAL** | **+33.6759%** | **2026-09-21** (same session, intraday) | FDA staff briefing document for the Galleri PMA posted with no major concerns, ahead of the 09-23 AdComm. FDA's own advisory-committee calendar page reads *"Content current as of: 09/21/2026"*; the posting is **bounded before ~12:37 ET** by a same-day analysis piece. Exact clock time UNRESOLVED; the date is not. | The cleanest event on the board. **But note the shape:** this is a *partial de-risking ahead of an unresolved binary*, so the **09-23 vote is a second, larger event inside any 10-day window** — a thesis must say what happens to the position across it rather than treating 09-21 as the whole story. |
| **WBD** | **+10.7914%** | **2026-09-21** (same session, intraday) | Twelve state AGs, led by California, settled their suit blocking the ~$110B WBD/Paramount Skydance merger. Primary: the CA OAG's own press release (carries **no timestamp**); the move was underway early in the session ahead of AG Bonta's on-record press conference. **Before the close, confirmed; clock time UNRESOLVED.** | Strongest event class here on dateability. **PSKY −2.9383% is the same event's counterparty leg** and moved the other way — a thesis on either name should explain why one settlement is worth +10.8% to one side and −2.9% to the other. |
| **NVO** | **−7.9556%** | **2026-09-21, 04:00 ET — PRE-OPEN, EXACT** | Novo Nordisk's own company announcement **PR260921-CMD-2026** via GlobeNewswire, 10:00 CEST = **04:00 ET**, for its Capital Markets Day in London. NVO's ADR was already down ~6% in premarket. **The only anchor of the three pinned to the clock, and it is issuer-originated.** | **The best mechanism fit of the three** — the stock fell on its own forward-looking disclosure, an information-versus-reaction divergence rather than a justified re-rating. Counterweight: patent-cliff repricing may be the market correctly discounting a real 2031+ cash-flow loss, in which case there is nothing to converge. |

**ANCHOR RESOLUTION — the convention landed in D1's prompt this run (see PLAN EDITS) was applied to this run's own candidates, and it changed two of them.** `qualifying_event_date` is the date the event became **public**, never the session the move was measured in. A dedicated leg went to the primary documents:
- **All three routed candidates anchor to 2026-09-21 and criterion 1 is therefore tested on 2026-09-21's move, which is the move measured.** NVO is pinned to the clock (04:00 ET, pre-open, issuer's own announcement). GRAL and WBD are confirmed **same-session and before the close** by multiple independent outlets, with the exact clock time **UNRESOLVED and recorded as such** — every reachable source omitted one, including two that were paywalled or blocked. An unresolved *time* inside a confirmed *date* does not move the anchor; it is recorded so a later session knows it was sought and not found.
- **ARM's anchor is 2026-09-16, not 2026-09-21 — and this is the finding that justifies holding it out.** The governing Haas comments aired on CNBC **after the close on 2026-09-16**, so the anchor is 09-16 and the reaction session is 09-17. **No new Haas remarks on 2026-09-21 exist**; the 09-21 coverage attributes the move to his *"recent"* comments. Anchoring a +17.16% Monday move to Monday would have been **the exact MSTR-class dating error** the new rule exists to prevent, reproduced within a day of writing it.
- **META's Muse leg first went public on 2026-09-18**, three days before this session — an executive's post on X, restated by Monday coverage as though new — and an App Store ranking is a **continuously-observable state, not a discrete disclosure**, so it cannot anchor anything. The Wells Fargo leg is a third party's *opinion* with **no primary source in existence** (bank research is not published publicly), reported only via aggregators.

**Four names clear the 5% bar and are deliberately NOT routed, even to the state index** — the same treatment 09-20 gave SMR and GM, but this time on dated evidence rather than on judgment alone:
- **ARM +17.1583%** — held out because its event is **five sessions stale**, per the resolution above. This is a materially stronger reason than the "attribution is contested" one this run would have recorded without the anchor leg.
- **INTC +12.1363%** and **AMD +9.9496%** — one sector repricing, not two events. Neither has an issuer disclosure; the driver is another company's product launch plus summit optimism. INTC's SK Hynix leg is explicitly *speculation*.
- **META +11.3406%** — held out on event quality, not magnitude, per the resolution above.

**Degraded-mode limitation on criterion 1 for the held-out names, stated rather than glossed:** because ARM's and META's true anchors fall on earlier sessions, testing criterion 1 properly would require their close-to-close moves **on those sessions** (2026-09-16→17 for ARM, 2026-09-17→18 for META). Those bars were not pulled — the names are held out on event quality regardless, so the test would not change the disposition — but a future session that wants to revisit either must pull them rather than reuse the 09-21 figures above.

**Strategies A, C, E: no candidates.** No newly-announced qualifying catalyst within 6 months surfaced for A, none within 45 days for C (and C is FOMC-only with no FOMC in window). **For E, the WBD/PSKY pair is a genuine same-event divergence and the best intra-group pair setup seen in several sessions** — but E is capital-disabled with a `DO-NOT-ACTIVATE` router, and the pair screen is M2's monthly call, not D1's. Recorded for M2 rather than routed.

**`NO-GO records are context, not barriers`** was applied. **Degraded-mode limitation, stated rather than implied:** the four-part field identity check `(item_type, strategy, ticker, qualifying_event_date)` against open and terminal `events.queue_events` history **could not be run** — that table was unreadable. The three candidates were checked against the repo record instead (`Watchlist.md`, the prior `Daily.md`), and **none of GRAL, WBD or NVO appears anywhere in it**. **D2 must perform the real field-based dedupe before converting**, and must not match on the key string.

---

## ANALYSIS — ADD-CANDIDATE CHECK

Strategies **A, B, D only** (Rev 40). **Durable record DEFERRED** — the `events.decision_log` `add-candidate-review` row could not be written; its full `fields` JSON is in the deferred-writes ledger.

**`mark_vs_cost_pct` — the denominator had to be RECONSTRUCTED, and that is labelled, not smoothed.** The rule requires **that tranche's own** `cost_basis / shares` from `state.current_positions` and explicitly forbids the broker's account-level blended `avg_price`. `state.current_positions` was unreadable. Rather than fall back to the forbidden basis, each tranche's cost was **derived arithmetically** from the prior run's published `mark_vs_cost_pct` against the confirmed 2026-09-18 close: `cost = close_0918 / (1 + mark_vs_cost/100)`. The numerator is today's IBKR regular-session close, as the rule requires.

**The reconstruction was validated against the broker, and the one name that FAILS the validation is the rule's own worked example.** For three of the four single-tranche names the derived cost matches IBKR's blended `average_price` to within 0.001%: **GEV** 969.9063 vs 969.90595, **RTX** 176.8990 vs 176.89881, **UBER** 73.2067 vs 73.20733. **ISRG does not** — derived **349.5294** against the broker's **352.4638**, a **+0.84% divergence**. That is precisely the account-level-blend artifact the 2026-09-07 pin warns about: ISRG carried a Strategy B position that exited in August, so IBKR's average-cost basis blends history that the D tranche's own cost basis does not. **Recorded as an inference** — the B exit could not be verified from BigQuery this run — but the three clean matches are strong evidence the reconstruction method itself is sound and that ISRG's gap is a basis-method seam rather than a reconstruction error.

| Tranche | Derived cost | mark vs cost (09-18 → 09-21) | Trigger | Disposition | Evaluable |
|---|---|---|---|---|---|
| D:AMZN:2026-07-09 | 241.2437 | +5.1675% → **+7.1323%** | none | declined_hard_gate | **false** |
| D:AMZN:2026-07-30 | 265.6922 | −4.5098% → **−2.7258%** | none | declined_hard_gate | **false** |
| D:DIS:2026-05-07 | 111.3200 | −7.7704% → **−6.3690%** | none | declined_hard_gate | **false** |
| D:DIS:2026-08-05 | 103.7854 | −1.0747% → **+0.4284%** | none | declined_hard_gate | **false** |
| D:GEV:2026-08-03 | 969.9063 | −3.0494% → **−2.4421%** | none | declined_hard_gate | **false** |
| D:GOOGL:2026-07-09 | 359.8475 | −2.8644% → **−1.3554%** | none | declined_hard_gate | **false** |
| D:GOOGL:2026-07-26 | 327.8433 | +6.6180% → **+8.2743%** | none | declined_hard_gate | **false** |
| D:ISRG:2026-07-20 | 349.5294 | +12.5313% → **+14.9116%** | none | declined_hard_gate | **false** |
| D:RTX:2026-04-27 | 176.8990 | +9.6671% → **+9.8593%** | none | declined_hard_gate | **false** |
| D:TSM:2026-07-21 | 427.8610 | +1.5914% → **+4.0385%** | none | declined_hard_gate | **false** |
| D:TSM:2026-07-29 | 392.8826 | +10.6361% → **+13.3010%** | none | declined_hard_gate | **false** |
| D:UBER:2026-07-09 | 73.2067 | −3.6973% → **−3.2329%** | none | declined_hard_gate | **false** |

**`n_evaluated` 12, `n_flagged` 0, `n_declined_hard_gate` 12.**

**WHY ALL TWELVE, AND WHY IT COSTS NOTHING TODAY.** The HARD GATE asks whether the position's original at-entry invalidation criteria can be **affirmatively confirmed unbreached**. That confirmation comes from `state.current_positions.invalidation_status`, a BigQuery field, and **the mirror was unreadable for this entire run**. The gate's own input is therefore missing, and "unbreached" cannot be affirmed for **any** tranche — so all twelve are `declined_hard_gate` and `invalidation_criteria_evaluable` is **false** on all twelve. This is the conservative reading and it is the correct one: the field exists to make ambiguity legible, and a run that cannot see it must not report evaluability it does not have. **The prior run's three-of-twelve split (ISRG, RTX, UBER on `$.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`) is carried forward as context and is NOT restated as this run's finding.**

**It changes nothing, and that is measurable rather than asserted: not one trigger fired.** Trigger (a) is a dip against an intact thesis, and **every one of the eight names ROSE today** — the book was +1.4011% value-weighted — so criterion (a) is foreclosed across the entire book by price action alone, before the gate is ever reached. Trigger (b) is strengthened conviction, and **nothing in this window reinforces a multi-year structural driver**: the closest candidate is the AI-semis repricing bearing on **D:TSM**, and that is a sector re-rating on another company's product launch, not new information about TSM's own capacity, pricing or customer concentration. Treating a +2.77% sector day as conviction-strengthening for a multi-year thesis would be exactly the reasoning the add rule's "new information reinforcing, not replacing" language exists to exclude. **So the sweep would have produced zero flags on a healthy run too**, and the degraded gate cost no candidate.

**The two names worth naming anyway**, so the series does not read as though nothing ever qualified: **D:GEV** remains −2.4421% below cost with its invalidation criterion untouched, but it rose 0.6264% so there is no dip; and **D:DIS:2026-08-05 crossed ABOVE its cost today** for the first time in this series (−1.0747% → +0.4284%), which retires the dip case that was live on 09-20. **D:DIS was the one genuine dip-with-intact-thesis trigger of the prior run and it is gone on price, not on judgment.** Note also that Strategy D remains `DO-NOT-ACTIVATE` and capital-disabled, so an add would have been unfundable regardless — the same standing reason recorded on 09-14, 09-16 and 09-20.

**Cross-strategy exclusions** are not binding here: every open position is Strategy D and Strategy.md bars only concurrent A-and-B and A-and-C in the same name.

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review is recommended. High bar; default NO on ambiguity holds.**

**The one thing that came close is the same metric as yesterday, moving back the other way.** Equity breadth crossed **above 50** (50.49, +0.99pp) after a single session beneath it, and the shared vocabulary's Equity Breadth State is **HEALTHY ≥50 / WEAK <50** — a threshold Strategy A's router reads. It is still **NO**, for three independent reasons: the classification is **D2a's to apply, not D1's** (D1 writes `TECHNICAL_INPUT`, never `TECHNICAL_SIGNAL`); the crossing is 0.49pp, well inside a day's noise on a series that has now straddled the line twice in two sessions; and **A is already `DO-NOT-ACTIVATE`**, so a WEAK→HEALTHY flip is permissive rather than restrictive and cannot by itself activate anything. **Recorded as an observation for D2a's STEP 1e and M1a's next scoring.** Worth flagging for M1a that this key has now flipped state twice in two sessions, which is the pattern a threshold-straddling series produces and is a reason to read the level rather than the crossing.

**Nothing else approaches the bar.** The five current divergence ids (`div-{A,B,C,D,E}-202608-1`) all date to 2026-08 and the FUNDAMENTAL_AXIS scores are as-of 2026-09-01 — none of this session's developments (a tanker strike that oil ignored, a merger-litigation settlement, an AI-semis repricing, an EU privacy fine, a bank-exposure supervisory sweep) speaks to a strategy's *activation* conditions as Strategy.md defines them.

**The standing ambiguity is now 20 days old and its evidence got worse again.** `shock_overlay = 'acute'` is as-of **2026-09-01**, while this window's own evidence points the other way harder than yesterday's did: **a tanker was actually struck in Hormuz and Brent fell 3.4% on the day, a fourth consecutive decline.** A standing state is never news and the overlay is M1a's to re-score — but this is the second consecutive run flagging it, and the contradiction is no longer merely a drift in the level, it is a kinetic event the tape declined to price. **Escalated to M1a rather than acted on here.**

---

## EQUITY-BREADTH OBSERVATION

**DEFERRED — `events.regime_events` was unwritable.** The figure was fully measured and is carried, paste-ready and idempotency-guarded, in the deferred-writes ledger: `as_of_date = 2026-09-21`, `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`, `numeric_value = 50.49`, `value = 'Barchart $S5TH'`.

- **Figure: 50.49** as published (`50.49 +0.99 (+2.00%) 18:09 ET [INDEX]`), source **Barchart `$S5TH`**, as-of wording verbatim *"Quote Overview for Mon, Sep 21st, 2026"*. **SOURCE-DATED, not `inferred_post_close`** — the fallback was neither used nor claimed.
- **THE ON-PAGE TIME PASSES, and this is the first run to apply the pin landed on 09-20.** Barchart's page carried **18:09 ET**, comfortably at or after the 16:00 ET close for the session it claims. That pin exists because the 09-17 run recorded 51.09 off two sources that both carried a **14:58 ET** stamp — an hour before the close — and the settled figure turned out to be 50.29, 0.80pp lower. **The guard fired correctly today and cost nothing.**
- **Previous Close reconciles EXACTLY.** Barchart's Previous Close field reads **49.50** against the 49.50 stored for 2026-09-18 — a **zero** mismatch, so no revision-noise question arises at all this run.
- **Cross-check: two usable sources, exact agreement.** EODData `S5TH` independently returned Close **50.49** for 21 Sep 26 (O 50.69 / H 51.09 / L 48.70), gap **0.00pp**. The compound EODData unsettled tell does **not** fire (Low 48.70 ≠ Close 50.49).
- **TWO CAVEATS RECORDED RATHER THAN SMOOTHED.** (1) EODData's own page header stamped **15:48 ET — below the 16:00 threshold** — and did not advance across a deliberate re-fetch, so on the letter of the pin it is **not independently certified post-close**; it is used as corroboration on the strength of Barchart's confirmed post-close page and the non-firing Low==Close tell. (2) **The two vendors agree to the cent on all four of OHLC**, which is more consistent with a shared upstream feed than with independent computation — so "two sources" is weaker evidence of independence here than the count suggests. Neither caveat changes the value; both change how much the agreement is worth.
- **Fetch provenance.** `tavily_extract` at advanced depth on cache-busted URLs produced both figures; a rendering `web_fetch` on the Barchart URL returned an **empty body**, which per the FETCH-METHOD-IS-PROVENANCE rule condemns that fetch, not the source.
- **MacroMicro: NOT probed, and none was owed.** The weekly re-probe rides on the **Sunday-anchored** week's first D1 fire; the 2026-09-20 Sunday run spent this week's probe (both paths failed again; the streak is unbroken since 2026-08-19). Today is Monday, so probing would have been a metered call buying nothing — exactly what the 09-06 ruling restructured the designation to avoid.
- **Day-over-day: 50.29 (09-17, settled) → 49.50 (09-18) → 50.49 (09-21).**

---

## PARK ALLOCATION CALL

- **`vehicle`: VOO** — at `target_f_pct = 0` the risk sleeve is the whole book, so VOO is the majority sleeve trivially. `risk_sleeve` VOO, `defensive_sleeve` SGOV.
- **`target_f_pct`: 0 — DOWN from 25. Direction: RE-RISK. Status: BOUND in form (see the binding note below).**
- **`conviction`: LOW, `conviction_pct` 15.**
- **`rationale`: the prior session named a re-risk bar, the bar was met, and both reasons it gave for declining f=0 were removed today.**

  **The bar.** The 09-20 call's `invalidation` stated it would **LOWER f to 0** on any one of: breadth recovering above ~60; the shock overlay de-escalating at the next M1a scoring; **or a second consecutive session with VIX below 15.** It went further and flagged that disjunct as already half-satisfied: *"VIX printed its first sub-15 close at 14.81, so a second consecutive sub-15 close completes it."* **VIX closed 14.87 today. That is the second consecutive sub-15 close and the disjunct is satisfied.** Honoring a named bar in the re-risk direction is the whole point of the 2026-08-18 SYMMETRIC EVIDENTIARY STANDARD, whose worked failure was a session that did *not* honor one and held the park through VOO 684.56 → 706.23.

  **The two stated reasons for declining f=0 yesterday are both gone.** Yesterday: *"breadth made a new low and crossed below 50, and the 2Y printed a cycle high with the 10Y back through 5%."* Today **breadth recovered +0.99pp to 50.49, back above 50**, and the **10Y fell 5bp to 4.96, back below 5.00**. The 2Y is unchanged at 4.76. The specific grounds that carried the KEEP have been withdrawn by the tape.

  **The axes, hand-scored — and there was no mechanical panel to agree or disagree with.** `state.park_axis_daily` was unreadable, so `fields.axis_overrides` is empty for the structural reason that there was nothing to override. **The one-way ratchet is not engaged and could not be:** it exists to stop a mechanical count upgrading a KEEP into a conversion or a one-axis call into a two-axis one, and the absence of the panel therefore cannot license a larger move — this call is a **decrease**, which the ratchet does not guard, and re-risks are explicitly exempt from the DE-RISK EVIDENCE CARDINALITY rule in every respect.
  - **Volatility — NOT defensive, and further away.** VIX **14.87**, second consecutive sub-15 close, **−5.4432%** below its 20d SMA of **15.7260** (yesterday −5.9025%). VIX rose 0.4051% on a +1.55% SPY day, which is a mild non-confirmation and is stated rather than omitted — but it fails both limbs of its conjunctive test either way.
  - **Breadth — STANDING defensive, improving.** **50.49** against the 66 line, so still defensive on the park's own scale, but +0.99pp and back above the vocabulary's HEALTHY 50.
  - **Index — NOT defensive, and markedly better.** SPY **773.50**, **+1.7627%** above its 50dma of **760.1020** and **+7.9190%** above its 200dma of **716.7414**. **The drawdown from the 777.88 trailing high (2026-08-13) collapsed to −0.5631% from −2.0813%** — the index is essentially back at its high, and the Nasdaq Composite made an outright record close.
  - **Rates — STANDING defensive, and genuinely MIXED within itself rather than improved.** 10Y **4.96** (−5bp, back below 5.00) and 30Y **5.29** (−5bp) are better; the **2Y is unchanged at 4.76, still a cycle high**, so the curve **flattened to +0.20 from +0.25, the flattest of this series** — a deterioration, not an improvement, and flattening is the classic defensive signal. The policy path is unchanged and hawkish: the Fed hiked to 3.75–4.00% on 09-16 with 12 of 18 dots seeing another 2026 hike, and **Goolsbee argued today that the AI capex boom is itself a second, demand-side inflation driver** with October odds above 50%. **This is the one robustly intact defensive axis and I am not discounting it.**
  - **Credit — NOT defensive.** HYG/IEF **0.863193** against a 20-session SMA of **0.860150** = **+0.3537% ABOVE**, where the test needs 0.50% *below*. It moved toward the test from +0.5806%, but **HYG itself ROSE (+0.1910%) and LQD rose (+0.3725%)** — the ratio moved only because IEF rose more (+0.3855%). A rates artifact, not a credit event; the same mechanism as 09-18 with the sign inverted.
  - **Shock — STANDING defensive, and the weakest of the three by a wide margin.** `shock_overlay='acute'` is a **twenty-day-old** standing state as of 2026-09-01, and Brent **100.34** still exceeds the 95 line — but it fell **−3.3985%**, a **fourth** consecutive decline, and the margin over 95 narrowed to 5.6% from 9.3%. **Today's own evidence actively contradicts the axis: a tanker was struck in Hormuz and confirmed by UKMTO, and crude fell 3.4% anyway.**

  **The arithmetic, computed before this was written.** Standing defensive count **3** (breadth, rates, shock), unchanged. Firing count **0** — no axis entered defensive — so the **increase gate is SHUT** and f=50 was mechanically unavailable; the only live choice was KEEP-25 versus DECREASE-to-0. Raw cap `LEAST(100, 25×3)` = **75**. **The decay-confirmed cap steps to 75 today, exactly as the prior run predicted it would:** the standing series reads 5 (09-15), 5 (09-16), 3 (09-17), 3 (09-18), **3 (09-21)**, so the lower count has now held on the two preceding measured sessions and the step-down executes on this third reading. The clamp is non-binding at any f considered. **Ladder: suggested target = nearest step to `0.15 × 75 = 11.25`; |11.25−0| = 11.25 against |11.25−25| = 13.75 → 0.** The ladder returns 0 directly; **no ±1-step deviation is used or needed.** **Crisis override not engaged:** session index move **+1.5505%** against the −2.5% bar, VIX **14.87** against the 28 bar.

  **Why f=0 beats the runner-up.** The runner-up is **KEEP-25** (f=50 is *barred* by the shut gate, not declined). The park's default vehicle is the risk asset, so **it is the defensive weight that needs justifying, not the risk weight** — and on that framing the question is whether three standing axes still justify a quarter of NAV in T-bills. Two of the three are weakening: breadth is back above the HEALTHY line, and the shock axis rests on a twenty-day-old overlay its own evidence contradicted again today. **That leaves rates as the one robustly intact defensive axis** — real, but one axis, and the cardinality floor already tells us the system treats a single standing axis as thin. Against that sits a measured record that is hostile to defensive positioning: **both closed defensive excursions of the AI era LOST** (−2.841pp, −1.019pp; 0-for-2), across 15 historical episodes the defensive signal carried mean forward edge **−0.638pp** and won **4 of 15**, and de-risking at all still costs against simply holding VOO.

  **The case AGAINST f=0, stated in full because it is real.** The session had **no scheduled catalyst whatsoever** — one +1.55% day on flow, a sell-side note and an app-store ranking is thin evidence to retire a defensive posture on. VIX *rose*. The curve *flattened*. And three axes are still standing defensive on the mechanical scale. **What decides it against that:** decreasing f is always allowed and never delayed, the prior session named this exact bar and it cleared, and the two specific conditions it cited for holding have both reversed. Declining now would make the re-entry bar harder than the exit bar in substance while appearing to honor it in form — the precise asymmetry the 2026-08-18 standard forbids.

- **`invalidation` (symmetric standard, both limbs disjunctive and at the same height):** **Would RAISE f from 0** — any one of: VIX closing back above its 20d SMA; SPY losing its 50dma on a close; credit finally confirming (HYG/IEF crossing more than 0.50% *below* its 20d SMA); breadth breaking back down through ~45; or Brent closing back above ~110. **Would KEEP f at 0** — the absence of all of the above. Each raise-limb disjunct is itself an *entering* event, so the increase gate would open with any of them, and the cardinality rule would then require a second independent axis before any increase converts. **Deliberately NOT added to the raise limb**, though I considered each: a further curve flattening, or a single hot inflation print. Both are real risks, but naming them would make the return-to-defensive bar a *conjunction-in-spirit* against a single-disjunct exit bar — the asymmetry this standard exists to prevent, and the exact mistake the 07-31/08-02 conjunctive re-entry bar made. No later session is bound by any of this.
- **`theater_check`:** **The decision rests entirely on one falsifiable number and I am naming it rather than burying it.** At `conviction_pct` 20 the ladder returns `0.20 × 75 = 15` → nearest step **25**, and this call would have been KEEP. At 15 it returns 0. **So the whole conversion turns on scoring my conviction in the defensive posture at 15 rather than 20**, and the conviction was chosen before the target, not after. The stated ground is that I am effectively scoring **two** robust standing defensive axes rather than three: the shock axis rests on a twenty-day-old `shock_overlay='acute'` whose own evidence contradicted it again today, and a standing state that its evidence has stopped supporting is not the same as a live defensive signal. **That is the claim to attack** — if a reader thinks a twenty-day-old overlay still deserves full weight, the correct call is KEEP-25 and the arithmetic says so explicitly. The opposite theater risk also applies and is worth naming: a conversion day invites dressing a decision as inevitable, and it was not — KEEP-25 was fully available and is defended above rather than strawmanned.

**⚠️ BINDING NOTE — the call is BOUND in form but reaches nothing tonight.** Every well-formed call logs `status='BOUND'`, and `'HOLD'` is reserved for the connectors-down / **evidence-ungatherable** case. **This is not that case**: all six axes were measured live this run from IBKR and published sources, and what was missing — `park_axis_daily`, `park_signal_daily`, `hy_oas`, `current_regime` — is briefing input the spec itself classes as weighable, never a mechanical input. So `HOLD` would misreport the run. **But the `park-allocation` decision_log row could not be written, so the call cannot reach `state.park_allocation_latest`, which is the only path D2 uses** — and D2 is halted on the same outage regardless. **No capital moves tonight.** Tomorrow's D1 re-decides fresh on tomorrow's evidence, as every KEEP and every conversion always does. This was stated after the call was made and deliberately did not influence it.

**Park state, measured at the broker:** VOO **16.2040 sh** × 712.78 = **$11,549.89**; SGOV **37.7181 sh** × 100.60 = **$3,794.44**; total **$15,344.33**; **`actual_f_pct_before` = 24.7286%** against a standing target of 25 — inside the no-op band, confirming the 09-17 graded re-risk remains fully settled. Converting to f=0 would sell the whole 37.7181 SGOV and buy ≈5.3235 VOO.

**Heartbeat: DEFERRED.** `ops.heartbeat ('loop:park_allocator', 'VOO call, status=BOUND')` is carried in the ledger. **This is the `meta_monitoring_heartbeat` dead-man's-switch marker, so its absence will correctly register as a missed beat** until the ledger is landed — which is the switch working, not a fault to suppress.

---

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

One HF `hf_fs` paper search, the **Monday** rotation slot (**cross-session consistency**). Five results returned; **not one was published inside the scan window**, and the gap is not marginal — the most recent hit (ReasonBENCH, 2512.07795) dates to **2025-12-08, over nine months before this window opens**, and two others are from 2023. **No capture owed, no `[HF Frontier-LLM Capture]` entry, no `state.strategy_candidates` row.** Out-of-window results are reported as out-of-scope rather than dressed up as findings.

**One observation for `HF_Resource_Catalog.md`'s owner, recorded not acted on:** this is the second consecutive run in which the `hf_fs` search returned only semantically-matching but badly stale papers (09-20's long-context slot returned nothing newer than 2026-09-03, seventeen days out). The tool appears to rank by semantic match with no recency weighting, which makes a "published since the last run" filter do all the work and return empty most days. Whether that is worth a query-shape change is §6.1's owner's call, not D1's.

---

## DEFERRED BIGQUERY WRITES

**Ten writes are owed and none landed.** The full record — paste-ready SQL, the recovery procedure, the idempotency guards, and an explicit list of what is NOT owed so a later session does not manufacture rows — is in **`ops/spikes/bigquery-deauth-2026-09-21-d1-deferred-writes.md`**. It lives there rather than only here because **this file is wholesale-overwritten by the next D1 run**, which is the "prose log that deletes itself" failure the add-candidate durable-log rule was written against.

| # | Target | Content |
|---|---|---|
| 1 | `ops.run_log` | `sp_routine_start('D1', 2026-09-21, …)` |
| 2 | `ops.sp_auto_resolve_alerts()` | best-effort preamble, never ran |
| 3 | `events.decision_log` | `research-screen`, `screen='single-name-move'`, `surfaced_count=8`, `rail_tally=11`, `universe_measured=25`, `agreement={both:7, ai_only:1, rule_only:4}` |
| 4 | `events.decision_log` | `research-screen`, `screen='sector-move'`, `surfaced_count=5`, `rail_tally=6`, `universe_measured=11`, `agreement={both:3, ai_only:2, rule_only:0}` |
| 5 | `events.decision_log` | `add-candidate-review`, `n_evaluated=12`, `n_flagged=0`, `n_declined_hard_gate=12` |
| 6 | `events.decision_log` | `park-allocation`, `target_f_pct=0`, direction `re-risk`, `conviction_pct=15`, status `BOUND` |
| 7 | `ops.heartbeat` | `('loop:park_allocator', 'VOO call, status=BOUND')` |
| 8 | `events.regime_events` | `EQUITY_BREADTH_PCT` = 50.49, `as_of_date=2026-09-21`, `TECHNICAL_INPUT` |
| 9 | `ops.web_calls` | **109 rows** — 65 Tavily + 28 FMP + 1 HF (metered) plus 13 `web_fetch` + 2 WebSearch (free but still owed a row) |
| 10 | `ops.run_log` | `sp_routine_end('D1', …, 'completed', …, rows_written=0, …)` |

**Consequence to expect, stated so it is not mistaken for a new fault:** `state.web_spend_month.has_unreported_runs` will read TRUE for D1 on 2026-09-21 until write 9 lands, so any fleet spend total drawn from `ops.web_calls` is a **FLOOR, not a total**, and must be reported as one. The `research-screen` rows are the sole Strategy-B intake for W2 — **if they are still unlanded when W2 next fires, W2's intake for this session is empty**, and that is an absence of record, not an absence of candidates.

---

## PLAN EDITS LANDED THIS RUN

**One edit to `Claude_Task_Plan.md` (slices regenerated in the same commit; `split_task_plan.py --check`, `check_connector_tools.py`, `check_settings_toolcov.py` and five further blocking CI checks all run locally and green before pushing).**

**D1's `qualifying_event_date` anchor convention — closing D1's own `d1_qualifying_event_date_anchor_unspecified` (`ops.alerts` info `03b8f773`, open since 2026-09-16).** The rule already existed as `Watchlist.md`'s **ANCHOR PIN** (D2, 2026-08-19) — *"the event date governs; the flag-date wording above is legacy"* — but it was written only inside D2's section and that file, and **D1, the routine that actually SETS the field, carried no equivalent limb.** The cost is measured, not hypothetical: **four consecutive cycles** of D1 anchors corrected downstream (HPE/DELL right on 09-13, JBHT wrong on 09-16, SMR wrong on 09-17, **all five of the 09-20 cohort wrong**). The new limb states the rule operationally (a release after the close of session S anchors on **S**, not on the S+1 reaction session — the single case D1 has gotten wrong every time, because the reaction session is where the screen's own arithmetic lives), records **why it is not bookkeeping** (MSTR clears criterion 1 by 3.3× on the reaction-session anchor and **fails by 19bp** on the correct one, with COIN as the control that clears on both), records that it silently **lengthens windows** (BE's had already closed before D1 surfaced it), and forbids resolving the anchor from the price series — an unestablishable release timestamp is recorded **UNRESOLVED**, never defaulted.

**The new rule bound this run immediately, and it changed this run's own output — which is the strongest evidence available that it was worth writing.** A dedicated leg was spent resolving release timestamps against primary documents, and it moved two of the seven names that cleared the 5% bar: **ARM's governing event is dated 2026-09-16 after the close** (no 09-21 remarks exist at all — the Monday move is a five-session-delayed reaction), and **META's Muse leg first went public 2026-09-18** and is a continuously-observable ranking rather than a discrete disclosure. **Under the silent default this run would have stamped both 2026-09-21 and routed on it** — reproducing the MSTR-class error within hours of writing the rule against it. The three routed candidates all anchor correctly to 2026-09-21, one of them (NVO) pinned to the clock at 04:00 ET pre-open from the issuer's own announcement number. **The rule also cost something and that is recorded too:** GRAL's and WBD's exact clock times are genuinely **UNRESOLVED** — every reachable source omitted one — and they are carried that way rather than defaulted, per the limb's own instruction.

**Recorded and NOT fixed here, with owners named:** the IBKR parallel cross-contamination defect (`7cc25b71`, owner OPS1 / `ops/connector_tools.yaml`) — contained again this run by strictly sequential pulls, not repaired; the **absence of any durable convention for a degraded routine's deferred writes** (owner W5 or OPS0) — this run hand-rolled `ops/spikes/…`, and §5 of that file states what a real fix would look like and why a research routine's degraded fire is the wrong place to choose one unilaterally; and the `hf_fs` recency-ranking observation above (owner: `HF_Resource_Catalog.md` §6.1). **None could be raised as an `ops.alerts` row for the obvious reason — the alert sink is the thing that is down.**

---

## RECOMMENDED ACTIONS

- **Watchlist add — GRAL** to the Strategy B new-entry candidates state index (index-only; **no** thesis construction routed, B router `DO-NOT-ACTIVATE` and capital-disabled), qualifying event date **2026-09-21** (FDA advisory-committee materials page, *"Content current as of: 09/21/2026"*; same session, before the close, exact clock time unresolved).
- **Watchlist add — WBD**, same treatment, qualifying event date **2026-09-21** (twelve-state-AG settlement; CA OAG press release carries no timestamp, but same-session pre-close publication is independently confirmed).
- **Watchlist add — NVO**, same treatment, qualifying event date **2026-09-21** (Novo Nordisk company announcement `PR260921-CMD-2026`, GlobeNewswire, 10:00 CEST = **04:00 ET, pre-open** — the one anchor of the three pinned to the clock).

**No exits triggered. No add candidates flagged. No router review recommended.**

*NOTE, deliberately not a bullet and deliberately absent from the block below: the* `## PARK ALLOCATION CALL` *above is a* **RE-RISK to** `target_f_pct` *0, but its decision_log row could not be written, so it reaches neither* `state.park_allocation_latest` *nor D2 — which is halted on the same outage. D2 reaches the park call through that view, never through* `d1_actions` *or prose-parsing.*

*NOTE 2: all three bullets above require D2 to run, and* **D2 will halt tonight** *on the BigQuery outage. They are not lost — D2's catch-up evidence window reaches back to its own last completion — but they will not convert on 2026-09-21.*

```yaml d1_actions
- action: watchlist
  ticker: GRAL
  strategy: B
  qualifying_event_date: 2026-09-21
  source_research_screen_id: DEFERRED-see-ops/spikes/bigquery-deauth-2026-09-21-d1-deferred-writes.md
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, no thesis construction
    routed, B router DO-NOT-ACTIVATE and capital-disabled). +33.6759% close-to-close 80.77 ->
    107.97, IBKR RTH daily bars contract 708088152, both bars stamped 13:30:00Z, confirmed in a
    strictly-sequential solo pull. Qualifying event: the FDA staff briefing document for the Galleri
    multi-cancer early-detection test posted with no major concerns ahead of the 2026-09-23 advisory
    committee vote. Largest move on the board by 16pp and the cleanest event shape of the session -
    a binary regulatory readout partially de-risked by the regulator's own document. Clears B Entry
    criterion 1's frozen >=5% floor by 6.7x. Cap $4.63B (FMP profile-symbol). ANCHOR RESOLVED to the
    DATE, not the clock: the FDA's own advisory-committee materials page reads "Content current as
    of: 09/21/2026" and the posting is bounded before ~12:37 ET by a same-day analysis piece, so the
    event is same-session and before the close and criterion 1 is correctly tested on the 09-21 move
    measured here. The exact clock time is UNRESOLVED - the PDF carries no post-time and no reachable
    source states one - and is recorded that way rather than defaulted, per the anchor convention
    landed in D1's prompt today. CAVEAT for the thesis session: this is a
    partial de-risking ahead of an UNRESOLVED binary, so the 09-23 vote is a second and larger event
    inside any 10-day window. Four-part field-identity dedupe could NOT be run (events.queue_events
    unreadable); no GRAL record exists anywhere in the repo record. D2 must perform the real
    field-based dedupe, never a key-string match.
- action: watchlist
  ticker: WBD
  strategy: B
  qualifying_event_date: 2026-09-21
  source_research_screen_id: DEFERRED-see-ops/spikes/bigquery-deauth-2026-09-21-d1-deferred-writes.md
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE and
    capital-disabled). +10.7914% close-to-close 27.80 -> 30.80, IBKR RTH daily bars contract
    554208351, both bars stamped 13:30:00Z, volume 208,173,054. Qualifying event: the state
    attorneys general who had sued to block the ~$110B Warner Bros. Discovery / Paramount Skydance
    merger reached a settlement, removing a named and quantified obstacle. Strongest event class in
    this cohort on dateability - a third-party legal settlement by twelve state AGs led by
    California. Cap $77.2B (FMP profile-symbol). ANCHOR RESOLVED to the DATE, not the clock: the CA
    OAG's own press release is the primary source and carries NO timestamp, but same-session
    pre-close publication is independently confirmed - the move was underway early in the session,
    ahead of AG Bonta's on-record press conference - so criterion 1 is correctly tested on the 09-21
    move measured here. Exact clock time UNRESOLVED and recorded as such; two of the outlets that
    would have carried it were paywalled or blocked. NOTE FOR THE THESIS
    SESSION: PSKY -2.9383% (10.21 -> 9.91, contract 804144296) is the SAME event's counterparty leg
    and moved the opposite way; a thesis on either name must explain why one settlement is worth
    +10.8% to one side and -2.9% to the other. PSKY is below the 5% floor and is recorded as context
    only, never routed. Field-identity dedupe could not be run; no WBD record exists in the repo
    record.
- action: watchlist
  ticker: NVO
  strategy: B
  qualifying_event_date: 2026-09-21
  source_research_screen_id: DEFERRED-see-ops/spikes/bigquery-deauth-2026-09-21-d1-deferred-writes.md
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE and
    capital-disabled). -7.9556% close-to-close 43.24 -> 39.80, IBKR RTH daily bars contract 10611
    (NOVO-NORDISK A/S-SPONS ADR, NYSE), both bars stamped 13:30:00Z. Qualifying event: Novo Nordisk
    announced 2030 growth ambitions and the stock FELL, on concerns over the coming loss of US
    semaglutide patent exclusivity and rising obesity-drug competition. THE BEST MECHANISM FIT OF
    THIS COHORT - issuer-originated, and the name fell on its own forward-looking disclosure, which
    is an information-versus-reaction divergence rather than a justified re-rating. Cap $176.8B (FMP
    profile-symbol). ANCHOR FULLY RESOLVED TO THE CLOCK, and it is the only one of the three that
    is: Novo Nordisk company announcement PR260921-CMD-2026 via GlobeNewswire at 10:00 CEST =
    04:00 ET on 2026-09-21 (Denmark is UTC+2 under DST in September), for its Capital Markets Day in
    London. That is PRE-OPEN for the NYSE-listed ADR, and the ADR was already down ~6% in premarket -
    so the anchor is 2026-09-21 and criterion 1 is correctly tested on the 09-21 close-to-close move
    measured here. COUNTERWEIGHT the thesis session must
    clear first: a patent-cliff repricing may be the market correctly discounting a real 2031+
    cash-flow loss, in which case there is nothing to converge - this is the same objection standing
    against every justified-re-rating candidate. Field-identity dedupe could not be run; no NVO
    record exists in the repo record.
```

---

*Metered spend this run: **94** metered calls, **109** `ops.web_calls` rows owed and **DEFERRED** — 65 Tavily (62 `search` + 3 advanced `extract`, ~68 credits, a rate-card ESTIMATE not provider-reported), 28 FMP (2 of them ACCESS DENIED on plan tier, which still cost a call), 1 HF, plus 13 Anthropic `web_fetch` (4 of 8 blocked/paywalled on the anchor leg) and 2 WebSearch, both free but still owed rows. **94 IBKR calls** (52 `get_price_history` issued strictly one per message, 39 `search_contracts`, 1 `search_futures`, 1 `get_account_summary`, 1 `get_account_positions`) and all BigQuery calls are free and are not billed telemetry; two Bash `curl` calls to the Internet Archive availability API are not a metered surface and are noted rather than logged. Seven sub-agents were used for discovery, confirmation, fetch and timestamp-resolution work; **the orchestrator made no metered call of its own.** The SEARCH PROTOCOL's widen-before-repeating rule was carried into every sub-agent prompt with an explicit budget; the heaviest leg was the scheduled-events sweep at 13 searches to establish a **genuine absence**, which is the expensive shape of an empty day and is reported rather than smoothed.*
