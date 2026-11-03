# Stage 2, L9: Shock policy-text reader

Working file, not policy. Written 2026-11-02. No candidate row, roster, order, alert or watchlist was touched.

**Verdict: KILL.** T3, T4 and T6 fail on evidence, and T5 is a serious overlap.

- After a next-open entry, 18 named notice-to-firm pairs lost 2.68% on average at 5 days and 2.91% at 10 days, before costs. The 5-day figure is at the 1.2nd percentile of same-pair placebo draws.
- Post-cutoff alone, the pairs had moved +1.77% in the predicted direction before the next open (99.2nd percentile), then lost 3.56% over 5 days (3.2nd percentile).
- No source supports a positive gross edge from reading policy text. All-in cost is 0.65% to 1.25% of gross, so there is nothing for it to come out of.

Labels: VERIFIED means I saw the number in a source or my own output. UNVERIFIED means I assumed it. Scripts and price files are in the session scratchpad, not the repo.

## T1 Register class: passes in form, with one rail problem

Class is SHOCK-NATIVE. It can be active under acute only if the activation rule requires `shock_overlay` in {latent, acute}. Source: Strategy.md, Shock Transmission Register, Classes paragraph (VERIFIED).

| Rail | Status | Note |
|---|---|---|
| Activation requires latent or acute | Can be met | Written into the rule |
| (i) No net-long expression | Can be met | Dollar-neutral pairs. Pairs in names with very different betas (GPRE vs VLO) are not market-neutral without beta sizing |
| (ii) Invalidation on symmetric exit test | Can be met | Same exit as any shock-native thesis |
| (iii) Frequency in qualifying shock events | **Problem** | The signal is a notice, not a shock event. Notices keep arriving between events and before the war (Venezuela licences in January and February). Candidate I was rejected partly on this same unit mismatch. The only clean restatement is at most one signal per qualifying event, about 11.3 per year |

## T2 Frequency: count clears the cull only while this shock stays open

**Notice counts, 2026-02-28 to 2026-11-02** (247 days, 0.676 years; VERIFIED output).

| Source | Query | All | Substantive energy | Since 2026-07-01 |
|---|---|---|---|---|
| OFAC | `ofac.treasury.gov/recent-actions`, every page, then each action page | 143 actions; 90 with Iran, Russia or Venezuela in the title; 20 energy licence by regex; 20 naming vessels | 14 by my reading | 62 actions; 3 substantive; 9 naming vessels |
| EPA | `epa.gov/enforcement/fuel-waivers` | 20 rows; 9 nationwide | 2 (03-25, 08-20) | 14 rows; 1 substantive |
| DOE SPR | energy.gov releases and award sheets | at least 12 (RFPs 03-13, 04-01, 04-29, 06-10; awards 03-20, 04-10, 04-17, 05-11, 06-22, 10-29; 03-11 announcement; 10-08 hurricane exchange) | 12 | 2 |
| DHS and CBP | Jones Act waiver and extensions | 3 (03-17, April, 08-10) | 3 | 1 |
| Presidential | DPA s.303 determinations, FR 2026-08016 and 2026-22052 | 2 | 2 | 1 |
| **Total** | | | **33, or 48.8 per year** | **8** |

- The 14 OFAC notices are GL 133, 134, 134A, 134B, 134C, U, V, X and X1, plus Venezuela 46B, the 47 and 50A set, the 46C set, 46D and 46E. They exclude Lukoil 131-series rollovers.
- "Substantive" is my judgment. The regex misses some Venezuela licences, so the OFAC count is a floor. UNVERIFIED as an exact number.
- Federal Register term counts for 2026 through 11-02 (API, VERIFIED): "Strategic Petroleum Reserve" 2; `"Jones Act" waiver` 0; `Iran sanctions` 66; `Strait of Hormuz` 4. The Jones Act waiver never appears, so a Federal Register reader alone would miss the waiver and most of the actual policy flow.
- Few notices name a firm. Only the five SPR award sheets name recipients, and they name mostly traders: Trafigura 34.35 mb, Marathon 22.10, Shell 18.10, Exxon 14.40 (VERIFIED, secondary ledger quoting DOE sheets). Most other mapping is inference. The two DPA determinations name no company (my regex on full text, VERIFIED). The law-firm alert on the Jones Act extension names none either.

**PAPER arithmetic** (VERIFIED output; rates are declarations, not forecasts; one pair counted as one closed trade).

| Declared rate | Per year | Closed in 60 days, 5-day hold | Closed in 60 days, 20-day hold | Floor | Trading days to floor | Count by day 400 |
|---|---:|---:|---:|---:|---:|---:|
| One per qualifying event (rail iii) | 11.3 | 2.5 | 1.8 | 10 | 223 + hold | 18 |
| My tested list | 26.6 | 5.8 | 4.2 | 10 | 95 + hold | 42 |
| All substantive | 48.8 | 10.7 | 7.7 | 10 | 52 + hold | 77 |

