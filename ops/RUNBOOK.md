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
> - **Park reconciliation** — `state.park_reconciliation` event-sources the idle-capital park holding
>   (SGOV historically, VOO from the 2026-07-15 cutover forward — `state.park_policy_current` names the
>   current vehicle); the hand-kept per-strategy share ledger is dissolved (Operating_Protocols §13).
>   `state.sgov_reconciliation` is frozen to SGOV-only history as of the cutover (§42).
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
  `bigquery/13_sgov_reconciliation.sql` → `state.sgov_position`, `state.sgov_reconciliation` (frozen to
  SGOV-only history as of 2026-07-15 — see `bigquery/54_park_policy_voo_cutover.sql` → `events.park_policy_changes`,
  `state.park_policy_current`, `state.park_position`, `state.park_reconciliation`, the live vehicle-aware
  successors, §42);
  and D2's run is logged by the routine via `ops.sp_routine_start`/`sp_routine_end` (not self-logged
  by `ops.sp_daily_refresh`).
- Quick check anytime: `SELECT * FROM state.system_health;` (want `all_green = TRUE`);
  `SELECT * FROM state.cadence_watch WHERE needs_attention;` (want zero rows);
  `SELECT * FROM state.park_reconciliation;` (events-side park shares, current vehicle, to compare to the connector).

To re-apply or move to a fresh project, run EVERY `bigquery/NN_*.sql` file present in the directory, in
ascending numeric order, via the BigQuery MCP `execute_sql` (same pattern the existing files use) —
deliberately no hardcoded endpoint (2026-07-18 audit: this line previously said "01..21", frozen at a
2026-06-24 file count while the directory grew to 87; a DR rebuild following it literally would have
silently omitted the arsenal lifecycle, cash-flow event-sourcing, gate self-heal, and everything else
in 22+. Respect each file's own "apply after"/supersede banners; `scripts/check_superseded_markers.py`
enforces the pointer discipline). (Added 2026-06-24: `18_stack_review_fixes.sql` —
additive monitor/integrity views + two `ALTER ADD COLUMN IF NOT EXISTS`; apply before re-pasting
`cadence_check.sql` / `backup_events_export.sql` and before creating `integrity_check.sql`. See §25.)
(Added 2026-06-22: `16_automation_health.sql` —
backup-freshness + Apps Script heartbeat monitors, apply before re-pasting `cadence_check.sql`;
`17_restore_drill.sql` — the `ops.sp_restore_drill()` DR-verification procedure, apply after 16. **16 +
17 + the embedding re-build are already applied live** (the agent ran them via the MCP 2026-06-22 and
verified); they are in the apply list for fresh-project reproducibility. See §3, §7, §23, §24.)

