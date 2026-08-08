"""Guard scripts/routine_backup.py -- the ops/routine_backup.json backup/restore/check tool built
after the 2026-08-01 accidental-trigger-deletion incident.

All tests run against tmp_path fixtures and monkeypatched module-level path constants (rb.CADENCE_PATH
/ rb.TRIGGERS_PATH / rb.TRIGGER_IDS_PATH / rb.BACKUP_PATH) -- never the real ops/*.json or
ops/cadence.yaml (a known trap in this repo: a prior session's tests clobbered real fixtures by
reading/writing the live files directly). rb reads these as bare globals (not default-parameter
values), so monkeypatch.setattr(rb, "BACKUP_PATH", ...) takes effect the same way it does for
scripts/check_cadence_consistency.py's CADENCE/OWNER_ACTIONS/etc. constants.
"""
import copy
import json
import os
import re
import uuid

import pytest

from conftest import load_module_from_path

rb = load_module_from_path("routine_backup", "scripts", "routine_backup.py")


ADDENDUM = rb.ADDENDUM


# ---- fixtures --------------------------------------------------------------------------------------
def _raw_trigger(*, tid="trig_D1AAAA", name="D1. Test Routine — deep research",
                  cron="0 16 * * *", run_once_at=None, enabled=True, content=None,
                  environment_id="env_FLEET", model="claude-opus-5", allowed_tools=None, autofix=True,
                  sources=None, connections=None, extra_top=None, extra_sc=None, notifications=None):
    """A raw RemoteTrigger object as `list`/`get` would return it, with every VOLATILE field
    populated with an obviously-poisoned value so a test can assert normalize_trigger() drops it."""
    if content is None:
        content = f"Read Claude_Task_Plan.md. Perform {name}.{ADDENDUM}"
    if allowed_tools is None:
        allowed_tools = list(rb._FLEET_TOOLS)
    if sources is None:
        sources = [{"git_repository": {"url": rb.FLEET_REPO_URL}}]
    if connections is None:
        connections = [
            {"connector_uuid": "u-fmp", "name": "FMP", "url": "https://fmp/mcp",
             "permitted_tools": [], "tool_policy_overrides": [], "clear_tool_policy_overrides": False},
            {"connector_uuid": "u-gh", "name": "Gmail", "url": "https://gmail/mcp",
             "permitted_tools": [], "tool_policy_overrides": [], "clear_tool_policy_overrides": False},
        ]
    sc = {
        "model": model, "allowed_tools": allowed_tools, "autofix_on_pr_create": autofix,
        "sources": sources,
        "outcomes": [{"git_repository": {"git_info": {"branches": ["claude/poison-branch"],
                                                        "repo": "should-never-appear/anywhere"}}}],
    }
    if extra_sc:
        sc.update(extra_sc)
    raw = {
        "id": tid, "name": name, "cron_expression": cron, "run_once_at": run_once_at, "enabled": enabled,
        "job_config": {"ccr": {
            "environment_id": environment_id, "session_context": sc,
            "events": [{"data": {
                "message": {"content": content, "role": "user"}, "parent_tool_use_id": None,
                "session_id": "", "type": "user", "uuid": "11111111-1111-1111-1111-111111111111"}}],
        }},
        "mcp_connections": connections,
        "notifications": notifications if notifications is not None else {"channel": {"email": False, "push": False, "slack": False}},
        # volatile top-level fields -- normalize_trigger() must never surface any of these.
        "next_run_at": "POISON-next_run_at", "last_fired_at": "POISON-last_fired_at",
        "updated_at": "POISON-updated_at", "created_at": "POISON-created_at",
        "ended_reason": "POISON-ended_reason", "suspension_reason": "POISON-suspension_reason",
        "api_token_hint": "POISON-api_token_hint",
        "creator": {"account_uuid": "POISON-creator-uuid"},
    }
    if extra_top:
        raw.update(extra_top)
    return raw


# A local, deliberately-distinct-from-production profile pair, matching _raw_trigger()'s own defaults
# exactly -- ingest/restore tests seed the backup file with THIS, not the real DEFAULT_PROFILES, so
# they stay correct even if the real production profile values (scripts/routine_backup.py's
# DEFAULT_PROFILES) ever change. check()-focused tests use the real DEFAULT_PROFILES instead (via
# _good_backup_doc()), since check() never derives a profile -- it only checks one is referenced.
TEST_PROFILES = {
    "fleet": {
        "environment_id": "env_FLEET", "autofix_on_pr_create": True, "model": "claude-opus-5",
        "notifications": {"channel": {"email": False, "push": False, "slack": False}},
        "allowed_tools": list(rb._FLEET_TOOLS),
        "sources": [{"git_repository": {"url": rb.FLEET_REPO_URL}}],
        "mcp_connections": [{"connector_uuid": "u-fmp", "name": "FMP", "url": "https://fmp/mcp"},
                             {"connector_uuid": "u-gh", "name": "Gmail", "url": "https://gmail/mcp"}],
    },
    "personal": {
        "environment_id": "env_PERSONAL_ENV", "autofix_on_pr_create": True, "model": "claude-opus-5",
        "notifications": {"channel": {"email": False, "push": False, "slack": False}},
        "allowed_tools": list(rb._PERSONAL_TOOLS),
        "sources": [{"git_repository": {"url": "https://github.com/JackOfSpade/Other-Repo"}}],
        "mcp_connections": [{"connector_uuid": "u-cal", "name": "Google-Calendar", "url": "https://cal"}],
    },
}

_UNSET = object()


def _wire(tmp_path, monkeypatch, *, backup_doc=_UNSET):
    """Point every rb path constant at tmp_path fixtures. cadence.yaml/triggers.json/trigger_ids.json
    describe two routines (D1 -- normal, carries ADDENDUM; OPS2 -- the documented no-addendum
    exception). backup_doc controls the starting ops/routine_backup.json: omitted (_UNSET) writes a
    minimal doc seeded with TEST_PROFILES; explicit None writes nothing (the missing-file case,
    load_backup() then falls back to the real DEFAULT_PROFILES skeleton); an explicit dict is written
    verbatim."""
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text(
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "  - id: OPS2\n"
        "    monitor_class: daily_all\n"
    )
    triggers = tmp_path / "triggers.json"
    triggers.write_text(json.dumps({
        "D1": {"instruction": "Read Claude_Task_Plan.md. Perform D1. Test Routine — deep research.",
               "monitor_class": "daily_trading"},
        "OPS2": {"instruction": "Read Claude_Task_Plan.md. Perform OPS2. Catch-up Executor — regular routine.",
                 "monitor_class": "daily_all"},
    }))
    trigger_ids = tmp_path / "trigger_ids.json"
    trigger_ids.write_text(json.dumps({
        "_meta": {"purpose": "test fixture"},
        "D1": {"trigger_id": "trig_D1AAAA", "verified_via": "api"},
        "OPS2": {"trigger_id": "trig_OPS2AAAA", "verified_via": "api"},
    }))
    backup = tmp_path / "routine_backup.json"
    if backup_doc is _UNSET:
        backup_doc = {"_meta": {}, "profiles": copy.deepcopy(TEST_PROFILES), "routines": {},
                      "_unmatched": {}}
    if backup_doc is not None:
        backup.write_text(json.dumps(backup_doc))

    monkeypatch.setattr(rb, "CADENCE_PATH", str(cadence))
    monkeypatch.setattr(rb, "TRIGGERS_PATH", str(triggers))
    monkeypatch.setattr(rb, "TRIGGER_IDS_PATH", str(trigger_ids))
    monkeypatch.setattr(rb, "BACKUP_PATH", str(backup))
    return cadence, triggers, trigger_ids, backup


