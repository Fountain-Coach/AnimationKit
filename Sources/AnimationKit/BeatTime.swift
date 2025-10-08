import Foundation

/// Represents a point in musical time measured in beats.
public struct BeatTime: Sendable, Equatable, Codable {
    /// Beat value relative to the configured beat offset.
    public var value: Double

    /// Creates a new beat time.
    public init(_ value: Double) {
        self.value = value
    }

    /// Zero beats.
    public static let zero = BeatTime(0)
}

/// Describes the tempo used to convert beats to wall-clock time.
public struct Tempo: Sendable, Equatable, Codable {
    /// Beats per minute; must be greater than zero.
    public var beatsPerMinute: Double

    /// Creates a tempo definition.
    public init(beatsPerMinute: Double) {
        precondition(beatsPerMinute > 0, "Tempo must be positive")
        self.beatsPerMinute = beatsPerMinute
    }

    /// Converts beats to seconds.
    public func seconds(forBeats beats: Double) -> TimeInterval {
        (beats * 60.0) / beatsPerMinute
    }

    /// Converts seconds to beats.
    public func beats(forSeconds seconds: TimeInterval) -> Double {
        seconds * beatsPerMinute / 60.0
    }
}

/// Configuration describing how beats map to absolute time.
public struct BeatTimeModel: Sendable, Equatable, Codable {
    /// Tempo used for beat conversion.
    public var tempo: Tempo
    /// Beat value that corresponds to the configured wall-time offset.
    public var beatOffset: Double
    /// Wall-clock offset in seconds.
    public var wallTimeOffset: TimeInterval
    /// Feature flag toggling experimental MIDI 2.0 clock synchronisation.
    public var enableMIDI2Clock: Bool

    /// Creates a new time model.
    public init(
        tempo: Tempo,
        beatOffset: Double = 0,
        wallTimeOffset: TimeInterval = 0,
        enableMIDI2Clock: Bool = false
    ) {
        self.tempo = tempo
        self.beatOffset = beatOffset
        self.wallTimeOffset = wallTimeOffset
        self.enableMIDI2Clock = enableMIDI2Clock
    }

    /// Converts beats to an absolute time interval.
    public func seconds(for beat: BeatTime) -> TimeInterval {
        wallTimeOffset + tempo.seconds(forBeats: beat.value - beatOffset)
    }

    /// Converts an absolute time interval back to beats.
    public func beat(forSeconds seconds: TimeInterval) -> BeatTime {
        let deltaSeconds = seconds - wallTimeOffset
        let beats = tempo.beats(forSeconds: deltaSeconds) + beatOffset
        return BeatTime(beats)
    }
}

/// A keyframe expressed in beats.
public struct BeatKeyframe: Sendable, Equatable, Codable {
    /// Beat position of the keyframe.
    public let beat: Double
    /// Target value at the keyframe.
    public let value: Double
    /// Easing curve used when interpolating to the next keyframe.
    public let easing: Easing

    /// Creates a beat keyframe.
    public init(beat: Double, value: Double, easing: Easing = .linear) {
        self.beat = beat
        self.value = value
        self.easing = easing
    }
}

/// A timeline defined using beat-based keyframes.
public struct BeatTimeline: Sendable, Equatable, Codable {
    /// Keyframes sorted by ascending beat.
    public var keyframes: [BeatKeyframe]

    /// Creates a beat timeline.
    public init(_ keyframes: [BeatKeyframe] = []) {
        self.keyframes = keyframes.sorted { $0.beat < $1.beat }
    }

    /// Evaluates the timeline at the provided beat time.
    public func value(at beat: BeatTime) -> Double {
        guard let first = keyframes.first else { return 0 }
        if beat.value <= first.beat { return first.value }
        guard let last = keyframes.last else { return 0 }
        if beat.value >= last.beat { return last.value }
        var previous = first
        for keyframe in keyframes.dropFirst() {
            if beat.value <= keyframe.beat {
                let span = keyframe.beat - previous.beat
                if span <= 0 { return keyframe.value }
                let localT = (beat.value - previous.beat) / span
                return previous.easing.interpolate(from: previous.value, to: keyframe.value, t: localT)
            }
            previous = keyframe
        }
        return last.value
    }

    /// Converts the beat timeline into a wall-time timeline using the provided model.
    public func asTimeline(using model: BeatTimeModel) -> Timeline {
        Timeline(
            keyframes.map { keyframe in
                Keyframe(
                    time: model.seconds(for: BeatTime(keyframe.beat)),
                    value: keyframe.value,
                    easing: keyframe.easing
                )
            }
        )
    }
}

public extension Timeline {
    /// Creates a wall-time timeline from a beat timeline and time model.
    init(beatTimeline: BeatTimeline, model: BeatTimeModel) {
        self = beatTimeline.asTimeline(using: model)
    }
}

public extension AnimationClip {
    /// Evaluates the clip using beat-based timing.
    func state(at beat: BeatTime, using model: BeatTimeModel) -> ParameterState {
        state(at: model.seconds(for: beat))
    }
}

public extension Animation {
    /// Evaluates the animation tree using beat-based timing.
    func state(at beat: BeatTime, using model: BeatTimeModel) -> ParameterState {
        state(at: model.seconds(for: beat))
    }
}
