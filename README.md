# AIMF — Andrew Inbound Message Format

A small, documented format for sending information **into** Andrew's assistant from outside — by a person, or by another AI acting for them. The format is the security: an allowlist, a strict schema, and a tiny vocabulary of message types. Nothing inbound is ever acted on outbound without Andrew's own approval.

**Start here:** the invite page — https://fourpshot.github.io/aimf-protocol/

- [`SPEC.md`](SPEC.md) — the full protocol (v1.7)
- [`trial-prompt.md`](trial-prompt.md) — one self-contained prompt that turns any AI chat into an AIMF counterparty for a trial
- [`test-vectors.md`](test-vectors.md) — standard valid/invalid sample messages with expected verdicts
- [`CHANGELOG.md`](CHANGELOG.md) — version history

Bots: read the raw files, e.g. `https://raw.githubusercontent.com/fourpshot/aimf-protocol/main/SPEC.md`.
