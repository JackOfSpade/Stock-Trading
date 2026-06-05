#!/usr/bin/env python3
"""One-shot BigQuery loader for the full migration.

Reads GCP_SA_KEY (full service-account JSON) from the environment, writes it to a
temp file, points google-auth at it, then load_table_from_json's every parser's
NDJSON into events.* under stock-trading-498512. Base64-encoded fields are decoded
to UTF-8 before loading. Each load is idempotency-checked (refuse to load if the
target table already has rows). Runs all six tables in dependency order and reports
per-table row counts + a few sanity-check queries at the end.

USAGE (from the venv where google-cloud-bigquery is installed):
    /tmp/bqenv/bin/python bigquery/load_all.py
"""
import os, sys, json, base64, tempfile, pathlib, time

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "bigquery" / "out"
PROJECT = "stock-trading-498512"

def _setup_credentials():
    key = os.environ.get("GCP_SA_KEY")
    if not key:
        sys.exit("ERROR: GCP_SA_KEY env var is missing. Bind it in the environment first.")
    # write to a tempfile (not committed, gitignored path)
    f = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
    f.write(key); f.close()
    os.chmod(f.name, 0o600)
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = f.name
    print(f"credentials staged at {f.name}", flush=True)
    return f.name

def _client():
    from google.cloud import bigquery
    return bigquery.Client(project=PROJECT)

def _b64(s):
    if not s: return None
    return base64.b64decode(s).decode("utf-8")

def _decode_rows(rows, b64_cols, drop_cols=()):
    """Walk rows, decode the listed *_b64 columns into their target name, drop helpers."""
    out = []
    for r in rows:
        rec = {k: v for k, v in r.items() if k not in drop_cols}
        for src, dst in b64_cols.items():
            if src in rec:
                rec[dst] = _b64(rec.pop(src))
        # convert any nested dicts/lists meant for JSON columns to JSON strings
        out.append(rec)
    return out

def _read_jsonl(name):
    p = OUT / name
    if not p.exists():
        return []
    return [json.loads(l) for l in p.read_text(encoding="utf-8").splitlines() if l.strip()]

def _load(client, table, rows, schema):
    from google.cloud import bigquery
    full = f"{PROJECT}.{table}"
    # idempotency: refuse if table non-empty
    n = list(client.query(f"SELECT COUNT(*) c FROM `{full}`").result())[0].c
    if n != 0:
        print(f"SKIP {table} — already has {n} rows (idempotency guard)", flush=True)
        return n
    if not rows:
        print(f"SKIP {table} — no rows in NDJSON", flush=True)
        return 0
    job = bigquery.LoadJobConfig(
        schema=schema,
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
    )
    # stream NDJSON via in-memory bytes
    buf = "\n".join(json.dumps(r, default=str) for r in rows).encode("utf-8")
    from io import BytesIO
    j = client.load_table_from_file(BytesIO(buf), full, job_config=job)
    j.result()
    n2 = list(client.query(f"SELECT COUNT(*) c FROM `{full}`").result())[0].c
    print(f"LOADED {table}: {n2} rows  (job {j.job_id})", flush=True)
    return n2

