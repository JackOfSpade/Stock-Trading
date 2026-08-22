#!/usr/bin/env python3
"""Export or verify canonical adversarial-review transcripts without creating Git artifacts.

The durable transcript store is ``state.adversarial_reviews_current``.  This tool provides the two
small operational affordances that the former root-level ``Adversarial_Review_*.md`` copies offered:

* ``export`` retrieves one exact current review (review id, role, and cycle number) to stdout, or to
  an explicitly named new file.
* ``audit`` compares every tracked *root-level* legacy review file (or an explicit recovered file)
  against its exact current BigQuery row using the id/cycle metadata inside the file and its role in
  the filename.
* ``repair`` prepares (or, only with ``--apply``, appends) a complete replacement for mismatched
  legacy transcripts through ``ops.sp_write_adversarial_review``.

``audit`` never changes files or BigQuery. ``repair`` is dry-run by default and uses parameterized
google-cloud-bigquery queries exclusively; it never shells out or interpolates transcript data into
SQL. ``export`` only writes when ``--output`` is explicitly supplied, and refuses to overwrite a file.

Examples:
  python scripts/adversarial_review_storage.py export \
      --review-id premortem-A-2026-a3 --role attacker --cycle-number 8
  python scripts/adversarial_review_storage.py audit
  python scripts/adversarial_review_storage.py audit --file /safe/export/Adversarial_Review_x_attacker.md
  python scripts/adversarial_review_storage.py repair              # read-only plan
  python scripts/adversarial_review_storage.py repair --file /safe/export/Adversarial_Review_x_attacker.md
  python scripts/adversarial_review_storage.py repair --apply --file /safe/export/Adversarial_Review_x_attacker.md
"""
import argparse
import concurrent.futures
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.bq_json import run_bq_query


PROJECT = os.environ.get("BQ_PROJECT", "stock-trading-498512")
# GoogleBigQueryWarehouse._rows() used to call .result() with no timeout at all, so a stuck
# BigQuery job — including on the live --apply WRITE path (append_replacement) — hung a repair
# forever with no operator signal to distinguish "still running" from "wedged" (found 2026-08-08).
# Overridable like BQ_PROJECT above (env), and per-invocation via `repair --timeout-seconds`.
DEFAULT_BQ_TIMEOUT_SECONDS = int(os.environ.get("BQ_QUERY_TIMEOUT_SECONDS", "300"))
ROOT = Path(__file__).resolve().parent.parent
FILENAME = re.compile(r"^Adversarial_Review_(?P<review_id>.+)_(?P<role>attacker|orchestrator)\.md$")
# Attacker artifacts use the machine-oriented names; older orchestrator artifacts use title-cased
# prose labels and sometimes put the review id only in the title/filename.  The filename remains the
# durable identity in both forms, while cycle metadata remains mandatory for an exact row lookup.
METADATA = re.compile(r"^- \*\*(?P<name>id|cycle_number|Cycle number):\*\*\s*(?P<value>\S(?:.*?\S)?)\s*$", re.MULTILINE)
CYCLE_VALUE = re.compile(r"^(?P<cycle>[1-9][0-9]*)(?:\s*\([^\r\n]*\))?$")
SAFE_REVIEW_ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._:-]*$")
SAFE_ROLE = re.compile(r"^[a-z][a-z0-9_]*$")
SAFE_PROJECT = re.compile(r"^[A-Za-z0-9][A-Za-z0-9-]*$")


@dataclass(frozen=True)
class ReviewKey:
    review_id: str
    role: str
    cycle_number: int


@dataclass(frozen=True)
class AuditResult:
    path: Path
    key: ReviewKey | None
    status: str
    detail: str
    local_sha256: str | None = None
    warehouse_sha256: str | None = None


@dataclass(frozen=True)
class RepairResult:
    path: Path
    key: ReviewKey | None
    status: str
    detail: str
    obsolete_event_id: str | None = None
    replacement_event_id: str | None = None


def _repair_role_status(role):
    """The exact PENDING_REVIEW transition consumed by each reviewer role."""
    if role == "attacker":
        return "pending"
    if role == "orchestrator":
        return "attacker-complete"
    raise ValueError(f"repair supports attacker/orchestrator roles only, not {role!r}")


