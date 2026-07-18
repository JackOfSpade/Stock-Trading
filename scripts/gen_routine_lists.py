#!/usr/bin/env python3
"""Generate the routine-list STRUCT rows for bigquery/12/15/24 from ops/cadence.yaml + Claude_Task_Plan.md.

WHY THIS EXISTS (ARCH-3 Item 30b, closing the deferred hand-copy hole). bigquery/12
(state.cadence_expected_today), bigquery/15 (ops.routine_catalog), and bigquery/24
(state.cadence_period_watch) each independently hand-carry a list of routine STRUCT rows that must
stay byte-consistent with ops/cadence.yaml. scripts/check_cadence_consistency.py's checks A/B/J only
CHECK that agreement -- nothing GENERATES the rows, so adding/renaming/rescheduling a routine still
required hand-editing three files (the deferred half of Item 30b). This script generates the row text
for a marker-delimited region inside each file, so a routine change only requires editing
ops/cadence.yaml (+ a Claude_Task_Plan.md heading for a brand-new routine) and re-running --write.

It does NOT generate bigquery/31_catchup_notify.sql or bigquery/59_catchup_autofire.sql's catchup-safe
UNNEST lists (those stay hand-kept, declared judgment calls -- check_cadence_consistency.py's check K
CHECKS them against cadence.yaml's catchup_safe field instead), and does NOT generate the
Claude_Task_Plan.md ROUTINE INVENTORY table (check L checks that by hand-authored convention too).

Regions generated (marker-delimited, one BEGIN/END pair per file):
  bigquery/12_cadence_monitor.sql   -- state.cadence_expected_today's `routines` CTE STRUCT rows,
                                        one per calendar-class routine (monitor_class != queue_driven),
                                        in ops/cadence.yaml order.
  bigquery/15_routine_catalog.sql   -- ops.routine_catalog's STRUCT rows, ALL routines, cadence.yaml
                                        order, instruction text derived from the matching
                                        Claude_Task_Plan.md heading exactly as check B does.
  bigquery/24_cadence_period_watch.sql -- state.cadence_period_watch's `routines` CTE STRUCT rows,
                                        one per routine whose monitor_class is a period class
                                        (weekly_sun/monthly_ftd/quarterly_ftd/annual_ftd), cadence.yaml
                                        order.

Usage:
  python scripts/gen_routine_lists.py --write   # regenerate all 3 marker regions in place
  python scripts/gen_routine_lists.py --check   # exit 1 + diff if any region is stale

Markers (exactly one BEGIN/END pair per file, wrapping ONLY the STRUCT rows -- the surrounding
`SELECT * FROM UNNEST([ ... ])` / `FROM UNNEST([ ... ])` SQL stays hand-kept):
  -- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)
  -- END GENERATED ROUTINE LIST
"""
import argparse
import os
import sys

import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.routine_manifest import parse_routine_headings, heading_to_id  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")
CADENCE = os.path.join(ROOT, "ops", "cadence.yaml")

CADENCE_MONITOR_SQL = os.path.join(ROOT, "bigquery", "12_cadence_monitor.sql")
ROUTINE_CATALOG_SQL = os.path.join(ROOT, "bigquery", "15_routine_catalog.sql")
PERIOD_WATCH_SQL = os.path.join(ROOT, "bigquery", "24_cadence_period_watch.sql")

BEGIN_MARKER = "-- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)"
END_MARKER = "-- END GENERATED ROUTINE LIST"

PERIOD_CLASSES = ("weekly_sun", "monthly_ftd", "quarterly_ftd", "annual_ftd")


def load_cadence_routines():
    """Ordered list of routine dicts, in ops/cadence.yaml file order (the canonical order every
    generated region reproduces)."""
    doc = yaml.safe_load(open(CADENCE, encoding="utf-8")) or {}
    return doc.get("routines", []) or []


def load_headings_by_id():
    return {heading_to_id(h): h for h in parse_routine_headings(PLAN) if heading_to_id(h)}


def gen_12_region(routines):
    """state.cadence_expected_today rows: one per calendar-class routine (monitor_class !=
    queue_driven), cadence.yaml order, 4-space indent matching the surrounding UNNEST([ block."""
    # Exclude both queue_driven AND a missing/None monitor_class (a malformed cadence.yaml routine):
    # the old `!= "queue_driven"` filter kept a None-monitor_class row, then the f-string's
    # r['monitor_class'] bracket-access raised KeyError, unlike the parallel gen_24_region whose
    # `in PERIOD_CLASSES` filter already drops None. check_cadence_consistency.py flags the missing
    # key loudly (`{rid}: missing monitor_class`), so omitting the row here masks nothing (2026-07-17).
    rows = [r for r in routines if r.get("monitor_class") not in ("queue_driven", None)]
    lines = []
    for i, r in enumerate(rows):
        comma = "," if i < len(rows) - 1 else ""
        lines.append(f"    STRUCT('{r['id']}' AS routine, '{r['monitor_class']}' AS schedule){comma}")
    return "\n".join(lines)


