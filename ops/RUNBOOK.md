# Operations Runbook

Companion to the analysis fixes. **Repo artifacts and additive BigQuery objects are already
done.** This file lists the steps that need the GCP/GitHub **console** (which automation cannot
click) plus the staged adoptions. Each item says what it solves (P0–P3 from the analysis).

> **2026-06-19 stack-review fixes (A1–D2).** A second review found the control plane was *coded but
> not operating* (empty `ops.run_log`; scheduled queries showing no recurring execution; everything
> running under one personal OAuth identity). The fixes below are now in the repo:
> - **IaC** — `infra/terraform/` codifies the datasets, the Vertex connection, the GCS backup bucket,
>   the budget, and **all four scheduled queries** (freshness, embed, backup, **new cadence check**).
>   This replaces the "click in console" steps in §1–§3 (see **§12**). The scheduled queries are
>   genuinely live only once `terraform apply` (or the console steps) runs — do that first.
> - **Run-logging** — `ops.sp_routine_start`/`sp_routine_end` + `ops.sp_assert_deps`
>   (`bigquery/12_cadence_monitor.sql`) give every routine one-call logging + a dependency gate
>   (see **§7**, **§13**). Data currency is also proven independently by
>   `state.freshness.marks_fresh`/`engine_fresh`.
> - **Cadence monitor** — `state.cadence_watch` + `bigquery/scheduled_queries/cadence_check.sql`
>   (self-bootstrapping: only alerts on routines that have adopted logging).
> - **SGOV reconciliation** — `state.sgov_reconciliation` event-sources the SGOV holding; the
>   hand-kept per-strategy share ledger is dissolved (Operating_Protocols §13).
> - **dbt** — `dbt/` is a tested, parallel-run modeling layer over the derived views (see **§14**).
> - **Credential resilience** — see **§15**.
> - **CI/dashboard** — `dbt parse` + keyless WIF SQL dry-run added to CI; a Pages workflow publishes
>   the dashboard (see **§5**, **§16**).

---

## 0. What is already live (no action needed)
- **CI** (`.github/workflows/ci.yml`): runs the options-math self-test + `pytest` + the
  `strategy/` slice-drift check on every push/PR. *(P0-1, P2-3)*
- **BigQuery objects deployed & verified** (additive, idempotent):
  `bigquery/09_market_calendar.sql` → `events.market_holidays`, `state.market_calendar`,
  `state.trading_day_today`; `bigquery/10_observability.sql` → `ops.run_log`, `ops.alerts`,
  `ops.sp_log_run`, `ops.sp_raise_alert[_once]`, `state.freshness`, `state.system_health`,
  `state.gate_watch`; `bigquery/11_theater_judge.sql` → `analytics.theater_judge`,
  `ops.sp_score_theater`, `analytics.theater_check_calibration`;
  `bigquery/12_cadence_monitor.sql` → `state.cadence_expected_today`, `state.cadence_watch`,
  `ops.sp_assert_deps`, `ops.sp_routine_start`, `ops.sp_routine_end`;
  `bigquery/13_sgov_reconciliation.sql` → `state.sgov_position`, `state.sgov_reconciliation`;
  and D2's run is logged by the routine via `ops.sp_routine_start`/`sp_routine_end` (not self-logged
  by `ops.sp_daily_refresh`).
- Quick check anytime: `SELECT * FROM state.system_health;` (want `all_green = TRUE`);
  `SELECT * FROM state.cadence_watch WHERE needs_attention;` (want zero rows);
  `SELECT * FROM state.sgov_reconciliation;` (events-side SGOV shares to compare to the connector).

To re-apply or move to a fresh project, run `bigquery/01..21_*.sql` in order via the BigQuery MCP
`execute_sql` (same pattern the existing files use). (Added 2026-06-24: `18_stack_review_fixes.sql` —
additive monitor/integrity views + two `ALTER ADD COLUMN IF NOT EXISTS`; apply before re-pasting
`cadence_check.sql` / `backup_events_export.sql` and before creating `integrity_check.sql`. See §25.)
(Added 2026-06-22: `16_automation_health.sql` —
backup-freshness + Apps Script heartbeat monitors, apply before re-pasting `cadence_check.sql`;
`17_restore_drill.sql` — the `ops.sp_restore_drill()` DR-verification procedure, apply after 16. **16 +
17 + the embedding re-build are already applied live** (the agent ran them via the MCP 2026-06-22 and
verified); they are in the apply list for fresh-project reproducibility. See §3, §7, §23, §24.)

---

