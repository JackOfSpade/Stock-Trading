# Weekly System Report — redesign implementation plan ("Strategies vs SGOV")

> **Handoff document.** Design decisions here are FINAL (made by the owner + the designing
> session on 2026-07-02 against live BigQuery data and verified Apps Script / Gmail docs,
> then adversarially reviewed by four independent critics — SQL was live-executed against
> BigQuery, worked numbers below are verified). The implementing session executes; it does
> not re-open design questions. Where a step says "verbatim", copy the given code/SQL
> exactly. Delete this file in the final commit of the implementation, or keep it —
> genuinely implementer's choice (as is commit granularity in Step 8; nothing else is).

## 0. Goal — the one question

The owner's directive (2026-07-02): the weekly email must answer exactly one question —

> **"Is each strategy beating just parking the cash it was allocated (a portion of the
> overall portfolio value) in SGOV?"**

— and everything that does not support answering that question is clutter and must go.
The clarification "(the cash it was allocated)" matters: the question is **sleeve-level**
("did giving $1,889 to strategy B beat leaving that $1,889 in the SGOV park?"), not just
"did the deployed slice have a good TWR".

Key domain fact that makes this answerable: **undeployed sleeve cash already sits in the
account-level SGOV park** (~98% of NAV; RUNBOOK §29 — the per-strategy SGOV split is
formally dissolved). So the actual sleeve differs from the all-parked counterfactual
**only on the deployed slice**, and:

```
sleeve-level edge vs full park (in $) =
    Σ over deployed position-days of  deployed_capital_day × (r_deployed_day − r_sgov_day)
```

