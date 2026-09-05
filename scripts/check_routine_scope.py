#!/usr/bin/env python3
"""Guard daily/weekly routine ownership boundaries in Claude_Task_Plan.md.

The routine plan is executable instruction text, not merely documentation.  D1 owns
daily market discovery (including its Sunday Friday/Saturday catch-up) and mechanical
exits; weekly routines add slower-horizon research or report/consolidate prior results.
Without a small machine-check, a future edit can quietly restore an expensive weekly duplicate of a
daily scan or a second order-staging path.

This check intentionally uses a handful of concept-level phrases rather than trying
to parse natural language.  Each required concept has alternatives so ordinary prose
edits remain possible; every routine section is isolated before scanning, preventing
shared preamble examples from satisfying (or tripping) a routine's rule.

Usage: python scripts/check_routine_scope.py
"""
from __future__ import annotations

import os
import re

from lib.md_fence import fence_mask
from lib.routine_manifest import HEADING_ID_PREFIX, ROUTINE_SUFFIX

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")


def routine_sections(text: str) -> dict[str, str]:
    """Return executable routine sections, excluding adjacent groups and fenced examples.

    A routine ends at either its next routine heading or the next top-level cadence
    group heading.  The latter matters for the final routine in a group (notably
    W5): otherwise text introducing MONTHLY/ADVERSARIAL work becomes accidental
    W5 scope.  The plan embeds Markdown/SQL samples, so fence-mask the same way
    ``split_task_plan.py`` does before treating a heading-shaped line as structure.

    HEADING TEST (finding routine-scope-duplicate-heading-detector). This used to accept ANY
    "## <token>. " line as a routine boundary, via a private ``ROUTINE_HEADING = re.compile(r"^##\\s+
    ([A-Za-z0-9_]+)\\.\\s")`` -- a second, independently maintained heading test with no requirement
    that the heading actually be a coded routine's. The canonical detector (this file's own
    scripts/split_task_plan.py, via scripts/lib/routine_manifest.py's ROUTINE_SUFFIX) additionally
    requires the heading END with its "— (deep research|regular routine)" type tag before it counts.
    Without that, a heading-SHAPED line inside some OTHER routine's own body -- a numbered aside like
    "## 3. See the note below" -- satisfied the old test and was misread as a NEW routine boundary,
    truncating the real routine's section right there and reassigning everything after it to a bogus
    id no _check_present/_check_absent rule names: whatever forbidden- or required-pattern text
    landed after the accidental heading silently dropped out of every ownership-boundary rule's view,
    with no error reported (see tests/test_check_routine_scope.py). HEADING_ID_PREFIX and ROUTINE_SUFFIX are
    now imported from lib.routine_manifest -- the same regex OBJECTS scripts/split_task_plan.py's own
    is_routine() checks -- rather than re-typed here, so this heading test cannot quietly re-diverge
    from the canonical one the way the deleted ROUTINE_HEADING already had.

    This does NOT delegate the whole boundary-WALK to scripts/split_task_plan.split(): that function
    requires a `# ` cadence-group header before the first routine and raises ValueError otherwise,
    which is correct for the real, canonically-structured Claude_Task_Plan.md but would break every
    synthetic fixture in tests/test_check_routine_scope.py that exercises routine_sections() on a
    bare "## <ID>. ... — regular routine" heading with no preceding group header. The walking loop
    below already tolerates a missing group header (next_group defaults to len(lines)); only the
    per-line heading TEST needed tightening to close the actual defect, so that is the only piece
    changed -- the two files' heading tests are now the SAME imported primitives even though the
    surrounding boundary-walk stays a second, narrower loop.
    """
    lines = text.splitlines(keepends=True)
    in_fence = fence_mask(lines)
    starts: list[tuple[int, str]] = []
    group_starts: list[int] = []
    for index, (line, fenced) in enumerate(zip(lines, in_fence, strict=True)):
        if fenced:
            continue
        if line.startswith("## "):
            title = line[3:].strip()
            id_match = HEADING_ID_PREFIX.match(title)
            if id_match and ROUTINE_SUFFIX.search(title):
                starts.append((index, id_match.group(1)))
        elif line.startswith("# "):
            group_starts.append(index)

    sections: dict[str, str] = {}
    for index, (start, routine) in enumerate(starts):
        next_routine = starts[index + 1][0] if index + 1 < len(starts) else len(lines)
        next_group = next((group for group in group_starts if group > start), len(lines))
        end = min(next_routine, next_group)
        # The routine prompts themselves are fenced, so retain fenced BODY text;
        # fence masking above is structural only (a heading-shaped example must not
        # split the section into a fictitious sibling routine).
        sections[routine] = "".join(lines[start:end])
    return sections


