# Part E — Parallel refactor report (2026-07-17)

**Scope (owned files, Part E — Golden scenarios, spec-math test hygiene, shell, weekly-report).**
My set is: five operational shell scripts (`scripts/auto_merge_decision.sh` — sourceable CI-gate/delete
predicates; `restore_drill.sh`, `backup_events.sh`, `notify_webhook.sh`, `state_snapshot.sh` — GCS
backup/restore/notify/snapshot side-effecting scripts with no unit tests); the golden-scenario
prose-regression harness (`tests/golden_scenarios/run_golden.py` + its data `scenarios.yaml` + its guard
`tests/test_golden_scenarios_runner.py`); the split-aware TWR spec-lock `tests/test_split_aware_engine.py`;
two spec-locked-source regression suites (`tests/test_options_math.py`, `tests/test_strategy_math.py` —
sources frozen, test-hygiene only); the auto-merge predicate test `tests/test_auto_merge_logic.sh`; and the
weekly-report trio (`ops/weekly_report/weekly_report.gs` — deployed live v5, audit-only;
`sample_preview.html` — audit-only; `test_pure_helpers.js` — the one freely-editable JS test). These files
have already survived multiple prior audit rounds and are, on the whole, in genuinely good shape — so the
bar for a change was a clear, verified, meaningful win, and most of the analysis correctly concluded "leave
it." Every claim below was produced by a 14-agent adversarial analysis workflow (per-group finders →
independent per-finding verifiers) **and** cross-checked against my own independent read + runtime probes;
I applied only findings that both passes agreed were real, safe, and above the churn bar.

## Baseline (before) → after
All green before and after. Deltas are purely additive test coverage + one strengthened assertion +
one comment-accuracy fix; **no production code, printed string, exit code, or command side-effect changed.**

| Check | Before | After |
|---|---|---|
| `python -m pytest -q` (full) | 405 passed | **411 passed** (+6 `run_live` tests) |
| targeted 4-file pytest | pass | pass |
| `bash tests/test_auto_merge_logic.sh` | 30 assertions | **35 assertions** (+5) |
| `node ops/weekly_report/test_pure_helpers.js` | 70 assertions | 70 assertions (1 strengthened) |
| `shellcheck -S warning` (5 scripts) | clean | clean |
| `ruff check` (required) | clean | clean |

## Changes made (3 files, all test-side / comment-side)

### 1. `tests/test_auto_merge_logic.sh` — lock the fail-closed guarantee of the CI-retry gate (+5 assertions)
`should_retry_failed_ci` fires **only** when `run_attempt == "1"`, so the safety of the one-shot auto-merge
retry rests entirely on `ci_run_attempt_from_json` returning `""` (never a number, never `"null"`) for the
no-run (`[]`), API-failure (`''`), and error-shaped (`{"message":"Not Found"}`) inputs. Runtime-verified all
three already return `""` today — but the suite asserted only the happy path (`run_attempt → "1"/"2"`).
Coverage was genuinely asymmetric across the three sibling parsers: `ci_conclusion_from_json` had the full
input matrix (incl. the error-shaped body at line 110), `ci_run_id_from_json` was tested for `[]`/`''` but
**not** error-shaped, and `ci_run_attempt_from_json` had only the happy path. Because each parser carries its
**own** copy of the `(.workflow_runs|type)!="array"` guard, `ci_conclusion`'s malformed test does not protect
the other two. Added the missing edge cases plus one end-to-end lock (`should_retry_failed_ci "failure"
"$(ci_run_attempt_from_json '{"workflow_runs":[]}')"` must not retry) that pins the parser→predicate wiring
the existing hardcoded-`""` assertions leave unpinned. Purely additive; sourced production script untouched.

### 2. `tests/test_golden_scenarios_runner.py` — cover `run_live()`, the untested core of `--live` mode (+6 tests)
Every helper `run_live` composes was unit-tested, but `run_live` itself (run_golden.py:397-456) — the
DECISION-line scan (must find a non-first, case-insensitive line), the `split`/`reply.strip()` fallback,
match-vs-flip token grading, the call-failed→`match=None` error class that `main()` counts, the
`scenario_ids` filter, and the flip branch that prints the `::warning::` annotation + the spec-only
`QUEUE_INSERT` advisory — was called by no test. A regression in any of these (wrong line picked, flip
mis-scored as match, crash instead of recorded error) would ship green. Added 6 network-free tests that drive
a fake Gemini caller (monkeypatching `rg._select_live_caller`, which `run_live` resolves as a module global
at call time) over synthetic scenarios whose `governing_files` point at a real on-disk file: match / preamble
+ case-insensitive DECISION line / flip-emits-annotation-and-INSERT-string / model-raises→error class /
`scenario_ids` filter / bare-token `reply.strip()` fallback.
**Golden non-issue respected:** the flip test asserts only on the *printed* advisory `INSERT` **string** — no
BigQuery write is wired into `run_golden.py`; the queue INSERT stays a print-only advisory per CLAUDE.md.

