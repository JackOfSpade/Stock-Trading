{#
  SGOV forward-fill: a missing SGOV daily return (r_sgov IS NULL for a given date) forward-fills from
  the most recent known r_sgov instead of reading as a hard 0 -- mirroring ops.sp_recompute_engine's
  forward-fill for the same "a missing mark must not read as 0" reason.

  2026-07-04 audit finding (dbt-internal only -- expands to the exact same COALESCE/LAST_VALUE text, no
  compiled-SQL change): this block was copy-pasted near-verbatim across strategy_vs_park_daily.sql,
  sgov_cumulative.sql, and deployed_book_vs_sgov.sql, differing only in partition/order columns -- a
  silent-divergence risk if one copy is edited and the others are missed.

  Args:
    r_sgov_col: the SGOV return column reference to forward-fill (e.g. `sg.r_sgov`).
    order_col: the date column to order the forward-fill window by (e.g. `sdr.as_of_date`).
    partition_col: optional partition column (e.g. `sdr.strategy`); omit for an unpartitioned window.
#}
{% macro sgov_forward_fill(r_sgov_col, order_col, partition_col=none) -%}
COALESCE(
  {{ r_sgov_col }},
  LAST_VALUE({{ r_sgov_col }} IGNORE NULLS) OVER (
    {%- if partition_col %}
    PARTITION BY {{ partition_col }}
    {%- endif %}
    ORDER BY {{ order_col }}
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
  0)
{%- endmacro %}