# ---- normalize_trigger: volatile-field / outcomes stripping ----------------------------------------
def test_normalize_trigger_strips_all_volatile_top_level_fields():
    raw = _raw_trigger()
    got = rb.normalize_trigger(raw)
    dumped = json.dumps(got)
    for poison in ("POISON-next_run_at", "POISON-last_fired_at", "POISON-updated_at",
                   "POISON-created_at", "POISON-ended_reason", "POISON-suspension_reason",
                   "POISON-api_token_hint", "POISON-creator-uuid"):
        assert poison not in dumped, f"{poison} leaked into normalize_trigger() output"


def test_normalize_trigger_strips_session_context_outcomes():
    raw = _raw_trigger()
    got = rb.normalize_trigger(raw)
    assert "outcomes" not in got
    assert "claude/poison-branch" not in json.dumps(got)
    assert "should-never-appear/anywhere" not in json.dumps(got)


def test_normalize_trigger_shape_and_cron_stripped():
    raw = _raw_trigger(cron="  0 16 * * *  ")
    got = rb.normalize_trigger(raw)
    assert got == {
        "trigger_id": "trig_D1AAAA",
        "name": "D1. Test Routine — deep research",
        "cron_expression": "0 16 * * *",
        "run_once_at": None,
        "enabled": True,
        "instruction": f"Read Claude_Task_Plan.md. Perform D1. Test Routine — deep research.{ADDENDUM}",
        "environment_id": "env_FLEET",
        "model": "claude-opus-5",
        "allowed_tools": list(rb._FLEET_TOOLS),
        "autofix_on_pr_create": True,
        "notifications": {"channel": {"email": False, "push": False, "slack": False}},
        "sources": [{"git_repository": {"url": rb.FLEET_REPO_URL}}],
        "mcp_connections": [
            {"connector_uuid": "u-fmp", "name": "FMP", "url": "https://fmp/mcp"},
            {"connector_uuid": "u-gh", "name": "Gmail", "url": "https://gmail/mcp"},
        ],
    }


def test_normalize_trigger_empty_cron_becomes_sentinel():
    raw = _raw_trigger(cron="")
    assert rb.normalize_trigger(raw)["cron_expression"] == rb.CRON_UNCONFIRMED
    raw2 = _raw_trigger(cron="   ")
    assert rb.normalize_trigger(raw2)["cron_expression"] == rb.CRON_UNCONFIRMED


def test_normalize_trigger_mcp_connections_sorted_by_name_regardless_of_input_order():
    raw = _raw_trigger(connections=[
        {"connector_uuid": "u-z", "name": "Zeta", "url": "https://z"},
        {"connector_uuid": "u-a", "name": "Alpha", "url": "https://a"},
    ])
    got = rb.normalize_trigger(raw)["mcp_connections"]
    assert [c["name"] for c in got] == ["Alpha", "Zeta"]


# ---- normalize_trigger: notifications key-filtering (B6) --------------------------------------------
def test_normalize_trigger_notifications_filtered_to_named_subkeys_only():
    """normalize_trigger() must filter notifications to EXACTLY {"channel": {email,push,slack}} --
    it used to copy `raw.get("notifications")` whole-cloth, the only field not key-filtered,
    contradicting the function's own docstring guarantee that only named fields are copied. An extra/
    volatile sub-key must never leak into the snapshot or a restore body."""
    raw = _raw_trigger(notifications={
        "channel": {"email": True, "push": False, "slack": True, "webhook": "POISON-webhook"},
        "extra_top_level_key": "POISON-extra-top-level",
    })
    got = rb.normalize_trigger(raw)["notifications"]
    assert got == {"channel": {"email": True, "push": False, "slack": True}}
    assert "POISON" not in json.dumps(got)


def test_normalize_trigger_notifications_defaults_missing_channel_values_to_false():
    raw = _raw_trigger(notifications={"channel": {"email": True}})
    got = rb.normalize_trigger(raw)["notifications"]
    assert got == {"channel": {"email": True, "push": False, "slack": False}}


# ---- normalize_trigger: run_once_at one-shot schedule (B1) -------------------------------------------
def test_normalize_trigger_captures_run_once_at_and_does_not_sentinel_cron():
    """A live one-shot trigger (the 2 real personal_* routines) carries an empty cron_expression and a
    populated run_once_at. Ingesting it must NOT degrade the empty cron into CRON_UNCONFIRMED -- that
    would silently lose the one-shot schedule."""
    raw = _raw_trigger(cron="", run_once_at="2026-08-01T12:52:00Z")
    got = rb.normalize_trigger(raw)
    assert got["run_once_at"] == "2026-08-01T12:52:00Z"
    assert got["cron_expression"] is None
    assert got["cron_expression"] != rb.CRON_UNCONFIRMED


def test_normalize_trigger_recurring_trigger_has_no_run_once_at():
    raw = _raw_trigger(cron="0 16 * * *", run_once_at=None)
    got = rb.normalize_trigger(raw)
    assert got["cron_expression"] == "0 16 * * *"
    assert got["run_once_at"] is None


def test_normalize_trigger_missing_cron_and_missing_run_once_at_still_sentinels():
    raw = _raw_trigger(cron="", run_once_at=None)
    got = rb.normalize_trigger(raw)
    assert got["cron_expression"] == rb.CRON_UNCONFIRMED
    assert got["run_once_at"] is None


# ---- ingest payload shapes ---------------------------------------------------------------------------
def test_iter_raw_triggers_accepts_list_response_get_response_and_bare_array():
    t = _raw_trigger()
    assert rb._iter_raw_triggers({"data": [t]}) == [t]
    assert rb._iter_raw_triggers({"trigger": t}) == [t]
    assert rb._iter_raw_triggers([t]) == [t]


def test_iter_raw_triggers_rejects_unrecognized_shape():
    with pytest.raises(ValueError):
        rb._iter_raw_triggers({"nonsense": True})


# ---- match_routine_id: trigger_id first, then core-instruction ---------------------------------------
def test_match_routine_id_by_trigger_id():
    trigger_ids_doc = {"D1": {"trigger_id": "trig_D1AAAA"}}
    normalized = rb.normalize_trigger(_raw_trigger(tid="trig_D1AAAA"))
    assert rb.match_routine_id(normalized, trigger_ids_doc, {}) == "D1"


def test_match_routine_id_falls_back_to_instruction_when_trigger_id_unknown():
    triggers_doc = {"D1": {"instruction": "Read Claude_Task_Plan.md. Perform D1. Test Routine — deep research."}}
    normalized = rb.normalize_trigger(_raw_trigger(tid="trig_BRAND_NEW"))
    assert rb.match_routine_id(normalized, {}, triggers_doc) == "D1"


def test_match_routine_id_none_when_neither_matches():
    normalized = rb.normalize_trigger(_raw_trigger(tid="trig_UNKNOWN", content="totally unrelated text"))
    assert rb.match_routine_id(normalized, {}, {}) is None


# ---- match_routine_id priority + match_conflict (B5, mutation gap 3) ---------------------------------
def test_match_routine_id_trigger_id_wins_over_conflicting_instruction_match():
    """Priority is deliberate and must never flip: trigger_id is the ground truth once recorded.
    ops/trigger_ids.json says this trigger_id is D1; ops/triggers.json says this INSTRUCTION belongs
    to OPS2 (a contrived collision, standing in for a stale/duplicated trigger_ids.json in the live
    account). match_routine_id() must still return the trigger_id-based answer ('D1'), never silently
    swap to the instruction-based one -- and match_conflict() must surface the disagreement so the
    caller (ingest()) doesn't just silently pick a side."""
    trigger_ids_doc = {"D1": {"trigger_id": "trig_D1AAAA"}}
    triggers_doc = {"OPS2": {"instruction":
                             "Read Claude_Task_Plan.md. Perform D1. Test Routine — deep research."}}
    normalized = rb.normalize_trigger(_raw_trigger(tid="trig_D1AAAA"))
    assert rb.match_routine_id(normalized, trigger_ids_doc, triggers_doc) == "D1"
    assert rb.match_conflict(normalized, trigger_ids_doc, triggers_doc) == ("D1", "OPS2")


