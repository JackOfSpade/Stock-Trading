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

Run AFTER `dbt compile` (the CI job does that), from the repo root. Running it by hand? clear
`dbt/target` first (`dbt clean`): that directory is git-ignored and `dbt compile` does not purge
it, so artifacts of models the repo no longer has survive there and used to be compared as if
they were ported models — see compiled_models()' ORPHAN GUARD. They are now skipped and counted. Requires the `bq` CLI authed
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
import concurrent.futures
import os
import subprocess  # noqa: F401 — kept so tests can monkeypatch subprocess.run/TimeoutExpired at the module level
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.bq_json import run_bq_query
from lib.sql_files import DBT_DATASETS
from lib.textio import read_text

PROJECT = "stock-trading-498512"
COMPILED_ROOT = os.path.join("dbt", "target", "compiled", "stock_trading", "models")
# DEDUP (sql-parity#0, 2026-08-31 code-quality pass): this used to be its own locally-declared
# tuple, `("state", "perf", "analytics")`, duplicating check_dbt_view_coverage.py's `DATASETS` —
# same three datasets, different name, different order, unconsolidated. Now shared via
# scripts/lib/sql_files.py's DBT_DATASETS (see that module's docstring for why the ELEMENT ORDER
# is load-bearing here: compiled_models() drives this tuple as the model-processing order, and
# main() aggregates the printed skipped/errors/diffs lists in that same order for a deterministic
# report — DBT_DATASETS preserves this file's original order for exactly that reason). Kept under
# the local name DATASET_FOLDERS (folder name == BigQuery dataset) rather than importing
# DBT_DATASETS bare, since every use site below already reads that name and tests/test_dbt_parity.py
# (out of scope for this pass) asserts against `dp.DATASET_FOLDERS`.
DATASET_FOLDERS = DBT_DATASETS
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
# THIRD OCCURRENCE OF THE SAME CLASS (2026-08-09): a missing column does NOT always say "Unrecognized
# name". When the reference is ALIAS-QUALIFIED against a subquery — which is exactly the shape this
# module builds (`SELECT <col> FROM (compiled) AS parity_src`) — BigQuery instead says
# "Name <col> not found inside <alias>". That phrasing matched none of the markers above, so
# state.book_drawdown_watch (missing peak_window_gap_days, added live by bigquery/153/155) was routed
# to a tolerant SKIP and counted as a pass. That run only went red because an UNRELATED model
# (analytics.account_reconciliation) happened to drift the same day; without that coincidence this
# module would have printed "OK: every compared dbt model matches its live view row-for-row" and
# exited 0 while a trading-gate-adjacent view went silently unverified. Note the failure mode is
# per-model and partial: main()'s `checked == 0` guard only catches a TOTAL skip (systemic bq/auth
# outage), never a single genuinely-broken model among many.
SCHEMA_DRIFT_MARKERS = ("unrecognized name", "not found inside", "set operations", "not groupable",
                        "no matching signature", "does not have a column", "incompatible types")

# Client-side concurrency for the per-model parity queries (owner-authorized 2026-07-30, Actions cost
# audit). The 43 parity queries are one bq job each and cannot be batched (see main()), so the only
# remaining lever is running them concurrently. This does NOT change the per-run BigQuery JOB COUNT — it
# only compresses those same jobs in time.
#
# WHY THIS NEEDED AUTHORIZATION, and why the ceiling below is not decoration: this job's BigQuery job
# volume tripped the project's Data Transfer Service consumer rate-quota on 2026-06-29, which delayed the
# 05:00-06:00 scheduled window and FAILED the embed + integrity scheduled-query runs. Every mitigation
# since then REDUCED job count (the bigquery/**|dbt/** path gate; halving to one combined query per
# model; batching the metadata into a single job). Concurrency is the first change that moves the other
# way on instantaneous rate, so it is deliberately conservative and overridable WITHOUT a code change:
# set DBT_PARITY_CONCURRENCY=1 to restore fully serial behavior if the quota is ever pressured again.
DEFAULT_PARITY_CONCURRENCY = 4
MAX_PARITY_CONCURRENCY = 16


