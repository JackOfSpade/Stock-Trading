"""Guard scripts/split_strategy.py's Strategy.md -> strategy/*.md slicing (P3-1).

split_strategy.py is the one script in scripts/ that had NO dedicated test file before this one
(its only guard was `python scripts/split_strategy.py --check` in CI against the real, current
Strategy.md — which never exercises edge cases the live file doesn't happen to hit). These tests
run entirely against tmp_path fixtures (never the real Strategy.md / strategy/ directory), so
nothing here can touch or drift the real committed slices.
"""
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "split_strategy.py")
    spec = importlib.util.spec_from_file_location("split_strategy", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


ss = _load()


# ---- slug() ------------------------------------------------------------------------------------

def test_slug_plain_heading():
    assert ss.slug("Entry Rules") == "entry_rules"
    # non-alnum runs (incl. leading/trailing whitespace and punctuation) collapse to single "_"
    assert ss.slug("  Position Sizing & Risk!  ") == "position_sizing_risk"


def test_slug_strategy_letter_heading_drops_everything_after_the_letter():
    # The "Strategy C: ..." rewrite rule (slug()'s first re.sub) fires for letters a-e and discards
    # everything after "Strategy <letter>:", regardless of how long/varied the rest of the title is.
    assert ss.slug("Strategy C: Momentum Breakout (High Vol)") == "strategy_c"
    assert ss.slug("Strategy A: X") == "strategy_a"
    # Outside the [a-e] class the special rule does not match -> falls through to generic slugify.
    assert ss.slug("Strategy F: Something") == "strategy_f_something"


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
    preamble, sections = ss.split(text)
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


# ---- find_orphans() -------------------------------------------------------------------------------

def test_find_orphans_flags_stale_file_not_in_build_output_or_hand_maintained(tmp_path, monkeypatch):
    outdir = tmp_path / "strategy"
    outdir.mkdir()
    (outdir / "03_removed_section.md").write_text("stale leftover from a renamed/removed section")
    (outdir / "README.md").write_text("hand-maintained, never generated")
    monkeypatch.setattr(ss, "OUTDIR", str(outdir))

    current_files = {"00_preamble.md": "...", "01_kept_section.md": "...", "INDEX.md": "..."}
    orphans = ss.find_orphans(current_files)

    assert orphans == ["03_removed_section.md"]


def test_find_orphans_empty_when_outdir_does_not_exist(tmp_path, monkeypatch):
    monkeypatch.setattr(ss, "OUTDIR", str(tmp_path / "does_not_exist"))
    assert ss.find_orphans({"00_preamble.md": "..."}) == []


def test_find_orphans_empty_when_everything_current_or_hand_maintained(tmp_path, monkeypatch):
    outdir = tmp_path / "strategy"
    outdir.mkdir()
    (outdir / "00_preamble.md").write_text("...")
    (outdir / "README.md").write_text("hand-maintained")
    monkeypatch.setattr(ss, "OUTDIR", str(outdir))
    assert ss.find_orphans({"00_preamble.md": "..."}) == []


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


# ---- main(): orphan handling driven end-to-end (find_orphans was only unit-tested in isolation) --

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
