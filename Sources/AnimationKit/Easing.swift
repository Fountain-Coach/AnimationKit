import Foundation

/// A simple easing enumeration for interpolations.
public enum Easing: Sendable, Equatable, Codable {
    case linear
    case easeIn
    case easeOut
    case easeInOut

    /// Interpolates between `a` and `b` at progress `t` in [0, 1].
    public func interpolate(from a: Double, to b: Double, t: Double) -> Double {
        let clamped = max(0, min(1, t))
        let eased: Double
        switch self {
        case .linear:
            eased = clamped
        case .easeIn:
            eased = clamped * clamped
        case .easeOut:
            eased = 1 - pow(1 - clamped, 2)
        case .easeInOut:
            if clamped < 0.5 {
                eased = 2 * clamped * clamped
            } else {
                let u = clamped - 0.5
                eased = 1 - 2 * (0.5 - u) * (0.5 - u)
            }
        }
        return a + (b - a) * eased
    }
}

