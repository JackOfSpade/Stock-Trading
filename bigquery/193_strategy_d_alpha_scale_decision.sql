-- bigquery/193_strategy_d_alpha_scale_decision.sql
-- ONE-TIME SEED — the events.decision_log OWNER-DIRECTIVE entry recording the 2026-08-21 correction
-- of Strategy D's beta-adjusted-alpha edge-decay test: its point-estimate comparison moves from the
-- MONTHLY OLS-intercept scale to the spec's CUMULATIVE 24-month scale. This is the "source decision"
-- that strategy/roster.yaml's D revision_history entry of the same date (and the recomputed D
-- spec_hash it carries) points back to.
--
-- CODIFICATION FIX, not a machinery change: the -3pp threshold, its CI gate, and every word of the
-- governing spec text are UNCHANGED — only the scale on which the already-stated threshold is
-- evaluated is corrected, bringing strategy_math/strategy_d.py to what Strategy.md / strategy/08_
-- pre_mortems.md already said. No entry/exit rule, indicator, router rule, sizing rule or kill
-- criterion moves, and this is NOT a terminate-and-restart (is_restart_of / spec_locked_since
-- untouched).
--
-- NOT idempotent DDL. Unlike bigquery/01..NN's CREATE OR REPLACE files (safe to re-apply in order),
-- this file writes a DURABLE decision row via ops.sp_log_decision (which also embeds it). It is
-- therefore GUARDED by a NOT-EXISTS check so re-running is a no-op, but it is NOT part of the
-- apply-in-order idempotent sequence and does NOT need to run on every DR restore. Apply it ONCE,
-- live, via the BigQuery MCP.
--
-- Prereqs: events.decision_log (bigquery/01_schema.sql), ops.sp_log_decision — whose canonical
-- definition is bigquery/116_decision_record_analyzability.sql (superseding bigquery/08_ops_
-- procedures.sql) — and state.decision_log_current (bigquery/144_decision_log_correction_consumers.sql),
-- which the guard below reads.
--
-- GUARD READS state.decision_log_current, NOT the raw events.decision_log. The earlier one-time
-- owner-directive seeds (bigquery/36, /55, /101) probe the base table and are named individually in
-- scripts/check_superseded_by_discipline.py's ALLOWLIST under '<file-level statements>'; reading the
-- final-effective view instead keeps this file inside that blocking check with no allowlist entry to
-- maintain, and answers the same question, because the append-only correction convention has a
-- correction row REPRODUCE the record it supersedes — an obsolete original is hidden by the view but
-- its replacement carries the same (entry_type, entry_date, title), so a re-apply is still a no-op.

