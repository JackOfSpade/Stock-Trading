"""Offline regressions for the 2026-08-01 decision-log integrity hardening."""
import re
from pathlib import Path

from lib.sql_files import strip_sql_comments


ROOT = Path(__file__).resolve().parents[1]
CORRECTION_SQL = ROOT / "bigquery" / "122_decision_correction_append_only.sql"
HORIZON_CORRECTION_SQL = ROOT / "bigquery" / "121_position_horizon_date_corrections.sql"
PLAN = ROOT / "Claude_Task_Plan.md"
D1_SLICE = ROOT / "task_plan" / "D1.md"


def _d1_body(text):
    marker = "## D1. Market Development Scan"
    start = text.index(marker)
    end = text.find("\n## D2a.", start)
    return text[start:] if end == -1 else text[start:end]


def test_find_precedents_excludes_correction_target_not_correction_row():
    sql = CORRECTION_SQL.read_text()
    code = strip_sql_comments(sql)

    # `superseded_by` is carried on the newly-appended correction and names the stale target. The
    # final-effective anti-join must therefore select that column, not the correction's entry_id.
    assert re.search(
        r"WHERE\s+base\.entry_id\s+NOT\s+IN\s*\(\s*SELECT\s+superseded_by\s+"
        r"FROM\s+`stock-trading-498512\.events\.decision_log`\s+WHERE\s+superseded_by\s+IS\s+NOT\s+NULL",
        code,
        re.DOTALL,
    )
    assert not re.search(
        r"SELECT\s+entry_id\s+FROM\s+`stock-trading-498512\.events\.decision_log`\s+"
        r"WHERE\s+superseded_by\s+IS\s+NOT\s+NULL",
        code,
        re.DOTALL,
    )

    rows = [
        {"entry_id": "old", "superseded_by": None},
        {"entry_id": "correction", "superseded_by": "old"},
        {"entry_id": "unrelated", "superseded_by": None},
    ]
    obsolete_targets = {row["superseded_by"] for row in rows if row["superseded_by"] is not None}
    final_effective = {row["entry_id"] for row in rows if row["entry_id"] not in obsolete_targets}
    assert final_effective == {"correction", "unrelated"}


def test_correction_definition_is_append_only_and_final_effective():
    sql = CORRECTION_SQL.read_text()
    code = strip_sql_comments(sql)
    assert "CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.find_precedents`" in code
    assert "CREATE OR REPLACE VIEW `stock-trading-498512.state.research_screen_calls`" in code
    assert "CREATE OR REPLACE VIEW `stock-trading-498512.state.add_candidate_reviews`" in code
    assert not re.search(r"\b(?:UPDATE|DELETE|MERGE)\b", code, re.IGNORECASE)
    assert "PRESERVES the superseded row's semantic entry_type" in sql
    assert "carries tag `correction`" in sql
    assert "No UPDATE, DELETE, or MERGE against events.decision_log is" in sql
    assert "permitted here." in sql


def test_d1_parser_views_replace_old_rows_without_losing_their_semantic_type():
    code = strip_sql_comments(CORRECTION_SQL.read_text())
    target_filter = (
        r"AND\s+entry_id\s+NOT\s+IN\s*\(\s*SELECT\s+superseded_by\s+"
        r"FROM\s+`stock-trading-498512\.events\.decision_log`\s+WHERE\s+superseded_by\s+IS\s+NOT\s+NULL"
    )
    for entry_type, view_name in [
        ("research-screen", "research_screen_calls"),
        ("add-candidate-review", "add_candidate_reviews"),
    ]:
        start = code.index(f"CREATE OR REPLACE VIEW `stock-trading-498512.state.{view_name}`")
        view_code = code[start:]
        assert f"WHERE entry_type = '{entry_type}'" in view_code
        assert re.search(target_filter, view_code, re.DOTALL)

    rows = [
        {"entry_id": "old-screen", "entry_type": "research-screen", "superseded_by": None},
        {"entry_id": "new-screen", "entry_type": "research-screen", "superseded_by": "old-screen"},
        {"entry_id": "old-add", "entry_type": "add-candidate-review", "superseded_by": None},
        {"entry_id": "new-add", "entry_type": "add-candidate-review", "superseded_by": "old-add"},
    ]
    targets = {row["superseded_by"] for row in rows if row["superseded_by"]}
    final_by_type = {
        kind: {row["entry_id"] for row in rows
               if row["entry_type"] == kind and row["entry_id"] not in targets}
        for kind in ("research-screen", "add-candidate-review")
    }
    assert final_by_type["research-screen"] == {"new-screen"}
    assert final_by_type["add-candidate-review"] == {"new-add"}


