2026-06-25
<!-- d1_scan_through_utc: 2026-06-25T22:04:37Z -->

# Daily Market Development Scan — 2026-06-25 (Thu, MT)

Scan window: 2026-06-23 16:04 MDT → 2026-06-25 16:04 MDT (~48h). **MULTI-SESSION WINDOW — no D1 ran Wed 6/24, so this covers TWO completed US sessions: Wed 6/24 and Thu 6/25.** `state.trading_day_today` confirms today `2026-06-25`, `is_trading_day=true`, `last_trading_day=2026-06-25`, `next_trading_day=2026-06-26`. The window's defining event is **Micron's FQ3 blowout (Wed 6/24 AMC)** — revenue quadrupled to $41.5B, EPS $25.11 vs ~$20.4 cons, ~86% GM, FQ4 guide to **$50B** — which **reaffirmed AI-memory demand and reignited the memory complex** (MU +15.7%, SNDK/WDC/STX up double-digits to mid-single) after last week's de-risking. But the **indices still fell both sessions** (S&P 6/24 −0.10% to 7,358.22; 6/25 −0.38% to 7,330.11) on a **megacap-AI rotation** — AAPL −6.1% on up-to-25% Mac/iPad price hikes, NVDA −1.6%, Oracle −3.1% — plus a **hot PCE print (4.1% YoY, hottest since Apr-2023)** that hardened the hawkish rate path. Cross-asset risk-off-rotation: Brent collapsed below **$73** (below pre-war levels) and gold broke **<$4,000** (−2.9%) as Hormuz tankers keep crossing; 10y yield eased to ~4.40%; banks (Fed stress-test pass + payout hikes) and homebuilders (housing bill) rallied — "rotation, not a fundamental alarm." Live marks read from the IBKR connector (Thu 6/25 close). Canonical state from BigQuery (`state.current_positions`, `state.current_regime`, `perf.kill_flags`).

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **No clean geopolitical/regulatory shock in-window; the macro story is the inflation print + the AI-leadership rotation.** The **May PCE (released Thu 6/25)** ran **+4.1% YoY (highest since April 2023)** / **+0.4% MoM** (monthly 0.1pp below consensus; annual in line) — the Fed's preferred gauge confirming reacceleration and hardening the post-Warsh hawkish case. **May durable-goods orders fell −4.5% (−$15.6B to $332.1B)**, ending a two-month streak — a growth-softening signal. Together they reinforce the standing **stagflation-tilt** read (hot inflation + softening real activity).
- **Iran / Strait of Hormuz — de-escalation now decisively priced.** Tankers continue crossing the reopened Strait; **Brent fell ~4.3% to ~$73.7 (below pre-war levels), erasing the last wartime risk premium**, and **gold dropped −2.9% to ~$3,999, breaking <$4,000 for the first time since November**. The shock overlay is **receding further toward latent/benign** — consistent with (and slightly more benign than) the 6/1 regime's `shock_overlay=latent`.

### 2. Scheduled events that resolved in-window (US universe, mkt cap ≥ $2B)

