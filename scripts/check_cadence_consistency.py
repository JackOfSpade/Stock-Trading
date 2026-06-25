#!/usr/bin/env python3
"""Single-source the cadence: fail CI if the hand-kept SQL drifts from ops/cadence.yaml + the plan.

WHY THIS EXISTS. "What runs when" was hand-maintained in THREE places that had to stay in lockstep
with no automated guard:
  1. ops/cadence.yaml                          — the documented manifest (now carries monitor_class)
  2. state.cadence_expected_today (SQL)        — bigquery/12_cadence_monitor.sql, a hardcoded routine list
  3. ops.routine_catalog (SQL)                 — bigquery/15_routine_catalog.sql, a hardcoded instruction seed
plus the canonical routine headings in Claude_Task_Plan.md. A routine added / renamed / rescheduled in
one place but not the others drifted silently — exactly the RUNBOOK §22-class problem. This check makes
ops/cadence.yaml + Claude_Task_Plan.md the SOURCE OF TRUTH and verifies the two SQL files agree:

  A. state.cadence_expected_today's (routine -> schedule-class) set == cadence.yaml's
     (id -> monitor_class) for every routine whose monitor_class is calendar-predictable
     (i.e. != queue_driven; the AR routines are deliberately excluded from the calendar view).
  B. ops.routine_catalog's (routine -> canonical_instruction) == the instruction derived from each
     Claude_Task_Plan.md routine heading ("Read Claude_Task_Plan.md. Perform <heading>.").
  C. Every cadence.yaml routine id maps 1:1 to a Claude_Task_Plan.md heading and appears in the catalog
     (the scripts/print_routines.py cross-check, extended to the SQL layer).
  D. cadence.yaml's top-level `cadence_watch_deadline_local` == the TIME literal in the
     state.cadence_watch deadline guard (bigquery/12_cadence_monitor.sql). The deadline is otherwise a
     bare SQL constant with no source of truth, so a real cadence shift could silently leave it stale and
     re-open the pre-deadline false-positive window (RUNBOOK §1 step 3 / §20 follow-up).

This does NOT generate the SQL (the .sql files carry comments + special formatting worth hand-keeping);
it CHECKS them, so editing cadence.yaml or a plan heading and forgetting the SQL fails the build with a
precise diff instead of surfacing weeks later as a false cadence/instruction_drift alert.

Usage:  python scripts/check_cadence_consistency.py        # exit 0 if consistent, 1 + diff if not
"""
import os
import re
import sys

try:
    import yaml
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")
CADENCE = os.path.join(ROOT, "ops", "cadence.yaml")
CADENCE_SQL = os.path.join(ROOT, "bigquery", "12_cadence_monitor.sql")
CATALOG_SQL = os.path.join(ROOT, "bigquery", "15_routine_catalog.sql")

ALLOWED_CLASSES = {
    "daily_trading", "daily_all", "weekly_sun",
    "monthly_ftd", "quarterly_ftd", "annual_ftd", "queue_driven",
}
# monitor_class values the calendar view (state.cadence_expected_today) must encode.
CALENDAR_CLASSES = ALLOWED_CLASSES - {"queue_driven"}

ROUTINE_SUFFIX = re.compile(r"—\s*(deep research|regular routine)\s*$")

# The state.cadence_watch deadline-guard literal: DATETIME(e.today, TIME 'HH:MM:SS'). Capture HH:MM.
SQL_DEADLINE = re.compile(r"DATETIME\(\s*e\.today\s*,\s*TIME\s*'(\d{2}:\d{2})(?::\d{2})?'\s*\)")
HHMM = re.compile(r"^\d{2}:\d{2}$")


def plan_headings():
    """Ordered routine section headings from Claude_Task_Plan.md (same rule as print_routines.py)."""
    out = []
    with open(PLAN, encoding="utf-8") as f:
        for ln in f:
            if ln.startswith("## "):
                h = ln[3:].strip()
                if ROUTINE_SUFFIX.search(h):
                    out.append(h)
    return out