def _validate_key(review_id, role, cycle_number):
    """Return a validated ReviewKey, keeping interpolated SELECT literals deliberately narrow."""
    if not isinstance(review_id, str) or not SAFE_REVIEW_ID.fullmatch(review_id):
        raise ValueError("review_id must contain only letters, digits, dot, underscore, colon, or hyphen")
    if not isinstance(role, str) or not SAFE_ROLE.fullmatch(role):
        raise ValueError("role must be lowercase letters, digits, or underscore")
    if isinstance(cycle_number, bool) or not isinstance(cycle_number, int) or cycle_number < 1:
        raise ValueError("cycle_number must be a positive integer")
    return ReviewKey(review_id=review_id, role=role, cycle_number=cycle_number)


def _validate_project(project):
    if not isinstance(project, str) or not SAFE_PROJECT.fullmatch(project):
        raise ValueError("project must be a valid BigQuery project id")
    return project


class GoogleBigQueryWarehouse:
    """Parameterized BigQuery access for repair operations."""

    def __init__(self, project, timeout_seconds=DEFAULT_BQ_TIMEOUT_SECONDS):
        _validate_project(project)
        try:
            from google.cloud import bigquery
        except ImportError as exc:  # pragma: no cover - operator environment only
            raise RuntimeError("repair requires google-cloud-bigquery") from exc
        self.project = project
        self.bigquery = bigquery
        self.client = bigquery.Client(project=project)
        self.timeout_seconds = timeout_seconds

    def _rows(self, sql, parameters):
        config = self.bigquery.QueryJobConfig(query_parameters=parameters)
        job = self.client.query(sql, job_config=config)
        try:
            result = job.result(timeout=self.timeout_seconds)
        except concurrent.futures.TimeoutError as exc:
            # .result() with no timeout (the prior behavior) waits forever on a stuck job — on the
            # live --apply WRITE path (append_replacement) that leaves an operator staring at a
            # blocked terminal with no way to tell "still running" from "wedged" (2026-08-08). Turn
            # the client library's bare TimeoutError (nothing but a job id) into the same clean,
            # actionable-message shape every other client/query failure in this file surfaces (see
            # repair_file's BLE001-annotated catches below) instead of a raw traceback.
            raise RuntimeError(
                f"BigQuery job {job.job_id} did not finish within {self.timeout_seconds}s "
                "(override with repair --timeout-seconds or the BQ_QUERY_TIMEOUT_SECONDS env var)"
            ) from exc
        return [dict(row.items()) for row in result]

    def _scalar(self, name, type_, value):
        return self.bigquery.ScalarQueryParameter(name, type_, value)

    def fetch_current_full(self, key):
        """Read exactly the effective row and every procedure-preserved metadata field."""
        sql = f"""
SELECT event_id, event_ts, review_id, review_type, strategy, role, review_date, cycle_number,
       verdict, theater_check, weaknesses, artifact_path, body_md, source_commit_sha, queue_event_id,
       content_sha256, body_bytes, TO_HEX(SHA256(body_md)) AS body_sha256
FROM `{self.project}.state.adversarial_reviews_current`
WHERE review_id = @review_id
  AND role = @role
  AND cycle_number = @cycle_number
""".strip()
        parameters = [
            self._scalar("review_id", "STRING", key.review_id),
            self._scalar("role", "STRING", key.role),
            self._scalar("cycle_number", "INT64", key.cycle_number),
        ]
        return self._rows(sql, parameters)

    def resolve_queue_event_id(self, row, key):
        """Return the one queue transition this role consumed, never a guessed UUID."""
        status = _repair_role_status(key.role)
        existing = row.get("queue_event_id")
        if existing:
            sql = f"""
SELECT event_id
FROM `{self.project}.events.queue_events`
WHERE event_id = @queue_event_id
  AND queue = 'PENDING_REVIEW'
  AND item_key = @review_id
  AND status = @status
  AND event_ts <= @review_event_ts
  AND COALESCE(SAFE_CAST(JSON_VALUE(payload, '$.cycle_number') AS INT64), 1) = @cycle_number
""".strip()
            parameters = [
                self._scalar("queue_event_id", "STRING", existing),
                self._scalar("review_id", "STRING", key.review_id),
                self._scalar("status", "STRING", status),
                self._scalar("review_event_ts", "TIMESTAMP", row["event_ts"]),
                self._scalar("cycle_number", "INT64", key.cycle_number),
            ]
        else:
            # Legacy rows predate queue_event_id. Queue state is latest-wins, so select only the
            # newest matching transition before the review write; an equal-timestamp tie is still
            # ambiguous and therefore fails below rather than being broken by an arbitrary UUID.
            sql = f"""
WITH candidates AS (
  SELECT event_id, event_ts
  FROM `{self.project}.events.queue_events`
  WHERE queue = 'PENDING_REVIEW'
    AND item_key = @review_id
    AND status = @status
    AND event_ts <= @review_event_ts
    AND COALESCE(SAFE_CAST(JSON_VALUE(payload, '$.cycle_number') AS INT64), 1) = @cycle_number
)
SELECT event_id
FROM candidates
WHERE event_ts = (SELECT MAX(event_ts) FROM candidates)
""".strip()
            parameters = [
                self._scalar("review_id", "STRING", key.review_id),
                self._scalar("status", "STRING", status),
                self._scalar("review_event_ts", "TIMESTAMP", row["event_ts"]),
                self._scalar("cycle_number", "INT64", key.cycle_number),
            ]
        rows = self._rows(sql, parameters)
        if len(rows) != 1 or not isinstance(rows[0].get("event_id"), str) or not rows[0]["event_id"]:
            source = "stored queue_event_id" if existing else "legacy queue transition"
            raise LookupError(
                f"expected exactly one valid {source} for {key.review_id}/{key.role}/cycle "
                f"{key.cycle_number}; found {len(rows)}"
            )
        return rows[0]["event_id"]

    def append_replacement(self, row, key, body_md, expected_sha256, queue_event_id):
        """Call the canonical migration-146 append-only writer with typed parameters, never SQL literals."""
        weaknesses = row["weaknesses"]
        if weaknesses is not None:
            if isinstance(weaknesses, str):
                weaknesses = json.loads(weaknesses)
            # JSON query parameters take a Python JSON value.  Passing json.dumps(...) here would
            # bind an object/array as a JSON *string*, silently changing the column's type on repair.
            try:
                json.dumps(weaknesses, ensure_ascii=False, separators=(",", ":"))
            except (TypeError, ValueError) as exc:
                raise ValueError("weaknesses is not JSON-serializable") from exc
        sql = f"""
CALL `{self.project}.ops.sp_write_adversarial_review`(
  @p_review_id, @p_review_type, @p_strategy, @p_role, @p_review_date, @p_cycle_number,
  @p_verdict, @p_theater_check, @p_weaknesses, @p_artifact_path, @p_body_md,
  @p_expected_sha256, @p_source_commit_sha, @p_queue_event_id, @p_superseded_by
)
""".strip()
        parameters = [
            self._scalar("p_review_id", "STRING", key.review_id),
            self._scalar("p_review_type", "STRING", row["review_type"]),
            self._scalar("p_strategy", "STRING", row["strategy"]),
            self._scalar("p_role", "STRING", key.role),
            self._scalar("p_review_date", "DATE", row["review_date"]),
            self._scalar("p_cycle_number", "INT64", key.cycle_number),
            self._scalar("p_verdict", "STRING", row["verdict"]),
            self._scalar("p_theater_check", "STRING", row["theater_check"]),
            self._scalar("p_weaknesses", "JSON", weaknesses),
            self._scalar("p_artifact_path", "STRING", row["artifact_path"]),
            self._scalar("p_body_md", "STRING", body_md),
            self._scalar("p_expected_sha256", "STRING", expected_sha256),
            self._scalar("p_source_commit_sha", "STRING", row["source_commit_sha"]),
            self._scalar("p_queue_event_id", "STRING", queue_event_id),
            self._scalar("p_superseded_by", "STRING", row["event_id"]),
        ]
        rows = self._rows(sql, parameters)
        if len(rows) != 1 or not isinstance(rows[0].get("event_id"), str) or not rows[0]["event_id"]:
            raise RuntimeError(f"append procedure returned {len(rows)} rows instead of one replacement event_id")
        return rows[0]["event_id"]


