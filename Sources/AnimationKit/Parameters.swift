import Foundation

/// RGBA color in sRGB space.
public struct RGBA: Sendable, Equatable, Codable {
    /// Red channel intensity in the range [0, 1].
    public var r: Double
    /// Green channel intensity in the range [0, 1].
    public var g: Double
    /// Blue channel intensity in the range [0, 1].
    public var b: Double
    /// Alpha channel value in the range [0, 1].
    public var a: Double

    /// Creates a new color.
    public init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

/// Declarative animation parameters for common properties.
public enum Parameter: Sendable, Equatable, Codable {
    /// Absolute opacity.
    case opacity(Double)
    /// Absolute position.
    case position(x: Double, y: Double)
    /// Absolute scale multiplier.
    case scale(Double)
    /// Absolute rotation in radians.
    case rotation(Double)
    /// Absolute RGBA color.
    case color(RGBA)
}

/// A two-dimensional position state.
public struct PositionState: Sendable, Equatable {
    /// Horizontal component.
    public var x: Double
    /// Vertical component.
    public var y: Double

    /// Creates a new position state.
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// A computed state for parameters at a given time.
public struct ParameterState: Sendable, Equatable {
    /// Optional opacity component.
    public var opacity: Double?
    /// Optional position component.
    public var position: PositionState?
    /// Optional scale component.
    public var scale: Double?
    /// Optional rotation component.
    public var rotation: Double?
    /// Optional color component.
    public var color: RGBA?

    /// Creates an empty parameter state.
    public init(
        opacity: Double? = nil,
        position: PositionState? = nil,
        scale: Double? = nil,
        rotation: Double? = nil,
        color: RGBA? = nil
    ) {
        self.opacity = opacity
        self.position = position
        self.scale = scale
        self.rotation = rotation
        self.color = color
    }

    /// Mutates the state by overlaying non-nil values from `other`.
    public mutating func merge(with other: ParameterState) {
        if let value = other.opacity {
            opacity = value
        }
        if let value = other.position {
            position = value
        }
        if let value = other.scale {
            scale = value
        }
        if let value = other.rotation {
            rotation = value
        }
        if let value = other.color {
            color = value
        }
    }

    /// Returns a new state merging `self` with `other`.
    public func merging(with other: ParameterState) -> ParameterState {
        var copy = self
        copy.merge(with: other)
        return copy
    }
}

extension RGBA {
    func setting(r: Double? = nil, g: Double? = nil, b: Double? = nil, a: Double? = nil) -> RGBA {
        RGBA(r: r ?? self.r, g: g ?? self.g, b: b ?? self.b, a: a ?? self.a)
    }
}
