-- Retry/dependency-wait telemetry: parse the machine tokens routines append to ops.run_log.note
-- (owner directive 2026-07-18, TRANSIENT-FAILURE WAIT-AND-RETRY + DEPENDENCY-WAIT WINDOW v2 in
-- Claude_Task_Plan.md's preamble). Project: stock-trading-498512. Apply after 10_observability.sql
-- (ops.run_log, whose `note` column this reads).
--
-- PROBLEM: the WAIT-AND-RETRY ladder and the DEPENDENCY-WAIT WINDOW both let a routine ride out a
-- transient failure or an unsatisfied dependency in-session instead of halting — good for
-- reliability, but invisible to W5's PROCESS-RELIABILITY REVIEW unless something parses the outcome
-- back out of free-text notes. Routines now append machine-parseable tokens to `ops.run_log.note`
-- alongside the human narrative:
--   RETRY[kind=<slug>;n=<int>;waited_s=<int>;outcome=<word>]
--   DEPWAIT[dep=<word>;polls=<int>;waited_s=<int>;outcome=<word>;refired=<word>]
--   INCIDENT[ref=<uuid-ish string>]
-- A single run can legitimately hit MORE THAN ONE of these in one note (e.g. a BigQuery transient
-- AND a separate IBKR blip in the same session) — a plain REGEXP_EXTRACT (single match) would
-- silently drop every occurrence after the first (an adversarial-review finding on this file's first
-- draft). This view uses REGEXP_EXTRACT_ALL + UNNEST so every token occurrence in a note produces
-- its own output row.
--
-- FIX: one row per token occurrence. Each token-type extraction regex requires the FULL, exact,
-- in-order field grammar (closing bracket included) — a token missing its closing bracket, or with
-- fields out of order or missing, simply does not match and is silently dropped (the token grammar is
-- machine-written by the routines themselves per Claude_Task_Plan.md, so a non-match means a bug in
-- the emitting routine, not a class of input this view needs to tolerate). Integer fields (n / polls /
-- waited_s) are SAFE_CAST so a garbage or empty value yields NULL rather than aborting the query.
--
-- Window: WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 90 DAY) — same
-- partition-pruning pattern as bigquery/27_process_reliability.sql's routine_health_scorecard.
-- ops.run_log.note is nullable; NULL notes are filtered out before tokenizing (REGEXP_EXTRACT_ALL on
-- NULL would return NULL, and UNNEST of a NULL array already drops the row, so this filter is a
-- clarity/perf no-op, not a correctness requirement).

CREATE OR REPLACE VIEW `stock-trading-498512.state.retry_telemetry` AS
WITH tokenized AS (
  SELECT routine, run_date, log_ts, session_id, note
  FROM `stock-trading-498512.ops.run_log`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 90 DAY)
    AND note IS NOT NULL
),
retry_rows AS (
  SELECT
    routine, run_date, log_ts, session_id,
    'RETRY' AS token_type,
    REGEXP_EXTRACT(token, r'kind=([^;\]]+);') AS kind,
    SAFE_CAST(REGEXP_EXTRACT(token, r';n=([^;\]]+);') AS INT64) AS n,
    SAFE_CAST(REGEXP_EXTRACT(token, r';waited_s=([^;\]]+);') AS INT64) AS waited_s,
    REGEXP_EXTRACT(token, r';outcome=([^;\]]+)\]') AS outcome,
    CAST(NULL AS STRING) AS refired,
    CAST(NULL AS STRING) AS related_alert_id
  FROM tokenized,
    UNNEST(REGEXP_EXTRACT_ALL(note, r'RETRY\[kind=[^;\]]+;n=[^;\]]+;waited_s=[^;\]]+;outcome=[^;\]]+\]')) AS token
),
depwait_rows AS (
  SELECT
    routine, run_date, log_ts, session_id,
    'DEPWAIT' AS token_type,
    REGEXP_EXTRACT(token, r'dep=([^;\]]+);') AS kind,
    SAFE_CAST(REGEXP_EXTRACT(token, r';polls=([^;\]]+);') AS INT64) AS n,
    SAFE_CAST(REGEXP_EXTRACT(token, r';waited_s=([^;\]]+);') AS INT64) AS waited_s,
    REGEXP_EXTRACT(token, r';outcome=([^;\]]+);') AS outcome,
    REGEXP_EXTRACT(token, r';refired=([^;\]]+)\]') AS refired,
    CAST(NULL AS STRING) AS related_alert_id
  FROM tokenized,
    UNNEST(REGEXP_EXTRACT_ALL(note, r'DEPWAIT\[dep=[^;\]]+;polls=[^;\]]+;waited_s=[^;\]]+;outcome=[^;\]]+;refired=[^;\]]+\]')) AS token
),
incident_rows AS (
  SELECT
    routine, run_date, log_ts, session_id,
    'INCIDENT' AS token_type,
    CAST(NULL AS STRING) AS kind,
    CAST(NULL AS INT64) AS n,
    CAST(NULL AS INT64) AS waited_s,
    CAST(NULL AS STRING) AS outcome,
    CAST(NULL AS STRING) AS refired,
    REGEXP_EXTRACT(token, r'ref=([^;\]]+)\]') AS related_alert_id
  FROM tokenized,
    UNNEST(REGEXP_EXTRACT_ALL(note, r'INCIDENT\[ref=[^;\]]+\]')) AS token
)
SELECT routine, run_date, log_ts, session_id, token_type, kind, n, waited_s, outcome, refired, related_alert_id FROM retry_rows
UNION ALL
SELECT routine, run_date, log_ts, session_id, token_type, kind, n, waited_s, outcome, refired, related_alert_id FROM depwait_rows
UNION ALL
SELECT routine, run_date, log_ts, session_id, token_type, kind, n, waited_s, outcome, refired, related_alert_id FROM incident_rows;
