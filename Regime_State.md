# Regime State

Current regime measurements, per-strategy activation states, and router history for the AI-directed trading experiment. Read by daily scans, weekly research sessions, monthly reviews, and adversarial divergence reviews.

> **⚠ Rev 35 cap-removal note (2026-05-30):** Per owner directive, Strategy.md rev 35 removes ALL holdings-**count** caps across A/B/C/D (3-per-GICS-sector for A/B/C; D's 10-position / theme / correlation-bucket caps). Dated router-history lines below that mention "N/5", "1/3 sector cap", "N/10", etc. are **historical state notes, not active rules** — no count cap applies to any strategy as of rev 35. Retained: D's 30%-of-NAV sector *exposure* cap, D's minimum-5 floor, the 2%-per-position size cap, all kill triggers. See Decision_Log 2026-05-30 + Operating_Protocols §10.

**Last updated:** 2026-06-01 (M5 Monthly Action Conversion — M1b 2026-06-01 per-strategy fundamental calls applied; three divergence-reviews queued for C/D/E in `Pending_Adversarial_Reviews.md`; D fundamental flipped ACTIVATE→DO-NOT-ACTIVATE creating a new divergence; prior router states preserved pending review outcomes; technical-signal table retained from 2026-04-22 close — M1b PART 2 reads the same signals; daily mechanical updates per D1)
**Next scheduled technical update:** Daily (mechanical, end of each US trading day)
**Next scheduled fundamental update:** 2026-07-01 (first trading day of July)

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

Per M1 monthly review (2026-06-01 M1b 2026-06-01; M1b PART 2 verbatim source for fundamental calls). Each strategy has an independent activation rule combining a technical signal and a fundamental signal per Strategy.md.

### Strategy A — Catalyst-driven equity long

- **Technical signal:** DO-NOT-ACTIVATE
  - Rule: SPY Trend = UP AND Breadth = HEALTHY
  - Current: SPY Trend = NEUTRAL → first clause fails
- **Fundamental signal (M1b 2026-06-01):** DO-NOT-ACTIVATE (UNCHANGED from April)
  - May regime is textbook macro-dominated: stagflation-tilt (decelerating growth + reaccelerating inflation + hawkish policy + new hawkish Chair) running concurrent with risk-on pricing concentrated in Q1-earnings-momentum / ceasefire-relief / mega-cap leadership; breadth ~54% above 50-day = moderate not broad. Late-cycle stagflation-tilt structurally adverse for catalyst-driven longs whose payoff path requires the market to absorb the narrative rather than re-price on the next macro print. Per M1b PART 2 Strategy A.
- **Divergence:** NO
- **Current activation state:** DO-NOT-ACTIVATE
- **Effect on book:** No new A entries permitted. Existing A positions (none) would run to normal exits. Strategy A queue in `Watchlist.md` remains queued (31 names as of 2026-05-31 W4 W23) — no router-flip → no A-queue drain this cycle.

### Strategy B — Post-event mispricing

- **Technical signal:** ACTIVATE
  - Rule: SPY Trend ≠ DOWN AND VIX ≠ HIGH
  - Current: SPY Trend = NEUTRAL (≠ DOWN); VIX = NORMAL (≠ HIGH) → both pass
- **Fundamental signal (M1b 2026-06-01):** ACTIVATE (UNCHANGED from April)
  - May regime replaces April's "high-volatility tape with geopolitical overshoot" basis with low-vol / risk-on / shock-recovery conditions that also support the B mechanism: VIX decompressed to mid-teens reduces post-event noise; risk-on with kinetic shock receding produces overshoots in both directions; B's per-thesis adversarial counter-argument (criterion 4) + 10-day window already filter for information-driven vs sentiment-driven moves. Residual risk = sharp inflation print → macro-driven selling cascades mimicking post-event noise; router's HIGH-VIX exclusion is the regime-level mitigation if VIX rebreaks 25. Per M1b PART 2 Strategy B.
- **Divergence:** NO
- **Current activation state:** ACTIVATE
- **Effect on book:** New B entries permitted subject to Strategy.md entry criteria. Open B book (6 as of 2026-06-01): HCA / ZBRA / BRC / TJX / AZO / BURL (BURL convergence-exit DUE — staged for Mon 2026-06-01 07:00 MT execution per existing calendar events). 10 W4 W23 thesis-construction events fired Sun 2026-05-31 09:00 MT, 12 missed sessions flagged for D2 re-route (Agilent NO-GO and OKTA DEFER already processed; 10 outstanding per 2026-05-31 D3). Rev 35 in force: no sector / total-count caps; KL #12 metric (d) pairwise-correlation monitoring-only.

### Strategy C — Defined-risk options around known events

- **Technical signal:** ACTIVATE
  - Rule: SPY Trend ≠ DOWN
  - Current: SPY Trend = NEUTRAL → passes
- **Fundamental signal (M1b 2026-06-01):** DO-NOT-ACTIVATE (UNCHANGED from April)
  - May regime is macro-dominated by construction (stagflation-tilted axes moving against trend simultaneously while risk-on pricing is concentrated in Q1-earnings-momentum / ceasefire-relief vectors); hawkish-FOMC-minutes / new-Chair dynamics make Fed reaction-function the dominant pricing factor, compressing per-name earnings reaction dispersion in stagflation-squeeze cross-sections (AI_Edges 2.13 miscalibration compounds directional thesis quality). FOMC events remain the affirmative exception per the April HYBRID logic but per the M1b immutable output format the strategy-level call is binary. Per M1b PART 2 Strategy C.
- **Divergence:** YES (Tech ACTIVATE / Fund DNA) — re-run on May regime; same direction as April
- **Pending review:** `div-C-202605-1` in `Pending_Adversarial_Reviews.md` (queued 2026-06-01 by M5; attacker_due 2026-06-02, orchestrator_due 2026-06-03)
- **Prior-cycle adversarial review outcome (2026-04-25):** HYBRID — see Decision_Log_Archive_2026_Q2.md entry "2026-04-25 Strategy C divergence adversarial review — HYBRID ACTIVATE (FOMC only)"
- **Current activation state (operative pending `div-C-202605-1`):** HYBRID ACTIVATE
  - **FOMC events: ACTIVATE** — affirmative case decisive on internal inconsistency in fundamental DNA (FOMC IS the macro catalyst the DNA reasoning names as dominating, not an "individual catalyst" suppressed by macro)
  - **Corporate earnings: DO-NOT-ACTIVATE** — fundamental DNA reasoning survives (cross-sectional dispersion compression in stagflation-squeeze regimes; AI_Edges 2.13 miscalibration compounds directional thesis quality)
  - **FDA PDUFA: DO-NOT-ACTIVATE** — no specific affirmative made; macro-domination doesn't change biotech-specific risk profile; revisit at M2
  - **Vol-directional theses across all event types: DO-NOT-ACTIVATE** — strategy spec doesn't constrain to long-vol-only; activating vol-directional in elevated-IV regime authorizes short-vol exposure the strategy isn't structured for; punt to strategy spec revision
- **Theater-check flag (April review):** CONVERGENT — incognito attacker and orchestrating-session review reach same HYBRID verdict with same scope decomposition
- **Effect on book:** New C entries permitted ONLY for FOMC events meeting all standard entry criteria (Strategy.md Section "Strategy C: Entry criteria" 1-5) — HYBRID state operative pending `div-C-202605-1` outcome. FOMC June 2026 thesis-construction event `7pbkg1kh2pge7midfiqnj6edvk` (Mon 2026-06-08 09:00 MT) proceeds under the operative HYBRID state; its directional-skew framing is OPEN per the W4 W20 W1-refresh update. Per-strategy C book mark-to-market remains ~$1,890 (no open C positions). M2 follow-up (empirical dispersion-compression check supporting potential earnings re-routing) tracking; next M2 cycle continues to inform the HYBRID scope.

### Strategy D — Long-horizon narrative core

- **Technical signal:** ACTIVATE
  - Rule: (SPY Trend = UP OR NEUTRAL) AND Yield Curve Sustained Inversion = NOT-SUSTAINED
  - Current: SPY Trend = NEUTRAL; flag = NOT-SUSTAINED → both pass
- **Fundamental signal (M1b 2026-06-01):** DO-NOT-ACTIVATE — **FLIP from April ACTIVATE**
  - May materially weakens the activation case on growth + inflation axes: Q1 GDP revised down to +1.6% with private-inventory + services-side downward revisions; UMich record low third consecutive monthly decline; ISM Services New Orders −7.1pp; April core CPI +0.4% MoM SA largest since Jan 2025; April PPI +6.0% YoY largest since Dec 2022; hawkish FOMC minutes + new Chair Warsh sworn 5/22. Persistent hawkish-inflation regimes structurally compress multi-year equity theses via (a) higher discount-rate path, (b) elevated reaccelerating-inflation tail risk, (c) cumulative pressure on long-duration earnings streams. Yield-curve sustained-inversion safeguard remains NOT-SUSTAINED, but the fundamental case has tipped from "secular theses intact" to "late-cycle compression risk materially elevated." Risk-on asset pricing does not alter the multi-year structural backdrop — it is the principal vector by which D would absorb regime breaks (concentration / AI / large-cap leadership). Per M1b PART 2 Strategy D.
  - Reconciliation override `inflation_trend=reaccelerating AND policy_stance=hawkish → D ACTIVATE→DNA` precondition satisfied but did not fire mechanically (rule is directional only; raw M1b call already DNA).
- **Divergence:** YES (Tech ACTIVATE / Fund DNA) — **NEW divergence from prior-month no-divergence ACTIVATE/ACTIVATE state**
- **Pending review:** `div-D-202605-1` in `Pending_Adversarial_Reviews.md` (queued 2026-06-01 by M5; attacker_due 2026-06-02, orchestrator_due 2026-06-03)
- **Current activation state (operative pending `div-D-202605-1`):** ACTIVATE — prior-cycle state preserved per Experiment_Parameters.md "During the review, the strategy retains its prior activation state"
- **Effect on book:** Existing D positions (RTX OPEN 2026-04-27 0.1595 sh @ $175.12 cost basis $28.21; DIS OPEN 2026-05-07 0.28 sh @ $110.35 cost basis $31.21) run to thesis-invalidation per Strategy.md "router-deactivation-does-not-force-exits" rule — neither is auto-closed by the fundamental flip. **M4 2026-05-31** recommended HOLD on both with all invalidation criteria NOT-TRIPPED + all driver pillars on-track-or-progressing (RTX: six pillars uniformly directionally supportive in window; DIS: five pillars on-track with Q2 FY26 first-verification print of SVOD margin trend at 10.6% vs Q1 8.4% baseline + FY26 EPS guide tightened upward + buyback raised $7B → $8B). **New D entries blocked pending `div-D-202605-1` outcome** per M1b PART 2 explicit text. BA D re-screen event (`r9i6u6mnpk9ukoj2bh15m1fr7c`, Mon 2026-06-01 09:00 MT) and LLY D mechanical re-screen event (`fpbueqccja9thjcnuj6ck9l6rs`, Fri 2026-06-12 09:30 MT) have a STEP-0 D-divergence-review gate added by this M5 cycle: the re-screen check on the original reconsideration trigger proceeds; any thesis-construction step is conditioned on the divergence-review verdict (ACTIVATE → proceed; DO-NOT-ACTIVATE → terminal NO-GO; pending → DEFER with NO-ENTRY conservative-default fallback).

### Strategy E — Market-neutral pairs

- **Technical signal:** ACTIVATE
  - Rule: SPY Trend ≠ DOWN AND VIX ≠ HIGH AND Breadth = HEALTHY (tightened 2026-04-23 per Strategy.md revision 2; prior rule was SPY ≠ DOWN AND VIX ≠ HIGH only)
  - Current: SPY Trend = NEUTRAL (≠ DOWN); VIX = NORMAL (≠ HIGH); Breadth = HEALTHY → all pass
- **Fundamental signal (M1b 2026-06-01):** DO-NOT-ACTIVATE (UNCHANGED from April)
  - May regime is macro-driven by construction; within-industry dispersion in stagflation-tilted + receding-shock configuration tracks regime-stress reaction patterns more than fundamental L-vs-S divergence — the shock-recovery vector is itself an intra-sector macro-overlay that compresses within-industry dispersion in the sectors most prone to E pair opportunities (energy / transports / industrials at retail-tradeable instrument depth). Trailing-252-day correlation stationarity remains stressed by the regime-break sequence of 2026 (March oil shock; February tariff-IEEPA SCOTUS ruling; ongoing Iran conflict) — structural-macro-hedge-failure-before-convergence risk per April divergence-review verdict persists. Per M1b PART 2 Strategy E.
- **Divergence:** YES (Tech ACTIVATE / Fund DNA) — re-run on May regime; same direction as April
- **Pending review:** `div-E-202605-1` in `Pending_Adversarial_Reviews.md` (queued 2026-06-01 by M5; attacker_due 2026-06-02, orchestrator_due 2026-06-03)
- **Prior-cycle adversarial review outcome (2026-04-25):** DO-NOT-ACTIVATE — see Decision_Log_Archive_2026_Q2.md entry "2026-04-25 Strategy E divergence adversarial review — DO-NOT-ACTIVATE"
- **Current activation state (operative pending `div-E-202605-1`):** DO-NOT-ACTIVATE
  - Affirmative case demonstrated stated DNA rationale is incomplete (sector-level language for industry-group strategy; doesn't engage with correlation filter or market-neutral structure) but did not defeat the available DNA rationale (regime breaks destabilize trailing-252-day correlation stationarity that entry criterion 3 relies on; pairs entered now risk structural macro-hedge failure before convergence)
  - Procedural moot point (ETF substitution at current portfolio size produces near-zero realized exposure regardless of router state) does not defeat the explicit default-DNA-on-ambiguity rule due to procedural symmetry
- **Theater-check flag (April review):** CONVERGENT — incognito attacker and orchestrating-session review reach same DO-NOT-ACTIVATE verdict with same reasoning structure
- **Effect on book:** No new E entries pending `div-E-202605-1` outcome. Per-strategy E book mark-to-market 2026-05-07 close $1,890.44 (Portfolio_Ledger.md); no open E positions; full SGOV parking. **M3 2026-06-01 advisory:** ranked pair shortlist 10 names (TOP-3: NVO/LLY, AMD/NVDA, STX/MU; REST-7: WFC/C, F/GM, CVX/XOM, ELV/UNH, AMAT/ASML, TGT/WMT, VZ/T) — every pair flagged "ETF-substitution required" at the per-leg 2%-of-NAV $37.81 sizing (cheapest individual-stock leg F ~$11–12; smallest leg-pair sum still requires non-fractional shares above sizing cap). M3 explicitly frames the list as "divergence-review reference material, not an entry queue" given M1b DO-NOT-ACTIVATE + universal ETF-substitution flag. **M5 does NOT schedule any E pair thesis-construction events this cycle** (operative DNA state pending review + advisory-only M3 disposition at current book size). M2 follow-up (signal-process tightening on the divergence-review verdict — first draft initiated 2026-04-26) remains tracking as the path back to activation independent of monthly cycles.

---

## Pending Adversarial Reviews

Per Experiment_Parameters.md and Claude_Task_Plan.md, divergences between technical and fundamental signals trigger a two-routine adversarial review (Attacker routine + Orchestrator routine; file-handoff via `Pending_Adversarial_Reviews.md`; default DO-NOT-ACTIVATE on orchestrator ambiguity) before the router state updates.

**Pending entries (queued 2026-06-01 by M5):**

| Queue id | Strategy | Divergence type | Artifact | Attacker due | Orchestrator due | Prior state operative pending review |
|----------|----------|------------------|----------|--------------|-------------------|---------------------------------------|
| `div-C-202605-1` | C | Tech ACTIVATE / Fund DO-NOT-ACTIVATE | Monthly_Fundamental.md (M1b 2026-06-01) | 2026-06-02 | 2026-06-03 | HYBRID ACTIVATE (FOMC-only) |
| `div-D-202605-1` | D | Tech ACTIVATE / Fund DO-NOT-ACTIVATE (NEW — fundamental FLIP) | Monthly_Fundamental.md (M1b 2026-06-01) | 2026-06-02 | 2026-06-03 | ACTIVATE |
| `div-E-202605-1` | E | Tech ACTIVATE / Fund DO-NOT-ACTIVATE | Monthly_Fundamental.md (M1b 2026-06-01) | 2026-06-02 | 2026-06-03 | DO-NOT-ACTIVATE |

**Completed (historical reference):**

| Strategy | Divergence type | Cycle date | Final state | Theater-check |
|----------|------------------|-------------|--------------|----------------|
| C | Tech ACTIVATE / Fund DO-NOT-ACTIVATE | 2026-04-23 → 2026-04-25 | **HYBRID ACTIVATE — FOMC only** | CONVERGENT |
| E | Tech ACTIVATE / Fund DO-NOT-ACTIVATE | 2026-04-23 → 2026-04-25 | **DO-NOT-ACTIVATE** | CONVERGENT |

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
| 2026-06-01 | A | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE (confirmed) | M1b 2026-06-01 technical + fundamental agreement (UNCHANGED) | Mechanical |
| 2026-06-01 | B | ACTIVATE | ACTIVATE (confirmed) | M1b 2026-06-01 technical + fundamental agreement (UNCHANGED) | Mechanical |
| 2026-06-01 | C | HYBRID ACTIVATE (FOMC-only) | HYBRID ACTIVATE (FOMC-only) — PENDING `div-C-202605-1` | M1b 2026-06-01 divergence (tech ACT / fund DNA); same direction as April; HYBRID state preserved | Two-routine queue (Pending_Adversarial_Reviews.md) |
| 2026-06-01 | D | ACTIVATE | ACTIVATE — PENDING `div-D-202605-1` | M1b 2026-06-01 NEW divergence created by fundamental FLIP ACTIVATE→DNA; ACTIVATE state preserved pending review; new D entries blocked per M1b PART 2 | Two-routine queue (Pending_Adversarial_Reviews.md) |
| 2026-06-01 | E | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE — PENDING `div-E-202605-1` | M1b 2026-06-01 divergence (tech ACT / fund DNA); same direction as April; DNA state preserved | Two-routine queue (Pending_Adversarial_Reviews.md) |

Note: B and D mechanical activations were initially conditional on pre-mortem and foundation-change assessment gates per the original 6-step execution plan. Both gates cleared 2026-04-25:
- Six pre-mortem adversarial reviews complete: router rev 5; A rev 7; B rev 7; C rev 9; D rev 5; E rev 5 — all ACCEPTED.
- Five foundation-change assessments complete: 5/5 Continue under AI_Trading_Foundation rev 4 mechanical framework; E re-assessed under stabilized rev 5 citation graph also Continue.
Remaining strategy-specific blockers documented in the Trade Eligibility Summary table below.

---

## Trade Eligibility Summary (current, 2026-06-01)

| Strategy | Router state | Pre-trade blockers | Can trade today? |
|----------|--------------|--------------------|--------------------|
| A | DO-NOT-ACTIVATE | Router DNA verdict (M1b 2026-06-01 UNCHANGED) — unblocks at next M1 cycle if signal flips | No |
| B | ACTIVATE | Strategy.md entry criteria — open B book 6 (HCA/ZBRA/BRC/TJX/AZO/BURL with BURL convergence-exit due Mon 2026-06-01); D2 re-route of 10 missed thesis sessions in progress; OKTA re-routed to Tue 2026-06-02 post-M1-gate | Yes (subject to entry criteria) |
| C | HYBRID ACTIVATE (FOMC only) — PENDING `div-C-202605-1` | FOMC catalyst required (corporate earnings / FDA / vol-directional remain DNA under HYBRID); FOMC June 2026 thesis-construction event Mon 2026-06-08 09:00 MT pending | FOMC-only (subject to entry criteria; HYBRID state operative pending divergence review) |
| D | ACTIVATE — PENDING `div-D-202605-1` | M1b fundamental FLIP to DNA created NEW divergence; new D entries BLOCKED pending review outcome per M1b PART 2; existing RTX + DIS positions run to thesis-invalidation per Strategy.md exit rules (M4 2026-05-31 HOLD; all criteria NOT-TRIPPED); BA + LLY D re-screen events gated by STEP-0 D-divergence-review check | No new entries (review pending) |
| E | DO-NOT-ACTIVATE — PENDING `div-E-202605-1` | Router DNA preserved pending review; M3 2026-06-01 pair shortlist (10 names) advisory-only at current book size (all ETF-substitution-required at $37.81/leg); M5 schedules no E pair thesis-construction events this cycle | No |

Pre-mortem and foundation-change assessment gates that previously blocked all five strategies are CLEARED as of 2026-04-25 — see Decision_Log.md entries dated 2026-04-25 for individual gate clearances per strategy. Remaining blockers are now strategy-specific (router state, thesis construction, infrastructure scaffolding for C).

---

## Update rules

- **Technical signals** update daily at US market close via mechanical price/volume data. Any threshold crossing that would change a strategy's activation state is logged in the history table.
- **Fundamental signals** update on the first trading day of each month via the shared fundamental analysis template in Strategy.md.
- **Divergences** between technical and fundamental signals trigger a three-session adversarial review per Experiment_Parameters.md before the router state updates. Pending reviews are logged above.
- Any adversarial review outcome (judge's final decision, reasoning, theater-check flag) is recorded in Decision_Log.md alongside the state change in the history table above.
- Closed history rows are never deleted or modified retroactively.