def test_match_conflict_none_when_sources_agree():
    trigger_ids_doc = {"D1": {"trigger_id": "trig_D1AAAA"}}
    triggers_doc = {"D1": {"instruction":
                           "Read Claude_Task_Plan.md. Perform D1. Test Routine — deep research."}}
    normalized = rb.normalize_trigger(_raw_trigger(tid="trig_D1AAAA"))
    assert rb.match_conflict(normalized, trigger_ids_doc, triggers_doc) is None


def test_match_conflict_none_when_only_one_source_resolves():
    trigger_ids_doc = {"D1": {"trigger_id": "trig_D1AAAA"}}
    normalized = rb.normalize_trigger(_raw_trigger(tid="trig_D1AAAA"))
    assert rb.match_conflict(normalized, trigger_ids_doc, {}) is None


# ---- is_personal / _personal_id ---------------------------------------------------------------------
def test_is_personal_true_for_different_repo():
    normalized = rb.normalize_trigger(_raw_trigger(
        sources=[{"git_repository": {"url": "https://github.com/JackOfSpade/Image-and-Video-Generation-Pipeline"}}]))
    assert rb.is_personal(normalized) is True


def test_is_personal_false_for_fleet_repo():
    normalized = rb.normalize_trigger(_raw_trigger())
    assert rb.is_personal(normalized) is False


def test_is_personal_false_when_sources_empty():
    """A sourceless trigger (empty `sources`) must stay `_unmatched`, not be reclassified 'personal' --
    is_personal()'s `bool(urls)` guard exists specifically so an empty source list short-circuits to
    False instead of vacuously satisfying 'FLEET_REPO_URL not in urls' (true for an empty set too)."""
    normalized = rb.normalize_trigger(_raw_trigger(sources=[]))
    assert rb.is_personal(normalized) is False


def test_personal_id_slugifies_name():
    assert rb._personal_id("Research Leading Omnireference Video Platforms") == (
        "personal_research_leading_omnireference_video_platforms")
    assert rb._personal_id("Update Image Generation in the Pipeline") == (
        "personal_update_image_generation_in_the_pipeline")


# ---- derive_profile: best match + overrides -----------------------------------------------------------
PROFILES = {
    "fleet": {
        "environment_id": "env_FLEET", "autofix_on_pr_create": True, "model": "claude-opus-5",
        "notifications": {"channel": {"email": False, "push": False, "slack": False}},
        "allowed_tools": ["Bash", "RemoteTrigger"],
        "sources": [{"git_repository": {"url": "https://github.com/Owner/Repo"}}],
        "mcp_connections": [{"connector_uuid": "u-a", "name": "A", "url": "https://a"},
                             {"connector_uuid": "u-b", "name": "B", "url": "https://b"}],
    },
    "sl": {
        "environment_id": "env_SL", "autofix_on_pr_create": False, "model": "claude-opus-5",
        "notifications": {"channel": {"email": False, "push": True, "slack": False}},
        "allowed_tools": ["Bash", "RemoteTrigger"],
        "sources": [{"git_repository": {"url": "https://github.com/Owner/Repo"}}],
        "mcp_connections": [{"connector_uuid": "u-a", "name": "A", "url": "https://a"},
                             {"connector_uuid": "u-b", "name": "B", "url": "https://b"}],
    },
}


def _norm(**over):
    base = {
        "trigger_id": "t", "name": "n", "cron_expression": "c", "enabled": True, "instruction": "i",
        "environment_id": "env_FLEET", "model": "claude-opus-5", "allowed_tools": ["Bash", "RemoteTrigger"],
        "autofix_on_pr_create": True, "notifications": {"channel": {"email": False, "push": False, "slack": False}},
        "sources": [{"git_repository": {"url": "https://github.com/Owner/Repo"}}],
        "mcp_connections": [{"connector_uuid": "u-a", "name": "A", "url": "https://a"},
                          {"connector_uuid": "u-b", "name": "B", "url": "https://b"}],
    }
    base.update(over)
    return base


def test_derive_profile_exact_match_has_no_overrides():
    profile, overrides = rb.derive_profile(_norm(), PROFILES)
    assert profile == "fleet"
    assert overrides == {}


def test_derive_profile_picks_best_scoring_profile_on_a_near_match():
    # env_SL + autofix False + push notifications match "sl" on those 3 fields and "fleet" on 0 of
    # them -- "sl" wins even though nothing is a PERFECT match.
    normalized = _norm(environment_id="env_SL", autofix_on_pr_create=False,
                       notifications={"channel": {"email": False, "push": True, "slack": False}})
    profile, overrides = rb.derive_profile(normalized, PROFILES)
    assert profile == "sl"
    assert overrides == {}


def test_derive_profile_records_every_differing_field_in_overrides():
    normalized = _norm(model="claude-opus-6", allowed_tools=["Bash"])
    profile, overrides = rb.derive_profile(normalized, PROFILES)
    assert profile == "fleet"
    assert overrides == {"model": "claude-opus-6", "allowed_tools": ["Bash"]}


def test_derive_profile_connector_order_never_produces_a_spurious_override():
    normalized = _norm(mcp_connections=[
        {"connector_uuid": "u-b", "name": "B", "url": "https://b"},
        {"connector_uuid": "u-a", "name": "A", "url": "https://a"},
    ])
    profile, overrides = rb.derive_profile(normalized, PROFILES)
    assert profile == "fleet"
    assert "mcp_connections" not in overrides


def test_derive_profile_connector_set_difference_is_an_override():
    normalized = _norm(mcp_connections=[{"connector_uuid": "u-c", "name": "C", "url": "https://c"}])
    profile, overrides = rb.derive_profile(normalized, PROFILES)
    assert overrides["mcp_connections"] == [{"connector_uuid": "u-c", "name": "C", "url": "https://c"}]


def test_derive_profile_raises_on_empty_profiles():
    with pytest.raises(ValueError):
        rb.derive_profile(_norm(), {})


# ---- derive_profile: allowed_tools compared order-insensitively, matching mcp_connections -------------
def test_derive_profile_tool_order_never_produces_a_spurious_override():
    """allowed_tools must be compared the same order-INSENSITIVE way mcp_connections already is (see
    test_derive_profile_connector_order_never_produces_a_spurious_override above) -- a live routine
    whose allowed_tools happens to come back from the API in a different order than its profile is not
    real drift and must not pick up a spurious override (2026-08-08)."""
    normalized = _norm(allowed_tools=["RemoteTrigger", "Bash"])
    profile, overrides = rb.derive_profile(normalized, PROFILES)
    assert profile == "fleet"
    assert "allowed_tools" not in overrides


def test_derive_profile_tool_set_difference_is_an_override():
    normalized = _norm(allowed_tools=["Bash"])
    profile, overrides = rb.derive_profile(normalized, PROFILES)
    assert overrides["allowed_tools"] == ["Bash"]


# ---- derive_profile tie-break: deterministic, lowest name wins (B7, mutation gap 1) -------------------
def _tied_profile(env, src_url):
    return {
        "environment_id": env, "autofix_on_pr_create": True, "model": "claude-opus-5",
        "notifications": {"channel": {"email": False, "push": False, "slack": False}},
        "allowed_tools": ["Bash"],
        "sources": [{"git_repository": {"url": src_url}}],
        "mcp_connections": [],
    }


