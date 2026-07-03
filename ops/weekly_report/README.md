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
| `analytics.strategy_scorecard` | activation string (for the NOT-DEPLOYED reason + kill-flag flag), NAV (alloc), deployed MV, excess-vs-SGOV %, closed trades |
| `analytics.strategy_vs_park` | latest cumulative $ edge vs the SGOV park per ever-deployed strategy, its 7-day change, first-deployed date, commissions to date |
| `analytics.strategy_vs_park_daily` | the chart's daily $ edge series |
| `analytics.park_baseline` | what parking everything would have earned over the same window — the hero tile's scale anchor |
| `state.system_health` | marks/engine freshness + firing kill-flags + critical alerts — the one surviving data-trust signal |
| `state.user_tz` | detected DISPLAY timezone (never the operating/trading-day timezone) |
| `perf.kill_flags` / `ops.alerts` | queried lazily, only when `state.system_health` flags something |

The SQL for the new views lives in `bigquery/21_strategy_vs_park.sql` (single-sourced,
version-controlled); `analytics.strategy_scorecard` and the `deployed_capital` column it
was extended with live in `bigquery/03_twr_engine.sql` and `bigquery/14_weekly_report.sql`.

### What the $ edge means

`analytics.strategy_vs_park_daily.edge_dollars_cum` is the cumulative dollar difference
between what a strategy's deployed capital actually earned and what those same dollars
would have earned sitting in the SGOV park instead — summed over the strategy's own
deployed days. Because undeployed sleeve cash already sits in the account-level SGOV park
(the per-strategy SGOV split is formally dissolved — see `ops/RUNBOOK.md` §29), this
dollar figure answers the sleeve-level question directly: a strategy that has never
deployed shows `$0.00 — NOT DEPLOYED`, not a loss, because its allocation IS the park.
`analytics.strategy_scorecard.excess_vs_sgov` (the deployed-TWR percentage) is shown too,
as a secondary column tied to the kill/gate machinery — it measures intensity on the
deployed slice only, not the sleeve-level dollar answer.

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
