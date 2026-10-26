"""Selected PR landing markers, with temporary git histories and a recording bq stub."""

import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys

import pytest
import yaml


ROOT = Path(__file__).resolve().parents[1]
WRITER = ROOT / "scripts/write_routine_commit_markers.sh"
REAL_GIT = shutil.which("git")


def git(repo, *args, env=None):
    return subprocess.check_output([REAL_GIT, *args], cwd=repo, env=env, text=True).strip()


def commit(repo, subject, email="noreply@anthropic.com", date="2026-10-20T12:00:00+0000"):
    env = dict(
        os.environ,
        GIT_AUTHOR_NAME="Fixture",
        GIT_AUTHOR_EMAIL=email,
        GIT_COMMITTER_NAME="Fixture",
        GIT_COMMITTER_EMAIL=email,
        GIT_AUTHOR_DATE=date,
        GIT_COMMITTER_DATE=date,
    )
    git(repo, "commit", "--quiet", "--allow-empty", "-m", subject, env=env)
    return git(repo, "rev-parse", "HEAD")


def write_python_shim(path, body):
    """Install an executable `path` that runs `body` under this interpreter.

    The body lives beside the shim and a POSIX sh wrapper execs it, because a
    `#!{sys.executable}` shebang breaks whenever the interpreter path contains a
    space (a checkout under e.g. "My Apps"): the kernel splits the shebang there.
    """
    impl = path.with_name(path.name + "_impl.py")
    impl.write_text("import json, os, sys\n" + body)
    path.write_text(f'#!/bin/sh\nexec {shlex.quote(sys.executable)} {shlex.quote(str(impl))} "$@"\n')
    path.chmod(0o755)


@pytest.fixture
def landed_pr(tmp_path):
    repo = tmp_path / "repo"
    repo.mkdir()
    git(repo, "init", "--quiet", "-b", "main")
    git(repo, "config", "user.name", "Fixture")
    git(repo, "config", "user.email", "fixture@example.com")
    base = commit(repo, "D1 2026-10-19: already landed before the selected PR")
    git(repo, "checkout", "--quiet", "-b", "pre-existing-unrelated")
    unrelated = commit(repo, "D3 2026-10-20: unrelated existing branch")
    git(repo, "checkout", "--quiet", "-b", "selected-pr", base)
    quoted_subject = "D1 2026-10-20: output with 'quotes', $HOME and `literal` text"
    first = commit(repo, quoted_subject)
    fallback = commit(repo, "SL2: evening output", date="2026-10-21T01:30:00+0000")
    halted = commit(repo, "W5 2026-10-20: HALTED at pre-flight")
    operator = commit(repo, "D2 2026-10-20: operator maintenance", email="jack@mac.home")
    head = commit(repo, "Ordinary maintenance without a routine prefix")
    git(repo, "checkout", "--quiet", "main")
    git(repo, "merge", "--quiet", "--no-ff", "selected-pr", "-m", "D1 2026-10-20: merge title is not routine output")
    merged = git(repo, "rev-parse", "HEAD")

    capture = tmp_path / "bq.jsonl"
    commands = tmp_path / "git.jsonl"
    shim = tmp_path / "bin"
    shim.mkdir()
    write_python_shim(
        shim / "bq",
        "with open(os.environ['BQ_CAPTURE'], 'a') as out: out.write(json.dumps(sys.argv[1:]) + '\\n')\n"
        "sys.exit(int(os.environ.get('BQ_FAILURE', '0')))\n",
    )
    write_python_shim(
        shim / "git",
        "with open(os.environ['GIT_CAPTURE'], 'a') as out: out.write(json.dumps(sys.argv[1:]) + '\\n')\n"
        "if sys.argv[1:] == ['fetch', '--no-tags', 'origin', os.environ['VALIDATED_MERGE_SHA']]: sys.exit(0)\n"
        "if sys.argv[1] not in {'show', 'merge-base', 'rev-list', 'log', 'rev-parse'}: sys.exit(99)\n"
        f"os.execv({REAL_GIT!r}, [{REAL_GIT!r}, *sys.argv[1:]])\n",
    )
    env = dict(
        os.environ,
        PATH=str(shim) + os.pathsep + os.environ["PATH"],
        BQ_CAPTURE=str(capture),
        GIT_CAPTURE=str(commands),
        VALIDATED_MERGE_SHA=merged,
    )
    return {
        "repo": repo,
        "base": base,
        "head": head,
        "merged": merged,
        "first": first,
        "fallback": fallback,
        "halted": halted,
        "operator": operator,
        "unrelated": unrelated,
        "quoted_subject": quoted_subject,
        "env": env,
        "capture": capture,
        "commands": commands,
    }