def test_derive_profile_tie_break_is_deterministic_lowest_name_wins():
    """Three profiles that all score IDENTICALLY against `normalized` (model/autofix/notifications and
    the empty mcp_connections set all match every one of the three equally; environment_id/
    allowed_tools/sources all mismatch every one of the three equally) -- dict-insertion order is
    "mmm", "aaa", "zzz" (deliberately NOT alphabetical, and deliberately NOT ending on the
    lexicographically-smallest one), so neither "first-seen wins" nor "last-seen wins" coincides with
    the correct answer. The documented tie-break (B7) is the lowest profile NAME wins,
    which must be "aaa" regardless of that order -- a plain `score > best_score` comparison (no tie-
    break) would non-deterministically return whichever profile the dict happens to visit first
    ("mmm" here), and a `score >= best_score` mutant (dropping the tie-break, always overwriting on a
    tie) would return whichever is visited LAST ("zzz" here). Both are distinguishable from the correct
    "aaa" by this ordering."""
    tied_profiles = {
        "mmm": _tied_profile("env_M", "https://m"),
        "aaa": _tied_profile("env_A", "https://a"),
        "zzz": _tied_profile("env_Z", "https://z"),
    }
    normalized = _norm(environment_id="env_NEITHER", allowed_tools=["Bash", "RemoteTrigger"],
                       sources=[{"git_repository": {"url": "https://neither"}}], mcp_connections=[])
    profile, _ = rb.derive_profile(normalized, tied_profiles)
    assert profile == "aaa"


# ---- _resolve_fields(): a profile missing a field resolves to None, never raises (2026-08-08) --------
def test_resolve_fields_handles_profile_missing_a_field_instead_of_raising_keyerror():
    """_resolve_fields() used to hard-index 6 of the 7 profile fields (p["environment_id"], p["model"],
    p["allowed_tools"], p["autofix_on_pr_create"], p["sources"], p["mcp_connections"]) while only
    `notifications` used p.get(...) -- that inconsistency was the tell. A snapshot profile missing one
    of the six (hand-edited or a corrupted ingest) raised an uncaught KeyError here, which crashed
    check()/restore() before _resolved_fields_errors()'s own 'missing/empty' reporting ever ran. Every
    field must resolve to None like notifications always did, not raise."""
    bare_profile = {"model": "claude-opus-5"}  # every other field simply absent, not just falsy
    entry = {"profile": "bare", "overrides": {}}
    fields = rb._resolve_fields(entry, {"bare": bare_profile})
    assert fields["model"] == "claude-opus-5"
    assert fields["environment_id"] is None
    assert fields["allowed_tools"] is None
    assert fields["autofix_on_pr_create"] is None
    assert fields["sources"] is None
    assert fields["mcp_connections"] is None


def test_check_reports_missing_profile_field_instead_of_crashing(tmp_path, monkeypatch, capsys):
    """End-to-end through check(): a profile missing a field entirely must surface as a normal FAIL
    with the existing 'resolved ... is missing/empty' message, not an uncaught exception."""
    doc = _good_backup_doc()
    del doc["profiles"]["fleet"]["sources"]
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "ROUTINE BACKUP CHECK: FAIL" in out
    assert "resolved sources is missing/empty" in out


def test_notifications_roundtrip_as_override_and_reaches_restore_body(tmp_path, monkeypatch):
    """A routine whose push-notification toggle differs from its profile must be recorded as an
    explicit override AND must come back out in the restore body -- a non-default notifications
    override is still a valid thing an entry can carry even though every routine is currently silent
    (SL1-SL5 used to push-notify while the rest of the fleet ran silent, before the 2026-08-01
    fleet-wide normalisation retired that split). A restore that silently dropped an override would
    have left the strategy-lifecycle routines quiet back when the split existed -- exactly what the
    2026-08-01 recreation did before this was wired up."""
    _wire(tmp_path, monkeypatch)
    pushy = {"channel": {"email": False, "push": True, "slack": False}}
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger(notifications=pushy)]})))
    assert rb.load_backup()["routines"]["D1"]["overrides"]["notifications"] == pushy
    bodies, errors, _ = rb.restore(["D1"])
    assert errors == [] and bodies[0][1]["notifications"] == pushy


# ---- load_backup(): fresh-checkout fallback ----------------------------------------------------------
def test_load_backup_returns_default_profiles_skeleton_when_file_absent(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch, backup_doc=None)
    doc = rb.load_backup()
    assert doc["profiles"] == rb.DEFAULT_PROFILES
    assert doc["routines"] == {} and doc["_unmatched"] == {}


# ---- ingest(): end-to-end merge into ops/routine_backup.json ----------------------------------------
def test_ingest_matches_by_trigger_id_and_writes_backup(tmp_path, monkeypatch):
    _, _, _, backup = _wire(tmp_path, monkeypatch)
    infile = tmp_path / "in.json"
    infile.write_text(json.dumps({"data": [_raw_trigger()]}))

    result = rb.ingest(str(infile))
    assert result == {"added": ["D1"], "updated": [], "unchanged": [], "unmatched": [],
                       "conflicts": [], "unconfirmed_cron": []}

    doc = json.loads(backup.read_text())
    assert doc["routines"]["D1"]["trigger_id"] == "trig_D1AAAA"
    assert doc["routines"]["D1"]["profile"] == "fleet"
    assert "overrides" not in doc["routines"]["D1"]
    assert re.fullmatch(r"\d{4}-\d{2}-\d{2}", doc["_meta"]["last_ingested"])


def test_ingest_is_idempotent_second_run_reports_unchanged(tmp_path, monkeypatch):
    _, _, _, _ = _wire(tmp_path, monkeypatch)
    infile = tmp_path / "in.json"
    infile.write_text(json.dumps({"data": [_raw_trigger()]}))
    rb.ingest(str(infile))
    result = rb.ingest(str(infile))
    assert result["added"] == [] and result["unchanged"] == ["D1"]


