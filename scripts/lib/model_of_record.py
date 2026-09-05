"""MODEL OF RECORD mirror-consistency check (check N of scripts/check_cadence_consistency.py) --
extracted here 2026-08-31 (code-quality pass, cadence#2).

WHERE THIS CAME FROM. This ~400-line block (MODEL_ID_CORE/MODEL_ID_RE/MODEL_ID_VALID/
NOT_A_MODEL_PREFIXES/URL_RE/MODEL_EXEMPT, model_mirror_files(), _tooling_prefix_hides_version(),
_is_subtracted_non_assertion(), check_model_of_record()) used to live inline in
check_cadence_consistency.py, where it was ~25% of that 1600+-line module. It was a naturally
separable slice: its only external dependencies were the caller's own path constants
(CADENCE/OWNER_ACTIONS/PLAN/CATALOG_SQL/ROOT) and lib.textio.load_yaml, it had exactly one call site
(check_cadence_consistency.main()'s check N), and it never touched that module's `cad`/`head_by_id`
or any other check's state.

THIS IS A PURE MOVE -- byte-identical behavior, every comment carried over verbatim -- with one
structural change: model_mirror_files() and check_model_of_record() now take their paths as explicit
PARAMETERS instead of reaching for module globals of their own, so this module has no globals for a
test to monkeypatch. check_cadence_consistency.py keeps thin, same-named, zero/one-arg wrapper
functions at check N's old location that resolve ITS OWN CADENCE/OWNER_ACTIONS/PLAN/CATALOG_SQL/ROOT
module globals at call time and pass them straight through here -- so every existing
`monkeypatch.setattr(cc, "CADENCE", ...)`-style fixture in tests/test_cadence_consistency.py keeps
working unchanged, exactly as it did before the move.
"""
import os
import re

from lib.textio import load_yaml

# ---- check N: MODEL OF RECORD mirrors (added 2026-07-28, owner directive; labelled "M" at first —
# renamed to N, the lowest unused letter, once it collided with check_cadence_consistency.py's
# pre-existing check M (H1, whole-system deep audit 2026-07-17): both blocks had claimed the same
# letter independently) ----
# ops/cadence.yaml's top-level `routine_model` is the single source of truth for which Claude model
# the owner configured for the remote-routine fleet ("we will always use the same model for all remote
# routines"). Several prose/SQL sites RESTATE that id; before this check they agreed only by hand, and
# that manual sync had already failed once in practice (commit f347b8f, 2026-07-26: the owner switched
# all 31 routines to claude-opus-5 and the in-repo comment "was already stale even before that").
# A stale mirror is not cosmetic: A1/Q3 read the model of record to decide which model's capability
# research is decision-relevant and which Tier 2 magnitudes flip to version-pending, so a wrong value
# silently anchors the whole foundation document to a model the experiment does not run.
# This check makes the mirrors machine-enforced: change routine_model, and CI names every file that
# still disagrees. Research/history files (Quarterly_AI_Foundation_Delta.md, Monthly_AI_Capabilities.md,
# Annual_AI_Foundation_Sweep.md) are deliberately NOT scanned — they legitimately name many models.
# AI_Trading_Foundation.md is also NOT scanned, but not for the reason this comment used to give.
# It used to be written only by the annual A3, so coupling CI to A3's annual cadence would have failed
# the build for months at a time — that objection no longer applies: the field is now Tier-M-synced at
# DAILY cadence by D3, with Q4/A3 as idempotent backstops (see AI_Trading_Foundation.md Part 4 "Write
# authority — two tiers"). The file stays unscanned anyway, deliberately: a runtime alert
# (D3's/Q4's `model_of_record_synced`) rather than a CI gate is the chosen detector for this field,
# precisely so a model change can never redden the build fleet-wide and block auto-merge for every
# branch. This field's accuracy now rests on the Tier M daily sync path, not on CI.
def model_mirror_files(cadence, owner_actions, plan, catalog_sql):
    """The check-N mirror-file list. Takes its four paths as explicit parameters instead of reaching
    for module globals of its own -- extracted 2026-08-31 (code-quality pass, cadence#2) from
    check_cadence_consistency.py, where this was resolved at CALL time (not import time) from THAT
    module's own path constants CADENCE/OWNER_ACTIONS/PLAN/CATALOG_SQL, precisely so
    monkeypatch.setattr(cc, "CADENCE", ...) (etc., as the fixture-based tests do) took effect. A
    module-level list built once at import time from hardcoded os.path.join(ROOT, ...) calls could
    never be monkeypatched, so a fixture test's routine_model VALUE (read from the patched CADENCE)
    would silently be compared against the REAL repo's mirror files instead of the fixture's —
    cross-contamination between what a test sets up and what it actually checks. That same call-time
    resolution now happens one layer up: check_cadence_consistency.py keeps its own zero-arg
    model_mirror_files() wrapper that reads ITS module globals at call time and passes them in here,
    so the monkeypatch behavior this docstring used to describe directly is unchanged end-to-end."""
    return [cadence, owner_actions, plan, catalog_sql]

