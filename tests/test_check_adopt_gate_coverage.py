"""Guard scripts/check_adopt_gate_coverage.py -- the OPS0 STEP 4d precondition-5 drift checker.

Regression coverage for ops0_adopt_gate_drift (2026-08-20): precondition 5's hand-kept list of
ci.yml `checks`-job steps had silently fallen six scripts behind ci.yml itself (check_cadence_
marker.py, routine_backup.py, check_cron_dst_safety.py, check_sq_version_registry.py,
check_superseded_by_discipline.py, check_connector_tools.py), which meant OPS0's ADOPT path could
merge a stranded branch onto main after running a weaker local gate than CI would apply. Every
test here builds its own synthetic ci.yml + Claude_Task_Plan.md excerpt in tmp_path and
monkeypatches cs.CI_YML / cs.TASK_PLAN -- nothing reads or writes the real repo files except the
one "real repo passes" test, same convention as the other check_*.py test files in this directory.
"""
import yaml

from conftest import load_module_from_path

cs = load_module_from_path("check_adopt_gate_coverage", "scripts", "check_adopt_gate_coverage.py")

PARA = (
    "5. **THE LOCAL CHECK SUITE PASSES ON THE RESOLUTION.** Run these: "
    "`{scripts}`.\n"
    "6. **PUSH IMMEDIATELY once 1-5 pass** -- do not hold the adoption to session end.\n"
)


def write_ci_yml(tmp_path, steps):
    doc = {
        "name": "CI",
        "on": {"push": None},
        "jobs": {"checks": {"name": "checks", "runs-on": "ubuntu-latest", "steps": steps}},
    }
    path = tmp_path / "ci.yml"
    path.write_text(yaml.dump(doc, sort_keys=False))
    return path


def write_task_plan(tmp_path, script_mentions):
    path = tmp_path / "Claude_Task_Plan.md"
    path.write_text(PARA.format(scripts="`; `".join(script_mentions)))
    return path


def wire(tmp_path, monkeypatch, steps, script_mentions):
    ci = write_ci_yml(tmp_path, steps)
    plan = write_task_plan(tmp_path, script_mentions)
    monkeypatch.setattr(cs, "CI_YML", str(ci))
    monkeypatch.setattr(cs, "TASK_PLAN", str(plan))


# ---- the actual regression: a blocking script absent from the prose list ----------------------

def test_blocking_script_missing_from_prose_is_caught(tmp_path, monkeypatch, capsys):
    wire(
        tmp_path, monkeypatch,
        steps=[
            {"name": "cadence-output first-line period markers",
             "run": "python scripts/check_cadence_marker.py"},
        ],
        script_mentions=["check_cadence_consistency.py"],  # check_cadence_marker.py NOT mentioned
    )
    assert cs.main() == 1
    err = capsys.readouterr().out
    assert "check_cadence_marker.py" in err
    assert "FAIL" in err


def test_script_present_in_prose_passes(tmp_path, monkeypatch):
    wire(
        tmp_path, monkeypatch,
        steps=[
            {"name": "cadence-output first-line period markers",
             "run": "python scripts/check_cadence_marker.py"},
        ],
        script_mentions=["check_cadence_marker.py"],
    )
    assert cs.main() == 0


def test_six_script_regression_shape_all_caught_together(tmp_path, monkeypatch, capsys):
    # Reproduces the exact 2026-08-20 gap: six blocking steps, prose mentions none of them.
    six = [
        "check_cadence_marker.py", "routine_backup.py", "check_cron_dst_safety.py",
        "check_sq_version_registry.py", "check_superseded_by_discipline.py",
        "check_connector_tools.py",
    ]
    wire(
        tmp_path, monkeypatch,
        steps=[{"name": f"step for {s}", "run": f"python scripts/{s}"} for s in six],
        script_mentions=["check_roster_consistency.py"],  # unrelated, none of the six
    )
    assert cs.main() == 1
    out = capsys.readouterr().out
    for s in six:
        assert s in out


# ---- correctly-excluded step shapes ------------------------------------------------------------

def test_continue_on_error_step_is_not_required(tmp_path, monkeypatch):
    # Mirrors ci.yml's "ruff check" step: advisory in ci.yml itself, so precondition 5 omitting
    # it does not weaken the local gate relative to what CI enforces.
    wire(
        tmp_path, monkeypatch,
        steps=[{"name": "ruff check", "run": "python scripts/ruff_shim.py",
                "continue-on-error": True}],
        script_mentions=[],
    )
    assert cs.main() == 0


