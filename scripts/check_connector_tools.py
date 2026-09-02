#!/usr/bin/env python3
"""Connector tool-inventory single-source: ops/connector_tools.yaml (drift class: new-tool stall).

WHY THIS EXISTS (2026-08-08). scripts/check_settings_toolcov.py's own docstring is now explicit
(see this session's docstring fix) that its coverage is deliberately limited to full `mcp__Server__tool`
tokens in routine text -- a small subset of the plan's tool references (the count drifts as prose
changes; that script prints it each run). Routine prose overwhelmingly writes
BARE backticked names instead (`` `get_account_summary` ``, `` `list_labels` ``), which that checker
cannot see at all: Gmail's `list_labels` is called every morning by OPS1 and was invisible to any CI
gate before this file existed. Two separate failure modes follow from that blind spot:

  (a) a routine calls a bare-named tool that is not allowlisted in .claude/settings.json, which stalls
      an unattended session on an unanswerable permission prompt (the same failure class
      check_settings_toolcov.py exists to catch, just on tokens it cannot parse), and
  (b) a routine calls a bare-named tool that no longer EXISTS -- the vendor retired it -- which is a
      silent dead-instruction bug, not a permission stall. This is not hypothetical: as of this file's
      introduction, Claude_Task_Plan.md still instructs D1 to run a Hugging Face `paper_search` query
      even though ops/connector_tools.yaml (and the plan's own Q3/A1 sections) record that tool as
      verified gone since 2026-07-28.

ops/connector_tools.yaml (see that file's own header) is the hand/routine-maintained EXPECTED inventory
per connector: which tools exist, whether the fleet needs them (`use: required|optional|unused`), and
which named tools are verified ABSENT (vendor-retired). This script cross-checks that manifest against
(1) itself, (2) .claude/settings.json's permissions.allow array, and (3) Claude_Task_Plan.md's routine
prose, in both directions -- required-but-unallowlisted (mirrors check_settings_toolcov.py's own
one-direction guard) AND called-but-retired (a check that checker structurally cannot express, since it
only ever asks "is this token allowlisted", never "does this tool still exist").

CHECKS (each accumulates findings; none exits early):

  CHECK 1 -- MANIFEST INTERNAL VALIDITY. A connector missing `name`/`connector_uuid`/`settings_prefix`/
  `tools` (present-but-null or empty counts as missing, same as absent -- a bare `tools:` key with no
  list under it is not a zero-tool connector, it's a malformed one); a `tools` or `absent` entry with
  no `name`; a tool `use` value outside {required, optional, unused}; a tool name declared twice within
  one connector's `tools`; a name present in BOTH `tools` and `absent` for the same connector; two
  connectors whose `settings_prefix` values are identical or one a proper prefix of the other (the
  invariant resolve_full_token() and CHECK 5 both assume when they stop at the first prefix match).

  CHECK 2 -- REQUIRED TOOLS MUST BE ALLOWLISTED. Every tool with `use: required` must have
  `<settings_prefix><name>` present in .claude/settings.json's permissions.allow, by EXACT string match
  only. No wildcard/server-level credit: mirrors check_settings_toolcov.py's own docstring reasoning
  (load_allowlist()) -- the harness does not expand a `mcp__Server__*` or bare `mcp__Server` grant into
  per-tool approvals at call time, so honoring one here would be a false negative (a tool that would
  still stall an unattended session reported as covered).

  CHECK 3 -- ROUTINE TEXT CALLS ONLY DECLARED TOOLS. Claude_Task_Plan.md is scanned for bare backticked
  identifiers (`` `name` ``) and full `mcp__<Server>__<tool>` tokens. A bare name that resolves to
  EXACTLY ONE connector's declared `tools` entry, and is not `prose_ambiguous`, must have `use: required`
  in the manifest -- calling a tool the manifest calls optional/unused means either the manifest or the
  routine text is wrong. A bare name resolving to MORE THAN ONE connector is skipped here and reported
  separately, non-fatally, as "ambiguous across connectors". `prose_ambiguous` names are skipped
  entirely UNLESS they appear in full `mcp__` form, where the qualified prefix removes the ambiguity a
  bare English word (`chart`, `news`, `quote`, ...) would otherwise carry.

  CHECK 4 -- NO ROUTINE TEXT CALLS A RETIRED TOOL. Any bare or full-form reference to a name listed under
  a connector's `absent:` block is a HARD FAILURE, reported with file:line and the manifest's `note` --
  this is the live paper_search/space_search bug class described above, and the entire reason this
  checker exists on top of check_settings_toolcov.py.

  CHECK 5 -- NO STALE ALLOWLIST ENTRIES. Any `mcp__*` entry in .claude/settings.json's permissions.allow
  whose `<prefix><tool>` matches no manifest `tools` entry for ANY connector is a finding, naming which
  connector prefix it belongs to and whether the tool is recorded in that connector's `absent` list (the
  expected explanation for a stale-but-still-granted permission). An entry whose prefix does not belong
  to any manifest connector at all (this manifest inventories the claude.ai connectors this fleet uses,
  not every mcp__ tool in existence -- e.g. Claude Code's own RemoteTrigger surface) is out of scope and
  not reported. An entry explained by an `absent` record with `verified: unconfirmed` is REPORT-ONLY /
  NON-FATAL -- those are pending confirmation by the first live OPS1 tool-inventory run and must not
  redden CI over a not-yet-confirmed removal; every other stale entry is a hard failure.

SELF-MATCH TRAP / IGNORE FENCE. This checker scans Claude_Task_Plan.md, and routine sections legitimately
discuss tool names in ways that are not calls -- most notably the historical notes explaining that
`paper_search` / `space_search` no longer exist, which themselves NAME the retired tool in backticks.
Lines between

    <!-- connector-tools-checker: ignore-start -->
    <!-- connector-tools-checker: ignore-end -->

are skipped entirely by CHECKS 3 and 4 (mirrors the exempt_line_regex idea in
scripts/check_prose_invariants.py, but as an explicit paired fence rather than a per-line regex, since
the passages needing exemption here are prose paragraphs, not single lines). Wrap a documentary mention
in the fence when it is genuinely not an instruction to call the tool; do NOT wrap an active call site --
CHECK 4 existing to catch exactly those is the point.

Usage:  python scripts/check_connector_tools.py        # exit 0 if consistent, 1 + diff if not
"""
import json
import os
import re
import sys

