2026-W26

# Weekly Post-Event Screen — Strategy B (W2)

**Run:** 2026-06-28 (Sun, non-trading; ISO week 2026-W26). Next trading session 2026-06-29.
**Prior-10-trading-day window screened:** 2026-06-12, 06-15, 06-16, 06-17, 06-18, 06-22, 06-23, 06-24, 06-25, 06-26 (June 19 = Juneteenth holiday, excluded).
**Regime gate (per `state.current_regime`, last M1b 2026-06-03):** SPY_TREND = NEUTRAL (≠ DOWN), VIX ≠ HIGH → **B = ACTIVATE**, long-biased in practice (Rev 36: B does not take shorts in risk-on/neutral regimes; pop-fades run into momentum/2.20-trap). Open B book: AZO, HCA (exit-pending), MDT, ZBRA. Open A book: **none** (A = DO-NOT-ACTIVATE) → no A↔B exclusion binds this week.
**Macro overlay (criterion-1 attribution):** the window straddles the **FOMC 6/17 hawkish surprise (Warsh debut, hike-odds spike)** and a **6/22–6/26 AI-cost / data-center / mega-cap-semi selloff** (NVDA worst week in >1yr). Much of the multi-directional ≥5% tape in MU / ON / MRVL / GNRC is macro/sector beta, **not** a discrete single-name public event — flagged per-name below. Criterion 1 requires the move be attributable to a *discrete public event*; macro/sector-beta days are not B-eligible triggers.

Data: close-to-close magnitudes and ADV$ from the IBKR connector (`get_price_history`/`get_price_snapshot`, authoritative); market caps from FMP batch-quote; event attribution from web/news + FMP. Prior decisions from `events.decision_log`.

---

## PART 1 — Universe (US equities, mkt cap ≥ $2B, 30-day ADV ≥ $10M, ≥5% close-to-close move on an event day in the prior 10 trading days, attributable to a public event)

Sorted by event date (most recent first). All names listed clear the $2B cap and $10M ADV gates by wide margins (ADV$ shown). "Move" = close-to-close on the event day.

| Ticker | Name | Event date | Event type | Move | Mkt cap | ADV$ | Direction | Source / note |
|---|---|---|---|---|---|---|---|---|
| ON | ON Semiconductor | 2026-06-26 | M&A (acquirer) — $7B all-stock acquisition of Synaptics (SYNA) announced 6/25 AC, 1.350 ratio / ~19% premium; read as dilutive + off-strategy (ON +119% YTD on an AI-power-semi narrative, buying IoT/touch) | **−23.66%** ($118.74→$90.65) | $35.5B | ~$0.8B | DOWN | onsemi/SYNA deal PR; news. **Already B NO-GO 6/27 (SP4e+PatternN).** |
| MU | Micron Technology | 2026-06-25 | Earnings — Q3 FY26 *record* results (HBM / AI-memory blowout) | **+15.74%** ($1,048.51→$1,213.56) | $1.28T | ~$38B | UP | Earnings. (Gave back −6.69% on 6/26.) +325% YTD; near 52-wk high $1,255. |
| AAPL | Apple | 2026-06-25 | Corporate action — announced consumer price increases (read negatively: demand/tariff-cost signal) into the AI-cost tech selloff | **−6.12%** ($293.08→$275.15) | $4.17T | ~$10B | DOWN | News. Mixed attribution (price-hike + sector beta). **Already B NO-GO 6/25 (SP4c+PatternN).** |
| ACN | Accenture | 2026-06-18 | Earnings — FQ3 FY26: print beat (rev +6% $18.7B, EPS +9% $3.80) but **weak bookings + FY guide trimmed**; TD Cowen downgrade Buy→Hold, PT $258→$150 | **−17.97%** ($156.01→$127.98) | $79B | ~$0.9B | DOWN | Earnings. (Pre-print −5.74% on 6/17; further −7% on 6/22.) −52.8% YTD. **Already B NO-GO 6/18 (PatternN).** |
| KMX | CarMax | 2026-06-18 | Earnings — Q1 FY27 beat (unit-sales growth + margin expansion) | **+13.14%** ($47.43→$53.66) | $7.5B | ~$0.11B | UP | Earnings. (Pre-print −8.98% on 6/17.) +36.9% YTD. No prior NO-GO. |
| GNRC | Generac | 2026-06-22 | Hyperscale data-center backup-power supply agreement | **+5.87%** ($279.15→$295.54) | $16.4B | ~$0.13B | UP | News. **Round-tripped entirely** in the data-center selloff (−7.11% 6/23, −5.60% 6/26). No prior NO-GO. |
| MRVL | Marvell Technology | 2026-06-15 | Computex / Jensen Huang "next trillion-dollar company" endorsement + AI-semi tape | **+10.43%** ($279.70→$308.88) | $233B | ~$10B | UP | News. Whipsawed both directions all month (−9.78% 6/16, +7.27% 6/18, −9.36% 6/23) = AI-tape, not a clean discrete event. **Window expired.** |
| ADBE | Adobe | 2026-06-12 | Earnings — Q2 FY26 beat (EPS $5.96 vs $5.82) but AI-disruption-to-creative-software fear (beat-and-fade) + CFO-exit overhang | **−6.76%** ($218.80→$204.02) | $80B | ~$1.1B | DOWN | Earnings. −44.7% YTD. **Already B NO-GO 6/21 (SP4+PatternN). Window expired.** |
| CCL | Carnival | 2026-06-12 | Sector sympathy — Royal Caribbean's strong 2026 outlook ignited the cruise sector | **+8.20%** ($25.99→$28.12) | $40B | ~$0.5B | UP | News (peer-driven, not a CCL-specific event). **Window expired.** |

