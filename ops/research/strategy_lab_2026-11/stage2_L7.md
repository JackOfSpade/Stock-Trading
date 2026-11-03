# Stage 2 L7: Odd-lot tender offers (working notes, in progress)

## Access notes
- EDGAR form.idx with the prescribed UA "strategy-research jacksterwu-research": HTTP 403 on all 5 quarters, body "Your Request Originates from an Undeclared Automated Tool", asks for company-specific info in the UA (VERIFIED, curl 2026-11-02). I did not invent a contact identity to get past it. Form counts below come from salvage_scout.md row 7 unless noted.
- state.strategy_candidates text search for tender/odd lot: 0 rows (VERIFIED), so no recorded cooldown.
- FMP secFilings search-by-form-type "SC TO-I": ACCESS DENIED, plan tier (VERIFIED). oddlotarbitrage.com returned HTTP 406 to curl; read via tavily_extract instead.

## Raw facts gathered so far
- IBKR Other Fees: voluntary corporate actions "All Other (Mandatory, Voluntary, With Options, etc) Free"; interactivebrokers.com/en/pricing/other-fees.php (VERIFIED, search excerpt).
- IBKR elections: Client Portal Corporate Actions Manager; no API or order route named; if not in the tool, a Web Ticket with exact quantity (corp-action-instructions.php, VERIFIED excerpt). Non-US/Canada region deadline text: "12:00 ET the day prior to the expiration" (US-specific line not yet read).
- OLA tracker US category counts by post year (posts on pages 1-3 of 8): 2026: 2 (RBNE, WIX); 2025: 2 (LEN, WEX); 2024: 4 (SILA, INCY, MNST, CNNE); 2023: 2+ (VVV, AVTA); 2022: 8 (TBK, TNET, SCHL, WTM, BALY, CMLS, HTH, TNET); 2021: 11+. VERIFIED from page text. Max profit stated at 99 shares before fees.
- Digest page (Oct 25 2026): 106 open, 11 flagged (US) in cards, 4 of those with odd-lot text: DCBO $20.38, BBXIA $3.84, GPUS $0.19, LEN (stale). VERIFIED, own parse.

## Event data (IBKR get_price_history daily bars pulled 2026-11-02, VERIFIED unless noted)
- IBKR lists CORPACT lines per offer: UTMD.TEN2 "TENDER ODD LOT", ABUS.TEN2 and ABUS.ODD2 "ODD LOT SPECIFIED BID", WIX.ODD/ODD2/ODD3, MDT.ODD (search_contracts). So IBKR does process odd-lot elections.
- UTMD: fixed $75, up to 650,000 sh, odd-lot priority (stocktitan/TradingView, VERIFIED). Close 9/14 70.67; open 9/15 71.27, close 74.63; open 9/16 74.59. Expiry extended 10/7 to 10/27. Bought 327,740 of 650,000: undersubscribed, so odd-lot priority did nothing.
- ABUS: $5.00-5.75 Dutch, cleared $5.00 (BioSpace 10/1, VERIFIED). Open 8/21 5.20; open 8/24 5.18.
- INVE: $2.85-3.40 Dutch, expiry 11/19 (PR, VERIFIED). Close 10/20 2.22; open 10/21 2.68; open 10/22 2.79; 11/2 bid 2.62 ask 2.66.

# Verdict: KILL

Two checks fail on evidence, each sufficient alone: T1 (DIRECTIONAL-LONG binds under acute) and T7 (the tender election is a human Client Portal step beyond the confirm tap). T3 also fails: the measured edge at the floor does not beat SGOV.

## T1 Register class: FAIL
- Class: DIRECTIONAL-LONG. The position is unhedged long stock for 18-29 trading days. Strategy.md register defines this class as a net-long expression where the shock prices into what is held (VERIFIED, Strategy.md, Shock Transmission Register).
- Not SPREAD: no short leg exists. A same-name short would break net-long tender eligibility (legal point UNVERIFIED this session). The three breaker requirements therefore do not arise, since there is no pair correlation to gate.
- Not SHOCK-NATIVE: activation does not require shock_overlay, and the expression is net long.
- Under acute today: forced DO-NOT-ACTIVATE.
- Fixed-price tenders are not immune. The offer condition can be invoked: tracker note on RBNE flags termination risk citing the Iran conflict; Frontera removed its odd-lot preference after filing (VERIFIED, oddlotarbitrage.com).

