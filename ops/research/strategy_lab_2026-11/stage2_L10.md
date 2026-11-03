# Stage 2 arithmetic check, L10: biotech cash-shell discount
Working file (read-only research). Started 2026-11-02. Numbers labelled VERIFIED only if seen in a source or own output.

## Evidence inherited (salvage_scout.md rows 14, 15, item 10)
- Third Harmonic est. $5.13-$5.42/sh; CARGO $4.38 + CVR (Mar 2026); Kezar $1.10 + CVR; Atea $5.75, 55% premium, rejected; ESSA 35% or 15% discount. All return evidence absent.

## Access log
- EDGAR form.idx: HTTP 403 "Undeclared Automated Tool" with the prescribed User-Agent (2026-11-02, two attempts). SEC page says access can resume once request rate drops for 10 minutes. VERIFIED (own output).
- FMP chart/quote/secFilings: ACCESS DENIED, plan tier. VERIFIED (own output).
- Tavily: 429 after a burst; retrying slowly.
- state.strategy_candidates regex on shell|liquidat|biotech|net cash|wind.down: 0 rows. VERIFIED (own query). No cooldown on this idea found by that query.

## Case evidence so far (price vs deal)
| Case | Date | Cash/sh | Prior close | Cash vs prior close | Source | Label |
|---|---|---|---|---|---|---|
| Kronos Bio / Concentra | 2025-05-01 | 0.57 + CVR | implied 0.89 | -35.96% | insidearbitrage.com snippet; Fierce "35% below" | VERIFIED snippet |
| iTeos / Concentra | 2025-07-21 | 10.047 + CVR | 10.26 | -2.1%; closed day-0 at 10.14 | BioSpace | VERIFIED snippet |
| IGM / Concentra | 2025-07 | 1.247 + CVR | 1.12 "currently trading" | +11.3% (timing of 1.12 unclear) | Investing.com | VERIFIED snippet |
| Atea / Concentra | 2023-05 | 5.75 | premium 55% | +55%; rejected by board | Julien Willard | VERIFIED page |
| Kezar / Concentra then Aurinia | 2024 / 2026-03 | 1.10 rejected, later 6.95 vs 6.20 close (post reverse split) | 6.20 | +12.1% | Fierce | VERIFIED snippet |
Concentra offers: 2023 six, two successful; 2025 seven by mid-Aug (BioSpace 2025-08-13). VERIFIED page.
Below-cash universe: 128 small/mid caps summer 2022 vs historical norm <45 (Jefferies via Willard); "No one maintains a reconciled quarterly count". 161 negative-EV names (nextfinancial substack, undated snippet). Approx 30% of US biotechs under $10B below cash (RTW Aug 14 2026 snippet, full page fetch failed).

# Verdict: KILL

Decisive: (1) T1, the only honest class binds under acute today and no breaker exists; (2) T3 with T4, the best-supported gross edge is about the same size as the all-in cost of the median tradable name, and the announcement effect is a day-0 repricing; (3) T6, the return driver is a classical net-cash premium plus an activist's bid, and the evidence shows the market closing the gap without an LLM.
Not refuted: that an LLM estimates distributable cash well. It was simply not the thing that pays. No sample of realised returns exists anywhere in this file.

Labels: VERIFIED = seen in a source or own output. "VERIFIED snippet" = seen in a search excerpt or fetch summary, full document not read. UNVERIFIED = estimate or memory.

## T1 Register class
- Source: Strategy.md Shock Transmission Register (Rev 50, E row and SPREAD rule revised Rev 53). No row means binds. VERIFIED.
- Long-only: DIRECTIONAL-LONG. BINDS. Under acute today: DO-NOT-ACTIVATE.
- Hedged vs XBI: the label SPREAD is not honest. Rule says SPREAD means "market factor netted". Measured on the one live shell: FULC vs XBI 2026-06-18 to 2026-11-02, 94 daily returns: beta 0.402, correlation 0.436; FULC -1.35%, XBI +8.05% (own output, IBKR bars, n=1 name). A 1:1 short is about 2.5x over-hedged and is net short biotech, a sector view the shell does not need. From the FULC next-open entry: FULC +17.36%, XBI +19.19%, so 1:1 hedged = -1.83% (own output). Honest class for any version with a positive net carry to a resolution event: DIRECTIONAL-LONG-BIASED. BINDS.
- If it were still registered SPREAD, the three requirements:
  - (i) per-industry-group leg: possible in form, since the whole book is one group, but there is no group statistic to read. M2's pair-correlation population does not contain these names and they would fail E's >=$10B floor.
  - (ii) low-side leg keyed to own breakdown invalidation: could be authored (net-cash estimate cut, board pivots to a new program instead of distributing).
  - (iii) stress replay showing it trips: cannot be done now. No dated series of shell returns exists here; I could not get delisted-name bars (FMP denied, IBKR lists live names).
  - Rev 53 also requires owner revision and adversarial review. No SPREAD row carries a breaker today. Not met.
