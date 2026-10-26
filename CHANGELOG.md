# AIMF Changelog

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
