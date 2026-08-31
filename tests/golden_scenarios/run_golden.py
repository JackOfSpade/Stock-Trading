#!/usr/bin/env python3
"""Golden-scenario prose regression runner (ITEM 20, 2026-07-11).

WHY THIS EXISTS. This system's real source code is prose (Strategy.md, Operating_Protocols.md,
Claude_Task_Plan.md routine bodies) read fresh by an LLM every routine run. Every existing CI check
(scripts/check_cadence_consistency.py, check_roster_consistency.py, check_autonomy_consistency.py,
split_strategy.py --check) is a STRUCTURAL fact scraper — none of them evaluate what a routine would
DECIDE when it reads the prose. tests/golden_scenarios/scenarios.yaml pins 31 concrete decision
scenarios (regime-router edge cases, kill-trigger/gate mechanics, per-strategy entry criteria, the AI
Park Allocator's daily call, the AI Research-Significance Screen) with an expected GO/NO-GO |
CONTINUE/TERMINATE | ACTIVATE/DO-NOT-ACTIVATE call and the specific rule that produces it. This script
is the runner.

TWO MODES, matching the two-job split in .github/workflows/golden-scenarios.yml:

  --offline (default; NO NETWORK; the CI HARD GATE)
      Pure schema validation: every scenario has the required fields, ids are unique, every
      governing_file exists on disk, and expected_decision starts with a recognized token. This is
      deterministic and must stay green on every push — it is what keeps the golden set itself from
      silently rotting (a scenario with a typo'd expected_decision or a renamed governing_file would
      otherwise vacuously "pass" any real check forever).

  --live (NETWORK; calls a model; ADVISORY ONLY — see the workflow header for why this never hard-
      blocks a merge)
      For each GROUP of scenarios that share an identical governing_files set (BATCHING, added
      2026-08-17 — see the "BATCHING" comment block above group_scenarios_for_batching() below for the
      full measured-cost narrative), reads the CURRENT text of the group's governing_files ONCE, sends
      one pinned prompt (BATCH_EVAL_PROMPT_TEMPLATE for a group of 2+, or the original single-scenario
      EVAL_PROMPT_TEMPLATE for a lone scenario / a group of 1) to a live model, parses a DECISION line
      per scenario from the reply, and diffs each against its own expected_decision's leading token.
      PROVIDER: Gemini's FREE tier (GEMINI_API_KEY), the sole provider — walks GEMINI_MODEL_LADDER,
      degrading model on per-model daily-quota exhaustion; stdlib REST, no SDK dependency; thinking left
      ON for accuracy. Prints a pass/fail table and, for the first leading-token mismatch on a NON-EMPTY
      governing_files reread, prints a GitHub Actions `::warning::` annotation plus the
      events.queue_events INSERT this script itself has no BigQuery write credentials to execute (CI
      stays read-only by design). WIRED FOR REAL (self-improvement audit 2026-07-15, CONFIRMED GAP
      golden-scenarios-prose-regression-unwired): D3 (Claude_Task_Plan.md's "GOLDEN-SCENARIO
      PROSE-REGRESSION CHECK" step) has full repo+BigQuery write access and runs daily — it performs the
      SAME governing-files-changed-since-last-check + re-evaluate logic independently (D3 IS the model,
      no separate API call), and actually files the queue entry (review_type='prose-regression', now a
      recognized AR review_type — see the Adversarial Reviews section) on a real mismatch. This CI job
      was a secondary, push-time signal only; as of 2026-08-30 NO CI job invokes --live at all
      (golden-prose-daily.yml, which held the last such invocation, was deleted along with the
      GEMINI_API_KEY repo secret — its flips were measured to be free-tier judge noise, not prose
      regressions, while D3 logged zero flips over the same scenarios). --live therefore survives as
      a MANUAL tool only; set GEMINI_API_KEY in your own environment to use it. Always exits 0
      (advisory) unless the offline schema gate itself fails first, or setup fails outright (missing API
      key/library), which is reported but still does not fail the *build* — the workflow's
      continue-on-error covers that.

      BATCHING (2026-08-17 — GOLDEN_BATCH, default ON; GOLDEN_BATCH=0 is the escape hatch back to
      today's exact one-call-per-scenario behavior): CI run 32043614925 measured 33 scenarios needing
      24.1MB / ~6.02M tokens of governing-file text if evaluated one-scenario-per-call (mean ~182k
      tok/scenario — Claude_Task_Plan.md alone is ~946KB/236k tok, re-sent whole on every one of the 16+
      scenarios it governs), and the job evaluated only 11 of 33 in 2987s (~271s/scenario) before its run
      budget stopped it — most of that time and nearly all of those tokens were the SAME governing text
      re-sent over and over for scenarios that share a governing_files set. group_scenarios_for_batching()
      groups scenarios by that shared set (33 scenarios -> ~7 groups against the real scenarios.yaml) so
      the shared text is sent ONCE per group instead of once per scenario. See run_live()'s own doc
      comment for exactly how a group is dispatched, and the OBSERVABILITY comment above
      GEMINI_MODEL_LADDER below for the per-attempt/per-group logging added alongside batching so a run
      like 32043614925 is diagnosable instead of just "11 of 33, no idea where the time went."

      SECTION SCOPING (2026-08-17, follow-up to the above — GOLDEN_SECTION_SCOPE, default ON;
      GOLDEN_SECTION_SCOPE=0 sends every governing_files entry whole, for an A/B run against the scoped
      verdicts): batching alone was not enough. CI run 32069773377 (AFTER batching landed) still only
      evaluated 23 of 33 scenarios, with 429s(rpm=83) out of 88 attempts — 94% REJECTED — at just 1.78
      requests/min but 480,044 tokens/min: the binding constraint is TOKENS-per-minute, not requests, and
      the single largest prompt was 294,554 tokens — 118% of an entire minute's free-tier budget, so it
      could never succeed no matter how long the runner waited (a retry re-sends the whole prompt, which is
      how 1.37M tokens of real content became 23.7M on the wire). A scenario's `governing_sections` (per-
      scenario, optional; see the SECTION SCOPING comment above _read_governing_text() below for the exact
      schema and extraction rules) scopes any governing_files entry down to just the heading section(s) that
      actually decide it, instead of the whole file — the only remaining lever once batching had already
      collapsed the PER-SCENARIO duplication. validate_offline() is the hard gate for this (a mis-declared
      anchor fails the BUILD, never silently starves the judge); group_scenarios_for_batching()'s key
      changed from a plain governing_files SET to a hash of the ASSEMBLED (possibly scoped) governing TEXT,
      so two scenarios sharing a file but scoping it to different sections never get merged into one call
      that would otherwise silently show them the wrong excerpt.

Usage:
  python tests/golden_scenarios/run_golden.py --offline
  python tests/golden_scenarios/run_golden.py --live [--scenario ID ...]   # needs GEMINI_API_KEY
  python tests/golden_scenarios/run_golden.py --scenarios-for-changed [--changed-file PATH ...]
      Utility mode (no network): prints, one per line, the ids of scenarios whose governing_files
      intersect the given --changed-file path(s), then exits — no offline/live run. Originally added
      (2026-07-30 cost-scoping) for golden-scenarios.yml's now-retired `prose-regression` job to compute
      the --scenario filter for --live from the push's changed files. CORRECTED (2026-08-31 code-quality
      pass): that job no longer exists (moved to golden-prose-daily.yml on 2026-08-21, that whole file
      deleted 2026-08-30) and D3's GOLDEN-SCENARIO PROSE-REGRESSION CHECK — the routine that replaced it
      as the real landing surface — does NOT call this function or this CLI flag; D3 recomputes the same
      idea itself inline, per scenario, via `git log --since=<D3's last run> -- <that scenario's
      governing_files>` (Claude_Task_Plan.md). This mode currently has NO production caller — it exists
      only as a unit-tested utility (tests/test_golden_scenarios_runner.py). See
      scenarios_for_changed_files() for the fail-open rules (no --changed-file at all, or a change
      under tests/golden_scenarios/ itself, both select EVERY scenario id) in case a future caller adopts it.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import time

try:
    import yaml
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SCENARIOS_PATH = os.path.join(ROOT, "tests", "golden_scenarios", "scenarios.yaml")

REQUIRED_FIELDS = ("id", "situation", "governing_files", "expected_decision", "rationale")

# Vocabulary the offline schema check accepts as a valid expected_decision LEADING token (free text may
# follow in parentheses, e.g. "CONTINUE (routes to review, not direct terminate)" — see scenarios.yaml's
# schema comment). Keeps a typo'd/empty expected_decision from silently validating, without constraining
# the free-text qualifier that follows it.
DECISION_LEAD_TOKENS = ("GO", "NO-GO", "CONTINUE", "TERMINATE", "ACTIVATE", "DO-NOT-ACTIVATE")

# Which DECISION_LEAD_TOKENS are actually valid for a given scenario `category` — catches a
# mis-categorized/copy-paste fixture (e.g. a kill_trigger scenario expecting "GO") that the bare
# vocabulary check above cannot, since GO/NO-GO and CONTINUE/TERMINATE are both individually valid tokens.
CATEGORY_TOKENS = {
    "regime_router": {"ACTIVATE", "DO-NOT-ACTIVATE"},
    "kill_trigger": {"CONTINUE", "TERMINATE"},
    "strategy_b_entry": {"GO", "NO-GO"},
    "strategy_a_entry": {"GO", "NO-GO"},
    "strategy_d_entry": {"GO", "NO-GO"},
    "strategy_e_entry": {"GO", "NO-GO"},
    # GO/NO-GO is a proxy vocabulary here too (there is no native park-allocator/research-screener
    # decision token — see scenarios.yaml's "VOCABULARY NOTE ON PA-*"/"...RS-*" headers) but the proxy
    # still needs scoping like every other category: without an entry here the live model was offered
    # all six DECISION_LEAD_TOKENS and would pick a correct-sentiment/wrong-vocabulary answer (e.g.
    # ACTIVATE instead of GO), scoring as a flip against nothing but vocabulary (fixed 2026-07-26).
    "park_allocator": {"GO", "NO-GO"},
    "research_screener": {"GO", "NO-GO"},
}

# ---- Gemini (Google AI Studio) live-eval provider (2026-07-17) ----
# The advisory live run uses Gemini's FREE tier exclusively (owner directive 2026-07-17 — no paid
# Anthropic fallback). It is enabled whenever GEMINI_API_KEY is set, and skips cleanly otherwise. The
# Gemini path uses the stdlib (urllib) REST endpoint, so it adds NO pip dependency to CI. The ladder
# below is tried best-quality-first; a model is abandoned PERMANENTLY (added to the run-level
# state["dead"] set, skipped by every later scenario too) only on a per-DAY quota exhaustion or a hard
# error — NOT on a per-minute rate limit (see the RPM constants below, and the ladder-rewind doctrine
# comment further down for how a purely-transient exhaustion is handled instead). "Thinking" is left ON
# (default/dynamic) — this is an accuracy check whose whole job is catching
# subtle decision flips, so the model should reason; the adaptive maxOutputTokens budget below (which
# auto-escalates on truncation) keeps that reasoning from crowding out the DECISION line.
#
# LADDER MEMBERSHIP verified live 2026-07-17 by probing generateContent per model with this project's
# key: the Pro tier has ZERO free-tier quota, and the whole 2.5 series (`gemini-2.5-flash`,
# `gemini-2.5-flash-lite`) returns 404 NOT_FOUND for this key's project — they are deliberately NOT in
# the ladder, since a dead rung just burns a request and a ladder slot. The survivors, best-first:
#   gemini-3.5-flash        — best quality; 5 RPM / 20 RPD
#   gemini-3-flash-preview  — next best;    5 RPM / 20 RPD
#   gemini-3.1-flash-lite   — deep reservoir; 15 RPM / 500 RPD (keeps the check alive once the top two
#                             exhaust their small daily quotas; 23 scenarios > 20 RPD, so this WILL be
#                             reached on a full run)
# Override the whole ladder with the GEMINI_MODEL_LADDER env var (comma-separated).
#
# ---- OBSERVABILITY (2026-08-17) ----
# CI run 32043614925 (2026-08-17) evaluated only 11 of 33 scenarios in 2987s before the run budget
# stopped it, and the ONLY visible artifact was that one number — no per-attempt log, no indication of
# how many 429s were hit, of which kind, how many seconds were spent sleeping vs. actually calling the
# model, or how many tokens had been sent. A run that degrades gracefully (GEMINI_RUN_BUDGET_S) but is
# completely opaque about WHY it degraded is barely better than a hang. Every _post() attempt (including
# every RPM retry and every ladder rewind — the SAME prompt re-sent, so these dominate total token spend)
# now prints one `::debug::` line to stderr with: model, a monotonic run-wide attempt number, an approx
# input-token count (len(prompt)//4), the HTTP status (or ERR for a transport-level failure), elapsed
# seconds for that one attempt, and a classification of ok / rpm-429 / daily-quota-429 / hard-failure.
# run_live() prints one more line per GROUP as it finishes (ids, elapsed, attempts used), and one final
# run-level summary line (wall-clock, total attempts, 429s by kind, total tokens sent INCLUDING every
# retry, and seconds spent sleeping split by pacing / RPM-retry / rewind-cooldown). All of it stays on
# stderr, like the existing `::notice::`/`::warning::` annotations, and all prints in the live path pass
# flush=True so a killed/timed-out job still leaves a readable trail — belt-and-suspenders alongside a
# workflow-level PYTHONUNBUFFERED=1 when stdout/stderr aren't already line-buffered under a non-tty
# runner. CORRECTED (2026-08-31 code-quality pass): the `prose-regression` job this comment used to cite
# no longer exists in golden-scenarios.yml (moved to golden-prose-daily.yml on 2026-08-21, that whole
# file deleted 2026-08-30) — `grep -n PYTHONUNBUFFERED .github/workflows/*.yml` currently matches
# nothing, so --live (manual-only now) is not run by any surviving workflow, and flush=True above is
# what actually keeps live-mode output ordered today.
#
# EXTENDED 2026-08-17, same day (RPM-retry retune, CI run 32060180247 — this initial telemetry is what
# made that run's 2021s-of-2998s-asleep-in-RPM-retry finding measurable at all; see the comment above
# GEMINI_RPM_MAX_RETRIES for the full narrative and the resulting 5->2 retune): the final summary line now
# also reports how many RPM-retry sleeps honoured a server-supplied RetryInfo.retryDelay vs. fell back to
# the flat GEMINI_RPM_RETRY_DELAY_S default (state['sleep_rpm_retry_server_n'] / ['..._default_n'], set in
# _try_model's RPM branch via _has_retry_delay()), and the total count of ladder-rung switches
# (state['ladder_switches'], incremented in _gemini_call's dispatch loop every time it moves off a rung
# without succeeding on it) — so a future run's summary line can show directly whether the retune is
# landing (more, earlier switches) instead of that only being inferable from the sleep-second totals.
GEMINI_MODEL_LADDER = [
    m.strip() for m in os.environ.get(
        "GEMINI_MODEL_LADDER",
        "gemini-3.5-flash,gemini-3-flash-preview,gemini-3.1-flash-lite",
    ).split(",") if m.strip()
]
GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"

# Free-tier 429s come in TWO flavors that MUST be handled differently — conflating them is what broke the
# first live run (2026-07-17): the runner fires 23 scenarios back-to-back, tripped the 5-requests-per-
# MINUTE limit at scenario 7, and, because every 429 was treated as "this model is done", it burned the
# entire ladder in ~60 seconds and produced zero results for 17 of 23 scenarios.
#   * per-MINUTE (RPM) — TRANSIENT. Wait out the API's suggested RetryInfo.retryDelay (via _retry_delay_s()
#     in _try_model's RPM branch below, NOT a flat GEMINI_RPM_RETRY_DELAY_S wait — matches the ladder-
#     rewind cooldown's own RetryInfo honoring further down) and retry the SAME model. Rate-rejected
#     requests do not consume the daily quota.
#   * per-DAY (RPD)    — persistent for the rest of the day. Advance the ladder AND mark the model dead
#     (state["dead"], sticky for the rest of the run) — waiting is futile.
#
# RETUNED 2026-08-17 (CI run 32060180247 — measurable only because of the OBSERVABILITY telemetry added
# earlier the same day, see the comment block above GEMINI_MODEL_LADDER): a --live run evaluated just 23 of
# 33 scenarios before GEMINI_RUN_BUDGET_S stopped it, and its own new summary line showed 2021.0s of the
# 2998.8s budget spent (67%) asleep in RPM-retry backoff alone — vs. 479.5s pacing + 329.0s rewind cooldown
# (attempts=91, tokens_sent~=24.6M including every retry). At the old GEMINI_RPM_MAX_RETRIES=5, ONE rung
# alone could burn up to 5*20=100s of sleep before the ladder ever tried a DIFFERENT model, and with all 3
# ladder rungs RPM-exhausted on the same call — the exact "every still-live rung stayed RPM-exhausted
# through N rewind(s)" failure this run hit on group 5/7 (KT-01, KT-04) — that is up to 300s spent before
# the first rewind even fires. Moving to the NEXT rung costs NO sleep at all and is strictly more likely to
# succeed than re-hitting the SAME rate-limited rung again, because each model carries its OWN per-model
# quota (see the ladder-membership comment above GEMINI_MODEL_LADDER) — RPM exhaustion on rung N says
# nothing about rung N+1's remaining capacity this minute. The ladder already supplies BREADTH (3 rungs)
# and the rewind loop already supplies DEPTH (GEMINI_LADDER_REWINDS=6 full passes); spending most of a
# call's retry budget re-sleeping on ONE rung before ever trying a different model was the single largest
# source of the wasted wall-clock measured above, so this drops from 5 to 2 retries per rung: enough to
# ride out a per-minute window that is about to roll over, without sitting through three more of the same
# wait when a fresh, differently-quota'd rung is sitting right there. Still fully env-overridable for a
# future re-tuning pass against fresh measurements.
GEMINI_RPM_MAX_RETRIES = int(os.environ.get("GEMINI_RPM_MAX_RETRIES", "2"))
GEMINI_RPM_RETRY_DELAY_S = float(os.environ.get("GEMINI_RPM_RETRY_DELAY_S", "20"))

# CORRECTED 2026-08-17 (this was still broken, just delayed): once GEMINI_RPM_MAX_RETRIES was spent on a
# model, the OLD code advanced the same sticky `state["idx"]` cursor a hard/permanent failure uses,
# permanently burying a model that was merely rate-limited for the CURRENT minute. On a scenario batch
# fired back-to-back, all three ladder rungs can RPM-out on scenario 1 before the first per-minute window
# resets — that stamped the cursor past the end of the ladder, and every later scenario hit the "ladder
# already exhausted earlier this run" short-circuit with ZERO attempts (live CI run 32039658866: 33
# scenarios scoped, 1 attempted, 32 short-circuited). Fixed by splitting the single sticky cursor into
# two independent mechanisms:
#   * state["dead"] — a set of model ids abandoned for a HARD reason (HTTP 401/403/404/400/5xx, any
#     per-DAY 429, a URLError/TimeoutError/ValueError, an empty/safety-blocked response, or still-
#     truncating at GEMINI_MAX_OUTPUT_TOKENS_CEIL). Sticky for the whole run, exactly like the old `idx`
#     cursor was — this preserves today's correct behavior for genuinely persistent failures.
#   * RPM-only exhaustion is NEVER added to state["dead"]. It only skips the model for the REST OF THE
#     CURRENT _gemini_call — the next scenario's call tries it again fresh, since a per-minute window
#     resets in well under the time between two scenarios.
#   * LADDER REWIND: if every still-live (not-yet-dead) rung gets RPM-exhausted within ONE call — the
#     pathology above — sleep the cooldown (honouring the failing request's own RetryInfo.retryDelay when
#     one was present, else GEMINI_LADDER_REWIND_COOLDOWN_S) and retry the whole still-live ladder from
#     the top, bounded by GEMINI_LADDER_REWINDS rewinds before finally raising. A rung already in
#     state["dead"] is never retried by a rewind (a hard failure is still permanent). A rewinds-exhausted
#     raise for ONE scenario does NOT touch state["dead"] and does NOT stop the run — owner directive
#     2026-08-17 ("i can wait, just make sure it dont fail ... it can wait and auto retry and eventually
#     complete"): no single scenario's outcome may prevent LATER scenarios from attempting their own call;
#     the only thing that legitimately stops the whole run early is genuine whole-ladder PERMANENT death
#     (every rung in state["dead"]) or the run wall-clock budget below — waiting cannot fix either of
#     those, so both exit promptly instead of burning rewinds/budget on a lost cause.
#   * PACING: GEMINI_MIN_CALL_INTERVAL_S paces consecutive requests (measured from the actual last
#     request, not a flat per-call sleep) to stay under the ~5 RPM free-tier ceiling in the first place,
#     so tripping RPM at all — and needing a rewind — becomes the exception rather than the norm.
#   * RUN BUDGET: GEMINI_RUN_BUDGET_S is a hard wall-clock ceiling on the WHOLE --live run (tracked from
#     the first call, in _select_live_caller's state), independent of the workflow's own job-level
#     `timeout-minutes` backstop (golden-scenarios.yml) — this one degrades gracefully (stop calling,
#     report what was actually evaluated) instead of the job just getting killed mid-request. Checked
#     before every call AND before every sleep ("never start a sleep that would overrun it"): a run that
#     is out of budget stops immediately rather than burning the remainder on one more wait.
GEMINI_LADDER_REWINDS = int(os.environ.get("GEMINI_LADDER_REWINDS", "6"))
GEMINI_LADDER_REWIND_COOLDOWN_S = float(os.environ.get("GEMINI_LADDER_REWIND_COOLDOWN_S", "65"))
GEMINI_MIN_CALL_INTERVAL_S = float(os.environ.get("GEMINI_MIN_CALL_INTERVAL_S", "13"))
GEMINI_RUN_BUDGET_S = float(os.environ.get("GEMINI_RUN_BUDGET_S", "3000"))

# Adaptive output-token budget. Thinking is ON (for accuracy), and thinking tokens are drawn from the
# same maxOutputTokens budget — so a hard scenario can occasionally reason past the budget and get
# truncated (finishReason=MAX_TOKENS) before it ever emits the DECISION line. Rather than pin one fixed
# cap (too small = spurious truncation errors; too big = wasteful default), the caller STARTS at _START
# and, on a MAX_TOKENS truncation, DOUBLES the budget and retries the SAME model until it succeeds or
# reaches _CEIL (then it advances the model ladder). Free-tier TPM is 250K, so even the ceiling is one
# request token-wise; the only cost of a retry is one unit of the per-model daily request quota, and
# truncation is rare at the _START default, so escalation almost never triggers. Both are env-overridable.
GEMINI_MAX_OUTPUT_TOKENS_START = int(os.environ.get("GEMINI_MAX_OUTPUT_TOKENS_START", "8192"))
GEMINI_MAX_OUTPUT_TOKENS_CEIL = int(os.environ.get("GEMINI_MAX_OUTPUT_TOKENS_CEIL", "65536"))

# Pinned eval prompt (ITEM 20 requirement: "Pin the eval prompt in-repo"). Deliberately mirrors how a
# routine session is actually run: given the CURRENT governing prose verbatim (no memorized/cached
# knowledge of a prior revision) plus one self-contained scenario, decide mechanically and literally.
# {allowed_decisions} is filled per-scenario with ONLY the tokens valid for that scenario's category
# (CATEGORY_TOKENS) — e.g. a strategy-entry scenario offers just "GO | NO-GO", not all six. This stops a
# spurious "flip" where the model picks a correct-sentiment but wrong-vocabulary token (a strategy-entry
# scenario answered "DO-NOT-ACTIVATE" instead of "NO-GO"); an uncategorized scenario falls back to all six.
# {reference_context_block} (added 2026-08-17, see referenced_scenario_ids()/build_single_prompt() below)
# is "" when this scenario's situation references no sibling scenario, which reproduces this template's
# exact pre-2026-08-17 text byte-for-byte (the blank line between GOVERNING FILES and SCENARIO already
# existed) — see build_single_prompt()'s own docstring for what it contains when non-empty.
EVAL_PROMPT_TEMPLATE = """You are evaluating ONE pinned regression scenario against this trading \
system's CURRENT governing prose. Read the governing-file excerpts below exactly as given below — do \
not rely on any outside/remembered knowledge of a prior revision of these files. Apply the rules \
mechanically and literally, exactly as an autonomous routine session executing Claude_Task_Plan.md \
would, with no added judgment beyond what the cited rule requires.

