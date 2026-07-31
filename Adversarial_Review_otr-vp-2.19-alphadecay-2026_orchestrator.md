# Adversarial Review — otr-vp-2.19-alphadecay-2026 (orchestrator)

- **id:** otr-vp-2.19-alphadecay-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-30
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md (§2.19, lines 546–567, 866, 890, 896, 927–938) + AI_Trading_Foundation.md (§2.19, lines 353–363) — de-blinded read
- **attacker_output:** Adversarial_Review_otr-vp-2.19-alphadecay-2026_attacker.md

## Final verdict
**HOLD** — the version-pending flag on 2.19's magnitude stays open; the queue entry is not resolved this cycle.

## Theater-check flag
**DIVERGENT** — the attacker verdicted RESOLVE on the strength of finding F3 (the re-expression text already
exists verbatim in the sweep artifact, line 866). That anchor checks out completely. But `AI_Trading_Foundation.md`
line 357 — a file the attacker's self-disclosed scope note says it never opened — states in so many words: *"It
remains VERSION-PENDING and is NOT resolved by the re-expression below... A3 has no authority to clear an item
off that list by finding an adjacent number it likes... the remedy is a source stating alpha decay in the units
the item claims, or an explicit, **adjudicated** re-expression."* That is a direct, on-point pre-emption of
exactly the argument the attacker built its RESOLVE verdict on. This is not attacker sloppiness — the attacker
reasoned candidly and disclosed the gap itself — but it is a real, material miss that only de-blinding could catch,
which is exactly the value-add this role exists to provide.

## (a) Validity assessment of each attacker finding

