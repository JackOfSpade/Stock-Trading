# Strategy B Criterion-4 NO-GO Sub-Pattern Taxonomy — ARCHIVE

Low-traffic archive split out of `B_Sub_Pattern_Taxonomy.md` (DEF-2 working-file pruning, 2026-07-17)
so the active taxonomy stays scoped to definitions + routing-rules + benchmark instances + the
recent-cycle window. **`B_Sub_Pattern_Taxonomy.md` remains the canonical taxonomy**; this file holds
only its *pure-archive reference rows* — content read by the **W5 weekly tally** and **Q1
retrospectives**, and NEVER by thesis-construction sub-pattern routing (these are not sub-patterns;
do not route candidates against them).

**What lives here**: the Mechanical-Failure NO-GO reference table (mechanical-gate fails — criterion-1
magnitude / instrument-rule mcap-floor / event-verification / sector-cap — that never reached
criterion-4 sub-pattern extraction). Per the W5 maintenance rule mirrored in the active file: once
the active file exceeds 80KB, criterion-4 instances older than ~90 days are moved here too — but a
benchmark / “Cleanest-L1” instance is NEVER moved. As of the 2026-07-17 split no non-mechanical
instance is >90 days old, so only the Mechanical-Failure table was moved.

**Maintained by**: W5 (appends here when it archives rows). Not read by D2 / thesis-construction.

---

## Mechanical-Failure NO-GOs (Pure Archive Moves — Reference Only)