- **Micron (MU) FQ3 FY26 — Wed 6/24 AMC — the window's marquee print.** Revenue **$41.46B** (vs ~$35.8B cons; +346% YoY, +74% QoQ), adj EPS **$25.11** (vs ~$20.4 cons), GAAP net income $28.24B, GM ~84.9–86%. FQ4 guide **revenue ~$50.0B ±$1.0B** (vs ~$43.6B cons), GM ~86%, EPS ~$31.00. Cited "multi-year Strategic Customer Agreements" for durability. Reaction: regular session −0.44% ($1,047.20) → after-hours +14–15% → **6/25 close $1,213.56 (+15.74% close-to-close)**, a fresh record area; Wedbush/Citi PT→$1,400. **Memory complex ripped in sympathy** (SNDK +15–20%, WDC +5%, STX +4%; DRAM ETF +9%, SOXX +2%).
- **FedEx (FDX) Q4 FY26 — reported Tue 6/23 AMC; Day-0 reaction 6/24.** Beat: adj EPS **$6.31** (vs ~$5.92 cons), revenue **$25.0B** (vs ~$24.2B). Initiated CY2026 guide **$16.90–18.10** EPS (~20% growth in the transition year as it moves to a Dec-31 fiscal year); FedEx Freight (FDXF) spun off June 1, its own call 6/25. Day-0 was a muted **sell-the-news** (~−2.8% off the ~$325.9 pre-print close to the $316.83 6/24 close), then **+3.98% on 6/25** to $329.44 (Freight-call/recovery). **No single-session ≥5% close-to-close** → not B-eligible (see Opportunity Check).
- **Apple (AAPL) — price-hike announcement (6/25).** Apple raised Mac/iPad prices by **up to 25%** (tariff cost pass-through read); shares fell **−6.12% close-to-close to $275.15** — a clean ≥5% idiosyncratic post-event move (see Opportunity Check).
- Big banks **passed the Fed's stress tests and lifted payouts** (JPMorgan, Goldman leading) — supports the financials bid. Smaller in-window prints (KBH, Paychex, Qualcomm investor day 6/24) not index-moving.

### 3. Large single-name moves ≥5% close-to-close (mkt cap ≥ $2B, event-attributable)

All measured 6/24→6/25 close-to-close (FMP):
- **MU +15.74%** ($1,213.56) — FQ3 blowout beat-and-raise (own earnings event). *Positive pop; info-driven repricing — see Opportunity Check (screened, declined for B).*
- **SNDK +~15–20%, WDC +~5%, STX +~4%** — memory-complex **sympathy** to MU (not own events) → not B-eligible.
- **AAPL −6.12%** ($275.15) — own event: up-to-25% Mac/iPad price hikes (tariff read). *Negative move, long-fade direction → B screening hit; see Opportunity Check.*
- (Sub-5% notables, logged not flagged: **Oracle −3.10%** $152.65, **NVDA −1.64%** $195.74, **DIS −3.04%** — DIS is a held D position, covered in Risk analysis.)

### 4. Sector-level moves (≥2% at sector-ETF level / notable dispersion)

- **Semiconductors/memory — sharply HIGHER** post-MU (DRAM ETF +9%, SOXX +2%; SNDK/WDC/STX up): the session's clean ≥2% sector winner.
- **The defining signal is intra-tech DISPERSION / ROTATION, not uniform risk-on.** Memory ripped while **megacap-AI leaders fell** (AAPL −6%, NVDA −2%, Oracle −3%, MSFT ~−2.3%), so the **Nasdaq/S&P closed lower both days even on the MU beat**. Simultaneously **financials** (stress-test pass + payout hikes) and **homebuilders** (housing bill) rallied, and **Dow outperformed** (third straight session of orderly de-risking/rotation). **Energy lower** (Brent <$73). This memory-vs-megacap and cyclical-vs-tech dispersion is the E-relevant read (Opportunity Check).

### 5. Notable commentary

- **Rate-path hardening under the tape:** the hot **PCE 4.1%** reinforces the post-Warsh hawkish repricing; BofA stayed constructive on memory ("supply-side discipline → more durable cycle") post-MU. Dip-buy framing on memory dominates; the megacap-AI names are the funding source for the rotation.
- **Quarter-end digestion:** Equity Clock flags the S&P pressuring its **50-day MA (~7,349)** — closed 6/25 at 7,330, marginally below — in a "notoriously mean-reverting" late-June, end-of-quarter rebalancing window. Watch item, not a trend break (see Regime Check).

---

## ANALYSIS — RISK TO EXISTING POSITIONS

Open book (canonical `state.current_positions`, cross-checked vs IBKR `get_account_positions` — **set matches**: B = AZO, HCA, MDT, ZBRA; D = DIS, RTX; plus the SGOV park (92.30 sh) and an immaterial **IBM dust residual ($0.18, 0.0007 sh)** — not a tracked position, no action). Live marks = Thu 6/25 close.

