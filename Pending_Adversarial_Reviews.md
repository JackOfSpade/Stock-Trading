# Pending Adversarial Reviews — queue

Queue file for structured adversarial reviews (pre-mortem, divergence-review, m2m-termination, capital-redistribution, scope-widening-adjudication) per `Claude_Task_Plan.md` ADVERSARIAL REVIEWS section. Triggering routines (M5, A3, kill-trigger handlers, termination handlers) write entries here; review routines (Recommendation / Attacker / Orchestrator) read entries and produce outputs per file handoff.

Each entry is a YAML-style block separated by `---`. Entries are appended in order of creation; processed entries are retained for traceability (status marked `complete` rather than deleted).

Schema reference (per `Claude_Task_Plan.md`):
- `id`: unique identifier (e.g., `div-D-202605-1`, `premortem-strategyB-cycle3`, `m2m-D-202609`).
- `review_type`: one of `pre-mortem | divergence-review | m2m-termination | capital-redistribution | scope-widening-adjudication`.
- `strategy`: `A | B | C | D | E | router | n/a` (n/a for account-level redistribution).
- `trigger_context`: one paragraph of context.
- `artifact_path`: relative repo path to the artifact under review.
- `prior_state`: free-form text describing system state pending review.
- `attacker_due_date`: next trading day after queue creation (America/Denver).
- `orchestrator_due_date`: one trading day after `attacker_due_date`.
- `recommendation_due_date`: `n/a` unless `review_type = capital-redistribution`.
- `status`: `pending | recommendation-complete | attacker-complete | complete | superseded`.
- `attacker_output_path` / `orchestrator_output_path` / `recommendation_output_path`: set by the respective routine when it completes.
- `cycle_number`: integer; `1` for first cycle of a given artifact; `n/a` for non-cycling review types.
- `notes`: free-form, optional.

---

- id: div-C-202605-1
  review_type: divergence-review
  strategy: C
  trigger_context: M1b 2026-06-01 (`Monthly_Fundamental.md`, covering the May 2026 regime) raised Strategy C technical-vs-fundamental divergence. Technical signal = ACTIVATE (SPY Trend = NEUTRAL ≠ DOWN per Strategy.md C rule). Fundamental signal = DO-NOT-ACTIVATE on the macro-domination axis (decelerating growth + reaccelerating inflation + hawkish policy with new Chair + risk-on pricing concentrated in earnings-momentum / ceasefire-relief; cross-sectional dispersion compression in stagflation-squeeze regimes compounds AI_Edges 2.13 miscalibration in earnings-event options pricing). Divergence direction (Tech ACTIVATE / Fund DNA) is the same as the April 2026 cycle, which resolved HYBRID-ACTIVATE (FOMC-only) with theater-check CONVERGENT — that resolution is the prior state operative until this review completes. Per M1b PART 2: "prior cycle resolved HYBRID-ACTIVATE-FOMC-only — re-run for May regime; existing HYBRID state remains operative until review completes." M5 enqueues per Claude_Task_Plan.md M5 rule B. Technical-reading snapshot at queue creation (from `Regime_State.md` / M1b PART 2): SPY Trend = NEUTRAL, VIX = NORMAL, Yield Curve Sustained Inversion = NOT-SUSTAINED, Equity Breadth = HEALTHY.
  artifact_path: Monthly_Fundamental.md
  prior_state: HYBRID ACTIVATE (FOMC-only) — operative pending this review per the 2026-04-25 divergence-review verdict (FOMC events router-eligible; corporate earnings DO-NOT-ACTIVATE; FDA PDUFA DO-NOT-ACTIVATE; vol-directional theses DO-NOT-ACTIVATE). New C entries permitted ONLY for FOMC catalysts meeting Strategy.md Section "Strategy C: Entry criteria" 1–5; the FOMC June 2026 thesis-construction event (`7pbkg1kh2pge7midfiqnj6edvk`, Mon 2026-06-08 09:00 MT) is unaffected by this queue entry and proceeds under the existing HYBRID state.
  attacker_due_date: 2026-06-02
  orchestrator_due_date: 2026-06-03
  recommendation_due_date: n/a
  status: attacker-complete
  attacker_output_path: Adversarial_Review_div-C-202605-1_attacker.md
  orchestrator_output_path:
  recommendation_output_path: n/a
  cycle_number: 1
  notes: Prior-cycle id for traceability — April 2026 divergence resolved HYBRID-ACTIVATE-FOMC-only with theater-check CONVERGENT (Decision_Log_Archive_2026_Q2.md entry "2026-04-25 Strategy C divergence adversarial review — HYBRID ACTIVATE (FOMC only)"). The HYBRID scope decomposition itself is not the artifact under this review — the May M1b fundamental DNA call is. Attacker 2026-06-02 verdict: FUNDAMENTAL CLAIM SHOULD NOT SURVIVE (nine weaknesses, six Tier 1 / borderline-Tier 1, three Tier 2 supporting; argues for technical ACTIVATE at minimum on FOMC-only scope).