try:
    import yaml  # noqa: F401 -- kept for this early, actionable failure message; the actual parsing
    # below goes through lib.textio.load_yaml(), which imports yaml itself and would otherwise raise
    # the same missing-dependency error as a bare traceback instead of this one.
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

from lib.mcp_tokens import MCP_TOKEN, load_allow_entries
from lib.textio import load_yaml, read_text

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "ops", "connector_tools.yaml")
TASK_PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")
SETTINGS_JSON = os.path.join(ROOT, ".claude", "settings.json")

USE_VALUES = frozenset({"required", "optional", "unused"})

# A bare backtick-delimited identifier, e.g. `` `get_account_summary` `` -- exactly one token, nothing
# else inside the backticks (no parens, no spaces), so an ordinary prose backtick-quoted phrase does not
# accidentally match.
BARE_NAME = re.compile(r"`([A-Za-z_][A-Za-z0-9_]*)`")
# MCP_TOKEN (a full mcp__<Server>__<tool> token, backtick-wrapped or bare in running text) is now
# imported from lib/mcp_tokens.py above -- it used to be a byte-identical private copy of
# check_settings_toolcov.py's, with a comment naming the coupling but nothing enforcing it
# (quality pass 2026-08-22).
#
# MCP_ALLOW_TOKEN -- "an allow-list entry that is itself an exact mcp__ tool token (excludes
# Bash(...) and similar)" -- is gone with it: `re.compile(r"^mcp__[A-Za-z0-9_]+$").match(x)` is
# just `MCP_TOKEN.fullmatch(x)` spelled as a THIRD copy of the same shape, and
# check_settings_toolcov.py's load_allowlist() already expressed the identical test as
# `MCP_TOKEN.fullmatch(a)`. Verified equivalent on the live .claude/settings.json (48 entries, zero
# disagreements, no entry carrying trailing whitespace); the only inputs on which `^...$` + match
# and fullmatch can differ are strings with a trailing newline, which the two gates previously
# classified DIFFERENTLY -- so unifying here removes a real, if narrow, disagreement rather than
# introducing one.

