"""Guard scripts/check_connector_tools.py's own parsers (2026-08-08, connector-tool manifest gate).

Mirrors the style of tests/test_settings_toolcov.py: feed known-good and deliberately-drifted fixtures
so a regex/YAML-shape change that makes the checker stop matching is caught by CI instead of silently
disarming the gate. Every assertion is on main()'s RETURN VALUE, never on stdout as the primary signal
(capsys checks below are secondary/diagnostic only).

HISTORICAL NOTE on the real repo (see test_real_repo_connector_tools_is_consistent at the bottom): at
this checker's introduction (2026-08-08) the real repo still carried some of the drift this checker
exists to catch (a dead `paper_search` call site, a stale allowlist entry, a couple of manifest/
routine-text disagreements), and that test asserted == 0 against a then-failing repo deliberately --
see its own docstring for the enumerated gaps. All of them have since been closed: the checker now
exits 0 against the committed files and that test is a standing green regression lock. Do NOT weaken
this file's checks to keep it green; fix the underlying files instead.
"""
import copy
import json

import yaml

from conftest import load_module_from_path

cct = load_module_from_path("check_connector_tools", "scripts", "check_connector_tools.py")


def _write_fixtures(tmp_path, manifest_doc, task_plan_text, settings_allow):
    manifest_path = tmp_path / "connector_tools.yaml"
    manifest_path.write_text(yaml.dump(manifest_doc, sort_keys=False))
    task_plan = tmp_path / "Claude_Task_Plan.md"
    task_plan.write_text(task_plan_text)
    claude_dir = tmp_path / ".claude"
    claude_dir.mkdir()
    settings = claude_dir / "settings.json"
    settings.write_text(json.dumps({"permissions": {"allow": settings_allow}}))
    return manifest_path, task_plan, settings


def _patch(monkeypatch, manifest_path, task_plan, settings):
    monkeypatch.setattr(cct, "MANIFEST", str(manifest_path))
    monkeypatch.setattr(cct, "TASK_PLAN", str(task_plan))
    monkeypatch.setattr(cct, "SETTINGS_JSON", str(settings))


def _base_manifest():
    """A clean, internally-consistent two-connector manifest. Tests deep-copy this and mutate one
    piece at a time so an unrelated check never trips alongside the one under test."""
    return {
        "connectors": [
            {
                "name": "FMP",
                "connector_uuid": "uuid-fmp",
                "settings_prefix": "mcp__FMP__",
                "tools": [
                    {"name": "chart", "use": "required", "prose_ambiguous": True,
                     "note": "OPS1 liveness probe"},
                    {"name": "search", "use": "unused", "prose_ambiguous": True},
                    {"name": "Fundraisers", "use": "unused"},
                ],
                "absent": [
                    {"name": "old_tool", "verified": "2026-01-01", "note": "retired by vendor"},
                ],
            },
            {
                "name": "Gmail",
                "connector_uuid": "uuid-gmail",
                "settings_prefix": "mcp__Gmail__",
                "tools": [
                    {"name": "list_labels", "use": "required", "note": "OPS1 probe"},
                    {"name": "get_message", "use": "unused"},
                ],
                "absent": [],
            },
        ]
    }


def _base_allow():
    return ["mcp__FMP__chart", "mcp__Gmail__list_labels"]


# ---------------------------------------------------------------------------------------------------
# Green case
# ---------------------------------------------------------------------------------------------------

def test_green_manifest_is_consistent(tmp_path, monkeypatch):
    task_plan = "D1 probes FMP `chart` and Gmail `list_labels` every morning.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 0


def test_ok_summary_names_counts(tmp_path, monkeypatch, capsys):
    task_plan = "no tool references here\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 0
    out = capsys.readouterr().out
    assert "CONNECTOR TOOLS: OK" in out
    assert "2 connectors" in out
    assert "5 tools" in out
    assert "2 required" in out


# ---------------------------------------------------------------------------------------------------
# CHECK 1 -- manifest internal validity
# ---------------------------------------------------------------------------------------------------

