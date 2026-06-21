#!/usr/bin/env python3
"""Print every routine's trigger instruction + cadence — no web-UI screenshots needed.

The Claude-Code-on-Web triggers (schedule + instruction) live ONLY in the web UI and are not
readable from a session (see ops/cadence.yaml header). But they are deterministic: each trigger's
instruction is exactly

    Read Claude_Task_Plan.md. Perform <routine heading>.

and the cadence is mirrored in ops/cadence.yaml. This script reconstructs the canonical list from
those two repo files, so you get one printout to review, to diff against the web UI, or to use when
(re)creating triggers — instead of opening each routine and screenshotting it.

It also cross-checks that every ops/cadence.yaml routine has a matching Claude_Task_Plan.md heading
(and vice-versa), so a drift between the two surfaces here.

EXACT CLOCK TIMES live only in the web UI; ops/cadence.yaml carries the cadence-level schedule
(e.g. "after_close trading_day", "weekly Sun", "monthly first_trading_day"). Record exact times in
cadence.yaml if you want them printed.

VERIFYING THE LIVE TRIGGERS (no screenshots): once routines record the verbatim instruction they
received (ops.run_log.instruction, set by ops.sp_routine_start), run
    SELECT * FROM `stock-trading-498512.state.routine_last_instruction`;
to see the ACTUAL trigger text each routine last received, and diff it against THIS script's canonical
output — any mismatch is a drifted/typo'd web-UI trigger.

Usage:  python scripts/print_routines.py
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

# A routine section heading ends with its type tag; this excludes preamble/queue-schema headings.
ROUTINE_SUFFIX = re.compile(r"—\s*(deep research|regular routine)\s*$")


def routine_headings():
    """Ordered list of routine section headings from Claude_Task_Plan.md."""
    out = []
    with open(PLAN, encoding="utf-8") as f:
        for ln in f:
            if ln.startswith("## "):
                h = ln[3:].strip()
                if ROUTINE_SUFFIX.search(h):
                    out.append(h)
    return out


def heading_to_id(h):
    """Map a heading to its ops/cadence.yaml id."""
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
    sched = {r["id"]: r for r in doc.get("routines", [])}
    return doc.get("timezone", "?"), sched


def main():
    headings = routine_headings()
    tz, cad = load_cadence()
    seen = set()

    print("Routine triggers — instruction is `Read Claude_Task_Plan.md. Perform <heading>.`")
    print(f"Cadence timezone: {tz}  (exact clock times are in the web UI only)\n")
    print("=" * 100)
    for h in headings:
        rid = heading_to_id(h) or "?"
        seen.add(rid)
        r = cad.get(rid, {})
        deps = ", ".join(r.get("depends_on") or []) or "—"
        print(f"{rid}   cadence: {r.get('schedule', '(not in cadence.yaml)')}   deps: {deps}")
        print(f"   instruction: Read Claude_Task_Plan.md. Perform {h}.")
        print()
    print("=" * 100)
    print(f"{len(headings)} routines.")

    # Drift check both directions.
    missing_heading = [cid for cid in cad if cid not in seen]
    if missing_heading:
        print("WARNING: in cadence.yaml but no matching Claude_Task_Plan heading: "
              + ", ".join(missing_heading))
    if "?" in seen:
        print("WARNING: a routine heading did not map to a cadence id (check heading format).")
    if not missing_heading and "?" not in seen:
        print("OK: every routine heading maps 1:1 to an ops/cadence.yaml routine.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
