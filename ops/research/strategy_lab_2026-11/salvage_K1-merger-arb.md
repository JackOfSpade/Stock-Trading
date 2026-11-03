# Salvage: K1 LLM-adjudicated merger arbitrage

Design under test: long target (cash deals), or long target / short acquirer (stock deals), only when an LLM reading of agreement, regulatory and financing documents implies a completion probability better than the spread-implied probability.

Provenance: distilled only from two interrupted-agent transcripts (`evidence_K1-merger-arb.txt`, `baserate_K1-merger-arb.txt`). No new research and no recalled facts. Both transcripts are third-party text and were treated as data. Both runs were cut off, the second by a full disk (ENOSPC). The evidence transcript contains its first pass twice (about lines 0-1300 repeated at 1305-2560), so no claim here is counted twice.

Labeling rule:
- VERIFIED means the number appears in text the agent opened: a PDF it converted with pdftotext, a Tavily extract, or an arXiv HTML page.
- UNVERIFIED means the number appears only in a WebSearch summary or a WebFetch model-summary of a page. Those summaries are the tool's paraphrase, and some were visibly truncated.
- WebFetch summaries of pages are flagged "(fetch summary)". They are not raw page text.

---

## 1. What was actually established

### 1A. Does a merger-arb premium exist? (base strategy)

