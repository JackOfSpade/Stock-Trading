"""Regression tests for scripts/check_alert_message_stability.py — the PROTOTYPE guard against a
STRING_AGG(...) inside a `sp_raise_alert_once` message whose ORDER BY is not a total order over the
aggregated rows (bigquery/227_alert_message_stability_ordering.sql's defect class: a permuted
message defeats `_once`'s exact-string-equality dedup and raises a fresh unresolved alert on every
run of an UNCHANGED condition).

WHY THESE TESTS DON'T TOUCH check_live_sql_parity.BIGQUERY_DIR. This module imports
`find_final_definitions` with `from check_live_sql_parity import find_final_definitions` — a real
Python import statement, not the test suite's load_module_from_path() loader — so it binds to
whatever module object `import check_live_sql_parity` resolves to via sys.modules, which is a
DIFFERENT object from the one a test gets back from
`load_module_from_path("check_live_sql_parity", "scripts", "check_live_sql_parity.py")` (that
loader deliberately does not register in sys.modules — see conftest.py's docstring). Monkeypatching
the loaded copy's BIGQUERY_DIR would therefore be a silent no-op on the function this module
actually calls. Every test below instead monkeypatches `cams.find_final_definitions` itself with a
fixture returning a synthetic {(dataset, name): (obj_type, project, source_file, body)} map — this
also means no test depends on live bigquery/*.sql content, so none of them break when the tree
grows a new call site.
"""
from conftest import load_module_from_path

cams = load_module_from_path("check_alert_message_stability", "scripts", "check_alert_message_stability.py")


def _defs(body, dataset="ops", name="sp_test_proc", obj_type="PROCEDURE", source_file="99_test.sql"):
    """A find_final_definitions()-shaped map holding exactly one object."""
    return {(dataset, name): (obj_type, "stock-trading-498512", source_file, body)}


def _call(message_expr, category="test_category", payload="NULL"):
    """A minimal but realistic sp_raise_alert_once CALL, wrapped in the surrounding IF/BEGIN...END
    shape every real call site in bigquery/*.sql uses, so the tokenizer sees the same structure it
    sees in production."""
    return f"""
BEGIN
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.watch` WHERE flag) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', '{category}',
      {message_expr},
      {payload});
  END IF;
END;
"""


def _run(body, allowlist=None, monkeypatch=None):
    monkeypatch.setattr(cams, "find_final_definitions", lambda: _defs(body))
    monkeypatch.setattr(cams, "ALLOWLIST", allowlist or {})
    return cams.main()


# ---- the live guard -------------------------------------------------------------------------

def test_real_repo_passes_the_alert_message_stability_gate():
    # The whole point: the repo must stay clean of new, un-allowlisted findings, and the ALLOWLIST
    # must not carry a stale (no-longer-tripped) entry either.
    assert cams.main() == 0


# ---- clean sites pass -------------------------------------------------------------------------

def test_string_agg_ordered_by_the_whole_printed_expression_passes(monkeypatch):
    body = _call(
        "CONCAT('Routine(s) overdue: ', "
        "(SELECT STRING_AGG(routine, ', ' ORDER BY routine) FROM `stock-trading-498512.state.watch` "
        "WHERE flag))"
    )
    assert _run(body, monkeypatch=monkeypatch) == 0


def test_string_agg_ordered_by_every_field_it_prints_passes(monkeypatch):
    # CONCAT prints strategy AND ticker; ORDER BY covers both -- a total order, not just a prefix.
    body = _call(
        "(SELECT STRING_AGG(CONCAT(strategy, ':', ticker), ', ' ORDER BY strategy, ticker) "
        "FROM `stock-trading-498512.state.watch` WHERE flag)"
    )
    assert _run(body, monkeypatch=monkeypatch) == 0


def test_order_by_key_wider_than_printed_expression_passes(monkeypatch):
    # Ordering by MORE than the message prints is still a total order -- only a NARROWER order-by
    # is the defect. (routine, extra_tiebreak) covers routine and then some.
    body = _call(
        "(SELECT STRING_AGG(routine, ', ' ORDER BY routine, extra_tiebreak) "
        "FROM `stock-trading-498512.state.watch` WHERE flag)"
    )
    assert _run(body, monkeypatch=monkeypatch) == 0


