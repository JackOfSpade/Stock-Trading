2026-08-23
<!-- d1_scan_through_utc: 2026-08-23T22:30:00Z -->

# Daily Market Development Scan — 2026-08-23 (Sun, MT)

> ## ⚠ DEGRADED MODE — BigQuery unreachable this run
>
> **The Google-Cloud-BigQuery MCP connector returned `requires re-authorization (token expired)` on every call**, including a bare `SELECT 1` probe. Per the `TRANSIENT-FAILURE DIAGNOSE-BY-PROBE` rule the probe pair was run **once**; `SELECT 1` failed with auth wording, which classifies as **non-waitable → the RE-AUTH branch**, not the retry ladder. Per `Claude_Task_Plan.md` Observability → "BigQuery unreachable": the alert sink is itself down, so `ops.alerts` / `sp_raise_alert` could not be used, and a **`[Claude] ATTENTION — RE-AUTH BigQuery connector` calendar event was created immediately** (2026-08-23 17:00 MT) as the only first-class channel. **D1 is research-only and stages no orders, so it proceeds in DEGRADED MODE** rather than halting.
>
> **What that means for this file, stated up front rather than discovered later:** the book and all marks are read from the **IBKR connector** (live, verified); regime/router state is **carried forward from the 2026-08-20 `Daily.md`**; and **every BigQuery side-write is DEFERRED** and itemised in **DEFERRED BIGQUERY WRITES** at the foot of this file. IBKR and Calendar both passed pre-flight. Nothing in this file is a guessed, recalled or model-produced number — where a figure could not be measured, it says so.
>
> **The same-day double-run guard could not be run** (it is a `ops.run_log` query). Substitute evidence: `Daily.md` on disk was dated **2026-08-20** with a matching commit at `2026-08-20T22:49:12Z`, so no D1 has completed since. Proceeding is correct.

**Scan window:** 2026-08-20 16:45 MT → 2026-08-23 16:30 MT (**71.75 hours — a MULTI-SESSION GAP, explicitly flagged**). The prior-run marker `<!-- d1_scan_through_utc: 2026-08-20T22:45:00Z -->` parsed cleanly from the `Daily.md` on disk and cross-checks against that file's own commit at `2026-08-20T22:49:12Z` (marker 4.2 minutes before the commit — consistent, not drift). **D1 did not run on Friday 2026-08-21 or Saturday 2026-08-22**; the window has therefore stretched back automatically to the actual last run, which is exactly what the dynamic-window rule exists to do. `state.routine_catchup_window` could not be read (BigQuery down), so no `CATCHUP` token is asserted either way.

**The window contains exactly ONE completed trading session — Friday 2026-08-21.** Saturday and Sunday are not trading days; today is Sunday, so this run covers Friday's session plus the weekend's news flow. Every close-to-close figure in this file is measured from **IBKR regular-session daily bars** (`get_price_history`, `step=ONE_DAY`, `outside_rth=false`), 2026-08-20 close → 2026-08-21 close, unless explicitly labelled otherwise. **No close-to-close figure here comes from `get_price_snapshot`.** Bars were identified by their own `T13:30:00Z` timestamps, never by array position — and that discipline earned its keep again this run (PROCESS NOTES 1).

## TL;DR

- **Exits triggered: none.** Zero mechanical triggers across the union of the live broker book and the carried-forward position list; no thesis-invalidation criterion breached on any of the 13 open D tranches. **Not one of the nine held names had a verified in-window company event** — the quietest book-level session in this file's recent history.
- **New entry candidates: none routed. 5 recorded index-only (BJ, TSLA, DNN, QBTS — all event-day 2026-08-21 — plus BTDR, whose qualifying day was 2026-08-20 and which the 08-20 screen MISSED).** B is DO-NOT-ACTIVATE and capital-disabled. **All four fresh names are B's weakest mechanism class** (justified re-ratings), which is the honest read, not a hedge.
- **Add candidates: none flagged. Zero genuine trigger-(a) fires** — against three last session. Friday was risk-on and the book rose with it; there were no dips to add into.
- **Watchlist changes:** add BJ, TSLA, DNN, QBTS, BTDR to the Strategy-B new-entry index; annotate MRNA (+8.86%, third session repricing the same unchanged data) and EL (+6.02%).
- **Regime review: no review.** Default-NO holds — but `growth_momentum` is now the strongest one-sided case it has been, and the reason to still decline is concrete rather than a hedge: **Jackson Hole (08-27→29) and NVDA earnings (08-26) both land BEFORE M1a re-scores on 09-01.**
- **Park: KEEP VOO** (MEDIUM, **58** — up from 55), status BOUND (write deferred).

**Tape — Friday 2026-08-21 (US cash close). RISK-ON, and it reversed Thursday in shape as well as sign.** SPY 762.60 → **765.72 (+0.41%)**; QQQ +0.35%; DIA **+0.89%**; IWM **+0.77%**; equal-weight RSP **+0.63%**, beating cap-weight by **22bp**. VIX 16.01 → **15.13 (−5.50%)**, back below its 50-day (16.98) and 200-day (18.50). **Eight of eleven GICS sectors higher, one flat, two lower.** GLD **+1.95%**, SLV +1.72%, USO +0.07%, UUP −0.04%. TLT −0.35%, IEF −0.19%, LQD −0.13%, HYG +0.06%. **Sector spread 4.42pp against Thursday's 2.14pp — dispersion more than doubled, and it is nearly all one name-group: XLU −2.28% against XLB +2.14%.**

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**(a) Iran / Hormuz — ESCALATED FURTHER, and it is now a six-session oil trend rather than a headline.** The ceasefire window expired 2026-08-17/18 (pre-window). In-window: Iran moved to a "fully offensive" posture, the US ruled out extending the ceasefire, and Trump characterised planned action as an **"Economic D-Day,"** with Treasury Secretary Bessent saying on 2026-08-21 that "any remaining tie to Tehran will hasten a nation's economic oblivion." Brent closed Friday around **$94.39** (+0.7%, its **sixth consecutive daily gain**, +~5% on the week); WTI ~$86–87. US retail gasoline hit a **record high for the calendar date** (~$4.10/gal, AAA). *Sources: WSJ live blog 2026-08-21; oilprice.com 2026-08-21; LPL Research weekly note 2026-08-21.* **What is new versus Thursday is duration, not a discrete escalation** — no Hormuz closure and no physical supply interruption is confirmed in-window. **The disconnect this file flagged on Thursday WIDENED rather than narrowed:** oil ground higher for a sixth session while **equity vol FELL 5.50%.**

**(b) The long end is the real macro story, and it got worse.** Total US federal debt crossed **$40 trillion** this week. Wednesday's Treasury buyback expansion has now fully failed to hold: the **30-year hit ~5.34% intraweek — a near-two-decade high — and settled ~5.27%**, while the **10-year closed ~4.734%, its highest close since January 2025.** *Sources: Investopedia 2026-08-21; LPL Research 2026-08-21.* LPL attributes the week's volatility to "fiscal worries, bond market supply crowding, and Federal Reserve credibility worries." **Equities rose anyway** — the second consecutive session where the bond market and the equity market disagreed, and Friday equities won.

**(c) Gold is behaving like the expression of (b).** GLD **+1.95%** on our own IBKR measurement; December futures ~$4,661–4,670, **+2.2% on the day and on track for the best month since 1999 (~+13% in August)**. UBS's Giovanni Staunovo reiterated a 12-month **$5,400** target citing US debt and dollar weakness (CNBC, 2026-08-21). **Recorded as a macro signal, not a trade:** a +13% month in gold alongside a 5.34% 30-year is a coherent fiscal-debasement read, and it is the single most persistent cross-asset message in this window.

**(d) Crypto — a genuine, large, in-window move with an identified mechanism.** Bitcoin rose above **$77,000**, its best week since 2024 (~+23%), on a **~$3.3B leveraged-short squeeze** plus Trump pressing Congress on crypto legislation. The equity complex followed: **HOOD +13.70%, COIN +8.20%, MSTR +6.10%, BMNR +5.84%, SOFI +5.52%** (all IBKR-measured). *Sources: WSJ live blog 2026-08-21; 247wallst 2026-08-20/21.* **Logged as ONE item, not five, to avoid manufacturing breadth** — no individual name has its own catalyst.

**(e) Jackson Hole is NEXT week, not this one — flagged prominently because the search space is heavily polluted.** The Kansas City Fed confirms the 2026 symposium runs **2026-08-27 → 08-29**. Fed Chair **Kevin Warsh** (sworn in 2026-05-22) is expected to give his first Jackson Hole address there. **No Jackson Hole speech occurred in-window.** A large share of "Jackson Hole Fed Chair speech" results are about **Powell's August 2025** address — stale by a full year — and a separate tranche discusses the Warsh appointment as though it were news. **A future session or routine that reads a "Jackson Hole" hit as in-window is almost certainly reading 2025.**

**(f) Nothing else cleared the bar.** No material bankruptcy, disaster, or unscheduled enforcement action with US market-wide impact surfaced in-window.

### 2. Scheduled events that resolved in-window

**THE EVENT OF THE WINDOW: S&P Global Flash US PMI (August, preliminary), released 2026-08-21 09:45 ET.** *Primary source: https://www.pmi.spglobal.com/Public/Home/PressRelease/552d682e429640fcb8af7da17ad060c3*

| Series | Actual | Consensus | Prior |
|---|---|---|---|
| **Composite** | **56.0** | ~54.0 | 54.5 |
| **Services** | **56.8** | ~54.0 | 54.6 |
| Manufacturing | **53.2** | ~53.9 | 53.9 |

Composite is a **52-month high**; services a **20-month high**; manufacturing a **5-month low**. This was the explicitly cited driver of Friday's equity rebound ("business activity grew at its fastest pace in more than four years"). **It is also the single most important input to the REGIME CHECK below.**

**Earnings that resolved in-window (US-listed, ≥$2B).**

| Name | Print | Result | Close-to-close |
|---|---|---|---|
| **BJ's Wholesale (BJ)** | **Fri 2026-08-21 BMO** | **Beat both lines.** EPS **$1.36** vs ~$1.16–1.17; revenue **$6.09B** vs ~$5.97B. | **+5.61%** (91.30 → 96.42) |

**EVENT-IDENTITY GATE — four findings, and they matter more than usual this run.**

1. **BJ is the only clean in-window earnings event.** Verified released **Friday 2026-08-21 before the open** (Zacks earnings calendar; CNBC live blog 2026-08-21), so Friday's **+5.61%** IS the reaction session. Measured independently on IBKR bars by this session, not taken from the press figure.
2. **BABA's print was THURSDAY, and this is the run's most important dating call.** Coverage dated 2026-08-21 reports "FY Q1 2027 results, adj EPS $1.26/ADS vs consensus" — but those are the **same figures the 2026-08-20 file already recorded from Thursday's pre-market release.** The print is **2026-08-20**; the 08-21 article is coverage, not a fresh event. **BABA's EVENT-DAY move was +1.26% (128.90 → 130.53); Friday's −8.57% (130.53 → 119.34) is a SECOND-SESSION repricing.** This distinction is load-bearing — see section 3.
3. **Walmart, Ross Stores, Target and TJX all reported 2026-08-20 and are PRE-WINDOW.** They remained heavily referenced in Friday's coverage; none is an in-window event and none is re-assessed here.
4. **NVDA (2026-08-26) and CRM (2026-08-26 AMC) are PENDING.** CRM's date was re-confirmed this run from Salesforce's own IR release: *"results will be released on Wednesday, August 26, 2026, after the close of the market."* No figures populated for either. **NVDA landing two days before Jackson Hole is the defining shape of the week ahead.**

**Fed.** No FOMC in-window; next meeting **2026-09-16**. **September hike odds moved materially: 32.7% → 39.0%** (Investing.com CME-based Fed Rate Monitor, updated 2026-08-22 00:35 EDT; a second OIS-based tool reads 34.4–37%, directionally consistent). **This is a reversal of the observation this file forwarded on Thursday — see OPPORTUNITY CHECK, Strategy C.**

**FDA / court / M&A.** **No PDUFA target action dates fall inside the window.** The nearest are Dasynoc (Xspray) 2026-08-25, Gilead's bictegravir/lenacapavir combo 2026-08-27, and ITM's 177Lu-edotreotide 2026-08-28 — all confirmed **PENDING**, none decided. No court ruling, M&A closing or index rebalance identified in-window.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

**Layer-1 population rail:** US-listed, market cap ≥ $2B, ≥2% close-to-close, attributable to identifiable public events. Population sourced from FMP biggest-gainers/losers/most-active, then **every** written-up figure re-measured on IBKR regular-session bars. **The enumeration is a bounded sample and is NOT established as complete.**

