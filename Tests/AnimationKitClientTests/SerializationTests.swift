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
        let anim = Animation(
            duration: 1.5,
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
        let clip = AnimationClip(duration: 1.0)
        let composite = Animation.sequence {
            Animation.clip(clip)
            Animation(duration: 1.0)
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
        let animation = Components.Schemas.Animation(
            duration: 1.0,
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
        let anim = Animation(duration: 2.0)
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