def test_check1_missing_required_field_fails(tmp_path, monkeypatch, capsys):
    doc = copy.deepcopy(_base_manifest())
    del doc["connectors"][0]["connector_uuid"]
    manifest_path, task_plan_path, settings = _write_fixtures(tmp_path, doc, "no refs\n", _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK1" in out and "connector_uuid" in out


def test_check1_invalid_use_value_fails(tmp_path, monkeypatch, capsys):
    doc = copy.deepcopy(_base_manifest())
    doc["connectors"][0]["tools"][0]["use"] = "sometimes"
    manifest_path, task_plan_path, settings = _write_fixtures(tmp_path, doc, "no refs\n", _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK1" in out and "invalid `use`" in out


def test_check1_duplicate_tool_name_fails(tmp_path, monkeypatch, capsys):
    doc = copy.deepcopy(_base_manifest())
    doc["connectors"][0]["tools"].append({"name": "chart", "use": "unused"})
    manifest_path, task_plan_path, settings = _write_fixtures(tmp_path, doc, "no refs\n", _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK1" in out and "2 times" in out


def test_check1_tool_in_both_tools_and_absent_fails(tmp_path, monkeypatch, capsys):
    doc = copy.deepcopy(_base_manifest())
    doc["connectors"][0]["absent"].append({"name": "chart", "verified": "2026-01-01"})
    manifest_path, task_plan_path, settings = _write_fixtures(tmp_path, doc, "no refs\n", _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK1" in out and "BOTH `tools` and `absent`" in out


def test_check1_null_tools_key_fails(tmp_path, monkeypatch, capsys):
    """REGRESSION (2026-09-02). A present-but-null `tools:` key (a hand-edit that deletes every list
    item but leaves the bare key) used to satisfy `"tools" not in c` and pass CHECK1 silently: `tools
    = c.get("tools")` came back None, the `tools is not None` type-check guard never fired, and
    `tools = tools or []` quietly turned it into an empty list -- the connector's entire tool set,
    including anything `use: required`, vanished from CHECK2's allowlist-coverage check with no
    diagnostic anywhere. Against the OLD `"tools" not in c` test this fixture returns 0 (bug); the
    NEW `not c.get("tools")` test must return 1 and name the connector's missing `tools`."""
    doc = copy.deepcopy(_base_manifest())
    doc["connectors"][0]["tools"] = None
    manifest_path, task_plan_path, settings = _write_fixtures(tmp_path, doc, "no refs\n", _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK1" in out and "missing required field `tools`" in out


def test_check1_absent_entry_with_no_name_fails(tmp_path, monkeypatch, capsys):
    """REGRESSION (2026-09-02). The `tools` loop has always flagged an entry with no `name` (a
    `nam:` typo, say); the sibling `absent` list had no equivalent check -- such an entry was simply
    dropped from `absent_names` by the set-comprehension with zero findings raised. That mattered
    because CHECK4 (the retired-tool gate) is built from this same list: a typo'd `absent:` entry
    didn't just fail to record a retirement, it made CHECK4 structurally unable to ever catch a
    routine calling that retired tool again -- with the manifest itself looking clean. Against the
    old code this fixture returns 0 (bug, and the retired tool is invisible to CHECK4 too); the new
    code must return 1 and name the connector's `absent` entry."""
    doc = copy.deepcopy(_base_manifest())
    doc["connectors"][0]["absent"].append({"verified": "2026-01-01", "note": "typo'd name key"})
    manifest_path, task_plan_path, settings = _write_fixtures(tmp_path, doc, "no refs\n", _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK1" in out and "`absent` entry with no `name`" in out


def test_check1_overlapping_settings_prefix_fails(tmp_path, monkeypatch, capsys):
    """REGRESSION (2026-09-02). resolve_full_token() and check5_stale_allowlist() both walk
    connectors in manifest order and return on the FIRST `settings_prefix` that is a string-prefix
    of a token, on the explicit assumption prefixes never overlap. CHECK1 never verified that
    assumption. A new connector declaring `mcp__Gm` -- a proper prefix of Gmail's existing
    `mcp__Gmail__` -- must be caught here, regardless of which one is shorter or where either sits
    in manifest order."""
    doc = copy.deepcopy(_base_manifest())
    doc["connectors"].append({
        "name": "GmailShort",
        "connector_uuid": "uuid-gmail-short",
        "settings_prefix": "mcp__Gm",  # a proper prefix of Gmail's mcp__Gmail__
        "tools": [{"name": "probe", "use": "unused"}],
        "absent": [],
    })
    manifest_path, task_plan_path, settings = _write_fixtures(tmp_path, doc, "no refs\n", _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK1" in out and "proper prefix" in out and "GmailShort" in out and "Gmail" in out


def test_check1_identical_settings_prefix_fails(tmp_path, monkeypatch, capsys):
    doc = copy.deepcopy(_base_manifest())
    doc["connectors"].append({
        "name": "FMP2",
        "connector_uuid": "uuid-fmp2",
        "settings_prefix": "mcp__FMP__",  # identical to the existing FMP connector's
        "tools": [{"name": "probe", "use": "unused"}],
        "absent": [],
    })
    manifest_path, task_plan_path, settings = _write_fixtures(tmp_path, doc, "no refs\n", _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK1" in out and "IDENTICAL" in out and "FMP2" in out


# ---------------------------------------------------------------------------------------------------
# CHECK 2 -- required tools must be allowlisted (exact-string match only)
# ---------------------------------------------------------------------------------------------------

def test_check2_required_tool_missing_from_allowlist_fails(tmp_path, monkeypatch, capsys):
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), "no refs\n", ["mcp__FMP__chart"])  # Gmail list_labels omitted
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK2" in out and "mcp__Gmail__list_labels" in out


def test_check2_wildcard_allow_entry_does_not_cover_required_tool(tmp_path, monkeypatch, capsys):
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), "no refs\n", ["mcp__FMP__*", "mcp__Gmail__*"])
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "exact-string match only" in out


# ---------------------------------------------------------------------------------------------------
# CHECK 3 -- routine text calls only declared tools
# ---------------------------------------------------------------------------------------------------

def test_check3_bare_name_use_mismatch_fails(tmp_path, monkeypatch, capsys):
    # `Fundraisers` is declared `use: unused` (not prose_ambiguous) -- calling it bare is a finding.
    task_plan = "D1 pulls `Fundraisers` data for the screen.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK3" in out and "Fundraisers" in out and "Claude_Task_Plan.md:1" in out


def test_check3_full_token_use_mismatch_fails(tmp_path, monkeypatch, capsys):
    task_plan = "D1 pulls `mcp__FMP__Fundraisers` data for the screen.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK3" in out and "mcp__FMP__Fundraisers" in out


def test_check3_prose_ambiguous_bare_name_is_skipped(tmp_path, monkeypatch):
    # `search` is use: unused AND prose_ambiguous: true -- a bare mention must NOT be flagged.
    task_plan = "Use `search` carefully when reading a document.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 0


def test_check3_prose_ambiguous_full_form_is_still_checked(tmp_path, monkeypatch, capsys):
    # Same tool, but in FULL mcp__ form -- prose_ambiguous does NOT exempt the qualified token.
    task_plan = "Use `mcp__FMP__search` here.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK3" in out and "mcp__FMP__search" in out


def test_check3_ambiguous_across_connectors_is_non_fatal(tmp_path, monkeypatch, capsys):
    doc = copy.deepcopy(_base_manifest())
    # Both connectors now declare a tool literally named "probe" -- an unqualified bare mention
    # cannot be resolved to one connector, so it must be skipped (non-fatal), not hard-failed even
    # though one of the two declarations is `use: unused`.
    doc["connectors"][0]["tools"].append({"name": "probe", "use": "unused"})
    doc["connectors"][1]["tools"].append({"name": "probe", "use": "required"})
    task_plan = "Run `probe` before anything else.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, doc, task_plan, [*_base_allow(), "mcp__Gmail__probe"])
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 0
    out = capsys.readouterr().out
    assert "ambiguous across connectors" in out.lower() or "Ambiguous across connectors" in out


# ---------------------------------------------------------------------------------------------------
# CHECK 4 -- no routine text calls an absent tool (hard failure)
# ---------------------------------------------------------------------------------------------------

def test_check4_bare_absent_reference_fails(tmp_path, monkeypatch, capsys):
    task_plan = "The old flow used `old_tool` for this.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK4" in out and "old_tool" in out and "retired by vendor" in out


def test_check4_bare_name_live_in_another_connector_is_non_fatal(tmp_path, monkeypatch, capsys):
    """REGRESSION (quality pass 2026-08-22). A bare name that is RETIRED in one connector but still
    LIVE-declared by a DIFFERENT one is the same cross-connector ambiguity CHECK 3 already handles
    as a non-fatal note -- CHECK 4 had no such guard and hard-failed CI on it. A routine
    legitimately calling Gmail's live `old_tool` was reported as "references RETIRED tool" (FMP's),
    forcing a bogus routine-text rewrite over a name FMP retired.

    Dormant on the real manifest (verified: 114 declared names, 5 absent names, zero overlap), but
    OPS1's AUTO-ADD branch adds new connector tools BY BARE NAME, so the first generic-sounding
    name a vendor ships that collides with another vendor's retired name lands on it.

    Reported, not silently skipped: the ambiguity still reaches a human as a non-fatal note,
    because it is not safe to just assume the live connector was the intended one."""
    manifest = copy.deepcopy(_base_manifest())
    # Gmail now declares a LIVE `old_tool`; FMP still lists it as absent.
    manifest["connectors"][1]["tools"].append({"name": "old_tool", "use": "required"})
    task_plan = "D1 calls Gmail's `old_tool` for this.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, manifest, task_plan, [*_base_allow(), "mcp__Gmail__old_tool"])
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 0, "a name live in another connector must not be a hard CHECK4 failure"
    out = capsys.readouterr().out
    assert "old_tool" in out and "non-fatal" in out
    assert "CHECK4:" not in out


def test_check4_still_fails_when_the_name_is_retired_everywhere(tmp_path, monkeypatch, capsys):
    """The guard must not weaken the gate: with no live declaration of the name anywhere, a
    retired-tool reference is still a hard CHECK4 failure. (This is the same assertion as
    test_check4_bare_absent_reference_fails, pinned again right beside the new exemption so a
    future widening of that exemption cannot quietly swallow the base case.)"""
    task_plan = "The old flow used `old_tool` for this.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    assert "CHECK4" in capsys.readouterr().out


def test_check4_full_token_absent_reference_fails(tmp_path, monkeypatch, capsys):
    task_plan = "The old flow used `mcp__FMP__old_tool` for this.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK4" in out and "mcp__FMP__old_tool" in out


# ---------------------------------------------------------------------------------------------------
# Ignore fence -- CHECKS 3 & 4 skip fenced lines
# ---------------------------------------------------------------------------------------------------

def test_ignore_fence_suppresses_check3_and_check4(tmp_path, monkeypatch):
    task_plan = (
        "<!-- connector-tools-checker: ignore-start -->\n"
        "Historical note: `old_tool` no longer exists; `Fundraisers` used to be called here too.\n"
        "<!-- connector-tools-checker: ignore-end -->\n"
        "Live text after the fence is unaffected.\n"
    )
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 0


def test_reference_outside_fence_still_fails(tmp_path, monkeypatch):
    # Sanity check on the fence test above: the SAME reference OUTSIDE the fence must still fail,
    # proving the green result above came from the fence and not from a broken absent-index lookup.
    task_plan = "Live text calls `old_tool` directly, no fence anywhere.\n"
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), task_plan, _base_allow())
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1


# ---------------------------------------------------------------------------------------------------
# CHECK 5 -- no stale allowlist entries
# ---------------------------------------------------------------------------------------------------

def test_check5_unexplained_stale_entry_fails(tmp_path, monkeypatch, capsys):
    allow = [*_base_allow(), "mcp__Gmail__ghost_tool"]  # not in tools, not in absent
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), "no refs\n", allow)
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK5" in out and "ghost_tool" in out and "not recorded as `absent`" in out


