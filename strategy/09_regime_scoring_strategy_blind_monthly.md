<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Regime scoring (strategy-blind, monthly)

The **M1a** routine — strategy-blind monthly regime scoring. It produces a scored assessment across five regime-condition axes from public macro/policy/earnings inputs, with **no reference to any strategy** (no strategy letter, activation rule, or mechanism). The per-strategy mapping that consumes this scoring — the **M1b** routine, its reconciliation rules that name specific strategies, the output format, and the divergence-review path — lives in `## Regime router` above; M1a is blinded from all of it. This is a **distinct top-level section** so the generated `strategy/` slice for M1a carries the scoring inputs WITHOUT the strategy-naming mapping, making M1a's blinding a hard file boundary rather than a discipline-only rule (see `Claude_Task_Plan.md` "Strategy reading" + `ops/RUNBOOK.md` §9).

*M1a routine (strategy-blind regime scoring).* Fresh routine context. Given the 6 input categories below, produces a scored assessment across five regime condition axes without any reference to strategies A–E, their activation rules, or their mechanisms. No mention of the word "strategy" or any of the five strategy letters in this routine's prompt or input material:
- Growth momentum (accelerating / stable / decelerating)
- Inflation trend (disinflating / stable / reaccelerating)
- Policy stance (dovish / neutral / hawkish)
- Risk sentiment (risk-on / neutral / stressed)
- Shock / overlay (none / latent / acute)

Four of the five axes are scored on judgment against the inputs below. The Shock / overlay axis additionally carries a written grading rubric — see `### Shock / overlay grading rubric` at the end of this section.

M1a's output is the structured regime scoring — the 5 axis assignments with brief rationale for each, citing the inputs that drove the call. M1a writes ONLY this output to the regime-scoring file (`Monthly_Fundamental_RegimeScore.md` per `Claude_Task_Plan.md`). Underlying inputs and M1a's full reasoning chain are not persisted.

**Inputs to M1a (all must be gathered each month, in this order):**

1. **Macro data releases from the prior month:**
   - CPI headline and core (BLS, initial prints — not revisions): latest, 3-month trend, 12-month trend, prior-cycle analogue for current level if one exists
   - PPI headline (BLS, initial): latest, 3-month, 12-month
   - Non-farm payrolls (BLS establishment survey, initial): latest, 3-month, 12-month
   - Unemployment rate (BLS household survey): latest, 3-month, 12-month, prior-cycle trough-to-peak
   - Retail sales (Census Bureau advance): latest, 3-month, 12-month
   - GDP growth rate (BEA — specify which estimate: advance, second, or third): most recent quarterly print if released during the prior month, 4-quarter trend

2. **Fed/FOMC developments:**
   - Any FOMC meeting in prior month: decision, statement changes, dot-plot updates
   - Fed speeches with market-moving content (cited by reference to originating Fed publication or transcript, not news-media summary)
   - Current fed funds futures implied path (CME FedWatch) vs latest dot plot
   - Dot-plot drift vs realized path over past 12 months

3. **Earnings aggregate status:**
   - If in earnings season: percentage of S&P 500 reported, aggregate EPS beat rate, aggregate sales beat rate, aggregate EPS surprise magnitude (source: FactSet Earnings Insight or equivalent named source)
   - Forward S&P 500 EPS consensus: change over prior month and over prior 12 months

4. **Geopolitical events (structured inclusion criteria):**
   - Include only events affecting ≥1 of: global trade flows; oil price move > $5/bbl; sovereign credit spreads; major currency > 2% move against USD.
   - Other events are excluded regardless of narrative salience (per 2.4).

5. **Policy environment:**
   - Regulatory changes affecting broad sectors (with citation to primary-source regulatory release)
   - Tariff and trade developments (with citation)
   - Major legislation passed or imminent (with citation)

6. **Cross-cycle comparison input:**
   - For current values of unemployment, inflation, fed funds, yield curve, breadth, VIX: identify the closest prior-cycle historical analogue (if any) and summarize what happened in the subsequent 6–18 months in that analogue. If no close analogue exists, state so.
   - Honest scope note: this input is contextual information only. It is produced by the same model it is meant to partially de-bias and therefore does NOT constitute a mitigation against 2.14 (recency bias). Treated as a contextual prompt to surface comparison data, not as a de-biasing mechanism.

Each input is gathered through explicit tool calls (web search, data fetch) to the specific named public sources above. No input is recalled from memory — per 2.3 (hallucination) and 2.5 (training cutoff), every input is verified by live retrieval.