=== GOVERNING FILES (verbatim, current repo state) ===
{governing_files_text}
{reference_context_block}
=== SCENARIO ===
{situation}

Respond with EXACTLY two lines and nothing else:
DECISION: <one of {allowed_decisions}>
RATIONALE: <one sentence citing the specific rule/section/threshold you applied>
"""

QUEUE_INSERT_TEMPLATE = """-- SPEC ONLY — never executed by this script (no BigQuery write credentials in CI) and not filed
-- verbatim by any routine either: D3's GOLDEN-SCENARIO PROSE-REGRESSION CHECK (Claude_Task_Plan.md) is
-- the actual filer, and since its 2026-08-27 "COLUMN-vs-PAYLOAD PLACEMENT CORRECTED" clause its real
-- INSERT uses a DIFFERENT, now-authoritative column set (adds `due_date`/`artifact_path`; `payload` is
-- built via PARSE_JSON(TO_JSON_STRING(STRUCT(...))), not a `JSON '<literal>'`) — CORRECTED (2026-08-31
-- code-quality pass): treat Claude_Task_Plan.md as the authority on the real write, not this template.
-- review_type='prose-regression' per ITEM 20.
-- {{scenario_id}}/{{note}}/{{payload_json}} below are ALREADY SQL-escaped by build_queue_insert_sql() —
-- do not .format() this template directly with raw values (see that function's docstring, 2026-08-17 fix).
INSERT INTO `stock-trading-498512.events.queue_events`
  (queue, item_key, item_type, status, note, payload)
VALUES (
  'PENDING_REVIEW',
  '{scenario_id}',
  'prose-regression',
  'pending',
  '{note}',
  JSON '{payload_json}'
);"""


def _sql_single_quote_escape(s):
    """Escape `s` for embedding inside a SQL single-quoted string literal, BigQuery's backslash form
    (\\' ), NOT the doubled '' form — this repo has a recorded convention (feedback_bigquery_file_
    conventions) that '' escaping FAILS in this project's BigQuery contexts. Backslashes are escaped
    FIRST (\\ -> \\\\) so an existing literal backslash in `s` — e.g. one already produced by
    json.dumps() to escape an embedded double-quote inside a JSON string value — round-trips intact
    once BigQuery un-escapes the SQL literal, instead of being misread as introducing a new escape."""
    return s.replace("\\", "\\\\").replace("'", "\\'")


def build_queue_insert_sql(scenario_id, expected, actual, governing_files):
    """Build the advisory (never-executed — see QUEUE_INSERT_TEMPLATE's own header / module docstring)
    events.queue_events INSERT text printed on a decision flip.

    FIXED 2026-08-17 (audit finding): the old version formatted `expected`/`actual`/`governing_files`
    straight into QUEUE_INSERT_TEMPLATE with Python's `!r` (repr), which is broken on the NORMAL case —
    scenarios.yaml's own schema documents expected_decision as "TOKEN (free-text qualifier)", e.g. KT-04's
    "CONTINUE (routes to review, not direct terminate)" — because repr() output is PYTHON syntax, not SQL
    or JSON: a value containing a literal `'` prematurely closes the surrounding SQL string, and a Python
    list's repr (used for `governing_files`) is not valid JSON at all (JSON requires double-quoted keys/
    strings). Concretely, the old code printed things like
        JSON '{"review_type": "prose-regression", ..., "expected": 'CONTINUE (routes to review, not
        direct terminate)', ...}'
    which is invalid on BOTH axes: the bare `'CONTINUE ...'` inside the JSON '...' literal is not
    JSON syntax, and if `expected`/`actual` had contained an actual apostrophe the SQL string itself would
    have been corrupted (early close). This function fixes both: the JSON payload is built with
    json.dumps() (always well-formed JSON), then the WHOLE resulting JSON text — and the separately-built
    `note` text — are each SQL-escaped exactly once (_sql_single_quote_escape) before being embedded in
    their own `'...'` SQL literals. Still print-only / never executed (unchanged, deliberate — see the
    module docstring's --live section and CLAUDE.md's "golden-scenarios.yml" non-issue note); this fix is
    about the printed text being genuinely valid SQL+JSON for whoever reads this annotation, not about
    wiring up an execution path here. CORRECTED (2026-08-31 code-quality pass): no routine actually files
    this template verbatim — D3's GOLDEN-SCENARIO PROSE-REGRESSION CHECK is the real filer and, per
    QUEUE_INSERT_TEMPLATE's own header above, uses a different (and now-authoritative) column/payload
    convention; this template's job is just to print a syntactically-valid illustration, not to match
    D3's live write."""
    payload_json = json.dumps({
        "review_type": "prose-regression",
        "scenario_id": scenario_id,
        "expected": expected,
        "actual": actual,
        "governing_files": governing_files,
    })
    note = f"golden-scenario decision flip: {scenario_id} expected {expected!r} got {actual!r}"
    return QUEUE_INSERT_TEMPLATE.format(
        scenario_id=_sql_single_quote_escape(scenario_id),
        note=_sql_single_quote_escape(note),
        payload_json=_sql_single_quote_escape(payload_json),
    )


def load_scenarios(path=SCENARIOS_PATH):
    with open(path, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict) or "scenarios" not in data:
        raise ValueError("scenarios.yaml must be a mapping with a top-level 'scenarios' list")
    scenarios = data["scenarios"]
    if not isinstance(scenarios, list) or not scenarios:
        raise ValueError("scenarios.yaml 'scenarios' must be a non-empty list")
    return scenarios


# Directory prefix identifying the golden-scenario harness's OWN files (scenarios.yaml, this runner,
# any future fixture placed alongside them). golden-scenarios.yml's push path filter triggers on this
# whole directory (tests/golden_scenarios/**) alongside the prose files it gates on — but unlike a prose
# file, a change HERE is never something a scenario's `governing_files` list points at (a scenario
# pointing at the fixture file that *defines* it would be self-referential and meaningless), so
# scenarios_for_changed_files()'s plain governing_files intersection is structurally blind to it. See
# that function's docstring for why this must fail OPEN (select every scenario), not silently select
# none, when a change lands here.
#
# MEASUREMENT TRAP (hit 2026-07-30, the day the scoping landed): because a push that edits THIS file
# fails open, the very push that introduces or changes the cost-scoping selects all 31 scenarios and
# bills full price — which reads as "the optimization does not work." It does; verified on the same
# push by re-running the selection with the harness files excluded: 71 changed files -> all 31 with
# them, 10 without. Measure this optimization on a push that does NOT touch tests/golden_scenarios/,
# and do NOT "fix" the fail-open to make the numbers look better — a runner/expectations change can
# alter any scenario's outcome, so narrowing it would trade a real correctness guarantee for cost.
HARNESS_SELF_PREFIX = "tests/golden_scenarios/"


def scenarios_for_changed_files(scenarios, changed_files):
    """Map `changed_files` (an iterable of repo-relative paths, e.g. from `git diff --name-only`) to the
    sorted list of ids of scenarios whose `governing_files` intersect them. This is the selection
    function behind golden-scenarios.yml's live-run cost-scoping (2026-07-30): the workflow's push path
    filter is directory/file-level (Strategy.md, Operating_Protocols.md, Claude_Task_Plan.md,
    tests/golden_scenarios/**), so every triggering push used to re-evaluate ALL scenarios via --live
    regardless of which ONE governing file actually changed — this narrows that to just the scenarios
    that file governs.

    FAIL-OPEN — returns every scenario id (never a false narrow subset) in two situations:
      * `changed_files` is falsy (None or an empty list/iterable) — the caller could not determine, or
        did not attempt to determine, what changed (e.g. a shallow clone, a zero-SHA push-before on ref
        creation, a force-push, or a first push to a new branch — see scripts/resolve_diff_base.sh). This
        matches every other path-gated check in this repo (dbt-parity, sql-validate): "can't scope it" ->
        run the full (expensive) check, never a false skip.
      * ANY changed file lives under HARNESS_SELF_PREFIX — see that constant's docstring. A change to
        scenarios.yaml's own pinned expectations, or to this runner's grading logic, can affect any/every
        scenario and is not visible to the governing_files intersection by construction, so it must not
        be treated as "matches nothing."

    Otherwise, returns only the ids of scenarios whose governing_files intersect changed_files — which is
    legitimately an EMPTY list when none of the changed files are governed by any scenario. That empty
    result is the entire cost saving: the caller skips the live (billed) run altogether in that case.

    Pure and side-effect-free (no network, no file I/O beyond what `scenarios` already embeds) so it is
    plain-unit-testable without a real git repo or a live model.

    DELIBERATELY STAYS FILE-LEVEL, not section-level (2026-08-17 SECTION SCOPING addendum): this function
    intersects `changed_files` against a scenario's `governing_files` list ONLY — it does NOT consult
    governing_sections to ask "did the change actually land inside the anchored heading(s)?" A change
    anywhere in a governing file still re-runs every scenario that file governs, even one whose
    governing_sections only reads a small slice of it. This is the mirror image of section scoping's own
    asymmetry: OVER-TRIGGER (re-run on any change to the file, even outside the scoped section) but
    UNDER-SEND (only the scoped section's text actually reaches the model once triggered). Narrowing this
    function to sections would risk the opposite failure mode from an unrelated diff slipping through
    unnoticed: a change to some OTHER heading in the same file could still be a genuine prose regression for
    a scenario currently scoped to a different heading (e.g. a renumbered/renamed anchor upstream, a
    cross-reference between sections, a changed shared definition), and staying blind to that would convert
    an advisory-but-real signal into a false negative. Re-evaluating a scenario whose actual excerpt didn't
    change is comparatively cheap (one skipped/negative live call); silently NOT re-evaluating a scenario
    whose excerpt DID change is the failure this cost-scoping function exists to never produce (see the
    fail-open rules above) — so this stays over-triggering, under-sending is section scoping's job alone."""
    if not changed_files:
        return sorted(sc.get("id") for sc in scenarios if isinstance(sc, dict) and sc.get("id"))
    changed = set(changed_files)
    if any(isinstance(f, str) and f.startswith(HARNESS_SELF_PREFIX) for f in changed):
        return sorted(sc.get("id") for sc in scenarios if isinstance(sc, dict) and sc.get("id"))
    ids = {
        sc.get("id")
        for sc in scenarios
        if isinstance(sc, dict) and sc.get("id")
        and changed.intersection(sc.get("governing_files") or [])
    }
    return sorted(ids)


def validate_offline(scenarios):
    """Pure schema + file-existence validation. No network, no model call. Returns a list of error
    strings (empty list = pass). This is the function the CI hard gate depends on.

    Also validates each scenario's OPTIONAL governing_sections mapping (2026-08-17 SECTION SCOPING — see
    the comment above _read_governing_text() below for the full "why"): every file key must be one of this
    scenario's own governing_files, every anchor must match EXACTLY ONE heading line in that file (zero or
    2+ matches is an error), and an empty anchor list is rejected explicitly. This is a load-bearing part of
    the hard gate, not a cosmetic addition — a mis-declared anchor would otherwise silently starve the live
    judge of the one rule it needed, with the offline gate staying green throughout. As a side effect (not
    an error, not reflected in the returned list), a clean governing_sections entry also PRINTS a one-line
    excerpt-size-vs-full-file-size report to stdout, so a suspiciously tiny excerpt is visible in CI output
    without anyone having to go look for it — see that print's own comment further down, and
    MIN_EXCERPT_BYTES for why "tiny" is measured in absolute bytes rather than as a share of the governing
    file. A scenario with no governing_sections key at all triggers none of this (no new errors, no new
    prints), so this function's behavior on such a scenario is exactly what it was before the feature
    existed. (The original wording here said "no scenario uses the feature yet" — stale as of 2026-08-18:
    scenarios.yaml now declares governing_sections widely, and the per-scenario report is routine output.)"""
    errors = []
    seen_ids = set()
    for i, sc in enumerate(scenarios):
        label = sc.get("id", f"<index {i}>") if isinstance(sc, dict) else f"<index {i}>"
        if not isinstance(sc, dict):
            errors.append(f"{label}: scenario entry is not a mapping")
            continue

        for field in REQUIRED_FIELDS:
            val = sc.get(field)
            if val is None or (isinstance(val, str) and not val.strip()):
                errors.append(f"{label}: missing or empty required field '{field}'")
            # codebase audit 2026-07-26: a non-string value (list/dict/int/bool) satisfies NEITHER branch
            # above — it is not None and `isinstance(val, str)` is False — so it silently passed this
            # loop forever. A YAML mis-indent (e.g. `expected_decision:\n  - GO`, which parses as a
            # one-element list, not the string "GO") is exactly this. Left unguarded, it sailed through
            # validate_offline() with zero errors and only blew up later, in --live, where _leading_token()
            # calls .strip() on it unguarded (outside run_live's try/except) and kills the ENTIRE live job
            # for all 23+ scenarios, not just the malformed one. Reject it here, by name and actual type,
            # so the hard gate catches it instead. `governing_files` is EXCLUDED here — it is the one
            # REQUIRED_FIELDS member that is legitimately a list, not a string, and already gets its own
            # dedicated type/contents validation a few lines below; running this check on it too would
            # make a well-formed governing_files list fail validation.
            elif field != "governing_files" and not isinstance(val, str):
                errors.append(
                    f"{label}: required field '{field}' must be a string, got {type(val).__name__} ({val!r})"
                )

        sid = sc.get("id")
        if sid:
            if sid in seen_ids:
                errors.append(f"{label}: duplicate scenario id '{sid}'")
            seen_ids.add(sid)

        gov = sc.get("governing_files")
        if isinstance(gov, list):
            if not gov:
                errors.append(f"{label}: governing_files must be a non-empty list")
            for gf in gov:
                if not isinstance(gf, str):
                    errors.append(f"{label}: governing_files entry {gf!r} is not a string")
                    continue
                full = os.path.join(ROOT, gf)
                if not os.path.isfile(full):
                    errors.append(f"{label}: governing_file '{gf}' does not exist at {full}")
        elif gov is not None:
            errors.append(f"{label}: governing_files must be a list, got {type(gov).__name__}")

        # governing_sections (2026-08-17 SECTION SCOPING — see the comment above _read_governing_text() for
        # the full "why" narrative, CI run 32069773377): OPTIONAL per-scenario map of governing_files entry
        # -> [heading anchor, ...]. This IS the load-bearing validation the task spec calls for — a
        # mis-declared anchor must fail the BUILD, not silently starve the judge of the rule it actually
        # needed while the offline gate stays green. A scenario with no governing_sections key at all skips
        # this block entirely (gov_sections is None) and is completely unaffected, which is what keeps
        # today's real scenarios.yaml (no scenario uses this feature yet) passing with zero new errors and
        # zero new report lines.
        gov_sections = sc.get("governing_sections")
        if gov_sections is not None:
            if not isinstance(gov_sections, dict):
                errors.append(
                    f"{label}: governing_sections must be a mapping of governing_files entry -> "
                    f"[heading anchor, ...], got {type(gov_sections).__name__}"
                )
            else:
                gov_file_set = set(gov) if isinstance(gov, list) else set()
                for gf, anchors in gov_sections.items():
                    # Every governing_sections key MUST also be one of this scenario's own governing_files —
                    # a section-scoping entry for a file the scenario doesn't even read is meaningless and
                    # almost certainly a stale/typo'd key left over from an edit.
                    if gf not in gov_file_set:
                        errors.append(
                            f"{label}: governing_sections key '{gf}' is not in this scenario's "
                            f"governing_files ({gov!r}) — a scoping entry for a file the scenario doesn't "
                            f"read is meaningless, likely a stale/typo'd key"
                        )
                        continue
                    # An empty anchor list is REJECTED outright rather than silently falling back to "send
                    # the whole file" (spec requirement: "say so explicitly rather than silently sending the
                    # whole file") — the author's intent is ambiguous (did they mean to scope this file and
                    # forget the anchors, or not scope it at all?), and staying silent here would be exactly
                    # the kind of mis-declaration this validation exists to catch.
                    if not isinstance(anchors, list) or not anchors:
                        errors.append(
                            f"{label}: governing_sections['{gf}'] must be a non-empty list of heading "
                            f"anchors — an empty/missing list is rejected explicitly rather than silently "
                            f"sending the whole file; omit the '{gf}' key entirely to send it whole"
                        )
                        continue
                    full_path = os.path.join(ROOT, gf)
                    if not os.path.isfile(full_path):
                        continue  # already reported as a missing governing_file by the gov-files loop above
                    try:
                        with open(full_path, encoding="utf-8") as fh:
                            file_text = fh.read()
                    # BUG FIX (2026-08-31 code-quality pass): UnicodeDecodeError is a ValueError
                    # subclass, not an OSError, so a governing file with invalid UTF-8 bytes (e.g. a
                    # stray non-UTF-8 paste into Strategy.md/Operating_Protocols.md/Claude_Task_Plan.md/
                    # Experiment_Parameters.md) used to escape this handler and crash validate_offline()
                    # with a raw traceback instead of the clean, listed schema error below — exactly the
                    # failure mode main()'s own `except (OSError, ValueError, yaml.YAMLError)` around
                    # load_scenarios() already guards against for the same kind of read.
                    except (OSError, UnicodeDecodeError) as exc:
                        errors.append(
                            f"{label}: could not read '{gf}' to validate governing_sections anchors: {exc}"
                        )
                        continue
                    headings = _document_headings(file_text)
                    anchors_ok = True
                    checked_keys = set()
                    for a in anchors:
                        if not isinstance(a, str) or not a.strip():
                            errors.append(
                                f"{label}: governing_sections['{gf}'] has a non-string/empty anchor entry "
                                f"{a!r}"
                            )
                            anchors_ok = False
                            continue
                        key = a.rstrip()
                        if key in checked_keys:
                            continue  # de-duplicated anchor — already validated once, don't double-report
                        checked_keys.add(key)
                        n_matches = len(_anchor_heading_indices(headings, a))
                        if n_matches == 0:
                            errors.append(
                                f"{label}: governing_sections['{gf}'] anchor {a!r} does not match any "
                                f"heading line in {gf} — likely stale (the heading was renamed/removed) or "
                                f"a typo"
                            )
                            anchors_ok = False
                        elif n_matches > 1:
                            errors.append(
                                f"{label}: governing_sections['{gf}'] anchor {a!r} matches {n_matches} "
                                f"heading lines in {gf} — ambiguous (the slice it selects is undefined); "
                                f"anchors must match EXACTLY ONE heading"
                            )
                            anchors_ok = False
                    # Per-scenario excerpt-size-vs-full-file report (spec requirement: "so a suspiciously
                    # tiny excerpt is visible in CI output"). Only printed once every anchor for this file
                    # validated cleanly — a broken anchor set has no well-defined excerpt to report on, and
                    # its own error(s) above are already the actionable CI output for that case.
                    # The percentage is reported for context but does NOT decide the advisory — that is an
                    # absolute byte floor; see MIN_EXCERPT_BYTES / _excerpt_size_verdict() for why.
                    if anchors_ok:
                        excerpt_text, n_blocks, n_anchors = extract_sections(file_text, anchors)
                        full_bytes = len(file_text.encode("utf-8"))
                        excerpt_bytes = len(excerpt_text.encode("utf-8"))
                        pct = (100.0 * excerpt_bytes / full_bytes) if full_bytes else 0.0
                        print(
                            f"  [governing_sections] {label} / {gf}: excerpt {excerpt_bytes:,} bytes of "
                            f"{full_bytes:,} full-file bytes ({pct:.1f}%), {n_blocks} of {n_anchors} "
                            f"section(s) — {_excerpt_size_verdict(excerpt_bytes, full_bytes)}",
                            flush=True,
                        )

        decision = sc.get("expected_decision")
        if isinstance(decision, str) and decision.strip():
            lead = decision.strip().upper()
            # codebase audit 2026-07-26: token-boundary match, not bare startswith — see
            # _token_boundary_match's docstring for the 'CONTINUES'/'TERMINATED'/'ACTIVATED'/'GOOF' typo
            # class this closes.
            if not any(_token_boundary_match(lead, tok) for tok in DECISION_LEAD_TOKENS):
                errors.append(
                    f"{label}: expected_decision '{decision}' does not start with a recognized token "
                    f"{DECISION_LEAD_TOKENS} — likely a typo, or the vocabulary needs a deliberate addition"
                )

        # 2026-07-29 bug hunt: `category` itself was never checked against CATEGORY_TOKENS — only the
        # nested `if cat in CATEGORY_TOKENS:` mismatch check below existed, which just NO-OPS when `cat`
        # doesn't match anything at all. A typo'd/invented category (e.g. 'regieme_router') therefore
        # sailed through offline validation with zero errors, then silently lost its per-category token
        # scoping downstream: _allowed_decisions_for() falls back to ALL SIX DECISION_LEAD_TOKENS for an
        # unrecognized category (see its docstring), reopening the exact unscoped-vocabulary flip risk the
        # 2026-07-26 CATEGORY_TOKENS fix was added to close — just via a misspelled key instead of a
        # missing one. Checked independently of expected_decision's validity so a malformed decision can't
        # mask a bad category or vice versa.
        cat = sc.get("category")
        if cat is not None and cat not in CATEGORY_TOKENS:
            errors.append(
                f"{label}: category '{cat}' is not a recognized key in CATEGORY_TOKENS "
                f"(valid: {sorted(CATEGORY_TOKENS)}) — likely a typo"
            )
        elif isinstance(decision, str) and decision.strip() and cat in CATEGORY_TOKENS:
            tok = _leading_token(decision)
            if tok is not None and tok not in CATEGORY_TOKENS[cat]:
                errors.append(
                    f"{label}: expected_decision token '{tok}' is not valid for category '{cat}' "
                    f"(allowed: {sorted(CATEGORY_TOKENS[cat])}) — likely a mis-categorized/copy-paste fixture")
    return errors


def _token_boundary_match(lead, tok):
    """True when `lead` (already .strip().upper()'d) starts with `tok` AND that match ends at a real
    token boundary. Plain str.startswith() alone lets a PREFIX TYPO through: 'CONTINUES' startswith
    'CONTINUE', 'TERMINATED' startswith 'TERMINATE', 'ACTIVATED' startswith 'ACTIVATE', 'GOOF' startswith
    'GO' — none of those are the token, all are a fixture typo, and all four passed the offline gate with
    zero errors and were then graded in --live as if correctly spelled (codebase audit 2026-07-26).
    Shared by validate_offline()'s vocabulary check and _leading_token()'s grader so the gate and the
    grader can never disagree about what a token is.

    A boundary is "anything that does not CONTINUE THE WORD": end-of-string, or a next character that is
    neither alphanumeric nor `_`/`-`. Defined by exclusion rather than by an allow-list of separators
    (adversarial review, same audit): _leading_token() also grades a LIVE MODEL's free-text reply, where
    ordinary sentence punctuation is normal — an allow-list of {whitespace, '('} rejected "GO." and
    "GO," outright, turning a correct model answer into a false UNPARSEABLE in run_live(). Hyphen counts
    as a word-continuation on purpose: the vocabulary itself contains hyphenated tokens ('NO-GO',
    'DO-NOT-ACTIVATE'), so a trailing '-' means the real token may be a longer compound, not this one."""
    if not lead.startswith(tok):
        return False
    rest = lead[len(tok):]
    return rest == "" or not (rest[0].isalnum() or rest[0] in "_-")


def _allowed_decisions_for(scenario):
    """The '<one of ...>' token list to offer this scenario's DECISION line: ONLY the tokens valid for
    its `category` (CATEGORY_TOKENS), or all six (DECISION_LEAD_TOKENS order) when the scenario has no
    recognized category. Scoping the choice to the category prevents a correct-sentiment/wrong-vocabulary
    'flip' (e.g. a strategy-entry scenario answered 'DO-NOT-ACTIVATE' instead of 'NO-GO')."""
    toks = CATEGORY_TOKENS.get(scenario.get("category"))
    # Keep DECISION_LEAD_TOKENS' longest-first-safe display order for the category subset too.
    ordered = [t for t in DECISION_LEAD_TOKENS if t in toks] if toks else list(DECISION_LEAD_TOKENS)
    return " | ".join(ordered)


def _leading_token(decision_text):
    """Extract the leading DECISION_LEAD_TOKENS token from a free-text decision string, for grading."""
    if not decision_text:
        return None
    lead = decision_text.strip().upper()
    # Longest-first so 'DO-NOT-ACTIVATE' isn't misread as a partial 'NO-GO'/'ACTIVATE' match.
    # codebase audit 2026-07-26: token-boundary match (see _token_boundary_match), not bare startswith
    # — a bare startswith let 'CONTINUES'/'TERMINATED'/'ACTIVATED'/'GOOF' grade as the clean token, which
    # both this grader AND the offline gate must agree is wrong (they share this helper for that reason).
    for tok in sorted(DECISION_LEAD_TOKENS, key=len, reverse=True):
        if _token_boundary_match(lead, tok):
            return tok
    return None


def _is_daily_quota_429(body):
    """True when a 429 body names a per-DAY quota (persistent — advance the ladder) rather than a
    per-minute one (transient — wait and retry the same model). Google spells the metric out in the
    message/violations, e.g. 'GenerateRequestsPerDayPerProjectPerModel' or '...requests per day'."""
    low = (body or "").lower()
    return "perday" in low or "per day" in low


_RETRY_DELAY_RE = re.compile(r'"retryDelay"\s*:\s*"(\d+(?:\.\d+)?)s"')


def _retry_delay_s(body, default):
    """Pull RetryInfo.retryDelay (e.g. "retryDelay": "38s") out of a 429 body; fall back to `default`."""
    m = _RETRY_DELAY_RE.search(body or "")
    return float(m.group(1)) if m else default


def _has_retry_delay(body):
    """True when `body` carries a server-supplied RetryInfo.retryDelay that _retry_delay_s() would honor —
    same regex (_RETRY_DELAY_RE), split out only so the RPM-retry telemetry counters (2026-08-17 retune,
    CI run 32060180247, item 4: "how many of the RPM sleeps used a server-supplied retryDelay versus the
    default") can classify a sleep without re-deriving _retry_delay_s()'s own server-vs-fallback
    distinction from its numeric return value. Deliberately NOT `delay == default` at the call site: a
    server-supplied retryDelay could legitimately equal GEMINI_RPM_RETRY_DELAY_S's own numeric value by
    coincidence, which a bare value comparison would misclassify as "used the default" when it was
    actually server-supplied."""
    return _RETRY_DELAY_RE.search(body or "") is not None


class _GeminiRunBudgetExhausted(RuntimeError):
    """Raised (by _check_run_budget, via _gemini_call) once GEMINI_RUN_BUDGET_S has been spent for this
    run, or would be spent by a sleep about to start. Caught by run_live() as a whole-RUN STOP signal
    (owner directive 2026-08-17: "i can wait ... if it fails, it can wait and auto retry and eventually
    complete" — but a 6-hour-default CI job cannot wait forever): report every not-yet-evaluated scenario
    as SKIPPED with this reason and stop attempting further calls, rather than letting each one
    independently re-discover the same exhausted budget."""


class _GeminiLadderPermanentlyDead(RuntimeError):
    """Raised when every ladder model is in state['dead'] — a genuine, waiting-cannot-fix exhaustion
    (every rung failed for a HARD reason: auth/not-found/bad-request, a per-DAY quota, a transport error,
    or persistent empty/truncated output — see _gemini_call's docstring). Caught by run_live() as the
    other whole-run STOP signal: no later scenario in this run will ever succeed against this ladder
    either, so exit promptly (never spending a rewind on a lost cause) instead of letting every remaining
    scenario burn a redundant attempt rediscovering the same dead ladder."""


def _check_run_budget(state, extra_s=0.0):
    """Raise _GeminiRunBudgetExhausted if GEMINI_RUN_BUDGET_S has already been spent for this run, or
    would be spent by sleeping/calling `extra_s` more seconds — "never start a sleep that would overrun
    the budget" (owner directive 2026-08-17). A no-op when `state` has no 'run_start_ts' — e.g. a
    low-level _gemini_call unit test that hand-builds a minimal state dict without going through
    _select_live_caller — since the run-budget feature only applies once a real run is tracking elapsed
    wall-clock time."""
    start = state.get("run_start_ts")
    if start is None:
        return
    elapsed = time.monotonic() - start
    if elapsed + extra_s >= GEMINI_RUN_BUDGET_S:
        raise _GeminiRunBudgetExhausted(
            f"Gemini run wall-clock budget (GEMINI_RUN_BUDGET_S={GEMINI_RUN_BUDGET_S:.0f}s) exhausted "
            f"after {elapsed:.0f}s elapsed — stopping further live attempts this run."
        )


def _pace(state):
    """Sleep just long enough (never more) that this request starts at least GEMINI_MIN_CALL_INTERVAL_S
    after the ACTUAL previous request — measured via time.monotonic() on state['last_call_ts'], never a
    flat per-call sleep — so consecutive scenarios stay under Gemini's free-tier ~5 RPM ceiling instead of
    tripping it and needing a ladder rewind. A no-op on the very first request of a run (state has no
    'last_call_ts' yet). Checks the run budget (via _check_run_budget) before actually starting the sleep,
    per the "never start a sleep that would overrun the budget" rule. Accumulates the actual sleep duration
    into state['sleep_pacing_s'] (2026-08-17 observability — see the OBSERVABILITY comment above
    GEMINI_MODEL_LADDER) so a run's end-of-run summary can separate "time spent pacing under the RPM
    ceiling" from RPM-retry and rewind-cooldown sleep, which used to be indistinguishable from the outside."""
    now = time.monotonic()
    last = state.get("last_call_ts")
    if last is not None:
        remaining = GEMINI_MIN_CALL_INTERVAL_S - (now - last)
        if remaining > 0:
            _check_run_budget(state, extra_s=remaining)
            time.sleep(remaining)
            state["sleep_pacing_s"] = state.get("sleep_pacing_s", 0.0) + remaining
            now = time.monotonic()
    state["last_call_ts"] = now


def _gemini_call(prompt, api_key, ladder, state):
    """POST one prompt to Gemini via the stdlib (no SDK dependency) and return (reply_text, model_id).

    THREE nested fallbacks:
      * Per model — ADAPTIVE OUTPUT BUDGET. Thinking is ON and draws from maxOutputTokens, so a hard
        scenario can truncate (finishReason=MAX_TOKENS) before emitting the DECISION line. On that, the
        budget DOUBLES (GEMINI_MAX_OUTPUT_TOKENS_START → … → _CEIL) and the SAME model is retried, until
        it produces an answer or the ceiling is reached.
      * Across models — LADDER, split by WHY a model was abandoned (2026-08-17 fix — see the doctrine
        comment above GEMINI_LADDER_REWINDS for the pathology this closes). A HARD failure (auth/
        not-found/bad-request, a per-DAY 429, a transport error, or persistent empty/truncated output)
        adds the model to state['dead'] — PERMANENT for the rest of the run. An RPM-only exhaustion
        (retries spent, still 429/minute) is NEVER added to state['dead'] — it only drops out of THIS
        call's remaining attempts; the next scenario's call tries it again fresh.
      * Across whole passes — REWIND. If every still-live (not dead) rung in the ladder was abandoned for
        an RPM-only reason within this one call, sleep a cooldown (honouring the last RPM 429's own
        RetryInfo.retryDelay when present, else GEMINI_LADDER_REWIND_COOLDOWN_S) and retry the whole
        still-live ladder from the top, bounded by GEMINI_LADDER_REWINDS. Exhausting the rewind budget is
        a PER-SCENARIO failure only (a plain RuntimeError; state['dead'] is untouched) — it does not stop
        the run, and the next scenario's call gets a fresh attempt at every still-live model (owner
        directive 2026-08-17: no single scenario's outcome may prevent a later one from attempting its
        own call).

    Raises _GeminiLadderPermanentlyDead when every ladder model is in state['dead'] (waiting cannot help
    — exits immediately, without spending a rewind), or _GeminiRunBudgetExhausted when GEMINI_RUN_BUDGET_S
    has been spent (checked before every network call and before every sleep). Both are whole-RUN stop
    signals that run_live() catches specially to skip every remaining scenario rather than retrying each
    in vain; a plain RuntimeError (rewinds exhausted for just this one scenario) is an ordinary
    per-scenario failure that does NOT stop the run."""
    import json as _json
    import urllib.error
    import urllib.request

    def _post(model, max_tokens):
        _check_run_budget(state)   # never START a fresh network call once the run budget is already spent
        _pace(state)
        # 2026-08-17 observability: count/log ONLY past this point — a call that never gets here (budget
        # already spent, above) never touched the network and must not inflate "total attempts" with a
        # phantom one. This is also what makes state['total_attempts'] the correct "attempt number" for
        # the per-attempt debug line below: it always corresponds to an actual urlopen() about to happen.
        state["total_attempts"] = state.get("total_attempts", 0) + 1
        state["total_tokens_sent"] = state.get("total_tokens_sent", 0) + len(prompt) // 4
        body = _json.dumps({
            "contents": [{"parts": [{"text": prompt}]}],
            # No thinkingConfig → each model's default/dynamic thinking stays ON (accuracy).
            "generationConfig": {"temperature": 0, "maxOutputTokens": max_tokens},
        }).encode("utf-8")
        req = urllib.request.Request(
            GEMINI_ENDPOINT.format(model=model) + "?key=" + api_key,
            data=body, headers={"Content-Type": "application/json"}, method="POST",
        )
        with urllib.request.urlopen(req, timeout=180) as resp:
            status = getattr(resp, "status", 200)
            data = _json.load(resp)
        cand = (data.get("candidates") or [{}])[0]
        parts = cand.get("content", {}).get("parts", []) or []
        # Thinking is ON, so a model MAY return separate "thought" summary parts (part.thought == True);
        # keep only the real answer text so the DECISION line parser never sees reasoning text.
        text = "".join(p.get("text", "") for p in parts
                       if isinstance(p, dict) and not p.get("thought"))
        return text, cand.get("finishReason", ""), status

    def _log_attempt(model, prompt_tokens_est, status, elapsed_s, cls):
        """One ::debug:: line per network attempt (2026-08-17 observability — see the comment above
        GEMINI_MODEL_LADDER). `status` is the HTTP status code on success/HTTPError, or the literal string
        "ERR" for a transport-level failure (URLError/TimeoutError/ValueError) that never got a status
        line at all. Uses state['total_attempts'] (already incremented by _post — see its own comment on
        why counting happens there, not here) as the attempt number, so this line's number always matches
        the run-level "total attempts" figure in run_live()'s end-of-run summary."""
        print(
            f"::debug::golden live attempt #{state.get('total_attempts', 0)} model={model} "
            f"tokens~={prompt_tokens_est} status={status} elapsed={elapsed_s:.1f}s class={cls}",
            file=sys.stderr, flush=True,
        )

    def _try_model(model):
        """Try ONE model, escalating maxOutputTokens on MAX_TOKENS truncation up to the ceiling. Returns
        (text, transient):
          * (text, False) on success.
          * (None, True) if abandoned ONLY because RPM retries were spent — transient; the caller must
            NOT add this model to state['dead'].
          * (None, False) if abandoned for any HARD reason — permanent; the caller adds it to
            state['dead'].

        The starting budget is the run-level HIGH-WATER MARK (state['budget']), not always _START: once
        any scenario in this run had to escalate, every later scenario/model starts at that discovered
        budget instead of re-truncating its way back up from _START each time (the scenarios share the
        same prompt shape, so if one needs a bigger budget they all do — this spends the per-model daily
        request quota once per run, not once per scenario). It never ratchets DOWN within a run; a bigger
        cap costs nothing per request (the model still emits only the short answer), and every ladder
        model accepts up to the ceiling, so carrying the mark across models is safe. state is fresh per
        run (created in _select_live_caller), so a new CI run re-starts at _START."""
        nonlocal last_rpm_body
        budget = state["budget"]
        rpm_retries = 0
        prompt_tokens_est = len(prompt) // 4
        while True:
            attempt_t0 = time.monotonic()
            try:
                text, finish, status = _post(model, budget)
            except urllib.error.HTTPError as exc:
                elapsed = time.monotonic() - attempt_t0
                body = exc.read().decode("utf-8", "replace")
                # A per-MINUTE 429 is transient: sleep out the API's suggested retryDelay and retry the
                # SAME model. Only a per-DAY 429 (or any other HTTP error) is a hard/permanent failure.
                if exc.code == 429 and not _is_daily_quota_429(body):
                    cls = "rpm-429"
                    state["total_429_rpm"] = state.get("total_429_rpm", 0) + 1
                    _log_attempt(model, prompt_tokens_est, exc.code, elapsed, cls)
                    last_rpm_body = body   # remembered for the rewind cooldown's own RetryInfo, below
                    if rpm_retries < GEMINI_RPM_MAX_RETRIES:
                        rpm_retries += 1
                        delay = _retry_delay_s(body, GEMINI_RPM_RETRY_DELAY_S)
                        # 2026-08-17 telemetry (retune item 4, CI run 32060180247): classify this sleep as
                        # server-supplied vs. flat-default so the run summary shows whether the ladder is
                        # mostly waiting out real API guidance or a guessed constant — see
                        # _has_retry_delay()'s docstring for why this can't be inferred from `delay` alone.
                        _delay_key = "sleep_rpm_retry_server_n" if _has_retry_delay(body) else \
                            "sleep_rpm_retry_default_n"
                        state[_delay_key] = state.get(_delay_key, 0) + 1
                        _check_run_budget(state, extra_s=delay)
                        time.sleep(delay)
                        state["sleep_rpm_retry_s"] = state.get("sleep_rpm_retry_s", 0.0) + delay
                        continue
                    errors.append(f"{model}: rate-limited (429/min) after {rpm_retries} retries")
                    return None, True
                # 429/day = daily quota gone; 404 = model not served to this key; 400 = e.g. budget above
                # this model's max; 5xx = transient-but-unretried. All => hard/permanent, dead the model.
                cls = "daily-quota-429" if exc.code == 429 else "hard-failure"
                if exc.code == 429:
                    state["total_429_daily"] = state.get("total_429_daily", 0) + 1
                _log_attempt(model, prompt_tokens_est, exc.code, elapsed, cls)
                errors.append(f"{model}: HTTP {exc.code} {body[:200]}")
                return None, False
            except (urllib.error.URLError, TimeoutError, ValueError) as exc:
                elapsed = time.monotonic() - attempt_t0
                _log_attempt(model, prompt_tokens_est, "ERR", elapsed, "hard-failure")
                errors.append(f"{model}: {exc}")
                return None, False
            elapsed = time.monotonic() - attempt_t0
            _log_attempt(model, prompt_tokens_est, status, elapsed, "ok")
            if text.strip():
                return text, False
            # Empty answer. If it was a MAX_TOKENS truncation and we have headroom, DOUBLE the budget and
            # retry the SAME model — the reasoning ran past the budget before reaching the DECISION line.
            if finish == "MAX_TOKENS" and budget < GEMINI_MAX_OUTPUT_TOKENS_CEIL:
                budget = min(budget * 2, GEMINI_MAX_OUTPUT_TOKENS_CEIL)
                state["budget"] = budget   # high-water mark: later scenarios/models start here, not _START
                continue
            # Empty for another reason (safety block, unexpected finishReason) or still truncating at the
            # ceiling — hard/permanent, give up on this model for the rest of the run.
            errors.append(f"{model}: empty response (finishReason={finish or '?'}, maxOutputTokens={budget})")
            return None, False

    state.setdefault("budget", GEMINI_MAX_OUTPUT_TOKENS_START)  # run-level output-budget high-water mark
    state.setdefault("dead", set())  # model ids abandoned for a HARD reason — sticky for the whole run
    # Accumulate EVERY model's failure THIS CALL (not just the last), so a total-exhaustion error names
    # what each live model actually returned — the difference between "all 404 (bad model ids/key)", "all
    # 429 (quota)", and "mixed" is the whole diagnosis.
    errors = []
    last_rpm_body = None  # most recent per-minute 429 body seen this call, for the rewind cooldown below

    if set(ladder) <= state["dead"]:
        # An earlier scenario in this run already walked the whole ladder to permanent death (bad key,
        # every model auth/quota/not-found). Waiting cannot fix this — exit immediately, no rewind spent.
        raise _GeminiLadderPermanentlyDead(
            "Gemini model ladder already exhausted earlier this run (see the first scenario's error)"
        )
    _check_run_budget(state)

    rewinds_used = 0
    while True:
        for model in ladder:
            if model in state["dead"]:
                continue
            text, transient = _try_model(model)
            if text is not None:
                return text, model
            if not transient:
                state["dead"].add(model)
            # 2026-08-17 telemetry (retune item 4, CI run 32060180247): count every time the loop moves off
            # a rung without succeeding on it — i.e. GEMINI_RPM_MAX_RETRIES was cut from 5 to 2 specifically
            # to make this happen SOONER/more often instead of re-sleeping on the same rung (see the
            # comment above GEMINI_RPM_MAX_RETRIES for the full rationale). This is how a later run's
            # summary shows whether that retune is actually landing, independent of the 429/sleep counts.
            state["ladder_switches"] = state.get("ladder_switches", 0) + 1

        if set(ladder) <= state["dead"]:
            # Every rung is now permanently dead — genuinely exhausted, not merely rate-limited.
            raise _GeminiLadderPermanentlyDead("Gemini model ladder exhausted — " + " | ".join(errors))

        # Every still-live rung failed for an RPM-only (transient) reason this pass — none was added to
        # state['dead']. Rewind the whole still-live ladder from the top after a cooldown, bounded by
        # GEMINI_LADDER_REWINDS. A rewinds-exhausted raise below is a per-SCENARIO bound only: it does NOT
        # touch state['dead'] and does NOT stop the run.
        if rewinds_used >= GEMINI_LADDER_REWINDS:
            raise RuntimeError(
                f"Gemini model ladder exhausted for this scenario — every still-live rung stayed "
                f"RPM-exhausted through {GEMINI_LADDER_REWINDS} rewind(s); will retry fresh next scenario "
                "— " + " | ".join(errors)
            )
        rewinds_used += 1
        cooldown = (
            _retry_delay_s(last_rpm_body, GEMINI_LADDER_REWIND_COOLDOWN_S)
            if last_rpm_body else GEMINI_LADDER_REWIND_COOLDOWN_S
        )
        _check_run_budget(state, extra_s=cooldown)
        time.sleep(cooldown)
        state["sleep_rewind_s"] = state.get("sleep_rewind_s", 0.0) + cooldown   # 2026-08-17 observability


def _select_live_caller():
    """Return a call_model(prompt) -> (reply_text, model_id) callable for the Gemini free-tier provider,
    or None (after printing a ::notice::) when GEMINI_API_KEY is not set. Gemini is the sole provider
    (owner directive 2026-07-17 — no Anthropic fallback)."""
    gemini_key = os.environ.get("GEMINI_API_KEY")
    if gemini_key:
        ladder = GEMINI_MODEL_LADDER
        # Shared across all scenarios in this run:
        #   dead         = model ids PERMANENTLY abandoned for a HARD reason (sticky). 2026-08-17 fix —
        #                  replaces the old single sticky `idx` cursor, which incorrectly treated an
        #                  RPM-only exhaustion as equally permanent (see the doctrine comment above
        #                  GEMINI_LADDER_REWINDS).
        #   budget       = adaptive maxOutputTokens high-water mark (sticky, never resets down within a run).
        #   run_start_ts = wall-clock anchor (time.monotonic()) for the GEMINI_RUN_BUDGET_S hard ceiling.
        #   last_call_ts = wall-clock of the previous actual request, for GEMINI_MIN_CALL_INTERVAL_S pacing
        #                  (absent until the first call; _pace() treats that as "no wait needed yet").
        # Fresh dict per run => fresh start: a new CI run/process re-starts at _START, empty dead set, and
        # a full run budget.
        state = {
            "dead": set(),
            "budget": GEMINI_MAX_OUTPUT_TOKENS_START,
            "run_start_ts": time.monotonic(),
        }
        print(f"::notice::golden live run — provider=Gemini (free tier); model ladder: {', '.join(ladder)}",
              file=sys.stderr, flush=True)

        def call_model(prompt):
            return _gemini_call(prompt, gemini_key, ladder, state)
        # Expose the shared run-state dict on the callable itself (2026-08-17 observability) so run_live()
        # can read the attempt/token/429/sleep counters _gemini_call accumulates in it, without widening
        # _select_live_caller()'s own return contract (still a plain callable-or-None — tests monkeypatch
        # this function directly with a fake caller that has no .state, so run_live() must getattr() this
        # with a default rather than assume it is always present).
        call_model.state = state
        return call_model

    print(
        "::notice::GEMINI_API_KEY not set — live golden-scenario run skipped (opt-in). Offline schema "
        "validation is unaffected.",
        file=sys.stderr, flush=True,
    )
    return None


# ---- BATCHING (2026-08-17) ----
# Measured problem (module docstring's --live section has the full narrative): CI run 32043614925 needed
# 24.1MB / ~6.02M tokens of governing-file text to evaluate 33 scenarios one-call-per-scenario, and got
# through only 11 of them in 2987s before the run budget stopped it. Most of that text was DUPLICATE: many
# scenarios share an IDENTICAL governing_files set (e.g. 16 of 33 are governed by Strategy.md alone) and
# each was re-sending that same multi-hundred-KB-to-megabyte text in its own call. group_scenarios_for_
# batching() groups scenarios by that shared set; run_live() sends the shared text ONCE per group via
# build_batch_prompt()/parse_batch_reply() instead of once per scenario — 33 scenarios collapse to ~7
# calls against the real scenarios.yaml. GOLDEN_BATCH=0 is the escape hatch back to today's exact
# one-call-per-scenario behavior (see run_live()'s own docstring for exactly how a group gets dispatched,
# including the deliberate size-1 bypass that does NOT go through this batch machinery at all).
GOLDEN_BATCH_MAX_DEFAULT = 8


def _governing_text_group_key(sc, text_cache):
    """The batching group key: a stable hash of `sc`'s ASSEMBLED GOVERNING TEXT — i.e. exactly what
    _read_governing_text(sc's governing_files, ..., sc's governing_sections) would produce — rather than the
    OLD frozenset(governing_files) key. This is the load-bearing change SECTION SCOPING requires of batching
    (task spec): two scenarios must land in the same group ONLY when they would receive byte-identical
    governing text, so a scenario that scopes Claude_Task_Plan.md down to '## OPS2.' must NOT be batched
    with one that scopes it down to '### PARK ROUTER' or sends it whole — merging them would mean ONE shared
    call answers for scenarios that were actually shown DIFFERENT text, silently poisoning whichever one's
    excerpt didn't match what was really sent.

    `governing_files` is sorted() before assembly (not used in `sc`'s own declared order) purely so this
    key's IDENTITY doesn't depend on two scenarios happening to list an identical file SET in a different
    YAML order — the OLD frozenset key never distinguished that ordering either, and the real prompt build
    (_run_one_scenario_live / _run_batch_group, elsewhere in this file) still uses each scenario's/group's
    own declared order, unaffected by this sort. A scenario with no governing_sections at all (or under the
    GOLDEN_SECTION_SCOPE=0 escape hatch) therefore hashes on exactly the same text the pre-2026-08-17
    frozenset key partitioned on — see test_group_key_order_independent_governing_files_list_still_merges
    and test_group_scenarios_for_batching_real_scenarios_yaml_still_seven_groups_no_op — which is
    what keeps today's 7-group result a true no-op when no scenario declares governing_sections.

    A missing/unreadable governing_file raises inside _read_governing_text() (that function's OWN documented
    contract: the read failure is the CALLER's problem, not its own) — caught here and degraded to a stable,
    deterministic fallback key so THIS function keeps its pre-existing "usable even pre-offline-gate, never
    raises" contract (test_group_scenarios_for_batching_missing_governing_file_costs_zero_not_raises): a real
    missing file is validate_offline()'s job to reject, not this ordering function's."""
    try:
        gov_files = sorted(sc.get("governing_files") or [])
        gov_sections = sc.get("governing_sections") if _section_scope_enabled() else None
        text = _read_governing_text(gov_files, text_cache, gov_sections)
        return hashlib.sha256(text.encode("utf-8")).hexdigest()
    except OSError:
        return "MISSING:" + repr(sorted(sc.get("governing_files") or []))


def group_scenarios_for_batching(scenarios, max_group=None):
    """Group `scenarios` (a list of scenario dicts, in scenarios.yaml order) by the identity of their
    ASSEMBLED GOVERNING TEXT (_governing_text_group_key() — 2026-08-17, changed from the plain
    frozenset(governing_files) set-identity to accommodate per-scenario section scoping, see that function's
    own docstring for why), for run_live()'s batching. Returns a list of groups (each a list of scenario
    dicts); a group of size 1 is legal (a scenario whose assembled text is unique in this run) and is exactly
    as valid an input to the caller as any other size.

    CONTRACT:
      * Order WITHIN a group matches scenarios.yaml's own relative order (never reshuffled) — two
        scenarios A before B in `scenarios` that land in the same group stay A-before-B in that group.
      * A group larger than `max_group` (default from the GOLDEN_BATCH_MAX env var, else
        GOLDEN_BATCH_MAX_DEFAULT=8) is split into consecutive chunks of at most `max_group`, preserving
        the same relative order across chunks (chunk N's scenarios are all before chunk N+1's, in
        scenarios.yaml order) — this bounds a single call's situation count (and therefore its reply
        length/parse surface) regardless of how large one governing text's real membership grows.
      * The returned GROUPS (not the scenarios within a group) are ordered by ASCENDING total on-disk byte
        size of their (deduplicated, since it's a set) governing_files — cheapest group first. This is
        deliberate, not incidental: GEMINI_RUN_BUDGET_S/the job timeout can stop a run mid-way (see
        _GeminiRunBudgetExhausted), and finishing the cheap, fast groups before the run risks running out
        of budget on an expensive one gets strictly more scenarios evaluated per second of budget spent
        than processing in scenarios.yaml's arbitrary declaration order would. Ties (including the
        genuinely-common case of two groups whose byte size is identical, or a governing_file that no
        longer exists on disk and contributes 0 either way) are broken by each group's/chunk's OWN first
        scenario's position in `scenarios` — deterministic, not hash-order-dependent.
        NOTE (2026-08-17, unchanged by the section-scoping key switch above): this cost estimate is still
        the FULL on-disk size of every governing_file in the group's first-seen scenario, not its (possibly
        much smaller) scoped excerpt size — deliberately left as-is so a run whose scenarios don't use
        governing_sections at all orders its groups byte-for-byte identically to before this feature landed
        (see the no-op tests). A truly excerpt-aware cost estimate is a real future improvement, not this
        task's job — see run_live()'s own governing-bytes telemetry (added alongside this) for the actual
        scoped-vs-unscoped bytes sent, which IS excerpt-aware, just not fed back into this ordering.

    A governing_file that no longer exists on disk (validate_offline()'s job to catch, not this function's)
    contributes 0 bytes to its group's cost rather than raising — this function must stay usable for
    ordering purposes even against a scenarios list that hasn't passed the offline schema gate yet."""
    if max_group is None:
        max_group = int(os.environ.get("GOLDEN_BATCH_MAX", str(GOLDEN_BATCH_MAX_DEFAULT)))

    text_cache = {}     # per-call file-read cache feeding _governing_text_group_key()'s hashing only
    buckets = {}        # text_hash -> [(original_index, scenario), ...]
    bucket_order = []   # first-seen key order (== scenarios.yaml order of first appearance)
    bucket_files = {}   # text_hash -> frozenset(governing_files) of the FIRST scenario seen with that hash,
                         # used only by _key_bytes() below (unchanged cost-ordering formula/behavior — see
                         # this function's own docstring NOTE on why that estimate stays full-file-based)
    for i, sc in enumerate(scenarios):
        key = _governing_text_group_key(sc, text_cache)
        if key not in buckets:
            buckets[key] = []
            bucket_order.append(key)
            bucket_files[key] = frozenset(sc.get("governing_files") or [])
        buckets[key].append((i, sc))

    # Split any oversized bucket into consecutive max_group-sized chunks, preserving order both within a
    # chunk and across a bucket's own chunks (range() walks the bucket's own already-order-preserved list
    # front-to-back).
    chunks = []  # (key, [scenario, ...], first_original_index) — one entry per returned group
    for key in bucket_order:
        entries = buckets[key]
        for start in range(0, len(entries), max_group):
            piece = entries[start:start + max_group]
            chunks.append((key, [sc for _, sc in piece], piece[0][0]))

    # Cheapest-group-first ordering. size_cache means a governing_files SET's byte size is computed once
    # even when that set was split into several chunks above (they all share the same key/cost).
    size_cache = {}

    def _key_bytes(key):
        if key not in size_cache:
            total = 0
            for gf in bucket_files[key]:
                try:
                    total += os.path.getsize(os.path.join(ROOT, gf))
                except OSError:
                    pass  # missing file: validate_offline()'s problem, not this ordering function's
            size_cache[key] = total
        return size_cache[key]

    chunks.sort(key=lambda c: (_key_bytes(c[0]), c[2]))
    return [chunk_scenarios for _, chunk_scenarios, _ in chunks]


# Batch eval prompt — same judging task, same decision vocabulary, same "read the prose fresh, apply it
# mechanically, no outside knowledge" instructions as EVAL_PROMPT_TEMPLATE above (that template is left
# untouched; the single-scenario/GOLDEN_BATCH=0/zero-parsed-fallback paths still use it directly), just
# restructured to grade N independent situations against ONE shared governing-files block. The "judge each
# situation INDEPENDENTLY" instruction below exists because a model reasoning through several situations
# in one continuous response could otherwise let an early answer anchor/bias a later one — something that
# structurally cannot happen when each situation gets its own isolated call.
# {reference_context_block} (added 2026-08-17, see referenced_scenario_ids()/build_batch_prompt() below)
# is "" when no situation in this group references a sibling scenario outside the group — reproducing
# this template's exact pre-2026-08-17 text byte-for-byte (the blank line between GOVERNING FILES and
# SITUATIONS already existed).
BATCH_EVAL_PROMPT_TEMPLATE = """You are evaluating {n} pinned regression scenarios against this trading \
system's CURRENT governing prose, in a single batched call ({n} situations that share an IDENTICAL \
governing_files set — the excerpt below is sent once for all of them, not once each; see the BATCHING \
comment above group_scenarios_for_batching() in this script for why). Read the governing-file excerpts \
below exactly as given — do not rely on any outside/remembered knowledge of a prior revision of these \
files. Apply the rules mechanically and literally, exactly as an autonomous routine session executing \
Claude_Task_Plan.md would, with no added judgment beyond what the cited rule requires.

=== GOVERNING FILES (verbatim, current repo state) ===
{governing_files_text}
{reference_context_block}
=== SITUATIONS ({n} total: {ids_list}) ===
Judge EACH situation below INDEPENDENTLY against the governing files above. Every situation is its own \
self-contained evaluation: do not let your answer to one situation influence, anchor, or bias your answer \
to any other situation below, even where two situations look similar or seem related to each other.

{situations_block}

For EACH situation above, reason it through against the governing files, citing the specific rule/section/\
threshold that decides it, then answer it using ITS OWN bracketed id exactly as given above, in the form:
RATIONALE[<id>]: <one sentence citing the specific rule/section/threshold you applied>
DECISION[<id>]: <one of that situation's own allowed decisions, listed with it above>

Your reply MUST end with exactly {n} lines — one DECISION[<id>]: line per situation id listed above, no \
fewer, no more, and no other lines mixed in among them — in exactly this form:
DECISION[<id>]: <decision>
"""


# ---- CROSS-SCENARIO REFERENCE RESOLUTION (2026-08-17) ----
# Measured defect: scenarios.yaml's `situation` prose sometimes refers to a SIBLING scenario by id instead
# of restating its facts (e.g. KT-02: "Same facts as KT-01 except the peak-to-trough drawdown is 46% rather
# than 52%.") and the harness never resolved that reference — the referenced scenario's situation text was
# simply never shown to the model judging the one that names it. Measured against the real 33-scenario
# file: 8 such cross-references exist (RR-02->RR-01, RR-03->RR-02, RR-04->RR-02, RR-04->RR-03,
# RR-06->RR-05, RR-08->RR-07, KT-02->KT-01, KT-06->KT-05). The batching work above (group_scenarios_for_
# batching()) accidentally resolves 7 of the 8 as a side effect: whenever both scenarios in a pair land in
# the same batch group, the referent's situation is already IN the prompt as one of the OTHER situations
# being judged. Exactly one pair never lands in the same group no matter how batching is tuned: KT-02's
# governing_files is {Experiment_Parameters.md} but KT-01's is {Experiment_Parameters.md,
# Claude_Task_Plan.md} — different sets, so group_scenarios_for_batching()'s frozenset-keyed grouping can
# never put them together. Fixed generally here (NOT by hand-patching KT-02's prose in scenarios.yaml,
# which would just paper over the harness gap for this one pair and leave the general defect unfixed for
# the next scenario that references a sibling with a different governing_files set) via
# referenced_scenario_ids() below, wired into BOTH prompt builders (build_batch_prompt / build_single_prompt).
_ID_SHAPE_RE = re.compile(r"^([A-Z]+)-(\d+)$")


def _infer_id_shape(known_ids):
    """Derive the (letters-quantifier, digits-quantifier) regex pieces for this scenario file's id SHAPE
    from the ACTUAL ids in `known_ids`, instead of hardcoding "two uppercase letters, hyphen, two digits"
    as a fixed literal that would silently stop matching every id the day a category needs a 3-letter or
    3-digit id. Every id in the real scenarios.yaml as of 2026-08-17 (RR-*/KT-*/SB-*/SA-*/SD-*/SE-*/PA-*/
    RS-*) happens to be exactly 2 letters + 2 digits, but that is a fact ABOUT the file's current contents,
    not something referenced_scenario_ids() should bake in as a constant. Falls back to that same 2/2
    shape only when `known_ids` contains no id matching the general LETTERS-HYPHEN-DIGITS shape at all
    (e.g. an empty known_ids, or a caller's non-conforming synthetic ids like "T-MATCH")."""
    letter_lens, digit_lens = set(), set()
    for sid in known_ids or ():
        m = _ID_SHAPE_RE.match(sid or "")
        if m:
            letter_lens.add(len(m.group(1)))
            digit_lens.add(len(m.group(2)))
    if not letter_lens or not digit_lens:
        return "{2}", "{2}"
    l_lo, l_hi = min(letter_lens), max(letter_lens)
    d_lo, d_hi = min(digit_lens), max(digit_lens)
    l_q = f"{{{l_lo}}}" if l_lo == l_hi else f"{{{l_lo},{l_hi}}}"
    d_q = f"{{{d_lo}}}" if d_lo == d_hi else f"{{{d_lo},{d_hi}}}"
    return l_q, d_q


def referenced_scenario_ids(scenario, known_ids):
    """Scan `scenario`'s own `situation` text for OTHER scenario ids it references by name (e.g. KT-02's
    "Same facts as KT-01 except..."), returning them as a list in FIRST-APPEARANCE order with no
    duplicates. Pure / side-effect-free — no file I/O, no network — so it is plain-unit-testable and cheap
    enough to call from both prompt builders below on every scenario, every run.

    `known_ids` scopes what counts as a real, resolvable reference (typically every id in the CURRENT
    scenarios.yaml, but a caller may pass a narrower set — e.g. a test fixture): a candidate substring is
    returned only when it (a) matches this file's id SHAPE (letters-hyphen-digits, INFERRED from
    `known_ids` itself via _infer_id_shape() — not hardcoded), (b) is a member of `known_ids`, and (c) is
    not `scenario`'s OWN id. Condition (b) is what stops a coincidental shape-alike substring (or a
    genuinely retired/renamed id) from being treated as a resolvable reference; condition (c) stops a
    scenario's own id appearing in its own prose (rare, but not meaningless-to-guard) from being
    "resolved" against itself.

    ONE LEVEL ONLY (2026-08-17, deliberate): this function is applied to a JUDGED scenario's own situation
    text — the callers below (_reference_context_ids_for) never re-apply it to a REFERENT's situation text,
    i.e. a chain (A references B, B references C) surfaces B's facts when judging A but NOT C's. Expanding
    transitively would make one judged scenario's prompt size depend on how deep a reference chain happens
    to run, undoing the point of the same-day batching work (a measured 77.3% token reduction) for exactly
    the scenarios that need a reference resolved at all. Bounding at one level keeps prompt growth
    proportional to the judged-scenario COUNT, not to reference-chain depth — see
    test_referenced_scenario_ids_resolution_is_one_level_only, and no scenario in the real file currently
    references a scenario that itself references a third, so this bound costs nothing today."""
    sid = scenario.get("id")
    text = scenario.get("situation") or ""
    known = set(known_ids or ())
    l_q, d_q = _infer_id_shape(known)
    pattern = re.compile(rf"\b[A-Z]{l_q}-\d{d_q}\b")
    seen = []
    for m in pattern.finditer(text):
        candidate = m.group(0)
        if candidate == sid or candidate not in known or candidate in seen:
            continue
        seen.append(candidate)
    return seen


# Shared by both prompt builders (build_batch_prompt / build_single_prompt) below. States, in terms a live
# model reliably follows, exactly the three things a REFERENCED-CONTEXT block must convey (spec, 2026-08-17):
# these facts exist ONLY to resolve an id another situation named, they are NOT to be answered, and no
# DECISION line may be emitted for an id that appears only here — plus the block's own visual separation
# ("===" header distinct from "=== SITUATIONS ==="/"=== SCENARIO ===", "---" per-id sub-delimiters) so a
# referenced id can never be mistaken for a judged one.
REFERENCE_CONTEXT_HEADER = (
    "=== REFERENCED CONTEXT (background facts only — do NOT judge, do NOT answer) ===\n"
    "One or more of the situation(s) above/below refers to another scenario BY ID (e.g. \"Same facts as "
    "KT-01 except...\"). The block(s) below are that OTHER scenario's own situation text, shown ONLY so "
    "the reference resolves to real facts instead of an id whose meaning you were never given. Each block "
    "below is NOT one of the situations you are being asked to judge in this call: do not reason about it "
    "as a fresh case to decide, and do NOT emit a DECISION line for it — no DECISION[<id>] (or bare "
    "DECISION:) line may name an id that appears ONLY in this REFERENCED CONTEXT section. Only the "
    "situation(s) shown under SITUATIONS / SCENARIO are being judged in this call."
)


def _reference_context_ids_for(scenarios_list, judged_ids, known_ids):
    """Deduped, first-appearance-ordered list of ids referenced (referenced_scenario_ids(), ONE LEVEL ONLY
    — see that function's docstring) by ANY scenario in `scenarios_list`, excluding any id already in
    `judged_ids`. A referent that is ITSELF one of the situations already being judged in this same call
    (e.g. KT-06 -> KT-05 when both are members of the same batch group) needs no separate context block —
    its situation is already present as one of the judged situations, and emitting a second copy would be
    a pure duplicate for zero benefit."""
    seen = []
    for sc in scenarios_list:
        for rid in referenced_scenario_ids(sc, known_ids):
            if rid in judged_ids or rid in seen:
                continue
            seen.append(rid)
    return seen


def _render_reference_context_block(ref_ids, id_to_scenario):
    """Render the REFERENCED-CONTEXT block for `ref_ids` (ids not already judged in this call — see
    _reference_context_ids_for), looking up each referent's situation text in `id_to_scenario` (id -> full
    scenario dict). Returns "" (renders as nothing — both EVAL_PROMPT_TEMPLATE and BATCH_EVAL_PROMPT_
    TEMPLATE already have their own blank-line spacing around {reference_context_block} for this case) when
    `ref_ids` is empty or none of them resolve to a known scenario dict.

    Deliberately includes ONLY the referent's `situation` text, never its governing_files: pulling in a
    referent's governing files would re-grow exactly the duplicate-text cost the 2026-08-17 batching work
    was built to eliminate (a referent's governing_files are frequently NOT already part of the judged
    group's own shared set — e.g. KT-01 additionally names Claude_Task_Plan.md, which KT-02's own group
    does not read at all)."""
    blocks = []
    for rid in ref_ids:
        ref_sc = id_to_scenario.get(rid)
        if ref_sc is None:
            continue
        blocks.append(
            f"--- REFERENCED CONTEXT [{rid}] (background only — NOT a situation to judge) ---\n"
            f"{(ref_sc.get('situation') or '').strip()}\n"
            f"--- END REFERENCED CONTEXT [{rid}] ---"
        )
    if not blocks:
        return ""
    return "\n" + "\n\n".join([REFERENCE_CONTEXT_HEADER, *blocks]) + "\n"


def build_batch_prompt(group, gov_text, id_to_scenario=None):
    """Build ONE prompt evaluating every scenario in `group` (a list of scenario dicts that all share the
    identical governing_files set — see group_scenarios_for_batching()) against `gov_text`, the ALREADY-
    ASSEMBLED verbatim governing-files text (the caller reads/caches the files, exactly as run_live() did
    per-scenario before batching — see _read_governing_text()); this function performs no file I/O of its
    own. Reuses _allowed_decisions_for() per scenario so each situation still only offers ITS OWN
    category's decision vocabulary — the same anti-vocabulary-flip scoping EVAL_PROMPT_TEMPLATE's
    single-scenario path already relies on (2026-07-26), just repeated once per situation instead of once
    per call.

    id_to_scenario (2026-08-17, optional; id -> full scenario dict, typically every id in scenarios.yaml —
    NOT just this group) resolves cross-scenario references (referenced_scenario_ids()): any sibling id a
    situation in `group` names that is NOT itself a member of `group` gets a REFERENCED-CONTEXT block (see
    _render_reference_context_block()) appended after the governing-files section. Omitting id_to_scenario
    (the default) disables resolution entirely — known_ids is then empty, so referenced_scenario_ids()
    finds nothing to resolve — which reproduces this function's exact pre-2026-08-17 output for any caller
    that doesn't have/need the full scenario set handy (e.g. this file's own pre-existing unit tests)."""
    ids = [sc.get("id") for sc in group]
    judged_ids = set(ids)
    known_ids = set(id_to_scenario) if id_to_scenario else set()
    ref_ids = _reference_context_ids_for(group, judged_ids, known_ids)
    reference_context_block = _render_reference_context_block(ref_ids, id_to_scenario or {})
    situations = []
    for sc in group:
        sid = sc.get("id")
        situations.append(
            f"--- SITUATION [{sid}] ---\n"
            f"{(sc.get('situation') or '').strip()}\n"
            f"Allowed decisions for [{sid}]: {_allowed_decisions_for(sc)}"
        )
    return BATCH_EVAL_PROMPT_TEMPLATE.format(
        n=len(group),
        governing_files_text=gov_text,
        reference_context_block=reference_context_block,
        ids_list=", ".join(f"[{i}]" for i in ids),
        situations_block="\n\n".join(situations),
    )


# Tolerant DECISION[<id>]: <decision> line matcher for parse_batch_reply(). Case-insensitive on the
# DECISION keyword; tolerates markdown emphasis/backticks wrapped around the marker (e.g.
# "**DECISION[KT-04]:**", "`DECISION[KT-04]:`") and stray whitespace around the id/colon, since a live
# model's exact markdown habits are not something this repo controls. The id itself is captured verbatim
# and compared CASE-SENSITIVELY against the caller's real ids in parse_batch_reply() — a model that
# mangled/invented the id must not fuzzy-match onto a real one.
_BATCH_DECISION_RE = re.compile(
    r"[*_`\s]*DECISION[*_`\s]*\[\s*(?P<id>[^\]]*?)\s*\][*_`\s]*:\s*(?P<decision>.*)",
    re.IGNORECASE,
)

# The single-scenario equivalent of _BATCH_DECISION_RE, for _extract_decision_line(): same markdown/
# whitespace tolerance around the marker, no per-scenario id (a single-scenario prompt asks for a bare
# "DECISION: <token>"). Used with .match() on an already-stripped line — ANCHORED, never .search() — so a
# mid-sentence "...the DECISION: ..." inside prose cannot hijack the line the way a batch-style scan would.
_SINGLE_DECISION_RE = re.compile(r"^[*_`\s]*DECISION[*_`\s]*:\s*(?P<decision>.*)", re.IGNORECASE)


def parse_batch_reply(reply, ids):
    """Parse a build_batch_prompt() reply into {id: decision_text_or_None}, with exactly one key for
    EVERY id in `ids` — never a partial dict. An id whose own "DECISION[<id>]:" line never appeared in the
    reply still gets an entry (value None) rather than being silently absent, so run_live() can score it
    as its own per-scenario parse failure without that poisoning its group-mates (spec requirement: a
    partial parse must not sink the whole group — see run_live()'s docstring).

    Tolerant of markdown wrapping/whitespace around the marker (_BATCH_DECISION_RE); the id itself must
    match one of `ids` EXACTLY (case-sensitive) once stripped. When the same id's DECISION line appears
    more than once in the reply, the LAST occurrence wins (simple last-write-wins, not an error) — a model
    that restates its answer, or an accidental duplicate block, should not make an otherwise-clean reply
    look ambiguous.

    NEVER RAISES: any unexpected input (a None/non-string reply, an empty `ids`, a regex surprise on
    adversarial text) degrades to the all-None dict, because a malformed batch reply must become a
    per-scenario/per-group parse failure that run_live() can act on, not an uncaught exception that would
    abort evaluation of every OTHER group in the run too."""
    result = dict.fromkeys(ids)
    try:
        if not reply:
            return result
        id_set = set(ids)
        for line in reply.splitlines():
            m = _BATCH_DECISION_RE.search(line)
            if not m:
                continue
            found_id = (m.group("id") or "").strip()
            if found_id not in id_set:
                continue
            decision = (m.group("decision") or "").strip().strip("*_` \t")
            result[found_id] = decision
    except Exception:  # noqa: BLE001 — malformed input degrades to all-None, never raises (see docstring)
        return dict.fromkeys(ids)
    return result


# ---- SECTION SCOPING (2026-08-17, follow-up to the same-day BATCHING work above) ----
# Measured problem (live CI run 32069773377): batching alone collapsed 33 scenarios to ~7 calls, but 23 of
# 33 scenarios still evaluated and the run hit 429s(rpm=83) out of 88 attempts — 94% REJECTED — at only
# 1.78 requests/min. The binding constraint is TOKENS-per-minute, not requests: the run measured 480,044
# tokens/min against a free-tier budget of roughly 250K/min, and the single largest prompt (the group
# carrying Claude_Task_Plan.md, governing 16+ scenarios) was 294,554 tokens on its OWN — 118% of an entire
# minute's budget, so that one request could never succeed however long the runner waited or however many
# times it retried (a retry re-sends the SAME full prompt, which is how 1.37M tokens of real content became
# 23.7M on the wire). Batching already fixed "the same text sent once per SCENARIO"; this fixes "the same
# FILE sent in full when a scenario only needs one rule out of it" — most governing files are large because
# they cover every routine/strategy/threshold in the system, but any ONE golden scenario is usually decided
# by a couple of headings, not the whole document.
#
# governing_sections (OPTIONAL, per-scenario field in scenarios.yaml — see the task spec's schema comment
# for the exact shape) maps a governing_files entry to a list of markdown heading-line anchors; only THOSE
# headings' sections are sent for that file, everything else in it is omitted. A governing_files entry with
# NO matching key in governing_sections is sent WHOLE, exactly as today — and a scenario with no
# governing_sections key AT ALL is completely unaffected: every code path below falls through to the plain
# whole-file block this function has always produced (see the "no-op" tests alongside this feature's other
# tests in test_golden_scenarios_runner.py, and _read_governing_text()'s own docstring below).
#
# validate_offline() (the HARD CI gate, extended alongside this) is what makes a mis-declared anchor fail
# the BUILD instead of silently starving the judge of the rule it actually needed — see that function's own
# governing_sections block for the full validation contract (unique-match requirement, empty-list rejection,
# file-key-must-be-in-governing_files, and the per-scenario excerpt-vs-full-file size report).
GOLDEN_SECTION_SCOPE = os.environ.get("GOLDEN_SECTION_SCOPE", "1")


def _section_scope_enabled():
    """GOLDEN_SECTION_SCOPE=0 is the escape hatch back to sending every governing_files entry WHOLE,
    ignoring any scenario's governing_sections entirely — needed for an A/B validation run comparing
    scoped-excerpt verdicts against full-file verdicts on the exact same scenario set. Read live (not
    cached at import time) so a test/CI step can flip it via monkeypatch/env without a process restart,
    matching this file's existing GOLDEN_BATCH=0 pattern (see run_live())."""
    return os.environ.get("GOLDEN_SECTION_SCOPE", GOLDEN_SECTION_SCOPE) != "0"


# ATX heading LINE: 1-6 '#' at the very start of the line, then required whitespace, then non-whitespace
# content. Deliberately NOT matched inside a fenced code block (tracked by _document_headings() below) —
# none of today's four governing files happen to contain a '#'-led line inside a ``` fence (verified
# 2026-08-17), but a routine/SQL/shell snippet added later easily could (e.g. a bash '# comment'), and a
# heading-shaped false positive there would silently corrupt an excerpt's slice boundaries with no error
# from validate_offline() (the anchor itself would still uniquely match — just the WRONG line).
_HEADING_LINE_RE = re.compile(r'^#{1,6}[ \t]+\S')
_FENCE_LINE_RE = re.compile(r'^\s*(`{3,}|~{3,})')

# Floor for the "SUSPICIOUSLY TINY" advisory on the per-scenario excerpt-size report (see
# validate_offline()'s governing_sections block). ABSOLUTE bytes, deliberately NOT a percentage of the
# governing file.
#
# WHY THE BASIS CHANGED (2026-08-18, SL5 diligence sweep). The advisory originally fired on
# `pct < 1.0` — the excerpt as a share of the WHOLE file. That basis is structurally wrong here: the
# denominator is a property of the governing DOCUMENT, not of the anchor, so a short-but-COMPLETE rule
# anchored inside a large reference file trips it no matter how correct the anchor is. Both of the
# repo's live instances were exactly that false positive, and each cost a routine session a full
# re-investigation before being cleared as a non-defect:
#   * RS-03 / Claude_Task_Plan.md — 4,916-byte excerpt of a 973,929-byte file (0.5%); the anchored
#     '## M2. E Pair Divergence Screen' section measures 4,866 bytes on disk, i.e. captured IN FULL
#     (verified SL5 2026-08-17).
#   * SB-04 / Operating_Protocols.md — 1,690-byte excerpt of a 231,960-byte file (0.7%); the anchored
#     '## 3. NO-GO Records Are Context, Not Barriers' section is a self-contained 15-line clause and is
#     likewise captured IN FULL, breadcrumb included (verified SL5 2026-08-18).
# The defect the advisory actually exists to catch is an anchor that resolves to (almost) NOTHING — a
# heading whose body is empty, or a stub/pointer paragraph standing in for the real rule. That failure
# is absolute-sized: such a capture is a heading line plus a breadcrumb, ~60-150 bytes. An absolute
# floor detects it directly and cannot be defeated or triggered by the size of the surrounding file.
#
# CALIBRATION: across today's 33 scenarios the smallest genuine excerpt is SB-04's 1,690 bytes, so 600
# sits ~2.8x below the real floor while staying ~4x above a heading-only capture. The percentage is
# still PRINTED (it is useful context for a reader eyeballing scope); it is simply no longer what
# decides the advisory.
MIN_EXCERPT_BYTES = int(os.environ.get("GOLDEN_MIN_EXCERPT_BYTES", "600"))


def _excerpt_size_verdict(excerpt_bytes, full_bytes):
    """Advisory verdict string for the per-scenario excerpt-size report. Returns 'ok', or the
    SUSPICIOUSLY TINY warning when the excerpt is small in ABSOLUTE terms (see MIN_EXCERPT_BYTES for
    why the basis is bytes rather than a share of the governing file).

    An empty governing file (full_bytes == 0) yields 'ok': there is no excerpt to be suspicious of, and
    a missing/unreadable file is already reported as a hard error by the governing_files loop."""
    if not full_bytes:
        return "ok"
    if excerpt_bytes < MIN_EXCERPT_BYTES:
        return (
            f"SUSPICIOUSLY TINY (< {MIN_EXCERPT_BYTES:,} bytes), double-check the anchors — an anchor "
            f"that resolves to little more than its own heading is starving the judge of the rule"
        )
    return "ok"


def _document_headings(text):
    """Every ATX markdown heading LINE in `text` (outside a fenced code block), in document order.
    Returns a list of dicts: {"line_no": int (0-based, into text.splitlines()), "level": int (1-6, the
    number of leading '#'), "raw": str (the full heading line, no trailing newline)}.

    Fence tracking is intentionally simple (toggle on ANY ``` or ~~~ fence-open/-close line, not fussy
    about matching the opening marker's exact character/length) — good enough to skip a '#'-led line
    inside a code sample without needing a full markdown parser for a heading-anchor feature."""
    headings = []
    in_fence = False
    for i, line in enumerate(text.splitlines()):
        if _FENCE_LINE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = _HEADING_LINE_RE.match(line)
        if m:
            headings.append({"line_no": i, "level": len(line) - len(line.lstrip("#")), "raw": line})
    return headings


def _anchor_heading_indices(headings, anchor):
    """Indices into `headings` (_document_headings()'s return shape) whose raw heading line matches
    `anchor` exactly, after an .rstrip() on both sides (so incidental trailing whitespace in the YAML
    anchor string or the file's own line doesn't cause a spurious non-match). Shared by validate_offline()'s
    zero-match/ambiguous-match checks and extract_sections()'s own anchor resolution so the two can never
    disagree about what "matches" means — exactly the same reason _token_boundary_match() is shared between
    the offline gate and the --live grader elsewhere in this file."""
    key = (anchor or "").rstrip()
    return [i for i, h in enumerate(headings) if h["raw"].rstrip() == key]


def _slice_heading(lines, headings, idx):
    """The [start, end) 0-based line range (into `lines`) for headings[idx]'s own section: from its own
    heading line through the line before the next heading in `headings` (document order — the very next
    entry, not a re-scan of the whole list) whose level is <= this heading's level ('##' ends at the next
    '##' or '#', but a deeper '###'/'####' in between stays INSIDE this slice as a nested subsection).
    `end` is len(lines) (EOF) when no such heading follows — the last matched section in a file runs to the
    end of the document, per spec."""
    h = headings[idx]
    end = len(lines)
    for later in headings[idx + 1:]:
        if later["level"] <= h["level"]:
            end = later["line_no"]
            break
    return h["line_no"], end


def _ancestor_breadcrumb(headings, idx):
    """The chain of enclosing SHALLOWER headings above headings[idx], outermost first, as their own raw
    heading lines (e.g. ["# Claude Task Plan", "## Routines"]) — so a model reading an isolated excerpt
    knows where in the document it sits, not just what the excerpt itself says. Walks BACKWARD from idx,
    taking the nearest heading whose level is strictly less than the running level (the immediate parent),
    then tightening the running level to THAT heading's level before continuing further back (the next hop
    up is the parent's own parent, not just any earlier shallow heading) — a standard breadcrumb-trail walk,
    stopping once a top-level (level 1) heading is collected or the start of the document is reached."""
    chain = []
    level = headings[idx]["level"]
    for h in reversed(headings[:idx]):
        if h["level"] < level:
            chain.append(h["raw"])
            level = h["level"]
            if level <= 1:
                break
    chain.reverse()
    return chain


def extract_sections(full_text, anchors):
    """Extract and assemble the scoped excerpt of `full_text` selected by `anchors` (a list of heading-line
    strings — see the governing_sections schema in the SECTION SCOPING comment above). Returns
    (excerpt_text, n_blocks, n_anchors):
      * excerpt_text — the assembled excerpt: matched sections in DOCUMENT order (regardless of the order
        `anchors` lists them in), each prefixed with its own ancestor breadcrumb (_ancestor_breadcrumb()),
        overlapping-or-adjacent slices MERGED into one contiguous block rather than emitted twice.
      * n_blocks     — the number of merged blocks actually emitted (< n_anchors when two+ anchors' own
        slices turned out to overlap or touch and were merged into one).
      * n_anchors    — the number of DISTINCT (de-duplicated) anchors in `anchors` that resolved to exactly
        one heading — the denominator render_scoped_block() below reports in its "K of N sections" label.

    CALLER CONTRACT: validate_offline() is the hard gate that guarantees every anchor reaching this function
    in a real CI run matches exactly one heading. This function stays DEFENSIVE anyway (an anchor matching
    zero or 2+ headings is silently skipped, never raises) so it stays safe to call from inside
    validate_offline() itself — to compute the size report — even while that same anchor's own zero/
    ambiguous-match error is still being assembled by the caller, and so a caller never sees an excerpt
    silently include text twice for an unresolved anchor."""
    headings = _document_headings(full_text)
    lines = full_text.splitlines()

    seen_keys = []
    idxs = []
    for a in anchors or []:
        if not isinstance(a, str):
            continue
        key = a.rstrip()
        if key in seen_keys:
            continue
        seen_keys.append(key)
        matches = _anchor_heading_indices(headings, a)
        if len(matches) == 1:
            idxs.append(matches[0])

    idxs = sorted(set(idxs))  # heading indices are already document-order; sort+dedup is belt-and-suspenders

    ranges = []
    for idx in idxs:
        s, e = _slice_heading(lines, headings, idx)
        ranges.append([s, e, idx])

    # Merge overlapping-or-ADJACENT ranges (s <= previous end, not s < previous end — a slice that starts
    # exactly where the previous one ends, i.e. the two are back-to-back with no gap, still counts as
    # "adjacent" per spec and must merge into one block, not two consecutive ones with a redundant seam).
    merged = []
    for s, e, idx in ranges:
        if merged and s <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], e)
        else:
            merged.append([s, e, idx])

    blocks = []
    for s, e, idx in merged:
        breadcrumb = _ancestor_breadcrumb(headings, idx)
        block_text = "\n".join(lines[s:e])
        if breadcrumb:
            blocks.append(f"[context: {' / '.join(breadcrumb)}]\n{block_text}")
        else:
            blocks.append(block_text)

    return "\n\n".join(blocks), len(merged), len(seen_keys)


