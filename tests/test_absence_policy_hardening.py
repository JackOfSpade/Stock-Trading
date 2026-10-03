"""Keep infra/terraform/apply_absence_policy_hardening.py in lockstep with monitoring.tf (RUNBOOK §56).

monitoring.tf is a spec that is never applied (CLAUDE.md "Settled decisions"), so the LIVE absence policies are
changed out-of-band by that script. Two hand-maintained copies of the same values drift silently -- and a drift
here has no runtime signal: a live policy simply carries a stale pending period or an empty/incorrect email body.
These offline tests parse monitoring.tf and compare it to the script's constants, and pin the fix's reason for
existing (a non-zero pending period) so a "tidy" back to `duration = "0s"` goes red.
"""
import json
import os
import re

import pytest

from conftest import ROOT, load_module_from_path

mod = load_module_from_path("apply_absence_policy_hardening", "infra", "terraform", "apply_absence_policy_hardening.py")
TF = open(os.path.join(ROOT, "infra", "terraform", "monitoring.tf"), encoding="utf-8").read()


def _hcl_str(raw):
    """Decode the HCL string-literal escapes monitoring.tf uses (only \\" and \\\\)."""
    return raw.replace('\\"', '"').replace("\\\\", "\\")


def _monitor_blocks():
    """key -> block text for each entry of local.scheduler_absence_monitors."""
    body = TF.split("scheduler_absence_monitors = {", 1)[1].split("} : key => monitor", 1)[0]
    blocks = {}
    for m in re.finditer(r"^\s{6}(\w+) = \{\n(.*?)^\s{6}\}", body, re.S | re.M):
        blocks[m.group(1)] = m.group(2)
    return blocks


def _documentation(block):
    m = re.search(r'documentation\s*=\s*"((?:[^"\\]|\\.)*)"\s*$', block, re.M)
    if m:
        return _hcl_str(m.group(1))
    j = re.search(r'documentation\s*=\s*join\(" ", \[(.*?)\]\)', block, re.S)
    assert j, "documentation is neither a string literal nor join(' ', [...])"
    return " ".join(_hcl_str(s) for s in re.findall(r'"((?:[^"\\]|\\.)*)"', j.group(1)))


def _var_default(name):
    m = re.search(r'variable "%s" \{.*?default\s*=\s*"([^"]*)"' % name, TF, re.S)
    assert m, name
    return m.group(1)


def test_five_monitors_parsed():
    assert set(_monitor_blocks()) == {"freshness", "backup", "cadence", "integrity_check", "ops_export"}
    assert len(mod.MONITORS) == 5


def test_duration_matches_spec_and_is_nonzero():
    spec = re.search(r'scheduler_absence_duration\s*=\s*"(\d+)s"', TF)
    assert spec, "monitoring.tf lost local.scheduler_absence_duration"
    assert mod.DURATION == f"{spec.group(1)}s"
    assert int(spec.group(1)) >= 600, (
        "a pending period shorter than 10 min no longer filters the evaluation-side blips of RUNBOOK §49/§56"
    )
    # ...and the policy resource must actually consume it (not a hardcoded "0s" again)
    assert re.search(r"duration\s*=\s*local\.scheduler_absence_duration", TF)
    block = TF.split('resource "google_monitoring_alert_policy" "scheduler_absent"', 1)[1].split("\n}\n", 1)[0]
    assert 'duration            = "0s"' not in block, "scheduler_absent regressed to a zero pending period"


def test_triage_text_matches_spec():
    m = re.search(r'scheduler_absence_triage\s*=\s*"((?:[^"\\]|\\.)*)"\n', TF)
    assert m, "monitoring.tf lost local.scheduler_absence_triage"
    assert _hcl_str(m.group(1)) == mod.TRIAGE


@pytest.mark.parametrize("key", ["freshness", "backup", "cadence", "integrity_check", "ops_export"])
def test_monitor_fields_match_spec(key):
    block = _monitor_blocks()[key]
    alert = re.search(r'alert_display_name\s*=\s*"([^"]*)"', block).group(1)
    cond = re.search(r'condition_display_name\s*=\s*"([^"]*)"', block).group(1)
    assert alert in mod.MONITORS, f"script has no entry for policy {alert!r}"
    cfg, s_cond, s_doc = mod.MONITORS[alert]
    assert s_cond == cond
    assert s_doc == _documentation(block)
    # config_id: var-backed ones are checkable against the variable default; the three resource-derived ones
    # are checked against the live ids recorded in monitoring.tf's own header comment (backup/cadence) and
    # the freshness id recorded in RUNBOOK §19.
    src = re.search(r"config_id\s*=\s*(\S+)", block).group(1)
    if src.startswith("var."):
        assert cfg == _var_default(src[4:])


