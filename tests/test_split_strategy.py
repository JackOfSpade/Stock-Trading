"""Guard scripts/split_strategy.py's Strategy.md -> strategy/*.md slicing (P3-1).

split_strategy.py is the one script in scripts/ that had NO dedicated test file before this one
(its only guard was `python scripts/split_strategy.py --check` in CI against the real, current
Strategy.md — which never exercises edge cases the live file doesn't happen to hit). These tests
run entirely against tmp_path fixtures (never the real Strategy.md / strategy/ directory), so
nothing here can touch or drift the real committed slices.
"""
from conftest import load_module_from_path

ss = load_module_from_path("split_strategy", "scripts", "split_strategy.py")


# ---- slug() ------------------------------------------------------------------------------------

def test_slug_plain_heading():
    assert ss.slug("Entry Rules") == "entry_rules"
    # non-alnum runs (incl. leading/trailing whitespace and punctuation) collapse to single "_"
    assert ss.slug("  Position Sizing & Risk!  ") == "position_sizing_risk"


def test_slug_strategy_letter_heading_drops_everything_after_the_letter():
    # The "Strategy C: ..." rewrite rule (slug()'s first re.sub) fires for any single letter and
    # discards everything after "Strategy <letter>:", regardless of how long/varied the rest of the
    # title is.
    assert ss.slug("Strategy C: Momentum Breakout (High Vol)") == "strategy_c"
    assert ss.slug("Strategy A: X") == "strategy_a"
    # A code past today's A-E roster (SISA can adopt up to roster.yaml's n_max autonomously) must
    # collapse the same way, so the slice filename stays resolvable to a roster code.
    assert ss.slug("Strategy F: Something") == "strategy_f"
    # A multi-letter word where the code goes is not a code -> generic slugify.
    assert ss.slug("Strategy Overview: Something") == "strategy_overview_something"


def test_slug_collisions_produce_identical_strings():
    # slug() itself has no dedup logic -- two differently-worded headings that normalize to the
    # same text collide to the identical slug. Disambiguation, if any, is the caller's job.
    assert ss.slug("Foo   Bar!!") == "foo_bar"
    assert ss.slug("Foo -- Bar") == "foo_bar"
    assert ss.slug("Foo   Bar!!") == ss.slug("Foo -- Bar")


def test_build_collision_suffix_loop_is_never_triggered_by_the_index_prefix(tmp_path, monkeypatch):
    # build()'s dedup loop is `while name in used: name = name[:-3] + "_.md"` (trailing underscore
    # before the extension, not a "_2"-style counter) -- but every generated name is first prefixed
    # with its 1-based section index ("{i:02d}_..."), and that index is unique per section by
    # construction (enumerate(sections, 1)). So two headings that collide after slug() still land
    # in `files` under distinct names ("01_foo_bar.md", "02_foo_bar.md"); the while-loop body is
    # unreachable via build()'s normal call path. This test locks that observed behavior rather
    # than the loop's (currently dead) suffix mechanics.
    src = tmp_path / "Strategy.md"
    src.write_text(
        "# Title\n\nPreamble.\n\n"
        "## Foo   Bar!!\n"
        "content 1\n\n"
        "## Foo -- Bar\n"
        "content 2\n"
    )
    monkeypatch.setattr(ss, "SRC", str(src))
    monkeypatch.setattr(ss, "OUTDIR", str(tmp_path / "strategy"))
    files = ss.build()
    assert set(files) == {"00_preamble.md", "01_foo_bar.md", "02_foo_bar.md", "INDEX.md"}
    assert "content 1" in files["01_foo_bar.md"]
    assert "content 2" in files["02_foo_bar.md"]


# ---- split() -------------------------------------------------------------------------------------

def _fixture_text():
    return (
        "# Trading Strategy\n"
        "\n"
        "Some preamble intro text.\n"
        "More preamble.\n"
        "\n"
        "## Section One\n"
        "Body of section one.\n"
        "Second line.\n"
        "\n"
        "## Section Two\n"
        "Body of section two.\n"
    )


def test_split_separates_preamble_and_sections():
    preamble, sections = ss.split(_fixture_text())
    assert preamble == "# Trading Strategy\n\nSome preamble intro text.\nMore preamble.\n\n"
    assert sections == [
        ("Section One", "## Section One\nBody of section one.\nSecond line.\n\n"),
        ("Section Two", "## Section Two\nBody of section two.\n"),
    ]


def test_split_no_headings_returns_whole_text_as_preamble():
    text = "# Just a title\n\nNo top-level sections here.\n"
    preamble, sections = ss.split(text)
    assert preamble == text
    assert sections == []