def test_ingest_cleanly_overwrites_cron_on_a_later_run(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    infile = tmp_path / "in.json"
    infile.write_text(json.dumps({"data": [_raw_trigger(cron="0 16 * * *")]}))
    rb.ingest(str(infile))
    infile.write_text(json.dumps({"data": [_raw_trigger(cron="0 17 * * *")]}))
    result = rb.ingest(str(infile))
    assert result["updated"] == ["D1"]
    doc = rb.load_backup()
    assert doc["routines"]["D1"]["cron_expression"] == "0 17 * * *"


def test_ingest_flags_unconfirmed_cron(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    infile = tmp_path / "in.json"
    infile.write_text(json.dumps({"data": [_raw_trigger(cron="")]}))
    result = rb.ingest(str(infile))
    assert result["unconfirmed_cron"] == ["D1"]


def test_ingest_routes_personal_out_of_scope_trigger_to_its_own_entry(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    infile = tmp_path / "in.json"
    infile.write_text(json.dumps({"data": [_raw_trigger(
        tid="trig_PERSONAL", name="Some Personal Research Routine",
        content="Deep research something unrelated.",
        environment_id="env_PERSONAL_ENV",
        allowed_tools=list(rb._PERSONAL_TOOLS),
        sources=[{"git_repository": {"url": "https://github.com/JackOfSpade/Other-Repo"}}],
        connections=[{"connector_uuid": "u-cal", "name": "Google-Calendar", "url": "https://cal"}])]}))
    result = rb.ingest(str(infile))
    assert result["added"] == ["personal_some_personal_research_routine"]
    doc = rb.load_backup()
    entry = doc["routines"]["personal_some_personal_research_routine"]
    assert entry["profile"] == "personal"
    assert "overrides" not in entry   # matches the personal TEST_PROFILES exactly -- ingest() only
                                       # sets the key `if overrides:`, so `{}` is a dead branch
    assert doc["_unmatched"] == {}


def test_ingest_records_genuinely_unmatched_trigger_without_dropping_it(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    infile = tmp_path / "in.json"
    infile.write_text(json.dumps({"data": [_raw_trigger(
        tid="trig_MYSTERY", name="Mystery Routine", content="unrelated instruction text entirely")]}))
    result = rb.ingest(str(infile))
    assert result["added"] == [] and result["unmatched"] == ["trig_MYSTERY"]
    doc = rb.load_backup()
    assert "trig_MYSTERY" in doc["_unmatched"]
    assert doc["_unmatched"]["trig_MYSTERY"]["name"] == "Mystery Routine"
    assert "D1" not in doc["routines"] and "Mystery Routine" not in doc["routines"]


def test_ingest_accepts_a_directory_of_files(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    indir = tmp_path / "indir"
    indir.mkdir()
    (indir / "a.json").write_text(json.dumps({"data": [_raw_trigger(tid="trig_D1AAAA")]}))
    (indir / "b.json").write_text(json.dumps({"trigger": _raw_trigger(
        tid="trig_OPS2AAAA", name="OPS2. Catch-up Executor — regular routine",
        content="Read Claude_Task_Plan.md. Perform OPS2. Catch-up Executor — regular routine.")}))
    result = rb.ingest(str(indir))
    assert sorted(result["added"]) == ["D1", "OPS2"]


# ---- ingest(): dedup raw triggers by trigger id before classification (2026-08-08) --------------------
def test_ingest_directory_with_same_trigger_in_two_files_does_not_double_count(tmp_path, monkeypatch):
    """The same trigger id can legitimately appear in more than one file of a directory ingest (e.g.
    overlapping RemoteTrigger `list` pages saved separately). Before the dedup fix, ingest()'s loop
    classified each occurrence separately, so this routine landed in BOTH 'added' (relative to the
    empty starting backup) and 'unchanged'/'updated' (relative to the entry the first occurrence had
    just written) -- double-counted even though doc["routines"]["D1"] only ever ends up holding the
    LAST occurrence's data (plain dict assignment is itself last-one-wins)."""
    _wire(tmp_path, monkeypatch)
    indir = tmp_path / "indir"
    indir.mkdir()
    (indir / "a.json").write_text(json.dumps({"data": [_raw_trigger(cron="0 16 * * *")]}))
    (indir / "b.json").write_text(json.dumps({"data": [_raw_trigger(cron="0 17 * * *")]}))
    result = rb.ingest(str(indir))
    assert result["added"] == ["D1"]
    assert result["updated"] == [] and result["unchanged"] == []
    # the LAST occurrence (b.json, 17:00) wins, matching this codebase's last-one-wins convention.
    assert rb.load_backup()["routines"]["D1"]["cron_expression"] == "0 17 * * *"


def test_dedup_raw_triggers_keeps_last_occurrence_by_trigger_id():
    raws = [{"id": "t1", "v": "first"}, {"id": "t2", "v": "other"}, {"id": "t1", "v": "second"}]
    got = rb._dedup_raw_triggers(raws)
    assert got == [{"id": "t1", "v": "second"}, {"id": "t2", "v": "other"}]


def test_dedup_raw_triggers_leaves_id_less_raws_alone():
    raws = [{"name": "no id here"}, {"name": "also no id"}]
    assert rb._dedup_raw_triggers(raws) == raws


# ---- ingest(): run_once_at one-shot storage (B1) -------------------------------------------------------
def test_ingest_stores_run_once_at_and_omits_cron_key_entirely(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    infile = _write(tmp_path, "in.json",
                     {"data": [_raw_trigger(cron="", run_once_at="2099-06-01T12:00:00Z")]})
    rb.ingest(str(infile))
    entry = rb.load_backup()["routines"]["D1"]
    assert entry["run_once_at"] == "2099-06-01T12:00:00Z"
    assert "cron_expression" not in entry


def test_ingest_recurring_entry_has_no_run_once_at_key(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger()]})))
    entry = rb.load_backup()["routines"]["D1"]
    assert entry["cron_expression"] == "0 16 * * *"
    assert "run_once_at" not in entry


# ---- ingest(): _unmatched is cleared once a stale trigger becomes matchable (B4) ------------------------
def test_ingest_clears_stale_unmatched_entry_once_it_becomes_matchable(tmp_path, monkeypatch):
    _, _, trigger_ids_path, _ = _wire(tmp_path, monkeypatch)
    infile = _write(tmp_path, "in.json", {"data": [_raw_trigger(
        tid="trig_NEWD1", name="A New Trigger", content="unrelated text entirely")]})

    result = rb.ingest(str(infile))
    assert result["unmatched"] == ["trig_NEWD1"]
    assert "trig_NEWD1" in rb.load_backup()["_unmatched"]

    # ops/trigger_ids.json is fixed out-of-band to know this trigger_id maps to D1.
    tid_doc = json.loads(trigger_ids_path.read_text())
    tid_doc["D1"] = {"trigger_id": "trig_NEWD1", "verified_via": "api"}
    trigger_ids_path.write_text(json.dumps(tid_doc))

    result2 = rb.ingest(str(infile))
    assert result2["added"] == ["D1"]
    backup = rb.load_backup()
    assert "D1" in backup["routines"]
    assert "trig_NEWD1" not in backup["_unmatched"], (
        "stale _unmatched copy must be cleared once matchable -- otherwise `restore` with no args "
        "would rebuild it as a DUPLICATE live trigger")


# ---- ingest(): trigger_id vs instruction conflict is recorded, not silently resolved (B5) ----------------
def test_ingest_records_conflict_and_leaves_existing_entries_untouched(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "first.json", {"data": [_raw_trigger()]})))
    before = rb.load_backup()["routines"]["D1"]

    # trigger_id resolves to D1 (per _wire's trigger_ids.json), but the instruction core matches
    # OPS2's canonical instruction in _wire's triggers.json -- a genuine disagreement.
    conflicting = _raw_trigger(
        tid="trig_D1AAAA",
        content="Read Claude_Task_Plan.md. Perform OPS2. Catch-up Executor — regular routine."
                + ADDENDUM)
    result = rb.ingest(str(_write(tmp_path, "second.json", {"data": [conflicting]})))

    assert result["conflicts"] == [
        {"trigger_id": "trig_D1AAAA", "trigger_id_routine": "D1", "instruction_routine": "OPS2"}]
    doc = rb.load_backup()
    assert doc["routines"]["D1"] == before   # untouched, not corrupted with OPS2's instruction
    assert "OPS2" not in doc["routines"]


# ---- ingest/restore: enabled=False must survive end to end (mutation gap 2) -----------------------------
def test_build_create_body_preserves_a_disabled_routine(tmp_path, monkeypatch):
    """Two REAL routines are deliberately paused (enabled=False) -- a restore must never re-enable
    them. No other test in this suite exercises enabled=False through ingest+restore."""
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger(enabled=False)]})))
    assert rb.load_backup()["routines"]["D1"]["enabled"] is False
    bodies, errors, _ = rb.restore(["D1"])
    assert errors == []
    assert bodies[0][1]["enabled"] is False


