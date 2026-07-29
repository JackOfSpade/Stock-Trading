2026

# Annual Constraint Audit — 2026

**Routine:** A2 (Per-Strategy Constraint Audit — deep research) · **Run date:** 2026-07-28 (America/Denver, `state.trading_day_today`)
**Governing procedure:** `AI_Trading_Foundation.md` rev 5, §5.3–§5.7 (mechanical, no orchestrator discretion)
**Roster-active strategies audited:** A, B, C, D, E (`state.active_strategy_codes` — 5 codes; none added since this task was authored)
**Upstream evidence:** `Annual_AI_Foundation_Sweep.md` (A1, 2026, re-run completed 2026-07-28) · `Quarterly_AI_Foundation_Delta.md` (Q3, 2026-Q2 — the only quarterly cycle that has ever existed)
**Catch-up evidence window:** `never_completed = TRUE`, `window_days = 366` (cadence-sized fallback; this is A2's first execution — no `CATCHUP[...]` token, the window is cadence-normal for an annual routine)
**Model of record:** `claude-opus-5` (`ops/cadence.yaml:41` `routine_model`)

---

## HEADLINE

**Zero constraints are relaxed this cycle. Zero per-constraint out-of-table flags fire. Six framework-level flags are raised — and the two blocking ones (F-1, F-2) were resolved by owner directive the same day; four remain open for A3.**

Every one of the **201 per-strategy constraints** inventoried in PART 1 terminates at **Step 1** of the §5.3 procedure. This is not a judgment call and did not require weighing evidence per constraint: **no Part-2 disadvantage in `AI_Trading_Foundation.md` classifies as PARTIAL or MATERIAL reduction in this audit cycle** (§2.0 below), so the §5.3 criterion — "a *Tier 2* disadvantage that the strategy compensates for has been *materially reduced*" — is unmet for every constraint in the corpus simultaneously.

This is the outcome A2's own specification predicts as the normal case ("most constraints have NONE primary-citation reduction (Step 1 terminates the evaluation)"), and it independently reproduces A1's §F.3 finding ("Zero Tier 2 disadvantages cleared all four §5.5 Goodhart guardrails for a reduction"). A2 reached it by the §5.3 route (per-constraint, primary-citation-keyed); A1 reached it by the §5.4/§5.5 route (per-item, evidence-keyed). The two agree.

The substantive output of this cycle is therefore **PART 1's inventory and citation graphs** (a durable artifact that did not previously exist in one place) plus **six framework-level findings** in §2.5 — two of which would **block** a relaxation if a future cycle ever produced one, and which are recorded now, while they are latent and cost nothing to fix, rather than discovered mid-relaxation.

---

## HOW A3 SHOULD READ THIS DOCUMENT

Per `Claude_Task_Plan.md` A3 §C, A3 reads PART 2 verbatim and produces the updated `Strategy.md`. For this cycle:

- **A3 §C — constraint relaxations to apply: NONE.** No constraint carries a §5.6 relaxation verdict. `Strategy.md` needs **no constraint-value edit** from A2 this cycle. (A1 separately produces a Strategy C pre-mortem re-open under §5.2; that is A1's output, not A2's, and flows through A3 §B, not §C.)
- **A3 §D — per-constraint out-of-table flags to enqueue: NONE.** §5.6's out-of-table branch sits inside **Step 4**, reachable only by constraints that pass Steps 1–3. No constraint passes Step 1, so no constraint reaches that branch. Enqueue **zero** `out-of-table-resolution` reviews on per-constraint grounds.
- **A3 §D — framework-level flags to enqueue: FOUR (F-3, F-4, F-5, F-6 — §2.5).** These are `§5.7` item-6 outputs ("any constraints **or items** the criteria couldn't deterministically resolve"). They are **not** constraint-value changes and must not be applied as such. **F-1 and F-2 were RESOLVED by owner directive on 2026-07-28, the same day as this audit** (foundation rev 6 / `Experiment_Parameters.md` rev 17 / `Strategy.md` rev 38 — new §5.6a in-life edit path, and the §5.6 per-position sizing row struck). **Do not enqueue F-1 or F-2**; their entries in §2.5 are retained as the audit record with the resolution stated inline.
- **A3 §E — decision-log counts:** constraints relaxed = 0 (per strategy: A 0, B 0, C 0, D 0, E 0); per-constraint out-of-table flags = 0; framework-level flags = 6; `Strategy.md` per-strategy revision bumps required by A2 = 0.

---

# PART 1 — Constraint inventory and foundation-citation graph

## 1.0 Method, sources, and a material caveat about the citation parse

Per §5.3 step 1 and A2 PART 1, constraints were parsed from **each strategy's mechanism document and its pre-mortem** — `strategy/03_strategy_a.md` … `strategy/07_strategy_e.md` and the corresponding `### Pre-mortem: Strategy X` sections of `strategy/08_pre_mortems.md`. Experiment-level constraints binding all strategies were parsed from `Experiment_Parameters.md` and `strategy/00_preamble.md` (§1.6). Every row below is backed by verbatim text at the cited `file:line` in those sources.

**Constraint types** are the six §5.6 categories: `P` per-position sizing cap · `U` universe restriction · `C` concentration limit · `F` frequency/cadence rule · `H` hit-rate threshold / edge-decay metric · `O` out-of-table (fits none of the five).

### THE CITATION-PARSE CAVEAT — read before using the "primary citation" column

§5.3 step 2 specifies a mechanical parse: *"a constraint's primary citation is the item named in its rev N annotation (e.g., 'rev 4 added per cycle 3 T1-α' — the cycle 3 attacker output is parsed for which 2.X item the T1-α attack referenced)."*

**That parse has no input for most of this corpus.** The constraint documents are densely annotated with revision tags, but those tags overwhelmingly name **internal adversarial-review defect labels** (`T1-α`, `T1.β`, `T1.ι`, `cycle 3 item 7`) and **not** foundation items. The referenced cycle-N attacker outputs are not retained in the repository — the pre-mortems record the *fixes*, not the attacker transcripts the parse is told to read. Concretely:

| | Constraints | With an explicit `1.X`/`2.X` link recoverable from mechanism doc or pre-mortem | `PRIMARY CITATION UNRESOLVED` |
|---|---|---|---|
| A | 33 | 5 | 28 |
| B | 35 | 9 | 26 |
| C | 51 | 17 | 34 |
| D | 48 | 13 | 35 |
| E | 34 | 10 | 24 |
| **Total** | **201** | **54 (27%)** | **147 (73%)** |

Where a citation *is* recoverable it is generally not from a rev-N annotation naming a foundation item, but from the **pre-mortem's Section 5 / binding-constraint prose** naming the constraint as a mitigation for a disadvantage. This audit used that as the citation source and says so per row.

**Handling (mechanical, no discretion):** a constraint with no parseable primary citation has, by construction, **no cited disadvantage that could have been reduced**. §5.3's criterion requires an affirmative link from a materially-reduced Tier 2 disadvantage to the constraint; absent that link the criterion is **unmet** and Step 1 terminates with NONE. This is a *deterministic* resolution, not an undecidable case, so it does **not** produce a §5.6 out-of-table flag (§5.6 defines out-of-table by constraint **type**, not by citation provenance). The provenance gap is recorded separately as framework flag **F-4**.

**This caveat is non-binding on this cycle's outcome.** Because zero disadvantages classify as reduced (§2.0), all 201 constraints terminate at Step 1 regardless of whether their citation is resolved. The gap would become binding the first time any disadvantage does register a reduction — which is exactly why it is flagged now.

---

## 1.1 Strategy A — Catalyst-driven equity long positions

**Mechanism doc:** `strategy/03_strategy_a.md` (no document-level revision header; latest inline tag **Rev 41**, 2026-07-22). **Pre-mortem:** rev **7** (2026-04-23, ACCEPTED) — `strategy/08_pre_mortems.md:216`. **Constraints: 33.**

| ID | Constraint | Type | Primary citation | Secondary | Rev added |
|---|---|---|---|---|---|
| C-A-01 | A/C cross-strategy exclusion (same name, same thesis) | U | UNRESOLVED | none | not stated |
| C-A-02 | A/B cross-strategy exclusion (never simultaneous) | U | UNRESOLVED | none | not stated |
| C-A-03 | US-listed common equity | U | UNRESOLVED | none | not stated |
| C-A-04 | Market cap ≥ $2B at entry | U | **2.3** (inline: "hallucination rates are elevated per 2.3", `03:18`) | none | not stated |
| C-A-05 | 30-day ADV ≥ $10M | U | UNRESOLVED | none | not stated |
| C-A-06 | Long-only | U | UNRESOLVED | none | not stated |
| C-A-07 | **2% of strategy portfolio per position** | **P** | **No single primary — explicit confluence** of 2.4, 2.13, 2.14, 2.19 (`08:257`) | 2.13 (`08:248`) | rev 6 reclassified |
| C-A-08 | No options | U | UNRESOLVED | none | not stated |
| C-A-09 | Entry 1 — catalyst within 6 months | U | UNRESOLVED | none | not stated |
| C-A-10 | Entry 2 — sourcing: retrieved, not recalled | U | **2.3 + 2.5** (inline, jointly, `03:27`) | none | not stated |
| C-A-11 | Entry 3 — price target + completion criteria, immutable | U | UNRESOLVED | none | not stated |
| C-A-12 | Entry 4 — adversarial counter-argument, no decisive flaw | U | **2.4** (`08:246`, `08:267`) | none | rev 5 reclassified |
| C-A-13 | Entry 5 — 3-per-GICS-sector cap — **REMOVED (Rev 35)** | C | UNRESOLVED | none | removed Rev 35 |
| C-A-14 | Entry 6 — 2.19 historical-analogue exclusion | U | **2.19** (`03:31`) | **2.4** (`08:275`) | pre-mortem rev 3 |
| C-A-15 | Add hard gate — invalidation criteria unbreached | U | UNRESOLVED | none | Rev 40 (2026-07-21) |
| C-A-16 | Add sizing — fresh 2% tranche, no cumulative cap | P | UNRESOLVED | none | Rev 40 |
| C-A-17 | Exit — thesis completion | O | UNRESOLVED | none | not stated |
| C-A-18 | Exit — thesis invalidation | O | UNRESOLVED | none | not stated |
| C-A-19 | Exit — 12-month hard time stop | O | UNRESOLVED | **2.20** (`08:251`) | not stated |
| C-A-20 | Exit — A→D thesis overlap resolution | U | UNRESOLVED | none | not stated |
| C-A-21 | "Not exit-triggering" list | O | UNRESOLVED | none | not stated |
| C-A-22 | Partial exit — remainder runs on original criteria | O | UNRESOLVED | none | Rev 41 (2026-07-22) |
| C-A-23 | Declared frequency 15–25 trades/yr | F | UNRESOLVED | none | not stated |
| C-A-24 | Router — SPY Trend UP **and** Breadth HEALTHY | O | UNRESOLVED | 2.20 (loose, `08:251`) | not stated |
| C-A-25 | Public-information-only (pre-mortem only) | U | UNRESOLVED — text **explicitly disclaims** a foundation link ("a methodological exclusion, not an AI_Edges-flowing exclusion", `08:259`) | none | not stated |
| C-A-26 | Monthly — hit-rate tracking | F | UNRESOLVED | none | not stated |
| C-A-27 | Monthly — forced reassessment at 9-month hold | F | UNRESOLVED | none | not stated |
| C-A-28 | At 15 trades — preliminary edge check | F | UNRESOLVED | none | not stated |
| C-A-29 | At 30 trades — gate evaluation | F | UNRESOLVED | none | not stated |
| C-A-30 | Monthly — beta-dominance attribution | F | UNRESOLVED | none | not stated |
| C-A-31 | Edge-decay — hit-rate decline over 10-trade windows | H | UNRESOLVED | none | not stated |
| C-A-32 | Edge-decay — win/loss size symmetry | H | UNRESOLVED | none | not stated |
| C-A-33 | Edge-decay — beta-dominance test formula | H | UNRESOLVED | none | rev 2 formula fix |

**Foundation citation graph — A.** Edges **1.1, 1.10** (`03:8`). Disadvantages **2.3, 2.4, 2.5, 2.8, 2.13, 2.14, 2.19, 2.20**.
Confirms A1's re-derivation: **A cites neither 1.4, 2.15 nor 2.17 anywhere** — see the reconciliation in §1.7.

---

## 1.2 Strategy B — Post-event mispricing exploitation

**Mechanism doc:** `strategy/04_strategy_b.md` (latest inline tag **Rev 41**). **Pre-mortem:** rev **7** (2026-04-23, ACCEPTED) — `08:304`. **Constraints: 35.**

| ID | Constraint | Type | Primary citation | Secondary | Rev added |
|---|---|---|---|---|---|
| C-B-01 | US-listed common equity | U | UNRESOLVED | none | not stated |
| C-B-02 | Market cap ≥ $2B at entry | U | UNRESOLVED | none | not stated |
| C-B-03 | 30-day ADV ≥ $10M | U | UNRESOLVED | none | not stated |
| C-B-04 | No options | U | UNRESOLVED | none | not stated |
| C-B-05 | **2% of strategy portfolio per position** | **P** | **No single primary — explicit confluence** of 2.4, 2.13, 2.14, 2.15, 2.20 (`08:385`) | **2.18** (`08:379`) | rev 4 framing |
| C-B-06 | Directional posture — long-biased in practice | U | **2.20** (`04:74`) | none | Rev 36 (2026-06-23) |
| C-B-07 | Entry 1 — event ≤10 trading days, ≥5% move | U | UNRESOLVED | **2.14** (`08:377`) | not stated |
| C-B-08 | Entry 2 — over/under-sizing narrative synthesis | U | UNRESOLVED | **2.15** (`08:375`), **2.19** (`08:437`) | not stated |
| C-B-09 | Entry 3 — convergence target, strict closed list | U | UNRESOLVED | **2.13** (`08:376`) | Rev 13 / Rev 14 |
| C-B-10 | 60-day convergence timeline (entry + expiry) | F | UNRESOLVED | **2.14** (`08:377`), **2.18** (`08:379`), **2.20** (`08:400`) | not stated |
| C-B-11 | Entry 4 — adversarial counter-argument | U | **2.4** (`08:398`) | **2.13** (`08:376`), **2.14** (`08:377`) | not stated |
| C-B-12 | Entry 5 — no open A position in same name | U | UNRESOLVED | none | not stated |
| C-B-13 | Add hard gate — invalidation unbreached | U | UNRESOLVED | none | Rev 40 |
| C-B-14 | Add sizing — fresh 2% tranche, no cumulative cap | P | UNRESOLVED | none | Rev 40 |
| C-B-15 | Short-specific add gate (not near stop trigger) | U | UNRESOLVED | none | Rev 40 |
| C-B-16 | Exit — convergence target reached | O | UNRESOLVED | none | not stated |
| C-B-17 | Exit — thesis invalidation | O | UNRESOLVED | none | not stated |
| C-B-18 | Exit — short borrow rate >10% annualized | O | UNRESOLVED | none | not stated |
| C-B-19 | Short-side stop-loss at +25% | O | **2.18** (`08:379`) | none | Rev 13 (= pre-mortem rev 3) |
| C-B-20 | Long positions — no stop-loss (asymmetric by design) | O | **2.18** (`08:379`) | none | baseline |
| C-B-21 | Declared frequency 20–30 trades/yr | F | UNRESOLVED | none | not stated |
| C-B-22 | 3-per-GICS-sector cap — **REMOVED (Rev 35)** | C | **2.8** (Constraint 3, `08:402`) | none | removed Rev 35 |
| C-B-23 | Router — SPY Trend ≠ DOWN | U | UNRESOLVED | none | not stated |
| C-B-24 | **Router — VIX Regime ≠ HIGH** (the HIGH-VIX exclusion) | U | **2.20** (Constraint 2, `08:400`) | none | not stated |
| C-B-25 | Edge-decay — hit-rate decline over 10-trade windows | H | UNRESOLVED | 2.4, 2.8 (`08:417`), 2.15 (`08:419`), 2.19 (`08:437`) | not stated |
| C-B-26 | At 15 trades — preliminary edge check | F | UNRESOLVED | none | not stated |
| C-B-27 | At 30 trades — gate evaluation | F | UNRESOLVED | none | not stated |
| C-B-28 | KL5 — edge-decay threshold = realized − 1.5 SE | H | UNRESOLVED | none | not stated |
| C-B-29 | KL6 — short/long hit-rate gap ≥15pp over 20 trades | H | UNRESOLVED | none | rev 2 |
| C-B-30 | KL7 — per-trade loss escalation trigger | H | UNRESOLVED | none | rev 5 |
| C-B-31 | KL7 — 30-trade-gate loss-pattern review | H | UNRESOLVED | none | rev 4 |
| C-B-32 | KL11 — convergence-magnitude calibration (<0.7×) | H | **2.13** (`08:439`) | none | rev 2 |
| C-B-33 | KL12 — concurrent-long correlation >0.5 / exposure >10% escalation | C | **2.20** (`08:441`) | none | rev 4 / rev 5 / rev 6 |
| C-B-34 | 36-month mark-to-market kill trigger (external ref) | H | UNRESOLVED | none | not stated |
| C-B-35 | KL8 — monthly A-after-B coordination audit | F | UNRESOLVED | none | rev 2 |

**Foundation citation graph — B.** Edges **1.1, 1.4** (`04:8`). Disadvantages **2.4, 2.8, 2.13, 2.14, 2.15, 2.17, 2.18, 2.19, 2.20**.
**B compensates no disadvantage.** It is structurally **exposed** to 2.20 — the mechanism *is* the textbook-rational instinct — with the router HIGH-VIX exclusion (C-B-24) a partial *regime-level* mitigation and "no mechanism-level mitigation" (`04:8`, `08:318`, `08:400`). The rev-1 claim that B "compensates 2.20" was retracted at rev 2.
**Post-Rev-35, B has zero hard concentration caps**; C-B-33 is a flag-for-review escalation threshold, not an entry block.

---

## 1.3 Strategy C — Defined-risk options structures around known events

**Mechanism doc:** `strategy/05_strategy_c.md` (latest inline tag **Rev 41**). **Pre-mortem:** rev **9** (2026-04-25, ACCEPTED) — `08:451`. **Constraints: 51.** C is the most heavily constrained and most densely cited strategy in the corpus.

| ID | Constraint | Type | Primary citation | Secondary | Rev added |
|---|---|---|---|---|---|
| C-C-01 | Max loss at expiration deterministically computable | U | UNRESOLVED | none | not stated |
| C-C-02 | Early-assignment cascade max-loss computable + 3 pinned conventions | U | UNRESOLVED (`T1.2`/`T1.4`/`T1.β` are internal defect tags, **not** foundation items) | none | rev 19 / rev 20 |
| C-C-03 | Bounded early-assignment loss ≤ 2% of portfolio | P | UNRESOLVED | none | not stated |
| C-C-04 | Multi-expiration variants excluded | U | UNRESOLVED | none | rev 20 |
| C-C-05 | **Total capital at risk ≤ 2% of strategy portfolio** | **P** | **2.18** (`08:551`, `08:473`; mechanism `05:8`) | confluence 2.1, 2.4, 2.13, 2.15 (`08:559`) | rev 3 / rev 5 |
| C-C-06 | Structure expiration within 1–45 days | U | UNRESOLVED | none | not stated |
| C-C-07 | Qualifying event strictly before expiration | U | UNRESOLVED | none | not stated |
| C-C-08 | Permitted structure types (positive list) | U | UNRESOLVED | none | rev 20 |
| C-C-09 | Qualifying-events whitelist (earnings / PDUFA / FOMC) | U | UNRESOLVED | none | not stated |
| C-C-10 | Excluded event types | U | **2.6** (`08:544`, `08:561`) | none | not stated |
| C-C-11 | Deferral behavior when no compliant structure exists | O | UNRESOLVED | none | not stated |
| C-C-12 | Entry 1 — qualifying event within 45 days | U | UNRESOLVED | none | not stated |
| C-C-13 | Entry 2 — thesis inputs (4 quarters + sell-side + peers) | U | **2.14** (`08:549`) | none | not stated |
| C-C-14 | Sell-side handling clause | U | **2.6** (`08:544`, `08:561`) | none | rev 19 |
| C-C-15 | Entry 3 — adversarial counter-argument | O | **2.4** (`08:543`, `08:563`) | **2.13** (`08:548`) | not stated |
| C-C-16 | Entry 4 — max loss / breakeven / 5-scenario P&L | O | **2.11** (`08:543`, `08:546`) | **2.12** (`05:72`) | not stated |
| C-C-17 | Dual-path verification (closed-form vs Monte Carlo, ≤$1) | O | **2.12** (`05:42`, `08:565`) | none | rev 19 |
| C-C-18 | Entry 5 — ≥1 trading day before event | U | **2.2** (inline, `05:43`) | none | not stated |
| C-C-19 | Default exit — hold to expiration | O | UNRESOLVED | none | not stated |
| C-C-20 | Early-exit triggers (incl. ≥80% max profit) | O | UNRESOLVED | none | not stated |
| C-C-21 | "Not exit-triggering" list | O | UNRESOLVED | none | not stated |
| C-C-22 | Partial scale-out (multi-contract only) | O | UNRESOLVED | none | Rev 41 |
| C-C-23 | Declared frequency, HYBRID-FOMC: 0–8 trades/yr | F | UNRESOLVED | none | rev 22 |
| C-C-24 | Declared frequency, full eligibility: 8–15 trades/yr | F | UNRESOLVED | none | rev 22 |
| C-C-25 | Classical-method delegation (all numerical work to code) | O | **2.11 + 2.12** (inline, jointly, `05:72`) | none | not stated |
| C-C-26 | Router — SPY Trend ≠ DOWN | U | **2.7** (`08:553`) | none | not stated |
| C-C-27 | Router fundamental question (monthly template) | F | UNRESOLVED | none | not stated |
| C-C-28 | Primary edge-decay — EV/trade < 0 over rolling 10 | H | UNRESOLVED (`T1.ι` internal) | none | rev 9 |
| C-C-29 | Hit rate <45% — long debit verticals | H | UNRESOLVED — **derivation cites payoff geometry** (1:2–1:3 R/R, breakeven 25–33%), **not** a Tier 2 magnitude (`08:528`) | none | pre-rev-9 |
| C-C-30 | Hit rate <35% — butterflies | H | UNRESOLVED — same (natural hit rate ~30–40%) | none | rev 9 |
| C-C-31 | Hit rate <60% — premium-selling structures | H | UNRESOLVED — same | none | pre-rev-9 |
| C-C-32 | Win/loss magnitude ratio <1.0 over 15 closes | H | UNRESOLVED | none | not stated |
| C-C-33 | Cumulative excess real return vs SGOV <0 at 15 closes | H | UNRESOLVED | none | not stated |
| C-C-34 | 80%+ take-profit firing rate <30% | H | UNRESOLVED | none | not stated |
| C-C-35 | Intraday-drift monitoring >0.2% of capital at risk | H | **2.1** (`08:539`, `08:542`) | none | rev 5 |
| C-C-36 | 3-per-GICS-sector cap — **REMOVED (Rev 35)** | C | **2.8** (`08:545`) | none | removed Rev 35 |
| C-C-37 | HYBRID router state — FOMC-only | U | **2.7** (`08:553`) | 2.6 (contextual, `08:608`) | cycle-1 divergence review |
| C-C-38 | Live-small sizing — first 5 post-widening trades at 1% | P | UNRESOLVED | none | rev 7 |
| C-C-39 | Live-small trigger (i) — loss exceeding at-entry bound | H | UNRESOLVED (2.12/2.19 named as *causes*, not mitigation targets) | none | rev 7 |
| C-C-40 | Live-small trigger (ii) — contamination review ≤5 days | F | UNRESOLVED | none | rev 8 / rev 9 |
| C-C-41 | Live-small trigger (iii) — end-of-phase AR_orc review | F | UNRESOLVED | none | rev 8; automated 2026-07-10 |
| C-C-42 | Monthly deferral-rate review (>80% → growth-gate flag) | F | UNRESOLVED | none | not stated |
| C-C-43 | Monthly code-stack health check (third-path verify) | F | **2.12** (`08:598`, `08:565`) | none | rev 5 / rev 3 |
| C-C-44 | At 20 trades — cumulative excess real return < −5% flag | H | UNRESOLVED | none | not stated |
| C-C-45 | At 30 trades — gate evaluation | F | UNRESOLVED | none | not stated |
| C-C-46 | At 10 trades — preliminary edge assessment | F | UNRESOLVED | none | not stated |
| C-C-47 | KL2 — hit rate <40% earnings/PDUFA over 10 closes | H | **2.6** (`08:586`) | none | not stated |
| C-C-48 | KL4 — 15-trade calibration check | H | **2.13** (`08:590`) | none | not stated |
| C-C-49 | KL7 — 15-trade retrieval-vs-analysis audit (>30%) | H | **2.19** (`08:596`) | none | not stated |
| C-C-50 | KL9 — early-assignment loss exceeding bound | H | UNRESOLVED | none | rev 3 / rev 4 |
| C-C-51 | KL11 — 15-trade recalibration of EV/hit-rate thresholds | F | UNRESOLVED | none | rev 19 / rev 8 / rev 9 |

**Foundation citation graph — C.** Edges **1.1, 1.4** (`05:8`; 1.4 is used as a *technique within* 1.1, not separately load-bearing — rev 21). Disadvantages **2.1, 2.2, 2.4, 2.6, 2.7, 2.8, 2.11, 2.12, 2.13, 2.14, 2.15, 2.18, 2.19**.
**2.11 is load-bearing for C** and is cited in both documents *exclusively* as the disadvantage compensated by classical-method delegation (C-C-16, C-C-25) — never as a threshold or sizing driver. This is the item A1 found **worsened ~88%** (20–24% → 37–45%), triggering A1's §5.2 pre-mortem re-open for C. That is a *worsening* pathway, not a reduction pathway, and produces no A2 relaxation (§2.3).

---

## 1.4 Strategy D — Long-horizon narrative-screened equity core

**Mechanism doc:** `strategy/06_strategy_d.md` (latest inline tag **Rev 41**). **Pre-mortem:** rev **5** (2026-04-25, ACCEPTED) — `08:626`. **Constraints: 48.** D is the only `review_cadence: long_horizon` strategy and carries the corpus's densest cadence surface (11 of its 48 constraints are cadence rules).

| ID | Constraint | Type | Primary citation | Secondary | Rev added |
|---|---|---|---|---|---|
| C-D-01 | **2% of strategy portfolio per position** | **P** | UNRESOLVED at its own site | **explicit confluence** 2.4, 2.8, 2.13, 2.15, 2.17, 2.19 (`08:744`) | not stated |
| C-D-02 | Add-on tranche sizing (2% each, no cumulative cap) | P | UNRESOLVED | none | Rev 40 |
| C-D-03 | US-listed common equity / ADR eligibility | U | UNRESOLVED | none | not stated |
| C-D-04 | Market cap ≥ $10B at entry | U | UNRESOLVED | none | not stated |
| C-D-05 | 30-day ADV ≥ $20M | U | UNRESOLVED | none | not stated |
| C-D-06 | Long-only | U | UNRESOLVED | none | not stated |
| C-D-07 | Thesis must be Subtype A or B | U | **2.19** (`06:14`) | none | rev 28 / pre-mortem rev 4 |
| C-D-08 | Typing rule for dual-signal theses | U | UNRESOLVED (`T1-1` internal) | none | rev 30 |
| C-D-09 | 12+ month realization-timeline requirement | U | UNRESOLVED | none | rev 28 |
| C-D-10 | Entry 4 (general) — immutable completion + invalidation | U | **2.4** (Constraint 1, `08:748`) | none | rev 28 |
| C-D-11 | Entry 4 (subtype-specific) — public-observable invalidation | U | **2.6** (Constraint 3, `08:758`) | none | rev 28 / pre-mortem rev 3–4 |
| C-D-12 | Metric-immutability auto-invalidation (Subtype B) | U | UNRESOLVED (`T1-3` internal) | none | rev 30 |
| C-D-13 | Entry 6 — momentum-deferral (trailing-30d rally) | U | **2.14** (inline, `06:49`) | **2.20** (`08:736`) | not stated |
| C-D-14 | Router — (SPY UP or NEUTRAL) AND Inversion NOT-SUSTAINED | U | **2.7** (`08:722`) | none | not stated |
| C-D-15 | Add-on hard gate — invalidation unbreached | U | UNRESOLVED | none | Rev 40 |
| C-D-16 | Adds inherit eligibility / sector / momentum rules | U | UNRESOLVED | none | Rev 40 |
| C-D-17 | 5–10 position deliberate concentration band | C | UNRESOLVED | none | not stated |
| C-D-18 | Concurrent-position floor (min 5) | C | UNRESOLVED | none | Rev 40 (tranche counting only) |
| C-D-19 | Concurrent-position maximum — **REMOVED (Rev 35)** | C | UNRESOLVED | none | removed Rev 35 |
| C-D-20 | **Entry 5 — >30%-of-NAV GICS-sector exposure cap** | **C** | **2.8** — "*Mitigation:* the 30% GICS-sector cap (retained)" (`08:724`) | 2.4, 2.13, 2.15, 2.17, 2.19 (`08:744`) | not stated |
| C-D-21 | Correlation-bucket cap at entry — **REMOVED (Rev 35)** | C | **2.8** (`08:744`) | none | rev 26/27/28; removed Rev 35 |
| C-D-22 | Post-entry correlation blocking (>0.7) — **REMOVED (Rev 35)** | C | **2.8** (`08:744`) | none | rev 28; removed Rev 35 |
| C-D-23 | Theme-concentration cap (max 3/theme) — **REMOVED (Rev 35)** | C | **2.8** (`08:724`) | none | rev 2; removed Rev 35 |
| C-D-24 | Multi-tranche name = ONE position toward floor | C | UNRESOLVED | none | Rev 40 |
| C-D-25 | Declared trade frequency 3–8/yr | F | UNRESOLVED | none | not stated |
| C-D-26 | No maximum hold | F | UNRESOLVED | none | not stated |
| C-D-27 | Monthly review — position-level thesis check | F | UNRESOLVED | none | not stated |
| C-D-28 | Monthly review — sector-concentration monitoring | F | UNRESOLVED | none | not stated |
| C-D-29 | Monthly review — correlation-bucket monitoring | F | **2.8** (`08:744`) | none | rev 2/3/4 |
| C-D-30 | Monthly review — LTCG-line tracking (>9mo) | F | UNRESOLVED | none | rev 2 |
| C-D-31 | Monthly review — deployment count (<5 for ≥3mo) | F | UNRESOLVED | none | not stated |
| C-D-32 | 12-month gate — first comprehensive review | F | UNRESOLVED | none | not stated |
| C-D-33 | 24-month gate — second comprehensive review | F | UNRESOLVED | none | rev 3/4/5 |
| C-D-34 | 36-month gate — MTM trigger becomes operative | F | UNRESOLVED | none | not stated |
| C-D-35 | Rolling-36mo evaluation cadence (invalidation count) | F | UNRESOLVED | none | not stated |
| C-D-36 | 24-mo beta-adjusted alpha test with CI gate | H | UNRESOLVED (`T1-4` internal) | none | rev 4 / rev 5 |
| C-D-37 | SGOV-underperformance signal ≥5pp @ 24mo | H | UNRESOLVED | none | cycle 2 T1-D |
| C-D-38 | Thesis-invalidation count ≥3 / 36mo | H | UNRESOLVED | none | not stated |
| C-D-39 | EV per closed position, rolling 5 closes | H | UNRESOLVED | none | not stated |
| C-D-40 | 36-mo MTM / drawdown kill trigger | H | UNRESOLVED | none | not stated |
| C-D-41 | Idle-capital parking rule (SGOV→VOO) | O | UNRESOLVED | none | Rev 38 |
| C-D-42 | Entry 2 — thesis construction inputs (8q + 2 annual) | O | **2.14** (`08:728`) | none | not stated |
| C-D-43 | Entry 3 — adversarial counter-argument, multi-year risks | O | **2.4** (`08:748`, `08:718`) | none | not stated |
| C-D-44 | Exit — thesis completion | O | UNRESOLVED | none | not stated |
| C-D-45 | Exit — thesis invalidation (not price alone) | O | UNRESOLVED | none | not stated |
| C-D-46 | LTCG-preference exit — **REMOVED (Rev 39)** | O | **2.23** (`06:8`) | none | removed Rev 39 (2026-07-21) |
| C-D-47 | "Not exit-triggering" exclusions list | O | UNRESOLVED | none | not stated |
| C-D-48 | Partial exit (trim) authorization | O | UNRESOLVED | none | Rev 41 |

**Foundation citation graph — D.** Edges **1.1, 1.4, 1.10** (`06:8`). Disadvantages **2.4, 2.6, 2.7, 2.8, 2.13, 2.14, 2.15, 2.17, 2.19, 2.20, 2.23** (eleven — matches the pre-mortem's own "five-of-eleven / six-of-eleven" cross-walk tally at `08:746`).

**D-specific finding (C-D-46) — 2.23's compensation mechanism was removed while the citation remained.** D's thesis still reads "Compensates 2.23 (tax and fee drag) through LTCG-optimized holding periods" (`06:8`), and `strategy/roster.yaml` lists **2.23 as D's sole `disadvantages_compensated` entry**. But the pre-mortem cross-walk names the **LTCG-preferred exit** as 2.23's mitigation route (`08:746`), and **Rev 39 (2026-07-21) removed that exit rule** — "exit timing is governed solely by thesis completion/invalidation; no preference to delay a completion-triggered exit for LTCG qualification" (`06:65`). LTCG treatment now applies only **passively**, when the 12-month line happens to have been crossed before thesis criteria fire.
This is **not** a relaxation candidate and requires **no A2 action** — 2.23 is Tier 1 (ineligible at Step 1) and its A1 2026 magnitudes were *confirmed*, not reduced. It is recorded here because it is a citation-graph accuracy defect that A3 §F may wish to reconcile, and because it is precisely the kind of drift a constraint audit exists to surface.

---

## 1.5 Strategy E — Market-neutral narrative-divergence pairs

**Mechanism doc:** `strategy/07_strategy_e.md` (latest inline tag **Rev 41**). **Pre-mortem:** rev **5** (2026-04-25, ACCEPTED) — `08:817`. **Constraints: 34.**

| ID | Constraint | Type | Primary citation | Secondary | Rev added |
|---|---|---|---|---|---|
| C-E-01 | Universe excludes private-information-derived theses | U | **2.6** (`07:10`, Constraint 1 `08:967`) | none | not stated |
| C-E-02 | Public-information compliance check (forbidden phrases) | U | **2.6** (via Constraint 1, `08:881`) | none | not stated |
| C-E-03 | Auditability-to-public-sources requirement | U | UNRESOLVED | none | not stated |
| C-E-04 | Same 6-digit GICS industry group pairing | U | UNRESOLVED | **2.8** (`08:939`) | not stated |
| C-E-05 | **2% of strategy portfolio per leg** | **P** | **No single primary — explicit confluence** of 2.4, 2.13, 2.15, 2.18, 2.19, 2.24, 2.26 (`08:963`, `08:965`) | none | rev 5 added 2.24 |
| C-E-06 | 4% per pair thesis (2 legs) | C | UNRESOLVED | same confluence | not stated |
| C-E-07 | Max simultaneous deployment ~24–48% *(derived, not authored)* | C | UNRESOLVED | none | not stated |
| C-E-08 | ETF-pair substitution rule | U | UNRESOLVED | none | not stated |
| C-E-09 | Entry 1 — quantitative reconvergence threshold | U | **2.24** (Constraint 3, `08:971`; rev 4 walks back its strength, `08:973`) | none | rev 3 / rev 4 |
| C-E-10 | Entry 2 — adversarial counter-argument | U | **2.4** (`08:867`) | none | not stated |
| C-E-11 | Entry 3a — L–S correlation ≥0.5 (trailing 252d) | U | UNRESOLVED | 2.17 discontinuity noted (`08:945`, `08:1036`) | not stated |
| C-E-12 | Entry 3b — beta-adjusted leg sizing | O | UNRESOLVED | none | not stated |
| C-E-13 | Entry 3c — 95th-percentile divergence anchor | U | UNRESOLVED (rev tag names no foundation item) | **2.4** (`08:933`), **2.24** (`08:955`, `08:972`) | rev 2 / rev 3 |
| C-E-14 | Entry 3d — spread-definition rule (3× share-price ratio) | O | UNRESOLVED | none | rev 3 |
| C-E-15 | Entry 4 — expected holding period 1–6 months | O | UNRESOLVED | none | not stated |
| C-E-16 | Entry 5 Anchor 1 — financing ≤15% of expected return | U | **2.13 + 2.26** (Constraint 4, jointly, `08:977`) | none | rev 2 |
| C-E-17 | Entry 5 Anchor 2 — deterministic reference-set gate | U | **2.13 + 2.26** (Constraint 4, `08:977`) | none | rev 3 |
| C-E-18 | Pair-prioritization deterministic rank order | O | **2.4 + 2.24** (`08:883`) | none | rev 4 |
| C-E-19 | Exit — convergence target reached | O | UNRESOLVED | none | not stated |
| C-E-20 | Exit — thesis invalidation | O | UNRESOLVED | none | not stated |
| C-E-21 | Exit — time-based at 6 months | O | **2.18** (`08:888`, `08:947`) | KL17 2.18×2.13/2.26 (`08:1046`) | rev 2 |
| C-E-22 | Exit — correlation breakdown <0.3 (60d rolling) | O | UNRESOLVED | none | not stated |
| C-E-23 | Partial exit — both legs proportionally, no naked leg | O | UNRESOLVED | none | Rev 41 (postdates pre-mortem) |
| C-E-24 | Declared frequency 6–12 pair theses/yr | F | UNRESOLVED | none | rev 2 reconciliation |
| C-E-25 | Router — SPY≠DOWN AND VIX≠HIGH AND Breadth HEALTHY | O | **2.7** (`08:937`; framed as a *contradiction* at `08:895`) | none | not stated |
| C-E-26 | Monthly — borrow-rate cap >10% annualized → close | O | UNRESOLVED | none | not stated |
| C-E-27 | Monthly — correlation drift-band 0.3–0.5 flag | F | UNRESOLVED | none | rev 2 |
| C-E-28 | Portfolio financing drag ratio >25% → flag | H | UNRESOLVED | none | rev 2 |
| C-E-29 | Mean entry-time borrow cost trend >50%/12mo → flag | H | UNRESOLVED | none | rev 2 |
| C-E-30 | Pair convergence rate <50% over rolling 10 closes | H | UNRESOLVED — derivation cites **pairs-trading literature** (50–70% in-sector convergence), not a Tier 2 magnitude | none | rev 2 |
| C-E-31 | Convergence-vs-expiry ratio <1:1 over 10 closes | H | UNRESOLVED | none | rev 2 |
| C-E-32 | Cumulative excess real return vs SGOV <0 at 10 closes | H | UNRESOLVED | none | not stated |
| C-E-33 | Entry-percentile vs realized-P&L rank correlation <0 | H | UNRESOLVED | none | rev 2 |
| C-E-34 | At 15 pair closes (30 trades) — gate evaluation | F | UNRESOLVED | none | not stated |

**Foundation citation graph — E.** Edges **1.1, 1.4, 1.10** (`07:8`). Disadvantages **2.4, 2.6, 2.7, 2.8, 2.13, 2.15, 2.17, 2.18, 2.19, 2.20, 2.23, 2.24, 2.26** (thirteen — matches the pre-mortem's own "seven-of-thirteen / five-of-thirteen" tally at `08:965`, and matches A1's F.1 graph exactly).
**2.24 is declared load-bearing for E** (`08:955`) — the heaviest single citation in the corpus (A1 counts ×42).

**E-specific note (not an A2 action):** the generated slice `07_strategy_e.md` is materially **behind** the pre-mortem's Section 1 — it lacks the 95th-percentile divergence anchor, the spread-definition rule, the dual-anchor financing gate and the pair-prioritization rule, all of which are rev 2–4 additions present only in the pre-mortem. This audit inventoried the union of both. Slice/canonical drift is `scripts/split_strategy.py` territory, not a constraint-relaxation matter.

---

## 1.6 Experiment-level constraints binding every strategy

From `Experiment_Parameters.md` and `strategy/00_preamble.md`. These are **not** per-strategy constraints and are inventoried because §5.6's relaxation lookup names the per-position sizing cap as its worked example, and that cap is defined here.

| ID | Constraint | Type | Primary citation | Immutability |
|---|---|---|---|---|
| X-01 | **2% of strategy portfolio per trade** (`EP:272`) | P | **UNRESOLVED** — derivation cites institutional consensus + streak arithmetic, no `1.X`/`2.X` | **GLOBALLY IMMUTABLE** (`EP:8`, `EP:161`, `00:8`, `00:33`) |
| X-02 | Risk via sizing, not stop-losses (`EP:282`) | O | UNRESOLVED | per-strategy machinery tier |
| X-03 | Capital preservation over return maximization (`EP:211`) | O | **2.18** (explicit) | not separately flagged |
| X-04 | Declared expected trade frequency (`EP:212`) | F | UNRESOLVED | not load-bearing on a kill trigger |
| X-05 | Two-signal technical+fundamental cross-check (`EP:224–231`) | O | **2.7** (explicit, `EP:231`) | indicator set/template immutable once trading begins |
| X-06 | Indicator set / fundamental template frozen (`EP:666–667`) | O | none stated | absolute ("immutable once trading begins") |
| X-07 | No inter-strategy rebalancing (`EP:149`) | O | UNRESOLVED | functionally locked |
| X-08 | Capital-allocation split bound [0.5×, 2×] (`EP:130`) | O | none | **explicitly VERSIONED POLICY** (carve-out, `EP:159`) |
| X-09 | Roster floor N≥2 / ceiling N_max=8 (`EP:199`) | O | none | **versioned policy** (governance rail) |
| X-10 | Probe-stake floor $2,000 (`EP:136`) | O | none | "adjustable parameter" vs "unchanged" (minor internal tension) |

**Kill criteria (per-strategy, experiment-level):** drawdown (TWR −50% from high-water), foundation-change trigger, runaway-success review (cited **2.18**, `EP:330`), 36-month mark-to-market underperformance (≥10pp vs SGOV over rolling 12m), and the 30-trade gate. All are named among the **globally immutable** "mechanical kill-trigger structure" (`EP:8`).

---

## 1.7 Citation-graph reconciliation — three sources disagree

Three artifacts record per-strategy foundation citations and they do **not** agree. §5.3 step 1 mandates the parse be taken from **the strategy's mechanism document and pre-mortem**, so this audit uses that as authoritative and records the divergences:

| Strategy | This audit (mechanism + pre-mortem) | `strategy/roster.yaml` `disadvantages_compensated` | A1 2026 §F.1 |
|---|---|---|---|
| A | 2.3, 2.4, 2.5, 2.8, 2.13, 2.14, 2.19, 2.20 | 2.4, 2.13, **2.15**, **2.17**, 2.19 | 2.3, 2.4, 2.5, 2.8, 2.13, 2.14, 2.19, 2.20 |
| B | 2.4, 2.8, 2.13, 2.14, 2.15, 2.17, 2.18, 2.19, 2.20 | *(empty — B compensates none)* | same as this audit |
| C | 2.1, 2.2, 2.4, 2.6, 2.7, 2.8, 2.11, 2.12, 2.13, 2.14, 2.15, 2.18, 2.19 | 2.1, 2.18 (+ 2.11 in a comment) | same as this audit |
| D | 2.4, 2.6, 2.7, 2.8, 2.13, 2.14, 2.15, 2.17, 2.19, 2.20, 2.23 | 2.23 | same as this audit |
| E | 2.4, 2.6, 2.7, 2.8, 2.13, 2.15, 2.17, 2.18, 2.19, 2.20, 2.23, 2.24, 2.26 | 2.7, 2.20 | same as this audit |

**Reading.** This audit and A1 2026 agree on all five graphs — two independent parses of the same sources, one per-constraint and one per-item. `roster.yaml`'s field is **narrower by design** (it records *compensated* disadvantages, a subset of *cited* ones) and its header states it was "parsed from `Quarterly_AI_Foundation_Delta.md` PART 2 … + `strategy/` mechanism slices," i.e. from the Q2 delta, which predates A1's correction.

**One roster row is not merely narrow but wrong:** roster lists **A** as compensating **2.15 and 2.17**. Neither appears anywhere in A's mechanism doc or pre-mortem. A1 2026 independently re-derived and confirmed this ("Strategy A does **not** cite 1.4, 2.15 or 2.17 anywhere"), and the Q2 delta carries the same error at `:202`. **No A2 action** — 2.15 and 2.17 both classify NONE this cycle, so nothing turns on it operationally — but A3 §F should reconcile `roster.yaml` (and D's 2.23 row, §1.4) against the corrected graphs. Recorded as framework flag **F-4**.

---

# PART 2 — Mechanical per-constraint relaxation verdicts

> **A3 reads this PART verbatim.** Per-constraint outcomes are explicit below.

## 2.0 STEP 1 — Reduction status of every Part-2 disadvantage (the master gate)

Step 1 is evaluated **once per foundation item**, not once per constraint: a constraint's Step 1 outcome is entirely determined by its primary citation's reduction class. Tier is from `AI_Trading_Foundation.md` rev 5. Evidence is from `Annual_AI_Foundation_Sweep.md` (A1 2026) and `Quarterly_AI_Foundation_Delta.md` (2026-Q2).

**§5.4 controlling rule:** *"For Tier 1 items: no PARTIAL/MATERIAL reduction thresholds apply. Tier 1 items don't get reduced — they get architecturally changed… The constraint-relaxation pathway is Tier-2-only."*

| Item | Tier | **Reduction** | Basis |
|---|---|---|---|
| 2.1 execution latency | T1 | **NONE** *(ineligible)* | Reframed chosen-not-ceiling; "remain TRUE of this workflow" |
| 2.2 no real-time monitoring | T1 | **NONE** *(ineligible)* | Same reframe |
| 2.3 hallucination | T1e/T2m | **NONE** | **L1 REGRESSION** — Opus 5 hallucination rate 6% *higher* than 4.8. Guardrails: replication FAIL, sustained FAIL, domain FAIL |
| 2.4 narrative over-fit | T1e/T2m | **NONE** | SPARSE — no magnitude at any evidence level; magnitude → VERSION-PENDING |
| 2.5 training cutoff | T1 | **NONE** *(ineligible)* | Quantified (May 2026), unchanged in kind |
| 2.6 no private information | T1 | **NONE** *(ineligible)* | KEEP UNCHANGED |
| 2.7 regime maladaptation | T1e/T2m | **NONE** | Benchmark trajectory **flat-to-negative**; "No reduction; guardrails not reached" |
| 2.8 homogenization | T1e/T2m | **NONE** | Concentration metric moved the **other** way; §5.5 records **no benchmark mapping** for 2.8 |
| 2.9 version drift | T1 | **NONE** *(ineligible)* | Unchanged in kind |
| **2.10 prompt injection** | T1e/T2m | **NONE** *(downgraded at Step 2)* | Sole PARTIAL candidate → **§5.5 guardrail 1 (replication) FAIL** + **guardrail 4 (domain coverage) FAIL** → Step 2 downgrades to NONE. Also capital-inert: **no strategy cites 2.10** |
| 2.11 numerical precision | T1 | **NONE** *(ineligible)* | Tier 1. Separately **WORSENED ~88%** (20–24% → 37–45%) — a §5.2 pathway, not §5.3 |
| 2.12 tabular weakness | T1 | **NONE** *(ineligible)* | Unchanged |
| 2.13 miscalibration | T1e/T2m | **NONE** | Best Claude ECE **0.120** vs documented 0.122 low end = **flat, not reduced** |
| 2.14 recency bias | T1e/T2m | **NONE** | SPARSE — absent at **all four** evidence levels; magnitude → VERSION-PENDING |
| 2.15 base-rate neglect | T1e/T2m | **NONE** | SPARSE; replication FAIL; magnitude → VERSION-PENDING |
| 2.16 syntactic matching | T1 | **NONE** *(ineligible)* | Unchanged/unfavourable |
| 2.17 algorithm appreciation | T1e/T2m | **NONE** | Direction **CONTRADICTED**, not reduced; replication FAIL |
| 2.18 instruction adherence | T1 | **NONE** *(ineligible)* | **STRENGTHENED** |
| 2.19 look-ahead bias | T1e/T2m | **NONE** | Contamination **confirmed and larger**; only the Scaling-Paradox sub-claim removed — a conservative-direction correction |
| 2.20 textbook-rational penalty | T1e/T2m | **NONE** | Heterogeneous ~50% sits in the MATERIAL band **but** guardrail 1 FAIL (single source, contradicted by `2502.15800`), guardrail 4 questionable |
| 2.21 min sample size | T1 | **NONE** *(ineligible)* | Figures untraceable → VERSION-PENDING |
| 2.22 path dependency | T1 | **NONE** *(ineligible)* | Mathematical |
| 2.23 tax/fee drag | T1 | **NONE** *(ineligible)* | Magnitudes **CONFIRMED** |
| 2.24 cross-session inconsistency | T1 | **NONE** *(ineligible)* | Confirmed + a new channel added |
| 2.25 agentic epistemic hallucination | T1 | **NONE** *(ineligible)* | Slightly **worse** at L1 |
| 2.26 RL overconfidence | T1 | **NONE** *(ineligible)* | Unchanged |

**Result: 0 of 26 items classify PARTIAL or MATERIAL.** Fifteen are Tier 1 and ineligible by §5.4 rule. Eleven carry Tier 2 magnitudes and every one classifies NONE on the evidence. **2.10 is the only item that reached Step 2, and it failed there.**

**A1's five proposed NEW disadvantages (2.27–2.31) are excluded from this table** and from every load-bearing test below: they are **not yet in `AI_Trading_Foundation.md`** (rev 5 ends at 2.26). A3 §A adds them. A newly-added disadvantage is in any case a §5.2 *strengthening* input, never a §5.3 reduction input, so their absence cannot have suppressed a relaxation.

---

## 2.1 Termination-reason codes

Every constraint's Step 1 verdict resolves to exactly one code:

| Code | Meaning | Constraints |
|---|---|---|
| **N-T1** | Primary citation is a pure **Tier 1** item → §5.4: Tier 1 items get no reduction classification; relaxation pathway is Tier-2-only | 19 |
| **N-T2** | Primary citation is a **Tier-2-magnitude** item whose 2026 classification is **NONE** | 35 |
| **N-UNRES** | **No parseable primary citation** → no cited disadvantage exists that could have been reduced → §5.3 criterion unmet (deterministic; see §1.0) | 147 |
| **N-G** | Reduction signal existed but failed §5.5 guardrails at Step 2 → downgraded to NONE | **0** — 2.10 is the only Step-2 case and **no strategy cites 2.10** |
| | | **201** |

**No constraint carries any other code.** Steps 2, 3 and 4 are unreached for all 201.

---

## 2.2 Per-strategy §5.7 audit trail

Each block is the §5.7 structured output: (1) identifier + revision, (2) citation graph, (3) per-citation status change, (4) outcome verdict, (5) relaxation candidates, (6) out-of-table flags.

### Strategy A
1. **Strategy A** — mechanism at Rev 41 (2026-07-22); pre-mortem rev 7 (ACCEPTED).
2. **Citation graph:** edges 1.1, 1.10; disadvantages 2.3, 2.4, 2.5, 2.8, 2.13, 2.14, 2.19, 2.20.
3. **Per-citation status since A's foundation revision:** 2.3 **INCREASE** (L1 regression) · 2.4 magnitude → VERSION-PENDING · 2.5 quantified, unchanged in kind · 2.8 worsening · 2.13 flat · 2.14 magnitude → VERSION-PENDING · 2.19 confirmed larger, sub-claim removed · 2.20 scope refined. **Reduction class: NONE on all eight.**
4. **Outcome:** no constraint-relaxation review for any A constraint. (A1 separately returns CONTINUE for A under §5.1/§5.2.)
5. **Relaxation candidates: none.** 33/33 terminate at Step 1 — 5 via N-T2, 28 via N-UNRES.
6. **Out-of-table flags: none** (Step 4 unreached).

### Strategy B
1. **Strategy B** — mechanism at Rev 41; pre-mortem rev 7 (ACCEPTED).
2. **Citation graph:** edges 1.1, 1.4; disadvantages 2.4, 2.8, 2.13, 2.14, 2.15, 2.17, 2.18, 2.19, 2.20. B **compensates none**; it is structurally exposed to 2.20.
3. **Per-citation status:** 2.4 VP · 2.8 worsening · 2.13 flat · 2.14 VP · 2.15 VP · 2.17 direction contested · 2.18 strengthened · 2.19 confirmed larger · 2.20 scope refined (heterogeneous markets bubble ~50% — makes B's exposure *real rather than hypothetical*, an adverse refinement). **Reduction class: NONE on all nine.**
4. **Outcome:** no constraint-relaxation review.
5. **Relaxation candidates: none.** 35/35 terminate at Step 1 — 7 via N-T2, 2 via N-T1 (2.18), 26 via N-UNRES.
   **Note on C-B-24 (the HIGH-VIX exclusion), the one constraint whose primary citation is 2.20:** 2.20 is the only item this cycle whose figure (~50% bubble participation) reaches the §5.4 **MATERIAL** band. It classifies NONE solely because §5.5 guardrail 1 fails. Had it cleared, C-B-24 would still not relax — it is a **universe restriction**, and §5.6 gives universe restrictions **no graded relaxation**; MATERIAL-with-full-elimination is required even to *reconsider* removal, and 2.20 is neither eliminated nor sole-cited. B's own mechanism additionally carries an explicit standing directive against loosening it: *"the SP1/2.20 short gating is **not** to be loosened"* (`04:74`).
6. **Out-of-table flags: none.**

### Strategy C
1. **Strategy C** — mechanism at Rev 41; pre-mortem rev 9 (ACCEPTED).
2. **Citation graph:** edges 1.1, 1.4; disadvantages 2.1, 2.2, 2.4, 2.6, 2.7, 2.8, 2.11, 2.12, 2.13, 2.14, 2.15, 2.18, 2.19.
3. **Per-citation status:** 2.1/2.2 reframed · 2.7 magnitude added (flat-to-negative) · **2.11 WORSENED ~88%** · 2.12 citation closed · 2.13 flat · 2.14 VP · 2.15 VP · 2.18 strengthened · 2.19 confirmed larger. **Reduction class: NONE on all thirteen.**
4. **Outcome:** no constraint-relaxation review. **A1 separately fires the §5.2 mechanical test on 2.11 and re-opens C's pre-mortem** — that is a *tightening* pathway routed through A3 §B, and is explicitly **not** an A2 relaxation input. A2 records it so A3 does not conflate the two.
5. **Relaxation candidates: none.** 51/51 terminate at Step 1 — 7 via N-T2, 10 via N-T1 (2.1, 2.2, 2.6, 2.11, 2.12, 2.18), 34 via N-UNRES.
   **Note on C's hit-rate thresholds (C-C-29/30/31), the corpus's best-populated §5.6 hit-rate category:** these do not relax even in principle. §5.6's hit-rate row states *"Default: no automatic relaxation unless the threshold's derivation explicitly cites a Tier 2 disadvantage magnitude."* Their derivations cite **payoff geometry** — 1:2–1:3 risk/reward placing breakeven at 25–33%; butterflies' ~30–40% natural hit rate — not any Tier 2 magnitude. The §5.6 default therefore binds independently of Step 1.
6. **Out-of-table flags: none.**

### Strategy D
1. **Strategy D** — mechanism at Rev 41; pre-mortem rev 5 (ACCEPTED).
2. **Citation graph:** edges 1.1, 1.4, 1.10; disadvantages 2.4, 2.6, 2.7, 2.8, 2.13, 2.14, 2.15, 2.17, 2.19, 2.20, 2.23.
3. **Per-citation status:** 2.7 magnitude added · 2.8 worsening · 2.13 flat · 2.14 VP · 2.15 VP · 2.17 contested · 2.19 confirmed larger · 2.20 scope refined · 2.23 **refreshed and confirmed** (5–8% breakeven band confirmed, not widened). **Reduction class: NONE on all eleven.**
4. **Outcome:** no constraint-relaxation review.
5. **Relaxation candidates: none.** 48/48 terminate at Step 1 — 11 via N-T2, 2 via N-T1 (2.6, 2.23), 35 via N-UNRES.
   **Note on C-D-20 (the >30%-of-NAV GICS-sector cap) — the single most consequential row in this audit.** It is the **only live `C`-type concentration limit remaining in the entire corpus** (Rev 35 removed A's, B's and C's sector count caps, D's correlation-bucket cap C-D-21/22 and D's theme cap C-D-23; D's position-count floor C-D-18 is a floor, not a cap). It is also the one constraint whose primary citation is unambiguously recoverable *and* whose type has a graded §5.6 relaxation form. Its primary citation is **2.8**, named directly as its mitigation target — *"the 30% GICS-sector cap (retained) … partially address single-theme over-allocation"* (`08:724`). **2.8's 2026 reduction class is NONE — and pointedly so: the trading-agent concentration metric moved in the *adverse* direction, and §5.5 records that 2.8 has no benchmark mapping at all, so it is reducible only by explicit-research signal, which does not exist.** Step 1 terminates. Had 2.8 somehow classified PARTIAL, Step 3 would then have applied: C-D-20 is also named in D's cross-constraint confluence alongside 2.4, 2.13, 2.15, 2.17 and 2.19 (`08:744`), every one of which remains in force — so the load-bearing test would have failed it regardless. **This constraint is doubly protected and does not move.**
6. **Out-of-table flags: none.**

### Strategy E
1. **Strategy E** — mechanism at Rev 41; pre-mortem rev 5 (ACCEPTED).
2. **Citation graph:** edges 1.1, 1.4, 1.10; disadvantages 2.4, 2.6, 2.7, 2.8, 2.13, 2.15, 2.17, 2.18, 2.19, 2.20, 2.23, 2.24, 2.26.
3. **Per-citation status:** 2.7 magnitude added · 2.8 worsening · 2.13 flat · 2.15 VP · 2.17 contested · 2.18 strengthened · 2.19 confirmed larger · 2.20 scope refined · 2.23 confirmed · **2.24 confirmed + second channel added** · 2.26 citations fixed. **Reduction class: NONE on all thirteen.**
4. **Outcome:** no constraint-relaxation review.
5. **Relaxation candidates: none.** 34/34 terminate at Step 1 — 5 via N-T2, 5 via N-T1 (2.6, 2.18, 2.24, 2.26), 24 via N-UNRES.
6. **Out-of-table flags: none.**

---

## 2.3 The two closest calls, worked explicitly

To demonstrate the machinery did not merely short-circuit, the two constraints nearest to a relaxation are worked to their actual stopping point:

**(a) The 2%-per-position sizing caps (C-A-07, C-B-05, C-C-05, C-D-01, C-E-05).** §5.6's worked example for a MATERIAL relaxation is a 2% cap. Four of the five strategies attribute their cap to an **explicit confluence** of disadvantages, with the pre-mortems stating no single primary (A: 2.4/2.13/2.14/2.19 · B: 2.4/2.13/2.14/2.15/2.20 · D: 2.4/2.8/2.13/2.15/2.17/2.19 · E: 2.4/2.13/2.15/2.18/2.19/2.24/2.26). C attributes its cap to 2.18 with a 2.1/2.4/2.13/2.15 confluence.
**Stopping point: Step 1** — every named item classifies NONE. **And Step 3 would independently block it:** a cap explicitly declared to flow from a confluence is load-bearing for *every* member, so a reduction in one member with the others still in force fails the load-bearing test by construction. A's pre-mortem makes this design intent explicit: the cap is listed at the cross-constraint level *"to avoid asymmetric per-constraint attribution"* (`08:257`). **And even past Step 4, F-1 and F-2 (§2.5) would each independently prevent execution.** Four independent barriers.

**(b) D's 30%-of-NAV GICS-sector cap (C-D-20).** Worked in full under Strategy D above. **Stopping point: Step 1** (2.8 = NONE), with Step 3 as an independent backstop.

---

## 2.4 Explicit annual review of frequency/cadence rules (§5.6 requirement)

§5.6 gives cadence rules **no automatic relaxation** and routes them to *"explicit review at the annual constraint audit (A2) with mechanical criteria specific to the cadence rule's purpose."* A2 is that review; it is performed here.

**Cadence rules in scope (35):** C-A-23, C-A-26…C-A-30 (6) · C-B-10, C-B-21, C-B-26, C-B-27, C-B-35 (5) · C-C-23, C-C-24, C-C-27, C-C-40, C-C-41, C-C-42, C-C-43, C-C-45, C-C-46, C-C-51 (10) · C-D-25…C-D-35 (11) · C-E-24, C-E-27, C-E-34 (3).

**Review performed.** Each cadence rule was checked for (i) a recoverable foundation citation and (ii) any status change on it. Results:
- **33 of 35 have no recoverable foundation citation at all** (N-UNRES). A cadence rule with no cited disadvantage has no disadvantage-keyed purpose against which "mechanical criteria specific to the cadence rule's purpose" could be written.
- **2 have one:** C-C-43 (monthly code-stack health check → **2.12**, Tier 1) and C-D-29 (monthly correlation-bucket monitoring → **2.8**, Tier 2 but classified NONE — and now monitoring-only since Rev 35 removed its blocking behaviour). Both terminate at Step 1.
- **D's trade-frequency vs review-cadence split**, called for by D's `long_horizon` status: *trading* frequency is **C-D-25** (3–8 trades/yr, entries and exits counted separately ≈ 1.5–4 round-trips/yr) and **C-D-26** (no maximum hold); *review* cadence is the nine rules **C-D-27…C-D-35** — five monthly checks plus the 12/24/36-month gates and the rolling-36-month evaluation. None carries a reduction-eligible citation. D's own mechanism records that its 30-trade gate "will likely not be reached within any stable model-generation window" and that this is "an accepted, documented property, not a flaw" (`06:82`) — so its cadence rules are load-bearing on the *kill-trigger* path, which §5.6 does not relax and `Experiment_Parameters.md` marks globally immutable.

**Verdict: all 35 cadence rules HOLD at current values.** The §5.6-mandated review is complete and recorded. Its one substantive finding — that the promised *"mechanical criteria specific to the cadence rule's purpose"* have never been authored, so the annual review has no criteria to apply beyond confirming the citation status — is raised as framework flag **F-5**.

---

## 2.5 §5.7 item 6 — Out-of-table flags

**Per-constraint flags: ZERO.** §5.6's out-of-table branch is a **Step 4** branch, reachable only by constraints that pass Steps 1–3. No constraint passed Step 1. The 39 `O`-typed constraints in PART 1 are therefore *typed* out-of-table but were never *flagged*, and **A3 must not enqueue `out-of-table-resolution` reviews for them.** (This matches A2's own prediction that out-of-table flags are rare.)

**Framework-level flags: SIX raised, TWO resolved same-day, FOUR open for A3.** §5.7 item 6 requires reporting "any constraints **or items** the criteria couldn't deterministically resolve." The following are defects in the criteria themselves, surfaced by executing them end-to-end. Each is stated with its consequence and the evidence. **F-1 and F-2 were resolved by owner directive on 2026-07-28** (foundation rev 6 / `Experiment_Parameters.md` rev 17 / `Strategy.md` rev 38) and carry their resolution inline; **A3 enqueues only F-3 … F-6.**

---

**F-1 — ✅ RESOLVED 2026-07-28 (owner directive), same day as this audit · originally BLOCKING · The §5.6 relaxation pathway collided head-on with the two-tier immutability doctrine, which post-dated it.**

> **RESOLUTION (owner directive 2026-07-28).** A new **`AI_Trading_Foundation.md` §5.6a in-life constraint edit path** (foundation rev 6; mirrored to `Experiment_Parameters.md` rev 17 and `Strategy.md` rev 38) resolves this. It reuses the existing material-structural-difference test, **inverted**: an edit changing **none** of the five dimensions {strategy approach, instrument scope, position-sizing methodology, regime-router structure, kill-criteria structure} is *non-fundamental* and may be applied in life without terminating the strategy; an edit touching ≥1 dimension remains terminate-and-restart. Six rails gate a routine-executed edit (exogenous trigger only with an explicit parameter-fishing prohibition; loosen-only; per-position sizing and kill-trigger structure excluded; dated epoch stamp marking the measurement seam; one edit per strategy per annual cycle; CI-enforced provenance). **Owner's controlling rationale:** immutability is a *means* to a clean statistical read, and that premise is already spent — the model of record is changed mid-strategy regardless of whether a strategy has reached an adequate trade count for analysis (item 2.9; Part 4 step 4), so a series already discontinuous at owner-driven model boundaries is not protected by refusing a bounded exogenous edit. **A3: do NOT enqueue this flag.** The original finding is retained below as the audit record.
>
> **Additional finding surfaced while resolving, now closed by the same change:** the two documents did not merely disagree — they formed a **closed loop with no legal exit**. A purely numerical relaxation was forbidden in place by immutability *and* rejected as a restart by `EP:528` ("must differ… in more than just threshold numbers"; "Same implementation with the drawdown trigger at 60% instead of 50% fails the check"). §5.6a gives a threshold-number change exactly one home instead of being refused by both.

`AI_Trading_Foundation.md` §5.3–§5.6 (rev 4, **2026-04-25**) authorises mechanical relaxation of a live strategy's constraints, and `Claude_Task_Plan.md` A3 §C instructs A3 to *"replace constraint value with new (relaxed) value per §5.6 formula"* in `Strategy.md`.

`Experiment_Parameters.md` rev 16 and `Strategy.md` rev 37 (both **2026-07-10**, owner directive — ~2.5 months *later*) state the opposite for exactly these objects:

> *"**Immutable (per-strategy machinery, for that strategy's entire life…).** Each strategy's entry/exit rules, thresholds, indicators, 2%-of-strategy-portfolio position sizing, kill-criteria structure, cited foundation edges/disadvantages, and its pre-mortem. … Once locked, the only way to change a strategy's machinery is terminate-that-strategy-and-restart-as-new … — **never a quiet edit**."* (`EP:8`)
> *"Revising a parameter of a **live** strategy still forces THAT strategy's termination and a materially-different successor."* (`EP:8`)

**All five strategies are locked** (`spec_locked_since: 2026-04-23`, `immutable_since: 2026-04-23`). A §5.6 relaxation applied to any of A–E would be precisely the "quiet edit" this clause prohibits, and on its face would *force that strategy's termination* rather than adjust its value.

The carve-outs that exist are explicit and do **not** cover this: roster membership and capital-allocation rules were deliberately moved into versioned policy (`EP:159`), and the same passage names what stays frozen — *"What is not relaxed: the evaluation machinery … and **2%-per-trade risk sizing** — all stand unchanged."* (`EP:161`).

**Consequence:** the §5.6 lookup can compute a new value that no routine is authorised to write. **Latent this cycle** (zero relaxations), which is why it is cheap to resolve now.
**Recommendation (for the AR pair, default HOLD):** reconcile the two documents — either scope §5.3–§5.6 explicitly to newcomer strategies pre-SHADOW-lock, or add an explicit foundation-driven-relaxation carve-out to the immutability clause with a revision-history entry. **Do not resolve it by having A3 edit a locked strategy.**

---

**F-2 — ✅ RESOLVED 2026-07-28 (owner directive), same day as this audit · originally BLOCKING · §5.6's MATERIAL sizing branch bounded against a 5% cap that does not exist.**

> **SUPERSEDING UPDATE (owner directive, same day, later in session).** The fixed 2% rule itself has since been **retired outright** — `Experiment_Parameters.md` rev 18 / `Strategy.md` Rev 39 replace it with **thesis-scaled risk budgeting** (AI-chosen per-thesis Capital-at-Risk budget, justified against a seven-factor list, adversarially attacked on size, bounded by per-name ≤10% CaR and per-strategy-deployed ≤75% CaR envelopes). So there is now no per-position sizing *cap* at all, not merely no relaxation rule for one. The owner's controlling reasons: Rev 40's unbounded add-tranches had already destroyed the 2% rule's status as a per-name risk cap, and with no price-based stop-losses the size decision *is* the risk decision, which a blanket number cannot express across theses of different shape. **This audit's F-2 analysis is unchanged and was load-bearing in that decision** — the finding that the cap was never disadvantage-keyed, and that the 5% bound contradicted the derivation behind 2%, is precisely why the answer was to retire the rule rather than define the missing ceiling. The original F-2 resolution follows.
>
> **ORIGINAL RESOLUTION (owner directive 2026-07-28).** The **per-position sizing row is struck from §5.6 entirely** (foundation rev 6; mirrored to `Experiment_Parameters.md` rev 17). Per-position sizing caps now carry **"no automatic relaxation" at either magnitude** and are additionally excluded from the §5.6a in-life edit path. The 5% bound is **not** defined into existence — the audit's own evidence argues against it: `Experiment_Parameters.md`'s Position-size derivation cites 5% precisely as a level that *fails* the "standard variance should not produce drawdowns above 10%" constraint (a 10-trade streak at 5% costs 40%), the struck 2%→4% MATERIAL branch implies ~33% streak drawdown against a 10% tolerance and lands essentially on the book-level `breach_hard` −40% halt, and the cap is not disadvantage-keyed in the first place (its derivation cites institutional consensus and streak arithmetic, no `1.X`/`2.X` — finding F-4, constraint X-01), so no reduction can license loosening it. This follows §5.6's own hit-rate default ("no automatic relaxation unless the threshold's derivation explicitly cites a Tier 2 disadvantage magnitude") to its conclusion. 2% sizing remains globally immutable. **A3: do NOT enqueue this flag.** Original finding retained below as the audit record.

> *"MATERIAL reduction → cap loosened to (current × 2) but bounded by **experiment-level cap of 5% per position**."* (`AI_Trading_Foundation.md:564`)

Repo-wide, the phrase occurs **exactly twice** — `AI_Trading_Foundation.md:564` and its verbatim restatement at `Experiment_Parameters.md:314`. **Both occurrences are inside §5.6's own relaxation-forms sentence.** No experiment-level 5% per-position cap is defined anywhere: no section, no derivation, no citation. The only other "5%" in `Experiment_Parameters.md` is inside the 2% rule's own derivation, illustrating that a 5% risk fraction would cost 40% on a 10-trade losing streak — i.e. the figure appears in the source material as an example of a level explicitly **rejected**.

**Consequence:** the MATERIAL branch for per-position sizing caps is not executable as written — it references a bound that has no definition, and the nearest textual evidence argues *against* 5% rather than establishing it. **Recommendation (default HOLD):** either define the ceiling as a real experiment parameter with a derivation, or strike the clause. Note this compounds F-1: 2% sizing is *globally* immutable, so this branch may be unreachable in principle regardless.

---

**F-3 — §5.5 guardrail 3 ("sustained") is structurally unclearable at the project's current age.**

Guardrail 3 requires improvement sustained across **≥2 consecutive quarterly delta cycles**, OR documented in **last-2-years annual-sweep coverage**.

Verified against full git history (repo unshallowed to genesis, 897 commits): **`Quarterly_AI_Foundation_Delta.md` has exactly one content-creating commit ever** — 2026-07-01, covering 2026-Q2. The document says so itself: *"No prior `Quarterly_AI_Foundation_Delta.md` exists; the foundation framework was formalized 2026-04-25 (rev 3/4), so this is the first full Q3 delta."* And **A1 2026 is the first annual sweep.**

**Consequence:** with a single data point in the quarterly sequence and a single annual sweep, no benchmark-inferred reduction can clear guardrail 3 on the quarterly route, and the annual route has no prior sweep to corroborate against. This is a property of the project's ~3-month age, not of any item's evidence — but it means **benchmark-inferred relaxation is effectively inoperable until at least 2027-Q1**, and any future cycle should know that before attributing a NONE verdict to weak evidence. Direct research findings remain unaffected (§5.5 exempts them explicitly). **No action required; recorded so a future A2 does not re-derive it.**

---

**F-4 — §5.3 step 2's mechanical citation parse has no input for 74% of the corpus.**

Detailed in §1.0: 147 of 201 constraints yield `PRIMARY CITATION UNRESOLVED`. The parse is specified to read rev-N annotations naming a foundation item and to trace `cycle M T1.X` attacker outputs; the annotations overwhelmingly name **internal defect labels** and the referenced attacker transcripts are **not retained in the repository**. Where citations were recovered, the source was pre-mortem Section 5 / binding-constraint prose, not the specified rev-N route.

Two adjacent accuracy defects belong here: **`roster.yaml` lists A as compensating 2.15 and 2.17**, which appear nowhere in A's documents (§1.7); and **D's 2.23 citation outlived its mechanism** — Rev 39 removed the LTCG-preference exit that the cross-walk names as 2.23's compensation route, while the thesis text and roster row still assert the compensation (§1.4).

**Consequence:** benign this cycle (all citations resolve to NONE either way), decisive later — the parse is the *only* mechanical route from a reduced disadvantage to the constraints that should relax. If a reduction ever registers, 74% of constraints cannot be connected to it. **Recommendation (default HOLD):** record each constraint's foundation citation inline as a first-class annotation at its next legitimate revision, and reconcile the two roster rows above. **Not** a licence to back-fill citations by inference — an invented citation is worse than an absent one.

---

**F-5 — §5.6's cadence-rule branch promises criteria that were never authored.**

§5.6 routes cadence rules to *"explicit review at the annual constraint audit (A2) **with mechanical criteria specific to the cadence rule's purpose**."* Those criteria do not exist in any document. A2 performed the review it could (§2.4) — confirming citation status and holding all 25 rules — but "mechanical criteria specific to the cadence rule's purpose" is an unfilled forward reference, so the branch currently reduces to "hold and confirm." **Recommendation (default HOLD):** either author the criteria or amend §5.6 to state that cadence rules hold pending an explicit owner-directed change.

---

**F-6 — The five §5.6 constraint types under-cover the corpus: 39 of 201 constraints (19%) are out-of-table by construction.**

Exit triggers, regime-router activation gates, execution-integrity mechanics (E's no-naked-leg rule), verification requirements (C's dual-path check), and computation-method-selection rules fit none of the five categories. This is not an artifact of classification generosity — the categories are sizing/universe/concentration/cadence/threshold, and an exit trigger is none of them.

**Consequence:** a fifth of the corpus can never receive a mechanical relaxation form; every such constraint would route to `out-of-table-resolution` if it ever passed Steps 1–3, which would flood a review path §5.6 describes as *"the explicit exception path the framework's 'no discretion' principle requires"* — i.e. designed for rare cases. **Recommendation (default HOLD):** consider whether exit triggers and regime gates warrant their own §5.6 rows (both would most likely be "no automatic relaxation," which would resolve the volume problem cleanly and honestly).

---

## 2.6 A3 handoff summary

| A3 section | Input from A2 | Action |
|---|---|---|
| §C — updated `Strategy.md` | 0 constraints relaxed; 0 constraint values changed | **No constraint edit.** No per-strategy revision bump required by A2 |
| §D — out-of-table enqueue | 0 per-constraint flags; 6 framework-level flags raised, **F-1 and F-2 RESOLVED 2026-07-28 by owner directive** | Enqueue **only F-3, F-4, F-5, F-6** as `out-of-table-resolution` (`conservative_default='HOLD'`), artifact_path = this §2.5. **Do not enqueue F-1 or F-2** |
| §D — consume prior verdicts | None — this is A2's first execution; no prior `out-of-table-resolution` verdicts exist | Nothing to apply |
| §E — decision log | A 0 · B 0 · C 0 · D 0 · E 0 relaxed; 0 per-constraint flags; 6 framework flags; 201 constraints audited | Record counts as stated |
| §F — reconciliation | `roster.yaml` A row lists 2.15/2.17 (absent from A's documents); D row's 2.23 mechanism removed by Rev 39 | Minimal edits if A3 judges them in scope; **not** constraint-value changes |

**Cross-routine note for A3:** A1's Strategy C outcome (**re-open pre-mortem** on 2.11's ~88% worsening) is a §5.2 *tightening* and flows through **A3 §B**, not §C. A2 produced no relaxation for C or any strategy. The two must not be merged in the `Strategy.md` edit.

---

*Audit executed against `AI_Trading_Foundation.md` rev 5 §5.3–§5.7 with no orchestrator discretion. 201 per-strategy constraints inventoried across 5 roster-active strategies (A 33 · B 35 · C 51 · D 48 · E 34) plus 10 experiment-level constraints; 26 Part-2 disadvantages classified; 0 relaxations; 0 per-constraint out-of-table flags; 6 framework-level flags.*
