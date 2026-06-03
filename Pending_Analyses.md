# Pending Analyses — queue

Autonomous queue for Claude-only analysis steps (thesis construction, scheduled re-screens, research-deferral checkpoints, foundation-change assessments, constraint-relaxation reviews, monitoring checks). These require NO human action, so they are NOT placed on the human's calendar. The daily D2 routine (Step 1) drains entries whose `due_date` has arrived and performs the analysis in-session — each as an isolated sub-task (subagent) for fresh context where available. Schema + drain rules: Claude_Task_Plan.md → "In-session analysis and the Pending_Analyses.md queue". Entries are appended in creation order, separated by `---`; processed entries are marked `status: complete` (or `superseded`) and retained for traceability.

Mirrors `Pending_Adversarial_Reviews.md`. Established 2026-06-01 (IBKR-connector workflow migration — analysis events moved off the human calendar; see Decision_Log 2026-06-01 "Analysis steps moved off the human calendar to in-session execution + Pending_Analyses.md queue"). The seven entries below were migrated 1:1 from the live `[Claude]` analysis calendar events that previously required a human paste.

---

- id: thesis-HPE-B-20260602
  analysis_type: thesis-construction
  strategy: B
  ticker_or_pair: HPE (contract_id 209411798, NYSE)
  due_date: 2026-06-02
  context: |
    Strategy B thesis for HPE (Hewlett Packard Enterprise). Q2 FY26 earnings AMC Mon 2026-06-01; after-hours +29–37% indicated; pre-report baseline close $47.00.
    STEP-0 CTC VERIFICATION (run first): Day-0 close-to-close = Tue 6/2 RTS close ÷ Mon 6/1 close $47.00 − 1. Pull the 6/2 close via connector get_price_snapshot / get_price_history (contract_id 209411798). If CTC < 5% → NO-GO at criterion-1 magnitude gate. If ≥ 5% → full criteria 1–5 per Strategy.md rev 35 (no sector/count caps).
    A-queue dual-listing: HPE is A-queued (Watchlist.md); A router DNA per M1b 2026-06-01 → criterion-5 PASS (DDOG precedent). Re-verify A-router state at run time (if flipped ACTIVATE, criterion-5 gate applies). Valuation-reset caveat ELEVATED to most-extreme tier (Watchlist.md 2026-06-01): the +29–37% may be a legitimate re-rating, not a temporary mispricing. Apply B_Sub_Pattern_Taxonomy.md; reference DELL/SNOW/MRVL post-print analogues; Operating_Protocols §2 (commissions) + §8 (conviction). Entry window through ~2026-06-15.
    IF GO: connector craft-order flow (Operating_Protocols §11) — create_order_instruction + one [Claude] Confirm order event; no fill-capture event (D2 Step 0 reconciles).
  conservative_default: decline (no entry) if the entry window closes unresolved.
  status: complete
  outcome: NO-GO — criterion-4 dual-framing (LONG foreclosed information-driven + B-vs-A; SHORT dismissed aggressive-sell-side-bull-ratification; Sub-Pattern 1 most-extreme PT-raise magnitude; 7 firms $65–$80 PT cluster vs $56.15 close). Decision_Log 2026-06-02 "Strategy B — HPE Q2 FY26 print B-thesis-construction — NO-GO."

---