def parity_concurrency():
    """Worker count for the per-model parity loop: DBT_PARITY_CONCURRENCY, else 4.

    Clamped to [1, MAX_PARITY_CONCURRENCY] and fully tolerant of a malformed value (empty, non-numeric,
    negative) — a typo'd env var must not crash a CI gate, and must NEVER silently widen concurrency
    beyond the ceiling given the 2026-06-29 rate-quota incident. 1 = serial (the pre-2026-07-30 path)."""
    raw = (os.environ.get("DBT_PARITY_CONCURRENCY") or "").strip()
    try:
        n = int(raw) if raw else DEFAULT_PARITY_CONCURRENCY
    except ValueError:
        n = DEFAULT_PARITY_CONCURRENCY
    return max(1, min(n, MAX_PARITY_CONCURRENCY))


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
    if dtype == "JSON" or dtype.startswith(("ARRAY", "STRUCT")):
        return f"TO_JSON_STRING({q})"
    if dtype == "GEOGRAPHY" or dtype == "INTERVAL" or dtype.startswith("RANGE"):
        return f"SAFE_CAST({q} AS STRING)"
    return q


def live_columns(dataset, table):
    """Per-model column lookup — ONE bq job per model. Retained as the FALLBACK path for
    live_columns_all() (and as the seam most unit tests patch); see that function."""
    return bq(
        f"SELECT column_name, data_type FROM `{PROJECT}`.{dataset}.INFORMATION_SCHEMA.COLUMNS "
        f"WHERE table_name = '{table}' ORDER BY ordinal_position"
    )


def live_columns_all():
    """Every column of every object in DATASET_FOLDERS in ONE bq job ->
    {(dataset, table): [{'column_name': .., 'data_type': ..}, ...]} in ordinal_position order.

    COST (2026-07-30 Actions audit): live_columns() was called once PER MODEL, so the 43 ported models
    cost 43 sequential bq CLI invocations. Measured against live: 43 per-model queries = 70.92s vs this
    single batched query = 1.50s, with the resulting column lists **43/43 byte-identical** (verified by
    an explicit old-vs-new equivalence diff, not by inspection — the same discipline that caught the
    100-row-cap bug in check_live_sql_parity.py the same day). A single-table INFORMATION_SCHEMA query
    and this whole-dataset one both cost ~1.7s, because the cost here is per-INVOCATION, not per-row.

    Returns None — meaning "unusable, use the per-model path" — on ANY exception OR on a row shape that
    lacks the expected keys. main() then falls back to live_columns() per model, preserving every
    audited error-routing guarantee exactly (a missing dataset errors the batch and falls back rather
    than mass-reporting 43 models as broken). A model ABSENT from a SUCCESSFUL batch correctly yields
    [] — the batch covers every table in the dataset, so absence means the object does not exist, which
    is the same signal live_columns()'s zero-row return carries and routes to the same fail-closed
    "deleted or renamed" branch.

    ROW CAP: bq() passes max_rows=100000 against 1,400 total columns across state+perf+analytics as of
    2026-07-30 — 71x headroom. This matters because `bq query` defaults to only 100 rows, and on the same
    day that exact default silently truncated check_live_sql_parity.py's batched query (111 views ->
    100 returned) and reported the 11 absent objects as MISSING. Here the analogous failure is
    fail-CLOSED, not a silent pass: a truncated batch makes real models look ABSENT, which routes to the
    "deleted or renamed" error branch and reddens CI. Do not lower max_rows.

    NOTE: batching the PARITY queries the same way was tested and REJECTED (2026-07-30) — see main().
    """
    unions = " UNION ALL ".join(
        f"SELECT '{ds}' AS ds, table_name, column_name, data_type, ordinal_position "
        f"FROM `{PROJECT}`.{ds}.INFORMATION_SCHEMA.COLUMNS"
        for ds in DATASET_FOLDERS
    )
    try:
        rows = bq(f"{unions} ORDER BY ds, table_name, ordinal_position")
    except Exception:  # noqa: BLE001 - "unusable, fall back to the per-model path" per this function's docstring above
        return None
    out = {}
    for r in rows:
        try:
            out.setdefault((r["ds"], r["table_name"]), []).append(
                {"column_name": r["column_name"], "data_type": r["data_type"]}
            )
        except (TypeError, KeyError, IndexError):
            return None   # unexpected row shape — do not guess, fall back to the per-model path
    return out or None