The following NO-GO archives in this cycle did NOT undergo sub-pattern extraction because they failed at the mechanical gate (criterion 1 close-to-close magnitude or instrument-rule mcap-floor) before reaching criterion 4. Listed here only for completeness; future thesis-construction sessions should NOT route candidates against these as sub-pattern matches (they're not sub-patterns).

| Ticker | Decision date | Mechanical failure | Archive pointer |
|--------|---------------|---------------------|------------------|
| EQIX | 2026-05-01 | Criterion 1 mechanical eligibility failure on close-to-close magnitude (premarket-vs-regular-session-close measurement artifact) | 2026-05-01 EQIX NO-GO → Decision_Log_Archive_2026_Q2.md |
| TDOC | 2026-05-01 | Instrument rule mechanical eligibility failure (mcap ~$1.07B vs $2B floor) | 2026-05-01 TDOC NO-GO → Decision_Log_Archive_2026_Q2.md |
| FIVN | 2026-05-02 | Instrument rule mechanical eligibility failure (mcap ~$1.65B vs $2B floor) | 2026-05-02 FIVN NO-GO → Decision_Log_Archive_2026_Q2.md |
| AXSM | 2026-05-02 | Criterion 1 mechanical eligibility failure on close-to-close magnitude (FDA-approval close-to-close +2.6% vs Daily.md-scan "+13%" premarket artifact) | 2026-05-02 AXSM NO-GO → Decision_Log_Archive_2026_Q2.md |
| DASH | 2026-05-11 | Criterion 1 magnitude gate fail (Daily.md "+9.6%" = Thu 5/7 intraday peak $183.50; actual Day-0 C/C +2.01% [$167.97→$171.35] < 5%; premarket / intraday-peak artifact — 3rd such after EQIX/AXSM; move fully unwound below baseline by Day-2) | events.decision_log 2026-05-11 DASH B NO-GO |
| DG | 2026-05-12 | Event-verification-gate fail (no qualifying B event in the 10-day window — FY26 guidance + CEO succession were 29-40+ trading days stale; the −7.64% Mon 5/11 move was a macro / sector retail sell-off [UMich 48.2 ATL, gas >$4 on Iran], outside B's enumerated event class; the live "sub-pattern 1" tag is stale). Same EVG class as CPRI 2026-06-03 | events.decision_log 2026-05-12 DG B NO-GO |
| MRNA | 2026-05-12 | Criterion 1 magnitude gate fail (prompt-anchored Mon 5/11 C/C −2.70% [$54.35→$52.88] < 5%; the asserted +7.5% / +9% was a premarket / intraday spike that "pared all gains"; even the corrected Fri-5/8 +11.97% anchoring fails criterion 3 [next earnings Jul 30 outside window] + criterion 4 [preclinical hantavirus pipeline]) | events.decision_log 2026-05-12 MRNA B NO-GO |
| AGL | 2026-05-14 | Instrument-rule mcap-floor fail (mcap $910.6M = 54.5% below the $2B floor; terminated at the criterion-1 instrument gate before any criteria 2-5 / sub-pattern routing). Same family as TDOC/FIVN/POET-2026-04-27 | events.decision_log 2026-05-14 AGL B NO-GO |
| BKE | 2026-05-29 | Portfolio-construction sector-cap gate fail (Consumer Discretionary book already 3/3 — TJX + AZO + BURL [BURL filled 5/29 @ ~$300.60] — so BKE would be the 4th; NO-GO at MANDATORY Step 2 before criteria 2-5; the beat-and-fade / SP6 thesis was never adjudicated; mcap $2.33B cleared). Sister to AEO 2026-05-30 (same cap) | events.decision_log 2026-05-29 BKE B NO-GO |
| PLAB | 2026-06-02 | Instrument-rule mechanical failure (mcap < $2B floor after a −36.4% Day-0 decline) | events.decision_log 2026-06-02 PLAB B NO-GO |
| ULTA | 2026-06-03 | Criterion 1 magnitude gate fail (Day-0 +1.33% < 5%) | events.decision_log 2026-06-03 ULTA B NO-GO |
| DG | 2026-06-03 | Criterion 1 magnitude gate fail (Day-0 −3.33% < 5%; intraday +5.8% faded to a down close) | events.decision_log 2026-06-03 DG B NO-GO |
| CRDO | 2026-06-03 | Criterion 1 magnitude gate fail (Day-0 +1.28% < 5%) | events.decision_log 2026-06-03 CRDO B NO-GO |
| CPRI | 2026-06-03 | Event-verification gate failure (no qualifying B event on 2026-06-03; the real Day-0 event was the 5/27 print — see SP6 CPRI 2026-06-04) | events.decision_log 2026-06-03 CPRI B NO-GO |
| CRWD | 2026-06-04 | Criterion 1 magnitude gate fail (Day-0 −3.81% < 5%; A-router gate cleared) | events.decision_log 2026-06-04 CRWD B NO-GO |
| OLLI | 2026-06-06 | Criterion 1 magnitude gate fail (qualifying earnings Day-0 close-to-close +0.62% < 5%; the −6.6% Day+1 was an analyst-downgrade move, not the earnings event) | events.decision_log 2026-06-06 OLLI B NO-GO |
| RH | 2026-06-13 | Criterion-1 magnitude gate fail (true Day-0 Fri 6/12 −3.94% < 5%; RH reported Thu 6/11 AMC, so the +7.15% on 6/11 was a pre-print rally, not the reaction; D1's "−5.8% / $149.95" was a stale-weekend-snapshot artifact — connector get_price_history authoritative). SP3 pre-print-rally + SP4 / Pattern-N housing-demand-overhang context recorded for any future qualifying RH event. | events.decision_log 2026-06-13 RH B NO-GO |
| ASML | 2026-07-27 | Terminal at the INSTRUMENT-ELIGIBILITY gate before criteria 1-5 were evaluated — no directional/sub-pattern work performed (`mechanical instrument-eligibility exclusion (not a sub-pattern; per B_Sub_Pattern_Taxonomy.md a pure archive move)`). Day-0 -5.80% C/C on a Chinese-domestic-DUV-mass-production report. ASML's only US listing is a "New York Registry Share" (registered Nasdaq share, fungible with the Euronext Amsterdam ordinary share, no ADR ratio) — the STRONGEST form of a permissive-reading test, and it still fails: Strategy B's instrument rule (`strategy/04_strategy_b.md`) reads verbatim "US-listed common equity" with NO ADR/registry-share carve-out; Strategy D's rule (`strategy/06_strategy_d.md`) has an EXPLICIT carve-out ("ADRs acceptable for large-cap foreign-domiciled companies") that both B and A (bare, matching rule) deliberately lack — an intentional asymmetry, not an oversight. Even ASML's NYRS structure runs through a JPMorgan Chase depositary-bank arrangement per ASML's own IR page, undercutting the distinction the permissive reading depended on. Controlling precedent: the W2 weekly post-event screen has repeatedly and explicitly excluded ADR-listed foreign issuers "per instrument rule" by name — TSM, NOK, SAP, NBIS (2026-W29/W30 self-checks) — and TSM specifically carries a standing unresolved Watchlist.md caveat, taken only via Strategy D. No B-thesis-construction session has EVER reached a foreign-domiciled ADR/registry-share name (filtered mechanically one stage earlier at W2), so there is no realized-outcome precedent base for this instrument class. Consistent with the AGL 2026-05-14 mcap-floor mechanical NO-GO. Not a deferral: nothing about ASML's listing structure changes inside the window (closes 2026-08-10); only an owner directive amending B's instrument rule, or ASML changing its US listing structure, would revisit it. The underlying DUV-competition question (genuine moat impairment vs. early-stage unproven competitive claim, ~5 Chinese units in 2026) is real and substantive but explicitly NOT analyzed this session — not pre-cleared for a future B thesis if the instrument rule ever changes. | events.decision_log 2026-07-27 ASML B NO-GO |