- A 60-day PAPER clears the floor only at the all-substantive rate with a 5-day hold.
- Before day 400 the count clears at all three rates, but only if the shock structure stays open. At the event study's onset rate of 6 in 36 years (0.167 per year), expected signals by day 400 are 0.27. The study's 11.3 per year (9 dated events in 0.80 years) describes 2026 only.
- Result: conditional pass on count. Not the deciding check.

## T3 Cost: passes rail (d), fails against the edge

All-in round trip for a pair at $2,000 gross, four fills.

| Item | Base | Worst | Status |
|---|---:|---:|---|
| Commission | 0.42% | 0.42% | VERIFIED as a stored measurement (`bigquery/133`, equity-pair round trip). I did not re-derive it; the $0.35 minimum alone gives 0.07% |
| Spread and slippage, market at open | 0.20% (10 bp per fill) | 0.40% (20 bp average, small-cap leg at 30 bp) | UNVERIFIED assumption |
| Borrow | 0.03% (0.43% read as annual, 20 days) | 0.43% (read as per trade) | Range VERIFIED (`bigquery/133`); units unclear |
| **All-in** | **0.65%, $13.08** | **1.25%, $25.00** | VERIFIED arithmetic |

- Rail (d): commission 0.42% is at or below 1.8%. Pass.
- Crowded shorts could cost more. Candidate I's rejection recorded JETS at about 39% of float short and left borrow fees unverified.
- **Best-supported gross edge per trade.**
  - Direct test (T4): -2.68% at 5 days, -2.91% at 10, -0.88% at 20.
  - Nearest in-house measure: first-hop hedged after non-onset events, +0.8% at 4 weeks, 76th percentile, CI -1.1% to +2.5%. This is first-hop drift, not text reading, and it does not reach the 95th-percentile bar (VERIFIED, `shock_nononset_event_study_2026-10.md`).
  - Literature: LLM link networks show a 4.67% annual long-short return, about 0.37% per 20 trading days, which is below cost (VERIFIED, dossier section 3.5; different mechanism).
  - Searches found no study of drift after Federal Register or OFAC notices. One adjacent secondary summary describes abnormal returns concentrated in the first few trading days and fading over weeks (not read in the original).
- Net of base cost: -3.33% at 5 days, -3.56% at 10, -1.53% at 20.

## T4 Next-open survival: fails

**Method.** I fixed the pairs and signs in code before computing returns, using a first-order reading of each notice.

- Gap: hedged return from the close before d0 to the open after d0, in the predicted direction. This is what an evening reader cannot capture.
- Post: from the open after d0 to the close 5, 10 or 20 trading days later.
- Prices: Nasdaq historical open and close (VERIFIED output); not dividend-adjusted.
- Placebo: the same pair on other days since 2026-03-02, excluding event dates, 4,000 pooled draws.

| Case | d0 | Set | Long / short | Gap | +5 | +10 | +20 |
|---|---|---|---|---:|---:|---:|---:|
| Jones Act waiver | 03-18 | pre | IYT / KEX | +0.61 | -9.08 | -6.74 | -2.74 |
| GL 133 Russian oil, India | 03-05 | pre | FRO DHT / XOP | -7.62 | -10.38 | -11.86 | -3.28 |
| GL 134 Russian oil, global | 03-12 | pre | FRO DHT / XOP | -8.09 | -2.74 | -4.52 | +7.63 |
| GL U Iranian oil at sea | 03-20 | pre | FRO DHT / XOP | -0.06 | -4.94 | -0.56 | +6.40 |
| GL X Iranian oil authorised | 06-22 | pre | VLO MPC / XOP | +1.68 | +5.35 | +10.04 | +13.47 |
| EPA E15 national pool | 03-25 | pre | GPRE REX / VLO MPC | +0.90 | +6.80 | +5.02 | +11.76 |
| SPR award, 45.2 mb | 03-20 | pre | MPC / VLO | +0.60 | -0.05 | -0.46 | -3.35 |
| SPR award, 53.3 mb | 05-11 | pre | MPC / VLO | +0.05 | -1.53 | +1.10 | +0.43 |
| Venezuela GL 46B | 03-13 | pre | VLO / MPC | -0.65 | +0.26 | +0.27 | +3.25 |
| GL X1 revokes GL X | 07-07 | post | XOP / VLO MPC | +3.52 | -6.22 | -5.34 | -7.54 |
| OFAC Shamkhani shipping network | 07-14 | post | FRO DHT / SEA | +0.38 | -0.79 | -0.15 | +0.16 |
| Jones Act extension, narrowed | 08-10 | post | KEX / IYT | +3.61 | +3.93 | +1.09 | +8.22 |
| EPA 15% ethanol, RVP waived | 08-20 | post | GPRE REX / VLO MPC | +2.29 | -11.32 | -14.23 | -19.37 |
| Venezuela GL 46D set | 08-27 | post | VLO / MPC | -0.41 | -0.40 | +1.04 | +4.87 |
| Diesel export ban talk (no text) | 09-22 | post | KNX JBHT / VLO MPC | +3.10 | -6.38 | -17.41 | -21.40 |
| Venezuela GL 46E | 09-28 | post | VLO / MPC | +1.41 | -3.23 | -5.15 | -12.54 |
| OFAC shadow-fleet action | 10-08 | post | FRO DHT / SEA | +1.73 | -2.73 | -1.53 | n/a |
| DPA s.303 determination | 10-22 | post | VLO MPC / SPY | +0.33 | -4.88 | n/a | n/a |

