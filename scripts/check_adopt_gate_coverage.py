#!/usr/bin/env python3
"""Fail CI if OPS0 STEP 4d precondition 5's hand-kept check list, OR auto-merge-claude.yml's
post-merge coverage-check step, drifts from ci.yml.

WHY THIS EXISTS (alert ops0_adopt_gate_drift, 2026-08-20). OPS0's STEP 4d ADOPT path
(Claude_Task_Plan.md) merges a stranded branch onto main with no human in the loop, gated on
precondition 5 running "ci.yml's `checks`-job steps" -- a list of script/test invocations copied
into that paragraph by hand, because the routine container cannot invoke the GitHub Actions
runner itself. That paragraph's own text already admitted the risk: "This step list is hand-kept
against ci.yml and nothing enforces it stays in sync." Verified 2026-08-20: six BLOCKING
checks-job steps existed in ci.yml with no mention in the prose list (check_cadence_marker.py,
routine_backup.py, check_cron_dst_safety.py, check_sq_version_registry.py,
check_superseded_by_discipline.py, check_connector_tools.py) -- OPS0 could have adopted (and
pushed straight to main) a branch that broke any of those six, because its own "run the local
suite" step would never have run them: a WEAKER gate than CI would apply. This script closes
that loop mechanically so the list can never silently drift again.

WHAT THIS CHECKS. Every BLOCKING step in ci.yml's `checks` job -- no `continue-on-error: true`,
no `|| true` shell fallback on the checked line
-- that invokes an identifiable script/test target (a `scripts/*.py` or root `*.py` file,
`python -m pytest`, a `tests/*.sh` file, a `node *.js` file) must have that file's basename
appear as a literal substring inside precondition 5's step-list paragraph in
Claude_Task_Plan.md. The three non-script "former shell-lint" steps (actionlint, the standalone
shellcheck pass, and the workflow_run trigger-name sync check) are matched by a small fixed
step-name -> keyword table instead, since they invoke a pinned lint binary rather than a
checked-in script.

WHAT THIS DELIBERATELY DOES NOT CHECK:
  - `dbt deps + parse`: intentionally absent from precondition 5's runnable list -- the prose
    explains why (dbt is not installed in the routine container; precondition 2 hard-excludes
    bigquery/**+dbt/** paths from ADOPT, so an adoptable branch can never change what dbt parse
    reads). Its `run:` body names no scripts/tests/*.py|.sh|.js target, so it is never a
    candidate here either -- both guards agree by construction, not by a special case.
  - Any step with `continue-on-error: true` (the two ruff steps) or a `|| true` shell fallback --
    both are advisory in ci.yml itself, so precondition 5 omitting them does not weaken the local
    gate relative to what CI actually enforces.
    STALE-EXAMPLE CORRECTION (2026-09-04): this bullet used to name "dbt view coverage" as the
    `|| true` example. That stopped being true on 2026-09-01, when the uncovered backlog reached
    zero and commit 8a533a7 dropped the fallback (ci.yml's step is now "dbt view coverage
    (ENFORCING as of 2026-09-01 -- backlog is zero)", with a bare `run:` and an inline "WAS
    `|| true`" note). check_dbt_view_coverage.py is consequently a REQUIRED identifier this script
    now enforces -- the exact opposite of an excluded step, so
    do not "restore" an exclusion for it. The checks job's ONLY `|| true` today is on the ruff
    invocation, and required_identifiers() already drops that step one clause earlier on its
    `continue-on-error: true` -- so the `|| true` line-skip below is currently REDUNDANT, not
    unexercised-for-lack-of-an-example. Keep it: it is the only guard for a future advisory step
    that relies on `|| true` alone, with no continue-on-error. (`warehouse-validation` also has a
    `|| true` line, on `gcloud config set`; this script never reads that job.) Re-measure with a
    PyYAML walk over jobs.checks.steps before restating any of this -- the previous example
    rotted in three days.
  - `warehouse-validation` job steps (dbt-parity, the SQL dry-run) -- precondition 2's own text
    already argues these are unreproducible-and-excluded-by-path, a separate, already-verified
    argument this script does not re-litigate.
  - The reverse direction (a prose-listed script no longer present in ci.yml): a stale mention
    makes precondition 5 do MORE work than CI requires, never less -- it cannot let a
    weaker-than-CI branch through, which is the only risk this script exists to close.

POST-MERGE VALIDATION. auto-merge-claude.yml ("Merge validated PR") used to carry a second hand-kept
copy of ci.yml's checks-job step list (an `id: postmerge` step of `run_check` lines), which this
script mirror-checked against ci.yml. That workflow now dispatches the WHOLE ci.yml on main after an
explicitly selected PR merges, so there is no subset left to drift; this script only asserts that the
dispatch still names ci.yml and still requires the `CI required` check. If either is dropped, the
post-merge safety net is gone and this fails.

Usage: python scripts/check_adopt_gate_coverage.py     # exit 0 if in sync, 1 + diff if not
"""
import json
import os
import re
import sys