def render_scoped_block(gf, full_text, anchors):
    """The '----- <path> (excerpt: ...) -----\\n<excerpt>' block _read_governing_text() emits for a
    governing_files entry that has a governing_sections mapping — the scoped-excerpt sibling of that
    function's own plain '----- <path> -----\\n<full text>' block for an unscoped file. Labels the block
    unambiguously as a PARTIAL view (spec requirement: "state plainly that it is a scoped excerpt of a
    larger file") and instructs the judge not to infer that an absent rule doesn't exist merely because this
    excerpt doesn't contain it — the model has no other way to know whether a decisive rule was cut, so it
    must be told to say so rather than guess."""
    excerpt_text, n_blocks, n_anchors = extract_sections(full_text, anchors)
    return (
        f"----- {gf} (excerpt: {n_blocks} of {n_anchors} section(s) — SCOPED, not the full file) -----\n"
        f"[This is a SCOPED EXCERPT of {gf}, not the file in full — sections outside the ones shown below "
        f"are omitted. If the rule you need to decide this scenario is not present in this excerpt, say so "
        f"explicitly instead of assuming an absent rule does not exist.]\n"
        f"{excerpt_text}"
    )


def _read_governing_text(governing_files, file_cache, governing_sections=None):
    """Assemble the verbatim '----- <path> -----\\n<text>' block for `governing_files` (a list of
    repo-relative paths), reading each file at most once per RUN via `file_cache` (a plain dict the caller
    owns and shares across every scenario/group run_live() processes in one run) rather than once per
    scenario. This cache still pays off even across DIFFERENT groups: a file like Claude_Task_Plan.md can
    appear in more than one group's governing_files set (e.g. paired with Operating_Protocols.md in one
    group and with Experiment_Parameters.md in another), so caching saves a re-READ even where batching
    itself can't save a re-SEND (each group still sends its own, different, combined text).

    `governing_sections` (2026-08-17, optional — a scenario's own governing_sections mapping, or None) scopes
    ANY file key present in it to render_scoped_block()'s excerpt instead of the whole file — see the
    SECTION SCOPING comment above. A file NOT named in `governing_sections` (including every file when
    `governing_sections` is None/empty, or when the GOLDEN_SECTION_SCOPE=0 escape hatch is set) is sent
    WHOLE via the exact same '----- {gf} -----\\n{text}' block this function produced before this feature
    existed — this is the entire no-op guarantee: a scenario that never opts into governing_sections drives
    this function down a code path byte-for-byte identical to its pre-2026-08-17 form."""
    scope_on = governing_sections and _section_scope_enabled()
    parts = []
    for gf in governing_files:
        if gf not in file_cache:
            with open(os.path.join(ROOT, gf), encoding="utf-8") as fh:
                file_cache[gf] = fh.read()
        full_text = file_cache[gf]
        anchors = governing_sections.get(gf) if scope_on else None
        if anchors:
            parts.append(render_scoped_block(gf, full_text, anchors))
        else:
            parts.append(f"----- {gf} -----\n{full_text}")
    return "\n\n".join(parts)


