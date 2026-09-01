2026-09

# Monthly D Position Deep-Dive — September 2026 cycle (review window 2026-08-03 → 2026-09-01)

**IMMEDIATE-ACTION flag: NONE.** No D position shows material thesis invalidation. Across **8 names and 12 tranches** there are **34 at-entry criteria** (AMZN 5, GOOGL 5, DIS 5, RTX 6, UBER 4, ISRG 4, TSM 3, GEV 2): **zero are breached.**

**All eight recommendations are HOLD.** There are no exits, no completions, and — for the first time since the routine began routing them — **no "further research" deferrals**, because the single one outstanding (GEV, prior-cycle F-8) was **resolved on evidence by D2 on 2026-08-09** and its queue item closed. Details in F-8 below.

The substantive output of this cycle is **not** in the per-position work, which is quiet and clean. It is **F-12**: Strategy D's last surviving mechanical deployment bound — the 30%-of-NAV GICS sector cap — stopped meaning what it was written to mean on 2026-08-06, and two sectors now read as over it on an essentially unchanged book.

---

## Span covered, and what "since the last cycle" means here

`state.routine_catchup_window` gives M3 `window_start_ts = 2026-08-03`, `window_days = 28.97` against a `monthly_ftd` fallback of 31 — **cadence-normal. No monthly cycle was missed, no multi-period catch-up sub-sections are owed, and no `CATCHUP[...]` token is due** (28.97 is below the 1.5× threshold, and in fact below the fallback itself).

The incremental research window is therefore **2026-08-03 → 2026-09-01**, a genuine 29-day month. Unlike the prior cycle — which covered two days and had to say so — this one contains real events: a Disney FQ3 FY26 print and 10-Q, an Uber Q2 2026 print, a completed D exit, a management change at GE Vernova, a $22.9B RTX award, and the capital event that produced F-12.

**Same-day double-run guard: clear.** `SELECT COUNT(*) FROM ops.run_log WHERE routine='M3' AND run_date='2026-09-01' AND status='completed'` returned 0 before any work began. M3's last completion was 2026-08-03.

**Scope is roster-derived.** This routine covers every roster-active strategy with `review_cadence: long_horizon` in `strategy/roster.yaml`. Enumerated this run: A, B, C, E are `reactive`; **D alone is `long_horizon`** (`roster_state: adopted`, `per_strategy_routine: null`). Scope is exactly D, unchanged. A future SISA `long_horizon` graduate would appear here automatically as its own `## Strategy <code>` section.

---

## Book state

**The book shrank from 9 names to 8, and holds at 12 tranches.** CRM was exited; DIS gained an add tranche.

- **`D:CRM:2026-07-09` CLOSED 2026-08-27** — exit staged by D2 on 2026-08-26 on **invalidation criterion 3** (non-GAAP operating margin contracts YoY), affirmatively MET on the verified FQ2 FY2027 print: 34.1% vs 34.3%, −20bp, SEC 8-K Ex-99.1 accession 0001108524-26-000187. Filled 0.2275 sh @ $234.77, commission $0.351448, **realized +$16.577627** (+45.4% on a $36.48 cost basis). This is D's **first and only closed trade**.
- **`D:DIS:2026-08-05` OPENED**, filled 2026-08-06 @ $102.9931, 0.4422 sh, cost basis $45.89389582 — an add tranche on the strengthened-conviction trigger, criteria inherited verbatim from the 2026-05-07 parent.

| Name | Tranches | Shares | Cost basis | Mark (09-01) | Market value | Unrealized | % of NAV | Recommendation |
|---|---|---|---|---|---|---|---|---|
| **GEV** | 1 (08-03) | 0.1244 | $120.656 | $878.53 | $109.289 | **−$11.367 (−9.42%)** | 20.06% | HOLD |
| **AMZN** | 2 (07-09, 07-30) | 0.3464 | $88.237 | $254.36 | $88.110 | −$0.126 (−0.14%) | 16.17% | HOLD |
| **GOOGL** | 2 (07-09, 07-26) | 0.2577 | $87.823 | $336.63 | $86.750 | −$1.074 (−1.22%) | 15.92% | HOLD |
| **DIS** | 2 (05-07, 08-05) | 0.7244 | $77.308 | $108.855 | $78.855 | +$1.546 (+2.00%) | 14.47% | HOLD |
| **TSM** | 2 (07-21, 07-29) | 0.1550 | $64.013 | $414.40 | $64.232 | +$0.219 (+0.34%) | 11.79% | HOLD |
| **ISRG** | 1 (07-20) | 0.1091 | $38.132 | $371.90 | $40.574 | +$2.443 (+6.41%) | 7.45% | HOLD |
| **UBER** | 1 (07-09) | 0.5156 | $37.746 | $76.025 | $39.198 | +$1.453 (+3.85%) | 7.19% | HOLD |
| **RTX** | 1 (04-27) | 0.1601 | $28.321 | $208.095 | $33.316 | **+$4.995 (+17.64%)** | 6.11% | HOLD |
| **Total** | **12** | — | **$542.237** | — | **$540.324** | **−$1.912 (−0.35%)** | **99.16%** | — |

*Marks are the **2026-09-01 IBKR connector snapshot** (`get_account_positions`), read from the authenticated account — the authoritative source per Operating_Protocols.md §11. Cost basis is the **ledger** figure from `state.current_positions` (shares × fill price + commission), which is authoritative per §15.*

*A reconciliation note, stated rather than smoothed: on several names the connector's own `unrealized_pnl` field differs from `market_value − ledger cost_basis` by a few cents, because the connector's `average_price` is not the ledger's commission-inclusive basis. The largest divergence is **ISRG**, where the connector reports `average_price` $352.464 against a ledger-implied $349.511 — a residue of the separate `B:ISRG:2026-07-21` tranche that shared the contract until it closed on 2026-08-12. **Every figure in the table above uses the ledger basis and the connector mark**; the connector's derived P&L field is not used anywhere.*

*The book is now **entirely** Strategy D: `state.current_positions` holds 12 rows and all 12 are D. `analytics.account_reconciliation` puts `deployed_total` at $544.87 against an account NAV of $15,955.34 — D's book is the whole of the account's deployed capital, with the remainder parked in VOO (21.888 sh, $15,365.60) under Strategy E. B's ISRG and MSCI positions both closed in August; A and C hold nothing.*

