"""Guard scripts/split_task_plan.py's Claude_Task_Plan.md -> task_plan/*.md slicing (DEF-2).

split_task_plan.py had NO dedicated unit test — its only CI guard was `python scripts/split_task_plan.py
--check` against the real plan, which never exercises the edge cases the live plan doesn't happen to
hit: the duplicate-id slice-name collision loop (which, unlike split_strategy's index-prefixed dead
twin, is LIVE here because slice names are `{rid}.md`), group_intro accumulation across cadence groups,
fence-guarded heading detection, the no-preceding-group-header guard, and the orphan/drift paths through
main(). These tests run entirely against tmp_path fixtures (never the real Claude_Task_Plan.md /
task_plan/), so nothing here can touch or drift the real committed slices.
"""
import pytest

from conftest import load_module_from_path

DR = "— regular routine"   # the em-dash + type tag ROUTINE_SUFFIX matches ("— regular routine")

stp = load_module_from_path("split_task_plan", "scripts", "split_task_plan.py")


# ---- slug() (fallback id maker when heading_to_id returns None) --------------------------------

def test_slug_basic_and_collapsing():
    assert stp.slug("D1. Foo Bar") == "d1_foo_bar"
    assert stp.slug("  Weird!!  Title  ") == "weird_title"


def test_slug_all_punctuation_falls_back_to_section():
    assert stp.slug("***") == "section"
    assert stp.slug("") == "section"


# ---- split(): preamble / group_intro / body across cadence groups -----------------------------

def _two_group_plan():
    return (
        "# Claude Task Plan\n"
        "\n"
        "ROUTINE INVENTORY + OPERATING MODEL preamble.\n"
        "\n"
        "# DAILY\n"
        "daily group intro line\n"
        f"## D1. First daily {DR}\n"
        "d1 body\n"
        f"## D2. Second daily {DR}\n"
        "d2 body\n"
        "\n"
        "# WEEKLY\n"
        "weekly group intro line\n"
        f"## W1. First weekly {DR}\n"
        "w1 body\n"
    )


def test_split_preamble_stops_at_first_cadence_group():
    preamble, routines = stp.split(_two_group_plan())
    assert preamble == "# Claude Task Plan\n\nROUTINE INVENTORY + OPERATING MODEL preamble.\n\n"
    assert [r[0] for r in routines] == ["D1", "D2", "W1"]


def test_split_group_intro_is_carried_per_group():
    _, routines = stp.split(_two_group_plan())
    by_id = {r[0]: r for r in routines}
    # D1 and D2 share the DAILY group intro; W1 gets the WEEKLY one.
    assert by_id["D1"][2] == "# DAILY\ndaily group intro line\n"
    assert by_id["D2"][2] == "# DAILY\ndaily group intro line\n"
    assert by_id["W1"][2] == "# WEEKLY\nweekly group intro line\n"
    # Bodies start at the routine heading and stop before the next routine/group.
    assert by_id["D1"][3] == f"## D1. First daily {DR}\nd1 body\n"
    assert by_id["W1"][3] == f"## W1. First weekly {DR}\nw1 body\n"


def test_split_no_routines_returns_whole_text_as_preamble():
    text = "# Just a title\n\nNo routines here.\n"
    preamble, routines = stp.split(text)
    assert preamble == text
    assert routines == []


def test_split_ignores_headings_inside_a_fenced_code_block():
    # A column-0 '## '/'# ' inside a ``` fence is body text, not a routine/group boundary. Without
    # fence tracking the fenced '## D2. Fake' would split the code block off into its own slice.
    text = (
        "# DAILY\n"
        f"## D1. Real {DR}\n"
        "body before fence\n"
        "```text\n"
        f"## D2. Fake inside fence {DR}\n"
        "# DAILY fake group\n"
        "```\n"
        "body after fence\n"
        f"## D2. Real second {DR}\n"
        "real d2 body\n"
    )
    _, routines = stp.split(text)
    assert [r[0] for r in routines] == ["D1", "D2"]
    d1_body = routines[0][3]
    assert "## D2. Fake inside fence" in d1_body   # the fenced heading stayed inside D1's body
    assert "body after fence" in d1_body


def test_split_falls_back_to_slug_when_heading_id_is_none():
    # A routine heading with no "X. " prefix and no Attacker/Orchestrator keyword -> heading_to_id
    # returns None -> the id is slug(title).
    text = f"# DAILY\n## Freeform housekeeping section {DR}\nbody\n"
    _, routines = stp.split(text)
    assert routines[0][0] == "freeform_housekeeping_section_regular_routine"


def test_split_raises_clear_error_when_routine_precedes_every_group_header():
    # Regression guard for the 2026-07-17 fix: previously `max(<empty>)` raised an opaque
    # "max() arg is an empty sequence"; now it's an actionable message.
    text = f"some preamble with no group header\n## D1. Orphan routine {DR}\nbody\n"
    with pytest.raises(ValueError, match="cadence-group header"):
        stp.split(text)


# ---- build(): duplicate-id collision loop (LIVE here, unlike split_strategy) -------------------