### Examined and EXCLUDED (with reason)
- **SYNA (Synaptics)** — M&A *target* of ON's all-stock fixed-ratio (1.350) offer. Now trades as merger-arb pegged to ON's price, **not** an independent post-event mispricing. B's convergence-target closed list (price level / next earnings / next FDA / next FOMC / index inclusion) does **not** admit "deal close." Structurally B-ineligible.
- **LEN (Lennar)** — qualifying close-to-close was +6.41% on **6/24**, but that is a **macro homebuilder/rate move, not a discrete LEN event**; the actual earnings (6/11→6/12) were **−4.90%**, sub-threshold. Criterion 1 (attributable to a discrete public event) fails.
- **NU (Nu Holdings)** — +5.70% on 6/26 with **no identifiable discrete public-event catalyst** (a rebound day); the mid-June CFO-transition news did not produce a ≥5% close-to-close. Criterion 1 fails.
- **DRI (Darden)** — reported 6/25; adj-EPS beat but **revenue missed**, SSS soft, FY27 guide low end → shares fell ~1%. **No ≥5% close-to-close.** Criterion 1 (mechanical) fails. (The web-circulated "+9.3%" did not appear in close-to-close data.)
- **FDX (FedEx)** — reported 6/23 (EPS $6.31 vs $5.91 beat); largest in-window close-to-close +3.98% (6/25). **No ≥5% move.** Criterion 1 fails.
- **NKE (Nike)** — reported **6/26 after close**; reaction lands 6/29, **not yet realized in-window**. No ≥5% close-to-close yet. Carry to next week's screen.
- **JBL, PAYX, GIS, KR** — examined; no ≥5% close-to-close in the window. Excluded.

---

## PART 2 — Ranked shortlist (priority for W4 → `PENDING_ANALYSIS` thesis-construction)

**Default assumption: the market reaction is correct.** A thesis must affirmatively establish an over- or under-sized reaction vs. fundamental implications, grounded in event details + recent fundamentals + retrieved comparable historical reactions, and survive criterion-4 (information- vs sentiment-driven). B is long-biased: positive-reaction pops are only takeable as LONG under-reactions, never shorted; negative-reaction selloffs are takeable as LONG mean-reversion-up only if the drop is a *sentiment overshoot*, not information.

**This is a low-yield week.** The four freshest, highest-magnitude reactions (ON −23.66%, ACN −17.97%, AAPL −6.12%, ADBE −6.76%) were **all already adjudicated B NO-GO within the last 10 days on these same events** (see §"Recently adjudicated" below). Absent *new evidence*, they are not re-queued ("NO-GO records are context, not barriers" — the context here is a documented decisive flaw, days old, with no change). The only un-adjudicated in-window candidates are **MU, KMX, GNRC**.

Days-remaining counted as trading days from the next session (2026-06-29) through the last valid entry day (10th trading day from the event; July 3 holiday accounted for).

### TOP-5 tier

**1. KMX — CarMax** · +13.14% (6/18 earnings beat) · **window closes 2026-07-02 → 4 days remaining (URGENT)**
- (a) Hypothesized mispricing direction/magnitude: **modest possible UNDER-reaction (LONG)** — a clean operating inflection (unit-sales growth + margin expansion after a multi-year used-car downcycle) could be under-extrapolated; but base case is fairly-priced-to-SP1.
- (b) Supporting public info: Q1 FY27 beat on units + gross margin; +36.9% YTD off a $30 low (recovery underway); used-car non-AI cyclical (no AI-disruption overhang to fade against).
- (c) Convergence indicators to watch: post-print sell-side PT cluster (aggressive multi-firm raises → SP1 NO-GO; muted/mixed → leaves an under-reaction anchor); whether the +13% holds above the pre-print ~$47 base (it gave back to $52.76, ~85% retained); next earnings as the in-window-or-not convergence marker.
- (d) Days remaining: **4** (closes 7/2).
- (e) Tier: **top-5**. Highest fresh-candidate conviction, but URGENT — if W4 enqueues, due_date = today/6-29 so D2 runs before the window shuts.

