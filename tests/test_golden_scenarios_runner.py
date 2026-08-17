"""Guard tests/golden_scenarios/run_golden.py's OWN offline schema validator (2026-07-14 audit
finding). validate_offline() and _leading_token() are the entire CI hard gate for the golden-scenario
harness, but were previously exercised only indirectly (running --offline against the current,
always-valid scenarios.yaml) — never fed a deliberately-broken fixture to prove each check actually
fires. golden-scenarios.yml's own header cites this exact discipline as load-bearing ("a check that
vacuously passes on a broken fixture is worse than no check") but the harness didn't apply it to
itself. Mirrors tests/test_cadence_consistency.py / test_roster_consistency.py's fixture-perturbation
pattern, just against small in-memory scenario dicts instead of a repo_copy (validate_offline() takes
a plain list and only checks file-existence via the real ROOT, which real repo-relative names like
'Strategy.md' satisfy for the happy path).
"""
import contextlib
import copy
import io
import json as _json
import os
import sys
import urllib.error
import urllib.request

import pytest

from conftest import load_module_from_path

rg = load_module_from_path("run_golden", "tests", "golden_scenarios", "run_golden.py")

VALID = {
    "id": "ZZ-01", "category": "kill_trigger", "situation": "x",
    "governing_files": ["Strategy.md"], "expected_decision": "CONTINUE", "rationale": "x",
}


@pytest.fixture(autouse=True)
def _no_pacing_by_default(monkeypatch):
    """_gemini_call's per-_post pacing (_pace, GEMINI_MIN_CALL_INTERVAL_S) is orthogonal to nearly every
    test in this file, but would otherwise interfere with them: _pace() measures elapsed time via the REAL
    time.monotonic() (most tests don't mock it), while time.sleep IS mocked to a no-op everywhere else in
    this file -- so back-to-back retries within a single test execute in a few microseconds of wall-clock
    time, _pace() sees "almost no time elapsed", and injects its own extra ~GEMINI_MIN_CALL_INTERVAL_S
    sleep call on top of whatever the test is actually trying to count (RPM retries, rewind cooldowns,
    etc). Zero the interval by default so pacing is a true no-op unless a test explicitly opts back in --
    this IS the documented contract ("the pacing interval must be overridable to ~0 in tests so nothing
    actually sleeps"). The dedicated test_pace_* tests below re-enable a real interval value themselves."""
    monkeypatch.setattr(rg, "GEMINI_MIN_CALL_INTERVAL_S", 0.0)


def test_real_scenarios_yaml_passes_offline_validation():
    assert rg.validate_offline(rg.load_scenarios()) == []


def test_duplicate_id_caught():
    errs = rg.validate_offline([copy.deepcopy(VALID), copy.deepcopy(VALID)])
    assert any("duplicate scenario id" in e for e in errs)


def test_missing_required_field_caught():
    sc = copy.deepcopy(VALID)
    del sc["rationale"]
    assert any("missing or empty required field 'rationale'" in e for e in rg.validate_offline([sc]))


def test_empty_required_field_caught():
    sc = copy.deepcopy(VALID)
    sc["situation"] = "   "
    assert any("missing or empty required field 'situation'" in e for e in rg.validate_offline([sc]))


def test_nonexistent_governing_file_caught():
    sc = copy.deepcopy(VALID)
    sc["governing_files"] = ["Strategy_Does_Not_Exist.md"]
    assert any("does not exist" in e for e in rg.validate_offline([sc]))


def test_governing_files_must_be_a_list():
    sc = copy.deepcopy(VALID)
    sc["governing_files"] = "Strategy.md"
    assert any("governing_files must be a list" in e for e in rg.validate_offline([sc]))


def test_empty_governing_files_list_caught():
    sc = copy.deepcopy(VALID)
    sc["governing_files"] = []
    assert any("non-empty list" in e for e in rg.validate_offline([sc]))


def test_unrecognized_decision_token_caught():
    sc = copy.deepcopy(VALID)
    sc["expected_decision"] = "MAYBE"
    assert any("does not start with a recognized token" in e for e in rg.validate_offline([sc]))


def test_category_token_mismatch_caught():
    sc = copy.deepcopy(VALID)
    sc["category"] = "kill_trigger"
    sc["expected_decision"] = "GO"  # GO is a globally-valid token, but not for kill_trigger
    assert any("is not valid for category" in e for e in rg.validate_offline([sc]))


def test_unrecognized_category_caught():
    # 2026-07-29 bug hunt: validate_offline() never checked `category` itself against CATEGORY_TOKENS —
    # the old code only ran a mismatch check INSIDE `if cat in CATEGORY_TOKENS:`, which just no-ops for a
    # typo'd/invented category. VALID's expected_decision ("CONTINUE") is a perfectly valid GLOBAL token,
    # so the vocabulary check alone can't catch this — only a dedicated category-membership check can.
    sc = copy.deepcopy(VALID)
    sc["category"] = "kil_trigger"  # typo of 'kill_trigger'
    errs = rg.validate_offline([sc])
    assert any("category 'kil_trigger' is not a recognized key in CATEGORY_TOKENS" in e for e in errs), errs
    # The error must name the valid categories, so a human fixing the fixture doesn't have to go read the
    # source for the CATEGORY_TOKENS dict.
    assert any("kill_trigger" in e and "regime_router" in e for e in errs), errs


def test_missing_category_not_flagged_as_unrecognized():
    # A scenario with NO category at all is a separate (pre-existing, out of scope) concern from a
    # WRONG category — don't conflate "absent" with "typo'd" and start rejecting fixtures that never
    # opted into the per-category scoping in the first place.
    sc = copy.deepcopy(VALID)
    del sc["category"]
    errs = rg.validate_offline([sc])
    assert not any("not a recognized key in CATEGORY_TOKENS" in e for e in errs), errs


def test_non_mapping_scenario_entry_caught():
    assert any("is not a mapping" in e for e in rg.validate_offline(["not-a-dict"]))


# ---- codebase audit 2026-07-26: two schema-gate holes that let a broken fixture "vacuously pass" ----


def test_list_valued_expected_decision_caught():
    # A YAML mis-indent (`expected_decision:\n  - GO`) parses as a one-element list, not a string. The
    # old REQUIRED_FIELDS emptiness test (`val is None or (isinstance(val, str) and not val.strip())`)
    # satisfies neither branch for a list, so it silently passed; then _leading_token() blew up
    # unguarded in --live (AttributeError, kills the whole live job). Must be rejected here, by name and
    # actual type, before it ever reaches --live.
    sc = copy.deepcopy(VALID)
    sc["expected_decision"] = ["GO"]
    errs = rg.validate_offline([sc])
    assert any(
        "required field 'expected_decision' must be a string, got list" in e for e in errs
    )


def test_int_valued_expected_decision_caught():
    sc = copy.deepcopy(VALID)
    sc["expected_decision"] = 1
    errs = rg.validate_offline([sc])
    assert any(
        "required field 'expected_decision' must be a string, got int" in e for e in errs
    )


def test_non_string_required_field_does_not_crash_leading_token_downstream():
    # The actual failure mode this closes: unguarded, _leading_token(['GO']) raises AttributeError
    # (outside run_live's try/except, per the module docstring) and kills the entire --live job for
    # every scenario, not just the malformed one. Confirm validate_offline() now catches it BEFORE that
    # code path is ever reached (main() always runs the offline gate first — see its docstring/comment).
    sc = copy.deepcopy(VALID)
    sc["expected_decision"] = ["GO"]
    assert rg.validate_offline([sc]) != []


def test_governing_files_valid_list_is_not_flagged_by_the_string_check():
    # governing_files is the one REQUIRED_FIELDS member that is LEGITIMATELY a list, not a string — the
    # new non-string check must not regress the happy path (it has its own dedicated list validation a
    # few lines below in validate_offline()).
    assert rg.validate_offline([copy.deepcopy(VALID)]) == []


