# Shock-episode event study: do SECOND-HOP industries drift after an oil / geopolitical supply shock? (2026-10-19)

**What this is.** The one measurement the shock-native dossier
(`ops/research/shock_native_candidate_dossier_2026-10-19.md`, Sections 3.5-3.6) said no published source
provides and SL1 needs: whether economic-link drift is bigger, smaller or just noisier IN SHOCK MONTHS, over
what horizon, and against what base rate. Public data only, a static public link map (the BEA input-output use
table), no LLM in the loop, so none of it is contaminated by model memorisation. It is an input to SL1's next
synthesis (first trading day of 2027-Q1). It is not a candidate row, not a Strategy.md edit and not a backtest
of the candidate's LLM mapping step (that can only be forward-tested, dossier Section 3.6).

**Reproduce.** `scripts/research/shock_episode_event_study.py` (standard library + numpy + pandas):

```bash
python scripts/research/shock_episode_event_study.py all --data-dir /tmp/shock_study --source french
python scripts/research/shock_episode_event_study.py all --data-dir /tmp/shock_study --source nasdaq
python scripts/research/shock_episode_event_study.py study --data-dir /tmp/shock_study --source french --hop2-rule literal
python scripts/research/shock_episode_event_study.py study --data-dir /tmp/shock_study --source nasdaq --baskets-only
```

Every number below was produced by those commands on 2026-10-19 (French data through 2026-08-31, Nasdaq data
through 2026-10-16, BEA 2023 use table from the 2024-09 static bundle). The downloads (~60 MB) are not in the
repo; the script re-fetches them. Placebo draws are seeded, so a re-run reproduces the tables exactly given the
same data vintage.

## 1. The question, made precise

For each episode onset (first trading day on/after the trigger) and horizon h in {1, 2, 4, 6, 8, 12} weeks:

- `d0` = the onset day's own market-hedged return (the announcement reaction; not tradeable by a strategy that
  reads the news that morning).
- `CAR_h` = cumulative market-hedged return over trading days 1..5h AFTER the onset day, i.e. the drift a day-1
  entry could earn. Beta is OLS over the 252 trading days before onset vs the market (Fama-French market
  factor for the French source, SPY for Nasdaq).
- Reported for the SECOND-hop basket, the FIRST-hop basket, and the spread second minus first; pooled over
  shock episodes with a percentile bootstrap over episodes (n is 6 or 3: the CI is honest, not powerful);
  the same statistics over 12 seeded placebo onsets (random trading days at least 26 weeks from every listed
  event, 1991-2026) and a 500-draw placebo distribution. The "percentile" row is where the pooled shock mean
  falls among pooled means of same-size random draws from those 500 placebo windows, which is the base rate the
  project's "backtest a detector before building it" rule asks for. The "dispersion" row compares the SD of the
  per-episode CARs with the SD of single placebo windows: the "noisier?" half of the question.

Episodes (onset): 1990-08-02 Iraq-Kuwait, 2003-03-19 Iraq, 2011-02-15 Libya, 2019-09-16 Abqaiq, 2022-02-24
Ukraine, 2026-03-02 Iran / Hormuz (2026-02-28 was a Saturday). Negative controls (demand shocks, not supply):
2008-07-14 (oil peak) and 2020-03-09 (COVID + price war).

## 2. Link map (BEA use table, summary level, 2023, after redefinitions, producers' prices)

Source: `https://apps.bea.gov/industry/iTables Static Files/AllTablesIO.zip`, file
`IOUse_After_Redefinitions_PRO_1997-2023_Summary.xlsx`, sheet `2023`, parsed with the standard library (no
openpyxl in the venv). Universe = the 71 summary industries minus government (5), "Management of companies"
(55: a holding-company overhead row with no product) and "Housing" (HS: an imputation) = 64 industries.
Petroleum = commodities 211 (oil and gas extraction) + 324 (petroleum and coal products).

**First hop = top decile (7 of 64) by direct(j) = max(petroleum input share of j's output, share of j's output
sold to petroleum).** Runners-up, for the record: 325 chemicals 0.054, 482 rail 0.043, 484 truck 0.038.

| BEA code | Industry | petroleum input share | petroleum output share | direct score |
|---|---|---:|---:|---:|
| 211 | Oil and gas extraction | 0.066 | 1.004 | 1.004 |
| 324 | Petroleum and coal products | 0.541 | 0.034 | 0.541 |
| 486 | Pipeline transportation | 0.003 | 0.345 | 0.345 |
| 213 | Support activities for mining | 0.008 | 0.159 | 0.159 |
| 481 | Air transportation | 0.130 | 0.001 | 0.130 |
| 483 | Water transportation | 0.077 | 0.010 | 0.077 |
| 22 | Utilities | 0.055 | 0.021 | 0.055 |

(211's output share exceeds 1 because the use table's total-commodity-output column nets imports; it is first
hop by definition either way.)

