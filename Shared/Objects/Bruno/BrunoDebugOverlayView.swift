//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if DEBUG

import Defaults
import SwiftUI
import UIKit

// swiftlint:disable hard_coded_display_string

// MARK: - Bruno debug overlay HUD (DEBUG only)

//
// Three independent, separately-toggled panels stacked at the top-trailing corner:
//
//   1. FPS        (.brunoDebugFPS) — frame rate, frame time, worst frame, hitch count, sparkline.
//   2. NAV/LAYOUT (.brunoDebugNav) — redraws/sec per tracked view + the recent layout/focus moves
//                                    that are the "graphic math" navigation triggers.
//   3. LOG        (.brunoDebugLog) — the full timestamped event stream incl. nav-attributed drags.
//
// The HUD never takes focus (`allowsHitTesting(false)`) and is purely additive over app content.

// MARK: Overlay modifier (injection point)

struct BrunoDebugOverlayModifier: ViewModifier {

    @Default(.brunoDebugFPS)
    private var showFPS
    @Default(.brunoDebugNav)
    private var showNav
    @Default(.brunoDebugLog)
    private var showLog

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                #if os(tvOS)
                // tvOS: the HUD is hosted in a passthrough overlay UIWindow (see BrunoDebugOverlayWindow),
                // not this root .overlay — the browse/decade/Studios/Kids drill-ins are full-screen
                // NavigationStack pushes (.ignoresSafeArea, nav bar hidden) that cover a root-level
                // overlay, and the frame-drag log is needed precisely on those pushed surfaces. A higher
                // window level floats above every push (and any future drill-in) with no per-surface
                // wiring. sync() below drives that window; this overlay stays empty.
                EmptyView()
                #else
                BrunoDebugHUD(showFPS: showFPS, showNav: showNav, showLog: showLog)
                    .allowsHitTesting(false)
                #endif
            }
            .onAppear { sync() }
            .onChange(of: showFPS) { _ in sync() }
            .onChange(of: showNav) { _ in sync() }
            .onChange(of: showLog) { _ in sync() }
    }

    /// Mirror the toggles into the cheap hot-path flags and run the display link only when needed.
    private func sync() {
        BrunoDebugFlags.redrawEnabled = showNav
        BrunoDebugFlags.interactionEnabled = showNav || showLog
        if showFPS || showNav || showLog {
            BrunoFrameMonitor.shared.start()
        } else {
            BrunoFrameMonitor.shared.stop()
        }
        #if os(tvOS)
        BrunoDebugOverlayWindow.shared.update(showFPS: showFPS, showNav: showNav, showLog: showLog)
        #endif
    }
}

// MARK: Overlay window (tvOS)

#if os(tvOS)

//
// The HUD's host on tvOS. A separate, non-interactive UIWindow one level above the app window, so it
// composites over full-screen NavigationStack pushes (which a root .overlay sits *under*). Created
// lazily when the first panel turns on, torn down when the last turns off; zero windows while idle.
// The hosted BrunoDebugHUD @ObservedObject's the same shared monitor/log singletons as the root copy,
// so it updates live.
@MainActor
final class BrunoDebugOverlayWindow {

    static let shared = BrunoDebugOverlayWindow()

    private var window: UIWindow?
    private var host: UIHostingController<AnyView>?

    private init() {}

    func update(showFPS: Bool, showNav: Bool, showLog: Bool) {
        guard showFPS || showNav || showLog else {
            teardown()
            return
        }

        // Full-screen clear container so the HUD pins to the top-trailing safe-inset corner, matching
        // the iOS .overlay placement. ignoresSafeArea so only the HUD's own screenInset (title-safe)
        // applies, not a doubled overscan inset.
        let root = AnyView(
            ZStack(alignment: .topTrailing) {
                Color.clear
                BrunoDebugHUD(showFPS: showFPS, showNav: showNav, showLog: showLog)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        )

        if let host {
            host.rootView = root
            return
        }

        guard let scene = activeScene else { return }
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .normal + 100
        window.isUserInteractionEnabled = false
        window.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false

        self.host = host
        self.window = window
    }

    private func teardown() {
        window?.isHidden = true
        window = nil
        host = nil
    }

    /// The foreground-active window scene (falls back to the first connected one) to attach to.
    private var activeScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}

#endif

// MARK: HUD

private struct BrunoDebugHUD: View {