def test_check5_stale_entry_explained_by_verified_absent_is_hard_fail(tmp_path, monkeypatch, capsys):
    allow = [*_base_allow(), "mcp__FMP__old_tool"]  # matches the absent record, verified (not unconfirmed)
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), "no refs\n", allow)
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "CHECK5" in out and "mcp__FMP__old_tool" in out and "is stale" in out


def test_check5_verified_unconfirmed_is_non_fatal(tmp_path, monkeypatch, capsys):
    doc = copy.deepcopy(_base_manifest())
    doc["connectors"][0]["absent"].append(
        {"name": "maybe_gone_tool", "verified": "unconfirmed", "note": "pending OPS1 confirmation"})
    allow = [*_base_allow(), "mcp__FMP__maybe_gone_tool"]
    manifest_path, task_plan_path, settings = _write_fixtures(tmp_path, doc, "no refs\n", allow)
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 0
    out = capsys.readouterr().out
    assert "maybe_gone_tool" in out and "report-only" in out.lower()


def test_check5_entry_with_no_matching_connector_prefix_is_out_of_scope(tmp_path, monkeypatch, capsys):
    # A connector this manifest simply does not track (e.g. Claude Code's own RemoteTrigger surface)
    # must not be reported at all -- only entries under a KNOWN manifest connector prefix are checked.
    allow = [*_base_allow(), "mcp__Claude_Code_Remote__list_triggers"]
    manifest_path, task_plan_path, settings = _write_fixtures(
        tmp_path, _base_manifest(), "no refs\n", allow)
    _patch(monkeypatch, manifest_path, task_plan_path, settings)
    assert cct.main() == 0
    out = capsys.readouterr().out
    assert "Claude_Code_Remote" not in out


