# Foundation-change re-review checklist

**Finding STRUCTURAL, whole-system deep audit 2026-07-17.** The root pattern behind the two 2026-07-17
CRITICALs: the 2026-07-15 **SGOV→VOO park cutover was a foundation change that silently invalidated
SGOV-era calibrated constants** (the −15% book-drawdown breaker, the D2a ±15% NAV connector-sanity
band, the benchmark assumptions) with nothing forcing a re-review. A −15% peak-to-trough is a
catastrophe in a ~0-vol SGOV book but an ORDINARY correction once ~97% of NAV is VOO equity — yet the
constant carried across the vehicle change unexamined (see `bigquery/78_book_drawdown_rebase_and_staleness_gate.sql`'s
WHY).

This checklist makes that re-validation **mechanical and in-band**. It is NOT a new human gate: no
approval, no confirm-tap, no chat question. It is a completion requirement on the routine that ACTIONS
a foundation change — run the applicable rows, re-validate/re-calibrate each, and log completion to
`events.decision_log` (`entry_type='foundation-change-review'`). The wiring lives in
`Claude_Task_Plan.md` (Q4 section B — FOUNDATION-CHANGE ASSESSMENT), and the park-vehicle cutover step
in `Operating_Protocols.md` §13 points here.

## When to run it

Run this checklist whenever ANY of these four **foundations** changes — whether the change is surfaced
by a Q3 foundation-change verdict (drained in Q4/D2), executed via the `Operating_Protocols.md` §13
park-policy cutover, or applied by an A3 `AI_Trading_Foundation.md` edit:

1. **Park vehicle** — the cash-parking instrument (`state.park_policy_current`; SGOV → VOO 2026-07-15,
   or any future change).
2. **Benchmark** — the excess-return / beta reference (SGOV total-return, SPY, VOO; e.g.
   `bigquery/39_beta_adjusted_alpha.sql`, `bigquery/46_weekly_benchmarks.sql`).
3. **Model version** — the operating LLM generation (per `AI_Trading_Foundation.md` "On what actually
   transfers forward": model-specific numerical calibration does NOT transfer and must be re-derived).
4. **Regime vocabulary** — the `strategy/01_shared_regime_vocabulary.md` axis tokens / cells (the
   regime-cell strings SL1/SL3/M1a and `state.arsenal_regime_coverage` join on).

## Checklist — which calibrated constants / bands / vocabularies to re-validate

For the change class(es) that apply, confirm each item is still correct for the NEW foundation, and
re-calibrate (land a new numbered `bigquery/NN_*.sql` per the supersede discipline, or edit the owning
prose) any that no longer hold. Record each item's disposition (unchanged-and-why / re-calibrated-to-X)
in the decision-log entry.

### A. Park-vehicle change (e.g. SGOV → VOO)
- [ ] **Book-drawdown breaker tiers** — the −15% soft (`breach_soft`, entries-only) and −40% hard
      (`breach_hard`, full-halt) thresholds in `state.book_drawdown_watch`
      (`bigquery/78_book_drawdown_rebase_and_staleness_gate.sql`). Are they still appropriate for the new
      vehicle's volatility (an equity park makes an ordinary correction breach an SGOV-era rail)?
- [ ] **D2a connector-sanity NAV band** — the ±15% day-over-day NLV move that HALTs D2a
      (`Claude_Task_Plan.md` D2a `connector_sanity`). Still right given the new vehicle's daily vol?
- [ ] **Mark-discontinuity threshold** — the >25% day-over-day tripwire in
      `state.mark_discontinuity_watch` (`bigquery/82_split_aware_engine.sql`) covers the new vehicle's
      ticker (VOO/SGOV/SPY are in its watched set); confirm the threshold is not routinely tripped by
      the new vehicle's normal moves.
- [ ] **Park-order guard band** — `analytics.fn_order_guard`'s `p_is_park` price band (read live from
      `state.park_policy_current`: 0.2% SGOV / 0.5% other) matches the new vehicle's spread.
- [ ] **Cash-tripwire / dwell economics** — the §13 $25 sweep floor rationale + the commission model
      (`Operating_Protocols.md` §13; VOO commission still UNVERIFIED as of 2026-07-15 — keep the
      larger-of fallback) and the $1 reconciliation tolerance (a higher per-share price is a tighter
      share-count margin — expected, not a retune).
- [ ] **Benchmark/park-beta assumptions** downstream of the park vehicle (see B).

### B. Benchmark change
- [ ] **Excess-vs-park / beta-adjusted alpha** — `bigquery/39_beta_adjusted_alpha.sql`,
      `analytics.strategy_vs_park*`, `bigquery/46_weekly_benchmarks.sql` reference the correct benchmark
      series; the interim-underperf `excess_vs_sgov <= -15%` kill-adjacent warning
      (`bigquery/03_twr_engine.sql`) is beta-adjusted to the current benchmark, not a retired one.
- [ ] **Weekly self-email** benchmark series (`ops/weekly_report/`) matches the live benchmark.
- [ ] **daily_marks benchmark tickers** — the unconditional SGOV/SPY/VOO ingest + completeness check
      (`Claude_Task_Plan.md` D2a step 1) includes the new benchmark so a silent ingest stop is caught.

### C. Model-version change
- [ ] **Numerical calibration re-derivation** — hit rates, bias magnitudes, conviction-tier posteriors
      (`analytics.calibration_summary`, `find_precedents` tiers) are treated as tagged historical record
      for the PRIOR model and re-derived from the new model's own data, not inherited
      (`AI_Trading_Foundation.md` "On what actually transfers forward").
- [ ] **Mistake catalog** re-tagged as "model X exhibited this" rather than carried as predictions about
      the new model.
- [ ] **Process / workflow / taxonomy** artifacts confirmed to transfer as-is (these DO transfer).

### D. Regime-vocabulary change
- [ ] **Regime-cell token set** — the `strategy/01_shared_regime_vocabulary.md` axis tokens are the
      single source; SL1 `target_regime_cells`, SL3 incubation `regime_cell`, M1a strategy-blind
      scoring, and `state.arsenal_regime_coverage` all join on the SAME tokens joined by `/`
      (`Claude_Task_Plan.md` SL1 STEP 2 / SL3 STEP 1, H7).
- [ ] **Per-strategy activation rules** in `Strategy.md` / `strategy/02_regime_router.md` still
      reference valid vocabulary tokens.
- [ ] **Router / M1a scoring** SQL and `events.regime_events` values use the new vocabulary consistently.

## Completion record

Write one `events.decision_log` entry via `CALL ops.sp_log_decision(...)`:
`entry_type='foundation-change-review'`, naming the foundation(s) changed, the checklist rows evaluated,
each row's disposition (unchanged-and-why / re-calibrated-to-X with the landing `bigquery/NN` file or
prose edit), and the change's source (Q3 verdict / §13 cutover / A3 edit). The entry IS the record that
the re-review ran — its absence for a foundation change is itself the detectable gap.
