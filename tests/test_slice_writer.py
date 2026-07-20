from scripts.lib.slice_writer import check_or_write_slices, find_orphaned_markdown_files, slugify


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