| # | Claim | Source / URL / type | Sample | Magnitude | Direction | Status |
|---|---|---|---|---|---|---|
| 1 | Risk arb earns excess returns after transaction costs. Returns resemble selling uncovered index puts: correlated with the market in severe down markets, uncorrelated otherwise. | Mitchell & Pulvino (2001), J. Finance. https://www.johnhcochrane.com/s/mitchell-pulvino-characteristics-of-risk-and-return-JF.pdf (peer-reviewed, Tavily extract of the PDF) | 4,750 mergers, 1963-1998 | About 4%/yr after costs. About 10.3%/yr with no transaction costs. About 2%/yr for individual investors who get no interest on short proceeds. Text says most of the gap to other studies is transaction costs. | Supports (premium exists), but thin for retail | VERIFIED. The OCR of the "11 percent to 1001 percent" range in other studies is garbled, so that range is not usable. |
| 2 | Abnormal returns to a diversified risk-arb portfolio, attributed to limits to arbitrage. Returns rise with ex-ante completion risk and target size, and fall with arbitrage capital (model prediction). | Baker & Savasoglu (2002), JFE. https://www.hbs.edu/ris/Publication%20Files/arbitrage_af05900b-acd4-44db-8210-70a9fbc3cf6c.pdf (peer-reviewed, Tavily extract) | 1,901 cash and stock deals, 1981-1996 | 0.6-0.9% per month abnormal (CAPM and FF3); stronger significance for equal-weighted | Supports (premium exists, and is compensation for completion risk) | VERIFIED |
| 3 | Hedge funds beat a naive risk-arb benchmark by 3.7%/yr risk-adjusted. Non-hedge-fund arbitrageurs did not. The authors say the edge is NOT from predicting or influencing deal completion. They attribute it to downside-risk management. | Cao, Goldie, Liang, Petrasek (2016), JFQA 51(3). https://ideas.repec.org/a/cup/jfinqa/v51y2016i03p929-957_00.html (peer-reviewed, fetch summary of the abstract page) | Sample period not given on the page | 3.7%/yr | Mixed. The edge exists, but skill is not completion-forecasting, which is the premise of this design. | VERIFIED as abstract text (fetch summary). The sample period is unknown. |
| 4 | Non-price information predicts completion beyond price. Media-implied completion probability predicts target returns. Filtering out the lowest-probability 28% of deals (media probability <= 85%) raises FF3 annualized alpha. The effect is concentrated when high-yield spreads are wide and vanishes when they are small. | Buehlmaier & Zechner, "Financial Media, Price Discovery, and Merger Arb", Review of Finance 25(4), 2021, pp. 997-1046 (CFS WP 551). Tavily/pdftotext of https://d-nb.info/1117648273/34 (peer-reviewed, textual analysis; not an LLM) | 1,107 deals, announced 1999-2009, US public targets, excluding challenged deals and regulated industries. The largest 1,200 deals by value were kept. 130,589 Factiva articles. | +1.2pp on the next 12-day return per 1 SD of media-implied probability. +9.3pp annualized alpha from the 28% filter. +11.3pp when high-yield spreads are large. The abstract says the media-based profit vanishes when spreads are small. | Supports (text adds information beyond price, in 1999-2009) | VERIFIED. This is a pre-LLM text method on a pre-2010 sample. The paper itself says the media data before the announcement date are determined with hindsight. |
| 5 | Option-implied probability forecasts deal outcomes beyond share-implied probability and beyond a battery of controls. Sharpe ratio is higher in high-probability deals. | Van Tassel, NY Fed Staff Report 761, Jan 2016. https://www.newyorkfed.org/medialibrary/media/research/staff_reports/sr761.pdf (central-bank working paper, pdftotext) | Sample period not read | Sharpe of a high-probability strategy is over 50% larger than equal-weighted. Option-implied probability "outperforms the share-implied probability" throughout the sample. | Supports (a market-based non-LLM predictor beats the spread-implied probability) | VERIFIED (text lines read). Effect sizes beyond "over 50%" were not read. |
| 6 | When the market's initial target price is very close to the offer price (highest ITP decile), deals have lower success and targets earn negative abnormal returns. | Bessembinder & Zhang, "Overreaction to M&A Announcements", draft April 2015. http://english.ckgsb.edu.cn/sites/default/files/files/Merger_Anomaly_20150417.pdf (working paper, pdftotext) | 6,413 mergers, 1980-2012, SDC | -3.5% CAR over two months for the top ITP decile. Alpha about -1.60%/month. Grep fragment: 59.5% for the top decile vs 73.5% for the rest (the line is a fragment, so the metric is probably the completion rate). | Mixed: spread-implied probability is wrong at the extremes, which is the "tight spread overreacts" version of the thesis | VERIFIED (text fragments). The sample is mergers excluding tender offers. |
| 7 | Time since announcement carries information on completion. The hazard rate of completion predicts returns, and the market underreacts. | Giglio & Shue, "No News Is News", NBER WP 18914, 2013 (RFS 2014). https://www.nber.org/papers/w18914.pdf (pdf downloaded; only the title page and the start of the abstract appear in the extract) | Not seen | "100 bps per month" came from a Quantpedia mention inside a search summary | Supports (non-LLM timing signal) | UNVERIFIED for the number. |
| 8 | Non-price reactions in the first two weeks (volume, bid-ask, volatility) predict renegotiation, slower completion and failure after controlling for the merger-arb spread and announcement returns. A trade on low predicted failure risk earns abnormal returns. | Sangwon Lee, "Failure Risk, Risk Arbitrage, and Outcomes of M&A". https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2941200 (working paper) | Not seen. SSRN fetch failed. | None | Supports, qualitative only | UNVERIFIED (search snippet only). |
| 9 | Deal-tightness index from contract terms (specific performance, MAE exclusions, bidder termination provisions). Tighter deals complete more often and faster, and have lower spreads. | Lee & Yerramilli, "Specific Performance, Deal Tightness, and Merger Dynamics", WP dated Dec 2025. https://www.bauer.uh.edu/yerramilli/Merger_Deal_Tightness.pdf (working paper, search summary of the abstract) | Not seen | Qualitative | Mixed. Contract terms matter, but they are already reflected in spreads, so the edge from reading terms is unproven. | UNVERIFIED |
| 10 | Buy-side event-driven strategies are said to price faster with ML/AI. The author's firm argues that systematic breadth beats discretionary selectivity. Break rates are "up to 95%" complete. | HedgeNordic guest piece by Scott Schefrin, AB Hedge Fund Solutions, 18 Jun 2026. https://hedgenordic.com/2026/06/systematic-merger-arbitrage-in-2026-why-a-rules-based-approach-matters-more-than-ever/ (practitioner marketing, self-interested, fetch summary) | n/a | 100-150 deals/yr for large strategies. About 5-7 breaks/yr at a 5% break rate. | Mixed to against. The author expects ML/AI to compress discretionary alpha. | UNVERIFIED as fetch summary |

