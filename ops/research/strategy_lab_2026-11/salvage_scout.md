# Salvage: scout_missed-ideas (AI-edge mechanisms beyond K1-K6)

Source: /private/tmp/claude-501/-Users-jack--claude-spares-spare-YOT00C/df96b944-d471-4a74-83f8-15366b3d403b/scratchpad/extract/scout_missed-ideas.txt (299 lines, read in full; several long lines were already truncated by the extractor).

Brief: low-attention, capacity-limited mechanisms that work with once-a-day decisions and next-open market orders.

Labelling rules used here:
- VERIFIED = the number appears in text the agent actually opened (a WebFetch result, a tavily_extract result, or a Bash command output). A WebFetch result is a model-written summary of the page, not the raw page, so "VERIFIED (fetch summary)" is the strongest grade available.
- UNVERIFIED = the number appears only in a search-result snippet, or the agent never opened the page. This includes every Tavily search snippet.
- The agent ran no analysis of its own beyond one EDGAR form-count. It never wrote a conclusion. Everything below is raw evidence, not a verdict.
- This is a read of the transcript only. Nothing was added from outside it.

## Headline

Status per the salvaged evidence: weak / insufficient-research. Not one candidate has a verified, post-cutoff, tradable, net-of-cost return, and no AI increment over a mechanical baseline was measured anywhere. The only verified return figures are for two old or decayed anomalies (post-reorg equity, spin-offs).

## 1. What was actually established