IGNORE_START = "<!-- connector-tools-checker: ignore-start -->"
IGNORE_END = "<!-- connector-tools-checker: ignore-end -->"


def _connector_label(c, idx):
    return c.get("name") or f"<connector #{idx}>"


def check1_manifest_validity(connectors, findings):
    """CHECK 1: manifest self-consistency -- required fields, valid `use` values, no duplicate tool
    name within a connector, no name shared between `tools` and `absent` for the same connector, and
    (across connectors) no `settings_prefix` that is a proper prefix of -- or identical to -- another
    connector's `settings_prefix`."""
    if not connectors:
        findings.append("CHECK1: ops/connector_tools.yaml declares zero connectors (empty or missing "
                         "`connectors:` list)")
        return

    for idx, c in enumerate(connectors):
        if not isinstance(c, dict):
            findings.append(f"CHECK1: connectors[{idx}] is not a mapping")
            continue
        cname = _connector_label(c, idx)

        for field in ("name", "connector_uuid", "settings_prefix"):
            if not c.get(field):
                findings.append(f"CHECK1: connector {cname} is missing required field `{field}`")
        # `not c.get("tools")` (not `"tools" not in c`) so a PRESENT-but-null `tools:` key -- e.g.
        # a hand-edit that deletes every list item but leaves the bare key behind -- is flagged the
        # same as a missing one. `"tools" not in c` only caught the key's ABSENCE: with the key
        # present and null, this finding was silently skipped, `tools = c.get("tools")` came back
        # None, the `tools is not None` guard just below never fired, and `tools = tools or []`
        # quietly turned it into an empty list -- a connector's entire `use: required` tool set
        # could vanish from CHECK2's allowlist coverage with no diagnostic anywhere (2026-09-02).
        if not c.get("tools"):
            findings.append(f"CHECK1: connector {cname} is missing required field `tools`")

        tools = c.get("tools")
        if tools is not None and not isinstance(tools, list):
            findings.append(f"CHECK1: connector {cname}'s `tools` must be a list, "
                             f"got {type(tools).__name__}")
            tools = []
        tools = tools or []

        seen_counts = {}
        for t in tools:
            if not isinstance(t, dict) or t.get("name") is None:
                findings.append(f"CHECK1: connector {cname} has a `tools` entry with no `name`")
                continue
            tname = t["name"]
            seen_counts[tname] = seen_counts.get(tname, 0) + 1
            use = t.get("use")
            if use not in USE_VALUES:
                findings.append(f"CHECK1: connector {cname} tool `{tname}` has invalid `use`: "
                                 f"{use!r} (must be one of {sorted(USE_VALUES)})")
        for tname, count in seen_counts.items():
            if count > 1:
                findings.append(f"CHECK1: connector {cname} declares tool `{tname}` {count} times "
                                 f"in `tools`")

        absent = c.get("absent")
        if absent is not None and not isinstance(absent, list):
            findings.append(f"CHECK1: connector {cname}'s `absent` must be a list, "
                             f"got {type(absent).__name__}")
            absent = []
        # Parallel to the `tools` loop above: a malformed `absent` entry (e.g. a `nam:` typo instead
        # of `name:`) used to be silently dropped by the `absent_names` comprehension below with no
        # finding raised at all -- unlike its `tools` sibling, which has flagged a name-less entry
        # since this check was written. That asymmetry mattered: CHECK4 (the retired-tool gate) reads
        # `absent_by_name`/`absent_full`, built from this same list, so a typo'd `absent:` entry did
        # not just fail to record a retirement -- it made CHECK4 structurally unable to ever catch a
        # routine calling that retired tool again, with the manifest looking clean.
        for a in (absent or []):
            if not isinstance(a, dict) or a.get("name") is None:
                findings.append(f"CHECK1: connector {cname} has an `absent` entry with no `name`")
        absent_names = {a["name"] for a in (absent or [])
                        if isinstance(a, dict) and a.get("name") is not None}
        overlap = set(seen_counts) & absent_names
        for tname in sorted(overlap):
            findings.append(f"CHECK1: connector {cname} lists `{tname}` in BOTH `tools` and `absent`")

    # Cross-connector: resolve_full_token() (below) and check5_stale_allowlist() both walk connectors
    # in manifest order and return on the FIRST `settings_prefix` that is a string-prefix of a token,
    # on the explicit assumption that prefixes never overlap -- see resolve_full_token()'s own comment
    # ("prefixes are disjoint, stop here"). Nothing enforced that assumption until now: today's real
    # prefixes (mcp__FMP__, mcp__Gmail__, ...) happen to be pairwise disjoint, but a future connector
    # added with a shorter, overlapping prefix ahead of an existing one in `connectors:` (e.g. a
    # hypothetical generic `mcp__Google_` positioned before `mcp__Google_Calendar__`) would silently
    # steal every full-token match belonging to the longer-prefixed connector -- CHECK4 would check
    # retirement against the wrong connector's `absent` list and CHECK5 would misattribute a stale
    # entry, with no error marking the misattribution. O(n^2) pairwise is fine here: connector count
    # is ~7, this runs once per CI invocation, and it guards the load-bearing invariant at its root
    # (the manifest itself) instead of leaving each first-match call site to assume it silently.
    prefixed = [(c.get("settings_prefix"), _connector_label(c, idx)) for idx, c in enumerate(connectors)
                if isinstance(c, dict) and c.get("settings_prefix")]
    for i, (prefix_a, name_a) in enumerate(prefixed):
        for prefix_b, name_b in prefixed[i + 1:]:
            if prefix_a == prefix_b:
                findings.append(
                    f"CHECK1: connectors {name_a} and {name_b} declare the IDENTICAL "
                    f"`settings_prefix` {prefix_a!r} -- full mcp__ token resolution "
                    f"(resolve_full_token()/CHECK5) requires prefixes to be unambiguous"
                )
            elif prefix_b.startswith(prefix_a):
                findings.append(
                    f"CHECK1: connector {name_a}'s `settings_prefix` {prefix_a!r} is a proper "
                    f"prefix of connector {name_b}'s {prefix_b!r} -- a full mcp__ token belonging "
                    f"to {name_b} would incorrectly resolve against {name_a} first "
                    f"(resolve_full_token()/CHECK5 both stop at the first prefix match)"
                )
            elif prefix_a.startswith(prefix_b):
                findings.append(
                    f"CHECK1: connector {name_b}'s `settings_prefix` {prefix_b!r} is a proper "
                    f"prefix of connector {name_a}'s {prefix_a!r} -- a full mcp__ token belonging "
                    f"to {name_a} would incorrectly resolve against {name_b} first "
                    f"(resolve_full_token()/CHECK5 both stop at the first prefix match)"
                )


