# AnimationKit — Status Report

- Timestamp (UTC): 2025-10-08T15:03:42Z
- Branch: main
- HEAD: f86ace3

## Summary
- SwiftPM package scaffolded with two targets: `AnimationKit` (DSL) and `AnimationKitClient` (OpenAPI façade).
- Apple Swift OpenAPI Generator wired via plugin on `AnimationKitClient` target; generated sources are ephemeral in `.build/`.
- Minimal OpenAPI defined with endpoints:
  - `GET /health` (health check)
  - `POST /evaluate` (evaluate scalar timeline at time)
  - `POST /animations` (submit animation; returns id)
- Declarative DSL implemented (deterministic evaluation):
  - Core types: `Easing`, `Keyframe`, `Timeline`
  - Aggregated tracks: `PositionTimeline`, `ColorTimeline`
  - `Animation` composes `opacity`, `position`, `scale`, `rotation`, `color`
- Façade client bridges DSL → transport types and calls generated client.
- Tests cover DSL evaluation, façade health/evaluate/submit, and JSON snapshot for serialized `Animation`.

## Structure
- Manifest: Package.swift:1
- Core DSL: Sources/AnimationKit/*
- Client façade: Sources/AnimationKitClient/ServiceClient.swift:1
- OpenAPI + plugin config:
  - Sources/AnimationKitClient/openapi.yaml:1
  - Sources/AnimationKitClient/openapi-generator-config.yaml:1
- Bridging: Sources/AnimationKitClient/Serialization.swift:1
- Tests:
  - Tests/AnimationKitTests/TimelineTests.swift:1
  - Tests/AnimationKitClientTests/ClientTests.swift:1
  - Tests/AnimationKitClientTests/SerializationTests.swift:1
- CI: .github/workflows/ci.yml:1 (macOS + Xcode 16.2; build and test)
- Docs: docs/README.md:1

## Decisions
- Follow Engraving (RulesKit-SPM) for plugin setup and OpenAPI placement.
- Keep generated code out of VCS; rely on reproducible build-time generation.
- Use aggregated types for clarity (`PositionTimeline`, `ColorTimeline`) over per-channel public API.
- Tests use URLProtocol for client façade; no live calls in CI.

## Open Items / Next Steps
- Extend DSL: groups/sequences, beats time model, optional MIDI2 hooks behind a flag.
- Façade: typed errors, retry/backoff policies, configuration surface.
- API: expand endpoints for retrieval/listing, patching, and bulk evaluation.
- Examples: add usage under `examples/` reflecting the aggregated API.
- CI: optional Linux job if we relax platform constraints; add doc coverage and lint if introduced.

## Housekeeping
- `references/` contains Engraving clone and is ignored.
- No generated sources committed; `.build/` ignored.
- Conventional commits used for history.

