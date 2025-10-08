import Foundation

/// A timeline of scalar keyframes with deterministic evaluation.
public struct Timeline: Sendable, Equatable, Codable {
    public var keyframes: [Keyframe]

    public init(_ keyframes: [Keyframe] = []) {
        self.keyframes = keyframes.sorted { $0.time < $1.time }
    }

    /// Evaluates the timeline at absolute time `t` (seconds).
    public func value(at t: TimeInterval) -> Double {
        guard let first = keyframes.first else { return 0 }
        if t <= first.time { return first.value }
        guard let last = keyframes.last else { return 0 }
        if t >= last.time { return last.value }
        // Find the segment that contains `t`
        var prev = first
        for kf in keyframes.dropFirst() {
            if t <= kf.time {
                let span = kf.time - prev.time
                if span <= 0 { return kf.value }
                let localT = (t - prev.time) / span
                return prev.easing.interpolate(from: prev.value, to: kf.value, t: localT)
            }
            prev = kf
        }
        return last.value
    }
}

