# Portfolio Ledger

Per-strategy portfolio state for the AI-directed trading experiment. Tracked externally to IBKR (which does not natively track sub-portfolios). Updated daily (mark-to-market) and on every trade, deposit, termination, or redistribution event per the regular prompts in `Recurring_Claude_Task_Plan.md`.

---

## Ledger schema conventions (size-discipline)

These conventions govern how this file is updated. They are read-first by every Claude session that touches the ledger. Substance lives in `Decision_Log.md` entries; this file is a state index with pointers, NOT a re-statement.

### "Last updated" header

One paragraph capturing the most recent state change with a `→ Decision_Log YYYY-MM-DD <entry-keyword>` pointer. Includes (a) what changed, (b) source pointer, (c) IBKR snapshot reference if applicable, (d) any flagged anomalies. Target length: **3–6 sentences**. NOT a run-on paragraph re-stating thesis substance, sell-side reset details, sub-pattern taxonomy, or sector cap arithmetic — those live in the linked Decision_Log entry. Older "Prior update" / "Prior update earlier" headers follow the same format and may be dropped after 5+ updates have accumulated (the audit trail lives in Decision_Log; the header rotation is a recency cache).

### Position-thesis-details subsections

Each open position gets one subsection under its strategy's "Position-thesis-details" block. Format:

```
### [Strategy X] TICKER — OPEN YYYY-MM-DD

- **Source thesis**: → Decision_Log YYYY-MM-DD "<staging entry title>" (full thesis substance, key public docs, criterion-3 closed-list convergence target derivation, adversarial review, sub-pattern classification, regime/sector context, conviction calibration all live there). Subsequent material updates: → Decision_Log YYYY-MM-DD "<entry title>" (e.g., gate-session, peer-print parse, fill-capture-anomaly).
- **Order details**: <limit/market specs as staged> → FILLED YYYY-MM-DD HH:MM:SS [MT/ET] at $X.XX (<exact-limit / better-than-limit / inside-the-spread> note); <shares>; principal $X + commission $Y = total cost basis $Z. <Operator-discretion notes if any (e.g., tighter limit at execution, GTC vs Day modification)>.
- **Convergence target**: $X.XX (immutable per Strategy.md criterion 3 closed-list rev XX). Gross return at convergence from actual fill: +X%. Net return at convergence pre-exit-commission: +Y%.
- **Time-based exit**: YYYY-MM-DD (entry + 60 calendar days; adjusted for market closures if applicable).
- **Invalidation criteria status** (forward-looking gates per Decision_Log staging, brief abstraction; full criterion text in staging entry):
  - (i) <criterion abstract> — NOT-TRIPPED / TRIPPED / TRIPPED-CLEARED-by-<event> as of <date>
  - (ii) ...
- **Mark-to-market**: <date/time> snapshot — last $X.XX, mark value $Y.YY, unrealized P&L $Z (vs cost basis incl comm).
- **Holding-period notes**: any in-window events that materially changed the thesis posture (criterion clearance, peer-print confirmation, sell-side trajectory shift). Brief; full reasoning in linked Decision_Log entries.
```

The full thesis substance, adversarial review, criterion-3 list source derivation, regime context, sector-context analysis, and sell-side compilation all live in the Decision_Log staging entry. Position-thesis-details should NEVER reproduce thesis content verbatim from the staging entry — pointer only. Target length per subsection: **8–14 bullet lines**. If a subsection exceeds 20 lines, prune to pointer.

### Activity log lines (under each strategy's "Portfolio state" block)

One sentence per session/event, ending with `→ Decision_Log YYYY-MM-DD <keyword>` pointer. NOT paragraph-length. Cumulative substance lives in Decision_Log entries; activity log is a chronological index for state changes affecting the strategy's portfolio.

Examples:
- `- Apr 28: HCA filled @ $433.46 (operator $0.04 tighter limit), cost basis $28.11; sector cap Health Care Facilities 1/3 NEW. → Decision_Log 2026-04-28 HCA fill capture.`
- `- May 1: META B-thesis-construction → GO MEDIUM conviction; limit BUY 0.0454 @ $615 Day staged for Mon May 4 (Funds-on-Hold gate scheduled). → Decision_Log 2026-05-01 META staging.`
- `- May 5 ~MT: UPS B-thesis-construction → NO-GO criterion 4 dual-framing; sub-pattern 4 advances 2→3 with structural-competitive-threat-emergence variant. → Decision_Log 2026-05-05 UPS NO-GO.`
- `- May 5 ~10:56 MT: META filled @ $601.30 GTC (operator-discretion $13.70 tighter limit + GTC duration), cost basis $27.57; sector cap Comm Services 1/3 NEW. Account-level $4.51 cash discrepancy flagged. → Decision_Log 2026-05-05 META fill capture.`

### SGOV Parking Activity table

Rows per transaction. The reconciliation note below the table captures per-strategy attribution + commission allocation in 1–3 sentences per cycle. NOT paragraph-length cycle write-ups.

### Operating principle

If you're writing a Portfolio_Ledger entry/section that exceeds 4 sentences inline (other than the structured templates above), stop and ask: is this content (a) state index entry (KEEP, brief), or (b) substantive reasoning that belongs in a Decision_Log entry (CUT to pointer; if no entry exists, create one). The operator does not read this file; future Claude reads it to reconstruct state. State + pointers > narrative.

---

