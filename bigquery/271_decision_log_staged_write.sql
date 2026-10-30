-- 271_decision_log_staged_write.sql (2026-10-29, interactive triage)
-- Project: stock-trading-498512. Apply after 270_decision_log_checked_write.sql.
--
-- THE DEFECT (D1, alert research_screen_call_issuer_output_truncated, 3e8b19b0).
-- The BigQuery MCP tool takes SQL text, never a file. On 2026-10-29 the issuing agent's
-- 85,925-byte and 66,399-byte research-screen CALLs were cut off at ~30-45KB of agent
-- output. A 47,569-byte call landed only after content was cut (b1e61b9c), losing source
-- URLs and release stamps. Live row fields reach 63KB; cutting the screen is not a fix.
--
-- THE CONTROL. scripts/decision_call.py emits files capped at 24,000 characters. Each
-- part carries its own digest and is safe to re-issue; the final call assembles complete
-- arguments and delegates to sp_log_decision_checked for the original full-call digest,
-- JSON storability check, idempotency, write and readback. This table is staging only and
-- is never read by any view. Expiration bounds abandoned parts to 14 days.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.decision_call_parts` (
  call_sha256 STRING NOT NULL,
  arg_name STRING NOT NULL,
  part_no INT64 NOT NULL,
  n_parts INT64 NOT NULL,
  part_sha256 STRING NOT NULL,
  payload STRING NOT NULL,
  staged_ts TIMESTAMP NOT NULL
)
PARTITION BY DATE(staged_ts)
OPTIONS(partition_expiration_days=14, description='Temporary digest-checked decision CALL parts; staging only, not read by views.');

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_stage_decision_part`(
  in_call_sha256 STRING, in_arg_name STRING, in_part_no INT64, in_n_parts INT64,
  in_part_sha256 STRING, in_payload STRING
)
BEGIN
  DECLARE actual_sha256 STRING;
  IF in_call_sha256 IS NULL OR in_arg_name IS NULL OR in_arg_name NOT IN ('body_md', 'fields') THEN
    RAISE USING MESSAGE = 'sp_stage_decision_part: REFUSED, call digest and a valid arg_name are required; nothing was written.';
  END IF;
  IF in_n_parts IS NULL OR in_part_no IS NULL OR in_n_parts < 1
     OR in_part_no < 1 OR in_part_no > in_n_parts THEN
    RAISE USING MESSAGE = 'sp_stage_decision_part: REFUSED, part_no must be in 1..n_parts and n_parts must be positive; nothing was written.';
  END IF;
  IF in_payload IS NULL THEN
    RAISE USING MESSAGE = 'sp_stage_decision_part: REFUSED, payload is NULL; nothing was written.';
  END IF;
  SET actual_sha256 = TO_HEX(SHA256(in_payload));
  IF in_part_sha256 IS NULL OR actual_sha256 != LOWER(in_part_sha256) THEN
    RAISE USING MESSAGE = FORMAT(
      'sp_stage_decision_part: REFUSED, part digest mismatch (expected %s, received %s). Nothing was written; re-issue this part file verbatim, never edit it.',
      IFNULL(in_part_sha256, 'NULL'), actual_sha256);
  END IF;
  IF EXISTS (
    SELECT 1 FROM `stock-trading-498512.ops.decision_call_parts`
    WHERE call_sha256 = LOWER(in_call_sha256) AND arg_name = in_arg_name AND part_no = in_part_no
      AND (part_sha256 != LOWER(in_part_sha256) OR n_parts != in_n_parts)
  ) THEN
    RAISE USING MESSAGE = FORMAT(
      'sp_stage_decision_part: REFUSED, conflicting staged part %s %d; nothing was written.', in_arg_name, in_part_no);
  END IF;
  IF EXISTS (
    SELECT 1 FROM `stock-trading-498512.ops.decision_call_parts`
    WHERE call_sha256 = LOWER(in_call_sha256) AND arg_name = in_arg_name AND part_no = in_part_no
  ) THEN
    SELECT in_call_sha256 AS call_sha256, in_arg_name AS arg_name, in_part_no AS part_no,
      in_n_parts AS n_parts, 'already_present' AS outcome;
    RETURN;
  END IF;
  INSERT INTO `stock-trading-498512.ops.decision_call_parts`
    (call_sha256, arg_name, part_no, n_parts, part_sha256, payload, staged_ts)
  VALUES (LOWER(in_call_sha256), in_arg_name, in_part_no, in_n_parts,
    LOWER(in_part_sha256), in_payload, CURRENT_TIMESTAMP());
  SELECT in_call_sha256 AS call_sha256, in_arg_name AS arg_name, in_part_no AS part_no,
    in_n_parts AS n_parts, 'staged' AS outcome;
