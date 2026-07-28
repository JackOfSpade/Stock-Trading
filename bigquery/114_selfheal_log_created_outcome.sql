-- ops.parity_selfheal_log gains a THIRD outcome value: 'created' (2026-07-28 owner directive).
-- Project: stock-trading-498512. Apply after 69_live_sql_parity_selfheal.sql.
--
-- PROBLEM (doc-only -- no structural change, `outcome` is and remains a bare STRING with no CHECK
-- constraint): bigquery/69's table OPTIONS description documents `outcome` as `applied|failed` only,
-- matching what D3's CI-FINDINGS ADJUDICATION step could produce at the time -- a re-apply of a
-- drifted-but-still-live object (branches (a)/(b)/(c)) either succeeds (`applied`) or doesn't
-- (`failed`). OWNER DIRECTIVE 2026-07-28 supersedes the design that kept `scripts/
-- check_live_sql_parity.py`'s `missing_objects` category out of self-heal reach: D3 gains a new
-- branch (d) (Claude_Task_Plan.md, CI-FINDINGS ADJUDICATION & LIVE-SQL-PARITY SELF-HEAL) that
-- autonomously CREATEs an object the checker found genuinely absent live, gated by the DROP-guard +
-- the existing persistence/latch/10-object rails described there -- and logs its own outcome to this
-- same table via `outcome='created'` (a create error still logs `outcome='failed'`, unchanged). A
-- third value the table's own description doesn't mention would leave a future reader of this table
-- guessing whether `created` is a typo or a real, sanctioned value -- this file closes that gap the
-- same way bigquery/57/79 kept `ops.monitor_health_history.check_id`'s column description in sync
-- with the values `bigquery/45/57/79` actually write, extended here to a SECOND target: this is also
-- the first genuine per-column `SET OPTIONS` description on `outcome` (bigquery/69's original header
-- comment -- `-- outcome: 'applied' | 'failed'.` -- was prose above the CREATE TABLE, not queryable
-- DDL metadata; INFORMATION_SCHEMA.COLUMNS/COLUMN_FIELD_PATHS can now answer "what are the legal
-- values of outcome" without reading the source file).
--
-- QUOTING: both description strings below use a DOUBLE-quoted delimiter (mirroring bigquery/57's and
-- bigquery/79's identical `check_id` column-description precedent) so the many embedded apostrophes
-- ('applied', 69's, 114's, did not, ...) need no escaping at all -- bigquery/README.md's Schema quick
-- reference already flags that BigQuery REJECTS `''`-style apostrophe escaping (use `\'` or triple
-- quotes instead); switching the delimiter sidesteps the question entirely, same as 57/79 did.
--
-- Idempotent (ALTER ... SET OPTIONS); safe to re-run. No backfill needed -- every existing row's
-- `outcome` is already `applied` or `failed`, both still valid under the extended vocabulary.

-- First genuine column-level description for `outcome` (bigquery/69 never had one -- see header).
ALTER TABLE `stock-trading-498512.ops.parity_selfheal_log`
  ALTER COLUMN outcome SET OPTIONS (description = "'applied' | 'failed' | 'created' -- 'created' added 2026-07-28 for D3 CI-FINDINGS ADJUDICATION branch (d), autonomous CREATE of a declared-but-absent object");

-- Table-level OPTIONS description, RESTATED from bigquery/69 with the outcome vocabulary extended
-- (applied|failed -> applied|failed|created) and "re-apply" generalized to "re-apply/create" wherever
-- the original text described what a row records.
ALTER TABLE `stock-trading-498512.ops.parity_selfheal_log`
  SET OPTIONS (description = "Append-only live-SQL-parity self-heal latch/idempotency log (live-sql-parity self-heal audit 2026-07-16, RES-3, issue #10; delivery path rewired to the ops.ci_findings / state.ci_findings_open bridge 2026-07-17/18 -- see bigquery/69's file header; outcome vocabulary extended to include 'created' 2026-07-28, owner directive -- see bigquery/114's file header). One row per D3 re-apply/create attempt for a (dataset, object) finding surfaced by state.ci_findings_open (workflow=live-sql-parity, per-object finding_key) -- a drift finding is re-applied (branches (a)/(b)/(c)), a MISSING finding (detail starts 'MISSING: ') is created (branch (d)). outcome=applied|failed|created. D3 latch-checks the last 7 days of heal_date before re-applying OR creating; a re-flagged/still-absent object already in this window within 7 days means the heal did not converge and is NOT re-applied/re-created again (comparator/competing-writer investigation, or for a MISSING object a create that silently did not take, instead).");