def compiled_artifacts():
    """Every .sql under COMPILED_ROOT/<dataset>, unfiltered — what `dbt compile` has LEFT ON DISK,
    which is not the same thing as what this repo currently ports. Kept separate from
    compiled_models() so the orphan count below can be reported rather than silently swallowed."""
    for dataset in DATASET_FOLDERS:
        d = os.path.join(COMPILED_ROOT, dataset)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if fn.endswith(".sql"):
                yield dataset, fn[:-4], read_text(os.path.join(d, fn)).strip().rstrip(";")


def compiled_models():
    """The compiled artifacts that correspond to a dbt model SOURCE file that still exists.

    ORPHAN GUARD (2026-09-01 audit). dbt/target/ is git-ignored and `dbt compile` does NOT purge it,
    so a compiled artifact outlives the model file it came from. This function used to yield every
    .sql on disk, so each orphan was compared against its live view as if it were a ported model —
    and since the orphan's SQL is frozen at whatever the model said when it was last compiled, any
    later legitimate redefinition of that live view shows up as FABRICATED DRIFT. Measured in one
    working checkout: 187 compiled artifacts vs 84 with a source file, and 5 of the 103 orphans
    reported drift purely because bigquery/200-203 had redefined their live views after the stale
    compile (state.web_call_coverage: dbt-only 457 rows vs live 159).

    This CANNOT weaken the fail-closed posture: an artifact with no source file is provably not a
    ported model, so dropping it removes a fabricated comparison, never a real one. The genuine
    partial-compile guard is the OPPOSITE direction — sources with no artifact — and main()'s
    `uncompiled` check still enforces that, now more accurately because compiled_names no longer
    counts orphans toward coverage.

    CI is structurally immune (dbt/.gitignore ships `target/` and actions/checkout is clean), so this
    only ever bit an interactive full-suite verification run — which is exactly the run an agent
    trusts when it reports "dbt_parity 0 drift"."""
    sources = model_source_names()
    for dataset, name, sql in compiled_artifacts():
        if (dataset, name) in sources:
            yield dataset, name, sql


def orphan_compiled_artifacts():
    """{(dataset, name)} compiled under COMPILED_ROOT with no surviving dbt/models/ source file.
    Reported by main() so a stale dbt/target/ is visible instead of silently shrinking coverage."""
    sources = model_source_names()
    return {(ds, nm) for ds, nm, _sql in compiled_artifacts() if (ds, nm) not in sources}


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


