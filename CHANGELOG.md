# AIMF Changelog

## v1.9 — 2026-10-26
- New canonical document: `update-prompt.md` — the standard nudge for a new version is a pointer prompt from the repository (SPEC §9.2). It carries no changes itself; a copy that differs from the repository copy is not genuine, and bots verify before running it.
- Onboarding now requires each side to declare its update-watching method (monitor or scheduled pull), recorded in the agreement (§8.2, §9.3, trial Step 2).

## v1.8 — 2026-10-26
- Monitor and update acknowledgement are now REQUIRED: SPEC §10 retitled (each side must run a monitor or an equivalent scheduled pull), §9.3 adds the monitor requirement and the update ack — a STATUS reply naming the new version and effective date, recorded against the agreement; missing acks are flagged "ack overdue," and a silent side may be paused.
- Trial prompt: MONITORING block is now a requirement (with the equivalent-pull fallback), and the updates block gained the UPDATE ACK duty.

## v1.7 — 2026-10-26
- The GitHub rule stated plainly (§9.1 + trial prompt): any change to the protocol or any of its documents, in any way, is made in the canonical GitHub repository — if it isn't on GitHub, it isn't an update.

## v1.6 — 2026-10-26
- Onboarding workflow (SPEC §7): the first test runs in simulation inside the chat; the bot then prompts its human for explicit permission before one real send test, validated for real by the receiving side's monitor and compared against the simulation.
- Trial prompt restructured as a workflow: 7 steps with approval gates — capability statement, draft agreement (stop), simulated first test, ask-first real email test, gate demonstration, proposal, summary.

## v1.5 — 2026-10-26
- Sender binding (SPEC §5.7): the envelope `from:` must be the transport-authenticated identity, or an alias recorded in the agreement's `transport_senders:` — otherwise the message fails the allowlist gate.
- Optional per-agreement auth (SPEC §5.8): `auth: secret` (shared code word) or `auth: hmac` for spoof resistance; secrets never appear in any document or registry.
- Monitoring (§10): agreement-expiry reminders (~7 days and ~1 day before) and a monitor heartbeat — silence is not health.
- Test vectors X8 (identity not bound to transport sender) and X9 (required auth missing/wrong) added.

## v1.4 — 2026-10-26
- Added SPEC §10 (monitoring the traffic): each side should run a report-only monitor (agent or scheduled job) over its own inbound transport — gate classification, watermark/seen-list bookkeeping, dedupe by transport ID and envelope id, attempt reporting, and version-verify checks where the agreement carries that feature. Trial prompt gained a matching MONITORING block; invite page gained a Monitoring section.

## v1.3 — 2026-10-26
- SPEC §9.2 all-surfaces rule: an update (including agreement approvals and amendments) posts only when the spec, trial prompt, changelog, and invite page (incl. agreement registry) are all updated in the same posting.
- First agreement registered: AGR-2026-10-26-001 (Andrew's Gemini bot, Level 1, v2 with the version-verify feature; expires 2026-11-25).

## v1.2 — 2026-10-26
- Canonical home named (SPEC §9.1): this repository, `fourpshot/aimf-protocol`; GitHub Pages site as the human front door; raw file links as the bot-readable copies. Expiring share links retired as addresses of record.
- Added test vectors (`test-vectors.md`) and the request-access first contact (SPEC §9.5).

## v1.1 — 2026-10-26
- Added SPEC §9: where protocol/API changes and documentation updates are posted, how they are announced (STATUS message with effective date), and how shared updates merge into the one canonical version.

## v1.0 — 2026-10-26
- Initial format: envelope, five message types (NOTE, FILE_DROP, REQUEST, STATUS, QUESTION), attachment limits, six hard rules.
- Added §8: capability statements, agreements, the intersection rule, proposal flow, trust ladder, expiry and unilateral revocation.
- Live self-test passed 2026-10-26 (NOTE validated end to end).
