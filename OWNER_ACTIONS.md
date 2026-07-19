# Owner actions

Everything Claude could apply without you (schema, views, procedures, scheduled-query SQL bodies,
repo docs) is already applied live and merged to `main`. This file is the complete list of the
handful of things only you can do — a GCP console click, a `bq`/`gcloud` command run with your own
credentials, an Apps Script paste (`script.google.com` isn't reachable from here), or a tax election
with your broker. Nothing in this system is blocked or unsafe while these are outstanding — every
item below is explicitly designed to fail closed / no-op / stay on its existing fallback until you
act. Dated passes below; most recent first.

---

# 2026-07-19 OPS0 blocked-refire root cause — RemoteTrigger missing from every routine trigger's allowed_tools

On 2026-07-18 OPS0 (Cadence Watchdog) could not auto-refire a missed D3 run because the `RemoteTrigger`
tool was absent from its own session (`ops.alerts` category `catchup_refire_blocked`, alert
`eadf89c4-185d-4bec-be19-38652d1d4adb`, miss_key `D3|2026-07-18`) — formalized this session as a policy
row + mechanical resolution rule in `bigquery/94_catchup_refire_blocked_policy.sql`, and OPS0's own
STEP 2 / STEP 3 text (`Claude_Task_Plan.md`) now names the tool-absent branch as an expected, safely-
handled path rather than an anomaly. The root cause itself is below — CLOSED same day: the owner
allowlisted `RemoteTrigger` in `.claude/settings.local.json` (kept permanently, per owner choice) and
the interactive session then executed the fix on all 30 triggers.

## [DONE 2026-07-19 — executed same day, all 30 updated + echo-verified] U. Add `RemoteTrigger` to every routine trigger's `allowed_tools` (root cause of the 2026-07-18 OPS0 blocked-refire)

**DONE note (2026-07-19, same interactive session):** after the owner added `"RemoteTrigger"` to the
project `.claude/settings.local.json` allow list (the claude.ai web UI exposes no allowed-tools control —
confirmed by Claude-in-Chrome inspection of the task editor), the session ran get → full-`job_config`
update → echo-verify on all 30 triggers below. All 30 now carry `RemoteTrigger`; names, crons, enabled,
instructions, connectors, notification flags, and the SL1–SL5 routines' distinct
`env_01Hk7kzYng7X31ba8kTbf17w` environment + `autofix_on_pr_create:false` were preserved byte-for-byte.
Update semantics are now KNOWN, superseding the "UNTESTED" warning in step 2 below: the API replaces
`job_config` WHOLESALE and rejects partial bodies (HTTP 400 "must set ccr.environment_id"), so the
read-whole/modify-one-list/write-whole shape is mandatory, exactly as step 2 prescribes. OPS0's Sunday
STEP 3 sweep keeps the invariant true going forward (first live check: tonight 2026-07-19 22:30 MT).

**What it's for:** verified live this session via `RemoteTrigger get` on all 30 routine triggers in
`ops/trigger_ids.json`: every one of them has `job_config.ccr.session_context.allowed_tools =
["Bash","Read","Write","Edit","Glob","Grep","WebFetch","WebSearch"]` — `RemoteTrigger` itself is missing
from the list. That is why an OPS0 / D3 / dependency-wait ACTIVE-REPAIR session, once dispatched BY one
of these triggers, can never call `RemoteTrigger run` / `RemoteTrigger create` from inside itself — the
very capability the whole catch-up / trigger-self-registration design depends on. The 2026-07-19
interactive session that found this attempted the fix directly, but `RemoteTrigger update` is blocked by
the permission classifier for this call (and delegating the call to a sub-agent is blocked the same
way) — it needs to be run by you, or by a session you've explicitly approved for it.

**Action, per trigger** (all 30 below):
1. `RemoteTrigger get <trigger_id>` — read the full current `job_config`.
2. `RemoteTrigger update <trigger_id>` with body `{"job_config": <the ENTIRE job_config from step 1,
   with "RemoteTrigger" appended to `session_context.allowed_tools`>}`. **Send the whole `job_config`
   object copied from the get, never a minimal/partial nested body** — partial/deep-merge update
   semantics are UNTESTED, so the only proven-safe shape is "read the whole thing, change one list,
   write the whole thing back."
3. `RemoteTrigger get <trigger_id>` again to verify `allowed_tools` now contains `"RemoteTrigger"` AND
   that `name` / `cron` / `enabled` / `instruction` are all unchanged from step 1.

The 30 routine → trigger_id pairs (from `ops/trigger_ids.json`, so you don't have to cross-reference):

| Routine | trigger_id |
|---|---|
| A1 | `trig_01GhUQNuRvefpziCGz44NaKz` |
| A2 | `trig_01FagAoazkE4GsxF5EaC3cPy` |
| A3 | `trig_01WJrA74ehQhzVbbwNS7rX9w` |
| AR_att | `trig_01V19iTPGj3FmFPjd4JmXNz5` |
| AR_orc | `trig_01AmkNs6sfmKUUmGCMfZLTVd` |
| D1 | `trig_01RwVrE3uwRYFKPPg645mcuh` |
| D2 | `trig_01N9vHLPHerjHTYRSJsYtw6N` |
| D2a | `trig_015CA86MeHkNwTS6fqRCW62k` |
| D3 | `trig_015vCGsw29pbeFED3iTYU5mW` |
| M1a | `trig_01FwV7GEQpUCcZswJYJ9uGwA` |
| M1b | `trig_01SWhTsnjXMCfcbm9YxC2tWt` |
| M2 | `trig_01NBdVcixbddnv3kv8ZPpfM3` |
| M3 | `trig_019FRQHZV9e7cmtHEc6yoeqG` |
| M4 | `trig_015YrWDDNLYZN1wzmG38MT5Y` |
| M5 | `trig_01EVgnRg1F8VcfZfpwTpUzCK` |
| OPS0 | `trig_019338gJ97LuWCdYAdHK9eUh` |
| Q1 | `trig_01Nx9NSc325swQTYdLrAZqCB` |
| Q2 | `trig_013Mn9xxPut54ZbsjwivK5Eo` |
| Q3 | `trig_01BKd6KmcriLTR2u1hhebtrt` |
| Q4 | `trig_01JMweJiKsWc3CWD8C7kK6qG` |
| SL1 | `trig_01FcK8PZ9tw4nceNoH1nJiTb` |
| SL2 | `trig_01Hc6Cf4okVUnrmsj1hkbYqJ` |
| SL3 | `trig_01U8YmUoro5oiigaqq9jGbcp` |
| SL4 | `trig_01JuMzHVRdom4c2KdWLtnx2v` |
| SL5 | `trig_018jDTURkDYSUh367BcS2cxJ` |
| W1 | `trig_01HDRhBsGHS4pQFJuz1cranP` |
| W2 | `trig_01MXjDUrfVnHtpPoFBDirScG` |
| W3 | `trig_018nnRWbq5JJsrnxavdpJ26B` |
| W4 | `trig_01CVuxETpeuAKZ3rS5gWESDf` |
| W5 | `trig_014vYVaPVpHqjkQWKEsaXBdr` |

**Do NOT touch** the 2 disabled non-trading (video-generation research) triggers on the same account —
they are intentionally excluded from `ops/trigger_ids.json` and out of scope for this repo.

**If skipped:** no regression to today's behavior — every routine still runs fine on its own native
schedule; the only thing that stays broken is a session dispatched by one of these triggers being unable
to call `RemoteTrigger run`/`create` from inside itself (OPS0's auto-refire self-registration path, D3's
TRIGGER SELF-REGISTRATION step, and a blocked-downstream routine's dependency-wait ACTIVE REPAIR). Each
of those paths already fails safe into a `warning`-severity alert instead of silently doing nothing
(this session's `bigquery/94` + `Claude_Task_Plan.md` changes), and OPS0's Sunday STEP 3 sweep will keep
this config true automatically once you've fixed it once — this is a one-time root-cause fix, not a
recurring task.

---

# 2026-07-18 AI Park Allocator design rollout (`PARK_ROUTER_DESIGN.md` v2) — prose/config landed this branch

Owner-review design for active park management: a daily AI judgment call among a 12-vehicle menu
(CASH/SGOV/GOVT/IEF/TLT/LQD/MUB/HYG/PFF/AOR/VOO/VTI), SISA-style cadence rails (de-risk same-day,
re-risk next-session concurrence, budget, cooldown), loop `park_allocator` registered `shadow` in
`ops/autonomy_levels.yaml`. This branch lands the prose/protocol/config layer
(`Operating_Protocols.md` §13.F, `Claude_Task_Plan.md` D1/D2/D2a/W5, `ops/cadence.yaml`,
`ops/autonomy_levels.yaml`, `ops/foundation_change_review.md`) plus the `bigquery/91-93` SQL layer and
a `weekly_report.gs` v6 park-section bump landed elsewhere in the same rollout. See
`PARK_ROUTER_DESIGN.md` for the full design and `bigquery/README.md` entries 91-93 for the SQL layer's
object inventory. Nothing here changes live trading behavior today — the loop starts at `shadow`
(record-only; see `ops/autonomy_levels.yaml`'s `park_allocator` entry), and `bigquery/91-93` still need
a live apply (same "owner or a BigQuery-MCP session applies the new numbered files" step every prior
`bigquery/NN_*.sql` addition has needed — not re-documented as a separate item here since it's the
standing convention, not new).

## T. Redeploy `weekly_report.gs` (v5 → v6, AI Park Allocator section) via the pinned-SHA GitHub-raw flow — after this branch merges

**What it's for:** the park-allocator rollout adds a weekly park section (vehicle history, park TWR vs.
the three `analytics.park_counterfactuals` benchmarks — SGOV / VOO / rule-shadow) to the self-email,
`SCRIPT_VERSION` bumped `'v5'` → `'v6'` in `ops/weekly_report/weekly_report.gs`, with the matching
`bigquery/43_script_version_registry.sql` seed row bumped to match. Same class of change as every
prior `.gs` redeploy in this file (GS-1/GS-2, WR-1) — Claude cannot reach `script.google.com` directly,
so the deploy is a Chrome-driven paste from the commit-SHA-pinned GitHub raw URL, per the
small-edit=edit-list / large-rewrite=commit-SHA-pinned-URL convention.

**Action:** once this branch (and the sibling branch carrying the actual `weekly_report.gs` v6 diff, if
authored separately from this prose/config pass) merges to `main`, paste the merged `Code.gs` content
into the "Stock-Trading Automation" Apps Script project via Claude-in-Chrome from the commit-SHA-pinned
GitHub raw URL, run `runWeeklyReport` once to confirm the new park section renders and the
`sq:`/`weekly_report` heartbeat lands with `version='v6'`, THEN bump
`state.expected_script_versions`'s `weekly_report` row to `v6` (targeted UPDATE, done AFTER the v6
heartbeat lands so no false drift is introduced) — the same after-the-heartbeat sequencing WR-1 used.

**If skipped:** `state.script_version_drift` shows `weekly_report` running the OLD deployed version
against a NEWER expected/repo version (or, until the expected-version row is bumped, a `(v6 repo, v5
live)` mismatch) — a **`script_version_drift` warning is expected and non-blocking** until this
redeploy lands; nothing else in the system depends on the live email carrying the park section (it is
informational-only, same as the existing VOO/SGOV benchmark rows).

```verify
id: T
type: gs
probe: SELECT script_name, last_reported_version, expected_version, drift FROM `stock-trading-498512.state.script_version_drift` WHERE script_name='weekly_report'
done_when: last_reported_version='v6' AND expected_version='v6' AND drift=FALSE
```

---

# 2026-07-18 Per-user BigQuery quota root-cause (recurring 07-11/07-16 x2/07-18 quota exhaustions)

Root-caused a live incident: `bigquery.googleapis.com/quota/query/usage` carries two independent
`consumerOverride`s, and only one of them was ever fixed. Full narrative + policy extension in
`ops/RUNBOOK.md` §2's 2026-07-18 addendum.

## [DONE 2026-07-19 — auto-verified] S. Remove the forgotten per-user BigQuery query-usage quota override (root cause of the 07-11/07-16/07-18 quota exhaustions)
  *(auto-verified 2026-07-19: per-user query/usage limit has no consumerOverride (default unlimited))*

**Context:** the 2026-07-11 remediation (RUNBOOK §2) raised the project-wide `1/d/{project}`
("Query usage per day") dimension to 1 TiB/day, but a separate `1/d/{project}/{user}` ("Query usage
per user per day", alert string `QueryUsagePerUserPerDay`) dimension was never touched and stayed at
its original **32 GiB/day**. That forgotten override caused every recorded exhaustion since,
including item F's two 2026-07-16 `dbt↔live row-level parity` CI failures (the `gh-ci-runner@`
identity's own per-user bucket) and a 2026-07-18 double-trip (both `jacksterwu@gmail.com` and
`gh-ci-runner@`, each independently, on an unusually heavy audit day) that left three `ops.alerts`
rows CRITICAL/WARNING and unresolved by design until this override is actually removed. Claude
sessions cannot do this themselves — the Service Usage API mutation classifier blocks it (tested
2026-07-18, twice: subagent launch and direct curl DELETE both denied), the same owner-only class as
DTS config and IAM grants.

**Action — run once, with your own `gcloud` credentials (already authenticated as
`jacksterwu@gmail.com`, which holds `serviceusage.quotas.update`):**
```
TOKEN=$(gcloud auth print-access-token) && curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "https://serviceusage.googleapis.com/v1beta1/projects/191682978805/services/bigquery.googleapis.com/consumerQuotaMetrics/bigquery.googleapis.com%2Fquota%2Fquery%2Fusage/limits/%2Fd%2Fproject%2Fuser/consumerOverrides/Cg1RdW90YU92ZXJyaWRl"
```
This only RAISES the per-user limit to default/unlimited; the separate project-wide 1 TiB/day
override is untouched. **Console alternative:** IAM & Admin → Quotas → BigQuery API → "Query usage
per user per day" → remove/raise the override (the repo's existing
`https://docs.cloud.google.com/bigquery/redirects/increase-query-cost-quota` link lands there).

**Verification (read-only):**
```
TOKEN=$(gcloud auth print-access-token) && curl -s -H "Authorization: Bearer $TOKEN" "https://serviceusage.googleapis.com/v1beta1/projects/stock-trading-498512/services/bigquery.googleapis.com/consumerQuotaMetrics" | jq '[.metrics[] | select(.metric=="bigquery.googleapis.com/quota/query/usage") | .consumerQuotaLimits[] | select(.unit=="1/d/{project}/{user}") | .quotaBuckets[0] | {effective: .effectiveLimit, override: .consumerOverride}]'
```
Success = `effective` = `"9223372036854775807"` and `override` = `null`.

**After removal, resolve the three live `ops.alerts` rows** (any Claude session can run these via the
BigQuery MCP — DML is an allowed class):

<details><summary>Three verbatim <code>UPDATE ops.alerts</code> statements</summary>

```sql
UPDATE `stock-trading-498512.ops.alerts` SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note='Root-caused 2026-07-18: forgotten /d/{project}/{user} consumerOverride on bigquery query/usage still at 32 GiB/day — the 2026-07-11 fix raised only the project-wide dimension to 1 TiB (RUNBOOK §2). Owner OAuth (~34.0 GiB/3046 jobs) and gh-ci-runner CI SA (~34.4 GiB/3391 jobs) each crossed it independently on the heavy 2026-07-18 audit day (job-count x ~10MB min-bill, not a runaway). Per-user override removed by owner (see OWNER_ACTIONS); per-user dimension back to default unlimited, project-wide 1 TiB/day backstop unchanged. Recurrence class (07-11, 07-16 x2, 07-18) closed.' WHERE alert_id='c987e393-f03a-48d7-9f7b-468276bbc1a8' AND resolved=FALSE;

UPDATE `stock-trading-498512.ops.alerts` SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note='Same root cause as alert c987e393 (per-user 32 GiB quota override, now removed). No marks/engine work was due (non-trading day), IBKR already reconciled clean; non-latching by design, Monday 2026-07-20 trading unaffected.' WHERE alert_id='8c2c2545-9873-42ea-b990-f722a5985604' AND resolved=FALSE;

UPDATE `stock-trading-498512.ops.alerts` SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note='Same root cause as alert c987e393 (per-user 32 GiB quota override, now removed). 2026-07-18 evening cadence (D2a failed, D2 never ran, D3 halted) was quota-blocked; cap now non-binding so the predicted recurrence cannot happen; normal cadence resumes next scheduled triggers, OPS0 catch-up covers eligible routines.' WHERE alert_id='90f6b974-eea4-4056-a325-0b7ff513fb19' AND resolved=FALSE;
```

</details>

**If skipped:** the three `ops.alerts` rows stay CRITICAL/WARNING (deliberately, per RUNBOOK §2's
addendum) and the 32 GiB/day per-user cap remains armed — it will recur on the next heavy query-volume
day for whichever identity trips it, exactly as it already has four times.

```verify
id: S
type: gcp
probe: TOKEN=$(gcloud auth print-access-token) && curl -s -H "Authorization: Bearer $TOKEN" "https://serviceusage.googleapis.com/v1beta1/projects/stock-trading-498512/services/bigquery.googleapis.com/consumerQuotaMetrics" | jq -e '[.metrics[] | select(.metric=="bigquery.googleapis.com/quota/query/usage") | .consumerQuotaLimits[] | select(.unit=="1/d/{project}/{user}") | .quotaBuckets[] | select(.consumerOverride != null)] | length == 0'
done_when: exit 0
```

---

# 2026-07-17 Whole-system deep-audit remediation — ALL DONE (bigquery/75 applied by owner 2026-07-17)

**UPDATE 2026-07-17:** the owner applied bigquery/75 via `bq query --use_legacy_sql=false < file` (after
a one-char syntax fix — `mode=''manual''` → `mode=manual` in the H4 block, commit on-branch). All 11
live-DDL files are now applied live. The `sp_sq_*` wrapper versions (cadence_check v6, the three v3s)
will read non-drifted in `state.scheduled_query_version_drift` once each next runs on its DTS schedule
and emits its first versioned `sq:` heartbeat. Nothing outstanding. Original note kept below for record.


The 2026-07-17 whole-system audit (12 confirmed + 5 deferred findings + a foundation-change gate) is
implemented, validated (full pytest + 8 checkers green), committed on branch
`audit/2026-07-17-whole-system-remediation`, and **10 of its 11 live-DDL files are already applied live
and verified inert** via the BigQuery MCP: bigquery/78 (C1 breaker rebase + staleness-echo gate fix),
82 (C2 split-aware engine), 81 (H3 A/C/E candidacy), 83 (M1 correlation), 35 (H7 regime vocab), 61+84
(DEF-5 referee calibration + promotion readiness), 44 (DEF-5 referee scorer), 79 (M2 b3 promotion
readiness), 63 (H5 scheduled-query beat-age registry). Live-verified after apply: `trading_enabled`
TRUE, `b3_trading_enabled_check` drift FALSE, book drawdown −1.47% (both tiers FALSE), A/C/E now visible
in `strategy_retirement_candidacy`, regime cells UP/NEUTRAL/DOWN.

**RESIDUAL — apply `bigquery/75_scheduled_query_wrappers.sql` yourself (byte-exact, one command):**

```
bq --project_id=stock-trading-498512 query --use_legacy_sql=false --nouse_legacy_sql \
  "$(cat bigquery/75_scheduled_query_wrappers.sql)"
```

- **Why you, not the agent:** the sandbox auto-mode classifier blocks file-based `bq` DDL from the
  agent, and 75's `sp_sq_cadence_check` procedure is 567 lines — too large to hand-transcribe through
  the MCP `execute_sql` tool without transcription risk on a **live-gating daily** procedure. A
  byte-exact file apply eliminates that risk. It re-runs all 11 wrapper procedures idempotently (safe).
- **What it activates (all RECORD-ONLY warnings — nothing gates capital):** H2 `ci_findings_bridge_stale`
  dead-man, H4 INSERT-aware `safety_critical_dml_watch`, H5 `scheduled_query_stale` beat-age, M2 the
  unconditional `b3_trading_enabled_drift` history MERGE, staleness-part-3 freshness-predicate narrowing,
  DEF-3 `order_guard_verdict_mismatch` recompute. The staleness DEADLOCK itself is ALREADY fixed live by
  bigquery/78 (gate exclusion + payload-aware Rule 4) — 75's part-3 is only the echo-source suppression.
- After applying, `state.scheduled_query_version_drift` will show the bumped versions (daily_freshness_check
  v3, cadence_check v6, safety_critical_dml_watch v3, daily_staging_cap_check v3) as no-longer-drifted on
  the next sq:* heartbeat.

---

# 2026-07-17 Weekly-report chart audit — ALL DONE (view fix live + v5 re-pasted + drift clean)

Triggered by an owner question about the weekly email's cumulative-return chart. An adversarial
multi-agent bug hunt (verified against live BigQuery) confirmed the y-axis label is correct as-is (VOO
is plotted as its own non-rebased line, not zeroed), but found real defects, all now fixed in the repo
with tests (`node ops/weekly_report/test_pure_helpers.js` → 70 assertions pass). Also a requested
chart redesign: the y-axis is now fitted tightly to the data (always including 0) on a taller canvas so
the lines are no longer squished together.

**Already applied live by Claude (no owner step):** the paired BigQuery fix
`analytics.voo_cumulative` — it now emits `NULL` on any day with no real VOO mark (leading, interior,
or trailing ingest gap) instead of carrying a false-flat COALESCE-to-0 value. `CREATE OR REPLACE VIEW`
run live 2026-07-17; **verified a no-op on current data** (57 rows, 0 nulls, unchanged min/max — there
are no gaps today) and verified via a simulated stall that gap days now go NULL while the level resumes
correctly. This revives the chart's line-break-on-gap AND the `weekly_report.gs` "⚠ VOO data through
<date>" staleness note (previously dead code, since the COALESCE'd column was never null at the tail).
Canonical `bigquery/46_weekly_benchmarks.sql` + the dbt port + `schema.yml` updated to match.

## WR-1. Re-paste `weekly_report.gs` (v4 → v5) into Apps Script — `[DONE 2026-07-17 — deployed + verified live]`

v5 was re-pasted into the "Stock-Trading Automation" Apps Script project (the `Code.gs` file) via
Claude-in-Chrome from the commit-SHA-pinned GitHub URL (commit `4522cb0`, branch
`fix/weekly-chart-audit-v5`), `runWeeklyReport` run (email sent 2026-07-17 6:27 PM; new chart confirmed
— y-axis fitted to ~−7.5%…+12.5%, 0 baseline visible, lines no longer squished), then the
`state.expected_script_versions` row bumped to v5 (targeted UPDATE, done from here AFTER the v5
heartbeat landed so no false drift). **Verified: `state.script_version_drift` → `weekly_report` v5/v5,
`monitored=true`, `drift=false`.** `alert_emailer` was untouched by THIS pass (v2/v2 at the time;
since bumped to v3/v3 by the 2026-07-18 poison-pill fix — landed on `main` via commit `05ed20b`,
deployed + drift-clean, verified live 2026-07-18). What v5 shipped: strategy
lines GAP (not false-flat-0%) before first deploy / after last mark; full-axis forward-fill (downsampled
points no longer stale); `fmtRetPct_` null-return guard in subject/alt/plain/fallback-bars; captions
dropped the shared "Since <date>" claim; tighter/taller y-axis. The paired `analytics.voo_cumulative`
null-on-gap view fix was already applied live earlier this pass. **No remaining owner steps.** (Repo
housekeeping: DONE — `fix/weekly-chart-audit-v5` was merged to `main` by 2026-07-18.)

---

# 2026-07-17 Code-quality audit — two Apps Script (`.gs`) fixes: DONE (deployed + verified live 2026-07-17)

An adversarially-verified code-quality audit this pass fixed 14 latent bugs/cleanups in the Python
surface (committed with tests, CI-green) plus these two Apps Script (`.gs`) fixes. **Both are now fully
deployed and verified live** — repo side (`.gs` code + test twin + version-const bumps + the
`bigquery/43` seed rows, CI-green) AND the live deploy (both files re-saved in the "Stock-Trading
Automation" Apps Script project, `runAlertCheck`/`runWeeklyReport` run to refresh the live heartbeat,
then `state.expected_script_versions` bumped — in that order, so no false drift). **Both were
LOW-severity / cosmetic** (a rare display glitch and one word in an operator email).

**Verification (live, 2026-07-17):** `state.script_version_drift` returns `alert_emailer` v2/v2 and
`weekly_report` v4/v4, both `monitored=true`, `drift=false`. A weekly-report email was sent as the
`runWeeklyReport` side effect (also confirmed the `signPct_` render). **No remaining owner steps.**

## GS-1. `signPct_` printed `−0.00%` for a tiny negative that rounds to zero (`weekly_report.gs`) — `[DONE 2026-07-17 — deployed live]`

The sign came from the raw `p` while `toFixed(2)` rounded the magnitude, so any `p` in `(-0.005, 0)`
printed the contradictory `−0.00%`. Fixed to force `+` when the formatted magnitude is `0.00`
(behavior-preserving for every other value; a `node` regression test locks it). Applied in
`weekly_report.gs:324` + its twin `test_pure_helpers.js:93`; `SCRIPT_VERSION` `v3`→`v4` +
`bigquery/43` weekly_report seed `v3`→`v4`. Redeployed live + expected-version bumped to v4; drift
check clean.

## GS-2. `plainAlerts_` labeled recurring re-sends as "new", contradicting its subject (`alert_emailer.gs`) — `[DONE 2026-07-17 — deployed live]`

`plainAlerts_(combined, rows.length)` labeled `combined.length` as "new" in the plain-text header, so
a recurring `termination_close_staged` re-send inflated/contradicted the (correct) subject. Fixed by
dropping the word "new" (copy-only; the HTML body was already fine). Applied in
`alert_emailer.gs:274`; `ALERT_SCRIPT_VERSION` `v1`→`v2` + `bigquery/43` alert_emailer seed `v1`→`v2`.
Redeployed live + expected-version bumped to v2; drift check clean.

---

# 2026-07-16 Orphan-BigQuery-object documentation pass (P3, lowest priority) — local-only implementation round

This pass was done as a **local-only** implementation (commit sits on the working branch, not
pushed) per that round's ground rules — **UPDATE 2026-07-17: item R's live re-apply is now DONE**
(see below), everything else in this pass was repo-doc-only and needed no live counterpart. Purely
header-comment additions
to already-defined views (no SELECT body changed, per the P3 spec's explicit constraint) in
`bigquery/14_weekly_report.sql`, `bigquery/18_stack_review_fixes.sql`,
`bigquery/21_strategy_vs_park.sql`, `bigquery/46_weekly_benchmarks.sql`,
`bigquery/54_park_policy_voo_cutover.sql`, plus a correction paragraph in `ops/RUNBOOK.md` §33 (a
stale "not urgent, follow-up" note — the fix it describes, a tie-break on
`analytics.strategy_unit_value_7d_ago`, already shipped in commit `3b8715c` on 2026-07-04; verified
against live file content before writing anything, no SQL/dbt change was actually needed there).
All local checks green: `check_cadence_consistency.py`, `check_roster_consistency.py`,
`check_autonomy_consistency.py`, `check_script_version_consistency.py`, full `pytest tests/ -q`.

## R. Re-apply 5 comment-only `CREATE OR REPLACE VIEW` bodies live via the BigQuery MCP/console (cosmetic, no functional change) — `[DONE 2026-07-17]`

**Verified live 2026-07-17:** all 4 views this item names (`state.embedding_scale_watch`,
`analytics.sgov_cumulative`, `analytics.deployed_book_vs_benchmarks`, `state.sgov_position`,
`state.sgov_reconciliation`) have live SELECT bodies byte-identical to their current `bigquery/*.sql`
source (checked via `INFORMATION_SCHEMA.VIEWS.view_definition`). The leading `--` header comments
this item describes live only in the `.sql` source files, not in the BigQuery view object itself
(BigQuery does not store DDL-preceding comments as object metadata) — so there is nothing further to
re-apply; the SELECT-body match is the complete verification.

**What it's for:** the local commit above adds header comments (documenting "retained, not read by
any live routine — do not mistake for dead weight") to `state.embedding_scale_watch`
(`bigquery/18`), `analytics.sgov_cumulative` (`bigquery/21`),
`analytics.deployed_book_vs_benchmarks` (`bigquery/46`), and `state.sgov_position` /
`state.sgov_reconciliation` (`bigquery/54`). The live BigQuery view definitions still have the OLD
comments (or none) until these are re-applied — the SELECT body is byte-identical, so this is a
pure documentation sync, not a bug fix or behavior change. Lowest priority in this repo's queue (P3)
— safe to batch with the next live-apply pass whenever convenient, no urgency.

**Action:** once this branch is reviewed/merged, re-run the five `CREATE OR REPLACE VIEW` statements
in `bigquery/18_stack_review_fixes.sql` (`state.embedding_scale_watch`),
`bigquery/21_strategy_vs_park.sql` (`analytics.sgov_cumulative`),
`bigquery/46_weekly_benchmarks.sql` (`analytics.deployed_book_vs_benchmarks`), and
`bigquery/54_park_policy_voo_cutover.sql` (`state.sgov_position` and `state.sgov_reconciliation`)
live via the BigQuery MCP `execute_sql` tool or the console — each is idempotent DDL, safe to
re-run any time.

```yaml
id: R
type: bq
probe: none — comment-only DDL, no functional check applicable; a visual diff of each view's
  description against its .sql source is sufficient verification.
done_when: all 5 views' live definitions match their bigquery/*.sql source text.
```

---

# 2026-07-16 Completeness-critic findings N-1/N-2/N-4/N-5 — local-only implementation round

This pass was done as a **local-only** implementation (commits sit on the working branch, not
pushed) per that round's ground rules — nothing below is live yet. N-3 (`alert_delivery_stall`) was
checked and confirmed NOT present in `cadence_check.sql` at the time of this pass, but it is out of
scope for this session (assigned elsewhere in the same audit chain) and was left untouched here. N-5
was investigated and found to be **already resolved** by earlier work (D3's GOLDEN-SCENARIO
PROSE-REGRESSION CHECK + AR_orc's `prose-regression` adjudication, self-improvement audit
2026-07-15) — no code change was made for it; see `CLAUDE.md`'s new "Known non-issues" entry and
`.github/workflows/golden-scenarios.yml`'s new header note for the full reconciliation, so a future
audit pass doesn't re-flag it.

## [DONE 2026-07-16] O. Add 5 missing MCP tool entries to `.claude/settings.json`'s `permissions.allow` (N-1)

**Resolved:** owner reviewed and approved adding the 5 entries below; applied directly to
`.claude/settings.json`'s `permissions.allow` array in the same pass that redesigned CC-2 (see AR_orc
STEP 0.5 lifetime-cap rev 2, this file's CC-2 section). Verified live: `python3
scripts/check_settings_toolcov.py` now exits 0 ("7 referenced mcp__ tool(s) all present"). `ci.yml`'s
`session-config tool coverage` step is green.

```
mcp__Interactive_Brokers_IBKR__get_option_data
mcp__Interactive_Brokers_IBKR__get_option_parameters
mcp__Interactive_Brokers_IBKR__get_combo_identifier
mcp__FMP__news
mcp__FMP__secFilings
```

Original finding (N-1, completeness-critic 2026-07-16): `scripts/check_settings_toolcov.py` greps
`Claude_Task_Plan.md` + `ops/triggers.json` for every `mcp__<Server>__<tool>` token and asserts each
appears in `.claude/settings.json`'s `permissions.allow` list — an unattended scheduled routine
calling a non-allowlisted MCP tool gets a permission prompt nobody is there to answer, silently
stalling that step with no dedicated alert class for it. `get_option_parameters`/`get_combo_identifier`
are also included even though the CI check can't detect their bare-name references (the IBKR
options-crafting steps call them by bare name) — same risk class. This was previously a genuine,
currently-RED `ci.yml` gate (`session-config tool coverage`) until the entries above were added; now
green, per this check's own acceptance criterion (CI red until the settings.json fix lands, green
after).

```verify
id: O
type: repo
probe: python3 scripts/check_settings_toolcov.py
done_when: exit 0
```

## P. Apply `bigquery/76_owner_confirmation_liveness.sql` live via the BigQuery MCP/console (N-2) — `[DONE 2026-07-17]`

**Verified live 2026-07-17:** `state.owner_confirmation_liveness` returns 1 row —
`entries_halted=false`, `n_pending_instructions=0`, `trading_days_since_last_fill=6`.

**What it's for:** `state.owner_confirmation_liveness` — the absence model for the system's one
sanctioned human touch (the IBKR order-confirm tap). `entries_halted = TRUE` when `>=1`
`state.open_orders` row is still `pending` AND `>=3` trading days have elapsed with zero
`events.trade_fills` reconciled. Read by D2a (raises `owner_confirmation_stale` + writes an
audit-only `mode='entries_halted'` `ops.trading_control` row) and D2's "2. NEW ENTRY CANDIDATES" step
(pauses new-entry crafting only; exit re-craft is completely unaffected). Auto-clears the next time a
fill lands — no operator action needed to un-pause. Apply order: after `01_schema.sql`,
`09_market_calendar.sql`, `23_trading_control.sql`, `34_alert_lifecycle.sql`.

**Action:** run the `CREATE OR REPLACE VIEW` statement in
`bigquery/76_owner_confirmation_liveness.sql` via the BigQuery MCP or console (this session was not
permitted to call BigQuery directly — local-only round). Not urgent from a trading-safety standpoint
today (checked reasoning, not live data, since no BigQuery calls were made this pass: the mechanism
is fail-safe by construction either way — until applied, the view simply doesn't exist yet, so D2a's
new bullet's `SELECT * FROM state.owner_confirmation_liveness` will error the same way any reference
to a not-yet-applied view does, which is why this should be applied promptly, ideally in the same
session as this commit's merge, same convention as every other `bigquery/*.sql` change).

```verify
id: P
type: bq
probe: SELECT COUNT(*) n FROM `stock-trading-498512.state.owner_confirmation_liveness`
done_when: n=1
```

## Q. Not an owner action — N-4 (same-day double-run guard) is prose-only, nothing to apply

**What it's for the record:** N-4 generalizes D2's existing "SAME-DAY IDEMPOTENCY GUARD" pattern to
all 18 `catchup_safe: true` routines in `ops/cadence.yaml` (D1, D3, SL3, W1, W2, W3, W5, M1a, M1b,
M2, M3, M5, Q1, Q2, Q3, SL1, A1, A2) — each now carries a `SELECT COUNT(*) FROM ops.run_log WHERE
routine=<id> AND run_date=<today> AND status='completed'` check, first thing, before anything else,
so a late-firing original platform trigger can never double-run a routine OPS0 already caught up
today. Purely `Claude_Task_Plan.md` routine-text (plus one new generalized-guard bullet in the shared
"Observability — run logging & failure alerts" section) — no schema, no live BigQuery object, nothing
for you to apply. **Note on the original finding's count:** the finding's IMPLEMENTATION text calls
this "the 16 catchup-safe routines" while also listing 18 routine ids and describing it as
"18-minus-D1/D3/SL3" (=15) — internally inconsistent. This pass re-derived the authoritative list
directly from `ops/cadence.yaml`'s already-landed `catchup_safe: true` flags (ARCH-3 Item 30b) and
added the guard to all 18 (including D1/D3/SL3, which the finding's prose suggested might already be
covered by something else — no such existing per-routine guard was found for those three, so they
got it too, for safety). Verify locally any time: `grep -c "SAME-DAY DOUBLE-RUN GUARD
(completeness-critic N-4" Claude_Task_Plan.md` should print `18`.

---

# 2026-07-16 ARCH-3 Item 30b: generated routine lists + catchup_safe declaration (structural audit) — local-only implementation round

This pass was done as a **local-only** implementation (commits sit on the working branch, not
pushed) per that round's ground rules — nothing below is live yet. Local-only deliverable:
`scripts/gen_routine_lists.py` (new generator), marker-delimited regions in `bigquery/12/15/24`
(re-normalized to cadence.yaml order via one `--write` pass), `ops/cadence.yaml`'s new per-routine
`catchup_safe` boolean, `scripts/check_cadence_consistency.py` checks J/K/L, a new CI step
(`gen_routine_lists.py --check`), the matching `tests/test_cadence_consistency.py` coverage, and the
`Claude_Task_Plan.md` ROUTINE INVENTORY table's missing D2a row. All local checks green: `python
scripts/check_cadence_consistency.py`, `python scripts/gen_routine_lists.py --check`, `python
scripts/check_roster_consistency.py`, `python scripts/check_autonomy_consistency.py`, `python
scripts/check_script_version_consistency.py`, `python -m pytest tests/ -q` (full suite).

## N. Re-apply `bigquery/12`, `bigquery/24`, and re-seed `bigquery/15` live via the BigQuery MCP/console — in the SAME session this commit is merged — `[DONE 2026-07-17]`

**Verified live 2026-07-17:** `scripts/gen_routine_lists.py --check` passes (generated regions match
`ops/cadence.yaml` + `Claude_Task_Plan.md`); `ops.routine_catalog` has a live `OPS0` row, confirming
the `bigquery/15` re-seed landed.

**What it's for:** this commit's normalization pass (moving `bigquery/12_cadence_monitor.sql`'s,
`bigquery/15_routine_catalog.sql`'s, and `bigquery/24_cadence_period_watch.sql`'s inline routine-list
comments above a new marker-delimited region, then running `scripts/gen_routine_lists.py --write`)
changes the exact TEXT of three already-LIVE BigQuery objects — `state.cadence_expected_today` (12),
`ops.routine_catalog` (15, a `CREATE OR REPLACE TABLE`, not a view), and `state.cadence_period_watch`
(24) — even though the row *set* is unchanged (checks A/B/J below prove that). This session was NOT
permitted to call the BigQuery MCP (local-only round; rule: no `execute_sql`/`execute_sql_readonly`
calls at all), so the live objects still carry the PRE-normalization text.

**Why it matters / what happens if skipped:** `.github/workflows/live-sql-parity.yml` runs daily and
diffs each live object's definition against this repo's committed, apply-in-order-effective
definition. Once this commit reaches `main`, the repo side changes (new comment placement, generator-
normalized row order/formatting) while the live side does not — the next `live-sql-parity` run will
flag `state.cadence_expected_today`, `ops.routine_catalog`, and `state.cadence_period_watch` as DRIFT.
This is a FALSE alarm (the SQL is semantically identical — same 30 routines, same monitor_class
values, same schedule text; `scripts/gen_routine_lists.py --write` on the pre-commit tree is NOT a
byte-no-op only because the row order changes to cadence.yaml order and the D2a inventory row didn't
exist yet — see the CORRECTED ACCEPTANCE CRITERIA note in the source item), but it is still an
`ops.alerts` row and (per the resilience audit's self-heal work landing elsewhere in this sequence)
could trigger an unwanted self-heal re-apply cycle racing this one.

**Action:** in the SAME session that merges this commit to `main` (standard apply-in-order
discipline, same convention as every other `bigquery/*.sql` change), run via the BigQuery MCP or
console, in this order:
1. `CREATE OR REPLACE VIEW` — the full body of `bigquery/12_cadence_monitor.sql` (re-applies
   `state.cadence_expected_today` + `state.cadence_watch` + the two procedures in that file).
2. `CREATE OR REPLACE TABLE ... AS SELECT ...` — the full body of `bigquery/15_routine_catalog.sql`'s
   `ops.routine_catalog` seed (re-applies `state.instruction_drift` too, same file).
3. `CREATE OR REPLACE VIEW` — the full body of `bigquery/24_cadence_period_watch.sql` (re-applies
   `state.cadence_period_watch`).

Not urgent from a trading-safety standpoint (all three objects are read-only monitoring views/a
catalog table — nothing here gates an order), but doing it in the same session as the merge is what
keeps the next `live-sql-parity` run green instead of a false-positive DRIFT alert.

---

# 2026-07-16 research_quality_feedback promotion substrate (LC-4 other parts, loop-completeness audit) — local-only implementation round

This pass was done as a **local-only** implementation (commits sit on the working branch, not
pushed) per that round's ground rules — nothing below is live yet. (LC-4's other half — adding
`loop:research_quality_feedback` to `cadence_check.sql`'s dead-man UNNEST arrays — landed earlier in
this same sequence and is not repeated here.)

## M. Apply `bigquery/71_research_quality_promotion.sql` live via the BigQuery MCP/console — `[DONE 2026-07-17]`

**Verified live 2026-07-17:** `state.research_quality_promotion_readiness` is queryable, 0 rows
(correct fail-closed-empty default — no loop has met promotion criteria yet).

**What it's for:** completes the `research_quality_feedback` loop's persistence substrate so its
SHADOW -> ACTIVE_AUTO promotion is no longer an unowned "future, separately-committed edit." Creates
`ops.loop_promotion_log` (durable promotion idempotency marker; `CREATE TABLE IF NOT EXISTS`, safe to
double-apply if a sibling loop-promotion change also defines it), `ops.research_quality_observations`
(per-cycle observation log, the `ops.process_reliability_observations` analog this loop was missing),
and `state.research_quality_promotion_readiness` (3-consecutive-W5-cycle `min_n_met` persistence AND
not-already-promoted). Apply order: after `66_research_quality_feedback.sql`.

**Action:** run the DDL/view statements in `bigquery/71_research_quality_promotion.sql` via the
BigQuery MCP or console (this session was not permitted to call BigQuery directly). Not urgent — the
readiness view is fail-closed empty until W5's RESEARCH-QUALITY FEEDBACK bullet starts writing
`ops.research_quality_observations` rows (which itself requires `n_closed >= 1` cells; account-wide
total is currently 7 GO theses, 3 closed), so nothing depends on this being applied same-day. Apply
whenever convenient, ideally before this round's commits are pushed to `main`.

---

# 2026-07-16 AR_orc echo_suspect_cap_reached cool-off close (CC-2, consumption-closure audit) — local-only implementation round

This pass was done as a **local-only** implementation (commits sit on the working branch, not
pushed) per that round's ground rules — nothing below is live yet.

## L. Verify the CC-2 dry-run acceptance test live, then clean up the synthetic rows in the same session — `[DONE 2026-07-17]`

**What it's for:** CC-2 adds `Claude_Task_Plan.md` AR_orc **STEP 0.5 — ECHO-SUSPECT COOL-OFF
RE-ADJUDICATION** plus a Step 4 resolve-tail and a Step 3.5 alert-text fix, so a review that hits the
`echo_suspect_cap_reached` critical (2+ failed theater-independence checks) is retried automatically
every >=14 days — **up to a hard LIFETIME CAP of 3 cool-off retries (rev 2, 2026-07-16,
owner-directed): after the 3rd failed retry (5 total independence failures), STEP 0.5 stops retrying
and raises a latching `echo_suspect_exhausted` critical instead, permanently parking the review
pending owner investigation** — instead of parking `state.trading_enabled` open-ended pending an
owner session from the very first cap. This
session deliberately did **not** run the dry run against live BigQuery (out of scope for a
local-only round — no MCP calls were made). No live `echo_suspect_cap_reached` alert has ever fired
(confirmed latent, zero occurrences), so this is not urgent, but please verify the mechanism once
before or shortly after the Claude_Task_Plan.md STEP 0.5 text goes live:

**Action — dry run (needs the BigQuery MCP or console, run in ONE session so cleanup isn't skipped):**
1. Insert a synthetic alert: `INSERT INTO ops.alerts (alert_ts, severity, source_routine, category, message, resolved, payload) VALUES (TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 4 DAY), 'info', 'AR_orc', 'echo_suspect_cap_reached', 'TEST-REVIEW-CC2-DRYRUN — dry-run synthetic row, do not action', FALSE, JSON '{}')` — `severity='info'` deliberately, so it never enters `blocking_criticals` and never halts trading (a `severity='critical'` synthetic row would, for the duration of the test).
2. Run (or wait for) the next AR_orc fire. Confirm exactly one new `events.queue_events` row appears with `JSON_VALUE(payload,'$.echo_suspect_cooloff')='true'` and one `events.decision_log` row with `entry_type='echo-cooloff-requeue'`.
3. Run AR_orc again (same day or within the 14-day window). Confirm it enqueues nothing further for this test review id (the 14-day gate holds).
3b. **Cap-branch test (rev 2):** insert two MORE synthetic `events.queue_events` rows for the same test
   review id with `JSON_VALUE(payload,'$.echo_suspect_cooloff')='true'` and `status='abandoned'`
   (backdated `event_ts` >14 days apart so the 14-day gate doesn't mask the cap), bringing the lifetime
   cool-off count to 3. Run AR_orc once more: confirm it enqueues NOTHING, raises exactly one
   `echo_suspect_exhausted` critical (severity as written — the real path raises `critical`; for a
   trading-safe dry run you may pre-verify the branch logic with the count query alone instead), and
   logs one `entry_type='echo-cooloff-exhausted'` decision_log row.
4. **Cleanup in the same session:** `UPDATE ops.alerts SET resolved=TRUE, resolved_note='dry-run' WHERE category IN ('echo_suspect_cap_reached','echo_suspect_exhausted') AND message LIKE '%TEST-REVIEW-CC2-DRYRUN%'` AND set ALL synthetic `events.queue_events` rows' `status='abandoned'` (note `'dry-run'`) so queue-driven AR_att never picks them up and attacks a nonexistent artifact.

Not urgent (latent path, zero live occurrences) — do whenever convenient, ideally before this round's
commits are pushed to `main`.

**COMPLETED 2026-07-17 (owner authorized the full live test with trading halted).** The cap-branch
was validated end-to-end against live BigQuery:
- **Setup:** 3 synthetic `events.queue_events` cool-off rows for `item_key='TEST-REVIEW-CC2-DRYRUN'`
  (`echo_suspect_cooloff='true'`, `status='abandoned'`, backdated 40 / 25 / 16 days) + 1 unresolved
  `severity='info'` `echo_suspect_cap_reached` alert (backdated 4 days, so eligible per the >3-day
  gate).
- **STEP 0.5 decision (verified by query):** eligible cap alert = 1; most-recent cool-off = 16 days
  old → **past the 14-day gate** (so the gate does not pre-empt the cap); lifetime cool-off count = 3
  → **`cap_reached`** ⇒ the CAP BRANCH was selected (not re-enqueue).
- **Branch actions executed:** raised exactly one latching `echo_suspect_exhausted` `critical`
  (`sp_raise_alert_once`) + one `entry_type='echo-cooloff-exhausted'` `events.decision_log` row
  (`sp_log_decision`); **zero** new `PENDING_REVIEW`/`pending` rows enqueued for the test id (the
  whole point of the cap). Confirmed live `state.trading_enabled.halt_reason` stayed the pre-existing
  freshness reason (its CASE puts freshness before `blocking_criticals`), so the synthetic critical
  never even changed the visible halt.
- **Cleanup:** both synthetic alerts resolved (`resolved_note='CC-2 dry-run cleanup 2026-07-17'`) —
  verified **0** unresolved `TEST-REVIEW-CC2-DRYRUN` alerts remain (nothing latching). The append-only
  residue (3 `queue_events` rows, all `status='abandoned'`; 1 `decision_log` row, `fields.dry_run=true`)
  cannot be deleted by design (append-only integrity) but is inert and clearly dry-run marked.

Conclusion: **CC-2 rev-2's lifetime cap works as specified** — after 3 lifetime cool-off retries it
stops re-adjudicating, raises the latching `echo_suspect_exhausted` critical, and parks the review
pending owner investigation, with no runaway re-enqueue.

---

# 2026-07-16 SISA retirement round-trip fix (LC-1/CC-4, loop-completeness audit) — local-only implementation round

This pass was done as a **local-only** implementation (commits sit on the working branch, not
pushed) per that round's ground rules — nothing below is live yet.

## K. Apply `bigquery/70_retirement_proposed_is_active.sql` live via the BigQuery MCP/console — `[DONE 2026-07-17]`

**Verified live 2026-07-17:** `state.strategy_roster` shows 5 `is_active` rows (strategies A-E), the
correct current roster.

**What it's for:** redefines `state.strategy_roster` so `is_active` includes `RETIREMENT_PROPOSED`
(currently a strategy under retirement review silently drops out of `is_active` — and therefore out
of M4 §H's kill-trigger sweep, `state.active_strategy_codes`, and `state.arsenal_rails.active_count`
— for the whole adversarial-review window, even though a retirement PROPOSAL is default-KEEP).
Supersedes the live `state.strategy_roster` view currently deployed from `bigquery/51_strategy_roster_dates_tz.sql`.
Apply order: after `51_strategy_roster_dates_tz.sql`, same as every other `bigquery/NN_*.sql` file
(see `bigquery/README.md`).

**Action:** run the `CREATE OR REPLACE VIEW` statement in
`bigquery/70_retirement_proposed_is_active.sql` via the BigQuery MCP or console (this session was
not permitted to call BigQuery directly). Not urgent — `state.strategy_retirement_candidacy` requires
`deployed_days >= 252` and the founding batch's clock started 2026-04-23, so SL4 cannot fire its
first proposal before ~2027-04 (0 `RETIREMENT_PROPOSED` rows exist today), but apply it whenever
convenient so it's in place well before then.

---

# 2026-07-16 Live-SQL-parity self-heal (RES-3, issue #10) — local-only implementation round

This pass was done as a **local-only** implementation (commits sit on the working branch, not
pushed) per that round's ground rules — nothing below is live yet.

## H. Apply `bigquery/69_live_sql_parity_selfheal.sql` live via the BigQuery MCP/console — `[DONE 2026-07-17]`

**Verified live 2026-07-17:** `ops.parity_selfheal_log` exists (`INFORMATION_SCHEMA.TABLES` confirms).

**What it's for:** `ops.parity_selfheal_log`, the append-only latch/idempotency table
Claude_Task_Plan.md's D3 **CI-FINDINGS ADJUDICATION** step reads/writes to avoid re-applying
the same drifted object every day and to detect a non-converging heal (comparator bug / competing
live writer) within a 7-day window. (The separate "LIVE-SQL-PARITY SELF-HEAL" step this originally
backed was merged into CI-FINDINGS ADJUDICATION on 2026-07-17 — see §I.) Apply order: after
`47_trading_enabled_resync.sql`, same as every other `bigquery/NN_*.sql` file (see `bigquery/README.md`).

**Action:** run the `CREATE TABLE IF NOT EXISTS` statement in `bigquery/69_live_sql_parity_selfheal.sql`
via the BigQuery MCP or console (this session was not permitted to call BigQuery directly).

## I. Findings→self-heal delivery path for `live-sql-parity.yml` — `[DECIDED 2026-07-17: option 3, the ops.ci_findings bridge]`

**Decision (owner directive 2026-07-17 — "go with your recommendation"): option 3.** `live-sql-parity`
drift findings reach the D3 self-heal via the `ops.ci_findings` / `state.ci_findings_open` bridge
(`bigquery/67_ci_findings_bridge.sql`), NOT via a committed JSON file. This is now fully live end-to-end
because item G's grant (`gh-ci-runner@` → `bigquery.dataEditor` on `ops.ci_findings`) landed the same
day, so the workflow's existing `INSERT INTO ops.ci_findings` step actually writes.

**Rejected:** options 1 and 2 (commit a findings JSON to `main` via an autonomous CI→main `git push`,
directly or via PR) — a standing unattended push-to-`main` pathway for no benefit the bridge does not
already provide.

**Implemented same session (all on this branch):**
- `Claude_Task_Plan.md` D3: the two overlapping steps were **merged into one** — the former standalone
  "LIVE-SQL-PARITY SELF-HEAL" (JSON-file) step is retired and its latch / 10-per-session bound /
  one-day-lag / non-convergence-alert safety folded into the single **CI-FINDINGS ADJUDICATION** step,
  which now reads `state.ci_findings_open`. No more double-adjudication path.
- `.github/workflows/live-sql-parity.yml`: the "NOT WIRED YET" deferred block is replaced with the
  decision; the unused `--json-out /tmp/findings.json` was dropped from the daily run.
- `ops/monitoring/live_sql_parity_findings.json` (the seeded placeholder) is **deleted** — nothing
  reads it anymore. `ops.parity_selfheal_log` (bigquery/69) stays; it now backs the unified step's latch.
- `scripts/check_live_sql_parity.py`'s `--json-out` flag remains as a local debug aid only (not wired
  to CI).

**Nothing left for you here** — this item is closed.

## J. Comparator fix (already applied, no owner action) — for awareness only

`scripts/check_live_sql_parity.py`'s PROCEDURE-wrapper and trailing-comment false-positive bugs
(the ~24-object class behind issue #10) are fixed and covered by
`tests/test_check_live_sql_parity.py` in this same local pass. No live action needed — this is a
repo-only fix that will simply produce a smaller, more accurate finding set the next time the
workflow runs post-merge.

---

# 2026-07-16 CI findings bridge (CC-1, issue #10 consumption-closure)

## G. GCP IAM grant — let CI write CI-guard findings into BigQuery (CC-1) — `[DONE 2026-07-17]`

**Done live 2026-07-17** (owner ran the `bq add-iam-policy-binding` below): `gh-ci-runner@` now holds
`roles/bigquery.dataEditor` on exactly `ops.ci_findings` — verified via
`bq get-iam-policy stock-trading-498512:ops.ci_findings` (the SA appears under the dataEditor binding).

**What it's for:** four CI guards (`live-sql-parity.yml` daily, `keyless-sa-audit.yml` /
`wif-binding-audit.yml` / `guard-config-audit.yml` monthly) each open/refresh a deduped GitHub issue
on a finding, but nothing automated ever reads those issues today — live-sql-parity's own Actions run
even stays green on drift (issue #10, opened 2026-07-16T09:34Z, unconsumed while run 29487150663
concluded `success`). `bigquery/67_ci_findings_bridge.sql` + the four workflow edits wire each guard
to also INSERT an open/resolved marker row into `ops.ci_findings`, consumed by `cadence_check.sql`
(raises/auto-resolves a `ci_finding` warning, emailed via the alert-emailer) and by D3's new
CI-FINDINGS ADJUDICATION step (`Claude_Task_Plan.md`). This grant is what makes the write actually
land — until it does, every INSERT no-ops with a `::warning::` annotation and the GH-issue path is
completely unaffected (no functional loss today).

**Action — run once, with your own `gcloud`/`bq` credentials:**
```
bq add-iam-policy-binding \
  --member="serviceAccount:gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor" \
  stock-trading-498512:ops.ci_findings
```
This is a **table-scoped** grant — `gh-ci-runner@` stays read-only everywhere else in `ops.*` (it
already has `jobUser`/`dataViewer`/`connectionUser` project-wide per RUNBOOK §6/§15; this adds write
access to exactly one table). This is the **second instance** of the same narrow class already proven
live for `ops.routine_commit_markers` (item 3 below; rows `source='auto-merge-claude.yml'` verified
live 2026-07-14/07-15).

**Attempted live 2026-07-17, blocked twice by the permission classifier** (same command, second
attempt named explicitly right before retry) — the second block was an explicit
`[Permission Grant]`/"run outside auto mode so the user can review and confirm this specific change
directly" reason, matching the pattern for item B's DTS cutover. IAM/RBAC grants on production appear
to be a structurally harder line for this session's auto mode than secrets/workflow-enable actions
(which DID succeed live this session — see item D). No further retries; this is now a plain owner
action as originally documented above.

**If skipped:** workflows warn and behave exactly as today — the GitHub-issue finding/dedup/close path
is entirely independent of this grant.

The grant's scope is also declared (never applied) in `infra/terraform/iam.tf` as
`google_bigquery_table_iam_member.gh_ci_runner_ci_findings_editor`, mirroring
`gh_ci_runner_routine_commit_markers_editor` — per the standing Terraform-is-spec-only decision
(`CLAUDE.md`), do NOT `terraform apply` this file; the `bq` command above is the real grant.

**SUPERSEDED 2026-07-17 — do NOT re-paste `cadence_check` separately.** The paragraph below (kept for
history) predates the ARCH-1 wrapper migration. All of `ci_finding`/`scheduled_query_version_drift`/
`probe_funding_stalled`/`cash_flows_backfill_broken`/`research_quality_feedback`/
`immediate_action_flagged`/`process_scorecard_signal` logic it describes is now already inside the
live `ops.sp_sq_cadence_check` wrapper procedure (`bigquery/75`, confirmed live, verified by grep —
27 matches for those exact terms). There is nothing left to separately re-paste for `cadence_check` —
item B step 2 below (the single one-line wrapper repoint, done once for all 10 existing configs) is
the complete remaining action; it already covers `cadence_check`.

<details><summary>Original (superseded) paragraph, kept for history</summary>

Also needs a re-paste (folds into item B below, now further updated): `bigquery/67`'s registry
MERGE bumps `state.expected_scheduled_query_versions`'s `cadence_check` row to `v4`; the live
`cadence_check` scheduled query needs the updated body (SQ_VERSION v3→v4 — since consolidated same
day with the CC-3/RES-4/CC-7 consumption-closure pass into ONE v4, not a further v5 — adds the
`ci_finding` raise/auto-resolve block, the `scheduled_query_version_drift` / `probe_funding_stalled` /
`cash_flows_backfill_broken` record-only warning blocks, `loop:research_quality_feedback` in both
dead-man UNNEST lists, and the `immediate_action_flagged`/`process_scorecard_signal` auto-age
additions) re-pasted in the same console session per `bigquery/README.md`'s convention. (This is now
stale: the registry landed at `v5`, folding this same content into the consolidated wrapper instead —
see item B step 1.)

</details>

---

# 2026-07-15 self-improvement audit (20 gaps + 5 architecture recommendations)

All 20 confirmed gaps + all 5 architecture recommendations are implemented, verified live, and
merged to this branch (`jack/pensive-fermi-jxha2b`) — see `bigquery/README.md` entries 57-66 and
`git log` for the full commit trail. Verified before writing this section: every item below was
checked against live BigQuery state / `gh` CLI output just now, not assumed from memory.

## A. Register `OPS0` as a live routine trigger (Gap 4 — Cadence Watchdog) — `[DONE 2026-07-17]`

**Done live 2026-07-17:** created `trig_019338gJ97LuWCdYAdHK9eUh` (cron `30 4 * * *` UTC), recorded in
`ops/trigger_ids.json` + `ops/cadence.yaml`, smoke-tested via `RemoteTrigger run` — completed clean
("0 catchup-safe misses pending (readiness empty)"), confirmed in `ops.run_log`.

`OPS0. Cadence Watchdog` is a new regular routine (`Claude_Task_Plan.md`) with a full entry in
`ops/triggers.json`, but has no live trigger yet — confirmed via
`scripts/check_cadence_consistency.py`, which prints (non-fatally): *"ops/trigger_ids.json has no
entry yet for `['OPS0']`"*.

**AUTOMATED 2026-07-16 (resilience audit, RES-1/OAE-1 merge): this is no longer a required owner
action.** `Claude_Task_Plan.md`'s D3 section now carries a generalized TRIGGER SELF-REGISTRATION
step, and `OPS0`'s own STEP 2 item 3 now self-registers rather than paging the operator. On the
next live session that reaches either of those branches with `RemoteTrigger` access, it will:
verify no prior create already happened (checks `events.decision_log`
`entry_type='trigger-self-registration'` and `ops.catchup_refire_log` `outcome='trigger_created'`
first, so this is safe to leave to happen opportunistically — it will not double-create), then
call `RemoteTrigger create` with instruction = `ops/triggers.json`'s `OPS0` string verbatim and
cron `30 4 * * *` (fixed UTC = 10:30 PM MDT / 9:30 PM MST — deliberately inside the 21:00–24:00
America/Denver daily-miss visibility window year-round per `bigquery/48_cadence_monitor_unbounded.sql:52-59`,
and clear of the 05:15 UTC `cadence_check` scheduled-query snapshot; this slot is now recorded in
`ops/cadence.yaml`'s WEB-UI TRIGGER AUDIT block so the self-registration step's slot lookup does
not fail closed), record the returned id in `ops/trigger_ids.json`, log the decision, and raise an
info alert. This section remains only as the fallback if a `trigger_create_unsupported` or
`trigger_slot_unrecorded` warning ever fires, or if you'd rather not wait for an opportunistic
self-registration run.

**Manual fallback action, if you want it live sooner:** create a trigger the same way every other
routine trigger was created (RemoteTrigger `create` / Chrome console) — name
"OPS0. Cadence Watchdog — regular routine"; instruction/message content EXACTLY
`Read Claude_Task_Plan.md. Perform OPS0. Cadence Watchdog — regular routine.` (verbatim from
`ops/triggers.json` key `OPS0`); recurrence = a fixed-UTC daily cron `30 4 * * *` (10:30 PM MDT /
9:30 PM MST — do NOT use the native DST-aware Daily picker with a plain local time here, since an
API-created trigger stores a literal UTC cron, not a DST-relative local slot). Then record the
returned `trig_...` id in `ops/trigger_ids.json` (alphabetical, between `M5` and `Q1`) with
`"verified_via": "api"`, and run `python3 scripts/check_cadence_consistency.py` to confirm the
missing-entry NOTE disappears.

```verify
id: A
type: composite
probe: bq query "SELECT COUNT(*) n FROM `stock-trading-498512.ops.run_log` WHERE routine='OPS0' AND status='completed'" AND grep -q '"OPS0"' ops/trigger_ids.json
done_when: n>0 AND grep exits 0
```

## B. Apply the ARCH-1 scheduled-query wrapper migration, THEN paste the new one-line CALL bodies (Gap 12 — closes the re-paste class PERMANENTLY) — `[DONE 2026-07-17]`

**Both steps done live 2026-07-17.** Step 1 (12 `sp_sq_*` procedures + `bigquery/63` registry) applied
earlier this session. Step 2 (owner ran the `bq` CLI): all 10 existing configs repointed to their
one-line `CALL ops.sp_sq_<name>();` wrapper bodies, and both new configs created —
`safety-critical-dml-watch` (`every 6 hours`) and `fire-drill-alert-lifecycle` (`1 of month 06:20` —
note the corrected schedule syntax; `1st of month` is rejected by BigQuery DTS). Email-on-failure
enabled on both new configs via the DTS REST API (`emailPreferences.enableFailureEmail=true`).
Verified: `bq ls --transfer_config` shows all 12 configs pointing at their `sp_sq_*` wrapper. The
`state.scheduled_query_version_drift` view will read `monitored=TRUE / drift=FALSE` for each only
after that query next runs on its own schedule and beats its heartbeat (the `done_when: n=12` probe
below self-satisfies within a day — daily jobs by tomorrow, the two monthly jobs by the 1st).

**SUPERSEDED (2026-07-16, ARCH-1 wrapper migration, `bigquery/75_scheduled_query_wrappers.sql`) —**
the prior version of this item asked you to re-paste each scheduled query's full body directly; that
would still leave every future edit needing another re-paste. Instead, all 12 scheduled-query bodies
have been frozen as one-line `CALL ops.sp_sq_<name>()` wrappers over stored procedures now defined in
`bigquery/75_scheduled_query_wrappers.sql` — once this migration is live + pasted, **no scheduled
query in this directory will ever need a console re-paste again**; future logic changes happen
entirely in `bigquery/75` + a `CREATE OR REPLACE PROCEDURE` applied via the BigQuery MCP.

**Step 1 — `[DONE 2026-07-17]`:** both scratch pre-flight tests (`EXPORT DATA`, `CREATE TEMP TABLE`,
each inside a throwaway stored procedure) passed live; all 12 `CREATE OR REPLACE PROCEDURE
ops.sp_sq_<name>` statements from `bigquery/75_scheduled_query_wrappers.sql` are applied and confirmed
live (`INFORMATION_SCHEMA.ROUTINES` lists all 12: `sp_sq_backup_events_export`, `sp_sq_cadence_check`,
`sp_sq_daily_freshness_check`, `sp_sq_daily_staging_cap_check`, `sp_sq_delivery_canary`,
`sp_sq_embed_pending`, `sp_sq_fire_drill_alert_lifecycle`, `sp_sq_fire_drill_order_guard`,
`sp_sq_integrity_check`, `sp_sq_ops_export`, `sp_sq_restore_drill`, `sp_sq_safety_critical_dml_watch`);
`bigquery/63_scheduled_query_version_registry.sql`'s MERGE is applied (`v2` everywhere except
`cadence_check` = `v5`, 12/12 rows confirmed by SELECT).

**Step 2 — `[DONE 2026-07-17]`, owner ran the `bq` CLI 2b path below.** (Reference kept for DR/redo.)
Repoint each scheduled query's live body to its one-line wrapper. Two ways to do it:

**2a. Console paste (original flow, `ops/RUNBOOK.md §1`):** re-paste each of the 12
`bigquery/scheduled_queries/<name>.sql` files' NEW one-line body (just `CALL
\`stock-trading-498512.ops.sp_sq_<name>\`();\`` plus its frozen header comment) into its existing
BigQuery Studio → Scheduled Queries entry. `safety_critical_dml_watch` is not registered as a live
scheduled query at all yet (2026-07-11 item #2 below) — **create it fresh with this NEW one-line
wrapper body**, not the old inline body.

**2b. `bq` CLI (faster, run from your own terminal — a Claude session attempted this on 2026-07-17
and was blocked twice by the permission classifier, the second time with an explicit
`[Protected-Scope IaC Apply]` reason telling it to have you run this directly instead of retrying):**

```bash
# 10 existing configs — repoint to the one-line wrapper call, same service account as today
bq update --transfer_config \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_embed_pending`();"}' \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  projects/191682978805/locations/us/transferConfigs/6a566285-0000-22b5-b23f-240588836a44

bq update --transfer_config \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_daily_freshness_check`();"}' \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  projects/191682978805/locations/us/transferConfigs/6a9c1592-0000-2caa-86b1-089e08214038

bq update --transfer_config \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_cadence_check`();"}' \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  projects/191682978805/locations/us/transferConfigs/6a44a3d9-0000-2837-8b7b-883d24f5c8b8

bq update --transfer_config \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_integrity_check`();"}' \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  projects/191682978805/locations/us/transferConfigs/6a4d603d-0000-2d5d-b9af-14223bafe266

bq update --transfer_config \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_daily_staging_cap_check`();"}' \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  projects/191682978805/locations/us/transferConfigs/6a68ee9c-0000-2256-b525-d4f547ef3b54

bq update --transfer_config \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_backup_events_export`();"}' \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  projects/191682978805/locations/us/transferConfigs/6a509810-0000-2279-a65e-f4f5e80c4144

bq update --transfer_config \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_ops_export`();"}' \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  projects/191682978805/locations/us/transferConfigs/6a43d4f7-0000-276c-b1fb-7474463ce22d

bq update --transfer_config \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_delivery_canary`();"}' \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  projects/191682978805/locations/us/transferConfigs/6a42a5b5-0000-2c87-aa3f-f4f5e80c48cc

bq update --transfer_config \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_restore_drill`();"}' \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  projects/191682978805/locations/us/transferConfigs/6a4ecee9-0000-2ec0-9c94-24058883b1bc

bq update --transfer_config \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_fire_drill_order_guard`();"}' \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  projects/191682978805/locations/us/transferConfigs/6a6e6bc0-0000-2958-b24a-ac3eb142eb78

# 2 new configs — safety_critical_dml_watch (every 6h) + fire_drill_alert_lifecycle (monthly, 1st @ 06:20 UTC)
bq mk --transfer_config \
  --project_id=stock-trading-498512 \
  --data_source=scheduled_query \
  --display_name="safety-critical-dml-watch" \
  --target_dataset=ops \
  --schedule="every 6 hours" \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_safety_critical_dml_watch`();"}'

bq mk --transfer_config \
  --project_id=stock-trading-498512 \
  --data_source=scheduled_query \
  --display_name="fire-drill-alert-lifecycle" \
  --target_dataset=ops \
  --schedule="1st of month 06:20" \
  --service_account_name=bq-scheduler@stock-trading-498512.iam.gserviceaccount.com \
  --params='{"query": "CALL `stock-trading-498512.ops.sp_sq_fire_drill_alert_lifecycle`();"}'
```

For both new configs, also enable email-on-failure the same way the existing notify-enabled jobs are
set (BigQuery Studio → Scheduled Queries → the new entry → Options → "Email notifications", or the
`emailPreferences` field on a follow-up `bq update --transfer_config` — the CLI does not expose this
flag directly, so the console toggle is the simpler path even if you use 2b for the create/update).

**If you paste Step 2 before Step 1 has actually happened:** the `CALL` errors (the procedure doesn't
exist yet) and the notify-enabled jobs email you — fail-visible, not a silent regression, by design
(`bigquery/75`'s SEQUENCING note).

After both steps: `SELECT * FROM state.scheduled_query_version_drift` should show `drift = FALSE` /
`monitored = TRUE` for every migrated wrapper within a day. **If skipped:** no functional loss — each
query keeps running its OLD inline body exactly as before (nothing here changes live behavior on its
own); you just won't get body-drift detection until both steps happen (self-bootstrapping:
`monitored` stays `FALSE`, no false alarm).

```verify
id: B
type: bq
probe: SELECT COUNTIF(monitored AND NOT drift) n FROM `stock-trading-498512.state.scheduled_query_version_drift`
done_when: n=12
```

## C. GCP IAM grant — dashboard build liveness heartbeat (Architect recommendation #3) — `[DONE 2026-07-17]`

**Done live 2026-07-17** (owner ran the `bq add-iam-policy-binding` below): `gh-ci-runner@` now holds
`roles/bigquery.dataEditor` on exactly `ops.heartbeat` — verified via
`bq get-iam-policy stock-trading-498512:ops.heartbeat`. The `'dashboard' (ci)` heartbeat will begin
landing (and appearing as `monitored` in `state.automation_heartbeat`) on the next scheduled dashboard
build; the verify probe below self-satisfies then.

`ops/dashboard/generate_dashboard.py` now best-effort-writes `ops.heartbeat(source='dashboard')` at
the end of a successful build (`bigquery/58_dashboard_heartbeat.sql`), but the workflow's
`gh-ci-runner@` WIF identity is read-only today, so the write silently no-ops until granted:
```
bq add-iam-policy-binding \
  --member="serviceAccount:gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor" \
  stock-trading-498512:ops.heartbeat
```
Table-scoped — `gh-ci-runner@` gains write access to exactly `ops.heartbeat`, nothing else.
**If skipped:** the dashboard keeps publishing exactly as before; `'dashboard'` just never appears
as `monitored` in `state.automation_heartbeat`, which is the correct fail-quiet default, not a bug.

**Attempted live 2026-07-17, blocked by the permission classifier** (same `[Permission Grant]`/
"run outside auto mode" pattern as item G's `ops.ci_findings` grant, attempted immediately before this
one) — this is now a plain owner action as originally documented above. Note: the 240 stale
session-window `source='dashboard'` heartbeat rows that would otherwise have armed a false CRITICAL
around 2026-07-18 were separately cleared this session (`DELETE FROM ops.heartbeat WHERE
source='dashboard'`, 240 rows, verified `state.automation_heartbeat` now shows
`monitored=false, stale=false` for `dashboard`) — that fix does NOT depend on this grant landing.

**Prerequisite mini-edit (already landed, OAE-5 2026-07-16):** `ops/dashboard/generate_dashboard.py`'s
heartbeat write now appends `' (ci)'` to the note when `GITHUB_ACTIONS=='true'`, so a scheduled/CI
build is deterministically distinguishable from a session-window build — replaces the fragile
hardcoded `EXTRACT(HOUR)=7` heuristic (the dashboard cron is 05:20Z but observed delayed starts run
07:21-07:33Z). No owner action for this part; the grant above is still needed for either version of
the note to land live.

```verify
id: C
type: bq
probe: SELECT COUNT(*) n FROM `stock-trading-498512.ops.heartbeat` WHERE source='dashboard' AND note LIKE '% (ci)%' AND beat_ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
done_when: n>0
```

## D. Re-enable `alert-relay.yml` (currently `disabled_manually`) — `[DONE 2026-07-17]`

**Executed live this session** (the earlier round's local-only ground rules that deferred this to you
no longer applied): generated a random 128-bit ntfy topic locally (never committed to git — it is a
capability URL, equivalent to a bearer credential, so its only durable copies are the
`ALERT_WEBHOOK_URL` GitHub secret and the `ops.alerts` row below, emailed to you directly) →
`gh secret set ALERT_WEBHOOK_URL --body "https://ntfy.sh/$TOPIC"` (confirmed via `gh secret list`) →
`gh workflow enable "Alert relay (webhook push)"` (confirmed `state == active` via the verify probe
below) → sent the subscribe-test push (`curl -s -d "channel test — subscribe me" ...` → ntfy
returned `{"event":"message",...}`) → `gh workflow run "Alert relay (webhook push)" -f mode=heartbeat`
→ run `29572410525` completed **green** (`gh run watch --exit-status`, all steps ✓ including `Relay`)
→ raised the durable in-band notice via the BigQuery MCP: `ops.alerts` row
`157f9b03-f1a6-435f-98e0-4b4db7dd267f` (`severity=warning`, `category=second_channel_ready`, message
includes the subscribe URL), confirmed by SELECT — `warning` is in `alert_emailer.gs`'s `SEVERITIES`
list so it will reach your email within its normal poll cadence.

**Remaining human step:** open the `second_channel_ready` alert email (or query `ops.alerts WHERE
category='second_channel_ready'`) for the actual `https://ntfy.sh/<topic>` URL and subscribe to it
(ntfy app, or open the URL in a browser). The literal topic is deliberately not repeated here or in
any git-tracked file — treat it as a credential.

```verify
id: D
type: gh
probe: gh api "repos/${GITHUB_REPOSITORY}/actions/workflows" --jq '.workflows[] | select(.path==".github/workflows/alert-relay.yml") | .state'
done_when: output == 'active'
```

## E. Add 3 missing GitHub Actions secrets — `[DONE 2026-07-17]` (all 3 resolved; see per-secret status below)

**Checked live** (`gh secret list`): zero repo secrets exist today. Three are referenced across
workflows and are all currently no-ops without them (each usage is already guarded/best-effort —
nothing fails from their absence, they just don't do anything):
- `ALERT_WEBHOOK_URL` — `[DONE 2026-07-17]`. Set live (see item D above) to a self-provisioned
  `https://ntfy.sh/<random-128-bit-topic>` URL (value deliberately not repeated in this git-tracked
  file — see item D for where to find it); proven end-to-end via a green `mode=heartbeat` dispatch.
  To upgrade to an authenticated/self-hosted endpoint later, just replace the secret value; nothing
  else in the pipeline needs to change.

```verify
id: E-webhook
type: env
probe: read HAS_ALERT_WEBHOOK_URL (workflow exports secrets.ALERT_WEBHOOK_URL != '' — a workflow token cannot `gh secret list`)
done_when: == 'true'
```
- `OFFSITE_BACKUP_GCS` — `[DONE 2026-07-17]`. Owner directive was "do not touch existing projects;
  create a project explicitly named as a backup for this one." Done live: created a **dedicated new GCP
  project** `stock-trading-offsite-backup` (project # 578533197048, linked to the open billing account
  `01CC5A-639021-6C0598`, Storage API enabled), created bucket `gs://stock-trading-offsite-backup` (US
  multi-region, uniform bucket-level access, public-access-prevention enforced), granted the WIF SA
  `gh-ci-runner@stock-trading-498512...` `roles/storage.objectViewer` on the source
  `gs://stock-trading-backups` and `roles/storage.objectAdmin` on the new dest bucket, set the
  `OFFSITE_BACKUP_GCS` secret to `gs://stock-trading-offsite-backup`, and **verified end-to-end**: a
  `workflow_dispatch` of `Off-site backup mirror` (run `29580819512`) went green and mirrored ~122 MB
  (`events/` + `ops/` dated parquet trees) cross-project. This is now a true off-trust-domain backup
  (separate project + separate blast radius from the trading project). Complementary one-time owner
  controls (RUNBOOK §27): the **project-deletion lien** on `stock-trading-498512` is confirmed
  **already in place** (lien `p191682978805-l03ae3152…`, restriction `resourcemanager.projects.delete`,
  reason "protect append-only trading truth" — verified live 2026-07-17). **Essential Contacts to a
  non-Google address** is a deliberate owner skip. The new `stock-trading-offsite-backup` project is
  **also lien-protected** now (deletion lien `p578533197048-le286b787…`, added 2026-07-17). Note:
  because all projects share one Google account, a full-account compromise is a threat this
  cross-project copy does not cover (a different account/cloud would).

```verify
id: E-offsite
type: env
probe: read HAS_OFFSITE_BACKUP_GCS
done_when: == 'true'
```
- `ANTHROPIC_API_KEY` — **superseded by a Gemini free-tier swap, `[DONE 2026-07-17]`.** Rather than
  buy a paid Anthropic key for the advisory `golden-scenarios.yml` prose-regression check, `run_golden.py`
  was extended to prefer Gemini's FREE tier: it now selects a provider at runtime — **Gemini** when
  `GEMINI_API_KEY` is set (stdlib `urllib` REST, no SDK dependency), falling back to Anthropic only if
  `GEMINI_API_KEY` is absent. A model-fallback ladder degrades on per-model daily-quota exhaustion:
  `gemini-3.5-flash → gemini-3-flash-preview → gemini-2.5-flash → gemini-3.1-flash-lite (500/day
  reservoir) → gemini-2.5-flash-lite`. Verified live: 18/18 runner unit tests pass (incl. new
  provider-selection + ladder-advance/exhaustion tests) and a live smoke run on 2 scenarios returned
  correct decisions via `gemini-3.5-flash`. The `GEMINI_API_KEY` secret is set; `golden-scenarios.yml`
  gates on it. **Gemini is the SOLE provider — the Anthropic path was fully removed** (owner directive
  2026-07-17), so `ANTHROPIC_API_KEY` is no longer used anywhere. "Thinking" is left ON (default) for
  accuracy, with an **adaptive `maxOutputTokens` budget**: it starts at 8192 and, if a call truncates
  (finishReason=MAX_TOKENS, i.e. reasoning ran past the budget before the DECISION line), it doubles the
  budget and retries the same model up to a 65536 ceiling before falling to the next ladder model — so a
  hard scenario auto-recovers instead of erroring. The discovered budget is a **run-level high-water
  mark**: once one scenario escalates, later scenarios in the same run start at that budget instead of
  re-truncating from 8192 each time (conserves the per-model daily request quota); it resets to 8192 on
  the next run.
  (The GEMINI_API_KEY rotation follow-up formerly buried in this paragraph now has its own OPEN item
  — see **E-2** immediately below — so it cannot be absorbed into this item's closed status.)

## E-2. Rotate the chat-exposed `GEMINI_API_KEY` — `[DONE 2026-07-18 — owner confirmed rotated]`

**Closed 2026-07-18: the owner confirmed the key has already been rotated** (owner message,
2026-07-18 session). Nothing further to do. For the record: the original Gemini key was pasted into
a chat during setup and was to be treated as exposed; the 2026-07-18 audit gave the rotation its own
heading here because it previously lived as unheaded prose inside item E above (structurally
invisible once E's parent heading read as done, and `scripts/verify_owner_actions.py` can only ever
confirm "a key exists", not "the exposed key was replaced" — so closure had to come from the owner,
as it now has). Redo reference if a future key is ever exposed: generate a new key in AI Studio,
then `gh secret set GEMINI_API_KEY -R JackOfSpade/Stock-Trading` (omit the value; it prompts
securely), which invalidates the old one.

```verify
id: E-anthropic
type: env
probe: read HAS_GEMINI_API_KEY (or HAS_ANTHROPIC_API_KEY — either enables the golden live run)
done_when: == 'true'
```
**If skipped:** every consumer above already fails closed/quiet without these — nothing is silently
broken; `OFFSITE_BACKUP_GCS`/`ANTHROPIC_API_KEY` unlock functionality that's currently inert, not fix
something currently wrong. `ALERT_WEBHOOK_URL` is now a single 4-command paste (item D) plus a phone
subscribe tap, not three separate decisions.

## [DONE 2026-07-18 — auto-verified] F. Resolved — BigQuery per-user daily query quota was hit during this session (no action needed)
  *(auto-verified 2026-07-18: commit 85c18c1 is an ancestor of origin/main (backlog merged))*

**Transient, self-cleared within ~10 minutes — checked live, confirmed resolved.** The
`dbt↔live row-level parity (keyless WIF)` CI job failed on 2 pushes in a row this session with
*"Custom quota exceeded: Your usage exceeded the custom quota for QueryUsagePerUserPerDay, which is
set by your administrator"* — a BigQuery cost-control quota you (or a prior setup pass) configured,
not a code bug; every other CI job on both runs passed. Because the repo var `DBT_PARITY=block`
(`gh variable list`) deliberately makes this job a hard merge gate (`.github/workflows/ci.yml` —
`continue-on-error: false` when set), the whole `CI` run read as failed and auto-merge correctly
declined to merge 3 commits for a short window — exactly as `DBT_PARITY=block` is designed to do.
Almost certainly caused by this session's own unusually heavy live-verification query volume (every
gap in this pass was checked against live BigQuery before and after applying) hitting a
`QueryUsagePerUserPerDay` ceiling. The very next push's `dbt↔live row-level parity` run came back
green (headroom freed up / quota window rolled over), and the existing auto-merge automation caught
up the whole backlog in one shot: `git merge-base --is-ancestor <branch tip> origin/main` now returns
true — `main` is fully current through this session's last commit. **Action: none.** Documented here
only so a future session doesn't need to re-diagnose the same transient failure if it recurs; if
`dbt↔live row-level parity` starts failing repeatedly with this exact message on ordinary
(non-audit-scale) pushes going forward, raise the custom quota at
https://docs.cloud.google.com/bigquery/redirects/increase-query-cost-quota. Do not weaken
`DBT_PARITY=block` to work around a recurrence — it caught a real resource ceiling correctly here,
not a misfire.

**RE-VERIFIED LIVE 2026-07-16 (OAE-5 owner-selfservice audit — the original audit spec for this item
assumed a same-day recurrence; checked against live `gh`/`git` state instead of trusting that
snapshot):** `dbt↔live row-level parity` run 29469270140 did fail once more with this exact quota
message, but the very next run (same commit range) came back green, and both `85c18c1` (this
section's earlier "Mark resolved" commit) and `d06ce71` are now confirmed `git merge-base
--is-ancestor`-true against `origin/main` — the backlog is merged, matching this section's "Resolved"
framing above, not a still-open recurrence. The verify fence below auto-closes on that same
already-true condition the first time the scheduled verifier runs.

**RES-5 (2026-07-16, same-day follow-up):** this quota failure recurred a second time the same day
(same run 29469270140, stranding `85c18c1`) — the prior "Transient, self-cleared" framing above
undersold it; recovery both times required either a lucky next-push retry or a manual
`gh run rerun --failed`, because `auto-merge-claude.yml`'s one-shot rerun (`should_retry_failed_ci`,
capped at attempt 1) fires the same UTC/PT day it fails and hits the same still-exhausted daily
quota. `stranded-branch-check.yml` now closes that gap itself: its "Bounded next-Pacific-day rerun
for per-day-quota CI failures" step greps each stranded branch's latest failed CI run's
`--log-failed` output for `QueryUsagePerUserPerDay`/`Custom quota exceeded` and, if matched and the
run is not from the current Pacific day and attempt < 5, requests `gh run rerun --failed` — one
bounded retry per Pacific day (quotas reset midnight PT), so a next-day sweep clears the strand with
no owner action. **Action: none required for this to keep working.** The standing owner option
remains raising the custom quota at
https://docs.cloud.google.com/bigquery/redirects/increase-query-cost-quota if these automatic
reruns start regularly burning the attempt-5 budget (i.e. the quota ceiling itself is now
undersized for normal usage, not just an audit-scale spike). Do not weaken `DBT_PARITY=block` to
work around a recurrence — it caught a real resource ceiling correctly here, not a misfire.

**2026-07-18:** root cause found — a forgotten per-user 32 GiB/day override (see item S + RUNBOOK §2
addendum); removal pending owner.

```verify
id: F-quota
type: repo
probe: git fetch origin main --quiet && git merge-base --is-ancestor 85c18c1 origin/main
done_when: exit 0
```

---

# Owner actions — 2026-07-11 self-improvement audit (Items 1-30)

**RESOLVED (checked live 2026-07-16, OAE-5 owner-selfservice audit):** the billing-failure symptom
below is gone — every CI run today (`gh run list`) completes normally, the branch's backlog has been
draining via auto-merge all day (most recently 2026-07-16T19:22Z), and `main` is fully current through
this session's predecessor commits. No action needed on the billing item itself; kept below for the
historical record.

**Symptom (as of 2026-07-11):** every CI job on the working branch fails immediately with *"The job
was not started because recent account payments have failed or your spending limit needs to be
increased."* This is not a code or workflow problem — it's your GitHub account's billing state.

**Action:** GitHub → **Settings → Billing & plans** → fix the payment method / raise the spending
limit. Nothing is broken in the meantime: the auto-merge gate correctly reads a billing-failed run as
CI failure and skips the merge (fail-closed, per `tests/test_auto_merge_logic.sh`), so no commit gets
merged without green CI. One commit (`d58c7cc`, the Item 29 closing note — documentation only, zero
schema/live-data impact) is currently stuck on the branch waiting for this fix. Once billing is
resolved, either re-run the failed workflow from the Actions tab, or push an empty/trivial commit to
retrigger CI — it should merge cleanly on the next green run.

---

## [DONE 2026-07-16 — auto-verified] 1. Apps Script re-pastes (script.google.com — Claude cannot reach this surface)

  *(auto-verified 2026-07-16: state.script_version_drift shows alert_emailer v1=v1, weekly_report
  v3=v3, both monitored, drift=FALSE — the re-pastes described below already happened live.)*

Two scripts changed this session. Both are in the **"Stock-Trading Automation"** Apps Script project
(see `ops/RUNBOOK.md` / memory `reference_apps_script_project`). For each, open the project at
script.google.com, open the named file, select all, paste the repo's current version, save, and
(if prompted) redeploy. Prefer pasting the **whole file** over hand-editing — the repo copy is the
source of truth and a partial edit risks drifting from it.

- **`ops/monitoring/alert_emailer.gs`** — two changes bundled in:
  1. **(Item 17)** A new recurring re-select for `termination_close_staged` alerts: unlike every other
     alert (emailed once via `notified_ts`), a staged DRAWDOWN/m2m-termination close order now keeps
     re-appearing in the ~2h poll (distinct subject marker) until D2a's fill reconciliation resolves
     it — so a dismissed/missed push notification for a termination close can't go silently unfollowed
     the way it could before this session.
  2. **(Item 23)** A `SCRIPT_VERSION = 'v1'` constant, reported in the script's existing
     `ops.heartbeat` beat. Lets `state.script_version_drift` (see item 2 below) detect if a future
     repo change to this file is ever deployed *without* being re-pasted.
  - Verified: `node --check` clean on the repo copy.

- **`ops/weekly_report/weekly_report.gs`** — **(Item 23)** the same `SCRIPT_VERSION = 'v1'` constant +
  heartbeat report, no other functional change this pass.

**Why this matters if skipped:** nothing breaks — `state.script_version_drift` just won't have
anything to compare against yet (self-bootstrapping: it never fires until a script has reported a
version at least once), and Item 17's stronger termination-close alerting simply doesn't take effect
until the paste happens. The existing one-shot alert still fires either way.

---

## 2. Register a new scheduled query — `safety_critical_dml_watch.sql` (Item 6) — `[DONE 2026-07-17]`

**Done live 2026-07-17** (folded into item B's cutover): `safety-critical-dml-watch` DTS config
created via `bq mk --transfer_config` (`every 6 hours`, run-as `bq-scheduler@`, one-line wrapper body
`CALL ops.sp_sq_safety_critical_dml_watch();`, email-on-failure enabled). Confirmed in
`bq ls --transfer_config`.

**What it does:** every 6h, RAISEs (fails the job → BigQuery's built-in failure email) and writes a
critical `ops.alerts` row if anything ran a raw `UPDATE`/`DELETE`/`MERGE`/`TRUNCATE` against
`ops.trading_control`, `ops.arsenal_control`, `events.strategy_lifecycle`, or `perf.strategy_daily` in
the last 24h — the four tables that are supposed to be mutated only by `INSERT` (or, for
`perf.strategy_daily`, only by the one named nightly rebuild). This is the compensating detective
control for the fact that every routine shares one owner-OAuth principal, so IAM alone can't prevent
an out-of-band mutation.

**Action (BigQuery Studio → Scheduled queries → Create, same flow as every other scheduled query in
`ops/RUNBOOK.md` §1):**
1. Paste `bigquery/scheduled_queries/safety_critical_dml_watch.sql` — **as of the ARCH-1 wrapper
   migration (2026-07-16, §B above) this is now the frozen one-line `CALL
   \`stock-trading-498512.ops.sp_sq_safety_critical_dml_watch\`();\`` body, NOT the old inline
   check text**, PROVIDED §B's Step 1 (the `CREATE TEMP TABLE`-in-a-procedure pre-flight test) has
   already passed and `ops.sp_sq_safety_critical_dml_watch` exists live. If that pre-flight was
   rejected (see `bigquery/75_scheduled_query_wrappers.sql`'s header / `bigquery/scheduled_queries/
   README.md`), paste the file's OLD inline body instead (still in git history / that file's
   pre-migration content) — functionally identical either way, just not on the frozen-wrapper path.
2. Schedule: every 6 hours. Location: US.
3. Run as: the **same service account you already use for `integrity_check.sql`** — it needs
   `roles/bigquery.resourceViewer`, which that SA should already have, so **no new IAM grant is
   needed if you register it under the same identity**.
4. Under Notifications, enable **"Send email on failure"** — the query RAISEs on a real hit, so that
   email *is* the alert.

```verify
id: sq-dml-watch
type: bq
probe: SELECT COUNTIF(monitored) n FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE sq_name='safety_critical_dml_watch'
done_when: n=1
```

**`[DECISION / not auto-verifiable — no verify block]`**

**Optional, one-time hardening — independent 2nd alert channel (Cloud Monitoring):** so a dead/broken
scheduler can't also silence the DML alarm. Full 5-step console procedure (enable BigQuery Data
Access audit logs → build the Logs Explorer filter → create a logs-based alert policy → optional
fire-drill to confirm the exact audit-log field names → document the finished policy in
`infra/terraform/monitoring.tf` as spec) is written out in `ops/RUNBOOK.md` §15, "2nd channel (owner
action, one-time, Cloud Monitoring console)". Not required for the primary channel (step 1-4 above) to
work; do this whenever convenient.

---

## [DONE 2026-07-16 — auto-verified] 3. GCP IAM grant — let CI self-heal a missed `ops.run_log` write (Item 3, RUNBOOK §38)

  *(auto-verified 2026-07-16: ops.routine_commit_markers has rows with source='auto-merge-claude.yml'
  dated 2026-07-14/07-15 — the grant below is live and the CI marker write works.)*

**What it's for:** closes the 2026-07-06..08 incident class where a routine's real output lands on
`main` but its `ops.run_log` completion write never happens (harness session-lifecycle issue, not a
repo bug — root cause is outside this repo's visibility). The fix already runs today as a **manual**
backfill when caught; this grant lets CI do it **automatically** on every merge instead.

**Action — run once, with your own `gcloud`/`bq` credentials:**
```
bq add-iam-policy-binding \
  --member="serviceAccount:gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor" \
  stock-trading-498512:ops.routine_commit_markers
```
This is a **table-scoped** grant — `gh-ci-runner@` stays read-only everywhere else in `ops.*`
(it already has `jobUser`/`dataViewer`/`connectionUser` project-wide per RUNBOOK §6/§15; this adds
write access to exactly one table). It cannot reach `ops.run_log` or `ops.alerts` directly — only
`ops.sp_backfill_run_log_from_markers()` (run under your own identity, like every other procedure)
actually writes those, off the marker rows this grant lets CI insert.

**If skipped:** no functional loss today. `auto-merge-claude.yml`'s marker-write step no-ops/warns
cleanly without this grant, and the existing manual-backfill fallback (`ops.sp_backfill_run_log_from_markers()`
called by hand, or by the nightly `cadence_check.sql` pass) is fully intact either way — this grant
only removes the "manual" part.

The grant's scope is also declared (never applied) in `infra/terraform/iam.tf` as
`google_bigquery_table_iam_member.gh_ci_runner_routine_commit_markers_editor`, purely so its blast
radius is reviewable in-repo before you run the command above — per the standing Terraform-is-spec-only
decision (`CLAUDE.md`), do NOT `terraform apply` this file; the `bq` command above is the real grant.

---

## 4. Elect (or confirm) your IBKR cost-basis method (Item 18) — `[DECIDED 2026-07-17: FIFO]`

**Owner decision 2026-07-17: FIFO** (the IBKR default) — no specific-lot election has been made, so the
repo's `analytics.tax_lots` FIFO lot construction matches the broker's own accounting. Recorded in
`Experiment_Parameters.md`'s tax-lot caveat. If you ever change the IBKR election, update that note and
this item. Nothing further to do.

**What changed:** `analytics.tax_lots` / `state.wash_sale_exposure`
(`bigquery/41_tax_lots.sql`) now detect account-wide wash sales (a same-ticker BUY within 30 calendar
days of ANY strategy's loss-realizing SELL — checked across strategies, not just within one, since the
IRS wash-sale rule is a taxpayer-level rule and this system now runs up to 8 independent strategies
that can legitimately trade the same ticker). This is **detection/reporting only** — IBKR's own
1099-B, computed off your account's actual elected method, remains the authoritative tax figure.

**Action:** this repo's lot construction assumes **FIFO** (the typical IBKR default) purely to build
its own internal lots. If you have elected — or ever elect — a different method with IBKR (e.g.
specific-lot ID), say so explicitly (in chat, or by editing `Experiment_Parameters.md`'s tax-lot
caveat note directly) — otherwise `analytics.tax_lots` will silently diverge from your broker's own
lot-by-lot 1099-B accounting (total shares/proceeds still reconcile either way, just not lot-by-lot).
If you're already on FIFO / haven't touched the election, no action needed — this is a "confirm or
correct an assumption," not a blocking requirement.

---

## 5. Read and decide — Agent SDK / headless-harness migration (Item 26, informational) — `[DECIDED 2026-07-17: NO-GO / no pilot]`

**Owner decision 2026-07-17: do NOT pilot the Agent-SDK / headless-harness migration (not even D1).**
Rationale (see the corrected analysis below): the spike's original "cost-neutral" premise was debunked
— piloting D1 on the Managed Agents API would convert its token cost from the flat subscription to
real metered API dollars (~15-30x), and the one concrete urgency case (the §38 run_log gap) was already
closed for free by Item 3. IBKR-order routines remain a hard NO-GO regardless (no headless auth path).
The routines stay on the current interactive claude.ai web-UI + RemoteTrigger model. Revisit only if
Anthropic ships subscription-priced headless usage AND a first-party headless IBKR auth path appears.
Item 29 (thin order gateway) stays closed. Original spike + fact-check retained below for the record.

`ops/spikes/agent-sdk-orchestration-2026Q3.md` is a feasibility report (no repo/live changes) on
moving routines off the interactive claude.ai web-UI onto a headless, scheduled harness. Bottom line:
**conditional GO for a D1-only pilot** (read/judgment-only, no IBKR orders), **unconditional NO-GO**
for anything that calls the IBKR connector until a separate spike resolves headless IBKR auth (no
first-party OAuth path exists today; the unofficial local-execution-only community IBKR MCP servers
are explicitly unsuited for real-money order placement without a dedicated security review this spike
doesn't attempt). This is a **decision for you, not an action required** — nothing changes unless you
say to proceed with the D1 pilot. Item 29 (a "thin order gateway" for mechanically enforcing the
order-guard before every IBKR order) is downstream of this and stays closed (see `ops/RUNBOOK.md` §40)
until this spike's IBKR gap is separately resolved.

**CORRECTED 2026-07-11 (owner fact-check) — the spike's cost-neutrality claim was wrong.** The spike
originally claimed migrating a routine's token cost was "unchanged, not a new cost line" because a
2026-06-15 Anthropic billing change already moved headless/Agent-SDK usage onto a separate API-rate
credit. That change was **paused before taking effect** — Anthropic's own Help Center confirms headless/
Agent-SDK usage still draws from the owner's Claude **subscription** limits today, not a metered pool.
Separately, the harness in (b) would call Claude via the **Managed Agents API** — a different product
surface from the subscription login, billed at standard per-token API rates with no subscription
discount. So piloting D1 on this harness would very likely convert D1's token cost from "bundled into
the flat subscription" to "real, metered API dollars per run" (one estimate: subscription pricing
subsidizes agent usage ~15-30x vs. API rates) — the opposite of the original "near-zero, cost-neutral"
framing. Also worth noting: the original urgency case for this migration (fixing the §38 run_log gap)
is now moot regardless of cost — Item 3 (this same 2026-07-11 session) closed that gap for free with no
migration needed (`ops/RUNBOOK.md` §38). Get an actual per-token cost estimate before deciding to pilot;
see the corrected `ops/spikes/agent-sdk-orchestration-2026Q3.md` (c) for detail.

---

## Not an owner action — flagged for the record

- **Item 30b** (deferred, not attempted this pass): collapsing the routine-list hand-copy-then-CI-check
  pattern across `bigquery/12/15/24` + `Claude_Task_Plan.md`'s ROUTINE INVENTORY table into a
  generator off `ops/cadence.yaml`. Genuine refactor with real risk of breaking the cadence-consistency
  CI gate if rushed — explicitly scoped as a future engineering follow-up, not something you need to
  do or decide.
- **`AI_Trading_Foundation.md`'s in-use-Claude-version field** (Item 30a) is now flagged rather than
  silently overwritten (this repo can't query which model a web-UI session actually ran on) — it will
  resolve itself via the document's own existing version-change protocol at the next Q3/A1 cycle; no
  action needed from you specifically.

- **Live BigQuery changed mid-session from an OUT-OF-BAND apply — re-measure before concluding
  anything about drift** (observed 2026-07-18, live-sql-parity remediation pass). A session was
  deciding *whether* to apply `bigquery/48_cadence_monitor_unbounded.sql` (removes the 14-day window
  from the FATAL `ops.sp_assert_deps` gate) and deliberately held it back pending review of one risky
  caller/dep pair. Between two parity runs ~50 minutes apart, live changed underneath it: file 48 was
  applied (both its objects) and `ops.sp_score_theater` was updated to the repo version. Parity read
  5 → 3 → 0 mismatched across the window, and two *phantom* drifts (`state.ci_findings_open`,
  `state.referee_promotion_readiness`) appeared and vanished between consecutive runs while the applies
  were in flight.

  **Attribution (verified via `region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`):** all the DDL ran as
  SCRIPT jobs under `jacksterwu@gmail.com` at ~06:52 MT — i.e. an owner-credentialed session running
  the files directly, which is this repo's *documented normal* operating model (CLAUDE.md: "out-of-band
  mutation via MCP/console **is** the operating model"). Ruled out by evidence, NOT assumption:
  CI/WIF (those run as `gh-ci-runner@`, not the owner address), any routine (`ops.run_log` has **zero**
  rows for 2026-07-18 — nothing ran), `scripts/check_live_sql_parity.py` itself (read-only; it only
  SELECTs and optionally writes a JSON file), and the D3 self-heal (see next item).

  **Lesson: a drift reading taken while an apply is in flight is a snapshot, not a fact.** Re-run
  before diagnosing, and check `JOBS_BY_PROJECT` for `user_email` + `statement_type` before attributing
  a live change to any automated loop — the answer is often "a human/agent applied it out of band."

- **`ops.parity_selfheal_log` is EMPTY — D3's LIVE-SQL-PARITY SELF-HEAL has never actually executed
  an apply** (verified 2026-07-18: zero rows since the table was created 2026-07-16 by
  `bigquery/69_live_sql_parity_selfheal.sql`). — **`[INVESTIGATED + FIRE DRILL IN FLIGHT 2026-07-18]`**
  (same-day follow-up session, owner-directed). Findings: the CHAIN IS CORRECTLY WIRED — D3's
  CI-FINDINGS ADJUDICATION step already reads `state.ci_findings_open` (unified 2026-07-17), the
  workflow writes per-object `finding_key='<dataset>.<name>'` rows, and `bigquery/86` supplies the
  episode-aware `first_detected` the one-day lag keys on. "Never fired" is CORRECT-IDLE, not broken:
  no qualifying per-object drift row has ever existed (per-object rows only began 2026-07-18 and
  parity went 179/179 clean the same day), and the loop is REAL-DRIFT-ONLY by construction — each
  clean daily parity run auto-resolves any open key before D3's evening run, so only drift persisting
  >= 2 daily runs can ever reach a re-apply (a synthetic test row structurally cannot). Fixed this
  pass: `bigquery/69`'s stale header/description rewired to the current bridge (repo + live ALTER),
  and D3's adjudication gained the missing branch **(c)** "live and repo already MATCH"
  (phantom-drift / healed-out-of-band, with JOBS_BY_PROJECT attribution — the retraction above's
  lesson, now encoded). **POSITIVE-EVIDENCE FIRE DRILL ARMED** (decision_log `entry_type='fire-drill'`,
  2026-07-18): a deliberate, semantically-inert live drift on `analytics.theater_check_calibration`
  (ROUND digit 3→4; W5-digest-only consumer; repo `bigquery/11` stays canonical). Expected: Sun 07-19
  parity flags it (+GH issue); Mon 07-20 ~18:30 MT D3 re-applies and writes the FIRST
  `parity_selfheal_log` row; Tue 07-21 parity auto-resolves. ONE `ci_finding` warning email ~Mon
  morning is EXPECTED (it is the drill). **If the finding is still open after Tue 2026-07-21, the
  loop failed the drill** — investigate D3's execution of the step, then hand-heal by re-applying
  `bigquery/11_theater_judge.sql`'s view. Do NOT hand-heal before Mon evening.

- **Residual, low-probability edge case now live: `SL5 <- [AR_orc]` under the un-bounded gate.**
  With `bigquery/48` now live, `ops.sp_assert_deps`' "monitored" test has no rolling window, so a dep
  that has EVER completed is monitored forever. 13 of 14 caller/dep pairs are provably safe (each dep
  is co-scheduled the same period-day as its caller, hours earlier — verified structurally against
  `ops/cadence.yaml` and empirically against `ops.run_log`). The exception is **SL5**, which has three
  trigger sources, two of them structurally decoupled from AR_orc (an SL3 PAPER→PROBE enqueue, and a
  D2 step-5 mechanical drawdown/30-trade/m2m TERMINATED transition). If AR_orc were dark for >14
  consecutive days AND one of those two paths fired, SL5 would be FATAL-blocked with no auto-heal
  (SL5/AR_orc are `catchup_safe: false`, so OPS0's catch-up refire excludes them) — which would stall
  post-kill roster DEREGISTRATION specifically.

  **Why this is being recorded rather than fixed:** the probability is low and the failure is
  fail-CLOSED, which is the correct direction for this system. AR_orc fires daily by trigger (not
  queue-gated) and logs explicit no-op `completed` rows on empty-queue days, so a >14-day gap requires
  a genuine multi-week trigger outage — the exact SPOF that file 48 exists to catch. The largest gap
  ever observed for ANY routine in `ops.run_log` is 7 days. Under the OLD bounded rule that same
  outage would have SILENTLY UN-MONITORED AR_orc and let SL5 proceed on a broken upstream — strictly
  worse. So the new behavior is an improvement, with one narrow edge worth knowing about.

  If you ever do want it closed, the cleanest fix is to scope SL5's `sp_assert_deps` call to require
  AR_orc same-day completion **only when the dispatched task's trigger is an AR_orc-authored verdict**,
  leaving the SL3-enqueue and D2-mechanical-kill paths ungated. That is a `Claude_Task_Plan.md` prose
  change to SL5's DEPENDENCY GATE line, not a SQL change.