def _governing_bytes_scoped_vs_unscoped(governing_files, governing_sections, file_cache):
    """Return (scoped_bytes, unscoped_bytes): the UTF-8 byte length of the text _read_governing_text()
    actually assembles for `governing_files`/`governing_sections` (what gets SENT, honoring
    GOLDEN_SECTION_SCOPE) vs. the byte length of the SAME governing_files sent WHOLE (governing_sections
    ignored) — the run-summary "what did scoping save" comparison (task spec telemetry requirement). Uses
    the SAME `file_cache` as the real prompt build, so this costs no extra disk I/O beyond what the run was
    already doing — only the (cheap, in-memory) excerpt assembly runs twice."""
    scoped_text = _read_governing_text(governing_files, file_cache, governing_sections)
    unscoped_text = _read_governing_text(governing_files, file_cache, None)
    return len(scoped_text.encode("utf-8")), len(unscoped_text.encode("utf-8"))


def _extract_decision_line(reply):
    """Pull the free-text decision out of a single-scenario reply's 'DECISION: ...' line (first such line,
    matched case-insensitively, may appear after preamble text), falling back to the whole stripped reply
    when no ':'-delimited DECISION line is present at all (the model answered with just a bare token, e.g.
    'GO'). Pulled out of run_live()'s pre-batching inline logic so the single-scenario path and the batch
    path's per-id extraction (parse_batch_reply) sit side by side without duplicating this scan — and, like
    that path, tolerant of markdown wrapping around the marker and around the decision token itself
    (**DECISION:** GO / `DECISION:` GO / DECISION: **GO**), which a plain "startswith('DECISION:')" scan
    graded as a false UNPARSEABLE. Every non-markdown reply extracts byte-identically to that older scan."""
    for line in reply.splitlines():
        m = _SINGLE_DECISION_RE.match(line.strip())
        if m:
            return (m.group("decision") or "").strip().strip("*_` \t")
    return reply.strip()


