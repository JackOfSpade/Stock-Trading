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
import copy
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "tests", "golden_scenarios", "run_golden.py")
    spec = importlib.util.spec_from_file_location("run_golden", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


rg = _load()

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

import contextlib
import io
import json as _json
import urllib.error
import urllib.request


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


def test_gemini_model_ladder_wellformed():
    assert isinstance(rg.GEMINI_MODEL_LADDER, list) and rg.GEMINI_MODEL_LADDER
    assert all(isinstance(m, str) and m.strip() for m in rg.GEMINI_MODEL_LADDER)
    # Best-quality-first: the top of the ladder must be a full Flash model, not a *-lite (putting the
    # cheap 500/day lite reservoir first would waste the higher-quality daily quota).
    assert "lite" not in rg.GEMINI_MODEL_LADDER[0]


def test_select_live_caller_none_when_no_keys():
    with _env(GEMINI_API_KEY=None, ANTHROPIC_API_KEY=None):
        assert rg._select_live_caller("claude-sonnet-5") is None


def test_select_live_caller_prefers_gemini_over_anthropic():
    # With BOTH keys set, Gemini (free tier) must win. Only assert a callable is returned — never invoke
    # it (no network in unit tests). If the anthropic branch were taken it would try to import the SDK.
    with _env(GEMINI_API_KEY="test-key", ANTHROPIC_API_KEY="test-key"):
        caller = rg._select_live_caller("claude-sonnet-5")
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


def test_gemini_ladder_advances_on_429_then_succeeds(monkeypatch):
    # First ladder model returns 429 (daily quota exhausted); the pointer must advance and the SECOND
    # model's valid DECISION reply must be returned, tagged with the model that actually answered.
    ladder = ["model-a", "model-b", "model-c"]

    def fake_urlopen(req, timeout=90):
        if "model-a:" in req.full_url:
            raise _fake_http_error(req.full_url, 429, b'{"error":"RESOURCE_EXHAUSTED"}')
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: GO\nRATIONALE: x"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    state = {"idx": 0}
    text, model = rg._gemini_call("prompt", "k", ladder, state)
    assert "DECISION: GO" in text
    assert model == "model-b"
    assert state["idx"] == 1  # advanced past the exhausted model, and stuck there


def test_gemini_ladder_exhaustion_raises(monkeypatch):
    # Every model 429s -> RuntimeError (never a silent blank that would score as a decision flip).
    def fake_urlopen(req, timeout=90):
        raise _fake_http_error(req.full_url, 429, b'{"error":"RESOURCE_EXHAUSTED"}')

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    state = {"idx": 0}
    try:
        rg._gemini_call("prompt", "k", ["m1", "m2"], state)
        assert False, "expected RuntimeError on ladder exhaustion"
    except RuntimeError as exc:
        assert "ladder exhausted" in str(exc)


def test_gemini_empty_response_advances(monkeypatch):
    # A blank/blocked candidate (e.g. thinking ate the whole budget) must advance the ladder, not be
    # scored as an empty decision.
    def fake_urlopen(req, timeout=90):
        if "m1:" in req.full_url:
            return _FakeResp({"candidates": [{"content": {"parts": [{"text": "   "}]}}]})
        return _FakeResp({"candidates": [{"content": {"parts": [{"text": "DECISION: NO-GO\nRATIONALE: y"}]}}]})

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    state = {"idx": 0}
    text, model = rg._gemini_call("prompt", "k", ["m1", "m2"], state)
    assert "NO-GO" in text and model == "m2"
