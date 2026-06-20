# Weekly performance self-email

A weekly HTML "infographic" digest of how the trading system is doing — regime, which
strategies are active/inactive, per-strategy budget + deployed performance, this week's
activity, and ops health — emailed to you automatically every week.

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

```
  BigQuery (views the trading routines maintain)
        │  read (BigQuery API, as owner)
        ▼
  Apps Script  weekly_report.gs   ── on Google's servers, weekly trigger
        │  GmailApp.sendEmail(you → you)
        ▼
  Your inbox   (labelled "Trading/Weekly")
```

## One-time setup (~3 minutes)

1. Go to **script.google.com** → **New project**. Name it `Stock-Trading Weekly Report`.
2. Delete the stub `Code.gs` content and **paste in `weekly_report.gs`** (this folder).
3. **Add the BigQuery service:** in the editor left rail click **Services (+)** → pick
   **BigQuery API** → **Add** (the identifier must be `BigQuery`).
4. (Optional) **Project Settings** → tick *Show "appsscript.json"* and confirm the manifest
   matches `appsscript.json` here (V8 runtime + the OAuth scopes). The default V8 runtime is fine.
5. (Optional) Edit the `CONFIG` block at the top of the script:
   - `RECIPIENT` defaults to your own address (`Session.getActiveUser().getEmail()`); hardcode
     `jacksterwu@gmail.com` if you prefer.
   - `SEND_HOUR` / `SEND_WEEKDAY` — when the weekly email goes out (default Sunday 07:00,
     **script timezone**; set the project timezone in Project Settings, e.g. America/Denver).
6. Select function **`testReport`** → **Run**. Approve the **BigQuery + Gmail** permissions
   when prompted (one time). Confirm the email arrives in your inbox.
7. Select function **`installWeeklyTrigger`** → **Run** once. Done — it now emails you weekly,
   forever. (Re-running it is safe; it de-dupes its own trigger.)

To change the schedule later, edit `SEND_HOUR`/`SEND_WEEKDAY` and run `installWeeklyTrigger`
again. To stop, delete the trigger (clock icon in the editor) or the project.

## Data sources (all BigQuery, project `stock-trading-498512`)

| View / table | Feeds |
|---|---|
| `analytics.strategy_scorecard` | the per-strategy table: activation, budget (NAV · 2% sizing base), deployed MV, deployed-TWR, excess vs SGOV, gate |
| `state.current_regime` | regime integrative label + 5 axes + technical signals |
| `state.system_health` | the green/red ops strip (marks/engine fresh, embeddings, alerts, kill-flags) |
| `state.account_latest` | account NAV + Week/MTD/YTD TWR (written daily by **D2 Step 0b** from IBKR) |
| `analytics.account_reconciliation` | NAV fallback if no account snapshot exists yet |
| `analytics.weekly_activity` | last-7-day counts (fills / GO / NO-GO / pending) + recent fills/NO-GOs |

The SQL for these lives in `bigquery/14_weekly_report.sql` (single-sourced, version-controlled).

### Account NAV / TWR (the only IBKR-only bit)

Apps Script can't reach the IBKR connector, so the daily **D2** routine writes one
`ops.account_snapshot` row/day (NAV, cash, buying power, and Week/MTD/YTD TWR from
`get_pa_performance_all_periods`). The email reads the latest. Until D2 has run once after
this was added, the header falls back to the BigQuery reconciliation NAV and shows `—` for
account TWR (the per-strategy deployed-TWR still renders — that's the real signal).

## Notes

- The subject line includes the date, so weekly reports **don't thread together** in Gmail.
- The received copy is auto-labelled `Trading/Weekly` (set `LABEL_NAME=''` to disable).
- Preview the design any time by opening `ops/weekly_report/sample_preview.html` in a browser.
