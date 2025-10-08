import XCTest
import AnimationKit
@testable import AnimationKitClient

final class SerializationTests: XCTestCase {
    func testAnimationToSchemaJSONSnapshot() throws {
        let opacity = Timeline([
            Keyframe(time: 0.0, value: 0.0, easing: .linear),
            Keyframe(time: 1.0, value: 1.0, easing: .easeIn)
        ])
        let posX = Timeline([
            Keyframe(time: 0.0, value: 10.0),
            Keyframe(time: 1.0, value: 20.0)
        ])
        let posY = Timeline([
            Keyframe(time: 0.0, value: 0.0),
            Keyframe(time: 1.0, value: 0.0)
        ])
        let colorR = Timeline([
            Keyframe(time: 0.0, value: 0.5)
        ])
        let midiTimeline = Midi2Timeline(
            timeModel: BeatTimeModel(tempo: Tempo(beatsPerMinute: 60)),
            tracks: [
                Midi2AutomationTrack(
                    channel: 0,
                    target: .opacity,
                    events: [
                        BeatKeyframe(beat: 0.0, value: 0.0, easing: .linear),
                        BeatKeyframe(beat: 1.0, value: 1.0, easing: .easeIn)
                    ]
                ),
                Midi2AutomationTrack(
                    channel: 1,
                    target: .positionX,
                    events: [
                        BeatKeyframe(beat: 0.0, value: 10.0),
                        BeatKeyframe(beat: 1.0, value: 20.0)
                    ]
                ),
                Midi2AutomationTrack(
                    channel: 1,
                    target: .positionY,
                    events: [
                        BeatKeyframe(beat: 0.0, value: 0.0),
                        BeatKeyframe(beat: 1.0, value: 0.0)
                    ]
                ),
                Midi2AutomationTrack(
                    channel: 2,
                    target: .colorR,
                    events: [
                        BeatKeyframe(beat: 0.0, value: 0.5)
                    ]
                )
            ]
        )
        let anim = Animation(
            duration: 1.5,
            midiTimeline: midiTimeline,
            opacity: opacity,
            position: PositionTimeline(x: posX, y: posY),
            color: ColorTimeline(r: colorR)
        )

        let schema = try AnimationSerialization.toSchema(anim)
        let data = try JSONEncoder.withSortedKeys.encode(schema)
        let json = String(data: data, encoding: .utf8)!

        // Build expected programmatically to keep it stable and readable.
        let expectedDict: [String: Any] = [
            "duration": 1.5,
            "midiTimeline": [
                "timeModel": [
                    "tempo": ["beatsPerMinute": 60.0],
                    "beatOffset": 0.0,
                    "wallTimeOffset": 0.0,
                    "enableMIDI2Clock": false
                ],
                "tracks": [
                    [
                        "channel": 0,
                        "target": "opacity",
                        "timeline": [
                            "keyframes": [
                                ["beat": 0.0, "value": 0.0, "easing": "linear"],
                                ["beat": 1.0, "value": 1.0, "easing": "easeIn"]
                            ]
                        ]
                    ],
                    [
                        "channel": 1,
                        "target": "positionX",
                        "timeline": [
                            "keyframes": [
                                ["beat": 0.0, "value": 10.0, "easing": "linear"],
                                ["beat": 1.0, "value": 20.0, "easing": "linear"]
                            ]
                        ]
                    ],
                    [
                        "channel": 1,
                        "target": "positionY",
                        "timeline": [
                            "keyframes": [
                                ["beat": 0.0, "value": 0.0, "easing": "linear"],
                                ["beat": 1.0, "value": 0.0, "easing": "linear"]
                            ]
                        ]
                    ],
                    [
                        "channel": 2,
                        "target": "colorR",
                        "timeline": [
                            "keyframes": [
                                ["beat": 0.0, "value": 0.5, "easing": "linear"]
                            ]
                        ]
                    ]
                ]
            ],
            "opacity": [
                "keyframes": [
                    ["time": 0.0, "value": 0.0, "easing": "linear"],
                    ["time": 1.0, "value": 1.0, "easing": "easeIn"],
                ]
            ],
            "position": [
                "x": [
                    "keyframes": [
                        ["time": 0.0, "value": 10.0, "easing": "linear"],
                        ["time": 1.0, "value": 20.0, "easing": "linear"],
                    ]
                ],
                "y": [
                    "keyframes": [
                        ["time": 0.0, "value": 0.0, "easing": "linear"],
                        ["time": 1.0, "value": 0.0, "easing": "linear"],
                    ]
                ]
            ],
            "color": [
                "r": [
                    "keyframes": [
                        ["time": 0.0, "value": 0.5, "easing": "linear"],
                    ]
                ]
            ]
        ]
        let expectedData = try JSONSerialization.data(withJSONObject: expectedDict, options: [.sortedKeys])
        let expectedJSON = String(data: expectedData, encoding: .utf8)!

        XCTAssertEqual(json, expectedJSON)
    }