def test_prefix_typo_expected_decision_caught_offline():
    # 'CONTINUES'.startswith('CONTINUE'), 'TERMINATED'.startswith('TERMINATE'),
    # 'ACTIVATED'.startswith('ACTIVATE'), 'GOOF'.startswith('GO') — a bare str.startswith() let all four
    # of these prefix typos through the vocabulary check with zero errors. Each must now be flagged.
    for typo, category in [
        ("CONTINUES", "kill_trigger"),
        ("TERMINATED", "kill_trigger"),
        ("ACTIVATED", "regime_router"),
        ("GOOF", "strategy_b_entry"),
    ]:
        sc = copy.deepcopy(VALID)
        sc["category"] = category
        sc["expected_decision"] = typo
        errs = rg.validate_offline([sc])
        assert any("does not start with a recognized token" in e for e in errs), (typo, errs)


def test_prefix_typo_leading_token_returns_none_not_the_truncated_token():
    # The SAME boundary rule must apply in the --live grader (_leading_token), not just the offline
    # gate — otherwise a typo'd fixture that (somehow) slipped past validate_offline would still be
    # graded in --live as if it were the correctly-spelled token, and the gate/grader would disagree.
    for typo in ("CONTINUES", "TERMINATED", "ACTIVATED", "GOOF"):
        assert rg._leading_token(typo) is None, typo


def test_token_boundary_match_allows_the_documented_free_text_qualifier():
    # The fix must not break the documented "TOKEN (free text)" format — only a bare continuation of the
    # same word (no boundary) is rejected.
    assert rg._token_boundary_match("CONTINUE (ROUTES TO REVIEW)", "CONTINUE") is True
    assert rg._token_boundary_match("CONTINUE", "CONTINUE") is True
    assert rg._token_boundary_match("CONTINUES", "CONTINUE") is False
    assert rg._token_boundary_match("CONTINUE-ISH", "CONTINUE") is False


def test_token_boundary_match_accepts_ordinary_sentence_punctuation():
    """_leading_token() also grades a LIVE MODEL's free-text reply in run_live(), where a trailing '.'
    or ',' is completely normal ("DECISION: GO."). An earlier form of this boundary check allowed only
    {end, whitespace, '('}, which graded "GO." as UNPARSEABLE — turning a CORRECT model answer into a
    reported failure (adversarial review, codebase audit 2026-07-26). Punctuation is a boundary; only a
    word-continuation is not."""
    for text, expected in [
        ("GO.", "GO"), ("GO,", "GO"), ("GO:", "GO"), ("GO;", "GO"), ("GO!", "GO"),
        ("NO-GO.", "NO-GO"), ("TERMINATE.", "TERMINATE"), ("DO-NOT-ACTIVATE,", "DO-NOT-ACTIVATE"),
    ]:
        assert rg._leading_token(text) == expected, f"{text!r} should grade as {expected}"
    # ...and the typo class stays rejected, including a hyphen continuation (the vocabulary itself has
    # hyphenated tokens, so a trailing '-' may mean a longer compound token, not this one).
    for text in ("CONTINUES", "TERMINATED", "ACTIVATED", "GOOF", "GO-FORTH", "CONTINUE_NOW"):
        assert rg._leading_token(text) is None, f"{text!r} is a typo/compound and must not grade clean"


def test_leading_token_disambiguation():
    assert rg._leading_token("DO-NOT-ACTIVATE") == "DO-NOT-ACTIVATE"
    assert rg._leading_token("NO-GO") == "NO-GO"
    assert rg._leading_token("GO") == "GO"
    assert rg._leading_token("CONTINUE (routes to review)") == "CONTINUE"
    assert rg._leading_token(None) is None
    assert rg._leading_token("") is None


def test_category_tokens_cover_all_four_strategy_entry_categories():
    # The 2026-07-14 audit extension: A/D/E entry categories must be recognized, not just B.
    for cat in ("strategy_a_entry", "strategy_b_entry", "strategy_d_entry", "strategy_e_entry"):
        assert cat in rg.CATEGORY_TOKENS
        assert rg.CATEGORY_TOKENS[cat] == {"GO", "NO-GO"}


def test_category_tokens_cover_park_allocator_and_research_screener():
    # 2026-07-26 fix: PA-*/RS-* scenarios use GO/NO-GO as a proxy vocabulary (see scenarios.yaml's
    # VOCABULARY NOTE headers) but were missing a CATEGORY_TOKENS entry, so the live model was offered
    # all six DECISION_LEAD_TOKENS instead of just GO/NO-GO and could "flip" on pure vocabulary alone
    # (e.g. answering ACTIVATE instead of GO on a park_allocator scenario).
    for cat in ("park_allocator", "research_screener"):
        assert cat in rg.CATEGORY_TOKENS
        assert rg.CATEGORY_TOKENS[cat] == {"GO", "NO-GO"}


# ---- live-provider selection + Gemini ladder (2026-07-17) — all network-free ----


@contextlib.contextmanager
def _env(**overrides):
    """Temporarily set/unset env vars (None = unset), restoring the prior state afterward, so a real
    GEMINI_API_KEY/ANTHROPIC_API_KEY in the test runner's environment cannot leak into these unit tests."""
    saved = {k: os.environ.get(k) for k in overrides}
    try:
        for k, v in overrides.items():
            os.environ.pop(k, None) if v is None else os.environ.__setitem__(k, v)
        yield
    finally:
        for k, v in saved.items():
            os.environ.pop(k, None) if v is None else os.environ.__setitem__(k, v)


def test_allowed_decisions_scoped_by_category():
    # Each category offers ONLY its own tokens (so the model cannot answer a correct-sentiment but
    # wrong-vocabulary token, e.g. DO-NOT-ACTIVATE on a strategy-entry scenario).
    assert rg._allowed_decisions_for({"category": "strategy_b_entry"}) == "GO | NO-GO"
    assert rg._allowed_decisions_for({"category": "kill_trigger"}) == "CONTINUE | TERMINATE"
    assert rg._allowed_decisions_for({"category": "regime_router"}) == "ACTIVATE | DO-NOT-ACTIVATE"
    # park_allocator/research_screener also scope to GO | NO-GO (2026-07-26 fix) despite being a proxy
    # vocabulary rather than a native decision token — see scenarios.yaml's VOCABULARY NOTE headers.
    assert rg._allowed_decisions_for({"category": "park_allocator"}) == "GO | NO-GO"
    assert rg._allowed_decisions_for({"category": "research_screener"}) == "GO | NO-GO"
    # No / unknown category => all six, in the pinned longest-first-safe order.
    all_six = " | ".join(rg.DECISION_LEAD_TOKENS)
    assert rg._allowed_decisions_for({}) == all_six
    assert rg._allowed_decisions_for({"category": "nope"}) == all_six


def test_eval_prompt_renders_scoped_tokens():
    # The pinned template must actually consume {allowed_decisions} and exclude out-of-category tokens.
    p = rg.EVAL_PROMPT_TEMPLATE.format(governing_files_text="G", situation="S",
                                       allowed_decisions=rg._allowed_decisions_for({"category": "strategy_b_entry"}))
    assert "DECISION: <one of GO | NO-GO>" in p
    assert "DO-NOT-ACTIVATE" not in p and "TERMINATE" not in p


def test_gemini_model_ladder_wellformed():
    assert isinstance(rg.GEMINI_MODEL_LADDER, list) and rg.GEMINI_MODEL_LADDER
    assert all(isinstance(m, str) and m.strip() for m in rg.GEMINI_MODEL_LADDER)
    # Best-quality-first: the top of the ladder must be a full Flash model, not a *-lite (putting the
    # cheap 500/day lite reservoir first would waste the higher-quality daily quota).
    assert "lite" not in rg.GEMINI_MODEL_LADDER[0]