---

- id: div-D-202605-1
  review_type: divergence-review
  strategy: D
  trigger_context: M1b 2026-06-01 (`Monthly_Fundamental.md`, covering the May 2026 regime) raised a NEW Strategy D technical-vs-fundamental divergence created by a fundamental FLIP from ACTIVATE (April 2026) to DO-NOT-ACTIVATE (May 2026). Technical signal = ACTIVATE (SPY Trend = NEUTRAL passes "(UP OR NEUTRAL)"; Yield Curve Sustained Inversion = NOT-SUSTAINED passes). Fundamental signal = DO-NOT-ACTIVATE on the multi-year-thesis-decompression axis (Q1 GDP revised down to +1.6% with private-inventory + services-side consumer-spending downward revisions; UMich record-low third consecutive monthly decline; ISM Services New Orders −7.1pp; April core CPI +0.4% MoM SA largest since Jan 2025; April PPI +6.0% YoY largest since Dec 2022; hawkish FOMC minutes + new hawkish Chair Warsh sworn 5/22; persistent hawkish-inflation structurally compresses multi-year theses via discount-rate path + reaccelerating-inflation tail + cumulative pressure on long-duration earnings streams; Strategy D pre-mortem identifies the concentration / AI / large-cap-leadership channel as exactly the configuration most exposed to multi-year decompression). Reconciliation override `inflation_trend=reaccelerating AND policy_stance=hawkish → D ACTIVATE→DNA` precondition was satisfied but did not fire mechanically (rule is directional only; the raw M1b call is already DNA). M5 enqueues per Claude_Task_Plan.md M5 rule B. Technical-reading snapshot at queue creation: SPY Trend = NEUTRAL, VIX = NORMAL, Yield Curve Sustained Inversion = NOT-SUSTAINED, Equity Breadth = HEALTHY.
  artifact_path: Monthly_Fundamental.md
  prior_state: ACTIVATE (April 2026 cycle, no-divergence agreement) — operative pending this review per Strategy.md / Experiment_Parameters.md "During the review, the strategy retains its prior activation state." Existing D positions (RTX OPEN 2026-04-27; DIS OPEN 2026-05-07) run to thesis-invalidation per Strategy.md "router-deactivation-does-not-force-exits" rule; both received M4 HOLD recommendations on 2026-05-31 with all invalidation criteria NOT-TRIPPED. New D entries blocked pending review outcome per M1b PART 2 explicit text. BA D re-screen (event `r9i6u6mnpk9ukoj2bh15m1fr7c`, Mon 2026-06-01 09:00 MT) and LLY D mechanical re-screen (event `fpbueqccja9thjcnuj6ck9l6rs`, Fri 2026-06-12 09:30 MT) have a STEP-0 D-divergence-review gate added to their event descriptions by this M5 cycle.
  attacker_due_date: 2026-06-02
  orchestrator_due_date: 2026-06-03
  recommendation_due_date: n/a
  status: attacker-complete
  attacker_output_path: Adversarial_Review_div-D-202605-1_attacker.md
  orchestrator_output_path:
  recommendation_output_path: n/a
  cycle_number: 1
  notes: First divergence-review queued for Strategy D since experiment inception (April was no-divergence ACTIVATE/ACTIVATE). The FLIP-direction is ACTIVATE→DNA fundamentally; if the orchestrator verdict resolves DO-NOT-ACTIVATE, the router state flips and the FLIP-TO-DO-NOT-ACTIVATE M5-rule-A downstream actions (Regime_State.md update + Decision_Log binding entry + cancel any pending D thesis-construction events) execute at orchestrator-output time. If the verdict resolves ACTIVATE, the existing ACTIVATE state continues and the BA/LLY re-screen gates clear. Attacker 2026-06-02 verdict: FUNDAMENTAL CLAIM SHOULD NOT SURVIVE (ten weaknesses, six Tier 1, four Tier 2; argues for technical ACTIVATE; identifies that the architectural Sustained-Inversion safeguard for the cited recession-compression channel is CONCEDED NOT-SUSTAINED, that the flip is supported on only 1 of 4 April ACTIVATE criteria, that the pre-mortem-self-referential mechanism is anti-conditioned/unfalsifiable, and that the fundamental call lands at the same destination as a non-firing mechanical reconciliation override — back-fit-to-mechanical pattern).

