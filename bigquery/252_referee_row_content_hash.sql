-- 252_referee_row_content_hash.sql
-- Closes ops.alerts fe36f70a-79e3-41ac-ba27-f7d299dadd1c (AR_att, adversarial_review_referee_rows_unhashed),
-- adjudicated by W5 SPEC-DEFECT NOTICE INTAKE 2026-10-04.
--
-- DEFECT (measured live by AR_att 2026-09-15, re-measured by W5 2026-10-04): ops.sp_score_cross_model_referee
-- INSERTs directly into events.adversarial_reviews and never set content_sha256 / body_bytes, so every
-- role='referee_gemini' row (16 of 16 as of 2026-10-04) is permanently unverifiable against the hash/readback
-- contract the attacker and orchestrator rows carry (ops.sp_write_adversarial_review, bigquery/146).
--
-- FIX (the alert's first suggestion; the second -- routing through sp_write_adversarial_review -- is rejected
-- because that writer ASSERTs a queue_event_id / attacker-orchestrator role contract the referee, which has no
-- queue transition, cannot satisfy): compute the SAME digest the guarded writer computes -- LOWER(TO_HEX(SHA256(body_md)))
-- and BYTE_LENGTH(body_md) -- inside this procedure's INSERT. Everything else is byte-identical to
-- bigquery/148 STATEMENT (5): the Gemini prompt, both 'already scored' guards, the QUALIFY single-attacker
-- reduction, and INSERT-only (no MERGE). bigquery/252 is now canonical for this procedure
-- (scripts/check_superseded_by_discipline.py ALLOWLIST re-pointed from 148).
--
-- THE 16 EXISTING referee rows are NOT backfilled: events.adversarial_reviews is append-only, and
-- sp_write_adversarial_review's correction path would append duplicate referee rows (it needs a NON-NULL
-- p_superseded_by on an identical-metadata body). They remain the known-legacy unhashed population; every
-- referee row written from this file forward carries a hash. A NULL body_md (empty Gemini reasoning) yields NULL
-- hash/bytes, the same as before.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_score_cross_model_referee`()
BEGIN
  INSERT INTO `stock-trading-498512.events.adversarial_reviews`
    (review_id, role, review_type, strategy, review_date, cycle_number, verdict, theater_check, weaknesses, artifact_path, body_md,
     content_sha256, body_bytes)
  SELECT
    S.review_id, S.role, S.review_type, S.strategy, S.review_date, S.cycle_number, S.verdict, S.theater_check, S.weaknesses, S.artifact_path, S.body_md,
    LOWER(TO_HEX(SHA256(S.body_md))), BYTE_LENGTH(S.body_md)
  FROM (
    SELECT
      g.review_id, 'referee_gemini' AS role, g.review_type, g.strategy, g.review_date, g.cycle_number,
      g.verdict_out AS verdict,
      CAST(NULL AS STRING) AS theater_check,
      TO_JSON(STRUCT(g.reasoning AS reasoning)) AS weaknesses,
      CAST(NULL AS STRING) AS artifact_path,
      g.reasoning AS body_md
    FROM AI.GENERATE_TABLE(
      MODEL `stock-trading-498512.ops.gemini`,
      (
        SELECT a.review_id, a.review_type, a.strategy, a.review_date, a.cycle_number,
          CONCAT(
            'You are an INDEPENDENT cross-model referee for a capital-binding autonomous-trading-system ',
            'decision. You have NOT seen any other reviewer opinion or verdict -- form your own from ',
            'first principles against the case below only. Return the SAME verdict vocabulary the review ',
            'type uses (SUFFICIENT/INSUFFICIENT for strategy-adoption; RETIRE/KEEP for strategy-retirement; ',
            'TERMINATE/CONTINUE/CONSTRAINT_RELAXATION for foundation-change-assessment; ',
            'ACTIVATE/DO-NOT-ACTIVATE/HYBRID for divergence-review). Begin your answer with the single ',
            'verdict token. Default on genuine ',
            'ambiguity: ',
            CASE a.review_type
              WHEN 'strategy-adoption' THEN 'INSUFFICIENT (reject)'
              WHEN 'strategy-retirement' THEN 'KEEP'
              WHEN 'divergence-review' THEN 'DO-NOT-ACTIVATE (keep the new-entry block)'
              ELSE 'CONTINUE' END,
            '.\n\nReview type: ', a.review_type,
            '\n\n=== CASE (attacker submission only -- no orchestrator text shown) ===\n',
            SUBSTR(COALESCE(a.body_md,''), 1, 6000)
          ) AS prompt
        FROM `stock-trading-498512.state.adversarial_reviews_current` a
        WHERE a.role = 'attacker'
          AND a.review_type IN ('strategy-adoption','strategy-retirement','foundation-change-assessment','divergence-review')
          AND NOT EXISTS (
            SELECT 1 FROM `stock-trading-498512.state.adversarial_reviews_current` r
            WHERE r.review_id = a.review_id AND r.role = 'referee_gemini'
              AND COALESCE(r.cycle_number, -1) >= a.cycle_number)
        -- ONE attacker row per review_id (newest cycle). Without this, two attacker rows sharing a
        -- review_id both pass the outer NOT EXISTS below -- which is evaluated against the
        -- pre-statement snapshot and so cannot see its own sibling inserts -- and two referee_gemini
        -- rows land for one review. Same idiom state.strategy_retirement_readiness's referee CTE
        -- already uses, applied at the WRITE path instead of only at a downstream read path.
        QUALIFY ROW_NUMBER() OVER (PARTITION BY a.review_id ORDER BY a.cycle_number DESC, a.event_ts DESC) = 1
      ),
      STRUCT('verdict_out STRING, reasoning STRING' AS output_schema, 0.0 AS temperature)
    ) g
  ) S
  WHERE NOT EXISTS (
    SELECT 1 FROM `stock-trading-498512.events.adversarial_reviews` T
    WHERE T.review_id = S.review_id AND T.role = S.role
      AND COALESCE(T.cycle_number, -1) >= S.cycle_number
  );
END;
