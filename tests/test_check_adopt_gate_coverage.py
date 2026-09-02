"""Guard scripts/check_adopt_gate_coverage.py -- the OPS0 STEP 4d precondition-5 drift checker,
and (2026-08-31, roster#0) its second mirror check against auto-merge-claude.yml's post-merge
coverage-check step.

Regression coverage for ops0_adopt_gate_drift (2026-08-20): precondition 5's hand-kept list of
ci.yml `checks`-job steps had silently fallen six scripts behind ci.yml itself (check_cadence_
marker.py, routine_backup.py, check_cron_dst_safety.py, check_sq_version_registry.py,
check_superseded_by_discipline.py, check_connector_tools.py), which meant OPS0's ADOPT path could
merge a stranded branch onto main after running a weaker local gate than CI would apply. Every
test here builds its own synthetic ci.yml + Claude_Task_Plan.md excerpt in tmp_path and
monkeypatches cs.CI_YML / cs.TASK_PLAN -- nothing reads or writes the real repo files except the
"real repo passes" tests, same convention as the other check_*.py test files in this directory.

The "second mirror" section below (roster#0) covers the SAME drift risk on auto-merge-claude.yml's
`id: postmerge` step, which is a structurally identical hand-kept copy of this same ci.yml step
list with no drift guard before this pass -- see scripts/check_adopt_gate_coverage.py's own
docstring for the full rationale. Those tests additionally monkeypatch cs.AUTO_MERGE_YML.
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


# ---- second mirror: auto-merge-claude.yml's post-merge coverage-check step (roster#0, --------
# ---- 2026-08-31 code-quality pass: this second hand-kept ci.yml mirror had no drift guard) ---

def write_auto_merge_yml(tmp_path, postmerge_run, step_id="postmerge"):
    doc = {
        "name": "Auto-merge branches to main",
        "on": {"workflow_run": None},
        "jobs": {
            "merge": {
                "name": "merge",
                "runs-on": "ubuntu-latest",
                "steps": [
                    {"name": "checkout", "uses": "actions/checkout@v7"},
                    {
                        "name": "Post-merge coverage check (mirrors ci.yml's `checks` job)",
                        "id": step_id,
                        "run": postmerge_run,
                    },
                ],
            },
        },
    }
    path = tmp_path / "auto-merge-claude.yml"
    path.write_text(yaml.dump(doc, sort_keys=False))
    return path


def wire_postmerge(tmp_path, monkeypatch, ci_steps, postmerge_run, postmerge_step_id="postmerge"):
    """Wires CI_YML + AUTO_MERGE_YML for a postmerge-mirror test. TASK_PLAN is pointed at a
    paragraph mentioning every identifier ci_steps could require, so precondition 5 always passes
    and cs.main()'s exit code reflects the postmerge mirror alone -- the same isolation `wire()`
    gives the precondition-5 tests above, just for the other mirror."""
    ci = write_ci_yml(tmp_path, ci_steps)
    all_mentions = [ident for ident, _ in cs.required_identifiers(cs.load_checks_job_steps(str(ci)))]
    plan = write_task_plan(tmp_path, all_mentions)
    am = write_auto_merge_yml(tmp_path, postmerge_run, step_id=postmerge_step_id)
    monkeypatch.setattr(cs, "CI_YML", str(ci))
    monkeypatch.setattr(cs, "TASK_PLAN", str(plan))
    monkeypatch.setattr(cs, "AUTO_MERGE_YML", str(am))


def test_postmerge_missing_run_check_is_caught(tmp_path, monkeypatch, capsys):
    wire_postmerge(
        tmp_path, monkeypatch,
        ci_steps=[{"name": "roster single-source",
                   "run": "python scripts/check_roster_consistency.py"}],
        postmerge_run="run_check python c_options_math.py\n",  # roster check NOT mirrored
    )
    assert cs.main() == 1
    out = capsys.readouterr().out
    assert "POST-MERGE COVERAGE MIRROR: FAIL" in out
    assert "check_roster_consistency.py" in out


def test_postmerge_full_mirror_passes(tmp_path, monkeypatch):
    wire_postmerge(
        tmp_path, monkeypatch,
        ci_steps=[
            {"name": "roster single-source", "run": "python scripts/check_roster_consistency.py"},
            {"name": "pytest regression suite", "run": "python -m pytest -q"},
            {"name": "bash suite", "run": "bash tests/test_auto_merge_logic.sh"},
            {"name": "node suite", "run": "node ops/weekly_report/test_pure_helpers.js"},
        ],
        postmerge_run=(
            "set -uo pipefail\n"
            "fail=0\n"
            "run_check() { :; }\n"
            "run_check python scripts/check_roster_consistency.py\n"
            "run_check python -m pytest -q\n"
            "run_check bash tests/test_auto_merge_logic.sh\n"
            "run_check node ops/weekly_report/test_pure_helpers.js\n"
        ),
    )
    assert cs.main() == 0


def test_postmerge_excluded_identifiers_do_not_require_a_run_check_line(tmp_path, monkeypatch):
    # check_cadence_marker.py (push-diff scoped) and the three pinned-linter/name-sync steps are
    # documented as deliberately absent from the post-merge mirror -- POSTMERGE_EXCLUDED_
    # IDENTIFIERS must let all four pass with NO run_check line for them at all.
    wire_postmerge(
        tmp_path, monkeypatch,
        ci_steps=[
            {"name": "cadence-output first-line period markers",
             "run": "python scripts/check_cadence_marker.py"},
            {"name": "actionlint (workflow YAML + embedded run-block bash via shellcheck)",
             "run": "./actionlint -color"},
            {"name": "shellcheck standalone scripts (warning+ blocks)",
             "run": "shellcheck -S warning file.sh"},
            {"name": "workflow_run trigger names stay in sync (auto-merge-claude.yml <-> ci.yml)",
             "run": "echo checking workflow_run triggers"},
        ],
        postmerge_run="run_check python c_options_math.py\n",  # none of the four mirrored
    )
    assert cs.main() == 0


def test_postmerge_line_must_be_a_real_run_check_invocation(tmp_path, monkeypatch, capsys):
    # A script path appearing anywhere in the run: body that is NOT an actual `run_check ...`
    # line (e.g. a comment showing an example command) must not count as coverage -- regression
    # guard for the `stripped.startswith("run_check ")` filter in postmerge_step_identifiers().
    wire_postmerge(
        tmp_path, monkeypatch,
        ci_steps=[{"name": "roster single-source",
                   "run": "python scripts/check_roster_consistency.py"}],
        postmerge_run=(
            "# reference: python scripts/check_roster_consistency.py\n"
            "run_check python c_options_math.py\n"
        ),
    )
    assert cs.main() == 1
    assert "check_roster_consistency.py" in capsys.readouterr().out


def test_postmerge_step_not_found_fails_loudly(tmp_path, monkeypatch, capsys):
    wire_postmerge(
        tmp_path, monkeypatch,
        ci_steps=[],
        postmerge_run="run_check python c_options_math.py\n",
        postmerge_step_id="some_other_id",  # not "postmerge" -- id: postmerge is unresolvable
    )
    assert cs.main() == 1
    out = capsys.readouterr().out
    assert "POST-MERGE COVERAGE MIRROR: FAIL" in out
    assert "could not locate" in out


# ---- adopt-gate-search-drops-second-match-per-line: two scripts chained on one run: line --------

def test_required_identifiers_captures_both_scripts_chained_on_one_line():
    """Regression for adopt-gate-search-drops-second-match-per-line. `pattern.search(line)` finds
    only the FIRST match on a physical line, so a `run:` line invoking two scripts with `&&` -- a
    normal shell idiom -- silently dropped the second script from `required`, making it invisible
    to both the precondition-5 comparison and the postmerge-mirror comparison. No live ci.yml step
    chains two scripts on one line today (every checks-job step runs exactly one script per `run:`
    line, verified by grep), so this fixture is synthetic -- but nothing enforces that convention,
    and a future step consolidation (this repo has done exactly that before, for CI-minute cost
    reasons) could reintroduce this shape with the checker itself reporting OK throughout."""
    steps = [{"name": "chained pair", "run": "python scripts/a.py && python scripts/b.py"}]
    required = cs.required_identifiers(steps)
    idents = {i for i, _ in required}
    assert idents == {"a.py", "b.py"}


def test_missing_second_chained_script_is_caught_end_to_end(tmp_path, monkeypatch, capsys):
    """End-to-end version of the same regression: a ci.yml step chaining two scripts on one line,
    with precondition 5's prose naming only the first, must FAIL. Pre-fix, `.search()` never even
    asked whether the second script was required, so this passed regardless of the prose -- a
    weaker-than-CI local gate exactly like the six-script gap this whole script exists to catch."""
    wire(
        tmp_path, monkeypatch,
        steps=[{"name": "chained pair",
                "run": ("python scripts/check_cadence_marker.py && "
                        "python scripts/check_cron_dst_safety.py")}],
        script_mentions=["check_cadence_marker.py"],  # second script NOT mentioned
    )
    assert cs.main() == 1
    out = capsys.readouterr().out
    assert "check_cron_dst_safety.py" in out
    assert "FAIL" in out


def test_postmerge_step_identifiers_captures_both_scripts_on_one_run_check_line():
    """Same fix, the postmerge-mirror extraction function (roster#0's second hand-kept ci.yml
    copy). A `run_check` line invoking two scripts must register both, not just the first."""
    step = {"run": "run_check python scripts/a.py && python scripts/b.py\n"}
    found = cs.postmerge_step_identifiers(step)
    assert found == {"a.py", "b.py"}


# ---- the real repo must satisfy its own contract -----------------------------------------------

def test_real_repo_passes_the_adopt_gate_coverage_check():
    # Read-only: no monkeypatch, so this exercises the real CI_YML/TASK_PLAN paths exactly as CI
    # runs it. If this starts failing, precondition 5's prose is missing a real ci.yml step --
    # fix the prose, not this test.
    assert cs.main() == 0


def test_real_repo_postmerge_mirror_is_in_sync():
    # Companion to the assertion above, isolating just the postmerge half via find_postmerge_
    # missing() directly (same real, unpatched CI_YML/AUTO_MERGE_YML cs.main() reads). If this
    # starts failing, auto-merge-claude.yml's post-merge coverage-check step (id: postmerge) is
    # missing a run_check line for a real ci.yml step -- fix that step's run: body, not this test.
    required = cs.required_identifiers(cs.load_checks_job_steps())
    missing, step = cs.find_postmerge_missing(required)
    assert step is not None
    assert missing == []
