"""Guard scripts/check_prose_invariants.py — the BLOCKING prose-invariant CI gate (finding H6).

check_prose_invariants.py runs at .github/workflows/ci.yml as a bare (non-zero-exit-fails) gate, yet
— unlike its offline single-source siblings (test_cadence_consistency.py, test_roster_consistency.py,
test_autonomy_consistency.py) — it had NO dedicated test. A benign tightening of a forbid_regex that
silently stops matching the retired phrasing would exit 0 (a vacuous pass) with nothing to catch it;
and the exempt_line_regex / exempt_sections / nearest_heading branches have literally never run in
production (the live ops/prose_invariants.yaml uses none of them). These tests exercise every branch
against tmp_path spec + fixture files (never the real files), and assert the exact printed contract.
"""
import yaml

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
