import Foundation

/// A two-dimensional position composed of independent x and y timelines.
public struct PositionTimeline: Sendable, Equatable, Codable {
    /// Timeline controlling the horizontal axis.
    public var x: Timeline
    /// Timeline controlling the vertical axis.
    public var y: Timeline

    /// Creates a position timeline from horizontal and vertical tracks.
    public init(x: Timeline, y: Timeline) {
        self.x = x
        self.y = y
    }
}

/// A color timeline with optional per-channel tracks.
public struct ColorTimeline: Sendable, Equatable, Codable {
    /// Optional red channel timeline.
    public var r: Timeline?
    /// Optional green channel timeline.
    public var g: Timeline?
    /// Optional blue channel timeline.
    public var b: Timeline?
    /// Optional alpha channel timeline.
    public var a: Timeline?

    /// Creates a color timeline with optional per-channel tracks.
    public init(r: Timeline? = nil, g: Timeline? = nil, b: Timeline? = nil, a: Timeline? = nil) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

/// A primitive animation clip describing parameter timelines over a fixed duration.
public struct AnimationClip: Sendable, Equatable, Codable {
    /// Total length of the clip in seconds.
    public var duration: TimeInterval
    /// Optional midi2 automation timeline controlling parameters in beats.
    public var midiTimeline: Midi2Timeline?
    /// Optional opacity track.
    public var opacity: Timeline?
    /// Optional position track.
    public var position: PositionTimeline?
    /// Optional scale track.
    public var scale: Timeline?
    /// Optional rotation track.
    public var rotation: Timeline?
    /// Optional color track.
    public var color: ColorTimeline?

    /// Creates an animation clip with optional parameter timelines.
    public init(
        duration: TimeInterval,
        midiTimeline: Midi2Timeline? = nil,
        opacity: Timeline? = nil,
        position: PositionTimeline? = nil,
        scale: Timeline? = nil,
        rotation: Timeline? = nil,
        color: ColorTimeline? = nil
    ) {
        let midiDuration = midiTimeline?.duration ?? 0
        self.duration = max(duration, midiDuration)
        self.midiTimeline = midiTimeline
        self.opacity = opacity
        self.position = position
        self.scale = scale
        self.rotation = rotation
        self.color = color
    }

    /// Creates an animation clip whose duration is derived from the midi timeline.
    public init(
        midiTimeline: Midi2Timeline,
        opacity: Timeline? = nil,
        position: PositionTimeline? = nil,
        scale: Timeline? = nil,
        rotation: Timeline? = nil,
        color: ColorTimeline? = nil
    ) {
        self.init(
            duration: midiTimeline.duration,
            midiTimeline: midiTimeline,
            opacity: opacity,
            position: position,
            scale: scale,
            rotation: rotation,
            color: color
        )
    }

    /// Evaluates the clip state at absolute time `t` (seconds).
    public func state(at t: TimeInterval) -> ParameterState {
        let clamped = max(0, min(duration, t))
        var state = ParameterState()
        if let midiTimeline {
            state.merge(with: midiTimeline.state(at: clamped))
        }
        if let opacity {
            state.opacity = opacity.value(at: clamped)
        }
        if let position {
            state.position = PositionState(
                x: position.x.value(at: clamped),
                y: position.y.value(at: clamped)
            )
        }
        if let scale {
            state.scale = scale.value(at: clamped)
        }
        if let rotation {
            state.rotation = rotation.value(at: clamped)
        }
        if let color {
            var base = state.color ?? RGBA(r: 0, g: 0, b: 0, a: 1)
            if let r = color.r { base = base.setting(r: r.value(at: clamped)) }
            if let g = color.g { base = base.setting(g: g.value(at: clamped)) }
            if let b = color.b { base = base.setting(b: b.value(at: clamped)) }
            if let a = color.a { base = base.setting(a: a.value(at: clamped)) }
            state.color = base
        }
        return state
    }
}

/// An animation group that evaluates its members concurrently.
public struct AnimationGroup: Sendable, Equatable, Codable {
    /// Member animations that render together.
    public var members: [Animation]

    /// Creates a new animation group.
    public init(_ members: [Animation]) {
        self.members = members
    }

    /// Maximum duration across all members.
    public var duration: TimeInterval {
        members.map { $0.duration }.max() ?? 0
    }

    /// Evaluates all members at the same absolute time and merges the resulting state.
    public func state(at t: TimeInterval) -> ParameterState {
        members.reduce(into: ParameterState()) { state, animation in
            let local = min(t, animation.duration)
            state.merge(with: animation.state(at: local))
        }
    }
}

/// An animation sequence that plays child animations one after another.
public struct AnimationSequence: Sendable, Equatable, Codable {
    /// Ordered child animations.
    public var steps: [Animation]

