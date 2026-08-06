-- 143_adversarial_review_correction_path.sql (2026-08-06)
-- Project: stock-trading-498512. Give events.adversarial_reviews a REAL append-only correction
-- path, and fix the review_id-only keying that made one impossible.
-- Apply after 11_theater_judge.sql, 35_strategy_arsenal.sql, 44_cross_model_referee.sql,
-- 61_cross_model_referee_shadow.sql, 87_referee_promotion_class_breadth.sql,
-- 122_decision_correction_append_only.sql, 139/141 (append_only_violation class + halt scope).
--
-- ============================ WHY ================================================================
-- Until now, correcting a corrupted `body_md` on events.adversarial_reviews required an out-of-band
-- in-place UPDATE. That was blessed by commit bb21c91 as "the ONE SANCTIONED correction mechanism"
-- for one reason only, restated identically in Claude_Task_Plan.md's shared preamble, in
-- ops.alert_policy's append_only_violation row (bigquery/139), and in bigquery/141's and bigquery/57's
-- headers:
--
--     "that table has no superseded_by column, and ops.sp_score_cross_model_referee filters
--      role='attacker' with no dedup across rows, so a superseding row would insert duplicate
--      referee_gemini rows"
--
-- Both halves of that premise are addressed here, so the premise no longer holds. The consequence of
-- leaving it in place was NOT hypothetical: every sanctioned repair trips the append_only_violation
-- detector (state.append_only_integrity, bigquery/18), and that class is registered latching=TRUE
-- (bigquery/139) precisely because "was that UPDATE legitimate" is an adjudication a view cannot
-- re-check. MEASURED: 10 firings 2026-07-16..2026-08-06, ALL closed by hand, resolved_note lengths
-- 287-5,140 chars. Meanwhile AR_att/AR_orc's mandatory post-write SHA256 check (bb21c91) is DESIGNED
-- to catch bad writes and trigger exactly this repair -- so the verification mechanism and the
-- manual-adjudication mechanism were wired to each other in a loop.
--
-- An INSERT is not watched by state.append_only_integrity at all (it keys on
-- UPDATE/DELETE/MERGE/TRUNCATE_TABLE only -- the same reason bigquery/44's 2026-07-20 MERGE->INSERT
-- rewrite made that procedure stop tripping the monitor). So moving corrections onto an append-only
-- INSERT path removes the alert at its source rather than suppressing it.
--
-- ============================ THE DIRECTION OF superseded_by (read before editing) ===============
-- Mirrors events.decision_log EXACTLY, per bigquery/122_decision_correction_append_only.sql, which is
-- the canonical statement of this convention:
--   * The CORRECTION (new, good) row carries `superseded_by` = the OBSOLETE row's `event_id`.
--   * The obsolete row is left completely untouched -- its own `superseded_by` stays NULL forever.
--   * Readers therefore exclude the TARGET that is NAMED, not the row that names it:
--         event_id NOT IN (SELECT superseded_by FROM ... WHERE superseded_by IS NOT NULL)
-- `WHERE superseded_by IS NULL` IS THE WRONG PREDICATE and does the exact opposite of what is wanted
-- (it keeps the stale row and drops the correction). bigquery/122 calls this out in terms:
-- "Do NOT filter `entry_id WHERE superseded_by IS NOT NULL`: that is the correction row itself."
-- Note bigquery/116:571 uses the `IS NULL` form -- that definition was SUPERSEDED by bigquery/122 and
-- is DR-history, not a live pattern to copy.
--
-- state.adversarial_reviews_current (below) exists so this predicate is written ONCE. Every
-- row-reading consumer is repointed at it by this file. A future consumer that reads
-- events.adversarial_reviews directly is the anomaly, and is what scripts/check_superseded_by_discipline.py
-- (added in this changeset) fails CI on.
--
-- ============================ TWO ORTHOGONAL CONCEPTS -- DO NOT CONFLATE =========================
-- superseded_by  = a DEFECT repair. The old row is a mis-transcription; it should never be read again.
-- cycle_number   = LEGITIMATE successive revisions of the same review_id. BOTH are real history; a
--                  consumer generally wants the LATEST cycle, and MUST NOT silently mix cycles.
-- Several consumers keyed on review_id ALONE, which is a live bug independent of superseded_by --
-- see the next section. Fixing only one of the two would leave the other.
--
-- ============================ LIVE DEFECTS THIS FILE FIXES (all measured 2026-08-06) =============
-- (1) analytics.theater_judge IS STALE IN PRODUCTION RIGHT NOW. ops.sp_score_theater (bigquery/11)
--     pairs attacker+orchestrator ON review_id ALONE and guards on
--     `NOT EXISTS (... tj.review_id = a.review_id)`. All five founding pre-mortems were re-reviewed
--     at newer cycles (premortem-A 7->8, B 7->8, C 9->10, D 5->6, E 5->6; attacker rows 2026-08-04,
--     orchestrator rows 2026-08-05), but analytics.theater_judge still holds ONLY the 2026-07-29
--     scoring for each -- scored_ts 1785460712 on all five. The guard is review_id-keyed, so a newer
--     cycle can never re-score. W5's ADVERSARIAL INDEPENDENCE AUDIT reads this table, so it has been
--     auditing superseded text.
-- (2) THE SAME JOIN FANS OUT. With two cycles present the self-join yields the FULL CROSS PRODUCT:
--     MEASURED 4 attacker x orchestrator pairs for each of the five pre-mortems (7x7, 7x8, 8x7, 8x8).
--     Only the review_id-keyed NOT EXISTS guard is currently suppressing 4 Gemini calls per review and
--     4 INSERTs against a PRIMARY KEY (review_id) table. Fixing (1) without fixing (2) would have
--     unmasked it.
-- (3) ops.sp_score_cross_model_referee CAN INSERT DUPLICATE referee_gemini ROWS. Its attacker
--     candidate subquery has no ROW_NUMBER/QUALIFY, and its outer NOT EXISTS guard is evaluated
--     against the statement's pre-statement snapshot, so it cannot see sibling rows being inserted by
--     the same statement. Two attacker rows sharing a review_id -> two Gemini calls -> two
--     referee_gemini rows. Dormant only because none of its four gated review_types has reached a
--     second cycle yet; pre-mortem (which has) is not in its IN-list.
-- (4) state.foundation_change_termination_readiness's `referee` CTE (bigquery/44:195-204) has ZERO
--     dedup of any kind and is LEFT JOINed on review_id -- a second referee row for one review_id
--     fans the view out to multiple rows per strategy_code with conflicting `ready` values.
-- (5) analytics.referee_concurrence_calibration's `normalized` CTE (bigquery/61:48-85) has no dedup
--     and `paired` self-joins it ON review_id alone. An extra orchestrator or referee row directly
--     inflates COUNT(*) n_scored and shifts concurrence_rate -- and those two numbers are the literal
--     inputs to state.referee_promotion_readiness's sample_floor_met (>=6) and concurrence_met
--     (>=0.80) bars. Highest blast radius of the five views.
--
-- ============================ WHAT IS DELIBERATELY *NOT* CHANGED ================================
-- * state.append_only_integrity_haltable (bigquery/141) is LEFT EXACTLY AS IS. Its carve-out
--   (statement_type='UPDATE' AND target_table='adversarial_reviews') becomes REDUNDANT once
--   corrections are INSERTs -- an INSERT never enters state.append_only_integrity in the first place
--   -- but redundant is not wrong, and it is fail-SAFE: it can only ever REDUCE halting, never cause
--   it. Retiring it would require bumping ops.sp_sq_integrity_check v3->v4 plus the bigquery/63
--   registry MERGE, which that file's own APPLY-ORDER WARNING documents as a delicate multi-file
--   sequence. RETIREMENT CONDITION for a future session: once JOBS_BY_PROJECT shows no UPDATE against
--   events.adversarial_reviews for 14 consecutive days AND the prose below is live in the generated
--   task_plan slices, drop the carve-out and repoint the promotion clock back at the full view, so an
--   UPDATE on this table becomes halt-eligible again (which, after this file, it should be).
-- * ops.alert_policy's append_only_violation row stays latching=TRUE. That is a settled decision
--   (bigquery/139): the class is an adjudication, not a re-checkable condition. This file reduces how
--   OFTEN it fires; it does not make it auto-resolvable, and no auto-resolve rule is added.
-- * The `analytics.theater_judge` PRIMARY KEY stays (review_id) -- ONE row per review, now carrying
--   the cycle it was scored at and overwritten in place when a newer cycle appears. A compound
--   (review_id, cycle_number) key was rejected: state.strategy_adoption_readiness joins
--   `t.review_id = v.review_id` with no cycle predicate, AR_orc reads `WHERE review_id = <id>`, and
--   analytics.theater_check_calibration aggregates the whole table -- all three would silently start
--   double-counting under a compound key.

