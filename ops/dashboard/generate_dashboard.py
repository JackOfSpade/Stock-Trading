#!/usr/bin/env python3
"""Generate a static HTML health dashboard from BigQuery (P1-4).

The redesign doc deferred Looker Studio; today the operator's only window into the system
is hand-run SQL. This renders the key health views to a single self-contained index.html
with zero console setup and no third-party deps (stdlib + the `bq` CLI). Commit the output,
serve it via GitHub Pages, or open it locally.

Usage:  python ops/dashboard/generate_dashboard.py            # writes ops/dashboard/index.html
Schedule it (Cloud Scheduler / cron / a routine) for a continuously fresh page — see ops/RUNBOOK.md.
"""
import html
import os
import subprocess
import sys
from datetime import datetime, timezone

try:
    from zoneinfo import ZoneInfo
except ImportError:  # pragma: no cover — stdlib since 3.9; CI/runners pin >=3.9
    ZoneInfo = None

PROJECT = os.environ.get("PROJECT", "stock-trading-498512")
OUT = os.path.join(os.path.dirname(__file__), "index.html")
BQ_TIMEOUT_S = 600

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
from lib.bq_json import parse_bq_json_stdout  # noqa: E402
from lib import tz_render  # noqa: E402


def q(sql: str):
    """Run a read-only query via the bq CLI and return a list of dict rows.

    Uses --quiet/--headless so bq emits no 'Waiting on bqjob...' status noise; as a
    belt-and-suspenders guard we still slice from the first JSON bracket in case any
    banner leaks to stdout anyway (this exact failure class already hit production in
    scripts/dbt_parity.py and scripts/alert_relay.py — see their bq()/bq helpers).
    """
    try:
        out = subprocess.run(
            ["bq", "--project_id", PROJECT, "--quiet", "--headless", "query",
             "--use_legacy_sql=false", "--format=json", "--max_rows=1000", sql],
            capture_output=True, text=True, check=True, timeout=BQ_TIMEOUT_S,
        ).stdout
    except subprocess.TimeoutExpired as e:
        raise RuntimeError(f"bq query timed out after {e.timeout}s: {sql[:120]}") from e
    return parse_bq_json_stdout(out)


def beat_heartbeat():
    """Best-effort ops.heartbeat(source='dashboard') write (2026-07-15 self-improvement audit,
    Architect recommendation #3 — the dashboard was the one out-of-band delivery surface with no
    liveness monitor). Never raises: the baseline gh-ci-runner@ WIF grant is read-only
    (bigquery.dataViewer), so this INSERT fails with a permission error until the owner grants a
    narrow, table-scoped bigquery.dataEditor on ops.heartbeat (bigquery/58_dashboard_heartbeat.sql);
    until then this is a silent no-op and the dashboard build must still succeed.

    OAE-5 (2026-07-16 owner-selfservice audit, §C probe): appends ' (ci)' to the note when running
    under GitHub Actions (GITHUB_ACTIONS=='true' — set by the platform on every Actions runner) so a
    scheduled/CI build (using the WIF identity the §C grant targets) is deterministically
    distinguishable from a session-window build, instead of the previous fragile
    EXTRACT(HOUR)=7 heuristic (the dashboard cron is 05:20Z but observed delayed starts have run
    07:21-07:33Z)."""
    note = "index.html generated"
    if os.environ.get("GITHUB_ACTIONS") == "true":
        note += " (ci)"
    try:
        subprocess.run(
            ["bq", "--project_id", PROJECT, "--quiet", "--headless", "query",
             "--use_legacy_sql=false",
             f"INSERT INTO `{PROJECT}.ops.heartbeat` (source, note) "
             f"VALUES ('dashboard', '{note}')"],
            capture_output=True, text=True, timeout=60,
        )
    except Exception:
        pass


def get_user_tz():
    """Detected DISPLAY timezone (state.user_tz — bigquery/20_user_prefs.sql). Purely cosmetic:
    changes how timestamps are RENDERED to the operator, never any query logic. Falls back to
    America/Denver (never bare UTC) so a missing view or a fresh deploy still reads sensibly.

    Thin wrapper over the shared core (scripts/lib/tz_render.py, 2026-07-20 dedup consolidation —
    this exact NULL/empty/error-falls-back-to-Denver logic had independently drifted from
    scripts/alert_relay.py's copy). Passes `q` itself, not a query result, so a test's
    `monkeypatch.setattr(gd, "q", ...)` is honored — the core calls back into whatever `q` resolves
    to in this module at call time."""
    return tz_render.get_display_tz(q, PROJECT)


def fmt_ts(v, tz_name):
    """Render a BigQuery TIMESTAMP string (UTC) in tz_name, labeled — never a bare unlabeled UTC
    string (the prior dashboard behavior: alert_ts/log_ts rendered raw, unlike the alert emailer
    which at least appended ' UTC'). The parse/localize half is the shared core
    (scripts/lib/tz_render.py); this wrapper keeps this site's own falsy-v passthrough (return `v`
    unchanged, not a labeled fallback string — alert_relay.py's sibling deliberately does NOT match
    this) and its "(UTC)" fallback label."""
    if not v or ZoneInfo is None:
        return v
    try:
        return tz_render.render_ts(v, tz_name)
    except (ValueError, KeyError):
        return f"{v} (UTC)"


