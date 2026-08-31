"""Guard scripts/check_prose_invariants.py — the BLOCKING prose-invariant CI gate (finding H6).

check_prose_invariants.py runs at .github/workflows/ci.yml as a bare (non-zero-exit-fails) gate, yet
— unlike its offline single-source siblings (test_cadence_consistency.py, test_roster_consistency.py,
test_autonomy_consistency.py) — it had NO dedicated test. A benign tightening of a forbid_regex that
silently stops matching the retired phrasing would exit 0 (a vacuous pass) with nothing to catch it.
CORRECTION (2026-08-31 code-quality pass, prose-scope#1): the exempt_sections / nearest_heading
branches have never run against the live ops/prose_invariants.yaml (a grep for a live
`exempt_sections:` key is still empty), but exempt_line_regex now DOES — it went live on
`market_only_orders` on 2026-07-21 and on `retired_car_envelopes_not_operational` on 2026-08-07, and
dropping it today would false-fail CI on real, currently-legitimate historical/changelog lines in
Claude_Task_Plan.md and Operating_Protocols.md. These tests exercise every branch against tmp_path
spec + fixture files (never the real files), and assert the exact printed contract.
"""
from copy import deepcopy
from pathlib import Path

import yaml
import pytest

from conftest import load_module_from_path

cpi = load_module_from_path("check_prose_invariants", "scripts", "check_prose_invariants.py")


def _run(tmp_path, monkeypatch, rules, files):
    """Write `files` ({relpath: content}) + a spec of `rules` under tmp_path, point the module's
    SPEC/ROOT at them, and return cpi.main()'s exit code."""
    for rel, content in files.items():
        p = tmp_path / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")
    spec = tmp_path / "prose_invariants.yaml"
    spec.write_text(yaml.safe_dump({"invariants": rules}, allow_unicode=True), encoding="utf-8")
    monkeypatch.setattr(cpi, "SPEC", str(spec))
    monkeypatch.setattr(cpi, "ROOT", str(tmp_path))
    return cpi.main()


def _actual_rules(*ids):
    """Return copies of named production rules, so regression examples exercise their real regexes."""
    spec = Path(__file__).resolve().parents[1] / "ops" / "prose_invariants.yaml"
    rules = {rule["id"]: rule for rule in yaml.safe_load(spec.read_text(encoding="utf-8"))["invariants"]}
    return [deepcopy(rules[rid]) for rid in ids]


def _rev19_clean_files(rules):
    """A minimally correct document for every target used by the selected Rev-19 rules."""
    return {
        rel: "The thesis budget has no numeric ceiling; size needs seven-factor justification.\n"
        for rule in rules for rel in rule["files"]
    }


# ---- load_spec() / files_for() unit behavior --------------------------------------------------

def test_load_spec_returns_invariants_list(tmp_path, monkeypatch):
    spec = tmp_path / "s.yaml"
    spec.write_text("invariants:\n  - id: a\n    files: [x.md]\n    require_regex: foo\n", encoding="utf-8")
    monkeypatch.setattr(cpi, "SPEC", str(spec))
    rules = cpi.load_spec()
    assert rules == [{"id": "a", "files": ["x.md"], "require_regex": "foo"}]


def test_load_spec_empty_doc_returns_empty_list(tmp_path, monkeypatch):
    spec = tmp_path / "s.yaml"
    spec.write_text("", encoding="utf-8")  # yaml.safe_load("") is None -> `or {}` -> {}
    monkeypatch.setattr(cpi, "SPEC", str(spec))
    assert cpi.load_spec() == []


def test_files_for_supports_both_files_and_file_keys():
    assert cpi.files_for({"files": ["a.md", "b.md"]}) == ["a.md", "b.md"]
    assert cpi.files_for({"file": "a.md"}) == ["a.md"]
    assert cpi.files_for({}) == []


# ---- forbid_regex: the retired-instruction guard ----------------------------------------------

def test_forbid_regex_matching_nonexempt_line_fails(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "no_ledger", "files": ["Doc.md"], "forbid_regex": "write to Portfolio_Ledger"}],
              {"Doc.md": "intro line\nplease write to Portfolio_Ledger now\nother\n"})
    assert rc == 1
    out = capsys.readouterr().out
    assert "PROSE INVARIANTS: FAIL" in out
    assert "Doc.md:2:" in out                       # 1-based line number of the offending line
    assert "RETIRED instruction re-appeared" in out


def test_forbid_regex_no_match_passes(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "no_ledger", "files": ["Doc.md"], "forbid_regex": "write to Portfolio_Ledger"}],
              {"Doc.md": "nothing retired here\nall good\n"})
    assert rc == 0
    assert "PROSE INVARIANTS: OK" in capsys.readouterr().out


# ---- adversarial-review transcript storage cutover ---------------------------------------------

