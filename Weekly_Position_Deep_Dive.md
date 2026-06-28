2026-W26

# W3 — Open-Position Deep-Dive (Strategies A, B, C, E)

**Run date:** 2026-06-28 (Sun, non-trading; last trading day 2026-06-26, next 2026-06-29; America/Denver via `state.trading_day_today`).
**Scope:** Strategies A, B, C, E only (D excluded — D gets the monthly M3 deep-dive). Open book in scope = **4 Strategy B positions** (AZO, HCA, MDT, ZBRA). **No open A, C, or E positions** (A router DO-NOT-ACTIVATE; C HYBRID-ACTIVATE but no open C; E ACTIVATE-but-execution-feasibility-deferred at current book size — no open E). So this week's deep-dive is entirely Strategy B.
**Prices:** 6/26 closes via IBKR connector `get_price_history`/`get_account_positions`. Web/peer/analyst research via Tavily/web for the prior week (~6/20–6/27, material since 6/15).

## IMMEDIATE-ACTION

**None — no NEW material thesis-invalidation this week.** One position (HCA) is on a mechanical 60-day time-stop whose exit was already staged by the 2026-06-27 EXIT routine (SELL, instruction_id 100, order day 2026-06-29) — that is in-flight, not a new invalidation. W4 action item there is **confirm-only** (do not double-stage). Per-position recommendations below.

---

## Summary table

| Pos (B) | Status | 6/26 close | Cost basis/sh | Conv. target | Δ to target | Time-exit | ~Trading days left | Unrealized | Recommendation |
|---|---|---|---|---|---|---|---|---|---|
| **AZO** | OPEN | $3,128.70 | ~$3,139.6 (avg) | $3,200 | **+2.3%** | 2026-07-24 | ~19 | −$0.13 (~flat) | **HOLD** |
| **HCA** | EXIT-PENDING | $391.68 | ~$437.80 | $442.85 (never hit) | +13.1% | **2026-06-27 (elapsed)** | — | −$2.96 (−10.5%) | **CLOSE — 60-day time-stop (already staged 6/29; W4 confirm-only)** |
| **MDT** | OPEN | $80.98 | ~$78.25 | $90.00 | +11.1% | 2026-07-31 | ~24 | +$0.96 (+2.5%) | **HOLD (degraded-catalyst flag)** |
| **ZBRA** | OPEN | $251.53 | ~$249.52 | $264.00 | +5.0% | **2026-07-13** | ~10 | −$0.28 (~flat) | **HOLD** |

---

## AZO — AutoZone (NYSE) — Strategy B LONG — HOLD

Entry 2026-05-27 (GO 2026-05-27, MEDIUM-LOW ~45–50%). Event: Q3 FY26 print 2026-05-26 BMO, −11.5% C/C to a 52-wk low. Target **$3,200** (immutable, 25% gap-fill). Time-exit **2026-07-24**.

