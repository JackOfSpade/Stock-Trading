#!/usr/bin/env bash
# Sourceable RUNBOOK §38 commit-marker helpers, sourced by scripts/write_routine_commit_markers.sh
# (run from .github/workflows/auto-merge-claude.yml after an explicitly selected PR merges) and
# tested directly by tests/test_auto_merge_logic.sh, so production and tests run the IDENTICAL
# implementation (no shadow copy to drift).
#
# The CI-gate / retry / stuck-gate / ancestor predicates that used to live here served the retired
# branch-sweeping auto-merge job; "Merge validated PR" (.github/scripts/merge_validated_pr.py) now
# validates checks itself and dispatches the full ci.yml, so they were removed on 2026-10-26.

# ---- RUNBOOK §38 commit-marker field extraction (extracted + FIXED 2026-07-29) ----------------
# WHY THESE EXIST: the marker fields used to be parsed by two inline greps in
# auto-merge-claude.yml, untested, and REQUIRED BOTH a routine token AND a full YYYY-MM-DD in the
# commit subject before writing an ops.routine_commit_markers row. Verified 2026-07-29: that gate
# meant the table had only EVER received rows for D1, D2 and W5 — the three routines whose commit
# convention happens to embed a full ISO date ("D1 Market Development Scan 2026-07-28"). Routines
# writing e.g. "A1 2026: annual foundation re-derivation" carry only a YEAR, so A1/A2/A3 landed real
# commits on main and got no marker at all. Because ops.sp_backfill_run_log_from_markers (RUNBOOK
# §38 layer A) reads this table, that self-heal had likewise only ever been able to repair those same
# three routines — a silent, fleet-wide hole in the "commit landed but run_log missing" recovery path.
# Extracted here as PURE string functions so tests/test_auto_merge_logic.sh covers the production
# implementation directly.

# marker_routine_from_subject <subject> — print the leading routine id if the subject starts with a
# known routine token, else print nothing. The token may be followed by whitespace OR punctuation
# (":", ".", ",", "-"), so "SL5: register newcomer" is recognised as well as "D1 Market Scan ...".
# A non-routine subject ("Landing hardening: ...", "Merge origin/main into ...") prints nothing, which
# is what suppresses marker rows for human/non-routine branches.
# The allowlist assignment below keeps the exact literal shape that
# scripts/check_cadence_consistency.py's check H greps for — that guard asserts every id in
# ops/cadence.yaml is accepted here, so a newly-added routine cannot be silently skipped by the
# §38 marker-write. Do NOT rewrite it into a case statement or a different quoting style without
# updating AUTO_MERGE_ROUTINE_RE / AUTO_MERGE_DECISION_SH and AUTO_MERGE_YML in that script. NOTE: do not restate
# that literal's shape anywhere in a comment — the checker's own pattern would match the comment
# first and silently validate a placeholder instead of the real allowlist.
marker_routine_from_subject() {
  local token routine_re
  routine_re='^(D1|D2a|D2|D3|OPS0|OPS1|OPS2|W[1-5]|M1a|M1b|M1R|M[2-5]|Q[1-4]|A[1-3]|SL[1-5]|AR_att|AR_orc)$'
  token="$(printf '%s' "${1:-}" | grep -oE '^[A-Za-z][A-Za-z0-9_]*' || true)"
  if [ -n "$token" ] && [[ "$token" =~ $routine_re ]]; then
    printf '%s\n' "$token"
  else
    printf '\n'
  fi
}

# marker_run_date_from_subject <subject> <fallback_iso_date> — print the run_date for the marker row:
# a full YYYY-MM-DD embedded in the subject when present (authoritative — preserves the existing
# D1/D2/W5 behaviour exactly), otherwise the supplied fallback. The caller passes the commit's author
# date rendered in America/Denver (`TZ=America/Denver git log -1 --date=short-local --format=%ad`),
# i.e. the OPERATING-plane calendar date on which the routine actually made the commit — not the merge
# date, and not the commit's own recorded offset. CORRECTED 2026-08-04: the caller previously passed
# `--format=%as`, which renders in the commit's OWN offset; routine containers commit in UTC, so an
# evening-slot routine's commit came back dated TOMORROW — reintroducing precisely the midnight-UTC
# misattribution this fallback exists to prevent. Prints nothing if neither source yields a date, and
# the caller then skips the row rather than inventing one.
marker_run_date_from_subject() {
  local in_subject
  in_subject="$(printf '%s' "${1:-}" | grep -oE '\b[0-9]{4}-[0-9]{2}-[0-9]{2}\b' | head -1 || true)"
  if [ -n "$in_subject" ]; then
    printf '%s\n' "$in_subject"
  else
    printf '%s\n' "${2:-}"
  fi
}