def heading_to_id(h):
    m = re.match(r"([A-Za-z0-9]+)\.\s", h)   # "D1. ...", "M1a. ...", "Q4. ..."
    if m:
        return m.group(1)
    if "Attacker" in h:
        return "AR·att"
    if "Orchestrator" in h:
        return "AR·orc"
    return None


def load_cadence():
    doc = yaml.safe_load(open(CADENCE, encoding="utf-8")) or {}
    return {r["id"]: r for r in doc.get("routines", [])}


def parse_expected_sql():
    """{routine: schedule_class} from the STRUCT(... AS routine, ... AS schedule) list in 12_*.sql."""
    txt = open(CADENCE_SQL, encoding="utf-8").read()
    pat = re.compile(r"STRUCT\('([^']+)'\s+AS routine,\s*'([^']+)'\s+AS schedule\)")
    return dict(pat.findall(txt))


def parse_catalog_sql():
    """{routine: canonical_instruction} from 15_*.sql (handles the first AS-labelled row + shorthand rows)."""
    txt = open(CATALOG_SQL, encoding="utf-8").read()
    pat = re.compile(
        r"STRUCT\('([^']+)'(?:\s+AS routine)?,\s*'(Read Claude_Task_Plan\.md\. Perform [^']*)'")
    return dict(pat.findall(txt))


def parse_deadline_sql():
    """['HH:MM', ...] from the DATETIME(e.today, TIME 'HH:MM:SS') deadline guard in 12_*.sql (state.cadence_watch)."""
    return SQL_DEADLINE.findall(open(CADENCE_SQL, encoding="utf-8").read())


def cadence_deadline_yaml():
    """Top-level cadence_watch_deadline_local from ops/cadence.yaml (raw value, or None)."""
    doc = yaml.safe_load(open(CADENCE, encoding="utf-8")) or {}
    return doc.get("cadence_watch_deadline_local")


