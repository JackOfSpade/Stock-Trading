"""Guard scripts/check_settings_toolcov.py's own parsers (completeness-critic N-1, 2026-07-16).

Mirrors the style of tests/test_cadence_consistency.py / tests/test_script_version_consistency.py:
feed known-good and deliberately-drifted fixtures so a regex/JSON-shape change that makes the
checker stop matching is caught by CI instead of silently disarming the gate.

NOTE on the real repo: as of this test's introduction, Claude_Task_Plan.md references three mcp__
tools (`mcp__FMP__news`, `mcp__FMP__secFilings`, `mcp__Interactive_Brokers_IBKR__get_option_data`)
that are NOT yet in `.claude/settings.json`'s permissions.allow list — a genuine, currently-open gap
(see OWNER_ACTIONS.md). `scripts/check_settings_toolcov.py` is therefore EXPECTED to exit 1 against
the real repo today; this file does not assert a real-repo green (unlike
test_script_version_consistency.py's test_real_repo_is_consistent) because that would be asserting a
false thing. Once the owner adds those entries to settings.json, `python
scripts/check_settings_toolcov.py` should be re-run by hand to confirm it flips green; a future
session can then add a real-repo-green test here.
"""
import importlib.util
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "check_settings_toolcov.py")
    spec = importlib.util.spec_from_file_location("check_settings_toolcov", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


stc = _load()


def _write_fixtures(tmp_path, task_plan_text, triggers_text, settings_allow):
    task_plan = tmp_path / "Claude_Task_Plan.md"
    task_plan.write_text(task_plan_text)
    ops_dir = tmp_path / "ops"
    ops_dir.mkdir()
    triggers = ops_dir / "triggers.json"
    triggers.write_text(triggers_text)
    claude_dir = tmp_path / ".claude"
    claude_dir.mkdir()
    settings = claude_dir / "settings.json"
    settings.write_text(json.dumps({"permissions": {"allow": settings_allow}}))
    return task_plan, triggers, settings


def test_mcp_token_regex_matches_known_shapes():
    line = "Pull the contract's daily premium via `mcp__Interactive_Brokers_IBKR__get_option_data`."
    assert stc.MCP_TOKEN.findall(line) == ["mcp__Interactive_Brokers_IBKR__get_option_data"]


def test_all_referenced_tools_covered_is_green(tmp_path, monkeypatch):
    task_plan, triggers, settings = _write_fixtures(
        tmp_path,
        "calls `mcp__FMP__quote` and `mcp__FMP__chart`\n",
        "{}",
        ["mcp__FMP__quote", "mcp__FMP__chart"],
    )
    monkeypatch.setattr(stc, "TASK_PLAN", str(task_plan))
    monkeypatch.setattr(stc, "TRIGGERS_JSON", str(triggers))
    monkeypatch.setattr(stc, "SOURCES", (str(task_plan), str(triggers)))
    monkeypatch.setattr(stc, "SETTINGS_JSON", str(settings))
    assert stc.main() == 0


def test_missing_required_source_fails_closed(tmp_path, monkeypatch, capsys):
    # #15 (2026-07-17 audit): a required SOURCES file that stops resolving (renamed/moved doc, drifted
    # path constant) must FAIL the gate, not silently shrink the scanned set to 0 refs and print OK.
    task_plan, triggers, settings = _write_fixtures(
        tmp_path, "calls `mcp__FMP__quote`\n", "{}", ["mcp__FMP__quote"],
    )
    ghost = tmp_path / "does_not_exist_Claude_Task_Plan.md"
    monkeypatch.setattr(stc, "TASK_PLAN", str(ghost))
    monkeypatch.setattr(stc, "TRIGGERS_JSON", str(triggers))
    monkeypatch.setattr(stc, "SOURCES", (str(ghost), str(triggers)))
    monkeypatch.setattr(stc, "SETTINGS_JSON", str(settings))
    assert stc.main() == 1
    out = capsys.readouterr().out
    assert "FAIL" in out and "not found" in out


def test_missing_tool_is_caught(tmp_path, monkeypatch, capsys):
    task_plan, triggers, settings = _write_fixtures(
        tmp_path,
        "calls `mcp__FMP__quote` and `mcp__Interactive_Brokers_IBKR__get_option_data`\n",
        "{}",
        ["mcp__FMP__quote"],
    )
    monkeypatch.setattr(stc, "TASK_PLAN", str(task_plan))
    monkeypatch.setattr(stc, "TRIGGERS_JSON", str(triggers))
    monkeypatch.setattr(stc, "SOURCES", (str(task_plan), str(triggers)))
    monkeypatch.setattr(stc, "SETTINGS_JSON", str(settings))
    assert stc.main() == 1
    out = capsys.readouterr().out
    assert "mcp__Interactive_Brokers_IBKR__get_option_data" in out
    assert "Claude_Task_Plan.md:1" in out


def test_reference_in_triggers_json_also_checked(tmp_path, monkeypatch):
    task_plan, triggers, settings = _write_fixtures(
        tmp_path,
        "no tools referenced here\n",
        '{"D1": "calls mcp__FMP__news for headlines"}\n',
        [],
    )
    monkeypatch.setattr(stc, "TASK_PLAN", str(task_plan))
    monkeypatch.setattr(stc, "TRIGGERS_JSON", str(triggers))
    monkeypatch.setattr(stc, "SOURCES", (str(task_plan), str(triggers)))
    monkeypatch.setattr(stc, "SETTINGS_JSON", str(settings))
    assert stc.main() == 1


def test_non_tool_permission_strings_ignored_in_allowlist(tmp_path, monkeypatch):
    # A future Bash(...) or other non-mcp__ permission entry must not be mistaken for tool coverage.
    task_plan, triggers, settings = _write_fixtures(
        tmp_path,
        "calls `mcp__FMP__quote`\n",
        "{}",
        ["mcp__FMP__quote", "Bash(git status:*)"],
    )
    monkeypatch.setattr(stc, "TASK_PLAN", str(task_plan))
    monkeypatch.setattr(stc, "TRIGGERS_JSON", str(triggers))
    monkeypatch.setattr(stc, "SOURCES", (str(task_plan), str(triggers)))
    monkeypatch.setattr(stc, "SETTINGS_JSON", str(settings))
    assert stc.main() == 0