def test_root_adversarial_review_transcript_fails_even_when_untracked(tmp_path, monkeypatch, capsys):
    # This is a filesystem guard, not a `git ls-files` guard: a generated root transcript is already
    # a split-brain hand-off before someone accidentally stages it.
    rc = _run(tmp_path, monkeypatch,
              [{"id": "safe", "files": ["Doc.md"], "require_regex": "safe"}],
              {"Doc.md": "safe\n", "Adversarial_Review_demo_attacker.md": "duplicate\n"})
    assert rc == 1
    assert "tracked or generated root review transcript" in capsys.readouterr().out


def test_active_review_file_write_and_output_path_handoff_fail(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "safe", "files": ["Doc.md"], "require_regex": "safe"}],
              {
                  "Doc.md": "safe\n",
                  "ops/cadence.yaml": (
                      "writes: [events.adversarial_reviews, "
                      "Adversarial_Review_*_attacker.md]\n"
                  ),
                  "Claude_Task_Plan.md": (
                      "Write attack to Adversarial_Review_<id>_attacker.md.\n"
                      "Set attacker_output_path after completion.\n"
                  ),
              })
    assert rc == 1
    out = capsys.readouterr().out
    assert "ops/cadence.yaml:1: active write" in out
    assert "Claude_Task_Plan.md:1: active write" in out
    assert "Claude_Task_Plan.md:2: active *_output_path hand-off" in out


def test_review_storage_guard_covers_canonical_and_generated_sources(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "safe", "files": ["Doc.md"], "require_regex": "safe"}],
              {
                  "Doc.md": "safe\n",
                  "Experiment_Parameters.md": (
                      "queue-driven via Pending_Adversarial_Reviews.md\n"
                      "The Orchestrator reads the attacker output file.\n"
                  ),
                  "Strategy.md": "Written to Adversarial_Review_<id>_attacker.md.\n",
                  "strategy/02_regime_router.md": (
                      "The Orchestrator reads the attacker output file.\n"
                  ),
                  "task_plan/AR_orc.md": "The Orchestrator reads the attacker file.\n",
              })
    assert rc == 1
    out = capsys.readouterr().out
    assert "Experiment_Parameters.md:1: active use of retired" in out
    assert "Experiment_Parameters.md:2: active local transcript file hand-off" in out
    assert "Strategy.md:1: active write" in out
    assert "strategy/02_regime_router.md:1: active local transcript file hand-off" in out
    assert "task_plan/AR_orc.md:1: active local transcript file hand-off" in out


def test_negated_output_path_reference_is_allowed(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "safe", "files": ["Doc.md"], "require_regex": "safe"}],
              {
                  "Doc.md": "safe\n",
                  "Experiment_Parameters.md": "Do not set attacker_output_path in the queue payload.\n",
              })
    assert rc == 0
    assert "PROSE INVARIANTS: OK" in capsys.readouterr().out


def test_shared_plan_exposes_the_full_positional_review_writer_contract():
    plan = (Path(__file__).resolve().parents[1] / "Claude_Task_Plan.md").read_text(encoding="utf-8")
    expected = (
        "review_id`, `review_type`, `strategy`, `role`, `review_date`, `cycle_number`, "
        "`verdict`, `theater_check`, `weaknesses`, `artifact_path`, `body_md`, "
        "`expected_sha256`, `source_commit_sha`, `queue_event_id`, `superseded_by`"
    )
    assert "AR transcript writer — positional call contract" in plan
    assert "CALL ops.sp_write_adversarial_review(" in plan
    assert expected in plan


def test_active_review_file_write_cannot_hide_in_a_wrapped_cadence_list(
        tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "safe", "files": ["Doc.md"], "require_regex": "safe"}],
              {
                  "Doc.md": "safe\n",
                  "ops/cadence.yaml": (
                      "writes: [events.adversarial_reviews, events.decision_log,\n"
                      "         Adversarial_Review_*_orchestrator.md]\n"
                  ),
              })
    assert rc == 1
    assert "ops/cadence.yaml:1: active write" in capsys.readouterr().out


def test_retired_review_history_and_blinding_reference_remain_allowed(tmp_path, monkeypatch):
    # The filename alone remains legitimate in a redirect note or an explicit do-not-read rule.
    rc = _run(tmp_path, monkeypatch,
              [{"id": "safe", "files": ["Doc.md"], "require_regex": "safe"}],
              {
                  "Doc.md": "safe\n",
                  "ops/cadence.yaml": "writes: [events.adversarial_reviews]\n",
                  "Claude_Task_Plan.md": (
                      "`Adversarial_Review_*.md` is retired; do not read it.\n"
                      "Do not create `Adversarial_Review_<id>_attacker.md`.\n"
                      "Read the attacker by review id, cycle number, and role from "
                      "state.adversarial_reviews_current.\n"
                      "~~Write to Adversarial_Review_<id>_attacker.md.~~\n"
                  ),
              })
    assert rc == 0