def main():
    cad = load_cadence()
    headings = plan_headings()
    errors = []

    # ---- canonical maps from the SOURCE OF TRUTH (cadence.yaml + the plan) ----
    head_by_id, dup = {}, []
    for h in headings:
        rid = heading_to_id(h)
        if rid is None:
            errors.append(f"plan heading does not map to a routine id (bad format?): '{h}'")
            continue
        if rid in head_by_id:
            dup.append(rid)
        head_by_id[rid] = h
    for rid in dup:
        errors.append(f"duplicate Claude_Task_Plan.md heading for id {rid}")

    want_catalog = {rid: f"Read Claude_Task_Plan.md. Perform {h}." for rid, h in head_by_id.items()}
    want_expected = {rid: r["monitor_class"] for rid, r in cad.items()
                     if r.get("monitor_class") in CALENDAR_CLASSES}

    # ---- validate monitor_class presence + vocabulary ----
    for rid, r in cad.items():
        mc = r.get("monitor_class")
        if mc is None:
            errors.append(f"{rid}: missing monitor_class in ops/cadence.yaml")
        elif mc not in ALLOWED_CLASSES:
            errors.append(f"{rid}: monitor_class '{mc}' not in {sorted(ALLOWED_CLASSES)}")

    # ---- C. cadence.yaml id <-> plan heading 1:1 ----
    for rid in cad:
        if rid not in head_by_id:
            errors.append(f"{rid}: in ops/cadence.yaml but no matching Claude_Task_Plan.md heading")
    for rid in head_by_id:
        if rid not in cad:
            errors.append(f"{rid}: Claude_Task_Plan.md heading but no ops/cadence.yaml routine")

    # ---- A. state.cadence_expected_today (12_*.sql) == calendar-class routines in cadence.yaml ----
    have_expected = parse_expected_sql()
    if not have_expected:
        errors.append("could not parse any STRUCT(... AS schedule) rows from 12_cadence_monitor.sql")
    for rid, cls in want_expected.items():
        if rid not in have_expected:
            errors.append(f"{rid}: monitor_class={cls} in cadence.yaml but MISSING from "
                          f"state.cadence_expected_today (12_cadence_monitor.sql)")
        elif have_expected[rid] != cls:
            errors.append(f"{rid}: schedule class mismatch — cadence.yaml='{cls}' vs "
                          f"12_cadence_monitor.sql='{have_expected[rid]}'")
    for rid in have_expected:
        if rid not in want_expected:
            errors.append(f"{rid}: in state.cadence_expected_today (12_*.sql) but not a calendar-class "
                          f"routine in cadence.yaml (queue_driven/unknown routines must NOT be listed)")

    # ---- B. ops.routine_catalog (15_*.sql) == plan-heading-derived instruction ----
    have_catalog = parse_catalog_sql()
    if not have_catalog:
        errors.append("could not parse any catalog STRUCT rows from 15_routine_catalog.sql")
    for rid, instr in want_catalog.items():
        if rid not in have_catalog:
            errors.append(f"{rid}: has a plan heading but is MISSING from ops.routine_catalog (15_*.sql)")
        elif have_catalog[rid] != instr:
            errors.append(f"{rid}: routine_catalog instruction drift\n"
                          f"     plan-derived: {instr}\n"
                          f"     15_*.sql:     {have_catalog[rid]}")
    for rid in have_catalog:
        if rid not in want_catalog:
            errors.append(f"{rid}: in ops.routine_catalog (15_*.sql) but has no Claude_Task_Plan.md heading")

    # ---- D. cadence_watch deadline guard: cadence.yaml constant == bigquery/12 SQL TIME literal ----
    want_deadline = cadence_deadline_yaml()
    have_deadlines = parse_deadline_sql()
    deadline_ok = True
    if want_deadline is None:
        errors.append("ops/cadence.yaml: missing top-level 'cadence_watch_deadline_local' "
                      "(declares the state.cadence_watch deadline-guard time)")
        deadline_ok = False
    elif not (isinstance(want_deadline, str) and HHMM.match(want_deadline)):
        errors.append(f"ops/cadence.yaml: cadence_watch_deadline_local must be a quoted \"HH:MM\" string "
                      f"(got {want_deadline!r} — an UNquoted 21:00 is YAML base-60 = 1260; always quote it)")
        deadline_ok = False
    if not have_deadlines:
        errors.append("bigquery/12_cadence_monitor.sql: could not parse the DATETIME(e.today, TIME '..') "
                      "deadline-guard literal from state.cadence_watch (did the clause change shape?)")
        deadline_ok = False
    elif len(set(have_deadlines)) > 1:
        errors.append(f"bigquery/12_cadence_monitor.sql: multiple distinct deadline literals "
                      f"{sorted(set(have_deadlines))} in state.cadence_watch — expected exactly one")
        deadline_ok = False
    if deadline_ok and have_deadlines[0] != want_deadline:
        errors.append(f"cadence_watch deadline DRIFT — ops/cadence.yaml='{want_deadline}' vs "
                      f"bigquery/12_cadence_monitor.sql TIME='{have_deadlines[0]}'. Keep them in sync.")

    # ---- report ----
    if errors:
        print("CADENCE CONSISTENCY: FAIL\n")
        for e in errors:
            print(" - " + e)
        print("\nFix ops/cadence.yaml (monitor_class) / Claude_Task_Plan.md headings and the matching "
              "bigquery/12_cadence_monitor.sql + bigquery/15_routine_catalog.sql so all three agree, "
              "then re-run. (See ops/cadence.yaml header + scripts/print_routines.py.)")
        return 1

    print(f"CADENCE CONSISTENCY: OK — {len(cad)} routines; "
          f"{len(want_expected)} calendar-class match state.cadence_expected_today; "
          f"{len(have_catalog)} catalog entries match the plan headings; "
          f"cadence_watch deadline {want_deadline} matches 12_cadence_monitor.sql.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