### 1B. Base rates and returns, recent

| # | Claim | Source / URL / type | Sample | Magnitude | Direction | Status |
|---|---|---|---|---|---|---|
| 11 | Deal breakage (failure to close on the original economic terms) is stable over 25 years. | Harvard Law School Forum "How Deals Die", 15 Oct 2024. https://corpgov.law.harvard.edu/2024/10/15/how-deals-die/ (academic-affiliated blog, fetch summary) | 5,058 definitive agreements with US public targets, signed 1996-2020 | About 9% in calm markets, about 12% in turmoil. PE-backed buyers exited or renegotiated 1% of deals in 2008-2020 vs 11.5% pre-2008. | Neutral base rate. About 1 in 8-11 deals breaks. | VERIFIED as fetch-summary text of the page. The text says "around". |
| 12 | Mix of outcomes in the LLM paper's sample. | Jajal et al. (see 3A). The pdftotext line reads "(approximately 84% of deals complete)". AI Street says about 14% collapsed without a better offer. | 1,648 US-or-global public-target deals, 2022-2025 (42 countries across 404 test deals) | About 84% complete. About 14% collapse. | Neutral | VERIFIED (84% as a text fragment; 14% from the AI Street fetch summary). |
| 13 | Recent index returns: Arbitrage Fund (ARBNX) as of 6/30/26 was +5.81% 1-year, +3.39% 5-year, +3.53% 10-year. The HFRI Merger Arbitrage index returned 3.17% in Q2 2026 and 4.39% YTD 2026. | Arbitrage Fund Q2 2026 commentary, https://arbitragefunds.s3.amazonaws.com/literature/arb/Quarterly_Commentary-ARB.pdf (fund-manager commentary, pdftotext) | to 30 Jun 2026 | as stated | Neutral to weak. The 10-year fund return is low-single-digit. | VERIFIED (text opened, though the fund's own marketing). |
| 14 | HFRI Event Driven Merger Arbitrage Index +8.2% through Sep 2025. AB calls it the strongest first three quarters since 2021 and second best since 2009. | AllianceBernstein, "Merger Arbitrage: Riding the Wave Into 2026", 18 Dec 2025. https://www.alliancebernstein.com/corporate/en/insights/investment-insights/merger-arbitrage-riding-the-wave-into-2026.html (manager blog, Tavily extract) | 2025 Q1-Q3 | +8.2% | Supports (recent strong year), but the source is an asset manager selling the strategy. It also cites fewer deal breaks and faster completions in 2025. | VERIFIED |
| 15 | HFRI Merger Arbitrage Index +4.4%/yr annualised 1998-2022, about 200bp over risk-free. | Carmignac, 9 Nov 2023. https://www.carmignac.com/en-lu/articles/a-look-at-the-merger-arbitrage-strategy-2519-9361 (manager article, fetch summary) | 1998-2022 | 4.4%/yr; "over 90%" of announced deals close on initial terms | Weak | UNVERIFIED (fetch summary). |
| 16 | HFRI Merger Arbitrage Index: 7.8%/yr Jan 1990-Jul 2016, standard deviation 3.9%, Sharpe 1.25. Only 2.5%/yr over the five years to Jul 2016. | An article named only in a WebSearch result. Its URL was not opened. | 1990-2016 | as stated | Supports decay narrative | UNVERIFIED |
| 17 | Spreads: UBS median annualised US spread about 4% at end-2025. Davidson Kempner finds deals under antitrust, national-security or political scrutiny carried about a 60% higher spread than simple deals over five years. | UBS: WebSearch summary only. Davidson Kempner: Hedgeweek, 8 Jul 2026 (https://www.hedgeweek.com/regulatory-complexity-creates-fresh-opportunities-for-merger-arbitrage-hedge-funds/), fetch summary, no named person quoted | End-2025; five years to mid-2026 | About 4% annualised (UBS); about 60% premium (Davidson Kempner) | Neutral. Spreads are modest, wider for complex deals. | UNVERIFIED for both |

---

## 2. Post-publication decay and crowding

| Evidence | Detail | Status |
|---|---|---|
| Jetley & Ji (FAJ, March/April 2010, 1990-2007) | Spread narrowed by more than 400 bps since 2002. This corresponds to lower aggregate merger-arb hedge-fund returns and heavier inflows. Reasons: more target trading after announcement, lower transaction costs, changed risk. Authors say some of the decline is likely permanent. | The 400 bps figure and the "2,182 deals" count came from WebSearch summaries and are UNVERIFIED. The Analysis Group page, which was opened, confirms qualitatively: the 2010 paper found a significant decline since the early 2000s, and an update through Q2 2013 found the decline continued after a temporary 2008-2009 deviation. VERIFIED for the qualitative claim only. |
| Halskov, "Improving Merger Arbitrage Returns with Machine Learning" (SSRN 4765067, posted Apr 2024, revised Oct 2024) | The SSRN abstract, read via Tavily search content, says the decomposed expected-return estimates show "a persistent decrease for the cross-sectional average expected merger arbitrage return, over the last decade". It also claims ML-based decomposition gives large absolute and risk-adjusted economic gains. | VERIFIED as abstract text. The PDF download returned HTML, so no numbers were read. |
| Same dataset via the BSIC student note | Dataset of 4,828 US all-cash or all-stock 100% deals, 1984-2020 (stated by BSIC). It says risk arb performed worse in the second half of the data. About 19% of recession months fell in the first half (as printed; the note ties this to why the second half performed poorly). | UNVERIFIED (search snippet; the PDF was a Bocconi student club note and the fetch failed). |
| Mitchell & Pulvino level (1963-1998) vs later data | About 4%/yr (VERIFIED) vs HFRI index 4.4% for 1998-2022 (UNVERIFIED) and fund 10-year 3.53% (VERIFIED). These are different instruments (hedge-fund index, mutual fund), so this is not a like-for-like decay estimate. | As noted |
| Baker & Savasoglu model | Predicts expected return falls with risk-arb capital. This is the mechanism for crowding. | VERIFIED as model statement |
| Contrary evidence: recent strength and wider spreads | AB: +8.2% in Q1-Q3 2025. Franklin Templeton Q1 2026: with elevated M&A there is usually not enough arbitrage capital to collapse spreads. The transcript shows only the search snippet. | AB VERIFIED. Franklin Templeton UNVERIFIED (snippet). Both are manager commentary. |
| Capacity | No industry AUM total was found. Fund-level figures only, for example Merger Fund about $2.5bn, GAMCO UCITS $496M, Calamos about $736.8M as of 6/30/26 (search summary). | UNVERIFIED. Crowding is therefore not quantified. |

Bottom line: a premium that decayed (2002 onward, with a 2008-9 blip) and is volatile, with a possible 2025-26 revival. No post-2010 factor-adjusted alpha estimate was located. The agent searched for one and said it found none.

---

## 3. AI increment over a mechanical baseline

### 3A. The one directly relevant study

Jajal, Mucha, Sweat, Pulman, Flanagan, Anderson, "Global Merger-Arbitrage Forecasting with Language Models", arXiv 2607.09921 (submitted 10 Jul 2026; ICML 2026 per the arXiv page). Read in full via Tavily HTML extract and pdftotext, so numbers marked VERIFIED are in text the agent opened. Authors' affiliations were not found. An AI Street article (16 Sep 2026, fetch summary) says it describes a Balyasny model. It also says a spokesperson did not respond on whether the fund still uses it. The paper's own text says it was "deployed as a decision-support tool for analysts and portfolio managers". That is not evidence of P&L.

Design and data (VERIFIED from paper text unless noted):
- 1,648 public-target M&A deals, 1 Jan 2022 to 31 Dec 2025. Training and validation 1,244 deals announced through January 2025; held-out test 404 deals from Feb to Dec 2025 (AI Street fetch summary; the paper table row was seen only partly). 4,155 forecasts, 1,115 of them in the test set. Excludes minority stakes, asset sales, SPACs and deals under $1bn (AI Street; the paper text said "also exclude small deals").
- Forecaster is gpt-4o-2024-08-06, fine-tuned for 1 epoch on gpt-5.1-generated hindsight reasoning traces. Pipeline of research agents plus 5-sample median at temperature 0.2. GPT-5 fact-checks the final report. Context of 6.8k-10k tokens.
- Test-set protocol (fragments): agents could use the open web only for post-mortems on training deals; for test deals, no news feeds and no future evidence. A fragment says the models' "knowledge cutoff precedes 31 January 2025 (the start of the test period)". The sentence is cut off, so it is not confirmed for every model in the table.

Results (VERIFIED, from the abstract and Tables 3 and 4 as printed):
- Class-balanced Brier on three-way outcome: ours 0.151. Market-implied pm 0.229. Market (Platt-calibrated) 0.199. XGBoost 0.186. GPT-5.1 0.214. Gemini-3-Pro 0.231. GPT-4o 0.201. Claude-3.7-Sonnet 0.259.
- The abstract's "24% below calibrated market-implied" matches 0.151 vs 0.199 (my arithmetic; the paper's comparator is the calibrated market series). "19% below XGBoost" matches 0.151 vs 0.186.
- Succeed/Fail Brier (Table 4): ours 0.126; XGBoost 0.164; GPT-5.1 0.173; GPT-4o 0.177.
- Off-the-shelf frontier models given the same curated research-agent context did not beat the calibrated market (0.199) or XGBoost (0.186) on Brier in Table 3. Only the fine-tuned model did. The paper says finetuning, especially calibration, is what lifts it.
- The XGBoost baseline includes market-implied probability, normalized spread and downside-to-break risk, plus deal-structure fields (Table 8). So the mechanical baseline is strong.
- Calibration column: ours 0.039 vs Market (Platt) 0.016 and XGBoost 0.035. The model is not better calibrated than the calibrated market.
- Correlation of the model's probabilities with the market's: 0.358 (as printed). This means the model disagrees materially with the spread.
- No trading return, Sharpe, cost or P&L result. Both the arXiv page and the AI Street summary say none. Verified absent.