def test_durable_review_file_claim_fails(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "safe", "files": ["Doc.md"], "require_regex": "safe"}],
              {
                  "Doc.md": "safe\n",
                  "Claude_Task_Plan.md": (
                      "The durable record includes per-review output files "
                      "(Adversarial_Review_<id>_attacker.md).\n"
                  ),
              })
    assert rc == 1
    assert "described as a durable record" in capsys.readouterr().out


def test_match_paragraph_catches_soft_wrapped_forbid_and_reports_first_line(
        tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "wrapped", "files": ["Doc.md"], "forbid_regex": r"CaR.*10%",
                "match_paragraph": True}],
              {"Doc.md": "safe intro\n\nPer-name CaR must not exceed\n10% of NAV.\n"})
    assert rc == 1
    assert "Doc.md:3:" in capsys.readouterr().out


def test_match_paragraph_keeps_blank_lines_as_hard_boundaries(tmp_path, monkeypatch):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "wrapped", "files": ["Doc.md"], "forbid_regex": r"CaR.*10%",
                "match_paragraph": True}],
              {"Doc.md": "Per-name CaR must not exceed\n\n10% of NAV.\n"})
    assert rc == 0


def test_match_wrapped_lines_catches_adjacent_soft_wrap_and_reports_first_line(
        tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "wrapped", "files": ["Doc.md"], "forbid_regex": r"CaR.*10%",
                "match_wrapped_lines": True}],
              {"Doc.md": "Per-name CaR must not exceed\n10% of NAV.\n"})
    assert rc == 1
    assert "Doc.md:1:" in capsys.readouterr().out


def test_match_wrapped_lines_keeps_blank_and_sibling_bullet_boundaries(tmp_path, monkeypatch):
    rule = [{"id": "wrapped", "files": ["Doc.md"], "forbid_regex": r"CaR.*10%",
             "match_wrapped_lines": True}]
    assert _run(tmp_path, monkeypatch, rule,
                {"Doc.md": "Per-name CaR must not exceed\n\n10% of NAV.\n"}) == 0
    # These are distinct list items; joining them would synthesize a prohibited sentence.
    assert _run(tmp_path, monkeypatch, rule,
                {"Doc.md": "- CaR is defined in this glossary.\n- 10% is an unrelated example.\n"}) == 0


def test_exempt_line_regex_suppresses_a_sanctioned_line(tmp_path, monkeypatch):
    # The line matches forbid_regex but ALSO matches exempt_line_regex (a §15 redirect-map line) -> skip.
    rc = _run(tmp_path, monkeypatch,
              [{"id": "no_ledger", "files": ["Doc.md"],
                "forbid_regex": "write to Portfolio_Ledger",
                "exempt_line_regex": r"§15"}],
              {"Doc.md": "§15: do NOT write to Portfolio_Ledger (retired)\n"})
    assert rc == 0


def test_exempt_sections_suppresses_match_under_named_heading(tmp_path, monkeypatch):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "no_ledger", "files": ["Doc.md"],
                "forbid_regex": "write to Portfolio_Ledger",
                "exempt_sections": ["Redirect map"]}],
              {"Doc.md": "## §15 Redirect map\nlegacy: write to Portfolio_Ledger\n"})
    assert rc == 0


def test_exempt_sections_fenced_code_comment_does_not_hijack_the_heading(tmp_path, monkeypatch):
    # BUG FIX (2026-07-17): a '# comment' inside a ``` fence between the real exempt heading and the
    # forbid match must NOT be mistaken for the nearest heading. Without fence tracking, nearest_heading
    # returned the code comment (which lacks the exempt substring) -> the sanctioned passage FAILED CI.
    doc = (
        "## §15 Redirect map\n"
        "example:\n"
        "```python\n"
        "# write to Portfolio_Ledger  (this hash line is a code comment, not a heading)\n"
        "```\n"
        "legacy note: write to Portfolio_Ledger (retired, see above)\n"
    )
    rc = _run(tmp_path, monkeypatch,
              [{"id": "no_ledger", "files": ["Doc.md"],
                "forbid_regex": "write to Portfolio_Ledger",
                "exempt_line_regex": r"code comment",   # exempt the line INSIDE the fence itself
                "exempt_sections": ["Redirect map"]}],
              {"Doc.md": doc})
    assert rc == 0  # the trailing match is exempted via the REAL §15 heading, not the fenced comment


def test_forbid_match_inside_a_fence_is_still_reported_without_exempt_sections(tmp_path, monkeypatch):
    # Scope guard: the fence fix only affects heading attribution for exempt_sections. A forbid match
    # is still reported even when it sits inside a code fence (no exempt_sections in play).
    rc = _run(tmp_path, monkeypatch,
              [{"id": "no_ledger", "files": ["Doc.md"], "forbid_regex": "write to Portfolio_Ledger"}],
              {"Doc.md": "```\nwrite to Portfolio_Ledger\n```\n"})
    assert rc == 1


