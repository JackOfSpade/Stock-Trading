2026-Q3
# Strategy D — Long-Horizon Candidate Screen, 2026-Q3

Prepared: 2026-07-01 (quarter just beginning)
Strategy: D (long-horizon narrative-screened equity core — Subtype A future-dated-catalyst / Subtype B trend-continuation)

---

## 0. Book state, regime, and screen constraints

- **D book** (`state.current_positions`, 2026-07-01): **2 open positions** — **RTX** (Industrials / Aerospace & Defense) and **DIS** (Communication Services / Entertainment). ~$57 deployed (RTX ~$30.6, DIS ~$27) of the ~$1,880 D sub-portfolio NAV; remainder SGOV-parked. The book is **below the minimum-5 concurrent-position floor**, so additions move D *toward* its floor rather than against any ceiling.
- **Regime** (`state.current_regime`, June 2026 integrative): **reflation-tilt + neutral risk** — growth *stable* (May payrolls +172k, revisions +93k), inflation *reaccelerating* (core PCE 3.4% YoY, fastest in ~3yr), policy *hawkish* (June dot-plot no-cuts/hike-bias; DXY 15-mo high), risk *neutral* (equities −1% MoM, VIX 16.45), shock *latent* (Iran ceasefire fragile, Brent ~$73). The macro-structural read for D's fundamental router question: multi-year equity theses face a **multiple-compression headwind** from a hawkish Fed + reaccelerating inflation; favor theses anchored to *quantifiable cash-generative trends* and *reasonable entry valuations* over high-multiple long-duration narratives.
- **D router**: Technical **ACTIVATE** (SPY Trend NEUTRAL satisfies UP-OR-NEUTRAL; Yield-Curve Sustained-Inversion = NOT-SUSTAINED). Operative state **ACTIVATE — PENDING `div-D-202606-1`**. **New D entries are currently BLOCKED pending resolution of the `div-D-202606-1` divergence review** (M4 2026-07: raw fundamental rose to ACTIVATE on the growth re-firm, but the inflation-reaccelerating + hawkish reconciliation override returns it to DNA; existing RTX/DIS run to thesis-invalidation). **Every readiness flag below reflects thesis/eligibility/momentum only; actual staging is gated by that router block** and by the downstream Q4 thesis-construction gate.
- **Caps** (Strategy.md **rev 35**): the 10-position hard cap, max-3-per-narrative-theme cap, and max-3-per-correlation-bucket *count* cap are **REMOVED**; the **minimum-5 floor** is retained; the **2%-per-position size cap** and the **30%-of-NAV per-GICS-sector exposure cap** are RETAINED. At ~2% sizing on a mostly-SGOV book, the 30%-of-NAV sector cap is **non-binding for every candidate** (each single-name add ≈ +1.5–2% of NAV; a single GICS sector would need ~15 concurrent adds to approach 30%). The task's "would this push D above the 10-position cap" test is therefore moot; concentration is flagged qualitatively where a candidate joins an already-occupied sector (Communication Services via DIS; Industrials via RTX).
- **Correlation-bucket check** (criterion 5b, >0.6 trailing-252d daily-return, max-3-per-bucket): computed by classical-method delegation at thesis-construction across held + candidate. With only DIS + RTX held (different sectors, likely <0.6), adding any single name cannot fill a 3-bucket. Non-binding at screen stage; flagged for the AI-cluster names (GOOGL/AMZN/TSM/CRM/AVGO would inter-correlate >0.6) **if multiple are accumulated over successive entries**.
- **Today's tape (2026-07-01):** a sharp in-session AI/semiconductor derating — TSM −6.4%, MU −8.9%, AMAT −10.4%, KLAC −12.8%, LRCX −11%, ASML −7.3%, CEG −6.2%, VST −3.9%, GEV −3.2%, CAT −7.0%. Directly relevant to entry-timing for the semis / AI-capex / power names.
- **'NO-GO records are context, not barriers':** prior D NO-GOs — LLY (entry-timing, re-screen 6/12 NO-GO), CCJ (criterion-4 decisive flaw), GEV (criterion-6 rally roll-off), BA (terminal re-screen NO-GO 6/4), GOOGL (entry-timing), CEG, VST (both 4/26) — are informative history, **not exclusions**. Several re-appear below on refreshed Q2-2026 evidence; each is re-screened on current facts.
- **Data provenance:** market cap / price / ADV / momentum from FMP batch quotes + IBKR connector as of 2026-07-01; thesis evidence from company filings and calendar-Q1-2026 (Apr–May 2026) earnings releases/transcripts and Apr–Jun 2026 developments via web research. **Eligibility gates (≥$10B market cap, ≥$20M 30-day ADV) cleared by every listed name** (all are ≥$29B cap trading >$100M/day).

**Thesis-category legend:** `1` Product cycle (multi-cycle roadmap) · `2` Regulatory/legal resolution · `3` Management execution / turnaround · `4` Secular thematic (specific mechanism) · `5` Industry structural change (identified beneficiary).

---

## 1. PART 1 — Candidate universe (broad long list)

48 names passing D's eligibility gates with a concrete, documented multi-year structural driver. Cast broadly per the quarterly mandate; PART 2 filters to a ranked shortlist. **DIS and RTX are excluded** (open D book). AI-infrastructure names are included but carry an explicit homogenization/AI-narrative-overfit caution (Strategy D pre-mortem 2.4 / 2.8) — do not accumulate the cluster without the correlation-bucket check.

