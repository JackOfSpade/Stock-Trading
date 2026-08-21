#!/usr/bin/env python3
"""Backup/restore for the claude.ai RemoteTrigger routine fleet (ops/routine_backup.json).

WHY THIS EXISTS. On 2026-08-01 thirteen routine triggers were accidentally deleted from the web UI
(claude.ai Code -> Routines) and had to be painstakingly reconstructed from scattered repo prose
(ops/cadence.yaml schedules, ops/triggers.json instructions, Claude_Task_Plan.md headings, memory).
The trigger config itself (schedule + instruction + connectors + model + tools) lives ONLY on the
claude.ai platform -- there is no API key on disk and no CLI, so a plain script can never call
RemoteTrigger directly; only a live Claude session with the tool can read or write it. This module
turns "reconstruct from memory" into "run a mechanical restore" by keeping a versioned snapshot
(ops/routine_backup.json) that a session `ingest`s from real RemoteTrigger list/get responses, and
`restore`s back into ready-to-paste RemoteTrigger create bodies.

WHY PROFILE-BASED, NOT A FLAT 34x DUMP. Every routine's full job_config is ~90% identical to every
other routine sharing its "cohort" (the 32 fleet routines, incl. SL1-SL5, vs the 2 personal,
out-of-repo-scope routines) -- same environment_id, same allowed_tools, same 7 (or 3) MCP connectors,
same model, same autofix_on_pr_create. A flat per-routine dump would be ~200KB of
near-duplicate JSON that no human can meaningfully diff-review. Instead: two small named PROFILES
capture the shared shape once each, and each routine stores only what makes it a routine (trigger_id,
name, cron, enabled, its own instruction text) plus an `overrides` dict for any field that genuinely
differs from its profile (empty/omitted in the overwhelming common case). A `git diff` on this file
after a real config change reads as a real change, not 200KB of connector-block restatement.

PER-TOOL CONNECTOR POLICY (2026-08-08). A live mcp_connections element actually carries SIX keys, not
three: besides connector_uuid/name/url, `permitted_tools` (tool names auto-allowed without an approval
prompt), `tool_policy_overrides` (explicit per-tool policy overrides), and `clear_tool_policy_overrides`
(a live-only "wipe overrides" instruction) are the actual per-tool permission surface. Before this date
normalize_trigger() copied only the first three, so a snapshot could not represent per-tool policy at
all and a restore from it would silently recreate every trigger with that policy absent -- real data
loss. All six are now copied and carried through the restore path. An empty permitted_tools/
tool_policy_overrides means "no override recorded, inherit the claude.ai connector's own default" --
NOT "nothing is permitted"; reading it the second way would be both wrong and dangerous (it would read
as every connector tool suddenly needing manual approval, when nothing has actually been restricted).
A snapshot written before this date simply lacks these three keys on each connection; every reader in
this module defaults their absence to ([], [], False) so the committed ops/routine_backup.json stays
valid without a re-ingest.

Subcommands (see each function's docstring for the exact contract):
  ingest <file_or_dir.json>   merge a RemoteTrigger list/get response into ops/routine_backup.json
  restore [routine_id ...]    print ready-to-use RemoteTrigger create bodies (all routines if none named)
  check                       validate ops/routine_backup.json against ops/cadence.yaml +
                               ops/triggers.json + ops/trigger_ids.json, offline, no network

Usage:
  python scripts/routine_backup.py ingest <file_or_dir.json>
  python scripts/routine_backup.py restore [routine_id ...]
  python scripts/routine_backup.py check
"""
import argparse
import copy
import glob
import json
import os
import re
import sys
import tempfile
import uuid
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.routine_manifest import cadence_routines
from lib.textio import load_yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACKUP_PATH = os.path.join(ROOT, "ops", "routine_backup.json")
TRIGGER_IDS_PATH = os.path.join(ROOT, "ops", "trigger_ids.json")
TRIGGERS_PATH = os.path.join(ROOT, "ops", "triggers.json")
CADENCE_PATH = os.path.join(ROOT, "ops", "cadence.yaml")

# The operator's standing second paragraph, appended verbatim to every live routine trigger's
# instruction EXCEPT OPS2 (documented exception -- OPS2 hosts other routines inline at full fidelity,
# and a blanket "push grunt work to a weaker sub-agent model" instruction is in direct tension with
# that job; see ops/cadence.yaml's OPS1/OPS2 block and bigquery/15_routine_catalog.sql's header for
# the full rationale). check()'s check (2) enforces this exception explicitly.
ADDENDUM = ("\n\nSpawn Sonnet 5 model sub-agents to do the grunt work. Save your processing "
            "(Opus 5) for design/analysis/orchestration work only.")
OPS2_NO_ADDENDUM_ID = "OPS2"

# The operator's standing scope-completion directive, appended verbatim to EVERY live routine
# trigger's instruction -- INCLUDING OPS2. Unlike ADDENDUM above, this carries no OPS2 exception: it
# governs when a routine may stop and give its final response, not which model does the grunt work,
# so OPS2's inline-hosting job is not in tension with it. check()'s check (2) appends this after
# ADDENDUM (or directly after the core instruction for OPS2) when computing the expected instruction
# text.
# NARROWED (owner directive 2026-08-21, superseding the 2026-08-17 form): the original wording also
# ordered out-of-scope issues fixed on best judgment in-session, and measurably turned no-op runs into
# spec-hardening sessions (routine-prefixed commits ~2.6/day -> ~9.2/day across the 2026-08-17
# boundary; SL5 median session 2.6 min -> 16-24 min). The current form keeps the in-scope completion
# bar and routes out-of-scope findings to a recorded handoff (queue/alert row) instead of an inline
# fix. The 2 personal_* triggers still carry the 2026-08-17 wording by design -- they are outside the
# fleet's cost/scope discipline and check (2) does not compute expected text for them.
SCOPE_ADDENDUM = ("\n\nDo not give final response until you have resolved every issue within this "
                   "run's own scope. Do NOT fix issues outside this run's scope: record each one "
                   "instead — an events.queue_events row or an ops.alerts info row naming the owning "
                   "routine or surface — and move on.")

# Sentinel stored as cron_expression when no trustworthy source could confirm it (an empty/missing
# cron_expression on ingest, or a bootstrap entry seeded without one). ingest() always reports every
# routine currently carrying this value so it is never silently mistaken for a real schedule.
CRON_UNCONFIRMED = "TO_POPULATE"

# Volatile RemoteTrigger response fields that create pure diff noise (server-timestamped or
# server-assigned, never something a human edits) -- normalize_trigger() strips these BY CONSTRUCTION:
# it only ever copies the named fields below into the canonical shape, so an ingest can never leak
# next_run_at / last_fired_at / updated_at / created_at / ended_reason / suspension_reason /
# api_token_hint / creator, or job_config.ccr.session_context.outcomes (the auto-assigned
# `claude/<random>` working branch a run happens to land on).
FLEET_REPO_URL = "https://github.com/JackOfSpade/Stock-Trading"