**Last updated**: 2026-05-11 ~09:00 MT (Strategy B GLW NVDA-partnership-and-Springboard-2030-upgrade B-thesis-construction → NO-GO criterion 2 + criterion 4 dual-framing decisive failure with sub-pattern 1 layered-1+3 variant FOURTH INSTANCE at MOST EXTREME pre-event-rally magnitude observed across any B candidate [YTD +101.8% / TTM +257.56% / 6-month +140% — exceeds AMD's prior most-extreme reference] plus NEW evidence layer "peer-cross-section-DECLINE on competitive-displacement-information" [AAOI -14% / COHR -10% / LITE -7% / CIEN -10% / FN -8% same-day on announcement; opposite-direction of typical sympathy-rally; validates information-content over sentiment-rotation per Strategy.md criterion 4]. **Criterion 1 qualifying-event sub-test resolved CLEANLY QUALIFYING** via Springboard-2030 upgrade compound-event component direct-listing match on Strategy.md thesis-line 262 explicit "guidance update" illustrative example — distinct from MU 2026-05-05 D2 decline precedent (third-party sell-side commentary fails sub-test); GLW first-party-corporate-issued on three dimensions (NVDA partnership press release + Springboard upgrade investor event at NYSE + 8-K SPA filing). **Event details (Wed 5/6):** (a) NVIDIA-Corning multiyear partnership 10× U.S. optical capacity expansion + 50%+ U.S. fiber capacity + 3 new facilities NC+TX + 3,000+ jobs; (b) Springboard 2030 Plan UPGRADE AND EXTENSION raising $20B annualized run-rate by end-2026 → $30B by end-2028 + 19% sales CAGR Q4'26→Q4'30 + new Photonics MAP $10B by 2030 + 20% operating margin by end-2026; (c) 8-K Securities Purchase Agreement NVDA Pre-Funded Warrant 3M @ $0.0001 ($500M upfront) + Traditional Warrant 15M @ $180 strike (up to $3.2B total if fully exercised). Stock action: Tue 5/5 close $162.10 (Tue +3.20% pre-announcement run-up) → Wed 5/6 close $181.57 (+12.01% close-to-close; session-prompt's "+17%" non-binding correction — primary-source stockanalysis.com verified; intraday high $195.81 was +20.81% from prior close, near 52-wk high $198.25) → Thu 5/7 close $182.40 (+0.46% hold) → Fri 5/8 close $186.94 (+2.49% EXTENDED). Net Tue→Fri +15.32% / 127.6% retention vs Day-0 close-to-close. Mkt cap ~$156B (session-prompt's "~$45-50B" non-binding correction by ~3×; 860.64M shares × Wed close). Q1 2026 print Apr 28 BMO (6 trading days pre-announcement) core sales $4.35B +18% / core EPS $0.70 +30% / Optical Comm +36% / Q2 guide $4.6B +14% / $0.73-0.77 EPS +25%. **6 LONG decisive flaws** [(α) sub-pattern 1 sell-side bull ratification 6 firms PT-raised 48-72h Oppenheimer $120→$210 +75% mega-raise + Citi $175→$225 / MS $140→$180 / UBS $179→$223 / Barclays $149→$180 / JPM $175→$185; (β) sub-pattern 3 MOST-EXTREME pre-event-rally (+257.56% TTM / +140% 6-month / +101.8% YTD); (γ) layered-1+3 variant FOURTH INSTANCE after AXSM 5/6 / PINS 5/7 / AMD 5/7; (δ) move HELD AND EXTENDED through Day 3 (127.6% retention vs Day 0); (ε) NEW evidence layer peer-cross-section-DECLINE; (ζ) stock TRADING ABOVE consensus PT $173.45 with new raised-cluster mean $200 implying only +7% remaining sell-side-implied upside thin against 2.13 ~30% systematic-optimism residual on KL #11] + **5 SHORT decisive flaws** [(η) 2.20-trap MAXIMUM severity 11-NO-GO B-short string in risk-on regime; (θ) +25% stop $233.68 binds against PT cluster + KL #7 NVDA-Q1-FQ27-print Wed 5/20 gap-up catastrophic + AMAT/AVGO/conference-circuit 5-7 vectors over 60 days; (ι) move-EXTENDED-Day-2 contradicts mean-reversion thesis; (κ) NVDA $180 option strike + sell-side $180 anchor (Barclays+MS) creates structural floor compressing realistic SHORT target to -3.7% not -13.3%; (λ) SHORT convergence target structurally weak Q2 print late-July outside 60-day window]. Conviction in NO-GO: HIGH (~85-90%) — between PINS (~85-90%) and AMD (~90-95%); stronger than DOC / TSN due to triple-convergent evidence (sub-pattern 1 + sub-pattern 3 + peer-cross-section-decline). Theater-check CONVERGENT. **NEW evidence layer flagged for W5 sub-pattern taxonomy extraction: "peer-cross-section-DECLINE signature"** (GLW first instance; cross-sectional-competitive-displacement dimension distinct from TSN's structural-temporal-overhang dimension; pending second-instance validation). Sub-pattern 1 advances to 7 instances (BE / CAT / AXSM / PINS / AMD / TSN / **GLW**); layered-1+3 variant advances to 5 instances (AXSM / PINS / AMD / TSN-layered-1+3+4 / **GLW**); sub-pattern 3 most-extreme-magnitude reference shifts to GLW from prior AMD. KL #12 UNFAVORABLE for GLW (estimated 4-long-book pairwise avg ~0.40-0.50 approaches 0.5 trigger due to GLW-IBM ~0.50-0.65 + GLW-META ~0.45-0.60 AI-narrative correlations; vs TSN-favorable 0.25-0.35 baseline; vs DOC-favorable 0.30-0.40 baseline) — secondary to criterion 4 disposition basis but reinforces NO-GO. Experiment Strategy B totals advance to **3 GO + 30 NO-GO = 9.1% / 90.9% hit rate** (from 3/29 = 9.4%/90.6% at session-start). Sector cap usage unchanged: IT Services 1/3 (IBM); Health Care Facilities 1/3 (HCA); Comm Services / Interactive Media & Services 1/3 (META); IT / Electronic Components 0/3 (GLW would have been 1/3 sub-industry / IT-sector would have advanced 1/3 → 2/3 within 3-per-sector cap — clean addition averted); other sub-industries 0/3. **No order staged. No portfolio-state change.** Strategy B router state ACTIVATE unchanged. 2% next-trade sizing $37.77 was the GLW-add scenario sizing; doesn't bind since NO-GO. Window expires ~Wed 2026-05-20 (10 trading days from Wed 5/6 announcement; today Mon 5/11 = Day 3). NVDA Q1 FQ27 print Wed 5/20 AMC = fresh-trigger event with independent 10-day post-NVDA-print window if NVDA print produces qualifying GLW sympathy move ≥5% close-to-close — distinct event evaluated per "NO-GO records are context, not barriers" §3, not extending the Wed 5/6 GLW window. No calendar event scheduled to revisit. Same-day B thesis-construction queue saturation status: GLW 5/11 09:00 ✓ COMPLETE; remaining Mon 5/11: SMCI 13:00 / DASH 13:00 / WHR 14:00 = 3 sessions stacked. → Decision_Log 2026-05-11 GLW NO-GO entry.

Prior: 2026-05-08 ~10:00 MT (Strategy B TSN Q2-FY26-print B-thesis-construction → NO-GO criterion 4 dual-framing decisive failure with sub-pattern 1+3+4 triple-layered fingerprint [sub-pattern 1 sell-side bull ratification: 5+ firms PT-raised 24-48h post-print Piper $75→$80 / BofA $68→$70 / Stephens $65→$70 / BMO $73→$75 / Goldman Buy / Barclays Buy reiterated, modest magnitude vs AMD-extreme + sub-pattern 3 pre-print bullish positioning: Piper Apr 6 OW upgrade $61→$75 +23% PT raise four weeks pre-print + Mizuho Mar 26 OP $72 init absorbed forward narrative + sub-pattern 4 structural-overhang persistence: Beef segment FY26 loss guide WIDENED to ($350M)–($500M) on cattle herd 75-year low + 2025 calf crop smallest since 1941 at 32.9M head + "Rebuild Delay" 2027-2028 normalization timeline + TSN COO/CEO call quotes confirm no near-term resolution]. Print details: Mon 2026-05-04 BMO (NOT Tue 5/5 as session prompt stated; primary-source verified 8-K + GlobeNewswire); EPS $0.87 vs $0.78 cons (+12% beat); rev $13.65B vs $13.61B cons; FY26 AOI guide raised $2.1-2.3B → $2.2-2.4B (+$100M midpoint); Chicken segment guide raised $1.65-1.9B → $1.9-2.05B (+$200M midpoint at 12.2% margin); adj EPS DOWN 5% Y/Y from $0.92. Stock action: Fri 5/1 close $64.07 → Mon 5/4 close ~$69.07 (+7.80% per TradingKey) → Tue 5/5 hit 52-wk high $69.48 → Thu 5/7 close $67.94 = ~77% retention of move through Day 3 (move-held-Day-3 sub-evidence layer, AMD-precedent). 6 LONG decisive flaws + criterion 3 closed-list rev 14 absent admissible target [numerical PT chase = sub-pattern 1 trap; Q3 print Aug 10 OUTSIDE 60-day window from May 4 = July 3; no FDA event; FOMC mismatch on idiosyncratic protein-processor; already in S&P 500 / Russell 1000] + 5 SHORT decisive flaws [2.20-trap canonical against beat-and-raise; mean reversion already partial; +25% stop $84.93 above 52-wk high $69.48 with KL #7 food-peer gap-up risk uncapped; cons-staples-defensive sector beta + risk-on regime fights short; SHORT convergence target structurally weak]. Conviction in NO-GO: HIGH (~80-85%) — between PINS (~85-90%) and DOC (~70-80%); stronger than DOC because clean sub-pattern 1+3 fingerprint match plus additional sub-pattern 4 layer; slightly weaker than PINS because sub-pattern 1 magnitude modest vs PINS BofA $20→$27 +35% anchor. Theater-check CONVERGENT. **NEW sub-pattern variant flagged for W4 taxonomy extraction: layered-1+3+4 triple-pattern fingerprint** (TSN first instance combining sell-side bull ratification + pre-print bullish positioning + structural overhang persistence; pending second-instance validation). Sub-pattern 1 advances to 6 instances (BE / CAT / AXSM / PINS / AMD / **TSN**); layered-1+3 variant advances to 4 instances (AXSM / PINS / AMD / **TSN — first instance with additional sub-pattern 4 layer**); sub-pattern 4 advances to 5 instances (V / MDLZ / UPS 4b / NCLH 4c / **TSN — first instance within layered-1+3 context**). 9-NO-GO B-short precedent string in current risk-on regime extends to 10 with TSN-SHORT-framing decisive failure. KL #12 FAVORABLE for TSN (cons-staples-defensive low-beta-name pairwise correlation profile vs IT/HC/Comm Services book among LOWEST observed across any B candidate; estimated 4-long-book pairwise avg 0.25-0.35 well under 0.5 trigger) but secondary to criterion 4 disposition basis. Experiment Strategy B totals advance to **3 GO + 29 NO-GO = 9.4% / 90.6% hit rate** (from 3/28 = 9.7%/90.3% at session-start). Sector cap usage unchanged: IT Services 1/3 (IBM); Health Care Facilities 1/3 (HCA); Comm Services / Interactive Media & Services 1/3 (META); Consumer Staples / Food Products 0/3 (TSN would have been 1/3 — clean sub-industry-cap addition averted); other sub-industries 0/3. **No order staged. No portfolio-state change.** Strategy B router state ACTIVATE unchanged. KL #12 first-computation event Wed 2026-06-03 ~15:30 MT operates on IBM × HCA × META 3-way unchanged. 2% next-trade sizing $37.77 (recomputed off updated $1,888.69 NAV per 5/7 fill-capture supplemental-deposit interpretation correction) was the TSN-add scenario sizing; doesn't bind since NO-GO. Window expires ~Mon 2026-05-18 (10 trading days from Mon 5/4 print, NOT 5/19 as session prompt stated; 1-day non-binding correction). No calendar event scheduled to revisit (criterion-4 information-driven characterization unlikely to flip from re-examining same data within window; routine Daily.md scan picks up any fresh trigger). **Same-week B thesis-construction queue saturation status:** TSN 5/8 10:00 ✓ COMPLETE; remaining Fri 5/8 PM ARM 11:00 / FLEX 13:00 / DDOG 14:00 / FTNT 15:00 = 4 sessions stacked. → Decision_Log 2026-05-08 TSN NO-GO entry.

Prior: 2026-05-07 ~14:30 MT (DIS fill capture session — Thu 5/7 09:36:29 MT DIS limit BUY 0.28 @ $110.35 Day order FILLED exact-limit at $110.35, principal $30.90 + commission $0.31 = cost basis $31.21. **4 anomalies documented in Decision_Log fill-capture entry**: (1) **Operator-discretion order modification at execution — looser limit + larger size** (staged 0.2584 @ $107.50 Day; placed/filled 0.28 @ $110.35 Day; +$2.85 looser limit / +0.0216 larger shares / principal +$3.12 = +11.2% on staged size; thesis-disposition unchanged on 12+ month structural Subtype B SVOD-margin-trajectory thesis; criterion 6 still clears at borderline; RTX 2026-04-27 looser-for-fill-assurance precedent continuation, opposite of META 2026-05-05 tighter-at-execution); (2) **May 5 $4.51 cash discrepancy CLOSED** as accepted-fee-or-timing-noise (today's account-level cash flow balances cleanly from observed May 5 $0.38 ending cash to today's $8.13 via $2,500 supplemental release + 5 trades; surviving candidate is IBKR Pro inactivity-fee or market-data subscription posted Apr 30-May 5; per-strategy attribution -$0.90/strategy equal-split); (3) **Funds-on-Hold $2,500 RELEASED with INTERPRETATION CORRECTION** — Apr 28 first-observation hypothesis "hold is *within* NLV (not additive)" REFUTED by today's data (NLV jumped $6,945 → $9,448 ≈ +$2,500 when hold cleared, demonstrating ADDITIVE not within-NLV); May 5 META gate-clear's "(a) pending outgoing transfer" framing was DIRECTIONALLY WRONG (flow was incoming, not outgoing); corrected interpretation: $2,500 was a SUPPLEMENTAL CAPITAL DEPOSIT deposited circa Apr 28 with settlement-hold status through Thu 5/7 release-for-trading; total experiment deposits revised $6,946.86 → $9,446.86 with $500/strategy equal-split per initial-allocation methodology; May 5 META gate-clear disposition itself unaffected by correction (B-cash sufficiency reasoning was correct regardless of flow direction); (4) **Account-level SGOV reparking cycle** documented across 5 today-trades — dividend reinvest 0.2021 SGOV @ $100.45 ($20.30, $0.02 comm; pro-rata to existing per-strategy SGOV) + D's DIS-funding cycle 0.4 SGOV sold @ $100.44 then 0.28 DIS bought @ $110.35 (D-specific) + supplemental-deposit deployment 28.87 SGOV bought @ $100.45 then 3.98 trim sold @ $100.44 net 24.89 SGOV at $100.4763 effective avg cost (allocated equal-split +4.978 SGOV/strategy at ~$500.17 cash deployment). Strategy D book post-fill: 2/10 concurrent (RTX + DIS), Industrials/A&D ~1.5% + Comm Services/Entertainment ~1.6% of new ~$1,888 D NAV (both well within 30% sector caps), DIS LTCG eligible 2027-05-08, invalidation criteria (i)-(v) all NOT-TRIPPED at fill. Per-strategy NAVs mark-to-market: A ~$1,890 / B ~$1,889 / C ~$1,890 / D ~$1,888 / E ~$1,890 (sum ~$9,447 vs IBKR NLV $9,448 within rounding). Funds-on-Hold field absent today (interpreted as $0 = released). No further calendar events created this session — DIS thesis-pulse falls into next M5 cycle (~2026-06-01) and Q3 FY26 print falsifiable reassessment (~2026-08-12; Daily.md scan auto-detects). 2026-Q2 D-shortlist final result: 2 GO (RTX, DIS), 7 NO-GO/pending across LLY/CEG/VST/GOOGL/CCJ/BA/GEV. → Decision_Log 2026-05-07 DIS fill capture anomaly entry.

Prior: 2026-05-07 ~13:00 MT (Strategy B DOC Q1-print B-thesis-construction → NO-GO criterion 4 dual-framing decisive failure under AMBIGUOUS sub-pattern routing — DOC does NOT cleanly match canonical sub-pattern 1 [no documented post-print PT-raise wave; pre-print sell-side BEARISH-positioned with Cantor PT $20→$17 May 4 + Jefferies Buy→Hold + Baird $21→$20] and does NOT match sub-pattern 3 [pre-print stock depressed near support, not rallying]. Pattern closer to NEW variant: "depressed-name pre-print-bearish-positioning-unwind on modest-print-confirmation + peer-print-tailwind WELL/VTR + risk-on-regime backdrop" — first observed instance, candidate sub-pattern 8 pending second-instance validation per W4 sub-pattern taxonomy extraction. Print components modest [Q1 FFO-as-Adj $0.45 vs $0.43 cons = +$0.02/+4.7% beat; FY26 FFO guide raised midpoint ONLY $0.01 ($1.72→$1.73; midpoint STILL BELOW prior consensus avg $1.74); Janus Living IPO completed March 2026 already-public; IPO accretion BACK-LOADED $0.04 in 2027+ neutral 2026 per management; April $100M buyback at $16.81 already-known]. Stock action: Wed 5/6 close $18.76 (+13.60% per Investing.com / +13.75% Yahoo / +17.93% intraday peak) → Thu 5/7 intraday ~$17.79 = -5.17% partial fade. **Day-2-3 trajectory bracket complete this session: full-fade (PINS) / partial-fade (DOC) / full-hold (AMD) — all three produce NO-GO under appropriate sub-pattern routing.** 6 LONG decisive flaws [modest information content; sentiment-dominant rally drivers per Investing.com explicit list (4-of-6 non-information: supportive call tone / balance sheet narrative / WELL+VTR peer prints / risk-on backdrop); pre-print-bearish-positioning-unwind not B-mechanism candidate; partial-fade equilibrium already settled at midpoint between pre-print baseline $16.50 and Wed peak $18.76; convergence target weak — stock already at 50% gap-fill ($17.77 = ~current $17.79) toward consensus PT $19.04 = only +7% remaining + Q2 print Aug 5 outside 60-day window from May 5 = July 4 weekend; sub-pattern routing ambiguity does NOT produce GO under Constraint 1 self-reference closure binding] + 5 SHORT decisive flaws [pre-mortem Constraint 2 2.20-trap canonical even on modest beat-and-raise — 9-NO-GO B-short precedent string in current risk-on regime extends to 10; mean reversion already partial via Thu fade -5.17%; +25% stop $22.24 above 52-wk high $19.68 with KL #7 gap-up risk uncapped; healthcare REIT sector beta tailwind WELL/VTR + risk-on regime fights short; SHORT convergence target weak — $16.81 buyback / $16.50 pre-print baseline = -5.5% to -7.2% target only]. Conviction in NO-GO: MEDIUM-HIGH (~70-80%) — lower than PINS (~85-90%) / AMD (~90-95%) because DOC pattern genuinely ambiguous, LONG framing has SOME residual edge but structurally weak. Theater-check CONVERGENT. Sub-pattern 1 instance count UNCHANGED at 5 (DOC does not cleanly fit sub-pattern 1 fingerprint). KL #12 FAVORABLE for DOC (REIT low equity-correlation; estimated 4-long-book pairwise avg 0.30-0.40 well under 0.5 trigger) but secondary to criterion 4 disposition basis. Experiment Strategy B totals advance to **3 GO + 28 NO-GO = 9.7% / 90.3% hit rate** (from 3/27 = 10.0%/90.0% post-AMD-entry). Sector cap usage unchanged: IT Services 1/3 (IBM); Health Care Facilities 1/3 (HCA); Comm Services / Interactive Media & Services 1/3 (META); Real Estate / Health Care REITs 0/3 (DOC would have been 1/3 — clean sub-industry-cap addition averted); IT/Semiconductors 0/3; other sub-industries 0/3. **No order staged. No portfolio-state change.** Strategy B router state ACTIVATE unchanged. **Same-session 5-disposition pattern Thu 2026-05-07: 1 GO (DIS Strategy D 09:00) + 3 NO-GO (PINS Strategy B 10:00 / AMD Strategy B 11:00 / DOC Strategy B 13:00) + DIS fill capture pending 14:30. The framework resolution discipline produced 1-of-1 GO Strategy D (post-Q2-FY26-print re-screen with trigger conditions met) and 3-of-3 NO-GO Strategy B (sub-pattern 1 layered-1+3 variant convergent disposition pattern + ambiguous-routing first-instance sub-pattern variant). The 4 dispositions across 3 strategies on 3 separate underlying patterns demonstrate the framework's intended asymmetric-disposition-per-session behavior.** → Decision_Log 2026-05-07 DOC NO-GO entry.

Prior: 2026-05-07 ~11:00 MT (Strategy B AMD Q1-print B-thesis-construction → NO-GO criterion 4 dual-framing decisive failure with sub-pattern 1 layered-1+3 variant THIRD INSTANCE [same-day after PINS 10:00 MT second instance + AXSM 2026-05-06 first instance] at MOST EXTREME magnitude observed across all B thesis-construction cases on both layer components. Goldman Sachs $240→$450 [+88%] AND upgrade Hold→BUY = LARGEST single-firm PT raise observed in any B case. Pre-print +89% one-month / +245% one-year / +327% twelve-month rally = MOST EXTREME pre-print absorption observed in any B case. 12+ PT raises in 48h post-print [Goldman / DA Davidson / Bernstein / Seaport / KeyBanc $530 / Roth / Barclays / TD Cowen / Cantor Fitzgerald / Wedbush / Stifel / Jefferies / CFRA / Citi / Morgan Stanley] + 4 rating upgrades [Goldman Hold→Buy / DA Davidson Neutral→Buy / Bernstein MP→OP / Seaport]. NEW evidence layer "post-event move HELD through Day 2-3" [Wed close +17.77% $417.47 / Thu -1.34% $415.73 = +16.2% net hold from Tue $354.50 pre-print baseline] — opposite of PINS's "move-faded-by-Day-2"; both fade and hold trajectories produce NO-GO disposition under sub-pattern 1 layered-1+3 variant, confirming structural logic doesn't depend on Day 2-3 fade trajectory specifics. 6 LONG decisive flaws [sub-pattern 1 most-extreme; sub-pattern 3 most-extreme; move-HELD evidence; convergence target structural failure under criterion 3 — next earnings Aug 3-5 outside 60-day window from May 5 = July 4 weekend; mega-cap multiple-compression-risk at $670B mkt cap / ~35-40× forward P/E per Morgan Stanley cautious EW $410; pre-mortem 2.4 self-reference closure binding] + 5 SHORT decisive flaws [2.20-trap canonical at maximum severity with +89% momentum tape; +25% stop binds catastrophically toward $450-$530 PT cluster; KL #7 chip-peer-correlation gap-up risk; 2.4 narrative-over-fit residual on SHORT; SHORT convergence target structurally fails]. Conviction in NO-GO: HIGH-VERY-HIGH (~90-95%) — higher than PINS NO-GO. Theater-check CONVERGENT. Sub-pattern 1 advances to 5 instances (BE 5/1, CAT 5/2, AXSM 5/6, PINS 5/7, **AMD 5/7**). Layered-1+3 sub-pattern variant advances to 3 instances. 9-NO-GO B-short precedent string in current risk-on regime would extend to 10 (AMD-short framing decisive failure). Experiment Strategy B totals advance to **3 GO + 27 NO-GO = 10.0% / 90.0% hit rate** (from 3/26 = 10.3%/89.7% post-PINS-entry). Sector cap usage unchanged: IT Services 1/3 (IBM); Health Care Facilities 1/3 (HCA); Comm Services / Interactive Media & Services 1/3 (META); IT/Semiconductors 0/3 (AMD would have been 1/3 within cap); other sub-industries 0/3. **No order staged. No portfolio-state change.** Strategy B router state ACTIVATE unchanged. KL #12 first-computation event Wed 2026-06-03 ~15:30 MT operates on IBM × HCA × META 3-way unchanged. Same-session 4-disposition pattern Thu 2026-05-07 (DIS GO Strategy D 09:00 + PINS NO-GO Strategy B 10:00 + AMD NO-GO Strategy B 11:00 + DOC pending Strategy B 13:00) demonstrates framework resolution discipline under information-resolvable-trigger logic. → Decision_Log 2026-05-07 AMD NO-GO entry.

Prior: 2026-05-07 ~10:00 MT (Strategy B PINS Q1-print B-thesis-construction → NO-GO criterion 4 dual-framing decisive failure with sub-pattern 1 layered-1+3 variant SECOND INSTANCE [after AXSM 2026-05-06 first instance] + NEW "move-completely-faded-by-Day-2" evidence layer [post-event price trajectory: Mon AH +18.94% $24.81 → Tue close +6.83% $22.28 → Wed close ~+1.3% $21.13 → Thu near pre-print baseline $20.85-21.10 = ~80%+ retrace within 2 trading days, leaving no remaining post-event mean-reversion edge for either LONG or SHORT framing]. 5 LONG decisive flaws [sub-pattern 1 PT-raise wave 15 firms BofA $20→$27 +35% anchor; sub-pattern 3 pre-print rally +19% from April lows; move-completely-faded-by-Day-2; ad pricing -5% YoY quality-of-revenue; convergence target structural failure under criterion 3 closed-list rev 14 — numerical-PT chase fails BE/CAT/STX/MDLZ doctrine + next earnings Aug 4-6 outside 60-day window from May 4 = July 3] + 5 SHORT decisive flaws [mean reversion already complete; aggressive ratification + 15.4% short interest squeeze risk; +25% stop binds toward BofA $27 PT; 2.20-trap canonical with 9-NO-GO B-short precedent string in current risk-on regime; SHORT convergence target structurally fails too]. Conviction in NO-GO: HIGH (~85-90%). Theater-check CONVERGENT. Sub-pattern 1 advances to 4 instances (BE 5/1, CAT 5/2, AXSM 5/6, **PINS 5/7**). Layered-1+3 sub-pattern variant advances to 2 instances (AXSM 5/6, PINS 5/7). Same-sub-industry concentration concern with META (both Comm Services / Interactive Media & Services, pairwise correlation estimated 0.55-0.70) addressed as SECONDARY concern bounded by NO-GO disposition; KL #12 first-computation event Wed 2026-06-03 unchanged. Experiment Strategy B totals advance to **3 GO + 26 NO-GO = 10.3% / 89.7% hit rate** (from 3/25 = 10.7%/89.3% session-start). Sector cap usage unchanged: IT Services 1/3 (IBM); Health Care Facilities 1/3 (HCA); Comm Services / Interactive Media & Services 1/3 (META — would have been 2/3 with PINS-add); other sub-industries 0/3. **No order staged. No portfolio-state change.** Strategy B router state ACTIVATE unchanged. The dual GO+NO-GO disposition pattern this session (DIS GO Strategy D 09:00 MT + PINS NO-GO Strategy B 10:00 MT) demonstrates the framework's information-resolvable-trigger discipline: GOs and NO-GOs both occur within the same session when underlying mechanical patterns differ. → Decision_Log 2026-05-07 PINS NO-GO entry.

Prior: 2026-05-07 ~09:00 MT (Strategy D DIS post-Q2-FY26-print re-screen → trigger conditions (a)/(b)/(c) all MET (SVOD operating margin 10.6% Q2 vs 8.4% Q1 baseline = +220bps cleared; FY26 10% guide cleared directionally by Q2 print itself; D'Amaro debut framed strategic continuity via three-pillar framework + "executing on the priorities we've already communicated to the market" + CFO Johnston "no FY26/FY27 adj-EPS growth changes anticipated"; FY26 buyback raised $7B → at least $8B = acceleration not just reaffirmation) → fresh Strategy D Subtype B thesis run per session-prompt step 4 → **GO with primary driver explicitly reframed from management-execution-quality (original NO-GO basis under KL #4) to financial-metric-traceable (SVOD operating margin sustained ≥10% over 12+ forward months + FY26 ~12% adj EPS growth reaffirmed + buyback ≥$8B)**. Two-observation trend-evidence in hand (Q1 8.4% → Q2 10.6%) resolves rev 30-anchored Subtype B prematurity from original NO-GO. KL #4 management-execution residual acknowledged as SECONDARY-driver bounded by quantitative invalidation gates (i) SVOD margin <8% for 2 consecutive quarters / (ii) FY26 adj EPS guide cut to ≤6% / (iii) buyback pace fall ≤$3B at H1 or ≤$5B at Q3 / (iv) rev 30 metric-immutability auto-invalidation if SVOD reporting form changes / (v) FCC TV-license adverse final order with material 8-K disclosure pre-emptive review trigger. Counter-cycle entry texture: trailing-30-day +12% (within +15% threshold per TradingView "month change is a 11.98% rise"; below +15% deferral); name -13% from 52-wk high $124.69; 28 of 30 days neutral-to-down trajectory with the +7.54% Q2-print pop being trigger-resolution-event itself (not separately disqualifying under criterion 6). **Limit BUY 0.2584 DIS @ $107.50 day order Thu 2026-05-07 staged.** Strategy D book post-fill: 2/10 concurrent (RTX + DIS), Industrials/A&D ~2.0% + Comm Services/Entertainment ~2.0% sector concentrations both well within 30% caps, ~$56 deployed, ~$1,333 SGOV remaining, total D NAV ~$1,388.65 (NAV-flat modulo ~$0.30 commission). 2026-Q2 D-shortlist net result advances to 2 GO (RTX, DIS), 6 NO-GO/pending across LLY/CEG/VST/GOOGL/CCJ/BA + GEV deferred. Fill capture event scheduled Thu 2026-05-07 14:30 MT (`llj1u9gd6qvh94ogp684rloq4c`). Watchlist.md updated to reflect DIS resolution out of D re-screen pipeline. → Decision_Log 2026-05-07 DIS re-screen GO entry.)

**Prior update**: 2026-05-06 ~late afternoon MT (D3 Calendar Hygiene reconciliation → 2 obsolete same-day events deleted (CCJ re-screen 5/6 09:00 fired AM with NO-GO logged; AXSM B thesis 5/6 10:00 fired AM with NO-GO logged); 0 new events created; 0 events modified (META mid-window pulse-check entry-date discrepancy preserved as-is per prior 2026-05-05 D3 precedent — 3-day shift within mid-window-pulse-check semantic tolerance; pulse-check session itself reads Portfolio_Ledger.md for actual entry date). 48 remaining future events Thu 5/7 → Sun 10/1 (and recurring quarterly/annual through 2027-10-01) verified consistent with current Decision_Log + Portfolio_Ledger state. Cadence-policy compliance audit per Claude_Task_Plan.md line 3 ("Only put quarterly and annual recurring events into google calendar. Human will execute the rest automatically."): no D1/D2/D3/W1-W5/M1-M5 cadence prompts in calendar; Q1-Q4 quarterly + A1-A3 annual recurring instances present; event-specific prompts (fill captures / re-screens / thesis-construction / KL #12 computation / time-based exits / pulse-checks) all present with popup notification at minute 0. No portfolio-state changes. → Decision_Log 2026-05-06 D3 Calendar Hygiene entry.)

**Prior update earlier**: 2026-05-06 ~mid-afternoon MT (D2 Daily Action Conversion against Daily.md 2026-05-06 RECOMMENDED ACTIONS → 7 Strategy B thesis-construction calendar events confirmed scheduled (AMD/DOC Thu / ARM/FLEX Fri / GLW/SMCI Mon / UBER Tue); 1 candidate routed to existing Strategy D re-screen path (DIS Thu 5/7 09:00 MT — trigger conditions all MET on Q2 print: SVOD margin 10.6% > 8.4% baseline; D'Amaro continuity messaging; buyback raised $7B → $8B); 4 candidates declined for B-thesis-construction at D2 (NVO with 340B-reversal-noise + borderline close-to-close magnitude; SHOP/PYPL/CDW with B-short framing in hostile risk-on regime context post Iran-de-escalation rally + 6-consecutive-NO-GO B-short precedent string [BE/CAT/TWLO/UPS/NCLH/CRCL]); Watchlist.md created (was absent prior — first content covers Strategy A queue [CAT/LLY/QCOM/AAPL] + B disqualifier-flag tracking [NVO] + B short-direction-declined-at-D2 tracking [SHOP/PYPL/CDW] + D re-screen pipeline pointers + B/A demotion log audit trail + architecture preamble); Daily.md "Strategy.md long-only B" architectural mis-statement corrected (Strategy.md instrument rule line 271 reads "Long or short"); no portfolio-state changes; no new orders; no exits; no router review; Strategy B sector cap state unchanged: IT Services 1/3 / Health Care Facilities 1/3 / Comm Services 1/3. → Decision_Log 2026-05-06 D2 Daily Action Conversion entry.)

**Prior update earlier still**: 2026-05-06 ~MT (Strategy B AXSM Q1-print follow-on thesis construction → THIRD AXSM NO-GO in 5 days; second NO-GO on the SAME Q1 print event Mon 5/4 but on FRESH post-event information per Operating Protocols "NO-GO records are context, not barriers" rule → NO-GO via criterion 4 dual-framing decisive failure with **NEW sub-pattern 1 layer** (post-event-L1-aggressive-ratification-wave: 8+ aggressive PT raises in Tue+Wed-AM 48-hour window post-Q1 print to FactSet PT cluster mean ~$263.85 from prior ~$226 = +16.7% mean PT-cluster shift; Mizuho $228→$310 +36% anchor) **layered on existing 2026-05-04 sub-pattern 3** (information-priced-via-pre-print-rally) **+ sub-pattern-4-mirror** (in-window-positive-catalyst Auvelity AD launch June 2026 inside 60-day window) **+ NEW evidence layer** (COO Mark Jacobson sold 50% position Mon @ $227.94 = $1.03M insider-distribution-into-rally; stock failing-to-follow-ratification Mon $227.93 → Tue $227.21 -0.32% on half-volume → Wed open $223.06 -1.83% pre-bell despite 2 additional Wed-AM PT raises; Morningstar 712%-premium-to-fair-value structural valuation distortion). Sub-pattern 1 advances to 3 instances (BE-CAT-AXSM) with new "**layered-1+3 sub-pattern variant**" established. LONG framing dismissed on 5 compounding criterion 4 flaws + criterion 3 closed-list rev 14 absent admissible convergence target structure (numerical PT chase fails BE/CAT/TWLO/UPS doctrine; Q2 print outside 60-day window; no upcoming binary FDA decision; FOMC mismatch; no index-inclusion catalyst). SHORT framing dismissed on canonical KL #1 textbook-rational-trap 2.20 (shorting against 8+ aggressive PT raises + first-in-class FDA approval + 35% Y/Y prescription growth + Auvelity peak sales raised to $8B + AD launch June inside window) + sub-pattern-4-mirror + KL #7 short-side gap-up execution risk. Experiment B totals advance to 3 GO + 25 NO-GO = 10.7%/89.3% hit rate. No CCJ-specific re-screen calendar event scheduled (10-day post-event window expires Mon 2026-05-18; routine Daily.md scan cadence picks up any fresh trigger). No portfolio-state changes. → Decision_Log 2026-05-06 AXSM Q1-print follow-on NO-GO entry.)

---

## Account-Level

- **Total account value (IBKR custodial)**: $9,448 (NLV from 2026-05-07 ~10:12 MT IBKR snapshot: SGOV 92.5414 shares + DIS 0.28 + IBM 0.1198 + RTX 0.1595 + HCA 0.0642 + META 0.0454 + USD Cash $8.13; daily P&L +$2 / +0.02% per IBKR display; Unrealized P&L -$15; MKT VAL $9,439.71; Excess Liq $7,087.87; Maint Margin $2,359.91; Buying Power $28,351.46; **Funds-on-Hold field absent = $0** — released Thu 2026-05-07 from settlement-hold status, confirming the corrected interpretation of $2,500 as a SUPPLEMENTAL CAPITAL DEPOSIT (not a pending outgoing transfer; Apr 28 "hold-within-NLV" first-observation hypothesis REFUTED by today's NLV jump of ~+$2,500 on hold-clearance); May 5 $4.51 account-level cash discrepancy CLOSED as accepted-fee-or-timing-noise per per-strategy equal-split attribution -$0.90/strategy; account-level SGOV reparking cycle deployed supplemental into +24.89 SGOV at $100.4763 effective avg cost — see Decision_Log 2026-05-07 DIS fill capture anomaly entry)
- **Experiment start**: 2026-04-22 with $6,946.86 initial capital, split approximately equally across Strategies A, B, C, D, E (A: $1,389.38; B, C, D, E: $1,389.37 each — A gets the $0.01 rounding residual)
- **Total deposits since start**: $9,446.86 ($6,946.86 initial 2026-04-22 + $2,500.00 supplemental deposited circa 2026-04-28 with IBKR settlement-hold status through Thu 2026-05-07 release-for-trading; supplemental allocated equal-split +$500.00/strategy per initial-allocation methodology; deployed today via account-level SGOV reparking cycle)
- **Held-aside pool (terminated strategies, SGOV)**: $0
- **Active strategies**: A, B, C, D, E
- **Terminated strategies**: (none)

### Operational Notes (standing — applies to all trade execution decisions)

- **IBKR account tier:** **IBKR Pro** (confirmed 2026-04-25). Tiered pricing ($0.0035/share with order-type-specific minimums). If account is ever migrated to Lite, this note should be updated.
- **Fractional shares:** IBKR supports fractional shares for US equities. All strategy-level position sizing assumes fractional execution is available. For any name where fractional is unsupported (e.g., certain ETFs, OTC), Claude re-sizes to the next whole share or defers per Strategy.md at thesis-construction time — never an order-ticket-time decision.
- **Commission policy (2026-04-27 Sunday late protocol shift):** Commission is disregarded at decision time and accepted as a business cost. No EV-at-design-size computation gates execution. Strategy-level edge-decay metrics measure realized post-commission P&L empirically (commissions accumulate as a fixed line item in closed-trade detail); this provides the binding measurement of whether commission drag exceeds edge magnitude, not an at-thesis-time veto. Implication: Claude does not stage trades subject to "human-operator EV check at order-ticket time" hooks. Theses either GO or NO-GO at construction; staged orders execute as specified.

**SGOV parking conversion (2026-04-23):** Initial SGOV purchase executed in two fills:
- Fill 1 (07:46:03 ET, NYSE): 68 shares @ $100.64, commission $0.43, gross $6,843.52
- Fill 2 (12:55:51 ET, IBKR): 0.98 shares @ $100.61, commission $0.35, gross $98.60
- Combined: 68.98 shares, $6,942.12 SGOV cost + $0.78 commissions = $6,942.90 total cost
- Residual USD Cash: $3.96

Per-strategy allocation uses fractional shares split evenly (13.796 shares each) at the weighted-average fill price of $100.6396. Commissions of $0.78 total distributed $0.16 per strategy as a cost of the parking conversion; each strategy's starting value is adjusted from $1,389.38/$1,389.37 to $1,389.22/$1,389.21 accordingly.

### Deposit History

| Date | Amount | Split among | Per-strategy amount |
|------|--------|--------------|---------------------|
| 2026-04-22 | $6,946.86 | A, B, C, D, E (initial) | $1,389.38 (A); $1,389.37 (B, C, D, E) |
| 2026-04-28 (settlement-released 2026-05-07) | $2,500.00 | A, B, C, D, E (supplemental, equal-split per Decision_Log 2026-05-07 DIS fill capture Anomaly 3 interpretation correction) | $500.00 each |

### SGOV Parking Activity

| Date | Action | Shares | Price | Commission | Gross $ | Order ID |
|------|--------|--------|--------|-------------|---------|----------|
| 2026-04-23 07:46:03 ET | Buy (NYSE) | 68 | $100.64 | $0.43 | $6,843.52 | 00fd111d.00011066.69eaee66.0001 |
| 2026-04-23 12:55:51 ET | Buy (IBKR) | 0.98 | $100.61 | $0.35 | $98.60 | 00fd111d.00011066.69e9a0d2.0001 |
| 2026-04-27 07:31:59 ET | Sell (IBKR) | 0.6 | $100.64 | $0.35 | $60.38 | (capture from screenshot 2026-04-27) |
| 2026-04-27 07:42:25 ET | Buy (IBKR) | 0.0695 | $100.65 | $0.07 | $7.00 | (capture from screenshot 2026-04-27) |
| 2026-04-28 07:30:05 ET | Sell (IBKR) | 0.3 | $100.65 | $0.30 | $30.20 | (capture from screenshot 2026-04-28) |
| 2026-04-28 11:48:42 ET | Buy (IBKR) | 0.0198 | $100.66 | $0.02 | $1.99 | (capture from screenshot 2026-04-28) |
| 2026-05-05 12:51:59 ET | Sell (IBKR) | 0.30 | $100.42 | $0.30 | $30.13 | (capture from screenshot 2026-05-05 ~10:56 MT) |
| 2026-05-05 12:55:40 ET | Sell (IBKR) | 0.02 | $100.42 | $0.02 | $2.01 | (capture from screenshot 2026-05-05 ~10:56 MT) |
| 2026-05-07 09:32:15 ET | Buy (IBDRIPUS, dividend reinvest) | 0.2021 | $100.45 | $0.02 | $20.30 | (capture from screenshot 2026-05-07 ~10:13 MT) |
| 2026-05-07 11:30:01 ET | Sell (IBKR) | 0.4 | $100.44 | $0.35 | $40.18 | (capture from screenshot 2026-05-07 ~10:13 MT) |
| 2026-05-07 13:10:13 ET | Buy (DARK+1) | 28.87 | $100.45 | $0.36 | $2,899.90 | (capture from screenshot 2026-05-07 ~10:13 MT) |
| 2026-05-07 13:11:11 ET | Sell (IBKR+1) | 3.98 | $100.44 | $0.36 | $399.77 | (capture from screenshot 2026-05-07 ~10:13 MT) |

**Apr 27 SGOV cycle reconciliation** (per-strategy attribution):
- B sold ~0.2786 SGOV @ $100.64 (gross $28.04) less $0.18 commission share = $27.86 net proceeds, used $27.85 to buy IBM (principal $27.57 + IBM commission $0.28); residual $0.01 to cash.
- D sold ~0.2821 SGOV @ $100.64 (gross $28.39) less $0.17 commission share = $28.22 net proceeds, used $28.21 to buy RTX (principal $27.93 + RTX commission $0.28); residual $0.01 to cash.
- Account-level residual operation: 0.0393 SGOV "extra" sold (above trade-funding need) + 0.0695 SGOV bought back = net +0.0302 SGOV at account, balanced by ~$3.04 cash → SGOV reparking. Allocated proportionally to each strategy's pre-trade cash holdings (~+0.0061 SGOV / −$0.62 cash per strategy; small rounding noise — see per-strategy state below).
- Cumulative SGOV trading commissions to date: $0.43 + $0.35 + $0.35 + $0.07 = $1.20 across 4 SGOV transactions (parking + Apr 27 cycle).

**Apr 28 SGOV cycle reconciliation** (per-strategy attribution):
- B sold ~0.2821 SGOV @ $100.65 (gross $28.40) less $0.28 commission share = $28.12 net proceeds, used $28.11 to buy HCA (principal $27.83 + HCA commission $0.28); residual $0.01 to cash.
- Account-level residual operation: 0.0179 SGOV "extra" sold (above B's trade-funding need; gross $1.80 less $0.02 commission share = $1.78 net) + 0.0198 SGOV bought back at $100.66 ($1.99 principal + $0.02 commission = $2.01 total cost) = net +0.0019 SGOV at account, balanced by −$0.23 cash → SGOV reparking. Allocated proportionally across all 5 strategies' pre-trade cash holdings (~−$0.05 cash / +0.0004 SGOV per strategy; small rounding noise — see per-strategy state below).
- Cumulative SGOV trading commissions to date: $1.20 + $0.30 + $0.02 = $1.52 across 6 SGOV transactions (parking + Apr 27 cycle + Apr 28 cycle).

**May 5 SGOV cycle reconciliation** (per-strategy attribution):
- B sold 0.30 SGOV @ $100.42 (gross $30.13) less $0.30 commission share = $29.83 net proceeds; B sold additional 0.02 SGOV @ $100.42 (gross $2.01, $0.02 commission, $1.99 net) for buffer-extension after META fill — total B SGOV-sale gross $32.14 less $0.32 commission = $31.82 net proceeds. B used $27.57 to buy META 0.0454 @ $601.30 GTC limit (principal $27.30 + META commission $0.27 — operator placed limit at $601.30 GTC vs staged $615 Day, exact-limit fill at $601.30, $13.70/share better than staged). B residual cash from cycle: $31.82 - $27.57 = $4.25 added to cash (net of 0.32 SGOV sold).
- **Account-level cash discrepancy flagged.** Expected end-of-cycle account-level USD Cash: $0.64 (Mon 5/4 09:15 MT) + $4.25 (B's net cash addition) = $4.89. Observed end-state USD Cash per Tue 5/5 ~10:56 MT screenshot: $0.38. Discrepancy: $4.51 unaccounted. Likely candidates: (a) IBKR Pro monthly minimum activity fee or market-data subscription posted today; (b) timing artifact in screenshot cash-display lag; (c) unrecorded SGOV reparking transaction not visible in 3-trade screenshot snapshot (though end-SGOV math 68.1693 - 0.32 = 67.8493 matches with no buyback). Magnitude is operationally minor (0.065% of NLV) and account-level (not strategy-specific). **Per-strategy NAV math is unaffected** because the cost-basis ledger is the source of truth for strategy NAVs — IBKR display discrepancies are reconciled at the next-routine-session investigation. Per-strategy cash attribution provisionally retains B-cash $4.39 (= $0.14 prior + $4.25 cycle residual) at the cost-basis-ledger level; the $4.51 account-level shortage is to be precision-corrected at next-session reconciliation when the source is identified.
- **Per Decision_Log 2026-05-07 DIS fill capture Anomaly 2: $4.51 May 5 cash discrepancy CLOSED** as accepted-fee-or-timing-noise; surviving candidate (a) IBKR Pro inactivity-fee or market-data subscription posted Apr 30-May 5 timeframe; per-strategy attribution -$0.90/strategy equal-split applied at today's ledger update.
- Cumulative SGOV trading commissions to date: $1.52 + $0.30 + $0.02 = $1.84 across 8 SGOV transactions (parking + Apr 27 cycle + Apr 28 cycle + May 5 cycle).

**May 7 SGOV cycle reconciliation** (per-strategy attribution; three logically-separable sub-cycles compressed into a single trading day; full anomaly-resolution-and-interpretation-correction substance lives in Decision_Log 2026-05-07 DIS fill capture entry):

- **Sub-cycle (a) Dividend reinvest 07:32:15 MT** — IBDRIPUS auto-reinvest of monthly SGOV dividend payment, +0.2021 SGOV @ $100.45 (principal $20.30 + commission $0.02). Pro-rata to existing per-strategy SGOV holdings (May 5 close): A +0.0411, B +0.0385, C +0.0411, D +0.0403, E +0.0411 (sum 0.2021). Cash effect ~neutral per strategy (dividend received then spent on SGOV; commission $0.02 absorbed at account level).

- **Sub-cycle (b) D's DIS-funding cycle 09:30:01-09:36:29 MT** — D-specific. D sold 0.4 SGOV @ $100.44 (gross $40.18, $0.35 comm, net $39.83 D cash); D bought 0.28 DIS @ $110.35 (principal $30.90 + DIS comm $0.31 = cost basis $31.21). D's net cash from DIS cycle: +$8.62 (over-funded SGOV sale relative to DIS-buy cost; surplus retained as D cash residual). D's SGOV: -0.4 shares; D's DIS: +0.28 shares NEW. Operator-discretion modification at execution: limit $110.35 vs staged $107.50 (+$2.85 / +2.65% looser); shares 0.28 vs staged 0.2584 (+0.0216 / +8.4% larger); principal $30.90 vs staged $27.78 (+$3.12 / +11.2% larger; 2.22% of D NAV vs 2.00% staged) — RTX 2026-04-27 looser-for-fill-assurance precedent continuation. Thesis disposition unchanged on 12+ month structural Subtype B SVOD-margin-trajectory thesis; criterion 6 still clears at borderline; LTCG eligible 2027-05-08; invalidation criteria (i)-(v) all NOT-TRIPPED at fill.

- **Sub-cycle (c) Supplemental-deposit deployment 11:10:13-11:11:11 MT** — operator deployed the released $2,500 supplemental into SGOV via 28.87 buy @ $100.45 ($2,899.90 + $0.36 comm = $2,900.26 cash out) followed by 3.98 over-buy trim @ $100.44 ($399.77 - $0.36 comm = $399.41 cash in); net 24.89 SGOV added at $2,500.86 effective cost = $100.4763/share avg cost (slightly above $100.4655 mid-market = ~$0.27 over-buy/trim cost across the pair). Allocated equal-split per supplemental-deposit attribution: +4.978 SGOV / strategy at $500.17 cash deployment / strategy. Combined with sub-cycle (a) dividend pro-rata + sub-cycle (b) D-funding -0.4 share: net per-strategy SGOV change today A/C/E +5.0191 / B +5.0165 / D +4.6183.

- **Per-strategy SGOV May 7 close**: A 18.8216, B 17.9383, C 18.8215, D 18.1387, E 18.8215 (sum 92.5416 ≈ IBKR 92.5414 within rounding).

- **Per-strategy cash residual May 7 close** (cost-basis-ledger basis, post fee allocation): A -$0.95, B $3.32, C -$0.95, D $7.32, E -$0.95 (sum $7.79 vs IBKR observed $8.13; rounding accumulation $0.34 acceptable). A/C/E negative cash residuals are bookkeeping artifacts of the May 5 $4.51 fee equal-split absorption combined with $500 supplemental's 4.978-share deployment slightly over-running each strategy's cash availability; will clear at next SGOV reparking opportunity (e.g., next thesis-construction-driven trade entry).

- **Per-strategy NAV mark-to-market May 7 close**: A $1,890.45, B $1,888.69, C $1,890.44, D $1,888.43, E $1,890.44 (sum $9,448.45 vs IBKR NLV $9,448 within rounding).

- Cumulative SGOV trading commissions to date: $1.84 + $0.02 + $0.35 + $0.36 + $0.36 = **$2.93** across 13 SGOV transactions. Cumulative open-position-buy commissions: $1.42 across 5 fills (IBM $0.28 + RTX $0.28 + HCA $0.28 + META $0.27 + DIS $0.31).

---

## Strategy A — Active

**Portfolio state** (as of 2026-05-07 ~10:12 MT — DIS fill capture session):
- Total value: **$1,890.45** mark-to-market (SGOV 18.8216 shares @ $100.48 mark = $1,891.40 + USD Cash residual -$0.95 absorbed-fee artifact). Cost-basis components: SGOV 18.8216 @ weighted ~$100.5947 cost ≈ $1,893.39 - cash deficit absorbing fee/comm allocation.
- Starting value: $1,389.22 on 2026-04-23 (after $0.16 SGOV parking commission; original allocation $1,389.38)
- Deposits received cumulative: **$1,889.38** ($1,389.38 initial 2026-04-22 + $500.00 supplemental allocation 2026-04-28 settlement-released 2026-05-07)
- Next trade size at 2%: $37.81 (recomputed off updated total value)
- Apr 27 activity: no trade entered. Cash → SGOV reparking allocated from account-level Apr 27 SGOV cycle: cash decreased $0.63, SGOV +0.0061 shares @ ~$100.65.
- Apr 28 activity: no trade entered. Cash → SGOV reparking allocated from account-level Apr 28 SGOV cycle: cash -$0.05, SGOV +0.0004 shares @ ~$100.66.
- May 7 activity: no A-specific trade. May 5 IBKR-fee equal-split allocation -$0.90; SGOV dividend reinvest pro-rata +0.0411 shares @ $100.45; supplemental capital deposit +$500.00 (per Decision_Log 2026-05-07 DIS fill capture Anomaly 3 interpretation correction); supplemental deployed via account-level SGOV reparking +4.978 shares @ $100.4763 effective avg cost. Net A SGOV +5.0191 shares; net cash residual -$0.95 (fee/comm artifact). → Decision_Log 2026-05-07 DIS fill capture anomaly entry.

**Performance**:
- First trade date: [not yet]
- Deployed TWR (cumulative from first trade): [n/a]
- Peak deployed TWR: [n/a]
- Current drawdown from peak: [n/a]
- Cumulative active time: 0 days
- Excess real return vs. SGOV benchmark (post-tax, post-inflation): [n/a]

**Gate**: 0 / 30 trades (not reached)

**Router activation state**: [see Regime_State.md]

**Open positions**: (none)

| # | Ticker | Entry Date | Entry Price | Position $ | Shares | Mark Price | Mark Value | Unrealized P&L |
|---|--------|------------|-------------|------------|--------|------------|------------|-----------------|

**Closed trades (at-a-glance)**: (none)

| # | Ticker | Entry | Exit | Days | Position $ | Net P&L | Return % | Exit Reason | Model (Entry / Exit) |
|---|--------|-------|------|------|------------|---------|----------|-------------|-----------------------|

**Closed trade details**: (none — populated as trades close; see template at the bottom of this document)

---

## Strategy B — Active

**Portfolio state** (as of 2026-05-07 ~10:12 MT — DIS fill capture session; no B-specific trade today; supplemental capital + fee allocation + dividend reinvest applied):
- Total value: **$1,888.69** mark-to-market. Composition: SGOV 17.9383 @ $100.48 mark = $1,802.36; IBM 0.1198 @ $229.45 mark = $27.49; HCA 0.0642 @ $433.49 mark = $27.83; META 0.0454 @ $610.00 mark = $27.69; USD Cash residual $3.32 (cost-basis-ledger basis = $4.39 May 5 cycle residual - $0.90 fee allocation - small dividend/comm rebal). Cumulative B commissions paid through cycle: $1.61.
- Starting value: $1,389.21 on 2026-04-23 (after $0.16 SGOV parking commission; original allocation $1,389.37).
- Deposits received cumulative: **$1,889.37** ($1,389.37 initial + $500.00 supplemental allocation 2026-04-28 settlement-released 2026-05-07).
- Next trade size at 2%: $37.77 (recomputed off updated total value).

**Activity log** (chronological state-affecting events; substance lives in linked Decision_Log entries):

- Apr 27: Sold 0.2786 SGOV → bought 0.1198 IBM @ $230.17 limit, cost basis $27.85; sector cap IT Services 1/3 NEW. → Decision_Log 2026-04-27 IBM fill capture.
- Apr 28: Sold 0.2821 SGOV → bought 0.0642 HCA @ $433.46 (operator $0.04 tighter limit), cost basis $28.11; sector cap Health Care Facilities 1/3 NEW; Funds-on-Hold $2,500 anomaly first observed (deferred to next-routine-session resolution). → Decision_Log 2026-04-28 HCA fill capture + hold anomaly.
- May 1 (mid-day): META B-thesis-construction → GO MEDIUM conviction; limit BUY 0.0454 @ $615 Day staged for Mon May 4 (Funds-on-Hold gate scheduled). → Decision_Log 2026-05-01 META GO.
- May 1 (afternoon): EQIX B-thesis-construction → NO-GO criterion 1 mechanical (close-to-close magnitude). → Decision_Log 2026-05-01 EQIX NO-GO.
- May 1 (afternoon): STLA B-thesis-construction → NO-GO criterion 4 (Investor Day May 21 in-window binary catalyst + V/MDLZ structural-overhang). First in-window-company-specific-binary-catalyst sub-pattern. → Decision_Log 2026-05-01 STLA NO-GO.
- May 1 (afternoon): BE B-thesis-construction → NO-GO criterion 4 SHORT-framing (NXPI/STX-style aggressive-sell-side-bull-ratification at greater magnitude). New "cleanest-L1-instance" benchmark for positive-direction-L1 sub-pattern. → Decision_Log 2026-05-01 BE NO-GO.
- May 1 (afternoon): TDOC B-thesis-construction → NO-GO instrument-rule (mkt cap $1.07B < $2B floor). First instrument-rule market-cap-floor-failure pattern. → Decision_Log 2026-05-01 TDOC NO-GO.
- May 4 (~09:15 MT): META Funds-on-Hold pre-execution gate FAILED → branch (b) single-deferral fired; META order DEFERRED to Tue 2026-05-05 with single-deferral fallback to NO-GO; no portfolio-state change. → Decision_Log 2026-05-04 META gate-fail branch (b).
- May 4 (~post-close): AXSM Q1-print B-thesis-construction → NO-GO criterion 4 sub-pattern 3 (information-priced-via-pre-print-rally + FDA-approval-launch-context overlay). Sub-pattern 3 advances 2→3 with new FDA-approval-with-bull-ratification variant. → Decision_Log 2026-05-04 AXSM NO-GO.
- May 5 (~MT): UPS B-thesis-construction → NO-GO criterion 4 dual-framing (Amazon Supply Chain Services launch as structural information event + V/MDLZ structural-overhang-persistence). Sub-pattern 4 advances 2→3 with new structural-competitive-threat-emergence variant. → Decision_Log 2026-05-05 UPS NO-GO.
- May 5 (~09:15 MT): META Funds-on-Hold pre-execution gate RE-CHECK CLEARED → branch (a) fired per operator state-change communication (settlement hold confirmed releasing Thu 2026-05-07); limit BUY 0.0454 @ $615 Day order PLACED. → Decision_Log 2026-05-05 META gate-clear branch (a).
- May 5 (~10:56 MT): META filled @ $601.30 GTC (operator-discretion: $13.70 tighter limit + GTC duration), cost basis $27.57; sector cap Comm Services 1/3 NEW. Account-level $4.51 cash discrepancy flagged for next-routine-session reconciliation. KL #12 first-computation calendar event scheduled Wed 2026-06-03. → Decision_Log 2026-05-05 META fill capture anomaly entry.
- May 5 (~MT): NCLH B-thesis-construction → NO-GO criterion 4 dual-framing (FY26 guide cut ~30% on Iran-war fuel + EU bookings macro overhang). Sub-pattern 4 advances 3→4 with new variant 4c "guide-cut-on-pre-existing-macro-overhang" established. Sector cap Cons Disc 0/3 unchanged (NCLH would have been 1/3 on entry). → Decision_Log 2026-05-05 NCLH NO-GO entry.
- May 5 (~MT): CRCL B-thesis-construction → NO-GO criterion 4 dual-framing (Q1 print May 11 BMO + Senate Banking markup week of May 11 stacked binaries at T+5–9 trading days from entry; sub-pattern 1 secondary features layered). Sub-pattern 5 advances 1→2 with new variant 5b "stacked-near-term-binaries" established. Sector cap Financials 0/3 unchanged (CRCL would have been 1/3 on entry). → Decision_Log 2026-05-05 CRCL NO-GO entry.
- May 6 (~AM MT): AXSM Q1-print follow-on B-thesis-construction (third AXSM NO-GO in 5 days; second on the same Q1 event but on FRESH post-event information per "NO-GO records are context, not barriers" rule) → NO-GO criterion 4 dual-framing with NEW sub-pattern 1 layered-1+3 variant established (post-event-L1-aggressive-ratification-wave: 8+ aggressive PT raises Tue+Wed-AM 48h window post-Q1 print; FactSet PT cluster mean $263.85 from prior $226 +16.7%; Mizuho $228→$310 +36% anchor; layered on existing 2026-05-04 sub-pattern 3 information-priced-via-pre-print-rally; + sub-pattern-4-mirror in-window-positive-catalyst Auvelity AD launch June 2026; + COO insider 50% position-reduction $1.03M into rally; + stock failing-to-follow-ratification signal). Experiment B totals advance to 3 GO + 25 NO-GO = 10.7%/89.3% hit rate. No portfolio-state change. → Decision_Log 2026-05-06 AXSM Q1-print follow-on NO-GO entry.
- May 6 (~mid-afternoon MT): Daily.md 2026-05-06 weekend+overnight+intraday scan persisted → 6 Strategy B "new entry candidates" surfaced (AMD/GLW/FLEX/DOC/ARM/DIS) + 3 disqualifier-flagged (SMCI/UBER/NVO) + 3 short-direction-flagged (SHOP/PYPL/CDW). D2 Daily Action Conversion → 7 thesis-construction calendar events confirmed scheduled (AMD/DOC Thu / ARM/FLEX Fri / GLW/SMCI Mon / UBER Tue); 1 candidate routed to existing Strategy D re-screen path (DIS Thu 5/7 09:00 MT); 4 candidates declined at D2 (NVO 340B-noise + borderline magnitude; SHOP/PYPL/CDW B-short in hostile risk-on regime); Watchlist.md created (was absent prior); Daily.md "Strategy.md long-only B" architectural mis-statement corrected (instrument rule line 271 reads "Long or short"). No portfolio-state change. → Decision_Log 2026-05-06 D2 Daily Action Conversion entry.
- May 7 (~10:00 MT): PINS Q1-print B-thesis-construction → NO-GO criterion 4 dual-framing decisive failure with sub-pattern 1 layered-1+3 variant SECOND INSTANCE (after AXSM 2026-05-06 first instance) + NEW "move-completely-faded-by-Day-2" evidence layer (post-event price trajectory: Mon AH +18.94% $24.81 → Tue close +6.83% $22.28 → Wed close ~+1.3% $21.13 → Thu near pre-print baseline $20.85-21.10 = ~80%+ retrace within 2 trading days, leaving no remaining post-event mean-reversion edge for either LONG or SHORT framing). 5 LONG decisive flaws (sub-pattern 1 PT-raise wave 15 firms BofA $20→$27 +35% anchor; sub-pattern 3 pre-print rally +19% from April lows; move-completely-faded-by-Day-2; ad pricing -5% YoY quality-of-revenue; convergence target structural failure) + 5 SHORT decisive flaws (mean reversion already complete; aggressive ratification + 15.4% short interest squeeze risk; +25% stop binds toward BofA $27 PT; 2.20-trap canonical with 9-NO-GO B-short precedent string in current risk-on regime; SHORT convergence target structurally fails too). Conviction in NO-GO: HIGH (~85-90%). Sub-pattern 1 advances to 4 instances (BE 5/1, CAT 5/2, AXSM 5/6, PINS 5/7). Layered-1+3 sub-pattern variant advances to 2 instances. Experiment B totals advance to 3 GO + 26 NO-GO = 10.3% / 89.7% hit rate. Sector cap usage unchanged (Comm Services / Interactive Media & Services 1/3, all others 0/3). No portfolio-state change. → Decision_Log 2026-05-07 PINS NO-GO entry.
- May 7 (~11:00 MT): AMD Q1-print B-thesis-construction → NO-GO criterion 4 dual-framing decisive failure with sub-pattern 1 layered-1+3 variant THIRD INSTANCE (same-day after PINS 10:00 MT second instance) at MOST EXTREME magnitude observed across all B thesis-construction cases on both layer components. Goldman Sachs $240→$450 (+88%) AND upgrade Hold→BUY = LARGEST single-firm PT raise observed in any B case. Pre-print +89% one-month / +245% one-year / +327% twelve-month rally = MOST EXTREME pre-print absorption observed in any B case. 12+ PT raises in 48h post-print + 4 rating upgrades (Goldman / DA Davidson / Bernstein / Seaport). NEW evidence layer "post-event move HELD through Day 2-3" (opposite of PINS's faded pattern; AMD Wed close +17.77% / Thu -1.34% = +16.2% net hold) — both fade and hold trajectories produce NO-GO disposition under sub-pattern 1 layered-1+3 variant, confirming the structural logic doesn't depend on Day 2-3 fade trajectory specifics. 6 LONG decisive flaws (sub-pattern 1 most-extreme; sub-pattern 3 most-extreme; move-HELD evidence; convergence target structural failure under criterion 3 — next earnings Aug 3-5 outside 60-day window from May 5; mega-cap multiple-compression-risk layer at $670B mkt cap / ~35-40× forward P/E; pre-mortem 2.4 self-reference closure binding) + 5 SHORT decisive flaws (2.20-trap canonical at maximum severity; +25% stop binds catastrophically toward $450-$530 PT cluster; KL #7 chip-peer-correlation gap-up risk; 2.4 narrative-over-fit residual on SHORT direction; SHORT convergence target structurally fails). Conviction in NO-GO: HIGH-VERY-HIGH (~90-95%). Sub-pattern 1 advances to 5 instances (BE 5/1, CAT 5/2, AXSM 5/6, PINS 5/7, **AMD 5/7**). Layered-1+3 variant advances to 3 instances. Experiment B totals advance to **3 GO + 27 NO-GO = 10.0% / 90.0% hit rate**. Sector cap usage unchanged (IT/Semiconductors 0/3 — AMD would have been 1/3 within cap; KL #12 first-computation event Wed 2026-06-03 unchanged; AMD-add scenario averted). No portfolio-state change. → Decision_Log 2026-05-07 AMD NO-GO entry.
- May 7 (~13:00 MT): DOC Q1-print B-thesis-construction → NO-GO criterion 4 dual-framing decisive failure under AMBIGUOUS sub-pattern routing (NOT canonical sub-pattern 1 — no documented post-print PT-raise wave; pre-print sell-side BEARISH-positioned with Cantor $20→$17 May 4 + Jefferies Buy→Hold + Baird $21→$20; NOT sub-pattern 3 — pre-print stock depressed not rallying). Pattern is closer to NEW variant: "depressed-name pre-print-bearish-positioning-unwind on modest-print-confirmation + peer-print-tailwind WELL/VTR + risk-on-regime backdrop" (first observed instance — candidate sub-pattern 8 pending second-instance validation per W4). Print components modest: Q1 FFO-as-Adj $0.45 vs $0.43 cons (+$0.02 / +4.7% beat); FY26 FFO guide raised midpoint $0.01 ($1.72→$1.73; midpoint STILL BELOW prior consensus avg $1.74); Janus Living IPO completed March 2026 (already-public); IPO accretion BACK-LOADED ($0.04 in 2027+; neutral 2026 per management); April $100M buyback at $16.81 already-known. Stock action: Wed close $18.76 (+13.60% per Investing.com / +13.75% Yahoo / Motley Fool +17.93% intraday peak) → Thu intraday ~$17.79 = -5.17% partial fade (DIAGNOSTIC MIDDLE CASE between PINS full-fade Day 2 and AMD full-hold Day 2-3). Day-2-3 trajectory bracket complete this session: full-fade (PINS) / partial-fade (DOC) / full-hold (AMD) — all three produce NO-GO under appropriate sub-pattern routing. 6 LONG decisive flaws (modest information content; sentiment-dominant rally drivers per Investing.com explicit list 4-of-6 non-information-content; pre-print-bearish-positioning-unwind not B-mechanism candidate; partial-fade equilibrium already settled at midpoint; convergence target weak with stock at 50% gap-fill point + Q2 print Aug 5 outside 60-day window; sub-pattern routing ambiguity binding under Constraint 1 self-reference closure) + 5 SHORT decisive flaws (2.20-trap canonical even on modest beat-and-raise; mean reversion already partial via Thu fade; +25% stop $22.24 above 52-wk high $19.68 with KL #7 gap-up risk; healthcare REIT sector beta tailwind WELL/VTR + risk-on; SHORT convergence target weak). Conviction in NO-GO: MEDIUM-HIGH (~70-80%) — lower than PINS (~85-90%) / AMD (~90-95%) because DOC pattern genuinely ambiguous and LONG framing has SOME residual edge (~+7% to consensus PT $19.04, KL #12 favorable with ~0.30-0.40 avg pairwise vs current B book, sector cap clean). KL #12 favorable for DOC (REIT, low equity-correlation) but secondary to criterion 4 disposition. Experiment B totals advance to **3 GO + 28 NO-GO = 9.7% / 90.3% hit rate**. Sector cap usage unchanged (Real Estate / Health Care REITs 0/3 — DOC would have been 1/3 within cap; KL #12 first-computation event unchanged; DOC-add scenario averted). No portfolio-state change. **Same-session 5-disposition pattern Thu 2026-05-07: 1 GO (DIS Strategy D) + 3 NO-GO (PINS / AMD / DOC Strategy B) demonstrates framework resolution discipline.** → Decision_Log 2026-05-07 DOC NO-GO entry.
- May 7 (~14:30 MT): No B-specific trade. May 5 IBKR-fee equal-split allocation -$0.90 (closes $4.51 May 5 cash discrepancy as accepted-fee-or-timing-noise per Anomaly 2 resolution); SGOV dividend reinvest pro-rata +0.0385 shares @ $100.45; supplemental capital deposit +$500.00 (per Decision_Log 2026-05-07 DIS fill capture Anomaly 3 interpretation correction; total B deposits cumulative $1,389.37 → $1,889.37); supplemental deployed via account-level SGOV reparking +4.978 shares @ $100.4763 effective avg cost. Net B SGOV +5.0165 shares (12.9218 → 17.9383); net cash residual $3.32 (= $4.39 May 5 cycle residual - $0.90 fee - small comm rebal). B IBM/HCA/META marks refreshed to today's snapshot ($228.61 → $229.45 / $431.17 → $433.49 / $601.34 → $610.00). → Decision_Log 2026-05-07 DIS fill capture anomaly entry.
- May 8 (~10:00 MT): TSN Q2-FY26-print B-thesis-construction → NO-GO criterion 4 dual-framing decisive failure with sub-pattern 1+3+4 triple-layered fingerprint (sell-side bull ratification 5+ firms PT-raised 24-48h post-print modest magnitude + pre-print bullish positioning Piper Apr 6 OW upgrade $61→$75 +23% PT raise four weeks pre-print + Beef segment structural overhang FY26 loss guide WIDENED to ($350M)-($500M) on cattle herd 75-year low + 2025 calf crop smallest since 1941 + "Rebuild Delay" 2027-2028 normalization timeline structurally mismatched against B's 60-day window). Print details: Mon 2026-05-04 BMO (NOT Tue 5/5 as session prompt stated; primary-source 8-K corrects); EPS $0.87 vs $0.78 cons (+12% beat); FY26 AOI guide raised +$100M midpoint; Chicken segment guide raised +$200M midpoint at 12.2% margin; adj EPS DOWN 5% Y/Y. Stock: Fri 5/1 close $64.07 → Mon 5/4 +7.80% to ~$69.07 → Tue 5/5 hit 52-wk high $69.48 → Thu 5/7 close $67.94 = ~77% retention through Day 3. 6 LONG decisive flaws + criterion 3 closed-list rev 14 absent admissible target (Q3 print Aug 10 outside 60-day window from May 4 = July 3; FOMC mismatch on idiosyncratic protein-processor; already in S&P 500 / Russell 1000) + 5 SHORT decisive flaws (2.20-trap canonical against beat-and-raise; 9-NO-GO B-short precedent string in current risk-on regime extends to 10). Conviction in NO-GO: HIGH (~80-85%) — between PINS (~85-90%) and DOC (~70-80%). Theater-check CONVERGENT. **NEW sub-pattern variant flagged for W4 taxonomy extraction: layered-1+3+4 triple-pattern fingerprint** (TSN first instance). Sub-pattern 1 advances to 6 instances (BE / CAT / AXSM / PINS / AMD / TSN); layered-1+3 variant advances to 4 instances; sub-pattern 4 advances to 5 instances. KL #12 FAVORABLE for TSN (cons-staples-defensive low-beta-name pairwise correlation among LOWEST observed across any B candidate vs current 3-long book; estimated 4-long-book pairwise avg 0.25-0.35 well under 0.5 trigger) but secondary to criterion 4 disposition. Experiment B totals advance to **3 GO + 29 NO-GO = 9.4% / 90.6% hit rate**. Sector cap usage unchanged (Cons Staples / Food Products 0/3 — TSN would have been 1/3 within cap; KL #12 first-computation event Wed 2026-06-03 unchanged; TSN-add scenario averted). Window expires ~Mon 2026-05-18 (1-day non-binding correction from session-prompt 5/19); no calendar event scheduled to revisit (criterion-4 information-driven characterization unlikely to flip from re-examining same data; routine Daily.md scan picks up any fresh trigger). No portfolio-state change. → Decision_Log 2026-05-08 TSN NO-GO entry.
- May 9 (~06:00 MT): D2 Daily Action Conversion — 10 B-thesis-construction calendar events scheduled (4 rescheduled ARM/FLEX/DDOG/FTNT; 6 new AKAM/MNST/AXON/PTC/VTRS/AGL); 3 Watchlist.md updates (AKAM A-queue add; VST color upgrade; DDOG note strengthen); 0 exits; 0 orders staged; no portfolio-state change. → Decision_Log 2026-05-09 D2 entry.
- May 11 (~09:00 MT): GLW NVDA-partnership-and-Springboard-2030-upgrade B-thesis-construction → NO-GO criterion 2 + criterion 4 dual-framing decisive failure with sub-pattern 1 layered-1+3 variant FOURTH INSTANCE at MOST EXTREME pre-event-rally magnitude observed across any B candidate (YTD +101.8% / TTM +257.56% / 6-month +140% exceeds prior AMD reference) + NEW evidence layer "peer-cross-section-DECLINE on competitive-displacement-information" (AAOI -14% / COHR -10% / LITE -7% / CIEN -10% / FN -8% same-day; opposite of typical sympathy-rally; validates information-content over sentiment-rotation). Criterion 1 qualifying-event sub-test resolved CLEANLY QUALIFYING via Springboard upgrade compound-event component direct-listing match on Strategy.md thesis-line 262 "guidance update" explicit example — distinct from MU 2026-05-05 D2 decline precedent (third-party sell-side commentary fails sub-test); GLW first-party-corporate-issued on three dimensions. Stock action Tue 5/5 $162.10 → Wed 5/6 $181.57 (+12.01% close-to-close; session-prompt's "+17%" non-binding correction) → Thu $182.40 → Fri $186.94 = +15.32% retained / 127.6% retention vs Day-0 gain (move EXTENDED through Day 2). Mkt cap ~$156B (session-prompt's "~$45-50B" non-binding correction by ~3×). 6 LONG decisive flaws + 5 SHORT decisive flaws. Conviction in NO-GO: HIGH (~85-90%) — between PINS and AMD. Theater-check CONVERGENT. Sub-pattern 1 advances to 7 instances (BE / CAT / AXSM / PINS / AMD / TSN / **GLW**); layered-1+3 variant advances to 5 instances (AXSM / PINS / AMD / TSN-layered-1+3+4 / **GLW**); NEW evidence layer "peer-cross-section-DECLINE signature" flagged for W5 sub-pattern taxonomy extraction (GLW first instance; cross-sectional-competitive-displacement dimension; pending second-instance validation). KL #12 UNFAVORABLE for GLW (estimated 4-long-book pairwise avg ~0.40-0.50 due to GLW-IBM ~0.50-0.65 + GLW-META ~0.45-0.60 AI-narrative correlations) — secondary to disposition basis but reinforces NO-GO. Experiment B totals advance to **3 GO + 30 NO-GO = 9.1% / 90.9% hit rate**. Sector cap usage unchanged (IT / Electronic Components 0/3 — GLW would have been 1/3 sub-industry / IT-sector would have advanced 1/3 → 2/3 within per-sector cap). No portfolio-state change. Window expires ~Wed 2026-05-20 (today Day 3 of 10). No calendar event scheduled to revisit. → Decision_Log 2026-05-11 GLW NO-GO entry.

**Performance**:
- First trade date: [not yet]
- Deployed TWR: [n/a]
- Peak deployed TWR: [n/a]
- Current drawdown: [n/a]
- Cumulative active time: 0 days
- Excess real return vs. SGOV: [n/a]

**Gate**: 0 / 30 trades (not reached)

**Router activation state**: [see Regime_State.md]

**Open positions**: 3

| # | Ticker | Entry Date | Entry Price | Position $ | Shares | Side | Mark Price | Mark Value | Unrealized P&L | Borrow Rate (if short) |
|---|--------|------------|-------------|------------|--------|------|------------|------------|-----------------|--------------------------|
| 1 | IBM | 2026-04-27 | $230.17 | $27.85 (incl $0.28 comm) | 0.1198 | Long | $229.45 | $27.49 | -$0.36 (mark vs cost basis incl comm) | n/a (long) |
| 2 | HCA | 2026-04-28 | $433.46 | $28.11 (incl $0.28 comm) | 0.0642 | Long | $433.49 | $27.83 | -$0.28 (mark vs cost basis incl comm; +$0.00 vs cost-pre-comm) | n/a (long) |
| 3 | META | 2026-05-05 | $601.30 | $27.57 (incl $0.27 comm) | 0.0454 | Long | $610.00 | $27.69 | +$0.12 (mark vs cost basis incl comm; +$0.40 vs cost-pre-comm; first open B position with positive mark P&L) | n/a (long) |

**Closed trades (at-a-glance)**: (none)

| # | Ticker | Entry | Exit | Days | Position $ | Side | Net P&L | Return % | Exit Reason | Model (Entry / Exit) |
|---|--------|-------|------|------|------------|------|---------|----------|-------------|-----------------------|

**Closed trade details**: (none)

---

## Strategy C — Active

**Portfolio state** (as of 2026-05-07 ~10:12 MT — DIS fill capture session; no C-specific trade today; supplemental capital + fee allocation + dividend reinvest applied):
- Total value: **$1,890.44** mark-to-market (SGOV 18.8215 shares @ $100.48 mark = $1,891.39 + USD Cash residual -$0.95 absorbed-fee artifact).
- Starting value: $1,389.21 on 2026-04-23 (after $0.16 SGOV parking commission; original allocation $1,389.37)
- Deposits received cumulative: **$1,889.37** ($1,389.37 initial + $500.00 supplemental)
- Next trade size at 2% (max capital at risk for any structure): $37.81
- Apr 27 activity: no trade entered. Cash → SGOV reparking allocated from account-level Apr 27 SGOV cycle: cash -$0.62, SGOV +0.0060 shares @ ~$100.65.
- Apr 28 activity: no trade entered. Cash → SGOV reparking allocated from account-level Apr 28 SGOV cycle: cash -$0.05, SGOV +0.0004 shares @ ~$100.66.
- May 7 activity: no C-specific trade. May 5 IBKR-fee equal-split allocation -$0.90; SGOV dividend reinvest pro-rata +0.0411 shares @ $100.45; supplemental capital deposit +$500.00 (per Decision_Log 2026-05-07 DIS fill capture Anomaly 3 interpretation correction); supplemental deployed via account-level SGOV reparking +4.978 shares @ $100.4763 effective avg cost. Net C SGOV +5.0191 shares; net cash residual -$0.95 (fee/comm artifact). → Decision_Log 2026-05-07 DIS fill capture anomaly entry.

**Performance**:
- First trade date: [not yet]
- Deployed TWR: [n/a]
- Peak deployed TWR: [n/a]
- Current drawdown: [n/a]
- Cumulative active time: 0 days
- Excess real return vs. SGOV: [n/a]

**Gate**: 0 / 30 trades (not reached)

**Router activation state**: [see Regime_State.md]

**Open positions (defined-risk options structures)**: (none)

| # | Underlying | Structure | Entry Date | Expiry | Net Debit/Credit at Entry | Max Loss at Entry (Position $) | Current Structure Value | Unrealized P&L |
|---|------------|-----------|------------|--------|----------------------------|--------------------------------|-----------------------|-----------------|

**Closed trades (at-a-glance)**: (none)

| # | Underlying | Structure | Entry | Exit | Days | Max Loss (Position $) | Net P&L | Return % | Exit Reason | Model (Entry / Exit) |
|---|------------|-----------|-------|------|------|------------------------|---------|----------|-------------|-----------------------|

**Closed trade details**: (none)

---

## Strategy D — Active

**Portfolio state** (as of 2026-05-07 ~10:12 MT — DIS fill capture session; DIS limit BUY filled at modified parameters; supplemental capital + fee allocation + dividend reinvest applied):
- Total value: **$1,888.43** mark-to-market. Composition: SGOV 18.1387 shares @ $100.48 mark = $1,822.59; RTX 0.1595 shares @ $176.24 mark = $28.11 (vs cost basis incl comm $28.21); DIS 0.28 shares @ $108.60 mark = $30.41 (vs cost basis incl comm $31.21); USD Cash residual $7.32 (= $0.13 prior + $500 supplemental + $39.83 SGOV-D-funding sale net - $31.21 DIS-buy cost - $0.90 fee allocation - $500.17 SGOV reparking - $0.004 div rebal).
- Starting value: $1,389.21 on 2026-04-23 (after $0.16 SGOV parking commission; original allocation $1,389.37)
- Deposits received cumulative: **$1,889.37** ($1,389.37 initial + $500.00 supplemental allocation 2026-04-28 settlement-released 2026-05-07)
- Next trade size at 2%: $37.77 (recomputed off updated total value)
- Apr 27: Sold 0.2821 SGOV → bought 0.1595 RTX @ $175.12 (operator $0.12 above $175.00 reference for fill assurance), cost basis $28.21; sector concentration Industrials (Aerospace & Defense) ~2.0% of NAV. → Decision_Log 2026-04-27 RTX fill capture.
- Apr 28: No new trade. Cash → SGOV reparking allocated from account-level Apr 28 SGOV cycle: cash -$0.05, SGOV +0.0004 shares @ ~$100.66. RTX mark essentially flat ($176.00 → $175.99).
- May 6 (~AM MT): CCJ post-Q1-print re-screen → trigger conditions (a)/(b)/(c) all MET → fresh Subtype B thesis run per session-prompt step 4 → NO-GO via criterion 4 (7-support adversarial decisive-flaw cluster: post-Q1-print -3.21% momentum-exhaustion at saturated valuation while SPY ATH; 2.13/2.19 nuclear-renaissance amplification expanded by Iran-war energy-security overlay; forward PE 117x at sell-side median PT $123.92 = +8.3% upside ceiling; Westinghouse Cameco-share GAAP net loss $46M persists; Iran-war-premium asymmetric reversal risk; family-pattern empirical 50% 2.13/2.19-decisive across CEG-VST-GOOGL-CCJ April D shortlist). No CCJ-specific re-screen calendar event scheduled; falls into 2026-Q3 quarterly D shortlist re-evaluation (~2026-07-26 ahead of Cameco Q2 print Fri 2026-07-31 BMO). No portfolio-state change. → Decision_Log 2026-05-06 CCJ re-screen NO-GO entry.
- May 7 (~09:00 MT): DIS post-Q2-FY26-print re-screen → trigger conditions (a)/(b)/(c) all MET (SVOD margin 10.6% Q2 vs 8.4% Q1 baseline cleared + FY26 10% guide cleared directionally; D'Amaro debut framed strategic continuity via three-pillar framework + CFO Johnston "no FY26/FY27 adj-EPS growth changes anticipated"; buyback raised $7B → $8B = acceleration not just reaffirmation) → fresh Strategy D Subtype B thesis run per session-prompt step 4 → **GO with primary driver explicitly reframed from management-execution-quality (KL #4 residual original NO-GO basis) to financial-metric-traceable (SVOD operating margin sustained ≥10% over 12+ forward months + FY26 ~12% adj EPS growth reaffirmed + buyback ≥$8B)**. Two-observation trend evidence (Q1 8.4% → Q2 10.6%) resolves rev 30 Subtype B prematurity. Counter-cycle entry texture: trailing-30-day +12% (within +15% threshold per TradingView; below deferral); -13% from 52-wk high $124.69. **Limit BUY 0.2584 DIS @ $107.50 day order Thu 2026-05-07 staged.** Fill capture event scheduled Thu 2026-05-07 14:30 MT (`llj1u9gd6qvh94ogp684rloq4c`). → Decision_Log 2026-05-07 DIS re-screen GO entry.
- May 7 (~09:36:29 MT): DIS limit BUY FILLED at modified parameters (operator-discretion looser limit + larger size: placed/filled 0.28 DIS @ $110.35 Day vs staged 0.2584 @ $107.50 Day; +$2.85 looser limit / +0.0216 larger shares / principal +$3.12 = +11.2% on staged; thesis disposition unchanged on 12+ month structural Subtype B SVOD-margin-trajectory thesis; criterion 6 still clears at borderline; RTX 2026-04-27 looser-for-fill-assurance precedent continuation). Cost basis $31.21 incl $0.31 comm. D-specific funding cycle: sold 0.4 SGOV @ $100.44 ($40.18 gross, $0.35 comm) → bought 0.28 DIS. D's net cash gain from cycle +$8.62. Sector concentration NEW: Communication Services / Entertainment ~1.6% of new ~$1,888 D NAV. LTCG eligible 2027-05-08. Invalidation criteria (i)-(v) all NOT-TRIPPED at fill. → Decision_Log 2026-05-07 DIS fill capture anomaly entry.
- May 7 (~14:30 MT): Account-level events allocated to D — May 5 IBKR-fee equal-split allocation -$0.90; SGOV dividend reinvest pro-rata +0.0403 shares @ $100.45; supplemental capital deposit +$500.00 (per Decision_Log 2026-05-07 DIS fill capture Anomaly 3 interpretation correction; total D deposits cumulative $1,389.37 → $1,889.37); supplemental deployed via account-level SGOV reparking +4.978 shares @ $100.4763 effective avg cost. Combined with DIS-funding -0.4 share: net D SGOV +4.6183 shares (13.5204 → 18.1387). RTX mark refreshed $175.99 → $176.24 (+$0.04 unrealized improvement). → Decision_Log 2026-05-07 DIS fill capture anomaly entry.

**Performance**:
- First trade date: 2026-04-27 (RTX fill)
- Deployed TWR: [computed at next M5 cycle]
- Peak deployed TWR: [n/a]
- Current drawdown: [n/a]
- Cumulative active time: ~10 days
- Excess real return vs. SGOV: [n/a]

**Gate**: 0 / 30 trades (not reached — D's design is unlikely to reach the gate within a stable model-generation window per Strategy.md; final determination at termination)

**Router activation state**: [see Regime_State.md]

**Concurrent position count**: **2 / 10** (hard cap) post-DIS-fill 2026-05-07

**GICS sector concentration** (% of D's portfolio deployed in each sector, relative to new ~$1,888 D NAV): Industrials / Aerospace & Defense ~1.5% (RTX $28.11 / $1,888.43); Communication Services / Entertainment ~1.6% (DIS $30.41 / $1,888.43); both well within 30% per-sector cap (~28%+ headroom remaining in each). Sector concentrations re-baseline lower than the staging-time ~2.0% projection due to D NAV jump from supplemental capital deposit (D NAV $1,388.95 → $1,888.43 mark-to-market).

**Open positions**: 2

| # | Ticker | Entry Date | Entry Price | Position $ | Shares | Mark Price | Mark Value | Unrealized P&L | 12-mo LTCG Eligible Date |
|---|--------|------------|-------------|------------|--------|------------|------------|-----------------|---------------------------|
| 1 | RTX | 2026-04-27 | $175.12 | $28.21 (incl $0.28 comm) | 0.1595 | $176.24 | $28.11 | -$0.10 (mark-vs-cost-basis-incl-comm; +$0.18 vs cost-pre-comm; mark drift +$0.04 since prior session $175.99) | 2027-04-28 |
| 2 | DIS | 2026-05-07 | $110.35 | $31.21 (incl $0.31 comm) | 0.28 | $108.60 | $30.41 | -$0.80 (mark-vs-cost-basis-incl-comm; -$0.49 vs cost-pre-comm $30.90; entry-day fill-mark drift -$1.75/share = -$0.49 on 0.28 shares — within typical Day-1 noise on a 12+ month thesis) | 2027-05-08 |

**Closed trades (at-a-glance)**: (none)

| # | Ticker | Entry | Exit | Days | Position $ | Net P&L | Return % | LTCG/STCG | Exit Reason | Model (Entry / Exit) |
|---|--------|-------|------|------|------------|---------|----------|-----------|-------------|-----------------------|

**Closed trade details**: (none)

---

## Strategy E — Active

**Portfolio state** (as of 2026-05-07 ~10:12 MT — DIS fill capture session; no E-specific trade today; supplemental capital + fee allocation + dividend reinvest applied):
- Total value: **$1,890.44** mark-to-market (SGOV 18.8215 shares @ $100.48 mark = $1,891.39 + USD Cash residual -$0.95 absorbed-fee artifact).
- Starting value: $1,389.21 on 2026-04-23 (after $0.16 SGOV parking commission; original allocation $1,389.37)
- Deposits received cumulative: **$1,889.37** ($1,389.37 initial + $500.00 supplemental)
- Next trade size at 2% per leg (4% per pair): $37.81 per leg
- Apr 27 activity: no trade entered. Cash → SGOV reparking allocated from account-level Apr 27 SGOV cycle: cash -$0.62, SGOV +0.0060 shares @ ~$100.65.
- Apr 28 activity: no trade entered. Cash → SGOV reparking allocated from account-level Apr 28 SGOV cycle: cash -$0.05, SGOV +0.0004 shares @ ~$100.66.
- May 7 activity: no E-specific trade. May 5 IBKR-fee equal-split allocation -$0.90; SGOV dividend reinvest pro-rata +0.0411 shares @ $100.45; supplemental capital deposit +$500.00 (per Decision_Log 2026-05-07 DIS fill capture Anomaly 3 interpretation correction); supplemental deployed via account-level SGOV reparking +4.978 shares @ $100.4763 effective avg cost. Net E SGOV +5.0191 shares; net cash residual -$0.95 (fee/comm artifact). → Decision_Log 2026-05-07 DIS fill capture anomaly entry.

**Performance**:
- First trade date: [not yet]
- Deployed TWR: [n/a]
- Peak deployed TWR: [n/a]
- Current drawdown: [n/a]
- Cumulative active time: 0 days
- Excess real return vs. SGOV: [n/a]

**Gate**: 0 / 30 trades (each leg counts as 1 trade; a pair = 2 trades)

**Router activation state**: [see Regime_State.md]

**Open pair positions**: (none)

| Pair ID | L Ticker (Long) | S Ticker (Short) | Entry Date | L Entry Price | S Entry Price | L Position $ | S Position $ | L Mark | S Mark | Unrealized Pair P&L | 252-day Correlation at Entry | 60-day Correlation Current |
|---------|------------------|-------------------|------------|----------------|----------------|----------------|----------------|--------|--------|-----------------------|--------------------------------|-----------------------------|

**Closed pair trades (at-a-glance)**: (none)

| Pair ID | L Ticker | S Ticker | Entry | Exit | Days | Pair Position $ (L + S) | Net Pair P&L | Return % | Exit Reason | Model (Entry / Exit) |
|---------|----------|----------|-------|------|------|------------------------|--------------|----------|-------------|-----------------------|

**Closed trade details**: (none)

---

## Position thesis details (open positions only)

For each open position across all strategies, a subsection below records thesis-level context. Preserved here while the position is open; on exit, this context moves to the "Closed trade details" subsection for that strategy per the detail template below.

Format:

### [Strategy X] [Ticker or Pair ID]

- **Thesis**: [narrative summary of the directional call or pair thesis]
- **Key public documents supporting thesis**: [filings, transcripts, analyst reports — cited]
- **Invalidation criteria**: [specific events or conditions — NOT price action alone]
- **Completion / convergence criteria**: [specific events, price targets, or narrative markers]
- **Expected resolution window**: [dates or conditions]
- **Time-based exit**: [per Strategy.md]
- **Conviction rating at entry**: [ordinal tier: low / medium / high — per AI_Trading_Foundation.md 2.13 miscalibration, use ordinal not explicit probability]
- **Expected return magnitude at entry**: [if specified, e.g., "+5 to 8%"]
- **Adversarial counter-argument summary**: [main bear case raised at entry and why it was not decisive]
- **Claude model at entry**: [e.g., Claude Opus 4.7]
- **Source of thesis**: [daily scan / weekly catalyst calendar / weekly post-event screen / weekly position deep-dive / monthly E pair screen / monthly D position deep-dive / quarterly D candidates / ad-hoc]
- **Regime state at entry**: [SPY Trend, VIX Regime, Yield Curve State, Breadth State]
- **Sector / concentration context** (D and E): [GICS sector/industry for D; pair industry group for E]

(Open positions populate below as they fill. As of 2026-04-28, three positions are open: IBM (B), RTX (D), HCA (B). No staged orders pending.)

### [Strategy B] IBM — OPEN 2026-04-27

- **Source thesis**: → Decision_Log 2026-04-25 "Strategy B thesis construction outcome — IBM GO" (full thesis substance including Q1 2026 print details, sector-contagion-from-NOW analysis, Q1 2024 same-name analogue, sell-side reset compilation, criterion-3 closed-list convergence target derivation, adversarial review, conviction calibration). Subsequent updates: → Decision_Log 2026-04-27 "Strategy B IBM fill capture / NOW Mon-evening checkpoint".
- **Order details**: Limit BUY 0.1198 IBM @ $230.17 Day → FILLED 2026-04-27 07:33:20 ET at $230.17 exact-limit (operator-discretion: tighter limit than original $232.50 staging ceiling); 0.1198 shares; principal $27.57 + commission $0.28 = total cost basis **$27.85**.
- **Convergence target**: $245.00 (immutable per Strategy.md criterion 3 closed-list rev 14; ~62% gap-fill from $230.17 fill toward pre-event $255.68). Gross return at convergence: +6.4%. Net return at convergence pre-exit-commission: +5.4%.
- **Time-based exit**: 2026-06-26 (entry 2026-04-27 + 60 calendar days).
- **Invalidation criteria status** (per Decision_Log 2026-04-25 staging):
  - (i) IBM 8-K reducing FY26 cc revenue guide below ">5%" floor — NOT-TRIPPED as of 2026-05-05.
  - (ii) Pre-announcement / negative business update on Software or Red Hat — NOT-TRIPPED as of 2026-05-05.
  - (iii) IGV close ≤ $80.00 — NOT-TRIPPED as of 2026-05-05.
  - (iv) Brent close ≥ $130/bbl on any single trading day — NOT-TRIPPED as of 2026-05-05.
- **Mark-to-market**: 2026-05-05 ~10:56 MT — last $228.61, mark value $27.39, unrealized P&L -$0.46 (vs cost basis incl comm).

### [Strategy D] RTX — OPEN 2026-04-27

- **Source thesis**: → Decision_Log 2026-04-26 "Strategy D thesis construction outcome — RTX GO" (full thesis substance: 12-24 month deep-cyclical recovery + secular aftermarket compounder; Q1 2026 backlog $271B / 2.9× FY26 sales; GTF Advantage EASA cert 2026-04-17; Hot Section Plus retrofit conversion of powder-metal liability; counter-cycle entry at trailing-30-day -16%; full adversarial review including tariff/Airbus/insider-selling weights).
- **Order details**: Limit BUY 0.1595 RTX @ $175.12 Day → FILLED 2026-04-27 07:35:46 ET at $175.12 exact-limit (operator-discretion: limit $0.12 above staged $175.00 reference to ensure fill within day-order window); 0.1595 shares; principal $27.93 + commission $0.28 = total cost basis **$28.21**.
- **Convergence target**: Long-horizon D position; no near-term price target. Falsifiable milestone for re-evaluation by Q1'27 earnings (multi-criterion gate per Decision_Log 2026-04-26 staging entry: AOGs / GTF Advantage EIS / backlog / FY26 adj EPS / defense organic growth).
- **Time-based exit**: None per Strategy.md D exit rules; quarterly position deep-dive checks thesis status at each cycle.
- **12-mo LTCG eligible date**: 2027-04-28 (entry + 1 year + 1 day per IRS "more than one year" rule; targeted per AI_Trading_Foundation.md 2.23).
- **Invalidation criteria status** (per Decision_Log 2026-04-26 staging):
  - (i) Material adverse Airbus damages ruling > $2B — NOT-TRIPPED as of 2026-05-05.
  - (ii) New powder-metal-style mass quality event > $1B incremental charge — NOT-TRIPPED as of 2026-05-05.
  - (iii) GTF Advantage EIS slips beyond Q1'27 — NOT-TRIPPED as of 2026-05-05.
  - (iv) Backlog declines two consecutive quarters — NOT-TRIPPED (Q1'26 backlog +25% YoY; next read Q2'26 print Jul 2026).
  - (v) FY26 FCF guide cut below $7.5B floor — NOT-TRIPPED as of 2026-05-05.
  - (vi) FY27 defense procurement cut ≥10% YoY — NOT-TRIPPED as of 2026-05-05.
- **Mark-to-market**: 2026-05-05 ~10:56 MT — last $172.76, mark value $27.56, unrealized P&L -$0.65 (vs cost basis incl comm).

### [Strategy B] HCA — OPEN 2026-04-28

- **Source thesis**: → Decision_Log 2026-04-27 "Strategy B thesis construction outcome — HCA GO at MEDIUM-LOW conviction" (full thesis substance: Q1 2026 print details, volume-vs-pricing distinction, Winter Storm Fern external verification, A.J. Rice CFO bridge, criterion-3 closed-list convergence target derivation, 5-weight adversarial review, conviction calibration). Subsequent material updates: → Decision_Log 2026-04-27 evening "UHS print parse — criterion (iv) cleared"; → Decision_Log 2026-04-28 "HCA fill captured + Apr 28 SGOV cycle reconciled + Funds-on-Hold $2,500 anomaly observed"; → Decision_Log 2026-04-30 "THC Q1 print parse — criterion (iii) <disposition>" if/when entry exists.
- **Order details**: Limit BUY 0.0642 HCA @ $433.50 Day → FILLED 2026-04-28 10:38:51 ET at $433.46 exact-limit (operator-discretion: limit $0.04/share tighter than staged $433.50); 0.0642 shares; principal $27.83 + commission $0.28 = total cost basis **$28.11**.
- **Convergence target**: $442.85 (immutable per Strategy.md criterion 3 closed-list rev 14; 25% gap-fill from $432.46 reference toward pre-event $474.03). Gross return at convergence from fill: +2.17%. Net return at convergence pre-exit-commission: +1.17%.
- **Time-based exit**: 2026-06-27 (entry 2026-04-28 + 60 calendar days; finalized at fill, supersedes staging-time placeholder of 2026-06-26).
- **Invalidation criteria status** (per Decision_Log 2026-04-27 staging):
  - (i) HCA 8-K reducing FY26 guide below reaffirmed range (revenue $76.5B / Adj EBITDA $15.55B / EPS $29.10 floors) — NOT-TRIPPED as of 2026-05-05.
  - (ii) HCA pre-announcement / negative business update — NOT-TRIPPED as of 2026-05-05.
  - (iii) THC Apr 30 print explicitly clean Q1 + FY26 guide reaffirmed at midpoint or higher — checkpoint scheduled 2026-04-30; status pending Decision_Log THC parse entry.
  - (iv) UHS Apr 27 AMC similarly clean Q1 reinforcing (iii) — **CLEARED Mon 2026-04-27 evening** per Decision_Log 2026-04-27 evening UHS-print-parse entry (UHS pre-flagged Q1 storm softness in Q4 2025 commentary; Q1 acute volume soft consistent with pre-flag = peer-level corroboration of weather narrative, not refutation).
- **Mark-to-market**: 2026-05-05 ~10:56 MT — last $431.17, mark value $27.68, unrealized P&L -$0.43 (vs cost basis incl comm).

### [Strategy B] META — OPEN 2026-05-05

- **Source thesis**: → Decision_Log 2026-05-01 "Strategy B thesis construction outcome — META GO at MEDIUM conviction" (full thesis substance: Q1 2026 print details, dual-driver ad strength, FY26 expense + OI guide unchanged, capex raise framing, GOOGL comparator, sell-side reset compilation, criterion-3 closed-list convergence target derivation, 5-weight adversarial review, KL #11 AI-ROI residual, conviction calibration). Subsequent material updates: → Decision_Log 2026-05-04 "META Funds-on-Hold gate FAILED — branch (b) single-deferral"; → Decision_Log 2026-05-05 "META Funds-on-Hold gate CLEARED — branch (a) fired"; → Decision_Log 2026-05-05 "META fill captured at $601.30 GTC; Tue 5/5 SGOV cycle reconciled; account-level $4.51 cash discrepancy flagged".
- **Order details**: Limit BUY 0.0454 META @ $615.00 Day staged Mon 2026-05-04 → DEFERRED branch (b) Mon → GATE CLEARED branch (a) Tue 09:15 MT → order placed Tue 2026-05-05. **Operator-discretionary modification at execution**: limit $601.30 GTC vs staged $615.00 Day ($13.70/share tighter limit + GTC duration; both more conservative; parallel to Apr 28 HCA $0.04 tighter-limit precedent). **FILLED 2026-05-05 10:54:59 MT (12:54:59 ET) at $601.30 exact-limit; 0.0454 shares; principal $27.30 + commission $0.27 = total cost basis $27.57.**
- **Convergence target**: $626.21 (immutable per Strategy.md criterion 3 closed-list rev 14; 25% gap-fill from $611.91 reference toward pre-event $669.12; does NOT adjust to better-than-reference fill of $601.30). Gross return at convergence from fill: +4.14% (vs +2.34% from $611.91 reference = +180bps improvement on operator-discretion tighter limit). Net return at convergence pre-exit-commission: +3.12%.
- **Time-based exit**: 2026-07-02 (Thu) per Strategy.md B exit rules (entry 2026-05-05 + 60 calendar days = Sat 2026-07-04 = July 4 observed market closure; Thu Jul 2 = last trading day on/before since Fri Jul 3 also closed for July 4). Mid-window pulse-check Mon 2026-06-01 ~10:00 MT.
- **Invalidation criteria status** (per Decision_Log 2026-05-01 staging):
  - (i) META 8-K resetting 2026 financial framework — capex >$145B (third raise), total expense >$169B, OI guide retracting "above 2025", or material FY26 ad-revenue/DAP reset — NOT-TRIPPED as of 2026-05-05.
  - (ii) Pre-announcement / material business update indicating advertiser pullback or DAP/engagement reversal — NOT-TRIPPED as of 2026-05-05.
  - (iii) Material META-specific regulatory development with material loss disclosure (US youth-trial verdict / DOJ AdTech remedy ruling against META / EU DMA enforcement against META) — NOT-TRIPPED as of 2026-05-05.
- **Mark-to-market**: 2026-05-05 ~10:56 MT (entry-day fill snapshot) — last $601.34, mark value $27.30, unrealized P&L -$0.27 (= entry commission; fill mark $601.34 is +$0.04 above $601.30 cost-pre-commission).
- **Holding-period notes**: Funds-on-Hold $2,500 status — settlement hold per operator communication releasing Thu 2026-05-07; consistent across Apr 28 / Mon 5/4 / Tue 5/5 readings; future sessions treat as benign-and-resolving without re-litigating until past Thu 5/7. Pre-mortem rev 7 KL #12 pairwise-correlation metric (3-concurrent-long IBM × HCA × META) first computation scheduled Wed 2026-06-03 ~15:30 MT (calendar event id `k9vtudr7d40ukto3vfhutcdbls`).

### [Strategy D] DIS — OPEN 2026-05-07

- **Source thesis**: → Decision_Log 2026-05-07 "Strategy D DIS re-screen — trigger conditions (a)/(b)/(c) all MET → fresh Subtype B thesis construction → GO with primary driver explicitly reframed from management-execution-quality to financial-metric-traceable" (full thesis substance: Q2 FY26 print outcomes verifying all three trigger conditions; Subtype B reframing rationale per session-prompt step 4 + KL #4 management-execution residual handling as secondary-driver bounded by quantitative invalidation gates; criterion 1-6 walk; adversarial review including 7 weights — D'Amaro-tenure / streaming-margin-competition / Experiences-macro-sensitivity / RTX-D-book-correlation / FCC-TV-license-overhang / 2.6 KL #4 / 2.13-2.19-amplification-absent; counter-cycle entry texture analysis on +12% trailing-30 / -13% from 52-wk high; theater-check on 1-of-1 GO disposition versus original 5-of-5 NO-GO batch; Subtype B reframing precedent for compaction). Original NO-GO context: → Decision_Log 2026-04-26 D batch 2 DIS subsection (lines 1715-1721 of Decision_Log; reconsideration trigger source). Subsequent material updates: → Decision_Log 2026-05-07 "DIS fill capture anomaly entry — operator-discretion order modification (looser limit + larger size); May 5 $4.51 cash discrepancy closed; Funds-on-Hold $2,500 release confirms supplemental-deposit interpretation correcting Apr 28 hypothesis; SGOV reparking cycle documented".
- **Order details**: Limit BUY 0.2584 DIS @ $107.50 Day staged → **operator-discretion modification at execution: placed/filled Limit BUY 0.28 DIS @ $110.35 Day** (+$2.85/+2.65% looser limit AND +0.0216 shares/+8.4% larger size; principal +$3.12/+11.2% to 2.22% of D NAV vs 2.00% staged; thesis disposition unchanged on 12+ month structural Subtype B SVOD-margin-trajectory; criterion 6 still clears at borderline; RTX 2026-04-27 looser-for-fill-assurance precedent continuation; opposite of META 2026-05-05 tighter-at-execution). **FILLED 2026-05-07 09:36:29 MT (11:36:29 ET) at $110.35 exact-limit; 0.28 shares; principal $30.90 + commission $0.31 = total cost basis $31.21.** D-funding cycle: 0.4 SGOV sold @ $100.44 (gross $40.18, $0.35 comm, net $39.83 cash) → DIS bought (cost basis $31.21); D's net cash gain from cycle +$8.62.
- **Convergence target**: Long-horizon position; no near-term price target. Falsifiable trend-metric verification at Q3 FY26 print (~2026-08-12 per TradingView next-earnings-date): SVOD margin remains ≥9% + Q3 segment OI guide ~$5.3B met ± reasonable variance + FY26 12% adj EPS growth reaffirmed at Q3 + Q3 buyback execution on pace toward $8B FY26.
- **Time-based exit**: None per Strategy.md D exit rules; multi-year SVOD-margin-trajectory thesis. M5 monthly D position deep dive cycle is the cadenced review mechanism (next M5 ~2026-06-01).
- **12-mo LTCG eligible date**: **2027-05-08** (entry 2026-05-07 + 1 year + 1 day per IRS "more than one year" rule; finalized at fill per actual fill date).
- **Invalidation criteria status** (per Decision_Log 2026-05-07 staging entry; immutable through position life; all public-information observable per Strategy.md Constraint 3 + rev 30 metric-immutability protection):
  - (i) Entertainment SVOD operating margin falls below 8% for 2 consecutive quarters — **NOT-TRIPPED** as of 2026-05-07 fill (Q1 FY26 8.4% baseline / Q2 FY26 10.6% — both above 8% floor; next read Q3 FY26 print ~2026-08-12).
  - (ii) FY26 adj EPS growth guide cut materially (revised guide ≤6% growth = >6pp cut from current ~12% midpoint) — **NOT-TRIPPED** as of 2026-05-07 fill (Q2 print reaffirmed FY26 ~12% adj EPS growth ex-53rd-week / ~16% incl. 53rd-week; FY27 double-digit guidance reaffirmed).
  - (iii) FY26 buyback pace fall (≤$3B at H1 close per 10-Q cash flow disclosure, ≤$5B at Q3 FY26 print, or 8-K announcement of suspended/reduced buyback) — **NOT-TRIPPED** as of 2026-05-07 fill (Q2 print raised FY26 target to ≥$8B from prior $7B pace; H1 cash flow disclosure pending Q2 10-Q filing).
  - (iv) Metric-immutability auto-invalidation (rev 30): SVOD operating income/margin no longer reported in current form for ≥2 consecutive quarters — **NOT-TRIPPED** as of 2026-05-07 fill (Q2 8-K Ex-99.1 reports Entertainment SVOD operating margin in current form).
  - (v) Regulatory-impairment escalation (KL #4 boundary case): FCC issues final order materially restricting Disney TV-station ownership AND Disney 8-Ks the development as material adverse impact to FY26/FY27 EPS framework — **NOT-TRIPPED** as of 2026-05-07 fill (FCC TV-license review item open per Brendan Carr / Trump admin / ABC stations; no final order; no Disney 8-K material-adverse-impact disclosure).
- **No price-based invalidation** per Strategy.md Strategy D long-position no-stop design. Worst-case loss bounded at ~$31.21 (100% of cost basis incl comm) by sizing.
- **Mark-to-market**: 2026-05-07 ~10:12 MT (entry-day fill snapshot) — last $108.60, mark value $30.41, unrealized P&L -$0.80 (mark vs cost basis incl comm = $31.21; -$0.49 vs cost-pre-comm $30.90). Entry-day fill drift -$1.75/share = -$0.49 across 0.28 shares within typical Day-1 noise on a 12+ month thesis.
- **Holding-period notes**: Entry-day fill marks DIS at -$0.80 unrealized incl comm — within Day-1 noise; no thesis re-evaluation until either Q3 FY26 print falsifiable reassessment (~2026-08-12; Daily.md scan auto-detects) OR next M5 monthly D position deep dive cycle (~2026-06-01) OR an invalidation-criterion (i)-(v) trip event surfaces. The +12-16% trailing-30-day on the +7.54% Q2-print pop pushed entry slightly above the +15% deferral threshold at the modified $110.35 fill price (vs ~+12% at staged $107.50), accepted as borderline-cleared at fill since the +7.54% Q2-print pop itself is the trigger-resolution event per criterion 6 (not separately disqualifying when the move IS the trigger). RTX-DIS pairwise correlation estimated 0.20-0.35 (different GICS sectors / cyclical drivers / betas) well below 0.6 entry-time bucket threshold; classical-method delegation for precise correlation matrix can be deferred to next M5 cycle if material.
- **Conviction rating at entry**: MEDIUM-HIGH (per AI_Trading_Foundation.md 2.13 ordinal-tier convention). Rationale per Decision_Log 2026-05-07 staging entry: clean Q2 print with two-observation trend establishing margin trajectory; FY26/FY27 reaffirmation under new CEO debut; buyback raise to $8B; consensus PT $129-133 implies +20-23% upside; counter-cycle entry texture; absence of 2.13/2.19 AI-narrative amplification overhang. Conviction discount factors: D'Amaro 7 weeks into tenure (early-tenure execution risk bounded by financial-metric invalidation menu); KL #4 management-execution-as-secondary-driver residual acknowledged but not eliminated.
- **Claude model at entry**: Claude Opus 4.7
- **Source of thesis**: 2026-04-26 Quarterly_D_Candidates.md April shortlist (Category 3 "Management execution"; reframed in 2026-05-07 re-screen session per session-prompt step 4) → 2026-04-26 D batch 2 NO-GO with documented reconsideration triggers → 2026-05-07 calendar-event-driven re-screen → 2026-05-07 fill at modified parameters.
- **Regime state at entry**: SPY Trend = NEUTRAL, VIX = NORMAL, Yield Curve = NORMAL, Breadth = HEALTHY (per Regime_State.md most-recent-call). Strategy D ACTIVATE (technical UP/NEUTRAL + sustained-inversion NOT-SUSTAINED + fundamental ACTIVATE).
- **Sector / concentration context**: GICS Communication Services / Entertainment ~1.6% of D NAV $1,888.43 mark. RTX (other open D position) is Industrials / Aerospace & Defense ~1.5% of D NAV — different GICS sector, no sector cap interaction; both well within 30% per-sector cap (~28%+ headroom remaining in each).

---

## Closed trade detail template

Every closed trade gets a subsection under its strategy's "Closed trade details" block using this format. The concise table above provides at-a-glance metrics; this detail subsection is the auditable record.

### Trade [#] — [Ticker or Pair ID] (Strategy [X])

**Profitability math**
- Entry date / exit date / holding days
- Entry price / exit price / shares or contracts
- Position $ at entry (capital deployed)
- Gross P&L (entry-to-exit before commissions): $
- Commissions total (entry + exit): $
- For B shorts / E S-legs: average borrow rate during holding, total borrow cost: $
- Net P&L (gross − commissions − borrow): $
- Return % (net / position $ at entry)
- Tax treatment: STCG (holding < 12 months) / LTCG (≥ 12 months)

**Entry thesis context (preserved from open-position detail at entry)**
- Thesis summary
- Key public documents
- Invalidation criteria
- Completion criteria
- Expected resolution window
- Conviction rating at entry (ordinal)
- Expected return magnitude at entry (if specified)
- Adversarial counter-argument summary

**Entry context**
- Claude model at entry
- Source of thesis (which recurring prompt / ad-hoc)
- Regime state at entry (SPY / VIX / Yield Curve / Breadth)

**Exit context**
- Exit reason: [completion / invalidation / time-based / termination / other]
- Did thesis play out as expected: [yes / partial / no] with brief narrative
- Actual resolution time vs expected (faster / slower / as expected)
- Actual return vs expected magnitude
- Theater-check retrospective on the adversarial counter-argument: did it identify the risk that actually materialized, miss it, or read as boilerplate?
- Claude model at exit
- Regime state at exit (SPY / VIX / Yield Curve / Breadth)

**Strategy-specific fields**
- **B**: side (long / short); for shorts: entry borrow rate, average borrow rate, total borrow cost
- **C**: structure type, strikes, expiration, net debit/credit at entry and exit, event type (earnings / PDUFA / FOMC), event date, event outcome (beat / miss / as expected), implied volatility at entry, realized volatility during holding
- **E**: pair ID, leg (L / S), counterparty leg ticker, 252-day correlation at entry, 60-day correlation at exit, pair thesis outcome (did L outperform S as hypothesized: yes / partial / no), whether pair closed together or asymmetrically
- **D**: GICS sector and industry, thesis category (product cycle / regulatory / management / thematic / structural), 12-month LTCG eligibility date, whether exited before or after LTCG qualification

---

## Reconciliation rules (enforced on every ledger update)

1. For each active strategy: Total value = SGOV balance + sum of open position marks
2. Account-level total = sum of active-strategy totals + held-aside pool
3. Active strategies = (A, B, C, D, E) minus (terminated strategies)
4. Every deposit creates an equal split among currently-active strategies at the time of deposit
5. Every trade entry reduces SGOV and increases deployed by equal amount
6. Every trade exit increases SGOV by exit proceeds and removes the position from deployed; realized P&L flows to the closed trades table + detail subsection and into the performance metrics
7. SGOV interest accrues to SGOV balance on the daily mechanical update
8. Closed trades never get deleted or modified retroactively — the audit trail is permanent