**D engine state (informational; not exit-triggering).** `perf.strategy_daily` 2026-08-31: `deployed_unit_value` **1.061062**, `peak_unit_value` 1.098110, `current_drawdown` **−3.37%**, `excess_vs_sgov` **+4.80%**, `deployed_days` 88, **`closed_trades` 1**, `gate_n` **29**. All `perf.kill_flags` FALSE (`drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `gate_reached`, `interim_underperf_warning`). `beta_hat` 0.9155 and `alpha_annualized` 0.2604 are computed but **`beta_min_n_met = FALSE`, so the alpha estimate is not usable** and no edge-decay read may be drawn from it. Note that `closed_trades` moved 0 → 1 and `gate_n` 30 → 29 on the CRM exit: the 30-trade gate has taken its first step in D's life, and at D's declared 3–8 trades/year would still need roughly a decade — the documented, accepted property, not a flaw.

**Regime and router state (informational; does NOT alter disposition).**

- **Fundamental axis, scored today by M1a (`as_of 2026-09-01`): "decelerating growth + disinflation + hawkish tightening bias + risk-on + acute shock."** Two axes moved from August: inflation stepped stable → **disinflating** (core CPI 2.47% index-derived, at the floor of its three-quarter band, though core PCE is flat at 3.34% and core PPI MoM re-accelerated — M1a itself calls this a boundary call), and risk sentiment flipped neutral → **risk-on** (VIX 14.92, HY OAS 2.60, breadth 66.2%). Growth deteriorated materially in evidence though not in label: July payrolls **−23k**, the first negative month of the cycle, with May/June revised −103k combined. Policy stays **hawkish** with a live September *hike* priced at ~66%. Shock stays **acute**.
- **Technical signals (D2a 2026-08-31, mechanical):** SPY_TREND **UP** (767.05 > 50d 754.36 > 200d 710.27); SUSTAINED_INVERSION **NOT-SUSTAINED** (10Y 4.75 vs 2Y 4.34, +0.41); VIX_REGIME **LOW** (14.92).
- **D router technical rule** — (SPY Trend UP or NEUTRAL) and inversion NOT-SUSTAINED — therefore reads **ACTIVATE**. **The binding state is DO-NOT-ACTIVATE**, set 2026-08-05 by `div-D-202607-1` (a STATE CHANGE from ACTIVATE). M1b's September call is DNA again and, as M1b notes, **raw for the second consecutive month** — the override-manufactured ground that the divergence review found had collapsed remains collapsed. M1b has queued a fresh divergence review; the new fact is confirmatory, not re-opening.
- **This changes no disposition below.** Per Strategy D's explicit rule, *"router deactivation does not force exits on existing D positions"* — existing positions run to thesis invalidation or completion. **Every recommendation in this file is criterion-driven, not regime-driven.** What the deactivation *did* do is move capital, which is F-12.

---

## Cross-cutting findings

Numbering continues the prior cycle's series so a finding can be traced across cycles: F-1, F-9 carry forward with updates; F-3, F-4, F-6, F-8, F-10, F-11 close; F-5 and F-7 update; F-12 through F-15 are new.

### F-12 (NEW, and the finding of this cycle). D's NAV fell 78% on an unchanged book, and the 30%-of-NAV sector cap — its only surviving deployment bound — now reads as breached in two sectors

**The measurement.** `analytics.strategy_nav` for D reads `nav = $544.88` today. The prior cycle recorded **$2,471.35** from the same view. The book barely moved in between (one add of $45.89, one exit of $36.48 cost).

**The cause is real, deliberate, and fully attributable — it is not a view defect.** The view's SQL is unchanged: `git log --since=2026-08-03 -- bigquery/` shows no commit touching `bigquery/22_cash_flows.sql` or `bigquery/127_strategy_nav_dust_exclusion.sql` (the live definer, applied 2026-08-02, i.e. *before* the prior cycle read $2,471.35). What changed is the `events.cash_flows` ledger underneath it, and the arithmetic reconciles to the cent:

| component | amount |
|---|---|
| D's 1/5 share of the three strategy-`NULL` deposits ($6,946.86 + $2,500.00 + $9,995.39) | +$3,888.45 |
| 2026-07-19 `regime_capital_sweep` in | +$566.81 |
| 2026-08-05 `regime_capital_sweep` in | +$499.77 |
| **2026-08-06 `regime_capital_sweep` OUT** | **−$4,376.85** |
| 2026-08-27 `regime_capital_sweep` out (CRM exit proceeds) | −$53.17 |
| **= `deposits`** | **$525.01** ✓ |

Plus realized $16.58 + unrealized $2.64 + dividends $0.65 = **`nav` $544.88**, and `available_funds` **$0.00**.

The 2026-08-06 sweep is the event. **D was ruled DO-NOT-ACTIVATE on 2026-08-05** (`events.regime_events` `cd0ebaf1-9b01-458d-944c-85199bcbb772`, resolving `div-D-202607-1`), which makes it `capital_disabled` in `state.strategy_capital_enablement`, and Operating_Protocols.md §16 then requires its idle cash to redistribute to capital-enabled strategies. $4,376.85 left D for C and E the next day (`events.decision_log` `6d51b893-b669-4a7a-adac-84e9d4f9e662`); a further $53.17 followed the CRM exit on 2026-08-27 (`a680633f-b59b-4a1b-95e0-aa655b08608d`). Both are pure accounting reallocations of *idle* cash — no security was bought or sold for either, and D's open positions were untouched. **Both the old and the new NAV figures were correct on their own dates.**

**Why it matters.** A capital-disabled strategy is swept to zero idle cash by construction, so **its NAV converges to its own deployed book.** D is now 99.16% deployed with $0 available funds — not because it took risk, but because the denominator was removed. Every ratio expressed as "% of D's NAV" therefore inflated by ~4.5× overnight on a book that did not change.

**The consequence for the one bound D still has.** Per the 2026-08-05 owner directive recorded in `strategy/06_strategy_d.md`, **both Capital-at-Risk envelopes are RETIRED** — the per-name ≤10% and the per-strategy deployed ≤75% are gone, at every level, and the file says so at three separate passages. *(The prior cycle's "Envelope compliance (Rev 43 sizing)" section applied both; it ran on 2026-08-03, two days before the directive, so it was right then and is stale now. It must not be re-applied.)* The **30%-of-NAV GICS sector cap is the only surviving mechanical deployment bound**, and on today's denominator:

| GICS sector | Names | Cost basis | % of NAV | Market value | % of NAV | % on the *prior* denominator |
|---|---|---|---|---|---|---|
| **Industrials** | GEV, UBER, RTX | $186.723 | **34.27%** | $181.804 | **33.37%** | 7.56% |
| **Communication Services** | GOOGL, DIS | $165.131 | **30.31%** | $165.604 | **30.39%** | 6.68% |
| Consumer Discretionary | AMZN | $88.237 | 16.19% | $88.110 | 16.17% | 3.57% |
| Information Technology | TSM | $64.013 | 11.75% | $64.232 | 11.79% | 2.59% |
| Health Care | ISRG | $38.132 | 7.00% | $40.574 | 7.45% | 1.54% |

Two sectors read over 30% — **on cost basis and on market value, and against either candidate denominator** (measuring "within D's book" instead of "of NAV" gives Industrials 33.65% / Communication Services 30.65%, because at 99% deployed the two denominators nearly coincide). Under the prior denominator neither was close.

**The adjudication, stated plainly, because the number alone invites the wrong action:**

1. **No exit is triggered, and none is available.** The 30% cap is **Entry criterion 5** — it governs whether a position *may be opened*, and the sentence is written as "position does not **produce** > 30% concentration." Strategy D's exit rules are exhaustive (thesis completion; thesis invalidation; no maximum hold) and its "Not exit-triggering" list explicitly covers macro shifts that do not invalidate the specific structural drivers. The directly analogous post-entry control in the same criterion — correlation-bucket monitoring — says in terms that it "does not force exits on already-held positions." A concentration reading is not an invalidation criterion, and no D position's immutable at-entry criteria mention sector concentration at all.
2. **It blocks nothing today either.** D is simultaneously DO-NOT-ACTIVATE (no new entries) and capital-disabled (no capital to enter with). There is no entry for criterion 5 to gate.
3. **And it very likely self-reverses before it ever binds.** The sweep is debt-tracked in `state.regime_capital_debt` and reverses mechanically through the `trigger=regime_enable` RESTORE path. The moment D re-activates — the same moment new entries become possible and criterion 5 starts mattering again — the capital comes back and the percentages fall back under 30%.

**So the finding is not "D is in violation." It is that D's only surviving mechanical bound is, right now, measuring something other than what it was written to measure**, and any routine that computes sector concentration against `analytics.strategy_nav.nav` while D is capital-disabled will read a breach that is an artifact of the disabled state. That is worth writing down precisely because the honest number looks alarming and the correct action is nothing.

**Routing.** This is a spec-interaction question between Operating_Protocols.md §16 (regime-capital sweep) and Strategy.md's Strategy D Entry criterion 5 — a strategy-surface reading, not something M3 may settle and not something a single routine should decide unilaterally. **Owner: W5's SPEC-DEFECT NOTICE INTAKE**, which is the same venue M1b used today for the regime-axis vocabulary drift. Recorded as an `ops.alerts` info row, category `sector_cap_denominator_artifact`, source M3. **M4 should carry it as context, not as an action** — there is no exit, no trim and no queue item owed, and manufacturing one would be the error this finding exists to prevent.

### F-8 (prior cycle's headline). RESOLVED ON EVIDENCE — and the premise it rested on was false

The prior cycle's single FURTHER RESEARCH recommendation is **closed**, and it closed well. `events.queue_events` shows `research-deferral-GEV-D-20260809` moving `pending` → **`complete`** on **2026-08-09**, drained by D2 **on its due date**, with `conservative_default_applied = false`.

What D2 found, from its own resolution note and `events.decision_log` `9f6e4fa3-7966-4a99-9ff5-d554040c55b3`:

> "The EXIT conservative default was NOT fired: it applies when the required data is still unavailable, and it was available. The deferral premise (FMP plan-gating makes the 8-quarter transcript floor unmeetable, an owner-actionable subscription problem) is **FALSE** — it was a **source-selection problem**. All 8 required quarters (Q3 2024 – Q2 2026) plus both annual reports were downloaded, extracted and READ from the issuer's own IR site this session, so criterion 2 is now satisfied CONSTRUCTED-FROM, not merely available, and the PROVISIONAL flag `6efeeb13` attached to the GEV GO is cleared."

Both sub-questions resolved: the **infrastructure** one CLOSED ("issuer IR publishes all transcripts free; never a subscription problem, no FMP upgrade required"), the **interpretive** one MOOT for GEV ("a documented substitute is only needed when the real thing is unavailable; the real thing was obtained and used"). Entry claims were verified verbatim against the primary transcripts (Q1-26 +71%, Q2-26 +88%; backlog series 118/119/123/129/135/150/163/176 $B). The same session also **REFUTED F-10** — management stated $200B in 2027 on the Q1 2026 call, explicitly revising from 2028, reaffirmed at Q2 2026 — so the prior cycle's "no primary written source" finding is withdrawn on primary evidence.

**The interpretive question is moot for GEV but not settled in general.** D2's reasoning cures the specific case by obtaining the real evidence; it does not rule on what happens the next time a transcript genuinely cannot be had. The same session also filed a correction that **BA's 2026-08-03 NO-GO rests on the same refuted premise** — all 8 required Boeing transcripts are likewise free on Boeing's IR CDN — so a NO-GO was recorded on a tooling limitation that did not exist. That is a live item, but it belongs to whoever re-screens BA, not to this routine.

**A carry-forward the resolution generated, and it is a real one (F-13 below):** D2's note records a **CALIBRATION FINDING** it explicitly did not act on — GEV's trend metric read **+8% and +4% in Q1/Q2 2025**, i.e. **two consecutive quarters below the 15% line, ~13 months before entry**. The criterion would have fired then. Both quarters are attributable to lapping single >$1B orders. Criteria are immutable for the position's life and none was rewritten — correctly.

### F-13 (NEW). Both of D's realized data points say the same thing: these criteria fire on lumpy inputs, and the one that has fired, fired on a winner

D now has exactly two empirical observations about how its invalidation machinery behaves in contact with real data, and they point the same way.

1. **CRM, the only closed trade.** Criterion 3 (non-GAAP operating margin contracts YoY) fired on a **−20bp move** — 34.1% vs 34.3% — and the position was flattened for a realized **+45.4%**. The criterion was applied literally and correctly; `Claude_Task_Plan.md` already records the drafting lesson (a criterion with no sensitivity band fires on noise) and, critically, records that the fix belongs at **authoring** time and must **never** be applied as a softening at the exit step. That prospective-only rule is honoured throughout this file: every criterion below is applied literally as written.
2. **GEV, from F-8's primary reconstruction.** The trend metric would have tripped the same criterion in Q1/Q2 2025 on order-timing lumpiness, 13 months before the thesis existed.

**What this is and is not.** It is **not** grounds to re-read any criterion more leniently — that is the exact inverse error `Claude_Task_Plan.md` warns is strictly worse, since suppressing a real invalidation keeps a broken thesis alive on a strategy with no stop-loss and no size ceiling. It **is** a calibration input for *future* thesis construction in D: two of two available observations show a bare threshold on a lumpy quarterly series firing on something other than structural deterioration. Recorded for D2's thesis-construction step and for the Strategy D pre-mortem, which reached SUFFICIENT at cycle 9 on 2026-08-16 after eight consecutive TIER 1 DEFECT verdicts. Not actionable against any open position.

### F-14 (NEW). Two criteria are on a path to becoming untestable in their own terms, and neither is a defect yet

Distinct from F-13, which is about criteria that fire wrongly. This is about criteria that may stop being able to fire at all. Both are surfaced from primary text read this cycle, both are **NOT TRIGGERED**, and both have a metric-immutability clause that would eventually catch them — the point is the dates.

- **UBER criterion 2** (adj-EBITDA margin as % of Gross Bookings contracts YoY 2 consecutive quarters). Uber's own Q2 2026 release states Adjusted EBITDA **"is no longer a key measure used by management; we include a disclosure on Adjusted EBITDA to assist during the transition to our new non-GAAP measures."** That language first appeared in Q1 2026 and is now confirmed into a **second consecutive quarter**. If Uber stops publishing it comparably, criterion 2 becomes unmeasurable. **UBER's metric-immutability clause (criterion 4) covers Gross Bookings disclosure only** — GB's definition paragraph was read in full this cycle and is verbatim-unchanged — **so it would not catch an Adjusted-EBITDA phase-out.** That is a genuine gap in the criteria set as written, and it is not repairable (criteria are immutable for the position's life). Watch at the Q3 2026 print, ~early Nov 2026.
- **DIS criterion 4** (metric-immutability on Entertainment SVOD operating income/margin). The FQ3 FY26 10-Q (accession 0001744489-26-000057) confirms in its own text that the Consumer-Products-into-Entertainment reclassification takes effect **"commencing with our fiscal 2027 reporting."** This is the criterion's live risk and it is on a known clock: first test at the ~Feb 2027 Q1 FY27 report, earliest possible auto-invalidation ~May 2027. A useful precision added this cycle by direct read of both documents: SVOD operating income has **never** lived in the 10-Q's segment footnote — the "current form" is, and has been, the **8-K Ex-99.1 supplemental table**. A future cycle checking the 10-Q alone would wrongly read a non-conforming quarter.

### F-15 (NEW). The FMP plan-gating adjudication has not propagated into practice

Six of the eight per-position research passes this cycle hit `ACCESS DENIED` on FMP's `secFilings`, `news`, `earningsTranscript` and/or `statements` endpoints — the same wall that produced the prior cycle's F-8. **This is no longer an open infrastructure question**: D2 settled it on 2026-08-09 (see F-8) — issuers publish transcripts and filings free on their own IR sites and on SEC EDGAR, so it is a *source-selection* problem, not a subscription problem. Operating_Protocols.md was corrected on 2026-08-30 in the same direction, withdrawing the claim that `sec.gov` 403s from this environment and requiring a direct EDGAR `WebFetch` attempt before flagging anything unverified.

**The adjudication is correct and it worked** — every pass that fell back to EDGAR/issuer IR got primary sources, and this cycle's per-position sections are built almost entirely on filing accession numbers. **What did not happen is anyone going there first.** Every pass spent a metered call discovering the wall before routing around it. That is a small, repeated, entirely avoidable cost, and it is the kind of thing that decays into "FMP is broken, so this is unverifiable" once the reasoning behind the fallback is a cycle or two old. Recorded as an `ops.alerts` info row, category `fmp_tier_fallback_not_default`, source M3, naming **W5 SPEC-DEFECT NOTICE INTAKE** as the consolidation venue — the routine-prose change (M3's own `ops.web_calls` obligation paragraph still describes FMP `news`/`secFilings` as the routine research path) has fleet-wide blast radius and is not M3's to make unilaterally mid-run.

### F-9 (carried, updated). The AI-capex cluster is still the book's real concentration, and it is still invisible to every control

AMZN + GOOGL + TSM (compute) plus GEV (power) now hold **$348.38 of $540.32 market value = 64.5% of the deployed book** — down from the prior cycle's 67.7% only because CRM's exit shrank the denominator's complement, not because the cluster shrank.

The four sit in **four different GICS sectors** (Consumer Discretionary, Communication Services, Information Technology, Industrials), so the 30% sector cap cannot see them — and F-12 shows that cap is currently mismeasuring anyway. The correlation recompute (F-7) does not see them either: the strongest cross-cluster pair, GEV–TSM, is at 0.599, still below the 0.6 bucket threshold, and rev 35 made bucket membership informational regardless.

**No invalidation criterion in any of the four theses names AI capex intensity, free cash flow, ROIC or cross-position correlation.** The nearest is TSM's criterion 3 ("structural AI-capex reset"), which is a single-name structural test, not a portfolio-concentration one; the AMZN pass noted the same gap independently, observing that the market's dominant narrative for the whole cohort this month — capex-versus-monetisation scrutiny — is uncovered by any criterion in any of the four. This is why the book's aggregate is **−0.35%** while every individual thesis is intact: the four names moved together, and nothing in the framework was designed to notice.

Unchanged in posture from the prior cycle: **recorded for future thesis construction, not actionable against open positions.** Criteria are immutable; the concentration cannot be retrofitted with a criterion, and no exit follows from it. The pair to watch remains GEV–TSM.

### F-7 (updated). Correlation recompute — 8×8, and the specified window was fully met

The monthly post-entry recompute that Entry criterion 5 (rev 28) requires. Source: IBKR `get_price_history` (`ONE_YEAR`/`ONE_DAY`, RTH), contract IDs resolved individually. **All 8 names returned a full, clean, identically-aligned series**; the in-progress 2026-09-01 session was dropped, leaving a common window **2025-09-02 → 2026-08-31, 251 closes / 250 daily returns per ticker, n = 250 on all 28 pairs.** The prior cycle's anticipated short-series problem for GEV did not materialise — GEV now carries well over 252 sessions since its April 2024 spin-off. No padding, no interpolation, no BigQuery fallback.

Pearson correlation of daily simple returns:

```
         AMZN     DIS     GEV   GOOGL    ISRG     RTX     TSM    UBER
  AMZN  1.000   0.203   0.188   0.504   0.249   0.053   0.262   0.281
   DIS  0.203   1.000  -0.068   0.176   0.297   0.112   0.069   0.275
   GEV  0.188  -0.068   1.000   0.187   0.080   0.168   0.599  -0.008
 GOOGL  0.504   0.176   0.187   1.000   0.215   0.080   0.317   0.268
  ISRG  0.249   0.297   0.080   0.215   1.000   0.189   0.119   0.214
   RTX  0.053   0.112   0.168   0.080   0.189   1.000   0.041   0.067
   TSM  0.262   0.069   0.599   0.317   0.119   0.041   1.000   0.195
  UBER  0.281   0.275  -0.008   0.268   0.214   0.067   0.195   1.000
```

- **Pairs above the 0.6 entry-time bucket threshold: none.** Highest is **GEV–TSM at 0.599**, up from 0.587 last cycle — a second consecutive month sitting just under the line, now 0.001 below it.
- **Pairs above the 0.7 post-entry emergent threshold (rev 28): none.**
- **No bucket forms at either threshold**; all 8 positions are singletons. Per rev 35 this is informational only — neither capped nor entry-blocking — so no consequence follows even at a crossing.
- Second-highest is **AMZN–GOOGL at 0.504**, the mega-cap hyperscaler pair. Both top pairs are **cross-sector thematic** overlaps, which is precisely F-9's point.

**Caveats, stated:** at n = 250 the 95% CI half-width on a Fisher-z-transformed r is roughly ±0.06–0.07, so 0.599 and 0.6 are not statistically distinguishable — a future cycle should not read "0.599 < 0.6" as a finding, only as an unchanged non-event. Several names carry one or two outsized earnings-gap days inside the window (AMZN +15.3% on 2026-07-31, GEV +15.6% on 2025-12-10, ISRG −14.1% on 2026-07-17), which no single observation dominates at n=250 but which do shape the estimates. And Pearson correlation on daily returns says nothing about tail co-movement in a stress regime, which is the scenario rev 28's monitoring language was actually worried about.

### F-5 (updated). Source-reliability items this cycle — including two of this run's own

Reported in the same spirit as the prior cycle: the failures of the research process itself are part of the output.

1. **A repo-only reading of the GEV carry-forward produced a confidently wrong conclusion.** The GEV research pass, working from repo files, found no reference to `research-deferral-GEV-D-20260809` after 2026-08-03 in `Watchlist.md`, `Daily.md`, `Quarterly_D_Candidates.md` or `Claude_Task_Plan.md`, and concluded the checkpoint was **"overdue by 23 days"** with a live exit default. It was not — `events.queue_events` shows it `complete` on its due date. The lesson generalises and is worth pinning: **queue state lives in BigQuery, and the repo `.md` files are not a mirror of it.** Per Operating_Protocols.md §15 the `Pending_*` queues were retired to `events.queue_events` / `state.open_queue`; a session that reconstructs queue status from markdown will systematically read resolved items as open. Every carry-forward in this file was re-verified against BigQuery for exactly this reason.
2. **A cost-basis-versus-price-per-share confusion produced a 26× overstatement.** The UBER pass reported the position at "+101% since entry" by comparing the tranche's total cost basis ($37.75, a dollar amount) against the share price ($76.03). The true figure is **+3.85%** ($39.198 MV vs $37.746 cost on 0.5156 sh). Corrected in the table above. The failure mode is specific to this book's fractional-share sizing, where a total cost basis and a per-share price can be the same order of magnitude, and it will recur.
3. **Analyst-action dates from aggregators could not be pinned to the window.** The GEV pass found a Citi price-target cut dated only "late July/early August" and could not place it inside or outside the window; a Morgan Stanley action re-surfaced as in-window when it is dated 2026-07-23, pre-window. Analyst actions are informational for D in any case (no criterion references them) and none is relied on anywhere in this file.
4. **Carried forward, unchanged:** the IBKR `get_price_history` contract-level series-swap defect recorded last cycle. It did **not** recur this cycle — the correlation recompute resolved each contract ID individually and fetched each series separately, which is the documented interim mitigation, and all 8 series returned self-consistent, date-aligned bars. Owner remains W5/D3.

### F-1 (carried). The completion-criteria gap for legacy positions is unchanged, and its named venue closed without addressing it

Of the 8 open names, **exactly one — GEV — carries a testable thesis-COMPLETION criterion** (backlog ≥ $200B AND trailing-4Q organic orders growth decelerated to ≤25% YoY for at least one quarter). The other seven carry invalidation criteria only, so they can be exited on failure but have no mechanism to be exited on success. Criteria are immutable for a position's life, so the seven cannot be retrofitted.

**Update:** the prior cycle named the `revise-premortem-D-2026-a3` queue item and the AR_orc pre-mortem cycle as "the natural venue for the residual." That process **completed on 2026-08-16 at cycle 9 with a verdict of SUFFICIENT** (after TIER 1 DEFECT verdicts at cycles 5, 6, 7 and 8, and revisions to rev 9). The venue is therefore closed and the gap is not addressed by it. RTX remains the live illustration: all five of its named falsifiable milestones were satisfied three quarters early, and there is still no mechanism by which that constitutes completion.

Recorded, not actionable. No exit follows from the absence of a completion marker.

### Prior findings now closed

| Prior | Status | Basis |
|---|---|---|
| **F-3** — four dated events to watch | **CLOSED**, all four resolved | ISRG/J&J Ottava call (08-03) — no named IDN, see ISRG below; DIS FQ3 FY26 (08-05) — printed, criteria 2 and 3 affirmatively re-passed; UBER Q2 2026 (08-05) — printed, criteria 1 and 2 cleared on new data; FCC reply-comment deadline (08-05) — passed with no order, and the proceeding has since inverted (see DIS below) |
| **F-4** — ledger defects | **CLOSED for the items named.** GEV's provisional staging basis was superseded by D2a Step 0 on fill; `state.current_positions` now carries the reconciled $120.656279, and the prior cycle's "if D2a has not reconciled by the next cycle, that becomes a real defect" condition did not arise. **One new instance replaces it** — see "Items owned by other routines" |
| **F-6** — why one position was routed to further research | **MOOT.** Its subject (F-8) resolved; zero positions are routed to further research this cycle |
| **F-8** — GEV entry-eligibility | **RESOLVED ON EVIDENCE**, 2026-08-09. See above |
| **F-10** — GEV's "$200B by 2027" framing unverified | **REFUTED and withdrawn** on primary transcript evidence, 2026-08-09. Management stated 2027 on the Q1 2026 call, explicitly revising from 2028, and reaffirmed at Q2 2026 |
| **F-11** — `analytics.strategy_nav` silently dropping GEV | **CLOSED.** GEV's `state.current_positions` status is now uppercase `OPEN` (repaired append-only by `bigquery/137`), a curated mark exists, and `deployed_mv` $544.87 now includes it — verified by reproducing the full 12-tranche book against the view to the cent. No open position anywhere currently carries a lowercase status literal; `B:MTZ:2026-08-03`, the other live instance the prior cycle named, has since closed. The underlying writer-side hygiene question stays with W5/D3 as a class, but it has no live instance today |

---

## Per-position deep-dives

Every criterion below is applied **literally as written**, per the prospective-only drafting rule in `Claude_Task_Plan.md`: a pre-existing criterion is never softened, re-interpreted, or held to a threshold it does not state. Where a criterion requires two consecutive quarters, one quarter is reported as "1 of 2" and never as a breach. Where no new quarter printed inside the window, the verdict is stated against the most recent available measurement **and** the absence of new data is stated — both, because M4 needs to know the disposition and the evidentiary freshness separately.

---

### GEV — GE Vernova · 1 tranche · HOLD

**Recommendation: HOLD.** *(Changed from the prior cycle's FURTHER RESEARCH — see F-8. The change is entirely the eligibility question resolving; the thesis reading is unchanged and remains the strongest in the book.)*

**1. Thesis status.** Intact, and the furthest from invalidation of anything held. Subtype B trend-continuation on total-company organic orders growth, entered 2026-08-03 at $967.09, cost basis $120.656279 for 0.1244 sh, LTCG 2027-08-04, conviction MEDIUM. No new quarterly print occurred in the window; Q3 2026 is expected ~late October 2026. **The position is the book's largest at 20.06% of NAV and its worst performer at −9.42%** — which, per Strategy D's explicit "Not exit-triggering" list and this position's own `not_exit_triggering` field (which names short-term price action), bears on nothing.

**2. Multi-year driver check.** All measured at the Q2 2026 print (2026-07-22, pre-window) — no driver has a fresh data point inside the window, and nothing found in the window moves any of them:
- *Electrification / grid capex* — **progressing**: revenue $3,637M (+68% reported / +29% organic), EBITDA margin 18.4% (+700bp organic), equipment backlog $40.6B (+69% YoY).
- *Gas power orders* — **progressing, target raised**: slot reservations 100GW → 116GW in Q2 alone; YE2026 target raised 110GW → ≥125GW.
- *Backlog conversion* — **progressing**: $150.2B (FY25) → $163B (Q1'26) → $176.3B (Q2'26).
- *Wind drag* — **deteriorating**, and explicitly non-exit-triggering by the position's own field: Q2 orders −40% organic, EBITDA loss $(275)M.
- *Margin ramp* — **progressing**: FY26 FCF guide raised to $11.5–12.5B from $6.5–7.5B; adjusted EBITDA margin guide unchanged at 12–14%.

**3. Fundamental developments, 2026-08-03 → 2026-09-01.** One substantive filing:
- **8-K filed 2026-08-25, accession 0001996810-26-000153** (Item 5.02, read directly from EDGAR): **CFO succession.** Kenneth Parks retires effective 2026-04-02, serving as strategic advisor to CEO Scott Strazik from 2027-01-01. **Claire McDonough** (Rivian CFO since Jan 2021) joins as strategic advisor 2026-11-01 and becomes CFO 2027-01-01 (base $1,000,000; sign-on $5,000,000; make-whole award $14,500,000). A planned, future-dated transition, not a disruption, and it bears on no criterion.
- Commercial/product items (secondary, company newsroom): medium-voltage UPS launch (08-24); VSC-HVDC joint venture with LS Electric (08-26); SF₆-free 420kV circuit breaker at CIGRE Paris (08-26); a UK 400kV substation win via Laing O'Rourke/National Grid (08-27); a 43-turbine (3.8MW) onshore wind order from Enfinity Global in India (08-04). None is individually large enough to move total-company organic orders or backlog before the Q3 print.
- No 10-Q, earnings call, investor day or regulatory order bearing on the trend metric or backlog.

**4. Criteria.**

| Criterion | Verdict | Measured | Source | Next test |
|---|---|---|---|---|
| Invalidation — organic orders growth YoY < 15% for 2 consecutive quarters | **NOT BREACHED**, by the widest margin in the book | +65% → +71% → **+88%**, accelerating. 0 of 2 quarters below the line | Q2'26 8-K accession 0001996810-26-000147, `gevpressrelease2q26.htm`; series verified verbatim against all 8 primary transcripts on 2026-08-09 | Q3'26, ~late Oct 2026 |
| Metric-immutability — comparable disclosure lapses 2 consecutive quarters | **NOT BREACHED** | Disclosed comparably in every quarter Q1'25–Q2'26; 0 of 2 non-conforming | Same | Q3'26 |
| Completion leg (i) — reported backlog ≥ $200B | **NOT MET** | $176.3B — ~88% of the way, gap ≈ $23.7B | Same | Q3'26 |
| Completion leg (ii) — trailing-4Q organic orders growth decelerated to ≤ 25% YoY for ≥ 1 quarter | **NOT MET, and moving away from the trigger** | Trend is accelerating (65 → 71 → 88%), the opposite of what this leg requires | Same | Q3'26 |

The completion legs are conjunctive. Leg (i) is numerically close; leg (ii) shows no sign of approaching its trigger. **No completion is plausible at the Q3 print.** F-8's calibration finding is recorded above under F-13.

**5. Sector and theme context.** US electricity demand is inflecting (~1.7%/yr 2020–2025 vs ~0.1%/yr 2005–2019, secondary). Gas-turbine slot scarcity persisted through the window with no contrary evidence found; independent coverage (Utility Dive, Turbomachinery Magazine, Power Engineering) restates the Q2'26 116GW figure without adding to it. No tariff-guidance revision and no new regulatory action in the window — and both further Wind deterioration and additional tariff-guidance revisions are on this position's own `not_exit_triggering` list in any case.

**6. Long-term tax treatment.** LTCG 2027-08-04 — **337 days** away, the longest in the book. No thesis-completion signal is near, so no LTCG timing coordination arises.

---

### AMZN — Amazon · 2 tranches · HOLD

**Recommendation: HOLD.** No criterion breached; no information gap.

**1. Thesis status.** Intact. No new AWS quarter printed in the window (Q2 2026 was the last, 10-Q accession 0001018724-26-000026; Q3 expected ~2026-10-29, unconfirmed), so criteria 1–3 carry forward their last measurements rather than being freshly tested. The mark fell from $285.82 to $254.36 across the month, taking the position from +12.2% to essentially flat (−0.14%) — tracking a cohort-wide AI-capex selloff that also hit GOOGL and Meta, not an AWS-specific deterioration.

**2. Multi-year driver check.** AWS revenue re-acceleration, operating margin and backlog: **no new data point** (last: +37.0% YoY, 39.4% margin, $496B backlog with 6.4yr weighted-average life). *Trainium/model-partner adoption* — **progressing**: AWS's 2026-08-03 and 2026-08-17 roundups record OpenAI GPT-5.6 price cuts (up to 80% lower) on Bedrock and an "OpenAI Daybreak on Bedrock" launch, i.e. the OpenAI-on-AWS integration deepening rather than narrowing. *Capex-to-monetisation* — **mixed, and now the dominant market narrative**: the FY26 capex guide of $220B (raised at the 07-30 print, pre-window, ~70% AI-related) is the proximate driver of the sector selloff.

**3. Fundamental developments, 2026-08-03 → 2026-09-01.** **No 8-K, no 10-Q, no earnings print** — confirmed directly against `data.sec.gov/submissions/CIK0001018724.json`. The only in-window filings under Amazon's CIK are routine Forms 4/144, an N-PX, third-party 13F-HR/13G filings, and an **S-4/A (2026-08-14) → EFFECT (2026-08-18) → 424B3 (2026-08-18)** sequence advancing the **Globalstar acquisition** (merger agreement 2026-04-13, ~$11.57B, satellite direct-to-device for Amazon Leo/Kuiper). That is a real corporate action progressing in the window, but it is **not AWS-segment and touches none of the five criteria** — noted for completeness only. Operational items (rolling AWS regional incidents in US-West-2, Frankfurt and US-East-1 through mid-August) are covered by no criterion and produced no evidence of customer-commitment impact. **On AMZN's own primary disclosures the window is genuinely empty**, and is reported as such rather than padded.

**4. Criteria.**

| # | Criterion | Verdict | Measured | New data this window? | Next test |
|---|---|---|---|---|---|
| 1 | AWS YoY < 18% for 2 consecutive Q | **NOT BREACHED** | +37.0% YoY, a fifth consecutive acceleration. 0 of 2 | **No** | ~2026-10-29 |
| 2 | AWS op margin < ~30% for 2 consecutive Q | **NOT BREACHED** | 39.4%, a series high. 0 of 2 | **No** | ~2026-10-29 |
| 3 | AWS backlog declines sequentially 2 consecutive Q | **NOT BREACHED** | $496B, WAL 6.4yr, **primary-confirmed** in the filed 10-Q. 0 of 2 | **No** | ~2026-10-29 |
| 4 | Anthropic/OpenAI commits renegotiated down / churned | **NOT BREACHED** | No evidence the Anthropic ($100B/10yr) or OpenAI ($38B→$100B) **compute-purchase commitments** were reduced or churned; the relationship deepened in-window | Yes (continuous) | Continuous |
| 5 | Metric-immutability — AWS segment reporting restructures ≥ 2 Q | **NOT BREACHED** | No reporting-structure change | Yes (continuous) | Continuous |

**On criterion 4, a distinction applied literally rather than collapsed:** a *separate* commercial item — Anthropic reportedly renegotiating the price **Amazon pays to consume Claude models** on Bedrock/Alexa+/Quick Suite, shifting to token-based billing (~2026-06-30, pre-window; Amazon disputes it raises costs) — is **not** the relationship criterion 4 names. Criterion 4 tests Anthropic's and OpenAI's commitment to *buy AWS capacity*, and no source describes either as reduced.

**Prior-cycle carry-forward, now closed — do not re-flag.** Criterion 3's Q2 backlog figure was secondary-source pending the Q2 10-Q as of 2026-08-03. That 10-Q is filed (accession 0001018724-26-000026) and the $496B / 6.4yr figures are primary-confirmed verbatim in the revenue note. Resolved **before** this window opened.

**5. Sector and theme context.** AI-capex anxiety is a cohort narrative, not an AMZN signal — see F-9, which is exactly this. One monitoring item with **no covering criterion**: the EU Commission's preliminary DMA gatekeeper designation of AWS (2026-06-25) is progressing, with AWS's written-representations window running into September 2026 and a final decision expected ~late October 2026. Unlike GOOGL, AMZN carries **no criterion analogous to a structural-remedy test**, so a regulatory outcome here would register nowhere in this thesis. Recorded, not actionable.

**6. Long-term tax treatment.** LTCG 2027-07-09 (parent, **311 days**) and 2027-07-31 (add, **333 days**). No completion signal; no coordination arises.

---

### GOOGL — Alphabet · 2 tranches · HOLD

**Recommendation: HOLD.** No criterion breached. **Criterion 4 carries the book's one genuinely unscheduled risk** — see below; it is a monitoring trigger, not a research deferral.

**1. Thesis status.** Intact, strengthening. The last reported quarter (Q2 2026, 2026-07-22, pre-window) showed Cloud revenue **accelerating** 63% → 82% YoY with margin expansion. No new print in the window; Q3 expected ~2026-10-27/28.

**2. Multi-year driver check.** *Cloud growth/profitability* — **progressing**: +81.8% YoY ($24.77B vs $13.62B), operating margin 35.6% vs 20.7% YoY. *RPO/backlog* — **progressing**: total RPO $519.5B at 2026-06-30 ($513.9B Google Cloud), up from "over $460B" at 2026-03-31. *Custom silicon* — **progressing, new in-window**: Marvell 8-K (2026-08-18) discloses a warrant to Google for up to 58,970,907 shares (~$12.2B notional at $206.58 strike) tied to an expanded custom-silicon partnership across TPU-ecosystem inference accelerators and storage/network/memory controllers, vesting through FY2033 against $500M revenue tranches. A supplier-side filing, but directly thesis-relevant — it reduces single-vendor TPU dependency. *Antitrust overhang* — **stalled (unresolved), not reversed**. *Research-talent bench* — **the one mixed signal**, see below.

**3. Fundamental developments, 2026-08-03 → 2026-09-01.** No Alphabet earnings print or periodic filing in the window. What did land:
- **2026-08-05 — DeepMind leadership reorganisation.** Demis Hassabis stepped back from day-to-day DeepMind leadership to a newly created Alphabet Chief Scientist / chair role, with deputy Koray Kavukcuoglu taking over operations. Same day: **Jeff Dean** (27-year tenure), senior fellow **Sanjay Ghemawat**, DeepMind VP **Oriol Vinyals** and Google Brain co-founder **Quoc Le** departed to co-found an external startup ("Discovery Loop"), with Google as founding investor and cloud partner. The stock fell ~4% on the day. This is a genuine driver-relevant development for the multi-year AI-competitiveness case and **maps to no numbered criterion** — recorded as a watch item, with Google's retained investor/customer relationship as a partial mitigant.
- **2026-08-28/30 — EU DMA follow-on.** Google ceased manual "site reputation abuse" demotions of EEA-based publishers effective 2026-08-30 in response to a Commission DMA investigation. **Voluntary/behavioural compliance, not an adjudicated remedy.**
- **2026-08-31** — Gemini 3.1 Flash Image reached general availability in US/EU (secondary).

**4. Criteria.**

| # | Criterion | Verdict | Measured | New data this window? | Next test |
|---|---|---|---|---|---|
| 1 | Cloud revenue YoY < 20% for 2 consecutive Q | **NOT BREACHED** | Q1'26 +63%, Q2'26 +81.8%. 0 of 2 | No | ~2026-10-27/28 |
| 2 | Cloud op margin contracts 2 consecutive Q | **NOT BREACHED** | Expanded YoY both quarters (17.7%→32.9%, 20.7%→35.6%) and sequentially (32.9%→35.6%). 0 of 2 | No | ~2026-10-27/28 |
| 3 | Cloud RPO/backlog declines sequentially 2 consecutive Q | **NOT BREACHED** | ">$460B" → $519.5B total / $513.9B Cloud. 0 of 2 | No | ~2026-10-27/28 |
| 4 | **Adverse structural remedy** | **NOT BREACHED** — see below | No structural remedy ordered in any jurisdiction | Yes (continuous) | **Unscheduled** |
| 5 | Metric-immutability — Cloud revenue reported comparably | **NOT BREACHED** | Discrete segment, consistent basis, no restatement | Yes | Each filing |

**Criterion 4 in detail, because it is the only criterion in the book that can fire without warning.** All four tracked proceedings were re-verified this cycle and **none has ordered a structural remedy**:
- *DOJ search case* — final remedies judgment (2025-12-05) was **behavioural**: a six-year exclusive-default-contract ban, index/data-sharing mandates, syndication requirements, ad-auction transparency, a five-member Technical Committee (fully staffed May 2026). It **explicitly declined** Chrome divestiture and Android breakup. Now on appeal to the D.C. Circuit (both sides cross-appealed); briefing still underway, no appellate ruling in-window.
- *DOJ ad-tech case (E.D. Va., Judge Brinkema)* — liability found April 2025 (publisher ad-server/exchange monopolisation, unlawful DFP–AdX tying); remedies closing arguments concluded November 2025; **the remedies ruling has still not issued.** DOJ's requested relief **explicitly includes structural divestiture of AdX** (and potentially DFP). **This is the single live path to a criterion-4 breach anywhere in the book, and it has no scheduled date.**
- *EU DMA* — €890M fine (2026-07-23) was monetary/behavioural; the in-window policy change is likewise behavioural.
- *UK CMA* — Strategic Market Status (2025-10-10) and the "fair ranking" conduct requirement (2026-06-17) are behavioural conduct requirements. No new order in-window.

**Routing:** this is a **monitoring trigger, not a research deferral.** There is no information gap — the state of every proceeding is known and current; what is unknown is when a court will rule, which no amount of research resolves. If a Brinkema ruling breaks, it warrants **out-of-cycle triage rather than waiting for the next monthly cycle**, because a structural order would be an immediate criterion-4 breach on a 15.92%-of-NAV position. Flagged to M4 as a watch item with that framing.

**5. Sector and theme context.** Q2 2026 hyperscaler shares (secondary aggregation): AWS ~28% but slowest-growing (+19%); Azure ~21%, +40%, AI run-rate ~$37B; Google Cloud ~15% but fastest at the +63%→+82% pace measured above. Google Cloud is closing the growth gap from a smaller base — directionally supportive — while absolute share still trails materially.

**6. Long-term tax treatment.** LTCG 2027-07-09 (parent, **311 days**) and 2027-07-27 (add, **329 days**).

---

### DIS — Walt Disney · 2 tranches · HOLD

**Recommendation: HOLD (both tranches).** No criterion breached; two affirmatively re-passed at their own named checkpoints. The most information-rich name in the book this cycle.

**1. Thesis status.** Holds, strengthened. The FQ3 FY26 print (2026-08-05) extended SVOD-margin expansion to a third straight quarter and re-affirmed both the EPS-growth and buyback checkpoints, which is what triggered the 2026-08-05 add at MEDIUM-HIGH 62 on the strengthened-conviction path. Blended cost across both tranches ≈ $106.72/sh against a $108.855 mark — **+2.00%**, a marked recovery from the −11.8% the parent tranche alone showed at the prior cycle.

**2. Multi-year driver check.** *Streaming profitability inflection* — **progressing, strongest confirmation since entry**: SVOD operating income $712M vs $329M YoY (+116%), margin ~12.9%, third consecutive quarter of expansion (8.4% → 10.6% → 12.9%); Entertainment segment operating income $1,680M, +64% YoY. *EPS growth framework* — **progressing, reiterated**: FY26 ~12% adj EPS growth ex-53rd-week (~16% including) and FY27 double-digit both reiterated; Q3 adj EPS $2.06 vs $1.61 (+28%). *Buyback/capital return* — **progressing, accelerated**: 9-month YTD repurchases **$7,245M** (primary, 10-Q cash-flow statement) vs $2,496M in the prior-year nine months; full-year target **raised to ≥$9B** from $8B. *Parks/Experiences* — **progressing**: operating income $3,017M, +20% YoY. *ESPN DTC* — **progressing qualitatively**; no subscriber counts disclosed (a standing choice since the Aug-2025 launch quarter, not new and not criterion-relevant).

**3. Fundamental developments, 2026-08-03 → 2026-09-01.** Per `data.sec.gov/submissions/CIK0001744489.json`, Disney filed exactly **two** substantive documents in-window, both 2026-08-05, plus routine Forms 4/144:
- **8-K** (Items 2.02, 9.01), accession **0001744489-26-000056** — FQ3 FY26 earnings release (period ended 2026-06-27). Revenue $25.2B (+7% YoY).
- **10-Q**, accession **0001744489-26-000057** — confirms the buyback figure directly from the cash-flow statement, and confirms in its own segment note that the Consumer-Products-into-Entertainment reclassification takes effect **"commencing with our fiscal 2027 reporting."**

Non-filing developments:
- **2026-08-18 — Disney and ABC sued the FCC** in federal court (with station-licensee plaintiffs), seeking an injunction against the early-license-renewal proceeding the FCC ordered in April 2026, alleging First-Amendment retaliation. **This is Disney going on offense, not the FCC issuing an adverse order**, and it triggered no 8-K. It is the sharpest sector development of the cycle and sits directly upstream of criterion 5 — while leaving both of that criterion's legs unmet, and the second leg pointing the opposite way.
- **2026-08-18 — D23 2026**: product/marketing showcase (short-form "Verts" scaling, live-sports personalisation, international ESPN expansion). No guidance content.
- CEO succession (Josh D'Amaro effective the March 2026 shareholder meeting) pre-dates the window and is unchanged background.

**4. Criteria.**

| # | Criterion | Verdict | Measured | Source | Next test |
|---|---|---|---|---|---|
| 1 | Entertainment SVOD op margin < 8% for 2 consecutive Q | **UNBREACHED** | $712M / $5,530M ≈ **12.9%**; third consecutive quarter of expansion. 0 of 2 | 8-K Ex-99.1, acc. 0001744489-26-000056, 2026-08-05 | Q4 FY26, ~Nov 2026 |
| 2 | FY26 adj EPS growth guide cut to ≤ 6% | **UNBREACHED — affirmatively re-passed** at its own named Q3 checkpoint | Guide **reiterated** ~12% ex-53rd-wk / ~16% incl.; FY27 double-digit reiterated. No cut | Same 8-K | Next formal guide, ~Nov 2026 |
| 3 | FY26 buyback ≤$3B at H1 / ≤$5B at Q3 / suspended-reduced 8-K | **UNBREACHED — affirmatively re-passed** at its own named Q3 checkpoint | 9-month repurchases **$7,245M** against a ≤$5B Q3 floor; FY target **raised to ≥$9B**. This leg is now un-breachable for FY26 | 10-Q cash-flow statement (primary), acc. 0001744489-26-000057 | No further FY26 checkpoint before ~fiscal year-end |
| 4 | Metric-immutability — SVOD op income/margin not disclosed in current form ≥ 2 consecutive Q | **UNBREACHED** | Zero non-conforming quarters | 10-Q + 8-K, 2026-08-05 | **First test ~Feb 2027** (Q1 FY27); earliest possible auto-invalidation ~May 2027 |
| 5 | **ESCALATION** — FCC final order restricting TV-station ownership **AND** a Disney 8-K asserting material adverse FY26/27 EPS impact | **NOT ENGAGED** | Neither leg present. No final FCC order of any kind exists; Disney sued to enjoin the proceeding. And **no 8-K** characterises any development as materially adverse — the only in-window 8-K is the routine earnings release | EDGAR submissions feed; coverage 2026-08-18 | Unscheduled |

**A precision worth carrying forward on criterion 4**, established by direct read of both documents this cycle: **SVOD operating income has never lived in the 10-Q's segment footnote** — the 10-Q reports only consolidated Entertainment segment operating income ($1,680M this quarter). The "current form" the criterion protects is, and has always been, the **8-K Ex-99.1 supplemental table**. A future cycle that checks the 10-Q alone would wrongly record a non-conforming quarter and start the auto-invalidation clock. See F-14.

**5. Sector and theme context.** The SVOD margin trajectory (8.4% → 10.6% → 12.9%) continues to validate the streaming-maturation thesis; Entertainment profitability (+64% YoY operating income) is now a larger swing factor than the legacy linear book. Broadcast regulation is the live sector story — the Disney/ABC suit is a first-of-its-kind escalation (the first time in 50+ years the FCC ordered early renewal across a network's full O&O station suite). Paramount Skydance's ~$110.9B acquisition of Warner Bros. Discovery (shareholder-approved April 2026, contested by a 12-state AG suit, expected close ~Q3 2026) continues to reshape the competitive set, with no direct bearing on any DIS criterion.

**6. Long-term tax treatment.** Parent tranche LTCG **2027-05-08 — 249 days**, the second-nearest in the book. **The add tranche's `ltcg_date` is NULL in the ledger** — a faithful echo of the superseded provisional row by D2a, which correctly declined to mint a horizon date it is not the mechanism for. The fill was 2026-08-06. See "Items owned by other routines"; this routine does not assert the date either.

---

### TSM — Taiwan Semiconductor · 2 tranches · HOLD

**Recommendation: HOLD.** No criterion breached; criterion 3 has evidence pointing actively away from breach.

**1. Thesis status.** Intact. The only primary print inside the window — July 2026 monthly revenue, released 2026-08-10 — shows continued acceleration. No quarterly print (GM, USD revenue YoY, node mix) lands until the **Q3 2026 call on 2026-10-15**, so criterion 1 and the mix half of criterion 2 are untestable this cycle **on schedule, not by omission**.

**2. Multi-year driver check.** *Leading-edge node leadership* — **progressing**: N2 in volume production, five 2nm fabs ramping through 2026, N2P confirmed for 2H26. A16 volume production is guided to **2027**, but that shift was reported in April 2026 — before both tranche entries (07-21, 07-29) — and was **not further pushed out in-window**. *CoWoS/advanced packaging* — **progressing, demand-constrained**: 5.5-reticle CoWoS yield >99% (TrendForce, 08-11); TSMC now **outsourcing CoWoS front-end steps to OSATs** (Amkor/ASE) because in-house capacity cannot keep up (TrendForce, 08-05) — a shortage, not a utilisation collapse. *AI/HPC mix* — **progressing**: July revenue +44.7% YoY. *US expansion* — **progressing**: the additional $100B Arizona investment (2026-07-16, pre-window) brings the total to $265B / 12 fabs; Fab 3 (2nm/A16-capable) construction began May 2026.

**3. Fundamental developments, 2026-08-03 → 2026-09-01.**
- **2026-08-10 (primary, TSMC PR / SEC 6-K):** July 2026 revenue **NT$467.58bn, +5.6% MoM, +44.7% YoY**; Jan–Jul cumulative NT$2,872.06bn, **+37.0% YoY**. The filing carries no USD-converted figure; secondary outlets' ~$14.5B estimate is treated as secondary and approximate, and one outlet's "$16.03B" appears to be an FX-conversion error and is not used.
- 2026-08-05 (TrendForce, secondary): CoWoS front-end outsourcing expansion amid rising Nvidia/ASIC demand.
- 2026-08-26 (Digitimes, secondary): a packaging-capacity shift that could raise AMD's CoWoS allocation share and modestly trim Nvidia's — a **mix reallocation among customers, not a net demand cut**.
- No capex revision in-window: the $60–64B FY26 guide and the ">40% USD revenue growth in 2026" outlook were set at the 2026-07-16 Q2 call, pre-window, and are baseline rather than new. The August monthly revenue release (~2026-09-10) falls outside the window.

**4. Criteria.**

| # | Criterion | Verdict | Measured | New data this window? | Next test |
|---|---|---|---|---|---|
| 1 | GM < 55% **OR** USD revenue YoY < 15%, 2 consecutive Q | **NOT BREACHED** on the last measurement; **no new quarterly data** | GM 67.7%, USD revenue +33.7% YoY (Q2'26 baseline). In-window proxy only: monthly NT revenue +44.7% YoY — far above any 15% threshold, but **not** the specified USD-quarterly metric, and reported as a proxy rather than substituted for it | Proxy only | **2026-10-15** (first of any consecutive pair) |
| 2 | N2/A16 ramp pushed out **OR** sub-7nm share declines 2 consecutive Q | **NOT BREACHED** | No fresh pushout in-window (the A16→2027 shift pre-dates both entries); sub-7nm mix last 77% and rising, no new figure | Partial | 2026-10-15 for mix |
| 3 | Structural AI-capex reset (hyperscaler/Nvidia order cuts; CoWoS utilisation drop) | **NOT BREACHED — evidence points the other way** | Hyperscaler 2026 capex raised, not cut, through the late-July round; **no** reported Nvidia or hyperscaler order cut in-window; TSMC *outsourcing* packaging because demand exceeds capacity; capex guide unrevised | Yes (continuous) | Continuous; Q3 hyperscaler earnings late Oct/early Nov |

**On criterion 3, applied as written:** it carries no two-quarter qualifier and no numeric threshold — it is a *structural-reset* test, and it is judged as one. A stale 2025-08-05 "CoWoS utilisation only 60%" figure surfaced in search and is **not** used: it predates the window by a year. The genuine caution, recorded without inflating it into evidence: investor scrutiny of hyperscaler capex sustainability intensified around the late-July earnings round, and Microsoft's useful-life accounting change makes headline capex trends harder to read cleanly. Neither is an order cut.

**5. Sector and theme context.** CoWoS remains the tightest link in the AI-accelerator chain, with HBM and ABF substrate — not TSMC wafer capacity — flagged as the next constraint. Intel 18A and Samsung SF2 are reported closing the yield gap (Intel ~85% vs TSM ~90% on N2; Samsung SF2 ~40% vs TSM ~60%), but these are **secondary, search-aggregated figures not verified against a primary source this cycle** and are treated as directional only. Export controls (annual US Commerce licence renewal since the VEU exemption lapsed 2025-12-31; Taiwan weighing stricter outbound controls) are unchanged structural background — **no new restriction was actually imposed in-window.**

**6. Long-term tax treatment.** LTCG 2027-07-21 (parent, **323 days**) and 2027-07-30 (add, **332 days**).

---

### UBER — Uber Technologies · 1 tranche · HOLD

**Recommendation: HOLD.** No criterion breached — and this is **the one name in the book whose criteria were tested against a genuinely new, post-entry quarter this cycle.**

**1. Thesis status.** Intact, and materially better evidenced than a month ago. The prior cycle flagged UBER as carrying "the thinnest evidentiary basis in the book" with zero new quarters since entry. **That caveat is now resolved:** Q2 2026 printed 2026-08-05, inside the window, and criteria 1 and 2 have now cleared across two genuinely post-entry quarters (Q1'26 and Q2'26) rather than resting on pre-entry data.

**2. Multi-year driver check.** *Mobility+Delivery flywheel* — **progressing**: GB $58.0B, +24% reported / **+22% cc**; trips +18% YoY to 3.9B; MAPCs +16% YoY to 208M; Mobility GB +20% cc, Delivery GB +25% cc. *Uber One membership* — **progressing**: "reached another all-time high," members now >70% of Delivery Gross Bookings, up ~20pp in two years. *Margin expansion* — **progressing**: adjusted-EBITDA margin **4.9% vs 4.5%** YoY (+40bp), a second consecutive quarter of YoY expansion; non-GAAP operating margin 3.7% vs 3.3%. TTM free cash flow exceeded **$10B for the first time**. *AV hedge* — **progressing, risk character unchanged**: multi-partner posture reaffirmed (15 markets by year-end 2026, "expanding significantly" in 2027), AV still <0.5% of trip volume; Nevada regulators approved Uber for up to 1,000 robotaxis in Clark County on 2026-08-20, alongside Tesla (5,000) and Waymo (1,000) — a concrete instance of Uber positioning as the aggregation layer across AV suppliers, and equally a live instance of the "hosting a competitor" tension the entry flagged.

**3. Fundamental developments, 2026-08-03 → 2026-09-01.**
- **2026-08-05 — Q2 2026 earnings, 8-K accession 0001543151-26-000027** (primary): GB $58.022B (+24% / +22% cc); revenue $14.191B (+12% / +11% cc — the release attributes 8pp of the growth gap to business-model changes, a revenue-recognition effect distinct from GB); GAAP diluted EPS $1.17 (including a $1.6B pre-tax equity-revaluation benefit); adjusted EBITDA $2.819B at a 4.9% margin; FCF $2.792B. Q3 guidance: GB $58.25–60.25B (18–22% cc), non-GAAP EPS $0.84–0.88.
- **2026-08-05 — 10-Q, accession 0001543151-26-000032** (period ended 2026-06-30).
- **2026-08-06 — 8-K, accession 0001552781-26-000414**: Term Loan Credit Agreement with Morgan Stanley Senior Funding plus a Bridge Credit Agreement amendment, financing the **Delivery Hero** acquisition (business combination agreement 2026-07-16, pre-window).
- **2026-08-27** — Delivery Hero tender offer advanced: following BaFin approval, Uber published the formal Offer Document (€41.50/share, ~$14.8B), acceptance period 2026-08-27 → 2026-11-05, **close still targeted H2 2027, unchanged**. *(Sourcing caveat: the exact accession attribution between the July BCA and the August offer document could not be cleanly disambiguated and is not relied on.)*
- **~2026-08-21 — Dutch DPA fine of €824,990,000 (~$966M)** against Uber B.V./Uber Technologies under GDPR, for automated driver-deactivation decisions without human review covering 2020–2022 conduct. Uber is appealing. **This maps to none of the four criteria** — it is not a GB, margin, membership or GB-disclosure event, and it is not a driver-classification ruling. See §5.
- No driver-employment-classification ruling, and no management change, dated inside the window.

**4. Criteria.**

| # | Criterion | Verdict | Measured | New data this window? | Next test |
|---|---|---|---|---|---|
| 1 | GB constant-currency YoY < ~15% for 2 consecutive Q | **NOT BREACHED** | Q1'26 +21% cc, Q2'26 **+22% cc** — accelerating slightly. 0 of 2 | **Yes** | Q3'26, ~early Nov (already guided 18–22% cc) |
| 2 | Adj-EBITDA margin (% of GB) contracts YoY 2 consecutive Q | **NOT BREACHED** | Q1'26 4.62% (+26bp YoY), Q2'26 4.9% vs 4.5% (**+40bp YoY**) — two consecutive quarters of *expansion*, the opposite of the trigger. 0 of 2 | **Yes** | Q3'26 — **see F-14 for the testability risk** |
| 3 | Uber One membership stalls / declines sequentially | **NOT BREACHED** | Applied literally, with no invented threshold and no two-quarter qualifier: the CEO's Q2 2026 prepared remarks state membership "reached **another all-time high** this quarter" — the series is measured as increasing, the direct opposite of "stalls or declines" | **Yes** | Q3'26 |
| 4 | Metric-immutability — GB disclosure structurally changes | **NOT BREACHED** | The GB definition paragraph was read in full and is **verbatim-unchanged** from prior quarters | **Yes** | Each quarter |

**A measurement caveat on criterion 3, stated rather than glossed.** Q1 2026 gave a raw count (">50 million"); the Q2 2026 primary materials — press release, prepared remarks and call transcript — disclose only the qualitative "all-time high" framing plus the %-of-Delivery-GB engagement metric, with **no raw Q2 headcount**. The qualitative language is itself primary-sourced and answers the criterion's literal wording, so the verdict stands. But a numeric sequential comparison was not obtainable, and the next cycle should seek the raw count again.

**This does not meet the bar for a research deferral, and is deliberately not routed as one.** It is a *specificity* gap on a criterion whose literal wording tests the direction of a series, not a numeric threshold — and that wording was answered affirmatively on primary evidence. Manufacturing a `PENDING_ANALYSIS` with an exit-if-unresolved default over it would put a healthy position at risk of a process exit for want of a number the criterion never asked for.

**5. Sector and theme context.** The platform continues to show growth and margin expanding together rather than trading off — Delivery segment operating income +38% YoY on GB +25% cc. Three shifts beneath the headline: the AV transition is now multi-jurisdictional and explicitly multi-partner on Uber's side, which is the two-sided hedge the thesis names, while Uber's own AV volume stays structurally behind the suppliers it hosts; regional food-delivery competition in Brazil is a named drag on trips growth (management attributed a 2-point moderation entirely to it) though not yet GB-material; and **the Dutch GDPR fine is a reminder that driver-relations, algorithmic-management and labour-regulatory risk sit entirely outside the four criteria as written** — none of 1–4 would register a labour shock of any size. A scope observation carried forward, not an invalidation-relevant finding.

**6. Long-term tax treatment.** LTCG 2027-07-09 — **311 days**.

---

### ISRG — Intuitive Surgical · 1 tranche · HOLD

**Recommendation: HOLD.** No criterion breached; criterion 4 was tested against the specific event the prior cycle flagged and did not fire.

**1. Thesis status.** Intact. No new print in the window (Q2 2026 landed 2026-07-16, just before it; Q3 lands ~mid-October), so criteria 1–3 carry Q1/Q2 2026 measured values. The stock's ~33% YTD drawdown through mid-August is a valuation and guidance-pace re-rating, not a driver failure — every driver below is positive and above threshold, and Oppenheimer upgraded to Outperform ($500 PT) on 2026-08-12 inside that same drawdown.

**2. Multi-year driver check.** *Procedure volume* — **progressing**: worldwide procedures +17% YoY (Q1'26) and +16% (Q2'26); da Vinci alone +16% and +15%. FY2026 guidance held at 13.5–15.5% — a deceleration from FY2025's ~18% pace, but comfortably above the 10% floor. *Installed-base placements* — **progressing**: 431 systems in Q1'26 (vs 367, +17.4%) and 468 in Q2'26 (vs 395, +18.5%); installed base 11,710 units at 2026-06-30, +12% YoY. *Recurring/instrument attach* — **progressing**: instruments & accessories revenue +18% YoY in Q2'26 ($1.73B vs $1.47B), outpacing procedure growth; recurring ≈85% of the revenue mix. *dV5 cycle* — **progressing**: dV5 was 246 of 468 Q2'26 placements (from 180 of 395) and 232 of 431 in Q1'26 (from 147 of 367).

**3. Fundamental developments, 2026-08-03 → 2026-09-01.** No ISRG 8-K or other Item-triggering filing fell inside the window — an EDGAR search for the period returned only routine Forms 4/144. The Q2 2026 earnings 8-K (accession 0001035267-26-000047) and 10-Q (accession 0001035267-26-000058) both pre-date it. Company-specific items:
- **2026-08-17** — a new ~316,000 sq ft manufacturing facility announced in Penang, Malaysia (~US$200M phase one scaling to ~US$500M over five years, operations targeted 2028, ~1,200 jobs by 2032), producing da Vinci instruments. Capacity and supply-chain diversification — a second Asia site — not a thesis catalyst.
- No management change in-window (the Charlton→Patton Chief Commercial & Marketing Officer transition was effective 2026-07-01, pre-window) and no FDA or regulatory action on ISRG itself.

**The window is genuinely quiet for ISRG-specific events, and is reported as such.**

**4. Criteria.**

| # | Criterion | Verdict | Measured | New data this window? | Next test |
|---|---|---|---|---|---|
| 1 | Procedure growth < 10% YoY for 2 consecutive Q | **NOT BREACHED** | Q1'26 +16%, Q2'26 +15%. 0 of 2 | No | Q3'26, ~mid-Oct |
| 2 | Placements decline YoY for 2 consecutive Q | **NOT BREACHED** | 431 vs 367 (+17.4%); 468 vs 395 (+18.5%). 0 of 2, both grew | No | Q3'26 |
| 3 | Recurring revenue decouples DOWN from procedures | **NOT BREACHED** | Instruments & accessories +18% YoY against da Vinci procedures +15% — attach strengthening, not decoupling downward | No | Q3'26 (no two-quarter qualifier; monitored continuously) |
| 4 | A competitor discloses displacing da Vinci at **named large IDNs** | **NOT MET** | See below | **Yes** | Continuous |

**Criterion 4 was the prior cycle's one dated open item, and it was tested directly.** J&J's Ottava investor call occurred **2026-08-03 — day one of this window**, confirming the carry-forward was correctly timed. J&J described only a general launch strategy ("early adopters and established robotic surgery programs, including academic and non-academic hospitals with high procedural volumes"). **No specific IDN was named, and no claim of displacing an existing da Vinci installation was made.** Applied literally, the criterion requires a *named large IDN* and a *displacement*; neither is present. The other competitors were checked and none qualifies either: Medtronic Hugo — no named-IDN displacement disclosed; Distalmotion Dexter — the nearest example is Cypress Surgery Center, Wichita (March 2026, pre-window), a single ambulatory surgery centre buying its **first** robot, so neither a large IDN nor a displacement; CMR Versius Plus — FDA clearance Dec 2025, US commercialisation "planned for 2026," no named-IDN win. **MicroPort's Toumai** is reported to have overtaken da Vinci in aggregate Chinese domestic share for Jan–May 2026 (secondary) across 30+ hospitals — that is a **market-share statistic, not a named-IDN displacement disclosure**, and China competition was already a disclosed headwind management cited on the Q1/Q2 calls, not a new in-window disclosure.

**The watch stays active rather than lapsing.** J&J's disciplined-launch messaging on 2026-08-03 signals initial commercial placements are now beginning, which is exactly when a qualifying disclosure becomes possible.

**5. Sector and theme context.** Surgical robotics is more contested than a year ago but remains pre-displacement: Ottava received its first FDA authorisation on 2026-07-22 and is in a deliberately slow, high-volume-site-only rollout; Hugo is characterised in industry commentary as "another choice" rather than a share-taker, hampered by switching costs and da Vinci-trained teams; CMR and Distalmotion target the ASC/smaller-footprint niche rather than large-hospital IDN accounts. The one genuinely intensifying pressure point is **China**, where Toumai is priced 60–75% below da Vinci (secondary estimates). Hospital capex and reimbursement headwinds (ACA subsidy changes, Medicaid funding uncertainty, European/Japanese capital constraints) are management-cited and consistent with FY2026 guidance sitting below FY2025's realised pace — a deceleration, not a reversal.

**6. Long-term tax treatment.** LTCG 2027-07-20 — **322 days**. *(The separate `B:ISRG:2026-07-21` tranche closed 2026-08-12 on its convergence target and is out of scope; unlike the prior cycle, no share-count split-out was needed — the connector now reports 0.1091 sh, the D tranche alone.)*

---

### RTX — RTX Corporation · 1 tranche · HOLD

**Recommendation: HOLD.** All six criteria not breached. The book's oldest and best-performing position.

**1. Thesis status.** Intact, unchanged. **No 8-K, no earnings, no guidance revision, no litigation ruling and no management change in the window — verified, not merely unfound:** a direct EDGAR check (CIK 0000101829) confirms the most recent 8-K remains the 2026-07-23 Q2 print, accession 0000101829-26-000025, with nothing filed between it and 2026-09-01. What the window delivered instead is a dense run of defence program awards that corroborate the thesis without testing it.

**2. Multi-year driver check.** *Commercial aftermarket (GTF MRO)* — no new data point (last: 43% YoY MRO output growth, AOGs −25% YTD, Q2'26). *GTF Advantage EIS* — unchanged; base entry-into-service already underway (EASA A320neo-family certification April 2026, first shipset to Airbus May 2026), with no in-window milestone in either direction. *Defence backlog and international demand* — **materially reinforced** by the award cluster below, though none of it is a *backlog* data point (that only updates at earnings). *FCF ramp* — no new data point (last: guide raised to $8.50–8.75B).

**3. Fundamental developments, 2026-08-03 → 2026-09-01.** All company press releases rather than 8-Ks — routine program awards sit below RTX's materiality threshold:
- **2026-08-17 — a $22.9B, seven-year Department of War contract** to ramp Tomahawk cruise-missile production to >1,000/yr; RTX states it delivered 3× more Tomahawks in H1'26 than H1'25. Among the largest single defence awards in RTX's history (corroborated by Bloomberg, 2026-08-17).
- **2026-08-10 — $745M** from the Missile Defense Agency for SM-3 IIA interceptor production and sustainment.
- 2026-08-11 — Collins Aerospace award supporting US Army Chinook modernisation (value not located); 2026-08-25 — a **$603M** Air Force contract; 2026-08-27 — a **$240.75M** Navy contract modification and a $50M Mississippi facility expansion completion. *(The last three are secondary aggregations of RTX's own news feed rather than independently fetched primary releases, and are labelled as such.)*
- **The Airbus/GTF litigation had no dated development in-window.** Repeated searches across the interval between the confirmed 2026-03-19 escalation and 2026-09-01 surfaced no ruling, no filing and no settlement. The dispute remains in the same unresolved, unquantified-damages posture.

**4. Criteria.**

| # | Criterion | Verdict | Measured | New data this window? | Next test |
|---|---|---|---|---|---|
| 1 | Material adverse Airbus damages ruling > $2B | **NOT BREACHED** | No ruling, settlement or adjudicated figure exists. Dispute still at the escalated-claim stage | Searched, none found | Unscheduled; next disclosure vehicle is the Q3 10-Q, ~2026-10-20 |
| 2 | New powder-metal-style mass quality event > $1B incremental charge | **NOT BREACHED** | No new charge announced; only retrospective coverage of the 2023-origin program | Searched, none found | Q3 earnings, ~2026-10-20 |
| 3 | GTF Advantage EIS slips beyond Q1'27 | **NOT BREACHED** | No schedule statement in-window in either direction; base EIS already begun | No | Q3 call, ~2026-10-20 |
| 4 | Backlog declines two consecutive quarters | **NOT BREACHED** on the last measurement; **no new quarterly data** | $289B at Q2'26 (+22% YoY, +6% sequential). 0 of 2 | No | Q3 earnings, ~2026-10-20 |
| 5 | FY26 FCF guide cut below the $7.5B floor | **NOT BREACHED** | Guide **raised** to $8.50–8.75B, a full $1.0B above the floor; no revision in-window | No | Q3 earnings, ~2026-10-20 |
| 6 | FY27 defence procurement cut ≥ 10% YoY | **NOT BREACHED — trend is the opposite of a cut** | FY27 appropriations unenacted; the House Defense bill (H.R. 9495) cleared committee but not the floor, the Senate committee has not passed its version, and **both chambers passed continuing resolutions at FY26 levels** (House through Dec 4, Senate through Dec 11) rather than any cut. FY27 request still $1.5T | Yes | Not measurable as *enacted* until FY27 appropriations conclude — now ~Dec 2026 / Q1 2027 given the CRs |

**Q1'27 falsifiable-milestone reassessment — separate, and not an invalidation criterion.** Status unchanged: all five named milestones (AOGs, GTF Advantage EIS, backlog ≥$280B, FY26 EPS $6.70–6.90, defence organic growth ≥ mid-single-digits) were already satisfied three quarters early as of Q2'26, and nothing in this window moves any backward. The reassessment itself is gated on the actual Q1'27 call and is not due until early 2027. *(This is F-1's live illustration: five milestones satisfied early, and no mechanism by which that constitutes completion.)*

**A drafting note carried forward, so it is not re-litigated:** an earlier draft criterion, "stock breaks $130 on heavy volume," was **explicitly dropped by the entry record itself** as contradicting Strategy D's no-stop design. Six criteria is the final list. No price-based test is reinstated here, and RTX's +17.64% mark is informational only.

**5. Sector and theme context.** The FY27 appropriations process is live and running behind schedule but on an *increase* trajectory, not a cut. The Airbus–Pratt dispute continues to be characterised in secondary coverage as a genuine supply-chain strain (Airbus reportedly delivering ~20% below original 2026 targets, attributed in part to GTF shortages) with no resolution mechanism visible. The award cluster — the $22.9B Tomahawk contract foremost — directly corroborates the record-backlog driver even though it will not appear as a measured backlog figure until Q3.

**6. Long-term tax treatment.** LTCG **2027-04-27 — 238 days**, the nearest in the book. No completion signal and no invalidation, so nothing to coordinate; per the Rev 39 owner directive, exit timing is governed solely by thesis completion/invalidation and LTCG applies passively if the line has been crossed by the time criteria fire.

---

## Long-term tax treatment — full book

No position is within 12 months of a thesis-completion signal, and none is near invalidation, so **no LTCG timing coordination arises anywhere in the book this cycle.** Per the Rev 39 owner directive (2026-07-21) the former preference for post-12-month completion exits is removed: exit timing is governed solely by thesis completion or invalidation, and LTCG treatment applies passively whenever the 12-month line has already been crossed.

| Tranche | LTCG date | Days from 2026-09-01 |
|---|---|---|
| `D:RTX:2026-04-27` | 2027-04-27 | 238 |
| `D:DIS:2026-05-07` | 2027-05-08 | 249 |
| `D:AMZN:2026-07-09` | 2027-07-09 | 311 |
| `D:GOOGL:2026-07-09` | 2027-07-09 | 311 |
| `D:UBER:2026-07-09` | 2027-07-09 | 311 |
| `D:ISRG:2026-07-20` | 2027-07-20 | 322 |
| `D:TSM:2026-07-21` | 2027-07-21 | 323 |
| `D:GOOGL:2026-07-26` | 2027-07-27 | 329 |
| `D:TSM:2026-07-29` | 2027-07-30 | 332 |
| `D:AMZN:2026-07-30` | 2027-07-31 | 333 |
| `D:GEV:2026-08-03` | 2027-08-04 | 337 |
| `D:DIS:2026-08-05` | **NULL in the ledger** | — (fill 2026-08-06) |

---

## Summary of recommendations

| Name | Recommendation | Basis |
|---|---|---|
| **GEV** | **HOLD** | No criterion met, by the widest margin in the book — organic orders growth +88% against a 15% floor, 0 of 2 quarters. Prior cycle's FURTHER RESEARCH is withdrawn: the eligibility gap (F-8) was resolved on primary evidence 2026-08-09 and its queue item closed with the exit default not fired. Neither completion leg is close |
| **AMZN** | **HOLD** | No criterion met. AWS +37% YoY, margin 39.4%, backlog $496B primary-confirmed; the Anthropic/OpenAI compute commitments are intact and the Bedrock relationship deepened in-window. No new quarter — next test ~2026-10-29 |
| **GOOGL** | **HOLD** | No criterion met. Cloud +82% YoY, margin 35.6%, RPO $519.5B. Criterion 4 re-verified across all four proceedings: no structural remedy ordered anywhere; the DOJ ad-tech remedies ruling remains the one unscheduled path to a breach and is flagged for out-of-cycle triage |
| **DIS** | **HOLD** (both tranches) | No criterion met. SVOD margin ~12.9% against an 8% floor, third straight quarter of expansion; criteria 2 and 3 **affirmatively re-passed** at their own named Q3 checkpoints (guide reiterated ~12%; 9-month buyback $7,245M against a ≤$5B floor, target raised to ≥$9B). Criterion 5 NOT ENGAGED — no final FCC order, and Disney sued to enjoin the proceeding |
| **TSM** | **HOLD** | No criterion met. July revenue +44.7% YoY (primary, in-window); criterion 3 actively contradicted by CoWoS capacity being *outsourced* under excess demand and by an unrevised $60–64B capex guide. No new quarter — next test 2026-10-15 |
| **UBER** | **HOLD** | No criterion met, and uniquely in this book, tested on a **new post-entry quarter**: GB +22% cc against a ~15% floor, adj-EBITDA margin +40bp YoY (second consecutive expansion), Uber One at an all-time high, GB definition verbatim-unchanged |
| **ISRG** | **HOLD** | No criterion met. Procedures +16%/+15%, placements +17.4%/+18.5%, instruments +18% outgrowing procedures. Criterion 4 tested directly against J&J's 2026-08-03 Ottava call: no IDN, hospital or health system named anywhere, and no displacement claimed |
| **RTX** | **HOLD** | No criterion met, all six actively re-tested. Backlog $289B (+22% YoY); FY26 FCF guide raised to $8.50–8.75B against a $7.5B floor; no Airbus ruling exists; FY27 appropriations running at FY26 levels under CRs, not cut |

**Zero exits. Zero completions. Zero research deferrals. No IMMEDIATE-ACTION flag.**

---

## Items owned by a routine other than M4's exit path

Reported here for their owners, **not repaired by this routine.** M3 is research-only: this run wrote nothing to `state.*`, `perf.*`, or `events.position_events`, staged no order, and altered no criterion.

1. **`D:DIS:2026-08-05` carries a NULL `ltcg_date`** (fill 2026-08-06). D2a echoed the superseded provisional row byte-identically and correctly declined to mint a horizon date, which is not its mechanism — `bigquery/121` is. This is a new instance of the class the prior cycle's F-4 closed for RTX and the DIS parent. **Owner: the horizon-date correction mechanism (`bigquery/121` class), via D3's self-heal sweep.** Recorded as an `ops.alerts` info row, category `ltcg_date_missing`. This routine does not assert the date either: the parent tranche's convention (fill 2026-05-07 → 2027-05-08) and the GEV precedent (fill 2026-08-03 → 2027-08-04) both suggest 2027-08-07, but the AMZN, TSM and GOOGL tranches use fill-date +1 year exactly, so the convention is not uniform and minting it here would be guessing.
2. **F-12 — the sector-cap denominator artifact.** A spec-interaction question between Operating_Protocols.md §16 and Strategy.md's Strategy D Entry criterion 5. **Owner: W5 SPEC-DEFECT NOTICE INTAKE.** `ops.alerts` info row, category `sector_cap_denominator_artifact`. **No action is owed by M4** beyond carrying it as context.
3. **F-15 — FMP tier fallback not the default.** The 2026-08-09 adjudication (issuer IR and EDGAR are free primary sources; FMP plan-gating is a source-selection problem) has not propagated into research practice. **Owner: W5 SPEC-DEFECT NOTICE INTAKE**, since the fix touches shared routine prose with fleet-wide blast radius. `ops.alerts` info row, category `fmp_tier_fallback_not_default`.
4. **The BA NO-GO rests on a refuted premise.** D2's 2026-08-09 correction records that BA's 2026-08-03 criterion-2 NOT MET determination rests on the same FMP-gating premise that was refuted — all eight required Boeing transcripts are free on Boeing's IR CDN. A D candidate was declined on a tooling limitation that did not exist. **Owner: whichever routine next re-screens BA** (D2 thesis construction / Q2 candidate generation). Not M3's — BA is not a held position and is out of this routine's scope. Recorded here so it is not lost.
5. **The GOOGL DOJ ad-tech remedies ruling needs out-of-cycle triage, not monthly cadence.** Judge Brinkema's remedies decision is unscheduled and DOJ's requested relief includes AdX divestiture — a structural remedy would breach criterion 4 immediately on a 15.92%-of-NAV position. **Owner: whichever surface watches dockets between M3 cycles (D1's development scan).** Flagged to M4 as a watch item.
6. **UBER criterion 2's testability risk (F-14).** Adjusted EBITDA is described by Uber's own release as "no longer a key measure used by management," now for a second consecutive quarter, and UBER's metric-immutability clause covers Gross Bookings only. Not repairable — criteria are immutable — but it should be watched at the Q3 print. **Owner: the next M3 cycle**, recorded here.

---

## Method, and what this run did not do

- **Positions** from `state.current_positions` (12 D rows); **marks** from the live IBKR connector (`get_account_positions`, 2026-09-01); **cost basis, criteria and horizon dates** from the ledger's `invalidation_status` JSON, verbatim; **decisions, queue state and capital movements** from `events.decision_log`, `events.queue_events` and `events.cash_flows`; **engine state** from `perf.strategy_daily` / `perf.kill_flags`; **regime** from `events.regime_events` and today's M1a/M1b outputs. Strategy rules from `strategy/06_strategy_d.md` + `01_shared_regime_vocabulary.md`, per the slice map.
- **Per-position research** was delegated to eight parallel sub-agents, one per name, each given that position's criteria verbatim and instructed to apply them literally. Their findings were **adjudicated here, not adopted** — two material sub-agent errors were caught and corrected (F-5 items 1 and 2), and one carry-forward conclusion ("GEV's checkpoint is overdue by 23 days") was reversed outright against BigQuery.
- **Every criterion verdict is stated against a named primary source with a date**, and every figure whose only source was an aggregator or a search summary is labelled secondary where it is used at all. Where the window contained nothing for a name, that is reported as a clean empty window rather than padded.
- **Not done, deliberately:** no criterion was rewritten, softened, or re-interpreted; no position was exited, trimmed or added to; no order was crafted; no queue item was created or closed; no `state.*`, `perf.*` or `events.position_events` row was written. The one recommendation that changed (GEV) changed because its blocking question was answered elsewhere, not because this routine re-read its criteria more leniently.
