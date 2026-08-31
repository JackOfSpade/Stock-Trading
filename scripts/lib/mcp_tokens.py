"""The single definition of what an `mcp__<Server>__<tool>` token looks like, plus the shared
.claude/settings.json permissions.allow reader both of that token's consumers need.

scripts/check_settings_toolcov.py and scripts/check_connector_tools.py each carried their own
byte-identical `MCP_TOKEN = re.compile(r"mcp__[A-Za-z0-9_]+")`, and check_connector_tools.py's copy
even documented the coupling in a comment ("same shape as check_settings_toolcov.py's MCP_TOKEN,
deliberately not backtick-anchored to match that precedent") without sharing the constant
(quality pass 2026-08-22 -- the same dedup treatment lib/sql_files.py, lib/md_fence.py and
lib/roster_common.py already gave their own cross-checker constants).

WHY IT MATTERS. Both are BLOCKING CI gates and they sit on opposite sides of the same question:
check_settings_toolcov.py decides which `mcp__` references in Claude_Task_Plan.md / ops/triggers.json
MUST appear in .claude/settings.json's allowlist, while check_connector_tools.py decides which
allowlist entries count as covering a declared connector tool. If the token shape ever has to widen
-- a connector server name containing a hyphen is the obvious candidate, which `[A-Za-z0-9_]+`
cannot match today -- fixing only one copy silently desynchronizes the pair: one gate stops
requiring a newly-shaped tool to be allowlisted while the other stops recognizing an
already-allowlisted entry of that shape as coverage. That is precisely the "two sites drift, one
gate goes quietly weaker than intended" failure class these checkers exist to prevent elsewhere.

The same drift class turned up right next to MCP_TOKEN and went unfixed here (cross-cutting#1,
2026-08-31 code-quality pass): check_connector_tools.py's `load_allow_set()` and
check_settings_toolcov.py's `load_allowlist()` both independently did
`open(SETTINGS_JSON, encoding="utf-8")` / `json.load(f)` / `.get("permissions", {}).get("allow", [])`
-- check_connector_tools.py's own comments even named `load_allowlist()` as the function this
logic mirrors, three times, without ever importing it. `load_allow_entries()` below is now the one
place that extraction lives.
"""
import json
import re

# A full mcp__<Server>__<tool> token. Deliberately NOT backtick-anchored: both consumers scan
# running prose as well as JSON/allowlist strings, and a token can legitimately appear bare
# mid-sentence.
MCP_TOKEN = re.compile(r"mcp__[A-Za-z0-9_]+")


def load_allow_entries(settings_path, *, mcp_only=False):
    """Read a settings.json's `permissions.allow` list, filtered to string entries.

    `settings_path` is the CALLER's own SETTINGS_JSON path constant, passed in rather than
    recomputed here -- both check_connector_tools.py and check_settings_toolcov.py already
    define that constant themselves (used for their own missing-file preconditions / messages),
    and their tests monkeypatch it (`monkeypatch.setattr(cct, "SETTINGS_JSON", ...)` /
    `monkeypatch.setattr(stc, "SETTINGS_JSON", ...)`); taking the resolved path as an argument
    keeps that working unchanged instead of requiring this module to know each caller's ROOT.

    Raises OSError / json.JSONDecodeError on a missing or malformed file -- callers decide how to
    report that (check_connector_tools.py catches and fails closed with a message;
    check_settings_toolcov.py lets it propagate, same as before this function existed).

    mcp_only=True additionally filters to entries that are a full mcp__ tool token
    (MCP_TOKEN.fullmatch) -- check_settings_toolcov.py's stricter coverage-set filter, which also
    drops `mcp__Server__*` wildcards, bare `mcp__Server` grants, and non-mcp__ permission strings
    like `Bash(...)`. mcp_only=False (the default) returns every string entry unfiltered, matching
    check_connector_tools.py's load_allow_set(), which does its own MCP_TOKEN.fullmatch filtering
    downstream in CHECK 5 instead of up front here.
    """
    with open(settings_path, encoding="utf-8") as f:
        data = json.load(f)
    allow = data.get("permissions", {}).get("allow", [])
    entries = {a for a in allow if isinstance(a, str)}
    if mcp_only:
        entries = {a for a in entries if MCP_TOKEN.fullmatch(a)}
    return entries
