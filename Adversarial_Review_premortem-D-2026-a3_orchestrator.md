# Adversarial Review — Orchestrator — premortem-D-2026-a3

- **Review type:** pre-mortem
- **Strategy:** D
- **Date:** 2026-08-05
- **Cycle number:** 6
- **Artifact under review:** strategy/08_pre_mortems.md (Pre-mortem: Strategy D, rev 6, 2026-08-03)
- **Attacker output:** Adversarial_Review_premortem-D-2026-a3_attacker.md

## Final verdict

**TIER 1 DEFECT — REVISION REQUIRED** — the primary offsetting claim for the 5x per-name blast-radius
increase ("size-vs-outcome becomes a directly measurable calibration series, consumed by the Section 4
indicator portfolio") describes a consumer that does not exist anywhere in Section 4's own five-item
definition. I independently enumerated Section 4 and confirmed this myself; it is not merely the
attacker's characterization.

**Binding decision:** Rev 6 is not accepted. A cycle-7 revision must either (a) build the calibration-
consuming mechanism the claim describes — a real conviction-tier-vs-outcome indicator in Section 4 or
Section 6 — or (b) remove the false claim and honestly state that conviction-tier calibration is
currently undetected, not just unmitigated. Given the soft-cap analysis below, another cycle is
justified rather than accepted-as-is.

## Theater-check flag

**MIXED** — I reach the same verdict token as the attacker, but by materially different means: I
independently re-derived the Section 4 enumeration rather than trusting the attacker's list; I found
the attacker's findings #2 and #3 to be over-graded and downgrade both; I traced finding #3's
underlying citation to its real source in `AI_Trading_Foundation.md` and found it mis-labeled ("A2
2026" vs. the actual "A1 2026 annual sweep") rather than "unverifiable" as the attacker framed it; I
pulled the live book (`state.current_positions`, `events.cash_flows`, `state.capital_allocation_calls`)
to test finding #6 against real positions; and I found a Tier 3 completeness gap (missing AI_Edges
2.28/2.31) by comparing D's rev 6 against E's rev 6 parallel edit, which the attacker structurally could
not do under blinding. This is not CONVERGENT (I did not merely ratify); it is not fully DIVERGENT
either (I land on the same verdict token for the same central reason).

## (a) Assessment of each weakness the attacker identified

1. **[Attacker: Tier 1] Calibration-detection mechanism does not exist in Section 4.**
   **VALID TIER 1.** Independently confirmed. Section 4 (`08_pre_mortems.md` lines 739-749) is fully
   enumerated in the document and contains exactly five indicators: beta-adjusted alpha-test (CI-gated),
   SGOV-underperformance gap, thesis-invalidation count >=3/36mo, theme-concentration check, and
   cumulative EV per closed position over a rolling 5 closes. I grepped "conviction" across the entire
   D section (lines 657-856): the only hits are in the Section 5 two-layer-control paragraphs making the
   claim itself — none inside Section 4's or Section 6's actual definitions. No indicator anywhere reads
   conviction tier, size, or outcome jointly. This is squarely rev-15 Tier 1: "describes a mechanism that
   cannot do what it claims." I did not find a plausible sibling-section rescue (e.g. Section 6 doesn't
   have it either — I checked lines 807-820 line by line).

