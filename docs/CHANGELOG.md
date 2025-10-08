# AnimationKit — Changelog

## Unreleased

### Changed
- Replaced the `Animation` struct with an enum tree supporting clips, groups, and sequences while preserving a convenience initializer for primitive clips.
- Documented all public DSL entry points and added deterministic evaluation guarantees for compositions.
- Extended `openapi.yaml` with animation list/retrieve/update endpoints and bulk evaluation support.

### Added
- Introduced `AnimationClip`, `AnimationGroup`, and `AnimationSequence` types for structured compositions.
- Added beat-based timing utilities (`BeatTime`, `BeatTimeModel`, `BeatTimeline`) with optional MIDI 2.0 clock flagging.
- Extended test coverage for grouped/sequenced animations and beat-to-wall-time conversion.
- Added typed client errors, retry/backoff policy, monitoring hooks, and façade methods for listing, fetching, updating, and bulk-evaluating animations.
- Implemented serialization models (`AnimationDraft`, `RemoteAnimation`, `AnimationPage`, `EvaluationSample`) and reverse timeline codecs with snapshot-backed tests.

### Fixed
- Updated SwiftPM manifest to the latest Apple Swift OpenAPI packages to align with the Engraver reference scaffold.
