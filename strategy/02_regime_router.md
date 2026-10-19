<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Regime router

The router determines, for each strategy, whether that strategy is currently activated (eligible to deploy new capital) or deactivated (~~capital in SGOV~~ **capital in the park — SGOV historically, VOO from the 2026-07-15 cutover forward [Rev 38, owner directive, 2026-07-15]; see Operating_Protocols.md §13**, no new entries, existing positions run to normal exits). Activation is per-strategy, not global.

### Technical indicator set (mechanical, daily)

The shared regime vocabulary above is the technical indicator set. Each strategy's activation rule maps specific combinations of these states to ACTIVATE or DO-NOT-ACTIVATE. Per-strategy technical rules are specified in the individual strategy sections.

### Fundamental analysis template (monthly)

One shared monthly template produces per-strategy activation calls. The template runs across two separate Claude routines (M1a and M1b per `Claude_Task_Plan.md`) with file-handoff to produce architectural blinding between the regime scoring and the per-strategy mapping. Where cross-month context is genuinely needed (e.g., comparing this month's regime assessment to prior months'), prior months' regime-scoring outputs (from the dedicated regime-scoring file) are read as explicit inputs in M1b — never reconstructed from M1a's underlying macro/policy/earnings inputs.

**Two-routine blinded scoring.** The original incognito-tab pattern (two manually-opened sessions with paste-back) was migrated to two separate routines under the routine architecture migration (see `Decision_Log.md` migration entry). M1a (strategy-blind regime scoring) writes only its conclusion to the regime-scoring output file; the underlying macro/policy/earnings inputs and M1a's full reasoning chain are NOT persisted. M1b (strategy-mapping) is a separate routine with fresh context that reads only the regime-scoring output file and applies per-strategy mapping. Blinding is preserved by what is persisted between routines, not by session isolation. The earlier-rejected single-session two-step pattern (where both sub-steps shared one session's context window) is NOT what M1a/M1b implements — the routine boundary is a genuine context boundary, equivalent to the original incognito-session boundary for the architectural property being preserved.

Residual limitation under the routine architecture: a routine has full repo read access by default, and structural prevention of cross-file reads (the property incognito sessions provided) is replaced by prompt-discipline ("M1b reads ONLY the regime-scoring file; do not read macro inputs from any source"). Documented as accepted-risk in the migration entry. The persistence-discipline part is structural — the macro inputs are nowhere in the repo by the time M1b runs — so the residual concern is narrower than full discipline-only blinding.

*M1a routine (strategy-blind regime scoring).* M1a's inputs, the five regime-condition axes, and the unavailable-input fallback are specified in their own strategy-blind top-level section, **`## Regime scoring (strategy-blind, monthly)`** — kept separate so M1a's generated slice carries the scoring WITHOUT this strategy-naming mapping (`Claude_Task_Plan.md` "Strategy reading" + `ops/RUNBOOK.md` §9). M1a writes ONLY the 5-axis scoring to the regime-scoring file; its underlying inputs and full reasoning chain are not persisted.

*M1b routine (strategy-mapping).* Separate routine with fresh context, architecturally blinded from M1a. Given ONLY the regime-scoring file (the 5 axis assignments with rationale) and each strategy's fundamental question, produces per-strategy ACTIVATE / DO-NOT-ACTIVATE calls. M1b does not see the underlying macro/policy/earnings/geopolitical inputs (these were not persisted by M1a) — only the regime scoring. This prevents M1b from re-anchoring on the input data and also prevents the strategy-specific questions from contaminating the regime assessment (strategy-identity leakage per 2.4).

**M1a / M1b reconciliation rules.** Certain combinations of M1a regime scoring and M1b activation calls are internally inconsistent. When a reconciliation rule below triggers, the affected strategy's fundamental call defaults to DO-NOT-ACTIVATE regardless of M1b's output, and the contradiction is logged in the M1b output for monthly review. Reconciliation is checked mechanically after M1b completes:

- If M1a scores `shock_overlay = acute` AND M1b returns ACTIVATE for a strategy → override to DO-NOT-ACTIVATE for that strategy **unless the Shock Transmission Register below exempts it for this scoring (Rev 50, 2026-10-19).** The override BINDS BY DEFAULT: a strategy with no register row, a row that binds, or an exempt-by-class row whose circuit-breaker has tripped or whose gate measurement is absent or older than its maximum age, is overridden exactly as before. An exemption decides only whether this rule APPLIES to M1b's raw call — it never alters that call and never turns a DO-NOT-ACTIVATE into ACTIVATE. The register is read and applied mechanically, after M1b, by the same step that applies the three rules below, from `state.shock_transmission_status` (`bigquery/257_shock_transmission_register.sql`); M1a never reads it, and M1b reads no macro input to evaluate it. An acute shock still overrides mechanism-specific optimism for every strategy whose mechanism the shock is transmitted into — which strategies those are is now stated per strategy in the register rather than assumed for all.
- If M1a scores `risk_sentiment = stressed` AND M1b returns ACTIVATE for A or D → override to DO-NOT-ACTIVATE. A and D are long-only directional strategies; stressed sentiment contradicts the ACTIVATE call.
- If M1a scores `growth_momentum = decelerating` AND `policy_stance = hawkish` AND M1b returns ACTIVATE for A → override to DO-NOT-ACTIVATE. Decelerating growth + hawkish policy is the classic late-cycle compression regime for catalyst-driven long equity.
- If M1a scores `inflation_trend = reaccelerating` AND `policy_stance = hawkish` AND M1b returns ACTIVATE for D → override to DO-NOT-ACTIVATE. Multi-year equity theses compress under persistent hawkish-inflation regimes.

If no reconciliation rule triggers for a strategy, M1b's call stands.

**Shock Transmission Register (Rev 50, 2026-10-19 — the per-strategy attributes of the `shock_overlay = acute` rule).** One row per roster strategy. `Exempt by class` says whether the rule applies at all; the three `Gate` columns are the circuit-breaker that re-arms the rule on an exempt strategy (a dash means no gate); `Horizon class` is limb (b)'s column, pinned to the strategy-holding-horizon reading and `status-quo` everywhere until measured. The runtime mirror is `ops.shock_transmission_register` → `state.shock_transmission_status` (`bigquery/257_shock_transmission_register.sql`); `scripts/check_shock_register_lockstep.py` (blocking CI) asserts this table and that file's seed rows agree, so a row is changed in both or in neither. A newcomer's row is authored by SL2 with its candidate section (default: binds) and inserted by SL5 at PROBE registration; a strategy with no row binds.

| Strategy | Transmission class | Exempt by class | Gate: median 60d pair correlation re-binds at ≥ | Gate: share of pairs with 60d correlation ≥ 0.80 re-binds at ≥ | Gate: max measurement age (days) | Horizon class (limb b) | Basis |
|---|---|---|---|---|---|---|---|
| A | DIRECTIONAL-LONG | no | — | — | — | status-quo | Long-only, 1–12 month holds; a shock prices into the index level A is long. BINDS. |
| B | DIRECTIONAL-LONG-BIASED | no | — | — | — | status-quo | Long-biased by construction (0 of ~108 theses ever short); long post-event drift carries beta during a shock, and B's own router rationale says a macro-dominated tape makes overreaction indistinguishable from regime change. No measured event-reaction-dispersion series exists to gate on, so default-REJECT: BINDS until one does. |
| C | DEFINED-RISK | no | — | — | — | status-quo | Loss bounded by structure (2.18); C already carries its own HYBRID FOMC-only scope with a widening gate, which this register neither duplicates nor widens. BINDS. |
| D | DIRECTIONAL-LONG | no | — | — | — | status-quo | Long-only, multi-year; entering at shock-elevated levels is the 2.7 "buying into declines" exposure. BINDS. Its horizon-class row is the live limb (b) question (see the Rev 50 changelog). |
| E | SPREAD | yes | 0.85 | 60% | 35 | status-quo | Market factor netted by construction. The surviving channel is an asymmetric within-industry-group shock that lifts pair correlation — E's own named failure channel — and the gate measures exactly that, on M2's current ≥ 0.50-floor population. Measured 2026-04 → 2026-10 across two oil shocks: median 60d correlation 0.70–0.75, at most 37.5% of pairs ≥ 0.80; the thresholds sit outside that range by design. Narrow-market risk stays with E's own technical rule (Breadth = HEALTHY), which is unchanged. |

