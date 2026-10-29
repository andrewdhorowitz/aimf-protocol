# AIMF — Andrew Inbound Message Format

[![CI](https://github.com/andrewdhorowitz/aimf-protocol/actions/workflows/ci.yml/badge.svg)](https://github.com/andrewdhorowitz/aimf-protocol/actions/workflows/ci.yml) [![Lighthouse](https://github.com/andrewdhorowitz/aimf-protocol/actions/workflows/lighthouse.yml/badge.svg)](https://github.com/andrewdhorowitz/aimf-protocol/actions/workflows/lighthouse.yml) [![Links](https://github.com/andrewdhorowitz/aimf-protocol/actions/workflows/links.yml/badge.svg)](https://github.com/andrewdhorowitz/aimf-protocol/actions/workflows/links.yml)

A small, documented format for sending information **into** Andrew's assistant from outside — by a person, or by another AI acting for them. The format is the security: an allowlist, a strict schema, and a tiny vocabulary of message types. Nothing inbound is ever acted on outbound without Andrew's own approval.

> **Published:** Site — https://aimf.andrewdhorowitz.com/ · Interactive — https://aimf.andrewdhorowitz.com/docs/interactive-architecture.html · Repo — https://github.com/andrewdhorowitz/aimf-protocol

**Start here:** the invite page — https://aimf.andrewdhorowitz.com/

- [`SPEC.md`](SPEC.md) — the full protocol (v1.9)
- [`trial-prompt.md`](trial-prompt.md) — one self-contained prompt that turns any AI chat into an AIMF counterparty for a trial
- [`test-vectors.md`](test-vectors.md) — standard valid/invalid sample messages with expected verdicts
- [`CHANGELOG.md`](CHANGELOG.md) — version history
- [`docs/architecture.md`](docs/architecture.md) — C4-lite architecture diagrams (System Context, Container, Deployment), with a generated interactive rendering beside it

Bots: read the raw files, e.g. `https://raw.githubusercontent.com/andrewdhorowitz/aimf-protocol/main/SPEC.md`.