### 3. `ops/weekly_report/test_pure_helpers.js` — one real test bug + a stale-cross-reference hygiene fix
- **Test bug fixed (tautological assertion):** the "bar-width floor" test asserted
  `out.includes('width:2px') || /width:\d+px/.test(out)`. The second disjunct matches the VOO bar
  (`width:240px`) and even the 40px label spans, so the assertion was vacuously true — a regression to
  `width:0px` on strategy A's near-zero bar would still pass. Dropped the redundant `||` so the test actually
  verifies the `Math.max(2,…)` floor it is named for. The `width:2px` expectation already holds today (A's
  `|val|`=0.01 vs VOO 10 → `widthPx = max(2, round(0.24)) = 2`), so no expected value changed; stdout/exit
  are byte-identical (still `70 assertions passed.`, exit 0).
- **Sync-contract accuracy:** the `KEEP IN SYNC MANUALLY` header located each verbatim-copied function by a
  brittle line number; **six** of those pointers had already drifted stale (e.g. `fallbackBarsHtml_` was
  ~60 lines from the claimed `418-436`; `esc_ 331→337`, `clr_ 325→331`, `pctCellHtml_ 441-446→511-516`,
  `alert_emailer isTest_ 210→218`, `esc2_ 205→213`). Rather than re-correcting numbers that will re-rot the
  next time the sources grow, converted the whole list to drift-proof **function-name** references (the
  durable, grep-able locator the header already used for 6 of its entries) — permanently removing the
  misdirection of a load-bearing manual-sync contract. Comment-only; no copied function body or asserted
  value touched.