def test_build_duplicate_id_collision_gets_underscore_suffixed_slice(tmp_path, monkeypatch):
    # Two headings both mapping (via heading_to_id's "Attacker" branch) to rid 'AR_att'. Slice names
    # are `{rid}.md` with no index prefix, so the second must be disambiguated to 'AR_att_.md' rather
    # than clobbering the first.
    src = tmp_path / "Claude_Task_Plan.md"
    src.write_text(
        "# Title\n\npreamble\n\n"
        "# ADVERSARIAL\n"
        f"## Red-team Attacker sweep {DR}\n"
        "body a\n"
        f"## Blue Attacker probe {DR}\n"
        "body b\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(stp, "SRC", str(src))
    files = stp.build()
    assert "AR_att.md" in files and "AR_att_.md" in files
    assert "body a" in files["AR_att.md"]
    assert "body b" in files["AR_att_.md"]


# ---- main(): end-to-end write / --check / orphan handling -------------------------------------

def _write_plan(tmp_path):
    src = tmp_path / "Claude_Task_Plan.md"
    src.write_text(_two_group_plan(), encoding="utf-8")
    return src


def test_main_writes_expected_slices_with_header_and_index(tmp_path, monkeypatch, capsys):
    src = _write_plan(tmp_path)
    outdir = tmp_path / "task_plan"
    monkeypatch.setattr(stp, "SRC", str(src))
    monkeypatch.setattr(stp, "OUTDIR", str(outdir))

    rc = stp.main([])
    assert rc == 0
    names = sorted(p.name for p in outdir.iterdir())
    assert names == ["00_preamble.md", "D1.md", "D2.md", "INDEX.md", "W1.md"]

    preamble = (outdir / "00_preamble.md").read_text(encoding="utf-8")
    assert preamble.startswith(stp.HEADER)
    assert "ROUTINE INVENTORY + OPERATING MODEL preamble." in preamble

    d1 = (outdir / "D1.md").read_text(encoding="utf-8")
    assert d1.startswith(stp.HEADER)
    assert "# DAILY" in d1 and "## D1. First daily" in d1     # preamble + group intro + own section
    assert "## D2. Second daily" not in d1                    # not a sibling's section

    index = (outdir / "INDEX.md").read_text(encoding="utf-8")
    assert "| D1 |" in index and "`D1.md`" in index
    assert "Wrote 5 files to task_plan/" in capsys.readouterr().out


def test_main_check_mode_reports_drift_then_passes_clean(tmp_path, monkeypatch, capsys):
    src = _write_plan(tmp_path)
    outdir = tmp_path / "task_plan"
    monkeypatch.setattr(stp, "SRC", str(src))
    monkeypatch.setattr(stp, "OUTDIR", str(outdir))

    # Nothing generated yet -> --check must fail (existing None != content) and write nothing.
    assert stp.main(["--check"]) == 1
    assert not outdir.exists() or not any(outdir.iterdir())
    assert "STALE slices" in capsys.readouterr().err

    stp.main([])                     # generate for real
    assert stp.main(["--check"]) == 0
    assert "in sync with Claude_Task_Plan.md" in capsys.readouterr().out


def test_main_check_flags_orphan_and_returns_1(tmp_path, monkeypatch, capsys):
    src = _write_plan(tmp_path)
    outdir = tmp_path / "task_plan"
    monkeypatch.setattr(stp, "SRC", str(src))
    monkeypatch.setattr(stp, "OUTDIR", str(outdir))

    stp.main([])                                              # generate slices
    (outdir / "ZZ_ghost.md").write_text("stale leftover", encoding="utf-8")   # orphan
    assert stp.main(["--check"]) == 1
    assert "ORPHANED slice file(s)" in capsys.readouterr().err


def test_main_non_check_warns_about_orphan_but_still_returns_0(tmp_path, monkeypatch, capsys):
    src = _write_plan(tmp_path)
    outdir = tmp_path / "task_plan"
    monkeypatch.setattr(stp, "SRC", str(src))
    monkeypatch.setattr(stp, "OUTDIR", str(outdir))

    stp.main([])
    (outdir / "ZZ_ghost.md").write_text("stale leftover", encoding="utf-8")
    assert stp.main([]) == 0
    assert "WARNING: orphaned slice file(s)" in capsys.readouterr().out


# ---- CRLF round-trip (tooling-misc#2) -----------------------------------------------------------

def test_crlf_source_round_trips_unchanged_through_split_and_check(tmp_path, monkeypatch):
    # BUG FIX (tooling-misc#2, code-quality pass 2026-08-31): read_text() silently normalized a CRLF
    # source to LF before split() ever saw it, so a CRLF Claude_Task_Plan.md would generate an LF
    # slice while --check still reported clean (both sides of that comparison ran through the same
    # lossy read) -- contradicting this script's own "--check proves ... byte-identical" claim. Build
    # a plan with real \r\n line endings on disk (write_bytes, not write_text, so nothing translates
    # them away before the script even runs) and confirm the CRLFs survive both write and --check.
    src = tmp_path / "Claude_Task_Plan.md"
    src.write_bytes(_two_group_plan().replace("\n", "\r\n").encode("utf-8"))
    outdir = tmp_path / "task_plan"
    monkeypatch.setattr(stp, "SRC", str(src))
    monkeypatch.setattr(stp, "OUTDIR", str(outdir))

    assert stp.main([]) == 0
    d1 = (outdir / "D1.md").read_bytes()
    assert b"\r\n" in d1
    assert b"## D1. First daily" in d1
    assert b"\r\r\n" not in d1   # no accidental double-CR from a translate-then-rewrite round trip

    # The generative claim under test: --check on the CRLF source against the CRLF slices it just
    # wrote is clean, not merely non-crashing.
    assert stp.main(["--check"]) == 0