# ---------------------------------------------------------------------------------------------------
# Fail-closed on missing inputs
# ---------------------------------------------------------------------------------------------------

def test_missing_manifest_fails_closed(tmp_path, monkeypatch, capsys):
    _, task_plan_path, settings = _write_fixtures(tmp_path, _base_manifest(), "no refs\n", _base_allow())
    ghost = tmp_path / "does_not_exist_connector_tools.yaml"
    _patch(monkeypatch, ghost, task_plan_path, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "FAIL" in out and "not found" in out


def test_missing_task_plan_fails_closed(tmp_path, monkeypatch, capsys):
    manifest_path, _, settings = _write_fixtures(tmp_path, _base_manifest(), "no refs\n", _base_allow())
    ghost = tmp_path / "does_not_exist_Claude_Task_Plan.md"
    _patch(monkeypatch, manifest_path, ghost, settings)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "FAIL" in out and "not found" in out


def test_missing_settings_json_fails_closed(tmp_path, monkeypatch, capsys):
    manifest_path, task_plan_path, _ = _write_fixtures(tmp_path, _base_manifest(), "no refs\n", _base_allow())
    ghost = tmp_path / "does_not_exist" / "settings.json"
    _patch(monkeypatch, manifest_path, task_plan_path, ghost)
    assert cct.main() == 1
    out = capsys.readouterr().out
    assert "FAIL" in out and "not found" in out


# ---------------------------------------------------------------------------------------------------
# Real repo
# ---------------------------------------------------------------------------------------------------

def test_real_repo_connector_tools_is_consistent():
    """The checker must exit 0 against the committed repo files (no monkeypatching).

    HISTORY: at this checker's introduction (2026-08-08) the real repo had NOT yet closed every gap the
    checker is designed to catch, and this assertion was written red-on-purpose against these three:
      - CHECK4: Claude_Task_Plan.md instructed a Hugging Face `paper_search` call (D1 ~line 700,
        SL1 ~line 2848) and mentioned `space_search` outside any exemption, even though
        ops/connector_tools.yaml recorded both as `absent` (paper_search verified 2026-07-28;
        space_search unconfirmed).
      - CHECK5: .claude/settings.json still allowlisted `mcp__Hugging_Face__paper_search`, which the
        manifest recorded as verified-absent -- a stale grant.
      - CHECK3: D2a's Step 0b (~line 1257) actively called `get_pa_performance_all_periods` (IBKR)
        while the manifest still declared it `use: unused`; the FMP tier-gating discussion at
        ~line 1336 mentioned `etfAndMutualFunds` without `prose_ambiguous: true`, unlike its sibling
        tier-gated tokens on the same line.
    All three have since been closed (the remaining paper_search/space_search mentions in
    Claude_Task_Plan.md are retirement prose the checker passes over; the manifest now records
    `use: required`; the stale allowlist entry is gone), so this is now a standing GREEN lock rather
    than a known-failing aspiration. Do NOT weaken check_connector_tools.py to keep this assertion
    passing -- fix the underlying manifest/routine-text/allowlist files instead.
    """
    assert cct.main() == 0
