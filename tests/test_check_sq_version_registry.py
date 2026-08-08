"""Regression tests for scripts/check_sq_version_registry.py — the sp_beat_heartbeat literal <->
bigquery/63 registry MERGE cross-check (2026-08-06, alert-triage follow-up). This was the only
scripts/*.py file in the repo with no test module at all, despite being a HARD BLOCKING CI gate.

The two live incidents that motivated the script (commit 0b9fd49: a heartbeat literal bumped without
the registry; commit 9a67c22: registry logic changed without bumping the literal) both produced a
WARNING with no ops.alert_policy row, so neither could ever auto-resolve — the only backstop against
a THIRD recurrence is this script actually firing in CI, which means this test module actually firing
on a planted violation (see the vacuity-guard tests below).

Mirrors the fixture conventions of tests/test_check_superseded_markers.py (synthetic bigquery/ tree
in tmp_path, BIGQUERY_DIR monkeypatched, real-repo live-guard test) and
tests/test_script_version_consistency.py (synthetic registry file, REGISTRY_SQL monkeypatched,
regex-level unit tests for the documented escape-aware quoted-string trap) — this script needs both
patch points at once, since it reads bigquery/*.sql for procedure bodies AND a separate registry file
for the expected-version seed.
"""
from conftest import load_module_from_path

sq = load_module_from_path("check_sq_version_registry", "scripts", "check_sq_version_registry.py")

PROJECT = "stock-trading-498512"


def _proc(name, version, note=None):
    """A minimal `CREATE OR REPLACE PROCEDURE ops.sp_sq_<name>` body ending in the self-reported
    sp_beat_heartbeat CALL the script keys its version comparison on."""
    note = note or f"{name}.sql ran"
    return (
        f"CREATE OR REPLACE PROCEDURE `{PROJECT}.ops.sp_sq_{name}`()\n"
        "BEGIN\n"
        f"  CALL `{PROJECT}.ops.sp_beat_heartbeat`('sq:{name}', '{version}', '{note}');\n"
        "END;\n"
    )


def _registry_row(name, version, note="git note", interval=24):
    return f"STRUCT('{name}', '{version}', '{note}', {interval}),\n"