def test_ignorecase_flag_makes_forbid_case_insensitive(tmp_path, monkeypatch):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "ci", "files": ["Doc.md"], "forbid_regex": "portfolio_ledger", "ignorecase": True}],
              {"Doc.md": "WRITE TO PORTFOLIO_LEDGER\n"})
    assert rc == 1


# ---- require_regex: the load-bearing-phrasing guard -------------------------------------------

def test_require_regex_present_passes(tmp_path, monkeypatch):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "computed", "files": ["README.md"], "require_regex": "ascending numeric order"}],
              {"README.md": "apply bigquery files in ascending numeric order\n"})
    assert rc == 0


def test_require_regex_absent_fails_with_reason(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "computed", "files": ["README.md"], "require_regex": "ascending numeric order",
                "reason": "must be computed", "source_of_truth": "bigquery/README.md"}],
              {"README.md": "apply bigquery/01..11_*.sql\n"})
    assert rc == 1
    out = capsys.readouterr().out
    assert "REQUIRED phrasing not found" in out
    assert "must be computed" in out and "bigquery/README.md" in out


def test_require_regex_is_matched_per_physical_line_not_across_lines(tmp_path, monkeypatch):
    # Rules match one physical line at a time (documented contract); a regex meant to span a line
    # break can never match. This locks that so re.MULTILINE is not silently reintroduced.
    rc = _run(tmp_path, monkeypatch,
              [{"id": "span", "files": ["Doc.md"], "require_regex": "foo.*bar"}],
              {"Doc.md": "foo\nbar\n"})
    assert rc == 1  # "foo" and "bar" are on separate lines -> no single-line match -> require fails


def test_ignore_strikethrough_applies_to_require_rules(tmp_path, monkeypatch):
    # A retired rendering of a doctrine must not keep its load-bearing require rule green.
    rule = [{"id": "doctrine", "files": ["Doc.md"], "require_regex": "no numeric ceiling",
             "ignore_strikethrough": True}]
    assert _run(tmp_path, monkeypatch, rule, {"Doc.md": "~~no numeric ceiling~~\n"}) == 1
    assert _run(tmp_path, monkeypatch, rule,
                {"Doc.md": "~~old words~~; current policy has no numeric ceiling.\n"}) == 0


def test_ignore_strikethrough_handles_valid_multiline_spans_and_keeps_live_text(tmp_path, monkeypatch):
    # The scanner preserves physical line positions while treating a paired, multi-line Markdown
    # span as historical.  Text after its closing delimiter remains active and is still caught.
    rule = [{"id": "no_cap", "files": ["Doc.md"], "forbid_regex": "CaR.*10%",
             "ignore_strikethrough": True}]
    assert _run(tmp_path, monkeypatch, rule,
                {"Doc.md": "~~Per-name CaR\nremains capped at 10%~~\n"}) == 0
    assert _run(tmp_path, monkeypatch, rule,
                {"Doc.md": "~~old CaR 10%~~; live CaR is capped at 10%\n"}) == 1


def test_unmatched_strikethrough_delimiter_is_not_silently_exempted(tmp_path, monkeypatch):
    # Only a valid *paired* span is historical; treating an unmatched delimiter as a comment could
    # conceal a live instruction after a typo.
    rule = [{"id": "no_cap", "files": ["Doc.md"], "forbid_regex": "CaR.*10%",
             "ignore_strikethrough": True}]
    assert _run(tmp_path, monkeypatch, rule, {"Doc.md": "~~live CaR is capped at 10%\n"}) == 1


# ---- rule-shape validation --------------------------------------------------------------------

def test_rule_with_both_forbid_and_require_errors(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "both", "files": ["Doc.md"], "forbid_regex": "x", "require_regex": "y"}],
              {"Doc.md": "z\n"})
    assert rc == 1
    assert "EXACTLY ONE of forbid_regex / require_regex" in capsys.readouterr().out


def test_rule_with_neither_forbid_nor_require_errors(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "neither", "files": ["Doc.md"]}],
              {"Doc.md": "z\n"})
    assert rc == 1
    assert "EXACTLY ONE of forbid_regex / require_regex" in capsys.readouterr().out


def test_rule_with_no_files_errors(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "nofiles", "forbid_regex": "x"}],
              {})
    assert rc == 1
    assert "names no files" in capsys.readouterr().out


def test_missing_target_file_errors(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "gone", "files": ["Missing.md"], "forbid_regex": "x"}],
              {})  # Missing.md is never written
    assert rc == 1
    assert "file not found" in capsys.readouterr().out


def test_duplicate_rule_id_errors(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "dup", "files": ["Doc.md"], "require_regex": "ok"},
               {"id": "dup", "files": ["Doc.md"], "require_regex": "ok"}],
              {"Doc.md": "ok\n"})
    assert rc == 1
    assert "duplicate rule id: dup" in capsys.readouterr().out