# ---- the 7 MCP connectors (owner-supplied 2026-08-01) ----------------------------------------------
CONNECTORS = [
    {"connector_uuid": "f4bd1992-c70e-4b23-b617-271b19976e92", "name": "FMP",
     "url": "https://financialmodelingprep.com/mcp"},
    {"connector_uuid": "8118e26a-1613-4cf8-b1cd-9a794b8d357b", "name": "Gmail",
     "url": "https://gmailmcp.googleapis.com/mcp/v1"},
    {"connector_uuid": "c91ddbb2-ced9-4011-9838-15e5239e83e9", "name": "Google-Calendar",
     "url": "https://calendarmcp.googleapis.com/mcp/v1"},
    {"connector_uuid": "64f9594a-0ed8-4081-883c-df850f1c8fcd", "name": "Google-Cloud-BigQuery",
     "url": "https://bigquery.googleapis.com/mcp"},
    {"connector_uuid": "fff8d981-37df-4721-97af-9e0fdf5238e7", "name": "Hugging-Face",
     "url": "https://huggingface.co/mcp?login&gradio=none"},
    {"connector_uuid": "d9d4ad11-d734-4c05-8302-9fd84698ef46", "name": "Interactive-Brokers--IBKR-",
     "url": "https://api.ibkr.com/v1/api/mcp"},
    {"connector_uuid": "715856f0-b776-4037-b2a3-a0c9531d965f", "name": "Tavily",
     "url": "https://mcp.tavily.com/mcp"},
]
CONNECTORS_BY_NAME = {c["name"]: c for c in CONNECTORS}


def _conns(*names):
    """A profile's mcp_connections block: the named connectors, sorted by name (deterministic;
    connector ORDER varies harmlessly between live routines, so profiles/entries always store them
    sorted rather than in whatever order a given `list`/`get` happened to return)."""
    return sorted((CONNECTORS_BY_NAME[n] for n in names), key=lambda c: c["name"])


# ---- the 2 base profiles --------------------------------------------------------------------------
_FLEET_TOOLS = ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "WebFetch", "WebSearch", "RemoteTrigger"]
_PERSONAL_TOOLS = ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "WebFetch", "WebSearch"]

# Per-routine claude.ai push/email/slack notification toggles. The entire fleet (incl. SL1-SL5) runs
# silent -- ops.alerts -> alert_emailer.gs is the real alerting path. No routine has used push
# notifications since the 2026-08-01 fleet-wide normalisation (see ops/routine_backup.json _meta).
NOTIFY_SILENT = {"channel": {"email": False, "push": False, "slack": False}}

DEFAULT_PROFILES = {
    "fleet": {
        "environment_id": "env_01DXtTeywLPpNoXku8rGNEie",
        "autofix_on_pr_create": True,
        "notifications": copy.deepcopy(NOTIFY_SILENT),
        "model": "claude-opus-5",
        "allowed_tools": list(_FLEET_TOOLS),
        "sources": [{"git_repository": {"url": FLEET_REPO_URL}}],
        "mcp_connections": _conns(*CONNECTORS_BY_NAME),
    },
    "personal": {
        "environment_id": "env_01DXtTeywLPpNoXku8rGNEie",
        "autofix_on_pr_create": True,
        "model": "claude-opus-5",
        "notifications": copy.deepcopy(NOTIFY_SILENT),
        "allowed_tools": list(_PERSONAL_TOOLS),
        "sources": [{"git_repository": {
            "url": "https://github.com/JackOfSpade/Image-and-Video-Generation-Pipeline"}}],
        "mcp_connections": _conns("Google-Calendar", "Hugging-Face", "Tavily"),
    },
}


def _empty_backup_doc():
    return {
        "_meta": {
            "purpose": (
                "Versioned snapshot of every claude.ai RemoteTrigger routine (schedule + instruction "
                "+ connectors), profile-based so a diff shows real config changes instead of restating "
                "shared boilerplate. Exists so a future accidental trigger deletion (2026-08-01 "
                "incident: 13 routines deleted from the web UI, hand-reconstructed from scattered repo "
                "prose) is a mechanical `restore`, not a research project."
            ),
            "how_to_refresh": (
                "In a session with the RemoteTrigger tool: call `list` (paginated, ~20 at a time -- "
                "see ops/trigger_ids.json _meta) and/or `get` on specific trigger ids, save the "
                "response body as JSON, then run `python scripts/routine_backup.py ingest <file>`. "
                "Re-running ingest on the same or overlapping data is safe and idempotent -- it "
                "cleanly overwrites each routine's stored fields (including cron_expression) with "
                "the freshly ingested values."
            ),
            "how_to_restore": (
                "`python scripts/routine_backup.py restore <routine_id ...>` (or no args for every "
                "routine) prints a ready-to-use RemoteTrigger create body per routine, each with a "
                "freshly generated uuid. Call RemoteTrigger create with that body, then record the "
                "returned trig_... id in ops/trigger_ids.json for that routine id (this script cannot "
                "call RemoteTrigger itself and never invents live API data)."
            ),
            "caveats": (
                "cron_expression may read 'TO_POPULATE' for a routine whose live cron could not yet "
                "be confirmed from a trustworthy source (see the initial-bootstrap commit message / "
                "session report) -- ingest against a real `list`/`get` response overwrites it. "
                "OPS2's instruction deliberately omits ONLY the Sonnet-delegation ADDENDUM every other "
                "routine carries (see ADDENDUM / OPS2_NO_ADDENDUM_ID in this module and ops/cadence.yaml's "
                "OPS1/OPS2 block) -- this is a documented exception, not drift. OPS2 DOES carry "
                "SCOPE_ADDENDUM (2026-08-17), which has no OPS2 exception. The 2 'personal' "
                "profile routines target a different repo (JackOfSpade/Image-and-Video-Generation-"
                "Pipeline) and are out of the trading fleet's scope -- kept here only because they "
                "live on the same claude.ai account and are equally vulnerable to an accidental "
                "deletion."
            ),
            "last_ingested": None,
        },
        "profiles": copy.deepcopy(DEFAULT_PROFILES),
        "routines": {},
        "_unmatched": {},
    }


def _load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_backup():
    """The current ops/routine_backup.json doc, or a fresh skeleton (seeded with DEFAULT_PROFILES) if
    it does not exist yet. Reads BACKUP_PATH as a bare global (not a default parameter) so
    monkeypatch.setattr(module, "BACKUP_PATH", ...) is honored -- a default arg would bind the
    pre-patch value at import time and never see a test's patched path (see
    scripts/check_cadence_consistency.py's model_mirror_files() for the same convention/rationale)."""
    if not os.path.exists(BACKUP_PATH):
        return _empty_backup_doc()
    doc = _load_json(BACKUP_PATH)
    doc.setdefault("_meta", {})
    doc.setdefault("profiles", copy.deepcopy(DEFAULT_PROFILES))
    doc.setdefault("routines", {})
    doc.setdefault("_unmatched", {})
    return doc


def write_backup(doc):
    """Atomically replace the backup with a human-diffable JSON document.

    The backup is itself the recovery path, so never truncate it in place: write and fsync a temporary
    file in its directory, then replace the old path atomically. A failed ingest therefore leaves the
    prior known-good snapshot intact.
    """
    parent = os.path.dirname(os.path.abspath(BACKUP_PATH))
    prefix = f".{os.path.basename(BACKUP_PATH)}."
    fd, tmp_path = tempfile.mkstemp(prefix=prefix, suffix=".tmp", dir=parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(doc, f, indent=2, sort_keys=True, ensure_ascii=False)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp_path, BACKUP_PATH)
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


def _today():
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


# ---- normalization ----------------------------------------------------------------------------------
def _strip_cron(raw_cron):
    cron = (raw_cron or "").strip()
    return cron or CRON_UNCONFIRMED


