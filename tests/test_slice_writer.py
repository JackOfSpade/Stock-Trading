from lib.slice_writer import (
    check_or_write_slices,
    dedupe_slice_name,
    find_orphaned_markdown_files,
    run_split_cli,
    slugify,
)


def test_slugify_collapses_non_alnum_and_uses_section_fallback():
    assert slugify("  Position Sizing & Risk!  ") == "position_sizing_risk"
    assert slugify("***") == "section"


def test_find_orphaned_markdown_files_ignores_expected_and_hand_maintained(tmp_path):
    (tmp_path / "current.md").write_text("generated", encoding="utf-8")
    (tmp_path / "README.md").write_text("manual", encoding="utf-8")
    (tmp_path / "stale.md").write_text("old", encoding="utf-8")
    (tmp_path / "notes.txt").write_text("not markdown", encoding="utf-8")

    assert find_orphaned_markdown_files(
        str(tmp_path),
        {"current.md": "generated"},
        {"README.md"},
    ) == ["stale.md"]


def test_find_orphaned_markdown_files_empty_when_outdir_does_not_exist(tmp_path):
    # check_or_write_slices always os.makedirs(outdir) before computing orphans, so this branch
    # (outdir never created at all) is only reachable by calling find_orphaned_markdown_files
    # directly, never via the main()/--check path -- cover it here explicitly.
    assert find_orphaned_markdown_files(
        str(tmp_path / "does_not_exist"),
        {"00_preamble.md": "..."},
        set(),
    ) == []


def test_check_or_write_slices_writes_then_passes_check(tmp_path, capsys):
    files = {"a.md": "A\n", "b.md": "B\n"}

    rc = check_or_write_slices(
        files,
        outdir=str(tmp_path),
        check=False,
        hand_maintained=set(),
        stale_message="STALE: ",
        orphan_message="ORPHAN: ",
        orphan_warning="WARN: ",
        ok_message="OK",
        wrote_message="WROTE",
    )

    assert rc == 0
    assert (tmp_path / "a.md").read_text(encoding="utf-8") == "A\n"
    assert capsys.readouterr().out == "WROTE\n"

    rc = check_or_write_slices(
        files,
        outdir=str(tmp_path),
        check=True,
        hand_maintained=set(),
        stale_message="STALE: ",
        orphan_message="ORPHAN: ",
        orphan_warning="WARN: ",
        ok_message="OK",
        wrote_message="WROTE",
    )

    assert rc == 0
    assert capsys.readouterr().out == "OK\n"


def test_check_or_write_slices_reports_stale_and_orphan_without_writing(tmp_path, capsys):
    (tmp_path / "a.md").write_text("old\n", encoding="utf-8")
    (tmp_path / "orphan.md").write_text("old\n", encoding="utf-8")

    rc = check_or_write_slices(
        {"a.md": "new\n"},
        outdir=str(tmp_path),
        check=True,
        hand_maintained=set(),
        stale_message="STALE: ",
        orphan_message="ORPHAN: ",
        orphan_warning="WARN: ",
        ok_message="OK",
        wrote_message="WROTE",
    )

    assert rc == 1
    assert (tmp_path / "a.md").read_text(encoding="utf-8") == "old\n"
    err = capsys.readouterr().err
    assert "STALE: a.md" in err
    assert "ORPHAN: orphan.md" in err


def test_check_or_write_slices_preserves_crlf_content_through_write_and_check(tmp_path, capsys):
    # BUG FIX (tooling-misc#2, code-quality pass 2026-08-31): the write branch and the check-read
    # branch used to open() with default universal-newline translation, so a CRLF `content` string
    # would be silently rewritten to LF on write, and a --check re-read of that same file would then
    # (wrongly) agree with the CRLF `content` it no longer matched byte-for-byte -- both sides of the
    # comparison went through the identical lossy read, so the drift was invisible either way.
    # newline="" on both opens closes that; this pins the round trip at the check_or_write_slices()
    # level directly (split_task_plan.py/split_strategy.py pin it again end-to-end).
    files = {"a.md": "line one\r\nline two\r\n"}
    kwargs = {
        "outdir": str(tmp_path),
        "hand_maintained": set(),
        "stale_message": "STALE: ",
        "orphan_message": "ORPHAN: ",
        "orphan_warning": "WARN: ",
        "ok_message": "OK",
        "wrote_message": "WROTE",
    }

    assert check_or_write_slices(files, check=False, **kwargs) == 0
    assert (tmp_path / "a.md").read_bytes() == b"line one\r\nline two\r\n"
    capsys.readouterr()   # discard the write-mode "WROTE" output

    assert check_or_write_slices(files, check=True, **kwargs) == 0
    assert capsys.readouterr().out == "OK\n"