def _rig(tmp_path, monkeypatch, bq_files, registry_rows):
    """bq_files = {filename: text} for the synthetic bigquery/ dir; registry_rows = a list of
    STRUCT(...) row strings (see _registry_row) for the synthetic bigquery/63 registry file. Points
    the module's BIGQUERY_DIR and REGISTRY_SQL at the synthetic tree so no assertion depends on the
    real repo's evolving contents."""
    d = tmp_path / "bigquery"
    d.mkdir(exist_ok=True)
    for name, text in bq_files.items():
        (d / name).write_text(text, encoding="utf-8")
    registry = tmp_path / "registry.sql"
    registry.write_text(
        "MERGE `x` T USING (SELECT * FROM UNNEST([\n" + "".join(registry_rows) + "])) S\n"
        "ON T.sq_name = S.sq_name WHEN MATCHED THEN UPDATE SET x = 1;\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(sq, "BIGQUERY_DIR", str(d))
    monkeypatch.setattr(sq, "REGISTRY_SQL", str(registry))
    return d


# ---- the live guard -------------------------------------------------------------------------

def test_real_repo_sq_version_registry_is_consistent():
    assert sq.main() == 0


def test_real_repo_actually_found_procedures_and_registry_rows():
    # main() == 0 alone can't distinguish "clean" from "found nothing to check" -- a checker whose
    # regexes silently stopped matching would ALSO print "OK" over zero procedures. Call the real
    # parsing functions directly and assert they found the known-live procedure/registry set (12
    # ops.sp_sq_* procedures registered in bigquery/63 as of 2026-08-07's v13 cadence_check bump).
    proc_defs, heartbeat_calls, offsets_by_file = sq.collect_bigquery()
    winners, resolve_errors = sq.resolve_winners(proc_defs, heartbeat_calls, offsets_by_file)
    registry, registry_errors = sq.parse_registry()
    assert resolve_errors == []
    assert registry_errors == []
    assert "cadence_check" in winners
    assert "cadence_check" in registry
    assert len(winners) >= 10
    assert set(winners) == set(registry)


# ---- happy path -------------------------------------------------------------------------------

def test_happy_path_well_formed_tree_passes(tmp_path, monkeypatch, capsys):
    _rig(
        tmp_path, monkeypatch,
        {"75_wrappers.sql": _proc("embed_pending", "v2") + _proc("cadence_check", "v1")},
        [_registry_row("embed_pending", "v2"), _registry_row("cadence_check", "v1")],
    )
    assert sq.main() == 0
    out = capsys.readouterr().out
    assert "OK" in out
    assert "2 ops.sp_sq_* procedure(s)" in out


# ---- the six distinct violation branches -------------------------------------------------------

def test_version_mismatch_between_body_and_registry_is_flagged(tmp_path, monkeypatch, capsys):
    _rig(
        tmp_path, monkeypatch,
        {"75_wrappers.sql": _proc("cadence_check", "v5")},
        [_registry_row("cadence_check", "v4")],
    )
    assert sq.main() == 1
    out = capsys.readouterr().out
    assert "body reports 'v5'" in out
    assert "expects 'v4'" in out


def test_registry_row_with_no_matching_procedure_is_a_dead_row(tmp_path, monkeypatch, capsys):
    _rig(
        tmp_path, monkeypatch,
        {"75_wrappers.sql": _proc("cadence_check", "v1")},
        [_registry_row("cadence_check", "v1"), _registry_row("ghost_query", "v1")],
    )
    assert sq.main() == 1
    out = capsys.readouterr().out
    assert "dead registry row" in out
    assert "ghost_query" in out


def test_heartbeat_with_no_registry_row_cannot_evaluate_drift(tmp_path, monkeypatch, capsys):
    _rig(
        tmp_path, monkeypatch,
        {"75_wrappers.sql": _proc("orphan_check", "v1")},
        [],
    )
    assert sq.main() == 1
    out = capsys.readouterr().out
    assert "orphan_check" in out
    assert "drift can never be evaluated" in out


def test_duplicate_registry_row_is_flagged(tmp_path, monkeypatch, capsys):
    # Same version on both rows deliberately, so this test isolates the duplicate-row branch from
    # the separate version-mismatch branch (parse_registry() keeps only the LAST-seen row's version
    # for the actual comparison; a differing second version would also trip that other check).
    _rig(
        tmp_path, monkeypatch,
        {"75_wrappers.sql": _proc("cadence_check", "v1")},
        [_registry_row("cadence_check", "v1"), _registry_row("cadence_check", "v1")],
    )
    registry, registry_errors = sq.parse_registry()
    assert len(registry_errors) == 1
    assert "duplicate registry row for sq_name='cadence_check'" in registry_errors[0]
    assert sq.main() == 1
    assert "duplicate registry row" in capsys.readouterr().out


def test_ambiguous_canonical_definition_two_files_share_winning_number(tmp_path, monkeypatch, capsys):
    # D6 case: bigquery/*.sql's NN_ prefix is not guaranteed unique (bigquery/114_period_aware_
    # dependency_gate.sql and bigquery/114_selfheal_log_created_outcome.sql really do share a leading
    # number in this repo). If two DIFFERENT files tied at the winning number both define the SAME
    # ops.sp_sq_* procedure, a bare max() can't tell which is canonical -- must raise, not guess.
    _rig(
        tmp_path, monkeypatch,
        {
            "114_a.sql": _proc("widget_check", "v1"),
            "114_b.sql": _proc("widget_check", "v2"),
        },
        [_registry_row("widget_check", "v1")],
    )
    proc_defs, heartbeat_calls, offsets_by_file = sq.collect_bigquery()
    winners, resolve_errors = sq.resolve_winners(proc_defs, heartbeat_calls, offsets_by_file)
    assert "widget_check" not in winners
    assert len(resolve_errors) == 1
    assert "AMBIGUOUS canonical definition" in resolve_errors[0]
    assert "114_a.sql" in resolve_errors[0] and "114_b.sql" in resolve_errors[0]
    assert sq.main() == 1
    out = capsys.readouterr().out
    assert "AMBIGUOUS canonical definition" in out


def test_winning_definition_has_no_heartbeat_call(tmp_path, monkeypatch, capsys):
    _rig(
        tmp_path, monkeypatch,
        {"75_wrappers.sql": (
            f"CREATE OR REPLACE PROCEDURE `{PROJECT}.ops.sp_sq_silent_check`()\n"
            "BEGIN\n"
            "  SELECT 1;\n"
            "END;\n"
        )},
        [_registry_row("silent_check", "v1")],
    )
    proc_defs, heartbeat_calls, offsets_by_file = sq.collect_bigquery()
    winners, resolve_errors = sq.resolve_winners(proc_defs, heartbeat_calls, offsets_by_file)
    assert "silent_check" not in winners
    assert len(resolve_errors) == 1
    assert "no `CALL ops.sp_beat_heartbeat" in resolve_errors[0]
    assert sq.main() == 1
    assert "cannot determine its deployed" in capsys.readouterr().out


# ---- canonical apply-order resolution, incl. the numeric-vs-lexical 2-vs-3-digit trap -----------

_TRIPLE_WRAPPED_TREE = {
    # bigquery/ has real files past 99 (e.g. bigquery/100_market_only_order_guard.sql); LEXICAL sort
    # puts "100_" BEFORE "75_" ('1' < '7' as the first character), so a checker walking
    # sorted(os.listdir(...)) instead of numbered_sql_files()'s numeric order could treat 75's body
    # as canonical even though 100 actually applies after it (this repo has had exactly that class of
    # bug -- see scripts/lib/sql_files.py's module docstring). These three files stand in for the
    # real cadence_check apply chain (75, 111, 120, 128, 132, 142, 147): the lowest-numbered file (75)
    # must lose to the highest (100), not to whichever sorts last lexically or last in dict order.
    "100_newest.sql": _proc("triple_wrapped", "v3"),
    "75_oldest.sql": _proc("triple_wrapped", "v1"),
    "92_middle.sql": _proc("triple_wrapped", "v2"),
}


def test_apply_order_winner_is_the_highest_number_not_the_lexically_last_file(tmp_path, monkeypatch, capsys):
    _rig(tmp_path, monkeypatch, _TRIPLE_WRAPPED_TREE, [_registry_row("triple_wrapped", "v3")])
    proc_defs, heartbeat_calls, offsets_by_file = sq.collect_bigquery()
    winners, resolve_errors = sq.resolve_winners(proc_defs, heartbeat_calls, offsets_by_file)
    assert resolve_errors == []
    version, filename, _line = winners["triple_wrapped"]
    assert (version, filename) == ("v3", "100_newest.sql")
    assert sq.main() == 0, capsys.readouterr().out


def test_apply_order_mismatch_names_the_highest_numbered_file_not_the_lowest(tmp_path, monkeypatch, capsys):
    # Vacuity companion to the above: registry is stale, still expecting the OLDEST (75_oldest.sql,
    # superseded twice over) body's version. The reported mismatch must cite bigquery/100_newest.sql
    # as the source of the live 'v3', never bigquery/75_oldest.sql -- proving the winner really was
    # resolved by NUMBER, not by iteration/lexical order.
    _rig(tmp_path, monkeypatch, _TRIPLE_WRAPPED_TREE, [_registry_row("triple_wrapped", "v1")])
    assert sq.main() == 1
    out = capsys.readouterr().out
    assert "bigquery/100_newest.sql" in out
    assert "body reports 'v3'" in out
    assert "bigquery/75_oldest.sql" not in out
    assert "bigquery/92_middle.sql" not in out


# ---- vacuity guard: the checker must actually FAIL on a planted violation -----------------------

def test_vacuity_guard_a_known_good_tree_starts_green_and_a_single_bump_makes_it_red(tmp_path, monkeypatch):
    # The single most important test in this file. A checker that always exits 0 (e.g. a regex that
    # silently stopped matching, or a comparison that got dropped in a refactor) is worse than no
    # checker at all -- it would let a real registry/heartbeat drift ship straight through CI green,
    # exactly the failure mode the two live incidents in this script's module docstring describe.
    good_bq = {"75_wrappers.sql": _proc("cadence_check", "v7")}
    good_registry = [_registry_row("cadence_check", "v7")]
    _rig(tmp_path, monkeypatch, good_bq, good_registry)
    assert sq.main() == 0, "fixture itself must be well-formed before perturbing it"

    # Perturb ONLY a COPY of the fixture data (tmp_path, never the repo) -- bump the registry's
    # expected version by one, exactly the shape of the real 0b9fd49 incident (heartbeat literal
    # bumped without the registry follow-up). The checker MUST flip to failing.
    bad_registry = [_registry_row("cadence_check", "v8")]
    _rig(tmp_path, monkeypatch, good_bq, bad_registry)
    assert sq.main() == 1, "checker failed to catch a real version mismatch -- it is checking nothing"


# ---- comment-stripping: a commented-out definition must not count as real ------------------------

def test_commented_out_procedure_is_not_treated_as_a_real_definition(tmp_path, monkeypatch, capsys):
    # Same bug class check_superseded_markers.py was bitten by (bigquery/02_ai_layer.sql:23's
    # "Reproduce:" doc recipe matching as a live CREATE) -- this script shares strip_sql_comments()
    # for the same reason and must not treat a documentation example as a live procedure/heartbeat.
    commented = (
        "-- Example:\n"
        f"--   CREATE OR REPLACE PROCEDURE `{PROJECT}.ops.sp_sq_ghost`() BEGIN\n"
        f"--     CALL `{PROJECT}.ops.sp_beat_heartbeat`('sq:ghost', 'v1', 'ghost ran');\n"
        "--   END;\n"
    )
    _rig(tmp_path, monkeypatch, {"10_doc.sql": commented}, [])
    proc_defs, heartbeat_calls, _offsets = sq.collect_bigquery()
    assert "ghost" not in proc_defs
    assert "ghost" not in heartbeat_calls
    assert sq.main() == 0


# ---- regex-level unit tests for the documented escape-aware quoted-string trap -------------------

def test_struct_row_regex_matches_first_row_with_as_labels():
    text = ("STRUCT('cadence_check' AS sq_name, 'v7' AS expected_version, "
            "'some note' AS git_note, 24 AS expected_interval_hours),\n")
    m = sq.STRUCT_ROW.search(text)
    assert m is not None
    assert (m.group(1), m.group(2)) == ("cadence_check", "v7")


def test_struct_row_regex_matches_positional_later_rows():
    text = "STRUCT('embed_pending', 'v2', 'plain note', 24),\n"
    m = sq.STRUCT_ROW.search(text)
    assert m is not None
    assert (m.group(1), m.group(2)) == ("embed_pending", "v2")


def test_struct_row_regex_survives_an_escaped_quote_inside_git_note():
    # bigquery/63's real git_note text embeds \' (e.g. "W5\'s weekly belt-and-suspenders...",
    # "bigquery/79_b3_promotion.sql\'s header spec"). A naive '(?:[^']*)' field pattern would stop at
    # that escaped quote and misparse (or entirely miss) every subsequent field on the row.
    text = r"STRUCT('cadence_check', 'v7', 'covers W5\'s weekly belt-and-suspenders logic', 24),"
    m = sq.STRUCT_ROW.search(text)
    assert m is not None
    assert m.group(1) == "cadence_check"
    assert m.group(2) == "v7"
    assert m.group(4) == "24"


def test_heartbeat_call_regex_captures_name_and_version():
    text = (f"CALL `{PROJECT}.ops.sp_beat_heartbeat`('sq:cadence_check', 'v9', "
            "'cadence_check.sql ran');\n")
    m = sq.HEARTBEAT_CALL.search(text)
    assert m is not None
    assert (m.group(1), m.group(2)) == ("cadence_check", "v9")