-- ============================================================================
-- (1) THE COLUMN. Nullable STRING, same shape and meaning as events.decision_log.superseded_by
-- (bigquery/01_schema.sql:24). Verified safe against every drift detector: state.ddl_drift and the
-- bigquery/19_stack_review_fixes_2.sql column registry are PARTIAL registries (key/partition/cluster
-- columns only), not exhaustive column mirrors, so a new column does not raise ddl_drift; and
-- ops.sp_restore_drill compares row counts/table lists, not column sets.
-- ============================================================================
ALTER TABLE `stock-trading-498512.events.adversarial_reviews`
  ADD COLUMN IF NOT EXISTS superseded_by STRING;

ALTER TABLE `stock-trading-498512.events.adversarial_reviews`
  SET OPTIONS(description='Adversarial attacker/orchestrator/referee outputs; paired view feeds theater-independence analytics. APPEND-ONLY: never UPDATE/DELETE. Corrections are NEW rows whose superseded_by names the OBSOLETE row event_id (same direction as events.decision_log, bigquery/122); readers exclude the NAMED TARGET via state.adversarial_reviews_current. cycle_number expresses legitimate successive revisions and is a SEPARATE concept from superseded_by.');

-- ============================================================================
-- (2) state.adversarial_reviews_current -- THE canonical non-superseded row set. Every row-reading
-- consumer below reads this instead of the base table, so the anti-join predicate is written once.
-- NOT IN is safe here: the subquery filters superseded_by IS NOT NULL, so it can never yield a NULL.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.adversarial_reviews_current` AS
SELECT *
FROM `stock-trading-498512.events.adversarial_reviews`
WHERE event_id NOT IN (
  SELECT superseded_by
  FROM `stock-trading-498512.events.adversarial_reviews`
  WHERE superseded_by IS NOT NULL
);

-- ============================================================================
-- (3) analytics.theater_judge gains cycle_number, so a re-review can re-score.
--
-- THE BACKFILL IS NOT OPTIONAL. ADD COLUMN leaves cycle_number NULL on all 28 existing rows, and the
-- re-score guard in (4) reads NULL as COALESCE(...,-1), which is < every real cycle_number (all 72
-- live rows are >= 1). Without the backfill the first run would therefore re-score ALL 28 scored
-- reviews -- 28 Gemini calls, 23 of them pure churn on reviews that never moved off cycle 1 -- rather
-- than the 5 genuinely-stale pre-mortems. Found by adversarial review of this file before it was
-- applied; the earlier draft asserted "re-scores exactly once ... that is intended", which understated
-- the blast radius by 4.6x.
--
-- The backfill sets each existing row to the newest cycle that was actually PAIRED AND VISIBLE at the
-- moment it was scored (event_ts <= scored_ts on BOTH roles) -- i.e. what the old, cycle-blind
-- procedure really judged. That yields 1 for the 23 single-cycle reviews (so they never re-score) and
-- 7/7/9/5/5 for premortem-A/B/C/D/E (so they DO re-score, against their current 8/8/10/6/6). If no
-- pair was visible at scored_ts the expression yields NULL, the row keeps NULL, and it re-scores --
-- fail-safe in the direction of re-judging rather than silently trusting an unattributable score.
-- ============================================================================
ALTER TABLE `stock-trading-498512.analytics.theater_judge`
  ADD COLUMN IF NOT EXISTS cycle_number INT64;

UPDATE `stock-trading-498512.analytics.theater_judge` T
SET cycle_number = (
  SELECT MAX(a.cycle_number)
  FROM `stock-trading-498512.events.adversarial_reviews` a
  JOIN `stock-trading-498512.events.adversarial_reviews` o
    ON a.review_id = o.review_id AND a.cycle_number = o.cycle_number
  WHERE a.role = 'attacker' AND o.role = 'orchestrator'
    AND a.review_id = T.review_id
    AND a.event_ts <= T.scored_ts AND o.event_ts <= T.scored_ts
)
WHERE T.cycle_number IS NULL;

-- ============================================================================
-- (4) ops.sp_score_theater -- SUPERSEDES the definition in bigquery/11_theater_judge.sql.
-- Changes from bigquery/11: reads state.adversarial_reviews_current; pairs attacker+orchestrator on
-- (review_id, cycle_number) rather than review_id alone (kills the cross product); reduces to exactly
-- ONE row per review_id -- the newest cycle having BOTH roles -- so the MERGE can never see two
-- source rows for one target row; re-scores when a newer cycle appears instead of never.
-- The Gemini prompt text is byte-identical to bigquery/11's.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_score_theater`()
BEGIN
  MERGE `stock-trading-498512.analytics.theater_judge` T
  USING (
    SELECT g.review_id, g.strategy, g.review_type, g.review_date, g.cycle_number, g.self_certified,
           g.independent AS judge_independent, g.reason AS judge_reason,
           -- self-cert "claims independence" = DIVERGENT or MIXED (partial independence); CONVERGENT = theater.
           -- So agree when that claim matches the judge: (DIVERGENT|MIXED) = independent. (MIXED must count
           -- as independence-consistent, else a MIXED review the judge finds independent is mis-scored as a
           -- disagreement.)
           ((UPPER(g.self_certified) LIKE '%DIVERGENT%' OR UPPER(g.self_certified) LIKE '%MIXED%') = g.independent) AS agrees_with_self_cert
    FROM AI.GENERATE_TABLE(
      MODEL `stock-trading-498512.ops.gemini`,
      (
        SELECT p.review_id, p.strategy, p.review_type, p.review_date, p.cycle_number,
               p.self_certified,
               CONCAT(
                 'Two adversarial reviewers examined the same artifact. The ATTACKER argues the bear/defect case; ',
                 'the ORCHESTRATOR independently adjudicates. Question: did the ORCHESTRATOR surface INDEPENDENT ',
                 'disagreement — substantive points the attacker did NOT make, or a verdict reached via reasoning ',
                 'that diverges from the attacker — rather than merely restating/agreeing with the attacker (which ',
                 'would be "theater")? Return independent=TRUE only for genuine independent reasoning.\n\n',
                 '=== ATTACKER (verdict: ', COALESCE(p.att_verdict,''), ') ===\n', SUBSTR(COALESCE(p.att_body,''), 1, 4000),
                 '\n\n=== ORCHESTRATOR (verdict: ', COALESCE(p.orc_verdict,''), ') ===\n', SUBSTR(COALESCE(p.orc_body,''), 1, 4000)
               ) AS prompt
        FROM (
          SELECT a.review_id, o.strategy, o.review_type, o.review_date, a.cycle_number,
                 o.theater_check AS self_certified,
                 a.verdict AS att_verdict, a.body_md AS att_body,
                 o.verdict AS orc_verdict, o.body_md AS orc_body
          FROM (
            SELECT review_id, cycle_number, verdict, body_md
            FROM `stock-trading-498512.state.adversarial_reviews_current`
            WHERE role = 'attacker'
            QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id, cycle_number ORDER BY event_ts DESC) = 1
          ) a
          JOIN (
            SELECT review_id, cycle_number, strategy, review_type, review_date, theater_check, verdict, body_md
            FROM `stock-trading-498512.state.adversarial_reviews_current`
            WHERE role = 'orchestrator'
            QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id, cycle_number ORDER BY event_ts DESC) = 1
          ) o
            ON a.review_id = o.review_id AND a.cycle_number = o.cycle_number
          -- Exactly ONE row per review_id: the newest cycle for which BOTH roles exist.
          QUALIFY ROW_NUMBER() OVER (PARTITION BY a.review_id ORDER BY a.cycle_number DESC) = 1
        ) p
        -- Score when never scored, OR when the paired cycle is newer than what was scored. A
        -- pre-cycle_number row reads NULL -> -1, so it re-scores exactly once.
        WHERE NOT EXISTS (
          SELECT 1 FROM `stock-trading-498512.analytics.theater_judge` tj
          WHERE tj.review_id = p.review_id
            AND COALESCE(tj.cycle_number, -1) >= p.cycle_number)
      ),
      STRUCT('independent BOOL, reason STRING' AS output_schema, 0.0 AS temperature)
    ) g
  ) S
  ON T.review_id = S.review_id
  WHEN MATCHED THEN UPDATE SET
    strategy = S.strategy, review_type = S.review_type, review_date = S.review_date,
    cycle_number = S.cycle_number, self_certified = S.self_certified,
    judge_independent = S.judge_independent, judge_reason = S.judge_reason,
    agrees_with_self_cert = S.agrees_with_self_cert, scored_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN INSERT
    (review_id, strategy, review_type, review_date, cycle_number, self_certified, judge_independent, judge_reason, agrees_with_self_cert)
    VALUES (S.review_id, S.strategy, S.review_type, S.review_date, S.cycle_number, S.self_certified, S.judge_independent, S.judge_reason, S.agrees_with_self_cert);