def check_one_model(dataset, name, compiled, batch_cols):
    """Compare ONE dbt model against its live view. Returns a (kind, detail) tuple where kind is one of
    'ok' | 'drift' | 'skipped' | 'error' — it never mutates shared state and never prints.

    Extracted from main()'s loop body (2026-07-30) so the loop can run concurrently: with shared
    accumulator lists the workers would race, and — more subtly — the ORDER of `skipped`/`errors`/`diffs`
    would follow completion order, making CI output nondeterministic run to run. main() aggregates these
    return values in model order instead, so the printed report is byte-identical to the serial version.
    The routing of every case (tolerant skip vs fail-closed error) is unchanged from the serial code."""
    live = f"`{PROJECT}`.{dataset}.{name}"
    try:
        # A model MISSING from a successful batch yields [] — the same "object does not exist"
        # signal live_columns() returns as zero rows, routed to the same fail-closed branch below.
        raw_cols = (batch_cols.get((dataset, name), [])
                    if batch_cols is not None else live_columns(dataset, name))
    except Exception as e:  # noqa: BLE001 - any metadata-lookup failure here is tolerated as a skip, not a drift finding
        return ("skipped", f"{dataset}.{name} (no live object? {e})")
    if not raw_cols:
        # BigQuery's INFORMATION_SCHEMA.COLUMNS does NOT error on a `table_name` filter that
        # matches nothing — it just returns zero rows, so a live view that was deleted or
        # renamed looks identical, by row count alone, to "the view exists but every column is
        # volatile" below. That's the exact 'OK on zero real comparisons' hazard this module's
        # docstring warns against, just triggered per-model instead of project-wide — fail
        # closed and name the missing object, instead of routing to the tolerant skip meant for
        # the genuinely-benign all-volatile case (2026-07-20 audit).
        return ("error", f"{dataset}.{name} (0 columns returned for live object {live} — it was "
                         f"likely deleted or renamed)")
    cols = [c for c in raw_cols if c["column_name"] not in VOLATILE_COLS]
    if not cols:
        return ("skipped", f"{dataset}.{name} (no comparable columns)")
    exprs = ", ".join(col_expr(c) for c in cols)
    try:
            # ONE combined query (2 scalar EXCEPT-DISTINCT subqueries) instead of 2 separate bq
            # jobs per model — this job's BigQuery job volume already tripped the project's DTS
            # consumer rate-quota once (2026-06-29 CI incident); halving it directly reduces
            # recurrence risk (2026-07-14 audit finding).
            # Both sides carry the SAME alias (PARITY_ALIAS), so the identical `exprs` string is valid
            # against the compiled subquery and the live view alike.
            #
            # DO NOT BATCH THESE ACROSS MODELS — tested against live and REJECTED (2026-07-30 Actions
            # cost audit). Batching the metadata lookups was a 47x win (see live_columns_all()), so the
            # obvious next step was to UNION ALL these per-model parity SELECTs into fewer jobs. Measured,
            # it fails twice over:
            #   * all 43 in one query (268,589 chars) -> BigQuery "Resources exceeded during query
            #     execution". Not a size-limit issue (the 1 MB query cap is not reached) — 86 EXCEPT
            #     DISTINCT subqueries in one job exhaust execution resources.
            #   * chunked, it is SLOWER than the per-model loop it replaces: 43 models took 226.1s
            #     per-model vs 276.4s in chunks of 15 and 245.8s in chunks of 10 — and one chunk still
            #     failed outright in BOTH chunkings. Slot contention inside a single job outweighs the
            #     saved bq CLI invocations, because unlike the metadata queries these subqueries do real
            #     work over the live views.
            # The remaining lever was CONCURRENCY, not batching, and that is what shipped instead:
            # main() runs these per-model queries through a small thread pool (owner-authorized
            # 2026-07-30). Job COUNT is unchanged; only the instantaneous rate rises. See
            # parity_concurrency() for the ceiling and the DBT_PARITY_CONCURRENCY=1 escape hatch.
        row = bq(
            f"SELECT "
            f"(SELECT COUNT(*) FROM (SELECT {exprs} FROM ({compiled}) AS {PARITY_ALIAS} "
            f"EXCEPT DISTINCT SELECT {exprs} FROM {live} AS {PARITY_ALIAS})) AS n_missing, "
            f"(SELECT COUNT(*) FROM (SELECT {exprs} FROM {live} AS {PARITY_ALIAS} "
            f"EXCEPT DISTINCT SELECT {exprs} FROM ({compiled}) AS {PARITY_ALIAS})) AS n_extra"
        )[0]
        n_missing, n_extra = int(row["n_missing"]), int(row["n_extra"])
    except Exception as e:  # noqa: BLE001 - routed below to error (schema-shaped) or skip (transient); see comment
        # A parity-query error AFTER live_columns() succeeded is, for a schema-shaped cause, real
        # drift (not a transient hiccup) — fail closed instead of swallowing it as a skip that
        # lets the drift pass green (2026-07-17 audit). Anything else stays a tolerant skip.
        if any(marker in str(e).lower() for marker in SCHEMA_DRIFT_MARKERS):
            return ("error", f"{dataset}.{name} (parity query failed on a schema-shaped error — the "
                             f"dbt port likely lacks a column its live view has, or a column type "
                             f"can't be EXCEPT-compared: {e})")
        return ("skipped", f"{dataset}.{name} (query error: {e})")
    if n_missing or n_extra:
        return ("drift", f"{dataset}.{name}: dbt-only={n_missing} live-only={n_extra} rows")
    return ("ok", None)


