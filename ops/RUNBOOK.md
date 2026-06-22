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

To re-apply or move to a fresh project, run `bigquery/01..16_*.sql` in order via the BigQuery MCP
`execute_sql` (same pattern the existing files use). (`16_automation_health.sql` — backup-freshness +
Apps Script heartbeat monitors — was added 2026-06-22; apply it before re-pasting `cadence_check.sql`,
which now references its views. See §3, §7, §24.)

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

**Backup *restore* drill — ADDED 2026-06-22.** A backup you have never restored is a hope, not a backup.
`scripts/restore_drill.sh` loads a dated snapshot of every `events.*` table into a throwaway scratch
dataset and sanity-checks restored row counts against live (each table must load, be non-empty, and not
exceed live). Run it periodically (e.g. quarterly) from Cloud Shell: `scripts/restore_drill.sh` (latest
snapshot) or `DATE=YYYY-MM-DD scripts/restore_drill.sh`. This converts "we export Parquet" into "we have
verified we can recover."

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
+ `roles/bigquery.jobUser`, already configured per §6). One var, **`DBT_PARITY`**, controls it (replaces
`RUN_DBT_PARITY`):
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