END;

-- ============================================================================
-- (5) ops.sp_score_cross_model_referee -- SUPERSEDES the definition in bigquery/44_cross_model_referee.sql.
-- Changes from bigquery/44: reads state.adversarial_reviews_current; the attacker candidate set is
-- reduced to ONE row per review_id (newest cycle) by QUALIFY, closing the duplicate-referee_gemini
-- path. Both original idempotency guards are preserved verbatim (inner NOT EXISTS avoids re-billing
-- Gemini; outer NOT EXISTS on (review_id, role) is unchanged), and it remains INSERT-only -- no MERGE
-- -- so it still cannot trip state.append_only_integrity (bigquery/44's 2026-07-20 fix, preserved).
-- The Gemini prompt text is byte-identical to bigquery/44's.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_score_cross_model_referee`()
BEGIN
  INSERT INTO `stock-trading-498512.events.adversarial_reviews`
    (review_id, role, review_type, strategy, review_date, cycle_number, verdict, theater_check, weaknesses, artifact_path, body_md)
  SELECT
    S.review_id, S.role, S.review_type, S.strategy, S.review_date, S.cycle_number, S.verdict, S.theater_check, S.weaknesses, S.artifact_path, S.body_md
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
            WHERE r.review_id = a.review_id AND r.role = 'referee_gemini')
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
  );
