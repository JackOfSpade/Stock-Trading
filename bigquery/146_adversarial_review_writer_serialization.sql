-- Adversarial-review writer serialization and JSON-shape repair (2026-08-07).
--
-- Apply after 145_adversarial_review_storage_cutover.sql.  BigQuery permits concurrent
-- append-only INSERT transactions, so 145's read-then-append checks did not serialize writers.
-- This migration adds a deliberately mutable singleton mutex outside events.* and redefines the
-- writer to UPDATE that exact row inside its transaction before it reads or appends a transcript.
--
-- It also performs the one-time repair for the Python JSON-parameter bug: 24 cutover correction rows
-- plus 6 legacy attacker/orchestrator rows stored weaknesses as JSON strings containing JSON arrays.
-- That exceptional type repair is an
-- asserted, explicit append-only migration below; ordinary body corrections may not alter metadata.

CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.adversarial_review_write_mutex` (
  lock_name STRING NOT NULL,
  revision INT64 NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (lock_name) NOT ENFORCED
)
CLUSTER BY lock_name
OPTIONS(description='Singleton transactional mutex for ops.sp_write_adversarial_review. The mutable row serializes check-then-append transcript writes; events.adversarial_reviews itself remains append-only.');

-- Seed before the procedure can use the mutex. Re-application is harmless; if corruption ever creates
-- two rows, the procedure's @@row_count=1 assertion fails closed and its transaction rolls back.
MERGE `stock-trading-498512.ops.adversarial_review_write_mutex` t
USING (SELECT 'adversarial-review-writer' AS lock_name) s
ON t.lock_name = s.lock_name
WHEN NOT MATCHED THEN
  INSERT (lock_name, revision, updated_at) VALUES (s.lock_name, 0, CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_write_adversarial_review`(
  p_review_id STRING,
  p_review_type STRING,
  p_strategy STRING,
  p_role STRING,
  p_review_date DATE,
  p_cycle_number INT64,
  p_verdict STRING,
  p_theater_check STRING,
  p_weaknesses JSON,
  p_artifact_path STRING,
  p_body_md STRING,
  p_expected_sha256 STRING,
  p_source_commit_sha STRING,
  p_queue_event_id STRING,
  p_superseded_by STRING
)
BEGIN
  DECLARE normalized_expected_sha256 STRING DEFAULT LOWER(p_expected_sha256);
  DECLARE actual_sha256 STRING DEFAULT LOWER(TO_HEX(SHA256(p_body_md)));
  DECLARE inserted_event_id STRING DEFAULT GENERATE_UUID();
  DECLARE inserted_event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE mutex_rows INT64;

  ASSERT p_review_id IS NOT NULL AND p_review_id != ''
    AS 'review_id is required';
  -- New referee rows remain generated only by sp_score_cross_model_referee.  This procedure accepts
  -- referee_gemini solely for a complete append-only correction of one already-written referee row.
  ASSERT p_role IN ('attacker', 'orchestrator')
      OR (p_role = 'referee_gemini' AND p_superseded_by IS NOT NULL)
    AS 'role must be attacker/orchestrator, or referee_gemini for a correction';
  ASSERT p_review_date IS NOT NULL
    AS 'review_date is required';
  ASSERT p_cycle_number IS NOT NULL AND p_cycle_number >= 1
    AS 'cycle_number must be a positive integer';
  ASSERT p_role = 'referee_gemini' OR (p_artifact_path IS NOT NULL AND p_artifact_path != '')
    AS 'artifact_path is required for attacker/orchestrator rows';
  ASSERT p_body_md IS NOT NULL AND BYTE_LENGTH(p_body_md) > 0
    AS 'body_md must contain the complete transcript';
  ASSERT REGEXP_CONTAINS(normalized_expected_sha256, r'^[0-9a-f]{64}$')
    AS 'expected_sha256 must be a 64-character hexadecimal digest';
  ASSERT actual_sha256 = normalized_expected_sha256
    AS 'body_md SHA-256 does not match the caller-computed canonical UTF-8 digest';
  ASSERT p_role = 'referee_gemini' OR p_superseded_by IS NOT NULL
      OR (p_queue_event_id IS NOT NULL AND p_queue_event_id != '')
    AS 'queue_event_id is required for a normal attacker/orchestrator write';
  ASSERT p_source_commit_sha IS NULL
      OR REGEXP_CONTAINS(LOWER(p_source_commit_sha), r'^[0-9a-f]{40}([0-9a-f]{24})?$')
    AS 'source_commit_sha must be NULL, a 40-character SHA-1, or a 64-character SHA-256';

  -- Queue transitions are immutable history. A UUID is not provenance unless it is this role's
  -- PENDING_REVIEW transition for the exact review/cycle being written. A normal write cannot
  -- consume a future transition; a correction must preserve a transition no newer than its target.
  IF p_role IN ('attacker', 'orchestrator') AND p_queue_event_id IS NOT NULL THEN
    -- event_id is a declared but NOT ENFORCED primary key. Count the fully-qualified physical rows:
    -- accepting "any matching row exists" would make a duplicate event_id ambiguous provenance.
    ASSERT (
      SELECT COUNT(*) = 1
      FROM `stock-trading-498512.events.queue_events` q
      WHERE q.event_id = p_queue_event_id
        AND q.queue = 'PENDING_REVIEW'
        AND q.item_key = p_review_id
        AND q.status = IF(p_role = 'attacker', 'pending', 'attacker-complete')
        AND COALESCE(SAFE_CAST(JSON_VALUE(q.payload, '$.cycle_number') AS INT64), 1) = p_cycle_number
        AND (
          (p_superseded_by IS NULL AND q.event_ts <= inserted_event_ts)
          OR (p_superseded_by IS NOT NULL AND EXISTS (
            SELECT 1
            FROM `stock-trading-498512.events.adversarial_reviews` target
            WHERE target.event_id = p_superseded_by
              AND q.event_ts <= target.event_ts
          ))
        )
    ) AS 'queue_event_id must name exactly one role-specific non-future PENDING_REVIEW transition for this review/cycle, or one no newer than a correction target';
  END IF;

  BEGIN TRANSACTION;

  -- The same UPDATE is intentionally in every invocation. Unlike append-only INSERTs, simultaneous
  -- UPDATEs of this one mutable row conflict, so only one invocation can perform the following
  -- current-row check plus append at a time. A retry starts from a fresh snapshot and sees the winner.
  UPDATE `stock-trading-498512.ops.adversarial_review_write_mutex`
  SET revision = revision + 1,
      updated_at = CURRENT_TIMESTAMP()
  WHERE lock_name = 'adversarial-review-writer';
  SET mutex_rows = @@row_count;
  ASSERT mutex_rows = 1
    AS 'adversarial-review writer mutex must contain exactly one seeded row';

  IF p_superseded_by IS NULL THEN
    ASSERT p_cycle_number > COALESCE((
      SELECT MAX(cycle_number)
      FROM `stock-trading-498512.state.adversarial_reviews_current`
      WHERE review_id = p_review_id AND role = p_role
    ), 0) AS 'a normal write must use a cycle_number higher than this role\'s current cycle';
    ASSERT NOT EXISTS (
      SELECT 1
      FROM `stock-trading-498512.state.adversarial_reviews_current`
      WHERE review_id = p_review_id
        AND role = p_role
        AND cycle_number = p_cycle_number
    ) AS 'an active row already exists for review_id, role, and cycle_number';
    IF p_role = 'orchestrator' THEN
      ASSERT EXISTS (
        SELECT 1
        FROM `stock-trading-498512.state.adversarial_reviews_current`
        WHERE review_id = p_review_id
          AND role = 'attacker'
          AND cycle_number = p_cycle_number
      ) AS 'an orchestrator write requires a current attacker row at the same review_id and cycle_number';
    END IF;
  ELSE
    -- Body corrections have no authority to rewrite a verdict, review classification, artifact, queue
    -- provenance, or any other semantic field. `queue_event_id IS NOT DISTINCT FROM` below means a
    -- correction may omit queue provenance only when its historical target also has NULL. The
    -- JSON-string type repair is deliberately outside this procedure in the dedicated asserted block.
    ASSERT (
      SELECT COUNT(*) = 1
      FROM `stock-trading-498512.events.adversarial_reviews`
      WHERE event_id = p_superseded_by
        AND review_id = p_review_id
        AND review_type IS NOT DISTINCT FROM p_review_type
        AND strategy IS NOT DISTINCT FROM p_strategy
        AND role = p_role
        AND review_date IS NOT DISTINCT FROM p_review_date
        AND cycle_number = p_cycle_number
        AND verdict IS NOT DISTINCT FROM p_verdict
        AND theater_check IS NOT DISTINCT FROM p_theater_check
        AND TO_JSON_STRING(weaknesses) IS NOT DISTINCT FROM TO_JSON_STRING(p_weaknesses)
        AND artifact_path IS NOT DISTINCT FROM p_artifact_path
        AND LOWER(source_commit_sha) IS NOT DISTINCT FROM LOWER(p_source_commit_sha)
        AND queue_event_id IS NOT DISTINCT FROM p_queue_event_id
    ) AS 'superseded_by must name one row with identical review metadata; corrections may change only body_md';
    ASSERT NOT EXISTS (
      SELECT 1
      FROM `stock-trading-498512.events.adversarial_reviews`
      WHERE superseded_by = p_superseded_by
    ) AS 'the obsolete row already has an appended replacement';
  END IF;

  INSERT INTO `stock-trading-498512.events.adversarial_reviews`
    (event_id, event_ts, review_id, review_type, strategy, role, review_date, cycle_number,
     verdict, theater_check, weaknesses, artifact_path, body_md, superseded_by,
     content_sha256, body_bytes, source_commit_sha, queue_event_id, schema_version)
  VALUES
    (inserted_event_id, inserted_event_ts, p_review_id, p_review_type, p_strategy, p_role,
     p_review_date, p_cycle_number, p_verdict, p_theater_check, p_weaknesses, p_artifact_path,
     p_body_md, p_superseded_by, actual_sha256, BYTE_LENGTH(p_body_md),
     LOWER(p_source_commit_sha), p_queue_event_id, 1);

  ASSERT (
    SELECT COUNT(*) = 1
    FROM `stock-trading-498512.state.adversarial_reviews_current`
    WHERE event_id = inserted_event_id
      AND content_sha256 = actual_sha256
      AND body_bytes = BYTE_LENGTH(p_body_md)
  ) AS 'post-write readback verification failed';

  COMMIT TRANSACTION;

  SELECT event_id, review_id, role, cycle_number, content_sha256, body_bytes
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE event_id = inserted_event_id;
END;