# ---- restore(): body shape, fresh uuid, no volatile fields --------------------------------------------
def test_restore_body_shape_matches_remotetrigger_create_contract(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger()]})))

    bodies, errors, note = rb.restore(["D1"])
    assert errors == [] and note is False
    assert [rid for rid, _ in bodies] == ["D1"]
    body = bodies[0][1]
    assert set(body) == {"name", "cron_expression", "enabled", "job_config", "mcp_connections",
                         "notifications"}
    # Pin the actual VALUE of every profile-derived field, not just its presence (F1, 2026-08-02
    # audit). Mutation testing proved forcing autofix_on_pr_create=False, environment_id, or model to
    # a wrong constant inside build_create_body() shipped green when this test only asserted
    # set(sc) == {...}. Expected literals below are the _raw_trigger() fixture's OWN defaults (see
    # its signature above) -- deliberately hardcoded here rather than recomputed via
    # rb._resolve_fields()/rb.derive_profile(), since re-deriving through the very functions under
    # test would be self-confirming and would not catch these mutants.
    assert body["name"] == "D1. Test Routine — deep research"
    assert body["enabled"] is True   # not just present -- pin the actual VALUE the fixture carries
    assert body["cron_expression"] == "0 16 * * *"
    assert body["mcp_connections"] == [
        {"connector_uuid": "u-fmp", "name": "FMP", "url": "https://fmp/mcp"},
        {"connector_uuid": "u-gh", "name": "Gmail", "url": "https://gmail/mcp"},
    ]
    assert body["notifications"] == {"channel": {"email": False, "push": False, "slack": False}}
    ccr = body["job_config"]["ccr"]
    assert set(ccr) == {"environment_id", "session_context", "events"}
    assert ccr["environment_id"] == "env_FLEET"
    sc = ccr["session_context"]
    assert set(sc) == {"model", "allowed_tools", "autofix_on_pr_create", "sources"}
    assert sc["model"] == "claude-opus-5"
    assert sc["allowed_tools"] == list(rb._FLEET_TOOLS)
    assert sc["autofix_on_pr_create"] is True
    assert sc["sources"] == [{"git_repository": {"url": rb.FLEET_REPO_URL}}]
    assert "outcomes" not in sc
    ev = ccr["events"]
    assert len(ev) == 1
    data = ev[0]["data"]
    assert set(data) == {"uuid", "session_id", "type", "parent_tool_use_id", "message"}
    assert data["session_id"] == "" and data["type"] == "user" and data["parent_tool_use_id"] is None
    assert data["message"] == {
        "content": f"Read Claude_Task_Plan.md. Perform D1. Test Routine — deep research.{ADDENDUM}",
        "role": "user",
    }
    assert data["message"] == {"content": body_instruction(body), "role": "user"}
    # no volatile fields anywhere in the body
    dumped = json.dumps(body)
    for f in ("next_run_at", "last_fired_at", "updated_at", "created_at", "ended_reason",
              "suspension_reason", "api_token_hint", "creator"):
        assert f not in dumped


def body_instruction(body):
    return body["job_config"]["ccr"]["events"][0]["data"]["message"]["content"]


def _write(tmp_path, name, obj):
    p = tmp_path / name
    p.write_text(json.dumps(obj))
    return p


def test_write_backup_uses_a_same_directory_atomic_replace(tmp_path, monkeypatch):
    _, _, _, backup = _wire(tmp_path, monkeypatch)
    seen = []
    real_replace = rb.os.replace

    def capture_replace(source, destination):
        seen.append((source, destination))
        assert os.path.dirname(source) == str(tmp_path)
        assert destination == str(backup)
        real_replace(source, destination)

    monkeypatch.setattr(rb.os, "replace", capture_replace)
    rb.write_backup({"_meta": {"atomic": True}, "profiles": {}, "routines": {}, "_unmatched": {}})
    assert seen
    assert json.loads(backup.read_text())["_meta"]["atomic"] is True
    assert not list(tmp_path.glob(f".{backup.name}.*.tmp"))


def test_restore_generates_a_fresh_uuid_each_call(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger()]})))

    bodies1, _, _ = rb.restore(["D1"])
    bodies2, _, _ = rb.restore(["D1"])
    uuid1 = bodies1[0][1]["job_config"]["ccr"]["events"][0]["data"]["uuid"]
    uuid2 = bodies2[0][1]["job_config"]["ccr"]["events"][0]["data"]["uuid"]
    assert uuid1 != uuid2
    # lowercase uuid4, valid on both
    for u in (uuid1, uuid2):
        assert u == u.lower()
        assert uuid.UUID(u).version == 4


def test_restore_no_args_restores_every_routine_and_notes_unmatched(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    infile = _write(tmp_path, "in.json", {"data": [
        _raw_trigger(),
        _raw_trigger(tid="trig_OPS2AAAA", name="OPS2. Catch-up Executor — regular routine",
                     content="Read Claude_Task_Plan.md. Perform OPS2. Catch-up Executor — regular routine."),
        _raw_trigger(tid="trig_MYSTERY", name="Mystery", content="totally unrelated"),
    ]})
    rb.ingest(str(infile))
    bodies, errors, note_unmatched = rb.restore([])
    assert sorted(rid for rid, _ in bodies) == ["D1", "OPS2"]
    assert errors == []
    assert note_unmatched is True   # _unmatched has the mystery trigger, and no ids were requested


def test_restore_explicit_ids_never_sets_unrestored_unmatched_note(tmp_path, monkeypatch):
    """has_unrestored_unmatched must depend on whether routine_ids was EMPTY (a 'restore all'), not
    merely on whether `_unmatched` happens to be non-empty (mutation gap 5) -- an explicit, targeted
    restore of D1 must never claim there's an unreviewed unmatched trigger sitting around unrestored,
    even though one genuinely exists in the backup."""
    _wire(tmp_path, monkeypatch)
    infile = _write(tmp_path, "in.json", {"data": [
        _raw_trigger(),
        _raw_trigger(tid="trig_MYSTERY", name="Mystery", content="totally unrelated"),
    ]})
    rb.ingest(str(infile))
    assert rb.load_backup()["_unmatched"]   # sanity: _unmatched is genuinely non-empty here
    bodies, errors, note_unmatched = rb.restore(["D1"])
    assert errors == []
    assert note_unmatched is False


def test_restore_unknown_routine_id_is_an_error_not_a_crash(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger()]})))
    bodies, errors, _ = rb.restore(["D1", "NOT_A_ROUTINE"])
    assert [rid for rid, _ in bodies] == ["D1"]
    assert len(errors) == 1 and "NOT_A_ROUTINE" in errors[0] and "not in" in errors[0]