def load_allow_set():
    """The raw string entries of .claude/settings.json's permissions.allow -- not filtered to mcp__
    tokens here (CHECK5 filters via MCP_TOKEN itself), so a malformed non-string entry is simply
    not an mcp__ token and is naturally skipped downstream rather than crashing a regex match.

    Delegates the actual read/parse to lib.mcp_tokens.load_allow_entries() -- shared with
    check_settings_toolcov.py's load_allowlist(), which used to carry a byte-identical copy of this
    open/json.load/`.get("permissions", {}).get("allow", [])` extraction (cross-cutting#1, 2026-08-31
    code-quality pass)."""
    return load_allow_entries(SETTINGS_JSON)


def check2_required_allowlisted(connectors, allow_set, findings):
    """CHECK 2: every `use: required` tool's exact `<settings_prefix><name>` token must be present in
    .claude/settings.json's permissions.allow. EXACT STRING MATCH ONLY -- mirrors
    check_settings_toolcov.py's load_allowlist() docstring: the harness does not expand a
    `mcp__Server__*` wildcard or a bare `mcp__Server` grant into per-tool approvals at call time, so
    crediting one here would be a false negative (a tool that would still stall an unattended session,
    reported as covered)."""
    for idx, c in enumerate(connectors):
        if not isinstance(c, dict):
            continue
        cname = _connector_label(c, idx)
        prefix = c.get("settings_prefix") or ""
        for t in c.get("tools") or []:
            if not isinstance(t, dict) or t.get("use") != "required":
                continue
            tname = t.get("name")
            if tname is None:
                continue
            full = f"{prefix}{tname}"
            if full not in allow_set:
                findings.append(
                    f"CHECK2: connector {cname} tool `{tname}` is `use: required` but `{full}` is not "
                    f"in .claude/settings.json permissions.allow (exact-string match only -- a "
                    f"wildcard or server-level grant is not coverage, see "
                    f"check_settings_toolcov.py's load_allowlist() docstring)"
                )


