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
    text += "\n## M2. Example — regular routine\nUse get_price_history and an AI-SIGNIFICANCE SCREEN.\n"
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
