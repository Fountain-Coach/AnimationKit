**AnimationKit AGENTS — Working Instructions**

This file defines how to work in this repository end to end. Its scope is the entire repo. Follow it for code layout, style, generation, and housekeeping. The goal is to implement AnimationKit “the right way,” with a clean Swift Package, OpenAPI‑driven client generation, and a declarative animation API.

**TL;DR Plan**
- Establish SwiftPM package + targets
- Wire Apple Swift OpenAPI plugin via Engraver reference
- Generate client from `openapi.yaml`
- Build declarative Animation DSL + core types
- Add tests, examples, and CI
- Keep references local under `references/` (ignored)
- Use Conventional Commits and small PRs

**Repository Layout (planned)**
- `Package.swift` — SwiftPM manifest
- `Sources/AnimationKit/` — Core declarative animation API (DSL, types)
- `Sources/AnimationKitClient/` — OpenAPI client wrappers (handwritten façade)
- `Sources/` (generated, build-time) — Generated sources emitted by the OpenAPI plugin (not committed)
- `Tests/AnimationKitTests/` — Unit tests for DSL and core types
- `Tests/AnimationKitClientTests/` — Client façade tests with mocks
- `openapi.yaml` — API specification (source of truth, shared with generator)
- `docs/` — Developer docs, design notes, examples
- `references/` — Cloned reference repos (ignored)
- `examples/` — Minimal usage samples

Keep generated code ephemeral (plugin output lives in `.build/`). Only commit handwritten sources and configuration.

**Reference Material**
- `Designing a Declarative Animation API for Fountain Coach.pdf` — Use for naming and DSL feel.
- `AnimationKit OpenAPI Specification and Swift Package Scaffold.pdf` — Align structure, SPM layout, and plugin usage.
- `Toward a Midi2‑Centric Animation Core for Fountain Coach – An Anti‑Thesis.pdf` — Considerations for MIDI2 integration; treat as future phase.

**OpenAPI Generation (Apple plugin)**
- Use the Apple Swift OpenAPI Generator (the same setup as in the Engraver repo). Treat Engraver as the canonical reference for:
  - `Package.swift` dependency and plugin declaration
  - Where `openapi.yaml` lives
  - Any generator configuration file(s)

Steps:
1) Add dependency in `Package.swift` (version per Engraver):
   - `.package(url: "https://github.com/apple/swift-openapi-generator", from: "<version>")`
2) Attach plugin to the client target:
   - `.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")`
3) Ensure the plugin points to `openapi.yaml` (either default discovery or config file as Engraver does).
4) Build to generate sources into `.build/` and import them from the handwritten façade in `Sources/AnimationKitClient/`.

**OpenAPI Source of Truth**
- The only OpenAPI document in the repo is `openapi.yaml` at the repository root. The client target copies this file via `Package.swift`; do not add secondary `openapi.*` documents elsewhere.
- When updating the schema, edit the root file and run `swift build` to regenerate plugin outputs. Commit the handwritten façade changes only.
- Keep documentation, release plans, and tooling aligned with this single specification.

Do not check in generated sources unless explicitly required; prefer reproducible builds that generate at compile time.

**Module Responsibilities**
- `AnimationKit` (core)
  - Declarative DSL for composing animations (result builders ok)
  - Types: `Animation`, `Timeline`, `Keyframe`, `Easing`, `Parameter` (colors, transforms, opacity), groups and sequences
  - Time model: wall time and beats; later, MIDI2 clock hooks (behind feature flag)
  - Deterministic evaluation for testability
- `AnimationKitClient` (façade)
  - Thin, ergonomic wrapper over generated client
  - Request/response types that map to DSL primitives where sensible
  - Error typing and retries/backoff strategy where appropriate
  - No networking policy in core; configurable client

**Coding Conventions (Swift)**
- Swift 5.9+ / Swift 6 ready; enable concurrency features where beneficial
- Public API uses clear nouns and verbs; no abbreviations in public names
- Prefer `struct` over `class` unless reference semantics are required
- Use `Result` and typed errors; avoid `fatalError` in library code
- Document public symbols with `///` doc comments; keep examples brief
- Keep files short and cohesive; one main type per file
- Avoid global state; inject dependencies (e.g., clients, clocks)

**Tests**
- Unit tests for DSL composition, evaluation, and edge cases
- Snapshot/simple golden tests for emitted timelines
- Client façade tests use protocol‑based mocks; no live calls in CI
- Keep test names descriptive; arrange‑act‑assert structure

**CI (deferred)**
- GitHub Actions to run: build, unit tests, and (optionally) swiftformat/swiftlint if configured
- Cache SPM dependencies; run plugin generation as part of build

**Branching and Commits**
- Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `build:`, `ci:`
- Small, focused PRs that map to one change
- Keep `main` green; use feature branches and PRs; squash merge by default

**References Clone (housekeeping)**
- Clone external references locally under `references/` and keep them untracked:
  - `mkdir -p references && cd references`
  - `git clone https://github.com/Fountain-Coach/Engraver.git`
- Do not vendoring or submodule unless we explicitly decide so; this repo ignores `references/`.

**Environment & Tooling**
- Xcode 15.3+ (prefer 16) or Swift toolchain 5.9+
- macOS development target as per app consumers; library remains platform‑agnostic where possible
- Run locally: `swift build` / `swift test`

**Implementation Phases**
1) Scaffolding
   - Add `Package.swift`, targets, and plugin per Engraver
   - Build to validate codegen from `openapi.yaml`
2) Core DSL
   - Define minimal composable API and types
   - Add unit tests and examples
3) Client Façade
   - Wrap generated client in `AnimationKitClient`
   - Provide bridging from DSL to transport calls
4) Integrations
   - Optional MIDI2 hooks; feature flag; doc strategy
5) Polish
   - Documentation, examples, CI, and version tagging

**Housekeeping**
- Keep `references/`, `scratch/`, and local tooling artifacts out of git
- Do not commit generated code or build output
- Avoid large binary assets; if needed, use Git LFS after explicit approval

**Checklist Before Pushing**
- Build and test pass locally
- Public API documented
- Conventional commit message prepared
- No unintended files staged (especially generated/build outputs)

