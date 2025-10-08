# AnimationKit — Stable v1.0 Task Plan

The following tasks translate the current repository status into an actionable plan for delivering the first stable release of AnimationKit. Tasks are grouped by milestone and written to be executable: each item has a clear deliverable, success criteria, and dependencies where relevant.

## Milestone 1 — Core Platform Hardening

- [x] **Audit SwiftPM scaffold against Engraver reference**
  - Confirm `Package.swift` includes the latest compatible `swift-openapi-generator` plugin version and aligned build settings.
  - Deliverable: Updated manifest if deltas exist; documented confirmation otherwise.
  - Result: Manifest now references `swift-openapi-generator` 1.10.3, `swift-openapi-runtime` 1.8.3, and `swift-openapi-urlsession` 1.2.0.
- [x] **Pin Swift toolchain and deployment targets**
  - Document supported Swift version (5.9+/Swift 6 readiness) and minimum platform versions in `README.md` and manifest.
  - Deliverable: Manifest deployment targets set; docs updated.
  - Result: README documents Swift 6 toolchain support alongside macOS 13+/iOS 16+ requirements.
- [x] **Stabilize DSL public API surface**
  - Review `Sources/AnimationKit` for naming consistency, doc comments, and access control.
  - Deliverable: Annotated public API documentation (`///`), breaking change log entry, and unit tests proving determinism.
  - Result: Public DSL types now carry doc comments, deterministic evaluation tests were added, and docs/CHANGELOG.md records the breaking change.
- [x] **Expand DSL coverage to groups and sequences**
  - Implement grouping and sequencing constructs per design notes, including evaluation tests for nested compositions.
  - Deliverable: New DSL types/functions with tests in `Tests/AnimationKitTests`.
  - Result: `Animation.clip/group/sequence`, `AnimationGroup`, and `AnimationSequence` power nested compositions with new unit coverage.
- [x] **Introduce beats-based time model**
  - Add beat-based timeline utilities with conversion to wall time; feature flagged for MIDI2 integration later.
  - Deliverable: Time model APIs, unit tests, and docs describing configuration.
  - Result: `BeatTimeModel`, `BeatTimeline`, and conversion tests were added with an opt-in MIDI 2.0 clock flag documented in STATUS/README files.

## Milestone 2 — Client Reliability & Transport Features

- [ ] **Define typed client errors and retry policy**
  - Create error enums and configurable retry/backoff strategy inside `AnimationKitClient` façade.
  - Deliverable: Error types, retry logic, configuration documentation, and client tests using mocks.
- [ ] **Enhance OpenAPI schema coverage**
  - Extend `openapi.yaml` with endpoints for animation retrieval/listing, updates, and bulk evaluation.
  - Deliverable: Updated schema, regenerated client outputs (build-only), façade adaptations, and new tests.
- [ ] **Add serialization bridging for new endpoints**
  - Implement codecs in `Serialization.swift` for newly modeled transport types.
  - Deliverable: Serialization utilities with snapshot or golden tests.
- [ ] **Implement health monitoring hooks**
  - Provide lightweight observability (metrics hooks or delegate callbacks) around client calls.
  - Deliverable: Protocols/types exposed publicly and exercised via unit tests.

## Milestone 3 — Quality Gates & Tooling

- [ ] **Strengthen unit and snapshot coverage**
  - Achieve targeted coverage for DSL evaluation and client serialization; add snapshot fixtures for complex animations.
  - Deliverable: Coverage report and CI step enforcing thresholds.
- [ ] **Set up linting and formatting**
  - Introduce `swiftformat`/`swiftlint` configurations, integrate into CI, and update contributing docs.
  - Deliverable: Config files, tooling scripts, CI job, and documentation.
- [ ] **Expand CI matrix**
  - Add Linux job (if platform support desired) and ensure macOS job pins Xcode 16.x.
  - Deliverable: Updated workflow under `.github/workflows/ci.yml` with green runs.
- [ ] **Automate documentation verification**
  - Add doc coverage check (DocC or swift-docc-plugin) ensuring public API is documented.
  - Deliverable: Doc build command in CI and pass criteria recorded in docs.

## Milestone 4 — Developer Experience & Examples

- [ ] **Publish comprehensive usage examples**
  - Build scenarios under `examples/` showing animation composition, evaluation, and client submission.
  - Deliverable: Example projects/scripts with README walkthroughs.
- [ ] **Create quick-start documentation**
  - Update `docs/README.md` with quick-start steps, including plugin usage and generation workflow.
  - Deliverable: Doc updates validated by a clean environment run-through.
- [ ] **Author migration guide for v1.0**
  - Document breaking changes, feature highlights, and upgrade steps from pre-release builds.
  - Deliverable: `docs/MIGRATION_GUIDE.md` covering DSL and client updates.

## Milestone 5 — Release Readiness

- [ ] **Finalize semantic versioning strategy**
  - Decide on tagging scheme, branching model, and release automation (GitHub Releases).
  - Deliverable: Documented release process in `docs/`.
- [ ] **Conduct release candidate hardening pass**
  - Run full build/test matrix, verify plugin generation from a clean checkout, and ensure no generated files leak into git.
  - Deliverable: Signed-off checklist stored in `docs/RELEASE_CHECKLIST.md`.
- [ ] **Tag and publish v1.0.0**
  - Create annotated tag, draft release notes summarizing milestones, and publish package metadata if required.
  - Deliverable: Git tag, release notes, and confirmation of distribution channels.

## Ongoing Governance

- [ ] **Maintain STATUS.md updates**
  - After each milestone, update `docs/STATUS.md` with latest accomplishments and open items.
  - Deliverable: Current status log aligned with repository state.
- [ ] **Track follow-up features (MIDI2 integration, etc.)**
  - Capture future work in backlog issues while keeping v1.0 scope focused.
  - Deliverable: Issue tracker entries referencing design notes.

