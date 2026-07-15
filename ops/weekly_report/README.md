# Weekly performance self-email — "Deployed vs Benchmarks"

A weekly HTML email that answers two questions: **is each strategy beating SGOV?**, and
**is deploying capital beating both SGOV AND the S&P 500 (VOO), over the same dollars and
the same days?** (2026-07 redesign — see `ops/RUNBOOK.md` §33 for the full rationale and
the iteration history; the VOO benchmark was added 2026-07-13, owner directive.) Everything
that didn't support those questions — regime, account NAV/MTD/YTD, open positions,
next-7-days, weekly activity, the full ops-health strip — was cut. What's left:
a **headline block** (the deployed book vs SGOV vs VOO — cumulative %, avg/month, avg/year,
and a "same dollars, same days" $ edge), a **returns chart** (each deployed strategy's
cumulative total return + a gray SGOV line + a steel-blue VOO line), a **table** of each
strategy's **average return vs SGOV per month / year** — a geometric per-period rate
measured over **active (deployed) time only**, so idle stretches never dilute it ("Not
enough data" until at least 21 deployed days exist) with SGOV's and VOO's own-return rows,
and a one-line data-trust warning that only appears when something is actually stale. No
combined aggregate beyond the headline, no verdict labels.

**VOO is purely informational** — it never feeds `perf.kill_flags` or any other live
decision surface; only SGOV is the sanctioned kill/gate benchmark.

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
`+0.00%`, but the headline/chart will be VOO-less until the backfill is applied). Then
re-paste `weekly_report.gs` (SCRIPT_VERSION `'v2'`) and run `testReport()` — no new OAuth
scope needed (read-only addition). Also re-apply `bigquery/43_script_version_registry.sql`'s
MERGE so `state.script_version_drift` expects `'v2'`, not `'v1'`.

To change the schedule later, edit `SEND_HOUR`/`SEND_WEEKDAY` and run `installWeeklyTrigger`
again. To stop, delete the trigger (clock icon in the editor) or the project.

## Data sources (all BigQuery, project `stock-trading-498512`)

| View / table | Feeds |
|---|---|
| `analytics.strategy_scorecard` | the A–E list + activation string (for the "not deployed" reason) |
| `analytics.strategy_vs_park_daily` | per strategy-day: `deployed_unit_value` (the chart's return lines) + cumulative `excess_vs_sgov` (the `.gs` turns the latest value into an average vs-SGOV return per month/year over the strategy's deployed days) |
| `analytics.sgov_cumulative` | SGOV's own cumulative total return per day (the chart's SGOV line + its own average return per month/year) |
| `analytics.voo_cumulative` | VOO's own cumulative total return per day, same date axis as `sgov_cumulative`; NULL before VOO's first backfilled mark (the chart's VOO line + its own average return per month/year) |
| `analytics.deployed_book_vs_benchmarks` | ONE row: the headline block — deployed book vs SGOV vs VOO, cumulative %, avg/month, avg/year, and "same dollars, same days" $ edges |
| `state.system_health` | marks/engine freshness + firing kill-flags + critical alerts — the one surviving data-trust signal |
| `state.user_tz` | detected DISPLAY timezone (never the operating/trading-day timezone) |
| `perf.kill_flags` / `ops.alerts` | queried lazily, only when `state.system_health` flags something |

The SQL for the strategy-vs-SGOV views lives in `bigquery/21_strategy_vs_park.sql`; the VOO
benchmark views (`voo_daily_return`, `voo_cumulative`, `deployed_book_vs_benchmarks`) live in
`bigquery/46_weekly_benchmarks.sql` (2026-07-13, owner directive — single-sourced,
version-controlled). The `deployed_unit_value` / `excess_vs_sgov` columns come from
`perf.strategy_daily` (the deployed-TWR engine, `bigquery/03_twr_engine.sql`).

### What the numbers mean (2026-07-13)

Everything is an **actual total return**, a **return vs SGOV**, or (new) a **same-dollars,
same-days comparison to SGOV and VOO**, as percentages and dollars:

- **Headline block** — the whole deployed book (all strategies combined, capital-weighted)
  vs SGOV vs VOO, over the SAME set of deployed trading days, since the book's first deployed
  day through the latest mark: cumulative %, avg/month, avg/year (`†` = annualized from fewer
  than 252 deployed days — extrapolated), and a $ column where each day's *actual* deployed
  dollars notionally earn the benchmark's return that day, summed (deliberately NOT a
  compounding buy-and-hold hypothetical — see `bigquery/46_weekly_benchmarks.sql`'s header for
  the full methodology, including why SGOV forward-fills a missing mark but VOO reads a gap as
  0%). A one-line takeaway states whether deploying beat or trailed each benchmark in dollars.