def test_restore_can_restore_an_unmatched_entry_by_its_trigger_id(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    infile = _write(tmp_path, "in.json", {"data": [
        _raw_trigger(tid="trig_MYSTERY", name="Mystery", content="totally unrelated")]})
    rb.ingest(str(infile))
    bodies, errors, _ = rb.restore(["trig_MYSTERY"])
    assert errors == []
    assert bodies[0][0] == "trig_MYSTERY"
    assert bodies[0][1]["name"] == "Mystery"


# ---- _assemble_create_body: exactly one of cron_expression/run_once_at (B1) ---------------------------
_ASSEMBLE_KWARGS = {"name": "x", "enabled": True, "instruction": "i", "environment_id": "e", "model": "m",
                        "allowed_tools": [], "autofix_on_pr_create": True, "sources": [], "mcp_connections": []}


def test_assemble_create_body_rejects_both_cron_and_run_once_at():
    with pytest.raises(ValueError):
        rb._assemble_create_body(cron_expression="0 1 * * *", run_once_at="2099-01-01T00:00:00Z",
                                  **_ASSEMBLE_KWARGS)


def test_assemble_create_body_rejects_neither_cron_nor_run_once_at():
    with pytest.raises(ValueError):
        rb._assemble_create_body(**_ASSEMBLE_KWARGS)


def test_assemble_create_body_emits_only_cron_expression_key():
    body = rb._assemble_create_body(cron_expression="0 1 * * *", **_ASSEMBLE_KWARGS)
    assert body["cron_expression"] == "0 1 * * *"
    assert "run_once_at" not in body


def test_assemble_create_body_emits_only_run_once_at_key():
    body = rb._assemble_create_body(run_once_at="2099-01-01T00:00:00Z", **_ASSEMBLE_KWARGS)
    assert body["run_once_at"] == "2099-01-01T00:00:00Z"
    assert "cron_expression" not in body


# ---- restore(): one-shot (run_once_at) entries (B1) ----------------------------------------------------
def _one_shot_backup_doc(run_once_at, *, enabled=True):
    profiles = copy.deepcopy(TEST_PROFILES)
    return {
        "_meta": {}, "profiles": profiles,
        "routines": {
            "D1": {
                "trigger_id": "trig_D1AAAA", "name": "D1. Test Routine — deep research",
                "run_once_at": run_once_at, "enabled": enabled, "profile": "fleet",
                "instruction": (f"Read Claude_Task_Plan.md. Perform D1. Test Routine — deep "
                                 f"research.{ADDENDUM}"),
            },
        },
        "_unmatched": {},
    }


def test_build_create_body_emits_run_once_at_not_cron_for_a_one_shot_entry(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch, backup_doc=_one_shot_backup_doc("2099-01-01T12:00:00Z"))
    bodies, errors, _ = rb.restore(["D1"])
    assert errors == []
    body = bodies[0][1]
    assert body.get("run_once_at") == "2099-01-01T12:00:00Z"
    assert "cron_expression" not in body


def test_restore_rejects_past_run_once_at_with_nonzero_exit(tmp_path, monkeypatch, capsys):
    _wire(tmp_path, monkeypatch, backup_doc=_one_shot_backup_doc("2020-01-01T00:00:00Z"))
    monkeypatch.setattr("sys.argv", ["routine_backup.py", "restore", "D1"])
    assert rb.main() == 1
    err = capsys.readouterr().err
    assert "run_once_at" in err and "past" in err.lower()


def test_restore_rejects_malformed_run_once_at(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch, backup_doc=_one_shot_backup_doc("not-a-timestamp"))
    bodies, errors, _ = rb.restore(["D1"])
    assert bodies == []
    assert len(errors) == 1 and "timezone-qualified RFC3339" in errors[0]


def test_restore_no_warning_for_future_run_once_at(tmp_path, monkeypatch, capsys):
    _wire(tmp_path, monkeypatch, backup_doc=_one_shot_backup_doc("2099-01-01T00:00:00Z"))
    monkeypatch.setattr("sys.argv", ["routine_backup.py", "restore", "D1"])
    assert rb.main() == 0
    err = capsys.readouterr().err
    assert "past" not in err.lower()


# ---- restore(): CRON_UNCONFIRMED sentinel is a hard error, never a create body (B2) --------------------
def test_restore_errors_on_cron_unconfirmed_instead_of_emitting_an_invalid_body(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger(cron="")]})))
    assert rb.load_backup()["routines"]["D1"]["cron_expression"] == rb.CRON_UNCONFIRMED

    bodies, errors, _ = rb.restore(["D1"])
    assert bodies == []
    assert len(errors) == 1
    assert "D1" in errors[0] and rb.CRON_UNCONFIRMED in errors[0]


def test_main_restore_returns_nonzero_when_cron_unconfirmed(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger(cron="")]})))
    monkeypatch.setattr("sys.argv", ["routine_backup.py", "restore", "D1"])
    assert rb.main() == 1


# ---- restore(): a stale/missing profile reference is a graceful skip, never a crash (F2, 2026-08-02) --
def test_restore_handles_missing_profile_reference_gracefully(tmp_path, monkeypatch):
    """An entry whose `profile` no longer exists (real scenario: an older snapshot still saying 'sl'
    after that profile was retired, per ops/routine_backup.json's _meta) must not crash restore() with
    an uncaught KeyError from `profiles[entry["profile"]]` -- every other restore failure mode (unknown
    routine id, CRON_UNCONFIRMED) is already handled gracefully by skipping the entry and appending a
    clear message to `errors`; a missing profile must be handled the same way, naming both the routine
    and the missing profile."""
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger()]})))
    doc = rb.load_backup()
    doc["routines"]["D1"]["profile"] = "sl"
    rb.write_backup(doc)

    bodies, errors, _ = rb.restore(["D1"])
    assert bodies == []
    assert len(errors) == 1
    assert "D1" in errors[0] and "sl" in errors[0]


def test_main_restore_returns_nonzero_on_missing_profile(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger()]})))
    doc = rb.load_backup()
    doc["routines"]["D1"]["profile"] = "sl"
    rb.write_backup(doc)
    monkeypatch.setattr("sys.argv", ["routine_backup.py", "restore", "D1"])
    assert rb.main() == 1


# ---- OPS2 no-addendum special case, across ingest AND check -----------------------------------------
def test_ops2_instruction_has_no_addendum_after_ingest(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch)
    infile = _write(tmp_path, "in.json", {"data": [_raw_trigger(
        tid="trig_OPS2AAAA", name="OPS2. Catch-up Executor — regular routine",
        content="Read Claude_Task_Plan.md. Perform OPS2. Catch-up Executor — regular routine.")]})
    rb.ingest(str(infile))
    doc = rb.load_backup()
    assert doc["routines"]["OPS2"]["instruction"] == (
        "Read Claude_Task_Plan.md. Perform OPS2. Catch-up Executor — regular routine.")
    assert ADDENDUM not in doc["routines"]["OPS2"]["instruction"]


# ---- check(): the four validations + failure modes ---------------------------------------------------
def _good_backup_doc():
    profiles = copy.deepcopy(rb.DEFAULT_PROFILES)
    return {
        "_meta": {"last_ingested": "2026-08-01"},
        "profiles": profiles,
        "routines": {
            "D1": {
                "trigger_id": "trig_D1AAAA", "name": "D1. Test Routine — deep research",
                "cron_expression": "0 16 * * *", "enabled": True, "profile": "fleet",
                "instruction": ("Read Claude_Task_Plan.md. Perform D1. Test Routine — deep research."
                                + ADDENDUM),
            },
            "OPS2": {
                "trigger_id": "trig_OPS2AAAA", "name": "OPS2. Catch-up Executor — regular routine",
                "cron_expression": "0 4 * * *", "enabled": True, "profile": "fleet",
                "instruction": "Read Claude_Task_Plan.md. Perform OPS2. Catch-up Executor — regular routine.",
            },
        },
        "_unmatched": {},
    }


def test_check_ok_on_a_consistent_backup(tmp_path, monkeypatch, capsys):
    _wire(tmp_path, monkeypatch, backup_doc=_good_backup_doc())
    assert rb.check() == 0
    out = capsys.readouterr().out
    assert "ROUTINE BACKUP CHECK: OK" in out


def test_check_fails_when_backup_file_missing(tmp_path, monkeypatch, capsys):
    cadence, triggers, trigger_ids, backup = _wire(tmp_path, monkeypatch, backup_doc=None)
    assert not backup.exists()
    assert rb.check() == 1
    assert "does not exist" in capsys.readouterr().out


def test_check_fails_on_invalid_json(tmp_path, monkeypatch, capsys):
    _, _, _, backup = _wire(tmp_path, monkeypatch)
    backup.write_text("{not valid json")
    assert rb.check() == 1
    assert "not valid JSON" in capsys.readouterr().out


