2026-W27

# Weekly Post-Event Screen — Strategy B (W2)

**Run:** 2026-07-05 (Sun, non-trading; ISO week 2026-W27). Next trading session 2026-07-06.
**Prior-10-trading-day window screened:** 2026-06-18, 06-22, 06-23, 06-24, 06-25, 06-26, 06-29, 06-30, 07-01, 07-02 (June 19 = Juneteenth holiday and July 3 = July-4-observed holiday, both excluded).
**Regime gate (per `state.current_regime`, last M1b/M4 2026-07-01):** SPY_TREND = NEUTRAL (≠ DOWN), VIX 16.45 = NORMAL (≠ HIGH) → **B = ACTIVATE (confirmed)**, long-biased in practice (Rev 36: B does not take shorts in risk-on/neutral regimes; pop-fades run into momentum / squeeze / the 2.20 textbook-rational trap). Open B book: **MDT only** (AZO + ZBRA convergence-exited 7/2; HCA time-exited 6/29). Open A book: **none** (A = DO-NOT-ACTIVATE, confirmed 7/1) → no A↔B exclusion binds this week.
**Macro overlay (criterion-1 attribution):** the freshest part of the window (6/29–7/2) is dominated by a **7/2 AI-capex-sentiment shock**: Zuckerberg told Meta employees "AI agents are advancing slower than expected" and reports surfaced that Meta is building a cloud business to sell AI compute (an AWS competitor). This hit the **memory + semi-cap-equipment complex** (Samsung/SK Hynix/Micron; ONTO −12.5%, NVMI −6.5%, and per the 7/2 session VICR/ACLS/VECO/UCTT/MXL/AEHR/Arteris all −17% to −20%). The SK Hynix rebound note characterized it verbatim as *"a correction in sentiment after investors appeared to overreact to Meta's cloud-computing plans"* — i.e. a **sector-wide sentiment read-across, not a discrete single-name public event**. Per criterion 1, sector-beta days are NOT B-eligible triggers; the semi-cap cluster is excluded below (same discipline that excluded the 6/22–26 AI-cost selloff last week).

Data: close-to-close magnitudes and ADV$ from the IBKR connector (`get_price_history`/`get_price_snapshot`, authoritative); market caps from FMP (or derived shares×price where FMP lacked the name); event attribution from FMP news + the 7/2 news corpus. Prior decisions from `events.decision_log`.

---

## PART 1 — Universe (US equities, mkt cap ≥ $2B, 30-day ADV ≥ $10M, ≥5% close-to-close move on an event day in the prior 10 trading days, attributable to a discrete public event)

Sorted by event date (most recent first). All listed names clear the $2B cap and $10M ADV gates by wide margins (ADV$ shown). "Move" = close-to-close on the event day (IBKR ONE_DAY bars, authoritative; corporate-actions checked — none distort these).