**THE DAY'S EVENT IS A NEGATIVE ONE: there was no single dominant single-name story.** Friday's movers decompose almost entirely into **three group drivers** (crypto squeeze, a quantum-sector analyst initiation, a utilities broker re-rating) plus a short tail of genuine single-name events. That is itself the finding — a broad risk-on session with thin idiosyncratic content.

**Written up (Layer-2 SIGNIFICANT):**

| Ticker | Move | Event | Significance | `legacy_rule_pass` (≥5%) | `below_spec_floor` (<5%) |
|---|---|---|---|---|---|
| **BABA** | **−8.57%** (130.53 → 119.34) | **Second-session** repricing of the **2026-08-20** FQ1-27 miss (adj EPS $1.26/ADS vs ~$1.85–1.94) | **75** — the most interesting object on the tape: a mega-cap that took a full extra session to price a miss it had initially shrugged off (+1.26% on event day) | true | false |
| **BJ** | **+5.61%** (91.30 → 96.42) | Q2 FY27 beat on both lines, **2026-08-21 BMO** | **60** — the only clean in-window earnings event; B's weakest mechanism class (price moved the way the information supports) | true | false |
| **TSLA** | **+5.14%** (345.13 → 362.86) | **2026-08-21**: Nevada cleared up to 5,000 driverless robotaxis in Las Vegas | **60** — a resolved, dated regulatory approval on a $1.43T name; justified re-rating | true | false |
| **DNN** | **+11.46%** (3.14 → 3.50) | **2026-08-21**: shift to full-scale construction at the Phoenix ISR uranium mine after approvals | **60** — genuine company-specific event; ~$2.95B cap, clears the rail | true | false |
| **Quantum complex** | **QBTS +8.46%**, RGTI +11.49%, IONQ +8.02% | **2026-08-21**: BMO initiated **D-Wave (QBTS)** at Outperform, $35 PT — sector followed | **60** — logged as ONE item; **only QBTS is the subject of its own event**, RGTI/IONQ moved on a third party's initiation | true | false |
| **BTDR** | **+9.01%** Fri; **+8.31% on 08-20** (9.63 → 10.43) | Barclays initiated Overweight $15 (08-20), plus Malaysia/Norway AI-cloud deals and a Q2 beat | **60** — **the qualifying day was 2026-08-20 and the 08-20 screen MISSED it.** Recorded now, not absorbed | true | false |
| **Crypto-proxy complex** | HOOD **+13.70%**, COIN +8.20, MSTR +6.10, BMNR +5.84, SOFI +5.52; **CIFR −8.40%** | ~$3.3B short squeeze, BTC >$77K — see 1(d) | **60** — ONE item, nine-plus tickers, no individual catalyst. CIFR fell *against* the complex on AI-pivot valuation scrutiny | true | false |
| **SRE** | **−5.14%** (87.38 → 82.89) | **2026-08-21** Morgan Stanley coverage-wide utility PT cuts (SRE $108→$104, **Overweight maintained**) | **60** — **clears the floor and is DECLINED as a B candidate on the SECTOR test.** See below | true | false |
| **UEC** | **+14.44%** (11.15 → 12.76) | **NO company-specific event found** | **45** — the largest single mover on the tape and the weakest-sourced item in the dataset; moved with uranium-sector strength alongside DNN | true | false |
| **FUTU** | **+9.68%** (112.73 → 123.64) | **No fresh Friday event.** Record Q2 was **2026-08-20 BMO** | **45** — **event-day move was +3.02%, BELOW B's floor**, so the 08-20 screen did NOT miss it; Friday is an unexplained delayed repricing | true | false |
| **Utilities complex** | **AEP −3.79%**, PWR −3.49, EXC −2.84, SO −2.72, DUK −2.31, **EIX −4.11%**, D −1.29, NEE −1.62 | Same 08-21 Morgan Stanley PT-cut wave | **60** — the session's most coherent cross-name message; **REGIME + GEV input**, see section 4 | false | **true** |

**Why SRE is declined despite clearing the floor — and it is the same call the 08-20 file made on STLD.** Strategy B wants a **single-name** post-event mispricing. SRE fell 5.14% on a **coverage-wide** broker action that hit AEP −3.79%, EXC −2.84%, SO −2.72%, DUK −2.31% and EIX −4.11% the same day; the PT cut itself was **$108→$104 (−3.7%) with Overweight MAINTAINED**, which does not on its own justify a −5.14% repricing. The disproportion is genuinely interesting — it is the shape of a sentiment cascade with a clean pre-event anchor at 87.38 — but the driver is unambiguously sector-wide, so it is **E ideation evidence, not a B single-name candidate.** Consistency with the STLD precedent is the point.

**Rejected as NOT significant (every ≥5% legacy-rule-passing item declined is listed — §19 requires this floor):**
- **MRNA +8.86%** (133.32 → 145.13) — **STALE attribution, and unusually clearly so.** Coverage explicitly describes it as "repricing the same unchanged Phase 3 melanoma data" from **2026-08-19**, now the **third** session doing so (+177% on 08-19, −23.55% on 08-20, +8.86% on 08-21). No new trial, regulatory, offering or index event. **Not a fresh B identity** — a continuation, exactly as MRVL's second day was treated on 08-20.
- **CIFR −8.40%** — no discrete event; "investors scrutinized its AI-pivot valuation." Declined on the same ground ISRG was declined on 08-20: B needs an event and there is none.
- **UEC +14.44%** — declined for the same reason, and **named rather than quietly dropped** because it is the largest mover on the tape with no company-specific driver found.
- **FUTU +9.68%** — declined: its qualifying event day (08-20) moved only +3.02%, failing B's frozen Entry criterion 1, and Friday has no event of its own.
- **PLTR +3.44%** — below floor anyway, but flagged: coverage attributes it to "follow-through" from Q2 earnings dated **2026-08-04**, seventeen days earlier. Stale.
- **EL +6.02%** — clears the floor, but the qualifying earnings event is **2026-08-19** (pre-window). Genuine **in-window analyst actions** exist (Barclays PT→$97 dated 08-21), but an analyst layer on a pre-window earnings base does not mint a fresh four-part identity. Continuation; watchlist annotation only.

**Rejected on the POPULATION RAIL:** CABO (~$0.22B), ZIP (~$0.36B).

**Market caps NOT verified this run:** FMP's `company` profile returned plan-restricted for BMNR, and **`mcp__FMP__quote` is now ACCESS-DENIED entirely at this plan tier** (PROCESS NOTES 3). **BTDR's cap is the genuinely borderline one** — the only figure obtainable is $2.28B dated May 2026 against a materially higher share price since, so its rail eligibility is **asserted on judgment, not measured.** Same treatment the 08-20 file gave AAP and WOLF.

**Strategy-B handoff identity.** Five names carry a qualifying event clearing B's frozen Entry criterion 1 (**≥5% close-to-close ON EVENT DAY**): **BJ 2026-08-21, TSLA 2026-08-21, DNN 2026-08-21, QBTS 2026-08-21, BTDR 2026-08-20.** Deterministic identity is `analysis_type='thesis-construction'` + `strategy='B'` + `ticker` + `qualifying_event_date`, matched **on the FIELDS, never on the key string**. **The dedupe check against `events.queue_events` and `events.decision_log` COULD NOT BE RUN this session (BigQuery down)** — so the check is **OWED**, and it is listed in DEFERRED BIGQUERY WRITES. **No thesis handoff is created today regardless** (B is DO-NOT-ACTIVATE and capital-disabled), so all five are index rows only and nothing can be duplicated by this deferral. No ticker-only deduplication was used anywhere.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

All eleven GICS sector ETFs measured from IBKR daily bars. **Two cleared the ≥1% Layer-1 rail on the downside/upside extremes; one cleared the legacy ≥2% bar in each direction.**

| Sector (ETF) | Close-to-close | Driver | Significance | `legacy_rule_pass` (≥2%) |
|---|---|---|---|---|
| **Utilities (XLU)** | **−2.28%** | **Morgan Stanley coverage-wide PT cuts, 2026-08-21** | **75** — the day's most decision-relevant sector item, and the only sizeable decliner on a risk-on tape | **true** |
| **Materials (XLB)** | **+2.14%** | Broad risk-on + a weaker dollar; no single-name driver identified | **45** — top sector, but no crisp catalyst; recorded, not over-read | **true** |
| **Health Care (XLV)** | **+1.29%** | Recovery of Thursday's −1.87% give-back | **45** — mean-reversion, not new information | false |
| **Cons. Discretionary (XLY)** | **+1.15%** | TSLA +5.14% is a large index weight; flash services PMI 56.8 | **45** — partly a one-name artifact, stated so | false |

**Full sector tape for the record:** XLB +2.14, XLV +1.29, XLY +1.15, XLF +0.93, XLP +0.79, XLC +0.65, XLI +0.27, XLK +0.11, XLRE 0.00, XLE −0.17, **XLU −2.28**. **Top-to-bottom spread 4.42 percentage points against Thursday's 2.14pp** — dispersion more than doubled, and **almost all of it is XLU**: strip utilities and the remaining ten sectors span 2.31pp.

**THE UTILITIES SELLOFF IS THE FINDING, AND ITS INTERNAL SPLIT IS WHY.** A −2.28% utilities move on a **risk-on day with rates barely moving (TLT −0.35%)** is not explained by rates or by beta rotation. The driver is a **Morgan Stanley coverage-wide price-target cut wave dated 2026-08-21** — SRE $108→$104, EIX $69→$65, D $71→$68, NRG $165→$162, CNP $40→$39, ATO $196→$190, AEE $118→$114. The plausible upstream is a Morgan Stanley research note published **2026-08-20** ("*'Capital alone no longer clears a site': data centers' big money era is over*," Fortune, 2026-08-20 08:12 ET) arguing AI data-centre siting now faces political/regulatory friction and 5–7 year interconnection queues, projecting a 38 GW power shortfall 2026–2028 and favouring near-term fixes over the "just build it" narrative. **The chronology is consistent; that this specific note drove every individual PT cut is plausible, not established, and is recorded as such.**

**THE SPLIT IS THE PART THAT MATTERS, AND IT CUTS AGAINST THE OBVIOUS READ.** If this were an AI-power-demand reversal, the merchant/AI-levered names should have led the decline. **They did not:**

| Regulated utilities (hit) | | Merchant / AI-power (not hit) | |
|---|---|---|---|
| AEP | **−3.79%** | **SMR** | **+3.64%** |
| PWR (grid contractor) | −3.49% | CEG | −0.01% |
| EXC | −2.84% | GEV | −0.95% |
| SO | −2.72% | ETN | +0.94% |
| DUK | −2.31% | TLN | −0.80% |
| EIX | −4.11% | NRG | −1.95% |
| SRE | −5.14% | VST | −1.96% |

**This is a broker-driven regulated-utility re-rating, not a repudiation of the AI-power-demand thesis** — the pure-play expression of that thesis (SMR) actually *rose*. Recorded explicitly because the lazy reading ("utilities fell, so the data-centre power trade is breaking") would have been directly wrong, and it bears on a held position (see RISK, GEV).

**Sub-item worth carrying: this also explains the breadth print.** Breadth fell 0.79pp (70.31 → 69.52) on a **+0.41% SPY day** — superficially the "narrowing participation" shape. But equal-weight RSP **beat** SPY by 22bp and 8 of 11 sectors rose, which is the opposite of narrowing. **A ~30-name utilities sector dropping 2–5% is more than enough to push several constituents below their own 200-day SMA while the other ten sectors rise.** The two facts are consistent, not contradictory, and the breadth decline should not be read as deteriorating participation this session.

### 5. Notable commentary

- **Bill Dudley** (former NY Fed president), Bloomberg "The Close," 2026-08-20/21: warned of a **"U.S. stock market bubble."**
- **Scott Bessent** (Treasury Secretary), 2026-08-21: expanded bond buybacks, an "increased focus on fiscal consolidation" coming, and the Iran "economic oblivion" line. *WSJ live blog 2026-08-21.*
- **Erica Klauer** (Science and Technology Partners), Bloomberg Tech 2026-08-21: flagged **"circular financing"** concerns around the Broadcom/Anthropic AI debt structure, noting **>$220B of AI-related corporate debt issued YTD 2026 against ~$20B in 2024.** The Broadcom deal itself (>$60B, potentially ~$100B via SPV, with Blackstone and Apollo in talks) is dated **2026-08-20 20:08 UTC** — at the very edge of the prior window — but the structure detail and the circular-financing critique are in-window.
- **Giovanni Staunovo** (UBS): 12-month gold target **$5,400/oz** on US debt and dollar weakness. *CNBC 2026-08-21.*
- **LPL Research**, 2026-08-21: the week's volatility driven by "fiscal worries, bond market supply crowding, and Federal Reserve credibility worries."
- **Deliberately NOT relied upon.** (a) A "da Vinci 5 cardiac clearance" item resurfaced for ISRG — its own byline date is **2026-01-23**; rejected, and this is the second consecutive session it has had to be rejected. (b) An RTX explanation citing the $22.9B Navy Tomahawk award — self-dated **2026-08-17**, pre-window. (c) A `perplexity.ai/finance/XLU` page stitching together an Iran narrative, a DOE grid emergency and an Nvidia data-centre item with no per-item dating — auto-generated, discarded. (d) An `energynow.com` "DeepSeek utilities selloff" article dated **2025-01-28**, nineteen months stale. (e) Utilities explanations attributing Friday's drop to "rising Treasury yields," which **contradicts our own measurement of TLT −0.35%**; the PT-cut explanation is independently sourced and does not depend on a rates move. (f) A SOFI "earnings beat" narrative recycled from its 2026-07-29 report. (g) An unverified Reuters/Bloomberg item on "Nvidia customers notified of AI-chip price hikes above 15%" — could not be confirmed to an in-window primary source and is **not** reported as fact.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP

Run over the **UNION** of the live IBKR book (`get_account_positions`, read this session) and the 13-tranche position list carried forward from 2026-08-20. **`state.current_positions` was unreachable this run**, so the BigQuery half of the union is the carried-forward list rather than a live read — stated plainly because it is a real, if narrow, degradation.

**Reconciliation status: CLEAN — zero reconciliation-lag positions, and this IS verifiable without BigQuery.** The live connector returns exactly nine names with share counts identical to the 08-20 file's reconciliation line: AMZN 0.3464, CRM 0.2275, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.1550, UBER 0.5156. VOO 21.8139 is the §13 park, not a strategy position. **No name appears in the connector that is absent from the carried-forward book**, which is the exact condition `position_reconciliation_lag` tests. **No alert is owed** — and none could have been raised anyway.

**Mechanical triggers: ZERO.** All 13 tranches are Strategy D, which carries **no** convergence targets and **no** time-based exits by design ("No maximum hold," `strategy/06_strategy_d.md`), so neither mechanical test can fire on this book. This is a structural property of an all-D book, not an absence of checking. `ltcg_date` values are tax markers, not exit triggers.

**Strategy B remains FLAT** (zero open positions), so the KL #12 pairwise-correlation warning is inert (`n_positions >= 2` fails). No `b_pairwise_corr_high` alert owed.

### PER-STRATEGY KILL-TRIGGER SWEEP

**`perf.kill_flags` could not be read this run.** The drawdown refresh was therefore computed **from live marks against the last engine anchor recorded in the 08-20 file** (D `deployed_unit_value` 1.084750613 as of 08-19, denominator `deployed_mv` 610.89). The refresh itself is **unconditional and was performed**, exactly as required — it is the flag table that is stale, not the marks.

| Strategy | Engine anchor | **Refreshed on live 08-21 marks** | Drawdown kill (≥50%) | Runaway (2×, pre-gate) | m2m review | Interim underperf |
|---|---|---|---|---|---|---|
| **D** | 1.084750613 (08-19) | **≈ −2.39%** (deployed MV **$603.64**, unit value ≈ **1.0719** vs peak 1.0981) | **false** | false (needs 2.0) | false | carried FALSE — **could not re-read** |
| **B** | n/a | flat, nothing to re-mark | **false** | false | false | carried FALSE — **could not re-read** |

Deployed MV rose from $602.96 to **$603.64 (+0.11%)** — the book essentially tracked a flat-to-up tape. **No strategy is within an order of magnitude of the −50% drawdown kill; nothing routes to D2.** A/C/E have no `perf.kill_flags` rows (never deployed). **`interim_underperf_warning` is carried forward as FALSE for both from 08-19 and is NOT re-verified this run** — an honest gap, though it is a WARNING-only signal that routes to SL4 monthly, not a kill trigger, so a three-day staleness is low-consequence. No HEAL-RESOLUTION `UPDATE` is asserted either way.

### THESIS-INVALIDATION ASSESSMENT — all 13 tranches

**The headline is an absence, and it is unusually complete: not one of the nine held names has a verified in-window company-specific event.** Every Friday move sits within ±2%. Marks are Friday's IBKR regular-session close against each tranche's **own** per-share cost basis.

**On the cost bases, because the method had to change and it produced a finding.** With `state.current_positions` unreachable, per-tranche cost bases were **derived** from the 08-20 file's stated mark-vs-cost percentages and that session's closes, then **validated against IBKR's `average_price`**. The validation is strong: for all four multi-tranche names the share-weighted blend of the derived tranche costs reproduces IBKR's `average_price` to **under six-thousandths of a dollar** (AMZN −0.0017, GOOGL +0.0051, TSM +0.0008, DIS −0.0037), and RTX / GEV / CRM / UBER reproduce the prior file's percentages **exactly**. **This also resolves an ambiguity the 08-20 file left open:** the TSM tranche mapping is confirmed as `:2026-07-29` → cost 392.90 and `:2026-07-21` → cost 427.85 (the file stated the pair in inconsistent order in two places).

**ISRG is the sole exception, and it is a genuine defect in the prior file.** ISRG is a **single-tranche** position, so there is no blending explanation available. IBKR's `average_price` of **352.4638** implies a 08-20 mark-vs-cost of **+6.25%**, but the 08-20 file recorded **+7.14%** — overstated by ~0.89pp. Since every other name validates to the cent, this is an error in that file's ISRG figure, not a systematic basis difference. **It matters because ISRG was the 08-20 session's single strongest add-candidate case and the "+7.14% above cost" figure was cited in making it.** This file uses the connector figure.

| Position | Fri move | Mark vs cost | Criterion touched by in-window developments? | Status |
|---|---|---|---|---|
| **D:ISRG:2026-07-20** | **+1.16%** | **+7.47%** | Procedure growth, placements, recurring-revenue decoupling, competitor displacement at named large IDNs. **No in-window event of any kind.** The stale "da Vinci 5 cardiac clearance" item resurfaced and was rejected again (2026-01-23 byline) | **UNBREACHED** |
| **D:RTX:2026-04-27** | −1.12% | +18.66% | Airbus damages, powder-metal charge, GTF Advantage EIS, backlog, FY26 FCF, FY27 procurement. No in-window event; the Tomahawk award is 08-17, pre-window | **UNBREACHED** |
| **D:GEV:2026-08-03** | −0.95% | −1.35% | **Total-company organic orders growth YoY** (entry 88%; invalidation <15% for 2 consecutive quarters). **No in-window GEV event; nothing published bearing on orders growth.** See the note below | **UNBREACHED** |
| **D:AMZN:2026-07-30** | −0.57% | **−2.66%** | AWS revenue growth, AWS op-margin, AWS backlog, Anthropic/OpenAI commitments, metric-immutability. No in-window AWS development | **UNBREACHED** |
| **D:AMZN:2026-07-09** | −0.57% | +7.21% | Same criteria | **UNBREACHED** |
| **D:GOOGL:2026-07-26** | +1.22% | +5.18% | Cloud revenue growth, Cloud op-margin, Cloud RPO, adverse structural remedy, metric-immutability. No in-window Cloud development | **UNBREACHED** |
| **D:GOOGL:2026-07-09** | +1.22% | **−4.18%** | Same criteria | **UNBREACHED** |
| **D:TSM:2026-07-29** | +0.71% | +6.63% | GM/revenue growth, N2/A16 ramp and sub-7nm share, **structural AI-capex reset**. No TSM event; the Samsung foundry price story is a competitor item dated 08-19, pre-window | **UNBREACHED** |
| **D:TSM:2026-07-21** | +0.71% | −2.08% | Same criteria | **UNBREACHED** |
| **D:CRM:2026-07-09** | +1.82% | **+30.44%** | Agentforce/Data-360 ARR, cRPO, non-GAAP op margin, FY27 revenue guide. **No CRM information exists** — Q2 FY27 re-confirmed 2026-08-26 AMC from Salesforce's own IR release | **UNBREACHED** |
| **D:DIS:2026-05-07** | +0.43% | −3.18% | SVOD margin, FY26 EPS guide, buyback pace, metric-immutability, FCC escalation. No in-window Disney financial or corporate news | **UNBREACHED** |
| **D:DIS:2026-08-05** | +0.43% | +3.85% | Same criteria | **UNBREACHED** |
| **D:UBER:2026-07-09** | +0.32% | +7.64% | Gross bookings, adj-EBITDA margin, Uber One membership. Q2 beat and Zagreb launch are 08-19, **pre-window** | **UNBREACHED** |

**THE GEV NOTE, because the sector move could easily have been misread into a breach.** GEV's criterion is a **quantitative trend-metric threshold** — total-company organic orders growth YoY, invalidating below 15% for two consecutive quarters against an entry reading of 88%. The utilities sector fell 2.28% on Friday, and a careless read would treat that as pressure on the power-demand demand channel GEV's orders depend on. **It is not, and the internal split proves it:** the decline was concentrated in **regulated** utilities named in a Morgan Stanley PT-cut wave, while the merchant/AI-power expression of the same thesis was flat to higher (SMR +3.64%, CEG −0.01%, ETN +0.94%). GEV itself fell only **0.95%**, less than half XLU. **Nothing published in-window bears on orders growth at all**, and the criterion is a two-consecutive-quarter test whose earliest possible fire is two reporting cycles away. **UNBREACHED, and not close.** The honest qualification: the Morgan Stanley note underlying the wave *does* argue that data-centre siting faces real friction (5–7 year interconnection queues, a 38 GW shortfall) — that is a genuine long-run consideration for this thesis's demand channel, and it is recorded as a **standing watch item**, not as evidence of breach.

**THE AI-CAPEX WATCH ITEM — now in its third session, and the equity leg still has not engaged.** The 08-19 file opened this as a sequence; 08-20 downgraded it; Friday leaves it downgraded. The **narrative** advanced materially — the Broadcom structure is now specified (>$60B, potentially ~$100B via SPV, Blackstone and Apollo in talks), and a named analyst put >$220B of AI-related corporate debt issued YTD against ~$20B in 2024, calling it circular. **But XLK closed +0.11% and TSM rose 0.71%.** The debt-market story keeps compounding while the equity transmission channel that would eventually reach GEV's orders or TSM's criterion 3 has now failed to operate for three consecutive sessions. **The watch stays open and stays weak.** NVDA on 2026-08-26 is the next real test of it.

### WATCHLIST CANDIDATE STATUS

- **MRNA:** **+8.86%** Friday (133.32 → 145.13), the **third consecutive session repricing the same unchanged 08-19 Phase-3 melanoma data** (+177%, −23.55%, +8.86%). No new disclosure. This sharpens rather than settles the mechanism objection recorded at creation: a name that swings ±20% three sessions running on one unchanged datapoint has **no stable post-event anchor** to underwrite convergence against. Candidacy **unchanged** (index-only regardless — router).
- **EL:** **+6.02%** Friday (96.15 → 101.94). Clears the 5% floor, but on a **pre-window** (08-19) earnings base plus in-window analyst actions (Barclays →$97 dated 08-21; Deutsche →$117; Telsey →$108; JPM Buy $112). **No fresh four-part identity minted** — continuation. Window open to 2026-09-02. Annotated.
- **FN −1.84%, KLAR +2.36%, BIDU +1.35%, AMLX −2.52%, ONON +0.40%, TME −0.57%:** no in-window news for any. All unchanged.
- **CVS and DVA:** windows expired 2026-08-19, closed by D2. No further action.
- **Strategy A queue (36 names):** unchanged. A remains DO-NOT-ACTIVATE with NAV $0.00.

---

## ANALYSIS — OPPORTUNITY CHECK

Scoped to roster-active strategies with `review_cadence: reactive` in `strategy/roster.yaml` — **A, B, C, E** (D excluded via `review_cadence: long_horizon`). **Read from `strategy/roster.yaml` on disk this session** (all five `roster_state: adopted`); the router *activation* states are carried forward from 2026-08-20 because `state.current_regime` was unreachable. Those states derive from the `div-*-202607-1` monthly calls effective 2026-08-05 and are not re-scored until M1a/M1b on 2026-09-01, so a three-day carry-forward is faithful.

**Strategy A — DO-NOT-ACTIVATE, NAV $0.00.** No candidate routed. Nothing in-window creates an A-shaped catalyst not already on the 36-name queue.

**Strategy B — DO-NOT-ACTIVATE, NAV $0.00.** **Five names clear B's frozen Entry criterion 1 on a resolved, dated, in-window-or-prior-session public event.** All index-only. Ranked on **mechanism fit rather than magnitude**:

1. **BTDR** (event 2026-08-20, **+8.31%** that day; +9.01% Friday) — **ranked first on process grounds as much as mechanism.** Its qualifying day was 08-20 and **the 08-20 screen missed it**, exactly as that screen missed MRVL's 08-19 qualification. Recording it now is the point. Mechanism fit is genuinely mixed: a Barclays initiation plus real contract news (Malaysia/Norway AI-cloud, ~$4.7B Norway lease) is information, but a 9%-then-8% two-session move on an initiation is the shape of a sentiment extension. **Its market cap is the run's one unmeasured rail input.**
2. **BJ −/+5.61%** (event 2026-08-21) — the cleanest event identity of the five: an unambiguous BMO print, a clear pre-event anchor at 91.30, a large-cap wholesale club, both lines beaten. **But it is B's weakest mechanism class** — the stock rose in the direction the information supports, and a justified re-rating has no reason to converge. Same standing objection already recorded against NDSN, DE, AMLX and MRNA.
3. **TSLA +5.14%** (event 2026-08-21) — a resolved, dated regulatory approval (Nevada, up to 5,000 robotaxis) on the most liquid name in the cohort. Same weakest-class objection as BJ, and more so: a permit expanding a named commercial deployment is about as information-driven as a catalyst gets.
4. **QBTS +8.46%** (event 2026-08-21) — a BMO initiation at Outperform, $35 PT. **The counterweight is the event class itself:** an analyst initiation carries no new company disclosure, which cuts *toward* B's overshoot mechanism, but the 08-20 file declined CRWD partly on an analyst action being the sole driver. Recorded with that tension stated rather than resolved.
5. **DNN +11.46%** (event 2026-08-21) — largest magnitude of the four fresh names and a genuine company-specific milestone (full-scale construction at Phoenix ISR). Ranked last on fit because a construction start against prior approvals is a scheduled de-risking event, and at a ~$2.95B cap it is the least liquid of the cohort.

**Explicitly NOT routed to B, with reasons:** **BABA −8.57%** — the biggest decline on the tape, and it fails criterion 1 on a technicality that is not a technicality: the criterion measures the **event-day** close-to-close, and BABA's event day (08-20) moved **+1.26%**. **SRE −5.14%** — declined on the sector test (see section 3). **CIFR −8.40%, UEC +14.44%, FUTU +9.68%** — no qualifying event. **MRNA, EL, PLTR** — continuations of pre-window events.

**Strategy C — HYBRID ACTIVATE (FOMC-only).** No FOMC in-window; next meeting 2026-09-16; `thesis-FOMC-C-20260908` remains queued. **No candidate — and the observation this file forwarded on Thursday must be RETRACTED, which is the honest outcome of having framed it as a testable claim.** Thursday's file recorded a divergence in which the priced distribution was "failing to respond to both the Fed's stated distribution *and* to strong incoming data," on the evidence that September hike odds sat at 32.7%, roughly flat, after the hawkish July minutes and three strong macro prints. **Friday's flash PMI landed at a 52-month high and the odds moved to 39.0%** — up 6.3pp, and up ~6.7pp on the week. **The market did respond; it was simply slower than one session.** That removes the specific input C's criterion has been missing across four NO-GO drains, and the two-leg divergence claim does not survive contact with Friday's data. **Forwarded to the `thesis-FOMC-C-20260908` drain as a RETRACTION of the 08-20 note, not as supporting evidence.** Recording the reversal is worth more than the original observation was.

**Strategy E — ACTIVATE, fully funded; execution-feasibility-deferred (ETF-substitution required at this book size).** E remains the only strategy with both an ACTIVATE router and deployable capital.

**No E candidate is routed, and the binding reason is unchanged and structural:** Rev 45's frozen Entry criterion 3 requires a **≥95th-percentile** trailing spread anchor, and no single session can move a trailing percentile. That is a measurement fact, not a judgment.

**But a materially better-formed E archetype appeared than anything forwarded in the last two weeks, and it is routed to M2 as ideation evidence.** The Morgan Stanley wave split the **Utilities GICS sector against itself** on one dated catalyst: regulated names fell (AEP −3.79%, SRE −5.14%, EIX −4.11%, EXC −2.84%, SO −2.72%, DUK −2.31%) while merchant/AI-levered names in the *same sector* did not (SMR +3.64%, CEG −0.01%, VST −1.96%, NRG −1.95%) — a **~5–9pp intra-sector divergence with an identifiable, dateable catalyst and a natural convergence trigger** (whether the siting-friction thesis is borne out in the next orders/interconnection datapoints). **This is a same-sector, plausibly same-6-digit-GICS-group divergence, which is precisely what E wants and what the previously-forwarded steel item was not** (STLD/NUE/CLF vs Canadian ASTL is a cross-border policy trade). Carried alongside the still-open steel, managed-care-vs-pharma and NVDA-vs-AVGO/AMD items. **M2 owns pair construction, the same-group test and the 252-day correlation machinery, none of which D1 can supply** — this is a note, not a queue item.

---

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only — Rev 40)

**Scope:** every open A/B/D position. **A = 0. B = 0. D = 13 tranches across 9 names. 13 evaluated.** Marks are Friday's IBKR close against each tranche's own per-share cost basis (never a name-level blend), derived and validated as described in the RISK section above.

**RESULT: 0 flagged. 0 declined at the HARD GATE. 13 declined. Tenth consecutive all-decline session — and unlike the last three, today produced NO genuine trigger, which is a different and simpler reason.**

**THE BINDING CONSTRAINT REMAINS THE ROUTER — but it did not have to do any work this session.** D has been DO-NOT-ACTIVATE since 2026-08-05; a deactivated strategy takes no new entries and an add deploys new capital by construction. **On 08-20 that router was the *only* thing standing between three defensible cases and a flag.** Friday it is redundant: **trigger (a) requires adverse price action, and the book had almost none.** Seven of nine names rose; the two that fell (RTX −1.12%, GEV −0.95%, AMZN −0.57%) fell by less than a percent and a half on a day the index rose 0.41%. There is no dip to add into. **Saying the streak broke on merit rather than on the router this session is the accurate description, and it is the opposite of last session's.**

**HARD GATE — all 13 pass.** Every tranche's original at-entry invalidation criteria remain UNBREACHED, so nothing routes to exit and `n_declined_hard_gate = 0`.

**`invalidation_criteria_evaluable` — the one field this run genuinely CANNOT compute, and it is not fudged.** The field is defined against `state.current_positions.invalidation_status` and its `$.status` key, with the mandated `COALESCE(JSON_VALUE(invalidation_status,'$.status'), '') = 'NOT_DISCRETELY_RECORDED_AT_ENTRY'` wrap. **That column is in BigQuery and BigQuery is unreachable.** The 08-20 file measured all 13 as `TRUE` (populated `invalidation_status`, no `$.status` key on any of them), and nothing this session could have changed that — but it was **not re-measured**, so it is carried forward as `TRUE` **with an explicit `carried_forward` marker** in the deferred record rather than asserted as a fresh measurement. Emitting an unverified TRUE as though measured would be the same class of error the 2026-08-17 NULL-safety note exists to prevent.

**NO TRIGGER-(a) OR (b) FIRES. The thirteen declines:**

- **D:ISRG:2026-07-20** (+7.47% vs cost, **+1.16%** on the session): **last session's strongest case is simply gone.** ISRG rose, recovering a fifth of Thursday's −5.84%, with no in-window event in either direction. A position that rises is not a dip. `none`. **Carrying the correction:** the 08-20 file cited "+7.14% above cost" in making that case; the correct figure was +6.25%, and it is +7.47% now.
- **D:RTX:2026-04-27** (+18.66%, −1.12%): a third consecutive decline, but a *small* one on a rising tape and again with no company event. The 08-20 file already downgraded this case once on the finding that the whole defense complex was falling; Friday's −1.12% against SPY +0.41% is ~1.5pp of underperformance, which is real but thin, and three sessions of drift without a catalyst is closer to sector rotation than to a dip against an intact thesis. **Not flagged** — and flagging it would be reaching for a trigger on a day that did not produce one. `none`.
- **D:GEV:2026-08-03** (−1.35%, −0.95%): the only name with a sector story, and **the sector story is the reason to decline, not to flag.** GEV fell less than half of XLU on a broker re-rating aimed at regulated utilities; trigger (a) wants adverse price action on the *position*, not sector drag it partially escaped. `none`.
- **D:AMZN:2026-07-30** (**−2.66%** below cost, −0.57%): the deepest-underwater tranche after GOOGL, but a −0.57% session is not adverse *movement*. A standing unrealised loss is not a trigger. `none`. **D:AMZN:2026-07-09** (+7.21%): trigger would be carried once at name level per the convention; there is none to carry. `none`.
- **D:GOOGL:2026-07-09** (**−4.18%**, the deepest in the book) and **D:GOOGL:2026-07-26** (+5.18%): GOOGL **rose 1.22%**, outperforming SPY. Not a dip. `none` ×2.
- **D:TSM:2026-07-29** (+6.63%) and **D:TSM:2026-07-21** (−2.08%): TSM **rose 0.71%** and its complex was flat-to-up. `none` ×2.
- **D:CRM:2026-07-09** (+30.44%, +1.82%): rose, and the standing objection binds hardest of all now — **Q2 FY27 is 2026-08-26 AMC, three days out and company-confirmed.** Adding into a print inside three days is buying event risk and calling it conviction. `none`.
- **D:DIS ×2** (+0.43%): rose. `none` ×2.
- **D:UBER:2026-07-09** (+7.64%, +0.32%): rose, no criterion-bearing news. `none`.

**On the streak.** Ten consecutive all-decline sessions. **The streak measures the router's state in nine of them and the tape's in this one** — and the distinction is worth preserving in the record, because a reader counting only the streak length would infer a book being starved of opportunity, when Friday's actual reason is that a risk-on session gave a mostly-profitable book nothing to buy. **Durable log DEFERRED** — `sp_log_decision` is unreachable; the full `fields` payload is specified in DEFERRED BIGQUERY WRITES.

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review is recommended. Default-NO holds — but `growth_momentum` has now moved from "genuinely two-sided" to "one-sided with a weakening dissent," and the reason to still decline has correspondingly changed from *the evidence is split* to *the calendar makes waiting strictly better.***

**`growth_momentum` (currently `decelerating`) — the case for an upgrade is now the strongest this axis has seen, and it should be stated at full strength before it is declined.** Across the last two sessions: Philadelphia Fed manufacturing **47.4 vs ~25** (highest since April 2021); initial claims **206K vs ~210K**; Conference Board LEI **+0.2% m/m with its six-month growth rate positive for the first time in over four years**; and now the **S&P Global flash composite at 56.0 vs ~54.0, a 52-month high, with services at 56.8, a 20-month high.** That is four independent series pointing the same way. **The consumer dissent that carried the "two-sided" reading on 08-20 also weakened:** Walmart's +2.6% comps and Advance Auto's "constrained" commentary still stand, but **BJ's beat both lines on 2026-08-21** and the flash **services** print is itself a consumption-heavy read. The dissent is now one large retailer's forward guide against four macro series.

**Why this still does not clear the bar — and the reason is a calendar fact, not a hedge.** M1a re-scores on **2026-09-01**, six trading days away. **Two events that bear directly on this axis land BEFORE that: NVDA earnings on 2026-08-26 and the Jackson Hole symposium 2026-08-27→29, where Chair Warsh gives his first address.** Firing an out-of-cycle router review *now* would adjudicate the axis on an evidence set that is guaranteed to be superseded within four trading days, on a question M1a will answer properly on a full monthly set two days after that. **That is motion, not information** — and unlike the 08-20 formulation ("one more month of data will resolve it"), this is a concrete, dated reason. **Flagged forward as the TOP item for M1a 2026-09-01, upgraded from "closest call in weeks" to "the evidence has stopped being balanced."**

**`policy_stance` (currently `hawkish`) — CONFIRMED and strengthened, on the cleanest evidence yet.** The 30-year touched a near-two-decade high (~5.34%) and settled ~5.27%; the 10-year closed ~4.734%, its highest since January 2025; **and September hike odds rose 32.7% → 39.0% on the flash PMI.** The axis value does not change. **What DOES change is the Strategy-C observation built on top of it, which is retracted above** — the market's non-response to hawkish inputs was the whole claim, and Friday it responded.

**`shock_overlay` (currently `acute`) — CONFIRMED, and the disconnect this file has flagged twice WIDENED.** Brent posted a sixth consecutive gain to ~$94.39 on "Economic D-Day" rhetoric and record-for-the-date US gasoline, while **VIX fell 5.50% to 15.13**, below both its 50- and 200-day. `acute` was already the scored state so there is nothing to flip, but **the gap between the geopolitical axis and the tape's pricing of it is now the widest it has been in this sequence** — and on 08-20 the tape had partially responded, so this is a reversal of that narrowing, not a continuation.

**`risk_sentiment` (currently `neutral`) — unchanged, and comfortably so.** VIX 15.13 and falling, inside a LOW regime and below both moving averages; breadth 69.52, far above any stress threshold; **credit is not merely quiet but actively tight — HY OAS 2.73% (as of 2026-08-19) against the ~2.85 base this file has been tracking**, i.e. spreads have *narrowed*; HYG +0.06%. All consistent with `neutral`.

