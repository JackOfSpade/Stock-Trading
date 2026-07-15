# Weekly performance self-email — "Deployed vs Benchmarks"

A weekly HTML email that answers one question: **what's each strategy's own return been**,
measured on **deployed capital only, over active (deployed) time only** — with VOO's own
return shown alongside as a single informational reference point. (2026-07-15 redesign,
owner directive — see `ops/RUNBOOK.md` §33 for the full iteration history. The prior v2
design, 2026-07-13, compared everything to SGOV; this directive dropped SGOV from the email
entirely and made VOO the sole displayed benchmark.) Everything that didn't support that
question — regime, account NAV/MTD/YTD, open positions, next-7-days, weekly activity, the
full ops-health strip, and (as of v3) the "Deployed Book Since..." headline block — was cut.
What's left: a **returns chart** (each deployed strategy's cumulative total return + VOO's
own cumulative return, each plotted as its own natural, non-rebased line), a **table**
("Average Return") of each strategy's **own average return per month / year** — a geometric
per-period rate measured over **active (deployed) time only**, so idle stretches never
dilute it ("Not enough data" until at least 21 deployed days exist), with a VOO own-return
row for reference, and a one-line data-trust warning that only appears when something is
actually stale.

**VOO is purely informational** — it never feeds `perf.kill_flags` or any other live
decision surface. SGOV remains the sanctioned kill/gate benchmark internally
(`perf.strategy_daily.excess_vs_sgov`) — this email simply no longer *displays* that
comparison; the kill/gate machinery itself is untouched by the 2026-07-15 directive (see
`events.decision_log`, 2026-07-15).

## Why it's an Apps Script and not a Claude routine

The official **Gmail connector can only create drafts, not send.** So a Claude remote
routine could only pile up drafts. Instead, delivery is owned by a **Google Apps Script**
(`weekly_report.gs`) that runs on **Google's servers** as you, on its own weekly trigger —
completely independent of Claude's remote-routine server.

Because you are **both sender and recipient** (from you, to you), this is the optimal design:

- Apps Script runs **as your Google account**, so `GmailApp.sendEmail()` needs **no SMTP
  server, no app password, no API key, and no separate sender identity** (which SendGrid or
  an external mailer would all require).
- It **builds the HTML and sends in one shot** — nothing ever lands in Drafts.
- All report data already lives in **BigQuery**, so the script reads it directly. **No Claude
  involvement at send time**, and no dependency on any routine having run that week.
- The chart is built server-side via the Apps Script **Charts service**
  (`Charts.newLineChart()`) and embedded as an inline `cid:` PNG attachment — Gmail supports
  no inline SVG and no `data:` URI images, so a `cid` attachment is the only self-contained
  image route. If the chart build ever throws, the script falls back to plain HTML bar rows
  (left-anchored, colored by verdict) so the email never fails to send over a chart problem.

```
  BigQuery (views the trading routines maintain)
        │  read (BigQuery API, as owner)
        ▼
  Apps Script  weekly_report.gs   ── on Google's servers, weekly trigger
        │  GmailApp.sendEmail(you → you), chart as inline cid PNG
        ▼
  Your inbox   (labelled "Trading/Weekly", forced unread — see below)
```

**Note — self-sent mail lands pre-marked read.** Because sender and recipient are the same
account, Gmail treats the send action itself as the read event, so the message would
otherwise appear in the inbox already read (no bold/unread indicator). The script forces it
back to unread (`GmailThread.markUnread()`) in the same post-send lookup that applies the
label — best-effort, so it never blocks the send if it fails.

## One-time setup (~3 minutes)

1. Go to **script.google.com** → **New project**. Name it `Stock-Trading Weekly Report`.
2. Delete the stub `Code.gs` content and **paste in `weekly_report.gs`** (this folder).
3. **Add the BigQuery service:** in the editor left rail click **Services (+)** → pick
   **BigQuery API** → **Add** (the identifier must be `BigQuery`).
4. **Project Settings** → tick *Show "appsscript.json"* and paste in the manifest from
   `appsscript.json` here (V8 runtime + the OAuth scopes — the BigQuery scope is the
   read/write `bigquery` scope, not `bigquery.readonly`, since the script writes a heartbeat
   row; the Gmail scope is `gmail.modify` + `gmail.send`, since the label step reads/searches
   threads, not just `gmail.labels`, which only covers label CRUD). The Charts service needs
   no manifest entry — it's a built-in service, not an advanced one.