def bq(sql, project):
    """Run a read-only BigQuery SELECT; a separate wrapper makes offline tests straightforward."""
    return run_bq_query(sql, project, max_rows=2)


def review_query(key, project):
    """SQL for an exact current row.  Callers reject 0 or >1 rows rather than choosing silently."""
    _validate_project(project)
    key = _validate_key(key.review_id, key.role, key.cycle_number)
    return f"""
SELECT review_id, role, cycle_number, body_md, TO_HEX(SHA256(body_md)) AS body_sha256
FROM `{project}.state.adversarial_reviews_current`
WHERE review_id = '{key.review_id}'
  AND role = '{key.role}'
  AND cycle_number = {key.cycle_number}
""".strip()


def fetch_review(key, project=PROJECT):
    """Fetch exactly one non-superseded row, or raise a descriptive error without guessing a row."""
    key = _validate_key(key.review_id, key.role, key.cycle_number)
    rows = bq(review_query(key, project), project)
    if len(rows) != 1:
        raise LookupError(f"expected exactly one current row for {key.review_id}/{key.role}/cycle {key.cycle_number}; found {len(rows)}")
    row = rows[0]
    required = ("review_id", "role", "cycle_number", "body_md", "body_sha256")
    missing = [name for name in required if name not in row]
    if missing:
        raise ValueError(f"BigQuery row is missing required column(s): {', '.join(missing)}")
    row_key = _validate_key(row["review_id"], row["role"], int(row["cycle_number"]))
    if row_key != key:
        raise ValueError(f"BigQuery returned the wrong row: {row_key!r}, expected {key!r}")
    if not isinstance(row["body_md"], str):
        raise ValueError("BigQuery row has NULL or non-string body_md")
    if not isinstance(row["body_sha256"], str) or not re.fullmatch(r"[0-9A-Fa-f]{64}", row["body_sha256"]):
        raise ValueError("BigQuery row has an invalid body_sha256")
    # Verify the warehouse-provided hash too.  It makes an unexpected CLI/schema coercion loud before
    # export, and pins the UTF-8 convention shared with local file hashing below.
    calculated = hashlib.sha256(row["body_md"].encode("utf-8")).hexdigest().upper()
    if calculated != row["body_sha256"].upper():
        raise ValueError("BigQuery body_md does not match its reported SHA256")
    return row


