# Pending Analysis — queue

Autonomous queue for Claude-only analysis steps (thesis construction, scheduled re-screens, research-deferral checkpoints, foundation-change assessments, constraint-relaxation reviews, monitoring checks). These require NO human action, so they are NOT placed on the human's calendar. The daily D2 routine (Step 1) drains entries whose `due_date` has arrived and performs the analysis in-session — each as an isolated sub-task (subagent) for fresh context where available. Schema + drain rules: Claude_Task_Plan.md → "In-session analysis and the Pending_Analysis.md queue". Entries are appended in creation order, separated by `---`; once an entry reaches a terminal `status` (`complete`/`superseded`) it is swept to `Archived_Analysis.md` by D3 on its next daily run and removed from this live file (full clear — no pointer; see Operating_Protocols.md §12 / Claude_Task_Plan.md "Queue lifecycle and daily archive policy"), so this file holds only actionable entries.

Mirrors `Pending_Adversarial_Reviews.md`. Established 2026-06-01 (IBKR-connector workflow migration — analysis events moved off the human calendar; see Decision_Log 2026-06-01 "Analysis steps moved off the human calendar to in-session execution + Pending_Analysis.md queue"). The seven entries below were migrated 1:1 from the live `[Claude]` analysis calendar events that previously required a human paste.

---

- id: rescreen-BA-D-20260604
  analysis_type: re-screen
  strategy: D
  ticker_or_pair: BA
  due_date: 2026-06-04
  context: |
    TERMINAL re-screen of the Strategy D BA NO-GO (orig 2026-04-26 5-name batch). Deferrals do not chain (Operating_Protocols §9) — resolve to GO / NO-GO / conservative-default here; do NOT re-defer.
    STEP-0 D-DIVERGENCE-REVIEW GATE (DISPOSITIVE): read the div-D-202605-1 verdict from its durable sources — `Adversarial_Review_div-D-202605-1_orchestrator.md` (orchestrator output) + `Regime_State.md` (D activation row). (The div-D-202605-1 queue entry completed 2026-06-03 and was swept to `Archived_Adversarial_Reviews.md` per the daily queue-archive policy — read it there only if the output file is unavailable.) Orchestrator verdict ACTIVATE → proceed to re-screen; DO-NOT-ACTIVATE → terminal NO-GO (BA blocked; original NO-GO preserved); verdict not resolvable → conservative-default NO-entry (no re-defer).
    RE-SCREEN LOGIC (only if gate clears): trigger = BA ≤ $210 (~10% from $234) with trailing-30d rally rolled off OR a 737 production-rate slip. Pull BA price + trailing-30d via connector. If trigger met → fresh Strategy D thesis (not constrained by prior NO-GO). Else log "NO-GO still active; trigger not met". See Decision_Log 2026-06-01 BA deferral + 2026-04-26 D batch (BA subsection).
  conservative_default: NO entry — original NO-GO preserved; terminal (do not re-defer).
  status: complete
  outcome: NO-GO still active — gate CLEARED (div-D-202605-1 = ACTIVATE) but re-screen trigger NOT met (BA $217.21 > $210; 737 production ramping, not slipping). Original NO-GO preserved, terminal. → Decision_Log 2026-06-04 BA terminal re-screen.

---

- id: thesis-FOMC-C-20260608
  analysis_type: thesis-construction
  strategy: C
  ticker_or_pair: FOMC June 2026 (SPY/SPX or TLT defined-risk options)
  due_date: 2026-06-08
  context: |
    Strategy C defined-risk options thesis around the FOMC June meeting (2026-06-16/17, with SEP / dot-plot). Pre-catalyst window (8–9 days out). Router: HYBRID ACTIVATE — FOMC ONLY (Regime_State.md); earnings/PDUFA/vol-directional are DNA.
    Directional skew is OPEN/CONTESTED (W20: 30Y yield > 5.13%, CME FedWatch ~50% odds of a HIKE by year-end) — do NOT pre-commit. Resolve skew at run time across (a) bullish-rates / TLT-call, (b) bearish-rates / TLT-put, (c) range-bound / SPX iron condor. A DIRECTIONAL thesis is REQUIRED (pure long-vol straddle is router-blocked). Dual-path verification (closed-form + Monte Carlo) via c_options_math.py REQUIRED before staging; max-loss ≤ 2% NAV.
    NOTE — options are NOT connector-craftable (Equity/ETF only). If GO, emit a manual-entry text order block in the [Claude] Confirm order event, explicitly labeled "manual entry — connector cannot craft options." Read latest Weekly_Catalyst_Calendar.md C #1, Daily.md tape, Strategy.md C criteria 1–5, Experiment_Parameters.md (2% cap), c_options_math.py. Deconflict vs open A/C positions.
  conservative_default: do not stage if dual-path verification fails or sizing exceeds the 2% cap.
  status: pending
  outcome: (pending)

