# Adversarial Review — otr-A-marketcap-floor-2026 (orchestrator)

- **id:** otr-A-marketcap-floor-2026
- **review_type:** out-of-table-resolution
- **strategy:** A
- **date:** 2026-07-30
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md (lines 263–276, 509–525, 940–989), cross-checked against
  Annual_Constraint_Audit.md (lines 73–92, 426–517, 595–603), strategy/03_strategy_a.md (lines 15–20),
  strategy/08_pre_mortems.md (lines 216–329, market-cap grep over the whole file)
- **attacker_output:** Adversarial_Review_otr-A-marketcap-floor-2026_attacker.md

## Final verdict
HOLD — the $2B market-cap floor (C-A-04) stays at its current value; the rationale annotation is left
as-is pending a future actual re-derivation, which this pass is not licensed to perform.

## Theater-check flag
CONVERGENT — but substantively so, not a rubber stamp. I independently re-pulled every anchor the
attacker cited and confirmed each is verbatim (Annual_AI_Foundation_Sweep.md:971, :969, :273, :525),
and I went further than the attacker's self-declared scope by reading the three documents it explicitly
said it did **not** read (Annual_Constraint_Audit.md, strategy/03_strategy_a.md,
strategy/08_pre_mortems.md). All three corroborate the attacker's read rather than contradict it (detail
in (c)). Agreement here is convergent on the object-level conclusion but not on method: the attacker
reasoned from the artifact and trigger_context alone; I reasoned from those plus the primary constraint
ledger and the strategy's own mechanism text, and landed in the same place because the underlying facts
are genuinely one-sided, not because I deferred to the attacker.

## (a) Validity assessment of each attacker finding

**F1 — artifact poses but does not answer the route-(a) re-derivation.**
Supports HOLD; valid. Anchor at Annual_AI_Foundation_Sweep.md:971 is verbatim. I additionally grepped
strategy/03_strategy_a.md (the actual constraint text, `03:18`, which the attacker did not read under
its blind) for "borrow", "index membership", "catalyst-coverage", "spread", "bid-ask" — zero matches —
and grepped strategy/08_pre_mortems.md for "market cap" across the *entire file* — only two hits, one
in Strategy B's entry-criteria restatement (line 329, distinguishable by "Long or short") and one in
Strategy D's (line 665, a $10B floor with its own stated rationale, "business-risk drift in smaller
names" — not 2.3). Neither is in A's own pre-mortem section (lines 216–~328). So the "zero matches"
claim in Annual_AI_Foundation_Sweep.md:969 is not just self-reported by the sweep — it is independently
reproducible from the primary source documents. Route (a) fails on the strongest evidence available.

**F2 — A2 terminated before reaching re-derivation.**
Supports HOLD; valid. Annual_Constraint_Audit.md:20 states A2 hit the predicted normal case (zero
Tier-2 disadvantages classified as reduced, so all constraints terminate at Step 1); line 517 states
explicitly "Per-constraint flags: ZERO... A3 must not enqueue out-of-table-resolution reviews for
[Step-1-terminated constraints]" — yet this very review exists, which is consistent with the trigger
context's account (A3 enqueuing on the *citation-mismatch* branch A2's per-constraint flags don't cover,
not on a per-constraint out-of-table flag from A2 itself). C-A-04 appears in the strategy-A constraint
table (Annual_Constraint_Audit.md:83) with primary citation 2.3 and no secondary, consistent with the
"N-T2, no relaxation" disposition trigger_context describes. This is a genuine confirmation the attacker
could not perform under its blind (it explicitly listed Annual_Constraint_Audit.md as unread).

