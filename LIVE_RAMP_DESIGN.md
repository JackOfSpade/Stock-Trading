# Live-ramp sizing for newcomer strategies — owner-review design, v1 (2026-10-19)

**Amended 2026-10-25 (section 9, owner directive):** SHADOW (≥ 5 days) and PAPER are RESTORED in front of the
ramp; sections 2 and 6 describe the rev 20 lifecycle and are superseded by section 9 where they disagree.

**Status:** owner directive 2026-10-19 (interactive session). Replaces the SHADOW → PAPER → PROBE
→ 30-trade-gate incubation pipeline with a single live state whose capital grows continuously with
evidence. Implemented the same day; this file is the design record the prose (Experiment_Parameters.md
rev 20, Strategy.md Rev 51, Claude_Task_Plan.md SL1/SL3/SL5/M4/D2/D2a) and the SQL
(`bigquery/259_live_ramp.sql`) derive from. It is a design record, not an operating surface: routines
read the prose and the views, never this file.

## 1. What the owner asked for, in their words, and what it changes

- "I do not want a non-trading probe; I want a forward test with real money as soon as it is confirmed
  likely to be profitable in theory." → SHADOW and PAPER are retired. A candidate that clears
  adversarial review enters **PROBE** directly and trades real money from its first signal.
- "There is no way I can wait 30 years for every new strategy idea." → The flat 30-trade
  PROBE → ADOPTED graduation gate is retired, and with it the 30-trade success-threshold termination.
- "Deploy a strategy that is good in theory at small size and ramp up little by little as it proves
  itself … a dynamic ramp rather than a fixed staircase, so I can see progress each trade … de-ramp the
  same way." → Capital is a continuous function of a per-strategy **ramp score** that moves on every
  closed trade.
- "The starting amount should be dynamic based on current portfolio size." → The floor is NAV-relative
  with a cost-viability minimum under it.
- "Fast, frequent-trade strategies should take long; rare-trade strategies faster." Corrected and
  agreed: the ramp is paid for in evidence, not trades or calendar days. A small-edge trade moves the
  score a little, a large-edge trade a lot; overlapping trades are discounted so one tape cannot buy
  the whole ramp. No regime-diversity rule (the owner rejected it: strategies are designed for one cell).
- "Evaluate how strongly the AI believes a strategy is profitable and set the starting point
  dynamically." → An opening score from a checkable rubric, never a self-reported confidence, capped
  by evidence quality, and logged against the realized ramp so the rubric calibrates over time.
- "AI can backtest with a proper harness." → Backtests are accepted evidence when contamination-safe
  (post-cutoff window, masked tickers and dates, placebo-controlled). Most of this system's strategies
  are not backtestable (judgment inputs have no clean history), so the ramp runs on **declared**
  parameters and the backtest, where one exists, only raises the opening score.

What is deliberately **not** changed: the drawdown kill, the mark-to-market review, the runaway-success
review, the foundation-change path, SL4 discretionary retirement, the `ops.arsenal_control` kill switch,
the n_min/n_max/k_incubate/adoption-window rails, the adversarial review, the spec freeze (it moves from
SHADOW entry to PROBE entry, which is now the same moment), and the IBKR confirm tap.

## 2. Lifecycle after this change

```
CANDIDATE → QUALIFYING → AUTHORING → UNDER_REVIEW → PROBE (live ramp) → ADOPTED
                                                   ↘ REJECTED            ↘ RETIREMENT_PROPOSED → TERMINATED
```

- **UNDER_REVIEW → PROBE** is fired by SL5 branch (1) on `state.strategy_adoption_readiness.ready`
  (SUFFICIENT verdict, judge-independent, caps, ceiling, arsenal switch, not already transitioned; the
  idempotency marker becomes `<code>:UNDER_REVIEW->PROBE`). SL5 writes the lifecycle row, the
  roster.yaml flip, the fanout, **and the strategy's `ops.strategy_ramp_params` row**. It raises
  `strategy_probe_registered` (existing roster notice, emailed).
- **PROBE** is the live ramp. `spec_locked_since = immutable_since = PROBE entry`. The strategy trades
  under its own rules at a deployment cap set by its ramp score (section 4). It is `is_active`, so every
  existing per-strategy mechanism (NAV bucket, kills, router, reports) applies unchanged.