def _normalize_notifications(raw_notifications):
    """Filter to EXACTLY {"channel": {"email": bool, "push": bool, "slack": bool}} (B6, 2026-08-01
    audit). This is the one field normalize_trigger() used to copy whole-cloth (`raw.get(...) or
    default`), contradicting the function's own docstring guarantee that only named fields are copied
    -- any extra/volatile sub-key a real API response happened to include would leak straight into
    ops/routine_backup.json and into every restore body. Missing/non-bool channel values default to
    False rather than raising, matching normalize_trigger's overall "always produce a well-shaped
    result" style."""
    ch = (raw_notifications or {}).get("channel") or {}
    return {"channel": {
        "email": bool(ch.get("email", False)),
        "push": bool(ch.get("push", False)),
        "slack": bool(ch.get("slack", False)),
    }}


def normalize_trigger(raw):
    """One RemoteTrigger list/get response element -> the canonical, volatile-stripped shape used
    throughout this module. Only ever COPIES the named fields below out of `raw` -- next_run_at,
    last_fired_at, updated_at, created_at, ended_reason, suspension_reason, api_token_hint, creator,
    and session_context.outcomes are never read, so they can never leak into ops/routine_backup.json
    regardless of what a real API response happens to include.

    PER-CONNECTION POLICY FIELDS (2026-08-08): each mcp_connections element also copies
    permitted_tools, tool_policy_overrides, and clear_tool_policy_overrides -- see the module
    docstring's 2026-08-08 note for why these three matter (they are the per-tool permission surface;
    dropping them meant a snapshot could not represent per-tool policy at all, and a restore from it
    would silently recreate the trigger with that policy absent). Missing/falsy input defaults to
    `[]` / `[]` / `False` respectively, so a raw payload that predates these fields (or a hand-authored
    'profiles' connector) still normalizes cleanly.

    SCHEDULE (B1, 2026-08-01 audit): a live trigger carries EXACTLY ONE of `cron_expression`
    (recurring) or `run_once_at` (RFC3339 UTC one-shot) -- the two 'personal_*' routines in this
    account are one-shots (empty cron_expression + a real run_once_at). The returned dict always has
    BOTH keys; exactly one is truthy. `cron_expression` is only ever sentinel'd to CRON_UNCONFIRMED
    when `run_once_at` is ALSO absent -- a one-shot trigger's empty cron_expression is normal, not an
    unconfirmed schedule, and must never be sentinel'd (that would silently degrade/lose the one-shot
    schedule on ingest -- see check()'s schedule-rule validation for the corresponding guard)."""
    ccr = (raw.get("job_config") or {}).get("ccr") or {}
    sc = ccr.get("session_context") or {}
    events = ccr.get("events") or []
    content = ""
    if events:
        content = ((events[0].get("data") or {}).get("message") or {}).get("content", "")
    conns = sorted(
        ({"connector_uuid": c.get("connector_uuid"), "name": c.get("name"), "url": c.get("url"),
          # Per-tool policy surface (2026-08-08, see module + function docstrings). permitted_tools is
          # sorted at storage time -- same determinism convention as allowed_tools/mcp_connections
          # order below (a plain list of tool names, harmless to reorder). tool_policy_overrides'
          # element shape is NOT documented/guaranteed to be sortable (may be a list of override
          # objects), so it is preserved in API-return order rather than risk a TypeError or silently
          # reordering something that could be order-significant.
          "permitted_tools": sorted(c.get("permitted_tools") or []),
          "tool_policy_overrides": list(c.get("tool_policy_overrides") or []),
          "clear_tool_policy_overrides": bool(c.get("clear_tool_policy_overrides"))}
         for c in (raw.get("mcp_connections") or [])),
        key=lambda c: c["name"] or "")
    run_once_at = ((raw.get("run_once_at") or "").strip()) or None
    cron_expression = None if run_once_at else _strip_cron(raw.get("cron_expression"))
    return {
        "trigger_id": raw.get("id") or raw.get("trigger_id"),
        "name": raw.get("name"),
        "cron_expression": cron_expression,
        "run_once_at": run_once_at,
        "enabled": raw.get("enabled"),
        "instruction": content,
        "environment_id": ccr.get("environment_id"),
        "model": sc.get("model"),
        # Sorted, matching the mcp_connections precedent two lines below (`conns = sorted(...)`):
        # canonicalise AT STORAGE TIME so the value written into ops/routine_backup.json is
        # deterministic w.r.t. whatever order a live `list`/`get` response happens to serialize
        # session_context in. Before this fix only the COMPARISON in derive_profile() (_tools_eq,
        # below) was made order-insensitive -- the stored value itself was still `list(...)`
        # verbatim, so an `overrides["allowed_tools"]` (once one exists) could flip byte-for-byte
        # between two ingests of the identical live routine, pure diff noise the mcp_connections
        # precedent was specifically introduced to avoid (2026-08-08).
        "allowed_tools": sorted(sc.get("allowed_tools") or []),
        "autofix_on_pr_create": sc.get("autofix_on_pr_create"),
        "notifications": _normalize_notifications(raw.get("notifications")),
        "sources": sc.get("sources") or [],
        "mcp_connections": conns,
    }


def _iter_raw_triggers(payload):
    """A RemoteTrigger `list` response ({"data":[...]}), a `get` response ({"trigger":{...}}), or a
    bare JSON array of trigger objects -> the list of raw trigger dicts."""
    if isinstance(payload, list):
        return payload
    if isinstance(payload, dict):
        if isinstance(payload.get("data"), list):
            return payload["data"]
        if isinstance(payload.get("trigger"), dict):
            return [payload["trigger"]]
    raise ValueError(
        "unrecognized ingest payload shape -- expected {'data': [...]} (list response), "
        "{'trigger': {...}} (get response), or a bare JSON array of trigger objects")


def _load_raw_triggers(path):
    """`path` may be a single JSON file, or a directory of JSON files (each individually one of the
    three shapes _iter_raw_triggers accepts) -- all are merged into one flat list of raw triggers."""
    files = [path]
    if os.path.isdir(path):
        files = sorted(glob.glob(os.path.join(path, "*.json")))
    out = []
    for fp in files:
        out.extend(_iter_raw_triggers(_load_json(fp)))
    return out


# ---- matching a normalized trigger back to a routine id ---------------------------------------------
def _core_instruction(instruction):
    """The instruction with the standing addendum (or any second paragraph) stripped -- everything up
    to the first blank line. Matching on the core avoids false negatives from the addendum's presence/
    absence (OPS2) or future wording changes to it."""
    return (instruction or "").split("\n\n", 1)[0]


def _trigger_id_match(tid, trigger_ids_doc):
    """rid whose ops/trigger_ids.json entry carries this trigger_id, or None."""
    for rid, entry in trigger_ids_doc.items():
        if rid == "_meta":
            continue
        if (entry or {}).get("trigger_id") == tid:
            return rid
    return None


def _instruction_match(instruction, triggers_doc):
    """rid whose ops/triggers.json core instruction equals this trigger's core instruction, or None.

    BOTH sides are core-stripped: ops/triggers.json's own text also carries the addendum for any
    routine with a cadence.yaml `instruction_note` (OPS2 today), so comparing the live core against
    the FULL stored text could never match those routines at all."""
    core = _core_instruction(instruction)
    for rid, entry in triggers_doc.items():
        if _core_instruction(entry.get("instruction")) == core:
            return rid
    return None


def match_routine_id(normalized, trigger_ids_doc, triggers_doc):
    """trigger_id lookup first (ops/trigger_ids.json, ground truth once recorded), else a core-
    instruction match against ops/triggers.json (covers a routine whose trigger was just recreated and
    has no trigger_ids.json entry yet). None if neither resolves -- the caller decides between the
    'personal' out-of-scope case and the genuine `_unmatched` catch-all.

    Priority is deliberate and must never flip (B5, 2026-08-01 audit): trigger_id is the ground truth
    once recorded. See match_conflict() for the case where BOTH sources resolve and DISAGREE -- that
    is a caller-level concern (ingest() must not silently corrupt either routine's entry), not
    something this function's return value alone can carry."""
    tid_rid = _trigger_id_match(normalized["trigger_id"], trigger_ids_doc)
    if tid_rid is not None:
        return tid_rid
    return _instruction_match(normalized["instruction"], triggers_doc)