---

- id: div-E-202605-1
  review_type: divergence-review
  strategy: E
  trigger_context: M1b 2026-06-01 (`Monthly_Fundamental.md`, covering the May 2026 regime) raised Strategy E technical-vs-fundamental divergence. Technical signal = ACTIVATE (SPY Trend = NEUTRAL ≠ DOWN; VIX = NORMAL ≠ HIGH; Equity Breadth = HEALTHY — all three clauses pass per Strategy.md rev-2 tightened E technical rule). Fundamental signal = DO-NOT-ACTIVATE on the within-industry-mean-reversion axis (stagflation-tilted axes moving against trend simultaneously while risk-on pricing is concentrated in Q1-earnings-momentum + ceasefire-relief vectors; shock-recovery vector compresses within-industry dispersion in energy / transports / industrials; trailing-252-day correlation stationarity remains stressed by 2026 regime-break sequence — March oil shock + February tariff-IEEPA SCOTUS ruling + ongoing Iran conflict; the structural-macro-hedge-failure-before-convergence risk identified in the April divergence-review verdict persists). Divergence direction (Tech ACTIVATE / Fund DNA) is the same as the April 2026 cycle, which resolved DO-NOT-ACTIVATE (default-on-ambiguity rule + procedural moot point under ETF-substitution at current book size) with theater-check CONVERGENT — that resolution is the prior state operative until this review completes. M5 enqueues per Claude_Task_Plan.md M5 rule B. Technical-reading snapshot at queue creation: SPY Trend = NEUTRAL, VIX = NORMAL, Yield Curve Sustained Inversion = NOT-SUSTAINED, Equity Breadth = HEALTHY.
  artifact_path: Monthly_Fundamental.md
  prior_state: DO-NOT-ACTIVATE — operative pending this review per the 2026-04-25 divergence-review verdict (affirmative case demonstrated stated DNA rationale incomplete on sector-vs-industry-group language but did not defeat the available DNA rationale that regime-break sequence destabilizes trailing-252-day correlation stationarity; procedural moot point — ETF substitution at current book size produces near-zero realized exposure regardless of router state — did not defeat the default-DNA-on-ambiguity rule due to procedural symmetry). No new E entries; existing state is no open E positions (E book at $1,890.44 fully in SGOV). M3 2026-06-01 (`Monthly_E_Pairs.md`) explicitly framed the pair shortlist as "divergence-review reference material, not an entry queue" given the M1b DO-NOT-ACTIVATE call and the universal ETF-substitution-required execution flag at the current per-strategy $1,890.44 book size ($37.81/leg sizing below every individual-stock leg in the shortlist). M5 does NOT schedule any E pair thesis-construction events this cycle (existing DNA state operative + advisory-only M3 disposition).
  attacker_due_date: 2026-06-02
  orchestrator_due_date: 2026-06-03
  recommendation_due_date: n/a
  status: attacker-complete
  attacker_output_path: Adversarial_Review_div-E-202605-1_attacker.md
  orchestrator_output_path:
  recommendation_output_path: n/a
  cycle_number: 1
  notes: Prior-cycle id for traceability — April 2026 divergence resolved DO-NOT-ACTIVATE (default-on-ambiguity) with theater-check CONVERGENT (Decision_Log_Archive_2026_Q2.md entry "2026-04-25 Strategy E divergence adversarial review — DO-NOT-ACTIVATE"). The M2 signal-process-tightening follow-up initiated 2026-04-26 is a separate work product (path back to ACTIVATION via signal-process refinement) and not the artifact under this review — the May M1b fundamental DNA call is. Attacker 2026-06-02 verdict: FUNDAMENTAL CLAIM SHOULD NOT SURVIVE (ten weaknesses, six Tier 1, four Tier 2; argues for technical ACTIVATE; identifies maximum-strength convergent-with-prior pattern on already-CONVERGENT April verdict, load-bearing correlation-stationarity claim unmeasured, cited regime-break sequence actively RESOLVING by artifact's own PART 1 data, anti-conditioned risk-on framing, and that the operative consideration is procedural moot point at current book size — substantive ACTIVATE + execution-feasibility-deferred operational state is the honest decomposition).

---