def test_missing_rule_id_errors(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"files": ["Doc.md"], "require_regex": "ok"}],
              {"Doc.md": "ok\n"})
    assert rc == 1
    assert "missing its `id`" in capsys.readouterr().out


def test_no_rules_returns_1(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch, [], {})
    assert rc == 1
    assert "no rules found" in capsys.readouterr().out


# ---- OK summary + real-spec happy path --------------------------------------------------------

def test_ok_summary_counts_invariants_and_file_targets(tmp_path, monkeypatch, capsys):
    rc = _run(tmp_path, monkeypatch,
              [{"id": "a", "files": ["A.md", "B.md"], "require_regex": "keep"},
               {"id": "b", "files": ["A.md"], "forbid_regex": "banned"}],
              {"A.md": "keep this\n", "B.md": "keep that\n"})
    assert rc == 0
    out = capsys.readouterr().out
    # 2 invariants, 3 file-targets (A.md+B.md, then A.md again).
    assert "2 invariants checked across 3 file-targets" in out


def test_real_prose_invariants_spec_passes():
    # Happy-path sanity like the sibling '*_against_real_files_is_clean' tests: the committed
    # ops/prose_invariants.yaml must hold against the committed prose files (no monkeypatch — uses
    # the module's real SPEC/ROOT).
    assert cpi.main() == 0


def test_d1_event_identity_gate_rule_fails_when_the_earnings_guard_is_removed(tmp_path, monkeypatch):
    """A calendar date is not proof that a fiscal-quarter report occurred (CRM, 2026-08-12)."""
    (rule,) = _actual_rules("d1_event_identity_gate_present")
    assert _run(
        tmp_path,
        monkeypatch,
        [rule],
        {"Claude_Task_Plan.md": "D1 records scheduled events and assesses held positions.\n"},
    ) == 1


def test_d2a_open_withdrawal_candidate_gate_fails_when_removed(tmp_path, monkeypatch):
    """A clean current residual must not hide an older open withdrawal candidate."""
    (rule,) = _actual_rules("d2a_open_withdrawal_candidate_gate_present")
    assert _run(
        tmp_path,
        monkeypatch,
        [rule],
        {"Claude_Task_Plan.md": "D2a checks only the current-session cash residual.\n"},
    ) == 1


def test_d2_exit_staging_write_time_echo_gate_fails_when_removed(tmp_path, monkeypatch):
    """EXIT_PENDING must be SELECT-derived, not a sparse hand-composed lifecycle replacement."""
    (rule,) = _actual_rules("d2_exit_staging_write_time_echo_present")
    assert _run(
        tmp_path,
        monkeypatch,
        [rule],
        {"Claude_Task_Plan.md": "D2 writes an EXIT_PENDING row after staging an exit.\n"},
    ) == 1


def test_position_metadata_carry_forward_doctrine_fails_when_removed(tmp_path, monkeypatch):
    """Shared prose must not revert to the pre-169 claim that every live field is latest-only."""
    (rule,) = _actual_rules("position_metadata_carry_forward_doctrine_present")
    assert _run(
        tmp_path,
        monkeypatch,
        [rule],
        {"Claude_Task_Plan.md": "state.current_positions has no carry-forward behavior.\n"},
    ) == 1


def test_d2a_snapshot_failure_scope_gate_fails_when_removed(tmp_path, monkeypatch):
    """Every missing target snapshot defers its craft; a healthy probe only narrows scope."""
    (rule,) = _actual_rules("d2a_snapshot_failure_scope_gate_present")
    assert _run(
        tmp_path,
        monkeypatch,
        [rule],
        {"Claude_Task_Plan.md": "D2a may use an unrelated probe after a target quote error.\n"},
    ) == 1


def test_snapshot_alert_recovery_scope_gate_fails_when_removed(tmp_path, monkeypatch):
    """A healthy SPY probe cannot clear a different symbol's outage."""
    (rule,) = _actual_rules("snapshot_alert_recovery_scope_present")
    assert _run(
        tmp_path,
        monkeypatch,
        [rule],
        {"Claude_Task_Plan.md": "OPS1 clears every IBKR snapshot alert after SPY succeeds.\n"},
    ) == 1


# ---- Rev 19 no-CaR-envelope regression rules ---------------------------------------------------

