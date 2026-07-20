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

from conftest import load_module_from_path

rg = load_module_from_path("run_golden", "tests", "golden_scenarios", "run_golden.py")

VALID = {
    "id": "ZZ-01", "category": "kill_trigger", "situation": "x",
    "governing_files": ["Strategy.md"], "expected_decision": "CONTINUE", "rationale": "x",
}


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


def test_non_mapping_scenario_entry_caught():
    assert any("is not a mapping" in e for e in rg.validate_offline(["not-a-dict"]))


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


def test_daily_vs_minute_quota_classification():
    assert rg._is_daily_quota_429(_QUOTA_DAY_BODY.decode()) is True
    assert rg._is_daily_quota_429(_QUOTA_MIN_BODY.decode()) is False
    assert rg._retry_delay_s(_QUOTA_MIN_BODY.decode(), 99) == 7.0   # honours the API's RetryInfo
    assert rg._retry_delay_s("{}", 99) == 99                        # falls back when absent


def test_gemini_ladder_advances_on_daily_quota_429(monkeypatch):
    # A per-DAY 429 is persistent: the pointer must advance and the SECOND model's reply is returned.
    ladder = ["model-a", "model-b", "model-c"]

    def fake_urlopen(req, timeout=180):
        if "model-a:" in req.full_url:
            raise _fake_http_error(req.full_url, 429, _QUOTA_DAY_BODY)
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: x"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(rg.time, "sleep", lambda s: None)  # must not be needed, but never really sleep
    state = {"idx": 0}
    text, model = rg._gemini_call("prompt", "k", ladder, state)
    assert "DECISION: GO" in text
    assert model == "model-b"
    assert state["idx"] == 1  # advanced past the day-exhausted model, and stuck there


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
    state = {"idx": 0}
    text, model = rg._gemini_call("prompt", "k", ["m1", "m2"], state)
    assert "NO-GO" in text
    assert model == "m1"          # stayed on the SAME (best) model
    assert state["idx"] == 0      # ladder rung NOT burned
    assert slept == [7.0]         # honoured the API's suggested retryDelay


def test_gemini_minute_quota_429_gives_up_after_max_retries(monkeypatch):
    # Bounded: a model stuck at a per-minute limit is eventually abandoned (ladder advances) rather than
    # retrying forever.
    slept = []

    def fake_urlopen(req, timeout=180):
        if "m1:" in req.full_url:
            raise _fake_http_error(req.full_url, 429, _QUOTA_MIN_BODY)
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: z"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(rg.time, "sleep", lambda s: slept.append(s))
    state = {"idx": 0}
    text, model = rg._gemini_call("prompt", "k", ["m1", "m2"], state)
    assert model == "m2" and state["idx"] == 1
    assert len(slept) == rg.GEMINI_RPM_MAX_RETRIES  # retried the cap, then advanced


def test_gemini_ladder_exhaustion_raises(monkeypatch):
    # Every model day-quota-exhausted -> RuntimeError (never a silent blank that would score as a flip),
    # and the message names EVERY model's failure, not just the last one.
    def fake_urlopen(req, timeout=180):
        raise _fake_http_error(req.full_url, 429, _QUOTA_DAY_BODY)

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(rg.time, "sleep", lambda s: None)
    state = {"idx": 0}
    try:
        rg._gemini_call("prompt", "k", ["m1", "m2"], state)
        assert False, "expected RuntimeError on ladder exhaustion"
    except RuntimeError as exc:
        assert "ladder exhausted" in str(exc)
        assert "m1" in str(exc) and "m2" in str(exc)  # per-model diagnostics, not just the last error


def test_gemini_empty_response_advances(monkeypatch):
    # A blank/blocked candidate that is NOT a MAX_TOKENS truncation (e.g. a safety block) must advance
    # the ladder, not be scored as an empty decision and not trigger a budget escalation.
    def fake_urlopen(req, timeout=180):
        if "m1:" in req.full_url:
            return _FakeResp({"candidates": [{"content": {"parts": [{"text": "   "}]}, "finishReason": "SAFETY"}]})
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: NO-GO\nRATIONALE: y"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    state = {"idx": 0}
    text, model = rg._gemini_call("prompt", "k", ["m1", "m2"], state)
    assert "NO-GO" in text and model == "m2"


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
    state = {"idx": 0}
    text, model = rg._gemini_call("prompt", "k", ["only-model"], state)
    assert "DECISION: GO" in text
    assert model == "only-model" and state["idx"] == 0          # stayed on the same model
    assert seen == [rg.GEMINI_MAX_OUTPUT_TOKENS_START, rg.GEMINI_MAX_OUTPUT_TOKENS_START * 2]  # doubled


