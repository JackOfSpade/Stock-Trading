#!/usr/bin/env python3
"""Apply the RUNBOOK §56 hardening to the five LIVE scheduler-absence alert policies.

WHY: a transient Cloud Monitoring evaluation blip opened an incident on a healthy scheduler three times in
seven weeks (RUNBOOK §49, §56) because every policy had `duration: 0s`. monitoring.tf now specs a 30-minute
pending period, corrected condition display names and non-empty documentation; this script makes the LIVE
policies match. monitoring.tf stays a spec (CLAUDE.md "Terraform ... do NOT propose import then apply") --
live changes are made out-of-band, which is this.

WHAT: PATCHes ONLY `conditions` + `documentation` (updateMask) on each policy, found by display name
(plus, for the SA-key policy, `documentation` alone -- its empty body is the same defect). The
condition's own `name` and its PromQL `query` / `evaluationInterval` are carried over untouched. Idempotent:
a policy already matching is skipped. DRY-RUN by default; pass --apply to write.

    python3 infra/terraform/apply_absence_policy_hardening.py            # show the diff
    python3 infra/terraform/apply_absence_policy_hardening.py --apply    # write it

Needs `gcloud` authenticated with monitoring.alertPolicies.update (project owner has it). The values below
are held in lockstep with monitoring.tf by tests/test_absence_policy_hardening.py.
"""
import argparse
import json
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

PROJECT = "stock-trading-498512"
API = "https://monitoring.googleapis.com/v3"

DURATION = "1800s"  # == monitoring.tf local.scheduler_absence_duration

# == monitoring.tf local.scheduler_absence_triage (with "<id>" -> the monitor's config_id)
TRIAGE = ' FALSE-ALARM CHECK FIRST (6 false alarms on 4 policies since 2026-08-17, ops/RUNBOOK.md section 56): the scheduler is usually fine. (1) Incident length: a blip auto-closes in ~4 min, a real absence stays open for hours. (2) Warehouse: `SELECT sq_name, last_beat_ts, stale_beat FROM state.scheduled_query_version_drift` -- this monitor\'s last_beat_ts within 24h and stale_beat=false means it is alive (a real death also raises a scheduled_query_stale warning in ops.alerts within ~36-60h). (3) Logs: `gcloud logging read \'resource.type="bigquery_dts_config" AND resource.labels.config_id="<id>" AND jsonPayload.message=~"^Summary: succeeded"\' --freshness=2d` -- a \'Summary: succeeded 1 jobs\' line inside 25h means the alert was an evaluation-side blip (a \'failed 1 jobs\' Summary is a failing run, not a dead scheduler: see the DTS failure email and ops.alerts). Blip => no action.'

# policy display name -> (config_id, condition display name, documentation)
# Each field equals monitoring.tf's scheduler_absence_monitors entry of the same key.
MONITORS = {
    "Freshness scheduler absent >25h": (
        "6a9c1592-0000-2caa-86b1-089e08214038",
        "No freshness run in 25h",
        "The freshness dead-man's switch has not emitted a run heartbeat in >25h. "
        "FIRST verify it is real, not a repeat of the 2026-06-20 false alarm: "
        "check INFORMATION_SCHEMA.JOBS_BY_PROJECT for recent scheduled_query% jobs "
        "running the freshness body (see ops/RUNBOOK.md §19). If runs ARE present, the "
        "heartbeat metric filter has drifted from the live config_id / DTS message wording "
        "— fix the metric, not the scheduler. If NO runs are present, the scheduler is "
        "genuinely down (paused config, lapsed run-SA, or DTS outage).",
    ),
    "Backup scheduler absent >25h": (
        "6a509810-0000-2279-a65e-f4f5e80c4144",
        "No events-backup run in 25h",
        "The events-backup scheduled query has emitted no run heartbeat in >25h — the append-only event store "
        "may be silently un-backed-up. Triage per ops/RUNBOOK.md §19: check "
        "region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT for recent scheduled_query% backup runs. Runs present -> "
        "the metric drifted (fix the metric). No runs -> the backup scheduler is down (paused config, lapsed "
        "run-SA, or DTS outage).",
    ),
    "Cadence scheduler absent >25h": (
        "6a44a3d9-0000-2837-8b7b-883d24f5c8b8",
        "No cadence-check run in 25h",
        "The cadence-check scheduled query has emitted no run heartbeat in >25h — missed-routine detection "
        "(state.cadence_watch) may be silently down. Triage per ops/RUNBOOK.md §19; note state.freshness still "
        "independently catches data staleness, so this is lower-severity than the freshness/backup absences.",
    ),
    "Integrity-check scheduler absent >25h": (
        "6a4d603d-0000-2d5d-b9af-14223bafe266",
        "No integrity-check run in 25h",
        "The daily append-only INTEGRITY check (state.append_only_integrity) has emitted no run heartbeat in "
        ">25h. It is record-only (writes a warning, never RAISEs), so a DEAD scheduler writes no alert of its "
        "own — this policy is the fast (25h) detector, and cadence_check independently raises a "
        "scheduled_query_stale warning via ops.alerts if no sq:integrity_check heartbeat lands for 36h, so a "
        "real death is double-covered. Triage per ops/RUNBOOK.md §19; confirm the "
        "resourceViewer grant + that view 18 is applied.",
    ),
    "ops-export scheduler absent >25h": (
        "6a43d4f7-0000-276c-b1fb-7474463ce22d",
        "No ops.* backup run in 25h",
        "The ops.* backup export (ops-export-daily) has emitted no run heartbeat in >25h — the irreplaceable "
        "run_log/alerts/backup_log/heartbeat/drill_log audit history may be silently un-backed-up. "
        "state.ops_backup_health additionally flags this via cadence_check. Triage per ops/RUNBOOK.md §19/§27.",
    ),
}