---

- id: review-ZBRA-B-20260609
  analysis_type: research-deferral-checkpoint
  strategy: B
  ticker_or_pair: ZBRA
  due_date: 2026-06-09
  context: |
    Strategy B ZBRA mid-window pulse-check (entry 2026-05-14 @ $249.52; convergence target $264.00; time-based exit 2026-07-13; midpoint ~6/9). Review: (1) live mark vs $264 (connector get_price_snapshot); (2) invalidation criterion (iv) sub-pattern-1 cluster-escalation check (3+ additional +10%+ PT raises post-staging → thesis-quality-shift trigger); (3) invalidation criteria (i)–(iii) status; (4) tariff-regime + customer-demand monitoring. Source thesis: Decision_Log 2026-05-13 ZBRA GO. (Mechanical convergence + time-exit are also caught by D1's daily exit-trigger sweep; this entry is the deeper mid-window thesis review.)
  conservative_default: HOLD (no action) if nothing is invalidated; position continues to its time-based exit.
  status: pending
  outcome: (pending)

---

- id: rescreen-LLY-D-20260612
  analysis_type: re-screen
  strategy: D
  ticker_or_pair: LLY
  due_date: 2026-06-12
  context: |
    Strategy D mechanical re-screen of the LLY entry-timing-failure NO-GO (2026-04-30 BMO Q1 print). ~30 trading days have elapsed since Apr 30.
    STEP-0 D-DIVERGENCE-REVIEW GATE (DISPOSITIVE; same div-D-202605-1 as BA): orchestrator verdict ACTIVATE → proceed to pre-screen; DO-NOT-ACTIVATE → terminal NO-GO (DNA supersedes; entry-timing NO-GO preserved); not resolvable → defer per §9 conservative-default NO-entry (no chaining). Read the div-D-202605-1 verdict at start from `Adversarial_Review_div-D-202605-1_orchestrator.md` + `Regime_State.md` (D activation row) — the div-D queue entry was swept to `Archived_Adversarial_Reviews.md` per the daily queue-archive policy.
    PRE-SCREEN (only if gate clears): check trailing-30d return normalized from the post-print +~10% / pre-print +~15-20% readings that produced the entry-timing fail; pull LLY price + trailing-30d via connector; verify Foundayo/orforglipron Q1 net rev + FY26 guide reaffirmation. If normalized AND no other criterion degraded → full Strategy D thesis re-construction (not constrained by prior NO-GO). Else → NO-GO STILL ACTIVE; queue for next quarterly cycle. Read Strategy.md D (criterion 6), Decision_Log 2026-04-30 LLY + GOOGL NO-GO precedent, Portfolio_Ledger D book.
  conservative_default: NO-GO still active (no entry) if the trigger is not met or the gate is not clear.
  status: pending
  outcome: (pending)

---

- id: thesis-AVGO-B-20260604
  analysis_type: thesis-construction
  strategy: B
  ticker_or_pair: AVGO (Broadcom Inc)
  due_date: 2026-06-04
  context: |
    Strategy B thesis for AVGO (Broadcom Inc). Q2 FY26 earnings AMC Wed 2026-06-03; entry window closes ~2026-06-17.
    STEP-0 CTC VERIFICATION (run first): Day-0 = Thu 6/4. Pull Day-0 close (6/4) and Day(-1) close (6/3 pre-earnings ≈ $479.23 per Daily.md) via connector get_price_history (search_contracts for AVGO contract_id if needed). CTC = (Day-0 close − Day(-1) close) / Day(-1) close. If |CTC| < 5% → NO-GO at criterion-1 magnitude gate. If ≥ 5% → full criteria 1–5 per Strategy.md rev 35 (no sector/count caps).
    Context from Daily.md 2026-06-03: AVGO pre-earnings close ~$479.23; AI chip demand (custom ASIC, networking) is the key guidance focus. Apply B_Sub_Pattern_Taxonomy.md for sub-pattern routing (esp. sub-pattern 3 pre-print rally check and sub-pattern 1 post-print sell-side ratification).
    IF GO: connector craft-order flow (Operating_Protocols §11) — create_order_instruction + one [Claude] Confirm order calendar event (07:00 MT next trading day); no fill-capture event (D2 Step 0 reconciles).
  conservative_default: decline (no entry) if criterion-1 |CTC| < 5% or if entry window closes unresolved.
  status: complete
  outcome: NO-GO (criterion 4). CTC −12.59% (criterion-1 PASS) but information-driven re-rating not overshoot — Sub-Pattern 3 pre-print rally (~+17% into print) + reiterated-not-raised target + Google chip-diversification. → Decision_Log 2026-06-04 AVGO NO-GO.

---

- id: thesis-CRWD-B-20260604
  analysis_type: thesis-construction
  strategy: B
  ticker_or_pair: CRWD (CrowdStrike Holdings)
  due_date: 2026-06-04
  context: |
    Strategy B thesis for CRWD (CrowdStrike Holdings). Q1 FY27 earnings AMC Wed 2026-06-03; 4-for-1 stock split effective; entry window closes ~2026-06-17.
    STEP-0 A-ROUTER GATE (DISPOSITIVE; check first): CRWD is A-queued (Daily.md 2026-06-03 annotation). If A router = ACTIVATE → INADMISSIBLE per Strategy.md criterion 5 (terminal NO-GO; CRWD proceeds as A-queue name only). If A = DO-NOT-ACTIVATE → gate clears (DDOG/PANW/OKTA criterion-5 precedent) → proceed to CTC verification.
    STEP-1 CTC VERIFICATION: Day-0 = Thu 6/4. Pull Day-0 close (6/4) and Day(-1) close (6/3 pre-earnings ≈ $768.95 pre-split per Daily.md) via connector (note: use split-adjusted prices consistently). If |CTC| < 5% → NO-GO at criterion-1 gate. Context: "sell-the-news" risk flagged in Daily.md given large pre-print run; sub-pattern 3 check is critical.
    Full criteria 1–5 per Strategy.md rev 35. Apply B_Sub_Pattern_Taxonomy.md. Operating_Protocols §2 (commissions) + §8 (conviction).
    IF GO: connector craft-order flow (§11) — create_order_instruction + one [Claude] Confirm order event (07:00 MT next trading day); no fill-capture event (D2 Step 0 reconciles).
  conservative_default: NO entry if A-router gate = ACTIVATE, criterion-1 |CTC| < 5%, or entry window closes unresolved.
  status: complete
  outcome: NO-GO (criterion 1 mechanical). A-router gate CLEARED (A=DNA). Event-day CTC −3.81% < 5% (queue context's $768.95 was the 6/2 close not 6/3; true 6/3 pre-print close $747.61 → 6/4 $719.09). → Decision_Log 2026-06-04 CRWD NO-GO.

---

- id: thesis-ANF-B-20260604
  analysis_type: thesis-construction
  strategy: B
  ticker_or_pair: ANF (Abercrombie & Fitch Co)
  due_date: 2026-06-04
  context: |
    Strategy B thesis for ANF (Abercrombie & Fitch). Day-0 print 2026-05-29; CTC ≈ −6.04% (criterion-1 clears). Entry window closes ~2026-06-12 (10 trading days from 5/29). Deferred from D2 2026-06-01 (prior session calendar event); Pending_Analysis.md architecture now governs (migrated 2026-06-01).
    Deferrals do not chain (Operating_Protocols §9) — resolve to GO / NO-GO / conservative-default here; do NOT re-defer.
    DIRECTION: NEGATIVE (−6.04% Day-0 = SHORT eligible). Full criteria 1–5 evaluation per Strategy.md rev 35. Apply B_Sub_Pattern_Taxonomy.md. Pull current ANF price via connector get_price_snapshot for any convergence target anchoring. Pull Q1 FY26 print context via Tavily search for criterion 2–4 evaluation (sub-pattern 1 sell-side PT raise cluster check; sub-pattern 3/6 pre-print rally / valuation-reset check). Reference Decision_Log 2026-06-01 ANF deferral context.
    IF GO: connector craft-order flow (§11) — create_order_instruction + one [Claude] Confirm order event (07:00 MT next trading day); no fill-capture event (D2 Step 0 reconciles).
  conservative_default: NO entry if entry window has closed (~6/12) or criterion-1 cannot be verified via connector.
  status: complete
  outcome: NO-GO (criterion 1 event-day artifact + criterion 4). Queue premise wrong: true Day-0 = Wed 5/27 = +8.88% POSITIVE earnings rally; the −6.04% was the 5/28→5/29 (T+2) give-back. Even on merits, information-driven fade (Q2 guide ~25% below cons, EMEA, tariffs) with sell-side ratifying lower. → Decision_Log 2026-06-04 ANF NO-GO.

---

- id: thesis-CPRI-B-20260604
  analysis_type: thesis-construction
  strategy: B
  ticker_or_pair: CPRI (Capri Holdings)
  due_date: 2026-06-04
  context: |
    Strategy B thesis for CPRI (Capri Holdings). Day-0 print 2026-05-29; CTC ≈ −7.35% (criterion-1 clears). Entry window closes ~2026-06-12 (10 trading days from 5/29). Deferred from D2 2026-06-01 (prior session calendar event); Pending_Analysis.md architecture now governs (migrated 2026-06-01).
    Deferrals do not chain (Operating_Protocols §9) — resolve to GO / NO-GO / conservative-default here; do NOT re-defer.
    DIRECTION: NEGATIVE (−7.35% Day-0 = SHORT eligible). Full criteria 1–5 evaluation per Strategy.md rev 35. Apply B_Sub_Pattern_Taxonomy.md. Pull current CPRI price via connector. Pull Q4 FY26 / Q1 FY27 print context via Tavily for criterion 2–4 (Capri Holdings = Michael Kors, Versace, Jimmy Choo; check sub-pattern 1 aggressive sell-side ratification, sub-pattern 6 valuation-reset, any strategic/M&A catalyst that could affect short thesis). Reference Decision_Log 2026-06-01 CPRI deferral context.
    IF GO: connector craft-order flow (§11) — create_order_instruction + one [Claude] Confirm order event (07:00 MT next trading day); no fill-capture event (D2 Step 0 reconciles).
  conservative_default: NO entry if entry window has closed (~6/12) or criterion-1 cannot be verified via connector.
  status: complete
  outcome: NO-GO (criterion 4; date/direction correction). True Day-0 = Thu 5/28 = +8.05% POSITIVE (Q4/FY26 reported after close Wed 5/27); the −7.35% was the 5/28→5/29 Day+1 fade. Information-driven re-rating (EPS +100% surprise, deleveraging post-Versace); SP6+SP4. → Decision_Log 2026-06-04 CPRI NO-GO.

---

- id: olli-thesis-B-20260605
  analysis_type: thesis-construction
  strategy: B
  ticker_or_pair: OLLI (Ollie's Bargain Outlet Holdings)
  due_date: 2026-06-05
  context: |
    Strategy B thesis for OLLI. Surfaced 2026-06-04 D2 verify-and-route (Daily.md OLLI −6.6%). Data exists today; queued to next D2 as a late-surfaced verification candidate (window has ample runway). CTC −6.61% (6/3 close 79.74 → 6/4 close 74.47; connector contract_id 199975711, NASDAQ).
    DAY-0 AMBIGUOUS — resolve FIRST via get_price_history: Q1 FY26 earnings released 6/3 pre-market (adj EPS $0.91 BEAT, raised FY EPS guide; stock +7.4% on 6/3 = POSITIVE Day-0 reaction). The −6.6% on 6/4 is a Day+1 reversal driven by a Gordon Haskett downgrade (Buy→Accumulate) + PT cut + slightly trimmed FY revenue forecast — NOT the earnings Day-0. If the qualifying B event (earnings) produced a +7.4% positive Day-0 → positive-direction routing (SP8 / sell-side framework), likely NO-GO; the negative-direction beat-and-fade frame only applies if treating the analyst action as the event (weaker B basis). Entry window from 6/3 Day-0 closes ~6/17.
    Full criteria 1–5 per Strategy.md rev 35 + B_Sub_Pattern_Taxonomy.md (SP8 modest-beat-sentiment-move / negative-analyst-cut fingerprint flagged). Op_Protocols §2/§3/§8. Sizing on GO = 2% of B sub-portfolio NAV ~$1,887.60 → ~$37.75 (NOT account net-liq).
    IF GO: connector craft-order flow (§11) — create_order_instruction + one [Claude] Confirm order event (07:00 MT next trading day); no fill-capture event (D2 Step 0 reconciles).
  conservative_default: NO entry if Day-0 resolves to the positive 6/3 print with no negative-direction qualifying setup, if criterion-1 |CTC| < 5% on the qualifying event, or if the window has closed.
  status: pending
  outcome: (pending)
