#!/usr/bin/env python3
"""Generate the routine-list STRUCT rows for bigquery/12/15/24/105/114/132 from ops/cadence.yaml +
Claude_Task_Plan.md.

WHY THIS EXISTS (ARCH-3 Item 30b, closing the deferred hand-copy hole). bigquery/12
(state.cadence_expected_today), bigquery/15 (ops.routine_catalog), bigquery/24
(state.cadence_period_watch), and bigquery/105 (state.routine_catchup_window) each independently
hand-carry a list of routine STRUCT rows that must stay byte-consistent with ops/cadence.yaml.
scripts/check_cadence_consistency.py's checks A/B/J only CHECK the first three's agreement --
nothing GENERATES the rows, so adding/renaming/rescheduling a routine still required hand-editing
multiple files (the deferred half of Item 30b). This script generates the row text for a
marker-delimited region inside each file, so a routine change only requires editing ops/cadence.yaml
(+ a Claude_Task_Plan.md heading for a brand-new routine) and re-running --write.

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
  bigquery/105_routine_catchup_window.sql -- state.routine_catchup_window's `routines` CTE STRUCT
                                        rows, ALL routines INCLUDING the 4 queue_driven ids (unlike
                                        bigquery/12's calendar-only filter -- this is the one region
                                        that needs the full routine roster), cadence.yaml order.
  bigquery/114_period_aware_dependency_gate.sql -- ops.sp_assert_deps' `period_class` CTE STRUCT rows.
                                        BYTE-IDENTICAL to the bigquery/24 region (same gen_24_region
                                        call): the dependency gate resolves a dep's period window from
                                        the same (routine -> monitor_class) mapping the period watch
                                        view uses, so the gate and the monitor cannot disagree about
                                        which routines are period-cadence. 114 embeds the list rather
                                        than joining state.cadence_period_watch because it is a FATAL,
                                        unwrapped gate that must not gain a runtime view dependency.
  bigquery/132_queue_driven_silence_watch.sql -- state.queue_driven_silence_watch's `routines` CTE
                                        STRUCT rows, ONLY the queue_driven routines -- the exact
                                        complement of the bigquery/12 region. Those four sit outside
                                        state.cadence_expected_today and therefore outside BOTH
                                        cadence nets; 132 is the only thing watching them.

Usage:
  python scripts/gen_routine_lists.py --write   # regenerate all 6 marker regions in place
  python scripts/gen_routine_lists.py --check   # exit 1 + diff if any region is stale

Markers (exactly one BEGIN/END pair per file, wrapping ONLY the STRUCT rows -- the surrounding
`SELECT * FROM UNNEST([ ... ])` / `FROM UNNEST([ ... ])` SQL stays hand-kept):
  -- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)
  -- END GENERATED ROUTINE LIST
"""
import argparse
import os
import sys

try:
    # this module's own reads now go through lib.textio.load_yaml() (2026-07-29 textio
    # adoption), so `yaml` is no longer referenced directly here, but the import stays for this
    # fail-fast ImportError guard (a clear "pip install pyyaml" message beats textio.py's own bare
    # ImportError traceback).
    import yaml  # noqa: F401
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.routine_manifest import (
    parse_routine_headings, heading_to_id, instruction_text, cadence_routines,
)
from lib.textio import read_text, load_yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")
CADENCE = os.path.join(ROOT, "ops", "cadence.yaml")

CADENCE_MONITOR_SQL = os.path.join(ROOT, "bigquery", "12_cadence_monitor.sql")
ROUTINE_CATALOG_SQL = os.path.join(ROOT, "bigquery", "15_routine_catalog.sql")
PERIOD_WATCH_SQL = os.path.join(ROOT, "bigquery", "24_cadence_period_watch.sql")
ROUTINE_CATCHUP_SQL = os.path.join(ROOT, "bigquery", "105_routine_catchup_window.sql")
DEP_GATE_SQL = os.path.join(ROOT, "bigquery", "114_period_aware_dependency_gate.sql")

