# OpenTimelineIO ?

Short answer:

* **Yes, you can implement OpenTimelineIO (OTIO) ↔︎ midi2 interoperability in pure Swift.**
* **No, there isn’t a first‑party Swift reference implementation** from the OTIO project today; the most pragmatic path is to implement a *focused, Codable OTIO subset* in Swift and write deterministic mappers to and from your **midi2/UMP** timeline model. That’s exactly how the AnimationKit spec and service were framed—OTIO is treated as an interchange format at the API edge, with conversion into a UMP‑timed, Engraver‑driven timeline in the core. 

Below is a concrete plan you can ship, plus code skeletons you can lift into your repo.

---

## 1) Scope: treat OTIO as an interchange, not a runtime

Your uploaded spec already positions OTIO as a bridge: **`POST /timelines/importOTIO`** to ingest OTIO JSON and **`GET /timelines/{id}/otio`** to export a native timeline back to OTIO; the runtime stays **UMP/midi2** (Engraver) for scheduling/playing. Keep that line: import/export at the edges, UMP inside. 

---

## 2) Data model: minimal OTIO in Swift

Implement a *minimal, Codable* subset of OTIO that’s sufficient for your use cases (timeline/stack/track/clip/gap/transition/marker, rational time/range, metadata). Example:

```swift
// OTIO core value types
public struct OTIORationalTime: Codable {
    public let value: Double
    public let rate: Double   // frames per second (or samples/sec)
}

public struct OTIOTimeRange: Codable {
    public let startTime: OTIORationalTime
    public let duration: OTIORationalTime
}

// Node base
public protocol OTIONode: Codable { var name: String? { get } }

public struct OTIOTimeline: OTIONode {
    public let name: String?
    public let tracks: OTIOStack
    public var metadata: [String: AnyCodable]?
}

public struct OTIOStack: OTIONode {
    public let name: String?
    public let children: [OTIOComposable]    // tracks or clips
}

public enum OTIOComposable: Codable {
    case track(OTIOTrack)
    case clip(OTIOClip)
    case gap(OTIOGap)
    case transition(OTIOTransition)
    // … add others as needed

    // implement Codable switch on a "OTIO_SCHEMA" discriminator if present
}

public struct OTIOTrack: OTIONode {
    public let name: String?
    public let kind: String? // "Video" | "Audio" | custom
    public let children: [OTIOComposable]    // clips/gaps/transitions
}

public struct OTIOClip: OTIONode {
    public let name: String?
    public let sourceRange: OTIOTimeRange?
    public var metadata: [String: AnyCodable]?
}

public struct OTIOGap: OTIONode {
    public let name: String?
    public let sourceRange: OTIOTimeRange?
}

public struct OTIOTransition: OTIONode {
    public let name: String?
    public let inOffset: OTIORationalTime
    public let outOffset: OTIORationalTime
    public var metadata: [String: AnyCodable]?
}

public struct OTIOMarker: Codable {
    public let name: String?
    public let markedRange: OTIOTimeRange
    public var metadata: [String: AnyCodable]?
}
```

> *Why not the full OTIO schema?* Because your service treats OTIO as an import/export format, not the live model. Start with the subset you actually need; extend as required.

---

## 3) Mapping OTIO ⟷ midi2/UMP (Engraver timeline)

Your native timeline is already defined as **UMP events with timestamps (seconds)**; this aligns cleanly with OTIO’s *RationalTime/rate* (convert to seconds). The uploaded spec explicitly models timelines as arrays of `{ time: Double, message: UmpPacket… }`. 

### 3.1 Import (OTIO → AnimationKit.Timeline)

Algorithm:

1. **Resolve timebase**

   * For each `OTIORationalTime(value v, rate r)`, compute seconds as `v / r`.
   * Optionally produce a **tempo map** if you want beats internally; otherwise keep seconds—your API already timestamps events in seconds while Engraver can still schedule via JR timestamps. 

2. **Track mapping**

   * Map each OTIO Track to a **MIDI Group (0–15) or channel (0–15)** (e.g., group = track index % 16, channel = track index / 16). Keep it stable so round‑trip is deterministic.

