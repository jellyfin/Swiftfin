//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if DEBUG

import OSLog
import QuartzCore
import SwiftUI
import UIKit

// MARK: - Bruno debug overlay engine (DEBUG only)

//
// Two singletons drive the on-screen HUD that diagnoses UX / nav hitches and "frame drag":
//
//   • BrunoFrameMonitor — a CADisplayLink that measures real frame timing (fps, worst frame,
//     dropped/long frames) and aggregates per-view redraw rates. This is the ground truth about
//     hitches: a "long frame" is the display missing its budget, which on tvOS reads as the
//     up/down focus snap / drag the perf invariants (INV-1..9) fight.
//
//   • BrunoDebugLog — a ring buffer of timestamped nav / layout / frame events. Layout moves and
//     focus changes stamp `lastInteraction`; when the monitor sees a long frame within
//     `interactionWindow` of that stamp it flags the hitch "(nav)" — i.e. this drop was caused by
//     navigation, not background work. That linkage is the whole point.
//
// Everything here is gated DEBUG and only runs while at least one overlay toggle is on
// (BrunoDebugFlags + the monitor's start()/stop()), so a release build pays nothing and a DEBUG
// build with the overlays off pays nothing.

/// Cheap, plain (non-published) flags the hot instrumentation paths check before doing any work.
/// Kept off SwiftUI state on purpose — `brunoDebugRedraw` runs inside view `body`, so it must not
/// touch anything observable. The overlay modifier writes these whenever a toggle changes.
enum BrunoDebugFlags {
    static var redrawEnabled = false
    static var interactionEnabled = false
}

// MARK: - BrunoDebugLog

/// A timestamped event stream (nav / layout / frame) rendered by the rich-log panel, plus the
/// `lastInteraction` stamp the frame monitor uses to attribute hitches to navigation.
final class BrunoDebugLog: ObservableObject {

    static let shared = BrunoDebugLog()

    /// Mirrors every event onto the Instruments "Points of Interest" timeline (nanosecond
    /// precision), labelled identically to the on-screen LOG so a recorded trace correlates with
    /// Time Profiler / Core Animation tracks. Free when not recording.
    private static let signposter = OSSignposter(
        subsystem: "org.jellyfin.swiftfin.bruno",
        category: .pointsOfInterest
    )

    enum Kind {
        case nav
        case layout
        case frame
        case info

        var glyph: String {
            switch self {
            case .nav: "⮕"
            case .layout: "▦"
            case .frame: "▼"
            case .info: "·"
            }
        }

        var color: Color {
            switch self {
            case .nav: .cyan
            case .layout: .yellow
            case .frame: .red
            case .info: .gray
            }
        }

        /// Signpost lane name — distinct names render as separate rows in the Instruments
        /// "Points of Interest" instrument.
        var signpostName: StaticString {
            switch self {
            case .nav: "nav"
            case .layout: "layout"
            case .frame: "frame"
            case .info: "info"
            }
        }
    }

    struct Entry: Identifiable {
        let id: Int
        let t: CFTimeInterval
        let kind: Kind
        let text: String
    }

    @Published
    private(set) var entries: [Entry] = []

    /// Wall-clock (CACurrentMediaTime) of the last nav/layout interaction — updated on EVERY move
    /// (including throttled, un-logged ones) so the hitch proximity window is exact. Read by the
    /// frame monitor to decide whether a long frame was navigation-induced.
    private(set) var lastInteractionT: CFTimeInterval = 0

    /// Sequence id (`#NNNN`) of the last *logged* nav/layout entry. A nav-attributed hitch cites this
    /// so a FRAME drag points back at the exact NAV/LOG line that caused it — the cross-window link.
    private(set) var lastInteractionID: Int = 0

    private var counter = 0
    private let cap = 140

    private init() {}

    /// Append an event and return its sequence id. Callers are on the main thread (SwiftUI
    /// focus/geometry callbacks), which fire *outside* the view-update pass, so mutating
    /// `@Published` here is safe. All panels render `id` + `t` from this one clock/counter, so the
    /// same event reads identically across the FRAME / NAV / LOG windows.
    @discardableResult
    func log(_ kind: Kind, _ text: String) -> Int {
        counter += 1
        let t = CACurrentMediaTime()
        entries.append(Entry(id: counter, t: t, kind: kind, text: text))
        if entries.count > cap {
            entries.removeFirst(entries.count - cap)
        }
        // Same `#id text` as the on-screen LOG, so the HUD trace and an Instruments recording match.
        Self.signposter.emitEvent(kind.signpostName, "#\(self.counter, privacy: .public) \(text, privacy: .public)")
        // A logged interaction becomes the back-reference target for nearby hitches.
        if kind == .nav || kind == .layout {
            lastInteractionT = t
            lastInteractionID = counter
        }
        return counter
    }

    /// Stamp an interaction (focus move / layout shift) so nearby frame drops can be blamed on it.
    /// Updates only the timestamp — the id is set when the move is actually logged.
    func markInteraction() {
        lastInteractionT = CACurrentMediaTime()
    }

    func clear() {
        entries.removeAll()
    }
}

// MARK: - BrunoFrameMonitor