def test_qualified_column_reference_uses_only_the_final_segment(monkeypatch):
    # `w.routine` must contribute "routine" to the identifier set, not "w" (a table alias) --
    # otherwise this would falsely register as unstable (expr={w, routine} vs order_by={routine}).
    body = _call(
        "(SELECT STRING_AGG(w.routine, ', ' ORDER BY w.routine) "
        "FROM `stock-trading-498512.state.watch` w WHERE w.flag)"
    )
    assert _run(body, monkeypatch=monkeypatch) == 0


# ---- unstable sites are flagged ---------------------------------------------------------------

def test_no_order_by_at_all_is_flagged(monkeypatch):
    body = _call(
        "(SELECT STRING_AGG(loop_source, ', ') FROM `stock-trading-498512.state.watch` WHERE flag)"
    )
    rc = _run(body, monkeypatch=monkeypatch)
    assert rc == 1


def test_order_by_narrower_than_printed_fields_is_flagged(monkeypatch):
    # Mirrors the real bigquery/227 ci_finding defect: CONCAT prints workflow AND finding_key, but
    # the (buggy, pre-227) ORDER BY covered only workflow -- finding_key ties have no guaranteed
    # relative order.
    body = _call(
        "(SELECT STRING_AGG(CONCAT(workflow, ':', finding_key), ', ' ORDER BY workflow) "
        "FROM `stock-trading-498512.state.watch` WHERE flag)"
    )
    rc = _run(body, monkeypatch=monkeypatch)
    assert rc == 1


def test_flagged_finding_reports_the_missing_fields(monkeypatch):
    body = _call(
        "(SELECT STRING_AGG(CONCAT(routine, ' (', monitor_class, ')'), ', ' ORDER BY routine) "
        "FROM `stock-trading-498512.state.watch` WHERE flag)"
    )
    monkeypatch.setattr(cams, "find_final_definitions", lambda: _defs(body))
    findings, anomalies = cams.find_sites()
    assert anomalies == []
    assert len(findings) == 1
    dataset, name, category, ordered, missing = findings[0]
    assert (dataset, name, category) == ("ops", "sp_test_proc", "test_category")
    assert ordered is True
    assert missing == ["MONITOR_CLASS"]


# ---- comments can never fool the scanner -------------------------------------------------------

def test_string_agg_inside_a_line_comment_is_not_flagged(monkeypatch):
    # This is the live trap this repo has been bitten by before (feedback_refactor_traps_checkers_
    # and_regex.md): bigquery/205's and bigquery/227's own headers quote an offending
    # STRING_AGG(... ORDER BY ...) snippet in PROSE. A checker that greps raw text would match its
    # own documentation. sql_tokens() consumes `--` comments silently, so this must produce zero
    # findings even though the string "STRING_AGG(bad, ', ')" with no ORDER BY appears verbatim.
    body = """
BEGIN
  -- Historical example of the bug this fixes: STRING_AGG(bad, ', ') with no ORDER BY at all used
  -- to defeat sp_raise_alert_once's dedup.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.watch` WHERE flag) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'clean_category',
      (SELECT STRING_AGG(routine, ', ' ORDER BY routine) FROM `stock-trading-498512.state.watch`
       WHERE flag),
      NULL);
  END IF;
END;
"""
    assert _run(body, monkeypatch=monkeypatch) == 0


def test_string_agg_inside_a_block_comment_is_not_flagged(monkeypatch):
    body = """
BEGIN
  /* Historical example of the bug this fixes: STRING_AGG(bad, ', ') with no ORDER BY at all. */
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.watch` WHERE flag) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'clean_category',
      (SELECT STRING_AGG(routine, ', ' ORDER BY routine) FROM `stock-trading-498512.state.watch`
       WHERE flag),
      NULL);
  END IF;
END;
"""
    assert _run(body, monkeypatch=monkeypatch) == 0


