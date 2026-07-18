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
- `python -m pytest -q` on the five owned test files — **119 passed** (`+64` new).
- `python scripts/split_strategy.py --check` / `split_task_plan.py --check` — in sync (byte-identical).
- `python scripts/check_prose_invariants.py` — OK, 6 invariants across 10 file-targets.
- `python scripts/check_script_version_consistency.py` — OK (the `.gs` was **not** modified; see owner items).
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
- **`main()` SELECTs now `CAST(alert_ts AS STRING)` / `CAST(log_ts AS STRING)`** (2026-07-17 follow-up).
  Previously the two TIMESTAMP columns were selected raw and rendered via bq's default JSON form; casting
  pins the deterministic `"...+00"` wire form that `fmt_ts` is tested against, matching `alert_relay.py`'s
  verified-good, proven-in-production pattern (`ORDER BY` on the same alias sorts chronologically — the
  zero-padded ISO string sorts lexically == temporally). Locked by a new `+00`-wire-form test.
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

### `scripts/split_task_plan.py` — opaque crash → actionable error + dead-flag removal
- `group_start = max(i for i in ... if is_group(i))` raised a bare `ValueError: max() arg is an empty
  sequence` if the first routine heading preceded every top-level `# ` group header. Replaced with an
  explicit empty-guard that raises a clear, actionable message. Byte-identical for the real plan (proven by
  `--check`); only improves the diagnostic on a structurally-invalid plan.
- **Removed the provably-redundant `seen_routine_in_group` flag** (2026-07-17 follow-up). Adversarial verify
  CONFIRMED the invariant `cur is None ⟺ seen_routine_in_group is False`, so the `elif not
  seen_routine_in_group:` guard was always-true when reached (≡ a bare `else`). Simplified to `else:` and
  dropped the two flag assignments. Byte-identical for the real plan (`--check`) and covered by the new
  `split()` group-intro-accumulation tests. (Initially deferred as "unmonitored-refactor risk"; applied now
  under direct owner direction, with `--check` + tests as the backstop.)

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

## Owner actions required (could NOT be applied in-repo — here is the exact patch)

