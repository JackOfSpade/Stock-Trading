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
      For each scenario, reads the CURRENT text of its governing_files, sends the pinned
      EVAL_PROMPT_TEMPLATE below to a live model, parses a DECISION: line from the reply, and diffs
      it against expected_decision's leading token. PROVIDER: Gemini's FREE tier (GEMINI_API_KEY), the
      sole provider — walks GEMINI_MODEL_LADDER, degrading model on per-model daily-quota exhaustion;
      stdlib REST, no SDK dependency; thinking left ON for accuracy. Prints a pass/fail table and, for the first
      leading-token mismatch on a NON-EMPTY governing_files reread, prints a GitHub Actions
      `::warning::` annotation plus the events.queue_events INSERT this script itself has no BigQuery
      write credentials to execute (CI stays read-only by design). WIRED FOR REAL (self-improvement
      audit 2026-07-15, CONFIRMED GAP golden-scenarios-prose-regression-unwired): D3 (Claude_Task_
      Plan.md's "GOLDEN-SCENARIO PROSE-REGRESSION CHECK" step) has full repo+BigQuery write access and
      runs daily — it performs the SAME governing-files-changed-since-last-check + re-evaluate logic
      independently (D3 IS the model, no separate API call), and actually files the queue entry
      (review_type='prose-regression', now a recognized AR review_type — see the Adversarial Reviews
      section) on a real mismatch. This CI job remains a secondary, push-time signal only. Requires
      GEMINI_API_KEY (free tier). Always exits 0 (advisory) unless the offline schema gate itself fails first,
      or setup fails outright (missing API key/library), which is reported but still does not fail the
      *build* — the workflow's continue-on-error covers that.

Usage:
  python tests/golden_scenarios/run_golden.py --offline
  python tests/golden_scenarios/run_golden.py --live [--scenario ID ...]   # needs GEMINI_API_KEY
  python tests/golden_scenarios/run_golden.py --scenarios-for-changed [--changed-file PATH ...]
      Utility mode (no network): prints, one per line, the ids of scenarios whose governing_files
      intersect the given --changed-file path(s), then exits — no offline/live run. Used by
      golden-scenarios.yml's `prose-regression` job (2026-07-30 cost-scoping) to compute the
      --scenario filter for --live from the push's changed files, so a push only re-evaluates the
      scenarios actually governed by what changed instead of all of them on every push. See
      scenarios_for_changed_files() for the fail-open rules (no --changed-file at all, or a change
      under tests/golden_scenarios/ itself, both select EVERY scenario id).
"""
import argparse
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
#   * per-MINUTE (RPM) — TRANSIENT. Wait out the API's suggested RetryInfo.retryDelay and retry the SAME
#     model. Rate-rejected requests do not consume the daily quota.
#   * per-DAY (RPD)    — persistent for the rest of the day. Advance the ladder AND mark the model dead
#     (state["dead"], sticky for the rest of the run) — waiting is futile.
GEMINI_RPM_MAX_RETRIES = int(os.environ.get("GEMINI_RPM_MAX_RETRIES", "5"))
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
EVAL_PROMPT_TEMPLATE = """You are evaluating ONE pinned regression scenario against this trading \
system's CURRENT governing prose. Read the governing-file excerpts below exactly as given below — do \
not rely on any outside/remembered knowledge of a prior revision of these files. Apply the rules \
mechanically and literally, exactly as an autonomous routine session executing Claude_Task_Plan.md \
would, with no added judgment beyond what the cited rule requires.

=== GOVERNING FILES (verbatim, current repo state) ===
{governing_files_text}

=== SCENARIO ===
{situation}

Respond with EXACTLY two lines and nothing else:
DECISION: <one of {allowed_decisions}>
RATIONALE: <one sentence citing the specific rule/section/threshold you applied>
"""

QUEUE_INSERT_TEMPLATE = """-- SPEC ONLY — never executed by this script (no BigQuery write credentials in CI; a routine with
-- write access may choose to file this for real). review_type='prose-regression' per ITEM 20.
INSERT INTO `stock-trading-498512.events.queue_events`
  (queue, item_key, item_type, status, note, payload)
VALUES (
  'PENDING_REVIEW',
  '{scenario_id}',
  'prose-regression',
  'pending',
  'golden-scenario decision flip: {scenario_id} expected {expected!r} got {actual!r}',
  JSON '{{"review_type": "prose-regression", "scenario_id": "{scenario_id}", "expected": {expected!r}, "actual": {actual!r}, "governing_files": {governing_files!r}}}'
);"""


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
    plain-unit-testable without a real git repo or a live model."""
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
    strings (empty list = pass). This is the function the CI hard gate depends on."""
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


def _retry_delay_s(body, default):
    """Pull RetryInfo.retryDelay (e.g. "retryDelay": "38s") out of a 429 body; fall back to `default`."""
    m = re.search(r'"retryDelay"\s*:\s*"(\d+(?:\.\d+)?)s"', body or "")
    return float(m.group(1)) if m else default


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
    per the "never start a sleep that would overrun the budget" rule."""
    now = time.monotonic()
    last = state.get("last_call_ts")
    if last is not None:
        remaining = GEMINI_MIN_CALL_INTERVAL_S - (now - last)
        if remaining > 0:
            _check_run_budget(state, extra_s=remaining)
            time.sleep(remaining)
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
            data = _json.load(resp)
        cand = (data.get("candidates") or [{}])[0]
        parts = cand.get("content", {}).get("parts", []) or []
        # Thinking is ON, so a model MAY return separate "thought" summary parts (part.thought == True);
        # keep only the real answer text so the DECISION line parser never sees reasoning text.
        text = "".join(p.get("text", "") for p in parts
                       if isinstance(p, dict) and not p.get("thought"))
        return text, cand.get("finishReason", "")

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
        while True:
            try:
                text, finish = _post(model, budget)
            except urllib.error.HTTPError as exc:
                body = exc.read().decode("utf-8", "replace")
                # A per-MINUTE 429 is transient: sleep out the API's suggested retryDelay and retry the
                # SAME model. Only a per-DAY 429 (or any other HTTP error) is a hard/permanent failure.
                if exc.code == 429 and not _is_daily_quota_429(body):
                    last_rpm_body = body   # remembered for the rewind cooldown's own RetryInfo, below
                    if rpm_retries < GEMINI_RPM_MAX_RETRIES:
                        rpm_retries += 1
                        delay = _retry_delay_s(body, GEMINI_RPM_RETRY_DELAY_S)
                        _check_run_budget(state, extra_s=delay)
                        time.sleep(delay)
                        continue
                    errors.append(f"{model}: rate-limited (429/min) after {rpm_retries} retries")
                    return None, True
                # 429/day = daily quota gone; 404 = model not served to this key; 400 = e.g. budget above
                # this model's max; 5xx = transient-but-unretried. All => hard/permanent, dead the model.
                errors.append(f"{model}: HTTP {exc.code} {body[:200]}")
                return None, False
            except (urllib.error.URLError, TimeoutError, ValueError) as exc:
                errors.append(f"{model}: {exc}")
                return None, False
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
              file=sys.stderr)

        def call_model(prompt):
            return _gemini_call(prompt, gemini_key, ladder, state)
        return call_model

    print(
        "::notice::GEMINI_API_KEY not set — live golden-scenario run skipped (opt-in). Offline schema "
        "validation is unaffected.",
        file=sys.stderr,
    )
    return None