## T2 Frequency: PASS on arithmetic, thin
Source for the eligible count: oddlotarbitrage US category pages 1-3 plus my searches, filtered by the floor. EDGAR measurement failed (see Access).
- Floor filter: $2,000 / 99 shares = $20.20, so price must be at least $20.21 (computed).
- Eligible by year: 2024: 4 (SILA 21.15, INCY 56.86, MNST 54.72, CNNE 21.96). 2025: 2 (WEX, LEN exchange). 2026 to date: 3 (WIX, UTMD, MDT exchange). About 3 per year, range 2-4 (VERIFIED list; not exhaustive, so a floor).
- Hold: 18-29 trading days. UTMD was extended from 10/7 to 10/27 (VERIFIED).
- At 3 per year: required closed trades = GREATEST(3, CEIL(1.5)) = 3. Closed in a 60-day PAPER = 0.71. Days to the floor = 252, before the 400-day cull. At 2 per year: 378 days, marginal.
- Share of SC TO-I filings that are operating-company offers with odd-lot priority priced above market: NOT MEASURED. Rough floor only: Q3 2026 has 156 SC TO-I filings (scout row 7). Named operating-company odd-lot offers in that quarter: 4 (UTMD, ABUS, Highlands REIT, MDT) = 2.6%. Cash and at or above the $2,000 floor: 1 (UTMD) = 0.6%. UNVERIFIED as a share, because the numerator is what I could find, not a census. Search hits for SC TO-I skew to non-traded funds (Ares Strategic Income, Goldman Sachs Private Credit), which have no market price to buy below.

## T3 Cost against edge: FAIL
Costs at floor:
- Commission: at most $1 per buy, 0.05% at $2,000 (IBKR schedule from memory, UNVERIFIED).
- Tender fee: $0, "All Other (Mandatory, Voluntary, With Options, etc) Free" (VERIFIED, IBKR Other Fees). Morgan Stanley charges $25 per voluntary event and $25 odd-lot processing, for contrast (VERIFIED).
- Borrow: none, long only.
- Quoted spreads, after-hours snapshot 2026-11-02: INVE 2.62/2.66 = 1.52%; ABUS 3.96/4.05 = 2.25%; MDT 98.65/99.29 = 0.65%. WIX and UTMD quotes were closed-market and unusable (UTMD 70.08/76.99). VERIFIED as printed, weak as a proxy for regular-session spread.
- All-in estimate for names above the floor: 0.2-0.5% (UNVERIFIED). Rail d (commission <= 1.8%): PASS.

Gross per trade, cash offers at or above the floor (own arithmetic, prices VERIFIED):
| Offer | Entry | Basis | Paid | Gross | 99-share $ | Odd-lot priority mattered? |
|---|---|---|---|---|---|---|
| UTMD 2026 | 74.59 | next open 9/16 | 75.00 fixed | +0.55% | +40.59 | No: 327,740 of 650,000 bought |
| WIX 2026 | 91.50 | next open 3/6 | 92.00 top | +0.55% | +49.50 | No: 18.7M bought, about $1.722B of $1.75B |
| INCY 2024 | 56.86 | tracker price | 60.00 top | +5.52% | +310.86 | Yes: proration 93.5% |
| MNST 2024 | 54.72 | tracker price | 53.00 bottom | -3.14% | -170.28 | Yes: about 47.6% proration, and it locked in a loss |
| WEX 2025 | 157.72 | tracker price | 154.00 | -2.36% | -368.28 | Barely: proration 99.55% |

- Mean gross +0.22%, median +0.55%, mean -$27.52 per trade, n=5. Not a random sample, and three entries use the tracker's publication price rather than a next open.
- SGOV carry over the hold: mean 0.32%, assuming 3.85% (rate UNVERIFIED).
- Net of carry and cost: 0.22 - 0.32 - (0.2 to 0.5) = about -0.3% to -0.6% per trade.

Large premiums exist only below the floor:
- RBNE $3.00 against $1.79: 99 shares = $177 notional.
- INVE $2.85-3.40 against 2.79: $276 notional, +$5.94 to +$60.39.
- ABUS: $513 notional, and it lost 3.47% at the $5.00 clear.
- Highlands REIT $0.20, Expensify $0.98-1.20, Yext $5.75, GPUS $0.21: all below the floor.