IF NOT EXISTS (
  SELECT 1
  FROM `stock-trading-498512.state.decision_log_current`
  WHERE entry_type = 'owner-directive'
    AND entry_date = DATE '2026-08-21'
    AND title LIKE 'Owner directive 2026-08-21 — Strategy D alpha-test scale correction%'
) THEN
  CALL `stock-trading-498512.ops.sp_log_decision`(
    DATE '2026-08-21',                                        -- in_entry_date
    'owner-directive',                                        -- in_entry_type
    'D',                                                      -- in_strategy
    NULL,                                                     -- in_ticker
    'AUTHORIZED',                                             -- in_decision
    NULL,                                                     -- in_conviction
    NULL,                                                     -- in_conviction_pct
    NULL,                                                     -- in_sub_pattern
    NULL,                                                     -- in_theater_check
    'Owner directive 2026-08-21 — Strategy D alpha-test scale correction (monthly intercept -> cumulative 24-month)',  -- in_title
    r"""**Owner directive (2026-08-21).** Strategy D's `beta_adjusted_alpha_test` point-estimate comparison is corrected from the **monthly-intercept scale** to the spec's **cumulative-24-month scale**. The CI-bound clause is UNCHANGED. The spec text is UNCHANGED — this directive moves the CODE to the spec, not the spec to the code.

**What was wrong.** `strategy_math/strategy_d.py` compared `reg.alpha` — the intercept of an OLS on MONTHLY returns, i.e. mean alpha PER MONTH (`strategy_math/common.py`: `alpha = mean(y) - beta*mean(x)`) — against `BETA_ADJUSTED_ALPHA_FIRE_THRESHOLD = -0.03`. The governing text states that threshold on the CUMULATIVE scale. Strategy.md's §D Section 4 edge-decay bullet — byte-identical to the Strategy D segment of `strategy/08_pre_mortems.md` (rev 5), both of which are hashed into D's `spec_hash` — computes the metric as "(iii) compare cumulative deployed TWR to cumulative synthetic; (iv) the alpha differential (Jensen's alpha equivalent at 24 months) is the alpha-test metric", and states condition (a) as "alpha point estimate ≤ -3pp **cumulative over 24 months**". The same bullet's own SE figure ("SE ±4.5pp", derived as typical β̂ noise of ±0.2 SE × cumulative SPY return ~0.22) is a cumulative-scale quantity too — roughly 24× a monthly-intercept SE. `strategy/06_strategy_d.md`'s Classical-method-delegation restatement ("alpha = TWR − synthetic", against the 24-month deployed TWR) says the same thing more briefly, and it was that shorter sentence the module's docstring had quoted.

**Impact of the defect.** Condition (a) was roughly 24× too strict: firing required a monthly intercept ≤ -3pp, i.e. a cumulative 24-month shortfall near -72pp (linear) / -52% (compounded). The alpha-test therefore never fired in practice — a silent FAIL-OPEN on an edge-decay/kill indicator. Reproduced directly against the module: a 24-month series with cumulative alpha -3.05pp and a 95% upper CI bound of -0.11pp satisfies BOTH spec conditions (a) and (b), yet `fires` returned False. Impact was LATENT rather than realized: `beta_adjusted_alpha_test` has no consumer outside the test suite today — its designated consumer is D's 24-month comprehensive review (~2028-04) — so no live decision was affected, and the correction runs toward MORE sensitivity on a kill trigger, never less.

**The correction (arithmetic aggregation, chosen deliberately over compounding).** The code now computes `cumulative_alpha = reg.alpha * reg.n` and tests condition (a) against that. Under the spec's own arithmetic aggregation this identity is EXACT, not an approximation: OLS residuals sum to zero, so `sum(TWR) − β̂·sum(SPY) == n·alpha`, which is precisely the spec's "cumulative deployed TWR minus cumulative synthetic". Compounding (`(1+alpha)^n − 1`, the form `bigquery/39_beta_adjusted_alpha.sql` uses to annualize its per-period intercept in the sibling SGOV-relative generalization) was considered and NOT adopted here, because the linear form is provably identical to the spec's stated computation and the spec's own SE derivation is linear.

**What is explicitly UNCHANGED.**
- The threshold VALUE (-3pp) and the CI upper bound (0pp). No number moves.
- Condition (b), the CI-bound clause: `upper_ci_95 = alpha + 1.645·alpha_se` stays on the regression's own per-month scale. "95% upper CI bound on alpha ≤ 0pp" is a SIGN test, invariant under a positive rescale, and alpha and alpha_se are directly comparable only on the same scale.
- Every word of `Strategy.md`, `strategy/06_strategy_d.md` and `strategy/08_pre_mortems.md`. No spec text was edited in either direction.
- D's entry/exit rules, indicators, router rule, sizing rule and kill criteria. This is NOT a terminate-and-restart: `is_restart_of` and `spec_locked_since` are deliberately untouched.

**What else landed in the same unit.** `AlphaTestResult` gains a `cumulative_alpha` slot so a reporting caller quotes the spec's own "alpha differential at 24 months" rather than re-deriving it. `strategy/roster.yaml`'s D `spec_hash` is recomputed (`strategy_math/strategy_d.py` is an R-F hash input, so the code change alone would fail `scripts/check_roster_consistency.py`) with a revision_history entry of this date. A regression test in `tests/test_strategy_math.py` pins a fixture whose cumulative alpha is -3.05pp while its monthly intercept is only ~-0.13pp — it fires only under the corrected reading — plus a clearly-not-firing complement; the four pre-existing alpha tests keep their verdicts unchanged.""",  -- in_body_md
    '{"scope":"Strategy D beta_adjusted_alpha_test point-estimate comparison","change":"monthly OLS intercept -> cumulative 24-month alpha differential","aggregation":"arithmetic (cumulative_alpha = reg.alpha * reg.n; exact under zero-sum OLS residuals)","aggregation_rejected":"compounded ((1+alpha)^n - 1)","threshold_value_unchanged":-0.03,"ci_clause_unchanged":true,"ci_upper_bound":0.0,"spec_text_unchanged":true,"machinery_change":false,"classification":"codification fix","restart":false,"fail_direction_before":"fail-open (flag effectively never fired; required ~-72pp cumulative)","live_impact":"latent — no consumer outside tests; designated consumer is D 24-month comprehensive review","files":["strategy_math/strategy_d.py","strategy/roster.yaml","tests/test_strategy_math.py"],"spec_hash_recomputed":"D"}',  -- in_fields_json
    ['strategy_math/strategy_d.py', 'strategy/roster.yaml', 'tests/test_strategy_math.py', 'strategy/06_strategy_d.md', 'strategy/08_pre_mortems.md#Pre-mortem: Strategy D', 'bigquery/39_beta_adjusted_alpha.sql'],  -- in_refs
    ['owner-directive', 'strategy-d', 'alpha-test', 'edge-decay', 'spec-lock', 'codification-fix', 'spec-hash-recompute'],  -- in_tags
    NULL,                                                     -- in_superseded_by
    'owner-directive 2026-08-21'                              -- in_source_session
  );
END IF;