# ---- Marker WRITE guards (added 2026-08-17, W5) --------------------------------------------------
# WHY: a ops.routine_commit_markers row asserts "this routine's OUTPUT commit landed on main", and
# ops.sp_backfill_run_log_from_markers turns that assertion into a 'completed' ops.run_log row. The two
# functions above decide WHICH routine/date a subject names; neither can tell whether the commit was
# produced BY a routine run at all. Two commit classes therefore minted phantom completions:
#
#   (A) A routine's own HALT commit. When a routine correctly follows the connector-pre-flight halt
#       branch it commits a record of the halt — e.g. "W5 2026-08-16: HALT at pre-flight — BigQuery
#       connector de-authorized", a commit whose own body states "HALTED W5 cleanly. No factbase edits,
#       no writes." That subject parses to routine=W5, run_date=2026-08-16 and was marked as output.
#       The perverse result: the better a routine documents its own failure, the more certainly it is
#       recorded as having succeeded.
#   (B) A NON-routine commit whose subject merely begins with a routine token. The operator's
#       "W5 weekend timing optimization, plus routine-scope CI guard and cadence cleanup" (author
#       3615459+JackOfSpade@users.noreply.github.com, 2026-08-17) is a commit ABOUT W5, not BY W5; with
#       no date in the subject the run_date fallback attributed it to the commit's own day.
#
# MEASURED HARM (2026-08-17, W5): those two rows made W5 read as completed on both 08-16 and 08-17, so
# the cadence dead-man's switch saw ran_completed_this_period=TRUE and could never raise period_missed
# or reach OPS0 auto-refire readiness (OPS0 logged exactly this diagnosis on 2026-08-16), AND
# state.routine_catchup_window collapsed W5's evidence reach from 8.3 days to 0.07 — the catch-up
# protocol that exists to cover missed periods was disarmed by the very rows recording the miss. Two
# W5 cycles were lost with nothing alarming; W4 had to flag it in prose.
#
# THIS IS A RECURRING FAMILY, NOT A ONE-OFF: the workflow's own inline comment records the same
# phantom-completion outcome on 2026-08-04, when an SL2 commit's UTC-rendered fallback date blinded
# state.queue_driven_silence_watch. That fix corrected the DATE limb; these two guards close the
# "was this a routine output commit at all?" limb.
#
# BIAS: both guards fail toward NOT writing a marker. That asymmetry is deliberate — a MISSING marker
# degrades to the pre-existing loud path (sp_assert_deps raises missing_dependency and the gate's
# git-evidence fallback still applies), whereas a FALSE marker silently blinds dead-man's switches.
# A noisy miss is recoverable; a silent false completion is what cost two cycles here.

# marker_author_is_routine <author_email> — true when a commit was authored by a routine session.
# Routine containers commit as `Claude <noreply@anthropic.com>`; VERIFIED against every routine commit
# in the 2026-07/08 window. Operator commits (GitHub web UI `…@users.noreply.github.com`, local
# `jack@mac.home`) and the auto-merge bot are all outside this domain — the same authorship split
# CLAUDE.md's stop-hook note already documents. Suffix-matched rather than pinned to the exact address
# so a harness identity change degrades to "still recognised" rather than "every marker suppressed".
marker_author_is_routine() {
  case "${1:-}" in
    *"@anthropic.com") return 0 ;;
    *) return 1 ;;
  esac
}

# marker_subject_declares_no_completion <subject> — true when a commit subject AFFIRMATIVELY states the
# run did not complete, so no marker should be written no matter how well-formed the id/date are.
# Deliberately narrow: it matches only the halt/abort vocabulary the halt-commit convention actually
# uses, as whole words. It is a BACKSTOP, never the authoritative completion signal — that remains the
# routine's own ops.sp_routine_end write.
#
# CORRECTION (2026-09-04 quality pass): this comment used to end that first sentence with "...so an
# ordinary output subject cannot trip it", and that claim is measurably FALSE. Measured over the whole
# repo history (source this file, walk `git log`, keep commits where marker_author_is_routine AND
# marker_routine_from_subject both hold): 447 candidate commits, 8 suppressed — and only 4 of the 8 are
# true halts (W5 "HALT at pre-flight", D3 "HALTED at dependency gate", D2 "HALTED on dependency gate",
# D2 "HALTED on missing D1 dependency"). The other 4 are COMPLETED runs whose subjects merely mention a
# halt: "AR_orc: stop a routine's own decision write from halting its own gate" (the word describes the
# fix), "W4 2026-W30: ... trading-halt root cause re-diagnosed" (`\bhalt\b` matches inside the hyphen
# compound), "D2a ... trading gate RED (halt)", "W4 2026-W32: ... MTZ exit confirmed but halted".
#
# That over-suppression (~0.9% of candidates) is left in place ON PURPOSE — it is the DESIGNED-SAFE
# direction, per the BIAS paragraph above: a missing marker degrades to the loud path, a false marker
# silently blinds the dead-man's switches (the measured harm that cost two W5 cycles). A narrower
# alternation was evaluated and REJECTED in the same pass: dropping halts/halting/aborts/aborting to
# recover 2 of those 4 historical commits also stops matching plausible genuine halt declarations
# ("D1 2026-09-01: aborting on connector failure", "W5 halts on pre-flight"), i.e. it trades the
# safe error for the dangerous one in this repo's most consequential automation. Do NOT re-propose it.
# The four measured false suppressions are pinned as regression cases in tests/test_auto_merge_logic.sh
# ("(B) halt/abort subjects") so the current, deliberate behavior cannot drift silently.
# Suppression is announced via ::notice:: in auto-merge-claude.yml, so an over-suppressed run is loud;
# what it loses is the RUNBOOK §38 sp_backfill_run_log_from_markers repair for that run.
marker_subject_declares_no_completion() {
  printf '%s' "${1:-}" | grep -qiE '\b(halt|halts|halted|halting|abort|aborts|aborted|aborting)\b'
}