def match_conflict(normalized, trigger_ids_doc, triggers_doc):
    """(trigger_id_rid, instruction_rid) when BOTH ops/trigger_ids.json (by trigger_id) AND
    ops/triggers.json (by core instruction) resolve `normalized` to a routine id AND those ids
    DISAGREE. None when they agree, or when either source fails to resolve at all.

    WHY THIS MATTERS (B5, 2026-08-01 audit): match_routine_id() resolves by trigger_id first and
    returns unconditionally -- with a stale or duplicated ops/trigger_ids.json (13 ids were replaced
    2026-08-01, so this is live risk) a trigger can be filed under the WRONG routine, silently
    overwriting that routine's stored config while the correct routine's entry never gets refreshed.
    ingest() calls this BEFORE match_routine_id() and, on a conflict, records it and leaves BOTH
    routines' stored entries untouched rather than picking a side."""
    tid_rid = _trigger_id_match(normalized["trigger_id"], trigger_ids_doc)
    instr_rid = _instruction_match(normalized["instruction"], triggers_doc)
    if tid_rid is not None and instr_rid is not None and tid_rid != instr_rid:
        return tid_rid, instr_rid
    return None


def is_personal(normalized):
    """True if this trigger's git source is NOT the trading-fleet repo -- the 2 known 'personal'
    routines (video/image pipeline research) live on the same claude.ai account but target
    JackOfSpade/Image-and-Video-Generation-Pipeline, not this repo, so they can never match by
    trigger_id or instruction yet are legitimately identifiable (not a genuine unknown)."""
    urls = {(s.get("git_repository") or {}).get("url") for s in (normalized.get("sources") or [])}
    return bool(urls) and FLEET_REPO_URL not in urls


def _personal_id(name):
    """A stable, readable routine-backup key for a personal (out-of-fleet-scope) trigger, derived from
    its live `name` -- e.g. "Research Leading Omnireference Video Platforms" ->
    "personal_research_leading_omnireference_video_platforms". Never collides with a cadence.yaml id
    (those are short alnum codes with no 'personal_' prefix). NOTE: keyed on name, so a renamed
    personal trigger re-ingests as a NEW key rather than updating the old one -- acceptable for a
    small, rarely-renamed set; not a concern for the fleet's own routines, which always match by the
    stable trigger_id first."""
    slug = re.sub(r"[^a-z0-9]+", "_", (name or "").lower()).strip("_")
    return f"personal_{slug or 'unnamed'}"


# ---- profile derivation -------------------------------------------------------------------------------
def _tools_set(tools):
    return set(tools or [])


def _tools_eq(a, b):
    """Order-INSENSITIVE, matching the mcp_connections precedent (_conn_key_set below / _conns'
    docstring): allowed_tools comes back from a live `list`/`get` response in whatever order the API
    happens to serialize session_context in, same as mcp_connections' connector order varies harmlessly
    between routines. Comparing as a list (the old `list(a) == list(b)`) treated that harmless order
    difference as a real config change -- a live routine whose allowed_tools order merely differed from
    its profile read as drift and picked up a spurious `overrides["allowed_tools"]` on every ingest
    (2026-08-08).

    STILL NEEDED after normalize_trigger() started sorting allowed_tools at storage time (2026-08-08,
    same audit): sorting only canonicalises the INGESTED side (`normalized["allowed_tools"]`). The `b`
    side here is a PROFILE's allowed_tools (DEFAULT_PROFILES' `_FLEET_TOOLS`/`_PERSONAL_TOOLS`, or
    whatever ops/routine_backup.json's 'profiles' hand-authors) -- those are config, never run through
    normalize_trigger(), and are deliberately left in their hand-written (non-alphabetical) order,
    confirmed live in ops/routine_backup.json's 'profiles' -- so a plain list compare between a sorted
    normalized value and an unsorted profile value would still misfire on every ingest. This is the
    literal 'path that bypasses normalize_trigger': the profile side of every derive_profile()
    comparison."""
    return _tools_set(a) == _tools_set(b)


def _sources_eq(a, b):
    return (a or []) == (b or [])


def _hashable_json_list(items):
    """`items` (a list of JSON-serializable values whose element shape isn't guaranteed, e.g. a
    connection's tool_policy_overrides) as a hashable tuple usable inside a set -- each element is
    json.dumps'd with sort_keys=True so two structurally-identical dicts always dump identically
    regardless of their own key order, and list ORDER is preserved (not sorted): unlike allowed_tools/
    permitted_tools (flat lists of names, harmless to reorder -- see _tools_eq's docstring), an
    overrides list's shape isn't documented anywhere this module can check, so it is treated as
    potentially order-significant rather than assumed to be a set."""
    return tuple(json.dumps(x, sort_keys=True, default=str) for x in (items or []))


def _conn_key(c):
    """The full comparable identity of one mcp_connection dict (2026-08-08): connector_uuid PLUS the
    per-tool policy fields (permitted_tools, tool_policy_overrides, clear_tool_policy_overrides) -- see
    the module docstring's 2026-08-08 note. Two connections with the SAME connector_uuid but DIFFERENT
    per-tool policy are NOT the same effective config and must not collapse together when
    derive_profile() decides whether a routine matches a profile's mcp_connections. permitted_tools is
    compared order-insensitively (a flat list of tool names, same as allowed_tools); every field
    defaults the same way normalize_trigger() defaults an ingested connection ([] / [] / False), so a
    profile connector dict written before this field existed (only 3 keys) still compares equal to a
    live connection whose policy is genuinely empty -- the common case for every routine today."""
    return (
        c.get("connector_uuid"),
        tuple(sorted(c.get("permitted_tools") or [])),
        _hashable_json_list(c.get("tool_policy_overrides")),
        bool(c.get("clear_tool_policy_overrides")),
    )


def _conn_key_set(conns):
    return {_conn_key(c) for c in (conns or [])}