**Second hop, primary rule ("weighted") = top decile (6 of the remaining 57) by a two-hop transmission
coefficient:** score(j) = sum over first-hop i NOT in {211, 324} of [a(i->j) + a(j->i)] x direct(i), where
a(i->j) is the input coefficient (dollars of i per dollar of j's output) and a(j->i) the share of j's output sold
to i. The link is weighted by how petroleum-exposed the intermediate industry is, and the petroleum commodities
themselves are excluded as intermediates. Without that exclusion the brief's literal wording selects rail,
trucking and chemicals: industries that buy diesel and naphtha DIRECTLY, i.e. first-order exposure ranked
8-13, exactly the thing Section 3.4 of the dossier says the market prices fast.

| BEA code | Industry | two-hop score | via (first-hop industry: contribution) |
|---|---|---:|---|
| 487OS | Other transportation and support activities (airports, ports, freight forwarding, couriers) | 0.0134 | 481: 0.0102, 486: 0.0013, 22: 0.0012, 483: 0.0007 |
| 212 | Mining, except oil and gas | 0.0081 | 22: 0.0048, 213: 0.0030 |
| 532RL | Rental and leasing services and lessors of intangible assets | 0.0054 | 481: 0.0034, 483: 0.0010, 213: 0.0005, 22: 0.0004 |
| 523 | Securities, commodity contracts, and investments | 0.0033 | 213: 0.0021, 481: 0.0008 |
| 561 | Administrative and support services | 0.0028 | 486: 0.0009, 481: 0.0008, 22: 0.0005, 483: 0.0005 |
| 327 | Nonmetallic mineral products | 0.0028 | 22: 0.0015, 481: 0.0005, 213: 0.0005 |

**Second hop, robustness rule ("literal", the brief's wording) = top decile by max(input share from ALL
first-hop industries, output share to them):**

| BEA code | Industry | input share from first hop | output share to first hop | score |
|---|---|---:|---:|---:|
| 487OS | Other transportation and support activities | 0.047 | 0.106 | 0.106 |
| 212 | Mining, except oil and gas | 0.073 | 0.079 | 0.079 |
| 482 | Rail transportation | 0.046 | 0.065 | 0.065 |
| 484 | Truck transportation | 0.057 | 0.031 | 0.057 |
| 325 | Chemical products | 0.035 | 0.056 | 0.056 |
| 532RL | Rental and leasing services and lessors of intangible assets | 0.010 | 0.056 | 0.056 |

Both rules share 487OS, 212 and 532RL. Note what the table says about the candidate archetype: at the
71-industry level the strongest second-hop channels run through AIRLINES (airport services, aircraft lessors)
and UTILITIES (mining, nonmetallic minerals), not through the refinery-to-converter chain the 2026 narrative
emphasised; that chain (324 -> 325 chemicals -> 326 plastics) is a direct-input link in the use table and is
first-order by this map.

## 3. Price data and proxies

The brief specified Yahoo Finance's v8 chart endpoint. **It was unusable from this host for the whole session:
`query1`/`query2.finance.yahoo.com` returned HTTP 429 to every request from the first call onwards, with or
without the cookie + crumb handshake, after waits of 1.5, 4 and ~40 minutes** (the brief's note that curl with
a browser User-Agent works did not hold today). The downloader is implemented (`--source yahoo`) and nothing
else about the pipeline depends on it; two other public, key-less sources were used instead:

| Source | What | Covers | Caveats |
|---|---|---|---|
| `french` (primary) | Kenneth French daily value-weighted 49-industry portfolios (CRSP universe) + daily Fama-French market factor | 1926-07 to 2026-08-31: ALL six shocks and both controls | SIC-based industries are coarser than BEA's: Oil = 211+213+324; Trans = 481+483+486 AND 482/484/487OS (so those three second-hop members fold into the first hop and drop out of the second); 212 -> Mines + Coal; 327 -> BldMt (also lumber, hardware); 523 -> Fin ("Trading": brokers, exchanges, holding offices, REITs); 561 and 532RL -> BusSv. No survivorship bias; value-weighted across every listed firm, so NOT the 5-10 large-cap basket a strategy would trade. |
| `nasdaq` (ETF-era cross-check) | api.nasdaq.com daily closes for the proxy table below | 2016-10-17 to 2026-10-16: the 2019, 2022 and 2026 shocks plus the 2020 control | Split-adjusted but NOT dividend-adjusted (12-week dividend drift about 0.5% or less, larger for AMLP/XLU); 10-year cap on history; no index series, so the market is SPY. |

**Proxy table** (ETF-first where a matched sub-industry ETF exists; otherwise an equal-weighted basket of
large US-listed names in the matched GICS sub-industry, chosen from TODAY's constituents by the author rather
than by a dated market-cap screen: a survivorship-biased rule by construction, stated here once). A basket
member counts only if its history covers the beta window and the full 12-week horizon; a hop needs at least 3
industries, an industry basket at least 3 members. Tickers Nasdaq returned no data for and that therefore
never count: AL, ET, GOGL, HES. Short histories that excluded a name from the 2019 window only: ADT, BKR, BTU,
DD, DOW, LIN; SEA (2022 listing) counts only in 2026.

| BEA code | Hop | ETF | Basket (equal-weighted) |
|---|---|---|---|
| 211 | first | XOP | XOM CVX COP EOG OXY DVN APA HES |
| 324 | first | CRAK | VLO MPC PSX DINO PBF CVI |
| 486 | first | AMLP | KMI WMB OKE EPD ET MPLX TRGP PAA |
| 213 | first | OIH | SLB HAL BKR NOV FTI HP PTEN |
| 481 | first | JETS | DAL UAL AAL LUV ALK JBLU SKYW ALGT |
| 483 | first | SEA (2022 listing) | KEX MATX FRO GOGL STNG DAC |
| 22 | first | XLU | NEE DUK SO D AEP EXC SRE XEL |
| 487OS | second (both rules) | none | FDX UPS EXPD CHRW LSTR HUBG FWRD |
| 212 | second (both) | XME (metals and mining incl. steel: imperfect) | FCX NEM VMC MLM BTU CLF HL RGLD |
| 532RL | second (both) | none | URI CAR AER AL GATX R WSC |
| 523 | second (weighted) | IAI | GS MS SCHW ICE CME NDAQ RJF LPLA |
| 561 | second (weighted) | none | BKNG EXPE RHI MAN ROL ABM ADT |
| 327 | second (weighted) | none | EXP OC USLM CRH APOG MLM |
| 482 | second (literal) | none | UNP CSX NSC CP CNI |
| 484 | second (literal) | none | ODFL JBHT KNX SAIA XPO WERN ARCB |
| 325 | second (literal) | none | LIN SHW APD ECL DD DOW LYB PPG |

## 4. Results, primary: French 49 industries, weighted second hop, six shocks 1990-2026

**Spread: second hop minus first hop**

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1990 Iraq-Kuwait | 1990-08-02 | 3/5 | 0.85 / 0.70 | -0.7% | -0.2% | +0.3% | -3.5% | -4.4% | -7.2% | -14.1% |
| 2003 Iraq | 2003-03-19 | 3/5 | 0.80 / 0.96 | -0.2% | -0.9% | +0.4% | +0.6% | +0.1% | +3.7% | +5.4% |
| 2011 Libya | 2011-02-15 | 3/5 | 0.99 / 1.40 | -0.6% | -2.3% | -1.1% | +0.3% | -1.8% | -1.7% | -8.2% |
| 2019 Abqaiq | 2019-09-16 | 3/5 | 0.81 / 1.05 | -1.4% | -1.7% | -1.1% | +0.5% | +1.2% | -2.5% | -0.5% |
| 2022 Ukraine | 2022-02-24 | 3/5 | 0.70 / 1.13 | -1.4% | +2.3% | +1.5% | -0.9% | -2.6% | -3.8% | -2.0% |
| 2026 Iran / Hormuz | 2026-03-02 | 3/5 | 0.75 / 1.03 | +0.0% | -1.9% | -3.7% | -5.1% | -1.4% | -4.8% | -5.2% |
| 2008-07 oil peak (demand, control) | 2008-07-14 | 3/5 | 0.93 / 1.33 | +0.4% | +1.6% | +1.6% | -2.7% | -0.7% | -3.1% | -9.8% |
| 2020-03 COVID / price war (demand, control) | 2020-03-09 | 3/5 | 0.89 / 1.06 | +3.5% | +6.0% | +2.9% | -3.7% | -6.3% | -4.7% | -3.3% |
| **Pooled shocks** mean | | | | -0.7% [-1.2%, -0.3%] 1/6>0 | -0.8% [-1.8%, +0.6%] 1/6>0 | -0.6% [-2.1%, +0.5%] 3/6>0 | -1.4% [-3.2%, +0.3%] 3/6>0 | -1.5% [-2.9%, -0.1%] 2/6>0 | -2.7% [-5.1%, +0.2%] 1/6>0 | -4.1% [-8.9%, +0.9%] 1/6>0 |
| Pooled demand controls mean | | | | +1.9% [+0.4%, +3.5%] 2/2>0 | +3.8% [+1.6%, +6.0%] 2/2>0 | +2.2% [+1.6%, +2.9%] 2/2>0 | -3.2% [-3.7%, -2.7%] 0/2>0 | -3.5% [-6.3%, -0.7%] 0/2>0 | -3.9% [-4.7%, -3.1%] 0/2>0 | -6.5% [-9.8%, -3.3%] 0/2>0 |
| 12 placebo onsets mean | | | | -0.0% [-0.3%, +0.3%] 6/12>0 | -0.7% [-1.5%, +0.1%] 5/12>0 | -0.6% [-1.5%, +0.8%] 4/12>0 | -0.5% [-3.7%, +3.1%] 5/12>0 | -0.1% [-2.6%, +2.8%] 4/12>0 | +1.2% [-1.5%, +4.2%] 8/12>0 | +1.1% [-3.1%, +5.0%] 8/12>0 |
| 500 placebo onsets mean | | | | +0.0% [-0.0%, +0.1%] 247/500>0 | +0.0% [-0.1%, +0.2%] 255/500>0 | +0.0% [-0.2%, +0.2%] 250/500>0 | -0.1% [-0.4%, +0.2%] 256/500>0 | -0.1% [-0.5%, +0.3%] 254/500>0 | -0.1% [-0.6%, +0.3%] 249/500>0 | -0.1% [-0.6%, +0.4%] 267/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 11th pct | 25th pct | 18th pct | 20th pct | 10th pct | 5th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +1.7% vs +1.7% | +1.8% vs +2.5% | +2.4% vs +3.6% | +2.0% vs +4.5% | +3.7% vs +5.2% | +6.7% vs +5.8% |

**Second hop (hedged)**

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1990 Iraq-Kuwait | 1990-08-02 | 3/5 | 0.85 / 0.70 | +0.9% | -1.3% | -0.5% | -4.6% | -3.5% | -6.4% | -12.8% |
| 2003 Iraq | 2003-03-19 | 3/5 | 0.80 / 0.96 | -0.2% | +0.3% | +1.3% | +2.0% | +1.1% | +5.3% | +8.9% |
| 2011 Libya | 2011-02-15 | 3/5 | 0.99 / 1.40 | -0.4% | -0.5% | +0.5% | +2.5% | +1.2% | -0.3% | -6.7% |
| 2019 Abqaiq | 2019-09-16 | 3/5 | 0.81 / 1.05 | +0.1% | -2.8% | -2.9% | -2.9% | -2.1% | -7.2% | -7.3% |
| 2022 Ukraine | 2022-02-24 | 3/5 | 0.70 / 1.13 | -2.4% | +6.4% | +9.2% | +5.5% | +4.0% | +5.1% | +11.5% |
| 2026 Iran / Hormuz | 2026-03-02 | 3/5 | 0.75 / 1.03 | +0.6% | -3.0% | -3.4% | +0.9% | -3.4% | -6.7% | -11.2% |
| 2008-07 oil peak (demand, control) | 2008-07-14 | 3/5 | 0.93 / 1.33 | +0.8% | -1.7% | -2.8% | -11.2% | -6.6% | -13.8% | -17.8% |
| 2020-03 COVID / price war (demand, control) | 2020-03-09 | 3/5 | 0.89 / 1.06 | -1.8% | +0.9% | -6.7% | -5.7% | -8.5% | -5.4% | +0.0% |
| **Pooled shocks** mean | | | | -0.2% [-1.2%, +0.5%] 3/6>0 | -0.1% [-2.2%, +2.7%] 2/6>0 | +0.7% [-2.2%, +4.4%] 3/6>0 | +0.6% [-2.2%, +3.2%] 4/6>0 | -0.5% [-2.5%, +1.8%] 3/6>0 | -1.7% [-5.7%, +2.4%] 2/6>0 | -2.9% [-10.1%, +4.6%] 2/6>0 |
| Pooled demand controls mean | | | | -0.5% [-1.8%, +0.8%] 1/2>0 | -0.4% [-1.7%, +0.9%] 1/2>0 | -4.8% [-6.7%, -2.8%] 0/2>0 | -8.5% [-11.2%, -5.7%] 0/2>0 | -7.6% [-8.5%, -6.6%] 0/2>0 | -9.6% [-13.8%, -5.4%] 0/2>0 | -8.9% [-17.8%, +0.0%] 1/2>0 |
| 12 placebo onsets mean | | | | +0.3% [-0.1%, +0.6%] 7/12>0 | -0.7% [-1.7%, +0.1%] 5/12>0 | -0.6% [-2.4%, +1.8%] 4/12>0 | -1.1% [-4.1%, +2.3%] 5/12>0 | -0.5% [-2.9%, +2.4%] 3/12>0 | +1.5% [-1.6%, +5.1%] 7/12>0 | +1.7% [-2.8%, +6.7%] 7/12>0 |
| 500 placebo onsets mean | | | | -0.0% [-0.1%, +0.0%] 237/500>0 | +0.0% [-0.1%, +0.2%] 262/500>0 | +0.0% [-0.2%, +0.2%] 249/500>0 | +0.1% [-0.2%, +0.4%] 271/500>0 | +0.2% [-0.2%, +0.5%] 263/500>0 | +0.4% [-0.0%, +0.8%] 282/500>0 | +0.5% [-0.0%, +1.0%] 289/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 39th pct | 79th pct | 65th pct | 33th pct | 13th pct | 7th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +3.5% vs +1.5% | +4.6% vs +2.2% | +3.7% vs +3.2% | +3.0% vs +4.0% | +5.9% vs +4.6% | +10.5% vs +5.5% |

**First hop (hedged)**

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1990 Iraq-Kuwait | 1990-08-02 | 3/5 | 0.85 / 0.70 | +1.6% | -1.1% | -0.7% | -1.1% | +0.9% | +0.9% | +1.3% |
| 2003 Iraq | 2003-03-19 | 3/5 | 0.80 / 0.96 | +0.0% | +1.2% | +0.9% | +1.4% | +1.0% | +1.7% | +3.5% |
| 2011 Libya | 2011-02-15 | 3/5 | 0.99 / 1.40 | +0.2% | +1.7% | +1.6% | +2.3% | +3.0% | +1.5% | +1.5% |
| 2019 Abqaiq | 2019-09-16 | 3/5 | 0.81 / 1.05 | +1.5% | -1.1% | -1.9% | -3.4% | -3.3% | -4.7% | -6.8% |
| 2022 Ukraine | 2022-02-24 | 3/5 | 0.70 / 1.13 | -1.0% | +4.2% | +7.7% | +6.4% | +6.6% | +8.9% | +13.5% |
| 2026 Iran / Hormuz | 2026-03-02 | 3/5 | 0.75 / 1.03 | +0.6% | -1.1% | +0.4% | +6.0% | -2.0% | -1.9% | -6.1% |
| 2008-07 oil peak (demand, control) | 2008-07-14 | 3/5 | 0.93 / 1.33 | +0.4% | -3.3% | -4.5% | -8.5% | -5.9% | -10.7% | -8.0% |
| 2020-03 COVID / price war (demand, control) | 2020-03-09 | 3/5 | 0.89 / 1.06 | -5.3% | -5.2% | -9.6% | -2.0% | -2.2% | -0.7% | +3.3% |
| **Pooled shocks** mean | | | | +0.5% [-0.3%, +1.2%] 5/6>0 | +0.6% [-0.7%, +2.3%] 3/6>0 | +1.3% [-0.7%, +4.0%] 4/6>0 | +1.9% [-0.9%, +4.8%] 4/6>0 | +1.0% [-1.4%, +3.8%] 4/6>0 | +1.0% [-1.8%, +4.6%] 4/6>0 | +1.2% [-3.8%, +6.6%] 4/6>0 |
| Pooled demand controls mean | | | | -2.5% [-5.3%, +0.4%] 1/2>0 | -4.2% [-5.2%, -3.3%] 0/2>0 | -7.0% [-9.6%, -4.5%] 0/2>0 | -5.3% [-8.5%, -2.0%] 0/2>0 | -4.0% [-5.9%, -2.2%] 0/2>0 | -5.7% [-10.7%, -0.7%] 0/2>0 | -2.3% [-8.0%, +3.3%] 1/2>0 |
| 12 placebo onsets mean | | | | +0.3% [+0.1%, +0.5%] 9/12>0 | -0.0% [-0.7%, +0.5%] 8/12>0 | -0.1% [-1.2%, +1.1%] 6/12>0 | -0.6% [-1.5%, +0.4%] 5/12>0 | -0.4% [-1.4%, +0.7%] 3/12>0 | +0.3% [-1.4%, +1.9%] 4/12>0 | +0.6% [-1.6%, +2.8%] 7/12>0 |
| 500 placebo onsets mean | | | | -0.0% [-0.1%, +0.0%] 239/500>0 | -0.0% [-0.1%, +0.1%] 262/500>0 | +0.0% [-0.2%, +0.2%] 259/500>0 | +0.2% [-0.0%, +0.4%] 275/500>0 | +0.3% [+0.0%, +0.6%] 285/500>0 | +0.5% [+0.2%, +0.8%] 280/500>0 | +0.5% [+0.2%, +0.9%] 255/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 90th pct | 96th pct | 95th pct | 73th pct | 64th pct | 64th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +2.2% vs +1.3% | +3.3% vs +1.9% | +3.9% vs +2.6% | +3.5% vs +3.2% | +4.6% vs +3.6% | +7.4% vs +4.2% |

**Per-industry drift, pooled over the shock episodes vs the placebo base rate** (mean hedged CAR; `k/n` = positive episodes)

| Industry (hop) | d0 | 1w | 2w | 4w | 6w | 8w | 12w | placebo 12w |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 211:Oil (first) | +1.4% 3/6 | +2.2% 5/6 | +4.0% 4/6 | +4.6% 4/6 | +2.5% 3/6 | +2.8% 4/6 | +2.4% 2/6 | +0.5% |
| 212:Coal (second) | -0.2% 3/6 | +2.7% 3/6 | +6.9% 5/6 | +6.8% 3/6 | +4.7% 3/6 | +2.3% 3/6 | +2.7% 2/6 | +2.0% |
| 212:Mines (second) | -0.3% 2/6 | -1.7% 1/6 | -1.1% 2/6 | -1.9% 2/6 | -1.5% 2/6 | -4.8% 2/6 | -6.3% 3/6 | +0.2% |
| 22:Util (first) | +0.0% 4/6 | +1.3% 4/6 | +2.3% 5/6 | +2.1% 5/6 | +2.6% 3/6 | +2.3% 4/6 | +4.6% 4/6 | +1.1% |
| 327:BldMt (second) | -0.5% 0/6 | -1.4% 2/6 | -0.8% 4/6 | -1.9% 2/6 | -2.7% 2/6 | -1.8% 3/6 | -3.9% 3/6 | -0.2% |
| 486:Trans (first) | +0.1% 3/6 | -1.6% 1/6 | -2.3% 1/6 | -0.9% 2/6 | -2.0% 2/6 | -2.0% 1/6 | -3.5% 2/6 | -0.0% |
| 523:Fin (second) | -0.3% 2/6 | -0.5% 2/6 | -1.3% 1/6 | -0.7% 2/6 | -2.5% 2/6 | -3.4% 1/6 | -5.0% 2/6 | +0.5% |
| 532RL:BusSv (second) | +0.1% 4/6 | +0.1% 2/6 | -0.1% 3/6 | +0.5% 5/6 | -0.2% 3/6 | -0.7% 3/6 | -2.1% 3/6 | -0.2% |

Coverage is identical in every episode: first hop = Oil + Trans + Util; second hop = Mines + Coal + BusSv + Fin
+ BldMt (487OS and 561 fold into Trans and BusSv respectively).

## 5. Robustness

### 5.1 French 49, literal second-hop rule (Mines, Coal, Chems, BusSv; rail, truck and 487OS fold into Trans)

Spread, then second hop (pooled rows):

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| **Pooled shocks** mean | | | | -0.8% [-1.4%, -0.3%] 0/6>0 | -0.5% [-1.9%, +1.6%] 1/6>0 | +0.0% [-1.4%, +1.9%] 2/6>0 | -0.4% [-2.3%, +1.2%] 4/6>0 | -0.4% [-2.0%, +1.4%] 2/6>0 | -1.8% [-4.4%, +1.2%] 2/6>0 | -2.9% [-7.5%, +1.8%] 2/6>0 |
| 500 placebo onsets mean | | | | +0.0% [-0.0%, +0.1%] 249/500>0 | -0.0% [-0.2%, +0.2%] 249/500>0 | -0.1% [-0.3%, +0.2%] 236/500>0 | -0.2% [-0.5%, +0.2%] 249/500>0 | -0.2% [-0.6%, +0.2%] 244/500>0 | -0.1% [-0.6%, +0.4%] 244/500>0 | -0.1% [-0.6%, +0.4%] 256/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 26th pct | 54th pct | 44th pct | 44th pct | 21th pct | 12th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +2.5% vs +1.9% | +2.4% vs +2.7% | +2.4% vs +3.8% | +2.4% vs +4.6% | +3.8% vs +5.3% | +6.4% vs +6.1% |

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| **Pooled shocks** mean | | | | -0.3% [-1.4%, +0.6%] 2/6>0 | +0.1% [-2.3%, +3.6%] 2/6>0 | +1.3% [-1.8%, +6.0%] 3/6>0 | +1.5% [-2.2%, +5.0%] 4/6>0 | +0.7% [-2.4%, +4.9%] 3/6>0 | -0.8% [-6.0%, +4.6%] 2/6>0 | -1.7% [-9.6%, +7.5%] 2/6>0 |
| 500 placebo onsets mean | | | | -0.0% [-0.1%, +0.1%] 229/500>0 | -0.0% [-0.2%, +0.1%] 251/500>0 | -0.1% [-0.3%, +0.2%] 255/500>0 | +0.0% [-0.3%, +0.3%] 259/500>0 | +0.1% [-0.3%, +0.5%] 246/500>0 | +0.4% [-0.0%, +0.8%] 262/500>0 | +0.4% [-0.1%, +1.0%] 273/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 59th pct | 90th pct | 86th pct | 62th pct | 29th pct | 20th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +4.3% vs +1.9% | +5.6% vs +2.8% | +5.2% vs +3.7% | +5.1% vs +4.6% | +7.5% vs +5.2% | +12.1% vs +6.3% |

### 5.2 ETF-era cross-check: Nasdaq data, weighted rule, ETF-first proxies (3 shocks + the 2020 control)

**Spread: second hop minus first hop**

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1990 Iraq-Kuwait | 1990-08-02 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2003 Iraq | 2003-03-19 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2011 Libya | 2011-02-15 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2019 Abqaiq | 2019-09-16 | 11/28 | 0.99 / 1.03 | -2.3% | +0.7% | +1.7% | +1.1% | +4.6% | +5.3% | +7.9% |
| 2022 Ukraine | 2022-02-24 | 11/28 | 0.94 / 1.08 | +0.3% | -1.3% | -4.6% | -2.9% | -9.9% | -9.9% | -14.7% |
| 2026 Iran / Hormuz | 2026-03-02 | 7/28 | 0.89 / 1.06 | -1.0% | -2.8% | -6.6% | -8.8% | +2.0% | +2.2% | -0.3% |
| 2008-07 oil peak (demand, control) | 2008-07-14 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2020-03 COVID / price war (demand, control) | 2020-03-09 | 11/28 | 1.00 / 1.01 | +8.2% | -2.5% | -0.4% | +0.4% | -5.8% | -5.8% | -3.1% |
| **Pooled shocks** mean | | | | -1.0% [-2.3%, +0.3%] 1/3>0 | -1.1% [-2.8%, +0.7%] 1/3>0 | -3.2% [-6.6%, +1.7%] 1/3>0 | -3.5% [-8.8%, +1.1%] 1/3>0 | -1.1% [-9.9%, +4.6%] 2/3>0 | -0.8% [-9.9%, +5.3%] 2/3>0 | -2.4% [-14.7%, +7.9%] 1/3>0 |
| Pooled demand controls mean | | | | +8.2% [+8.2%, +8.2%] 1/1>0 | -2.5% [-2.5%, -2.5%] 0/1>0 | -0.4% [-0.4%, -0.4%] 0/1>0 | +0.4% [+0.4%, +0.4%] 1/1>0 | -5.8% [-5.8%, -5.8%] 0/1>0 | -5.8% [-5.8%, -5.8%] 0/1>0 | -3.1% [-3.1%, -3.1%] 0/1>0 |
| 12 placebo onsets mean | | | | -0.3% [-0.8%, +0.2%] 6/12>0 | -0.2% [-1.0%, +0.7%] 5/12>0 | -0.1% [-1.3%, +1.3%] 5/12>0 | +0.5% [-1.3%, +2.4%] 6/12>0 | +2.0% [+0.2%, +3.8%] 7/12>0 | +1.2% [-1.2%, +3.9%] 7/12>0 | +0.6% [-2.2%, +3.5%] 6/12>0 |
| 500 placebo onsets mean | | | | -0.0% [-0.1%, +0.1%] 252/500>0 | +0.1% [-0.0%, +0.3%] 273/500>0 | +0.1% [-0.2%, +0.3%] 247/500>0 | +0.2% [-0.1%, +0.6%] 257/500>0 | +0.3% [-0.1%, +0.7%] 272/500>0 | +0.4% [-0.0%, +0.8%] 281/500>0 | +0.7% [+0.3%, +1.2%] 283/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 12th pct | 2th pct | 4th pct | 30th pct | 31th pct | 15th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +1.8% vs +1.8% | +4.4% vs +2.6% | +5.0% vs +3.7% | +7.7% vs +4.6% | +8.0% vs +4.9% | +11.4% vs +5.2% |

**Second hop (hedged)**

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1990 Iraq-Kuwait | 1990-08-02 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2003 Iraq | 2003-03-19 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2011 Libya | 2011-02-15 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2019 Abqaiq | 2019-09-16 | 11/28 | 0.99 / 1.03 | +0.5% | -1.2% | -1.9% | -2.1% | +0.9% | -0.6% | -0.3% |
| 2022 Ukraine | 2022-02-24 | 11/28 | 0.94 / 1.08 | -0.7% | +1.3% | +2.7% | +2.0% | -4.0% | +1.7% | +3.4% |
| 2026 Iran / Hormuz | 2026-03-02 | 7/28 | 0.89 / 1.06 | -0.1% | -3.9% | -6.7% | -1.4% | +1.2% | +0.7% | -6.0% |
| 2008-07 oil peak (demand, control) | 2008-07-14 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2020-03 COVID / price war (demand, control) | 2020-03-09 | 11/28 | 1.00 / 1.01 | -2.0% | -4.3% | -5.0% | -4.7% | -4.9% | -2.0% | +6.8% |
| **Pooled shocks** mean | | | | -0.1% [-0.7%, +0.3%] 1/3>0 | -1.3% [-3.9%, +1.3%] 1/3>0 | -1.9% [-6.7%, +2.7%] 1/3>0 | -0.5% [-2.1%, +2.0%] 1/3>0 | -0.6% [-4.0%, +1.2%] 2/3>0 | +0.6% [-0.6%, +1.7%] 2/3>0 | -1.0% [-6.0%, +3.4%] 1/3>0 |
| Pooled demand controls mean | | | | -2.0% [-2.0%, -2.0%] 0/1>0 | -4.3% [-4.3%, -4.3%] 0/1>0 | -5.0% [-5.0%, -5.0%] 0/1>0 | -4.7% [-4.7%, -4.7%] 0/1>0 | -4.9% [-4.9%, -4.9%] 0/1>0 | -2.0% [-2.0%, -2.0%] 0/1>0 | +6.8% [+6.8%, +6.8%] 1/1>0 |
| 12 placebo onsets mean | | | | +0.1% [-0.4%, +0.5%] 6/12>0 | -0.9% [-2.2%, +0.5%] 2/12>0 | -1.5% [-3.0%, +0.0%] 3/12>0 | -0.4% [-2.8%, +2.0%] 5/12>0 | -0.3% [-2.8%, +2.5%] 6/12>0 | -1.4% [-4.4%, +1.4%] 5/12>0 | -1.1% [-5.5%, +3.7%] 5/12>0 |
| 500 placebo onsets mean | | | | -0.0% [-0.1%, +0.1%] 238/500>0 | -0.1% [-0.2%, +0.1%] 250/500>0 | -0.1% [-0.3%, +0.2%] 245/500>0 | -0.1% [-0.4%, +0.2%] 241/500>0 | -0.0% [-0.4%, +0.3%] 248/500>0 | -0.0% [-0.4%, +0.4%] 236/500>0 | -0.1% [-0.5%, +0.4%] 233/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 10th pct | 7th pct | 41th pct | 40th pct | 59th pct | 39th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +2.6% vs +1.7% | +4.7% vs +2.4% | +2.2% vs +3.3% | +2.9% vs +4.1% | +1.1% vs +4.6% | +4.7% vs +5.5% |

**First hop (hedged)**

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1990 Iraq-Kuwait | 1990-08-02 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2003 Iraq | 2003-03-19 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2011 Libya | 2011-02-15 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2019 Abqaiq | 2019-09-16 | 11/28 | 0.99 / 1.03 | +2.8% | -2.0% | -3.6% | -3.3% | -3.7% | -5.8% | -8.2% |
| 2022 Ukraine | 2022-02-24 | 11/28 | 0.94 / 1.08 | -1.0% | +2.6% | +7.3% | +4.9% | +5.9% | +11.6% | +18.1% |
| 2026 Iran / Hormuz | 2026-03-02 | 7/28 | 0.89 / 1.06 | +0.9% | -1.0% | -0.0% | +7.4% | -0.7% | -1.4% | -5.7% |
| 2008-07 oil peak (demand, control) | 2008-07-14 | 0/0 | - | skipped: outside the source's data span | | | | | | |
| 2020-03 COVID / price war (demand, control) | 2020-03-09 | 11/28 | 1.00 / 1.01 | -10.2% | -1.8% | -4.7% | -5.1% | +0.9% | +3.8% | +9.9% |
| **Pooled shocks** mean | | | | +0.9% [-1.0%, +2.8%] 2/3>0 | -0.1% [-2.0%, +2.6%] 1/3>0 | +1.2% [-3.6%, +7.3%] 1/3>0 | +3.0% [-3.3%, +7.4%] 2/3>0 | +0.5% [-3.7%, +5.9%] 1/3>0 | +1.4% [-5.8%, +11.6%] 1/3>0 | +1.4% [-8.2%, +18.1%] 1/3>0 |
| Pooled demand controls mean | | | | -10.2% [-10.2%, -10.2%] 0/1>0 | -1.8% [-1.8%, -1.8%] 0/1>0 | -4.7% [-4.7%, -4.7%] 0/1>0 | -5.1% [-5.1%, -5.1%] 0/1>0 | +0.9% [+0.9%, +0.9%] 1/1>0 | +3.8% [+3.8%, +3.8%] 1/1>0 | +9.9% [+9.9%, +9.9%] 1/1>0 |
| 12 placebo onsets mean | | | | +0.3% [-0.3%, +1.0%] 6/12>0 | -0.8% [-2.1%, +0.6%] 4/12>0 | -1.4% [-3.6%, +0.7%] 4/12>0 | -0.8% [-3.6%, +1.8%] 5/12>0 | -2.3% [-5.1%, +0.2%] 4/12>0 | -2.7% [-6.6%, +0.5%] 4/12>0 | -1.8% [-6.9%, +3.4%] 5/12>0 |
| 500 placebo onsets mean | | | | +0.0% [-0.1%, +0.1%] 233/500>0 | -0.2% [-0.4%, +0.0%] 234/500>0 | -0.1% [-0.4%, +0.2%] 238/500>0 | -0.3% [-0.7%, +0.1%] 207/500>0 | -0.3% [-0.8%, +0.2%] 199/500>0 | -0.4% [-1.0%, +0.2%] 193/500>0 | -0.8% [-1.4%, -0.2%] 183/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 52th pct | 79th pct | 90th pct | 64th pct | 72th pct | 74th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +2.4% vs +2.3% | +5.6% vs +3.4% | +5.6% vs +4.7% | +4.9% vs +5.9% | +9.0% vs +6.5% | +14.5% vs +7.2% |

Per-industry, same run:

| Industry (hop) | d0 | 1w | 2w | 4w | 6w | 8w | 12w | placebo 12w |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 211 (first) | +5.0% 2/3 | +0.6% 2/3 | +3.7% 2/3 | +6.1% 2/3 | -0.3% 2/3 | +2.0% 2/3 | +1.3% 1/3 | -1.2% |
| 212 (second) | +0.2% 2/3 | +1.4% 1/3 | +2.1% 1/3 | +2.4% 1/3 | +2.7% 1/3 | +2.7% 1/3 | +2.6% 1/3 | +0.6% |
| 213 (first) | +2.2% 1/3 | -1.9% 1/3 | +1.0% 1/3 | +2.3% 2/3 | -2.2% 2/3 | +2.1% 2/3 | +1.0% 1/3 | -2.6% |
| 22 (first) | -0.2% 2/3 | +2.0% 2/3 | +3.9% 3/3 | +2.7% 3/3 | +3.9% 2/3 | +2.0% 1/3 | +1.4% 1/3 | -0.9% |
| 324 (first) | +0.2% 2/3 | +1.8% 3/3 | +3.9% 3/3 | +6.4% 3/3 | +6.0% 3/3 | +6.8% 3/3 | +6.6% 2/3 | -0.7% |
| 327 (second) | -0.1% 1/3 | -3.7% 1/3 | -3.1% 1/3 | -3.4% 0/3 | -3.4% 1/3 | -2.4% 1/3 | -3.3% 2/3 | +0.7% |
| 481 (first) | -2.1% 0/3 | -4.8% 0/3 | -7.1% 0/3 | -3.7% 0/3 | -2.9% 1/3 | -1.0% 2/3 | -1.8% 1/3 | -1.4% |
| 483 (first) | +1.3% 2/3 | -0.7% 1/3 | +0.9% 2/3 | +6.6% 3/3 | +1.8% 1/3 | +0.4% 1/3 | +3.6% 2/3 | +1.6% |
| 486 (first) | +0.0% 2/3 | +2.0% 2/3 | +2.4% 2/3 | +0.5% 2/3 | -2.9% 1/3 | -2.3% 1/3 | -2.4% 1/3 | -0.3% |
| 487OS (second) | +0.3% 2/3 | -2.6% 1/3 | -4.4% 1/3 | -3.6% 0/3 | -6.6% 1/3 | -3.6% 0/3 | -6.0% 1/3 | -2.6% |
| 523 (second) | -0.2% 2/3 | -1.3% 1/3 | -2.9% 0/3 | -2.2% 1/3 | -4.6% 1/3 | -4.4% 0/3 | -5.2% 0/3 | +1.4% |
| 532RL (second) | +0.5% 2/3 | -1.7% 0/3 | -1.8% 1/3 | +2.7% 2/3 | +7.4% 2/3 | +10.5% 3/3 | +8.0% 3/3 | +0.9% |
| 561 (second) | -1.3% 1/3 | +0.2% 1/3 | -1.5% 1/3 | +0.9% 2/3 | +0.7% 2/3 | +0.9% 2/3 | -2.0% 2/3 | -1.4% |

### 5.3 ETF-era, other variants (pooled rows only)

Weighted rule, stock baskets only (no ETFs): spread, then second hop.

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| **Pooled shocks** mean | | | | -1.2% [-1.9%, -0.1%] 0/3>0 | -1.4% [-2.0%, -0.4%] 0/3>0 | -4.8% [-7.4%, -0.0%] 0/3>0 | -5.9% [-12.0%, -0.4%] 0/3>0 | -2.7% [-11.3%, +2.2%] 2/3>0 | -3.6% [-12.2%, +2.3%] 1/3>0 | -6.8% [-20.7%, +5.4%] 1/3>0 |
| 500 placebo onsets mean | | | | -0.1% [-0.2%, +0.0%] 247/500>0 | +0.0% [-0.1%, +0.2%] 256/500>0 | -0.0% [-0.3%, +0.2%] 253/500>0 | +0.1% [-0.3%, +0.4%] 247/500>0 | -0.1% [-0.6%, +0.4%] 267/500>0 | -0.1% [-0.6%, +0.4%] 267/500>0 | +0.1% [-0.4%, +0.6%] 276/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 12th pct | 1th pct | 2th pct | 19th pct | 13th pct | 2th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +0.8% vs +2.1% | +4.2% vs +3.1% | +5.8% vs +4.3% | +7.5% vs +5.3% | +7.6% vs +5.5% | +13.1% vs +5.8% |

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| **Pooled shocks** mean | | | | -0.2% [-0.8%, +0.3%] 1/3>0 | -1.4% [-4.1%, +0.9%] 1/3>0 | -2.3% [-7.6%, +2.3%] 1/3>0 | -0.5% [-1.9%, +2.2%] 1/3>0 | -0.4% [-3.0%, +1.2%] 2/3>0 | +0.1% [-1.0%, +2.1%] 1/3>0 | -2.1% [-8.8%, +2.9%] 1/3>0 |
| 500 placebo onsets mean | | | | -0.0% [-0.1%, +0.0%] 242/500>0 | -0.0% [-0.2%, +0.1%] 264/500>0 | +0.0% [-0.2%, +0.2%] 253/500>0 | -0.0% [-0.3%, +0.3%] 249/500>0 | +0.1% [-0.3%, +0.4%] 252/500>0 | +0.1% [-0.3%, +0.5%] 251/500>0 | +0.2% [-0.2%, +0.7%] 244/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 6th pct | 4th pct | 39th pct | 42th pct | 49th pct | 23th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +2.5% vs +1.6% | +5.0% vs +2.3% | +2.3% vs +3.2% | +2.3% vs +3.9% | +1.8% vs +4.4% | +6.1% vs +5.3% |

Literal rule, ETF-first: spread, then second hop.

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| **Pooled shocks** mean | | | | -0.9% [-2.9%, +0.5%] 1/3>0 | -0.7% [-3.7%, +1.0%] 2/3>0 | -2.5% [-7.6%, +2.0%] 1/3>0 | -2.5% [-8.9%, +1.1%] 2/3>0 | -1.0% [-8.6%, +4.5%] 2/3>0 | +0.3% [-9.1%, +7.0%] 2/3>0 | -1.3% [-13.7%, +6.3%] 2/3>0 |
| 500 placebo onsets mean | | | | -0.1% [-0.1%, +0.0%] 257/500>0 | +0.1% [-0.1%, +0.2%] 271/500>0 | -0.0% [-0.3%, +0.2%] 244/500>0 | -0.0% [-0.4%, +0.3%] 243/500>0 | -0.2% [-0.6%, +0.2%] 265/500>0 | -0.2% [-0.7%, +0.2%] 271/500>0 | -0.1% [-0.5%, +0.4%] 278/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 24th pct | 6th pct | 14th pct | 38th pct | 55th pct | 32th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +2.7% vs +1.9% | +4.8% vs +2.7% | +5.6% vs +3.9% | +6.8% vs +4.8% | +8.4% vs +5.1% | +10.8% vs +5.5% |

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| **Pooled shocks** mean | | | | -0.0% [-0.5%, +0.5%] 1/3>0 | -0.8% [-4.8%, +3.6%] 1/3>0 | -1.2% [-7.7%, +5.6%] 1/3>0 | +0.5% [-2.2%, +5.3%] 1/3>0 | -0.5% [-2.7%, +0.8%] 2/3>0 | +1.8% [+1.2%, +2.5%] 3/3>0 | +0.1% [-2.3%, +4.4%] 1/3>0 |
| 500 placebo onsets mean | | | | -0.0% [-0.1%, +0.0%] 236/500>0 | -0.1% [-0.3%, +0.0%] 231/500>0 | -0.2% [-0.4%, +0.1%] 224/500>0 | -0.4% [-0.7%, -0.1%] 237/500>0 | -0.5% [-0.9%, -0.2%] 223/500>0 | -0.6% [-1.0%, -0.3%] 228/500>0 | -0.8% [-1.3%, -0.4%] 203/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 25th pct | 22th pct | 69th pct | 51th pct | 84th pct | 62th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +4.2% vs +1.8% | +6.6% vs +2.5% | +4.2% vs +3.4% | +1.9% vs +3.9% | +0.6% vs +4.2% | +3.8% vs +5.2% |

Literal rule, baskets only: spread, then second hop.

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| **Pooled shocks** mean | | | | -1.1% [-2.5%, +0.1%] 1/3>0 | -0.9% [-3.0%, +0.7%] 1/3>0 | -4.1% [-8.2%, +0.2%] 1/3>0 | -5.1% [-12.3%, -0.5%] 0/3>0 | -2.9% [-10.9%, +1.8%] 2/3>0 | -2.9% [-12.3%, +3.5%] 1/3>0 | -6.0% [-20.1%, +3.3%] 1/3>0 |
| 500 placebo onsets mean | | | | -0.1% [-0.2%, +0.0%] 252/500>0 | -0.0% [-0.2%, +0.2%] 269/500>0 | -0.1% [-0.4%, +0.1%] 244/500>0 | -0.2% [-0.6%, +0.2%] 251/500>0 | -0.6% [-1.0%, -0.1%] 255/500>0 | -0.7% [-1.2%, -0.2%] 246/500>0 | -0.7% [-1.2%, -0.1%] 260/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 23th pct | 3th pct | 5th pct | 21th pct | 23th pct | 8th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +1.9% vs +2.2% | +4.2% vs +3.2% | +6.4% vs +4.5% | +6.9% vs +5.5% | +8.3% vs +5.8% | +12.4% vs +6.1% |

| Episode | Onset | series n1/n2 | β1 / β2 | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| **Pooled shocks** mean | | | | -0.1% [-0.6%, +0.3%] 1/3>0 | -0.9% [-5.1%, +3.3%] 1/3>0 | -1.6% [-8.6%, +5.2%] 1/3>0 | +0.3% [-2.2%, +5.1%] 1/3>0 | -0.6% [-2.6%, +0.9%] 1/3>0 | +0.7% [-0.2%, +2.0%] 2/3>0 | -1.2% [-4.7%, +3.5%] 1/3>0 |
| 500 placebo onsets mean | | | | -0.1% [-0.1%, +0.0%] 235/500>0 | -0.1% [-0.3%, +0.0%] 240/500>0 | -0.1% [-0.3%, +0.1%] 233/500>0 | -0.3% [-0.6%, -0.0%] 236/500>0 | -0.4% [-0.7%, -0.1%] 227/500>0 | -0.5% [-0.8%, -0.1%] 223/500>0 | -0.6% [-1.0%, -0.1%] 201/500>0 |
| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | |  | 20th pct | 13th pct | 64th pct | 45th pct | 70th pct | 43th pct |
| Dispersion: SD across shock episodes vs SD across single placebo windows | | | |  | +4.2% vs +1.7% | +6.9% vs +2.4% | +4.1% vs +3.2% | +1.8% vs +3.7% | +1.2% vs +4.0% | +4.2% vs +5.0% |

Per-industry, literal rule, baskets only (adds rail, truck and chemicals; 324 is the refiner basket, not CRAK):

| Industry (hop) | d0 | 1w | 2w | 4w | 6w | 8w | 12w | placebo 12w |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 211 (first) | +3.3% 2/3 | +2.8% 2/3 | +6.4% 2/3 | +8.3% 2/3 | +0.3% 2/3 | +2.4% 2/3 | +4.4% 1/3 | -1.2% |
| 212 (second) | -0.4% 2/3 | +0.8% 1/3 | +0.2% 1/3 | +1.0% 1/3 | +1.6% 1/3 | -3.6% 1/3 | -5.0% 1/3 | +2.3% |
| 213 (first) | +2.3% 2/3 | -0.8% 1/3 | +3.0% 1/3 | +4.5% 2/3 | -0.3% 2/3 | +4.9% 2/3 | +4.4% 1/3 | -2.3% |
| 22 (first) | -0.0% 1/3 | +2.4% 2/3 | +4.5% 3/3 | +3.5% 3/3 | +5.2% 2/3 | +3.2% 1/3 | +3.5% 1/3 | -0.9% |
| 324 (first) | +1.3% 1/3 | +1.1% 2/3 | +11.6% 3/3 | +17.3% 3/3 | +14.2% 3/3 | +16.3% 3/3 | +20.8% 3/3 | +0.9% |
| 325 (second) | -1.5% 0/3 | -0.2% 1/3 | +0.7% 2/3 | +3.1% 2/3 | +0.5% 2/3 | +1.7% 2/3 | -0.7% 1/3 | -2.8% |
| 481 (first) | -2.0% 0/3 | -6.3% 0/3 | -9.0% 0/3 | -4.8% 0/3 | -3.6% 1/3 | -1.9% 2/3 | -3.8% 1/3 | -0.6% |
| 482 (second) | +0.0% 2/3 | -0.8% 1/3 | -0.3% 1/3 | -0.5% 1/3 | -1.7% 1/3 | +0.9% 2/3 | -1.1% 1/3 | -1.0% |
| 483 (first) | +1.1% 2/3 | -1.9% 1/3 | -1.3% 2/3 | +6.4% 3/3 | +1.2% 1/3 | +1.4% 2/3 | +4.5% 2/3 | +3.3% |
| 484 (second) | +0.4% 2/3 | -1.2% 1/3 | -3.7% 2/3 | -0.9% 1/3 | -5.0% 1/3 | -1.7% 2/3 | -2.3% 1/3 | -0.2% |
| 486 (first) | +1.1% 2/3 | +2.3% 2/3 | +2.9% 2/3 | +2.3% 2/3 | -1.0% 1/3 | -0.8% 1/3 | -0.2% 1/3 | +1.6% |
| 487OS (second) | +0.3% 2/3 | -2.6% 1/3 | -4.4% 1/3 | -3.6% 0/3 | -6.6% 1/3 | -3.6% 0/3 | -6.0% 1/3 | -2.6% |
| 532RL (second) | +0.5% 2/3 | -1.7% 0/3 | -1.8% 1/3 | +2.7% 2/3 | +7.4% 2/3 | +10.5% 3/3 | +8.0% 3/3 | +0.9% |

## 6. What the numbers say

1. **The second hop does not drift in a reliable direction after a supply shock.** Pooled over six episodes
   (1990-2026, French data, weighted rule) the hedged second-hop CAR is -0.1% at 1 week, +0.7% at 2, +0.6% at
   4, -0.5% at 6, -1.7% at 8 and -2.9% at 12 weeks; every bootstrap CI straddles zero; positive in 2 to 4 of 6
   episodes at every horizon; percentile of the placebo base rate 39th / 79th / 65th / 33rd / 13th / 7th. The
   12-week number is the only one near a tail and it is two episodes (1990: -12.8%, 2026: -11.2%), both of
   which coincided with a macro turn (recession onset; a hawkish hike into the shock) that a 71-industry link
   map cannot see. The literal rule gives the same picture (+1.3% / +1.5% at 2-4 weeks, 90th / 86th percentile,
   then fading to -1.7% at 12 weeks). The ETF-era cross-check (n = 3) is consistent: 2019 negative, 2022
   positive, 2026 negative; pooled -1.3% / -1.9% at 1-2 weeks ETF-first (10th / 7th percentile, on three
   episodes), -1.4% / -2.3% with stock baskets (6th / 4th), and back to the base rate by 4-8 weeks.

2. **Shock months are NOISIER, not bigger.** Across the six shocks the SD of the second-hop CAR is 3.5% at 1
   week and 4.6% at 2 weeks, against 1.5% and 2.2% across single placebo windows (roughly double), and 10.5%
   vs 5.5% at 12 weeks. The same holds on the ETF-era data (2.5-5.0% vs 1.6-2.4% at 1-2 weeks). A sign that
   flips by episode with twice the usual dispersion is what "the effect lives at the second hop" would look
   like if the DIRECTION of the second-hop repricing depends on which transmission channel dominates in that
   episode (aircraft lessors and coal rallied in some, brokers and building materials sold off in others).
   That is the judgment the candidate claims to supply, and it is exactly what a static map cannot test.

3. **The spread second-minus-first is negative at every horizon, and the reason is the FIRST hop.** Spread
   pooled: -0.8%, -0.6%, -1.4%, -1.5%, -2.7%, -4.1% (1-12 weeks), positive in only 1-3 of 6 episodes,
   5th-25th placebo percentile. The first hop (Oil + Trans + Util, equal-weighted) keeps drifting UP for 2-4
   weeks after onset: +1.3% / +1.9% at 2 / 4 weeks, 96th / 95th percentile of the placebo base rate, 4 of 6
   positive. The per-industry table shows where: Oil +4.0% / +4.6% at 2 / 4 weeks (5 of 6 positive at 1
   week), Utilities +2.3% / +2.1%, Coal +6.9% at 2 weeks (5 of 6). In the ETF era the refiner basket is the
   standout, +11.6% / +17.3% / +20.8% at 2 / 4 / 12 weeks, 3 of 3 (CRAK: +3.9% / +6.4% / +6.6%), and airlines
   the mirror image, -7.1% to -9.0% at 2 weeks, 0 of 3 positive. **So the first-order supply-shock
   repricing is not complete on the onset day at the industry level: it continues for two to four weeks.**
   That contradicts the dossier's Section 3.4 extrapolation from tariff-disclosure studies ("the market prices
   disclosed first-order exposure within two days") and is the more tradeable finding here. It is also a
   directional sector bet (long refiners / short airlines IS the sector), which the SHOCK-NATIVE rail (i)
   forbids as a net-directional expression and which B's event-fade and the regime router's `acute` cell
   already touch.

4. **The demand-shock controls behave differently, as they should:** the first hop falls (-4.2% / -7.0% at 1-2
   weeks pooled over 2008 and 2020) and the second hop falls with it over 4-12 weeks (-8.5% to -9.6%). A
   detector has to distinguish supply from demand shocks before onset; the rubric's qualifying-event
   definition already does that (oil up, not down).

5. **Per second-hop industry, nothing over six shocks is consistent enough to pre-register.** Coal is the
   only second-hop member positive in 5 of 6 at any horizon (2 weeks, +6.9%, vs +2.0% placebo at 12 weeks),
   and it is a substitute-fuel beneficiary, i.e. economically a first-order winner the SIC map files under
   mining. Mines, Fin and BldMt are negative on average at 8-12 weeks but in only 2-3 of 6 episodes. In the
   ETF era the rental-and-leasing basket (URI, CAR, AER, GATX, R, WSC) is +7.4% / +10.5% / +8.0% at 6 / 8 /
   12 weeks in 2-3 of 3: interesting, n = 3, and the lessors' gain is as much a first-order effect of
   grounded capacity on lease rates as a second hop.

## 7. Verdict

Second-hop hedged drift over 4 weeks is +0.6% (bootstrap 95% CI -2.2% to +3.2%) vs +0.1% in placebo windows,
positive in 4 of 6 episodes; over 12 weeks it is -2.9% (CI -10.1% to +4.6%) vs +0.5% in placebos, positive in
2 of 6. No horizon from 1 to 12 weeks shows a second-hop drift distinguishable from the base rate, while the
dispersion of second-hop outcomes in shock months is about twice the placebo dispersion (3.5% vs 1.5% at 1
week, 10.5% vs 5.5% at 12 weeks). The spread second-hop minus first-hop is negative at every horizon (-0.6%
at 2 weeks to -4.1% at 12, 5th-25th placebo percentile) because the FIRST hop keeps repricing for 2-4 weeks
after onset (+1.9% hedged at 4 weeks, 95th percentile; refiners +17% and airlines -9% on 2016-2026 ETF data,
3 of 3). Caveats that bound every sentence above: n = 6 (3 in the ETF era), industry-level portfolios with a
coarse SIC map for the long history and a survivorship-selected 2026 basket for the short one, Yahoo
unavailable so no dividend-adjusted long ETF series, and a link map that treats the refinery-to-converter
chain as first-order. For SL1 the implication is: the data support "shock months make second-hop outcomes
noisier, with episode-specific direction" (the hypothesis the candidate's judgment step would have to exploit,
unmeasurable here) and do NOT support a mechanical second-hop drift to lean on; the measurable, repeatable
drift is first-order and multi-week, which Rev 50's rails already route elsewhere.