def test_check_fails_when_a_cadence_routine_is_missing_from_backup(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    del doc["routines"]["OPS2"]
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "OPS2: in ops/cadence.yaml but missing" in out


def test_check_fails_on_instruction_drift_for_a_normal_routine(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["instruction"] = "Read Claude_Task_Plan.md. Perform D1. WRONG TEXT." + ADDENDUM
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    assert "D1: instruction drift" in capsys.readouterr().out


def test_check_fails_when_a_normal_routine_is_missing_its_addendum(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["instruction"] = "Read Claude_Task_Plan.md. Perform D1. Test Routine — deep research."
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    assert "D1: instruction drift" in capsys.readouterr().out


def test_check_fails_when_ops2_incorrectly_carries_the_addendum(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["OPS2"]["instruction"] += ADDENDUM
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "OPS2: instruction drift" in out
    assert "NO addendum" in out


def test_check_fails_on_trigger_id_mismatch(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["trigger_id"] = "trig_WRONG_ID"
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    assert "D1: trigger_id mismatch" in capsys.readouterr().out


def test_check_fails_when_profile_does_not_exist(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["profile"] = "no_such_profile"
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "D1: profile 'no_such_profile' not in" in out


# ---- check(): profile existence checked for EVERY entry, not just cadence-known ones (mutation gap 6) --
def test_check_profile_existence_checked_for_non_cadence_entries_too(tmp_path, monkeypatch, capsys):
    """check()'s docstring claims profile existence is validated for ANY entry, not just ones
    ops/cadence.yaml knows about -- e.g. a 'personal_*' routine. A mutant that narrowed this check to
    cadence-known ids only would miss a broken profile reference on a non-cadence entry."""
    doc = _good_backup_doc()
    doc["routines"]["personal_extra"] = {
        "trigger_id": "trig_PERSONAL_X", "name": "Extra Personal", "cron_expression": "0 6 1 * *",
        "enabled": False, "profile": "no_such_profile", "instruction": "whatever",
    }
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "personal_extra: profile 'no_such_profile' not in" in out


# ---- check(): schedule shape -- exactly one of cron_expression/run_once_at (B1) -------------------------
def test_check_fails_when_entry_has_both_cron_and_run_once_at(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["run_once_at"] = "2099-01-01T00:00:00Z"   # cron_expression already present
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "D1" in out and "BOTH cron_expression and run_once_at" in out


def test_check_fails_when_entry_has_neither_cron_nor_run_once_at(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    del doc["routines"]["D1"]["cron_expression"]
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "D1" in out and "NEITHER cron_expression nor run_once_at" in out


def test_check_ok_when_entry_uses_run_once_at_instead_of_cron(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    del doc["routines"]["D1"]["cron_expression"]
    doc["routines"]["D1"]["run_once_at"] = "2099-01-01T00:00:00Z"
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 0
    assert "ROUTINE BACKUP CHECK: OK" in capsys.readouterr().out


# ---- check(): resolved (profile + overrides) fields must be real recovery data, not just present (B3) --
def test_check_catches_a_profile_wiped_by_an_empty_session_context(tmp_path, monkeypatch, capsys):
    """Reproduces the B3 bug directly through ingest(): a payload with session_context: {} (and no
    top-level mcp_connections) ingests into overrides of {"model": None, "allowed_tools": [],
    "environment_id": None, "sources": [], "mcp_connections": []} -- the OLD check() still printed OK,
    i.e. it blessed a snapshot whose actual recovery data is wiped."""
    _wire(tmp_path, monkeypatch)
    raw = _raw_trigger()
    raw["job_config"]["ccr"]["session_context"] = {}
    raw["job_config"]["ccr"]["environment_id"] = None
    raw["mcp_connections"] = []
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [raw]})))
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "ROUTINE BACKUP CHECK: FAIL" in out
    assert "environment_id" in out and "model" in out and "allowed_tools" in out


def test_check_fails_when_resolved_model_is_empty(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["overrides"] = {"model": ""}
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "D1: resolved model is missing/empty" in out


def test_check_fails_when_resolved_allowed_tools_is_empty(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["overrides"] = {"allowed_tools": []}
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "D1: resolved allowed_tools is missing/empty" in out


def test_check_fails_when_resolved_sources_is_empty(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["overrides"] = {"sources": []}
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "D1: resolved sources is missing/empty" in out


def test_check_fails_when_resolved_mcp_connections_is_empty(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["overrides"] = {"mcp_connections": []}
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "D1: resolved mcp_connections is missing/empty" in out


def test_check_fails_when_resolved_notifications_malformed(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["overrides"] = {
        "notifications": {"channel": {"email": "not-a-bool", "push": False, "slack": False}}}
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "D1: resolved notifications missing/malformed" in out


def test_check_fails_when_entry_name_is_empty(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["name"] = ""
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "D1: name is missing/empty" in out


def test_check_fails_when_a_fleet_cron_is_unconfirmed(tmp_path, monkeypatch, capsys):
    doc = _good_backup_doc()
    doc["routines"]["D1"]["cron_expression"] = rb.CRON_UNCONFIRMED
    _wire(tmp_path, monkeypatch, backup_doc=doc)
    assert rb.check() == 1
    out = capsys.readouterr().out
    assert "D1" in out and rb.CRON_UNCONFIRMED in out and "incomplete" in out


def test_check_rejects_malformed_one_shot_timestamp(tmp_path, monkeypatch, capsys):
    _wire(tmp_path, monkeypatch, backup_doc=_one_shot_backup_doc("not-a-timestamp"))
    assert rb.check() == 1
    assert "timezone-qualified RFC3339" in capsys.readouterr().out


# ---- CLI wiring (main()) -----------------------------------------------------------------------------
def test_main_check_subcommand_returns_checks_exit_code(tmp_path, monkeypatch):
    _wire(tmp_path, monkeypatch, backup_doc=_good_backup_doc())
    monkeypatch.setattr("sys.argv", ["routine_backup.py", "check"])
    assert rb.main() == 0


def test_main_ingest_subcommand(tmp_path, monkeypatch, capsys):
    _wire(tmp_path, monkeypatch)
    infile = _write(tmp_path, "in.json", {"data": [_raw_trigger()]})
    monkeypatch.setattr("sys.argv", ["routine_backup.py", "ingest", str(infile)])
    assert rb.main() == 0
    assert "1 added" in capsys.readouterr().out


def test_main_restore_subcommand_prints_bodies(tmp_path, monkeypatch, capsys):
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger()]})))
    monkeypatch.setattr("sys.argv", ["routine_backup.py", "restore", "D1"])
    assert rb.main() == 0
    out = capsys.readouterr().out
    assert "=== D1 ===" in out
    assert '"cron_expression": "0 16 * * *"' in out


# ---- main() propagates cmd_restore's real exit code (mutation gap 7) ----------------------------------
def test_main_restore_subcommand_returns_nonzero_on_unknown_routine_id(tmp_path, monkeypatch):
    """cmd_restore() must actually surface a failure through main()'s exit code -- a mutant that made
    cmd_restore always `return 0` regardless of errors would make this pass silently."""
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "in.json", {"data": [_raw_trigger()]})))
    monkeypatch.setattr("sys.argv", ["routine_backup.py", "restore", "NOT_A_ROUTINE"])
    assert rb.main() == 1


# ---- main() ingest subcommand surfaces a conflict loudly and non-zero (B5) ----------------------------
def test_main_ingest_returns_nonzero_and_prints_conflict(tmp_path, monkeypatch, capsys):
    _wire(tmp_path, monkeypatch)
    rb.ingest(str(_write(tmp_path, "first.json", {"data": [_raw_trigger()]})))
    conflicting = _raw_trigger(
        tid="trig_D1AAAA",
        content="Read Claude_Task_Plan.md. Perform OPS2. Catch-up Executor — regular routine."
                + ADDENDUM)
    infile2 = _write(tmp_path, "second.json", {"data": [conflicting]})
    monkeypatch.setattr("sys.argv", ["routine_backup.py", "ingest", str(infile2)])
    assert rb.main() == 1
    out = capsys.readouterr().out
    assert "CONFLICT" in out
    assert "trig_D1AAAA" in out and "'D1'" in out and "'OPS2'" in out