| # | Ticker | Company | Mkt Cap | GICS Sector / Industry | Cat | Why on the list (1–2 sentences) | Key public docs |
|---|---|---|---|---|---|---|---|
| 1 | GOOGL | Alphabet | ~$4.35T | Comm Services / Interactive Media | 4,2 | Google Cloud +63% YoY (Q1'26) with backlog ~$460B on owned-silicon (Ironwood TPU) capturing external AI demand (Anthropic up-to-$40B/5GW); antitrust remedy on appeal (opening brief 5/22/26). | FY25 10-K; Q1'26 release 4/29/26; Jun-2026 investor deck; DC Circuit appeal |
| 2 | AMZN | Amazon | ~$2.62T | Cons Disc / Broadline Retail | 4,5 | AWS +28% YoY (Q1'26, fastest in 15 quarters), $195B backlog, record 13.1% consolidated margin; Trainium silicon + Anthropic/OpenAI multi-year commits monetized as power comes online. | FY25 10-K; Q1'26 8-K 4/29/26; earnings-call remarks |
| 3 | TSM | Taiwan Semiconductor (ADR) | ~$2.32T | IT / Semiconductors | 1,4 | Sole scaled leading-edge AI-accelerator foundry; Q1'26 rev +40.6% USD, GM 66.2%, advanced nodes 74%; N2 HVM + N2P/A16 (backside power) H2'26; Arizona $165B. | Q1'26 6-K (Apr-2026); FY25 annual report; Jul-16-2026 Q2 print pending |
| 4 | AVGO | Broadcom | ~$1.77T | IT / Semiconductors | 4 | Custom-ASIC (XPU) hyperscaler engagements + Ethernet-for-AI networking displacing InfiniBand; mid-20s% revenue CAGR guided; VMware software annuity. | FY25 10-K; Q1/Q2 FY26 transcripts |
| 5 | TSLA | Tesla | ~$1.60T | Cons Disc / Automobiles | 1,4 | Robotaxi/FSD + Optimus optionality on a multi-year roadmap. **AI-narrative-overfit + momentum caution** (pre-mortem 2.4); binary execution, thin near-term FCF support. | FY25 10-K; Q1'26 earnings; robotaxi updates |
| 6 | MU | Micron | ~$1.19T | IT / Semiconductors | 1,4 | HBM3E/HBM4 supply-constrained multi-year pricing/capacity cycle on AI memory demand. **Rallied ~10x off 2025 lows — extreme entry-timing risk.** | FY25 10-K; FY26 quarterly transcripts |
| 7 | LLY | Eli Lilly | ~$1.11T | Health Care / Pharma | 1 | Incretin franchise +56% YoY (Q1'26; Mounjaro +125%); oral orforglipron (Foundayo) FDA-approved 4/1/26 unlocks a structurally larger, supply-scalable TAM. | FY25 10-K; Q1'26 release 4/30/26; Foundayo approval 4/1/26 |
| 8 | BRK-B | Berkshire Hathaway | ~$1.08T | Financials / Diversified | 3 | First full year under CEO Greg Abel (from 1/1/26); ~$380B+ cash optionality and capital-allocation reset. Structural-narrative fit is looser (compounder). | 2025 10-K; Q1'26 10-Q; annual letter |
| 9 | INTC | Intel | ~$644B | IT / Semiconductors | 1,3 | Lip-Bu Tan turnaround; 18A HVM ramp + external-foundry customer commitments targeted 2H'26. **Momentum extreme: +248% YTD, +17% trailing-30d — hard defer.** | 2026 DEF 14A; Q1'26 earnings; foundry updates |
| 10 | AMAT | Applied Materials | ~$514B | IT / Semiconductor Equipment | 4 | GAA transistor + advanced-packaging content-per-wafer rise; leading-edge capex beneficiary. Sold off −10% today on the semis derating. | FY25 10-K; FY26 quarterly transcripts |
| 11 | LRCX | Lam Research | ~$482B | IT / Semiconductor Equipment | 4 | GAA + 200+-layer 3D-NAND drive etch/deposition content; expanding CSBG recurring base. Down −11% today. | FY25 10-K; FY26 Q3 (Apr-2026) |
| 12 | CAT | Caterpillar | ~$456B | Industrials / Machinery | 5 | Infrastructure + data-center backup-power (large-engine) + electrification demand; multi-year backlog. Cyclical to the reflation tape; −7% today. | FY25 10-K; Q1'26 earnings |
| 13 | ABBV | AbbVie | ~$443B | Health Care / Pharma | 1 | Post-Humira immunology reacceleration on Skyrizi + Rinvoq multi-year ramp past the LOE trough; neuroscience/aesthetics optionality. | FY25 10-K; Q1'26 release |
| 14 | BAC | Bank of America | ~$414B | Financials / Banks | 2,5 | Basel III Endgame re-proposal lowered capital ~4.8%; NII tailwind + capital-markets upturn + Erica operating leverage. Rate-beta name (looser D fit). | Q1'26 results; Basel re-proposal Mar-2026 |
| 15 | ORCL | Oracle | ~$413B | IT / Software | 4 | OCI / RPO cloud-infrastructure backlog for AI-training capacity. **Crushed ~−58% from 52-wk high** — thesis intact but sharp de-rating raises execution/backlog-conversion questions. | FY26 10-K; RPO disclosures; OCI updates |
| 16 | GE | GE Aerospace | ~$391B | Industrials / Aerospace & Defense | 1,4 | Commercial-engine (LEAP/GE9X) installed-base **aftermarket/services supercycle** — multi-decade high-margin annuity as the narrowbody fleet ages. | FY25 10-K; Q1'26 earnings; investor day |
| 17 | UNH | UnitedHealth | ~$388B | Health Care / Providers & Svcs | 3 | Managed-care margin-recovery turnaround off the 2025 MLR/utilization trough. **Recovered +12% trailing-30d / +29% YTD — momentum caution.** | FY25 10-K; Q1'26 earnings; guidance reset |
| 18 | KLAC | KLA Corp | ~$344B | IT / Semiconductor Equipment | 4 | Process-control monopoly-ish share; leading-edge + advanced-packaging inspection intensity rises. Down −13% today. | FY25 10-K; FY26 quarterly transcripts |
| 19 | MRK | Merck | ~$309B | Health Care / Pharma | 1 | Keytruda subcutaneous (2026) extends the franchise past LOE; Winrevair/sotatercept ramp. LOE cliff is the multi-year risk to weigh. | FY25 10-K; Q1'26 release |
| 20 | GEV | GE Vernova | ~$306B | Industrials / Electrical Equipment | 4,5 | Electrification/grid supercycle — Q1'26 orders +71%, backlog **$163B**, gas-power slot reservations 83→100 GW (→110 by YE). **Rallied very hard — defer.** | Q1'26 release 4/22/26; investor day; 10-K |
| 21 | IBM | IBM | ~$270B | IT / Software & IT Services | 4 | Hybrid-cloud (Red Hat) + watsonx AI + a genuine quantum-roadmap option; recurring software mix rising. | FY25 10-K; Q1'26 earnings; quantum roadmap |
| 22 | LIN | Linde | ~$247B | Materials / Industrial Gases | 4,5 | ~$10B+ sale-of-gas project backlog (clean-H2 + semiconductor end-markets) converting to revenue 2026+; pricing-power compounder. | FY25 10-K; Q4'25/FY25 8-K |
| 23 | MRVL | Marvell | ~$242B | IT / Semiconductors | 4 | Custom-silicon (hyperscaler ASIC) + AI interconnect/optics ramp. Down −7% today; AI-cluster correlation caution. | FY25 10-K; FY26 quarterly transcripts |
| 24 | NVO | Novo Nordisk (ADR) | ~$216B | Health Care / Pharma | 1 | GLP-1 franchise (semaglutide) + oral Wegovy launch; but CagriSema disappointment vs tirzepatide and share loss to LLY are the multi-year overhang. | FY25 annual report; Q1'26 results |
| 25 | QCOM | Qualcomm | ~$194B | IT / Semiconductors | 1,4 | Diversification beyond handsets into automotive (design-win backlog) + IoT/edge-AI; Apple-modem roll-off is the offsetting risk. | FY25 10-K; FY26 transcripts; auto backlog |
| 26 | BA | Boeing | ~$173B | Industrials / Aerospace & Defense | 3,2 | Ortberg turnaround; 737 MAX now **42/mo → 47 "this summer"**, 143 Q1'26 deliveries, cash-burn narrowing; 737-7/-10 + 777X certifications pending 2026. | Q1'26 release 4/22/26; monthly deliveries; FAA actions |
| 27 | DE | Deere | ~$170B | Industrials / Machinery | 1,4 | Precision-ag (autonomy + See-&-Spray) recurring-tech roadmap through an ag-cycle trough; multi-year margin/mix story. | FY25 10-K; FY26 quarterly transcripts |
| 28 | UNP | Union Pacific | ~$164B | Industrials / Ground Transport (Rail) | 5,2 | Transcontinental rail-merger structural reshaping (regulatory-gated) + volume/precision-railroading operating leverage. | FY25 10-K; Q1'26 earnings; STB filings |
| 29 | ETN | Eaton | ~$161B | Industrials / Electrical Equipment | 4,5 | Electrification + data-center power backlog; reshoring capex beneficiary with multi-year book-to-bill >1. | FY25 10-K; Q1'26 earnings; investor day |
| 30 | UBER | Uber | ~$149B | Industrials / Ground Transport | 4 | Gross-bookings +25% YoY (Q1'26) on the Uber One flywheel; AV as a two-sided platform hedge ($10B+ Nuro/Lucid/Waymo). | FY25 10-K; Q1'26 release 5/6/26; AV deals |
| 31 | ISRG | Intuitive Surgical | ~$143B | Health Care / Health Care Equipment | 4 | Razor-and-blades installed-base compounder — procedures +16% YoY, base 11,395 (+12%), dV5 mix accelerating; recurring high-margin annuity. | FY25 10-K; Q1'26 8-K 4/21/26 |
| 32 | CRM | Salesforce | ~$134B | IT / Software | 4 | Agentforce/Data-360 AI ARR $3.4B (+>200% YoY), Agentforce alone $1.2B (+205%), on a +14% cRPO core; land-and-expand into 150k+ base. | FY26 10-K; Q1 FY27 8-K 5/27/26 |
| 33 | LMT | Lockheed Martin | ~$120B | Industrials / Aerospace & Defense | 5 | Defense spend + missile-defense ("Golden Dome") multi-year demand; F-35 sustainment annuity. Off 52-wk highs on program charges. | FY25 10-K; Q1'26 earnings; backlog |
| 34 | SBUX | Starbucks | ~$117B | Cons Disc / Restaurants | 3 | Niccol "Back to Starbucks" turnaround; comp-recovery + throughput (Green Apron); FY28 framework. Rallied +22% YTD — entry-timing watch. | FY25 8-K; Investor Day Jan-2026; Q2 FY26 |
| 35 | NOW | ServiceNow | ~$110B | IT / Software | 4 | Agentic-AI workflow platform (Now Assist) monetizing the enterprise install base; subscription-RPO compounding. | FY25 10-K; Q1'26 earnings |
| 36 | HWM | Howmet Aerospace | ~$107B | Industrials / Aerospace & Defense | 4 | Aero-engine structural components (blades/fasteners) supercycle on build-rate ramp + aftermarket spares pricing. | FY25 10-K; Q1'26 earnings |
| 37 | GD | General Dynamics | ~$98B | Industrials / Aerospace & Defense | 5 | Defense (Marine/Combat) multi-year backlog + Gulfstream G700/G800 delivery ramp. | FY25 10-K; Q1'26 earnings; backlog |
| 38 | SPOT | Spotify | ~$97B | Comm Services / Entertainment | 4,5 | Pricing-power + gross-margin inflection (audiobooks, marketplace, ad-tech); structural shift to profitability at scale. | FY25 20-F; Q1'26 shareholder letter |
| 39 | MELI | MercadoLibre | ~$88B | Cons Disc / Broadline Retail | 4,5 | LatAm e-commerce + fintech (Mercado Pago credit book) dual-flywheel; structural digital-payments penetration. | FY25 10-K; Q1'26 earnings |
| 40 | FCX | Freeport-McMoRan | ~$87B | Materials / Metals & Mining | 5 | Copper structural supply deficit vs electrification/grid/data-center demand; multi-year volume + leaching-tech optionality. | FY25 10-K; Q1'26 earnings |
| 41 | CEG | Constellation Energy | ~$84B | Utilities / IPP | 4,5 | Nuclear PPAs to hyperscalers (Crane/TMI restart, Calpine deal); data-center power scarcity. **Collapsed −44% from 52-wk high** — de-rating raises deal-timing risk. | 8-K PPAs; Q1'26 earnings; investor deck |
| 42 | HON | Honeywell | ~$70B | Industrials / Industrial Conglomerate | 3,5 | Planned three-way separation (Aerospace / Automation / Advanced Materials) as a value-unlock catalyst through 2026. | FY25 10-K; separation filings |
| 43 | SLB | Schlumberger (SLB) | ~$68B | Energy / Energy Equipment & Svcs | 4,5 | International + digital/AI oilfield (Lumi/Tela) multi-year contract backlog; capital-return discipline. | FY25 10-K; Q4'25/Q1'26 releases |
| 44 | NOC | Northrop Grumman | ~$74B | Industrials / Aerospace & Defense | 5 | B-21 production ramp (multi-decade) + Sentinel ICBM program; backlog ~$95B. | FY25 10-K; Q1'26 earnings |
| 45 | NKE | Nike | ~$63B | Cons Disc / Textiles & Apparel | 3 | Elliott Hill "Win Now"/"Sport Offense" turnaround; running now 5 straight double-digit-growth quarters, wholesale reset working — but total revenue not yet re-inflected. | FY26 10-K; Q4 FY26 release 6/30/26 |
| 46 | VST | Vistra | ~$51B | Utilities / IPP | 4,5 | Nuclear + gas PPAs (Meta 20-yr) to data centers; capacity-scarcity beneficiary. **Down −44% from 52-wk high** — de-rating/entry-timing watch. | 8-K Meta PPA; Q1'26 earnings |
| 47 | CMG | Chipotle | ~$45B | Cons Disc / Restaurants | 3 | Unit-growth runway (7,000+ NA target) + throughput/automation ("Autocado"/Hyphen) under new CEO; margin durability. | FY25 10-K; Q1'26 earnings |
| 48 | CCJ | Cameco | ~$43B | Energy / Uranium | 4,5 | Uranium contracting cycle + 49% Westinghouse (AP1000 new-build); nuclear-renaissance beneficiary. **Prior criterion-4 NO-GO (extreme multiple/momentum) — re-verify valuation.** | 6-K MD&A; contract announcements |

**Long-list notes.**
- **AI-infrastructure cluster** (GOOGL, AMZN, TSM, AVGO, MU, INTC, AMAT, LRCX, KLAC, MRVL, ORCL, NOW, CRM): real structural theses, but (a) they inter-correlate >0.6 and would share a correlation bucket if multiply accumulated (monitor at entry per criterion 5b), and (b) several are late-cycle-rallied — today's −7% to −13% semis derating is an entry-timing signal, not yet a thesis signal. Do not treat "AI exposure" as a thesis (pre-mortem 2.4); each PART-2 name carries a *specific, quantifiable* mechanism.
- **Power/nuclear names** (CEG, VST, GEV, CAT, ETN, LIN): the electrification/data-center-power theme is intact, but CEG/VST have de-rated 40%+ from highs while GEV has rallied hard — dispersion within one theme; screen each on its own trend metric.
- **Financials** (BRK-B, BAC) are intentionally under-weighted — rate-beta names fit D's "structural multi-year narrative" mandate less cleanly.
- **Defense** is well-represented (GE, BA, LMT, HWM, GD, NOC) — the correlation-bucket cap would bite first here if several were accumulated alongside the held RTX.

---

## 2. PART 2 — Ranked shortlist (10) with readiness flags

Ranked by thesis strength × evidence quality × subtype cleanliness × regime/entry-timing fit. **Q4 reads this section verbatim to schedule D thesis-construction for "ready now" names** — but note the overarching **`div-D-202606-1` router block on all new D entries** (§0): "ready now" means *ready for thesis construction once that block clears*, not "stage today."

Momentum convention (criterion 6): trailing-30-day change; "rallying hard" = the prior screen's >~15% trailing-30d flag. Where FMP throttled the precise 30-day read, the 52-week-range position + 50-day-MA posture is used and labeled as a proxy.

### Rank 1 — GOOGL (Alphabet) · Comm Services / Interactive Media · ~$4.35T
- **Thesis (Subtype B):** Google Cloud is a durable second growth engine — owned Ironwood TPU capacity captures external AI training/inference at cost/scale rivals struggle to match (Q1'26 Cloud +63% YoY, backlog ~$460B; Anthropic up-to-$40B/5GW, >$10B Meta deal), while Gemini/AI-Overviews defends and *extends* Search monetization (AI Overviews >2.5B MAU) rather than cannibalizing it. **Trend metric: Google Cloud revenue grows ≥25% YoY for ≥4 consecutive quarters** (printed +63%).
- **Subtype-A overlay (catalyst):** US v. Google remedy on appeal — opening brief filed at the DC Circuit 5/22/26; oral arguments late-2026/early-2027. Slow-moving; sits in the invalidation set, not the thesis anchor.
- **Evidence base:** Complete — ≥8 quarters of transcripts + FY24/FY25 10-Ks; Jun-2026 investor deck + Q1'26 release (4/29/26).
- **Invalidation:** Cloud YoY <20% for 2 consecutive quarters; Cloud operating margin contracts 2 consecutive quarters; Cloud RPO declines sequentially 2 consecutive quarters; adverse structural remedy forcing Chrome/Android divestiture.
- **Momentum:** trailing-30d **−4.4%**, YTD +15% → **not rallying; entry-timing clean.**
- **Concentration:** joins **DIS in Communication Services** — Comm Svcs would be ~2 positions (~3–4% of NAV), far below the 30%-of-NAV cap. Non-binding; flag for future accumulation.
- **Thesis strength: Very High.** **Readiness: READY NOW** (subject to the `div-D-202606-1` block). Best combination of quantified accelerating trend, complete evidence, embedded regulatory optionality, and reasonable valuation in a hawkish-multiple regime.

### Rank 2 — AMZN (Amazon) · Cons Disc / Broadline Retail · ~$2.62T
- **Thesis (Subtype B):** AWS is re-accelerating (Q1'26 +28% YoY, fastest in 15 quarters; op income $14.2B; backlog $195B +25%) as vertically-integrated Trainium silicon captures hyperscale AI workloads at better price-performance; contracted demand (Anthropic >$100B/10yr, OpenAI multi-year) converts to revenue as power/data-center capacity comes online (6–24-mo capex→revenue lag). Consolidated margin at a record 13.1%. **Trend metric: AWS revenue grows ≥20% YoY for ≥4 consecutive quarters** (printed +28%).
- **Evidence base:** Complete — ≥8 quarters transcripts + FY24/FY25 10-Ks; Q1'26 8-K (4/29/26).
- **Invalidation:** AWS YoY <18% for 2 consecutive quarters; AWS operating margin falls below ~30% for 2 consecutive quarters; AWS backlog declines sequentially 2 consecutive quarters; Anthropic/OpenAI commitments materially renegotiated down or churned.
- **Momentum:** trailing-30d **−6.7%**, YTD +5.7% → **not rallying; entry-timing clean.**
- **Concentration:** new GICS sector (Cons Disc / Broadline) — improves book diversification.
- **Thesis strength: Very High.** **Readiness: READY NOW** (subject to block). Key watch: ~$200B/yr capex with a monetization lag — the invalidation set is the ROIC guardrail.

### Rank 3 — CRM (Salesforce) · IT / Software · ~$134B
- **Thesis (Subtype B — qualifies cleanly):** Enterprise AI-agent monetization — Agentforce/Data-360 ARR $3.4B (+>200% YoY), Agentforce alone $1.2B (+205%), on a durable +14% cRPO core; >50% of AI bookings come from the *existing* ~150k+ base, so land-and-expand drives high-margin incremental ARR while non-GAAP op margin holds ~34.8%. **Trend metric: Data-360 + Agentforce ARR sustains ≥50% YoY (off the now-material $3.4B base) AND cRPO holds ≥low-double-digit YoY for ≥12 months.**
- **Evidence base:** Complete — ≥8 quarters transcripts + FY25/FY26 10-Ks; Q1 FY27 8-K (5/27/26).
- **Invalidation:** AI/Agentforce ARR growth decelerates below ~50% YoY (base failing to compound); cRPO YoY <10% cc for 2 consecutive quarters; non-GAAP operating margin contracts YoY (AI monetized at the cost of profitability) or FY27 revenue guide cut below ~10%.
- **Momentum:** below 50-DMA ($164 vs $175), near 52-wk low $146, YTD deeply negative → **not rallying; de-rated entry (favorable).** (30-d proxy; FMP throttled.)
- **Concentration:** new GICS sector (IT/Software). AI-cluster correlation caution vs GOOGL/AMZN if co-accumulated.
- **Thesis strength: High.** **Readiness: READY NOW** (subject to block). Cleanest disclosed Subtype-B metric on the shortlist; risk is that >200% ARR growth is off an early base — the ≥50% floor is the honest test.

### Rank 4 — ISRG (Intuitive Surgical) · Health Care / Health Care Equipment · ~$143B
- **Thesis (Subtype B):** Razor-and-blades installed-base compounding — each da Vinci placement (esp. dV5) seeds a multi-year recurring instruments/accessories annuity (~high-margin) that scales with procedure volume. Q1'26: procedures +16% YoY, installed base 11,395 (+12%), 431 placements (232 dV5); 7 new robotic-reimbursed procedures effective Jun-2026 widen the funnel. **Trend metric: da Vinci procedure volume grows ≥13% YoY** (FY26 guide raised to 13.5–15.5%).
- **Evidence base:** Complete — ≥8 quarters transcripts + FY24/FY25 10-Ks; Q1'26 8-K (4/21/26).
- **Invalidation:** procedure growth <10% YoY for 2 consecutive quarters; system placements decline YoY for 2 consecutive quarters; recurring-revenue growth decouples downward from procedure growth; a competitor (Medtronic Hugo — FDA-cleared Dec-2025; J&J Ottava — de novo submitted Jan-2026) disclosed displacing dV placements at named large IDNs.
- **Momentum:** near 52-wk low ($403 vs low $396), below 50/200-DMA → **not rallying; deeply out-of-favor entry (favorable).**
- **Concentration:** new GICS sector (Health Care Equipment) — improves diversification.
- **Thesis strength: High.** **Readiness: READY NOW** (subject to block). Cleanest secular annuity mechanism; the emerging-competition clause is the live multi-year risk to monitor.

### Rank 5 — UBER (Uber) · Industrials / Ground Transportation · ~$149B
- **Thesis (Subtype B):** Marketplace-scale compounding — Q1'26 gross bookings $53.7B +25% YoY (Mobility +25%, Delivery +28%), >50M Uber One members driving retention; AV is a two-sided hedge (Uber as the demand-aggregation layer for third-party autonomy — Waymo + $10B+ to Nuro/Lucid/WeRide) converting robotaxi supply into incremental high-margin trips. **Trend metric: total gross-bookings cc YoY growth ≥15%** (printed +25%; Q2'26 guide +18–22% cc).
- **Evidence base:** Complete — ≥8 quarters transcripts + FY24/FY25 10-Ks; Q1'26 release (5/6/26).
- **Invalidation:** GB cc YoY decelerates below ~15% for 2 consecutive quarters; adjusted-EBITDA margin (% of GB) contracts YoY for 2 consecutive quarters (uneconomic growth); Uber One membership stalls/declines sequentially.
- **Momentum:** trailing-30d **−0.8%**, YTD −10.5% → **not rallying; entry-timing clean.**
- **Concentration:** Industrials, but **Ground Transportation** — distinct sub-industry from RTX's Aerospace & Defense; low correlation to RTX. Effectively diversifying.
- **Thesis strength: High.** **Readiness: READY NOW** (subject to block). Primary risk is AV disintermediation + the $10B+ AV capital drag on FCF — the margin-contraction invalidation is the guardrail.

### Rank 6 — TSM (Taiwan Semiconductor, ADR) · IT / Semiconductors · ~$2.32T
- **Thesis (Subtype B):** Sole scaled leading-edge AI-accelerator foundry (Nvidia/AMD/Broadcom/hyperscaler ASICs); N2 HVM (Q4'25 start) + N2P/A16 backside-power (H2'26) extend the process lead and pricing power as AI/HPC becomes the revenue core. Q1'26 rev +40.6% USD, GM 66.2%, advanced nodes 74%; Arizona ($165B) localizes US supply under tariff exemptions. **Trend metric: USD revenue grows ≥15% YoY with gross margin ≥55% and advanced-node (<7nm) mix rising, sustained ≥4 quarters.**
- **Evidence base:** Complete — ≥8 quarters transcripts + FY24/FY25 annual reports (6-K); Q2'26 print lands **7/16/26** (after this screen).
- **Invalidation:** gross margin <55%, or USD revenue YoY <15% for 2 consecutive quarters; N2/A16 ramp timelines pushed out or <7nm wafer share declines 2 consecutive quarters; a structural AI-capex reset (hyperscaler/Nvidia order cuts; CoWoS utilization drop).
- **Momentum:** trailing-30d **+2.8%** (passes the >15% "rallying-hard" gate) but **YTD +47%** and today **−6.4%** in the semis derating → **entry-timing acceptable on 30-day, but flag elevated YTD valuation + regime risk** (hawkish/reflation is unfavorable to high-multiple long-duration semis).
- **Concentration:** new GICS sector (IT/Semis); AI-cluster correlation caution.
- **Thesis strength: High** (arguably the widest structural moat on the list), **discounted by regime/valuation.** **Readiness: READY NOW but VALUATION/REGIME-CAUTIONED** — prefer building the thesis and staging into further weakness rather than at the YTD-elevated level; the Q2 print (7/16) is a near-term evidence checkpoint.

### Rank 7 — GEV (GE Vernova) · Industrials / Electrical Equipment · ~$306B
- **Thesis (Subtype B):** Electrification/grid supercycle — Q1'26 orders $18.3B (+71% organic), backlog **$163B** (targeting $200B by 2027, a year early), gas-power equipment backlog + slot reservations 83→**100 GW** (→≥110 GW by YE26), data-center orders $2.4B in one quarter; FCF $4.8B and raised 2026 guide (rev $44.5–45.5B, FCF $6.5–7.5B). **Trend metric: gas-power slot reservations reach ≥110 GW by YE26 and total backlog grows toward $200B, with adjusted-EBITDA-margin expansion sustained.**
- **Evidence base:** **Partial by count** — GE Vernova spun off Apr-2024, so ~8 standalone quarters exist (right at the criterion-2 minimum); supplement with GE-era segment history. FY25 10-K + Q1'26 release (4/22/26).
- **Invalidation:** slot reservations stall below 100 GW or fail to reach ~110 GW by YE26; organic orders growth turns negative 2 consecutive quarters; FCF guide cut; gas-turbine slot cancellations disclosed.
- **Momentum:** ~+9.7% above 50-DMA, near 52-wk high ($1,138 vs high $1,182), very large YTD advance → **RALLYING HARD.** (Precise 30-day unavailable — FMP throttled — but 52-wk-high proximity + steep-rising 50-DMA confirm a strong trailing rally.)
- **Concentration:** Industrials (distinct sub-industry from RTX); power-theme dispersion vs CEG/VST.
- **Thesis strength: High.** **Readiness: DEFERRED pending rally pause** (criterion 6). Also weigh the ~8-quarter evidence floor and today's −3.2%/power-derating as a possible pause onset — re-screen on a ≥10–15% pullback or a stalled 30-day.

### Rank 8 — LLY (Eli Lilly) · Health Care / Pharma · ~$1.11T
- **Thesis (Subtype B + Subtype-A overlay):** Dual-modality incretin dominance — injectable tirzepatide (Mounjaro +125%, Zepbound +79% in Q1'26) compounding while oral orforglipron (Foundayo, FDA-approved 4/1/26) unlocks a structurally larger, supply-scalable (small-molecule, no cold chain) TAM; ~60% GLP-1 share. **Trend metric: incretin franchise (Mounjaro+Zepbound+orforglipron) revenue grows ≥30% YoY for ≥12 months** (Q1'26 combined +56%). **Dated catalyst overlay:** orforglipron **T2D FDA submission planned 2026**, likely decision/launch 2027.
- **Evidence base:** Complete — ≥8 quarters transcripts + FY24/FY25 10-Ks; Q1'26 release (4/30/26) + Foundayo approval (4/1/26).
- **Invalidation:** franchise revenue YoY <25% for 2 consecutive quarters; orforglipron launch materially below the oral-Wegovy ~$354M first-full-quarter benchmark, or the 2026 T2D submission slips / receives a CRL; US GLP-1 share falls below ~55%; adverse IRA/Medicare net-price outcome beyond guidance.
- **Momentum:** ~+13% above 50-DMA ($1,183 vs $1,043), near 52-wk high $1,238 → **RALLYING HARD.** (30-day proxy; FMP throttled.)
- **Concentration:** Health Care/Pharma — new sector.
- **Thesis strength: Very High (fundamentals); regime- and momentum-cautioned.** **Readiness: DEFERRED pending rally pause** (criterion 6), reinforced by the hawkish-multiple regime and the prior entry-timing NO-GO (6/12). Re-screen on a rally pause / pullback toward the 50-DMA.

### Rank 9 — BA (Boeing) · Industrials / Aerospace & Defense · ~$173B
- **Thesis (Subtype A, with a B-form rate metric):** Recovery is gated by converting a multi-thousand-unit 737/787 backlog into deliveries as production normalizes — Q1'26: 143 commercial deliveries (+10%), 737 MAX **at 42/mo ramping to 47 "this summer"** (Ortberg), operating cash flow −$179M (from −$1.6B). **Primary dated catalysts:** FAA authorization of the next 737 rate step (→47/mo); 737-7/-10 certification (2026; first deliveries 2027); 777X certification/first delivery (2026). Invalidation is cleanly public-observable. *(B-form alternative metric: trailing-3-mo 737 delivery run-rate rises above 42/mo toward 47.)*
- **Evidence base:** Complete — well beyond 8 quarters of transcripts + FY24/FY25 10-Ks; Q1'26 release (4/22/26) + monthly orders/deliveries (highest-frequency check).
- **Invalidation:** FAA does not raise the 737 rate on the guided timeline, or re-imposes/tightens a cap after a new quality escape/accident; trailing-3-mo 737 delivery run-rate fails to trend above ~42/mo (or 787 stalls <5/mo) for 2 consecutive quarters; **free cash flow fails to inflect positive in 2026**, or a new IAM stoppage / 777X or fixed-price-defense charge resets the cash timeline.
- **Momentum:** trailing-30d **−2.4%**, YTD +0.9% → not rallying (entry-timing clean).
- **Concentration:** **joins RTX in Industrials / Aerospace & Defense** — same sub-industry; correlation-bucket caution (RTX + BA + any third A&D name → monitor the >0.6 bucket, though max-3-per-bucket count cap is removed, the exposure still concentrates the theme). Still far below the 30%-of-NAV sector cap.
- **Thesis strength: Medium-High (improving).** **Readiness: DEFERRED pending catalyst + FCF confirmation**, and mindful of the **terminal re-screen NO-GO 2026-06-04** (27 days ago; "gate ACTIVATE, trigger not met"). The 42→47 rate step and a positive-FCF print are the resolving triggers — re-screen on the next FAA rate action / Q2'26 FCF inflection, with the conservative default = decline if FCF stays negative.

### Rank 10 — NKE (Nike) · Cons Disc / Textiles & Apparel · ~$63B
- **Thesis (Subtype B — borderline / NOT yet in trend):** Elliott Hill "Win Now"/"Sport Offense" turnaround — clearing excess inventory + pulling back promotional DTC to let full-price wholesale sell-through recover and re-expand underlying gross margin as the innovation pipeline refills (running is the proof point: **5 straight double-digit-growth quarters**). **But the *company-level* trend metric has not turned:** FY26 revenue $46.4B flat/−2% cc, and the Q4 GM jump (+890 bps) was ~900 bps of one-off IEEPA tariff-recovery ($986M) — underlying GM roughly flat; Greater China −17% cc, Nike Direct −9% cc. **Qualifying Subtype-B metric (not yet met): total cc revenue turns positive to ≥MSD YoY, sustained ≥4 quarters, with ex-tariff GM expanding YoY.** Do NOT classify on the running sub-segment alone.
- **Evidence base:** Complete — ≥8 quarters transcripts + FY25/FY26 10-Ks; Q4 FY26 release (6/30/26).
- **Invalidation:** total cc revenue stays negative YoY for 2 more consecutive quarters (through 1H FY27); ex-tariff gross margin fails to expand YoY in FY27; running decelerates out of double-digits or Greater China cc decline fails to narrow from −17%.
- **Momentum:** trailing-30d **−7.7%**, YTD −33% → not rallying (deep-value; +3.3% on the 6/30 print).
- **Concentration:** Cons Disc / Apparel — distinct sub-industry.
- **Thesis strength: Speculative (trend-in-waiting).** **Readiness: DEFERRED pending trend confirmation** — this is currently a management-execution story without a confirmed company-level Subtype-B metric; conservative default = decline until total cc revenue re-inflects positive with ex-tariff margin expansion. Re-screen after the FY27 Q1/Q2 prints.

---

### Shortlist summary

| Rank | Ticker | Sector | Subtype | Trend/catalyst metric | Momentum (30d) | Readiness |
|---|---|---|---|---|---|---|
| 1 | GOOGL | Comm Svcs | B (+A overlay) | Cloud rev ≥25% YoY ×4Q (was +63%) | −4.4% | **Ready now** (router-blocked) |
| 2 | AMZN | Cons Disc | B | AWS rev ≥20% YoY ×4Q (was +28%) | −6.7% | **Ready now** (router-blocked) |
| 3 | CRM | IT/Software | B | Agentforce/Data-360 ARR ≥50% YoY + cRPO ≥low-teens | −6%* | **Ready now** (router-blocked) |
| 4 | ISRG | Health Care Equip | B | Procedure vol ≥13% YoY (was +16%) | −6.5%* | **Ready now** (router-blocked) |
| 5 | UBER | Industrials/Transport | B | Gross-bookings cc ≥15% YoY (was +25%) | −0.8% | **Ready now** (router-blocked) |
| 6 | TSM | IT/Semis | B | USD rev ≥15% YoY, GM ≥55% (was +40.6%/66.2%) | +2.8% | Ready, **valuation/regime-cautioned** |
| 7 | GEV | Industrials/Elec Equip | B | Slot reservations ≥110 GW YE26; backlog→$200B | rallying* | **Deferred** — rally pause |
| 8 | LLY | Health Care/Pharma | B (+A overlay) | Incretin rev ≥30% YoY (was +56%) | rallying* | **Deferred** — rally pause |
| 9 | BA | Industrials/A&D | A (+B rate) | 737 rate 42→47/mo; FCF-positive 2026 | −2.4% | **Deferred** — catalyst/FCF (recent NO-GO 6/4) |
| 10 | NKE | Cons Disc/Apparel | B (not yet in trend) | Total cc rev →≥MSD YoY sustained | −7.7% | **Deferred** — trend confirmation |

`*` = 30-day proxy from 52-week-range position + 50-DMA posture (FMP `quote-change` was rate-throttled for these names); direction is unambiguous.

**Ready-now set for Q4 (once `div-D-202606-1` clears): GOOGL, AMZN, CRM, ISRG, UBER** (+ **TSM** with a valuation/regime caveat and a 7/16/26 Q2-print checkpoint). Adding any of these keeps every GICS sector far below the 30%-of-NAV cap and moves D toward its minimum-5 floor (currently 2). **Sector notes:** GOOGL joins DIS in Communication Services; BA joins RTX in Aerospace & Defense; the remaining ready-now names each open a *new* GICS sector (Cons Disc, IT/Software, Health Care Equipment, Ground Transport), improving book diversification. No shortlist addition requires an existing D position to close first (count cap removed; sector cap non-binding).

**Deferred set: GEV, LLY** (rally pause), **BA** (FAA rate/FCF catalyst; recent terminal NO-GO), **NKE** (company-level trend not yet turned). All deferrals specify a resolving trigger and a conservative default (decline/skip) per Decision-discipline; deferrals do not chain.
