"""The single definition of what an `mcp__<Server>__<tool>` token looks like.

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
"""
import re

# A full mcp__<Server>__<tool> token. Deliberately NOT backtick-anchored: both consumers scan
# running prose as well as JSON/allowlist strings, and a token can legitimately appear bare
# mid-sentence.
MCP_TOKEN = re.compile(r"mcp__[A-Za-z0-9_]+")
