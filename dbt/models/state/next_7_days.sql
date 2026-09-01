-- Parallel-run dbt port of bigquery/14_weekly_report.sql:state.next_7_days — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT 'QUEUE_DUE' AS category, item_key AS ref, ticker, strategy, due_date
FROM {{ ref('open_queue') }}
WHERE due_date BETWEEN CURRENT_DATE('America/Denver')
                    AND DATE_ADD(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
UNION ALL
SELECT 'TIME_EXIT' AS category, position_key AS ref, ticker, strategy, time_exit_date AS due_date
FROM {{ ref('current_positions') }}
WHERE status = 'OPEN' AND strategy != 'D'  -- D runs to thesis-invalidation, no time exit
  AND time_exit_date BETWEEN CURRENT_DATE('America/Denver')
                          AND DATE_ADD(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
UNION ALL
SELECT 'ORDER_WINDOW' AS category, item_key AS ref, ticker, strategy, entry_window_close AS due_date
FROM {{ ref('open_orders') }}
WHERE entry_window_close BETWEEN CURRENT_DATE('America/Denver')
                              AND DATE_ADD(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
ORDER BY due_date
