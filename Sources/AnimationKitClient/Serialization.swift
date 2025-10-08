import Foundation
import AnimationKit

public enum AnimationSerialization {
    public static func toSchema(_ animation: AnimationKit.Animation) throws -> Components.Schemas.Animation {
        guard let clip = animation.clip else {
            throw AnimationSerializationError.unsupportedComposition
        }
        return toSchema(clip)
    }

    public static func toSchema(_ clip: AnimationKit.AnimationClip) -> Components.Schemas.Animation {
        .init(
            duration: clip.duration,
            opacity: clip.opacity?.asGenerated(),
            position: clip.position?.asGenerated(),
            scale: clip.scale?.asGenerated(),
            rotation: clip.rotation?.asGenerated(),
            color: clip.color?.asGenerated()
        )
    }
}

public enum AnimationSerializationError: Error, Sendable {
    case unsupportedComposition
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