## Bugs fixed
- **1 test bug:** the tautological bar-width assertion in `test_pure_helpers.js` (see change #3). No **live
  production** bug was found in any owned file — the substantive wins were test-coverage/quality gaps that
  could have let a *future* regression ship green (the auto-merge retry fail-closed guarantee; the entire
  `run_live` grading path).

## Deferred / report-only / owner items

### Audit-only files (report bugs, do NOT edit — HARD RULE 3)
- **`ops/weekly_report/sample_preview.html` is STALE vs the live v5 `weekly_report.gs`** (confirmed by two
  independent passes). Line 15 shows the pre-v5 header `"Cumulative Return Since Apr 17 (%)"` but live
  `weekly_report.gs:544` renders `"Cumulative Return (%)"` (the fixed Apr-17 anchor was removed in the v5
  "each line from its own start" redesign). Line 16 shows the old caption `"Each strategy's total return; VOO
  (steel blue) benchmark. A, C, E not deployed."` but live `:545` assembles `"Each line from its own start —
  a strategy from its first deployed day, VOO from its first mark. VOO (steel blue) benchmark."` + the
  not-deployed/VOO-stale notes. The Average-Return table + footer still match live. Git corroborates: the
  preview was last touched in the v3 SGOV-drop commit while the `.gs` advanced to v5 without regenerating the
  preview. **Owner action:** regenerate `sample_preview.html` from live v5 output in a context where editing
  it is in scope. (Not a known non-issue — CLAUDE.md/memory exempt only the y-axis label, not this file.)
- **`ops/weekly_report/weekly_report.gs` — NO confirmed bugs.** I traced the null/NaN guards
  (`signPct_`/`fmtRetPct_` force `+` on a rounded-zero and never fabricate `0` for a null return), the
  `periodAvg_` 21-day floor, `niceNum_`/`niceYRange_` edge cases (empty / all-null / flat / all-positive /
  all-negative all bracket 0 and never yield a zero span), the chart forward-fill/gap logic, and
  `esc_`/timezone parsing — all correct. **One item explicitly cleared so a sibling auditor does not
  re-raise it:** the chart date axis is sourced solely from `d.vooByDate`; this is *correct*, not a bug —
  `analytics.voo_cumulative`'s axis is a superset of every deployed strategy's dates (it is
  `DISTINCT as_of_date FROM strategy_vs_park_daily`), so it is non-empty whenever anything is deployed and
  drops no strategy point.

### Spec-locked-source test files (test-hygiene only; asserted values are frozen)
- **`tests/test_strategy_math.py` — `test_e_correlation_breakdown` (line 307) does not pin the 0.3 exit
  threshold.** The assertion re-derives the expected boolean from the same Pearson value it tests, and the
  fixture correlation is exactly `-0.3`, so the equality holds for *any* threshold `> -0.3` (verified by
  sweep: 0.4/0.5/0.9 all still pass; only an operator flip is caught). Left **as-is** — a real fix needs
  *new* fixture data + a *new* hardcoded expected boolean, i.e. adding an asserted value to a frozen-source
  test, which exceeds the hygiene-only allowance and risks a safety-critical pin. Report-only. (Note the
  sibling `test_e_pair_correlation_qualifies` *was* hardened for exactly this on 2026-07-11 — an authorized
  future edit could do the same here, citing that precedent.)
- `tests/test_options_math.py` / `tests/test_strategy_math.py` otherwise in excellent shape: every expected
  value is independently hand-computed (or cross-checked via a second path), imports are all used (ruff
  clean), names are clear. The pervasive repeated structure-construction is deliberate per-test
  self-containment for regression pins — folding it into shared fixtures would reduce test isolation (one
  fixture edit would silently move inputs across many max-loss assertions), a net negative for safety pins.
  No refactor.

### `tests/test_split_aware_engine.py` — considered, left as-is (below the bar)
- `mv_series`'s `entry_price` parameter is never referenced in its body (dead). Left it: two verifiers noted
  the passed values (each = the scenario's first close) read as inline scenario documentation, and removing a
  param + 3 call sites on a crisp 68-line spec-lock is churn for marginal gain.
- No reverse-split (`split_ratio < 1`) case is exercised. Left it: the mirror's `EXP(SUM(LN(split)))`
  formulation is **branchless**, so a `0.5` ratio traverses the identical arithmetic as `2.0`/`4.0` — the
  existing 2:1/4:1 tests already lock the exact continuity invariant; a reverse case adds no distinct
  coverage or regression protection (real data has `split_ratio` NULL/1.0 everywhere per bigquery/82).

### Considered and rejected
- **`run_golden.py` — no change.** Traced every hunt target adversarially (DECISION parser, `_leading_token`
  longest-first sort, daily-vs-minute 429 classification, sticky ladder advance, bounded RPM retries,
  output-budget high-water mark bounded at `_CEIL` and persisted across scenarios): all correct and
  consistent with the pinned tests. `args.offline` is parsed-but-unread yet load-bearing (the CI entrypoint /
  docstring contract; offline is the default path), so not removable. No genuine dead code or unreachable
  branch.
- **Five shell scripts — no change.** Audit-hardened and correctly fail-closed; the one real within-file
  duplication (`ci_run_id_from_json` vs `ci_run_attempt_from_json`) is best left as two explicit functions —
  this is the repo's most consequential automation and the author deliberately favors inline clarity over
  another indirection layer. `restore_drill`/`backup_events`/`notify_webhook`/`state_snapshot` verified by
  reading + shellcheck; their side-effecting command sequences were not touched (HARD RULE 8).
- **`test_golden_scenarios_runner.py` Gemini success-envelope "dedup" — skipped.** Not a real win: there are
  4 distinct fake-response shapes, a single helper would cover only 3 and leave a mixed helper/inline style
  (worse consistency); the inline literals are self-documenting fixtures, not boilerplate.

## Parallel-safety note — and the shared-HEAD race that hit this session
This working tree was shared with the other 4 parallel instances; `git status` showed unrelated
modifications (`ops/dashboard/generate_dashboard.py`, `scripts/alert_relay.py`, others) belonging to other
parts. I staged **only my own four paths** (the three code files above + this report) with explicit
`git add` (never `-A`/`.`), and did not push/PR/merge or run any repo-wide formatter.

**However — the per-instance branch isolation the plan assumed did not hold.** Five instances shared ONE
working tree, and a git working tree has exactly ONE `HEAD`. Each instance's `git checkout <its branch>`
moved that single shared `HEAD` for everyone, so a `git commit` landed on whichever branch `HEAD` happened
to point at *at that instant* — not on the committing instance's own branch. Concretely: my commit
`e19c248` (parent = base `5486993`, containing exactly my 4 paths — the content was never wrong) landed on
`partC` because another instance had just checked it out; Part D's and Part C's commits then stacked on top
of mine, producing `partC = 18ab049 → 6f9e6b6(D) → e19c248(E) → base`, while `partD`/`partE` sat at base.
Recovering this needs a **force** branch-pointer rewrite (`git branch -f` / `update-ref` / delete+recreate),
all of which the sandbox classifier correctly gates — so it required operator action. Net outcome: my work
reached `main` **via `Union: merge partC`** (my commit was inside partC's ancestry), which is why the merge
series shows no separate `Union: merge partE`. Verified after the merge: all four Part-E changes are present
and intact in `main`, and the full unioned suite is green (606 pytest, 35 shell assertions, 70 node
assertions, shellcheck/ruff clean, golden `--offline` gate OK).

**Lesson for the next parallel round:** give each instance its own `git worktree` (or its own clone), not a
shared checkout — one `HEAD` per working tree makes "commit to your own branch" impossible to honour
concurrently, regardless of how carefully each instance stages its own paths.