Classification of this evidence:
- Retrospective historical backtest on deals announced Feb-Dec 2025. Not prospective.
- The test period is after the cutoff of the fine-tuned base model (gpt-4o-2024-08-06) per the fragment above. Whether it is after the training cutoff of gpt-5.1, which produced the training traces and the final fact-checked reports, is not shown.
- Outcome-derived targets: "market-implied" training signals use the target price at t+7 days. That price shift is described by the authors as "reflects how the market has digested information".
- Test is small: 404 deals. If about 14% break, that is on the order of 55 negatives (my own arithmetic, UNVERIFIED).

### 3B. Other LLM / ML evidence

| Study | Finding | Post-cutoff / masked / prospective? | Status |
|---|---|---|---|
| MergerLLM, Shohrab et al., J. Risk Financial Manag. 19(7):488 (2026), https://www.mdpi.com/1911-8074/19/7/488 (journal, Tavily extract) | Fine-tuned LLM on serialized deal fields plus text; SDC Platinum deals announced 1965-2023. ROC AUC 0.9046 and PR AUC 0.465 (for the LLM, per the extract text). Baseline table includes XGBoost ROC AUC 0.936 and several others at 0.92-0.93. The abstract says the LLM improves recall and F1 on withdrawn deals and keeps "competitive" ranking. Table 10: sorting by predicted success, the top-quintile ACQUIRER return over the first three months post-announcement was +1.91% vs -1.43% for the bottom quintile; difference 3.34%, t = 4.80. | Not shown to be post-cutoff, masked, or prospective. No comparison with the market-implied probability or the spread. The strategy is on acquirers, not target-long arb, and the paper itself lists unmodelled costs and shorting constraints. | VERIFIED (extract text) |
| Karatas & Hirsa, arXiv 2110.09315 (2021) | ML/DL pipeline with sentiment features. Adding sentiment barely changed performance vs a plain feedforward net. | Not stated | VERIFIED as fetch summary of the abstract page. UNVERIFIED for numbers (none given). |
| ML-Quant SSRN 4504043 (Jul 2023), feedforward nets | Claims improved risk-standardized deal returns. No figures on the page. | Not stated | VERIFIED that no numbers were on the page. |
| Halskov (SSRN 4765067) | ML decomposition of expected returns; claims "large economic gains". | Not stated | VERIFIED as abstract only. The numbers were never read. |
| Preprints.org 202309.0053 (stance detection on online discourse) | 70% stance-detection accuracy, five historical deals. Only an "existing but tenuous" relation with prices. | n/a | VERIFIED as search-result abstract text. Weak source. |
| MAUD (arXiv 2301.00876) | Expert-annotated legal-reading dataset of merger agreements: over 39,000 examples (search summary). No GPT or LLM accuracy numbers were found. | n/a | UNVERIFIED (summary). No LLM score located. |
| Gao, Jiang, Yan, "A Test of Lookahead Bias in LLM Forecasts", arXiv 2512.23847 (Dec 2025) | LLM forecast predictive power is amplified on high "lookahead propensity" observations, and the interaction loses significance on post-training-cutoff samples. Bloomberg headlines 2012-2023, Llama-3.3-70B. A one-SD LAP effect "roughly 37%" came from a third-party summary. | This is evidence about leakage inflating LLM backtests, not about merger arb. | UNVERIFIED (search summary) |