3. **Clip mapping**

   * Represent clip **start** as a UMP event at `clipStartSeconds` and **end** as a UMP event at `clipEndSeconds`.
   * Choose a message strategy:

     * **Note On/Off**: start = NoteOn, end = NoteOff; encode clip ID/name in *Flex Data* or Stream message near the NoteOn so semantics survive export.
     * **Flex Data (messageType 13)**: carry rich semantics (e.g., `{ "action":"clip", "name":"Intro", "id":"…", "kind":"Video" }`) in a 128‑bit packet series if you prefer metadata‑first.
   * For audio/video affinity, write `kind` into metadata and keep UMP as the timing rail.

4. **Transitions**

   * For crossfades or ramps, emit **Control Change** (0xB) sequences (linear ramp of a “mix” CC) spanning the overlap window, or a short series of Flex Data commands indicating the fade curve parameters.

5. **Markers**

   * Emit a zero‑length Flex Data/Stream message at `markerTime` with marker metadata.

6. **Assemble**

   * Produce `Timeline{ id, name, events:[UmpEvent(time:…, message:…)] }`.

Sketch:

```swift
public struct Timeline { public var id: String; public var events: [UmpEvent]; /* … */ }

public func importOTIO(_ otio: OTIOTimeline, defaultGroup: Int = 0) throws -> Timeline {
    var evs: [UmpEvent] = []
    for (tIndex, tNode) in otio.tracks.children.enumerated() {
        guard case .track(let track) = tNode else { continue }
        let (group, channel) = (tIndex % 16, (tIndex / 16) % 16)

        for child in track.children {
            switch child {
            case .clip(let clip):
                let start = seconds(clip.sourceRange?.startTime ?? .init(value: 0, rate: 1))
                let dur   = seconds(clip.sourceRange?.duration ?? .init(value: 0, rate: 1))
                let end   = start + dur

                evs.append(.flexData(time: start, group: group, payload: .clipStart(name: clip.name, meta: clip.metadata)))
                evs.append(.flexData(time: end,   group: group, payload: .clipEnd(name: clip.name)))

                // Optional: add NoteOn/Off guard rails for engines that prefer notes:
                evs.append(.noteOn(time: start, group: group, channel: channel, note: 60, vel16: 0x7FFF))
                evs.append(.noteOff(time: end,   group: group, channel: channel, note: 60, vel16: 0))
            case .transition(let tr):
                let s = seconds(tr.inOffset) // overlap start offset relative to previous
                let e = seconds(tr.outOffset)
                evs += ccRamp(group: group, channel: channel, from: 0, to: 127, startTime: s, endTime: e, cc: 1) // "mix" CC
            default: break
            }
        }
    }
    evs.sort{ $0.time < $1.time }
    return Timeline(id: UUID().uuidString, events: evs)
}
```

> The point is not which exact MIDI message you choose, but that **all temporal facts become UMP on one clock**, as your spec recommends (OTIO is just an import/export view). 

### 3.2 Export (AnimationKit.Timeline → OTIO)

Algorithm:

1. **Group events into tracks** by `(group, channel)` to form OTIO Tracks.
2. **Reconstruct clips** by pairing `clipStart`/`clipEnd` Flex Data (or NoteOn/NoteOff of a designated note) into OTIO `Clip` nodes with `sourceRange`.
3. **Recreate transitions** by detecting CC ramps or dedicated Flex Data transition messages.
4. **Emit markers** from zero‑length metadata events.
5. **Choose an OTIO rate** (e.g., 30.0 fps) and convert seconds → rational time `value = seconds * rate`.

Sketch:

```swift
public func exportOTIO(_ timeline: Timeline, rate: Double = 30.0) -> OTIOTimeline {
    let tracksByKey = Dictionary(grouping: timeline.events, by: { ($0.group, $0.channel) })
    var tracks: [OTIOComposable] = []

    for ((group, _), events) in tracksByKey {
        var children: [OTIOComposable] = []
        // pair up clipStart/clipEnd
        for pair in findClipPairs(in: events) {
            let range = OTIOTimeRange(
                startTime: .init(value: pair.start * rate, rate: rate),
                duration:  .init(value: (pair.end - pair.start) * rate, rate: rate)
            )
            children.append(.clip(OTIOClip(name: pair.name, sourceRange: range, metadata: pair.meta)))
        }
        // transitions and markers likewise…
        tracks.append(.track(OTIOTrack(name: "Group \(group)", kind: "Fountain", children: children)))
    }

    return OTIOTimeline(
        name: timeline.id,
        tracks: OTIOStack(name: "root", children: tracks),
        metadata: ["OTIO_SCHEMA": AnyCodable("Timeline.1")]
    )
}
```

