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

- **5 fixes to owned CLI checkers** (1 HIGH bug, 3 MEDIUM bugs, 1 LOW latent-corruption hardening),
  each with a **mutation-verified** regression test (proven to fail when the fix is reverted). The
  initial pass shipped 2; a follow-up (owner directive: "fix all") implemented the two fail-open
  guards and the apostrophe fail-fast this report had first deferred.
- **~64 new tests** added across the owned surface (3 brand-new files for previously **untested**
  modules + additions to 4 existing files). Full suite: **596 passed** (shared tree — includes other
  instances' concurrent additions), ruff clean, all checkers pass.
- **Zero shared-lib edits**, zero frozen-file edits. Behavior changes are confined to
  previously-broken cases: a permanent false-DRIFT object, a mis-routed schema-drift error, two
  "reported OK on zero real comparisons" gates that now fail closed, and a malformed-SQL-emitting
  apostrophe path that now fails fast — **all byte-identical / exit-code-identical on the current
  tree**.
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

### 3. MEDIUM — `check_live_sql_parity.py` failed OPEN on total live-read failure *(follow-up; was deferred)*
[`scripts/check_live_sql_parity.py`](../../scripts/check_live_sql_parity.py) `main()`.

If every `live_definition()` raised (systemic WIF/auth failure) every object landed in `missing_live`,
`checked` stayed 0, and `main()` printed `OK:` and returned **0** — a false green hiding a fully
broken daily parity gate. Its sibling `dbt_parity.py` had this exact `checked==0` guard; this script
didn't. **Fix:** added a `checked == 0` fail-closed branch (after the mismatches return, before the
final OK) mirroring `dbt_parity.py`. I went **beyond** the report's first draft (`checked==0 and
final`) to a bare `checked == 0`: for this repo `bigquery/*.sql` always has objects, so an empty
parse is itself a breakage that should also fail closed, not pass. Updated the one existing test
whose premise was the bug (a lone missing object → now needs a second clean object to stay OK) and
added a fail-closed test. **Mutation check:** neutering the guard prints the vacuous `OK:` and fails
the new test.

### 4. MEDIUM — `dbt_parity.py` partial-compile gap *(follow-up; was deferred)*
[`scripts/dbt_parity.py`](../../scripts/dbt_parity.py) `main()` + new `model_source_names()`.

The "sources exist but nothing compiled" guard only fired at `total==0`; a *partial* compile
(`0 < total < sources`) left the uncompiled models silently unverified while `main()` still reported
full parity OK. **Fix:** added `model_source_names()` (refactored `model_source_count()` to
`len(model_source_names())` for a single source of truth), collect the compiled `(dataset, name)` set
in the loop, and fail closed (listing the specific models) if any source has no compiled artifact.
Placed last, so it only changes the would-be-OK path. **Disabled-model caveat** (documented inline):
a deliberately `enabled=false` model would also surface here — **none exist today** and CI runs a full
`dbt compile`, so this can't false-fire now; if one is ever added, exclude it from
`model_source_names()` or declare it out of scope. Two happy-path tests were updated to declare their
source universe; added a partial-compile fail test, a full-compile OK control, and a
`count == len(names)` invariant test. **Mutation check:** neutering the guard prints the vacuous
`OK:` and fails the new test.

### 5. LOW — `gen_routine_lists.py` `gen_15_region` apostrophe: silent corruption → explicit fail-fast *(follow-up; was deferred)*
[`scripts/gen_routine_lists.py`](../../scripts/gen_routine_lists.py) `gen_15_region()`.

A routine heading containing `'` would (a) break the single-quoted `ops.routine_catalog` SQL literal
and (b) be **structurally un-representable** downstream: the frozen `check_cadence_consistency.py`
check B parses this row back with `'(Read …\. Perform [^']*)'`, whose `[^']*` truncates at the first
quote and can **never** match the raw-apostrophe `want_catalog` — so the two byte-identical
derivations could not agree no matter what this generator emits. A *complete* fix (support
apostrophes) is therefore **impossible within Part C's ownership**: it requires escaping `'`→`''`
here **and** teaching check B's frozen parser to un-escape — a coordinated two-file change.

What I *could* do, and did: convert the latent failure into an **explicit fail-fast**. `gen_15_region`
now raises `SystemExit` with a clear, actionable message the moment a heading contains `'`, naming the
routine and the two-file coordination needed — instead of silently writing malformed SQL that surfaces
later (possibly after being applied to BigQuery) as a confusing `routine_catalog instruction drift`
from check B. The guard fires **only** on an apostrophe, so it is **byte-identical on the current tree**
(no heading has one; `gen --check` still clean). Tests: a unit rejection test + an integration test
proving the guard propagates through `main() --check`. **Mutation check:** neutering the guard fails
both. The path to real apostrophe *support* (the coordinated escape/un-escape change) is documented
inline and in Deferred below for the operator.

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

> Every item this section originally deferred has since been addressed within Part C's ownership per
> owner directive ("fix all"): the two fail-open guards (`check_live_sql_parity` `checked==0`,
> `dbt_parity` partial-compile) are Bugs fixed #3/#4, and the `gen_15_region` apostrophe is now a
> fail-fast guard (Bugs fixed #5). The `dbt_parity` guard ships with a documented disabled-model
> caveat (can't false-fire today; inline note tells a future maintainer to exclude a deliberately
> `enabled=false` model from `model_source_names()`).

**Only cross-file work that remains (genuinely NOT in Part C's ownership):** to *support* (rather than
reject) an apostrophe in a routine heading, a coordinated two-file change is required — escape
`'`→`''` in `gen_15_region` (Part C) **and** teach the frozen `check_cadence_consistency.py` check B
parser to un-escape `''`→`'` (not owned by Part C). Until then, Bugs fixed #5's guard enforces the
"no apostrophe in a heading" invariant explicitly and early. No heading has an apostrophe today, so
nothing is blocked.

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

Full suite `python -m pytest -q` → **596 passed** (shared tree — count includes other instances'
concurrent work). `gen_routine_lists.py --check` → 0; `check_script_version_consistency.py` → 0;
`check_live_sql_parity.py --offline` → 0 (179 objects parse); `check_dbt_view_coverage.py` → 1
(advisory, by design); `ruff check` on all owned .py → clean. All **five** source fixes carry
mutation-verified regression tests (each proven to fail when its fix is reverted — including the two
fail-open guards and the apostrophe guard, whose mutations reproduce the vacuous `OK:` / missing
fail-fast they prevent). Only my owned paths were staged (the working tree also carries other parallel
instances' in-flight edits to non-owned files, which were **not** staged).