def _has_all(text: str, patterns: tuple[str, ...]) -> bool:
    return all(re.search(pattern, text, re.IGNORECASE) for pattern in patterns)


# (A symmetric `_has_any()` used to sit here beside _has_all().  It was dead from birth -- introduced
# by 60f338e, the commit that created this guard, and never called by any rule, test or prose in the
# repo -- so it was removed in the 2026-09-04 quality pass.  The three checkers that could plausibly
# have wanted any-of semantics all use something else: _check_present -> _has_all, _check_absent ->
# _has_active_match, and _has_active_match -> its own finditer walk.  If a future ownership rule
# genuinely needs any-of, reintroduce it NEXT TO that rule's call site, where the requirement is
# visible.)


# A negation governs the rest of its clause, but a CONTRASTIVE conjunction ends that scope: in
# "W4 does not skip validation, but calls create_order_instruction", the "but" starts a new,
# affirmative clause that the earlier "does not" does not reach (quality pass 2026-08-22).
_CONTRAST = re.compile(r"\b(?:but|however|instead|whereas|although|though|yet)\b", re.IGNORECASE)
_NEGATED = re.compile(r"\b(?:do(?:es)?\s+not|must\s+not|never|without)\b", re.IGNORECASE)


def _has_active_match(text: str, patterns: tuple[str, ...]) -> bool:
    """Whether a forbidden action appears outside an explicit prohibition.

    The plan must say what a weekly routine *does not* do.  Treating that safety
    sentence as a violation would force authors to omit the boundary entirely.
    Scope the negation to the same physical line so a distant historical "never"
    cannot hide a later active instruction.

    WITHIN the line, the negation's scope ends at the last CONTRASTIVE conjunction before the
    match (quality pass 2026-08-22).  Scoping to the whole line prefix was too generous: any
    unrelated earlier negation on the same physical line silently masked a real violation later in
    it.  Verified: a W4 section reading "W4 does not skip validation, but calls
    create_order_instruction directly for a fast-track exit" produced NO error, even though the
    literal forbidden action is present and active — the exact anti-pattern the W4 _check_absent
    rule exists to catch.

    Splitting on every comma/semicolon instead was measured and REJECTED: it breaks the coordinated
    list, which is the plan's normal way of writing a prohibition.  W5 really says "…but do not
    diagnose a live discrepancy, raise an operational drift alert, or attempt a repair", where one
    "do not" governs all three items; comma-scoping cut the governing "do not" off the second and
    third and turned a correct safety sentence into a CI failure on live main.  A contrastive
    conjunction is the thing that actually ends a negation's reach, so that is what is split on.
    """
    for pattern in patterns:
        for match in re.finditer(pattern, text, re.IGNORECASE):
            line_start = text.rfind("\n", 0, match.start()) + 1
            prefix = text[line_start:match.start()]
            contrasts = [c.end() for c in _CONTRAST.finditer(prefix)]
            if contrasts:
                prefix = prefix[contrasts[-1]:]
            if not _NEGATED.search(prefix):
                return True
    return False


