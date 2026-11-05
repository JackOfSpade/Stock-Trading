CALL `stock-trading-498512.ops.sp_stage_decision_part`(
  'cb7a075850ab0925e780fdeece52c2f976f711dade4cc32943e90c1606800127',  -- in_call_sha256
  'fields',  -- in_arg_name
  8,  -- in_part_no
  8,  -- in_n_parts
  'beafeb91beba305f0112ba3b943958fd2e2195e5b5dd817417e1d890ce7f32e3',  -- in_part_sha256
  '04 close) chains to the 2026-11-04 event_close 26.01 (Nasdaq discovery basis) of the same name and anchor 2026-11-04 in the landed 2026-11-04 row (7701d3bc), coded POST_MOVE_EVENT there; the anchor is after-close 2026-11-04, so the pair legitimately chains forward to reaction session 2026-11-05 and that disposition is consistent, not contradicted."},"note":"CROSS-ROW CLOSE-CHAIN: 12 landed single-'
  'name-move rows (entry_date 2026-10-20..2026-11-04) read from state.decision_log_current. Every hit is a name coded POST_MOVE_EVENT in the 2026-11-04 row (own filing accepted after the 11-04 close, anchor 2026-11-04) that now passes with an after-close 2026-11-04 anchor and reaction session 2026-11-05: its prior_close equals that row\'s event_close (to Nasdaq-vs-IBKR rounding), so the chain is a le'
  'gitimate forward chain, not a session-late pair. No pre-open/intraday-anchor hit, so no re-take. Prior dispositions (POST_MOVE_EVENT) are consistent with today\'s pass. Not a clearance for the unmeasured names."}}'  -- in_payload
);