### MECHANICAL EXIT-TRIGGER SWEEP (run for every open position)

| Pos | Strat | Live (6/25) | Convergence target | Time-exit | Trigger? |
|-----|-------|-------------|--------------------|-----------|----------|
| AZO | B | 3061.74 | 3200 | 2026-07-24 | **No** (3061.74 < 3200; below target) |
| HCA | B | 387.15 | 442.85 | **2026-06-27 (Sat)** | **No** — target not hit; **time-exit fires first triggering session Mon 6/29** (6/27 is a weekend) |
| MDT | B | 80.60 | 90 | 2026-07-31 | **No** (80.60 < 90) |
| ZBRA | B | 243.39 | 264 | 2026-07-13 | **No** (243.39 < 264; drifted further from target) |
| DIS | D | 98.50 | — | — | **No** (no mechanical triggers) |
| RTX | D | 186.52 | — | 2027-04-27 | **No** (far-dated) |

**No convergence target hit. No time-based exit due today.** Nearest is **HCA time-exit 2026-06-27** — but 6/27 is a Saturday, so the first session where `today ≥ 2026-06-27` is **Mon 6/29** (6/26 Fri is still < 6/27). D2 will craft the HCA time-exit on the **6/29** session, not before. All four B convergence targets remain above current price (underwater mean-reversion longs awaiting reversion-up or the time-stop).

### PER-STRATEGY KILL-TRIGGER SWEEP

From `perf.kill_flags` (engine as of 6/24 close): **B** deployed_unit_value **1.0513**, current_drawdown **0%** (at peak), no flags; **D** deployed_unit_value **0.9898**, current_drawdown **−1.93%**, no flags. Both drawdowns are an order of magnitude inside the −50% drawdown-kill threshold; neither strategy has doubled (no runaway-success; B 5 closed trades vs 25-gate, D 0 vs 30-gate). Refreshing against today's live marks: book daily P&L was small and mixed (B: AZO −0.35, HCA +0.08, MDT +0.19, ZBRA −0.66 → ~−0.74 net; D: DIS −0.82, RTX +0.23 → ~−0.59) — no sharp intraday move that would materially move either strategy's drawdown. **No kill or runaway trigger; no strategy termination.**

### Judgment-laden thesis-invalidation check (does any Development trigger an entry-record exit criterion?)

- **AZO, HCA, MDT (B — auto-retail / healthcare / med-tech defensives):** Zero exposure to the memory/megacap-AI rotation. Net roughly flat-to-green on the rotation. No invalidation criterion met. **HOLD.** (HCA time-stop fires 6/29 mechanically — above.)
- **ZBRA (B — enterprise data-capture/automation hardware, the one tech-adjacent name):** −1.77% to 243.39, modestly caught in the megacap-tech de-risking; drifted further from the 264 target. This is **broad sector rotation, not a ZBRA-specific public event or guidance change** — no entry-record invalidation criterion is triggered. Time-exit 7/13 (~2.5 wks) is the mechanical backstop. **HOLD** (monitor).
- **DIS (D — media/comm-services):** −3.04% today; ~−5% over the window (103.32 → ~98.05). Verified **no DIS-specific catalyst** (no earnings, no downgrade, no park/streaming news in-window) — the move is **XLC comm-services sector beta** (XLC ~−4.6% over a comparable window; DIS tracked it), part of the megacap/comm-services leg of the rotation. Multi-year narrative thesis intact; no invalidation criterion met. **HOLD.**
- **RTX (D — defense/aerospace):** +0.79% to 186.52, unrealized +$1.54. A **modest relative winner** despite oil/geopolitics de-escalating (Hormuz fully reopening), holding on the financials/cyclical-rotation bid and structural defense-spending optics. Thesis intact. **HOLD.**