def test_shell_fallback_line_is_not_required(tmp_path, monkeypatch):
    # Mirrors ci.yml's "dbt view coverage" step: `|| true` makes the step always pass.
    wire(
        tmp_path, monkeypatch,
        steps=[{"name": "dbt view coverage",
                "run": "python scripts/check_dbt_view_coverage.py || true"}],
        script_mentions=[],
    )
    assert cs.main() == 0


def test_act_local_only_step_is_not_required(tmp_path, monkeypatch):
    # Mirrors ci.yml's "Install shellcheck (act-local CI only)" step: never runs on a real
    # GitHub-hosted run, so it must not be treated as a real blocking gate.
    wire(
        tmp_path, monkeypatch,
        steps=[{"name": "Install shellcheck (act-local CI only)",
                "run": "python scripts/would_never_run_on_hosted_ci.py",
                "if": "${{ env.ACT == 'true' }}"}],
        script_mentions=[],
    )
    assert cs.main() == 0


def test_step_with_no_run_key_is_ignored(tmp_path, monkeypatch):
    # A pure `uses:` step (checkout, setup-python, actions/cache) names no script at all.
    wire(tmp_path, monkeypatch, steps=[{"name": "checkout", "uses": "actions/checkout@v7"}],
         script_mentions=[])
    assert cs.main() == 0


def test_dbt_deps_and_parse_step_names_no_candidate(tmp_path, monkeypatch):
    # dbt parse is intentionally absent from precondition 5 (dbt not installed in the routine
    # container; precondition 2 hard-excludes bigquery/**+dbt/** from ADOPT). Its run: body names
    # no .py/.sh/.js target, so this checker must not flag it either -- both guards should agree
    # by construction, not by hardcoding an exemption for this one step.
    wire(
        tmp_path, monkeypatch,
        steps=[{"name": "dbt deps + parse", "run": "dbt deps\ndbt parse"}],
        script_mentions=[],
    )
    assert cs.main() == 0


# ---- non-script targets: pytest and the three former shell-lint steps -------------------------

def test_pytest_invocation_matches_bare_keyword(tmp_path, monkeypatch):
    wire(
        tmp_path, monkeypatch,
        steps=[{"name": "pytest regression suite", "run": "python -m pytest -q"}],
        script_mentions=["pytest"],
    )
    assert cs.main() == 0


def test_lint_steps_matched_by_name_keyword(tmp_path, monkeypatch):
    wire(
        tmp_path, monkeypatch,
        steps=[
            {"name": "actionlint (workflow YAML + embedded run-block bash via shellcheck)",
             "run": "./actionlint -color"},
            {"name": "shellcheck standalone scripts (warning+ blocks)",
             "run": "shellcheck -S warning file.sh"},
            {"name": "workflow_run trigger names stay in sync (auto-merge-claude.yml <-> ci.yml)",
             "run": "echo checking workflow_run triggers"},
        ],
        script_mentions=["actionlint", "shellcheck -S warning", "workflow_run"],
    )
    assert cs.main() == 0


def test_lint_step_missing_from_prose_is_caught(tmp_path, monkeypatch, capsys):
    wire(
        tmp_path, monkeypatch,
        steps=[{"name": "shellcheck standalone scripts (warning+ blocks)",
                "run": "shellcheck -S warning file.sh"}],
        script_mentions=["actionlint"],  # shellcheck keyword not mentioned
    )
    assert cs.main() == 1
    assert "shellcheck" in capsys.readouterr().out


# ---- anchor integrity -----------------------------------------------------------------------

def test_missing_paragraph_anchor_fails_loudly(tmp_path, monkeypatch, capsys):
    ci = write_ci_yml(tmp_path, steps=[])
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text("this file no longer contains the precondition-5 anchors at all\n")
    monkeypatch.setattr(cs, "CI_YML", str(ci))
    monkeypatch.setattr(cs, "TASK_PLAN", str(plan))
    assert cs.main() == 1
    assert "could not locate precondition 5" in capsys.readouterr().out


# ---- the real repo must satisfy its own contract -----------------------------------------------

def test_real_repo_passes_the_adopt_gate_coverage_check():
    # Read-only: no monkeypatch, so this exercises the real CI_YML/TASK_PLAN paths exactly as CI
    # runs it. If this starts failing, precondition 5's prose is missing a real ci.yml step --
    # fix the prose, not this test.
    assert cs.main() == 0