def test_split_ignores_hash_headings_inside_a_fenced_code_block():
    # #14 (2026-07-17 audit): a column-0 '## ' line INSIDE a ``` fence is body, not a section
    # boundary. Without fence tracking it split the code block across two slices and truncated the
    # real section. Strategy.md sections are machine-authored (SL2) and may contain markdown examples.
    text = (
        "intro\n\n"
        "## Real Section A\n"
        "body a\n"
        "```text\n"
        "## looks like a heading but is inside a fence\n"
        "```\n"
        "more body a\n\n"
        "## Real Section B\n"
        "body b\n"
    )
    _preamble, sections = ss.split(text)
    assert [t for t, _ in sections] == ["Real Section A", "Real Section B"]
    # Section A keeps its entire body — the fenced block AND the text after it.
    assert "## looks like a heading but is inside a fence" in sections[0][1]
    assert "more body a" in sections[0][1]


# ---- build()/main(): end-to-end slice generation into a tmp_path OUTDIR --------------------------

def test_main_writes_expected_files_with_expected_content_to_tmp_path(tmp_path, monkeypatch):
    src = tmp_path / "Strategy.md"
    src.write_text(
        "# Trading Strategy\n"
        "\n"
        "Some preamble intro text.\n"
        "\n"
        "## Section One\n"
        "Body of section one.\n"
        "\n"
        "## Section Two\n"
        "Body of section two.\n"
    )
    outdir = tmp_path / "strategy"
    monkeypatch.setattr(ss, "SRC", str(src))
    monkeypatch.setattr(ss, "OUTDIR", str(outdir))

    rc = ss.main([])

    assert rc == 0
    assert sorted(p.name for p in outdir.iterdir()) == [
        "00_preamble.md", "01_section_one.md", "02_section_two.md", "INDEX.md",
    ]
    assert (outdir / "00_preamble.md").read_text() == (
        "<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.\n"
        "     Strategy.md is canonical; regenerate after editing it. -->\n\n"
        "# Trading Strategy\n\nSome preamble intro text.\n\n"
    )
    assert (outdir / "01_section_one.md").read_text() == (
        "<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.\n"
        "     Strategy.md is canonical; regenerate after editing it. -->\n\n"
        "## Section One\nBody of section one.\n\n"
    )
    index = (outdir / "INDEX.md").read_text()
    assert "| Section One | `01_section_one.md` |" in index
    assert "| Section Two | `02_section_two.md` |" in index


def test_main_check_mode_reports_drift_without_writing(tmp_path, monkeypatch, capsys):
    src = tmp_path / "Strategy.md"
    src.write_text("# T\n\nIntro.\n\n## Sec\nbody\n")
    outdir = tmp_path / "strategy"
    monkeypatch.setattr(ss, "SRC", str(src))
    monkeypatch.setattr(ss, "OUTDIR", str(outdir))

    # Nothing generated yet -> --check must fail (existing == None != content) and not create files.
    rc = ss.main(["--check"])
    assert rc == 1
    assert not outdir.exists() or not any(outdir.iterdir())

    # Now generate for real, then --check must pass clean.
    ss.main([])
    rc = ss.main(["--check"])
    assert rc == 0
    assert "in sync" in capsys.readouterr().out


# ---- slug() edge cases: empty-title fallback + anchored strategy-letter rule -------------------

def test_slug_all_punctuation_title_falls_back_to_section():
    # slug()'s `return s or "section"` guard: an all-punctuation title normalizes to '' -> 'section'
    # (otherwise build() would emit a name like '01_.md').
    assert ss.slug("***") == "section"
    assert ss.slug("###") == "section"


def test_slug_strategy_letter_rule_is_anchored_to_the_title_start():
    # Anchored (^strategy...): a REAL title that starts with the phrase still collapses to
    # 'strategy_<letter>'; a title that merely MENTIONS it mid-line is slugified in full, not
    # truncated. Byte-identical for every current heading (all real ones start with the phrase).
    assert ss.slug("Strategy A: Momentum Breakout") == "strategy_a"
    assert ss.slug("Notes on Strategy A: results") == "notes_on_strategy_a_results"


# ---- split(): the ~~~ fence alternative (only ``` was covered before) -------------------------

def test_split_ignores_hash_headings_inside_a_tilde_fenced_block():
    text = (
        "intro\n\n"
        "## Real Section A\n"
        "body a\n"
        "~~~\n"
        "## looks like a heading but is inside a ~~~ fence\n"
        "~~~\n"
        "more body a\n\n"
        "## Real Section B\n"
        "body b\n"
    )
    _, sections = ss.split(text)
    assert [t for t, _ in sections] == ["Real Section A", "Real Section B"]
    assert "inside a ~~~ fence" in sections[0][1]
    assert "more body a" in sections[0][1]


# ---- main(): orphan handling driven end-to-end via check_or_write_slices ----------------------

