-- ITEM: latest-wins "curated" dedup views have no deterministic tiebreaker when ingest_ts ties
-- exactly (2026-07-14 self-improvement audit, finding sql-early#2).
--
-- BUG: state.daily_marks_curated (bigquery/03_twr_engine.sql) is
-- `QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY ingest_ts DESC) = 1`.
-- ingest_ts is `TIMESTAMP DEFAULT CURRENT_TIMESTAMP()`, and BigQuery evaluates CURRENT_TIMESTAMP()
-- ONCE PER QUERY — so every row inserted by a single multi-row INSERT statement shares the
-- identical ingest_ts. The view's own header comment explicitly anticipates "a re-ingested day
-- (crashed / re-run session)" producing duplicate (ticker, mark_date) rows and relies on "latest
-- ingest wins" to resolve them — but if the duplicate rows for the SAME (ticker, mark_date) land in
-- the SAME INSERT statement (e.g. a catch-up re-ingest that accidentally includes an already-loaded
-- day), their ingest_ts ties exactly and ROW_NUMBER()'s pick among tied rows is UNDEFINED per
-- BigQuery's docs — the view could silently return the OLD (wrong) close/dividend value on one
-- query execution and the NEW one on the next, with no code change in between. This is exactly the
-- "ambiguous ORDER BY tie in a latest-wins view" class this codebase has already hardened against
-- elsewhere (state.current_regime's explicit `event_id DESC` tiebreaker, bigquery/01_schema.sql).
-- The identical pattern recurs in state.trade_fills_curated (keyed on trade_id, which is naturally
-- unique, so lower risk — fixed here anyway for defense-in-depth/consistency) and
-- state.macro_fred_latest (keyed on metric/ref_month, no natural unique id — fixed here with the
-- same row_uid pattern as daily_marks).
--
-- Confirmed via a live read-only query (2026-07-14) that no such duplicate currently exists in
-- events.daily_marks — this is a LATENT, not-yet-triggered gap, fixed prophylactically.
--
-- FIX: add a `row_uid STRING DEFAULT GENERATE_UUID()` column to events.daily_marks and
-- events.macro_fred (does NOT backfill existing rows; they get NULL row_uid, which is fine since no
-- current duplicates exist to disambiguate), then add it as a secondary ORDER BY tiebreaker in the
-- three curated views below. trade_fills_curated adds `trade_id DESC` instead (already unique per
-- fill, no ALTER needed).
--
-- BUG FIX (2026-07-15, caught applying this file live): the original single-statement
-- `ADD COLUMN IF NOT EXISTS row_uid STRING DEFAULT GENERATE_UUID()` fails on an already-existing
-- table with `Add field with default value to an existing table schema is not supported` — BigQuery
-- only allows a defaulted ADD COLUMN at CREATE TABLE time; adding a defaulted column to a table that
-- already exists must be split into ADD COLUMN (no default) + a separate ALTER COLUMN SET DEFAULT,
-- exactly as the error message's own suggested fix says. Deliberately NOT taking the error message's
-- 3rd suggested statement (`UPDATE ... SET row_uid = GENERATE_UUID() WHERE TRUE`) — that would
-- backfill every existing row, which this file's original design explicitly decided against (see
-- above: no current duplicates exist, so NULL row_uid on old rows is fine and a full-table UPDATE is
-- unnecessary cost). Both dry-run-verified (0 bytes, no error) against live events.daily_marks and
-- events.macro_fred before landing this fix.
--
-- SUPERSEDES the state.daily_marks_curated VIEW in bigquery/03_twr_engine.sql, the
-- state.trade_fills_curated VIEW in bigquery/01_schema.sql, and the state.macro_fred_latest VIEW in
-- bigquery/07_fred_macro.sql. dbt/models/state/daily_marks_curated.sql and
-- dbt/models/state/trade_fills_curated.sql get the IDENTICAL secondary ORDER BY column added in the
-- same commit so the live view and its dbt-parity mirror can never resolve a real future tie
-- differently (scripts/dbt_parity.py). macro_fred_latest has no dbt mirror. Apply after
-- 01_schema.sql, 03_twr_engine.sql, 07_fred_macro.sql, 46_weekly_benchmarks.sql.

ALTER TABLE `stock-trading-498512.events.daily_marks`
  ADD COLUMN IF NOT EXISTS row_uid STRING;

ALTER TABLE `stock-trading-498512.events.daily_marks`
  ALTER COLUMN row_uid SET DEFAULT GENERATE_UUID();

ALTER TABLE `stock-trading-498512.events.macro_fred`
  ADD COLUMN IF NOT EXISTS row_uid STRING;

ALTER TABLE `stock-trading-498512.events.macro_fred`
  ALTER COLUMN row_uid SET DEFAULT GENERATE_UUID();

CREATE OR REPLACE VIEW `stock-trading-498512.state.daily_marks_curated` AS
SELECT * FROM `stock-trading-498512.events.daily_marks`
QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY ingest_ts DESC, row_uid DESC) = 1;

CREATE OR REPLACE VIEW `stock-trading-498512.state.trade_fills_curated` AS
SELECT * FROM `stock-trading-498512.events.trade_fills`
QUALIFY ROW_NUMBER() OVER (PARTITION BY trade_id ORDER BY ingest_ts DESC, trade_id DESC) = 1;

CREATE OR REPLACE VIEW `stock-trading-498512.state.macro_fred_latest` AS
SELECT metric, ref_month, value, source, fetched_ts
FROM `stock-trading-498512.events.macro_fred`
QUALIFY ROW_NUMBER() OVER (PARTITION BY metric, ref_month ORDER BY fetched_ts DESC, row_uid DESC) = 1;