def _check_present(sections: dict[str, str], routine: str, description: str,
                   patterns: tuple[str, ...], errors: list[str]) -> None:
    body = sections.get(routine)
    if body is None:
        errors.append(f"{routine}: routine section missing from {os.path.basename(PLAN)}")
    elif not _has_all(body, patterns):
        errors.append(f"{routine}: missing ownership boundary — {description}")


def _check_absent(sections: dict[str, str], routine: str, description: str,
                  patterns: tuple[str, ...], errors: list[str]) -> None:
    body = sections.get(routine)
    if body is None:
        errors.append(f"{routine}: routine section missing from {os.path.basename(PLAN)}")
    elif _has_active_match(body, patterns):
        errors.append(f"{routine}: forbidden overlap reappeared — {description}")


# --------------------------------------------------------------------------
# PRE-MORTEM OWNER <-> CONSUMING-STEP COUPLING (added 2026-09-01, closing ops.alerts
# premortem_live_gate_defect 6c670d35-c44a-416d-b3e6-73209e66fc3f, AR_orc on
# premortem-C-2026-a3 cycle 17).
#
# strategy/08_pre_mortems.md assigns its review triggers by writing "Owner: <ROUTINE>" into the
# trigger's own text.  Nothing ever checked that the named routine had a step which reads the file.
# For six weeks it did not: seven live loci sat on M4, whose 66-line body contained no mention of
# pre-mortems, Section 6 or any Known Limitation, so every one of them was a trigger that could not
# fire while the document read as though each were owned.  The plan's SL2 section already PINS the
# rule in prose ("AN OUT-OF-SECTION ESCALATION MUST NAME A VERIFIED CONSUMER, NEVER AN ASSUMED
# ONE", 2026-08-27) and the shared OUT-OF-SCOPE FINDINGS rule generalizes it -- and rev 17 reused
# exactly the evidence that pin disqualifies (a slice-map row granting READ access "for reviews")
# three days after it was pinned.  This is that pin made mechanical, in BOTH directions: an
# assignment with no consuming step fails, and deleting a consuming step while assignments remain
# also fails.
#
# The marker is a fixed phrase, not a filename match, on purpose: the plan names 08_pre_mortems.md
# in read-scope lines, slice-map rows and A1's context-budget note, none of which is an executed
# step -- and mistaking one of those for a step is the precise error being guarded.
#
# The owner pattern is deliberately tight.  It is CASE-SENSITIVE on "Owner:" and requires the
# captured token to have routine SHAPE (1-4 capitals then a digit then an optional lowercase
# letter, or AR_att / AR_orc).  A loose [A-Z]\w* would capture a filename out of an
# "OWNER: <surface>" escalation line and fail the build on prose.  "Owner: the participant" does
# not match (lowercase), and must not -- a human owner is what the 2026-07-10 SISA directive
# removed from this loop.
PREMORTEM = os.path.join(ROOT, "strategy", "08_pre_mortems.md")
PREMORTEM_OWNER = re.compile(r"Owner:\s*\*{0,2}((?:AR_(?:att|orc))|(?:[A-Z]{1,4}[0-9][a-z]?))\b")
WALK_MARKER = "PRE-MORTEM OWNER-ASSIGNED CHECK WALK"
# AR_att / AR_orc read the artifact under review by queue contract (artifact_path), and their
# headings carry no "<id>." prefix so routine_sections() cannot produce them.  Their consumption of
# this file is structural rather than prose-declared, so an Owner: naming them is satisfied by
# construction.
CONTRACTUAL_OWNERS = frozenset({"AR_att", "AR_orc"})


def premortem_owner_routines(premortem_text: str) -> set[str]:
    """Routine ids named as ``Owner:`` anywhere in the pre-mortem slice.

    Deliberately over-broad WITHIN routine-shaped tokens: it also matches the non-assigning
    revision-note mentions and the explains-why-unowned mention at Known Limitation 9.  Over-
    matching can only demand a consuming step that already exists; under-matching would let a real
    assignment through, which is the failure being fixed.
    """
    return {match.group(1) for match in PREMORTEM_OWNER.finditer(premortem_text)}


