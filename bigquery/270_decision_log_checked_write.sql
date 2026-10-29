-- 270_decision_log_checked_write.sql (2026-10-29, interactive triage)
-- Project: stock-trading-498512. Apply after 269_owner_confirmation_pending_age.sql.
--
-- NEW: ops.sp_log_decision_checked -- a digest-checked, idempotent front door to ops.sp_log_decision
-- for decision_log rows whose arguments are generated rather than composed in the call (D1's
-- research-screen rows above all). ops.sp_log_decision itself is UNCHANGED: every existing caller keeps
-- its signature and behaviour, and this procedure writes through it, so the conviction_pct guard and the
-- embedding step still run on exactly one code path.
--
-- THE DEFECT (alert decision_log_large_call_retyped_in_transit, D1 2026-10-28). The BigQuery MCP tool
-- takes SQL text, never a file, so a ~50KB CALL is re-typed token by token by whichever agent issues it.
-- D1's issuing sub-agent landed two transcription defects in research-screen row 72e9607d (a fanout
-- date and a dropped legend key). Nothing caught it in-write: sp_log_decision checks no digest, and it
-- stores SAFE.PARSE_JSON(in_fields_json), so damage that breaks the JSON (a dropped brace) would not
-- even fail -- it would land fields = NULL silently. D1 found it only by an improvised per-key SHA-256
-- readback and replaced the row append-only (c8a50e56). The paper-book rows were closed against the same
-- class on 2026-10-21 (scripts/paper_book.py, ops.alerts 5638e932); decision_log writes were not.
--
-- THE CONTROL. scripts/decision_call.py generates the CALL from a saved JSON file, in printable ASCII,
-- with in_expected_sha256 = SHA-256 of the 16 arguments as it rendered them. This procedure recomputes
-- that digest from what BigQuery RECEIVED and REFUSES (RAISE, nothing written) on a mismatch, so a call
-- damaged in transit is re-issued, never repaired. The rendering is pinned in decision_call.py's header
-- and was reproduced by BigQuery on 2026-10-29 (tests/test_decision_call.py pins that vector).
--
-- ALSO REFUSED: fields that do not parse as a JSON object under PARSE_JSON's default exact mode. The
-- digest proves the text arrived intact; this proves the intact text is storable, instead of letting
-- sp_log_decision's SAFE.PARSE_JSON store NULL.
--
-- DIGEST TAG + IDEMPOTENT. The row is written with tag 'sha256:<digest>' appended to the caller's tags,
-- so the stored row names the exact arguments it came from. A re-issue after a lost response finds that
-- tag and returns the landed entry_id with outcome = 'already_present' instead of appending a duplicate.
-- Every call ends with one result row: (entry_id, outcome, sha256).
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_log_decision_checked`(
  in_entry_date DATE, in_entry_type STRING, in_strategy STRING, in_ticker STRING,
  in_decision STRING, in_conviction STRING, in_conviction_pct NUMERIC,
  in_sub_pattern STRING, in_theater_check STRING, in_title STRING, in_body_md STRING,
  in_fields_json STRING, in_refs ARRAY<STRING>, in_tags ARRAY<STRING>,
  in_superseded_by STRING, in_source_session STRING,
  in_expected_sha256 STRING
)
BEGIN
  DECLARE actual_sha256 STRING DEFAULT TO_HEX(SHA256(ARRAY_TO_STRING([
    IFNULL(CONCAT('S', CAST(in_entry_date AS STRING)), 'N'),
    IFNULL(CONCAT('S', in_entry_type), 'N'),
    IFNULL(CONCAT('S', in_strategy), 'N'),
    IFNULL(CONCAT('S', in_ticker), 'N'),
    IFNULL(CONCAT('S', in_decision), 'N'),
    IFNULL(CONCAT('S', in_conviction), 'N'),
    IFNULL(CONCAT('S', CAST(in_conviction_pct AS STRING)), 'N'),
    IFNULL(CONCAT('S', in_sub_pattern), 'N'),
    IFNULL(CONCAT('S', in_theater_check), 'N'),
    IFNULL(CONCAT('S', in_title), 'N'),
    IFNULL(CONCAT('S', in_body_md), 'N'),
    IFNULL(CONCAT('S', in_fields_json), 'N'),
    CONCAT('A', ARRAY_TO_STRING(ARRAY(
      SELECT IFNULL(CONCAT('S', r), 'N') FROM UNNEST(in_refs) AS r WITH OFFSET AS o ORDER BY o), '\x1e')),
    CONCAT('A', ARRAY_TO_STRING(ARRAY(
      SELECT IFNULL(CONCAT('S', t), 'N') FROM UNNEST(in_tags) AS t WITH OFFSET AS o ORDER BY o), '\x1e')),
    IFNULL(CONCAT('S', in_superseded_by), 'N'),
    IFNULL(CONCAT('S', in_source_session), 'N')
  ], '\x1f')));
  DECLARE digest_tag STRING DEFAULT CONCAT('sha256:', actual_sha256);
  DECLARE found_id STRING;

  -- 1) Transit check. Nothing is written on a mismatch.
  IF in_expected_sha256 IS NULL OR LOWER(in_expected_sha256) != actual_sha256 THEN
    RAISE USING MESSAGE = FORMAT(
      'sp_log_decision_checked: REFUSED, digest mismatch (expected %s, received %s). The CALL text was damaged in transit; nothing was written. Re-issue the generated call.sql verbatim; never edit it.',
      IFNULL(in_expected_sha256, 'NULL'), actual_sha256);
  END IF;

  -- 2) Storability check: what arrived intact must also parse, or sp_log_decision would store NULL.
  IF in_fields_json IS NOT NULL
     AND NOT STARTS_WITH(IFNULL(TO_JSON_STRING(SAFE.PARSE_JSON(in_fields_json)), ''), '{') THEN
    RAISE USING MESSAGE =
      'sp_log_decision_checked: REFUSED, in_fields_json is not a JSON object PARSE_JSON accepts (exact number mode: a number a FLOAT64 cannot hold exactly is rejected). Nothing was written. Fix the source file and regenerate.';
  END IF;

  -- 3) Idempotency: the digest tag names these exact arguments, so a row carrying it IS this write.
  --    Identity is the tag, never a JSON text comparison: a stored JSON value does not serialise like a
  --    fresh PARSE_JSON of the same text (measured 2026-10-29: storage writes 59.0 as 59 and can keep a
  --    different key order), so comparing TO_JSON_STRING(fields) would miss a landed row.
  SET found_id = (
    SELECT entry_id FROM `stock-trading-498512.events.decision_log`
    WHERE entry_date = in_entry_date AND digest_tag IN UNNEST(tags)
    ORDER BY event_ts LIMIT 1);
  IF found_id IS NOT NULL THEN
    SELECT found_id AS entry_id, 'already_present' AS outcome, actual_sha256 AS sha256;
    RETURN;
  END IF;

  -- 4) The write, through the one canonical path, with the digest tag appended to the caller's tags.
  CALL `stock-trading-498512.ops.sp_log_decision`(
    in_entry_date, in_entry_type, in_strategy, in_ticker, in_decision, in_conviction, in_conviction_pct,
    in_sub_pattern, in_theater_check, in_title, in_body_md, in_fields_json, in_refs,
    ARRAY_CONCAT(IFNULL(in_tags, []), [digest_tag]),
    in_superseded_by, in_source_session);

  -- 5) Readback of the row just written: present, and fields not silently NULLed.
  SET found_id = (
    SELECT entry_id FROM `stock-trading-498512.events.decision_log`
    WHERE entry_date = in_entry_date AND digest_tag IN UNNEST(tags)
      AND (in_fields_json IS NULL OR fields IS NOT NULL)
    ORDER BY event_ts LIMIT 1);
  IF found_id IS NULL THEN
    RAISE USING MESSAGE =
      'sp_log_decision_checked: the write did not read back. Run readback.sql before re-issuing; never re-issue blind.';
  END IF;
  SELECT found_id AS entry_id, 'written' AS outcome, actual_sha256 AS sha256;
END;

-- ============================================================================
-- VERIFICATION (run after applying; read-only). The digest vector pinned in tests/test_decision_call.py
-- must reproduce: the WITH-bound expression of this procedure over that vector's arguments returns
-- 19edf671479d4ba9dea4e2bc81882238e15d8f315cee5a3760e99e1142aae002 (verified live 2026-10-29).
--   SELECT routine_name FROM `stock-trading-498512.ops.INFORMATION_SCHEMA.ROUTINES`
--   WHERE routine_name = 'sp_log_decision_checked';
