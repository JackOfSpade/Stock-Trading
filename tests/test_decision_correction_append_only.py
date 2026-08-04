"""Offline regressions for the 2026-08-01 decision-log integrity hardening."""
import re
from pathlib import Path

from lib.sql_files import strip_sql_comments


ROOT = Path(__file__).resolve().parents[1]
CORRECTION_SQL = ROOT / "bigquery" / "122_decision_correction_append_only.sql"
HORIZON_CORRECTION_SQL = ROOT / "bigquery" / "121_position_horizon_date_corrections.sql"
SL1_LEADS_SQL = ROOT / "bigquery" / "133_sl1_research_leads_and_record_corrections.sql"
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


def test_sl1_leads_no_update_delete_merge_targets_decision_log():
    """bigquery/133 legitimately contains one UPDATE, but it targets the deliberately mutable
    state.strategy_candidates registry (see the file's own comment above it), never
    events.decision_log. A bare `not re.search(r"\bUPDATE\b", code)` would wrongly fail on that
    UPDATE, so this must check each UPDATE/DELETE/MERGE statement's OWN target table."""
    sql = SL1_LEADS_SQL.read_text()
    code = strip_sql_comments(sql)

    targets = re.findall(
        r"\b(?:UPDATE|DELETE\s+FROM|MERGE(?:\s+INTO)?)\s+`([^`]+)`",
        code,
        re.IGNORECASE,
    )
    assert targets, "expected at least the state.strategy_candidates UPDATE to be present"
    assert not any(t.endswith("events.decision_log") for t in targets)
    assert any(t.endswith("state.strategy_candidates") for t in targets)


def test_sl1_leads_corrections_route_through_sp_log_decision_with_superseded_by():
    sql = SL1_LEADS_SQL.read_text()
    code = strip_sql_comments(sql)

    stale_entry_ids = {
        "ef3cfdcf-8da8-43f8-83a1-3619a66aaf62",
        "789de922-da85-4451-bf9c-340c0a52ee57",
    }

    # Each correction is guarded by `IF NOT EXISTS (... WHERE superseded_by = '<stale id>') THEN
    # CALL ops.sp_log_decision(...) END IF;`. Extract the guarded block for each stale id and
    # confirm the CALL inside it names that SAME id as in_superseded_by and carries tag
    # 'correction' -- not just that a CALL and a superseded_by exist somewhere in the file.
    if_block_re = re.compile(
        r"IF\s+NOT\s+EXISTS\s*\(\s*SELECT\s+1\s+FROM\s+`stock-trading-498512\.events\.decision_log`\s+"
        r"WHERE\s+superseded_by\s*=\s*'(?P<stale_id>[^']+)'\s*\)\s*THEN"
        r"(?P<body>.*?)"
        r"END\s+IF;",
        re.DOTALL,
    )
    # The CALL's positional args end `..., [<tags>], '<in_superseded_by>', '<in_source_session>');`
    # -- anchoring on the tags array immediately followed by exactly two more quoted args and the
    # closing `);` finds the true call terminator even though the file also contains an
    # unrelated `);`-shaped substring inside a title string ("... rejected (H); 2 research ...").
    call_tail_re = re.compile(
        r"\[(?P<tags>[^\[\]]*)\]\s*,\s*'(?P<superseded_by>[^']+)'\s*,\s*'[^']*'\s*\)\s*;",
        re.DOTALL,
    )

    blocks = list(if_block_re.finditer(code))
    assert len(blocks) == 2
    assert {b.group("stale_id") for b in blocks} == stale_entry_ids

    for block in blocks:
        stale_id = block.group("stale_id")
        body = block.group("body")
        assert "CALL `stock-trading-498512.ops.sp_log_decision`(" in body
        tail = call_tail_re.search(body)
        assert tail is not None, f"could not locate sp_log_decision's trailing args for {stale_id}"
        assert tail.group("superseded_by") == stale_id
        assert "'correction'" in tail.group("tags")


def test_sl1_leads_inserts_are_guarded_by_where_not_exists_on_own_lead_id():
    """Each strategy_research_leads INSERT must be re-apply-safe: guarded by a WHERE NOT EXISTS
    that names THAT SAME insert's own lead_id, not just any WHERE NOT EXISTS anywhere."""
    sql = SL1_LEADS_SQL.read_text()
    code = strip_sql_comments(sql)

    lead_ids = {
        "sl1-2026-08-disclosure-information-surprise",
        "a1-2026-2.20-heterogeneous-regime",
    }

    insert_re = re.compile(
        r"INSERT INTO `stock-trading-498512\.events\.strategy_research_leads`.*?"
        r"SELECT\s*\n\s*'(?P<select_lead_id>[^']+)',\s*'OPEN',.*?"
        r"WHERE NOT EXISTS \(\s*"
        r"SELECT 1 FROM `stock-trading-498512\.events\.strategy_research_leads`\s*"
        r"WHERE lead_id = '(?P<guard_lead_id>[^']+)'\s*"
        r"\);",
        re.DOTALL,
    )
    inserts = list(insert_re.finditer(code))
    assert len(inserts) == 2
    for match in inserts:
        assert match.group("select_lead_id") == match.group("guard_lead_id")
    assert {m.group("select_lead_id") for m in inserts} == lead_ids


def test_sl1_leads_has_no_bare_doubled_quote_escape():
    """BigQuery does not use SQL-standard '' doubling to escape a quote inside a string literal
    (it reads adjacent literals as concatenation and fails to parse) -- bigquery/117's EDITOR TRAP
    comment documents this repo hitting it twice. A `''` that is part of a `'''` triple-quote
    delimiter is fine; an isolated `''` is the trap. `(?<!')''(?!')` matches a `''` run that is
    exactly two quotes long -- neither preceded nor followed by another `'` -- so it never fires
    inside a `'''` delimiter (each `'` in a 3-run has an adjacent `'` on one side) but does fire on
    a standalone doubled-quote escape."""
    sql = SL1_LEADS_SQL.read_text()
    code = strip_sql_comments(sql)

    bad = list(re.finditer(r"(?<!')''(?!')", code))
    assert not bad, [code[max(0, m.start() - 40):m.start() + 40] for m in bad]