# MATCHING A MODEL ID: LOUD BY DEFAULT, NEVER SILENT (2026-07-28, adversarially re-reviewed TWICE the
# SAME day — a first cut over-tightened the match SHAPE, and a second cut over-corrected the other way
# with a shape-based escape hatch that turned out to be just as unsound). The governing principle: a
# FALSE POSITIVE here is cheap — it shows up in CI and is one 'model-id-exempt' marker away from fixed
# — while a FALSE NEGATIVE is the exact failure this check exists to eliminate: a stale mirror that CI
# swears is clean (the manual-sync failure of commit f347b8f). So the match must stay BROAD, subtracting
# only precisely-known non-assertions — never narrowed up front to "look like a model id", and never
# allowed to swallow a real, different id just because it happens to share a shape with something benign.
#
# ROUND 1 (reverted): a same-day adversarial pass on this check's FIRST cut (a pattern requiring family
# word(s) then a digit-led version, with a negative lookahead against a further slug character) proved
# that tightening the match SHAPE was the WRONG TRADE, with live repros:
#   - 'claude-opus-4-latest' — the real -latest/-preview alias convention — matched ZERO times.
#     End-to-end: a fixture with a genuinely stale OWNER_ACTIONS.md mirror printed "CADENCE
#     CONSISTENCY: OK ... matches all mirror sites" and exited 0. Silent false-clean — the worst
#     possible outcome for a check built specifically to prevent silent false-clean.
#   - 'claude-3-5-sonnet-20241022', 'claude-3-opus-20240229', 'claude-5-opus' — real historical
#     Anthropic ids with a DIGIT right after 'claude-' — also matched ZERO times; the tightened shape
#     required a letter immediately after the family hyphen.
#   - the URL-strip (r"https?://\S+", greedy to the next whitespace) SWALLOWED a genuine id sitting
#     right after a markdown link's closing paren with no space:
#     '[text](https://example.com/x)claude-sonnet-4 remains configured' — the id vanished with the URL.
# Fix: match broadly again (MODEL_ID_CORE below), and bound URL_RE at a closing bracket/quote/backtick
# instead of only whitespace.
#
# ROUND 2 (also reverted — DEFECT A, later the same day): the broad-match design then added a SECOND
# subtraction — "a slug that merely EXTENDS THE CORRECT id (routine_model) with a citation suffix", e.g.
# treat 'claude-opus-5-model-card' as clean when routine_model is 'claude-opus-5' because
# token.startswith(model) and the next character is '-'/'.'. This was UNSOUND: a real, DIFFERENT model
# id that happens to extend the correct id character-for-character is STRUCTURALLY IDENTICAL to a
# citation slug — shape alone cannot tell them apart. Live repros, ALL confirmed returning ZERO errors
# with routine_model='claude-opus-5' under the reverted rule:
#     claude-opus-5-preview, claude-opus-5-latest, claude-opus-5-beta, claude-opus-5-exp,
#     claude-opus-5-20250219, claude-opus-5-1, claude-opus-5.1
# A mirror reading "All remote routines run claude-opus-5-preview today." printed "CADENCE
# CONSISTENCY: OK ... matches all mirror sites" and exited 0 — again the exact silent false-clean this
# check exists to prevent. The branch was DELETED, not refined — there is no shape-only fix, because the
# ambiguity is inherent (a citation slug and a real sibling model id are the same shape by construction).
# Consequence, which is CORRECT and intended: 'claude-opus-5-model-card' appearing in prose OUTSIDE a
# URL is now FLAGGED too, and the author resolves it with the 'model-id-exempt' marker, same as any
# other citation. An id sitting inside a URL is still stripped by URL_RE, which already covers the
# overwhelmingly common citation case. Do NOT re-add an "extends the correct id" subtraction in any
# form, however narrowed — if a future site produces a false positive, mark that specific line
# 'model-id-exempt' instead.
#
# Do NOT re-tighten MODEL_ID_CORE to "look like" a model id in some more elaborate way either (Round 1
# above). If a future site produces a false positive, add 'model-id-exempt' to that line, or extend the
# SUBTRACTION below with a new, precisely scoped, well-tested, NON-shape-based exception (one that
# structurally cannot also match a real different model id) — never narrow the broad match itself.
#
# THE DESIGN: match BROADLY (anything shaped like "claude-" + more slug characters), then SUBTRACT
# exactly ONE precisely-known class of non-assertion:
#   NOT_A_MODEL_PREFIXES — tokens that name CLI/SDK tooling, never a model ('claude-code',
#   'claude-code-action', 'claude-agent-sdk-with-your-claude-plan', ...). No Anthropic model is named
#   claude-code*/claude-agent-sdk*/claude-cli*/claude-desktop*, so this can never hide a genuinely
#   drifted id — UNLESS the remainder right after the matched prefix looks version-shaped ('-' or '.'
#   then a DIGIT, e.g. 'claude-code-5', 'claude-cli-2.1'), in which case it is left FLAGGED, not
#   subtracted (DEFECT B, 2026-07-28: a blunt str.startswith() previously swallowed a hypothetical real
#   model sharing a tooling prefix's name — confirmed live, 'claude-code-5' returned zero errors — see
#   _tooling_prefix_hides_version below).
# A URL span still never carries a fleet assertion, so it is stripped before scanning a line — but the
# strip now stops at a closing bracket/brace/angle-bracket/quote/backtick as well as whitespace, so it
# can no longer eat a model id that immediately follows a markdown link with no space.
#
# KNOWN, ACCEPTED LIMIT (DEFECT C — do not "fix"): a model id glued directly onto a URL path segment
# with NO delimiter, e.g. 'https://example.com/system-cardclaude-opus-4-8', is still never scanned —
# but AS OF 2026-07-28's leading-\b removal (below), the MECHANISM is not what an earlier pass of this
# comment claimed. That earlier text said URL_RE "consumes it whole" and that the id is unfindable
# because there is no word boundary between 'card' and 'claude' — implying the boundary check was the
# operative cause. Re-tested against BOTH regex generations and the claim does not hold either way:
#   - WITH the (now-removed) leading \b: MODEL_ID_RE.findall() on the raw, unstripped string ALSO
#     returns [] — 'd' (of 'card') and 'c' (of 'claude') are both word characters, so \b never matches
#     between them and the scan can't even start there. URL_RE never gets a chance to matter for this
#     string under the old regex, because MODEL_ID_RE was already blind to it on its own.
#   - WITHOUT the leading \b (current code, since MODEL_ID_RE has no start-anchor at all anymore):
#     MODEL_ID_RE.findall() on the RAW string now DOES find 'claude-opus-4-8' embedded inside
#     'system-cardclaude-opus-4-8' — confirmed live. So post-fix, URL_RE is now the ACTUAL and ONLY
#     reason this case still yields no match: the whole string is a single unbroken URL (no comma,
#     semicolon, pipe, bracket, quote, or other stop character anywhere in it), so URL_RE's substitution
#     consumes it in full before MODEL_ID_RE ever runs, and the id inside is never scanned. End-to-end
#     behavior is unchanged (still no match) but the mechanism has flipped: URL_RE was NEVER the
#     mechanism under the old regex, and IS the (sole) mechanism under the new one. This is unfixable by
#     construction either way — with no delimiter, the id's characters are indistinguishable from an
#     ordinary URL path segment — and an id living inside a URL, delimited or not, is a citation rather
#     than a fleet assertion, so losing recall here is an acceptable trade. Do NOT widen URL_RE's
#     stop-set trying to catch this (there is no delimiter to stop at) and do NOT add a test asserting
#     the swallow — that would enshrine an accepted gap as a spec instead of leaving it documented here
#     as a known, reasoned limit.
#
# KNOWN, ACCEPTED LIMIT (case sensitivity — decided 2026-07-28, do NOT re-litigate without new
# evidence): MODEL_ID_CORE is lowercase-only, so a capitalized form like 'Claude-Sonnet-5' never
# matches, and re.IGNORECASE was considered and DECLINED. Measured against all four real mirror files
# with re.IGNORECASE added: it would newly match 26 tokens, EVERY one ordinary English prose, NONE a
# model id — Claude-in-Chrome (x8), Claude-only (x5), Claude-version (x5), Claude-specific (x3),
# Claude-Code-on-Web (x2), Claude-crafted (x1), Claude-family (x1), Claude-produced (x1) — i.e. 26
# immediate CI failures each demanding its own 'model-id-exempt' marker on a line that never named a
# model in the first place. Separately, the realistic capitalized human-written form for a fleet
# assertion is "Claude Opus 5" (a space, not a hyphen) — case-insensitivity would not catch that shape
# either way, since MODEL_ID_CORE requires a hyphen after 'claude'. So re.IGNORECASE buys a narrow,
# not-observed-in-practice band (a hyphenated id with non-lowercase letters) at a large, concrete,
# immediate cost (26 false positives on the current tree) and does not even reach the realistic
# capitalized case. Declined. If a future audit re-flags this, re-measure the token count against the
# THEN-current mirror files before re-proposing — do not assume the 26-token cost is stale without
# checking, and do not add re.IGNORECASE without also solving the "Claude Opus 5" (space-separated) gap
# it still wouldn't close.
#
# KNOWN GAP (prose-form family names — "Opus 5", "Sonnet 5", "Fable 5" — documented 2026-07-28; do NOT
# implement prose matching pre-emptively, and do NOT add a test asserting the gap): MODEL_ID_CORE only
# matches ids shaped 'claude-...', so the space-separated human form — including the fleet's own
# routine-suffix convention "(Opus 5)" that the live trigger text uses to name the model to a human
# reader — carries no 'claude-' prefix and is never scanned at all. A mirror line asserting the WRONG
# model in that form therefore passes clean. Confirmed live: with routine_model='claude-opus-5', the
# line "All remote routines now run Sonnet 5 today, replacing the prior Opus 5 configuration." runs
# through MODEL_ID_RE.findall() and returns [] — check_model_of_record() reports zero errors for it.
#   MEASURED CURRENT EXPOSURE (2026-07-28, re-run against the four real mirror files this check scans).
#   Measure the BARE form, not a paren-anchored one — the gap is about the space-separated shape in any
#   context, and a paren-anchored grep undercounts it (1 hit vs 3):
#     $ grep -nE "\b(Opus|Sonnet|Haiku|Fable) [0-9]" ops/cadence.yaml OWNER_ACTIONS.md \
#           Claude_Task_Plan.md bigquery/15_routine_catalog.sql
#     bigquery/15_routine_catalog.sql:110:-- addendum's model references from Fable 5 to Opus 5, and the routines' own `model` field to
#     bigquery/15_routine_catalog.sql:112:-- operator addendum (as of 2026-07-26: "Spawn Sonnet 5 model sub-agents to do the grunt work. Save your
#     bigquery/15_routine_catalog.sql:113:-- processing (Opus 5) for design/analysis/orchestration work only."), separated from the heading by a
#   THREE lines, all in one file, and they are NOT all historical narration — the distinction matters:
#     - :110 IS historical ("owner switched the addendum's model references from Fable 5 to Opus 5"),
#       describing the 2026-07-26 change in the past tense. Already correct; would not rot.
#     - :112-113 are a PRESENT-TENSE quotation of the CURRENT live trigger addendum — the surrounding
#       comment says the live web-UI trigger message "is now ALWAYS" the heading plus this addendum.
#       If the fleet model changes and this quoted text is not updated in the same pass, it becomes
#       exactly the stale live assertion this check exists to catch, and check N will not see it.
#   So the exposure today is small (one file, three lines) but it is NOT purely historical prose.
#   WHY NOT CLOSED NOW: matching bare "Opus 5"/"Sonnet 5"/"Haiku 5"/"Fable 5" would require a second,
#   prose-shaped pattern over ordinary English words (a family name followed by a bare digit), whose
#   false-positive cost on living docs (bigquery/15's own historical-comment prose is the immediate
#   example, and any future narration of a past model switch elsewhere would hit the same pattern) has
#   never been measured — the exact same mistake the case-sensitivity decision above avoided by
#   measuring the 26-token cost FIRST, before deciding.
#   CONSEQUENCE an owner should weigh: if the fleet model changes again, prose of this form — including
#   the "(Opus 5)" routine-suffix convention itself — will NOT be flagged by this check and can rot
#   silently, the same class of risk commit f347b8f already demonstrated for the hyphenated id form.
#   WHAT A FUTURE AUDIT SHOULD DO before proposing a fix: measure the false-positive count of a
#   prose-shaped pattern (e.g. r"\b(Opus|Sonnet|Haiku|Fable) [0-9]") against the THEN-current mirror
#   files first, exactly as the case-sensitivity paragraph's 26-token measurement did — do not add prose
#   matching on the strength of "it seems safe," measure it.
#
# MODEL_ID_CORE is the one shape both MODEL_ID_RE (the mirror scanner) and MODEL_ID_VALID (the
# routine_model well-formedness gate) are built from -- but sharing a shape does NOT by itself mean
# the two can never drift apart: MODEL_ID_VALID.fullmatch() checks the WHOLE string, while
# MODEL_ID_RE.findall() only has to locate an embedded token, and MODEL_ID_RE's trailing \b cannot
# terminate a match right after a non-word character -- a trailing '-' or '.', both admitted by
# MODEL_ID_CORE's own tail class ([a-z0-9.\-]*). So a routine_model value ending in '-' or '.' could
# pass MODEL_ID_VALID.fullmatch() as WELL-FORMED while MODEL_ID_RE.findall() on that same text only
# ever recovers a SHORTER token, self-contradictorily flagging the source-of-truth line itself
# (DEFECT, 2026-07-28: confirmed live with routine_model='claude-opus-5-'). check_model_of_record()'s
# validation gate closes that gap by separately rejecting any routine_model whose last character is
# not alphanumeric. The precise property that now holds is narrower than "can never drift": any value
# the VALIDATION GATE ACCEPTS is matchable IN FULL by the scanner -- not that MODEL_ID_RE and
# MODEL_ID_VALID can never disagree on some OTHER string neither of them is ever asked to validate.
MODEL_ID_CORE = r"claude-[a-z0-9][a-z0-9.\-]*"
# LEADING \b DROPPED (2026-07-28 adversarial review, HIGH; see the DEFECT C paragraph above for how
# this changes that limit's mechanism). The leading \b required a non-word character immediately before
# 'claude', so a dropped-space typo fusing the id into the previous word ("Fleet nowclaude-sonnet-5 is
# the model.") hid it from the scanner entirely -- confirmed live pre-fix, zero errors. The trailing \b
# is KEPT: it still stops the match at the end of the id's own character class (no word character
# bleeds past a match into whatever follows), which is the boundary that actually matters for correctly
# delimiting the RIGHT edge of an id. Re-verified against all four real mirror files (ops/cadence.yaml,
# OWNER_ACTIONS.md, Claude_Task_Plan.md, bigquery/15_routine_catalog.sql): dropping the leading \b
# matches NOTHING NEW there today, so this is a free strictness gain with zero false-positive cost on
# the current tree.
MODEL_ID_RE = re.compile(MODEL_ID_CORE + r"\b")
# fullmatch (not a bare $-anchored .match()) so a YAML block-scalar's trailing "\n" (routine_model: |)
# is rejected as MALFORMED instead of silently passing — a bare "$" also matches just before a
# trailing newline, which let such a value leak into the mismatch loop below and interpolate a raw
# embedded newline into the single-line " - " bullet report (2026-07-28 adversarial review).
MODEL_ID_VALID = re.compile(MODEL_ID_CORE)
# The one remaining subtraction: a token starting with one of these names CLI/SDK tooling, never a
# model — UNLESS the remainder right after the matched prefix looks version-shaped (DEFECT B; see
# _tooling_prefix_hides_version), in which case it is left FLAGGED rather than subtracted. Also enforced
# against routine_model ITSELF (see check_model_of_record) — a routine_model value that hits one of
# these prefixes is rejected outright as malformed: it would be too easy to confuse with the CLI/SDK
# tooling of the same name, and in the exact-match case (e.g. routine_model='claude-code') could never
# be found by the scanner at all (it would always subtract itself out as tooling), silently making the
# whole check vacuous.
NOT_A_MODEL_PREFIXES = ("claude-code", "claude-agent-sdk", "claude-cli", "claude-desktop")
# A URL span never carries a fleet assertion — strip it before scanning a line for model ids. Bounded
# at a closing bracket/brace/angle-bracket/quote/backtick as well as whitespace, so the strip stops at
# a markdown link's closing ')' instead of running on and eating whatever immediately follows with no
# space (2026-07-28 adversarial review, MEDIUM finding). Also bounded at ',' ';' '|' '<' '(' '[' '{'
# (2026-07-28, operator-requested, MEDIUM): those are natural sentence delimiters the character class
# previously still admitted, so a genuine stale id sitting immediately after one of them within the
# same line -- e.g. "See https://example.com/x,claude-sonnet-4 is stale" -- was eaten along with the
# URL and never scanned. Confirmed live pre-fix: zero matches on that line. Deliberately NOT bounded at
# ':' despite it also reading as a plausible sentence delimiter: a URL legitimately contains a ':' in
# an authority-section port number ("https://example.com:8080/path"), and excluding it from the class
# would truncate the strip there, leaving "8080/path" unstripped and scanned as ordinary text on every
# such URL. The genuine in-URL-path citation case (a slug with NO delimiter before it, e.g.
# '.../claude-opus-4-8-system-card') is unaffected by any of this -- none of the newly-excluded
# characters appear in an ordinary path segment, so that span is still consumed whole.
URL_RE = re.compile(r"""https?://[^\s,;|<>()\[\]{}"'`]+""")
# A line carrying this marker names a model id for illustration/history, not as a fleet assertion.
# \b-anchored on the LEFT, negative-lookahead-bounded on the RIGHT (2026-07-28 adversarial review,
# HIGH, two rounds the same day):
#   Round 1: an unanchored substring search let an ordinary word containing 'model-id-exempt' as an
#   infix (e.g. "...that citation is model-id-exemption-only, not a live assertion.") silently suppress
#   a REAL drift reported on the same line -- check_model_of_record() skips the ENTIRE line on a
#   MODEL_EXEMPT match, so a false marker hit hides everything on that line, not just itself. Confirmed
#   live pre-fix: a fixture line naming a genuinely stale id and containing "model-id-exemption-only"
#   printed "CADENCE CONSISTENCY: OK" and exited 0. Fixed by adding a trailing \b.
#   Round 2 (this fix): a trailing \b is satisfied by ANY non-word character, including '-', so a
#   LONGER hyphen-continued token that merely STARTS WITH the marker -- a filename or config-key
#   mention like 'model-id-exempt-list.md' or 'model-id-exempt-routines:' -- also matched and, same as
#   Round 1, silently suppressed a genuine drift reported on the same line. Confirmed live pre-fix:
#   'model-id-exempt-list.md' and 'model-id-exempt-routines:' both matched \bmodel-id-exempt\b (the '-'
#   right after 'exempt' already satisfies a trailing \b). Fixed by replacing the trailing \b with a
#   negative lookahead that additionally rejects a hyphen continuation, `(?![-\w])`: the marker token
#   must be followed by end-of-string or a character that is neither '-' nor a word character (a space,
#   '.', ',', ')', backtick, etc. -- exactly the ordinary prose punctuation that follows a real,
#   standalone marker) to suppress. 'model-id-exempt', 'model-id-exempt.', 'marked model-id-exempt, a
#   cite' all still suppress; 'model-id-exempt-list.md', 'model-id-exempt-routines:',
#   'model-id-exemption-only' ('i' is a word char), 'model-id-exempted' ('e' is a word char), and
#   'nonmodel-id-exempt' (no left \b -- 'n' before 'model' is a word char) do not.
MODEL_EXEMPT = re.compile(r"\bmodel-id-exempt(?![-\w])")
# KNOWN, DELIBERATE LIMIT (model-id-exempt is LINE-SCOPED — documented 2026-07-28, do NOT implement the
# escape hatch below pre-emptively): check_model_of_record() skips the ENTIRE line on a MODEL_EXEMPT
# match, not just the token nearest the marker. A legitimate exemption for one, historical id on a line
# therefore also hides any OTHER, genuinely wrong id sharing that same line. Confirmed live: with
# routine_model='claude-opus-5', the line "In 2026-07 we migrated from claude-sonnet-4
# (model-id-exempt) to claude-opus-6 as the new fleet model." matches MODEL_EXEMPT (True) and is
# skipped whole — the pre-skip scan would have found BOTH 'claude-sonnet-4' and 'claude-opus-6', the
# latter a real drift (routine_model is 'claude-opus-5', not 'claude-opus-6'), but check_model_of_record
# never gets to look at either because the line-level skip fires first.
#   WHY THIS IS DIFFERENT FROM THE ROUNDS 1-6 FIXES: every other miss this file's history documents was
#   the CHECKER failing to see something on its own — a regex too narrow, a strip too greedy, a boundary
#   too loose — with no human involvement at the site of the miss. This one requires a human to have
#   typed the literal marker 'model-id-exempt' onto that exact line, which is an explicit, author-signed
#   assertion that the author reviewed that line and takes responsibility for what it contains. Line
#   scope is therefore the INTENDED contract of the marker, not an accidental gap: it is opt-in silence
#   at a spot a human already looked at, not the check silently missing something nobody looked at.
#   Do NOT "fix" this by narrowing MODEL_EXEMPT's suppression to some token-proximity heuristic (e.g.
#   "only the nearest id") — proximity is a shape-based guess with the same failure mode Rounds 1/2
#   above rejected for MODEL_ID_CORE itself, and it would silently change the meaning of every
#   'model-id-exempt' marker already written into the tree today.
#   ESCAPE HATCH IF THIS EVER BITES IN PRACTICE (record only — NOT implemented, do not add pre-emptively):
#   a scoped marker form 'model-id-exempt:<id>' that suppresses only the named token instead of the
#   whole line, backward compatible with the existing bare marker (a bare 'model-id-exempt' keeps
#   meaning "whole line," as today). If a future audit finds a real line that needs one id exempted
#   while a second, different id on the same line must still be caught, implement the scoped form then —
#   do not add it speculatively ahead of a real, observed need.