    let showFPS: Bool
    let showNav: Bool
    let showLog: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: BrunoDebugStyle.gap) {
            if showFPS { FPSPanel() }
            if showNav { NavPanel() }
            if showLog { LogPanel() }
        }
        .padding(BrunoDebugStyle.screenInset)
    }
}

// MARK: Panels

private struct FPSPanel: View {

    @ObservedObject
    private var monitor = BrunoFrameMonitor.shared

    private var tint: Color {
        if monitor.fps >= 58 { return .green }
        if monitor.fps >= 45 { return .yellow }
        return .red
    }

    var body: some View {
        BrunoDebugPanel(title: "FRAME") {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.0f", monitor.fps))
                    .font(BrunoDebugStyle.bigFont)
                    .foregroundStyle(tint)
                Text("FPS")
                    .font(BrunoDebugStyle.font)
                    .foregroundStyle(.secondary)
            }

            Text(String(format: "frame %.1fms · worst %.0fms", monitor.frameMs, monitor.worstMs))
                .font(BrunoDebugStyle.font)
                .foregroundStyle(.primary)

            Text("hitches \(monitor.hitchCount)")
                .font(BrunoDebugStyle.font)
                .foregroundStyle(monitor.hitchCount > 0 ? .red : .secondary)

            // Shared timeline anchor: the same frame# and clock the NAV/LOG rows are stamped against.
            Text(String(format: "f%d · t %.3fs", monitor.displayFrameIndex, monitor.clock))
                .font(BrunoDebugStyle.font)
                .foregroundStyle(.secondary)

            Sparkline(samples: monitor.samples, budgetMs: 1000.0 / 60.0)
                .frame(width: BrunoDebugStyle.panelWidth, height: BrunoDebugStyle.sparkHeight)
        }
    }
}

private struct NavPanel: View {

    @ObservedObject
    private var monitor = BrunoFrameMonitor.shared
    @ObservedObject
    private var log = BrunoDebugLog.shared

    private var moves: [BrunoDebugLog.Entry] {
        log.entries.filter { $0.kind == .nav || $0.kind == .layout }.suffix(5).reversed()
    }

    var body: some View {
        BrunoDebugPanel(title: "NAV / LAYOUT") {
            if monitor.redrawRates.isEmpty {
                Text("redraws/s —")
                    .font(BrunoDebugStyle.font)
                    .foregroundStyle(.secondary)
            } else {
                Text("redraws/s")
                    .font(BrunoDebugStyle.font)
                    .foregroundStyle(.secondary)
                ForEach(monitor.redrawRates.prefix(4), id: \.name) { rate in
                    Text("\(rate.count)× \(rate.name)")
                        .font(BrunoDebugStyle.font)
                        .foregroundStyle(rate.count > 4 ? .orange : .primary)
                        .lineLimit(1)
                }
            }

            Divider().overlay(Color.white.opacity(0.2))

            ForEach(Array(moves), id: \.id) { entry in
                TraceRow(entry: entry)
            }
        }
    }
}

private struct LogPanel: View {

    @ObservedObject
    private var log = BrunoDebugLog.shared

    private var recent: [BrunoDebugLog.Entry] {
        Array(log.entries.suffix(12).reversed())
    }

    var body: some View {
        BrunoDebugPanel(title: "LOG") {
            if recent.isEmpty {
                Text("waiting for events…")
                    .font(BrunoDebugStyle.font)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recent, id: \.id) { entry in
                    TraceRow(entry: entry)
                }
            }
        }
    }
}

// MARK: Trace row

/// One event rendered with the shared trace columns — `t.mmm  #NNNN  glyph  text` — so the SAME
/// event lines up identically across the NAV and LOG windows and against the FRAME panel's anchor.
private struct TraceRow: View {

    let entry: BrunoDebugLog.Entry

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(String(format: "%8.3f", entry.t - BrunoFrameMonitor.shared.startTime))
                .foregroundStyle(.secondary)
            Text(String(format: "#%04d", entry.id))
                .foregroundStyle(.white.opacity(0.45))
            Text(entry.kind.glyph)
                .foregroundStyle(entry.kind.color)
            Text(entry.text)
                .foregroundStyle(entry.kind == .frame ? Color.red : .primary)
        }
        .font(BrunoDebugStyle.font)
        .lineLimit(1)
    }
}