- Not SHOCK-NATIVE: activation has no link to shock_overlay and it is net long.
- FAIL on evidence.

## T2 Frequency
Sources, no exact query possible: EDGAR form.idx returned HTTP 403 throughout, so no SC TO-T count. Counts below are press and filing based and incomplete.
- Concentra offers: 6 in 2023 (2 succeeded), 7 by 2025-08-13. BioSpace page. VERIFIED.
- Concentra deals named 2025: Allakos, Kronos, Elevation, IGM, CARGO, iTeos = 6. BioSpace snippets. VERIFIED snippet.
- Banker precedent set: 9 net-cash deals Jul 2023 to Aug 2025 (SC 14D9, accession 0001193125-25-272604, Aquilo Partners), the excerpt may be partial. VERIFIED snippet.
- Reverse mergers: 7 closed H1 2026 (Willard), so about 14/yr. VERIFIED page. Many pay a pre-closing dividend (Talaris, Sesen, Fulcrum).
- Plans of dissolution: rare. Willard calls the orderly ending "the rare one". Named: SQZ 2024, Third Harmonic 2025. No count found.
- Below-cash universe (pre-event version): 128 small/mid caps 2022 vs historic norm <45 (Jefferies via Willard); 161 negative EV (substack, undated); about 30% of US biotechs under $10B (RTW 2026-08-14, snippet only, page fetch failed). "No one maintains a reconciled quarterly count." Plentiful, not the constraint.
- Declared for this check: 8 round trips/yr. UNVERIFIED, my estimate after the price and cost screens below remove sub-$1 names from roughly 15-25 events/yr.
- Hold: 3 to 6 months. Fulcrum event 2026-06-02, closing targeted Q4 2026 (5-7 months). iTeos data 2025-05-13, deal 2025-07-21, close Q3 (about 3 months). Third Harmonic plan 2025-04-14, first distribution targeted Q3 2025 (about 4 months, targeted, not realised). VERIFIED snippet.
- Floor at 8/yr = GREATEST(3, CEIL(8/2)) = 4 closed. Own output: 1.9 expected closes per 60 trading days at steady state, but entries in the first PAPER window with a 63-126 day hold mostly do not close inside it: about 0-1 closed in a 60-day PAPER. Floor reached about 126 trading days of entries plus one hold = about 189-252 trading days. Before the 400-day cull: yes on arithmetic.
- Caveat: PAPER accrual under a binding override is the open question in stage1_ideas.md. If a bound strategy does not accrue simulated fills, the clock stops while acute lasts.
- PASS on count alone, conditional on that open question.

## T3 Cost at $2,000
Commission: IBKR tiered $0.0035/share, min $0.35, cap 1% (Operating_Protocols.md cites the $0.0035 rate). Spread: Abdi-Ranaldo estimate from IBKR daily high/low/close, 2026-10 sessions, own output. Noisy estimator. Snapshots below were taken after the close (21:00-21:27 UTC on 2026-11-02) so they overstate spreads and are shown only for reference.

| Name | Price | ADV 90d $ | $2,000/ADV | Shares | RT commission | AR spread est | All-in RT | Rail d 1.8% | Post-close quote spread |
|---|---|---|---|---|---|---|---|---|---|
| FULC | 3.65 | 5,595,358 | 0.04% | 548 | 0.19% | 0.79% | 0.98% | pass | 5.07% |
| AVIR | 4.10 | 1,149,398 | 0.17% | 488 | 0.17% | 1.42% | 1.59% | pass | 17.39% |
| XBIT | 1.92 | 105,305 | 1.90% | 1,042 | 0.36% | 2.87% | 3.23% | FAIL | 8.88% |
| CRBU | 0.44 | 1,139,652 | 0.18% | 4,546 | 1.59% | 4.18% | 5.77% | FAIL | 5.56% |
| TCRX | 0.18 | 132,353 | 1.51% | 11,198 | 2.00% (1% cap) | 5.58% | 7.58% | FAIL | 9.03% |
| RLYB | 15.76 | 256,888 | 0.78% | 127 | 0.04% (0.35 min x2) | not computed | n/a | n/a | 4.35% |
| BTAIQ | 0.0129 | 75,584 | 2.65% | n/a | 2% cap | not computed | n/a | FAIL (quote 32.56%) | 32.56% |