def test_gemini_budget_escalation_is_bounded_then_advances(monkeypatch):
    # A model that truncates at EVERY budget must escalate only up to the ceiling (never unboundedly),
    # then advance the ladder to the next model.
    seen_m1 = []

    def fake_urlopen(req, timeout=180):
        if "m1:" in req.full_url:
            seen_m1.append(_budget_of(req))
            return _FakeResp({"candidates": [{"content": {"parts": []}, "finishReason": "MAX_TOKENS"}]})
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: TERMINATE\nRATIONALE: z"}]},
                                          "finishReason": "STOP"}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    state = {"idx": 0}
    text, model = rg._gemini_call("prompt", "k", ["m1", "m2"], state)
    assert "TERMINATE" in text and model == "m2" and state["idx"] == 1
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
    state = {"idx": 0}  # no explicit budget => _gemini_call seeds it to _START via setdefault
    rg._gemini_call("scenario-1", "k", ["m"], state)     # truncates at _START, escalates to 2*_START
    assert state["budget"] == rg.GEMINI_MAX_OUTPUT_TOKENS_START * 2
    seen.clear()
    rg._gemini_call("scenario-2", "k", ["m"], state)     # must reuse the mark: ONE call, no re-truncation
    assert seen == [rg.GEMINI_MAX_OUTPUT_TOKENS_START * 2]


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


def test_run_live_records_an_error_class_when_the_model_call_raises(monkeypatch, capsys):
    monkeypatch.setattr(rg, "_select_live_caller", _fake_caller_returning(RuntimeError("ladder exhausted")))
    r = rg.run_live([_sc("T-ERR", "GO")])[0]
    # The except branch records match=None (the ERROR class main() counts), not a scored flip.
    assert r["match"] is None and r["actual"] is None and r["model"] is None
    assert "ladder exhausted" in r["reply"]
    assert "model call failed" in capsys.readouterr().err


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
    # Drive the aggregation/print path at run_golden.py:502-508 directly, bypassing run_live()'s own
    # internals (already covered by the test_run_live_* tests above) — main() must count and label a
    # mixed match/flip/error results list correctly, since this print IS what a human triaging a live
    # CI run actually reads (module docstring: advisory, continue-on-error).
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--live"])
    mixed_results = [
        {"id": "A", "expected": "GO", "actual": "GO", "match": True, "reply": "r", "model": "m"},
        {"id": "B", "expected": "GO", "actual": "NO-GO", "match": False, "reply": "r", "model": "m"},
        {"id": "C", "expected": "GO", "actual": None, "match": None, "reply": "boom", "model": None},
    ]
    monkeypatch.setattr(rg, "run_live", lambda scenarios, scenario_ids=None: mixed_results)
    assert rg.main() == 0
    out = capsys.readouterr().out
    assert "Live results: 1 match, 1 flip(s), 1 error(s) out of 3." in out
    assert "[MATCH] A: expected='GO' actual='GO'" in out
    assert "[FLIP] B: expected='GO' actual='NO-GO'" in out
    assert "[ERROR] C: expected='GO' actual=None" in out


def test_main_live_scenario_unknown_id_prints_warning(monkeypatch, capsys):
    # run_golden.py:492-496 — --scenario ids not present in scenarios.yaml must be flagged with a
    # ::warning:: annotation so a typo'd filter doesn't silently run zero scenarios unnoticed.
    monkeypatch.setattr(sys, "argv", ["run_golden.py", "--live", "--scenario", "nonexistent-id"])
    monkeypatch.setattr(rg, "run_live", lambda scenarios, scenario_ids=None: [])
    assert rg.main() == 0
    err = capsys.readouterr().err
    assert "::warning::--scenario id(s) not found in scenarios.yaml: ['nonexistent-id']" in err
