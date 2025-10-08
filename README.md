# AnimationKit

A Swift package for a declarative animation API used in Fountain Coach, backed by an OpenAPI‑driven client. The repository includes the OpenAPI specification (`openapi.yaml`) and design references to guide a “right way” implementation that is portable, testable, and clean.

Status: early scaffolding. See `AGENTS.md` for the full working plan and conventions.

## Supported Toolchains & Platforms
- Swift toolchain: Swift 6.0 toolset (builds with Swift 5.9+; validated against Swift 6.0 snapshots)
- Xcode: 15.3 or newer (16.x preferred)
- Platforms: macOS 13+, iOS 16+

## Goals
- Declarative animation DSL (compose, group, sequence, keyframes, easing)
- Beat-based time model with conversion to wall-clock seconds
- Clean separation between core DSL and transport (OpenAPI client)
- Generated client via Apple’s Swift OpenAPI plugin (as in Engraver)
- Solid tests and examples, reproducible builds, minimal global state

## Quick Start (dev)
1. Ensure recent Swift toolchain (Swift 6 toolset / 5.9+) or Xcode (15.3+, prefer 16).
2. Clone the repo and optionally clone references locally (ignored by git):
   ```bash
   git clone https://github.com/Fountain-Coach/AnimationKit.git
   cd AnimationKit
   mkdir -p references && cd references
   git clone https://github.com/Fountain-Coach/Engraver.git
   ```
3. Follow Engraver for the Apple OpenAPI plugin setup and file placement.
4. Build and test:
   ```bash
   swift build
   swift test
   ```

## Repository Structure (planned)
- `openapi.yaml` — API source of truth
- `Sources/AnimationKit/` — Declarative animation DSL and core types
- `Sources/AnimationKitClient/` — Handwritten façade over generated client
- `Tests/` — Unit and façade tests
- `docs/` — Additional docs and examples
- `references/` — Local cloned reference repos (ignored)

Generated sources from the OpenAPI plugin remain in the build directory and are not committed.

## Development Conventions
- Follow `AGENTS.md` for step‑by‑step implementation.
- Conventional Commits for commit messages.
- Keep PRs small and focused; prefer squash merges.
- Public API must be documented with concise `///` comments.

## References in this repo
- `Designing a Declarative Animation API for Fountain Coach.pdf`
- `AnimationKit OpenAPI Specification and Swift Package Scaffold.pdf`
- `Toward a Midi2‑Centric Animation Core for Fountain Coach – An Anti‑Thesis.pdf`
- `openapi.yaml`

These documents guide naming, DSL shape, and package/plugin structure. Use the Engraver repository as the working reference for Apple’s OpenAPI plugin configuration and file placement.

## License
TBD.

