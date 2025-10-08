import XCTest
@testable import AnimationKit

final class BeatTimeTests: XCTestCase {
    func testBeatTimelineConversion() {
        let beatTimeline = BeatTimeline([
            BeatKeyframe(beat: 0.0, value: 0.0),
            BeatKeyframe(beat: 2.0, value: 1.0)
        ])
        let model = BeatTimeModel(tempo: Tempo(beatsPerMinute: 120))

        let wallTimeline = beatTimeline.asTimeline(using: model)
        XCTAssertEqual(wallTimeline.keyframes.count, 2)
        XCTAssertEqual(wallTimeline.keyframes[1].time, 1.0, accuracy: 1e-9)
        XCTAssertEqual(wallTimeline.value(at: 0.5), 0.5, accuracy: 1e-9)
    }

    func testBeatTimeModelConversionRoundTrip() {
        let model = BeatTimeModel(
            tempo: Tempo(beatsPerMinute: 90),
            beatOffset: 1.0,
            wallTimeOffset: 0.5,
            enableMIDI2Clock: true
        )

        let beat = BeatTime(3.0)
        let seconds = model.seconds(for: beat)
        let roundTrip = model.beat(forSeconds: seconds)
        XCTAssertEqual(roundTrip.value, beat.value, accuracy: 1e-9)
        XCTAssertTrue(model.enableMIDI2Clock)
    }

    func testClipEvaluationUsingBeats() throws {
        let beatTimeline = BeatTimeline([
            BeatKeyframe(beat: 0.0, value: 0.0),
            BeatKeyframe(beat: 4.0, value: 1.0)
        ])
        let model = BeatTimeModel(tempo: Tempo(beatsPerMinute: 120))

        let clip = AnimationClip(
            duration: 2.0,
            midiTimeline: Midi2Timeline(
                timeModel: model,
                tracks: [
                    Midi2AutomationTrack(
                        target: .opacity,
                        events: [
                            BeatKeyframe(beat: 0.0, value: 0.0),
                            BeatKeyframe(beat: 4.0, value: 1.0)
                        ]
                    )
                ]
            ),
            opacity: Timeline(beatTimeline: beatTimeline, model: model)
        )

        let state = clip.state(at: BeatTime(2.0), using: model)
        let opacity = try XCTUnwrap(state.opacity)
        XCTAssertEqual(opacity, 0.5, accuracy: 1e-9)
    }

    func testMidiTimelineEvaluatesAgainstTimeModel() throws {
        let model = BeatTimeModel(tempo: Tempo(beatsPerMinute: 120))
        let timeline = Midi2Timeline(
            timeModel: model,
            tracks: [
                Midi2AutomationTrack(
                    target: .scale,
                    events: [
                        BeatKeyframe(beat: 0.0, value: 1.0),
                        BeatKeyframe(beat: 2.0, value: 3.0)
                    ]
                )
            ]
        )

        let beatState = timeline.state(at: BeatTime(1.0))
        let beatScale = try XCTUnwrap(beatState.scale)
        XCTAssertEqual(beatScale, 2.0, accuracy: 1e-9)

        let secondsState = timeline.state(at: 0.5)
        let secondsScale = try XCTUnwrap(secondsState.scale)
        XCTAssertEqual(secondsScale, 2.0, accuracy: 1e-9)

        XCTAssertEqual(timeline.duration, 1.0, accuracy: 1e-9)
    }
}