def parse_legacy_review(path):
    """Parse legacy filename identity plus mandatory in-file cycle metadata.

    ``id`` is optional because the original orchestrator format placed it in the title and canonical
    filename instead.  When present, it is still an integrity assertion and must agree with that
    filename.  ``cycle_number`` and its legacy prose spelling ``Cycle number`` are equivalent; an
    explanatory parenthetical after the integer is allowed in the latter format.
    """
    path = Path(path)
    match = FILENAME.fullmatch(path.name)
    if not match:
        raise ValueError("filename must be Adversarial_Review_<id>_<attacker|orchestrator>.md")
    # Path.read_text() uses universal-newline translation, which would turn a canonical CRLF body
    # into LF before its audit hash or repair write.  A decoded valid UTF-8 string round-trips to
    # precisely these bytes, including CRLF and a UTF-8 BOM.
    text = path.read_bytes().decode("utf-8")
    fields = {}
    for metadata in METADATA.finditer(text):
        name, value = metadata.group("name"), metadata.group("value")
        if name == "Cycle number":
            name = "cycle_number"
        if name in fields:
            raise ValueError(f"duplicate {name} metadata")
        fields[name] = value
    if "cycle_number" not in fields:
        raise ValueError("missing cycle_number metadata")
    cycle_match = CYCLE_VALUE.fullmatch(fields["cycle_number"])
    if not cycle_match:
        raise ValueError("cycle_number metadata must begin with a positive integer, optionally followed by a parenthetical note")
    cycle_number = int(cycle_match.group("cycle"))
    filename_id = match.group("review_id")
    metadata_id = fields.get("id")
    if metadata_id is not None and metadata_id != filename_id:
        raise ValueError(f"filename id {filename_id!r} does not match metadata id {metadata_id!r}")
    key = _validate_key(filename_id, match.group("role"), cycle_number)
    return key, text


def tracked_root_review_files(root=ROOT):
    """Return only tracked root-level legacy reviews; never sweep untracked runtime files."""
    completed = subprocess.run(
        ["git", "-C", str(root), "ls-files", "-z", "--", "Adversarial_Review_*.md"],
        capture_output=True,
        check=False,
    )
    if completed.returncode:
        detail = completed.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(detail or "git ls-files failed")
    files = []
    for name in completed.stdout.decode("utf-8", errors="strict").split("\0"):
        if not name:
            continue
        relative = Path(name)
        if relative.parent == Path("."):
            files.append(Path(root) / relative)
    return sorted(files)