def ignored_line_mask(lines):
    """True for each line index inside an `ignore-start`/`ignore-end` fence (inclusive of the marker
    lines themselves). An unterminated ignore-start (no matching ignore-end before EOF) leaves every
    subsequent line ignored -- a missing END is a documentation bug, not a reason to silently un-skip
    and start reporting mid-fence content as if it were live routine text."""
    mask = []
    ignored = False
    for line in lines:
        if IGNORE_START in line:
            ignored = True
            mask.append(True)
            continue
        if IGNORE_END in line:
            mask.append(True)
            ignored = False
            continue
        mask.append(ignored)
    return mask


def scan_task_plan_references():
    """Return (bare_refs, full_refs): lists of (1-based lineno, matched text) for every bare backticked
    identifier and every full mcp__ token in TASK_PLAN, excluding ignore-fenced lines."""
    text = read_text(TASK_PLAN)
    lines = text.split("\n")
    mask = ignored_line_mask(lines)
    bare_refs = []
    full_refs = []
    for i, line in enumerate(lines):
        if mask[i]:
            continue
        lineno = i + 1
        for m in BARE_NAME.finditer(line):
            bare_refs.append((lineno, m.group(1)))
        for m in MCP_TOKEN.finditer(line):
            full_refs.append((lineno, m.group(0)))
    return bare_refs, full_refs


def resolve_full_token(connectors, token):
    """Resolve a full mcp__<Server>__<tool> token to (connector_name, 'tool'|'absent', tool_name,
    record), or None if the token's prefix belongs to no manifest connector, or belongs to one but names
    a tool that connector declares neither current nor absent (out of this manifest's scope either way)."""
    for idx, c in enumerate(connectors):
        if not isinstance(c, dict):
            continue
        prefix = c.get("settings_prefix")
        if not prefix or not token.startswith(prefix):
            continue
        cname = _connector_label(c, idx)
        tail = token[len(prefix):]
        for t in c.get("tools") or []:
            if isinstance(t, dict) and t.get("name") == tail:
                return cname, "tool", tail, t
        for a in c.get("absent") or []:
            if isinstance(a, dict) and a.get("name") == tail:
                return cname, "absent", tail, a
        return None  # prefix matched; tail unknown to this connector -- prefixes are disjoint, stop here
    return None


def _absent_finding(rel, lineno, token_display, cname, record):
    verified = record.get("verified")
    note = (record.get("note") or "").strip()
    return (f"CHECK4: {rel}:{lineno}: routine text references RETIRED tool `{token_display}` "
            f"({cname}, verified absent={verified!r}) -- {note}")