    func testSerializationRejectsCompositeAnimations() {
        let clip = AnimationClip(
            duration: 1.0,
            midiTimeline: Midi2Timeline(
                timeModel: BeatTimeModel(tempo: Tempo(beatsPerMinute: 60)),
                tracks: []
            )
        )
        let composite = Animation.sequence {
            Animation.clip(clip)
            Animation(
                duration: 1.0,
                midiTimeline: Midi2Timeline(
                    timeModel: BeatTimeModel(tempo: Tempo(beatsPerMinute: 60)),
                    tracks: []
                )
            )
        }

        XCTAssertThrowsError(try AnimationSerialization.toSchema(composite)) { error in
            guard case AnimationSerializationError.unsupportedComposition = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testAnimationResourceDecoding() throws {
        let timeline = Components.Schemas.Timeline(keyframes: [
            .init(time: 0.0, value: 0.0, easing: .linear),
            .init(time: 1.0, value: 1.0, easing: .easeIn)
        ])
        let midiTimeline = Components.Schemas.Midi2Timeline(
            timeModel: .init(
                tempo: .init(beatsPerMinute: 60.0),
                beatOffset: 0,
                wallTimeOffset: 0,
                enableMIDI2Clock: false
            ),
            tracks: [
                .init(
                    channel: 0,
                    target: .opacity,
                    timeline: .init(keyframes: [
                        .init(beat: 0.0, value: 0.0, easing: .linear),
                        .init(beat: 1.0, value: 1.0, easing: .easeIn)
                    ])
                )
            ]
        )
        let animation = Components.Schemas.Animation(
            duration: 1.0,
            midiTimeline: midiTimeline,
            opacity: timeline
        )
        let updatedAt = Date(timeIntervalSince1970: 120)
        let resource = Components.Schemas.AnimationResource(
            id: "anim-1",
            animation: animation,
            name: "Example",
            tags: ["demo"],
            createdAt: nil,
            updatedAt: updatedAt
        )
        let decoded = try AnimationSerialization.fromSchema(resource)
        XCTAssertEqual(decoded.id, "anim-1")
        XCTAssertEqual(decoded.name, "Example")
        XCTAssertEqual(decoded.tags, ["demo"])
        XCTAssertEqual(decoded.animation.duration, 1.0)
        XCTAssertEqual(decoded.animation.clip?.opacity?.keyframes.count, 2)
        let updatedTime = try XCTUnwrap(decoded.updatedAt?.timeIntervalSince1970)
        XCTAssertEqual(updatedTime, 120, accuracy: 0.5)
    }

    func testAnimationSummaryDecoding() throws {
        let summary = Components.Schemas.AnimationSummary(
            id: "anim-2",
            name: "Another",
            duration: 2.0,
            updatedAt: Date(timeIntervalSince1970: 50)
        )
        let converted = try AnimationSerialization.fromSchema(summary)
        XCTAssertEqual(converted.id, "anim-2")
        XCTAssertEqual(converted.name, "Another")
        XCTAssertEqual(converted.duration, 2.0)
        let summaryTime = try XCTUnwrap(converted.updatedAt?.timeIntervalSince1970)
        XCTAssertEqual(summaryTime, 50, accuracy: 0.5)
    }

    func testDraftToUpdateRequest() throws {
        let anim = Animation(
            duration: 2.0,
            midiTimeline: Midi2Timeline(
                timeModel: BeatTimeModel(tempo: Tempo(beatsPerMinute: 60)),
                tracks: [
                    Midi2AutomationTrack(
                        target: .opacity,
                        events: [
                            BeatKeyframe(beat: 0.0, value: 0.0)
                        ]
                    )
                ]
            )
        )
        let draft = AnimationDraft(animation: anim, name: "Updated", tags: ["tag"])
        let request = try AnimationSerialization.toSchema(draft)
        XCTAssertEqual(request.name, "Updated")
        XCTAssertEqual(request.tags, ["tag"])
        XCTAssertEqual(request.animation.duration, 2.0)
    }

    func testBulkEvaluationRequestFactory() {
        let timeline = Timeline([
            Keyframe(time: 0.0, value: 0.0),
            Keyframe(time: 1.0, value: 1.0)
        ])
        let request = AnimationSerialization.makeBulkRequest(timeline: timeline, samples: [0.0, 0.5, 1.0])
        XCTAssertEqual(request.samples, [0.0, 0.5, 1.0])
        XCTAssertEqual(request.timeline.keyframes.count, 2)
    }
}

private extension JSONEncoder {
    static var withSortedKeys: JSONEncoder {
        let enc = JSONEncoder()
        if #available(macOS 10.15, iOS 13.0, *) {
            enc.outputFormatting.insert(.sortedKeys)
        }
        return enc
    }
}
