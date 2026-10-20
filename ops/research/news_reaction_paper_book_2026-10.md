# News-reaction paper book — pre-registration (J lead, 2026-10-20)

Owner directive 2026-10-20 (interactive session): "finish everything we can here, then tell me how long
it'll take if we wait, it'll auto deploy for real." This memo is the pre-registration record for the
prospective paper book that SL1's 2026-10-19 UPDATED event on the J lead
(`events.strategy_research_leads`, lead_id `interactive-2026-10-news-reaction-confidence-gated-long-short`,
archetype `news-reaction-confidence-gated-long-short`) named as the first step, and the design record
for the mechanism that lets the chain run with no owner touch: D1 scores calls daily, a readiness view
flips, D1 enqueues a `PENDING_QUALIFICATION` item, OPS2 hosts SL1 off-cycle, SL1 qualifies (default-REJECT),
SL2 authors, AR_orc reviews, SL5 registers PROBE at the dynamic floor, the live ramp does the rest.

**What the paper book is and is not.** It is NOT a forward-test phase (SHADOW/PAPER were retired 2026-10-19,
Experiment_Parameters.md rev 20). It is a check that the signal J would trade on exists at all with OUR
tools: the published edge (NBER w34965; Lopez-Lira & Tang, JFE 2026) is gated on token-probability
confidence the deployed model does not expose, and declared confidence carries no signal. So the book
measures a DIFFERENT confidence proxy — agreement across independent reads — on a prospective, timestamped,
post-cutoff sample. If the proxy carries no net edge after 30 realized calls, nothing deploys. That is the
correct outcome, not a failure of the mechanism.

## 1. Pre-registered constants (fixed before the first call; changing any of them re-opens the book)

| constant | value | where it lives |
|---|---|---|
| universe | 40 liquid US large caps (section 2) + SPY as benchmark | `ops.news_reaction_universe` (bigquery/261 seed) |
| readers k | 5 independent Sonnet sub-agent reads per headline, blind to each other, to prices and to D1's own analysis | D1 step text |
| confidence proxy | `agreement_score` = share of the k reads that voted the modal direction (0.2..1.0) | `events.news_reaction_calls.agreement_score` |
| agreement gate | 0.8 (at least 4 of 5 agree) | readiness view literal |
| side | long-biased: readiness counts modal-UP calls only; DOWN and FLAT calls are recorded for the record and never traded | readiness view |
| horizon | 1 trading day, open-to-open: enter at the first open after `call_date`, exit at the next open | `horizon_days = 1`; realized-return view |
| cost model | 20 bp per round trip (IBKR $1 minimum each way at the $2,000 floor is 10 bp; spread 5-10 bp) | readiness view literal `0.002` |
| readiness | `n_realized >= 30 AND net_mu > 0`, where `net_mu = mean(realized_return) - 0.002` over gated long calls with a realized return at the declared horizon | `state.news_reaction_paper_book_readiness.ready` |
| headline cap | at most 3 headlines per ticker per `call_date`, newest first | D1 step text |

Why open-to-open and not Lopez-Lira & Tang's open-to-close: every order in this system is crafted in the
evening and executed at the next open (market-only cutover 2026-07-21), so the earliest exit after a
next-open entry is the following open. The book measures what we can execute, not what the paper measured.

Why agreement and not stated confidence: w34965 shows declared confidence is uninformative to inverted
while inner (token-entropy) confidence carries the edge. Agreement across independent blind reads is the
structural proxy SL1's UPDATED next_step item (1) asked for; it is computable with the deployed model and
it is pre-registered here so it cannot be tuned post hoc. All k votes are stored, so ordinal tiers can be
calibrated later from the same rows without re-running anything; the readiness gate itself stays at 0.8.

## 2. Universe (fixed)

