# Regime State

Current regime measurements, per-strategy activation states, and router history for the AI-directed trading experiment. Read by daily scans, weekly research sessions, monthly reviews, and adversarial divergence reviews.

> **⚠ Rev 35 cap-removal note (2026-05-30):** Per owner directive, Strategy.md rev 35 removes ALL holdings-**count** caps across A/B/C/D (3-per-GICS-sector for A/B/C; D's 10-position / theme / correlation-bucket caps). Dated router-history lines below that mention "N/5", "1/3 sector cap", "N/10", etc. are **historical state notes, not active rules** — no count cap applies to any strategy as of rev 35. Retained: D's 30%-of-NAV sector *exposure* cap, D's minimum-5 floor, the 2%-per-position size cap, all kill triggers. See Decision_Log 2026-05-30 + Operating_Protocols §10.

**Last updated:** 2026-04-26 (B and D first trades staged for Mon 2026-04-27 execution; C scaffolding complete; M2 follow-ups for C dispersion-compression and E signal-process tightening initiated this session — see Decision_Log.md 2026-04-26)
**Next scheduled technical update:** Daily (mechanical, end of each US trading day)
**Next scheduled fundamental update:** 2026-05-01 (first trading day of May)

---

## Current Technical Signal States

Computed per the shared regime vocabulary in Strategy.md. All values as of 2026-04-22 close (latest retrievable primary-source data as of M1 review).

| Indicator | Value | State |
|-----------|-------|-------|
| SPY close | 708.44 | — |
| SPY 50-day SMA | ~666 | below 200-day |
| SPY 200-day SMA | ~657–673 (vendor range) | — |
| **SPY Trend State** | SPY > 50-day but 50-day < 200-day | **NEUTRAL** |
| VIX close | 19.42 | **NORMAL** (15–25) |
| 10Y UST yield | ~4.30% | — |
| 2Y UST yield | ~3.79% | — |
| **Yield Curve State** | 10Y > 2Y | **NORMAL** (not inverted) |
| Prior inversion period | 2022-10-25 to 2024-12-12 (~26 months, ended) | — |
| **Yield Curve Sustained Inversion Flag** | Currently positive; no ≥18-month active inversion | **NOT-SUSTAINED** |
| % S&P 500 constituents above own 200-day SMA | ~59% (2026-04-20 MacroMicro) | — |
| **Equity Breadth State** | ≥50% | **HEALTHY** |

**Data caveats:**
- SPY 50-day and 200-day SMAs span vendor ranges; qualitative conclusion (50-day below 200-day → NEUTRAL) is robust across the range.
- End-of-March 2026 precise VIX close and breadth figures not independently verified from primary sources; March intraday VIX peaked 31.05 on 2026-03-27.
- VIX and breadth inputs used here are latest available (April 22), treated as proxy for current technical regime.

---

## Current Per-Strategy Activation States

Per M1 monthly review (2026-04-23). Each strategy has an independent activation rule combining a technical signal and a fundamental signal per Strategy.md.

### Strategy A — Catalyst-driven equity long

- **Technical signal:** DO-NOT-ACTIVATE
  - Rule: SPY Trend = UP AND Breadth = HEALTHY
  - Current: SPY Trend = NEUTRAL → first clause fails
- **Fundamental signal (M1):** DO-NOT-ACTIVATE
  - Macro-dominated tape; catalyst-specific pricing suppressed by war/oil/yield vectors
- **Divergence:** NO
- **Current activation state:** DO-NOT-ACTIVATE
- **Effect on book:** No new A entries permitted. Existing A positions (none) would run to normal exits.

### Strategy B — Post-event mispricing

- **Technical signal:** ACTIVATE
  - Rule: SPY Trend ≠ DOWN AND VIX ≠ HIGH
  - Current: SPY Trend = NEUTRAL (≠ DOWN); VIX = NORMAL (≠ HIGH) → both pass
- **Fundamental signal (M1):** ACTIVATE
  - High-volatility tape with geopolitical overshoot conditions; mean-reversion setup above average
- **Divergence:** NO
- **Current activation state:** ACTIVATE
- **Effect on book:** New B entries permitted subject to Strategy.md entry criteria. Pre-mortem and foundation-change assessment gates cleared 2026-04-25. **First trade staged 2026-04-26: IBM long limit BUY 0.1198 @ $232.50, day order Mon 2026-04-27.** NOW declined on criterion 4 (adversarial counter-argument). Post-Monday: if filled, B has 1/5 open positions, IT Services 1/3 sector cap; if not filled, re-evaluate Tue with 7 trading days remaining in 10-day post-event window.

### Strategy C — Defined-risk options around known events

- **Technical signal:** ACTIVATE
  - Rule: SPY Trend ≠ DOWN
  - Current: SPY Trend = NEUTRAL → passes
- **Fundamental signal (M1):** DO-NOT-ACTIVATE
  - Macro shocks dominating individual-catalyst dynamics; event-trading environment not functional this cycle
- **Divergence:** YES (Tech ACTIVATE / Fund DNA)
- **Adversarial review outcome (2026-04-25):** HYBRID — see Decision_Log.md entry "Strategy C divergence review"
- **Current activation state:** HYBRID ACTIVATE
  - **FOMC events: ACTIVATE** — affirmative case decisive on internal inconsistency in fundamental DNA (FOMC IS the macro catalyst the DNA reasoning names as dominating, not an "individual catalyst" suppressed by macro)
  - **Corporate earnings: DO-NOT-ACTIVATE** — fundamental DNA reasoning survives (cross-sectional dispersion compression in stagflation-squeeze regimes; AI_Edges 2.13 miscalibration compounds directional thesis quality)
  - **FDA PDUFA: DO-NOT-ACTIVATE** — no specific affirmative made; macro-domination doesn't change biotech-specific risk profile; revisit at M2
  - **Vol-directional theses across all event types: DO-NOT-ACTIVATE** — strategy spec doesn't constrain to long-vol-only; activating vol-directional in elevated-IV regime authorizes short-vol exposure the strategy isn't structured for; punt to strategy spec revision
- **Theater-check flag (review):** CONVERGENT — incognito attacker and orchestrating-session review reach same HYBRID verdict with same scope decomposition
- **Effect on book:** New C entries permitted ONLY for FOMC events meeting all standard entry criteria (Strategy.md Section "Strategy C: Entry criteria" 1-5). At current portfolio size ($6,946), 2% sizing cap = $139 max loss per structure; most FOMC theses likely defer per the deferral mechanism until portfolio grows. Pre-mortem and foundation-change assessment gates cleared 2026-04-25. **Operational blocker resolved 2026-04-26**: classical-method options-math scaffolding (`c_options_math.py`) built, hardened across critical evaluation cycle (1 issue + 5 design warnings all addressed), 14 self-tests pass. Next FOMC catalyst: 2026-06-16/17. M2 follow-up underway: empirical dispersion-compression check supporting potential earnings re-routing at next M2 cycle.

### Strategy D — Long-horizon narrative core

- **Technical signal:** ACTIVATE
  - Rule: (SPY Trend = UP OR NEUTRAL) AND Yield Curve Sustained Inversion = NOT-SUSTAINED
  - Current: SPY Trend = NEUTRAL; flag = NOT-SUSTAINED → both pass
- **Fundamental signal (M1):** ACTIVATE
  - Secular theses intact; no sustained inversion; no confirmed recession; AI/earnings concentration durable
- **Divergence:** NO
- **Current activation state:** ACTIVATE
- **Effect on book:** New D entries permitted subject to Strategy.md entry criteria. Pre-mortem and foundation-change assessment gates cleared 2026-04-25. **First trade staged 2026-04-26: RTX long limit BUY 0.1595 @ $175.00, day order Mon 2026-04-27.** LLY declined (defer to 2026-05-01 post-Q1-print re-screen — Q1 print 4-30 BMO is 3 trading days from reference; sentiment one-sided). CEG declined (defer to 2026-05-12 post-Q1-print re-screen — Q1 print 5-11 in 17 days; +7.09% rotation-pop entry; Crane FERC interconnection slip risk to 2031). Post-Monday: if filled, D has 1/10 open positions, Industrials/A&D ~2% of 30% sector cap; if not filled, re-evaluate Tue (D has no entry-window pressure like B).

### Strategy E — Market-neutral pairs

- **Technical signal:** ACTIVATE
  - Rule: SPY Trend ≠ DOWN AND VIX ≠ HIGH AND Breadth = HEALTHY (tightened 2026-04-23 per Strategy.md revision 2; prior rule was SPY ≠ DOWN AND VIX ≠ HIGH only)
  - Current: SPY Trend = NEUTRAL (≠ DOWN); VIX = NORMAL (≠ HIGH); Breadth = HEALTHY → all pass
- **Fundamental signal (M1):** DO-NOT-ACTIVATE
  - Macro vector overriding intra-industry dispersion; within-sector mean reversion suppressed
- **Divergence:** YES (Tech ACTIVATE / Fund DNA)
- **Adversarial review outcome (2026-04-25):** DO-NOT-ACTIVATE — see Decision_Log.md entry "Strategy E divergence review"
- **Current activation state:** DO-NOT-ACTIVATE
  - Affirmative case demonstrated stated DNA rationale is incomplete (sector-level language for industry-group strategy; doesn't engage with correlation filter or market-neutral structure) but did not defeat the available DNA rationale (regime breaks destabilize trailing-252-day correlation stationarity that entry criterion 3 relies on; pairs entered now risk structural macro-hedge failure before convergence)
  - Procedural moot point (ETF substitution at current portfolio size produces near-zero realized exposure regardless of router state) does not defeat the explicit default-DNA-on-ambiguity rule due to procedural symmetry
- **Theater-check flag (review):** CONVERGENT — incognito attacker and orchestrating-session review reach same DO-NOT-ACTIVATE verdict with same reasoning structure
- **Effect on book:** No new E entries until next M2 fundamental update (2026-05-01) or earlier divergence-review reopening on regime change. Note: E also effectively inactive at current book size per monthly E pair screen (ETF substitution required; both legs typically net inside same broad ETF). Pre-mortem and foundation-change assessment gates cleared 2026-04-25 (pre-mortem rev 5 ACCEPTED under combined revision-churn + saturation stop; foundation-change assessment under stabilized rev 5 citation graph → Continue). **Path back to activation: M2 fundamental signal process tightening on the divergence-review verdict — first draft initiated 2026-04-26 (see Decision_Log).**

---

## Pending Adversarial Reviews

Per Experiment_Parameters.md, divergences between technical and fundamental signals trigger a three-session adversarial review (attacker, judge, all incognito; default DO-NOT-ACTIVATE on judge ambiguity) before the router state updates.

| Strategy | Divergence type | Session 1 (Fundamental) | Session 2 (Attacker) | Session 3 (Judge) | Final state | Theater-check |
|----------|------------------|--------------------------|----------------------|---------------------|--------------|----------------|
| C | Tech ACTIVATE / Fund DO-NOT-ACTIVATE | Completed 2026-04-23 (M1) | Completed 2026-04-25 (single-session per EP rev 14) | In-conversation review 2026-04-25 | **HYBRID ACTIVATE — FOMC only** | CONVERGENT |
| E | Tech ACTIVATE / Fund DO-NOT-ACTIVATE | Completed 2026-04-23 (M1) | Completed 2026-04-25 (single-session per EP rev 14) | In-conversation review 2026-04-25 | **DO-NOT-ACTIVATE** | CONVERGENT |

---

## Activation State Change History

| Date | Strategy | Prior state | New state | Trigger | Review type |
|------|----------|-------------|-----------|---------|-------------|
| 2026-04-22 | A | n/a (inception) | DO-NOT-ACTIVATE | Experiment inception | — |
| 2026-04-22 | B | n/a (inception) | DO-NOT-ACTIVATE | Experiment inception | — |
| 2026-04-22 | C | n/a (inception) | DO-NOT-ACTIVATE | Experiment inception | — |
| 2026-04-22 | D | n/a (inception) | DO-NOT-ACTIVATE | Experiment inception | — |
| 2026-04-22 | E | n/a (inception) | DO-NOT-ACTIVATE | Experiment inception | — |
| 2026-04-23 | A | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE (confirmed) | M1 technical + fundamental agreement | Mechanical |
| 2026-04-23 | B | DO-NOT-ACTIVATE | ACTIVATE (pending foundation-change gate) | M1 technical + fundamental agreement | Mechanical |
| 2026-04-23 | D | DO-NOT-ACTIVATE | ACTIVATE (pending foundation-change gate) | M1 technical + fundamental agreement | Mechanical |
| 2026-04-23 | C | DO-NOT-ACTIVATE | PENDING ADVERSARIAL REVIEW | M1 divergence (tech ACT / fund DNA) | Three-session |
| 2026-04-25 | C | PENDING ADVERSARIAL REVIEW | HYBRID ACTIVATE (FOMC only) | Adversarial review outcome | Single-session per EP rev 14 |
| 2026-04-23 | E | DO-NOT-ACTIVATE | PENDING ADVERSARIAL REVIEW | M1 divergence (tech ACT / fund DNA) | Three-session |
| 2026-04-25 | E | PENDING ADVERSARIAL REVIEW | DO-NOT-ACTIVATE | Adversarial review outcome (default DNA on ambiguity) | Single-session per EP rev 14 |

Note: B and D mechanical activations were initially conditional on pre-mortem and foundation-change assessment gates per the original 6-step execution plan. Both gates cleared 2026-04-25:
- Six pre-mortem adversarial reviews complete: router rev 5; A rev 7; B rev 7; C rev 9; D rev 5; E rev 5 — all ACCEPTED.
- Five foundation-change assessments complete: 5/5 Continue under AI_Trading_Foundation rev 4 mechanical framework; E re-assessed under stabilized rev 5 citation graph also Continue.
Remaining strategy-specific blockers documented in the Trade Eligibility Summary table below.

---

## Trade Eligibility Summary (current)

| Strategy | Router state | Pre-trade blockers | Can trade today? |
|----------|--------------|--------------------|--------------------|
| A | DO-NOT-ACTIVATE | Router DNA verdict (M1) — unblocks at next M1 cycle if signal flips | No |
| B | ACTIVATE | Strategy.md entry criteria — currently: post-event historical-analogue retrieval (criterion 2 second pass) + thesis construction on NOW/IBM candidates within 10-day entry window (~closes 2026-05-06) | No (blocking on retrieval + thesis) |
| C | HYBRID ACTIVATE (FOMC only) | (a) Classical-method options-math scaffolding (Step 5 from original 6-step plan); (b) upcoming FOMC catalyst with thesis | No |
| D | ACTIVATE | Strategy.md entry criteria — currently: thesis construction on Quarterly_D_Candidates.md shortlist (LLY/RTX/CEG/VST/GOOGL/BA/CCJ/DIS) | No (blocking on thesis construction) |
| E | DO-NOT-ACTIVATE | Router DNA verdict (E divergence review 2026-04-25) — unblocks at M2 (2026-05-01) fundamental review if signal flips, or via M2 follow-up signal-process tightening | No |

Pre-mortem and foundation-change assessment gates that previously blocked all five strategies are CLEARED as of 2026-04-25 — see Decision_Log.md entries dated 2026-04-25 for individual gate clearances per strategy. Remaining blockers are now strategy-specific (router state, thesis construction, infrastructure scaffolding for C).

---

## Update rules

- **Technical signals** update daily at US market close via mechanical price/volume data. Any threshold crossing that would change a strategy's activation state is logged in the history table.
- **Fundamental signals** update on the first trading day of each month via the shared fundamental analysis template in Strategy.md.
- **Divergences** between technical and fundamental signals trigger a three-session adversarial review per Experiment_Parameters.md before the router state updates. Pending reviews are logged above.
- Any adversarial review outcome (judge's final decision, reasoning, theater-check flag) is recorded in Decision_Log.md alongside the state change in the history table above.
- Closed history rows are never deleted or modified retroactively.
