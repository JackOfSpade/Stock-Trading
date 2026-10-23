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

*Rev 52 (2026-10-22, owner directive).* **The rubric is symmetric.** Each leg is read on the scoring date alone against ONE threshold; a shock structure opens and closes on dated events in both directions; a plateau re-base re-measures the baseline when Brent settles on a new level, above or below the old one; and every transition takes effect at the first scoring whose measurement reads the other way. Rev 48's event-recency leg, quiet windows and retracement leg are struck below and kept as record; struck text is not operative.

**Qualifying shock event.** A dated development that (i) meets input category 4's structured inclusion criteria above — an effect on global trade flows, an oil price move > $5/bbl attributable to the shock channel, a widening in sovereign credit spreads, or a major currency move > 2% against USD — and (ii) is attributable to a named geopolitical or trade channel. Narrative escalation with no measurable leg, undated commentary, and developments failing category 4's criteria are not qualifying events regardless of salience (per 2.4).

**Qualifying resolution event (Rev 52, 2026-10-22 — the mirror of a qualifying shock event).** A dated development that (i) meets input category 4's structured criteria in the reverse direction — trade flows restored, an oil price move > $5/bbl DOWN attributable to the channel's resolution, a narrowing in sovereign credit spreads, or a major currency reversing > 2% against USD — and (ii) is attributable to the resolution of the named channel: a ceasefire or settlement in force, a blockade lifted, a tariff regime removed, or a sanctions posture settled. Narrative de-escalation with no measurable leg is not a qualifying resolution, exactly as narrative escalation is not a qualifying event (per 2.4). A price move is read over the same two-session window `Claude_Task_Plan.md` M1a applies to a qualifying shock event's price move.

**Shock structure (Rev 52, 2026-10-22).** The first qualifying shock event opens a structure on its named channel. A qualifying resolution event of that structure's channel closes it. Between those two dated events the structure is open whatever the legs read; the legs below decide only between `acute` and `latent`.