**No position shows thesis invalidation. No judgment-laden exit triggered.**

### Watchlist candidates — status change?

The A-queue is dominated by AI/semi/megacap-tech names (MU, NVDA, QCOM, INTC, AMD, DELL, HPE, SNOW, ORCL, AVGO, etc.), all carrying a standing **"valuation-reset caveat"** for the eventual A-router-ACTIVATE. The window **mixed** that caveat: **memory names (MU/SNDK/WDC) re-compressed entry quality UP** (MU back to record area on the blowout — caveat re-tightens for the memory cohort), while **megacap-AI leaders (AAPL −6%, NVDA, ORCL) de-rated** (caveat partially relieved for that cohort). No A-queue name is invalidated. **Net: A-queue unchanged structurally; the AI-leadership read is now bifurcated (memory re-rated up, megacap-AI rotated down) — a clean input for the July M1a/M1b.**

---

## ANALYSIS — OPPORTUNITY CHECK

Evaluated every Development for a new A/B/C/E entry candidate, not limited to watchlist names.

- **Strategy B (post-event mispricing, ≥5% close-to-close on a qualifying public event; long-biased in practice per Rev 36):**
  - **MU +15.74% (FQ3 blowout) — SCREENED, DECLINED.** Clears criterion-1 magnitude, but it is a **positive pop** whose only B-tradable direction is a **SHORT** to fade — and B does **not** take shorts in the risk-on/neutral regime the router activates in (Rev 36 long-bias; the entire late-May/June AI-print cohort — DELL/HPE/SNOW/NTAP — is SP1 / "B-vs-A foreclosure"). The move is **information-driven** (revenue quadrupled, guide to $50B, multi-year SCAs = genuine re-rating, not sentiment overshoot → criterion-4 flaw), and MU is **already A-queued** (multi-quarter AI-memory ramp = Strategy A territory). **Not surfaced as an actionable B candidate.**
  - **AAPL −6.12% (up-to-25% Mac/iPad price hikes) — B SCREENING HIT → surface for thesis construction.** A clean ≥5% **negative** post-event move on an idiosyncratic public event, in the **long-fade direction B does take**; mega-cap ($4.0T) and mega-liquid (criteria 1/instrument-eligibility met); no A position open in AAPL (criterion 5 OK; A = DNA). **Caveat (strong prior for criterion-4 NO-GO):** a 25% price hike is most naturally read as **tariff cost pass-through**, so the −6% plausibly prices a **structural tariff/demand overhang (SP4c-adjacent / Pattern-N information-confirmation), not a sentiment overshoot** — thesis construction must clear criterion 4 (is the drop over-sized vs fundamentals, or correct repricing of tariff exposure?). Route to a **B thesis-construction session** per Strategy.md (separate session); "NO-GO records are context, not barriers" — but this faces a high bar.
  - FDX (+3.98% 6/25, ~−2.8% Day-0 6/24) — **no single-session ≥5% close-to-close** → fails criterion 1; not B-eligible. SNDK/WDC/STX are MU sympathy (not own events) → not B-eligible.
- **Strategy A (catalyst within 6 months):** Router = **DO-NOT-ACTIVATE** → any A candidate routes to the Watchlist A-queue, no thesis now. The window created **no new forward A catalyst**; it re-priced the existing A-queue cohort (memory up, megacap-AI down — noted above). No add required.
- **Strategy C (defined-risk options around a known event ≤45 days):** Router = HYBRID. The **FOMC 7/28–29 meeting (~4.5 weeks out, within 45 days)** became **more binary/market-moving** after the hot PCE (4.1%) hardened the rate-hike path — a candidate event for **W1's C calendar**, not a same-day D1 action (C structures build 7–10 days ahead; this is ~4+ weeks out). **No immediate C candidate.**
- **Strategy E (pair/divergence):** Router = ACTIVATE but **execution-feasibility-deferred at current book size (ETF-substitution-required per M3)**. The window produced a clean E-relevant **divergence**: **memory/storage (MU/SNDK/WDC) ripped while megacap-AI (AAPL/NVDA/ORCL) fell**, plus a cyclical-vs-tech rotation (financials/homebuilders up). This intra-tech (memory-vs-megacap-AI) dispersion is **noted for the M2/M4 pair screen**; not actionable at current size. **No actionable E entry.**

