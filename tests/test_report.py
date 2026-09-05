"""Guard scripts/lib/report.py's fail_or_ok() — the shared FAIL/OK terminal-report block adopted by
several scripts/check_*.py checkers (code-quality pass 2026-08-31, cross-cutting#0). See that
module's docstring for the duplication class this closes and for the call sites deliberately left
unconverted because they don't fit this exact shape.
"""
from lib.report import fail_or_ok


def test_empty_errors_prints_ok_line_verbatim_and_returns_0(capsys):
    assert fail_or_ok("WIDGET", [], "WIDGET: OK — 3 thing(s) checked.") == 0
    assert capsys.readouterr().out == "WIDGET: OK — 3 thing(s) checked.\n"


def test_empty_errors_list_is_falsy_same_as_none_would_be(capsys):
    # errors=[] (the real shape every caller passes when clean) must take the OK branch, not be
    # mistaken for "some truthy sentinel" -- this is just `if errors:` on a list, but pin it since a
    # caller passing errors=None instead would also need to hit this same branch.
    assert fail_or_ok("WIDGET", [], "WIDGET: OK") == 0
    out = capsys.readouterr().out
    assert "FAIL" not in out


def test_single_error_prints_fail_header_and_one_bullet(capsys):
    code = fail_or_ok("WIDGET", ["thing one is broken"], "WIDGET: OK")
    assert code == 1
    out = capsys.readouterr().out
    assert out == "WIDGET: FAIL\n\n - thing one is broken\n"


def test_multiple_errors_print_one_bullet_each_in_given_order(capsys):
    errors = ["zebra error", "apple error", "mango error"]
    code = fail_or_ok("WIDGET", errors, "WIDGET: OK")
    assert code == 1
    out = capsys.readouterr().out
    assert out == (
        "WIDGET: FAIL\n"
        "\n"
        " - zebra error\n"
        " - apple error\n"
        " - mango error\n"
    )


def test_sort_true_sorts_the_bullets_alphabetically(capsys):
    errors = ["zebra error", "apple error", "mango error"]
    code = fail_or_ok("WIDGET", errors, "WIDGET: OK", sort=True)
    assert code == 1
    out = capsys.readouterr().out
    assert out == (
        "WIDGET: FAIL\n"
        "\n"
        " - apple error\n"
        " - mango error\n"
        " - zebra error\n"
    )


def test_sort_false_is_the_default_and_preserves_caller_order(capsys):
    errors = ["b error", "a error"]
    fail_or_ok("WIDGET", errors, "WIDGET: OK")
    out = capsys.readouterr().out
    assert out == "WIDGET: FAIL\n\n - b error\n - a error\n"


def test_sort_does_not_mutate_the_callers_list_in_place(capsys):
    # sorted(errors) returns a new list; the caller's own `errors` list (which several checkers keep
    # referencing, or re-derive counts from, after the report call) must not be reordered as a
    # side effect.
    errors = ["z", "a"]
    fail_or_ok("WIDGET", errors, "WIDGET: OK", sort=True)
    assert errors == ["z", "a"]


def test_hint_paragraph_is_printed_after_the_bullets_blank_line_led(capsys):
    code = fail_or_ok("WIDGET", ["broken"], "WIDGET: OK", hint="Fix the widget and re-run.")
    assert code == 1
    out = capsys.readouterr().out
    # The hint is its own blank-line-led paragraph after the bullets: the bullet loop's own
    # print(" - broken") already ends the line, then print("\n" + hint) adds a blank line before it.
    assert out == "WIDGET: FAIL\n\n - broken\n\nFix the widget and re-run.\n"


def test_no_hint_by_default_prints_nothing_after_the_bullets(capsys):
    fail_or_ok("WIDGET", ["broken"], "WIDGET: OK")
    out = capsys.readouterr().out
    assert out == "WIDGET: FAIL\n\n - broken\n"


def test_hint_is_skipped_on_the_ok_path_even_if_given(capsys):
    # A caller has no reason to pass hint= alongside empty errors, but the helper must not print it
    # if it does -- hint is FAIL-only by construction (`if hint:` sits inside `if errors:`).
    code = fail_or_ok("WIDGET", [], "WIDGET: OK — clean.", hint="never shown")
    assert code == 0
    assert capsys.readouterr().out == "WIDGET: OK — clean.\n"


def test_empty_string_hint_is_treated_as_no_hint(capsys):
    # hint="" is falsy, same as hint=None -- a caller building a hint conditionally and landing on
    # "" must not get a stray blank paragraph.
    code = fail_or_ok("WIDGET", ["broken"], "WIDGET: OK", hint="")
    assert code == 1
    # The return code alone cannot see the documented property: `if hint: print("\n" + hint)` sits
    # inside the `if errors:` branch and does not influence `return 1`, so without this stdout
    # assertion the test passed byte-for-byte even if the stray paragraph WAS printed. Exact-output
    # shape, matching test_no_hint_by_default_prints_nothing_after_the_bullets.
    assert capsys.readouterr().out == "WIDGET: FAIL\n\n - broken\n"


def test_title_is_used_only_for_the_fail_header_not_the_ok_line(capsys):
    # ok_line is the caller's own fully-composed string (see module docstring: callers disagree on
    # the FAIL/OK separator glyph and on how much detail follows it) -- `title` must not leak into
    # it a second time.
    fail_or_ok("WIDGET", [], "totally different OK wording, no WIDGET prefix at all")
    out = capsys.readouterr().out
    assert out == "totally different OK wording, no WIDGET prefix at all\n"


def test_real_call_site_shape_matches_the_hand_rolled_original():
    # Reproduces the exact hand-rolled block every adopting checker used to carry (see
    # scripts/check_autonomy_consistency.py before the 2026-08-31 conversion): title/errors/hint on
    # the FAIL side, a fully composed f-string on the OK side.
    errors = []
    ok = fail_or_ok(
        "AUTONOMY CONSISTENCY", errors,
        "AUTONOMY CONSISTENCY: OK — 8 stage citation(s) match ops/autonomy_levels.yaml "
        "(10 registered loop(s)).",
        hint="Fix the stale prose/SQL citation OR ops/autonomy_levels.yaml so they agree.",
    )
    assert ok == 0