BEGIN_MARKER = "-- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)"
END_MARKER = "-- END GENERATED ROUTINE LIST"

PERIOD_CLASSES = ("weekly_sun", "monthly_ftd", "quarterly_ftd", "annual_ftd")


def load_cadence_routines():
    """Ordered list of routine dicts, in ops/cadence.yaml file order (the canonical order every
    generated region reproduces)."""
    doc = load_yaml(CADENCE)
    return cadence_routines(doc)


def load_headings_by_id():
    return {heading_to_id(h): h for h in parse_routine_headings(PLAN) if heading_to_id(h)}


def _sql_str(s):
    """Escape a Python string for embedding inside a single-quoted BigQuery SQL literal: ' -> ''.
    check_cadence_consistency.py check B (parse_catalog_sql) performs the exact inverse ('' -> ')
    when it reads the row back, so gen_15_region's output and check B's want_catalog stay byte-
    compatible even for a heading containing an apostrophe. The two MUST stay in lockstep."""
    return s.replace("'", "''")


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
    that loudly rather than this generator silently guessing.

    A heading may contain an apostrophe; it is escaped to '' for the single-quoted SQL literal (see
    _sql_str). This is kept in LOCKSTEP with check_cadence_consistency.py check B (parse_catalog_sql),
    which un-escapes ''->' when it parses the row back so its want_catalog (raw heading text) matches.
    The two derivations are byte-identical and MUST move together: changing the escaping here without
    the paired check B un-escape (or vice-versa) desyncs them. Byte-identical on the current tree --
    no routine heading contains an apostrophe today, so this only changes output once one does."""
    lines = []
    n = len(routines)
    for i, r in enumerate(routines):
        rid = r["id"]
        heading = head_by_id.get(rid)
        instr = instruction_text(heading) if heading else ""
        comma = "," if i < n - 1 else ""
        # rid is a constrained \w+ id (never quoted), so only the free-text instruction needs escaping
        # -- and check B un-escapes only the instruction capture, so escaping only it keeps the two
        # derivations matched.
        lines.append(f"  STRUCT('{rid}' AS routine, '{_sql_str(instr)}' AS canonical_instruction){comma}")
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


def gen_105_region(routines):
    """state.routine_catchup_window rows: ALL routines, INCLUDING the 4 queue_driven ids (unlike
    gen_12_region's calendar-only filter and gen_24_region's period-only filter), cadence.yaml
    order, 4-space indent matching the surrounding UNNEST([ block. This is the one generated region
    that needs the full routine roster -- state.routine_catchup_window computes a catch-up
    evidence window for every routine, calendar-predictable or queue_driven alike (owner directive
    2026-07-25; see bigquery/105_routine_catchup_window.sql's header)."""
    rows = [r for r in routines if r.get("monitor_class") is not None]
    lines = []
    for i, r in enumerate(rows):
        comma = "," if i < len(rows) - 1 else ""
        lines.append(f"    STRUCT('{r['id']}' AS routine, '{r['monitor_class']}' AS monitor_class){comma}")
    return "\n".join(lines)


def _region_bounds(txt, path):
    """(begin_index, end_index) of the marker positions in `txt`. RAISES SystemExit on missing/out-of-
    order markers -- the single shared bounds-finder for this module. Before 2026-08-08 this exact
    `txt.find(BEGIN_MARKER)` / `txt.find(END_MARKER)` / `e < b` check was duplicated verbatim in
    current_region() below (which returned None on failure instead of raising), so the two paths could
    silently drift apart if one copy's finding logic were ever tweaked without the other. Unified on
    the RAISING behavior (the stricter/louder of the two) because write_region() below -- a mutating
    operation -- must never proceed past a missing region; current_region() (read-only, used by --check
    to keep reporting every OTHER target's staleness) adapts that into its own None-on-failure contract
    by catching the SystemExit itself, rather than re-implementing the search."""
    b = txt.find(BEGIN_MARKER)
    e = txt.find(END_MARKER)
    if b == -1 or e == -1 or e < b:
        raise SystemExit(f"{path}: could not find BEGIN/END GENERATED ROUTINE LIST markers")
    return b, e


def current_region(path):
    """The exact text currently between the markers (excluding the marker lines themselves), or None
    if the markers are not present in the file (adapted from _region_bounds' SystemExit -- see that
    function's docstring)."""
    txt = read_text(path)
    try:
        b, e = _region_bounds(txt, path)
    except SystemExit:
        return None
    return txt[b + len(BEGIN_MARKER):e]


def wanted_region(body):
    """The canonical marker-region text (including the newline padding on each side) a `body` of
    STRUCT-row lines is rendered into -- shared by --write (what gets written) and --check (what is
    compared against) so the two can never drift from each other."""
    return "\n" + body + "\n  "


def write_region(path, body):
    txt = read_text(path)
    b, e = _region_bounds(txt, path)
    new_txt = txt[:b + len(BEGIN_MARKER)] + wanted_region(body) + txt[e:]
    if new_txt != txt:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_txt)
        return True
    return False


QUEUE_SILENCE_SQL = os.path.join(ROOT, "bigquery", "132_queue_driven_silence_watch.sql")


def gen_132_region(routines):
    """state.queue_driven_silence_watch rows: ONLY the queue_driven routines -- the exact complement
    of gen_12_region's calendar-class filter. These four are excluded from
    state.cadence_expected_today by construction, so neither state.cadence_watch nor
    state.cadence_period_watch can see them; bigquery/132 is their only net. Generating the list here
    (rather than hand-keeping it) means adding a 5th queue_driven routine to ops/cadence.yaml cannot
    silently leave it unwatched. cadence.yaml order, 4-space indent matching the surrounding
    UNNEST([ block."""
    rows = [r for r in routines if r.get("monitor_class") == "queue_driven"]
    lines = []
    for i, r in enumerate(rows):
        comma = "," if i < len(rows) - 1 else ""
        lines.append(f"    STRUCT('{r['id']}' AS routine, '{r['monitor_class']}' AS monitor_class){comma}")
    return "\n".join(lines)


def build_targets():
    routines = load_cadence_routines()
    head_by_id = load_headings_by_id()
    return [
        (CADENCE_MONITOR_SQL, gen_12_region(routines)),
        (ROUTINE_CATALOG_SQL, gen_15_region(routines, head_by_id)),
        (PERIOD_WATCH_SQL, gen_24_region(routines)),
        (ROUTINE_CATCHUP_SQL, gen_105_region(routines)),
        # bigquery/114 needs the IDENTICAL (routine, monitor_class) period-class rows as bigquery/24 --
        # ops.sp_assert_deps resolves a dependency's period window from the same mapping the period
        # watch view uses -- so it reuses gen_24_region verbatim rather than defining a near-duplicate
        # generator. The two regions are byte-identical by construction, which is the point: the gate
        # and the monitor can never disagree about which routines are period-cadence. 114 embeds the
        # list (instead of joining state.cadence_period_watch) because it is a FATAL, unwrapped gate
        # that must not gain a runtime view dependency -- see that file's header.
        (DEP_GATE_SQL, gen_24_region(routines)),
        # bigquery/132 takes the COMPLEMENT of bigquery/12's list: 12 carries every calendar-class
        # routine, 132 carries every queue_driven one. Between them the two regions partition the
        # roster, so a routine cannot be absent from both and end up watched by nothing -- which is
        # precisely the hole bigquery/132 was written to close (SL2/SL5, 2026-08-03).
        (QUEUE_SILENCE_SQL, gen_132_region(routines)),
    ]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--write", action="store_true", help="regenerate all 6 marker regions in place")
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
            print("gen_routine_lists --write: all 6 regions already current (no-op).")
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
    print("gen_routine_lists --check: OK -- bigquery/12, 15, 24, 105, 114, 132 generated regions match "
          "ops/cadence.yaml + Claude_Task_Plan.md.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
