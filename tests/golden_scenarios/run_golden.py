#!/usr/bin/env python3
"""Golden-scenario prose regression runner (ITEM 20, 2026-07-11).

WHY THIS EXISTS. This system's real source code is prose (Strategy.md, Operating_Protocols.md,
Claude_Task_Plan.md routine bodies) read fresh by an LLM every routine run. Every existing CI check
(scripts/check_cadence_consistency.py, check_roster_consistency.py, check_autonomy_consistency.py,
split_strategy.py --check) is a STRUCTURAL fact scraper — none of them evaluate what a routine would
DECIDE when it reads the prose. tests/golden_scenarios/scenarios.yaml pins 20 concrete decision
scenarios (regime-router edge cases, kill-trigger/gate mechanics, Strategy B entry criteria) with an
expected GO/NO-GO | CONTINUE/TERMINATE | ACTIVATE/DO-NOT-ACTIVATE call and the specific rule that
produces it. This script is the runner.

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
    raise SystemExit(2)

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
# below is tried best-quality-first; a model is abandoned (permanently, for the rest of the run) only on
# a per-DAY quota exhaustion or a hard error — NOT on a per-minute rate limit (see the RPM constants
# below). "Thinking" is left ON (default/dynamic) — this is an accuracy check whose whole job is catching
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
#   * per-DAY (RPD)    — persistent for the rest of the day. Advance the ladder (sticky) — waiting is futile.
GEMINI_RPM_MAX_RETRIES = int(os.environ.get("GEMINI_RPM_MAX_RETRIES", "5"))
GEMINI_RPM_RETRY_DELAY_S = float(os.environ.get("GEMINI_RPM_RETRY_DELAY_S", "20"))

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
            cat = sc.get("category")
            if cat in CATEGORY_TOKENS:
                tok = _leading_token(decision)
                if tok is not None and tok not in CATEGORY_TOKENS[cat]:
                    errors.append(
                        f"{label}: expected_decision token '{tok}' is not valid for category '{cat}' "
                        f"(allowed: {sorted(CATEGORY_TOKENS[cat])}) — likely a mis-categorized/copy-paste fixture")
    return errors


def _token_boundary_match(lead, tok):
    """True when `lead` (already .strip().upper()'d) starts with `tok` AND that match ends at a real
    token boundary — end-of-string, whitespace, or an opening paren (the documented free-text-qualifier
    separator, e.g. "CONTINUE (routes to review, not direct terminate)"). Plain str.startswith() alone
    lets a PREFIX TYPO through: 'CONTINUES' startswith 'CONTINUE', 'TERMINATED' startswith 'TERMINATE',
    'ACTIVATED' startswith 'ACTIVATE', 'GOOF' startswith 'GO' — none of those are the token, all are a
    fixture typo, and all four passed the offline gate with zero errors and were then graded in --live
    as if correctly spelled (codebase audit 2026-07-26). Shared by validate_offline()'s vocabulary check
    and _leading_token()'s grader so the gate and the grader can never disagree about what a token is."""
    if not lead.startswith(tok):
        return False
    rest = lead[len(tok):]
    return rest == "" or rest[0].isspace() or rest[0] == "("


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


def _gemini_call(prompt, api_key, ladder, state):
    """POST one prompt to Gemini via the stdlib (no SDK dependency) and return (reply_text, model_id).

    TWO nested fallbacks:
      * Per model — ADAPTIVE OUTPUT BUDGET. Thinking is ON and draws from maxOutputTokens, so a hard
        scenario can truncate (finishReason=MAX_TOKENS) before emitting the DECISION line. On that, the
        budget DOUBLES (GEMINI_MAX_OUTPUT_TOKENS_START → … → _CEIL) and the SAME model is retried, until
        it produces an answer or the ceiling is reached.
      * Across models — LADDER. On a quota/auth/transport error, a safety-blocked/otherwise-empty reply,
        or still-truncating at the ceiling, it advances state['idx'] to the next ladder model (STICKY for
        the rest of the run — a model that is quota-exhausted or too small stays skipped for later
        scenarios too). Raises RuntimeError only when the whole ladder is exhausted."""
    import json as _json
    import urllib.error
    import urllib.request

    def _post(model, max_tokens):
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
        the answer text on success, or None (setting nonlocal last_err) if this model should be skipped.

        The starting budget is the run-level HIGH-WATER MARK (state['budget']), not always _START: once
        any scenario in this run had to escalate, every later scenario/model starts at that discovered
        budget instead of re-truncating its way back up from _START each time (the 23 scenarios have the
        same prompt shape, so if one needs a bigger budget they all do — this spends the per-model daily
        request quota once per run, not once per scenario). It never ratchets DOWN within a run; a bigger
        cap costs nothing per request (the model still emits only the short answer), and every ladder
        model accepts up to the ceiling, so carrying the mark across models is safe. state is fresh per
        run (created in _select_live_caller), so a new CI run re-starts at _START."""
        budget = state["budget"]
        rpm_retries = 0
        while True:
            try:
                text, finish = _post(model, budget)
            except urllib.error.HTTPError as exc:
                body = exc.read().decode("utf-8", "replace")
                # A per-MINUTE 429 is transient: sleep out the API's suggested retryDelay and retry the
                # SAME model. Only a per-DAY 429 (or any other HTTP error) abandons the model.
                if exc.code == 429 and not _is_daily_quota_429(body):
                    if rpm_retries < GEMINI_RPM_MAX_RETRIES:
                        rpm_retries += 1
                        time.sleep(_retry_delay_s(body, GEMINI_RPM_RETRY_DELAY_S))
                        continue
                    errors.append(f"{model}: rate-limited (429/min) after {rpm_retries} retries")
                    return None
                # 429/day = daily quota gone; 404 = model not served to this key; 400 = e.g. budget above
                # this model's max; 5xx = transient-but-unretried. All => abandon model, advance ladder.
                errors.append(f"{model}: HTTP {exc.code} {body[:200]}")
                return None
            except (urllib.error.URLError, TimeoutError, ValueError) as exc:
                errors.append(f"{model}: {exc}")
                return None
            if text.strip():
                return text
            # Empty answer. If it was a MAX_TOKENS truncation and we have headroom, DOUBLE the budget and
            # retry the SAME model — the reasoning ran past the budget before reaching the DECISION line.
            if finish == "MAX_TOKENS" and budget < GEMINI_MAX_OUTPUT_TOKENS_CEIL:
                budget = min(budget * 2, GEMINI_MAX_OUTPUT_TOKENS_CEIL)
                state["budget"] = budget   # high-water mark: later scenarios/models start here, not _START
                continue
            # Empty for another reason (safety block, unexpected finishReason) or still truncating at the
            # ceiling — give up on this model and advance the ladder.
            errors.append(f"{model}: empty response (finishReason={finish or '?'}, maxOutputTokens={budget})")
            return None

    state.setdefault("budget", GEMINI_MAX_OUTPUT_TOKENS_START)  # run-level output-budget high-water mark
    # Accumulate EVERY model's failure (not just the last), so a total-ladder-exhaustion error names what
    # each model actually returned — the difference between "all 404 (bad model ids/key)", "all 429
    # (quota)", and "mixed" is the whole diagnosis.
    errors = []
    if state["idx"] >= len(ladder):
        # An earlier scenario in this run already walked the whole ladder (bad key / total quota-out).
        raise RuntimeError("Gemini model ladder already exhausted earlier this run (see the first scenario's error)")
    while state["idx"] < len(ladder):
        model = ladder[state["idx"]]
        text = _try_model(model)
        if text is not None:
            return text, model
        state["idx"] += 1

    raise RuntimeError("Gemini model ladder exhausted — " + " | ".join(errors))


def _select_live_caller():
    """Return a call_model(prompt) -> (reply_text, model_id) callable for the Gemini free-tier provider,
    or None (after printing a ::notice::) when GEMINI_API_KEY is not set. Gemini is the sole provider
    (owner directive 2026-07-17 — no Anthropic fallback)."""
    gemini_key = os.environ.get("GEMINI_API_KEY")
    if gemini_key:
        ladder = GEMINI_MODEL_LADDER
        # Shared across all scenarios in this run: idx = ladder position (sticky), budget = output-token
        # high-water mark (sticky, never resets down within a run). Fresh dict per run => fresh start.
        state = {"idx": 0, "budget": GEMINI_MAX_OUTPUT_TOKENS_START}
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
    Advisory only — never returns a failing process exit code by itself; the caller decides."""
    call_model = _select_live_caller()
    if call_model is None:
        return []
    results = []
    file_cache = {}

    for sc in scenarios:
        sid = sc.get("id")
        if scenario_ids and sid not in scenario_ids:
            continue

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

        try:
            reply, model_used = call_model(prompt)
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
    parser.add_argument("--scenario", action="append", dest="scenario_ids", default=None,
                         help="restrict --live to this scenario id (repeatable)")
    args = parser.parse_args()

    try:
        scenarios = load_scenarios()
    except (OSError, ValueError, yaml.YAMLError) as exc:
        print(f"FATAL: could not load {SCENARIOS_PATH}: {exc}", file=sys.stderr)
        return 1

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
    n_err = sum(1 for r in results if r["match"] is None)
    print(f"\nLive results: {n_match} match, {n_flip} flip(s), {n_unparseable} unparseable, "
          f"{n_err} error(s) out of {len(results)}.")
    for r in results:
        if r["match"] is True:
            status = "MATCH"
        elif r["match"] is False:
            status = "FLIP"
        elif r["match"] == "UNPARSEABLE":
            status = "UNPARSEABLE"
        else:
            status = "ERROR"
        print(f"  [{status}] {r['id']}: expected={r['expected']!r} actual={r['actual']!r}")

    # Advisory only — see module docstring. A flip or an error is reported (already emitted as
    # ::warning:: above) but never fails the process; the workflow's continue-on-error is the other
    # half of that contract for when this runs in CI.
    return 0


if __name__ == "__main__":
    sys.exit(main())