def check_task_plan_calls(connectors, findings, ambiguous_notes):
    """CHECKS 3 & 4 in one pass over TASK_PLAN (same source, same ignore-fence)."""
    declared_by_name = {}   # bare tool name -> [(connector_name, tool_record), ...]
    absent_by_name = {}     # bare tool name -> [(connector_name, absent_record), ...]
    for idx, c in enumerate(connectors):
        if not isinstance(c, dict):
            continue
        cname = _connector_label(c, idx)
        for t in c.get("tools") or []:
            if isinstance(t, dict) and t.get("name") is not None:
                declared_by_name.setdefault(t["name"], []).append((cname, t))
        for a in c.get("absent") or []:
            if isinstance(a, dict) and a.get("name") is not None:
                absent_by_name.setdefault(a["name"], []).append((cname, a))

    bare_refs, full_refs = scan_task_plan_references()
    rel = os.path.relpath(TASK_PLAN, ROOT)
    seen_ambiguous = set()
    seen_absent = set()

    for lineno, name in bare_refs:
        # CHECK 4 first: an absent-tool bare reference is a hard finding regardless of CHECK 3 --
        # UNLESS the same bare name is also LIVE-declared by a DIFFERENT connector (quality pass
        # 2026-08-22). A bare name that is retired in one connector and alive in another is exactly
        # the cross-connector ambiguity CHECK 3 below already handles as a non-fatal note; CHECK 4
        # had no such guard and hard-failed CI on it, so a routine legitimately calling the LIVE
        # connector's tool would be reported as "references RETIRED tool" and forced into a bogus
        # rewrite. Dormant on today's manifest (verified: 114 declared names, 5 absent names, zero
        # overlap), but OPS1's AUTO-ADD branch adds new connector tools BY BARE NAME, so the first
        # generic-sounding name a vendor ships that collides with an already-retired name from
        # another vendor lands on it. Reported rather than skipped, so the ambiguity still reaches
        # a human -- it is not safe to silently assume the live connector was the intended one.
        live_elsewhere = {c for c, _t in declared_by_name.get(name, [])}
        for cname, arecord in absent_by_name.get(name, []):
            key = (lineno, name, cname)
            if key in seen_absent:
                continue
            seen_absent.add(key)
            others = sorted(live_elsewhere - {cname})
            if others:
                ambiguous_notes.append(
                    f"{rel}:{lineno}: bare name `{name}` is retired in {cname} but still declared "
                    f"by {', '.join(others)} -- CHECK4 skipped, non-fatal; disambiguate the routine "
                    f"text with the full mcp__<connector>__{name} form if it means {cname}'s."
                )
                continue
            findings.append(_absent_finding(rel, lineno, name, cname, arecord))

        # CHECK 3
        matches = declared_by_name.get(name)
        if not matches:
            continue
        if len(matches) > 1:
            key = name
            if key not in seen_ambiguous:
                seen_ambiguous.add(key)
                connector_names = ", ".join(m[0] for m in matches)
                ambiguous_notes.append(
                    f"{rel}:{lineno}: bare name `{name}` resolves to {len(matches)} connectors "
                    f"({connector_names}) -- skipped, non-fatal"
                )
            continue
        cname, trecord = matches[0]
        if trecord.get("prose_ambiguous"):
            continue
        use = trecord.get("use")
        if use != "required":
            findings.append(
                f"CHECK3: {rel}:{lineno}: routine text calls `{name}` ({cname}) but the manifest "
                f"declares `use: {use}` -- either ops/connector_tools.yaml is wrong or the routine "
                f"should not be calling this tool"
            )

    for lineno, token in full_refs:
        resolved = resolve_full_token(connectors, token)
        if resolved is None:
            continue
        cname, kind, name, record = resolved
        if kind == "absent":
            findings.append(_absent_finding(rel, lineno, token, cname, record))
            continue
        use = record.get("use")
        if use != "required":
            findings.append(
                f"CHECK3: {rel}:{lineno}: routine text calls `{token}` ({cname}) but the manifest "
                f"declares `use: {use}` for `{name}`"
            )


def check5_stale_allowlist(connectors, allow_set, findings, report_only_notes):
    """CHECK 5: an allowlisted mcp__ token that matches no manifest `tools` entry for any connector.
    Skipped entirely (out of scope, no finding) if its prefix belongs to no manifest connector at all --
    this manifest inventories only the claude.ai connectors listed in its own header, not every mcp__
    surface in the harness (e.g. Claude Code's own RemoteTrigger tools)."""
    declared_full = {}   # full token -> (connector_name, tool_name, tool_record)
    absent_full = {}      # full token -> (connector_name, tool_name, absent_record)
    prefix_owner = []     # [(prefix, connector_name), ...]
    for idx, c in enumerate(connectors):
        if not isinstance(c, dict):
            continue
        cname = _connector_label(c, idx)
        prefix = c.get("settings_prefix") or ""
        if prefix:
            prefix_owner.append((prefix, cname))
        for t in c.get("tools") or []:
            if isinstance(t, dict) and t.get("name") is not None:
                declared_full[f"{prefix}{t['name']}"] = (cname, t["name"], t)
        for a in c.get("absent") or []:
            if isinstance(a, dict) and a.get("name") is not None:
                absent_full[f"{prefix}{a['name']}"] = (cname, a["name"], a)

    for entry in sorted(allow_set):
        if not MCP_TOKEN.fullmatch(entry):   # exact mcp__ token only -- skips Bash(...) and similar
            continue
        if entry in declared_full:
            continue  # current -- not stale

        owner = next((cname for prefix, cname in prefix_owner if entry.startswith(prefix)), None)
        if owner is None:
            continue  # out of this manifest's scope entirely -- not reported

        if entry in absent_full:
            cname, tname, arecord = absent_full[entry]
            verified = arecord.get("verified")
            note = (arecord.get("note") or "").strip()
            msg = (f"CHECK5: `{entry}` in .claude/settings.json permissions.allow is stale -- "
                   f"{cname}'s manifest lists `{tname}` as absent (verified={verified!r}). {note}")
            if verified == "unconfirmed":
                report_only_notes.append(msg + " [report-only: pending first live OPS1 confirmation]")
            else:
                findings.append(msg)
        else:
            findings.append(
                f"CHECK5: `{entry}` in .claude/settings.json permissions.allow (connector: {owner}) "
                f"matches no `tools` entry in that connector's manifest and is not recorded as "
                f"`absent` either -- the manifest is missing this tool, or the allowlist entry itself "
                f"is unexplained stale drift"
            )