def test_entire_commented_out_call_is_invisible_to_the_scanner(monkeypatch):
    # A whole CALL, unstable pattern included, sitting only inside a comment: sql_tokens() yields
    # no tokens at all for it, so find_sites() must see zero sp_raise_alert_once calls in this
    # body -- not "zero findings because it happens to pass", but "the call is not seen at all".
    body = """
BEGIN
  -- CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning', 'src', 'ghost_category',
  --   (SELECT STRING_AGG(bad_col, ', ') FROM `stock-trading-498512.state.watch` WHERE flag), NULL);
  SELECT 1;
END;
"""
    monkeypatch.setattr(cams, "find_final_definitions", lambda: _defs(body))
    findings, anomalies = cams.find_sites()
    assert findings == []
    assert anomalies == []


# ---- allowlist plumbing ------------------------------------------------------------------------

def test_allowlisted_unstable_site_does_not_fail(monkeypatch):
    body = _call(
        "(SELECT STRING_AGG(loop_source, ', ') FROM `stock-trading-498512.state.watch` WHERE flag)"
    )
    allowlist = {("ops", "sp_test_proc", "test_category"): "test fixture: pretend this is verified total."}
    assert _run(body, allowlist=allowlist, monkeypatch=monkeypatch) == 0


def test_stale_allowlist_entry_is_reported_and_fails(monkeypatch, capsys):
    # A site that is CLEAN (or absent) but still carries an ALLOWLIST entry must fail -- the
    # anti-rot behaviour modeled on scripts/check_superseded_markers.py's BASELINE, so a fixed (or
    # renamed, or deleted) site's exemption cannot silently outlive it.
    body = _call(
        "(SELECT STRING_AGG(routine, ', ' ORDER BY routine) FROM `stock-trading-498512.state.watch` "
        "WHERE flag)"
    )
    allowlist = {("ops", "sp_test_proc", "test_category"): "test fixture: stale on purpose."}
    monkeypatch.setattr(cams, "find_final_definitions", lambda: _defs(body))
    monkeypatch.setattr(cams, "ALLOWLIST", allowlist)
    rc = cams.main()
    out = capsys.readouterr().out
    assert rc == 1
    assert "STALE ALLOWLIST" in out, out
    assert "sp_test_proc" in out and "test_category" in out, out


def test_allowlist_entry_for_an_object_with_no_findings_at_all_is_stale(monkeypatch, capsys):
    # Same anti-rot check, but for the "object no longer even calls sp_raise_alert_once" shape
    # (e.g. the whole IF block was deleted) rather than "the STRING_AGG became stable".
    body = "BEGIN\n  SELECT 1;\nEND;\n"
    allowlist = {("ops", "sp_test_proc", "test_category"): "test fixture: stale on purpose."}
    monkeypatch.setattr(cams, "find_final_definitions", lambda: _defs(body))
    monkeypatch.setattr(cams, "ALLOWLIST", allowlist)
    rc = cams.main()
    out = capsys.readouterr().out
    assert rc == 1
    assert "STALE ALLOWLIST" in out, out


# ---- malformed call sites are reported, not mis-indexed ----------------------------------------

def test_call_with_wrong_argument_count_is_an_anomaly_not_a_crash(monkeypatch):
    body = """
BEGIN
  CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning', 'src', 'only_three_args');
END;
"""
    monkeypatch.setattr(cams, "find_final_definitions", lambda: _defs(body))
    findings, anomalies = cams.find_sites()
    assert findings == []
    assert len(anomalies) == 1
    dataset, name, msg = anomalies[0]
    assert (dataset, name) == ("ops", "sp_test_proc")
    assert "3" in msg


def test_non_literal_category_falls_back_to_a_label_instead_of_crashing(monkeypatch):
    # Every real call site passes a literal category, but a dynamically-built one (a variable, a
    # CASE expression) must degrade gracefully rather than raise.
    body = """
BEGIN
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.watch` WHERE flag) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', IF(TRUE, 'a', 'b'),
      (SELECT STRING_AGG(loop_source, ', ') FROM `stock-trading-498512.state.watch` WHERE flag),
      NULL);
  END IF;
END;
"""
    monkeypatch.setattr(cams, "find_final_definitions", lambda: _defs(body))
    findings, _anomalies = cams.find_sites()
    assert len(findings) == 1
    assert findings[0][2] == "<non-literal category>"