def _score_decision(sc, actual_decision, reply_for_record, model_used):
    """Score an already-extracted `actual_decision` string against `sc`'s expected_decision, returning a
    result dict in run_live()'s standard shape ({id, expected, actual, match, reply, model}) and printing
    the flip/unparseable annotations exactly as before the 2026-08-17 batching refactor. `reply_for_record`
    is whatever should be stored in the result's 'reply' field for diagnosis — the single-scenario reply
    text, or the shared multi-scenario batch reply for a scenario that was scored as part of a group.
    Shared by BOTH the single-scenario path (which first extracts a DECISION: line via
    _extract_decision_line) and the batch path (which gets its per-id decision text straight from
    parse_batch_reply()) so match/UNPARSEABLE grading can never drift between the two call shapes — this
    is the exact grading logic run_live() used inline before batching, unchanged in behavior."""
    sid = sc.get("id")
    expected_tok = _leading_token(sc.get("expected_decision"))
    actual_tok = _leading_token(actual_decision)

    if actual_tok is None:
        # The model replied (no exception) but the answer didn't start with ANY recognized
        # DECISION_LEAD_TOKENS token -- it ignored the "<one of ...>" instruction and invented its own
        # word. That's a format-following failure, not a decision disagreement: there is no real
        # expected-vs-actual call to adjudicate, so it must not be blended into the FLIP bucket below
        # (which proposes a prose-regression review) or silently miscounted as one.
        match = "UNPARSEABLE"
    else:
        match = expected_tok is not None and expected_tok == actual_tok

    result = {"id": sid, "expected": sc.get("expected_decision"), "actual": actual_decision,
              "match": match, "reply": reply_for_record, "model": model_used}

    if match is False:
        print(
            f"::warning file=tests/golden_scenarios/scenarios.yaml::{sid} decision flip — "
            f"expected '{sc.get('expected_decision')}' got '{actual_decision}'. "
            f"Governing files: {sc.get('governing_files')}.",
            flush=True,
        )
        print(build_queue_insert_sql(sid, sc.get("expected_decision"), actual_decision,
                                      sc.get("governing_files")), flush=True)
    elif match == "UNPARSEABLE":
        print(
            f"::warning::{sid}: model reply had no recognized decision token — got '{actual_decision}'. "
            f"Not filed as a decision flip (no expected-vs-actual call to adjudicate); no "
            f"queue_events INSERT emitted.",
            flush=True,
        )
    return result