def _tooling_prefix_hides_version(token, prefix):
    """True if the characters immediately after `prefix` in `token` look like a version suffix — a '-'
    or '.' followed by a DIGIT, e.g. 'claude-code-5', 'claude-code-4-8', 'claude-cli-2.1' — rather than
    a tooling-name extension like 'claude-code-action' or 'claude-code-settings.json'.

    DEFECT B (2026-07-28 adversarial review): NOT_A_MODEL_PREFIXES exists to subtract CLI/SDK tooling
    names, never a model — but matching it with a blunt str.startswith() silently swallowed a
    hypothetical real model that happens to share a tooling prefix's name (confirmed live:
    'claude-code-5' returned zero errors against routine_model='claude-opus-5'). A version-shaped
    remainder is a positive signal the token names something OTHER than the tooling product itself, so
    such a token must stay FLAGGED (loud) rather than be subtracted as "just tooling".

    DEFECT B, CONTINUED (2026-07-28, same-day follow-up): the original fix only recognized a version
    when a literal '-' or '.' SEPARATES it from the prefix ('claude-code-5'). A digit GLUED directly
    onto the prefix with no separator ('claude-code5') fell through both branches and was silently
    subtracted as ordinary tooling — confirmed live: 'claude-code5' (and 'claude-code58', 'claude-cli9',
    'claude-desktop3', 'claude-agent-sdk7') returned zero errors. A leading digit is exactly as strong a
    version-shaped signal as a separator-prefixed one, so it must also stay FLAGGED.

    DEFECT B, THIRD CASE (quality pass 2026-08-22): both branches above only inspect the FIRST one or
    two characters after the prefix, so a token that continues with a LETTER and only then carries a
    version suffix -- 'claude-codex-5' (prefix 'claude-code', rest 'x-5'), 'claude-clinical-5'
    (prefix 'claude-cli', rest 'nical-5'), 'claude-desktopia-1' -- was silently subtracted as
    ordinary tooling. Reproduced end to end: with routine_model 'claude-opus-5' and OWNER_ACTIONS.md
    reading "All remote routines now run claude-codex-5 for grunt work", check_model_of_record()
    returned ZERO errors on a genuinely drifted model id.

    The letter-continuation itself must stay subtracted -- 'claude-codebase' is a real tooling
    extension and is pinned as such by _GLUED_DIGIT_GENUINE_TOOLING_EXTENSION_TOKENS -- so the
    signal is not "does it continue with a letter" but "does the remainder carry a version-shaped
    segment ANYWHERE". Anything whose remainder contains a '-'- or '.'-led digit is version-shaped
    and stays FLAGGED; every existing subtracted case ('claude-code', 'claude-codebase',
    'claude-code-action', 'claude-code-settings.json', 'claude-agent-sdk-python',
    'claude-desktop.app') carries no separator-led digit at all and is unaffected.

    DEFECT B, FOURTH CASE (quality pass 2026-09-04): the third case's rule was written END-ANCHORED
    -- "does the WHOLE token END in a version", i.e. a '-'/'.'-led digit run followed immediately by
    end-of-token. That missed the alias convention the ROUND 1 block above MODEL_ID_CORE names as the
    REAL one ('claude-opus-4-latest'), and the '-preview'/'-latest'/'-beta'/'-exp' shapes DEFECT A's
    own repro list enumerates: a version FOLLOWED BY an alias suffix does not end the token. So the
    2026-08-22 fix closed 'claude-codex-5' but left 'claude-codex-5-latest', 'claude-codex-5-preview'
    and 'claude-desktopia-1-beta' silently subtracted -- the same false-clean, one alias suffix away.
    Reproduced end to end pre-fix: routine_model 'claude-opus-5' plus an OWNER_ACTIONS.md line "All
    remote routines now run claude-codex-5-latest for grunt work" returned ZERO errors. The end
    anchor is therefore dropped: a separator-led digit ANYWHERE in the remainder is the signal. The
    change is strictly LOUDER, never narrower -- the direction THE DESIGN above requires (a false
    positive here is cheap and self-correcting; a false negative is the exact failure this check
    exists to eliminate) -- and it is NOT a re-introduction of the routine_model-dependent
    subtraction DEFECT A deleted. Measured 2026-09-04 over every claude-code*/claude-cli*/
    claude-agent-sdk*/claude-desktop*-prefixed token in the repo (25 distinct) plus all three pinned
    tables in tests/test_cadence_consistency.py: zero tokens change classification.

    Note the ordering below: the DEFECT B original branch ("a '-'/'.' separator IMMEDIATELY after the
    prefix, then a digit") no longer needs a line of its own -- it is a strict subset of the
    anywhere-search, which would otherwise leave it unreachable. Only the GLUED-digit case
    ('claude-code5', rest '5', no separator at all) is still a genuinely separate test."""
    rest = token[len(prefix):]
    if not rest:
        return False
    if rest[0].isdigit():
        return True
    return bool(re.search(r"[-.]\d", rest))