- id: thesis-OKTA-B-20260602
  analysis_type: thesis-construction
  strategy: B
  ticker_or_pair: OKTA
  due_date: 2026-06-02
  context: |
    Strategy B thesis for OKTA (Okta). Day-0 print 2026-05-29 AMC; entry window closes ~2026-06-09.
    STEP-0 A-ROUTER GATE (DISPOSITIVE; check first): OKTA is A-queued (Watchlist.md). If A router = ACTIVATE → INADMISSIBLE per Strategy.md criterion 5 (terminal NO-GO; OKTA proceeds as an A-queue name). If A = DO-NOT-ACTIVATE (per M1b 2026-06-01) → gate clears (DDOG criterion-5 precedent) → run the full 5-criterion B thesis. If the M1 6/1 A-router outcome is not confirmable clear at run time → conservative-default NO entry (do NOT re-defer).
    Apply B_Sub_Pattern_Taxonomy.md; Strategy.md rev 35 (no caps; KL #12 metric (d) monitoring-only); live quotes/CTC via connector. See Decision_Log 2026-05-31 OKTA deferral.
    IF GO: connector craft-order flow (§11) — create_order_instruction + one Confirm-order event.
  conservative_default: NO entry if the A-router gate is not confirmable clear (deferrals do not chain).
  status: complete
  outcome: NO-GO — criterion-4 dual-framing (LONG foreclosed information-driven + B-vs-A; SHORT dismissed SP1 sell-side bull-ratification + stock-above-PT-cluster; A-router gate clears DNA; conviction ~76%) — 2026-06-02

---

- id: monitor-KL12-B-20260603
  analysis_type: re-screen
  strategy: B
  ticker_or_pair: n/a (B book)
  due_date: 2026-06-03
  context: |
    KL #12 (pre-mortem rev 7) pairwise-correlation monitoring for the B book. At run time read Portfolio_Ledger.md §[Strategy B] for the actual open B positions (expected 5-long: HCA, ZBRA, BRC, TJX, AZO — BURL CLOSED 2026-06-01; IBM/META closed earlier). Compute average pairwise correlation across the open names (use connector get_price_history return series). Threshold: average pairwise correlation > 0.5 → flag for position review per pre-mortem rev 7 KL #12 metric (d). Monitoring-only, NOT an entry gate (Operating_Protocols §10). Open-position fills for the lookback: HCA 4/28 @ $433.46; ZBRA 5/14 @ $249.52; BRC 5/22 @ $84.97; TJX 5/26 @ $158.50; AZO 5/27 @ ~$3,110.69.
  conservative_default: skip (no flag) if correlations cannot be computed.
  status: complete
  outcome: NO-FLAG — avg pairwise correlation 0.20 (below 0.50 threshold); 10 pairs computed over 5 trading days (2026-05-27 → 2026-06-02) — 2026-06-03

---

- id: rescreen-BA-D-20260604
  analysis_type: re-screen
  strategy: D
  ticker_or_pair: BA
  due_date: 2026-06-04
  context: |
    TERMINAL re-screen of the Strategy D BA NO-GO (orig 2026-04-26 5-name batch). Deferrals do not chain (Operating_Protocols §9) — resolve to GO / NO-GO / conservative-default here; do NOT re-defer.
    STEP-0 D-DIVERGENCE-REVIEW GATE (DISPOSITIVE): read Pending_Adversarial_Reviews.md (div-D-202605-1 status + orchestrator_output_path = Adversarial_Review_div-D-202605-1_orchestrator.md) + Regime_State.md (D activation). Orchestrator verdict ACTIVATE → proceed to re-screen; DO-NOT-ACTIVATE → terminal NO-GO (BA blocked; original NO-GO preserved); verdict still unposted (slipped its 2026-06-03 due) → conservative-default NO-entry (no re-defer).
    RE-SCREEN LOGIC (only if gate clears): trigger = BA ≤ $210 (~10% from $234) with trailing-30d rally rolled off OR a 737 production-rate slip. Pull BA price + trailing-30d via connector. If trigger met → fresh Strategy D thesis (not constrained by prior NO-GO). Else log "NO-GO still active; trigger not met". See Decision_Log 2026-06-01 BA deferral + 2026-04-26 D batch (BA subsection).
  conservative_default: NO entry — original NO-GO preserved; terminal (do not re-defer).
  status: pending
  outcome: (pending)

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
    STEP-0 D-DIVERGENCE-REVIEW GATE (DISPOSITIVE; same div-D-202605-1 as BA): orchestrator verdict ACTIVATE → proceed to pre-screen; DO-NOT-ACTIVATE → terminal NO-GO (DNA supersedes; entry-timing NO-GO preserved); absent → defer per §9 conservative-default NO-entry (no chaining). Read Pending_Adversarial_Reviews.md (div-D-202605-1) + Regime_State.md (D activation) at start.
    PRE-SCREEN (only if gate clears): check trailing-30d return normalized from the post-print +~10% / pre-print +~15-20% readings that produced the entry-timing fail; pull LLY price + trailing-30d via connector; verify Foundayo/orforglipron Q1 net rev + FY26 guide reaffirmation. If normalized AND no other criterion degraded → full Strategy D thesis re-construction (not constrained by prior NO-GO). Else → NO-GO STILL ACTIVE; queue for next quarterly cycle. Read Strategy.md D (criterion 6), Decision_Log 2026-04-30 LLY + GOOGL NO-GO precedent, Portfolio_Ledger D book.
  conservative_default: NO-GO still active (no entry) if the trigger is not met or the gate is not clear.
  status: pending
  outcome: (pending)
