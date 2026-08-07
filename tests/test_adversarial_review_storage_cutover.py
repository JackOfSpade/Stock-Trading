"""Static contract tests for bigquery/146's serialized transcript writer."""
from pathlib import Path


SQL = (Path(__file__).resolve().parents[1] / "bigquery" / "146_adversarial_review_writer_serialization.sql").read_text()


def test_writer_uses_a_transaction_and_returns_its_own_generated_identity():
    assert "DECLARE inserted_event_id STRING DEFAULT GENERATE_UUID();" in SQL
    assert "ops.adversarial_review_write_mutex" in SQL
    assert "WHERE lock_name = 'adversarial-review-writer';" in SQL
    assert "ASSERT mutex_rows = 1" in SQL
    assert "BEGIN TRANSACTION;" in SQL
    assert "COMMIT TRANSACTION;" in SQL
    assert "WHERE event_id = inserted_event_id;" in SQL
    assert "QUALIFY ROW_NUMBER() OVER (ORDER BY event_ts DESC)" not in SQL


def test_singleton_mutex_update_precedes_current_row_checks_and_the_append():
    procedure = SQL[SQL.index("CREATE OR REPLACE PROCEDURE"):SQL.index("-- 145's Python repair client")]
    mutex_update = procedure.index("UPDATE `stock-trading-498512.ops.adversarial_review_write_mutex`")
    current_row_check = procedure.index("IF p_superseded_by IS NULL THEN")
    transcript_insert = procedure.index("INSERT INTO `stock-trading-498512.events.adversarial_reviews`")
    assert mutex_update < current_row_check < transcript_insert


def test_writer_validates_queue_provenance_and_monotonic_cycles():
    queue_assertion = SQL[SQL.index("FROM `stock-trading-498512.events.queue_events` q") - 120:
                          SQL.index("END IF;", SQL.index("FROM `stock-trading-498512.events.queue_events` q"))]
    assert "SELECT COUNT(*) = 1" in queue_assertion
    assert "SELECT 1\n      FROM `stock-trading-498512.events.queue_events` q" not in queue_assertion
    for fragment in (
        "p_superseded_by IS NOT NULL\n      OR (p_queue_event_id IS NOT NULL AND p_queue_event_id != '')",
        "IF p_role IN ('attacker', 'orchestrator') AND p_queue_event_id IS NOT NULL THEN",
        "FROM `stock-trading-498512.events.queue_events` q",
        "q.queue = 'PENDING_REVIEW'",
        "q.item_key = p_review_id",
        "q.status = IF(p_role = 'attacker', 'pending', 'attacker-complete')",
        "JSON_VALUE(q.payload, '$.cycle_number')",
        "p_superseded_by IS NULL AND q.event_ts <= inserted_event_ts",
        "q.event_ts <= target.event_ts",
        "a normal write must use a cycle_number higher",
        "an orchestrator write requires a current attacker row",
    ):
        assert fragment in SQL


def test_correction_must_preserve_review_semantics_and_referee_can_use_it():
    for fragment in (
        "(p_role = 'referee_gemini' AND p_superseded_by IS NOT NULL)",
        "review_type IS NOT DISTINCT FROM p_review_type",
        "strategy IS NOT DISTINCT FROM p_strategy",
        "verdict IS NOT DISTINCT FROM p_verdict",
        "theater_check IS NOT DISTINCT FROM p_theater_check",
        "TO_JSON_STRING(weaknesses) IS NOT DISTINCT FROM TO_JSON_STRING(p_weaknesses)",
        "artifact_path IS NOT DISTINCT FROM p_artifact_path",
        "queue_event_id IS NOT DISTINCT FROM p_queue_event_id",
    ):
        assert fragment in SQL


def test_json_type_repair_is_an_explicit_asserted_migration_not_a_writer_exception():
    assert "IF ARRAY_LENGTH(json_string_target_ids) > 0 THEN" in SQL
    assert "ASSERT ARRAY_LENGTH(json_string_target_ids) = 30" in SQL
    assert "role IN ('attacker', 'orchestrator')" in SQL
    assert "JSON_TYPE(SAFE.PARSE_JSON(JSON_VALUE(weaknesses, '$'))) = 'array'" in SQL
    assert "SAFE.PARSE_JSON(JSON_VALUE(weaknesses, '$'))" in SQL
    assert "source_commit_sha, queue_event_id, 1" in SQL
    assert "a current attacker/orchestrator transcript still has JSON-string weaknesses" in SQL
    assert "corrections may change only body_md" in SQL
