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

ROSTER-ACTIVE definition matches check_roster_consistency.py's R-A exactly: both key on roster_state IN
{probe, adopted} (scripts/lib/roster_common.py's ACTIVE_STATES_YAML), and R-A compares that against
ACTIVE_STATES_SQL = {PROBE, ADOPTED} parsed from the bigquery/35 seed, which genuinely is the same set.
We parse roster.yaml independently here (a self-contained parse — we deliberately do NOT import
check_roster_consistency.py, which another agent owns) so this check has no coupling to that file.

THE LIVE SIDE IS NOT THAT SET, and this paragraph used to claim it was (corrected 2026-09-04: it
asserted "roster_state IN {probe, adopted} == state.strategy_roster.is_active ==
PROBE|ADOPTED|RETIREMENT_PROPOSED via bigquery/70" — an equality chain whose two ends are unequal).
live_active_codes() reads state.active_strategy_codes, i.e. state.strategy_roster WHERE is_active, and
bigquery/70_retirement_proposed_is_active.sql deliberately WIDENED is_active to
PROBE|ADOPTED|RETIREMENT_PROPOSED ("a retirement PROPOSAL is default-KEEP and must not drop the strategy
out of this enumeration mid-review"). So the two sets are equal only while NO strategy sits in
RETIREMENT_PROPOSED. Unreachable today (all five roster.yaml entries are roster_state: adopted; zero
retirement proposals to date), which is why nothing is being changed here now — but retirement_proposed
IS a legal roster_state per strategy/roster.yaml's own domain list, and SL5 is its sole writer, so the
day SL5 writes it this check will print "LIVE but NOT in roster.yaml" for a designed, HEALTHY state.
WHEN THAT HAPPENS: widen the roster-active set for THIS CALLER ONLY, at roster_active_codes() below —
do NOT widen ACTIVE_STATES_YAML in scripts/lib/roster_common.py (it is SHARED with R-A, whose repo-side
set must keep matching the bigquery/35 seed's {PROBE, ADOPTED} or that gate breaks), and do NOT take the
"update strategy/roster.yaml to match live" half of main()'s reconcile advice, which would corrupt the
roster by rewriting a lifecycle state SL5 owns.

EXIT: 0 = live active set == roster.yaml active set. 1 = drift (symmetric difference printed), OR a
live-query/auth failure (FAIL CLOSED — a safety parity check must never report OK on zero real
comparison; the workflow gates this step behind the WIF guard, so a failure here is a real problem, not
an expected 'creds absent' skip). If strategy/roster.yaml is ABSENT (a pre-2026-07-10 checkout) every
check is SKIPPED cleanly (green), mirroring check_roster_consistency.py.

Usage:  python scripts/check_live_roster_parity.py [--project stock-trading-498512]
"""
import argparse
import os
import sys

from lib.bq_json import run_bq_query
from lib.textio import load_yaml
from lib.roster_common import roster_active_codes as _roster_active_codes_for_doc

try:
    # This module's own read now goes through lib.textio.load_yaml() (2026-07-29 textio adoption), so
    # `yaml` is not referenced directly below, but the import stays as the fail-fast "pip install pyyaml"
    # guard (same pattern as check_roster_consistency.py / check_autonomy_consistency.py).
    import yaml  # noqa: F401
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROSTER = os.path.join(ROOT, "strategy", "roster.yaml")


def bq(sql, project):
    """Run a read-only query and return a list of dict rows (dbt_parity.py's bq() pattern:
    --format=json + --quiet/--headless to suppress banner noise, 600s timeout so a stalled CLI call
    can't hang the CI job). Delegates to lib/bq_json.py's run_bq_query — the shared invoke wrapper
    this module's copy was consolidated into (2026-07-18 dedup-sweep audit)."""
    return run_bq_query(sql, project, max_rows=100000)


def roster_active_codes():
    """strategy/roster.yaml strategies[].code where roster_state in {probe, adopted}. Thin wrapper
    around lib/roster_common.py's doc-based core (roster-group audit, 2026-08-08 dedup — this
    function and ACTIVE_STATES_YAML were byte-identical copies of check_roster_consistency.py's,
    down to a stale KeyError on a roster.yaml entry missing 'code'). Kept as a local no-arg wrapper
    (rather than importing roster_active_codes directly) so this module's ROSTER path constant stays
    the thing tests monkeypatch — see tests/test_check_live_roster_parity.py's ROSTER-repoint tests."""
    return _roster_active_codes_for_doc(load_yaml(ROSTER))


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
    except Exception as e:  # noqa: BLE001 - fail closed: a parity check must never report OK on zero real comparison
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
        # Named suspect, not a new check: the live is_active enumeration is WIDER than roster.yaml's
        # roster-active set by exactly RETIREMENT_PROPOSED (bigquery/70) — see this module's docstring.
        # Rule that out FIRST, because for that case the reconcile advice below is actively wrong.
        print("    Check roster_state for these codes before reconciling: a code sitting in "
              "retirement_proposed is LIVE-active by design (bigquery/70 widened is_active so a "
              "default-KEEP retirement proposal does not drop it mid-review) and is NOT drift — the fix "
              "there is to widen roster_active_codes() for this caller, never to edit strategy/roster.yaml.")
    print("\nReconcile: re-apply the roster-derived lifecycle transition (BigQuery MCP) OR update "
          "strategy/roster.yaml to match live, so the checked-in policy source of truth and the live "
          "roster the derived NAV/sizing SQL reads agree. See ops/RUNBOOK.md §39 (SISA) and the "
          "INSERT-aware safety_critical_dml_watch (bigquery/75).")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