| Pool | Measure | n | Mean | Placebo mean | Percentile | Positive |
|---|---|---:|---:|---:|---:|---:|
| All | Gap | 18 | +0.19% | +0.02% | 61.8 | 13/18 |
| All | +5 | 18 | -2.68% | -0.05% | 1.2 | 4/18 |
| All | +10 | 17 | -2.91% | -0.37% | 5.0 | 6/17 |
| All | +20 | 16 | -0.88% | -1.05% | 53.9 | 9/16 |
| Post-cutoff | Gap | 9 | +1.77% | -0.14% | 99.2 | 8/9 |
| Post-cutoff | +5 | 9 | -3.56% | -0.42% | 3.2 | 1/9 |
| Post-cutoff | +10 | 8 | -5.21% | -1.44% | 3.7 | 2/8 |
| Post-cutoff | +20 | 7 | -6.80% | -3.87% | 18.4 | 3/7 |
| Pre-cutoff | Gap | 9 | -1.40% | +0.18% | 3.6 | 5/9 |
| Pre-cutoff | +5 | 9 | -1.81% | +0.30% | 10.6 | 3/9 |
| Pre-cutoff | +10 | 9 | -0.86% | +0.53% | 27.3 | 4/9 |
| Pre-cutoff | +20 | 9 | +3.73% | +1.14% | 84.5 | 6/9 |

Robustness (VERIFIED output):

- Without refiner legs (n=7): +5 -3.82%, +10 -3.47%, +20 +2.73% (n=6).
- With refiner legs (n=11): +5 -1.96%, +10 -2.51%, +20 -3.04% (n=10).
- So the 5-day and 10-day loss is not only the 2026 refiner rally. The refiner rally does drive much of the 20-day post-cutoff figure.

**What this shows.**

- Post-cutoff, the move was mostly gone by the next open. Pre-cutoff, the gap went the wrong way on average. Either way, nothing positive remains at 5 or 10 days.
- The one favourable pocket is pre-cutoff +20 days, at the 84.5th percentile. It is not significant, and it reverses post-cutoff.
- The text often arrives after the market knows:
  - GL U followed Bessent's public remarks earlier that week (VERIFIED, secondary).
  - GL 134 was announced by Bessent on X on 03-12 (VERIFIED, law-firm footnote).
  - The Jones Act waiver followed a social-media post, and CBP's guidance followed that (VERIFIED, Holland & Knight).
  - The refiner move of 09-22 had no text at all (VERIFIED, 24/7 Wall St: "Nothing has been signed").
- Federal Register publication lags further: GL U 82 days, GL X 100 days, GL 46D 34 days (VERIFIED). FR abstracts say the licences were "previously made available on OFAC's website." FR is a record, not a source of timing.

**Limits of this test.**

- n is small and windows overlap.
- The mapping is mine: one first-order pass, not a deployed multi-step LLM reader.
- Some signs were chosen after search results had shown me refiners rallying in September, so the post-cutoff refiner cases are not fully blind.
- Some pairs are arguable. Tanker sign, MPC vs VLO for SPR awards and VLO vs MPC for Venezuela are the weakest.
- Four of nine post-cutoff cases sit within one session of a dated qualifying shock event (07-07, 08-10, 09-22, 10-08), so policy and kinetic effects are confounded.
- These limits make the negative numbers imprecise. None of them produces a positive edge.

## T5 Overlap: serious