def table(rows, cols=None):
    if not rows:
        return "<p class='muted'>(no rows)</p>"
    cols = cols or list(rows[0].keys())
    # Escape everything: cell values come from BigQuery (e.g. ops.alerts.message) and could
    # contain <, >, & — unescaped they'd break or inject into the page.
    head = "".join(f"<th>{html.escape(str(c))}</th>" for c in cols)
    body = "".join("<tr>" + "".join(
        f"<td>{html.escape('' if r.get(c) is None else str(r.get(c)))}</td>" for c in cols
    ) + "</tr>" for r in rows)
    return f"<table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table>"


def main():
    try:
        health = q(f"SELECT * FROM `{PROJECT}.state.system_health`")
        kills = q(f"SELECT strategy,as_of_date,deployed_unit_value,current_drawdown,excess_vs_sgov,"
                  f"deployed_days,closed_trades,drawdown_kill,runaway_review,m2m_underperf_review,"
                  f"interim_underperf_warning "
                  f"FROM `{PROJECT}.perf.kill_flags` ORDER BY strategy")
        nav = q(f"SELECT strategy,nav,available_funds,sizing_base_2pct,deployed_mv "
                f"FROM `{PROJECT}.analytics.strategy_nav` ORDER BY strategy")
        gate = q(f"SELECT * FROM `{PROJECT}.state.gate_watch`")
        # CAST(... AS STRING) on the TIMESTAMP columns to match scripts/alert_relay.py's verified-good,
        # deterministic wire form ("YYYY-MM-DD HH:MM:SS[.ffffff]+00") that fmt_ts is tested against —
        # rather than relying on bq --format=json's default raw-TIMESTAMP rendering. ORDER BY on the
        # same alias sorts chronologically (the zero-padded ISO string sorts lexically == temporally),
        # the exact pattern alert_relay.py uses in production (2026-07-17 audit; parallel-refactor).
        alerts = q(f"SELECT CAST(alert_ts AS STRING) AS alert_ts,severity,source,category,message "
                   f"FROM `{PROJECT}.ops.alerts` "
                   f"WHERE NOT resolved ORDER BY alert_ts DESC LIMIT 20")
        runs = q(f"SELECT routine,run_date,status,CAST(log_ts AS STRING) AS log_ts "
                 f"FROM `{PROJECT}.ops.run_log` "
                 f"ORDER BY log_ts DESC LIMIT 20")
    except (subprocess.CalledProcessError, OSError, RuntimeError, ValueError) as e:
        # OSError (broadened from FileNotFoundError) so ANY spawn-time OS error from the bq subprocess
        # — a missing binary (FileNotFoundError), a non-executable one (PermissionError), a PATH entry
        # that is a directory (IsADirectoryError), all OSError subclasses — yields the clean "Query
        # failed" diagnostic + return 1, instead of an uncaught traceback (2026-07-17 audit).
        # CalledProcessError's default __str__ is just "Command '[...]' returned non-zero exit
        # status N" — it never includes bq's actual stderr diagnostic, even though check=True
        # already populated e.stderr with the real error text (2026-07-14 audit finding).
        detail = e.stderr.strip() if isinstance(e, subprocess.CalledProcessError) and e.stderr else str(e)
        print(f"Query failed (is the bq CLI installed & authenticated?): {detail}", file=sys.stderr)
        return 1

    h = health[0] if health else {}
    green = str(h.get("all_green", "")).lower() == "true"
    banner = ("#0a7d28", "ALL GREEN") if green else ("#b00020", "ATTENTION")

    user_tz = get_user_tz()
    now = fmt_ts(datetime.now(timezone.utc).isoformat(), user_tz)
    for r in alerts:
        if "alert_ts" in r:
            r["alert_ts"] = fmt_ts(r["alert_ts"], user_tz)
    for r in runs:
        if "log_ts" in r:
            r["log_ts"] = fmt_ts(r["log_ts"], user_tz)

    page = f"""<!doctype html><html><head><meta charset="utf-8">
<title>Stock-Trading — health</title>
<style>
 body{{font:14px -apple-system,Segoe UI,Roboto,sans-serif;margin:24px;color:#1a1a1a;background:#fafafa}}
 h1{{font-size:18px}} h2{{font-size:15px;margin-top:28px;border-bottom:1px solid #ddd;padding-bottom:4px}}
 .banner{{padding:14px 18px;border-radius:8px;color:#fff;font-weight:600;background:{banner[0]}}}
 table{{border-collapse:collapse;margin-top:8px;background:#fff}} th,td{{border:1px solid #e2e2e2;padding:5px 9px;text-align:left}}
 th{{background:#f0f0f0}} .muted{{color:#888}} .ts{{color:#888;font-size:12px}}
</style></head><body>
<h1>Stock-Trading experiment — system health</h1>
<div class="banner">{banner[1]}</div>
<p class="ts">generated {html.escape(now)} · project {html.escape(PROJECT)}</p>

<h2>Freshness &amp; health</h2>{table(health)}
<h2>Deployed-TWR engine / kill flags</h2>{table(kills)}
<h2>Per-strategy NAV</h2>{table(nav)}
<h2>Conviction gate watch (30 closed trades)</h2>{table(gate)}
<h2>Open alerts</h2>{table(alerts)}
<h2>Recent routine runs</h2>{table(runs)}
</body></html>"""

    # Explicit encoding: the page declares <meta charset="utf-8"> and contains non-ASCII (em-dash,
    # middle dot), so pin UTF-8 rather than relying on the platform default (matches the other
    # generators; PEP 597 hygiene — 2026-07-17).
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(page)
    print(f"Wrote {OUT}  ({'GREEN' if green else 'ATTENTION'})")
    beat_heartbeat()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