| Ticker | Name | Event date | Event type | Move | Mkt cap | ADV$ | Direction | Source / note |
|---|---|---|---|---|---|---|---|---|
| RIVN | Rivian Automotive | 2026-07-02 | Guidance — Q2 deliveries beat + **FY delivery forecast RAISED** | **+8.44%** ($17.18→$18.63) | $23.4B | ~$567M | UP | FMP news + IBKR (cid 525768800). Reclaimed 50/200-day (~$15.6/$15.8). **NEW — un-adjudicated.** |
| AVAV | AeroVironment | 2026-07-02 | Contract — **$500M U.S. DoW counter-drone (C-UAS) Army award** (announced 7/1 AH) | **+10.70%** ($172.44→$190.89) | ~$8.5B | ~$289M | UP | FMP news + IBKR (cid 42464367). Second in-window event for AVAV. **NEW — un-adjudicated.** |
| AVAV | AeroVironment | 2026-06-30 | Earnings — **FQ4 blowout**: record rev $642M (+31% organic); funded backlog $1.2B (from $726.6M) | **+18.76%** ($139.00→$165.07) | ~$8.5B | ~$289M | UP | FMP news + IBKR. Primary/cleaner B trigger for AVAV; SCAR-cancellation securities class-action overhang (below). **NEW — un-adjudicated.** |
| ON | ON Semiconductor | 2026-06-26 | M&A (acquirer) — $7B all-stock acquisition of Synaptics (SYNA), ~19% premium; read as dilutive + off-strategy | **−23.66%** ($118.74→$90.65) | $35.5B | ~$0.8B | DOWN | **Already B NO-GO 2026-06-27 (SP4e [overlay: PatternN]).** Window last entry ~7/10. |
| MU | Micron Technology | 2026-06-25 | Earnings — Q3 FY26 *record* results (HBM / AI-memory blowout) | **+15.74%** ($1,048.51→$1,213.56) | $1.28T | ~$38B | UP | **Already B NO-GO 2026-06-28 (SP1 [overlay: SP3]).** Gave back −6.69% 6/26. Window last entry ~7/9. |
| AAPL | Apple | 2026-06-25 | Corporate action — consumer price increases read negatively (demand/tariff-cost signal) into the AI-cost selloff | **−6.12%** ($293.08→$275.15) | $4.17T | ~$10B+ | DOWN | **Already B NO-GO 2026-06-25 (SP4c [overlay: PatternN]).** Window last entry ~7/9. |
| GNRC | Generac | 2026-06-22 | Hyperscale data-center backup-power supply agreement | **+5.87%** ($279.15→$295.54) | $16.4B | ~$0.13B | UP | **Already B NO-GO 2026-06-28 (SP1 [overlay: SP4]).** Round-tripped fully (−6.5% more on 7/2 to $252.66; −14.4% on the week). Window last entry ~7/6 (≈closing). |
| ACN | Accenture | 2026-06-18 | Earnings — FQ3 beat but weak bookings + FY guide trimmed; TD Cowen downgrade Buy→Hold | **−17.97%** ($156.01→$127.98) | $79B | ~$0.9B | DOWN | **Already B NO-GO 2026-06-18 (PatternN).** Window **EXPIRED** (last valid entry was 7/2). |
| KMX | CarMax | 2026-06-18 | Earnings — Q1 FY27 beat (unit-sales growth + margin expansion) | **+13.14%** ($47.43→$53.66) | $7.5B | ~$0.11B | UP | **Already B NO-GO 2026-06-28 (SP1 [overlay: SP4c]).** Window **EXPIRED** (last valid entry was 7/2). |

