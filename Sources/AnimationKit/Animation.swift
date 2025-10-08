import Foundation

/// A basic animation composed of parameter timelines.
public struct PositionTimeline: Sendable, Equatable, Codable {
    public var x: Timeline
    public var y: Timeline
    public init(x: Timeline, y: Timeline) { self.x = x; self.y = y }
}

public struct ColorTimeline: Sendable, Equatable, Codable {
    public var r: Timeline?
    public var g: Timeline?
    public var b: Timeline?
    public var a: Timeline?
    public init(r: Timeline? = nil, g: Timeline? = nil, b: Timeline? = nil, a: Timeline? = nil) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }
}

public struct Animation: Sendable, Equatable, Codable {
    public var duration: TimeInterval
    public var opacity: Timeline?
    public var position: PositionTimeline?
    public var scale: Timeline?
    public var rotation: Timeline?
    public var color: ColorTimeline?

    public init(
        duration: TimeInterval,
        opacity: Timeline? = nil,
        position: PositionTimeline? = nil,
        scale: Timeline? = nil,
        rotation: Timeline? = nil,
        color: ColorTimeline? = nil
    ) {
        self.duration = duration
        self.opacity = opacity
        self.position = position
        self.scale = scale
        self.rotation = rotation
        self.color = color
    }

    /// Evaluates the animation state at absolute time `t`.
    public func state(at t: TimeInterval) -> ParameterState {
        var state = ParameterState()
        if let opacity {
            state.opacity = opacity.value(at: t)
        }
        if let position {
            state.position = (x: position.x.value(at: t), y: position.y.value(at: t))
        }
        if let scale { state.scale = scale.value(at: t) }
        if let rotation { state.rotation = rotation.value(at: t) }
        if let color {
            var base = state.color ?? RGBA(r: 0, g: 0, b: 0, a: 1)
            if let r = color.r { base = base.setting(r: r.value(at: t)) }
            if let g = color.g { base = base.setting(g: g.value(at: t)) }
            if let b = color.b { base = base.setting(b: b.value(at: t)) }
            if let a = color.a { base = base.setting(a: a.value(at: t)) }
            state.color = base
        }
        return state
    }
}

@resultBuilder
public enum AnimationBuilder {
    public static func buildBlock(_ components: Animation...) -> [Animation] { components }
}