| # | Claim | Source and URL | Source type | Sample period | Magnitude | Direction | Status |
|---|---|---|---|---|---|---|---|
| 1 | Post-reorg equity outperformed on average, but the median abnormal return was zero (gains from a small right tail). Outperformance concentrated in OTC stocks. Roughly +40% to +50% mean abnormal return in the 200 days after emergence. | Jiang, Wang, Yang, "The Disappearing Outperformance of Post-reorg Equity", via Duke FinReg blog https://sites.duke.edu/thefinregblog/2021/09/17/has-post-reorg-equity-outperformed-in-the-last-three-decades | Blog summary of an academic paper, opened by WebFetch | Chapter 11 filers 1981-2016, returns tracked to end 2019 | 200-day mean about +40% to +50%; calendar-time equal-weighted monthly rebalanced portfolio (20 stocks) from Jan 1992 beat benchmark by 7.2%/yr | Mixed, mostly refutes for the present: effect gone after 2010 | VERIFIED (fetch summary). Firm count not stated. |
| 2 | Same paper, time variation: alpha was 0.8-1.2% per month in 2000-2010 and zero afterward vs the five-factor benchmark. Exchange-traded stocks had negative alpha in 2010-2019. | Same URL | Same | 2000-2019 | 0.8-1.2%/month then 0 | Refutes for post-2010 | VERIFIED (fetch summary) |
| 3 | Post-reorg predictors: management stock options in the plan and hedge-fund or PE debtor-in-possession financing predicted higher returns. Business change did not. | Same URL | Same | 1981-2016 | Not quantified in the summary | Supports only as a cross-sectional filter | VERIFIED (fetch summary), no magnitude |
| 4 | Verdad: 49 emerged companies with market cap above $100M (of 93 relisted 2008-2019). 1-year average return 19.8% vs 11.2% for Russell 2000; 1-year median -15%, 25th pct -62%, 75th pct 46%. 2-year median -35%, 25th pct -76%, 75th pct 65%. About 22% lost more than 80% within 2 years. Average 2-year return by EBIT yield: below 0% = -21%, 0-20% = -5%, above 20% = +61%. | Hartranft, "Post-Reorg Equities", Verdad, published Aug 17, 2020. https://verdadcap.com/archive/ymo55pidxxqf34wns523ph1vkvp0e8 | Practitioner blog, opened by WebFetch | 2008-2019 | See left | Mixed. Mean beats, median is a large loss. Only the high-EBIT-yield bucket is positive. | VERIFIED (fetch summary). Small n, no costs, no borrow, ends 2019. |
| 5 | Odd-lot tender priority exists only if the offer document says so. Common in US issuer self-tenders. Risks: amendment or withdrawal, Dutch-auction price settling low, stock falling during the offer, brokers failing to transmit the odd-lot election, commissions and settlement costs. The page gives no typical return and no annual frequency. | https://specialsitsdigest.com/odd-lot-tender-offers (page dated Oct 18, 2026) | Specialist-site blog, opened by WebFetch | Snapshot Oct 2026 | Page header says 117 open offers and also "54 tender offers this week" (the fetch summary flagged the conflict). No count of odd-lot ones. | Mixed. Mechanism is real but no return evidence. | VERIFIED for the qualitative claims. No return number exists. |
| 6 | An odd-lot tracker listed 9 offers. Among the 4 US tender-category offers (RBNE, WIX, LEN, WEX) only Lennar/Millrose mentions an odd-lot provision (99 shares or fewer not prorated). Indicative gross returns: RBNE 67.6%, Docebo 6.9% (Canada), TTSH 3.9% (going private), LEN about 6.4% (page figure), Air Canada 6.3%-20.9% (Canada, range), Frontera 47.4% (Canada, completed). The fetch tool computed the returns from listed prices. The page states no per-year counts. | https://oddlotarbitrage.com/tender-offer-tracker | Commercial tracker, opened by WebFetch | Listed expiries Oct 2024 to Sep 2026 | See left | Mixed. Gross spreads are not net of cost, many listings are stale or non-US. | VERIFIED (fetch summary) for the table. Returns are model-computed, not stated by the site (except LEN). |
| 7 | EDGAR full-index form counts, per quarter, SC TO-I: 150 (2025Q4), 151 (2026Q1), 149 (2026Q2), 156 (2026Q3). SC TO-I/A: 173, 206, 187, 186. SC TO-T: 19, 22, 26, 12. SC 13E3: 10, 7, 8, 11. SC 14D9: 9, 12, 13, 6. SCHEDULE 13D: 2920, 2738, 2688, 2492. Form 425: 1984, 1584, 1546, 1450. DEFM14A: 70, 68, 67, 64. NT 10-K: 39, 310, 187, 56. NT 10-Q: 323, 74, 324, 245. | https://www.sec.gov/Archives/edgar/full-index/{2025/QTR4,2026/QTR1,2026/QTR2,2026/QTR3}/form.idx (downloaded with curl and a research-bot user agent) | Primary source (SEC), agent's own awk count | 2025Q4 to 2026Q3 | See left | Neutral. These are filing counts, not opportunity counts. | VERIFIED (Bash output). Counts every filing of the form, including amendments and filings already on the same issuer. SC TO-I is not filtered to odd-lot-priority offers. The 2026Q3 file header said "Last Data Received: March 31, 2026" for the first file printed (2025Q4 download shown); the agent did not check whether QTR3 was complete. |
| 8 | FDA CRL publication is a real, if interrupted, data source. July 2025: more than 200 letters published. Sept 4, 2025: 89 further letters and a commitment to real-time publication with company names. FDA reportedly paused real-time publication in April 2026 after a citizen petition. Resumed July 10, 2026 with 14 letters. As of Aug 13, 2026, FDA's API reported 458 CRL records. A rulemaking (RIN 0910-AJ16) targeted an October 2026 proposal. | https://intuitionlabs.ai/articles/fda-complete-response-letters-dataset (published 9/5/2026), opened via tavily_extract. Cross-check https://www.biospace.com/fda/fda-freezes-crl-trove-as-radical-transparency-push-hits-speedbump via WebFetch. | Vendor article plus trade press | 2025-07 to 2026-08 | 458 letters total; 14 new after the pause | Supports data availability, refutes dependability of timing | VERIFIED (extract and fetch summary). The BioSpace fetch summary said the FDA did not freeze publication per a July 23, 2026 HHS statement, and that a citizen petition response was due about Oct 17, 2026 with none posted as of the article. Whether releases are truly real-time was explicitly NOT answered. |
| 9 | Stock reactions to CRLs: study of 222 CRL events across 124 firms, 2010-2025, CAR around issuance. | SSRN https://papers.ssrn.com/sol3/papers.cfm?abstract_id=6027774 and GitHub https://github.com/pmuralithara-oss/crl-market-impact-study | Working paper (SSRN abstract), repo README | 2010-2025 | None obtained | Unknown | UNVERIFIED. SSRN returned 403. The repo README gave no CAR, deficiency-type split, drift, or sample figures. The "222 events, 124 firms" line comes from a search snippet only. |
| 10 | Cohen, Diether, Malloy, "Legislating Stock Prices" (NBER w18291): snippets show tables including Long-Short alphas, e.g. "Signing for High Lobbying Industries Only" Carhart alpha 0.58 (t 1.27) and Fama-French 0.44 (t 1.04); another panel Long-Short average return -0.01. | https://www.nber.org/system/files/working_papers/w18291/w18291.pdf | Academic working paper, search snippet only | Not shown | Mixed snippet fragments, mostly insignificant t-stats | Looks weak or null in the fragments shown, but panel identity is unclear | UNVERIFIED. Never opened. The row labels in the snippet are fragmentary and the agent did not map them to the main result. Do not use. |
| 11 | Post-bankruptcy equity offerings: BHAR vs size/SIC-matched firms: 1 month +5.10% (n=65), 12 months +18.55% (n=55), 36 months +48.64% (n=32). | Jory & Madura, "Equity Offerings by Firms That Emerged from Bankruptcy", https://digitalcommons.pepperdine.edu/cgi/viewcontent.cgi?article=1025&context=jef | Journal article, search snippet only | Not shown | See left | Supports (for offerings, not general emerged equity) | UNVERIFIED (snippet). Sample period not shown, and this is equity offerings, a different object from item 1. |
| 12 | Spin-offs (McConnell et al., J. Portfolio Mgmt 2015): spun-off subsidiaries outperformed a size/BM benchmark by 0.72%/month, cumulative excess 17.1% over the first period. Parents outperformed by 0.27%/month (cumulative 3.7% over 15 months), but the excess vanishes if one extreme outlier is removed. | https://business.purdue.edu/faculty/mcconnell/publications/The%20Stock%20Price...2013%20jpm.2015.42.1.143.pdf | Journal article, search snippet only | Not shown (title mentions 2013) | See left | Supports for subsidiaries, weak for parents | UNVERIFIED (snippet). Sample period not displayed. The search query asked about 2015-2025 and the result did not answer it. |
| 13 | Hite, Owers, Rogers (1987): significant positive abnormal returns around liquidation announcements. Asset-sale announcement abnormal returns 0.5%-1.66% across three 1980s studies. | https://www.sciencedirect.com/science/article/pii/0304405X87900407/pdf and https://bpb-us-w2.wpmucdn.com/u.osu.edu/dist/0/30211/files/2016/05/Asset-sales-18zfo4n.pdf | Journal articles, snippets only | 1980s | 0.5%-1.66% (asset sales); liquidation magnitude not shown | Supports, but 1980s | UNVERIFIED (snippets). |
| 14 | Biotech cash-shell wind-downs: Third Harmonic Bio plan of dissolution (April 14, 2025): estimated total distribution about $246.6M-$259.8M, or about $5.13-$5.42 per share, initial distribution $5.13-$5.33. Tang/Concentra offers: CARGO Therapeutics March 2026 $4.38 plus CVR for cash above $217.5M and 80% of asset proceeds for two years; Kezar Oct 2024 $1.10 plus CVR for 80% of net proceeds (snippet); Atea May 2023 $5.75, a 55% premium, rejected by the board. | https://www.biospace.com/press-releases/third-harmonic-bio-announces-plan-of-liquidation-and-dissolution ; https://julienwillard.com/insights/biotech-reverse-merger-shell-shortage ; https://www.bizjournals.com/sanfrancisco/news/2026/04/14/activist-investor-kevin-tang-aurinia-kezar.html | Press release, advisor blog, news (snippets) | 2023-2026 | See left | Mechanism supported, return evidence absent | UNVERIFIED (snippets). The agent never found the realised distribution vs estimate for any company, and never found the stock price at announcement. |
| 15 | ESSA Pharma (EPIX) example: the post gives two inconsistent discounts, about 35% to net cash (subtitle) and about 15% to pro-forma net cash (body); cash above $125M, liabilities about $4M, market cap about $80M; Tang held about 9.7% via a 13D; six past Tang/Concentra offers are listed with no price, discount or CVR terms. | https://centraltendency.substack.com/p/on-a-potential-sale-of-essa-pharma | Single-author Substack, opened by WebFetch | Written about 2025-2026 | See left | Mixed (one anecdote, internal inconsistency) | VERIFIED (fetch summary) that the page says this. The fetch summary said per-share net cash and price cannot be computed. This is an anecdote, not a return estimate. |
| 16 | Item 1.05 cyber 8-K reactions: CB Financial (CBFV) first AI-root-cause 8-K, May 2026: -1.16% day after, -3.30% at T+5. Halliburton (Aug 23, 2024): -3.99% day after, -8.94% at T+5. Johnson Controls (Mar 13, 2026): -0.26% day after, -2.10% at T+5. One further case showed -3.62% day after and -13.21% at T+5 (company name not visible in the snippet). 31 voluntary 8.01 filings in the vendor's dataset. | https://www.cherryhilladvisory.com/sec-cybersecurity-disclosure-rule-two-year-review | Consultancy marketing page, search snippet only | 2024-2026 | See left | Mixed anecdotes. Direction at T+5 is further down than day 1, which is suggestive of drift but is cherry-picked cases from a vendor selling services. | UNVERIFIED (snippet). Not a study, no benchmark adjustment, no sample count shown. |
| 17 | Clinical-trial sponsor event study: early biotech abnormal returns exceed large pharma by 8.32% on day 0 and 10.95% over days 0-1. | https://pmc.ncbi.nlm.nih.gov/articles/PMC9439234 | Peer-reviewed article (PLOS-style), snippet only | Not shown | 8.32% / 10.95% differential | Describes announcement reaction, not post-event drift | UNVERIFIED (snippet). Says nothing about a tradable next-open drift. |
| 18 | Intra-industry earnings information transfer: late announcers underreact to early peers' precise news in rich information environments (international study). | https://ira.lib.polyu.edu.hk/bitstream/10397/96101/1/Overreactior_UnderreactiIntra-Industry_Earnings.pdf | Working paper, snippet only (abstract) | Not shown | None | Mixed: overreact vs underreact depends on country and signal precision | UNVERIFIED (snippet). |
| 19 | Managed-care reaction to the 2027 Medicare Advantage proposal: net rate +0.09% vs analyst forecast 4-6%; Elevance -13%, Centene -10%, Molina -8.8%, Cigna -3.2%; broader healthcare -1.18%. | https://www.morningstar.com/markets/healthcare-managed-care-stocks-plunge-following-almost-flat-medicare-rate-proposal | Morningstar article, snippet only | Announcement night to next afternoon, early 2026 (year implied by "2027 rate") | See left | Shows the market reacted fast and hard for large caps, evidence against low attention for this case | UNVERIFIED (snippet). |

