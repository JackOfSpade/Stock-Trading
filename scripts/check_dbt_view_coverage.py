#!/usr/bin/env python3
"""Advisory check: which live state/analytics/perf VIEWs have neither a dbt model nor a declared
dbt source (2026-07-14 self-improvement audit finding).

WHY. scripts/dbt_parity.py only proves row-level parity for views that already HAVE a dbt model —
it has no way to notice a bigquery/*.sql view that was never ported or declared out-of-scope. A
reproducible count (this script) found 70 of 113 live state/analytics/perf views (62%) with no dbt
presence at all, including several pure-SELECT views feeding the autonomous Strategy Arsenal
lifecycle's readiness/kill gates that therefore have ZERO row-level parity protection. This is a
coverage gap, not a correctness bug: a view is legitimately "out of scope" if it depends on
ML.*/AI.*/VECTOR_SEARCH (dbt/README.md's own stated criterion for what dbt owns) or is procedure-
maintained — this script does not try to judge that; it only prints the uncovered list so a human
can triage "port it" vs "declare it out of scope" for each one.

Read-only, no BigQuery/dbt CLI needed — pure text parsing of files already in the repo.

Usage:  python scripts/check_dbt_view_coverage.py     # exit 0 if fully covered, 1 + list if not
Wired ADVISORY in .github/workflows/ci.yml's `dbt` job (never blocks CI/auto-merge) — there is no
baseline/allowlist here (unlike check_cadence/roster/autonomy_consistency.py), so it prints the full
backlog on every run until items are ported or explicitly declared out of scope.
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
BIGQUERY_DIR = os.path.join(ROOT, "bigquery")
DBT_MODELS_DIR = os.path.join(ROOT, "dbt", "models")
DBT_SOURCES_YML = os.path.join(ROOT, "dbt", "models", "sources.yml")

# dataset folder name == BigQuery dataset name, for both bigquery/*.sql views and dbt/models/*/*.sql.
DATASETS = ("state", "analytics", "perf")

VIEW_DDL = re.compile(
    r"CREATE\s+OR\s+REPLACE\s+VIEW\s+`stock-trading-498512\.(state|analytics|perf)\.(\w+)`",
    re.IGNORECASE,
)
DROP_VIEW_DDL = re.compile(
    r"DROP\s+VIEW\s+(?:IF\s+EXISTS\s+)?`stock-trading-498512\.(state|analytics|perf)\.(\w+)`",
    re.IGNORECASE,
)


def live_views():
    """(dataset, name) for every active VIEW across bigquery/*.sql in file-sorted order.
    A view created in an earlier file and dropped in a later file is not live."""
    found = set()
    for fn in sorted(os.listdir(BIGQUERY_DIR)):
        if not fn.endswith(".sql"):
            continue
        path = os.path.join(BIGQUERY_DIR, fn)
        if os.path.isdir(path):
            continue
        txt = open(path, encoding="utf-8").read()
        for dataset, name in VIEW_DDL.findall(txt):
            found.add((dataset, name))
        for dataset, name in DROP_VIEW_DDL.findall(txt):
            found.discard((dataset, name))
    return found


def dbt_model_names():
    """(dataset, name) for every dbt/models/<dataset>/*.sql model file (excluding schema.yml)."""
    found = set()
    for dataset in DATASETS:
        d = os.path.join(DBT_MODELS_DIR, dataset)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if fn.endswith(".sql"):
                found.add((dataset, fn[:-4]))
    return found


def dbt_source_names():
    """(dataset, name) for every table declared under a dbt source block whose (possibly-overridden)
    `dataset:` is one of state/analytics/perf."""
    found = set()
    doc = yaml.safe_load(open(DBT_SOURCES_YML, encoding="utf-8")) or {}
    for src in doc.get("sources", []) or []:
        dataset = src.get("dataset") or src.get("name")
        if dataset not in DATASETS:
            continue
        for tbl in src.get("tables", []) or []:
            name = tbl.get("name")
            if name:
                found.add((dataset, name))
    return found


def main():
    live = live_views()
    covered = dbt_model_names() | dbt_source_names()
    uncovered = sorted(live - covered)

    print(f"dbt view coverage: {len(live)} live state/analytics/perf views, "
          f"{len(covered)} dbt-covered (model or source), {len(uncovered)} uncovered.")
    if uncovered:
        print("\nUncovered (neither a dbt model nor a declared dbt source) — for each, either port "
              "it as a dbt model, or add it to dbt/models/sources.yml as an explicitly out-of-scope "
              "source (e.g. it depends on ML.*/AI.*/VECTOR_SEARCH, or is procedure-maintained):")
        for dataset, name in uncovered:
            print(f"  - {dataset}.{name}")
        return 1
    print("OK: every live state/analytics/perf view is either a dbt model or a declared dbt source.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