That cumulative **dollar edge vs the park** is the redesign's primary metric. The existing
engine metric `excess_vs_sgov` (deployed-TWR unit value ÷ SGOV index − 1, chained over the
strategy's own deployed days — `perf.strategy_daily`, the sanctioned kill/gate metric)
stays as the secondary "edge intensity on the deployed slice" column. Both are shown; the
dollar edge answers the owner's question, the percent ties to the spec's kill/gate
machinery. Note they measure differently ($ is capital-weighted, % is time-weighted) —
they can legitimately differ in sign when deployment size varies across good/bad days.

**Live values at design time (2026-07-01 close — verified by executing the Step-1 SQL
against BigQuery):** only **B** and **D** have ever deployed (46 contiguous trading days
each, 2026-04-27 → 2026-07-01).

| | B | D |
|---|---|---|
| edge_dollars_cum (gross $ vs park) | **+$10.67** | **−$1.46** |
| excess_vs_sgov (deployed-TWR %) | +8.42% | −2.05% |
| closed trades / gate | 6/30 | 0/30 |
| commissions_to_date | $4.83 | ≈$0.6–1.5 (few fills) |

Combined edge ≈ **+$9.22**; the park itself earned ≈ **$61.59** (`park_return` 0.006516 on
~$9,452 total sleeve NAV) over the same window. A/C/E have **zero** deployed history — by
design, not failure (A router do-not-activate; C hybrid FOMC-only with options-sizing
deferral; E execution-deferred).

All dollar examples below use these verified values. They will have drifted by
implementation time — regenerate examples from live data where a step says to; never
hardcode them into logic.

## 1. The redesigned email — final design

Email = one hero verdict, one chart, one verdict table, one methodology footnote.
Visual language stays the current one (600px card, navy `#0f2747` header, `#f5f7fa` tiles,
inline styles only, table-based layout — see the current `.gs` / `sample_preview.html`),
with one deliberate change: card/table surfaces switch from pure `#ffffff` to `#fffffe`
(Gmail iOS/Android dark-mode invert targets pure white/black in CSS; near-white dodges
it). Keep the near-black text colors `#0f2747`/`#1f2d3d`.

### 1.0 Verdict states (used by subject, hero, table, fallback bars)

Per-strategy, from `edge_dollars_cum` and `commissions_to_date` (both from
`analytics.strategy_vs_park`), computed on the **2dp-rounded** dollar value:

- `NEUTRAL_BAND(s) = max(2.00, commissions_to_date(s))` — a materiality floor: below ~$2
  the edge is inside its own day-to-day noise at current scale, and an edge smaller than
  the commissions paid to earn it shouldn't claim green (gross-vs-net has already flipped
  sign once in this experiment's history, 2026-06-05 findings).
- `edge ≥ +BAND` → **BEATING PARK** (green)
- `edge ≤ −BAND` → **TRAILING PARK** (red)
- `|edge| < BAND` → **≈ EVEN WITH PARK** (amber — the honest state for a noise-level edge)
- no perf rows ever → **NOT DEPLOYED** (gray; edge is $0.00 **by construction** — the
  sleeve sits in the park)

Live application: B (+$10.67, band $4.83) → BEATING PARK; D (−$1.46, band $2.00) →
≈ EVEN WITH PARK. Never print a signed zero (render `$0.00` unsigned in neutral/gray
styles). The combined (hero) figure uses `max(2.00, total commissions)` the same way.

### 1.1 Subject line

```
Stock-Trading · Strategies vs SGOV — Jul 5, 2026 · B +$10.67 · D ≈even
```

- Every **ever-deployed** strategy enumerated in fixed A→E order: its signed 2dp dollar
  edge when outside the neutral band, `≈even` inside it. No survivorship — winners,
  losers, and evens all appear.
- If none has ever deployed: `· all parked`.
- Append ` · ⚠ check data` when the data-trust predicate (§1.6) is not green.
- Keep the date in the subject (prevents Gmail threading — existing convention).

### 1.2 Header (navy band)

- Title: `Stock-Trading · Strategies vs SGOV` + "Week ending {date}" right-aligned
  (same layout as today).
- One small line under the title: `data through {system_health.last_mark_date} close`.
  Nothing else when green — absence of warnings is the signal. (Not-green: §1.6.)

### 1.3 Hero verdict tile

One full-width stat tile (like today's stat cards but single, centered):

- Label: `ALL STRATEGIES COMBINED · SINCE FIRST DEPLOYMENT ({MMM d} =
  park_baseline.first_deployed_date)`
- Big number: combined edge, e.g. `+$9.22 vs SGOV park` — green `#1a7f5a` beyond
  +band, red `#c0392b` beyond −band, navy `#0f2747` inside the band.
- Subline (muted) — worded to prevent a head-to-head misread of relative-vs-absolute:
  `for scale: the SGOV park itself earned ≈$62 over this period — the figure above is
  what deploying added on top of that, gross of ${total commissions} commissions.`
  (`park_dollars_approx` from `analytics.park_baseline`, rounded to whole dollars, `≈`
  kept — its base is current sleeve NAV, not exact deposits.)
- If no strategy has ever deployed: the tile reads `all sleeves parked in SGOV — no
  deployments yet` with no dollar figure.

### 1.4 The chart — cumulative $ edge vs SGOV park

**Design rationale (final, recorded for the RUNBOOK entry; do not re-litigate):** the
owner suggested a multi-line chart of each strategy plus SGOV. We keep the multi-line
form but plot each strategy **relative to SGOV**, with SGOV rendered as the flat $0
baseline line, because (a) — the decisive reason — raw growth-of-$1 unit curves are
deployed-slice-only and dollar-unaware: they would visually re-crown B's +9.1% slice
number, reinstating exactly the framing the owner's sleeve-level clarification corrected;
(b) a single calendar SGOV line stops being any strategy's true benchmark once
deployments pause (the engine chains per-strategy and pauses when parked); (c) dollars
answer the sleeve question directly, and D's gap would be small and hard to judge at unit
scale. "Above the gray line = beating the park" is readable in one glance, and the SGOV
line the owner asked for is still there — it IS the zero line, labeled "SGOV park". What
a raw-scale chart uniquely offers (SGOV's own earning power) is carried by the hero's
park-$ anchor instead; a second chart/scale would violate the one-question directive.

- **Series:** one line per ever-deployed strategy (`edge_dollars_cum` by `as_of_date`,
  from `analytics.strategy_vs_park_daily`), plus a constant-0 series named `SGOV park`.
  **The SGOV park series is the FIRST data column** (and first in `setColors`) so
  strategy lines draw on top of the baseline — the near-$0 region is exactly where a
  noise-band strategy lives and must not be overplotted by the gray line.
- **Missing dates:** build the union of dates across deployed strategies, downsample the
  UNION once if it exceeds 130 points (keep the last date per ISO week + always the final
  date), then forward-fill every series onto the kept dates. Before a strategy's first
  `as_of_date` its value is **0** (it was fully parked — edge $0 by construction), so
  every line spans the full x-axis. A flat stretch = parked/idle, which is semantically
  correct, not an artifact. (Today B/D share all 46 dates; this is future-proofing.)
- **Build:** Apps Script Charts service (server-side static PNG — verified alive and
  correct as of 2026-07-02), embedded via `inlineImages` cid. **Gmail supports NO inline
  SVG and NO data-URI images; cid inline attachment is the only self-contained image
  route.** Never use the Sheets EmbeddedChart export path (known fidelity bugs), never
  chart.googleapis.com (dead since 2019), never an external renderer (no new scopes, no
  third-party data exposure).
- **Colors — fixed identity map, never reassigned by rank, presence, or performance**
  (CVD-validated 2026-07-02 on the white chart surface; B↔D worst-pair ΔE 96.7):

  | Series | Hex |
  |---|---|
  | SGOV park (zero line, first column) | `#898781` |
  | A | `#1baf7a` |
  | B | `#2a78d6` |
  | C | `#4a3aa7` |
  | D | `#eb6834` |
  | E | `#e87ba4` |

- **Chart spec:** `Charts.newDataTable()` with a `DATE` first column; `setDimensions(1120,
  400)` rendered, displayed at `width="560" style="width:100%;max-width:560px;height:auto;
  display:block;"` (2× for retina); `setLegendPosition(Charts.Position.BOTTOM)`;
  `setPointStyle(Charts.PointStyle.NONE)`; `setBackgroundColor('#fffffe')` (baked opaque
  near-white — never transparent: dark axis text on a transparent PNG vanishes on dark
  backgrounds; PNG pixels themselves are never inverted by Gmail); no chart title (the
  HTML section header carries it); `setYAxisTitle('$ vs park')`.
- **Empty state:** when no strategy has ever deployed, **skip the chart section
  entirely** and render one muted line: `Nothing has ever deployed — all sleeves fully
  parked (edge $0 by construction).` Guard `buildParkChart_` with
  `if (!deployedStrategies.length) return null;`.
- **Fallback (must exist):** the chart build is wrapped in try/catch. On any throw,
  render a Gmail-safe HTML bar row per ever-deployed strategy instead: left-anchored
  magnitude bars (fixed-px-width `<div>`s, widths scaled to `max(max|edge|, 1.00)`,
  minimum 2px), sign/verdict carried by color — green `#1a7f5a` beyond +band, red
  `#c0392b` beyond −band, amber `#b9770e` inside the band — plus the signed value printed
  beside each bar. Sign-as-status coloring is correct here (the color MEANS the verdict).
  The email must never fail to send because the chart failed.
- **Alt text** on the `<img>`, generated from the data:
  `Cumulative dollar edge vs SGOV park: B +$10.67, D −$1.46`.
- Section header above the chart: `CUMULATIVE EDGE VS SGOV PARK ($ PER SLEEVE)`, with a
  one-line muted caption: `SGOV park = the gray $0 line. Above it = beating the park;
  flat = parked/idle. A, C, E have never deployed — their edge sits on the $0 line.`
  (Drop the A/C/E sentence if/when all five have deployed.)

### 1.5 Verdict table (the table view / accessibility twin of the chart)

One row per strategy, always all five, fixed A→E order:

| col | content |
|---|---|
| (chip) | 10px square in the strategy's chart color (ties table to chart) |
| Strategy | letter, bold; muted subtext under it: `alloc $1,896 · deployed $117 · comm. $4.83` (scorecard `nav`, `deployed_mv`, and `commissions_to_date`; omit `deployed` when 0, omit `comm.` when NULL/0) |
| Verdict | chip per §1.0: `BEATING PARK` (bg `#e6f4ee` / fg `#1a7f5a`), `TRAILING PARK` (bg `#fdecea` / fg `#c0392b`), `≈ EVEN WITH PARK` (bg `#fdf3e3` / fg `#b9770e`), `NOT DEPLOYED` (bg `#edf0f3` / fg `#8a96a3`) |
| vs park $ | `edge_dollars_cum`, signed, 2dp, colored by verdict (amber → muted `#8a96a3` text); unsigned `$0.00` muted for NOT DEPLOYED |
| Δ wk | `edge_dollars_wk`, signed, 2dp, colored by raw sign; `—` for NOT DEPLOYED |
| TWR edge, deployed slice | scorecard `excess_vs_sgov` as signed %, colored by sign; `—` when NULL |
| Closed trades / 30 | `{closed_trades}/30`; append ` ✓` when the gate is reached — **derive in JS as `num_(s.closed_trades) != null && num_(s.closed_trades) >= 30`** (identical to `perf.kill_flags.gate_reached`, 03_twr_engine.sql:154). Do NOT add columns to the scorecard query and do NOT query kill_flags for this. `—` for NOT DEPLOYED |

- NOT-DEPLOYED rows are muted (text `#8a96a3`) and carry a one-line reason derived from
  the scorecard `activation` string: contains `DO-NOT` → `router: do-not-activate`;
  contains `HYBRID` → `hybrid — awaiting qualifying event`; otherwise (active, no
  deployments) → `awaiting first deployment`. Never render them as losing.
- If `any_kill_flag` is true for a strategy, add a red `KILL REVIEW` chip in its Verdict
  cell and one line under the table naming the firing flag(s) (query `perf.kill_flags`
  only in that case — same lazy pattern as today's `buildHealthReasons_`). Kill flags are
  SGOV-question-relevant (the m2m kill IS an excess-vs-SGOV trigger); everything else
  about ops health is not.
- Muted caption under the table: `Verdicts are provisional before a strategy's 30-trade
  gate (spec: ~30 closed trades is the first point an honest directional claim can be
  made). The $ edge is capital-weighted and the % edge time-weighted — they can differ in
  sign when deployment size varies.`

### 1.6 Data-trust line (the only surviving "ops" content)

The SGOV verdict is only as good as the marks/engine behind it, so keep exactly one
trust signal and nothing else. **The green predicate, computed in the .gs from
`state.system_health` alone:**

```
green := marks_fresh && engine_fresh && firing_kill_flags === 0 && open_critical_alerts === 0
```

(`open_critical_alerts` is a real column on the view — 10_observability.sql:134. Use it,
NOT `open_alerts`, which counts warnings too. Embeddings/backups/automation/cadence are
deliberately excluded.)

- Green case: nothing beyond the header's `data through {last_mark_date} close`.
- Not-green case: one amber block under the header: `⚠ Numbers below may be stale —
  {reasons}`, reusing the existing `buildHealthReasons_` logic **restricted to**:
  marks/engine freshness — keeping the existing `d2_ran_last_trading_day` distinction
  (D2-pending still counts as not-green, with the existing "normal before ~22:30 MT, not
  a fault by itself" wording as the reason) — firing kill flags, and unresolved
  `severity='critical'` alerts (lazy `ops.alerts` query ONLY when
  `open_critical_alerts > 0`).
- **Dropped from the email entirely:** embeddings health, backups, automation heartbeats,
  cadence watch, non-critical alerts, the ALL GREEN/ATTENTION badge, regime section
  (integrative label, axes, technical signals), account NAV/Week/MTD/YTD stat cards, open
  positions table, next-7-days strip, weekly activity (fills/GO/NO-GO/pending). Rationale
  to record in the RUNBOOK entry: account TWR is ~98% SGOV park (not a strategy signal);
  ops monitoring already reaches the operator via the independent DTS failure email +
  the dashboard; positions/activity/regime are available in Daily.md and the dashboard.
  This is an owner directive (2026-07-02) — do not re-add these sections later without a
  new owner ask.

### 1.7 Footer / methodology (small, muted, one block)

- `Edge $ = deployed dollars × (deployed return − SGOV total return), summed over each
  strategy's deployed days; undeployed sleeve cash sits in the SGOV park (edge $0 by
  construction). Edge % = deployed-TWR unit value vs SGOV index over the strategy's own
  deployed days (perf.strategy_daily — the kill/gate metric). Figures are nominal,
  pre-tax/pre-inflation, and GROSS of commissions (owner directive 2026-06-05; per-sleeve
  commissions shown in the table). Benchmark = SGOV actual total return incl. monthly
  dividends. Auto-generated weekly from BigQuery; times in {tz} (detected).`
- The headline stays gross (settled decision; no "net edge" column) — but commissions are
  surfaced per-row (§1.5 subtext) and inside the neutral band (§1.0), not buried.

### 1.8 Plain-text part

Rebuild `buildPlain_` to mirror every section above from the same `d` object: subject
verdicts, hero + park-scale line, per-strategy rows (verdict incl. ≈even, $ edge, Δ wk,
% edge, closed-trades count, reason when not deployed), data-trust reasons when present,
methodology line. The chart's content is carried by the alt-text data (per-strategy
latest edges). Same null-guarding discipline as the current file (NULL → `—`, never
`+0.00%`).

## 2. Implementation steps

### Step 1 — SQL: one edited view + one new file

**1a. Edit `bigquery/03_twr_engine.sql`** — in the final SELECT of
`analytics.strategy_daily_returns` (currently `SELECT mark_date AS as_of_date, strategy,
SAFE_DIVIDE(...) AS r_deployed, COUNT(*) AS n_positions`), add one column:

```sql
       SUM(prev_mv) AS deployed_capital,
```

(after `r_deployed`; keep everything else byte-identical). This is additive: the engine
recompute (`ops.sp_recompute_engine`) selects named columns and is unaffected, and no
other live view or repo consumer reads this view (verified). Add a one-line comment above
the column: `-- deployed dollars marked that day (Σ prev_mv); feeds
analytics.strategy_vs_park_daily (21_strategy_vs_park.sql)`.

**1b. New file `bigquery/21_strategy_vs_park.sql`** — verbatim (add a header comment
block in the style of `14_weekly_report.sql`: project, purpose "sleeve-vs-SGOV-park
substrate for the redesigned weekly self-email", apply after 03; note the email reads
these via the Apps Script):

```sql
-- ===== analytics.strategy_vs_park_daily — cumulative $ edge vs the SGOV park, per strategy =====
-- The weekly email's chart series. edge_dollars_day = deployed_capital × (r_deployed − r_sgov):
-- the dollars the deployed slice made over what those same dollars would have earned staying in
-- the SGOV park. Cumulative sum answers the owner's question at SLEEVE level, because undeployed
-- sleeve cash already sits in the account-level SGOV park (RUNBOOK §29) — the sleeve differs from
-- the all-parked counterfactual only on the deployed slice. Simple (non-compounded) daily sum:
-- second-order compounding of the counterfactual is < $0.01 at current scale/horizon.
-- r_sgov forward-fill mirrors ops.sp_recompute_engine (a missing SGOV mark must not read as 0).
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_vs_park_daily` AS
WITH j AS (
  SELECT
    sdr.as_of_date, sdr.strategy, sdr.deployed_capital, sdr.r_deployed,
    COALESCE(
      sg.r_sgov,
      LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
        PARTITION BY sdr.strategy ORDER BY sdr.as_of_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
      0) AS r_sgov
  FROM `stock-trading-498512.analytics.strategy_daily_returns` sdr
  LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
)
SELECT
  as_of_date, strategy, deployed_capital,
  deployed_capital * (r_deployed - r_sgov) AS edge_dollars_day,
  SUM(deployed_capital * (r_deployed - r_sgov)) OVER (
    PARTITION BY strategy ORDER BY as_of_date) AS edge_dollars_cum
FROM j;

-- ===== analytics.strategy_vs_park — latest verdict row per ever-deployed strategy =====
-- 7d-ago anchor: nearest row to CURRENT_DATE−7 (America/Denver — the operating plane; display tz
-- never leaks into SQL windows), deterministic tie-break toward the NEWER row (', as_of_date DESC'
-- — same pattern as state.account_nav_7d_ago; a Monday-holiday week produces real two-row ties,
-- and dbt-parity evaluates the twin and the live view independently, so a nondeterministic pick
-- would show up as spurious drift). In a strategy's first week the nearest row is its own early
-- history, so edge_dollars_wk reads as approximately since-inception — same accepted behavior as
-- twr_7d.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_vs_park` AS
WITH latest AS (
  SELECT strategy, as_of_date, edge_dollars_cum
  FROM `stock-trading-498512.analytics.strategy_vs_park_daily`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
wk_ago AS (
  SELECT strategy, edge_dollars_cum AS edge_dollars_cum_7d_ago
  FROM `stock-trading-498512.analytics.strategy_vs_park_daily`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY strategy
    ORDER BY ABS(DATE_DIFF(as_of_date, DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY), DAY)),
             as_of_date DESC
  ) = 1
),
firsts AS (
  SELECT strategy, MIN(as_of_date) AS first_deployed_date
  FROM `stock-trading-498512.analytics.strategy_vs_park_daily`
  GROUP BY strategy
),
comm AS (
  SELECT strategy, SUM(commission) AS commissions_to_date
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE ticker != 'SGOV' AND strategy IS NOT NULL
  GROUP BY strategy
)
SELECT
  l.strategy, l.as_of_date, l.edge_dollars_cum,
  l.edge_dollars_cum - w.edge_dollars_cum_7d_ago AS edge_dollars_wk,
  f.first_deployed_date,
  c.commissions_to_date
FROM latest l
JOIN wk_ago w USING (strategy)
JOIN firsts f USING (strategy)
LEFT JOIN comm c USING (strategy);

-- ===== analytics.park_baseline — "what would parking everything have earned" (hero subline) =====
-- One row. Anchored on strategy_vs_park_daily (NOT perf.strategy_daily, which is rebuilt via a
-- non-atomic DELETE+INSERT in ops.sp_recompute_engine — a mid-recompute read would transiently
-- see an empty table). park_dollars_approx uses current total sleeve NAV as the base
-- (≈ deposits ± small P&L) rather than duplicating the deposit literal hardcoded in
-- analytics.strategy_nav — labeled ≈ in the email.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.park_baseline` AS
WITH f AS (
  SELECT MIN(as_of_date) AS first_deployed_date
  FROM `stock-trading-498512.analytics.strategy_vs_park_daily`
),
p AS (
  SELECT EXP(SUM(LN(1 + sg.r_sgov))) - 1 AS park_return
  FROM `stock-trading-498512.analytics.sgov_daily_return` sg, f
  WHERE sg.as_of_date >= f.first_deployed_date
)
SELECT
  f.first_deployed_date,
  p.park_return,
  (SELECT SUM(nav) FROM `stock-trading-498512.analytics.strategy_nav`) * p.park_return
    AS park_dollars_approx
FROM f, p;
```

**1c. Apply live** via the BigQuery MCP `execute_sql` (write tool, project
`stock-trading-498512`): first the edited `analytics.strategy_daily_returns` statement,
then the three statements of `21_strategy_vs_park.sql`. This repo's operating model is
MCP/console-applied SQL with the repo as versioned spec (CLAUDE.md settled decision — no
Terraform). If the write tool is unavailable in your session, stop and leave the SQL
committed with a note in the commit body that the owner must apply it from the console;
do NOT skip the file.

**1d. Verify live** (readonly). Expected values are as-of 2026-07-01 marks; they drift
daily, so treat the bands, not the cents, as the check:

```sql
SELECT * FROM `stock-trading-498512.analytics.strategy_vs_park` ORDER BY strategy;
-- expect exactly 2 rows (B, D) unless a new strategy deployed since;
-- B.edge_dollars_cum ≈ +$9–12 (was +$10.67 at 2026-07-01), D ≈ −$1–2 (was −$1.46);
-- first_deployed_date = 2026-04-27 for both; commissions_to_date: B ≈ $4.83, D > 0.
-- CROSS-CHECK: edge_dollars_cum must NOT equal commissions_to_date for any strategy
-- (that coincidence is the exact wrong-column failure mode this check exists for).
SELECT strategy, COUNT(*) n, MIN(as_of_date) mn, MAX(as_of_date) mx
FROM `stock-trading-498512.analytics.strategy_vs_park_daily` GROUP BY strategy;
-- expect B and D, 46+ rows each (grows daily), mn = 2026-04-27.
SELECT * FROM `stock-trading-498512.analytics.park_baseline`;
-- expect 1 row, park_return ≈ 0.006–0.008, park_dollars_approx ≈ $60–75.
```

Sign sanity: today B's `edge_dollars_cum` sign matches `perf.kill_flags.excess_vs_sgov`
sign (+) and D's matches (−). Sign disagreement is mathematically possible under
time-varying deployed capital ($ is capital-weighted, % time-weighted) — if you see one,
investigate before proceeding, but it is not automatically a defect.

### Step 2 — rewrite `ops/weekly_report/weekly_report.gs`

Full rewrite of the data-gathering and rendering; **keep these verbatim / structurally
identical** (they encode settled contracts):

- `bq_()` — the fail-loudly contract (a query that doesn't complete must THROW and abort
  the send; an aborted send writes no heartbeat, which is what the dead-man's switch
  detects — fix F3, do not soften). Remember `bq_()` returns every cell as a STRING —
  keep the `num_()` discipline on all numerics.
- The heartbeat INSERT after a successful send, with the exact source string
  `'weekly_report'` (must match `16_automation_health.sql`'s
  `STRUCT('weekly_report' AS source, 216 AS max_age_hours)`), still best-effort
  try/catch, still AFTER `GmailApp.sendEmail`.
- `getUserTz_()` (display tz from `state.user_tz`, Denver fallback) — display formatting
  only; never anchor SQL logic to it.
- `installWeeklyTrigger()` / `testReport()` / `runWeeklyReport()` entry points, the
  Sunday-07:00 constants, `RECIPIENT`/`SENDER_NAME` config block, the file-top doc
  comment (update its DATA list to the new views).
- Formatting helpers `num_ money0_ money2_ signPct_ clr_ esc_` and the per-FIELD
  null-guard discipline. Add one helper for signed money (subject/hero/table):
  `function signedMoney2_(v){ return (v >= 0 ? '+' : '−') + '$' + Math.abs(v).toFixed(2); }`
  (unicode minus, matching `signPct_`).

**Label step — keep the structure, UPDATE the search string** (it is coupled to the
subject format; kept verbatim it silently never matches again):

```javascript
GmailApp.search(`subject:"Strategies vs SGOV — ${d.dateLabel}" newer_than:1d`, 0, 5)
// NOTE: this search string must match the subject format built in sendWeeklyReport_.
```

**New `gatherData_()` queries** (every email query stays a named, version-controlled
BigQuery view — existing convention):

```
analytics.strategy_scorecard      -- explicit columns: strategy, activation, is_active, nav,
                                  --   deployed_mv, excess_vs_sgov, closed_trades, any_kill_flag
                                  --   (view is UNCHANGED — do not touch its SQL or dbt twin,
                                  --   and do not add columns to this SELECT: gate ✓ is derived
                                  --   in JS from closed_trades, §1.5)
analytics.strategy_vs_park        -- SELECT * (verdicts, $ edges, wk deltas, commissions)
analytics.strategy_vs_park_daily  -- SELECT as_of_date, strategy, edge_dollars_cum
                                  --   ORDER BY strategy, as_of_date  (chart series)
analytics.park_baseline           -- SELECT *
state.system_health               -- SELECT * (data-trust predicate, §1.6)
state.user_tz                     -- (via getUserTz_)
perf.kill_flags                   -- ONLY when a scorecard row has any_kill_flag (lazy)
ops.alerts (critical, unresolved) -- ONLY when system_health.open_critical_alerts > 0 (lazy)
```

**Queries to DELETE from the .gs** (views stay in BigQuery — see Step 5):
`state.current_regime`, `analytics.weekly_activity`, `state.account_latest`,
`state.account_nav_7d_ago`, `analytics.account_reconciliation`, `analytics.weekly_fills`,
`analytics.weekly_nogos`, `state.open_positions_summary`, `state.next_7_days`,
`state.automation_heartbeat`, `state.backup_health`, `state.ops_backup_health`,
`state.cadence_watch`, `state.embedding_health`.

**Chart build** (new function; returns `{blob, altText}` or `null` — caller then uses the
HTML bar fallback). Note the two marshalling traps: `bq_()` returns strings, and
`new Date('YYYY-MM-DD')` is UTC midnight (renders as the PREVIOUS day in Denver) — build
dates with local-midnight construction:

```javascript
function buildParkChart_(daily, deployedStrategies) {
  try {
    if (!deployedStrategies.length) return null;
    const COLORS = { A:'#1baf7a', B:'#2a78d6', C:'#4a3aa7', D:'#eb6834', E:'#e87ba4' };
    const SGOV_GRAY = '#898781';
    // 1. union of as_of_dates across deployed strategies, ascending
    // 2. if union > 130 dates: keep last date per ISO week + always the final date
    // 3. per strategy: map date -> Number(edge_dollars_cum); forward-fill onto kept dates;
    //    0 before the strategy's first date (fully parked = edge $0 by construction)
    const dt = Charts.newDataTable().addColumn(Charts.ColumnType.DATE, 'Date');
    dt.addColumn(Charts.ColumnType.NUMBER, 'SGOV park');            // FIRST: draws under strategies
    deployedStrategies.forEach(s => dt.addColumn(Charts.ColumnType.NUMBER, 'Strategy ' + s));
    keptDates.forEach(iso => {
      const p = iso.split('-').map(Number);                          // 'YYYY-MM-DD'
      const jsDate = new Date(p[0], p[1] - 1, p[2]);                 // LOCAL midnight, not UTC
      dt.addRow([jsDate, 0].concat(deployedStrategies.map(s => filled[s][iso])));
    });
    const chart = Charts.newLineChart().setDataTable(dt.build())
      .setColors([SGOV_GRAY].concat(deployedStrategies.map(s => COLORS[s])))
      .setDimensions(1120, 400)
      .setLegendPosition(Charts.Position.BOTTOM)
      .setPointStyle(Charts.PointStyle.NONE)
      .setBackgroundColor('#fffffe')
      .setYAxisTitle('$ vs park')
      .build();
    return { blob: chart.getAs('image/png').setName('strategies_vs_park.png'),
             altText: 'Cumulative dollar edge vs SGOV park: ' + /* 'B +$10.67, D −$1.46' from data */ };
  } catch (e) { Logger.log('chart build failed, using HTML fallback: ' + e); return null; }
}
```

and in the send path:

```javascript
const opts = { htmlBody: html, name: SENDER_NAME };
if (chartResult) opts.inlineImages = { parkchart: chartResult.blob };
GmailApp.sendEmail(RECIPIENT, subject, plain, opts);
```

with `<img src="cid:parkchart" width="560" alt="..." style="width:100%;max-width:560px;height:auto;display:block;">`
present in the HTML **iff** the blob exists (build the HTML after the chart attempt so
the img tag and the blob can never disagree), else the HTML bar fallback rows (§1.4).
Keep the chart build INSIDE its own try/catch and OUTSIDE `bq_()`'s fail-loudly rule:
bad data must still abort the send; a bad chart must not.

**Dark-mode hygiene:** switch the card/table surfaces from today's pure `#ffffff` to
`#fffffe` and keep near-black text `#0f2747`/`#1f2d3d`; do not introduce pure
`#ffffff`/`#000000` anywhere. No `@media` queries (Gmail strips them).

**HTML size guard:** the new email is far smaller than the old one; keep raw HTML well
under 102KB (Gmail clipping threshold — cid image bytes don't count).

### Step 3 — `ops/weekly_report/appsscript.json` scope fix

Change `https://www.googleapis.com/auth/bigquery.readonly` →
`https://www.googleapis.com/auth/bigquery`. The script performs DML (the heartbeat
INSERT); the deployed project evidently holds a broader grant than the checked-in
manifest, but a fresh deploy from this manifest would silently kill the heartbeat
(try/catch-wrapped) and fire a critical `automation_heartbeat` alarm ~9 days later.
All other scopes/settings unchanged. Known-and-accepted residual (record in the RUNBOOK
entry, do not fix): the checked-in Gmail scopes (`gmail.send` + `gmail.labels`) are also
insufficient for the label step's `GmailApp.search`/`addLabel` on a fresh deploy — that
failure is cosmetic-only (labeling), try/catch-wrapped, and not worth broadening to
`mail.google.com` scope.

### Step 4 — dbt parity

- **Mirror the `deployed_capital` column** in `dbt/models/analytics/strategy_daily_returns.sql`
  (identical expression; it has a live twin and the parity job diffs matching names —
  a column-set mismatch silently drops the model from parity coverage, which we don't
  want on an engine-feeding view).
- **Add twins** `dbt/models/analytics/strategy_vs_park_daily.sql` and
  `strategy_vs_park.sql` (translate table refs to `ref()`/`source()` exactly as the
  neighboring models do — `ref('strategy_daily_returns')`, `ref('sgov_daily_return')`,
  `ref('trade_fills_curated')`; header comment
  `-- Parallel-run dbt port of bigquery/21_strategy_vs_park.sql:<name> — canonical source
  is that file until owner cutover.`). Also add `park_baseline.sql`
  (`ref('strategy_vs_park_daily')` + `ref('sgov_daily_return')` + `ref('strategy_nav')`).
- **`dbt/models/analytics/schema.yml`:** add entries — `strategy_vs_park_daily`
  (`unique_combination_of_columns(as_of_date, strategy)`; `strategy` accepted_values
  A–E), `strategy_vs_park` (`strategy` unique + not_null + accepted_values A–E),
  `park_baseline` (column docs only). Column descriptions: one line each, in the file's
  existing voice.
- While in there, fix the stale claim in `schema.yml`'s `strategy_scorecard` description
  ("weekly self-email + dashboard" → the dashboard does not read it; email only). Same
  fix for the comment at `bigquery/14_weekly_report.sql:21`.
- Run `cd dbt && dbt deps && dbt parse` with the offline profile exactly as
  `.github/workflows/ci.yml`'s `dbt` job does (it is blocking CI). Must pass.

### Step 5 — the now-orphaned email views: keep, annotate, do not drop

`analytics.weekly_activity`, `analytics.weekly_fills`, `analytics.weekly_nogos`,
`state.open_positions_summary`, `state.next_7_days`, `state.account_latest`,
`state.account_nav_7d_ago`, and table `ops.account_snapshot` (+ D2 Step 0b) all stay —
**dropping or renaming anything the deployed .gs still reads would break the LIVE email
during the window between merge and the owner re-pasting the script** (the deployed
scorecard query uses an explicit column list; the old script keeps running until
re-paste). Also `account_latest`/`weekly_activity` have dbt twins and D2 writes the
snapshot table per `Claude_Task_Plan.md` L508 — none of that churns in this redesign.

Repo-text annotations (comments only, no live DDL):

- Update the header comment of `bigquery/14_weekly_report.sql`: as of this redesign the
  weekly email reads only `strategy_scorecard` (+ the `21_strategy_vs_park.sql` views);
  the other objects in the file are retained for RUNBOOK verification, history, and
  possible future use — an actual drop/cleanup is a separate, later decision (explicitly
  out of scope here).
- Also retag these four stale "weekly self-email" references as "retained; no longer read
  by the weekly email (2026-07 redesign)": `dbt/models/state/schema.yml` (`account_latest`
  description), `dbt/models/analytics/schema.yml` (`weekly_activity` description),
  `dbt/models/analytics/weekly_activity.sql` header comment, and the two body comments in
  `bigquery/14_weekly_report.sql` (the `ops.account_snapshot` OPTIONS description text —
  repo text only, no live `ALTER TABLE SET OPTIONS` needed — and the
  "the .gs file does SELECT *" convention note above `weekly_fills`).

### Step 6 — docs

1. **`ops/weekly_report/README.md`** — rewrite: new purpose paragraph (the one question),
   new data-sources table (`strategy_scorecard`, `strategy_vs_park`,
   `strategy_vs_park_daily`, `park_baseline`, `system_health`, `user_tz`), chart
   mechanism note (Charts service PNG via cid; HTML-bar fallback), unchanged setup steps,
   plus an explicit "Owner actions to deploy this redesign" list: re-paste `.gs`, update
   the manifest scope (Project Settings → show appsscript.json → replace), run
   `testReport()` and re-approve the consent screen (scope changed), **confirm the email
   contains the line-chart PNG, not the HTML bar fallback** (a bars-only email means the
   chart build is failing — check the Apps Script execution log), done — trigger
   unchanged.
2. **`ops/weekly_report/sample_preview.html`** — regenerate to the new design with
   static data **matching the live-verified design-time values**: B `BEATING PARK`
   +$10.67 (comm. $4.83), D `≈ EVEN WITH PARK` −$1.46, A/C/E `NOT DEPLOYED`, hero +$9.22,
   park ≈$62. For the chart, embed a simple static placeholder (a gray-bordered div with
   the section header and caption) — do not fake a PNG.
3. **`ops/RUNBOOK.md`** — new dated section **§33** (last existing is §32 as of
   2026-07-02; renumber if the RUNBOOK has grown): what changed and why (the owner's
   one-question directive + the sleeve-level clarification), the sleeve-edge formula and
   why it equals the deployed slice's dollar excess (park absorbs the rest), the recorded
   chart rationale from §1.4, the neutral-band verdict rule, the additive SQL applied
   live, the scope fix rationale + the accepted Gmail-scope residual (Step 3), the deploy
   order (SQL applied → merge → owner re-paste; old email keeps working meanwhile), what
   was deliberately dropped from the email and where that information still lives
   (dashboard, DTS failure emails, Daily.md), a note that the owner may want to
   re-confirm the gross-of-commissions convention specifically for this counterfactual
   question (the 2026-06-05 directive predates it; the neutral band is the interim
   mitigation), a note that `analytics.strategy_unit_value_7d_ago` carries the same
   missing-tie-break latent flaw the new view fixed (follow-up candidate, not urgent),
   and the "do not re-add dropped sections without an owner ask" line. Update the stale
   `run bigquery/01..18_*.sql` line (RUNBOOK L47) to `01..21`; **leave** the `01..13`
   mention at L391 (quoted historical decision rationale, not a living instruction).
4. **`bigquery/README.md`** — add Layout one-liners for `21_strategy_vs_park.sql` and the
   currently-missing `14_weekly_report.sql` and `19_stack_review_fixes_2.sql`; add a
   Schema-quick-reference row for `analytics.strategy_vs_park`.
5. **`ops/cadence.yaml`** — in the NON-CLAUDE AUTOMATION comment block (~L193-201):
   update the view list the weekly email reads AND rewrite the now-false dependency
   sentence ("The only Claude-side dependency is D2 Step 0b writing ops.account_snapshot
   …") to say D2 Step 0b still writes `ops.account_snapshot` (history/dashboard use) but
   the weekly email no longer reads it — its data dependencies are the D2-maintained
   marks/engine views. Comments only; do not touch `routines:` entries (the
   cadence-consistency CI gate parses those).

### Step 7 — tests / CI verification before pushing

- `python -m pytest tests/` (offline; guards cadence-consistency + dbt_parity helpers —
  should be untouched by this change, so any failure means you broke a convention).
- `cd dbt && dbt deps && dbt parse` (blocking CI job equivalent).
- `python scripts/check_cadence_consistency.py` if it runs standalone (the `test` CI job
  runs it) — must stay green; this change touches cadence.yaml comments only.
- Confirm the heartbeat source string is untouched: `grep -n "weekly_report" bigquery/16_automation_health.sql ops/weekly_report/weekly_report.gs`.
- Backward-compat check: none of the 14 views in Step 2's "Queries to DELETE" list, nor
  the 8 scorecard columns the OLD deployed .gs selects (see
  `git show HEAD:ops/weekly_report/weekly_report.gs`, L96-100), may be dropped, renamed,
  or type-changed by your diff.
- Eyeball `sample_preview.html` in a browser (layout, no horizontal scroll at 600px).

### Step 8 — commit & push

Branch `claude/weekly-report-redesign-875a6w` (already exists and is checked out).
Logical commits are fine (SQL+dbt, .gs+manifest, docs+preview) or one commit —
implementer's choice. Push with `git push -u origin claude/weekly-report-redesign-875a6w`
(retry on network errors with backoff). Do NOT open a PR unless the owner asks.

## 3. Hard constraints — violating any of these is a defect

1. **Backward compatibility until owner re-paste:** no existing view/column that the
   currently-deployed .gs queries may be dropped, renamed, or type-changed. All SQL in
   this redesign is strictly additive (one added column + three new views).
2. **Heartbeat contract:** exact source string `'weekly_report'`; INSERT only after a
   successful send; failed sends must abort loudly (no heartbeat) — that IS the alarm.
3. **Fail-loudly `bq_()`:** never render silently-empty data on a failed/incomplete query.
   The chart is the one exception (its failure falls back to HTML bars, never blocks).
4. **Timezone two-plane rule:** SQL windows anchored to `America/Denver` only;
   `state.user_tz` is display-only. Parse `YYYY-MM-DD` strings with local-midnight
   construction, never `new Date('YYYY-MM-DD')` (UTC shift).
5. **Settled decisions:** metrics stay GROSS of commissions (the neutral band and per-row
   commission subtext are the mitigations; no "net edge" headline or column). No
   per-strategy SGOV holdings anywhere (SGOV is account-level; RUNBOOK §29). No
   Terraform. Experiment parameters/thresholds are immutable — this changes what is
   REPORTED, never what is MEASURED for kill/gate.
6. **Chart identity colors are fixed** per the §1.4 table — never reassigned by rank,
   presence, or performance. SGOV baseline is always the gray zero line, drawn first.
7. **A/C/E render as NOT DEPLOYED ($0.00 by construction), never as losing/0%/red.**
8. **Gmail constraints:** no SVG, no data-URI images, no `<style>` blocks/media queries,
   no external image URLs — cid inline PNG + inline styles only.
9. **No new OAuth scopes beyond the §Step-3 fix** (Charts service needs none;
   `script.external_request` must NOT appear).
10. **`analytics.strategy_scorecard` view SQL and its dbt twin are untouched** (the .gs
    reads fewer columns from it; derive gate-✓ in JS from `closed_trades`, never by
    adding columns to that SELECT).

## 4. Acceptance criteria

- [ ] New views live in BigQuery and return the §Step-1d expected bands/signs, including
      the edge≠commissions cross-check.
- [ ] `.gs` compiles conceptually (valid V8 JS), gathers only §Step-2 queries, renders:
      subject with per-deployed-strategy verdicts (signed $ or ≈even); hero combined edge
      + park-scale subline; chart (or fallback bars) with fixed identity colors, gray
      zero line drawn first; 5-row verdict table with §1.0 chips incl. NOT DEPLOYED
      reasons and JS-derived gate ✓; commissions in row subtext; methodology footnote;
      plain-text mirror; heartbeat + updated label search + trigger intact.
- [ ] `appsscript.json` carries the full `bigquery` scope.
- [ ] `dbt parse` passes; parity twins updated/added; schema.yml entries + stale-comment
      fixes in.
- [ ] `pytest tests/` green; cadence consistency green.
- [ ] README/RUNBOOK §33/bigquery-README/cadence-comment updated; preview regenerated
      with the verified example values.
- [ ] Everything committed and pushed to `claude/weekly-report-redesign-875a6w`; no PR.
- [ ] Backward-compat check from Step 7 passed (nothing the deployed old .gs reads was
      dropped/renamed).

## 5. Explicit non-goals

- Dropping the orphaned views / `ops.account_snapshot` / D2 Step 0b (later decision).
- Any change to the TWR engine's semantics, kill thresholds, or the 30-trade gate.
- A rolling-12-month M2M window view (spec-noted gap, separate work).
- Post-tax / post-inflation adjustments (label as nominal instead).
- Fixing `analytics.strategy_unit_value_7d_ago`'s missing tie-break (noted in RUNBOOK
  §33 as a follow-up candidate; it feeds a column the new email no longer displays).
- Broadening Gmail scopes for the label step (accepted cosmetic residual, Step 3).
- Testing the actual Apps Script send (Claude cannot reach script.google.com — the owner
  runs `testReport()` per the README's deploy list and confirms the PNG chart rendered).
