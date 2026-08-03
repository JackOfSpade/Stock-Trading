2026-08-03
<!-- d1_scan_through_utc: 2026-08-03T22:24:49Z -->

# Daily Market Development Scan — 2026-08-03 (Mon, MT)

**Scan window:** 2026-08-02 22:14 MT → 2026-08-03 16:24 MT (≈18.2h). The prior-run marker `<!-- d1_scan_through_utc: 2026-08-03T04:14:43Z -->` parsed cleanly from the `Daily.md` on disk, cross-checked against that file's commit at 2026-08-03T04:19:35Z (agree to within 5 min). `state.routine_catchup_window` reports `window_days = 0.74`, `never_completed = false` — below the 1.5× daily threshold, so **no `CATCHUP[]` token this run**. The window contains exactly one full trading session: **Monday 2026-08-03** (`state.trading_day_today.is_trading_day = true`).

**Tape summary — measured, at/after the 14:00 MT close.** A broad, oil-led risk-on session that took the Dow to a record. **S&P 500 7,599.97 (+1.47%)**, ~0.1% off its record; **Dow 53,178.41 (+1.32%), a record close**; **Nasdaq Composite +2.1%**; **Russell 2000 2,981.91 (+1.73%)** — small caps leading, i.e. broad rather than mega-cap-only. **VOO 696.96 (+1.50%** vs Friday's 686.65**)**, day range 688.61–697.31 (IBKR live, 22:15Z). **VIX 15.86 (−0.81%** from 15.99**)**, day range 15.54–16.30, and now **below both its 50-day (17.38) and 200-day (18.70) averages** — FMP `^VIX` ts 20:14Z, cross-checked exactly against the IBKR CBOE daily bar. VIX3M 18.93 (−0.47%); VIX9D printed 13.15, **identical to Friday — flagged as possibly stale, not used**. **The move is oil.** Brent ~$83.6 and WTI ~$79.5, each down ~4.5–6% on the session as the Iran war premium unwound further; **XLE −1.21% was the only sector that fell.** Rates eased modestly across the curve: **2Y 4.25% (−3bp), 10Y 4.70% (−5bp), 30Y 5.23% (−4bp)** — the 30Y is off Friday's 5.27% 19-year high but still above 5.20%, and it eased *despite* a hot ISM and a $68B increase in Treasury's Q3 borrowing estimate, which is itself informative about long-end absorption. Gold $4,107.00 (+0.40%), silver $58.30 (+0.77%). **EURUSD 1.15072 (−0.20%); USDJPY 157.421, essentially flat** — notable, because the US and Japan confirmed a rare joint yen-buying intervention today (below). BTC $63,447 (−0.08%) and ETH $1,857.57 (−1.36%) did **not** ratify the equity risk-on. Credit firm: HYG +0.27%, JNK +0.30%; `hy_oas` **2.84** (FRED, July ref-month, up from 2.74 in June — still in the tight third of its trailing-12m range). **Not obtained this run** (flagged rather than estimated): a clean API print for WTI, copper, natural gas, DXY at API level, HY OAS in bps, and breadth (A/D, %>50dma, new highs/lows) — FMP `quote`/`chart`/`commodity`/`news` endpoints are **plan-gated (ACCESS DENIED) on this account's tier**, which materially constrained several screens below and is called out where it bites.

## TL;DR

- **Exits triggered — 1: MTZ (Strategy B).** Thesis invalidation criterion 3 (bear-cluster) **independently CONFIRMED at n=5 analysts**, not the 3 the upstream alert named. Position entered this morning; invalidated the same day.
- **New entry candidates — 2, both marginal: SRAD, TGTX (both Strategy B).** Each clears criterion 1 mechanically; each carries a named sub-pattern risk that a thesis session is likely to reject at criterion 4.
- **Add candidates — none.** 17 open A/B/D positions evaluated, 0 flagged, **3 declined at the HARD GATE** (MDT, ISRG-B, MTZ).
- **Watchlist changes — none.** (The FTV item below is a live-position adjudication, deliberately **not** routed as a watchlist action — see RECOMMENDED ACTIONS.)
- **Regime review — no review.** Five divergence reviews (A/B/C/D/E) are already in flight from M4 today; today's ISM 55.6 is material evidence *for* them, not grounds for a sixth.
- **Park — SWITCH SGOV → VOO** (MEDIUM, 60, BOUND, re-risk). First direction change since the 2026-07-26 de-risk.

---

# DEVELOPMENTS

## 1. Market-wide breaking events

**1a. Iran / Strait of Hormuz — the de-escalation is real in oil and denied in Tehran.** Over the weekend Trump called off a planned strike on Iranian energy infrastructure — which he described Sunday as what would have been "the biggest attack since World War II" — at Saudi/UAE/Qatari request, citing agreed "perimeters of a deal" covering a full Hormuz reopening (Times of Israel; ABC News). **Monday materially complicated that.** Iranian foreign-ministry spokesman **Esmail Baghaei stated "We are not currently negotiating with the United States,"** and said Iran would not host or be hosted by a delegation; FM Araghchi described the only live channel as **Iran–Oman talks on a *temporary* safe-passage route, "in the final stages"** (Al Jazeera; Bloomberg wire via Spokesman-Review). Trump, from the Oval Office, called this Iran's **"last chance,"** called Iran "unbelievably duplicitous" for the public denial, and **walked back** Sunday's claim that talks would begin "this afternoon" to "the next day or two" (PBS NewsHour).

*Reaction (measured):* Brent −~4.7% to ~$83.6 (intraday low $81.55), WTI −~5.5% to ~$79.5 — a **second** consecutive session of give-back, not a bounce. Equities rallied broadly (above); **XLE −1.21% was the only declining sector**; European travel/leisure +2.1% against European energy −2% (Guardian). Gold roughly flat at ~$4,107 — the risk premium is coming out of oil, not out of gold. IG's Tony Sycamore, quoted in the Guardian, framed the risk plainly: whether this week is "a rinse and repeat of last week — with hopes of a deal collapsing as Iran digs in its heels."

**This is the single most consequential item on the tape and it is explicitly one-sided.** `state.current_regime` already scores `shock_overlay = acute` as of 2026-08-01, and M1a's rationale — written today at 11:12Z, i.e. *with* the weekend news and *with* Iran's denial in hand — reaches the same conclusion this scan does: "a one-sided operational pause, not a negotiated de-escalation." Nothing today upgrades that. What today *does* establish is that the market is willing to price the pause at VIX 15.86 while the overlay stays acute.

**1b. US–Japan joint FX intervention — first since 2011.** Japan's MOF (FM Satsuki Katayama) confirmed joint yen-buying intervention with the US Treasury to counter "excessive volatility and disorderly movements," adding Japan "will not hesitate to conduct further joint intervention" (Al Jazeera; NPR/AP). The yen had fallen toward a ~40-year low. **The cross-check is unflattering to the intervention:** USDJPY closed at **157.421, +0.01% — flat.** Whatever snapback occurred intraday, the pair ended the session unmoved, which is a poor result for a coordinated two-central-bank operation and a live risk of a follow-up attempt. **Nikkei 225 −1.4% to 63,445.53** as a firmer yen hit exporters — Asia traded its own story against a risk-on US tape, the same divergence flagged in the prior scan.

**1c. Tariffs — a 25-state suit over the new Section 301 regime.** Reported Monday, but sourced **only** to a news-organisation social post with no primary wire or docket confirmation found. Background is solid (the 10% global Section 122 tariffs expired 2026-07-24 at their 150-day statutory limit and were replaced same-day by Section 301 tariffs of 10–12.5% across ~60–80 countries). **Recorded as UNCONFIRMED**; no observable market reaction attributable to it.

**1d. Nothing else material.** No bankruptcy, disaster, sanctions action, or other market-wide shock inside the window.

## 2. Scheduled events that resolved today

**2a. ISM Manufacturing PMI (July): 55.6 vs 54.0 consensus, 53.3 prior — the highest reading since May 2022** (ismworld.org, MEASURED). This is the most important number of the day after oil and is discussed under REGIME CHECK: it cuts directly against the `growth_momentum = decelerating` score M1a wrote on 2026-08-01 off June payrolls and Q2 GDP. **The corroboration is not clean:** S&P Global's final US Manufacturing PMI for July printed **53.9** (vs 53.8 flash, 53.9 prior June final) — flat, and diverging sharply from ISM's jump. Two manufacturing surveys, one screaming and one flat.

**2b. Treasury Q3 2026 borrowing estimate raised to $739B, +$68B vs May's $671B**; Q4 projected $628B (Treasury sb0485; Reuters). The full Quarterly Refunding Statement lands Wednesday 2026-08-05, outside this window. Supply-relevant to the long end — and, as noted, the 30Y still fell 4bp today.

**2c. Earnings.** Confirmed prints: **Palantir** (Q2 revenue $1.935B vs $1.812B est, +93% YoY; EPS $0.41 vs $0.35; FY26 revenue guide raised to $8.150–8.158B from $7.65–7.662B; **+7.35% after-hours to $134.89** on top of +2.1% in the regular session); **Snap** (EPS $0.06 vs −$0.12 consensus — a loss-to-profit beat; revenue $1.599B vs $1.539B; **+7.7% regular, ~+16% including after-hours**); **ON Semiconductor** (revenue $1.6035B, +9% YoY; GAAP EPS $0.56 vs $0.41 YoY; AI-datacenter revenue guided to more than double in 2026); **Marriott** (adj. EPS $3.19 vs $3.08 — *fell* on a cost-reimbursement revenue miss and a demanding guidance bar); **CNA Financial** (EPS $1.19 vs $1.05); **Tyson Foods** (sales $13.868B ~flat YoY, adj. EPS $0.99 vs $0.91 YoY); **Loews**; **EchoStar** (revenue $3.58B — sources conflict on beat vs miss; **flagged unresolved**).

*Coverage limits, stated rather than papered over.* Roughly 110 US names were scheduled today. A large AMC cohort — Vertex, Williams, ONEOK, Diamondback, SBA Communications, Jazz, Clorox, AES, TKO, Grab, Alexandria, Vornado and others — had **consensus available but actuals not yet confirmed** by the 22:11Z cutoff. **Berkshire Hathaway is explicitly unresolved, not reported:** sources conflict on the date (Aug 3 vs Yahoo's own "Aug 8" estimate vs a claimed Aug 14 call) and no figures or filing dated today were found. FMP's `quote` and `economics` endpoints being plan-gated is the proximate cause of most of this gap.

**2d. FDA / PDUFA: none resolving today.** Nearest are Aug 5 (Moderna flu vaccine), then Aug 13/17/23/25/28/30. No advisory-committee meeting today.

**2e. FOMC / central banks: no meeting today.** See §5 for NY Fed commentary.

**2f. Other scheduled catalysts: none identified** (no M&A shareholder votes, index rebalances, or at-scale lock-up expiries surfaced).

## 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

Layer-1 population rail (mechanical, a cost bound — never a significance claim): US-listed, market cap ≥ $2B, ≥2% close-to-close (2026-07-31 → 2026-08-03), attributable to an identifiable public event. Layer-2 judgment decides what is written up. `legacy_rule_pass` = the retired ≥5% bar, computed mechanically, **record-only**.

**Screen integrity caveat, stated up front:** FMP's `quote` (batch), `news`, and `chart` endpoints were **ACCESS DENIED** on this account's plan tier for the whole session. The screen was assembled from FMP `marketPerformance` gainer/loser/most-active lists (which skew heavily to sub-$2B micro-caps and leveraged single-stock ETFs, all excluded), per-symbol `company` profiles for the market-cap filter, IBKR snapshots for held names, and web attribution. **This is a sampled screen, not a certified-exhaustive large-cap sweep** — do not read `surfaced_count` as a complete census of the ≥2% cohort.

| Ticker | Move | Event | Conv. | Reason | legacy_rule_pass | below_spec_floor |
|---|---|---|---|---|---|---|
| ATKR | **+28.1%** ($72.96→$93.48) | Prysmian to acquire at $95/sh cash, ~$3.8B EV, ~30% premium; same-day Q3 beat | 75 | A definitive all-cash takeout is the cleanest event class there is and is terminal for the name | true | false |
| CRWV | **+19.5%** | AI-cloud demand read-through from MSFT/AMZN prints; Truist upgrade to Buy | 60 | Largest move in the AI-infra complex and the clearest read on how the tape is repricing that theme | true | false |
| SRAD | **−15.1%** | Q2 revenue miss + lowered FY guidance | 60 | A clean, name-specific guide-cut event — the only genuine down-side B-population hit today | true | false |
| GME | **−12.2%** | $1.4B convertible-note-for-equity swap; dilution | 45 | Real and name-specific, but a structural dilution overhang rather than a mispricing | true | false |
| ONDS | **+11.7%** | $875.8M DZYNE acquisition; FY26 revenue guide hiked to $525M | 45 | Genuine corporate action, but a ~$4.8B cap with a history of promotional guidance | true | false |
| TGTX | **−11.3%** | Q2: revenue beat, EPS badly missed on R&D ramp | 45 | Mixed-signal print — the sign of the news is genuinely ambiguous | true | false |
| SOFI | **+10.5%** | Q2: revenue +40.5% YoY, EPS beat, FY26 outlook raised | 45 | Strong clean beat, but a positive-direction print into an already-recovered name | true | false |
| AZN | **~−9%** | Reported AstraZeneca/Bristol Myers combination talks (FT-sourced) | 60 | Mega-cap pharma M&A speculation, cross-sectionally confirmed by BMY moving the opposite way | true | false |
| BMY | **~+6%** | Same (target leg) | 60 | The cross-sectional confirmation leg — both legs moving correctly is what makes the report credible | true | false |
| IREN | **+8.0%** | 2026 revenue target raised to $4B on AI-infra demand | 45 | Real guidance raise, same AI-infra beta as CRWV | true | false |
| SNAP | **+7.7%** (+~16% incl. AH) | Q2 beat; loss-to-profit swing, revenue +18.9% YoY | 60 | A genuine surprise (consensus was a loss) at a $8.5B cap — the largest true earnings surprise on the tape | true | false |
| **ISRG** | **+6.25%** ($353.33→$375.42, vol 3.50M vs 3.00M avg) | **No discrete new public event.** Re-rating on a revisited growth story after the post-print selloff; management's reaffirmed FY26 da Vinci procedure-growth range | 60 | A 6.25% move on a $134B mega-cap with *no news* is itself the signal — and this name is **held in two of our strategies** | true | false |
| ORCL | **+9.3%** ($129.87→$141.90) | AI-cloud sympathy following MSFT/AMZN results | 45 | Large, but sympathy beta with no name-specific event — and ORCL sits on the A queue | true | false |
| AAL | **+5.0%** | Airline complex bid on the fuel-cost outlook as crude fell | 45 | A clean, mechanical read-through of the day's oil move, not name-specific news | true | false |
| MSFT | **+4.9%** | Q4 FY26: EPS/revenue beat, Azure >$100B ARR growing 43% | 60 | The largest market cap in the move set and the proximate driver of the whole tech complex today | false | **true** |
| AMZN | **+4.6%** | Q2 beat, AWS +37% YoY (fastest in 18 quarters); crossed $3T, record high | 60 | Second-largest driver of the tape; directly reinforces a **held D thesis** | false | **true** |
| GOOGL | **+4.34%** (vol 39.0M) | Reports of TPU v9 AI-chip capacity expansion | 45 | Led the day's best sector; directly relevant to a **held D thesis** | false | **true** |
| NVDA | **+2.9%** | AI-infra spend confidence revival post-MSFT/AMZN | 30 | Pure complex beta with no name-specific event; on the A queue | false | **true** |
| PLTR | **+2.1%** regular (+7.35% AH) | Q2 beat; FY26 revenue guide raised to $8.150–8.158B | 45 | Substantial print, but the regular-session close-to-close is what the rail measures | false | **true** |

**Surfaced: 19. Rejected as noise despite clearing the legacy ≥5% bar: none** — every ≥5% name located had an identifiable driver worth recording. **Agreement: both 14, ai_only 5, rule_only 0.**

**Moved but driver not identified: none** in the sampled set.

## 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

Layer-1 rail: any GICS sector ≥1% at sector-ETF level, or notable dispersion. Percentages are IBKR sector-ETF close-to-close (primary source); a Yahoo cap-weighted dashboard corroborated every sign.

| Sector (ETF) | Move | Driver | Conv. | legacy_rule_pass (≥2%) |
|---|---|---|---|---|
| **Energy (XLE)** | **−1.21%** | Crude −4.5/6% as the Iran war premium unwound a second session | **75** | false |
| Comm. Services (XLC) | **+2.82%** | GOOGL +4.34% on TPU v9 capacity reports; continued META strength | 60 | **true** |
| **Utilities (XLU) — dispersion** | **−0.14%** (ETF) vs ~+2.06% equal-weighted | Mega-cap defensives sold while small-cap utilities rallied; press reports XLU on its longest losing streak of 2026 | 60 | false *(dispersion-only surfacing — `false` by convention, never NULL; `metric_pct` is the raw ETF close-to-close)* |
| Technology (XLK) | **+1.91%** | MSFT +4.9%, NVDA +2.9% | 45 | false |
| Cons. Discretionary (XLY) | **+1.83%** | AMZN crossing $3T on AWS margins/EPS | 45 | false |
| Industrials (XLI) | **+1.70%** | Broad cyclical bid on the de-escalation | 45 | false |
| Materials (XLB) | **+1.29%** | Beta participation; no distinct driver isolated | 30 | false |

**Why Energy outranks Communication Services despite being less than half its magnitude** — this is precisely the judgment Layer 2 exists to make. XLC's +2.82% is two mega-caps having a good day inside a +1.47% tape; it tells us almost nothing we did not already know. XLE's −1.21% is the **only** sector that fell, and it is the direct, mechanical price readout of the single macro variable — the Hormuz risk premium — that currently sets `shock_overlay`, drives `inflation_trend`, and anchors the park call below. A small move in the one instrument that is actually carrying information outranks a large move in six instruments carrying beta.

**Surfaced: 7. Rejected despite clearing the legacy ≥2% bar: none. Agreement: both 1, ai_only 6, rule_only 0.**

**Two data-integrity notes, recorded so they are not re-derived later.** (i) FMP's sector-average endpoint appears to be **NASDAQ-listed-only**: it flips the sign on Energy (+0.55% vs the ETF's −1.21%) and Materials (−0.12% vs +1.29%) because XOM/CVX and LIN are excluded. Those two FMP sector numbers are unreliable and were not used. (ii) A Yahoo "Stock Market News" article carried sector figures (XLK +5.5%, XLC −2.7%, XLP −2.2%) contradicting **every** other source checked; excluded as unreliable.

## 5. Notable commentary

**NY Fed President John Williams (Reuters interview, today)** — the most relevant Fed voice inside the window. He called policy **"well positioned"** and supported last week's hold at 3.50–3.75%, but was explicit that hikes remain live: *"if the economy is not on a trajectory that will bring inflation back down to 2% … it would absolutely be appropriate to act to get us on a trajectory that does."* He expects inflation to fall in H2 2026 and reach 2% by 2028 (June PCE 3.7% YoY). Directly on today's main story, he said he does **not** expect the Iran conflict to keep pushing inflation higher, and that resolution plus reopened shipping lanes "could allow conditions to improve rapidly" (Quartz; NY Fed Teller Window).

**Cboe Macro Volatility Digest (today)** — flags **bond** volatility as the standout: the 30Y is near a 20-year high after the hawkish hold, and **TLT put skew is at post-GFC highs**, i.e. positioning for further yield rises. This is the strongest single piece of evidence against taking duration anywhere in the park menu, and it is used as such below.

**Standard Chartered Daily Navigator (3 Aug)** — USD "consolidates as geopolitical risks ease"; **downgraded gold to a "core holding"** on the fading risk premium against an uncertain Fed path.

**Amazon CEO Andy Jassy** on AWS: growth of "36.7% year-over-year in Q2 — our fastest growth in 18 quarters." Directly relevant to a held D thesis (below).

*Not in window, recorded so it is not mistaken for fresh:* quotes from Logan, Hammack and Kashkari circulating in a 3-Aug sell-side note refer to the **July 29** FOMC, not to Monday remarks.

---

# ANALYSIS — RISK TO EXISTING POSITIONS

## Mechanical exit-trigger sweep

Swept the **UNION** of `state.current_positions` (17 rows) and live `get_account_positions`. Live marks are IBKR, ~22:15Z.

**Union reconciliation — three registry-vs-broker divergences, all resolved against the broker per "the registry is not the broker":**

| Name | Registry says | Broker says | Resolution |
|---|---|---|---|
| **MDT** | `EXIT_PENDING`, 0.4852 sh | **position 0**, `daily_pnl` +0.2115 | The staged time-exit SELL (`exit-MDT-timeexit-20260803`, instruction 100) **FILLED today.** MDT is closed. No exit action is owed. |
| **MTZ** | provisional OPEN, cost_basis 149.99 (staging estimate) | 0.5628 sh @ avg **258.699** | Entry **FILLED at the open.** Real cost basis ≈ $145.60, not $149.99. |
| **GEV** | provisional OPEN, cost_basis 123.92 (staging estimate) | 0.1244 sh @ avg **969.906** | Entry **FILLED.** Real cost basis ≈ $120.66, not $123.92 (the 996.175 staging reference was $26 high). |

All three are **normal, expected intermediate registry states awaiting D2a Step-0 reconciliation — not errors, and not a reconciliation lag.** No `position_reconciliation_lag` alert is raised: the lag category is defined as a position present in the connector but **absent** from `state.current_positions`, and there is no such position today. MTZ and GEV are both present, with their convergence/time-exit fields already populated, so neither was exempt from this sweep.

**Mechanical triggers, all 17 positions:**

| Position | Live mark | Convergence target | Time exit | Verdict |
|---|---|---|---|---|
| B:FTV:2026-07-29 | 59.46 | 61 — **not hit** | 2026-09-28 — not due | no mechanical trigger |
| B:ISRG:2026-07-21 | 375.42 | 400 — **not hit** | 2026-09-18 — not due | no mechanical trigger |
| B:MSCI:2026-07-27 | 574.43 | 615 — **not hit** | 2026-09-25 — not due | no mechanical trigger |
| B:MTZ:2026-08-03 | 261.01 | 278 — **not hit** | 2026-10-02 — not due | no *mechanical* trigger — see thesis invalidation below |
| B:MDT:2026-06-17 | — | 90 — never reached | 2026-07-31 | **already actioned; SELL filled today** |
| D × 12 tranches | — | none (NULL) | none (NULL) | Strategy D carries no mechanical exits by design |

**No mechanical exit triggers fired today.**

## Per-strategy kill-trigger sweep

`perf.kill_flags` as of 2026-07-31 (D1 runs before D2, so the engine row is yesterday's close), **with `current_drawdown` refreshed unconditionally against today's live marks** as required — no judgment predicate on whether to refresh:

| Strategy | Engine deployed / peak unit value | Engine drawdown | Live-mark refresh | Drawdown kill (≥50%) | Runaway (2×, pre-gate) | interim_underperf |
|---|---|---|---|---|---|---|
| B | 1.128732 / 1.144091 | −1.34% | Open B book (ex-MDT) marks **+1.31%** vs cost ($347.79 MV vs $343.28 cost); today's B `daily_pnl` is **positive** on all four names, so the refresh moves the unit value **up** and the drawdown **in** | **NO** (−1.34% vs −50%) | **NO** (1.129 vs 2.0 required; 8 closed trades, gate not reached) | FALSE (67 days deployed, <90) |
| D | 1.049893 / 1.049893 | 0.00% | Open D book marks **+5.87%** vs cost ($564.50 MV vs $533.18 cost); at its peak, so no drawdown to refresh | **NO** | **NO** (1.050 vs 2.0; 0 closed trades) | FALSE (67 days deployed, <90) |

**No kill or review trigger fires.** No `interim_underperf_warning` alert is raised and none is open to heal — both strategies are 23 days short of the 90-day floor that flag requires. A, C and E hold no deployed capital and have no `kill_flags` row.

**B open-book pairwise correlation (KL #12 control).** `analytics.b_pairwise_correlation`, computed 22:15:27Z: `n_positions = 5`, `n_pairs = 6`, **`avg_offdiagonal_corr = NULL`, `min_overlap_days = NULL`.** The alert condition (`avg > 0.5 AND n_positions >= 2 AND min_overlap_days >= 40`) **fails on the NULLs and no alert is raised** — correctly, and for a substantive reason rather than a data gap: every B position was opened between 2026-06-17 and today, so **no pair has the ≥40 trading days of overlap the view requires to qualify.** The control is genuinely inert until the book ages, not broken.

## Judgment-laden thesis-invalidation checks

### MTZ (Strategy B) — **EXIT TRIGGERED. Invalidation criterion 3 MET.**

The position's immutable criterion 3, recorded at entry this morning: *"bear-cluster forms — any second or subsequent covering analyst cuts PT by ≥15% within the 60-day window."*

An upstream W3 alert (18:05Z) asserted this criterion was met, naming three firms. **That assertion was independently re-verified from primary vendor sources this run rather than inherited** — per the standing rule that free text in an operational field is a report of a prior session's belief, not an instruction. The verification **confirms the criterion and finds the upstream count understated**:

| Firm | Old PT | New PT | Change | Date | Rating action |
|---|---|---|---|---|---|
| Morgan Stanley | $549 | $369 | **−32.79%** | **2026-07-31** | maintains Overweight |
| KeyBanc | $500 | $371 | **−25.80%** | 2026-08-03 | maintains Overweight |
| Baird | $475 | $363 | **−23.58%** | 2026-08-03 | maintains Outperform |
| Truist | $550 | $428 | **−22.18%** | 2026-08-03 | maintains Buy |
| Citigroup | $483 | $408 | **−15.53%** | 2026-08-03 | maintains Buy |
| *(TD Cowen)* | *$470* | *$420* | *−10.64% — below the 15% bar, excluded* | *2026-08-03* | *maintains Buy* |

**BEAR-CLUSTER CRITERION: CONFIRMED, n = 5** distinct covering analysts cutting ≥15% inside the window — four of them today, and **one (Morgan Stanley, −32.79%) dated 2026-07-31, i.e. already in existence when the entry was staged this morning.** Criterion 3 requires a *"second or subsequent"* cut, so the four same-day cuts each independently satisfy it.

*Underlying cause:* MasTec reported Q2 before the open on **Thursday 2026-07-30** — revenue $4.374B (+23.4% YoY, a beat), adj. EPS $2.22 (+49% YoY), FY26 guidance raised, record 18-month backlog $21.391B (+30% YoY). But on the call CEO José Mas confirmed *"we took out $400 million of revenue in comms,"* cutting FY26 Communications revenue guidance to ~$3.25B on carrier wireless-spectrum delays and RDOF wireline deferrals. The stock fell ~19% on **Friday 2026-07-31** (close $263.10). The B entry was staged into that post-event window this morning and filled at $258.08; MTZ then closed **$261.01, −0.79%** on the day, on 4.49M shares (~1.9× average).

**Note the exact shape of what happened, because it is the finding, not a footnote: the position's own criterion 4 ("segment overhang worsens") and criterion 3 (bear-cluster) both describe the mechanism that was *already fully visible in public sources at staging time*. The bear cluster did not form after entry — one leg of it pre-dated entry by a session, and the rest landed the same morning.** This is textbook **Pattern N** (negative-direction, information-confirmed-by-cross-section, sell-side bear-cluster / "SP1-inversion") and **SP4** (structural-overhang-persistence: a segment overhang requiring multi-quarter resolution outside the 60-day window). The entry thesis rated it MEDIUM 56%. The position is currently ~+1.1% on the fill, so **there is no loss pressure distorting this call in either direction.**

**Verdict: EXIT. Full flatten of 0.5628 sh, Strategy B, on invalidation criterion 3.** This is not a new finding — W4 reached the same conclusion today (`events.decision_log` 0c561001) and could not craft, because `state.trading_enabled` is FALSE. D1 re-derives it independently and routes it again so the exit is not lost between routines.

### FTV (Strategy B) — invalidation criterion 3: **NOT met, but a genuinely close call that has been sitting unadjudicated for three sessions.**

This one deserves more space than its $98 notional suggests, because it was flagged once and then dropped. FTV's immutable criterion 3: *"a **confirmed** close below the post-event trough ($58.22 intraday / $59.54 close) on a SUBSEQUENT session with above-average volume."*

Measured daily bars (IBKR), with the 21-session pre-event average volume computed at **1,132,283**:

| Date | Close | vs $59.54 trough close | Volume | vs avg |
|---|---|---|---|---|
| 2026-07-29 (event/trough) | 59.54 | — (the reference) | 4,167,273 | 3.68× |
| 2026-07-30 | **58.48** | **−1.8% below** | 2,544,835 | **2.25×** |
| 2026-07-31 | **59.21** | −0.6% below | 1,569,588 | 1.39× |
| 2026-08-03 | **59.46** | −0.13% below | 1,354,382 | 1.20× |

D2a flagged the 07-30 bar as a factual observation on 2026-07-30 and explicitly deferred adjudication to D2/W3 (correctly — D2a carries no analysis). **No routine appears to have picked it up since.** Adjudicating it now:

Two defensible readings exist and they disagree. On the **literal** reading — a close below the trough *close* of $59.54, on a subsequent session, with above-average volume — 2026-07-30 satisfies all three conditions squarely, and the criterion is MET. On the reading that gives the word **"confirmed"** independent work, it is not: this system's criteria repeatedly and deliberately build in anti-noise confirmation requirements (the DIS criteria state their two-consecutive-quarter framing exists precisely to stop single-period lumpiness from auto-invalidating), and the single breaching close was **immediately and monotonically reversed** — 58.48 → 59.21 → 59.46, two consecutive higher closes, with today posting a higher low (59.13) than any session since the event. On the stricter intraday-trough reading ($58.22), no close has ever been below it.

**I adopt the second reading: criterion 3 is NOT met, because "confirmed" is not surplusage and a one-session breach reversed over the next two sessions is the definition of unconfirmed.** Recording the reasoning explicitly so that a future session inherits the judgment rather than re-litigating it, and so that the opposite reading is visible and can be overturned on better argument.

**The bright line, stated now so it is mechanical next time: a close below $58.48 on above-average volume confirms the breach and triggers the exit.** Also worth flagging as context rather than as a trigger: FTV finished **−0.13% below its post-event trough close on a day the tape rose 1.47%**, which is real relative weakness even though it is not an invalidation.

### All other open positions — no invalidation

- **D:AMZN (2 tranches)** — today's print **reinforces** every metric criterion: AWS +37% YoY against an invalidation floor of <18% for two consecutive quarters; op-margin and backlog criteria untouched. UNBREACHED.
- **D:GOOGL (2 tranches)** — +4.34% on TPU v9 capacity reports; the criteria are Cloud revenue/margin/RPO metrics on a quarterly cadence, none of which today's news bears on adversely. UNBREACHED.
- **D:ISRG / B:ISRG** — +6.25% with management reaffirming the FY26 da Vinci procedure-growth range; the D criteria are procedure growth and placements, both reinforced. UNBREACHED. The B tranche's convergence target (400) is not hit.
- **D:TSM (2 tranches)**, **D:CRM**, **D:RTX**, **D:UBER**, **D:GEV** — no development in window bears on their criteria. UNBREACHED.
- **D:DIS** — the largest drawdown in the book at **−11.8%** (mark 98.15 vs cost 111.32). No DIS-specific development inside the window. Its criteria are all quarterly-reported metrics (SVOD operating margin, FY26 EPS guide, buyback pace) with nothing observable to test until the fiscal-Q3 print. UNBREACHED **on available evidence**, with the honest caveat that its mirrored `invalidation_status` carries `breach_status: "NOT_ASSESSED_BY_THIS_BACKFILL"` — the criteria are recorded, but no routine has affirmatively assessed them since the 2026-07-30 backfill.
- **B:MSCI** — 574.43, comfortably above the 550.79 post-event trough named in its criterion 2; no downgrade (criterion 1) and no opex-guidance escalation (criterion 3) found. UNBREACHED.

## Watchlist candidates — effect of today's developments

**Strategy A queue (33 rows in BigQuery; Watchlist.md carries 38 — a documented 6-row drift that is W5's mandate, not this run's).** The A router is **DO-NOT-ACTIVATE pending div-A-202607-1**, so nothing on this queue is actionable today regardless. Materially moved today: **ORCL +9.3%**, **NVDA +2.9%**, plus AMD, AVGO, MU, SNOW, INTU, META and CRM all participating in the AI-complex rally. **No candidacy status changes** — a broad sympathy rally moves the entry price without touching any of these names' catalyst theses. **META and INTU were added to the queue earlier today** by an upstream routine (INTU on a confirmed 2026-09-17 Investor Day); both are inherited here, not new findings of this run.

**Strategy B tracking rows** (SHOP, PYPL, CDW, MGM, NVO): unchanged, no development in window.

---

# ANALYSIS — OPPORTUNITY CHECK

Scope is the roster-active strategies with `review_cadence: reactive` in `strategy/roster.yaml` — **A, B, C, E** (D is `long_horizon` and excluded here by design).

**Router context that bounds everything below.** M4 ran today and queued a **whole-roster divergence — all five of A/B/C/D/E** (first in the recorded lineage), attacker due 2026-08-04, orchestrator 2026-08-05. Operative states pending those reviews: **A DO-NOT-ACTIVATE**, **B ACTIVATE** (M4's raw call was to flip to DO-NOT-ACTIVATE via the universal `shock_overlay = acute` override; because the flip arrived divergence-attached, the prior ACTIVATE remains operative), **C HYBRID ACTIVATE (FOMC-only)**, **E ACTIVATE (substantive) + execution-feasibility-deferred**.

**Strategy B candidates.** The spec-floor rail is hard: a name is routable only if it also meets B's frozen entry criterion 1 (**≥5% close-to-close on event day**). Every `below_spec_floor` name in §3 — MSFT, AMZN, GOOGL, NVDA, PLTR — is therefore **context and SL1 ideation evidence only and is not routed**, however significant.

Two names clear the floor mechanically and are surfaced as candidates. **Both are surfaced with an explicit prior, because D1's job is to flag, not to pre-empt the thesis session — and equally, not to pad:**

1. **SRAD (Sportradar, ~$3.65B) — −15.1% on a Q2 revenue miss plus lowered FY guidance.** Clears criterion 1 and the 10-day window. **Prior: likely NO-GO at criterion 4.** A lowered forward guide is the canonical *information*-driven reaction, and it maps onto **SP4 (structural-overhang / guide-cut)** and **Pattern N**. Note the base rate this run is looking at: five B theses were constructed today (RDDT, VCYT, ALHC, BTSG, MTZ) and four went NO-GO at criterion 4 on exactly this distinction.
2. **TGTX (TG Therapeutics, ~$7.07B) — −11.3%, revenue beat but EPS badly missed on an R&D ramp.** Clears criterion 1 and the window. **Prior: SP9 (mixed-signal / split sell-side).** The sign of the event is genuinely ambiguous, which is the one fact pattern where an over-reaction case is at least arguable rather than foreclosed — that is why it is surfaced rather than declined here.

**Explicitly not routed as B candidates, with reasons** (recorded so the same names are not re-surfaced tomorrow): **ATKR** — a definitive all-cash takeout, terminal, no convergence mechanism (SP5). **AZN/BMY** — M&A speculation is an in-window binary catalyst (SP5). **ORCL, NVDA, AAL, CRWV, IREN** — sector/complex sympathy with no *name-specific* public event, so criterion 1 is not met on its own terms regardless of move size. **GME** — a dilution overhang requiring structural resolution (SP4e). **SOFI, SNAP** — positive-direction clean beats sitting in SP1/SP3 territory (bull-ratification / already-priced). **ISRG** — a 6.25% move with **no discrete event day at all**, so criterion 1 cannot be satisfied; and a B position is already open in the name.

**Strategy A: none.** Router is DO-NOT-ACTIVATE, and no development created a new 6-month catalyst.

**Strategy C: none new.** Router is HYBRID ACTIVATE (FOMC-only); W4 already enqueued the **2026-09-16 FOMC** for thesis construction today. No PDUFA resolved today and none entered the 45-day qualifying window from today's developments.

**Strategy E: none.** No sector-level divergence today opened an intra-industry-group pair. The day was a broad beta rally in which ten of eleven sectors rose together — the *opposite* of the dispersion E feeds on. The single genuine dispersion item (utilities cap- vs equal-weighted) sits *within* one sector rather than between two names in one 6-digit GICS group, and no pair identified meets criterion 3's trailing-252-day correlation ≥0.5 test.

---

# ANALYSIS — ADD-CANDIDATE CHECK

Strategies **A, B, D only**. 17 open positions evaluated. **0 flagged. 3 declined at the HARD GATE.**

| Position | Mark vs cost | Evaluable? | Disposition | Reason |
|---|---|---|---|---|
| B:MTZ:2026-08-03 | +1.1% | yes | **declined_hard_gate** | Invalidation criterion 3 is **breached** (bear-cluster, n=5). Per the gate, this is not an add — it is an exit; routed to RISK above. |
| B:MDT:2026-06-17 | closed | **no** (`invalidation_status` NULL) | **declined_hard_gate** | No criteria recorded, so "unbreached" cannot be affirmatively confirmed. Separately: the position is flat at the broker as of today. |
| B:ISRG:2026-07-21 | +6.5% | **no** (`NOT_DISCRETELY_RECORDED_AT_ENTRY`) | **declined_hard_gate** | The honest marker written by bigquery/117: this entry recorded no discrete invalidation criteria, exiting mechanically instead. Structurally ineligible for adds for its whole life. |
| B:FTV:2026-07-29 | −0.36% | yes | declined | A dip, and the thesis is intact — but criterion 3 sits one confirming close away from breach (above). Adding into that is adding into invalidation territory. |
| B:MSCI:2026-07-27 | −0.84% | yes | declined | Ordinary adverse mark with no news; too shallow and too early (entered 5 sessions ago) to constitute a dip worth a second tranche. |
| D:AMZN:2026-07-09 | +16.4% | yes | declined | Conviction genuinely strengthened by AWS +37% — but **the 07-30 add already acted on this exact print.** No new information since; adding again 6.4% above that fill is chasing, not conviction. |
| D:AMZN:2026-07-30 | +5.7% | yes | declined | Same catalyst, same reasoning; second tranche is 3 sessions old. |
| D:GOOGL:2026-07-09 | +3.2% | yes | declined | Today's TPU-capacity move is AI-complex beta, not new *Cloud-metric* information, and Cloud metrics are what the criteria measure. |
| D:GOOGL:2026-07-26 | +13.3% | yes | declined | Same; second tranche added 6 sessions ago. |
| D:ISRG:2026-07-20 | +7.3% | yes | declined | +6.25% today on **no discrete news** — a re-rating, not new evidence for the procedure-growth thesis. Adding on a no-news gap-up is momentum, not conviction. |
| D:TSM:2026-07-21 | −4.6% | yes | declined | A real dip against an intact thesis, but the 07-29 add already took the second tranche and nothing new has arrived since. |
| D:TSM:2026-07-29 | +3.9% | yes | declined | Same. |
| D:CRM:2026-07-09 | +16.4% | yes | declined | No development in window; nothing to act on. |
| D:RTX:2026-04-27 | +22.5% | yes | declined | Best performer in the book. No new information; an add here would be pure momentum. |
| D:UBER:2026-07-09 | −2.1% | yes | declined | Shallow dip, no news, no thesis development. |
| D:DIS:2026-05-07 | **−11.8%** | yes | declined | The clearest *dip* in the book, and the thesis is not invalidated — **but** its criteria carry `breach_status: NOT_ASSESSED_BY_THIS_BACKFILL` and are all quarterly metrics untestable until the fiscal-Q3 print. Adding to the book's worst position on criteria no routine has affirmatively assessed is exactly the trade the hard gate exists to slow down. **The right next step is an assessment, not a tranche.** |
| D:GEV:2026-08-03 | +4.0% | yes | declined | Entered today, already at a **+4.0% mark** — and its thesis carries an open criterion-2 PROVISIONAL flag (the 8-quarter transcript floor was unverifiable on the current data plan). Nothing to add to. |

**The pattern worth naming across the declines:** seven separate D tranches (AMZN ×2, GOOGL ×2, TSM ×2, ISRG) present a superficially attractive add case today, and every one fails on the same test — *the "new" information is either the same catalyst a prior tranche already acted on, or it is complex-wide beta rather than evidence bearing on that thesis's own metrics.* A day when the whole tape rises 1.47% generates the *appearance* of strengthened conviction across an entire book at once, which is close to a definition of what the strengthened-conviction trigger must not fire on.

---

# ANALYSIS — REGIME CHECK

**No inter-monthly router review is recommended.** High bar, default NO — and here the bar is not met for two reinforcing reasons.

First, **five router reviews are already in flight.** M4 today queued `div-A/B/C/D/E-202607-1` — the entire roster, the first whole-roster divergence in the recorded lineage — with the attacker due 2026-08-04 and the orchestrator 2026-08-05. Requesting a sixth review of the same question, one day before the answers land, would be duplicative work, not diligence.

Second, today's technical developments **reinforce** rather than challenge the technical plane as re-measured on 2026-07-31: SPY_TREND UP (and today's +1.47% widens the margin over the 50dma decisively), VIX_REGIME NORMAL at 15.86, EQUITY_BREADTH HEALTHY, SUSTAINED_INVERSION NOT-SUSTAINED. Nothing flipped.

**But one item is material evidence for the reviews already in flight, and is recorded here so it reaches them rather than dying in a file that is overwritten tomorrow: today's ISM Manufacturing PMI at 55.6 — vs 54.0 consensus, 53.3 prior, the highest since May 2022 — cuts directly against the `growth_momentum = decelerating` score.** That score was written on 2026-08-01 off June payrolls (+57k vs ~110k consensus, with 74k of downward revisions) and the Q2 GDP advance (+1.5% SAAR). It is a defensible read of backward-looking data, and `growth_momentum` feeds the fundamental leg of both the B and D router calls now under review. The evidence is genuinely two-sided and this run does not assert the score is wrong: **S&P Global's competing final July manufacturing PMI printed 53.9, flat month-over-month, and diverges sharply from ISM's jump.** One survey jumped, one did not move. That disagreement is itself the finding, and it belongs in front of the divergence reviewers.

---

# PARK ALLOCATION CALL

**Current policy:** SGOV, effective 2026-07-26. **Live park book: 87.1736 sh SGOV = $8,754.41, or 92.5% of the $9,469.52 net liquidation value.** This is not a marginal sleeve — the park *is* the portfolio (deployed strategy positions total ~$912 of market value).

**Evidence gathered fresh this session:** VIX 15.86 close (−0.81%; range 15.54–16.30; 50d avg **17.38**, 200d avg **18.70**) — FMP `^VIX`, cross-checked exactly against the IBKR CBOE daily bar. VOO 696.96 (+1.50%), day range 688.61–697.31, IBKR live. S&P 500 7,599.97 (+1.47%), ~0.1% off record; Dow at a record close; Russell 2000 +1.73%. `state.park_signal_daily` at 2026-07-31: spy_close 747.03, spy_50dma 744.99, spy_200dma 700.39, spy_trend **UP**, `dd_from_252d_high` −1.65% (today's +1.47% takes that to roughly flat). `hy_oas` **2.84** (FRED, July). `state.current_regime` FUNDAMENTAL_AXIS: `shock_overlay` **acute**, `policy_stance` **hawkish**, `growth_momentum` decelerating, `inflation_trend` stable, `risk_sentiment` neutral; integrative *"stagflationary shock + hawkish policy."* Curve: 2Y 4.25%, 10Y 4.70%, 30Y 5.23%, all lower on the day. Plus today's DEVELOPMENTS in full.

- **`vehicle`: VOO** *(SWITCH from SGOV)*
- **`conviction`: MEDIUM — `conviction_pct` 60**
- **`direction`: re-risk**
- **`status`: BOUND**

**`rationale`.** The 2026-07-26 de-risk into SGOV named its own conditions explicitly: the park was ~96% of NLV in tier-4 VOO into an FOMC and a Mag-7 print week, with SPY closed below its 50dma on both 7/23 and 7/24 and VIX at 18.58, above its 50-day average. **Every one of those conditions has now reversed or passed.** SPY is above its 50dma with today's move widening the gap decisively; VIX at 15.86 is below both its 50d (17.38) and 200d (18.70) averages; the FOMC is behind us, and the Mag-7 prints are behind us and were, on balance, strong (Azure >$100B ARR growing 43%, AWS +37%). Breadth is healthy and small caps led today, so this is not a narrow mega-cap tape. Credit is firm. Holding SGOV from here would mean holding on a rationale whose stated premises no longer hold, which requires a *new* argument — and the only new argument available is the acute shock overlay, which the market is currently pricing at VIX 15.86 while making record highs. **Why VOO beats the runner-up:** the runner-up is not a middle rung, it is SGOV itself, because every intermediate menu instrument is a duration bet and duration is the one leg that is unambiguously unfavourable — the 30Y at 5.23% is within 4bp of a 19-year high, Cboe reports TLT put skew at post-GFC highs, ~66% odds of a September hike are priced, and Treasury raised its Q3 borrowing estimate by $68B today. That rules out GOVT, IEF, MUB, LQD and TLT on their own terms, and AOR through its ~40% bond sleeve; HYG and PFF add credit and rate risk to buy only a fraction of equity upside. The menu therefore collapses to a genuine binary — tier-0 or tier-4 — and on a binary the equity evidence is now one-sided while SGOV's remaining case rests on a single geopolitical tail.

**`invalidation`.** Any of: a resumption of kinetic US–Iran action (a strike executed, or Hormuz transit volumes falling again) or Brent back above ~$95; SPY closing back below its 50-day average; VIX closing back above its 50-day average (~17.4); or the 30Y breaking decisively above ~5.35% on a hawkish repricing.

**`theater_check`.** The honest test is the symmetric one: *if the park were already VOO, would today's evidence make me switch to SGOV?* Clearly not — VIX below both moving averages, SPY above its 50dma, a record Dow, tight credit and falling oil is not a de-risking tape. Since this call would not *open* the SGOV position today, holding it today is status-quo bias rather than analysis. Two further checks against narrating a foregone conclusion, both cutting *toward* this call rather than away: W5's park scorecard, written today, reports the AI allocator **trailing all three benchmarks including the shadow rule table**, with the VOO→SGOV switch as the one vehicle change since the watermark — i.e. the de-risk has cost money, exactly the kind of evidence a default-KEEP ratchet quietly ignores; and `PARK_ROUTER_DESIGN.md` §1, written well before this decision, offers its own worked example — *"Today's tape (VIX ~15.7, market near highs, shock latent-but-building): the AI would very likely call VOO"* — a near-exact description of today's tape and an independent, pre-registered anchor. **And the argument against, stated plainly rather than buried: this call overrides a same-day `shock_overlay = acute` score that M1a wrote at 11:12Z today with Iran's denial already in hand, and M4 used that same acute reading today to argue for deactivating Strategy B. That is a real internal tension, it is why this binds at MEDIUM 60 and not higher, and it is why the invalidation list leads with the re-escalation trigger.**

---

# RECOMMENDED ACTIONS

- **EXIT — MTZ, Strategy B.** Full flatten of 0.5628 sh on **thesis-invalidation criterion 3 (bear-cluster)**, independently confirmed this run at **n = 5** distinct covering analysts cutting price targets ≥15% inside the 60-day window (Morgan Stanley −32.79% on 07-31; KeyBanc −25.80%, Baird −23.58%, Truist −22.18%, Citigroup −15.53%, all on 08-03). The convergence target (278) was not reached and the time exit (2026-10-02) is not due — this is a judgment exit on the position's own immutable criterion, not a mechanical one. W4 confirmed the same exit today and was blocked by the trading-enable halt; this re-routes it.
- **NEW ENTRY CANDIDATE — SRAD, Strategy B.** −15.1% close-to-close on a Q2 revenue miss plus a lowered FY guide; clears frozen entry criterion 1 (≥5%) and the 10-day window. Requires full thesis construction in a separate session per Strategy.md. **Carry forward into that session:** the prior is a likely NO-GO at criterion 4 (guide cuts are information-driven), with SP4 and Pattern N both in play.
- **NEW ENTRY CANDIDATE — TGTX, Strategy B.** −11.3% close-to-close on a revenue beat with a large EPS miss on R&D ramp; clears criterion 1 and the window. Requires full thesis construction in a separate session per Strategy.md. **Carry forward:** SP9 (mixed-signal / split sell-side) — the event's sign is genuinely ambiguous, which is the fact pattern where an over-reaction case is arguable rather than foreclosed.

**Deliberately not emitted as action bullets, recorded here so the omissions are explicit rather than silent:**
- **FTV** — the criterion-3 adjudication above is a live-position monitoring finding, not an exit, an add, or a watchlist change; none of the five action types fits it, and forcing it into `watchlist` would invite D2 to edit `Watchlist.md` for an open position. The finding, the reasoning, and the mechanical bright line (**a close below $58.48 on above-average volume confirms the breach and triggers the exit**) live in the RISK section above and in the durable `add-candidate-review` decision-log row written this run.
- **The park call** is carried by `state.park_allocation_latest` and D2's PARK ALLOCATION CONVERSION step, not by this list.
- **Blocking condition, for D2's awareness, not an action:** `state.trading_enabled` is **FALSE** (`halt_reason`: *"state.freshness marks_fresh/engine_fresh not both TRUE"*), while `state.trading_enabled_mechanical` is TRUE. D2a's own marks/engine ingest is what clears this; the MTZ exit and the park switch both depend on it.

```yaml d1_actions
- action: exit
  ticker: MTZ
  strategy: B
  detail: Thesis-invalidation criterion 3 (bear-cluster) MET — n=5 covering analysts cut PT >=15% within the 60-day window (MS -32.79% 07-31; KeyBanc -25.80%, Baird -23.58%, Truist -22.18%, Citi -15.53%, all 08-03). Full flatten 0.5628 sh. Convergence target 278 not reached and time exit 2026-10-02 not due — judgment exit, not mechanical.
- action: thesis
  ticker: SRAD
  strategy: B
  detail: -15.1% close-to-close on Q2 revenue miss plus lowered FY guidance; clears frozen entry criterion 1 (>=5%) and the 10-day window. Full thesis construction required in a separate session; prior is likely NO-GO at criterion 4 with SP4 / Pattern N in play.
- action: thesis
  ticker: TGTX
  strategy: B
  detail: -11.3% close-to-close on a Q2 revenue beat with a large EPS miss on R&D ramp; clears criterion 1 and the 10-day window. Full thesis construction required in a separate session; SP9 mixed-signal read — event sign genuinely ambiguous.
```
