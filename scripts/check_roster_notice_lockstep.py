#!/usr/bin/env python3
"""Assert the SISA roster-change NOTICE category list agrees in all four places that hold it.

WHY THIS EXISTS. ops/monitoring/alert_emailer.gs has carried this warning in a comment since
2026-08-04, with nothing enforcing it:

    Keep this list in lockstep with Rule 5's IN list in bigquery/134 and the ROSTER-CHANGE NOTICE
    contract in the Claude_Task_Plan.md preamble. A category in only one of the three places is inert.

"Inert" understates it, because the three places fail in three DIFFERENT and individually silent ways:

  * missing from alert_emailer.gs's ROSTER_NOTICE_CATEGORIES -> the notice still emails, but rendered
    as "⚠ ALERT" in the incident lane instead of the non-fault roster lane. The operator is told a
    healthy autonomous action is a fault.
  * missing from bigquery/134's Rule 5 IN list -> ops.sp_auto_resolve_alerts never closes it, so a
    notification-only row sits unresolved on the alert board forever, needing a manual UPDATE.
  * missing from the Claude_Task_Plan.md contract -> the routine that raises it has no spec to raise
    it against, so the payload keys the emailer renders may simply never be written.

2026-09-07 added a FOURTH copy — scripts/alert_relay.py's NO_PUSH_CATEGORIES, the ntfy suppression
list for the owner's "no pushes for things needing no action" directive — whose own failure mode is
the most dangerous of the four and the least visible: a category listed there is silently NEVER
PUSHED. A typo, or a future category added to the other three and copied here by reflex, would
suppress a real alert from the phone with no error, no log line and no red run anywhere. Adding an
unchecked fourth copy of a list that already had no checker was not acceptable, so this script was
written in the same change: the drift hazard the .gs comment describes is now smaller than it was
before that copy existed, not larger.

DELIBERATELY EXACT-SET, NOT SUBSET. All four lists must contain the SAME six categories — not "the
relay's list must be a subset of the emailer's". A subset rule would permit exactly the mistake that
matters most: adding a category to NO_PUSH_CATEGORIES alone silently takes it off the phone while
every other file still treats it as a normal alert. Suppression must be a whole-system decision made
in four places at once, or not made at all.

Exit 1 on any disagreement. Wired into ci.yml's `checks` job (blocking, no credentials needed) and
mirrored in auto-merge-claude.yml's post-merge coverage check, like its sibling consistency guards.
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Each source: (label, path, extractor). An extractor returns a set of category strings, or raises
# ValueError with a precise message if it cannot find its anchor. A FAILED EXTRACTION IS A FAILURE,
# never an empty set that compares equal to another empty set — the "both arrays empty makes every
# check pass vacuously" trap alert-relay.yml's own cron self-check calls out by name.


def _extract_py_tuple(text):
    """scripts/alert_relay.py — NO_PUSH_CATEGORIES = ( 'a', 'b', ... )"""
    m = re.search(r"NO_PUSH_CATEGORIES\s*=\s*\((.*?)\)", text, re.DOTALL)
    if not m:
        raise ValueError("could not find the NO_PUSH_CATEGORIES = (...) tuple")
    return set(re.findall(r"[\"']([a-z0-9_]+)[\"']", m.group(1)))


def _extract_gs_array(text):
    """ops/monitoring/alert_emailer.gs — const ROSTER_NOTICE_CATEGORIES = [ 'a', 'b', ... ];"""
    m = re.search(r"ROSTER_NOTICE_CATEGORIES\s*=\s*\[(.*?)\]", text, re.DOTALL)
    if not m:
        raise ValueError("could not find the ROSTER_NOTICE_CATEGORIES = [...] array")
    return set(re.findall(r"[\"']([a-z0-9_]+)[\"']", m.group(1)))


def _extract_sql_rule5(text):
    """bigquery/*.sql — Rule 5's `AND category IN ('a', 'b', ...)` over the roster notices.

    Anchored on the presence of the two categories that only ever appear in THIS list, rather than on
    "the first category IN (...)" — sp_auto_resolve_alerts contains several other category IN/= tests
    and matching the wrong one would compare an unrelated list and pass or fail for the wrong reason.
    """
    for m in re.finditer(r"category\s+IN\s*\(([^)]*)\)", text, re.IGNORECASE | re.DOTALL):
        cats = set(re.findall(r"'([a-z0-9_]+)'", m.group(1)))
        if {"strategy_shadow_registered", "roster_below_floor"} <= cats:
            return cats
    raise ValueError("could not find a `category IN (...)` list containing the roster-notice categories")


def _extract_task_plan(text):
    """Claude_Task_Plan.md — the ROSTER-CHANGE NOTICES preamble bullet's backticked category list."""
    i = text.find("ROSTER-CHANGE NOTICES")
    if i == -1:
        raise ValueError("could not find the 'ROSTER-CHANGE NOTICES' preamble bullet")
    m = re.search(r"These six categories\s*—(.*?)—\s*are raised", text[i:i + 4000], re.DOTALL)
    if not m:
        raise ValueError("found the ROSTER-CHANGE NOTICES bullet but not its 'These six categories — ... — are raised' list")
    return set(re.findall(r"`([a-z0-9_]+)`", m.group(1)))


def _sql_canonical_rule5():
    """The apply-in-order winner among bigquery/*.sql files defining ops.sp_auto_resolve_alerts.

    Resolved rather than hardcoded to bigquery/134: that procedure has been superseded repeatedly
    (34 -> 78 -> 94 -> 97 -> 107 -> 130 -> 134 -> 148 as of this writing), and pinning a file number
    here would silently start checking a stale definition the next time it moves.
    """
    bq = os.path.join(REPO, "bigquery")
    best = None
    for fn in os.listdir(bq):
        m = re.match(r"^(\d+)_.*\.sql$", fn)
        if not m:
            continue
        text = open(os.path.join(bq, fn), encoding="utf-8").read()
        if "PROCEDURE `stock-trading-498512.ops.sp_auto_resolve_alerts`" in text:
            n = int(m.group(1))
            if best is None or n > best[0]:
                best = (n, fn, text)
    if best is None:
        raise ValueError("no bigquery/*.sql file defines ops.sp_auto_resolve_alerts")
    return best[1], best[2]


def main():
    sql_name, sql_text = _sql_canonical_rule5()
    sources = [
        ("scripts/alert_relay.py (NO_PUSH_CATEGORIES — ntfy suppression)", "scripts/alert_relay.py", _extract_py_tuple, None),
        ("ops/monitoring/alert_emailer.gs (ROSTER_NOTICE_CATEGORIES — email render lane)", "ops/monitoring/alert_emailer.gs", _extract_gs_array, None),
        (f"bigquery/{sql_name} (sp_auto_resolve_alerts Rule 5 — auto-resolve)", f"bigquery/{sql_name}", _extract_sql_rule5, sql_text),
        ("Claude_Task_Plan.md (ROSTER-CHANGE NOTICE contract — the spec)", "Claude_Task_Plan.md", _extract_task_plan, None),
    ]

    found = {}
    failures = []
    for label, rel, fn, pretext in sources:
        text = pretext if pretext is not None else open(os.path.join(REPO, rel), encoding="utf-8").read()
        try:
            cats = fn(text)
        except ValueError as e:
            failures.append(f"{label}: EXTRACTION FAILED — {e}. Fix the anchor rather than letting this guard pass vacuously.")
            continue
        if not cats:
            failures.append(f"{label}: extracted ZERO categories — the pattern matched but found no entries.")
            continue
        found[label] = cats

    if failures:
        for f in failures:
            print(f"ERROR: {f}", file=sys.stderr)
        return 1

    reference = None
    for label, cats in found.items():
        if reference is None:
            reference = (label, cats)
        elif cats != reference[1]:
            missing = sorted(reference[1] - cats)
            extra = sorted(cats - reference[1])
            print("ERROR: roster-notice category lists DISAGREE.", file=sys.stderr)
            for lbl, c in found.items():
                print(f"  {lbl}\n      {sorted(c)}", file=sys.stderr)
            print(f"\n  '{label}' vs '{reference[0]}': missing={missing} extra={extra}", file=sys.stderr)
            print("\n  A category present in only some of these is worse than absent from all of them:\n"
                  "    * absent from alert_relay.py NO_PUSH_CATEGORIES  -> it PUSHES to the phone as a fault\n"
                  "    * present in alert_relay.py NO_PUSH_CATEGORIES only -> it is SILENTLY never pushed\n"
                  "    * absent from alert_emailer.gs -> emailed in the incident lane, not the roster lane\n"
                  "    * absent from Rule 5 -> never auto-resolves; sits on the alert board forever\n"
                  "    * absent from Claude_Task_Plan.md -> no routine has a spec to raise it against\n"
                  "  Update ALL FOUR, or none.", file=sys.stderr)
            return 1

    print(f"ROSTER-NOTICE LOCKSTEP: OK — all {len(found)} sources agree on {len(reference[1])} categories: "
          f"{', '.join(sorted(reference[1]))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
