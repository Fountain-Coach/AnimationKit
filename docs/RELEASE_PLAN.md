# AnimationKit — v1.0 Release Plan

This plan captures the remaining work required to ship AnimationKit 1.0. It reflects the current repository state after the MIDI-aware timing refactor and client transport expansion, and it focuses on making the existing functionality shippable.

## Current Snapshot (2025-10-08)
- DSL supports clips, groups, and sequences with deterministic evaluation and builder conveniences.
- Beat-based timing flows from the DSL through MIDI automation timelines and into the client transport.
- The OpenAPI-backed client façade surfaces health, evaluation, submission, listing, retrieval, and update endpoints with typed errors, retries, and monitoring hooks.
- Cross-platform CI (macOS 14 + Linux/Swift 6) runs build and test jobs on every push and pull request.

## Completed Milestones
- [x] **Foundation scaffold** — SwiftPM manifest, Apple Swift OpenAPI generator plugin integration, and deterministic DSL primitives.
- [x] **Transport + MIDI integration** — Unified `openapi.yaml`, façade serialization layer, MIDI automation timelines, and coverage tests for request/response bridging.
- [x] **Baseline CI** — macOS and Linux workflows that build and test the package using Swift 6 toolchains.

## Milestone 3 — Quality Gates & Tooling *(In Progress)*
- [ ] **Broaden test coverage and reporting**
  - Deliverable: Code coverage reports for DSL compositions and client serialization (including MIDI timelines and retry paths) with thresholds enforced in CI.
  - Success criteria: CI fails when coverage drops below agreed limits; documentation describes how to run coverage locally.
- [ ] **Introduce lint/format and static analysis checks**
  - Deliverable: `swiftformat`/`swiftlint` (or equivalent) configuration committed with CI enforcement and contributor instructions.
  - Success criteria: CI blocks non-conforming code; contributing docs updated with tooling usage.
- [ ] **Automate doc health**
  - Deliverable: DocC (or swift-docc-plugin) build step validating public API docs, plus a checklist for adding new API documentation.
  - Success criteria: CI job produces doc build artifacts or fails when documentation is incomplete.

## Milestone 4 — Developer Experience & Documentation
- [ ] **Publish runnable examples**
  - Deliverable: Populated `examples/` directory with at least two scenarios (timeline evaluation and client submission) accompanied by README walkthroughs.
  - Success criteria: Examples compile and run with documented commands from a clean checkout.
- [ ] **Refresh quick-start and onboarding docs**
  - Deliverable: Updated root and docs READMEs covering toolchains, generation workflow, and integration guidance.
  - Success criteria: Instructions verified in a clean environment; STATUS report references the new onboarding flow.
- [ ] **Author migration and troubleshooting guides**
  - Deliverable: `docs/MIGRATION_GUIDE.md` for pre-1.0 adopters and a troubleshooting appendix for common generator/runtime issues.
  - Success criteria: Guides referenced from README and release notes; internal reviewers sign off.

## Milestone 5 — Release Candidate & Publication
- [ ] **Create release checklist and dry run**
  - Deliverable: `docs/RELEASE_CHECKLIST.md` capturing clean-build validation, generator output audit, and artifact packaging steps.
  - Success criteria: Checklist executed once on a clean machine with outcomes recorded.
- [ ] **Finalize semantic versioning and branching strategy**
  - Deliverable: Documented release process (tagging, branching, changelog updates) including automation scripts if any.
  - Success criteria: Approved by maintainers; aligns with CI and repository protections.
- [ ] **Cut v1.0.0 release**
  - Deliverable: Annotated Git tag, release notes summarizing milestones, and publication to intended distribution channels.
  - Success criteria: Release artifacts verified; documentation and changelog updated with final version details.

## Post-1.0 Backlog
- [ ] MIDI 2.0 clock synchronization beyond feature flag defaults (e.g., external clock sources, latency compensation).
- [ ] Transport support for grouped/sequenced animations or wall-time-only clips.
- [ ] Additional integrations (e.g., real-time streaming endpoints, editor plugins) as dictated by product roadmap.
