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

        let schema = AnimationSerialization.toSchema(anim)
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
