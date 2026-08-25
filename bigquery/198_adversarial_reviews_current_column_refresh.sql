-- ===== 198: state.adversarial_reviews_current — refresh the frozen SELECT * column list =====
-- (2026-08-25 — interactive alert triage; found by a stale-SQL-identifier class sweep, not by any
-- existing monitor. No alert reported this: nothing in the stack was capable of noticing it.)
--
-- THE BUG. bigquery/143_adversarial_review_correction_path.sql created the view as:
--     CREATE OR REPLACE VIEW state.adversarial_reviews_current AS
--     SELECT * FROM events.adversarial_reviews
--     WHERE event_id NOT IN (SELECT superseded_by FROM events.adversarial_reviews
--                            WHERE superseded_by IS NOT NULL);
-- Two files later, bigquery/145_adversarial_review_storage_cutover.sql ran
-- `ALTER TABLE events.adversarial_reviews ADD COLUMN` for `content_sha256`, `body_bytes` and
-- `queue_event_id` (with `source_commit_sha` and `schema_version` arriving on the same surface).
-- The view was never re-created.
--
-- BigQuery expands `SELECT *` AT VIEW-CREATION TIME and freezes the resulting column list into the
-- view's schema. The stored definition text still literally reads `SELECT *`, but the view's actual
-- schema is whatever the base table looked like on the day it was created. MEASURED 2026-08-25:
-- `events.adversarial_reviews` has 19 columns; `state.adversarial_reviews_current` exposes 14. The
-- five missing ones are exactly 145's additions.
--
-- WHY EVERY EXISTING GUARD IS BLIND TO IT — this is the part worth remembering.
-- `scripts/check_live_sql_parity.py` compares the repo's SQL TEXT against the live view's stored
-- definition TEXT. Both still say `SELECT *`, byte for byte, so parity is GREEN and always would
-- have been. `state.ddl_drift` and bigquery/19's column registry are PARTIAL registries (key /
-- partition / cluster columns only), so neither notices. `ops.sp_restore_drill` compares row counts
-- and table lists, not column sets. Nothing in the stack compares a `SELECT *` view's column set
-- against its source. The bug is invisible by construction to every drift detector we own.
--
-- BLAST RADIUS, measured rather than asserted. `Claude_Task_Plan.md`'s AR_att "STEP 0 — STRANDED-
-- TRANSCRIPT RECONCILIATION" — the self-repair step that rescues a review transcript stranded when a
-- routine dies mid-write — joins `state.adversarial_reviews_current r ON r.queue_event_id = q.event_id`.
-- `queue_event_id` is one of the five missing columns, so that JOIN KEY does not exist on the view and
-- the query cannot compile against it. 82 rows of `events.adversarial_reviews` carry a non-NULL
-- `queue_event_id` and are unreachable through the view.
--
-- The step has nonetheless reported "ran first, returned ZERO rows" on every fire since 2026-08-17.
-- BigQuery resolves column names at parse time regardless of row count, so a clean zero-row result is
-- only possible if the executing session silently substituted the base table. That is the failure mode
-- to sit with: the step has only ever "worked" because each executing model noticed the mismatch and
-- routed around it, never because the mechanism was sound — and it is precisely the step that must
-- work unattended at the moment a routine has just died.
--
-- THE FIX is a no-op re-run of 143's own DDL: identical text, re-expanded `SELECT *`, which picks up
-- all 19 columns. Semantics are unchanged — same anti-join, same non-superseded row set — so no
-- consumer of the existing 14 columns is affected, and `check_live_sql_parity.py` stays green because
-- the definition text is byte-identical to what 143 already declares.
--
-- THIS FILE IS REQUIRED FOR DR CORRECTNESS, not just for the live fix. An apply-in-order DR rebuild
-- replays 143 (creating the view against the pre-145 column set) and then 145 (adding the columns to
-- the base table) — and would faithfully reproduce this exact bug. Re-creating the view at 198,
-- AFTER 145, is what makes the rebuild land on the correct schema.
--
-- STANDING RULE for this view and any other `SELECT *` view: adding a column to
-- `events.adversarial_reviews` does NOT propagate. Any future `ALTER TABLE ... ADD COLUMN` on that
-- table MUST be followed, in the same numbered file, by re-running the DDL below.

CREATE OR REPLACE VIEW `stock-trading-498512.state.adversarial_reviews_current` AS
SELECT *
FROM `stock-trading-498512.events.adversarial_reviews`
WHERE event_id NOT IN (
  SELECT superseded_by
  FROM `stock-trading-498512.events.adversarial_reviews`
  WHERE superseded_by IS NOT NULL
);