AAPL MSFT NVDA AMZN GOOGL META TSLA AVGO JPM BAC GS V MA UNH LLY JNJ PFE MRK ABBV XOM CVX COP CAT DE BA
GE HON UPS WMT COST HD NKE MCD DIS NFLX CRM ORCL AMD INTC QCOM — plus SPY (role BENCHMARK, never scored).

Chosen for liquidity (cost rail (d) at the floor), news density (single-name headlines most days) and sector
spread. The published edge is strongest in small caps and we deliberately do not trade them (fillable size,
spread); the book therefore tests the edge where we would actually trade it.

## 3. Data sources (all key-less; verified from this host 2026-10-20)

- **Headlines:** Google News RSS per ticker —
  `https://news.google.com/rss/search?q=<company name or ticker>+stock+when:1d&hl=en-US&gl=US&ceid=US:en`,
  browser User-Agent. Returned dated items for CAT within seconds. Fallback: Nasdaq per-symbol RSS
  `https://www.nasdaq.com/feed/rssoutbound?symbol=<T>` (also verified). Metered Tavily search is the last
  resort and is logged to `ops.web_calls` per the shared obligation; the two RSS feeds are not metered and
  log nothing. FMP `news` is ACCESS DENIED on this plan (ops/connector_tools.yaml) and is never used.
- **Prices:** Nasdaq historical —
  `https://api.nasdaq.com/api/quote/<T>/historical?assetclass=stocks&fromdate=<D-14>&todate=<D>&limit=20`
  (`assetclass=etf` for SPY), browser User-Agent, `Accept: application/json`. `data.tradesTable.rows[]`
  carries `date` (MM/DD/YYYY), `open`, `close` as `$`-prefixed strings with thousands separators. Split-adjusted,
  not dividend-adjusted — irrelevant at a 1-day horizon. Written to `events.news_reaction_marks`, a table of
  its own: `events.daily_marks` is the deployed-TWR engine's spec-frozen input (held tickers only) and
  `events.signal_marks` is the park menu's; neither may be widened to 41 tickers.

## 4. Tables and views (bigquery/261_news_reaction_paper_book.sql)

- `ops.news_reaction_universe` (ticker, role UNIVERSE|BENCHMARK, added_date, note) — seeded once, NOT-EXISTS guarded.
- `events.news_reaction_marks` (mark_date, ticker, open_px, close_px, source, ingest_ts, row_uid) — append-only;
  consumers read `state.news_reaction_marks_curated` (latest ingest per ticker/day, row_uid tiebreak).
- `events.news_reaction_calls` — append-only, one row per (call_date, ticker, headline_hash):
  call_id, call_ts, call_date (America/Denver), lead_id, ticker, headline_hash (SHA256 hex of the lower-cased,
  whitespace-collapsed headline), headline, published_ts, source, source_url, direction UP|DOWN|FLAT (the modal
  vote), agreement_score, k, votes_json (the k raw votes), horizon_days, scorer_routine, scorer_session, note.
- `state.news_reaction_call_returns` — per call: entry_date (first curated mark_date strictly after call_date
  for that ticker), entry_open, and open-to-open returns at 1, 3 and 5 trading days plus SPY over the same
  windows; `realized_return` = the return at the row's own horizon_days.
- `state.news_reaction_paper_book_readiness` — one row per lead_id: the constants above, counts, gross_mu,
  net_mu, excess-vs-SPY mu, hit rate, `ready`, first/last call dates, days since last call.

## 5. The daily step (D1, every firing, after the PARK PIN CHECK, before RECOMMENDED ACTIONS)

1. Read the universe. Fetch the last ~10 trading days of marks per ticker (Nasdaq historical) and INSERT any
   (mark_date, ticker) pair missing from the curated view — gaps self-heal on the next run.
2. Fetch headlines per universe ticker published since the SCAN WINDOW start (capped at 48 h), keep items that
   name the company, de-duplicate by headline_hash, keep at most 3 per ticker.