def test_main_check_flags_orphan_and_returns_1(tmp_path, monkeypatch, capsys):
    src = tmp_path / "Strategy.md"
    src.write_text("# T\n\nIntro.\n\n## Sec\nbody\n")
    outdir = tmp_path / "strategy"
    monkeypatch.setattr(ss, "SRC", str(src))
    monkeypatch.setattr(ss, "OUTDIR", str(outdir))
    ss.main([])                                              # generate slices
    (outdir / "99_stale.md").write_text("stale leftover from a renamed section")
    assert ss.main(["--check"]) == 1
    assert "ORPHANED slice file(s)" in capsys.readouterr().err


def test_main_non_check_warns_about_orphan_but_returns_0(tmp_path, monkeypatch, capsys):
    src = tmp_path / "Strategy.md"
    src.write_text("# T\n\nIntro.\n\n## Sec\nbody\n")
    outdir = tmp_path / "strategy"
    monkeypatch.setattr(ss, "SRC", str(src))
    monkeypatch.setattr(ss, "OUTDIR", str(outdir))
    ss.main([])
    (outdir / "99_stale.md").write_text("stale leftover")
    assert ss.main([]) == 0
    assert "WARNING: orphaned slice file(s)" in capsys.readouterr().out


# ---- build(): '[CANDIDATE]' sections generate no slice and consume no number ---------------------
# Regression lock for the SL5 2026-08-25 diligence-sweep fix. SL5 branch (1) SHADOW-register must
# add a '## Strategy <code> [CANDIDATE]' section to Strategy.md AND must not run the repo-view
# fanout. Before the fix those two instructions contradicted each other: the bare heading made every
# on-disk slice stale and orphaned the tail, so `split_strategy.py --check` -- a blocking ci.yml step
# -- failed on the arsenal's first-ever SHADOW registration, on a branch the ended session could
# never repair (auto-merge is fail-closed and retries a tip SHA exactly once). check_roster_
# consistency.py's headings_in() has always excluded '[CANDIDATE]'; this generator had not.

def _candidate_fixture(candidate_block: str) -> str:
    return (
        "# Title\n\nPreamble.\n\n"
        "## Alpha Section\n"
        "content alpha\n\n"
        + candidate_block +
        "## Omega Section\n"
        "content omega\n"
    )


def _build_from(tmp_path, monkeypatch, text):
    src = tmp_path / "Strategy.md"
    src.write_text(text)
    monkeypatch.setattr(ss, "SRC", str(src))
    monkeypatch.setattr(ss, "OUTDIR", str(tmp_path / "strategy"))
    return ss.build()


def test_build_candidate_section_generates_no_slice_and_shifts_no_number(tmp_path, monkeypatch):
    """A CANDIDATE section is a byte-for-byte no-op on the generated tree."""
    without = _build_from(tmp_path, monkeypatch, _candidate_fixture(""))
    with_cand = _build_from(
        tmp_path, monkeypatch,
        _candidate_fixture("## Strategy F [CANDIDATE]: Overnight gap fade\ncandidate body\n\n"),
    )
    # No slice for the candidate...
    assert not any("strategy_f" in name for name in with_cand)
    # ...and the tail keeps its numbering, so no existing slice goes stale.
    assert set(with_cand) == set(without) == {
        "00_preamble.md", "01_alpha_section.md", "02_omega_section.md", "INDEX.md"}
    assert with_cand == without, "a CANDIDATE section must not change any generated file"


def test_build_candidate_section_is_excluded_from_index(tmp_path, monkeypatch):
    files = _build_from(
        tmp_path, monkeypatch,
        _candidate_fixture("## Strategy F [CANDIDATE]: Overnight gap fade\ncandidate body\n\n"),
    )
    assert "CANDIDATE" not in files["INDEX.md"]
    assert "candidate body" not in "".join(files.values())


def test_build_candidate_marker_is_case_insensitive(tmp_path, monkeypatch):
    """headings_in() compares on .upper(); this filter must agree, or the pair drifts again."""
    files = _build_from(
        tmp_path, monkeypatch,
        _candidate_fixture("## Strategy F [candidate]: Overnight gap fade\ncandidate body\n\n"),
    )
    assert set(files) == {"00_preamble.md", "01_alpha_section.md", "02_omega_section.md", "INDEX.md"}


def test_build_promoted_candidate_does_generate_a_slice(tmp_path, monkeypatch):
    """Branch (2) PROBE-register renames the heading first; THEN the slice appears."""
    files = _build_from(
        tmp_path, monkeypatch,
        _candidate_fixture("## Strategy F: Overnight gap fade\npromoted body\n\n"),
    )
    assert "02_strategy_f.md" in files
    assert "promoted body" in files["02_strategy_f.md"]
