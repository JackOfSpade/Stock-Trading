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
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

PROJECT = os.environ.get("PROJECT", "stock-trading-498512")
OUT = os.path.join(os.path.dirname(__file__), "index.html")


def q(sql: str):
    """Run a read-only query via the bq CLI and return a list of dict rows."""
    out = subprocess.run(
        ["bq", "--project_id", PROJECT, "query", "--use_legacy_sql=false",
         "--format=json", "--max_rows=1000", sql],
        capture_output=True, text=True, check=True,
    ).stdout
    return json.loads(out) if out.strip() else []


def table(rows, cols=None):
    if not rows:
        return "<p class='muted'>(no rows)</p>"
    cols = cols or list(rows[0].keys())
    # Escape everything: cell values come from BigQuery (e.g. ops.alerts.message) and could
    # contain <, >, & — unescaped they'd break or inject into the page.
    head = "".join(f"<th>{html.escape(str(c))}</th>" for c in cols)
    body = "".join("<tr>" + "".join(f"<td>{html.escape(str(r.get(c, '')))}</td>" for c in cols) + "</tr>" for r in rows)
    return f"<table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table>"


def main():
    try:
        health = q(f"SELECT * FROM `{PROJECT}.state.system_health`")
        kills = q(f"SELECT strategy,as_of_date,deployed_unit_value,current_drawdown,excess_vs_sgov,"
                  f"deployed_days,closed_trades,drawdown_kill,runaway_review,m2m_underperf_review "
                  f"FROM `{PROJECT}.perf.kill_flags` ORDER BY strategy")
        nav = q(f"SELECT strategy,nav,available_funds,sizing_base_2pct,deployed_mv "
                f"FROM `{PROJECT}.analytics.strategy_nav` ORDER BY strategy")
        gate = q(f"SELECT * FROM `{PROJECT}.state.gate_watch`")
        alerts = q(f"SELECT alert_ts,severity,source,category,message FROM `{PROJECT}.ops.alerts` "
                   f"WHERE NOT resolved ORDER BY alert_ts DESC LIMIT 20")
        runs = q(f"SELECT routine,run_date,status,log_ts FROM `{PROJECT}.ops.run_log` "
                 f"ORDER BY log_ts DESC LIMIT 20")
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Query failed (is the bq CLI installed & authenticated?): {e}", file=sys.stderr)
        return 1

    h = health[0] if health else {}
    green = str(h.get("all_green", "")).lower() == "true"
    banner = ("#0a7d28", "ALL GREEN") if green else ("#b00020", "ATTENTION")
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

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
<p class="ts">generated {now} · project {PROJECT}</p>

<h2>Freshness &amp; health</h2>{table(health)}
<h2>Deployed-TWR engine / kill flags</h2>{table(kills)}
<h2>Per-strategy NAV</h2>{table(nav)}
<h2>Conviction gate watch (30 closed trades)</h2>{table(gate)}
<h2>Open alerts</h2>{table(alerts)}
<h2>Recent routine runs</h2>{table(runs)}
</body></html>"""

    with open(OUT, "w") as f:
        f.write(page)
    print(f"Wrote {OUT}  ({'GREEN' if green else 'ATTENTION'})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
