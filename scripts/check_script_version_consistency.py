#!/usr/bin/env python3
"""Single-source the Apps Script version constants: .gs file <-> bigquery/43's MERGE seed
(2026-07-14 self-improvement audit finding).

WHY THIS EXISTS. ops/monitoring/alert_emailer.gs's ALERT_SCRIPT_VERSION and
ops/weekly_report/weekly_report.gs's SCRIPT_VERSION are each hand-kept in lockstep with
bigquery/43_script_version_registry.sql's MERGE seed (state.expected_script_versions), which
state.script_version_drift compares against ops.heartbeat.version to catch "repo fixed but the
live out-of-band script not redeployed." Every other cross-file constant this codebase maintains
this way (ops/cadence.yaml, strategy/roster.yaml's rails) has a dedicated CI script that fails the
build on drift — this pairing had none: a future .gs version bump that forgets to also bump the
seed (or vice versa) would silently break state.script_version_drift with no CI signal.

Usage:  python scripts/check_script_version_consistency.py    # exit 0 if consistent, 1 + diff if not
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALERT_GS = os.path.join(ROOT, "ops", "monitoring", "alert_emailer.gs")
WEEKLY_GS = os.path.join(ROOT, "ops", "weekly_report", "weekly_report.gs")
REGISTRY_SQL = os.path.join(ROOT, "bigquery", "43_script_version_registry.sql")

# Whitespace-tolerant: alert_emailer.gs aligns with extra spaces before '=', weekly_report.gs does not.
GS_VERSION = re.compile(r"const\s+(?:ALERT_)?SCRIPT_VERSION\s*=\s*'([^']+)'")
SEED_ROW = re.compile(r"STRUCT\('(\w+)'\s+AS\s+script_name,\s*'([^']+)'\s+AS\s+expected_version")

# script_name (bigquery/43's MERGE seed key, == ops.heartbeat.source) -> .gs file path.
SCRIPTS = {"alert_emailer": ALERT_GS, "weekly_report": WEEKLY_GS}


def parse_gs_version(path):
    m = GS_VERSION.search(open(path, encoding="utf-8").read())
    return m.group(1) if m else None


def parse_seed_versions():
    txt = open(REGISTRY_SQL, encoding="utf-8").read()
    return {name: version for name, version in SEED_ROW.findall(txt)}


def main():
    errors = []
    seed = parse_seed_versions()
    for script_name, gs_path in SCRIPTS.items():
        gs_version = parse_gs_version(gs_path)
        rel = os.path.relpath(gs_path, ROOT)
        if gs_version is None:
            errors.append(f"{rel}: could not find a SCRIPT_VERSION/ALERT_SCRIPT_VERSION const "
                          f"(regex may need updating if the declaration shape changed)")
            continue
        seed_version = seed.get(script_name)
        if seed_version is None:
            errors.append(f"bigquery/43_script_version_registry.sql: no MERGE seed row for "
                          f"script_name='{script_name}' (expected one matching {rel})")
        elif gs_version != seed_version:
            errors.append(f"{rel}'s version const is '{gs_version}' but "
                          f"bigquery/43_script_version_registry.sql's seed for '{script_name}' "
                          f"expects '{seed_version}' — bump the seed in the SAME commit that bumps "
                          f"the .gs version const")

    if errors:
        print("SCRIPT VERSION CONSISTENCY: FAIL\n")
        for e in errors:
            print(" - " + e)
        return 1
    print(f"SCRIPT VERSION CONSISTENCY: OK — {len(SCRIPTS)} script(s) agree with "
          f"bigquery/43_script_version_registry.sql's seed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
