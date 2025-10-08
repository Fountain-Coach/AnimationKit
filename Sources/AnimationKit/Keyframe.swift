import Foundation

/// A scalar keyframe with an easing function.
public struct Keyframe: Sendable, Equatable, Codable {
    /// Absolute time in seconds.
    public let time: TimeInterval
    /// Target value at `time`.
    public let value: Double
    /// Easing curve used when interpolating to the next keyframe.
    public let easing: Easing

    public init(time: TimeInterval, value: Double, easing: Easing = .linear) {
        self.time = time
        self.value = value
        self.easing = easing
    }
}