# ---- dedupe_slice_name ---------------------------------------------------------------------------

def test_dedupe_slice_name_passes_through_an_unused_name():
    used = set()
    assert dedupe_slice_name("D1.md", used) == "D1.md"
    assert used == {"D1.md"}


def test_dedupe_slice_name_appends_underscore_before_extension_on_collision():
    # split_task_plan.py's/split_strategy.py's shared collision-guard idiom: a trailing underscore
    # before the extension, not a "_2"-style counter -- pinned here so the shared helper can't drift
    # from what both callers' own tests (test_build_duplicate_id_collision_gets_underscore_suffixed_
    # slice, test_build_collision_suffix_loop_is_never_triggered_by_the_index_prefix) expect.
    used = {"D1.md"}
    assert dedupe_slice_name("D1.md", used) == "D1_.md"
    assert used == {"D1.md", "D1_.md"}


def test_dedupe_slice_name_handles_a_triple_collision():
    used = {"D1.md", "D1_.md"}
    assert dedupe_slice_name("D1.md", used) == "D1__.md"
    assert used == {"D1.md", "D1_.md", "D1__.md"}


# ---- run_split_cli --------------------------------------------------------------------------------

def test_run_split_cli_derives_all_five_messages_from_caller_identity(tmp_path, capsys):
    # tooling-misc#0: split_task_plan.py's and split_strategy.py's main()s used to hand-write these
    # five strings identically except for a handful of substitutions. Pin that run_split_cli derives
    # the same wording from (script_name, source_name, outdir_label, unit_noun) alone.
    outdir = tmp_path / "task_plan"
    rc = run_split_cli(
        [],
        lambda: {"a.md": "content\n"},
        outdir=str(outdir),
        outdir_label="task_plan/",
        source_name="Claude_Task_Plan.md",
        script_name="split_task_plan.py",
        unit_noun="routine",
        hand_maintained=set(),
    )
    assert rc == 0
    assert (outdir / "a.md").read_text(encoding="utf-8") == "content\n"
    assert "Wrote 1 files to task_plan/" in capsys.readouterr().out

    # Now go stale (build_fn changes) and confirm --check names this script/source/routine wording.
    rc = run_split_cli(
        ["--check"],
        lambda: {"a.md": "different\n"},
        outdir=str(outdir),
        outdir_label="task_plan/",
        source_name="Claude_Task_Plan.md",
        script_name="split_task_plan.py",
        unit_noun="routine",
        hand_maintained=set(),
    )
    assert rc == 1
    err = capsys.readouterr().err
    assert "STALE slices (run scripts/split_task_plan.py): a.md" in err


def test_run_split_cli_check_mode_ok_message_names_outdir_and_source(tmp_path, capsys):
    outdir = tmp_path / "strategy"
    build_fn = lambda: {"a.md": "content\n"}  # noqa: E731 -- tiny fixed fixture, a def buys nothing here
    assert run_split_cli(
        [], build_fn, outdir=str(outdir), outdir_label="strategy/", source_name="Strategy.md",
        script_name="split_strategy.py", unit_noun="section", hand_maintained=set(),
    ) == 0
    capsys.readouterr()   # discard the write-mode output

    assert run_split_cli(
        ["--check"], build_fn, outdir=str(outdir), outdir_label="strategy/", source_name="Strategy.md",
        script_name="split_strategy.py", unit_noun="section", hand_maintained=set(),
    ) == 0
    assert "strategy/ slices are in sync with Strategy.md" in capsys.readouterr().out


def test_run_split_cli_orphan_message_names_the_unit_noun(tmp_path, capsys):
    outdir = tmp_path / "strategy"
    outdir.mkdir()
    (outdir / "ghost.md").write_text("stale", encoding="utf-8")
    rc = run_split_cli(
        ["--check"],
        lambda: {"a.md": "content\n"},
        outdir=str(outdir),
        outdir_label="strategy/",
        source_name="Strategy.md",
        script_name="split_strategy.py",
        unit_noun="section",
        hand_maintained=set(),
    )
    assert rc == 1
    err = capsys.readouterr().err
    assert "no longer produced by any current Strategy.md heading (a section was likely" in err
