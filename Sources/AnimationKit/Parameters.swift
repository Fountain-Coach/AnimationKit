import Foundation

/// RGBA color in sRGB space.
public struct RGBA: Sendable, Equatable, Codable {
    public var r: Double
    public var g: Double
    public var b: Double
    public var a: Double
    public init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }
}

/// Declarative animation parameters for common properties.
public enum Parameter: Sendable, Equatable, Codable {
    case opacity(Double)
    case position(x: Double, y: Double)
    case scale(Double)
    case rotation(Double)
    case color(RGBA)
}

/// A computed state for parameters at a given time.
public struct ParameterState: Sendable {
    public var opacity: Double?
    public var position: (x: Double, y: Double)?
    public var scale: Double?
    public var rotation: Double?
    public var color: RGBA?
}
