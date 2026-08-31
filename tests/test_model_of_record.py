"""Direct unit tests for scripts/lib/model_of_record.py -- the check-N (MODEL OF RECORD) block
extracted out of scripts/check_cadence_consistency.py (2026-08-31 code-quality pass, cadence#2).

tests/test_cadence_consistency.py already carries ~39 end-to-end tests of this logic, reached through
check_cadence_consistency.py's cc.check_model_of_record()/cc.model_mirror_files() wrappers (fixture
paths installed via monkeypatch.setattr(cc, "CADENCE", ...) etc.) -- those are UNCHANGED by this
extraction (see that wrapper's own docstring) and are NOT duplicated here. What the extraction
unlocks, and what this file adds, is testing scripts/lib/model_of_record.py's functions directly --
explicit parameters, no cc module, no monkeypatch machinery at all -- which is the whole point of
pulling this block into its own parameterized module.
"""
import os

from lib.model_of_record import (
    MODEL_ID_CORE,
    MODEL_ID_RE,
    MODEL_ID_VALID,
    MODEL_EXEMPT,
    NOT_A_MODEL_PREFIXES,
    URL_RE,
    _is_subtracted_non_assertion,
    _tooling_prefix_hides_version,
    check_model_of_record,
    model_mirror_files,
)


# ---- model_mirror_files(): parameterized, no module globals to reach for ----
def test_model_mirror_files_returns_paths_in_order():
    assert model_mirror_files("C", "O", "P", "S") == ["C", "O", "P", "S"]


def test_model_mirror_files_has_no_hidden_state_between_calls():
    # This is exactly the property the 2026-08-31 extraction's parameterization exists to guarantee --
    # a module-level list built from hardcoded globals could never do this (see the module's own
    # docstring on the fixture cross-contamination bug that motivated call-time resolution).
    assert model_mirror_files("a", "b", "c", "d") == ["a", "b", "c", "d"]
    assert model_mirror_files("w", "x", "y", "z") == ["w", "x", "y", "z"]


# ---- MODEL_ID_CORE / MODEL_ID_RE / MODEL_ID_VALID ----
def test_model_id_re_and_valid_share_the_same_core_pattern():
    assert MODEL_ID_VALID.pattern == MODEL_ID_CORE
    assert MODEL_ID_RE.pattern == MODEL_ID_CORE + r"\b"


def test_model_id_valid_accepts_well_formed_ids():
    for model_id in ("claude-opus-5", "claude-sonnet-4-5", "claude-3-5-sonnet-20241022"):
        assert MODEL_ID_VALID.fullmatch(model_id), model_id


def test_model_id_valid_rejects_missing_claude_prefix():
    assert not MODEL_ID_VALID.fullmatch("opus-5")


def test_model_id_re_finds_embedded_id_without_leading_boundary():
    # 2026-07-28 fix: the leading \b was dropped so a dropped-space typo ("nowclaude-sonnet-5") still
    # surfaces the id -- see the module's own DEFECT C comment above MODEL_ID_CORE.
    assert MODEL_ID_RE.findall("Fleet nowclaude-sonnet-5 is the model.") == ["claude-sonnet-5"]


def test_model_id_re_trailing_boundary_stops_before_a_trailing_hyphen():
    assert MODEL_ID_RE.findall("claude-opus-5-") == ["claude-opus-5"]


# ---- NOT_A_MODEL_PREFIXES / _tooling_prefix_hides_version ----
def test_tooling_prefix_hides_version_false_for_ordinary_tooling_extension():
    assert not _tooling_prefix_hides_version("claude-code-action", "claude-code")
    assert not _tooling_prefix_hides_version("claude-codebase", "claude-code")


def test_tooling_prefix_hides_version_true_for_separator_prefixed_digit():
    assert _tooling_prefix_hides_version("claude-code-5", "claude-code")


def test_tooling_prefix_hides_version_true_for_glued_digit():
    assert _tooling_prefix_hides_version("claude-code5", "claude-code")


def test_tooling_prefix_hides_version_true_for_letter_then_version_suffix():
    # DEFECT B, THIRD CASE (quality pass 2026-08-22): 'claude-codex-5' continues with a letter ('x')
    # before the version, so a check that only inspects the first character after the prefix misses it.
    assert _tooling_prefix_hides_version("claude-codex-5", "claude-code")


# ---- _is_subtracted_non_assertion ----
def test_is_subtracted_non_assertion_true_for_the_bare_tooling_names():
    for token in NOT_A_MODEL_PREFIXES:
        assert _is_subtracted_non_assertion(token), token


def test_is_subtracted_non_assertion_false_for_version_shaped_tooling_lookalikes():
    assert not _is_subtracted_non_assertion("claude-code-5")
    assert not _is_subtracted_non_assertion("claude-codex-5")


def test_is_subtracted_non_assertion_false_for_an_unrelated_model_id():
    assert not _is_subtracted_non_assertion("claude-opus-5")


