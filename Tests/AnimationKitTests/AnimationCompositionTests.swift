import XCTest
@testable import AnimationKit

final class AnimationCompositionTests: XCTestCase {
    func testGroupMergesParameterStates() throws {
        let fadeInMidi = Midi2Timeline(
            timeModel: BeatTimeModel(tempo: Tempo(beatsPerMinute: 60)),
            tracks: [
                Midi2AutomationTrack(
                    target: .opacity,
                    events: [
                        BeatKeyframe(beat: 0.0, value: 0.0),
                        BeatKeyframe(beat: 1.0, value: 1.0)
                    ]
                )
            ]
        )
        let fadeIn = Animation(
            duration: 1.0,
            midiTimeline: fadeInMidi,
            opacity: Timeline([
                Keyframe(time: 0.0, value: 0.0),
                Keyframe(time: 1.0, value: 1.0)
            ])
        )

        let moveMidi = Midi2Timeline(
            timeModel: BeatTimeModel(tempo: Tempo(beatsPerMinute: 60)),
            tracks: [
                Midi2AutomationTrack(
                    target: .positionX,
                    events: [
                        BeatKeyframe(beat: 0.0, value: 0.0),
                        BeatKeyframe(beat: 1.0, value: 10.0)
                    ]
                ),
                Midi2AutomationTrack(
                    target: .positionY,
                    events: [
                        BeatKeyframe(beat: 0.0, value: 0.0),
                        BeatKeyframe(beat: 1.0, value: 5.0)
                    ]
                )
            ]
        )
        let move = Animation(
            duration: 1.0,
            midiTimeline: moveMidi,
            position: PositionTimeline(
                x: Timeline([
                    Keyframe(time: 0.0, value: 0.0),
                    Keyframe(time: 1.0, value: 10.0)
                ]),
                y: Timeline([
                    Keyframe(time: 0.0, value: 0.0),
                    Keyframe(time: 1.0, value: 5.0)
                ])
            )
        )

        let group = Animation.group {
            fadeIn
            move
        }

        let state = group.state(at: 0.5)
        let opacity = try XCTUnwrap(state.opacity)
        let position = try XCTUnwrap(state.position)
        XCTAssertEqual(opacity, 0.5, accuracy: 1e-9)
        XCTAssertEqual(position.x, 5.0, accuracy: 1e-9)
        XCTAssertEqual(position.y, 2.5, accuracy: 1e-9)
    }

    func testSequenceEvaluatesWithOffsets() throws {
        let fadeOutMidi = Midi2Timeline(
            timeModel: BeatTimeModel(tempo: Tempo(beatsPerMinute: 60)),
            tracks: [
                Midi2AutomationTrack(
                    target: .opacity,
                    events: [
                        BeatKeyframe(beat: 0.0, value: 1.0),
                        BeatKeyframe(beat: 1.0, value: 0.0)
                    ]
                )
            ]
        )
        let fadeOut = Animation(
            duration: 1.0,
            midiTimeline: fadeOutMidi,
            opacity: Timeline([
                Keyframe(time: 0.0, value: 1.0),
                Keyframe(time: 1.0, value: 0.0)
            ])
        )

        let scaleMidi = Midi2Timeline(
            timeModel: BeatTimeModel(tempo: Tempo(beatsPerMinute: 60)),
            tracks: [
                Midi2AutomationTrack(
                    target: .scale,
                    events: [
                        BeatKeyframe(beat: 0.0, value: 1.0),
                        BeatKeyframe(beat: 0.5, value: 2.0)
                    ]
                )
            ]
        )
        let scaleUp = Animation(
            duration: 0.5,
            midiTimeline: scaleMidi,
            scale: Timeline([
                Keyframe(time: 0.0, value: 1.0),
                Keyframe(time: 0.5, value: 2.0)
            ])
        )

        let sequence = Animation.sequence {
            fadeOut
            scaleUp
        }

        XCTAssertEqual(sequence.duration, 1.5, accuracy: 1e-9)

        let midFade = sequence.state(at: 0.5)
        let fadeOpacity = try XCTUnwrap(midFade.opacity)
        XCTAssertEqual(fadeOpacity, 0.5, accuracy: 1e-9)
        XCTAssertNil(midFade.scale)

        let midScale = sequence.state(at: 1.25)
        XCTAssertNil(midScale.opacity)
        let scale = try XCTUnwrap(midScale.scale)
        XCTAssertEqual(scale, 1.5, accuracy: 1e-9)
    }

    func testNestedCompositionsRemainDeterministic() {
        let clip = AnimationClip(
            duration: 1.0,
            midiTimeline: Midi2Timeline(
                timeModel: BeatTimeModel(tempo: Tempo(beatsPerMinute: 60)),
                tracks: [
                    Midi2AutomationTrack(
                        target: .opacity,
                        events: [
                            BeatKeyframe(beat: 0.0, value: 0.0),
                            BeatKeyframe(beat: 1.0, value: 1.0)
                        ]
                    )
                ]
            ),
            opacity: Timeline([
                Keyframe(time: 0.0, value: 0.0),
                Keyframe(time: 1.0, value: 1.0)
            ])
        )

        let nested = Animation.sequence {
            Animation.group {
                Animation.clip(clip)
            }
            Animation.group {
                Animation(
                    duration: 0.5,
                    midiTimeline: Midi2Timeline(
                        timeModel: BeatTimeModel(tempo: Tempo(beatsPerMinute: 60)),
                        tracks: [
                            Midi2AutomationTrack(
                                target: .rotation,
                                events: [
                                    BeatKeyframe(beat: 0.0, value: 0.0),
                                    BeatKeyframe(beat: 0.5, value: Double.pi)
                                ]
                            )
                        ]
                    ),
                    rotation: Timeline([
                        Keyframe(time: 0.0, value: 0.0),
                        Keyframe(time: 0.5, value: Double.pi)
                    ])
                )
            }
        }

        let firstState = nested.state(at: 0.75)
        let secondState = nested.state(at: 0.75)
        XCTAssertEqual(firstState, secondState)
    }
}
