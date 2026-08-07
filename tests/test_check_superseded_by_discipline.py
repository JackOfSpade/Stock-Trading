"""Regression tests for the append-only correction-reader checker."""
from conftest import load_module_from_path


cs = load_module_from_path("check_superseded_by_discipline", "scripts", "check_superseded_by_discipline.py")


def _tree(tmp_path, files, monkeypatch):
    directory = tmp_path / "bigquery"
    directory.mkdir()
    for name, text in files.items():
        (directory / name).write_text(text, encoding="utf-8")
    monkeypatch.setattr(cs, "BIGQUERY_DIR", str(directory))
    monkeypatch.setattr(cs, "ALLOWLIST", {})


def test_real_repo_passes_the_superseded_by_discipline_gate():
    assert cs.main() == 0


def test_control_flow_on_a_procedure_parameter_is_not_a_row_filter(tmp_path, monkeypatch):
    _tree(tmp_path, {
        "10_writer.sql": """
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_writer`(p_superseded_by STRING)
BEGIN
  IF p_superseded_by IS NULL THEN
    SELECT 1;
  END IF;
END;
""",
    }, monkeypatch)
    assert cs.main() == 0


def test_real_inverted_filter_is_still_rejected(tmp_path, monkeypatch):
    _tree(tmp_path, {
        "10_bad_view.sql": """
CREATE OR REPLACE VIEW `stock-trading-498512.state.bad` AS
SELECT *
FROM `stock-trading-498512.events.adversarial_reviews` a
WHERE a.superseded_by IS NULL;
""",
    }, monkeypatch)
    assert cs.main() == 1