1. **Current thesis status — HOLDS.** The thesis (oversized sentiment reaction to a small, geographically-contained Mexico/Brazil revenue miss, ignoring the EPS beat + accelerating domestic comps) is intact. AZO recovered from a 6/22 trough (~$2,949, near the 52-wk low $2,928) to close 6/26 at $3,128.70 — back above cost basis and within +2.3% of the $3,200 target; partial mean-reversion is underway. Prevailing sell-side/media narrative still frames AZO/ORLY as recession-resistant compounders on the aging US fleet (~12.8 yrs) — no drift toward a "domestic deterioration" story.
2. **Competitive landscape — supportive.** Sector-wide bid in the prior week: AAP +5.0% (6/26, turnaround story), ORLY +3.0%, GPC +2.7% — a peer-group move, not AZO-idiosyncratic, which reinforces the "AZO-specific overreaction" read. No peer earnings/guidance cut and no peer datapoint signaling domestic-demand weakness (Zacks Auto-Parts Outlook 6/25: "tough environment" on rates/energy but aging-fleet tailwind intact; ORLY/AAP Zacks Rank #3).
3. **Fundamental developments.** Only material AZO filing in-window: **8-K 6/16 — Board authorized an additional $1.5B buyback (total program $42.2B)** — management-confidence signal, no operational guidance. Analyst flow thin: Weiss cosmetic C+→C (6/23); substantive recent notes remain bullish (TD Cowen Buy $3,700 6/4; Argus Buy $4,325 6/11; consensus Moderate/Strong Buy, ~$3,970–4,040 median, 0 Sell). No downgrade challenges the thesis.
4. **Sector & macro.** Aftermarket demand mechanics counter-cyclical and intact (AAPEX: 61% expect 2026 demand growth). Tariff overhang persists as a *margin/cost* risk (S&P Global: ~5–6% potential aftermarket revenue hit; ~47% of imported parts from Mexico) but **no new tariff escalation in-window and not yet a demand hit**. Hormuz reopening eased energy/logistics costs.
5. **Invalidation signals — none tripped, none near.** (i) No 8-K cutting FY26 domestic SSS; latest reported domestic SSS comfortably above the 3% floor. (ii) No structural ICE/parts-demand disruption. (iii) No international-to-domestic contagion — weakness remains Mexico-macro-specific.
   - **Data-hygiene flag (carry to W4 / W5):** the entry memo cited "+5.5% domestic SSS"; the actual Q3 FY26 press release showed **domestic SSS ≈ +4.1%** (total company +3.9%) — the +5.5% appears to conflate a prior quarter. Immaterial to disposition (+4.1% ≫ the 3% invalidation floor) but the invalidation-criterion (i) anchor should reference +4.1%.
6. **Time-to-resolution.** ~19 trading days to the 2026-07-24 time-stop; only +2.3% to target. Convergence within the window is plausible given the recovery momentum. Not approaching the time-stop yet.

**Recommendation: HOLD.** No invalidation; runs to $3,200 target or the 2026-07-24 60-day time-stop, whichever first.

---

## HCA — HCA Healthcare (NYSE) — Strategy B LONG — CLOSE (60-day time-stop; already staged)

Entry 2026-04-28 (GO 2026-04-27, MEDIUM-LOW). Event: Q1 2026 print 2026-04-24, −8.77% C/C. Target **$442.85** (never reached). Time-exit **2026-06-27 — ELAPSED**.

1. **Current thesis status — failed; mechanically exiting.** Convergence target never reached; the 60-day stale window has elapsed. Per Strategy B exit rules ("timeline expiry at 60 days — thesis is stale; market had ample absorption time and did not converge"), the **time-stop fires regardless of P&L**. This is the time-stop, NOT an invalidation-criterion breach. The 2026-06-27 EXIT routine already staged SELL ~0.0642 sh marketable LIMIT ~$385 DAY (instruction_id 100), order day 2026-06-29, with the `[Claude] Confirm order` event scheduled 07:00 MT 6/29. 6/26 close $391.68 (~−10.5% vs entry; HCA actually firmed +3.9% on the week but remains ~12% below target).
2. **Competitive / sector context.** No prior-week peer print or shock. The ACA enhanced-subsidy lapse (effective 2026; HCA-cited ~$1B exposure) remains the structural overhang. CYH deleveraging coverage (6/23) immaterial to HCA. Nothing "cleans up" or undercuts — nor newly invalidates — the prior framing.
3. **Reconsider the staged exit? No.** No positive catalyst toward $442.85; analyst tone soft (Bernstein PT $413/Market-Perform 6/4; Weiss Hold 6/9; TD Cowen Buy $431 6/22). Only nearby company filing is a routine **8-K (event 6/15, filed 6/18) — CCO Dr. Cuffe to step down Aug 31, 2026** (governance, not financial; FY26 guidance unchanged from the Q1 reaffirmation, so invalidation criterion (i) was never triggered). Nothing changes the disposition.
4–6. (Sector/macro, invalidation, time-to-resolution all moot — the time-stop has fired.)

**Recommendation: CLOSE — 60-day time-stop (Strategy B timeline-expiry exit rule).** Exit is **already staged** (instruction_id 100, 6/29). **W4 action = confirm-only** (verify the staged order + confirm-order event exist; do NOT double-stage). Fill reconciles via D2 Step 0.

---

## MDT — Medtronic plc (NYSE) — Strategy B LONG — HOLD (degraded-catalyst flag)

Entry filled 2026-06-17 (GO 2026-06-03, 60% / MEDIUM-LOW). Event: Q4 FY2026 print 2026-06-03, +5.70% C/C. Target **$90.00** (immutable, bear-camp floor UBS $90 / Piper $91 / Truist $95). Time-exit **2026-07-31**. Ex-div $0.72 on 2026-06-26.

1. **Current thesis status — broad valuation thesis intact, but the SPECIFIC entry catalyst has FAILED/inverted.** The macro mispricing (MDT ~28% below the ~$107 consensus mean PT) still stands and price is stable/up (+2.5% unrealized, $80.98). BUT the entry's named convergence mechanism — *post-print upward PT revisions from the $90–95 bear camp* — did not appear; it inverted. Post-6/3 actions (all ~6/4, MarketBeat/Benzinga) were overwhelmingly DOWNWARD: UBS $90→$85, Truist $95→$86, Baird $93→$85, JPMorgan $100→$86, BofA $110→$95, Bernstein $112→$97, Wells $114→$102, Needham $120→$101; Goldman held Neutral $83. The ONLY positive action was **BTIG upgrade to Buy, PT $90 (6/4)** — a single print that merely matches the target. **No new MDT-specific PT/rating action found in the prior week (6/20–6/27).** The entry explicitly priced this exact risk ("if post-print notes don't show upward PT revisions, the catalyst weakens — priced into 60% conviction").
2. **Competitive landscape.** Cardiac-ablation (CAS/PFA) competitive pressure persists, not eases: BSX FARAPULSE remains PFA leader; Abbott Volt PFA has FDA approval; BSX won a Farapoint clearance — a structural headwind to Medtronic's Affera/Sphere-9 CAS growth engine. No prior-week BSX PFA headline located. (Peer marks: SYK ~$332, ABT ~$93.8, JNJ ~$254.7 (+ on 6/26 broad-healthcare strength); an FMP BSX $44.23 print looked like a data anomaly — not load-bearing.)
3. **Fundamental developments.** No new MDT 8-K / guidance / M&A in the prior week. Pending items unchanged: SPR Therapeutics ($650M) closing ~H1 FY27; Hugo RAS 510(k) filings; IRCAD NA training partnership (supportive, not a catalyst). No FDA decision on Hugo expansion or Sphere-9 in-window. Insider selling clustered 6/3–6/7 (~$83) — mild negative.
4. **Sector & macro.** Live overhang = **Section 232 medical-device tariff investigation** (AdvaMed pushing exemptions, 6/16; large medtechs face ~$200–450M annual exposure) — no duties yet. Sector fundamentals stable but "fears of the unknown." No reimbursement shock in-window.
5. **Invalidation signals.** **No HARD invalidation:** no FY27 guide walk-back, no demand-weakness print — fundamentals intact, and Strategy B carries no price stop for longs. The degradation is catalyst-mechanism failure (the $90–95 firms cut to $85–86, i.e., below the convergence target), which lowers the probability of reaching $90 by 7/31 but does not breach a Strategy.md exit trigger. This is a *thesis-quality* downgrade, not an exit condition.
6. **Time-to-resolution.** ~24 trading days to the 2026-07-31 time-stop; +11.1% to target. With the sell-side tailwind absent (and the bear camp anchored at $85–86), reaching $90 now requires multiple re-rating on its own; **base case is resolution at the 7/31 time-stop rather than at target.** Not approaching the stop yet.

**Recommendation: HOLD (flagged).** No Strategy.md exit condition is met (no convergence, no hard invalidation, no timeline expiry) and the entry pre-priced the catalyst risk into MEDIUM-LOW conviction; the broad valuation gap + small unrealized gain do not justify a discretionary early exit against the no-price-stop B design. **Flag for W4/W5 calibration:** the named convergence catalyst (upward PT-revision cascade) has failed/inverted — track whether MDT resolves at the time-stop, and feed the catalyst-failure into conviction calibration. No further-research deferral enqueued (the resolving information — downward PTs — is already in; there is no future-dated data gap to wait on).

---

## ZBRA — Zebra Technologies (NASDAQ) — Strategy B LONG — HOLD

Entry 2026-05-14 (GO 2026-05-13, MEDIUM-HIGH). Event: Q1 2026 print 2026-05-12 BMO, clean beat-and-raise, +11.4% C/C (~+18% intraday) — an **under-reaction** B-long (expect further convergence UP). Target **$264.00** (immutable, 25% gap-fill). Time-exit **2026-07-13** (the nearest time-stop in the book). 6/9 mid-window pulse-check = HOLD.

1. **Current thesis status — HOLDS, modestly reinforced.** The 5/12 beat-and-raise (EPS $4.75 vs ~$4.21–4.25; rev +14.3% / +4.3% organic; FY26 raised to EPS $18.30–18.70, sales +10–14%) remains the live story with no offsetting prior-week event. ZBRA closed 6/26 at **$251.53 (+3.3% on the day)**, ~flat to cost basis and ~5% below the $264 target. Slight positive drift (AAII: 1 upgrade / 0 downgrades trailing month as of 6/26).
2. **Competitive landscape — thesis-neutral-to-supportive.** Structural AIDC consolidation: **Honeywell agreed to sell its Productivity Solutions & Services (barcode/mobile-computing) unit to Brady for $1.4B** (~$1.1B 2025 rev, ~8× EBITDA; closing 2H26) — Honeywell exiting direct competition with ZBRA. No adverse prior-week moves from Cognex, Datalogic, or SATO. Sector AIDC commentary constructive.
3. **Fundamental developments.** No 8-K resetting the FY26 framework. Only housekeeping filings since 5/13 (S-8 5/29; LTIP 8-K 5/26). **Prior-week analyst action: Barclays raised PT $345→$346, maintained Overweight (6/22)** — small but directionally confirming. Consensus Moderate/Strong Buy, mean PT ~$330–335, no recent downgrades. Next earnings **8/4/2026 — AFTER the 7/13 time-exit** (no scheduled company catalyst inside the window).
4. **Sector & macro — easing, supportive.** Tariff backdrop easing: IEEPA tariffs struck down (Supreme Court 2/20/2026); avg effective US tariff rate ~7.0% (Wharton PWBM 6/16). A Section 232 "Robotics & Industrial Machinery" probe is *pending* (no duties) — watch-item, not a trip. US manufacturing in its fifth straight month of expansion (May) — constructive for enterprise-capex / warehouse-automation demand.
5. **Invalidation signals — none tripped, none nearer.** (i) No guidance reset / pre-announcement — FY26 EPS floor ~$18.30 and ~22%+ EBITDA-margin guide intact. (ii) No demand-break / customer cancellation / adverse Elo or Connected-Frontline update (Elo news is positive product launches). (iii) Tariffs easing; **no ZBRA-specific disclosed tariff impact** (general macro noise does NOT trip this criterion). (iv) Sub-pattern-1 cluster NOT escalating — only one +PT move (Barclays +$1, 6/22), far short of the 3+ / +10% threshold.
6. **Time-to-resolution.** ~10 trading days to the 2026-07-13 time-stop; +5.0% to target. Convergence to $264 is **realistic but not assured** — it needs continuation of the existing re-rating with no scheduled catalyst before the time-exit (8/4 print is past it). Nearest time-stop in the book; if not converged by 7/13 the time-stop fires.

**Recommendation: HOLD.** No invalidation; runs to $264 target or the 2026-07-13 60-day time-stop, whichever first. (Watch-item only: the 7/13 time-stop is ~10 trading days out — D1's daily mechanical sweep covers the convergence/time-exit triggers; no W4 action needed now.)

---

## W4 hand-off notes

- **Exits to confirm (section A):** **HCA** — close on 60-day time-stop; **already staged** (instruction_id 100, order day 2026-06-29, confirm-order event exists). W4 = confirm-only second-look (time_exit_date 2026-06-27 elapsed ✓); do NOT re-stage.
- **No "further research" deferrals (section B).** MDT's catalyst degradation has no future-dated information gap (the resolving data — downward post-print PTs — is already in), so no `PENDING_ANALYSIS` research-deferral is warranted; it is a HOLD-with-flag, not a further-research call.
- **Holds:** AZO, MDT, ZBRA — no W4 exit/deferral action. Mechanical convergence/time-exit triggers for all three are covered by D1's daily connector sweep.
- **Calibration flag for W5:** MDT named-catalyst (upward PT-revision cascade) failed/inverted; AZO invalidation-criterion (i) anchor should reference the actual Q3 domestic SSS +4.1% (not the memo's +5.5%).