**`inflation_trend` (currently `stable`) — no in-window CPI or PPI, so no present evidence about it.** Recorded as accumulating **forward** risk rather than flagged: six straight sessions of oil gains to ~$94, record-for-the-date gasoline, gold's best month since 1999, and a services PMI at a 20-month high are four channels that would each transmit to prices with a lag. **Not flagged, because this axis is about realised prints and none occurred** — but this is the second consecutive session of one-directional forward pressure, and it is named so a later reader can see when the accumulation started.

---

## EQUITY-BREADTH OBSERVATION

**69.52% of S&P 500 constituents closed above their own 200-day SMA on 2026-08-21.** **MEASURED and SOURCE-DATED**; the post-close-inference fallback was not needed and was not used. **The `events.regime_events` write is DEFERRED** (BigQuery unreachable) and is specified in full below — this is a value that was successfully obtained and could not be stored, which is a materially better position than the reverse.

- **THREE independent sources agree exactly, with zero percentage-point dispersion** — the strongest corroboration this key has had.
  - **Barchart `$S5TH`** (the source used): verbatim *"Quote Overview for Fri, Aug 21st, 2026"*, value **69.52**, change **−0.79 (−1.12%)**, **"Previous Close 70.31."** Fetched **twice with two different cache-busters** (`?cb=20260823a`, `?cb=20260823b`) returning identical content, identical as-of date and identical previous close.
  - **EODData `$S5TH`**: EOD table row **"21 Aug 26 | Open 70.31 | High 71.11 | Low 69.52 | Close 69.52"**, and its prior four rows reproduce this system's stored history exactly (08-20 70.31, 08-19 72.11, 08-18 68.12, 08-17 68.58).
  - **MacroMicro** (the mandated primary): **still unreachable by direct extract** — two attempts, two cache-busters, both `{"error":"Failed to fetch url"}`. However a search-index snippet surfaced its own page content: *"US - S&P 500 Stocks above 200-Day Average. 2026-08-21. 69.52 %. 70.31 %."* — same date, same value, same prior. **Treated as corroborating, not as a clean primary fetch**, since it is a snippet rather than a rendered page.
- **The Previous-Close self-validation passes decisively.** Barchart and EODData both carry **70.31** as the prior session — an exact match to this system's stored 08-20 value. A stale cache could not carry the correct immediately-preceding settled figure.
- **The `Low == Close` unsettled tell fired and is affirmatively resolved.** EODData's row shows Low 69.52 == Close 69.52. But the tell requires **both** halves, and here the second half is absent: Barchart's independently-dated, post-close *"Quote Overview for Fri, Aug 21st, 2026"* page shows the identical Day Low = Close = 69.52. **Two independent sources agreeing that the session closed at its low is evidence of a genuine down-into-the-close print, not of an unsettled bar.** EODData was also **not** stale this run — the first time in four sessions it has carried the current session at all, which is a reversal of the widening-staleness trend the 08-20 file recorded.
- **MacroMicro's direct-fetch failure is now at four consecutive runs** (five attempts on 08-20, two here). **This is a source-availability regression, not a one-off**, and the 08-20 file already asked that it be acted on rather than absorbed. Repeating that request here, and noting that the mandated primary has now been unavailable for the entire period during which it has been the mandated primary.

**Direction — the give-back continued, but at a quarter of the prior session's pace and for a reason that is NOT deteriorating participation.** Series: 08-13 73.16 → 08-14 72.76 → 08-17 68.58 → 08-18 68.12 → 08-19 72.11 → 08-20 70.31 → **08-21 69.52 (−0.79pp)**. A −0.79pp breadth decline on a **+0.41% SPY** day superficially matches the narrowing-leadership shape. **It does not survive the cross-checks:** equal-weight RSP **outperformed** SPY by 22bp and 8 of 11 sectors rose. **The arithmetic is fully accounted for by utilities** — a ~30-name sector falling 2–5% will push constituents below their own 200-day SMA regardless of what the other ten sectors do (see section 4). **Read as sector-specific attrition, not broad participation loss.**

Threshold classification (HEALTHY/WEAK) is D2a's to apply on `TECHNICAL_SIGNAL` and is deliberately not written here. For D2a: **69.52 ≫ 50**, `breadth_measurement_age_days = 0` at Friday's session, a genuine same-session measurement — **but note the row is not yet written**, so D2a's `ORDER BY as_of_date DESC LIMIT 1` will still return the 08-20 row until the deferred write lands.

---

## PARK ALLOCATION CALL

- **`vehicle`: VOO — KEEP.** Today's park vehicle is **VOO, confirmed directly from the IBKR connector** (21.8139 shares, $15,374 market value, ~96% of the $15,972 net liquidation) rather than from `state.park_policy_current`, which was unreachable. The menu allowlist was read from `PARK_ROUTER_DESIGN.md` on disk (CASH, SGOV, GOVT, IEF, TLT, LQD, MUB, HYG, PFF, AOR, VOO, VTI).
- **`conviction`: MEDIUM — `conviction_pct` 58** (up from 55 on 08-20).
- **`rationale`:** **The symmetry rule that cut conviction on Thursday raises it today, and applying it in only one direction would have been the tell.** Thursday cut 60 → 55 on breadth giving back 45% of its recovery and VIX rising 7.52%. **Friday reversed the vol leg outright — VIX −5.50% to 15.13, back under both its 50-day (16.98) and 200-day (18.50) — and the breadth decline slowed to −0.79pp from −1.80pp**, with the residual fully attributable to one sector rather than to narrowing leadership. Add the strongest growth print in four years (flash composite 56.0), participation that *beat* cap-weight (RSP +22bp over SPY), and 8 of 11 sectors green. **It does not go back to 60, and the two reasons are specific:** the long end deteriorated to a near-two-decade high on the 30-year with the 10-year at its highest close since January 2025, and **gold's +1.95% day inside its best month since 1999 is a fiscal-debasement signal that a rising equity tape does not refute.** Those are new risks that were not present when 60 was last set. **Why VOO beats the runner-up, VTI, and VTI was genuinely assessed:** VTI actually *won* on direction this session (+0.44% vs VOO +0.39%, with IWM +0.77% beating SPY as small caps participated) — **the honest statement is that the direction leg went to VTI and VOO wins on cost alone**, since the park's entire ~$15.4k sits in 21.8139 VOO shares and rotating pays a full round trip on the whole position for a few basis points of weight difference. That is a weaker case for VOO than Thursday's, when VTI lost on both legs, and it is recorded as weaker rather than restated as if unchanged. **The de-risk tier again had nothing to offer, for the third consecutive session:** TLT −0.35%, IEF −0.19%, GOVT −0.13%, LQD −0.13% all fell while equities rose. Rotating into duration on a day the 30-year printed 5.34% would have bought correlated loss, not protection.
- **`invalidation` (SYMMETRIC EVIDENTIARY STANDARD):** a de-risk out of VOO becomes the better call if **ANY ONE** holds — stated as a **disjunction at narrative bar**, matching the narrative bar on which the 2026-08-03 re-risk into VOO was justified. **(a)** the give-back resumes at pace — % above 200-day rolls under ~65 and keeps falling *while SPY holds up*, i.e. genuinely narrowing leadership rather than one sector's attrition; **(b)** Hormuz converts from rhetoric to a supply interruption the tape prices — sustained Brent through ~$100 *with equity vol responding*; **(c)** the AI-capex story converts into a credit event — HY OAS widening materially off its current 2.73% *on a live reading* — or a hyperscaler capex guide-down, **with NVDA on 2026-08-26 the nearest real test**; **(d)** the long end breaks disorderly — a 30-year sustained through ~5.50% with equities finally responding, replacing 08-20's consumer-deterioration clause, **which is retired because Friday's evidence went against it** (BJ beat both lines and services PMI hit a 20-month high). **No conjunctive numeric checklist is set**, for the reason recorded on 08-18: an exit bar harder to clear than the entry bar quietly removes next-session reversibility, the only compensating control left after the 2026-07-26 directive retired the anti-churn rails.
- **`theater_check`:** The conviction moved **up** on the same metrics that moved it down on Thursday — had VIX risen again and breadth given back another 1.8pp, this would have gone to 50, not held at 55. **The runner-up assessment is recorded as having WEAKENED the incumbent's case** (VTI won the direction leg; VOO survives on cost alone), which is the opposite of how a defence of a held position reads. The two facts arguing for a de-risk — a near-two-decade-high 30-year and gold's best month since 1999 — are stated as the reason conviction did not return to 60, not buried after the supporting facts. **And the honest weakness of this call is that it is a KEEP made on a Sunday about a Friday tape, with NVDA earnings and Jackson Hole both landing before the next re-evaluation would normally matter** — reversibility is doing real work here, and it is named rather than assumed.
- **`status`: BOUND** — a KEEP is trivially BOUND, and D2's PARK ALLOCATION CONVERSION no-ops when the called vehicle equals the current policy vehicle. **`direction`: keep.** **The connectors-down HOLD branch was considered and deliberately not taken:** it exists for the evidence-ungatherable case, and the evidence here was substantially gatherable (VIX, the full tape and the de-risk tier from IBKR; yields, oil, gold and HY OAS from research; the current vehicle from the connector itself). The only unavailable inputs were `state.park_signal_daily` — which the spec designates as a briefing the AI may weigh or override, never a mechanical input — and the FUNDAMENTAL_AXIS scores, carried forward as degraded mode authorises. **Nothing turns on the distinction in any case, because a KEEP converts to a no-op under either status.** The `sp_log_decision` write and the `ops.heartbeat` marker are both DEFERRED.

---

## RECOMMENDED ACTIONS

- **Exits triggered:** none. Zero mechanical triggers (Strategy D carries no convergence targets or time exits by design); zero thesis-invalidation criteria breached across all 13 open tranches; no in-window company event on any of the nine held names.
- **New entry candidates:** none routed. Strategy B is DO-NOT-ACTIVATE with NAV $0.00; Strategy E is ACTIVATE and funded but cannot clear Rev 45's ≥95th-percentile trailing spread anchor on one session.
- **Add candidates:** none. **No trigger fired** — seven of nine names rose on a risk-on session; there was no dip to add into. Distinct from the last three sessions, which were declined on the router despite genuine triggers.
- **Watchlist updates:**
  1. **Add BTDR** to the Strategy B new-entry index — +8.31% on 2026-08-20, **missed by that session's screen and recorded now**; index-only.
  2. **Add BJ** — +5.61% on the 2026-08-21 Q2 FY27 beat; the cleanest event identity of the cohort; index-only.
  3. **Add TSLA** — +5.14% on the 2026-08-21 Nevada robotaxi approval; index-only.
  4. **Add QBTS** — +8.46% on the 2026-08-21 BMO Outperform initiation; index-only.
  5. **Add DNN** — +11.46% on the 2026-08-21 Phoenix ISR construction start; index-only.
  6. **Annotate MRNA** — +8.86%, a third consecutive session repricing the same unchanged 08-19 data; no disposition change.
  7. **Annotate EL** — +6.02% on a pre-window earnings base plus in-window analyst actions; continuation, no fresh identity; no disposition change.
- **Router reviews recommended:** none. `growth_momentum` is flagged forward as the **top** item for M1a 2026-09-01, upgraded to "the evidence has stopped being balanced"; `policy_stance`, `shock_overlay` and `risk_sentiment` confirmed at their existing values.