- **Chart** — each deployed strategy's cumulative total return since its first deployment
  (`deployed_unit_value − 1`), SGOV's own cumulative total return (`sgov_cumulative`), and
  VOO's own cumulative total return (`voo_cumulative`, once it has data) — each a line. SGOV
  is gray, VOO is steel blue, neither is a flat baseline.
- **Table** — per strategy, the **average return *above SGOV* per month / year** — a
  geometric per-period rate over the strategy's **active (deployed) days only**:
  `(1 + excess_latest) ^ (tradingDaysPerPeriod / deployedDays) − 1`, with
  `TRADING_DAYS_PER = {month:21, year:252}` and `excess_vs_sgov` = deployed-TWR unit value ÷
  SGOV index − 1 (the sanctioned kill/gate metric — VOO is never part of this calculation).
  `strategy_vs_park_daily` has a row only for deployed days, so idle days are absent and never
  dilute the average toward 0. "Not enough data" shows when the strategy has fewer than 21
  deployed days (below that, not even a monthly average is meaningful — this floor is also why
  per-week reporting was dropped in this redesign). Separate **SGOV and VOO rows** show each
  benchmark's *own* average return per period over the same active window.

Returns are gross of commissions (the sanctioned profitability convention); SGOV and VOO are
their actual total returns including dividends. Strategies with no deployed history (A/C/E
currently) show "not deployed" — their cash is held in SGOV, so there is no strategy return
to compare.

### Views retained but no longer read by the email

`analytics.weekly_activity`, `analytics.weekly_fills`, `analytics.weekly_nogos`,
`state.open_positions_summary`, `state.next_7_days`, `state.account_latest`,
`state.account_nav_7d_ago`, and the `ops.account_snapshot` table (+ D2 Step 0b, which still
writes it daily) are kept in BigQuery for RUNBOOK verification, dashboard/history use, and
possible future use — dropping them is a separate, later decision. See the header comment
in `bigquery/14_weekly_report.sql`. Also retained but no longer read by the email:
`analytics.strategy_vs_park` (dollar edge + commissions), `analytics.deployed_book_vs_sgov`
(the short-lived combined-% hero, 2026-07-03), and `analytics.park_baseline` (the dollar-era
hero scale anchor) — all superseded for the email's purposes by
`analytics.deployed_book_vs_benchmarks` (2026-07-13), which covers the same "combined book"
question plus VOO.

## Notes

- The subject line includes the date, so weekly reports **don't thread together** in Gmail.
- The received copy is auto-labelled `Trading/Weekly` (set `LABEL_NAME=''` to disable) — the
  label search string is coupled to the subject format; if you change the subject prefix,
  update the `GmailApp.search(...)` call in `sendWeeklyReport_` to match.
- Preview the design any time by opening `ops/weekly_report/sample_preview.html` in a browser
  (the chart is a static placeholder there — the real email renders an actual PNG). Regenerated
  for v2/VOO on 2026-07-14 — this file drifted for a full redesign cycle (2026-07-13's VOO
  rewrite) because that entry's checklist omitted the regeneration step every prior redesign
  included; regenerate it again (by hand, matching `buildHtml_`/`headlineSectionHtml_`'s current
  output) any time the email's HTML structure changes, in the SAME commit.
