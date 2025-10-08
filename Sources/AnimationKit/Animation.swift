import Foundation

/// A basic animation composed of parameter timelines.
public struct Animation: Sendable, Equatable, Codable {
    public var duration: TimeInterval
    public var opacity: Timeline?
    public var positionX: Timeline?
    public var positionY: Timeline?
    public var scale: Timeline?
    public var rotation: Timeline?
    public var colorR: Timeline?
    public var colorG: Timeline?
    public var colorB: Timeline?
    public var colorA: Timeline?

    public init(
        duration: TimeInterval,
        opacity: Timeline? = nil,
        positionX: Timeline? = nil,
        positionY: Timeline? = nil,
        scale: Timeline? = nil,
        rotation: Timeline? = nil,
        colorR: Timeline? = nil,
        colorG: Timeline? = nil,
        colorB: Timeline? = nil,
        colorA: Timeline? = nil
    ) {
        self.duration = duration
        self.opacity = opacity
        self.positionX = positionX
        self.positionY = positionY
        self.scale = scale
        self.rotation = rotation
        self.colorR = colorR
        self.colorG = colorG
        self.colorB = colorB
        self.colorA = colorA
    }

    /// Evaluates the animation state at absolute time `t`.
    public func state(at t: TimeInterval) -> ParameterState {
        var state = ParameterState()
        if let opacity {
            state.opacity = opacity.value(at: t)
        }
        if let positionX {
            let x = positionX.value(at: t)
            if let existing = state.position {
                state.position = (x: x, y: existing.y)
            } else {
                state.position = (x: x, y: 0)
            }
        }
        if let positionY {
            let y = positionY.value(at: t)
            if let existing = state.position {
                state.position = (x: existing.x, y: y)
            } else {
                state.position = (x: 0, y: y)
            }
        }
        if let scale { state.scale = scale.value(at: t) }
        if let rotation { state.rotation = rotation.value(at: t) }
        if let colorR { state.color = (state.color ?? RGBA(r: 0, g: 0, b: 0, a: 1)).setting(r: colorR.value(at: t)) }
        if let colorG { state.color = (state.color ?? RGBA(r: 0, g: 0, b: 0, a: 1)).setting(g: colorG.value(at: t)) }
        if let colorB { state.color = (state.color ?? RGBA(r: 0, g: 0, b: 0, a: 1)).setting(b: colorB.value(at: t)) }
        if let colorA { state.color = (state.color ?? RGBA(r: 0, g: 0, b: 0, a: 1)).setting(a: colorA.value(at: t)) }
        return state
    }
}

@resultBuilder
public enum AnimationBuilder {
    public static func buildBlock(_ components: Animation...) -> [Animation] { components }
}
