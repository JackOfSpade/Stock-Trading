# Parallel refactor 2026-07-17 — Part D report (Alerts, dashboard, split-tooling, prose-invariants)

Branch: `refactor/parallel-2026-07-17/partD`

## Inventory of owned files

Part D owns six runtime modules plus their tests. **`scripts/alert_relay.py`** is the out-of-session
alert / staged-order / weekly-heartbeat / catch-up webhook relay (reads BigQuery through the read-only
WIF SA, POSTs to a vendor-neutral webhook; the diversification channel to the Gmail-inbox emailer).
**`scripts/check_prose_invariants.py`** is a BLOCKING CI gate (`ci.yml`) that fails the build if
routine-executed prose re-instructs retired behavior, per `ops/prose_invariants.yaml`.
**`scripts/split_task_plan.py`** and **`scripts/split_strategy.py`** generate read-optimized per-routine
/ per-section slices of `Claude_Task_Plan.md` and `Strategy.md` (canonical monoliths stay authoritative;
both have a `--check` drift gate in CI). **`ops/dashboard/generate_dashboard.py`** renders the static
HTML health dashboard from BigQuery. **`ops/monitoring/alert_emailer.gs`** is an **AUDIT-ONLY** mirror of
a live Apps Script deployment (findings here are for an owner redeploy — not edited). Tests:
`tests/test_alert_relay.py`, `tests/test_split_strategy.py`, `tests/test_generate_dashboard.py` (existing),
and two new files this pass. Two modules (`check_prose_invariants.py`, `split_task_plan.py`) had **no
dedicated unit test** before this pass — only their CI `--check`/exit-code invocation.

Approach: an adversarial audit workflow fanned out one bug-hunter per owned file, then adversarially
verified every candidate finding (17 candidates → 11 confirmed, 6 refuted). Every confirmed source
change below was independently reproduced before applying, and each preserves exact observable behavior
(stdout strings, exit codes, CLI flags, output format). `--check` byte-identity on the real `Strategy.md`
/ `Claude_Task_Plan.md` proves the slug/guard changes are no-ops for the live tree.

## Verification (all green)