def test_select_live_caller_none_without_gemini_key():
    # Gemini is the sole provider (2026-07-17). No GEMINI_API_KEY => skip (None), even if a stray
    # ANTHROPIC_API_KEY is present (it must NOT enable anything anymore).
    with _env(GEMINI_API_KEY=None, ANTHROPIC_API_KEY="ignored"):
        assert rg._select_live_caller() is None


def test_select_live_caller_returns_gemini_when_key_set():
    # With GEMINI_API_KEY set, a callable is returned. Only assert callable — never invoke it (no
    # network in unit tests).
    with _env(GEMINI_API_KEY="test-key", ANTHROPIC_API_KEY=None):
        caller = rg._select_live_caller()
    assert callable(caller)


def _fake_http_error(url, code, body):
    return urllib.error.HTTPError(url, code, "err", {}, io.BytesIO(body))


class _FakeResp:
    def __init__(self, payload):
        self._payload = payload

    def read(self):
        return _json.dumps(self._payload).encode()

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False


# A realistic per-DAY 429 body (persistent => advance the ladder) and a per-MINUTE one (transient =>
# wait + retry the SAME model). Distinguishing these is the fix for the 2026-07-17 first-live-run bug
# where a per-minute limit burned the whole ladder in ~60s.
_QUOTA_DAY_BODY = (b'{"error":{"code":429,"status":"RESOURCE_EXHAUSTED","message":"Quota exceeded for '
                   b'metric GenerateRequestsPerDayPerProjectPerModel"}}')
_QUOTA_MIN_BODY = (b'{"error":{"code":429,"status":"RESOURCE_EXHAUSTED","message":"Quota exceeded for '
                   b'metric GenerateRequestsPerMinutePerProjectPerModel","details":[{"@type":'
                   b'"type.googleapis.com/google.rpc.RetryInfo","retryDelay":"7s"}]}}')
# Same per-MINUTE metric but with NO RetryInfo.retryDelay in the body — exercises the "falls back to the
# flat constant" half of _retry_delay_s()'s contract (2026-08-17 rewind-cooldown honoring test below).
_QUOTA_MIN_BODY_NO_DELAY = (b'{"error":{"code":429,"status":"RESOURCE_EXHAUSTED","message":"Quota exceeded '
                             b'for metric GenerateRequestsPerMinutePerProjectPerModel"}}')


def test_daily_vs_minute_quota_classification():
    assert rg._is_daily_quota_429(_QUOTA_DAY_BODY.decode()) is True
    assert rg._is_daily_quota_429(_QUOTA_MIN_BODY.decode()) is False
    assert rg._retry_delay_s(_QUOTA_MIN_BODY.decode(), 99) == 7.0   # honours the API's RetryInfo
    assert rg._retry_delay_s("{}", 99) == 99                        # falls back when absent


def test_gemini_ladder_advances_on_daily_quota_429(monkeypatch):
    # A per-DAY 429 is persistent: the pointer must advance and the SECOND model's reply is returned, and
    # the day-exhausted model must be added to the permanent-death set.
    ladder = ["model-a", "model-b", "model-c"]

    def fake_urlopen(req, timeout=180):
        if "model-a:" in req.full_url:
            raise _fake_http_error(req.full_url, 429, _QUOTA_DAY_BODY)
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: x"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(rg.time, "sleep", lambda s: None)  # must not be needed, but never really sleep
    state = {}
    text, model = rg._gemini_call("prompt", "k", ladder, state)
    assert "DECISION: GO" in text
    assert model == "model-b"
    assert state["dead"] == {"model-a"}  # permanently dead; model-b/model-c untouched


def test_gemini_minute_quota_429_retries_same_model(monkeypatch):
    # A per-MINUTE 429 is TRANSIENT: wait out RetryInfo and retry the SAME model — it must NOT burn a
    # ladder rung (this is the exact bug that killed 17 of 23 scenarios on the first live run).
    calls = {"n": 0}
    slept = []

    def fake_urlopen(req, timeout=180):
        calls["n"] += 1
        if calls["n"] == 1:
            raise _fake_http_error(req.full_url, 429, _QUOTA_MIN_BODY)
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: NO-GO\nRATIONALE: y"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(rg.time, "sleep", lambda s: slept.append(s))
    state = {}
    text, model = rg._gemini_call("prompt", "k", ["m1", "m2"], state)
    assert "NO-GO" in text
    assert model == "m1"                # stayed on the SAME (best) model
    assert state["dead"] == set()       # ladder rung NOT burned, nothing permanently dead
    assert slept == [7.0]               # honoured the API's suggested retryDelay


def test_gemini_minute_quota_429_gives_up_after_max_retries(monkeypatch):
    # Bounded: a model stuck at a per-minute limit is eventually abandoned FOR THIS CALL (ladder advances
    # within the call) rather than retrying forever — but 2026-08-17 fix: this must NOT be permanent. An
    # RPM-only exhaustion is a completely different failure class from a hard/day-quota one and must not
    # end up sticky like the old single `idx` cursor made it (that was the exact bug: live CI run
    # 32039658866 burned every rung on scenario 1's RPM limit and 32 of 33 scenarios never got attempted).
    slept = []

    def fake_urlopen(req, timeout=180):
        if "m1:" in req.full_url:
            raise _fake_http_error(req.full_url, 429, _QUOTA_MIN_BODY)
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: z"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(rg.time, "sleep", lambda s: slept.append(s))
    state = {}
    _text, model = rg._gemini_call("prompt", "k", ["m1", "m2"], state)
    assert model == "m2"
    assert state["dead"] == set()   # RPM-only exhaustion must NEVER land in the permanent-death set
    assert len(slept) == rg.GEMINI_RPM_MAX_RETRIES  # retried the cap, then moved on for this call only


def test_gemini_ladder_exhaustion_raises(monkeypatch):
    # Every model day-quota-exhausted -> _GeminiLadderPermanentlyDead (never a silent blank that would
    # score as a flip), and the message names EVERY model's failure, not just the last one. This IS the
    # genuinely-permanent case, so both models must land in state['dead'].
    def fake_urlopen(req, timeout=180):
        raise _fake_http_error(req.full_url, 429, _QUOTA_DAY_BODY)

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(rg.time, "sleep", lambda s: None)
    state = {}
    try:
        rg._gemini_call("prompt", "k", ["m1", "m2"], state)
        raise AssertionError("expected an exception on ladder exhaustion")
    except rg._GeminiLadderPermanentlyDead as exc:
        assert "ladder exhausted" in str(exc)
        assert "m1" in str(exc) and "m2" in str(exc)  # per-model diagnostics, not just the last error
        assert state["dead"] == {"m1", "m2"}


def test_gemini_empty_response_advances(monkeypatch):
    # A blank/blocked candidate that is NOT a MAX_TOKENS truncation (e.g. a safety block) is a HARD
    # failure — must advance the ladder AND land in state['dead'], not be scored as an empty decision and
    # not trigger a budget escalation.
    def fake_urlopen(req, timeout=180):
        if "m1:" in req.full_url:
            return _FakeResp({"candidates": [{"content": {"parts": [{"text": "   "}]}, "finishReason": "SAFETY"}]})
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: NO-GO\nRATIONALE: y"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    state = {}
    text, model = rg._gemini_call("prompt", "k", ["m1", "m2"], state)
    assert "NO-GO" in text and model == "m2"
    assert state["dead"] == {"m1"}


def _budget_of(req):
    return _json.loads(req.data.decode())["generationConfig"]["maxOutputTokens"]