def derive_profile(normalized, profiles):
    """(profile_name, overrides) for `normalized` against the candidate `profiles` dict -- the
    best-scoring profile (most matching fields) wins, and every field that still differs from THAT
    profile is recorded in `overrides`. mcp_connections is compared as an UNORDERED set of each
    connection's full identity -- connector_uuid AND its per-tool policy fields (_conn_key, 2026-08-08;
    connector ORDER varies harmlessly between live routines -- see _conns' docstring, but the per-tool
    POLICY of a given connector is real config, not noise), every other field is compared as-is.

    TIE-BREAK (B7, 2026-08-01 audit): on an EQUAL score between two or more profiles, the
    lexicographically LOWEST profile name wins, deterministically, regardless of dict iteration
    order. Effective restored config is identical either way (every differing field still lands in
    `overrides`), but a plain `score > best_score` comparison is dict-order dependent -- and profile
    order differs between a first-ever ingest (source order) and every later load (write_backup's
    sort_keys=True) -- which was previously pure diff-noise on re-ingest."""
    if not profiles:
        raise ValueError("no profiles to derive against -- ops/routine_backup.json 'profiles' is empty")
    best_name, best_score = None, -1
    for pname, p in profiles.items():
        score = (
            (normalized["environment_id"] == p.get("environment_id"))
            + (normalized["model"] == p.get("model"))
            + (normalized["autofix_on_pr_create"] == p.get("autofix_on_pr_create"))
            + (normalized.get("notifications") == p.get("notifications"))
            + _tools_eq(normalized["allowed_tools"], p.get("allowed_tools"))
            + _sources_eq(normalized["sources"], p.get("sources"))
            + (_conn_key_set(normalized["mcp_connections"]) == _conn_key_set(p.get("mcp_connections")))
        )
        if score > best_score or (score == best_score and pname < best_name):
            best_name, best_score = pname, score
    p = profiles[best_name]
    overrides = {}
    if normalized["environment_id"] != p.get("environment_id"):
        overrides["environment_id"] = normalized["environment_id"]
    if normalized["model"] != p.get("model"):
        overrides["model"] = normalized["model"]
    if normalized["autofix_on_pr_create"] != p.get("autofix_on_pr_create"):
        overrides["autofix_on_pr_create"] = normalized["autofix_on_pr_create"]
    if normalized.get("notifications") != p.get("notifications"):
        overrides["notifications"] = normalized.get("notifications")
    if not _tools_eq(normalized["allowed_tools"], p.get("allowed_tools")):
        overrides["allowed_tools"] = normalized["allowed_tools"]
    if not _sources_eq(normalized["sources"], p.get("sources")):
        overrides["sources"] = normalized["sources"]
    if _conn_key_set(normalized["mcp_connections"]) != _conn_key_set(p.get("mcp_connections")):
        overrides["mcp_connections"] = normalized["mcp_connections"]
    return best_name, overrides


def _dedup_raw_triggers(raws):
    """Collapse `raws` to one entry per trigger id, keeping the LAST occurrence -- a directory ingest
    (_load_raw_triggers) flattens every file's triggers into one list, and the SAME trigger id can
    legitimately appear in more than one file (e.g. two overlapping RemoteTrigger `list` pages saved
    separately). Without this, ingest()'s loop below classified each occurrence separately and
    double-counted the routine across added/updated/unchanged, even though doc["routines"][rid] already
    ended up holding only the LAST occurrence's data -- plain dict assignment inside that loop is
    itself last-one-wins (2026-08-08). Keeping the last occurrence here just makes the classification
    match what the stored data already did. A raw with no id/trigger_id at all (should not happen for a
    real RemoteTrigger response) has no stable identity to dedup on, so each is kept as its own entry
    rather than collapsed with unrelated id-less raws."""
    keyed = {}
    for i, raw in enumerate(raws):
        tid = raw.get("id") or raw.get("trigger_id")
        keyed[tid if tid else ("__no_id__", i)] = raw
    return list(keyed.values())


# ---- ingest -----------------------------------------------------------------------------------------
def ingest(path):
    """Merge every trigger found at `path` (file or directory; see _iter_raw_triggers/_load_raw_triggers
    for accepted shapes) into ops/routine_backup.json. Returns a summary dict (added/updated/unchanged
    routine ids, unmatched trigger ids, conflicts, and routines whose stored cron is still
    CRON_UNCONFIRMED) -- the caller (cmd_ingest) prints it; ingest() itself does not print, so tests
    can call it directly."""
    doc = load_backup()
    trigger_ids_doc = _load_json(TRIGGER_IDS_PATH) if os.path.exists(TRIGGER_IDS_PATH) else {}
    triggers_doc = _load_json(TRIGGERS_PATH) if os.path.exists(TRIGGERS_PATH) else {}

    added, updated, unchanged, unmatched, conflicts = [], [], [], [], []

    for raw in _dedup_raw_triggers(_load_raw_triggers(path)):
        normalized = normalize_trigger(raw)

        # B5 (2026-08-01 audit): trigger_id and instruction disagreeing on the routine id is NOT safe
        # to silently resolve by priority -- with a stale/duplicated ops/trigger_ids.json that would
        # overwrite the WRONG routine's stored config. Record it loudly and leave every existing entry
        # untouched rather than guess.
        conflict = match_conflict(normalized, trigger_ids_doc, triggers_doc)
        if conflict is not None:
            tid_rid, instr_rid = conflict
            conflicts.append({
                "trigger_id": normalized["trigger_id"],
                "trigger_id_routine": tid_rid,
                "instruction_routine": instr_rid,
            })
            continue

        rid = match_routine_id(normalized, trigger_ids_doc, triggers_doc)
        if rid is None and is_personal(normalized):
            rid = _personal_id(normalized["name"])
        if rid is None:
            # Genuinely unidentifiable (same repo as the fleet, but no trigger_id or instruction match)
            # -- record it rather than dropping it silently, per the ingest contract.
            # An id-less raw (which _dedup_raw_triggers deliberately preserves) would otherwise be
            # stored under a None key, and write_backup's json.dump(sort_keys=True) then raises a
            # TypeError comparing None to the other str keys, losing the whole ingest. The synthetic
            # key mirrors _dedup_raw_triggers' own "__no_id__" convention and is readable in restore()'s
            # operator-facing messages, which echo _unmatched keys verbatim as the id to type.
            key = (normalized["trigger_id"]
                   or f"__no_id__:{_core_instruction(normalized['instruction'])[:60]}")
            doc["_unmatched"][key] = normalized
            unmatched.append(key)
            continue

        # B4 (2026-08-01 audit): this trigger_id is now matchable, so any stale `_unmatched` copy of it
        # (from an earlier ingest, before e.g. ops/trigger_ids.json was fixed) must not linger --
        # otherwise a `restore` with no args would rebuild it as a DUPLICATE live trigger alongside the
        # now-correctly-filed routine entry below.
        doc["_unmatched"].pop(normalized["trigger_id"], None)

        profile_name, overrides = derive_profile(normalized, doc["profiles"])
        entry = {
            "trigger_id": normalized["trigger_id"],
            "name": normalized["name"],
            "enabled": normalized["enabled"],
            "profile": profile_name,
            "instruction": normalized["instruction"],
        }
        # B1 (2026-08-01 audit): store whichever of the two schedule fields is actually populated --
        # never sentinel an empty cron_expression when run_once_at is present (that would silently
        # degrade a one-shot trigger's real schedule into a bogus "unconfirmed cron").
        if normalized.get("run_once_at"):
            entry["run_once_at"] = normalized["run_once_at"]
        else:
            entry["cron_expression"] = normalized["cron_expression"]
        prior = doc["routines"].get(rid)
        if overrides:
            entry["overrides"] = overrides

        doc["routines"][rid] = entry
        if prior is None:
            added.append(rid)
        elif prior != entry:
            updated.append(rid)
        else:
            unchanged.append(rid)

    doc["_meta"]["last_ingested"] = _today()
    write_backup(doc)

    unconfirmed_cron = sorted(
        rid for rid, e in doc["routines"].items() if e.get("cron_expression") == CRON_UNCONFIRMED)
    return {
        "added": sorted(added),
        "updated": sorted(updated),
        "unchanged": sorted(unchanged),
        "unmatched": sorted(unmatched),
        "conflicts": conflicts,
        "unconfirmed_cron": unconfirmed_cron,
    }


# ---- restore ----------------------------------------------------------------------------------------
def _fresh_uuid():
    return str(uuid.uuid4()).lower()