- **PROBE → ADOPTED** is fired when `state.strategy_ramp.graduation_ready` (score reached 1.0). SL3
  enqueues `PENDING_ROSTER` `item_type='adopt-register'`; SL5 branch (2) drains it (lifecycle row,
  roster.yaml `adopted`, `strategy_graduated` notice). ADOPTED lifts the cap; nothing else changes.
- **SHADOW / PAPER** remain legal historical states in the enum and in `scripts/check_roster_consistency.py`
  (no row ever carried them; none will). Their readiness and stuck views (`bigquery/52`, `60`, `189`)
  stay deployed and read empty forever; they are not deleted because landed SQL is never rewritten.
- **k_incubate** now counts strategies in PROBE (the ramping set) instead of SHADOW + PAPER, so "at most
  two concurrent incubations" keeps its meaning. The adoption window (one PROBE entry per 90 days) is
  unchanged.

## 3. The ramp score

One number per strategy in PROBE, `score ∈ [0, 1]`, recomputed deterministically from closed trades.
Nothing updates it in place: `state.strategy_ramp` derives it on every read from
`analytics.position_campaigns` and `ops.strategy_ramp_params`, so there is no row to get stale and the
full history is reconstructible.

### 3.1 Parameters (`ops.strategy_ramp_params`, latest row per code)

| column | meaning | default |
|---|---|---|
| `mu_per_trade` | declared expected net return per closed campaign (fraction of cost basis) | required, > 0 |
| `sigma_per_trade` | declared per-campaign return standard deviation | required, > 0 |
| `tail_loss_5pct` | declared 5th-percentile campaign return; a trade at or below it is a **surprise** | `mu − 1.645·sigma` |
| `holding_horizon_days` | declared typical holding period | required |
| `opening_score` | section 5 rubric output | required, in [0, 0.4] |
| `calibration_trades` | in-line trades from 0 to 1 at full weight | 10 |
| `loss_asymmetry` | multiplier on a losing trade's decrement | 2.0 |
| `surprise_cut` | multiplier applied to the score on a surprise | 0.5 |
| `surprise_window_trades` | a second surprise within this many trades drops the score to 0 | 5 |
| `floor_pct_nav` | NAV-relative floor | 0.02 |
| `cost_min_usd` | cost-viability minimum under the floor | 2000 |
| `sprt_alpha`, `sprt_beta` | sequential-test error rates for the evidence kill | 0.05, 0.20 |
| `rubric_json` | the rubric components that produced `opening_score` | required |

Written once by SL5 at PROBE entry from the candidate's declarations (SL1 STEP 3 writes them to
`state.strategy_candidates`; SL2 cites them in the section). Append-only; a later row supersedes.

### 3.2 Trades

A trade is a closed, non-dust `analytics.position_campaigns` row of the strategy with
`entry_date ≥ DATE(immutable_since)`, ordered by `exit_date, entry_date, campaign_key`.
`r = realized_pnl / (entry_price × total_shares_bought)`.

**Overlap weight.** `w = 1 / (1 + n_overlap)` where `n_overlap` is the number of other such trades of
the same strategy whose `[entry_date, exit_date]` intersects this trade's. Ten trades open at once on one
tape carry roughly the evidence of one.

### 3.3 Sequential update (the exact algorithm; `scripts/ramp_calc.py` and `analytics.fn_ramp_path` implement it byte-for-byte)

```
s = opening_score; cum_llr = 0; last_surprise = None
for i, trade in enumerate(trades, start=1):
    llr = (r*mu - mu*mu/2) / (sigma*sigma)        # log-likelihood ratio N(mu,σ) vs N(0,σ)
    cum_llr += llr                                 # unweighted: the statistical record
    if r <= tail_loss_5pct:                        # surprise
        s = 0 if (last_surprise and i - last_surprise <= surprise_window_trades) else s * surprise_cut
        last_surprise = i; inc = 0
    else:
        raw = (r / mu) / calibration_trades
        if r < 0: raw *= loss_asymmetry
        inc = w * clip(raw, -0.5, +0.15)
        s = clip(s + inc, 0, 1)
    evidence_kill      = cum_llr <= ln(beta / (1 - alpha))      # −1.558 at the defaults
    evidence_confirmed = cum_llr >= ln((1 - beta) / alpha)      # +2.773 at the defaults
```