def test_gemini_escalates_output_budget_on_truncation(monkeypatch):
    # A MAX_TOKENS truncation (reasoning ran past the budget) must DOUBLE maxOutputTokens and retry the
    # SAME model — not advance the ladder — until the answer fits.
    seen = []

    def fake_urlopen(req, timeout=180):
        budget = _budget_of(req)
        seen.append(budget)
        if budget <= rg.GEMINI_MAX_OUTPUT_TOKENS_START:  # first attempt truncates
            return _FakeResp({"candidates": [{"content": {"parts": []}, "finishReason": "MAX_TOKENS"}]})
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: x"}]},
                                          "finishReason": "STOP"}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    state = {}
    text, model = rg._gemini_call("prompt", "k", ["only-model"], state)
    assert "DECISION: GO" in text
    assert model == "only-model" and state["dead"] == set()     # stayed on the same model, never dead
    assert seen == [rg.GEMINI_MAX_OUTPUT_TOKENS_START, rg.GEMINI_MAX_OUTPUT_TOKENS_START * 2]  # doubled


def test_gemini_budget_escalation_is_bounded_then_advances(monkeypatch):
    # A model that truncates at EVERY budget must escalate only up to the ceiling (never unboundedly),
    # then advance the ladder to the next model — still-truncating-at-ceiling is a HARD failure, so m1
    # must land in state['dead'].
    seen_m1 = []

    def fake_urlopen(req, timeout=180):
        if "m1:" in req.full_url:
            seen_m1.append(_budget_of(req))
            return _FakeResp({"candidates": [{"content": {"parts": []}, "finishReason": "MAX_TOKENS"}]})
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: TERMINATE\nRATIONALE: z"}]},
                                          "finishReason": "STOP"}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    state = {}
    text, model = rg._gemini_call("prompt", "k", ["m1", "m2"], state)
    assert "TERMINATE" in text and model == "m2" and state["dead"] == {"m1"}
    # m1 escalated START, 2*START, ... , capped at CEIL (last value equals the ceiling; strictly increasing)
    assert seen_m1[0] == rg.GEMINI_MAX_OUTPUT_TOKENS_START
    assert seen_m1[-1] == rg.GEMINI_MAX_OUTPUT_TOKENS_CEIL
    assert max(seen_m1) == rg.GEMINI_MAX_OUTPUT_TOKENS_CEIL      # never exceeds the ceiling
    assert seen_m1 == sorted(seen_m1)                            # monotonically escalating


def test_gemini_budget_high_water_mark_persists_across_scenarios(monkeypatch):
    # Once one scenario escalates the budget, the NEXT scenario (sharing the same run `state`) must START
    # at the discovered budget — not re-truncate its way back up from _START each time.
    seen = []

    def fake_urlopen(req, timeout=180):
        budget = _budget_of(req)
        seen.append(budget)
        if budget <= rg.GEMINI_MAX_OUTPUT_TOKENS_START:  # only the smallest budget truncates
            return _FakeResp({"candidates": [{"content": {"parts": []}, "finishReason": "MAX_TOKENS"}]})
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: x"}]},
                                          "finishReason": "STOP"}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    state = {}  # no explicit budget/dead => _gemini_call seeds them via setdefault
    rg._gemini_call("scenario-1", "k", ["m"], state)     # truncates at _START, escalates to 2*_START
    assert state["budget"] == rg.GEMINI_MAX_OUTPUT_TOKENS_START * 2
    seen.clear()
    rg._gemini_call("scenario-2", "k", ["m"], state)     # must reuse the mark: ONE call, no re-truncation
    assert seen == [rg.GEMINI_MAX_OUTPUT_TOKENS_START * 2]


# ---- 2026-08-17 fix: RPM-only exhaustion is NOT sticky across scenarios; hard failures ARE; the whole
# ladder rewinds (bounded) on an all-transient exhaustion within one call; requests are paced; and the
# whole run is bounded by a wall-clock budget that degrades to a reported partial result rather than
# hanging or silently producing nothing. See the doctrine comment above GEMINI_LADDER_REWINDS in
# run_golden.py for the full narrative (live CI run 32039658866: 33 scenarios scoped, 1 attempted, 32
# silently short-circuited).


def test_gemini_rpm_exhausted_model_is_retried_by_a_later_scenario(monkeypatch):
    # THE core regression test: m1 RPM-exhausts on scenario 1 (m2 picks up the slack); scenario 2's call
    # — sharing the same run `state` — must try m1 again FRESH, proving RPM-only exhaustion is not sticky.
    calls_m1 = {"n": 0}

    def fake_urlopen(req, timeout=180):
        if "m1:" in req.full_url:
            calls_m1["n"] += 1
            raise _fake_http_error(req.full_url, 429, _QUOTA_MIN_BODY)
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: x"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(rg.time, "sleep", lambda s: None)
    state = {}
    ladder = ["m1", "m2"]

    _text1, model1 = rg._gemini_call("scenario-1", "k", ladder, state)
    assert model1 == "m2"
    assert "m1" not in state["dead"]          # RPM-only -- must NOT be permanently dead
    n_after_first = calls_m1["n"]
    assert n_after_first == rg.GEMINI_RPM_MAX_RETRIES + 1   # 1 initial attempt + the retries

    _text2, model2 = rg._gemini_call("scenario-2", "k", ladder, state)
    assert model2 == "m2"
    assert calls_m1["n"] > n_after_first      # m1 was attempted again (fresh) on scenario 2


def test_gemini_hard_failure_is_permanently_dead_across_scenarios(monkeypatch):
    # The other half of the same fix: a genuinely HARD failure (404 here) must stay dead for scenario 2 —
    # never re-attempted, unlike the RPM case above.
    seen_urls = []

    def fake_urlopen(req, timeout=180):
        seen_urls.append(req.full_url)
        if "m1:" in req.full_url:
            raise _fake_http_error(req.full_url, 404, b'{"error":{"message":"model not found"}}')
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: x"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(rg.time, "sleep", lambda s: None)
    state = {}
    ladder = ["m1", "m2"]

    _text1, model1 = rg._gemini_call("scenario-1", "k", ladder, state)
    assert model1 == "m2"
    assert state["dead"] == {"m1"}

    seen_urls.clear()
    _text2, model2 = rg._gemini_call("scenario-2", "k", ladder, state)
    assert model2 == "m2"
    assert not any("m1:" in u for u in seen_urls)   # m1 never even attempted -- permanently dead


def test_rewind_exhaustion_on_one_scenario_does_not_block_the_next(monkeypatch):
    # Per-scenario independence (owner directive 2026-08-17): even a scenario that exhausts ALL of its
    # ladder rewinds (a per-SCENARIO RuntimeError, not a whole-run stop signal) must leave state['dead']
    # untouched, so the very next scenario gets a completely fresh attempt.
    monkeypatch.setattr(rg, "GEMINI_LADDER_REWINDS", 1)
    state = {}

    def always_rpm_429(req, timeout=180):
        raise _fake_http_error(req.full_url, 429, _QUOTA_MIN_BODY)

    monkeypatch.setattr(urllib.request, "urlopen", always_rpm_429)
    monkeypatch.setattr(rg.time, "sleep", lambda s: None)

    try:
        rg._gemini_call("scenario-1", "k", ["m1"], state)
        raise AssertionError("expected a plain RuntimeError (rewinds exhausted)")
    except rg._GeminiLadderPermanentlyDead as exc:
        raise AssertionError(
            "an all-RPM exhaustion must NOT raise the whole-run permanent-death signal"
        ) from exc
    except RuntimeError:
        pass
    assert state["dead"] == set()   # nothing permanently dead

    def now_succeeds(req, timeout=180):
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: x"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", now_succeeds)
    text, model = rg._gemini_call("scenario-2", "k", ["m1"], state)  # fresh attempt, succeeds immediately
    assert "DECISION: GO" in text and model == "m1"


