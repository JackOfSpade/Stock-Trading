#!/usr/bin/env python3
"""Row-level parity check: dbt models vs the live hand-SQL views (D1).

The 22 views are defined twice — canonical hand-SQL in `bigquery/*.sql` and a parallel-run
dbt port in `dbt/models/`. CI's `dbt parse` only validates STRUCTURE (refs/sources resolve).
This adds ROW-LEVEL parity: it proves the dbt model and the live view produce the SAME rows,
catching logic drift between the two definitions.

HOW (read-only — never writes, never `dbt build`): for each compiled dbt model, run
    SELECT <cols> FROM (<compiled model SQL>) EXCEPT DISTINCT SELECT <cols> FROM `<live view>`
and the reverse. Both must return 0 rows. The compiled SQL already has refs/sources resolved to
the live `state`/`perf`/`analytics` objects, so this compares the two SELECT logics over identical
inputs. NOTE: this does NOT `dbt build` — the generate_schema_name override pins models to the bare
live datasets, so a build would overwrite them; compile+EXCEPT stays read-only.

Run AFTER `dbt compile` (the CI job does that), from the repo root. Requires the `bq` CLI authed
(WIF in CI). Exit 0 = all parity; exit 1 = any drift (prints the offending model + sample rows).

Volatile columns evaluated per-query (CURRENT_TIMESTAMP) can never match across two evaluations,
so they are excluded from the comparison (see VOLATILE_COLS).
"""
import json
import os
import subprocess
import sys

PROJECT = "stock-trading-498512"
COMPILED_ROOT = os.path.join("dbt", "target", "compiled", "stock_trading", "models")
DATASET_FOLDERS = ("state", "perf", "analytics")   # folder name == BigQuery dataset
# Columns generated fresh on every evaluation (CURRENT_TIMESTAMP) — excluded from row compare.
VOLATILE_COLS = {"checked_at"}


def bq(sql):
    """Run a read-only query and return a list of dict rows.

    Uses --format=json (unambiguous, unlike CSV header parsing) with global --quiet/--headless so
    bq emits no 'Waiting on bqjob...' status noise. As a belt-and-suspenders guard we still slice
    from the first JSON bracket in case any banner leaks to stdout.
    """
    out = subprocess.run(
        ["bq", "--project_id=" + PROJECT, "--quiet", "--headless", "--format=json",
         "query", "--use_legacy_sql=false", "--max_rows=100000", sql],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or out.stdout.strip())
    s = out.stdout.strip()
    i = s.find("[")
    return json.loads(s[i:]) if i != -1 else []


def live_columns(dataset, table):
    rows = bq(
        f"SELECT column_name FROM `{PROJECT}`.{dataset}.INFORMATION_SCHEMA.COLUMNS "
        f"WHERE table_name = '{table}' ORDER BY ordinal_position"
    )
    return [r["column_name"] for r in rows]


def compiled_models():
    for dataset in DATASET_FOLDERS:
        d = os.path.join(COMPILED_ROOT, dataset)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if fn.endswith(".sql"):
                with open(os.path.join(d, fn), encoding="utf-8") as f:
                    yield dataset, fn[:-4], f.read().strip().rstrip(";")


def main():
    diffs, skipped, checked = [], [], 0
    for dataset, name, compiled in compiled_models():
        live = f"`{PROJECT}`.{dataset}.{name}"
        try:
            cols = [c for c in live_columns(dataset, name) if c not in VOLATILE_COLS]
        except Exception as e:
            skipped.append(f"{dataset}.{name} (no live object? {e})")
            continue
        if not cols:
            skipped.append(f"{dataset}.{name} (no comparable columns)")
            continue
        collist = ", ".join(f"`{c}`" for c in cols)
        try:
            n_missing = int(bq(
                f"SELECT COUNT(*) AS n FROM (SELECT {collist} FROM ({compiled}) "
                f"EXCEPT DISTINCT SELECT {collist} FROM {live})")[0]["n"])
            n_extra = int(bq(
                f"SELECT COUNT(*) AS n FROM (SELECT {collist} FROM {live} "
                f"EXCEPT DISTINCT SELECT {collist} FROM ({compiled}))")[0]["n"])
        except Exception as e:
            skipped.append(f"{dataset}.{name} (query error: {e})")
            continue
        checked += 1
        if n_missing or n_extra:
            diffs.append(f"{dataset}.{name}: dbt-only={n_missing} live-only={n_extra} rows")

    print(f"dbt↔live parity: {checked} models compared, {len(skipped)} skipped, {len(diffs)} drifted.")
    for s in skipped:
        print(f"  - skipped {s}")
    for d in diffs:
        print(f"  ✗ DRIFT {d}")
    if diffs:
        print("\nPARITY FAILED — a dbt model and its live view disagree. Reconcile "
              "bigquery/*.sql and dbt/models/*.sql (or add a genuinely-volatile column to VOLATILE_COLS).")
        return 1
    print("OK: every compared dbt model matches its live view row-for-row.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
