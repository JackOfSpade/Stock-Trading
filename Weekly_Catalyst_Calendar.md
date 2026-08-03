2026-W32

# Weekly Catalyst Calendar — Strategies A and C

Run date 2026-08-03 (Monday; ISO week 2026-W32, the same week W2/W3 stamp this cycle). Windows measured from the run date: **Strategy A = 6 months (2026-08-03 → 2027-02-03); Strategy C = 45 days (2026-08-03 → 2026-09-17).**

**CATCH-UP: the W31 weekly cycle was missed by the entire weekly cohort.** W1's last completion was 2026-07-26 (2026-W30); `state.routine_catchup_window` reports `window_days = 8.4`, `never_completed = false`. That is below the weekly 1.5× threshold (10.5 days), so **no `CATCHUP[]` token** is emitted, but the evidence window below is the full 2026-07-26 → 2026-08-03 span rather than a nominal week. W2/W3/W4/W5 last completed the same day and are in the same position. Per the MULTI-PERIOD OUTPUT RULE the marker stays current-period (2026-W32); no W31-stamped content is emitted, and because both calendars are *forward-looking from the run date*, a missed cycle is subsumed rather than needing a separate labelled sub-section — what the missed cycle would have covered forward is inside today's windows already.

**Regime context (`state.current_regime`; M1a scored 2026-08-01, M1b/M4 converted today):** integrative call **"stagflationary shock + hawkish policy"** — growth_momentum **decelerating**, inflation_trend **stable**, policy_stance **hawkish**, risk_sentiment **neutral**, shock_overlay **acute**. Technical plane (M1b re-measured for 2026-07-31 after repairing a 61-day-stale write): SPY_TREND **UP** (close 747.03 > 50d 744.99 > 200d 700.39), EQUITY_BREADTH **HEALTHY** (~67%), VIX_REGIME **NORMAL** (15.99), SUSTAINED_INVERSION **NOT-SUSTAINED**.

**Router state — both A and C are sub judice, with reviews due tomorrow.**
- **A = DO-NOT-ACTIVATE, pending `div-A-202607-1` (due 2026-08-04).** This is the **first A divergence in the recorded lineage**, and it exists only because the SPY_TREND repair flipped A's *technical* leg (SPY Trend UP **AND** Breadth HEALTHY) to ACTIVATE for the first time; M1b's raw fundamental call remains DO-NOT-ACTIVATE. Prior final state DO-NOT-ACTIVATE stays operative until the review resolves.
- **C = HYBRID ACTIVATE (FOMC-only), pending `div-C-202607-1` (due 2026-08-04).** Only an FOMC-catalyst C thesis is router-eligible; earnings/FDA/vol-directional C theses remain DO-NOT-ACTIVATE. The review's stated new input is that the September FOMC is now materially two-sided.

**Strategy A is CAPITAL-DISABLED, not merely router-gated — this is new since the W30 file and changes what the A shortlist means.** Under the REGIME-CAPITAL SYNC owner directive (2026-07-19), a router DO-NOT-ACTIVATE strategy receives zero allocation and its capital is swept to enabled strategies. A's entire **$1,889.37** was swept to B/C/D/E on 2026-07-19. `analytics.strategy_nav` reads **A NAV = $0.00**; `state.regime_capital_debt` shows A `swept_out_total` $1,889.37, `restored_total` $0.00, `outstanding_debt` **$1,889.37**; `state.strategy_capital_enablement` shows A `capital_disabled = TRUE` (B/C/D/E all `capital_enabled`). Restoration is **mechanical on `trigger=regime_enable`** — i.e. the capital comes back automatically if and when the router flips. **Consequence for PART 2A: the A shortlist below is a queue against a router flip that also restores funding, not a list of presently-fundable entries.** At A NAV $0.00 no A entry is executable at any size today. The W30 file ranked 46 A candidates without recording this.

**Open positions (for overlap/deconfliction), from `state.current_positions`:**
- **B:** ISRG (7/21), MSCI (7/27), FTV (7/29), MTZ (8/3, provisional staging-time OPEN), MDT (EXIT_PENDING on the mechanical time exit, three sessions overdue)
- **D:** AMZN ×2 (7/09, 7/30), GOOGL ×2 (7/09, 7/26), TSM ×2 (7/21, 7/29), CRM, DIS, ISRG, RTX, UBER, GEV (8/3, provisional)
- **No open A or C positions.**

Strategy.md prohibits **A/B** and **A/C** same-name simultaneous holding; there is **no A/D prohibition**. **Excluded from the A shortlist on the A/B rule: ISRG, MSCI, FTV, MTZ, MDT.** D holdings (AMZN, GOOGL, TSM, CRM, DIS, RTX, UBER, GEV, ISRG) may appear on the A shortlist, but any future A activation on those names must first run the correlation-bucket check against the open D position (Experiment_Parameters §Position size factor 4 — correlation with the existing book is a sizing input, not a bar).

**Operational note (context, not a W1 gate):** `state.trading_enabled` is **FALSE** (`halt_reason`: "state.freshness marks_fresh/engine_fresh not both TRUE"). W1 stages nothing and is unaffected; it bears on W4's conversion of anything below, and several 8/3 entries were crafted under an explicit owner-authorized exception recorded in `events.decision_log`.

**Past-window tape (2026-07-26 → 2026-08-03; facts per extraction discipline, sources at foot).** The mega-cap print block landed and **split hard**, inverting the W30 file's "tape punishes the capex payers" read: **MSFT** FQ4 rev $90.01B / EPS $4.74 both beat, **Azure +43%**, total cloud +27% to $59.3B → **+8.5%**; **AMZN** rev $200.6B (+20%) beat, **AWS +36.7% YoY — fastest in 18 quarters**, AI run-rate >$25B → **+15.32% to $271.58** on 7/31; against **META** EPS $6.18 vs $7.19 est (miss) on $2.40B legal + $1.18B layoff charges → **−9%**; and **AAPL**, which beat on both lines with Cook calling it the "strongest June quarter" but guided softly → **−7.4% Friday, its worst day in a year**. **QCOM** in line on the quarter but guided FQ4 EPS $2.05 vs $2.35 street, citing "unprecedented increases in memory pricing" → **−2.7%**. **SBUX** +8% on a $0.85-vs-$0.65 beat. **BA** rev $24.6B (+8%) beat with a wider core loss; reaction reports conflict (+3.0% / +1.2% / −2.2%) and are recorded unreconciled. **PYPL** +3.2% on a beat-and-raise. **XOM** profit $14.5B (more than doubled YoY) on an 8¢ adj-EPS miss; **CVX** net income $12.0B with a 50¢ beat. **ABBV** adj EPS $3.65 missed $3.77 and trimmed the FY26 guide on Apogee dilution.

Macro: the **7/29 FOMC held at 3.50–3.75% on a 9–3 vote with three dissents FOR A HIKE** (Logan, Kashkari, Hammack) — the first three-dissent vote since 2016; the 30Y reached **5.21%, highest since 2007**, and 10Y 4.69%. June **PCE** headline −0.1% MoM / +3.7% YoY, **core +0.1% MoM / +3.3% YoY** (unchanged from May). **ISM Manufacturing for July, released this morning, printed 55.6 vs 53.3 prior — the fastest expansion in over four years**, which cuts directly against the decelerating-growth axis M1a scored on 8/01. Week ending 7/31: S&P 500 **+1.0% to 7,489.72**, Nasdaq **+1.6% to 25,373.85**, Russell 2000 +0.1%, but **SOX −4.30% on the week and >−20% for July — its worst month since October 2008**. Credit stayed tight (**HY OAS 281–284bp, IG 81bp**); VIX eased to **~16.8–17.1**. Oil round-tripped: Brent ran ~+16–20% through July on Hormuz disruption, then **fell ~7.5% over the weekend** (Brent $83.42, WTI $79.79 Sunday night) after Trump **called off** the planned strike on 8/2 and announced "parameters" of a Hormuz-reopening deal — **which Iran's foreign ministry publicly denied on 8/3**, with Baghaei stating the strait "remains closed." **This is at least the fifth halt/ceasefire announcement in this conflict to be contradicted within days; the de-escalation is one-sided and unconfirmed.** China PMIs weakened materially in the same window (NBS manufacturing **49.2**, first contraction since February; Caixin 50.9 vs 51.5 expected).

**September-hike odds are venue-contested and the W30 file's figure is stale.** Readings this session: RateProbability **62%**, Polymarket **60%**, Kalshi **56%**; the ~82% CME FedWatch figure the W30 file carried is a **2026-07-23** read and is not re-verifiable as current. D1's own 8/2 scan independently flagged this, recording NYT DealBook (7/30) at 60% and marking the precise level **INFERRED** rather than measured. Treated here as: the market prices a **meaningful but sub-certain** September hike probability, roughly 56–62% on the venues checkable today.

**Not yet resolvable at run time:** today's 8/3 session had not closed when this file was written; **PLTR reports 8/3 AMC** and **VRTX reported 8/3 AMC** — both land after this file and are W2/D1 material, not W1's.

---
## PART 1A — Strategy A universe catalyst calendar (6-month window, 2026-08-03 → 2027-02-03)

Universe: US-listed common equity, market cap ≥ $2B, 30-day ADV ≥ $10M, with a scheduled catalyst in the window. Date labels: **(C)** confirmed to a company/primary source · **(E)** estimated (recurring cadence or stated window, no fixed date) · **(T)** tentative (sources conflict or single low-quality source). No interpretation — facts only.