    /// Creates a new animation sequence.
    public init(_ steps: [Animation]) {
        self.steps = steps
    }

    /// Total duration of the sequence.
    public var duration: TimeInterval {
        steps.reduce(0) { $0 + $1.duration }
    }

    /// Evaluates the sequence at absolute time `t`, accounting for offsets.
    public func state(at t: TimeInterval) -> ParameterState {
        guard !steps.isEmpty else { return ParameterState() }
        var elapsed: TimeInterval = 0
        for animation in steps {
            let next = elapsed + animation.duration
            if t < next || animation.duration == 0 {
                let local = max(0, min(animation.duration, t - elapsed))
                return animation.state(at: local)
            }
            elapsed = next
        }
        // If t exceeds total duration, clamp to the final step.
        if let last = steps.last {
            return last.state(at: last.duration)
        }
        return ParameterState()
    }
}

/// High-level animation representation supporting clips, groups, and sequences.
public enum Animation: Sendable, Equatable, Codable {
    /// A primitive clip.
    case clip(AnimationClip)
    /// A concurrent group of animations.
    case group(AnimationGroup)
    /// A sequential collection of animations.
    case sequence(AnimationSequence)

    /// Total duration of the animation tree.
    public var duration: TimeInterval {
        switch self {
        case let .clip(clip):
            return clip.duration
        case let .group(group):
            return group.duration
        case let .sequence(sequence):
            return sequence.duration
        }
    }

    /// Evaluates the animation tree at time `t` (seconds).
    public func state(at t: TimeInterval) -> ParameterState {
        switch self {
        case let .clip(clip):
            return clip.state(at: t)
        case let .group(group):
            return group.state(at: t)
        case let .sequence(sequence):
            return sequence.state(at: t)
        }
    }

    /// Returns the underlying clip if the animation is primitive.
    public var clip: AnimationClip? {
        if case let .clip(clip) = self {
            return clip
        }
        return nil
    }

    /// Convenience initializer for creating a primitive clip inline.
    public init(
        duration: TimeInterval,
        midiTimeline: Midi2Timeline? = nil,
        opacity: Timeline? = nil,
        position: PositionTimeline? = nil,
        scale: Timeline? = nil,
        rotation: Timeline? = nil,
        color: ColorTimeline? = nil
    ) {
        self = .clip(
            AnimationClip(
                duration: duration,
                midiTimeline: midiTimeline,
                opacity: opacity,
                position: position,
                scale: scale,
                rotation: rotation,
                color: color
            )
        )
    }

    /// Convenience initializer for creating a primitive clip backed by a midi timeline.
    public init(
        midiTimeline: Midi2Timeline,
        opacity: Timeline? = nil,
        position: PositionTimeline? = nil,
        scale: Timeline? = nil,
        rotation: Timeline? = nil,
        color: ColorTimeline? = nil
    ) {
        self = .clip(
            AnimationClip(
                midiTimeline: midiTimeline,
                opacity: opacity,
                position: position,
                scale: scale,
                rotation: rotation,
                color: color
            )
        )
    }

    /// Creates a group animation from builder content.
    public static func group(@AnimationBuilder _ content: () -> [Animation]) -> Animation {
        .group(AnimationGroup(content()))
    }

    /// Creates a sequence animation from builder content.
    public static func sequence(@AnimationBuilder _ content: () -> [Animation]) -> Animation {
        .sequence(AnimationSequence(content()))
    }

    /// Returns the opacity track when the animation is a primitive clip.
    public var opacity: Timeline? { clip?.opacity }
    /// Returns the position track when the animation is a primitive clip.
    public var position: PositionTimeline? { clip?.position }
    /// Returns the scale track when the animation is a primitive clip.
    public var scale: Timeline? { clip?.scale }
    /// Returns the rotation track when the animation is a primitive clip.
    public var rotation: Timeline? { clip?.rotation }
    /// Returns the color track when the animation is a primitive clip.
    public var color: ColorTimeline? { clip?.color }
}

/// Result-builder used by the DSL to compose animation trees.
@resultBuilder
public enum AnimationBuilder {
    /// Produces the collected animations for the builder context.
    public static func buildBlock(_ components: Animation...) -> [Animation] { components }

    public static func buildArray(_ components: [[Animation]]) -> [Animation] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Animation]?) -> [Animation] {
        component ?? []
    }

    public static func buildEither(first component: [Animation]) -> [Animation] { component }

    public static func buildEither(second component: [Animation]) -> [Animation] { component }
}