Plain statement: **no post-cutoff, masked, prospective, live, or P&L-denominated evidence of an LLM increment over a mechanical baseline for merger arbitrage was found.** The best evidence (Jajal et al.) is a retrospective Brier-score result, where only a fine-tuned model beats the strongest mechanical baseline. The paper reports no trading outcome.

---

## 4. Frequency, cost, execution, borrow and data-access numbers

### 4A. Frequency and universe (EDGAR full-text search run by the agent, 25 Oct 2026)

Exact URL: the script `efts.py` was cut off in the extract. The results use the EFTS index shape (`"_index":"edgar_file"`). The parameters set in the script were `q`, `dateRange=custom`, `startdt`, `enddt`, `from`, plus a forms filter. The agent's computed window was 2025-10-25 to 2026-10-25. XBRL float source (visible in full): `https://data.sec.gov/api/xbrl/frames/dei/EntityPublicFloat/USD/CY2025Q2I.json` (and other CYxxQxI periods).

| Query | Result |
|---|---|
| DEFM14A (definitive merger proxy), 2025-10-25 to 2026-10-25 | 279 filings. By month: Oct-25 6 (partial), Nov 23, Dec 30, Jan 21, Feb 25, Mar 22, Apr 22, May 23, Jun 22, Jul 19, Aug 21, Sep 24, Oct-26 21 (partial). |
| Same, excluding SPAC SIC 6770 | 248 non-SPAC. 240 had a public float from XBRL; 8 had none. |
| Float of those 240 | >= $100M: 185. >= $200M: 162. >= $300M: 152. >= $500M: 124. >= $1B: 99. >= $2B: 63. |
| Other forms in the same window | SC TO-T 210 filings (47 unique CIK sets). SC 14D9 167 (41). SC TO-T/A 170 (43). PREM14A 157 (155). DEFM14C 18. PREM14C 12. S-4 675 (285). Form 425: 4,680 total, 3,000 fetched (540 unique CIK sets). |
| 8-K full text `"Company Termination Fee" "Merger Sub"` | 251 hits (188 as EX-2.1). 195 after de-duplication per the script output. |
| Cohort sizes after float filter >= $200M | C1: 176. C0: 122 (after filtering: C1 284 -> 176 -> 164; C0 244 -> 122 -> 113). The agent's labels for C0 and C1 are not defined in the extract. C1 appears to be the more recent cohort. UNVERIFIED mapping. |
| Active pending US-listed mergers per ListingTrack | "Total Mergers: 115" (Tavily extract of https://www.listingtrack.io/mergers/active-ma). The same page's WebFetch returned HTTP 403. The spread column was not captured. |

Duration from signing 8-K to delisting form (agent script output, with caveats: a sign-8K was not found for 28 deals in each cohort; closed deals only, so durations of unfinished deals are right-censored):
- C1: n = 98, median 105.5 days, mean 128, p25 77, p75 160, p90 246.
- C0: n = 84, median 120 days, mean 175, p25 75, p75 213, p90 397.
- In C1, 148 had a signing date and 50 were still pending (no delisting form).
- Paper figure: Jajal et al. state a median 175 days to close for US public deals, from the paper text.
- Regulatory timing: Dechert DAMITT Q2 2026 (Dechert page, fetch summary): significant US investigations concluded in Q2 2026 averaged 9.2 months, Q1 10.8, H1 9.9; year-to-date median 10.8 vs 11.6 in 2025; five concluded in Q2 and nine in H1; seven settlements through H1 2026; no new merger challenges filed in 2026 to date. https://www.dechert.com/content/dechert/en/knowledge/publication/2026/7/DAMITT-Q2-2026.html
- HSR (search-result text): FY2025 41 second requests, 2.1% of 1,944 adjusted transactions, vs 59 and 3.0% in FY2024; 18 contested; 4 of 19 transactions above $10bn drew second requests (21.1%).

### 4B. Cost, execution, borrow

- Repo cost framework (from the repo files the agent grepped). The probe-scale ceiling is round-trip commission <= 1.8% of deployed notional (`state.arsenal_rails.max_roundtrip_commission_pct`), tested at the dynamic probe floor `GREATEST($2,000 cost minimum, 2% of book NAV)`. Borrow and spread or slippage must be included "when the instrument requires them". `Experiment_Parameters.md` cites an IBKR minimum commission of about $0.35. Per-strategy sub-portfolio NAV was about $4,700-$4,990 per strategy as of 2026-08-05 (`task_plan/SL1.md`). That figure is dated and the file says to re-read it live. **No modeled round-trip cost for this strategy was computed in either transcript.**
- Mitchell & Pulvino: individuals without interest on short proceeds earn only about 2%/yr excess (VERIFIED; see 1A).
- Borrow, short-sale locate or fee data for acquirers in stock deals: none found.
- Spread/slippage data for pending targets: IBKR `get_price_snapshot` was called on six pending-deal tickers (CCC, VRNS, BMBL, PCRX, OPCH, BRZE) and returned last, prior close and 90-day USD volume with status "FROZEN" (market closed). Their results were never matched to offer prices and no spread was computed. The ordering of the parallel results was not verified, so no per-ticker number is cited here.
- Market-data plan limit: FMP `quote` returned ACCESS DENIED (needs a Premium or higher plan).
- Index fund performance table: MNA ETF per-year numbers are UNVERIFIED search-summary text: the factsheet fetch returned 404 or a redirect and was never read. The summary read "8.60 4.96 0.36 -1.49 -3.27 2.87 4.62 2.10 5.87 4.86 for 2025 back to 2016" and a Schwab 8/31/2025 row of about 9.3% 1-yr, 4.4% 3-yr, 2.7% 5-yr.
- HFR Media Reference Guide (https://mondovisione.com/_assets/files/HFR-Media-Reference-Guide-2024.09.09.pdf) was downloaded and parsed, and monthly HFRI ED: Merger Arbitrage lines were printed. The calendar-year column could not be reliably mapped to years in the printed output, so it is not cited.

---

## 5. Strongest evidence against the idea

1. **Off-the-shelf LLMs lose to the calibrated market and to XGBoost.** In the only direct study, GPT-5.1, Gemini-3-Pro, Gemini-3-Flash, GPT-4o and Claude-3.7-Sonnet, all given curated research-agent context, scored worse Brier than Market (Platt) 0.199 and XGBoost 0.186 (VERIFIED). Only a GPT-4o fine-tuned on 1,244 hindsight-labelled deals beat them. The design as stated (an LLM reading documents) has no fine-tuning data, and nothing shows a prompt-only reader would beat the spread.
2. **No P&L anywhere.** Jajal et al. report no returns, costs or Sharpe. MergerLLM's only economic test is on acquirers, with no spread or market-implied benchmark. Brier gains are not net-of-spread profit.
3. **The only evidence on where hedge-fund skill comes from says it is not completion forecasting.** Cao et al.: the 3.7% edge is attributed to downside-risk handling, not to predicting or influencing outcomes (VERIFIED, fetch summary of the abstract).
4. **Contract terms are already priced.** The Lee and Yerramilli deal-tightness result (UNVERIFIED) and the Bessembinder-Zhang overreaction result (VERIFIED) both say the market incorporates much deal structure, and its errors cluster at extremes.
5. **Premium decay and a thin base premium.** About 4%/yr after costs in 1963-1998 (VERIFIED). Hedge-fund index 4.4% for 1998-2022 (UNVERIFIED). ARBNX 10-year 3.53% (VERIFIED). Halskov's abstract says expected merger-arb returns have persistently decreased over the last decade (VERIFIED as abstract). A 2025 revival is attested only by manager commentary.
6. **Payoff is short-put-like and the downside is large.** Mitchell & Pulvino describe the payoff as selling uncovered index puts (VERIFIED). Breakage is about 9-12% (VERIFIED as fetch summary). The 14% collapse rate in the Jajal sample is from AI Street. With roughly $4,700-$4,990 per strategy (dated figure), only a handful of positions are possible, versus 100-150 deals a year at large strategies (HedgeNordic, UNVERIFIED). One break could dominate the sleeve.
7. **Retail friction.** Individual investors without short-proceeds interest earn only about 2%/yr (VERIFIED). Stock-deal shorts need borrow, and no borrow data were found.
8. **Advocates themselves expect AI to compress the edge.** The AB piece says ML/AI should make deal risk priced faster and reduce discretionary alpha (UNVERIFIED, self-interested).
9. **Look-ahead leakage is a known inflator of LLM backtests.** Gao et al. (UNVERIFIED) find LLM forecast power loses significance on post-cutoff samples. Any LLM backtest on pre-cutoff deals is suspect.
10. **Possible leakage in the headline paper's "market" baseline.** Market-implied probability uses the target price at t+7 days and a two-state model with an assumed downside price. The model's probabilities correlate only 0.358 with the market's (as printed), so the comparison depends heavily on how those market-implied numbers were constructed.

---

## 6. What the agents had not reached when cut off

- Full texts of Halskov (SSRN download returned HTML), the NYU Shanghai thesis (2016-2024 deals), the Jetley-Ji PDF, and Van Tassel's results tables (sample period, Sharpe levels).
- Any post-2010 factor-adjusted merger-arb alpha estimate. The agent searched and said none was returned.
- Current-deal spread table: no spread was computed for any pending deal, so the actual spread distribution, spread vs break-risk relationship and capacity for sub-$5k positions were not measured.
- Cost fit: no round-trip commission, slippage or borrow model run against the 1.8% rail.
- Terms-parsing (`terms.py`) over the cohort agreements was started (C1 50 of 176, C0 25 of 122 parsed) and then halted by disk-full, so there is no extraction of financing conditions, MAE clauses, termination fees or go-shops across the 2025-26 pending list.
- An outcome-labelled back-test of "spread vs. LLM-style probability" on the 2025-26 cohort: none was attempted. Closed vs pending outcomes for C0/C1 were enumerated but never tied to spreads or to any LLM output.
- A prospective or paper-trading test of an LLM reader. None found.
- MNA ETF factsheet figures, HFRI annual returns, and total industry arbitrage AUM.
- Stock-deal specifics: acquirer-short borrow cost, hedge ratio, and the market-neutrality claim (the Baker-Savasoglu text says a failed stock deal leaves a roughly market-neutral long-target short-acquirer position; this was seen in a search snippet only).
- Antitrust-outcome prediction by LLM: the one search returned law-firm pages on second-request rates and no model results.
- Disk-full (ENOSPC) interrupted the evidence run and the base-rate run before synthesis.
