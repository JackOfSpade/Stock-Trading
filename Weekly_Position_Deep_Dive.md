2026-W34

# W3 — Open-Position Deep-Dive (Strategies A, B, C, E)

**Run date:** 2026-08-17 (Monday; `state.trading_day_today.today` = 2026-08-17, `is_trading_day=true`, `last_trading_day=2026-08-17`). The 2026-08-17 session was **still open** while this file was written, so **every price below is the 2026-08-14 (Friday) regular-session close** — the last *completed* session — pulled via `get_price_history`, `step=ONE_DAY`, `outside_rth=false`. Today's intraday prints are referenced exactly twice, both explicitly labelled as non-closes, and nothing in this file rests on them.

**Marker `2026-W34`.** 2026-08-17 is a Monday and the first day of ISO week 2026-W34, so the convention (ISO week of the run date, never a look-ahead) gives W34. W2 also ran today and stamped `2026-W34`; **W1 ran Sunday 2026-08-16 and correctly stamped `2026-W34` as well.** All three weekly files therefore agree this cycle and W4's upstream-freshness read matches. Note for a future reader: W1's Sunday run falling inside the *same* ISO week as a Monday W2/W3 is the benign case — the Mon/Sun anchor mismatch documented in the shared Observability section bites only when a Sunday upstream lands in the ISO week *before* its Monday downstream.

**Span covered: since W3's own last successful completion, 2026-08-09 → today.** `state.routine_catchup_window` gives `window_start_ts` 2026-08-09 and `window_days = 8.28`, against a 10.5-day (1.5×) weekly bar — **cadence-normal, no `CATCHUP[...]` token owed**, no missed-period sub-section due. The five completed sessions newly in scope are **2026-08-10 through 2026-08-14**. The prior W3 file covered through the 2026-08-07 close.

**Scope:** Strategies **A, B, C, E** — the roster-derived `review_cadence: reactive` set (re-verified this run against both `strategy/roster.yaml` and `state.strategy_roster`: A, B, C, E `reactive` and `ADOPTED`; D is `long_horizon` and gets its deep-dive monthly in M3; F/G/H are `REJECTED` and hold nothing). **In-scope open book = one position, `B:MSCI:2026-07-27`.** There are **no open A, C or E positions anywhere in the book.** The twelve D tranches (AMZN ×2, CRM, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER) are out of scope here by design.

**The book halved again.** Two B positions were open at the last review; **ISRG closed 2026-08-12 on its convergence target** (fill $402.64 against a $400 target), leaving MSCI as the only open position in any reactive strategy. Its resolution record is at the foot of this file.

**Research method.** Four Sonnet sub-agent sweeps — analyst-actions, company filings/disclosures, peer complex, sector/macro — plus one targeted follow-up to the filings agent to close its single unresolved item. All price measurement, all BigQuery reads, all arithmetic and all adjudication were retained in-session (claude-opus-5); no sub-agent was asked for a price, a recommendation, or a judgment. Per the shared "One shared pull" rule the orchestrator pulled the price series **before** fan-out and each sweep was told explicitly not to fetch prices; the peer and macro sweeps were told the same in terms, and both complied.

**Price provenance — dual-sourced, and they agree byte-for-byte.** Every MSCI close below was pulled from IBKR daily bars **and** independently cross-checked against `events.daily_marks`: 08-06 567.23 / 08-07 563.17 / 08-10 563.08 / 08-11 561.71 / 08-12 563.01 / 08-13 575.24 / 08-14 569.13 — identical in both sources, `source='connector'`. `include_corporate_actions=true` on every pull: **no split, spin-off or special dividend** for MSCI or any peer measured. One ordinary cash dividend each for MSCI and MCO, both ex-2026-08-14, both handled explicitly below.

---

## IMMEDIATE-ACTION

**None.** The single open position is **HOLD**. No thesis-invalidation criterion is met, and — the material change from last week — **none is closer to breach than at the last review; one is measurably further away.** No `WEEKLY-THESIS-ACTION` flag is set and no `immediate_action_flagged` alert is raised this run.

---

## Summary

All figures are 2026-08-14 regular-session closes.

| Pos (B) | Basis (all-in /sh) | Total basis | 2026-08-14 close | Market value | Unrealized (price) | Div. accrued | Economic P&L | Recommendation |
|---|---|---|---|---|---|---|---|---|
| **MSCI** | $579.2788 (0.0863 sh) | $49.9918 | **$569.13** | $49.1160 | **−$0.8758 (−1.75%)** | +$0.1769 | **−$0.6989 (−1.40%)** | **HOLD** |

