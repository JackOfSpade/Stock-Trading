"""Regression coverage for scripts/check_routine_scope.py."""
from conftest import load_module_from_path


crs = load_module_from_path("check_routine_scope", "scripts", "check_routine_scope.py")


def _plan(overrides=None):
    bodies = {
        "D1": (
            "D1 uses regular-session daily bars. Route a qualifying mover to Strategy B as a B candidate.\n"
        ),
        "W1": "W1 reuses D1-originated catalysts when maintaining its future calendar.\n",
        "W2": (
            "W2 consumes D1 events.decision_log research-screen records. Use event identity and skip an "
            "already queued or decided thesis in events.queue_events. W2 logs an entry_type "
            "screen='post-event-enrichment' provenance record, not a second significance screen.\n"
        ),
        "W3": (
            "D1 owns mechanical convergence and time-based exits. W3 covers narrative drift and "
            "cumulative evidence.\n"
        ),
        "W4": "Route weekly findings to D2 via idempotent PENDING_ANALYSIS queue items.\n",
        "W5": "W5 reports trend-only analytics and leaves repairs to the daily owner.\n",
    }
    bodies.update(overrides or {})
    return "\n".join(f"## {rid}. Example — regular routine\n{body}" for rid, body in bodies.items())


def test_clean_plan_passes():
    assert crs.check(_plan()) == []


def test_sections_are_isolated_from_sibling_examples():
    text = _plan({"W2": "W2 consumes D1 events.decision_log research-screen records. Use event identity and skip an already queued thesis in events.queue_events. W2 logs an entry_type post-event-enrichment provenance record, not a second significance screen.\n"})
    text += ("\n## M2. Example — regular routine\n"
             # sp_embed_pending is W5's OWN forbidden token, and W5 is the section this M2 example
             # FOLLOWS (_plan()'s bodies dict is insertion-ordered and ends at W5) -- so if the sibling
             # routine heading ever stops being a boundary, this example leaks into W5's body and trips
             # its embedding-catch-up rule.  Planting only W2's tokens (get_price_history /
             # AI-SIGNIFICANCE SCREEN) made this assertion UNFAILABLE: W5's _check_absent patterns are
             # sp_embed_pending / get_account_(...) / the repair-or-drift alternation, none of which
             # either W2 token can match, and W2 is unreachable from a section appended after W5.
             # Verified both directions after this change: boundary intact -> check() == []; boundary
             # removed -> ['W5: forbidden overlap reappeared — embedding catch-up or live account
             # repair'] (2026-09-04 quality pass).  The two W2 tokens are KEPT alongside it -- M2 is
             # matched by no rule, so they cost nothing and preserve the original intent.
             "Use get_price_history, call sp_embed_pending, and an AI-SIGNIFICANCE SCREEN.\n")
    assert crs.check(text) == []


def test_final_weekly_section_stops_before_next_cadence_group():
    text = _plan()
    text += "\n# MONTHLY\nA shared note may call sp_embed_pending without becoming W5 scope.\n"
    assert crs.check(text) == []


def test_fenced_heading_shaped_example_does_not_split_the_active_prompt():
    text = _plan({
        "W2": (
            "W2 consumes D1 events.decision_log research-screen records. Use event identity and skip an "
            "already queued or decided thesis in events.queue_events.\n"
            "```text\n## W3. Fake — regular routine\nRun get_price_history.\n```\n"
        )
    })
    sections = crs.routine_sections(text)
    assert "W3" in sections and "Run get_price_history." in sections["W2"]


# ---- routine_sections(): a heading-SHAPED aside inside a body must not become a new boundary ------
# BUG FIX (finding routine-scope-duplicate-heading-detector). check_routine_scope.py used to
# identify a routine-section boundary with its OWN, independently maintained regex
# (``ROUTINE_HEADING = re.compile(r"^##\s+([A-Za-z0-9_]+)\.\s")``), which accepted ANY
# "## <token>. " line as a new routine start -- coded routine heading or not. The canonical
# detector (scripts/split_task_plan.py's own is_routine(), built on scripts/lib/routine_manifest.py's
# ROUTINE_SUFFIX) additionally requires the heading END with its "— (deep research|regular routine)"
# type tag before it counts as a routine boundary. Without that extra requirement, a heading-SHAPED
# line sitting inside some OTHER routine's own body -- a numbered aside like "## 3. See the note
# below" -- satisfied the old, looser test and was misread as a NEW routine boundary: it truncated
# the real routine's section right there and silently reassigned everything after it to a bogus id no
# _check_present/_check_absent rule names. Whatever forbidden- or required-pattern text landed after
# the accidental heading dropped out of every ownership-boundary rule's view with no error reported --
# defeating the whole point of this script. Reproduced below against W4's forbidden
# create_order_instruction/ORDER_STAGED overlap rule, the same class of guard the module docstring
# cites as the reason this check exists.
#
# This fixture is a hand-written literal, not built from _plan() above: routine_sections() keeps its
# own narrow boundary-walking loop instead of delegating wholesale to scripts/split_task_plan.split()
# (see routine_sections()'s own docstring in scripts/check_routine_scope.py) because split() requires
# a `# ` cadence-group header before the first routine and raises ValueError without one -- and every
# fixture in this file, including _plan()'s output, is deliberately a bare "## <ID>. ... — regular
# routine" heading with no such group header.
PLAN_WITH_NUMBERED_ASIDE = (
    "## D1. Example — regular routine\n"
    "D1 uses regular-session daily bars. Route a qualifying mover to Strategy B as a B candidate.\n"
    "\n"
    "## W4. Example — regular routine\n"
    "Route weekly findings to D2 via idempotent PENDING_ANALYSIS queue items.\n"
    "\n"
    "## 3. A numbered illustrative aside, not a routine heading\n"
    "W4 calls create_order_instruction then writes ORDER_STAGED.\n"
)