> **RESOLVED 2026-07-18 — no owner action remains.** The constraint below was real only for the
> parallel-refactor commit itself (bigquery/** frozen per-instance). The same night, commit
> `05ed20b` swept the coordinated change (`.gs` v3 + `bigquery/43` seed + the 16/58 DTS-masking
> fix) onto `main`, and it was deployed + verified live (`state.script_version_drift`:
> `alert_emailer` v3/v3, drift=false, 2026-07-18). The local branch
> `fix/alert-emailer-poison-pill-and-dts-2026-07-18` (de8fd93) was a byte-identical duplicate of
> that already-merged work and has been deleted. Runbook kept below for the historical record.

Two `alert_emailer.gs` bugs were **genuinely blocked from landing in this parallel-refactor commit**, and
directed to fix them, I did **not** edit the `.gs` — doing so would break CI or corrupt the deploy-mirror
invariant. The reasons (and the ready-to-apply patch) follow so the owner can apply them via the proper
Apps-Script redeploy workflow.

**Why the `.gs` can't be edited here:** `ops/monitoring/alert_emailer.gs` is a **version-controlled mirror
of a LIVE Apps Script deployment**. `check_script_version_consistency.py` (a CI gate, `test_real_repo_is_consistent`)
asserts the `.gs`'s `ALERT_SCRIPT_VERSION` equals `bigquery/43_script_version_registry.sql`'s seed. So a
functional `.gs` change forces a version bump (the file's own "bump on every functional change" contract) →
which forces a lockstep `bigquery/43` seed bump → but **`bigquery/**` is FROZEN for every instance**, so I
cannot make them agree. Editing the `.gs` *without* a bump is worse: the repo would then carry fixed code and
live would carry buggy code, **both labeled `v2`** — defeating the version-drift detector the registry exists
to power. The correct fix is a single coordinated owner step (edit + bump + registry + redeploy), below.

### Ordered runbook (do the steps in this sequence)

Fix **B** (bigquery/16) is independent — apply it anytime. Fix **A** (the `.gs` poison pill) is a coordinated
version bump whose **repo commit** and **live apply** must be sequenced (or `state.script_version_drift`
false-alarms during the gap). Steps:

1. **A-repo (one commit):** edit `alert_emailer.gs` (patch A1 below) **and** `bigquery/43` seed (patch A2
   below) together. `check_script_version_consistency.py` stays green because both now say `v3`.
2. **B-repo + live:** apply patch B to `bigquery/16` and re-run the `CREATE OR REPLACE VIEW` live (BigQuery
   MCP/console). Idempotent, no data migration, no ordering constraint.
3. **A-live redeploy:** in the "Stock-Trading Automation" Apps Script project (script.google.com), paste the
   updated `alert_emailer.gs` over the existing file, **Save**, then **Run → `testAlertCheck()`** once. That
   authorizes/verifies it *and* forces an immediate `ops.heartbeat` beat carrying `version='v3'`. The 2h
   trigger stays as-is (no need to reinstall).
4. **A-live registry (AFTER step 3):** run `bigquery/43`'s `MERGE state.expected_script_versions …` live so
   `expected_version='v3'`. Doing this **after** step 3 avoids the documented false-alarm window (bigquery/43
   header: "do not apply this MERGE live until the owner has re-pasted … into the live Apps Script project").
5. **Verify:** `SELECT * FROM state.script_version_drift WHERE script_name='alert_emailer'` → `monitored=TRUE,
   drift=FALSE`; `SELECT * FROM state.automation_heartbeat WHERE source='alert_emailer'`.

### Patch A1 — JSON.parse poison pill (`alert_emailer.gs`, in `checkAlerts_`)
`JSON.parse(props.getProperty('notified_alert_ids') || '[]')` runs inside the main `try` but is not
individually guarded — while the corresponding `setProperty` **write** *is*. If `notified_alert_ids` ever
holds a non-JSON value (manual Script-Properties edit, truncated/partial write, tampering), `JSON.parse`
throws on **every** poll before any send, indefinitely — **permanently suppressing ALL alert delivery** while
`beat_(false)` keeps the heartbeat fresh (see patch B). Replace:
```js
    const props = PropertiesService.getScriptProperties();
    const seen = new Set(JSON.parse(props.getProperty('notified_alert_ids') || '[]'));
```
with:
```js
    const props = PropertiesService.getScriptProperties();
    let seen;
    try {
      seen = new Set(JSON.parse(props.getProperty('notified_alert_ids') || '[]'));
    } catch (e) {
      Logger.log('notified_alert_ids parse failed (corrupt property?) — treating as empty: ' + e);
      seen = new Set();   // degrade to at-worst a re-send, never permanent silence
    }
```
And bump the version const in the same file:
```js
const ALERT_SCRIPT_VERSION = 'v3';   // was 'v2'
```

### Patch A2 — registry lockstep (`bigquery/43_script_version_registry.sql`, the MERGE seed)
In the `MERGE state.expected_script_versions` `UNNEST([...])`, change the `alert_emailer` STRUCT's
`'v2' AS expected_version` → `'v3' AS expected_version` and refresh its `git_note`, e.g.:
```sql
    STRUCT('alert_emailer' AS script_name, 'v3' AS expected_version,
           '2026-07-18: alert_emailer.gs v3 — guard the notified_alert_ids JSON.parse (corrupt Script Property no longer permanently suppresses all delivery). Do NOT apply this MERGE live until the .gs has been re-pasted into the live Apps Script project (else state.script_version_drift false-alarms vs the still-v2 live heartbeat).' AS git_note),
```
(Committed together with A1, this keeps `check_script_version_consistency.py` green — both files say `v3`.)

### Patch B — sustained poll-error masks the dead-man's switch (`bigquery/16_automation_health.sql`)
On a persistent BigQuery failure (the `QueryUsagePerDay ... custom quota exceeded` class the `.gs` line-60
comment cites), every ~2h poll throws → `pollOk=false` → `beat_(false)` still INSERTs an `ops.heartbeat` row
(`note='poll-error'`) **outside** the `try`. `state.automation_heartbeat`'s `last` CTE does `MAX(beat_ts)`
with no `note` filter, so a poll-error beat keeps the source "fresh" and the 8h DTS **never fires** while zero
alerts deliver and the outage is invisible. The `.gs` already records the note correctly — the consumer is
what needs updating. **Minimal one-line fix** to the `last` CTE (consistent with this file's self-bootstrapping
"monitored once it has produced ≥1 *good* signal" convention — a source that has only ever poll-error'd is
`monitored=FALSE`, matching `state.backup_health`):
```sql
last AS (
  SELECT source, MAX(beat_ts) AS last_beat_ts
  FROM `stock-trading-498512.ops.heartbeat`
  WHERE note IS DISTINCT FROM 'poll-error'   -- a poll-error beat is NOT proof of life; excluding it lets a
                                             -- sustained emailer outage age out and trip the DTS (2026-07-18).
                                             -- Keeps 'poll'/'report'/NULL notes; weekly_report never writes
                                             -- 'poll-error' so its liveness is unchanged.
  GROUP BY source
)
```
**Optional stronger variant** (also alarms on deploy-then-immediately-broken, i.e. a source that has beaten but
*never healthily*): keep `last_beat_ts` as the true `MAX(beat_ts)` to arm `monitored`, and add
`MAX(IF(note IS DISTINCT FROM 'poll-error', beat_ts, NULL)) AS last_healthy_ts`; then base `age_hours` and
`stale` on `last_healthy_ts` (`stale = monitored AND (last_healthy_ts IS NULL OR TIMESTAMP_DIFF(...,
last_healthy_ts, HOUR) > max_age_hours)`). Do **not** "fix" this on the `.gs` side by suppressing the poll-error
beat — that beat is the intended, correct signal. Re-run the `CREATE OR REPLACE VIEW` live after editing.

### `ops/weekly_report/test_pure_helpers.js` — `alertSubject_` canary+recurring test gap (not owned)
The `alertSubject_` path for a batch that is a canary **plus** a recurring `termination_close_staged` re-send
(the `(+N test)` + `UNCONFIRMED TERMINATION CLOSE (recurring)` subject) has no test. `test_pure_helpers.js` is
not a Part-D file — for the owner / owning instance to add.

## Note on the shared working tree + branch collision

**Shared HEAD, one working tree.** All 5 parallel instances share one `.git` and one working tree (not
per-instance worktrees). During this session the working tree carried concurrent, unstaged changes from the
other instances (`scripts/dbt_parity.py`, `check_cadence_consistency.py`, `check_live_sql_parity.py`, and
several `tests/*` files) — I did **not** touch or stage any of them.

**Commit landed on the wrong branch, then recovered.** Because HEAD is shared, another instance's `git checkout`
ran between my `git checkout -b partD` and my `git commit`, so my commit `6f9e6b6` landed on **`partC`** (stacked
on Part E's likewise-misplaced `e19c248`) while `partD` stayed at the base `5486993`. I recovered **without
touching HEAD or any other branch**: built a clean commit off the intended base `5486993` containing only my
owned files (via `commit-tree`/`update-ref` plumbing with a compare-and-swap guard) and repointed `partD` to it.
`partD` is now correct and self-contained (verified: it changes nothing outside my owned paths, and its content
matches the files the green suite ran against). Observed later: `partE` was independently repointed by the Part E
instance to its own clean `e19c248` (confirming each instance recovers its own branch — and that my not touching
their branches was correct). `partC` still carries my redundant `6f9e6b6` in its ancestry; that is Part C's branch
to clean, and I deliberately left it (and every other instance's branch) untouched — resetting them risks
destroying work I did not create (e.g. Part E's commit was, at one point, reachable *only* via `partC`).

**Recommendation:** this setup needs **per-instance git worktrees** (or serialized commits). A shared HEAD makes
correct per-branch attribution impossible — commits race onto whichever branch happens to be checked out. I did
not push, PR, or merge anything.
