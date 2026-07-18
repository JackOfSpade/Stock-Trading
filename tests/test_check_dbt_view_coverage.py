"""Guard scripts/check_dbt_view_coverage.py — the advisory "which live state/analytics/perf VIEWs
have no dbt model and no declared dbt source" checker (2026-07-14 self-improvement audit). This
module had NO dedicated test before now, yet its whole value is a trustworthy count: a regex that
silently stops matching, or set math that quietly under/over-reports, turns the advisory into noise.

All tests run against tmp_path fixtures (never the real bigquery/ or dbt/ trees).
"""
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "check_dbt_view_coverage.py")
    spec = importlib.util.spec_from_file_location("check_dbt_view_coverage", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


cov = _load()


# ---- live_views(): CREATE OR REPLACE VIEW extraction across bigquery/*.sql ------------------------
def test_live_views_matches_datasets_dedupes_and_skips_non_sql(tmp_path, monkeypatch):
    bq = tmp_path / "bigquery"
    bq.mkdir()
    (bq / "01_a.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS SELECT 1;\n"
        "CREATE OR REPLACE VIEW `stock-trading-498512.ops.ignored_wrong_dataset` AS SELECT 1;\n"
    )
    (bq / "02_b.sql").write_text(
        # redefine state.foo in a later file (must dedupe to one), and add analytics.bar
        "create   or   replace   view   `stock-trading-498512.state.foo` as select 2;\n"   # case/spacing tolerant
        "CREATE OR REPLACE VIEW `stock-trading-498512.analytics.bar` AS SELECT 3;\n"
    )
    (bq / "README.md").write_text("CREATE OR REPLACE VIEW `stock-trading-498512.state.doc_only` AS SELECT 1;\n")
    (bq / "subdir").mkdir()   # directory entry ending in nothing; must be skipped, never opened
    monkeypatch.setattr(cov, "BIGQUERY_DIR", str(bq))
    assert cov.live_views() == {("state", "foo"), ("analytics", "bar")}


def test_live_views_ignores_non_view_ddl(tmp_path, monkeypatch):
    bq = tmp_path / "bigquery"
    bq.mkdir()
    (bq / "01.sql").write_text(
        "CREATE OR REPLACE TABLE `stock-trading-498512.state.t` AS SELECT 1;\n"
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.state.p`() BEGIN SELECT 1; END;\n"
    )
    monkeypatch.setattr(cov, "BIGQUERY_DIR", str(bq))
    assert cov.live_views() == set()


def test_live_views_does_not_match_materialized_view_by_design(tmp_path, monkeypatch):
    # SCOPE NOTE (pin, not a bug): VIEW_DDL requires "REPLACE VIEW" contiguously, so a MATERIALIZED
    # VIEW ("REPLACE MATERIALIZED VIEW") is intentionally NOT counted as a coverage-tracked live view.
    # None exist in the tree today; if materialized views should ever be coverage-checked, that is an
    # owner scope decision (widen VIEW_DDL + confirm the dbt-parity semantics), not a silent regex tweak.
    bq = tmp_path / "bigquery"
    bq.mkdir()
    (bq / "01.sql").write_text(
        "CREATE OR REPLACE MATERIALIZED VIEW `stock-trading-498512.state.mv` AS SELECT 1;\n"
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.regular` AS SELECT 1;\n"
    )
    monkeypatch.setattr(cov, "BIGQUERY_DIR", str(bq))
    assert cov.live_views() == {("state", "regular")}   # mv excluded, regular view kept


# ---- dbt_model_names(): dataset subdir *.sql (excluding schema.yml) -------------------------------
def test_dbt_model_names_collects_sql_only(tmp_path, monkeypatch):
    models = tmp_path / "models"
    for ds in ("state", "perf"):
        (models / ds).mkdir(parents=True)
    (models / "state" / "foo.sql").write_text("select 1")
    (models / "state" / "schema.yml").write_text("version: 2")   # not .sql -> excluded
    (models / "perf" / "baz.sql").write_text("select 1")
    monkeypatch.setattr(cov, "DBT_MODELS_DIR", str(models))
    assert cov.dbt_model_names() == {("state", "foo"), ("perf", "baz")}


def test_dbt_model_names_tolerates_missing_dataset_dir(tmp_path, monkeypatch):
    models = tmp_path / "models"
    (models / "state").mkdir(parents=True)   # only state exists; analytics/perf absent
    (models / "state" / "foo.sql").write_text("select 1")
    monkeypatch.setattr(cov, "DBT_MODELS_DIR", str(models))
    assert cov.dbt_model_names() == {("state", "foo")}


# ---- dbt_source_names(): declared sources, dataset override, dataset filter -----------------------
def test_dbt_source_names_honors_dataset_override_and_filters_out_of_scope(tmp_path, monkeypatch):
    src = tmp_path / "sources.yml"
    src.write_text(
        "version: 2\n"
        "sources:\n"
        "  - name: state\n"
        "    dataset: state\n"
        "    tables:\n"
        "      - name: covered_src\n"
        "  - name: events\n"           # events is NOT in {state,analytics,perf} -> excluded
        "    dataset: events\n"
        "    tables:\n"
        "      - name: decision_log\n"
        "  - name: logical_name\n"     # dataset override: block name != dataset
        "    dataset: perf\n"
        "    tables:\n"
        "      - name: strategy_daily\n"
        "  - name: analytics\n"        # no dataset: -> falls back to the block name 'analytics'
        "    tables:\n"
        "      - name: fallback_tbl\n"
        "      - {}\n"                  # a table with no name -> skipped, no crash
    )
    monkeypatch.setattr(cov, "DBT_SOURCES_YML", str(src))
    assert cov.dbt_source_names() == {
        ("state", "covered_src"),
        ("perf", "strategy_daily"),
        ("analytics", "fallback_tbl"),
    }


def test_dbt_source_names_empty_file_is_empty(tmp_path, monkeypatch):
    src = tmp_path / "sources.yml"
    src.write_text("")
    monkeypatch.setattr(cov, "DBT_SOURCES_YML", str(src))
    assert cov.dbt_source_names() == set()


# ---- main(): the coverage verdict + exit code ----------------------------------------------------
def test_main_returns_1_and_lists_uncovered(monkeypatch, capsys):
    monkeypatch.setattr(cov, "live_views",
                        lambda: {("state", "foo"), ("analytics", "bar"), ("perf", "baz")})
    monkeypatch.setattr(cov, "dbt_model_names", lambda: {("state", "foo")})
    monkeypatch.setattr(cov, "dbt_source_names", lambda: {("perf", "baz")})
    assert cov.main() == 1
    out = capsys.readouterr().out
    assert "3 live state/analytics/perf views" in out
    assert "1 uncovered" in out
    assert "- analytics.bar" in out
    # covered ones must NOT be listed as uncovered
    assert "- state.foo" not in out and "- perf.baz" not in out


def test_main_returns_0_when_fully_covered(monkeypatch, capsys):
    monkeypatch.setattr(cov, "live_views", lambda: {("state", "foo"), ("perf", "baz")})
    monkeypatch.setattr(cov, "dbt_model_names", lambda: {("state", "foo")})
    monkeypatch.setattr(cov, "dbt_source_names", lambda: {("perf", "baz")})
    assert cov.main() == 0
    assert "OK: every live state/analytics/perf view" in capsys.readouterr().out


def test_main_reports_zero_uncovered_with_no_live_views(monkeypatch, capsys):
    monkeypatch.setattr(cov, "live_views", lambda: set())
    monkeypatch.setattr(cov, "dbt_model_names", lambda: set())
    monkeypatch.setattr(cov, "dbt_source_names", lambda: set())
    assert cov.main() == 0
    assert "0 live state/analytics/perf views" in capsys.readouterr().out