*Universe floor unchanged this cycle: AR_orc adjudicated `otr-A-marketcap-floor-2026` on 2026-07-30 → **HOLD**, with an explicit non-relaxation note ("a contradicted rationale makes the floor potentially UNMOTIVATED, not over-tight — nothing here licenses loosening").*

### 1A.1 — Earnings catalysts

| Ticker | Name | Catalyst | Date | Source |
|--------|------|----------|------|--------|
| AMD | AMD | Q2 FY26 earnings | 2026-08-04 (C) | AMD IR release 2026-07-08 |
| PFE | Pfizer | Q2 earnings | 2026-08-04 (C) | Pfizer IR release |
| MRK | Merck | Q2 earnings (BMO, 9:00 ET) | 2026-08-04 (C) | Merck IR release 2026-07-01 |
| CAT | Caterpillar | Q2 earnings | 2026-08-04 (C) | Caterpillar media advisory |
| DIS | Disney | FQ3 earnings (BMO, call 08:30 ET) | 2026-08-05 (C — **upgraded** from E) | Disney IR release 2026-07-14 |
| SHOP | Shopify | Q2 earnings | 2026-08-05 (C — **upgraded**) | Shopify release 2026-07-08 |
| UBER | Uber | Q2 earnings | 2026-08-05 (C — **upgraded**) | Uber IR release 2026-07-13 |
| LLY | Eli Lilly | Q2 earnings (BMO) | 2026-08-05 (C) | investor.lilly.com |
| DDOG | Datadog | Q2 earnings | 2026-08-06 (C — **NEW**, absent from baseline) | Datadog IR release 2026-07-16 |
| SMCI | Super Micro | FQ4 earnings | 2026-08-11 (C) | SMCI release 2026-07-21 |
| CSCO | Cisco | FQ4 earnings | 2026-08-12 (C — **upgraded**) | stated on Cisco's own FQ3 call |
| DE | Deere | FQ3 earnings | 2026-08-13 **or** 2026-08-20 (T — **NEW conflict**: public.com 8/13 vs Zacks/MarketBeat 8/20) | conflicting aggregators |
| HD | Home Depot | Q2 earnings | 2026-08-18 (C — **NEW**) | Home Depot IR events page |
| TGT | Target | Q2 earnings | 2026-08-19 (C — **upgraded**) | Target IR events page |
| LOW | Lowe's | Q2 earnings | 2026-08-19 (C* — **NEW**; Lowe's own page labels it "(tentative)") | corporate.lowes.com |
| WMT | Walmart | Q2 FY27 earnings (07:00 CT) | 2026-08-20 (C — **upgraded**) | Walmart corporate events page |
| OKTA | Okta | FQ2 earnings | 2026-08-26 (C — **CONFLICT RESOLVED**; baseline had 8/25 vs 9/2, neither correct) | Okta release 2026-08-01 |
| NVDA | NVIDIA | FQ2 earnings | 2026-08-26 (C — **upgraded**) | NVIDIA release 2026-07-29 |
| SNOW | Snowflake | FQ2 earnings | 2026-08-26 (E) | cadence (FQ2'26 landed 2025-08-27) |
| WDAY | Workday | FQ2 earnings | 2026-08-27 (C — **NEW**) | Workday release 2026-08-03 |
| MRVL | Marvell | FQ2 earnings | 2026-08-27 (E) | cadence (FQ2'26 confirmed 2025-08-28) |
| CRWD | CrowdStrike | FQ2 earnings | ~2026-09-01 (E) | MarketBeat cadence estimate |
| PANW | Palo Alto Networks | FQ4 earnings | 2026-09-01 (C — **MOVED** from baseline ~8/17) | PANW release 2026-08-03 |
| ZS | Zscaler | FQ4 earnings | ~2026-09-01 (E — **NEW**) | MarketBeat cadence estimate |
| AVGO | Broadcom | FQ3 earnings | 2026-09-02 (C — **CONFLICT RESOLVED**, 9/2 not 9/3) | Broadcom release 2026-08-03 |
| NTAP | NetApp | FQ1 earnings | 2026-09-02 (C) | NetApp IR target date |
| HPE | HP Enterprise | FQ3 earnings | ~2026-09-02 (E) | MarketBeat cadence estimate |
| CRM | Salesforce | FQ2 earnings | ~2026-09-02 (E) | MarketBeat cadence estimate |
| DELL | Dell | FQ2 earnings | 2026-09-03 **or** 2026-08-27 (T — **NEW conflict**; the 8/27 datapoint duplicates MRVL/WDAY dates and is likely a stale scrape) | conflicting aggregators |
| ORCL | Oracle | FQ1 earnings | 2026-09-08 / 09-09 / 09-14 (T — **3-way, WORSENED** from baseline's 2-way; no Oracle IR release found) | conflicting aggregators |
| ADBE | Adobe | FQ3 earnings | 2026-09-10 (E) | Zacks (explicitly "estimated") |
| FDX | FedEx | FQ1 earnings | 2026-09-17 (E) | cadence estimate |
| MU | Micron | FQ4 earnings | 2026-09-22 / 09-23 / 09-29 (T — 3-way conflict persists; no Micron IR confirmation) | conflicting aggregators |
| COST | Costco | FQ4 earnings | 2026-09-24 (C) | Costco IR events page; WSH "CONFIRMED" |
| NKE | Nike | FQ1 earnings | 2026-09-29 **or** 2026-09-24 (T — **NEW conflict**) | conflicting aggregators |
| TSM | Taiwan Semi (ADR) | Q3 earnings | ~2026-10-15 (E) | cadence (Q2 landed 2026-07-16) |
| GE | GE Aerospace | Q3 earnings | ~2026-10-20 (E) | cadence (Q2 landed 2026-07-16) |
| NFLX | Netflix | Q3 earnings | ~2026-10-20 (E) | cadence |
| UNH | UnitedHealth | Q3 earnings | ~2026-10-27 (T — TipRanks outlier 10/09 inconsistent with cadence) | Zacks/public.com vs TipRanks |
| MSFT / GOOGL / META / AMZN / AAPL | Mega-cap Q3 block | Q3 / fiscal-Q4 earnings | ~2026-10-27 → 10-30 (E) | cadence |
| NVDA | NVIDIA | FQ3 earnings | ~2026-11-18 (E) | WSH "INFERRED"; cadence off confirmed FQ2 |
| CRM | Salesforce | FQ3 earnings | ~2026-12-02 (E) | cadence (FQ3'26 landed 2025-12-03) |
| ORCL | Oracle | FQ2 earnings | ~2026-12-09 (E) | cadence (FQ2'26 landed 2025-12-10) |
| AVGO | Broadcom | FQ4 earnings | ~2026-12-10 (E) | cadence (FQ4'25 landed 2025-12-11) |
| MU | Micron | FQ1 earnings | ~2026-12-16 (E) | cadence (FQ1'26 landed 2025-12-17) |
| JPM | JPMorgan Chase | Q4 earnings | 2027-01-14 (C) | JPMorganChase IR events page |
| BAC / C / WFC | Money-center banks | Q4 earnings | ~2027-01-13 → 01-14 (E) | cadence, anchored to JPM's confirmed date |
| GS / MS | Goldman / Morgan Stanley | Q4 earnings | ~2027-01-15 (E) | cadence |
| MSFT | Microsoft | FQ2 earnings | ~2027-01-26 → 01-27 (E) | cadence |
| META | Meta Platforms | Q4 earnings | 2027-01-27 (E) | WSH "INFERRED"; cadence |
| AAPL | Apple | FQ1 earnings | ~2027-01-28 → 01-29 (E) | cadence |
| GOOGL | Alphabet | Q4 earnings | ~2027-02-02 → 02-03 (E — **at the window edge**) | cadence |

*(AMZN's Q4 print, cadence ~2027-02-04/05, falls **just outside** the 2027-02-03 boundary and is deliberately not listed.)*

**Reported inside the evidence window — no longer upcoming catalysts:** V, KO, BA, PYPL, F (7/28); QCOM, SBUX, MSFT, META, HOOD (7/29); AAPL, AMZN, COIN, MA (7/30); ABBV, XOM, CVX (7/31). Their next prints are the October / January entries above. **Premise correction carried from the W30 file: TSM did NOT report on 7/30.** TSMC reported **2026-07-16**; the 7/30 move (close $403.31, +7.66% vs 7/29's $374.67) was a **sector-wide semiconductor rally** — Fed hold, a Nikkei report that TSMC plans chip-price increases up to 10% from 2027, and short-covering after five straight down sessions — with MU +12%, INTC +8.6% and AMD +8.1% the same day. It was not an earnings reaction and must not be read as one.

### 1A.2 — Product launches / product events

| Ticker | Name | Catalyst | Date | Source |
|--------|------|----------|------|--------|
| GOOGL | Alphabet | "Made by Google" — Pixel 11 / Pro / Pro XL / Pro Fold, Pixel Watch 5 (NYC, 6:00pm ET) | 2026-08-12 (C) | official Google invite issued 2026-07-07; 9to5Google / TechCrunch / The Verge concur |
| AAPL | Apple | Fall event — iPhone 18 Pro / Pro Max **+ first foldable** | ~2026-09-09 (T — leak consensus; **still no official invite as of 8/2**, expected ~8/25-26 on the usual 2-week lead) | Forbes (updated 2026-08-02), MacRumors |
| META | Meta | In-house "Iris" AI training chip enters production (Broadcom design partner, TSMC fab; 7GW 2026 → 14GW 2027) | September 2026 (E) | internal memo via Reuters; ~6-week testing completed |
| NVDA | NVIDIA | Vera Rubin VR200 NVL72 — **in full production since January 2026**; partner/volume availability H2 2026 | H2 2026 (C) | CES 2026 keynote; GTC 2026 |
| INTC | Intel | Nova Lake-S desktop platform | Q1–Q3 2027 (T — **leak-only slip** from "end of 2026"; Intel has confirmed no date either way) | Tom's Hardware / TechPowerUp / WCCFTech, all tracing to unnamed supply-chain leakers |
| (industry) | — | **CES 2027**, Las Vegas Convention Center | 2027-01-06 → 01-09 (C — **newly in window**) | ces.tech (CTA) |

**Resolved / corrected this pass (calendar hygiene):**
- **AMD Instinct MI400 series (MI455X / MI430X, CDNA5) — ALREADY LAUNCHED 2026-07-23** at "Advancing AI 2026" (San Francisco, July 22–23). **Removed from the forward calendar.** The W30 file, written 2026-07-26, carried it as an "H2 2026 (E)" forward catalyst *three days after it had shipped*. Source: AMD IR release, dateline "SAN FRANCISCO, July 23, 2026."
- **NVDA Rubin "redesign" counter-report — WITHDRAWN as a current signal.** The Fubon Research note (analyst Sherman Shang) speculating a Rubin redesign against AMD's MI450 is dated **2025-08-14**, not July 2026; NVIDIA publicly called the delay reports "incorrect" and said "Rubin is on track" at the time; and Rubin subsequently entered full production in January 2026 on its original schedule. The W30 file presented this as a "NEW counter-report" from that week and made it load-bearing in NVDA's #1 ranking — **wrong on both date and outcome.** Do not carry it forward. (A separate, more recent and much weaker claim — that AMD's MI450X board-power increase pushed Rubin's TGP/bandwidth targets — circulates undated on social/tech-forum sources and is **not** adopted here.)

### 1A.3 — Analyst / investor days & major industry conferences

| Ticker | Name | Catalyst | Date | Source |
|--------|------|----------|------|--------|
| CRM | Salesforce | Dreamforce 2026 (Moscone, SF) | 2026-09-15 → 09-17 (C — carried, not re-verified this pass) | salesforce.com |
| INTU | Intuit | Investor Day (Mountain View HQ) | 2026-09-17 (C — carried, not re-verified this pass) | Intuit IR |
| ORCL | Oracle | Oracle AI World 2026 (Las Vegas) | 2026-10-25 → 10-28 (C — carried, not re-verified) | oracle.com |
| ADBE | Adobe | Adobe MAX 2026 (Miami Beach) | 2026-11-10 → 11-12 (C — carried, not re-verified) | max.adobe.com |
| MSFT | Microsoft | Ignite 2026 (Moscone, SF) | 2026-11-17 → 11-20 (C — carried, not re-verified) | ignite.microsoft.com |
| AMZN | Amazon | AWS re:Invent 2026 (Las Vegas) | 2026-12-01 → 12-04 (C — carried, not re-verified) | aws.amazon.com |
| Pharma/biotech (broad) | (multi) | J.P. Morgan 45th Healthcare Conference (SF) | ~2027-01-11 → 01-14 (**E — DOWNGRADED from (C)**: JPMorgan's own conference page still lists only the 44th (Jan 2026); the 2027 dates come from conference-directory secondaries consistent with historical cadence) | jpmorgan.com (official, shows 44th only) + directory secondaries |
| NKE | Nike | Investor Day, Philip H. Knight campus, Beaverton | **UNDATED (T)** — management said "this fall" on the FQ3'26 call; no date set as of 2026-08-03 after checking NIKE IR, newsroom and the call transcript. Third consecutive pass undated. | investors.nike.com / about.nike.com |

*Adjacent but **outside** the window, recorded so a future run does not double-count it: **JPMorganChase's own 2027 Investor Day, 2027-02-22, New York** (announced 2026-06-15) — this is a different event from the JPM Healthcare Conference above and falls 19 days past the 2027-02-03 boundary.*

### 1A.4 — Regulatory decisions (FDA PDUFA, sponsors ≥$2B + structural-regulatory)

| Date | Ticker | Company | Drug / indication | Type | Source |
|------|--------|---------|-------------------|------|--------|
| 2026-08-05 | MRNA | Moderna | mRNA-1010 seasonal flu (VRBPAC 9-0 favorable) | BLA (C) | Moderna PR 2026-02-18 |
| 2026-08-13 | LNTH | Lantheus | MK-6240 tau-PET imaging | NDA, Fast Track (C) | Lantheus PR 2025-10-28 |
| 2026-08-17 | BMY | Bristol Myers Squibb | Iberdomide, r/r multiple myeloma | NDA, Priority + Breakthrough (C) | BMS PR 2026-02-17 |
| 2026-08-23 | RARE | Ultragenyx (~$2.46B) | DTX401 (AAV), GSD-Ia | BLA, Priority (C) | Ultragenyx 8-K 2026-02-23 |
| 2026-08-25 | JAZZ | Jazz Pharma (~$15.9B) | Ziihera, 1L HER2+ gastric/GEJ | sBLA, Priority (C) | Jazz PR 2026-04-27 |
| 2026-08-27 | GILD | Gilead | Bictegravir/lenacapavir HIV | NDA, Priority (C) | Gilead PR 2026-04-29 |
| August 2026 | REGN | Regeneron | Garetosmab, FOP | BLA, Priority (**E — day-level date has never been published**) | Regeneron PR 2026-02-19 |
| 2026-09-11 | TLX | Telix (~$3.4B) | TLX101-Px, recurrent glioma | NDA (**C — UPGRADED** from two passes of (T)) | Telix PR 2026-04-10 |
| 2026-09-19 | RARE | Ultragenyx | UX111 (AAV), Sanfilippo A | BLA (C) | Ultragenyx PR 2026-04-02 |
| 2026-09-21 | MRK | Merck | Winrevair (sotatercept) — HYPERION label update | sBLA (C) | Merck pipeline update |
| 2026-09-22 | IONS | Ionis (~$13.1B) | Zilganersen, Alexander disease | NDA, Priority (C) | Ionis PR 2026-03-23 |
| Q3 2026 | TAK / PTGX | Takeda / Protagonist (~$8.75B) | Rusfertide, polycythemia vera | NDA, Priority (**E — "Q3 2026" only; the prior "~09/30" was inferred, never published**) | Takeda/PTGX PR 2026-03-02 |
| Q3 2026 | ROIV | Roivant (~$20.5B) | Brepocitinib, dermatomyositis | NDA, Priority (**E — "Q3 2026" only; the company's "end of September" figure is a *launch* expectation, not the PDUFA date**) | Priovant/Roivant 8-K 2026-03-03 |
| 2026-10-10 | MRK | Merck (w/ Daiichi) | Ifinatamab deruxtecan, ES-SCLC | BLA, Priority (C) | Merck PR 2026-04-13 |
| 2026-10-17 | VTRS | Viatris | MR-141, presbyopia | sNDA (C) | Viatris PR 2026-02-25 |
| 2026-11-14 | SMMT | Summit | Ivonescimab + chemo, 2L+ EGFRm NSCLC | BLA (C) | Summit PR 2026-01-29 |
| 2026-11-25 | SNY | Sanofi (ADR) | Venglustat, Type 3 Gaucher | NDA, Priority (C — **NEW**) | sanofi.com PR 2026-05-28 |
| 2026-11-27 | BBIO | BridgeBio (~$15.7B) | BBP-418, LGMD 2i/R9 | NDA, Priority, no adcomm planned (C) | BridgeBio PR 2026-05-27 |
| 2026-11-27 | NUVL | Nuvalent (~$9.8B) | Neladalkib, ALK+ NSCLC | NDA, Priority (C) | Nuvalent PR 2026-05-27 |
| 2026-11-30 | COGT | Cogent (~$6.7B) | Bezuclastinib **+ sunitinib, GIST** | NDA, Priority (C — **INDICATION CORRECTED**, see below) | Cogent PR 2026-05-28 |
| 2026-11-30 | VRTX | Vertex | Povetacicept, IgA nephropathy | BLA, accelerated (C) | Vertex PR 2026-06-01 |
| 2026-12-03 | EXEL | Exelixis | Zanzalintinib + atezolizumab, mCRC | NDA, standard (C) | Exelixis PR 2026-02-02 |
| 2026-12-23 | GILD | Gilead (via Arcellx) | Anito-cel, 4L r/r multiple myeloma | BLA (C — **NEW**) | Gilead PR 2026-02-23 |
| 2026-12-27 | PRAX | Praxis (~$9.1B) | Relutrigine, DEE | NDA, Priority (C — moved from 9/27 on a 3-month major-amendment extension) | Praxis PR 2026-06-29 |
| 2026-12-27 | VTRS | Viatris | MR-107A-02 meloxicam, acute pain | NDA (C) | Viatris PR 2026-05-18 |
| 2026-12-30 | COGT | Cogent | Bezuclastinib, **Non-Advanced SM** | NDA, Priority (C) | Cogent PR 2026-03-16 |
| 2027-01-04 | NUVB | Nuvation Bio (~$2.0–2.6B, **borderline floor**) | IBTROZI (taletrectinib), ROS1+ NSCLC — DOR update | sNDA (C — **NEW**) | Nuvation Bio PR 2026-05-06 |

**Resolved / corrected / excluded this pass:**
- **VTRS MR-100A-01 contraceptive patch — APPROVED 2026-07-29** (a day ahead of its 7/30 PDUFA), branded **Gwyn Lo™**. Removed from the pending calendar.
- **COGT indication correction (material).** The 2026-11-30 Priority date belongs to **bezuclastinib + sunitinib in GIST**, *not* Advanced Systemic Mastocytosis as the baseline recorded. The **AdvSM** NDA was only submitted 2026-06-30, has **not yet been accepted by FDA, and carries no PDUFA date**. AdvSM is therefore not a dated catalyst and is tracked as pending-acceptance only.
- **Three baseline entries lose their day-level precision** — REGN garetosmab ("August 2026"), TAK/PTGX rusfertide and ROIV brepocitinib (both "Q3 2026"). None of these day-level dates was ever published by the sponsor; the prior file's "~08/31" and "~09/30" were inferred from period-end. Re-labelled (E).
- **Sub-floor / non-US sponsors excluded (verified this pass):** Savara/molgramostim (~$1.03B; and its date moved to 2026-11-22, not the 12/12 an aggregator carried), Vanda/imsidolimab (~$306M — independently re-confirms the prior pass's drop), Deciphera/tirabrutinib (sponsor is **Ono Pharmaceutical**, Tokyo-listed with no US listing — fails the US-listed test, not merely the cap test), Beren/adrabetadex (private), Pierre Fabre/tabelecleucel (private), INOVIO (unverified cap, likely sub-floor).
- **Previously-dropped entries NOT reintroduced**, per instruction: VRTX Journavx "12/5", Novo Nordisk "9/30", ANAB/VNDA imsidolimab "12/12".
- **No FDA advisory committee meeting with a ≥$2B sponsor is scheduled 2026-08-03 → 2026-11-03.** Contextual: FDA has convened seven adcomms this administration versus 22 in the comparable prior period, and 2026 PDUFA-acceptance releases repeatedly state "FDA does not currently plan to hold an advisory committee meeting." Adcomms in this environment are typically announced only 4–6 weeks ahead, so re-check nearer each date.

**Structural-regulatory (non-FDA):**

| Ticker | Matter | Status | Source |
|--------|--------|--------|--------|
| GOOGL | Ad-tech remedies, EDVA (DOJ sought AdX divestiture), Judge Brinkema | **Effectively OUT of the 6-month window** — at closing arguments the judge told the parties **no decision should be expected until 2027**. No ruling date set. | National Law Review 2026-07-15 |
| GOOGL | Search remedies, DC Circuit cross-appeals (#26-5023, cons. 26-5047/26-5049) | **"ORAL ARGUMENT NOT YET SCHEDULED"** on the DOJ's own 2026-07-28 brief. Briefing: Google reply 2026-09-29, final briefs 2026-10-29. Argument informally projected late-2026/early-2027 by commentators, **not court-set**. | justice.gov/atr filing 2026-07-28; Courthouse News 2026-07-29 |

### 1A.5 — Restructuring / structural events (M&A, spin-offs)

| Ticker | Name | Catalyst | Date | Source |
|--------|------|----------|------|--------|
| EA | Electronic Arts | $55B take-private (PIF 93.4% / Silver Lake 5.5% / Affinity 1.1%) — **ALL regulatory approvals obtained as of 2026-07-30, CFIUS cleared**; largest LBO ever | **expected to close on/about 2026-08-04 (C)** — i.e. resolving the day after this run | EA 8-K 2026-07-30 |
| WBD / PSKY | Warner Bros. Discovery / Paramount Skydance | $31.00/sh acquisition. Under the **2026-07-24 stipulation** Paramount agreed **not to close before 2027-06-01** (or resolution of the merits); in exchange the state-AG and WGA **preliminary-injunction motions set for 2026-08-03 were withdrawn — that hearing did not occur.** DOJ Antitrust separately cleared the deal on competition grounds without divestitures. | no close before 2027-06-01 (C); **merits trial date UNRESOLVED** — companies propose 2026-11-04, state AGs/WGA propose 2027-04-05 | Variety / CNBC / Deadline 2026-07-24; Law Commentary |
| AZN / BMY | AstraZeneca / Bristol Myers Squibb | FT reported AstraZeneca has explored a combination with BMY; combined value ~**$400B**. AZN declined comment; BMY did not respond. Talks described as ongoing "in recent months," and could "materialise soon, but could also be delayed or fall apart." | reported 2026-08-02 (T — **talks only, unconfirmed as a transaction**) | FT via Reuters/CNBC 2026-08-02 |
| ICE / MKTX | Intercontinental Exchange / MarketAxess | ~$6B equity-value acquisition of the institutional fixed-income electronic trading platform | announced 2026-07-30 (C — **NEW**) | WSJ 2026-07-30 |
| UBER | Uber | Delivery Hero acquisition — €41.50/sh cash (~$14.8B); SSW Partners takes 14 overlap markets; Prosus (~17%) irrevocably committed | **completion expected H2 2027** (C, per Uber's own deck); no new milestone in the evidence window | Uber IR / Bloomberg Law |
| UNP / NSC | Union Pacific / Norfolk Southern | STB review — the **2026-07-27 supplemental-information deadline was met**; UP/NS filed customer-protection commitments plus a binding UP–CN agreement transferring NS's TRRA / Kansas City Terminal interests to CN. Proceeding remains in **abeyance** pending the EIS process (12+ public meetings planned). | close **expected mid-2027** (C) | stb.gov; UP press release 2026-07-27 |
| CMCSA | Comcast | Tax-free spin-off of NBCUniversal / Sky | ~mid-2027 (E — **carried, NOT re-verified this cycle**) | Comcast PR (prior cycle) |
| KDP | Keurig Dr Pepper | Coffee / Beverage split (post-JDE Peet's); Starboard activist backdrop | early 2027 (T — **carried, NOT re-verified this cycle**) | prior cycle |

---

## PART 1B — Strategy C universe catalyst calendar (45-day window, 2026-08-03 → 2026-09-17)

C's qualifying event types **only**: corporate earnings (company IR), FDA PDUFA (FDA calendar / company disclosure), FOMC (Fed calendar). No interpretation. **Router reminder: only an FOMC-catalyst thesis is router-eligible this cycle (HYBRID ACTIVATE, FOMC-only); every earnings and FDA entry below is router-PARKED and is divergence context, not actionable.**

### 1B.1 — FOMC

| Event | Catalyst | Date | Source |
|-------|----------|------|--------|
| **FOMC** | Federal Open Market Committee decision — meeting **2026-09-15/16**, decision day **Wednesday 2026-09-16**, **WITH Summary of Economic Projections / dot plot** | **2026-09-16 (C)** — the **only** FOMC decision inside the 45-day window | federalreserve.gov/monetarypolicy/fomccalendars.htm |

Remaining 2026–27 meetings, for reference: 2026-10-27/28 (no SEP), 2026-12-08/09 (SEP), 2027-01-26/27 (no SEP). **The 2026-07-29 meeting has RESOLVED** — held at 3.50–3.75% on a 9–3 vote with three dissents for a hike (Logan, Kashkari, Hammack), the first three-dissent vote since 2016.

**Dated macro releases inside the window that bear on the 9/16 decision** (context for a C thesis, not themselves C-qualifying events): **July payrolls Friday 2026-08-07**; July CPI and PPI mid-August; **FOMC minutes ~2026-08-19**; **Jackson Hole 2026-08-27 → 08-29**; August payrolls ~2026-09-04; August CPI ~mid-September — i.e. two full payroll prints and two CPI prints land between this file and the decision.

### 1B.2 — Corporate earnings inside the 45-day window

Same dated set as PART 1A.1 on/before 2026-09-17: AMD/PFE/MRK/CAT **(all C)** 8/4 · DIS/SHOP/UBER/LLY **(all C)** 8/5 · DDOG **(C)** 8/6 · SMCI **(C)** 8/11 · CSCO **(C)** 8/12 · DE (T) 8/13-or-8/20 · HD **(C)** 8/18 · TGT **(C)** / LOW 8/19 · WMT **(C)** 8/20 · OKTA **(C)** / NVDA **(C)** / SNOW (E) 8/26 · WDAY **(C)** / MRVL (E) 8/27 · CRWD (E) / PANW **(C)** / ZS (E) 9/1 · AVGO **(C)** / NTAP **(C)** / HPE (E) / CRM (E) 9/2 · DELL (T) 9/3-or-8/27 · ORCL (T) 9/8-or-9/9-or-9/14 · ADBE (E) 9/10 · FDX (E) 9/17. Sources per 1A.1.

### 1B.3 — FDA PDUFA (sponsors ≥ $2B) inside the 45-day window

| Date | Ticker | Company | Drug / indication | Event | Source |
|------|--------|---------|-------------------|-------|--------|
| 2026-08-05 | MRNA | Moderna | mRNA-1010 seasonal flu (VRBPAC 9-0) | BLA action (C) | Moderna PR |
| 2026-08-13 | LNTH | Lantheus (~$6.5–7.0B) | MK-6240 tau-PET | NDA action (C) | Lantheus PR |
| 2026-08-17 | BMY | Bristol Myers Squibb | Iberdomide, r/r multiple myeloma | NDA, Priority (C) | BMS PR |
| 2026-08-23 | RARE | Ultragenyx (~$2.46B) | DTX401, GSD-Ia | BLA, Priority (C) | Ultragenyx 8-K |
| 2026-08-25 | JAZZ | Jazz Pharma | Ziihera, 1L HER2+ gastric/GEJ | sBLA, Priority (C) | Jazz PR |
| 2026-08-27 | GILD | Gilead | Bictegravir/lenacapavir HIV | NDA, Priority (C) | Gilead PR |
| August 2026 | REGN | Regeneron | Garetosmab, FOP | BLA, Priority (E — no day-level date) | Regeneron PR |
| 2026-09-11 | TLX | Telix (~$3.4B) | TLX101-Px, recurrent glioma | NDA (C — upgraded this pass) | Telix PR 2026-04-10 |

**Possibly in-window but undated:** TAK/PTGX rusfertide and ROIV brepocitinib both carry "Q3 2026" PDUFA goals with no published day — either may or may not fall on/before 9/17. Not rankable as dated events.

**Just outside the boundary:** RARE UX111 Sanfilippo A, 2026-09-19 (two days past). **Resolved since the last cycle:** VTRS MR-100A-01 approved 2026-07-29.

---

## PART 2A — Strategy A preliminary ranked shortlist (44 candidates)

W4 reads this section verbatim.

**ROUTING — read this before the table. Two gates now apply to A, not one.** (i) **Router:** A = DO-NOT-ACTIVATE (operative), so every top-tier name below routes to the `Watchlist.md` A-queue with reason "router gate; queued for next M1 ACTIVATE" — **no thesis-construction is enqueued this cycle.** (ii) **Capital:** A is *also* capital-disabled with **NAV $0.00** and an outstanding regime-capital debt of $1,889.37, so even a hypothetical router flip has to restore funding before any entry is fundable. The restore is mechanical on `trigger=regime_enable`, so the two gates lift together — but a reader must not infer from the router gate alone that capital is sitting ready. **`div-A-202607-1` (due 2026-08-04) is the live resolution path for both.**

Rankings are still explicit so the queue is ordered by conviction of narrative-misalignment when the router next flips. Per candidate: (a) hypothesized mispricing direction, (b) supporting public documents, (c) catalyst date, (d) overlap with open positions / A-queue, (e) tier. Direction is a *preliminary* synthesis hypothesis — full thesis construction (adversarial counter-argument attacking **size as well as direction** per Experiment_Parameters rev 18, immutable at-entry targets per Strategy.md Entry criterion 3) happens in W4-scheduled sessions.

**MEASUREMENT NOTE — analyst price targets are UNAVAILABLE this cycle, and no remembered figure is carried.** The W30 file leaned on "PT consensus $X" in most rows. Both FMP routes (`analyst` price-target-consensus and the `tipranks` summary) returned plan-quota "Rate limit reached" for every symbol this session. Per the extraction discipline, **no price target appears anywhere below** — carrying forward a remembered consensus would be exactly the fabrication the rule forbids. The observable substitutes used instead are **% off the 52-week high** and **implied-volatility percentile**, both read live from IBKR. All prices are **IBKR intraday snapshots taken 2026-08-03 ~16:09–16:24 UTC — today's session had NOT closed when this file was written**, so they are not closes and must not be treated as such.

**This cycle's re-ranking theme: the payer-vs-receiver split RESOLVED, and it resolved against the receivers.** The W30 file's central read was that the tape was punishing the AI-capex *payers* while the *receivers* held up. One week of prints inverted it. The two largest capex payers printed monetization that validated the spend and were rewarded — **MSFT** Azure +43% / total cloud +27% to $59.3B → **+8.5%**, and **AMZN** AWS +36.7% YoY, the fastest in 18 quarters, with AI run-rate >$25B → **+15.32%**. Meanwhile the *receivers* got the punishment: **SOX −4.30% on the week and >−20% for July, its worst month since October 2008.** So the misalignment has not closed — it has **migrated**. It is no longer "hyperscalers versus their own capex"; it is now **"semiconductors versus the hyperscaler capex documents that just validated their demand."** NVDA, which has not yet printed, is the largest unresolved instance (FQ2 8/26). Two W30 counter-signals in this cohort are **withdrawn**: the Fubon Rubin-redesign note is a refuted year-old report (see 1A.2), and AMD's MI400 has already shipped, converting a roadmap promise into visible execution.

**The honest counter-case is macro and it strengthened this week, in both directions.** Against the cohort: the 30Y at **5.21%**, highest since 2007, with a 56–62% September hike priced and a 9–3 FOMC that dissented *toward* tightening — long-duration growth multiples are newly rate-exposed. Also against: China's NBS manufacturing PMI at **49.2**, its first contraction since February. *For* the cohort, and cutting against M1a's decelerating-growth axis: **ISM Manufacturing printed 55.6 this morning versus 53.3 prior, the fastest expansion in over four years.** Adjudicating that tension is thesis-construction's job, not this shortlist's.

### TOP-10

| # | Ticker | Direction | Supporting public documents | Catalyst (date) | Overlap |
|---|--------|-----------|------------------------------|-----------------|---------|
| 1 | NVDA | Bullish | The demand documents strengthened at *third-party print level* this week — MSFT Azure +43% and AMZN AWS +36.7% (fastest in 18 quarters, AI run-rate >$25B) are the two largest customers' own disclosures. NVDA has **not yet printed** and sits at $207.01, **−12.5% off its 52-week high**, having survived SOX's worst month since Oct-2008. **The W30 "Rubin redesign" counter-signal is WITHDRAWN** — that Fubon note is dated 2025-08-14, NVIDIA called it "incorrect" at the time, and Rubin entered full production in Jan-2026 on schedule. IV %ile 74.8% | **FQ2 earnings 2026-08-26 (C)**; Rubin volume availability H2 2026 | A-queue |
| 2 | MRVL | Bullish | Same capex-receiver read-through as #1 via custom-ASIC; at $190.22 it is **−42.3% off its 52-week high** with **IV %ile 95.2%** — the derate is deepest exactly where the hyperscaler documents are strongest. Prior FQ1 record $2.418B + accelerating guide unrefuted by any subsequent disclosure | FQ2 earnings ~2026-08-27 (E) | A-queue |
| 3 | AMD | Bullish | **MI400 (MI455X/MI430X, CDNA5) LAUNCHED 2026-07-23** at Advancing AI 2026 — roadmap risk converted to shipped product, and the print lands **tomorrow**. $480.20, −17.9% off high, IV %ile 92.8%; options imply a **~12.3%** move | **Q2 earnings 2026-08-04 (C)** | A-queue |
| 4 | INTC | Bullish | The 7/23 print — rev $16.1B **+25% YoY, fastest since 2011**, DC/AI +59%, GM back to 42%, capex raised >$20B, management "cannot keep up with orders" — remains **unrefuted by any subsequent disclosure**, and the stock is **LOWER now ($90.54) than at the W30 read ($92.32)**. The documents-vs-tape gap widened rather than closed. −36.4% off high | Q3 earnings ~2026-10-22 (E); Nova Lake-S now Q1–Q3 2027 (T, leak-only) | A-queue (5/12) |
| 5 | MU | Bullish — PROMOTED | **New third-party document this week:** QCOM's FQ4 guide-down explicitly cited *"unprecedented increases in memory pricing"* as a cost driver — a customer's own disclosure evidencing memory pricing power, which is the load-bearing leg of the MU thesis. FQ3 blowout + FQ4 guide 15–22% above Street still unrefuted. $816.59, −34.9% off high, IV %ile 81.2% | FQ4 earnings 2026-09-22 / 09-23 / 09-29 (T — 3-way conflict unresolved) | A-queue |
| 6 | ORCL | Bullish (deep re-base) | FQ4 RPO + multi-year OCI bookings per the 10-K, against a **−59.8% drawdown from the 52-week high** ($137.98 vs $343.05) — the largest documents-vs-price gap in the entire shortlist. IV %ile 77.6%. Date risk is real: FQ1 is a **3-way conflict** | FQ1 earnings 2026-09-08 / 09-09 / 09-14 (T); AI World 10/25–28 | A-queue (5/9) |
| 7 | AVGO | Bullish | Custom-AI ASIC pipeline + VMware EBITDA per the FQ2 print; same capex-receiver cohort as #1/#2/#3. **Date now company-confirmed 9/2** (was a 9/2-vs-9/3 conflict). $388.24, −21.6% off high, IV %ile 84.0% | FQ3 earnings 2026-09-02 (C) | A-queue (5/9) |
| 8 | INTU | Bullish | 10-K GenAI attach; at $321.73 the stock is **−59.2% off its 52-week high** with **IV %ile 99.2%**, into a *dated, company-confirmed* Investor Day — an unusual combination of maximum implied uncertainty and a fixed disclosure event | **Investor Day 2026-09-17 (C)** | — |
| 9 | META | Bullish — REFRAMED, not carried | **The W30 bullish thesis was REFUTED at print** (EPS $6.18 vs $7.19 est on $2.40B legal + $1.18B layoff charges, −9%). What replaces it is a *different* setup: the charges are now disclosed rather than feared, revenue still beat at $60.80B (+28%), the Iris training chip enters production in September, and the stock is **−25.4% off its 52-week high**. This is a new thesis requiring independent construction — it does **not** inherit the W30 rationale | Q2 print PASSED; Iris production Sept 2026 (E); Q4 earnings 2027-01-27 (E) | A-queue (7/5) |
| 10 | DELL | Bullish | AI-server backlog conversion per the FQ1 blowout; $417.85, −11.0% off high, but **IV %ile 100%** — implied uncertainty at its 52-week ceiling into a date that is itself contested | FQ2 earnings 2026-09-03 **or** 08-27 (T — new conflict) | A-queue (5/17) |

### 11–20

| # | Ticker | Direction | Supporting public documents | Catalyst (date) | Overlap |
|---|--------|-----------|------------------------------|-----------------|---------|
| 11 | SMCI | Bullish (high-risk) | FQ4 preliminary release raised the GM guide to 15–17% (from 8.2–8.4%) with >$60B new orders (management non-firm/cancellation caveat). $28.51, **−52.0% off high**, IV %ile 95.6%; options imply **~18.6%**, above the 4-quarter average of 16.9% | **FQ4 earnings 2026-08-11 (C)** | A-queue (5/29); B NO-GO 7/22 = context |
| 12 | NOW | Bullish | Q2 7/22 beat-raise (subscription rev +24.5%, cRPO +21.5%, FY26 guide raised) — yet $115.12 is **−40.9% off the 52-week high**. The print ratified the thesis and the tape has since de-rated it hard | Q3 earnings ~2026-10-21 (E) | A-queue (5/29) |
| 13 | CRM | Bullish | Agentforce / cRPO per the 10-Q; Dreamforce is a dated disclosure event. $189.02, −29.6% off high, IV %ile 86.4% | FQ2 earnings ~2026-09-02 (E); **Dreamforce 09-15/17 (C)** | A-queue (5/17) + **open D position** (correlation check) |
| 14 | PANW | Bullish | Platformization + CyberArk per the FQ3 print; **date MOVED to 9/1 (C)** from the ~8/17 the W30 file carried — a two-week slip that changes the catalyst's position in the window. IV %ile 96.4% | FQ4 earnings 2026-09-01 (C — moved) | A-queue (5/31) |
| 15 | CRWD | Bullish | Falcon Flex + Charlotte AI net-new-ARR; **IV %ile 99.2%** at only −9.0% off the high — implied uncertainty near its ceiling on a name trading near its highs | FQ2 earnings ~2026-09-01 (E) | A-queue (5/31) |
| 16 | NBIS | Bullish (high-vol) | $775M GPU-infrastructure debt (7/17) funding a documented buildout; **+13.81% today** to $216.71, −27.7% off high, **IV 140.9%** — the highest-vol name in the shortlist; neocloud-unwind risk is the live counter | Q2 earnings ~Aug 2026 (E) | A-queue (5/13) |
| 17 | SNOW | Bullish | FQ1 print + the $6B AWS commitment; **+7.36% today** and trading at/through its recorded 52-week high (the IBKR 52w stat lags today's tick), IV %ile 88.0% — thesis-runway compression is the counter, not the documents | FQ2 earnings 2026-08-26 (E) | A-queue (5/25) |
| 18 | HPE | Bullish | FQ2 print (+29–37% AH) on AI-server + GreenLake; $49.19, −23.4% off high, **IV %ile 99.2%** | FQ3 earnings ~2026-09-02 (E) | A-queue (5/29) |
| 19 | OKTA | Bullish | Agentic-AI identity/security adoption cohort; **date CONFLICT RESOLVED to 8/26 (C)** by Okta's own 8/1 release — the W30 file's 8/25-vs-9/2 pair was wrong on both. **IV %ile 100%** at −8.2% off high | FQ2 earnings 2026-08-26 (C — resolved) | A-queue (5/29) |
| 20 | CSCO | Bullish | FQ3 print (AI-infra orders $9B, third consecutive guide raise); $115.34, −11.5% off high, IV %ile 95.6%; options imply ~5–8% (sources conflict; 8-quarter median realized move 3.0%) | FQ4 earnings 2026-08-12 (C) | A-queue (5/9) |

### 21–44 (rest tier)

| # | Ticker | Direction | Supporting public documents | Catalyst (date) | Overlap |
|---|--------|-----------|------------------------------|-----------------|---------|
| 21 | MSFT | Bullish — **REALIZED at print, demoted from #2** | Azure +43%, total cloud +27% to $59.3B, rev $90.01B / EPS $4.74 both beat → **+8.5%**. The W30 misalignment (price-vs-documents gap) **closed at the print**; $487.27 is now only −11.6% off high. A fresh entry needs a new thesis, not this one | Q3/FQ1 earnings ~2026-10-27→10-30 (E); Ignite 11/17–20 | A-queue (7/5) |
| 22 | AMZN | Bullish — **REALIZED at print, demoted from #7** | AWS +36.7% YoY (fastest in 18 quarters), rev $200.6B (+20%) beat → **+15.32% to $271.58** on 7/31, $284.37 today, at/through its recorded 52-week high. Thesis played out; re-entry needs independent construction | Q3 earnings ~2026-10-29 (E); re:Invent 12/1–4 | A-queue (7/12) + **open D ×2** (correlation check) |
| 23 | GOOGL | Bullish — **REALIZED, demoted from #3** | The W30 divergence was the post-print capex selloff; it has **fully retraced** — $374.80, +5.24% today, −8.3% off high. Ad-tech remedies ruling is now **out of the window** (no decision before 2027, per the judge) | Made-by-Google 2026-08-12 (C); Q4 earnings ~2027-02-02/03 (E) | A-queue (7/5) + **open D ×2** (correlation check) |
| 24 | AAPL | Direction SUSPENDED — **thesis refuted at print** | Beat both lines, Cook called it the "strongest June quarter," but soft forward guidance drove **−7.4% Friday, its worst day in a year**, and −1.51% again today to $304.25. The W30 "anomalously cheap implied move into a CEO-transition print" framing resolved *against* the long. IV 25.2% is still the lowest in the mega-cap set | Fall event ~2026-09-09 (T — no invite as of 8/2); FQ1 earnings ~2027-01-28/29 (E) | A-queue (7/5) |
| 25 | TSM | Bullish — **ELIGIBILITY UNRESOLVED, deliberately not top-tier** | FY26 growth guide >40% + raised capex unchanged; $403.61, −15.7% off high. **Strategy A's instrument rule requires US-listed COMMON EQUITY and TSM is an ADR** — W4 must resolve eligibility *before* any activation, so it is held out of the top tier rather than ranked into it. Also: the 7/30 +7.66% was a sector rally, **not** an earnings move | Q3 earnings ~2026-10-15 (E) | **open D ×2** (correlation check) + A-queue |
| 26 | QCOM | Bearish — **RATIFIED at print** | FQ4 guide $2.05 vs $2.35 street, citing "unprecedented increases in memory pricing" and cyclical handset headwinds → −2.7%. The W30 bearish-lean landed; $149.31 is −42.6% off high. Thesis largely realized — and its own guide-down is the bull document for #5 | Q1 earnings ~2026-11 (E) | A-queue (5/1) |
| 27 | GEV | Bullish | Q2 7/22: rev $11.1B +22%, orders +88% to $24.2B, backlog $176B incl. 116GW gas-power reservations, >$5B 2026 data-center orders, FY26 guides raised — the AI-power-demand document set. $998.99, −16.4% off high | Q3 earnings ~2026-10-21 (E) | **open D position (new 8/3)** — correlation check; `research-deferral-GEV-D-20260809` queued |
| 28 | DIS | Bullish (contested) | FQ3 print is **2026-08-05 BMO (C, upgraded)** and is the single largest dated thesis risk in the open book — three of the D position's five invalidation criteria are mechanism-enforced at exactly this print. $97.63, −17.9% off high; options imply ~6.3% | **FQ3 earnings 2026-08-05 (C)** | **open D position** (correlation check; largest D drawdown) |
| 29 | LMT | Bullish | Q2 7/23: sales +11%, EPS $7.94, FCF $2.9B, FY26 guide raised, record $230B backlog incl. $35B THAAD multiyear. $579.57, −16.3% off high, but **IV %ile 41.2%** — the lowest-implied-uncertainty name in the top half. Counter: the 8/2 strike stand-down cuts against a defense-demand narrative | Q3 earnings ~2026-10-20 (E) | — |
| 30 | BA | Bullish (recovery) | Q2 7/28 rev $24.6B (+8%) beat with core EPS loss wider than est; FCF +$631M ahead of guide; backlog $715B. **+4.75% today** to $226.40. Reaction reports conflicted (+3.0% / +1.2% / −2.2%) and are recorded unreconciled | Q3 earnings ~2026-10 (E) | D NO-GO 2026-08-03 (criterion 2) = context |
| 31 | MRK | Bullish | Stacked *dated* pipeline catalysts against the Keytruda-LOE-2028 fear: Winrevair sBLA **9/21 (C)** and I-DXd **10/10 (C)**. $127.47, −5.6% off high, IV %ile 87.2% | Q2 earnings 2026-08-04 (C); PDUFAs 9/21 + 10/10 | A-queue |
| 32 | UBER | Bullish | Delivery Hero acquisition (€41.50/sh, ~$14.8B) — **completion now stated H2 2027**, materially later than the W30 read implied; $71.19, −30.2% off high; options imply ~8.3% into the 8/5 print | **Q2 earnings 2026-08-05 (C)**; deal close H2 2027 | **open D position** (correlation check) |
| 33 | VRTX | Bullish (non-AI diversifier) | Povetacicept IgAN BLA **11/30 (C)** stands as the anchor catalyst; **IV %ile 98.4%**. The Journavx "12/5" entry stays dropped — it failed primary-source verification twice and was not reintroduced | Povetacicept BLA 2026-11-30 (C) | A-queue (7/5) |
| 34 | NTAP | Bullish | DataPelago acquisition (GPU-accelerated data processing); FQ1 date company-stated; **IV %ile 99.2%** at only −5.2% off high | FQ1 earnings 2026-09-02 (C) | A-queue (5/29) |
| 35 | WMT | Bullish | $110.43, −18.3% off high with **IV %ile 96.0%** into a company-confirmed print. The 5/22 A-queue note recorded the tariff-pass-through thesis as *not decisively supported* at the prior print — that caveat stands and is not resolved here | Q2 FY27 earnings 2026-08-20 (C) | A-queue (5/9) |
| 36 | UNP | Bullish (structural) | STB supplemental filing **made 7/27**, with new customer-protection commitments and a binding UP–CN terminal-interest transfer resolving one flagged issue; proceeding in abeyance, close expected **mid-2027**. $290.66, −8.0% off high | Q3 earnings ~2026-10-22 (E); STB process ongoing | — |
| 37 | HD | Bullish/neutral — NEW to shortlist | Print date newly company-confirmed; the 5/20 A-queue note recorded the bearish housing-turnover thesis as only modestly supported at the prior print (comps +0.6%, guide reaffirmed, −2.5%). Direction genuinely unresolved | **Q2 earnings 2026-08-18 (C)** | A-queue (5/9) |
| 38 | TGT | Direction SUSPENDED — documentation row | The queued bearish thesis was **refuted** at the prior print (comps +6%, adj EPS $1.71 vs $1.46, FY sales-growth target doubled to 4%). **+3.14% today**, trading at/through its recorded 52-week high. Recommend framing-flip or demotion at the next M1 ACTIVATE, per the standing 5/22 note | Q2 earnings 2026-08-19 (C) | A-queue (5/9) |
| 39 | IBM | Direction SUSPENDED — documentation row | The 7/22 official print confirmed the pre-announced miss and added nothing new. $226.86, −31.7% off high. A-queue disposition for M1 to re-rank | Q3 earnings ~2026-10-20 (E) | A-queue (5/29) |
| 40 | TSLA | Bearish — **RATIFIED, documentation row** | Q2 7/22 landed every bearish leg (GAAP EPS $0.32 miss, op income −57%, op margin 1.4%, first negative FCF in 2+ years on record $5.79B capex). $323.73, −35.1% off high. Thesis realized; a fresh entry needs a new thesis at Q3 | Q3 earnings ~2026-10-21 (E) | direction realized |
| 41 | PLTR | Bearish-lean | Extreme multiple vs 10-Q commercial AIP; $125.12, −39.7% off high, IV %ile 96.8%; options imply **~11.4%** into tonight's print. **Reports 2026-08-03 AMC — after this file**, so the adjudication is D1/W2's, not W1's | **Q2 earnings 2026-08-03 AMC (C)** | — |
| 42 | ADBE | Bearish | Creative Cloud deceleration + Firefly lag; $253.68, −31.6% off high — substantially realized | FQ3 earnings 2026-09-10 (E); MAX 11/10–12 | A-queue (5/9) |
| 43 | GM | Bullish (ratified) | Q2 beat + FY guide raised a second consecutive quarter; $87.86, −4.3% off high. Catalyst passed; next leg is Q3 | Q3 earnings ~2026-10-20 (E) | — |
| 44 | VZ | Bullish (ratified) | Q2 EPS beat + FY EPS guide raised a second time + buyback expanded to $4.5B + $1B+ Google dark-fiber AI deal; $47.46, −6.8% off high. Catalyst passed | Q3 earnings ~2026-10-21 (E) | — |

**Priority-tier summary.** **Top-10** = NVDA, MRVL, AMD, INTC, MU, ORCL, AVGO, INTU, META, DELL — the misalignment has concentrated in **semiconductors and the deeply de-rated software/infrastructure names**, because that is where the hyperscaler prints strengthened the demand documents while the tape sold the cohort through SOX's worst month since October 2008. **11–20** = the second-tier AI-infrastructure and security cohort, several carrying IV percentiles at or near their 52-week ceilings (OKTA and DELL at 100%, CRWD and HPE at 99.2%). **Rest** = the four mega-caps whose theses **resolved at print this week** (MSFT and AMZN ratified, META and AAPL refuted — all four demoted precisely because they resolved), the eligibility-blocked ADR (TSM), ratified-and-passed prints awaiting their next leg, and the realized bear calls.

**Changes vs 2026-W30:** NVDA #1→#1 (counter-signal withdrawn, demand documents strengthened); MSFT #2→#21, GOOGL #3→#23, AMZN #7→#22, AAPL #11→#24, META #6→#9 (all four adjudicated at print — two ratified, two refuted); MRVL #9→#2, AMD #4→#3, INTC #8→#4, MU #12→#5 (promoted on QCOM's guide-down as a memory-pricing document), ORCL #15→#6, INTU #31→#8; TSM #5→#25 on the unresolved ADR eligibility question; QCOM #20→#26 (bearish ratified); HD added; NOW #10→#12; SMCI #24→#11. **Dropped from the shortlist:** ISRG and MDT (already excluded), plus **MSCI, FTV and MTZ newly excluded** — all three are open Strategy B positions and A/B same-name simultaneous holding is prohibited. **Universe count 46 → 44.**

---

## PART 2B — Strategy C preliminary ranked shortlist (12 event candidates)

W4 reads this section verbatim. **CRITICAL ROUTER GATE: C = HYBRID ACTIVATE (FOMC-only). Only candidate #1 (FOMC 2026-09-16) is router-eligible for a new C entry. Candidates #2–#12 are router-PARKED (DO-NOT-ACTIVATE) — divergence context only; W4 must NOT enqueue thesis-construction for them.**

**SIZING — the W30 file's per-structure budget was retired-2% contamination and is corrected here.** That file stated a "2%-of-strategy max-loss budget ≈ $46.29 per structure." The flat 2% rule was **retired** by Experiment_Parameters rev 18 / Strategy.md Rev 43 (owner directive 2026-07-28); `analytics.strategy_nav.sizing_base_2pct` is explicitly a **legacy reference column, not the budget**. The governing constraints are now: the **AI-chosen risk budget per thesis**, justified against the seven-factor list and adversarially attacked **on size as well as direction**, bounded by the hard envelopes **per-name CaR ≤10%** and **per-strategy deployed CaR ≤75%**. On C NAV $2,314.48 (`analytics.strategy_nav`) that is a **per-name ceiling of $231.45** and a deployed ceiling of $1,735.86 — roughly **5× the figure the W30 file screened against**, which changes executability verdicts rather than merely their wording. For Strategy C specifically, CaR is `max_loss` inclusive of the bounded early-assignment cascade, dual-path verified by `c_options_math.py` — **exact, not assumed** — which per factor 3 supports a larger budget than open-ended equity downside at equal conviction. *(SL2 flagged this same retired-2% contamination class repo-wide on 2026-07-30; this is one instance of it.)*

**Option-chain data is UNAVAILABLE this session and no constructibility claim is asserted.** IBKR `get_option_data` returned "Error invoking method" on every attempt across five retries and multiple symbols (`get_option_parameters` worked normally, so expiration lists below are solid; strike-level bid/ask/premium is not). **No strike spacing or premium appears below**, and no spread is claimed constructible or non-constructible — that verification belongs to D2 at thesis time under Strategy C entry criterion 4's dual-path max-loss requirement. What *can* be said is that the corrected envelope no longer excludes these names on size the way the $46 figure did.

**Overlap with open A positions: none open → no A/C conflict on any candidate.** *(NAV read: `analytics.strategy_nav` engine is through 2026-07-31 and was flagged stale in an 8/3 interactive session; the envelope figures above move with it.)*

| # | Event (ticker) | Type | Date | Hypothesized divergence (direction) | Supporting public documents | Executable within the CaR envelope? | Router / tier |
|---|----------------|------|------|--------------------------------------|------------------------------|--------------------------|---------------|
| 1 | **FOMC** | FOMC | **2026-09-16 (C)** | **A genuinely two-sided, unadjudicated event — and the first router-eligible C candidate in several cycles that is not encumbered by a standing NO-GO.** The 7/29 meeting held 3.50–3.75% on a **9–3 vote with three dissents FOR A HIKE** (Logan, Kashkari, Hammack) — the first three-dissent vote since 2016 — and September carries a **dot plot**. Market-implied hike odds are **56–62%** across the venues checkable today (Kalshi 56%, Polymarket 60%, RateProbability 62%); the ~82% CME figure the W30 file carried is a 2026-07-23 read and is **not currently verifiable**. Direction is genuinely ambiguous and the inputs are dated: **two payrolls (8/07, ~9/04) and two CPI prints land before the decision**, plus minutes ~8/19 and Jackson Hole 8/27–29 | federalreserve.gov FOMC calendar + 7/29 statement/vote; Kalshi / Polymarket / RateProbability 2026-08-03; 30Y 5.21% (highest since 2007); June core PCE +3.3% YoY; ISM Manufacturing 55.6 (2026-08-03) | **Plausible within the corrected envelope** — rate/index defined-risk structures at a CaR budget up to $231.45 are no longer excluded on size as they were at $46.29. Construction + dual-path verification is D2's step | **ROUTER-ELIGIBLE · top-5 #1** |
| 2 | JAZZ PDUFA | FDA | 2026-08-25 (C) | **The richest measured vol-vs-event setup on the list.** IV **44.7%** against historical vol **31.4%**, with **IV percentile 93.2% at 52 weeks and 100% at both 13 and 26 weeks** — implied vol is at its outright ceiling into a binary Priority-Review decision. $251.00, −3.9% off the 52-week high | Jazz PR 2026-04-27; IBKR snapshot 2026-08-03 (re-verified directly) | Plausible on size; chain unverified | PARKED · top-5 #2 |
| 3 | RARE PDUFA | FDA | 2026-08-23 (C) | Clean binary with a **large measured event premium**: IV **161.4%** vs HV **58.3%**, IV %ile 97.2% (100% at 13/26w), on a $25.00 underlying **−37.3% off its 52-week high**. Small-cap sponsor (~$2.46B, just above the floor) — the sponsor-size risk is itself the counter-argument | Ultragenyx 8-K 2026-02-23; IBKR snapshot 2026-08-03 | Plausible on size (low underlying); chain unverified | PARKED · top-5 #3 |
| 4 | LNTH PDUFA | FDA | 2026-08-13 (C) | **A measured anomaly that is either the best divergence on this list or a data artifact, and this file does not claim to know which.** IV reads **9.29%** against historical vol **38.83%**, with IV percentile **0.0 at 13, 26 and 52 weeks** — implied vol at its 52-week floor, roughly a quarter of realized, ten days before a binary FDA decision. **Independently re-pulled and reproduced.** The artifact hypothesis is live and specific: LNTH has **no weekly expiries** (first expiry 2026-08-21, *after* the PDUFA), so the quotes feeding this may be thin or stale. **Must be re-verified against a live chain before any thesis rests on it** | Lantheus PR 2025-10-28; IBKR snapshot 2026-08-03 (re-verified); Barchart independently reports HV 39.42% | Plausible on size; **the IV reading itself is what needs verification, not the sizing** | PARKED · top-5 #4 |
| 5 | NVDA earnings | Earnings | 2026-08-26 (C) | Post-derate implied vol against demand documents that strengthened at third-party print level this week (MSFT Azure +43%, AMZN AWS +36.7%); options imply **~±8.3%**, within the 7–12% historical range. IV %ile 74.8% — notably *not* extreme, into the cohort's largest unresolved catalyst | NVIDIA release 2026-07-29; MSFT/AMZN Q2 prints; Saxo implied-move read | No — $207 underlying; a defined-risk structure at 1-contract minimum is unlikely to fit $231.45, but this is a judgment for construction, not a mechanical bar | PARKED · top-5 #5 |
| 6 | MRNA PDUFA | FDA | 2026-08-05 (C) | Clean binary (VRBPAC voted 9-0 favorable) against a distressed tape: $56.42, **−34.1% off its 52-week high** (the W30 file's −11.7% rested on a wrong 52-week high of $64.24; the actual high is $85.60). IV 78.4% vs HV 74.2% — implied only modestly above realized, IV %ile 72.4%. **Two days out — entry must land by 8/04 per C entry criterion 5** | Moderna PR 2026-02-18; VRBPAC record; IBKR snapshot 2026-08-03 (re-verified) | Plausible on size; **timing is the binding constraint, not sizing** | PARKED · rest |
| 7 | BMY PDUFA | FDA | 2026-08-17 (C) | Binary iberdomide approval on a mega-cap — **now with an M&A overhang that did not exist last cycle.** The FT reported 2026-08-02 that AstraZeneca has explored a ~$400B combination with BMY. $64.59, only **−1.6% off its 52-week high**, IV 30.0% / IV %ile 59.2% — the options market is **not** pricing a takeover premium or elevated binary risk, and BMY fell 1.1% today rather than gapping on the report. Two independent binaries now overlap one expiry | BMS PR 2026-02-17; FT via Reuters/CNBC 2026-08-02; IBKR snapshot 2026-08-03 (re-verified) | Plausible on size; **the M&A overhang materially complicates a clean event thesis** | PARKED · rest |
| 8 | AMD earnings | Earnings | 2026-08-04 (C) | Prints tomorrow into shipped MI400 silicon (launched 7/23) rather than a roadmap promise; options imply **~12.3%**, IV %ile 92.8% | AMD IR release 2026-07-08; AMD AAI-2026 release 2026-07-23; TipRanks/Benzinga implied-move reads | No — $480 underlying | PARKED · rest |
| 9 | GILD PDUFA | FDA | 2026-08-27 (C) | Binary BIC/LEN approval; **IV %ile 96.8%** (IV 37.4% vs HV 31.3%) on a name **−17.3% off its 52-week high of $156.43** — note the W30-era figures for this name were corrupted in the source sweep and are corrected here | Gilead PR 2026-04-29; IBKR snapshot 2026-08-03 (re-verified) | Plausible on size; mega-cap low move-per-premium is the counter | PARKED · rest |
| 10 | SMCI earnings | Earnings | 2026-08-11 (C) | Options imply **~18.6%**, above the 4-quarter average of 16.9%, IV %ile 95.6%, on a name −52.0% off its high with a raised GM guide carrying an explicit management cancellation caveat | SMCI release 2026-07-21; TipRanks/GuruFocus implied-move reads | Plausible on size — $28.51 underlying is the lowest-priced earnings candidate here | PARKED · rest |
| 11 | TLX PDUFA | FDA | 2026-09-11 (C — **NEW this cycle**) | Binary TLX101-Px recurrent-glioma decision, **newly upgraded from two consecutive passes of (T) to company-confirmed**, and it falls inside the window only because the window rolled. Vol data **not pulled this session** — no divergence is asserted, this is a dated-event placeholder for construction | Telix PR 2026-04-10 | Unassessed — vol and chain both unread | PARKED · rest |
| 12 | DIS earnings | Earnings | 2026-08-05 (C) | Options imply ~6.3%, IV %ile 77.2%. Listed for completeness because it is the **largest dated thesis risk in the open book** — three of the open D position's five invalidation criteria are mechanism-enforced at this exact print — but as a C candidate it is unremarkable | Disney IR release 2026-07-14; Investing.com implied-move read | No — thin edge; overlaps an open D position | PARKED · rest |

**C top-5:** #1 FOMC 9/16 (the only router-eligible candidate), then JAZZ 8/25, RARE 8/23, LNTH 8/13 and NVDA 8/26 as the richest measured implied-vol-vs-event divergences — all four router-parked.

**Operative read for W4 — this differs from the last three cycles and the difference is the point.** For several cycles the C section's conclusion was "zero or near-zero executable C entries," resting on two things that have both now changed: a router-eligible FOMC that already carried a standing NO-GO, and a $46.29 screening budget that excluded nearly every constructible structure. Neither holds this cycle. **The 2026-09-16 FOMC is a distinct event from the 2026-07-29 FOMC** — the `rescreen-FOMC-C-20260720` NO-GO adjudicated the *July* meeting, whose window has closed, and it does **not** carry over. Treating September as covered by that NO-GO would be an error; equally, this is a fresh trigger rather than a re-defer, so the no-chaining rule is not engaged. Per W4 §D, C top-tier enqueues at `due_date` = the pre-catalyst window 7–10 days before the catalyst when the catalyst is ≥14 days out, i.e. **2026-09-06 → 2026-09-09**, with entry required at least one trading day before 9/16 and a structure expiring after it (the 2026-09-18 monthly is the natural expiry and sits ~10 days from that entry, well inside C's 1–45-day tenor). Two payrolls and two CPI prints land in between, so a thesis constructed today would be built on inputs that turn over twice before entry — which is an argument for the 9/6–9/9 due_date, not for acting sooner.

---

*Shortlists only. Full thesis construction per Strategy.md — adversarial counter-argument attacking size as well as direction; immutable at-entry price target and thesis-completion criteria for A; dual-path max-loss verification and a defined-risk structure for C — happens in separate W4-scheduled `PENDING_ANALYSIS` sessions.*

*Sources and provenance: `federalreserve.gov` FOMC calendar; company IR releases and 8-Ks as cited per row; FDA/sponsor primary sources cross-checked against RTTNews/pdufa.bio; IBKR `get_price_snapshot` for all prices, implied vol, IV percentile, historical vol and 90-day dollar volume (intraday 2026-08-03, session not closed); web sources for implied moves (TipRanks, Benzinga, Investing.com, OptionSlam, Saxo, GuruFocus, EarningsWatcher); `state.current_regime` / `state.current_positions` / `analytics.strategy_nav` / `state.regime_capital_debt` / `state.strategy_capital_enablement` / `events.decision_log` / `state.open_queue_detail` / `Watchlist.md` A-queue (37 names).*

***Data-quality disclosures for this run — recorded so a later reader can weigh the numbers correctly:***
1. ***Analyst price targets: UNAVAILABLE for all symbols.*** *Both FMP routes returned plan-quota "Rate limit reached." No remembered PT figure was carried forward anywhere in this file, which is why PART 2A cites % off 52-week high and IV percentile instead.*
2. ***A transcription corruption in the market-data sweep was detected and corrected.*** *The sweep self-flagged two rows (BMY, REGN) whose volatility/volume fields had been copied from adjacent rows; independent inspection found **three more it missed** — JAZZ (fields identical to UNP), GILD (identical to WMT), and MRNA (a wrong 52-week high). **BMY, JAZZ, GILD, MRNA, LNTH and RARE were re-pulled directly from IBKR and the corrected values are what appear above.** The corrections were not cosmetic: JAZZ's true IV percentile is 93.2%, not the 63.6% the corrupted row implied, which is the difference between an unremarkable row and the #2 candidate. **Volatility and volume figures for the un-re-verified names from that same batch — REGN, IONS, EXEL, BBIO, NUVL, COGT, SMMT, VTRS — should be treated as unverified and re-pulled before use.***
3. ***IBKR `get_option_data` was down all session*** *("Error invoking method", 5+ retries), so no strike-level premium or spacing was observed and no constructibility claim is made in PART 2B.*
4. ***`mcp__FMP__calendar` returned rate-limit errors, NOT the plan-tier ACCESS DENIED the W30 run hit*** *— a different and possibly transient failure mode; a future run should not conclude the endpoint is permanently gated.*
5. ***Today's session had not closed*** *when this file was written; PLTR (8/3 AMC) and VRTX (8/3 AMC) report after it.*
