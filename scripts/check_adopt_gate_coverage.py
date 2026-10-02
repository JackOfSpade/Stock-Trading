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
    now enforces, and it is present in BOTH mirrors -- the exact opposite of an excluded step, so
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

SECOND MIRROR (roster#0, 2026-08-31 code-quality pass). auto-merge-claude.yml's `id: postmerge`
step ("Post-merge coverage check", run against main's ACTUAL merged tip after this job pushes)
is a STRUCTURALLY IDENTICAL hand-kept copy of ci.yml's checks-job step list -- its own comment
says as much ("Every command below is copy-identical to ci.yml's `checks` job ... except the
push-diff-scoped check_cadence_marker.py ... and the lint/dbt steps"). Nothing cross-checked that
copy against ci.yml the way this script already does for Claude_Task_Plan.md's precondition 5,
so it could drift exactly as precondition 5 already did once (ops0_adopt_gate_drift, above) with
zero CI signal -- the next blocking step added to ci.yml would silently stop being re-verified
against main's merged tip. This script now also asserts every required identifier's basename
appears as a `run_check <cmd> ...` line inside that step's `run:` body, EXCEPT the identifiers in
POSTMERGE_EXCLUDED_IDENTIFIERS below -- an explicit allowlist (not silence) for the omissions the
step's own comment already documents as deliberate: check_cadence_marker.py (needs a `git diff`
against the ORIGINAL push's base, which no longer resolves once this job has already merged onto
main's new tip) and the three pinned-linter/name-sync steps (actionlint, shellcheck,
workflow_run) that this job never installs a linter binary to run at all. This closes that
agreement mechanically so it can't silently rot the way precondition 5's did.

STALE-COMMENT CORRECTION (2026-08-31 code-quality pass, same day): this paragraph originally
froze "the two lists agree today (24 `run_check` lines == 28 required identifiers minus those 4
allowlisted ones)" here. That was already wrong by the time this file was read again in the same
pass -- two more blocking ci.yml steps (tests/test_bq_csv.sh, tests/test_ci_finding.sh) had been
added after the sentence was written, and re-running this script now prints 30 required
identifiers / 26 `run_check` lines, not 28/24. A number frozen in prose rots the moment ci.yml
gains or loses a blocking step; it is not re-verified by anything. Do not restore a hardcoded
count here -- run `python scripts/check_adopt_gate_coverage.py` and read its own
`POST-MERGE COVERAGE MIRROR: OK -- N blocking checks-job identifiers ... (plus 4 deliberately
allowlisted)` line for the live count; that line is generated from ci.yml and
auto-merge-claude.yml every time this script runs, so it cannot go stale the way this comment did.

Usage: python scripts/check_adopt_gate_coverage.py     # exit 0 if in sync, 1 + diff if not
"""
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

# auto-merge-claude.yml's post-merge coverage-check step is identified by its `id:`, not by a
# substring of its `name:` -- that workflow has FIVE other steps whose name also contains "post-
# merge coverage check" (the Python setup step before it, the GH-issue/ops.ci_findings steps
# after it), so a name substring would be ambiguous. `id:` is also what the step's own later
# `if: steps.postmerge.outputs.result == ...` conditions key off, so it is already the load-
# bearing identifier for this step elsewhere in the same workflow, not a citation invented here.
POSTMERGE_STEP_ID = "postmerge"

# Required identifiers (roster#0, 2026-08-31) that the post-merge coverage-check step
# DELIBERATELY does not run_check, per that step's own comment -- an explicit allowlist rather
# than silently treating a missing identifier as fine. See this module's docstring ("SECOND
# MIRROR") for why each one is here.
POSTMERGE_EXCLUDED_IDENTIFIERS = {
    "check_cadence_marker.py",  # push-diff scoped; no ORIGINAL push base to diff post-merge
    "actionlint",  # pinned-linter step; this job never installs actionlint
    "shellcheck",  # pinned-linter step; this job never installs shellcheck
    "workflow_run",  # name-sync check reads workflow files directly, not run here
}

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
            # -- silently dropped the second script from `required`, making it invisible to both
            # the precondition-5 comparison and the postmerge-mirror comparison below. No live
            # ci.yml step does this today (every checks-job step runs exactly one script per
            # `run:` line), so the gap was dormant, but nothing enforced that convention and a
            # future step consolidation (this repo has done exactly that before, for CI-minute
            # cost reasons) could reintroduce it with this checker itself reporting OK
            # throughout -- the identical drift shape this whole script exists to catch, just
            # originating in its own extraction logic instead of the prose list it audits.
            # `finditer()` instead of `search()` captures every match on the line; the `seen`
            # dedup sets in main()/find_postmerge_missing() already handle the resulting
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


def load_postmerge_step(path=None):
    """The auto-merge-claude.yml step whose `id:` is POSTMERGE_STEP_ID, or None if no step in
    the workflow carries that id (workflow restructured -- the id itself renamed or removed)."""
    doc = load_yaml(path or AUTO_MERGE_YML)
    try:
        jobs = doc["jobs"]
    except KeyError as e:
        raise SystemExit(f"{path or AUTO_MERGE_YML}: no jobs found -- workflow restructured? ({e})") from e
    for job in jobs.values():
        for step in job.get("steps") or []:
            if step.get("id") == POSTMERGE_STEP_ID:
                return step
    return None


def postmerge_step_identifiers(step):
    """Identifiers the post-merge coverage-check step actually `run_check`s, reusing the same
    PY_RUN/PYTEST_RUN/BASH_TEST_RUN/NODE_RUN patterns required_identifiers() uses against
    ci.yml. Unlike that function, there is no continue-on-error/`|| true` shape to
    filter here -- every line in this step is unconditionally blocking by construction (see the
    step's own comment) -- so the only filter is requiring the line to actually be a `run_check
    ...` invocation, not one of the surrounding `run_check()` helper-function lines (`fail=0`,
    the `if ! "$@"; then` body, the trailing `if [ "$fail" -eq 0 ]` summary)."""
    found = set()
    for line in (step.get("run") or "").splitlines():
        stripped = line.strip()
        if not stripped.startswith("run_check "):
            continue
        if PYTEST_RUN.search(stripped):
            found.add("pytest")
        # Same `.search()`-drops-the-second-match fix as required_identifiers() above, and for
        # the identical reason: a `run_check` line invoking two scripts would otherwise only
        # register the first. `found` is a set, so widening to every match is a pure addition.
        for pattern in (PY_RUN, BASH_TEST_RUN, NODE_RUN):
            for m in pattern.finditer(stripped):
                found.add(os.path.basename(m.group(1)))
    return found


def find_postmerge_missing(required):
    """(missing, step): step is the located `id: postmerge` step (or None if it could not be
    found at all); missing is the (ident, step_name) pairs required_identifiers() computed from
    ci.yml that are absent from that step's run_check lines, after excluding
    POSTMERGE_EXCLUDED_IDENTIFIERS -- the same "one per identifier, first ci.yml step wins"
    dedup shape main() already uses for the precondition-5 comparison."""
    step = load_postmerge_step()
    if step is None:
        return [], None

    present = postmerge_step_identifiers(step)
    missing = []
    seen = set()
    for ident, step_name in required:
        if ident in POSTMERGE_EXCLUDED_IDENTIFIERS or ident in present or ident in seen:
            continue
        seen.add(ident)
        missing.append((ident, step_name))
    return missing, step


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

    # SECOND MIRROR (roster#0, 2026-08-31): auto-merge-claude.yml's `id: postmerge` step is a
    # second hand-kept copy of this same ci.yml step list -- see this module's docstring. Run
    # regardless of the precondition-5 result above so one report shows both mirrors' status.
    postmerge_missing, postmerge_step = find_postmerge_missing(required)
    if postmerge_step is None:
        print(f"POST-MERGE COVERAGE MIRROR: FAIL -- could not locate the `id: {POSTMERGE_STEP_ID}` "
              f"step in {os.path.relpath(AUTO_MERGE_YML, ROOT)} (workflow restructured -- the "
              f"step's id was renamed or removed). Fix POSTMERGE_STEP_ID in this script if that "
              f"was deliberate, or restore the step's id if it was accidentally dropped.")
        exit_code = 1
    elif postmerge_missing:
        print("POST-MERGE COVERAGE MIRROR: FAIL -- auto-merge-claude.yml's post-merge coverage-"
              "check step (id: postmerge) is missing run_check lines for steps ci.yml's checks "
              "job actually blocks on. A branch could merge to main's tip without this job's "
              "post-merge safety net re-verifying it against that check. Add each one as a "
              "`run_check ...` line in that step, or to POSTMERGE_EXCLUDED_IDENTIFIERS in this "
              "script if the omission is deliberate and documented there like the existing four:\n")
        for ident, step_name in postmerge_missing:
            print(f"  - {ident}  (ci.yml step: {step_name!r})")
        exit_code = 1
    else:
        covered = len({i for i, _ in required} - POSTMERGE_EXCLUDED_IDENTIFIERS)
        print(f"POST-MERGE COVERAGE MIRROR: OK -- {covered} blocking checks-job identifiers all "
              f"present in auto-merge-claude.yml's post-merge coverage-check step (plus "
              f"{len(POSTMERGE_EXCLUDED_IDENTIFIERS)} deliberately allowlisted).")

    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
