import Foundation
import AnimationKit

public enum AnimationSerialization {
    public static func toSchema(_ animation: AnimationKit.Animation) -> Components.Schemas.Animation {
        .init(
            duration: animation.duration,
            opacity: animation.opacity?.asGenerated(),
            position: animation.position?.asGenerated(),
            scale: animation.scale?.asGenerated(),
            rotation: animation.rotation?.asGenerated(),
            color: animation.color?.asGenerated()
        )
    }
}

extension AnimationKit.Easing {
    func asGenerated() -> Components.Schemas.Easing {
        switch self {
        case .linear: return .linear
        case .easeIn: return .easeIn
        case .easeOut: return .easeOut
        case .easeInOut: return .easeInOut
        }
    }
}

extension AnimationKit.Keyframe {
    func asGenerated() -> Components.Schemas.Keyframe {
        .init(time: time, value: value, easing: easing.asGenerated())
    }
}

extension AnimationKit.Timeline {
    func asGenerated() -> Components.Schemas.Timeline {
        .init(keyframes: keyframes.map { $0.asGenerated() })
    }
}

extension AnimationKit.PositionTimeline {
    func asGenerated() -> Components.Schemas.Position {
        .init(x: x.asGenerated(), y: y.asGenerated())
    }
}

extension AnimationKit.ColorTimeline {
    func asGenerated() -> Components.Schemas.Color {
        .init(
            r: r?.asGenerated(),
            g: g?.asGenerated(),
            b: b?.asGenerated(),
            a: a?.asGenerated()
        )
    }
}