def run_writer(case, *overrides, failure=0):
    refs = overrides or (case["base"], case["head"], case["merged"])
    return subprocess.run(
        ["bash", str(WRITER), *refs],
        cwd=case["repo"],
        env=dict(case["env"], BQ_FAILURE=str(failure)),
        capture_output=True,
        text=True,
        check=False,
        timeout=20,
    )


def calls(case):
    if not case["capture"].exists():
        return []
    return [json.loads(line) for line in case["capture"].read_text().splitlines()]


def test_marks_only_selected_landed_routine_outputs_and_preserves_calendar_guards(landed_pr):
    case = landed_pr
    result = run_writer(case)
    assert result.returncode == 0, result.stdout + result.stderr
    emitted = calls(case)
    assert len(emitted) == 2
    assert "--parameter=p_git_commit:STRING:" + case["first"] in emitted[0]
    assert "--parameter=p_commit_subject:STRING:" + case["quoted_subject"] in emitted[0]
    assert "--parameter=p_run_date:DATE:2026-10-20" in emitted[0]
    assert "--parameter=p_git_commit:STRING:" + case["fallback"] in emitted[1]
    assert "--parameter=p_run_date:DATE:2026-10-20" in emitted[1]
    assert all('"auto-merge-claude.yml"' in call[-1] for call in emitted)
    assert "SUPPRESSED" in result.stdout
    recorded = [json.loads(line) for line in case["commands"].read_text().splitlines()]
    assert {args[0] for args in recorded} <= {"show", "merge-base", "rev-list", "log", "rev-parse"}
    assert git(case["repo"], "rev-parse", "main") == case["merged"]
    assert git(case["repo"], "rev-parse", "pre-existing-unrelated") == case["unrelated"]
    assert git(case["repo"], "rev-parse", "selected-pr") == case["head"]


@pytest.mark.parametrize("invalid", ["unrelated-base", "wrong-head", "invalid-sha"])
def test_rejects_unverified_or_malformed_selected_range_before_cloud_write(landed_pr, invalid):
    case = landed_pr
    base, head = case["base"], case["head"]
    if invalid == "unrelated-base":
        base = case["unrelated"]
    elif invalid == "wrong-head":
        head = case["first"]
    else:
        base = "--all"
    result = run_writer(case, base, head, case["merged"])
    assert result.returncode != 0
    assert calls(case) == []


def test_main_advancing_before_the_merge_still_marks_only_the_prs_own_commits(landed_pr):
    # GitHub merges onto main's CURRENT tip, so if main moved after validation the merge's first
    # parent is a descendant of the validated base, not the base itself. Markers used to be
    # skipped outright in that case.
    case = landed_pr
    repo = case["repo"]
    git(repo, "checkout", "--quiet", "-b", "racing-main", case["base"])
    commit(repo, "D3 2026-10-20: landed on main while the PR was being validated")
    racing_tip = git(repo, "rev-parse", "HEAD")
    git(repo, "merge", "--quiet", "--no-ff", "selected-pr", "-m", "Merge selected PR onto newer main")
    merged = git(repo, "rev-parse", "HEAD")
    result = run_writer(case, case["base"], case["head"], merged)
    assert result.returncode == 0, result.stdout + result.stderr
    marked = [arg for call in calls(case) for arg in call if arg.startswith("--parameter=p_git_commit:")]
    assert marked == ["--parameter=p_git_commit:STRING:" + case["first"],
                      "--parameter=p_git_commit:STRING:" + case["fallback"]]
    assert racing_tip not in "".join(marked)


def test_stale_pr_head_cannot_supply_markers_for_new_main(landed_pr):
    case = landed_pr
    git(case["repo"], "checkout", "--quiet", "-b", "stale-pr", case["base"])
    stale = commit(case["repo"], "D1 2026-10-20: old branch output")
    git(case["repo"], "checkout", "--quiet", "main")
    git(case["repo"], "merge", "--quiet", "--no-ff", "stale-pr", "-m", "Merge stale PR")
    merged = git(case["repo"], "rev-parse", "HEAD")
    result = run_writer(case, case["merged"], stale, merged)
    assert result.returncode != 0
    assert "does not contain its validated main base" in result.stderr
    assert calls(case) == []


