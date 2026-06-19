# Operations Runbook

Companion to the analysis fixes. **Repo artifacts and additive BigQuery objects are already
done.** This file lists the steps that need the GCP/GitHub **console** (which automation cannot
click) plus the staged adoptions. Each item says what it solves (P0–P3 from the analysis).

---

## 0. What is already live (no action needed)
- **CI** (`.github/workflows/ci.yml`): runs the options-math self-test + `pytest` + the
  `strategy/` slice-drift check on every push/PR. *(P0-1, P2-3)*
- **BigQuery objects deployed & verified** (additive, idempotent):
  `bigquery/09_market_calendar.sql` → `events.market_holidays`, `state.market_calendar`,
  `state.trading_day_today`; `bigquery/10_observability.sql` → `ops.run_log`, `ops.alerts`,
  `ops.sp_log_run`, `ops.sp_raise_alert[_once]`, `state.freshness`, `state.system_health`,
  `state.gate_watch`; `bigquery/11_theater_judge.sql` → `analytics.theater_judge`,
  `ops.sp_score_theater`, `analytics.theater_check_calibration`.
- Quick check anytime: `SELECT * FROM state.system_health;` (want `all_green = TRUE`).

To re-apply or move to a fresh project, run `bigquery/01..11_*.sql` in order via the BigQuery MCP
`execute_sql` (same pattern the existing files use).

---

## 1. Scheduled queries — **the dead-man's switch** *(P0-2, P0-3)*
Until these exist, the procedures only run when a session calls them (a skipped session =
silent drift). Bodies are in `bigquery/scheduled_queries/` (see that folder's README).

BigQuery Studio → **Scheduled queries → Create**:
1. **Embeddings heal** — paste `embed_pending.sql`; daily ~06:00 America/Denver; Location US.
2. **Freshness check** — paste `daily_freshness_check.sql`; daily ~21:30 America/Denver
   (after D2). Under **Notifications**, enable *Send email on failure* — the query RAISEs when
   `system_health` isn't green, so that email IS the alert (no Pub/Sub needed).
3. On each, set an advanced **`maximum_bytes_billed`** cap (these scans are tiny). *(P2-2)*

---

## 2. Cost guardrails *(P2-2)*
- GCP Console → **Billing → Budgets & alerts** → budget on project `stock-trading-498512`
  with email thresholds (Vertex embeddings/Gemini/AI.FORECAST are the only billed pieces;
  they're pennies, but unattended scheduled jobs should be capped).
- Keep `maximum_bytes_billed` on scheduled queries and prefer `execute_sql_readonly` for agent reads.

---

## 3. Backups of the event store *(P2-1)*
`events.*` is now the irreplaceable source of truth; only 7-day time-travel protects it today.
1. Create a bucket: `gsutil mb -l US gs://stock-trading-backups`.
2. Lifecycle (keep 90 daily, then sparse): `gsutil lifecycle set ops/gcs_lifecycle.json gs://stock-trading-backups`
   *(write the rule you want; example: delete objects > 400 days)*.
3. Schedule `scripts/backup_events.sh` daily (Cloud Scheduler → Cloud Run job, or cron on a
   trusted box): `BUCKET=gs://stock-trading-backups scripts/backup_events.sh`.
4. (Optional, auditability) have D2 run `scripts/state_snapshot.sh` and commit
   `state_snapshots/` — restores the "git diff shows what changed today" property the
   `.md`→BigQuery cutover gave up, without resurrecting the retired live-state files.

---

## 4. Dashboard *(P1-4)*
Two options (pick one):
- **No console:** schedule `python ops/dashboard/generate_dashboard.py` (needs `bq` auth) and
  serve `ops/dashboard/index.html` via GitHub Pages / commit it. Self-contained HTML.
- **Looker Studio:** New report → BigQuery connector → `state.system_health`,
  `perf.strategy_daily`, `analytics.strategy_nav`, `ops.alerts`, `state.gate_watch`.

---

## 5. Make CI actually gate merges *(P0-1)*
`auto-merge-claude.yml` merges `claude/*` → `main` via a direct bot push, so a red CI build does
**not** block it yet. To gate:
- Easiest: add a step at the **start** of the auto-merge job that runs the tests
  (`pip install pytest && python c_options_math.py && python -m pytest -q &&
  python scripts/split_strategy.py --check`) and exits non-zero on failure, *before* it merges.
- Or: GitHub → Settings → Branches → protect `main` with the **CI** check required, and route
  merges through PRs (changes the current direct-push model — heavier).

## 6. Enable the CI SQL dry-run *(P2-3)*
Add a repo secret **`GCP_SA_KEY`** (a least-privilege SA with BigQuery *dry-run*/jobUser). The
`sql-validate` job then dry-runs every `bigquery/*.sql` on each push; without the secret it skips
cleanly (CI stays green).

---

## 7. Adopt `run_log` + `alerts` in the routines *(P1-1, P0-4)*
Mechanism is live and **D2 is already wired as the reference example** (`Claude_Task_Plan.md` D2
"RUN LOGGING" + the §13 cash-tripwire alert in both `Claude_Task_Plan.md` and
`Operating_Protocols.md §13.A.4`). Replicate the same two calls across the other routines
(see `ops/cadence.yaml` `defaults`):
- **Start/end of every routine:** `CALL ops.sp_log_run('<id>', <run_date>, 'started'|'completed'|'failed'|'halted', <session>, <branch>, <rows>, <error>, <note>)`.
  This populates `state.freshness.d2_ran_last_trading_day` and the audit trail.
- **On any hard-stop** (cash tripwire > $1, dual-path max-loss disagreement, embedding
  unhealthy, merge-conflict PR, stale data): `CALL ops.sp_raise_alert('critical', '<routine>',
  '<category>', '<message>', '<payload_json>')` **and** create a `[Claude] ATTENTION …`
  calendar event so the unmonitored failure reaches the operator.

## 8. Extend the market-holiday calendar yearly *(P1-3)*
Each December, append next year's NYSE/Nasdaq full closes (+ any early closes) to
`events.market_holidays` (MERGE in `bigquery/09_market_calendar.sql` is the template) and extend
the date range in `state.market_calendar` if needed.

## 9. Strategy slices — staged cutover *(P3-1)*
`strategy/*.md` are generated from `Strategy.md` (parallel-run; nothing reads them yet). When
ready, re-point routine read-instructions in `Claude_Task_Plan.md` / `Operating_Protocols.md` at
the per-strategy slice (+ preamble/router) so blinding becomes a file boundary and context shrinks.
Regenerate after any `Strategy.md` edit: `python scripts/split_strategy.py` (CI guards drift).

## 10. Theater judge — run it *(P3-2)*
Add to **W5**: `CALL ops.sp_score_theater();` then read `analytics.theater_check_calibration`
to compare the objective judge against the orchestrator's self-certified theater_check. Billed
(Gemini) but tiny — only scores not-yet-scored paired reviews.

## 11. Conviction gate watch *(P3-3)*
No action now (B at 5/30, D at 0/30 closed). `state.gate_watch` surfaces proximity; revisit the
gated conviction model (`bigquery/04_analytics.sql`) when `approaching_gate` flips TRUE.