---

## 4) How this plugs into your service

Your **AnimationKit** API already specifies the OTIO endpoints and the UMP timeline schema; the server is SwiftNIO‑based, and persistence is Fountain‑Store. Implement the two bridges above behind:

* `POST /timelines/importOTIO` → parse OTIO JSON (`Codable`), call `importOTIO`, persist the resulting UMP timeline, return `201`.
* `GET /timelines/{id}/otio` → load UMP timeline, call `exportOTIO`, return OTIO JSON.

Those endpoints and the UMP event structure are laid out in the spec you uploaded. 

---

## 5) Message choices (recommended defaults)

| OTIO concept   | UMP choice                                                           | Notes                                                                                                                  |
| -------------- | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Track          | **Group** (0–15) and **Channel** (0–15)                              | Deterministic mapping from track index keeps round‑trips stable.                                                       |
| Clip start/end | **Flex Data** semantic events; optionally guard with **Note On/Off** | Flex Data carries structured metadata (name/id/kind). Notes give simple on/off for engines.                            |
| Transition     | **CC** ramp (0xB) on a chosen CC (e.g., 1)                           | Encode curve in metadata or step CC values for linear/log curves.                                                      |
| Marker         | **Flex Data** or Stream marker                                       | Zero‑duration at marker’s time with metadata.                                                                          |
| Tempo          | Optional                                                             | You can keep seconds; Engraver can still schedule with JR timestamps. If you want beats, add a tempo map UMP sequence. |

> This adheres to your anti‑thesis: **time lives in midi2**; OTIO is a structural import/export. 

---

## 6) Authentication, storage, and codegen glue

* **Auth**: keep your Bearer token via `swift-secretstore`; the spec and the example server glue already reflect the pattern (`Authorization: Bearer …` or `x-api-key`). 
* **Store**: write/read timelines as JSON blobs in **Fountain‑Store**; MVCC and snapshots make updates safe while playback reads. 
* **Codegen**: keep using Apple’s **Swift OpenAPI Generator** for types/client/server; your spec has operationIds and models ready for generation. 

---

## 7) “Is there a reference implementation?”

* **Official**: The OTIO project provides C++/Python SDKs; there is **no first‑party Swift SDK** today.
* **In the Fountain stack**: The *reference* is the design in your AnimationKit doc that treats OTIO as JSON at the boundaries and converts to **UMP** in the core. That document—plus the import/export endpoints—*is* your design reference, and the minimal Codable subset + mapping above is the pragmatic way to realize it in Swift right now. 

If you ever need “full” OTIO semantics, you have two advanced options:

1. **Swift C++ interop**: build the OTIO C++ library for Apple platforms and call it from Swift (heavier toolchain + packaging).
2. **Out‑of‑process Python**: run `otio` Python to normalize/validate and pass JSON over stdio/IPC; still keep your Swift Codable bridge.

Most teams start with the **native Codable subset** approach because it is simple, fast, and matches the “OTIO only at the edges” philosophy in your spec.

---

## 8) Tests you should add

* Round‑trip identity (OTIO → UMP → OTIO) for basic cases (single clip, multiple tracks, transitions, markers).
* Stability: ordering, tie‑breaking for coincident events.
* Tolerance: fractional frame rounding (`value/rate`) edge cases.
* Metadata preservation: clip/marker metadata survives round‑trip via Flex Data payloads.

---

### TL;DR

* Implement a **Swift Codable OTIO subset**, and deterministic **mappers** OTIO ⟷ UMP.
* Keep **UMP/midi2** as the *only* runtime timing fabric (Engraver Space).
* Use your **AnimationKit** import/export endpoints as the public surface; the core remains UMP. 

If you want, I can turn the snippets above into a small `OTIOKit` + `Midi2Bridge` module pair and wire them into the generated server handlers from your spec.