def test_rev19_rule_covers_each_canonical_and_operational_source():
    rule, active_numeric, direct_numeric, legacy_sizing, doctrine = _actual_rules(
        "retired_car_envelopes_not_operational",
        "active_numeric_car_caps_not_operational",
        "direct_or_symbolic_car_caps_not_operational",
        "retired_fixed_two_percent_and_envelope_sizing_not_operational",
        "no_ceiling_sizing_doctrine_present",
    )
    expected = {
        "Experiment_Parameters.md", "AI_Trading_Foundation.md", "AI_DECISION_REDESIGN.md",
        "Operating_Protocols.md", "Strategy.md", "Claude_Task_Plan.md", "task_plan/D2.md",
        "task_plan/SL2.md",
    }
    assert set(rule["files"]) == expected
    assert set(active_numeric["files"]) == expected
    assert set(direct_numeric["files"]) == expected
    assert set(doctrine["files"]) == expected
    # D1 is a generated executable slice. Its source is Claude_Task_Plan.md and slice-sync verifies
    # derivation; scanning it here additionally makes a stale regeneration fail the prose gate.
    assert set(legacy_sizing["files"]) == expected | {"task_plan/D1.md"}


def test_rev19_actual_rules_fail_when_correct_no_ceiling_text_coexists_with_a_reinstated_cap(
        tmp_path, monkeypatch):
    # Presence of the current phrase is insufficient: the alert recurred because a retired constraint
    # remained operative in a document that otherwise described the new policy correctly.
    rules = _actual_rules("retired_car_envelopes_not_operational",
                          "no_ceiling_sizing_doctrine_present")
    files = _rev19_clean_files(rules)
    files["Experiment_Parameters.md"] += "Per-name CaR must not exceed 10% of strategy NAV.\n"
    assert _run(tmp_path, monkeypatch, rules, files) == 1


def test_rev19_actual_doctrine_rule_does_not_accept_struck_only_current_policy(
        tmp_path, monkeypatch):
    (rule,) = _actual_rules("no_ceiling_sizing_doctrine_present")
    files = _rev19_clean_files([rule])
    files["Strategy.md"] = "~~no numeric ceiling~~\n"
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


@pytest.mark.parametrize("rel, stale_instruction", [
    ("AI_Trading_Foundation.md", "A single-name Capital at Risk budget is capped at 10 percent.\n"),
    ("Operating_Protocols.md", "Total deployed strategy CaR must stay below 75%.\n"),
    ("Claude_Task_Plan.md", "A new candidate is bounded by the current hard envelopes.\n"),
])
def test_rev19_actual_retired_envelope_rule_rejects_normal_rephrasings(
        tmp_path, monkeypatch, rel, stale_instruction):
    # Do not regress to an inventory of the last incident's exact sentences.
    (rule,) = _actual_rules("retired_car_envelopes_not_operational")
    files = _rev19_clean_files([rule])
    files[rel] += stale_instruction
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


def test_rev19_actual_retired_envelope_rule_allows_explicitly_retired_historical_text(
        tmp_path, monkeypatch):
    (rule,) = _actual_rules("retired_car_envelopes_not_operational")
    files = _rev19_clean_files([rule])
    files["Strategy.md"] = "~~Per-name CaR must not exceed 10% hard envelope~~ [RETIRED 2026-08-05].\n"
    assert _run(tmp_path, monkeypatch, [rule], files) == 0


def test_rev19_actual_rule_ignores_only_struck_text_not_a_live_cap_on_the_same_line(
        tmp_path, monkeypatch):
    (rule,) = _actual_rules("retired_car_envelopes_not_operational")
    files = _rev19_clean_files([rule])
    files["Strategy.md"] = "~~Per-name CaR must not exceed 10% hard envelope~~.\n"
    assert _run(tmp_path, monkeypatch, [rule], files) == 0

    files["Strategy.md"] = (
        "~~The old per-name CaR cap was 10%~~. Per-name CaR is capped at 10%.\n"
    )
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


def test_rev19_active_cap_rule_is_not_bypassed_by_retirement_narrative_on_the_same_line(
        tmp_path, monkeypatch):
    (rule,) = _actual_rules("active_numeric_car_caps_not_operational")
    files = _rev19_clean_files([rule])
    files["Strategy.md"] = "Former envelope retired. Per-name CaR is capped at 10%.\n"
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


@pytest.mark.parametrize("stale_instruction", [
    "Per-name CaR ≤ 10% of NAV.\n",
    "Deployed Capital-at-Risk <= 75 percent.\n",
    "Per-name Capital-at-Risk allocation is 10%.\n",
    "Per-strategy CaR remains limited to 75%.\n",
    "Aggregate CaR continues in force at 10%.\n",
    "The old policy is retired outright; per-name Capital-at-Risk <= 10%.\n",
    "Current sizing has no numeric ceiling; per-name Capital-at-Risk allocation is 10%.\n",
    "Current sizing has no numeric ceiling; per-name Capital-at-Risk has a hard 10% envelope.\n",
    "Per-name CaR <= 10%; current sizing has no numeric ceiling.\n",
    "Per-name CaR must not exceed\n10% of NAV.\n",
    "Per-name Capital-at-Risk is capped at 10%.\n",
    "Per-name Capital-at-Risk is limited to 10%.\n",
    "Per-name risk budget is capped at 10%.\n",
    "Per-name CaR is limited to 10%.\n",
    "CaR <= 10% of strategy NAV per name.\n",
    "Capital-at-Risk = 10% of strategy NAV per name.\n",
])
def test_rev19_direct_and_symbolic_cap_rule_rejects_compact_forms(
        tmp_path, monkeypatch, stale_instruction):
    (rule,) = _actual_rules("direct_or_symbolic_car_caps_not_operational")
    files = _rev19_clean_files([rule])
    files["Strategy.md"] += stale_instruction
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