def _restore_conn(c):
    """One `mcp_connections` element as it goes into a RemoteTrigger create body (2026-08-08) --
    connector_uuid/name/url plus the per-tool policy fields, each explicitly defaulted rather than
    left absent, so a restore never depends on the live API guessing a missing key's meaning.

    SAFETY-CRITICAL: `clear_tool_policy_overrides` must ONLY ever be exactly the value that was backed
    up for this connection -- sending `true` on a restore would WIPE the live per-tool policy for that
    connector. When nothing was ever recorded (e.g. `c` came from a hand-authored 'profiles' connector
    written before this field existed), it defaults to False, NEVER True -- a restore must never clear
    policy it has no record of. Do not change this default without re-reading that sentence."""
    return {
        "connector_uuid": c.get("connector_uuid"),
        "name": c.get("name"),
        "url": c.get("url"),
        "permitted_tools": list(c.get("permitted_tools") or []),
        "tool_policy_overrides": list(c.get("tool_policy_overrides") or []),
        "clear_tool_policy_overrides": bool(c.get("clear_tool_policy_overrides")),
    }


def _assemble_create_body(*, name, cron_expression=None, run_once_at=None, enabled, instruction,
                           environment_id, model, allowed_tools, autofix_on_pr_create, sources,
                           mcp_connections, notifications=None):
    """B1 (2026-08-01 audit): a RemoteTrigger create body carries EXACTLY ONE of `cron_expression`
    (recurring) or `run_once_at` (RFC3339 UTC one-shot) -- never both, never neither. Raises ValueError
    rather than silently emitting an invalid/ambiguous body; callers (build_create_body,
    build_unmatched_create_body) pass through whichever ONE of the two their source data has.

    Each mcp_connections element is passed through _restore_conn() (2026-08-08) so the per-tool policy
    fields are always present and explicitly defaulted in the emitted body -- see _restore_conn's
    docstring for the clear_tool_policy_overrides safety rule."""
    if bool(cron_expression) == bool(run_once_at):
        raise ValueError(
            "exactly one of cron_expression/run_once_at is required for a RemoteTrigger create body "
            f"(got cron_expression={cron_expression!r}, run_once_at={run_once_at!r})")
    body = {
        "name": name,
        "enabled": enabled,
        "job_config": {
            "ccr": {
                "environment_id": environment_id,
                "session_context": {
                    "model": model,
                    "allowed_tools": allowed_tools,
                    "autofix_on_pr_create": autofix_on_pr_create,
                    "sources": sources,
                },
                "events": [
                    {"data": {
                        "uuid": _fresh_uuid(),
                        "session_id": "",
                        "type": "user",
                        "parent_tool_use_id": None,
                        "message": {"content": instruction, "role": "user"},
                    }},
                ],
            },
        },
        "mcp_connections": [_restore_conn(c) for c in (mcp_connections or [])],
        "notifications": notifications if notifications is not None else copy.deepcopy(NOTIFY_SILENT),
    }
    if cron_expression:
        body["cron_expression"] = cron_expression
    else:
        body["run_once_at"] = run_once_at
    return body


def _resolve_fields(entry, profiles):
    """profile + overrides -> the effective session_context/mcp_connections fields for one
    ops/routine_backup.json routine entry.

    All seven fields go through p.get(...) -- six of them used to hard-index (p["sources"] etc.),
    only `notifications` used .get(). A snapshot profile missing one of the six (hand-edited or a
    corrupted ingest) raised an uncaught KeyError here and crashed check()/restore() before
    _resolved_fields_errors() ever got a chance to report it as the "missing/empty" finding it already
    knows how to describe (2026-08-08). .get() everywhere makes a missing field resolve to None like
    notifications always did, so the crash becomes a clean, reportable validation failure instead.

    `mcp_connections` resolves to whichever whole list of connection dicts wins (override or profile)
    -- each dict's per-tool policy fields (permitted_tools/tool_policy_overrides/
    clear_tool_policy_overrides) ride along unchanged; _assemble_create_body()'s _restore_conn() step
    is what defaults any missing ones before they reach a live create body."""
    p = profiles[entry["profile"]]
    ov = entry.get("overrides") or {}
    return {
        "environment_id": ov.get("environment_id", p.get("environment_id")),
        "model": ov.get("model", p.get("model")),
        "allowed_tools": ov.get("allowed_tools", p.get("allowed_tools")),
        "autofix_on_pr_create": ov.get("autofix_on_pr_create", p.get("autofix_on_pr_create")),
        "notifications": ov.get("notifications", p.get("notifications")),
        "sources": ov.get("sources", p.get("sources")),
        "mcp_connections": ov.get("mcp_connections", p.get("mcp_connections")),
    }


def build_create_body(entry, profiles):
    """A ready-to-use RemoteTrigger create body for one profile-based ops/routine_backup.json
    `routines` entry, with a FRESH lowercase uuid4 for events[0].data.uuid. `entry` carries exactly
    one of cron_expression/run_once_at (see ingest()'s B1 handling); whichever is absent is simply not
    a key on `entry`, so `.get()` naturally passes only the present one through to
    _assemble_create_body."""
    fields = _resolve_fields(entry, profiles)
    return _assemble_create_body(
        name=entry["name"], cron_expression=entry.get("cron_expression"),
        run_once_at=entry.get("run_once_at"), enabled=entry["enabled"],
        instruction=entry["instruction"], **fields)


def build_unmatched_create_body(normalized):
    """Same shape as build_create_body, for a raw `_unmatched` entry (already the normalize_trigger()
    shape, so no profile expansion is needed -- every field it needs is already present verbatim)."""
    return _assemble_create_body(
        name=normalized["name"], cron_expression=normalized.get("cron_expression"),
        run_once_at=normalized.get("run_once_at"),
        enabled=normalized["enabled"], instruction=normalized["instruction"],
        environment_id=normalized["environment_id"], model=normalized["model"],
        allowed_tools=normalized["allowed_tools"],
        autofix_on_pr_create=normalized["autofix_on_pr_create"], sources=normalized["sources"],
        mcp_connections=normalized["mcp_connections"],
        notifications=normalized.get("notifications"))


def _parse_rfc3339_utc(ts):
    """A timezone-qualified RFC3339 timestamp as UTC, or None when the input is unsafe to restore."""
    try:
        dt = datetime.fromisoformat(str(ts).replace("Z", "+00:00"))
    except (ValueError, TypeError):
        return None
    if dt.tzinfo is None:
        return None
    return dt.astimezone(timezone.utc)


def _one_shot_restore_error(rid, entry):
    ts = entry.get("run_once_at")
    if not ts:
        return None
    dt = _parse_rfc3339_utc(ts)
    if dt is None:
        return (f"{rid}: run_once_at={ts!r} is not a timezone-qualified RFC3339 timestamp -- skipped "
                "rather than emitting an API-invalid create body.")
    if dt < datetime.now(timezone.utc):
        return (f"{rid}: run_once_at ({ts}) is in the past -- skipped because the API rejects past "
                "one-shot schedules. Supply a new future timestamp before restoring it.")
    return None