def build_single_prompt(scenario, gov_text, id_to_scenario=None):
    """Build the single-scenario EVAL_PROMPT_TEMPLATE prompt for ONE `scenario` — the GOLDEN_BATCH=0 /
    size-1-group / batch-zero-parsed-fallback path's prompt builder, factored out of _run_one_scenario_
    live() (2026-08-17, alongside referenced_scenario_ids()) so it is directly unit-testable exactly like
    build_batch_prompt() is, instead of only reachable through _run_one_scenario_live()'s file I/O + live
    call_model() side effects.

    Wires the SAME cross-scenario reference resolution as build_batch_prompt() (see that function's
    docstring and _render_reference_context_block()) into EVAL_PROMPT_TEMPLATE's {reference_context_block}
    placeholder: id_to_scenario (optional; id -> full scenario dict, typically every id in scenarios.yaml)
    is where a referenced sibling's situation text is looked up. Omitting it (the default) disables
    resolution entirely, reproducing this path's exact pre-2026-08-17 output."""
    sid = scenario.get("id")
    known_ids = set(id_to_scenario) if id_to_scenario else set()
    ref_ids = _reference_context_ids_for([scenario], {sid}, known_ids)
    reference_context_block = _render_reference_context_block(ref_ids, id_to_scenario or {})
    return EVAL_PROMPT_TEMPLATE.format(
        governing_files_text=gov_text,
        situation=(scenario.get("situation") or "").strip(),
        allowed_decisions=_allowed_decisions_for(scenario),
        reference_context_block=reference_context_block,
    )