def test_gemini_ladder_rewind_bounded_then_raises(monkeypatch):
    # Every rung RPM-exhausts on EVERY pass (never succeeds) -- the ladder must rewind exactly
    # GEMINI_LADDER_REWINDS times (bounded — this IS the fix: unbounded waiting would never finish) then
    # raise a per-SCENARIO RuntimeError, never the whole-run _GeminiLadderPermanentlyDead signal (these
    # are all transient RPM failures; nothing may go into state['dead']).
    monkeypatch.setattr(rg, "GEMINI_LADDER_REWINDS", 2)
    ladder = ["m1", "m2"]

    def fake_urlopen(req, timeout=180):
        raise _fake_http_error(req.full_url, 429, _QUOTA_MIN_BODY)

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    slept = []
    monkeypatch.setattr(rg.time, "sleep", lambda s: slept.append(s))
    state = {}

    try:
        rg._gemini_call("prompt", "k", ladder, state)
        raise AssertionError("expected RuntimeError")
    except rg._GeminiLadderPermanentlyDead as exc:
        raise AssertionError("RPM-only exhaustion must not raise the permanent/whole-run signal") from exc
    except RuntimeError as exc:
        assert state["dead"] == set()
        assert "2 rewind" in str(exc)

    # 3 passes (initial + 2 rewinds) x 2 models x GEMINI_RPM_MAX_RETRIES RPM-retry sleeps, plus one
    # cooldown sleep after each of the first 2 passes (none after the final, raising pass).
    expected_sleeps = 3 * len(ladder) * rg.GEMINI_RPM_MAX_RETRIES + 2
    assert len(slept) == expected_sleeps


def test_gemini_ladder_rewinds_default_is_six():
    # Owner amendment 2026-08-17 ("i can wait ... it can wait and auto retry and eventually complete")
    # raised the default from 2 to 6 rewinds.
    assert rg.GEMINI_LADDER_REWINDS == 6


def test_ladder_rewind_cooldown_honors_retry_delay_from_body(monkeypatch):
    # The rewind cooldown must use the failing request's own RetryInfo.retryDelay (7.0, from
    # _QUOTA_MIN_BODY) when present, NOT the flat GEMINI_LADDER_REWIND_COOLDOWN_S constant.
    monkeypatch.setattr(rg, "GEMINI_LADDER_REWINDS", 2)
    monkeypatch.setattr(rg, "GEMINI_LADDER_REWIND_COOLDOWN_S", 999.0)  # obviously wrong if this is used
    ladder = ["m1", "m2"]
    threshold = len(ladder) * (rg.GEMINI_RPM_MAX_RETRIES + 1)  # calls needed to RPM-exhaust pass 1 fully
    calls = {"n": 0}

    def fake_urlopen(req, timeout=180):
        calls["n"] += 1
        if calls["n"] <= threshold:
            raise _fake_http_error(req.full_url, 429, _QUOTA_MIN_BODY)
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: x"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    slept = []
    monkeypatch.setattr(rg.time, "sleep", lambda s: slept.append(s))
    state = {}

    text, model = rg._gemini_call("prompt", "k", ladder, state)
    assert "DECISION: GO" in text and model == "m1"   # rewound to the top; m1 succeeds fresh
    assert 999.0 not in slept                          # the flat constant was never used
    assert 7.0 in slept                                 # the body's own retryDelay was honoured


def test_ladder_rewind_cooldown_falls_back_to_constant_without_retry_info(monkeypatch):
    # When the 429 body carries NO RetryInfo, the rewind cooldown must fall back to the flat
    # GEMINI_LADDER_REWIND_COOLDOWN_S constant (same fallback _retry_delay_s already does for RPM retries).
    monkeypatch.setattr(rg, "GEMINI_LADDER_REWINDS", 1)
    monkeypatch.setattr(rg, "GEMINI_LADDER_REWIND_COOLDOWN_S", 42.0)
    ladder = ["only-model"]
    threshold = rg.GEMINI_RPM_MAX_RETRIES + 1
    calls = {"n": 0}

    def fake_urlopen(req, timeout=180):
        calls["n"] += 1
        if calls["n"] <= threshold:
            raise _fake_http_error(req.full_url, 429, _QUOTA_MIN_BODY_NO_DELAY)
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: x"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    slept = []
    monkeypatch.setattr(rg.time, "sleep", lambda s: slept.append(s))
    state = {}

    text, model = rg._gemini_call("prompt", "k", ladder, state)
    assert "DECISION: GO" in text and model == "only-model"
    assert 42.0 in slept   # fell back to the flat constant (body had no RetryInfo)


def test_pace_sleeps_only_the_remaining_interval(monkeypatch):
    # Pacing must be measured from the ACTUAL last request, never a flat sleep: only 5s elapsed since the
    # last call, interval is 13s, so it must sleep exactly the shortfall (8s), not the full interval.
    # Explicitly re-enables a real interval (the module-wide autouse fixture zeroes it by default).
    monkeypatch.setattr(rg, "GEMINI_MIN_CALL_INTERVAL_S", 13.0)
    monkeypatch.setattr(rg.time, "monotonic", lambda: 105.0)
    slept = []
    monkeypatch.setattr(rg.time, "sleep", lambda s: slept.append(s))
    state = {"last_call_ts": 100.0}
    rg._pace(state)
    assert slept == [8.0]
    assert state["last_call_ts"] == 105.0


def test_pace_does_not_sleep_when_interval_already_elapsed(monkeypatch):
    monkeypatch.setattr(rg, "GEMINI_MIN_CALL_INTERVAL_S", 13.0)
    monkeypatch.setattr(rg.time, "monotonic", lambda: 200.0)
    slept = []
    monkeypatch.setattr(rg.time, "sleep", lambda s: slept.append(s))
    state = {"last_call_ts": 100.0}  # 100s elapsed, well past the 13s interval
    rg._pace(state)
    assert slept == []
    assert state["last_call_ts"] == 200.0


def test_pace_is_a_noop_on_the_first_call_of_a_run(monkeypatch):
    monkeypatch.setattr(rg, "GEMINI_MIN_CALL_INTERVAL_S", 13.0)
    monkeypatch.setattr(rg.time, "monotonic", lambda: 50.0)
    slept = []
    monkeypatch.setattr(rg.time, "sleep", lambda s: slept.append(s))
    state = {}   # no last_call_ts yet
    rg._pace(state)
    assert slept == []
    assert state["last_call_ts"] == 50.0


def test_check_run_budget_noop_without_run_start_ts():
    rg._check_run_budget({})  # no run_start_ts key -> no-op, must not raise


def test_check_run_budget_raises_when_spent(monkeypatch):
    monkeypatch.setattr(rg, "GEMINI_RUN_BUDGET_S", 100.0)
    monkeypatch.setattr(rg.time, "monotonic", lambda: 250.0)
    rg._check_run_budget({"run_start_ts": 200.0})   # 50s elapsed < 100s budget -> must not raise
    try:
        rg._check_run_budget({"run_start_ts": 100.0})   # 150s elapsed >= 100s budget -> raises
        raise AssertionError("expected _GeminiRunBudgetExhausted")
    except rg._GeminiRunBudgetExhausted:
        pass


def test_check_run_budget_never_starts_a_sleep_that_would_overrun(monkeypatch):
    # "Check the budget before sleeping too — never start a sleep that would overrun it."
    monkeypatch.setattr(rg, "GEMINI_RUN_BUDGET_S", 100.0)
    monkeypatch.setattr(rg.time, "monotonic", lambda: 195.0)
    state = {"run_start_ts": 100.0}   # 95s elapsed, 5s of budget left
    rg._check_run_budget(state, extra_s=4.0)   # 95+4=99 < 100 -> fine, no raise
    try:
        rg._check_run_budget(state, extra_s=10.0)   # 95+10=105 >= 100 -> would overrun -> raise BEFORE sleeping
        raise AssertionError("expected _GeminiRunBudgetExhausted")
    except rg._GeminiRunBudgetExhausted:
        pass


