# Part A — Roster & autonomy checkers: parallel-refactor report (2026-07-17)

Branch: `refactor/parallel-2026-07-17/partA`

## Inventory of owned files

Part A owns the three **CI consistency gates** for the Strategy-Arsenal (SISA) roster and the
self-improvement autonomy register, plus their offline tests. `scripts/check_roster_consistency.py`
(the largest, ~800 lines) is the roster single-source gate: checks **R-A..R-K** fail the build if
`strategy/roster.yaml` drifts from its mirrors (the `bigquery/35` seed, `Strategy.md` sections, the
`strategy/` slices, the `Claude_Task_Plan.md` slice-map) or if a bare roster literal / fixed-`/N`
divisor, a stale `events.strategy_candidates` dataset name, a spec-hash drift on locked machinery, a
regime-vocabulary mismatch, or an uncovered SHADOW/PAPER/PROBE/ADOPTED strategy survives.
`scripts/check_live_roster_parity.py` compares the **live** `state.active_strategy_codes` set against
the roster-active set via a read-only `bq` query and fails **closed**. `scripts/check_autonomy_consistency.py`
guards `ops/autonomy_levels.yaml` stage citations against prose/SQL drift, the stage≤ceiling invariant,
and heartbeat/dead-man's-switch coverage for every `active_auto` loop. Tests are pure-offline fixture
suites (`tests/test_roster_consistency.py`, `tests/test_autonomy_consistency.py`, and the **new**
`tests/test_check_live_roster_parity.py`).

All work was driven by a 43-agent adversarial bug-hunt workflow (29 findings confirmed after
independent verification, 7 rejected, 1 uncertain), then each fix was implemented, empirically checked
against the real frozen inputs for behavior-preservation, and locked with a regression test.

## Baseline & result

| | Baseline | After |
|---|---|---|
| Owned test files (roster+autonomy) | 59 | **118** (roster 66, autonomy 32, parity **20 new**) |
| Full suite | green | **green** (588 passed) |
| `check_roster_consistency.py` / `check_autonomy_consistency.py` | exit 0 | exit 0 (byte-identical OK output) |
| `ruff` on all owned files | clean | clean |

Every change is **behavior-preserving on the current green repo** — the OK-path stdout, exit codes, and
CLI of all three checkers are unchanged (verified by diffing output and by the existing tests). All new
guards fire only on inputs that do not occur today (latent gaps / crash-instead-of-clean-FAIL paths).

---

## Bugs fixed (latent — none fired on the current repo, all now regression-tested)

### `check_roster_consistency.py`
1. **R-B bare-literal evasion** (`vacuous-pass`). `BARE_LITERAL` was single-quote-only and required ≥2
   elements, so a re-hardcoded roster written double-quoted (`["A","B",...]`, valid BigQuery) or as a
   single-element `['A']` silently evaded the SOLE guard against a hardcoded roster membership literal in
   the live derived SQL. Widened to a matched-quote class `['"]` with a comma-or-bracket terminator.
   Verified: 0 matches on all three real derived-SQL files before and after (the `['A'..'E']` comment
   notation and STRUCT arrays still don't match).
2. **R-B / R-C leading-operator divisor evasion** (`vacuous-pass`). The `/N`-adjacency context window
   only spanned the divisor's own line, so a leading-operator wrap (`SUM(amount)`⏎`  / 5`, the
   sqlfluff/dbt `operator_new_lines: before` default) put `amount` on the preceding line, outside the
   window — the forbidden equal-split went unflagged. Extracted `_divisor_context()`, which reaches back
   one line **only when the operator is the first non-space char of its line** (a mid-line `/N` such as a
   `section 5/6` comment is not widened, so the R-B/R-C false-positive-suppression tests stay green).
   Verified `old_fire == new_fire` for every `FIXED_DIVISOR` match across all four real files.
3. **R-E crash on a non-integer rail value** (`robustness`). A present-but-blanked `n_min:` (YAML null)
   passed the `in` test, skipped the clean "missing" branch, and hit an unguarded `int(None)` → traceback
   with no `ROSTER CONSISTENCY: FAIL` line. `_compare_rails()` now catches `TypeError`/`ValueError` and
   emits a clean R-E error naming the bad value.
4. **R-G empty-list vacuous pass** (`vacuous-pass`). `if codes and codes != roster_codes` treated a
   strategy-column `accepted_values` degenerated to `values: []` as clean. R-G is the CI-blocking guard
   (the dbt `accepted_values` test is advisory-only), so the roster-vs-schema divergence would have passed
   green. Dropped the `codes and` short-circuit.