def audit_file(path, project=PROJECT):
    """Compare one legacy Markdown body to its exact canonical BigQuery row."""
    path = Path(path)
    try:
        key, body = parse_legacy_review(path)
        local_sha256 = hashlib.sha256(body.encode("utf-8")).hexdigest().upper()
    except (OSError, UnicodeError, ValueError) as exc:
        return AuditResult(path, None, "INVALID", str(exc))
    try:
        row = fetch_review(key, project)
    except LookupError as exc:
        return AuditResult(path, key, "MISSING", str(exc), local_sha256=local_sha256)
    except Exception as exc:  # noqa: BLE001 - a query/auth failure is neither a missing review nor a safe clean audit
        return AuditResult(path, key, "ERROR", str(exc), local_sha256=local_sha256)
    warehouse_sha256 = row["body_sha256"].upper()
    if local_sha256 != warehouse_sha256:
        return AuditResult(path, key, "MISMATCH", "UTF-8 SHA256 differs from canonical body_md",
                           local_sha256, warehouse_sha256)
    return AuditResult(path, key, "OK", "UTF-8 SHA256 matches canonical body_md", local_sha256, warehouse_sha256)


def audit_tracked_files(root=ROOT, project=PROJECT):
    return [audit_file(path, project) for path in tracked_root_review_files(root)]


_FULL_ROW_REQUIRED = (
    "event_id", "event_ts", "review_id", "review_type", "strategy", "role", "review_date",
    "cycle_number", "verdict", "theater_check", "weaknesses", "artifact_path", "body_md",
    "source_commit_sha", "queue_event_id", "content_sha256", "body_bytes", "body_sha256",
)


def _fetch_one_current_full(warehouse, key):
    rows = warehouse.fetch_current_full(key)
    if len(rows) != 1:
        raise LookupError(
            f"expected exactly one current row for {key.review_id}/{key.role}/cycle {key.cycle_number}; "
            f"found {len(rows)}"
        )
    row = rows[0]
    missing = [name for name in _FULL_ROW_REQUIRED if name not in row]
    if missing:
        raise ValueError(f"BigQuery row is missing required column(s): {', '.join(missing)}")
    row_key = _validate_key(row["review_id"], row["role"], int(row["cycle_number"]))
    if row_key != key:
        raise ValueError(f"BigQuery returned the wrong row: {row_key!r}, expected {key!r}")
    if not isinstance(row["event_id"], str) or not row["event_id"]:
        raise ValueError("BigQuery row has no event_id")
    if not isinstance(row["body_md"], str):
        raise ValueError("BigQuery row has NULL or non-string body_md")
    calculated = hashlib.sha256(row["body_md"].encode("utf-8")).hexdigest().lower()
    if not isinstance(row["body_sha256"], str) or calculated != row["body_sha256"].lower():
        raise ValueError("BigQuery body_md does not match its reported SHA256")
    return row


def _body_matches_local(row, local_sha256, local_bytes):
    """True when the effective transcript is byte-for-byte the legacy canonical body."""
    return (
        row["body_sha256"].lower() == local_sha256
        and row["body_md"].encode("utf-8") == local_bytes
    )


def _postwrite_matches_local(row, local_sha256, local_bytes):
    """The stricter migration-146 verification required only for a newly appended replacement."""
    return (
        _body_matches_local(row, local_sha256, local_bytes)
        and row["content_sha256"] is not None
        and row["content_sha256"].lower() == local_sha256
        and row["body_bytes"] == len(local_bytes)
    )


