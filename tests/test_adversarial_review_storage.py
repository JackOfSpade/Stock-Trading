"""Offline tests for the append-only adversarial-review export/audit tool."""
import concurrent.futures
import hashlib
import types
from copy import deepcopy

import pytest

from conftest import load_module_from_path


ars = load_module_from_path("adversarial_review_storage", "scripts", "adversarial_review_storage.py")


BODY = "# Adversarial Review — Attacker\n\n- **id:** review-A-1\n- **cycle_number:** 3\n\nBody.\n"
SHA = hashlib.sha256(BODY.encode("utf-8")).hexdigest().upper()
KEY = ars.ReviewKey("review-A-1", "attacker", 3)


def _row(body=BODY, sha=SHA, **overrides):
    row = {"review_id": "review-A-1", "role": "attacker", "cycle_number": "3",
           "body_md": body, "body_sha256": sha}
    row.update(overrides)
    return row


def _full_row(body=BODY, **overrides):
    row = {
        "event_id": "old-event", "event_ts": "2026-08-04 12:00:00+00", "review_id": "review-A-1",
        "review_type": "pre-mortem", "strategy": "A", "role": "attacker", "review_date": "2026-08-04",
        "cycle_number": 3, "verdict": "REVISE", "theater_check": "MIXED", "weaknesses": [{"n": 1}],
        "artifact_path": "strategy/08_pre_mortems.md", "body_md": body, "source_commit_sha": None,
        "queue_event_id": None, "content_sha256": None, "body_bytes": None,
        "body_sha256": hashlib.sha256(body.encode("utf-8")).hexdigest().upper(),
    }
    row.update(overrides)
    return row


class FakeRepairWarehouse:
    def __init__(self, current, queue_event_id="queue-event", postwrite_metadata=True):
        self.current = current
        self.queue_event_id = queue_event_id
        self.postwrite_metadata = postwrite_metadata
        self.resolve_calls = []
        self.append_calls = []

    def fetch_current_full(self, key):
        return [deepcopy(self.current)]

    def resolve_queue_event_id(self, row, key):
        self.resolve_calls.append((deepcopy(row), key))
        if isinstance(self.queue_event_id, Exception):
            raise self.queue_event_id
        return self.queue_event_id

    def append_replacement(self, row, key, body_md, expected_sha256, queue_event_id):
        self.append_calls.append((deepcopy(row), key, body_md, expected_sha256, queue_event_id))
        self.current = deepcopy(row)
        self.current.update({
            "event_id": "new-event", "body_md": body_md, "body_sha256": expected_sha256.upper(),
            "content_sha256": expected_sha256 if self.postwrite_metadata else None,
            "body_bytes": len(body_md.encode("utf-8")) if self.postwrite_metadata else None,
            "queue_event_id": queue_event_id,
        })
        return "new-event"


def test_review_query_is_exact_current_view_query():
    sql = ars.review_query(KEY, "proj-1")
    assert "proj-1.state.adversarial_reviews_current" in sql
    assert "review_id = 'review-A-1'" in sql
    assert "role = 'attacker'" in sql
    assert "cycle_number = 3" in sql
    assert "events.adversarial_reviews" not in sql


@pytest.mark.parametrize("review_id, role, cycle", [
    ("bad quote'", "attacker", 1), ("review-A", "Bad", 1), ("review-A", "attacker", 0),
])
def test_key_validation_rejects_values_that_cannot_safely_form_sql(review_id, role, cycle):
    with pytest.raises(ValueError):
        ars._validate_key(review_id, role, cycle)


def test_fetch_review_delegates_to_bq_and_checks_warehouse_hash(monkeypatch):
    captured = {}

    def fake_bq(sql, project):
        captured["sql"], captured["project"] = sql, project
        return [_row()]
    monkeypatch.setattr(ars, "bq", fake_bq)
    assert ars.fetch_review(KEY, "proj-1") == _row()
    assert captured["project"] == "proj-1"
    assert "state.adversarial_reviews_current" in captured["sql"]


