"""The one shared FAIL/OK terminal-report block for scripts/check_*.py (code-quality pass
2026-08-31, cross-cutting#0).

WHY THIS EXISTS. ~13 checkers hand-roll the identical shape:

    if errors:
        print("<NAME>: FAIL\\n")
        for e in errors:
            print(" - " + e)
        [optional trailing hint paragraph]
        return 1
    print(f"<NAME>: OK - ...")
    return 0

...copy-pasted, not shared, with small drift already visible between copies (some sort `errors`
before printing, some print them in check-order; some append a remediation paragraph after the
bullets, some don't). Every other lib/ module in this repo exists to absorb exactly this kind of
duplication class (lib/textio.py for the bare-open idiom, lib/mcp_tokens.py for the settings.json
allow-list read) — this was the largest remaining unconsolidated one.

fail_or_ok() below absorbs ONLY the call sites where doing so is a byte-for-byte no-op. Several
checkers' FAIL block is a genuinely different shape and is deliberately left hand-rolled rather than
bent to fit here:
  - a single un-bulleted fail-closed message for a missing-input precondition, printed as its own
    `print(f"...")` with no bullet loop at all (check_connector_tools.py's missing-manifest/
    malformed-settings guards, check_settings_toolcov.py's missing-source guard) — not this shape;
  - a leading explanatory paragraph BEFORE the bullet loop rather than after it
    (check_settings_toolcov.py's missing-tool-coverage block);
  - more than one independently-conditional bulleted sub-section threaded through both the FAIL and
    OK branches (check_connector_tools.py's ambiguous-notes/report-only-notes, check_roster_
    consistency.py's non-blocking NOTES block) — a second `notes` list is a real, recurring shape of
    its own, but only one call site in this pass has it, and a knob added to cover a single caller is
    worse than that caller's few lines of duplication (see this repo's own "a helper with more
    parameters than call sites is worse than the duplication" standard, applied here the same way
    check_roster_consistency.py's R-F/R-L checks apply it to their own non-blocking-vs-blocking
    split).
See each converted checker's own call site for why it DOES fit.
"""


def fail_or_ok(title, errors, ok_line, *, hint=None, sort=False):
    """Print the shared FAIL/OK terminal block and return the matching process exit code.

    errors: list of message strings already collected by the caller's own checks.
      - Empty (falsy): OK path — print `ok_line` verbatim (the caller's own fully-composed
        "<TITLE>: OK ..." string) and return 0.
      - Non-empty: FAIL path — print "<title>: FAIL\\n", then one " - <e>" bullet per error (in
        `errors`' given order, or sorted first if sort=True — check_sq_version_registry.py's
        `errors` list is assembled out of file-scan order across several independent passes and
        needs a final sort at print time, unlike siblings whose list is already built in report
        order), then `hint` if given as its own blank-line-led paragraph, then return 1.

    `ok_line` is the CALLER's own fully-composed message, not something this helper assembles from
    `title` — callers disagree on the FAIL/OK separator glyph ("—" vs a plain "--") and on how much
    summary detail follows it, so the OK line was never part of the shape being standardized here;
    only the FAIL-side bullet-list mechanics were duplicated verbatim across callers.
    """
    if errors:
        print(f"{title}: FAIL\n")
        for e in (sorted(errors) if sort else errors):
            print(" - " + e)
        if hint:
            print("\n" + hint)
        return 1
    print(ok_line)
    return 0