## 2. Post-publication decay and crowding evidence

- Post-reorg equity: Jiang, Wang, Yang (via Duke blog, VERIFIED fetch summary) show alpha of 0.8-1.2% per month in 2000-2010 and zero afterward against a five-factor benchmark, with negative alpha for exchange-traded stocks in 2010-2019. This is the cleanest decay evidence in the transcript, and it kills the naive version of the idea. Verdad (Aug 2020) still shows a positive mean but a negative median over 2008-2019, with a positive return only in the high EBIT-yield bucket.
- Spin-offs: the McConnell snippet shows excess returns for the original sample and a parent-side result that disappears when one outlier is dropped. The agent searched for a "recent decade 2015-2025" result and did not get one. UNVERIFIED, no decay measurement.
- Liquidation announcement returns: only 1980s evidence was found (Hite, Owers, Rogers 1987). No decay measurement.
- Odd-lot tenders: the site that sells the tracker is itself public, and the transcript contains two competing public trackers (specialsitsdigest.com, oddlotarbitrage.com). That is crowding by dedicated information vendors, but no return-by-year data exists in the transcript. Not quantified.
- Legislation underreaction (Cohen, Diether, Malloy): snippets suggest weak or insignificant long-short alphas in some panels. Never opened and no decay split shown. UNVERIFIED.
- Biotech cash-shell activism: a hedgeweek snippet title says activists are "targeting nearly $30bn in underutilised" biotech capital, and the ESSA post and the Julien Willard post both describe Tang Capital's playbook as "relatively well known". That is qualitative evidence of crowding. No return decay figure. UNVERIFIED, snippets.
- No post-publication decay study was found for CRL publication, cyber 8-Ks, trial registry changes, or CMS rules.

