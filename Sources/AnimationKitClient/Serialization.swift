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

    public static func toSchema(_ draft: AnimationDraft) throws -> Components.Schemas.UpdateAnimationRequest {
        .init(
            animation: try toSchema(draft.animation),
            name: draft.name,
            tags: draft.tags.isEmpty ? nil : draft.tags
        )
    }

    public static func fromSchema(_ animation: Components.Schemas.Animation) throws -> AnimationKit.Animation {
        let clip = AnimationKit.AnimationClip(
            duration: animation.duration,
            opacity: try animation.opacity?.asTimeline(),
            position: try animation.position?.asTimeline(),
            scale: try animation.scale?.asTimeline(),
            rotation: try animation.rotation?.asTimeline(),
            color: try animation.color?.asTimeline()
        )
        return .clip(clip)
    }

    public static func fromSchema(_ summary: Components.Schemas.AnimationSummary) throws -> RemoteAnimationSummary {
        RemoteAnimationSummary(
            id: summary.id,
            name: summary.name,
            duration: summary.duration,
            updatedAt: summary.updatedAt
        )
    }

    public static func fromSchema(_ response: Components.Schemas.AnimationListResponse) throws -> AnimationPage {
        let summaries = try response.items.map { try fromSchema($0) }
        return AnimationPage(items: summaries, nextPageToken: response.nextPageToken)
    }

    public static func fromSchema(_ resource: Components.Schemas.AnimationResource) throws -> RemoteAnimation {
        RemoteAnimation(
            id: resource.id,
            animation: try fromSchema(resource.animation),
            name: resource.name,
            tags: resource.tags ?? [],
            createdAt: resource.createdAt,
            updatedAt: resource.updatedAt
        )
    }

    public static func makeBulkRequest(timeline: AnimationKit.Timeline, samples: [TimeInterval]) -> Components.Schemas.BulkEvaluationRequest {
        .init(
            timeline: timeline.asGenerated(),
            samples: samples
        )
    }

    public static func fromSchema(_ response: Components.Schemas.BulkEvaluationResponse) -> [EvaluationSample] {
        response.results.map { EvaluationSample(t: $0.t, value: $0.value) }
    }

}

public enum AnimationSerializationError: Error, Sendable {
    case unsupportedComposition
}

public struct AnimationDraft: Sendable, Equatable {
    public var animation: AnimationKit.Animation
    public var name: String?
    public var tags: [String]

    public init(animation: AnimationKit.Animation, name: String? = nil, tags: [String] = []) {
        self.animation = animation
        self.name = name
        self.tags = tags
    }
}

public struct RemoteAnimationSummary: Sendable, Equatable {
    public var id: String
    public var name: String?
    public var duration: TimeInterval
    public var updatedAt: Date?

    public init(id: String, name: String? = nil, duration: TimeInterval, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.duration = duration
        self.updatedAt = updatedAt
    }
}

public struct RemoteAnimation: Sendable, Equatable {
    public var id: String
    public var animation: AnimationKit.Animation
    public var name: String?
    public var tags: [String]
    public var createdAt: Date?
    public var updatedAt: Date?

    public init(
        id: String,
        animation: AnimationKit.Animation,
        name: String? = nil,
        tags: [String] = [],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.animation = animation
        self.name = name
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct AnimationPage: Sendable, Equatable {
    public var items: [RemoteAnimationSummary]
    public var nextPageToken: String?

    public init(items: [RemoteAnimationSummary], nextPageToken: String? = nil) {
        self.items = items
        self.nextPageToken = nextPageToken
    }
}

public struct EvaluationSample: Sendable, Equatable {
    public var t: TimeInterval
    public var value: Double

    public init(t: TimeInterval, value: Double) {
        self.t = t
        self.value = value
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

extension Components.Schemas.Timeline {
    func asTimeline() throws -> AnimationKit.Timeline {
        let frames = keyframes.map { $0.asKeyframe() }
        return AnimationKit.Timeline(frames)
    }
}

extension Components.Schemas.Keyframe {
    func asKeyframe() -> AnimationKit.Keyframe {
        AnimationKit.Keyframe(time: time, value: value, easing: easing.asEasing())
    }
}

extension Components.Schemas.Easing {
    func asEasing() -> AnimationKit.Easing {
        switch self {
        case .linear: return .linear
        case .easeIn: return .easeIn
        case .easeOut: return .easeOut
        case .easeInOut: return .easeInOut
        }
    }
}

extension Components.Schemas.Position {
    func asTimeline() throws -> AnimationKit.PositionTimeline {
        AnimationKit.PositionTimeline(x: try x.asTimeline(), y: try y.asTimeline())
    }
}

extension Components.Schemas.Color {
    func asTimeline() throws -> AnimationKit.ColorTimeline {
        AnimationKit.ColorTimeline(
            r: try r?.asTimeline(),
            g: try g?.asTimeline(),
            b: try b?.asTimeline(),
            a: try a?.asTimeline()
        )
    }
}