def check_premortem_consumers(plan_text: str, premortem_text: str) -> list[str]:
    """Return coupling errors between pre-mortem ``Owner:`` names and plan walk steps."""
    sections = routine_sections(plan_text)
    errors: list[str] = []
    owners = premortem_owner_routines(premortem_text) - CONTRACTUAL_OWNERS
    for routine in sorted(owners):
        body = sections.get(routine)
        if body is None:
            errors.append(
                f"{routine}: strategy/08_pre_mortems.md assigns `Owner: {routine}` but no such "
                f"routine section exists in {os.path.basename(PLAN)} -- an owner that cannot be "
                f"invoked is an unassigned locus wearing an owner's name")
        elif WALK_MARKER not in body:
            errors.append(
                f"{routine}: strategy/08_pre_mortems.md assigns `Owner: {routine}`, but its section "
                f"carries no '{WALK_MARKER}' step, so the trigger cannot fire. Fix: add the walk "
                f"step to {routine}. NOTE this matcher is deliberately over-broad and also matches "
                f"non-assigning revision-note prose, which survives an unassignment -- so removing "
                f"the live loci does NOT clear this error, and must not be attempted as the remedy. "
                f"Retiring the step entirely is a deliberate scope change: drop {routine} from the "
                f"coupling rule here, in the same commit, with the reason")
    for routine, body in sorted(sections.items()):
        if WALK_MARKER in body and routine not in owners:
            errors.append(
                f"{routine}: carries a '{WALK_MARKER}' step but strategy/08_pre_mortems.md assigns "
                f"it no `Owner: {routine}` locus -- restore the assignment or delete the step; a "
                f"walk over an empty scope writes a receipt that certifies nothing")
    return errors