## 3. Evidence on the AI increment over a mechanical baseline

None found. Specifically:
- No source in the transcript compares an LLM or agent signal with a mechanical or keyword baseline for any of the mechanisms above.
- Nothing post-training-cutoff, masked, or prospective was found. The agent did search for it (a query on LLM-read legislation text and firm exposure, one on LLM transcripts for peer read-through, and three Hugging Face paper searches on out-of-sample-after-cutoff LLM return predictability).
- What the searches returned, none of it opened:
  - A BFI/Chicago working paper ("Large Language Models: An Applied Econometric Framework", BFI_WP_2025-10) whose snippet says GPT-4o's ability to predict whether a Congressional bill passes is likely driven by training leakage because bill text is in the training data. This is a snippet-level contamination warning that applies directly to the legislation idea. UNVERIFIED.
  - A ScienceDirect link (S0304405X26001066) the agent tried to fetch for contamination controls. It returned HTTP 403. Nothing was read.
  - SSRN 4416687, "Expected Returns and Large Language Models" (news-text two-step procedure). Not opened.
  - Hugging Face paper 2512.23847, "Detecting Lookahead Bias in LLM Forecasts", published 2026-06-12 per the listing. The listing shows a title and a one-line description only. Not read. Other listed papers (2411.00856 on LLM equity ratings, 2608.11381 on real estate agents) were titles and descriptions only.
