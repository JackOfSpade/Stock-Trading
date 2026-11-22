2026-W47

# W3 — Open-Position Deep-Dive (Strategies A, B, C, E)

**Run:** Sunday 2026-11-22. **Evidence window:** 2026-11-15 09:14 UTC (W3's own last `completed` row) to 2026-11-22 ~10:30 UTC. `state.routine_catchup_window` gives `window_days = 6.99` and `never_completed` FALSE. That is a normal cadence, so this file has no catch-up section and no `CATCHUP` token.

**NO `WEEKLY-THESIS-ACTION` FLAG.**
- No in-scope position has a cumulative completion or invalidation finding that D1's daily mechanics missed. So W3 raises no `immediate_action_flagged` alert.
- Three positions carry a **further-research** recommendation: ANDE, RVMD and NRIX.
- Eleven are **hold**.

**Marker.** `2026-W47` is the ISO week of the run date. Sunday 11-22 is day 7 of the week Mon 11-16 to Sun 11-22. W2 stamped `2026-W47` earlier today.

**Scope is derived, not assumed.**
- In `strategy/roster.yaml`, A, B, C and E are `review_cadence: reactive`. D is `long_horizon` and belongs to M3.
- `state.strategy_roster`, read this run: A–E are `ADOPTED` and `is_active`; F, G, H and I are `REJECTED`. There is no SHADOW, PROBE or graduate row.
- The in-scope set is therefore **A, B, C and E**, unchanged.

---

## HEADLINE: the in-scope book is no longer empty, and it was bought into a correction

1. **B opened 14 positions at the 11-16 open.** This ends 13 consecutive weekly cycles with an empty in-scope book.
   - D2's 11-15 drain of the overflow queue produced 14 GO theses.
   - D2a reconciled 26 fills on 11-16 (`6bee7b8f`), at $3,844.53 total cost including commissions of $4.99.
   - Every tranche has a convergence target and a 2027-01-15 time exit, and none has a stop.
2. **The market fell hard from the entry day on.** By the IBKR regular-session bars:
   - SPY went from 754.37 on 11-13 to **689.81** on 11-20, down 8.6%.
   - ^VIX went from 19.30 to **35.89**.
   - 11-20 was the capitulation session: S&P −3.7% and Nasdaq −5.3%. The Nasdaq had its worst week since 2020, and the S&P and the Dow closed in correction (§4).
   - At the 11-20 closes the B book is worth **$3,545.41, which is −$299.11 or −7.8% against cost**, roughly in line with SPY.
   - Only IRTC (+3.6%) and SYY (−0.1%) are not under water.
3. **The router de-risked B two sessions after entry.**
   - D2 11-17 measured the trigger `vix_regime_high` (VIX 25.46) and set B = DO-NOT-ACTIVATE (`e5782937` / `76858106`). New entries are halted, and existing tranches run to their normal exits.
   - D2 11-18 measured the re-risking trigger `vix_regime_exit_high` (VIX 24.56). The technical plane flipped back to ACTIVATE against the standing fundamental DO-NOT-ACTIVATE, so B is now **DO-NOT-ACTIVATE — PENDING `div-B-202611-3`** (`f411301f`).
   - The attacker finished on 11-19 with verdict PARTIAL (`50940d58`). The judge (AR_orc) has not yet ruled on it; it was due 11-20.
   - VIX then closed HIGH again on both 11-19 (28.44) and 11-20 (35.89).
4. **D1's daily sweep covered each tranche every session from 11-16 to 11-19, and found no breach.** Its add-candidate reviews are `4370d8af`, `21fba791`, `0b121f3e` and `e80382c3`.
   - **One reading is wrong:** ANDE's criterion 5 price-level review trigger *has* been met since 11-18. See the ANDE section and the alert filed.
   - **Friday 11-20 and the weekend have no D1 coverage yet**, because D1 runs on a `daily_sun_thu` cadence. D1 picks the 11-20 session up tonight. This file treats the 11-20 items below as evidence handed forward, not as decisions.

---

## THE BOOK, RE-ESTABLISHED INDEPENDENTLY

`state.current_positions`, measured this run, holds 26 OPEN rows:
- **14 are Strategy B:** ANDE, ARQT, DDOG, ECG, EXPE, IRTC, MCY, MTRN, NRIX, RELY, ROK, RVMD, SM and SYY. All are keyed `B:<T>:2026-11-15` and filled 11-16.
- **12 are Strategy D:** M3's scope, not assessed here.

A, C and E hold nothing. Supporting reads:
- `state.open_orders`: 0.
- `events.position_events` for non-D strategies since 11-17: none. So there have been no exits or adds.

Prices and P&L: closes are IBKR regular-session daily bars read by the sub-agents. The 11-16 to 11-19 closes match D1's recorded marks. Cost/sh is `cost_basis / shares` from `state.current_positions`, commissions included.

| Ticker | Event (date, move) | Cluster | Cost/sh | 11-19 | **11-20** | vs cost | To target | Conviction |
|---|---|---|---|---|---|---|---|---|
| ANDE | 11-03, −11.7% | idiosyncratic M&A financing | 55.42 | 47.46 | **44.97** | **−18.9%** | 61.50 | LOW |
| ARQT | 11-04, −20.7% | growth de-rate | 28.20 | 27.17 | 26.36 | −6.5% | 32.00 | MEDIUM |
| DDOG | 11-04, −14.4% | AI software | 182.64 | 166.46 | 157.37 | −13.8% | 202.00 | LOW |
| ECG | 11-03, −29.3% | AI infra / data centres | 82.75 | 83.85 | 76.59 | −7.4% | 103.00 | MEDIUM |
| EXPE | 11-04, −13.7% | travel / geopolitics | 256.97 | 239.19 | 234.96 | −8.6% | 290.00 | MEDIUM |
| IRTC | 11-05, −30.7% | medtech | 91.40 | 94.24 | 94.72 | +3.6% | 111.00 | LOW |
| MCY | 11-03, −13.4% | rates / duration | 87.58 | 82.59 | 81.43 | −7.0% | 96.00 | LOW |
| MTRN | 11-04, −17.7% | AI capex / semis materials | 194.81 | 202.80 | 182.47 | −6.3% | 225.00 | MEDIUM |
| NRIX | 11-03, −38.2% | biotech partner exit | 15.37 | 13.60 | **12.85** | **−16.4%** | 19.50 | MEDIUM |
| RELY | 11-04, −20.4% | fintech growth de-rate | 22.38 | 20.06 | 19.83 | −11.4% | 24.50 | LOW |
| ROK | 11-05, −14.2% | industrial / AI infra | 394.18 | 383.10 | 361.93 | −8.2% | 430.00 | MEDIUM |
| RVMD | 11-04, −11.0% | biotech launch | 172.27 | 159.43 | 161.20 | −6.4% | 188.00 | LOW |
| SM | 11-03, −15.3% | oil beta | 32.41 | 29.34 | 28.57 | −11.9% | 35.50 | LOW |
| SYY | 11-03, −9.3% | food distribution | 78.22 | 77.15 | 78.17 | −0.1% | 81.00 | MEDIUM |

**Correlation, measured in the tape.** On 11-20 the four AI-cluster names fell together, all on no company news found: DDOG −5.5%, ECG −8.7%, MTRN −10.0% and ROK −5.5%. The theses tagged them as one correlated bet at construction. This week confirmed it.

**Binding states.** Read from `state.current_regime` this run.

| Strategy | Operative value | Since | Basis |
|---|---|---|---|
| A | DO-NOT-ACTIVATE (`div-A-202611-1`) | 11-04 | Unchanged |
| B | **DO-NOT-ACTIVATE — PENDING `div-B-202611-3`** | 11-18 | Held state: technical ACTIVATE on 11-18 vs fundamental DNA (rail 3r). The attacker's verdict is PARTIAL; AR_orc has not ruled |
| C | HYBRID ACTIVATE (FOMC-only) (`div-C-202611-1`) | 11-04 | D2 11-19 NO-CHANGE (`1758f3e7`) |
| E | DO-NOT-ACTIVATE — PENDING `div-E-202611-3` | 11-18 | Attacker verdict: SURVIVES narrowly. `div-E-202611-2` resolved ACTIVATE on 11-16 (`cbd791c4`), then 11-17 de-risked again |

- **Integrative regime** (M1R, 11-18): `stable growth + reaccelerating inflation + hawkish policy + stressed risk + latent shock`.
- **Technical signals** (11-19): `VIX_REGIME` HIGH (28.44), `SPY_TREND` NEUTRAL (715.87 vs SMA50 761.67 / SMA200 732.69), `EQUITY_BREADTH` WEAK (49.10).
- **11-20 provisional read:** SPY 689.81 is below both moving averages, and SMA50 > SMA200. The condition for DOWN is close < SMA50 < SMA200, so this still reads NEUTRAL, not DOWN.
- Scoring belongs to D2a and M1R. W3 scores nothing.

---

## PER-POSITION REVIEW — Strategy B (14)

**Method.**
- **D1 coverage:** D1's records since W3's last completion are taken as evidence already detected. They are the 11-16 to 11-19 add-candidate rows, the screen hits for IRTC/SM on 11-18 and RELY on 11-17, and the ROK Investor Day reading on 11-18.
- **New work this run:** Friday 11-20, the weekend, and slow-burn peer, analyst and filing evidence. Research was done by four Sonnet sub-agents with disjoint ticker sets.
- **Source grades:** CONFIRMED means an issuer, SEC or regulator page. SECONDARY means a wire or aggregator. UNCONFIRMED means a claim by an interested party.
- **Out of scope:** per step 6, no convergence target, time exit or other mechanical trigger is checked here.

**Evidence span for every position:** 2026-11-16 (entry) to 2026-11-22. This is the first W3 cycle for all 14 tranches.

### ANDE — **FURTHER RESEARCH** (largest loss; review trigger already met)

- **Original thesis:** an acquirer M&A financing overhang. Andersons bought the Harvestone ethanol plants for about $915M, debt-funded, with no share issuance, and was sold 11.7% on 11-03.
- **Thesis status (slow-burn):**
  - The stock has fallen on five of five sessions since entry: 54.68 / 52.02 / **47.51** / 47.46 / **44.97**.
  - The 11-20 close is a new 52-week low and −18.9% against cost.
  - No company-specific negative disclosure was found.
- **11-18, the −8.7% day:** ANDE presented at the Stephens conference that day (transcript, SECONDARY). The talk restated several facts:
  - About half of Harvestone's $225–250M EBITDA comes from 45Z/45Q credits.
  - EBITDA starts "at the lower end in year 1–2".
  - Carbon sequestration at the Indiana site comes only around 2028–29.
  - 45Z sunsets at the end of 2029.
  - Leverage is about 2x at closing.
- **The ethanol peer fell the same day.** Green Plains also presented at Stephens and fell 7.48% on 11-18 (Investing.com, SECONDARY).
  - GPRE's own Q3 showed crush margin improving and a 2027 EBITDA guide of at least $250M (issuer, CONFIRMED). So the evidence points to an ethanol and 45Z-sentiment de-rating across the group, not an ANDE-specific event.
- **11-20 (−5.25%):** grain traders lagged in a staples rally. Reuters reported that Asian farm-purchase deals were "largely falling short" (via aggregator, SECONDARY).
- **Analysts:** a Seeking Alpha contributor note upgraded the stock to Hold with a $63 target on 11-17. StoneX's Buy at $100 stands, and consensus is about $95. No broker cuts were found.
- **Criteria:**

  | # | Status |
  |---|---|
  | (1) Deal or financing | Not met. The 11-06 8-K shows committed financing from U.S. Bank and Farm Credit Mid-America. No termination, price change or second request found |
  | (2) Guide, covenant or equity | Not met |
  | (3) 45Z/45Q or RFS policy | Not met. No Treasury or EPA action; the RFS 2026/27 rule dates from 2026-03-27 |
  | (4) Crush margin or grain volume | Not met on the evidence (GPRE crush improving). No board-crush quote was retrieved, so this is unverified |
  | (5) Close below $52 on volume (new post-event low) = review trigger | **MET since 11-18**, a 47.51 close on elevated volume, and deepening through 44.97 on 11-20 |

- **Recommendation: further research.** The trigger asks for a reassessment. This review finds nothing in criteria 1–4 broken. The remaining open question is whether the market is re-pricing the 45Z-dependence of the deal economics, which is not a listed invalidation. Specific gaps:
  1. The ethanol board crush for 11-16 to 11-20.
  2. A primary EDGAR sweep for ANDE 8-K and Form 4 filings since 11-16.
  3. Whether any 11-18 sell-side note reacted to the Stephens disclosures.

  D1 and D2 own the daily review-trigger handling.
- **Observed defect, filed:** D1's 11-18 and 11-19 rows recorded ANDE's criteria as "unbreached" at closes of 47.51 and 47.46. The populated criterion 5 is price-level and was crossed. This is filed as an `ops.alerts` info row naming D1 (see FILED). It is not a weekly-thesis-action: criterion 5 is a review trigger that D1's sweep owns, not a slow-burn completion.

### NRIX — **FURTHER RESEARCH**

- **Thesis:** Sanofi's 11-03 termination of SAR448272 (a STAT6 degrader) on a nonclinical finding was over-punished at −38%. Nurix's cash runway extends into 2H 2029.
- **Slow-burn:** the stock fell on five of five sessions: 14.73 / 14.24 / 14.10 / 13.60 / **12.85**. That is −16.4% against cost and a 52-week low.
- **Conference remarks.** CEO remarks at the 11-17 UBS and 11-18 Jefferies conferences (transcripts, SECONDARY):
  - Nurix has **not yet received Sanofi's tox report or data** and has requested them.
  - The Sanofi alliance continues, with STAT6 backups and a second target.
  - The ASH preview is consistent with the 11-05 abstract: about 85% ORR and 22.1-month PFS in R/R CLL.
  - Progressor sequencing shows no degrader-class resistance mechanism.
  - The Roche bexobrutideg collaboration is intact.
- **Holders:** five Schedule 13G/A amendments are dated 11-16. Perceptive's stake is now 4.9%, below 5%. The direction of the others is UNCONFIRMED.
- **Analysts:** no analyst action in the window. The last was Wells Fargo cutting its target from $25 to $20 on 11-04.
- **Valuation:** the stock trades near its $1.1B cash.
- **Criteria:**
  1. Class or pathway finding, or more terminations: **not met, unresolved.** This is the main risk, and Nurix itself does not have the data.
  2. Safety, hold or Roche change: not met.
  3. ASH worse than abstract: not met, untested until 12-12 to 12-15.
  4. Dilution or runway: not met.
- **Recommendation: further research.** Gaps:
  1. The content of Sanofi's tox report once Nurix discloses it. It decides criterion 1.
  2. Whether the 13G/A filers are exiting.

  ASH on 12-12 to 12-15 is the next dated test, and D1 owns it on the day.

### RVMD — **FURTHER RESEARCH**

- **Thesis:** a launch-trajectory scare after the 11-04 Q3 print. Q3 sales were $198M in about 5 weeks. The position is long for normalisation.
- **New 11-20, not yet covered by D1: Erasca reported Phase 1 data for ERAS-0015**, a pan-RAS molecular glue, in an 8-K, CONFIRMED.
  - 2L+ KRAS G12X pancreatic cancer at 32 mg: **44% confirmed ORR (n=25)**, with 84% of patients in 3L+.
  - G12D/V subset: **69% confirmed ORR (n=13)**.
  - Erasca is accelerating a 1L pancreatic Phase 3 into 1H 2027.
  - For comparison, Rasonque monotherapy showed 24% ORR in G12D pancreatic cancer in RASolute 302 (SECONDARY). Cross-trial comparison is unreliable here: Phase 1, n=13, about 4 months of follow-up, and no PFS or OS.
  - **RVMD rose 1.1% that day** (and +2.3% after hours) on twice normal volume, in a −3.7% tape. Truist was quoted calling RVMD's moat "competitive" (SECONDARY).
- **Supportive, cumulative:**
  - EC approval on 11-16 (issuer, CONFIRMED). That closes half of criterion 5.
  - 1L Rasonque + GnP data at ENA on 11-19/20 (issuer, CONFIRMED): ORR 60.7%, mPFS 12.8 months, 12-month OS 76.6%, plus FDA Breakthrough designation.
  - RVMD has filed a patent suit against Erasca.
  - HC Wainwright reiterated its $350 target on 11-17.
- **Caution, cumulative:** at Jefferies on 11-16 (SECONDARY), management:
  - called the Q3 Expanded Access Program and backlog cohorts "largely one-time";
  - said the timing of any Q4 sales disclosure "remained undecided".

  So criterion 1 (Q4 tracking well below about $300M) **may not be measurable before the 2027-01-15 time exit.**
- **Criteria:**

  | # | Status |
  |---|---|
  | (1) Q4 sales | Not met. Possibly unobservable in-window |
  | (2) Competitor pancreatic RAS data | **Moved closer.** On a literal reading, "compelling competitor pancreatic RAS data (G12D/pan-RAS) in 2L PDAC" is arguably engaged by ERAS-0015. On substance it is early-phase, and the tape and sell-side did not treat it as thesis-breaking |
  | (3) Payer / gross-to-net | Not met |
  | (4) Price-target cuts or downgrade | Not met |
  | (5) Equity raise or EC non-approval | Not met (EC approved) |

- **Recommendation: further research.** This is a judgement call, and it is not a weekly-thesis-action:
  - The Erasca readout is a **single-day development on 11-20**, which D1's sweep evaluates tonight.
  - Repeating that evaluation here is outside W3's remit.

  Gaps:
  1. Sell-side readthrough notes on ERAS-0015 versus Rasonque, especially in G12D.
  2. Whether any Q4 consensus revenue figure has moved.
  3. Whether RVMD will disclose Q4 sales before 2027-01-15.

### DDOG — HOLD

- **Thesis:** the overhang from the largest AI customer's usage cut was over-discounted.
- **RBC conference, 11-18** (CFO, transcript, SECONDARY):
  - The largest customer is at its contractual minimum and has "tried to insource". This is **the same disclosure as the Q3 print**, not new.
  - Growth excluding that customer accelerated from 36% in Q2.
  - Large-customer gross retention is in the upper 90s.
  - AI-native customers are "increasingly choosing to outsource" with longer commitments.
- **11-20:** −5.5%, with no company news found. The cause was the AI and software rout: Nasdaq −5.3% and Anthropic down 8–9% on its second trading day.
- **Peer:** PANW raised its forecast.
- **Criteria:**
  1. Largest customer: not met (status quo).
  2. Other AI natives cutting, or AI-lab financing stress: **moved closer.** OpenAI cut its funding target by about $10B (SECONDARY), and AI-financing stress is the market theme. No named customer cut was found.
  3. Guide, departure or peer slowdown: not met. No Snowflake, Dynatrace or Cloudflare print was found in the window.
- **Hold.** At −13.8% this is the AI-cluster name with the deepest loss. The loss is beta and theme, not a thesis break.

### ECG — HOLD

- **Thesis:** Everus was de-rated on AI-infrastructure contagion plus the post-election data-centre-policy shock. Fundamentals are intact: Q3 backlog was $5.48B (+86%) and FY26 guidance was raised (issuer, CONFIRMED).
- **11-20:** −8.7% on about 1.4x the 11-19 volume, with no company news found.
- **Policy, mixed:**
  - Texas's environmental regulator (TCEQ) resumed data-centre permits on 11-18 (SECONDARY). That works against criterion 2.
  - The Texas governor-elect's pledged moratorium covers new approvals and takes effect from January.
  - Federal moratorium bill S.4214 has had no action (SECONDARY).
- **Financing:** NVIDIA's Q3 FY27 beat came with a "disciplined" financing-guarantee stance. Its CEO resigned on 11-12. On 11-20 there were reports of an SEC accounting examination (SECONDARY, unverified).
- **Criteria:**
  1. Guide or backlog: not met.
  2. Statewide freeze reaching permitted projects: not met.
  3. Hyperscaler or NVIDIA pullback: moved closer on narrative. No announced pullback.
  4. Close below $70.44 on volume: 76.59, 8.7% above the line.
  5. Executive or accounting event: not met.
- **Hold.** Note for later cycles: the 2027 Texas moratorium is the slow-burn risk to watch.

### MTRN — HOLD

- **Thesis:** a beat-and-raise that was sold off as a momentum unwind. The FY26 adjusted EPS guide of $7.10–7.40 was raised on 11-04 (issuer, CONFIRMED).
- **11-20:** −10.0% with chip equipment. Lam Research, Applied Materials and KLA each fell about 10%, and the new US AI-chip export controls dated 11-19 are reportedly hitting the supply chain more broadly than expected (Nikkei Asia, SECONDARY). Scope against MTRN's products is unverified.
- **Analysts and filings:** no downgrade since 11-05. Consensus median target is about $256. No equity issue or acquisition.
- **Criteria:**
  1. Q4 or guide: not met.
  2. Semiconductor capex or export rules: **moved closer**, unverified.
  3. Customer, outage or issuance: not met.
  4. Downgrade on orders: not met.
- **Hold.** Gap: the scope of the 11-19 export-control rule and whether it touches Materion's electronic materials.

### ROK — HOLD

- **Thesis:** an industrial de-rated on the 11-05 rout day.
- **Investor Day, 11-18:** criterion 1 was not met and the thesis was reinforced. Management reaffirmed FY27 guidance of $14.50–15.50 and set a ~25% enterprise-margin midpoint, up from 22%.
- **Slow-burn evidence:**
  - Post-Investor-Day targets were mixed (SECONDARY):
    - Cuts: JPMorgan $426 → $400 and TD Cowen $400 (Hold).
    - Raise: Mizuho $375 → $415.
    - Reiterations: KeyBanc $510, BofA $500 and Morgan Stanley $435.
  - No downgrade. FY27 consensus is about $15.05 (Wells Fargo), against the ~$14.55 line.
  - The 11-18 S-3ASR covers **debt securities only** (SEC, CONFIRMED), so it carries no dilution.
  - Rockwell signed to buy AGILOX, a mobile-robot maker, on 11-18 (issuer, CONFIRMED). The price is undisclosed and the deal is outside guidance.
  - The CEO bought about $1.5M of stock on 11-09. The only selling is a 10b5-1 sale by the Treasurer.
- **11-20:** −5.5% to **361.93**, with no company news.
- **Criteria:**
  - (1), (2), (3), (4) and (5) not met.
  - (6) close below $360 *on news*: 361.93 is 0.5% above the line. The 11-20 move had no ROK news, so a sub-$360 print without news would not meet the "on news" condition. That is D1's call on the day.
- **Hold.**

### EXPE — HOLD

- **Thesis:** a soft Q4 guide (bookings growth of 3.3–5.2%) inside a raised full year, with a geopolitical overhang.
- **New 11-20:** Bernstein cut its target from $310 to $261 and kept Market Perform (SECONDARY, several aggregators). EXPE fell only 1.8% against SPY's −3.6%.
- **Slow-burn evidence:**
  - Booking's Vayo AI agent books whole trips **on Expedia's own site**. That is OTA-channel AI, not the supply-bypassing launch criterion 3 describes.
  - No peer guidance cut. Airbnb was upbeat on 11-06 (Reuters, CONFIRMED).
  - No downgrade wave; Bernstein's is one target cut.
- **Gulf escalation, 11-21 (Euronews/Al Jazeera, Bahrain-confirmed):** Iranian strikes on US bases in Bahrain, and tankers attacked near Hormuz (via UKMTO, SECONDARY).
  - No airspace closure or new travel advisory was found.
  - Brent settled about $92.5 on 11-20, which does not meet the "spike materially above" test.
- **Criteria:**
  1. Guide or peer cut: not met.
  2. Gulf escalation, fuel spike or advisories: **moved closer** on the 11-21 weekend escalation. D1 owns the Monday reading.
  3. AI bypass: not met.
  4. FY27 EBITDA cut over 5% or a downgrade wave: not met. The FY27 EBITDA consensus was not checked (gap).
- **Hold.**

### RELY — HOLD

- **Thesis:** a de-rating on decelerating guidance.
- **Q4 guide:** revenue growth of +20–21%. The CFO said FY27 revenue growth is in the "high teens". That implies about $2.35B, above the ~$2.28B line; this is W3's inference, not consensus.
- **Analysts:** no target cut or downgrade. KeyBanc reiterated $32 on 11-17 and BofA has $29 (11-16). FY27 EPS consensus is about $1.65, against the ~$1.50 line (SECONDARY).
- **Insiders:** a director's 10b5-1 sale of 5,000 shares at about $23.75 (Form 144, SECONDARY).
- **Peers:** Western Union hit lows after it terminated the Intermex deal. That is a deal story, not a guidance cut, so criterion 5 is not met.
- **Price:** 11-20 close 19.83, −11.4%. The tape is fintech beta.
- **Criteria:** all five not met. Criterion 3 (remittance tax and immigration enforcement) stays a watch item.
- **Hold.** Gaps:
  1. The FY27 revenue consensus figure.
  2. A buyback-status check, which was searched only partially.

### IRTC — HOLD

- **Thesis:** the slip of the Zio MCT filing to 2027 was over-punished at −30.7%.
- **The week supports the thesis:**
  - The $100M accelerated buyback (8-K, CONFIRMED) was already seen by D1.
  - A director bought about $764K near $96.67 (SECONDARY).
  - CFO at Jefferies on 11-19: Zio Monitor growth is "durable", VitalConnect launches in Q1 2027, and the MCT filing is still "2027".
  - The legacy securities class action reached final judgement at $45M on 11-20. That is the old 2022–24 case, already accrued; **it is not a new filed complaint.**
- **Criteria:** all seven not met.
  - **Criterion 5 is unverified.** The CY2027 Physician Fee Schedule final rule (CMS-1848-F, out on 11-04 and published 11-09) cuts the conversion factor by 2.3%. The proposed rule had raised ambulatory ECG rates by about 3%. The final rates for CPT 93243, 93247 and 93229 were **not retrieved**, so this stays open. Gap: the CMS Addendum B RVU file.
- **Hold.** It is the one tranche above cost and outperformed the tape.

### ARQT — HOLD

- **Thesis:** a growth de-rating of a company whose guidance was intact. FY26 revenue guidance of $535–545M was raised on 11-04 (issuer, CONFIRMED).
- **Vitiligo Phase 2 has not read out.** It is due in Q4 2026 and is the main binary event inside the hold window.
- **Moved slightly closer on criterion 4 (dilution):** the 11-04 10-Q discloses that the ATM program was **upsized to $200M** in November (CONFIRMED). No usage has been disclosed.
- **Analysts and IQVIA data:** no downgrades; TD Cowen raised its target to $40 on 11-05. No IQVIA weekly TRx data after the Q3 deck was found (gap).
- **Price:** 11-20 close 26.36, −6.5%, with no company news.
- **Hold.** Gaps:
  1. Weekly ZORYVE TRx data.
  2. ATM draw-down, visible in the 10-K.

### MCY — HOLD

- **Thesis:** an over-reaction to a non-operating, rate-driven mark on the investment book.
- **11-20 price:** 81.43 (−1.4%) on the week's highest volume. The day's low was the close.
- **Slow-burn:**
  - California's Insurance Commissioner-elect plans to review the outgoing commissioner's Sustainable Insurance Strategy, which enabled recent rate increases (SECONDARY). That is a forward risk to criterion 2, and no filing decision has been made.
  - The 10-year Treasury yield actually *fell* to 4.92% on 11-20, down from 5.12% on 11-16 (Treasury par, CONFIRMED).
  - AM Best kept the US personal-lines outlook stable on 11-18. That is segment-level.
  - A director bought 750 shares around 11-06 to 11-09.
- **Criteria:**
  - (2) moved closer as a forward risk.
  - (3) moved further away this week.
  - (5), close below $79: 81.43 is 3.1% above the line.
  - All others not met.
- **Hold.**

### SM — HOLD

- **Thesis:** a minor guide trim punished as oil beta.
- **The week:**
  - Brent fell 3.5% and WTI 5.6% on the week, their third straight weekly decline, on an IEA surplus and Hormuz flows recovering (SECONDARY).
  - 11-20: SM −2.6% with its exploration-and-production peers.
- **Analysts:** KeyBanc reiterated Overweight at $46 on 11-20, citing debt reduction. Seaport upgraded Sell to Neutral on 11-16. Wall Street Zen's quant rating went to Hold on 11-21.
- **Uinta:** analysts flag that Uinta takeaway constraints "may persist into 2027" (Seeking Alpha, SECONDARY). Nothing has come from the company, and February's 2027 guidance is the test for criteria 1 and 2.
- **Criteria:** all four not met.
- **Hold.**

### SYY — HOLD

- **Thesis:** a sales-only guide trim with profit guidance intact.
- **Guidance and deal:**
  - FY27 adjusted EPS and local case-volume guidance were reiterated on 11-03.
  - The Restaurant Depot acquisition is "under federal review", with political pushback (SECONDARY). No FTC suit or second request was found, and closing is targeted for fiscal Q3.
- **Management:** the 11-17 8-K covers the Chief HR Officer moving to an adviser role. That is not a CEO or CFO change.
- **Analysts:** Guggenheim reiterated Buy at $90 on 11-17; Citi trimmed to $84.
- **Peers:** PFGC reiterated its FY27 guidance on 11-19; no peer guidance cut.
- **Price:** 11-20 +1.3%, an up day for a defensive name in a −3.7% tape.
- **Criteria:** all four not met.
- **Hold.** Gap: a primary-source check of the FTC status.

---

## STEP 4 — SECTOR AND MACRO CONTEXT

### 4a. The tape: from VIX NORMAL to a correction in five sessions

IBKR regular-session daily bars. The 11-16 to 11-19 bars match `state.signal_marks_curated` to the cent. The 11-20 bar is **provisional**: D2a has not ingested it, so per the warehouse-first clause it is sourced externally.

| Session | SPY | ^VIX | VIX band | Driver (graded) |
|---|---|---|---|---|
| 11-13 | 754.37 | 19.30 | NORMAL | — |
| 11-16 | 739.95 | 22.91 | NORMAL | Entry day. Risk-off. Outages story (SECONDARY) |
| 11-17 | 732.44 | 25.46 | **HIGH** | NVIDIA Q3 FY27: revenue $115.8B (+103%), Q4 guide ~$130B. Shares fell on the governance crisis (SECONDARY) |
| 11-18 | 730.20 | 24.56 | NORMAL | FOMC minutes: nearly all members see a December 25 bp hike, two floated 50 bp (AP, CONFIRMED) |
| 11-19 | 715.87 | 28.44 | HIGH | Anthropic IPO priced at $83, closed +17% then faded. S&P −2.0% (Reuters, CONFIRMED). New US AI-chip export controls (SECONDARY) |
| 11-20 | **689.81** | **35.89** | HIGH (prov.) | S&P −3.7% to 6,910 (seventh straight loss), Nasdaq −5.3%. NVIDIA −14%, AMD −13%. Reports the SEC is examining NVIDIA's accounting (SECONDARY). Both S&P and Dow in correction (Yahoo Finance, CONFIRMED prices) |

- The VIX intraday high on 11-20 was 40.03.
- One outlet's 37.43 VIX close disagrees with IBKR and Yahoo (35.89). W3 uses IBKR.

### 4b. Rates and the Fed — hawkish talk, falling yields

- **Treasury par, 11-20 (CONFIRMED):** 2Y **4.63%**, 10Y **4.92%**, 30Y 5.31%.
  - On the week, the 10Y fell 5.12 → 4.92 and the 2Y fell 4.83 → 4.63.
  - The flight to quality outweighed the hawkish minutes.
  - The warehouse's own read on 11-19 was 10Y 5.04 / 2Y 4.76 (`SUSTAINED_INVERSION` NOT-SUSTAINED).
- **December 8–9 FOMC:** roughly 95% hike odds (CME FedWatch via a secondary source). One source also prices a January hike.
- **Fed speakers:** Waller (50 bp possible), Daly, Paulson, and Cook on 11-20 ("too accommodative"), all SECONDARY.
- **For Strategy C:** the `thesis-FOMC-C-20261130` item, due 11-30, now faces a fully priced 25 bp hike. Its criterion-2 divergence would have to be about size (25 vs 50 bp) or the path afterwards. W3 does not construct it.

### 4c. The shock price leg — still `latent` and retraced

From `state.shock_price_leg_status` (`bigquery/263`), read this run:
- Constants: anchor 2026-08-01, baseline 84.73 (N = 43), peak 116.72, midpoint **100.725**.
- Through 11-19 the leg is `price_leg_elevated` FALSE with basis `retraced`, and `plateau_band_holds` is FALSE every day.

| mark_date | `brent_close` | plateau median | Source |
|---|---|---|---|
| 11-13 | 95.84 | 95.83 | warehouse |
| 11-16 | 91.76 | 95.21 | warehouse |
| 11-17 | 93.46 | 94.03 | warehouse |
| 11-18 | 91.44 | 93.11 | warehouse |
| 11-19 | 92.70 | 92.73 | warehouse (FMP, ingested 11-19 22:43Z — provisional same-evening) |
| 11-20 | ~92.49 (Jan contract settle) | — | EXTERNAL, secondary (Investing.com). WTI 82.40 |

- **Week:** Brent −3.5% and WTI −5.6%, the third weekly decline. Closest approach to the midpoint was about 4.9 (on 11-13). Every session since entry has been ≥ 7.3 below it.
- **Vendor-revision note, not a defect:** Reuters gives the 11-19 Brent settle as 91.98, against the warehouse's FMP same-evening 92.70.
  - `events.signal_marks` shows a single ingest at 22:43Z on 11-19 with no restatement yet.
  - Under D2a's VENDOR REVISES THIS SERIES rule the same-evening figure is provisional, and a later restatement is expected and is not a defect.
  - The 0.72 gap does not move `brent_peak` or the midpoint.
- **Shock channel 11-18 → 11-22.** Evidence for the scorer; W3 does not adjudicate it.
  - **CONFIRMED:**
    - UKMTO: a tanker was hit in the engine room near Khasab on 11-18/19.
    - JMIC: four attacks in 96 hours.
    - SPA / Saudi civil defence: a Houthi strike on the Public Investment Fund office in Riyadh, 11-19.
    - Bahrain confirmed attacks on 11-21.
    - CENTCOM denied an F-16 damage claim.
  - **SECONDARY:**
    - Two to three tankers struck exiting the Gulf on 11-21 (UKMTO via Al Jazeera and Euronews).
    - Witkoff and Kushner met Qatari officials in Berlin on 11-19 (Axios).
  - **UNCONFIRMED:**
    - The Iranian navy says tankers hit mines (11-19, 11-21).
    - The IRGC claims hits on four US bases in Bahrain and on Patriot batteries (11-21).
    - Iran says reopening Hormuz would be "not difficult" on its terms, after a Qatari visit to Tehran on 11-21.
    - More than 14 Iranian tankers are said to be massing to break the blockade.
  - **No ceasefire, deal or lifting of the blockade is in force.**
  - The 11-21 weekend escalation post-dates M1R's 11-18 sweep. Whether any of it is a `Qualifying shock event` is for M1R or M1a to measure.
  - **W4 must not route this to M1a (blinding).**

### 4d. Thesis-mechanics read for B

- B's 14 theses are post-event mean-reversion bets with 60-day clocks.
- The week's tape has added a market-wide drawdown roughly equal to the book's own loss. That is the generic risk B's criteria explicitly mark as "not exit-triggering".
- What *is* thesis-relevant, and recorded above per name, is narrower:
  - the AI-financing narrative, which bears on DDOG, ECG and MTRN;
  - the 11-19 export controls, which bear on MTRN;
  - Erasca's data, which bears on RVMD;
  - Gulf escalation, which bears on EXPE.

---

## STRATEGIES A, C AND E — no position

- **A:** DO-NOT-ACTIVATE on both planes. W1 owns the census of 47 A watchlist rows.
- **C:** HYBRID ACTIVATE (FOMC-only). It holds nothing. Its one pending item, `thesis-FOMC-C-20261130`, is due 11-30 for the 12-09 decision (see §4b).
- **E:** DO-NOT-ACTIVATE — PENDING `div-E-202611-3` (attacker verdict: SURVIVES narrowly). It held no position through its brief 11-16 ACTIVATE window.

---

## CORRECTING THIS ROUTINE'S OWN PRIOR FILE

1. **W46's headline said "B ACTIVATE … 451 items … nothing has acted on it yet".** D2 worked the drain on 11-15:
   - 14 GO;
   - 224 NO-GO and 216 NO-ACTION (lapsed windows), plus the CAI/FIG/WMS NO-GOs.

   So the "unworked" state W46 described ended within about 14 hours of that file.
2. **W46 said "VIX stayed NORMAL all four unrecorded sessions" and E was pending `div-E-202611-2`.** Both were true when written.
   - `div-E-202611-2` then resolved **ACTIVATE** on 11-16 (`cbd791c4`).
   - The 11-17 VIX HIGH close de-risked B and E within one session.

   This was later events, not a W46 error.
3. **W46 quoted the 10Y "above 5.1%" and 2Y ~4.87%.** Both were right at the time (warehouse 11-19 10Y 5.04). By 11-20, yields had *fallen* 20 bp on the week (§4b).

## COVERAGE STATED HONESTLY

- **Warehouse (measured):**
  - positions, position events, open orders, open queue;
  - roster and `state.current_regime`;
  - `state.shock_price_leg_status` and `events.signal_marks` (BZUSD);
  - the decision log since 11-15 09:14Z (528 rows, incl. D1 add-candidate, screen and D2 router rows);
  - run log, open alerts and `div-*-202611-3` queue rows.
- **IBKR (free):** daily bars for all 14 names plus SPY and ^VIX through 11-20, and one `search_contracts` call. The 11-16 to 11-19 closes match D1's.
- **External:** 27 Parallel `web_search` calls across four Sonnet sub-agents with disjoint subject sets (ANDE/SM/MCY/SYY 5, ARQT/NRIX/RVMD/IRTC 9, DDOG/ECG/MTRN/ROK 8, EXPE/RELY/macro 5). There were 0 `web_fetch` and 0 FMP calls. No call errored and the search guard never tripped.
- **Not done or not found:**
  - no primary EDGAR sweep (filing status comes from search and aggregators);
  - ethanol board crush;
  - CY2027 PFS final ambulatory-ECG rates;
  - IQVIA ZORYVE weekly TRx;
  - RVMD Q4 consensus;
  - EXPE FY27 EBITDA consensus;
  - RELY FY27 revenue consensus;
  - the scope of the 11-19 export controls against MTRN products;
  - Snowflake, Dynatrace and Cloudflare prints.
- **Open alerts (fleet), before this run: 27 unresolved.** 25 are warning (15 `queue_driven_missed_fire`, 6 `routine_run_warning`) and 2 are info. None is critical. W3 files one more below. W3 has no prior open alert.

## OBSERVED, NOT ADJUDICATED — do not re-flag

- **AR_orc has not judged `div-B-202611-3` or `div-E-202611-3`.** Both were attacker-complete 11-20 00:09Z and due 11-20; the queue-driven judge owns them. A ruling to ACTIVATE would not reopen the closed entry windows of these 14 tranches.
- **BZUSD 11-19 provisional vs the Reuters settle (0.72):** this is expected vendor revision (§4c).

## FILED / CHANGED THIS RUN

- **`ops.alerts`, 1 info row** (`sp_raise_alert`, source W3, category `held_position_review_trigger_unreported`). It names **D1** as owner. D1's 11-18 and 11-19 add-candidate rows called ANDE's criteria "unbreached" while ANDE's populated criterion 5 (close below $52 on volume = review trigger) had been crossed at 47.51 and 47.46. D1 handles the review trigger on its next run. Info severity is deliberate: this is a reading defect in a daily record, not an owner-action item.
- No `events.queue_events` row. No `events.decision_log` row. No `immediate_action_flagged` alert.
- `ops.web_calls`: 27 rows, one per sub-agent `web_search`, with targets verbatim from the sub-agents' returned query arrays. The run's own `ops.run_log` rows are logging, not output.

## STEPS 1–6, DISPOSED

| Step | Disposition |
|---|---|
| 1 Thesis status | Done for all 14 B tranches. The D1 window 11-16 to 11-19 was taken as already covered; 11-20 and the weekend are new. The span is a single week (no missed cycle) |
| 2 Competitive landscape | Done per name. Material: Erasca ERAS-0015 (RVMD), the GPRE same-day move (ANDE), Booking's Vayo (EXPE), the PANW raise (DDOG), PFGC reiteration (SYY), WU/Intermex (RELY) |
| 3 Fundamental developments | Done per name: filings, analyst actions and conference commentary |
| 4 Sector and macro | §4a–4d |
| 5 Invalidation signals | Per-criterion tables above. None newly met on a slow-burn basis. ANDE criterion 5 was met on 11-18 (a daily price trigger: D1's domain, alert filed). RVMD (2), DDOG (2), ECG (3), MTRN (2), EXPE (2) and MCY (2) moved closer |
| 6 Time-to-resolution | All 14 are inside a 60-day window. RVMD's Q4-sales criterion may not be observable before 2027-01-15. ARQT's vitiligo readout (Q4) and NRIX's ASH data (12-12 to 12-15) fall inside the window. Mechanical exits remain D1/D2's sole domain |

## WHAT W4 OWES ON THIS FILE

- **No `WEEKLY-THESIS-ACTION` flag.** Nothing for D2 to revalidate or convert.
- **Three further-research recommendations** (ANDE, NRIX, RVMD). Each names its information gap above. They are research referrals, not trade actions. W4's queue-only handoff decides whether any warrants a queue row; W3 mints none.
- **Cross-strategy deconfliction:** B's 14 tranches overlap D on factors, not tickers:
  - the AI-infrastructure cluster (B's DDOG/ECG/MTRN/ROK and D's GOOGL/AMZN/TSM/GEV);
  - medtech (B's IRTC and D's ISRG);
  - travel and consumer (B's EXPE and D's UBER/DIS).

  No ticker is held by two strategies.
- **§4 is evidence, not referrals.** W4 must not route the shock channel to M1a (blinding).
