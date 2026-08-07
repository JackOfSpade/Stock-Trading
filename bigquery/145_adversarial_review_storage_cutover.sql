-- Adversarial-review transcript storage cutover (2026-08-07).
--
-- events.adversarial_reviews is the sole durable transcript store.  The former
-- root-level Adversarial_Review_*.md files were a duplicate authoring/handoff
-- surface and are retired by the same changeset as this migration.
--
-- Apply after bigquery/143_adversarial_review_correction_path.sql.  The base
-- table remains append-only: a correction is a complete new row whose
-- superseded_by value names the obsolete event_id.

ALTER TABLE `stock-trading-498512.events.adversarial_reviews`
  ADD COLUMN IF NOT EXISTS content_sha256 STRING OPTIONS (
    description='Lowercase SHA-256 of the exact UTF-8 bytes stored in body_md; populated by ops.sp_write_adversarial_review.'
  ),
  ADD COLUMN IF NOT EXISTS body_bytes INT64 OPTIONS (
    description='BYTE_LENGTH(body_md), recorded at insert time.'
  ),
  ADD COLUMN IF NOT EXISTS source_commit_sha STRING OPTIONS (
    description='Git commit containing the reviewed artifact, when available; NULL means the artifact was intentionally reviewed from an uncommitted snapshot.'
  ),
  ADD COLUMN IF NOT EXISTS queue_event_id STRING OPTIONS (
    description='events.queue_events.event_id of the queue state consumed by this reviewer.'
  ),
  ADD COLUMN IF NOT EXISTS schema_version INT64 OPTIONS (
    description='Transcript storage contract version; version 1 is the BigQuery-only cutover.'
  );

ALTER TABLE `stock-trading-498512.events.adversarial_reviews`
  SET OPTIONS(description='Canonical adversarial attacker/orchestrator/referee transcripts. APPEND-ONLY: never UPDATE/DELETE. New AR_att/AR_orc writes use ops.sp_write_adversarial_review, including a caller-computed SHA-256 checked against the exact stored UTF-8 body. Corrections are complete replacement rows whose superseded_by names the obsolete event_id; readers use state.adversarial_reviews_current.');

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

  ASSERT p_review_id IS NOT NULL AND p_review_id != ''
    AS 'review_id is required';
  ASSERT p_role IN ('attacker', 'orchestrator')
    AS 'role must be attacker or orchestrator';
  ASSERT p_review_date IS NOT NULL
    AS 'review_date is required';
  ASSERT p_cycle_number IS NOT NULL AND p_cycle_number >= 1
    AS 'cycle_number must be a positive integer';
  ASSERT p_artifact_path IS NOT NULL AND p_artifact_path != ''
    AS 'artifact_path is required';
  ASSERT p_body_md IS NOT NULL AND BYTE_LENGTH(p_body_md) > 0
    AS 'body_md must contain the complete transcript';
  ASSERT REGEXP_CONTAINS(normalized_expected_sha256, r'^[0-9a-f]{64}$')
    AS 'expected_sha256 must be a 64-character hexadecimal digest';
  ASSERT actual_sha256 = normalized_expected_sha256
    AS 'body_md SHA-256 does not match the caller-computed canonical UTF-8 digest';
  ASSERT p_queue_event_id IS NOT NULL AND p_queue_event_id != ''
    AS 'queue_event_id is required';
  ASSERT p_source_commit_sha IS NULL
      OR REGEXP_CONTAINS(LOWER(p_source_commit_sha), r'^[0-9a-f]{40}([0-9a-f]{24})?$')
    AS 'source_commit_sha must be NULL, a 40-character SHA-1, or a 64-character SHA-256';

  IF p_superseded_by IS NULL THEN
    ASSERT NOT EXISTS (
      SELECT 1
      FROM `stock-trading-498512.state.adversarial_reviews_current`
      WHERE review_id = p_review_id
        AND role = p_role
        AND cycle_number = p_cycle_number
    ) AS 'an active row already exists for review_id, role, and cycle_number';
  ELSE
    ASSERT (
      SELECT COUNT(*) = 1
      FROM `stock-trading-498512.events.adversarial_reviews`
      WHERE event_id = p_superseded_by
        AND review_id = p_review_id
        AND role = p_role
        AND cycle_number = p_cycle_number
    ) AS 'superseded_by must name exactly one row with the same review_id, role, and cycle_number';
    ASSERT NOT EXISTS (
      SELECT 1
      FROM `stock-trading-498512.events.adversarial_reviews`
      WHERE superseded_by = p_superseded_by
    ) AS 'the obsolete row already has an appended replacement';
  END IF;

  INSERT INTO `stock-trading-498512.events.adversarial_reviews`
    (review_id, review_type, strategy, role, review_date, cycle_number,
     verdict, theater_check, weaknesses, artifact_path, body_md,
     superseded_by, content_sha256, body_bytes, source_commit_sha,
     queue_event_id, schema_version)
  VALUES
    (p_review_id, p_review_type, p_strategy, p_role, p_review_date,
     p_cycle_number, p_verdict, p_theater_check, p_weaknesses,
     p_artifact_path, p_body_md, p_superseded_by, actual_sha256,
     BYTE_LENGTH(p_body_md), LOWER(p_source_commit_sha), p_queue_event_id, 1);

  ASSERT EXISTS (
    SELECT 1
    FROM `stock-trading-498512.state.adversarial_reviews_current`
    WHERE review_id = p_review_id
      AND role = p_role
      AND cycle_number = p_cycle_number
      AND content_sha256 = actual_sha256
      AND body_bytes = BYTE_LENGTH(p_body_md)
  ) AS 'post-write readback verification failed';

  SELECT event_id, review_id, role, cycle_number, content_sha256, body_bytes
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE review_id = p_review_id
    AND role = p_role
    AND cycle_number = p_cycle_number
    AND content_sha256 = actual_sha256
  QUALIFY ROW_NUMBER() OVER (ORDER BY event_ts DESC) = 1;
END;