def run_live(scenarios, scenario_ids=None):
    """Call the live Gemini model ladder per scenario and diff its decision vs. the pinned
    expected_decision. Enabled by GEMINI_API_KEY (the sole provider; owner directive 2026-07-17).
    Advisory only — never returns a failing process exit code by itself; the caller decides.

    STOPS EARLY (owner directive 2026-08-17) on either whole-run signal _gemini_call can raise —
    _GeminiRunBudgetExhausted (GEMINI_RUN_BUDGET_S spent) or _GeminiLadderPermanentlyDead (every ladder
    model in state['dead'], a genuine waiting-cannot-help exhaustion) — recording the triggering scenario
    AND every scenario after it as match='SKIPPED' with the reason, instead of letting each remaining
    scenario independently re-attempt and re-discover the same terminal condition ("never a silent
    nothing" — a partial result reported honestly, not silence). Any OTHER exception — including a plain
    per-scenario RuntimeError from a bounded ladder-rewind exhaustion, see _gemini_call's docstring — is
    an ordinary per-scenario failure (match=None) and does NOT stop the loop: no single scenario's outcome
    may prevent a later one from attempting its own call."""
    call_model = _select_live_caller()
    if call_model is None:
        return []
    results = []
    file_cache = {}

    target = [sc for sc in scenarios if not scenario_ids or sc.get("id") in scenario_ids]

    for i, sc in enumerate(target):
        sid = sc.get("id")

        # 2026-07-29 bug hunt: this governing_files read used to sit OUTSIDE the try/except below, so one
        # scenario with a missing/unreadable governing_file raised an uncaught OSError straight out of
        # run_live() — aborting the ENTIRE batch (every later scenario silently never evaluated) instead
        # of degrading just that one scenario, unlike every other per-scenario failure this loop already
        # handles (a bad model call, a malformed reply, etc.). Folded into the same try/except so a read
        # failure is reported and scored exactly like a model-call failure.
        try:
            gov_text_parts = []
            for gf in sc.get("governing_files", []):
                if gf not in file_cache:
                    with open(os.path.join(ROOT, gf), encoding="utf-8") as fh:
                        file_cache[gf] = fh.read()
                gov_text_parts.append(f"----- {gf} -----\n{file_cache[gf]}")
            prompt = EVAL_PROMPT_TEMPLATE.format(
                governing_files_text="\n\n".join(gov_text_parts),
                situation=sc.get("situation", "").strip(),
                allowed_decisions=_allowed_decisions_for(sc),
            )
            reply, model_used = call_model(prompt)
        except (_GeminiRunBudgetExhausted, _GeminiLadderPermanentlyDead) as exc:
            remaining = target[i:]
            print(
                f"::warning::{sid}: {exc} — stopping further live attempts this run "
                f"({len(remaining)} scenario(s), including this one, not evaluated).",
                file=sys.stderr,
            )
            for rem in remaining:
                results.append({"id": rem.get("id"), "expected": rem.get("expected_decision"),
                                 "actual": None, "match": "SKIPPED", "reply": str(exc), "model": None})
            break
        except Exception as exc:  # noqa: BLE001 — advisory path, any failure is reported, not raised
            print(f"::warning::{sid}: model call failed — {exc}", file=sys.stderr)
            results.append({"id": sid, "expected": sc.get("expected_decision"), "actual": None,
                             "match": None, "reply": str(exc), "model": None})
            continue

        actual_line = next((ln for ln in reply.splitlines() if ln.strip().upper().startswith("DECISION:")), "")
        actual_decision = actual_line.split(":", 1)[1].strip() if ":" in actual_line else reply.strip()
        expected_tok = _leading_token(sc.get("expected_decision"))
        actual_tok = _leading_token(actual_decision)

        if actual_tok is None:
            # The model replied (no exception) but the answer didn't start with ANY recognized
            # DECISION_LEAD_TOKENS token -- it ignored the "<one of ...>" instruction and invented its
            # own word. That's a format-following failure, not a decision disagreement: there is no real
            # expected-vs-actual call to adjudicate, so it must not be blended into the FLIP bucket below
            # (which proposes a prose-regression review) or silently miscounted as one.
            match = "UNPARSEABLE"
        else:
            match = expected_tok is not None and expected_tok == actual_tok

        results.append({
            "id": sid, "expected": sc.get("expected_decision"), "actual": actual_decision,
            "match": match, "reply": reply, "model": model_used,
        })

        if match is False:
            print(
                f"::warning file=tests/golden_scenarios/scenarios.yaml::{sid} decision flip — "
                f"expected '{sc.get('expected_decision')}' got '{actual_decision}'. "
                f"Governing files: {sc.get('governing_files')}."
            )
            print(QUEUE_INSERT_TEMPLATE.format(
                scenario_id=sid,
                expected=sc.get("expected_decision"),
                actual=actual_decision,
                governing_files=sc.get("governing_files"),
            ))
        elif match == "UNPARSEABLE":
            print(
                f"::warning::{sid}: model reply had no recognized decision token — got '{actual_decision}'. "
                f"Not filed as a decision flip (no expected-vs-actual call to adjudicate); no "
                f"queue_events INSERT emitted."
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
        # Pure utility mode: no offline schema gate, no network. Callers that need a validated
        # scenarios.yaml before trusting this output already get that for free — golden-scenarios.yml's
        # `prose-regression` job only runs `needs: schema-validate`, so by the time this mode is invoked
        # there, the offline hard gate already passed for this SHA.
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
          f"(filter: {args.scenario_ids or 'all'})")
    if args.scenario_ids:
        known_ids = {sc.get("id") for sc in scenarios}
        unknown = [sid for sid in args.scenario_ids if sid not in known_ids]
        if unknown:
            print(f"::warning::--scenario id(s) not found in scenarios.yaml: {unknown}", file=sys.stderr)
    results = run_live(scenarios, scenario_ids=args.scenario_ids)
    if not results:
        print("Live run produced no results (skipped — see notice/warning above). Advisory: exit 0.")
        return 0

    n_match = sum(1 for r in results if r["match"] is True)
    n_flip = sum(1 for r in results if r["match"] is False)
    n_unparseable = sum(1 for r in results if r["match"] == "UNPARSEABLE")
    n_skipped = sum(1 for r in results if r["match"] == "SKIPPED")
    n_err = sum(1 for r in results if r["match"] is None)
    n_evaluated = len(results) - n_skipped
    print(f"\nLive results: {n_match} match, {n_flip} flip(s), {n_unparseable} unparseable, "
          f"{n_err} error(s), {n_skipped} skipped ({n_evaluated} evaluated) out of {len(results)}.")
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
        print(f"  [{status}] {r['id']}: expected={r['expected']!r} actual={r['actual']!r}")

    # NEVER A SILENT NOTHING (owner directive 2026-08-17): always state how many scenarios were evaluated
    # vs. skipped, and why, as a GitHub Actions annotation — the only surface a human actually reads for
    # this advisory job. A partial result reported honestly is the required behavior; zero results with no
    # explanation is the exact bug this fix closes (live CI run 32039658866: 33 scoped, 1 attempted, 32
    # silently short-circuited with no indication why).
    if n_skipped:
        skip_reasons = sorted({r["reply"] for r in results if r["match"] == "SKIPPED"})
        print(f"::warning::golden live run: {n_skipped} scenario(s) SKIPPED (not attempted), "
              f"{n_evaluated} evaluated out of {len(results)}. Skip reason(s): {'; '.join(skip_reasons)}")
    else:
        print(f"::notice::golden live run: all {n_evaluated} scenario(s) considered were evaluated "
              f"(0 skipped).")

    # Advisory only — see module docstring. A flip, error, or skip is reported (already emitted as
    # ::warning:: above) but never fails the process; the workflow's continue-on-error is the other
    # half of that contract for when this runs in CI.
    return 0


if __name__ == "__main__":
    sys.exit(main())
