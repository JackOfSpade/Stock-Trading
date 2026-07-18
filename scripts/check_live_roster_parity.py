#!/usr/bin/env python3
"""Live-vs-repo ROSTER parity: fail CI if state.active_strategy_codes drifts from strategy/roster.yaml.

WHY THIS EXISTS (MON H4, 2026-07-17 whole-system deep audit). scripts/check_roster_consistency.py
proves the roster is internally consistent ACROSS THE REPO (roster.yaml <-> the bigquery/35 seed <->
Strategy.md <-> slices <-> the plan slice-map). It does NOT compare against LIVE state — the actual set
of strategy codes state.active_strategy_codes returns in BigQuery right now. Those two can diverge
silently: an out-of-band events.strategy_lifecycle INSERT (the exact append-only mutation the
INSERT-aware safety_critical_dml_watch, bigquery/75, now flags detectively) can add or remove a live
active code with no repo commit, or a merged roster.yaml change can sit un-applied to live. Either way
the roster TRUTH the derived NAV/sizing SQL reads (state.active_strategy_codes -> bigquery/22/26 +
dbt strategy_nav) would no longer match the checked-in policy source of truth.

This is the roster analog of scripts/dbt_parity.py (live-vs-compiled) and lives alongside the daily
live-sql-parity job (.github/workflows/live-sql-parity.yml), which already has the read-only WIF SA +
`bq` CLI. Read-only: one SELECT, no writes.

ROSTER-ACTIVE definition matches check_roster_consistency.py's R-A exactly (roster_state IN
{probe, adopted} == state.strategy_roster.is_active == PROBE|ADOPTED|RETIREMENT_PROPOSED via bigquery/70;
the repo side keys on roster_state, the live side on the is_active view the same seed drives). We parse
roster.yaml independently here (a self-contained parse — we deliberately do NOT import
check_roster_consistency.py, which another agent owns) so this check has no coupling to that file.

EXIT: 0 = live active set == roster.yaml active set. 1 = drift (symmetric difference printed), OR a
live-query/auth failure (FAIL CLOSED — a safety parity check must never report OK on zero real
comparison; the workflow gates this step behind the WIF guard, so a failure here is a real problem, not
an expected 'creds absent' skip). If strategy/roster.yaml is ABSENT (a pre-2026-07-10 checkout) every
check is SKIPPED cleanly (green), mirroring check_roster_consistency.py.

Usage:  python scripts/check_live_roster_parity.py [--project stock-trading-498512]
"""
import argparse
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.bq_json import parse_bq_json_stdout

try:
    import yaml
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROSTER = os.path.join(ROOT, "strategy", "roster.yaml")
# roster_state values meaning is_active — IDENTICAL to check_roster_consistency.py's ACTIVE_STATES_YAML.
ACTIVE_STATES_YAML = {"probe", "adopted"}


def bq(sql, project):
    """Run a read-only query and return a list of dict rows (dbt_parity.py's bq() pattern:
    --format=json + --quiet/--headless to suppress banner noise, 600s timeout so a stalled CLI call
    can't hang the CI job)."""
    try:
        out = subprocess.run(
            ["bq", "--project_id=" + project, "--quiet", "--headless", "--format=json",
             "query", "--use_legacy_sql=false", "--max_rows=100000", sql],
            capture_output=True, text=True, timeout=600,
        )
    except subprocess.TimeoutExpired as e:
        raise RuntimeError(f"bq query timed out after {e.timeout}s") from e
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or out.stdout.strip())
    return parse_bq_json_stdout(out.stdout)


def roster_active_codes():
    """strategy/roster.yaml strategies[].code where roster_state in {probe, adopted}."""
    doc = yaml.safe_load(open(ROSTER, encoding="utf-8")) or {}
    return {s["code"] for s in doc.get("strategies", []) or []
            if str(s.get("roster_state", "")).lower() in ACTIVE_STATES_YAML}


def live_active_codes(project):
    rows = bq(f"SELECT strategy_code FROM `{project}`.state.active_strategy_codes "
              f"ORDER BY strategy_code", project)
    return {r["strategy_code"] for r in rows}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default="stock-trading-498512")
    args = ap.parse_args()

    if not os.path.exists(ROSTER):
        print("LIVE ROSTER PARITY: SKIP — strategy/roster.yaml absent (pre-2026-07-10 checkout). "
              "Nothing to compare.")
        return 0

    repo = roster_active_codes()
    try:
        live = live_active_codes(args.project)
    except Exception as e:
        # FAIL CLOSED: a safety parity check must never report OK on zero real comparison. The workflow
        # gates this step behind the WIF guard, so reaching here means creds were present but the live
        # read failed — a real problem, not an expected skip.
        print(f"LIVE ROSTER PARITY: NOT VERIFIED — could not read live state.active_strategy_codes "
              f"({e}). Refusing to report OK on zero comparison.")
        return 1

    if not repo and not live:
        # Zero-vs-zero is not a real comparison. roster.yaml is PRESENT here (the absent case SKIPed
        # above), so an empty roster-active set means zero probe/adopted codes — a violation of the SISA
        # N>=2 floor — and an empty live state.active_strategy_codes would starve the derived NAV/sizing
        # SQL (bigquery/22/26 + strategy_nav). Fail closed rather than report a vacuous OK on zero codes,
        # matching dbt_parity.py's total==0 NOT-VERIFIED guard and this file's own "never report OK on
        # zero real comparison" doctrine (MON H4).
        print("LIVE ROSTER PARITY: NOT VERIFIED — both strategy/roster.yaml's roster-active set and live "
              "state.active_strategy_codes are EMPTY. Refusing to report OK on a zero-vs-zero comparison: "
              "a present roster with zero probe/adopted codes violates the SISA N>=2 floor, and an empty "
              "live active set would starve the derived NAV/sizing SQL.")
        return 1

    if repo == live:
        print(f"LIVE ROSTER PARITY: OK — live state.active_strategy_codes == strategy/roster.yaml "
              f"roster-active set ({sorted(repo)}).")
        return 0

    only_repo = sorted(repo - live)
    only_live = sorted(live - repo)
    print("LIVE ROSTER PARITY: FAIL — live state.active_strategy_codes has drifted from "
          "strategy/roster.yaml's roster-active (probe/adopted) set.\n")
    if only_repo:
        print(f"  - in roster.yaml but NOT live (roster.yaml active, state.active_strategy_codes missing "
              f"— roster.yaml change not applied live, or an out-of-band lifecycle removal): {only_repo}")
    if only_live:
        print(f"  - LIVE but NOT in roster.yaml (state.active_strategy_codes active, roster.yaml not — an "
              f"out-of-band events.strategy_lifecycle INSERT, or a live roster add never mirrored to "
              f"roster.yaml): {only_live}")
    print("\nReconcile: re-apply the roster-derived lifecycle transition (BigQuery MCP) OR update "
          "strategy/roster.yaml to match live, so the checked-in policy source of truth and the live "
          "roster the derived NAV/sizing SQL reads agree. See ops/RUNBOOK.md §39 (SISA) and the "
          "INSERT-aware safety_critical_dml_watch (bigquery/75).")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