def test_numbered_aside_inside_a_routine_body_is_not_a_new_boundary():
    """routine_sections() must not carve a heading-shaped numbered aside (no routine-suffix type
    tag) out of the routine whose body it sits in.  Under the old ROUTINE_HEADING regex, "## 3. A
    numbered illustrative aside..." matched (any "## <token>. " shape counted), producing a bogus
    "3" section and truncating W4's real body right before the forbidden text."""
    sections = crs.routine_sections(PLAN_WITH_NUMBERED_ASIDE)
    assert "3" not in sections
    assert "create_order_instruction" in sections["W4"]
    assert "ORDER_STAGED" in sections["W4"]


def test_numbered_aside_does_not_hide_a_forbidden_overlap_from_check():
    """End-to-end: the W4 forbidden-overlap rule must still see the violation that lands after the
    fake heading. Under the old, looser ROUTINE_HEADING regex this silently passed with ZERO
    errors -- the exact silent-miss defect this fix closes -- because W4's body was truncated to
    end right before "## 3. ...", leaving the forbidden create_order_instruction/ORDER_STAGED text
    stranded inside a bogus "3" section that no ownership-boundary rule ever inspects."""
    errors = crs.check(PLAN_WITH_NUMBERED_ASIDE)
    assert any("W4: forbidden overlap reappeared — direct weekly exit crafting" in e for e in errors)


def test_w2_broad_rescan_and_price_pull_are_rejected():
    errors = crs.check(_plan({
        "W2": (
            "W2 consumes D1 events.decision_log research-screen records. Use event identity and skip an "
            "already queued thesis in events.queue_events. W2 logs an entry_type post-event-enrichment provenance record, "
            "not a second significance screen. Screen all US-listed equities in the prior 10 trading days with "
            "get_price_history, including an uncovered-tail scan.\n"
        )
    }))
    assert any("W2: forbidden overlap reappeared — market-wide post-event re-scan" in e for e in errors)
    assert any("W2: forbidden overlap reappeared — direct price-bar pull" in e for e in errors)


def test_w2_must_keep_durable_provenance_and_idempotency():
    errors = crs.check(_plan({"W2": "W2 reads D1 notes and adds candidates.\n"}))
    assert any("D1 durable research-screen records" in e for e in errors)
    assert any("idempotent exclusion of already-identified events" in e for e in errors)


def test_w2_must_log_distinct_enrichment_provenance_not_a_second_screen():
    errors = crs.check(_plan({
        "W2": (
            "W2 consumes D1 events.decision_log research-screen records. Use event identity and skip an "
            "already queued thesis in events.queue_events.\n"
        )
    }))
    assert any("distinct post-event-enrichment provenance record" in e for e in errors)


def test_w3_requires_mechanical_exit_boundary():
    errors = crs.check(_plan({"W3": "W3 covers narrative drift and cumulative evidence.\n"}))
    assert any("W3: missing ownership boundary — D1 ownership" in e for e in errors)


def test_w4_rejects_direct_exit_staging_and_requires_d2_handoff():
    errors = crs.check(_plan({
        "W4": "W4 calls create_order_instruction then writes ORDER_STAGED.\n"
    }))
    assert any("W4: missing ownership boundary — idempotent PENDING_ANALYSIS handoff to D2" in e for e in errors)
    assert any("W4: forbidden overlap reappeared — direct weekly exit crafting" in e for e in errors)


def test_explicit_prohibitions_do_not_count_as_active_overlap():
    plan = _plan({
        "W4": (
            "W4 does not call create_order_instruction or write ORDER_STAGED. Route weekly findings to D2 "
            "via idempotent PENDING_ANALYSIS queue items.\n"
        ),
        "W5": "W5 reports trend-only analytics without sp_embed_pending or live account repair.\n",
    })
    assert crs.check(plan) == []


def test_w5_rejects_embedding_and_live_account_repair():
    errors = crs.check(_plan({
        "W5": "W5 reports a trend and calls sp_embed_pending, then raises an account drift alert.\n"
    }))
    assert any("W5: forbidden overlap reappeared — embedding catch-up" in e for e in errors)