**Classes.** `DIRECTIONAL-LONG` / `DIRECTIONAL-LONG-BIASED`: net-long directional expression — the shock prices into what the strategy is long, so the rule applies. `DEFINED-RISK`: loss bounded by the instrument structure; the rule applies, and any scope carve-out is the strategy's own (C's HYBRID state). `SPREAD`: market factor netted; the rule applies only through a circuit-breaker on the strategy's named failure channel. `SHOCK-NATIVE` (no roster member today): a strategy whose activation rule REQUIRES `shock_overlay ∈ {latent, acute}` — the acute grade is its activation INPUT, not a contradiction of mechanism-specific optimism, so the rule has nothing to reconcile and the strategy is exempt by construction, with no gate. SL1 STEP 3 (a) and SL2 (A) must enforce three authoring rails before a SHOCK-NATIVE candidate can qualify: (i) hedged or defined-risk structure — no net-long directional expression; (ii) per-thesis invalidation keyed to the `### Shock / overlay grading rubric`'s own de-escalation legs (the 15-trading-day quiet window and the 50% retracement), so a thesis cannot outlive the shock that justified it; (iii) declared frequency denominated in qualifying shock events, which the rubric already counts.

**How the gate is evaluated.** M2 publishes, in its monthly `research-screen` decision-log row, the median 60-day pair correlation and the share of pairs with 60-day correlation ≥ 0.80 over its ≥ 0.50-floor population, with the measurement date. `state.shock_transmission_status` reads the latest such row and `state.trading_day_today`: `measurement_fresh` requires age ≤ the row's max; `breaker_tripped` is TRUE when the measurement is missing or stale or either leg is at or above its threshold; `override_applies` is `NOT (exempt_by_class AND NOT breaker_tripped)`. M1b step 2 reads `override_applies` for each strategy and applies the first rule only where it is TRUE, logging an exemption — with the class and the measured legs — under "Reconciliation overrides applied" exactly as it logs an override; M4's standing `fundamental-call` row records `reconciliation_rule` = `shock-override-exempt:<class>` for an exempt strategy whose raw call the rule would otherwise have overridden. The gate never reads breadth, which belongs to E's technical rule, and never reads M1a's inputs.

