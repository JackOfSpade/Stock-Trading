#!/usr/bin/env bash
# Git-committable snapshot of key operational state (P2-1, auditability).
#
# WHY: the .md->BigQuery cutover gave up the "git diff shows exactly what changed since
# yesterday" property. This dumps the small, high-signal state views to CSV under
# state_snapshots/ so a routine (or the owner) can commit them — restoring a human-readable,
# version-controlled daily trail of positions / NAV / performance / health, WITHOUT
# resurrecting the retired live-state .md files.
#
# Usage:  scripts/state_snapshot.sh        # writes state_snapshots/*.csv
# Optionally have D2 run this and `git add state_snapshots && git commit` at end of run.
set -euo pipefail

PROJECT="${PROJECT:-stock-trading-498512}"
OUT="${OUT:-state_snapshots}"
mkdir -p "$OUT"
command -v bq >/dev/null || { echo "bq CLI not found (install Google Cloud SDK)"; exit 1; }

dump () {  # dump <name> <sql>
  echo "  $1.csv"
  bq --project_id="$PROJECT" query --use_legacy_sql=false --format=csv --quiet --headless --max_rows=100000 "$2" > "$OUT/$1.csv"
}

echo "Snapshotting state -> $OUT/"
dump system_health        "SELECT * FROM \`$PROJECT.state.system_health\`"
dump kill_flags           "SELECT * FROM \`$PROJECT.perf.kill_flags\`"
dump strategy_nav         "SELECT * FROM \`$PROJECT.analytics.strategy_nav\`"
dump current_positions    "SELECT strategy,ticker,status,shares,cost_basis,convergence_target,time_exit_date FROM \`$PROJECT.state.current_positions\` ORDER BY strategy,ticker"
dump open_queue           "SELECT queue,item_key,item_type,status,strategy,ticker,due_date FROM \`$PROJECT.state.open_queue\` ORDER BY queue,due_date"
dump open_orders          "SELECT item_key,strategy,ticker,side,qty,limit_price,status,entry_window_close FROM \`$PROJECT.state.open_orders\` ORDER BY strategy,ticker"
dump account_reconciliation "SELECT * FROM \`$PROJECT.analytics.account_reconciliation\`"
dump strategy_daily_tail  "SELECT * FROM \`$PROJECT.perf.strategy_daily\` WHERE as_of_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 10 DAY) ORDER BY as_of_date,strategy"

echo "Done. Review & commit:  git add $OUT && git commit -m 'state snapshot'"