def _run_one_scenario_live(sc, call_model, file_cache, id_to_scenario):
    """Evaluate exactly ONE scenario via the plain (non-batched) EVAL_PROMPT_TEMPLATE path (build_single_
    prompt(), which resolves any cross-scenario reference in `sc`'s own situation text against
    `id_to_scenario` — see that function and referenced_scenario_ids()) and return its result dict
    (run_live()'s standard shape). Raises whatever call_model() raises, OR an OSError from reading a
    governing_file — both left uncaught here BY DESIGN, exactly like _read_governing_text(): the
    governing_files read must stay inside the CALLER's try/except (2026-07-29 comment) so a read failure
    degrades only the scenario/group attempting it.

    This is run_live()'s pre-batching per-scenario code path, factored out unchanged (2026-08-17) so THREE
    different callers share it instead of three copies that could quietly drift apart:
      * GOLDEN_BATCH=0 (the escape hatch back to today's exact behavior),
      * a lone scenario's own size-1 group (see run_live()'s docstring for why size 1 bypasses batching
        entirely rather than going through build_batch_prompt/parse_batch_reply for a single situation),
      * a batch group's zero-parsed fallback (_run_batch_group, below).

    Threads `sc`'s own governing_sections (2026-08-17 SECTION SCOPING) into _read_governing_text() so this
    path gets the identical scoped/whole-file split as the batched path below — see that function's own
    docstring and the SECTION SCOPING comment above it."""
    gov_text = _read_governing_text(sc.get("governing_files") or [], file_cache, sc.get("governing_sections"))
    prompt = build_single_prompt(sc, gov_text, id_to_scenario)
    reply, model_used = call_model(prompt)
    return _score_decision(sc, _extract_decision_line(reply), reply, model_used)


def _run_batch_group(group, call_model, file_cache, results, gi, n_groups, id_to_scenario):
    """Attempt ONE call_model() call for `group` (2+ scenarios sharing a governing_files set) via
    build_batch_prompt()/parse_batch_reply(), APPENDING each scenario's result dict to `results` as it is
    produced rather than returning a list — so that if a whole-run terminal signal
    (_GeminiRunBudgetExhausted / _GeminiLadderPermanentlyDead) is raised PARTWAY through the zero-parse
    fallback below, group-mates already scored before that point keep their REAL result instead of being
    overwritten as SKIPPED by run_live()'s handler (which tells "already evaluated" from "not yet" by
    checking which ids are already present in `results`).

    Falls back to individual per-scenario calls (_run_one_scenario_live) for the WHOLE group ONLY when
    parse_batch_reply() extracts ZERO ids from the batch reply (the reply was entirely unusable for this
    group — wrong format, empty, the model ignored the per-id instruction entirely). A PARTIAL parse (some
    ids present, others missing) is instead handled per-id below — a missing id becomes THAT scenario's
    own match=None failure without affecting a group-mate whose id DID parse (spec requirement: "must NOT
    poison its group-mates"). Each fallback sub-call is itself wrapped so one scenario's ordinary failure
    there doesn't lose its already-fallback-evaluated group-mates either, mirroring the "no single
    scenario's outcome may prevent a later one" doctrine (owner directive 2026-08-17) at group-fallback
    granularity.

    Raises exactly what call_model() (or a governing_files read) itself raises — including the two
    whole-run stop signals — so run_live()'s outer try/except handles a batch call identically to a single
    one; this function does not catch a whole-run stop signal internally.

    `id_to_scenario` (2026-08-17; id -> full scenario dict, typically every id in scenarios.yaml) is
    threaded straight through to build_batch_prompt() (for the group's own cross-scenario reference
    resolution) and to each _run_one_scenario_live() fallback call below (so a reference doesn't silently
    stop resolving just because the group's batch reply happened to be unparseable)."""
    ids = [sc.get("id") for sc in group]
    # SECTION SCOPING (2026-08-17): group[0]'s own governing_sections is safe to use for the WHOLE group
    # here — group_scenarios_for_batching() now groups by the hash of the ASSEMBLED governing text itself
    # (_governing_text_group_key()), so every member of `group` is guaranteed to want byte-identical text,
    # exactly the same guarantee the pre-2026-08-17 shared-frozenset-of-governing_files grouping gave for
    # whole-file sends.
    gov_text = _read_governing_text(group[0].get("governing_files") or [], file_cache,
                                     group[0].get("governing_sections"))
    prompt = build_batch_prompt(group, gov_text, id_to_scenario)
    reply, model_used = call_model(prompt)
    parsed = parse_batch_reply(reply, ids)

    if all(v is None for v in parsed.values()):
        print(
            f"::warning::golden live group {gi + 1}/{n_groups} ({', '.join(ids)}): batch reply had zero "
            f"parseable DECISION[<id>]: line(s) — falling back to {len(group)} individual per-scenario "
            f"call(s) for this group.",
            file=sys.stderr, flush=True,
        )
        for sc in group:
            try:
                results.append(_run_one_scenario_live(sc, call_model, file_cache, id_to_scenario))
            except (_GeminiRunBudgetExhausted, _GeminiLadderPermanentlyDead):
                raise  # whole-run stop signal -- propagate untouched, run_live() handles it
            except Exception as exc:  # noqa: BLE001 — one fallback sub-call must not sink its group-mates
                print(f"::warning::{sc.get('id')}: model call failed (batch-fallback) — {exc}",
                      file=sys.stderr, flush=True)
                results.append({"id": sc.get("id"), "expected": sc.get("expected_decision"), "actual": None,
                                 "match": None, "reply": str(exc), "model": None})
        return

    for sc in group:
        sid = sc.get("id")
        actual_decision = parsed.get(sid)
        if actual_decision is None:
            print(
                f"::warning::{sid}: batch reply (group {gi + 1}/{n_groups}) had no DECISION[{sid}]: line "
                f"— scored as this scenario's own parse failure, not a decision flip (its group-mates "
                f"parsed fine).",
                file=sys.stderr, flush=True,
            )
            results.append({"id": sid, "expected": sc.get("expected_decision"), "actual": None,
                             "match": None, "reply": reply, "model": model_used})
            continue
        results.append(_score_decision(sc, actual_decision, reply, model_used))