**F3 — route (b) also requires manufacturing a replacement rationale.**
Supports HOLD; valid. The resolves_when clause (BigQuery payload) offers "a decision that its stated
2.3 rationale should be corrected while the value itself holds" as an alternate resolving path, but
"corrected" to what is exactly the unanswered part of route (a). There is no candidate replacement
rationale anywhere in the read set or in the documents I additionally checked. Manufacturing one here
would be the review inventing content, which the review_type's own scope rule forbids
("if resolving would require you to invent, choose, or derive replacement wording/rationale, that is
out of scope for this pass → HOLD").

**F4 — the reversal itself is unverified for Claude / single-source.**
Supports HOLD; valid but auxiliary. This finding does not independently drive HOLD (F1–F3 already do
that on scope grounds) — it reinforces the case for *not* rushing an ad hoc resolution even if one were
tempted to, by noting the underlying L4 finding fails §5.5 guardrail 1 (replication) per
Annual_AI_Foundation_Sweep.md:273. Correct as far as it goes; not itself dispositive.

**F5 — the artifact's own precedent (2.17) treats contradiction as a flag, not a resolution.**
Supports HOLD; valid. Annual_AI_Foundation_Sweep.md:525 ("Do not read a contradicted disadvantage as a
reduced disadvantage... a question for A2/A3, not a §5.6 relaxation lookup") is verbatim and the
trigger_context's paraphrase is accurate. Consistent internal precedent, correctly cited.

## (b) Theater in the attacker's output
None found. Every anchor quoted was checked against source and is verbatim (no misquotes, no
non-existent lines). The attacker's self-imposed scope confirmation is honest and specific (it names
which line ranges it read and which documents it declined to read) rather than a vague "I reviewed the
relevant materials." Its reasoning does not recycle a generic objection — it engages the artifact's own
two-branch fork (re-annotate vs. out-of-table-flag) on its own terms and shows why neither branch is
completable from what's on the table. I looked for padding (restating the same point under multiple
headings without adding anchor-level content) and did not find it — F1–F3 are the substantive chain,
F4–F5 are genuinely auxiliary corroboration rather than filler dressed as findings.

## (c) Weaknesses the attacker missed
None material to the verdict. The de-blinded view adds corroboration rather than new problems:
- Direct confirmation from strategy/03_strategy_a.md that the $2B floor's only stated rationale, in the
  actual constraint text (not just the sweep's summary of it), is the 2.3 citation — no other criterion
  in the instrument-eligibility list (US-listed, ADV, long-only) even gestures at spread/borrow/index
  membership/catalyst coverage as a rationale for the *market-cap* line specifically.
- Confirmation from Annual_Constraint_Audit.md that C-A-04's audit trail is genuinely inert this cycle
  (Step 1 termination, zero relaxations, zero per-constraint out-of-table flags issued by A2 itself) —
  there is no orphaned A2 output this review should have picked up instead of proceeding on
  trigger_context alone.
- Cross-strategy context (Strategy D's $10B floor citing a wholly different rationale, "business-risk
  drift," not 2.3) rules out an implicit shared-rationale reading under which A's floor might borrow
  D's or B's justification. Each strategy's cap floor is independently grounded, and A's is
  singly-grounded in the one item that reversed.
None of this changes the outcome; it closes off the paths that might have produced a different one.

## (d) Verdict reasoning
The review_type's default is HOLD unless the objective, already-present criteria in trigger_context's
`resolves_when` clause clearly resolve the flag. `resolves_when` gives exactly two resolving conditions:
(1) an affirmative re-derivation of the $2B floor on other grounds, or (2) a decision to correct the
stated rationale while holding the value. Neither is objectively present:
- (1) is checked and fails: I independently verified — beyond the artifact's own self-report and beyond
  what the attacker could check under its blind — that no alternate ground for the market-cap floor
  appears anywhere in Strategy A's mechanism doc or pre-mortem. This is not an absence-of-search
  problem; the primary documents that would carry such a rationale if it existed simply do not contain
  it.
- (2) is not executable as an objective lookup: naming *what* the corrected rationale should be is
  precisely the re-derivation that (1) already failed to supply. Choosing to write "liquidity" or
  "index membership" into the annotation without an evidentiary basis would be this review manufacturing
  content, which is explicitly out of scope for a non-adversarial out-of-table-resolution pass.
With both resolving paths objectively unavailable, the conservative default controls: HOLD.

**Explicit non-relaxation statement:** this HOLD is not a finding against the $2B floor and does not
license loosening, removing, or reducing it. The floor's stated rationale (2.3's market-cap direction)
is contradicted at a single L4 source with no Claude replication (§5.5 guardrail 1 fails per
Annual_AI_Foundation_Sweep.md:273), which makes the constraint's citation potentially unmotivated, not
over-tight (Annual_AI_Foundation_Sweep.md:525, :971). Unmotivated is a call for re-derivation, not a
license to act. The constraint remains in force at $2B unchanged.

## (e) Action taken
Verdict HOLD is recorded for this queue entry. AR_orc takes no further editorial action: the $2B
floor (C-A-04) and its existing rationale annotation in strategy/03_strategy_a.md are left untouched;
no `Strategy.md` revision bump is triggered by this review; the open question (whether the floor
survives on liquidity/spread/borrow/index-membership/catalyst-coverage grounds) remains genuinely open
and is not resolved here, consistent with F1–F3. The orchestrating session (not this file) is
responsible for writing the HOLD disposition to `events.decision_log` / closing the
`PENDING_REVIEW` row for `otr-A-marketcap-floor-2026` in BigQuery — no BigQuery write or git operation
is performed as part of producing this file.