END;

-- ============================================================================
-- (6) state.strategy_adoption_readiness -- SUPERSEDES the definition in bigquery/35_strategy_arsenal.sql.
-- Only change: latest_verdict + theater read the current view / carry cycle_number. The QUALIFY
-- partitions BY STRATEGY (across different reviews), so review_date DESC stays the correct primary
-- sort -- a correction row reproduces its original's review_date and therefore cannot outrank a newer
-- review. Everything else is byte-identical to bigquery/35.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_adoption_readiness` AS
WITH latest_verdict AS (
  SELECT strategy AS strategy_code, verdict, review_id
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE review_type = 'strategy-adoption' AND role = 'orchestrator'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, cycle_number DESC, event_ts DESC) = 1
),
theater AS (
  SELECT review_id, judge_independent
  FROM `stock-trading-498512.analytics.theater_judge`
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  v.verdict,
  v.verdict = 'SUFFICIENT' AS review_sufficient,
  COALESCE(t.judge_independent, FALSE) AS theater_ok,
  NOT rails.incubation_cap_reached AS caps_ok,
  NOT rails.at_ceiling AS ceiling_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':UNDER_REVIEW->SHADOW')) AS not_already_transitioned,
  (v.verdict = 'SUFFICIENT'
   AND COALESCE(t.judge_independent, FALSE)
   AND NOT rails.incubation_cap_reached
   AND NOT rails.at_ceiling
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':UNDER_REVIEW->SHADOW'))) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
JOIN latest_verdict v USING (strategy_code)
LEFT JOIN theater t ON t.review_id = v.review_id
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'UNDER_REVIEW';

-- ============================================================================
-- (7) state.strategy_retirement_readiness -- SUPERSEDES the definition in bigquery/44_cross_model_referee.sql.
-- Only change: both CTEs read the current view, and cycle_number joins the ORDER BY of the
-- per-review_id referee QUALIFY. Its review_id pairing (the 2026-07-11 adversarial self-audit fix)
-- is preserved exactly.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_retirement_readiness` AS
WITH orch AS (
  SELECT strategy AS strategy_code, verdict AS orch_verdict, review_id,
         ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, cycle_number DESC, event_ts DESC) AS rn
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE review_type = 'strategy-retirement' AND role = 'orchestrator'
),
referee AS (
  -- Paired to the orchestrator by review_id (like the foundation_change_termination_readiness sibling
  -- below), NOT by strategy_code — pairing by strategy alone let a STALE referee_gemini verdict from an
  -- earlier, different retirement review satisfy referee_concurs against a NEW orchestrator verdict
  -- (adversarial self-audit fix, rev 2026-07-11).
  SELECT review_id, verdict AS referee_verdict
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE review_type = 'strategy-retirement' AND role = 'referee_gemini'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY cycle_number DESC, review_date DESC, event_ts DESC) = 1
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  o.orch_verdict,
  ref.referee_verdict,
  COALESCE(o.orch_verdict, 'MISSING') = 'RETIRE' AS orchestrator_retire,
  COALESCE(ref.referee_verdict, 'MISSING') = 'RETIRE' AS referee_concurs,
  rails.active_count > rails.n_min AS floor_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.strategy_code = r.strategy_code AND cl.to_state = 'TERMINATED') AS not_already_transitioned,
  (COALESCE(o.orch_verdict, 'MISSING') = 'RETIRE'
   AND COALESCE(ref.referee_verdict, 'MISSING') = 'RETIRE'
   AND rails.active_count > rails.n_min
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.strategy_code = r.strategy_code AND cl.to_state = 'TERMINATED')) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN orch o ON o.strategy_code = r.strategy_code AND o.rn = 1
LEFT JOIN referee ref ON ref.review_id = o.review_id
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'RETIREMENT_PROPOSED';

