"""Runs tests/test_finding_issue.sh (the stubbed-`gh` suite for scripts/finding_issue.sh) under pytest.

The other tests/test_*.sh suites each have their own ci.yml step. This one rides `python -m pytest`
instead, so it is covered by every push AND by any local run of the suite without adding a step that
OPS0's hand-kept precondition-5 list (scripts/check_adopt_gate_coverage.py) would have to mirror.
"""
import os
import shutil
import subprocess

import pytest

from conftest import ROOT


@pytest.mark.skipif(shutil.which("bash") is None or shutil.which("jq") is None,
                    reason="needs bash and jq (both present on the CI runner)")
def test_finding_issue_shell_suite_passes():
    result = subprocess.run(["bash", os.path.join(ROOT, "tests", "test_finding_issue.sh")],
                            capture_output=True, text=True, timeout=120)
    assert result.returncode == 0, result.stdout + result.stderr
    assert "FAIL:" not in result.stdout
