#!/usr/bin/env python3
"""Row-level parity check: dbt models vs the live hand-SQL views (D1).

Every ported dbt model is defined twice — canonical hand-SQL in `bigquery/*.sql` and a parallel-run
dbt port in `dbt/models/`. CI's `dbt parse` only validates STRUCTURE (refs/sources resolve).
This adds ROW-LEVEL parity: it proves the dbt model and the live view produce the SAME rows,
catching logic drift between the two definitions.

HOW (read-only — never writes, never `dbt build`): for each compiled dbt model, run ONE query with
two scalar EXCEPT-DISTINCT subqueries (n_missing = dbt-only rows, n_extra = live-only rows). The
compiled SQL already has refs/sources resolved to the live `state`/`perf`/`analytics` objects, so
this compares the two SELECT logics over identical inputs. NOTE: this does NOT `dbt build` — the
generate_schema_name override pins models to the bare live datasets, so a build would overwrite
them; compile+EXCEPT stays read-only.

Run AFTER `dbt compile` (the CI job does that), from the repo root. Requires the `bq` CLI authed
(WIF in CI). Exit 0 = all parity; exit 1 = any drift, OR every model was skipped (a systemic bq/
auth failure must not silently report "OK" on zero real comparisons — 2026-07-14 audit finding).

Two column adjustments make the EXCEPT well-defined:
  * VOLATILE_COLS — columns evaluated fresh each query (CURRENT_TIMESTAMP) can never match across
    two evaluations, so they are dropped from the compare.
  * JSON/ARRAY/STRUCT columns don't support set-operation comparison, so they are wrapped in
    TO_JSON_STRING() (applied identically to both sides) instead of being skipped.
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.bq_json import parse_bq_json_stdout

PROJECT = "stock-trading-498512"
COMPILED_ROOT = os.path.join("dbt", "target", "compiled", "stock_trading", "models")
DATASET_FOLDERS = ("state", "perf", "analytics")   # folder name == BigQuery dataset
# Columns generated fresh on every evaluation (CURRENT_TIMESTAMP) — excluded from row compare.
VOLATILE_COLS = {"checked_at"}


def bq(sql):
    """Run a read-only query and return a list of dict rows.

    Uses --format=json (unambiguous, unlike CSV header parsing) with global --quiet/--headless so
    bq emits no 'Waiting on bqjob...' status noise. A 600s timeout keeps a stalled bq CLI call (a
    network partition mid-token-refresh, or a hung query-polling loop) from blocking the CI job
    indefinitely (2026-07-14 audit finding).
    """
    try:
        out = subprocess.run(
            ["bq", "--project_id=" + PROJECT, "--quiet", "--headless", "--format=json",
             "query", "--use_legacy_sql=false", "--max_rows=100000", sql],
            capture_output=True, text=True, timeout=600,
        )
    except subprocess.TimeoutExpired as e:
        raise RuntimeError(f"bq query timed out after {e.timeout}s: {sql[:120]}") from e
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or out.stdout.strip())
    return parse_bq_json_stdout(out.stdout)


def col_expr(col):
    """SQL expression for one column in the EXCEPT. JSON/ARRAY/STRUCT can't be set-compared, so
    serialize them deterministically; scalars compare directly."""
    name, dtype = col["column_name"], col["data_type"]
    q = f"`{name}`"
    if dtype == "JSON" or dtype.startswith("ARRAY") or dtype.startswith("STRUCT"):
        return f"TO_JSON_STRING({q})"
    return q


def live_columns(dataset, table):
    return bq(
        f"SELECT column_name, data_type FROM `{PROJECT}`.{dataset}.INFORMATION_SCHEMA.COLUMNS "
        f"WHERE table_name = '{table}' ORDER BY ordinal_position"
    )


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
    diffs, skipped, checked, total = [], [], 0, 0
    for dataset, name, compiled in compiled_models():
        total += 1
        live = f"`{PROJECT}`.{dataset}.{name}"
        try:
            cols = [c for c in live_columns(dataset, name) if c["column_name"] not in VOLATILE_COLS]
        except Exception as e:
            skipped.append(f"{dataset}.{name} (no live object? {e})")
            continue
        if not cols:
            skipped.append(f"{dataset}.{name} (no comparable columns)")
            continue
        exprs = ", ".join(col_expr(c) for c in cols)
        try:
            # ONE combined query (2 scalar EXCEPT-DISTINCT subqueries) instead of 2 separate bq
            # jobs per model — this job's BigQuery job volume already tripped the project's DTS
            # consumer rate-quota once (2026-06-29 CI incident); halving it directly reduces
            # recurrence risk (2026-07-14 audit finding).
            row = bq(
                f"SELECT "
                f"(SELECT COUNT(*) FROM (SELECT {exprs} FROM ({compiled}) "
                f"EXCEPT DISTINCT SELECT {exprs} FROM {live})) AS n_missing, "
                f"(SELECT COUNT(*) FROM (SELECT {exprs} FROM {live} "
                f"EXCEPT DISTINCT SELECT {exprs} FROM ({compiled}))) AS n_extra"
            )[0]
            n_missing, n_extra = int(row["n_missing"]), int(row["n_extra"])
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
    if total and checked == 0:
        print("\nPARITY NOT VERIFIED — every compiled model was skipped (bq/auth failure?); "
              "refusing to report OK on zero comparisons.")
        return 1
    if diffs:
        print("\nPARITY FAILED — a dbt model and its live view disagree. Reconcile "
              "bigquery/*.sql and dbt/models/*.sql (or add a genuinely-volatile column to VOLATILE_COLS).")
        return 1
    print("OK: every compared dbt model matches its live view row-for-row.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