```yaml d1_actions
- action: watchlist
  ticker: BTDR
  strategy: B
  qualifying_event_date: 2026-08-20
  source_research_screen_id: DEFERRED-bigquery-unreachable
  detail: ADD to Strategy B new-entry index — qualifying move is +8.31% close-to-close on 2026-08-20 (9.63 -> 10.43, IBKR RTH daily bars) on the Barclays Overweight initiation ($15 PT) alongside Malaysia/Norway AI-cloud agreements (~$4.7B Norway lease) and a Q2 EPS beat; Friday 2026-08-21's +9.01% (10.43 -> 11.37) is a SECOND-DAY CONTINUATION and is not the qualifying move; the 2026-08-20 D1 screen MISSED this name and it is recorded now rather than absorbed, the same defect class as MRVL on 2026-08-19; mechanism fit mixed (real contract information vs a two-session extension on an initiation); MARKET CAP UNVERIFIED — only $2.28B dated May 2026 obtainable against a materially higher price since, so population-rail eligibility is asserted on judgment not measured; index-only, no thesis construction routed (B router DO-NOT-ACTIVATE and B NAV 0.00)
- action: watchlist
  ticker: BJ
  strategy: B
  qualifying_event_date: 2026-08-21
  source_research_screen_id: DEFERRED-bigquery-unreachable
  detail: ADD to Strategy B new-entry index — +5.61% close-to-close (91.30 -> 96.42, IBKR RTH daily bars, measured independently by this session) on the Q2 FY27 print released 2026-08-21 before the open; EPS 1.36 vs ~1.16-1.17 BEAT and revenue 6.09B vs ~5.97B BEAT; the only clean in-window earnings event of the window with an unambiguous pre-event anchor at 91.30; ranked SECOND on mechanism fit and recorded as B's WEAKEST mechanism class (the stock rose in the direction the information supports, so a justified re-rating has no reason to converge — the same standing objection already recorded against NDSN, DE, AMLX and MRNA); index-only, same router/capital reason as BTDR
- action: watchlist
  ticker: TSLA
  strategy: B
  qualifying_event_date: 2026-08-21
  source_research_screen_id: DEFERRED-bigquery-unreachable
  detail: ADD to Strategy B new-entry index — +5.14% close-to-close (345.13 -> 362.86) on the 2026-08-21 Nevada regulatory approval clearing up to 5,000 driverless robotaxis in Las Vegas (largest share of 8,000 authorized region-wide), with an EU Semi debut confirmed the same day; a resolved, dated regulatory approval on a ~$1.43T name, the most liquid of the cohort; ranked THIRD on fit — same weakest-mechanism-class objection as BJ and more so, since a permit expanding a named commercial deployment is about as information-driven as a catalyst gets; index-only, same router/capital reason as BTDR
- action: watchlist
  ticker: QBTS
  strategy: B
  qualifying_event_date: 2026-08-21
  source_research_screen_id: DEFERRED-bigquery-unreachable
  detail: ADD to Strategy B new-entry index — +8.46% close-to-close (18.80 -> 20.39) on BMO Capital initiating D-Wave at Outperform with a $35 price target on 2026-08-21; QBTS is the direct subject of the initiation whereas RGTI (+11.49%) and IONQ (+8.02%) moved on a third party's event and are recorded as a group item only; mechanism tension recorded rather than resolved — an analyst initiation carries no new company disclosure, which cuts TOWARD B's overshoot mechanism, but the 2026-08-20 file declined CRWD partly on an analyst action being the sole driver; ~$5.3B cap; index-only, same router/capital reason as BTDR
- action: watchlist
  ticker: DNN
  strategy: B
  qualifying_event_date: 2026-08-21
  source_research_screen_id: DEFERRED-bigquery-unreachable
  detail: ADD to Strategy B new-entry index — +11.46% close-to-close (3.14 -> 3.50) on the 2026-08-21 shift to full-scale construction at the Phoenix ISR uranium mine (Wheeler River, Saskatchewan) following environmental and construction approvals; largest magnitude of the four fresh 2026-08-21 names and a genuine company-specific milestone; ranked LAST on fit because a construction start against previously granted approvals is a scheduled de-risking event and at ~$2.95B this is the least liquid name in the cohort; note UEC +14.44% moved with the same uranium-sector strength but has NO company-specific event and is not routed; index-only, same router/capital reason as BTDR
- action: watchlist
  ticker: MRNA
  strategy: B
  qualifying_event_date: 2026-08-19
  source_research_screen_id: DEFERRED-bigquery-unreachable
  detail: ANNOTATE the existing 2026-08-19 row — MRNA rose +8.86% close-to-close (133.32 -> 145.13) on 2026-08-21, the THIRD consecutive session repricing the same unchanged 2026-08-19 Phase-3 melanoma readout (+177% on 08-19, -23.55% on 08-20, +8.86% on 08-21) with no new disclosure, trial detail, offering or index action; coverage explicitly describes it as repricing unchanged data, so this is STALE ATTRIBUTION for any fresh-event purpose; the three-session whipsaw SHARPENS the mechanism objection recorded at row creation — a name swinging +-20% three sessions running on one unchanged datapoint has no stable post-event anchor to underwrite convergence against; CONTINUATION of the 2026-08-19 event, no fresh B identity minted, candidacy unchanged, index-only
- action: watchlist
  ticker: EL
  strategy: B
  qualifying_event_date: 2026-08-19
  source_research_screen_id: DEFERRED-bigquery-unreachable
  detail: ANNOTATE the existing 2026-08-19 row — EL rose +6.02% close-to-close (96.15 -> 101.94) on 2026-08-21, clearing B's 5% floor on MAGNITUDE but on a PRE-WINDOW earnings base (FQ4 FY26 beat, 2026-08-19); genuine in-window analyst actions exist (Barclays PT to 97 dated 2026-08-21; Deutsche Bank 117, Telsey 108, JPMorgan Buy 112 dated 2026-08-20) but an analyst layer on a pre-window earnings base does not mint a fresh four-part identity; CONTINUATION, no new B identity, candidacy unchanged, entry window open to 2026-09-02, index-only
```

---

## DEFERRED BIGQUERY WRITES

**Every item below was computed, verified and is ready to write; the connector was unreachable.** Listed so OPS2's catch-up, the next clean D1, or an operator replay can land them without re-deriving anything. **A calendar event `[Claude] ATTENTION — RE-AUTH BigQuery connector` carries this same list.**

1. **`ops.run_log`** — D1 `started` and `completed` rows for `run_date = 2026-08-23`, plus the `sp_routine_end` terminal call. **The same-day double-run guard was also not run** (see the banner).
2. **`events.decision_log` — `entry_type='research-screen'`, `screen='single-name-move'`, run date 2026-08-23.** `surfaced_count = 11` written-up items; the five B-qualifying identities (BJ/TSLA/DNN/QBTS event-day 2026-08-21, BTDR event-day 2026-08-20); the ≥5% legacy-rule cohort and every declined ≥5% item with its reason (MRNA stale, CIFR no-event, UEC no-event, FUTU below-floor-on-event-day, SRE sector-test, BABA fails-criterion-1-on-event-day); `below_spec_floor` items (the utilities complex, F, PATH, NU, INTC, AAL, SMCI); and a `measurement_integrity` note recording the recurrence of the parallel-batch shift defect (PROCESS NOTES 1).
3. **`events.decision_log` — `entry_type='research-screen'`, `screen='sector-move'`, run date 2026-08-23.** XLU −2.28% (conviction 75, `legacy_rule_pass=true`), XLB +2.14% (45, true), XLV +1.29% (45, false), XLY +1.15% (45, false); full eleven-sector tape; spread 4.4213pp; the regulated-vs-merchant split table and its bearing on GEV.
4. **`events.decision_log` — `entry_type='add-candidate-review'`, run date 2026-08-23.** `n_evaluated = 13`, `n_flagged = 0`, `n_declined_hard_gate = 0`; one `positions` object per tranche with `ticker`, `strategy='D'`, `mark_vs_cost_pct` (the thirteen figures in the RISK table), `trigger_type='none'` for all thirteen, `disposition='declined'` for all thirteen, the verbatim one-sentence reason, and **`invalidation_criteria_evaluable = true` MARKED `carried_forward` from 2026-08-20, NOT re-measured** (the source column is in BigQuery). `body_md` carries the streak-reason distinction (declined on the tape, not the router) and the ISRG cost-basis correction.
5. **`events.regime_events`** — `INSERT (as_of_date='2026-08-21', scope='TECHNICAL_INPUT', key='EQUITY_BREADTH_PCT', value='Barchart $S5TH', numeric_value=69.52, rationale='https://www.barchart.com/stocks/quotes/$S5TH — "Quote Overview for Fri, Aug 21st, 2026", 69.52 −0.79 (−1.12%), Previous Close 70.31; corroborated exactly by EODData $S5TH EOD row "21 Aug 26 ... Close 69.52" and by a MacroMicro search-index snippet "2026-08-21. 69.52 %. 70.31 %."; MacroMicro direct extract unreachable for a 4th consecutive run; two cache-busters agreed; Previous-Close self-validation matched the stored 08-20 value of 70.31 exactly', source_review_ref='D1 2026-08-23 EQUITY-BREADTH OBSERVATION')`. **Idempotent on `(as_of_date, scope, key)`.** Do **not** write to `TECHNICAL_SIGNAL` — that scope is D2a's.
6. **`events.decision_log` — `entry_type='park-allocation'`, run date 2026-08-23.** `fields = {vehicle:'VOO', conviction:'MEDIUM', conviction_pct:58, direction:'keep', status:'BOUND', readings:{vix_close:15.13, vix_chg_pct:-5.4966, spy_chg_pct:+0.4091, voo_chg_pct:+0.3852, vti_chg_pct:+0.4408, rsp_less_spy_bp:+22.19, breadth_pct:69.52, hy_oas:2.73, hy_oas_as_of:'2026-08-19', brent:94.39, us30y:5.27, us10y:4.734, gld_chg_pct:+1.9507, tlt_chg_pct:-0.3522}}`. **`readings` carries no `state.park_signal_daily` or FUNDAMENTAL_AXIS values — both unreachable; the axis values used are carried forward from 2026-08-20.**
7. **`ops.heartbeat`** — `INSERT (source='loop:park_allocator', note='VOO call, status=BOUND')`.
8. **`events.queue_events` / `events.decision_log` DEDUPE CHECK — OWED, not merely deferred.** The five B four-part identities were **not** checked against open and terminal queue history or against `events.decision_log`. **No handoff was created, so nothing can have been duplicated** — but the check must be run before any of the five is ever converted.
9. **`ops.web_calls`** — the batched per-call `INSERT` for this run (six sub-agents plus this session; providers `tavily`, `anthropic`, `fmp`, `hf`) could not be written. **This run's external spend is therefore invisible to `state.web_spend_month` and `state.web_duplicate_targets`.**
10. **An `ops.alerts` info row or `events.queue_events` item for the FMP plan-tier regression** described in PROCESS NOTES 3 — owning surface is the task plan's PARK ALLOCATION evidence list and D2a's FMP-dependent steps.

---

### APPENDED BY THE D2a SLOT — 2026-08-23 16:45 MT — **D2a HALTED, NOT DEGRADED**

*This subsection is written by the D2a routine, not by D1. It lives here because this file is the day's shared outage record (`ops/RUNBOOK.md` §26 triage: "confirm a same-day DEGRADED-MODE run in `Daily.md`") and because D2, which fires at 17:15 MT into the same outage, reads this file.*