def test_d1_requires_final_state_before_append_and_never_in_place_repair():
    d1 = _d1_body(PLAN.read_text())
    assert d1.count("Late-data discipline") >= 2
    assert "including any D2a reconciliation that overlapped this D1" in d1
    assert "re-read `state.current_positions` and any overlapping D2a reconciliation output" in d1
    assert d1.count("in_superseded_by=<old entry_id>") >= 2
    assert "preserves `entry_type='research-screen'`, carries tag `correction`" in d1
    assert "preserves `entry_type='add-candidate-review'`, carries tag `correction`" in d1
    assert "Never UPDATE, DELETE, or MERGE `events.decision_log`." in d1


def test_generated_d1_slice_carries_the_same_append_only_rule():
    d1 = _d1_body(D1_SLICE.read_text())
    assert "Late-data discipline for this durable add-candidate record" in d1
    assert "Never UPDATE, DELETE, or MERGE `events.decision_log`." in d1


def test_horizon_date_correction_is_full_row_append_only_and_rerun_safe():
    """The one-time position fix must remain a guarded, append-only full-row correction."""
    code = strip_sql_comments(HORIZON_CORRECTION_SQL.read_text())

    # This migration may append position events, but must never rewrite either events table.
    assert not re.search(r"\b(?:UPDATE|DELETE|MERGE)\b", code, re.IGNORECASE)

    insert_re = re.compile(
        r"INSERT\s+INTO\s+`stock-trading-498512\.events\.position_events`\s*"
        r"\((?P<columns>.*?)\)\s*SELECT(?P<select>.*?)FROM\s+preflight\s*"
        r"WHERE\s+(?P<predicate>.*?);",
        re.DOTALL,
    )
    inserts = list(insert_re.finditer(code))
    assert len(inserts) == 2

    expected_columns = [
        "event_id", "event_ts", "position_key", "event_type", "status", "strategy", "ticker",
        "contract_id", "cost_basis", "shares", "convergence_target", "time_exit_date", "ltcg_date",
        "invalidation_status", "conviction", "model_at_entry", "source_thesis_ref", "note",
    ]
    carried_columns = [
        "position_key", "status", "strategy", "ticker", "contract_id", "cost_basis", "shares",
        "convergence_target", "invalidation_status", "conviction", "model_at_entry", "source_thesis_ref",
    ]
    for match in inserts:
        columns = re.sub(r"\s+", "", match.group("columns")).split(",")
        assert columns == expected_columns
        for column in carried_columns:
            assert re.search(rf"\b{column}\b", match.group("select"))

    predicates = {match.group("predicate") for match in inserts}
    assert any(re.search(
        r"position_key\s*=\s*'D:RTX:2026-04-27'\s+AND\s+"
        r"time_exit_date\s*=\s*DATE\s+'2027-04-27'\s+AND\s+ltcg_date\s+IS\s+NULL",
        predicate,
    ) for predicate in predicates)
    assert any(re.search(
        r"position_key\s*=\s*'D:DIS:2026-05-07'\s+AND\s+ltcg_date\s+IS\s+NULL",
        predicate,
    ) for predicate in predicates)

    # Each preflight accepts precisely the historical defect or its final corrected state, which
    # lets a successful rerun append no duplicate adjustment.
    assert re.search(
        r"time_exit_date\s*=\s*DATE\s+'2027-04-27'\s+AND\s+ltcg_date\s+IS\s+NULL\s*\)\s*"
        r"OR\s*\(\s*time_exit_date\s+IS\s+NULL\s+AND\s+ltcg_date\s*=\s*DATE\s+'2027-04-27'",
        code,
        re.DOTALL,
    )
    assert re.search(
        r"ltcg_date\s+IS\s+NULL\s+OR\s+ltcg_date\s*=\s*DATE\s+'2027-05-08'",
        code,
    )

    begin = code.index("BEGIN TRANSACTION;")
    commit = code.index("COMMIT TRANSACTION;")
    assert begin < inserts[0].start() < inserts[1].start() < commit
    for postcondition in (
        "RTX state is not the full-row carry-forward with corrected dates.",
        "DIS state is not the full-row carry-forward with corrected LTCG date.",
        "RTX ADJUST event was not appended exactly once.",
        "DIS ADJUST event was not appended exactly once.",
    ):
        assert inserts[-1].end() < code.index(postcondition) < commit