def repair_file(path, warehouse, apply=False):
    """Plan or append one full-body correction; malformed/ambiguous state always stops safely."""
    path = Path(path)
    try:
        key, local_body = parse_legacy_review(path)
        local_bytes = local_body.encode("utf-8")
        local_sha256 = hashlib.sha256(local_bytes).hexdigest().lower()
        current = _fetch_one_current_full(warehouse, key)
    except Exception as exc:  # noqa: BLE001 - a repair must report any client/query failure as non-actionable
        return RepairResult(path, None, "ERROR", str(exc))

    if _body_matches_local(current, local_sha256, local_bytes):
        return RepairResult(path, key, "NOOP", "canonical body already matches (legacy nullable metadata preserved)", current["event_id"])
    try:
        queue_event_id = warehouse.resolve_queue_event_id(current, key)
    except Exception as exc:  # noqa: BLE001 - ambiguous or inaccessible provenance must stop the repair
        return RepairResult(path, key, "ERROR", f"queue provenance not resolved: {exc}", current["event_id"])
    if not apply:
        return RepairResult(
            path, key, "DRY_RUN",
            f"would append a full-body replacement using queue_event_id={queue_event_id}",
            current["event_id"],
        )

    # THE APPEND AND THE POST-WRITE RE-READ GET SEPARATE try BLOCKS (quality pass 2026-08-22).
    # They used to share one, so a failure of the RE-READ — after append_replacement had already
    # durably committed the new row server-side — was reported as an undifferentiated ERROR
    # carrying only the PRE-write (now obsolete) event_id, with `replacement_event_id` silently
    # dropped even though it was sitting in scope. On the one code path that talks to live
    # BigQuery during a delicate manual `--apply` recovery, that told the operator nothing about a
    # write that actually landed. (Retrying is safe — the NOOP self-heal branch below makes it
    # idempotent — so this was a misreport, not data loss, but a misreport at exactly the wrong
    # moment.) Splitting the blocks also keeps the idempotent-race handling where it belongs: that
    # branch is only meaningful when the APPEND itself was rejected.
    try:
        replacement_event_id = warehouse.append_replacement(current, key, local_body, local_sha256, queue_event_id)
    except Exception as exc:  # noqa: BLE001 - re-read below handles only the idempotent-race success case
        # A competing repair can make the procedure reject our obsolete event. Re-read once: a now-
        # matching current row is a successful idempotent outcome, anything else remains an error.
        try:
            reread = _fetch_one_current_full(warehouse, key)
            if _body_matches_local(reread, local_sha256, local_bytes):
                return RepairResult(path, key, "NOOP", "a concurrent or prior repair already matches", reread["event_id"])
        except Exception:  # noqa: BLE001 - retain the original procedure failure as the useful error
            pass
        return RepairResult(path, key, "ERROR", str(exc), current["event_id"])

    try:
        current = _fetch_one_current_full(warehouse, key)
    except Exception as exc:  # noqa: BLE001 - the write LANDED; report it rather than losing the id
        return RepairResult(
            path, key, "ERROR",
            f"append_replacement SUCCEEDED but the post-write re-read failed, so this run could not "
            f"verify it: {exc}. The replacement event_id is reported below — re-running the repair is "
            f"safe and idempotent.",
            current["event_id"], replacement_event_id)
    if current["event_id"] != replacement_event_id:
        return RepairResult(path, key, "ERROR", "post-write current row is not the procedure-returned replacement",
                            current["event_id"], replacement_event_id)
    if not _postwrite_matches_local(current, local_sha256, local_bytes):
        return RepairResult(path, key, "ERROR", "post-write body/hash/byte verification failed",
                            current["event_id"], replacement_event_id)
    return RepairResult(path, key, "APPLIED", "append-only replacement passed exact post-write verification",
                        None, replacement_event_id)


def repair_files(paths, warehouse, apply=False):
    """Repair files, permitting append-only apply for exactly one target.

    BigQuery cannot roll back an already committed append, and state can change after a preflight.
    A multi-file apply could therefore still leave earlier writes committed when a later target
    fails.  Keep multi-file dry-runs useful, but require one target per ``--apply`` invocation.
    """
    paths = list(paths)
    if not apply:
        return [repair_file(path, warehouse, apply=False) for path in paths]
    if len(paths) != 1:
        return [
            RepairResult(path, None, "ERROR", "--apply requires exactly one --file target; run a multi-file dry-run first")
            for path in paths
        ]
    return [repair_file(paths[0], warehouse, apply=True)]


def _print_audit_result(result):
    key = "?" if result.key is None else f"{result.key.review_id}/{result.key.role}/cycle {result.key.cycle_number}"
    print(f"{result.status}: {result.path.name} ({key}) — {result.detail}")
    if result.status == "MISMATCH":
        print(f"  local={result.local_sha256}\n  warehouse={result.warehouse_sha256}")