@pytest.mark.parametrize("rows, match", [
    ([], "found 0"), ([_row(), _row()], "found 2"),
])
def test_fetch_review_rejects_missing_or_ambiguous_rows(monkeypatch, rows, match):
    monkeypatch.setattr(ars, "bq", lambda sql, project: rows)
    with pytest.raises(LookupError, match=match):
        ars.fetch_review(KEY)


def test_fetch_review_rejects_a_row_with_bad_reported_hash(monkeypatch):
    monkeypatch.setattr(ars, "bq", lambda sql, project: [_row(sha="0" * 64)])
    with pytest.raises(ValueError, match="does not match"):
        ars.fetch_review(KEY)


def test_parse_legacy_review_uses_metadata_and_filename_role(tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    assert ars.parse_legacy_review(path) == (KEY, BODY)


def test_parse_legacy_review_preserves_crlf_bytes_for_exact_hashing(tmp_path):
    body = BODY.replace("\n", "\r\n")
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_bytes(body.encode("utf-8"))
    key, parsed = ars.parse_legacy_review(path)
    assert key == KEY
    assert parsed == body
    assert parsed.encode("utf-8") == path.read_bytes()


def test_parse_legacy_orchestrator_uses_filename_id_and_prose_cycle_label_when_id_is_absent(tmp_path):
    body = ("# Adversarial Review — Orchestrator — review-A-1\n\n"
            "- **Review type:** pre-mortem\n"
            "- **Cycle number:** 3 (recurring; prior cycle resolved)\n\n"
            "Body.\n")
    path = tmp_path / "Adversarial_Review_review-A-1_orchestrator.md"
    path.write_text(body, encoding="utf-8")
    assert ars.parse_legacy_review(path) == (ars.ReviewKey("review-A-1", "orchestrator", 3), body)


def test_parse_legacy_review_rejects_filename_metadata_identity_mismatch(tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-2_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    with pytest.raises(ValueError, match="does not match"):
        ars.parse_legacy_review(path)


@pytest.mark.parametrize("body, match", [
    ("- **id:** review-A-1\n", "missing cycle_number"),
    (BODY + "- **id:** review-A-1\n", "duplicate id metadata"),
    (BODY.replace("**cycle_number:** 3", "**cycle_number:** nope"), "must begin with a positive integer"),
])
def test_parse_legacy_review_rejects_incomplete_or_ambiguous_metadata(tmp_path, body, match):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(body, encoding="utf-8")
    with pytest.raises(ValueError, match=match):
        ars.parse_legacy_review(path)


def test_audit_file_reports_matching_hash(monkeypatch, tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    monkeypatch.setattr(ars, "fetch_review", lambda key, project: _row())
    result = ars.audit_file(path)
    assert result.status == "OK"
    assert result.local_sha256 == SHA == result.warehouse_sha256


def test_audit_file_handles_crlf_as_exact_utf8_bytes(monkeypatch, tmp_path):
    body = BODY.replace("\n", "\r\n")
    sha = hashlib.sha256(body.encode("utf-8")).hexdigest().upper()
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_bytes(body.encode("utf-8"))
    monkeypatch.setattr(ars, "fetch_review", lambda key, project: _row(body=body, sha=sha))
    result = ars.audit_file(path)
    assert result.status == "OK"
    assert result.local_sha256 == sha


def test_audit_file_reports_hash_mismatch(monkeypatch, tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    other_body = BODY + "changed\n"
    monkeypatch.setattr(ars, "fetch_review", lambda key, project: _row(body=other_body,
                                                                           sha=hashlib.sha256(other_body.encode()).hexdigest().upper()))
    result = ars.audit_file(path)
    assert result.status == "MISMATCH"
    assert result.local_sha256 != result.warehouse_sha256


def test_audit_file_distinguishes_missing_from_query_failure(monkeypatch, tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    monkeypatch.setattr(ars, "fetch_review", lambda key, project: (_ for _ in ()).throw(LookupError("found 0")))
    assert ars.audit_file(path).status == "MISSING"
    monkeypatch.setattr(ars, "fetch_review", lambda key, project: (_ for _ in ()).throw(RuntimeError("auth denied")))
    assert ars.audit_file(path).status == "ERROR"


def test_repair_dry_run_plans_replacement_without_appending(tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    warehouse = FakeRepairWarehouse(_full_row(body="short summary\n"))
    result = ars.repair_file(path, warehouse)
    assert result.status == "DRY_RUN"
    assert result.obsolete_event_id == "old-event"
    assert warehouse.resolve_calls and warehouse.append_calls == []


def test_repair_matching_legacy_body_is_noop_even_when_new_metadata_is_null(tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    warehouse = FakeRepairWarehouse(_full_row())
    result = ars.repair_file(path, warehouse)
    assert result.status == "NOOP"
    assert "legacy nullable metadata preserved" in result.detail
    assert warehouse.resolve_calls == [] and warehouse.append_calls == []


def test_repair_apply_preserves_procedure_metadata_and_verifies_new_fields(tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    original = _full_row(body="short summary\n", source_commit_sha="a" * 40)
    warehouse = FakeRepairWarehouse(original)
    result = ars.repair_file(path, warehouse, apply=True)
    assert result.status == "APPLIED"
    assert result.replacement_event_id == "new-event"
    preserved, key, body, sha, queue_id = warehouse.append_calls[0]
    assert preserved == original
    assert key == KEY and body == BODY and sha == SHA.lower() and queue_id == "queue-event"
    assert warehouse.current["content_sha256"] == SHA.lower()
    assert warehouse.current["body_bytes"] == len(BODY.encode("utf-8"))


def test_repair_apply_fails_if_procedure_readback_lacks_new_integrity_metadata(tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    warehouse = FakeRepairWarehouse(_full_row(body="short summary\n"), postwrite_metadata=False)
    assert ars.repair_file(path, warehouse, apply=True).status == "ERROR"


def test_repair_aborts_when_legacy_queue_provenance_is_ambiguous(tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    warehouse = FakeRepairWarehouse(_full_row(body="short summary\n"), queue_event_id=LookupError("found 2"))
    result = ars.repair_file(path, warehouse)
    assert result.status == "ERROR"
    assert "queue provenance not resolved" in result.detail
    assert warehouse.append_calls == []


def test_google_repair_call_uses_only_typed_parameters_for_body_and_metadata():
    warehouse = object.__new__(ars.GoogleBigQueryWarehouse)
    warehouse.project = "proj-1"
    warehouse._scalar = lambda name, type_, value: (name, type_, value)
    captured = {}

    def fake_rows(sql, parameters):
        captured["sql"], captured["parameters"] = sql, parameters
        return [{"event_id": "new-event"}]
    warehouse._rows = fake_rows
    body = "apostrophe ' and SQL-looking ; DROP TABLE x;"
    row = _full_row(body="short\n")
    assert warehouse.append_replacement(row, KEY, body, "a" * 64, "queue-event") == "new-event"
    assert body not in captured["sql"]
    assert "@p_body_md" in captured["sql"] and "@p_superseded_by" in captured["sql"]
    params = {name: (type_, value) for name, type_, value in captured["parameters"]}
    assert params["p_body_md"] == ("STRING", body)
    assert params["p_superseded_by"] == ("STRING", "old-event")
    # A JSON parameter must receive the Python array/object.  A serialized string would store a
    # JSON string containing an array instead of preserving the JSON column's original shape.
    assert params["p_weaknesses"] == ("JSON", [{"n": 1}])


def test_google_repair_parses_legacy_json_string_before_binding_json_parameter():
    warehouse = object.__new__(ars.GoogleBigQueryWarehouse)
    warehouse.project = "proj-1"
    warehouse._scalar = lambda name, type_, value: (name, type_, value)
    captured = {}

    def fake_rows(sql, parameters):
        captured["parameters"] = parameters
        return [{"event_id": "new-event"}]

    warehouse._rows = fake_rows
    row = _full_row(body="short\n", weaknesses='[{"n":1}]')
    assert warehouse.append_replacement(row, KEY, BODY, "a" * 64, "queue-event") == "new-event"
    params = {name: (type_, value) for name, type_, value in captured["parameters"]}
    assert params["p_weaknesses"] == ("JSON", [{"n": 1}])


def test_legacy_queue_derivation_uses_latest_transition_when_two_pending_rows_have_distinct_times():
    warehouse = object.__new__(ars.GoogleBigQueryWarehouse)
    warehouse.project = "proj-1"
    warehouse._scalar = lambda name, type_, value: (name, type_, value)
    captured = {}

    def fake_rows(sql, parameters):
        captured["sql"], captured["parameters"] = sql, parameters
        # These represent two candidates at distinct event_ts values. The MAX-filtered BigQuery
        # query returns only the newer transition, which is the queue latest-wins rule.
        return [{"event_id": "newer-pending-transition"}]
    warehouse._rows = fake_rows
    assert warehouse.resolve_queue_event_id(_full_row(), KEY) == "newer-pending-transition"
    assert "SELECT MAX(event_ts) FROM candidates" in captured["sql"]
    assert "ORDER BY event_ts DESC" not in captured["sql"]


def test_stored_queue_provenance_is_scoped_to_exact_cycle_and_review_time():
    warehouse = object.__new__(ars.GoogleBigQueryWarehouse)
    warehouse.project = "proj-1"
    warehouse._scalar = lambda name, type_, value: (name, type_, value)
    captured = {}

    def fake_rows(sql, parameters):
        captured["sql"], captured["parameters"] = sql, parameters
        return [{"event_id": "stored-pending-transition"}]

    warehouse._rows = fake_rows
    row = _full_row(queue_event_id="stored-pending-transition")
    assert warehouse.resolve_queue_event_id(row, KEY) == "stored-pending-transition"
    assert "event_ts <= @review_event_ts" in captured["sql"]
    assert "JSON_VALUE(payload, '$.cycle_number')" in captured["sql"]
    params = {name: value for name, _type, value in captured["parameters"]}
    assert params["cycle_number"] == KEY.cycle_number
    assert params["review_event_ts"] == row["event_ts"]


def test_legacy_queue_derivation_fails_closed_when_latest_transition_timestamp_ties():
    warehouse = object.__new__(ars.GoogleBigQueryWarehouse)
    warehouse.project = "proj-1"
    warehouse._scalar = lambda name, type_, value: (name, type_, value)
    # A tie at MAX(event_ts) intentionally leaves both event ids in the result; no UUID tie-breaker
    # is acceptable because it would invent provenance for an append-only correction.
    warehouse._rows = lambda sql, parameters: [{"event_id": "pending-a"}, {"event_id": "pending-b"}]
    with pytest.raises(LookupError, match="found 2"):
        warehouse.resolve_queue_event_id(_full_row(), KEY)


# ---- _rows() bounded timeout: a stuck BigQuery job must surface a clean error, not hang forever
# or dump a raw traceback (found 2026-08-08 — no timeout was passed to .result() at all, including
# on the live --apply WRITE path through append_replacement) ---------------------------------------

class _FakeTimingOutJob:
    job_id = "job-abc123"

    def __init__(self):
        self.seen_timeout = "unset"

    def result(self, timeout=None):
        self.seen_timeout = timeout
        raise concurrent.futures.TimeoutError()


class _FakeQueryClient:
    def __init__(self, job):
        self.job = job
        self.calls = []

    def query(self, sql, job_config=None):
        self.calls.append((sql, job_config))
        return self.job


def _bare_warehouse(timeout_seconds):
    warehouse = object.__new__(ars.GoogleBigQueryWarehouse)
    warehouse.project = "proj-1"
    # A stub with just enough surface for _rows(): QueryJobConfig only needs to be callable, the
    # real class isn't exercised by this test.
    warehouse.bigquery = types.SimpleNamespace(QueryJobConfig=lambda **kw: kw)
    warehouse.timeout_seconds = timeout_seconds
    return warehouse


def test_rows_passes_configured_timeout_to_result_and_wraps_timeout_error_cleanly():
    job = _FakeTimingOutJob()
    warehouse = _bare_warehouse(timeout_seconds=5)
    warehouse.client = _FakeQueryClient(job)
    with pytest.raises(RuntimeError, match=r"job-abc123 did not finish within 5s") as excinfo:
        warehouse._rows("SELECT 1", [])
    # The bounded value actually reached .result(), not None (which would mean "wait forever" —
    # the exact prior behavior this fix removes), and the raw concurrent.futures.TimeoutError is
    # preserved as the chained cause rather than swallowed.
    assert job.seen_timeout == 5
    assert isinstance(excinfo.value.__cause__, concurrent.futures.TimeoutError)


def test_rows_still_returns_normal_results_when_the_job_finishes_in_time():
    class FakeRow:
        def __init__(self, mapping):
            self._mapping = mapping

        def items(self):
            return self._mapping.items()

    class FakeJob:
        job_id = "job-fine"

        def result(self, timeout=None):
            assert timeout == 5
            return [FakeRow({"event_id": "e1"})]

    warehouse = _bare_warehouse(timeout_seconds=5)
    warehouse.client = _FakeQueryClient(FakeJob())
    assert warehouse._rows("SELECT 1", []) == [{"event_id": "e1"}]


def test_google_bigquery_warehouse_defaults_timeout_to_module_constant(monkeypatch):
    from google.cloud import bigquery as real_bigquery

    class FakeClient:
        def __init__(self, project=None):
            self.project = project

    monkeypatch.setattr(real_bigquery, "Client", FakeClient)
    warehouse = ars.GoogleBigQueryWarehouse("proj-1")
    assert warehouse.timeout_seconds == ars.DEFAULT_BQ_TIMEOUT_SECONDS


def test_google_bigquery_warehouse_accepts_explicit_timeout_override(monkeypatch):
    from google.cloud import bigquery as real_bigquery

    class FakeClient:
        def __init__(self, project=None):
            self.project = project

    monkeypatch.setattr(real_bigquery, "Client", FakeClient)
    warehouse = ars.GoogleBigQueryWarehouse("proj-1", timeout_seconds=17)
    assert warehouse.timeout_seconds == 17


def test_main_repair_apply_passes_timeout_seconds_flag_to_warehouse(tmp_path, monkeypatch):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    captured = {}

    class FakeWarehouse:
        def __init__(self, project, timeout_seconds=None):
            captured["project"] = project
            captured["timeout_seconds"] = timeout_seconds

    monkeypatch.setattr(ars, "GoogleBigQueryWarehouse", FakeWarehouse)
    monkeypatch.setattr(ars, "repair_files", lambda paths, warehouse, apply: [])
    assert ars.main(["repair", "--apply", "--file", str(path), "--timeout-seconds", "17"]) == 0
    assert captured == {"project": ars.PROJECT, "timeout_seconds": 17}


def test_main_repair_defaults_timeout_seconds_when_flag_omitted(tmp_path, monkeypatch):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    path.write_text(BODY, encoding="utf-8")
    captured = {}

    class FakeWarehouse:
        def __init__(self, project, timeout_seconds=None):
            captured["timeout_seconds"] = timeout_seconds

    monkeypatch.setattr(ars, "GoogleBigQueryWarehouse", FakeWarehouse)
    monkeypatch.setattr(ars, "repair_files", lambda paths, warehouse, apply: [])
    assert ars.main(["repair", "--file", str(path)]) == 0
    assert captured["timeout_seconds"] == ars.DEFAULT_BQ_TIMEOUT_SECONDS


def test_tracked_root_review_files_filters_nested_entries(monkeypatch, tmp_path):
    class Completed:
        returncode = 0
        stdout = b"Adversarial_Review_root_attacker.md\0nested/Adversarial_Review_nested_attacker.md\0"
        stderr = b""
    monkeypatch.setattr(ars.subprocess, "run", lambda *args, **kwargs: Completed())
    assert ars.tracked_root_review_files(tmp_path) == [tmp_path / "Adversarial_Review_root_attacker.md"]


def test_write_new_file_requires_new_path(tmp_path):
    output = tmp_path / "review.md"
    ars._write_new_file(output, BODY)
    assert output.read_text(encoding="utf-8") == BODY
    with pytest.raises(FileExistsError):
        ars._write_new_file(output, BODY)


def test_write_new_file_rejects_retired_root_transcript_name(tmp_path):
    output = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    with pytest.raises(ValueError, match="retired root"):
        ars._write_new_file(output, BODY, root=tmp_path)
    assert not output.exists()


def test_repair_files_rejects_multi_target_apply_before_any_repair_call(monkeypatch, tmp_path):
    good = tmp_path / "good.md"
    bad = tmp_path / "bad.md"
    calls = []

    def fake_repair(path, warehouse, apply):
        calls.append((path, apply))
        return ars.RepairResult(path, KEY, "DRY_RUN", "dry run")

    monkeypatch.setattr(ars, "repair_file", fake_repair)
    results = ars.repair_files([good, bad], object(), apply=True)
    assert [result.status for result in results] == ["ERROR", "ERROR"]
    assert calls == []


def test_repair_files_keeps_multi_target_dry_run(monkeypatch, tmp_path):
    one = tmp_path / "one.md"
    two = tmp_path / "two.md"
    calls = []

    def fake_repair(path, warehouse, apply):
        calls.append((path, apply))
        return ars.RepairResult(path, KEY, "DRY_RUN", "ok")

    monkeypatch.setattr(ars, "repair_file", fake_repair)
    results = ars.repair_files([one, two], object(), apply=False)
    assert [result.status for result in results] == ["DRY_RUN", "DRY_RUN"]
    assert calls == [(one, False), (two, False)]


def test_main_export_defaults_to_stdout_and_uses_exact_key(monkeypatch, capsys):
    captured = {}

    def fake_fetch(key, project):
        captured["key"], captured["project"] = key, project
        return _row()
    monkeypatch.setattr(ars, "fetch_review", fake_fetch)
    assert ars.main(["--project", "proj-1", "export", "--review-id", "review-A-1", "--role", "attacker",
                     "--cycle-number", "3"]) == 0
    assert capsys.readouterr().out == BODY
    assert captured == {"key": KEY, "project": "proj-1"}


def test_main_audit_is_nonzero_on_any_non_ok_result(monkeypatch, capsys, tmp_path):
    ok = ars.AuditResult(tmp_path / "one.md", KEY, "OK", "matches")
    bad = ars.AuditResult(tmp_path / "two.md", KEY, "MISMATCH", "differs", "A", "B")
    monkeypatch.setattr(ars, "audit_tracked_files", lambda project: [ok, bad])
    assert ars.main(["audit"]) == 1
    out = capsys.readouterr().out
    assert "1 OK, 1 non-OK, 2 total" in out


def test_main_audit_accepts_explicit_recovered_legacy_file(monkeypatch, capsys, tmp_path):
    path = tmp_path / "Adversarial_Review_review-A-1_attacker.md"
    monkeypatch.setattr(ars, "audit_file", lambda found, project: ars.AuditResult(found, KEY, "OK", "matches"))
    assert ars.main(["audit", "--file", str(path)]) == 0
    assert path.name in capsys.readouterr().out


def test_main_repair_with_no_retired_files_does_not_construct_bigquery_client(monkeypatch, capsys):
    monkeypatch.setattr(ars, "tracked_root_review_files", list)
    monkeypatch.setattr(ars, "GoogleBigQueryWarehouse", lambda project: pytest.fail("client should not be constructed"))
    assert ars.main(["repair"]) == 0
    assert "supply --file" in capsys.readouterr().out


def test_main_repair_rejects_multi_file_apply_before_bigquery_client(monkeypatch, capsys, tmp_path):
    one = tmp_path / "Adversarial_Review_one_attacker.md"
    two = tmp_path / "Adversarial_Review_two_attacker.md"
    monkeypatch.setattr(ars, "GoogleBigQueryWarehouse", lambda project: pytest.fail("client should not be constructed"))
    assert ars.main(["repair", "--apply", "--file", str(one), "--file", str(two)]) == 2
    assert "exactly one" in capsys.readouterr().err
