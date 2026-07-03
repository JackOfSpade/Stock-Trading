# Weekly performance self-email — "Strategies vs SGOV"

A weekly HTML email that answers exactly one question: **is each strategy beating SGOV?**
(2026-07 redesign — see `ops/RUNBOOK.md` §33 for the full rationale and the iteration
history.) Everything that didn't support that question — regime, account NAV/MTD/YTD, open
positions, next-7-days, weekly activity, the full ops-health strip — was cut. What's left:
a **returns chart** (each deployed strategy's cumulative total return + a gray SGOV line),
a **table** of each strategy's **average return vs SGOV per week / month / year** — a
geometric per-period rate measured over **active (deployed) time only**, so idle stretches
never dilute it ("Not enough data" until that much deployed history exists) with an SGOV
own-return row, and a one-line data-trust warning that only appears when something is
actually stale. No combined aggregate, no verdict labels, no dollar figures.

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
| `analytics.strategy_scorecard` | the A–E list + activation string (for the "not deployed" reason) |
| `analytics.strategy_vs_park_daily` | per strategy-day: `deployed_unit_value` (the chart's return lines) + cumulative `excess_vs_sgov` (the `.gs` turns the latest value into an average vs-SGOV return per week/month/year over the strategy's deployed days) |
| `analytics.sgov_cumulative` | SGOV's own cumulative total return per day (the chart's SGOV line + its own average return per week/month/year) |
| `state.system_health` | marks/engine freshness + firing kill-flags + critical alerts — the one surviving data-trust signal |
| `state.user_tz` | detected DISPLAY timezone (never the operating/trading-day timezone) |
| `perf.kill_flags` / `ops.alerts` | queried lazily, only when `state.system_health` flags something |

The SQL for these views lives in `bigquery/21_strategy_vs_park.sql` (single-sourced,
version-controlled); the `deployed_unit_value` / `excess_vs_sgov` columns come from
`perf.strategy_daily` (the deployed-TWR engine, `bigquery/03_twr_engine.sql`).

### What the numbers mean (2026-07-03)

Everything is an **actual total return** or a **return vs SGOV**, both as percentages:

- **Chart** — each deployed strategy's cumulative total return since its first deployment
  (`deployed_unit_value − 1`) and SGOV's own cumulative total return (`sgov_cumulative`),
  each a line. SGOV is a real gray line, not a flat baseline.
- **Table** — per strategy, the **average return *above SGOV* per week / month / year** — a
  geometric per-period rate over the strategy's **active (deployed) days only**:
  `(1 + excess_latest) ^ (tradingDaysPerPeriod / deployedDays) − 1`, with
  `TRADING_DAYS_PER = {week:5, month:21, year:252}` and `excess_vs_sgov` = deployed-TWR unit
  value ÷ SGOV index − 1 (the sanctioned kill/gate metric). `strategy_vs_park_daily` has a row
  only for deployed days, so idle days are absent and never dilute the average toward 0.
  "Not enough data" shows when the strategy has fewer deployed days than the period (so 1-year
  reads "Not enough data" until ~252 deployed days exist). A separate **SGOV row** shows
  SGOV's *own* average return per period over the same active window.

Returns are gross of commissions (the sanctioned profitability convention); SGOV is its
actual total return including its monthly dividends. Strategies with no deployed history
(A/C/E currently) show "not deployed" — their cash is held in SGOV, so there is no
strategy return to compare.

### Views retained but no longer read by the email

`analytics.weekly_activity`, `analytics.weekly_fills`, `analytics.weekly_nogos`,
`state.open_positions_summary`, `state.next_7_days`, `state.account_latest`,
`state.account_nav_7d_ago`, and the `ops.account_snapshot` table (+ D2 Step 0b, which still
writes it daily) are kept in BigQuery for RUNBOOK verification, dashboard/history use, and
possible future use — dropping them is a separate, later decision. See the header comment
in `bigquery/14_weekly_report.sql`. Also retained but no longer read by the email after the
2026-07-03 iterations: `analytics.strategy_vs_park` (dollar edge + commissions),
`analytics.deployed_book_vs_sgov` (the short-lived combined-% hero), and
`analytics.park_baseline` (the dollar-era hero scale anchor).

## Notes

- The subject line includes the date, so weekly reports **don't thread together** in Gmail.
- The received copy is auto-labelled `Trading/Weekly` (set `LABEL_NAME=''` to disable) — the
  label search string is coupled to the subject format; if you change the subject prefix,
  update the `GmailApp.search(...)` call in `sendWeeklyReport_` to match.
- Preview the design any time by opening `ops/weekly_report/sample_preview.html` in a browser
  (the chart is a static placeholder there — the real email renders an actual PNG).