-- ============================================================================
-- (8) state.foundation_change_termination_readiness -- SUPERSEDES the definition in
-- bigquery/44_cross_model_referee.sql. Fixes defect (4): the `referee` CTE had NO dedup at all and is
-- LEFT JOINed on review_id, so a second referee row for one review_id multiplied the output rows per
-- strategy_code with conflicting `ready` values. The QUALIFY MUST live inside this CTE -- adding it
-- after the join cannot undo a fan-out that already happened (the bigquery/116 placement trap).
-- Still DORMANT: no review_type='foundation-change-assessment' row exists yet, so it returns 0 rows.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.foundation_change_termination_readiness` AS
WITH orch AS (
  SELECT strategy AS strategy_code, review_id, verdict AS orch_verdict,
         ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, cycle_number DESC, event_ts DESC) AS rn
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE review_type = 'foundation-change-assessment' AND role = 'orchestrator'
),
referee AS (
  SELECT review_id, verdict AS referee_verdict
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE review_type = 'foundation-change-assessment' AND role = 'referee_gemini'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY cycle_number DESC, review_date DESC, event_ts DESC) = 1
)
SELECT
  o.strategy_code, o.review_id, o.orch_verdict, ref.referee_verdict,
  o.orch_verdict = 'TERMINATE' AS orchestrator_terminate,
  COALESCE(ref.referee_verdict, 'MISSING') = 'TERMINATE' AS referee_concurs,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.strategy_code = o.strategy_code AND cl.to_state = 'TERMINATED'
                AND cl.note LIKE 'foundation-change%') AS not_already_transitioned,
  (o.orch_verdict = 'TERMINATE'
   AND COALESCE(ref.referee_verdict, 'MISSING') = 'TERMINATE'
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.strategy_code = o.strategy_code AND cl.to_state = 'TERMINATED'
                     AND cl.note LIKE 'foundation-change%')) AS ready
FROM orch o
LEFT JOIN referee ref ON ref.review_id = o.review_id
WHERE o.rn = 1;

-- ============================================================================
-- (9) analytics.referee_concurrence_calibration -- SUPERSEDES the definition in
-- bigquery/61_cross_model_referee_shadow.sql. Fixes defect (5): `normalized` gains a per
-- (review_id, role) QUALIFY so `paired`'s self-join cannot multiply, and reads the current view. The
-- entire verdict-normalization CASE is byte-identical to bigquery/61's -- including its
-- leading-token anchoring, which was validated against the 6 live orchestrator rows on 2026-07-17
-- and must not be "simplified" into a substring match.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.referee_concurrence_calibration` AS
WITH normalized AS (
  SELECT
    review_id, role, review_type,
    CASE
      -- divergence-review vocabulary (DEF-5 Part 1, 2026-07-17): ACTIVATE / DO-NOT-ACTIVATE / HYBRID.
      -- SCOPED to review_type='divergence-review' AND ANCHORED to the LEADING decision token
      -- (^[^A-Z]* skips leading spaces / markdown '**' / quotes before the token) rather than a bare
      -- substring match. This deviates from a naive '%DO-NOT-ACTIVATE%'/'%DNA%'-before-'%ACTIVATE%'
      -- substring ordering ON PURPOSE: the live orchestrator divergence-review verdicts are verbose
      -- free-text whose REASONING embeds the word "DNA" while the DECISION is ACTIVATE — e.g.
      -- "ACTIVATE (binding, UNCHANGED). Post-reconciliation DNA is override-manufactured on a raw call
      -- that ROSE to ACTIVATE...". A bare '%DNA%' test (checked before ACTIVATE) misnormalizes ALL FOUR
      -- such ACTIVATE decisions to DO_NOT_ACTIVATE (VERIFIED against the 6 live orchestrator rows,
      -- 2026-07-17), which would falsely record disagreement and understate concurrence on a metric that
      -- gates a capital-binding promotion. Anchoring to the leading token fixes that while preserving the
      -- required ordering (HYBRID first — "HYBRID ACTIVATE" contains ACTIVATE; DO-NOT-ACTIVATE / DNA
      -- before the bare ACTIVATE fallback). Scoping to the review_type keeps a SISA verdict that happens
      -- to contain the word "activate" in prose from cross-normalizing into this vocabulary.
      WHEN review_type = 'divergence-review' AND REGEXP_CONTAINS(UPPER(verdict), r'^[^A-Z]*HYBRID') THEN 'HYBRID'
      WHEN review_type = 'divergence-review' AND REGEXP_CONTAINS(UPPER(verdict), r'^[^A-Z]*DO[ -]?NOT[ -]?ACTIVATE') THEN 'DO_NOT_ACTIVATE'
      WHEN review_type = 'divergence-review' AND REGEXP_CONTAINS(UPPER(verdict), r'^[^A-Z]*DNA\b') THEN 'DO_NOT_ACTIVATE'
      WHEN review_type = 'divergence-review' AND UPPER(verdict) LIKE '%ACTIVATE%' THEN 'ACTIVATE'
      WHEN UPPER(verdict) LIKE '%RETIRE%' THEN 'RETIRE'
      WHEN UPPER(verdict) LIKE '%KEEP%' THEN 'KEEP'
      WHEN UPPER(verdict) LIKE '%TERMINATE%' THEN 'TERMINATE'
      WHEN UPPER(verdict) LIKE '%CONSTRAINT%' THEN 'CONSTRAINT_RELAXATION'
      WHEN UPPER(verdict) LIKE '%CONTINUE%' THEN 'CONTINUE'
      -- INSUFFICIENT / REVISION-REQUIRED before the bare SUFFICIENT check below, so
      -- "TIER 1 DEFECT — REVISION REQUIRED" (which contains neither literal word "INSUFFICIENT") still
      -- normalizes to the referee's INSUFFICIENT vocabulary rather than falling through to OTHER.
      WHEN UPPER(verdict) LIKE '%INSUFFICIENT%' OR UPPER(verdict) LIKE '%REVISION%' THEN 'INSUFFICIENT'
      WHEN UPPER(verdict) LIKE '%SUFFICIENT%' THEN 'SUFFICIENT'
      ELSE 'OTHER'
    END AS verdict_norm
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE review_type IN ('strategy-adoption', 'strategy-retirement', 'foundation-change-assessment', 'divergence-review')
    AND role IN ('orchestrator', 'referee_gemini')
  -- ONE row per (review_id, role), newest cycle. Without this, `paired` below self-joins on review_id
  -- alone and an extra orchestrator or referee row multiplies COUNT(*) n_scored -- which is the literal
  -- input to state.referee_promotion_readiness's sample_floor_met (>=6) and concurrence_met (>=0.80).
  QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id, role ORDER BY cycle_number DESC, review_date DESC, event_ts DESC) = 1
),
paired AS (
  SELECT o.review_id, o.review_type,
    o.verdict_norm AS orchestrator_verdict_norm, r.verdict_norm AS referee_verdict_norm,
    (o.verdict_norm = r.verdict_norm) AS concurs
  FROM normalized o
  JOIN normalized r ON o.review_id = r.review_id AND o.role = 'orchestrator' AND r.role = 'referee_gemini'
),
by_type AS (
  SELECT review_type, COUNT(*) AS n_scored, COUNTIF(concurs) AS n_concur,
    SAFE_DIVIDE(COUNTIF(concurs), COUNT(*)) AS concurrence_rate
  FROM paired
  GROUP BY review_type
),
overall AS (
  SELECT '__ALL__' AS review_type, COUNT(*) AS n_scored, COUNTIF(concurs) AS n_concur,
    SAFE_DIVIDE(COUNTIF(concurs), COUNT(*)) AS concurrence_rate
  FROM paired
)
SELECT * FROM by_type
UNION ALL
SELECT * FROM overall;