def restore(routine_ids):
    """(bodies, errors, has_unrestored_unmatched) for the named `routine_ids` (every entry in
    `routines` if empty/None). `bodies` is [(routine_id, create_body), ...]; `errors` is a list of
    human-readable message strings (each naming its routine_id) covering every failure mode: a
    requested id found in neither `routines` nor `_unmatched`; (F2, 2026-08-02 audit) a matched entry
    whose `profile` no longer exists in `profiles` (e.g. a stale snapshot still referencing a retired
    profile) -- that entry is skipped rather than letting `profiles[entry["profile"]]` raise an
    uncaught KeyError, which would otherwise crash this fast-recovery-during-an-incident path with a
    raw traceback; a matched entry whose EFFECTIVE resolved fields (profile + overrides) are missing/
    empty recovery data, per _resolved_fields_errors() -- same check() already runs (B3) -- rather than
    building a create body at all (2026-08-08: _resolve_fields() was changed to .get() every profile
    field instead of hard-indexing, so a profile missing a required key stopped raising KeyError here
    and started silently resolving that field to None; without THIS check, restore() had zero errors
    for that entry and printed a create body with e.g. environment_id=None straight at a live
    RemoteTrigger call -- a crash traded for silent wrong-restore of a live scheduled routine, strictly
    worse); (B2, 2026-08-01 audit) a matched entry whose schedule is still the CRON_UNCONFIRMED
    sentinel -- that entry is skipped rather than handed to build_create_body(), which would otherwise
    emit a create body with a bogus 'TO_POPULATE' cron_expression straight into a live API call; and a
    past/malformed one-shot timestamp.
    `has_unrestored_unmatched` is True when routine_ids was empty AND `_unmatched` is
    non-empty (a 'restore all' never silently expands to include unreviewed unmatched triggers -- the
    caller prints a note instead)."""
    doc = load_backup()
    profiles, routines, unmatched = doc["profiles"], doc["routines"], doc.get("_unmatched", {})

    targets = list(routine_ids) if routine_ids else sorted(routines)
    bodies, errors = [], []
    for rid in targets:
        if rid in routines:
            entry = routines[rid]
            profile_name = entry.get("profile")
            if profile_name not in profiles:
                errors.append(
                    f"{rid}: profile '{profile_name}' not in ops/routine_backup.json 'profiles' -- "
                    f"skipped rather than crashing (e.g. a stale snapshot still referencing a retired "
                    f"profile); fix the entry's 'profile' field or re-run `ingest` against a fresh "
                    f"RemoteTrigger response before restoring this routine.")
                continue
            # check()'s (6) validates the EFFECTIVE resolved fields (profile + overrides) for every
            # entry via this same helper -- restore() used to only check the profile NAME existed, not
            # that resolving it actually produced real data. _resolve_fields() started .get()-ing
            # every profile field instead of hard-indexing (so a hand-edited/corrupted profile missing
            # a key reports cleanly instead of raising KeyError) -- but that safety net alone means a
            # missing field now resolves to None instead of crashing, so WITHOUT this check restore()
            # would build and print a live create body with that field set to None: zero errors, a
            # silent wrong-restore of a live scheduled routine. Run the same validation check() uses
            # and skip the entry on failure, matching the profile-not-found guard just above
            # (2026-08-08).
            field_errors = _resolved_fields_errors(rid, entry, profiles)
            if field_errors:
                errors.extend(field_errors)
                continue
            if entry.get("cron_expression") == CRON_UNCONFIRMED:
                errors.append(
                    f"{rid}: cron_expression is still {CRON_UNCONFIRMED} -- ingest a real value "
                    f"(re-run `ingest` against a fresh RemoteTrigger list/get response) before "
                    f"restoring this routine; skipped rather than emitting an invalid create body.")
                continue
            one_shot_error = _one_shot_restore_error(rid, entry)
            if one_shot_error:
                errors.append(one_shot_error)
                continue
            bodies.append((rid, build_create_body(entry, profiles)))
        elif rid in unmatched:
            normalized = unmatched[rid]
            if normalized.get("cron_expression") == CRON_UNCONFIRMED:
                errors.append(
                    f"{rid}: cron_expression is still {CRON_UNCONFIRMED} -- skipped rather than "
                    f"emitting an invalid create body.")
                continue
            one_shot_error = _one_shot_restore_error(rid, normalized)
            if one_shot_error:
                errors.append(one_shot_error)
                continue
            bodies.append((rid, build_unmatched_create_body(normalized)))
        else:
            errors.append(f"{rid}: not in ops/routine_backup.json (routines or _unmatched) -- skipped.")
    return bodies, errors, (not routine_ids and bool(unmatched))


def _resolved_fields_errors(rid, entry, profiles):
    """B3 (2026-08-01 audit): validate the EFFECTIVE recovery data for one entry -- profile +
    overrides, resolved the same way build_create_body/restore does -- not just that a profile name
    happens to exist. Reproduced live: a payload with session_context: {} ingests into overrides of
    {"model": None, "allowed_tools": [], "environment_id": None, "sources": [], "mcp_connections": []}
    and the OLD check() still printed OK, i.e. it blessed a snapshot whose actual restore data is
    wiped. Caller guarantees entry['profile'] is a valid key into `profiles` (checked separately).

    Deliberately does NOT validate permitted_tools/tool_policy_overrides as their own missing/empty
    check the way mcp_connections itself is checked just below (2026-08-08): those two live INSIDE
    each mcp_connections element, not as their own top-level resolved field, and an empty list for
    either is a LEGITIMATE, common value meaning "no override recorded for this connector, inherit the
    claude.ai connector's own default" -- not "nothing is permitted" (see the module docstring's
    2026-08-08 note). Flagging `[]` there as missing/empty would be a false positive on every
    routine in the fleet today, since none currently has recorded per-tool policy."""
    errors = []
    fields = _resolve_fields(entry, profiles)
    if not (isinstance(fields.get("environment_id"), str) and fields["environment_id"]):
        errors.append(f"{rid}: resolved environment_id is missing/empty ({fields.get('environment_id')!r})")
    if not (isinstance(fields.get("model"), str) and fields["model"]):
        errors.append(f"{rid}: resolved model is missing/empty ({fields.get('model')!r})")
    if not (isinstance(fields.get("allowed_tools"), list) and fields["allowed_tools"]):
        errors.append(f"{rid}: resolved allowed_tools is missing/empty ({fields.get('allowed_tools')!r})")
    if not (isinstance(fields.get("sources"), list) and fields["sources"]):
        errors.append(f"{rid}: resolved sources is missing/empty ({fields.get('sources')!r})")
    if not (isinstance(fields.get("mcp_connections"), list) and fields["mcp_connections"]):
        errors.append(f"{rid}: resolved mcp_connections is missing/empty ({fields.get('mcp_connections')!r})")
    notif = fields.get("notifications")
    channel = notif.get("channel") if isinstance(notif, dict) else None
    if not (isinstance(channel, dict)
            and all(isinstance(channel.get(k), bool) for k in ("email", "push", "slack"))):
        errors.append(f"{rid}: resolved notifications missing/malformed, need "
                       f"channel.{{email,push,slack}} as bools ({notif!r})")
    if not entry.get("name"):
        errors.append(f"{rid}: name is missing/empty")
    return errors


def _schedule_errors(rid, entry):
    """B1 (2026-08-01 audit): an entry must carry EXACTLY ONE of cron_expression/run_once_at -- never
    both (ambiguous -- which one does a restore honor?), never neither (a restore would have nothing
    to schedule with)."""
    has_cron = bool(entry.get("cron_expression"))
    has_run_once = bool(entry.get("run_once_at"))
    if has_cron and has_run_once:
        return [f"{rid}: has BOTH cron_expression and run_once_at -- exactly one is allowed"]
    if not has_cron and not has_run_once:
        return [f"{rid}: has NEITHER cron_expression nor run_once_at -- exactly one is required"]
    return []