- The last HF result block was cut off in the extract, so some results are not visible.

## 4. Frequency, cost, execution, borrow, and data-access numbers

| Item | Number | Exact query or URL | Status |
|---|---|---|---|
| EDGAR issuer tender offers (SC TO-I), per quarter | 150, 151, 149, 156 for 2025Q4 to 2026Q3 (about 600 per year including all filers). SC TO-I/A amendments 173, 206, 187, 186. | `curl -A "research-bot jack@example.com" https://www.sec.gov/Archives/edgar/full-index/2026/QTR1/form.idx` (and 2025/QTR4, 2026/QTR2, 2026/QTR3), then an awk count of the form-type column. A search through `efts.sec.gov/LatestSearch/rest/search-index?q="odd lot"&forms=SC TO-I` returned HTTP 403. | VERIFIED for the form counts. The fraction with odd-lot priority is not measured. The agent could not text-search filings. |
| Third-party tender offers (SC TO-T) | 19, 22, 26, 12 per quarter | same form.idx files | VERIFIED |
| 13D filings | 2920, 2738, 2688, 2492 per quarter (declining each quarter) | same | VERIFIED. 13D count is not filtered to biotech or to Item 4 content. |
| Going-private (SC 13E3) | 10, 7, 8, 11 per quarter | same | VERIFIED |
| Merger documents (DEFM14A) | 70, 68, 67, 64 per quarter | same | VERIFIED |
| Late-filer notices (NT 10-K / NT 10-Q) | NT 10-K 39, 310, 187, 56; NT 10-Q 323, 74, 324, 245 | same | VERIFIED counts, no return evidence linked. |
| Odd-lot tender listings open | 117 (page header) conflicting with "54 this week" | https://specialsitsdigest.com/odd-lot-tender-offers | VERIFIED (fetch summary) as stated by the page. Internally inconsistent. |
| Odd-lot tender tracker | 9 offers listed, 1 of 4 US tenders mentions odd-lot priority | https://oddlotarbitrage.com/tender-offer-tracker | VERIFIED (fetch summary) |
| Odd-lot capacity, fees, proration | Odd lot = fewer than 100 shares aggregated across holder accounts. Commissions, settlement and transfer tax are named as costs. No dollar figure. | specialsitsdigest.com page | VERIFIED qualitatively. No capacity or cost number was obtained. |
| Odd-lot size limit and fit to a market-order-next-open design | Not addressed. The mechanism requires tendering shares, not a market order at the open, so fit to the design is unresolved. | none | Not reached |
| FDA CRL volume | 458 CRL records in the FDA API as of Aug 13, 2026; 14 new after July 10, 2026 resumption | https://intuitionlabs.ai/articles/fda-complete-response-letters-dataset | VERIFIED (extract) |
| FDA warning letters | Public table with posted date and letter issue date (e.g. posted 10/20/2026 for letters issued 09/28 to 10/14/2026, including Baxter International and Olympus Medical Systems) | https://www.fda.gov/inspections-compliance-enforcement-and-criminal-investigations/compliance-actions-and-activities/warning-letters | UNVERIFIED (snippet). Lag shown in the snippet is about 6-22 days from issue to posting. Not computed by the agent. No stock-reaction evidence. |
| Short borrow / locate cost for any candidate | None found | none | Not reached |
| Market-order slippage for small caps / OTC names | None found | none | Not reached |
| Data cost (EDGAR, FDA API, ClinicalTrials.gov, CMS) | EDGAR full-index is free and was downloadable. No pricing was found for any other source. | EDGAR URLs above | Partly verified, EDGAR only |