**Fallback protocol for unavailable inputs.** If a primary data source is unavailable at routine run time, M1a documents the specific miss in its output and does NOT substitute a secondary source silently. The regime assessment proceeds with the remaining inputs and explicitly flags which inputs were absent. If ≥2 of the 5 primary input categories (macro / Fed / earnings / geopolitical / policy) are absent — input 6 is compensatory and does not count toward this threshold — the fundamental call for the affected month is DO-NOT-ACTIVATE across all strategies regardless of the partial assessment, and M1b is not run that month (M1a writes a fallback-suppression flag to the regime-scoring file; M1b reads that flag and exits without producing strategy mappings).

### Shock / overlay grading rubric

*Added 2026-09-05 (Rev 48, owner directive).* Until this revision the Shock / overlay axis had a token set and no stated criterion for entering or leaving any of its three values — a scoring could raise the axis on judgment, and nothing in this document said when to lower it again. This rubric supplies the missing anchors. It **constrains judgment; it does not replace it**: a scoring that reads the evidence differently may still deviate from the grade the rubric indicates, but must argue against these anchors explicitly in that axis's rationale rather than around them.

**Qualifying shock event.** A dated development that (i) meets input category 4's structured inclusion criteria above — an effect on global trade flows, an oil price move > $5/bbl attributable to the shock channel, a widening in sovereign credit spreads, or a major currency move > 2% against USD — and (ii) is attributable to a named geopolitical or trade channel. Narrative escalation with no measurable leg, undated commentary, and developments failing category 4's criteria are not qualifying events regardless of salience (per 2.4).

**Pre-shock baseline.** The 60-trading-day median of Brent front-month closes ending the session BEFORE the first qualifying event of the current shock structure — or, when fewer than 60 sessions precede that event, the median of the full available history (the series begins 2026-06-01, so a shock structure older than roughly three months has a shorter window by construction rather than by fault), with the actual observation count N recorded in the rationale alongside the triplet so a short baseline is visible rather than implied. Brent closes are read from `state.signal_marks_curated` (`ticker = 'BZUSD'`), one row per trading day off the same daily signal-marks ingest that captures the rest of the mark set — the CURATED view and never the raw `events.signal_marks` table, per the SOURCE TRAP `bigquery/216` pins for every price series (the raw table carries same-day duplicates from two ingest paths, which shift a computed margin), and the surface `state.rerisking_limb_status` computes the same triplet from; a baseline asserted from memory is not a baseline.

**Shock elevation.** The peak Brent close since that first qualifying event, minus the pre-shock baseline. If the peak never exceeded the baseline the elevation is zero and the price leg is treated as satisfied — a price leg that never lifted has nothing to retrace, and the grade then turns on the event-recency and transmission legs alone.

**Grades.**
- `acute` — EITHER a qualifying event dated within the trailing 15 trading days OR (the shock elevation is positive AND Brent is still at or above baseline + 50% of it); AND transmission is ACTIVE, meaning at least one measurable market leg (Brent, sovereign spreads, FX) is still pricing the named channel.
- `latent` — an unresolved shock STRUCTURE remains (a standing blockade, a tariff regime, an unsettled sanctions posture), but there has been no qualifying event in the trailing 15 trading days AND Brent has retraced below baseline + 50% of shock elevation.
- `none` — no unresolved shock structure and no qualifying event in the trailing 60 trading days.

**De-escalation from `acute` to `latent` is REQUIRED, not optional, once both legs hold.** Downgrade when BOTH are true, each dated and measured in the row rationale: (i) zero new qualifying events for 15 consecutive trading days; and (ii) Brent has retraced at least 50% of the shock elevation, i.e. it now sits at or below the baseline-to-peak midpoint. Either leg failing keeps the grade at `acute`. This is the operative exit the axis previously lacked — an `acute` reading that satisfies both legs and is scored `acute` anyway is a deviation, and is subject to the same obligation to argue against the anchors as any other deviation.

**Escalation is immediate, and the asymmetry is deliberate.** Any qualifying event with active transmission moves the axis to `acute` at the next scoring with no dwell requirement, while the downgrade waits on a 15-trading-day quiet window and a measured retracement. Fast to raise and slow to lower is a choice, not an oversight, and it is stated here so that it stays a choice on the record rather than an artifact of an unwritten exit.

**Rationale-recording duty.** Whatever the grade, that axis's rationale MUST record: (1) the date of the most recent qualifying event; (2) the baseline / peak / current Brent triplet; and (3) which legs held and which failed. This is what makes a grade auditable after the fact, and it is what leaves the next scoring — and any out-of-cycle re-scoring — a dated, measured anchor to move off rather than a re-reading of the same narrative.

**Calibration.** The rubric was checked against this axis's own recorded history before being written down, and reproduces it: 2026-07-01 → `latent` (the June spike's driver had reversed within the month, so the transmission leg fails); 2026-08-01 → `acute`; 2026-09-01 → `acute`. A rubric that re-graded its own history differently would be a new rule dressed as a written-down one, and would need to be argued as such.