### Examined and EXCLUDED (with reason)
- **7/2 semiconductor / semi-cap-equipment complex** — VICR (−19.2%), ACLS (−19.0%), VECO (−18.5%), UCTT (−17.8%), MXL (−17.1%), AEHR (−17.1%), Arteris/AIP (−20.0%), OUST (−17.0%), plus ONTO (−12.5%) / NVMI (−6.5%). Magnitudes clear 5% but the driver was the **7/2 Meta-AI-capex sentiment read-across** (Zuckerberg "AI agents advancing slower than expected" + Meta-building-a-cloud reports), explicitly characterized as a **sentiment overreaction, not a fundamental reset** and NOT a discrete company-specific event for any single name. **Criterion 1 (attributable to a discrete public event about the name) fails — sector beta.** (Same treatment as last week's 6/22–26 AI-cost selloff.) *No individual name in this cluster had its own qualifying discrete event; several are also likely sub-$2B (AEHR, Arteris, OUST) or borderline. If a specific name here later prints a company event, it re-enters on that.*
- **NKE (Nike)** — reported FQ4 on **6/30 AMC** (EPS $0.72 vs $0.11 est, ~6.5× beat; rev $10.97B). Day-0 reaction 7/1 close-to-close was **+4.90%** ($41.05→$43.06) — **below the 5% threshold**; no single in-window day ≥5%. **Criterion 1 (magnitude) fails.** Correctly declined by D2 (NKE NO-GO 7/1). Not a PART-1 qualifier.
- **CLVT (Clarivate)** — +16.7% on 7/2 ($2.22→$2.59), a discrete-looking move, but market cap ≈ **$1.9B** (~730M sh × $2.59) sits **below the $2B floor**. **Instrument-rule mcap-floor fail.** (Borderline — re-enters if it clears $2B on a subsequent event.)
- **FDX (FedEx)** — reported 6/23 (EPS $6.31 vs $5.91 beat); no in-window close-to-close ≥5% (largest was +3.98% on 6/25). Criterion 1 fails. (Carried from last week; unchanged.)
- **CCL / FDX** and the other FMP-calendar names (NKE covered above) — no additional ≥5% discrete-event day in the fresh window.
- **GNRC 7/2 −6.5%** and other 7/2 giveback days on already-listed names — continuation / sector beta, not a new discrete event (the qualifying GNRC event is the 6/22 deal, already adjudicated).

*Data-coverage note: the FMP earnings calendar for this window returned only NKE/CCL/FDX with actuals (it did not even surface AVAV's FQ4 print), so the screen was triangulated across the earnings calendar, the 7/2 biggest-gainers/losers session snapshot, and the full 7/2 news corpus. Late-June/early-July is between earnings seasons; the discrete large-cap event set is genuinely thin.*

---

## PART 2 — Ranked shortlist (priority for W4 → `PENDING_ANALYSIS` thesis-construction)

**Default assumption: the market reaction is correct.** A thesis must affirmatively establish an over- or under-sized reaction vs. fundamental implications, grounded in event details + recent fundamentals + retrieved comparable historical reactions, and survive criterion-4 (information- vs sentiment-driven). B is long-biased: positive-reaction pops are only takeable as a LONG **under-reaction**, never shorted.

**Only two fresh, un-adjudicated, in-window, ≥$2B discrete-event names exist this week: RIVN and AVAV.** Every other in-window mover (ON, MU, AAPL, GNRC, ACN, KMX) was already adjudicated B NO-GO on its own event within the last 10 days with a documented decisive flaw, and the 7/2 semi-cap cluster is sector-beta-excluded. Per "NO-GO records are context, not barriers," the adjudicated names remain re-screenable but are **not re-queued absent new evidence** (§"Recently adjudicated" below). The top-tier is therefore not padded.

Days-remaining counted as trading days from the next session (2026-07-06) through the last valid entry (10th trading day from the event; July 3 holiday accounted for).

### TOP-5 tier

**1. RIVN — Rivian Automotive** · +8.44% (7/2, Q2 delivery beat + FY delivery-guidance RAISE) · **window closes ~2026-07-16 → 9 trading days remaining**
- (a) Hypothesized mispricing direction/magnitude: **modest possible UNDER-reaction (LONG).** A Q2 delivery beat *and* a raised FY delivery forecast at a name the market has been structurally skeptical of (YTD −12.8%, trading below its recent range) could be under-extrapolated — the +8.44% may not fully price a demand/delivery inflection. Base case, though, is **information-driven fair repricing** (delivery numbers are partly pre-whispered; a guidance raise is genuine positive information, not sentiment overshoot).
- (b) Supporting public info: Q2 deliveries above consensus; FY delivery forecast raised; heavy conviction volume (77.8M sh, ~3.5× normal); decisively reclaimed the 50-day (~$15.60) and 200-day (~$15.80) at $18.63.
- (c) Convergence indicators to watch: post-event **sell-side PT / delivery-estimate revisions** (aggressive multi-firm raises → SP1 information-driven NO-GO; muted/mixed → an under-reaction anchor survives); whether +8.44% **holds above the pre-event ~$17.18** or fades; the **Q2 earnings print (~early Aug, within 60 days)** as an admissible in-window convergence marker (criterion 3(b) "next earnings release").
- (d) Days remaining: **9** (window ~7/16).
- (e) Tier: **top-5 (#1).** Freshest clean single-catalyst positive reaction, best-defined B setup, most runway. Under-reaction vs information-driven is the crux for D2's thesis pass.

**2. AVAV — AeroVironment** · +18.76% (6/30 FQ4 earnings blowout) **and** +10.70% (7/2 $500M counter-drone contract) · **window closes ~2026-07-14 (earnings) / ~7/16 (contract) → 7 trading days remaining**
- (a) Hypothesized mispricing direction/magnitude: **positive reactions; LONG under-reaction is the only B-takeable side — but a +37% two-session run (139→190.89) makes an under-reaction case hard.** Base case is **information-driven re-rating** (a record FQ4 with backlog +65% to $1.2B, plus a hard $500M contract, is genuine fundamental information, likely met by SP1 sell-side bull-ratification), and a multi-year defense-backlog ramp is arguably **Strategy-A territory (B-vs-A foreclosure)**. A **securities class-action overhang** (SCAR program cancellation + $151M impairment; class period 6/25/25–3/10/26; 7/27 lead-plaintiff deadline) is a structural caveat cutting against a clean LONG.
- (b) Supporting public info: FQ4 record revenue $642M (+31% organic); funded backlog $1.2B (from $726.6M); $500M U.S. Department of War counter-UAS Army award (7/1 AH); Seeking Alpha "best drone stock got cheaper" bull framing. Offsetting: SCAR cancellation / $151M impairment / active securities-fraud class action.
- (c) Convergence indicators to watch: post-earnings/contract **PT-raise breadth & magnitude** (mega/multi-firm raises → canonical SP1 NO-GO); whether the +37% **holds/extends or fades** toward the pre-event ~$139; **next earnings (FQ1 ~early Sept) likely falls OUTSIDE the 60-day window** → criterion 3 weak unless a numerical price-level convergence target is defensibly set at entry; litigation-headline risk.
- (d) Days remaining: **7** (binding earnings window ~7/14; the 7/2 contract trigger extends effective entry to ~7/16).
- (e) Tier: **top-5 (#2).** Biggest fresh reaction of the week; warrants a documented thesis pass to adjudicate under-reaction vs SP1 / B-vs-A / litigation-overhang. Likely NO-GO on current read, but the magnitude and freshness earn a full pass.

*(Only two un-adjudicated in-window candidates exist this week; the top-5 tier is not padded. No "rest tier.")*

### Recently adjudicated — prior B NO-GO within the entry window; NOT re-queued (no new evidence)
Per "NO-GO records are context, not barriers": these remain re-screenable, but each was declined on the *same event now in window*, days ago, with a documented decisive flaw. Re-queue **only on new evidence** (the specific trigger noted). No such evidence exists as of this screen.
- **ON — ON Semiconductor** (−23.66% 6/26; window to ~7/10, ~4 days) — B NO-GO **2026-06-27**, *SP4e [overlay: PatternN]*: acquirer all-stock-dilution structural overhang + sell-side downgrade ratification + sector-beta contamination; information-driven, not a sentiment overshoot. **Re-screen trigger:** a deal-terms change/withdrawal, a sell-side re-rating reversing the downgrade ratification, or ON strategic clarification before window close.
- **MU — Micron** (+15.74% 6/25; window to ~7/9, ~3 days) — B NO-GO **2026-06-28**, *SP1 [overlay: SP3]*: record AI-memory beat met by sell-side bull-ratification (all PTs above spot) + B-vs-A foreclosure (multi-quarter HBM ramp = A territory). **Re-screen trigger:** none expected pre-window-close. (Also freshly re-pressured by the 7/2 Meta-capex sentiment shock — a bearish, not bullish, new datapoint.)
- **AAPL — Apple** (−6.12% 6/25; window to ~7/9, ~3 days) — B NO-GO **2026-06-25**, *SP4c [overlay: PatternN]*: tariff/price-hike structural overhang; move sector-beta-contaminated. **Re-screen trigger:** a discrete Apple-specific reversal (e.g., demand-data refutation of the price-hike concern) before window close.
- **GNRC — Generac** (+5.87% 6/22; window to ~7/6, ~1 day ≈ closing) — B NO-GO **2026-06-28**, *SP1 [overlay: SP4]*: the catalyst pop **round-tripped entirely** (a further −6.5% on 7/2 to $252.66; −14.4% on the week) — PINS-style "move-faded-to-baseline," no residual mispricing to converge, sector-beta-contaminated. **Window effectively closes 7/6; not actionable.**
- **ACN — Accenture** (−17.97% 6/18) — B NO-GO **2026-06-18**, *PatternN*: information-driven negative reaction (AI-disruption-to-IT-services demand + bookings cut). **Window EXPIRED** (last valid entry 7/2).
- **KMX — CarMax** (+13.14% 6/18) — B NO-GO **2026-06-28**, *SP1 [overlay: SP4c]*: stock-above-cluster full-saturation + used-car-cyclical overhang. **Window EXPIRED** (last valid entry 7/2).

---

### Self-check
- Universe screened to mkt cap ≥ $2B, ADV ≥ $10M, ≥5% close-to-close on a discrete-public-event day in the prior 10 trading days (6/18–7/2); macro/sector-beta-only days (the 7/2 Meta-AI-capex semi-cap selloff) excluded per criterion 1. ✔
- Names with an open Strategy A position excluded — none exist this week (A = DO-NOT-ACTIVATE). ✔
- Open B holding (MDT) not surfaced as a new entry. ✔
- Prior `events.decision_log` NO-GOs surfaced as context (not barriers); same-event recent NO-GOs (ON/MU/AAPL/GNRC/ACN/KMX) not re-queued absent new evidence. ✔
- Close-to-close magnitudes/dates and ADV$ verified via the IBKR connector (authoritative); NKE (<5%) and CLVT (<$2B) correctly excluded on the mechanical gates. ✔
- PART 2 ranked with mispricing direction/magnitude, supporting info, convergence indicators, days-remaining, and priority tier per candidate, ordered for W4 → `PENDING_ANALYSIS` (RIVN #1 / AVAV #2; AVAV binding window ~7/14). ✔