## 5. Strongest evidence against the idea

1. The one mechanism the agent measured carefully decayed. Post-reorg equity alpha was 0.8-1.2%/month in 2000-2010 and zero after, with negative alpha for exchange-listed stocks 2010-2019 (VERIFIED fetch summary). The median abnormal return is zero, so the average comes from a small right tail.
2. Verdad's post-reorg sample shows a 1-year median of -15% and a 2-year median of -35%, with about 22% of firms losing more than 80% within two years. Only the above-20% EBIT-yield bucket is positive. That is a single filter on a 49-firm sample that ends in 2019. VERIFIED fetch summary.
3. The sources most directly tied to the "AI reads text" premise are the ones the agent could not open. The ScienceDirect paper returned HTTP 403, SSRN returned HTTP 403, the CRL GitHub README held no numbers. A snippet from the BFI working paper says LLM predictions of bill passage are explained by training leakage. That is contamination evidence pointing against any backtest that uses text the model has already seen. UNVERIFIED snippet.
4. FDA CRL publication timing is unreliable. A reported April 2026 pause, then a July 10, 2026 resumption, a citizen petition arguing the policy is unlawful (FDA response due about Oct 17, 2026, none posted as of the article), and a rulemaking targeting an October 2026 proposal. VERIFIED via BioSpace fetch and the intuitionlabs extract. Whether future letters arrive in real time is unknown.
5. The odd-lot tender listings found were mostly stale or non-US. Of 9 listed offers on one tracker, expiries ranged Oct 2024 to Sep 2026, only one of the four US tender-category listings mentioned odd-lot priority, and the status was "Not stated" for almost all of them. Gross spreads (3.9%-67.6%) are not net of cost and the largest ones were Canadian or tiny-priced. The mechanism also needs a tender, not a next-open market order.
6. Liquidation and cash-shell evidence is 1980s academic work (Hite, Owers, Rogers 1987) plus anecdotes. The agent found no sample of realised distribution versus pre-announcement price, and the Tang playbook is described as well known and crowded by activist funds.
7. Cyber 8-K "drift" numbers come from a consultancy page with hand-picked cases. UNVERIFIED snippet.
8. Large-cap reactions to regulatory text appear fast (Medicare Advantage rate proposal, managed care stocks fell 3.2% to 13% within about one trading day per a Morningstar snippet), which argues against low attention for the CMS idea in large caps.

## 6. What the agent had not reached when it was cut off

- Any measured AI-over-mechanical-baseline comparison. Searches were launched, nothing was opened.
- Whether any odd-lot-priority offers exist in sufficient number and size. The EDGAR full-text search failed with 403, so the count of SC TO-I filings with odd-lot priority is unknown. The agent had downloaded the form index only.
- Realised per-share liquidating distributions vs the announced range and vs the stock price at announcement for the 2025-2026 biotech wind-downs. Only announcement text for Third Harmonic and Tang bid prices without price context.
- CRL study numbers (222 events, 124 firms, CAR by deficiency type, drift). Only the sample size in a snippet.
- The Cohen-Diether-Malloy main result (the snippets were fragmentary), and any CMS, antidumping or HHS event study. The antidumping search returned a tariff-jumping FDI paper with no returns and a 40% final-affirmative base rate for 1980-1993 USITC cases. UNVERIFIED snippet.
- Activism 13D drift. Search returned a thesis and a 2007 paper; no figure was read.
- The results of the three hf_fs paper searches (output truncated).
- The Item 1.05 cyber 8-K idea, the ClinicalTrials.gov registry-change idea and the intra-industry peer read-through idea each got one search and no opened source.
- Any borrow, slippage or capacity number for any idea. Any execution test with next-open market orders. Any holding-period or turnover estimate.
- The agent did not map any idea explicitly to K1-K6, and the transcript does not show which K1-K6 are. The "beyond K1-K6" filter was not checked here.