Commission alone reaches 1.8% at price $0.389 (own output). AVIR and TCRX are restructurers or at-risk programs used for liquidity measurement, not confirmed shells. Median all-in of the 5 measured = 3.23%. Hold-to-payout saves the exit side only: CRBU one-way about 2.9%, still above rail d.
Hedge leg if used: 13 XBI short, $0.70 commission (0.035%), spread minimal, borrow unmeasured for XBI here; prior repo sample 0.25-0.43% on fractional shorts (candidate G text, state.strategy_candidates). About +0.1%.

Best-supported GROSS edge per trade (cash component only, last close before deal to deal cash):
- 9-deal precedent table 1-day premium: -4, +217, +11, -36, +52, -29, +4, +8, +3. Median +4%, mean +25.1%; without DURECT (a commercial asset, not a shell) median +3.5%, mean +1.1%. Own output.
- LaaS only (XOMA/Concentra rows plus iTeos -2.1% and Kezar +12.1%): n=7, median +3%, mean +5.14%, 43% at or below zero. Own output.
- CVR value not included. Realised CVR payments: not found. UNVERIFIED and load-bearing, though CVRs are capped small in the case seen (Theseus up to $0.15 on $3.90).
- Net: +3% gross, less 3.23% median cost, less SGOV carry about 0.9-1.9% for 3-6 months at 3.7%/yr = about -1 to -2%. With a FULC-quality name at 0.98% cost: about 0 to +1%, on a distribution ranging -36% to +52%.
- Upfront equity is 0.46x-0.86x last-filed net cash, median 0.67x, mean 0.69x, stated in the 14D9 (the visible 9 rows give 0.72 and 0.678). So a 30% discount to reported net cash is about the price at which a professional liquidator buys it. Reported discount is not edge.
- FAIL on evidence.

## T4 Next-open survival
Two different signals:
- Signal at deal or dissolution announcement: day-0. iTeos cash $10.047 vs prior 10.26, day-0 close 10.14. CARGO $4.47 vs cash $4.379. Theseus $4.05 vs $3.90 + up to $0.15. The remainder after next open is the CVR and a merger-arb spread. FAILS.
- Signal at failure and restructuring, before any deal: mixed, n=2, no sample.
  - FULC: 6/1 close 6.42, 6/2 close 3.14, next open 6/3 3.11, 11/2 close 3.65 = +17.36%. Value stated $3.54 dividend + $0.41 stub = $3.95, +27.0%. Note 6/18 close was already 3.70, so most of it was gone 12 sessions later. Today the dividend alone is below price, -3.0%, and the market prices the stub at $0.11 vs $0.41 stated. VERIFIED bars; dividend and stub per Fulcrum release and Yahoo snippet.
  - CRBU: 8-K 10/6, 10/7 close 0.6174, next open 10/8 0.5938, 11/2 close 0.4399 = -25.92%. Cash $113.8M at 6/30 / 98.26M shares = $1.16; my estimate after burn and $15-19M restructuring about $0.58 before leases, severance, LaaS fee. UNVERIFIED estimate; lease liability not found, and load-bearing.
- Survives for FULC by weeks, not for CRBU. Not established. FAIL for the announcement signal, unproven for the other.

## T5 Overlap
- B: same mechanism on FULC (a >=5% post-event reaction) but excluded by B's >=$2B cap (FULC about $490M at 6.42 x 76.3M shares). No rule overlap, and it is a near neighbour in spirit.
- B rail on targets pinned by all-cash deals, and L1 merger arb: the post-announcement version is L1.
- A: a pre-event catalyst long on an awaited bid is A-shaped. D, C, E: none.
- Dead ideas: post-reorg equity is the closest analog (median abnormal return zero, gains from a right tail, salvage_scout row 1). No listed cooldown: state.strategy_candidates regex on shell/liquidat/biotech/net cash/wind-down returned 0 rows; listing shows F, G, H, I only with F, G, H expired or expiring and I to 2027-01-17. VERIFIED own query.
- PASS with a warning.