Exchange variant tail (MDT/MMED):
- Odd lots escaped the 18.289% proration, with at least 7,656 odd-lot accounts (757,890 / 99).
- The ratio hit the 4.5939 upper limit.
- Buy 9/15 open at 93.69: value at 10/9 close $90.55 (-3.4%); at 10/15 open $76.44 (-18.4%).
- Buy 10/6 open at 87.97: +2.9% at 10/9 close; -13.1% at 10/15 open.
- MMED delivery date UNVERIFIED, so the exit bar is a range.

## T4 Next-open survival: FAIL for cash offers above the floor
Most of the gap to the offer price is gone before a next-open entry:
- UTMD: close 70.67, then 74.59 at the first open I treat as post-news. 90.5% of the distance to $75 gone. News timing inferred from bars (9/15 open 71.27, close 74.63), UNVERIFIED.
- WIX: 83.78 to 91.50: 93.9% of the distance to $92 gone.
- INVE: 2.22 to 2.79: 90.5% of the distance to the $2.85 low end gone.
What remains (+0.55% on UTMD and WIX) is about what cash pays over the hold.

## T5 Overlap
- B: tender announcements are event-day moves of at least 5% in names that can meet B's $2B cap and $10M ADV (WIX +11% on 3/5 with earnings). Partial overlap. B's all-cash exclusion covers deal targets, not issuer self-tenders.
- Account constraint: odd-lot priority needs fewer than 100 shares in aggregate, all tendered. Any A/B/D holding of the same name can void it.
- Dead ideas: none directly. state.strategy_candidates text search for tender/odd lot: 0 rows, no cooldown (VERIFIED).

## T6 Mechanical baseline: AI adds nothing measured
- Non-AI version: read a free tracker and buy 99 shares. Measured above: +0.22% gross, negative net of carry.
- Public competition: two trackers publish the list, and specialsitsdigest sells exports.
- What the AI would have to add: predicting the Dutch clearing price and the post-offer path (MNST, WEX and ABUS cleared at or near the low end; INCY and WIX at the top). No evidence exists that it can. Rail a also fails: the return is a contractual priority term plus a premium, not narrative synthesis.
- Reading the document to confirm the clause is a lookup, not an edge.

## T7 Data and execution: FAIL
- Inputs: reachable (filings, press releases, IBKR quotes). EDGAR index access needs a declared User-Agent (see Access).
- Entry: a market order at the open works.
- Exit: not an order. IBKR takes voluntary elections through the Client Portal Corporate Actions Manager, or a Web Ticket stating an exact quantity (VERIFIED, IBKR pages). IBKR does carry odd-lot lines (UTMD.TEN2, ABUS.ODD2, WIX.ODD*, MDT.ODD, VERIFIED search_contracts).
- The connector exposes no election tool: its tool list has orders, alerts, watchlists, screeners and data, and connector release notes through v1.2.1 (2026-10-27) name none (VERIFIED). "Autonomous Trading" in v1.2.1 covers orders without confirmation, not elections.
- So a human must log in, pick the odd-lot line and for a Dutch auction enter a price. That breaks the rule that only the confirm tap and deposits are human touches.
- Deadline: the page says "12:00 ET the day prior to the expiration" under All Other Regions; I did not see a US-specific heading. Canadian offers do not support guaranteed delivery. Elections submitted late are best-efforts (VERIFIED).
- If the election is missed, the position is plain long stock after the offer lapses: WIX fell from 90.50 to 81.95 close the day after its 4/1 expiry (VERIFIED bars).

## T8 Test feasibility: FAIL for power
July 2026 onward, found (not a census):
- US operating-company offers: UTMD, ABUS, INVE (odd-lot clause not confirmed), Highlands REIT, MDT exchange. Also Air Canada (Canada).
- Above the floor: UTMD (cash) and MDT (exchange) = 2 events, 2 windows that overlap in time (9/16-10/27 and 9/15-10/9). One independent cash observation, and that one was undersubscribed, so it does not test odd-lot priority at all.

## Access notes and what is not known
- EDGAR form.idx with the prescribed UA: HTTP 403 on all 5 quarters. SEC asks for company-specific information in the UA. I did not substitute a made-up contact or the owner's email. A real declared UA would allow the census. FMP secFilings and chart: plan-denied. SEC filing text was read only where a search result surfaced it.
- Open unknowns: the SC TO-I share; whether IBKR has any programmatic election route outside the connector; regular-session spreads during an offer; SILA, CNNE, VVV, AVTA outcomes (not pulled).

## One suggestion (not a rescue)
None of this should reach SHADOW. If the owner ever wants the money anyway, it is a personal manual side trade outside the system, at about tens of dollars per event.