def test_shallow_checkout_refuses_instead_of_marking_old_history(landed_pr, tmp_path):
    # 2026-10-23 (PR #80): a depth-1 main checkout plus a PR head that had merged main
    # made base..head span history below the shallow boundary -> 218 May-Jul markers.
    case = landed_pr
    repo = case["repo"]
    git(repo, "checkout", "--quiet", "-b", "old-routine-history", case["base"])
    old = commit(repo, "D2 2026-05-09: old routine output already on main", date="2026-05-09T12:00:00+0000")
    git(repo, "checkout", "--quiet", "main")
    git(repo, "merge", "--quiet", "--no-ff", "old-routine-history", "-m", "Merge old history")
    base = git(repo, "rev-parse", "HEAD")
    git(repo, "checkout", "--quiet", "-b", "pr-that-merged-main", old)
    commit(repo, "AR_orc 2026-10-22: selected PR output")
    git(repo, "merge", "--quiet", "--no-ff", "main", "-m", "Merge branch 'main' into pr")
    head = git(repo, "rev-parse", "HEAD")
    git(repo, "checkout", "--quiet", "main")
    git(repo, "merge", "--quiet", "--no-ff", "pr-that-merged-main", "-m", "Merge PR")
    merged = git(repo, "rev-parse", "HEAD")
    # Mirror CI: depth-1 checkout of main as it was before the merge, then fetch the merge.
    git(repo, "branch", "main-before-merge", base)
    shallow = tmp_path / "shallow"
    subprocess.check_call(
        [REAL_GIT, "clone", "--quiet", "--depth=1", "--no-local", "--branch", "main-before-merge",
         f"file://{repo}", str(shallow)]
    )
    git(shallow, "fetch", "--quiet", "--no-tags", "origin", "main")
    assert git(shallow, "rev-parse", "FETCH_HEAD") == merged
    assert git(shallow, "rev-parse", "--is-shallow-repository") == "true"
    result = run_writer(dict(case, repo=shallow), base, head, merged)
    assert result.returncode != 0
    assert "shallow repository" in result.stderr
    assert calls(case) == []


def test_bigquery_failure_warns_and_continues_after_successful_pr_merge(landed_pr):
    result = run_writer(landed_pr, failure=13)
    assert result.returncode == 0
    assert len(calls(landed_pr)) == 2
    assert result.stdout.count("::warning::routine_commit_markers insert failed") == 2


@pytest.mark.parametrize(
    "auth,provider,expected_rows",
    [
        ("success", "fixture-provider", 2),
        ("failure", "fixture-provider", 0),
        ("skipped", "", 0),
    ],
)
def test_real_workflow_preserves_selected_markers_and_optional_auth_contract(landed_pr, auth, provider, expected_rows):
    case = landed_pr
    workflow = yaml.safe_load((ROOT / ".github/workflows/auto-merge-claude.yml").read_text())
    job = workflow["jobs"]["merge"]
    assert job["permissions"]["id-token"] == "write"
    steps = job["steps"]
    checkout = next(step for step in steps if str(step.get("uses", "")).startswith("actions/checkout@"))
    assert checkout["with"]["fetch-depth"] == 0
    assert any(step.get("id") == "merge" for step in steps)
    marker_auth = next(step for step in steps if step.get("id") == "marker-auth")
    assert marker_auth["continue-on-error"] is True
    writer = next(step for step in steps if "bash scripts/write_routine_commit_markers.sh" in step.get("run", ""))
    assert "always()" in writer["if"]
    assert "steps.merge.outputs.merge_sha" in writer["if"]
    for field in ("base", "head", "merge"):
        assert writer["env"][field.upper() + "_SHA"] == "${{ steps.merge.outputs." + field + "_sha }}"
    trusted_scripts = case["repo"] / "scripts"
    trusted_scripts.mkdir()
    shutil.copy2(WRITER, trusted_scripts / WRITER.name)
    shutil.copy2(ROOT / "scripts/auto_merge_decision.sh", trusted_scripts / "auto_merge_decision.sh")
    env = dict(
        case["env"],
        BASE_SHA=case["base"],
        HEAD_SHA=case["head"],
        MERGE_SHA=case["merged"],
        AUTH_OUTCOME=auth,
        WIF_PROVIDER=provider,
        WIF_SERVICE_ACCOUNT="fixture-service-account",
    )
    result = subprocess.run(
        ["bash", "-e", "-o", "pipefail", "-c", writer["run"]],
        cwd=case["repo"],
        env=env,
        capture_output=True,
        text=True,
        check=False,
        timeout=20,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert len(calls(case)) == expected_rows
    if expected_rows:
        recorded = [json.loads(line) for line in case["commands"].read_text().splitlines()]
        assert recorded[0] == ["fetch", "--no-tags", "origin", case["merged"]]
    else:
        assert not case["commands"].exists()