# ---- URL_RE ----
def test_url_re_strips_a_bare_url():
    stripped = URL_RE.sub(" ", "See https://example.com/x for details")
    assert "example.com" not in stripped
    assert stripped.startswith("See") and stripped.rstrip().endswith("details")


def test_url_re_stops_at_markdown_link_close_paren():
    # 2026-07-28 fix: a model id sitting right after a markdown link's closing ')' with no space must
    # survive the strip -- the old greedy r"https?://\S+" ate it along with the URL.
    text = "[text](https://example.com/x)claude-sonnet-4 remains configured"
    assert "claude-sonnet-4" in URL_RE.sub(" ", text)


# ---- MODEL_EXEMPT ----
def test_model_exempt_matches_the_bare_marker():
    assert MODEL_EXEMPT.search("claude-sonnet-4 (model-id-exempt) historical mention")


def test_model_exempt_does_not_match_a_longer_hyphenated_token():
    # Round 2 fix (2026-07-28): a filename/config-key that merely STARTS WITH the marker must not
    # suppress a real drift on the same line.
    assert not MODEL_EXEMPT.search("see model-id-exempt-list.md for the policy")


def test_model_exempt_does_not_match_as_an_infix_of_another_word():
    assert not MODEL_EXEMPT.search("that citation is model-id-exemption-only, not a live assertion.")


# ---- check_model_of_record(): direct calls, explicit params, no cc module / no monkeypatch ----
def test_check_model_of_record_clean_when_all_mirrors_agree(tmp_path):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("routine_model: claude-opus-5\n")
    mirror = tmp_path / "OWNER_ACTIONS.md"
    mirror.write_text("All remote routines run claude-opus-5.\n")
    errs, model = check_model_of_record(str(cadence), [str(mirror)], str(tmp_path))
    assert errs == []
    assert model == "claude-opus-5"


def test_check_model_of_record_flags_a_drifted_mirror(tmp_path):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("routine_model: claude-opus-5\n")
    mirror = tmp_path / "OWNER_ACTIONS.md"
    mirror.write_text("All remote routines run claude-opus-6.\n")
    errs, model = check_model_of_record(str(cadence), [str(mirror)], str(tmp_path))
    assert len(errs) == 1
    assert "claude-opus-6" in errs[0]
    assert model == "claude-opus-5"


def test_check_model_of_record_missing_routine_model(tmp_path):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("timezone: America/Denver\n")
    errs, model = check_model_of_record(str(cadence), [], str(tmp_path))
    assert model is None
    assert len(errs) == 1
    assert "missing top-level 'routine_model'" in errs[0]


def test_check_model_of_record_rejects_malformed_model_id(tmp_path):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("routine_model: opus-5\n")
    errs, model = check_model_of_record(str(cadence), [], str(tmp_path))
    assert model is None
    assert "must be a bare Claude model id" in errs[0]


def test_check_model_of_record_rejects_trailing_non_alphanumeric(tmp_path):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("routine_model: claude-opus-5-\n")
    errs, model = check_model_of_record(str(cadence), [], str(tmp_path))
    assert model is None
    assert "ends with '-'" in errs[0]


def test_check_model_of_record_rejects_tooling_prefix_as_routine_model(tmp_path):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("routine_model: claude-code\n")
    errs, model = check_model_of_record(str(cadence), [], str(tmp_path))
    assert model is None
    assert "CLI/SDK tooling" in errs[0]


def test_check_model_of_record_honors_model_id_exempt_marker(tmp_path):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("routine_model: claude-opus-5\n")
    mirror = tmp_path / "OWNER_ACTIONS.md"
    mirror.write_text("Historical: claude-opus-4 (model-id-exempt) preceded the current model.\n")
    errs, _model = check_model_of_record(str(cadence), [str(mirror)], str(tmp_path))
    assert errs == []


def test_check_model_of_record_skips_an_absent_mirror_file(tmp_path):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("routine_model: claude-opus-5\n")
    absent = tmp_path / "does_not_exist.md"
    errs, model = check_model_of_record(str(cadence), [str(absent)], str(tmp_path))
    assert errs == []
    assert model == "claude-opus-5"


def test_check_model_of_record_accepts_a_preparsed_doc(tmp_path):
    # doc bypasses load_yaml(cadence_path) entirely -- cadence_path need not even exist on disk.
    errs, model = check_model_of_record(
        str(tmp_path / "does_not_exist.yaml"), [], str(tmp_path),
        doc={"routine_model": "claude-opus-5"})
    assert errs == []
    assert model == "claude-opus-5"


def test_check_model_of_record_reports_mirror_paths_relative_to_root(tmp_path):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("routine_model: claude-opus-5\n")
    sub = tmp_path / "sub"
    sub.mkdir()
    mirror = sub / "notes.md"
    mirror.write_text("claude-opus-6 is wrong.\n")
    errs, _model = check_model_of_record(str(cadence), [str(mirror)], str(tmp_path))
    expected_rel = os.path.relpath(str(mirror), str(tmp_path))
    assert len(errs) == 1
    assert errs[0].startswith(f"{expected_rel}:1:")