END;

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_log_decision_staged`(
  in_entry_date DATE, in_entry_type STRING, in_strategy STRING, in_ticker STRING,
  in_decision STRING, in_conviction STRING, in_conviction_pct NUMERIC,
  in_sub_pattern STRING, in_theater_check STRING, in_title STRING, in_body_md STRING,
  in_fields_json STRING, in_refs ARRAY<STRING>, in_tags ARRAY<STRING>,
  in_superseded_by STRING, in_source_session STRING,
  in_staged_args ARRAY<STRING>, in_expected_sha256 STRING
)
BEGIN
  DECLARE body_value STRING DEFAULT in_body_md;
  DECLARE fields_value STRING DEFAULT in_fields_json;
  DECLARE assembled STRING;
  DECLARE min_parts INT64;
  DECLARE max_parts INT64;
  DECLARE missing_parts STRING;

  IF in_expected_sha256 IS NULL OR in_staged_args IS NULL OR ARRAY_LENGTH(in_staged_args) = 0
     OR EXISTS (SELECT 1 FROM UNNEST(in_staged_args) AS name WHERE name IS NULL OR name NOT IN ('body_md', 'fields'))
     OR ARRAY_LENGTH(in_staged_args) != (SELECT COUNT(DISTINCT name) FROM UNNEST(in_staged_args) AS name) THEN
    RAISE USING MESSAGE = 'sp_log_decision_staged: REFUSED, expected digest and a non-empty, duplicate-free subset of body_md and fields are required.';
  END IF;
  IF ('body_md' IN UNNEST(in_staged_args) AND in_body_md IS NOT NULL)
     OR ('fields' IN UNNEST(in_staged_args) AND in_fields_json IS NOT NULL) THEN
    RAISE USING MESSAGE = 'sp_log_decision_staged: REFUSED, staged arguments must be passed as NULL.';
  END IF;

  FOR staged_arg IN (SELECT name FROM UNNEST(in_staged_args) AS name) DO
    SET (min_parts, max_parts) = (
      SELECT AS STRUCT MIN(n_parts), MAX(n_parts)
      FROM `stock-trading-498512.ops.decision_call_parts`
      WHERE call_sha256 = LOWER(in_expected_sha256) AND arg_name = staged_arg.name);
    IF min_parts IS NULL THEN
      RAISE USING MESSAGE = FORMAT(
        'sp_log_decision_staged: REFUSED, %s has no parts; all part numbers are missing. Issue all its part files then re-issue this call.', staged_arg.name);
    END IF;
    SET missing_parts = (
      SELECT STRING_AGG(CAST(number AS STRING), ', ' ORDER BY number)
      FROM UNNEST(GENERATE_ARRAY(1, max_parts)) AS number
      WHERE NOT EXISTS (
        SELECT 1 FROM `stock-trading-498512.ops.decision_call_parts` AS p
        WHERE p.call_sha256 = LOWER(in_expected_sha256) AND p.arg_name = staged_arg.name AND p.part_no = number));
    IF min_parts != max_parts OR min_parts < 1 OR missing_parts IS NOT NULL OR EXISTS (
      SELECT 1 FROM `stock-trading-498512.ops.decision_call_parts` AS p
      WHERE p.call_sha256 = LOWER(in_expected_sha256) AND p.arg_name = staged_arg.name
        AND (p.part_no < 1 OR p.part_no > max_parts)
    ) THEN
      RAISE USING MESSAGE = FORMAT(
        'sp_log_decision_staged: REFUSED, %s has incomplete or inconsistent parts; missing part numbers: %s. Issue those part files then re-issue this call.',
        staged_arg.name, IFNULL(missing_parts, 'none (inconsistent part metadata)'));
    END IF;
    IF EXISTS (
      SELECT part_no FROM `stock-trading-498512.ops.decision_call_parts`
      WHERE call_sha256 = LOWER(in_expected_sha256) AND arg_name = staged_arg.name
      GROUP BY part_no HAVING COUNT(DISTINCT part_sha256) > 1 OR COUNT(DISTINCT payload) > 1
    ) THEN
      RAISE USING MESSAGE = FORMAT('sp_log_decision_staged: REFUSED, conflicting duplicate parts for %s.', staged_arg.name);
    END IF;
    SET assembled = (
      SELECT STRING_AGG(payload, "" ORDER BY part_no)
      FROM (
        SELECT part_no, ARRAY_AGG(payload LIMIT 1)[OFFSET(0)] AS payload
        FROM `stock-trading-498512.ops.decision_call_parts`
        WHERE call_sha256 = LOWER(in_expected_sha256) AND arg_name = staged_arg.name
        GROUP BY part_no));
    IF staged_arg.name = 'body_md' THEN
      SET body_value = assembled;
    ELSE
      SET fields_value = assembled;
    END IF;
  END FOR;

  CALL `stock-trading-498512.ops.sp_log_decision_checked`(
    in_entry_date, in_entry_type, in_strategy, in_ticker, in_decision, in_conviction, in_conviction_pct,
    in_sub_pattern, in_theater_check, in_title, body_value, fields_value, in_refs, in_tags,
    in_superseded_by, in_source_session, in_expected_sha256);
END;

-- ============================================================================
-- VERIFICATION (read-only, after applying).
-- SELECT table_name FROM `stock-trading-498512.ops.INFORMATION_SCHEMA.TABLES`
-- WHERE table_name = 'decision_call_parts';
-- SELECT routine_name FROM `stock-trading-498512.ops.INFORMATION_SCHEMA.ROUTINES`
-- WHERE routine_name IN ('sp_stage_decision_part', 'sp_log_decision_staged');
