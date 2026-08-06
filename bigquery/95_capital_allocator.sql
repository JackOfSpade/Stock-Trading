-- bigquery/95_capital_allocator.sql — AI Capital-Allocation Call: the read/audit view over the
-- rail-bounded AI judgment call that replaces the fixed equal split of a strategy-termination
-- redistribution's or a deposit's post-newcomer-floor remainder. Project: stock-trading-498512.
--
-- NUMBERING NOTE: the task spec that authorized this file named it `bigquery/94_capital_allocator.sql`.
-- At authoring time, `bigquery/94_catchup_refire_blocked_policy.sql` already existed, uncommitted, in
-- this working tree (a concurrent, unrelated in-flight change — RemoteTrigger-missing-from-
-- allowed_tools incident policy, OWNER_ACTIONS.md 2026-07-19 item) — confirmed via `git status`
-- showing it untracked alongside OTHER uncommitted edits to OWNER_ACTIONS.md and bigquery/78 that this
-- session did not make. Rather than overwrite or renumber someone else's in-progress, differently-
-- scoped work, this file takes the next free slot, 95. Nothing in this file depends on 94 or is
-- depended on by it; apply in either order, any time after bigquery/01_schema.sql.
--
-- Spec: AI_DECISION_REDESIGN.md §3 Redesign A (owner verdict 2026-07-19) — implements the AI
-- capital-allocation call described in Operating_Protocols.md §16 and wired inline in
-- Claude_Task_Plan.md's D2 STRATEGY TERMINATIONS (step 5) / AR_orc's m2m-termination handler / D2's
-- §13.C deposit-recording flow. Every call is logged as an events.decision_log row
-- (entry_type='capital-allocation') carrying a `fields` JSON payload; this file's ONLY object is the
-- read view over that payload — no new table, no new procedure, and NOTHING here CHOOSES an
-- allocation for real capital. The rails that bound the call (never choose it) live in prose only
-- (Operating_Protocols.md §16): each survivor clamped to [0.5x, 2x] its equal share, default-EQUAL
-- below MEDIUM conviction. This mirrors bigquery/92_park_allocator.sql's item 3
-- (state.park_allocation_recent / _latest) closely — same "parse `fields` JSON via JSON_VALUE"
-- convention, same entry_type-keyed events.decision_log read — generalized here to an UNNEST over a
-- per-call array (one row per {call, survivor}) since a capital-allocation call is inherently
-- multi-strategy where a park-allocation call is single-vehicle.
--
-- fields JSON schema written by CALL ops.sp_log_decision(..., entry_type='capital-allocation', ...)
-- (D2 §5 / AR_orc / §13.C — Claude_Task_Plan.md, Operating_Protocols.md §16):
--   {
--     "trigger":          "termination" | "deposit",
--     "conviction":       "HIGH" | "MEDIUM" | "LOW",
--     "conviction_pct":   <NUMERIC 0-100>,
--     "is_default_equal": <BOOL>,               -- TRUE = below-MEDIUM-conviction / HOLD fallback fired
--     "winner_code":      "<strategy_code>",     -- top-allocated survivor
--     "runner_up_code":   "<strategy_code>",     -- second-highest allocated survivor
--     "total_dollars":    <NUMERIC>,             -- the remainder being allocated (post newcomer-floor fill)
--     "invalidation":     "<text>",
--     "theater_check":    "<text>",
--     "allocations": [
--       {"strategy_code": "<code>", "pct": <NUMERIC, sums to 100 across the array>, "dollars": <NUMERIC>},
--       ...                                       -- one entry per currently-active survivor
--     ]
--   }
-- `rationale` (why `winner_code` beats `runner_up_code`) is the decision_log row's native `body_md`
-- column, not a fields key — this view's fields-JSON columns are the single source of truth for every
-- OTHER structured field of the call, so exactly one payload is authoritative for those, never split
-- redundantly across native columns and JSON (contrast bigquery/92_park_allocator.sql, whose
-- `theater_check` the task spec there left ungenerated into `fields` at all — a known gap in that
-- file, out of scope here; this file's OWN `theater_check` is written into `fields` deliberately, per
-- the schema above).
--
-- Zero-row-safe by construction: entry_type='capital-allocation' has never been written as of this
-- file's authoring (terminations: zero so far, per AI_DECISION_REDESIGN.md §3's own staging note; no
-- deposit capital-allocation call has fired either) — `state.capital_allocation_calls` is EXPECTED to
-- read back empty today. That is the correct, not-broken state; do not treat an empty read as a bug
-- (verified live via the readonly BigQuery MCP at authoring time: zero decision_log rows of this
-- entry_type exist).
-- ============================================================================
-- SUPERSEDED LIVE by bigquery/144_decision_log_correction_consumers.sql — current single source of truth
-- for this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation: its `calls` CTE reads events.decision_log directly, so a superseded capital-allocation call would
-- be scored twice by W5's CAPITAL-ALLOCATION SCORECARD.
CREATE OR REPLACE VIEW `stock-trading-498512.state.capital_allocation_calls` AS
WITH calls AS (
  SELECT
    entry_id,
    entry_date,
    event_ts,
    body_md                                                        AS rationale,
    JSON_VALUE(fields, '$.trigger')                                AS trigger,
    JSON_VALUE(fields, '$.conviction')                             AS conviction,
    SAFE_CAST(JSON_VALUE(fields, '$.conviction_pct') AS NUMERIC)   AS conviction_pct,
    SAFE_CAST(JSON_VALUE(fields, '$.is_default_equal') AS BOOL)    AS is_default_equal,
    JSON_VALUE(fields, '$.winner_code')                            AS winner_code,
    JSON_VALUE(fields, '$.runner_up_code')                         AS runner_up_code,
    SAFE_CAST(JSON_VALUE(fields, '$.total_dollars') AS NUMERIC)    AS total_dollars,
    JSON_VALUE(fields, '$.invalidation')                           AS invalidation,
    JSON_VALUE(fields, '$.theater_check')                          AS theater_check,
    JSON_QUERY_ARRAY(fields, '$.allocations')                      AS allocations
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'capital-allocation'
)
-- One row per {call, survivor}. W5's CAPITAL-ALLOCATION SCORECARD bullet (Claude_Task_Plan.md) reads
-- `deviation_pct` — the call's own equal-split counterfactual, computed from THIS call's own
-- allocations-array length (the active-survivor count AS OF that historical call), never a live join
-- back to state.strategy_roster's CURRENT membership, which could differ from what this call actually
-- saw (a later termination/adoption must never revise an earlier call's counterfactual — the same
-- as-of-the-flow's-own-date discipline bigquery/22_cash_flows.sql's analytics.strategy_nav uses for
-- historical equal-split divisors).
SELECT
  entry_id,
  entry_date,
  event_ts,
  trigger,
  conviction,
  conviction_pct,
  is_default_equal,
  winner_code,
  runner_up_code,
  total_dollars,
  invalidation,
  theater_check,
  rationale,
  JSON_VALUE(alloc, '$.strategy_code')                                                  AS strategy_code,
  SAFE_CAST(JSON_VALUE(alloc, '$.pct') AS NUMERIC)                                        AS pct,
  SAFE_CAST(JSON_VALUE(alloc, '$.dollars') AS NUMERIC)                                    AS dollars,
  100.0 / ARRAY_LENGTH(allocations)                                                       AS equal_share_pct,
  SAFE_CAST(JSON_VALUE(alloc, '$.pct') AS NUMERIC) - (100.0 / ARRAY_LENGTH(allocations))  AS deviation_pct
FROM calls, UNNEST(allocations) AS alloc;