**Status: the Google-Cloud-BigQuery MCP connector is not merely token-expired in the D2a session — its tools are not exposed at all** (the session harness withheld the server's entire tool surface pending re-authorization). That is a strictly stronger failure than the one D1 diagnosed at 16:15 MT, and it makes the sanctioned pre-flight liveness read (`SELECT * FROM state.trading_day_today`) and the `DIAGNOSE-BY-PROBE` probe pair unexecutable rather than merely failing. Auth-class ⇒ **non-waitable**; the retry ladder was correctly not entered. IBKR, Calendar and FMP are live and were exercised.

**Branch taken: HALT, per `Claude_Task_Plan.md` Observability → "BigQuery unreachable" — "D2/D3 require canonical state → HALT cleanly (never run on missing/stale state; craft no orders)."** D2a is an order-crafting, canonical-state routine, so DEGRADED MODE (D1's branch) does **not** apply to it. Consequently: **no `ops.run_log` row was written (not even `started`), no order was crafted, no `events.*` row was written, and no `ops.alerts` row was raised** — the alert sink is itself down. The SAME-DAY DOUBLE-RUN GUARD could not be run either (it is an `ops.run_log` query); substitute evidence that no D2a completed today is the absence of any D2a-attributable commit on `origin/main` for 2026-08-23.

**No duplicate calendar event was created.** D1 already created `[Claude] ATTENTION — RE-AUTH BigQuery connector` at 22:11 UTC for this same incident; per the Observability INCIDENT INHERITANCE rule ("one incident, one alert thread"; raise anew only on material information) the D2a blast-radius escalation was **appended to that existing event's description** instead.

#### What the halt actually cost today — measured, not assumed

**Nothing was crafted, and nothing needed to be crafted.** Read live from IBKR at 2026-08-23 22:45 UTC:

- `get_account_orders` → **`[]`** (no live/working order). `get_order_instructions` → **`[]`** (no saved instruction). So the staged-order registry's daily re-craft had nothing at the broker to re-craft or supersede, the stale-instruction GC had nothing to `delete_order_instruction`, and no owner confirm-tap is outstanding. *Caveat: `state.open_orders` could not be read, so if the registry believes a row is still `pending`, that divergence is invisible from here and must be adjudicated on replay.*
- **Park sweep/cover: both thresholds miss, so §13.E would have been a no-op even on a healthy run.** `settled_cash = −$0.20`; no filled-but-unsettled paired SELL exists at the broker (the most recent SELL is 2026-08-18, long settled), so `bridge_adjusted_settled_cash = −$0.20` as well. Sweep needs `free_cash ≥ +$25` → **no**. Cover needs `bridge_adjusted_settled_cash ≤ −$5` → **no**; −$0.20 sits inside the documented $0…−$5 leave-on-margin band. No `get_price_snapshot` was requested for the park vehicle, since no craft was in prospect.
- **Fills: nothing new.** `get_account_trades(DAYS_7)` returns exactly two rows, both older than the last D2a slot: `00012978.6a85bca8.01.01` VOO **BUY** 0.0665 @ 708.27, 2026-08-19T13:30:05Z, comm 0.350271, net 47.099955, `realized_pnl` 0, order 2078622304; and `00012971.6a8444cc.01.01` MSCI **SELL** 0.0863 @ 550.68, 2026-08-18T13:30:00Z, comm 0.351271, net 47.523684, `realized_pnl` **−2.819387**, order 584233614. Whether both were already mirrored into `events.trade_fills` cannot be verified without BigQuery — but the insert is idempotent on `trade_id`, so a replay is safe either way.

**What the halt DID cost, and it is not nothing:** today's run is the one that carries **Friday 2026-08-21's** `ops.account_snapshot` row (`snapshot_date = state.trading_day_today.last_trading_day`; today is Sunday, so `source = 'D2a-connector-carried'`). `ops.account_snapshot` has no loop and no backfill — an unreplayed slot leaves a **permanent** hole that `state.account_snapshot_gap` (`bigquery/153`) then flags every week, exactly the 2026-07-23/24 failure mode. Also skipped: `events.daily_marks` / `events.signal_marks` / `events.option_marks` ingest, `ops.sp_daily_refresh()`, the `TECHNICAL_SIGNAL` four-key write (`SPY_TREND`, `VIX_REGIME`, `SUSTAINED_INVERSION`, `EQUITY_BREADTH` — the last of which is what D1's deferred item 5 above feeds), the mark-discontinuity tripwire, the cash/park tripwire, REGIME-CAPITAL and NOMADIC sync, and the alert-lifecycle sweep.

#### Perishable evidence — captured now so the replay does not have to invent it

Live IBKR reads at **2026-08-23 22:45–22:48 UTC (16:45–16:48 MT)**. These are the correct inputs for the back-dated `ops.account_snapshot` row and cannot be recovered by a later session, because a Monday-evening read no longer sees Friday's book.

- `get_account_summary`: `net_liquidation` **15972.15**, `equity_with_loan_value` 15949.24, `buying_power` 47824.93, `gross_position_value` **15972.05**, `total_cash_value` **−0.20**, `available_funds` **11956.23**, `initial_margin` 3993.01, `maintenance_margin` 3993.01, `excess_liquidity` 11978.83, `dividends` 0.30, `leverage` 1.0.
- `get_account_balances` (USD = BASE): `cash_balance` −0.20, `settled_cash` −0.20, `net_liquidation_value` 15972.1457, `stock_market_value` 15972.05, `unrealized_pnl` −43.21, `realized_pnl` 0.
- `get_account_positions` — 10 rows, VOO is the park vehicle (`state.park_policy_current`, contract 136155102): **VOO 21.8139 sh @ 703.71002195 = 15350.66004782** (avg 707.63192735, unrealized −85.55); then AMZN 0.3464 @ 258.6300049 = 89.5894337; CRM 0.2275 @ 209.16999815 = 47.58617458; DIS 0.7244 @ 107.7799988 = 78.07583113; GEV 0.1244 @ 957.00 = 119.0508; GOOGL 0.2577 @ 345.1000061 = 88.93227157; ISRG 0.1091 @ 378.80999755 = 41.32817073; RTX 0.1601 @ 209.91000365 = 33.60659158; TSM 0.1550 @ 418.9500122 = 64.93725189; UBER 0.5156 @ 79.00 = 40.7324. Nine equity tranches — matching D1's book — plus the park leg. **No option position, so the option-mark branches (1b) were vacuous today regardless.**
- `get_pa_performance_all_periods` (`portfolio_measure = "TWR"`, last element of each `cps`): `twr_1d` **0.00111103**, `twr_7d` **−0.01327739**, `twr_mtd` **0.00855368**, `twr_ytd` **−0.01329126**, `twr_1y` **−0.01329126**. The daily NAV series ends `…20260820: 15894.229893, 20260821: 15954.419893, 20260823: 15972.14566`.

#### Two observations for the replay session — neither is actionable from a halted D2a

1. **The Sunday-carry caveat (i) in D2a's Step 0b is not exactly true this week, and the performance series gives the better number.** That bullet asserts `nav`/`total_cash`/`gross_position_value`/`sgov_market_value` "carry over CLEANLY (the book does not trade over a weekend it is parked through, so Friday's close IS what a Sunday read sees for those fields)". Measured today they do not: `get_pa_performance_all_periods` reports **NAV 15954.419893 for 2026-08-21** but **15972.14566 for 2026-08-23** — a **+$17.73 (+0.111%)** weekend move, which is precisely what `twr_1d = 0.00111103` is measuring (its own `start_date` is `20260821`, so that figure is a Friday-close→Sunday return, not Friday's session; Friday's own session return was 15894.229893 → 15954.419893 = **+0.3787%**). Consistently with that, the per-position `market_value` fields sum to **15954.50**, which matches IBKR's own 2026-08-21 NAV, while `get_account_summary`'s `gross_position_value`/`net_liquidation` read 15972.05/15972.15 — i.e. the two connector surfaces, read within the same minute, disagree by ~$17.6 because they are marked as of different instants. **Recommendation for the replay: stamp the `snapshot_date = 2026-08-21` row from the performance series' own `20260821` NAV (15954.419893), not from the live summary NLV**, and treat the TWR columns per caveat (i) as measuring the wrong window. Do not read the $17.6 as connector corruption — the connector-sanity band was not tripped, and this is a marking-instant difference, not an unexplained residual. Owning surface: `Claude_Task_Plan.md` D2a STEP 0b.
2. **RUNBOOK §48's incident class is recurring TODAY, on D1's own commit, and the correction must land before it does damage.** §48's adopted prevention is "a halt-record commit subject must NOT lead with the routine's own id," because `scripts/auto_merge_decision.sh`'s `marker_routine_from_subject()` + `bigquery/38_run_log_selfheal.sql` will backfill a `status='completed'` row from any such marker. Commit `088fcf7`'s subject leads with **`D1`** and D1 wrote **no** `ops.run_log` row today (BigQuery was down), so once the connector is restored the first `ops.sp_assert_deps` call will insert an auto-backfilled `completed` row for **D1 / 2026-08-23** and advance `state.routine_catchup_window`'s D1 watermark to today — even though D1's ten deferred writes above never landed. That is the exact W5 / 2026-08-16 mechanism. **This D2a record deliberately does not lead its commit subject with `D2a`**, so it mints no marker of its own. Owning surface: RUNBOOK §48 resolution + `bigquery/38`; D2a did not mutate another routine's run history from its own session, matching the precedent D2 set on 2026-08-16.

#### Replay checklist (recovery session, after re-auth — RUNBOOK §26 step 2)

Re-run **D2a for 2026-08-23 first**, then D2. D2a is in the OPS0/OPS2 scope-guardrail exclusion set (`bigquery/59`), so **nothing will auto-refire it** — its only recovery is a human or its next scheduled slot, and its next slot cannot recover Friday's `ops.account_snapshot` row. The nightly `cadence_check` will have raised a `missed_run` critical for it; resolve that per §26 once the replay is green.

---

### APPENDED BY THE D2 SLOT — 2026-08-23 ~17:15 MT — **D2 HALTED, NOT DEGRADED**

*Written by the D2 routine. Same rationale as the D2a subsection above: this file is the day's shared outage record, and D2 is the last daily routine to fire into the outage.*

**Pre-flight.** The BigQuery MCP server's tools were not exposed to this session at all — the harness withheld the entire surface pending re-authorization — so the sanctioned liveness read (`SELECT * FROM state.trading_day_today`) and the DIAGNOSE-BY-PROBE probe pair were **unexecutable rather than merely failing**, exactly as in the D2a slot. Auth class ⇒ **non-waitable**; the TRANSIENT-FAILURE retry ladder was correctly not entered and no wait budget was spent. **IBKR live** (`get_account_summary` exercised: NLV 15972.15, gross_position_value 15972.05, total_cash −0.20, available_funds 11962.72, dividends 0.30) and **Calendar live** (`search_events` exercised).

**Positive corroboration of the de-auth, beyond "the tools are absent" (new this slot).** `~/.claude/.credentials.json` carries an `mcpOAuth` entry for `Google-Cloud-BigQuery` whose **`accessToken` is an empty string and which holds no refresh token**. This distinguishes a genuine credential loss from a transient harness tooling gap, and it means the fix is a **full owner re-authorization, not a token refresh**.

**No alternate path exists from this container — checked rather than assumed.** No `bq` / `gcloud` CLI; `google-cloud-bigquery` and `google-auth` are not installed (`ModuleNotFoundError: No module named 'google'`); no service-account key, no `GOOGLE_APPLICATION_CREDENTIALS`, no ADC, no `~/.config/gcloud`; the GCE metadata endpoint returns 403. Every in-repo script that touches BigQuery either shells out to the absent `bq` CLI (`scripts/lib/bq_json.py` consumers) or lazily imports the absent client library (`scripts/adversarial_review_storage.py`). CI's only path is **keyless WIF bound to a GitHub Actions OIDC token** (`.github/actions/gcp-wif-auth`), which a routine session's container cannot obtain, and no long-lived key exists anywhere in the repo to bypass it. Network egress to `bigquery.googleapis.com` is open (discovery doc returns 200) but useless without credential material.

#### TWO INDEPENDENT, INDIVIDUALLY SUFFICIENT REASONS TO HALT — re-auth ALONE does not unblock D2

1. **BigQuery unreachable** → `Claude_Task_Plan.md` Observability, "BigQuery unreachable": *"D2/D3 require canonical state → HALT cleanly ... craft no orders."* D1's DEGRADED-MODE branch is explicitly research-only and does not extend to D2.
2. **D2's own FATAL dependency gate would abort even with BigQuery fully restored.** `CALL ops.sp_assert_deps('D2', ['D1','D2a'], 2026-08-23)` requires both upstreams to have logged `completed` for today. **D2a wrote no `ops.run_log` row at all** (it halted), and its halt-record commit `0f15df5` correctly opens with the token `Halt`, which `marker_routine_from_subject()`'s allowlist regex does not match — so the §38 marker self-heal mints **no** D2a row either. The gate therefore fails on D2a on the merits. (Contrast D1: commit `088fcf7` leads with `D1`, so the backfill *will* mint a spurious `completed` row for it — the RUNBOOK §48 defect D2a already recorded, and it is D2's own `sp_assert_deps` call that triggers it. It does not rescue the gate, because D2a remains unsatisfied.)

**Consequence for recovery: the replay order in the D2a checklist above is confirmed at the gate level, not merely by convention.** Re-authorizing BigQuery and firing D2 would still abort on `missing_dependency`. The order is **re-auth → replay D2a for 2026-08-23 → then D2.**

#### NEW: THE OUTAGE ONSET IS BOUNDED TO A ~3-HOUR WINDOW

Neither the D1 nor the D2a record dates the onset. It is recoverable from today's own commit history:

- **OPS1 — commit `603c92f`, 2026-08-23 12:53 UTC (06:53 MT): BigQuery LIVE.** Its dual-source connector enumeration counted **`Google-Cloud-BigQuery` 6** tools (surface fully exposed), and the run raised a `connector_tool_added` warning and wrote its observation rows — both BigQuery writes.
- **Alert triage — commit `56989bf`, 2026-08-23 19:11 UTC (13:11 MT): BigQuery LIVE.** That session resolved three `ops.alerts` rows on the board with measured notes and landed `bigquery/196` — again, live writes.
- **D1 pre-flight — ~2026-08-23 22:15 UTC (16:15 MT): BigQuery DEAD** ("requires re-authorization (token expired)" on every call, including bare `SELECT 1`).

**Onset window: 2026-08-23 19:11–22:15 UTC (13:11–16:15 MT).** Useful to RUNBOOK §26 recurrence analysis, which so far records only that the grant "expired" without bounding when.

#### WHAT THE HALT COST — MEASURED FROM TODAY'S `Daily.md`, NOT ASSUMED

**The D1 prose/`d1_actions` corruption cross-check PASSES.** Run independently against today's snapshot (the one gate in D2's flow that needs no BigQuery): **7 prose bullets vs 7 block entries, and per category** — exits 0/0, new entry candidates 0/0, add candidates 0/0, watchlist 7/7, router reviews 0/0. The block is present, fenced, parseable and in the post-2026-07 format. **So D2 would not have aborted on the corruption gate; today's file is trustworthy and directly replayable, and the recovery session need not re-run this check.** (The CATCH-UP CHECK's backfilled-snapshot arm was not exercised — `state.routine_catchup_window` is unreadable — but `Daily.md` on disk is today's and the prior D1 was 2026-08-20, already converted.)

Against that verified action set, the conversion workload D2 owed today was:

| D2 step | Owed today | Status |
|---|---|---|
| 1. EXITS TRIGGERED | **0** — mechanical triggers ZERO, no invalidation criterion breached on any of the 13 open D tranches | nothing lost |
| 2. NEW ENTRY CANDIDATES | **0 routed** (5 recorded index-only; B router DO-NOT-ACTIVATE, B NAV 0.00) | nothing lost |
| 2a. ADD CANDIDATES | **0** — 13 evaluated, 0 flagged, 0 declined at the hard gate | nothing lost |
| 3. WATCHLIST UPDATES | **7** — 5 adds (BTDR, BJ, TSLA, QBTS, DNN) + 2 annotations (MRNA, EL), all Strategy B, all index-only | **DEFERRED — see below** |
| 4. ROUTER REVIEWS | **0** — default-NO holds, no inter-monthly review recommended | nothing lost |
| 5. STRATEGY TERMINATIONS | **0** — kill-trigger sweep clean on D and B; drawdown and runaway both false | nothing lost |
| 6. PARK ALLOCATION CONVERSION | **no-op regardless** — see below | nothing lost |
| STEP 1. PENDING_ANALYSIS drain | queue unreadable; **no item evidenced as due on/before today** — see below | probably nil, must be re-checked live |

**Item 6 — park conversion was a no-op on its own rails, outage or not.** D1's call is `status=BOUND`, `vehicle=VOO`, `direction=keep`. The live park leg is already VOO (D2a measured 21.8139 sh @ 703.71), and the last vehicle cutover recorded in `bigquery/` is the 2026-07-15 SGOV→VOO one (`54`/`55`), with no later `park_policy_changes` write. That is a **bound KEEP**, which the routine defines as *"also do nothing; there is no switch to execute."* No `events.park_policy_changes` INSERT, no first-leg SELL, no paired BUY leg. (`state.park_policy_current` itself was unreadable, so this rests on the live holding plus the repo's cutover history rather than on the view — stated so the replay re-reads the view rather than inheriting the inference.)

**Item 3 — why the 7 watchlist edits were NOT applied unilaterally, which is a correctness reason and not merely "the routine halted."** Watchlist edits are otherwise among the cheapest things D2 does, and the trading-enable gate explicitly never blocks them. But **all 7 are Strategy-B identities**, and item 2's **Strategy-B event identity guard** requires querying open *and* terminal `events.queue_events` history plus `events.decision_log` for the exact four-part identity (`thesis-construction` + `strategy='B'` + ticker + `qualifying_event_date`) **before creating or acting on one**. That query is precisely **DEFERRED ITEM 8 above**, which D1 itself marks *"OWED, not merely deferred ... the check must be run before any of the five is ever converted."* Writing them into `Watchlist.md` now would be converting them with their dedupe check unrun — the one thing that item forbids. They are fully specified in the `d1_actions` block above and replay verbatim once the check can run; nothing needs re-deriving.

**STEP 1 — the `PENDING_ANALYSIS` drain is the only step whose cost cannot be read off `Daily.md`, and D2 is its SOLE drainer** (`ops/handoff_contracts.yaml`: `drainers: [D2]`). The queue lives only in `events.queue_events` and could not be read. It is nonetheless bounded tightly by the on-disk record, because the *last clean D2 run* left a dated statement about it:

- **D2's own run on 2026-08-18 (commit `a25c9003`) records: "No PENDING_ANALYSIS items due today."** That is the strongest single datum available — a direct observation of the live queue by this very routine, five days ago.
- **The window that statement leaves open is 2026-08-19 → 2026-08-23, and the visible history covers it.** Every routine that fired in it and could have enqueued into this lane recorded a no-op: **W4** (`6feb31e`, today 09:51 UTC) states *"Zero PENDING_ANALYSIS enqueues and zero `events.queue_events` rows"*; **W2** (`8b53d6a`) confirms C's only item is already pending and explicitly must not be re-enqueued; today's **D1** routed no thesis and enqueued nothing (it could not write at all); **D2a** halted. The SL2/SL3/AR_orc/D3 `due_date` traffic in this window is all in the `PENDING_DRAFT` / `PENDING_ROSTER` / `PENDING_REVIEW` lanes, which D2 does not drain.
- **Every dated `PENDING_ANALYSIS` item findable on disk falls after today:** `recheck-CRM-criteria-D-20260827` (**due 2026-08-27** — re-assessing all five `D:CRM:2026-07-09` invalidation criteria ahead of Salesforce's FQ2 FY27 print on 2026-08-26 AMC; this is the item `ops/RUNBOOK.md` §48's "earliest due 2026-08-27" reading refers to), `thesis-FOMC-C-20260908` (**2026-09-08**), `rescreen-LLY-D-20260914` (**2026-09-14**), `rescreen-NKE-D-20260925` (**2026-09-25**).
- **The one item with a past due_date, `research-deferral-GEV-D-20260809`, is resolved by the same 08-18 datum.** `Watchlist.md`'s prose describes it as open and was never corrected, so the file alone is ambiguous — but an item due 2026-08-09 and still open would necessarily have been *due* on 2026-08-18, and D2 recorded none due that day. Taking this routine's own run record at face value, it drained on or before 2026-08-18. (Its conservative default was a PROCESS exit of the GEV position; no such exit appears anywhere, which is consistent with a normal resolution rather than a lapse.)

**Conclusion: no `PENDING_ANALYSIS` item is due on or before 2026-08-23, so D2's drain cost today is almost certainly nil** — the same finding as the 2026-08-16 halt. **This is a bound from evidence, not a substitute for the check:** the checkout is a **shallow clone** with no commits reachable before 2026-08-18 04:45 UTC, and an item enqueued straight into BigQuery leaves no file trace at all. **The replay must still run STEP 1 against the live queue rather than inheriting this conclusion.** It is recorded because a due item rotting past its window unexamined is the one D2-specific loss this outage could cause, and it is worth knowing that it very probably did not.

**Nothing was written.** No `ops.run_log` row for D2 (not even `started`), no order crafted, no `events.*` row, no `ops.alerts` row, no `Watchlist.md` edit, no calendar event of its own.

#### D2 cannot be auto-refired either

`ops/cadence.yaml` declares **D2 `catchup_safe: false`** — capital-adjacent, and in the same OPS0/OPS2 scope-guardrail exclusion set as D2a (`bigquery/59`). **Neither OPS0's 22:30 MT sweep nor OPS2 will recover this run.** Its only recovery is a human or its next scheduled slot, and the nightly `cadence_check` (05:15 UTC) will raise a `missed_run` critical for D2 alongside D2a's; both are TRUE positives and resolve per §26 once the replays are green.

#### Calendar

**No duplicate event.** D1's existing `[Claude] ATTENTION — RE-AUTH BigQuery connector` event was amended in place with this slot's escalation, per the Observability **INCIDENT INHERITANCE** rule (one incident, one alert thread; escalate only on material information — here the onset bound, the second independent halt reason, and the drain-lane blast radius).

---

## PROCESS NOTES

**1. THE PARALLEL-BATCH SHIFT DEFECT RECURRED, EXACTLY AS THE 2026-08-20 FILE PREDICTED — and the operational rule it wrote caught it.** That file recorded a 30-way parallel `get_price_history` batch returning internally shifted results and established the rule: *do not issue wide parallel batches; keep batches small, match every response by `contract_id`, and spot-verify any figure a decision turns on.* This run, a **25-symbol parallel batch silently dropped the BABA call and shifted every subsequent result by one position.** The sub-agent caught it by cross-checking against independently sourced closes and re-fetched every affected ticker individually or in small batches before computing anything. **This is now a reproducible defect across two consecutive sessions and two different agents, not an anomaly.** Independently of that, the orchestrating session pulled the decision-critical bars itself in batches of ≤2 — VOO, ISRG, BJ, SRE, EIX, FUTU, BTDR — and the tape agent's figures were confirmed exactly where they overlapped (VOO 701.01 → 703.71; ISRG 374.48 → 378.81).

**2. THE COST-BASIS DERIVATION WAS FORCED BY THE OUTAGE AND FOUND A DEFECT IN THE PRIOR FILE.** With `state.current_positions` unreachable, per-tranche costs had to be reconstructed from the 08-20 file's percentages and validated against IBKR `average_price`. The validation succeeded to under six-thousandths of a dollar on all four multi-tranche names and exactly on RTX/GEV/CRM/UBER — which is what makes the **single failure diagnostic rather than ambiguous**: ISRG, a single-tranche position with no blending explanation, is off by 0.89pp, so the 08-20 file's "+7.14%" was wrong and +6.25% was correct. **A degraded-mode workaround produced a cross-check the normal path does not perform.** The derivation also resolved the TSM tranche-ordering ambiguity that file left open in two inconsistent places.

**3. `mcp__FMP__quote` IS NOW PLAN-GATED ENTIRELY — a documented D1 evidence path has silently degraded.** A `batch-quote` call returned **`ACCESS DENIED: This tool ("quote") requires the Premium, Ultimate, or Enterprise plan`**, with an explicit instruction not to retry or attempt sibling tools. **This matters beyond one call:** `Claude_Task_Plan.md`'s PARK ALLOCATION CALL names `mcp__FMP__quote`/`mcp__FMP__chart` as the VIX source and asserts that *"no daily VIX series exists anywhere else in this stack."* **That assertion is now false in both halves** — the FMP path is gated, and **IBKR `get_price_history` with `security_type="IND"` on CBOE returns a clean daily VIX series** (used for this run's 16.01 → 15.13). **No task-plan edit was made:** that file is outside D1's remit, the run was not blocked (IBKR covered it), and the correction is recorded here and in DEFERRED BIGQUERY WRITES item 10 for the owning surface. FMP's `company` profile also returned plan-restricted for BMNR, leaving BTDR's and BMNR's market caps unverified.

