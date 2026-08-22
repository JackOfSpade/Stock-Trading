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

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")
ROUTINE_HEADING = re.compile(r"^##\s+([A-Za-z0-9_]+)\.\s")


def routine_sections(text: str) -> dict[str, str]:
    """Return executable routine sections, excluding adjacent groups and fenced examples.

    A routine ends at either its next routine heading or the next top-level cadence
    group heading.  The latter matters for the final routine in a group (notably
    W5): otherwise text introducing MONTHLY/ADVERSARIAL work becomes accidental
    W5 scope.  The plan embeds Markdown/SQL samples, so fence-mask the same way
    ``split_task_plan.py`` does before treating a heading-shaped line as structure.
    """
    lines = text.splitlines(keepends=True)
    in_fence = fence_mask(lines)
    starts: list[tuple[int, str]] = []
    group_starts: list[int] = []
    for index, (line, fenced) in enumerate(zip(lines, in_fence, strict=True)):
        if fenced:
            continue
        match = ROUTINE_HEADING.match(line)
        if match:
            starts.append((index, match.group(1)))
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


def _has_any(text: str, patterns: tuple[str, ...]) -> bool:
    return any(re.search(pattern, text, re.IGNORECASE) for pattern in patterns)


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
            errors = check(file.read())
    except OSError as exc:
        print(f"ROUTINE SCOPE: FAIL — cannot read {PLAN}: {exc}")
        return 1

    if errors:
        print("ROUTINE SCOPE: FAIL")
        for error in errors:
            print(f"  - {error}")
        return 1
    print("ROUTINE SCOPE: OK — daily/weekly ownership boundaries hold")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
