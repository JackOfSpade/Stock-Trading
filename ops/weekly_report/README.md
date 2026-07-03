# Weekly performance self-email — "Strategies vs SGOV"

A weekly HTML email that answers exactly one question: **is each strategy beating just
parking the cash it was allocated in SGOV?** (2026-07 redesign — see `ops/RUNBOOK.md` §33
for the full rationale.) Everything that didn't support that question — regime, account
NAV/MTD/YTD, open positions, next-7-days, weekly activity, the full ops-health strip — was
cut. What's left: a hero combined-edge figure, a line chart (one series per ever-deployed
strategy, plotted as cumulative $ vs the SGOV park baseline), a 5-row verdict table, and a
one-line data-trust warning that only appears when something is actually stale.

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
  Your inbox   (labelled "Trading/Weekly")
```

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

To change the schedule later, edit `SEND_HOUR`/`SEND_WEEKDAY` and run `installWeeklyTrigger`
again. To stop, delete the trigger (clock icon in the editor) or the project.

## Data sources (all BigQuery, project `stock-trading-498512`)

| View / table | Feeds |
|---|---|
| `analytics.strategy_scorecard` | activation string (for the NOT-DEPLOYED reason + kill-flag flag), NAV (alloc), deployed MV, **deployed-slice excess-vs-SGOV %** (the primary per-strategy number), closed trades |
| `analytics.deployed_book_vs_sgov` | the hero headline: combined **value-weighted** deployed-book excess % (+ book/SGOV return legs) |
| `analytics.strategy_vs_park_daily` | the chart's daily series — **excess %** (primary, the y-axis) + cumulative $ edge (secondary/for-scale) |
| `analytics.strategy_vs_park` | latest $ edge + commissions + first-deployed date per ever-deployed strategy (the secondary "$ for scale" figures) |
| `state.system_health` | marks/engine freshness + firing kill-flags + critical alerts — the one surviving data-trust signal |
| `state.user_tz` | detected DISPLAY timezone (never the operating/trading-day timezone) |
| `perf.kill_flags` / `ops.alerts` | queried lazily, only when `state.system_health` flags something |

The SQL for these views lives in `bigquery/21_strategy_vs_park.sql` (single-sourced,
version-controlled); `analytics.strategy_scorecard` and the `deployed_capital` column it
was extended with live in `bigquery/03_twr_engine.sql` and `bigquery/14_weekly_report.sql`.

### What the numbers mean (percentage primary, 2026-07-03)

The headline and chart are **percentages** — the deployed-slice excess return vs SGOV
(`perf.strategy_daily.excess_vs_sgov` = deployed-TWR unit value ÷ SGOV index − 1, over the
strategy's own deployed days; the sanctioned kill/gate metric). This is the return on the
capital actually put to work — the honest "is this strategy any good" number — not a
sleeve-level % (which, with ~98% of the sleeve parked, would dilute to ~0.7% and hide the
signal). The hero's combined figure (`deployed_book_vs_sgov`) value-weights every deployed
strategy into one book, because percentages don't sum.

The **dollar** edge (`strategy_vs_park_daily.edge_dollars_cum` = deployed dollars × (deployed
return − SGOV total return), summed over deployed days) is kept as a small **secondary
"for scale"** figure under each row and in the hero subline. It answers the same question at
sleeve level: undeployed sleeve cash already sits in the account-level SGOV park (the
per-strategy SGOV split is formally dissolved — see `ops/RUNBOOK.md` §29), so a strategy
that has never deployed sits at 0% / $0 — `NOT DEPLOYED`, not a loss, because its allocation
IS the park.
`analytics.strategy_scorecard.excess_vs_sgov` is that same deployed-slice percentage as of
the latest close — the per-strategy verdict number and the metric the kill/gate machinery
already runs on.

### Views retained but no longer read by the email

`analytics.weekly_activity`, `analytics.weekly_fills`, `analytics.weekly_nogos`,
`state.open_positions_summary`, `state.next_7_days`, `state.account_latest`,
`state.account_nav_7d_ago`, and the `ops.account_snapshot` table (+ D2 Step 0b, which still
writes it daily) are kept in BigQuery for RUNBOOK verification, dashboard/history use, and
possible future use — dropping them is a separate, later decision. See the header comment
in `bigquery/14_weekly_report.sql`.

## Notes

- The subject line includes the date, so weekly reports **don't thread together** in Gmail.
- The received copy is auto-labelled `Trading/Weekly` (set `LABEL_NAME=''` to disable) — the
  label search string is coupled to the subject format; if you change the subject prefix,
  update the `GmailApp.search(...)` call in `sendWeeklyReport_` to match.
- Preview the design any time by opening `ops/weekly_report/sample_preview.html` in a browser
  (the chart is a static placeholder there — the real email renders an actual PNG).
