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
    TO_JSON_STRING() (applied identically to both sides) instead of being skipped. GEOGRAPHY/
    INTERVAL/RANGE have the same set-operation problem but TO_JSON_STRING() doesn't accept them, so
    those are wrapped in SAFE_CAST(... AS STRING) instead (2026-07-20 audit).
"""
import os
import subprocess  # noqa: F401 — kept so tests can monkeypatch subprocess.run/TimeoutExpired at the module level
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.bq_json import run_bq_query
from lib.textio import read_text

PROJECT = "stock-trading-498512"
COMPILED_ROOT = os.path.join("dbt", "target", "compiled", "stock_trading", "models")
DATASET_FOLDERS = ("state", "perf", "analytics")   # folder name == BigQuery dataset
# Columns generated fresh on every evaluation (CURRENT_TIMESTAMP) — excluded from row compare.
VOLATILE_COLS = {"checked_at"}

# BigQuery error substrings that indicate a SCHEMA-SHAPED divergence rather than a transient/infra
# hiccup. live_columns() already succeeded (auth + object existence proven), so a subsequent parity-
# query error naming one of these is real drift `dbt parse` cannot catch — most commonly a dbt port
# that lacks a column its live view has (`SELECT <col> FROM (compiled)` -> "Unrecognized name"), a
# column type col_expr() doesn't yet know to serialize before the compare ("cannot be used in set
# operations" — col_expr() already covers the known offenders, JSON/ARRAY/STRUCT/GEOGRAPHY/INTERVAL/
# RANGE, so a genuinely-matching column of one of those no longer reaches this marker; a future
# BigQuery type col_expr() hasn't been taught yet still would), or a column whose TYPE DIFFERS
# between the dbt port and the live view so the two EXCEPT sides don't line up ("… has incompatible
# types: INT64, STRING" -> "incompatible types"; added 2026-07-17 parallel-refactor audit — a
# type-drifted column is exactly the schema drift `dbt parse` cannot catch, yet its error matched
# none of the other markers and so
# was mis-routed to a tolerant skip that passed green). These FAIL CLOSED (see main()'s `errors`)
# instead of being swallowed as a benign skip, which let schema drift pass green even in
# DBT_PARITY=block (2026-07-17 audit). A genuinely transient error (timeout, network, quota) matches
# none of these and still skips.
SCHEMA_DRIFT_MARKERS = ("unrecognized name", "set operations", "not groupable",
                        "no matching signature", "does not have a column", "incompatible types")


def bq(sql):
    """Run a read-only query and return a list of dict rows.

    Uses --format=json (unambiguous, unlike CSV header parsing) with global --quiet/--headless so
    bq emits no 'Waiting on bqjob...' status noise. A 600s timeout keeps a stalled bq CLI call (a
    network partition mid-token-refresh, or a hung query-polling loop) from blocking the CI job
    indefinitely (2026-07-14 audit finding). Delegates to lib/bq_json.py's run_bq_query — the
    shared invoke wrapper this module's copy was consolidated into (2026-07-18 dedup-sweep audit).
    """
    return run_bq_query(sql, PROJECT, max_rows=100000)


# Table alias applied to BOTH sides of every EXCEPT, so each selected column is referenced as
# `<alias>.<col>` rather than bare `<col>`.
#
# BUG FIX (2026-07-18): a bare `col` is AMBIGUOUS whenever a view's own name equals one of its column
# names. In `SELECT trading_enabled FROM <p>.state.trading_enabled`, BigQuery resolves the identifier
# to the TABLE's implicit range variable — i.e. the WHOLE ROW as a STRUCT — not to the BOOL column
# (verified live: it returned {"trading_enabled":true,"halt_reason":null}). The other EXCEPT side is an
# anonymous subquery `(<compiled>)`, which has no such range variable, so there the same identifier
# correctly resolved to the column. The two sides therefore disagreed on type and the parity query died
# with `Column 1 in EXCEPT DISTINCT has incompatible types: BOOL, STRUCT<trading_enabled BOOL,
# halt_reason STRING>`. Because "incompatible types" is a SCHEMA_DRIFT_MARKER, this fail-closed as
# NOT VERIFIED and red-lit CI — reporting phantom schema drift on a model whose dbt port and live view
# actually match column-for-column. Aliasing both sides makes every reference unambiguously a COLUMN.
# state.trading_enabled is the only such name collision in state/perf/analytics today, but the fix is
# structural so a future one can't reintroduce this.
PARITY_ALIAS = "parity_src"


def col_expr(col, alias=PARITY_ALIAS):
    """SQL expression for one column in the EXCEPT. JSON/ARRAY/STRUCT can't be set-compared, so
    serialize them deterministically via TO_JSON_STRING(). GEOGRAPHY/INTERVAL/RANGE have the same
    "cannot be used in set operations" problem but TO_JSON_STRING() doesn't accept them — BigQuery
    supports an explicit CAST to STRING for all three, so SAFE_CAST(... AS STRING) serializes those
    instead (SAFE_CAST so a value the cast can't handle yields NULL — which still compares — rather
    than erroring the whole query; 2026-07-20 audit). RANGE reports as `RANGE<DATE>` etc. in
    INFORMATION_SCHEMA.COLUMNS, not a bare `RANGE` literal, hence the prefix check. Scalars compare
    directly. Always alias-qualified — see PARITY_ALIAS for why a bare column reference is unsafe."""
    name, dtype = col["column_name"], col["data_type"]
    q = f"{alias}.`{name}`"
    if dtype == "JSON" or dtype.startswith("ARRAY") or dtype.startswith("STRUCT"):
        return f"TO_JSON_STRING({q})"
    if dtype == "GEOGRAPHY" or dtype == "INTERVAL" or dtype.startswith("RANGE"):
        return f"SAFE_CAST({q} AS STRING)"
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
                yield dataset, fn[:-4], read_text(os.path.join(d, fn)).strip().rstrip(";")


def model_source_names():
    """{(dataset, name)} for every dbt model SOURCE file under dbt/models/{state,perf,analytics} — the
    universe compiled_models() should reproduce. Lets main() distinguish 'no models ported yet'
    (legitimately OK when empty) from 'sources exist but compile emitted nothing, or only a SUBSET,
    under COMPILED_ROOT' (a stale path / renamed dbt project / partial `dbt compile` — breakage that
    must NOT report OK; 2026-07-17 audit + parallel-refactor partial-compile guard)."""
    names = set()
    for dataset in DATASET_FOLDERS:
        d = os.path.join("dbt", "models", dataset)
        if os.path.isdir(d):
            for fn in os.listdir(d):
                if fn.endswith(".sql"):
                    names.add((dataset, fn[:-4]))
    return names


def model_source_count():
    """Number of dbt model SOURCE files (== len(model_source_names())); see that function."""
    return len(model_source_names())


def main():
    diffs, skipped, errors, checked, total = [], [], [], 0, 0
    compiled_names = set()
    for dataset, name, compiled in compiled_models():
        total += 1
        compiled_names.add((dataset, name))
        live = f"`{PROJECT}`.{dataset}.{name}"
        try:
            raw_cols = live_columns(dataset, name)
        except Exception as e:
            skipped.append(f"{dataset}.{name} (no live object? {e})")
            continue
        if not raw_cols:
            # BigQuery's INFORMATION_SCHEMA.COLUMNS does NOT error on a `table_name` filter that
            # matches nothing — it just returns zero rows, so a live view that was deleted or
            # renamed looks identical, by row count alone, to "the view exists but every column is
            # volatile" below. That's the exact 'OK on zero real comparisons' hazard this module's
            # docstring warns against, just triggered per-model instead of project-wide — fail
            # closed and name the missing object, instead of routing to the tolerant skip meant for
            # the genuinely-benign all-volatile case (2026-07-20 audit).
            errors.append(f"{dataset}.{name} (0 columns returned for live object {live} — it was "
                          f"likely deleted or renamed)")
            continue
        cols = [c for c in raw_cols if c["column_name"] not in VOLATILE_COLS]
        if not cols:
            skipped.append(f"{dataset}.{name} (no comparable columns)")
            continue
        exprs = ", ".join(col_expr(c) for c in cols)
        try:
            # ONE combined query (2 scalar EXCEPT-DISTINCT subqueries) instead of 2 separate bq
            # jobs per model — this job's BigQuery job volume already tripped the project's DTS
            # consumer rate-quota once (2026-06-29 CI incident); halving it directly reduces
            # recurrence risk (2026-07-14 audit finding).
            # Both sides carry the SAME alias (PARITY_ALIAS), so the identical `exprs` string is valid
            # against the compiled subquery and the live view alike.
            row = bq(
                f"SELECT "
                f"(SELECT COUNT(*) FROM (SELECT {exprs} FROM ({compiled}) AS {PARITY_ALIAS} "
                f"EXCEPT DISTINCT SELECT {exprs} FROM {live} AS {PARITY_ALIAS})) AS n_missing, "
                f"(SELECT COUNT(*) FROM (SELECT {exprs} FROM {live} AS {PARITY_ALIAS} "
                f"EXCEPT DISTINCT SELECT {exprs} FROM ({compiled}) AS {PARITY_ALIAS})) AS n_extra"
            )[0]
            n_missing, n_extra = int(row["n_missing"]), int(row["n_extra"])
        except Exception as e:
            # A parity-query error AFTER live_columns() succeeded is, for a schema-shaped cause, real
            # drift (not a transient hiccup) — fail closed instead of swallowing it as a skip that
            # lets the drift pass green (2026-07-17 audit). Anything else stays a tolerant skip.
            if any(marker in str(e).lower() for marker in SCHEMA_DRIFT_MARKERS):
                errors.append(f"{dataset}.{name} (parity query failed on a schema-shaped error — the "
                              f"dbt port likely lacks a column its live view has, or a column type "
                              f"can't be EXCEPT-compared: {e})")
            else:
                skipped.append(f"{dataset}.{name} (query error: {e})")
            continue
        checked += 1
        if n_missing or n_extra:
            diffs.append(f"{dataset}.{name}: dbt-only={n_missing} live-only={n_extra} rows")

    print(f"dbt↔live parity: {checked} models compared, {len(skipped)} skipped, "
          f"{len(errors)} errored, {len(diffs)} drifted.")
    for s in skipped:
        print(f"  - skipped {s}")
    for er in errors:
        print(f"  ✗ NOT VERIFIED {er}")
    for d in diffs:
        print(f"  ✗ DRIFT {d}")
    if total == 0:
        # No compiled models discovered. That's legitimately OK only if nothing is ported yet;
        # if model SOURCES exist, COMPILED_ROOT is stale/renamed/empty and reporting OK would be the
        # same 'OK on zero real comparisons' vacuous pass the checked==0 guard below prevents, via a
        # different cause (2026-07-17 audit).
        if model_source_count() > 0:
            print("\nPARITY NOT VERIFIED — model sources exist under dbt/models/ but 0 compiled models "
                  "were found under COMPILED_ROOT (stale path / renamed dbt project / `dbt compile` "
                  "emitted nothing). Run `dbt compile` from dbt/ before this check.")
            return 1
        print("OK: no dbt models ported yet (0 compiled, 0 sources) — nothing to compare.")
        return 0
    if errors:
        # Checked BEFORE the generic checked==0 guard: a schema-shaped error is a more specific and
        # more actionable finding than "everything was skipped", and it fails closed either way.
        print("\nPARITY NOT VERIFIED — a parity query errored on a schema-shaped divergence (a dbt "
              "model missing a live column, or an un-comparable column type). This is real drift "
              "`dbt parse` cannot catch — reconcile the dbt model with its live view.")
        return 1
    if checked == 0:
        print("\nPARITY NOT VERIFIED — every compiled model was skipped (bq/auth failure?); "
              "refusing to report OK on zero comparisons.")
        return 1
    if diffs:
        print("\nPARITY FAILED — a dbt model and its live view disagree. Reconcile "
              "bigquery/*.sql and dbt/models/*.sql (or add a genuinely-volatile column to VOLATILE_COLS).")
        return 1
    # Partial-compile guard (checked last — everything that WAS compiled compared cleanly). A model
    # SOURCE with no compiled artifact was never verified at all, so reporting full parity would be the
    # same 'OK on zero real comparisons FOR THAT MODEL' vacuous pass the total==0 branch guards, one
    # model at a time. `dbt compile` is atomic today (a compile error fails the CI step before this
    # runs) and no model is disabled, so this normally can't fire — it is defense-in-depth against a
    # selective/partial compile. NOTE: a deliberately-disabled model (config enabled=false) has a
    # source file but no compiled artifact and would also surface here; none exist today, but if one is
    # added, exclude it from model_source_names() or declare it out of scope (2026-07-17 audit).
    uncompiled = sorted(model_source_names() - compiled_names)
    if uncompiled:
        print(f"\nPARITY NOT VERIFIED — {len(uncompiled)} dbt model source(s) under dbt/models/ have no "
              "compiled artifact under COMPILED_ROOT, so they were never compared (partial `dbt "
              "compile`?). Run a full `dbt compile` from dbt/ before this check:")
        for ds, nm in uncompiled:
            print(f"  - {ds}.{nm}")
        return 1
    print("OK: every compared dbt model matches its live view row-for-row.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