**Inputs to M1a + fallback protocol for unavailable inputs.** Specified in the strategy-blind top-level section `## Regime scoring (strategy-blind, monthly)` (so they reach M1a's slice without the mapping above).

**Fallback interaction with divergence review (rev 4).** When the fallback protocol fires, M1b is not run, no M1b output exists, and the "Router divergence review" procedure below is suppressed for that month for all strategies. Per-strategy activation states resolve as follows during a fallback month: fundamental call = DO-NOT-ACTIVATE for all strategies (per fallback rule above); therefore if a strategy's technical call is DO-NOT-ACTIVATE, its activation state is DO-NOT-ACTIVATE (agreement); if a strategy's technical call is ACTIVATE, its activation state is DO-NOT-ACTIVATE (fundamental fallback binds without divergence review). This resolution is logged in the monthly fundamental output with explicit flag `fallback_suppression = true` and is tracked separately from orchestrator-ambiguity defaults in indicator 9.4.

**Output format (per strategy, immutable):**

```
Strategy [letter]:
  Activation call: [ACTIVATE | DO-NOT-ACTIVATE]
  Reasoning: [text, max 300 words, references M1a regime scoring]
  Reconciliation override applied: [yes (with rule) | no]
  Technical signal for this strategy: [ACTIVATE | DO-NOT-ACTIVATE]
  Divergence: [YES | NO]
  If YES → trigger the router divergence review per the section below
```

### Router divergence review (two-routine, triggered on disagreement)

Triggered only when the technical call and the fundamental call for a strategy differ on ACTIVATE vs DO-NOT-ACTIVATE AND the fundamental call was produced by a normal M1b run (not by fallback suppression). Agreement updates the activation state mechanically with no review. Fallback-suppressed months do not trigger divergence review — see "Fallback interaction with divergence review" in the fundamental template section. Technical signals update daily; fundamental signals update monthly. Activation state changes can occur any day a signal would cross a threshold.

Architecture: two routines with the BigQuery-keyed transcript handoff per `Claude_Task_Plan.md`'s Adversarial Review Attacker / Orchestrator routine pair, queue-driven through `events.queue_events` / `state.open_queue`. The triggering routine (typically M4 Monthly Action Conversion, or D2 if a daily technical flip creates the divergence) writes a queue entry with review type `divergence-review`, the strategy affected, prior activation state, and references to the M1b output file and current technical reading.

**M1b output (already produced).** Non-adversarial. The M1b routine output from the monthly fundamental run that produced the disagreement, including the M1a regime scoring it received and the reconciliation rule application (if any). Persisted in the regime-scoring + strategy-mapping output files; the queue entry references the path.

**Attacker routine.** Reads the M1b output, the technical call, and the queue entry. Instructed to attack the fundamental call and argue for the technical call, regardless of which side the routine would otherwise endorse. Output: best case for technical-call-based activation state, specific weaknesses in the fundamental reasoning, stored as the keyed attacker row in `events.adversarial_reviews`. Attacker prompt explicitly forbids reading other repo files (Decision_Log.md, prior reviews, Strategy.md beyond the section under review) — accepted-risk note: this is prompt-discipline blinding rather than the structural blinding incognito sessions provided. The persistence-discipline part is structural — the attacker routine has no chat history and no access to the orchestrator routine's reasoning, since the orchestrator hasn't run yet.

**Orchestrator routine.** Reads the exact current attacker row from `state.adversarial_reviews_current` by `(review_id, cycle_number, role='attacker')`, M1b output, technical call, and queue entry. Produces an explicit independent assessment that documents: (a) the validity of each weakness the attacker identified, (b) any theater in the attacker's output (generic-sounding objections without specific anchors), (c) any weaknesses the attacker missed, (d) a final activation state for the strategy (activate or do-not-activate), reasoning, and theater-check flag (CONVERGENT / DIVERGENT / MIXED — the orchestrator's judgment on whether its own assessment identified substantive issues or merely ratified the attacker without meaningful independence). The theater-check is self-certified by the orchestrator routine; this is a known reduction in rigor relative to a separate-routine theater auditor pattern, accepted as part of the migration scope. If self-certification proves inadequate empirically (theater-check flags consistently CONVERGENT across reviews), a separate Theater Auditor routine can be added in a future revision.

**Decision rule.** Orchestrator's verdict binds if and only if its theater-check is DIVERGENT or MIXED. If theater-check is CONVERGENT, the activation state defaults to DO-NOT-ACTIVATE regardless of the orchestrator's verdict — the adversarial architecture did not generate independent reasoning, so the tiebreaker applies.

Additional ambiguity triggers also default to DO-NOT-ACTIVATE:
- Orchestrator's output is literally non-committal ("either could be defended," "depends on conditions not yet observable")
- Orchestrator's verdict is conditional on unspecified future evidence

**Logging.** Attacker routine output, orchestrator routine output, theater-check flag, and final binding decision are recorded in `Decision_Log.md` with the date, strategy affected, prior and new activation states, and the queue entry ID for traceability.

### Per-strategy activation rules

Each strategy's activation rule is specified in its strategy section below. The technical component is one line of Boolean logic over the shared regime vocabulary; the fundamental component is a question for the monthly template to answer.

---