def test_rev19_direct_cap_rule_allows_clean_struck_history_but_not_mixed_live_line(
        tmp_path, monkeypatch):
    (rule,) = _actual_rules("direct_or_symbolic_car_caps_not_operational")
    files = _rev19_clean_files([rule])
    files["Strategy.md"] = "Historical example: ~~Per-name Capital-at-Risk allocation is 10%~~.\n"
    assert _run(tmp_path, monkeypatch, [rule], files) == 0

    files["Strategy.md"] = (
        "~~The old Capital-at-Risk allocation was 10%~~; per-name allocation is 10%.\n"
    )
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


@pytest.mark.parametrize("stale_instruction", [
    "Current sizing has no numeric ceiling; per-name Capital-at-Risk is capped at 10%.\n",
    "Current sizing has no numeric ceiling; per-name Capital-at-Risk allocation is 10%.\n",
    "Current sizing has no numeric ceiling; per-name Capital-at-Risk has a hard 10% envelope.\n",
    "Budgets are unbounded, but deployed CaR <= 75%.\n",
    "Per-name CaR <= 10%; current sizing has no numeric ceiling.\n",
])
def test_rev19_current_doctrine_cannot_exempt_a_same_line_live_cap(
        tmp_path, monkeypatch, stale_instruction):
    (rule,) = _actual_rules("no_ceiling_statement_cannot_hide_live_cap")
    files = _rev19_clean_files([rule])
    files["Strategy.md"] = stale_instruction
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


@pytest.mark.parametrize("rel, stale_instruction", [
    ("Claude_Task_Plan.md", "Open a fresh 2% tranche on the name.\n"),
    ("Experiment_Parameters.md", "Deploy redistribution at its own 2%-per-trade pace.\n"),
    ("Experiment_Parameters.md", "Deploy redistribution at its own 2%/trade pace.\n"),
    ("Experiment_Parameters.md", "Position sizes are 2% of each strategy allocation.\n"),
    ("Operating_Protocols.md", "Keep PROBE sizing within the standing envelopes.\n"),
    ("Operating_Protocols.md", "Scale capital, never the 2% risk fraction.\n"),
    ("Operating_Protocols.md", "$2,000 (so a 2% position is about $40).\n"),
    ("Strategy.md", "Worst-case long loss is bounded at 2%.\n"),
    ("Claude_Task_Plan.md", "Craft an executable defined-risk structure at 2% sizing.\n"),
    ("task_plan/D1.md", "Open a fresh 2% tranche on the name.\n"),
    ("Claude_Task_Plan.md", "A new 2% tranche is required for every add.\n"),
    ("Strategy.md", "Each position is 2% of strategy NAV.\n"),
    ("Operating_Protocols.md", "Maintain a 2 percent per-trade pace.\n"),
    ("Claude_Task_Plan.md", "Use concurrent, independently-funded ~2%-of-sleeve bets.\n"),
    ("Claude_Task_Plan.md", "Open a 2% tranche on every add.\n"),
    ("Strategy.md", "Each position has a fixed 2% allocation.\n"),
    ("Strategy.md", "Worst-case long loss is capped at 2 percent.\n"),
    ("Claude_Task_Plan.md", "Craft a defined-risk structure with 2 percent sizing.\n"),
    ("Operating_Protocols.md", "Maintain a 2 percent risk fraction.\n"),
])
def test_rev19_fixed_two_percent_and_generic_envelope_rule_rejects_audited_families(
        tmp_path, monkeypatch, rel, stale_instruction):
    (rule,) = _actual_rules("retired_fixed_two_percent_and_envelope_sizing_not_operational")
    files = _rev19_clean_files([rule])
    files[rel] += stale_instruction
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


@pytest.mark.parametrize("stale_instruction", [
    "The former envelopes are retired. New theses remain bounded by the hard envelopes.\n",
    "Historical policy was retired. Envelope-based magnitude-only mitigation applies to every thesis.\n",
    "The old rule is superseded. Keep sizing toward the lower end of the 10% per-name envelope.\n",
    "The envelope is historical. Worst-case loss is 10%, a 5x increase.\n",
])
def test_rev19_active_envelope_phrases_are_not_bypassed_by_retirement_words(
        tmp_path, monkeypatch, stale_instruction):
    (rule,) = _actual_rules("active_numeric_car_caps_not_operational")
    files = _rev19_clean_files([rule])
    files["Strategy.md"] = stale_instruction
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