**Pre-shock baseline.** The 60-trading-day median of Brent front-month closes ending the session BEFORE the first qualifying event of the current shock structure — or, when fewer than 60 sessions precede that event, the median of the full available history (the series begins 2026-06-01, so a shock structure older than roughly three months has a shorter window by construction rather than by fault), with the actual observation count N recorded in the rationale alongside the triplet so a short baseline is visible rather than implied. Brent closes are read from `state.signal_marks_curated` (`ticker = 'BZUSD'`), one row per trading day off the same daily signal-marks ingest that captures the rest of the mark set — the CURATED view and never the raw `events.signal_marks` table, per the SOURCE TRAP `bigquery/216` pins for every price series (the raw table carries same-day duplicates from two ingest paths, which shift a computed margin), ~~and the surface `state.rerisking_limb_status` computes the same triplet from~~ **[Rev 52, owner directive, 2026-10-22 — superseded: and the surface `state.shock_price_leg_status` (`bigquery/263`) computes its mechanical proxy from — a proxy, not this rubric: it anchors at the start of the current `acute` run rather than at the first qualifying event, and applies only the plateau re-base's price half (a), so the triplet a scoring records stays authoritative]**; a baseline asserted from memory is not a baseline. *Rev 52:* when a plateau re-base (below) fires, its 10-session median replaces this baseline for the current structure, and a later re-base replaces it in turn.

**Shock elevation.** The peak Brent close since that first qualifying event, minus the pre-shock baseline. ~~If the peak never exceeded the baseline the elevation is zero and the price leg is treated as satisfied — a price leg that never lifted has nothing to retrace, and the grade then turns on the event-recency and transmission legs alone.~~ **[Rev 52, owner directive, 2026-10-22 — superseded: if the peak never exceeded the baseline, the elevation is zero and the price leg reads NOT ELEVATED (Legs, below), so the grade turns on the spread and FX legs. After a plateau re-base the elevation is zero until the next qualifying event; from that event it is the peak close since that event minus the re-based baseline.]**

**Plateau re-base (Rev 52, 2026-10-22 — symmetric).** The re-base fires when BOTH of these hold: (a) all of Brent's trailing 10 trading-day closes, including the scoring session, lie within ±5% of their own median — read from the stored curated `BZUSD` series as recorded, with a front-month roll gap not adjusted; and (b) no qualifying shock event is dated within those 10 sessions. When it fires, the baseline becomes that 10-session median and the shock elevation is set to ZERO, so the price leg reads NOT ELEVATED. The elevation stays zero until the next qualifying event; after that event it is the peak close since that event minus the re-based baseline. The re-base applies whether the plateau sits above or below the prior baseline. It is a re-measurement, not a grade change on its own: the grade still follows from the structure and the legs.

**Legs (Rev 52, 2026-10-22).** Each leg is read on the scoring date alone. Each has ONE threshold, applied identically whichever grade the axis currently holds.
- *Price leg* — ELEVATED ⇔ the shock elevation is greater than zero AND the current Brent close is at or above baseline + 50% of the elevation (the baseline-to-peak midpoint). This one threshold replaces both Rev 48's reading of Brent as "still pricing the named channel" and its 50%-retracement downgrade leg, so raising and lowering cross the same line.
- *Sovereign-spread leg* and *FX leg* — ACTIVE ⇔ measured AND attributed to the named channel against input category 4's thresholds, as the axis already records them. A leg that cannot be measured is NOT active.

**Grades.**
- ~~`acute` — EITHER a qualifying event dated within the trailing 15 trading days OR (the shock elevation is positive AND Brent is still at or above baseline + 50% of it); AND transmission is ACTIVE, meaning at least one measurable market leg (Brent, sovereign spreads, FX) is still pricing the named channel.~~
- ~~`latent` — an unresolved shock STRUCTURE remains (a standing blockade, a tariff regime, an unsettled sanctions posture), but there has been no qualifying event in the trailing 15 trading days AND Brent has retraced below baseline + 50% of shock elevation.~~
- ~~`none` — no unresolved shock structure and no qualifying event in the trailing 60 trading days.~~

**[Rev 52, owner directive, 2026-10-22 — the three Rev 48 grade definitions above are superseded by the three below. Retired with them: the 15-trading-day event-recency leg of `acute` and the 60-trading-day condition for `none`.]**

*Rev 52 (2026-10-22, owner directive):*
- `acute` — a shock structure is open AND at least one leg is ELEVATED or ACTIVE.
- `latent` — a shock structure is open AND no leg is ELEVATED or ACTIVE.
- `none` — no shock structure is open.

A qualifying shock event while the axis reads `none` opens a structure; the grade then follows from the legs read on the scoring date: `acute` if any leg is ELEVATED or ACTIVE, otherwise `latent`.

~~**De-escalation from `acute` to `latent` is REQUIRED, not optional, once both legs hold.** Downgrade when BOTH are true, each dated and measured in the row rationale: (i) zero new qualifying events for 15 consecutive trading days; and (ii) Brent has retraced at least 50% of the shock elevation, i.e. it now sits at or below the baseline-to-peak midpoint. Either leg failing keeps the grade at `acute`. This is the operative exit the axis previously lacked — an `acute` reading that satisfies both legs and is scored `acute` anyway is a deviation, and is subject to the same obligation to argue against the anchors as any other deviation.~~

~~**Escalation is immediate, and the asymmetry is deliberate.** Any qualifying event with active transmission moves the axis to `acute` at the next scoring with no dwell requirement, while the downgrade waits on a 15-trading-day quiet window and a measured retracement. Fast to raise and slow to lower is a choice, not an oversight, and it is stated here so that it stays a choice on the record rather than an artifact of an unwritten exit.~~

**[Rev 52, owner directive, 2026-10-22 — both paragraphs above are superseded by the symmetry statement below. Retired with them: the 15-quiet-day + 50%-retrace downgrade requirement.]**

*Rev 52 (2026-10-22, owner directive).* **Every transition is symmetric, and every transition is REQUIRED.** Every transition, in either direction, uses the same test above and takes effect at the first scoring — M1a monthly, or M1R out-of-cycle — whose measurement reads the other way. There is no dwell, quiet period or confirmation window in either direction. A scoring whose measurement indicates one grade and that scores another anyway is a deviation in whichever direction it errs, and carries the same obligation to argue against these anchors as any other deviation.

**Incomplete evidence is symmetric too (Rev 52, 2026-10-22).** If a scoring cannot complete the event sweep that a leg or a re-base needs, the axis keeps its STANDING value, whatever that value is. It does not default to `acute`, and it does not default to a lower grade.

**Rationale-recording duty.** Whatever the grade, that axis's rationale MUST record: (1) the date of the most recent qualifying event; (2) the baseline / peak / current Brent triplet; and (3) which legs held and which failed. **[Rev 52, owner directive, 2026-10-22 — extended:]** (4) any plateau re-base — its 10-session window, its median and N — and, where a structure closed, the date of the qualifying resolution event that closed it. This is what makes a grade auditable after the fact, and it is what leaves the next scoring — and any out-of-cycle re-scoring — a dated, measured anchor to move off rather than a re-reading of the same narrative.

**Calibration.** ~~The rubric was checked against this axis's own recorded history before being written down, and reproduces it: 2026-07-01 → `latent` (the June spike's driver had reversed within the month, so the transmission leg fails); 2026-08-01 → `acute`; 2026-09-01 → `acute`. A rubric that re-graded its own history differently would be a new rule dressed as a written-down one, and would need to be argued as such.~~ **[Rev 52, owner directive, 2026-10-22 — superseded as a description of the operative rubric: that calibration was of the Rev 48 rubric, which it reproduced.]** *Rev 52 (2026-10-22, owner directive).* Rev 48's own calibration clause says a rubric that re-grades history differently is a new rule that must be argued as one. Rev 52 IS a new rule, argued by the owner directive that adopted it. It is not claimed to reproduce the axis's history, and no previously scored grade is re-graded: the revisable-series rule (`Claude_Task_Plan.md` M1a — the triplet recorded at scoring time anchors the verdict, and a later restatement never re-grades a scored date) still applies. The adoption-day measurement is recorded in the Rev 52 changelog, not in this rubric, so a scoring is never handed a triplet it did not measure.