-- 145's Python repair client bound json.dumps(weaknesses) as a JSON parameter. BigQuery consequently
-- stored JSON strings, not JSON arrays. The six pre-cutover rows with the same array-in-a-string shape
-- are normalized in this single audited repair too. The canonical body and semantic/provenance fields
-- are preserved; replacements gain 145 integrity metadata and schema_version=1. This migration appends
-- exactly the 30 full-row replacements needed to restore the JSON type.
BEGIN
DECLARE json_string_target_ids ARRAY<STRING> DEFAULT ARRAY(
  SELECT event_id
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE role IN ('attacker', 'orchestrator')
    AND JSON_TYPE(weaknesses) = 'string'
  ORDER BY event_id
);
DECLARE repair_mutex_rows INT64;

-- A clean re-apply sees zero strings and intentionally performs no append. Any nonzero unexpected
-- population must still be the exact audited 30 rows, never a broadened best-effort conversion.
IF ARRAY_LENGTH(json_string_target_ids) > 0 THEN
  ASSERT ARRAY_LENGTH(json_string_target_ids) = 30
    AS 'expected exactly the 30 known attacker/orchestrator JSON-string rows; inspect before changing this asserted repair';
  ASSERT (
    SELECT COUNT(*) = ARRAY_LENGTH(json_string_target_ids)
    FROM `stock-trading-498512.state.adversarial_reviews_current`
    WHERE event_id IN UNNEST(json_string_target_ids)
      AND role IN ('attacker', 'orchestrator')
      AND JSON_TYPE(weaknesses) = 'string'
      AND JSON_TYPE(SAFE.PARSE_JSON(JSON_VALUE(weaknesses, '$'))) = 'array'
  ) AS 'every targeted JSON string must decode to an array before this migration may repair it';

  BEGIN TRANSACTION;
  UPDATE `stock-trading-498512.ops.adversarial_review_write_mutex`
  SET revision = revision + 1,
      updated_at = CURRENT_TIMESTAMP()
  WHERE lock_name = 'adversarial-review-writer';
  SET repair_mutex_rows = @@row_count;
  ASSERT repair_mutex_rows = 1
    AS 'adversarial-review writer mutex must contain exactly one seeded row';

  INSERT INTO `stock-trading-498512.events.adversarial_reviews`
    (event_id, event_ts, review_id, review_type, strategy, role, review_date, cycle_number,
     verdict, theater_check, weaknesses, artifact_path, body_md, superseded_by,
     content_sha256, body_bytes, source_commit_sha, queue_event_id, schema_version)
  SELECT
    GENERATE_UUID(), CURRENT_TIMESTAMP(), review_id, review_type, strategy, role, review_date,
    cycle_number, verdict, theater_check,
    SAFE.PARSE_JSON(JSON_VALUE(weaknesses, '$')),
    artifact_path, body_md, event_id, LOWER(TO_HEX(SHA256(body_md))), BYTE_LENGTH(body_md),
    source_commit_sha, queue_event_id, 1
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE event_id IN UNNEST(json_string_target_ids);

  ASSERT (
    SELECT COUNT(*) = ARRAY_LENGTH(json_string_target_ids)
    FROM `stock-trading-498512.state.adversarial_reviews_current`
    WHERE superseded_by IN UNNEST(json_string_target_ids)
      AND JSON_TYPE(weaknesses) = 'array'
      AND content_sha256 = LOWER(TO_HEX(SHA256(body_md)))
      AND body_bytes = BYTE_LENGTH(body_md)
  ) AS 'JSON type repair did not append exactly one verified array-shaped replacement per target';
  COMMIT TRANSACTION;
END IF;
ASSERT NOT EXISTS (
  SELECT 1
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE role IN ('attacker', 'orchestrator')
    AND JSON_TYPE(weaknesses) = 'string'
) AS 'a current attacker/orchestrator transcript still has JSON-string weaknesses after the asserted repair';
END;