def _print_repair_result(result):
    key = "?" if result.key is None else f"{result.key.review_id}/{result.key.role}/cycle {result.key.cycle_number}"
    print(f"{result.status}: {result.path.name} ({key}) — {result.detail}")
    if result.obsolete_event_id:
        print(f"  obsolete_event_id={result.obsolete_event_id}")
    if result.replacement_event_id:
        print(f"  replacement_event_id={result.replacement_event_id}")


def _write_new_file(path, body, root=ROOT):
    path = Path(path)
    if not path.parent.is_dir():
        raise ValueError(f"output directory does not exist: {path.parent}")
    resolved_path = path.resolve(strict=False)
    resolved_root = Path(root).resolve(strict=False)
    if resolved_path.parent == resolved_root and FILENAME.fullmatch(resolved_path.name):
        raise ValueError(
            "refusing to recreate a retired root Adversarial_Review_*.md transcript; "
            "choose an explicit non-root output directory"
        )
    # Exclusive create is deliberate: an export command must not clobber a user file or a legacy copy.
    with path.open("x", encoding="utf-8", newline="") as handle:
        handle.write(body)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project", default=PROJECT, help="BigQuery project (default: %(default)s)")
    commands = parser.add_subparsers(dest="command", required=True)
    export = commands.add_parser("export", help="print one canonical body, or write it to a new explicit path")
    export.add_argument("--review-id", required=True)
    export.add_argument("--role", required=True)
    export.add_argument("--cycle-number", required=True, type=int)
    export.add_argument("--output", type=Path, help="new file to create; stdout when omitted")
    audit = commands.add_parser("audit", help="hash-audit tracked root or explicit legacy review files")
    audit.add_argument("--file", action="append", type=Path,
                       help="legacy file to audit (repeatable; use after retirement/recovery)")
    repair = commands.add_parser("repair", help="dry-run or append full-body corrections for legacy transcript mismatches")
    repair.add_argument("--file", action="append", type=Path,
                        help="legacy file to repair (repeatable for dry-run; default is every tracked root review file)")
    repair.add_argument("--apply", action="store_true", help="append one replacement; without this flag repair is read-only")
    repair.add_argument("--timeout-seconds", type=int, default=DEFAULT_BQ_TIMEOUT_SECONDS,
                        help="abort a stuck BigQuery job (query or --apply write) after this many "
                             "seconds instead of hanging forever (default: %(default)s; also settable "
                             "via BQ_QUERY_TIMEOUT_SECONDS)")
    args = parser.parse_args(argv)

    try:
        if args.command == "export":
            row = fetch_review(ReviewKey(args.review_id, args.role, args.cycle_number), args.project)
            if args.output is None:
                sys.stdout.write(row["body_md"])
            else:
                _write_new_file(args.output, row["body_md"])
                print(f"EXPORTED: {args.output}", file=sys.stderr)
            return 0

        if args.command == "repair":
            paths = args.file if args.file else tracked_root_review_files()
            if not paths:
                print("REPAIR: no tracked root Adversarial_Review_*.md files; supply --file for a recovered legacy transcript")
                return 0
            if args.apply and len(paths) != 1:
                print("ERROR: repair --apply requires exactly one --file target; run a multi-file dry-run first", file=sys.stderr)
                return 2
            warehouse = GoogleBigQueryWarehouse(args.project, timeout_seconds=args.timeout_seconds)
            results = repair_files(paths, warehouse, args.apply)
            for result in results:
                _print_repair_result(result)
            failures = [result for result in results if result.status == "ERROR"]
            print(f"REPAIR: {len(results) - len(failures)} planned/applied/no-op, {len(failures)} error, {len(results)} total")
            return 1 if failures else 0

        results = ([audit_file(path, args.project) for path in args.file]
                   if args.file else audit_tracked_files(project=args.project))
        if not results:
            print("AUDIT: no tracked root Adversarial_Review_*.md files; supply --file for a recovered legacy transcript")
            return 0
        for result in results:
            _print_audit_result(result)
        failed = [result for result in results if result.status != "OK"]
        print(f"AUDIT: {len(results) - len(failed)} OK, {len(failed)} non-OK, {len(results)} total")
        return 1 if failed else 0
    except Exception as exc:  # noqa: BLE001 - CLI must fail closed on client/auth/query errors
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