**No new actionable entry candidate requiring immediate action.** One B candidate (**AAPL**) is surfaced for a separate thesis-construction session, carrying a strong tariff-overhang criterion-4 prior.

---

## ANALYSIS — REGIME CHECK

Does any Development plausibly shift a strategy's router-activation state enough to warrant an inter-monthly router review? **Default NO; high bar.**

The window is **directionally consistent with the standing 6/1 regime (`stagflation-tilt + risk-on`), and reinforces several of its axes rather than breaking them**: hot **PCE 4.1%** hardens `inflation_trend=reaccelerating` + `policy_stance=hawkish`; **durable goods −4.5%** reinforces `growth_momentum=decelerating`; **Brent <$73 / gold <$4,000 / Hormuz reopening** push `shock_overlay` further toward benign/latent. The **MU blowout reaffirms AI-memory demand**, relieving the prior D1's watch item ("whether AI-derisking broadens") — the AI complex did not break, it **rotated** (memory re-rated up, megacap-AI down; financials/homebuilders bid = "rotation, not a fundamental alarm"). None of the **active** routers flip on this: B/D/E stay ACTIVATE, A stays DO-NOT-ACTIVATE, C stays HYBRID. **One thing to watch (forward, not a trigger):** the S&P closed marginally **below its 50-day MA (~7,349 → 7,330)** in a quarter-end digestion — if this extends into a confirmed **SPY Trend = DOWN**, it would gate Strategy B's router; but a single close below the 50-DMA in an orderly rotation is **not** a DOWN regime (current `SPY_TREND=NEUTRAL`, `EQUITY_BREADTH=HEALTHY`), and SPY-trend/technical-signal scoring is M1a's lane for the July M1. **No inter-monthly router review recommended.**

---

## RECOMMENDED ACTIONS

- **Exits triggered:** **None today.** No convergence target hit, no time-exit due today, no thesis-invalidation exit, no kill/termination trigger. **Watch: HCA (B) time-exit due 2026-06-27 (Sat) → fires the Mon 6/29 session** (`today ≥ 6/27` first true on 6/29); D2 crafts the HCA time-exit then.
- **New entry candidates:** **AAPL (Strategy B)** — −6.12% close-to-close on the up-to-25% Mac/iPad price-hike announcement; ≥5% negative post-event move in B's long-fade direction, mega-cap/mega-liquid, no A conflict. **Route to a full B thesis-construction session** (separate session per Strategy.md entry criteria). Flag for the thesis: the move is plausibly **information-driven (tariff cost pass-through → SP4c-adjacent / Pattern-N structural-tariff overhang)** rather than a sentiment overshoot — criterion 4 faces a high bar. (MU +15.7% screened and **declined**: positive pop / info-driven blowout / A-queue territory / would require a short B does not take.)
- **Watchlist updates:** No add/remove. Context note for the **July M1**: the AI-leadership read is now **bifurcated** — memory (MU/SNDK/WDC) re-rated UP (A-queue valuation-reset caveat re-tightens for that cohort), megacap-AI leaders (AAPL/NVDA/ORCL) rotated DOWN (caveat partially relieved). Plus a hot PCE (4.1%) hardening the hawkish path and an E-relevant memory-vs-megacap dispersion for the M2/M4 pair screen.
- **Router reviews recommended:** **None** (high bar not met; window reinforces the standing hawkish/stagflation-tilt regime). Forward watch for July M1a: the S&P's marginal 50-DMA breach (potential SPY-Trend gate for B) and whether the megacap-AI rotation broadens.