# Documentation-only: the live SA-key policy has an EMPTY body, so its email carries no "delete the key" guidance.
# Its condition (an event detector, increase()>0) is deliberately NOT touched -- a pending period would let a
# real key creation expire before opening an incident. == monitoring.tf local.sa_key_created_documentation
DOC_ONLY = {
    "SA key created on gh-ci-runner or bq-scheduler": 'A user-managed (downloadable) key was just created on gh-ci-runner@ or bq-scheduler@ — both are supposed to be keyless (WIF, RUNBOOK §6/§15/§25). If you did not intend this, DELETE the key immediately (gcloud iam service-accounts keys delete) and investigate who created it. Pairs with the monthly keyless-sa-audit.yml state assertion.',
}


def token():
    return subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()


def call(method, url, tok, body=None):
    req = urllib.request.Request(
        url,
        method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code} on {method} {url}: {e.read().decode()[:500]}")
    except (urllib.error.URLError, TimeoutError) as e:
        sys.exit(f"network error on {method} {url}: {e} (idempotent -- safe to re-run)")


def desired(policy, cfg, cname, doc):
    """Build the PATCH body for one live policy, or return (None, reason) if it is not patchable."""
    conds = policy.get("conditions", [])
    if len(conds) != 1 or "conditionPrometheusQueryLanguage" not in conds[0]:
        return None, f"expected exactly one PromQL condition, found {len(conds)}"
    c = conds[0]
    prom = dict(c["conditionPrometheusQueryLanguage"])
    prom["duration"] = DURATION
    cond = {"displayName": cname, "conditionPrometheusQueryLanguage": prom}
    if "name" in c:
        cond["name"] = c["name"]
    content = doc + TRIAGE.replace("<id>", cfg)
    return {"conditions": [cond], "documentation": {"content": content, "mimeType": "text/markdown"}}, None


def current_view(policy):
    c = (policy.get("conditions") or [{}])[0]
    return {
        "conditionName": c.get("displayName"),
        "duration": c.get("conditionPrometheusQueryLanguage", {}).get("duration"),
        "hasDocumentation": bool((policy.get("documentation") or {}).get("content")),
    }


def matches(policy, body):
    c, want = (policy.get("conditions") or [{}])[0], body["conditions"][0]
    return (
        c.get("displayName") == want["displayName"]
        and c.get("conditionPrometheusQueryLanguage", {}).get("duration") == DURATION
        and (policy.get("documentation") or {}).get("content") == body["documentation"]["content"]
    )


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--apply", action="store_true", help="write the changes (default is a dry run)")
    args = ap.parse_args()
    tok = token()

    by_name, page = {}, ""
    while True:
        qs = {"pageSize": 100, **({"pageToken": page} if page else {})}
        listing = call("GET", f"{API}/projects/{PROJECT}/alertPolicies?" + urllib.parse.urlencode(qs), tok)
        for p in listing.get("alertPolicies", []):
            by_name.setdefault(p["displayName"], []).append(p)
        page = listing.get("nextPageToken", "")
        if not page:
            break

    rc = 0
    for disp, (cfg, cname, doc) in MONITORS.items():
        found = by_name.get(disp, [])
        if len(found) != 1:
            print(f"!! {disp}: expected exactly 1 live policy, found {len(found)} -- skipped")
            rc = 1
            continue
        policy = found[0]
        body, why = desired(policy, cfg, cname, doc)
        if body is None:
            print(f"!! {disp}: {why} -- skipped")
            rc = 1
            continue
        if matches(policy, body):
            print(f"= {disp}: already hardened")
            continue
        print(f"~ {disp}: {json.dumps(current_view(policy))}  ->  conditionName={cname!r} duration={DURATION}"
              f" + documentation")
        if args.apply:
            url = f"{API}/{policy['name']}?" + urllib.parse.urlencode({"updateMask": "conditions,documentation"})
            out = call("PATCH", url, tok, body)
            print(f"  applied; live duration now "
                  f"{out['conditions'][0]['conditionPrometheusQueryLanguage']['duration']}")
    for disp, doc in DOC_ONLY.items():
        found = by_name.get(disp, [])
        if len(found) != 1:
            print(f"!! {disp}: expected exactly 1 live policy, found {len(found)} -- skipped")
            rc = 1
            continue
        policy = found[0]
        if (policy.get("documentation") or {}).get("content") == doc:
            print(f"= {disp}: documentation already set")
            continue
        print(f"~ {disp}: documentation only")
        if args.apply:
            url = f"{API}/{policy['name']}?" + urllib.parse.urlencode({"updateMask": "documentation"})
            call("PATCH", url, tok, {"documentation": {"content": doc, "mimeType": "text/markdown"}})
            print("  applied")
    if not args.apply:
        print("\n(dry run -- re-run with --apply to write)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
