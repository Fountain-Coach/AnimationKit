import Foundation

/// A basic animation composed of parameter timelines.
public struct Animation: Sendable, Equatable, Codable {
    public var duration: TimeInterval
    public var opacity: Timeline?
    // Future: position, scale, rotation, color tracks

    public init(duration: TimeInterval, opacity: Timeline? = nil) {
        self.duration = duration
        self.opacity = opacity
    }

    /// Evaluates the animation state at absolute time `t`.
    public func state(at t: TimeInterval) -> ParameterState {
        var state = ParameterState()
        if let opacity {
            state.opacity = opacity.value(at: t)
        }
        return state
    }
}

@resultBuilder
public enum AnimationBuilder {
    public static func buildBlock(_ components: Animation...) -> [Animation] { components }
}