def test_header_config_ids_match_script():
    for label, disp in (
        ("backup", "Backup scheduler absent >25h"),
        ("cadence", "Cadence scheduler absent >25h"),
        ("integrity_check", "Integrity-check scheduler absent >25h"),
        ("ops_export", "ops-export scheduler absent >25h"),
    ):
        m = re.search(r"#\s{3}%s\s+\S+\s+([0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12})" % label, TF)
        assert m, f"header comment lost the live config_id for {label}"
        assert mod.MONITORS[disp][0] == m.group(1)


def test_freshness_config_id_matches_spec_header():
    # freshness is the one id monitoring.tf DERIVES from a resource, so pin it to the id recorded in its own
    # header comment (and to the metric filter documented in RUNBOOK section 19).
    cfg = mod.MONITORS["Freshness scheduler absent >25h"][0]
    assert f'config_id="{cfg}"' in TF or cfg in TF
    assert cfg in open(os.path.join(ROOT, "ops", "RUNBOOK.md"), encoding="utf-8").read()


def test_evaluation_intervals_in_spec_match_live_values():
    # The script carries each LIVE interval over untouched, so the spec must state them (measured 2026-10-03).
    want = {"freshness": "1800s", "backup": "30s", "cadence": "30s", "integrity_check": "30s", "ops_export": "30s"}
    for key, block in _monitor_blocks().items():
        assert re.search(r'evaluation_interval\s*=\s*"%s"' % want[key], block), key


def test_sa_key_doc_only_entry_matches_spec():
    m = re.search(r'sa_key_created_documentation\s*=\s*"((?:[^"\\]|\\.)*)"', TF)
    assert m and _hcl_str(m.group(1)) == mod.DOC_ONLY["SA key created on gh-ci-runner or bq-scheduler"]


def test_integrity_doc_does_not_claim_to_be_the_only_detector():
    # Stale since MON H5 (2026-07-17): cadence_check's scheduled_query_stale also covers integrity_check.
    assert "ONLY thing" not in mod.MONITORS["Integrity-check scheduler absent >25h"][2]
    assert "ONLY thing" not in TF


def test_runbook_cites_the_script_and_the_section():
    rb = open(os.path.join(ROOT, "ops", "RUNBOOK.md"), encoding="utf-8").read()
    assert "## 56." in rb and "apply_absence_policy_hardening.py" in rb
    assert "§56" in TF and "section 56" in mod.TRIAGE


# ---- the script's own pure logic (no network) -------------------------------------------------------------
def _live(duration="0s", cname="Backup scheduler absent >25h", doc=None):
    return {
        "name": "projects/p/alertPolicies/1",
        "displayName": "Integrity-check scheduler absent >25h",
        "conditions": [
            {
                "name": "projects/p/alertPolicies/1/conditions/2",
                "displayName": cname,
                "conditionPrometheusQueryLanguage": {
                    "query": "absent_over_time(x[25h])",
                    "duration": duration,
                    "evaluationInterval": "30s",
                },
            }
        ],
        **({"documentation": {"content": doc, "mimeType": "text/markdown"}} if doc else {}),
    }


def test_desired_preserves_query_interval_and_condition_name():
    cfg, cname, doc = mod.MONITORS["Integrity-check scheduler absent >25h"]
    body, why = mod.desired(_live(), cfg, cname, doc)
    assert why is None
    c = body["conditions"][0]
    assert c["name"] == "projects/p/alertPolicies/1/conditions/2"
    prom = c["conditionPrometheusQueryLanguage"]
    assert prom["query"] == "absent_over_time(x[25h])" and prom["evaluationInterval"] == "30s"
    assert prom["duration"] == mod.DURATION and c["displayName"] == cname
    assert cfg in body["documentation"]["content"] and "<id>" not in body["documentation"]["content"]


def test_idempotent_and_skips_unpatchable():
    cfg, cname, doc = mod.MONITORS["Integrity-check scheduler absent >25h"]
    body, _ = mod.desired(_live(), cfg, cname, doc)
    assert not mod.matches(_live(), body)  # stale live -> would patch
    hardened = _live(mod.DURATION, cname, body["documentation"]["content"])
    assert mod.matches(hardened, body)  # already hardened -> skipped
    multi = _live()
    multi["conditions"] = multi["conditions"] * 2
    assert mod.desired(multi, cfg, cname, doc)[0] is None  # never silently drop a second condition
    non_prom = {"conditions": [{"displayName": "x", "conditionThreshold": {}}]}
    assert mod.desired(non_prom, cfg, cname, doc)[0] is None
    json.dumps(body)  # serialisable