**What an "apply after N" banner does and does not mean (codebase audit 2026-07-26).** Some files carry
a banner naming a HIGHER-numbered file (e.g. a view reading a table first created later). That does not
break a strict ascending rebuild: BigQuery binds view definitions lazily, so `CREATE VIEW` applies
cleanly against a not-yet-existing table and self-heals once the later file lands in the same run. Run
the files in ascending order and let the banners inform you, not reorder you. The one real exposure is
narrow: querying such a view *mid-rebuild*, before its dependency has been applied, returns a genuine
"table not found" — that is expected, not a broken rebuild; finish the run and re-check. Deliberately
stated as a rule rather than a list of which files this affects — the 2026-07-18 note above records that
a hardcoded enumeration here rotted once already, and each file's own banner (plus `bigquery/README.md`'s
per-file "apply after" line) is the non-rotting source for that.

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
   **Deadline guard (2026-06-25; autotuned 21:00 → 21:45 on 2026-08-03, REVERTED back to 21:00 on
   2026-08-06):** `state.cadence_watch.needs_attention` requires Denver-time
   to be past **21:00** (the daily routines' after-close completion deadline), so an *off-schedule /
   manual / duplicate* run of this query *before* the routines have run today can no longer raise a
   spurious `missed_run` CRITICAL (the 2026-06-21 12:00 MT + 2026-06-24 09:37 MT morning false positives,
   exposed once the notification-complete emailer began relaying self-healed alerts). W5's 2026-08-03
   autotune to 21:45 (`process_reliability` self-improvement loop, on a 3-consecutive-cycle
   deadline-threat streak) turned out to rest on evidence that was an ARTIFACT of a marker-backfill
   counting bug in `analytics.routine_health_scorecard`: a backfilled row's `log_ts` is its backfill
   time (~22:15 MT), not its real completion time, manufacturing a fake late tail. Commit 0b9fd49
   (2026-08-04, `bigquery/89`) fixed the scorecard to exclude backfilled rows at the reader. Recomputed
   honestly, the three routines split — the artifact was NOT uniform, and only D1's evidence dissolved:
   **D1 recomputes to 1006 min-of-day (16:46 MT)**, 254 minutes clear of the +/-90-minute threat band
   around the 21:00 deadline (minute 1260) and 299 clear of the 21:45 one (minute 1305) — its entire
   evidence trail was that backfill artifact, at all three justifying cycles. D2's and D3's evidence was
   genuine and essentially unaffected by the bug — **D2 1266 (21:06 MT), D3 1193 (19:53 MT)** — and both
   sit INSIDE the band at 21:00 (6 and 67 minutes from it). That is the point: D2 is inside the band at
   21:45 as well (39 minutes), so the autotune never cleared the one routine that actually had a threat
   signal, and reverting costs it nothing. D3 is the only routine the loosening genuinely moved out of
   the band, by 112 minutes, and it was never the routine the change was argued from.
   *(Two different D2 p90s are both correct and are easy to confuse: **1266** is the recomputed value
   for the 2026-08-03 observation, pinned at that observation's own `observed_ts` — the right number for
   auditing the decision; **1245** is the CURRENT live `analytics.routine_health_scorecard` reading,
   which has no upper time bound and so drifts as new runs land — the right number for "where is D2
   today". Always say which you mean; a 2026-08-06 review pass mistook one for the other.)* Because `cadence_watch_deadline_local` is one shared constant across
   D1/D2/D3, not set per routine, all three revert together, owner-approved 2026-08-06. The revert lands
   in `bigquery/142_cadence_deadline_revert_and_evidence_drift.sql`, which SUPERSEDES
   `bigquery/129_cadence_watch_deadline_autotune.sql` (now historical-only — do not re-apply it live in
   isolation) and is the CURRENT canonical definition of `state.cadence_watch`. bigquery/142 also adds
   `state.process_constant_evidence_drift`, a backward-looking check that re-validates a self-tuning
   loop's justifying observations against the CURRENT (corrected) metric formula — closing the structural
   gap that let a since-fixed formula bug justify a live constant change with nothing ever re-checking it
   against a later correction. 21:00 still sits before this 05:15 UTC scheduled run in **both** seasons —
   05:15 UTC is 23:15 MDT in summer but **22:15 MST in winter**, and the winter figure is the binding
   ceiling on this constant — so a *genuine* miss still fires critical here year-round.
   **OPS0 winter consideration (why 21:45 was never safe to keep, independent of the evidence bug):**
   OPS0 fires 04:30 UTC and performs a same-night auto-catchup sweep keyed off
   `state.cadence_watch.needs_attention` at that same run — 22:30 MDT in summer, but **21:30 MST once
   clocks fall back** (~2026-11-01). A deadline later than 21:30, as 21:45 was, sits AFTER OPS0's winter
   dispatch: a genuinely missed D1/D3 run would read `needs_attention=FALSE` at that 21:30 MST catchup
   check (the deadline hasn't passed yet in the view's own terms) and silently lose same-night
   auto-catchup for the night — even though `cadence_check.sql` would still correctly alarm 45 minutes
   later at 22:15 MST. This hazard was dormant under MDT (today's DST state) and would only have gone
   live ~2026-11-01, but it means any FUTURE loosening of this deadline must be checked against **OPS0's
   winter dispatch time (21:30 MST)**, not just `cadence_check`'s own 22:15 MST scheduled run — the two
   ceilings are different and OPS0's is the tighter one. Computed in the `America/Denver` named zone
   (DST-safe) and NOT gated on `is_trading_day`, so D3's daily-all miss-detection still works on
   weekends/holidays. Logic in `bigquery/12_cadence_monitor.sql` (view, kept in sync but superseded for
   live-apply purposes); current source of truth is
   `bigquery/142_cadence_deadline_revert_and_evidence_drift.sql`.
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

**POLICY — the cost guardrail NOTIFIES, it does NOT block (settled 2026-07-11).** The primary
control is the Billing **budget alert** (email at 50/90/100% actual + 100% forecast); per-job
`maximum_bytes_billed` caps a runaway single query where settable. Do **NOT** use a project-wide
`QueryUsagePerDay` (BigQuery API "Query usage per day") custom quota as the primary/binding control.
Why: on 2026-07-11 that quota was set to **32 GiB/day** and was exhausted mid-day by a manual
routine-recovery session (the whole D1..SL stack re-run by hand to recover a broken Friday pipeline).
When it tripped it blocked **every** query — including the read-only `state.trading_enabled_mechanical`
gate, D2a's account reconciliation, and even `SELECT`/`UPDATE` on `ops.alerts` — i.e. cost control
silently **bricked the safety layer** and left a D2a↔trading-gate deadlock. The cap has been raised to
**1 TiB/day** and is retained ONLY as a non-binding runaway backstop (~30x real usage), never the
day-to-day monitor. Bytes are tiny (<2 MB/scan, well inside BigQuery's 1 TiB/mo free tier), so a
per-day *query* cap has no upside here and a severe downside. If query **volume** (job count; the
10 MB minimum-bill per query) ever becomes the cost driver, fix it by batching / materializing the
hot gate views (`state.system_health`, `state.trading_enabled_mechanical`) — not by a blocking daily
cap. See `events.decision_log` (entry_type=ops, 2026-07-11).

**2026-07-18 addendum — the quota has TWO dimensions; the per-user one was the recurring root
cause.** `bigquery.googleapis.com/quota/query/usage` carries two independent `consumerOverride`s:
unit `1/d/{project}` ("Query usage per day", raised to 1 TiB/day above) and a separate unit
`1/d/{project}/{user}` ("Query usage per user per day", alert string `QueryUsagePerUserPerDay`).
The 2026-07-11 remediation above raised only the project-wide dimension; a forgotten per-user
override was left at the original **32 GiB/day** (GCP's default for this dimension is
unlimited/int64-max) and caused **all four** recorded exhaustions since: 2026-07-11 (this section's
original incident), 2026-07-16 twice (`gh-ci-runner@` CI identity — OWNER_ACTIONS.md item F), and
2026-07-18 (BOTH `jacksterwu@gmail.com` at ~34.0 GiB/3046 jobs AND `gh-ci-runner@` at ~34.4
GiB/3391 jobs, each tripping its own per-user bucket independently on an unusually heavy audit day
of many ~10 MB-minimum-billed small jobs — not a runaway query/loop). 2026-07-18 evening cascade:
owner bucket tripped ~14:36 MT → D2a WARNING 16:27 MT (alert_id
`8c2c2545-9873-42ea-b990-f722a5985604`) → AR_orc CRITICAL 18:11 MT (alert_id
`c987e393-f03a-48d7-9f7b-468276bbc1a8`) → D3 CRITICAL 18:36 MT (alert_id
`90f6b974-eea4-4056-a325-0b7ff513fb19`; D2a failed, D2 never ran, D3 halted).

**Diagnostic gotcha:** metadata calls, dry-runs, result-cache repeats, and 0-byte queries all still
succeed once a per-user bucket is exhausted — only a FRESH table-scanning query fails — so a casual
connector spot-check can read healthy while the safety layer (the trading-enable gate, D2a
reconciliation, `sp_daily_refresh`, even `UPDATE ops.alerts`) is bricked for that principal (measured
live 2026-07-18 ~19:00-20:00 MT: 12 of 13 fresh scans rejected). Always probe with a query that
scans a real table, never a metadata/cached/dry-run check, when diagnosing a suspected quota brick.

**Policy extension (2026-07-18):** the per-user dimension must carry **NO** binding override —
default/unlimited, the same posture this section already mandates for the project-wide dimension's
day-to-day role; the project-wide 1 TiB/day cap remains the sole backstop. If a per-user backstop is
ever deliberately reintroduced, size it ≥30x the heaviest observed per-user day (≥1 TiB as of
2026-07-18 — mirroring this section's original ~30x-real-usage sizing rule), never a bare default
like 32 GiB.

Removal (owner-only — the Service Usage API mutation classifier blocks this from a Claude session,
the same class as DTS config/IAM grants; see OWNER_ACTIONS.md item S):
```
TOKEN=$(gcloud auth print-access-token) && curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "https://serviceusage.googleapis.com/v1beta1/projects/191682978805/services/bigquery.googleapis.com/consumerQuotaMetrics/bigquery.googleapis.com%2Fquota%2Fquery%2Fusage/limits/%2Fd%2Fproject%2Fuser/consumerOverrides/Cg1RdW90YU92ZXJyaWRl"
```
Console alternative: IAM & Admin → Quotas → BigQuery API → "Query usage per user per day" →
remove/raise the override (the redirect link below lands there). Verify (read-only):
```
TOKEN=$(gcloud auth print-access-token) && curl -s -H "Authorization: Bearer $TOKEN" "https://serviceusage.googleapis.com/v1beta1/projects/stock-trading-498512/services/bigquery.googleapis.com/consumerQuotaMetrics" | jq '[.metrics[] | select(.metric=="bigquery.googleapis.com/quota/query/usage") | .consumerQuotaLimits[] | select(.unit=="1/d/{project}/{user}") | .quotaBuckets[0] | {effective: .effectiveLimit, override: .consumerOverride}]'
```
Success = `effective` = `"9223372036854775807"` and `override` = `null`. Today's 2026-07-18
exhaustion also self-clears at midnight US/Pacific regardless, but without the removal the 32 GiB
cap stays armed and will recur on the next heavy day (it already has, four times). See also
`Claude_Task_Plan.md`'s preamble TRANSIENT-FAILURE WAIT-AND-RETRY bullet (2026-07-18), which
classifies daily-window quota exhaustion (`QueryUsagePerUserPerDay`) as non-waitable in-session —
alert-and-halt is correct, not retry.

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
  from Cloud Shell — same checks via `bq`/`gcloud storage`.

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

The **`warehouse-validation`** job's SQL dry-run steps (live `bq --dry_run` of changed `bigquery/*.sql` under keyless
GitHub→GCP Workload Identity Federation) is **OPT-IN and OFF by default** — and we recommend leaving
it off. Why: dry-running the DDL files (`CREATE TABLE/MODEL/VIEW`) requires **CREATE/DDL permissions
on the production datasets** (events/ops/analytics/state), *even in `--dry_run`*. Granting a
CI/PR-triggered identity write+DDL on the append-only source of truth over-privileges it for marginal
value, and a live dry-run does **not** catch the runtime-only bugs we actually hit (e.g. the
`EXPORT DATA` JSON-serialization error — its own comment notes dry-run misses it). So the CI service
account (`gh-ci-runner`) is kept **read-only** (`jobUser` + `dataViewer` + `connectionUser`).

This read-only posture now carries two narrow, table-scoped append-only exceptions (never a dataset-
or project-wide grant): `ops.routine_commit_markers` (OWNER_ACTIONS.md §3) and `ops.ci_findings`
(bigquery/67_ci_findings_bridge.sql, OWNER_ACTIONS.md, self-improvement audit 2026-07-16 CC-1) — each
grants `gh-ci-runner@` write to exactly one table, nothing else in `ops.*`.

WIF itself is set up (provider `github-pool/github-provider`, SA `gh-ci-runner@…`, repo variables
`GCP_WIF_PROVIDER` + `GCP_WIF_SERVICE_ACCOUNT`) and powers any future keyless need (e.g. a `dbt build`
or §16's dashboard). As of 2026-06-22 it also powers **`warehouse-validation`'s dbt-parity steps, which now
runs by default whenever those WIF vars are present** (read-only; advisory until promoted to `DBT_PARITY=block`
— see §12 "D1"). That is the real guard on the two hand-maintained copies of each view; `dbt parse` only
checks structure.

The same read-only WIF SA also powers **`warehouse-validation`'s always-blocking SQL syntax steps** (ci.yml, added
2026-07-17 after a `mode=''manual''` parse error reached the live apply step undetected — nothing in CI
parsed raw hand-SQL). It runs **by default whenever the WIF vars are present**, needs **NO DDL grant**
(BigQuery compiles a `--dry_run` before it authorizes the DDL, so `scripts/check_sql_dryrun.py` sees a
syntax error at parse time and BLOCKS on it, while it TOLERATES the "Access Denied" a read-only SA gets
on a valid CREATE and the "Not found" of a not-yet-live sibling — it can never false-block). It is a
**blocking** gate on the `CI` workflow (a parse error fails CI → blocks auto-merge), scoped to the
changed `bigquery/*.sql` in each push. Escape hatch: repo var **`RUN_SQL_DRYRUN=off`** disables it. The
old opt-in variant (`RUN_SQL_DRYRUN=true` + a `roles/bigquery.dataEditor` DDL grant to dry-run the DDL
*successfully*) is retired — that over-privilege is unnecessary to catch the parse errors that actually
bite. SQL is also dry-run via the BigQuery MCP during development, a further safety net.

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
  '<category>', '<message>', '<payload_json>')` — delivered to the operator via
  `alert_emailer.gs`'s email poll of `ops.alerts` (no calendar event for an ordinary hard-stop
  since the 2026-07-09 calendar-scope narrowing; the sole surviving calendar exception is a
  BigQuery-unreachable RE-AUTH pre-flight, since `sp_raise_alert` itself can't run when BigQuery
  is down).

**Alert DELIVERY (A2) — push channel added 2026-06-20.** A Google
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

**D1 — row-level dbt↔live parity: NOW RUNS BY DEFAULT (changed 2026-06-22).** `warehouse-validation`'s dbt-parity steps in
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
(2) the disaster-recovery / fresh-project path is "apply every `bigquery/NN_*.sql` in ascending numeric order via the MCP" (no hardcoded endpoint — see the DR note near the top of this file)
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
- **Safety-critical DML watch — detective control (ITEM 6, 2026-07-11).** This section's finding (a
  single shared owner-OAuth principal for every routine) means nothing in IAM stops a raw
  `UPDATE ops.trading_control` (or `ops.arsenal_control` / `events.strategy_lifecycle` /
  `perf.strategy_daily`) from succeeding — those four tables are the halt gate, the SISA kill-switch,
  the roster-transition truth, and the deployed-TWR engine truth respectively, each designed to be
  mutated ONLY by INSERT (or, for `perf.strategy_daily`, by the one named nightly rebuild procedure).
  `bigquery/scheduled_queries/safety_critical_dml_watch.sql` is the compensating control: every ~6h it
  scans `INFORMATION_SCHEMA.JOBS_BY_PROJECT` for the last 24h and RAISEs (fail the job — BigQuery's
  built-in failure email) plus writes a critical `ops.alerts` row on any UPDATE/DELETE/MERGE/TRUNCATE
  touching those four tables — excluding `ops.alerts` itself (its resolution columns are legitimately
  updated in place, frequently) and the one sanctioned nightly `perf.strategy_daily` rebuild inside
  `ops.sp_recompute_engine()` (matched by exact query text). It is DETECTIVE, not preventive — it
  catches a bypass within the next run (<=6h), it cannot stop the mutation. A full IAM re-scope
  (per-routine service accounts / row-column security / a write-mediating API) is deferred until a
  self-hosted MCP replaces the managed connector's single-OAuth design (see the credential table above)
  — do not re-propose it without that prerequisite.

  **2nd channel (owner action, one-time, Cloud Monitoring console)** — independent of this scheduled
  query's own health, so a dead/broken scheduler does not also silence the DML alarm:
  1. **Enable BigQuery Data Access audit logs** if not already on: IAM & Admin → Audit Logs → BigQuery →
     check Data Read + Data Write (Admin Read is on by default and insufficient here — DML needs Data
     Write). Without this, the log-based policy below has nothing to alert on and the scheduled query
     above remains the sole channel.
  2. Logging → Logs Explorer, build this query (adjust `resource.type` if the console renders BigQuery
     job-completion audit entries under a different resource type — verify against a live sample UPDATE
     job first, e.g. by running the fire-drill note in step 4):
     ```
     resource.type="bigquery_resource"
     protoPayload.methodName="google.cloud.bigquery.v2.JobService.InsertJob"
     protoPayload.serviceData.jobCompletedEvent.job.jobConfiguration.query.statementType=("UPDATE" OR "DELETE" OR "MERGE" OR "TRUNCATE_TABLE")
     (protoPayload.serviceData.jobCompletedEvent.job.jobConfiguration.query.destinationTable.tableId="trading_control"
       OR protoPayload.serviceData.jobCompletedEvent.job.jobConfiguration.query.destinationTable.tableId="arsenal_control"
       OR protoPayload.serviceData.jobCompletedEvent.job.jobConfiguration.query.destinationTable.tableId="strategy_lifecycle"
       OR protoPayload.serviceData.jobCompletedEvent.job.jobConfiguration.query.destinationTable.tableId="strategy_daily")
     ```
  3. "Create alert" from that query → Logs-based alert policy, threshold > 0 over a 5-minute rolling
     window, notify the same channels as the other absence policies
     (`local.scheduler_alert_channels` in `infra/terraform/monitoring.tf`). Name it
     **"Safety-critical DML detected"**.
  4. Optional fire-drill to derive the exact live filter fields before finalizing step 2: run one
     harmless test (e.g. `UPDATE ops.trading_control SET reason = reason WHERE FALSE` — a no-op, zero
     rows touched, still logged as an UPDATE job) and inspect the resulting Logs Explorer entry's exact
     field names/values, since BigQuery's audit-log JSON shape has shifted across API versions.
  5. Document the finished policy in `infra/terraform/monitoring.tf` as spec (see that file — appended
     as documentation only, per this repo's Terraform-is-spec-only convention, RUNBOOK "Settled
     decisions").

  **DONE — APPLIED LIVE 2026-07-17 (owner-authorized).** The 2nd channel is live end-to-end:
  - **Audit logs enabled:** BigQuery Data Access **DATA_WRITE** audit logging is on (`gcloud projects
    set-iam-policy`, adding only the `bigquery.googleapis.com` `DATA_WRITE` auditConfig — all 10 IAM
    bindings preserved; DATA_READ deliberately NOT enabled, to avoid logging every SELECT = large
    volume/cost). Verify: `gcloud projects get-iam-policy stock-trading-498512
    --format='json(auditConfigs)'`.
  - **Filter verified against a live sample (this was essential).** A fire-drill (no-op UPDATE on a
    throwaway `ops._dml_firedrill` scratch table, since a DML on the four real tables would also trip the
    primary alarm) revealed this project emits the **modern `BigQueryAuditMetadata`** shape
    (`protoPayload.metadata.jobChange.job.jobConfig.queryConfig.*`), NOT the legacy
    `serviceData.jobCompletedEvent.*` shape the earlier `monitoring.tf` draft assumed — that draft would
    have **silently never fired**. The affected table is `queryConfig.destinationTable` (a full path
    string); the statement type is `queryConfig.statementType`.
  - **Live policy:** alert policy **"Safety-critical DML detected"** (id `466668310285526135`), a
    **log-match** condition (`conditionMatchedLog` — alerts directly on the log entry; a metric-threshold
    was rejected because this project's log-based metrics surface under `resource.type="global"`, which a
    naive metric filter would miss — see `sa_key_created`'s PromQL). It matches
    `statementType IN (UPDATE/DELETE/MERGE/TRUNCATE_TABLE)` on the four tables' exact `destinationTable`
    paths, **excluding** the sanctioned nightly `DELETE FROM perf.strategy_daily WHERE TRUE` rebuild
    (same exclusion the primary watch makes — otherwise it false-alarms nightly). Notifies both email
    channels (`Jack Wu` = `1159936910064574712`, `jacksterwu@gmail.com` = `1236496873256214049`). The
    exact filter is spec'd in `infra/terraform/monitoring.tf`.
  - **Optional owner end-to-end check:** a no-op `UPDATE ops.trading_control SET reason = reason WHERE
    FALSE` should produce the "Safety-critical DML detected" email within ~1-2 min. NOTE it will ALSO be
    caught by the primary `safety_critical_dml_watch` on its next run (≤6h) → a critical `ops.alerts` row
    (expected — proves both channels); resolve that test row afterward.
  **Priority context:** this is the 2nd, independent channel; the primary `safety_critical_dml_watch`
  scheduled query (every 6h, email-on-failure ON, live 2026-07-17) is the first line.

- **§15a. Connector tool-permission matrix (added 2026-07-19; generalized 2026-08-08).** The claude.ai
  connectors UI exposes per-tool allow/ask/block controls; a tool group's dropdown reads "Always allow"
  only while EVERY tool in the group is set to allow — if even one differs, the label silently flips to
  "Custom". **A label flip is therefore not proof anyone changed a needed permission** — check the
  underlying per-tool matrix, not the group label.

  **Authority: `ops/connector_tools.yaml` (added 2026-08-08).** The per-tool expected state for ALL
  SEVEN connectors this fleet uses (FMP, Gmail, Google-Calendar, Google-Cloud-BigQuery,
  Interactive-Brokers-IBKR, Tavily, Hugging-Face — 118 tools total as of 2026-09-13) is now
  version-controlled in that
  manifest, each tool marked `required` / `optional` / `unused`. That file is the authority going
  forward. The BigQuery matrix below is RETAINED as the worked example — it predates the manifest and
  its incident record is live history — rather than duplicated into all 118 rows here; for any other
  connector, read `ops/connector_tools.yaml` directly.

  **Canonical expected matrix — Google Cloud BigQuery connector (worked example):**

  | Tool | Setting | Why |
  |---|---|---|
  | `execute_sql` (write/delete group) | Always allow | REQUIRED — all routine DML/DDL |
  | `execute_sql_readonly` | allow | REQUIRED — every routine's pre-flight liveness read (`SELECT * FROM state.trading_day_today`) |
  | `get_dataset_info` | allow | used — diagnostics/schema inspection |
  | `get_table_info` | allow | used — diagnostics/schema inspection |
  | `list_dataset_ids` | OPTIONAL | zero operational dependency (repo-wide verified 2026-07-19) |
  | `list_table_ids` | OPTIONAL | zero operational dependency (repo-wide verified 2026-07-19) |

  **Incident record, 2026-07-19.** Owner observed the read-only group's label flip "Always
  allow"→"Custom", with `list_dataset_ids`/`list_table_ids` shown as blocked. Same-evening
  investigation concluded: (a) no Claude session, sub-agent, routine, or API surface on this side can
  modify claude.ai connector settings (UI-only, owner-controlled) — the flip was platform-side (a
  connectors permission-model/UI update, or a re-auth resetting defaults), not an action by anything in
  this system; (b) `ops.run_log` back to 2026-06-25 carries zero permission-denial entries for either
  tool — no routine ever hit the block; (c) the owner had already re-enabled both toggles before this
  same-evening investigation ran, so the live probe that found both tools working confirms the
  restored state, not whether the displayed block was ever runtime-enforced (untested, now moot);
  (d) zero operational impact either way.

  **Drift-detection posture (corrected 2026-08-08).** A harmful flip (`execute_sql` or
  `execute_sql_readonly` blocked) is already self-detecting — every routine's first action is the
  BigQuery liveness read, so a block halts the routine at pre-flight and raises the connector alert
  same-session, identical to an OAuth expiry (§26 precedent). This section previously claimed the only
  invisible drift class was the two BigQuery tools nothing depends on — "harmless by definition." That
  was always narrower than it read: it reasoned only about a tool being BLOCKED, never about a tool
  being ADDED. **The larger, previously-undetected class is a vendor ADDING a tool.** A new tool arrives
  in the claude.ai connectors UI defaulted to "ask" / "needs approval" — not silently blocked, not
  silently allowed — and is invisible to every existing dead-man switch, because nothing was calling it
  before, so nothing was failing before. An unattended scheduled routine that happens to call it mid-run
  hits a permission prompt with nobody there to answer, and stalls with no error message: no exception,
  no alert, just a session that never completes. Live example: the IBKR connector added `whats_new` in
  July 2026 — currently `use: unused` in `ops/connector_tools.yaml` (nothing in the fleet calls it),
  recorded there specifically so it doesn't re-raise as unexplained drift. OPS1 (below) now closes this
  gap mechanically. **Operator guidance (unchanged):** after any connector re-auth, reconnect, or
  visible connectors-UI redesign, glance at the per-tool matrix against the table above; restore the two
  OPTIONAL BigQuery rows to allow, or accept them blocked — either is fine.

  **Operator playbook: `connector_tool_added` / `connector_tool_removed` /
  `connector_tool_enumeration_failed` (added 2026-08-08; `connector_tool_added` auto-added
  2026-08-12).** OPS1 (`Claude_Task_Plan.md`) diffs the live per-connector tool roster against
  `ops/connector_tools.yaml` every pre-market morning and raises these on `ops.alerts`.

  **`connector_tool_added` is now self-clearing — no operator action required to silence it.** OPS1
  itself appends the new tool to `ops/connector_tools.yaml` as `use: unused` in the same run it raises
  the alert (owner directive 2026-08-12: the operator grants every new tool "Always allow" regardless of
  relevance and will never manually edit this file, so a routine does the reconciliation instead). The
  alert self-heals mechanically on OPS1's NEXT run, once the merged edit is visible to a fresh
  observation — same `state.connector_tool_drift`-going-empty self-heal as always, just no longer
  waiting on a human edit to trigger it. Nothing here grants the tool any operational capability:
  `use: unused` still blocks any routine from calling it (CI gate `scripts/check_connector_tools.py`
  CHECK 3/4). The only remaining human step is optional and separate — **if** a future task wants a
  routine to actually call the new tool, promote it to `required`/`optional` and add the calling routine
  prose together, by hand, same as any other feature-adoption change.

  **A tool that reappears out of a connector's `absent:` block is a special case** (full procedure:
  Claude_Task_Plan.md's OPS1 AUTO-ADD paragraph — this is a summary, not the source of truth). If the
  matching `absent:` entry is `verified: unconfirmed`, OPS1 deletes it as part of the same edit (CHECK1
  hard-fails if a name sits in both `tools:` and `absent:`). If it's a DATED/confirmed retirement instead,
  OPS1 does NOT auto-delete it or auto-add that one tool — it leaves the alert open and flags it for a
  human glance, since silently discarding a confirmed-retirement record permanently disables CHECK4's
  ability to block a future accidental call to it.

  For `connector_tool_removed` with `use: required`, that alert is a **critical**: routine text calls
  that tool and will now fail. This category is deliberately NOT auto-reconciled (a vanished tool can
  break a routine, which needs a judgment call, not a rubber stamp) — either restore it in the
  connectors UI or fix the routine text and the manifest together; do not just delete the manifest row
  to make the alert go away.

  For `connector_tool_enumeration_failed`, the morning's sweep was incomplete and the day's clean bill
  of health is void for the named connector(s) — re-run OPS1 or check the connector manually before
  trusting the absence of other drift alerts that morning.

  **Supporting objects:** `ops.connector_tool_inventory` (append-only per-connector-per-tool observation
  record, `bigquery/151_connector_tool_inventory.sql`), `state.connector_tool_drift` (added/removed rows
  needing attention), `state.connector_tool_inventory_stale` (an independent staleness dead-man switch —
  a self-reported check cannot detect its own omission, so something outside OPS1 must), and the CI gate
  `scripts/check_connector_tools.py`.

- **§15b. Connector OAuth expiry playbook (added 2026-07-20).** The 2026-07-19 IBKR connector expiry
  (OWNER_ACTIONS.md item V) was the FIRST IBKR occurrence on record — the only prior connector-expiry
  incident on record is BigQuery's, 2026-06-26 (§26). It was discovered only at D2a's 16:20 MT
  pre-flight, hours into the evening cadence, and cascaded into a halted evening. Guidance: if the same
  connector recurs 3+ times, record its expiry interval per §15's credential table and pre-empt the
  predictable ones during the annual credential review rather than waiting to be caught mid-cascade
  again.

  **OPS1 (Morning Connector Liveness Probe, `Claude_Task_Plan.md`)** now closes most of this gap
  mechanically: its currently fixed `12:30 UTC` cron fires at 06:30 MDT / 05:30 MST (trigger
  `trig_012jxpUDFsrTR5FnSRmnxej4`) and reads IBKR/Calendar/FMP/Gmail read-only, raising a
  `connector_reauth_needed` warning on an auth-class failure. It remains well ahead of the evening
  cadence. The fixed-UTC winter shift is intentional and is validated against both seasons by
  `scripts/check_cron_dst_safety.py`.

  **PLATFORM LIMITATION (verified 2026-07-19 ~22:45-23:10 MT).** `RemoteTrigger` is unavailable INSIDE a
  headless routine session regardless of what its trigger's `allowed_tools` lists (contrast
  OWNER_ACTIONS.md item U's config fix, which is real but insufficient alone) — verified twice the same
  evening: OPS0's own run note read "RemoteTrigger tool unavailable in session", and D2a's evening note
  recorded its D2 chain-call as skipped for the identical reason. Headless auto-refire / chain-call
  therefore cannot work today; **interactive sessions remain the real refire path** until/unless the
  platform closes this gap.

  **Related gap, same evening.** OPS0's readiness view (`state.catchup_refire_readiness`) reported "0
  misses" even though SL3 sat halted on a dependency that had since been satisfied — the view counts
  only MISSING runs as refireable misses, not a halted run whose blocking dependency later cleared
  (observed `SL3|2026-07-19`; an interactive session refired it manually). The view fix is deliberately
  DEFERRED — the platform limitation above already makes any headless refire moot, so widening the
  view's definition buys nothing until that closes.

  **RE-DIAGNOSIS 2026-07-27 (this session's RemoteTrigger-gap review — the deferral rationale above is
  INCOMPLETE and its stated cause is WRONG; neither correction reopens the RemoteTrigger platform gap,
  which is still Anthropic's to close and still correctly tracked in OWNER_ACTIONS.md item U + §15b above).**
  Two corrections: **(1)** `state.catchup_refire_readiness` is a plain BigQuery view read the same way by
  interactive sessions and the operator, not only by (currently-moot) headless auto-refire — so "headless
  refire is moot" does NOT make an undercount harmless; it would mislead the WORKING (interactive) fallback
  path too. That is precisely how the 2026-07-19 SL3 miss escaped: an interactive session caught it by
  independent investigation, not because the view flagged it. **(2)** The stated mechanism ("the view counts
  only MISSING runs, not a halted-then-unblocked run") is a MISDIAGNOSIS. Reconstructed from `ops.run_log`:
  2026-07-19 was a **Sunday** (`state.market_calendar.is_trading_day = false`) and SL3's `monitor_class` is
  `daily_trading` (`ops/cadence.yaml`), so `state.cadence_expected_today` emitted NO row for SL3 that day —
  it was never "expected", so `cadence_watch.needs_attention` was undefined for it regardless of the
  halted-vs-missing distinction. The real gap is a **classification mismatch**: all four
  `monitor_class: daily_trading` routines (`ops/cadence.yaml`: D1, D2a, D2, SL3) actually run 7 days/week
  because each carries its OWN `expected_trigger` cron with `recurrence: daily` and no trading-day gate — the
  `depends_on`/`sp_assert_deps` chain only gates intra-day ORDERING, not WHETHER a routine fires — yet
  `state.cadence_expected_today` emits a `daily_trading` row only on trading days, so a NON-TRADING-DAY halt of
  ANY of the four is invisible to the whole cadence/catch-up stack — orthogonal to RemoteTrigger and
  fully in-repo-fixable. **GATE-FEEDING RECLASSIFICATION NOT done here, by deliberate judgment — owner-gated follow-up.** Reclassifying a
  routine's `monitor_class` changes what `cadence_watch`/`needs_attention` expects, which feeds `missed_run`
  and thence the trading-halt gate (`state.trading_enabled` via `system_health`); a wrong expectation could
  HALT live trading. That is not a change to make unattended/overnight — it needs a dry-run-verified pass with
  the owner able to catch a false halt.
  **EMAIL-ONLY VISIBILITY SUBSET — DONE 2026-07-27 (owner directive, the safe part).** The operator chose
  email-reminder-then-manual-refire as the workaround for the headless-RemoteTrigger gap, so the one place this
  invisibility actually bites — an operator relying on the email — is now closed WITHOUT touching the gate:
  OPS0's new STEP 1b (`Claude_Task_Plan.md` / `task_plan/OPS0.md`) directly checks D1 and SL3 (the two
  `catchup_safe` `daily_trading` routines that fire every calendar day) for a non-trading-day miss and raises the
  same actionable `catchup_refire_blocked` reminder. It reads only `ops.run_log` + the trading-day calendar and
  feeds NO gate (`cadence_watch`/`system_health`/`trading_enabled` untouched), so it carries none of the
  halt blast-radius. What remains owner-gated is only the gate-side `monitor_class` reclassification above — and
  it is now lower-priority, since the operator-facing symptom is handled.
  **[HISTORICAL — see below]** Both this STEP 1b bridge and the "owner-gated" `monitor_class` reclassification
  it was a stopgap for are SUPERSEDED as of 2026-08-08 — see the DAILY-TIER FRI/SAT CONSOLIDATION note further
  down this section.

  **DAILY-TIER FRI/SAT CONSOLIDATION — GATE-FEEDING RECLASSIFICATION DONE 2026-08-08 (interactive session, owner
  request — the dry-run-verified pass the paragraph above called for).** `ops/cadence.yaml` gained a NEW
  `monitor_class: daily_sun_thu` (every Sunday-Thursday calendar day, unconditionally NOT trading-day-gated —
  distinct from making all four `daily_trading` routines run on non-trading days unconditionally, which is what
  the paragraph above evaluated and left owner-gated) and applied it to all 8 calendar-monitored daily routines
  (D1, D2a, D2, D3, OPS0, OPS1, OPS2, SL3), ahead of a SEPARATE, later step that would retime their crons to stop
  firing Friday/Saturday. This closes the exact classification mismatch diagnosed above (a calendar-firing
  routine invisible to `cadence_watch` on a non-trading day) for all 8, not just D1/SL3, AND does so without ever
  making `cadence_watch` blind on a day these routines are expected to run — see `ops/cadence.yaml`'s own
  DAILY-TIER FRI/SAT CONSOLIDATION header note for the full rationale and `bigquery/12_cadence_monitor.sql` for
  the encoding. Consequently, **OPS0's STEP 1b (the EMAIL-ONLY VISIBILITY SUBSET above) is now RETIRED**
  (`Claude_Task_Plan.md`, OPS0's own STEP 1b entry carries the reasoning) — `state.cadence_watch` itself now
  expects D1/SL3 on every Sunday-Thursday day (holiday or not), so the synthetic non-trading-day bridge STEP 1b
  built by hand is fully subsumed by the ordinary readiness read, and — unlike simply leaving it alone — keeping
  it running past the later cron-migration step would have made it emit a false weekly "D1/SL3 missed Saturday"
  reminder forever, since it never distinguished a still-firing-Saturday cron from a deliberately-retired one.

  **CRON MIGRATION LANDED — 2026-08-08 (same day, later pass).** The "SEPARATE, later step" above is done, not
  pending: the operator flipped all 12 daily-tier live triggers (the 8 above plus the 4 `queue_driven`
  daily-tier routines AR_att/AR_orc/SL2/SL5, which share the same underlying trigger day-set even though
  `monitor_class: queue_driven` keeps them out of `state.cadence_watch` regardless) to stop firing
  Friday/Saturday America/Denver, verified via `next_run_at` reporting Sunday-evening Denver on all 12.
  `ops/cadence.yaml`'s `cron_utc` for each of the 12 was updated to match (a day-of-week list replacing the
  previous `*`), `ops/routine_backup.json` re-ingested to match (`scripts/check_cron_dst_safety.py`'s
  `backup_snapshot_errors()` hard-fails CI on any disagreement between the two), and `Claude_Task_Plan.md`'s
  remaining literal "fires daily"/"runs daily" prose for these routines corrected to "Sun-Thu." All 12 now fire
  Sunday through Thursday only.

  **CATCH-UP EXECUTOR (OPS2) — added 2026-07-27 (owner directive), the next-level workaround.** Beyond the
  email reminder, the owner opted to AUTO-RUN missed catchup_safe routines rather than manually re-run them.
  Since `RemoteTrigger run` is uncallable headless, OPS2 — a new routine on its OWN 22:15 MT cron — does NOT
  fire the missed routine's trigger; it EXECUTES that routine's slice INLINE in its own session (the cron
  launch is what works; no in-session `RemoteTrigger` call is needed). Scope: the NON-order-crafting
  catchup_safe set (D1, OPS1, SL3, W4's idempotent queue handoff, and the W/M/Q/A/SL research routines), executed at full model fidelity on
  OPS2's own branch. Deliberately EXCLUDED from inline execution: (a) the order-crafting/capital-adjacent
  routines D2/D2a/M4/Q4/A3/SL4 (never auto-refired, by design), and (b) any routine whose slice calls
  `create_order_instruction` — notably **D3**, which is catchup_safe yet crafts orders (persist-and-wait
  re-craft), so OPS2 DEFERS it to OPS0's email rather than run it half-way (OPS2 never inline-executes an
  order-crafting routine; per-connector read-only tool-scoping isn't offered by the claude.ai GUI, so full IBKR
  access is accepted 2026-07-27 and the guardrail — not tool restriction — is the control). OPS0's
  22:30 actionable email remains the residual fallback for everything OPS2 defers or fails. Cost: +1 of the
  owner's Max-plan 15/day routine-run cap (accepted). Adversarially reviewed 2026-07-27 (faithfulness/git,
  guardrails/idempotency, fallback/cadence) — the review caught + fixed the D3 order-craft scope hole, a
  model-downgrade fidelity gap, git-branch hosting, and a completion-verification gap before go-live.
  **LIVE since 2026-07-27** (`ops/cadence.yaml` OPS2 `enabled: true`; trig_id recorded in
  `ops/trigger_ids.json`) — full IBKR access accepted (a READ-only connector grant is not offered by the
  claude.ai GUI; see the guardrail language two sentences above), cron retimed the same day to
  `15 4 * * *` (04:15 UTC = **22:15 MDT / 21:15 MST**, DST-robust; the original `0 3 * * *` fell to 20:00 MST
  in winter, before the 21:00 MT deadline) — see OWNER_ACTIONS.md for the go-live/retime record. **Quote the
  MDT rendering (22:15), not the MST one (21:15)** — this line and the OPS2 slice both read "~21:15 MT" until
  2026-08-18, which cost five consecutive OPS2 sessions a phantom "timing drift" re-diagnosis of a trigger that
  was firing exactly on schedule; the same MST-vs-MDT split is the trap `scripts/check_cron_dst_safety.py` now
  enforces for `cadence.yaml`'s `time_local`, and it cannot see prose. The real residual issue the correct
  figure exposes — only 15 min of headroom before OPS0's 22:30 sweep against STEP 2's N=4 inline executions —
  is tracked as OWNER_ACTIONS.md **OPS2-headroom**, not as a trigger fault. Recorded here so the deferred item points at the RIGHT fix (cadence
  classification for the 7-day-a-week chained routines), not the misdiagnosed one (widening the readiness view
  for halted-vs-missing).

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

**Fix: `.github/workflows/stranded-branch-check.yml`** — a scheduled sweep (every 8h) that flags any
`claude/*` branch unmerged > 6h, or any open `Auto-merge conflict:` PR, and opens a deduped GitHub issue
(notifies the owner) + fails the run. Delivery is a GitHub issue, **not `ops.alerts`**, because writing
`ops.alerts` from CI would require granting the deliberately read-only CI identity (RUNBOOK §6) BigQuery
write. **Optional `ops.alerts` upgrade:** grant the WIF SA `roles/bigquery.dataEditor` on the `ops`
dataset (or a custom role with only `bigquery.tables.updateData` on `ops.alerts`) and have the workflow
`bq query` an `INSERT` via the existing WIF auth — then it flows through the alert-emailer + weekly report
+ `state.system_health` like every other alert. Left off by default to keep CI read-only.

**IMPLEMENTED VARIANT (2026-07-16, CC-1, issue #10):** the narrow, table-scoped form of this same
upgrade is now live-wired (pending the OWNER_ACTIONS.md grant) for the four CI *guard* workflows
(`live-sql-parity.yml`, `keyless-sa-audit.yml`, `wif-binding-audit.yml`, `guard-config-audit.yml`) —
not this workflow — via `ops.ci_findings` / `state.ci_findings_open`
(`bigquery/67_ci_findings_bridge.sql`), consumed by `cadence_check.sql`'s `ci_finding` alert and D3's
adjudication step. It grants write to exactly `ops.ci_findings`, not the whole `ops` dataset, keeping
the "read-only except one narrow append-only table" posture this section otherwise describes as
all-or-nothing. `stranded-branch-check.yml` could adopt the identical pattern if this gap is ever
revisited.

**Remediation, not just detection (2026-07-15, self-improvement audit — CONFIRMED GAP
red-ci-merge-conflict-no-remediation).** Before this, a red-CI branch just sat parked until a human
noticed the stranded-branch-check issue — no automated remediation at all, even for the common case of a
transient/flaky CI failure. `auto-merge-claude.yml` now requests **one** content-free re-run
(`gh run rerun <id> --failed`) the first time a branch's CI reads a genuine terminal `failure`
(`should_retry_failed_ci` in `scripts/auto_merge_decision.sh`, bounded to `run_attempt == 1` — GitHub's
own retry counter is the idempotency marker, so this can never loop). The rerun's own completion
re-triggers the workflow via the existing `workflow_run` trigger. A real code bug just fails again on
attempt 2 and falls through to the stranded-branch alert above unchanged; this never touches branch
content and never attempts to resolve a genuine merge conflict (that stays a human/session action via
the `Auto-merge conflict:` PR — automating a rebase on ambiguous conflict content was judged too risky
to do blindly).

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

Status (2026-07-29): **correction to the two Status lines above.** Verification on 2026-07-29 found that the
Operating_Protocols.md §17 detector (the never-pushed-branch reconciliation step, not this file's own unrelated
§17 public-exposure guardrail) was never inlined into `Claude_Task_Plan.md` or any `task_plan/` slice, so it
never actually ran as a live D2 step at any point, including on 2026-06-24. The "D2 Step-0 detector (§17) fired
correctly" account above reflects a session self-executing freshly-written spec prose from its own commit
that same day, not a live, wired step reachable by ordinary D2 runs on other days. The "detector closed RUNBOOK
20's second incident" and "root cause confirmed + hardened" closure claims at the two Status lines above are
therefore not supported and should not be relied on as evidence this detector was ever live. Operating_Protocols.md
§17 is now retired (2026-07-29); its successor is **OPS0 STEP 4(f)** in `Claude_Task_Plan.md`, which is live as of
2026-07-29 (raises a real `warning` alert, not shadow) and detects the same signature via git evidence against
each routine's `ops/cadence.yaml` `writes:` list, not via `ops.routine_commit_markers`.

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

**`events.adversarial_reviews` — a second table with a `superseded_by` path (added 2026-08-06,
`bigquery/143_adversarial_review_correction_path.sql`).** This section previously described `decision_log`
as the only table using the new-row-plus-`superseded_by` correction convention; `adversarial_reviews` now
uses it too, in exactly the same direction — **the correction row names the obsolete row's `event_id`,
the obsolete row is never touched, and readers exclude the row that is _named_** via
`state.adversarial_reviews_current`. `WHERE superseded_by IS NULL` is the wrong predicate for either
table (it keeps the stale row and drops the fix); `bigquery/122` states this in terms, and
`scripts/check_superseded_by_discipline.py` now blocks in CI any new canonical reader of
`adversarial_reviews` that goes to the base table instead of the `_current` view.

  This **replaces**, and is not an addition to, the interim rule that stood between 2026-08-05 and
  2026-08-06: commit `bb21c91` had blessed an in-place `UPDATE` on `adversarial_reviews` as its one
  sanctioned repair, purely because the table then had no `superseded_by` column and
  `ops.sp_score_cross_model_referee` would have inserted duplicate referee rows against a superseding
  row. `bigquery/143` fixed both, so **that UPDATE exception is withdrawn** — an `UPDATE` on this table
  is now a genuine `append_only_violation` to investigate, not a routine disposition. `sub_pattern`
  (above) remains the **only** in-place exception anywhere in `events.*`.

  Note the `state.append_only_integrity_haltable` carve-out (`bigquery/141`) that exempts
  `UPDATE adversarial_reviews` from the halt clock is deliberately **left in place but now redundant** —
  a correction is an `INSERT`, which the detector does not watch at all. `bigquery/141`'s header carries
  the retirement condition.

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

**Known residual as of 2026-06-22 — RESOLVED 2026-07-03 (CHUNKING built).** At the time this note was
written, bodies up to ~74k chars existed while content past the embedding model's token cap went
unembedded — a modest recall gap on long theses (the lead carries the decision + reasoning, so
single-vector retrieval was usually sufficient, which is why it was staged, not urgent, at the time).
The full-coverage fix described below — **one embedding row per `(entry_id, chunk_index)`** — was
built the same section originally sketched it:
- `analytics.decision_embeddings` gained `chunk_index`; `body_md` is split into ~6k-char chunks (title on
  chunk 0); `ops.sp_embed_pending` keys its MERGE on `(entry_id, chunk_index)`.
- `find_precedents` runs `VECTOR_SEARCH(top_k => 30)` then `QUALIFY ROW_NUMBER() OVER (PARTITION BY
  entry_id ORDER BY distance)=1` and `LIMIT 10` — best chunk per entry, still 10 distinct precedents.
- `state.embedding_health`'s invariant changed from "exactly one embedding per entry" to "every entry
  has ≥1 ok chunk AND zero errored chunks" (the `dup_rows` check now keys on
  `(entry_id, chunk_index)` uniqueness instead of one-row-per-entry). Stays fail-loud
  (COALESCE→unhealthy) since `all_green` depends on it.
`bigquery/02_ai_layer.sql` carries the build: applied + validated 2026-07-03 at 825/825 chunk rows,
0 failures, every entry with a `chunk_index=0` row. Live state re-verified 2026-07-30: **1,054 chunk
rows over 496 `decision_log` rows**, `state.embedding_health` reports `is_healthy=TRUE` with 0 error /
0 missing / 0 dup rows. Nothing remains pending here. The optional move to **`gemini-embedding-001`**
(higher retrieval quality; 3072-dim default, or set `output_dimensionality`) would ride a future
re-embed — change the `ENDPOINT` on `ops.text_embed` and re-run `02` (query + doc embeddings both
switch, so the space stays consistent) — but is a separate, not-yet-scheduled enhancement, not a gap
in current coverage.

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
- **NOTIFICATION POLICY (owner directive 2026-09-07) — two rules that now bind every channel in this
  section.** (1) **Every ntfy push must be accompanied by an email.** (2) **ntfy is for things needing
  operator action — no "everything is fine" pings.** An audit of every outbound path (ntfy, email,
  calendar, GitHub issue) established the constraint that makes rule 1 mechanical rather than a habit:
  **`ops.alerts` → `alert_emailer.gs` is the only email channel that exists**, and a GitHub Actions job
  cannot reach any other — there is no SMTP/mail secret (repo secrets are `ALERT_WEBHOOK_URL` +
  `OFFSITE_BACKUP_GCS`, nothing else), no mail-sending Action is used anywhere, the relay runs as the
  read-only WIF SA whose only `ops` write grant is table-scoped to `ops.ci_findings`, and **ntfy.sh
  rejects its own `Email:` forwarding header on this topic** (probed live 2026-09-07: HTTP 400
  `{"code":40053,"error":"anonymous email sending is not allowed"}` — it now requires an authenticated
  ntfy account, which a capability URL deliberately is not). Rule 1 therefore reduces to a structural
  invariant enforced in `scripts/alert_relay.py`: **the relay may only push events that are rows in
  `ops.alerts`.** Anything sourced elsewhere (a bare `state.*` view, a CI step, a fixed canary string)
  is email-less by construction and must not be pushed. Three consequences, all live as of 2026-09-07:
  - **A3's daily staged-order push is RETIRED** — it read `state.open_orders`, which no email path
    queries, making it the one operator-facing notice in the system with no email counterpart; and it
    re-listed every unreconciled order every day, including craftable ones already confirmed in IBKR
    (`pending` means "not yet filled AND reconciled", never "not yet confirmed"). Replaced by the
    `staged_order_awaiting_confirm` warning that `bigquery/229_staged_order_confirm_notice.sql` raises
    from the existing daily 05:25 UTC `daily_staging_cap_check` — one `ops.alerts` row, both channels,
    one alert per `item_key`, auto-resolved when the order reconciles. See §25 A3 below and `bigquery/229`.
  - **The weekly liveness heartbeat is now SILENT** — it still POSTs (the HTTP round-trip against the
    real configured URL is the entire dead-channel proof) but with ntfy `Priority: min` + `Cache: no` +
    `Firebase: no`, so it verifies the channel without notifying. Do NOT "fix" it by posting to a
    scratch topic or by polling instead: ntfy returns 200 for any topic name, so both alternatives
    would pass against a typo'd URL and prove nothing.
  - **The six SISA roster-change notices are email-only** (`NO_PUSH_CATEGORIES`) — they are completed,
    healthy, fully-autonomous actions needing no operator action, which `alert_emailer.gs` already
    encodes by rendering them in a non-fault lane. The list now lives in four places and
    `scripts/check_roster_notice_lockstep.py` (blocking CI) asserts all four hold the same set.
  **The one deliberate exception, kept on purpose:** `delivery_canary`'s weekly `🧪 [TEST] … no action
  needed` EMAIL still sends. It is not status chatter — it is the only end-to-end proof that email
  delivery works at all (step 1 of the next canary asserts the previous one was delivered and stamped
  `notified_ts`), it cannot be silenced without destroying that check because the send IS the test, and
  the operator asked on 2026-06-29 that it stay visible in the inbox. See §18.

- **A2 — version-controlled relay (`.github/workflows/alert-relay.yml` + `scripts/alert_relay.py`).**
  **A3 (the once-daily staged-order reminder off `state.open_orders`) was RETIRED 2026-09-07 — see the
  NOTIFICATION POLICY bullet above and `bigquery/229_staged_order_confirm_notice.sql`.** Everything below
  about A3 describes the mechanism as it stood BEFORE that date and is retained as the historical record
  of why it was built and why it was eventually removed; do not read any of it as current behaviour, and
  do not restore the push (it had no email counterpart, which is the whole reason it went).
  A scheduled GHA reads `ops.alerts` via the EXISTING read-only WIF (no new grant) and POSTs to a webhook
  — a git-reviewable poller whose failure mode is uncorrelated with the owner's Google account. It once
  also carried a once-daily staged-order reminder (A3) off `state.open_orders`, so that a silenced 07:00
  calendar alarm was not the ONLY notice of an order to confirm; that need is now met by the
  `staged_order_awaiting_confirm` `ops.alerts` warning, which reaches EMAIL as well as the push.
  **OFF until** repo **secret `ALERT_WEBHOOK_URL`** + the WIF vars
  are set. It COMPLEMENTS (does not replace) the reliable ~2h `alert_emailer`; keep the Apps Scripts until
  the relay is proven. **Do not retire `alert_emailer.gs`/`weekly_report.gs` yet.**
  **Self-provisioned-channel note (OAE-6, 2026-07-16):** `ALERT_WEBHOOK_URL` no longer requires the
  owner to stand up a webhook endpoint — `scripts/alert_relay.py::post()` now has a plain-text branch
  for `ntfy.sh` (a free, capability-URL push topic: `https://ntfy.sh/<128-bit-random-topic-name>`,
  no signup, no owner-run server), so the entire remaining owner surface for A2/A3 is: run the
  `gh secret set` / `gh workflow enable` / dispatch-heartbeat command block in `OWNER_ACTIONS.md` §D,
  then subscribe to the topic on a phone (ntfy app, or open the URL in a browser). **Upgrade path:**
  to move to an authenticated or self-hosted endpoint later, just replace the `ALERT_WEBHOOK_URL`
  secret value with the new endpoint — nothing else in `alert_relay.py`, this workflow, or the guard
  audits changes. (A1's Cloud Monitoring webhook-channel spec in `monitoring.tf`, above, is unaffected
  and stays Terraform-spec-only per the standing decision — this note is about A2/A3's GHA-side
  channel only.)
  **Craftability-aware wording (2026-07-20) — HISTORICAL: `relay_orders()` was RETIRED 2026-09-07.**
  The reasoning below is NOT obsolete and was carried forward verbatim into its replacement: the
  craftable-vs-manual-entry distinction is now rendered in the `staged_order_awaiting_confirm` alert
  message and its `needs_calendar_tap` payload field (`bigquery/229_staged_order_confirm_notice.sql`).
  Only the delivery mechanism changed. The daily A3 order reminder (`relay_orders()`) used to
  tell the operator to "tap the `[Claude] Confirm order` event" on every still-`pending` row, unconditionally
  — but per the 2026-07-09 calendar-scope narrowing a CRAFTABLE order (equity/ETF/single-leg-options,
  `instruction_id` set at staging) never gets that calendar event; its confirm surface is
  `create_order_instruction`'s own IBKR notification. Read literally, the old wording told the operator
  to go find a confirm link that does not exist, and re-fired identically every day a craftable order sat
  unfilled — including days after the operator had already confirmed it via IBKR and it was simply
  resting (`status='pending'` in `state.open_orders` means "not yet filled + reconciled," not "not yet
  confirmed"; this relay has no live IBKR read, so it genuinely cannot tell "still needs a tap" apart
  from "already confirmed, just unfilled"). Root-caused from a live false-alarm report (2026-07-20,
  ISRG/TSM staged 2026-07-17 — confirmed the confusion by checking `get_account_orders`: TSM had a live
  working DAY order the whole time, ISRG's had lapsed with the persist-and-wait re-craft blocked by a
  concurrent IBKR-connector-reauth outage — see the D2a/D3 `ops.run_log` notes for 2026-07-19). Fix:
  `relay_orders()` now selects `instruction_id` and branches the per-row note — a craftable row (
  `instruction_id` set) says "confirm surface is IBKR's own order notification, not a calendar event"
  instead; a genuinely non-craftable/manual-entry row (`instruction_id` NULL) keeps the original
  "tap the `[Claude] Confirm order` event" text, since that one still has a real event. Mirrors the same
  craftability filter already added to `state.staged_without_confirm`
  (`bigquery/30_confirm_attestation.sql`, same date). Does not fully eliminate the daily re-notify for a
  craftable order sitting unfilled across several sessions — that is inherent to the DAY-only TIF
  re-craft policy (§11) and this relay's lack of live IBKR access — only the misleading action text.

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
  baseline holds. **Promotion mechanism (self-improvement audit ITEM 31, 2026-07-15):**
  `bigquery/57_append_only_integrity_promotion.sql` + D3's MONITOR-PROMOTION SELF-FLIP step now do this
  automatically, the same self-flip pattern ITEM 24 already gave `ddl_drift`/`restore_stale` — see §27
  Promotion Ladder. No owner judgment call anymore; the owner's only remaining action is the routine
  scheduled-query console re-paste once D3 lands the promotion, same as every other scheduled-query body
  edit in this codebase.
- **B4 — position-drift guard (`state.position_reconciliation`; NOT advisory — a BLOCKING all_green /
  `trading_enabled` term since 2026-07-03).** `state.current_positions` (the 2%-sizing path) vs
  `analytics.position_lifecycle` (the TWR path) can diverge with no monitor; this flags a material
  per-(strategy,ticker) open-share gap (tolerance ignores sub-cent dividend-reinvest fractions — the
  live ~$0.20 drift does NOT trip it). Also surfaced as a warning in `cadence_check.sql` + the dbt
  singular test `assert_current_positions_match_lifecycle.sql`, but the wording that used to sit here
  ("record-only warning") had been WRONG since `bigquery/23_trading_control.sql:428,431`
  (self-improvement audit B-5-exec/B-6-data, 2026-07-03) LOGICAL_OR'd `drifted` into
  `state.system_health.all_green`, and thus into `state.trading_enabled` /
  `state.trading_enabled_mechanical`'s `AND NOT pr.drift` term
  (`bigquery/107_halt_echo_missed_run_gate.sql:173,181`) — `ops.sp_assert_trading_enabled[_mechanical]`
  RAISEs and aborts the calling routine on a drifted row, exactly like any other blocking critical.
  **Predicate (rev 2026-07-27, `bigquery/110_pending_order_aware_reconciliation.sql`, superseding the
  original flat predicate in `bigquery/18_stack_review_fixes.sql:130-153`, now SUPERSEDED there with an
  explicit marker):** `drifted` = `ABS(residual_share_diff) > 0.01`, where `residual_share_diff` nets a
  (strategy,ticker)'s still-working BUY quantity in `state.open_orders` out of the raw `share_diff`
  before testing the tolerance (suppress-only — it can only move a row toward not-drifted, never
  manufacture drift). `drifted_raw` retains the original flat `ABS(share_diff) > 0.01` predicate verbatim,
  for audit. `explained_by_pending_buy` is TRUE exactly when the two disagree — `drifted_raw` fired but
  `drifted` did not — i.e. a benign staged-but-unfilled BUY lag, not a book discrepancy. See §47 for the
  2026-07-26 incident that motivated this and what to check before escalating a `position_drift` alert.

### Theme C — CI / merge / supply-chain hardening
- **C1 — `DBT_PARITY=block` fails closed (DONE, live-on-merge).** When `block`, a missing WIF var now
  FAILS the guard (was: skip-green) so the hard parity gate can't silently become a no-op after promotion.
- **C2 — drift-defense tests + advisory `dbt test` (DONE).** `tests/test_cadence_consistency.py` +
  `tests/test_dbt_parity.py` exercise the regex parsers / column-typing so a rotted regex is caught (not a
  vacuous pass); an advisory `dbt test` step runs the B3 invariant suite vs live data.
  **[2026-07-30: that step MOVED from ci.yml's per-push `dbt-parity` job to `live-sql-parity.yml`'s DAILY
  job, and its delivery changed from a `::warning::` annotation to an `ops.ci_findings` row.** The tests
  assert properties of live DATA, which changes on the calendar rather than when someone pushes, so the push
  trigger was blind on no-push days and redundant on multi-push days; and a `::warning::` is routed nowhere,
  so a violated invariant reached no one. The finding row now flows through `state.ci_findings_open` into
  cadence_check's `ci_finding` warning alert and the monitored email channel — no new IAM grant was needed,
  because `gh-ci-runner@` already holds table-scoped `bigquery.dataEditor` on exactly `ops.ci_findings`
  (§6); writing `ops.alerts` from CI would have required a new owner-run grant and was not done. It is
  recorded under `workflow='b3-invariants'` (NOT `live-sql-parity`, whose auto-resolve is workflow-scoped
  and would otherwise clear a still-failing B3 row, and whose D3 self-heal branch expects an object name).
  Still never fails a job. ci.yml keeps the compiled-vs-live ROW parity check as the dbt-parity steps of
  its `warehouse-validation` job (those two jobs were consolidated later the same day).]**
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
  binding is fork-permissive; pure documentation if it is already scoped (likely). The companion
  `wif-binding-audit.yml` standing guard now durably opens a deduped GitHub issue on a real finding (or an
  unverified read) instead of relying solely on a possibly-unconfigured webhook — see §43.
- **E2 — keyless-SA audit (`.github/workflows/keyless-sa-audit.yml`, opt-in).** Monthly check that
  `gh-ci-runner@` / `bq-scheduler@` carry ZERO user-managed keys. **Owner to enable:** grant the WIF SA
  `iam.serviceAccountKeys.list` on those SAs and set `vars.RUN_SA_KEY_AUDIT=true`. The preventive analog
  (org policy `iam.disableServiceAccountKeyCreation`) is deferred for the same no-Org reason as §17.
  A real finding (or a read failure that could not verify) now durably opens a deduped GitHub issue,
  not just a webhook post that may be unconfigured — see §43.

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
> - **`ddl_drift` → critical: AUTOMATED (self-improvement audit ITEM 24, 2026-07-11).** Previously gated on a
>   `[Claude] Review` calendar event (2026-07-14 09:00 MT) — no longer needed. `bigquery/45_monitor_promotion.sql`
>   adds `ops.monitor_health_history` (logged unconditionally by `cadence_check.sql` every run) +
>   `state.ddl_drift_promotion_readiness` (ready once 14 consecutive DISTINCT logged days are clean). D3
>   (Claude_Task_Plan.md "MONITOR-PROMOTION SELF-FLIP") reads it and self-applies the `'warning'`→`'critical'`
>   edit to `cadence_check.sql` + commits/pushes once ready — repo-side only; the live scheduled query still
>   needs the owner's normal console re-paste (same as any other scheduled-query body edit in this codebase),
>   which D3's `monitor_promoted` alert names explicitly as the remaining step.
> - **`restore_stale` → critical: AUTOMATED (self-improvement audit ITEM 24, 2026-07-11).** Previously gated on
>   a `[Claude] Review` calendar event (2026-08-04 09:00 MT) — no longer needed.
>   `state.restore_stale_promotion_readiness` (same file) is ready once `state.restore_health.monitored=TRUE`
>   AND the last drill passed (≥1 successful `ops.drill_log` marker — the same bar this bullet always stated,
>   now mechanically checked). Same D3 self-flip mechanism as `ddl_drift` above.
> - **`append_only_integrity` → critical: READINESS SUBSTRATE ADDED (self-improvement audit ITEM 31,
>   2026-07-15).** Closes CONFIRMED GAP `append-only-integrity-no-promotion` — unlike `ddl_drift`/
>   `restore_stale`, this monitor had NO promotion path at all until now (stuck at staged-rollout
>   WARNING since 2026-06-24, not read by `state.trading_enabled`, so a real audit-trail tamper event
>   produced only a dismissible email with no halt/escalation ever). `bigquery/
>   57_append_only_integrity_promotion.sql` adds `state.append_only_integrity_promotion_readiness` (the
>   SAME 14-consecutive-DISTINCT-logged-clean-days bar as `ddl_drift`, reusing `bigquery/45`'s
>   `ops.monitor_health_history`/`ops.monitor_promotion_log` substrate verbatim) and
>   `bigquery/scheduled_queries/integrity_check.sql` now writes its own history row every run
>   (alerting behavior unchanged by that write — still WARNING-only pending promotion). Same D3
>   self-flip mechanism as `ddl_drift`/`restore_stale` above, EXCEPT the edit target is
>   `integrity_check.sql` (a separate scheduled query with no `raise_msg` accumulator of its own — D3
>   adds a direct `RAISE` there instead, per that file's promoted-body spec). **Not yet promoted** — the
>   readiness bar needs 14 FRESH logged days accumulated AFTER `integrity_check.sql`'s edited body goes
>   live via console re-paste; the pre-2026-07-15 "baseline verified clean" note above does not carry
>   over (no backfill, by design — see `bigquery/57`'s header).
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
  **[2026-07-29: `stranded_session` removed from that auto-age list — see bigquery/111 — retired alongside
  Operating_Protocols.md section 17.]**
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
**[2026-07-29: `stranded_session` removed from that auto-age list — see bigquery/111 — retired alongside
Operating_Protocols.md section 17.]**

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

  **CORRECTION (self-improvement audit 2026-07-16 orphan-cleanup pass):** the "not urgent, candidate
  for follow-up" framing above went stale the same day it was written — commit `3b8715c` ("Fix
  BigQuery SQL + dbt layer: NULL/dedup bugs, missing SGOV guard, parity gaps", 2026-07-04) already
  applied the identical `, as_of_date DESC` tie-break to both `analytics.strategy_unit_value_7d_ago`
  (`bigquery/14_weekly_report.sql`) and its dbt twin (`dbt/models/analytics/strategy_unit_value_7d_ago.sql`),
  it just never updated this paragraph to say so. Verified live in both files as of 2026-07-16: the
  `QUALIFY ROW_NUMBER()` in each now reads `ORDER BY ABS(DATE_DIFF(...)), as_of_date DESC`, matching
  `strategy_vs_park`'s pattern exactly. No further SQL change was needed for the 2026-07-16 pass;
  this note exists only so a future reader doesn't re-attempt a fix that already shipped.

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

**2026-07-13 — VOO benchmark added (owner directive, SCRIPT_VERSION v2).** Owner asked for the
weekly report to compare deployed gain/loss not only vs SGOV but also vs holding VOO (Vanguard
S&P 500 ETF) for the same amount of time, with average monthly and average yearly figures,
full design freedom otherwise delegated. VOO is deliberately a SECOND, purely informational
benchmark — SGOV stays the sole sanctioned kill/gate benchmark (`perf.strategy_daily.excess_vs_sgov`,
`perf.kill_flags`); nothing here touches that machinery (ADDITIVE ONLY, the same discipline
`bigquery/39_beta_adjusted_alpha.sql` established for the SPY beta benchmark).

*Methodology.* Three legs — deployed book (capital-weighted across strategies), SGOV, VOO — computed
over the book's OWN deployed-day set: start = the book's first deployed day (derived dynamically,
never hardcoded), end = the latest deployed mark date. SGOV keeps its existing forward-fill
convention on a missing mark (correct for a cash-like accrual — repeats the last known RATE); VOO
reads a gap as 0% (COALESCE, not forward-fill — repeating a stale rate is right for cash, wrong for
a volatile equity index; since `r_voo` LAGs over VOO's OWN marks, the next real mark after a gap
still spans it exactly, so no return is lost). Percent legs are geometric compounded returns.
"Same dollars, same days" $ legs re-base the counterfactual to the book's ACTUAL deployed capital
each day and sum arithmetically — the established `strategy_vs_park_daily.edge_dollars_day`
convention — deliberately NOT a compounding buy-and-hold hypothetical (a different question: this
answers "did today's deployed dollars beat parking/indexing today", not "what if the whole account
had bought VOO at inception"). Average monthly/yearly reuses the existing geometric `periodAvg_`
convention (`(1+cum)^(period/N)−1`), with N = deployed days shared across all three legs — but the
**gate changed from `N < period` to `N < 21`** (`MIN_AVG_DAYS`), so avg/year is now stated (marked
`†` = extrapolated) as soon as 21 deployed days exist, rather than waiting until 252. This is also
why per-week reporting was dropped from the per-strategy table (a <21-day average is noise
regardless of period) — the user asked for monthly and yearly only.

*SQL (additive, applied after `03_twr_engine.sql` + `21_strategy_vs_park.sql`):*
`bigquery/46_weekly_benchmarks.sql` — `analytics.voo_daily_return` (byte-parallel to
`sgov_daily_return`/`spy_daily_return`), `analytics.voo_cumulative` (same date axis as
`sgov_cumulative`; NULL before VOO's first mark, so the email can render "Not enough data" instead
of a false flat line), `analytics.deployed_book_vs_benchmarks` (ONE row: book/SGOV/VOO % + $ legs,
plus `n_voo_mark_days`/`voo_last_mark_date` data-presence signals every VOO-derived column NULLs out
on — so a skipped/incomplete backfill renders "Not enough data", never a confident `VOO +0.00%`).
dbt twins added (`voo_daily_return.sql`, `voo_cumulative.sql`, `deployed_book_vs_benchmarks.sql` +
`schema.yml` entries). **VOO ingest:** one-time backfill via IBKR `get_price_history` for
2026-04-17→latest (mirroring the SPY/ITEM-10 precedent, `source='connector-backfill'`); ongoing
unconditional daily pull added to D2a STEP 1 (`Claude_Task_Plan.md`) alongside the existing SGOV/SPY
pulls, with the per-name completeness check (previously OPEN-positions-only) extended to cover all
three unconditional benchmark tickers — closing the exact gap that let SPY's own history sit at a
single mark, unnoticed, since ITEM 10 (2026-07-11). **Deliberately NOT done:** a matching SPY
backfill — SPY feeds the live beta/alpha kill-suppression in `39_beta_adjusted_alpha.sql`;
retroactively deepening that history would change a live signal input, out of scope for a reporting
ask.

*`weekly_report.gs` v2 changes:* subject/HTML-title prefix changed to "Deployed vs Benchmarks" (was
"Strategies vs SGOV") — the post-send `GmailApp.search()` string was updated in lockstep (both read
`buildSubject_`'s exact prefix; a mismatch would silently break the unread/label housekeeping via its
best-effort try/catch). New headline block (book/SGOV/VOO — cumulative %, avg/month, avg/year, $)
between the trust block and the chart, with a sign-aware one-line takeaway ("beat"/"trailed" each
benchmark). Chart gained a third line (VOO, steel blue `#5f7d95` — distinct from Strategy B's blue
`#2a78d6` and SGOV's gray `#898781`), gated on `n_voo_mark_days > 0` so a not-yet-backfilled VOO never
draws a false flat/zero line; the Gmail-safe HTML-bar fallback gained a matching VOO bar. Per-strategy
table dropped the avg/week column (kept avg/month + avg/year per the ask) and gained a "VOO — own
return" row parallel to the existing SGOV row (strategy rows themselves stay excess-vs-SGOV ONLY —
never blended with VOO, to avoid any appearance that VOO factors into the kill/gate reading).
`periodAvg_`'s new 21-day gate is hardcoded inside the function itself (not a shared file-level
const) so it stays a self-contained pure function; new `isExtrapolated_` and `benchmarkRow_` helpers
copied verbatim into `test_pure_helpers.js` alongside the updated `periodAvg_`/`buildSubject_`
copies (11 new/changed assertions, including a regression pin on the live-verified 2026-07-13 figures
— book +7.3734277% over N=52 deployed days → avg/mo +2.9147%, avg/yr +41.17%† — and an explicit test
that the old `periodAvg_(0.10, 5, 5)` whole-window case now correctly returns `null` under the new
21-day floor, not the pre-redesign 0.10). `node ops/weekly_report/test_pure_helpers.js`: 49/49 pass.
Additionally verified functionally (not just via the pure-helper unit tests) with a one-off Node `vm`
harness mirroring the 2026-07-02 precedent above — stubs `BigQuery`/`GmailApp`/`Charts`/`Utilities`/
`ScriptApp` and feeds `gatherData_()` realistic response shapes across four scenarios (VOO fully
backfilled; VOO with zero marks; nothing ever deployed; stale data + a simulated chart-build failure)
— all four ran end-to-end with no throw and no `NaN` anywhere in the subject/HTML/plain-text output.
`SCRIPT_VERSION` bumped to `'v2'`; `bigquery/43_script_version_registry.sql`'s seed updated in
lockstep. **Owner action required to go live:** apply the VOO backfill + `46_weekly_benchmarks.sql`
+ the updated `43` MERGE via the BigQuery MCP (in that order — the views compute correctly with zero
VOO rows, rendering "Not enough data", but have no VOO figures to show until the backfill lands),
then re-paste `weekly_report.gs` and run `testReport()` (no new OAuth scope).

## 34. Guard config visibility + alert-channel liveness — 2026-07-03 (self-improvement audit)

**Problem.** By §25/§27, five-plus CI jobs (`alert-relay`, `offsite-backup`, `keyless-sa-audit`,
`wif-binding-audit`, `dashboard`) plus two `ci.yml` opt-ins (`DBT_PARITY`, `RUN_SQL_DRYRUN`) are all
double-gated and default OFF, each printing its own `::notice::` when disabled. That notice only
lives inside that one workflow's own run log — there was no single place showing the aggregate
picture, so a guard could sit dormant indefinitely simply because nobody thought to check five
separate Actions histories. Separately, `alert-relay`'s alerts mode is deliberately
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
that runs `RELAY_MODE=heartbeat`. Unlike alerts (and unlike the `orders` mode, a second best-effort
mode until its 2026-09-07 retirement), `relay_heartbeat()`
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
yml` gained a fourth schedule (daily `30 4 * * *`) running a new `RELAY_MODE=catchup`
(`scripts/alert_relay.py::relay_catchup`) — worded as an opportunity ("no rush, fire the trigger
whenever"), delivered separately from the existing `missed_run` critical so a D2 miss is never
mis-described as low-urgency.

**RETIRED 2026-07-18 (consolidation audit) — the `catchup` relay mode + its `30 4 * * *` cron only.**
OPS0's autonomous catch-up auto-refire (`bigquery/59_catchup_autofire.sql`, 2026-07-15) reads the same
underlying signal (`state.catchup_refire_readiness`, built on `state.catchup_available`) and fires the
trigger ITSELF in the same 04:30 UTC slot, so a push asking a human to duplicate an autonomous action
had become alert-fatigue noise (§19). The residual needs-a-human case (no live trigger id) alerts via
`bigquery/59`'s `catchup_refire_no_trigger_id` warning through the standard `alerts` relay mode. The
`state.catchup_available` VIEW stays (OPS0's readiness view builds on it); only the human-notice relay
mode was removed.

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

**Cross-reference (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive).** This exact
skeleton — an objective BigQuery readiness view (`state.d2a_cutover_readiness`) + a durable BQ idempotency
marker (`ops.d2a_cutover_log`) + self-execute in-session + an `info`-severity `ops.alerts` audit row, and
never a chat question — is reused verbatim by the fully-autonomous Strategy Arsenal lifecycle that makes
strategy add/delete autonomous. The "strategy-level gate" this narrow routine's lower 3-run bar is
contrasted against above is defined there as the multi-scrutiny graduation pipeline: adversarial pre-mortem
+ multi-regime SHADOW/PAPER forward-test + the live $2,000 PROBE + the existing 30-trade gate. See §39 and
`bigquery/35_strategy_arsenal.sql`.

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

## 38. `ops.run_log` completion write silently skipped despite real output landing — the 2026-07-06..08 D1/D3 stranding *(durability, new incident class)*

**Symptom.** D1 stranded 3 consecutive trading days. 2026-07-06 and 2026-07-07 each logged only `started`
at the time, with the session producing no output and no terminal status of its own (branch never reached
origin either day — a genuine no-output strand); 07-07 has since been given an honest backfilled `failed`
terminal row (see below) precisely *because* it produced nothing, which is a different backfill outcome
than 07-08 got — don't read the two dates as identically "untouched." 2026-07-08 was different and is the
new case this section documents: **D1's real output landed** (`Daily.md` pushed to
`origin/main`, commit `07716c04`, scan_through ~23:22–23:30Z) **but `ops.run_log` got zero rows for it —
not `started`, not `completed`, nothing.** The same evening a D3 session independently re-crafted the
halt-exempt SGOV park-sweep for real (`state.open_orders`/`events.queue_events` rows landed, timestamped)
and *also* wrote no `ops.run_log` row. Both were caught only because an operator-directed session cross-
checked git/BigQuery evidence directly and backfilled the missing rows by hand.

**This is a different failure mode than §20, not a recurrence of it.** §20's 2026-06-24 hardening made
routines push their branch and verify it (`git ls-remote --exit-code`) **before** logging `completed`,
specifically so a `completed` row can never lie about the push having happened — it closes the case where
`run_log` says done but the branch never made it out. 2026-07-08 is the mirror image: the branch/output
genuinely made it out, yet the `run_log` write — which happens as a separate, later BigQuery MCP call —
never happened at all, so there is no row to be honest or dishonest about. The §20 hardening does not (and
structurally cannot) catch this, because it only ever checks the push, never the log call's own success.

**Consequence, mechanically.** This is exactly the class `state.cadence_watch`/`cadence_check.sql` exists to
catch, and it did: `missing_dependency` → `missed_run` → `routine_stalled` fired in cascade, correctly
holding `state.trading_enabled = FALSE` for two downstream sessions (D2 halted cleanly twice, 2026-07-08,
exactly as designed — no order ever staged on stale/ungated state). Unwinding it took an operator-directed
session: (1) backfill honest `ops.run_log` terminal rows for every run whose true outcome could be verified
— `completed` for D1 07-08 and D3 07-08 (real output confirmed via git/BigQuery), `failed` for D1 07-07
(confirmed via git that it genuinely produced nothing — a terminal row, just not a `completed` one), and
no backfill at all for 07-06 (same genuine no-output outcome as 07-07, simply not yet backfilled) — (2)
manually resolve the resulting
`trading_halted` and `missed_run` alerts once their root cause was confirmed benign (no drawdown breach, no
order-guard block, no cash tripwire behind any of them), because the `staleness` auto-resolve rule's own
gap (fixed same day — see below) meant it could not unwind mechanically. See `ops.run_log` notes for
2026-07-08 (routine `D2`, all three attempts) and `ops.alerts` `resolved_note`s dated 2026-07-08/09 for the
full evidence trail.

**Root cause — open.** Why the session dies specifically in the window after the real work (and possibly
after the push) but before/during the `ops.run_log` completion write is a harness session-lifecycle
question (timing of a usage-limit cutoff or container reclamation relative to the routine's own remaining
steps), not something diagnosable from repo state alone — this repo has no visibility into harness-side
session timing. Recorded here as a new, distinct incident class (rather than folded into §20) so a 4th
occurrence is recognized immediately instead of re-investigated from scratch. Now observed 3x for D1
(2026-07-06, 07-07 as classic no-output strands; 07-08 as this new landed-but-unlogged variant) and 1x for
D3 (2026-07-08).

**Mitigating hardening applied (2026-07-09, same-day self-improvement audit).** While the session-timing
root cause stays open, the *blast radius* of a recurrence is now smaller: `bigquery/34_alert_lifecycle.sql`
Rule 4 (`staleness` auto-resolve) was missing the `category != 'trading_halted'` exclusion that
`state.trading_enabled`/`trading_enabled_mechanical` already carry — so a lingering `trading_halted` echo
kept `staleness` (and therefore the trading-enable gate) latched even after `missing_dependency`/
`missed_run` legitimately cleared, turning this incident's cleanup into three manual `ops.alerts` UPDATEs
instead of one. Fixed live and in-repo 2026-07-09 (`34_alert_lifecycle.sql`, Rule 4 now excludes
`trading_halted` too, matching the two gate views). Next recurrence: **the honest `ops.run_log` backfill
alone should be sufficient — no manual `ops.alerts` UPDATE needed at all, not even for `trading_halted`.**
`missed_run`'s own resolve rule (`ops.alert_policy`) depends only on `ops.run_log` evidence, not on
`trading_halted`, so Rules 1-3 clear `missing_dependency`/`missed_run`/`routine_stalled` directly from the
backfilled rows in one `sp_auto_resolve_alerts` call; Rule 4 then finds zero *other* open criticals
(`trading_halted` no longer counts) and clears `staleness` in the same pass, reopening the gate.
`trading_halted` itself can be left open for a human to review on their own time — it no longer blocks
anything mechanically.

**Watch-trigger for the open root cause.** A 4th D1/D3 (or any monitored routine) landed-but-unlogged strand
within a similar session-length/timing profile would be strong evidence of a systematic harness-side cutoff
rather than incidental — worth escalating past repo-side mitigation at that point. Harness internals aren't
configurable from this repo — CLAUDE.md establishes that directly for the stop-hook script specifically
("harness-managed, re-provisioned fresh each session"); it doesn't say so for session-lifecycle/timeout
behavior in general, but the same constraint plausibly applies, which is why this section stops at
"documented and mitigated" rather than promising a repo-side fix for the root cause.

**Mechanical self-heal added (2026-07-11, ITEM 3) — the recovery no longer needs a human.** The manual
backfill described above is now automated end to end, closing exactly the gap this section opened with:
a routine's real output can land on `main` while its `ops.run_log` completion write never happens.
`bigquery/38_run_log_selfheal.sql` adds three objects: `ops.routine_commit_markers` (a durable marker
that a routine's output commit landed on `origin/main`, independent of that routine's own session ever
reaching its `ops.run_log` write), `state.run_log_selfheal_candidates` (the objective view: marker
present, no completed `run_log` row), and `ops.sp_backfill_run_log_from_markers()` (inserts the missing
`completed` row, noted `auto-backfilled from commit marker`, then calls the existing
`ops.sp_auto_resolve_alerts()` so `missing_dependency`/`missed_run`/`routine_stalled`/`staleness` clear
mechanically off that fresh evidence — precisely the "honest backfill alone should be sufficient"
recovery this section already documented as the intended mechanism above, minus the human). CI
(`.github/workflows/auto-merge-claude.yml`) writes the marker for every merged commit whose subject
parses to a known routine id + date, via the keyless WIF identity; `bigquery/scheduled_queries/
cadence_check.sql` calls the backfill proc first thing, before evaluating `missed_run`/
`missing_dependency`. FAIL-CLOSED BY DEFAULT: the marker write needs a narrow, table-scoped
`roles/bigquery.dataEditor` grant on `ops.routine_commit_markers` for `gh-ci-runner@` (read-only
otherwise, RUNBOOK section 15) that the owner has not yet applied as of this writing — until granted,
the CI step no-ops/warns and this section's existing manual-backfill fallback is unchanged and fully
intact. No human review/approval/chat step is anywhere in this loop (CLAUDE.md "Settled decisions");
the compensating control is the git commit itself as objective evidence, exactly like every other
readiness view in this system.


## 39. Strategy add/delete made fully autonomous — the 2026-07-10 SISA conversion *(autonomy, owner directive)*

**Owner directive (2026-07-10).** Strategy addition and deletion become COMPLETELY AUTONOMOUS: no human
review, approval, or chat anywhere in the path. The only residual human touches are the system-wide IBKR
order-confirm tap (execution layer — it gates every trade equally, including a newcomer's first probe order
and a terminated strategy's liquidation) and deposits. This retires the last cluster of human gates in the
experiment — Experiment_Parameters.md:460 ("the participant may decide to restart"), :412 (participant tier
triage), :261/:263/:275 (out-of-table participant resolution), and Operating_Protocols.md:97 (the
strategy-design-change confirmation) — under the authority of Operating_Protocols.md:29 ("any workflow that
needs human action beyond an order-confirm is broken and Claude redesigns it").

**What changed conceptually — immutability splits into two tiers.** Roster MEMBERSHIP (which strategies
exist, and in what phase) becomes VERSIONED POLICY, mirroring the 2026-06 capital-allocation pivot
(Experiment_Parameters.md:150-154) that already carved allocation out of blanket immutability. Each
strategy's OWN machinery stays immutable for its life, frozen at SHADOW entry (`spec_locked_since`, so the
forward-test measures a fixed ruleset), with its official edge-measurement clock starting at first PROBE
trade (`immutable_since`). Adding or retiring a strategy no longer "ends the experiment"; the immutable,
load-bearing thing is now the measurement-and-selection MACHINERY, not the roster's size. Recorded as
active_auto per `ops/autonomy_levels.yaml`, loop `strategy_arsenal` (owner decision, 2026-07-10).

**The loop (SISA — Self-Improving Strategy Arsenal), five routines.** SL1 (quarterly, after Q1/Q3)
synthesizes + mechanically qualifies candidates (default-REJECT on ambiguity); SL2 (queue-driven) authors
the draft + 7-section pre-mortem and auto-revises on an AR verdict, in independent context; AR_att/AR_orc
adversarially review the three new review types (`strategy-adoption` default-REJECT, `strategy-retirement`
default-KEEP, `out-of-table-resolution` default-HOLD), with AR_orc doing MECHANICAL tier triage (absorbs the
EP:412 human step without infinite regress); SL3 (daily, after D2a) runs the SHADOW->PAPER forward-test and
judges graduation; SL5 (queue-driven) is the SOLE writer of roster membership + the self-executing fanout
engine; SL4 (monthly, after M4) is a REMOVE-ONLY discretionary-retirement proposer. The graduation pipeline
— adversarial pre-mortem -> zero-capital SHADOW signals -> simulated-fill PAPER vs SGOV (>= ~60 days, >= ~10
sim trades, excess >= 0, regime coverage) -> live $2,000 PROBE at its per-thesis risk budget (Rev 43 / EP rev 18, 2026-07-28 — formerly a flat 2%) -> existing 30-trade gate — is
the compensating control that REPLACES human PR review. The mechanical kill triggers (drawdown / 30-trade /
m2m) are UNCHANGED; SL4 only ever moves in the fail-safe (retire) direction and never below the N>=2 floor.

**Same D2a skeleton (§36) per transition.** Every state advance is fired by exactly one routine against
exactly one OBJECTIVE readiness view — `state.strategy_shadow_readiness`, `strategy_paper_readiness`,
`strategy_adoption_readiness`, `strategy_retirement_candidacy` (each the `state.d2a_cutover_readiness`
analog: a boolean `ready` + its component signals + a NOT-EXISTS-later-state idempotency guard) — never on
judgment and never on a chat question (§36's precedent: make the DECISION autonomous, do not re-route the
question; the chat-is-unmonitored constraint is fully honored). The durable idempotency marker is
`ops.roster_change_log` (the `ops.d2a_cutover_log` analog — a BigQuery row keyed by `change_key`, so SL5 can
never double-apply a fanout). Every transition writes `events.strategy_lifecycle` + `events.decision_log`;
consequential ones also write an `info`-severity `ops.alerts` row (delivered by alert_emailer.gs) purely for
the audit trail.

**Cross-model referee hardening — planned, not yet live (ITEM 27, 2026-07-11).** The adversarial-review
"independence" this section leans on (AR_att vs AR_orc, and the theater judge that checks their pairing)
all runs on the SAME Claude model weights, differing only by context-window isolation — a fragility the
project's own docs concede (`AI_Trading_Foundation.md` 2.24). `bigquery/44_cross_model_referee.sql` adds a
genuinely cross-model-family referee for the three IRREVERSIBLE decision classes (strategy-adoption,
strategy-retirement, foundation-change-TERMINATE): a third `events.adversarial_reviews` `role=
'referee_gemini'` row, generated via the EXISTING `ops.gemini` Vertex remote model (already provisioned +
billed against, in production use by `ops.sp_score_theater()` since 2026-06-06 — zero new credential),
blinded to the orchestrator's verdict (it sees only the attacker's case). DORMANT today: the objects exist
(the procedure + `state.strategy_retirement_readiness` + `state.foundation_change_termination_readiness`),
but nothing calls the procedure on a schedule and no readiness view's `ready` column reads
`referee_verdict` yet — `state.strategy_adoption_readiness`'s `ready` is unaffected by this file (its only
new AND-condition this pass is item 7's theater-judge check, a different, already-live mechanism). Design
+ staged rollout (`dormant` → `shadow` → `active_auto`, burn in one full quarter of observed
referee/orchestrator concurrence before the AND-condition goes live) in
`ops/spikes/cross-model-adversarial-independence-2026Q3.md` §6; register loop
`cross_model_referee_independence` in `ops/autonomy_levels.yaml`. Adds NO human gate at any stage — the
compensating control for promotion is the observed concurrence-rate evidence, exactly like every other
readiness-view promotion in this register.

**Kill switch.** `ops.arsenal_control` (enabled / incubation_frozen) is the owner analog of
`ops.trading_control`; `ops.sp_assert_arsenal_enabled(<routine>)` gates the top of SL1-SL5 and RAISEs + a
critical alert if disabled. A single out-of-band INSERT freezes ALL candidate generation / graduation /
retirement WITHOUT disturbing live trading. An account-wide `ops.trading_control` halt additionally defers a
PROBE launch (the capital step) but not incubation.

**Where the record lives.** Single source of truth = the checked-in `strategy/roster.yaml` (the roster
analog of `ops/cadence.yaml`), mirrored to `events.strategy_lifecycle` -> `state.strategy_roster` ->
`state.active_strategy_codes`; all BQ objects are declared in `bigquery/35_strategy_arsenal.sql` (applied
live via the BigQuery MCP, the out-of-band operating model). `scripts/check_roster_consistency.py` (wired
into ci.yml's test job) FAILS the build if roster.yaml, the state seed, the Strategy.md `## Strategy`
sections, the strategy/ slices, the Claude_Task_Plan.md slice-map, and the roster-derived SQL ever disagree
— an inconsistent roster can never merge (auto-merge only merges on green CI). The four `['A'..'E']` UNNEST
literals and the `/5` deposit divisor now read the roster view (the divisor an as-of-flow-date active-count
that still returns 5 for the founding flows, so no historical attribution moves). Dead-man coverage: SL1/
SL3/SL4 register in cadence.yaml + bigquery/12/15/18/24; the queue_driven SL2/SL5 in bigquery/15 +
ops/triggers.json + bigquery/18 stalled_runs only.

**Self-bootstrapping order (per SL5 + the D2a discipline).** ON ADD, land the repo + SQL FIRST — upsert the
lifecycle/roster row, finalize Strategy.md + regenerate slices + the slice-map row, run the three CI checks
locally, commit/push (auto-merge on green), re-apply the roster-derived views live via the MCP — and create
any per-strategy web-UI trigger LAST. ON DELETE, reverse it: delete the web-UI trigger FIRST, then remove
the cadence/plan/SQL rows, letting the `instruction_drift` completed-run windows age so the non-self-healing
`unknown_routine` alarm (§28/§30) never fires. The SL1-SL5 routines themselves are permanent.

**Owner action required:** none, ever — but you are now TOLD, by email. Add/delete still runs itself with no
approval step; since 2026-08-04 (owner directive) every roster-MEMBERSHIP change reaches your inbox within
~2h via six `warning`-severity ROSTER-CHANGE NOTICE categories: `strategy_shadow_registered`,
`strategy_probe_registered`, `strategy_graduated`, `retirement_proposed`, `strategy_deregistered`,
`roster_below_floor` (contract in the `Claude_Task_Plan.md` preamble; auto-resolve Rule 5 in
`bigquery/134_roster_change_notifications.sql`; dedicated rendering lane in `alert_emailer.gs` v5).
**Correction to this section's pre-2026-08-04 wording,** which said to "watch for the `info`-severity
`strategy_adopted` / retirement rows in `ops.alerts`": those rows were raised at `info`, and BOTH
`alert_emailer.gs` (`SEVERITIES = ['critical','warning']`) and `scripts/alert_relay.py` filter `info` out —
so a roster change reached no push channel whatsoever, and that instruction described a pull that only ever
worked if you happened to go looking. The category `strategy_adopted` was also renamed
`strategy_probe_registered`, because it fired at PAPER→PROBE rather than at the ADOPTED state. The weekly W5
lifecycle digest (`events.decision_log`, `entry_type='arsenal-digest'`) and `state.strategy_roster` /
`ops.roster_change_log` remain queryable any time. To PAUSE the whole loop, INSERT an `enabled = FALSE` row
into `ops.arsenal_control` — live trading is unaffected.

## 40. "Thin order gateway" — closed NO-BUILD, gated on Item 26's IBKR headless-auth finding (self-improvement audit ITEM 29, 2026-07-11)

**What was scoped.** Item 29 of the 2026-07-11 self-improvement audit proposed a "thin order gateway": a
code layer sitting between a routine's LLM reasoning and the IBKR `create_order_instruction` MCP tool that
would MECHANICALLY call `fn_order_guard`/`fn_order_guard_options` before every order left the system,
closing the same gap Item 15 (§ finding H-1, `b3d01c2`) already addresses by detection rather than
prevention: no BigQuery procedure can gate a call to a *different* MCP tool, so guard compliance today
depends on the routine's own markdown instructions being followed, with Item 15 making an omission
detectable after the fact (`state.open_orders.guard_passed`, a new CRITICAL check in
`bigquery/scheduled_queries/daily_staging_cap_check.sql`). A gateway would make it detectable *before* the
fact — genuinely stronger, IF it can be built somewhere IBKR's connector can be intercepted.

**Why it is NOT built.** Item 29 was explicitly gated on Item 26's Agent-SDK-orchestration feasibility spike
(`ops/spikes/agent-sdk-orchestration-2026Q3.md`, `b6d5332`). That spike's finding (a): the live IBKR MCP
connector is a claude.ai product-managed, per-user delegated-OAuth connector, unreachable from any headless
process outside claude.ai — there is no first-party IBKR OAuth path today, and the unofficial community IBKR
MCP servers with a "headless mode" are explicitly documented as **"strictly designed for local execution...
never run on public servers,"** an inappropriate foundation for real-money order placement without a
security review the spike does not attempt. The spike's own (d) recommendation is **"NO-GO, unconditionally,
for any routine that calls the IBKR connector until a follow-up spike closes the gap."** A thin order gateway
is, by definition, a routine that calls the IBKR connector — there is no interception point between
"the interactive claude.ai chat session" and "IBKR" for a gateway to occupy today. Building one now would
mean either (a) intercepting inside the same interactive session the order already flows through — which is
not a new gateway, it is just Item 15's existing detective control renamed — or (b) standing up exactly the
headless IBKR harness Item 26 said NO-GO on, purely to host a gateway. Neither is a real Item 29.

**Disposition: CLOSED, not deferred.** This is not "not yet built" pending future work in this audit — it is
correctly unbuildable under the current connector architecture, and attempting it would either be a no-op
relabeling of Item 15 or a violation of Item 26's own NO-GO. The compensating control remains Item 15's
detective `guard_passed IS NULL` CRITICAL alert, unchanged. Item 29 becomes buildable only if a future,
separately-scoped spike resolves headless IBKR auth (Item 26 (a)'s "long pole") AND that spike's own
GO/NO-GO explicitly clears order-placing routines for a headless harness — at which point a thin order
gateway is the natural first thing to build inside that harness, not a separate project. No `ops.autonomy_levels.yaml`
registration, no new schema, no live-apply: this section is the entire deliverable.

## 41. Delayed evening trigger crosses local midnight → dependency gate checks the wrong day — the 2026-07-13/14 cascade *(new incident class, fixed same-day)*

**Symptom.** Four `missing_dependency` criticals fired between 00:44-01:23 MT on 2026-07-14 —
`AR_orc` blocked on `AR_att`, `SL3` blocked on `D2a`, `SL5` blocked on `AR_orc`, `D3` blocked on `D2` — plus
two carried-over duplicates from the evening before and the nightly `scheduled.freshness`/`scheduled.cadence`
criticals, all landing while `state.trading_enabled = FALSE`. Surfaced via the `alert_emailer.gs` digest;
investigated live (BigQuery + `RemoteTrigger get` on each routine's cron) rather than assumed.

**Root cause, mechanically confirmed.** `RemoteTrigger get` on each trigger id (`ops/trigger_ids.json`) showed
every evening-block cron (`D2` 23:15 UTC, `AR_att` 23:30 UTC, `AR_orc` 00:00 UTC, `D3` 00:30 UTC, `SL5` 01:15
UTC, `SL3` 02:00 UTC — all correctly matching `ops/cadence.yaml`'s documented MT times, so this is NOT a
schedule-drift bug like the pre-2026-07-10 UTC-evaluation issue) actually fired 5-7h late on 2026-07-13:
`last_fired_at` for `D2` was ~22:07 MT vs. its 17:15 MT slot, `AR_orc` ~00:42 MT (07-14) vs. its 18:00 MT
(07-13) slot, `D3` ~01:20 MT vs. 18:30 MT, etc. Root cause of the delay itself is the same opaque Anthropic
cloud trigger infra already logged for the 2026-07-12 W2/W4 no-show (`ops/cadence.yaml` DAILY/WEEKLY
schedule comments) — no log access from this repo. The NEW finding is the second-order effect: several
evening MT slots are encoded as cron expressions landing on or after UTC midnight (`AR_orc` `0 0 * * *`, `D3`
`30 0 * * *`, `SL5` `15 1 * * *`, `SL3` `0 2 * * *`), which is normally harmless (a routine still executes
within the same MT calendar day it targets) — UNTIL a multi-hour delay pushes the ACTUAL execution past local
midnight MT too. Each routine computes its dependency-check date (`in_run_date` passed to
`ops.sp_assert_deps`) from `state.trading_day_today` at the moment it happens to execute, not from when it
was scheduled — so a routine that finally runs at, say, 00:42 MT checks its upstream against the NEW calendar
day (whose own evening chain hasn't started yet, next slot hours away) instead of the day it was actually
serving, even though that day's upstream had genuinely completed — also late, but before midnight. Confirmed
concretely: `AR_att` completed cleanly for 2026-07-13 at 23:05 MT; `AR_orc` fired at 00:42 MT 2026-07-14 and
raised `missing_dependency` checking `AR_att` against 07-14 instead of 07-13. Same mechanism for `SL3`
(`D2a` completed 07-13 at 16:28 MT, `SL3` fired 00:59 MT 07-14 and checked against the wrong day). Two of the
four headline alerts (`SL5`<-`AR_orc`, `D3`<-`D2`) were NOT this artifact — `AR_orc` and `D2` themselves
never produced a `completed` row for 07-13 either (see below), a genuine gap, not a day-boundary mismatch.

**Distinct from, and layered under, §38.** §38's landed-but-unlogged self-heal fixes the case where the
upstream's real output landed but its OWN `ops.run_log` completion write never happened. This incident's
upstreams (`AR_att`, `D2a`) DID log `completed` — correctly, for the day they actually processed. The bug is
in the CALLER's equality check (`run_date = in_run_date`), not in the upstream's logging. Both self-heals
now live inside the same `ops.sp_assert_deps` (`bigquery/12_cadence_monitor.sql`), in the order: (1) best-
effort `sp_backfill_run_log_from_markers()` call, (2) the dependency check itself, now tolerant of either
`in_run_date` or `in_run_date` minus one day (the latter only while Denver wall-clock is before **noon** of
`in_run_date` — comfortably covering the observed 5-7h delay while staying well clear of D1's normal 4pm MT
slot for the new day, so a routine invoked once that day's own fresh evening cycle is genuinely underway
still gets a real gate). Relaxes an equality check on already-correctly-dated data; fabricates nothing.

**Why the other two alerts (`SL5`<-`AR_orc`, `D3`<-`D2`) needed no code change.** `AR_orc` halted on its OWN
(now-fixed) `AR_att` gate rather than ever completing, so it had no `completed` row for `SL5` to find even a
day early — once `AR_orc` succeeds on a future invocation (immediate now that its own gate self-heals), `SL5`
resolves on its next run normally, no separate fix needed. `D2` halted for a genuinely different reason (the
`trading_halted` gate — order-staging blocked because `state.trading_enabled = FALSE`, itself tripped by
this same alert cascade) — a real, correctly-fail-closed gap the owner reviewed and manually resolved
(`ops.alerts` resolved_note, 2026-07-14, "root cause fully diagnosed... no capital impact"), unrelated to the
midnight-crossing bug and requiring no code change (`trading_halted` is deliberately human-latching per
`ops.alert_policy`, not mechanically auto-resolvable — see §38's own Rule-4 fix for that design).

**Verification.** Live-applied via BigQuery MCP 2026-07-14, then sanity-tested read-only (no test rows written
to production `ops.run_log`/`ops.alerts` — replayed the exact `missing`-computation WHERE clause against real
data at the actual historical fire timestamps): confirms the fix clears the `AR_orc`<-`AR_att` and `SL3`<-
`D2a` false positives while correctly leaving `D3`<-`D2` (a genuine gap) still failing.

**Owner action required:** none. All four `missing_dependency` criticals plus the two `scheduled.*` criticals
remain `latching = FALSE` in `ops.alert_policy` and clear mechanically once the normal 07-14 evening cycle
(D1 4pm MT onward) completes — this fix prevents the SAME false positive recurring, it does not itself need
to touch `ops.alerts`.
registration, no new schema, no live-apply: this section is the entire deliverable.
---

## 42. SGOV removed from the weekly email; idle-capital parking vehicle switches SGOV → VOO — the 2026-07-15 owner directive *(design, owner directive)*

**Directive.** Two changes, owner-specified 2026-07-15, both scoped to the weekly digest email's display
and the physical idle-capital parking vehicle — neither touches the sanctioned kill/gate benchmark:

1. **Weekly email v3** (`ops/weekly_report/weekly_report.gs`, `SCRIPT_VERSION` `'v2'` → `'v3'`). The
   "Deployed Book Since..." headline section (§33/§41's v2 design: deployed-book vs SGOV vs VOO,
   cumulative/avg/$-edge) is removed entirely. SGOV is removed from the subject line, the returns
   chart, and the per-strategy table. The table is retitled "Average Return" and now shows each
   strategy's OWN average return on deployed capital only, over active (deployed) time only —
   `analytics.strategy_vs_park_daily.deployed_unit_value`, a pure `.gs`-side switch from
   `excess_vs_sgov`; no BigQuery view changed, since `deployed_unit_value` already carried exactly
   this figure. The chart keeps each deployed strategy's cumulative return + VOO's own cumulative
   return, each its own natural (non-rebased) line — VOO was already plotted this way; only the SGOV
   line was removed. VOO is the sole displayed benchmark, still purely informational.
2. **Idle-capital parking vehicle: SGOV → VOO.** Idle (undeployed) capital parks in VOO going forward.
   Implemented event-sourced via the new `events.park_policy_changes` table + `state.park_policy_current`
   view (`bigquery/54_park_policy_voo_cutover.sql`), NOT a hardcoded cutover date — the actual cutover
   activates only when a live INSERT records the owner's manual "sell all SGOV, buy VOO" IBKR transfer
   (a separate, later, one-time action the owner triggers; not executed by this migration). History
   before that transfer is genuinely SGOV and is not rewritten — `events.parking_events` gained a
   `ticker` column, backfilled `'SGOV'` for all 22 pre-existing rows (2-statement `ADD COLUMN` + `UPDATE`,
   verified live). `state.sgov_position`/`state.sgov_reconciliation` are frozen (via `WHERE ticker='SGOV'`)
   to SGOV-only history; the new `state.park_position`/`state.park_position_current`/`state.park_reconciliation`
   supersede them going forward, vehicle-aware. `analytics.fn_order_guard`'s `p_is_sgov` parameter is
   renamed `p_is_park` (same call position — zero call-site changes required) and its price band is now
   read live from `state.park_policy_current` (0.2% for SGOV, 0.5% for any other vehicle), so the
   function needs no further edit on the actual cutover day. VOO's IBKR `contract_id` (136155102, ARCA
   US primary listing) resolved via `search_contracts` and cached in `Claude_Task_Plan.md`.

**Explicitly out of scope — the sanctioned kill/gate benchmark is unchanged.** `perf.strategy_daily.excess_vs_sgov`,
`perf.kill_flags`, `state.strategy_retirement_candidacy`, `state.strategy_paper_readiness`'s PAPER-phase
excess-vs-SGOV gate, `analytics.nogo_counterfactual`, `analytics.sgov_daily_return`, and
`ops.sp_recompute_engine` all remain SGOV-anchored, exactly as `bigquery/39_beta_adjusted_alpha.sql` and
`bigquery/46_weekly_benchmarks.sql` already document. SGOV's own daily mark ingestion continues
unconditionally in D2a (alongside SPY and VOO) regardless of the parking-vehicle switch, because that
benchmark still needs it — this was NOT touched.

**Deliberately not done — the 9 pre-existing `ticker != 'SGOV'` defensive filters were NOT widened to
also exclude VOO** (`analytics.position_lifecycle`, `analytics.tax_lots`, `analytics.execution_quality`,
`state.open_positions_summary`, `analytics.strategy_vs_park`'s commission CTE, etc. — the same filters
§29 documents). SGOV could never legitimately be a strategy's own directional position (no strategy has
a "buy risk-free T-bills" thesis), so a blanket exclusion was always safe defense-in-depth; VOO is an
ordinary, liquid, popular ETF a strategy COULD legitimately trade as a real thesis (none does today,
confirmed via repo-wide search, but nothing structurally prevents it going forward). Blanket-excluding
VOO the same way would silently drop a future strategy's real P&L from the deployed-TWR engine — a
silent correctness bug, worse than the leak class it would guard against. Instead, a new DETECTIVE dbt
test, `dbt/tests/assert_no_park_ticker_in_strategy_positions.sql`, watches `state.trade_fills_curated`
for any `ticker IN ('SGOV','VOO')` row carrying a non-NULL `strategy` (the §29 leak shape, either
vehicle), carving out the known 2026-06-30 SGOV incident by `trade_id` so it doesn't re-flag history.

**Files changed:** `ops/weekly_report/weekly_report.gs` (v3 rewrite), `ops/weekly_report/test_pure_helpers.js`
(mirrored, 58/58 assertions pass), `ops/weekly_report/sample_preview.html`, `ops/weekly_report/README.md`,
`bigquery/43_script_version_registry.sql` (file bumped to `'v3'`; **live MERGE deliberately deferred**
until the owner actually re-pastes the `.gs`, to avoid a false `state.script_version_drift` alarm in the
interim), `bigquery/54_park_policy_voo_cutover.sql` (new, applied live and verified byte-identical output
for `state.sgov_position`/`state.sgov_reconciliation` pre/post, plus a 5-case `fn_order_guard` fire-drill
re-check), `bigquery/55_park_policy_voo_seed.sql` (new, `events.decision_log` entry applied live),
`dbt/tests/assert_no_park_ticker_in_strategy_positions.sql` (new), `dbt/models/sources.yml`,
`dbt/README.md`, `Operating_Protocols.md` §13 (full rewrite — vehicle-generic, event-sourced) + §1/§16/§18
pointer updates, `Claude_Task_Plan.md` (D2a tripwire/sweep/cover sections retargeted; marks-ingest/kill-gate
sections explicitly left unchanged; VOO `contract_id` cached), `ops/cadence.yaml` (+regenerated
`ops/triggers.json`, `check_cadence_consistency.py` green), `bigquery/README.md`.

**Owner actions — all 4 complete as of 2026-07-15 (same day):** (1) re-pasted `weekly_report.gs` into
the live "Stock-Trading Automation" Apps Script project and ran `testReport()` clean — see "Deployed
live" note below; (2) applied `bigquery/43_script_version_registry.sql`'s MERGE live in the same window
— `state.script_version_drift` confirms v3=v3; (3) executed the manual IBKR "sell all SGOV, buy VOO"
transfer (92.0612 SGOV sh → 13.4048 VOO sh, real fills below); (4) same day, ran the filled-in cutover
SQL (`bigquery/56_park_policy_voo_manual_cutover_TEMPLATE.sql`) and confirmed `state.park_reconciliation`
reconciles cleanly against the connector with no tripwire hard-stop — see "Cutover executed live" below.

**Verification.** `node ops/weekly_report/test_pure_helpers.js` — 58/58 pass. Live BigQuery: `state.sgov_position`/
`state.sgov_reconciliation` post-migration output verified byte-identical to pre-migration (92.0612 SGOV
shares, $9,253.99 MV, unchanged). `analytics.fn_order_guard` fire-drill: oversize/off-band/negative-qty
strategy-order rejections unchanged (FALSE/FALSE/FALSE); SGOV in-band park order passes, off-band park
order rejects (TRUE/FALSE) — identical to pre-redefinition behavior. New dbt test returns zero rows against
live data. `scripts/check_cadence_consistency.py` — OK, `ops/triggers.json` current.

**Post-implementation review fix (2026-07-15, same day).** A multi-agent adversarial review of this
migration caught two latent bugs in `bigquery/54_park_policy_voo_cutover.sql`, neither triggered by
today's SGOV-only live state but both real on the actual cutover day, plus two stale doc cross-references:
1. `state.park_position_current` joined FROM `state.park_position` (only has a row per ticker with
   existing `events.parking_events` history) INTO `state.park_policy_current` via a default INNER JOIN.
   Since the real cutover is two separate, non-atomic INSERTs (bigquery/56 step 1 flips the policy row;
   step 2, gated on real IBKR fill data, records the matching `parking_events` legs), the INNER JOIN would
   have returned **zero rows** in the gap between those two steps — reintroducing exactly the "must never
   silently return zero rows" failure mode `state.sgov_reconciliation` (same file) explicitly guards
   against with a LEFT JOIN. `state.park_reconciliation` is built directly on top of it, so the §13.A
   hard-stop check would have silently gone blank right when a cutover-day discrepancy would matter most.
   **Fixed**: now drives FROM the always-exactly-one-row `park_policy_current` and LEFT JOINs OUT to
   `park_position`, with `COALESCE(...,0)` on the numeric columns — guarantees one output row naming the
   current vehicle even with zero recorded events, showing `0` (not silence) as the discrepancy signal.
2. `state.park_policy_current` ordered `QUALIFY ROW_NUMBER() OVER (ORDER BY effective_date DESC, event_ts
   DESC)` — `effective_date` is a hand-typed, operator-supplied target date (`bigquery/56`'s
   `<TRANSFER_DATE>` placeholder), not a transition time, violating this repo's own documented house rule
   (`bigquery/01_schema.sql`'s `queue_events.due_date` discussion: order by `event_ts`, the actual
   insert-time transition order, never a target date). A forward-dated or mistyped `effective_date` on the
   real VOO INSERT could have flipped the live vehicle ahead of the operator's intent. **Fixed**: now orders
   by `event_ts DESC` only — whichever row was actually inserted last always wins, matching the file's own
   stated "the actual live INSERT... is what flips every downstream view" design goal.
3. `ops/cadence.yaml` and `ops/weekly_report/README.md` both linked "the 2026-07-15 redesign" to RUNBOOK
   §33 (the pre-v3 "Strategies vs SGOV" section, untouched by this commit) instead of this §42. **Fixed**:
   both now point to §42 (with §33 kept as the pre-v3 history pointer).

Both view fixes re-applied live via `CREATE OR REPLACE VIEW` (idempotent, DDL-only). Re-verified:
today's live `state.park_policy_current`/`state.park_position_current`/`state.park_reconciliation` output
is byte-identical to pre-fix (SGOV, 92.0612 sh, $9,253.99 MV) — behavior-preserving, as designed. A
read-only simulation of the cutover-gap scenario (policy row = VOO, zero VOO `parking_events` rows, exactly
today's real live data otherwise) now correctly returns one row — `park_ticker=VOO, events_park_shares=0,
park_close=$691.10 (live VOO mark), events_park_market_value=$0` — instead of returning nothing. Full
suite re-run clean: 58/58 JS assertions, 272/272 pytest, `check_roster_consistency.py` /
`check_cadence_consistency.py` / `check_script_version_consistency.py` all OK, `dbt_parity.py` 0 drift.

**Cutover executed live (2026-07-15, same day as the above).** The owner's manual IBKR "sell all SGOV,
buy VOO" transfer ran. Actual fills (`get_account_trades`):
- SELL SGOV: 92.0612 sh across 3 exchange-split fills (4 @ BYX, 88 @ BYX, 0.0612 @ IBKR), all @ $100.53,
  total commission $0.559149, gross $9,254.912436, order_id 1061743393.
- BUY VOO: 13.4048 sh across 2 exchange-split fills (13 @ DARK, 0.4048 @ IBKR), all @ $690.33,
  total commission $0.352978, gross $9,253.735584, order_id 1061743463.

`bigquery/56_park_policy_voo_manual_cutover_TEMPLATE.sql`'s 5 placeholders were filled in with these real
values (not the earlier ~$560/~$694 estimates) and run live as a single atomic `BEGIN TRANSACTION` /
`COMMIT TRANSACTION` — both the `events.park_policy_changes` INSERT and the two `events.parking_events`
legs landed together, so the cutover-gap window the same-day post-implementation review fixed in
`state.park_position_current`'s join logic was never actually opened by this run. Verified post-run:
`state.park_policy_current` = VOO (`effective_date` 2026-07-15); `state.park_position_current` and
`state.park_reconciliation` both report events-side shares = 13.4048, exactly matching the connector's
live VOO holding (`get_account_positions`, contract_id 136155102). `park_mark_fresh=false` at check
time — D2a's 2026-07-15 VOO daily mark hadn't run yet mid-session; expected, resolves at the next D2a
cycle, not a discrepancy. Also recorded VOO's first live commission data point (Operating_Protocols.md
§13's Commission-model note, previously UNVERIFIED): ≈0.0038% of trade value — not SGOV's ~1% schedule,
not $0 either; only one order so far, so `comm_buffer` still falls back to the connector's actual
per-order commission until more fills accumulate. → `events.decision_log`
851e579a-efba-4a72-840e-889f185bbc17 "SGOV->VOO parking-vehicle cutover executed live (2026-07-15)".

## 43. Keyless-SA / WIF-binding audit findings had no durable record — 2026-07-15 (self-improvement audit)

**Problem.** `keyless-sa-audit.yml` (E2) and `wif-binding-audit.yml` (E1) — unlike their sibling
read-only-CI-finding workflows `stranded-branch-check.yml` (§20) and `guard-config-audit.yml` (§34) —
only responded to a real finding (a user-managed key, or a fork-permissive WIF binding) with an
`::error::` annotation, a best-effort POST to `scripts/notify_webhook.sh` (a confirmed silent no-op
when `ALERT_WEBHOOK_URL` is unset — it is unset today), and `exit 1` to redden the monthly cron's
Actions run. None of that outlives GitHub's Actions run-history retention. A genuine credential
compromise (a downloadable key reintroduced on `gh-ci-runner@`/`bq-scheduler@`) or a fork-permissive
WIF trust-boundary widening could therefore leave **zero durable trace** beyond a run that eventually
scrolls off history — confirmed live: `wif-binding-audit.yml` had 3 real `failure` runs during
2026-06-29 bring-up (IAM-grant propagation lag) with no corresponding GitHub issue anywhere. This is a
finding-durability gap, not a stalled autonomous pipeline — remediation for a leaked key or a
fork-permissive binding is inherently a human GCP-console IAM action (by-design exclusion, same class
as §17/§25 E1/E2), so no automated "consumer that takes action" is possible or appropriate here. The
fix only makes the finding **durably visible**, mirroring the pattern already proven twice in this repo.

**Fix.** Both workflows now carry `issues: write` (added to their existing `contents: read` /
`id-token: write`) and two new steps mirroring `guard-config-audit.yml`'s dedup-issue pattern:
- **"Open/refresh finding issue (dedup)"** — runs on `always()` (the audit step itself exits
  non-zero on a finding, which by default skips subsequent steps) whenever the audit step's new
  `id: audit` / `result` output is `finding` or `inconclusive`. Opens a title-prefix-deduped GitHub
  issue (`⚠️ Keyless-SA audit: needs attention` / `⚠️ WIF binding audit: needs attention`) — or
  comments on the existing one if already open — with the persisted finding/verify-error text and a
  link to the run. `FINDING` (a real key / a scoped-binding violation) and `INCONCLUSIVE` (a
  read-failure that could not confirm posture either way — e.g. IAM-grant propagation lag, NOT itself
  a security finding) are labeled distinctly in the issue body so a transient propagation hiccup can
  never be mistaken for a leaked credential or a fork-permissive binding — same distinction the audit
  scripts' own `verify_error` vs. real-finding branches already draw internally.
- **"Close finding issue if resolved"** — runs when `result == 'ok'` (a real, successfully-verified
  clean run); comments + closes any open dedup issue. Never fires on a skipped run (guard off / opt-in
  not enabled) — an unverified state is never reported as "resolved."
- The audit step (`id: audit`) now writes `result=finding|inconclusive|ok` to `$GITHUB_OUTPUT` and the
  finding/verify-error message text to `/tmp/audit_finding.txt` immediately before each `exit`, so the
  two new steps (which run after the audit step has already failed) have both a machine-readable
  outcome and the human-readable detail to work from. The existing webhook POST + `::error::` +
  `exit 1/2` behavior is unchanged — this is additive.

Not a cadence change (no new routine, no new schedule, no BigQuery object) — both workflows keep their
existing monthly opt-in cron and double-gate (`vars.RUN_SA_KEY_AUDIT` / `vars.RUN_WIF_AUDIT` + the WIF
vars); `ops/cadence.yaml`'s informational CI-jobs comment block, `bigquery/12/15/24`, `ops/triggers.json`,
and `Claude_Task_Plan.md`'s ROUTINE INVENTORY are all unaffected (these two workflows were never part of
the 29-routine BigQuery-tracked cadence set — `scripts/check_cadence_consistency.py` does not enumerate
them, same as `stranded-branch-check.yml`/`guard-config-audit.yml`/`offsite-backup.yml`/`dashboard.yml`).

**Verified:** `actionlint -color` (repo-wide, auto-discovers `.github/workflows/`) exits 0 on both
edited files — the embedded shellcheck pass (the CI-blocking gate, §25 Theme C actionlint job) is clean.
No new secrets/grants: `GH_TOKEN: ${{ github.token }}` (the same default token `stranded-branch-check.yml`
/ `guard-config-audit.yml` already use for `issues: write`) is sufficient; no GCP IAM change.

**Owner action required:** none. Both workflows stay OFF by default (`vars.RUN_SA_KEY_AUDIT` /
`vars.RUN_WIF_AUDIT` unset) exactly as before; this only changes what happens on the next real finding
once/if the owner enables them per E1/E2 above.

## 44. `append_only_violation` on `parking_events` — expected trailing detection of the 2026-07-15 cutover backfill *(monitoring, false-alarm-shaped)*

**Fired 2026-07-16 07:40 UTC** (`scheduled.integrity` / `append_only_violation`, WARNING): *"out-of-band
UPDATE/DELETE/MERGE on immutable events.* table(s): UPDATE parking_events."* Payload identified
`job_ZDLqO17hsfG4MKAJbeAu1YO1wr_8`, `UPDATE events.parking_events SET ticker='SGOV' WHERE ticker IS
NULL`, run by `jacksterwu@gmail.com`.

**Not a violation.** This is the documented §42 cutover backfill itself — `events.parking_events`
gained a `ticker` column on 2026-07-15 and the 22 pre-existing rows were backfilled `ticker='SGOV'`
(a 2-statement `ADD COLUMN` + `UPDATE`, verified live per §42's "Cutover executed live" note). The
live table description already states this is correct ground truth: the account held nothing but
SGOV before the transfer. `INFORMATION_SCHEMA.JOBS_BY_PROJECT` confirms the UPDATE actually ran
2026-07-15 13:57:45 UTC — same day as the rest of the cutover, well before that day's
`integrity_check` pass (which runs ~05:20 UTC and so predated the backfill). The tripwire
(`bigquery/scheduled_queries/integrity_check.sql`) uses a **rolling 48h lookback**
(`state.append_only_integrity`, `bigquery/18_stack_review_fixes.sql`), not a calendar-day one, so it
first caught this job on the very next run (2026-07-16 07:40 UTC) — a one-day-lagged, expected
detection, not a new incident.

**Resolved same day** with a root-cause note. Because `sp_raise_alert_once` dedupes forever on exact
`(category, message)` while `NOT resolved` (`bigquery/10_observability.sql`), resolving reopens the
dedup gate — and the source job (2026-07-15 13:57:45 UTC) is still inside the 48h window at the next
run (2026-07-17 ~07:40 UTC cutoff ≈ 2026-07-15 07:40 UTC), so **one more identical WARNING is
expected around 2026-07-17 ~07:40 UTC**. Resolve it the same way, no re-investigation needed; the
window fully ages the job out by the 2026-07-18 run.

**No permanent exception added — deliberately.** Unlike §21's `decision_log.sub_pattern` case (an
*ongoing* sanctioned in-place-edit pattern, allowlisted in the tripwire itself), this was a **one-time,
now-complete migration event**: going forward `ticker` is only ever set via `INSERT` on new rows, so
the tripwire will not see this table again absent a genuinely new out-of-band mutation. Adding a
permanent suppression for a single closed-out backfill would blind the tripwire to a real future
violation on this same table for zero ongoing benefit.

**Aside — confirms a known residual owner action, not a new gap.** `ops.monitor_health_history` has
zero historical rows for `check_id='append_only_integrity'` (only `ddl_drift`/`restore_stale` are
present). This matches OWNER_ACTIONS.md item B (2026-07-15 pass): `integrity_check` is one of the 11
scheduled queries whose updated body (the monitor-health-history `MERGE`, self-improvement audit ITEM
31) hasn't been re-pasted into the live BigQuery Studio scheduled query yet — so the 14-consecutive-
clean-day promotion-readiness counter for this check isn't accumulating. No action taken here beyond
noting it; item B already tracks the fix (re-paste the 11 bodies) and today's alert fired correctly
off the currently-live (pre-ITEM-31) query body regardless.

## 45. Order-guard evolution — market-only cutover, then full pre-trade-rail strip; partial-sell support — 2026-07-21..22 *(design, owner directive)*

**Why this section exists.** §42 (2026-07-15) is the last place this runbook described
`analytics.fn_order_guard`, and it describes a guard that no longer exists: a `p_is_park` parameter
(renamed from `p_is_sgov`) plus a per-vehicle price band read from `state.park_policy_current`. That
paragraph is a correct **dated record of the 2026-07-15 vehicle cutover** and is deliberately left
intact — but the guard has since changed twice, and a reader who stops at §42 would wrongly believe the
price band and `p_is_park` are still live. This section carries the guard forward to its current state.
The canonical spec is now `bigquery/104_strip_pretrade_rails.sql` plus the order-craft sections of
`Claude_Task_Plan.md` (§"Crafting an order", D2/D2a/D3) and `Operating_Protocols.md` (§11/§13) — **not** §42.

**2026-07-21 — market-only cutover (`bigquery/100_market_only_order_guard.sql` / `101`, owner directive).**
Every IBKR order the system crafts became a MARKET order (`order_type='MARKET'`, TIF `DAY`) — entries,
exits, park sweeps/covers, options alike. This retired limit orders entirely: the marketable-limit
convention, the persist-and-wait resting-limit model, the 2026-07-20 LIMIT DECISION
(RAISE/HOLD/LOWER/ABANDON) framework, and the >0.5%-off-last equity price band (§42's per-vehicle band
included). In their place liquidity became a HARD pre-craft gate: an expected-implementation-shortfall
model (Almgren-Thum-Hauptmann-Li 2005: half-spread + 0.142·σ·participation^0.6) vs a per-strategy
holding-horizon budget (D 150 / A 100 / C 25 / else 50 bps), a $1M minimum-ADV floor, and a 10% ADV
participation cap. `fn_order_guard`/`fn_order_guard_options` gained ADV/spread/σ (equity) and
open-interest/spread (options) parameters; `p_is_park` still selected a liquidity exemption + the
1.10×-NAV magnitude backstop for park orders. (A follow-up the next morning,
`bigquery/103_adaptive_shortfall_budget.sql`, briefly made that horizon budget a self-activating φ·α
edge-relative number via `analytics.calibration_return_shrunk` — superseded within the day, below.)

**2026-07-22 — all pre-trade rails stripped except market-only (`bigquery/104_strip_pretrade_rails.sql`,
owner directive; the CURRENT state).** In one interactive session the owner directed "strip everything
except market orders only": full freedom to market-buy/-sell on thesis and market conditions
**regardless of current price and slippage**. `fn_order_guard` collapses to a 5-arg signature
`(p_strategy, p_side, p_qty, p_ref_price, p_order_type)` whose only rail is `order_type IN ('MARKET','MKT')`
plus malformed-input sanity (`qty>0`, `ref_price>0`). Removed: the entire expected-shortfall gate + its
φ·α adaptive budget (`analytics.calibration_return_shrunk` **dropped**), the $1M ADV floor, the 10%
participation cap, **and** the fat-finger sizing rails that predated even the shortfall gate — the 1.5×
`sizing_base_2pct` notional cap, the $50 absolute-notional backstop, and the park 1.10×-NAV magnitude
backstop. `p_is_park` is gone from the signature entirely: park and non-park orders are now checked
identically. `fn_order_guard_options` drops to 6 args and keeps exactly ONE rail beyond market-only +
sanity — a **defined, positive `max_loss`** (unbounded-loss prevention; explicitly retained by owner
directive as a risk class distinct from liquidity/sizing). **The owner's per-order IBKR confirm-tap is now
the sole discretionary backstop.** `ops.sp_fire_drill_order_guard` was rewritten to 10 cases (down from
14), two of which prove the strip — a $5M-notional equity order and a $500k-defined-`max_loss` options
order that the pre-strip guard rejected must now PASS. The superseded-marker chain
(`bigquery/23/54/99/100/103`) was repointed to 104; `ops.sp_sq_daily_staging_cap_check` (`bigquery/75`)
recompute was updated to the 5-arg guard; the dead adaptive-budget dbt model/test/schema were deleted.
**Applied live via the BigQuery MCP and verified 2026-07-22:** 10/10 fire-drill cases correct,
`calibration_return_shrunk` confirmed dropped, `ops.run_log` FIRE_DRILL_ORDER_GUARD = `completed`.

**2026-07-22 — partial-sell (trim / scale-out) support (same session, owner directive).** The AI may now
sell PART of an open position — a MARKET sell for fewer shares than held — in addition to the pre-existing
full-exit and add-to-position operations. The fills-derived FIFO-lot + campaign accounting
(`bigquery/102_pyramid_aware_lifecycle.sql`) already resolved partial exits correctly, so **no
accounting-engine change was needed**; the new work is in the event-sourcing layer + prose. A partial-sell
fill that does NOT zero the `(strategy,ticker)` position is reconciled (D2a Step 0) FIFO across the
position's open tranches: a CLOSE `events.position_events` row for each fully-consumed tranche, and for the
boundary tranche an **`event_type='ADJUST'`** row with **`status='OPEN'`** (the exact literal —
`analytics.strategy_nav` / `state.daily_briefing` / `weekly_report` filter on it), reduced `shares`, and
proportionally-reduced `cost_basis`; `state.current_positions` (latest non-CLOSE row per `position_key`)
then shows the trimmed position automatically. The `ORDER_STAGED` payload gained `sell_type:
'FULL'|'PARTIAL'`, and fill matching prefers `payload.instruction_id` (+ a qty-consistency check) so two
concurrent SELL rows on one ticker aren't conflated. Per-strategy trim rules are in `Strategy.md` (Rev 41):
A/B/D long trims (B short partial-cover), C partial-contract scale-out, E both pair legs together in the
same session (never a naked leg); all five `spec_hash`es were recomputed.

## 46. Catch-up evidence windows — every routine covers back to its own last completion (owner directive 2026-07-25)

**Why this section exists.** The 2026-07-23/24 BigQuery-connector outage (in the lineage of §26's
2026-06-26 incident) showed a gap that every prior fix in this runbook had left open: each routine's
evidence-gathering step only ever looked at "today," "this week," or some other FIXED lookback window
hand-anchored to its own cadence. When a routine was itself down (or its upstream feed was) for longer
than that fixed window, the missed day(s) were never covered by any later run — the routine simply
resumed reading from wherever its normal window happened to start, and evidence from the outage window
was silently lost forever. This is a distinct failure class from a missed TRIGGER (which `catchup_safe` +
OPS0 already refire) and from a stale ALERT (which auto-resolves) — a routine can run exactly on schedule,
every trigger firing normally, and still never look far enough back to see what it missed while it (or a
dependency) was down.

**The aging-alert trap that made the gap invisible.** `ops.sp_auto_resolve_alerts` Rule 2
(`bigquery/34_alert_lifecycle.sql`) clears a `missed_run` alert once the alerted day is more than 1 day
stale — on EITHER a later completion OR simply the alert aging out, whichever comes first, with **zero**
requirement that any completion evidence exists. That means a cleared `missed_run` alert was never
proof the missed day's evidence was actually analyzed by anything; the alert lifecycle and the evidence
lifecycle were two unrelated clocks that happened to look like the same signal. This is the concrete
mechanism verified during recon for this redesign, and it is why "the alert is clear" cannot be trusted
as a stand-in for "the routine covered that day."

**`state.routine_catchup_window` (`bigquery/105_routine_catchup_window.sql`) — the mechanism.** One row
per routine (all 31 ids in `ops/cadence.yaml`, including the 4 `queue_driven` ones — no existing view
carried that full set), generated via a new `scripts/gen_routine_lists.py` marker region (its 4th, joining
the existing bigquery/12/15/24 regions) so the roster can never hand-drift from `ops/cadence.yaml`. For
each routine: `window_start_ts` = the timestamp of that routine's own last `completed` `ops.run_log` row,
or — if it has never completed — a cadence-sized fallback keyed to its monitor class (daily/queue_driven 1
day, weekly 7, monthly 31, quarterly 92, annual 366). `window_days` reports the elapsed size for quick
reading. Routine ids are normalized the same way `state.instruction_drift` already does (§28,
`REGEXP_REPLACE(routine, r'[·._-]', '')`) so legacy middle-dot `AR·att`/`AR·orc` rows fold onto the
current keys instead of being dropped from the `MAX(log_ts)`. The `routines` CTE is the closed, generated
list — never `SELECT DISTINCT routine FROM ops.run_log` — specifically so fire-drill/self-heal synthetic
markers (`FIRE_DRILL_ORDER_GUARD`, `SELFHEAL_RUN_LOG`, etc.) never surface as phantom routines with their
own meaningless windows. As part of the same file, `state.go_without_order` (D3's staging-completeness
surface, §25, originally defined in `bigquery/18_stack_review_fixes.sql`) is redefined with its lookback
now `GREATEST(2 days, days since D3's own last completed run)` — floored at the original fixed ~36h/2-day
cutoff so it never narrows, widening automatically across a D3 outage. bigquery/18's original copy is kept
in place, unmodified, as the DR-rebuild apply-in-order record, with an explicit SUPERSEDED marker pointing
forward to bigquery/105 (verified clean by `scripts/check_superseded_markers.py`) and a caution against
re-applying it live in isolation.

**The preamble protocol (`Claude_Task_Plan.md`, Observability section, the CATCH-UP EVIDENCE WINDOW
bullet, immediately after Run logging).** States the principle once — this run's evidence reach is
*(this routine's own last successful completion, now]*, not a fixed lookback — and is the single place
every routine-specific edit points back to rather than restating the mechanism. Read
`state.routine_catchup_window` for the routine's own id; fold `window_start_ts` into whatever the routine
already reads for evidence (a Daily.md scan range, a `decision_log` lookback, a git-log-since bound, a
missed-trading-day marks backfill) as a widen-only floor — it can push a lookback further back than its
normal cadence would, never pull it in tighter. Explicitly generalizes, rather than replaces, the
reference implementations that had already independently solved pieces of this same problem: D1's SCAN
WINDOW (marker + git-commit-timestamp + fixed-lookback fallback), D3's golden-scenario
`git log --since=<D3's own last completed run>` check, W5's "since the last W5 run" bullets, and the
queue-drain routines SL2/SL5/SL1/AR_att/AR_orc. **BEST-EFFORT / NON-GATING**, mirroring the OPS0 "must
NEVER be blocked" rule and the existing Alert auto-resolve bullet's posture: if
`state.routine_catchup_window` is unreadable (BigQuery hiccup, view missing) or the query errors, the
routine falls back to its own existing cadence-default lookback, proceeds, and notes the fallback (e.g.
`catchup view unreadable, used cadence-default lookback`) — it must never halt or degrade a run on this
view's absence. The bullet also explicitly disambiguates two similarly-named windows so future edits don't
conflate them: the pre-existing DEPENDENCY-WAIT WINDOW (waiting on an upstream routine before running at
all) is unrelated to this CATCH-UP EVIDENCE WINDOW (this routine widening how far back its OWN evidence
reads once it does run); and `catchup_safe` (`ops/cadence.yaml`) — whether OPS0 may auto-refire a missed
TRIGGER — is a live-ops scheduling concept, not an evidence-reach one; a routine can be `catchup_safe:
false` and still fully benefit from this bullet.

**The 12 routine-specific edits.** Each points back at the universal bullet rather than re-deriving the
mechanism: **D2** gained a CATCH-UP CHECK paragraph (immediately after the same-day idempotency guard,
before run logging) that git-diffs `Daily.md` since D2's own last completion and unions any un-converted
RECOMMENDED ACTIONS bullets from intervening D1 saves into Step 1, skipping anything already reflected in
`decision_log`/`queue_events`/`open_orders`. **D2a** widened the fills-reconciliation window to
`GREATEST(7 days, days since D2a's own last completion)` in both the canonical STEP 0 copy and the
non-canonical connector-usage-preamble summary (kept in sync per that section's own header), widened the
daily-marks ingest to backfill every missed trading day (idempotent on `(mark_date, ticker)`, feeding SL3's
own catch-up loop), and added a stale-baseline-awareness clause to the connector-sanity ΔNAV band so a
multi-day gap's mechanical mark-to-market sum — not a same-day delta — is what gets judged against the
±15% threshold. **D3** widened `state.go_without_order`'s window as described above and requires a durable
`sp_log_decision` adjudication row for every surfaced candidate regardless of verdict. **SL3** added a
catch-up loop that runs the SHADOW/PAPER signal/simulated-fill steps against EVERY missed trading day
between SL3's own last completion and today (oldest first), each day keyed off `state.daily_marks_curated`
— dependent on D2a's own marks backfill above. **OPS1** got a naming-clarification only: its
3-consecutive-completed-runs recurrence streak is explicitly NOT widened by this protocol (a gap where
OPS1 itself did not run neither breaks nor pads the streak) — called out so a future edit doesn't
misapply evidence-window widening to a streak-counting rule. **W2** no longer widens or owns a retrospective
post-event significance screen: it enriches D1-recorded candidates since W2's completion watermark, while
D1's daily dynamic scan owns coverage of missed trading days. Strategy B's frozen 10-trading-day entry window
is untouched. **W3** and
**M3** each now cover the full span back through every missed weekly/monthly cycle, oldest first, stating
the actual span covered (e.g. "covering 2026-W25–W27") instead of silently treating only the
immediately-prior period. **M1a** and **Q3** cover each missed month/quarter as its own labeled
sub-section, oldest first, in addition to the immediately-prior period; **Q1** and **Q3** additionally
carry an explicit WRITE-ONCE rule (a 2+-quarter catch-up session writes each distinct
`state.strategy_candidates` finding / verification answer once, not once per covered quarter, so it can't
inflate SL1's candidate feed or falsely satisfy SL4's multi-cycle corroboration test). **A1** widens its
full-re-derivation scope to the longer of last-24-months or the full span since A1's own last completion
(same in the ordinary case, since A1 is annual; only actually widens if A1 has been down more than ~2
years).

**Decision-scoping rule (unchanged, restated everywhere this protocol touches).** Only the EVIDENCE window
widens. Every decision a routine makes while covering a catch-up span is still taken, staged, and dated as
of the CURRENT session — nobody retroactively places, backdates, or alters an order for a missed day. D3's
go-without-order re-staging, D2a's fills/marks backfill, and SL3's per-day simulated-fill catch-up loop all
write records dated to the historical day they reconstruct (a fill happened when it happened, a mark is
for the day it prices), but that is data reconstruction from real, already-occurred broker/market events —
not a new trading decision being backdated. The Decision discipline section (trigger + conservative
default; deferrals do not chain) is unchanged.

**What was deliberately NOT changed.** `ops/cadence.yaml`'s `catchup_safe` list and the OPS0 auto-refire
machinery it drives are untouched and remain conceptually distinct (see the preamble bullet's explicit
disambiguation) — this protocol governs how far back a routine's evidence reaches once it runs, never
whether OPS0 may fire a missed trigger for it. Blinding is unchanged: AR_att's strict blinding and M1a's
file-boundary blinding govern WHICH sources a routine may read and are untouched by a protocol that only
ever widens WHEN (in time) a routine reads from sources it was already allowed to read. File-write markers
stay CURRENT-period — W4/M4/Q4/A3's freshness checks still parse a first-line marker for the immediately-
current week/month/quarter/year; missed periods are folded in as labeled sub-sections in the body (oldest
first), not by back-dating the marker itself. Write-once discipline reuses each routine's existing
idempotency keys (`trade_id`, `(mark_date, ticker)`, `entry_id`, etc.) so covering multiple periods in one
session produces one BigQuery write per distinct finding, not a duplicate per period. No cap was added on
`window_days` — a routine broken for months would get an arbitrarily large window; a safety valve (e.g.
capping at some multiple of the routine's own cadence default) was explicitly left as a future design call
for whoever wires a given routine's evidence-gathering step against this view, not assumed here.

## 47. `position_drift` halting trading on a staged-but-unfilled BUY — pending-order-aware reconciliation and the trading-enable gate rework — the 2026-07-26 `D:GOOGL` halt *(monitoring, new incident class)*

**Fired 2026-07-26, D2's evening run (17:17-17:22 MT)** (`alert 7ef50e04` /
`INCIDENT[ref=423ecc02-fdb7-4f47-9445-d8c79d399e8c]`): `state.position_reconciliation drift detected`.
Unlike §29's SGOV phantom lot, this was a REAL, correctly-detected structural gap — the fix here is not
"the drift was spurious," it is "the drift was expected and transient, and the gate treated it as fatal."

**Root cause — two representations of an open position are written at different points in an order's
life, and the old predicate didn't know that.** `state.current_positions` (`bigquery/01_schema.sql:129-133`,
latest-wins over `events.position_events` `WHERE event_type <> 'CLOSE'`) gets its OPEN row at
**ORDER-STAGING TIME** — D2 writes it on a GO, before the order even reaches the broker
(`Claude_Task_Plan.md` items 2 and 2a — the staging-time provisional OPEN, written co-located with the
`ORDER_STAGED` row after the pre-craft gates pass; that write ORDERING was hardened 2026-07-27, see the FIX below). `analytics.position_lifecycle`
(`bigquery/102_pyramid_aware_lifecycle.sql`) is FIFO lots derived purely from
`state.trade_fills_curated` — it only ever sees shares that ACTUALLY FILLED. So from the moment a BUY is
staged until its fill reconciles, `current_positions` legitimately LEADS `position_lifecycle` by exactly
the working order's quantity — an expected, transient, fully-explained gap. The old predicate,
`ABS(share_diff) > 0.01` (`bigquery/18_stack_review_fixes.sql:130-153`, now carrying an explicit
SUPERSEDED marker at that CREATE), was a flat share tolerance with no order awareness, so it read that
gap as indistinguishable from the phantom-open-position bug it was built to catch. Trigger: one pending
order — D:GOOGL add-tranche BUY 0.1534 sh, IBKR #84254447, owner-CONFIRMED, status NEW, staged 2026-07-26
00:49:46 MT — produced `current_positions` 0.2577 vs `position_lifecycle` 0.1043, `share_diff` 0.1534,
~15x the 0.01-share tolerance.

**Why it mattered — `drifted` is a BLOCKING term, not advisory, and has been since 2026-07-03.**
`drifted` is `LOGICAL_OR`'d account-wide into `state.system_health.all_green`
(`bigquery/23_trading_control.sql:428,431`, self-improvement audit B-5-exec/B-6-data) and from there
directly into `state.trading_enabled`'s `AND NOT pr.drift` term
(`bigquery/107_halt_echo_missed_run_gate.sql:173,181`) and `state.trading_enabled_mechanical`'s
equivalent. `ops.sp_assert_trading_enabled[_mechanical]` (`bigquery/85_gate_selfheal_repo_catchup.sql`)
then RAISEs on a FALSE gate, aborting the calling routine's session outright — not a warning anyone could
triage at leisure.

**Blast radius — the SECOND consecutive blocked D2 evening, but NOT the same cause, and the cost was
date-dependent.** The 2026-07-26 halt left `rows_written = 0` and 6 due `PENDING_ANALYSIS` theses
undrained (ALL `due_date` 2026-07-26; two with entry windows closing 2026-07-28,
`Claude_Task_Plan.md:1085`). The 2026-07-25 evening run was ALSO blocked, but by four unrelated,
since-resolved open criticals (`missed_run`, two `missing_dependency`, `automation_heartbeat`) — the
GOOGL order did not even exist yet at that halt; it was staged the following morning, 00:49:46 MT. The
07-25 abort cost NO queue drainage, because none of those 6 items was yet due or even enqueued a day
earlier — write it as two separate incidents, not "halted on two consecutive evenings" as if one cause.
The general lesson: **this exact defect is cheap on a day the due-queue happens to be empty and expensive
on a day it isn't, and nothing about the halt itself — same alert, same category, same RAISE — tells you
which kind of day you're looking at.** A gate that fails the same way regardless of what it's about to
discard is a gate whose blast radius you can't read off the alert; that gap, not the drift detection
itself, is the actual defect this incident exposes.

**Why it could not self-clear.** Only a fill lands in `events.trade_fills` → `analytics.position_lifecycle`
via D2a Step 0 can close the gap — nothing else writes to the fills-derived side. 2026-07-26 was a Sunday,
so no fill was possible; the condition was structurally guaranteed to persist through the entire
non-trading weekend.

**Latent self-latching hazard — averted, not an outage.** The only writer that can clear the drift is
D2a's own STEP 0 broker reconciliation (`Claude_Task_Plan.md:658`), and D2a's own
`ops.sp_assert_trading_enabled_mechanical('D2a')` gate (`Claude_Task_Plan.md:656`) reads that SAME drift
term. A strict reading of the OLD D2a gate prose — "FATAL ... before anything else," contradicted several
sentences later by "Reads/reconciliation are safe regardless" — would abort D2a BEFORE Step 0 ever ran,
so the one fill that would clear the drift would never be reconciled and the halt would never lift: a
control that disables the only mechanism able to satisfy it. **In practice this did NOT happen.**
`ops.run_log` shows D2a COMPLETED on both 2026-07-25 (53 rows written, backfilling the outage-missed
07-23/07-24 marks) and 2026-07-26 (0 rows — non-trading Sunday, nothing to reconcile) with the gate
reading FALSE both days; D2a never logged `halted` (`Claude_Task_Plan.md:658`, "sessions have in fact
been resolving it correctly ... but 'the last N sessions guessed right' is not a control"). Record this
accurately: a latent hazard that was averted by correct per-session judgment calls, not an outage that
actually occurred.

**The alert-text-vs-actual-behavior mismatch.** The gate's alert message is the fixed string
`'Order staging blocked: trading is HALTED. See payload for the triggering routine and reason.'`
(`bigquery/85_gate_selfheal_repo_catchup.sql:73,106`, kept stable deliberately so
`sp_raise_alert_once`'s exact-match dedup doesn't fragment into one alert per routine per day) — but the
`RAISE USING MESSAGE` that immediately followed it (`bigquery/85_gate_selfheal_repo_catchup.sql:75-76,110-111`)
aborted the ENTIRE calling routine, uncaught, not merely "order staging." The alert said one thing; the
control flow did another, larger thing.

**Fix — two parts, both 2026-07-27, `INCIDENT[ref=423ecc02-fdb7-4f47-9445-d8c79d399e8c]`.**
1. **Data side — `bigquery/110_pending_order_aware_reconciliation.sql`**, the new single source of truth
   for `state.position_reconciliation` (supersedes ONLY that one view from
   `bigquery/18_stack_review_fixes.sql`; the ~10 other objects that file defines are untouched and still
   canonical there). New predicate: `residual_share_diff = IF(share_diff > 0, GREATEST(share_diff -
   pending_buy_shares, 0), share_diff)`, `drifted = ABS(residual_share_diff) > 0.01`, where
   `pending_buy_shares` sums a (strategy,ticker)'s still-working BUY quantity from `state.open_orders`
   (`side='BUY' AND qty>0`, staleness-bounded — either still inside its own entry window or (re-)staged
   within the last 7 days, `bigquery/110:83-90`). `drifted_raw` keeps the old flat predicate verbatim, for
   audit. `explained_by_pending_buy` is TRUE exactly when `drifted_raw` fired and `drifted` did not — a
   benign staged-but-unfilled BUY lag, never a book discrepancy (`bigquery/110:180-190`).
2. **Routine side — `Claude_Task_Plan.md`.** The TRADING-ENABLE GATE paragraphs for D2 (`:1081`), D2a
   (`:656`), W4 (`:1435`), M4 (`:1777`), Q4 (`:2199`), and A3 (`:2377`) were rewritten from "FATAL, aborts
   the routine" to "read the gate NON-FATALLY here, carry the verdict forward, and enforce it at every
   order-craft point" — so a halt now costs exactly the orders it should block, and nothing else: research
   reads, `PENDING_ANALYSIS`/`PENDING_REVIEW` enqueues, Watchlist.md updates, and run logging all proceed
   regardless of the gate. D3 was GIVEN a trading-enable gate for the first time (`:1213`) — it had always
   crafted orders (`create_order_instruction` + `ORDER_STAGED` writes) with no gate of its own; its
   protection against staging during a halt was a pure SIDE EFFECT of D2's old FATAL abort making D2 never
   log `completed`, which then FATAL-failed D3's `sp_assert_deps('D3', ['D2'])` dependency gate
   (`Claude_Task_Plan.md:1215`) — "protection that only works because an unrelated upstream crashed is not
   protection; it is a coincidence that was load-bearing." Once D2 correctly completes through a halt
   instead of aborting, that accidental protection disappears, so D3 needed the real thing.

**Why suppress-only is safe to consult from inside a load-bearing gate.** Four deliberate properties
(`bigquery/110:62-81`): **(1) SUPPRESS-ONLY, never additive** — the `GREATEST(...,0)` floor plus the
`share_diff > 0` guard make `|residual_share_diff| <= |share_diff|` identically, so a bug in the pending
term can only degrade to the OLD behavior, never manufacture a spurious halt. **(2) BOUNDED masking** —
only the pending quantity is netted, not the whole row; a genuine 5-share phantom behind a 0.15-share
working BUY still trips the gate. **(3) PARTIAL-FILL TOLERANT** — the bound is `<=` the pending quantity,
so a fractional MARKET fill drives the residual negative (clamped to 0) instead of flipping the row back
to drifted mid-fill. **(4) BUY-SIDE ONLY, by construction** — a staged EXIT writes only an annotation to
`events.position_events`; `event_type='CLOSE'` (the only thing `state.current_positions` filters on) is
written by D2a Step 0 at FILL time, never at staging, so a pending SELL structurally cannot depress
`current_positions` ahead of lifecycle and needs no netting term.

**Verified live (read-only), post-fix.** The new predicate returns `drifted=FALSE` for all 12
(strategy,ticker) rows, with an IDENTICAL row set and IDENTICAL raw `share_diff` values vs. the live
(pre-fix) view — only D:GOOGL's `drifted` flag changes (`drifted_raw` stays TRUE, `explained_by_pending_buy`
TRUE).

**What to check if `position_drift` fires again — READ BEFORE ESCALATING.** `SELECT * FROM
state.position_reconciliation WHERE drifted` and inspect `explained_by_pending_buy` and
`pending_buy_item_keys` on the drifted row(s) (`bigquery/110:172-190`). `explained_by_pending_buy = TRUE`
means a benign staged-but-unfilled BUY on one of the `pending_buy_item_keys` — not a book discrepancy;
the halt clears itself once that order fills or its staleness window lapses, same as this incident.
`explained_by_pending_buy = FALSE` on a drifted row means the residual survived netting — a genuine
break, escalate as before this fix would have required.

**Known remaining gap — CLOSED 2026-07-27 (pre-existing, NOT introduced by this change, never fired — live check found
only `filled` and `pending` `ORDER_STAGED` rows).** A staged BUY that EXPIRES (`Claude_Task_Plan.md:826`,
window closed unfilled → set terminal `expired`) or is ABANDONED (`:818`, the ENTER/EXIT-vs-ABANDON
judgment sets the row terminal instead of re-crafting) unfilled leaves its staging-time OPEN
`events.position_events` row sitting in `state.current_positions` FOREVER — latest-wins,
`event_type <> 'CLOSE'` (`bigquery/01_schema.sql:129-133`) — while the `ORDER_STAGED` row simply drops out
of `state.open_orders` once terminal (`state.open_orders` is pending-only,
`bigquery/01_schema.sql:242`). Nothing nets the phantom OPEN row back out: it becomes a permanent genuine
drift and a permanent halt. `bigquery/110` is arithmetically neutral for this specific case —
`pending_buy_shares` collapses to 0 once the order goes terminal, so `residual_share_diff` collapses to
the raw `share_diff`, exactly the pre-fix behavior. Neither D2a's expire branch (`:826`) nor its abandon
branch (`:818`) writes anything beyond `CALL ops.sp_log_decision(...)` — no compensating CLOSE
`events.position_events` row.

**FIX (2026-07-27, `INCIDENT[ref=423ecc02-fdb7-4f47-9445-d8c79d399e8c]`, this session).** D2a's registry-reconciliation
branches themselves now write the compensating CLOSE — the **PHANTOM-CLOSE RULE** appended to
`Claude_Task_Plan.md`'s `ORDER_STAGED` bullet (branches (b)-ABANDON at `:818` and (c)-EXPIRE at `:826`). Chosen
over a separate sweep deliberately: at the moment D2a flips a BUY row terminal it already holds everything needed
to net the provisional out deterministically — the order's `payload.position_key` (`K`) — so it writes
`INSERT INTO events.position_events (position_key=K, event_type='CLOSE', status='CLOSED', event_ts=CURRENT_TIMESTAMP(),
…strategy/ticker/contract_id/shares/cost_basis carried verbatim from the phantom OPEN)` iff `K` is non-null AND still
a live non-CLOSE row in `state.current_positions`. By design (`bigquery/110`'s header + `Claude_Task_Plan.md` items 2 and 2a) BOTH a first entry AND a
pyramid `add-tranche` pre-write a staging-time provisional OPEN — but ONLY at their `ORDER_STAGED`-write step, co-located
with the `ORDER_STAGED` row and AFTER all four pre-craft gates pass (the ordering was hardened this session, `INCIDENT`
above, self-audit finding: writing the OPEN before the gates would strand a phantom with no `ORDER_STAGED` row for
PHANTOM-CLOSE to reach, on any gate-declined GO). Both kinds record their `position_key` verbatim in the `ORDER_STAGED`
payload, so PHANTOM-CLOSE (keyed on `payload.position_key`) covers BOTH. The 2026-07-27 live check happened to find
staged provisional OPENs only for `add-tranche` (e.g. `D:GOOGL:2026-07-26`) — not because first entries never pre-write,
but because the only BUY staged-but-still-unfilled at that instant happened to be the `D:GOOGL` add (a MARKET order
staged 00:49 MT on a Sunday, still `NEW`/unfilled with the market closed — so a provisional OPEN is NOT short-lived
whenever an order is staged while the market is shut; a first entry caught the same way would show one identically); a
`park-switch` leg carries the same payload convention but never reaches
`events.position_events` (park routes to `events.parking_events`), so it is out of scope with `K` null. The companion **STAGING-OPEN KEY INVARIANT** (`Claude_Task_Plan.md` items 2 / 2a + Step 0
fill reconciliation) makes it forward-safe: any order that pre-writes a provisional OPEN records its key in
`payload.position_key` and reuses that SAME key at fill (Step 0's fill OPEN SUPERSEDES the provisional) and at
PHANTOM-CLOSE — so a fill never strands the provisional either. SUPPRESS-ONLY-safe by construction: reaching the
abandon/expire branch means the order NEVER filled (a fill, even partial, is caught by branch (a) and routed to fill
reconciliation, never here), so the CLOSE removes only genuinely-unbacked shares; a belt-and-suspenders guard refuses
(and raises a `phantom_close_skipped` warning) any CLOSE that would make `state.current_positions` UNDER-count
`analytics.position_lifecycle`. If a phantom ever slips through anyway, `state.position_reconciliation` still halts
fail-closed with `explained_by_pending_buy=FALSE` — the correct response to a genuinely unexplained drift — so this
fix removes the FALSE permanent halt without weakening detection of a real one. Neither a new scheduled object nor a
BigQuery write from CI is involved; the CLOSE is written in-band by D2a exactly as its existing fill-time CLOSE rows are.

## 48. The entire Sunday slot fails to fire, and a halt-record commit is auto-backfilled as `completed` — the 2026-08-16 D1/D2a no-fire *(monitoring, new incident class)*

**Observed 2026-08-16 (Sun), D2's evening run (17:27-18:2x MT)**, alert `6473abc3`
(`missing_dependency`, critical) plus alert `run_log_backfill_masked_halt` (warning). Two
independent defects surfaced in one run; the second is the durable one and is a NEW incident class.

### Part A — the no-fire (operational, self-recovering)

D2 fired on schedule (23:15 UTC / 17:15 MT) and found **neither of its declared upstreams had produced
any `ops.run_log` row at all** for 2026-08-16 — not `completed`, not even `started`. D1's slot
(22:00 UTC / 16:00 MT) had passed by 89 min and D2a's (22:40 UTC / 16:40 MT) by 49 min. Nothing was
committed to `origin/main` by either, so the §38 marker backfill had nothing to self-heal from and the
git-evidence fallback (`git log origin/main --since=<today 00:00 MT> -- Daily.md`) came back empty. The
gate was therefore genuinely correct to abort.

This was not isolated. Of the 13 routines `state.cadence_expected_today` expected on 2026-08-16, only
**OPS1** and **W5** produced any evidence, and both of those ran inside the morning BigQuery
connector de-authorization (§26 recurrence) and so landed commits without run-log rows. **W2** logged
`started` at 12:04 MT — proving the BigQuery grant was already restored by midday — and never wrote a
terminal row. W1, W3, W4, D1, D2a, D3, OPS0, OPS2 and SL3 left no trace whatsoever. The immediately
preceding Sunday (2026-08-09) saw all of D1/D2a/D2/D3/OPS0/OPS1/SL3 complete normally, so the
Sun-Thu cadence itself (`ops/cadence.yaml`, 2026-08-08 consolidation) is not implicated; this looks
like a platform-side trigger-delivery failure confined to 2026-08-16.

**Why D2 could not repair it.** The DEPENDENCY-WAIT WINDOW's ACTIVE REPAIR branch was unavailable on
both deps, for two separate reasons, and this is the part worth remembering:
- **D2a is in the OPS0 scope-guardrail exclusion set** (D2, D2a, W4, M4, Q4, A3, SL4), so it is
  `REFIREABLE = false` by rule. Neither a blocked downstream *nor OPS0's own 22:30 MT sweep* can
  recover a missed D2a. Its only recovery is its next scheduled slot — or a human.
- **D1 is nominally refireable** (`catchup_safe: true`, `trigger_id` present, not excluded, no
  `ops.catchup_refire_log` row for `D1|2026-08-16`) but **the routine session had no `RemoteTrigger`
  tool exposed at all**, so the refire was not executable. A session that cannot see `RemoteTrigger`
  should record that fact rather than reporting the upstream as un-refireable on policy grounds.

Because D2a can never be auto-refired, an OPS0 sweep that recovers D1 still leaves D2 blocked. The
Friday 2026-08-14 marks/fills gap therefore persisted until D2a's next Monday slot — with
`state.freshness` reading `last_mark_date = engine_through = 2026-08-13` against
`last_trading_day = 2026-08-14`, and `state.trading_enabled = FALSE` on
`marks_fresh/engine_fresh not both TRUE` as the correct downstream consequence.

**Blast radius was nil by luck, not by design:** the earliest due `PENDING_ANALYSIS` item was
2026-08-27, no exits or entries were pending, and `Daily.md` was still 2026-08-13's already-converted
file. D2's halt cost nothing. On a day carrying a due thesis or a triggered exit it would have.

### Part B — a halt-record commit auto-backfilled as `completed` (NEW incident class)

**The mechanism.** `ops.sp_assert_deps` calls `ops.sp_backfill_run_log_from_markers()` first and
unconditionally (§38 self-heal). D2's gate call at 17:27:14 MT ran it, and it inserted a
`status='completed'` row for **W5 / 2026-08-16** derived from commit `3bd39e1`, whose subject is
*"W5 2026-08-16: HALT at pre-flight — BigQuery connector de-authorized"*. W5 had deliberately written
no run-log row precisely so that its watermark would not advance; the backfill advanced it anyway.

Every link in the chain is halt-blind:
- `scripts/auto_merge_decision.sh` `marker_routine_from_subject()` matches only the leading token
  against `^(D1|D2a|D2|D3|OPS0|OPS1|OPS2|W[1-5]|M1a|M1b|M[2-5]|Q[1-4]|A[1-3]|SL[1-5]|AR_att|AR_orc)$`.
  The word "HALT" later in the subject is invisible to it.
- `bigquery/38_run_log_selfheal.sql` hardcodes the literal `'completed'` in its INSERT and never
  inspects the marker; its NOT-EXISTS guard checks only for an existing `completed` row, so an
  existing `halted`/`failed` terminal row would not have suppressed it either.
- `bigquery/172_run_log_unpaired_terminal.sql` deliberately **excludes** `^(auto-)?backfilled` rows,
  so the anomaly detector that would otherwise notice a terminal row with no `started` row is
  designed to skip exactly these.

**Consequence.** `state.routine_catchup_window` derives `window_start_ts` from
`MAX(log_ts) FROM ops.run_log WHERE status='completed'` (`bigquery/105_routine_catchup_window.sql`),
with no genuineness filter. W5's window is now pinned to 2026-08-16 instead of its true last
completion, 2026-08-09. Left uncorrected, the 2026-08-23 W5 run will never re-scan
`events.decision_log` — or anything derived from it (B-sub-pattern extraction, Watchlist /
Operating_Protocols mirroring, vocabulary-drift watch, wash-sale review) — for the
2026-08-09 → 2026-08-16 span. Contrast the 2026-07-19 W5 halt, whose note correctly records
"watermark for the next W5 remains last completed 2026-07-12, so nothing is lost": that is the
intended behavior, and it held only because no halt-record commit was made that day.

**The general rule this exposes: a routine's durable halt record and its run-log completion marker are
the same signal to the marker parser.** The §38 self-heal's premise — "a landed commit means the
routine did its work" — is false for exactly one commit shape, and it is the shape the plan otherwise
encourages a halted routine to produce. Any routine that halts, follows the W5 precedent, and commits
a record whose subject leads with its own routine id will silently mark itself `completed` and advance
its own watermark.

### Resolution procedure

1. Correct the spurious row so W5's watermark falls back to 2026-08-09 (owner or a reviewed change —
   D2 deliberately did **not** mutate another routine's run history from its own session):
   ```sql
   UPDATE `stock-trading-498512.ops.run_log`
   SET status = 'halted',
       error_msg = 'BigQuery connector de-authorized at pre-flight',
       note = CONCAT(note, ' | CORRECTED 2026-08-__: backfilled as completed from a HALT-record commit; see RUNBOOK §48')
   WHERE routine = 'W5' AND run_date = DATE '2026-08-16' AND status = 'completed'
     AND note LIKE 'auto-backfilled from commit marker%';
   ```
   Then resolve the `run_log_backfill_masked_halt` warning. Must land before the 2026-08-23 W5 run.
2. `ops.alerts` `6473abc3` (`missing_dependency`) clears on its own via `ops.sp_auto_resolve_alerts()`
   once D1 and D2a complete.

### Prevention adopted

- **Immediate, no code change: a halt-record commit subject must NOT lead with the routine's own id.**
  D2's own 2026-08-16 halt record was committed under a subject beginning with an ordinary English word
  for exactly this reason, so the marker parser produced no marker and no backfill. This is the cheap
  half of the fix and it works today.
- **Recommended, not applied here (needs review — it touches the observability control plane):** make
  the chain halt-aware at its source. Either have `marker_routine_from_subject()` refuse a subject
  matching `HALT|HALTED|FAILED|ABORT` , or have `ops.sp_backfill_run_log_from_markers` write
  `'halted'` rather than `'completed'` when the marker's `commit_subject` carries such a token. The
  parser-side guard is the better of the two: it stops the bad marker being written at all, rather
  than correcting its interpretation afterwards.
- **`state.routine_catchup_window` should arguably not treat a backfilled row as a genuine completion
  for watermark purposes** — the rows are self-identifying (`note LIKE 'auto-backfilled%'`). Noted as
  an option, not a recommendation: the backfill exists precisely so a landed-but-unlogged run counts,
  and excluding those rows wholesale would undo §38's purpose. Only the halt-shaped subset is wrong.

## 49. `"Cadence scheduler absent >25h"` fires with a valid heartbeat sample already inside the window — the 2026-08-17 false alarm *(monitoring, false-alarm-shaped)*

**Symptom.** Cloud Monitoring policy *"Cadence scheduler absent >25h"* (condition *"No cadence-check
run in 25h"*) fired at **2026-08-18 01:22 UTC** on metric `logging.googleapis.com/user/cadence_scheduled_run`,
grouped on `__missing__` — the operator forwarded the alert email to an interactive session the same
evening ("investigate and fix if needed").

**It was a FALSE alarm — the dead-man's switch was healthy, and unlike the §19 precedent, a valid
heartbeat sample already existed well inside the 25h lookback window at evaluation time.** Verified
live:
- The `cadence-check-daily` scheduled query (config_id `6a44a3d9-0000-2837-8b7b-883d24f5c8b8`) ran and
  succeeded at **2026-08-17 05:15:07 UTC** (`region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`, `state=DONE`,
  no `error_result`) — only **~20h 7m** before the alert fired, not the ~25h an absence would require.
- Its heartbeat log line landed correctly at 05:17:30 UTC (`Summary: succeeded 1 jobs, failed 0 jobs.`),
  matching the live metric filter exactly:
  ```
  resource.type="bigquery_dts_config"
  resource.labels.config_id="6a44a3d9-0000-2837-8b7b-883d24f5c8b8"
  jsonPayload.message=~"^Summary: succeeded"
  ```
  (`gcloud logging metrics describe cadence_scheduled_run` — this is already the §19 terminal-agnostic
  fix, correctly configured; no metric drift here, unlike §19's cause.)
- Cloud Monitoring's own time-series API confirms a `DELTA` sample of value `1` recorded for exactly
  that run (`monitoring.googleapis.com/v3/.../timeSeries`, point `2026-08-17T05:17:28Z`–`05:18:28Z`).
- The alert policy itself matches spec: `absent_over_time(logging_googleapis_com:user_cadence_scheduled_run[25h])`,
  `duration=0s`, `evaluationInterval=30s`, unchanged since its 2026-06-21 creation (no recent
  metric/policy recreate that could explain a backfill gap).
- `state.system_health.all_green = TRUE`, `state.embedding_health.is_healthy = TRUE`, zero open
  criticals, all checked within the hour. No routine or trading impact of any kind.

**Root cause — likely a Cloud Monitoring evaluation-side quirk, not a scheduler or metric-filter
defect.** This is a genuinely different mechanism from §19 (which was caused by a success-only filter
missing an entire cutover window with zero samples). Here the filter is correct, terminal-agnostic, and
a real sample landed with ~5h of margin before the window would have legitimately gone empty — yet the
policy evaluated `absent_over_time` as true anyway. The most plausible explanation is a transient
ingestion/evaluation-side lag specific to log-based `DELTA` metrics under Cloud Monitoring's PromQL
backend; this was not fully root-caused at the GCP-internals level, since the observable evidence
(scheduler ran on time, metric has the correct sample) already fully classifies the incident as a false
alarm under this file's own §19 triage rule ("Runs present -> the metric drifted (fix the metric)... No
runs -> the scheduler is genuinely down") — runs were present AND the metric had the correct sample, so
neither branch applies and no infra change was made.

**Action taken: none to metric/policy/scheduler — all three verified correct.** No `terraform`/Console
change needed; `infra/terraform/monitoring.tf`'s `cadence` entry in `local.scheduler_absence_monitors`
already documents this alert as lower-severity than freshness/backup (`state.freshness` independently
catches data staleness). If this alert recurs with the same signature (a valid heartbeat sample already
inside the 25h window at fire time), re-run this file's verification steps first before assuming
scheduler death — do not skip straight to a Console/Terraform metric-filter change, since the 2026-08-17
instance proved the filter was never the problem.

**Lesson.** Not every recurrence of an `absent_over_time` alert is the §19 root cause (an
un-versioned, success-only, identity-cutover-sensitive filter). The class is now two distinct
mechanisms with the same symptom and the same triage starting point (check `JOBS_BY_PROJECT` for the
real run, check the log-metric filter, check the time-series API for the actual sample) — verify all
three independently rather than pattern-matching the symptom to the first documented cause.

## 50. Run-outcome notification — mechanical alerting for a failed/halted or a warned-completed run *(observability, owner directive 2026-09-08)*

**Why this section exists.** The owner asked, verbatim: *"for the remote routines, they have a
pathway to send me an email for any incomplete runs or even if run is complete but there are warnings
or errors? if not, we should add that feature rather than just having them paste those in chat (since
chat won't be read or monitored)."* A 34-agent audit measured the actual state before answering:
incomplete runs (`'failed'`/`'halted'`) were already 100% covered by email, but only BY CONSEQUENCE —
no mechanism cross-referenced a bad `ops.run_log` row against an alert, `ops.run_log.error_msg` had no
reader anywhere in the codebase, and a `'completed'` run carrying real problem language in its `<note>`
had NO channel at all (476 of 765 `'completed'` rows in a trailing-90d scan contained words like
error/failed/warning/skipped/stale/degraded with no alert ever raised). `bigquery/230_run_outcome_notification.sql`
closes both gaps mechanically. This section is the triage reference for what it added; the file's own
header carries the full measured audit and the design-constraint rationale and is not repeated here.

**The three new categories, all severity `'warning'` — never `'critical'` (an open critical feeds
`state.trading_enabled`'s `blocking_criticals` and halts order staging fleet-wide; a routine failing to
complete is not on its own a capital-safety event, so none of these three can ever contribute to a
trading halt):**

- **`routine_run_failed`** — a terminal `ops.run_log` row logged `'failed'` or `'halted'`. Raised
  MECHANICALLY, inside `ops.sp_log_run` itself, off the `in_status` argument every routine already
  passes — no routine has to remember to call anything for this one. Message carries
  `(routine, run_date, status)` plus a `<detail>` clause (the run's `error_msg`, falling back to
  `<note>`, falling back to a fixed literal, truncated to 400 chars).
- **`routine_run_warning`** — either (a) a terminal row logged `'completed'` with a non-blank
  `error_msg` (also mechanical, same `sp_log_run` write-time block), or (b) a routine called the new
  `ops.sp_report_run_issue(...)` procedure to report an in-run observation that did not block
  completion — see its contract below. Both land in this ONE category, sharing one closure entry and
  one mental model ("the run was fine but flag this").
- **`run_log_problem_unalerted`** — the BACKSTOP, raised only by the nightly `cadence_check` sweep
  (below), never by a routine directly. It exists because `sp_log_run`'s escalation block runs inside
  its own `BEGIN...EXCEPTION WHEN ERROR THEN...END` (the terminal row must land unconditionally even if
  alerting fails) — so a raise that itself throws is silent by design, and this is the independent
  witness that re-checks, from outside that handler, whether every problem row in the trailing 14 days
  ever got a matching alert AT ALL (keyed on "no alert ever raised," resolved or not — never "no open
  alert," because the first two categories are designed to auto-age off the board on a healthy
  schedule, and an open-only check would mistake that healthy aging for a dropped raise).

**Which reach email, and which also push.** All three are `'warning'` severity, so all three reach
email via `alert_emailer.gs`'s existing 2-hourly poll — nothing about email delivery changed. Push is
selective, per the 2026-09-07 notification policy (§25 above: every push gets an email, but not every
email needs a push):
- **`routine_run_failed`** — PUSHED. A run that did not complete may need a re-fire or other owner
  action.
- **`run_log_problem_unalerted`** — PUSHED. Its very existence means the notification pipe itself
  dropped something, which is the class of thing a push exists for.
- **`routine_run_warning`** — EMAIL ONLY (`scripts/alert_relay.py`'s `EMAIL_ONLY_CATEGORIES`, a
  SEPARATE tuple composed with the frozen `NO_PUSH_CATEGORIES` into one suppression set — see that
  file's own header for why it could not simply be added to `NO_PUSH_CATEGORIES`, which CI pins to
  exactly the six roster categories). The run completed and nothing is blocked; it reaches the inbox
  without buzzing the phone.

**Auto-age lifecycle — the closure path.** All three categories ride `ops.sp_sq_cadence_check`'s
existing number 14 auto-age allowlist (7-day sweep, `warning`/`info` only, `critical` excluded by
construction), the SAME mechanism `monitor_promoted` and several other categories already use, rather
than an `ops.alert_policy` `resolve_rule`. This is deliberate, not an oversight: each of the three is a
RECEIPT FOR A PAST EVENT — the run failed, or reported an issue, or a raise went missing — and that
fact is permanent; there is no mechanically re-checkable "it healed" condition for `sp_auto_resolve_alerts`
to verify, and the durable record of what actually happened lives in `ops.run_log` itself, not in
whether the announcement row is still open. Do not "fix" a still-open one of these by writing a
condition-based heal — there is no condition to check.

**`ops.sp_report_run_issue(in_routine, in_run_date, in_issue_key, in_summary, in_payload_json)` — the
contract, for any routine text (or triage session) that calls or reads it.** This is the actual
replacement for "paste it in chat" the owner asked for — call it instead of leaving an observation in
a `<note>` nobody reads for content, or in chat output nobody monitors.
- Severity is FIXED at `'warning'` — not a parameter. No argument combination can turn this into a
  halt; a genuine hard-stop still uses the routine's own cause-specific `sp_raise_alert_once` call.
- `in_issue_key` REFUSES (raises) if blank/whitespace or over 64 characters. It is the
  `sp_raise_alert_once` dedup key folded into the message, so it MUST name the KIND of issue
  (`'fmp_rate_limited'`), never the instance (`'fmp_rate_limited_at_14:32'`) — an instance-keyed value
  mints a fresh alert, and a fresh email, on every occurrence, the exact fatigue defect
  `bigquery/229_staged_order_confirm_notice.sql`'s `item_key` convention exists to avoid.
- `in_summary` REFUSES if under 30 non-blank characters — same reasoning as
  `ops.sp_amend_run_note`'s 40-character floor: a placeholder that only satisfies the signature is
  worse than silence, because it looks like a report.
- Lands in category `routine_run_warning` (shared with the mechanical completed-with-error case above).
  Message embeds `(routine, run_date, issue_key, summary)` — the summary text itself is IN the message,
  not just the payload, because unlike the mechanical escalation this procedure's whole purpose is to
  carry a human-written account to the inbox, and `alert_emailer.gs` only renders payload detail for
  the six roster categories.

**Triage, per category:**
- **`routine_run_failed`** — read the alert's payload (`run_id`, `session_id`, `branch`,
  `rows_written`, `error_msg`, `note`) or query `ops.run_log` directly for the named `(routine,
  run_date)`. Decide whether the run needs a re-fire (check `ops/cadence.yaml`'s `catchup_safe` for
  that routine) or whether the routine's OWN cause-specific alert (if any fired alongside this one)
  already names the real diagnosis — this backstop carries only the FACT that the run failed, not the
  diagnosis, so check for a sibling alert from the same routine/run before assuming this is the only
  signal.
- **`routine_run_warning`** — read the message for the reported issue (either the `error_msg` excerpt,
  or an `sp_report_run_issue` `issue_key` + summary). Nothing is blocked; decide whether the underlying
  condition needs a fix or is a known, accepted transient (e.g. an FMP rate-limit). This one is
  email-only by design — do not expect a push, and do not add one (§25's notification-policy rules
  above cover why).
- **`run_log_problem_unalerted`** — this means the notification path itself may be broken: a
  `routine_run_failed`/`routine_run_warning` raise that should have fired did not. Read
  `state.run_log_unalerted_problems` (or the alert's `STRING_AGG`'d payload) for the named
  `(routine, run_date, run_id)` rows, then go straight to `ops.run_log` for those rows' `error_msg`/
  `<note>` directly — the alert layer is exactly what is suspect here, so trust the underlying log row
  over any alert that may or may not exist for it.

**What was deliberately NOT changed.** `missed_run` (critical) and `routine_stalled` (warning) —
the two existing `cadence_check`-driven detectors — are untouched; neither gets `error_msg`/`<note>`
detail spliced into its message, because both are dedup-stable today and splicing per-run prose in
would defeat that, and for `missed_run` specifically (critical) would churn the trading gate. This
run-outcome path delivers its own diagnostic in its OWN alert instead. No new `ops.run_log.status`
value was added — `'completed with warnings'` as a status would silently change every existing
`status='completed'` predicate across the ~30 views/gates that read it; a `'completed'` row that also
carries a `routine_run_warning` alert is how that distinction is expressed instead.

## 51. The BigQuery MCP connector drops the `query` argument — and the *message* is the damaging part *(external dependency, 2026-08-18 → open)*

**The defect.** `mcp__Google_Cloud_BigQuery__execute_sql` and `..._execute_sql_readonly` intermittently
return `Required parameter is missing: query` for a well-formed call in which `query` WAS supplied. No
BigQuery job is created (no `queryId`, zero bytes billed, nothing in `INFORMATION_SCHEMA.JOBS_BY_PROJECT`),
so the request never reaches BigQuery. An immediate byte-identical re-issue clears it. First seen
2026-08-18 (D1); 21 distinct (routine, run_date) sightings in `ops.run_log` through 2026-09-10 across
D1, D2, D2a, D3, M1R, OPS0, OPS1, OPS2, SL2, SL5, AR_att and AR_orc; still reproducing 2026-09-11.

**Localisation (measured 2026-09-11, 284 calls).** The fault is downstream of the model and upstream of
BigQuery, and is **specific to the `query` argument of the two SQL-executing tools**:

- SQL tools **28 / 204 failed (13.7%)**; sibling tools on the same connector — `list_table_ids`,
  `list_dataset_ids` — **0 / 80**, including 20 interleaved call-for-call with failing
  `execute_sql_readonly` calls in the same window (Fisher exact p ≈ 8.2e-5). The interleave is what
  rules out "the bug is bursty and the control ran during a quiet period".
- `projectId` was supplied in all 284 calls and reported missing **zero** times.
- Not the model's emission: 30 byte-identical `tool_use` blocks in ONE assistant message → 25 serviced,
  5 rejected.
- Not positional: emitting `query` FIRST and `projectId` SECOND across 60 calls still produced 10
  failures, all naming `query`.

The MCP server is Google's (fully managed, closed-source, `bigquery.googleapis.com/mcp`); the claude.ai
broker relaying the call is Anthropic's, and this failure shape is a known family there
(`anthropics/claude-ai-mcp#628`, `claude-code#36518`/`#3966`/`#49910`). Which of the two owns it needs
server-side logs we cannot see.

**Why this has its own section rather than a line in the retry policy: the ERROR TEXT is a second,
independent defect.** Calling `execute_sql_readonly` with `projectId` and deliberately NO `query`
returns the **byte-identical** string. A caller therefore cannot distinguish *"you did not supply
`query`"* from *"`query` was supplied and was lost in transit"* — and every misdiagnosis this bug has
caused follows from that ambiguity, not from the drop:

- **2026-09-09, AR_att** — read the error on a 6,495-byte `ops.run_log` note, inferred a size limit, and
  rewrote the note down to **4,703 bytes**. ~2,291 bytes of audit prose lost. The run re-measured the
  identical payload afterwards: it succeeded first try.
- **2026-09-10, D2 and M1R independently** — both concluded a deterministic request-size ceiling existed
  ("~12.6KB succeeds, ~15KB fails twice"), and that conclusion became **binding guidance in
  `Claude_Task_Plan.md` and all 34 slices**. It is false: at a 13% per-call drop rate two consecutive
  drops is p² ≈ 1.7%, and across a 30-call session at least one back-to-back double is ~39% — expected,
  not deterministic. Re-measured directly 2026-09-11: byte-identical requests of **16,042** characters
  succeeded 6/8 and of **25,018** characters 3/4, both above the claimed ceiling, and no response at any
  size mentioned size, length or a limit. `ops.alerts` `5d971f00` was resolved WRONG on 2026-09-11, but
  the retraction never reached the plan text, so the refuted rule stayed binding for a day. It was
  **withdrawn on `main` in commit `8c1f780`**, landed independently and concurrently with this
  investigation; this changeset keeps that wording and adds the localisation above, the direct
  re-measurement, and the arithmetic that explains why the ceiling was inferred in the first place.

**The checksum does not protect you from this.** `ops.sp_write_adversarial_review` asserts the body
SHA-256 at write time, but it hashes whatever the session supplies — text shortened *before* the digest
is computed yields a self-consistent row that passes every assertion. Verified 2026-09-11:
`events.adversarial_reviews` is 193 rows with **0** hash mismatches, i.e. that table is intact *and* the
check could never have revealed this damage class. The defence is not making the misdiagnosis.

**Standing rule (unchanged, and confirmed correct by this work).** One immediate verbatim re-issue,
no wait, before any other branch — `Claude_Task_Plan.md` §Observability → MCP-TRANSPORT REJECTION. All
25 observed drops were transient; `state.retry_telemetry` shows every recorded arg-drop retry recovered
and none exhausted. A second identical failure is the same bug again: re-issue and work THE LADDER.
**Never shorten a record to make a write succeed.**

**Status: FILED 2026-09-11 — awaiting maintainer response.** [anthropics/claude-ai-mcp#1022](https://github.com/anthropics/claude-ai-mcp/issues/1022), submitted under the repo's Bug Report template (Area: Tool Discovery / Invocation). It carries all three asks: the drop itself, the misleading message as an independent defect, and the retry-semantics question. The GCP project ID was deliberately withheld from the public body and offered on request instead. **No maintainer has responded yet**, so this is filed, not acknowledged — if it is closed as a duplicate of the `claude-ai-mcp#628` brokered-argument-loss family, that is a legitimate outcome and should be recorded here as such. Full measurements and the submitted body: `ops/spikes/bigquery-mcp-query-arg-drop-2026-09-11.md`.

---

## 52. A BigQuery MCP call that outruns the synchronous window returns success-shaped emptiness — and the recovery tool was forbidden by our own CI gate *(external dependency, 2026-09-13)*

**The signature.** `execute_sql` / `execute_sql_readonly` can return

```json
{"jobComplete": false, "jobId": "job_bpsvGc2jj_QY3_zU-AsSlU7sb2Tn"}
```

— no rows, no `error_result`, no message of any kind. This is **not a failure**. BigQuery accepted the
statement and the job is RUNNING; it will run to completion and commit whether or not the session ever
looks at it again. The MCP tool merely stopped waiting: its synchronous window defaults to ~20 s
(`timeoutMs`).

**Why this is dangerous rather than merely awkward.** The response is shaped like an empty success, so
the two natural readings are both wrong. Read as "the query returned nothing", a routine proceeds on
absent data. Read as "the call failed", a routine re-issues the statement — and on an `INSERT` /
`UPDATE` / `MERGE` / `DELETE` / `CALL` that is a **double-write**, because the first job is still live
and will commit. The re-issue does not replace it; it duplicates it.

**It is the exact inverse of §51 and the two must never be conflated.** §51's arg-drop
(`Required parameter is missing: query`) is diagnosed by *no provider job having been created* — no
`queryId`, no bytes billed, nothing in `INFORMATION_SCHEMA.JOBS_BY_PROJECT` — and its correct handling
is ONE immediate verbatim re-issue. Here a job demonstrably WAS created and its id is in hand, and
re-issuing is precisely the wrong move. A session that pattern-matches this onto §51 converts a
non-event into data corruption.

**Frequency — measured 2026-09-13, not estimated.** Over the trailing 180 days, **867 of 54,522**
MCP-labelled BigQuery jobs (**1.6 %**) ran past 20 s. It happens on **every single operating day**
(range 7–95/day); **p99 is 26.3 s — already above the default window** — and the maximum observed was
**195.7 s**. Over the trailing 60 days the statements affected were **565 `SCRIPT`** (mean 29.1 s —
these are the `ops.sp_routine_start` / `ops.sp_auto_resolve_alerts` pre-flight blocks that EVERY
routine runs), **239 `SELECT`** (mean 41.0 s), and, mutating: **12 `MERGE`, 9 `INSERT`, 6 `UPDATE`,
1 `DELETE`**.

*No confirmed corruption incident has been traced to this yet* — a retry-signature sweep over the same
60 days found identical re-issues within 10 min for 0 of 9 `INSERT`, 0 of 6 `UPDATE` and 0 of 1
`DELETE` slow jobs (the 12-of-12 `MERGE` matches are `sp_sq_embed_pending`'s naturally-recurring
idempotent backfill, not retries). The exposure is that each occurrence leaves the outcome **unknown to
the session**, with no written procedure to resolve it.

**Verified end-to-end the same day.** A deliberately-timed-out read (`timeoutMs: 1`) returned
`jobComplete:false` + a `jobId`; `get_query_results` polled on that id returned the complete result set
(`n = 200000000`). So the recovery works and the tool is permitted.

**The second defect — the recovery was structurally un-documentable.** `get_query_results` arrived in
the connector on 2026-09-13 and OPS1 auto-added it to `ops/connector_tools.yaml` as `use: unused`,
which is the correct conservative default for a vendor-added tool. But
`scripts/check_connector_tools.py` **CHECK 3** hard-fails any routine text naming a tool the manifest
does not mark `required` — and `get_query_results` resolves to exactly one connector and carries no
`prose_ambiguous` flag. So for as long as it stayed `unused`, **writing the recovery procedure into
`Claude_Task_Plan.md` would have turned CI red**. The gate designed to stop routines calling tools they
should not was, for this one tool, also preventing the fleet from being told how to recover a lost
result. Note the fence is NOT the escape hatch here: `<!-- connector-tools-checker: ignore-start -->`
is reserved for documentary mentions, and this is an active call site.

**Fix landed 2026-09-13 (all in one commit, per `ops/connector_tools.yaml`'s EDIT DISCIPLINE rule that
a `use:` promotion and the prose that calls the tool move together):**
1. `ops/connector_tools.yaml` — `get_query_results` promoted `unused` → **`required`**.
2. `.claude/settings.json` — `mcp__Google_Cloud_BigQuery__get_query_results` added to
   `permissions.allow` (CHECK 2's requirement for any `required` tool).
3. `Claude_Task_Plan.md` — new **SYNCHRONOUS-TIMEOUT HANDOFF** bullet in the TRANSIENT-FAILURE
   WAIT-AND-RETRY ladder, placed immediately before THE LADDER and immediately after the two
   MCP-TRANSPORT REJECTION bullets so the contrast with §51 is read in place.

**`cancel_job` was deliberately NOT promoted, and must not be "for symmetry".** The two tools are not
symmetric: `get_query_results` RECOVERS a result, `cancel_job` only ABORTS one — discarding work
already being billed. No routine has a reason to abandon a query it deliberately issued, and cancelling
a DML would leave the write in an indeterminate state the fleet has no reconciliation path for, which
is strictly worse than waiting. It stays `use: unused`.

**Still open / not done here.** No vendor issue has been filed for this one — unlike §51 it is
documented, intended tool behaviour rather than a defect, so the fix is ours. If the fleet later wants
long statements to stop handing back control at all, the lever is an explicit larger `timeoutMs` on the
call rather than more polling; that was NOT changed here, because raising it fleet-wide would lengthen
every routine's worst-case stall and none of the measured 867 occurrences is known to have caused harm.
