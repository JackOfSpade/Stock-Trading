-- bigquery/36_strategy_arsenal_seed.sql
-- ONE-TIME SEED — the events.decision_log OWNER-DIRECTIVE entry recording the 2026-07-10 SISA
-- ("Self-Improving Strategy Arsenal") autonomy conversion: strategy addition AND deletion become
-- COMPLETELY AUTONOMOUS. This is the "source decision" that W5's strategy/roster.yaml
-- revision-history mirroring and the events.strategy_lifecycle audit trail point back to, and the
-- authorization of record for promoting the strategy_arsenal loop to active_auto in
-- ops/autonomy_levels.yaml.
--
-- NOT idempotent DDL. Unlike bigquery/01..35 (CREATE OR REPLACE, safe to re-apply in order),
-- this file writes a DURABLE decision row via ops.sp_log_decision (which also embeds it). It is
-- therefore GUARDED by a NOT-EXISTS check so re-running is a no-op, but it is NOT part of the
-- apply-in-order idempotent sequence and does NOT need to run on every DR restore. Apply it ONCE,
-- live, via the BigQuery MCP, AFTER bigquery/35_strategy_arsenal.sql (which creates the arsenal
-- objects and seeds the founding A-E events.strategy_lifecycle / state.strategy_roster rows).
-- Roster/lifecycle ROW seeding lives in 35, not here; this file is solely the governance record.
--
-- Prereqs (both pre-date 35): events.decision_log (bigquery/01_schema.sql) and ops.sp_log_decision
-- (bigquery/08_ops_procedures.sql).