// MARK: Shared chrome

private struct BrunoDebugPanel<Content: View>: View {

    let title: String
    @ViewBuilder
    let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(BrunoDebugStyle.titleFont)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 2)
            content
        }
        .padding(BrunoDebugStyle.padding)
        .frame(width: BrunoDebugStyle.panelWidth, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .environment(\.colorScheme, .dark)
    }
}

private struct Sparkline: View {

    let samples: [Double]
    let budgetMs: Double

    var body: some View {
        GeometryReader { geo in
            let maxMs = max(samples.max() ?? budgetMs, budgetMs * 2)
            let count = max(samples.count, 1)
            let step = geo.size.width / CGFloat(count)

            // Budget line: anything spiking above it is a dropped/long frame.
            let budgetY = geo.size.height * (1 - CGFloat(budgetMs / maxMs))

            Path { p in
                p.move(to: CGPoint(x: 0, y: budgetY))
                p.addLine(to: CGPoint(x: geo.size.width, y: budgetY))
            }
            .stroke(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            ForEach(Array(samples.enumerated()), id: \.offset) { index, ms in
                let h = geo.size.height * CGFloat(min(ms / maxMs, 1))
                let over = ms > budgetMs * 1.5
                Rectangle()
                    .fill(over ? Color.red : Color.green.opacity(0.7))
                    .frame(width: max(step - 1, 1), height: max(h, 1))
                    .position(x: CGFloat(index) * step + step / 2, y: geo.size.height - h / 2)
            }
        }
    }
}

// MARK: Style

private enum BrunoDebugStyle {
    #if os(tvOS)
    static let screenInset: CGFloat = 60
    static let panelWidth: CGFloat = 460
    static let padding: CGFloat = 14
    static let gap: CGFloat = 10
    static let sparkHeight: CGFloat = 40
    static let font: Font = .system(size: 18, weight: .medium, design: .monospaced)
    static let bigFont: Font = .system(size: 40, weight: .bold, design: .monospaced)
    static let titleFont: Font = .system(size: 14, weight: .heavy, design: .monospaced)
    #else
    static let screenInset: CGFloat = 12
    static let panelWidth: CGFloat = 270
    static let padding: CGFloat = 8
    static let gap: CGFloat = 6
    static let sparkHeight: CGFloat = 28
    static let font: Font = .system(size: 11, weight: .medium, design: .monospaced)
    static let bigFont: Font = .system(size: 26, weight: .bold, design: .monospaced)
    static let titleFont: Font = .system(size: 9, weight: .heavy, design: .monospaced)
    #endif
}

// MARK: - Layout / nav instrumentation modifiers

/// Logs a tracked view's vertical movement (the shelf-spine "graphic math" of a nav scroll) and
/// stamps it as an interaction so coincident frame drags get attributed to navigation. Throttled
/// so a smooth scroll reads as a steady stream rather than a per-frame flood.
struct BrunoDebugLayoutModifier: ViewModifier {

    let name: String

    @State
    private var last: CGRect = .zero
    @State
    private var lastLog: CFTimeInterval = 0

    func body(content: Content) -> some View {
        content.onFrameChanged { frame, _ in
            guard BrunoDebugFlags.interactionEnabled else { return }
            defer { last = frame }
            guard last != .zero else { return }

            let dy = frame.minY - last.minY
            guard abs(dy) > 1 else { return }

            BrunoDebugLog.shared.markInteraction()

            let now = CACurrentMediaTime()
            guard now - lastLog > 0.18 else { return }
            lastLog = now
            BrunoDebugLog.shared.log(.layout, String(format: "%@ Δy %+.0f", name, dy))
        }
    }
}

/// Logs when a tracked focusable gains focus — a discrete nav-input event.
struct BrunoDebugNavFocusModifier: ViewModifier {

    let name: String
    let isFocused: Bool

    func body(content: Content) -> some View {
        content.onChange(of: isFocused) { focused in
            guard focused, BrunoDebugFlags.interactionEnabled else { return }
            BrunoDebugLog.shared.markInteraction()
            BrunoDebugLog.shared.log(.nav, "focus → \(name)")
        }
    }
}

// swiftlint:enable hard_coded_display_string

#endif
