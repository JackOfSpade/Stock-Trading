<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Regime scoring (strategy-blind, monthly)

The **M1a** routine — strategy-blind monthly regime scoring. It produces a scored assessment across five regime-condition axes from public macro/policy/earnings inputs, with **no reference to any strategy** (no strategy letter, activation rule, or mechanism). The per-strategy mapping that consumes this scoring — the **M1b** routine, its reconciliation rules that name specific strategies, the output format, and the divergence-review path — lives in `## Regime router` above; M1a is blinded from all of it. This is a **distinct top-level section** so the generated `strategy/` slice for M1a carries the scoring inputs WITHOUT the strategy-naming mapping, making M1a's blinding a hard file boundary rather than a discipline-only rule (see `Claude_Task_Plan.md` "Strategy reading" + `ops/RUNBOOK.md` §9).

*M1a routine (strategy-blind regime scoring).* Fresh routine context. Given the 6 input categories below, produces a scored assessment across five regime condition axes without any reference to strategies A–E, their activation rules, or their mechanisms. No mention of the word "strategy" or any of the five strategy letters in this routine's prompt or input material:
- Growth momentum (accelerating / stable / decelerating)
- Inflation trend (disinflationary / stable / reaccelerating)
- Policy stance (dovish / neutral / hawkish)
- Risk sentiment (complacent / normal / stressed)
- Shock / overlay (none / contained / acute)

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