5. **R-G crash on non-mapping `accepted_values`** (`robustness`). A bare-list `accepted_values: ['A','B']`
   (not `{values: [...]}`) `AttributeError`'d on `.get`. Added an `isinstance(..., dict)` guard emitting a
   clean R-G error.
6. **`strategies: null` crash** (`robustness`). Three `doc.get("strategies", [])` sites (`roster_active_codes`,
   R-D, R-F) plus `cad.get("routines", [])` lacked the `or []` guard the same file already used at 5 other
   sites, so a present-but-null key (e.g. a partial SL5 write) raised `TypeError` instead of a clean FAIL.
   Added `or []` at all four.
7. **Missing top-level input files crash** (`robustness`). `Strategy.md` / `Claude_Task_Plan.md` /
   `ops/cadence.yaml` were opened unconditionally (unlike `ARSENAL_SQL`/derived-SQL/`DBT_RECONCILE`, which
   are guarded), so absence raised `FileNotFoundError` with no clean FAIL line (and made R-H's own
   PLAN/CADENCE guard dead code). Added existence guards mirroring the established pattern.
8. **`slicemap_codes()` empty-on-last-section** (`robustness`). `(?=^##\s)` required a following H2, so if
   `## Strategy reading` ever became the plan's last H2 the section parsed empty → spurious R-A full-roster
   mismatch. Changed to `(?=^##\s|\Z)`, matching `shared_regime_tokens()`'s existing precedent.

### `check_autonomy_consistency.py`
9. **Heartbeat coverage fail-open** (`vacuous-pass`). `cadence_heartbeat_loops()` unions **both**
   `loop:<id>` UNNEST literals in `bigquery/75` — the IF-EXISTS **detection** list that fires the alarm and
   the STRING_AGG **message** list that only builds alert text. A future `active_auto` loop added to the
   message list but omitted from the detection list has no working dead-man's switch, yet union-membership
   marked it "monitored." Added `cadence_detection_loops()` (intersection of all loop-bearing UNNEST
   literals = detection-list membership) and switched the coverage check to it; `cadence_heartbeat_loops()`
   is retained for the file-missing / rot signals. Real repo: the two lists are identical, so
   intersection == union → clean (verified).
10. **Stage-less loop passes silently** (`robustness`). `check_stage_ceiling_invariant` never flagged a
    loop that declared a `ceiling` but had no `stage` (a dropped/indent-slipped `stage:` line), which then
    silently drops out of `active_auto_loops()` and its heartbeat requirement. Added a branch gating on
    stage-absent specifically (a stage-present/ceiling-absent loop stays valid).

### `check_live_roster_parity.py`
11. **Both-empty vacuous OK** (`vacuous-pass`). `main()` reported `OK … ([])` when both the roster-active
    set and the live set were empty — contradicting the file's own "never report OK on zero real
    comparison" doctrine (a present roster with zero probe/adopted codes violates the SISA N≥2 floor).
    Added a both-empty `NOT VERIFIED` / return-1 guard before the OK branch, mirroring `dbt_parity.py`.

## Refactors (pure DRY, provably behavior-preserving — byte-identical error strings verified)