## 7. Every idea the scout surfaced

Frequency below means the number or event rate the transcript supports, not a design choice. "Weakest" is the biggest gap in the transcript's evidence.

1. Legislation text underreaction (Cohen, Diether, Malloy "Legislating Stock Prices"; LLM reads bill text and maps firm exposure).
   - Mechanism: market underreacts to legislative text because few investors parse bills. An LLM could map bills to firms.
   - Evidence: NBER w18291 snippets only (fragmentary alphas, many with t-stats near 1). The BFI paper snippet warns of training leakage in LLM bill-text prediction.
   - Frequency: not found.
   - Weakest: the original result looks insignificant in the fragments the agent saw, the paper was never opened, and the contamination risk for an LLM tested on public bills is documented. UNVERIFIED.
2. FDA complete response letter (CRL) text vs the sponsor's press release.
   - Mechanism: FDA now publishes redacted CRLs, so an LLM can compare the sponsor's account to the letter and trade the gap. Debevoise and others note companies historically omitted a substantial portion of FDA concerns.
   - Evidence: a 222-event, 124-firm CAR study exists (2010-2025) but its numbers were never obtained. 458 records in the FDA API, 14 added July 10, 2026.
   - Frequency: roughly 14 letters in the July 2026 batch; 458 total over about 13 months of publication plus the historic batch.
   - Weakest: publication has been paused and may be rolled back by petition or rule, no return number was found, and timing relative to the company's own release is unverified (the agent asked and could not answer).
3. Odd-lot tender offer arbitrage.
   - Mechanism: holders of fewer than 100 shares can get priority in an issuer tender and avoid proration, capturing the tender premium.
   - Evidence: mechanism described on two trackers (VERIFIED, fetch summaries). Indicative gross spreads on one tracker: 3.9%, 6.4%, 6.9%, 6.3%-20.9% (range), 47.4%, 67.6%, with most being non-US or stale. EDGAR filings of SC TO-I run about 150 per quarter.
   - Frequency: about 150 SC TO-I filings per quarter (all issuer tenders, not filtered for odd-lot priority).
   - Weakest: not a next-open market-order trade, since shares must be tendered and held to expiry, there is no return history, capacity per name is tiny by construction, and the odd-lot-priority share of filings is unknown because EDGAR full-text search returned 403.
4. CMS (Medicare) payment-rule underreaction, small-cap home health and hospice.
   - Mechanism: small providers react slowly to final-rule text.
   - Evidence: search returned CMS rule pages and a generic event-study tutorial. The only reaction found was large-cap managed care, which moved 3.2% to 13% within about a day (Morningstar snippet).
   - Frequency: annual rule cycle (final rule for CY2024 home health is CMS-1780-F per a snippet), not otherwise measured.
   - Weakest: no small-cap evidence at all, and the one reaction found shows fast pricing in large caps. UNVERIFIED.
5. Post-bankruptcy emerged equity.
   - Mechanism: forced selling by creditors and low attention produce abnormal returns after emergence.
   - Evidence: VERIFIED fetch summaries for Jiang-Wang-Yang (200-day mean +40% to +50%, median 0, alpha zero after 2010) and Verdad (49 firms, 1-year mean 19.8%, median -15%, EBIT-yield above 20% bucket +61% at 2 years).
   - Frequency: 93 relistings over 2008-2019 (about 8 per year), 49 above $100M market cap (about 4 per year).
   - Weakest: decayed to zero alpha after 2010, concentrated in OTC names, tiny annual n, and no AI step is needed or tested.
6. Spin-off drift.
   - Mechanism: index and institutional selling of spun-off stocks creates a discount that closes.
   - Evidence: McConnell et al. snippet, subsidiaries beat benchmark by 0.72%/month (cumulative 17.1%), parents' excess is an outlier artifact. UNVERIFIED.
   - Frequency: not found.
   - Weakest: the agent asked for 2015-2025 evidence and did not get it, so recent persistence is unknown.