## T6 Mechanical baseline
- Screen: XBRL cash minus total liabilities per share; buy below about 0.67x; sell into deal. Earnings of that exact screen in biotech: NOT FOUND.
- Nearest: Bochman, negative-EV US stocks 1972-2012, 26,569 stock-months, +50.4% average 1-year, before costs (GuruFocus citing CFA Institute post). Secondary and all-sector. VERIFIED snippet. That is a classical deep-value premium, which rail (a) excludes when the AI merely selects from it. Rejections of F, H, I cite this same category error.
- Swedroe: of 1,000+ biotechs reaching $200M cap, 67% lost money and many sit below cash as zombies. VERIFIED snippet, paid post.
- What the AI must add, specifically: forward burn, severance, lease and contract exit costs from footnotes, plus the probability the board distributes rather than pivots. NextCure shows the size: cash $20.1M vs management's estimated wind-down spend about $19.2M, so reported cash is nearly all consumed. VERIFIED snippet. Real work for a reader.
- Against: Fulcrum's own liquidation analysis (first distribution $3.71, then PV $0.09 and $0.08 = $3.88) was public only in the S-4 (Sept 2026), yet price was 3.70 by 6/18 with no such document. The market got to within about 5% in 12 sessions. n=1. And the pivot-versus-distribute decision depends on boards and activists, not on a filing yet written.
- No measured AI increment exists. The return comes from a bid floor supplied by Tang, XOMA and peers, and Ligand's April 2026 purchase of XOMA removes one of them (Willard). FAIL rail (a) as evidenced.

## T7 Data and execution
- Inputs: 10-Q/8-K/S-4/14D9 from EDGAR. EDGAR direct 403 in this run with the prescribed User-Agent; same documents reachable through the search and extract tool. Prices via IBKR connector. FMP chart, quote and filings tools denied by plan.
- Value delivery:
  - Tender plus back-end merger: cash paid at merger close without tendering, on general knowledge of the structure. UNVERIFIED for IBKR handling. An election would be a human step beyond the tap; not tendering avoids it.
  - CVR: "non-tradeable" per Kronos and IGM, "nontransferable" per iTeos. Cannot be exited by market order, terms up to years. Position would sit unreconciled in a system whose only exit is a MARKET order. No such path verified in the repo.
  - Dissolution: paid by board-timed distributions, tail up to 3 years in the Fulcrum analysis (Dec 2029 final). Transfer books close at dissolution; after that no market exit.
  - Reverse merger stub: tradable, market-order exit works, but you hold a new biotech (FULC 5% stub).
  - Bankruptcy path: BTAIQ at $0.0129 on PINK, quote status FROZEN_DELAYED. Equity near zero.
  - Clean alternative: sell by MARKET before close and forfeit CVR. No extra human step, gross edge smaller.
- Paper simulator must define close events for each path. Not impossible, unbuilt.
- PASS with cost, only under sell-before-close.

## T8 Test feasibility (July 2026 onward)
Found by search, incomplete because EDGAR was blocked:
1. NextCure reverse merger with CVR, July 2026.
2. Fulcrum/Slate, 2026-08-17 (trigger event 2026-06-02 is pre-July).
3. Caribou strategic review, 2026-10-06.
4. BioXcel asset sale and wind-down, 2026-10-30 (Chapter 11, equity near zero).
5. InMed merger with CVR record date, Oct 2026 (exact deal date not read).
6. Chemomab/Scipher merger with CVR (DEFM14A, date not read).
7. Rallybio/Avenzo 2026-05-31, CVR, pending: pre-July signal, post-July resolution.
Excluded: TScan and Foghorn (cuts, no wind-down), Vicarious Surgical (medtech), Standard BioTools (tools).
About 6 usable events on about 6 independent dates, and 0 with a realised final payout today. No post-July Concentra or XOMA deal found, which may be a search gap. UNVERIFIED completeness. A contamination-safe test is not possible now; a usable n arrives around 2027 and only if deals keep coming.

## One suggestion
If this is ever reopened: score the LLM's distributable-cash estimate, made before the fact, against the liquidation analyses boards later publish in S-4s and proxies, and test only on names above about $1 with sell-before-close. That measures the AI increment the idea currently lacks.

## Corrections to inherited evidence
- Scout row 14 and Willard date the CARGO offer March 2026. BioSpace (Aug 2025) and GAMCO show it as a 2025 deal. Treat March 2026 as wrong.
- Kezar: the $1.10 bid was 2024 and rejected; the 2026 deal was Aurinia at $6.95 with a Tang-run acquirer.
