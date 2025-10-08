import XCTest
@testable import AnimationKit

final class TimelineTests: XCTestCase {
    func testLinearInterpolation() {
        let tl = Timeline([
            Keyframe(time: 0.0, value: 0.0),
            Keyframe(time: 1.0, value: 1.0)
        ])
        XCTAssertEqual(tl.value(at: -0.1), 0.0)
        XCTAssertEqual(tl.value(at: 0.0), 0.0)
        XCTAssertEqual(tl.value(at: 1.0), 1.0)
        XCTAssertEqual(tl.value(at: 2.0), 1.0)
        XCTAssertEqual(tl.value(at: 0.5), 0.5, accuracy: 1e-9)
    }

    func testEaseInInterpolation() {
        let tl = Timeline([
            Keyframe(time: 0.0, value: 0.0, easing: .easeIn),
            Keyframe(time: 1.0, value: 1.0)
        ])
        let mid = tl.value(at: 0.5)
        XCTAssertLessThan(mid, 0.5) // easeIn should be below linear at midpoint
    }

    func testAnimationState() {
        let opacity = Timeline([
            Keyframe(time: 0.0, value: 0.0),
            Keyframe(time: 1.0, value: 1.0)
        ])
        let anim = Animation(duration: 1.0, opacity: opacity)
        XCTAssertEqual(anim.state(at: 0.0).opacity, 0.0)
        XCTAssertEqual(anim.state(at: 1.0).opacity, 1.0)
    }

    func testTimelineEvaluationIsDeterministic() {
        let tl = Timeline([
            Keyframe(time: 0.0, value: 0.0),
            Keyframe(time: 2.0, value: 2.0)
        ])

        let first = tl.value(at: 1.0)
        let second = tl.value(at: 1.0)
        XCTAssertEqual(first, second, accuracy: 1e-9)
    }
}