def test_w1_must_reuse_daily_catalysts():
    errors = crs.check(_plan({"W1": "W1 builds a future catalyst calendar.\n"}))
    assert any("W1: missing ownership boundary — reuse of D1-originated catalysts" in e for e in errors)


# ---- negation scoping: a contrastive conjunction ends a prohibition's reach --------------------
def test_negation_does_not_mask_a_later_contrasting_clause_on_the_same_line():
    """REGRESSION (quality pass 2026-08-22). _has_active_match() scoped its negation search to the
    WHOLE physical line prefix, so ANY unrelated earlier negation on that line silently masked a
    real, active forbidden action later in it.

    Here 'does not skip validation' has nothing to do with the 'but calls create_order_instruction'
    clause that follows, yet it suppressed the W4 forbidden-overlap error entirely — the exact
    anti-pattern that rule exists to catch (a future edit quietly restoring a second order-staging
    path). The negation's scope now ends at the contrastive conjunction."""
    errors = crs.check(_plan({
        "W4": ("W4 does not skip validation, but calls create_order_instruction directly for a "
               "fast-track exit. Route weekly findings to D2 via idempotent PENDING_ANALYSIS "
               "queue items.\n"),
    }))
    assert any("W4: forbidden overlap reappeared — direct weekly exit crafting" in e for e in errors)


def test_negation_still_governs_a_coordinated_list_across_commas():
    """The other half of the contract, and the reason commas are NOT treated as scope-enders. The
    plan's normal way of writing a prohibition is one negation governing a comma-separated list —
    W5 really says '...but do not diagnose a live discrepancy, raise an operational drift alert, or
    attempt a repair'. Scoping the negation to the nearest comma was measured and rejected: it cut
    the governing 'do not' off the later items and failed live main on a correct safety sentence."""
    plan = _plan({
        "W5": ("W5 summarizes reconciliation history for trend context, but does not diagnose a "
               "live discrepancy, raise an operational drift alert, or attempt a repair.\n"),
    })
    assert crs.check(plan) == []


def test_w5_permits_its_own_decision_vocab_drift_alert():
    """The W5 forbid pattern's trailing alternation is domain-qualified. A bare `drift` matched any
    drift at all, including W5's own legitimate decision-vocabulary alert — knowledge/analytics
    work, which is W5's actual job, not the 'live account repair' the rule forbids. That over-match
    was inert only because the loose negation scope above happened to mask it; tightening the
    negation exposed it as a CI failure on live main."""
    plan = _plan({
        "W5": ("W5 reports trends. Instead of updating rows, call "
               "ops.sp_raise_alert('info','W5','decision_vocab_drift', ...) so the drift is "
               "recorded for review.\n"),
    })
    assert crs.check(plan) == []


def test_w5_still_rejects_an_active_operational_drift_alert():
    """...and the tightening must not weaken the gate: an account-domain drift alert raised
    ACTIVELY (no governing negation) is still a forbidden overlap."""
    errors = crs.check(_plan({
        "W5": "W5 reports a trend, then raises an operational drift alert for the reconciliation.\n"
    }))
    assert any("W5: forbidden overlap reappeared — embedding catch-up" in e for e in errors)


def test_premortem_owner_with_a_walk_step_passes():
    plan = _plan({"M4": "M4 runs I. PRE-MORTEM OWNER-ASSIGNED CHECK WALK each cycle.\n"})
    premortem = "Review trigger: audit the record. **Owner: M4 (Monthly Action Conversion)**\n"
    assert crs.check_premortem_consumers(plan, premortem) == []


def test_premortem_owner_without_a_walk_step_fails():
    plan = _plan({"M4": "M4 converts M1b/M2/M3 outputs into actions.\n"})
    premortem = "Review trigger: audit the record. **Owner: M4 (Monthly Action Conversion)**\n"
    errors = crs.check_premortem_consumers(plan, premortem)
    assert any("carries no 'PRE-MORTEM OWNER-ASSIGNED CHECK WALK' step" in e for e in errors)


def test_premortem_owner_naming_a_nonexistent_routine_fails():
    premortem = "Review trigger: audit the record. **Owner: Z9**\n"
    errors = crs.check_premortem_consumers(_plan(), premortem)
    assert any("no such routine section exists" in e for e in errors)


def test_walk_step_without_any_assignment_fails():
    plan = _plan({"M4": "M4 runs I. PRE-MORTEM OWNER-ASSIGNED CHECK WALK each cycle.\n"})
    errors = crs.check_premortem_consumers(plan, "No owner is named anywhere here.\n")
    assert any("assigns it no `Owner: M4` locus" in e for e in errors)


def test_human_owner_and_surface_owner_are_not_routine_assignments():
    premortem = (
        "manually verified by Owner: the participant against both code paths.\n"
        "OWNER: Claude_Task_Plan.md (nearest owning routine: W5)\n"
    )
    assert crs.premortem_owner_routines(premortem) == set()


def test_contractual_owners_need_no_declared_walk_step():
    premortem = "**Owner: AR_orc** adjudicates this by queue contract.\n"
    assert crs.check_premortem_consumers(_plan(), premortem) == []