def main():
    diffs, skipped, errors, checked = [], [], [], 0
    models = list(compiled_models())
    total = len(models)
    compiled_names = {(dataset, name) for dataset, name, _ in models}
    # Stale dbt/target/ artifacts are skipped, not compared (see compiled_models()). Say so out loud:
    # a silent skip would read identically to "there was nothing there", and the whole point of the
    # guard is that the operator can see the local tree is stale and re-run `dbt clean && dbt compile`.
    orphans = orphan_compiled_artifacts()
    if orphans:
        print(f"NOTE: skipped {len(orphans)} compiled artifact(s) under {COMPILED_ROOT} with no dbt/models/ "
              f"source file (stale dbt/target/ — `dbt clean` then re-`dbt compile` to clear). These are NOT "
              f"ported models and comparing them would fabricate drift against legitimately-redefined live "
              f"views: " + ", ".join(f"{ds}.{nm}" for ds, nm in sorted(orphans)[:8])
              + (f", +{len(orphans) - 8} more" if len(orphans) > 8 else ""))
    # ONE batched metadata job for all models instead of one per model (2026-07-30 Actions cost audit;
    # 70.9s -> 1.5s, proven 43/43 equivalent — see live_columns_all()). None = batch unusable, in which
    # case every model falls back to the original per-model live_columns() call inside the worker.
    # Skipped entirely when there are no models, so the total==0 / no-sources guards cost no BigQuery job.
    batch_cols = live_columns_all() if models else None

    # Run the per-model comparisons concurrently (owner-authorized 2026-07-30 — see parity_concurrency()
    # for the rate-quota history that makes this deliberately conservative and env-overridable). Results
    # are collected POSITIONALLY and aggregated below in model order, so the printed report does not
    # depend on completion order — a nondeterministic report would be unreviewable in CI and would make
    # log diffs between runs meaningless.
    workers = min(parity_concurrency(), total) if total else 0
    results = [None] * total
    if workers > 1:
        with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
            futures = {pool.submit(check_one_model, d, n, c, batch_cols): i
                       for i, (d, n, c) in enumerate(models)}
            for fut in concurrent.futures.as_completed(futures):
                i = futures[fut]
                try:
                    results[i] = fut.result()
                except Exception as e:  # noqa: BLE001 - an unexpected worker failure must fail closed, not abort the batch; see comment
                    # check_one_model catches its own expected failures, so reaching here means an
                    # UNEXPECTED bug. Fail closed as an error (never a tolerant skip) but keep going, so
                    # the report still covers every other model instead of dying on the first surprise.
                    dataset, name, _ = models[i]
                    results[i] = ("error", f"{dataset}.{name} (unexpected worker failure: {e})")
    else:
        for i, (dataset, name, compiled) in enumerate(models):
            results[i] = check_one_model(dataset, name, compiled, batch_cols)

    # CONCURRENCY SAFETY NET (2026-07-30, added with the thread pool above — do not drop it if the pool
    # stays). A transient failure routes to the TOLERANT `skipped` bucket, and a skipped model still lets
    # main() report OK so long as some other model compared. So without this, raising concurrency could
    # quietly REDUCE COVERAGE (auth-token refresh contention or a rate-limit blip skipping N models) while
    # still exiting 0 — the precise "OK on fewer real comparisons" hazard this module's docstring is built
    # to prevent, reintroduced one model at a time. Re-run every skipped model ONCE, serially, and keep
    # the retry whenever it produced a verdict (including a fail-closed `error`). Costs nothing in the
    # normal all-clean case because there are no skips, and the deterministic skip reasons ("no comparable
    # columns") simply return the same answer again without issuing a query.
    if workers > 1:
        for i, (kind, _) in enumerate(results):
            if kind != "skipped":
                continue
            dataset, name, compiled = models[i]
            retry = check_one_model(dataset, name, compiled, batch_cols)
            if retry[0] != "skipped":
                results[i] = retry

    for kind, detail in results:
        if kind == "skipped":
            skipped.append(detail)
        elif kind == "error":
            errors.append(detail)
        elif kind == "drift":
            checked += 1
            diffs.append(detail)
        else:
            checked += 1

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