- **Candidate I, cooldown to 2027-01-17.** Same shape: a shock-native, hedged, event-triggered trade held for weeks, with an LLM judging exposure. A notice is a different trigger, but most mapped firms are the same first-hop refiners, tankers and carriers. I's rejection reason applies: the return is classical post-event drift and the AI layer is an unmeasured overlay. Checked `state.strategy_candidates`; the row and date are VERIFIED. Whether SL1 would rule this the same archetype is a judgment, UNVERIFIED.
- **Second-hop transmission, refuted.** The idea's own claim, "through several steps", is the second-hop thesis in new words. Measured second-hop drift was +0.6% at 4 weeks, placebo level (VERIFIED, candidate row provenance).
- **B.** Overlaps on post-event reaction to public information. B is long-biased and binds under acute, so this is only partial.
- **E.** VLO/MPC is a same-industry-group pair and overlaps E's construction. E binds under acute.
- A, C, D: little overlap.

## T6 Mechanical baseline: fails

- Non-AI version: sector mapping from a static link table, entered after any qualifying event. Measured +0.8% at 4 weeks (76th percentile), not distinguishable from placebo.
- What the AI must add: a better sign and a call on what is already priced, by name. It would have to beat the baseline by more than 0.65% to 1.25% per trade.
- What I measured: my own Claude mapping earned less than placebo at 5 and 10 days, and less than the mechanical baseline at every comparable horizon in the pooled sample. **The AI adds nothing measurable here**, on this small and imperfect test.
- Separate adverse evidence is recorded in candidate I's rejection: frontier LLM stock-selection alpha about zero to negative in a masked test (KTD-Fin), and LLM news predictability weakest on the short side and strongest over next-day horizons. Secondary to this memo; I did not re-read those papers.

## T7 Data and execution: passes

- FR API, OFAC pages, EPA waiver page and energy.gov pages all answered from this host (VERIFIED). No key was needed. OFAC and EPA have no API that I used, so these are HTML parses that can break.
- Social-media pre-announcements are not covered by those feeds. Leaving them out means reading late; adding them is noisier.
- Pairs use US stocks and ETFs. Fractional shorts are recorded as permitted (`bigquery/133`, VERIFIED).
- No human step beyond the confirm tap. Two legs may mean two taps, and one leg can be confirmed or filled without the other.

## T8 Test feasibility: enough to reject, not enough to confirm

- Post-cutoff tested cases: 9 distinct dates.
- Independent windows from those dates: 6 at 5-day spacing, 4 at 20-day spacing (07-07, 08-10, 09-22, 10-22) (VERIFIED output).
- Further post-cutoff notices exist: 8 substantive in T2 (some already among the 9), plus 9 OFAC actions naming vessels.
- Four independent windows cannot prove an edge. They already lean the wrong way, with 1 of 9 positive at 5 days.

## One suggestion, not a rescue

Keep the notice feeds as context for existing reviews, such as a D or E thesis check on a named exposure. Do not make them a strategy. I did not test fading the mapped direction. The sign flip would look positive in this sample, but that is a result of mining 18 cases.

## Sources

- Federal Register API: FR docs 2026-11614, 2026-20010, 2026-20009, 2026-08016, 2026-22052.
- OFAC recent actions: https://ofac.treasury.gov/recent-actions
- EPA fuel waivers: https://www.epa.gov/enforcement/fuel-waivers
- DOE: https://www.energy.gov/hgeo/opr/articles/energy-department-awards-new-contracts-strategic-petroleum-reserve-advancing and https://www.energy.gov/hgeo/opr/articles/energy-department-awards-contracts-strategic-petroleum-reserve-part-president
- SPR ledger (secondary): https://thevaultreport.com/research/why-the-spr-is-falling-2026-exchange-award-ledger
- Holland & Knight on the Jones Act: https://www.hklaw.com/en/insights/publications/2026/03/jones-act-waiver-issued-in-response-to-iran-conflict and https://www.hklaw.com/en/insights/publications/2026/08/dhs-extends-jones-act-waiver-again
- Baker McKenzie on GL U: https://sanctionsnews.bakermckenzie.com/ofac-issues-iran-related-general-license-authorizing-delivery-and-sale-of-iranian-origin-crude-oil-and-petroleum-products-and-amends-russia-related-general-license-134
- Paul Weiss on GL 134 series: https://www.paulweiss.com/insights/client-memos/ofac-issues-coordinated-energy-related-general-licenses-for-venezuela-russia-and-iran
- Blank Rome on GL X: https://www.blankrome.com/news-and-events/ofac-issues-a-general-license-authorizing-transactions-in-iranian-oil-petrochemical-products-and-petroleum-products-for-60-days
- Diesel ban: https://247wallst.com/investing/2026/09/24/trump-wants-to-ban-diesel-exports-refiners-are-selling-off
- Prices: `api.nasdaq.com/api/quote/{T}/historical`.
- Repo: Strategy.md register; `bigquery/133_sl1_research_leads_and_record_corrections.sql`; `ops/research/shock_nononset_event_study_2026-10.md`; `ops/research/shock_native_candidate_dossier_2026-10-19.md`; `state.strategy_candidates`.