def test_gemini_call_raises_budget_exhausted_before_any_network_call(monkeypatch):
    # Once the run budget is already spent, _gemini_call must not even attempt a request.
    def fake_urlopen(req, timeout=180):
        raise AssertionError("must not attempt a network call once the run budget is already spent")

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(rg, "GEMINI_RUN_BUDGET_S", 100.0)
    monkeypatch.setattr(rg.time, "monotonic", lambda: 500.0)
    state = {"run_start_ts": 0.0}
    try:
        rg._gemini_call("prompt", "k", ["m1"], state)
        raise AssertionError("expected _GeminiRunBudgetExhausted")
    except rg._GeminiRunBudgetExhausted:
        pass


# ---- run_live() end-to-end grading (the core of --live mode) — all network-free ----
# run_live composes already-tested helpers, but its OWN logic had zero direct coverage: the DECISION-line
# scan (must find a non-first, case-insensitive line), the split/reply.strip() fallback, match-vs-flip
# token grading, the call-failed -> match=None error class main() counts, the scenario_ids filter, and the
# flip branch that PRINTS the ::warning:: annotation + the SPEC-ONLY QUEUE_INSERT advisory. These drive a
# fake Gemini caller (no network) and assert only on run_live's returned dicts + its printed strings — no
# BigQuery write is wired (the queue INSERT is a print-only advisory by design; see the module docstring).


def _sc(sid, expected, category="strategy_b_entry"):
    # A minimal valid scenario whose single governing_file exists on disk (run_live really reads it).
    return {"id": sid, "category": category, "situation": "synthetic",
            "governing_files": ["Strategy.md"], "expected_decision": expected, "rationale": "r"}


def _fake_caller_returning(*replies):
    """Return a drop-in _select_live_caller() whose call_model yields `replies` in call order. A reply
    that is an Exception instance is RAISED (to exercise run_live's error path); any other value is
    returned as (reply, 'fake-model-1'). run_live looks up _select_live_caller as a module global at call
    time, so monkeypatching rg._select_live_caller to this is sufficient — no real Gemini/network."""
    queue = list(replies)

    def select():
        def call_model(prompt):
            item = queue.pop(0)
            if isinstance(item, Exception):
                raise item
            return item, "fake-model-1"
        return call_model
    return select


def test_run_live_scores_a_match_and_prints_no_flip_or_queue_insert(monkeypatch, capsys):
    monkeypatch.setattr(rg, "_select_live_caller", _fake_caller_returning("DECISION: GO\nRATIONALE: because"))
    results = rg.run_live([_sc("T-MATCH", "GO")])
    assert len(results) == 1
    r = results[0]
    assert r["match"] is True and r["actual"] == "GO" and r["model"] == "fake-model-1"
    out = capsys.readouterr().out
    assert "decision flip" not in out and "INSERT INTO" not in out


def test_run_live_finds_a_decision_line_after_preamble_case_insensitively(monkeypatch):
    # The next() scan must find a DECISION line that is NOT first, matched case-insensitively.
    reply = "Here is my reasoning first.\ndecision: CONTINUE (routes to review)\nRATIONALE: x"
    monkeypatch.setattr(rg, "_select_live_caller", _fake_caller_returning(reply))
    r = rg.run_live([_sc("T-PRE", "CONTINUE", category="kill_trigger")])[0]
    assert r["match"] is True
    assert r["actual"] == "CONTINUE (routes to review)"


def test_run_live_flags_a_flip_and_prints_the_advisory_queue_insert(monkeypatch, capsys):
    monkeypatch.setattr(rg, "_select_live_caller", _fake_caller_returning("DECISION: NO-GO\nRATIONALE: nope"))
    r = rg.run_live([_sc("T-FLIP", "GO")])[0]
    assert r["match"] is False and r["actual"] == "NO-GO"
    out = capsys.readouterr().out
    # A flip prints a GitHub Actions annotation AND the spec-only advisory INSERT (a print-only string;
    # never executed — the runner has no BigQuery credentials, per the golden non-issue). Assert the
    # STRING only; no write is performed.
    assert "::warning file=tests/golden_scenarios/scenarios.yaml::T-FLIP decision flip" in out
    assert "INSERT INTO" in out and "prose-regression" in out and "T-FLIP" in out


def test_run_live_scores_unparseable_when_reply_has_no_recognized_token(monkeypatch, capsys):
    # 2026-07-26 fix: a reply that ignores the "<one of ...>" instruction and answers with a token
    # outside DECISION_LEAD_TOKENS entirely (e.g. the model inventing "SCREEN") is a format-following
    # failure, not a decision disagreement — it must NOT be scored as a FLIP (match=False) or file the
    # advisory queue_events INSERT, since there is no real expected-vs-actual call to adjudicate.
    monkeypatch.setattr(rg, "_select_live_caller", _fake_caller_returning("DECISION: SCREEN\nRATIONALE: x"))
    r = rg.run_live([_sc("T-UNPARSE", "GO")])[0]
    assert r["match"] == "UNPARSEABLE" and r["actual"] == "SCREEN"
    out = capsys.readouterr().out
    assert "T-UNPARSE decision flip" not in out and "INSERT INTO" not in out
    assert "::warning::T-UNPARSE: model reply had no recognized decision token" in out


def test_run_live_records_an_error_class_when_the_model_call_raises(monkeypatch, capsys):
    monkeypatch.setattr(rg, "_select_live_caller", _fake_caller_returning(RuntimeError("ladder exhausted")))
    r = rg.run_live([_sc("T-ERR", "GO")])[0]
    # The except branch records match=None (the ERROR class main() counts), not a scored flip.
    assert r["match"] is None and r["actual"] is None and r["model"] is None
    assert "ladder exhausted" in r["reply"]
    assert "model call failed" in capsys.readouterr().err


def test_run_live_survives_one_scenarios_unreadable_governing_file(monkeypatch):
    # 2026-07-29 bug hunt: the governing_files read loop used to sit OUTSIDE run_live's per-scenario
    # try/except, so an unreadable/missing governing_file on scenario N raised an uncaught OSError that
    # propagated straight out of run_live() -- aborting the WHOLE batch and losing every scenario after
    # it, not just the bad one. Put the bad scenario FIRST and a good one SECOND: pre-fix, run_live()
    # itself raises FileNotFoundError before ever returning (T-GOOD never evaluated); post-fix, T-BAD's
    # failure is recorded as a per-scenario error (matching the model-call-raises error class) and T-GOOD
    # is still evaluated and scored normally. Only ONE reply is queued -- if the bug ever regressed to
    # calling call_model for T-BAD too, this would fail with an IndexError (queue underflow) instead of
    # silently passing.
    bad = _sc("T-BAD-GOVFILE", "GO")
    bad["governing_files"] = ["Strategy_Does_Not_Exist_2026_07_29.md"]
    good = _sc("T-GOOD-AFTER-BAD", "GO")
    monkeypatch.setattr(rg, "_select_live_caller", _fake_caller_returning("DECISION: GO\nRATIONALE: ok"))

    results = rg.run_live([bad, good])

    ids = [r["id"] for r in results]
    assert ids == ["T-BAD-GOVFILE", "T-GOOD-AFTER-BAD"], (
        f"a scenario after one with an unreadable governing_file was lost: {ids}"
    )
    bad_result = next(r for r in results if r["id"] == "T-BAD-GOVFILE")
    assert bad_result["match"] is None  # per-scenario error class, not a raised exception
    good_result = next(r for r in results if r["id"] == "T-GOOD-AFTER-BAD")
    assert good_result["match"] is True and good_result["actual"] == "GO"