try:
    import yaml  # noqa: F401 -- see check_prose_invariants.py for why this early import exists
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

from lib.textio import load_yaml, read_text

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CI_YML = os.path.join(ROOT, ".github", "workflows", "ci.yml")
TASK_PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")
AUTO_MERGE_YML = os.path.join(ROOT, ".github", "workflows", "auto-merge-claude.yml")

# Anchors bounding precondition 5's step-list paragraph within OPS0 STEP 4d's ADOPT block. Both
# must exist verbatim; a rewrite that removes either is itself worth failing loudly for, rather
# than silently scanning the wrong (or zero) text.
PARA_START = "THE LOCAL CHECK SUITE PASSES ON THE RESOLUTION"
PARA_END = "PUSH IMMEDIATELY once 1"

PY_RUN = re.compile(r"\bpython3?\s+(?:-m\s+)?(\S+\.py)\b")
PYTEST_RUN = re.compile(r"\bpython3?\s+-m\s+pytest\b")
BASH_TEST_RUN = re.compile(r"\bbash\s+(tests/\S+\.sh)\b")
NODE_RUN = re.compile(r"\bnode\s+(\S+\.js)\b")

# The three former-`shell-lint` steps run a pinned linter binary, not a checked-in script, so
# PY_RUN/BASH_TEST_RUN/NODE_RUN have no filename to extract from them. Matched by a substring of
# the step's own `name:` -> the keyword precondition 5's prose already uses to describe each one.
LINT_STEP_KEYWORDS = {
    "actionlint (workflow yaml": "actionlint",
    "shellcheck standalone scripts": "shellcheck",
    "workflow_run trigger names stay in sync": "workflow_run",
}


def load_checks_job_steps(path=None):
    doc = load_yaml(path or CI_YML)
    try:
        return doc["jobs"]["checks"]["steps"]
    except KeyError as e:
        raise SystemExit(f"{path or CI_YML}: no jobs.checks.steps found -- workflow restructured? ({e})") from e


def required_identifiers(steps):
    """(identifier, step_name) pairs precondition 5 must mention, one per BLOCKING checks-job
    step whose run: body names an identifiable script/test/lint target."""
    required = []
    for step in steps:
        run = step.get("run")
        name = step.get("name", "<unnamed step>")
        if not run or step.get("continue-on-error") is True:
            continue

        name_lower = name.lower()
        matched_lint = False
        for needle, keyword in LINT_STEP_KEYWORDS.items():
            if needle in name_lower:
                required.append((keyword, name))
                matched_lint = True
                break
        if matched_lint:
            continue

        for line in run.splitlines():
            if "|| true" in line:  # always-pass fallback -- advisory in ci.yml, not a real gate
                continue
            if PYTEST_RUN.search(line):
                required.append(("pytest", name))
            # BUG FIX (finding adopt-gate-search-drops-second-match-per-line): `.search()` finds
            # only the FIRST match on a line, so a `run:` line invoking two scripts on one
            # physical line -- `python scripts/a.py && python scripts/b.py`, a normal shell idiom
            # -- silently dropped the second script from `required`, making it invisible to the
            # precondition-5 comparison below. No live
            # ci.yml step does this today (every checks-job step runs exactly one script per
            # `run:` line), so the gap was dormant, but nothing enforced that convention and a
            # future step consolidation (this repo has done exactly that before, for CI-minute
            # cost reasons) could reintroduce it with this checker itself reporting OK
            # throughout -- the identical drift shape this whole script exists to catch, just
            # originating in its own extraction logic instead of the prose list it audits.
            # `finditer()` instead of `search()` captures every match on the line; the `seen`
            # dedup set in main() already handles the resulting
            # duplicate identifiers when only one script appears, so this is a pure widening.
            for pattern in (PY_RUN, BASH_TEST_RUN, NODE_RUN):
                for m in pattern.finditer(line):
                    required.append((os.path.basename(m.group(1)), name))
    return required