/// Drives all timing-based panels. Subclasses NSObject only so it can be a CADisplayLink target.
final class BrunoFrameMonitor: NSObject, ObservableObject {

    static let shared = BrunoFrameMonitor()

    // Published at a throttled cadence (≈4 Hz for timing, 1 Hz for redraw rates) so the HUD itself
    // doesn't re-render every frame and pollute the very measurement it's taking.
    @Published
    private(set) var fps: Double = 0
    @Published
    private(set) var frameMs: Double = 0
    @Published
    private(set) var worstMs: Double = 0
    @Published
    private(set) var hitchCount: Int = 0
    /// Recent frame durations (ms) for the sparkline. Newest last.
    @Published
    private(set) var samples: [Double] = []
    /// Per-view redraw counts over the last ~1s window, busiest first.
    @Published
    private(set) var redrawRates: [(name: String, count: Int)] = []

    /// Live frame number and clock (seconds since start), snapshotted at the throttled flush so the
    /// FRAME panel shows the shared timeline anchor without re-publishing every frame.
    @Published
    private(set) var displayFrameIndex: Int = 0
    @Published
    private(set) var clock: Double = 0

    /// Time origin used to render relative timestamps in the log.
    private(set) var startTime: CFTimeInterval = 0

    /// Monotonic frame counter (every display refresh) — the FRAME panel's `f<n>` and the frame
    /// number a hitch reports, so a drag can be located on the timeline.
    private var frameIndex = 0

    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    /// One display refresh in ms (16.67 @60, 8.33 @120). A frame longer than 1.5× this is "long".
    private var budgetMs: Double = 1000.0 / 60.0
    private var longFrameMs: Double {
        budgetMs * 1.5
    }

    // Raw (unpublished) accumulation, flushed to the published props on a timer.
    private var window: [Double] = []
    private var windowWorst: Double = 0
    private var lastTimingFlush: CFTimeInterval = 0

    private var redrawCounts: [String: Int] = [:]
    private var redrawWindowStart: CFTimeInterval = 0

    override private init() {
        super.init()
    }

    func start() {
        guard link == nil else { return }

        let maxFPS = max(UIScreen.main.maximumFramesPerSecond, 60)
        budgetMs = 1000.0 / Double(maxFPS)

        let now = CACurrentMediaTime()
        startTime = now
        lastTimestamp = 0
        lastTimingFlush = now
        redrawWindowStart = now
        window.removeAll()
        windowWorst = 0
        hitchCount = 0
        frameIndex = 0
        displayFrameIndex = 0
        clock = 0

        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    /// Called by `brunoDebugRedraw` from inside view `body`. Plain dict bump — no observable state.
    func bumpRedraw(_ name: String) {
        redrawCounts[name, default: 0] += 1
    }

    @objc
    private func tick(_ link: CADisplayLink) {
        let ts = link.timestamp

        guard lastTimestamp != 0 else {
            lastTimestamp = ts
            return
        }

        let dt = ts - lastTimestamp
        lastTimestamp = ts
        guard dt > 0 else { return }

        frameIndex += 1
        let ms = dt * 1000
        window.append(ms)
        windowWorst = max(windowWorst, ms)

        // A long frame is the hitch. Log it immediately (rare event), citing the frame number and —
        // if it landed within the interaction window — the exact interaction id (`#NNNN`) that
        // caused it plus the lag from that interaction to the drop. That id appears verbatim in the
        // NAV/LOG windows, so a FRAME drag links straight to its cause.
        if ms > longFrameMs {
            hitchCount += 1
            let log = BrunoDebugLog.shared
            let lagMs = (ts - log.lastInteractionT) * 1000
            let dropped = Int((ms / budgetMs).rounded()) - 1
            // Front-load the cause link (→#id +lag) so it survives the single-line truncation; the
            // dropped-frame count and frame number trail as secondary detail.
            let link = lagMs < Self.interactionWindow * 1000
                ? String(format: " →#%04d +%.0fms", log.lastInteractionID, lagMs)
                : ""
            log.log(
                .frame,
                String(format: "drag %.0fms%@ · %df · f%d", ms, link, dropped, frameIndex)
            )
        }

        // Throttled flush of timing panels (~4 Hz).
        if ts - lastTimingFlush >= 0.25 {
            let count = Double(window.count)
            let avg = window.reduce(0, +) / count
            fps = avg > 0 ? 1000.0 / avg : 0
            frameMs = avg
            worstMs = windowWorst
            samples = Array(window.suffix(60))
            displayFrameIndex = frameIndex
            clock = ts - startTime
            window.removeAll(keepingCapacity: true)
            windowWorst = 0
            lastTimingFlush = ts
        }

        // Redraw-rate flush (~1 Hz) → counts-per-second per tracked view.
        if ts - redrawWindowStart >= 1.0 {
            redrawRates = redrawCounts
                .map { (name: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
            redrawCounts.removeAll(keepingCapacity: true)
            redrawWindowStart = ts
        }
    }

    /// A long frame within this many seconds of an interaction is blamed on navigation.
    static let interactionWindow: CFTimeInterval = 0.5
}

#endif