def test_run_live_respects_the_scenario_ids_filter(monkeypatch):
    scs = [_sc("T-A", "GO"), _sc("T-B", "GO")]
    # Only ONE reply queued: if the filter leaked and evaluated T-A too, call_model would pop from empty.
    monkeypatch.setattr(rg, "_select_live_caller", _fake_caller_returning("DECISION: GO\nRATIONALE: x"))
    results = rg.run_live(scs, scenario_ids=["T-B"])
    assert [r["id"] for r in results] == ["T-B"]


def test_run_live_bare_token_without_decision_prefix_uses_the_reply_fallback(monkeypatch):
    # No 'DECISION:' line and no colon -> actual_decision = reply.strip() (the else fallback).
    monkeypatch.setattr(rg, "_select_live_caller", _fake_caller_returning("GO"))
    r = rg.run_live([_sc("T-BARE", "GO")])[0]
    assert r["match"] is True and r["actual"] == "GO"


# ---- 2026-08-17: run_live() stops early on a whole-run signal (_GeminiRunBudgetExhausted /
# _GeminiLadderPermanentlyDead) and reports every remaining scenario as SKIPPED with a reason -- "never a
# silent nothing." An ordinary per-scenario RuntimeError (already covered above by
# test_run_live_records_an_error_class_when_the_model_call_raises) must NOT trigger this — only the two
# specific whole-run signal classes do.


def test_run_live_stops_and_skips_remaining_scenarios_on_run_budget_exhaustion(monkeypatch, capsys):
    exc = rg._GeminiRunBudgetExhausted(
        "Gemini run wall-clock budget (GEMINI_RUN_BUDGET_S=3000s) exhausted after 3001s elapsed — "
        "stopping further live attempts this run."
    )
    monkeypatch.setattr(rg, "_select_live_caller",
                         _fake_caller_returning("DECISION: GO\nRATIONALE: ok", exc))
    scs = [_sc("T-A", "GO"), _sc("T-B", "GO"), _sc("T-C", "GO")]

    results = rg.run_live(scs)

    assert [r["id"] for r in results] == ["T-A", "T-B", "T-C"]
    a, b, c = results
    assert a["match"] is True and a["actual"] == "GO"
    # T-B triggered the exhaustion; T-C was never even attempted (only 2 replies were queued above, so if
    # run_live tried to call_model for T-C too this test would fail with an IndexError first).
    assert b["match"] == "SKIPPED" and "budget" in b["reply"].lower()
    assert c["match"] == "SKIPPED" and c["actual"] is None and c["model"] is None
    assert c["reply"] == b["reply"]   # same reason propagated to every skipped scenario
    err = capsys.readouterr().err
    assert "T-B" in err and "stopping further live attempts" in err


def test_run_live_stops_and_skips_remaining_scenarios_on_ladder_permanently_dead(monkeypatch, capsys):
    exc = rg._GeminiLadderPermanentlyDead("Gemini model ladder exhausted — m1: HTTP 404 | m2: HTTP 404")
    monkeypatch.setattr(rg, "_select_live_caller", _fake_caller_returning(exc))
    scs = [_sc("T-ONLY", "GO"), _sc("T-NEVER-ATTEMPTED", "GO")]

    results = rg.run_live(scs)

    assert [r["id"] for r in results] == ["T-ONLY", "T-NEVER-ATTEMPTED"]
    assert all(r["match"] == "SKIPPED" for r in results)
    assert all("ladder exhausted" in r["reply"] for r in results)


def test_run_live_a_plain_runtime_error_does_not_trigger_the_skip_path(monkeypatch, capsys):
    # A per-scenario RuntimeError (e.g. rewinds exhausted for just this one scenario) is NOT one of the
    # two whole-run stop signals -- it must fall through to the ordinary error class and let the loop
    # continue trying later scenarios normally (both replies below get consumed).
    monkeypatch.setattr(
        rg, "_select_live_caller",
        _fake_caller_returning(RuntimeError("ladder exhausted for this scenario — rewinds spent"),
                                "DECISION: GO\nRATIONALE: ok"),
    )
    results = rg.run_live([_sc("T-A", "GO"), _sc("T-B", "GO")])
    assert [r["match"] for r in results] == [None, True]   # T-A errored, T-B still attempted and matched


# ---- scenarios_for_changed_files() — CI cost-scoping selection function (2026-07-30). golden-scenarios.
# yml used to re-run ALL scenarios' live model calls on every triggering push, regardless of which ONE
# governing file actually changed (measured ~2,251 billable CI min/month — the single largest line item
# in the repo's Actions bill). This function maps a push's changed files to just the scenario ids they
# govern, so the workflow's `--live` step can pass a `--scenario` filter (or skip the whole step when the
# result is empty) instead of always evaluating all 31. FAIL-OPEN ("select every scenario") on an
# unscoped/unknown input is the entire correctness contract here — a false NARROW selection could hide a
# real prose regression from the (already advisory-only) live check; see HARD CONSTRAINT 3 in the task
# that produced this and scripts/resolve_diff_base.sh's identical fail-open posture for the diff-base
# resolution the workflow itself performs before calling this function.


def test_scenarios_for_changed_selects_exactly_the_strategy_md_scenarios():
    # Ground-truthed against the REAL scenarios.yaml (not a synthetic fixture) so this test would catch a
    # regression in the real coverage, not just in the selection logic against toy data.
    scenarios = rg.load_scenarios()
    strategy_scenario_ids = {sc["id"] for sc in scenarios if "Strategy.md" in (sc.get("governing_files") or [])}
    assert len(strategy_scenario_ids) == 17  # scenarios.yaml's own header: Strategy.md governs 17/31
    assert set(rg.scenarios_for_changed_files(scenarios, ["Strategy.md"])) == strategy_scenario_ids


def test_scenarios_for_changed_unions_two_files():
    scs = [
        {"id": "A", "governing_files": ["Strategy.md"]},
        {"id": "B", "governing_files": ["Operating_Protocols.md"]},
        {"id": "C", "governing_files": ["Claude_Task_Plan.md"]},
        {"id": "D", "governing_files": ["Strategy.md", "Operating_Protocols.md"]},
    ]
    result = rg.scenarios_for_changed_files(scs, ["Strategy.md", "Operating_Protocols.md"])
    assert result == ["A", "B", "D"]  # sorted union, C (unrelated) excluded


def test_scenarios_for_changed_unknown_file_selects_none():
    scs = [
        {"id": "A", "governing_files": ["Strategy.md"]},
        {"id": "B", "governing_files": ["Operating_Protocols.md"]},
    ]
    # README.md is a real repo-relative path that governs no scenario and is not under the harness's own
    # directory — the "true zero" case that is the entire point of the narrowing (skip the live step).
    assert rg.scenarios_for_changed_files(scs, ["README.md"]) == []


def test_scenarios_for_changed_mixed_known_and_unknown_files_selects_only_known():
    scs = [
        {"id": "A", "governing_files": ["Strategy.md"]},
        {"id": "B", "governing_files": ["Operating_Protocols.md"]},
    ]
    assert rg.scenarios_for_changed_files(scs, ["Strategy.md", "unrelated/file.py"]) == ["A"]


def test_scenarios_for_changed_empty_or_none_selects_all_fail_open():
    scs = [
        {"id": "A", "governing_files": ["Strategy.md"]},
        {"id": "B", "governing_files": ["Operating_Protocols.md"]},
    ]
    assert rg.scenarios_for_changed_files(scs, []) == ["A", "B"]
    assert rg.scenarios_for_changed_files(scs, None) == ["A", "B"]