Properties, so nobody re-derives them:

- An exactly in-line trade (`r = mu`, no overlap) adds 0.10; ten of them carry 0 → 1. Graduation compares the score rounded to 10 decimal places (ten increments of 0.1 are 0.9999999999999999 in binary floating point; the view, the UDF consumers and `ramp_summary` all round the same way). That is the
  owner's calibration point, not a promise about noisy reality.
- With noise the drift per trade is slower and scales with the declared edge. For a strategy that
  performs exactly as declared, expected trades from 0.2 to 1.0:

  | `mu/sigma` | expected trades to full |
  |---|---|
  | 0.50 | ≈ 13 |
  | 0.33 | ≈ 33 |
  | 0.00 (no edge, declared edge 0.33σ) | drifts to the floor in ≈ 2 trades |

  Rare, large-edge strategies ramp in few trades; frequent, small-edge strategies need many, which they
  collect quickly. Neither reaches full size without the evidence.
- Ordinary losses subtract twice what ordinary wins add. A surprise (worse than the declared 5th
  percentile) halves the score at once; a second within five trades drops it to the floor. This is the
  "nine wins then a big loss" case: after the loss the next trade runs at half the size that hurt.
- `score = 0` is the floor, not death. A strategy is terminated only by the existing kills or by the
  **evidence kill**: the sequential probability ratio test's lower boundary on `cum_llr`, which fires
  when the realized record is strong evidence against the declared edge. It lands in `perf.kill_flags`
  as `evidence_kill` beside `drawdown_kill`, so D1's daily kill sweep and M4 §H act on it through the
  unchanged termination path. `gate_reached` stays on the view for history and drives nothing.

## 4. Capital

```
book_nav        = SUM(nav) over analytics.strategy_nav
floor_usd       = GREATEST(cost_min_usd, floor_pct_nav × book_nav)
full_usd        = book_nav / active_count                        # the equal share the deposit split already uses
deployable_cap  = floor_usd + score × GREATEST(0, full_usd − floor_usd)
headroom_usd    = deployable_cap − deployed_mv
```

- The cap bounds a PROBE strategy's **total deployed market value**. A thesis whose notional exceeds
  `headroom_usd` is sized down to it; below the cost minimum per trade it is not crafted. ADOPTED
  strategies have no cap, as today. Nothing resizes an open position.
- Capital is sourced exactly as today: the strategy's own NAV bucket, then
  `analytics.fn_nomadic_capital_restore_plan` from other strategies' idle funds. The FIFO
  "frozen until deposits fill $2,000" rule is retired: a newcomer may pull its floor from idle funds at
  its first trade. `state.strategy_probe_funding_gap` keeps reporting the shortfall against the
  **dynamic** floor as information; it freezes nothing.
- At the 2026-10-19 book (~$13k, five active strategies) `full_usd ≈ $2.6k` and `floor_usd = $2,000`,
  so the ramp spans only ~$600 today. The design is for the book this is meant to grow into; at
  today's size a newcomer is effectively at its floor until the book grows, and that is stated here so
  nobody reads a flat score-to-dollars line as a defect.

## 5. Opening score

A rubric, each component checkable, mapped to `opening_score ∈ [0, 0.4]`:

| component | 0 | 0.5 | 1 |
|---|---|---|---|
| backtest strength | none | component or literature only | pooled, placebo-controlled, multiple-testing corrected, ≥ 95th placebo percentile |
| evidence breadth | one market, one period | two of {markets, periods, cross-sections} | three |
| harness coverage of the judgment layer | none | prospective paper book started | post-cutoff, masked, scored vs the mechanical base |
| mechanism class | classical pattern with an AI wrapper | mixed | Part-1 AI edge is the return driver |
| cost margin at the floor | < 1.5× the cost rail | 1.5–3× | > 3× |
| adversarial review | SUFFICIENT after ≥ 3 cycles or any Tier-1 on the edge | 2 cycles | 1 cycle, no Tier-1 on the edge |
| redundancy with the live roster | high | moderate | low |