def gen_15_region(routines, head_by_id):
    """ops.routine_catalog rows: ALL routines, cadence.yaml order, instruction text derived from the
    matching plan heading exactly as check_cadence_consistency.py's check B derives want_catalog, so
    the generated output stays byte-compatible with that check. A routine with no plan heading yet
    (should not happen in a consistent tree) gets an empty instruction string -- check B/C will flag
    that loudly rather than this generator silently guessing."""
    lines = []
    n = len(routines)
    for i, r in enumerate(routines):
        rid = r["id"]
        heading = head_by_id.get(rid)
        instr = f"Read Claude_Task_Plan.md. Perform {heading}." if heading else ""
        comma = "," if i < n - 1 else ""
        lines.append(f"  STRUCT('{rid}' AS routine, '{instr}' AS canonical_instruction){comma}")
    return "\n".join(lines)


def gen_24_region(routines):
    """state.cadence_period_watch rows: routines whose monitor_class is one of the four period
    classes, cadence.yaml order, 4-space indent matching the surrounding UNNEST([ block."""
    rows = [r for r in routines if r.get("monitor_class") in PERIOD_CLASSES]
    lines = []
    for i, r in enumerate(rows):
        comma = "," if i < len(rows) - 1 else ""
        lines.append(f"    STRUCT('{r['id']}' AS routine, '{r['monitor_class']}' AS monitor_class){comma}")
    return "\n".join(lines)


def _region_bounds(txt, path):
    b = txt.find(BEGIN_MARKER)
    e = txt.find(END_MARKER)
    if b == -1 or e == -1 or e < b:
        raise SystemExit(f"{path}: could not find BEGIN/END GENERATED ROUTINE LIST markers")
    return b, e


def current_region(path):
    """The exact text currently between the markers (excluding the marker lines themselves), or None
    if the markers are not present in the file."""
    txt = open(path, encoding="utf-8").read()
    b = txt.find(BEGIN_MARKER)
    e = txt.find(END_MARKER)
    if b == -1 or e == -1 or e < b:
        return None
    return txt[b + len(BEGIN_MARKER):e]


def wanted_region(body):
    """The canonical marker-region text (including the newline padding on each side) a `body` of
    STRUCT-row lines is rendered into -- shared by --write (what gets written) and --check (what is
    compared against) so the two can never drift from each other."""
    return "\n" + body + "\n  "


def write_region(path, body):
    txt = open(path, encoding="utf-8").read()
    b, e = _region_bounds(txt, path)
    new_txt = txt[:b + len(BEGIN_MARKER)] + wanted_region(body) + txt[e:]
    if new_txt != txt:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_txt)
        return True
    return False


def build_targets():
    routines = load_cadence_routines()
    head_by_id = load_headings_by_id()
    return [
        (CADENCE_MONITOR_SQL, gen_12_region(routines)),
        (ROUTINE_CATALOG_SQL, gen_15_region(routines, head_by_id)),
        (PERIOD_WATCH_SQL, gen_24_region(routines)),
    ]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--write", action="store_true", help="regenerate all 3 marker regions in place")
    g.add_argument("--check", action="store_true", help="exit 1 + diff if any region is stale")
    args = ap.parse_args()

    targets = build_targets()

    if args.write:
        changed = []
        for path, body in targets:
            if write_region(path, body):
                changed.append(os.path.relpath(path, ROOT))
        if changed:
            print(f"gen_routine_lists --write: regenerated {', '.join(changed)}.")
        else:
            print("gen_routine_lists --write: all 3 regions already current (no-op).")
        return 0

    # --check
    drift = False
    for path, body in targets:
        rel = os.path.relpath(path, ROOT)
        current = current_region(path)
        if current is None:
            print(f"{rel}: could not find BEGIN/END GENERATED ROUTINE LIST markers")
            drift = True
            continue
        want = wanted_region(body)
        if current != want:
            drift = True
            print(f"{rel}: GENERATED ROUTINE LIST region is STALE vs ops/cadence.yaml + "
                  f"Claude_Task_Plan.md -- run `python scripts/gen_routine_lists.py --write`")
    if drift:
        return 1
    print("gen_routine_lists --check: OK -- bigquery/12, 15, 24 generated regions match "
          "ops/cadence.yaml + Claude_Task_Plan.md.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
