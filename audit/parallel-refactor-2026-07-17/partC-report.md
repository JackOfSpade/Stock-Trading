# Part C — Shared libs + routines + parity/version tooling — refactor report (2026-07-17)

## Inventory of owned files

Part C owns two **shared libraries** — [`scripts/lib/bq_json.py`](../../scripts/lib/bq_json.py)
(`parse_bq_json_stdout`, imported by 6 call sites) and
[`scripts/lib/routine_manifest.py`](../../scripts/lib/routine_manifest.py) (`ROUTINE_SUFFIX`,
`heading_to_id`, `parse_routine_headings`, `build_triggers_manifest`, imported by 4) — plus six
standalone CLI drift-checkers: [`gen_routine_lists.py`](../../scripts/gen_routine_lists.py)
(generates the marker regions in bigquery/12/15/24), [`print_routines.py`](../../scripts/print_routines.py)
(reconstructs the trigger list + writes `ops/triggers.json`),
[`dbt_parity.py`](../../scripts/dbt_parity.py) and
[`check_live_sql_parity.py`](../../scripts/check_live_sql_parity.py) (two live-BigQuery parity gates,
run in dedicated WIF workflows — no creds in the sandbox, so their pytest coverage is the source of
truth), [`check_dbt_view_coverage.py`](../../scripts/check_dbt_view_coverage.py) (advisory coverage
count), and [`check_script_version_consistency.py`](../../scripts/check_script_version_consistency.py)
(.gs ↔ bigquery/43 version lockstep), with their five existing test files. The two libs are the
already-de-duplicated shared impl from the 2026-07-14 audit; interface byte-stability was my #1
priority and **neither lib was modified** (`git diff scripts/lib/*.py` is empty). Baseline was fully
green (full suite, all four checkers, ruff); `check_dbt_view_coverage.py` exits 1 by design (advisory
backlog print).

## Summary

- **2 real bugs fixed** in owned CLI checkers (1 HIGH, 1 MEDIUM), each with a **mutation-verified**
  regression test (proven to fail when the fix is reverted).
- **56 new tests** added across the owned surface (3 brand-new files for previously **untested**
  modules + 20 additions to 4 existing files). Full suite: **529 passed**, ruff clean, all checkers
  pass.
- **Zero shared-lib edits**, zero frozen-file edits, zero changes to any printed string / exit code /
  CLI flag of a passing path. The two bug fixes intentionally change behavior **only** in the
  currently-broken case (a permanent false-DRIFT object; a mis-routed schema-drift error).
- Method: an adversarial multi-agent review (6 finders × per-finding verify) surfaced 32 findings /
  16 confirmed; every confirmed item was re-verified by hand against the real tree before acting.

## Bugs fixed (source changes)

### 1. HIGH — `check_live_sql_parity.py`: top-level non-CREATE statements bled into an extracted body → permanent false DRIFT
[`scripts/check_live_sql_parity.py`](../../scripts/check_live_sql_parity.py) `NEXT_TOP_LEVEL`.

`extract_body` ended an object's body at the *next top-level CREATE*. But
[`bigquery/67_ci_findings_bridge.sql`](../../bigquery/67_ci_findings_bridge.sql) ends
`CREATE OR REPLACE VIEW state.ci_findings_open AS SELECT … ;` and then, in the same file, runs a
standalone `MERGE state.expected_scheduled_query_versions …` registry bump. Because the boundary
only recognized `CREATE`, that whole `MERGE` statement was swept into `ci_findings_open`'s extracted
body. The live `view_definition` is only the `SELECT`, so the object could **never** converge — a
permanent false DRIFT — and `normalize_tail` couldn't rescue it (the tail is a full statement, not a
comment). This is the same *foreign-DDL-bleed* class the 2026-07-17 code-quality audit fixed for
`CREATE` keywords, but the fix hadn't covered non-CREATE statements.

