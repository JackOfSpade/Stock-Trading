{#
  halt_echo: the halt_echo_md / halt_echo_mr CTE pair shared by every trading-gate model that excludes
  'missing_dependency' / 'missed_run' critical alerts that are pure fallout of an already-known,
  still-open trading halt, so they don't double-count as an INDEPENDENT reason to keep trading blocked.

  DEDUPLICATED 2026-08-31 (code-quality pass, dbt#2): this ~50-line pair's LOGIC was copy-pasted across
  trading_enabled.sql, trading_enabled_mechanical.sql, and (already source()-ified)
  b3_trading_enabled_check.sql -- exactly the class of duplication dbt/macros/sgov_forward_fill.sql's
  own header already documents fixing once, for the SGOV forward-fill block, for the same reason: a
  future edit to the halt-echo exclusion logic has to be applied by hand in every copy, and missing one
  is invisible until the byte-identical-wording trap trading_enabled.sql's own DRIFT FIX 2026-07-18
  comment warns about (for a different field in the same query) bites again. That logic HAS changed 3
  times already per trading_enabled.sql's header (97's missing_dependency exclusion, 107's missed_run
  exclusion, 176's embeddings-health removal) -- extracted here so the next change lands once.

  CORRECTION (2026-08-31, same pass): the three pre-dedup copies were never byte-identical.
  `git show HEAD:dbt/models/state/b3_trading_enabled_check.sql` shows b3's copy carried these two CTEs
  with ZERO inline comments, while trading_enabled.sql and trading_enabled_mechanical.sql both carried
  the ~10-line rationale block reproduced below. Compiling b3 against this macro therefore GAINS those
  ~10 comment lines into its compiled output (verified with `dbt compile --target ci`) -- a real,
  benign compiled-text change for that one model, not the no-op the file's own header used to claim.
  The underlying CTE LOGIC (the SELECT/JOIN/WHERE text) was already identical across all three; only
  the comment coverage differed.

  Emits BOTH CTEs, source()-ified, with a trailing comma so it splices directly into a model's WITH
  clause ahead of whatever CTE consumes halt_echo_md / halt_echo_mr, e.g.:
      WITH ctrl AS (...),
      f AS (...),
      {{ halt_echo() }}
      al AS (
        SELECT COUNTIF(... AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
                        AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)) AS blocking_criticals
        FROM {{ source('ops', 'alerts') }}
      )
#}
{% macro halt_echo() -%}
halt_echo_md AS (
  -- missing_dependency alerts that are pure fallout of a same-day, still-open trading halt:
  -- every dep in payload.missing_deps has an OPEN trading_halted alert (source = dep) whose
  -- Denver date equals this alert's payload.run_date. Fail-closed: any parse failure or
  -- unmatched dep keeps the alert blocking, and a NULL alert_id is excluded outright — left
  -- in, it would make the downstream blocking-criticals NOT IN return NULL for every row and
  -- fail the gate OPEN. Delimiter ', ' matches sp_assert_deps' STRING_AGG(d, ', ') and
  -- sp_auto_resolve_alerts Rule 1's SPLIT.
  SELECT a.alert_id
  FROM {{ source('ops', 'alerts') }} a,
       UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
  LEFT JOIN {{ source('ops', 'alerts') }} th
    ON th.category = 'trading_halted'
   AND NOT th.resolved
   AND th.source = dep
   AND DATE(th.alert_ts, 'America/Denver') =
       SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missing_dependency'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(th.alert_id IS NOT NULL)
),
halt_echo_mr AS (
  -- 'missed_run' critical alerts that are pure fallout of an already-known trading-gate halt.
  -- (A) reuses Rule 2's completion test; (B) correlates the latest halted attempt to a
  -- trading_halted alert within the load-bearing 24-hour bound from bigquery/107.
  SELECT a.alert_id
  FROM {{ source('ops', 'alerts') }} a,
       UNNEST(JSON_QUERY_ARRAY(a.payload)) AS item
  LEFT JOIN {{ source('ops', 'run_log') }} r
    ON r.routine = JSON_VALUE(item, '$.routine') AND r.status = 'completed'
       AND r.run_date >= SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.today'))
  LEFT JOIN (
    SELECT routine, MAX(log_ts) AS last_halt_ts
    FROM {{ source('ops', 'run_log') }}
    WHERE status = 'halted'
    GROUP BY routine
  ) hr ON hr.routine = JSON_VALUE(item, '$.routine')
  LEFT JOIN {{ source('ops', 'alerts') }} th
    ON th.category = 'trading_halted'
       AND hr.last_halt_ts IS NOT NULL
       AND ABS(TIMESTAMP_DIFF(th.alert_ts, hr.last_halt_ts, HOUR)) <= 24
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missed_run'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(r.routine IS NOT NULL OR th.alert_id IS NOT NULL)
),
{%- endmacro %}