IF NOT EXISTS (
  SELECT 1
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'owner-directive'
    AND entry_date = DATE '2026-07-10'
    AND title LIKE 'Owner directive 2026-07-10 — Strategy Arsenal autonomy conversion%'
) THEN
  CALL `stock-trading-498512.ops.sp_log_decision`(
    DATE '2026-07-10',                                        -- in_entry_date
    'owner-directive',                                        -- in_entry_type
    NULL,                                                     -- in_strategy (arsenal-wide, not per-strategy)
    NULL,                                                     -- in_ticker
    'AUTHORIZED',                                             -- in_decision
    NULL,                                                     -- in_conviction
    NULL,                                                     -- in_conviction_pct
    NULL,                                                     -- in_sub_pattern
    NULL,                                                     -- in_theater_check
    'Owner directive 2026-07-10 — Strategy Arsenal autonomy conversion (strategy add/delete fully autonomous)',  -- in_title
    r"""**Owner directive (2026-07-10).** Strategy **addition and deletion** are hereby **completely autonomous**: there is **no human review, approval, or chat step anywhere in the add or delete path**. The only residual human touches in the strategy lifecycle are the system-wide **IBKR order-confirm tap** (the execution layer, applied to every trade equally — e.g. a newcomer's first probe order, or a terminated strategy's liquidation orders) and **deposits**. This supersedes every prior human gate on the roster: the participant-reserved restart/successor decision (`Experiment_Parameters.md`:458-470), the strategy-design-change confirmation (`Operating_Protocols.md`:97), the user-pasted adversarial-review loop (`Operating_Protocols.md`:91-93), and the participant pre-mortem tier triage (`Experiment_Parameters.md`:412).

**Reframing of immutability (two tiers, mirroring the 2026-06 capital-allocation pivot).** Immutability was always a MEANS to a clean, uncontaminated statistical read on each strategy's edge — served by freezing each strategy's OWN machinery, not by freezing the SIZE of the roster.
- **Immutable (per strategy, for life):** entry/exit rules, thresholds, indicators, the per-thesis Capital-at-Risk budgeting discipline and the requirement for hard risk envelopes, kill-criteria structure, cited edges/disadvantages, and the strategy's pre-mortem. The fixed 2%-of-sub-portfolio fraction in this 2026-07-10 directive was retired by the owner in Rev 43 (2026-07-28): every thesis now receives a fresh, seven-factor-justified CaR budget within the then-current hard envelopes. A strategy's spec FREEZES AT SHADOW ENTRY (`spec_locked_since`) so the forward-test measures a fixed ruleset; its official edge clock (`immutable_since`) starts at its first PROBE trade. Changing a locked strategy's machinery is possible only via terminate-and-restart-as-new (fresh pre-mortem, fresh derivation, documented post-mortem).
- **Versioned policy:** roster MEMBERSHIP and N — which strategies exist and in what phase — revised through the Strategy Arsenal Lifecycle (SL1/SL2/AR_att/AR_orc/SL3/SL5), recorded in `strategy/roster.yaml`. Adding or retiring a strategy no longer "ends the experiment"; a true whole-experiment successor is reserved for a change to the measurement-and-selection MACHINERY itself (a separate owner directive).

**Compensating controls (what replaces human PR review, modeled on the D2a autonomous cutover):**
1. **Five-layer graduation pipeline** before any live capital: adversarial pre-mortem (SUFFICIENT) → SHADOW (signals only, zero capital) → PAPER (simulated fills with modeled IBKR commissions + conservative slippage vs SGOV; ≥ ~60 days, ≥ ~10 simulated closed trades, excess ≥ 0, regime coverage in ≥2 cells or a zero-coverage cell) → PROBE (live at the $2,000 probe-stake floor, using a fresh thesis-scaled CaR budget justified against the current seven-factor list and bounded by the current hard envelopes) → the existing 30-trade gate.
2. **Scrutineer independence:** SL1 synthesizes/qualifies, SL2 authors in a separate context, AR_att/AR_orc review under strict blinding, SL3 judges graduation, SL5 is the sole roster-membership writer; the theater-judge (`bigquery/11`) still applies.
3. **Default-no / default-KEEP biases:** SL1 default-REJECT on any unmet rail or ambiguity; strategy-adoption review `conservative_default=REJECT`; SL4 / strategy-retirement default-KEEP (affirmative RETIRE required); out-of-table-resolution default-HOLD-current-state.
4. **Anti-churn / anti-runaway rails** (`strategy/roster.yaml`): roster floor N≥2 / ceiling N_max=8, concurrent-incubation cap k_incubate=2, at most one adoption per rolling 90 days, post-rejection/termination/KEEP cooldowns, and the material-structural-difference + fresh-parameter-derivation restart tests (dead-strategy-laundering guard).
5. **Mechanical kill triggers UNCHANGED** (drawdown immediate; runaway-success / foundation-change / m2m via the already-autonomous AR reviews). SL4's discretionary retirement is strictly ADDITIVE, remove-only, and can never spare or continue a strategy a mechanical trigger flagged (respects `AI_Trading_Foundation.md`:384).
6. **Owner kill-switch** `ops.arsenal_control` (`enabled` / `incubation_frozen`) gated at the top of SL1-SL5 via `ops.sp_assert_arsenal_enabled`; a single out-of-band INSERT freezes all candidate generation / graduation / retirement without disturbing live trading. A PROBE launch (the capital step) additionally gates on `ops.trading_control`.
7. **Idempotency + full audit:** `ops.roster_change_log` per-change marker + a NOT-EXISTS-later-state guard in every readiness view; each transition writes `events.strategy_lifecycle` + `events.decision_log` + (consequential ones) an info-severity `ops.alerts` row delivered by `alert_emailer.gs`.
8. **CI internal-consistency gate** `scripts/check_roster_consistency.py` (a build failure on any roster drift) + full dead-man monitoring (cadence_watch / period_watch / stalled_runs) + the SL1/SL3/SL4 meta-heartbeat (`decision_log` 'evaluated, no change' every firing).

**Authorization of record.** The `strategy_arsenal` loop is promoted to **active_auto** in `ops/autonomy_levels.yaml` under this directive. SL commits are routine commits gated by the adversarial + shadow + paper controls (like the D2a auto-cutover), NOT PR-gated constant tuning, so the `no_auto_merge_self_improvement` carve-out does not apply. The owner may revert at any time by setting `ops.arsenal_control.enabled = FALSE`.""",  -- in_body_md
    '{"scope":"strategy addition and deletion — the full roster add/delete path","fully_autonomous":true,"residual_human_touches":["IBKR order-confirm tap (execution layer)","deposits"],"single_source_of_truth":"strategy/roster.yaml -> state.strategy_roster -> state.active_strategy_codes","ci_gate":"scripts/check_roster_consistency.py","kill_switch":"ops.arsenal_control (enabled / incubation_frozen) via ops.sp_assert_arsenal_enabled","autonomy_loop":"strategy_arsenal = active_auto (ops/autonomy_levels.yaml)","routines":["SL1","SL2","AR_att","AR_orc","SL3","SL4","SL5"],"graduation_pipeline":["adversarial-pre-mortem","SHADOW","PAPER","PROBE","30-trade-gate"],"rails":{"n_min":2,"n_max":8,"k_incubate":2,"adoption_rate_window_days":90},"superseded_human_gates":["Experiment_Parameters.md:458-470","Experiment_Parameters.md:412","Operating_Protocols.md:91-93","Operating_Protocols.md:97"],"mechanical_kills":"unchanged"}',  -- in_fields_json
    ['strategy/roster.yaml', 'bigquery/35_strategy_arsenal.sql', 'ops/autonomy_levels.yaml#strategy_arsenal', 'Experiment_Parameters.md:458-470', 'Operating_Protocols.md:97', 'AI_Trading_Foundation.md:384'],  -- in_refs
    ['owner-directive', 'strategy-arsenal', 'SISA', 'autonomy', 'governance', 'immutability-rewrite', 'roster'],  -- in_tags
    NULL,                                                     -- in_superseded_by
    'owner-directive 2026-07-10'                              -- in_source_session
  );
END IF;