**4. VIX BARS CARRY A DIFFERENT TIMESTAMP AND THE AGENT WAS RIGHT TO FLAG IT.** IBKR stamps the VIX index series at **`T07:15:00Z`**, not the `T13:30:00Z` used by US equity regular-session bars. The identify-by-timestamp discipline is about not trusting array position; it is not a claim that every instrument shares one stamp. Flagged so a future run does not reject a valid VIX bar for having the "wrong" timestamp.

**5. SEARCH-SPACE POLLUTION WAS THE DOMINANT RESEARCH HAZARD THIS RUN, AND IT WAS ONE-DIRECTIONAL.** Every stale item found pointed toward a **more eventful** reading than the truth: a 2025 Jackson Hole speech, a January 2026 ISRG clearance, a 2025-01-28 utilities-selloff article, a 2026-08-04 PLTR catalyst, a recycled SOFI earnings beat, and an RTX contract dated 08-17. **Not one stale item would have made the window look quieter than it was.** On a window whose genuine content is thin, that asymmetry is the specific way a scan gets inflated, and it is worth naming as a pattern rather than as six separate rejections.

**6. FRONTIER-LLM CAPABILITY CHECK — run, no capture.** One `hf_fs` paper search (Sunday rotation: long-context degradation, query *"long context LLM degradation lost in the middle"*). Five results; the newest published **2025-02-01**, i.e. **none published since the last D1 run** and none within the ~72-hour cap. No paper bears on a documented `AI_Trading_Foundation.md` disadvantage in-window, so **no `[HF Frontier-LLM Capture]` entry and no `state.strategy_candidates` row** — and neither could have been written this run in any case. Default-silent on ambiguity, as specified.

**7. SUB-AGENT FAN-OUT.** Six Sonnet sub-agents ran (tape/sector measurement, macro and breaking events, single-name movers, equity breadth, held positions and watchlist, utilities/power complex). Every prompt carried an explicit per-agent search budget with instructions on exhaustion, the mandated IBKR price basis with the identify-by-timestamp rule, the anti-staleness verification requirement with the four known-stale ISRG items named, the widen-don't-sibling search rule, and an explicit instruction **not** to pass `include_usage` to Tavily — **zero agents burned retries on that parameter, holding the 2026-08-19 correction for a second consecutive run.** The utilities agent was spawned mid-run by the orchestrating session, not up front, because the XLU outlier only became visible once the tape measurements returned; that is the fan-out working as intended rather than a plan miss.

**8. TRUNCATION AND UNRESOLVED ITEMS, NAMED RATHER THAN LEFT TO SILENCE.** (a) **UEC +14.44% is the largest single mover on the tape and has no company-specific driver** — the weakest-sourced item in the dataset and the one most deserving of a follow-up pass. (b) **FUTU's +9.68% Friday move is unexplained**; its event day was 08-20 at +3.02%. (c) The FMP movers enumeration is a bounded sample and is not established as complete — the 08-20 file's own correction, which surfaced three further ≥5% names twenty minutes after logging, is the standing evidence for how bounded it is. (d) BMNR's and BTDR's market caps are unverified. (e) The Morgan Stanley note→PT-cut causal chain is **plausible and consistent in chronology, not established.**