**2. MU — Micron** · +15.74% (6/25 earnings, record results) · **window closes 2026-07-09 → 8 days remaining**
- (a) Hypothesized mispricing: **likely NONE / fairly-to-over-priced.** Base case is canonical **SP1** (record AI-memory beat met by sell-side bull-ratification) compounded by **B-vs-A foreclosure** (a multi-quarter HBM ramp is Strategy-A territory, not a 60-day B convergence) — both decisive-flaw routes.
- (b) Supporting public info: Q3 FY26 record rev/EPS, HBM demand; +325% YTD, near 52-wk high $1,255; the +15.74% pop already gave back −6.69% the next day (partial fade).
- (c) Convergence indicators: PT-raise breadth/magnitude (mega-raises → SP1); whether the move holds vs. fades toward the pre-print $1,048; any in-window catalyst (next print is late-Aug = outside 60 days).
- (d) Days remaining: **8**.
- (e) Tier: **top-5** — biggest fresh positive reaction; warrants a documented thesis pass to confirm SP1/B-vs-A NO-GO vs. any under-reaction angle.

**3. GNRC — Generac** · +5.87% (6/22 data-center backup-power deal) · **window closes 2026-07-06 → 5 days remaining**
- (a) Hypothesized mispricing: **likely NONE.** The catalyst pop **round-tripped completely** (−7.11% 6/23, −5.60% 6/26) inside the data-center selloff — a "move-completely-faded-by-Day-N" signature (PINS-analogue); the market has already mean-reverted, leaving no residual mispricing to converge, and the residual tape is sector-beta-contaminated.
- (b) Supporting public info: hyperscale backup-power supply agreement; +116% YTD; but net move ≈ 0 after the giveback.
- (c) Convergence indicators: does the stock stabilize above the pre-deal ~$279 (residual deal value) or settle below (deal value erased); data-center / power-IPP sector beta.
- (d) Days remaining: **5**.
- (e) Tier: **top-5 (low)** — include for a thesis pass, but the faded move makes a GO unlikely.

*(Only three un-adjudicated in-window candidates exist this week; the top-5 tier is not padded.)*

### Rest tier
- **MRVL — Marvell** (+10.43% 6/15 Computex endorsement) — **window EXPIRED** (0 days; last valid entry was 6/26). Also AI-tape multi-directional (info-driven re-rating, SP1-adjacent). Not actionable. Listed for completeness.
- **CCL — Carnival** (+8.20% 6/12, RCL-outlook sector sympathy) — **window EXPIRED** (0 days). Peer-driven, not a CCL event. Not actionable.

### Recently adjudicated — prior B NO-GO within the entry window; NOT re-queued (no new evidence)
Per "NO-GO records are context, not barriers": these remain re-screenable, but each was declined on the *same event now in window*, days ago, with a documented decisive flaw. Re-queue **only on new evidence** (the specific trigger noted). No such evidence exists as of this screen.
- **ON — ON Semiconductor** (−23.66% 6/26; window open to ~7/10, 9 days) — B NO-GO **2026-06-27**, *SP4e [overlay: PatternN]*: acquirer all-stock-dilution structural overhang + sell-side downgrade ratification + sector-beta contamination of the move. The −24% is information-driven (capital-allocation re-rating + dilution), not a sentiment overshoot. **Re-screen trigger:** a sell-side re-rating that reverses the downgrade ratification, a deal-terms change/withdrawal, or ON management strategic clarification before window close.
- **AAPL — Apple** (−6.12% 6/25; window to ~7/9, 8 days) — B NO-GO **2026-06-25**, *SP4c [overlay: PatternN]*: tariff/price-hike structural overhang; move is sector-beta-contaminated (AI-cost selloff). **Re-screen trigger:** a discrete Apple-specific reversal (e.g., demand-data refutation of the price-hike concern) before window close.
- **ACN — Accenture** (−17.97% 6/18; window to ~7/2, 4 days) — B NO-GO **2026-06-18**, *PatternN*: information-driven negative reaction (AI-disruption-to-IT-services demand + bookings cut, an SP4-style structural overhang requiring multi-quarter resolution; next print late-Sept is outside the 60-day window → criterion-3 weak). Subsequent further decline (−7% 6/22) validates the NO-GO. **Re-screen trigger:** a bookings/guidance stabilization datapoint before window close (none expected pre-window-close).
- **ADBE — Adobe** (−6.76% 6/12) — B NO-GO **2026-06-21**, *SP4 [overlay: PatternN]*: CFO-exit overshoot on a beat-and-raise + AI-disruption overhang. **Window EXPIRED.**

---

### Self-check
- Universe screened to mkt cap ≥ $2B, ADV ≥ $10M, ≥5% close-to-close on a discrete-public-event day in the prior 10 trading days; macro/sector-beta-only days excluded per criterion 1. ✔
- Names with an open Strategy A position excluded — none exist this week (A = DO-NOT-ACTIVATE). ✔
- Open B holdings (AZO/HCA/MDT/ZBRA) not surfaced as new entries. ✔
- Prior `events.decision_log` NO-GOs surfaced as context (not barriers); same-event recent NO-GOs not re-queued absent new evidence. ✔
- PART 2 ranked with mispricing direction/magnitude, supporting info, convergence indicators, days-remaining, and priority tier per candidate, ordered for W4 → `PENDING_ANALYSIS` (urgency surfaced: KMX 4 days). ✔