def run_live(scenarios, scenario_ids=None):
    """Call the live Gemini model ladder, GROUPED by shared governing_files (BATCHING, 2026-08-17 — see
    the comment above group_scenarios_for_batching()), and diff each scenario's decision vs. its pinned
    expected_decision. Enabled by GEMINI_API_KEY (the sole provider; owner directive 2026-07-17). Advisory
    only — never returns a failing process exit code by itself; the caller decides.

    DISPATCH PER GROUP:
      * A group of size 1 BYPASSES the batch machinery entirely and goes straight to
        _run_one_scenario_live() (EVAL_PROMPT_TEMPLATE, unchanged from pre-batching) — there is nothing to
        batch for a single situation, so this is byte-identical to today's behavior, strictly simpler than
        building/parsing a one-situation batch prompt, and carries zero batch-reply parse risk for zero
        benefit. GOLDEN_BATCH=0 (env, default unset => batching ON) makes EVERY group size 1 in
        scenarios.yaml order (no byte-size reordering either) — the full escape hatch back to today's
        exact per-scenario call sequence.
      * A group of size 2+ goes through _run_batch_group() (one call_model() call via
        build_batch_prompt()/parse_batch_reply(), with a per-scenario-call fallback if the reply parses
        zero ids — see that function's docstring).

    STOPS EARLY (owner directive 2026-08-17, preserved unchanged by batching) on either whole-run signal
    _gemini_call can raise — _GeminiRunBudgetExhausted (GEMINI_RUN_BUDGET_S spent) or
    _GeminiLadderPermanentlyDead (every ladder model in state['dead']) — recording every NOT-YET-evaluated
    scenario as match='SKIPPED' with the reason ("never a silent nothing"). "Not-yet-evaluated" is
    determined by id membership in `results`, not by group boundaries: a group whose fallback sub-loop
    partially completed before the signal fired keeps its already-scored members' REAL results, only the
    rest (starting with whichever scenario's call actually raised, plus every scenario in every later
    group) become SKIPPED. A terminal signal raised on a MULTI-scenario group's initial (non-fallback)
    batch call has no partial completion to preserve — the whole group is "not yet evaluated" together,
    since one shared call answering for N scenarios cannot fail for only some of them.

    Any OTHER exception is a per-GROUP failure that does NOT stop the loop: every scenario in that group
    gets match=None (a plain per-scenario RuntimeError, or a governing_files read failure, raised by a
    single shared call answering for a whole batch group necessarily fails that whole group together — see
    the module's BATCHING comment for why this is the correct, not merely tolerated, consequence of
    batching multiple scenarios onto one call). No single group's failure may prevent a LATER group from
    attempting its own call.

    CROSS-SCENARIO REFERENCES (2026-08-17, see the comment above referenced_scenario_ids()): `id_to_
    scenario` is built here from the FULL `scenarios` list (every id in scenarios.yaml), not just `target`
    — a --scenario-filtered run can still resolve a reference to a sibling that isn't itself being
    evaluated this run — and threaded into both dispatch branches below so a referenced sibling's facts
    reach the model regardless of which path (size-1 / batched / GOLDEN_BATCH=0) a given scenario takes."""
    call_model = _select_live_caller()
    if call_model is None:
        return []
    results = []
    file_cache = {}
    id_to_scenario = {sc.get("id"): sc for sc in scenarios if isinstance(sc, dict) and sc.get("id")}

    target = [sc for sc in scenarios if not scenario_ids or sc.get("id") in scenario_ids]

    batching_enabled = os.environ.get("GOLDEN_BATCH", "1") != "0"
    if batching_enabled:
        groups = group_scenarios_for_batching(target)
    else:
        # GOLDEN_BATCH=0 escape hatch: one group per scenario, scenarios.yaml order preserved (no
        # byte-size reordering) — restores today's exact one-call-per-scenario call sequence.
        groups = [[sc] for sc in target]

    run_t0 = time.monotonic()
    state_ref = getattr(call_model, "state", None)  # None for a test's fake caller — see _select_live_caller
    # SECTION SCOPING telemetry (2026-08-17, task spec requirement): total governing bytes actually SENT
    # (honoring any scenario's governing_sections + GOLDEN_SECTION_SCOPE) vs. what the UNSCOPED equivalent
    # (every governing_files entry sent whole) would have cost — see _governing_bytes_scoped_vs_unscoped().
    # Both stay 0 for a run where no scenario declares governing_sections (scoped == unscoped in that case,
    # so this simply reports "0% saved," never a distorted number — see the no-op tests).
    total_scoped_bytes = 0
    total_unscoped_bytes = 0

    def _counter(key, default=0):
        return (state_ref or {}).get(key, default)

    for gi, group in enumerate(groups):
        group_ids = [sc.get("id") for sc in group]
        group_t0 = time.monotonic()
        attempts_before = _counter("total_attempts")
        # Governing-bytes telemetry for THIS group — computed unconditionally (independent of whether the
        # call below succeeds/fails/skips) since it is a pure function of scenario data + on-disk files, not
        # of the live call's outcome. Wrapped defensively: a missing governing_file will legitimately fail
        # the real call moments later anyway (and get reported there), so a telemetry-only read failure here
        # must not itself raise or print a second, redundant warning.
        group_token_est = None
        try:
            group_scoped_b, group_unscoped_b = _governing_bytes_scoped_vs_unscoped(
                group[0].get("governing_files") or [], group[0].get("governing_sections"), file_cache,
            )
            total_scoped_bytes += group_scoped_b
            total_unscoped_bytes += group_unscoped_b
            group_token_est = group_scoped_b // 4  # same rough chars/4 heuristic _gemini_call uses elsewhere
        except OSError:
            pass
        try:
            if len(group) == 1:
                results.append(_run_one_scenario_live(group[0], call_model, file_cache, id_to_scenario))
            else:
                _run_batch_group(group, call_model, file_cache, results, gi, len(groups), id_to_scenario)
        except (_GeminiRunBudgetExhausted, _GeminiLadderPermanentlyDead) as exc:
            already_ids = {r["id"] for r in results}
            remaining = [sc for grp in groups[gi:] for sc in grp if sc.get("id") not in already_ids]
            if len(group) == 1:
                sid = group[0].get("id")
                print(
                    f"::warning::{sid}: {exc} — stopping further live attempts this run "
                    f"({len(remaining)} scenario(s), including this one, not evaluated).",
                    file=sys.stderr, flush=True,
                )
            else:
                print(
                    f"::warning::group {gi + 1}/{len(groups)} ({', '.join(group_ids)}): {exc} — stopping "
                    f"further live attempts this run ({len(remaining)} scenario(s), not evaluated).",
                    file=sys.stderr, flush=True,
                )
            for rem in remaining:
                results.append({"id": rem.get("id"), "expected": rem.get("expected_decision"),
                                 "actual": None, "match": "SKIPPED", "reply": str(exc), "model": None})
            break
        except Exception as exc:  # noqa: BLE001 — advisory path; a group failure must not stop the loop
            already_ids = {r["id"] for r in results}
            for sc in group:
                if sc.get("id") in already_ids:
                    continue
                if len(group) == 1:
                    print(f"::warning::{sc.get('id')}: model call failed — {exc}",
                          file=sys.stderr, flush=True)
                else:
                    print(f"::warning::{sc.get('id')} (group {gi + 1}/{len(groups)}): model call failed "
                          f"— {exc}", file=sys.stderr, flush=True)
                results.append({"id": sc.get("id"), "expected": sc.get("expected_decision"), "actual": None,
                                 "match": None, "reply": str(exc), "model": None})
        finally:
            group_elapsed = time.monotonic() - group_t0
            attempts_used = _counter("total_attempts") - attempts_before
            print(
                f"::debug::golden live group {gi + 1}/{len(groups)} done — ids={group_ids} "
                f"elapsed={group_elapsed:.1f}s attempts={attempts_used} "
                f"governing_tokens~={group_token_est}",
                file=sys.stderr, flush=True,
            )

    run_elapsed = time.monotonic() - run_t0
    # SECTION SCOPING telemetry (2026-08-17): what scoping actually saved this run, vs. the unscoped
    # equivalent — see the accumulator comment above the per-group loop. Guarded against a zero-file run
    # (total_unscoped_bytes == 0, e.g. `scenarios` was empty) so this never divides by zero.
    bytes_saved_pct = (
        100.0 * (1 - total_scoped_bytes / total_unscoped_bytes) if total_unscoped_bytes else 0.0
    )
    print(
        f"::notice::golden live run summary — wall_clock={run_elapsed:.1f}s attempts={_counter('total_attempts')} "
        f"429s(rpm={_counter('total_429_rpm')}, daily={_counter('total_429_daily')}) "
        f"tokens_sent~={_counter('total_tokens_sent')} (includes every retry) sleep(pacing="
        f"{_counter('sleep_pacing_s', 0.0):.1f}s, rpm_retry={_counter('sleep_rpm_retry_s', 0.0):.1f}s, "
        f"rewind={_counter('sleep_rewind_s', 0.0):.1f}s) "
        # 2026-08-17 retune telemetry (CI run 32060180247, item 4): of the RPM sleeps above, how many
        # honoured a server-supplied RetryInfo.retryDelay vs. fell back to the flat GEMINI_RPM_RETRY_DELAY_S
        # default (see _has_retry_delay()), and how many times the ladder moved off a rung without
        # succeeding on it (state['ladder_switches'], incremented in _gemini_call's dispatch loop) — this is
        # how the NEXT run gets judged against the GEMINI_RPM_MAX_RETRIES 5->2 retune's own stated goal
        # (switch rungs sooner instead of re-sleeping on one), not just eyeballed from wall_clock alone.
        f"rpm_retry_delay(server={_counter('sleep_rpm_retry_server_n')}, "
        f"default={_counter('sleep_rpm_retry_default_n')}) ladder_switches={_counter('ladder_switches')} "
        f"— see the OBSERVABILITY comment above GEMINI_MODEL_LADDER for why this line exists (CI run "
        f"32043614925, 2026-08-17), and the comment above GEMINI_RPM_MAX_RETRIES for the RPM-retry retune "
        f"(CI run 32060180247, 2026-08-17). "
        # SECTION SCOPING (2026-08-17, CI run 32069773377 — 94% of requests 429'd at 480,044 tokens/min, a
        # TOKENS-per-minute ceiling batching alone couldn't fix): governing bytes actually sent this run vs.
        # what sending every governing_files entry WHOLE (no scoping) would have cost.
        f"governing_bytes(scoped={total_scoped_bytes}, unscoped={total_unscoped_bytes}, "
        f"saved={bytes_saved_pct:.1f}%)",
        file=sys.stderr, flush=True,
    )
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--offline", action="store_true", help="offline schema validation only (no network); default")
    mode.add_argument("--live", action="store_true", help="call the live Gemini ladder and diff decisions (network; advisory)")
    mode.add_argument("--scenarios-for-changed", action="store_true", dest="scenarios_for_changed",
                       help="print (one id per line) the scenarios governed by --changed-file path(s), then exit "
                            "(no network, no offline/live run; utility mode for CI cost-scoping)")
    parser.add_argument("--scenario", action="append", dest="scenario_ids", default=None,
                         help="restrict --live to this scenario id (repeatable)")
    parser.add_argument("--changed-file", action="append", dest="changed_files", default=None,
                         help="repo-relative changed file path (repeatable); only used with --scenarios-for-changed")
    args = parser.parse_args()

    try:
        scenarios = load_scenarios()
    except (OSError, ValueError, yaml.YAMLError) as exc:
        print(f"FATAL: could not load {SCENARIOS_PATH}: {exc}", file=sys.stderr)
        return 1

    if args.scenarios_for_changed:
        # Pure utility mode: no offline schema gate, no network. CORRECTED (2026-08-31 code-quality
        # pass): this used to say golden-scenarios.yml's `prose-regression` job invokes this mode with
        # `needs: schema-validate` ensuring the offline gate already passed first — that job no longer
        # exists in this file (retired 2026-08-30; see the module docstring's --scenarios-for-changed
        # section) and nothing in production calls this mode today. Documenting the ordering contract
        # for whichever future caller (if any) adopts it: such a caller would still want the offline
        # gate to have passed for this SHA first, since this mode does not itself validate scenarios.yaml.
        for sid in scenarios_for_changed_files(scenarios, args.changed_files):
            print(sid)
        return 0

    # The offline schema gate ALWAYS runs first, in both modes — a broken fixture file must never be
    # masked by a live run that happens to still produce plausible-looking output.
    errors = validate_offline(scenarios)
    if errors:
        print(f"FAIL — {len(errors)} golden-scenario schema error(s):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print(f"OK — {len(scenarios)} golden scenarios pass offline schema validation "
          f"(unique ids, required fields present, every governing_file exists, "
          f"expected_decision vocabulary recognized).")

    if not args.live:
        return 0

    _provider = "Gemini free tier" if os.environ.get("GEMINI_API_KEY") else "none configured (set GEMINI_API_KEY)"
    print(f"\nLive mode — provider={_provider}, {len(scenarios)} scenario(s) "
          f"(filter: {args.scenario_ids or 'all'})", flush=True)
    if args.scenario_ids:
        known_ids = {sc.get("id") for sc in scenarios}
        unknown = [sid for sid in args.scenario_ids if sid not in known_ids]
        if unknown:
            print(f"::warning::--scenario id(s) not found in scenarios.yaml: {unknown}",
                  file=sys.stderr, flush=True)
    results = run_live(scenarios, scenario_ids=args.scenario_ids)
    if not results:
        print("Live run produced no results (skipped — see notice/warning above). Advisory: exit 0.",
              flush=True)
        return 0

    n_match = sum(1 for r in results if r["match"] is True)
    n_flip = sum(1 for r in results if r["match"] is False)
    n_unparseable = sum(1 for r in results if r["match"] == "UNPARSEABLE")
    n_skipped = sum(1 for r in results if r["match"] == "SKIPPED")
    n_err = sum(1 for r in results if r["match"] is None)
    n_evaluated = len(results) - n_skipped
    print(f"\nLive results: {n_match} match, {n_flip} flip(s), {n_unparseable} unparseable, "
          f"{n_err} error(s), {n_skipped} skipped ({n_evaluated} evaluated) out of {len(results)}.",
          flush=True)
    for r in results:
        if r["match"] is True:
            status = "MATCH"
        elif r["match"] is False:
            status = "FLIP"
        elif r["match"] == "UNPARSEABLE":
            status = "UNPARSEABLE"
        elif r["match"] == "SKIPPED":
            status = "SKIPPED"
        else:
            status = "ERROR"
        print(f"  [{status}] {r['id']}: expected={r['expected']!r} actual={r['actual']!r}", flush=True)

    # NEVER A SILENT NOTHING (owner directive 2026-08-17): always state how many scenarios were evaluated
    # vs. skipped, and why, as a GitHub Actions annotation — the only surface a human actually reads for
    # this advisory job. A partial result reported honestly is the required behavior; zero results with no
    # explanation is the exact bug this fix closes (live CI run 32039658866: 33 scoped, 1 attempted, 32
    # silently short-circuited with no indication why).
    if n_skipped:
        skip_reasons = sorted({r["reply"] for r in results if r["match"] == "SKIPPED"})
        print(f"::warning::golden live run: {n_skipped} scenario(s) SKIPPED (not attempted), "
              f"{n_evaluated} evaluated out of {len(results)}. Skip reason(s): {'; '.join(skip_reasons)}",
              flush=True)
    else:
        print(f"::notice::golden live run: all {n_evaluated} scenario(s) considered were evaluated "
              f"(0 skipped).", flush=True)

    # Advisory only — see module docstring. A flip, error, or skip is reported (already emitted as
    # ::warning:: above) but never fails the process; the workflow's continue-on-error is the other
    # half of that contract for when this runs in CI.
    return 0


if __name__ == "__main__":
    sys.exit(main())