def test_scenarios_for_changed_harness_self_change_fails_open_to_all():
    scs = [
        {"id": "A", "governing_files": ["Strategy.md"]},
        {"id": "B", "governing_files": ["Operating_Protocols.md"]},
    ]
    # A change to scenarios.yaml (pinned expectations) or run_golden.py (grading logic) itself is not
    # something any scenario's governing_files list points at (that would be self-referential) -- the
    # governing_files intersection alone is structurally blind to it, so it must fail OPEN to every
    # scenario rather than silently select nothing just because nothing in `scs` names that path.
    assert rg.scenarios_for_changed_files(scs, ["tests/golden_scenarios/scenarios.yaml"]) == ["A", "B"]
    assert rg.scenarios_for_changed_files(scs, ["tests/golden_scenarios/run_golden.py"]) == ["A", "B"]
    # Mixed with an otherwise-narrowing file: the harness-self file still forces the wide (all) answer.
    assert rg.scenarios_for_changed_files(scs, ["Strategy.md", "tests/golden_scenarios/scenarios.yaml"]) == ["A", "B"]


def test_scenarios_for_changed_skips_non_dict_and_idless_entries():
    scs = ["not-a-dict", {"governing_files": ["Strategy.md"]}, {"id": "A", "governing_files": ["Strategy.md"]}]
    assert rg.scenarios_for_changed_files(scs, ["Strategy.md"]) == ["A"]
    assert rg.scenarios_for_changed_files(scs, None) == ["A"]


def test_scenarios_for_changed_every_returned_id_exists_in_scenarios_yaml():
    # Cross-check against the real fixture file for a range of inputs, including the two fail-open paths
    # — a returned id that doesn't actually exist in scenarios.yaml would make the workflow's downstream
    # `--scenario <id>` call a silent no-op for that id (run_golden.py's own --scenario handling only
    # warns on an unknown id, it doesn't fail the build).
    scenarios = rg.load_scenarios()
    known_ids = {sc["id"] for sc in scenarios}
    for changed in (
        ["Strategy.md"], ["Operating_Protocols.md"], ["Claude_Task_Plan.md"], ["Experiment_Parameters.md"],
        None, [], ["nonexistent/file.md"], ["tests/golden_scenarios/scenarios.yaml"],
    ):
        for sid in rg.scenarios_for_changed_files(scenarios, changed):
            assert sid in known_ids


def test_main_scenarios_for_changed_prints_ids_and_returns_0(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--scenarios-for-changed", "--changed-file", "Strategy.md"])
    assert rg.main() == 0
    out_lines = capsys.readouterr().out.strip().splitlines()
    assert len(out_lines) == 17
    assert set(out_lines) <= {sc["id"] for sc in rg.load_scenarios()}


def test_main_scenarios_for_changed_with_no_changed_file_prints_all(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--scenarios-for-changed"])
    assert rg.main() == 0
    out_lines = capsys.readouterr().out.strip().splitlines()
    assert len(out_lines) == len(rg.load_scenarios())


def test_main_scenarios_for_changed_does_not_run_offline_validation_banner(monkeypatch, capsys):
    # Utility mode must short-circuit before validate_offline()'s own print — it is not the schema gate.
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--scenarios-for-changed", "--changed-file", "Strategy.md"])
    assert rg.main() == 0
    assert "OK —" not in capsys.readouterr().out


# ---- main() — the actual CLI entry point / CI hard-gate contract — previously never invoked by any
# test here, even though every helper it calls (above) is meticulously unit-tested in isolation. These
# monkeypatch sys.argv (matching the convention already used by test_check_live_sql_parity.py et al. in
# this repo) rather than subprocess, so module internals can be patched too.


def test_main_offline_returns_0_on_real_scenarios(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--offline"])
    assert rg.main() == 0
    assert "OK —" in capsys.readouterr().out


def test_main_returns_1_and_prints_fatal_on_load_error(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--offline"])
    monkeypatch.setattr(rg, "load_scenarios", lambda: (_ for _ in ()).throw(ValueError("boom")))
    assert rg.main() == 1
    assert "FATAL" in capsys.readouterr().err


def test_main_returns_1_on_offline_validation_errors(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--offline"])
    monkeypatch.setattr(rg, "validate_offline", lambda scenarios: ["fake error"])
    assert rg.main() == 1
    assert "FAIL" in capsys.readouterr().err


def test_main_live_returns_0_when_no_provider_configured(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--live"])
    monkeypatch.setattr(rg, "_select_live_caller", lambda: None)
    assert rg.main() == 0


def test_main_live_prints_summary_counts_and_per_row_labels(monkeypatch, capsys):
    # Drive the aggregation/print path directly, bypassing run_live()'s own internals (already covered by
    # the test_run_live_* tests above) — main() must count and label a mixed match/flip/error/unparseable/
    # skipped results list correctly, since this print IS what a human triaging a live CI run actually
    # reads (module docstring: advisory, continue-on-error). Includes a SKIPPED row (2026-08-17 — "never a
    # silent nothing": a partial result must be reported, with a reason, never silently dropped).
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--live"])
    mixed_results = [
        {"id": "A", "expected": "GO", "actual": "GO", "match": True, "reply": "r", "model": "m"},
        {"id": "B", "expected": "GO", "actual": "NO-GO", "match": False, "reply": "r", "model": "m"},
        {"id": "C", "expected": "GO", "actual": None, "match": None, "reply": "boom", "model": None},
        {"id": "D", "expected": "GO", "actual": "SCREEN", "match": "UNPARSEABLE", "reply": "r", "model": "m"},
        {"id": "E", "expected": "GO", "actual": None, "match": "SKIPPED", "reply": "run budget exhausted",
         "model": None},
    ]
    monkeypatch.setattr(rg, "run_live", lambda scenarios, scenario_ids=None: mixed_results)
    assert rg.main() == 0
    out = capsys.readouterr().out
    assert "Live results: 1 match, 1 flip(s), 1 unparseable, 1 error(s), 1 skipped (4 evaluated) out of 5." in out
    assert "[MATCH] A: expected='GO' actual='GO'" in out
    assert "[FLIP] B: expected='GO' actual='NO-GO'" in out
    assert "[ERROR] C: expected='GO' actual=None" in out
    assert "[UNPARSEABLE] D: expected='GO' actual='SCREEN'" in out
    assert "[SKIPPED] E: expected='GO' actual=None" in out
    assert "::warning::golden live run: 1 scenario(s) SKIPPED" in out
    assert "run budget exhausted" in out


def test_main_live_prints_notice_when_nothing_skipped(monkeypatch, capsys):
    # The complementary "never a silent nothing" case: when NOTHING was skipped, still emit an explicit
    # ::notice:: saying so (not just silence) — a human triaging the run should never have to infer full
    # coverage from the absence of a warning.
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--live"])
    results = [{"id": "A", "expected": "GO", "actual": "GO", "match": True, "reply": "r", "model": "m"}]
    monkeypatch.setattr(rg, "run_live", lambda scenarios, scenario_ids=None: results)
    assert rg.main() == 0
    out = capsys.readouterr().out
    assert "::notice::golden live run: all 1 scenario(s) considered were evaluated (0 skipped)." in out
    assert "::warning::golden live run:" not in out


def test_main_live_scenario_unknown_id_prints_warning(monkeypatch, capsys):
    # run_golden.py:492-496 — --scenario ids not present in scenarios.yaml must be flagged with a
    # ::warning:: annotation so a typo'd filter doesn't silently run zero scenarios unnoticed.
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--live", "--scenario", "nonexistent-id"])
    monkeypatch.setattr(rg, "run_live", lambda scenarios, scenario_ids=None: [])
    assert rg.main() == 0
    err = capsys.readouterr().err
    assert "::warning::--scenario id(s) not found in scenarios.yaml: ['nonexistent-id']" in err