def main():
    missing = [(name, path) for name, path in (
        ("MANIFEST", MANIFEST), ("TASK_PLAN", TASK_PLAN), ("SETTINGS_JSON", SETTINGS_JSON),
    ) if not os.path.exists(path)]
    if missing:
        print("CONNECTOR TOOLS: FAIL\n")
        rels = ", ".join(f"{name} ({os.path.relpath(path, ROOT)})" for name, path in missing)
        print(f"Required input file(s) not found: {rels}. This gate cannot verify connector tool "
              f"coverage against a source it can't read -- failing closed rather than silently passing "
              f"on an unscanned source (renamed/moved file, or a drifted path constant).")
        return 1

    manifest = load_yaml(MANIFEST)
    connectors = manifest.get("connectors") or []
    if not isinstance(connectors, list):
        print("CONNECTOR TOOLS: FAIL\n")
        print("CHECK1: ops/connector_tools.yaml's `connectors` key must be a list.")
        return 1

    findings = []
    ambiguous_notes = []
    report_only_notes = []

    check1_manifest_validity(connectors, findings)

    try:
        allow_set = load_allow_set()
    except (OSError, json.JSONDecodeError) as exc:
        print("CONNECTOR TOOLS: FAIL\n")
        print(f"CHECK2/CHECK5: could not read/parse .claude/settings.json: {exc}")
        return 1

    check2_required_allowlisted(connectors, allow_set, findings)
    check_task_plan_calls(connectors, findings, ambiguous_notes)
    check5_stale_allowlist(connectors, allow_set, findings, report_only_notes)

    n_connectors = len(connectors)
    n_tools = sum(len(c.get("tools") or []) for c in connectors if isinstance(c, dict))
    n_required = sum(
        1 for c in connectors if isinstance(c, dict)
        for t in (c.get("tools") or []) if isinstance(t, dict) and t.get("use") == "required"
    )

    if findings:
        print("CONNECTOR TOOLS: FAIL\n")
        for f in findings:
            print(" - " + f)
        if ambiguous_notes:
            print("\nAmbiguous across connectors (non-fatal, skipped):")
            for n in ambiguous_notes:
                print(" - " + n)
        if report_only_notes:
            print("\nReport-only, pending confirmation (non-fatal):")
            for n in report_only_notes:
                print(" - " + n)
        print("\nFix: reconcile ops/connector_tools.yaml, .claude/settings.json, and "
              "Claude_Task_Plan.md so declared tool `use`, the allowlist, and routine text all agree. "
              "See this script's module docstring and ops/connector_tools.yaml's own header.")
        return 1

    if ambiguous_notes:
        print("Ambiguous across connectors (non-fatal, skipped):")
        for n in ambiguous_notes:
            print(" - " + n)
    if report_only_notes:
        print("Report-only, pending confirmation (non-fatal):")
        for n in report_only_notes:
            print(" - " + n)

    print(f"CONNECTOR TOOLS: OK -- {n_connectors} connectors, {n_tools} tools, {n_required} required "
          f"all allowlisted.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