def _is_subtracted_non_assertion(token):
    """True if `token` (a MODEL_ID_RE match already known to differ from routine_model) belongs to the
    one precisely-known non-assertion class the broad match must SUBTRACT — see "THE DESIGN" above:
    tokens naming CLI/SDK tooling (NOT_A_MODEL_PREFIXES), unless the remainder right after the matched
    prefix looks version-shaped, in which case the token is left FLAGGED (DEFECT B, see
    _tooling_prefix_hides_version).

    DEFECT A (2026-07-28 adversarial review) deleted this function's second, unsound subtraction — "a
    slug that merely extends the correct routine_model with a citation suffix" — entirely; see the
    comment block above MODEL_ID_CORE for the live repros that forced the removal and why no shape-only
    replacement is possible. Do NOT re-add a routine_model-dependent branch here."""
    for prefix in NOT_A_MODEL_PREFIXES:
        if token.startswith(prefix):
            return not _tooling_prefix_hides_version(token, prefix)
    return False


def check_model_of_record(cadence_path, mirror_paths, root, doc=None):
    """`routine_model` exists and is well-formed, and every mirror site quotes the same id.

    cadence_path/mirror_paths/root -- explicit parameters (extracted 2026-08-31, code-quality pass,
    cadence#2, from check_cadence_consistency.py, where this read its own module-level CADENCE /
    model_mirror_files() / ROOT globals directly) so this module has no globals of its own for a test
    to monkeypatch. check_cadence_consistency.py keeps a thin check_model_of_record(doc=None) wrapper
    at check N's old location that resolves ITS OWN CADENCE/ROOT globals (and its own
    model_mirror_files() wrapper) at call time and passes them straight through, so every existing
    `monkeypatch.setattr(cc, "CADENCE", ...)`-style fixture in tests/test_cadence_consistency.py keeps
    working unchanged.

    doc -- an already-parsed ops/cadence.yaml document, or None to parse `cadence_path` fresh here;
    see check_cadence_consistency.py's PERF NOTE above its load_cadence() for why callers thread a
    pre-parsed doc through instead of re-parsing it 5 times per run."""
    errs = []
    if doc is None:
        doc = load_yaml(cadence_path)
    model = doc.get("routine_model")
    if model is None:
        return ["ops/cadence.yaml: missing top-level 'routine_model' — it is the source of truth for "
                "which Claude model the owner configured for the remote-routine fleet, and A1/Q3/A3 "
                "read it to anchor AI_Trading_Foundation.md's in-use-version field. Re-add it."], None
    if not (isinstance(model, str) and MODEL_ID_VALID.fullmatch(model)):
        return [f"ops/cadence.yaml: routine_model must be a bare Claude model id like "
                f"'claude-opus-5' (got {model!r})"], None
    if not model[-1].isalnum():
        # MODEL_ID_CORE's tail class ([a-z0-9.\-]*) admits a trailing '-' or '.', so a value like
        # 'claude-opus-5-' or 'claude-opus-5.' passes MODEL_ID_VALID.fullmatch() above as
        # well-formed -- but MODEL_ID_RE's trailing \b cannot terminate a match right after that same
        # non-word character, so the mirror scanner recovers only the SHORTER token 'claude-opus-5'
        # from prose naming this exact value. Left unchecked, check_model_of_record() would then
        # report BOTH a mirror line AND this very ops/cadence.yaml line as drifted -- a
        # self-contradictory report pointing the author at the line that IS the source value. Reject
        # it here instead, explicitly naming the trailing character so the fix is obvious.
        return [f"ops/cadence.yaml: routine_model must be a bare Claude model id like "
                f"'claude-opus-5' (got {model!r} — it ends with {model[-1]!r}, a trailing "
                f"non-alphanumeric character the mirror scanner's word-boundary match can never "
                f"include, so this value could never be found in full by MODEL_ID_RE)"], None
    # Reject the model id only if the mirror scanner would SUBTRACT it as a tooling mention -- that
    # is exactly the vacuity condition the message below describes. Previously a bare
    # startswith(NOT_A_MODEL_PREFIXES), which also rejected a legitimate version-shaped id that
    # merely shares a tooling prefix's characters, e.g. 'claude-codex-5' (quality pass 2026-08-22).
    if _is_subtracted_non_assertion(model):
        return [f"ops/cadence.yaml: routine_model must be a bare Claude model id like "
                f"'claude-opus-5' (got {model!r} — this names CLI/SDK tooling, never a model; every "
                f"mirror-site token that starts with it would be subtracted as tooling too, making "
                f"this whole check vacuous)"], None
    for path in mirror_paths:
        if not os.path.exists(path):
            continue
        rel = os.path.relpath(path, root)
        # RESOURCE-LEAK FIX (finding model-of-record-bare-open): this used to be a bare
        # `open(path, encoding="utf-8")` handed straight to enumerate(), with no `with` block and no
        # variable binding — the exact idiom lib/textio.py's own module docstring names as problem #1
        # it exists to retire repo-wide ("fine on CPython, a ResourceWarning under -W error and a real
        # leak on any other runtime"). Every other lib/*.py file that opens a file (textio.py,
        # mcp_tokens.py, slice_writer.py) already uses `with open(...) as f`; this was the sole
        # holdout despite importing lib.textio two lines above. The risk isn't cosmetic: if
        # MODEL_ID_RE.findall() or this loop body ever raised mid-file (a future mirror file with
        # invalid UTF-8, or any other exception), the bare-open handle stays referenced by the
        # exception's traceback/frame and is not promptly released — confirmed live (see
        # tests/test_model_of_record.py): catching such an exception with the traceback still bound
        # leaves the old form's handle open, while the `with` form closes it during unwind, before the
        # exception ever reaches the caller. A full-file read via lib.textio.read_text is unnecessary
        # here since the loop only needs line-by-line access, so keep the generator — just bind and
        # close it properly.
        with open(path, encoding="utf-8") as mirror_file:
            for n, line in enumerate(mirror_file, 1):
                if MODEL_EXEMPT.search(line):
                    continue
                scanned = URL_RE.sub(" ", line)
                # dict.fromkeys, not set(...): de-dupes while preserving FIRST-APPEARANCE order, so
                # two distinct wrong ids on one line report in a deterministic (left-to-right) order
                # instead of one that varies with PYTHONHASHSEED (2026-07-28 adversarial review).
                for found in dict.fromkeys(MODEL_ID_RE.findall(scanned)):
                    if found == model or _is_subtracted_non_assertion(found):
                        continue
                    errs.append(
                        f"{rel}:{n}: names model '{found}' but ops/cadence.yaml routine_model is "
                        f"'{model}'. All remote routines run the SAME model, so every mirror must "
                        f"quote it. If the owner changed the fleet model, update routine_model AND "
                        f"this line in the same pass; if this line is illustrative or historical "
                        f"rather than a fleet assertion, add the marker 'model-id-exempt' to it.")
    return errs, model