`opening_score = 0.4 × mean(components)`, floored at 0 for a mechanism with no backtest **and** no paper
book (it deploys at the floor). Non-backtestable mechanisms therefore cap near 0.2. Every opening score
is written with its `rubric_json`, and `state.strategy_ramp_calibration` pairs it with the realized score
after `calibration_trades` trades; W5 reads that view in its scorecard. This is the calibration data the
foundation document names as the deliverable of this phase.

## 6. Routines

| routine | before | after |
|---|---|---|
| SL1 STEP 3 | qualifies; declares frequency/roundtrips | also declares `mu`, `sigma`, `tail_loss_5pct`, `holding_horizon_days` and scores the rubric; writes them to `state.strategy_candidates` (new nullable columns); no 30-trade arithmetic in rail (iii) |
| SL2 route (A) | authors section + pre-mortem | section carries a **Ramp declaration** block citing the four parameters and the rubric |
| SL3 (daily) | forward-test series, SHADOW→PAPER, PAPER→PROBE enqueue, culls | **ramp monitor**: reads `state.strategy_ramp`; on `graduation_ready` enqueues `adopt-register`; on a new surprise raises `ramp_surprise_cut` (email-only notice); on a cap breach raises `ramp_cap_breached`; heartbeat unchanged |
| SL5 branch (1) | UNDER_REVIEW→SHADOW | UNDER_REVIEW→PROBE + `ops.strategy_ramp_params` row + full fanout |
| SL5 branch (2) | PAPER→PROBE on `probe-register` | PROBE→ADOPTED on `adopt-register` |
| M4 §H | 30-trade gate termination | evidence kill; no gate |
| D1 daily kill sweep | drawdown/runaway/m2m | + `evidence_kill` |
| D2 / D2a sizing | per-strategy NAV base, seven-factor CaR | + for a PROBE strategy, notional ≤ `headroom_usd` from `state.strategy_ramp` |
| D2 PENDING-NEWCOMER FROZEN CHECK | freeze below $2,000 funded | retired; replaced by the ramp cap |

## 7. SQL objects (`bigquery/259_live_ramp.sql`)

- `ops.strategy_ramp_params` (table, append-only).
- `ALTER TABLE state.strategy_candidates ADD COLUMN IF NOT EXISTS` ×5 (declared parameters, rubric JSON).
- `analytics.fn_ramp_path` (JavaScript UDF): the section 3.3 algorithm over an ordered trade array.
- `analytics.strategy_ramp_trades` (view): the per-trade path with weights, increments, score after.
- `state.strategy_ramp` (view): one row per PROBE strategy — score, trades_n, cum_llr, floor/full/cap/
  headroom in dollars, `graduation_ready`, `evidence_kill`, `evidence_confirmed`, `last_surprise_idx`.
- `state.strategy_ramp_calibration` (view): opening score vs realized score at `calibration_trades`.
- `state.arsenal_rails` (replace): `incubating_count` counts PROBE.
- `state.strategy_adoption_readiness` (replace): marker `UNDER_REVIEW->PROBE`.
- `perf.kill_flags` (replace): adds `evidence_kill`.
- `ops.alert_policy` rows: `ramp_surprise_cut`, `ramp_cap_breached` (notices, closed by SL3 on the next fire).
- dbt mirrors for every `state.`/`perf.` view touched.

## 8. Verification

- `scripts/ramp_calc.py` is the reference implementation; `tests/test_ramp_calc.py` pins the section 3.3
  properties on fixed vectors (`tests/fixtures/ramp_vectors.json`). The JavaScript UDF is checked
  against the same vectors live in BigQuery before the file lands.
- Existing gates unchanged: `check_roster_consistency`, `check_handoff_contracts` (new write target,
  NOT NULL columns named in SL5), `check_adopt_gate_coverage`, `check_dbt_view_coverage`, dbt parity,
  live SQL parity, slice generators, pytest.

## 9. Amendment 2026-10-25: SHADOW and PAPER restored in front of the ramp (EP rev 21, Strategy.md Rev 54)

