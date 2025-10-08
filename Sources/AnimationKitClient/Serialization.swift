import Foundation
import AnimationKit

public enum AnimationSerialization {
    public static func toSchema(_ animation: AnimationKit.Animation) -> Components.Schemas.Animation {
        .init(
            duration: animation.duration,
            opacity: animation.opacity?.asGenerated(),
            positionX: animation.positionX?.asGenerated(),
            positionY: animation.positionY?.asGenerated(),
            scale: animation.scale?.asGenerated(),
            rotation: animation.rotation?.asGenerated(),
            colorR: animation.colorR?.asGenerated(),
            colorG: animation.colorG?.asGenerated(),
            colorB: animation.colorB?.asGenerated(),
            colorA: animation.colorA?.asGenerated()
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