-- ============================================================================
-- (10) state.referee_promotion_readiness -- SUPERSEDES the definition in
-- bigquery/87_referee_promotion_class_breadth.sql. Only change: first_ref reads the current view, so
-- referee_rows and MIN(event_ts) cannot count a superseded row. The five promotion bars
-- (quarter_elapsed / sample_floor_met / concurrence_met / class_breadth_met / not_already_promoted)
-- and every threshold are byte-identical to bigquery/87 -- its real gate inputs come from
-- analytics.referee_concurrence_calibration, which (9) above fixes.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.referee_promotion_readiness` AS
WITH first_ref AS (
  -- MIN(event_ts) = the actual INSERTION time of the earliest referee_gemini row, deliberately NOT its
  -- review_date (bigquery/44 backdates review_date to the original attacker submission; keying the
  -- 90-day burn-in on it would satisfy the quarter clock retroactively — see bigquery/84's note).
  SELECT MIN(event_ts) AS first_referee_ts, COUNT(*) AS referee_rows
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE role = 'referee_gemini'
),
concur_rollup AS (
  SELECT COALESCE(n_scored, 0) AS n_scored, concurrence_rate
  FROM `stock-trading-498512.analytics.referee_concurrence_calibration`
  WHERE review_type = '__ALL__'
),
class_breadth AS (
  -- Distinct review_types with a non-trivial per-class sample (n_scored >= 2). Empty calibration
  -- => COUNT(*)=0 => the bar stays FALSE — fail-closed, same as every other bar here.
  SELECT COUNT(*) AS n_types_with_evidence
  FROM `stock-trading-498512.analytics.referee_concurrence_calibration`
  WHERE review_type != '__ALL__' AND n_scored >= 2
)
SELECT
  fr.first_referee_ts,
  fr.referee_rows,
  r.n_scored,
  r.concurrence_rate,
  cb.n_types_with_evidence,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) AS days_since_first_referee,
  (fr.first_referee_ts IS NOT NULL
   AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) >= 90) AS quarter_elapsed,
  (r.n_scored >= 6) AS sample_floor_met,
  (COALESCE(r.concurrence_rate, 0.0) >= 0.80) AS concurrence_met,
  (cb.n_types_with_evidence >= 2) AS class_breadth_met,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.loop_promotion_log` pl
              WHERE pl.loop_id = 'cross_model_referee_independence' AND pl.to_stage = 'active_auto') AS not_already_promoted,
  (fr.first_referee_ts IS NOT NULL
   AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) >= 90
   AND r.n_scored >= 6
   AND COALESCE(r.concurrence_rate, 0.0) >= 0.80
   AND cb.n_types_with_evidence >= 2
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.loop_promotion_log` pl
                   WHERE pl.loop_id = 'cross_model_referee_independence' AND pl.to_stage = 'active_auto')) AS ready_for_promotion
FROM first_ref fr CROSS JOIN concur_rollup r CROSS JOIN class_breadth cb;

-- ============================================================================
-- (11) ops.alert_policy -- correct the append_only_violation row's `note`.
-- bigquery/139's INSERT is NOT-EXISTS-guarded on category, so RE-APPLYING THAT FILE IS A NO-OP
-- against the existing row. An explicit UPDATE is the only thing that propagates the corrected text.
-- `latching` and `resolve_rule` are deliberately untouched -- the class stays manual-adjudication.
-- This is a control-plane table, not an events.* audit table, so an UPDATE here is ordinary.
-- ============================================================================
UPDATE `stock-trading-498512.ops.alert_policy`
SET note = CONCAT(
      'INTEGRITY CLASS, first raised 2026-07-16; registered 2026-08-05 after the 8th firing ',
      '(alert 9c7c0261, AR_att UPDATE on events.adversarial_reviews) revealed the class had no ',
      'ops.alert_policy row at all and therefore no written resolve rule. Detector: ',
      'state.append_only_integrity (bigquery/18) over UPDATE/DELETE/MERGE/TRUNCATE_TABLE against the ',
      'eight audit-truth events.* tables; one carve-out exists, W5 normalizing ',
      'events.decision_log.sub_pattern in place (RUNBOOK 21). ',
      'CORRECTED 2026-08-06 by bigquery/143_adversarial_review_correction_path.sql -- the previous ',
      'text said adding a second row is NOT a safe alternative to an in-place fix on ',
      'events.adversarial_reviews, because that table had no superseded_by column and ',
      'ops.sp_score_cross_model_referee filtered role=attacker with no dedup. BOTH have been fixed. ',
      'events.adversarial_reviews now HAS superseded_by, with the same direction as ',
      'events.decision_log (bigquery/122): the CORRECTION row names the OBSOLETE row event_id, and ',
      'readers exclude the named TARGET via state.adversarial_reviews_current. An APPEND is now the ',
      'correct and only sanctioned repair; an in-place UPDATE on this table is NO LONGER sanctioned ',
      'and should be investigated as a genuine violation. Because an INSERT is not a watched ',
      'statement_type, a correct repair no longer raises this alert at all.'
    )
WHERE category = 'append_only_violation';

-- VERIFICATION (run after apply; all must hold). This file MUTATES DATA -- two ALTERs, a backfill
-- UPDATE, and a procedure whose next CALL re-scores rows -- so it needs runnable assertions more than
-- its pure-view sibling bigquery/144 does. (It shipped without them; added 2026-08-06 on audit.)
-- Double-dash line comments only: a trailing C-style block comment after the last statement causes
-- permanent live-sql-parity drift.
--
-- 1. The column exists and NOTHING was superseded by this file itself:
--    SELECT COUNT(*) AS n, COUNTIF(superseded_by IS NOT NULL) AS n_superseded
--    FROM `stock-trading-498512.events.adversarial_reviews`;
--    -> expect n=72, n_superseded=0 at apply time (the mechanism is armed, not yet used).
--
-- 2. The theater_judge backfill left NO row unattributed, and did not change the row set:
--    SELECT COUNT(*) AS n, COUNT(DISTINCT review_id) AS n_ids, COUNTIF(cycle_number IS NULL) AS n_null
--    FROM `stock-trading-498512.analytics.theater_judge`;
--    -> expect 28 / 28 / 0. n_null > 0 means the correlated backfill subquery found no visible pair
--       for some row; that row will re-score on the next CALL, which is fail-safe but worth knowing.
--
-- 3. Exactly the five stale founding pre-mortems were re-scored, and to their CURRENT cycles:
--    SELECT review_id, cycle_number FROM `stock-trading-498512.analytics.theater_judge`
--    WHERE review_id LIKE 'premortem-%' ORDER BY review_id;
--    -> expect premortem-A=8, B=8, C=10, D=6, E=6. Every other row must remain cycle_number=1.
--
-- 4. The dedup actually holds -- no fan-out from the (review_id, cycle_number) pairing:
--    SELECT COUNT(*) FROM (SELECT review_id FROM `stock-trading-498512.analytics.theater_judge`
--                          GROUP BY review_id HAVING COUNT(*) > 1);
--    -> expect 0 (the PRIMARY KEY is review_id and is NOT ENFORCED, so this must be checked, not assumed).
--
-- 5. The current-rows view is a pure pass-through until a correction exists:
--    SELECT (SELECT COUNT(*) FROM `stock-trading-498512.events.adversarial_reviews`)
--         - (SELECT COUNT(*) FROM `stock-trading-498512.state.adversarial_reviews_current`);
--    -> expect 0 today; it becomes exactly the number of superseded rows once corrections land.
