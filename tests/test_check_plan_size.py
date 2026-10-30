"""The size guard must catch prose growth without exempting unrelated content."""

from conftest import load_module_from_path


cs = load_module_from_path("check_plan_size", "scripts", "check_plan_size.py")


def test_paragraph_limit_counts_unicode_characters_and_reports_line():
    text = "# Plan\n\n" + "é" * 10 + "\n \t\n" + "x" * 11 + "\n"
    assert cs.oversized_paragraphs(text, limit=10) == [(5, 11)]


def test_inventory_exemption_is_only_for_its_table():
    text = (
        "# ROUTINE INVENTORY & BIGQUERY RESPONSIBILITIES\n\n"
        + cs.INVENTORY_HEADER + "\n|---|---|---|---|---|---|\n\n"
        + "y" * 61 + "\n\n"
        "| ID | " + "x" * 61 + " |\n\n"
        "# OPERATING MODEL\n\n"
        "| ID | " + "z" * 61 + " |\n"
    )
    assert cs.oversized_paragraphs(text, limit=60) == [(6, 61), (8, 70), (12, 70)]


def test_cli_fails_for_over_budget_plan(tmp_path, monkeypatch, capsys):
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text("x" * (cs.MAX_PARAGRAPH_CHARS + 1), encoding="utf-8")
    monkeypatch.setattr(cs, "TASK_PLAN", plan)
    assert cs.main() == 1
    assert "Claude_Task_Plan.md:1" in capsys.readouterr().out


def test_real_plan_uses_tight_budget_at_most_twenty_thousand():
    paragraphs = cs.oversized_paragraphs(
        cs.TASK_PLAN.read_text(encoding="utf-8"), limit=0,
    )
    maximum = max(size for _, size in paragraphs)
    assert cs.MAX_PARAGRAPH_CHARS <= 20_000
    assert cs.MAX_PARAGRAPH_CHARS == (maximum // 1_000 + 1) * 1_000
    assert cs.main() == 0