- **`_line_no()` + `_divisor_context()`** collapse the line-number + line-context computation that was
  character-identical across R-B's divisor loop, R-C's loop, and (line-number half) R-B's bare-literal
  loop. The leading-operator fix (#2) lives in this one place instead of two copies.
- **`_compare_rails()`** collapses R-E's two structurally-identical rail-comparison loops (top-level rails
  + `cooldown_days`), which had already drifted once (the missing-key hardening had to be hand-applied to
  both). The non-integer guard (#3) lives here.

## Tests added (+59)

- **`tests/test_check_live_roster_parity.py` (NEW, 20 tests)** — the gate had **zero** tests despite being
  a fail-the-job CI gate. Locks `bq()`'s read-only argv + `timeout=600` + banner-tolerant JSON parse +
  returncode/timeout handling; `roster_active_codes()`'s probe/adopted filter, case-insensitivity, and
  **docstring-promised parity** with `check_roster_consistency.roster_active_codes`; `live_active_codes()`
  extraction/target/malformed-row handling; and every `main()` branch (SKIP / OK / drift-FAIL /
  FAIL-CLOSED-on-exception / FAIL-CLOSED-on-malformed-rows / both-empty-NOT-VERIFIED / `--project`).
- **`tests/test_roster_consistency.py` (+31)** — first-ever tests for **R-J** (regime-vocab drift, both
  cell-side and vocabulary-side, + section-scoping) and **R-K** (uncovered adopted strategy, slice-based
  path-a coverage, scenarios-absent skip, shadow-with-slice-uncovered) — the latter required extending the
  `repo_copy` fixture to copy + repoint `SCENARIOS_YAML` (it previously read the real file, making R-K
  untestable). Plus R-E cooldown mismatch/missing + rail-const rot, R-F `.md`-slice drift + missing input,
  R-A fail-loud branches, R-C `deposit` token, R-H line-number contract, and one regression test per bug
  fixed above.
- **`tests/test_autonomy_consistency.py` (+8)** — `main()`-level integration (stage>ceiling and
  unmonitored-`active_auto` both return 1), the heartbeat rot branch, the None-stage citation path, and
  regression tests for fixes #9 and #10 (detection-only divergence caught; stage-less-with-ceiling flagged).

---

## Deferred / owner items (NOT actionable within owned files)

1. **OWNER — live stale autonomy citation + owned glob (HIGH).** `bigquery/README.md:32` carries
   `STATUS: DORMANT per ops/autonomy_levels.yaml (loop id process_reliability)`, but that loop is
   `active_auto` (promoted 2026-07-10b) — a **real live drift**. `check_autonomy_consistency.py`'s
   `EXTRA_SCAN_GLOBS` scans `bigquery/*.sql` but **not** `bigquery/*.md`, so the stale citation is never
   checked (a genuine vacuous pass). Fix is two-part and cannot ship owned-only: the owner must correct the
   frozen `bigquery/README.md:32` (`DORMANT` → `active_auto`), and **together** add
   `os.path.join(ROOT, "bigquery", "*.md")` to `EXTRA_SCAN_GLOBS`. Adding the glob alone flips the checker
   RED on the current repo (confirmed), so it must land with the doc fix — hence deferred.

2. **OWNER (policy) — R-K slice-less SHADOW/PAPER coverage gap.** A SHADOW/PAPER strategy whose roster
   entry lands before its slice file passes R-K with a non-blocking note and **zero** enforced coverage
   (R-A/R-D never inspect non-active entries). Closing this (hard-fail a slice-less incubating strategy)
   is a **policy change** that would reverse the settled SISA "no hard gate on strategy add" decision and
   break the `b13` test, so it is the owner's call. I made the safe, owned, behavior-neutral part: the
   **false in-code comment** ("its absence is caught by R-D/R-A") is corrected to state the true caveat.

3. **NOTE (left as-is, fails closed).** `check_live_roster_parity.py`'s `only_live = sorted(live - repo)`
   would `TypeError` if the live view ever returned a NULL `strategy_code`. It fails **closed** (crash →
   exit 1 = FAIL, not a vacuous OK), the view is defined to return non-null codes, and a defensive filter
   could mask what a legitimate drift looks like — so left unchanged and noted.

4. **NOTE — R-A slice/slice-map zero-guard asymmetry (low).** `slice_codes()`/`slicemap_codes()` lack the
   explicit zero-count guard `md_codes`/`n_seed` have, but this is **provably not** a vacuous pass (an
   empty slice set can only pass if `roster_codes` is also empty, which trips the `md_codes` backstop). Left
   as-is per the finding's own `leave-and-note` recommendation; only the diagnostic precision is affected.

## Shared-tree observation (operational, for the consolidator)

The five instances share one working tree. At report time it also contained **other instances'** in-flight
edits to non-owned files (`scripts/check_cadence_consistency.py`, `tests/test_cadence_consistency.py`,
`tests/test_settings_toolcov.py`, `tests/test_verify_owner_actions.py`, `audit/.../partB-report.md`). I
staged **only** my owned paths (explicit `git add`, never `-A`) and did not touch those. The full suite
(588 passed) includes everyone's in-flight changes and is green.

## Owned files touched

- `scripts/check_roster_consistency.py` (+143 / −62)
- `scripts/check_autonomy_consistency.py` (+37 / −2)
- `scripts/check_live_roster_parity.py` (+13 / −0)
- `tests/test_roster_consistency.py` (+346)
- `tests/test_autonomy_consistency.py` (+106)
- `tests/test_check_live_roster_parity.py` (NEW, 229 lines)