3. Fan out k = 5 blind reads (Sonnet sub-agents, the fleet convention): each receives the whole day's list of
   (ticker, headline, published_ts) and nothing else, and returns one vote per headline: UP, DOWN or FLAT for the
   stock's next-open-to-following-open move. No reader sees another reader, any price, or D1's own scan.
4. INSERT one `events.news_reaction_calls` row per headline (all directions), NOT-EXISTS guarded on
   (call_date, ticker, headline_hash), horizon_days = 1, lead_id literal, scorer_routine = 'D1'.
5. Read the readiness view. If `ready = TRUE` and no open `PENDING_QUALIFICATION` item exists for the lead,
   INSERT the `events.queue_events` item: queue 'PENDING_QUALIFICATION', item_key = lead_id,
   item_type 'lead-readiness', status 'pending', due_date = the next calendar day after
   `state.trading_day_today.today`, payload {resolving_venue:'SL1', lead_id, archetype, n_realized, net_mu}.
6. One line in Daily.md under the TL;DR: `Paper book (J): <calls today> calls, <n_realized>/30 realized,
   net_mu <x.xx%>, ready=<TRUE|FALSE>`.

The step is non-gating: a failed fetch is a skipped ticker, noted in the run note, never a halted D1.

## 6. The hand-off (why a queue lane and OPS2, not a cron change)

SL1 fires quarterly (`0 21 2 1,4,7,10 *`, next 2027-01-02). Headless routines cannot call the RemoteTrigger
`run` action (RUNBOOK §15b), so nothing in the fleet can fire SL1 on demand; the catch-up design already
answers this for missed slots — OPS2 executes a catchup_safe routine INLINE, and SL1 is catchup_safe. The
cheapest correct hand-off is therefore the same shape every other SISA handoff uses: a queue lane.

- Lane `PENDING_QUALIFICATION`, item_type `lead-readiness`, drainer SL1, terminal status `complete`.
  Registered in `state.queue_venue_claim_unwired`'s allowed_map by bigquery/262 (supersedes 225) and in
  ops/handoff_contracts.yaml queue_lanes, so D3's venue-claim check accepts `resolving_venue = 'SL1'`.
- OPS2 (every Sun–Thu 22:15 MT) reads the lane; if an item is due and `ops.run_log` holds no SL1 `completed`
  row logged after the item was enqueued, it hosts SL1 inline under STEP 2's existing hosting rules. SL1's
  own guards (arsenal kill-switch, Q1/Q3 period-window dependency gate, same-day double-run guard) are unchanged.
- SL1 reads the lane in STEP 1: a lead whose readiness view says `ready` has met its objective promotion
  threshold, so STEP 2 writes the CONVERTED lead event + the candidate row and STEP 3 qualifies
  (default-REJECT). Whatever the verdict, SL1 closes the item at status `complete`. If readiness no longer
  holds at fire time, SL1 appends an UPDATED lead event and still closes the item.
- A due item SL1 never drains trips D3's `queue_item_stale` warning the next evening — the existing detector,
  no new alert category.

A monthly SL1 cron was considered and rejected for now: it still waits up to a month after readiness, costs a
deep-research run every month, and is a cadence change touching cadence.yaml, triggers.json, routine_backup.json,
the generated routine lists and the live trigger (feedback_cadence_change_dependency_traps). The queue path is
immediate and touches none of those.

## 7. Timeline arithmetic (stated honestly)

Calls per day are unmeasured until the first run. Expectation: 40 names, roughly a third to a half carry a
company-specific headline on a given day, and perhaps a third of those reach a modal-UP vote at agreement
>= 0.8 — on the order of 5–8 gated long calls per trading day. 30 realized calls then takes about 5–8 trading
days plus 2 trading days for the last call to realize. The first run is the measurement; the readiness view
reports `n_realized` and `days_since_last_call` so the estimate is checkable from day one.

If `net_mu` after 30 realized calls is not positive, the readiness view never flips, no queue item is written,
SL1 next sees the lead at its scheduled 2027-01-02 fire with a measured negative, and nothing deploys.