# ---- check ------------------------------------------------------------------------------------------
def check():
    """Validate ops/routine_backup.json with NO network: (1) valid JSON, every ops/cadence.yaml
    routine has an entry; (2) each entry's instruction == ops/triggers.json's instruction + ADDENDUM
    (except OPS2, no ADDENDUM per the documented exception) + SCOPE_ADDENDUM (always, no exception);
    (3) each entry's trigger_id matches
    ops/trigger_ids.json; (4) every referenced profile exists (checked for EVERY entry, not just
    cadence-known ones); (5) every entry has exactly one of cron_expression/run_once_at (B1), with a
    parseable timezone-qualified one-shot timestamp; (6) every entry's EFFECTIVE resolved fields
    (profile + overrides) are real, non-empty recovery data, not just a profile name that happens to
    exist (B3); and (7) a fleet routine can never retain a TO_POPULATE schedule that restore refuses.
    Prints per-error ' - ' bullet lines and a FAIL/OK
    summary, mirroring scripts/check_cadence_consistency.py's conventions. Returns 0/1."""
    rel = os.path.relpath(BACKUP_PATH, ROOT)
    if not os.path.exists(BACKUP_PATH):
        print(f"ROUTINE BACKUP CHECK: FAIL\n\n - {rel} does not exist")
        return 1
    try:
        doc = _load_json(BACKUP_PATH)
    except (OSError, ValueError) as e:
        print(f"ROUTINE BACKUP CHECK: FAIL\n\n - {rel} is not valid JSON ({e})")
        return 1

    profiles = doc.get("profiles") or {}
    routines = doc.get("routines") or {}
    errors = []

    cadence_doc = load_yaml(CADENCE_PATH)
    cad_ids = sorted({r["id"] for r in cadence_routines(cadence_doc) if r.get("id")})
    triggers_doc = _load_json(TRIGGERS_PATH) if os.path.exists(TRIGGERS_PATH) else {}
    trigger_ids_doc = _load_json(TRIGGER_IDS_PATH) if os.path.exists(TRIGGER_IDS_PATH) else {}

    # (1) every cadence.yaml routine has an entry
    for rid in cad_ids:
        if rid not in routines:
            errors.append(f"{rid}: in ops/cadence.yaml but missing from {rel} 'routines'")

    # (4) every profile referenced (by ANY entry, not just cadence-known ones) must exist; (5) schedule
    # shape; (6) resolved fields -- (6) is skipped for an entry whose profile is invalid (already
    # reported by (4); _resolve_fields would KeyError on a profile name that doesn't exist).
    for rid, entry in sorted(routines.items()):
        prof = entry.get("profile")
        if prof not in profiles:
            errors.append(f"{rid}: profile '{prof}' not in {rel} 'profiles'")
        else:
            errors.extend(_resolved_fields_errors(rid, entry, profiles))
        errors.extend(_schedule_errors(rid, entry))
        if entry.get("run_once_at") and _parse_rfc3339_utc(entry["run_once_at"]) is None:
            errors.append(f"{rid}: run_once_at must be a timezone-qualified RFC3339 timestamp "
                          f"({entry['run_once_at']!r})")
    # A cadence/fleet entry with this sentinel is not restorable, so it must never be CI-green.
    for rid in cad_ids:
        if (routines.get(rid) or {}).get("cron_expression") == CRON_UNCONFIRMED:
            errors.append(f"{rid}: cron_expression is still {CRON_UNCONFIRMED} -- fleet recovery is "
                          "incomplete and restore will refuse it")

    # (2) instruction == triggers.json instruction (+ ADDENDUM, except OPS2) (+ SCOPE_ADDENDUM, always)
    for rid in cad_ids:
        entry = routines.get(rid)
        if entry is None:
            continue
        want_core = (triggers_doc.get(rid) or {}).get("instruction")
        if want_core is None:
            errors.append(f"{rid}: no matching entry in ops/triggers.json to check instruction against")
            continue
        want = want_core if rid == OPS2_NO_ADDENDUM_ID else want_core + ADDENDUM
        want += SCOPE_ADDENDUM
        have = entry.get("instruction")
        if have != want:
            errors.append(f"{rid}: instruction drift vs ops/triggers.json"
                          f"{' (OPS2 must carry NO addendum)' if rid == OPS2_NO_ADDENDUM_ID else ' + ADDENDUM'}"
                          f" + SCOPE_ADDENDUM\n"
                          f"     want: {want!r}\n"
                          f"     have: {have!r}")

    # (3) trigger_id == ops/trigger_ids.json
    for rid in cad_ids:
        entry = routines.get(rid)
        if entry is None:
            continue
        want_tid = (trigger_ids_doc.get(rid) or {}).get("trigger_id")
        have_tid = entry.get("trigger_id")
        if want_tid is not None and have_tid != want_tid:
            errors.append(f"{rid}: trigger_id mismatch -- ops/trigger_ids.json='{want_tid}' vs "
                          f"{rel}='{have_tid}'")

    if errors:
        print("ROUTINE BACKUP CHECK: FAIL\n")
        for e in errors:
            print(" - " + e)
        print(f"\nFix {rel} (hand-edit, or re-run `python scripts/routine_backup.py ingest <file>` "
              f"against a fresh RemoteTrigger list/get response) so all checks pass, then re-run.")
        return 1

    print(f"ROUTINE BACKUP CHECK: OK — {len(cad_ids)} cadence routines present, instructions and "
          f"trigger_ids match, all {len(profiles)} referenced profile(s) resolve with real recovery "
          f"data ({len(routines)} total entries, {len(doc.get('_unmatched') or {})} unmatched).")
    return 0


# ---- CLI ----------------------------------------------------------------------------------------------
def cmd_ingest(args):
    result = ingest(args.path)
    print(f"routine_backup ingest {args.path}: {len(result['added'])} added, "
          f"{len(result['updated'])} updated, {len(result['unchanged'])} unchanged, "
          f"{len(result['unmatched'])} unmatched.")
    if result["added"]:
        print("  added: " + ", ".join(result["added"]))
    if result["updated"]:
        print("  updated: " + ", ".join(result["updated"]))
    if result["unmatched"]:
        print("  UNMATCHED trigger_id(s), recorded under _unmatched for manual review: "
              + ", ".join(result["unmatched"]))
    if result.get("conflicts"):
        print("  CONFLICT(S) -- trigger_id and instruction resolved to DIFFERENT routine ids; "
              "entry left untouched (fix ops/trigger_ids.json / ops/triggers.json, then re-ingest):")
        for c in result["conflicts"]:
            print(f"    trigger_id={c['trigger_id']}: trigger_id says '{c['trigger_id_routine']}', "
                  f"instruction says '{c['instruction_routine']}'")
    if result["unconfirmed_cron"]:
        print(f"  cron still {CRON_UNCONFIRMED} for: " + ", ".join(result["unconfirmed_cron"]))
    return 1 if result.get("conflicts") else 0


def cmd_restore(args):
    bodies, errors, has_unrestored_unmatched = restore(args.routine_ids)
    for rid, body in bodies:
        print(f"=== {rid} ===")
        print(f"Call RemoteTrigger create with the body below, then record the returned trig_... id "
              f"in ops/trigger_ids.json for '{rid}'.")
        print(json.dumps(body, indent=2, ensure_ascii=False))
        print()
    for msg in errors:
        print(f"ERROR: {msg}", file=sys.stderr)
    if has_unrestored_unmatched:
        print("NOTE: ops/routine_backup.json also has _unmatched entries not included in this "
              "'restore all' -- pass their trigger_id explicitly if you need one restored.",
              file=sys.stderr)
    return 1 if errors else 0


def cmd_check(_args):
    return check()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="command", required=True)

    p_ingest = sub.add_parser("ingest", help="merge a RemoteTrigger list/get response into the backup")
    p_ingest.add_argument("path", help="JSON file, or a directory of JSON files")
    p_ingest.set_defaults(func=cmd_ingest)

    p_restore = sub.add_parser("restore", help="print RemoteTrigger create bodies")
    p_restore.add_argument("routine_ids", nargs="*", help="routine ids to restore (default: all)")
    p_restore.set_defaults(func=cmd_restore)

    p_check = sub.add_parser("check", help="validate the backup file offline, no network")
    p_check.set_defaults(func=cmd_check)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