**What the owner asked for.** On 2026-10-25 the owner restored a no-capital forward test before real money, with
these steps: SHADOW for at least 5 trading days of non-trading signals; PAPER for at least 60 days and 10
simulated trades; then the live ramp described above. In the same session the owner accepted these recommendations:
PAPER also requires simulated excess return of at least zero; 6 concurrent SHADOW/PAPER slots instead of 2;
monthly SL1 synthesis instead of quarterly; one live entry per 30 days instead of per 90. The reason given: with a
forward test that costs no capital back in place, the arsenal should be testing many more AI-edge candidates,
while most of the frequent strategies sit out the current regime.

**Lifecycle after this amendment.**

```
CANDIDATE → QUALIFYING → AUTHORING → UNDER_REVIEW → SHADOW → PAPER → PROBE (live ramp) → ADOPTED
                                                   ↘ REJECTED  ↘ REJECTED ↘ REJECTED ↘ RETIREMENT_PROPOSED → TERMINATED
```

| transition | fired by | gate | marker |
|---|---|---|---|
| UNDER_REVIEW → SHADOW | SL5 branch (1) | `state.strategy_adoption_readiness.ready` | `<code>:UNDER_REVIEW->SHADOW` |
| SHADOW → PAPER | SL3 STEP 3 (self-executes) | `state.strategy_shadow_readiness.ready`: ≥ 5 shadow trading days, signal rate in band, zero scaffolding faults | `<code>:SHADOW->PAPER` |
| PAPER → PROBE | SL3 enqueues `probe-register`, SL5 branch (2) | `state.strategy_paper_readiness.ready`: ≥ 60 paper days, simulated-trade floor (10 for ≥ 10 declared round-trips a year), trailing-10-day excess ≥ 0, regime coverage, adoption window, n_max | `<code>:PAPER->PROBE` |
| PROBE → ADOPTED | SL3 R2 enqueues `adopt-register`, SL5 branch (4) | `state.strategy_ramp.graduation_ready` (score 1.0) | `<code>:PROBE->ADOPTED` |

**What stays exactly as sections 3 to 5 describe.** PROBE opens at the ramp floor with the rubric opening score.
`immutable_since` is PROBE entry, and `analytics.strategy_ramp_trades` reads only live campaigns from that date, so
simulated PAPER trades never move the ramp score. The evidence kill and the other mechanical kills are unchanged. The
30-trade gate stays retired.

**What moved.**
- `spec_locked_since` returns to SHADOW entry. `state.strategy_roster` (bigquery/70) already takes the first
  SHADOW/PAPER/PROBE/ADOPTED row, so no SQL change was needed for it.
- `state.arsenal_rails` (bigquery/266): `incubating_count` counts SHADOW+PAPER again; `k_incubate` 2 → 6;
  `adoption_rate_window_days` 90 → 30 (and the matching `probes_in_window` interval). Live capital is bounded by
  n_max (PROBE counts as active) and that window, not by `k_incubate`.
- `state.strategy_shadow_readiness` (bigquery/266): floor 20 → 5 shadow trading days.
- `state.strategy_adoption_readiness` (bigquery/266): marker back to `UNDER_REVIEW->SHADOW`.
- `state.strategy_paper_readiness` (bigquery/189): unchanged. It reads the new window through `state.arsenal_rails`.
- SL5: branch (1) SHADOW register (restored); branch (2) PROBE register (restored, plus the `ops.strategy_ramp_params`
  row and a ramp-floor `capital_usd`); branch (4) ADOPT register (rev 20's branch (2), renumbered).
- SL3: STEPS 1–4 restored, R1–R4 kept, then STEP 5.
- SL1: monthly on the 2nd at 21:00 UTC (`0 21 2 * *`, was `0 21 2 1,4,7,10 *`); `depends_on [Q1, Q3]` kept, because
  `ops.sp_assert_deps` windows a quarterly dependency to the calendar quarter.
- `scripts/check_roster_consistency.py` R-E now reads the rail constants from the canonical `state.arsenal_rails`
  file (the highest-numbered definer) instead of `bigquery/35`, which had been superseded since bigquery/259.

**Known open item carried forward.** SL3 STEP 2's `regime_met` pin records a W5 trigger: the term is vacuous on the
first graduation, and it must be resolved before the first PAPER → PROBE enqueue. Rev 20 made that unreachable; this
amendment makes it reachable again, no earlier than about 65 trading days after the first SHADOW registration.