5. Edit the `CONFIG` block at the top of the script:
   - `RECIPIENT` defaults to your own address (`Session.getActiveUser().getEmail()`); hardcode
     `jacksterwu@gmail.com` if you prefer.
   - `SEND_HOUR` / `SEND_WEEKDAY` — when the weekly email goes out (default Sunday 07:00,
     **script timezone**; set the project timezone in Project Settings, e.g. America/Denver).
6. Select function **`testReport`** → **Run**. Approve the **BigQuery + Gmail** permissions
   when prompted (one time). Confirm the email arrives in your inbox.
7. Select function **`installWeeklyTrigger`** → **Run** once. Done — it now emails you weekly,
   forever. (Re-running it is safe; it de-dupes its own trigger.)

**Owner actions to deploy this redesign onto an already-installed script:** re-paste
`weekly_report.gs` over the existing project; update the manifest scope (step 4 above —
`bigquery.readonly` → `bigquery`, `gmail.labels` → `gmail.modify`); run `testReport()` and
re-approve the consent screen (the scope changed, so Google will re-prompt); **confirm the
email contains the line-chart PNG, not the HTML bar fallback** (a bars-only email means the
chart build is failing — check the Apps Script execution log, `View → Executions`). The
weekly trigger itself is unchanged, so `installWeeklyTrigger` does not need to be re-run.
Deployed 2026-07-02/03 — see `ops/RUNBOOK.md` §33 for the live verification notes and the
follow-up `gmail.modify` scope fix.

**Owner actions to deploy the 2026-07-13 VOO redesign (v2):** apply
`bigquery/46_weekly_benchmarks.sql` live (creates `analytics.voo_daily_return`,
`voo_cumulative`, `deployed_book_vs_benchmarks`) — the VOO one-time price backfill into
`events.daily_marks` must land BEFORE this, or the new views simply compute with zero VOO
rows (the email correctly renders "Not enough data" for VOO in that case, never a false
`+0.00%`, but the chart will be VOO-less until the backfill is applied). Then re-paste
`weekly_report.gs` (SCRIPT_VERSION `'v2'`) and run `testReport()` — no new OAuth scope
needed (read-only addition). Also re-apply `bigquery/43_script_version_registry.sql`'s MERGE
so `state.script_version_drift` expects `'v2'`, not `'v1'`.

**Owner actions to deploy the 2026-07-15 SGOV-removal redesign (v3):** no new BigQuery views
needed — everything v3 reads already existed (`analytics.strategy_vs_park_daily`,
`analytics.voo_cumulative`). Re-paste `weekly_report.gs` (SCRIPT_VERSION `'v3'`) via the
commit-SHA-pinned GitHub raw URL method (a large rewrite — dozens of functions changed, so a
direct chat/artifact paste risks corruption) and run `testReport()` — no new OAuth scope
needed. Re-apply `bigquery/43_script_version_registry.sql`'s MERGE so
`state.script_version_drift` expects `'v3'`, not `'v2'`. Confirm the sent email: no "Deployed
Book Since..." section, no SGOV anywhere (subject line, chart, table, footer), the table
retitled "Average Return", and the chart showing only strategy lines + a VOO line.

To change the schedule later, edit `SEND_HOUR`/`SEND_WEEKDAY` and run `installWeeklyTrigger`
again. To stop, delete the trigger (clock icon in the editor) or the project.

## Data sources (all BigQuery, project `stock-trading-498512`)

| View / table | Feeds |
|---|---|
| `analytics.strategy_scorecard` | the A–E list + activation string (for the "not deployed" reason) |
| `analytics.strategy_vs_park_daily` | per strategy-day: `deployed_unit_value` — each strategy's own cumulative return (the chart's strategy lines AND, as of v3, the table's per-strategy average-return figures). A row exists only on deployed days, so idle time never dilutes the average. |
| `analytics.voo_cumulative` | VOO's own cumulative total return per day, its own date axis from its own first observed mark; NULL before that mark (the chart's VOO line + the table's VOO own-return row) |
| `state.system_health` | marks/engine freshness + firing kill-flags + critical alerts — the one surviving data-trust signal |
| `state.user_tz` | detected DISPLAY timezone (never the operating/trading-day timezone) |
| `perf.kill_flags` / `ops.alerts` | queried lazily, only when `state.system_health` flags something |

