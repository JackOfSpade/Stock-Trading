"""Shared roster-active-code definition for the two roster-consistency gates (roster-group audit,
2026-08-08).

scripts/check_roster_consistency.py's R-A and scripts/check_live_roster_parity.py's live-vs-repo
diff both need the same thing — the set of strategy/roster.yaml `strategies[].code` whose
roster_state means "is_active" (probe/adopted) — and until this consolidation each file carried its
own byte-identical copy of ACTIVE_STATES_YAML and roster_active_codes(), differing only in a
comment. One copy here means a future roster_state addition only has to change in one place instead
of being remembered (and kept in sync) twice.

Both copies also read `s["code"]` instead of `s.get("code")`, so a roster.yaml entry missing its
`code` field raised an uncaught KeyError that killed the checker before it ever reached its own
error-collection/report step (same audit pass — the crash pre-empted BOTH gates' fail-clean
convention, not just one). Fixed here: `s.get("code")` plus a truthy filter, so a codeless entry
simply contributes no code to the returned set instead of crashing. That entry then surfaces through
each CALLER's own pre-existing set-comparison error path — check_roster_consistency.py's R-A
"in <surface> but not roster.yaml" message (the entry's roster_state says it should be active, but no
other surface can ever name a code roster.yaml never gave it, so the set mismatch is real and
already-reported) or check_live_roster_parity.py's symmetric-difference FAIL — exactly like any other
missing-code roster drift, rather than needing a bespoke error message in this shared helper.
"""
ACTIVE_STATES_YAML = {"probe", "adopted"}      # roster.yaml roster_state values meaning is_active


def roster_active_codes(doc):
    """Parsed roster.yaml doc -> set of strategies[].code where roster_state in ACTIVE_STATES_YAML.

    A strategy entry with no (or falsy) `code` contributes nothing to the returned set rather than
    raising — see module docstring for why that's the right failure mode here."""
    return {s.get("code") for s in doc.get("strategies", []) or []
            if str(s.get("roster_state", "")).lower() in ACTIVE_STATES_YAML and s.get("code")}
