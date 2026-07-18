#!/usr/bin/env python3
"""Session-config tool coverage single-source (completeness-critic N-1, 2026-07-16).

WHY THIS EXISTS. Routine text (Claude_Task_Plan.md) and the trigger catalog (ops/triggers.json) name
specific MCP tools (mcp__<Server>__<tool>) that an unattended scheduled routine will call mid-run --
e.g. mcp__Interactive_Brokers_IBKR__get_option_data for the D2 options-mark step. If a tool a routine
actually calls is missing from .claude/settings.json's permissions.allow list, an unattended session
hitting that call gets a permission prompt nobody is there to answer -- the step silently stalls with
no dedicated alert class for it (a plain missing-tool-permission hang doesn't look like any of the
existing failure signatures the cadence/freshness dead-man switches watch for).

This script is a ONE-DIRECTION drift guard: every mcp__ token referenced in Claude_Task_Plan.md or
ops/triggers.json must appear in .claude/settings.json's permissions.allow array. (The reverse -- an
allowlisted tool nothing references yet -- is not an error; sessions legitimately provision ahead of
a routine-text change.)

Usage:  python scripts/check_settings_toolcov.py    # exit 0 if covered, 1 + diff if not
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TASK_PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")
TRIGGERS_JSON = os.path.join(ROOT, "ops", "triggers.json")
SETTINGS_JSON = os.path.join(ROOT, ".claude", "settings.json")

MCP_TOKEN = re.compile(r"mcp__[A-Za-z0-9_]+")

# Sources scanned for mcp__ tool references. Add future routine-text-bearing files here.
SOURCES = (TASK_PLAN, TRIGGERS_JSON)


def find_referenced_tools():
    """Return {tool_token: {source_file: set-of-lines-seen}} for every mcp__ reference."""
    refs = {}
    for path in SOURCES:
        if not os.path.exists(path):
            continue
        rel = os.path.relpath(path, ROOT)
        with open(path, encoding="utf-8") as f:
            for lineno, line in enumerate(f, start=1):
                for tok in MCP_TOKEN.findall(line):
                    refs.setdefault(tok, {}).setdefault(rel, []).append(lineno)
    return refs


def load_allowlist():
    """Read .claude/settings.json's permissions.allow — the actual JSON list, not a regex scrape.

    Coverage is deliberately by EXACT tool token: a referenced mcp__Server__tool is covered only by an
    identical allow entry, NOT by a server-level `mcp__Server` grant or a `mcp__Server__*` wildcard.
    That strictness is intentional and must not be relaxed — the harness does not expand such grants
    into per-tool approvals at call time, so honoring them here would pass a tool that would still
    stall an unattended session (a false negative). Every tool a routine calls must be listed explicitly.
    """
    with open(SETTINGS_JSON, encoding="utf-8") as f:
        data = json.load(f)
    allow = data.get("permissions", {}).get("allow", [])
    # Keep only entries that are exact MCP tool tokens. `isinstance(a, str)` guards a malformed
    # non-string entry (e.g. a dict) so this gate reports cleanly instead of crashing with a
    # TypeError; the fullmatch filter drops non-tool permission strings (e.g. Bash(...)) and any
    # server-level / wildcard grant (see the docstring — those are intentionally NOT coverage).
    return {a for a in allow if isinstance(a, str) and MCP_TOKEN.fullmatch(a)}


def main():
    # Fail CLOSED on a missing required source. find_referenced_tools() skips a nonexistent SOURCES
    # file, so without this guard a renamed/moved doc (or a drifted TASK_PLAN/TRIGGERS_JSON constant)
    # would silently shrink the scanned set — with 0 mcp__ refs left, the gate prints OK and exits 0,
    # disarming itself (2026-07-17 audit). Both current sources are committed repo files.
    missing_sources = [os.path.relpath(p, ROOT) for p in SOURCES if not os.path.exists(p)]
    if missing_sources:
        print("SETTINGS TOOL COVERAGE: FAIL\n")
        print(f"Required source file(s) not found: {', '.join(missing_sources)}. This gate cannot "
              f"verify mcp__ tool coverage against a source it can't read — failing closed rather "
              f"than silently passing on an unscanned source (renamed/moved doc, or a drifted path "
              f"constant). Restore the file or update the SOURCES path constant.")
        return 1

    refs = find_referenced_tools()
    allowlist = load_allowlist()

    missing = sorted(tok for tok in refs if tok not in allowlist)

    if missing:
        print("SETTINGS TOOL COVERAGE: FAIL\n")
        print(f"{len(missing)} mcp__ tool(s) referenced in routine text/trigger catalog are NOT in "
              f".claude/settings.json's permissions.allow list. An unattended session calling one of "
              f"these will hit an unanswerable permission prompt and silently stall that step.\n")
        for tok in missing:
            locations = ", ".join(
                f"{src}:{','.join(str(n) for n in lines)}" for src, lines in refs[tok].items()
            )
            print(f" - {tok}  (referenced in {locations})")
        print("\nFix: add the missing token(s) to .claude/settings.json's permissions.allow array.")
        return 1

    print(f"SETTINGS TOOL COVERAGE: OK — {len(refs)} referenced mcp__ tool(s) all present in "
          f".claude/settings.json's permissions.allow list.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
