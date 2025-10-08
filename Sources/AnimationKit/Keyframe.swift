import Foundation

/// A scalar keyframe with an easing function.
public struct Keyframe: Sendable, Equatable, Codable {
    public let time: TimeInterval
    public let value: Double
    public let easing: Easing

    public init(time: TimeInterval, value: Double, easing: Easing = .linear) {
        self.time = time
        self.value = value
        self.easing = easing
    }
}

