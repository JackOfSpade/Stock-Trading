-- Parallel-run dbt port of bigquery/10_observability.sql:state.gate_watch — canonical source is that file until owner cutover.
-- Conviction-model 30-closed-trade gate proximity (watch-only, advisory). Don't build the
-- model now (single-class / overfits); just surface how close each strategy is to the gate.

SELECT
  strategy, closed_trades, gate_reached,
  GREATEST(0, 30 - closed_trades) AS closed_to_gate,
  closed_trades >= 25 AS approaching_gate
FROM {{ ref('kill_flags') }}
ORDER BY closed_trades DESC