## 1. Scheduled queries — **the dead-man's switch** *(P0-2, P0-3)*
Until these exist, the procedures only run when a session calls them (a skipped session =
silent drift). Bodies are in `bigquery/scheduled_queries/` (see that folder's README).

> **PREFERRED PATH (2026-06-19): apply via Terraform.** `infra/terraform/scheduled_queries.tf`
> codifies all four scheduled queries (single-sourcing the SQL bodies from
> `bigquery/scheduled_queries/`), with `email_preferences.enable_failure_email = true` on the
> RAISE-ing ones. Run `terraform apply` (after the one-time `import` of existing resources — see
> `infra/terraform/README.md` and §12) instead of hand-creating them. **A second review found these
> scheduled queries were NOT actually running** (no recurring execution in 30 days of job history),
> so this is the step that makes the dead-man's switch real. The console steps below remain valid as
> a manual fallback.

BigQuery Studio → **Scheduled queries → Create**. **BigQuery schedules are UTC** (the UI's
local-time label is misleading) — use the UTC times below so the check lands in the Denver
evening *after* D2 year-round:
1. **Embeddings heal** — paste `embed_pending.sql`; daily ~06:00 UTC; Location US. (Timing is
   irrelevant — the embedder is idempotent.)
2. **Freshness check** — paste `daily_freshness_check.sql`; **daily at 05:00 UTC** (≈ 22:30 MDT /
   21:30 MST — evening, after D2; NOT 21:30 UTC, which is 15:30 MDT = *before* D2 and would
   false-alarm every trading day). Under **Notifications**, enable *Send email on failure* — the
   query RAISEs when `system_health` isn't green, so that email IS the alert (no Pub/Sub needed).
3. **Cadence check** — paste `cadence_check.sql`; **daily at 05:15 UTC** (after D2/D3, like the
   freshness check). Enable *Send email on failure* — it RAISEs when a *monitored* routine
   (one that has logged a `completed` run in the last 14 days) was expected today but did not run.
   Self-bootstrapping, so it never false-alarms on routines that don't yet self-log. *(A3)*
   **Deadline guard (2026-06-25):** `state.cadence_watch.needs_attention` now also requires Denver-time
   to be past **21:00** (the daily routines' after-close completion deadline), so an *off-schedule /
   manual / duplicate* run of this query *before* the routines have run today can no longer raise a
   spurious `missed_run` CRITICAL (the 2026-06-21 12:00 MT + 2026-06-24 09:37 MT morning false positives,
   exposed once the notification-complete emailer began relaying self-healed alerts). 21:00 MT clears the
   latest observed completions (D2 ~17:47, D3 ~18:36) yet sits before this 05:15 UTC (23:15 MT) scheduled
   run, so a *genuine* miss still fires critical here. Computed in the `America/Denver` named zone
   (DST-safe) and NOT gated on `is_trading_day`, so D3's daily-all miss-detection still works on
   weekends/holidays. Logic in `bigquery/12_cadence_monitor.sql`; applied live via the MCP 2026-06-25.
4. The new scheduling UI no longer exposes `maximum_bytes_billed`; don't worry about it — all
   queries scan < 2 MB. Cost is bounded by the budget alert in §2. *(P2-2)*

---

## 2. Cost guardrails *(P2-2)*
- GCP Console → **Billing → Budgets & alerts** → budget on project `stock-trading-498512`
  with email thresholds (Vertex embeddings/Gemini/AI.FORECAST are the only billed pieces;
  they're pennies, but unattended scheduled jobs should be capped).
- Prefer `execute_sql_readonly` for agent reads. (`maximum_bytes_billed` isn't settable on
  scheduled queries in the current UI; the scheduled scans are tiny, so the budget alert is the
  guardrail.)

---

## 3. Backups of the event store *(P2-1)*
`events.*` is now the irreplaceable source of truth; only 7-day time-travel protects it today.
Bucket + lifecycle are **DONE** (`gs://stock-trading-backups`, US, delete > 400 days). To automate
the actual backups with **no Cloud Run job and no key**, use the BigQuery scheduled query
`bigquery/scheduled_queries/backup_events_export.sql` (it `EXPORT DATA`s every `events.*` table to
the bucket as dated Parquet, straight from BigQuery):
1. Grant the scheduled query's service account `roles/storage.objectAdmin` on `gs://stock-trading-backups`.
2. Create the scheduled query: daily ~05:30 UTC (after the freshness check); Location US; no destination.
3. *(Alternative, ad-hoc / full export)* run `BUCKET=gs://stock-trading-backups scripts/backup_events.sh`
   from Cloud Shell — same Parquet layout, uses the `bq` CLI; good for a one-off verification.
4. (Optional, auditability) have D2 run `scripts/state_snapshot.sh` and commit
   `state_snapshots/` — restores the "git diff shows what changed today" property the
   `.md`→BigQuery cutover gave up, without resurrecting the retired live-state files.

**Backup *liveness* monitor — DONE 2026-06-22.** The data-side freshness switch (`state.freshness`)
watches the event TABLES, not the bucket — so a backup that silently stops (expired identity, deleted
schedule) would go unnoticed until a restore was needed. Now `backup_events_export.sql` logs an
`ops.backup_log` marker on a full-success run, `state.backup_health` flags a stale backup (no success in
>2 days; self-bootstrapping so it never alarms before the first marker), and `cadence_check.sql` RAISEs
on it (so the DTS failure-email — identity-independent — delivers the alarm). Apply
`bigquery/16_automation_health.sql` (creates `ops.backup_log` + `state.backup_health`) before re-pasting
`cadence_check.sql`.

**Backup *restore* drill — ADDED + VALIDATED + AUTOMATED 2026-06-22.** A backup you have never restored is
a hope, not a backup. Two equivalent drills exist:
- **In-warehouse (automated, least-privilege):** `ops.sp_restore_drill()` (`bigquery/17_restore_drill.sql`)
  loads the latest logged snapshot (`ops.backup_log.run_date`) of every `events.*` table into the
  pre-created `events_restore_drill` scratch dataset (overwritten each run), checks restored row counts vs
  live (each must load, be non-empty unless live is empty, and not exceed live), and RAISEs + alerts on
  failure. Self-bootstrapping (no-op until the backup logs a marker). **Already applied 2026-06-22 (via the
  MCP):** the procedure, the pre-created scratch dataset, and a **scoped** `roles/bigquery.dataEditor`
  grant on *that dataset only* to `bq-scheduler@` (SQL DCL — deliberately NOT project-level, so the
  scheduler never gets write on the append-only `events.*` truth). **Two console steps remain (owner/Chrome):**
  (1) grant `bq-scheduler@` `roles/storage.objectViewer` on `gs://stock-trading-backups` (GCS IAM — the
  drill must READ the backups; the daily backup already has write, so this read grant is drill-only), and
  (2) create the monthly scheduled query from `bigquery/scheduled_queries/restore_drill.sql`.
- **Ad-hoc (shell):** `scripts/restore_drill.sh` (latest snapshot) or `DATE=YYYY-MM-DD scripts/restore_drill.sh`
  from Cloud Shell — same checks via `bq`/`gsutil`.

**Validated end-to-end 2026-06-22:** ran the drill across all 12 `events.*` tables from the dt=2026-06-21
snapshot — every table restored at **exact row-count parity to live** (e.g. decision_log 262/262,
daily_marks 444/444, macro_fred 777/777; `hf_capability_captures` 0/0 = legitimately empty). So the
backup→restore path is proven, not assumed.

**DDL-FIRST restore (the FAITHFUL recovery procedure — added 2026-06-28, §27 #13).** The quick
`bq load --source_format=PARQUET --replace` shown in `backup_events_export.sql` proves *presence* but
INFERS the schema, so it yields an **un-partitioned, un-clustered, nullable-everywhere** table with JSON
degraded to STRING and a NUMERIC→FLOAT64 coercion risk — fine for a spot-check, WRONG for a real recovery
of a financial system of record. For an actual restore, recreate the schema FIRST, then load into the typed
table:
1. **Recreate the canonical schema:** apply `bigquery/01_schema.sql` (+ `03_twr_engine.sql` for
   `events.daily_marks`, `07_fred_macro.sql` for `events.macro_fred`) to a fresh/empty target — this
   restores `NOT NULL`, `PARTITION BY` / `CLUSTER BY`, `DEFAULT GENERATE_UUID()/CURRENT_TIMESTAMP()`,
   NUMERIC types, and the immutability `OPTIONS`/description.
2. **Load into the pre-created typed table** (NOT `--replace`-from-FILES, which re-infers): `LOAD DATA INTO`
   a `<table>_staging` table `FROM FILES(format='PARQUET', uris=[…dt=<DATE>/*.parquet])`, then `INSERT INTO`
   the canonical `events.<table>` `SELECT * REPLACE(SAFE.PARSE_JSON(<jsoncol>) AS <jsoncol>, …)` from the
   staging table — re-parsing the TO_JSON_STRING'd JSON columns (decision_log.fields,
   position_events.invalidation_status, queue_events.payload, trade_fills.raw, adversarial_reviews.weaknesses).
3. **ops.\* restore** is identical, applying `10/14/16/17` for the ops DDL then loading from
   `gs://stock-trading-backups/ops/<table>/dt=<DATE>/` (the new `ops_export.sql` snapshots, §27 #2).
The monthly drill now also runs a **typed-restore fidelity check** on one representative table (`trade_fills`
— NUMERIC + JSON) each run: it `CREATE TABLE LIKE`s the live table and loads the snapshot into that canonical
schema, so a backup that no longer fits the real types surfaces as a record-only `restore_fidelity` **warning**
(never the critical RAISE) — `bigquery/17_restore_drill.sql`.

---

## 4. Dashboard *(P1-4)*
Two options (pick one):
- **No console:** schedule `python ops/dashboard/generate_dashboard.py` (needs `bq` auth) and
  serve `ops/dashboard/index.html` via GitHub Pages / commit it. Self-contained HTML.
- **Looker Studio:** New report → BigQuery connector → `state.system_health`,
  `perf.strategy_daily`, `analytics.strategy_nav`, `ops.alerts`, `state.gate_watch`.

---

## 5. Make CI actually gate merges *(P0-1)* — DONE
`auto-merge-claude.yml` now triggers on the **CI** workflow's completion (`workflow_run`) instead
of on push, and merges a `claude/*` branch only if the CI run for that branch's **exact tip
commit** concluded `success`. Because the gate keys off the whole CI *run* conclusion, it covers
every required job (`options-math tests`, `dbt parse`, and the keyless-WIF `BigQuery SQL dry-run`
when configured — §6); the `lint` job is `continue-on-error` (advisory), so it never affects the
gate. A red build is skipped (and retried automatically when its CI later turns green), so a broken
commit no longer reaches `main` — all without human intervention or changing the direct-push model.
Fail-closed: in-progress / missing / API-error states are treated as "not green".
Considered but rejected: re-running the tests inside the merge job (duplicates CI and, in the
drain-all loop, would need a per-branch checkout+test), and branch protection + required checks
(would force PRs, abandoning the direct-push model).

## 6. CI SQL validation — `dbt parse` (always-on) + optional keyless-WIF dry-run *(P2-3, D2)*
The always-on SQL gate is the **`dbt` job's offline `dbt parse`** (no creds, runs on every push;
validates the modeling layer + that every ref/source/test resolves). That is the recommended gate.

The separate **`sql-validate`** job (live `bq --dry_run` of every `bigquery/*.sql` under keyless
GitHub→GCP Workload Identity Federation) is **OPT-IN and OFF by default** — and we recommend leaving
it off. Why: dry-running the DDL files (`CREATE TABLE/MODEL/VIEW`) requires **CREATE/DDL permissions
on the production datasets** (events/ops/analytics/state), *even in `--dry_run`*. Granting a
CI/PR-triggered identity write+DDL on the append-only source of truth over-privileges it for marginal
value, and a live dry-run does **not** catch the runtime-only bugs we actually hit (e.g. the
`EXPORT DATA` JSON-serialization error — its own comment notes dry-run misses it). So the CI service
account (`gh-ci-runner`) is kept **read-only** (`jobUser` + `dataViewer` + `connectionUser`).

WIF itself is set up (provider `github-pool/github-provider`, SA `gh-ci-runner@…`, repo variables
`GCP_WIF_PROVIDER` + `GCP_WIF_SERVICE_ACCOUNT`) and powers any future keyless need (e.g. a `dbt build`
or §16's dashboard). As of 2026-06-22 it also powers the **`dbt-parity` row-level drift gate, which now
runs by default whenever those WIF vars are present** (read-only; advisory until promoted to `DBT_PARITY=block`
— see §12 "D1"). That is the real guard on the two hand-maintained copies of each view; `dbt parse` only
checks structure. To turn the live SQL dry-run ON anyway, the owner must:
1. Enable the **Cloud Resource Manager API** (`gcloud services enable cloudresourcemanager.googleapis.com`)
   and the IAM Service Account Credentials API (already enabled).
2. Grant `gh-ci-runner` the DDL perms the dry-run needs (`roles/bigquery.dataEditor` on
   events/ops/analytics/state/perf + `bigquery.models.create` on `ops`) — accepting the
   over-privilege tradeoff above.
3. Set repo variable **`RUN_SQL_DRYRUN=true`**.
Until all three are set the job skips cleanly (green). SQL is also dry-run via the BigQuery MCP during
development, which is the practical safety net.

---

## 7. Adopt `run_log` + `alerts` in the routines *(P1-1, P0-4)* — convention DONE; enforcement HARDENED 2026-06-19
A **global convention** in `Claude_Task_Plan.md` ("## Observability — run logging & failure
alerts") binds every routine (D1–A3 + the adversarial attacker/orchestrator), with D2 as the
worked example.

> **FINDING (2026-06-19): `ops.run_log` was EMPTY in production** — the convention is instruction-only
> and the agent was skipping it, so `state.freshness.d2_ran_last_trading_day` was permanently FALSE
> (only marks/engine freshness actually worked). **Fixes applied:**
> - `ops.sp_routine_start` / `ops.sp_routine_end` collapse start/end logging (+ a dependency gate)
>   into one call each, lowering the "remember-to" surface; now demonstrably adopted in production
>   (D1/D2/D3/AR routines logging). Data currency is independently proven by
>   `state.freshness.marks_fresh`/`engine_fresh` (which read the data tables, not `run_log`).
> - `state.cadence_watch` + `cadence_check.sql` catch a *monitored* routine that skips a scheduled run.
> A routine becomes monitored automatically the first time it logs, so adoption is incremental and
> never false-alarms. Verify adoption: `SELECT routine, MAX(run_date) FROM ops.run_log GROUP BY 1`.

For reference, the calls each routine makes (see also `ops/cadence.yaml` `defaults`):
- **Start/end of every routine:** `CALL ops.sp_log_run('<id>', <run_date>, 'started'|'completed'|'failed'|'halted', <session>, <branch>, <rows>, <error>, <note>)`.
  This populates `state.freshness.d2_ran_last_trading_day` and the audit trail.
- **On any hard-stop** (cash tripwire > $1, dual-path max-loss disagreement, embedding
  unhealthy, merge-conflict PR, stale data): `CALL ops.sp_raise_alert('critical', '<routine>',
  '<category>', '<message>', '<payload_json>')` **and** create a `[Claude] ATTENTION …`
  calendar event so the unmonitored failure reaches the operator.

**Alert DELIVERY (A2) — push channel added 2026-06-20.** Beyond the calendar event, a Google
Apps Script (`ops/monitoring/alert_emailer.gs`) polls `ops.alerts` every ~2h and **emails** you on
a new unresolved critical/warning (de-duped, self-email, no console wiring) — so an alert reaches
you between routines without watching the calendar. Setup: same as the weekly report
(`ops/weekly_report/README.md`) — paste the script, add the BigQuery service, run `testAlertCheck`
then `installAlertTrigger`. (A Cloud Monitoring alert policy on `ops.alerts` is the heavier alternative.)

**Apps Script LIVENESS heartbeat — DONE 2026-06-22 (who-watches-the-watchers).** Both Apps Scripts run
OUTSIDE Claude on Google's servers, so a silent death (revoked OAuth scope / deleted trigger) would stop
alerts/reports with no signal — and for the alert emailer that is *circular* (a dead emailer can't email
that it's dead). Both now write an `ops.heartbeat` beat each run (`alert_emailer` per poll, `weekly_report`
per send — best-effort, never blocks delivery); `state.automation_heartbeat` flags a source whose last beat
exceeded its expected interval (6h for the emailer, ~9 days for the report; self-bootstrapping so a not-yet-
deployed script never alarms), and **`cadence_check.sql` RAISEs on it via the independent DTS failure-email**
— a channel that survives the emailer being the thing that died. Apply `bigquery/16_automation_health.sql`
(creates `ops.heartbeat` + `state.automation_heartbeat`) before re-pasting `cadence_check.sql`; the heartbeat
writes are already in the two `.gs` files, so re-paste them into the Apps Script project (no other change).

## 8. Extend the market-holiday calendar — now AUTO-EXTENDED *(P1-3)* — DONE (2026-06-20)
**No longer a manual yearly task.** The **W5** weekly routine self-extends `events.market_holidays`
from the **FMP connector** (`marketHours` `holidays-by-exchange`, NASDAQ) whenever the calendar's
horizon falls within ~120 days — see `bigquery/09_market_calendar.sql §auto-extend` + the
"MARKET-CALENDAR AUTO-EXTEND" step in Claude_Task_Plan.md W5. The seed is hand-verified through
**2029** and `state.market_calendar` now spans through **2030-12-31**. Manual fallback (if ever
needed): the MERGE template in `bigquery/09_market_calendar.sql` + bump the `GENERATE_DATE_ARRAY`
end date. The freshness dead-man's switch (`state.freshness`, COALESCE→FALSE) still backstops a
silently-exhausted calendar.

## 9. Strategy slices — cutover DONE (via authoritative read convention) *(P3-1)*
`strategy/*.md` are generated from `Strategy.md` (`scripts/split_strategy.py`; CI guards drift).
The cutover is now done at the instruction layer: `Claude_Task_Plan.md` "Strategy reading — use the
generated `strategy/` slices" is an **authoritative** routine→slice map that overrides any in-body
"Read Strategy.md (… section)" — per-strategy routines load only their slice(s) + `01`, so blinding
is a file boundary and context shrinks. `Strategy.md` stays canonical (fallback + regenerate source).

**M1a exception — RESOLVED 2026-06-22.** Previously the slices split on top-level `##` and the
"Regime router" slice (`02`) bundled M1a's regime-scoring template WITH the M1b strategy-mapping +
reconciliation rules naming strategies A/D, so no slice gave the strategy-blind M1a a clean file and
M1a read a named sub-section of `Strategy.md` under discipline-only blinding. `Strategy.md` was
restructured (content-preserving) to split the old "Regime router" section into two distinct top-level
sections — **`## Regime scoring (strategy-blind, monthly)`** (M1a inputs + 5 axes, no strategy names)
and **`## Regime router`** (the M1b mapping / reconciliation / divergence / output format) — placed so
only the unreferenced document-completion-checklist slice renumbered (`09`→`10`); the referenced strategy
slices `00`–`08` kept their numbers. The splitter now emits a clean M1a slice
`09_regime_scoring_strategy_blind_monthly.md`; **M1a loads `01` + `09` only** and its blinding is a hard
file boundary. Verified: the M1a slice contains the axes + inputs + fallback and the A/D reconciliation
mapping does NOT appear in it (the one `A–E` mention is the blinding directive itself); the router slice
retains the M1b reconciliation rules. Routing updated in `Claude_Task_Plan.md` ("Strategy reading" table
+ M1a prompt body).

## 10. Theater judge — run it *(P3-2)*
Add to **W5**: `CALL ops.sp_score_theater();` then read `analytics.theater_check_calibration`
to compare the objective judge against the orchestrator's self-certified theater_check. Billed
(Gemini) but tiny — only scores not-yet-scored paired reviews.

## 11. Conviction gate watch *(P3-3)*
No action now (B at 5/30, D at 0/30 closed). `state.gate_watch` surfaces proximity; revisit the
gated conviction model (`bigquery/04_analytics.sql`) when `approaching_gate` flips TRUE.

---

## 12. Infrastructure as code — Terraform *(A1, A4)*

> **DECISION (2026-06-21): NOT adopted — kept as a declared spec / reference only.** Verified that
> `terraform state list` against `gs://stock-trading-tfstate` is **empty** — this module has never
> been imported or applied, and we are deliberately **not** adopting it. The live substrate
> (datasets, connection, bucket, scheduled queries, the freshness monitor) is created and changed
> out-of-band via the BigQuery MCP + console; the operating model has **no Terraform runtime** (same
> logic as the §14 dbt-ownership decision). Adopting would add a clobber risk — a later
> `terraform apply` reverting a live MCP/console fix on production trading infra — for benefits
> already covered by the runtime dead-man's switches, the `dbt-parity` CI drift check, and the
> `bigquery/*.sql` rebuild path. Treat `infra/terraform/` as a **reviewable spec, not a live
> manager**; do NOT run the import-then-apply flow below unless the project deliberately switches to
> Terraform-first change control. Also logged in `CLAUDE.md` "Settled decisions". The procedure
> below remains ONLY as the reference for that hypothetical future adoption.

`infra/terraform/` codifies the GCP substrate that previously lived only as console state: the 5
datasets, the `us.vertex` connection, the `gs://stock-trading-backups` bucket + lifecycle, the budget
alert, and **all four scheduled queries** (single-sourcing the SQL bodies from
`bigquery/scheduled_queries/`). Most resources ALREADY EXIST, so the flow is **import, then apply**:
1. `cd infra/terraform && terraform init`.
2. `terraform import` each existing resource (datasets, connection, bucket) — exact commands in
   `infra/terraform/README.md`. After import, `terraform plan` should show ~no changes for them.
3. Set `billing_account` + `notification_emails` in `terraform.tfvars` (copy `.example`).
4. `terraform apply` — would converge/adopt the resources. NOTE (2026-06-21): the scheduled queries
   already exist and run (under `bq-scheduler@`, created out-of-band), so this would be *adoption*,
   not creation — and per the decision banner above it is **not currently pursued**.
Owner decisions: the `billing_account` id; and whether the backup export runs under owner creds
(default) or a dedicated SA (A1).

**A3 — remote GCS state backend: ENABLED (2026-06-20).** `versions.tf` now declares
`backend "gcs" { bucket = "stock-trading-tfstate" }`. Create the bucket once before `terraform init`:
`gsutil mb -l US -b on gs://stock-trading-tfstate && gsutil versioning set on gs://stock-trading-tfstate`,
then `terraform init -migrate-state`. CI does not run terraform, so this only affects an owner running
terraform locally / in Cloud Shell.

**D1 — row-level dbt↔live parity: NOW RUNS BY DEFAULT (changed 2026-06-22).** The `dbt-parity` job in
`ci.yml` + `scripts/dbt_parity.py` `dbt compile` each model and run compiled-vs-live `EXCEPT DISTINCT`
both ways (read-only; never `dbt build`, which would overwrite the live datasets). This is the ONLY guard
on the two hand-kept copies of every view (`bigquery/*.sql` + `dbt/`); it was previously opt-in
(`RUN_DBT_PARITY=true`) and so **never actually ran**, leaving that duplication undefended. It now runs
on every push **whenever the read-only WIF creds exist** (the same `gh-ci-runner@` SA, `roles/bigquery.dataViewer`
+ `roles/bigquery.jobUser`, already configured per §6). **PATH-GATED (2026-06-29):** the job's guard step now
skips parity unless the push touched `bigquery/**` or `dbt/**` (view-logic drift is impossible without an
SQL/model change). This removed the ~1k-BigQuery-job/day load — dbt compile + ~30 `EXCEPT DISTINCT`
comparisons on *every* `claude/**`/`main` push — that tripped the BigQuery Data Transfer Service **consumer
rate-quota** on 2026-06-29 (delaying the 05:00–06:00 UTC scheduled window and failing the `embed_pending` +
`integrity_check` runs). The gate **fails open** (unknown base commit → run) and preserves the block-mode
fail-closed contract (an SQL change pushed with WIF creds missing still errors). One var, **`DBT_PARITY`**,
controls it (replaces `RUN_DBT_PARITY`):
- unset / `advisory` (default): runs; a drift prints a `::warning::` but does NOT block the merge — a
  staged rollout, so a latent drift can't wedge auto-merge before a clean baseline is confirmed;
- `block`: runs and FAILS the build on drift (promote to this once parity is green — it becomes a hard merge gate);
- `off`: skip entirely (escape hatch).
If the WIF vars are unset the job skips cleanly (green). **Owner action to finish enabling it:** confirm
`GCP_WIF_PROVIDER` + `GCP_WIF_SERVICE_ACCOUNT` repo vars are set (§6), watch one CI run go green/advisory,
then set `DBT_PARITY=block` to make drift a hard gate.

## 13. Cadence monitor + dependency gate *(A3, C1)* — DONE (deployed)
`bigquery/12_cadence_monitor.sql` is applied. `state.cadence_watch` shows, per operating day, which
routines were expected (per `ops/cadence.yaml`, encoded in `state.cadence_expected_today`) and whether
they logged `completed`; `cadence_check.sql` (schedule it, §1) alerts on a *monitored* miss.
Run-logging is **best-effort and cannot abort a routine**: routines wrap `ops.sp_routine_start('<ID>',
<denver_today>, <session>, <branch>, <instruction>)` / `ops.sp_routine_end(...)` in a
`BEGIN … EXCEPTION WHEN ERROR THEN … END` block (templates in `Claude_Task_Plan.md` "Observability"),
so a malformed/failed log call is swallowed and the trading work proceeds (verified: a wrong-arity
call raises but is swallowed). The dependency gate is a **separate, deliberately-fatal** call action
routines make first — `ops.sp_assert_deps('<ID>', <deps>, <denver_today>)` — which aborts on a missing
monitored upstream (self-bootstrapping). `<instruction>` (verbatim trigger text) is recorded in
`ops.run_log.instruction` → `state.routine_last_instruction`, so the **live web-UI trigger text is
verifiable by query** (no screenshots): `SELECT * FROM state.routine_last_instruction;` and diff
against `python scripts/print_routines.py`. No console action beyond scheduling `cadence_check.sql`.

## 14. dbt — TEST/VALIDATION layer (view-ownership cutover NOT pursued — decided 2026-06-19) *(B2, B3)*
`dbt/` ports the pure-SELECT derived views (state/perf/analytics) into dbt models with a dependency
DAG + data tests, INCLUDING the load-bearing invariants the review flagged (reserved_cash formula,
queue `event_ts` latest-wins, daily-marks no-double-count, one-row health views). CI runs `dbt parse`
offline on every push; run the assertions against BigQuery on demand with `cd dbt && dbt deps && dbt test`
(uses your `oauth` profile or WIF). **This is dbt's role here: a continuous structure + invariant
TEST layer.**

**Decision: do NOT transfer view OWNERSHIP to dbt** (i.e., do not remove the view DDL from
`bigquery/*.sql`). Reasons specific to this system: (1) routine sessions run on the BigQuery MCP and
have **no dbt runtime**, so if dbt owned the views, a session could neither rebuild nor change them;
(2) the disaster-recovery / fresh-project path is "apply `bigquery/01..13_*.sql` in order via the MCP"
— removing the view DDL breaks that single-command rebuild; (3) it can't be validated here (no dbt in
this environment) that `dbt build` reproduces every view byte-identically, and these are live trading
views. So `bigquery/*.sql` stays the **canonical runtime owner** of the views; `dbt/` is the test
mirror (kept in sync as a parallel-run port; `dbt parse` drift is the guard). If a true ownership
cutover is ever wanted, it must FIRST wire an operational dbt runner (e.g. a scheduled `dbt build`
into a scratch dataset, with the CI SA granted dataEditor only on that scratch dataset) and validate
byte-parity — only then remove the DDL. See `dbt/README.md`.

## 15. Operational identity & credential resilience *(C3)*
**Finding (2026-06-19):** 30 days of BigQuery job history ran under a SINGLE principal —
`jacksterwu@gmail.com` (owner OAuth). There is no autonomous service identity; the only service
account, `bq-loader@…`, last ran on the migration day and its key was deleted. Risks: if that OAuth
grant lapses or the operator is unavailable, the whole system stalls — and the dead-man's switch would
stall with it (it ran under the same identity).
- **Make the monitor independent of the agent.** Run the freshness + cadence + backup scheduled
  queries (§1, via Terraform §12) under the **BigQuery Data Transfer service identity** (or a
  dedicated SA), NOT the interactive OAuth session — so the alarm can still fire when the agent's
  identity is the thing that failed. (Email-on-failure is already enabled on them.)
- **Document expiry + rotation — FILLED IN 2026-06-22.** The interactive routines all run under the
  owner's Google OAuth + the MCP connector grants; an unplanned expiry stalls everything, so treat these
  as scheduled maintenance, not a surprise:

  | Credential | Used by | Typical lifetime | Renew / rotate |
  |---|---|---|---|
  | Owner Google OAuth (BigQuery MCP, Calendar, Gmail-draft) | every routine | Refresh token stays valid while used; Google may expire an unused/over-6-month-idle grant, or on password change / scope change | Re-consent in the Claude connector settings (re-auth the Google connector); no code change |
  | IBKR connector grant | D1/D2 (fills, positions, quotes, order-craft) | Brokerage session/token per IBKR's policy; can require periodic re-auth | Re-auth the IBKR connector in Claude; verify with a `get_account_summary` call |
  | FMP connector | W5 holiday auto-extend; market data | Per FMP subscription/token | Renew the FMP subscription/key; re-auth the connector |
  | `bq-scheduler@` SA (freshness/cadence/backup/embed scheduled queries) | the dead-man's switch | Long-lived SA; **GCP-managed, no downloadable key** | None routine; if ever rotated, re-point the 4 scheduled queries' run-as SA (and re-derive `monitoring.tf`'s config-id metric — §19) |
  | GitHub `GITHUB_TOKEN` (auto-merge / CI) | Actions | Per-run, auto-issued | None (managed by GitHub) |

  **Procedure:** keep a recurring **annual calendar reminder** ("re-verify Stock-Trading connector grants")
  and, on any connector that starts failing, re-auth it in the Claude connector settings first (most
  outages are an expired grant, not a code bug). A connector outage during a routine surfaces as a
  `connector` hard-stop alert (Claude_Task_Plan.md "Observability"); a scheduled-query identity failure
  surfaces as the §19 metric-absence alert. For any future downloadable secret, prefer **GCP Secret
  Manager + Workload Identity** over a key file.

- **Web-UI trigger restore (the one un-versioned config).** The routine schedules/triggers live only in
  the Claude-Code-on-Web UI. If that config is ever lost, **`python scripts/print_routines.py` is the
  restore script** — it reconstructs every routine's canonical trigger instruction (`Read Claude_Task_Plan.md.
  Perform <heading>.`) + cadence from `Claude_Task_Plan.md` + `ops/cadence.yaml`, ready to re-create the
  triggers. `state.instruction_drift` (cadence_check) detects a *drifted* live trigger; `scripts/check_cadence_consistency.py`
  (CI) keeps the canonical sources + the SQL in lockstep (§24). If/when the platform exposes triggers-as-code
  or an export, adopt it to remove this last manual-restore step.
- **Heartbeat.** The freshness email is the liveness signal; if it stops arriving entirely (vs. firing
  red), that absence is itself the alert — note this so a silent scheduler death is noticed. The
  failure email canNOT do this on its own (a query that never runs sends no email), so a Cloud
  Monitoring **metric-absence** alert on a per-run heartbeat metric is the backstop — now codified in
  `infra/terraform/monitoring.tf`. **It must be identity-agnostic AND count run completion, not
  success** (see §19 — a success-only heartbeat false-alarmed across the SA migration the day after).

## 16. Publish the health dashboard *(D1)*
`.github/workflows/dashboard.yml` builds `ops/dashboard/index.html` from BigQuery and deploys it to
GitHub Pages. **OFF by default and double-gated** (the page shows live trading data): enable only by
setting repo variables `PUBLISH_DASHBOARD=true` **and** the WIF vars (§6), and only on a PRIVATE repo
with access-controlled Pages (Settings → Pages → Private), or accept public exposure. **On a personal
(non-Enterprise) repo, Pages publishes PUBLICLY even for a private repo — so do NOT use the Pages path
there.**

### Recommended hosted option — Looker Studio (Google-auth gated, no public exposure)
This is the recommended way to get a continuously-fresh hosted dashboard without exposing live data.
It stays private to your Google account unless you explicitly share it; viewing requires Google login.
1. Go to https://lookerstudio.google.com → **Create → Report** → add a **BigQuery** data source.
2. Authorize, pick project `stock-trading-498512`, and add these as data sources (Custom query or
   table per view), each in **US**:
   - `state.system_health` (the green/red rollup — put `all_green` on a scorecard up top)
   - `perf.kill_flags` (per-strategy drawdown / excess / closed-trades / firing flags)
   - `analytics.strategy_nav` (NAV / available_funds / sizing_base_2pct)
   - `state.cadence_watch` (filter `needs_attention = true` — a table that should stay empty)
   - `ops.alerts` (filter `resolved = false` — open alerts)
   - `ops.run_log` (recent routine runs)
3. Build the report (scorecards + tables); set the data-source **freshness** to ~1 hour.
4. **Keep it private:** do NOT use "Share → Anyone with the link." Share only to your own Google
   account / specific addresses. (Optional: point the data sources at a dedicated read-only viewer
   service account instead of "Owner's credentials.")
This needs no repo/CI changes and no `PUBLISH_DASHBOARD`. The static `ops/dashboard/generate_dashboard.py`
remains for ad-hoc local viewing (`python ops/dashboard/generate_dashboard.py` → open `index.html`).

## 17. Public-exposure guardrail — enforce `iam.disablePublicIamGrants` *(security, deferred)*
From the 2026-06-19 public-exposure audit. IAM is clean today (no `allUsers` /
`allAuthenticatedUsers` on the project or any BigQuery dataset, GCS bucket has Public Access
Prevention enforced), but nothing *prevents* a future accidental public grant. The
`iam.disablePublicIamGrants` org-policy constraint rejects any such binding outright — turning
"clean today" into "can't be made public by accident."

**Not actionable yet:** the constraint can only target a resource under a **Google Cloud
Organization**, and `stock-trading-498512` is a standalone project with no Org (the Org Policies
page returns "select a resource under an organization"). When/if you attach the project to an Org
(requires Google Workspace or Cloud Identity + domain verification — owner-only setup):
1. IAM & Admin → **Organization Policies** → constraint **`iam.disablePublicIamGrants`** ("Disable
   public IAM grants") → set **Enforced** at the org or project level.
   CLI: `gcloud resource-manager org-policies enable-enforce iam.disablePublicIamGrants --project=stock-trading-498512`
   (only succeeds once the project is under an Org where the constraint is available).
2. Related, optional: enforce `iam.allowedPolicyMemberDomains` (Domain restricted sharing) to
   confine bindings to your own domain.

## 18. Weekly performance self-email *(reporting)* — owner deploys the Apps Script
A weekly HTML digest of how the system is doing (regime, active/inactive strategies, per-strategy
budget + deployed performance, this week's activity, ops health) emailed to you automatically.

**Why an Apps Script, not a Claude routine:** the official Gmail connector can only *draft*, not
send. So delivery is owned by a **Google Apps Script** that runs on Google's servers as you, on a
weekly trigger, reads BigQuery directly, and self-emails (from you, to you — no SMTP, app password,
or API key needed). Nothing lands in Drafts. Files: `ops/weekly_report/` (`weekly_report.gs`,
`appsscript.json`, `README.md`, `sample_preview.html`). Data SQL: `bigquery/14_weekly_report.sql`.

**Owner action (one-time, ~3 min):** follow `ops/weekly_report/README.md` — paste `weekly_report.gs`
into a new script.google.com project, add the **BigQuery** advanced service, run `testReport` (approve
BigQuery + Gmail scopes), then run `installWeeklyTrigger`. Set the project timezone to America/Denver.

**Claude-side dependency (already wired):** D2 Step 0b writes one `ops.account_snapshot` row/day
(account NAV + Week/MTD/YTD TWR from the IBKR connector — the only datum the script can't fetch
itself). Until D2 runs once after this change, the email header falls back to the BigQuery
reconciliation NAV and shows `—` for account TWR; per-strategy deployed-TWR renders regardless.

## 19. "Freshness scheduler absent >25h" — the 2026-06-20 FALSE ALARM *(monitoring)*
**Symptom.** Cloud Monitoring policy *"Freshness scheduler absent >25h"* (condition *"No successful
freshness run in 26h"*) fired at **2026-06-20 23:41 UTC** on metric
`logging.googleapis.com/user/freshness_scheduled_run`, grouped on `__missing__`.

**It was a FALSE alarm — the dead-man's switch was healthy.** Verified at the time:
- `state.system_health.all_green = TRUE`; `ops.alerts` had zero open rows; D1/D2/D3 logged
  `completed` through 2026-06-20 in `ops.run_log`.
- The freshness scheduled query **ran and succeeded** at 2026-06-20 **05:00** and **19:29 UTC**
  (the latter only ~4h *before* the alert), per `region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
  (`job_id LIKE 'scheduled_query%'`, freshness body, `state=DONE`, no `error_result`).

**Root cause — an un-versioned monitor with a success-only heartbeat, tripped by the SA cutover.**
On **2026-06-19 ~21:30 UTC** the scheduled queries were moved off the owner's OAuth
(`jacksterwu@gmail.com`) onto the dedicated SA **`bq-scheduler@stock-trading-498512.iam.gserviceaccount.com`**
(the §15 "make the monitor independent of the agent identity" fix — and the point at which
freshness/cadence/backup actually began running on a reliable daily schedule). The log-based metric
`freshness_scheduled_run` was hand-built in the Console and went absent for >25h across that cutover,
so the policy fired. The runs never stopped; the *counter watching them* lost its signal.

**Verified live config (Claude-in-Chrome console inspection, 2026-06-21).** This *corrects* an earlier
hypothesis that the filter pinned `principalEmail` — it does **not**:
- **Metric filter (live):** `resource.type="bigquery_dts_config"`,
  `resource.labels.config_id="6a9c1592-0000-2caa-86b1-089e08214038"` (the freshness config, running as
  `bq-scheduler@`), `jsonPayload.message:"completed successfully"`. No identity label, no principal pin.
  **The defect is the message clause:** `"completed successfully"` matches only the per-JOB success line,
  so it is **success-only** — it records nothing for a red/failed run, and had no sample across the
  migration window. (A log-based metric also does not backfill, so it only counts from when its filter
  last matched forward.)
- **Policy (live):** a **PromQL** condition, not classic MetricAbsence (which caps at 24h and so cannot
  express >25h): `absent_over_time(logging_googleapis_com:user_freshness_scheduled_run[25h])`. No
  group-by, no label selector. The **`__missing__`** in the alert email was simply the metric having
  **zero time series** during the absence — not an identity-derived label.
- **Channel:** one email channel → `jacksterwu@gmail.com` (correct: alerts go to a human inbox; the
  `bq-scheduler@` SA is the query *run* identity, never an alert *recipient*).
- The incident **auto-resolved 2026-06-21 06:40 UTC**, once the 05:00 UTC run produced a sample.

**Immediate fix (owner, Console — makes the heartbeat terminal-agnostic).** In **Logging → Log-based
metrics → `freshness_scheduled_run` → Edit filter**, swap the success-only clause for the per-run
`Summary:` line (the DTS emits exactly one, on success *and* failure):

```
resource.type="bigquery_dts_config"
resource.labels.config_id="6a9c1592-0000-2caa-86b1-089e08214038"
jsonPayload.message=~"^Summary: succeeded"
```

(`"Summary: succeeded 1 jobs, failed 0 jobs."` on success; `"...succeeded 0 jobs, failed 1 jobs."` on
failure — both match.) Preview logs to confirm a hit in the last 24h, save. Liveness ("did the scheduler
fire") is now orthogonal to green/red — red is already covered by the freshness failure email, so a red
run no longer also masquerades as a *dead* scheduler. The policy itself needs **no change** (the bare
`absent_over_time` is already identity-agnostic).

**Durable fix (in-repo, this change).** `infra/terraform/monitoring.tf` codifies the metric + the PromQL
policy + email channel, with the config-id-keyed, terminal-agnostic filter (the `config_id` is derived
from the `freshness_check` resource, so Terraform re-points it automatically on any recreate).
`scheduled_queries.tf` + `var.scheduled_query_service_account` codify the live state that all four
scheduled queries run under the dedicated SA. Adopt via **import-then-apply** (`infra/terraform/README.md`).

**Lesson.** This is the §1/§12/§15 anti-pattern (control-plane config living only in a Console,
un-reviewable) biting the monitoring layer. A heartbeat/absence alert on a scheduled job must (a) key on
the **job/config identity-agnostically** (never the run principal), and (b) count run **completion**, not
success — otherwise an identity rotation OR a red run re-creates this false alarm.

## 20. Silent loss of a routine's git output — the 2026-06-14 W5/W2 data loss *(durability)*
**Discovered 2026-06-21** by the W5 routine: the **2026-06-14** W5 cycle's `.md` edits
(`B_Sub_Pattern_Taxonomy.md`) never reached `main`, even though its `events.decision_log` outcome
(BigQuery) did. Same for that Sunday's **W2** (`Weekly_Post_Event_Screen.md`). W1 and W3 from the same
day merged fine.

**Root cause — a fixed concurrency race in the OLD auto-merge.** Before the **2026-06-19** rewrite
(commit `edcbc22`), `auto-merge-claude.yml` triggered per-push and merged **one branch per run** under
`concurrency: group=auto-merge-main, cancel-in-progress=false` — which keeps only ONE pending run and
**drops** the rest. On Sunday 6/14 five weekly sessions (W1–W5) pushed within minutes; the surplus
auto-merge runs were dropped, stranding W2 and W5, whose branches were later cleaned up. BigQuery writes
survived because they never go through git. The 6/19 rewrite (drain **all** un-merged `claude/*` branches
each run, + green-CI gate, + conflict→PR fallback) fixed exactly this; the 6/21 cycle merged W1/W2/W3/W5
cleanly, confirming it.

**Blast radius.** Only **cumulative** files lose data lastingly: `B_Sub_Pattern_Taxonomy.md` (W5) appends
instances, so 6/14's were truly missing → **back-filled by the 2026-06-21 W5 run** (recovered via the
decision_log backstop). Overwritten-each-run files (`Weekly_*`, `Daily.md`) are moot (the current version
is fresh). BigQuery outputs were never at risk. Earlier cycles (≤ 6/7) may still have un-merged taxonomy
additions — clear with a one-time **full-history W5 taxonomy reconcile** (walk all `decision_log`
B-strategy entries vs the taxonomy tables; back-fill misses; dedupe).

**The monitoring gap (now closed).** A routine logs `completed` in `ops.run_log` (BigQuery) the moment it
finishes, but its committed `.md` output only persists if its branch **merges to main**. A branch whose CI
stays red (auto-merge skips it) or an unresolved `Auto-merge conflict:` PR strands the output silently —
and every monitor (freshness/cadence) watches BigQuery, so none see the git↔BigQuery divergence. That is
why this sat undetected until W5 happened to notice.

**Fix: `.github/workflows/stranded-branch-check.yml`** — a scheduled sweep (every 6h) that flags any
`claude/*` branch unmerged > 6h, or any open `Auto-merge conflict:` PR, and opens a deduped GitHub issue
(notifies the owner) + fails the run. Delivery is a GitHub issue, **not `ops.alerts`**, because writing
`ops.alerts` from CI would require granting the deliberately read-only CI identity (RUNBOOK §6) BigQuery
write. **Optional `ops.alerts` upgrade:** grant the WIF SA `roles/bigquery.dataEditor` on the `ops`
dataset (or a custom role with only `bigquery.tables.updateData` on `ops.alerts`) and have the workflow
`bq query` an `INSERT` via the existing WIF auth — then it flows through the alert-emailer + weekly report
+ `state.system_health` like every other alert. Left off by default to keep CI read-only.

**Second incident — 2026-06-22 (a *different*, still-open gap: the never-pushed branch).** The 6/22 daily
cycle (D1 `fervent-franklin-2cu646`, D2 `kind-thompson-1efmei`, D3 `great-brown-pf7414`) logged `completed`
in `ops.run_log` with BigQuery outputs intact (queue drained 6/21, GOOGL adjudicated, marks/engine through
6/22), yet **none of those branches ever reached the remote** (`git branch -r` shows only `main` + the
active session branch) and `main`'s `Daily.md` stayed frozen at 6/21. This is **not** the pushed-but-unmerged
race above: the branches were **never `git push`ed** at all — the session containers died before their push
step (cf. the 6/21 INTC-redo note: *"the d2-20260621 subagent that died on a usage limit and wrote nothing"*),
then were reclaimed, so those commits are gone.

**Why the existing monitor does NOT catch this.** Both `auto-merge-claude.yml` and `stranded-branch-check.yml`
iterate `refs/remotes/origin/claude/*` — **remote** branches only. A branch that never pushed has no remote
ref, so the sweep is structurally blind to it; and CI cannot close the gap (no BigQuery access — §6 — and
zero git trace on the remote). The *only* signal of a never-pushed completed session is `ops.run_log` (BQ): a
`status='completed'` row whose `branch` is neither present on the remote nor an ancestor of `main`.

**Effective fix (owner decision — needs BQ + git together, so it cannot live in CI).** A routine-side
reconciliation (e.g. D2 Step-0, which already reads `run_log` and has BQ via MCP): for each session logging
`completed` in the last ~36h, assert its `branch` merged to `main` (or its expected `.md` output is present);
on divergence write `ops.alerts` (routines have BQ write) so it flows through the alert-emailer like every
other dead-man's switch. Alternatives: grant the CI WIF SA `bigquery.dataViewer` on `ops` so
`stranded-branch-check.yml` can cross-check `run_log` (re-opens the deliberately-read-only-CI question, §6);
or a standalone `scripts/check_stranded_sessions.py` run on a schedule. **Impact is low / self-healing** —
BigQuery holds all trade-relevant state, and the next successful D1/D2 regenerates the overwrite-each-run
`Daily.md` fresh — so this is a durability/observability gap, not a trading-correctness bug.


**Third occurrence + recurrence — 2026-06-24 (root cause confirmed; hardened).** D1 `sess-d1-20260624`
(branch `claude/fervent-franklin-z9oztl`) stranded again: `ops.run_log` shows `completed` with the full scan
note (MU FQ3 Day-0 6/25, CBRS −19.6% B-long candidate, FDX fails the 5% gate), but the branch has zero
trace on the remote and `main`'s `Daily.md` stayed at 6/23. The D2 Step-0 detector (§17) **fired correctly**
— one `never_pushed_branch` `warning` alert — and D2 deferred the MU/CBRS candidates to the next regenerated
`Daily.md` (well within the 10-day B windows), so no trading-correctness impact. With 6/22 this is **2 strands
in the last 3 trading days** (6/22 ✗, 6/23 ✓, 6/24 ✗) — a recurrence, not a fluke.
**Root cause (confirmed).** `Claude_Task_Plan.md` "Branch and state propagation" delegates the `git push` to
the **harness at session end**; the routine never pushes itself. The `completed` row is written to BigQuery
*mid-session* (MCP network call), so any abnormal session end (the documented trigger: a usage-limit cutoff,
then container reclamation) between the work and the harness push strands the local commit while `run_log`
already reads `completed`. GitHub/CI/auto-merge are not at fault — the branch never reaches the remote at all.
**Hardening (this branch).** (1) **Eliminate the divergence at the source:** routines now **explicitly push
their own assigned branch and verify it** (`git ls-remote --exit-code`) *before* logging `completed`, and log
`'failed'`/`'halted'` if the push can't be confirmed — so `completed` reliably implies "branch on remote"
(Claude_Task_Plan.md → "Session end" + Observability END template). (2) **Make a real strand un-missable:**
the §17 detector now escalates `never_pushed_branch` from `warning` to **`critical`** (flips `all_green` →
fires the freshness DTS email) on data-loss (cumulative-file strand), recurrence (≥2 in 5 trading days), or
unhealed cases; a lone self-healing `Daily.md` strand stays `warning` to avoid alarm fatigue. (3) **Email the
self-healing class too:** `ops/monitoring/alert_emailer.gs` was notification-incomplete — it queried
`WHERE NOT resolved` on a 2h poll, so any alert created-and-resolved inside one poll window (the self-healing
class: a stranded-session warning, a cadence `missed_run` the next run clears) was **never emailed**, even
though the relay was alive (heartbeat fresh, but `notified_ts` NULL on those rows). Fixed to key on
`notified_ts IS NULL` (bounded to 48h) so every raised alert is relayed exactly once — resolved-since-raise
ones included, tagged AUTO-RESOLVED. **Deploy step:** re-paste `alert_emailer.gs` into the Apps Script
project (the `notified_ts` column already exists from `bigquery/18_stack_review_fixes.sql`).

Status (2026-06-23): **detector closed RUNBOOK 20's second incident** — Operating_Protocols.md 17 codifies it; merged to main via claude/never-pushed-reconciliation.
Status (2026-06-24): **root cause confirmed + hardened** (explicit verified push gating the `completed` log; severity escalation on data-loss/recurrence/unhealed) — Claude_Task_Plan.md "Session end"/Observability + Operating_Protocols.md 17.
## 21. `events.*` append-only convention — the `sub_pattern` in-place exception *(data governance)*
`events.*` is the **append-only source of truth** (schema description: *"INSERT/Storage-Write only; never
UPDATE/DELETE"*; `decision_log`: *"corrections are new rows with `superseded_by`"*). That invariant is
deliberate — decisions/outcomes must be immutable and auditable.

**The one sanctioned exception (added 2026-06-21):** the **pure-classification metadata** column
`events.decision_log.sub_pattern` MAY be normalized **in place** (UPDATE) by **W5** (the taxonomy owner),
provided an **old→new audit trail** is recorded in `B_Sub_Pattern_Taxonomy.md` (W5 run-log). Rationale:
`sub_pattern` is a free-text classification tag, not a decision/outcome; using the `superseded_by`
new-row pattern to fix a tag would duplicate ~120 rows per relabel for zero analytic gain. **All other
columns — `decision`, `conviction`, `conviction_pct`, `body_md`, `title`, outcomes — remain strictly
append-only** (corrections via a new row + `superseded_by`; never UPDATE/DELETE). Reversible via 7-day
time-travel; the documented mapping makes the pre-state recoverable beyond that. The live table
description (`bigquery/01_schema.sql`) carries this exception too.

**Why this section exists — the two 2026-06-21 normalizations that established it:**
- **9-row family-level reconcile** — fixed entries whose raw `sub_pattern` *contradicted* the curated
  taxonomy (e.g. DG/MRNA tagged SP1 but actually Mechanical; HIMS tagged SP8 but SP4); the taxonomy
  itself had already flagged those tags as stale.
- **111-row full normalization + canonical vocabulary** — conformed the entire Strategy-B history to the
  controlled token set (`SP1`/`SP4f`/`PatternN`/`Mechanical (…)`/…, `(candidate)` suffix, `[overlay: …]`),
  documented in the "Sub_pattern canonical vocabulary" block at the top of `B_Sub_Pattern_Taxonomy.md`.

**Going forward:** the routine that logs B NO-GOs (**D2**) should emit the canonical tokens directly (see
that vocabulary block); **W5** conforms any drift in its weekly pass. Anything beyond `sub_pattern`
stays append-only.

## 22. `instruction_drift` false alarm from ad-hoc runs reusing a routine id — the 2026-06-22 W5 alert *(monitoring)*
**Fired 2026-06-22 05:15 UTC** (`scheduled.cadence` / `instruction_drift`, WARNING): *"Trigger drift: routine(s)
whose live web-UI trigger differs from the canonical catalog: W5."* **It was a false positive — the scheduled
W5 web-UI trigger was never edited.**

**Root cause.** `state.routine_last_instruction` took the **most-recent non-null** `ops.run_log.instruction`
per routine, and `state.instruction_drift` diffs that against `ops.routine_catalog`. On 2026-06-21 the W5 id was
used by **four** sessions: the genuine scheduled Sunday W5 (which discovered the §20 loss), plus **three one-time
§20/§21 remediations** (full-history taxonomy reconcile, the 111-row `sub_pattern` normalization, and the
DLTR/GTLB/CPRI review-item resolution). W5 legitimately owns the taxonomy, so those ad-hoc sessions reused its id —
but each logged its **task description** as `instruction` instead of the verbatim trigger. The most-recent one
(`"sub_pattern normalization — review-item resolution…"`) shadowed the real trigger → `live ≠ canonical` → drift.
A secondary contributor: the scheduled run itself logged a **shorthand** (`…Factbase & Analytics Consolidation`,
dropping the ` — regular routine.` suffix), so even after excluding the ad-hoc notes the live read still differed.

**Fix (deployed 2026-06-22).**
1. **`state.routine_last_instruction` now only counts canonical-trigger-shaped instructions** —
   `instruction LIKE 'Read Claude_Task_Plan.md. Perform %'` (`bigquery/10_observability.sql`). Free-form ad-hoc
   notes can no longer masquerade as a routine's live trigger; a genuinely typo'd/edited trigger still lands inside
   that shape and is still caught. Trade-off: a trigger rewritten to *not* start with that prefix reads as "no live
   trigger" (live NULL → not drifted) rather than drift — acceptable and visible (a routine that ran yet shows a
   NULL live trigger is itself a yellow flag).
2. **Behavioural guard (the durable one):** `Claude_Task_Plan.md` "Observability" now states that `<instruction>`
   is the **trigger-of-record**, not a task note — ad-hoc/one-off sessions that reuse a routine id must still pass
   the **verbatim scheduled trigger**; what the one-off did goes in `<note>`/`session_id`.
3. **Data correction:** restored the dropped ` — regular routine.` suffix on the one genuine 2026-06-21 scheduled
   W5 run (`run_log.instruction`), so the live trigger now matches canonical and the view reads clean. (The next
   scheduled W5 re-logs the verbatim trigger and self-confirms; if the real web-UI trigger ever *did* lack the
   suffix, the hardened detector would re-fire then — nothing is permanently masked.)
4. Resolved the open `ops.alerts` row with a note pointing here.

**General rule.** A drift/`unknown_routine` alert is a **config bug to fix, not a halt** (it does not RAISE). First
confirm whether it is a real edited trigger (diff `state.routine_last_instruction` vs `python scripts/print_routines.py`)
or — as here — an ad-hoc session that logged a non-trigger instruction. Fix the cause, then
`UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note='…' WHERE alert_id='…'`.

**Update 2026-06-29 — re-fire; now a CONFIRMED genuine web-UI trigger drift (NOT a false alarm).** Fired
again 2026-06-29 05:15 UTC, same routine (W5), same shape: live `…Factbase & Analytics Consolidation` vs
canonical `…Factbase & Analytics Consolidation — regular routine.` (the dropped ` — regular routine.` suffix).
This is exactly the re-fire fix #3 above predicted. Diagnosis (decisive):
- The genuine scheduled **2026-06-28** Sunday run (`w5-20260628-quirky-hopper`) logged its verbatim trigger
  WITHOUT the suffix. That instruction IS in the canonical `Read Claude_Task_Plan.md. Perform %` shape, so the
  §22 hardening correctly let it through — this is **not** an ad-hoc-shadow false positive this time.
- **W5 is the ONLY drifted routine.** Every other run-logged routine — including **W4**, also a "regular
  routine" — logs the full ` — regular routine.` / ` — deep research.` suffix exactly. So this is a
  W5-specific web-UI trigger typo, not a systematic operator habit.
- The in-repo canonical side is **fully consistent**: the W5 plan heading carries the suffix and
  `python scripts/check_cadence_consistency.py` passes (`ops.routine_catalog` == plan-derived). **There is no
  repo bug to fix.**

Root cause (now confirmed): the **live W5 web-UI trigger genuinely omits ` — regular routine.`**. The
2026-06-22 data-correction (#3) only rewrote `ops.run_log`; it cannot change the operator-owned web-UI
trigger, so the next scheduled run re-logged the drifted text and re-fired — precisely as #3 warned.

**Durable fix is OPERATOR-OWNED (web UI, not repo) — a session cannot edit the trigger.** In
Claude-Code-on-Web, edit the W5 routine's trigger instruction to read EXACTLY (matching W4 and all 22 other
routines):
> `Read Claude_Task_Plan.md. Perform W5. Factbase & Analytics Consolidation — regular routine.`

After that, the next W5 run self-confirms (`state.instruction_drift` reads clean) and the WARNING auto-ages
(cadence_check.sql #14).

**Do NOT** weaken `state.instruction_drift` to strip the type-suffix — the ` — deep research.` /
` — regular routine.` tag carries the session-mode signal, so a trigger naming the WRONG type is a real drift
worth catching. **Do NOT** re-apply the §22 #3 `run_log` band-aid either: now that the trigger is *known* to
genuinely lack the suffix, rewriting the 2026-06-28 `instruction` to add it would falsify the
trigger-of-record audit trail to mask a live, unfixed config bug — leave `run_log` honest and fix the trigger.
The open `ops.alerts` WARNING is non-raising (never blocks `all_green`); leave it as a weekly reminder until
the trigger is fixed, or resolve-with-note pointing here — either way it auto-ages 7 days after the next W5
run logs the corrected trigger and the condition heals.

## 23. Semantic precedent layer — embedding coverage + the chunking upgrade *(analytics)*
**Done 2026-06-22 (conservative step):** `bigquery/02_ai_layer.sql` now embeds an 8,000-char excerpt
(up from 6,000) of `title + body_md`, filling text-embedding-005's ~2,048-token input budget for
prose-heavy entries. Same one-row-per-entry schema, so `state.embedding_health` (the embedding half of
`all_green`) and `analytics.find_precedents` are unchanged. **Apply:** re-run `bigquery/02_ai_layer.sql`
via the MCP — the `CREATE OR REPLACE TABLE … AS SELECT FROM ML.GENERATE_EMBEDDING` rebuilds
`analytics.decision_embeddings` atomically (Vertex-billed, ~pennies at ~250 rows; `state.embedding_health`
should stay `is_healthy=TRUE` after). Until re-run, retrieval keeps using the 6,000-char vectors.

**Known residual + the real fix (CHUNKING).** Bodies up to ~74k chars exist, so content past the model's
token cap is still not embedded — a modest recall gap on long theses (the lead carries the decision +
reasoning, so single-vector retrieval is usually sufficient, which is why this is staged, not urgent).
Full coverage needs **one embedding row per `(entry_id, chunk_index)`**:
- `analytics.decision_embeddings` gains `chunk_index`; split `body_md` into ~6k-char chunks (title on
  chunk 0); `ops.sp_embed_pending` keys its MERGE on `(entry_id, chunk_index)`.
- `find_precedents` runs `VECTOR_SEARCH(top_k => 30)` then `QUALIFY ROW_NUMBER() OVER (PARTITION BY
  entry_id ORDER BY distance)=1` and `LIMIT 10` — best chunk per entry, still 10 distinct precedents.
- `state.embedding_health` changes its invariant from "exactly one embedding per entry" to "every entry
  has ≥1 ok chunk AND zero errored chunks" (drop the `dup_rows = COUNT − COUNT(DISTINCT entry_id)` check —
  multiple chunks per entry become expected; replace with a per-`(entry_id,chunk_index)` uniqueness check).
  Keep it fail-loud (COALESCE→unhealthy) since `all_green` depends on it.
This reshapes a live table + the dead-man's-switch input + retrieval, so it is a **deliberate, separately-
applied + validated change** (re-embed into a scratch table, diff `find_precedents` top-k vs current, then
cut over). The optional move to **`gemini-embedding-001`** (higher retrieval quality; 3072-dim default,
or set `output_dimensionality`) rides the same re-embed — change the `ENDPOINT` on `ops.text_embed` and
re-run `02` (query + doc embeddings both switch, so the space stays consistent). Validate before relying
on it for live precedent.

## 24. Cadence single-source — `monitor_class` + the CI consistency gate *(maintainability)*
**Done 2026-06-22.** "What runs when" was hand-kept in THREE places with no automated guard —
`ops/cadence.yaml`, the hardcoded `state.cadence_expected_today` list (`bigquery/12_cadence_monitor.sql`),
and the `ops.routine_catalog` seed (`bigquery/15_routine_catalog.sql`) — plus the canonical headings in
`Claude_Task_Plan.md`. Drift between them is the recurring §22-class problem. Fix:
- Each `ops/cadence.yaml` routine now carries an explicit **`monitor_class`** (the canonical cadence
  bucket: `daily_trading` / `daily_all` / `weekly_sun` / `monthly_ftd` / `quarterly_ftd` / `annual_ftd` /
  `queue_driven`) — this manifest is the SOURCE OF TRUTH for the SQL bucket mapping.
- **`scripts/check_cadence_consistency.py`** (wired into the CI `test` job) FAILS the build unless: (A)
  `state.cadence_expected_today`'s `(routine → class)` set equals the calendar-class routines in
  `cadence.yaml` (queue-driven AR routines excluded), (B) `ops.routine_catalog`'s instructions equal the
  ones derived from the `Claude_Task_Plan.md` headings, and (C) every cadence.yaml id maps 1:1 to a plan
  heading. It CHECKS the SQL (does not regenerate it — the `.sql` keep their hand-written comments), so a
  routine added/renamed/rescheduled in one place but not the others now fails CI with a precise diff
  instead of surfacing weeks later as a false cadence / `instruction_drift` alert. `scripts/print_routines.py`
  remains the human-facing printer + the web-UI trigger restore script (§15).

## 25. Stack-review fixes — 2026-06-24 (verified deltas)

A full workflow / storage / automation review (six layers, adversarially verified against the
already-done + settled record). Only genuine deltas were implemented; the settled decisions (Terraform
adoption §12, dbt view ownership §14) were respected — the Terraform additions below are **spec-only**,
never applied. **Repo artifacts are DONE; this section lists the owner/console apply steps.** New code:
`bigquery/18_stack_review_fixes.sql`, `bigquery/scheduled_queries/integrity_check.sql`,
`.github/workflows/alert-relay.yml`, `.github/workflows/keyless-sa-audit.yml`, `requirements-ci.txt`,
`infra/terraform/wif.tf`, `tests/test_cadence_consistency.py`, `tests/test_dbt_parity.py`, plus edits to
`backup_events_export.sql`, `cadence_check.sql`, `ci.yml`, `storage.tf`, `monitoring.tf`,
`dbt_project.yml`, `Claude_Task_Plan.md`, `alert_emailer.gs`.

> **APPLY ORDER for the BigQuery pieces:** apply `bigquery/18_stack_review_fixes.sql` via the MCP
> **first** (additive: new `state.*` views + two `ALTER ADD COLUMN IF NOT EXISTS` — no behaviour change;
> verified clean against live data 2026-06-24), **then** re-paste the updated `cadence_check.sql` +
> `backup_events_export.sql` scheduled queries, **then** (optionally) create `integrity_check.sql`.
>
> **`18` APPLIED + VERIFIED LIVE via the MCP 2026-06-24.** All 8 new objects clean: `append_only_integrity`
> 0 rows, `position_reconciliation` 0 drift, `trigger_attestation` 0 overdue, `stalled_runs` 0,
> `market_calendar_horizon` runway ~1651d, `embedding_scale_watch` 263/5000; both additive columns
> (`ops.backup_log.per_table_rows`, `ops.alerts.notified_ts`) present. `system_health` is unaffected by
> `18` (it references none of these); any `all_green=FALSE` seen during a trading day before D2 runs is the
> normal `marks_fresh` intraday transient (zero open alerts), which the evening-scheduled checks are timed
> to skip. The remaining scheduled-query re-pastes + `integrity_check.sql` (+ its `resourceViewer` grant)
> stay owner/console steps.

### Theme A — alert delivery (closes the single-inbox SPOF + the un-versioned poller)
- **A1 — second, different-class alert channel (live-on-edit spec).** `monitoring.tf` now creates a
  webhook notification channel (`var.alert_webhook_url`, guarded — empty = email-only) and the three
  scheduler-absence policies notify it **alongside** email. Every alert path today converges on ONE
  Gmail inbox / ONE Google account; a non-Google webhook breaks that correlation.
  **Owner:** set `alert_webhook_url` to a Slack/Discord/ntfy/Pub/Sub-push endpoint (NOT another Gmail
  address). Spec-only here (per §12); to make it live without Terraform, add the channel in the Console
  and attach it to the three "… scheduler absent >25h" policies.
- **A2/A3 — version-controlled relay (`.github/workflows/alert-relay.yml` + `scripts/alert_relay.py`).**
  A scheduled GHA reads `ops.alerts` via the EXISTING read-only WIF (no new grant) and POSTs to a webhook
  — a git-reviewable poller whose failure mode is uncorrelated with the owner's Google account, plus a
  once-daily staged-order reminder (A3) off `state.open_orders` so a silenced 07:00 calendar alarm is not
  the ONLY notice of an order to confirm. **OFF until** repo **secret `ALERT_WEBHOOK_URL`** + the WIF vars
  are set. It COMPLEMENTS (does not replace) the reliable ~2h `alert_emailer`; keep the Apps Scripts until
  the relay is proven. **Do not retire `alert_emailer.gs`/`weekly_report.gs` yet.**

### Theme B — data durability & integrity
- **B1 — GCS Object Versioning (owner, gsutil).** `storage.tf` now declares `versioning{}` + a
  noncurrent-version lifecycle (keep 3 / 30 days). To apply live without Terraform:
  `gsutil versioning set on gs://stock-trading-backups` and add the noncurrent-version lifecycle rule
  (Console → bucket → Lifecycle). Makes a bad in-place overwrite of a `dt=` snapshot recoverable.
- **B2 — backup row-count evidence (repo done; re-paste).** `backup_events_export.sql` now records a
  per-table `{table: rows}` map in `ops.backup_log.per_table_rows` (column added by `18`). Re-paste the
  scheduled query after applying `18`. Auditable day-over-day; an append-only table's count only grows.
- **B3 — append-only integrity tripwire (`state.append_only_integrity` + `integrity_check.sql`).**
  Surfaces any out-of-band UPDATE/DELETE/MERGE on the immutable AUDIT-TRAIL tables (decision_log /
  position_events / trade_fills / regime_events / queue_events / adversarial_reviews / parking_events /
  hf_capability_captures), suppressing the one sanctioned W5 `sub_pattern` UPDATE. The reference/market
  feeds (`market_holidays` MERGE, `daily_marks` re-ingest, `macro_*`) are deliberately OUT of scope — they
  are maintained in place by design (verified live). **Owner console:** grant the `integrity_check`
  run-as SA **`roles/bigquery.resourceViewer`** (project-level — reads `JOBS_BY_PROJECT` job METADATA,
  not data) and create the `integrity_check.sql` scheduled query (daily ~05:20 UTC, email-on-failure ON).
  **Posture:** staged-rollout WARNING (record-only, delivered by the emailer/relay; does NOT flip
  `all_green` or RAISE). Baseline verified clean (0 rows). **Promote** to critical+RAISE once a clean
  baseline holds.
- **B4 — position-drift guard (`state.position_reconciliation`; `cadence_check` warning + dbt test).**
  `state.current_positions` (the 2%-sizing path) vs `analytics.position_lifecycle` (the TWR path) can
  diverge with no monitor; this flags a material per-(strategy,ticker) open-share gap (tolerance ignores
  sub-cent dividend-reinvest fractions — the live ~$0.20 drift does NOT trip it). Surfaced as a record-only
  warning in `cadence_check.sql` + the dbt singular test `assert_current_positions_match_lifecycle.sql`.

### Theme C — CI / merge / supply-chain hardening
- **C1 — `DBT_PARITY=block` fails closed (DONE, live-on-merge).** When `block`, a missing WIF var now
  FAILS the guard (was: skip-green) so the hard parity gate can't silently become a no-op after promotion.
- **C2 — drift-defense tests + advisory `dbt test` (DONE).** `tests/test_cadence_consistency.py` +
  `tests/test_dbt_parity.py` exercise the regex parsers / column-typing so a rotted regex is caught (not a
  vacuous pass); an advisory `dbt test` step runs the B3 invariant suite vs live each push (`::warning::`,
  never blocks).
- **C3 — pinned CI toolchain (DONE).** `requirements-ci.txt` (constraints) + `require-dbt-version` —
  every CI install is now version-bounded. **Owner (optional):** tighten the ranges to exact `==` from a
  green run's resolved versions for full reproducibility.
- **C4 — server-side merge gate (owner console).** Add a GitHub **repository ruleset** on `main` requiring
  the `options-math tests` check, with the **github-actions bot as a bypass actor** — so "main is CI-green"
  is server-enforced for every non-bot actor (token compromise / workflow edit / manual drain) WITHOUT
  forcing PRs for the bot path (the §5 objection no longer applies with bypass actors). **Validate the
  bypass end-to-end first** — a misconfigured bypass could wedge auto-merge.
  **STATUS 2026-06-24 — DEFERRED, not actionable on the current GitHub plan (like §17's org policy).**
  Attempting it found this repo (personal-account PRIVATE) offers only Active/Disabled enforcement — no
  "Evaluate" (dry-run) mode, which is an org/Team feature — AND the ruleset page warns rulesets "won't be
  enforced on this private repository until you move to a GitHub Team organization account." So a ruleset
  here cannot enforce the gate today, and Evaluate-then-flip isn't possible. Enabling it would require
  GitHub Pro (protected branches on a personal private repo) or moving the repo under a GitHub Team org.
  Until then the **bash-level per-SHA CI gate in `auto-merge-claude.yml` remains the merge gate** — no
  regression, that is the status quo. Revisit if/when the repo moves to a Team org (pairs naturally with
  §17's org adoption).

### Theme D — workflow observability
- **D1 — research-feeder freshness gate (DONE, instruction-layer).** W4/M4/Q4/A3 now assert each upstream
  research `.md`'s first-line **period marker** equals the current period before `sp_routine_start`, so the
  dependency gate bites NOW (it was inert for the not-yet-monitored research routines). See
  `Claude_Task_Plan.md` "Observability".
- **D2 — deleted-trigger attestation (`state.trigger_attestation`; `cadence_check` warning).** Flags a
  low-frequency routine (the weekly/monthly/quarterly/annual ones the cadence ALARM excludes) that has
  logged no completed run across its cadence window — a DELETED (vs edited) trigger `instruction_drift`
  can't see. Self-bootstrapping (only routines that have ever completed).
- **D3 — GO-without-order check (`state.go_without_order`; D3 instruction).** Anchors on the GO decision
  to catch a GO whose `ORDER_STAGED` row was never written (session died mid-step) — invisible to the
  registry-centric reconciliations. D3 adjudicates each candidate.

### Theme E — identity & governance
- **E1 — WIF trust binding codified + verify (`infra/terraform/wif.tf`, spec-only).** Documents the
  pool/provider `attribute_condition` + the `workloadIdentityUser` principalSet that scope impersonation
  to this repo. **Owner (read-only verify):** run the two `gcloud … describe` / `get-iam-policy` commands
  in `wif.tf`'s header and confirm the live binding pins `assertion.repository` to `JackOfSpade/Stock-Trading`
  (and is NOT a pool-wide binding). Record the result here. This is the highest-severity item IF the live
  binding is fork-permissive; pure documentation if it is already scoped (likely).
- **E2 — keyless-SA audit (`.github/workflows/keyless-sa-audit.yml`, opt-in).** Monthly check that
  `gh-ci-runner@` / `bq-scheduler@` carry ZERO user-managed keys. **Owner to enable:** grant the WIF SA
  `iam.serviceAccountKeys.list` on those SAs and set `vars.RUN_SA_KEY_AUDIT=true`. The preventive analog
  (org policy `iam.disableServiceAccountKeyCreation`) is deferred for the same no-Org reason as §17.

### Marginals (scoped per the review)
- `ops.alerts.notified_ts` (column in `18`; `alert_emailer.gs` stamps it on send — re-paste the script):
  makes "was the human told?" queryable. De-dup still via Script Properties; re-fire-on-reopen preserved.
- `state.stalled_runs` — a DAILY routine `started` but never terminal (>=6h); `cadence_check` warning.
- `state.market_calendar_horizon` — FMP auto-extend liveness (warns if runway < 100 days; ~1500 today).
- `state.embedding_scale_watch` — near-free advisory mirroring `gate_watch` for the 5k VECTOR INDEX
  threshold (~13 years out; revisit the §23 chunking work when it approaches).
- **Left out deliberately** (review recommended "leave it"): an in-warehouse SNAPSHOT/CLONE layer for
  `events.*` (the proven daily GCS-Parquet + restore-drill path already covers >7-day recovery).

## 26. BigQuery-connector outage → cadence + freshness double-critical — the 2026-06-26 incident *(monitoring)*
**Symptom.** Two `critical` `ops.alerts` rows opened and emailed in one batch the night of 2026-06-26:
- `scheduled.cadence · missed_run` @ **2026-06-27 05:15 UTC** — *"Cadence check: monitored routine(s)
  expected today did not complete: D1, D2, D3"*.
- `scheduled.freshness · staleness` @ **2026-06-27 05:00 UTC** — *"Daily freshness check: system_health
  not green"*.

**Both are TRUE positives — the dead-man's switches working correctly. NOT a false alarm and NOT a code
bug** (contrast the §19 and §22 false alarms). They are two downstream symptoms of a single upstream
outage: on **2026-06-26** (Fri, a trading day) the **owner Google OAuth grant for the BigQuery MCP
connector expired** ("token expired / re-authorization required" — see the `Daily.md` 2026-06-26 *DEGRADED
MODE* banner). Consequences:
- **D1** ran **research-only** (open book + live marks read from the IBKR connector; regime carried forward
  from the prior `Daily.md`). With BigQuery unreachable it could **not** `ops.sp_routine_start/_end`-log, so
  no `completed` row landed in `ops.run_log`.
- **D2/D3 did not run at all** — D2 hard-stops on the connector (`ops.sp_assert_deps` / canonical-state
  reads), so the 6/26 close was never ingested.
- → `state.cadence_watch.needs_attention` flagged D1/D2/D3 (no logged run today), and `state.system_health`
  went not-green (marks/engine stale vs the last trading day). The two scheduled checks then RAISEd, each
  recording its idempotent `ops.alerts` row and firing the DTS failure-email.

**Why the monitors still fired while the agent was locked out.** The freshness/cadence scheduled queries run
as the dedicated **`bq-scheduler@` SA** (§15), a GCP-managed identity independent of the owner OAuth that
expired — exactly the §15/§19 "make the monitor independent of the agent identity" property. The control
plane kept watching while the data plane was down. The **21:00-MT cadence deadline guard** (§1 step 3) is
irrelevant here: the scheduled run is 23:15 MT (past the deadline) and the routines *genuinely* did not run,
so this is the real miss the guard is designed to let through — not a pre-deadline manual-run false positive.

**Resolution procedure** (the alert email's *"Resolve via UPDATE ops.alerts SET resolved=TRUE …"*). Fix the
**cause first**, then resolve the rows — do not blind-resolve a live red:
1. **Re-auth the connector (owner, no code change).** Re-consent the Google/BigQuery connector in the Claude
   connector settings (§15 credential table, row 1: most outages are an expired grant, not a code bug).
   Verify with any `state.*` read.
2. **Let the data catch up.** Re-run **D2** (then **D3**) for 2026-06-26 so `events.daily_marks` /
   `perf.strategy_daily` ingest the close → `state.system_health.all_green` returns TRUE and the **next**
   05:00 UTC freshness run stops re-raising. (The 6/26 *cadence* miss is historical — re-running won't
   retroactively un-miss it in `ops.run_log`; that is expected and fine.)
3. **Resolve the two open rows** once green:
   ```sql
   UPDATE `stock-trading-498512.ops.alerts`
   SET resolved = TRUE,
       resolved_ts = CURRENT_TIMESTAMP(),
       resolved_note = '2026-06-26 BigQuery MCP connector OAuth expired (Daily.md DEGRADED MODE): D1 '
                    || 'research-only, D2/D3 did not run. True-positive cadence missed_run + freshness '
                    || 'staleness. Connector re-authed; D2/D3 re-run so marks/engine caught up and '
                    || 'system_health is green. See RUNBOOK §26.'
   WHERE NOT resolved
     AND source   IN ('scheduled.cadence', 'scheduled.freshness')
     AND category IN ('missed_run', 'staleness');
   ```

A `[Claude] ATTENTION` calendar event was already created during the 6/26 D1 degraded run to surface the
outage for re-authorization (per `Daily.md`), so the two `ops.alerts` rows are a redundant — and correct —
second channel, not new information.

**General rule.** An outage-induced **cadence + freshness double-critical fired in the same batch** is the
expected signature of a connector/credential outage, not two independent bugs. Triage: confirm a same-day
DEGRADED-MODE run in `Daily.md`/`ops.run_log`; if present, the alerts are true positives → re-auth the
connector (§15), re-run the skipped action routines, then resolve the rows with a note pointing here. This
differs from §19 (a monitor whose own heartbeat metric went absent) and §22 (an ad-hoc run that logged a
non-trigger instruction) — both of which were monitor-side false alarms with nothing red underneath.

**Prevention adopted (2026-06-27).**
- **Blast-radius (done).** A uniform **connector pre-flight** is now the FIRST cross-cutting call in every
  routine (`Claude_Task_Plan.md` "Observability", ahead of run-logging / the dependency gate): one trivial
  BigQuery + IBKR liveness read up front, so a de-auth is caught in seconds and routed to the right handling
  (BigQuery down → calendar-only `[Claude] ATTENTION — RE-AUTH` + D1-degraded / D2-D3-halt, since the alert
  sink itself is down; IBKR down → the `connector` hard-stop). D1 already did this ad-hoc on 6/26; this makes
  it uniform and first-in-run, so a future de-auth surfaces same-minute instead of mid-routine.
- **Recurrence (operator).** The BigQuery MCP connector is **Anthropic's first-party Google connector**, so
  its OAuth client is Anthropic-managed and the de-auth is a Google-account-side grant lifecycle event, not a
  GCP-project setting we can change (verified 2026-06-27: nothing in the project console governs a first-party
  connector's refresh-token lifetime; the only relevant surface is *Google Account → Security → third-party
  access*, where the grant lives). Levers: re-consent proactively on a **quarterly** calendar cadence (tighten
  the §15 annual reminder), and keep the Google password/scopes stable (either revokes the grant).
- **Structural (deferred — real but not free).** A keyless **service-account / agent identity** for the
  interactive path would remove refresh-token expiry entirely (as `bq-scheduler@` already does for the
  scheduled queries). The BigQuery MCP server *does* support non-OAuth Google identities — but only on the
  **self-hosted / Google-managed remote MCP server**, NOT the first-party Claude connector this project uses
  (that path is owner-OAuth only). Adopting it means standing up a self-managed BigQuery MCP endpoint the
  Code-on-Web sessions can reach, with a SA holding the routines' **write** scope (not just read) — net-new
  runtime that cuts against the CLAUDE.md "MCP + console, no extra runtime" posture. Revisit only if the
  de-auth becomes frequent enough to justify the operational weight.

## 27. Stack-review fixes #2 — 2026-06-28 (verified deltas)

A third workflow / storage / automation review (six layers, adversarially verified against the already-done
+ settled record). Only genuine deltas were implemented; the settled decisions (Terraform adoption §12, dbt
view ownership §14) were respected — the Terraform additions below are **spec-only, never applied**, and no
new connector was added (a Slack/Twilio push channel was evaluated and deferred to the operator's call;
the already-built A3 relay just needs enabling — §25 A2/A3). **Repo artifacts are DONE; this section lists
the owner/console apply steps.**

**New code:** `bigquery/19_stack_review_fixes_2.sql` (state.ddl_drift), `bigquery/scheduled_queries/ops_export.sql`,
`bigquery/scheduled_queries/delivery_canary.sql`, `.github/workflows/wif-binding-audit.yml`,
`.github/workflows/offsite-backup.yml`, `tests/test_alert_relay.py`,
`dbt/tests/assert_open_positions_have_marks.sql`; **edits to** `bigquery/16_automation_health.sql` (backup_log.dataset
+ state.ops_backup_health), `bigquery/17_restore_drill.sql` (ops.drill_log + state.restore_health + typed-fidelity
check + events-pinned drill date), `bigquery/18_stack_review_fixes.sql` (state.stalled_runs generalized),
`bigquery/scheduled_queries/backup_events_export.sql` (dataset='events' marker),
`bigquery/scheduled_queries/cadence_check.sql` (ops_backup_stale / restore_stale / ddl_drift warnings +
warning auto-resolve), `infra/terraform/monitoring.tf` (restore_drill/integrity absence + SA-key alert),
`.github/workflows/ci.yml` (shell-lint job), `Claude_Task_Plan.md` (Calendar pre-flight + staging atomicity +
FMP mark fallback).

> **APPLY ORDER for the BigQuery pieces (via the MCP):** `16` → `17` → `18` → `19` (all additive/idempotent:
> ALTER ADD COLUMN IF NOT EXISTS, CREATE TABLE IF NOT EXISTS, CREATE OR REPLACE VIEW/PROCEDURE — no behaviour
> change to existing objects), **then** re-paste the scheduled queries `cadence_check.sql` (now reads
> state.ops_backup_health / state.restore_health / state.ddl_drift) + `backup_events_export.sql` (dataset
> marker), **then** create the two NEW scheduled queries `ops_export.sql` + `delivery_canary.sql`. **VERIFY**
> after applying `19`: `SELECT * FROM state.ddl_drift` should return **0 rows** (a clean baseline — if a benign
> `is_partitioning_column` reporting diff shows up for the `DATE(timestamp)` partitions, adjust the expected
> spec in `19` before relying on it). `state.ddl_drift` / `state.restore_stale` / fidelity stay **record-only
> WARNING** (staged rollout, like append_only_integrity); promote to critical+RAISE once a clean baseline holds.

> **APPLIED + VERIFIED LIVE 2026-06-29 (Cloud Shell + DTS REST API, owner).** All four schema files ran in
> order with no errors: `16` (added `ops.backup_log.dataset`, created `state.ops_backup_health`), `17`
> (replaced `sp_restore_drill`, created `state.restore_health`), `18` (replaced `state.stalled_runs` +
> peers), `19` (created `state.ddl_drift`). **Baseline clean:** `state.ddl_drift` = **0 rows** (monitor
> trusted); `state.stalled_runs` = 0; `state.ops_backup_health` / `state.restore_health` self-bootstrapping
> (`monitored=false` until first marker). `state.system_health.all_green=FALSE` at apply time was the normal
> pre-D2 `marks_fresh` intraday transient (0 open critical alerts). The two existing scheduled queries were
> re-pasted (`cadence-check-daily` ← `cadence_check.sql`; `events-backup-daily` ← `backup_events_export.sql`).
> The two NEW scheduled queries were created, run-as `bq-scheduler@`, email-on-failure ON, Location US:
> - **`ops-export-daily`** — every day 05:35 UTC; config_id `6a43d4f7-0000-276c-b1fb-7474463ce22d`. First run
>   auto-fired 2026-06-29 08:04 UTC; `state.ops_backup_health` → `monitored=true, stale=false,
>   last_backup_date=2026-06-29`; `gs://stock-trading-backups/ops/<table>/dt=2026-06-29/` Parquet confirmed.
> - **`delivery-canary-weekly`** — every Monday 05:40 UTC (next 2026-07-05); config_id
>   `6a42a5b5-0000-2c87-aa3f-f4f5e80c48cc`. Prereq confirmed (`state.automation_heartbeat` shows
>   `alert_emailer monitored=true, stale=false`, so notified_ts stamping is live).
>
> Still-optional follow-ups (separate owner tasks, not blocking): the Cloud Monitoring absence policies for
> restore_drill + integrity_check (#4 — supply their config_ids to `monitoring.tf` vars) and the
> `CreateServiceAccountKey` alert (#6); and — for full backup-scheduler symmetry — an absence policy on
> `ops-export-daily` (config_id above) mirroring `backup-scheduler-absent` (today a dead ops-export is still
> caught transitively via `state.ops_backup_health` → `cadence_check` `ops_backup_stale`).

> **PROMOTION LADDER — status 2026-06-29.** The staged-rollout gates promote only once a clean baseline has
> *held*; flipping on day one would risk flapping `all_green` / wedging the merge gate on a first-occurrence
> false positive (the same discipline that took dbt-parity advisory→block and integrity_check warning→critical).
> - **`shell-lint` → BLOCKING: DONE 2026-06-29.** Confirmed clean on the runner (CI #102, actionlint +
>   shellcheck all green), so `continue-on-error` was dropped in `ci.yml`. Hardened against tool-drift wedging
>   a *blocking* linter: actionlint pinned to **v1.7.12** (script + binary), shellcheck floored at `-S warning`.
> - **`ddl_drift` → critical: PENDING.** One clean read (0 rows, 2026-06-29) validates the encoding, but the
>   data-monitor baseline should hold ~1–2 weeks of clean daily `cadence_check` runs first. Then in
>   `cadence_check.sql` change the `ddl_drift` block's `'warning'`→`'critical'` and add it to `raise_msg`.
>   *Reminder set:* `[Claude] Review` calendar event **2026-07-14 09:00 MT** (carries the verify+flip steps).
> - **`restore_stale` → critical: BLOCKED (no baseline yet).** The monthly drill has not run since the change
>   (`state.restore_health.monitored=false`); promote only after ≥1 successful drill logs an `ops.drill_log` marker.
>   *Reminder set:* `[Claude] Review` calendar event **2026-08-04 09:00 MT** (verify `state.restore_health.monitored=true` first).
> - **`dbt-parity` → block: PENDING (owner repo-setting).** Requires the WIF repo vars set AND one clean parity
>   run observed; then set `vars.DBT_PARITY=block` (it FAILS CLOSED if the WIF vars are absent — RUNBOOK §25 C1).

> **CONSOLE ENABLEMENT — status 2026-06-29 (Chrome).** Live config_ids: `ops-export-daily`
> `6a43d4f7-0000-276c-b1fb-7474463ce22d`, `integrity-check-daily` `6a4d603d-0000-2d5d-b9af-14223bafe266`,
> restore-drill (monthly) `6a4ecee9-0000-2ec0-9c94-24058883b1bc`.
> - **Cloud Monitoring (#4/#6 + ops-export symmetry) — DONE for the daily jobs.** Log-based metrics created:
>   `ops_export_scheduled_run`, `integrity_check_scheduled_run`, `sa_key_created` (+ a `restore_drill_scheduled_run`
>   that should be removed — see next bullet). Alert policies created (channel `jacksterwu@gmail.com`):
>   "ops-export scheduler absent >25h" (`11665307314393105160`), "Integrity-check scheduler absent >25h"
>   (`4948636131821978669`), "SA key created on gh-ci-runner or bq-scheduler" (`3307594591438576313`).
> - **Restore-drill absence policy — REMOVE IT (wrong tool).** A "Restore-drill scheduler absent >33d" policy
>   (`13125720338366635305`) was created but Cloud Monitoring caps the PromQL absence lookback at ~25h, so it
>   was forced to `[25h]` — which on a MONTHLY job false-fires every day. **Owner: delete policy
>   `13125720338366635305` and metric `restore_drill_scheduled_run`.** Monthly drill liveness is covered correctly
>   by `state.restore_health` (40-day window) via `cadence_check` `restore_stale`. `monitoring.tf` was corrected to
>   drop the restore_drill absence spec for this reason.
> - **keyless-sa-audit — ENABLED + GREEN.** Custom role `SA_KeyList` (`iam.serviceAccountKeys.list`) granted to
>   `gh-ci-runner@` on both SAs; `vars.RUN_SA_KEY_AUDIT=true`. First run SUCCESS — both SAs keyless, confirmed.
> - **wif-binding-audit — ENABLED + GREEN (run #5); the early failures were TWO audit-script bugs, never a real
>   exposure.** The binding was repo-scoped throughout. Run #1 failed on a read-failure masking bug (it ran
>   seconds after the Section-C grants, before `workloadIdentityPoolViewer`/`serviceAccountViewer` propagated, and
>   `2>/dev/null || echo ''` turned the failed `gcloud` read into a false "empty condition") — **fixed**: a read
>   failure now exits 2 "COULD NOT VERIFY", distinct from a real exit-1 finding. Runs #2–#4 then failed because the
>   live `attributeCondition` used the **mapped-attribute form** `attribute.repository == "JackOfSpade/Stock-Trading"`,
>   while the matcher only accepted the literal `assertion.repository` — equivalent (attribute_mapping sets
>   `attribute.repository = assertion.repository`), so a brittle string match, not a security gap — **fixed**: the
>   matcher now accepts either form. On 2026-06-29 the live condition was normalized (owner, gcloud) to
>   `assertion.repository == 'JackOfSpade/Stock-Trading'` to match `wif.tf` line 91 exactly, and run #5 → GREEN.
>   Net: no fork could ever impersonate `gh-ci-runner@` (provider condition + repo-scoped principalSet both
>   confirmed); the E1 RESULT above stands. Also done this session: deleted the stray restore-drill policy/metric,
>   enabled `iam.googleapis.com`.
> - **dbt-parity hard gate — ALREADY ON.** `vars.DBT_PARITY=block` was already set (owner, prior week); WIF vars
>   `GCP_WIF_PROVIDER`/`GCP_WIF_SERVICE_ACCOUNT` confirmed present. The §27 ladder item is satisfied.
> - **DR blast-radius (#3) — DONE.** Project deletion lien created (`p191682978805-103ae3152-…`); Essential
>   Contacts set for all categories. NOTE: contact is `jacksterwu@gmail.com` (the same at-risk Google account) —
>   add a non-Google address if you want true resilience against account suspension. Off-site mirror: skipped (optional).

### Theme A — backup / DR completeness (the truth is protected; the audit trail + its trust boundary were not)
- **#2 — back up the irreplaceable ops.\* audit history (owner console).** `ops.run_log`/`alerts`/`backup_log`/
  `heartbeat`/`drill_log` are append-only history with NO upstream — yet only `events.*` was ever exported.
  Create `scheduled_queries/ops_export.sql` as a **daily** scheduled query (~05:35 UTC, after the events
  export; Location US; run-as `bq-scheduler@`, which already holds objectAdmin on the bucket; enable email-on-
  failure). It logs a `dataset='ops'` marker; `state.ops_backup_health` + `cadence_check` (`ops_backup_stale`,
  critical) then catch a stalled ops backup. The restore drill's date is now pinned to the events snapshot
  (`COALESCE(dataset,'events')='events'`), removing the self-referential fragility.
- **#3 — get one copy out of the project / trust domain (owner gcloud + optional GHA).** Today live truth AND
  its only backup share one project + one Google account. Three independent controls:
  (1) **project deletion lien** — `gcloud resource-manager liens create --project=stock-trading-498512
  --restrictions=resourcemanager.projects.delete --reason="protect append-only trading truth"`;
  (2) **Essential Contacts** (IAM & Admin → Essential Contacts) for LEGAL/SECURITY/TECHNICAL/BILLING, ideally a
  **non-Google** address, so a suspension/billing notice doesn't depend on the at-risk account;
  (3) **off-site mirror** — enable `.github/workflows/offsite-backup.yml` (set secret `OFFSITE_BACKUP_GCS` to an
  OFF-PROJECT bucket, grant the WIF SA `storage.objectViewer` on `gs://stock-trading-backups` + `objectAdmin`
  on the destination). OFF by default (clean no-op). Distinct from the §25-rejected *in-project* snapshot idea.
- **#13 — DDL-first restore + typed-fidelity drill.** See §3 "DDL-FIRST restore". Repo-done; no console step
  beyond using the documented procedure on a real recovery.

### Theme B — who-watches-the-watchers (newest monitors + highest-privilege controls)
- **#1 — verify + RECORD the live WIF trust binding (owner, HIGHEST severity).** The E1 verification (§25 E1)
  was specified but never done. Run the two read-only `gcloud … describe` / `get-iam-policy` commands in
  `infra/terraform/wif.tf`'s header and **record the literal result here**, replacing §25 E1's "Record the
  result here." If the provider has no `attribute_condition` or the `workloadIdentityUser` member is pool-wide
  (not `attribute.repository/JackOfSpade/Stock-Trading`), TIGHTEN it in the Console (it lets any repo mint a
  `gh-ci-runner@` token and read all live data). Optional standing guard: enable
  `.github/workflows/wif-binding-audit.yml` (grant the WIF SA `iam.workloadIdentityPoolViewer` +
  `iam.serviceAccounts.getIamPolicy` on `gh-ci-runner@`; set `vars.RUN_WIF_AUDIT=true`).

  **E1 RESULT — VERIFIED ✅ SCOPED (good), 2026-06-28** (Claude-in-Chrome console inspection, read-only; the §19 pattern):
  - `attribute_condition` (live, literal): `assertion.repository=='JackOfSpade/Stock-Trading'` — the OIDC
    token exchange is gated at the provider; a fork / any other repo's JWT cannot pass.
  - `roles/iam.workloadIdentityUser` member on `gh-ci-runner@` (live, literal):
    `principalSet://iam.googleapis.com/projects/191682978805/locations/global/workloadIdentityPools/github-pool/attribute.repository/JackOfSpade/Stock-Trading`
    — a repo-scoped `attribute.repository` principalSet, **NOT** a pool-wide `/*` wildcard.
  Both layers agree, so only `JackOfSpade/Stock-Trading`'s Actions can mint a `gh-ci-runner@` token and reach
  BigQuery. The highest-severity item is closed; no Console change needed. (The `wif-binding-audit.yml`
  standing guard remains optional belt-and-suspenders.)
- **#4 — scheduler-absence + liveness for restore_drill & integrity_check (owner console).** `monitoring.tf`
  (spec) now declares absence metrics+policies for both — supply their live `config_id`s via
  `var.restore_drill_config_id` / `var.integrity_check_config_id` (Console → the scheduled query → its
  transferConfig id), or add the metric+policy directly in the Console (same terminal-agnostic `^Summary:`
  filter + `absent_over_time` PromQL as the existing three; seed one run before attaching the policy — no
  backfill). The drill also writes an `ops.drill_log` marker every run → `state.restore_health` →
  `cadence_check` `restore_stale` warning (no console step; rides the BigQuery apply).
- **#6 — alert on `CreateServiceAccountKey` (owner console).** `monitoring.tf` declares a log-based metric on
  the Admin Activity `CreateServiceAccountKey` method for `gh-ci-runner@`/`bq-scheduler@` + a threshold alert
  (fires on any key creation; needs NO `keys.list` grant). Create it in the Console (Logging → Create metric;
  Monitoring → alert). Keep `keyless-sa-audit.yml` as the monthly state assertion.

### Theme C — test / static-analysis asymmetry
- **#5 — `shell-lint` CI job (repo-done; advisory).** `ci.yml` now runs actionlint (workflow YAML + embedded
  `run:` bash) + shellcheck (`scripts/*.sh`), the previously-unguarded high-stakes automation. **Advisory**
  (continue-on-error) so it can't red-light the merge gate on a pre-existing finding; **promote to a hard gate**
  (drop `continue-on-error`) once a clean baseline is confirmed.
- **#8 — `tests/test_alert_relay.py` (repo-done).** Offline tests of the bq-JSON slice helper (the exact
  regressed bug class) + the row-shape contract for the off-Google delivery channel. Auto-discovered by the
  always-on `test` job.

### Theme D — drift / per-name coverage
- **#7 — `state.ddl_drift` (repo-done; verify baseline).** Detects a silent out-of-band ALTER on the immutable
  `events.*` audit tables (NOT NULL / type / partition / cluster) vs `01_schema.sql` — the structural gap the
  view-logic (dbt-parity), DML (append_only_integrity), and trigger (instruction_drift) guards left open.
  Record-only warning; MAINTAIN the expected-spec UNNEST in `19` alongside `01_schema.sql`.
- **#11 — `state.stalled_runs` generalized (repo-done).** Now covers all run-logged routines (per-class 6h/18h
  thresholds, 7-day lookback), not just D1/D2/D3 — catches a weekly/monthly/AR session that died after
  `sp_routine_start`.
- **#12 — FMP mark fallback + completeness (repo-done; instruction + dbt test).** D2 falls back to the FMP
  connector when `get_price_history` returns no/stale bar for a held name (`source='FMP-fallback'`), and asserts
  every open position has a recent mark (`dbt/tests/assert_open_positions_have_marks.sql`, advisory).

### Theme E — alert-sink hygiene
- **#10 — Calendar pre-flight + staging atomicity (repo-done; instruction).** Order-staging routines now
  liveness-check the Calendar connector first (the sole human surface) and gate `completed` on the confirm-order
  event actually being created.
- **#14 — auto-resolve stale self-healing warnings (repo-done).** `cadence_check.sql` ages out >7-day
  `stranded_session`/`instruction_drift`/`calendar_runway_low`/`routine_stalled` warnings so the weekly digest's
  "N open alerts" reflects live issues (all_green keys only on open criticals — digest-quality only).
- **#15 — delivery canary (owner console).** Create `scheduled_queries/delivery_canary.sql` as a **weekly**
  scheduled query (e.g. Mon ~05:40 UTC; email-on-failure ON). It asserts the prior week's canary got
  `notified_ts` stamped (proves the emailer actually DELIVERED) and emits a fresh `[CANARY]` row. The
  `alert_emailer.gs` renders a canary-only batch with a clear `⚗ [TEST]` subject + `[TEST]` body tag; per
  operator preference (2026-06-29) the test email is left VISIBLE in the inbox — no Gmail auto-filter — so
  it is recognisable at a glance without defeating the test (re-paste the emailer for this to take effect).

## 28. `instruction_drift` from an id-separator transcription slip — the 2026-06-29 `AR_att` alert *(monitoring)*
**Fired 2026-06-30 05:15 UTC** (`scheduled.cadence` / `instruction_drift`, WARNING): *"Trigger drift: routine(s)
whose live web-UI trigger differs from the canonical catalog: AR_att."*

**Diagnosis — NOT a web-UI trigger edit and NOT an ad-hoc §22 note shadow.** The drifted token was the routine
**id**, not the trigger text. The catalog keys the adversarial routines under a **non-ASCII middle dot** —
`AR·att` / `AR·orc` (`·` = U+00B7), the form aligned on 2026-06-21 to match the live sessions + the
`Claude_Task_Plan.md` routine table. That id is **not part of the trigger text** (`Read Claude_Task_Plan.md.
Perform Adversarial Review Attacker — regular routine.`); a session hand-transcribes it from the plan's routine
table into `ops.sp_routine_start`. On 2026-06-29 the AR Attacker run (`sess-arattack-20260629`) transcribed it as
**`AR_att`** (ASCII underscore U+005F) — byte-identical, correct instruction text, only the separator swapped
(codepoints confirm: `…183…` middle-dot vs `…95…` underscore). This is the **2nd** time the middle dot has mis-
fired (cf. the 2026-06-21 AR `unknown_routine` reconcile); a non-ASCII char an agent must reproduce by hand is
inherently fragile.

**Why it would NOT self-heal (the load-bearing detail).** `state.routine_last_instruction` keeps the **all-time-
latest** trigger-shaped row **per DISTINCT id** (no time window). `AR_att` is a *distinct* id from `AR·att`, so its
2026-06-29 row is the permanent latest for that partition → `state.instruction_drift` carries an
`unknown_routine=TRUE` row for `AR_att` forever → `cadence_check.sql` re-raises the warning **every day**
(`sp_raise_alert_once` dedups while open; the #14 7-day auto-age only clears it until the next 05:15 run re-raises).
Simply resolving the `ops.alerts` row is therefore **not** durable.

**Fix (deployed 2026-06-30; repo + live).** Made `state.instruction_drift` match the catalog↔live join on a
**separator-normalized id** — `REGEXP_REPLACE(id, r'[·._-]', '')` on both sides — so `AR·att` / `AR_att` / `AR.att`
/ `AR-att` collapse to one routine (verified: every real id `D1…A3` is separator-free, so none collide), and the
live side is re-deduped to one row per normalized key (latest run). `bigquery/15_routine_catalog.sql` carries the
new view; applied live via the BigQuery MCP. Post-fix: `state.instruction_drift` has **0** `drifted OR
unknown_routine` rows, 23 rows total (= the 23 catalog routines), and reports `AR·att` / `AR·orc` under their
canonical ids with `live_last_seen=2026-06-29`. The open alert was resolved-with-note pointing here.

**Scope of the change — narrow by design.** Only the **cosmetic id-punctuation** false positive is suppressed.
The instruction-**TEXT** drift check is **unchanged** (`drifted = live text != canonical text`), so a genuinely
wrong heading / routine number / `— deep research.` vs `— regular routine.` tag still drifts (the §22 2026-06-29 W5
case would still fire), and a genuinely new/renamed routine with a different alphanumeric stem still flags
`unknown_routine`. Residual risk: a brand-new routine whose id differs from an existing one ONLY by separator
punctuation would be absorbed — implausible in this id namespace, and accepted.

**Alternatives considered + deliberately NOT taken.**
- **Run_log band-aid** (rewrite the 2026-06-29 `AR_att` row → `AR·att`). `ops.run_log` is NOT under the
  append-only guard (that covers `events.*` only — §25 B3 / `integrity_check.sql`), so it is *technically*
  possible, and unlike the §22 2026-06-29 W5 case it would mask no live config bug. Still rejected: it rewrites
  audit history to fix a one-off, and does nothing about recurrence. Left `run_log` honest.
- **Switch the canonical ids to ASCII `AR_att`/`AR_orc`** everywhere (plan table, `cadence.yaml`, catalog,
  `print_routines.py`, `check_cadence_consistency.py`, tests). Addresses the root cause (robust, agent-reproducible
  id) but is a large diff across a deliberately-set convention AND still leaves the historical middle-dot
  partitions as new `unknown_routine` flags — i.e. it *also* needs the detector change. Deferred as an optional
  follow-up: the normalization above already defuses the fragility, and this can be layered on later without
  conflict if the operator wants a clean ASCII id. (The normalization is the prerequisite either way.)
  **→ ADOPTED 2026-07-01; see the follow-up below.**

**Follow-up — ASCII id standardization ADOPTED (2026-07-01; repo + live).** The deferred alternative above was
taken (operator picked the root-cause route). The canonical adversarial ids are now the robust ASCII **`AR_att`
/ `AR_orc`** across the source of truth: the `Claude_Task_Plan.md` routine table (and the strategy-blinding
table's `AR_attacker` / `AR_orchestrator` labels), `ops/cadence.yaml` (ids + `AR_orc`'s `depends_on: [AR_att]`),
`bigquery/15_routine_catalog.sql` (catalog seed), `scripts/print_routines.py`,
`scripts/check_cadence_consistency.py` (`heading_to_id`), `tests/test_cadence_consistency.py`, and the
`state.stalled_runs` per-routine threshold table (`bigquery/18_stack_review_fixes.sql`); the stray `AR-attacker`
/ `AR·att` mentions in the `10_observability.sql` / `12_cadence_monitor.sql` header comments were corrected too.
Live: re-applied the `ops.routine_catalog` table (now keyed `AR_att`/`AR_orc`) and the `state.stalled_runs` view
via the BigQuery MCP. **The 6/30 separator-normalization is deliberately KEPT** — it now folds the *legacy*
middle-dot `ops.run_log` rows (2026-06-20…28) onto the new ASCII keys, so the historical partitions do NOT
resurface as `unknown_routine` after the switch, and it remains a guard against any future punctuation slip.
**No `ops.run_log` history was rewritten** (the middle-dot rows stay as logged; the normalized join reconciles
them). Post-change verification: `state.instruction_drift` still **0** `drifted OR unknown_routine`, 23 rows, AR
now reported under `AR_att` / `AR_orc`; `python scripts/check_cadence_consistency.py` OK; test suite green.
Recurrence-proof: an agent hand-transcribing the id now reads an ASCII underscore from the plan table, and even a
`.`/`-`/`·` slip still normalizes to the same routine.

**General rule (reaffirms §22).** An `instruction_drift` / `unknown_routine` alert is a **config bug to fix, not a
halt** (non-raising; never blocks `all_green`). First classify it: (a) a real edited/typo'd web-UI **trigger**
(diff `state.routine_last_instruction` vs `python scripts/print_routines.py` — operator-owned fix, §22 W5); (b) an
ad-hoc note shadow (§22 — already filtered by the trigger-shape guard); or (c) — as here — a cosmetic **id-
separator** transcription of a known routine (repo-owned fix: the normalized join). Then resolve the `ops.alerts`
row with a note pointing to the relevant section.

## 29. `position_drift` from an SGOV cash-sweep fill leaking into the deployed lifecycle — the 2026-07-01 `B:SGOV` alert *(monitoring)*
**Fired 2026-07-01 05:15 UTC** (`scheduled.cadence` / `position_drift`, WARNING): *"Position reconciliation:
current_positions vs position_lifecycle open-share drift: B:SGOV."*

**Diagnosis — a phantom, NOT a real position break.** `state.position_reconciliation` (B4,
`bigquery/18_stack_review_fixes.sql`) FULL-OUTER-JOINs two independent open-position representations per
`(strategy,ticker)`: `state.current_positions` (← `events.position_events`, hand-written by D2) vs the open lots of
`analytics.position_lifecycle` (← `state.trade_fills_curated`). For **B:SGOV** they read **0** vs **0.2468** shares
(Δ −0.2468 > the 0.01-share tolerance). Root cause: **SGOV is the shared, ACCOUNT-LEVEL cash-sweep / benchmark
instrument** — event-sourced through `events.parking_events` (strategy NULL on every row) and reconciled by
`state.sgov_position` / D2 Step 0 / §13, with the per-strategy SGOV split **formally dissolved**
(`13_sgov_reconciliation.sql`). It is deliberately kept OUT of `position_events` / `current_positions`. On
**2026-06-30** a partial-share SGOV sweep **BUY (0.2468 sh @ $100.68, tagged strategy B)** landed in `trade_fills`
(→ `trade_fills_curated`), so `analytics.position_lifecycle` — which had NEVER carried SGOV before — minted a
phantom open lot with no paired SELL, while `current_positions` (correctly) still carried no SGOV → structural drift.

**Two blast radii, not one.** Besides the false B4 alert, `analytics.position_lifecycle` also feeds
`analytics.strategy_daily_returns` (the deployed-TWR profitability metric) by joining `daily_marks_curated` on
ticker — and SGOV **is** in daily_marks (it is the benchmark). So from 2026-06-30 the phantom lot was also
**contaminating strategy B's `r_deployed`**, counting the ~$24.84 cash-park as BOTH a deployed position and the
benchmark.

**Why it would NOT self-heal.** `sp_raise_alert_once` dedups on `(unresolved, category, message)` so it won't pile
up duplicates — but the one row stays open while the condition holds, and cadence_check's >7-day auto-age
**explicitly excludes `position_drift`** (only `stranded_session` / `instruction_drift` / `calendar_runway_low` /
`routine_stalled` auto-age). SGOV keeps leaving residual fractional lots (monthly DRIP + sweeps), so absent a fix it
would re-drift indefinitely.

**Fix (deployed 2026-07-01; repo + live).** Exclude SGOV from the deployed lifecycle at the source — `AND ticker !=
'SGOV'` on BOTH the entries (BUY) and exits (SELL) CTEs of `analytics.position_lifecycle` — in the canonical
`bigquery/03_twr_engine.sql`, the dbt parity port `dbt/models/analytics/position_lifecycle.sql`, and applied live
via the BigQuery MCP. One change fixes every consumer at once: B4 (`state.position_reconciliation`) and its dbt
mirror (`dbt/tests/assert_current_positions_match_lifecycle.sql`) no longer see SGOV, and `strategy_daily_returns`
stops counting it. Post-fix: `position_lifecycle` has 0 SGOV rows, `state.position_reconciliation` has **0** drifted
rows (6 real positions reconcile cleanly). The open alert was resolved-with-note pointing here.

**Scope / what was NOT done.** No audit history rewritten — the 2026-06-30 SGOV BUY stays as logged in `trade_fills`
(and in `parking_events`, where it belongs); the view simply stops treating SGOV as a deployed position. B4's
0.01-share tolerance is unchanged (still catches a genuine whole-position break on any real ticker and swallows
sub-cent DRIP fractions). Strategy B's deployed-TWR figures published from 2026-06-30 (e.g. the 2026-07-01 M5
forecast) were computed with the SGOV contamination and correct themselves forward as the views recompute; the
committed artifacts remain as historical record.

**Follow-up (source anomaly).** SGOV fills normally route ONLY to `parking_events`; the 6/30 fill also landing in
`trade_fills` is the trigger. The view-level exclusion is recurrence-proof regardless of source (any SGOV fill in
`trade_fills` is now filtered from the deployed lifecycle), so no runtime change is required. If SGOV starts
routinely double-booking into `trade_fills`, investigate the D2 Step-0 fill-ingestion classification separately.

## 30. `instruction_drift` from a genuinely-wrong M5 web-UI trigger — the 2026-07-01 M5 type-tag drop *(monitoring)*
**Surfaced 2026-07-01** while verifying §28/§29 (not yet an alert — it would have fired at the next 05:15 UTC
cadence_check). M5's first-ever run (monthly first-trading-day) logged its trigger as `Read Claude_Task_Plan.md.
Perform M5. Deployed-TWR & Macro Forecast` — **missing the trailing ` — regular routine.` type-tag** → `drifted=TRUE`.

**Classification — §28 case (a) / the §22 W5 precedent, ACTUALLY fixed.** NOT an id-separator slip (§28) and NOT an
ad-hoc note shadow (§22): the drifted token was the trigger TEXT, and diffing `state.routine_last_instruction`
against the canonical (`python scripts/print_routines.py`) confirmed the **live web-UI trigger itself genuinely
lacked the suffix** — a real edited/typo'd trigger, exactly the un-versioned-trigger SPOF §15/§22 warn about. The
detector worked as designed (§28 scope note: a wrong heading/number/type-tag SHOULD drift); the fix is operator-side,
NOT a detector change.

**Fix (2026-07-01; both fronts).**
1. **Recurrence — the web-UI trigger.** The schedule + instruction live ONLY in the Claude-Code-on-Web UI
   (unversioned, browser-only — §15/§26). Corrected the M5 automation's Instructions field to exactly
   `Read Claude_Task_Plan.md. Perform M5. Deployed-TWR & Macro Forecast — regular routine.` (spaced em-dash + final
   period) via a **Claude-in-Chrome** session; schedule/name/connectors untouched, no other routine touched. Future
   M5 runs now log the canonical text.
2. **The current row.** `state.routine_last_instruction` keeps the all-time-latest trigger-shaped row PER id, so the
   truncated 2026-07-01 `started` row (`run_id fb5b80f4…`) would keep `instruction_drift` drifted until M5's NEXT
   monthly run (~a month) → daily false alert until then. With the trigger now fixed, that row is a **confirmed
   one-off masking no live config bug**, so corrected its single `ops.run_log.instruction` to the canonical string.
   `ops.run_log` is NOT under the append-only guard (events.* only — §25 B3). (Contrast §28's AR case, where the
   separator-normalization made a rewrite unnecessary; here there is no normalization escape — it is a genuine text
   difference the detector must keep catching — so the bounded row correction is the clean call.)

Post-fix: `state.instruction_drift` = **0** drifted / **0** unknown (23 rows); M5 reports the canonical trigger; no
alert fired. **General rule (reaffirms §22/§28):** classify first (id-separator → normalized join, §28; ad-hoc note
→ trigger-shape guard, §22; real wrong trigger → operator fixes the web-UI trigger + optionally correct the one-off
`run_log` row, as here). Never weaken the text-drift detector to silence a genuinely wrong trigger.

## 31. Report-system redesign — weekly email fixes, display-timezone plane, mixed-tz SQL bugs, markdown conventions *(reporting, verified deltas)*

**2026-07-02.** A dedicated analysis pass (12 adversarially-verified findings in the weekly self-email, a 6-area
154-item timezone sweep, a review of the routine markdown-report corpus) drove a report-system-wide fix batch.
APPLIED + VERIFIED LIVE via the BigQuery MCP; `.gs` files are repo-only until the operator re-pastes them
(script.google.com — see the Chrome checklist below).

**A. Weekly self-email (`ops/weekly_report/weekly_report.gs` + `14_weekly_report.sql`).** Fixed: NULL MTD/YTD TWR
rendering as green "+0.00%" instead of `—`; the NAV weekly-delta arrow/sign/format (was always ▲ even on a down
week, and derived from TWR which strips cash flows — now an exact dollar delta from `state.account_nav_7d_ago`,
a new 7-days-back snapshot lookup); a `bq_()` silent-failure path that could send an email with empty data instead
of failing; the header ALL-GREEN badge recomputed from the same component signals the ops strip renders (was
`state.system_health.all_green`, which excludes firing kill-flags / non-critical alerts and could contradict the
strip); the subject-line performance tag (was the single best-deployed-sleeve TWR — survivorship-biased — now the
account week TWR); NAV staleness (a days-old snapshot rendered identically to a fresh one — now flags `STALE` +
shows the as-of date); the fill-row glyph (was a hardcoded ▲ for both BUY and SELL); regime-rationale truncation
(now appends `…`); the computed-but-never-rendered `go_7d` count (now shown as "GO · NO-GO"); the plain-text part
(had drifted from the HTML — omitted MTD/YTD/excess/gate/regime/fills and could emit literal `undefined` — rebuilt
to mirror every HTML section from the same data object); the ACTIVE-vs-ACTIVE-idle badge ambiguity (two colors,
identical label, and the amber branch's `activation_note` check was dead code — the SELECT never fetched that
column — removed, amber state relabeled `ACTIVE · idle`). Content additions: `state.open_positions_summary` (the
current book — the single biggest prior gap) and `state.next_7_days` (queue/time-exit/order-window items due
soon) are new sections; the scorecard gained a `Δ Wk` column (`analytics.strategy_unit_value_7d_ago`); the ops
strip gained backups/automation/cadence rollup items (previously reached the operator only via the independent
DTS failure-email); the inline fills/NO-GO queries moved into named views (`analytics.weekly_fills` /
`analytics.weekly_nogos`) matching the rest of the file's convention. `alert_emailer.gs`: `LOOKBACK_HOURS` 48→168 —
an emailer dead >48h would otherwise never send an early-outage alert to ANY channel on recovery (`notified_ts`
stays NULL past the scan window; the relay/canary don't backfill).

**B. Display-timezone plane (`bigquery/20_user_prefs.sql`, new).** Operator asked for timezone auto-detection
instead of a hardcoded MT/UTC pin. Two-plane design: the OPERATING plane (trading-day/cadence/dead-man's-switch
timing — §everything else in this doc) stays pinned to America/Denver, unconditionally, forever — re-anchoring it
to wherever the operator is would reintroduce the 2026-05-27 UTC/Denver confirm-event deletion bug. The DISPLAY
plane (how a timestamp is RENDERED in an email/alert/dashboard) now follows a detected timezone: `ops.user_prefs`
(append-only) + `state.user_tz` (latest `display_tz`, self-bootstrapping fallback `America/Denver`). **D3** (Calendar
Hygiene, which already calls the Calendar connector daily) is the writer — it reads the primary calendar's
`timeZone` field (Google keeps this current with the phone's location when "update primary time zone" is enabled)
and inserts a row only on change (`Claude_Task_Plan.md` §D3). Consumers updated to read `state.user_tz` and label
their output: `alert_emailer.gs` (was raw unlabeled-as-such UTC — now `MMM d, h:mm a (tz)`), `generate_dashboard.py`
(alert_ts/log_ts/generated-at, via `zoneinfo`), `scripts/alert_relay.py` (alert timestamps; `entry_window_close` is
a DATE with no time-of-day component, so it was left alone — documented, not silently skipped). No trading-day
logic reads `state.user_tz` anywhere.

**C. Mixed-timezone SQL bugs — 11 verified findings, all latent (0/21 historical fills affected; the fix is a
no-op today, structural for tomorrow).** Root-cause fix: `analytics.position_lifecycle`'s `entry_date`/`exit_date`
(`bigquery/03_twr_engine.sql` + `dbt/models/analytics/position_lifecycle.sql`) now use
`DATE(fill_ts, 'America/New_York')` — the exchange trading date the mark-join keys on — instead of the bare
(UTC-default) form, which would mis-date an after-hours/overnight fill to the next day and shift the TWR
entry-day baseline. Six downstream consumers (`thesis_outcomes`, `strategy_nav`'s dividend-accrual join, and their
dbt mirrors, plus `strategy_daily_returns`) inherit the fix automatically — they consume `position_lifecycle`'s
columns rather than calling `DATE(fill_ts)` themselves. Two independent Denver-operating-day sites fixed directly:
`analytics.weekly_activity` / `analytics.weekly_fills` (`fills_7d` was comparing a UTC-derived fill date against a
Denver-anchored 7-day window) and `state.go_without_order` (`bigquery/18_stack_review_fixes.sql` — a bare-UTC
comparison against `decision_log.entry_date` could produce a false negative, suppressing a genuine
go-without-order candidate). New dbt model `strategy_unit_value_7d_ago.sql` added (parity pair for the
`analytics.strategy_scorecard` Δ Wk column above); `strategy_scorecard.sql`'s dbt mirror updated to match.

**D. Markdown-report conventions (`Claude_Task_Plan.md`, `Daily.md`, `Weekly_Catalyst_Calendar.md`,
`Quarterly_Regime.md`).** `Weekly_Catalyst_Calendar.md` had stamped `2026-W27` (an improvised "upcoming
trading-Monday" convention) while `Weekly_Post_Event_Screen.md`/`Weekly_Position_Deep_Dive.md` correctly stamped
`2026-W26` (the run day's ISO week) the SAME cycle — since the W4 upstream-freshness gate computes "current
period" as the plain ISO week of today, the mismatched marker would have false-halted W4. Corrected the live file
and added an explicit guard to the W1 prompt body against recurrence; also converted its ASCII `====` banners to
`##` headings, matching its sibling files. `Quarterly_Regime.md` had a title on line 1 and its `2026-Q2` marker on
line 3 (violates "first line is the marker" — every other cadence file gets this right); corrected, and the Q1
prompt body now says so explicitly. Added a per-routine table to "File-write conventions" disambiguating monthly/
quarterly marker semantics (retrospective vs forward-looking) instead of a single prose rule. Added a required
≤5-line TL;DR to Daily.md (applied to the live file) and a machine-readable fenced `d1_actions` YAML block
mirroring the prose RECOMMENDED ACTIONS bullets — D2 now cross-checks the prose bullet count against the block's
entry count and halts (`missing_dependency`) on a mismatch, closing a prose-only-parse blind spot where a missed
or double-counted bullet could become a missed exit or a fabricated order.

**Verification.** All 14 weekly-email findings independently confirmed by 2 adversarial reviewers each (12/14
confirmed 2-0, 2 confirmed-with-refinement, 0 refuted) before implementation. Post-apply: `SELECT` smoke tests on
every new/changed view returned sane data (`state.user_tz` → `America/Denver` fallback as expected pre-D3;
`state.account_nav_7d_ago` → correct 7-days-back snapshot; `state.open_positions_summary` → 5 rows matching the
live book; `analytics.strategy_scorecard.twr_7d` → B +4.5%/D +0.7% over 7d, A/C/E null as expected). `pytest
tests/` (52 tests), `scripts/check_cadence_consistency.py`, and a live `analytics.position_lifecycle` row-count
check (14, unchanged pre/post) all pass.

**Owner action required (Claude-in-Chrome or manual, script.google.com — NOT a BigQuery/console step):** re-paste
the updated `ops/weekly_report/weekly_report.gs` and `ops/monitoring/alert_emailer.gs` into their Apps Script
projects (Claude cannot reach script.google.com) — the repo and BigQuery sides are live now, but the deployed
scripts will keep running the pre-fix code until re-pasted. Also confirm both projects' timezone (Project
Settings) is still `America/Denver` (governs trigger hour only — unrelated to the new `state.user_tz` display
plane, which the scripts read from BigQuery at send/poll time).

## 32. Weekly email — "why" line under Operational Health *(reporting)*

**2026-07-02.** Triggered by the operator questioning a `SYSTEM ATTENTION` badge on a manually-sent
test copy of the report (the 2026-07-02 14:09 MT send — see §31; a one-off `testReport()` verification
run, not the real `SUNDAY @ 07:00` cadence). Investigation: the badge/strip glyphs (`✓`/`✕`) never
carried an explanation, so a same-day freshness lag (report generated before the evening D2 batch,
which normally completes ~22:30 MT) was visually indistinguishable from a genuinely stalled pipeline —
confirmed via live query that today's `marks_fresh`/`engine_fresh = false` was solely because D2 for
2026-07-02 hadn't run yet (0 `run_log` rows), with `open_alerts = 0`, `firing_kill_flags = 0`,
`embeddings_healthy = true` otherwise clean. Also confirmed the real Sunday 07:00 send is unaffected
(`state.trading_day_today` resolves `last_trading_day` to the prior Friday on a Sunday query, and
Friday evening's batch is long complete by Sunday morning — verified against the clean 2026-06-28
Sunday heartbeat).

**Fix, not a schedule change.** Rather than move the trigger (the real cadence was never broken), added
`buildHealthReasons_()` to `ops/weekly_report/weekly_report.gs`: only runs when the badge isn't
`ALL GREEN`, and renders a `Why:` line under the Operational Health strip (HTML) / a `WHY:` line in the
plain-text part. Distinguishes "D2 hasn't completed yet for `last_trading_day`" (expected, pending —
via `state.system_health.d2_ran_last_trading_day`) from "D2 completed but marks/engine are still
stale" (a genuine inconsistency to investigate directly). For open alerts, pulls the actual
`ops.alerts.message` (top 3, critical-first) instead of a bare count. For kill-flags, names the
firing strategy + flag(s) from `perf.kill_flags` instead of a bare count. For unhealthy embeddings,
surfaces `state.embedding_health`'s missing/error/dup row counts. All three new queries smoke-tested
live against BigQuery (clean empty results for alerts/kill-flags today; embedding_health returned
0/0/0 as expected).

**Owner action required:** re-paste the updated `ops/weekly_report/weekly_report.gs` into its Apps
Script project (script.google.com) — same as §31, this is repo-only until re-pasted.

## 33. Weekly email redesign — "Strategies vs SGOV" *(reporting, owner directive)*

**2026-07-02.** Owner directive: the weekly email should answer exactly one question — "is each
strategy beating just parking the cash it was allocated (a portion of the overall portfolio value)
in SGOV?" — with everything that doesn't support that question removed. The owner floated a
multi-line chart (one line per strategy + one for SGOV) and delegated final visual design.

**Why the question is sleeve-level, not deployed-slice-level.** The owner's clarification —
"the cash it was allocated" — means "did giving strategy B its $1,889 sleeve beat leaving that
$1,889 in the SGOV park?", not "did B's currently-deployed ~$117 slice have a good TWR?". Because
undeployed sleeve cash already sits in the account-level SGOV park (§29 — the per-strategy SGOV
split is formally dissolved), a sleeve differs from the "park everything" counterfactual **only on
its deployed slice**, so the sleeve-level answer in dollars is:

```
edge_dollars_cum = Σ over deployed position-days of  deployed_capital_day × (r_deployed_day − r_sgov_day)
```

This is a NEW primary metric (`analytics.strategy_vs_park_daily.edge_dollars_cum`,
`bigquery/21_strategy_vs_park.sql`) — additive on top of the existing sanctioned deployed-TWR engine
(`perf.strategy_daily` / `Operating_Protocols.md` §14), not a replacement. `excess_vs_sgov` (the
deployed-TWR percentage) stays in the email as a secondary column tied to the kill/gate machinery;
it measures intensity on the deployed slice only ($ is capital-weighted, % is time-weighted — they
can legitimately differ in sign when deployment size varies across good/bad days).

**Chart design (steelmanning the owner's raw-multi-line suggestion, then rejecting it).** A raw
growth-of-$1 unit-value chart (each strategy's `deployed_unit_value` plus a calendar SGOV line) was
considered and rejected: it is deployed-slice-only and dollar-unaware, so it would visually re-crown
B's +9.1% *deployed-slice* return, reinstating exactly the framing the owner's sleeve-level
clarification corrected. It also stops being any strategy's true benchmark once deployments pause
(the engine chains `sgov_index` per-strategy and pauses when parked). What the raw chart uniquely
offers — SGOV's own earning power / absolute trajectory — is instead carried by the hero tile's
"the SGOV park itself earned ≈$X over this period" scale line. **Final design:** one multi-line
chart, each strategy plotted as its own cumulative `edge_dollars_cum` line, with SGOV rendered as
the flat **$0 baseline** (drawn first, gray `#898781`, so strategy lines draw on top of it — the
near-$0 region is exactly where a noise-band strategy lives and must not be overplotted). "Above the
gray line = beating the park" reads in one glance; the SGOV line the owner asked for is still
there — it IS the zero line. A/C/E (never deployed) sit exactly on that line by construction. Built
server-side via the Apps Script Charts service (`Charts.newLineChart()` → `getAs('image/png')`),
embedded as an inline `cid:` attachment — Gmail supports no inline SVG and no `data:` URI images, so
`cid` is the only self-contained image route; a genuine chart-build failure falls back to
Gmail-safe HTML bar rows (color = verdict) so the email never fails to send over a chart problem.

**Neutral-band verdict rule.** A strategy's edge is classified `BEATING PARK` / `TRAILING PARK` only
when `|edge_dollars_cum|` exceeds `max($2.00, commissions_to_date)` — otherwise it reads
`≈ EVEN WITH PARK`. Rationale: at current scale (sub-$150 deployed sleeves), a few-dollar edge is
inside its own day-to-day noise, and an edge smaller than the commissions paid to earn it shouldn't
claim green — the 2026-06-05 findings (`bigquery/03_twr_engine.sql` §"FINDINGS") already show
gross-vs-net flipping B's sign once in this experiment's history. **Note for the owner:** the
2026-06-05 gross-of-commissions directive was scoped to the profitability/kill metric ("commissions
are a scale artifact, not stock-selection edge"); this redesign extends gross-of-commissions to the
new cash-counterfactual question too (a genuinely costless park vs a strategy with real commission
drag). The neutral band is the interim mitigation — commissions are surfaced per-row in the table
subtext, not buried in the footer only. If commission drag keeps flipping verdicts as deployed
capital grows, the gross convention may be worth re-confirming specifically for this question; no
change was made without an explicit owner ask (settled decisions stay settled).

**What was cut, and where it still lives.** Dropped entirely from the email: the regime section
(integrative label, 5 axes, technical signals), account NAV/Week/MTD/YTD stat cards (≈98% SGOV
park — not a strategy-skill signal), the open-positions table, the next-7-days strip, weekly
activity (fills/GO-NO-GO/pending), and the full ops-health strip (embeddings, backups, automation
heartbeats, cadence watch, non-critical alerts, the ALL GREEN/ATTENTION badge). In their place: one
data-trust line, shown only when
`marks_fresh && engine_fresh && firing_kill_flags == 0 && open_critical_alerts == 0` is false
(embeddings/backups/automation/cadence deliberately excluded — they already reach the operator via
the independent DTS failure email, per `ops/weekly_report/README.md` and this RUNBOOK's monitoring
sections). Positions/activity/regime remain available in `Daily.md` and the health dashboard. **Do
not re-add any of these sections to the weekly email without a new owner ask** — this is a
deliberate, requested reduction, not an oversight.

**SQL applied live (additive only — see hard-constraint discipline below):**
- `bigquery/03_twr_engine.sql`: `analytics.strategy_daily_returns` gained one column,
  `deployed_capital` (`SUM(prev_mv)`, the deployed dollars marked that day) — byte-identical
  otherwise; `ops.sp_recompute_engine` selects named columns and is unaffected.
- `bigquery/21_strategy_vs_park.sql` (new file): `analytics.strategy_vs_park_daily` (the chart's
  daily $ edge series), `analytics.strategy_vs_park` (latest verdict row per ever-deployed
  strategy — $ edge, 7d Δ, first-deployed date, commissions to date), `analytics.park_baseline`
  (one row: what parking everything would have earned — the hero's scale anchor).
- Live-verified 2026-07-02 (as-of 2026-07-01 close): B `edge_dollars_cum` = **+$10.6737**
  (excess_vs_sgov +8.42%, commissions $4.83 → BEATING PARK), D = **−$1.4553** (excess_vs_sgov
  −2.05%, commissions $0.59, band $2.00 → **≈ EVEN WITH PARK**, not TRAILING — the neutral band
  doing its job on a genuinely noise-level edge). Combined ≈ **+$9.22**; park itself earned
  ≈**$61.59** over the same 46-deployed-day window (2026-04-27 → 2026-07-01). Signs match
  `perf.kill_flags.excess_vs_sgov` for both strategies. A, C, E: zero `perf.strategy_daily` rows —
  render as `NOT DEPLOYED` ($0.00 by construction — router do-not-activate / hybrid FOMC-only /
  execution-feasibility-deferred respectively), never as losing or red.
- Fixed a latent nondeterministic-tie bug while porting the 7d-ago pattern: the new
  `strategy_vs_park`'s week-ago QUALIFY adds `, as_of_date DESC` as a tie-break (matching
  `state.account_nav_7d_ago`'s existing pattern) — a Monday-holiday week produces genuine two-row
  distance ties, and an un-tie-broken pick would show up as spurious drift in the dbt-parity CI
  job (which evaluates the live view and the dbt twin independently).
  `analytics.strategy_unit_value_7d_ago` (`bigquery/14_weekly_report.sql`) carries the same latent
  flaw and was NOT fixed here — it now feeds a column the redesigned email no longer displays, so
  it's a candidate for a follow-up, not urgent.

**dbt parity:** mirrored `deployed_capital` into `dbt/models/analytics/strategy_daily_returns.sql`;
added `strategy_vs_park_daily.sql` / `strategy_vs_park.sql` / `park_baseline.sql` twins +
`schema.yml` entries (uniqueness/not-null/accepted-values tests matching the `strategy_nav`-family
convention). Also corrected four stale "weekly self-email" claims found while touching this area:
`analytics.strategy_scorecard`'s description (never read by the dashboard — verified against
`ops/dashboard/generate_dashboard.py`, which reads `system_health`/`kill_flags`/`strategy_nav`/
`gate_watch`/`alerts`/`run_log` directly), `state.account_latest`, `analytics.weekly_activity`
(both the dbt model header and its `schema.yml` entry), and the `ops.account_snapshot`
`OPTIONS(description=...)` + the `weekly_fills`/`weekly_nogos` convention comment in
`bigquery/14_weekly_report.sql` — all now say "retained; no longer read by the weekly email."

**Backward-compatibility discipline (hard constraint — the deployed `.gs` is manual).** The live
Apps Script keeps running the pre-redesign code until the owner re-pastes it (Claude cannot reach
script.google.com); the deployed script's `gatherData_()` selects an explicit column list from
`analytics.strategy_scorecard` and reads `state.current_regime` / `state.account_latest` /
`analytics.weekly_activity` / `analytics.weekly_fills` / `analytics.weekly_nogos` /
`state.open_positions_summary` / `state.next_7_days` / the automation-health views directly. **None
of that was dropped or renamed** — this redesign is strictly additive on the BigQuery side (one
new column, three new views); the now-unread-by-email views stay live for the old deployed script,
RUNBOOK verification, dashboard/history use, and a possible future re-use. Cleaning them up is an
explicit non-goal, deferred to a later, separate decision.

**Scope fix:** `ops/weekly_report/appsscript.json`'s BigQuery OAuth scope was
`bigquery.readonly`, which cannot run the heartbeat `INSERT` the script has always performed after
a successful send — the deployed project evidently holds a broader grant than the checked-in
manifest (or the heartbeat write has been silently no-op'ing, try/catch-wrapped). Corrected to the
full `bigquery` scope.

**Deploy order:** BigQuery views applied live first (this section) → code merged to
`claude/weekly-report-redesign-875a6w` → **owner action required:** re-paste
`ops/weekly_report/weekly_report.gs`, update the manifest scope, run `testReport()` (re-approve the
consent screen — the scope changed), confirm the email shows the line-chart PNG (not the bar
fallback). The old deployed script keeps sending its old-format email, uninterrupted, during the
window between merge and re-paste.

**Deployed 2026-07-02/03 (Claude-in-Chrome, owner-directed).** Re-pasted `weekly_report.gs` +
the updated `appsscript.json`, re-approved the OAuth consent screen, ran `testReport()`. Confirmed
live: real line-chart PNG (not the bar fallback), correct 5-row verdict table, subject line
`Stock-Trading · Strategies vs SGOV — Jul 2, 2026 · B +$12.25 · D ≈even` (B `BEATING PARK`, D
correctly reading `≈ EVEN WITH PARK` rather than a false red on a noise-level edge, A/C/E
`NOT DEPLOYED`). One caught-and-logged exception as anticipated: the label step (`GmailApp.search`
+ `thread.addLabel`, only ever meant to tag the received copy `Trading/Weekly`) threw under
`gmail.labels` alone — that scope covers label CRUD only, not searching/modifying threads. This
was flagged above as a "known-and-accepted residual, not worth fixing" on the theory that the only
fix was `https://mail.google.com/` (full mailbox access incl. permanent delete) for a labeling
nicety — revisited after live confirmation: `https://www.googleapis.com/auth/gmail.modify`
("all read/write operations except immediate, permanent deletion") is the correctly-scoped middle
ground, missed in the original writeup. Manifest updated (`gmail.labels` → `gmail.modify`,
`gmail.send` kept alongside it); owner action required again: re-paste `appsscript.json` and
re-approve consent once more. Low urgency — cosmetic-only (inbox organization), send/report content
unaffected either way.

**Verified functionally** (not just syntactically) via a Node `vm`-sandboxed harness that stubs
`GmailApp`/`BigQuery`/`Utilities`/`ScriptApp`/`Charts`/`Logger` and feeds `weekly_report.gs` the
real live-captured BigQuery response shapes: the primary scenario (live B/D data) and four edge
cases — all-green, all-parked (no strategy ever deployed), a firing kill-flag, and a genuine
Charts-service failure exercising the HTML bar fallback — all ran end-to-end without throwing, with
subject/hero/chart-data/table/plain-text all internally consistent. `sample_preview.html` was
regenerated from the harness's actual `buildHtml_()` output against the live-verified numbers above
(with the chart's `cid:` image swapped for a static placeholder div, since a preview file can't ship
a live PNG), then screenshotted — no horizontal overflow at 600px, no label collisions.

**2026-07-03 follow-up — percentage-primary.** After seeing the first live send, the owner asked for
the headline + chart to compare **percentages, not absolute dollars** ("I evaluate performance of a
strategy better with percentage comparison"). The percentage that measures strategy performance is
the **deployed-slice excess return** — `perf.strategy_daily.excess_vs_sgov` (deployed-TWR unit value
÷ SGOV index − 1, over the strategy's own deployed days; the sanctioned kill/gate metric) — i.e. the
return on the capital actually put to work, NOT a sleeve-level % (which at ~98% parked would be a
diluted ~0.7% and useless for judging a strategy). Changes:
- `bigquery/21_strategy_vs_park.sql`: `analytics.strategy_vs_park_daily` gained an `excess_vs_sgov`
  column (LEFT JOIN `perf.strategy_daily`, so the chart, the scorecard %, and the kill/gate metric
  are one number); new view `analytics.deployed_book_vs_sgov` — the combined **value-weighted**
  deployed-book excess % (percentages don't sum, so the hero can't be a sum of per-strategy %; it's
  the aggregate book's own excess). Both additive, applied live 2026-07-03. Verified: combined
  **+7.18%** (book +7.92% vs SGOV +0.69% over 47 deployed days); B **+9.88%**, D **+1.76%**.
- `ops/weekly_report/weekly_report.gs`: hero now leads with the combined excess % + a book-vs-SGOV
  scale line (keeping the ≈$ dollar edge as a small "for scale" figure — honouring the earlier
  sleeve-level dollar request as secondary, not headline); the chart plots cumulative **excess %**
  per strategy against the flat **0%** SGOV baseline (y-axis "% vs SGOV"); the verdict table leads
  with **vs SGOV %** (the $ edge muted beneath), Δ wk is the trailing-7-day change in **percentage
  points**; the subject line is percentages. Neutral band is now **±1.0 percentage point** of excess
  (was the dollar `max($2, commissions)` band) — earliness is carried by the gate column + the
  "provisional before the 30-trade gate" caption, not by masking the number, since the owner wants
  to read the real %. `analytics.park_baseline` is no longer read by the email (its park-$ scale
  role is replaced by the book/SGOV %); retained in BigQuery.
- dbt twins + `schema.yml` updated (`excess_vs_sgov` on `strategy_vs_park_daily`, new
  `deployed_book_vs_sgov`); still additive, backward-compatible with the deployed pre-change script
  until re-pasted. Re-verified via the same Node harness (all five scenarios) + preview screenshot.
  **Owner action required:** re-paste `weekly_report.gs` (no manifest/scope change this time — the
  `gmail.modify` + `bigquery` scopes from the prior deploys already cover it).

**2026-07-03 follow-up #2 — actual returns + trailing week/month/year.** Owner feedback on the
percentage version: (a) the combined/aggregate figure is not useful — show each strategy
individually; (b) show SGOV's own return, not a flat 0% "excess" baseline; (c) drop the "BEATING
PARK"/verdict labels, the dollar figures, the Δ-wk percentage-points column, and the
"Closed trades / 30" column; (d) say "SGOV", not "SGOV park"; (e) the long explanatory footnotes
signal the visual design isn't clean — cut them; (f) show vs-SGOV as **weekly / monthly / yearly**
figures, with "Not enough data" until that much history exists. Result:
- **Chart** now plots each deployed strategy's **actual cumulative total return** (deployed_unit_value
  − 1) plus a real **SGOV line** (its own cumulative total return) — not the excess-with-flat-0
  framing. New view `analytics.sgov_cumulative` supplies the SGOV line + its trailing-window returns;
  `analytics.strategy_vs_park_daily` gained a `deployed_unit_value` column for the strategy lines.
  Both additive, applied live 2026-07-03.
- **Table** ("Return vs SGOV"): one row per strategy, columns **1 week / 1 month / 1 year** = the
  strategy's return *above SGOV* over each trailing window (derived in the `.gs` from the cumulative
  `excess_vs_sgov` series: `(1+e_latest)/(1+e_{≤latest−W})−1`), "Not enough data" when the strategy's
  history is shorter than the window (1-year is "Not enough data" until ~2027-04). Plus a distinct
  **SGOV row** showing SGOV's *own* return over the same windows (satisfies "show SGOV %"). Not-deployed
  strategies (A/C/E) show a "not deployed — …" reason. Colour: strategy cells green/red by sign; SGOV
  row and not-deployed muted.
- **Removed**: the combined-hero tile, all verdict chips/labels, every dollar figure, the Δ-wk pp
  column, the gate column, and the multi-sentence methodology footnotes (replaced by one short line:
  "Total return, gross of commissions; SGOV includes dividends"). Subject line now shows each deployed
  strategy's cumulative actual return + SGOV's (e.g. `B +10.64% · D +2.46% · SGOV +0.69%`).
- **Interpretation note (RESOLVED in follow-up #3 below):** this build implemented "weekly/monthly/yearly"
  as the return vs SGOV over the **trailing** 1 week / 1 month / 1 year (fund-fact-sheet style). The
  owner then confirmed they wanted a per-period **average rate** over active days instead — see
  follow-up #3. Trailing-window figures this build showed (superseded): B 1wk +5.81% / 1mo +10.35%;
  D 1wk +4.52% / 1mo +6.18%; SGOV own 1wk +0.11% / 1mo +0.33%; 1yr "Not enough data" for all.
- `deployed_book_vs_sgov`, `strategy_vs_park`, `park_baseline` are no longer read by the email
  (retained in BigQuery). dbt twin + `schema.yml` updated (`deployed_unit_value` col, new
  `sgov_cumulative`). Additive/backward-compatible; re-verified via the Node harness (primary +
  all-parked + chart-failure) + preview screenshot. **Owner action required:** re-paste
  `weekly_report.gs` (no scope change).

**2026-07-03 follow-up #3 — per-period AVERAGE over ACTIVE days (resolves the #2 interpretation
note).** Owner confirmed the table should show a per-period **average rate** ("average +X% per week
across all history"), NOT a trailing-window return; and it must **disregard inactive time** —
idle days must not default to 0 return and drag the average down. Result:
- **Table** header is now **"Average Return vs SGOV"** with columns **avg / week · avg / month ·
  avg / year**. Each cell is a geometric per-period average of the strategy's cumulative return
  *above SGOV*, computed over its **active (deployed) days only**:
  `(1 + excess_latest) ^ (tradingDaysPerPeriod / deployedDays) − 1`, with
  `TRADING_DAYS_PER = {week:5, month:21, year:252}`. Because `strategy_vs_park_daily` has a row
  **only** for deployed days, `deployedDays = points.length` naturally excludes idle stretches — no
  zero-return calendar days ever enter the denominator. "Not enough data" when `deployedDays` is
  fewer than the period's trading days (so 1-year stays "Not enough data" until 252 deployed days,
  ~2027-04). The SGOV row shows SGOV's own average per period over the same active window.
- No SQL/view change — this is a pure `.gs` recomputation off the existing `excess_vs_sgov` /
  `sgov_cum_return` series (the old `windowReturn_` trailing-window helper was replaced by
  `periodAvg_`). dbt/SQL/README comments refreshed to say "average per period over deployed days".
  Live-verified 2026-07-03 (47 deployed days): B avg/wk **+1.01%** / avg/mo **+4.30%**; D avg/wk
  **+0.19%** / avg/mo **+0.78%**; SGOV own avg/wk **+0.07%** / avg/mo **+0.31%**; avg/yr "Not enough
  data" for all. Re-verified via the Node harness (primary + all-parked + chart-failure) + preview
  screenshot. **Deployed 2026-07-03 via Claude-in-Chrome** (re-pasted `Code.gs` from `main`@`d69d099`,
  ran `testReport`, confirmed table header + B avg/wk +1.01% / avg/mo +4.30% in the actual sent
  email) — supersedes the follow-up #2 build.

**2026-07-03 follow-up #4 — self-sent mail was landing pre-marked READ.** Owner reported the
weekly email always arrives already read (no unread/bold indicator) — a known Gmail quirk for
self-addressed mail: because sender and recipient are the same account, the send action itself
registers as the read event, so the Inbox copy never gets the normal "new mail" unread flag.
Fix: `sendWeeklyReport_()`'s post-send Gmail lookup (previously label-only) now also calls
`GmailThread.markUnread()` on the just-sent thread, in the same `GmailApp.search(...)` lookup
used for the `Trading/Weekly` label — one search, both operations, best-effort (never blocks the
send). No new scope required (`markUnread()` uses the same `gmail.modify` scope `addLabel()`
already needs). Node harness updated with a tracked fake-thread stub asserting exactly one
`markUnread()` + one `addLabel()` call on the just-sent thread. **Owner action required:**
re-paste `weekly_report.gs` (no scope change).

## 34. Guard config visibility + alert-channel liveness — 2026-07-03 (self-improvement audit)

**Problem.** By §25/§27, five-plus CI jobs (`alert-relay`, `offsite-backup`, `keyless-sa-audit`,
`wif-binding-audit`, `dashboard`) plus two `ci.yml` opt-ins (`DBT_PARITY`, `RUN_SQL_DRYRUN`) are all
double-gated and default OFF, each printing its own `::notice::` when disabled. That notice only
lives inside that one workflow's own run log — there was no single place showing the aggregate
picture, so a guard could sit dormant indefinitely simply because nobody thought to check five
separate Actions histories. Separately, `alert-relay`'s alerts/orders modes are deliberately
best-effort (a POST failure is swallowed so a transient webhook hiccup never adds noise on top of
the reliable emailer) — but that same design meant a *permanently dead* webhook (revoked, URL
typo'd) would never surface, since it only has to fire when there happens to be something to relay.

**Fix — `guard-config-audit.yml` (new, monthly).** Reads the same `vars`/`secrets` every gated
workflow already reads (read-only, no new grants). Distinguishes LOAD-BEARING guards
(`ALERT_WEBHOOK_URL`, `OFFSITE_BACKUP_GCS` — the two this self-improvement audit specifically
flagged as closing a real redundancy gap) from OPTIONAL ones (`RUN_SA_KEY_AUDIT`, `RUN_WIF_AUDIT`,
`PUBLISH_DASHBOARD`, `DBT_PARITY`, `RUN_SQL_DRYRUN` — genuinely opt-in nice-to-haves per their own
workflow headers). Only the load-bearing pair — and only once their sole prerequisite (the WIF
vars) is already live, so the pre-bootstrap state is never itself a "finding" — opens a deduped
GitHub issue and fails the run (same pattern as `stranded-branch-check.yml`); the issue is
commented + auto-closed once resolved. Optional guards are `::notice::`-only, deliberately never a
"problem" — treating an intentional, self-documented default-off state as a recurring failure would
be exactly the alert-fatigue/cry-wolf pattern §19 exists to avoid.

**Fix — `alert-relay.yml` heartbeat mode.** Added a third schedule (`15 13 * * 1`, weekly Monday)
that runs `RELAY_MODE=heartbeat`. Unlike alerts/orders, `relay_heartbeat()`
(`scripts/alert_relay.py`) does **not** swallow a POST failure — it is the one mode guaranteed to
run even with nothing to relay, so it is the only mechanism that can ever catch a dead channel
before a real alert silently fails to arrive. A failed heartbeat fails the scheduled run (red in the
Actions tab; GitHub's own default failure-notification email is a channel independent of the
webhook it's testing).

**Owner action required:** none to keep current behavior — both additions are pure guard/observability
layers on top of existing (already double-gated, already-off-by-default) mechanisms; nothing changes
until `ALERT_WEBHOOK_URL` / `OFFSITE_BACKUP_GCS` are actually set. No new files to re-paste elsewhere
(GitHub Actions only).

## 35. Confirm-event attestation + catch-up-available notice — 2026-07-03 (self-improvement audit WO-5 / WO-8 part 1)

**WO-5 — confirm-event attestation.** `Claude_Task_Plan.md`'s D3 already walked `state.open_orders` and
repaired a missing `[Claude] Confirm order` calendar event in-session, but wrote no durable record that
the check happened or what it found — the one reconciliation loop in this system without a BigQuery
attestation (contrast `state.embedding_health` / `state.cadence_watch` / `state.go_without_order`, all of
which make "the check ran and found X" independently queryable). A D3 session that crashed before
reaching that bullet, or a Calendar-connector write that silently failed, was invisible until the
existing missed-confirmation hard-stop fired — potentially days later, on an order that never got
confirmed. Fix: `ops.confirm_event_snapshot` (new table, `bigquery/30_confirm_attestation.sql`) — D3 now
inserts one attestation row per still-pending `state.open_orders` item every run (found/missing,
matched calendar event id, whether this run had to repair it). `state.staged_without_confirm` flags a
pending order that is either never attested, attested-missing, or whose attestation is stale (>30h,
covering a skipped D3 run) — self-bootstrapping like every other watch view in this system: a row staged
within the grace window is never flagged even with zero history, since a D3 cycle simply hasn't reached
it yet. D3's prose now inserts the attestation immediately after its existing repair check and raises
`ops.alerts` (`warning`, `confirm_event_gap`) if `state.staged_without_confirm` shows a stale/missing row
from a PRIOR run. Verified live 2026-07-03: the one live pending order (`sweep-SGOV-20260702`, 17h old)
correctly does NOT appear in `state.staged_without_confirm` (within the 30h grace window) — no day-one
false alarm.

**WO-8 part 1 — catch-up-available notification.** `state.cadence_watch.needs_attention` already alarms
(critical, `missed_run`, `bigquery/scheduled_queries/cadence_check.sql`) on ANY missed D1/D2/D3, but
treats every miss identically. D1 (market scan) and D3 (calendar/queue hygiene) have no live
order-crafting or intraday-price dependency — firing the trigger late recovers full same-day value. D2
(and D2a once cut over) is deliberately excluded: it crafts orders off live quotes, so a late run is
harmless to execute but does not recover the value a same-day run would have had. Fix:
`state.catchup_available` (new view, `bigquery/31_catchup_notify.sql`) — a short, hand-maintained
`catchup_safe` list (currently `['D1','D3']`; update if D2a is cut over, since its reconciliation-only
scope carries no discretionary order crafting either) joined against `state.cadence_watch`. `alert-relay.
yml` gained a fourth schedule (daily `30 4 * * *`, safely after the 21:00 MT deadline in both DST states
and before the 05:15 UTC main `cadence_check.sql`) running a new `RELAY_MODE=catchup`
(`scripts/alert_relay.py::relay_catchup`) — worded as an opportunity ("no rush, fire the trigger
whenever"), delivered separately from the existing `missed_run` critical so a D2 miss is never
mis-described as low-urgency.

**Owner action required:** none — both are additive to already-gated mechanisms (D3's attestation write
requires no new grant; `alert-relay.yml`'s new schedule is covered by the same double-gate as its other
modes). No new files to re-paste (BigQuery objects applied live 2026-07-03; `Claude_Task_Plan.md`'s D3
section is read fresh each run, no separate re-paste needed there either).

## 36. D2a's first run asked chat a question nobody would ever answer — the 2026-07-03 dead-end escalation

**What happened.** The owner created D2a's web-UI trigger and, at the owner's request, fired it manually
to verify it works. It ran cleanly (a market holiday — no new fills, a well-reasoned $4.50 month-start-fee
attribution instead of a false tripwire halt, snapshot + engine refresh all correct) and correctly
reasoned that performing the D2/D2a dependency cutover unilaterally, on one non-trading-day run, was too
risky to do without confirmation. It then ended its chat output with "Reply if you'd like me to complete
the cutover." The owner caught the problem: **routine chat is unmonitored** — stated throughout
`Claude_Task_Plan.md` as the reason every other consequential signal in this system goes through
`ops.alerts` + a calendar event instead. That chat question would never be seen, so the cutover would
simply never happen — a dead-end, not a real escalation. The routine's risk judgment was correct; only
its communication channel was wrong, and that was a gap in this section's own instructions (which never
specified an escalation mechanism at all), not a one-off mistake by that run.

**Fix — make the cutover decision itself autonomous, not just re-route the question.** Re-routing "should
I cut over?" through `ops.alerts` would still require a human to eventually read and act on it — better,
but not the "minimal human intervention" the owner is building toward, and this decision has an
objective evidence bar rather than a genuine judgment call. `state.d2a_cutover_readiness`
(`bigquery/32_d2a_cutover_readiness.sql`) requires **3 DISTINCT TRADING-DAY** completed D2a runs before
`ready_for_cutover` — the 2026-07-03 holiday run does not count, since it never exercised real fill
reconciliation, SGOV sweep/cover crafting under `analytics.fn_order_guard`, or TWR-engine ingest from
freshly-pulled marks (the paths the cutover actually needs confidence in). `ops.d2a_cutover_log` is the
durable idempotency marker (a BigQuery row, not a prose/grep read of `Claude_Task_Plan.md`, so it can
never mis-detect whether the cutover already happened). Once ready, D2a performs the full cutover itself
in the same session — repo edits, commit, push — and records an `info`-severity `ops.alerts` row purely
for the audit trail. No chat question, before or after, on any future run.

**Why 3 trading-day runs, not fewer/more/an alert-based ask.** Matches this system's existing
self-bootstrapping convention (a routine/signal only becomes "acted on" after demonstrated evidence, e.g.
`state.cadence_watch`'s 1-completed-run monitored bar, `analytics.nogo_counterfactual_summary`'s
`min_n_met >= 5`) scaled to a narrow, mechanical, easily-verified routine — not a full trading strategy,
so a lower bar than a strategy-level gate is appropriate, but not zero: a single lucky/atypical run should
not flip a structural dependency change. Verified live 2026-07-03:
`state.d2a_cutover_readiness.qualifying_trading_day_runs = 0`, `ready_for_cutover = FALSE` — correctly
does NOT fire on today's holiday run.

**Owner action required:** none. D2a will cut over itself once the threshold clears, with no further
chat or reply needed — check `state.d2a_cutover_readiness` / `ops.d2a_cutover_log` any time to see
progress, or just watch for the `info`-severity `auto_cutover` row in `ops.alerts` (and the resulting
commit) once it happens.

## 37. `queue_drain_stale` false alarm on the two-phase adversarial-review due date — the 2026-07-04 div-C/D/E-202606 alert *(monitoring)*

**What happened.** D3's 2026-07-03 run raised `ops.sp_raise_alert('warning','D3','queue_drain_stale', ...)`
(alert_id `a3311f51-3399-4c93-847c-2511dbb642b2`), claiming the three June divergence-review items
(div-C/D/E-202606-1, all `PENDING_REVIEW`/`attacker-complete`) were stuck past `orchestrator_due_date
2026-07-02` despite AR_orc completing (no-op) on both 7/2 and 7/3.

**It was a FALSE ALARM.** The real `orchestrator_due_date` for all three items is **2026-07-06**
(`events.queue_events.payload.orchestrator_due_date`, set by AR_att when it advanced each item to
`attacker-complete` on 2026-07-02) — not 2026-07-02. AR_orc's own 7/2 and 7/3 run-log notes independently
read the correct field both days ("orchestrator_due_date=2026-07-06 > today ... none due for orchestrator
phase") and correctly no-op'd; it never missed a due drain. 2026-07-06 had not yet arrived when the alert
fired (or when this was triaged, 2026-07-04), so nothing was actually stale.

**Root cause.** `state.open_queue`/`events.queue_events.due_date` is set once at row creation and, for a
`PENDING_REVIEW` divergence-review item, holds the **attacker** due date only — it is never advanced when
the item flips to `attacker-complete`. The item's second, later due date (`orchestrator_due_date`) exists
solely inside `payload` JSON. `Claude_Task_Plan.md`'s D3 "QUEUE HYGIENE" instruction ("flag any
`state.open_queue` item whose `due_date` is past but still actionable") was written for the
single-due-date `PENDING_ANALYSIS` queue; applied verbatim to `PENDING_REVIEW` it compares today against
the stale attacker `due_date` instead of the real `payload.orchestrator_due_date` — so it misfires
"stuck adversarial drain" on every attacker-complete divergence-review item for the entire gap between
`attacker_due_date` and `orchestrator_due_date` (here, 2026-07-02 through 2026-07-06), which recurs every
monthly M4 divergence cycle for however many of C/D/E diverge that month.

**Fix (this change).** `Claude_Task_Plan.md` D3 QUEUE HYGIENE now explicitly branches on status for
`PENDING_REVIEW` items: `pending` → compare `due_date` (attacker_due_date); `attacker-complete` → compare
`payload.orchestrator_due_date`, never the row's `due_date` column. No BigQuery schema change — the JSON
field already carried the right value; the bug was purely in what D3 was told to read.

**Owner action:** none. Resolved `ops.alerts` row `a3311f51-...` with a note pointing here; the fixed
instruction takes effect on the next D3 run. div-C/D/E-202606-1 need no rework — AR_orc will correctly
pick them up on 2026-07-06 as it was already on track to do.