def find_precondition5_paragraph(plan_text):
    """The step-list paragraph's text, or None if the anchors have moved/vanished."""
    try:
        start = plan_text.index(PARA_START)
        end = plan_text.index(PARA_END, start)
    except ValueError:
        return None
    return plan_text[start:end]


def dispatches_full_ci(path=None):
    """True iff auto-merge-claude.yml's merge step dispatches ci.yml on main and requires the
    `CI required` check -- the property that makes a hand-kept post-merge mirror of ci.yml unnecessary."""
    doc = load_yaml(path or AUTO_MERGE_YML)
    for job in (doc.get("jobs") or {}).values():
        for step in job.get("steps") or []:
            if step.get("run") != "python3 .github/scripts/merge_validated_pr.py":
                continue
            env = step.get("env") or {}
            try:
                workflows = json.loads(env.get("MAIN_WORKFLOWS", "[]"))
                checks = json.loads(env.get("REQUIRED_CHECKS", "[]"))
            except (TypeError, ValueError):
                return False
            return "ci.yml" in workflows and "CI required" in checks
    return False


def main():
    steps = load_checks_job_steps()
    required = required_identifiers(steps)
    exit_code = 0

    paragraph = find_precondition5_paragraph(read_text(TASK_PLAN))
    if paragraph is None:
        print(f"ADOPT GATE COVERAGE: FAIL -- could not locate precondition 5's step-list "
              f"paragraph in {os.path.relpath(TASK_PLAN, ROOT)} (anchor {PARA_START!r} or "
              f"{PARA_END!r} missing/moved). Fix the anchors in this script if the prose was "
              f"deliberately reworded, or restore the paragraph if it was accidentally deleted.")
        exit_code = 1
    else:
        missing = []
        seen = set()
        for ident, step_name in required:
            if ident in paragraph or ident in seen:
                continue
            seen.add(ident)
            missing.append((ident, step_name))

        if missing:
            print("ADOPT GATE COVERAGE: FAIL -- OPS0 STEP 4d precondition 5's hand-kept check list "
                  "(Claude_Task_Plan.md) is missing steps that ci.yml's checks job actually blocks "
                  "on. OPS0's ADOPT path would run a WEAKER local gate than CI. Add each one to "
                  "precondition 5's step list:\n")
            for ident, step_name in missing:
                print(f"  - {ident}  (ci.yml step: {step_name!r})")
            exit_code = 1
        else:
            print(f"ADOPT GATE COVERAGE: OK -- {len({i for i, _ in required})} blocking checks-job "
                  f"identifiers all present in precondition 5's step list.")

    if dispatches_full_ci():
        print("POST-MERGE VALIDATION: OK -- explicitly selected PR merges dispatch the full "
              "ci.yml on main, covering every required job without a mirrored subset.")
    else:
        print(f"POST-MERGE VALIDATION: FAIL -- {os.path.relpath(AUTO_MERGE_YML, ROOT)} no longer runs "
              f"`python3 .github/scripts/merge_validated_pr.py` with ci.yml in MAIN_WORKFLOWS and "
              f"'CI required' in REQUIRED_CHECKS, so a merged PR is no longer re-verified on main.")
        exit_code = 1

    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