def main():
    _setup_credentials()
    client = _client()
    from google.cloud import bigquery as bq

    # ---- 1. events.decision_log
    dl = _read_jsonl("decision_log.jsonl")
    dl_rows = _decode_rows(dl,
        b64_cols={"title_b64": "title", "body_b64": "body_md"},
        drop_cols=("era",))
    dl_rows = [{**r, "source_session": r.pop("source")} for r in dl_rows]
    dl_schema = [
        bq.SchemaField("entry_date", "DATE", "REQUIRED"),
        bq.SchemaField("entry_type", "STRING", "REQUIRED"),
        bq.SchemaField("strategy", "STRING"), bq.SchemaField("ticker", "STRING"),
        bq.SchemaField("decision", "STRING"), bq.SchemaField("conviction", "STRING"),
        bq.SchemaField("conviction_pct", "NUMERIC"),
        bq.SchemaField("sub_pattern", "STRING"), bq.SchemaField("theater_check", "STRING"),
        bq.SchemaField("title", "STRING"), bq.SchemaField("body_md", "STRING"),
        bq.SchemaField("source_session", "STRING"),
    ]
    _load(client, "events.decision_log", dl_rows, dl_schema)

    # ---- 2. events.position_events
    pos = _read_jsonl("position_events.jsonl")
    for r in pos:
        r["note"] = _b64(r.pop("note_b64"))
        if r.get("invalidation_status_json") is not None:
            r["invalidation_status"] = json.dumps(r.pop("invalidation_status_json"))
        else:
            r.pop("invalidation_status_json", None)
    pos_schema = [
        bq.SchemaField("position_key", "STRING", "REQUIRED"),
        bq.SchemaField("event_ts", "TIMESTAMP"),
        bq.SchemaField("event_type", "STRING", "REQUIRED"),
        bq.SchemaField("status", "STRING"),
        bq.SchemaField("strategy", "STRING"), bq.SchemaField("ticker", "STRING"),
        bq.SchemaField("cost_basis", "NUMERIC"), bq.SchemaField("shares", "NUMERIC"),
        bq.SchemaField("convergence_target", "NUMERIC"),
        bq.SchemaField("time_exit_date", "DATE"), bq.SchemaField("ltcg_date", "DATE"),
        bq.SchemaField("invalidation_status", "JSON"),
        bq.SchemaField("conviction", "STRING"), bq.SchemaField("model_at_entry", "STRING"),
        bq.SchemaField("source_thesis_ref", "STRING"), bq.SchemaField("note", "STRING"),
    ]
    _load(client, "events.position_events", pos, pos_schema)

    # ---- 3. events.trade_fills (migration-synthetic; will be superseded by connector ingest by trade_id)
    tf = _read_jsonl("trade_fills.jsonl")
    for r in tf:
        r.pop("fill_tz", None); r.pop("is_synthetic", None); r.pop("principal", None)
    tf_schema = [
        bq.SchemaField("trade_id", "STRING", "REQUIRED"),
        bq.SchemaField("fill_ts", "TIMESTAMP"),
        bq.SchemaField("strategy", "STRING"), bq.SchemaField("ticker", "STRING"),
        bq.SchemaField("side", "STRING"),
        bq.SchemaField("shares", "NUMERIC"), bq.SchemaField("price", "NUMERIC"),
        bq.SchemaField("commission", "NUMERIC"),
        bq.SchemaField("source_thesis_ref", "STRING"),
    ]
    _load(client, "events.trade_fills", tf, tf_schema)

    # ---- 4. events.parking_events
    pk = _read_jsonl("parking_events.jsonl")
    pk_schema = [
        bq.SchemaField("action_date", "DATE", "REQUIRED"),
        bq.SchemaField("action", "STRING"),
        bq.SchemaField("shares", "NUMERIC"), bq.SchemaField("price", "NUMERIC"),
        bq.SchemaField("commission", "NUMERIC"), bq.SchemaField("gross", "NUMERIC"),
        bq.SchemaField("order_id", "STRING"), bq.SchemaField("note", "STRING"),
    ]
    _load(client, "events.parking_events", pk, pk_schema)

    # ---- 5. events.regime_events
    rg = _read_jsonl("regime_events.jsonl")
    rg_schema = [
        bq.SchemaField("as_of_date", "DATE", "REQUIRED"),
        bq.SchemaField("scope", "STRING", "REQUIRED"),
        bq.SchemaField("key", "STRING", "REQUIRED"),
        bq.SchemaField("value", "STRING"), bq.SchemaField("numeric_value", "NUMERIC"),
        bq.SchemaField("divergence_id", "STRING"), bq.SchemaField("theater_check", "STRING"),
        bq.SchemaField("rationale", "STRING"), bq.SchemaField("source_review_ref", "STRING"),
    ]
    _load(client, "events.regime_events", rg, rg_schema)

    # ---- 6. events.queue_events
    q = _read_jsonl("queue_events.jsonl")
    for r in q:
        r["note"] = _b64(r.pop("note_b64"))
        if r.get("payload_json") is not None:
            r["payload"] = json.dumps(r.pop("payload_json"))
        else:
            r.pop("payload_json", None)
    q_schema = [
        bq.SchemaField("queue", "STRING", "REQUIRED"),
        bq.SchemaField("item_key", "STRING", "REQUIRED"),
        bq.SchemaField("item_type", "STRING"),
        bq.SchemaField("status", "STRING", "REQUIRED"),
        bq.SchemaField("strategy", "STRING"), bq.SchemaField("ticker", "STRING"),
        bq.SchemaField("due_date", "DATE"),
        bq.SchemaField("conservative_default", "STRING"),
        bq.SchemaField("artifact_path", "STRING"),
        bq.SchemaField("payload", "JSON"), bq.SchemaField("note", "STRING"),
    ]
    _load(client, "events.queue_events", q, q_schema)

    # ---- 7. events.adversarial_reviews
    ar = _read_jsonl("adversarial_reviews.jsonl")
    for r in ar:
        r["body_md"] = _b64(r.pop("body_b64"))
        if r.get("weaknesses_json") is not None:
            r["weaknesses"] = json.dumps(r.pop("weaknesses_json"))
        else:
            r.pop("weaknesses_json", None)
    ar_schema = [
        bq.SchemaField("review_id", "STRING", "REQUIRED"),
        bq.SchemaField("review_type", "STRING"), bq.SchemaField("strategy", "STRING"),
        bq.SchemaField("role", "STRING"),
        bq.SchemaField("review_date", "DATE"), bq.SchemaField("cycle_number", "INT64"),
        bq.SchemaField("verdict", "STRING"), bq.SchemaField("theater_check", "STRING"),
        bq.SchemaField("weaknesses", "JSON"), bq.SchemaField("artifact_path", "STRING"),
        bq.SchemaField("body_md", "STRING"),
    ]
    _load(client, "events.adversarial_reviews", ar, ar_schema)

    # ---- Sanity-check the state views
    print("\n=== state views sanity check ===", flush=True)
    for v in ("state.current_positions", "state.current_regime", "state.open_queue", "state.trade_fills_curated"):
        n = list(client.query(f"SELECT COUNT(*) c FROM `{PROJECT}.{v}`").result())[0].c
        print(f"  {v}: {n} rows", flush=True)

    print("\nDONE.", flush=True)

if __name__ == "__main__":
    main()