**Fix:** extend `NEXT_TOP_LEVEL` to also stop at the start of a top-level DML/DDL statement
(`INSERT|MERGE|UPDATE|DELETE|TRUNCATE|DROP|ALTER|GRANT|REVOKE|CALL|EXPORT|ASSERT`). `BEGIN` is
deliberately **excluded** (it opens a PROCEDURE's own body). **Verified before shipping** by diffing
old-vs-new extraction over all 179 objects: only `ci_findings_open`'s body changed (now correctly
ends at `status = 'open'`), no procedure body was truncated, and zero residual column-0 statement
bleeds remain. Tests: broadened the real-tree bleed-invariant to any top-level statement (not just
`^CREATE`), plus a synthetic view+trailing-MERGE case and a direct `ci_findings_open` assertion.
**Mutation check:** reverting to the CREATE-only boundary fails exactly those 3 tests.

### 2. MEDIUM — `dbt_parity.py`: a cross-side type-mismatch error was mis-routed to a benign skip and passed green
[`scripts/dbt_parity.py`](../../scripts/dbt_parity.py) `SCHEMA_DRIFT_MARKERS`.

When a column's **type differs** between the dbt port and the live view, the `EXCEPT DISTINCT`
parity query errors with `… has incompatible types: INT64, STRING`. That substring matched none of
the `SCHEMA_DRIFT_MARKERS` the 2026-07-17 audit added to *fail closed* on schema-shaped divergences,
so it fell through to the tolerant `skipped` branch — real, `dbt parse`-invisible schema drift could
pass green (even under `DBT_PARITY=block`). **Fix:** add `"incompatible types"` to
`SCHEMA_DRIFT_MARKERS` (one-line constant, matching the block's documented intent). Test drives
`main()` with a type-mismatch model **and** a clean model, asserting exit 1 + the `schema-shaped`
error path. **Mutation check:** removing the marker fails that test (the error would route to skip
and, because the clean model keeps `checked>0`, `main()` would return 0).

## Tests added (56 total; the core deliverable)

New files for **previously untested** modules:
- **`tests/test_gen_routine_lists.py`** (20) — `gen_12/15/24_region` row rendering incl. the
  documented `queue_driven`/`None`-`monitor_class` KeyError-guard, indent/comma placement, the
  `wanted_region` byte-padding, `write_region`/`current_region` round-trip + idempotence, missing-marker
  fail-closed, and `main()`'s `--write`/`--check` exit codes + stdout (the CI-gating contract, which had
  no test).
- **`tests/test_check_dbt_view_coverage.py`** (10) — `live_views` dataset-scoping / dedup / non-VIEW &
  MATERIALIZED-VIEW exclusion, `dbt_model_names`, `dbt_source_names` dataset-override/name-fallback,
  and `main()`'s coverage math + exit codes.
- **`tests/test_routine_manifest.py`** (6) — direct coverage of the shared lib's public surface,
  including `build_triggers_manifest`'s duplicate-id last-wins resolution (the two importers feed it
  differently-shaped inputs and rely on this to keep `ops/triggers.json` byte-identical).

Additions to existing owned files:
- **`tests/test_check_live_sql_parity.py`** (+16) — the boundary regression tests above, plus the
  first offline coverage of `bq()`, `live_definition()` (per-object-type query shape + key
  extraction), `main()`'s offline/drift/clean/missing-live decision tree, `--json-out`/`write_json_out`,
  the TABLE FUNCTION `extract_body` branch, and `numbered_sql_files`' numeric (not lexical) ordering.
- **`tests/test_dbt_parity.py`** (+2) — the `incompatible types` fail-closed test, and a behavior
  test proving a `VOLATILE_COLS` column is actually dropped from the `EXCEPT` query (the existing
  `test_volatile_cols_constant_present` only pinned the constant, not the behavior).
- **`tests/test_bq_json.py`** (+1) — a banner whose bracketed text is *itself* well-formed JSON before
  the real row array (correctness rests on `json.loads`' whole-string "Extra data" rejection, which
  nothing pinned; a `raw_decode` refactor would silently return the wrong array here).
- **`tests/test_script_version_consistency.py`** (+1) — the `parse_gs_version` → `None` branch (the
  path that fires precisely when the version regex stops matching — the failure mode the checker
  exists to prevent).

## Deferred / owner items (NOT changed — flagged for coordination)

