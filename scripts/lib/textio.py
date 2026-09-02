"""One place to read a repo file as text, bytes, or YAML (codebase audit 2026-07-29).

WHY THIS EXISTS. Every checker under scripts/ reads the same handful of repo files — ops/cadence.yaml,
strategy/roster.yaml, ops/autonomy_levels.yaml, Claude_Task_Plan.md, bigquery/*.sql — and each one
re-derived its own reading idiom. Three separate problems came out of that:

1. TWO SPELLINGS OF THE SAME READ. Most call sites were the bare
   `open(path, encoding="utf-8").read()` / `yaml.safe_load(open(path, encoding="utf-8")) or {}`
   one-liner, which leaves the handle to be closed by refcounting (fine on CPython, a ResourceWarning
   under `-W error` and a real leak on any other runtime). A 2026-07-29 pass converted roughly a
   quarter of them to `with open(...)` blocks and left the rest, so a single file could carry both
   spellings a few lines apart — strictly worse than either uniform state, because a reader can no
   longer tell whether a bare `open()` at a given site is an oversight or a deliberate exception.

2. FOUR SPELLINGS OF THE "MISSING FILE" GUARD. `load_stages()` returned `{}`, `roster_active_codes()`
   returned `set()`, `scenario_docs()` returned `None`, and `main()` inlined
   `if os.path.exists(...): ... else: _doc = {}`. Each is a hand-rolled version of "absent file
   behaves like an empty document", and the same pass that started (1) also *re-introduced* the guard
   twice more inside a single file. The duplication was actively growing.

3. `or {}` WAS LOAD-BEARING AND EASY TO FORGET. `yaml.safe_load` returns None for an empty or
   all-comments document, so every caller that omits the `or {}` turns an empty config into an
   AttributeError on the next `.get()` instead of a clean "nothing declared" path.

load_yaml() collapses all three: the handle is scoped, a missing file and an empty document both
yield the same empty mapping, and no caller has to remember `or {}` again.

NOT A BEHAVIOR CHANGE. Callers that must DISTINGUISH "file absent" from "file empty" — scenario_docs()
in check_roster_consistency.py returns None for absent so its caller can skip the whole R-J check, and
several main() blocks emit a specific error naming the missing file — keep their own os.path.exists()
test and use these helpers only for the read itself. Do not collapse those; the distinction is the
check.
"""
import os
import re

import yaml


def read_text(path):
    """Whole file decoded as UTF-8. The one spelling for "read this repo file as text".

    NOT byte-identical: this uses Python's default universal-newline translation, so a source CRLF
    (or bare \\r) silently becomes \\n. Fine for callers that immediately `.split("\n")` or
    `.splitlines()` this function's own return value — they want LF-normalized lines, not a
    byte-exact copy (a call-site count isn't pinned here on purpose: it was wrong the moment it was
    first written this same pass, having been eyeballed against a broader grep than genuine
    read_text()-chained call sites, and any count frozen in prose goes stale on the next such call
    site added or removed). A caller that promises a byte-identical round-trip of its source (e.g. a
    generator whose own `--check` claims byte-identity) must use read_text_preserving_newlines()
    below instead — see tooling-misc#2, same pass.
    """
    with open(path, encoding="utf-8") as f:
        return f.read()


def read_bytes(path):
    """Whole file as raw bytes — for hashing, where decoding would be wrong (see
    check_roster_consistency.py's compute_spec_hash: the spec_hash must cover the exact bytes on
    disk, not a re-encoding of them)."""
    with open(path, "rb") as f:
        return f.read()


def read_text_preserving_newlines(path):
    """Whole file decoded as UTF-8 with NO newline translation — a CRLF or bare \\r on disk comes
    back exactly as \\r\\n or \\r, not silently collapsed to \\n.

    Same fix, same reasoning, as scripts/adversarial_review_storage.py's parse_legacy_review(),
    which reads `path.read_bytes().decode("utf-8")` instead of `Path.read_text()` specifically
    because (that function's own comment) "Path.read_text() uses universal-newline translation,
    which would turn a canonical CRLF body into LF before its audit hash or repair write." read_text()
    above has the identical blind spot: split_task_plan.py and split_strategy.py both ingest their
    source file through it while their own docstrings claim `--check` proves a byte-identical slice
    tree — a claim that CRLF content would silently falsify, since both sides of that comparison
    would run through the same lossy read and stay agreeing-but-wrong. Use this reader (paired with
    lib/slice_writer.py's newline="" write/check-read) for any caller that makes that promise
    (tooling-misc#2, code-quality pass 2026-08-31).
    """
    return read_bytes(path).decode("utf-8")


def load_yaml(path, missing=None):
    """Parse `path` as YAML and return the document.

    Returns `missing` (default: a fresh empty dict) when the file does not exist, and an empty dict
    when the file exists but parses to None (empty, or comments only). Both cases therefore support
    `.get(...)` without a guard, which is what every caller wanted and what the `or {}` idiom was
    hand-rolling at each site.

    `missing` exists for the few callers whose absent-file case is a DIFFERENT empty than {} — e.g.
    `load_yaml(p, missing=set())`. It is not a way to detect absence: prefer an explicit
    os.path.exists() test at the call site when the distinction drives a check, since that reads as
    the check it is. See this module's docstring.
    """
    if not os.path.exists(path):
        return {} if missing is None else missing
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


# The repo's single most-repeated YAML trap: an UNQUOTED "HH:MM" scalar (e.g. `21:00`) YAML-1.1-parses
# as base-60 sexagesimal -- an INT (1260), not the string a caller wants -- so the only reliable guard
# is "is this actually a string matching HH:MM", not "does str(value) look right". HHMM_RE is the one
# regex every caller of validate_hhmm_field() below shares, so the shape rule itself cannot drift out
# of sync with the message that describes it.
HHMM_RE = re.compile(r"^\d{2}:\d{2}$")


def validate_hhmm_field(value, field_name):
    """None when `value` is a quoted "HH:MM" string; otherwise the STANDARD drift-guard message for
    the base-60 trap described above. `field_name` is the CALLER's own leading field-path text (e.g.
    "ops/cadence.yaml: cadence_watch_deadline_local" or "D1: expected_trigger.time_local") so the same
    message reads correctly at every call site without this helper needing to know the object's
    identity.

    Extracted 2026-09-02 ('hhmm-validation-triplicated' finding, code-quality pass): this exact
    message -- byte-identical at two of its three sites -- used to be copy-pasted at THREE independent
    call sites in TWO files with nothing keeping them in sync: scripts/check_cadence_consistency.py's
    check D (cadence_watch_deadline_local) and check I (expected_trigger.time_local), and
    scripts/check_cron_dst_safety.py's load_cadence() (the SAME cadence_watch_deadline_local field, a
    second file entirely, whose own comment said it deliberately mirrored check D's wording with
    nothing enforcing that). A wording or regex fix landed in one could silently desync the other two
    with zero CI signal -- a reader hitting the trap in one script and fixing the OTHER script's copy
    from memory would leave the third permanently stale. Single-sourcing both the message AND the
    HH:MM shape regex here (HHMM_RE) means all three call sites read the SAME rule and the SAME
    wording going forward; the shape check itself can no longer drift out of sync with the message
    that describes it either.
    """
    if isinstance(value, str) and HHMM_RE.match(value):
        return None
    return (f"{field_name} must be a quoted \"HH:MM\" string (got {value!r} — an UNquoted 21:00 is "
            f"YAML base-60 = 1260; always quote it)")