The dividend column is not decoration: MSCI went **ex-dividend $2.05 on 2026-08-14** (below), so the price-only unrealized figure now understates the position's economics by $0.1769 and will keep doing so until the 2026-08-28 pay date. `analytics.strategy_nav` carries B `unrealized_pnl = −0.88` (price-only, agrees) and `dividends_held = 0.78` at the strategy level, of which $0.1769 is MSCI's.

**Strategy B: NAV $49.30, available funds $0.18, realized P&L +$20.27 lifetime.** Realized is up from +$13.47 at the last review — the ISRG win. B's NAV is now essentially just this one position's market value, because the capital ISRG released was swept straight out: **`REGIME-CAPITAL SWEEP 2026-08-12: B $55.71 → C $27.86 / E $27.85`.** B remains router **DO-NOT-ACTIVATE** and `capital_disabled = TRUE` (unchanged since 2026-08-05). As last week's file said and this one repeats because the shape still invites misreading: **this neither forces nor argues for an exit.** DNA blocks new B entries only; existing positions run to their own criteria undisturbed. It does mean **no add to MSCI is possible regardless of merit** — there is $0.18 to fund one — and that when MSCI resolves, B's NAV goes to ~zero pending re-activation.

### Weekly and fortnightly cross-section

The single most useful measurement in this file, because last week's review rested on the fortnight's first half and reached a conclusion the second half partly reverses.

**Week, 2026-08-07 close → 2026-08-14 close:**

| | Price | Dividend | Total return | vs SPY |
|---|---|---|---|---|
| MORN | +3.364% | — | **+3.364%** | +2.97pp |
| SPGI | +2.599% | — | **+2.599%** | +2.20pp |
| MCO | +1.509% | $1.03 (ex 08-14) | **+1.725%** | +1.33pp |
| **MSCI** | **+1.058%** | **$2.05 (ex 08-14)** | **+1.422%** | **+1.02pp** |
| FDS | −0.728% | — | **−0.728%** | −1.13pp |
| SPY | +0.398% | — | +0.398% | — |

**Fortnight, 2026-07-31 close → 2026-08-14 close:**

| | Price | Total return | vs SPY (+3.923%) |
|---|---|---|---|
| FDS | +7.709% | **+7.709%** | +3.79pp |
| MORN | +7.706% | **+7.706%** | +3.78pp |
| SPGI | +1.668% | **+1.668%** | −2.26pp |
| MCO | +1.375% | **+1.590%** | −2.33pp |
| **MSCI** | **−0.543%** | **−0.185%** | **−4.11pp** |

**Since entry (2026-07-28 close → 2026-08-14 close):** MSCI −1.417% total return against SPY +4.789% — **−6.21pp of relative give-up over 13 sessions.**

Read these three together, because any one of them alone misleads. This week MSCI beat SPY by 1.02pp and sat mid-pack in its own complex — a clean reversal of the prior week, when it was the *worst* name in the complex and lagged SPY by 5.10pp. But **the fortnight has not reversed:** FDS and MORN, the two closest pure-play subscription-data comparables, are still ~7.9pp ahead of MSCI over two weeks. The correct statement is that the divergence the last review identified **stopped widening; it did not close.** Notably it was FDS — the comparable the prior file leaned on hardest — that did the stalling (+7.71% fortnight, −0.73% this week), while MORN kept going.

---

## MSCI — MSCI Inc (NYSE) — Strategy B LONG — **HOLD**

Entry 2026-07-28, fill 0.0863 sh @ $575.22 MARKET/DAY, commission $0.350275, all-in basis $49.991761. Authorizing thesis `5af250e9-676a-4db2-8819-cdbc39affb14` (D2 2026-07-27, GO, conviction 65%). Convergence target $615, time exit 2026-09-25 — **both mechanical, both owned by D1's every-run sweep and D2's daily conversion, and neither checked as a trigger anywhere in this file.**

### 1. Current thesis status — intact, and untested by any new information

