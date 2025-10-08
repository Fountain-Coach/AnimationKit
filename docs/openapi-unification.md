# OpenAPI Unification Audit

## Status Quo Audit

- **Historical divergence**: Commit `cc18d050` introduced a detailed root-level `openapi.yaml` that was never wired into the build after the SwiftPM scaffold landed in `459ef0b9`. Subsequent client-centric commits (`d2a6ae1`, `9436eca`, `41419df`, `f86ace3`, `adc3cf60`) evolved `Sources/AnimationKitClient/openapi.yaml` without touching the root document, leaving two incompatible specifications in the tree.
- **Observed drift**: The root document used OpenAPI 3.1 syntax plus documentation annotations (`contentReference[...]`) that made it invalid for the Apple generator, while the client used a lean OpenAPI 3.0.3 contract that matched the façade implementation. Code generation and tests were therefore bound to the in-target spec, with the root file acting as stale documentation only.
- **Impact**: Developers consulting the root spec designed against unsupported endpoints (timeline OTIO import/export, MIDI 2.0 payloads) and schema shapes that the façade neither generated nor serialized, creating confusion for DSL and transport workstreams.

## Refactoring Actions

1. **Reassert the root spec as source of truth**: The canonical OpenAPI contract continues to live at the repository root (`openapi.yaml`) and retains the historical MIDI timeline surface in addition to the animation/evaluation endpoints the client already supports.
2. **Wire the build to the canonical file**: `Package.swift` copies the root spec into the client target so the Swift OpenAPI Generator consumes the shared document during builds.
3. **Remove the duplicate**: `Sources/AnimationKitClient/openapi.yaml` remains deleted to prevent silent drift; only the generator config lives beside the façade code.
4. **Normalize schema shapes**: The root specification was rewritten to OpenAPI 3.0.3 syntax so the Apple generator accepts it, while serialization helpers were adjusted for non-optional timelines/easing consistent with the DSL.
5. **Document the workflow**: `AGENTS.md`, the generator config comment, and this audit record the expectation that all schema updates happen in the root document followed by `swift build` to refresh generated sources.

## Milestone Alignment

- `docs/RELEASE_PLAN.md` under “Milestone 1 — Core Platform Hardening” now tracks OpenAPI unification as a completed task so roadmap consumers understand the new baseline.
- `docs/STATUS.md` highlights that the client and DSL now share a single schema, closing the previous gap between documentation and implementation.

## Next Steps

- Use `swift build` or `swift test` after every schema change to ensure the generator validates the document.
- Extend milestone tracking if future features (e.g., OTIO import/export) graduate from design notes into the canonical spec; the build will fail fast if unsupported YAML constructs reappear.
- Consider adding automated linting (e.g., `openapi-format` or generator dry runs) in Milestone 3 to guard against regressions once CI is in place.