def check(text: str) -> list[str]:
    """Return ownership-boundary errors for a plan body."""
    sections = routine_sections(text)
    errors: list[str] = []

    # D1 remains the daily source of the complete event screen and B routing.  This
    # makes the W2 reconciliation rule meaningful instead of allowing both routines
    # to degrade into an uncovered no-op.
    _check_present(
        sections, "D1", "daily regular-session screen and B-candidate routing",
        (r"regular-session daily bars", r"Strategy B", r"B candidate"), errors,
    )

    # W1 may maintain the long-horizon calendar, but discovery already made by D1
    # must be carried forward rather than researched a second time.
    _check_present(
        sections, "W1", "reuse of D1-originated catalysts",
        (r"(?:reuse|reuses|use|uses|start(?:ing)? from|carry forward)[^.\n]{0,220}(?:D1|Daily\.md|daily scan)",),
        errors,
    )

    # D1's Sunday dynamic scan owns the Friday/Saturday catch-up too.  W2 only
    # consumes D1's durable results, enriches/ranks them for B, and never runs a
    # second broad screen or a second significance call.
    _check_present(
        sections, "W2", "consumption of D1 durable research-screen records",
        (r"D1", r"events\.decision_log", r"research-screen"), errors,
    )
    _check_present(
        sections, "W2", "idempotent exclusion of already-identified events",
        (r"(?:event identity|event-id|event id)", r"(?:already|existing)",
         r"events\.queue_events", r"(?:decision|thesis)"), errors,
    )
    _check_present(
        sections, "W2", "distinct post-event-enrichment provenance record, not a significance screen",
        (r"(?:log|write)[^.\n]{0,300}(?:entry_type|decision row|decision record)", r"post-event-enrichment",
         r"(?:not|no)[^.\n]{0,100}(?:second )?significance screen"), errors,
    )
    _check_absent(
        sections, "W2", "market-wide post-event re-scan",
        (r"all US-listed equities", r"prior 10 trading days", r"market-wide (?:post-event )?scan",
         r"uncovered[- ]tail(?: scan)?", r"(?:scan|cover) (?:the )?(?:uncovered )?tail"), errors,
    )
    _check_absent(
        sections, "W2", "direct price-bar pull or second AI-significance judgment",
        (r"get_price_history", r"AI-SIGNIFICANCE SCREEN", r"Layer-1 population rail", r"Layer-2 \(the decider\)"), errors,
    )

    # W3 still owns cumulative/narrative thesis research, but D1 must remain the
    # sole owner of mechanical convergence and time exits.
    _check_present(
        sections, "W3", "D1 ownership of mechanical convergence/time exits",
        (r"D1", r"(?:convergence|time-based|time exit|mechanical).{0,100}(?:exit|exits)"), errors,
    )
    _check_present(
        sections, "W3", "weekly narrative/cumulative research scope",
        (r"(?:narrative drift|cumulative evidence|competitive landscape|fundamental developments)",), errors,
    )

    # W4's weekly findings enter the existing D2 queue path.  It must not revive a
    # parallel direct order-crafting/staging route.
    _check_present(
        sections, "W4", "idempotent PENDING_ANALYSIS handoff to D2",
        (r"PENDING_ANALYSIS", r"D2", r"(?:idempotent|duplicate|already)[^.\n]{0,180}(?:queue|queued|item_key)"), errors,
    )
    _check_absent(
        sections, "W4", "direct weekly exit crafting or ORDER_STAGED write",
        (r"create_order_instruction", r"ORDER_STAGED", r"craft the exit order"), errors,
    )

    # W5 reports trends/scorecards only.  Embedding catch-up and live account repair
    # belong to their daily owners and make this weekly run unexpectedly expensive.
    _check_present(
        sections, "W5", "trend-only account/analytics interpretation",
        (r"trend",), errors,
    )
    # The third pattern's trailing alternation is DOMAIN-QUALIFIED: a bare `drift` matched any
    # drift at all, including W5's own legitimate `sp_raise_alert('info','W5','decision_vocab_drift'
    # ...)` — decision-vocabulary drift is knowledge/analytics work, which is precisely W5's job,
    # not the "live account repair" this rule forbids. That over-match was inert only because
    # _has_active_match() used to let an unrelated negation earlier on the same physical line mask
    # it; tightening the negation scope (quality pass 2026-08-22) exposed it as a CI failure on
    # live main. `account` and `reconciliation` are unchanged, so any real account-repair
    # instruction — which names one of those — is still caught; only bare `drift` is narrowed to
    # the account senses the rule was written for.
    _check_absent(
        sections, "W5", "embedding catch-up or live account repair",
        (r"sp_embed_pending", r"get_account_(?:summary|positions|balances|orders|trades)",
         r"(?:repair|resolve|raise.{0,100}alert).{0,100}"
         r"(?:account|reconciliation|(?:broker|nav|position|operational)\s+drift)"), errors,
    )
    return errors


def main() -> int:
    try:
        with open(PLAN, encoding="utf-8") as file:
            plan_text = file.read()
    except OSError as exc:
        print(f"ROUTINE SCOPE: FAIL — cannot read {PLAN}: {exc}")
        return 1

    errors = check(plan_text)

    # Cross-file: every `Owner:` named in the pre-mortem slice must have a consuming step in the
    # plan.  Kept OUT of check() deliberately -- check() takes a plan body and nothing else, and
    # tests/test_check_routine_scope.py exercises it with synthetic plans that contain no M4
    # section; reading the real pre-mortem from inside check() would fail every one of them.
    try:
        with open(PREMORTEM, encoding="utf-8") as file:
            premortem_text = file.read()
    except OSError as exc:
        errors.append(
            f"strategy/08_pre_mortems.md unreadable ({exc}) — fail closed: the pre-mortem "
            f"owner <-> consuming-step coupling cannot be verified without it")
    else:
        errors.extend(check_premortem_consumers(plan_text, premortem_text))

    if errors:
        print("ROUTINE SCOPE: FAIL")
        for error in errors:
            print(f"  - {error}")
        return 1
    print("ROUTINE SCOPE: OK — daily/weekly ownership boundaries hold; "
          "every pre-mortem Owner: names a routine with a walk step")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