The original thesis: MSCI's Q2 print (2026-07-21) was a clean beat — adj EPS $4.94 vs ~$4.90–4.93 consensus, revenue $867.0M +12.2% YoY, organic recurring-subscription Run Rate growth *accelerating* to 8.1%, retention up to 95.3% from 94.4%, operating margin 56.2% — and the −10.14% close-to-close reaction was driven entirely by a ~$45M FY26 opex guide raise attributed to the disclosed $120M First Street acquisition, AUM-linked incentive-comp accruals, and AI/analytics investment. The entry's decisive argument was a magnitude mismatch: ~$4.6B of market cap destroyed against a ~$45M full-year expense delta (~$34M after tax), a **>100×** gap, with no cross-sectional confirmation from peers that session.

**D1's daily coverage is the baseline, and it found nothing on this name.** D1's `research-screen` records for 2026-08-11, 08-12, 08-13 and 08-16 (single-name-move and sector-move arms) and its add-candidate sweeps across the span surface **no MSCI item at all** — no development, no invalidation trigger, no candidate flag. So there is no daily-detected event for this review to build on, and nothing for it to duplicate.

**Cumulative or slow-burn drift beyond that coverage: none found.** The window produced **zero** new company-specific information of any kind (§3 below). The thesis's central claim has not been tested, let alone contradicted. What *has* accumulated is fifteen sessions of price history since the event, and its shape is the substantive question — taken up in §5 and §6.

### 2. Competitive landscape — quiet in-window; the standing divergence narrowed but did not close

**No peer earnings print, guidance change, rating-category change, index-mandate win or loss, or fee-compression announcement is dated inside 2026-08-08 → 2026-08-17** for FDS, MORN, SPGI, MCO, LSEG, ICE, NDAQ or CME. The only in-window items found are immaterial to this thesis: FactSet declared a routine dividend (2026-08-13), and ICE commenced a ~$3.73B investment-grade bond sale (~2026-08-13) to fund its MarketAxess acquisition — that deal was announced 2026-07-30, i.e. *before* this window, and touches fixed-income trading venues rather than equity index licensing. Recorded and set aside.

Two pieces of **out-of-window** context are worth carrying anyway, because they bear directly on the cross-sectional argument both this review and the last one turn on:

- **Morningstar's capital-markets moat review maintained a WIDE moat on MSCI (alongside SPGI, MCO, Broadridge, FICO, Verisk) while cutting FactSet and SS&C to NO moat**, on generative-AI disruption grounds. I could not date this note inside the window — its own text references FactSet's fiscal-Q2 results of 2026-03-31, so it is very likely months old — and it is therefore **not** reported as new evidence. It matters as framing: the "AI disrupts financial-data vendors" thesis, where a major independent research house has applied it, was applied to FDS and *not* to MSCI. That is relevant to reading FDS's price action as a comparable at all.
- **LSEG (FTSE Russell's parent) reported H1 2026 on 2026-07-30 and raised FY guidance** (organic income growth to 7.0–7.5% from 6.5–7.5%). Out of window, but it is the nearest thing to a datapoint on whether index-provider economics are deteriorating industry-wide. It says they are not.

**The honest cross-sectional read, given the numbers in the Summary:** the prior review's concern was that FDS and MORN — closer comparables to MSCI's subscription model than any exchange or ratings name — rallied +8.50% and +4.20% while MSCI fell, i.e. the sub-sector re-rated up and MSCI did not participate, cutting against the entry's "idiosyncratic, not a sector re-rate" argument. This week that pattern **inverted**: MSCI +1.06% (+1.42% TR) mid-pack, FDS the only decliner. But one week is a weak sample, the two weeks roughly cancel, and **over the fortnight the ~7.9pp gap to both FDS and MORN survives**. I weight this as: the divergence is real, it is no longer widening, and it is not yet evidence of a durable MSCI-specific re-rating — because there is still **no company-specific negative anywhere in the record** to attach it to.

**The stale-article false positive was suppressed for a third time.** The "Moody's and FactSet stocks slide on S&P Global's weak 2026 outlook / MSCI down 2.7%" story surfaced again in two of the eight peer searches. It is dated **2026-02-10**. Two prior W3 runs killed it; this is the third. It is not evidence in either direction and a fourth reviewer should not have to adjudicate it again.

### 3. Fundamental developments — a genuine, EDGAR-verified zero

**No SEC filing of any type is dated 2026-08-08 through 2026-08-17.** Checked three ways against SEC EDGAR directly (a free primary source, not an aggregator): `type=8-K` — most recent is **2026-08-07**, one day before the window, the Item 5.02 officer-succession filing already adjudicated in a prior review as a scheduled succession disclosed 2026-03-31, with no Item 4.02, no restatement and no material-weakness language; unfiltered all-types — nothing in-window; `type=4` — most recent 2026-06-12, so **no insider transactions** either. This negative is auditable at the EDGAR URLs, which is a materially stronger evidentiary basis than the aggregator-sourced negatives this file has had to rely on in past weeks.

**No analyst action of any kind is dated in-window** — no rating change, no target change, no initiation, no coverage drop. Established across eight independent trackers (MarketWatch's MSCI page *and* its all-ticker upgrades/downgrades tool, MarketBeat, Benzinga, stockanalysis.com, marketscreener.com, tickernerd, finviz) plus, usefully, the personal action log of BofA's Curtis Nagle — a covering MSCI analyst who published on seven *other* tickers between 2026-08-05 and 2026-08-12 and none on MSCI. MSCI's own IR page lists **18 covering firms**; this is aggregator-freshness evidence, not a firm-by-firm poll of all 18, and TipRanks/Zacks could not be checked directly (403). Detail in §5.

**The August 2026 Index Review was published on schedule and is a non-event.** Results went out **2026-08-12** shortly after 11:00pm CEST (MSCI IR press release, corroborated by the primary standard-list PDF at `app2.msci.com` dated the same day and by multiple press pickups); changes take effect after the close **2026-08-31**, exactly as scheduled. Headline counts — ACWI 55 additions / 92 deletions; ACWI Small Cap 203/261; ACWI IMI 184/279; World All Cap 137/73; Frontier 6/5 — sit inside the normal range for an August cycle (Aug 2025: 42/56; Aug 2024: 27/96), with heavier deletions than some prior cycles but nothing anomalous. **No methodology change, consultation outcome or market reclassification** surfaced alongside it, though that last point rests on search-snippet coverage rather than a full read of the release, so it is a well-supported "nothing found," not an exhaustive "nothing exists." The prior review flagged this as the only scheduled company-specific event before the time exit; it has now happened and it changed nothing.

**Ex-dividend $2.05 on 2026-08-14 — CONFIRMED, and by our own data, not just by aggregators.** `events.daily_marks` carries `ticker='MSCI', mark_date='2026-08-14', dividend=2.05, source='connector'` — the broker's own corporate-action attribution places the dividend on the 08-14 bar. That is a primary, in-system confirmation, and it converges with eight independent external trackers (StockAnalysis, Simply Wall St, DividendMax, Stock Events, Digrin, Koyfin, Futu, Yahoo) all reporting ex-date = record date = 2026-08-14 under T+1, consistent with the record date already known from the Q2 10-Q. **One outlier (Investing.com) says 2026-08-13; it is wrong**, and the connector's own dividend attribution is what settles it rather than the 8-to-1 count. Declared 2026-07-20, payable 2026-08-28. Consequences are worked through in §5.

**No expense-guidance escalation and no reframing of the FY26 opex raise.** No in-window 8-K, no conference appearance, no investor-day, no guidance revision, no management statement at all — MSCI's IR events page lists nothing between the 2026-07-21 Q2 call and today. Criterion 3 is unbreached on an evidentiary base of "the company said nothing," which is the strongest form this particular negative can take.

**Instrument eligibility, checked because a protocol landed today.** A `MARKET CAP BASIS` protocol was added to `Operating_Protocols.md` §11 on 2026-08-17 requiring SEC-filing-derived shares outstanding near the $2B/$10B eligibility floors. MSCI is at roughly **$41B** (≈72.8M shares × $569.13) — nowhere near the floor, so the new protocol does not bind here. Recorded so it is visibly considered rather than silently skipped.

### 4. Sector and macro context — a mild multiple tailwind, and a mechanism headwind

**For a ~30× recurring-revenue compounder, the rate and volatility backdrop continued to improve, more slowly.** July CPI (released 2026-08-12) printed **+0.1% MoM headline / +0.2% core**, in line, with YoY at 3.4% / 2.5%; shelter was ~two-thirds of the monthly increase and energy fell 1.5% MoM. Market-implied odds of a **September hike** — the live debate all summer has been hold-versus-*hike*, not hold-versus-cut, after the 9–3 July FOMC — continued falling: ~44% on 2026-08-07 → **~30% on 2026-08-16**. Treasury par yields drifted down modestly (2Y −3bp, 10Y −5bp, 30Y flat, 08-10→08-14), against −9/−10/−8bp the prior week: **the big repricing is behind us and the curve is consolidating**. HY OAS unchanged at ~270–275bp, still historically rich. VIX drifted 14.90 → **14.25** inside a 14.25–15.46 band, no spike — `state.current_regime` classifies VIX_REGIME **LOW**, SPY_TREND **UP**, EQUITY_BREADTH **HEALTHY** (72.76%). All of that is a tailwind for a long-duration recurring-revenue multiple, and it is the *second* consecutive week in which the macro moved MSCI's way.

**The mechanism-level reading is less comfortable, and it is the item worth carrying forward.** Strategy B's own router poses the question directly: *is the current environment one in which event reactions show measurable mean reversion at 2–8 week horizons, or is the market in a regime where reactions are fully informative?* The evidence this week leans toward the second: the index is at record highs (a 26th record close of the year as of 08-14), breadth is **rising** rather than narrowing, and cross-stock correlation is reported near record lows. A broadening, persistent, record-high tape is the classic weak environment for mean reversion — a headwind to B's edge generally, and therefore to this position's convergence specifically.

Two honest qualifications, because the point cuts both ways. First, the breadth/correlation read rests on a **single non-mainstream source** citing a proprietary indicator, and the sweep exhausted its budget before a second independent confirmation for dates inside the window — it is directionally consistent with our own `EQUITY_BREADTH` measurement of 72.76% (broad participation, the widest since December 2024) but is not independently corroborated as a *correlation* claim. Second, **record-low cross-stock correlation actually helps this particular mechanism**: single-name mean reversion is easier to isolate and realise when moves are idiosyncratic rather than macro-driven. A trending index with low correlation beneath it is not straightforwardly hostile to a single-name post-event reversion thesis. I record the headwind as real but not decisive, and note that B is *already* router DO-NOT-ACTIVATE, so this is consistent with the standing router state rather than new information about it.

**The Hormuz shock escalated, and its characterisation changed.** The prior review described it as a live risk "the equity complex is still refusing to price." In-window: a fresh tanker attack logged by UKMTO on 2026-08-08 (the 84th incident since 2026-03-01, assessed "highly likely" a deliberate hostile attack by JMIC); two more ships attacked by 2026-08-14 with the US Navy blockade stated as maintainable "indefinitely"; traffic at ~20% of pre-war levels; war-risk insurance up from 0.25% to 7.5–10% of vessel value (~$345K → $10M+ per VLCC crossing). So the risk is **not merely live but demonstrably escalating, and it is being priced — in shipping and insurance markets, not in equity or vol.** That gap widened this week rather than closed. This feeds the `shock_overlay = acute` axis that produced B's DNA in the first place; it is not MSCI-specific and implies nothing about this thesis, but a reviewer should know the standing macro risk got worse while the equity tape got calmer.

### 5. Thesis-invalidation signals — none breached, and the trajectory reversed

The three criteria are immutable from entry. Assessed individually, with the cumulative direction stated:

**(1) First ratings downgrade from any covering analyst — UNBREACHED.** Zero rating-category changes in-window across eight independent trackers plus a covering analyst's own action log. The most recent rating-category change on MSCI in *any* direction is **Wells Fargo's Equal-Weight → Overweight UPGRADE on 2026-05-27** — the criterion has not merely failed to fire, the last move on that axis was favourable. Every post-print action remains a price-target move with the rating explicitly maintained (JPM 742→700, Evercore 746→722, Wells Fargo 700→690, Clear Street 643→615, UBS set 615, and — newly surfaced this run, still out-of-window — BofA 730→715 on 07-22/23 with Buy maintained, and Autonomous Research 797→**805**, a *raise*, on 07-24, maintaining Outperform). The $615 target floor still sits above the last close.

Three known false positives stayed dead and are recorded so a fourth reviewer need not re-adjudicate them: **Clear Street** has been at Hold *continuously since initiation*, so its 07-22 $615 action is a reiteration and not the "criterion already met five days before entry" that a careless read produces; **Redburn's** Buy→Neutral/Neutral→Sell pair is from **2024**; **Weiss Ratings'** letter-grade moves are a quantitative service, not a covering sell-side analyst.

*Completeness, stated plainly:* this is a negative established from the freshness of eight aggregators, not from polling all 18 covering firms' primary notes. TipRanks and Zacks could not be reached directly (403) and are **unchecked**, not confirmed-negative. Given the corroboration density I treat the criterion as unbreached with high confidence; I do not treat it as proven.

**(2) A fresh close below $550.79 with no accompanying new information — UNBREACHED, and the margin WIDENED.** The lowest close in the window is $561.71 (08-11); the last close is $569.13, **+3.330% above the line**, against **+2.248%** at the prior review (563.17). **The cushion grew by 1.08pp.** The prior review's warning that this was "the single item in the whole file most likely to become actionable, and one ordinary bad session away" has, for now, eased rather than materialised. Two things qualify that:

- **Today's intraday print is $559.39, only +1.56% above the line.** It is *not* a close, it is not load-bearing, and it does not enter any assessment here. It is stated because a reader comparing this file to Tuesday's tape should know the direction of travel on the day it was written.
- **The ex-dividend now sits inside the criterion, and it makes the line fire EARLIER than drafted.** The $550.79 trough was set on the 2026-07-24 close, cum-dividend. Since 2026-08-14 the price series is permanently $2.05 lower for a purely mechanical reason. The economically-equivalent post-ex line is **$548.74**, against which the current cushion is **+3.716%**, not +3.330%. So the criterion as written is now roughly **0.37pp more conservative than its own economics** — it will trip on a stock that has not actually fallen to the trough it was drafted against.

  **This is not a licence to redraft it.** The criterion is immutable, D1 fires on it literally, and the drift happens to run in the *safe* direction (toward invalidation, toward exit), which matches the system's conservative-default posture. The point is narrow and it is for the second look: **if criterion 2 fires, W4/D2 must net out the $2.05 before reading the breach as thesis deterioration**, because up to $2.05 of any move toward the line is a dividend, not a market verdict. The prior review flagged this prospectively; the ex-date has now passed and it is realised.
- Also carried forward, still true and still worth not rediscovering: **$550.79 is a post-event trough, not a technically significant floor.** MSCI closed $554.85 and traded $542.33 intraday in the week of 2026-06-22 — below the line, six weeks *before* the event, on ordinary tape.

**(3) Further FY26 opex/expense guidance escalation, or management reframing the raise as durable/structural rather than AUM-linked, before 2026-09-25 — UNBREACHED.** No 8-K, no conference, no investor day, no guidance revision, no management statement of any kind in-window (§3). Nothing to assess against.

**Cumulative verdict.** No criterion is breached. **No criterion is closer to breach than at the last review, and criterion 2 is measurably further away.** Last week's file described a position whose cushion had halved in five sessions; this week the cushion is back above its level of a fortnight ago and the only criterion with a moving part is moving the right way. That is a genuine reversal of trajectory, and it is the reason this file's recommendation carries less tension than the last one's.

### 6. Time-to-thesis-resolution — and a correction to how last week measured it

**29 trading sessions remain from today through 2026-09-25 inclusive** (28 after today), computed against `events.market_holidays` with Labor Day 2026-09-07 excluded, not estimated. **No MSCI earnings event lands inside that span** — Q3 prints late October, which is precisely why the convergence target is a numerical level rather than an event marker — so convergence has to come from multiple repair rather than a catalyst. The only dated forward company item is the Index Review's effective date after the close 2026-08-31, which is index mechanics and not an MSCI-Inc catalyst. *(The time exit and the target are mechanical and are D1's and D2's to detect and convert. The distances below are trajectory measurements for this cumulative review, not trigger checks, and this file performs no exit check of any kind.)*

**The correction.** The prior review leaned on a realized-volatility figure of **43.92%** to argue that a +9.2% recovery in the remaining sessions was "unremarkable," and separately puzzled that implied volatility of 26.69% sat at the 0th percentile of its 13-week range — the market "pricing calm, not repair." **Both readings are artifacts of a single bar.** Measured over the 19 sessions since the event, annualized realized volatility is **45.5%** — but strip the 2026-07-21 event day itself and the trailing 18-session figure is **23.8%**. The event bar is essentially the entire volatility estimate.

That changes two things. First, the implied-versus-realized puzzle largely dissolves: implied ~26.7% against post-event realized ~23.8% is a normal, slightly-elevated implied, not a market ignoring a 44%-vol stock. Second, and less comfortably, the resolution arithmetic gets harder rather than easier. The target sits **+8.06%** above the last close (down from +9.20% a week ago, so the gap did narrow). At 23.8% annualized — daily σ ≈ 1.50% — the standard deviation of the move over the 28 remaining sessions is **≈7.94%**, so the required move is about **1.0σ**. Under a driftless lognormal that is roughly a **15%** chance of finishing at or above the target, not the near-noise a 44%-vol framing implies. The estimate is from a short sample and the event-day exclusion is a judgment call, so treat it as an order of magnitude rather than a probability — but the order of magnitude is the point, and last week's was wrong by roughly a factor of two in the optimistic direction.

**Resolution risk is therefore real and cumulative, and it is the strongest argument against this position in this file.** It is also, precisely, not an exit criterion: Strategy B's exit rules are convergence, thesis invalidation on new public information, and the 60-day expiry — and the "Not exit-triggering" list names *adverse mark-to-market without news* explicitly, for long positions, which is exactly what a −1.40% position with a zero-information week is.

### Recommendation: **HOLD**

Not `weekly-thesis-action`, and not `further research`.

- **Not `weekly-thesis-action`.** That disposition is reserved for a cumulative or slow-burn completion or invalidation finding that D1's daily mechanics did not already detect. There is no such finding: no criterion is breached, none is closer than at the last review, and the window produced **zero** new company information against which a slow-burn case could even be built.
- **Not `further research`.** The one genuine information gap is that TipRanks and Zacks were unreachable, so criterion 1 rests on eight other trackers rather than ten. A deferral would not close it — the same 403s would greet the next session — and the gap does not change the assessment, since the corroboration already includes MSCI's own covering-analyst roster cross-checked against one covering analyst's personal publication log. **Stated here explicitly so W4 does not re-derive it.**
- **The affirmative case for HOLD** is that every criterion is unbreached on evidence that got *stronger* this week (an EDGAR-verified filing negative rather than an aggregator-sourced one), the criterion-2 cushion widened, the peer divergence stopped widening, and the macro backdrop moved favourably for a second consecutive week.
- **The case against, recorded honestly rather than buried:** the position is −1.40% and has given up 6.21pp against SPY in 13 sessions; the fortnightly gap to the two closest comparables is still ~7.9pp; the tape is a persistence tape, which is the weak regime for B's mechanism; and the corrected volatility estimate puts convergence at roughly 1σ rather than comfortably inside noise. None of these is an exit trigger under B's rules, and B's rules are explicit that adverse mark-to-market without news is not one. But a reader should not come away thinking this is a comfortable position — it is an intact thesis with a deteriorating clock.

---

## Strategies A, C and E — no open positions

Confirmed against `state.current_positions`: **zero** open A, C or E rows. Router states, for the record: **A** DO-NOT-ACTIVATE (capital-disabled), **C** HYBRID ACTIVATE (FOMC-only) — capital-enabled but parked, its last four FOMC drains all NO-GO on absent documentable divergence — and **E** ACTIVATE and capital-enabled with $15,309.94 NAV but nothing deployed. Nothing in this file's scope to review for any of the three; recorded affirmatively so the absence reads as measured rather than overlooked.

---

## Position resolved inside this span

**B:ISRG — CLOSED 2026-08-12 on its convergence target, profitably.** The $400 target was hit on the 2026-08-11 close ($401.23), triggering a mechanical full flatten of the (B, ISRG) bucket — 0.1388 sh staged as instruction 100 — and the exit filled at **$402.64** on 2026-08-12. This was a clean mechanical resolution: D1 detected, D2 converted, D2a reconciled, and no discretion was exercised anywhere in the chain. It is recorded here as a resolution record, not as an open-position review. B's lifetime realized P&L moved from +$13.47 to **+$20.27** on it. The released capital did not stay in B — see the 2026-08-12 regime-capital sweep in the Summary.

---

## Notes for W4 and W5

- **No W4 action is owed by this file.** The one open position is HOLD; there are no exits to stage, no thesis actions to hand to D2, no `further research` deferrals to enqueue (the case for one is examined and rejected above, with reasons, so W4 need not re-derive it), and no immediate-action flag.

- **`state.trading_enabled` is FALSE, and it is the benign intraday artifact, not an incident.** `halt_reason` reads *"state.freshness marks_fresh/engine_fresh not both TRUE"*; underneath, `marks_current` and `engine_current` are both **TRUE** with marks complete through 2026-08-14 and `marks_due_through = 2026-08-14`. The gate is FALSE only because `last_trading_day` is today, today's session had not closed, and D2a has not yet run for it — exactly the pre-close shape the 2026-08-03 cycle also hit. It should clear on tonight's D2a. **W3 stages nothing, so this has no effect here**; it is flagged because W4 runs downstream and a related `critical` `trading_halted` alert (D2a, 2026-08-17 00:02 UTC) is open on the board.

- **W5's 2026-W34 run never happened, and W5 is this file's downstream consumer.** An open OPS0 `catchup_refire_blocked` warning records that W5 fired 2026-08-16, HALTED at pre-flight on a de-authorized BigQuery connector, and then had a **phantom `completed` row** written into `ops.run_log` by the RUNBOOK §38 marker backfill — which parses a leading routine token plus an ISO date and never reads the word HALT in the commit subject. The consequence is that W5 alone shows `ran_completed_this_period=TRUE` while W1/W2/W3/W4 correctly show FALSE, so it will **never** raise `period_missed` and never reach OPS0's auto-refire readiness. It needs a hand re-run before the 2026-08-23 W5 cycle. Not W3's to fix and already alerted; carried here because **this file is written for W5 to consume**, and W5 has not run since 2026-08-09.

- **DATA-PLANE: today's FMP failure was RATE-LIMIT, not the plan-tier lockout — so the prior diagnosis is untested today, not refuted.** The prior W3 diagnosed the FMP failures as a hard plan-tier lockout (`ACCESS DENIED — requires higher plan`) that OPS1's morning liveness probe structurally cannot see. This run's single FMP test returned a *different* error: **`Rate limit reached... exceeded request/bandwidth allowance`**. That is consistent with W2 having spent the account-wide 250-request daily cap this morning, and it means today's probe **could not reach the plan-tier question at all**. The prior finding stands unrefuted and unretested. The practical consequence is the same either way and is worth stating once more: Strategy B's criterion 1 is written on sell-side analyst actions, and it was again assessed entirely on web aggregators.

- **PROCESS DEFECT: `include_usage=true` is mandated by the shared metered-calls rule but is NOT an exposed parameter on this Tavily MCP connector's schema.** Three of four sweeps independently hit a pre-execution validation error on it; **six sub-agent calls were rejected before executing** (unbilled, but they cost latency and had to be reissued). The rule's part (b) requires `include_usage=true` on *every* call so that the `credits_reported` field in `ops.web_calls` can be TRUE rather than an estimate. **Through this connector that is currently un-executable**, so every Tavily row this fleet writes will carry `credits_reported=FALSE` until either the connector exposes the parameter or the rule is amended to say "where the connector supports it." Referred to W5. This run's credit figures are consequently **routine-ESTIMATED from the published rate card** (basic 1, advanced 2), not provider-REPORTED.

- **DATA-QUALITY: a 17–36bp disagreement between FMP's treasury series and Treasury.gov's own par yield curve, for the same date.** `events.regime_events` `TECHNICAL_SIGNAL/SUSTAINED_INVERSION` for `as_of 2026-08-14` records **10Y = 4.68 / 2Y = 4.17** (spread +0.51), sourced from FMP `economics` treasury-rates. The US Treasury's own daily par yield curve for **2026-08-14** reads **10Y = 4.51 / 2Y = 3.81** (spread +0.70) — a 17bp gap on the 10Y and 36bp on the 2Y. **The signal VALUE is unaffected**: both series put 10Y above 2Y, so the curve is NORMAL and `NOT-SUSTAINED` is correct either way, and no gate or router state turns on this. But the two sources are measuring something different, or one is stale, and Treasury.gov is the primary source for that curve. This is a MEASURED discrepancy from a single cross-check, **not** an established defect in FMP — referred to W5/D2a to determine which series FMP is actually returning before anything downstream is built on those levels.

- **`analytics.b_pairwise_correlation` is now inert at n=1.** With ISRG closed there is one B position, so there is no pair to correlate and the KL #12 concentration check cannot engage for the remainder of MSCI's life. Sector concentration is trivially a non-issue at n=1. Fail-safe behaving as designed, not a data gap.

- **Metered-call spend, this run: approximately 30 credits, routine-ESTIMATED.** Roughly 25 Tavily searches and one extract across four sub-agent sweeps plus one follow-up, mostly at `advanced` depth (2 credits) with the remainder basic (1). Six further calls were rejected pre-execution by the `include_usage` validation error above and were not billed. Free and unmetered, and deliberately preferred wherever they would answer the question: all IBKR price history and contract resolution (13 calls), all SEC EDGAR filing checks, all BigQuery reads, and the BLS/Treasury.gov direct fetches. Two findings in this file — the EDGAR filing zero and the ex-dividend confirmation from `events.daily_marks` — came from free primary sources that are strictly better evidence than the paid aggregators they replaced.
