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

- If M1a scores `shock_overlay = acute` AND M1b returns ACTIVATE for any strategy → override to DO-NOT-ACTIVATE for that strategy. An acute shock overrides mechanism-specific optimism across all strategies.
- If M1a scores `risk_sentiment = stressed` AND M1b returns ACTIVATE for A or D → override to DO-NOT-ACTIVATE. A and D are long-only directional strategies; stressed sentiment contradicts the ACTIVATE call.
- If M1a scores `growth_momentum = decelerating` AND `policy_stance = hawkish` AND M1b returns ACTIVATE for A → override to DO-NOT-ACTIVATE. Decelerating growth + hawkish policy is the classic late-cycle compression regime for catalyst-driven long equity.
- If M1a scores `inflation_trend = reaccelerating` AND `policy_stance = hawkish` AND M1b returns ACTIVATE for D → override to DO-NOT-ACTIVATE. Multi-year equity theses compress under persistent hawkish-inflation regimes.

If no reconciliation rule triggers for a strategy, M1b's call stands.

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

Architecture: two routines with file handoff per `Claude_Task_Plan.md`'s Adversarial Review Attacker / Orchestrator routine pair, queue-driven via `Pending_Adversarial_Reviews.md`. The triggering routine (typically M4 Monthly Action Conversion, or D2 if a daily technical flip creates the divergence) writes a queue entry with review type `divergence-review`, the strategy affected, prior activation state, and references to the M1b output file and current technical reading.

**M1b output (already produced).** Non-adversarial. The M1b routine output from the monthly fundamental run that produced the disagreement, including the M1a regime scoring it received and the reconciliation rule application (if any). Persisted in the regime-scoring + strategy-mapping output files; the queue entry references the path.

**Attacker routine.** Reads the M1b output, the technical call, and the queue entry. Instructed to attack the fundamental call and argue for the technical call, regardless of which side the routine would otherwise endorse. Output: best case for technical-call-based activation state, specific weaknesses in the fundamental reasoning. Written to `Adversarial_Review_<id>_attacker.md`. Attacker prompt explicitly forbids reading other repo files (Decision_Log.md, prior reviews, Strategy.md beyond the section under review) — accepted-risk note: this is prompt-discipline blinding rather than the structural blinding incognito sessions provided. The persistence-discipline part is structural — the attacker routine has no chat history and no access to the orchestrator routine's reasoning, since the orchestrator hasn't run yet.

**Orchestrator routine.** Reads the attacker output, M1b output, technical call, queue entry. Produces an explicit independent assessment that documents: (a) the validity of each weakness the attacker identified, (b) any theater in the attacker's output (generic-sounding objections without specific anchors), (c) any weaknesses the attacker missed, (d) a final activation state for the strategy (activate or do-not-activate), reasoning, and theater-check flag (CONVERGENT / DIVERGENT / MIXED — the orchestrator's judgment on whether its own assessment identified substantive issues or merely ratified the attacker without meaningful independence). The theater-check is self-certified by the orchestrator routine; this is a known reduction in rigor relative to a separate-routine theater auditor pattern, accepted as part of the migration scope. If self-certification proves inadequate empirically (theater-check flags consistently CONVERGENT across reviews), a separate Theater Auditor routine can be added in a future revision.

**Decision rule.** Orchestrator's verdict binds if and only if its theater-check is DIVERGENT or MIXED. If theater-check is CONVERGENT, the activation state defaults to DO-NOT-ACTIVATE regardless of the orchestrator's verdict — the adversarial architecture did not generate independent reasoning, so the tiebreaker applies.

Additional ambiguity triggers also default to DO-NOT-ACTIVATE:
- Orchestrator's output is literally non-committal ("either could be defended," "depends on conditions not yet observable")
- Orchestrator's verdict is conditional on unspecified future evidence

**Logging.** Attacker routine output, orchestrator routine output, theater-check flag, and final binding decision are recorded in `Decision_Log.md` with the date, strategy affected, prior and new activation states, and the queue entry ID for traceability.

### Per-strategy activation rules

Each strategy's activation rule is specified in its strategy section below. The technical component is one line of Boolean logic over the shared regime vocabulary; the fundamental component is a question for the monthly template to answer.

---