1. **MEDIUM — `check_live_sql_parity.py` fails OPEN on total live-read failure.** If every
   `live_definition()` raises (systemic WIF/auth failure), all objects land in `missing_live`,
   `checked` stays 0, and `main()` prints `OK:` and returns **0** — a false green that hides a fully
   broken parity gate. Its sibling `dbt_parity.py` was explicitly hardened against this exact
   *vacuous-pass* class (its `checked==0` guard, 2026-07-14 audit); this script never got the guard.
   **Deferred to owner** (not applied) because the fix necessarily changes an exit code (0→1) and
   adds a printed line on a **live daily CI gate** I cannot exercise against BigQuery or observe the
   workflow's failure handling for — HARD RULE 7 (bias to safe / leave uncertain), and the review's
   own independent verifier reached the same `defer-owner` verdict. Ready-to-apply patch — insert
   before the final `print("OK: …"); return 0` in `main()`:
   ```python
   if not mismatches and checked == 0 and final:
       print("\nLIVE SQL PARITY NOT VERIFIED — every object was skipped (bq/auth failure?); "
             "refusing to report OK on zero comparisons.")
       return 1
   ```

2. **MEDIUM — `dbt_parity.py` partial-compile gap.** The "sources exist but nothing compiled" guard
   only fires at `total==0`; a *partial* compile (`0 < total < model_source_count`) leaves the
   uncompiled models silently unverified while `main()` still reports full parity OK. **Deferred**
   (not applied): today CI runs a **full** `dbt compile` (no `--select`) and the project has **no
   disabled/ephemeral models**, so `total == model_source_count` always holds and a partial compile
   is practically unreachable (dbt compile is atomic — a compile error fails the CI step before this
   script runs). A stricter per-model set check would add a new fail path to a safety gate for an
   unreachable case, and would false-fail the day a legitimately-disabled model is introduced. Note
   for owner if selective compile is ever adopted.

3. **LOW (out of scope) — `gen_routine_lists.py` `gen_15_region` SQL-literal apostrophe.** A routine
   heading containing `'` would emit a malformed single-quoted SQL literal. **Not actionable here:**
   the frozen `check_cadence_consistency.py` check B derives the byte-identical instruction text
   (`Claude_Task_Plan.md:` → `f"Read Claude_Task_Plan.md. Perform {h}."`) and its parser is `[^']*`,
   so quote-escaping would have to be coordinated across a frozen file. No heading contains an
   apostrophe today, and check B fails loud if one is ever introduced. Enforced invariant, not a
   code change.

## Considered but declined (no clear, meaningful win / would risk a constraint)

- **`bq_json.parse_bq_json_stdout` internal optimization** — the `[`-scan calls `json.loads` on the
  whole trailing string for each candidate, an O(n²) worst case. A `raw_decode`-based rewrite would
  be faster **but** silently changes the correctness contract (a valid-JSON banner bracket before the
  real array would be returned instead of skipped). The impl is small, correct, and interface-frozen;
  the optimization isn't worth the risk. **Declined** and pinned by a new regression test instead.
  This is the one shared-lib change I weighed and chose not to make.
- **`check_live_sql_parity.py` balance-aware TABLE FUNCTION paren-strip** (review finding) — all three
  live TABLE FUNCTIONs are single `AS ( … )` wrappers, so the current unconditional outer-paren strip
  is byte-identical today; a balance-check would be speculative hardening of a live-path parser for a
  case that doesn't occur. **Declined**, added offline tests for the branch instead.
- **`gen_routine_lists.py` `--check` help/docstring wording** ("exit 1 + diff" — no diff is printed) —
  a genuine doc-vs-behavior nit, but changing help text is churn on a marginal inaccuracy; **skipped**.
- **`dbt_parity.py` EXCEPT-DISTINCT multiplicity** — set semantics can't see row-count drift; a true
  fix changes the observable query construction (out of scope). Left as-is; the limitation is inherent
  and low-risk.

## Verification

Full suite `python -m pytest -q` → **529 passed**. `gen_routine_lists.py --check` → 0;
`check_script_version_consistency.py` → 0; `check_live_sql_parity.py --offline` → 0 (179 objects
parse); `check_dbt_view_coverage.py` → 1 (advisory, by design); `ruff check` on all owned .py → clean.
Both source fixes carry mutation-verified regression tests (proven to fail when reverted). Only my
owned paths were staged (the working tree also carries other parallel instances' in-flight edits to
non-owned files — `check_cadence_consistency.py`, `check_roster_consistency.py`,
`test_cadence_consistency.py`, `test_settings_toolcov.py`, `test_verify_owner_actions.py` — which were
**not** staged).
