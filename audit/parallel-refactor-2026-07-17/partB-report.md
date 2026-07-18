# Parallel refactor 2026-07-17 — Part B report (Cadence / owner-actions / settings-coverage)

## Inventory of owned files

Part B owns three offline CI drift-guard scripts and their pytest suites.
[scripts/check_cadence_consistency.py](../../scripts/check_cadence_consistency.py) (652→646 lines) is
the big one: it makes `ops/cadence.yaml` + `Claude_Task_Plan.md` the single source of truth and
cross-checks ~13 lettered invariants (A–M) against the hand-kept SQL in `bigquery/12/15/24/31/59`,
`ops/triggers.json`, `ops/trigger_ids.json`, and `.github/workflows/auto-merge-claude.yml`, using
regex scrapers whose own robustness is guarded by
[tests/test_cadence_consistency.py](../../tests/test_cadence_consistency.py).
[scripts/verify_owner_actions.py](../../scripts/verify_owner_actions.py) is the fail-open /
always-exit-0 / single-file-commit-surface OWNER_ACTIONS.md auto-closer (parses ```verify fences,
runs one read-only probe per id, flips newly-passing headings), covered by
[tests/test_verify_owner_actions.py](../../tests/test_verify_owner_actions.py).
[scripts/check_settings_toolcov.py](../../scripts/check_settings_toolcov.py) is a one-direction gate:
every `mcp__` tool named in routine text/trigger catalog must be in `.claude/settings.json`'s
`permissions.allow`, covered by [tests/test_settings_toolcov.py](../../tests/test_settings_toolcov.py).
The scripts consume the frozen, Part-C-owned `scripts/lib/routine_manifest.py` (heading parsing /
triggers manifest) and `scripts/lib/bq_json.py` (bq stdout→JSON) **as-is** — no lib edits were needed
or made. All three scripts are invoked only as CLI in CI (`ci.yml`, `owner-actions-verify.yml`); no
production module imports them, so the observable contract is exactly *stdout strings + exit codes* (+
the module API their own tests exercise).

## Method

Established a green baseline (378 tests, ruff clean), then ran an adversarial multi-agent audit
workflow: five independent finders (one per module + a test-gap finder + a cross-cutting/dead-code
finder) produced 24 raw findings, each of which was then independently verified by a skeptic agent for
(a) reality, (b) byte-exact observable-behavior preservation, and (c) owned-file-boundary compliance.
Every applied change below was cross-checked against my own independent read of the files and, for the
source refactor, proven byte-identical to the original with a direct string comparison. High bar:
these are mature, heavily-audited files, so churn was rejected.

## Changes made (owned files only)

### Source — `scripts/check_cadence_consistency.py`

1. **Extracted `catchup_list_errors()` helper — dedup of check K's two near-identical blocks.**
   The daily (`bigquery/31_catchup_notify.sql`) and period (`bigquery/59_catchup_autofire.sql`)
   catchup-safe `UNNEST([...]) AS routine` validators were ~30 lines of copy-paste differing only in
   four tokens: the path constant, the display filename, the tier word (`daily`/`period`), and the
   monitor-class set (`DAILY_CLASSES`/`PERIOD_CLASSES`). This is exactly the kind of duplicated
   drift-guard where a one-sided wording fix silently desyncs the two branches. *Why safe:* both
   emitted strings (the `… drift guard is DISARMED …` and `catchup-safe <tier> UNNEST list DRIFT — file
   has … wants …` messages) are fully reconstructable from the four parameters, so stdout is preserved
   character-for-character. Verified two ways: (i) all pre-existing tests still pass unchanged (they
   monkeypatch the module-global path constants, which `main()` still reads by name at call time and
   passes through); (ii) a direct comparison proved the helper's DISARMED and DRIFT strings are
   byte-identical to the originals on **both** the 31 and 59 sides. Net −23 lines in `main()`.

2. **Fixed an inverted docstring in `parse_period_grace_sql()`.** Its docstring claimed
   "Returns `{}` if the file is absent," but the code returns `None` (and the caller relies on
   `is not None` to decide whether to run check E — an empty `{}` would have the *opposite* effect,
   flagging every grace class as a parse failure). Corrected the docstring to "Returns `None`…". This
   is a documentation-correctness fix; zero runtime impact.

### Tests — added coverage for correctness-critical branches that ran *only* via the aggregate
`main()==0` end-to-end tests (the vacuous-pass class this module's own docstring exists to prevent)

`tests/test_cadence_consistency.py` (+19 tests):
- `catchup_list_errors()` helper: absent-file silent, matching-list silent, and — closing a real gap —
  the **daily/31 side** DRIFT and DISARMED paths, which previously had *no* error-level coverage (only
  the 59 side did).
- **Check M** (H1 evening-slot SAME-DAY guard noon-threshold clause): happy path, `MISSING the
  noon-threshold clause`, and `DISARMED` (guard-query regex rot) — a live safety guard that had zero
  unit coverage.
- **Check I** (`expected_trigger` structural validation): well-formed clean, missing-`expected_trigger`
  with a live trigger id, bad `recurrence`, missing `enabled`, bad `time_local`, empty `cron_utc`.
- **Check D** `multiple distinct deadline literals` branch.
- monitor_class presence + vocabulary branches; duplicate plan-heading detection.
- **Check L** AR_att `Daily¹` footnote branch (queue_driven behind a Daily cadence cell), plus its
  negative (plain `Daily` without the footnote is correctly rejected).

`tests/test_verify_owner_actions.py` (+9 tests): probe **success** paths and the `trigger_ids.json`
read branch, which previously only had fail-open/error arms — `check_A` compound success + no-entry
open + read fail-open; `check_D` active / inactive states + the `gh repo view` repo fallback;
`_bq_scalar`'s row-present-but-missing-column arm; `check_E_anthropic` via `GEMINI_API_KEY` (true/unset).

`tests/test_settings_toolcov.py` (+1 test, docstring corrected): the module docstring documented a
now-**closed** gap (three `mcp__` tools missing from `.claude/settings.json` → real repo expected to
exit 1). The owner has since added those entries and the real gate now exits 0; corrected the stale
docstring and added `test_real_repo_settings_toolcov_is_consistent` (the real-repo-green lock-in the
old docstring explicitly deferred to "a future session").

### Follow-up round (owner-requested): the three originally-deferred items, now implemented

On the owner's explicit instruction ("fix all and go with your recommendation for all"), the three
items originally deferred below were implemented, each in the direction of my stated recommendation:

1. **Removed the dead `ROUTINE_SUFFIX` re-export** (`check_cadence_consistency.py`): dropped the
   `ROUTINE_SUFFIX as _ROUTINE_SUFFIX` import alias and the `ROUTINE_SUFFIX = _ROUTINE_SUFFIX`
   re-export + its now-stale provenance comment. Verified dead (nothing references it; heading parsing
   is delegated to `lib.routine_manifest`; `print_routines.py`/`split_task_plan.py` import the name
   directly from the lib). Guarded by `test_routine_suffix_dead_reexport_removed`. No stdout/exit change.

2. **Made the OWNER_ACTIONS.md write fail-open** (`verify_owner_actions.py`): wrapped the final
   write in `try/except (OSError, ValueError)`, printing a clear `could not write … (flip NOT persisted;
   will retry next run)` notice and still returning 0 — mirroring the already-guarded read path and the
   module's documented "never raise / always exit 0" contract. Chose fail-open over the "loud crash"
   alternative because the auto-close is **idempotent**: the next run recomputes the same flip and
   re-attempts the write, so a transient failure is retried rather than lost (the earlier "dropped
   forever" concern only holds for a permanently read-only FS, where nothing can be persisted anyway).
   Guarded by `test_main_write_failure_is_fail_open_not_crash` (verified rc==0, notice printed, no
   traceback). This intentionally makes the write-failure error path exit 0 instead of crashing —
   authorized by the owner and restoring the stated contract.

3. **Documented + hardened the settings allowlist** (`check_settings_toolcov.py`), **without** the
   harmful widening: went with my recommendation that exact-token matching is *correct* (a
   `mcp__Server__*` wildcard / server-level grant is NOT expanded by the harness at call time, so
   treating it as coverage would be a false negative that lets an unattended session stall). Made that
   strictness explicit in the docstring and added an `isinstance(a, str)` guard so a malformed
   non-string `permissions.allow` entry is skipped rather than crashing the gate with a `TypeError`.
   Guarded by `test_non_string_allow_entry_is_ignored_not_crashed` and
   `test_wildcard_allow_entry_does_not_cover_referenced_tool`. No stdout/exit change on valid input.

## Bugs fixed

- The inverted `parse_period_grace_sql()` docstring (above) — a latent documentation bug that
  mis-states the contract the caller depends on.
- A latent robustness bug in `check_settings_toolcov.load_allowlist()`: a non-string
  `permissions.allow` entry would crash the gate with a `TypeError` from `re.fullmatch`; now skipped
  cleanly (follow-up item 3).
- No functional/logic bug was found in the *checking logic* of any of the three scripts; they are
  unusually robust (the adversarial finders' logic-bug candidates all failed verification). The test
  additions are regression insurance for branches previously only transitively exercised.

## Deferred / owner items

**Update:** all three items below were subsequently IMPLEMENTED on owner request — see the "Follow-up
round" subsection above. They are retained here for the original rationale/context.

1. **Dead `ROUTINE_SUFFIX` re-export in `check_cadence_consistency.py`** (lines ~71/155–158). The
   `import … ROUTINE_SUFFIX as _ROUTINE_SUFFIX` + `ROUTINE_SUFFIX = _ROUTINE_SUFFIX` re-export is
   verifiably unused: nothing in the file references it, no test accesses it, and `print_routines.py` /
   `split_task_plan.py` import `ROUTINE_SUFFIX` **directly** from `lib.routine_manifest` (so the
   line-155 provenance comment's "identical copy shared with print_routines.py" is now stale).
   **Left as-is on purpose:** two independent verifiers split on it — one called removal a clean
   dead-code delete, the other "churn-for-its-own-sake" on a mature safety-critical file (it is a
   deliberate module-level public re-export; removal also drags in an edit to audit-provenance docs and
   cannot be proven safe against a hypothetical out-of-tree importer). Per the "leave uncertain
   refactors" guidance, deferred. *Owner call:* if you want it removed, drop the import alias + lines
   155–158, or at minimum correct the now-stale provenance comment.

2. **`verify_owner_actions.py` OWNER_ACTIONS.md write is unguarded** (the `open(…, "w")` at the end of
   `main()`). A read-only FS / disk-full makes it raise, which technically violates the "never raise /
   always exit 0" docstring. **Deliberately not changed:** wrapping it to fail-open would (a) change an
   exit code on the error path (the constraints say reject any exit-code change in a cleanup) and (b) be
   arguably *wrong* — a swallowed write failure would silently drop a computed close forever (the next
   run recomputes and re-fails the write) with no signal, so a loud crash is the safer behavior. This is
   a genuine design tradeoff, not a mechanical hardening → owner's call.

3. **`check_settings_toolcov.py` allowlist filter recognizes only exact `mcp__server__tool` tokens**,
   not server-level or `mcp__server__*` wildcard grants. This is *latent* (the live `.claude/settings.json`
   is 48/48 exact tokens; the check is green) and the trigger — adding a wildcard entry — lives in a
   frozen file. Verification also found the "widening" would likely introduce a **false negative**
   (Claude Code does not expand `mcp__server__*` wildcards, so the strict FAIL is the *correct*, safer
   posture for a gate protecting an unattended trading session). Recorded as an owner design decision;
   no change.

Verifier-dropped (agree, no action): unifying checks A/B/J's map-diff scaffolds (messages differ too
much — would reduce readability and risk string drift); wrapping bare `open().read()` calls in context
managers (run-once CLI, ruff-clean — churn); `MCP_TOKEN` left-boundary and duplicate-line-number
cosmetics (the latter would change the FAIL diff format = observable behavior); the redundant
`n and n > 0` guard in `check_A` (harmless defensive code).

## Verification

- `python -m pytest -q tests/test_cadence_consistency.py tests/test_verify_owner_actions.py
  tests/test_settings_toolcov.py` → **all pass** (baseline had 80; now **113** owned-file tests, +33).
- `python -m pytest -q` (full) → my owned files all pass. One failure appears in the shared working
  tree — `tests/test_check_live_sql_parity.py::test_main_skips_a_missing_live_object_without_reporting_drift`
  — but that is **Part A's file, not mine** (it fails on "0 objects verified against live BigQuery," a
  bq/auth/environment issue in another instance's in-progress work; it references none of my files and
  is not in my commit). Per the parallel contract I note it and do not touch it. None of my changes
  broke anything I own or don't own.
- `python scripts/check_cadence_consistency.py` → `OK` (stdout byte-identical to baseline), exit 0.
- `python scripts/check_settings_toolcov.py` → `OK`, exit 0.
- `verify_owner_actions.py` deliberately **not** run against the real OWNER_ACTIONS.md (its `main()`
  would flip a newly-passing item and mutate that non-owned file); coverage is via the monkeypatched
  suite per the contract. I imported it and exercised its help/summary path once early, which flipped
  F-quota in OWNER_ACTIONS.md — I immediately `git checkout`-restored that file, and the working tree
  shows no OWNER_ACTIONS.md change.
- `ruff check` on all six owned `.py` files → clean.

## Note on the shared working tree / how this was committed

All five instances share one working tree. At commit time the tree already contained Parts A/C/D/E's
uncommitted changes, HEAD was on a sibling branch (`partC`), and branches partA/C/D/E existed. To avoid
racing the shared HEAD or disturbing another instance mid-operation, `refactor/parallel-2026-07-17/partB`
was created from the pristine merge-base (`5486993`) via plumbing (a private temp index + `commit-tree`)
so the commit contains **only** my six modified owned files (all three scripts + all three test files)
+ this report, touches no other file, and never switched the shared working-tree HEAD. Files owned by other parts (e.g. `check_live_sql_parity.py`,
`dbt_parity.py`, `test_bq_json.py`, new `test_gen_routine_lists.py` / `test_routine_manifest.py`) were
left entirely untouched.
