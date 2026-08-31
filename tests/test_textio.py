"""Guard scripts/lib/textio.py's read_text/read_bytes/load_yaml — the shared repo-file-read helper
(codebase audit 2026-07-29). Two things pin here that a casual reimplementation could get wrong:

1. read_bytes must return the EXACT on-disk bytes, not a decode/re-encode of them. It feeds
   check_roster_consistency.py's compute_spec_hash (a sha256 over the raw file), so a text-mode
   detour (which applies universal-newline translation on read) would silently change the hash
   without changing the file on disk.
2. load_yaml's "missing file" and "empty document" cases must both collapse to {} (the `or {}` every
   call site used to hand-roll and sometimes forgot — textio.py docstring, point 3), and the file
   handle must not leak (point 1: a bare `open()` with no `with` leaves closing to refcounting GC).
"""
import gc
import warnings

import pytest

from lib.textio import load_yaml, read_bytes, read_text, read_text_preserving_newlines


def test_read_text_and_read_bytes_agree_on_a_utf8_file_with_non_ascii_content(tmp_path):
    text = "spec_hash café — 日本語 \U0001F600\n"
    p = tmp_path / "unicode.md"
    p.write_text(text, encoding="utf-8")
    assert read_text(str(p)) == text
    assert read_bytes(str(p)) == text.encode("utf-8")


def test_read_bytes_preserves_exact_bytes_not_a_decode_reencode(tmp_path):
    # Text mode's default universal-newline translation (newline=None) collapses \r\n -> \n on
    # read. If read_bytes were ever implemented as read_text(...).encode("utf-8"), this CRLF file
    # would come back with \n instead of \r\n -- same content, different bytes, different sha256.
    # This is the exact failure mode read_bytes exists to avoid (see module docstring, point 1).
    raw = "line one\r\nline two\r\n".encode("utf-8")
    p = tmp_path / "crlf.md"
    p.write_bytes(raw)
    assert read_bytes(str(p)) == raw


def test_read_text_preserving_newlines_does_not_collapse_crlf(tmp_path):
    # Same failure mode test_read_bytes_preserves_exact_bytes_not_a_decode_reencode guards against
    # (module docstring, point 1) but for the decoded-text sibling: if this were ever implemented as
    # `read_text(path)` (or a bare `open(...).read()`), the \r\n here would silently collapse to \n on
    # read (tooling-misc#2, code-quality pass 2026-08-31 — the exact bug class already fixed once in
    # scripts/adversarial_review_storage.py::parse_legacy_review, which this function mirrors).
    raw = "line one\r\nline two\r\n".encode("utf-8")
    p = tmp_path / "crlf.md"
    p.write_bytes(raw)
    assert read_text_preserving_newlines(str(p)) == "line one\r\nline two\r\n"


def test_read_text_preserving_newlines_agrees_with_read_text_on_lf_only_content(tmp_path):
    # For content with no \r bytes at all, the two readers must return identical strings -- this
    # isn't a special-purpose "CRLF mode", it's the same text minus read_text()'s universal-newline
    # translation step, which is a no-op when there is nothing for it to translate.
    text = "spec_hash café — 日本語 \U0001F600\n"
    p = tmp_path / "unicode.md"
    p.write_text(text, encoding="utf-8")
    assert read_text_preserving_newlines(str(p)) == read_text(str(p)) == text


def test_read_text_preserving_newlines_raises_for_a_missing_file(tmp_path):
    with pytest.raises(FileNotFoundError):
        read_text_preserving_newlines(str(tmp_path / "nope.md"))


def test_read_text_raises_for_a_missing_file(tmp_path):
    # No missing-file guard here (unlike load_yaml) -- read_text is the raw read primitive; a
    # caller that needs "absent behaves like empty" uses load_yaml or its own os.path.exists() test.
    with pytest.raises(FileNotFoundError):
        read_text(str(tmp_path / "nope.md"))


def test_read_bytes_raises_for_a_missing_file(tmp_path):
    with pytest.raises(FileNotFoundError):
        read_bytes(str(tmp_path / "nope.md"))


def test_read_text_does_not_leave_a_file_handle_open(tmp_path):
    # A bare `open(path).read()` (no `with`) leaves the handle to CPython's refcounting GC, which
    # surfaces as a ResourceWarning on finalization -- verified empirically: the warning fires
    # inside __del__ (printed as "Exception ignored", not raised), so it must be caught via
    # warnings.catch_warnings(record=True), not pytest.raises. Force finalization with gc.collect()
    # and assert none was recorded for the `with`-scoped read.
    p = tmp_path / "x.md"
    p.write_text("hello\n", encoding="utf-8")
    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        read_text(str(p))
        gc.collect()
    assert not [w for w in caught if issubclass(w.category, ResourceWarning)]


def test_load_yaml_does_not_leave_a_file_handle_open(tmp_path):
    p = tmp_path / "cfg.yaml"
    p.write_text("a: 1\n", encoding="utf-8")
    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        load_yaml(str(p))
        gc.collect()
    assert not [w for w in caught if issubclass(w.category, ResourceWarning)]


def test_load_yaml_parses_a_normal_mapping(tmp_path):
    p = tmp_path / "cfg.yaml"
    p.write_text("a: 1\nb:\n  - x\n  - y\n", encoding="utf-8")
    assert load_yaml(str(p)) == {"a": 1, "b": ["x", "y"]}


def test_load_yaml_missing_path_returns_empty_dict(tmp_path):
    assert load_yaml(str(tmp_path / "does_not_exist.yaml")) == {}


def test_load_yaml_empty_file_returns_empty_dict(tmp_path):
    # yaml.safe_load returns None for an empty document -- every pre-textio call site relied on a
    # hand-rolled `or {}` to turn that into a usable mapping (textio.py docstring, point 3).
    p = tmp_path / "empty.yaml"
    p.write_text("", encoding="utf-8")
    assert load_yaml(str(p)) == {}


def test_load_yaml_comments_only_file_returns_empty_dict(tmp_path):
    # Same None-from-yaml.safe_load case as an empty file, via a different route (an all-comments
    # document parses to None too, not to {}).
    p = tmp_path / "comments.yaml"
    p.write_text("# nothing but comments\n# still nothing\n", encoding="utf-8")
    assert load_yaml(str(p)) == {}


def test_load_yaml_missing_sentinel_is_returned_verbatim_for_an_absent_file(tmp_path):
    sentinel = object()
    assert load_yaml(str(tmp_path / "gone.yaml"), missing=sentinel) is sentinel


def test_load_yaml_explicit_missing_none_matches_the_default(tmp_path):
    # missing=None (the default) and an explicit missing=None must behave identically -- both mean
    # "no sentinel supplied, use a fresh {}" per the docstring, not "sentinel value is None".
    absent = str(tmp_path / "gone.yaml")
    assert load_yaml(absent) == load_yaml(absent, missing=None) == {}


def test_load_yaml_missing_default_returns_independent_dicts_not_a_shared_mutable(tmp_path):
    # `{} if missing is None else missing` builds a fresh literal per call, not a mutable default
    # argument -- guards against a future edit that hoists it into `def load_yaml(path, missing={})`,
    # which would let one caller's mutation of its "absent" result leak into every other caller's.
    a = load_yaml(str(tmp_path / "gone1.yaml"))
    b = load_yaml(str(tmp_path / "gone2.yaml"))
    a["x"] = 1
    assert b == {}