7. Activist 13D filings, small-cap Item 4 text.
   - Mechanism: an LLM reads the Item 4 purpose-of-transaction text and separates real activism from passive reservation of rights.
   - Evidence: the Harvard 2007 paper snippet notes that often the investor has no activist plans and files a 13D only to reserve rights. No drift number was read. 13D filings run about 2,500-2,900 per quarter (VERIFIED, form counts).
   - Frequency: about 2,500-2,900 filings per quarter, most of them not activism.
   - Weakest: no post-filing return evidence, the 13D rule changes are not in the transcript, and the known drift is front-loaded into the filing day, which is before a next-open order could act.
8. Antidumping and countervailing duty petitions.
   - Mechanism: domestic producers rise on petitions and determinations.
   - Evidence: a University of Oregon tariff-jumping paper snippet says the USITC final determination was affirmative in 40% of cases 1980-1993. No returns shown. UNVERIFIED.
   - Frequency: not found.
   - Weakest: only 1980-1993 base rate, no returns, no recent data.
9. FDA warning letters for public companies.
   - Mechanism: warning letters are posted on the FDA site after a lag and may not be in an 8-K.
   - Evidence: FDA table with posted dates 6-22 days after issue dates (snippet); a Dexcom 8-K for a March 4, 2025 letter shows the company did file an 8.01. No reaction numbers.
   - Frequency: the table lists many letters posted on 10/20/2026 (count not read).
   - Weakest: no return evidence, and large caps like Dexcom disclose themselves.
10. Biotech cash-shell liquidations and activist buyouts (trading below cash, plan of dissolution, Tang/Concentra bids with CVRs).
    - Mechanism: stock trades at a discount to net cash, closing on liquidation or on an activist-led bid at a premium. Concentra offered 55% premium to the prior close for Atea in May 2023, which the board rejected.
    - Evidence: Hite, Owers, Rogers 1987 snippet (positive liquidation returns, magnitude not shown). ESSA anecdote (VERIFIED fetch summary): about 35% or about 15% discount depending on the cost assumption, market cap about $80M vs cash over $125M. Third Harmonic estimate $5.13-$5.42/share.
    - Frequency: not counted. Six Tang offers 2023-2024 listed in the ESSA post, more in 2026 snippets (CARGO, LianBio, Aurinia/Kezar).
    - Weakest: no realised-vs-estimated distribution data, tiny capacity, the setup is a very public activist playbook, and the transcript never measures net returns or time to payout. Also not an AI-edge in any evidence shown.
11. ClinicalTrials.gov registry changes (primary outcome change, completion-date delay).
    - Mechanism: sponsors alter registry fields before the market notices.
    - Evidence: only the PMC event study snippet (day 0-1 abnormal returns, early biotech vs large pharma +8.32% / +10.95%). It measures announcement reactions, not registry edits.
    - Frequency: not found.
    - Weakest: no evidence for the registry-edit idea at all.
12. SEC Item 1.05 cyber incident 8-Ks.
    - Mechanism: slow digestion produces post-disclosure drift.
    - Evidence: consultancy snippet cases (CBFV -1.16% to -3.30% T+5; Halliburton -3.99% to -8.94% T+5; Johnson Controls -0.26% to -2.10% T+5). UNVERIFIED.
    - Frequency: 31 voluntary 8.01 filings in the vendor's dataset. Item 1.05 count not seen.
    - Weakest: anecdotes from a vendor, no benchmark adjustment, and it is a short signal, which was not costed (no borrow data).
13. LLM read-through of earnings calls across industry peers.
    - Mechanism: late announcers underreact to early peers' news when the news is a precise signal.
    - Evidence: one abstract (international study, moderated confidence hypothesis). UNVERIFIED.
    - Frequency: not found.
    - Weakest: the result is conditional on country and signal precision, no US result and no LLM comparison was found.
14. Regulatory-text and LLM news mining generally (Expected Returns and LLMs; BFI framework; lookahead-bias detection paper).
    - Mechanism: LLMs extract return-relevant information from text.
    - Evidence: titles and snippets only. None opened.
    - Frequency: not applicable.
    - Weakest: the training-leakage warning in the BFI snippet applies, and no out-of-sample or post-cutoff test was seen.

## Files and tools

Written file: /Users/jack/Desktop/My Apps/Stock-Trading/ops/research/strategy_lab_2026-11/salvage_scout.md. No other file written, no git, no BigQuery, no external service touched during this salvage.
