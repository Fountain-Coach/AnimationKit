# AnimationKit — Developer Notes

This package contains:
- `AnimationKit`: a minimal declarative animation DSL (timelines, keyframes, easing).
- `AnimationKitClient`: a thin façade over a generated OpenAPI client (Apple plugin).

OpenAPI code is generated at build time via the `swift-openapi-generator` plugin.
Generated sources remain ephemeral under `.build/`. Only handwritten code is committed.

## Local Development

Commands
- `swift build`
- `swift test`

References live in `references/` and are ignored. See `references/Engraving` for the canonical plugin setup.