### F1 — Decay is CONFIRMED and LARGER
Anchors verified: line 551 ("Sharpe Ratio decay ranges from 51.48%... to 62.23%", "Total Return decay ranges from
50.18%... to 71.85%"), line 562 ("confirmed and larger"), line 560 (CROSS-LEVEL VERDICT: CONVERGENT). All quotes
check out exactly as cited. **Valid, but not determinative** — this establishes the phenomenon's direction and
severity, which is not in dispute; it says nothing about whether the resolves_when criterion for *this specific
citation defect* is met.

### F2 — The defect is units/citation, not substance
Anchors verified: line 561 ("Units problem..."), line 563 (`ABSENCE-FROM-RECENT-RESEARCH [all levels]` tag with
"as stated (units mismatch)" qualifier). Accurate characterization of what A1 found. **Valid, but not
determinative** — correctly describes the problem; does not itself establish resolution.

### F3 — The evidence's own units are already drafted into a re-expression, in-artifact, verbatim
Anchor verified: line 866 does contain the quoted re-expression text verbatim, and it is genuinely one of the 26
listed UPDATE actions (line 1066). The attacker is factually correct that this text exists and required no
composition by the reviewer. **Invalid as to its use to support RESOLVE.** The reason is not that the anchor is
wrong — it is that a second, dispositive anchor the attacker did not have access to (`AI_Trading_Foundation.md`
line 357, see §(c) below) states explicitly that this exact re-expression, even though A3 has *already applied it
verbatim to the live foundation document* (line 359: "Sharpe decay of 51–62% and total-return decay of 50–72%...")
is declared **insufficient to clear the flag**, and that clearing it requires an "adjudicated" act — i.e.
discretion — which the task's own governing rule for this review type puts out of scope for a default-HOLD pass.
F3's factual anchor is sound; the inference drawn from it is not.

### F4 — Scaling Paradox sub-claim removal is separate
Anchors verified: lines 555–559 (contradicting evidence), line 931 (removal text), consistent with the attacker's
own framing that this is non-determinative for the resolve/hold call. **Valid, not determinative**, and correctly
scoped by the attacker as orthogonal.

## (b) Theater in the attacker's output
None of the theater smells (generic objections, recycled framings, misquoted or absent anchors, padding) are
present. Every anchor cited by the attacker was checked against the source lines and held exactly as quoted; the
attacker even pre-empted the discretion objection in its own "Objective-criteria assessment" section ("the concern
to guard against was that restating the claim in different units could be a discretionary editorial act... That
concern does not apply here") — a genuine, non-theatrical engagement with the hardest part of the question, argued
in good faith to the limit of what its blind allowed. It also explicitly and honestly disclosed, in its
self-imposed scope confirmation, that it did not read `AI_Trading_Foundation.md`. That disclosure is precisely
what let this pass catch the miss — the opposite of theater. I do not fully agree with the attacker (see verdict),
so this is not convergent rubber-stamping; where I agree (F1, F2, F4) it is because those anchors independently
check out on their own terms, not because I am deferring to the attacker's overall conclusion.

## (c) Weaknesses the attacker missed
The decisive one: `AI_Trading_Foundation.md` lines 355–357 (the live §2.19 blockquote, already downstream of A3's
application of this exact sweep) reads in full:

> "A1's per-item fade review (§C.3) additionally flags the original '15 percentage points' alpha-decay figure as
> untraceable in its stated units. **It remains VERSION-PENDING and is NOT resolved by the re-expression below.**
> The re-expressed Sharpe/total-return decay is better-sourced and points the same way — more severe, not less —
> but it is a *different measurement in different units*, so substituting it does not replicate the withdrawn
> claim; A1 placed 2.19 in the §C.3 version-pending list and A3 has no authority to clear an item off that list by
> finding an adjacent number it likes. Adjudication is enqueued as `out-of-table-resolution` review
> `otr-vp-2.19-alphadecay-2026`, **conservative default HOLD**; the item stays version-pending until an affirmative
> RESOLVE verdict lands... the remedy is a source stating alpha decay in the units the item claims, or an explicit,
> **adjudicated** re-expression of the claim into the units the evidence actually reports."

Two things follow that the attacker, working from the sweep document alone, had no way to see:

1. **The re-expression is already live**, not merely proposed. Line 359 of the foundation document already reads
   "Sharpe decay of 51–62% and total-return decay of 50–72%..." — A3 has already done everything the attacker
   thought would resolve the flag, and the flag is *still* explicitly open. This is stronger evidence against
   RESOLVE than a merely-proposed re-expression would have been: it shows the artifact ecosystem's own author (A1,
   in the very blockquote A3 carried forward) anticipated and rejected exactly the move the attacker made.
2. **The named remedy requires "adjudication,"** not mere transcription-checking. That word choice is load-bearing:
   it is the artifact's own signal that clearing this flag is a discretionary/analytical act (a judgment about
   whether a differently-scaled substitute magnitude is an adequate stand-in for a withdrawn, untraceable one) —
   which is exactly the category of act the task instructions say this review type is not licensed to perform
   ("If resolving would require you to invent, choose, or derive replacement wording/rationale, that is out of
   scope for this pass → HOLD").

Also worth noting but non-determinative: `Annual_AI_Foundation_Sweep.md` line 896 independently describes the same
posture from A1's side ("items stay VERSION-PENDING until an affirmative RESOLVE verdict lands, and are
re-surfaced each review cycle") — consistent with, and reinforcing, the foundation document's explicit denial.

## (d) Verdict reasoning
This is a non-adversarial, out-of-table-resolution triage. Default is HOLD; RESOLVE requires the resolving fact to
be objectively already present, not something this pass must construct through discretion.

The attacker's Route 2 argument (an "explicit re-expression... already exists, so no discretion is needed") is
the right test applied to an incomplete record. Once the record is completed with `AI_Trading_Foundation.md` §2.19
— a supporting spec document this orchestrator is licensed to read and the attacker was blinded from — the
resolving fact runs the other way: the artifact ecosystem's own governing text explicitly states (a) the
re-expression, even fully applied to the live document, does **not** resolve the flag, and (b) resolution
requires "adjudication," i.e., discretion. Under the task's own bar, a defect whose stated remedy is an act of
discretion is precisely what must default to HOLD. There is no live, undischarged ambiguity to resolve in the
attacker's favor here — the artifact has already, affirmatively, told this review what it may not do (treat the
existing re-expression as self-resolving) and what would be required instead (an adjudicated judgment call, which
this narrow triage pass is not the vehicle for).

Non-relaxation / non-reversion statement: this HOLD does not disturb anything already applied to the live
foundation document. The re-expressed Sharpe/total-return figures at `AI_Trading_Foundation.md` line 359 stay in
place exactly as A3 wrote them (they are well-sourced and, if anything, more severe than the original claim) and
the Scaling Paradox removal (line 361) is unaffected — neither of those is what this queue entry gates. HOLD means
only that the `VERSION-PENDING REPLICATION` / untraceable-"15pp" marker at lines 355–357 stays in force; it is not
a finding that the underlying disadvantage is weaker, and it does not license quietly treating the new numbers as
though they had cleared the flag.

## (e) Action taken
AR_orc records verdict **HOLD** for `otr-vp-2.19-alphadecay-2026`. No state change to `AI_Trading_Foundation.md`
§2.19 is warranted or performed by this review — its VERSION-PENDING marker (lines 355–357) stays exactly as
written, correctly anticipating this outcome. This orchestrator file is the only artifact produced; the
orchestrating session is responsible for writing the corresponding `events.decision_log` / `queue_events` state
transition (HOLD, re-surface next cycle) and for closing the pending `PENDING_REVIEW` row. No BigQuery write and
no git operation was performed by this review.