# ---- market_only_orders: exempt_line_regex must require proximity, not a bare word match -------

def test_market_only_orders_rule_not_bypassed_by_a_distant_unrelated_retirement(tmp_path, monkeypatch):
    # 2026-08-08 bug: exempt_line_regex was a bare '(?:retired|supersede[sd]?|RETIRES)' match ANYWHERE
    # on the line, so a line naming an unrelated retirement in one clause could re-instruct
    # order_type=LIMIT in a later, disconnected clause and still pass the gate silently. The two
    # clauses below are ~280 chars apart (see ops/prose_invariants.yaml's comment on the fix) — one
    # names the retirement of the (unrelated) daily-staging-cap liquidity backstop, the other
    # re-instructs a live limit order; they are plainly about different things, not one sentence
    # explaining the forbidden term's own retirement.
    (rule,) = _actual_rules("market_only_orders")
    stale_instruction = (
        "The legacy pre-2026 daily-staging-cap backstop that used to recompute a liquidity and "
        "sizing verdict from the payload is retired outright, per the 2026-07-22 pre-trade rail "
        "strip; nothing about that unrelated change touches how a routine should reference an old "
        "resting order's price when it re-crafts a still-open position tomorrow morning well before "
        "the market even opens for the day. Craft every entry with order_type=LIMIT for tighter fills.\n"
    )
    files = {"Claude_Task_Plan.md": stale_instruction, "Operating_Protocols.md": "unrelated text\n"}
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


def test_market_only_orders_rule_still_exempts_a_genuine_proximate_supersession(tmp_path, monkeypatch):
    # Companion to the above: the exemption must still fire when the retirement language IS talking
    # about the forbidden term in the same clause, the way the real prose files' ENTRY/EXIT DECISION
    # and changelog lines do (ops/prose_invariants.yaml's comment cites the ~244-char real example).
    (rule,) = _actual_rules("market_only_orders")
    files = {
        "Claude_Task_Plan.md": (
            "ENTRY/EXIT DECISION (market-only) supersedes the retired LIMIT DECISION judgment.\n"
        ),
        "Operating_Protocols.md": "unrelated text\n",
    }
    assert _run(tmp_path, monkeypatch, [rule], files) == 0


def test_market_only_orders_rule_rejects_a_same_line_different_clause_reinstruction(tmp_path, monkeypatch):
    # 2026-08-08, second pass: the 260-char proximity fix above closed the *bare word* bypass but its
    # own commit comment overclaimed that it checks the retirement language is "actually talking
    # about" the forbidden term — it only counts characters. This line has TWO unrelated sentences
    # on one physical line: the first retires an unrelated mechanism (the daily-staging-cap
    # backstop), the second is a live, unrelated re-instruction to build a LIMIT order. They sit
    # ~251 chars apart — inside the OLD 260-char window (so the OLD regex wrongly exempted this
    # line, the exact gap ops/prose_invariants.yaml's comment now documents), but outside the
    # TIGHTENED 250-char window this fix ships, so it must be CAUGHT. Verified against the actual
    # production rule (not a hand-rolled copy) so this tracks whatever window is live.
    (rule,) = _actual_rules("market_only_orders")
    stale_instruction = (
        "The legacy pre-2026 daily-staging-cap backstop that used to recompute a liquidity and "
        "sizing verdict from the payload is retired outright, per the 2026-07-22 pre-trade rail "
        "strip. Nothing about that unrelated change touches how a routine references an old "
        "resting order price when it re-crafts a still-open position tomorrow morning before the "
        "market opens. Craft the order with order_type=LIMIT for tighter fills.\n"
    )
    files = {"Claude_Task_Plan.md": stale_instruction, "Operating_Protocols.md": "unrelated text\n"}
    assert _run(tmp_path, monkeypatch, [rule], files) == 1


# ---- fence_mask() / nearest_heading() units (the fix, in isolation) ---------------------------

def test_fence_mask_marks_lines_inside_a_fence():
    lines = ["## Heading", "```", "# fake", "```", "after"]
    assert cpi.fence_mask(lines) == [False, True, True, False, False]


def test_nearest_heading_skips_fenced_code_comment():
    lines = ["## Real Heading", "```", "# fake heading", "```", "match line"]
    mask = cpi.fence_mask(lines)
    assert cpi.nearest_heading(lines, 4, mask) == "Real Heading"
    # Without the mask (legacy behavior) the fenced comment wins — this is exactly the bug the mask fixes.
    assert cpi.nearest_heading(lines, 4, None) == "fake heading"


def test_nearest_heading_returns_empty_when_no_heading_precedes():
    assert cpi.nearest_heading(["plain", "text", "here"], 2) == ""