The SQL for `strategy_vs_park_daily` lives in `bigquery/21_strategy_vs_park.sql`; the VOO
benchmark views (`voo_daily_return`, `voo_cumulative`) live in
`bigquery/46_weekly_benchmarks.sql` (2026-07-13, owner directive — single-sourced,
version-controlled). `deployed_unit_value` comes from `perf.strategy_daily` (the deployed-TWR
engine, `bigquery/03_twr_engine.sql`).

### What the numbers mean (2026-07-15)

Everything is an **actual total return** — a strategy's own, or VOO's own — as percentages,
never a comparison to SGOV:

- **Chart** — each deployed strategy's cumulative total return since its first deployment
  (`deployed_unit_value − 1`) and VOO's own cumulative total return (`voo_cumulative`, from
  VOO's own first observed mark) — each its own natural line, never rebased to line up with
  any other series' start date.
- **Table ("Average Return")** — per strategy, its **own average return** per month / year —
  a geometric per-period rate over the strategy's **active (deployed) days only**:
  `(1 + return_latest) ^ (tradingDaysPerPeriod / deployedDays) − 1`, with
  `TRADING_DAYS_PER = {month:21, year:252}` and `return_latest` = `deployed_unit_value − 1`
  (the strategy's own cumulative return — no SGOV comparison anywhere in this calculation).
  `strategy_vs_park_daily` has a row only for deployed days, so idle days are absent and never
  dilute the average toward 0 — this table shows return on **deployed capital only**, never
  diluted by idle/parked capital. "Not enough data" shows when the strategy has fewer than 21
  deployed days (below that, not even a monthly average is meaningful — this floor is also why
  per-week reporting was dropped in the 2026-07 redesign). A separate **VOO row** shows VOO's
  own average return per period, for reference only.

Returns are gross of commissions (the sanctioned profitability convention); VOO's return is
its actual total return including dividends. Strategies with no deployed history (A/C/E
currently) show "not deployed" — there is no strategy return to compare.

### Views retained but no longer read by the email

`analytics.weekly_activity`, `analytics.weekly_fills`, `analytics.weekly_nogos`,
`state.open_positions_summary`, `state.next_7_days`, `state.account_latest`,
`state.account_nav_7d_ago`, and the `ops.account_snapshot` table (+ D2 Step 0b, which still
writes it daily) are kept in BigQuery for RUNBOOK verification, dashboard/history use, and
possible future use — dropping them is a separate, later decision. See the header comment
in `bigquery/14_weekly_report.sql`. Also retained but no longer read by the email:
`analytics.strategy_vs_park` (dollar edge + commissions), `analytics.deployed_book_vs_sgov`
(the short-lived combined-% hero, 2026-07-03), `analytics.park_baseline` (the dollar-era hero
scale anchor), and, as of the 2026-07-15 redesign, `analytics.sgov_cumulative` (the chart's
former SGOV line) and `analytics.deployed_book_vs_benchmarks` (the former "Deployed Book
Since..." headline block, dropped entirely — see `events.decision_log`, 2026-07-15).

## Notes

- The subject line includes the date, so weekly reports **don't thread together** in Gmail.
- The received copy is auto-labelled `Trading/Weekly` (set `LABEL_NAME=''` to disable) — the
  label search string is coupled to the subject format; if you change the subject prefix,
  update the `GmailApp.search(...)` call in `sendWeeklyReport_` to match.
- Preview the design any time by opening `ops/weekly_report/sample_preview.html` in a browser
  (the chart is a static placeholder there — the real email renders an actual PNG). Regenerated
  for v3 (SGOV removal) on 2026-07-15 — a prior redesign cycle (2026-07-13's VOO rewrite) let
  this file drift for a full cycle because that entry's checklist omitted the regeneration
  step; regenerate it again (by hand, matching `buildHtml_`'s current output) any time the
  email's HTML structure changes, in the SAME commit.