2. **[Attacker: Tier 1] OUTER-layer CaR envelope has no stated enforcement mechanism.**
   **VALID BUT TIER 2 (downgrade from attacker's Tier 1).** The gap is real — the correlation-bucket
   rule ("computed by classical-method delegation") and the metric-immutability rule ("mechanism-
   enforced via classical-method delegation") both name an enforcement method; the CaR envelopes do
   not. But a per-name aggregate-CaR sum across tranches is trivial bookkeeping arithmetic, not a
   mechanism that "cannot do what it claims" in the Tier 1 sense — it is an unspecified *procedural
   form* for an otherwise straightforward computation. That is rev-15 Tier 2 ("a threshold, indicator,
   or protocol is specified but its specific... procedural form is unjustified"), not Tier 1.

3. **[Attacker: Tier 1] Self-containment break — unreproduced A2 2026 findings citation.**
   **VALID BUT TIER 3 (downgrade), on different grounds than the attacker's.** I read
   `AI_Trading_Foundation.md` directly, which the attacker could not. The substance checks out: line
   315 states for 2.13, "*A1 2026 annual sweep update*... REDUCTION: NONE — flat, not reduced"; line 351
   states for 2.18, "*A1 2026 annual sweep update — strengthened with in-window evidence*." Both match
   the pre-mortem's "flat" / "STRENGTHENED" claims in direction and substance. So this is NOT the
   "unverifiable directional claim asserted as settled fact" the attacker characterizes it as — I
   verified it, and it is true. What I found instead: the pre-mortem cites "`AI_Trading_Foundation.md`'s
   A2 2026 findings," but the actual source is the **A1 2026 annual sweep**, not "A2 2026" — "A2 2026"
   is a distinct process elsewhere in that document (a citation-integrity audit; see e.g. its "verified
   the phrase occurs exactly twice repo-wide" language). This is a real but minor citation-labeling
   defect — Tier 3 completeness/accuracy, not a Tier 1 self-containment failure, since the claim is
   correct and traceable once you go to the right sweep.

4. **[Attacker: Tier 2] Five-of-eleven / six-of-eleven count inversion.** **VALID TIER 2**, agree with
   attacker's grade. I recounted both lists myself: confluence list has 6 items (2.4, 2.8, 2.13, 2.15,
   2.17, 2.19); not-in-confluence has 5 (2.6, 2.7, 2.14, 2.20, 2.23). The summary sentence inverts this
   ("Five-of-eleven... route through cap... six-of-eleven route through other"). Confirmed real and
   textually self-contradictory, but it's a trivial swapped label sitting two sentences below the
   correct lists — a careful reader can recount instantly. Tier 2, not Tier 1: it doesn't mislead about
   magnitude or mechanism, just about a count.

5. **[Attacker: Tier 2] Per-tranche sizing not shown aggregate-of-name-aware.** **VALID TIER 2**, agree.
   The seven-factor list genuinely omits "capital already committed to this name," and the per-name cap
   is stated only as an external backstop, not an input the tranche justification itself must compute.

6. **[Attacker: Tier 2] No Section 6 monitoring item for CaR-envelope drift via price appreciation.**
   **VALID TIER 2**, agree, and I tested it against the live book (see Independent verification below).
   Currently no name breaches the envelope (largest is GEV at ~5.1% of D's $2,498.85 strategy portfolio),
   but the structural gap is real: nothing in Section 6 re-checks aggregate CaR after price drift, only
   at the moment of a new tranche decision.

7. **[Attacker: Tier 3] Unsourced empirical comparison figures (Known Limitation 16).** **VALID TIER 3**,
   agree with the grade, but I can add grounding the attacker (blinded) couldn't: I traced the Sharpe
   0.703/0.241, p>0.34 figures to `AI_Trading_Foundation.md` line 261 ("A1 2026 annual sweep update...
   Level: L4 (FINSABER, arXiv 2505.07078)"). The numbers are real and sourced *elsewhere in the repo* —
   not a fabricated or floating statistic — the defect is specifically that the pre-mortem's own inline
   citation omits the paper/arXiv reference, which is exactly the completeness-level defect the attacker
   correctly scoped it as.

## (b) Theater in the attacker's output

Largely substantive. All seven anchors quote real, correctly-located text; I checked every one against
the source and none were fabricated or misquoted. The self-imposed scope confirmation is honest and the
attacker explicitly declines to manufacture findings against material the artifact flags as
out-of-scope-this-cycle (W5/W7/alpha-test residual) — a good discipline. The one place I'd call
overreach rather than theater: findings #2 and #3 both use Tier 1 language ("cannot do what it claims,"
"unverifiable... treated as Tier 1... when load-bearing") for gaps that, on inspection, are procedural-
specification and citation-labeling gaps rather than structural contradictions or fabricated claims. This
reads as tier-inflation on real findings, not padding with generic objections — the attacker's own
anchors are specific throughout.

## (c) Weaknesses the attacker missed

1. **The A2-2026-vs-A1-2026 citation mislabel (detailed in (a)3).** The attacker treated this as an
   unverifiable claim; it is verifiable and true, but mis-cited to the wrong internal process name. The
   attacker was structurally blocked from finding this (forbidden from reading other repo files).

2. **Cross-strategy completeness gap: AI_Edges 2.28 and 2.31 are absent from D's Section 5, while E's
   rev 6 (same 2026-08-03 SL2 authoring pass, same sizing-retirement trigger) explicitly added 2.28
   ("memory-mediated cross-session contamination") to its own Section 5 list, reasoning that a prior
   session's persisted decision-log sizing justification could anchor a later session's thesis-
   construction judgment. That exact mechanism applies at least as directly to D: D's inner-layer risk
   budget is set per-thesis and justified in a decision-log entry per the seven-factor list, which is
   precisely the kind of durable, persisted artifact 2.28 describes. Item 2.31 ("goal drift through
   inaction over long horizons") is arguably even more on-point for D specifically — D has no maximum
   hold, exits only on completion/invalidation, and Strategy.md/the pre-mortem itself already document
   "no escape mechanism for existing positions." I grepped the full D section for "2.28," "2.31," and
   "memory-mediated": zero hits. This is a real Tier 3 completeness gap the attacker could not find
   (blinded from E's document) and I could only find by deliberately comparing the two strategies'
   parallel same-day edits — the same pattern the 2026-07-30 theater judge specifically rewarded when an
   orchestrator did it for E against D.

3. **Live-book verification of the central residual.** D currently holds 9 names / 12 tranches (AMZN,
   CRM, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER — matching the trigger context). I reconstructed D's actual
   strategy-portfolio denominator via `events.cash_flows` (the 2026-08-05 note: "Post-sweep D holds
   1999.08 + 499.77 = 2498.85") rather than trusting the first, smaller sweep figure, and recomputed
   per-name concentration: no current breach (GEV highest at ~5.1%, well inside the 10% cap). This
   matters for grading finding #6 correctly: the drift-monitoring gap is real but not yet biting.

4. **The SISA-authoring-path retired-2% contamination SL2 flagged on 2026-07-30 is confirmed NOT present
   in this artifact.** I queried `events.decision_log` and found the SL2 2026-07-30 entry describing
   contamination in `Claude_Task_Plan.md`, `bigquery/36_strategy_arsenal_seed.sql`, and
   `strategy/roster.yaml`. I then grepped every "2%" occurrence inside D's pre-mortem section (9 hits):
   every single one is struck through with an adjacent Rev 43 superseded annotation. This specific
   contamination vector is real elsewhere in the repo but does not reach this artifact — it is not a
   defect of premortem-D-2026-a3.

5. **Cycle 5's four Tier 1 items (W1-W4) and the screen-(iv) self-containment break (Rev 40 absent) are
   genuinely fixed in rev 6, verified directly against the text, not just accepted on the revision
   header's word.** Rev 40 now appears multiple times inline (lines 690, 697, 779 in my numbering); all
   nine "2%" mentions are properly struck and annotated; and KL16 now carries the ~-8.8pp effective-
   firing-threshold figure the cycle-5 orchestrator explicitly recommended adding.

## (d) Verdict reasoning

**Rev-15 forcing question** (Experiment_Parameters.md:495): *"If we accept the pre-mortem at its
current revision with these residual Tier 1 items, would that change deployment risk vs. fixing them
first?"*

**Answer: (a) yes, fixing changes deployment risk meaningfully — continue cycling.** Specifically: the
false "consumed by the Section 4 indicator portfolio" claim currently creates false comfort that
conviction-tier miscalibration (2.13/2.26) is being mechanically detected when it is not. This is not
cosmetic, because of what changed this cycle and what D's architecture is: (i) the per-name blast radius
just went from 2% to 10% (5x, arithmetic independently confirmed: Rev 43 owner directive 2026-07-28,
Experiment_Parameters.md rev 18); (ii) D has no forced-exit mechanism on deactivation or otherwise —
`Strategy.md:510` and the pre-mortem's own router-activation-rule text both state existing positions run
to thesis outcomes regardless of router state, "which may be catastrophic in severe recessions"
(`Strategy.md:1322`, reproduced verbatim in the pre-mortem's own Section 2 scenario 1); (iii) the current
regime score is `shock_overlay=acute`, `growth_momentum=decelerating`, `policy_stance=hawkish` — not a
benign backdrop; (iv) D is live with 9 names / 12 tranches right now. Fixing this defect means either
building a real conviction-vs-outcome indicator (a genuinely new, currently-absent early-warning signal
for exactly the failure mode this cycle is about — a bias-inflated high-conviction thesis being
oversized) or, at minimum, honestly stating the detection gap so a future monitoring-design pass (or a
human) doesn't skip building one believing it already exists. Either path changes what a downstream
reader or routine (SL2's redraft process, D3's monthly review, the operator) will do differently. That
satisfies rev-15's requirement that answer (a) "identif[y] what specifically would change in deployment
risk" — this is not "the document would be more rigorous."

**Cycle-5 soft cap** (Experiment_Parameters.md:497), now at cycle 6, one past the soft cap: *"what
specific deployment risk would another cycle bound that the current revision does not? If no such risk
is identifiable, the soft cap fires acceptance."* The risk is the one just named: an undetected
conviction-miscalibration blind spot on a strategy whose single-thesis blast radius just increased 5x and
which cannot force an exit if that blind spot lets a bad thesis run. That risk is identifiable, specific,
and not yet bound by rev 6 — **the soft cap does not fire acceptance; another cycle is justified.**
This is also consistent with the pattern already visible across this pre-mortem's history: every fix
surfaces a defect at the new fix surface (cycles 2-3-4's locus-recurrence pattern, explicitly documented
in the artifact's own rev-5 acceptance note) — rev 6's fix to W1-W4 introduced exactly one new
Tier-1-shaped defect in the new "partially offsetting" paragraph it had to add to re-derive the
crosswalk. That is a normal, bounded revision-induced defect, not evidence of unbounded churn: it is one
item, at the fix surface rev 6 itself created, not a recurrence of the old items.

## Independent verification performed

- Read the full Strategy D pre-mortem section (`strategy/08_pre_mortems.md` lines 657-856) directly,
  before forming grades, and grepped it for "conviction," "2%," "2.28," "2.29," "2.30," "2.31,"
  "memory-mediated," "goal drift," "inaction" to test specific claims.
- Read `AI_Trading_Foundation.md` sections on 2.13, 2.14, 2.15, 2.17, 2.18, 2.28, 2.29, 2.30, 2.31 and
  the §5.4 magnitude table, and grepped for "A2 2026," "A1 2026 annual sweep," "STRENGTHENED," "flat" to
  independently trace the residual paragraph's citation.
- Read the cycle-5 orchestrator output (`Adversarial_Review_premortem-D-2026-a3_orchestrator.md`,
  2026-07-30) in full and cross-checked its four Tier 1 findings and its KL16 recommendation against
  rev 6's actual text.
- Read Strategy E's parallel rev-6 section (`08_pre_mortems.md` lines 857-1050+) to compare its 2.28
  treatment and two-layer-control language against D's.
- BigQuery: `state.current_positions` (D's 12 open tranches), `state.open_positions_summary` (market
  values), `events.cash_flows` (D's two deposits, and the load-bearing "1999.08 + 499.77 = 2498.85" note
  that fixed my initial wrong denominator), `state.capital_allocation_calls` (the 2026-07-19 regime-
  capital-sweep context), `events.decision_log` (the SL2 2026-07-30 SISA-contamination entry, D's
  2026-08-03 through 2026-08-05 thesis-construction entries, the GEV STAGED-BUT-HALTED and criterion-2
  inconsistency notes).
- Reproduced arithmetic myself: Section 4/8's five-item enumeration, the confluence-list count (6 vs. 5,
  reversed in the summary sentence), and per-name CaR concentration against the corrected $2,498.85
  denominator (GEV highest at ~5.07%, no current breach).
- Did NOT verify: whether SL2's rev-6 authoring process for D was itself influenced by any 2.28-style
  cross-session anchoring (i.e., I flagged the 2.28/2.31 omission as a documentation gap in the artifact,
  but did not and could not test whether the omission itself is evidence of the very bias 2.28
  describes — that would require information about SL2's actual session history I don't have access to).

## Action

Cycle 6 does not accept rev 6. Recommend a cycle-7 SL2 redraft targeting: (1) either build a real
Section 4/6 conviction-tier-vs-outcome indicator or remove/reword the false "consumed by Section 4"
claim; (2) state the CaR-envelope computation's enforcement method explicitly (Tier 2, should-fix); (3)
fix the A2-2026-vs-A1-2026 sweep mislabel (Tier 3, low cost); (4) fix the five-of-eleven/six-of-eleven
count inversion (Tier 2, trivial); (5) consider whether 2.28 and/or 2.31 belong in Section 5 given the
cross-strategy comparison in (c)2 above — this is newly surfaced this cycle and not part of the original
attacker/cycle-5 scope, so it is offered as a should-consider, not a blocking item for cycle 7 unless the
next attacker independently reaches the same conclusion. Per the theater-check (MIXED), this action is a
pre-mortem-review action, not a divergence-review action, so it is not itself subject to the Step 3.5
theater-independence gate — that gate applies to divergence-review's binding activation-state decision,
not to this review type's revision-required verdict.