- `python -m pytest -q` — full suite passes (includes the other instances' concurrent changes).
- `python -m pytest -q` on the five owned test files — **118 passed** (`+63` new).
- `python scripts/split_strategy.py --check` / `split_task_plan.py --check` — in sync (byte-identical).
- `python scripts/check_prose_invariants.py` — OK, 6 invariants across 10 file-targets.
- `ruff check` on all owned `.py` + new test files — clean.

## Changes made (with why)

### `scripts/alert_relay.py` — NULL/empty-tz hardening (honors documented contract)
- `get_user_tz()`: `return rows[0]["tz"]` → `return rows[0]["tz"] or "America/Denver"`. The docstring
  already promises "falls back to America/Denver," but the code only did so on an *exception*; a NULL/empty
  `tz` value returned `None`/`""` cleanly.
- `fmt_ts()`: guard widened `if not v or ZoneInfo is None:` → `if not v or not tz_name or ZoneInfo is None:`.
  `ZoneInfo(None)` raises `TypeError`, which is **neither** `ValueError` nor `ZoneInfoNotFoundError`, so it
  escaped `fmt_ts`'s cosmetic fallback and — via `main()`'s best-effort `except Exception` — **silently
  dropped the entire alert batch**, the exact outcome the docstring forbids. For `tz_name == ""` the guard
  returns the same `"... UTC"` string the except-branch already produced (observable-identical).

### `ops/dashboard/generate_dashboard.py`
- `get_user_tz()`: same NULL/empty coalesce (`(rows[0]["tz"] if rows else None) or "America/Denver"`). A
  `None` tz here would reach `fmt_ts`, where `ZoneInfo(None)` `TypeError` **crashes the render loop** (it is
  outside `main()`'s query-only `except` tuple).
- `main()` except tuple: `FileNotFoundError` → `OSError`. Any spawn-time OS error from the `bq` subprocess
  (missing binary = `FileNotFoundError`, non-executable = `PermissionError`, PATH-is-a-dir = `IsADirectoryError`,
  all `OSError` subclasses) now yields the clean `"Query failed (is the bq CLI installed & authenticated?)"`
  diagnostic + `return 1` instead of an uncaught traceback. `FileNotFoundError ⊂ OSError`, so every
  previously-caught case still works; `CalledProcessError` (not an `OSError`) is kept explicit.

### `scripts/check_prose_invariants.py`
- **`nearest_heading()` fenced-code bug (real, latent).** `HEADING` (`^#{1,6}\s+`) matches ordinary code
  comments (`# foo`) inside ``` / ~~~ fences, which pervade the scanned `.md` files. `nearest_heading`
  scanned backward without fence-awareness, so under an `exempt_sections` rule a fenced `# comment` between
  the real heading and a forbid-match would be returned as "the nearest heading" — breaking the exemption
  (a sanctioned passage would FAIL the build, or a code comment could falsely suppress a real match). Fixed
  by adding `fence_mask()` (the same fence tracking `split_task_plan.py`/`split_strategy.py` already use) and
  skipping fenced lines. **Unreachable today** (no live rule uses `exempt_sections`), so observable-neutral
  for the current spec — but the shipped feature is now correct for the first rule that uses it.
- Removed the inert `| re.MULTILINE` from the pattern compile (patterns are searched one physical line at a
  time, so `^`/`$` already anchor to line ends and `MULTILINE` was a no-op that misleadingly implied
  cross-line matching). Added a comment stating the per-line contract.
- Switched the two bare `open(...)` reads (`load_spec`, `check_rule`) to context managers — matches the
  repo's other checkers and avoids a `ResourceWarning` under `python -W error`.

### `scripts/split_task_plan.py` — opaque crash → actionable error
- `group_start = max(i for i in ... if is_group(i))` raised a bare `ValueError: max() arg is an empty
  sequence` if the first routine heading preceded every top-level `# ` group header. Replaced with an
  explicit empty-guard that raises a clear, actionable message. Byte-identical for the real plan (proven by
  `--check`); only improves the diagnostic on a structurally-invalid plan.

### `scripts/split_strategy.py` — anchored slug rewrite
- `re.sub(r"strategy ([a-e]):.*", ...)` → `re.sub(r"^strategy ([a-e]):.*", ...)`. The rule is meant to fire
  only for a title that *starts* with "Strategy &lt;letter&gt;:"; unanchored it also matched a mid-title
  mention (e.g. "Notes on Strategy A: results") and silently truncated everything after it. Byte-identical
  for every current heading (all real ones begin with the phrase); `--check` confirms.

### Tests (`+63`)
- **NEW `tests/test_check_prose_invariants.py` (25).** Full branch coverage for the previously-untested
  BLOCKING gate: forbid/require XOR, exempt_line_regex, exempt_sections, the **fenced-comment fix** (unit +
  end-to-end), require-not-found, missing-file, no-files, duplicate/missing id, no-rules, ignorecase, the
  exact "OK" summary + counts, per-line (non-`MULTILINE`) matching, and a happy-path run of the real spec.
- **NEW `tests/test_split_task_plan.py` (15).** slug fallback, split preamble/group-intro across two cadence
  groups, `~~~`/```` fence guarding, `heading_to_id`→slug fallback, the **new groupless-plan error guard**,
  the **live duplicate-id collision loop** (`AR_att.md`/`AR_att_.md`), main write/`--check`/orphan paths.
- **`tests/test_alert_relay.py` (+11):** `get_user_tz` happy/NULL/empty/error; `fmt_ts` None/empty tz;
  end-to-end "batch NOT dropped when `state.user_tz.tz` is NULL"; `main()` no-webhook clean no-op.
- **`tests/test_generate_dashboard.py` (+6):** `get_user_tz` happy/NULL/empty/error; `main()` `PermissionError`
  + `FileNotFoundError` both yield the clean diagnostic (the OSError broadening).
- **`tests/test_split_strategy.py` (+6):** slug all-punctuation fallback + anchored-rule; `~~~` fence; orphan
  detection driven end-to-end through `main()` (`--check` returns 1 / non-check WARNING).

## Bugs fixed (severity / reachability)

| # | File | Bug | Reachable today? |
|---|------|-----|------------------|
| 1 | `alert_relay.py` | NULL/empty `tz` → `fmt_ts` `TypeError` → **whole alert batch silently dropped** (violates the function's own "never drop the batch" contract). | **Latent** — `state.user_tz` is a `COALESCE(..., 'America/Denver')` view, so `tz` is non-NULL today. Fix is defense-in-depth honoring the documented contract if the view/schema ever changes. |
| 2 | `generate_dashboard.py` | Same NULL/empty `tz` → `fmt_ts` `TypeError` → **crashes the dashboard render loop**. | Latent (same COALESCE-view guard). |
| 3 | `check_prose_invariants.py` | `nearest_heading` mis-attributes a forbid match to a fenced code-comment, breaking `exempt_sections` (false FAIL of a sanctioned passage, or false suppression of a real match). | Latent — no live rule uses `exempt_sections` yet; the shipped feature was broken for the first that does. |
| 4 | `generate_dashboard.py` | A non-`FileNotFoundError` `OSError` (e.g. `PermissionError`) from the `bq` spawn escaped as an uncaught traceback instead of the clean "Query failed" + `return 1`. | Reachable (cosmetic: both exit non-zero; the fix restores the intended clean diagnostic). |
| 5 | `split_task_plan.py` | Opaque `max() arg is an empty sequence` crash on a plan whose first routine precedes every `# ` group header. | Latent (real plan always has `# DAILY`); now an actionable message. |
| 6 | `split_strategy.py` | Unanchored slug rewrite truncates a title that mentions "Strategy &lt;letter&gt;:" mid-line. | Latent (all current headings start with the phrase). |

## Deferred / owner items

### `ops/monitoring/alert_emailer.gs` (AUDIT-ONLY — needs an **owner redeploy**; not edited)
1. **JSON.parse poison pill (line ~85).** `JSON.parse(props.getProperty('notified_alert_ids') || '[]')`
   runs inside the main `try`, but the *read/parse that gates delivery* is not individually guarded — while
   the corresponding `setProperty` **write** (lines ~122-124) *is*. If `notified_alert_ids` ever holds a
   non-JSON value (manual Script-Properties edit, truncated/partial write, tampering), `JSON.parse` throws on
   **every** poll before any send, indefinitely — permanently suppressing ALL alert delivery while `beat_(false)`
   keeps writing `'poll-error'` beats. **Fix:** wrap only the read+parse in its own try/catch defaulting to an
   empty Set (e.g. `const seen = new Set(safeParse());`), mirroring the write's defensive posture. Low severity
   (requires external tampering), well-scoped, no printed-output/format change.
2. **Sustained poll-error masks the dead-man's switch (cross-layer).** On a persistent BigQuery failure (the
   `QueryUsagePerDay ... custom quota exceeded` class the line-60 comment cites), every ~2h poll throws →
   `pollOk=false` → `beat_(false)` still INSERTs an `ops.heartbeat` row (`note='poll-error'`) **outside** the
   `try`. `state.automation_heartbeat` keys only on `MAX(beat_ts)` (`max_age_hours=8`) and never reads `note`,
   so the beat keeps the source "fresh" and the 8h DTS **never fires** while zero alerts are delivered and the
   outage is invisible. The `.gs` already records the note correctly; the gap is that **no consumer reads it**.
   **Fix is cross-layer and touches FROZEN files (not owned):** make `state.automation_heartbeat`
   (`bigquery/16`) note-aware (flag stale when the latest beat's `note='poll-error'`), OR have `beat_` skip/alter
   the healthy `'poll'` cadence on a persistent error so the DTS can trip. **Report only.**

### `ops/dashboard/generate_dashboard.py` — raw TIMESTAMP without `CAST AS STRING` (optional, NOT changed)
`main()` SELECTs `alert_ts` / `log_ts` as raw `TIMESTAMP` (lines ~134/138), unlike the sibling
`alert_relay.py`, which uses `CAST(alert_ts AS STRING)` and documents the verified wire form. If
`bq --format=json` ever emits an epoch form for a raw TIMESTAMP, `fmt_ts` would fall through to the
`"(UTC)"` branch. **Left as-is:** the dashboard has run in production and `fmt_ts` already handles the
`" UTC"`-suffixed wire form (guarded by `test_fmt_ts_space_utc_suffixed`); I cannot verify the live
`bq --format=json` TIMESTAMP form from this environment, so I did **not** change the SQL speculatively
("bias to safe, verified wins"). **Recommendation (optional):** add `CAST(... AS STRING)` to both SELECTs to
match `alert_relay.py`'s verified-good, deterministic path.

### `scripts/split_task_plan.py` — `seen_routine_in_group` is provably redundant (NOT removed)
Adversarial verify CONFIRMED the invariant `cur is None ⟺ seen_routine_in_group is False`, so the
`elif not seen_routine_in_group:` guard is always-true when reached (≡ a bare `else`) and the flag can be
deleted with no behavior change. **Left in place deliberately:** it is not a bug, and removing it is a
control-flow edit in a subtle parser loop — outside my safety threshold for an *unmonitored* refactor even
with `--check` + new tests as backstops. Flagged here for a future supervised cleanup.

### `ops/weekly_report/test_pure_helpers.js` — `alertSubject_` canary+recurring test gap (not owned)
The `alertSubject_` composition path for a batch that is a canary **plus** a recurring
`termination_close_staged` re-send (the `(+N test)` + `UNCONFIRMED TERMINATION CLOSE (recurring)` subject)
has no test. `test_pure_helpers.js` is not a Part-D file — for the owner / the owning instance to add.

## Note on the shared working tree

The working tree contains concurrent, unstaged changes from the other parallel instances
(`scripts/dbt_parity.py`, `scripts/check_cadence_consistency.py`, `scripts/check_live_sql_parity.py`,
`tests/test_check_dbt_view_coverage.py`, `tests/test_gen_routine_lists.py`). Per the parallel-run rules I did
**not** touch or stage any of them; my commit stages only the Part-D owned paths via explicit `git add`.
