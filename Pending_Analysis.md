# Pending Analysis — queue

Autonomous queue for Claude-only analysis steps (thesis construction, scheduled re-screens, research-deferral checkpoints, foundation-change assessments, constraint-relaxation reviews, monitoring checks). These require NO human action, so they are NOT placed on the human's calendar. The daily D2 routine (Step 1) drains entries whose `due_date` has arrived and performs the analysis in-session — each as an isolated sub-task (subagent) for fresh context where available. Schema + drain rules: Claude_Task_Plan.md → "In-session analysis and the Pending_Analysis.md queue". Entries are appended in creation order, separated by `---`; once an entry reaches a terminal `status` (`complete`/`superseded`) it is swept to `Archived_Analysis.md` by D3 on its next daily run and removed from this live file (full clear — no pointer; see Operating_Protocols.md §12 / Claude_Task_Plan.md "Queue lifecycle and daily archive policy"), so this file holds only actionable entries.

Mirrors `Pending_Adversarial_Reviews.md`. Established 2026-06-01 (IBKR-connector workflow migration — analysis events moved off the human calendar; see Decision_Log 2026-06-01 "Analysis steps moved off the human calendar to in-session execution + Pending_Analysis.md queue"). The seven entries below were migrated 1:1 from the live `[Claude]` analysis calendar events that previously required a human paste.

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
